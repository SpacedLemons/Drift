//
//  AppNotificationDelegate.swift
//  Drift
//
//  Created by Lucas Stuart West Rogers on 13/05/2026.
//

import Foundation
import UserNotifications

final class AppNotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
  private let reminderService: any ReminderService & Sendable
  private let launchActionStore: AppLaunchActionStore

  init(
    reminderService: any ReminderService & Sendable,
    launchActionStore: AppLaunchActionStore
  ) {
    self.reminderService = reminderService
    self.launchActionStore = launchActionStore
    super.init()
  }

  func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification
  ) async -> UNNotificationPresentationOptions {
    [.banner, .list, .sound]
  }

  func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse
  ) async {
    do {
      let result = try await reminderService.handleNotificationAction(
        identifier: response.actionIdentifier
      )
      await handleNotificationActionResult(result)
    } catch {
      await launchActionStore.reportRoutingError()
    }
  }

  @MainActor
  private func handleNotificationActionResult(_ result: ReminderNotificationActionResult) {
    switch result {
    case .startJournalEntry:
      launchActionStore.enqueue(.startJournalEntry)
    case .snoozed, .dismissed:
      break
    }
  }
}
