//
//  ReminderConfiguration.swift
//  Drift
//
//  Created by Lucas Stuart West Rogers on 12/05/2026.
//

import Foundation

struct ReminderConfiguration: Hashable, Codable, Sendable {
  var isEnabled: Bool
  var time: DateComponents
  var repeatFrequency: ReminderFrequency
  var message: String

  static let `default` = ReminderConfiguration(
    isEnabled: false,
    time: DateComponents(hour: 20, minute: 30),
    repeatFrequency: .daily,
    message: "Take a moment to drift."
  )
}
