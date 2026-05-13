//
//  SubscriptionServiceTests.swift
//  DriftTests
//
//  Created by Lucas Stuart West Rogers on 12/05/2026.
//

import Testing

@testable import Drift

struct SubscriptionServiceTests {
  @Test
  func disabledSubscriptionServiceReturnsFreeEntitlement() async throws {
    let service = DisabledSubscriptionService()

    let entitlement = try await service.currentEntitlement()
    let isAIUnlocked = try await service.isFeatureUnlocked(.aiSummary)

    #expect(entitlement == .free)
    #expect(entitlement.isPremium == false)
    #expect(entitlement.unlockedFeatures.isEmpty)
    #expect(isAIUnlocked == false)
  }
}
