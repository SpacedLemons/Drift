//
//  DailyEntryLimitServiceTests.swift
//  DriftTests
//
//  Created by Lucas Stuart West Rogers on 16/05/2026.
//

import Foundation
import Testing

@testable import Drift

struct DailyEntryLimitServiceTests {
  @Test
  func freeUserCanCreateEntryUnderTenPerDay() async throws {
    let calendar = calendarForEntryLimitTests()
    let now = fixtureDate(calendar: calendar, year: 2026, month: 5, day: 16, hour: 12)
    let entries = makeEntries(
      count: 9,
      on: now,
      calendar: calendar
    )
    let service = makeService(
      entries: entries,
      entitlement: .free,
      calendar: calendar,
      now: now
    )

    let result = try await service.evaluateNewEntryAccess()

    #expect(result.canCreateEntry)
    #expect(result.entriesCreatedToday == 9)
    #expect(result.limit == 10)
  }

  @Test
  func freeUserIsBlockedAtTenPerDay() async throws {
    let calendar = calendarForEntryLimitTests()
    let now = fixtureDate(calendar: calendar, year: 2026, month: 5, day: 16, hour: 12)
    let service = makeService(
      entries: makeEntries(count: 10, on: now, calendar: calendar),
      entitlement: .free,
      calendar: calendar,
      now: now
    )

    let result = try await service.evaluateNewEntryAccess()

    #expect(!result.canCreateEntry)
    #expect(result.blockReason == .freeLimitReached)
    #expect(result.shouldOfferUpgrade)
    #expect(
      result.message
        == "You've used today's 10 free entries. Come back tomorrow or upgrade for more daily entries."
    )
  }

  @Test
  func plusUserCanCreateMoreThanTenPerDay() async throws {
    let calendar = calendarForEntryLimitTests()
    let now = fixtureDate(calendar: calendar, year: 2026, month: 5, day: 16, hour: 12)
    let service = makeService(
      entries: makeEntries(count: 42, on: now, calendar: calendar),
      entitlement: .plus(),
      calendar: calendar,
      now: now
    )

    let result = try await service.evaluateNewEntryAccess()

    #expect(result.canCreateEntry)
    #expect(result.entriesCreatedToday == 42)
    #expect(result.limit == 100)
  }

  @Test
  func plusUserIsBlockedAtOneHundredPerDay() async throws {
    let calendar = calendarForEntryLimitTests()
    let now = fixtureDate(calendar: calendar, year: 2026, month: 5, day: 16, hour: 12)
    let service = makeService(
      entries: makeEntries(count: 100, on: now, calendar: calendar),
      entitlement: .plus(),
      calendar: calendar,
      now: now
    )

    let result = try await service.evaluateNewEntryAccess()

    #expect(!result.canCreateEntry)
    #expect(result.blockReason == .plusLimitReached)
    #expect(!result.shouldOfferUpgrade)
    #expect(result.message == "You've reached today's entry limit. This helps keep Drift reliable.")
  }

  @Test
  func limitResetsByLocalCalendarDay() async throws {
    let calendar = calendarForEntryLimitTests()
    let now = fixtureDate(calendar: calendar, year: 2026, month: 5, day: 16, hour: 9)
    let yesterday = fixtureDate(calendar: calendar, year: 2026, month: 5, day: 15, hour: 23)
    let service = makeService(
      entries: makeEntries(count: 10, on: yesterday, calendar: calendar),
      entitlement: .free,
      calendar: calendar,
      now: now
    )

    let result = try await service.evaluateNewEntryAccess()

    #expect(result.canCreateEntry)
    #expect(result.entriesCreatedToday == 0)
  }

  @Test
  func existingEntriesRemainReadableEditableAndExportableWhenFreeLimitIsReached() async throws {
    let calendar = calendarForEntryLimitTests()
    let now = fixtureDate(calendar: calendar, year: 2026, month: 5, day: 16, hour: 12)
    let repository = PreviewJournalRepository(
      entries: makeEntries(count: 10, on: now, calendar: calendar)
    )
    let limitService = LocalDailyEntryLimitService(
      journalRepository: repository,
      subscriptionService: SubscriptionServiceStub(entitlement: .free),
      calendar: calendar,
      now: { now }
    )

    let result = try await limitService.evaluateNewEntryAccess()
    let existingEntries = try await repository.fetchEntries()
    var editedEntry = try #require(existingEntries.first)
    editedEntry.transcript = "Edited while at the daily limit."
    try await repository.updateEntry(editedEntry)
    let editedEntryFromRepository = try await repository.fetchEntry(id: editedEntry.id)
    let exportDirectory = FileManager.default.temporaryDirectory
      .appendingPathComponent("drift.limit.export.\(UUID().uuidString)", isDirectory: true)
    defer { try? FileManager.default.removeItem(at: exportDirectory) }
    let exportService = LocalMarkdownExportService(
      outputDirectory: exportDirectory,
      calendar: calendar,
      locale: Locale(identifier: "en_GB"),
      timeZone: calendar.timeZone
    )
    let exportURL = try await exportService.export(
      entries: existingEntries,
      exportedAt: now
    )

    #expect(!result.canCreateEntry)
    #expect(existingEntries.count == 10)
    #expect(editedEntryFromRepository?.transcript == "Edited while at the daily limit.")
    #expect(FileManager.default.fileExists(atPath: exportURL.path))
  }

  private func makeService(
    entries: [JournalEntry],
    entitlement: SubscriptionEntitlement,
    calendar: Calendar,
    now: Date
  ) -> LocalDailyEntryLimitService {
    LocalDailyEntryLimitService(
      journalRepository: PreviewJournalRepository(entries: entries),
      subscriptionService: SubscriptionServiceStub(entitlement: entitlement),
      calendar: calendar,
      now: { now }
    )
  }

  private func makeEntries(
    count: Int,
    on date: Date,
    calendar: Calendar
  ) -> [JournalEntry] {
    (0..<count).map { index in
      let entryDate = calendar.date(byAdding: .minute, value: index, to: date) ?? date
      return testJournalEntry(
        createdAt: entryDate,
        title: "Entry \(index)"
      )
    }
  }

  private func calendarForEntryLimitTests() -> Calendar {
    var calendar = Calendar(identifier: .gregorian)
    calendar.locale = Locale(identifier: "en_GB")
    calendar.timeZone = fixtureTimeZone(secondsFromGMT: 0)
    return calendar
  }
}
