//
//  DisabledSubscriptionService.swift
//  Drift
//
//  Created by Lucas Stuart West Rogers on 12/05/2026.
//

final class DisabledSubscriptionService: SubscriptionService, Sendable {
  func loadProducts() async throws -> [SubscriptionProduct] {
    SubscriptionProduct.Plan.allCases.map(SubscriptionProduct.fallback)
  }

  func purchase(product: SubscriptionProduct) async throws -> SubscriptionPurchaseResult {
    throw SubscriptionServiceError.productsUnavailable
  }

  func restorePurchases() async throws -> SubscriptionRestoreResult {
    SubscriptionRestoreResult(entitlement: .free, restoredActiveSubscription: false)
  }

  func currentEntitlement() async throws -> SubscriptionEntitlement {
    .free
  }

  func refreshEntitlement() async throws -> SubscriptionEntitlement {
    .free
  }

  func currentState() async throws -> SubscriptionState {
    .free
  }

  func isFeatureUnlocked(_ feature: PremiumFeature) async throws -> Bool {
    false
  }
}
