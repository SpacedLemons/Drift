//
//  UserIdentityService.swift
//  Drift
//
//  Created by Lucas Stuart West Rogers on 24/05/2026.
//

import Foundation
import Mockable
import Security

@Mockable
protocol UserIdentityService {
  func currentIdentity() throws -> AnonymousDriftIdentity
  func resetIdentityForDebugOnly() throws
}

enum UserIdentityServiceError: LocalizedError, Equatable {
  case encodeFailed
  case decodeFailed
  case keychainReadFailed(status: OSStatus)
  case keychainWriteFailed(status: OSStatus)
  case keychainDeleteFailed(status: OSStatus)

  var errorDescription: String? {
    switch self {
    case .encodeFailed:
      "We could not prepare the local Drift identity."
    case .decodeFailed:
      "We could not read the local Drift identity."
    case .keychainReadFailed:
      "We could not read the local Drift identity from Keychain."
    case .keychainWriteFailed:
      "We could not save the local Drift identity in Keychain."
    case .keychainDeleteFailed:
      "We could not reset the local Drift identity."
    }
  }
}

protocol KeychainStoring: Sendable {
  func data(forService service: String, account: String) throws -> Data?
  func setData(_ data: Data, forService service: String, account: String) throws
  func deleteData(forService service: String, account: String) throws
}

struct SystemKeychainStore: KeychainStoring {
  func data(forService service: String, account: String) throws -> Data? {
    var query = baseQuery(service: service, account: account)
    query[kSecReturnData as String] = true
    query[kSecMatchLimit as String] = kSecMatchLimitOne

    var item: CFTypeRef?
    let status = SecItemCopyMatching(query as CFDictionary, &item)

    if status == errSecItemNotFound {
      return nil
    }

    guard status == errSecSuccess else {
      throw UserIdentityServiceError.keychainReadFailed(status: status)
    }

    return item as? Data
  }

  func setData(_ data: Data, forService service: String, account: String) throws {
    let query = baseQuery(service: service, account: account)
    let updateAttributes = [kSecValueData as String: data]
    let updateStatus = SecItemUpdate(query as CFDictionary, updateAttributes as CFDictionary)

    if updateStatus == errSecSuccess {
      return
    }

    guard updateStatus == errSecItemNotFound else {
      throw UserIdentityServiceError.keychainWriteFailed(status: updateStatus)
    }

    var attributes = query
    attributes[kSecValueData as String] = data
    attributes[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly

    let addStatus = SecItemAdd(attributes as CFDictionary, nil)
    guard addStatus == errSecSuccess else {
      throw UserIdentityServiceError.keychainWriteFailed(status: addStatus)
    }
  }

  func deleteData(forService service: String, account: String) throws {
    let status = SecItemDelete(baseQuery(service: service, account: account) as CFDictionary)
    guard status == errSecSuccess || status == errSecItemNotFound else {
      throw UserIdentityServiceError.keychainDeleteFailed(status: status)
    }
  }

  private func baseQuery(service: String, account: String) -> [String: Any] {
    [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: service,
      kSecAttrAccount as String: account,
    ]
  }
}

final class KeychainUserIdentityService: UserIdentityService, @unchecked Sendable {
  private let keychainStore: any KeychainStoring
  private let serviceName: String
  private let accountName: String
  private let uuidProvider: @Sendable () -> UUID
  private let now: @Sendable () -> Date
  private let lock = NSLock()

  init(
    keychainStore: any KeychainStoring = SystemKeychainStore(),
    serviceName: String = "LWR.Drift.anonymousIdentity",
    accountName: String = "local-install",
    uuidProvider: @escaping @Sendable () -> UUID = UUID.init,
    now: @escaping @Sendable () -> Date = Date.init
  ) {
    self.keychainStore = keychainStore
    self.serviceName = serviceName
    self.accountName = accountName
    self.uuidProvider = uuidProvider
    self.now = now
  }

  func currentIdentity() throws -> AnonymousDriftIdentity {
    try lock.withLock {
      if let existingIdentity = try readIdentity() {
        return existingIdentity
      }

      // The anonymous Drift ID identifies this local install.
      // It is not authentication for remote services.
      // Future connected features must use passkeys/OAuth or another secure auth flow.
      let identity = AnonymousDriftIdentity(id: uuidProvider(), createdAt: now())
      try store(identity)
      return identity
    }
  }

  func resetIdentityForDebugOnly() throws {
    try lock.withLock {
      try keychainStore.deleteData(forService: serviceName, account: accountName)
    }
  }

  private func readIdentity() throws -> AnonymousDriftIdentity? {
    guard let data = try keychainStore.data(forService: serviceName, account: accountName) else {
      return nil
    }

    do {
      return try JSONDecoder().decode(AnonymousDriftIdentity.self, from: data)
    } catch {
      throw UserIdentityServiceError.decodeFailed
    }
  }

  private func store(_ identity: AnonymousDriftIdentity) throws {
    do {
      let data = try JSONEncoder().encode(identity)
      try keychainStore.setData(data, forService: serviceName, account: accountName)
    } catch let error as UserIdentityServiceError {
      throw error
    } catch {
      throw UserIdentityServiceError.encodeFailed
    }
  }
}

final class PreviewUserIdentityService: UserIdentityService, @unchecked Sendable {
  private let lock = NSLock()
  private var identity: AnonymousDriftIdentity

  init(
    identity: AnonymousDriftIdentity = AnonymousDriftIdentity(
      id: UUID(uuidString: "C0000000-0000-0000-0000-000000000001") ?? UUID(),
      createdAt: PreviewData.baseDate
    )
  ) {
    self.identity = identity
  }

  func currentIdentity() throws -> AnonymousDriftIdentity {
    lock.withLock { identity }
  }

  func resetIdentityForDebugOnly() throws {
    lock.withLock {
      identity = AnonymousDriftIdentity(id: UUID(), createdAt: Date())
    }
  }
}
