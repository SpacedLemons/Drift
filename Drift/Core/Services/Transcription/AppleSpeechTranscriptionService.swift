//
//  AppleSpeechTranscriptionService.swift
//  Drift
//
//  Created by Lucas Stuart West Rogers on 12/05/2026.
//

import Foundation
import Speech

final class AppleSpeechTranscriptionService: TranscriptionService, @unchecked Sendable {
  private let locale: Locale
  private let fileManager: FileManager

  init(
    locale: Locale = .autoupdatingCurrent,
    fileManager: FileManager = .default
  ) {
    self.locale = locale
    self.fileManager = fileManager
  }

  var supportsOnDeviceTranscription: Bool {
    makeRecognizer()?.supportsOnDeviceRecognition == true
  }

  func currentPermissionStatus() async -> PermissionStatus {
    switch SFSpeechRecognizer.authorizationStatus() {
    case .authorized: .granted
    case .denied: .denied
    case .restricted: .restricted
    case .notDetermined: .unknown
    @unknown default: .unknown
    }
  }

  func requestPermission() async throws {
    switch SFSpeechRecognizer.authorizationStatus() {
    case .authorized:
      return
    case .denied:
      throw TranscriptionError.permissionDenied
    case .restricted:
      throw TranscriptionError.permissionRestricted
    case .notDetermined:
      let status = await withCheckedContinuation { continuation in
        SFSpeechRecognizer.requestAuthorization { status in
          continuation.resume(returning: status)
        }
      }
      try handleAuthorizationStatus(status)
    @unknown default:
      throw TranscriptionError.permissionDenied
    }
  }

  func transcribe(audioURL: URL) async throws -> String {
    try await requestPermission()

    guard fileManager.fileExists(atPath: audioURL.path) else {
      throw TranscriptionError.missingAudioFile
    }

    guard let recognizer = makeRecognizer() else {
      throw TranscriptionError.unsupportedLocale
    }

    guard recognizer.isAvailable else {
      throw TranscriptionError.recognizerUnavailable
    }

    let request = SFSpeechURLRecognitionRequest(url: audioURL)
    request.shouldReportPartialResults = false
    request.taskHint = .dictation

    if recognizer.supportsOnDeviceRecognition {
      request.requiresOnDeviceRecognition = true
    }

    let taskBox = SpeechRecognitionTaskBox()

    return try await withTaskCancellationHandler {
      try await withCheckedThrowingContinuation { continuation in
        let continuationBox = SpeechRecognitionContinuationBox(continuation: continuation)
        taskBox.setContinuationBox(continuationBox)

        let task = recognizer.recognitionTask(with: request) { result, error in
          if let result, result.isFinal {
            let transcript =
              result.bestTranscription.formattedString
              .trimmingCharacters(in: .whitespacesAndNewlines)

            if transcript.isEmpty {
              continuationBox.resume(throwing: TranscriptionError.emptyResult)
            } else {
              continuationBox.resume(returning: transcript)
            }
            return
          }

          if error != nil {
            continuationBox.resume(throwing: TranscriptionError.transcriptionFailed)
          }
        }

        taskBox.setTask(task)
      }
    } onCancel: {
      taskBox.cancel()
    }
  }

  private func makeRecognizer() -> SFSpeechRecognizer? {
    SFSpeechRecognizer(locale: locale)
  }

  private func handleAuthorizationStatus(_ status: SFSpeechRecognizerAuthorizationStatus) throws {
    switch status {
    case .authorized:
      return
    case .denied:
      throw TranscriptionError.permissionDenied
    case .restricted:
      throw TranscriptionError.permissionRestricted
    case .notDetermined:
      throw TranscriptionError.permissionDenied
    @unknown default:
      throw TranscriptionError.permissionDenied
    }
  }
}

private final class SpeechRecognitionTaskBox: @unchecked Sendable {
  private let lock = NSLock()
  private var continuationBox: SpeechRecognitionContinuationBox?
  private var task: SFSpeechRecognitionTask?

  func setContinuationBox(_ continuationBox: SpeechRecognitionContinuationBox) {
    lock.lock()
    self.continuationBox = continuationBox
    lock.unlock()
  }

  func setTask(_ task: SFSpeechRecognitionTask) {
    lock.lock()
    self.task = task
    lock.unlock()
  }

  func cancel() {
    lock.lock()
    let values = (task, continuationBox)
    task = nil
    continuationBox = nil
    lock.unlock()

    values.0?.cancel()
    values.1?.resume(throwing: CancellationError())
  }
}

private final class SpeechRecognitionContinuationBox: @unchecked Sendable {
  private let lock = NSLock()
  private var continuation: CheckedContinuation<String, any Error>?

  init(continuation: CheckedContinuation<String, any Error>) {
    self.continuation = continuation
  }

  func resume(returning value: String) {
    resume { continuation in
      continuation.resume(returning: value)
    }
  }

  func resume(throwing error: any Error) {
    resume { continuation in
      continuation.resume(throwing: error)
    }
  }

  private func resume(_ action: (CheckedContinuation<String, any Error>) -> Void) {
    lock.lock()
    let continuation = self.continuation
    self.continuation = nil
    lock.unlock()

    guard let continuation else { return }
    action(continuation)
  }
}
