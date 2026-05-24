//
//  ChatGPTConnectionViewModelTests.swift
//  DriftTests
//
//  Created by Lucas Stuart West Rogers on 24/05/2026.
//

import Foundation
import Testing

@testable import Drift

@MainActor
struct ChatGPTConnectionViewModelTests {
  @Test
  func localDriftFeaturesDoNotRequireConnectedAccountState() async throws {
    let viewModel = makeViewModel()

    await viewModel.load()

    #expect(viewModel.connectionState == .notConnected)
    #expect(viewModel.isLocalUseAllowed)
  }

  @Test
  func loadDoesNotSelectEverySpaceByDefault() async throws {
    let viewModel = makeViewModel()

    await viewModel.load()

    #expect(!viewModel.spaces.isEmpty)
    #expect(viewModel.settings.selectedSpaceIds.isEmpty)
    #expect(viewModel.selectedSpaces.isEmpty)
  }

  @Test
  func selectedSpacesArePersistedThroughViewModel() async throws {
    let service = LocalChatGPTConnectionService(
      userDefaults: UserDefaults(suiteName: "DriftTests.ViewModel.\(UUID().uuidString)")
        ?? .standard
    )
    let viewModel = makeViewModel(chatGPTConnectionService: service)

    await viewModel.load()
    let space = try #require(viewModel.spaces.first)
    await viewModel.toggleSpaceSelection(space)
    let loadedSettings = try await service.loadSettings()

    #expect(loadedSettings.selectedSpaceIds == [space.id])
  }

  @Test
  func startInChatGPTPlaceholderCopiesPromptWithoutUploadingData() async throws {
    let service = TrackingChatGPTConnectionService()
    var copiedPrompt: String?
    let viewModel = makeViewModel(
      chatGPTConnectionService: service,
      pasteboardWriter: { prompt in
        copiedPrompt = prompt
      }
    )

    await viewModel.load()
    viewModel.copyStarterPrompt()

    #expect(copiedPrompt?.contains("I use an app called Drift") == true)
    #expect(viewModel.connectionState == .notConnected)
    #expect(await service.saveCallCount == 0)
  }

  private func makeViewModel(
    chatGPTConnectionService: any ChatGPTConnectionService & Sendable =
      LocalChatGPTConnectionService(),
    pasteboardWriter: @escaping @MainActor (String) -> Void = { _ in }
  ) -> ChatGPTConnectionViewModel {
    let space = DriftSpace(
      id: fixtureUUID("C4000000-0000-0000-0000-000000000001"),
      name: "Goals",
      description: "Goals and next steps.",
      icon: "target"
    )
    let entry = JournalEntry(
      id: fixtureUUID("C4000000-0000-0000-0000-000000000002"),
      createdAt: Date(timeIntervalSince1970: 1_779_000_000),
      transcript: "A selected goal.",
      driftType: .goal,
      spaceIds: [space.id]
    )
    let contextPack = ContextPack(
      id: fixtureUUID("C4000000-0000-0000-0000-000000000003"),
      name: "Goals Context",
      description: "Selected goals.",
      driftIds: [entry.id],
      spaceIds: [space.id]
    )

    return ChatGPTConnectionViewModel(
      userIdentityService: PreviewUserIdentityService(),
      chatGPTConnectionService: chatGPTConnectionService,
      spaceRepository: LocalSpaceRepository(spaces: [space]),
      contextPackService: LocalContextPackService(contextPacks: [contextPack]),
      driftRepository: JournalBackedDriftRepository(
        journalRepository: PreviewJournalRepository(entries: [entry])
      ),
      pasteboardWriter: pasteboardWriter
    )
  }
}

private actor TrackingChatGPTConnectionService: ChatGPTConnectionService {
  private(set) var saveCallCount = 0

  func loadSettings() async throws -> ChatGPTConnectionSettings {
    .default
  }

  func saveSettings(_ settings: ChatGPTConnectionSettings) async throws {
    saveCallCount += 1
  }

  func connectedAccountState() async -> ConnectedAccountState {
    .notConnected
  }

  func pendingUpdates() async throws -> [PendingChatGPTUpdate] {
    []
  }
}
