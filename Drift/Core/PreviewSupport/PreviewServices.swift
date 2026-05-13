//
//  PreviewServices.swift
//  Drift
//
//  Created by Lucas Stuart West Rogers on 12/05/2026.
//

import Foundation
import UserNotifications

final class PreviewAudioRecordingService: AudioRecordingService, @unchecked Sendable {
  private(set) var recordingState: RecordingState = .idle

  func requestPermission() async throws {}

  func startRecording() async throws {
    recordingState = .recording(startedAt: PreviewData.baseDate)
  }

  func pauseRecording() async throws {
    recordingState = .paused(elapsed: 12)
  }

  func resumeRecording() async throws {
    recordingState = .recording(startedAt: PreviewData.baseDate)
  }

  func stopRecording() async throws -> URL {
    recordingState = .idle
    return URL(fileURLWithPath: "/tmp/drift-preview-recording.m4a")
  }

  func cancelRecording() async {
    recordingState = .cancelled
  }

  func currentAudioLevel() async -> Double {
    0.36
  }
}

final class PreviewTranscriptionService: TranscriptionService, Sendable {
  var supportsOnDeviceTranscription: Bool { true }

  func currentPermissionStatus() async -> PermissionStatus {
    .granted
  }

  func requestPermission() async throws {}

  func transcribe(audioURL: URL) async throws -> String {
    "I felt focused today after clearing my inbox. The quiet morning helped me settle into the work without rushing. I want to keep this momentum tomorrow but make sure I do not overload myself."
  }
}

final class PreviewMoodAnalysisService: MoodAnalysisService, Sendable {
  func suggestMood(from transcript: String) async throws -> Mood {
    .positive
  }

  func suggestThemes(from transcript: String) async throws -> [JournalTheme] {
    [.productivity, .work, .growth]
  }
}

actor PreviewReminderService: ReminderService {
  private var configuration: ReminderConfiguration
  private var permissionStatus: PermissionStatus
  private(set) var didScheduleRemindLater = false

  init(
    configuration: ReminderConfiguration = .default,
    permissionStatus: PermissionStatus = .granted
  ) {
    self.configuration = configuration
    self.permissionStatus = permissionStatus
  }

  func loadReminderConfiguration() async throws -> ReminderConfiguration {
    configuration
  }

  func saveReminderConfiguration(_ configuration: ReminderConfiguration) async throws {
    self.configuration = configuration
  }

  func currentPermissionStatus() async -> PermissionStatus {
    permissionStatus
  }

  func requestPermission() async throws {
    permissionStatus = .granted
  }

  func scheduleReminder(configuration: ReminderConfiguration) async throws {
    self.configuration = configuration
  }

  func scheduleRemindLater() async throws {
    didScheduleRemindLater = true
  }

  func cancelReminder() async throws {
    configuration.isEnabled = false
  }

  nonisolated func registerNotificationActions() {}

  func handleNotificationAction(identifier: String) async throws -> ReminderNotificationActionResult
  {
    switch identifier {
    case NotificationActionIdentifier.noteJournalEntry, UNNotificationDefaultActionIdentifier:
      return .startJournalEntry
    case NotificationActionIdentifier.remindLater:
      try await scheduleRemindLater()
      return .snoozed
    case NotificationActionIdentifier.dismiss, UNNotificationDismissActionIdentifier:
      return .dismissed
    default:
      throw ReminderServiceError.unknownNotificationAction
    }
  }
}
