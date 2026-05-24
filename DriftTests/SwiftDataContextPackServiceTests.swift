//
//  SwiftDataContextPackServiceTests.swift
//  DriftTests
//
//  Created by Lucas Stuart West Rogers on 23/05/2026.
//

import Foundation
import Testing

@testable import Drift

struct SwiftDataContextPackServiceTests {
  @Test
  func savesFetchesAndDeletesContextPacks() async throws {
    let service = try makeService()
    let driftID = fixtureUUID("F2000000-0000-0000-0000-000000000001")
    let spaceID = fixtureUUID("F2000000-0000-0000-0000-000000000002")
    let pack = ContextPack(
      id: fixtureUUID("F2000000-0000-0000-0000-000000000003"),
      name: "OpenAI Application Context",
      description: "Curated context from Drift.",
      driftIds: [driftID],
      spaceIds: [spaceID],
      createdAt: Date(timeIntervalSince1970: 100),
      updatedAt: Date(timeIntervalSince1970: 200),
      aiVisibility: .privateLocalOnly
    )

    try await service.saveContextPack(pack)
    let savedPacks = try await service.fetchContextPacks()

    #expect(savedPacks == [pack])

    try await service.deleteContextPack(id: pack.id)
    let deletedPacks = try await service.fetchContextPacks()

    #expect(deletedPacks.isEmpty)
  }

  private func makeService() throws -> SwiftDataContextPackService {
    SwiftDataContextPackService(
      modelContainer: try SwiftDataContainer.make(inMemory: true)
    )
  }
}
