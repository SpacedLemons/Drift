//
//  CustomThemeServiceError.swift
//  Drift
//
//  Created by Lucas Stuart West Rogers on 13/05/2026.
//

import Foundation

enum CustomThemeServiceError: LocalizedError, Equatable {
  case invalidName
  case duplicateName
  case loadFailed
  case saveFailed

  var errorDescription: String? {
    switch self {
    case .invalidName:
      "Add a theme name before saving."
    case .duplicateName:
      "That theme already exists."
    case .loadFailed:
      "We could not load your custom themes."
    case .saveFailed:
      "We could not save your custom theme. Please try again."
    }
  }
}
