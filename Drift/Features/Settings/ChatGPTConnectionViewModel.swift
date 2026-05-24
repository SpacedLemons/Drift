//
//  ChatGPTConnectionViewModel.swift
//  Drift
//
//  Created by Lucas Stuart West Rogers on 24/05/2026.
//

import Foundation
import Observation
import UIKit

@MainActor
@Observable
final class ChatGPTConnectionViewModel {
  @ObservationIgnored
  private let userIdentityService: any UserIdentityService & Sendable
  @ObservationIgnored
  private let chatGPTConnectionService: any ChatGPTConnectionService & Sendable
  @ObservationIgnored
  private let spaceRepository: any SpaceRepository & Sendable
  @ObservationIgnored
  private let contextPackService: any ContextPackService & Sendable
  @ObservationIgnored
  private let driftRepository: any DriftRepository & Sendable
  @ObservationIgnored
  private let promptBuilder: ChatGPTStarterPromptBuilder
  @ObservationIgnored
  private let pasteboardWriter: @MainActor (String) -> Void

  private(set) var identityStatus: LocalIdentityStatus = .unknown
  private(set) var connectionState: ConnectedAccountState = .notConnected
  private(set) var settings: ChatGPTConnectionSettings = .default
  private(set) var spaces: [DriftSpace] = []
  private(set) var contextPacks: [ContextPack] = []
  private(set) var pendingUpdates: [PendingChatGPTUpdate] = []
  private(set) var isLoading = false
  private(set) var errorMessage: String?
  private(set) var statusMessage: String?
  var shareItem: ChatGPTPromptShareItem?

  @ObservationIgnored
  private var drifts: [DriftItem] = []

  init(
    userIdentityService: any UserIdentityService & Sendable,
    chatGPTConnectionService: any ChatGPTConnectionService & Sendable,
    spaceRepository: any SpaceRepository & Sendable,
    contextPackService: any ContextPackService & Sendable,
    driftRepository: any DriftRepository & Sendable,
    promptBuilder: ChatGPTStarterPromptBuilder = ChatGPTStarterPromptBuilder(),
    pasteboardWriter: @escaping @MainActor (String) -> Void = { prompt in
      UIPasteboard.general.string = prompt
    }
  ) {
    self.userIdentityService = userIdentityService
    self.chatGPTConnectionService = chatGPTConnectionService
    self.spaceRepository = spaceRepository
    self.contextPackService = contextPackService
    self.driftRepository = driftRepository
    self.promptBuilder = promptBuilder
    self.pasteboardWriter = pasteboardWriter
  }

  var isLocalUseAllowed: Bool {
    true
  }

  var localIdentitySummary: String {
    switch identityStatus {
    case .unknown:
      "Checking local identity"
    case .ready(let createdAt):
      "Ready since \(Self.identityDateFormatter.string(from: createdAt))"
    case .unavailable:
      "Unavailable"
    }
  }

  var selectedSpaces: [DriftSpace] {
    spaces
      .filter { settings.selectedSpaceIds.contains($0.id) }
      .sorted { $0.name < $1.name }
  }

  var selectedContextPacks: [ContextPack] {
    contextPacks
      .filter { settings.selectedContextPackIds.contains($0.id) }
      .sorted { $0.name < $1.name }
  }

  var starterPromptPreview: String {
    promptBuilder.buildPrompt(
      selectedSpaces: selectedSpaces,
      selectedContextPacks: selectedContextPacks,
      settings: settings
    )
  }

  func load() async {
    guard !isLoading else { return }

    isLoading = true
    errorMessage = nil
    statusMessage = nil
    loadIdentity()

    do {
      async let loadedSettings = chatGPTConnectionService.loadSettings()
      async let loadedConnectionState = chatGPTConnectionService.connectedAccountState()
      async let loadedSpaces = spaceRepository.fetchSpaces()
      async let loadedContextPacks = contextPackService.fetchContextPacks()
      async let loadedDrifts = driftRepository.fetchDrifts()
      async let loadedPendingUpdates = chatGPTConnectionService.pendingUpdates()

      settings = try await loadedSettings
      connectionState = await loadedConnectionState
      spaces = try await loadedSpaces
      contextPacks = try await loadedContextPacks
      drifts = try await loadedDrifts
      pendingUpdates = try await loadedPendingUpdates
    } catch {
      errorMessage = "We could not load ChatGPT connection settings."
    }

    isLoading = false
  }

  func setAllowSpaceSuggestions(_ isEnabled: Bool) async {
    settings.allowChatGPTSpaceSuggestions = isEnabled
    await persistSettings()
  }

  func setRequireReviewBeforeSaving(_ isEnabled: Bool) async {
    settings.requireReviewBeforeSaving = isEnabled
    await persistSettings()
  }

  func setAllowDriftProposals(_ isEnabled: Bool) async {
    settings.allowChatGPTDriftProposals = isEnabled
    await persistSettings()
  }

  func setAllowDriftUpdates(_ isEnabled: Bool) async {
    settings.allowChatGPTDriftUpdates = isEnabled
    await persistSettings()
  }

  func toggleSpaceSelection(_ space: DriftSpace) async {
    if settings.selectedSpaceIds.contains(space.id) {
      settings.selectedSpaceIds.remove(space.id)
    } else {
      settings.selectedSpaceIds.insert(space.id)
    }

    await persistSettings()
  }

  func toggleContextPackSelection(_ contextPack: ContextPack) async {
    if settings.selectedContextPackIds.contains(contextPack.id) {
      settings.selectedContextPackIds.remove(contextPack.id)
    } else {
      settings.selectedContextPackIds.insert(contextPack.id)
    }

    await persistSettings()
  }

  func driftCount(for space: DriftSpace) -> Int {
    drifts.filter { $0.spaces.contains(space.id) }.count
  }

  func copyStarterPrompt() {
    pasteboardWriter(starterPromptPreview)
    statusMessage = "Starter prompt copied. Nothing was shared automatically."
    errorMessage = nil
  }

  func prepareStarterPromptForSharing() {
    shareItem = ChatGPTPromptShareItem(prompt: starterPromptPreview)
    statusMessage = "Starter prompt prepared. You choose where to share it."
    errorMessage = nil
  }

  private func loadIdentity() {
    do {
      let identity = try userIdentityService.currentIdentity()
      identityStatus = .ready(createdAt: identity.createdAt)
    } catch {
      identityStatus = .unavailable
    }
  }

  private func persistSettings() async {
    do {
      try await chatGPTConnectionService.saveSettings(settings)
      statusMessage = "Connection preferences saved locally."
      errorMessage = nil
    } catch {
      statusMessage = nil
      errorMessage = "We could not save ChatGPT connection settings."
    }
  }

  private static let identityDateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .short
    return formatter
  }()
}

struct ChatGPTPromptShareItem: Identifiable, Equatable {
  let id = UUID()
  let prompt: String
}
