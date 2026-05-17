//
//  StoreKitSubscriptionService.swift
//  Drift
//
//  Created by Lucas Stuart West Rogers on 16/05/2026.
//

import Foundation
import StoreKit

actor StoreKitSubscriptionService: SubscriptionService {
  private let productIDs: [String]
  private let shouldObserveTransactions: Bool
  private var productsByID: [String: Product] = [:]
  private var cachedState: SubscriptionState = .free
  private var updatesTask: Task<Void, Never>?

  init(
    productIDs: [String] = SubscriptionProduct.defaultProductIDs,
    observeTransactions: Bool = true
  ) {
    self.productIDs = productIDs
    shouldObserveTransactions = observeTransactions
  }

  deinit {
    updatesTask?.cancel()
  }

  func loadProducts() async throws -> [SubscriptionProduct] {
    startObservingTransactionUpdatesIfNeeded()

    do {
      let products = try await Product.products(for: productIDs)
      guard !products.isEmpty else {
        throw SubscriptionServiceError.productsUnavailable
      }

      productsByID = Dictionary(uniqueKeysWithValues: products.map { ($0.id, $0) })
      return
        products
        .sorted { firstProduct, secondProduct in
          let firstIndex = productIDs.firstIndex(of: firstProduct.id) ?? Int.max
          let secondIndex = productIDs.firstIndex(of: secondProduct.id) ?? Int.max
          return firstIndex < secondIndex
        }
        .map(subscriptionProduct)
    } catch let error as SubscriptionServiceError {
      throw error
    } catch {
      throw SubscriptionServiceError.productsUnavailable
    }
  }

  func purchase(product: SubscriptionProduct) async throws -> SubscriptionPurchaseResult {
    startObservingTransactionUpdatesIfNeeded()

    do {
      let storeProduct = try await storeKitProduct(for: product.productID)
      let result = try await storeProduct.purchase()

      switch result {
      case .success(let verificationResult):
        let transaction = try Self.verified(verificationResult)
        await transaction.finish()
        return .completed(try await refreshEntitlement())
      case .userCancelled:
        throw SubscriptionServiceError.purchaseCancelled
      case .pending:
        cachedState = SubscriptionState(
          entitlement: cachedState.entitlement,
          status: .pending,
          activeProductID: cachedState.activeProductID,
          expirationDate: cachedState.expirationDate,
          updatedAt: Date()
        )
        return .pending
      @unknown default:
        throw SubscriptionServiceError.purchaseFailed
      }
    } catch let error as SubscriptionServiceError {
      throw error
    } catch {
      throw SubscriptionServiceError.purchaseFailed
    }
  }

  func restorePurchases() async throws -> SubscriptionRestoreResult {
    startObservingTransactionUpdatesIfNeeded()

    do {
      try await AppStore.sync()
      let entitlement = try await refreshEntitlement()
      return SubscriptionRestoreResult(
        entitlement: entitlement,
        restoredActiveSubscription: entitlement.isPremium
      )
    } catch let error as SubscriptionServiceError {
      throw error
    } catch {
      throw SubscriptionServiceError.restoreFailed
    }
  }

  func currentEntitlement() async throws -> SubscriptionEntitlement {
    startObservingTransactionUpdatesIfNeeded()

      return try await refreshEntitlement()
  }

  func refreshEntitlement() async throws -> SubscriptionEntitlement {
    startObservingTransactionUpdatesIfNeeded()

      return try await refreshState().entitlement
  }

  func currentState() async throws -> SubscriptionState {
    startObservingTransactionUpdatesIfNeeded()

      return try await refreshState()
  }

  func isFeatureUnlocked(_ feature: PremiumFeature) async throws -> Bool {
    startObservingTransactionUpdatesIfNeeded()

      return try await currentEntitlement().isFeatureUnlocked(feature)
  }

  private func startObservingTransactionUpdatesIfNeeded() {
    guard shouldObserveTransactions, updatesTask == nil else { return }

    updatesTask = Task { [weak self] in
      await self?.observeTransactionUpdates()
    }
  }

  private func storeKitProduct(for productID: String) async throws -> Product {
    if let product = productsByID[productID] {
      return product
    }

    let products = try await Product.products(for: [productID])
    guard let product = products.first else {
      throw SubscriptionServiceError.productUnavailable
    }

    productsByID[productID] = product
    return product
  }

  private func refreshState() async throws -> SubscriptionState {
    do {
      if let activeTransaction = try await activePlusTransaction() {
        let entitlement = SubscriptionEntitlement.plus(
          activeProductID: activeTransaction.productID,
          expirationDate: activeTransaction.expirationDate
        )
        cachedState = SubscriptionState(
          entitlement: entitlement,
          status: .active,
          activeProductID: activeTransaction.productID,
          expirationDate: activeTransaction.expirationDate,
          updatedAt: Date()
        )
        return cachedState
      }

      cachedState = try await inactiveStateFromTransactionHistory()
      return cachedState
    } catch let error as SubscriptionServiceError {
      throw error
    } catch {
      throw SubscriptionServiceError.entitlementRefreshFailed
    }
  }

  private func activePlusTransaction() async throws -> Transaction? {
    var latestTransaction: Transaction?

    for await result in Transaction.currentEntitlements {
      let transaction = try Self.verified(result)
      guard isRelevantPlusTransaction(transaction) else { continue }
      guard isActive(transaction) else { continue }

      let latestPurchaseDate = latestTransaction?.purchaseDate ?? .distantPast
      if transaction.purchaseDate > latestPurchaseDate {
        latestTransaction = transaction
      }
    }

    return latestTransaction
  }

  private func inactiveStateFromTransactionHistory() async throws -> SubscriptionState {
    var latestTransaction: Transaction?

    for await result in Transaction.all {
      let transaction = try Self.verified(result)
      guard isRelevantPlusTransaction(transaction) else { continue }

      let latestPurchaseDate = latestTransaction?.purchaseDate ?? .distantPast
      if transaction.purchaseDate > latestPurchaseDate {
        latestTransaction = transaction
      }
    }

    guard let latestTransaction else {
      return SubscriptionState(
        entitlement: .free,
        status: .free,
        activeProductID: nil,
        expirationDate: nil,
        updatedAt: Date()
      )
    }

    let status: SubscriptionStatus
    if latestTransaction.revocationDate != nil {
      status = .revoked
    } else if let expirationDate = latestTransaction.expirationDate, expirationDate <= Date() {
      status = .expired
    } else {
      status = .free
    }

    return SubscriptionState(
      entitlement: .free,
      status: status,
      activeProductID: latestTransaction.productID,
      expirationDate: latestTransaction.expirationDate,
      updatedAt: Date()
    )
  }

  private func observeTransactionUpdates() async {
    for await result in Transaction.updates {
      do {
        let transaction = try Self.verified(result)
        await transaction.finish()
        _ = try await refreshEntitlement()
      } catch {
        continue
      }
    }
  }

  private func subscriptionProduct(from product: Product) -> SubscriptionProduct {
    let plan = SubscriptionProduct.Plan.allCases.first { $0.productID == product.id } ?? .monthly
    return SubscriptionProduct(
      productID: product.id,
      plan: plan,
      displayName: product.displayName.isEmpty ? plan.displayName : product.displayName,
      displayPrice: product.displayPrice,
      description: product.description,
      isFallback: false
    )
  }

  private func isRelevantPlusTransaction(_ transaction: Transaction) -> Bool {
    productIDs.contains(transaction.productID) && transaction.productType == .autoRenewable
  }

  private func isActive(_ transaction: Transaction) -> Bool {
    guard transaction.revocationDate == nil else { return false }

    if let expirationDate = transaction.expirationDate {
      return expirationDate > Date()
    }

    return true
  }

  private static func verified<T>(_ result: VerificationResult<T>) throws -> T {
    switch result {
    case .verified(let value):
      return value
    case .unverified:
      throw SubscriptionServiceError.verificationFailed
    }
  }
}
