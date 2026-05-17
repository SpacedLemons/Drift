//
//  SubscriptionService.swift
//  Drift
//
//  Created by Lucas Stuart West Rogers on 12/05/2026.
//

import Mockable

@Mockable
protocol SubscriptionService {
  func loadProducts() async throws -> [SubscriptionProduct]
  func purchase(product: SubscriptionProduct) async throws -> SubscriptionPurchaseResult
  func restorePurchases() async throws -> SubscriptionRestoreResult
  func currentEntitlement() async throws -> SubscriptionEntitlement
  func refreshEntitlement() async throws -> SubscriptionEntitlement
  func currentState() async throws -> SubscriptionState
  func isFeatureUnlocked(_ feature: PremiumFeature) async throws -> Bool
}
