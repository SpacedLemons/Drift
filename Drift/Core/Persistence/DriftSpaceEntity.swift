//
//  DriftSpaceEntity.swift
//  Drift
//
//  Created by Lucas Stuart West Rogers on 23/05/2026.
//

import Foundation
import SwiftData

@Model
final class DriftSpaceEntity {
  @Attribute(.unique) var id: UUID
  var name: String
  var spaceDescription: String
  var icon: String
  var accentColorHex: String?
  var createdAt: Date
  var updatedAt: Date
  var isPinned: Bool
  var aiVisibilityRawValue: String?

  init(
    id: UUID,
    name: String,
    spaceDescription: String,
    icon: String,
    accentColorHex: String?,
    createdAt: Date,
    updatedAt: Date,
    isPinned: Bool,
    aiVisibilityRawValue: String?
  ) {
    self.id = id
    self.name = name
    self.spaceDescription = spaceDescription
    self.icon = icon
    self.accentColorHex = accentColorHex
    self.createdAt = createdAt
    self.updatedAt = updatedAt
    self.isPinned = isPinned
    self.aiVisibilityRawValue = aiVisibilityRawValue
  }
}
