//
//  JournalRepository.swift
//  Drift
//
//  Created by Lucas Stuart West Rogers on 12/05/2026.
//

import Foundation
import Mockable

@Mockable
protocol JournalRepository {
  func fetchEntries() async throws -> [JournalEntry]
  func fetchEntry(id: UUID) async throws -> JournalEntry?
  func saveEntry(_ entry: JournalEntry) async throws
  func updateEntry(_ entry: JournalEntry) async throws
  func deleteEntry(id: UUID) async throws
  func deleteAllEntries() async throws
  func searchEntries(query: String) async throws -> [JournalEntry]
}
