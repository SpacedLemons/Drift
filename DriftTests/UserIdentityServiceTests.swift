//
//  UserIdentityServiceTests.swift
//  DriftTests
//
//  Created by Lucas Stuart West Rogers on 24/05/2026.
//

import Foundation
import Testing

@testable import Drift

struct UserIdentityServiceTests {
  @Test
  func anonymousIdentityIsGeneratedIfMissing() throws {
    let store = InMemoryKeychainStore()
    let expectedID = fixtureUUID("C1000000-0000-0000-0000-000000000001")
    let createdAt = Date(timeIntervalSince1970: 1_779_000_000)
    let service = KeychainUserIdentityService(
      keychainStore: store,
      serviceName: "identity.generated",
      uuidProvider: { expectedID },
      now: { createdAt }
    )

    let identity = try service.currentIdentity()

    #expect(identity.id == expectedID)
    #expect(identity.createdAt == createdAt)
  }

  @Test
  func anonymousIdentityIsReusedAfterCreation() throws {
    let store = InMemoryKeychainStore()
    let firstID = fixtureUUID("C1000000-0000-0000-0000-000000000002")
    let secondID = fixtureUUID("C1000000-0000-0000-0000-000000000003")
    var generatedIDs = [firstID, secondID]
    let service = KeychainUserIdentityService(
      keychainStore: store,
      serviceName: "identity.reused",
      uuidProvider: { generatedIDs.removeFirst() },
      now: { Date(timeIntervalSince1970: 1_779_000_000) }
    )

    let firstIdentity = try service.currentIdentity()
    let secondIdentity = try service.currentIdentity()

    #expect(firstIdentity == secondIdentity)
    #expect(secondIdentity.id == firstID)
    #expect(generatedIDs == [secondID])
  }

  @Test
  func resetIdentityForDebugOnlyRemovesStoredIdentity() throws {
    let store = InMemoryKeychainStore()
    let firstID = fixtureUUID("C1000000-0000-0000-0000-000000000004")
    let secondID = fixtureUUID("C1000000-0000-0000-0000-000000000005")
    var generatedIDs = [firstID, secondID]
    let service = KeychainUserIdentityService(
      keychainStore: store,
      serviceName: "identity.reset",
      uuidProvider: { generatedIDs.removeFirst() },
      now: { Date(timeIntervalSince1970: 1_779_000_000) }
    )

    let firstIdentity = try service.currentIdentity()
    try service.resetIdentityForDebugOnly()
    let resetIdentity = try service.currentIdentity()

    #expect(firstIdentity.id == firstID)
    #expect(resetIdentity.id == secondID)
  }
}

private final class InMemoryKeychainStore: KeychainStoring, @unchecked Sendable {
  private let lock = NSLock()
  private var storage: [String: Data] = [:]

  func data(forService service: String, account: String) throws -> Data? {
    lock.lock()
    defer { lock.unlock() }
    return storage[key(service: service, account: account)]
  }

  func setData(_ data: Data, forService service: String, account: String) throws {
    lock.lock()
    defer { lock.unlock() }
    storage[key(service: service, account: account)] = data
  }

  func deleteData(forService service: String, account: String) throws {
    lock.lock()
    defer { lock.unlock() }
    storage.removeValue(forKey: key(service: service, account: account))
  }

  private func key(service: String, account: String) -> String {
    "\(service).\(account)"
  }
}
