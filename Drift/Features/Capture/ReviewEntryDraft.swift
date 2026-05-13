//
//  ReviewEntryDraft.swift
//  Drift
//
//  Created by Lucas Stuart West Rogers on 12/05/2026.
//

import Foundation

struct ReviewEntryDraft: Hashable, Sendable {
  var id: UUID
  var audioURL: URL
  var duration: TimeInterval
  var createdAt: Date
  var transcript: String
  var suggestedMood: Mood
  var suggestedThemes: [JournalTheme]
  var tags: [String]
}
