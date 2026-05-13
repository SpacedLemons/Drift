//
//  RecordingResult.swift
//  Drift
//
//  Created by Lucas Stuart West Rogers on 12/05/2026.
//

import Foundation

struct RecordingResult: Hashable, Sendable {
  var audioURL: URL
  var duration: TimeInterval
  var finishedAt: Date
}
