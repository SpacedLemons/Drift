//
//  SwiftDataContainer.swift
//  Drift
//
//  Created by Lucas Stuart West Rogers on 12/05/2026.
//

import SwiftData

enum SwiftDataContainer {
  static func make(inMemory: Bool = false) throws -> ModelContainer {
    let schema = Schema([
      JournalEntryEntity.self
    ])
    // Add explicit migration plans before removing or renaming persisted fields.
    // New codable metadata fields should keep safe empty defaults.
    let configuration = ModelConfiguration(
      schema: schema,
      isStoredInMemoryOnly: inMemory
    )

    return try ModelContainer(
      for: schema,
      configurations: [configuration]
    )
  }
}
