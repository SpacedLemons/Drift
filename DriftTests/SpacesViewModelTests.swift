//
//  SpacesViewModelTests.swift
//  DriftTests
//
//  Created by Lucas Stuart West Rogers on 23/05/2026.
//

import Foundation
import Testing

@testable import Drift

@MainActor
struct SpacesViewModelTests {
  @Test
  func creatingSpacePersistsThroughRepository() async throws {
    let repository = LocalSpaceRepository(spaces: [])
    let viewModel = SpacesViewModel(
      spaceRepository: repository,
      driftRepository: JournalBackedDriftRepository(
        journalRepository: PreviewJournalRepository(entries: [])
      ),
      contextPackService: LocalContextPackService(),
      now: { Date(timeIntervalSince1970: 1_778_600_000) }
    )

    let didCreateSpace = await viewModel.createSpace(
      from: SpaceEditorDraft(
        name: "OpenAI Career",
        description: "Interview context",
        icon: "sparkles",
        accentColorHex: nil,
        isPinned: true
      )
    )

    let spaces = try await repository.fetchSpaces()

    #expect(didCreateSpace)
    #expect(spaces.map(\.name) == ["OpenAI Career"])
    #expect(spaces.first?.isPinned == true)
  }

  @Test
  func deletingSpaceKeepsDriftsAndRemovesMembership() async throws {
    let space = DriftSpace(
      id: fixtureUUID("C1000000-0000-0000-0000-000000000001"),
      name: "Goals",
      description: "Goals",
      icon: "target"
    )
    let entry = JournalEntry(
      id: fixtureUUID("C1000000-0000-0000-0000-000000000002"),
      createdAt: Date(timeIntervalSince1970: 1_778_600_000),
      transcript: "A goal Drift.",
      driftType: .goal,
      spaceIds: [space.id]
    )
    let journalRepository = PreviewJournalRepository(entries: [entry])
    let viewModel = SpacesViewModel(
      spaceRepository: LocalSpaceRepository(spaces: [space]),
      driftRepository: JournalBackedDriftRepository(journalRepository: journalRepository),
      contextPackService: LocalContextPackService()
    )

    await viewModel.load()
    let didDeleteSpace = await viewModel.deleteSpace(space)

    let entries = try await journalRepository.fetchEntries()

    #expect(didDeleteSpace)
    #expect(entries.count == 1)
    #expect(entries.first?.spaceIds == [])
  }

  @Test
  func deletingSpaceKeepsSpaceWhenMembershipCleanupFails() async throws {
    let space = DriftSpace(
      id: fixtureUUID("C1000000-0000-0000-0000-000000000010"),
      name: "Goals",
      description: "Goals",
      icon: "target"
    )
    let drift = DriftItem(
      id: fixtureUUID("C1000000-0000-0000-0000-000000000011"),
      createdAt: Date(timeIntervalSince1970: 1_778_600_000),
      body: "A goal Drift.",
      type: .goal,
      spaces: [space.id]
    )
    let spaceRepository = LocalSpaceRepository(spaces: [space])
    let viewModel = SpacesViewModel(
      spaceRepository: spaceRepository,
      driftRepository: FailingUpdateDriftRepository(drifts: [drift]),
      contextPackService: LocalContextPackService()
    )

    await viewModel.load()
    let didDeleteSpace = await viewModel.deleteSpace(space)

    let fetchedSpace = try await spaceRepository.fetchSpace(id: space.id)

    #expect(!didDeleteSpace)
    #expect(fetchedSpace == space)
    #expect(viewModel.errorMessage == "We could not delete that Space.")
  }

  @Test
  func deletingMissingSpaceReturnsFailure() async throws {
    let missingSpace = DriftSpace(
      id: fixtureUUID("C1000000-0000-0000-0000-000000000013"),
      name: "Goals",
      description: "Goals",
      icon: "target"
    )
    let viewModel = SpacesViewModel(
      spaceRepository: LocalSpaceRepository(spaces: []),
      driftRepository: JournalBackedDriftRepository(
        journalRepository: PreviewJournalRepository(entries: [])
      ),
      contextPackService: LocalContextPackService()
    )

    await viewModel.load()
    let didDeleteSpace = await viewModel.deleteSpace(missingSpace)

    #expect(!didDeleteSpace)
    #expect(viewModel.errorMessage == "We could not delete that Space.")
  }

  @Test
  func editingSpacePersistsChanges() async throws {
    let space = DriftSpace(
      id: fixtureUUID("C1000000-0000-0000-0000-000000000007"),
      name: "Ideas",
      description: "Old description",
      icon: "lightbulb"
    )
    let repository = LocalSpaceRepository(spaces: [space])
    let viewModel = SpacesViewModel(
      spaceRepository: repository,
      driftRepository: JournalBackedDriftRepository(
        journalRepository: PreviewJournalRepository(entries: [])
      ),
      contextPackService: LocalContextPackService(),
      now: { Date(timeIntervalSince1970: 1_778_600_000) }
    )

    let didUpdateSpace = await viewModel.updateSpace(
      space,
      from: SpaceEditorDraft(
        name: "OpenAI Career",
        description: "Interview prep",
        icon: "sparkles",
        accentColorHex: "#45D1C2",
        isPinned: true
      )
    )

    let updatedSpace = try #require(await repository.fetchSpace(id: space.id))

    #expect(didUpdateSpace)
    #expect(updatedSpace.name == "OpenAI Career")
    #expect(updatedSpace.description == "Interview prep")
    #expect(updatedSpace.icon == "sparkles")
    #expect(updatedSpace.accentColorHex == "#45D1C2")
    #expect(updatedSpace.isPinned)
  }

  @Test
  func editingMissingSpaceDoesNotRecreateIt() async throws {
    let missingSpace = DriftSpace(
      id: fixtureUUID("C1000000-0000-0000-0000-000000000012"),
      name: "Ideas",
      description: "Old description",
      icon: "lightbulb"
    )
    let repository = LocalSpaceRepository(spaces: [])
    let viewModel = SpacesViewModel(
      spaceRepository: repository,
      driftRepository: JournalBackedDriftRepository(
        journalRepository: PreviewJournalRepository(entries: [])
      ),
      contextPackService: LocalContextPackService()
    )

    let didUpdateSpace = await viewModel.updateSpace(
      missingSpace,
      from: SpaceEditorDraft(
        name: "OpenAI Career",
        description: "Interview prep",
        icon: "sparkles",
        accentColorHex: "#45D1C2",
        isPinned: true
      )
    )

    let spaces = try await repository.fetchSpaces()

    #expect(!didUpdateSpace)
    #expect(spaces.isEmpty)
    #expect(viewModel.errorMessage == "We could not save that Space.")
  }

  @Test
  func clearMessagesRemovesStaleStatusAndErrorCopy() async throws {
    let missingSpace = DriftSpace(
      id: fixtureUUID("C1000000-0000-0000-0000-000000000016"),
      name: "Ideas",
      description: "Ideas",
      icon: "lightbulb"
    )
    let viewModel = SpacesViewModel(
      spaceRepository: LocalSpaceRepository(spaces: []),
      driftRepository: JournalBackedDriftRepository(
        journalRepository: PreviewJournalRepository(entries: [])
      ),
      contextPackService: LocalContextPackService()
    )

    _ = await viewModel.deleteSpace(missingSpace)
    #expect(viewModel.errorMessage == "We could not delete that Space.")

    viewModel.clearMessages()

    #expect(viewModel.statusMessage == nil)
    #expect(viewModel.errorMessage == nil)
  }

  @Test
  func addingAndRemovingDriftUpdatesMembershipOnly() async throws {
    let space = DriftSpace(
      id: fixtureUUID("C1000000-0000-0000-0000-000000000003"),
      name: "Ideas",
      description: "Ideas",
      icon: "lightbulb"
    )
    let entry = JournalEntry(
      id: fixtureUUID("C1000000-0000-0000-0000-000000000004"),
      createdAt: Date(timeIntervalSince1970: 1_778_600_000),
      transcript: "An idea.",
      driftType: .idea
    )
    let journalRepository = PreviewJournalRepository(entries: [entry])
    let viewModel = SpacesViewModel(
      spaceRepository: LocalSpaceRepository(spaces: [space]),
      driftRepository: JournalBackedDriftRepository(journalRepository: journalRepository),
      contextPackService: LocalContextPackService()
    )

    await viewModel.load()
    let drift = try #require(viewModel.availableDrifts(for: space).first)
    let didAddDrift = await viewModel.addDrift(drift, to: space)

    let addedEntry = try #require(await journalRepository.fetchEntry(id: entry.id))
    #expect(didAddDrift)
    #expect(addedEntry.spaceIds == [space.id])

    await viewModel.load()
    let addedDrift = try #require(viewModel.drifts(in: space).first)
    let didRemoveDrift = await viewModel.removeDrift(addedDrift, from: space)

    let removedEntry = try #require(await journalRepository.fetchEntry(id: entry.id))
    #expect(didRemoveDrift)
    #expect(removedEntry.spaceIds == [])
  }

  @Test
  func addingDriftReturnsFailureWhenMembershipUpdateFails() async throws {
    let space = DriftSpace(
      id: fixtureUUID("C1000000-0000-0000-0000-000000000014"),
      name: "Ideas",
      description: "Ideas",
      icon: "lightbulb"
    )
    let drift = DriftItem(
      id: fixtureUUID("C1000000-0000-0000-0000-000000000015"),
      createdAt: Date(timeIntervalSince1970: 1_778_600_000),
      body: "An idea Drift.",
      type: .idea
    )
    let viewModel = SpacesViewModel(
      spaceRepository: LocalSpaceRepository(spaces: [space]),
      driftRepository: FailingUpdateDriftRepository(drifts: [drift]),
      contextPackService: LocalContextPackService()
    )

    await viewModel.load()
    let didAddDrift = await viewModel.addDrift(drift, to: space)

    #expect(!didAddDrift)
    #expect(viewModel.errorMessage == "We could not update that Drift.")
  }

  @Test
  func loadRefreshesDriftCountsAfterRepositoryChanges() async throws {
    let space = DriftSpace(
      id: fixtureUUID("C1000000-0000-0000-0000-000000000008"),
      name: "Goals",
      description: "Goals",
      icon: "target"
    )
    let journalRepository = PreviewJournalRepository(entries: [])
    let viewModel = SpacesViewModel(
      spaceRepository: LocalSpaceRepository(spaces: [space]),
      driftRepository: JournalBackedDriftRepository(journalRepository: journalRepository),
      contextPackService: LocalContextPackService()
    )

    await viewModel.load()

    #expect(viewModel.summaries.first?.driftCount == 0)

    try await journalRepository.saveEntry(
      JournalEntry(
        id: fixtureUUID("C1000000-0000-0000-0000-000000000009"),
        createdAt: Date(timeIntervalSince1970: 1_778_600_000),
        transcript: "A refreshed Space Drift.",
        driftType: .goal,
        spaceIds: [space.id]
      )
    )
    await viewModel.load()

    #expect(viewModel.summaries.first?.driftCount == 1)
  }

  @Test
  func creatingContextPackFromSpaceUsesOnlyThatSpace() async throws {
    let space = DriftSpace(
      id: fixtureUUID("C1000000-0000-0000-0000-000000000005"),
      name: "Drift App",
      description: "Product ideas",
      icon: "app.badge"
    )
    let entry = JournalEntry(
      id: fixtureUUID("C1000000-0000-0000-0000-000000000006"),
      createdAt: Date(timeIntervalSince1970: 1_778_600_000),
      transcript: "Build context packs.",
      driftType: .idea,
      spaceIds: [space.id]
    )
    let contextPackService = LocalContextPackService()
    let viewModel = SpacesViewModel(
      spaceRepository: LocalSpaceRepository(spaces: [space]),
      driftRepository: JournalBackedDriftRepository(
        journalRepository: PreviewJournalRepository(entries: [entry])
      ),
      contextPackService: contextPackService
    )

    await viewModel.load()
    let pack = await viewModel.createContextPack(from: space)
    let savedPacks = try await contextPackService.fetchContextPacks()

    #expect(pack?.spaceIds == [space.id])
    #expect(pack?.driftIds == [entry.id])
    #expect(savedPacks.first?.spaceIds == [space.id])
  }
}

extension SpaceEditorDraft {
  fileprivate init(
    name: String,
    description: String,
    icon: String,
    accentColorHex: String?,
    isPinned: Bool
  ) {
    self.init()
    self.name = name
    self.description = description
    self.icon = icon
    self.accentColorHex = accentColorHex
    self.isPinned = isPinned
  }
}

private actor FailingUpdateDriftRepository: DriftRepository {
  private let drifts: [DriftItem]

  init(drifts: [DriftItem]) {
    self.drifts = drifts
  }

  func fetchDrifts() async throws -> [DriftItem] {
    drifts
  }

  func fetchDrift(id: UUID) async throws -> DriftItem? {
    drifts.first { $0.id == id }
  }

  func saveDrift(_ drift: DriftItem) async throws {}

  func updateDrift(_ drift: DriftItem) async throws {
    throw TestDriftRepositoryError.updateFailed
  }

  func deleteDrift(id: UUID) async throws {}

  func searchDrifts(query: String) async throws -> [DriftItem] {
    drifts
  }
}

private enum TestDriftRepositoryError: Error {
  case updateFailed
}
