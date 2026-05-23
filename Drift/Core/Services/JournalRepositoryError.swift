//
//  JournalRepositoryError.swift
//  Drift
//
//  Created by Lucas Stuart West Rogers on 12/05/2026.
//

import Foundation

enum JournalRepositoryError: LocalizedError, Equatable, Sendable {
  case entryNotFound
  case saveFailed
  case updateFailed
  case deleteFailed
  case fetchFailed

  var errorDescription: String? {
    switch self {
    case .entryNotFound:
      "We could not find this Drift."
    case .saveFailed:
      "We could not save this Drift. Please try again."
    case .updateFailed:
      "We could not save your Drift changes. Please try again."
    case .deleteFailed:
      "We could not delete this Drift. Please try again."
    case .fetchFailed:
      "We could not load your Drifts."
    }
  }
}
