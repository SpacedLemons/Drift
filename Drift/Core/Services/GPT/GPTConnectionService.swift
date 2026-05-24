//
//  GPTConnectionService.swift
//  Drift
//
//  Created by Lucas Stuart West Rogers on 24/05/2026.
//

import Foundation
import Mockable

@Mockable
protocol GPTConnectionService {
  func loadConnection() async throws -> GPTConnectionSnapshot
  func connect(method: GPTConnectionMethod) async throws -> GPTConnectionSnapshot
  func disconnect() async throws -> GPTConnectionSnapshot
  func saveSettings(_ settings: GPTConnectionSettings) async throws -> GPTConnectionSnapshot
  func fetchActivity() async throws -> [GPTActivityItem]
  func appendActivity(_ activityItem: GPTActivityItem) async throws
}

enum GPTConnectionServiceError: LocalizedError, Equatable {
  case loadFailed
  case saveFailed

  var errorDescription: String? {
    switch self {
    case .loadFailed: "We could not load the GPT connection."
    case .saveFailed: "We could not save the GPT connection."
    }
  }
}

actor LocalGPTConnectionService: GPTConnectionService {
  private let userDefaults: UserDefaults
  private let connectionKey: String
  private let activityKey: String
  private let now: @Sendable () -> Date

  init(
    userDefaults: UserDefaults = .standard,
    connectionKey: String = "drift.gpt.connection.snapshot",
    activityKey: String = "drift.gpt.activity",
    now: @escaping @Sendable () -> Date = Date.init
  ) {
    self.userDefaults = userDefaults
    self.connectionKey = connectionKey
    self.activityKey = activityKey
    self.now = now
  }

  func loadConnection() async throws -> GPTConnectionSnapshot {
    guard let data = userDefaults.data(forKey: connectionKey) else {
      return .default
    }

    do {
      return try JSONDecoder().decode(GPTConnectionSnapshot.self, from: data)
    } catch {
      throw GPTConnectionServiceError.loadFailed
    }
  }

  func connect(method: GPTConnectionMethod) async throws -> GPTConnectionSnapshot {
    var snapshot = try await loadConnection()
    snapshot.state = .connected
    snapshot.connectedAt = now()
    snapshot.method = method
    try save(snapshot)

    let existingActivity = try await fetchActivity()
    if existingActivity.isEmpty {
      try await seedConnectedActivity()
    }

    return snapshot
  }

  func disconnect() async throws -> GPTConnectionSnapshot {
    var snapshot = try await loadConnection()
    snapshot.state = .notConnected
    snapshot.connectedAt = nil
    snapshot.method = nil
    try save(snapshot)
    return snapshot
  }

  func saveSettings(_ settings: GPTConnectionSettings) async throws -> GPTConnectionSnapshot {
    var snapshot = try await loadConnection()
    snapshot.settings = settings
    try save(snapshot)
    return snapshot
  }

  func fetchActivity() async throws -> [GPTActivityItem] {
    guard let data = userDefaults.data(forKey: activityKey) else {
      return []
    }

    do {
      return try JSONDecoder().decode([GPTActivityItem].self, from: data)
        .sorted { $0.createdAt > $1.createdAt }
    } catch {
      throw GPTConnectionServiceError.loadFailed
    }
  }

  func appendActivity(_ activityItem: GPTActivityItem) async throws {
    var activityItems = try await fetchActivity()
    activityItems.removeAll { $0.id == activityItem.id }
    activityItems.append(activityItem)

    do {
      let data = try JSONEncoder().encode(activityItems.sorted { $0.createdAt > $1.createdAt })
      userDefaults.set(data, forKey: activityKey)
    } catch {
      throw GPTConnectionServiceError.saveFailed
    }
  }

  private func save(_ snapshot: GPTConnectionSnapshot) throws {
    do {
      let data = try JSONEncoder().encode(snapshot)
      userDefaults.set(data, forKey: connectionKey)
    } catch {
      throw GPTConnectionServiceError.saveFailed
    }
  }

  private func seedConnectedActivity() async throws {
    let createdAt = now()
    try await appendActivity(
      GPTActivityItem(
        createdAt: createdAt,
        kind: .createdDrift,
        title: "Product idea",
        subtitle: "Created Drift"
      )
    )
    try await appendActivity(
      GPTActivityItem(
        createdAt: createdAt.addingTimeInterval(-180),
        kind: .updatedDrift,
        title: "OpenAI Career",
        subtitle: "Updated Drift"
      )
    )
    try await appendActivity(
      GPTActivityItem(
        createdAt: createdAt.addingTimeInterval(-360),
        kind: .suggestedSpace,
        title: "Drift App",
        subtitle: "Suggested Space"
      )
    )
  }
}
