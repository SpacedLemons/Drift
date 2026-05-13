//
//  LocalMoodAnalysisService.swift
//  Drift
//
//  Created by Lucas Stuart West Rogers on 12/05/2026.
//

final class LocalMoodAnalysisService: MoodAnalysisService, Sendable {
  func suggestMood(from transcript: String) async throws -> Mood {
    let text = transcript.lowercased()

    if text.containsAny(["grateful", "good", "calm", "focused", "happy"]) {
      return .positive
    }

    if text.containsAny(["stress", "stressed", "overwhelmed", "deadline"]) {
      return .stressed
    }

    if text.containsAny(["anxious", "worried", "nervous"]) {
      return .anxious
    }

    if text.containsAny(["low", "sad", "tired", "heavy"]) {
      return .low
    }

    if text.containsAny(["thinking", "noticed", "realised", "quiet"]) {
      return .reflective
    }

    return .neutral
  }

  func suggestThemes(from transcript: String) async throws -> [JournalTheme] {
    let text = transcript.lowercased()
    var themes: [JournalTheme] = []

    append(.work, to: &themes, when: text.containsAny(["work", "meeting", "deadline", "inbox"]))
    append(
      .productivity, to: &themes, when: text.containsAny(["focused", "planning", "task", "inbox"]))
    append(
      .relationships, to: &themes, when: text.containsAny(["friend", "partner", "relationship"]))
    append(.health, to: &themes, when: text.containsAny(["sleep", "walk", "health", "body"]))
    append(.gratitude, to: &themes, when: text.containsAny(["grateful", "thankful", "appreciate"]))
    append(.family, to: &themes, when: text.containsAny(["family", "home"]))
    append(.growth, to: &themes, when: text.containsAny(["learn", "growing", "practice"]))
    append(.challenge, to: &themes, when: text.containsAny(["hard", "challenge", "stuck"]))

    return themes.isEmpty ? [.other] : themes
  }

  private func append(_ theme: JournalTheme, to themes: inout [JournalTheme], when condition: Bool)
  {
    guard condition, !themes.contains(theme) else { return }
    themes.append(theme)
  }
}

extension String {
  fileprivate func containsAny(_ values: [String]) -> Bool {
    values.contains { contains($0) }
  }
}
