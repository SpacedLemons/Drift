//
//  ChatGPTStarterPromptBuilder.swift
//  Drift
//
//  Created by Lucas Stuart West Rogers on 24/05/2026.
//

import Foundation

struct ChatGPTStarterPromptBuilder: Sendable {
  func buildPrompt(
    selectedSpaces: [DriftSpace],
    selectedContextPacks: [ContextPack],
    settings: ChatGPTConnectionSettings
  ) -> String {
    let spaceLines = selectedSpaces.promptLines(emptyMessage: "No Drift Spaces selected yet.")
    let contextPackLines = selectedContextPacks.promptLines(
      emptyMessage: "No Context Packs selected yet."
    )

    return """
      I use an app called Drift as my personal context board.

      When I say "Drift this", summarise the useful parts of our conversation into a structured Drift.

      A Drift should include:
      - title
      - type
      - summary
      - key decisions
      - action items
      - suggested Space
      - tags

      Ask before saving or updating anything.

      My selected Drift Spaces are:
      \(spaceLines)

      My selected Context Packs are:
      \(contextPackLines)

      My Drift connection preferences are:
      - Require review before saving GPT-created Drifts: \(settings.requireReviewBeforeSaving.yesNo)
      - Allow ChatGPT to suggest Spaces: \(settings.allowChatGPTSpaceSuggestions.yesNo)
      - Allow ChatGPT to create Drift proposals: \(settings.allowChatGPTDriftProposals.yesNo)
      - Allow ChatGPT to suggest updates to existing Drifts: \(settings.allowChatGPTDriftUpdates.yesNo)

      Nothing should be saved or updated until I review it.
      """
  }
}

extension Array where Element == DriftSpace {
  fileprivate func promptLines(emptyMessage: String) -> String {
    guard !isEmpty else { return "- \(emptyMessage)" }

    return sorted { $0.name < $1.name }
      .map { space in
        "- \(space.name): \(space.description)"
      }
      .joined(separator: "\n")
  }
}

extension Array where Element == ContextPack {
  fileprivate func promptLines(emptyMessage: String) -> String {
    guard !isEmpty else { return "- \(emptyMessage)" }

    return sorted { $0.name < $1.name }
      .map { pack in
        "- \(pack.name): \(pack.description)"
      }
      .joined(separator: "\n")
  }
}

extension Bool {
  fileprivate var yesNo: String {
    self ? "Yes" : "No"
  }
}
