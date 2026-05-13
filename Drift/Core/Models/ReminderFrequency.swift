//
//  ReminderFrequency.swift
//  Drift
//
//  Created by Lucas Stuart West Rogers on 12/05/2026.
//

enum ReminderFrequency: String, CaseIterable, Identifiable, Codable, Hashable, Sendable {
  case daily
  case weekdays
  case weekends
  case custom

  var id: String { rawValue }

  var displayName: String {
    switch self {
    case .daily: "Daily"
    case .weekdays: "Weekdays"
    case .weekends: "Weekends"
    case .custom: "Custom"
    }
  }
}
