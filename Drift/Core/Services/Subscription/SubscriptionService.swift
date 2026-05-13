//
//  SubscriptionService.swift
//  Drift
//
//  Created by Lucas Stuart West Rogers on 12/05/2026.
//

import Mockable

@Mockable
protocol SubscriptionService {
  func currentEntitlement() async throws -> SubscriptionEntitlement
  func refreshEntitlement() async throws -> SubscriptionEntitlement
  func isFeatureUnlocked(_ feature: PremiumFeature) async throws -> Bool
}
