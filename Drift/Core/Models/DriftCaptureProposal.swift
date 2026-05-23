//
//  DriftCaptureProposal.swift
//  Drift
//
//  Created by Lucas Stuart West Rogers on 23/05/2026.
//

import Foundation

struct DriftCaptureProposal: Identifiable, Hashable, Codable, Sendable {
  var id: UUID
  var createdAt: Date
  var title: String?
  var body: String
  var suggestedType: DriftType
  var suggestedMood: Mood?
  var suggestedTags: [String]
  var suggestedSpaceIds: [UUID]
  var source: DriftSource
  var aiVisibility: AIVisibility

  init(
    id: UUID = UUID(),
    createdAt: Date = Date(),
    title: String? = nil,
    body: String,
    suggestedType: DriftType = .reflection,
    suggestedMood: Mood? = nil,
    suggestedTags: [String] = [],
    suggestedSpaceIds: [UUID] = [],
    source: DriftSource = .voice,
    aiVisibility: AIVisibility = .privateLocalOnly
  ) {
    self.id = id
    self.createdAt = createdAt
    self.title = title
    self.body = body
    self.suggestedType = suggestedType
    self.suggestedMood = suggestedMood
    self.suggestedTags = suggestedTags
    self.suggestedSpaceIds = suggestedSpaceIds
    self.source = source
    self.aiVisibility = aiVisibility
  }
}
