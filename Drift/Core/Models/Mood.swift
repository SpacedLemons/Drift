//
//  Mood.swift
//  Drift
//
//  Created by Lucas Stuart West Rogers on 12/05/2026.
//

enum Mood: String, CaseIterable, Identifiable, Codable, Hashable, Sendable {
  case positive
  case neutral
  case low
  case anxious
  case stressed
  case reflective
  case unknown

  var id: String { rawValue }

  var displayName: String {
    switch self {
    case .positive: "Positive"
    case .neutral: "Neutral"
    case .low: "Low"
    case .anxious: "Anxious"
    case .stressed: "Stressed"
    case .reflective: "Reflective"
    case .unknown: "Unknown"
    }
  }

  /// Local trend score for visualising broad mood direction. This is not a medical score.
  var trendScore: Double? {
    switch self {
    case .positive: 5
    case .reflective: 4
    case .neutral: 3
    case .anxious: 2
    case .stressed: 2
    case .low: 1
    case .unknown: nil
    }
  }
}
