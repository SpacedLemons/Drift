//
//  InsightsViewModelTests.swift
//  DriftTests
//
//  Created by Lucas Stuart West Rogers on 12/05/2026.
//

import Foundation
import Testing

@testable import Drift

@MainActor
struct InsightsViewModelTests {
  @Test
  func calculatesTotalEntries() {
    let viewModel = makeViewModel()

    let summary = viewModel.calculateSummary(from: makeEntries())

    #expect(summary.totalEntries == 4)
  }

  @Test
  func calculatesEntriesThisWeek() {
    let viewModel = makeViewModel()

    let summary = viewModel.calculateSummary(from: makeEntries())

    #expect(summary.entriesThisWeek == 3)
  }

  @Test
  func calculatesMostCommonMood() {
    let viewModel = makeViewModel()

    let summary = viewModel.calculateSummary(from: makeEntries())

    #expect(summary.mostCommonMood == .positive)
  }

  @Test
  func calculatesMostCommonTheme() {
    let viewModel = makeViewModel()

    let summary = viewModel.calculateSummary(from: makeEntries())

    #expect(summary.mostCommonThemeName == "Work")
  }

  @Test
  func calculatesWritingStreak() {
    let viewModel = makeViewModel()

    let summary = viewModel.calculateSummary(from: makeEntries())

    #expect(summary.currentStreak == 3)
  }

  @Test
  func emptyEntriesProduceEmptySummary() {
    let viewModel = makeViewModel()

    let summary = viewModel.calculateSummary(from: [])

    #expect(summary == .empty)
  }

  @Test
  func unknownMoodAndThemeDoNotCrashSummary() {
    let viewModel = makeViewModel()
    let entries = [
      JournalEntry(
        createdAt: date(year: 2026, month: 5, day: 13),
        transcript: "A legacy entry.",
        mood: .unknown,
        themes: [.other]
      )
    ]

    let summary = viewModel.calculateSummary(from: entries)

    #expect(summary.totalEntries == 1)
    #expect(summary.mostCommonMood == .unknown)
    #expect(summary.mostCommonThemeName == "Other")
    #expect(summary.moodTrend.isEmpty)
  }

  @Test
  func moodValuesMapCorrectly() {
    #expect(Mood.positive.trendScore == 5)
    #expect(Mood.reflective.trendScore == 4)
    #expect(Mood.neutral.trendScore == 3)
    #expect(Mood.anxious.trendScore == 2)
    #expect(Mood.stressed.trendScore == 2)
    #expect(Mood.low.trendScore == 1)
    #expect(Mood.unknown.trendScore == nil)
  }

  @Test
  func moodTrendProducesExpectedPoints() {
    let viewModel = makeViewModel()

    let summary = viewModel.calculateSummary(from: makeEntries())

    #expect(summary.moodTrend.count == 3)
    #expect(summary.moodTrend.map(\.score) == [4, 5, 5])
  }

  @Test
  func moodTrendRangeCanSwitchToThirtyDays() async {
    let viewModel = InsightsViewModel(
      journalRepository: PreviewJournalRepository(entries: makeEntries()),
      calendar: testCalendar,
      now: { date(year: 2026, month: 5, day: 13) }
    )

    await viewModel.load()
    viewModel.selectMoodTrendRange(.last30Days)

    #expect(viewModel.summary.moodTrend.count == 4)
  }

  private func makeViewModel() -> InsightsViewModel {
    InsightsViewModel(
      journalRepository: PreviewJournalRepository(entries: []),
      calendar: testCalendar,
      now: { date(year: 2026, month: 5, day: 13) }
    )
  }

  private func makeEntries() -> [JournalEntry] {
    [
      JournalEntry(
        createdAt: date(year: 2026, month: 5, day: 13),
        transcript: "Today felt focused.",
        mood: .positive,
        themes: [.work, .productivity]
      ),
      JournalEntry(
        createdAt: date(year: 2026, month: 5, day: 12),
        transcript: "Work moved along.",
        mood: .positive,
        themes: [.work]
      ),
      JournalEntry(
        createdAt: date(year: 2026, month: 5, day: 11),
        transcript: "A reflective start to the week.",
        mood: .reflective,
        themes: [.growth]
      ),
      JournalEntry(
        createdAt: date(year: 2026, month: 5, day: 3),
        transcript: "Last week was calmer.",
        mood: .neutral,
        themes: [.health]
      ),
    ]
  }
}

private let testCalendar: Calendar = {
  var calendar = Calendar(identifier: .gregorian)
  calendar.timeZone = fixtureTimeZone(secondsFromGMT: 0)
  calendar.firstWeekday = 2
  return calendar
}()

private func date(year: Int, month: Int, day: Int) -> Date {
  fixtureDate(calendar: testCalendar, year: year, month: month, day: day)
}
