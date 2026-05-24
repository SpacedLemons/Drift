//
//  ContextPacksViewModelTests.swift
//  DriftTests
//
//  Created by Lucas Stuart West Rogers on 23/05/2026.
//

import Foundation
import Testing

@testable import Drift

@MainActor
struct ContextPacksViewModelTests {
  @Test
  func draftPackIncludesSelectedSpacesAndDrifts() async throws {
    let space = DriftSpace(
      id: fixtureUUID("D1000000-0000-0000-0000-000000000001"),
      name: "OpenAI Career",
      description: "Career context",
      icon: "sparkles"
    )
    let selectedEntry = JournalEntry(
      id: fixtureUUID("D1000000-0000-0000-0000-000000000002"),
      createdAt: Date(timeIntervalSince1970: 1_778_600_000),
      transcript: "Interview prep.",
      driftType: .goal,
      spaceIds: [space.id]
    )
    let hiddenEntry = JournalEntry(
      id: fixtureUUID("D1000000-0000-0000-0000-000000000003"),
      createdAt: Date(timeIntervalSince1970: 1_778_600_100),
      transcript: "Unselected.",
      driftType: .thought
    )
    let viewModel = ContextPacksViewModel(
      driftRepository: JournalBackedDriftRepository(
        journalRepository: PreviewJournalRepository(entries: [selectedEntry, hiddenEntry])
      ),
      spaceRepository: LocalSpaceRepository(spaces: [space]),
      contextPackService: LocalContextPackService(),
      contextExportService: LocalContextExportService(
        calendar: Calendar(identifier: .gregorian),
        locale: Locale(identifier: "en_US_POSIX"),
        timeZone: TimeZone(secondsFromGMT: 0) ?? .gmt
      ),
      now: { Date(timeIntervalSince1970: 1_778_600_000) }
    )

    await viewModel.load()
    viewModel.selectedSpaceIds = [space.id]
    viewModel.selectedDriftIds = []
    let markdown = await viewModel.markdownPreview()

    #expect(viewModel.draftPack.spaceIds == [space.id])
    #expect(viewModel.draftDrifts.map(\.id) == [selectedEntry.id])
    #expect(markdown.contains("Interview prep."))
    #expect(!markdown.contains("Unselected."))
  }

  @Test
  func draftPackIncludesIndividuallySelectedDrifts() async throws {
    let selectedEntry = JournalEntry(
      id: fixtureUUID("D1000000-0000-0000-0000-000000000008"),
      createdAt: Date(timeIntervalSince1970: 1_778_600_000),
      transcript: "Selected standalone Drift.",
      title: "Selected Drift",
      driftType: .thought
    )
    let hiddenEntry = JournalEntry(
      id: fixtureUUID("D1000000-0000-0000-0000-000000000009"),
      createdAt: Date(timeIntervalSince1970: 1_778_600_100),
      transcript: "Unselected standalone Drift.",
      title: "Hidden Drift",
      driftType: .idea
    )
    let viewModel = ContextPacksViewModel(
      driftRepository: JournalBackedDriftRepository(
        journalRepository: PreviewJournalRepository(entries: [selectedEntry, hiddenEntry])
      ),
      spaceRepository: LocalSpaceRepository(spaces: []),
      contextPackService: LocalContextPackService(),
      contextExportService: LocalContextExportService(
        calendar: Calendar(identifier: .gregorian),
        locale: Locale(identifier: "en_US_POSIX"),
        timeZone: TimeZone(secondsFromGMT: 0) ?? .gmt
      ),
      now: { Date(timeIntervalSince1970: 1_778_600_000) }
    )

    await viewModel.load()
    viewModel.selectedSpaceIds = []
    viewModel.selectedDriftIds = [selectedEntry.id]
    let markdown = await viewModel.markdownPreview()

    #expect(viewModel.draftPack.driftIds == [selectedEntry.id])
    #expect(viewModel.draftDrifts.map(\.id) == [selectedEntry.id])
    #expect(markdown.contains("Selected Drift"))
    #expect(!markdown.contains("Hidden Drift"))
  }

  @Test
  func draftPackKeepsStableIdentityAcrossAccesses() async throws {
    let createdAt = Date(timeIntervalSince1970: 1_778_600_000)
    let viewModel = ContextPacksViewModel(
      driftRepository: JournalBackedDriftRepository(
        journalRepository: PreviewJournalRepository(entries: [])
      ),
      spaceRepository: LocalSpaceRepository(spaces: []),
      contextPackService: LocalContextPackService(),
      contextExportService: LocalContextExportService(),
      now: { createdAt }
    )

    let firstDraft = viewModel.draftPack
    viewModel.draftName = "Updated Context"
    let updatedDraft = viewModel.draftPack

    #expect(updatedDraft.id == firstDraft.id)
    #expect(updatedDraft.createdAt == createdAt)
    #expect(updatedDraft.name == "Updated Context")
  }

  @Test
  func loadDoesNotAutoselectSpacesOrDrifts() async throws {
    let space = DriftSpace(
      id: fixtureUUID("D1000000-0000-0000-0000-000000000006"),
      name: "Goals",
      description: "Goals",
      icon: "target"
    )
    let drift = JournalEntry(
      id: fixtureUUID("D1000000-0000-0000-0000-000000000007"),
      createdAt: Date(timeIntervalSince1970: 1_778_600_000),
      transcript: "A goal Drift.",
      driftType: .goal,
      spaceIds: [space.id]
    )
    let viewModel = ContextPacksViewModel(
      driftRepository: JournalBackedDriftRepository(
        journalRepository: PreviewJournalRepository(entries: [drift])
      ),
      spaceRepository: LocalSpaceRepository(spaces: [space]),
      contextPackService: LocalContextPackService(),
      contextExportService: LocalContextExportService()
    )

    await viewModel.load()

    #expect(viewModel.selectedSpaceIds.isEmpty)
    #expect(viewModel.selectedDriftIds.isEmpty)
    #expect(viewModel.draftPack.spaceIds.isEmpty)
    #expect(viewModel.draftPack.driftIds.isEmpty)
  }

  @Test
  func loadFailureClearsSelectableContext() async throws {
    let space = DriftSpace(
      id: fixtureUUID("D1000000-0000-0000-0000-000000000010"),
      name: "Goals",
      description: "Goals",
      icon: "target"
    )
    let drift = JournalEntry(
      id: fixtureUUID("D1000000-0000-0000-0000-000000000011"),
      createdAt: Date(timeIntervalSince1970: 1_778_600_000),
      transcript: "A goal Drift.",
      driftType: .goal,
      spaceIds: [space.id]
    )
    let viewModel = ContextPacksViewModel(
      driftRepository: JournalBackedDriftRepository(
        journalRepository: PreviewJournalRepository(entries: [drift])
      ),
      spaceRepository: LocalSpaceRepository(spaces: [space]),
      contextPackService: FailingContextPackService(),
      contextExportService: LocalContextExportService()
    )

    await viewModel.load()

    #expect(viewModel.contextPacks.isEmpty)
    #expect(viewModel.recentDrifts.isEmpty)
    #expect(viewModel.spaces.isEmpty)
    #expect(viewModel.errorMessage == "We could not load Context Packs yet.")
  }

  @Test
  func savingDraftPackPersistsLocally() async throws {
    let contextPackService = LocalContextPackService()
    let viewModel = ContextPacksViewModel(
      driftRepository: JournalBackedDriftRepository(
        journalRepository: PreviewJournalRepository(entries: [])
      ),
      spaceRepository: LocalSpaceRepository(spaces: []),
      contextPackService: contextPackService,
      contextExportService: LocalContextExportService()
    )

    viewModel.draftName = "Drift App"
    viewModel.draftDescription = "Product context"
    await viewModel.saveDraftPack()

    let packs = try await contextPackService.fetchContextPacks()

    #expect(packs.map(\.name) == ["Drift App"])
    #expect(packs.first?.aiVisibility == .privateLocalOnly)
  }

  @Test
  func savingDraftPackTwiceUpdatesCurrentDraftInsteadOfDuplicating() async throws {
    let contextPackService = LocalContextPackService()
    let viewModel = ContextPacksViewModel(
      driftRepository: JournalBackedDriftRepository(
        journalRepository: PreviewJournalRepository(entries: [])
      ),
      spaceRepository: LocalSpaceRepository(spaces: []),
      contextPackService: contextPackService,
      contextExportService: LocalContextExportService()
    )

    viewModel.draftName = "Initial Context"
    await viewModel.saveDraftPack()
    viewModel.draftName = "Updated Context"
    await viewModel.saveDraftPack()

    let packs = try await contextPackService.fetchContextPacks()

    #expect(packs.count == 1)
    #expect(packs.first?.name == "Updated Context")
  }

  @Test
  func startingNewDraftAllowsAnotherContextPack() async throws {
    let contextPackService = LocalContextPackService()
    let viewModel = ContextPacksViewModel(
      driftRepository: JournalBackedDriftRepository(
        journalRepository: PreviewJournalRepository(entries: [])
      ),
      spaceRepository: LocalSpaceRepository(spaces: []),
      contextPackService: contextPackService,
      contextExportService: LocalContextExportService()
    )

    viewModel.draftName = "First Context"
    await viewModel.saveDraftPack()
    viewModel.startNewDraft()
    viewModel.draftName = "Second Context"
    await viewModel.saveDraftPack()

    let packs = try await contextPackService.fetchContextPacks()

    #expect(packs.count == 2)
    #expect(Set(packs.map(\.name)) == Set(["First Context", "Second Context"]))
  }

  @Test
  func copyMarkdownReturnsLocalMarkdownWithoutSharingAutomatically() async throws {
    let drift = JournalEntry(
      id: fixtureUUID("D1000000-0000-0000-0000-000000000004"),
      createdAt: Date(timeIntervalSince1970: 1_778_600_000),
      transcript: "Prepare a clear context packet.",
      title: "Context prep",
      driftType: .thought
    )
    let pack = ContextPack(
      name: "Drift App",
      description: "Product context",
      driftIds: [drift.id]
    )
    let viewModel = ContextPacksViewModel(
      driftRepository: JournalBackedDriftRepository(
        journalRepository: PreviewJournalRepository(entries: [drift])
      ),
      spaceRepository: LocalSpaceRepository(spaces: []),
      contextPackService: LocalContextPackService(contextPacks: [pack]),
      contextExportService: LocalContextExportService(
        calendar: Calendar(identifier: .gregorian),
        locale: Locale(identifier: "en_US_POSIX"),
        timeZone: TimeZone(secondsFromGMT: 0) ?? .gmt
      ),
      now: { Date(timeIntervalSince1970: 1_778_600_000) }
    )

    await viewModel.load()

    let markdown = await viewModel.copyMarkdown(for: pack)

    #expect(markdown?.contains("# Context Pack: Drift App") == true)
    #expect(markdown?.contains("Context prep") == true)
    #expect(viewModel.copiedMessage == "Context copied. Nothing was shared automatically.")
  }

  @Test
  func shareMarkdownReturnsLocalMarkdownWithoutUploadingAutomatically() async throws {
    let drift = JournalEntry(
      id: fixtureUUID("D1000000-0000-0000-0000-000000000005"),
      createdAt: Date(timeIntervalSince1970: 1_778_600_000),
      transcript: "Share only after I choose the native share action.",
      title: "Sharing guardrail",
      driftType: .context
    )
    let pack = ContextPack(
      name: "Sharing Context",
      description: "Product context",
      driftIds: [drift.id]
    )
    let viewModel = ContextPacksViewModel(
      driftRepository: JournalBackedDriftRepository(
        journalRepository: PreviewJournalRepository(entries: [drift])
      ),
      spaceRepository: LocalSpaceRepository(spaces: []),
      contextPackService: LocalContextPackService(contextPacks: [pack]),
      contextExportService: LocalContextExportService(
        calendar: Calendar(identifier: .gregorian),
        locale: Locale(identifier: "en_US_POSIX"),
        timeZone: TimeZone(secondsFromGMT: 0) ?? .gmt
      ),
      now: { Date(timeIntervalSince1970: 1_778_600_000) }
    )

    await viewModel.load()

    let markdown = await viewModel.shareMarkdown(for: pack)

    #expect(markdown?.contains("# Context Pack: Sharing Context") == true)
    #expect(markdown?.contains("Sharing guardrail") == true)
    #expect(viewModel.copiedMessage == "Context prepared for sharing. Nothing was uploaded.")
  }
}

private actor FailingContextPackService: ContextPackService {
  func fetchContextPacks() async throws -> [ContextPack] {
    throw ContextPackServiceError.fetchFailed
  }

  func saveContextPack(_ contextPack: ContextPack) async throws {
    throw ContextPackServiceError.saveFailed
  }

  func deleteContextPack(id: UUID) async throws {
    throw ContextPackServiceError.deleteFailed
  }
}
