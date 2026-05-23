//
//  ContextPack.swift
//  Drift
//
//  Created by Lucas Stuart West Rogers on 23/05/2026.
//

import Foundation

struct ContextPack: Identifiable, Hashable, Codable, Sendable {
  var id: UUID
  var name: String
  var description: String
  var driftIds: [UUID]
  var spaceIds: [UUID]
  var createdAt: Date
  var updatedAt: Date
  var aiVisibility: AIVisibility

  init(
    id: UUID = UUID(),
    name: String,
    description: String,
    driftIds: [UUID] = [],
    spaceIds: [UUID] = [],
    createdAt: Date = Date(),
    updatedAt: Date? = nil,
    aiVisibility: AIVisibility = .privateLocalOnly
  ) {
    self.id = id
    self.name = name
    self.description = description
    self.driftIds = driftIds
    self.spaceIds = spaceIds
    self.createdAt = createdAt
    self.updatedAt = updatedAt ?? createdAt
    self.aiVisibility = aiVisibility
  }
}
