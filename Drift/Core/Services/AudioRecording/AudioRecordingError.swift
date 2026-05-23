//
//  AudioRecordingError.swift
//  Drift
//
//  Created by Lucas Stuart West Rogers on 12/05/2026.
//

import Foundation

enum AudioRecordingError: Error, Equatable, LocalizedError, Sendable {
  case permissionDenied
  case permissionUnavailable
  case sessionConfigurationFailed
  case startFailed
  case stopFailed
  case missingAudioFile
  case interrupted
  case cleanupFailed

  var errorDescription: String? {
    switch self {
    case .permissionDenied:
      "Drift needs microphone access so you can record voice-first Drifts. You can enable it in Settings."
    case .permissionUnavailable:
      "Microphone recording is not available on this device."
    case .sessionConfigurationFailed:
      "We could not prepare the microphone. Please try again."
    case .startFailed:
      "We could not start recording. Please try again."
    case .stopFailed:
      "We could not finish this recording. Please try again."
    case .missingAudioFile:
      "We could not prepare this recording. Please try again."
    case .interrupted:
      "Recording was interrupted."
    case .cleanupFailed:
      "We could not delete this temporary recording."
    }
  }
}
