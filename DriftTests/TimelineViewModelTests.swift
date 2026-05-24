//
//  TimelineViewModelTests.swift
//  DriftTests
//
//  Created by Lucas Stuart West Rogers on 23/05/2026.
//

import Foundation
import Testing

@testable import Drift

@MainActor
struct TimelineViewModelTests {
  @Test
  func timelineLoadsHistoricalDrifts() async throws {
    let entries = [
      JournalEntry(
        id: fixtureUUID("E1000000-0000-0000-0000-000000000001"),
        createdAt: Date(timeIntervalSince1970: 1_778_600_000),
        transcript: "Recent",
        driftType: .thought
      ),
      JournalEntry(
        id: fixtureUUID("E1000000-0000-0000-0000-000000000002"),
        createdAt: Date(timeIntervalSince1970: 1_778_500_000),
        transcript: "Older",
        driftType: .memory
      ),
    ]
    let viewModel = TimelineViewModel(
      journalRepository: PreviewJournalRepository(entries: entries),
      now: { Date(timeIntervalSince1970: 1_778_600_000) }
    )

    await viewModel.load()

    #expect(viewModel.visibleEntries.map(\.id) == entries.map(\.id))
  }

  @Test
  func timelineFiltersByDateAndDriftType() async throws {
    let calendar = calendarForTimelineTests()
    let selectedDate = fixtureDate(calendar: calendar, year: 2026, month: 5, day: 23)
    let matchingEntry = JournalEntry(
      id: fixtureUUID("E1000000-0000-0000-0000-000000000003"),
      createdAt: selectedDate,
      transcript: "Goal",
      driftType: .goal
    )
    let wrongTypeEntry = JournalEntry(
      id: fixtureUUID("E1000000-0000-0000-0000-000000000004"),
      createdAt: selectedDate.addingTimeInterval(60),
      transcript: "Thought",
      driftType: .thought
    )
    let wrongDateEntry = JournalEntry(
      id: fixtureUUID("E1000000-0000-0000-0000-000000000005"),
      createdAt: fixtureDate(calendar: calendar, year: 2026, month: 5, day: 22),
      transcript: "Old goal",
      driftType: .goal
    )
    let viewModel = TimelineViewModel(
      journalRepository: PreviewJournalRepository(
        entries: [matchingEntry, wrongTypeEntry, wrongDateEntry]
      ),
      calendar: calendar,
      now: { selectedDate }
    )

    await viewModel.load()
    viewModel.selectDate(selectedDate)
    viewModel.selectDriftTypeFilter(.goal)

    #expect(viewModel.visibleEntries == [matchingEntry])
  }

  @Test
  func calendarStartsExpandedOnCurrentMonth() async throws {
    let calendar = calendarForTimelineTests()
    let now = fixtureDate(calendar: calendar, year: 2026, month: 5, day: 13)
    let viewModel = TimelineViewModel(
      journalRepository: PreviewJournalRepository(entries: []),
      calendar: calendar,
      now: { now }
    )

    #expect(viewModel.isCalendarExpanded)
    #expect(viewModel.selectedDate == nil)
    #expect(calendar.component(.year, from: viewModel.selectedMonth) == 2026)
    #expect(calendar.component(.month, from: viewModel.selectedMonth) == 5)
    #expect(calendar.component(.day, from: viewModel.selectedMonth) == 1)
  }

  @Test
  func toggleCalendarExpansionChangesState() async throws {
    let viewModel = TimelineViewModel(
      journalRepository: PreviewJournalRepository(entries: []),
      now: { PreviewData.baseDate }
    )

    viewModel.toggleCalendarExpansion()

    #expect(!viewModel.isCalendarExpanded)

    viewModel.toggleCalendarExpansion()

    #expect(viewModel.isCalendarExpanded)
  }

  @Test
  func monthNavigationChangesSelectedMonth() async throws {
    let calendar = calendarForTimelineTests()
    let now = fixtureDate(calendar: calendar, year: 2026, month: 5, day: 13)
    let viewModel = TimelineViewModel(
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
  func calendarDayIDsChangeWhenMonthChanges() async throws {
    let calendar = calendarForTimelineTests()
    let now = fixtureDate(calendar: calendar, year: 2026, month: 5, day: 13)
    let viewModel = TimelineViewModel(
      journalRepository: PreviewJournalRepository(entries: []),
      calendar: calendar,
      now: { now }
    )

    let mayDayID = try #require(viewModel.calendarDays.first { $0.dayNumber == 13 }?.id)

    viewModel.moveSelectedMonth(by: 1)

    let juneDayID = try #require(viewModel.calendarDays.first { $0.dayNumber == 13 }?.id)

    #expect(mayDayID != juneDayID)
    #expect(mayDayID.contains("2026-5"))
    #expect(juneDayID.contains("2026-6"))
  }

  @Test
  func calendarDaysMarkDatesWithEntries() async throws {
    let calendar = calendarForTimelineTests()
    let entryDate = fixtureDate(calendar: calendar, year: 2026, month: 5, day: 13)
    let viewModel = TimelineViewModel(
      journalRepository: PreviewJournalRepository(
        entries: [timelineEntry(on: entryDate, title: "Marked")]
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
  func calendarWeekdaysFollowCalendarFirstWeekday() async throws {
    let calendar = calendarForTimelineTests()
    let now = fixtureDate(calendar: calendar, year: 2026, month: 7, day: 13)
    let viewModel = TimelineViewModel(
      journalRepository: PreviewJournalRepository(entries: []),
      calendar: calendar,
      now: { now }
    )

    #expect(viewModel.weekdaySymbols == ["M", "T", "W", "T", "F", "S", "S"])

    viewModel.moveSelectedMonth(by: 1)

    #expect(viewModel.weekdaySymbols == ["M", "T", "W", "T", "F", "S", "S"])
  }

  @Test
  func calendarDaysIncludeLeadingBlanksForFirstWeekday() async throws {
    let calendar = calendarForTimelineTests()
    let now = fixtureDate(calendar: calendar, year: 2026, month: 7, day: 13)
    let viewModel = TimelineViewModel(
      journalRepository: PreviewJournalRepository(entries: []),
      calendar: calendar,
      now: { now }
    )

    #expect(viewModel.calendarDays[0].dayNumber == nil)
    #expect(viewModel.calendarDays[1].dayNumber == nil)
    #expect(viewModel.calendarDays[2].dayNumber == 1)
    #expect(
      Array(viewModel.calendarDays.prefix(7).compactMap(\.dayNumber)) == [1, 2, 3, 4, 5])
  }

  @Test
  func selectDateFiltersEntriesAndMovesSelectedMonth() async throws {
    let calendar = calendarForTimelineTests()
    let now = fixtureDate(calendar: calendar, year: 2026, month: 5, day: 13)
    let selectedDate = fixtureDate(calendar: calendar, year: 2025, month: 2, day: 4)
    let matchingEntry = timelineEntry(on: selectedDate, title: "Old entry")
    let hiddenEntry = timelineEntry(
      on: fixtureDate(calendar: calendar, year: 2026, month: 5, day: 13),
      title: "Today"
    )
    let viewModel = TimelineViewModel(
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
}

private func calendarForTimelineTests() -> Calendar {
  var calendar = Calendar(identifier: .gregorian)
  calendar.locale = Locale(identifier: "en_US_POSIX")
  calendar.timeZone = fixtureTimeZone(secondsFromGMT: 0)
  calendar.firstWeekday = 2
  return calendar
}

private func timelineEntry(
  on date: Date,
  title: String,
  driftType: DriftType = .thought
) -> JournalEntry {
  JournalEntry(
    id: UUID(),
    createdAt: date,
    transcript: title,
    title: title,
    mood: .neutral,
    themes: [],
    tags: [],
    driftType: driftType
  )
}
