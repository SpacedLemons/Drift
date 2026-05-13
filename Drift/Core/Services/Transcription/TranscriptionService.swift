//
//  TranscriptionService.swift
//  Drift
//
//  Created by Lucas Stuart West Rogers on 12/05/2026.
//

import Foundation
import Mockable

@Mockable
protocol TranscriptionService {
  var supportsOnDeviceTranscription: Bool { get }

  func currentPermissionStatus() async -> PermissionStatus
  func requestPermission() async throws
  func transcribe(audioURL: URL) async throws -> String
}
