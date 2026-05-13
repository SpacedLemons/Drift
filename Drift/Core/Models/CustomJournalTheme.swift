//
//  CustomJournalTheme.swift
//  Drift
//
//  Created by Lucas Stuart West Rogers on 13/05/2026.
//

import Foundation

struct CustomJournalTheme: Identifiable, Hashable, Codable, Sendable {
  var id: UUID
  var name: String
  var createdAt: Date

  init(
    id: UUID = UUID(),
    name: String,
    createdAt: Date = Date()
  ) {
    self.id = id
    self.name = name
    self.createdAt = createdAt
  }

  var displayName: String {
    name.trimmingCharacters(in: .whitespacesAndNewlines)
  }
}
