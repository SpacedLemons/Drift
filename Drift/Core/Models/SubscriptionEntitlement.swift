//
//  SubscriptionEntitlement.swift
//  Drift
//
//  Created by Lucas Stuart West Rogers on 12/05/2026.
//

struct SubscriptionEntitlement: Hashable, Codable, Sendable {
  var isPremium: Bool
  var unlockedFeatures: Set<PremiumFeature>

  static let free = SubscriptionEntitlement(
    isPremium: false,
    unlockedFeatures: []
  )
}

enum PremiumFeature: String, CaseIterable, Identifiable, Codable, Hashable, Sendable {
  case aiMood
  case aiSummary
  case smartReflections
  case semanticSearch
  case customThemes
  case customIcons
  case advancedInsights

  var id: String { rawValue }
}
