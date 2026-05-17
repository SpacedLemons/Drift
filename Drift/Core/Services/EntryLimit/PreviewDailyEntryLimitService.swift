//
//  PreviewDailyEntryLimitService.swift
//  Drift
//
//  Created by Lucas Stuart West Rogers on 16/05/2026.
//

import Foundation

actor PreviewDailyEntryLimitService: DailyEntryLimitService {
  private var result: DailyEntryLimitResult

  init(
    result: DailyEntryLimitResult = .allowed(
      entitlement: .free,
      entriesCreatedToday: 0
    )
  ) {
    self.result = result
  }

  func evaluateNewEntryAccess() async throws -> DailyEntryLimitResult {
    result
  }

  func evaluateNewEntryAccess(on date: Date) async throws -> DailyEntryLimitResult {
    result
  }
}
