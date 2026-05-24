//
//  GPTConnectionModels.swift
//  Drift
//
//  Created by Lucas Stuart West Rogers on 24/05/2026.
//

import Foundation

enum GPTConnectionState: String, Equatable, Codable, Sendable {
  case notConnected
  case connected

  var displayName: String {
    switch self {
    case .notConnected: "Not connected"
    case .connected: "Connected"
    }
  }
}

enum GPTConnectionMethod: String, CaseIterable, Identifiable, Equatable, Codable, Sendable {
  case passkey
  case apple

  var id: String { rawValue }

  var displayName: String {
    switch self {
    case .passkey: "Passkey"
    case .apple: "Apple"
    }
  }
}

struct GPTConnectionSettings: Equatable, Codable, Sendable {
  var requireReviewBeforeSaving: Bool
  var autoDriftConversations: Bool
  var selectedSpaceIds: Set<UUID>

  static let `default` = GPTConnectionSettings(
    requireReviewBeforeSaving: true,
    autoDriftConversations: false,
    selectedSpaceIds: []
  )
}

struct GPTConnectionSnapshot: Equatable, Codable, Sendable {
  var state: GPTConnectionState
  var connectedAt: Date?
  var method: GPTConnectionMethod?
  var settings: GPTConnectionSettings

  static let `default` = GPTConnectionSnapshot(
    state: .notConnected,
    connectedAt: nil,
    method: nil,
    settings: .default
  )
}

struct GPTActivityItem: Identifiable, Equatable, Codable, Sendable {
  var id: UUID
  var createdAt: Date
  var kind: GPTActivityKind
  var title: String
  var subtitle: String
  var relatedDriftId: UUID?
  var relatedSpaceId: UUID?
  var status: GPTActivityStatus

  init(
    id: UUID = UUID(),
    createdAt: Date = Date(),
    kind: GPTActivityKind,
    title: String,
    subtitle: String,
    relatedDriftId: UUID? = nil,
    relatedSpaceId: UUID? = nil,
    status: GPTActivityStatus = .completed
  ) {
    self.id = id
    self.createdAt = createdAt
    self.kind = kind
    self.title = title
    self.subtitle = subtitle
    self.relatedDriftId = relatedDriftId
    self.relatedSpaceId = relatedSpaceId
    self.status = status
  }
}

enum GPTActivityKind: String, CaseIterable, Identifiable, Codable, Hashable, Sendable {
  case createdDrift
  case updatedDrift
  case suggestedSpace
  case createdProposal
  case acceptedProposal
  case rejectedProposal

  var id: String { rawValue }

  var displayName: String {
    switch self {
    case .createdDrift: "Created Drift"
    case .updatedDrift: "Updated Drift"
    case .suggestedSpace: "Suggested Space"
    case .createdProposal: "Created Proposal"
    case .acceptedProposal: "Accepted Proposal"
    case .rejectedProposal: "Rejected Proposal"
    }
  }
}

enum GPTActivityStatus: String, Equatable, Codable, Sendable {
  case pending
  case completed
}
