//
//  DriftDomainModelTests.swift
//  DriftTests
//
//  Created by Lucas Stuart West Rogers on 23/05/2026.
//

import Foundation
import Testing

@testable import Drift

struct DriftDomainModelTests {
  @Test
  func driftTypeDisplayNamesUseStableCases() {
    #expect(
      DriftType.allCases.map(\.displayName) == [
        "Thought",
        "Reflection",
        "Goal",
        "Idea",
        "Memory",
        "Mood",
        "Decision",
        "Task",
        "Visual",
        "Context",
      ])
  }

  @Test
  func reviewSelectionShowsReflectionFirst() {
    #expect(
      DriftType.reviewSelectionOrder.map(\.displayName) == [
        "Reflection",
        "Thought",
        "Goal",
        "Idea",
        "Memory",
        "Mood",
        "Decision",
        "Task",
        "Visual",
        "Context",
      ])
  }

  @Test
  func aiVisibilityDefaultsToPrivateLocalOnly() {
    let drift = DriftItem(
      createdAt: Date(timeIntervalSince1970: 1_778_600_000),
      body: "A private reflection."
    )
    let contextPack = ContextPack(
      name: "Recent Drifts",
      description: "Local context"
    )

    #expect(drift.aiVisibility == .privateLocalOnly)
    #expect(contextPack.aiVisibility == .privateLocalOnly)
  }

  @Test
  func aiVisibilityLabelsDoNotImplyLiveAIAccess() {
    #expect(AIVisibility.privateLocalOnly.displayName == "Private local only")
    #expect(AIVisibility.availableForInAppAI.displayName == "Prepared for future in-app AI")
    #expect(AIVisibility.availableForChatGPT.displayName == "Manual ChatGPT export")
    #expect(
      AIVisibility.availableForInAppAI.privacyCopy
        == "Prepared for future in-app AI features, but no AI access is active yet."
    )
    #expect(
      AIVisibility.availableForChatGPT.privacyCopy
        == "Can be included in a local context export that you copy when you choose."
    )
  }

  @Test
  func driftItemDisplayTitleUsesTitleBodyThenTypeFallback() {
    let titledDrift = DriftItem(
      createdAt: Date(timeIntervalSince1970: 1_778_600_000),
      title: "  Focused morning  ",
      body: "Body text.",
      type: .thought
    )
    let bodyOnlyDrift = DriftItem(
      createdAt: Date(timeIntervalSince1970: 1_778_600_000),
      body: "\n  First line.\nSecond line.",
      type: .idea
    )
    let emptyDrift = DriftItem(
      createdAt: Date(timeIntervalSince1970: 1_778_600_000),
      body: "   ",
      type: .goal
    )

    #expect(titledDrift.displayTitle == "Focused morning")
    #expect(bodyOnlyDrift.displayTitle == "First line.")
    #expect(emptyDrift.displayTitle == "Goal Drift")
    #expect(emptyDrift.previewText == "No Drift body yet")
  }

  @Test
  func journalEntryDisplayTitleUsesFirstNonEmptyTranscriptLine() {
    let entry = JournalEntry(
      createdAt: Date(timeIntervalSince1970: 1_778_600_000),
      transcript: "\n  Legacy first line.\nSecond line.",
      driftType: .reflection
    )

    #expect(entry.displayTitle == "Legacy first line.")
    #expect(entry.previewText == "Legacy first line.\nSecond line.")
  }

  @Test
  func journalEntryMapsToReflectionDriftByDefault() {
    let spaceID = fixtureUUID("E0000000-0000-0000-0000-000000000099")
    let entry = JournalEntry(
      id: fixtureUUID("E0000000-0000-0000-0000-000000000001"),
      createdAt: Date(timeIntervalSince1970: 1_778_600_000),
      transcript: "A legacy entry.",
      spaceIds: [spaceID]
    )

    let drift = JournalEntryToDriftItemMapper.driftItem(from: entry)

    #expect(drift.id == entry.id)
    #expect(drift.body == entry.transcript)
    #expect(drift.type == .reflection)
    #expect(drift.spaces == [spaceID])
    #expect(drift.aiVisibility == .privateLocalOnly)
    #expect(drift.status == .active)
  }

  @Test
  func driftSpaceModelCreationUsesLocalPrivateDefaults() {
    let space = DriftSpace(
      id: fixtureUUID("E0000000-0000-0000-0000-000000000002"),
      name: "Goals",
      description: "Goals and next steps",
      icon: "target",
      isPinned: true
    )

    #expect(space.name == "Goals")
    #expect(space.isPinned)
    #expect(space.aiVisibility == .privateLocalOnly)
  }

  @Test
  func contextPackModelCreationKeepsSelectedIds() {
    let driftID = fixtureUUID("E0000000-0000-0000-0000-000000000003")
    let spaceID = fixtureUUID("E0000000-0000-0000-0000-000000000004")
    let contextPack = ContextPack(
      name: "Launch planning",
      description: "Drifts for a planning chat",
      driftIds: [driftID],
      spaceIds: [spaceID]
    )

    #expect(contextPack.driftIds == [driftID])
    #expect(contextPack.spaceIds == [spaceID])
    #expect(contextPack.aiVisibility == .privateLocalOnly)
  }

  @Test
  func journalBackedDriftRepositoryDoesNotHideExistingEntries() async throws {
    let entries = [
      JournalEntry(
        id: fixtureUUID("E0000000-0000-0000-0000-000000000005"),
        createdAt: Date(timeIntervalSince1970: 1_778_600_000),
        transcript: "First legacy entry."
      ),
      JournalEntry(
        id: fixtureUUID("E0000000-0000-0000-0000-000000000006"),
        createdAt: Date(timeIntervalSince1970: 1_778_600_100),
        transcript: "Second task.",
        driftType: .task
      ),
    ]
    let repository = JournalBackedDriftRepository(
      journalRepository: PreviewJournalRepository(entries: entries)
    )

    let drifts = try await repository.fetchDrifts()

    #expect(drifts.map(\.id) == entries.sorted { $0.createdAt > $1.createdAt }.map(\.id))
    #expect(drifts.map(\.type) == [.task, .reflection])
  }

  @Test
  func contextExportMarkdownIncludesLocalPrivacyCopy() async throws {
    let drift = DriftItem(
      createdAt: Date(timeIntervalSince1970: 1_778_600_000),
      title: "Focused morning",
      body: "Cleared the inbox and planned the next task.",
      type: .thought,
      tags: ["focus"]
    )
    let pack = ContextPack(
      name: "Recent Drifts",
      description: "Local export",
      driftIds: [drift.id]
    )
    let exportService = LocalContextExportService(
      calendar: Calendar(identifier: .gregorian),
      locale: Locale(identifier: "en_US_POSIX"),
      timeZone: TimeZone(secondsFromGMT: 0) ?? .gmt
    )

    let markdown = try await exportService.markdown(
      for: pack,
      drifts: [drift],
      spaces: [],
      exportedAt: Date(timeIntervalSince1970: 1_778_600_000)
    )

    #expect(markdown.contains("Drifts are private by default."))
    #expect(markdown.contains("# Context Pack: Recent Drifts"))
    #expect(markdown.contains("## Thoughts"))
    #expect(markdown.contains("Type: Thought"))
    #expect(markdown.contains("Focused morning"))
  }
}
