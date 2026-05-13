//
//  UnavailableAudioRecordingService.swift
//  Drift
//
//  Created by Lucas Stuart West Rogers on 12/05/2026.
//

import Foundation

final class UnavailableAudioRecordingService: AudioRecordingService, Sendable {
  var recordingState: RecordingState { .idle }

  func requestPermission() async throws {
    throw DriftServiceError.unavailable("Voice recording is not wired yet.")
  }

  func startRecording() async throws {
    throw DriftServiceError.unavailable("Voice recording is not wired yet.")
  }

  func pauseRecording() async throws {
    throw DriftServiceError.unavailable("Voice recording is not wired yet.")
  }

  func resumeRecording() async throws {
    throw DriftServiceError.unavailable("Voice recording is not wired yet.")
  }

  func stopRecording() async throws -> URL {
    throw DriftServiceError.unavailable("Voice recording is not wired yet.")
  }

  func cancelRecording() async {}

  func currentAudioLevel() async -> Double {
    0
  }
}
