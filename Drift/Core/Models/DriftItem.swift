//
//  DriftItem.swift
//  Drift
//
//  Created by Lucas Stuart West Rogers on 23/05/2026.
//

import Foundation

struct DriftItem: Identifiable, Hashable, Codable, Sendable {
  var id: UUID
  var createdAt: Date
  var updatedAt: Date
  var title: String?
  var body: String
  var type: DriftType
  var mood: Mood?
  var tags: [String]
  var spaces: [UUID]
  var attachments: [JournalImageAttachment]
  var source: DriftSource
  var aiVisibility: AIVisibility
  var status: DriftStatus
  var linkedDriftIds: [UUID]
  var linkedGoalIds: [UUID]

  init(
    id: UUID = UUID(),
    createdAt: Date,
    updatedAt: Date? = nil,
    title: String? = nil,
    body: String,
    type: DriftType = .reflection,
    mood: Mood? = nil,
    tags: [String] = [],
    spaces: [UUID] = [],
    attachments: [JournalImageAttachment] = [],
    source: DriftSource = .voice,
    aiVisibility: AIVisibility = .privateLocalOnly,
    status: DriftStatus = .active,
    linkedDriftIds: [UUID] = [],
    linkedGoalIds: [UUID] = []
  ) {
    self.id = id
    self.createdAt = createdAt
    self.updatedAt = updatedAt ?? createdAt
    self.title = title
    self.body = body
    self.type = type
    self.mood = mood
    self.tags = tags
    self.spaces = spaces
    self.attachments = attachments
    self.source = source
    self.aiVisibility = aiVisibility
    self.status = status
    self.linkedDriftIds = linkedDriftIds
    self.linkedGoalIds = linkedGoalIds
  }

  var transcript: String { body }
}
