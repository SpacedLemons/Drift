//
//  ChatGPTConnectionService.swift
//  Drift
//
//  Created by Lucas Stuart West Rogers on 24/05/2026.
//

import Foundation
import Mockable

@Mockable
protocol ChatGPTConnectionService {
  func loadSettings() async throws -> ChatGPTConnectionSettings
  func saveSettings(_ settings: ChatGPTConnectionSettings) async throws
  func connectedAccountState() async -> ConnectedAccountState
  func pendingUpdates() async throws -> [PendingChatGPTUpdate]
}

enum ChatGPTConnectionServiceError: LocalizedError, Equatable {
  case loadFailed
  case saveFailed

  var errorDescription: String? {
    switch self {
    case .loadFailed:
      "We could not load ChatGPT connection settings."
    case .saveFailed:
      "We could not save ChatGPT connection settings."
    }
  }
}

actor LocalChatGPTConnectionService: ChatGPTConnectionService {
  private let userDefaults: UserDefaults
  private let settingsKey: String

  init(
    userDefaults: UserDefaults = .standard,
    settingsKey: String = "drift.chatgpt.connection.settings"
  ) {
    self.userDefaults = userDefaults
    self.settingsKey = settingsKey
  }

  func loadSettings() async throws -> ChatGPTConnectionSettings {
    guard let data = userDefaults.data(forKey: settingsKey) else {
      return .default
    }

    do {
      return try JSONDecoder().decode(ChatGPTConnectionSettings.self, from: data)
    } catch {
      throw ChatGPTConnectionServiceError.loadFailed
    }
  }

  func saveSettings(_ settings: ChatGPTConnectionSettings) async throws {
    do {
      let data = try JSONEncoder().encode(settings)
      userDefaults.set(data, forKey: settingsKey)
    } catch {
      throw ChatGPTConnectionServiceError.saveFailed
    }
  }

  func connectedAccountState() async -> ConnectedAccountState {
    .notConnected
  }

  func pendingUpdates() async throws -> [PendingChatGPTUpdate] {
    []
  }
}
