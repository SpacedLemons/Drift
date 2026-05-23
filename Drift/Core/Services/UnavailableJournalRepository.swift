//
//  UnavailableJournalRepository.swift
//  Drift
//
//  Created by Lucas Stuart West Rogers on 12/05/2026.
//

import Foundation

final class UnavailableJournalRepository: JournalRepository, Sendable {
  func fetchEntries() async throws -> [JournalEntry] {
    []
  }

  func fetchEntry(id: UUID) async throws -> JournalEntry? {
    nil
  }

  func saveEntry(_ entry: JournalEntry) async throws {
    throw DriftServiceError.unavailable("Local Drift persistence is not wired yet.")
  }

  func updateEntry(_ entry: JournalEntry) async throws {
    throw DriftServiceError.unavailable("Local Drift persistence is not wired yet.")
  }

  func deleteEntry(id: UUID) async throws {
    throw DriftServiceError.unavailable("Local Drift persistence is not wired yet.")
  }

  func deleteAllEntries() async throws {
    throw DriftServiceError.unavailable("Local Drift persistence is not wired yet.")
  }

  func searchEntries(query: String) async throws -> [JournalEntry] {
    []
  }
}
