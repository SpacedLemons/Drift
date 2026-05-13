//
//  AudioPlaybackService.swift
//  Drift
//
//  Created by Lucas Stuart West Rogers on 13/05/2026.
//

import Foundation
import Mockable

struct AudioPlaybackMetadata: Hashable, Sendable {
  var duration: TimeInterval
}

@Mockable
protocol AudioPlaybackService {
  func prepare(url: URL) async throws -> AudioPlaybackMetadata
  func play() async throws
  func pause() async
  func stop() async
  func currentTime() async -> TimeInterval
  func isPlaying() async -> Bool
}
