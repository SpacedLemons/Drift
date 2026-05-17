//
//  SubscriptionEntitlement.swift
//  Drift
//
//  Created by Lucas Stuart West Rogers on 12/05/2026.
//

import Foundation

struct SubscriptionEntitlement: Hashable, Codable, Sendable {
  var tier: SubscriptionTier
  var unlockedFeatures: Set<PremiumFeature>
  var activeProductID: String?
  var expirationDate: Date?

  var isPremium: Bool {
    tier == .plus
  }

  var dailyEntryLimit: Int {
    tier.dailyEntryLimit
  }

  static let free = SubscriptionEntitlement(
    tier: .free,
    unlockedFeatures: [],
    activeProductID: nil,
    expirationDate: nil
  )

  static func plus(
    activeProductID: String? = nil,
    expirationDate: Date? = nil
  ) -> SubscriptionEntitlement {
    SubscriptionEntitlement(
      tier: .plus,
      unlockedFeatures: Set(PremiumFeature.allCases),
      activeProductID: activeProductID,
      expirationDate: expirationDate
    )
  }

  func isFeatureUnlocked(_ feature: PremiumFeature) -> Bool {
    unlockedFeatures.contains(feature)
  }
}

enum SubscriptionTier: String, CaseIterable, Identifiable, Codable, Hashable, Sendable {
  case free
  case plus

  var id: String { rawValue }

  var displayName: String {
    switch self {
    case .free: "Free"
    case .plus: "Drift Plus"
    }
  }

  var dailyEntryLimit: Int {
    switch self {
    case .free: 10
    case .plus: 100
    }
  }
}

enum PremiumFeature: String, CaseIterable, Identifiable, Codable, Hashable, Sendable {
  case enhancedTranscription
  case aiSummary
  case askJournal
  case fullThemeBuilder
  case premiumExports
  case iCloudBackup
  case advancedInsights
  case customAppIcons

  var id: String { rawValue }
}

enum SubscriptionStatus: String, Codable, Hashable, Sendable {
  case free
  case active
  case expired
  case revoked
  case pending
  case unavailable
}

struct SubscriptionState: Hashable, Codable, Sendable {
  var entitlement: SubscriptionEntitlement
  var status: SubscriptionStatus
  var activeProductID: String?
  var expirationDate: Date?
  var updatedAt: Date

  static let free = SubscriptionState(
    entitlement: .free,
    status: .free,
    activeProductID: nil,
    expirationDate: nil,
    updatedAt: Date(timeIntervalSince1970: 0)
  )
}
