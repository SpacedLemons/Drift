//
//  JournalBackedDriftRepository.swift
//  Drift
//
//  Created by Lucas Stuart West Rogers on 23/05/2026.
//

import Foundation

struct JournalBackedDriftRepository: DriftRepository, Sendable {
  private let journalRepository: any JournalRepository & Sendable

  init(journalRepository: any JournalRepository & Sendable) {
    self.journalRepository = journalRepository
  }

  func fetchDrifts() async throws -> [DriftItem] {
    try await journalRepository.fetchEntries().map {
      JournalEntryToDriftItemMapper.driftItem(from: $0)
    }
  }

  func fetchDrift(id: UUID) async throws -> DriftItem? {
    try await journalRepository.fetchEntry(id: id).map {
      JournalEntryToDriftItemMapper.driftItem(from: $0)
    }
  }

  func saveDrift(_ drift: DriftItem) async throws {
    let existingEntry = try await journalRepository.fetchEntry(id: drift.id)
    let entry = DriftItemToJournalEntryMapper.journalEntry(
      from: drift,
      preserving: existingEntry
    )
    try await journalRepository.saveEntry(entry)
  }

  func updateDrift(_ drift: DriftItem) async throws {
    let existingEntry = try await journalRepository.fetchEntry(id: drift.id)
    let entry = DriftItemToJournalEntryMapper.journalEntry(
      from: drift,
      preserving: existingEntry
    )
    try await journalRepository.updateEntry(entry)
  }

  func deleteDrift(id: UUID) async throws {
    try await journalRepository.deleteEntry(id: id)
  }

  func searchDrifts(query: String) async throws -> [DriftItem] {
    try await journalRepository.searchEntries(query: query)
      .map {
        JournalEntryToDriftItemMapper.driftItem(from: $0)
      }
  }
}
