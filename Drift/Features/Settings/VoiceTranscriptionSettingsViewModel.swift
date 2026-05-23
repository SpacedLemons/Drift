//
//  VoiceTranscriptionSettingsViewModel.swift
//  Drift
//
//  Created by Lucas Stuart West Rogers on 17/05/2026.
//

import Foundation
import Observation

@MainActor
@Observable
final class VoiceTranscriptionSettingsViewModel {
  @ObservationIgnored
  private let transcriptionService: any TranscriptionService & Sendable
  @ObservationIgnored
  private let audioRecordingService: any AudioRecordingService & Sendable

  private(set) var voiceRecognitionValue = "Checking"
  private(set) var speechPermissionStatus: PermissionStatus = .unknown
  private(set) var microphonePermissionStatus: PermissionStatus = .unknown

  init(
    transcriptionService: any TranscriptionService & Sendable,
    audioRecordingService: any AudioRecordingService & Sendable
  ) {
    self.transcriptionService = transcriptionService
    self.audioRecordingService = audioRecordingService
  }

  var speechPermissionStatusText: String {
    statusText(for: speechPermissionStatus)
  }

  var microphonePermissionStatusText: String {
    statusText(for: microphonePermissionStatus)
  }

  var shouldShowSystemSettingsLink: Bool {
    speechPermissionStatus == .denied || microphonePermissionStatus == .denied
  }

  func load() async {
    voiceRecognitionValue =
      transcriptionService.supportsOnDeviceTranscription
      ? "On-device available"
      : "Apple Speech fallback"
    speechPermissionStatus = await transcriptionService.currentPermissionStatus()
    microphonePermissionStatus = await audioRecordingService.currentPermissionStatus()
  }

  private func statusText(for status: PermissionStatus) -> String {
    switch status {
    case .unknown: "Not requested"
    case .granted: "Allowed"
    case .denied: "Off"
    case .restricted: "Restricted"
    }
  }
}
