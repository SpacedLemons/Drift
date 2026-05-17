//
//  SubscriptionProduct.swift
//  Drift
//
//  Created by Lucas Stuart West Rogers on 16/05/2026.
//

import Foundation

struct SubscriptionProduct: Identifiable, Hashable, Codable, Sendable {
  enum Plan: String, CaseIterable, Identifiable, Codable, Hashable, Sendable {
    case monthly
    case yearly

    var id: String { rawValue }

    var productID: String {
      switch self {
      case .monthly: "drift.plus.monthly"
      case .yearly: "drift.plus.yearly"
      }
    }

    var displayName: String {
      switch self {
      case .monthly: "Monthly Plus"
      case .yearly: "Yearly Plus"
      }
    }
  }

  var id: String { productID }

  let productID: String
  let plan: Plan
  let displayName: String
  let displayPrice: String
  let description: String
  let isFallback: Bool

  static let defaultProductIDs = Plan.allCases.map(\.productID)

  static func fallback(plan: Plan) -> SubscriptionProduct {
    SubscriptionProduct(
      productID: plan.productID,
      plan: plan,
      displayName: plan.displayName,
      displayPrice: "Price unavailable",
      description: "StoreKit products are not available right now.",
      isFallback: true
    )
  }
}

enum SubscriptionPurchaseResult: Hashable, Sendable {
  case completed(SubscriptionEntitlement)
  case pending
}

struct SubscriptionRestoreResult: Hashable, Sendable {
  let entitlement: SubscriptionEntitlement
  let restoredActiveSubscription: Bool
}
