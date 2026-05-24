//
//  ChatGPTConnectionServiceTests.swift
//  DriftTests
//
//  Created by Lucas Stuart West Rogers on 24/05/2026.
//

import Foundation
import Testing

@testable import Drift

struct ChatGPTConnectionServiceTests {
  @Test
  func defaultConnectionStateIsNotConnected() async throws {
    let service = makeService()

    let state = await service.connectedAccountState()
    let settings = try await service.loadSettings()

    #expect(state == .notConnected)
    #expect(settings == .default)
    #expect(settings.selectedSpaceIds.isEmpty)
    #expect(settings.selectedContextPackIds.isEmpty)
  }

  @Test
  func selectedSpacesPersistLocally() async throws {
    let service = makeService()
    let spaceID = fixtureUUID("C2000000-0000-0000-0000-000000000001")
    var settings = ChatGPTConnectionSettings.default
    settings.selectedSpaceIds = [spaceID]

    try await service.saveSettings(settings)
    let loadedSettings = try await service.loadSettings()

    #expect(loadedSettings.selectedSpaceIds == [spaceID])
  }

  @Test
  func selectedContextPacksPersistLocally() async throws {
    let service = makeService()
    let contextPackID = fixtureUUID("C2000000-0000-0000-0000-000000000002")
    var settings = ChatGPTConnectionSettings.default
    settings.selectedContextPackIds = [contextPackID]

    try await service.saveSettings(settings)
    let loadedSettings = try await service.loadSettings()

    #expect(loadedSettings.selectedContextPackIds == [contextPackID])
  }

  @Test
  func futureConnectionSettingsPersistLocally() async throws {
    let service = makeService()
    var settings = ChatGPTConnectionSettings.default
    settings.allowChatGPTSpaceSuggestions = false
    settings.requireReviewBeforeSaving = true
    settings.allowChatGPTDriftProposals = true
    settings.allowChatGPTDriftUpdates = false

    try await service.saveSettings(settings)
    let loadedSettings = try await service.loadSettings()

    #expect(loadedSettings.allowChatGPTSpaceSuggestions == false)
    #expect(loadedSettings.requireReviewBeforeSaving)
    #expect(loadedSettings.allowChatGPTDriftProposals)
    #expect(loadedSettings.allowChatGPTDriftUpdates == false)
  }

  private func makeService() -> LocalChatGPTConnectionService {
    let suiteName = "DriftTests.ChatGPTConnection.\(UUID().uuidString)"
    let userDefaults = UserDefaults(suiteName: suiteName) ?? .standard
    userDefaults.removePersistentDomain(forName: suiteName)
    return LocalChatGPTConnectionService(userDefaults: userDefaults)
  }
}
