//
//  DisabledSubscriptionService.swift
//  Drift
//
//  Created by Lucas Stuart West Rogers on 12/05/2026.
//

final class DisabledSubscriptionService: SubscriptionService, Sendable {
  func currentEntitlement() async throws -> SubscriptionEntitlement {
    .free
  }

  func refreshEntitlement() async throws -> SubscriptionEntitlement {
    .free
  }

  func isFeatureUnlocked(_ feature: PremiumFeature) async throws -> Bool {
    false
  }
}
