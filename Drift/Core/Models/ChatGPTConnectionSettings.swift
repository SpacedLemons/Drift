//
//  ChatGPTConnectionSettings.swift
//  Drift
//
//  Created by Lucas Stuart West Rogers on 24/05/2026.
//

import Foundation

struct ChatGPTConnectionSettings: Equatable, Codable, Sendable {
  var allowChatGPTSpaceSuggestions: Bool
  var requireReviewBeforeSaving: Bool
  var allowChatGPTDriftProposals: Bool
  var allowChatGPTDriftUpdates: Bool
  var selectedSpaceIds: Set<UUID>
  var selectedContextPackIds: Set<UUID>

  static let `default` = ChatGPTConnectionSettings(
    allowChatGPTSpaceSuggestions: true,
    requireReviewBeforeSaving: true,
    allowChatGPTDriftProposals: false,
    allowChatGPTDriftUpdates: true,
    selectedSpaceIds: [],
    selectedContextPackIds: []
  )
}

struct PendingChatGPTUpdate: Identifiable, Equatable, Codable, Sendable {
  var id: UUID
  var title: String
  var createdAt: Date
}
