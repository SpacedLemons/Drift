//
//  TranscriptionError.swift
//  Drift
//
//  Created by Lucas Stuart West Rogers on 12/05/2026.
//

import Foundation

enum TranscriptionError: Error, Equatable, LocalizedError, Sendable {
  case permissionDenied
  case permissionRestricted
  case recognizerUnavailable
  case onDeviceRecognitionUnavailable
  case transcriptionFailed
  case emptyResult
  case unsupportedLocale
  case missingAudioFile
  case cleanupFailed

  var errorDescription: String? {
    switch self {
    case .permissionDenied:
      "Drift uses speech recognition to turn your voice journal entries into text. You can enable it in Settings."
    case .permissionRestricted:
      "Speech recognition is restricted on this device."
    case .recognizerUnavailable:
      "Speech recognition is unavailable for this language or device."
    case .onDeviceRecognitionUnavailable:
      "On-device transcription is unavailable for this language or device."
    case .transcriptionFailed:
      "We could not transcribe this recording. You can try again or type it manually."
    case .emptyResult:
      "We couldn't hear anything clearly. You can try again or write the entry manually."
    case .unsupportedLocale:
      "Speech recognition is unavailable for this language."
    case .missingAudioFile:
      "We could not find this recording. You can try again or type the entry manually."
    case .cleanupFailed:
      "We could not delete the temporary audio file."
    }
  }
}
