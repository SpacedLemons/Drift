//
//  ChatGPTStarterPromptBuilderTests.swift
//  DriftTests
//
//  Created by Lucas Stuart West Rogers on 24/05/2026.
//

import Foundation
import Testing

@testable import Drift

struct ChatGPTStarterPromptBuilderTests {
  @Test
  func starterPromptIncludesSelectedSpacesAndContextPacks() {
    let space = DriftSpace(
      id: fixtureUUID("C3000000-0000-0000-0000-000000000001"),
      name: "Product",
      description: "Drift product context.",
      icon: AppIcons.sparkles
    )
    let contextPack = ContextPack(
      id: fixtureUUID("C3000000-0000-0000-0000-000000000002"),
      name: "Launch Notes",
      description: "Important launch details."
    )

    let prompt = ChatGPTStarterPromptBuilder().buildPrompt(
      selectedSpaces: [space],
      selectedContextPacks: [contextPack],
      settings: .default
    )

    #expect(prompt.contains("Product: Drift product context."))
    #expect(prompt.contains("Launch Notes: Important launch details."))
    #expect(!prompt.contains("No Drift Spaces selected yet."))
    #expect(!prompt.contains("No Context Packs selected yet."))
  }

  @Test
  func starterPromptIncludesDriftInstructions() {
    let prompt = ChatGPTStarterPromptBuilder().buildPrompt(
      selectedSpaces: [],
      selectedContextPacks: [],
      settings: .default
    )

    #expect(prompt.contains("I use an app called Drift as my personal context board."))
    #expect(prompt.contains("When I say \"Drift this\""))
    #expect(prompt.contains("- title"))
    #expect(prompt.contains("- key decisions"))
    #expect(prompt.contains("Ask before saving or updating anything."))
  }

  @Test
  func starterPromptReflectsFutureConnectionPreferences() {
    var settings = ChatGPTConnectionSettings.default
    settings.allowChatGPTSpaceSuggestions = false
    settings.allowChatGPTDriftProposals = true
    settings.allowChatGPTDriftUpdates = false

    let prompt = ChatGPTStarterPromptBuilder().buildPrompt(
      selectedSpaces: [],
      selectedContextPacks: [],
      settings: settings
    )

    #expect(prompt.contains("Allow ChatGPT to suggest Spaces: No"))
    #expect(prompt.contains("Allow ChatGPT to create Drift proposals: Yes"))
    #expect(prompt.contains("Allow ChatGPT to suggest updates to existing Drifts: No"))
  }
}
