//
//  CustomisationServiceError.swift
//  Drift
//
//  Created by Lucas Stuart West Rogers on 13/05/2026.
//

import Foundation

enum CustomisationServiceError: Error, Equatable, LocalizedError, Sendable {
  case loadFailed
  case saveFailed

  var errorDescription: String? {
    switch self {
    case .loadFailed:
      "We could not load appearance settings."
    case .saveFailed:
      "We could not save this setting. Please try again."
    }
  }
}
