//
//  AVAudioPlaybackService.swift
//  Drift
//
//  Created by Lucas Stuart West Rogers on 13/05/2026.
//

import AVFoundation
import Foundation

actor AVAudioPlaybackService: AudioPlaybackService {
  private var player: AVAudioPlayer?

  func prepare(url: URL) async throws -> AudioPlaybackMetadata {
    guard FileManager.default.fileExists(atPath: url.path) else {
      throw AudioPlaybackError.unavailable
    }

    do {
      let player = try AVAudioPlayer(contentsOf: url)
      player.prepareToPlay()
      self.player = player
      return AudioPlaybackMetadata(duration: player.duration)
    } catch {
      throw AudioPlaybackError.failedToPrepare
    }
  }

  func play() async throws {
    guard let player else {
      throw AudioPlaybackError.unavailable
    }

    guard player.play() else {
      throw AudioPlaybackError.failedToPlay
    }
  }

  func pause() async {
    player?.pause()
  }

  func stop() async {
    player?.stop()
    player?.currentTime = 0
  }

  func currentTime() async -> TimeInterval {
    player?.currentTime ?? 0
  }

  func isPlaying() async -> Bool {
    player?.isPlaying ?? false
  }
}
