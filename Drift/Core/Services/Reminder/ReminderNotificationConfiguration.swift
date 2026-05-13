//
//  ReminderNotificationConfiguration.swift
//  Drift
//
//  Created by Lucas Stuart West Rogers on 12/05/2026.
//

enum NotificationCategoryIdentifier {
  static let journalReminder = "journalReminder"
}

enum NotificationActionIdentifier {
  static let noteJournalEntry = "noteJournalEntry"
  static let remindLater = "remindLater"
  static let dismiss = "dismiss"
}

enum ReminderNotificationIdentifier {
  static let daily = "drift.reminder.daily"
  static let weekdayMonday = "drift.reminder.weekday.monday"
  static let weekdayTuesday = "drift.reminder.weekday.tuesday"
  static let weekdayWednesday = "drift.reminder.weekday.wednesday"
  static let weekdayThursday = "drift.reminder.weekday.thursday"
  static let weekdayFriday = "drift.reminder.weekday.friday"
  static let weekendSaturday = "drift.reminder.weekend.saturday"
  static let weekendSunday = "drift.reminder.weekend.sunday"
  static let snooze = "drift.reminder.snooze"

  static let main = [
    daily,
    weekdayMonday,
    weekdayTuesday,
    weekdayWednesday,
    weekdayThursday,
    weekdayFriday,
    weekendSaturday,
    weekendSunday,
  ]

  static let all = main + [snooze]
}

enum ReminderNotificationAction: String, CaseIterable, Identifiable, Sendable {
  case noteJournalEntry
  case remindLater
  case dismiss

  var id: String { rawValue }

  var title: String {
    switch self {
    case .noteJournalEntry: "Note journal entry"
    case .remindLater: "Remind me later"
    case .dismiss: "Not now"
    }
  }
}

enum ReminderNotificationActionResult: Equatable, Sendable {
  case startJournalEntry
  case snoozed
  case dismissed
}
