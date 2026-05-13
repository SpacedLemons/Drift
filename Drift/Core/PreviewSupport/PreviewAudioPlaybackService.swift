//
//  PreviewAudioPlaybackService.swift
//  Drift
//
//  Created by Lucas Stuart West Rogers on 13/05/2026.
//

import Foundation

actor PreviewAudioPlaybackService: AudioPlaybackService {
  private var preparedDuration: TimeInterval
  private var playbackTime: TimeInterval = 0
  private var playing = false

  init(duration: TimeInterval = 72) {
    preparedDuration = duration
  }

  func prepare(url: URL) async throws -> AudioPlaybackMetadata {
    AudioPlaybackMetadata(duration: preparedDuration)
  }

  func play() async throws {
    playing = true
  }

  func pause() async {
    playing = false
  }

  func stop() async {
    playing = false
    playbackTime = 0
  }

  func currentTime() async -> TimeInterval {
    if playing {
      playbackTime = min(preparedDuration, playbackTime + 1)
    }

    return playbackTime
  }

  func isPlaying() async -> Bool {
    playing
  }
}
