//
//  RecordingViewModelTests.swift
//  DriftTests
//
//  Created by Lucas Stuart West Rogers on 12/05/2026.
//

import Foundation
import Mockable
import Testing

@testable import Drift

@MainActor
struct RecordingViewModelTests {
  @Test
  func initialStateIsReady() {
    let viewModel = RecordingViewModel(audioRecordingService: MockAudioRecordingService())

    #expect(viewModel.elapsedTime == 0)
    #expect(viewModel.formattedElapsedTime == "00:00")
    #expect(viewModel.audioLevel == 0)
    #expect(!viewModel.isRecording)
    #expect(!viewModel.isPaused)
    #expect(!viewModel.isPreparing)
    #expect(!viewModel.isFinishing)
    #expect(!viewModel.isCancelling)
    #expect(viewModel.errorMessage == nil)
    #expect(viewModel.statusText == "Ready")
  }

  @Test
  func startShowsPreparingThenStartsRecording() async throws {
    let service = MockAudioRecordingService()
    given(service)
      .startRecording().willReturn()
      .currentAudioLevel().willReturn(0)

    let viewModel = RecordingViewModel(audioRecordingService: service)

    await viewModel.start()

    #expect(viewModel.isRecording)
    #expect(!viewModel.isPaused)
    #expect(!viewModel.isPreparing)
    #expect(viewModel.errorMessage == nil)
    #expect(viewModel.statusText == "Recording")
    verify(service)
      .startRecording().called(.once)
  }

  @Test
  func startSurfacesPermissionDeniedError() async throws {
    let service = MockAudioRecordingService()
    given(service)
      .startRecording().willThrow(AudioRecordingError.permissionDenied)

    let viewModel = RecordingViewModel(audioRecordingService: service)

    await viewModel.start()

    #expect(!viewModel.isRecording)
    #expect(!viewModel.isPreparing)
    #expect(viewModel.errorMessage == AudioRecordingError.permissionDenied.localizedDescription)
    #expect(viewModel.shouldShowSettingsLink)
    verify(service)
      .startRecording().called(.once)
  }

  @Test
  func startSurfacesRecordingFailure() async throws {
    let service = MockAudioRecordingService()
    given(service)
      .startRecording().willThrow(AudioRecordingError.startFailed)

    let viewModel = RecordingViewModel(audioRecordingService: service)

    await viewModel.start()

    #expect(!viewModel.isRecording)
    #expect(!viewModel.isPreparing)
    #expect(viewModel.errorMessage == AudioRecordingError.startFailed.localizedDescription)
    #expect(!viewModel.shouldShowSettingsLink)
  }

  @Test
  func startUsesGenericCopyForUnexpectedRecordingErrors() async throws {
    let service = MockAudioRecordingService()
    given(service)
      .startRecording().willThrow(TestRecordingError.failed)

    let viewModel = RecordingViewModel(audioRecordingService: service)

    await viewModel.start()

    #expect(viewModel.errorMessage == "We could not start recording. Please try again.")
    #expect(!viewModel.shouldShowSettingsLink)
  }

  @Test
  func startPublishesPreparingWhileRecorderStarts() async throws {
    let service = DelayedAudioRecordingService()
    let viewModel = RecordingViewModel(audioRecordingService: service)

    let startTask = Task {
      await viewModel.start()
    }

    while !service.hasStarted {
      await Task.yield()
    }

    #expect(viewModel.isPreparing)
    #expect(viewModel.statusText == "Preparing")

    service.finishStart()
    await startTask.value

    #expect(viewModel.isRecording)
    #expect(!viewModel.isPreparing)
  }

  @Test
  func togglePausePausesAndResumesRecording() async throws {
    let service = MockAudioRecordingService()
    given(service)
      .startRecording().willReturn()
      .pauseRecording().willReturn()
      .resumeRecording().willReturn()
      .currentAudioLevel().willReturn(0)

    let viewModel = RecordingViewModel(audioRecordingService: service)
    await viewModel.start()

    await viewModel.togglePause()
    #expect(viewModel.isPaused)
    #expect(viewModel.statusText == "Paused")

    await viewModel.togglePause()
    #expect(!viewModel.isPaused)
    #expect(viewModel.statusText == "Recording")

    verify(service)
      .pauseRecording().called(.once)
      .resumeRecording().called(.once)
  }

  @Test
  func finishStopsRecordingAndReturnsAudioURL() async throws {
    let audioURL = URL(fileURLWithPath: "/tmp/drift-test-recording.m4a")
    let finishedAt = Date(timeIntervalSince1970: 100)
    let service = MockAudioRecordingService()
    given(service)
      .startRecording().willReturn()
      .stopRecording().willReturn(audioURL)
      .currentAudioLevel().willReturn(0.8)

    let viewModel = RecordingViewModel(
      audioRecordingService: service,
      now: { finishedAt }
    )
    await viewModel.start()
    try await Task.sleep(nanoseconds: 120_000_000)

    #expect(viewModel.audioLevel > 0)

    let result = await viewModel.finish()

    #expect(result?.audioURL == audioURL)
    #expect(result?.duration == 1)
    #expect(result?.finishedAt == finishedAt)
    #expect(viewModel.audioLevel == 0)
    #expect(!viewModel.isRecording)
    #expect(!viewModel.isFinishing)
    verify(service)
      .stopRecording().called(.once)
  }

  @Test
  func finishPublishesFinishingAndIgnoresDuplicateFinish() async throws {
    let service = DelayedStopAudioRecordingService()
    let viewModel = RecordingViewModel(audioRecordingService: service)

    await viewModel.start()

    let firstFinishTask = Task {
      await viewModel.finish()
    }

    while !service.hasStartedStopping {
      await Task.yield()
    }

    #expect(viewModel.isFinishing)
    #expect(viewModel.statusText == "Finishing")

    let duplicateResult = await viewModel.finish()
    #expect(duplicateResult == nil)
    #expect(service.stopCount == 1)

    service.finishStop()
    let result = await firstFinishTask.value

    #expect(result?.audioURL == service.audioURL)
    #expect(!viewModel.isFinishing)
  }

  @Test
  func cancelStopsTimerAndCancelsRecording() async throws {
    let service = MockAudioRecordingService()
    given(service)
      .startRecording().willReturn()
      .cancelRecording().willReturn()
      .currentAudioLevel().willReturn(0)

    let viewModel = RecordingViewModel(audioRecordingService: service)
    await viewModel.start()

    await viewModel.cancel()

    #expect(!viewModel.isRecording)
    #expect(!viewModel.isPaused)
    #expect(viewModel.elapsedTime == 0)
    #expect(viewModel.statusText == "Ready")
    verify(service)
      .cancelRecording().called(.once)
  }

  @Test
  func cancelResetsAudioLevelAndIgnoresDuplicateCancel() async throws {
    let service = DelayedCancelAudioRecordingService()
    let viewModel = RecordingViewModel(audioRecordingService: service)

    await viewModel.start()
    try await Task.sleep(nanoseconds: 120_000_000)

    #expect(viewModel.audioLevel > 0)

    let firstCancelTask = Task {
      await viewModel.cancel()
    }

    while !service.hasStartedCancelling {
      await Task.yield()
    }

    #expect(viewModel.isCancelling)

    await viewModel.cancel()
    #expect(service.cancelCount == 1)

    service.finishCancel()
    await firstCancelTask.value

    #expect(viewModel.audioLevel == 0)
    #expect(!viewModel.isCancelling)
  }

  @Test
  func meteringUpdatesAudioLevelWhileRecording() async throws {
    let service = MockAudioRecordingService()
    given(service)
      .startRecording().willReturn()
      .cancelRecording().willReturn()
      .currentAudioLevel().willReturn(0.8)

    let viewModel = RecordingViewModel(audioRecordingService: service)
    await viewModel.start()

    try await Task.sleep(nanoseconds: 120_000_000)

    #expect(viewModel.audioLevel > 0)
    await viewModel.cancel()
  }

  @Test
  func silencePromptTriggersAfterThreshold() async throws {
    let service = MockAudioRecordingService()
    given(service)
      .startRecording().willReturn()
      .cancelRecording().willReturn()
      .currentAudioLevel().willReturn(0)
    let viewModel = RecordingViewModel(
      audioRecordingService: service,
      silencePromptThreshold: 0.08,
      silenceAutoPauseThreshold: 1,
      meteringInterval: 0.04
    )

    await viewModel.start()
    try await Task.sleep(nanoseconds: 160_000_000)

    #expect(viewModel.shouldShowSilencePrompt)
    await viewModel.cancel()
  }

  @Test
  func keepRecordingDismissesSilencePrompt() async throws {
    let service = MockAudioRecordingService()
    given(service)
      .startRecording().willReturn()
      .cancelRecording().willReturn()
      .currentAudioLevel().willReturn(0)
    let viewModel = RecordingViewModel(
      audioRecordingService: service,
      silencePromptThreshold: 0.08,
      silenceAutoPauseThreshold: 1,
      meteringInterval: 0.04
    )

    await viewModel.start()
    try await Task.sleep(nanoseconds: 160_000_000)
    viewModel.keepRecordingAfterSilencePrompt()

    #expect(!viewModel.shouldShowSilencePrompt)
    await viewModel.cancel()
  }

  @Test
  func continuedSilenceAutoPausesRecording() async throws {
    let service = MockAudioRecordingService()
    given(service)
      .startRecording().willReturn()
      .pauseRecording().willReturn()
      .cancelRecording().willReturn()
      .currentAudioLevel().willReturn(0)
    let viewModel = RecordingViewModel(
      audioRecordingService: service,
      silencePromptThreshold: 0.04,
      silenceAutoPauseThreshold: 0.12,
      meteringInterval: 0.04
    )

    await viewModel.start()
    try await Task.sleep(nanoseconds: 220_000_000)

    #expect(viewModel.isPaused)
    #expect(!viewModel.shouldShowSilencePrompt)
    verify(service)
      .pauseRecording().called(.once)
    await viewModel.cancel()
  }
}

private enum TestRecordingError: Error {
  case failed
}

private final class DelayedStopAudioRecordingService: AudioRecordingService, @unchecked Sendable {
  let audioURL = URL(fileURLWithPath: "/tmp/drift-delayed-stop-recording.m4a")
  var recordingState: RecordingState { .idle }

  private let lock = NSLock()
  private var stopContinuation: CheckedContinuation<URL, Never>?
  private var didStartStopping = false
  private var recordedStopCount = 0

  var hasStartedStopping: Bool {
    lock.lock()
    defer { lock.unlock() }
    return didStartStopping
  }

  var stopCount: Int {
    lock.lock()
    defer { lock.unlock() }
    return recordedStopCount
  }

  func requestPermission() async throws {}

  func currentPermissionStatus() async -> PermissionStatus {
    .granted
  }

  func startRecording() async throws {}

  func pauseRecording() async throws {}

  func resumeRecording() async throws {}

  func stopRecording() async throws -> URL {
    await withCheckedContinuation { continuation in
      lock.lock()
      didStartStopping = true
      recordedStopCount += 1
      stopContinuation = continuation
      lock.unlock()
    }
  }

  func cancelRecording() async {}

  func currentAudioLevel() async -> Double {
    0
  }

  func finishStop() {
    lock.lock()
    let continuation = stopContinuation
    stopContinuation = nil
    lock.unlock()
    continuation?.resume(returning: audioURL)
  }
}

private final class DelayedCancelAudioRecordingService: AudioRecordingService, @unchecked Sendable {
  var recordingState: RecordingState { .idle }

  private let lock = NSLock()
  private var cancelContinuation: CheckedContinuation<Void, Never>?
  private var didStartCancelling = false
  private var recordedCancelCount = 0

  var hasStartedCancelling: Bool {
    lock.lock()
    defer { lock.unlock() }
    return didStartCancelling
  }

  var cancelCount: Int {
    lock.lock()
    defer { lock.unlock() }
    return recordedCancelCount
  }

  func requestPermission() async throws {}

  func currentPermissionStatus() async -> PermissionStatus {
    .granted
  }

  func startRecording() async throws {}

  func pauseRecording() async throws {}

  func resumeRecording() async throws {}

  func stopRecording() async throws -> URL {
    URL(fileURLWithPath: "/tmp/drift-delayed-cancel-recording.m4a")
  }

  func cancelRecording() async {
    await withCheckedContinuation { continuation in
      lock.lock()
      didStartCancelling = true
      recordedCancelCount += 1
      cancelContinuation = continuation
      lock.unlock()
    }
  }

  func currentAudioLevel() async -> Double {
    0.8
  }

  func finishCancel() {
    lock.lock()
    let continuation = cancelContinuation
    cancelContinuation = nil
    lock.unlock()
    continuation?.resume()
  }
}

private final class DelayedAudioRecordingService: AudioRecordingService, @unchecked Sendable {
  var recordingState: RecordingState { .idle }

  private let lock = NSLock()
  private var startContinuation: CheckedContinuation<Void, Never>?
  private var didStart = false

  var hasStarted: Bool {
    lock.lock()
    defer { lock.unlock() }
    return didStart
  }

  func requestPermission() async throws {}

  func currentPermissionStatus() async -> PermissionStatus {
    .granted
  }

  func startRecording() async throws {
    await withCheckedContinuation { continuation in
      lock.lock()
      didStart = true
      startContinuation = continuation
      lock.unlock()
    }
  }

  func pauseRecording() async throws {}

  func resumeRecording() async throws {}

  func stopRecording() async throws -> URL {
    URL(fileURLWithPath: "/tmp/drift-delayed-recording.m4a")
  }

  func cancelRecording() async {
    finishStart()
  }

  func currentAudioLevel() async -> Double {
    0
  }

  func finishStart() {
    lock.lock()
    let continuation = startContinuation
    startContinuation = nil
    lock.unlock()
    continuation?.resume()
  }
}
