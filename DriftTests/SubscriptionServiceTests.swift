//
//  SubscriptionServiceTests.swift
//  DriftTests
//
//  Created by Lucas Stuart West Rogers on 12/05/2026.
//

import Foundation
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

  @Test
  func entitlementDefaultsToFreeEntryLimitAndLockedFeatures() async throws {
    let entitlement = SubscriptionEntitlement.free

    #expect(entitlement.tier == .free)
    #expect(entitlement.dailyEntryLimit == 10)
    #expect(!entitlement.isFeatureUnlocked(.askJournal))
    #expect(!entitlement.isFeatureUnlocked(.premiumExports))
  }

  @Test
  func plusEntitlementUnlocksFuturePaidFeatures() async throws {
    let entitlement = SubscriptionEntitlement.plus(activeProductID: "drift.plus.monthly")

    #expect(entitlement.tier == .plus)
    #expect(entitlement.dailyEntryLimit == 100)
    #expect(entitlement.isFeatureUnlocked(.enhancedTranscription))
    #expect(entitlement.isFeatureUnlocked(.aiSummary))
    #expect(entitlement.isFeatureUnlocked(.askJournal))
    #expect(entitlement.isFeatureUnlocked(.fullThemeBuilder))
    #expect(entitlement.isFeatureUnlocked(.premiumExports))
    #expect(entitlement.isFeatureUnlocked(.iCloudBackup))
    #expect(entitlement.isFeatureUnlocked(.advancedInsights))
    #expect(entitlement.isFeatureUnlocked(.customAppIcons))
  }

  #if DEBUG
    @Test
    func debugForceFreeReturnsFreeEntitlement() async throws {
      let defaults = UserDefaults(suiteName: "drift.tests.\(UUID().uuidString)") ?? .standard
      let store = DebugEntitlementOverrideStore(userDefaults: defaults)
      await store.saveMode(.forceFree)
      let service = DebugSubscriptionService(
        baseService: SubscriptionServiceStub(entitlement: .plus()),
        overrideStore: store
      )

      let entitlement = try await service.currentEntitlement()

      #expect(entitlement == .free)
    }

    @Test
    func debugForcePlusReturnsPlusEntitlement() async throws {
      let defaults = UserDefaults(suiteName: "drift.tests.\(UUID().uuidString)") ?? .standard
      let store = DebugEntitlementOverrideStore(userDefaults: defaults)
      await store.saveMode(.forcePlus)
      let service = DebugSubscriptionService(
        baseService: SubscriptionServiceStub(entitlement: .free),
        overrideStore: store
      )

      let entitlement = try await service.currentEntitlement()

      #expect(entitlement.tier == .plus)
      #expect(entitlement.dailyEntryLimit == 100)
    }

    @Test
    func debugRealStoreKitModeDelegatesToBaseService() async throws {
      let defaults = UserDefaults(suiteName: "drift.tests.\(UUID().uuidString)") ?? .standard
      let store = DebugEntitlementOverrideStore(userDefaults: defaults)
      await store.saveMode(.realStoreKit)
      let baseService = SubscriptionServiceStub(entitlement: .plus())
      let service = DebugSubscriptionService(
        baseService: baseService,
        overrideStore: store
      )

      let entitlement = try await service.currentEntitlement()
      let callCount = await baseService.currentEntitlementCallCount

      #expect(entitlement.tier == .plus)
      #expect(callCount == 1)
    }
  #endif
}
