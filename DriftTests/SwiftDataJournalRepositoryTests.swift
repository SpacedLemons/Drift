//
//  SwiftDataJournalRepositoryTests.swift
//  DriftTests
//
//  Created by Lucas Stuart West Rogers on 12/05/2026.
//

import Foundation
import Testing

@testable import Drift

struct SwiftDataJournalRepositoryTests {
  @Test
  func savesAndFetchesEntriesNewestFirst() async throws {
    let repository = try makeRepository()
    let olderEntry = makeRepositoryEntry(
      id: fixtureUUID("A0000000-0000-0000-0000-000000000001"),
      createdAt: Date(timeIntervalSince1970: 100)
    )
    let newerEntry = makeRepositoryEntry(
      id: fixtureUUID("A0000000-0000-0000-0000-000000000002"),
      createdAt: Date(timeIntervalSince1970: 200)
    )

    try await repository.saveEntry(olderEntry)
    try await repository.saveEntry(newerEntry)

    let entries = try await repository.fetchEntries()
    let fetchedEntry = try await repository.fetchEntry(id: olderEntry.id)

    #expect(entries.map(\.id) == [newerEntry.id, olderEntry.id])
    #expect(fetchedEntry == olderEntry)
  }

  @Test
  func updatesEntries() async throws {
    let repository = try makeRepository()
    let entry = makeRepositoryEntry()
    var updatedEntry = entry
    updatedEntry.updatedAt = Date(timeIntervalSince1970: 300)
    updatedEntry.title = "Updated title"
    updatedEntry.transcript = "Updated transcript with a searchable phrase."
    updatedEntry.mood = .reflective
    updatedEntry.themes = [.growth]
    updatedEntry.customThemes = [CustomJournalTheme(name: "Side project")]
    updatedEntry.tags = ["updated"]
    updatedEntry.imageAttachments = [JournalImageAttachment(localFileName: "updated.jpg")]
    updatedEntry.isFavorite = true

    try await repository.saveEntry(entry)
    try await repository.updateEntry(updatedEntry)

    let fetchedEntry = try await repository.fetchEntry(id: entry.id)

    #expect(fetchedEntry == updatedEntry)
  }

  @Test
  func deletesEntries() async throws {
    let repository = try makeRepository()
    let entry = makeRepositoryEntry()

    try await repository.saveEntry(entry)
    try await repository.deleteEntry(id: entry.id)

    let fetchedEntry = try await repository.fetchEntry(id: entry.id)

    #expect(fetchedEntry == nil)
  }

  @Test
  func deletesAllEntries() async throws {
    let repository = try makeRepository()

    try await repository.saveEntry(
      makeRepositoryEntry(id: fixtureUUID("A0000000-0000-0000-0000-000000000003"))
    )
    try await repository.saveEntry(
      makeRepositoryEntry(id: fixtureUUID("A0000000-0000-0000-0000-000000000004"))
    )
    try await repository.deleteAllEntries()

    let entries = try await repository.fetchEntries()

    #expect(entries.isEmpty)
  }

  @Test
  func searchesByTranscriptTitleAndTag() async throws {
    let repository = try makeRepository()
    let transcriptEntry = makeRepositoryEntry(
      id: fixtureUUID("A0000000-0000-0000-0000-000000000005"),
      transcript: "A transcript containing the lavender keyword."
    )
    let titleEntry = makeRepositoryEntry(
      id: fixtureUUID("A0000000-0000-0000-0000-000000000006"),
      title: "Harbour planning"
    )
    let tagEntry = makeRepositoryEntry(
      id: fixtureUUID("A0000000-0000-0000-0000-000000000007"),
      tags: ["ritual"]
    )

    try await repository.saveEntry(transcriptEntry)
    try await repository.saveEntry(titleEntry)
    try await repository.saveEntry(tagEntry)

    let transcriptResults = try await repository.searchEntries(query: "LAVENDER")
    let titleResults = try await repository.searchEntries(query: "harbour")
    let tagResults = try await repository.searchEntries(query: "ritual")

    #expect(transcriptResults.map(\.id) == [transcriptEntry.id])
    #expect(titleResults.map(\.id) == [titleEntry.id])
    #expect(tagResults.map(\.id) == [tagEntry.id])
  }

  @Test
  func searchesByThemeAndReturnsNewestFirst() async throws {
    let repository = try makeRepository()
    let olderEntry = makeRepositoryEntry(
      id: fixtureUUID("A0000000-0000-0000-0000-000000000008"),
      createdAt: Date(timeIntervalSince1970: 100),
      transcript: "Older health note.",
      tags: [],
      themes: [.health]
    )
    let newerEntry = makeRepositoryEntry(
      id: fixtureUUID("A0000000-0000-0000-0000-000000000009"),
      createdAt: Date(timeIntervalSince1970: 200),
      transcript: "Newer health note.",
      tags: [],
      themes: [.health]
    )

    try await repository.saveEntry(olderEntry)
    try await repository.saveEntry(newerEntry)

    let results = try await repository.searchEntries(query: "Health")

    #expect(results.map(\.id) == [newerEntry.id, olderEntry.id])
  }

  @Test
  func searchesByCustomTheme() async throws {
    let repository = try makeRepository()
    let entry = makeRepositoryEntry(
      id: fixtureUUID("A0000000-0000-0000-0000-000000000010"),
      customThemes: [CustomJournalTheme(name: "Side project")]
    )

    try await repository.saveEntry(entry)

    let results = try await repository.searchEntries(query: "side project")

    #expect(results.map(\.id) == [entry.id])
  }

  private func makeRepository() throws -> SwiftDataJournalRepository {
    SwiftDataJournalRepository(
      modelContainer: try SwiftDataContainer.make(inMemory: true)
    )
  }

  private func makeRepositoryEntry(
    id: UUID = fixtureUUID("A0000000-0000-0000-0000-000000000000"),
    createdAt: Date = Date(timeIntervalSince1970: 100),
    transcript: String = "A repository journal entry.",
    title: String? = "Repository entry",
    tags: [String] = ["repository"],
    themes: [JournalTheme] = [.work],
    customThemes: [CustomJournalTheme] = [],
    imageAttachments: [JournalImageAttachment] = []
  ) -> JournalEntry {
    JournalEntry(
      id: id,
      createdAt: createdAt,
      updatedAt: createdAt,
      transcript: transcript,
      title: title,
      mood: .positive,
      moodConfidence: 0.75,
      themes: themes,
      customThemes: customThemes,
      tags: tags,
      duration: 60,
      source: .voice,
      imageAttachments: imageAttachments
    )
  }
}
