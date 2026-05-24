//
//  ContextPackEntity.swift
//  Drift
//
//  Created by Lucas Stuart West Rogers on 23/05/2026.
//

import Foundation
import SwiftData

@Model
final class ContextPackEntity {
  @Attribute(.unique) var id: UUID
  var name: String
  var packDescription: String
  var driftIdsData: Data
  var spaceIdsData: Data
  var createdAt: Date
  var updatedAt: Date
  var aiVisibilityRawValue: String?

  init(
    id: UUID,
    name: String,
    packDescription: String,
    driftIdsData: Data,
    spaceIdsData: Data,
    createdAt: Date,
    updatedAt: Date,
    aiVisibilityRawValue: String?
  ) {
    self.id = id
    self.name = name
    self.packDescription = packDescription
    self.driftIdsData = driftIdsData
    self.spaceIdsData = spaceIdsData
    self.createdAt = createdAt
    self.updatedAt = updatedAt
    self.aiVisibilityRawValue = aiVisibilityRawValue
  }
}
