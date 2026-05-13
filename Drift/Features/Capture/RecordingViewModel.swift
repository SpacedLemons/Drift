//
//  RecordingViewModel.swift
//  Drift
//
//  Created by Lucas Stuart West Rogers on 12/05/2026.
//

import Foundation
import Observation

@MainActor
@Observable
final class RecordingViewModel {
  @ObservationIgnored
  private let audioRecordingService: any AudioRecordingService
  @ObservationIgnored
  private let now: () -> Date
  @ObservationIgnored
  private let silencePromptThreshold: TimeInterval
  @ObservationIgnored
  private let silenceAutoPauseThreshold: TimeInterval
  @ObservationIgnored
  private let silenceLevelThreshold: Double
  @ObservationIgnored
  private let meteringInterval: TimeInterval
  @ObservationIgnored
  private var timerTask: Task<Void, Never>?
  @ObservationIgnored
  private var meteringTask: Task<Void, Never>?
  @ObservationIgnored
  private var startToken: UUID?

  private(set) var elapsedTime: TimeInterval = 0
  private(set) var audioLevel: Double = 0
  private(set) var isPreparing = false
  private(set) var isRecording = false
  private(set) var isPaused = false
  private(set) var isFinishing = false
  private(set) var isCancelling = false
  private(set) var errorMessage: String?
  private(set) var shouldShowSettingsLink = false
  private(set) var shouldShowSilencePrompt = false
  private(set) var didAutoPauseForSilence = false
  private var sustainedSilenceDuration: TimeInterval = 0

  init(
    audioRecordingService: any AudioRecordingService,
    now: @escaping () -> Date = Date.init,
    silencePromptThreshold: TimeInterval = 10,
    silenceAutoPauseThreshold: TimeInterval = 20,
    silenceLevelThreshold: Double = 0.06,
    meteringInterval: TimeInterval = 0.08
  ) {
    self.audioRecordingService = audioRecordingService
    self.now = now
    self.silencePromptThreshold = silencePromptThreshold
    self.silenceAutoPauseThreshold = silenceAutoPauseThreshold
    self.silenceLevelThreshold = silenceLevelThreshold
    self.meteringInterval = meteringInterval
  }

  deinit {
    timerTask?.cancel()
    meteringTask?.cancel()
  }

  var formattedElapsedTime: String {
    let totalSeconds = max(Int(elapsedTime), 0)
    let minutes = totalSeconds / 60
    let seconds = totalSeconds % 60
    return String(format: "%02d:%02d", minutes, seconds)
  }

  var pauseResumeTitle: String {
    isPaused ? "Resume" : "Pause"
  }

  var pauseResumeIcon: String {
    isPaused ? AppIcons.play : AppIcons.pause
  }

  var statusText: String {
    if isCancelling { return "Cancelling" }
    if isPreparing { return "Preparing" }
    if isFinishing { return "Finishing" }
    if isPaused { return "Paused" }
    if isRecording { return "Recording" }
    return "Ready"
  }

  var silencePromptTitle: String {
    "Still there?"
  }

  var silencePromptMessage: String {
    "We have not heard much for a moment."
  }

  var canPauseOrFinish: Bool {
    isRecording && !isPreparing && !isFinishing && !isCancelling
  }

  var canCancel: Bool {
    !isCancelling && !isFinishing
  }

  func start() async {
    guard !isRecording, !isPreparing else { return }

    let token = UUID()
    startToken = token
    isPreparing = true
    errorMessage = nil
    shouldShowSettingsLink = false
    elapsedTime = 0
    audioLevel = 0
    sustainedSilenceDuration = 0
    shouldShowSilencePrompt = false
    didAutoPauseForSilence = false

    do {
      try await audioRecordingService.startRecording()
      guard startToken == token, !isCancelling else { return }

      startToken = nil
      isPreparing = false
      isRecording = true
      isPaused = false
      startTimer()
      startMetering()
    } catch {
      guard startToken == token else { return }

      startToken = nil
      isPreparing = false
      stopTimer()
      stopMetering(resetLevel: true)
      errorMessage = userFacingErrorMessage(
        for: error,
        fallback: "We could not start recording. Please try again."
      )
      shouldShowSettingsLink = shouldShowSettingsLink(for: error)
    }
  }

  func togglePause() async {
    guard canPauseOrFinish else { return }

    do {
      if isPaused {
        try await audioRecordingService.resumeRecording()
        isPaused = false
        sustainedSilenceDuration = 0
        shouldShowSilencePrompt = false
        didAutoPauseForSilence = false
        startMetering()
      } else {
        try await audioRecordingService.pauseRecording()
        isPaused = true
        stopMetering(resetLevel: true)
      }
    } catch {
      errorMessage = userFacingErrorMessage(
        for: error,
        fallback: "We could not update this recording. Please try again."
      )
      shouldShowSettingsLink = shouldShowSettingsLink(for: error)
    }
  }

  func finish() async -> RecordingResult? {
    guard isRecording, !isFinishing, !isCancelling else {
      errorMessage = "We could not prepare this recording. Please try again."
      return nil
    }

    isFinishing = true
    errorMessage = nil
    startToken = nil
    stopMetering(resetLevel: true)

    do {
      let url = try await audioRecordingService.stopRecording()
      stopTimer()
      isRecording = false
      isPaused = false
      isFinishing = false

      return RecordingResult(
        audioURL: url,
        duration: max(elapsedTime, 1),
        finishedAt: now()
      )
    } catch {
      isFinishing = false
      if isRecording, !isPaused {
        startMetering()
      }
      errorMessage = userFacingErrorMessage(
        for: error,
        fallback: "We could not finish this recording. Please try again."
      )
      shouldShowSettingsLink = shouldShowSettingsLink(for: error)
      return nil
    }
  }

  func cancel() async {
    guard canCancel else { return }

    startToken = nil
    isCancelling = true
    stopTimer()
    stopMetering(resetLevel: true)
    await audioRecordingService.cancelRecording()
    isPreparing = false
    isRecording = false
    isPaused = false
    isFinishing = false
    isCancelling = false
    errorMessage = nil
    shouldShowSettingsLink = false
    shouldShowSilencePrompt = false
    didAutoPauseForSilence = false
    sustainedSilenceDuration = 0
    elapsedTime = 0
  }

  func keepRecordingAfterSilencePrompt() {
    sustainedSilenceDuration = 0
    shouldShowSilencePrompt = false
    didAutoPauseForSilence = false
  }

  private func startTimer() {
    timerTask?.cancel()
    timerTask = Task { [weak self] in
      while !Task.isCancelled {
        try? await Task.sleep(nanoseconds: 1_000_000_000)

        await MainActor.run {
          guard let self, self.isRecording, !self.isPaused else { return }
          self.elapsedTime += 1
        }
      }
    }
  }

  private func stopTimer() {
    timerTask?.cancel()
    timerTask = nil
  }

  private func startMetering() {
    meteringTask?.cancel()
    let audioRecordingService = audioRecordingService
    let meteringInterval = meteringInterval
    let silenceLevelThreshold = silenceLevelThreshold
    let silencePromptThreshold = silencePromptThreshold
    let silenceAutoPauseThreshold = silenceAutoPauseThreshold

    meteringTask = Task { [weak self, audioRecordingService] in
      while !Task.isCancelled {
        let nextLevel = await audioRecordingService.currentAudioLevel()
        var shouldAutoPause = false

        await MainActor.run { [weak self] in
          guard
            let self,
            self.isRecording,
            !self.isPaused,
            !self.isFinishing,
            !self.isCancelling
          else { return }

          let smoothing = nextLevel > self.audioLevel ? 0.36 : 0.20
          self.audioLevel += (nextLevel - self.audioLevel) * smoothing
          self.updateSilenceState(
            nextLevel: nextLevel,
            interval: meteringInterval,
            levelThreshold: silenceLevelThreshold,
            promptThreshold: silencePromptThreshold,
            autoPauseThreshold: silenceAutoPauseThreshold
          )
          shouldAutoPause = self.didAutoPauseForSilence && !self.isPaused
        }

        if shouldAutoPause {
          await self?.pauseForContinuedSilence()
        }

        try? await Task.sleep(nanoseconds: UInt64(meteringInterval * 1_000_000_000))
      }
    }
  }

  private func stopMetering(resetLevel: Bool) {
    meteringTask?.cancel()
    meteringTask = nil

    if resetLevel {
      audioLevel = 0
    }
  }

  private func updateSilenceState(
    nextLevel: Double,
    interval: TimeInterval,
    levelThreshold: Double,
    promptThreshold: TimeInterval,
    autoPauseThreshold: TimeInterval
  ) {
    if nextLevel > levelThreshold {
      sustainedSilenceDuration = 0
      shouldShowSilencePrompt = false
      didAutoPauseForSilence = false
      return
    }

    sustainedSilenceDuration += interval

    if sustainedSilenceDuration >= promptThreshold {
      shouldShowSilencePrompt = true
    }

    if sustainedSilenceDuration >= autoPauseThreshold {
      didAutoPauseForSilence = true
      shouldShowSilencePrompt = false
    }
  }

  private func pauseForContinuedSilence() async {
    do {
      try await audioRecordingService.pauseRecording()
      await MainActor.run {
        guard isRecording, !isFinishing, !isCancelling else { return }
        isPaused = true
        stopMetering(resetLevel: true)
      }
    } catch {
      await MainActor.run {
        errorMessage = userFacingErrorMessage(
          for: error,
          fallback: "We could not pause this recording. Please try again."
        )
      }
    }
  }

  private func userFacingErrorMessage(
    for error: any Error,
    fallback: String
  ) -> String {
    if let recordingError = error as? AudioRecordingError {
      return recordingError.localizedDescription
    }

    return fallback
  }

  private func shouldShowSettingsLink(for error: any Error) -> Bool {
    guard let recordingError = error as? AudioRecordingError else { return false }
    return recordingError == .permissionDenied
  }
}
