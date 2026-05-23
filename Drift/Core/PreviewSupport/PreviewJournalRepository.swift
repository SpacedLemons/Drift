//
//  PreviewJournalRepository.swift
//  Drift
//
//  Created by Lucas Stuart West Rogers on 12/05/2026.
//

import Foundation

actor PreviewJournalRepository: JournalRepository {
  private var entries: [JournalEntry]

  init(entries: [JournalEntry] = PreviewData.journalEntries) {
    self.entries = entries
  }

  func fetchEntries() async throws -> [JournalEntry] {
    sorted(entries)
  }

  func fetchEntry(id: UUID) async throws -> JournalEntry? {
    entries.first { $0.id == id }
  }

  func saveEntry(_ entry: JournalEntry) async throws {
    entries.removeAll { $0.id == entry.id }
    entries.append(entry)
  }

  func updateEntry(_ entry: JournalEntry) async throws {
    guard let index = entries.firstIndex(where: { $0.id == entry.id }) else {
      throw DriftServiceError.notFound
    }
    entries[index] = entry
  }

  func deleteEntry(id: UUID) async throws {
    entries.removeAll { $0.id == id }
  }

  func deleteAllEntries() async throws {
    entries.removeAll()
  }

  func searchEntries(query: String) async throws -> [JournalEntry] {
    let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmedQuery.isEmpty else {
      return try await fetchEntries()
    }

    return sorted(entries).filter { entry in
      entry.matchesSearch(trimmedQuery)
    }
  }

  private func sorted(_ entries: [JournalEntry]) -> [JournalEntry] {
    entries.sorted { $0.createdAt > $1.createdAt }
  }
}

extension JournalEntry {
  fileprivate func matchesSearch(_ query: String) -> Bool {
    let lowercasedQuery = query.lowercased()
    let searchableValues = [
      title ?? "",
      transcript,
      mood?.displayName ?? "",
      driftType.displayName,
      themes.map(\.displayName).joined(separator: " "),
      customThemes.map(\.displayName).joined(separator: " "),
      tags.joined(separator: " "),
    ]

    return
      searchableValues
      .joined(separator: " ")
      .lowercased()
      .contains(lowercasedQuery)
  }
}
