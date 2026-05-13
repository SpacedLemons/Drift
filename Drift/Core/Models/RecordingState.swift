//
//  RecordingState.swift
//  Drift
//
//  Created by Lucas Stuart West Rogers on 12/05/2026.
//

import Foundation

enum RecordingState: Hashable, Sendable {
  case idle
  case requestingPermission
  case preparing
  case recording(startedAt: Date)
  case paused(elapsed: TimeInterval)
  case finishing
  case cancelling
  case cancelled
  case failed(message: String)
}
