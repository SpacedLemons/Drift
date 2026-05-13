//
//  ReminderServiceError.swift
//  Drift
//
//  Created by Lucas Stuart West Rogers on 13/05/2026.
//

import Foundation

enum ReminderServiceError: Error, Equatable, LocalizedError, Sendable {
  case permissionDenied
  case permissionRestricted
  case schedulingFailed
  case cancellationFailed
  case invalidConfiguration
  case unknownNotificationAction
  case routingFailed

  var errorDescription: String? {
    switch self {
    case .permissionDenied:
      "Notifications are off. You can enable them in iOS Settings if you want Drift to remind you."
    case .permissionRestricted:
      "Notifications are unavailable right now."
    case .schedulingFailed:
      "We could not schedule your reminder. Please try again."
    case .cancellationFailed:
      "We could not update your reminders. Please try again."
    case .invalidConfiguration:
      "We could not save this reminder. Please check the time and message."
    case .unknownNotificationAction:
      "We could not handle this reminder action."
    case .routingFailed:
      "Drift could not open the recording screen from this reminder."
    }
  }
}
