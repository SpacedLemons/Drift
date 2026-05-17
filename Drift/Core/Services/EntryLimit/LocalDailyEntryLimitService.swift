//
//  LocalDailyEntryLimitService.swift
//  Drift
//
//  Created by Lucas Stuart West Rogers on 16/05/2026.
//

import Foundation

actor LocalDailyEntryLimitService: DailyEntryLimitService {
  private let journalRepository: any JournalRepository & Sendable
  private let subscriptionService: any SubscriptionService & Sendable
  private let calendar: Calendar
  private let now: @Sendable () -> Date

  init(
    journalRepository: any JournalRepository & Sendable,
    subscriptionService: any SubscriptionService & Sendable,
    calendar: Calendar = .current,
    now: @escaping @Sendable () -> Date = Date.init
  ) {
    self.journalRepository = journalRepository
    self.subscriptionService = subscriptionService
    self.calendar = calendar
    self.now = now
  }

  func evaluateNewEntryAccess() async throws -> DailyEntryLimitResult {
    try await evaluateNewEntryAccess(on: now())
  }

  func evaluateNewEntryAccess(on date: Date) async throws -> DailyEntryLimitResult {
    do {
      let entitlement = try await subscriptionService.currentEntitlement()
      let entries = try await journalRepository.fetchEntries()
      let entriesCreatedToday = entries.filter { entry in
        calendar.isDate(entry.createdAt, inSameDayAs: date)
      }.count

      guard entriesCreatedToday < entitlement.dailyEntryLimit else {
        return .blocked(
          entitlement: entitlement,
          entriesCreatedToday: entriesCreatedToday
        )
      }

      return .allowed(
        entitlement: entitlement,
        entriesCreatedToday: entriesCreatedToday
      )
    } catch {
      throw DailyEntryLimitError.calculationFailed
    }
  }
}
