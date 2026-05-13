//
//  JournalHomeViewModelTests.swift
//  DriftTests
//
//  Created by Lucas Stuart West Rogers on 12/05/2026.
//

import Foundation
import Mockable
import Testing

@testable import Drift

@MainActor
struct JournalHomeViewModelTests {
  @Test
  func loadPopulatesEntriesFromRepository() async throws {
    let repository = MockJournalRepository()
    given(repository)
      .fetchEntries()
      .willReturn(PreviewData.journalEntries)

    let viewModel = JournalHomeViewModel(
      journalRepository: repository,
      now: { PreviewData.baseDate }
    )

    await viewModel.load()

    #expect(viewModel.visibleEntries.count == PreviewData.journalEntries.count)
    #expect(!viewModel.shouldShowFirstRunIntro)
    verify(repository)
      .fetchEntries()
      .called(.once)
  }

  @Test
  func loadHandlesEmptyEntries() async throws {
    let repository = MockJournalRepository()
    given(repository)
      .fetchEntries()
      .willReturn([])

    let viewModel = JournalHomeViewModel(journalRepository: repository)

    await viewModel.load()

    #expect(viewModel.visibleEntries.isEmpty)
    #expect(viewModel.errorMessage == nil)
    #expect(viewModel.shouldShowFirstRunIntro)
  }

  @Test
  func searchFiltersEntriesLocally() async throws {
    let repository = MockJournalRepository()
    given(repository)
      .fetchEntries()
      .willReturn(PreviewData.journalEntries)

    let viewModel = JournalHomeViewModel(
      journalRepository: repository,
      now: { PreviewData.baseDate }
    )

    await viewModel.load()
    viewModel.applySearchQuery("stressed")

    #expect(viewModel.visibleEntries.count == 1)
    #expect(viewModel.visibleEntries.first?.mood == .stressed)
  }

  @Test
  func searchIsCaseInsensitive() async throws {
    let repository = MockJournalRepository()
    given(repository)
      .fetchEntries()
      .willReturn(PreviewData.journalEntries)

    let viewModel = JournalHomeViewModel(
      journalRepository: repository,
      now: { PreviewData.baseDate }
    )

    await viewModel.load()
    viewModel.applySearchQuery("STRESSED")

    #expect(viewModel.visibleEntries.count == 1)
    #expect(viewModel.visibleEntries.first?.mood == .stressed)
  }

  @Test
  func searchTrimsWhitespace() async throws {
    let repository = MockJournalRepository()
    given(repository)
      .fetchEntries()
      .willReturn(PreviewData.journalEntries)

    let viewModel = JournalHomeViewModel(
      journalRepository: repository,
      now: { PreviewData.baseDate }
    )

    await viewModel.load()
    viewModel.applySearchQuery("  stressed  ")

    #expect(viewModel.visibleEntries.count == 1)
    #expect(viewModel.visibleEntries.first?.mood == .stressed)
  }

  @Test
  func clearingSearchRestoresVisibleEntries() async throws {
    let repository = MockJournalRepository()
    given(repository)
      .fetchEntries()
      .willReturn(PreviewData.journalEntries)

    let viewModel = JournalHomeViewModel(
      journalRepository: repository,
      now: { PreviewData.baseDate }
    )

    await viewModel.load()
    viewModel.applySearchQuery("stressed")
    viewModel.applySearchQuery("")

    #expect(viewModel.visibleEntries.count == PreviewData.journalEntries.count)
  }

  @Test
  func reloadReflectsRepositoryChanges() async throws {
    let repository = PreviewJournalRepository(entries: [PreviewData.journalEntries[0]])
    let viewModel = JournalHomeViewModel(
      journalRepository: repository,
      now: { PreviewData.baseDate }
    )

    await viewModel.load()
    #expect(viewModel.visibleEntries.count == 1)

    try await repository.saveEntry(PreviewData.journalEntries[1])
    await viewModel.load()

    #expect(viewModel.visibleEntries.count == 2)
  }

  @Test
  func calendarStartsCollapsedOnCurrentMonth() async throws {
    let calendar = calendarForTests()
    let now = fixtureDate(calendar: calendar, year: 2026, month: 5, day: 13)
    let viewModel = JournalHomeViewModel(
      journalRepository: PreviewJournalRepository(entries: []),
      calendar: calendar,
      now: { now }
    )

    #expect(!viewModel.isCalendarExpanded)
    #expect(calendar.component(.year, from: viewModel.selectedMonth) == 2026)
    #expect(calendar.component(.month, from: viewModel.selectedMonth) == 5)
    #expect(calendar.component(.day, from: viewModel.selectedMonth) == 1)
  }

  @Test
  func toggleCalendarExpansionChangesState() async throws {
    let viewModel = JournalHomeViewModel(
      journalRepository: PreviewJournalRepository(entries: []),
      now: { PreviewData.baseDate }
    )

    viewModel.toggleCalendarExpansion()

    #expect(viewModel.isCalendarExpanded)

    viewModel.toggleCalendarExpansion()

    #expect(!viewModel.isCalendarExpanded)
  }

  @Test
  func monthNavigationChangesSelectedMonth() async throws {
    let calendar = calendarForTests()
    let now = fixtureDate(calendar: calendar, year: 2026, month: 5, day: 13)
    let viewModel = JournalHomeViewModel(
      journalRepository: PreviewJournalRepository(entries: []),
      calendar: calendar,
      now: { now }
    )

    viewModel.moveSelectedMonth(by: -12)

    #expect(calendar.component(.year, from: viewModel.selectedMonth) == 2025)
    #expect(calendar.component(.month, from: viewModel.selectedMonth) == 5)

    viewModel.moveSelectedMonth(by: 13)

    #expect(calendar.component(.year, from: viewModel.selectedMonth) == 2026)
    #expect(calendar.component(.month, from: viewModel.selectedMonth) == 6)
  }

  @Test
  func calendarDaysMarkDatesWithEntries() async throws {
    let calendar = calendarForTests()
    let entryDate = fixtureDate(calendar: calendar, year: 2026, month: 5, day: 13)
    let viewModel = JournalHomeViewModel(
      journalRepository: PreviewJournalRepository(
        entries: [journalEntry(on: entryDate, title: "Marked")]
      ),
      calendar: calendar,
      now: { entryDate }
    )

    await viewModel.load()

    let markedDay = try #require(viewModel.calendarDays.first { $0.dayNumber == 13 })
    let unmarkedDay = try #require(viewModel.calendarDays.first { $0.dayNumber == 14 })

    #expect(markedDay.hasEntries)
    #expect(!unmarkedDay.hasEntries)
  }

  @Test
  func selectDateFiltersEntriesAndMovesSelectedMonth() async throws {
    let calendar = calendarForTests()
    let now = fixtureDate(calendar: calendar, year: 2026, month: 5, day: 13)
    let selectedDate = fixtureDate(calendar: calendar, year: 2025, month: 2, day: 4)
    let matchingEntry = journalEntry(on: selectedDate, title: "Old entry")
    let hiddenEntry = journalEntry(
      on: fixtureDate(calendar: calendar, year: 2026, month: 5, day: 13),
      title: "Today"
    )
    let viewModel = JournalHomeViewModel(
      journalRepository: PreviewJournalRepository(entries: [matchingEntry, hiddenEntry]),
      calendar: calendar,
      now: { now }
    )

    await viewModel.load()
    viewModel.selectDate(selectedDate)

    #expect(viewModel.visibleEntries == [matchingEntry])
    #expect(calendar.component(.year, from: viewModel.selectedMonth) == 2025)
    #expect(calendar.component(.month, from: viewModel.selectedMonth) == 2)
  }

  @Test
  func selectedDateHasNoEntriesWorksForEmptyDay() async throws {
    let calendar = calendarForTests()
    let now = fixtureDate(calendar: calendar, year: 2026, month: 5, day: 13)
    let emptyDate = fixtureDate(calendar: calendar, year: 2026, month: 5, day: 14)
    let viewModel = JournalHomeViewModel(
      journalRepository: PreviewJournalRepository(
        entries: [journalEntry(on: now, title: "Today")]
      ),
      calendar: calendar,
      now: { now }
    )

    await viewModel.load()
    viewModel.selectDate(emptyDate)

    #expect(viewModel.visibleEntries.isEmpty)
    #expect(viewModel.selectedDateHasNoEntries)
  }

  @Test
  func loadSurfacesRepositoryFetchError() async throws {
    let repository = MockJournalRepository()
    given(repository)
      .fetchEntries()
      .willThrow(JournalRepositoryError.fetchFailed)

    let viewModel = JournalHomeViewModel(journalRepository: repository)

    await viewModel.load()

    #expect(viewModel.visibleEntries.isEmpty)
    #expect(viewModel.errorMessage == JournalRepositoryError.fetchFailed.localizedDescription)
  }

  @Test
  func loadUsesGenericCopyForUnexpectedRepositoryErrors() async throws {
    let repository = MockJournalRepository()
    given(repository)
      .fetchEntries()
      .willThrow(TestJournalHomeRepositoryError.failed)

    let viewModel = JournalHomeViewModel(journalRepository: repository)

    await viewModel.load()

    #expect(viewModel.visibleEntries.isEmpty)
    #expect(viewModel.errorMessage == "We could not load your journal.")
  }
}

private enum TestJournalHomeRepositoryError: Error {
  case failed
}

private func calendarForTests() -> Calendar {
  var calendar = Calendar(identifier: .gregorian)
  calendar.timeZone = fixtureTimeZone(secondsFromGMT: 0)
  calendar.firstWeekday = 2
  return calendar
}

private func journalEntry(on date: Date, title: String) -> JournalEntry {
  JournalEntry(
    id: UUID(),
    createdAt: date,
    transcript: title,
    title: title,
    mood: .neutral,
    themes: [],
    tags: []
  )
}
