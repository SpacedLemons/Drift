//
//  VoiceTranscriptionSettingsViewModelTests.swift
//  DriftTests
//
//  Created by Lucas Stuart West Rogers on 17/05/2026.
//

import Foundation
import Testing

@testable import Drift

@MainActor
struct VoiceTranscriptionSettingsViewModelTests {
  @Test
  func loadShowsOnDeviceAndPermissionState() async throws {
    let viewModel = VoiceTranscriptionSettingsViewModel(
      transcriptionService: VoiceTranscriptionServiceStub(
        supportsOnDeviceTranscription: true,
        permissionStatus: .granted
      ),
      audioRecordingService: VoiceAudioRecordingServiceStub(permissionStatus: .granted)
    )

    await viewModel.load()

    #expect(viewModel.voiceRecognitionValue == "On-device available")
    #expect(viewModel.speechPermissionStatus == .granted)
    #expect(viewModel.speechPermissionStatusText == "Allowed")
    #expect(viewModel.microphonePermissionStatus == .granted)
    #expect(viewModel.microphonePermissionStatusText == "Allowed")
    #expect(!viewModel.shouldShowSystemSettingsLink)
  }

  @Test
  func loadShowsFallbackAndSettingsLinkWhenPermissionIsDenied() async throws {
    let viewModel = VoiceTranscriptionSettingsViewModel(
      transcriptionService: VoiceTranscriptionServiceStub(
        supportsOnDeviceTranscription: false,
        permissionStatus: .denied
      ),
      audioRecordingService: VoiceAudioRecordingServiceStub(permissionStatus: .unknown)
    )

    await viewModel.load()

    #expect(viewModel.voiceRecognitionValue == "Apple Speech fallback")
    #expect(viewModel.speechPermissionStatusText == "Off")
    #expect(viewModel.microphonePermissionStatusText == "Not requested")
    #expect(viewModel.shouldShowSystemSettingsLink)
  }
}

private struct VoiceTranscriptionServiceStub: TranscriptionService, Sendable {
  let supportsOnDeviceTranscription: Bool
  let permissionStatus: PermissionStatus

  func currentPermissionStatus() async -> PermissionStatus {
    permissionStatus
  }

  func requestPermission() async throws {}

  func transcribe(audioURL: URL) async throws -> String {
    throw TranscriptionError.transcriptionFailed
  }
}

private struct VoiceAudioRecordingServiceStub: AudioRecordingService, Sendable {
  let permissionStatus: PermissionStatus
  var recordingState: RecordingState { .idle }

  func currentPermissionStatus() async -> PermissionStatus {
    permissionStatus
  }

  func requestPermission() async throws {}

  func startRecording() async throws {}

  func pauseRecording() async throws {}

  func resumeRecording() async throws {}

  func stopRecording() async throws -> URL {
    URL(fileURLWithPath: "/tmp/drift-voice-test.m4a")
  }

  func cancelRecording() async {}

  func currentAudioLevel() async -> Double {
    0
  }
}
