//
//  UnavailableReminderService.swift
//  Drift
//
//  Created by Lucas Stuart West Rogers on 12/05/2026.
//

final class UnavailableReminderService: ReminderService, Sendable {
  func loadReminderConfiguration() async throws -> ReminderConfiguration {
    .default
  }

  func saveReminderConfiguration(_ configuration: ReminderConfiguration) async throws {
    throw DriftServiceError.unavailable("Local reminders are not wired yet.")
  }

  func currentPermissionStatus() async -> PermissionStatus {
    .unknown
  }

  func requestPermission() async throws {
    throw DriftServiceError.unavailable("Local reminders are not wired yet.")
  }

  func scheduleReminder(configuration: ReminderConfiguration) async throws {
    throw DriftServiceError.unavailable("Local reminders are not wired yet.")
  }

  func scheduleRemindLater() async throws {
    throw DriftServiceError.unavailable("Local reminders are not wired yet.")
  }

  func cancelReminder() async throws {
    throw DriftServiceError.unavailable("Local reminders are not wired yet.")
  }

  func registerNotificationActions() {}

  func handleNotificationAction(identifier: String) async throws -> ReminderNotificationActionResult
  {
    throw DriftServiceError.unavailable("Local reminders are not wired yet.")
  }
}
