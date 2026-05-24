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
  func captureUsesProductQuickDriftTypeFilters() {
    let viewModel = JournalHomeViewModel(
      journalRepository: PreviewJournalRepository(entries: [])
    )

    #expect(
      viewModel.driftTypeFilters == [
        .thought,
        .goal,
        .idea,
        .reflection,
        .memory,
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
