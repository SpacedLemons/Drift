//
//  AudioRecordingService.swift
//  Drift
//
//  Created by Lucas Stuart West Rogers on 12/05/2026.
//

import Foundation
import Mockable

@Mockable
protocol AudioRecordingService {
  var recordingState: RecordingState { get }

  func currentPermissionStatus() async -> PermissionStatus
  func requestPermission() async throws
  func startRecording() async throws
  func pauseRecording() async throws
  func resumeRecording() async throws
  func stopRecording() async throws -> URL
  func cancelRecording() async
  func currentAudioLevel() async -> Double
}
