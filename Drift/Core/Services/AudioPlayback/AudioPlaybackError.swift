//
//  AudioPlaybackError.swift
//  Drift
//
//  Created by Lucas Stuart West Rogers on 13/05/2026.
//

import Foundation

enum AudioPlaybackError: LocalizedError, Equatable {
  case unavailable
  case failedToPrepare
  case failedToPlay

  var errorDescription: String? {
    switch self {
    case .unavailable:
      "This temporary recording is unavailable."
    case .failedToPrepare:
      "We could not prepare this recording for playback."
    case .failedToPlay:
      "We could not play this recording."
    }
  }
}
