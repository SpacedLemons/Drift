//
//  DriftPlusPaywallViewModel.swift
//  Drift
//
//  Created by Lucas Stuart West Rogers on 16/05/2026.
//

import Foundation
import Observation

@MainActor
@Observable
final class DriftPlusPaywallViewModel {
  @ObservationIgnored
  private let subscriptionService: any SubscriptionService & Sendable

  let reasonMessage: String?

  private(set) var products: [SubscriptionProduct] = []
  private(set) var entitlement: SubscriptionEntitlement = .free
  private(set) var isLoadingProducts = false
  private(set) var purchasingPlan: SubscriptionProduct.Plan?
  private(set) var isRestoring = false
  private(set) var errorMessage: String?
  private(set) var statusMessage: String?
  var selectedPlan: SubscriptionProduct.Plan = .yearly

  init(
    subscriptionService: any SubscriptionService & Sendable,
    reasonMessage: String? = nil
  ) {
    self.subscriptionService = subscriptionService
    self.reasonMessage = reasonMessage
  }

  var monthlyProduct: SubscriptionProduct {
    product(for: .monthly)
  }

  var yearlyProduct: SubscriptionProduct {
    product(for: .yearly)
  }

  var hasStoreKitProducts: Bool {
    products.contains { !$0.isFallback }
  }

  var sortedProducts: [SubscriptionProduct] {
    SubscriptionProduct.Plan.allCases.map(product)
  }

  var selectedProduct: SubscriptionProduct {
    product(for: selectedPlan)
  }

  var isPurchaseInFlight: Bool {
    purchasingPlan != nil || isRestoring
  }

  func load() async {
    guard !isLoadingProducts else { return }

    isLoadingProducts = true
    errorMessage = nil
    statusMessage = nil
    defer { isLoadingProducts = false }

    do {
      products = try await subscriptionService.loadProducts()
      entitlement = try await subscriptionService.currentEntitlement()
      selectedPlan = products.contains { $0.plan == .yearly } ? .yearly : .monthly
    } catch let error as SubscriptionServiceError {
      products = []
      errorMessage = error.localizedDescription
      entitlement = (try? await subscriptionService.currentEntitlement()) ?? .free
    } catch {
      products = []
      errorMessage = SubscriptionServiceError.productsUnavailable.localizedDescription
      entitlement = (try? await subscriptionService.currentEntitlement()) ?? .free
    }
  }

  func purchaseMonthly() async {
    await purchase(product: monthlyProduct)
  }

  func purchaseYearly() async {
    await purchase(product: yearlyProduct)
  }

  func purchaseSelectedPlan() async {
    await purchase(product: selectedProduct)
  }

  func restorePurchases() async {
    guard !isPurchaseInFlight else { return }

    isRestoring = true
    errorMessage = nil
    statusMessage = nil
    defer { isRestoring = false }

    do {
      let result = try await subscriptionService.restorePurchases()
      entitlement = result.entitlement
      statusMessage =
        result.restoredActiveSubscription
        ? "Drift Plus is active."
        : "No active Drift Plus purchase was found."
    } catch let error as SubscriptionServiceError {
      errorMessage = error.localizedDescription
    } catch {
      errorMessage = SubscriptionServiceError.restoreFailed.localizedDescription
    }
  }

  private func purchase(product: SubscriptionProduct) async {
    guard !isPurchaseInFlight else { return }
    guard !product.isFallback else {
      errorMessage = SubscriptionServiceError.productsUnavailable.localizedDescription
      return
    }

    purchasingPlan = product.plan
    errorMessage = nil
    statusMessage = nil
    defer { purchasingPlan = nil }

    do {
      let result = try await subscriptionService.purchase(product: product)

      switch result {
      case .completed(let entitlement):
        self.entitlement = entitlement
        statusMessage = "Drift Plus is active."
      case .pending:
        statusMessage = SubscriptionServiceError.purchasePending.localizedDescription
      }
    } catch let error as SubscriptionServiceError {
      errorMessage = error.localizedDescription
    } catch {
      errorMessage = SubscriptionServiceError.purchaseFailed.localizedDescription
    }
  }

  private func product(for plan: SubscriptionProduct.Plan) -> SubscriptionProduct {
    products.first { $0.plan == plan } ?? .fallback(plan: plan)
  }
}
