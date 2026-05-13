//
//  ReminderService.swift
//  Drift
//
//  Created by Lucas Stuart West Rogers on 12/05/2026.
//

import Mockable

@Mockable
protocol ReminderService {
  func loadReminderConfiguration() async throws -> ReminderConfiguration
  func saveReminderConfiguration(_ configuration: ReminderConfiguration) async throws
  func currentPermissionStatus() async -> PermissionStatus
  func requestPermission() async throws
  func scheduleReminder(configuration: ReminderConfiguration) async throws
  func scheduleRemindLater() async throws
  func cancelReminder() async throws
  func registerNotificationActions()
  func handleNotificationAction(identifier: String) async throws -> ReminderNotificationActionResult
}
