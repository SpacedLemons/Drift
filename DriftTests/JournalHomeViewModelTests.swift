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

    let viewModel = JournalHomeViewModel(journalRepository: repository)

    await viewModel.load()

    #expect(viewModel.visibleEntries == PreviewData.journalEntries)
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
  func captureShowsEntriesAcrossDates() async throws {
    let viewModel = JournalHomeViewModel(
      journalRepository: PreviewJournalRepository(entries: PreviewData.journalEntries)
    )

    await viewModel.load()

    #expect(viewModel.visibleEntries.count == PreviewData.journalEntries.count)
  }

  @Test
  func captureCalendarStartsCompactOnCurrentDay() {
    let calendar = calendarForHomeTests()
    let now = fixtureDate(calendar: calendar, year: 2026, month: 5, day: 26)
    let viewModel = JournalHomeViewModel(
      journalRepository: PreviewJournalRepository(entries: []),
      calendar: calendar,
      now: { now }
    )

    #expect(!viewModel.isCalendarExpanded)
    #expect(viewModel.selectedDate == calendar.startOfDay(for: now))
    #expect(viewModel.dateStripDays.count == 7)
  }

  @Test
  func captureCalendarMarksLoadedEntryDates() async throws {
    let calendar = calendarForHomeTests()
    let entryDate = fixtureDate(calendar: calendar, year: 2026, month: 5, day: 21)
    let entry = JournalEntry(
      id: fixtureUUID("A1000000-0000-0000-0000-000000000010"),
      createdAt: entryDate,
      transcript: "A dated Drift.",
      driftType: .thought
    )
    let viewModel = JournalHomeViewModel(
      journalRepository: PreviewJournalRepository(entries: [entry]),
      calendar: calendar,
      now: { fixtureDate(calendar: calendar, year: 2026, month: 5, day: 26) }
    )

    await viewModel.load()

    #expect(viewModel.dateHasEntries(entryDate))
    #expect(!viewModel.isCalendarExpanded)
  }

  @Test
  func captureUsesProductQuickDriftTypeFilters() {
    let viewModel = JournalHomeViewModel(
      journalRepository: PreviewJournalRepository(entries: [])
    )

    #expect(
      viewModel.driftTypeFilters == [
        .thought,
        .reflection,
        .goal,
        .idea,
        .memory,
        .task,
      ])
  }

  @Test
  func reloadReflectsRepositoryChanges() async throws {
    let repository = PreviewJournalRepository(entries: [PreviewData.journalEntries[0]])
    let viewModel = JournalHomeViewModel(journalRepository: repository)

    await viewModel.load()
    #expect(viewModel.visibleEntries.count == 1)

    try await repository.saveEntry(
      JournalEntry(
        id: fixtureUUID("A1000000-0000-0000-0000-000000000099"),
        createdAt: PreviewData.baseDate.addingTimeInterval(-60),
        transcript: "Another same-day Drift."
      )
    )
    await viewModel.load()

    #expect(viewModel.visibleEntries.count == 2)
  }

  @Test
  func driftTypeFilterNarrowsVisibleEntries() async throws {
    let entries = [
      JournalEntry(
        id: fixtureUUID("A1000000-0000-0000-0000-000000000001"),
        createdAt: PreviewData.baseDate,
        transcript: "Goal",
        driftType: .goal
      ),
      JournalEntry(
        id: fixtureUUID("A1000000-0000-0000-0000-000000000002"),
        createdAt: PreviewData.baseDate.addingTimeInterval(-60),
        transcript: "Idea",
        driftType: .idea
      ),
    ]
    let viewModel = JournalHomeViewModel(
      journalRepository: PreviewJournalRepository(entries: entries)
    )

    await viewModel.load()
    viewModel.selectDriftTypeFilter(.goal)

    #expect(viewModel.visibleEntries.map(\.driftType) == [.goal])

    viewModel.selectDriftTypeFilter(nil)

    #expect(viewModel.visibleEntries.count == 2)
  }

  @Test
  func searchTrimsWhitespaceAndIsCaseInsensitive() async throws {
    let openAIEntry = JournalEntry(
      id: fixtureUUID("A1000000-0000-0000-0000-000000000011"),
      createdAt: PreviewData.baseDate,
      transcript: "Interview thoughts.",
      title: "OpenAI prep",
      driftType: .thought
    )
    let otherEntry = JournalEntry(
      id: fixtureUUID("A1000000-0000-0000-0000-000000000012"),
      createdAt: PreviewData.baseDate.addingTimeInterval(-60),
      transcript: "Weekend notes.",
      title: "Weekend",
      driftType: .reflection
    )
    let viewModel = JournalHomeViewModel(
      journalRepository: PreviewJournalRepository(entries: [otherEntry, openAIEntry])
    )

    await viewModel.load()
    viewModel.searchText = "  openai  "

    #expect(viewModel.visibleEntries.map(\.id) == [openAIEntry.id])
  }

  @Test
  func titleSearchMatchesRankAboveBodyOnlyMatches() async throws {
    let bodyOnlyMatch = JournalEntry(
      id: fixtureUUID("A1000000-0000-0000-0000-000000000013"),
      createdAt: PreviewData.baseDate,
      transcript: "Mentioned OpenAI once in the body.",
      title: "Career notes",
      driftType: .thought
    )
    let titleMatch = JournalEntry(
      id: fixtureUUID("A1000000-0000-0000-0000-000000000014"),
      createdAt: PreviewData.baseDate.addingTimeInterval(-60 * 60),
      transcript: "Prep plan.",
      title: "OpenAI prep",
      driftType: .goal
    )
    let viewModel = JournalHomeViewModel(
      journalRepository: PreviewJournalRepository(entries: [bodyOnlyMatch, titleMatch])
    )

    await viewModel.load()
    viewModel.searchText = "OpenAI"

    #expect(viewModel.visibleEntries.map(\.id) == [titleMatch.id, bodyOnlyMatch.id])
  }

  @Test
  func searchMatchesTagsAndSpaceNames() async throws {
    let spaceID = fixtureUUID("A1000000-0000-0000-0000-000000000015")
    let taggedEntry = JournalEntry(
      id: fixtureUUID("A1000000-0000-0000-0000-000000000016"),
      createdAt: PreviewData.baseDate,
      transcript: "A launch plan.",
      title: "Launch",
      tags: ["roadmap"],
      driftType: .task
    )
    let spaceEntry = JournalEntry(
      id: fixtureUUID("A1000000-0000-0000-0000-000000000017"),
      createdAt: PreviewData.baseDate.addingTimeInterval(-60),
      transcript: "Interview notes.",
      title: "Prep",
      driftType: .thought,
      spaceIds: [spaceID]
    )
    let viewModel = JournalHomeViewModel(
      journalRepository: PreviewJournalRepository(entries: [taggedEntry, spaceEntry]),
      spaceRepository: LocalSpaceRepository(
        spaces: [
          DriftSpace(
            id: spaceID,
            name: "OpenAI Career",
            description: "Application notes.",
            createdAt: PreviewData.baseDate
          )
        ]
      )
    )

    await viewModel.load()
    viewModel.searchText = "roadmap"

    #expect(viewModel.visibleEntries.map(\.id) == [taggedEntry.id])

    viewModel.searchText = "career"

    #expect(viewModel.visibleEntries.map(\.id) == [spaceEntry.id])
    #expect(viewModel.spaceNames(for: spaceEntry) == ["OpenAI Career"])
  }

  @Test
  func searchAndDriftTypeFilterCombine() async throws {
    let goalEntry = JournalEntry(
      id: fixtureUUID("A1000000-0000-0000-0000-000000000018"),
      createdAt: PreviewData.baseDate,
      transcript: "OpenAI goal.",
      title: "OpenAI plan",
      driftType: .goal
    )
    let ideaEntry = JournalEntry(
      id: fixtureUUID("A1000000-0000-0000-0000-000000000019"),
      createdAt: PreviewData.baseDate.addingTimeInterval(-60),
      transcript: "OpenAI idea.",
      title: "OpenAI idea",
      driftType: .idea
    )
    let viewModel = JournalHomeViewModel(
      journalRepository: PreviewJournalRepository(entries: [goalEntry, ideaEntry])
    )

    await viewModel.load()
    viewModel.searchText = "openai"
    viewModel.selectDriftTypeFilter(.goal)

    #expect(viewModel.visibleEntries == [goalEntry])
  }

  @Test
  func emptySearchReturnsNormalRecentDrifts() async throws {
    let olderEntry = JournalEntry(
      id: fixtureUUID("A1000000-0000-0000-0000-000000000020"),
      createdAt: PreviewData.baseDate.addingTimeInterval(-60 * 60),
      transcript: "Older.",
      title: "Older",
      driftType: .reflection
    )
    let recentEntry = JournalEntry(
      id: fixtureUUID("A1000000-0000-0000-0000-000000000021"),
      createdAt: PreviewData.baseDate,
      transcript: "Recent.",
      title: "Recent",
      driftType: .thought
    )
    let viewModel = JournalHomeViewModel(
      journalRepository: PreviewJournalRepository(entries: [olderEntry, recentEntry])
    )

    await viewModel.load()
    viewModel.searchText = "  "

    #expect(viewModel.visibleEntries.map(\.id) == [recentEntry.id, olderEntry.id])
    #expect(viewModel.visibleEntriesSectionTitle == "Recent Drifts")
  }

  @Test
  func searchNoResultsUsesSearchEmptyState() async throws {
    let viewModel = JournalHomeViewModel(
      journalRepository: PreviewJournalRepository(entries: [PreviewData.journalEntries[0]])
    )

    await viewModel.load()
    viewModel.searchText = "not-here"

    #expect(viewModel.visibleEntries.isEmpty)
    #expect(viewModel.emptyEntriesTitle == "No matching Drifts.")
    #expect(viewModel.emptyEntriesMessage == "Try another word or phrase.")
  }

  @Test
  func entryReturnsLoadedEntry() async throws {
    let entry = PreviewData.journalEntries[0]
    let viewModel = JournalHomeViewModel(
      journalRepository: PreviewJournalRepository(entries: [entry])
    )

    await viewModel.load()

    #expect(viewModel.entry(id: entry.id) == entry)
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
    #expect(viewModel.errorMessage == "We could not load your Drifts.")
  }
}

private enum TestJournalHomeRepositoryError: Error {
  case failed
}

private func calendarForHomeTests() -> Calendar {
  var calendar = Calendar(identifier: .gregorian)
  calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .gmt
  calendar.locale = Locale(identifier: "en_GB")
  return calendar
}
