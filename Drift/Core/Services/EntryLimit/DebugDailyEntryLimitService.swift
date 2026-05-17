//
//  DebugDailyEntryLimitService.swift
//  Drift
//
//  Created by Lucas Stuart West Rogers on 16/05/2026.
//

#if DEBUG
  import Foundation

  actor DebugDailyEntryLimitService: DailyEntryLimitService {
    private let baseService: any DailyEntryLimitService & Sendable
    private let subscriptionService: any SubscriptionService & Sendable
    private let overrideStore: DebugEntitlementOverrideStore

    init(
      baseService: any DailyEntryLimitService & Sendable,
      subscriptionService: any SubscriptionService & Sendable,
      overrideStore: DebugEntitlementOverrideStore
    ) {
      self.baseService = baseService
      self.subscriptionService = subscriptionService
      self.overrideStore = overrideStore
    }

    func evaluateNewEntryAccess() async throws -> DailyEntryLimitResult {
      if let overrideResult = try await debugOverrideResult() {
        return overrideResult
      }

      return try await baseService.evaluateNewEntryAccess()
    }

    func evaluateNewEntryAccess(on date: Date) async throws -> DailyEntryLimitResult {
      if let overrideResult = try await debugOverrideResult() {
        return overrideResult
      }

      return try await baseService.evaluateNewEntryAccess(on: date)
    }

    private func debugOverrideResult() async throws -> DailyEntryLimitResult? {
      let settings = await overrideStore.loadSettings()
      let entitlement = try await subscriptionService.currentEntitlement()

      if settings.simulateFreeEntryLimitReached, !entitlement.isPremium {
        return .blocked(
          entitlement: .free,
          entriesCreatedToday: SubscriptionTier.free.dailyEntryLimit
        )
      }

      if settings.simulatePlusEntryLimitReached, entitlement.isPremium {
        return .blocked(
          entitlement: .plus(),
          entriesCreatedToday: SubscriptionTier.plus.dailyEntryLimit
        )
      }

      return nil
    }
  }
#endif
