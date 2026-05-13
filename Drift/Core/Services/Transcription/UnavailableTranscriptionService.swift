//
//  UnavailableTranscriptionService.swift
//  Drift
//
//  Created by Lucas Stuart West Rogers on 12/05/2026.
//

import Foundation

final class UnavailableTranscriptionService: TranscriptionService, Sendable {
  var supportsOnDeviceTranscription: Bool { false }

  func currentPermissionStatus() async -> PermissionStatus {
    .unknown
  }

  func requestPermission() async throws {
    throw DriftServiceError.unavailable("Transcription is not wired yet.")
  }

  func transcribe(audioURL: URL) async throws -> String {
    throw DriftServiceError.unavailable("Transcription is not wired yet.")
  }
}
