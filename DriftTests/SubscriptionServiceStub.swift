//
//  SubscriptionServiceStub.swift
//  DriftTests
//
//  Created by Lucas Stuart West Rogers on 16/05/2026.
//

import Foundation

@testable import Drift

actor SubscriptionServiceStub: SubscriptionService {
  private let entitlement: SubscriptionEntitlement
  private(set) var currentEntitlementCallCount = 0

  init(entitlement: SubscriptionEntitlement = .free) {
    self.entitlement = entitlement
  }

  func loadProducts() async throws -> [SubscriptionProduct] {
    SubscriptionProduct.Plan.allCases.map(SubscriptionProduct.fallback)
  }

  func purchase(product: SubscriptionProduct) async throws -> SubscriptionPurchaseResult {
    .completed(entitlement)
  }

  func restorePurchases() async throws -> SubscriptionRestoreResult {
    SubscriptionRestoreResult(
      entitlement: entitlement,
      restoredActiveSubscription: entitlement.isPremium
    )
  }

  func currentEntitlement() async throws -> SubscriptionEntitlement {
    currentEntitlementCallCount += 1
    return entitlement
  }

  func refreshEntitlement() async throws -> SubscriptionEntitlement {
    entitlement
  }

  func currentState() async throws -> SubscriptionState {
    SubscriptionState(
      entitlement: entitlement,
      status: entitlement.isPremium ? .active : .free,
      activeProductID: entitlement.activeProductID,
      expirationDate: entitlement.expirationDate,
      updatedAt: Date(timeIntervalSince1970: 1_779_000_000)
    )
  }

  func isFeatureUnlocked(_ feature: PremiumFeature) async throws -> Bool {
    entitlement.isFeatureUnlocked(feature)
  }
}

actor DailyEntryLimitServiceStub: DailyEntryLimitService {
  private let result: DailyEntryLimitResult

  init(result: DailyEntryLimitResult) {
    self.result = result
  }

  func evaluateNewEntryAccess() async throws -> DailyEntryLimitResult {
    result
  }

  func evaluateNewEntryAccess(on date: Date) async throws -> DailyEntryLimitResult {
    result
  }
}
