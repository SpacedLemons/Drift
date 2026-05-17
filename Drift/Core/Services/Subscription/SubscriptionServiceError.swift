//
//  SubscriptionServiceError.swift
//  Drift
//
//  Created by Lucas Stuart West Rogers on 16/05/2026.
//

import Foundation

enum SubscriptionServiceError: Error, Equatable, LocalizedError, Sendable {
  case productsUnavailable
  case productUnavailable
  case purchaseCancelled
  case purchasePending
  case purchaseFailed
  case restoreFailed
  case verificationFailed
  case entitlementRefreshFailed

  var errorDescription: String? {
    switch self {
    case .productsUnavailable:
      "We couldn't load subscription options. Please try again."
    case .productUnavailable:
      "This subscription option is not available right now. Please try again."
    case .purchaseCancelled:
      "Purchase was cancelled."
    case .purchasePending:
      "Purchase is pending."
    case .purchaseFailed:
      "We couldn't complete the purchase. Please try again."
    case .restoreFailed:
      "We couldn't restore purchases. Please try again."
    case .verificationFailed:
      "We couldn't verify this purchase. Please try again."
    case .entitlementRefreshFailed:
      "We couldn't refresh Drift Plus status. Please try again."
    }
  }
}
