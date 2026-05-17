//
//  DebugSubscriptionService.swift
//  Drift
//
//  Created by Lucas Stuart West Rogers on 16/05/2026.
//

#if DEBUG
  import Foundation

  enum DebugEntitlementMode: String, CaseIterable, Identifiable, Codable, Sendable {
    case realStoreKit
    case forceFree
    case forcePlus

    var id: String { rawValue }

    var displayName: String {
      switch self {
      case .realStoreKit: "Real StoreKit"
      case .forceFree: "Force Free"
      case .forcePlus: "Force Plus"
      }
    }
  }

  struct DebugEntitlementOverrideSettings: Hashable, Codable, Sendable {
    var mode: DebugEntitlementMode
    var simulateFreeEntryLimitReached: Bool
    var simulatePlusEntryLimitReached: Bool

    static let `default` = DebugEntitlementOverrideSettings(
      mode: .realStoreKit,
      simulateFreeEntryLimitReached: false,
      simulatePlusEntryLimitReached: false
    )
  }

  actor DebugEntitlementOverrideStore {
    private let userDefaults: UserDefaults
    private let modeKey: String
    private let freeLimitKey: String
    private let plusLimitKey: String

    init(
      userDefaults: UserDefaults = .standard,
      keyPrefix: String = "drift.debug.entitlement"
    ) {
      self.userDefaults = userDefaults
      modeKey = "\(keyPrefix).mode"
      freeLimitKey = "\(keyPrefix).simulateFreeLimit"
      plusLimitKey = "\(keyPrefix).simulatePlusLimit"
    }

    func loadSettings() -> DebugEntitlementOverrideSettings {
      let modeRawValue = userDefaults.string(forKey: modeKey)
      let mode = modeRawValue.flatMap(DebugEntitlementMode.init(rawValue:)) ?? .realStoreKit

      return DebugEntitlementOverrideSettings(
        mode: mode,
        simulateFreeEntryLimitReached: userDefaults.bool(forKey: freeLimitKey),
        simulatePlusEntryLimitReached: userDefaults.bool(forKey: plusLimitKey)
      )
    }

    func saveMode(_ mode: DebugEntitlementMode) {
      userDefaults.set(mode.rawValue, forKey: modeKey)
    }

    func saveSimulateFreeEntryLimitReached(_ isEnabled: Bool) {
      userDefaults.set(isEnabled, forKey: freeLimitKey)
    }

    func saveSimulatePlusEntryLimitReached(_ isEnabled: Bool) {
      userDefaults.set(isEnabled, forKey: plusLimitKey)
    }
  }

  actor DebugSubscriptionService: SubscriptionService {
    private let baseService: any SubscriptionService & Sendable
    private let overrideStore: DebugEntitlementOverrideStore

    init(
      baseService: any SubscriptionService & Sendable,
      overrideStore: DebugEntitlementOverrideStore
    ) {
      self.baseService = baseService
      self.overrideStore = overrideStore
    }

    func loadProducts() async throws -> [SubscriptionProduct] {
      try await baseService.loadProducts()
    }

    func purchase(product: SubscriptionProduct) async throws -> SubscriptionPurchaseResult {
      try await baseService.purchase(product: product)
    }

    func restorePurchases() async throws -> SubscriptionRestoreResult {
      try await baseService.restorePurchases()
    }

    func currentEntitlement() async throws -> SubscriptionEntitlement {
      switch await overrideStore.loadSettings().mode {
      case .realStoreKit:
        return try await baseService.currentEntitlement()
      case .forceFree:
        return .free
      case .forcePlus:
        return .plus()
      }
    }

    func refreshEntitlement() async throws -> SubscriptionEntitlement {
      try await currentEntitlement()
    }

    func currentState() async throws -> SubscriptionState {
      let settings = await overrideStore.loadSettings()

      switch settings.mode {
      case .realStoreKit:
        return try await baseService.currentState()
      case .forceFree:
        return SubscriptionState(
          entitlement: .free,
          status: .free,
          activeProductID: nil,
          expirationDate: nil,
          updatedAt: Date()
        )
      case .forcePlus:
        return SubscriptionState(
          entitlement: .plus(),
          status: .active,
          activeProductID: "debug.force.plus",
          expirationDate: nil,
          updatedAt: Date()
        )
      }
    }

    func isFeatureUnlocked(_ feature: PremiumFeature) async throws -> Bool {
      try await currentEntitlement().isFeatureUnlocked(feature)
    }
  }
#endif
