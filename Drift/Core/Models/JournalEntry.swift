//
//  JournalEntry.swift
//  Drift
//
//  Created by Lucas Stuart West Rogers on 12/05/2026.
//

import Foundation

struct JournalEntry: Identifiable, Hashable, Codable, Sendable {
  var id: UUID
  var createdAt: Date
  var updatedAt: Date
  var transcript: String
  var title: String?
  var mood: Mood?
  var moodConfidence: Double?
  var themes: [JournalTheme]
  var customThemes: [CustomJournalTheme]
  var tags: [String]
  var duration: TimeInterval?
  var source: EntrySource
  var isFavorite: Bool
  var imageAttachments: [JournalImageAttachment]
  var driftType: DriftType
  var aiVisibility: AIVisibility
  var driftStatus: DriftStatus

  init(
    id: UUID = UUID(),
    createdAt: Date,
    updatedAt: Date? = nil,
    transcript: String,
    title: String? = nil,
    mood: Mood? = nil,
    moodConfidence: Double? = nil,
    themes: [JournalTheme] = [],
    customThemes: [CustomJournalTheme] = [],
    tags: [String] = [],
    duration: TimeInterval? = nil,
    source: EntrySource = .voice,
    isFavorite: Bool = false,
    imageAttachments: [JournalImageAttachment] = [],
    driftType: DriftType = .reflection,
    aiVisibility: AIVisibility = .privateLocalOnly,
    driftStatus: DriftStatus = .active
  ) {
    self.id = id
    self.createdAt = createdAt
    self.updatedAt = updatedAt ?? createdAt
    self.transcript = transcript
    self.title = title
    self.mood = mood
    self.moodConfidence = moodConfidence
    self.themes = themes
    self.customThemes = customThemes
    self.tags = tags
    self.duration = duration
    self.source = source
    self.isFavorite = isFavorite
    self.imageAttachments = imageAttachments
    self.driftType = driftType
    self.aiVisibility = aiVisibility
    self.driftStatus = driftStatus
  }

  var displayTitle: String {
    if let title, !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
      return title
    }

    return
      transcript
      .components(separatedBy: .newlines)
      .first?
      .trimmingCharacters(in: .whitespacesAndNewlines)
      .nonEmpty ?? "\(driftType.displayName) Drift"
  }

  var previewText: String {
    transcript
      .trimmingCharacters(in: .whitespacesAndNewlines)
      .nonEmpty ?? "No transcript yet"
  }
}

extension String {
  fileprivate var nonEmpty: String? {
    isEmpty ? nil : self
  }
}
