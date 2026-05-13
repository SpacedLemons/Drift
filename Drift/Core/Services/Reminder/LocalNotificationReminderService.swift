//
//  LocalNotificationReminderService.swift
//  Drift
//
//  Created by Lucas Stuart West Rogers on 13/05/2026.
//

import Foundation
import UserNotifications

actor LocalNotificationReminderService: ReminderService {
  private let userDefaults: UserDefaults
  private let notificationCenter: UNUserNotificationCenter
  private let configurationKey: String
  private let snoozeDuration: TimeInterval

  init(
    userDefaults: UserDefaults = .standard,
    notificationCenter: UNUserNotificationCenter = .current(),
    configurationKey: String = "drift.reminder.configuration",
    snoozeDuration: TimeInterval = 3_600
  ) {
    self.userDefaults = userDefaults
    self.notificationCenter = notificationCenter
    self.configurationKey = configurationKey
    self.snoozeDuration = snoozeDuration
  }

  func loadReminderConfiguration() async throws -> ReminderConfiguration {
    guard let data = userDefaults.data(forKey: configurationKey) else {
      return .default
    }

    return (try? JSONDecoder().decode(ReminderConfiguration.self, from: data)) ?? .default
  }

  func saveReminderConfiguration(_ configuration: ReminderConfiguration) async throws {
    do {
      let data = try JSONEncoder().encode(configuration.normalizedForNotifications())
      userDefaults.set(data, forKey: configurationKey)
    } catch {
      throw ReminderServiceError.invalidConfiguration
    }
  }

  func currentPermissionStatus() async -> PermissionStatus {
    await notificationCenter.notificationSettings().permissionStatus
  }

  func requestPermission() async throws {
    let status = await currentPermissionStatus()

    switch status {
    case .granted:
      return
    case .denied:
      throw ReminderServiceError.permissionDenied
    case .restricted:
      throw ReminderServiceError.permissionRestricted
    case .unknown:
      let isGranted = try await notificationCenter.requestAuthorization(options: [.alert, .sound])
      guard isGranted else { throw ReminderServiceError.permissionDenied }
    }
  }

  func scheduleReminder(configuration: ReminderConfiguration) async throws {
    let configuration = configuration.normalizedForNotifications()
    guard configuration.isEnabled else {
      try await saveReminderConfiguration(configuration)
      return
    }

    try await requireNotificationPermission()
    registerNotificationActions()

    do {
      let requests = try makeReminderRequests(configuration: configuration)
      notificationCenter.removePendingNotificationRequests(
        withIdentifiers: ReminderNotificationIdentifier.main
      )

      for request in requests {
        try await notificationCenter.add(request)
      }

      try await saveReminderConfiguration(configuration)
    } catch let error as ReminderServiceError {
      notificationCenter.removePendingNotificationRequests(
        withIdentifiers: ReminderNotificationIdentifier.main
      )
      throw error
    } catch {
      notificationCenter.removePendingNotificationRequests(
        withIdentifiers: ReminderNotificationIdentifier.main
      )
      throw ReminderServiceError.schedulingFailed
    }
  }

  func scheduleRemindLater() async throws {
    try await requireNotificationPermission()
    registerNotificationActions()

    let configuration = (try? await loadReminderConfiguration()) ?? .default
    let content = makeNotificationContent(message: configuration.message)
    let trigger = UNTimeIntervalNotificationTrigger(timeInterval: snoozeDuration, repeats: false)
    let request = UNNotificationRequest(
      identifier: ReminderNotificationIdentifier.snooze,
      content: content,
      trigger: trigger
    )

    do {
      notificationCenter.removePendingNotificationRequests(
        withIdentifiers: [ReminderNotificationIdentifier.snooze]
      )
      try await notificationCenter.add(request)
    } catch {
      throw ReminderServiceError.schedulingFailed
    }
  }

  func cancelReminder() async throws {
    do {
      notificationCenter.removePendingNotificationRequests(
        withIdentifiers: ReminderNotificationIdentifier.all
      )
      var configuration = try await loadReminderConfiguration()
      configuration.isEnabled = false
      try await saveReminderConfiguration(configuration)
    } catch {
      throw ReminderServiceError.cancellationFailed
    }
  }

  nonisolated func registerNotificationActions() {
    let noteAction = UNNotificationAction(
      identifier: NotificationActionIdentifier.noteJournalEntry,
      title: ReminderNotificationAction.noteJournalEntry.title,
      options: [.foreground]
    )
    let remindLaterAction = UNNotificationAction(
      identifier: NotificationActionIdentifier.remindLater,
      title: ReminderNotificationAction.remindLater.title,
      options: []
    )
    let dismissAction = UNNotificationAction(
      identifier: NotificationActionIdentifier.dismiss,
      title: ReminderNotificationAction.dismiss.title,
      options: []
    )
    let category = UNNotificationCategory(
      identifier: NotificationCategoryIdentifier.journalReminder,
      actions: [noteAction, remindLaterAction, dismissAction],
      intentIdentifiers: [],
      options: []
    )

    UNUserNotificationCenter.current().setNotificationCategories([category])
  }

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

  private func requireNotificationPermission() async throws {
    switch await currentPermissionStatus() {
    case .granted:
      return
    case .denied:
      throw ReminderServiceError.permissionDenied
    case .restricted:
      throw ReminderServiceError.permissionRestricted
    case .unknown:
      try await requestPermission()
    }
  }

  private func makeReminderRequests(
    configuration: ReminderConfiguration
  ) throws -> [UNNotificationRequest] {
    switch configuration.repeatFrequency {
    case .daily:
      [
        try makeCalendarRequest(
          identifier: ReminderNotificationIdentifier.daily,
          configuration: configuration
        )
      ]
    case .weekdays:
      try [
        (ReminderNotificationIdentifier.weekdayMonday, 2),
        (ReminderNotificationIdentifier.weekdayTuesday, 3),
        (ReminderNotificationIdentifier.weekdayWednesday, 4),
        (ReminderNotificationIdentifier.weekdayThursday, 5),
        (ReminderNotificationIdentifier.weekdayFriday, 6),
      ].map { identifier, weekday in
        try makeCalendarRequest(
          identifier: identifier,
          configuration: configuration,
          weekday: weekday
        )
      }
    case .weekends:
      try [
        (ReminderNotificationIdentifier.weekendSaturday, 7),
        (ReminderNotificationIdentifier.weekendSunday, 1),
      ].map { identifier, weekday in
        try makeCalendarRequest(
          identifier: identifier,
          configuration: configuration,
          weekday: weekday
        )
      }
    case .custom:
      throw ReminderServiceError.invalidConfiguration
    }
  }

  private func makeCalendarRequest(
    identifier: String,
    configuration: ReminderConfiguration,
    weekday: Int? = nil
  ) throws -> UNNotificationRequest {
    let content = makeNotificationContent(message: configuration.message)
    let components = try makeDateComponents(
      configuration: configuration,
      weekday: weekday
    )
    let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)

    return UNNotificationRequest(
      identifier: identifier,
      content: content,
      trigger: trigger
    )
  }

  private func makeNotificationContent(message: String) -> UNMutableNotificationContent {
    let content = UNMutableNotificationContent()
    content.title = "Drift"
    content.body = ReminderConfiguration.normalizedMessage(message)
    content.sound = .default
    content.categoryIdentifier = NotificationCategoryIdentifier.journalReminder
    return content
  }

  private func makeDateComponents(
    configuration: ReminderConfiguration,
    weekday: Int?
  ) throws -> DateComponents {
    guard
      let hour = configuration.time.hour,
      let minute = configuration.time.minute,
      (0...23).contains(hour),
      (0...59).contains(minute)
    else {
      throw ReminderServiceError.invalidConfiguration
    }

    var components = DateComponents()
    components.calendar = Calendar.current
    components.timeZone = .current
    components.hour = hour
    components.minute = minute
    components.weekday = weekday
    return components
  }
}

extension ReminderConfiguration {
  fileprivate static func normalizedMessage(_ message: String) -> String {
    let trimmedMessage = message.trimmingCharacters(in: .whitespacesAndNewlines)
    return trimmedMessage.isEmpty ? Self.default.message : trimmedMessage
  }

  fileprivate func normalizedForNotifications() -> ReminderConfiguration {
    ReminderConfiguration(
      isEnabled: isEnabled,
      time: DateComponents(hour: time.hour, minute: time.minute),
      repeatFrequency: repeatFrequency,
      message: Self.normalizedMessage(message)
    )
  }
}

extension UNNotificationSettings {
  fileprivate var permissionStatus: PermissionStatus {
    switch authorizationStatus {
    case .authorized, .provisional, .ephemeral: .granted
    case .denied: .denied
    case .notDetermined: .unknown
    @unknown default: .restricted
    }
  }
}
