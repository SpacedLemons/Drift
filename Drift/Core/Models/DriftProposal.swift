//
//  DriftProposal.swift
//  Drift
//
//  Created by Lucas Stuart West Rogers on 24/05/2026.
//

import Foundation

struct DriftProposal: Identifiable, Equatable, Hashable, Codable, Sendable {
  var id: UUID
  var createdAt: Date
  var updatedAt: Date
  var source: DriftProposalSource
  var action: DriftProposalAction
  var status: DriftProposalStatus
  var title: String
  var body: String
  var suggestedDriftType: DriftType
  var suggestedSpaceIds: [UUID]
  var suggestedTags: [String]
  var suggestedMood: Mood?
  var targetDriftId: UUID?
  var targetSpaceId: UUID?
  var confidence: Double
  var summary: String

  init(
    id: UUID = UUID(),
    createdAt: Date = Date(),
    updatedAt: Date? = nil,
    source: DriftProposalSource = .gpt,
    action: DriftProposalAction,
    status: DriftProposalStatus = .pending,
    title: String,
    body: String,
    suggestedDriftType: DriftType,
    suggestedSpaceIds: [UUID] = [],
    suggestedTags: [String] = [],
    suggestedMood: Mood? = nil,
    targetDriftId: UUID? = nil,
    targetSpaceId: UUID? = nil,
    confidence: Double = 0.72,
    summary: String
  ) {
    self.id = id
    self.createdAt = createdAt
    self.updatedAt = updatedAt ?? createdAt
    self.source = source
    self.action = action
    self.status = status
    self.title = title
    self.body = body
    self.suggestedDriftType = suggestedDriftType
    self.suggestedSpaceIds = suggestedSpaceIds
    self.suggestedTags = suggestedTags
    self.suggestedMood = suggestedMood
    self.targetDriftId = targetDriftId
    self.targetSpaceId = targetSpaceId
    self.confidence = confidence
    self.summary = summary
  }
}

enum DriftProposalSource: String, Equatable, Codable, Sendable {
  case gpt
}

enum DriftProposalAction: String, CaseIterable, Identifiable, Codable, Hashable, Sendable {
  case createNewDrift
  case updateExistingDrift
  case appendToSpace
  case suggestSpace
  case createContextPack

  var id: String { rawValue }

  var displayName: String {
    switch self {
    case .createNewDrift: "Create Drift"
    case .updateExistingDrift: "Update Drift"
    case .appendToSpace: "Append to Space"
    case .suggestSpace: "Suggest Space"
    case .createContextPack: "Create Context Pack"
    }
  }
}

enum DriftProposalStatus: String, Equatable, Codable, Sendable {
  case pending
  case accepted
  case rejected
  case edited
  case saved

  var displayName: String {
    switch self {
    case .pending: "Pending"
    case .accepted: "Accepted"
    case .rejected: "Rejected"
    case .edited: "Edited"
    case .saved: "Saved"
    }
  }
}
