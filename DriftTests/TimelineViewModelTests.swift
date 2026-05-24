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
      journalRepository: PreviewJournalRepository(entries: entries)
    )

    await viewModel.load()

    #expect(viewModel.visibleEntries.map(\.id) == entries.map(\.id))
  }

  @Test
  func timelineFiltersByDriftTypeOnly() async throws {
    let goalEntry = JournalEntry(
      id: fixtureUUID("E1000000-0000-0000-0000-000000000003"),
      createdAt: Date(timeIntervalSince1970: 1_778_600_000),
      transcript: "Goal",
      driftType: .goal
    )
    let thoughtEntry = JournalEntry(
      id: fixtureUUID("E1000000-0000-0000-0000-000000000004"),
      createdAt: Date(timeIntervalSince1970: 1_778_500_000),
      transcript: "Thought",
      driftType: .thought
    )
    let olderGoalEntry = JournalEntry(
      id: fixtureUUID("E1000000-0000-0000-0000-000000000005"),
      createdAt: Date(timeIntervalSince1970: 1_778_400_000),
      transcript: "Old goal",
      driftType: .goal
    )
    let viewModel = TimelineViewModel(
      journalRepository: PreviewJournalRepository(
        entries: [goalEntry, thoughtEntry, olderGoalEntry]
      )
    )

    await viewModel.load()
    viewModel.selectDriftTypeFilter(.goal)

    #expect(viewModel.visibleEntries == [goalEntry, olderGoalEntry])
  }
}
