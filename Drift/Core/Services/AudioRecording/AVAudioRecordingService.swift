//
//  AVAudioRecordingService.swift
//  Drift
//
//  Created by Lucas Stuart West Rogers on 12/05/2026.
//

import AVFoundation
import Foundation
import UIKit

final class AVAudioRecordingService: NSObject, AudioRecordingService, AVAudioRecorderDelegate,
  @unchecked Sendable
{
  var recordingState: RecordingState {
    stateLock.lock()
    defer { stateLock.unlock() }
    return _recordingState
  }

  private let audioSession: AVAudioSession
  private let fileManager: FileManager
  private let temporaryDirectory: URL
  private let notificationCenter: NotificationCenter
  private let now: @Sendable () -> Date
  private let operationQueue = DispatchQueue(
    label: "com.drift.audio-recording-service",
    qos: .userInitiated
  )
  private let stateLock = NSLock()

  private var _recordingState: RecordingState = .idle
  private var recorder: AVAudioRecorder?
  private var currentRecordingURL: URL?
  private var startedAt: Date?
  private var accumulatedElapsed: TimeInterval = 0

  init(
    audioSession: AVAudioSession = .sharedInstance(),
    fileManager: FileManager = .default,
    temporaryDirectory: URL = FileManager.default.temporaryDirectory,
    notificationCenter: NotificationCenter = .default,
    now: @escaping @Sendable () -> Date = Date.init
  ) {
    self.audioSession = audioSession
    self.fileManager = fileManager
    self.temporaryDirectory = temporaryDirectory
    self.notificationCenter = notificationCenter
    self.now = now
    super.init()

    notificationCenter.addObserver(
      self,
      selector: #selector(handleAudioInterruption(_:)),
      name: AVAudioSession.interruptionNotification,
      object: audioSession
    )
    notificationCenter.addObserver(
      self,
      selector: #selector(handleRouteChange(_:)),
      name: AVAudioSession.routeChangeNotification,
      object: audioSession
    )
    notificationCenter.addObserver(
      self,
      selector: #selector(handleAppDidEnterBackground),
      name: UIApplication.didEnterBackgroundNotification,
      object: nil
    )
  }

  deinit {
    notificationCenter.removeObserver(self)
  }

  func requestPermission() async throws {
    try await requestPermissionIfNeeded()
  }

  func currentPermissionStatus() async -> PermissionStatus {
    await perform {
      switch AVAudioApplication.shared.recordPermission {
      case .granted: .granted
      case .denied: .denied
      case .undetermined: .unknown
      @unknown default: .restricted
      }
    }
  }

  func startRecording() async throws {
    try await requestPermissionIfNeeded()
    try await perform {
      try self.startRecordingAfterPermission()
    }
  }

  func pauseRecording() async throws {
    try await perform {
      try self.pauseRecordingOnQueue()
    }
  }

  func resumeRecording() async throws {
    try await perform {
      try self.resumeRecordingOnQueue()
    }
  }

  func stopRecording() async throws -> URL {
    try await perform {
      try self.stopRecordingOnQueue()
    }
  }

  func cancelRecording() async {
    await perform {
      self.cancelRecordingOnQueue()
    }
  }

  func currentAudioLevel() async -> Double {
    await perform {
      self.currentAudioLevelOnQueue()
    }
  }

  func audioRecorderDidFinishRecording(
    _ recorder: AVAudioRecorder,
    successfully flag: Bool
  ) {
    let recorderIdentifier = ObjectIdentifier(recorder)
    operationQueue.async { [weak self] in
      guard
        let self,
        !flag,
        let currentRecorder = self.recorder,
        ObjectIdentifier(currentRecorder) == recorderIdentifier
      else { return }

      self.fail(with: .stopFailed, deletingCurrentFile: false)
    }
  }

  func audioRecorderEncodeErrorDidOccur(
    _ recorder: AVAudioRecorder,
    error: (any Error)?
  ) {
    let recorderIdentifier = ObjectIdentifier(recorder)
    operationQueue.async { [weak self] in
      guard
        let self,
        let currentRecorder = self.recorder,
        ObjectIdentifier(currentRecorder) == recorderIdentifier
      else { return }

      self.fail(with: .interrupted)
    }
  }

  private static let recordingSettings: [String: Any] = [
    AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
    AVSampleRateKey: 12_000,
    AVNumberOfChannelsKey: 1,
    AVEncoderAudioQualityKey: AVAudioQuality.medium.rawValue,
  ]

  private func requestPermissionIfNeeded() async throws {
    setRecordingState(.requestingPermission)

    let recordPermission = await perform {
      AVAudioApplication.shared.recordPermission
    }

    switch recordPermission {
    case .granted:
      setRecordingState(.idle)
    case .denied:
      setRecordingState(.failed(message: AudioRecordingError.permissionDenied.localizedDescription))
      throw AudioRecordingError.permissionDenied
    case .undetermined:
      let granted = await withCheckedContinuation { continuation in
        AVAudioApplication.requestRecordPermission { granted in
          continuation.resume(returning: granted)
        }
      }

      try await perform {
        if granted {
          self.setRecordingState(.idle)
        } else {
          self.setRecordingState(
            .failed(message: AudioRecordingError.permissionDenied.localizedDescription)
          )
          throw AudioRecordingError.permissionDenied
        }
      }
    @unknown default:
      setRecordingState(
        .failed(message: AudioRecordingError.permissionUnavailable.localizedDescription))
      throw AudioRecordingError.permissionUnavailable
    }
  }

  private func startRecordingAfterPermission() throws {
    setRecordingState(.preparing)
    resetRecordingProgress()

    do {
      try configureAudioSession()

      let recordingURL = temporaryRecordingURL()
      let recorder = try AVAudioRecorder(url: recordingURL, settings: Self.recordingSettings)
      recorder.delegate = self
      recorder.isMeteringEnabled = true
      recorder.prepareToRecord()

      guard recorder.record() else {
        throw AudioRecordingError.startFailed
      }

      let startDate = now()
      self.recorder = recorder
      currentRecordingURL = recordingURL
      startedAt = startDate
      setRecordingState(.recording(startedAt: startDate))
    } catch let error as AudioRecordingError {
      fail(with: error)
      throw error
    } catch {
      fail(with: .startFailed)
      throw AudioRecordingError.startFailed
    }
  }

  private func pauseRecordingOnQueue() throws {
    guard let recorder, recorder.isRecording else { return }

    recorder.pause()
    updateAccumulatedElapsed()
    setRecordingState(.paused(elapsed: accumulatedElapsed))
  }

  private func resumeRecordingOnQueue() throws {
    guard let recorder else {
      fail(with: .startFailed)
      throw AudioRecordingError.startFailed
    }

    guard recorder.record() else {
      fail(with: .startFailed)
      throw AudioRecordingError.startFailed
    }

    let startDate = now()
    startedAt = startDate
    setRecordingState(.recording(startedAt: startDate))
  }

  private func stopRecordingOnQueue() throws -> URL {
    guard let recorder, let currentRecordingURL else {
      fail(with: .missingAudioFile)
      throw AudioRecordingError.missingAudioFile
    }

    setRecordingState(.finishing)
    updateAccumulatedElapsed()
    recorder.stop()
    self.recorder = nil

    do {
      try deactivateAudioSession()
    } catch {
      fail(with: .stopFailed, deletingCurrentFile: false)
      throw AudioRecordingError.stopFailed
    }

    guard fileManager.fileExists(atPath: currentRecordingURL.path) else {
      fail(with: .missingAudioFile)
      throw AudioRecordingError.missingAudioFile
    }

    let finishedURL = currentRecordingURL
    resetRecordingProgress()
    setRecordingState(.idle)
    return finishedURL
  }

  private func cancelRecordingOnQueue() {
    setRecordingState(.cancelling)
    recorder?.stop()
    recorder = nil

    do {
      try deleteCurrentRecordingFile()
      try deactivateAudioSession()
      resetRecordingProgress()
      setRecordingState(.cancelled)
    } catch {
      resetRecordingProgress()
      setRecordingState(.failed(message: AudioRecordingError.cleanupFailed.localizedDescription))
    }
  }

  private func currentAudioLevelOnQueue() -> Double {
    guard let recorder, recorder.isRecording else { return 0 }

    recorder.updateMeters()
    let averagePower = recorder.averagePower(forChannel: 0)
    let minimumDecibels: Float = -55

    guard averagePower > minimumDecibels else { return 0 }
    guard averagePower < 0 else { return 1 }

    let linearLevel = (averagePower - minimumDecibels) / abs(minimumDecibels)
    return min(max(Double(pow(linearLevel, 1.5)), 0), 1)
  }

  private func configureAudioSession() throws {
    do {
      try audioSession.setCategory(
        .playAndRecord, mode: .spokenAudio, options: [.allowBluetoothHFP, .defaultToSpeaker])
      try audioSession.setActive(true)
    } catch {
      throw AudioRecordingError.sessionConfigurationFailed
    }
  }

  private func deactivateAudioSession() throws {
    try audioSession.setActive(false, options: .notifyOthersOnDeactivation)
  }

  private func temporaryRecordingURL() -> URL {
    temporaryDirectory
      .appendingPathComponent("drift-\(UUID().uuidString)")
      .appendingPathExtension("m4a")
  }

  private func updateAccumulatedElapsed() {
    guard let startedAt else { return }
    accumulatedElapsed += now().timeIntervalSince(startedAt)
    self.startedAt = nil
  }

  private func resetRecordingProgress() {
    currentRecordingURL = nil
    startedAt = nil
    accumulatedElapsed = 0
  }

  private func fail(
    with error: AudioRecordingError,
    deletingCurrentFile: Bool = true
  ) {
    recorder?.stop()
    recorder = nil

    if deletingCurrentFile {
      try? deleteCurrentRecordingFile()
    }
    try? deactivateAudioSession()
    resetRecordingProgress()
    setRecordingState(.failed(message: error.localizedDescription))
  }

  private func deleteCurrentRecordingFile() throws {
    guard let currentRecordingURL, fileManager.fileExists(atPath: currentRecordingURL.path) else {
      return
    }
    try fileManager.removeItem(at: currentRecordingURL)
  }

  @objc
  private func handleAudioInterruption(_ notification: Notification) {
    let rawType = notification.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt
    operationQueue.async { [weak self] in
      self?.handleAudioInterruption(rawType: rawType)
    }
  }

  @objc
  private func handleRouteChange(_ notification: Notification) {
    let rawReason = notification.userInfo?[AVAudioSessionRouteChangeReasonKey] as? UInt
    operationQueue.async { [weak self] in
      self?.handleRouteChange(rawReason: rawReason)
    }
  }

  @objc
  private func handleAppDidEnterBackground() {
    // Background recording is intentionally not enabled for the MVP.
  }

  private func handleAudioInterruption(rawType: UInt?) {
    guard recorder != nil else { return }

    guard
      let rawType,
      let type = AVAudioSession.InterruptionType(rawValue: rawType)
    else { return }

    switch type {
    case .began:
      updateAccumulatedElapsed()
      recorder?.pause()
      setRecordingState(.failed(message: AudioRecordingError.interrupted.localizedDescription))
    case .ended:
      // Automatic resume needs explicit recovery UI before it is safe to enable.
      break
    @unknown default:
      break
    }
  }

  private func handleRouteChange(rawReason: UInt?) {
    guard recorder != nil else { return }

    guard
      let rawReason,
      let reason = AVAudioSession.RouteChangeReason(rawValue: rawReason)
    else { return }

    switch reason {
    case .oldDeviceUnavailable:
      updateAccumulatedElapsed()
      recorder?.pause()
      setRecordingState(.failed(message: AudioRecordingError.interrupted.localizedDescription))
    default:
      // External microphone recovery can be added with dedicated route-change UI.
      break
    }
  }

  private func perform<T>(_ operation: @escaping @Sendable () throws -> T) async throws -> T {
    try await withCheckedThrowingContinuation { continuation in
      operationQueue.async {
        do {
          continuation.resume(returning: try operation())
        } catch {
          continuation.resume(throwing: error)
        }
      }
    }
  }

  private func perform<T>(_ operation: @escaping @Sendable () -> T) async -> T {
    await withCheckedContinuation { continuation in
      operationQueue.async {
        continuation.resume(returning: operation())
      }
    }
  }

  private func setRecordingState(_ recordingState: RecordingState) {
    stateLock.lock()
    _recordingState = recordingState
    stateLock.unlock()
  }
}
