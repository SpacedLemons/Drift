//
//  SwiftDataSpaceRepositoryTests.swift
//  DriftTests
//
//  Created by Lucas Stuart West Rogers on 23/05/2026.
//

import Foundation
import Testing

@testable import Drift

struct SwiftDataSpaceRepositoryTests {
  @Test
  func savesUpdatesAndFetchesSpaces() async throws {
    let repository = try makeRepository()
    let space = DriftSpace(
      id: fixtureUUID("F1000000-0000-0000-0000-000000000001"),
      name: "Goals",
      description: "Goal Drifts",
      icon: "target",
      accentColorHex: "#9E78FF",
      createdAt: Date(timeIntervalSince1970: 100),
      isPinned: true
    )
    var updatedSpace = space
    updatedSpace.name = "OpenAI Career"
    updatedSpace.description = "Career context"
    updatedSpace.icon = "sparkles"
    updatedSpace.accentColorHex = "#45D1C2"
    updatedSpace.isPinned = false
    updatedSpace.updatedAt = Date(timeIntervalSince1970: 200)

    try await repository.saveSpace(space)
    try await repository.updateSpace(updatedSpace)

    let spaces = try await repository.fetchSpaces()
    let fetchedSpace = try await repository.fetchSpace(id: space.id)

    #expect(spaces.map(\.id) == [space.id])
    #expect(fetchedSpace == updatedSpace)
  }

  @Test
  func deletesSpaceWithoutTouchingJournalEntries() async throws {
    let container = try SwiftDataContainer.make(inMemory: true)
    let spaceRepository = SwiftDataSpaceRepository(modelContainer: container)
    let journalRepository = SwiftDataJournalRepository(modelContainer: container)
    let space = DriftSpace(
      id: fixtureUUID("F1000000-0000-0000-0000-000000000002"),
      name: "Ideas",
      description: "Ideas",
      icon: "lightbulb"
    )
    let entry = JournalEntry(
      id: fixtureUUID("F1000000-0000-0000-0000-000000000003"),
      createdAt: Date(timeIntervalSince1970: 100),
      transcript: "An idea.",
      spaceIds: [space.id]
    )

    try await spaceRepository.saveSpace(space)
    try await journalRepository.saveEntry(entry)
    try await spaceRepository.deleteSpace(id: space.id)

    let fetchedSpace = try await spaceRepository.fetchSpace(id: space.id)
    let fetchedEntry = try await journalRepository.fetchEntry(id: entry.id)

    #expect(fetchedSpace == nil)
    #expect(fetchedEntry?.id == entry.id)
    #expect(fetchedEntry?.spaceIds == [space.id])
  }

  @Test
  func fetchSpacesSeedsDefaultsOnlyOnceForEmptyStore() async throws {
    let repository = try makeRepository()

    let seededSpaces = try await repository.fetchSpaces()

    #expect(Set(seededSpaces.map(\.name)) == Set(DriftSpace.defaultSpaces.map(\.name)))

    for space in seededSpaces {
      try await repository.deleteSpace(id: space.id)
    }

    let spacesAfterDeletingDefaults = try await repository.fetchSpaces()

    #expect(spacesAfterDeletingDefaults.isEmpty)
  }

  @Test
  func fetchSpacesDoesNotMixDefaultsIntoExistingUserSpaces() async throws {
    let repository = try makeRepository()
    let customSpace = DriftSpace(
      id: fixtureUUID("F1000000-0000-0000-0000-000000000004"),
      name: "Custom",
      description: "User-created Space",
      icon: "sparkles"
    )

    try await repository.saveSpace(customSpace)

    let spaces = try await repository.fetchSpaces()

    #expect(spaces == [customSpace])
  }

  private func makeRepository() throws -> SwiftDataSpaceRepository {
    SwiftDataSpaceRepository(
      modelContainer: try SwiftDataContainer.make(inMemory: true)
    )
  }
}
