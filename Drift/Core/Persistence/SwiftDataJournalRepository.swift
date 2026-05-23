//
//  SwiftDataJournalRepository.swift
//  Drift
//
//  Created by Lucas Stuart West Rogers on 12/05/2026.
//

import Foundation
import SwiftData

@ModelActor
actor SwiftDataJournalRepository: JournalRepository {
  func fetchEntries() async throws -> [JournalEntry] {
    do {
      let descriptor = FetchDescriptor<JournalEntryEntity>(
        sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
      )
      return try modelContext.fetch(descriptor).map(JournalEntryMapper.model)
    } catch {
      throw JournalRepositoryError.fetchFailed
    }
  }

  func fetchEntry(id: UUID) async throws -> JournalEntry? {
    do {
      return try fetchEntity(id: id).map(JournalEntryMapper.model)
    } catch let error as JournalRepositoryError {
      throw error
    } catch {
      throw JournalRepositoryError.fetchFailed
    }
  }

  func saveEntry(_ entry: JournalEntry) async throws {
    do {
      if let existingEntity = try fetchEntity(id: entry.id) {
        try JournalEntryMapper.update(existingEntity, with: entry)
      } else {
        let entity = try JournalEntryMapper.entity(from: entry)
        modelContext.insert(entity)
      }

      try modelContext.save()
    } catch {
      throw JournalRepositoryError.saveFailed
    }
  }

  func updateEntry(_ entry: JournalEntry) async throws {
    do {
      guard let existingEntity = try fetchEntity(id: entry.id) else {
        throw JournalRepositoryError.entryNotFound
      }

      try JournalEntryMapper.update(existingEntity, with: entry)
      try modelContext.save()
    } catch let error as JournalRepositoryError {
      throw error
    } catch {
      throw JournalRepositoryError.updateFailed
    }
  }

  func deleteEntry(id: UUID) async throws {
    do {
      guard let entity = try fetchEntity(id: id) else {
        throw JournalRepositoryError.entryNotFound
      }

      modelContext.delete(entity)
      try modelContext.save()
    } catch let error as JournalRepositoryError {
      throw error
    } catch {
      throw JournalRepositoryError.deleteFailed
    }
  }

  func deleteAllEntries() async throws {
    do {
      let entities = try modelContext.fetch(FetchDescriptor<JournalEntryEntity>())
      entities.forEach(modelContext.delete)
      try modelContext.save()
    } catch {
      throw JournalRepositoryError.deleteFailed
    }
  }

  func searchEntries(query: String) async throws -> [JournalEntry] {
    let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmedQuery.isEmpty else {
      return try await fetchEntries()
    }

    let lowercasedQuery = trimmedQuery.lowercased()
    return try await fetchEntries().filter { entry in
      searchableText(for: entry).contains(lowercasedQuery)
    }
  }

  private func fetchEntity(id: UUID) throws -> JournalEntryEntity? {
    var descriptor = FetchDescriptor<JournalEntryEntity>(
      predicate: #Predicate { entity in
        entity.id == id
      }
    )
    descriptor.fetchLimit = 1
    return try modelContext.fetch(descriptor).first
  }

  private func searchableText(for entry: JournalEntry) -> String {
    [
      entry.title ?? "",
      entry.transcript,
      entry.mood?.rawValue ?? "",
      entry.mood?.displayName ?? "",
      entry.driftType.rawValue,
      entry.driftType.displayName,
      entry.themes.map(\.rawValue).joined(separator: " "),
      entry.themes.map(\.displayName).joined(separator: " "),
      entry.customThemes.map(\.displayName).joined(separator: " "),
      entry.tags.joined(separator: " "),
    ]
    .joined(separator: " ")
    .lowercased()
  }
}
