//
//  GPTConnectionServiceTests.swift
//  DriftTests
//
//  Created by Lucas Stuart West Rogers on 24/05/2026.
//

import Foundation
import Testing

@testable import Drift

struct GPTConnectionServiceTests {
  @Test
  func defaultGPTConnectionStateIsNotConnected() async throws {
    let service = makeConnectionService()

    let snapshot = try await service.loadConnection()

    #expect(snapshot.state == .notConnected)
    #expect(snapshot.settings.requireReviewBeforeSaving)
    #expect(!snapshot.settings.autoDriftConversations)
  }

  @Test
  func connectingInMockModeChangesStateToConnected() async throws {
    let service = makeConnectionService()

    let snapshot = try await service.connect(method: .passkey)

    #expect(snapshot.state == .connected)
    #expect(snapshot.method == .passkey)
    #expect(snapshot.connectedAt != nil)
  }

  @Test
  func disconnectingReturnsToNotConnected() async throws {
    let service = makeConnectionService()
    _ = try await service.connect(method: .apple)

    let snapshot = try await service.disconnect()

    #expect(snapshot.state == .notConnected)
    #expect(snapshot.method == nil)
    #expect(snapshot.connectedAt == nil)
  }

  private func makeConnectionService() -> LocalGPTConnectionService {
    let suiteName = "DriftTests.GPTConnection.\(UUID().uuidString)"
    let userDefaults = UserDefaults(suiteName: suiteName) ?? .standard
    userDefaults.removePersistentDomain(forName: suiteName)
    return LocalGPTConnectionService(userDefaults: userDefaults)
  }
}
