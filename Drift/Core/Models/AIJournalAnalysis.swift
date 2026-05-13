//
//  AIJournalAnalysis.swift
//  Drift
//
//  Created by Lucas Stuart West Rogers on 12/05/2026.
//

struct AIJournalAnalysis: Hashable, Codable, Sendable {
  var summary: String?
  var suggestedMood: Mood?
  var suggestedThemes: [JournalTheme]
}
