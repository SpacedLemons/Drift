//
//  JournalTheme.swift
//  Drift
//
//  Created by Lucas Stuart West Rogers on 12/05/2026.
//

enum JournalTheme: String, CaseIterable, Identifiable, Codable, Hashable, Sendable {
  case productivity
  case relationships
  case health
  case money
  case growth
  case work
  case family
  case gratitude
  case challenge
  case other

  var id: String { rawValue }

  var displayName: String {
    switch self {
    case .productivity: "Productivity"
    case .relationships: "Relationships"
    case .health: "Health"
    case .money: "Money"
    case .growth: "Growth"
    case .work: "Work"
    case .family: "Family"
    case .gratitude: "Gratitude"
    case .challenge: "Challenge"
    case .other: "Other"
    }
  }
}
