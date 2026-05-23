//
//  DriftSpace.swift
//  Drift
//
//  Created by Lucas Stuart West Rogers on 23/05/2026.
//

import Foundation

struct DriftSpace: Identifiable, Hashable, Codable, Sendable {
  var id: UUID
  var name: String
  var description: String
  var icon: String
  var accentColorHex: String?
  var createdAt: Date
  var updatedAt: Date
  var isPinned: Bool
  var aiVisibility: AIVisibility

  init(
    id: UUID = UUID(),
    name: String,
    description: String,
    icon: String = AppIcons.book,
    accentColorHex: String? = nil,
    createdAt: Date = Date(),
    updatedAt: Date? = nil,
    isPinned: Bool = false,
    aiVisibility: AIVisibility = .privateLocalOnly
  ) {
    self.id = id
    self.name = name
    self.description = description
    self.icon = icon
    self.accentColorHex = accentColorHex
    self.createdAt = createdAt
    self.updatedAt = updatedAt ?? createdAt
    self.isPinned = isPinned
    self.aiVisibility = aiVisibility
  }

  static let placeholderSpaces: [DriftSpace] = [
    DriftSpace(
      id: uuid("D0000000-0000-0000-0000-000000000001"),
      name: "Inbox",
      description: "Fresh Drifts before they are grouped.",
      icon: "tray",
      isPinned: true
    ),
    DriftSpace(
      id: uuid("D0000000-0000-0000-0000-000000000002"),
      name: "Goals",
      description: "Goals, milestones, and next steps.",
      icon: "target",
      isPinned: true
    ),
    DriftSpace(
      id: uuid("D0000000-0000-0000-0000-000000000003"),
      name: "Ideas",
      description: "Ideas, sparks, and things worth revisiting.",
      icon: "lightbulb"
    ),
    DriftSpace(
      id: uuid("D0000000-0000-0000-0000-000000000004"),
      name: "Memories",
      description: "Moments and context you may want later.",
      icon: "clock.arrow.circlepath"
    ),
  ]

  private static func uuid(_ rawValue: String) -> UUID {
    UUID(uuidString: rawValue) ?? UUID()
  }
}
