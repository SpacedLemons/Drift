//
//  DailyEntryLimitService.swift
//  Drift
//
//  Created by Lucas Stuart West Rogers on 16/05/2026.
//

import Foundation
import Mockable

@Mockable
protocol DailyEntryLimitService {
  func evaluateNewEntryAccess() async throws -> DailyEntryLimitResult
  func evaluateNewEntryAccess(on date: Date) async throws -> DailyEntryLimitResult
}

struct DailyEntryLimitResult: Equatable, Sendable {
  enum BlockReason: Equatable, Sendable {
    case freeLimitReached
    case plusLimitReached
  }

  let canCreateEntry: Bool
  let entitlement: SubscriptionEntitlement
  let entriesCreatedToday: Int
  let limit: Int
  let blockReason: BlockReason?

  var shouldOfferUpgrade: Bool {
    blockReason == .freeLimitReached
  }

  var message: String {
    switch blockReason {
    case .freeLimitReached:
      "You've used today's 10 free Drifts. Come back tomorrow or upgrade for more daily Drifts."
    case .plusLimitReached:
      "You've reached today's Drift limit. This helps keep Drift reliable."
    case nil:
      "You can create a new Drift."
    }
  }

  static func allowed(
    entitlement: SubscriptionEntitlement,
    entriesCreatedToday: Int
  ) -> DailyEntryLimitResult {
    DailyEntryLimitResult(
      canCreateEntry: true,
      entitlement: entitlement,
      entriesCreatedToday: entriesCreatedToday,
      limit: entitlement.dailyEntryLimit,
      blockReason: nil
    )
  }

  static func blocked(
    entitlement: SubscriptionEntitlement,
    entriesCreatedToday: Int
  ) -> DailyEntryLimitResult {
    DailyEntryLimitResult(
      canCreateEntry: false,
      entitlement: entitlement,
      entriesCreatedToday: entriesCreatedToday,
      limit: entitlement.dailyEntryLimit,
      blockReason: entitlement.isPremium ? .plusLimitReached : .freeLimitReached
    )
  }
}

enum DailyEntryLimitError: Error, LocalizedError, Sendable {
  case calculationFailed

  var errorDescription: String? {
    switch self {
    case .calculationFailed:
      "We couldn't check today's Drift limit. Please try again."
    }
  }
}
