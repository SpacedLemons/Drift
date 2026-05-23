//
//  ServiceError.swift
//  Drift
//
//  Created by Lucas Stuart West Rogers on 12/05/2026.
//

import Foundation

enum DriftServiceError: LocalizedError, Equatable, Sendable {
  case unavailable(String)
  case permissionDenied(String)
  case emptyRecording
  case notFound

  var errorDescription: String? {
    switch self {
    case .unavailable(let message):
      message
    case .permissionDenied(let message):
      message
    case .emptyRecording:
      "No usable recording was captured."
    case .notFound:
      "The requested Drift could not be found."
    }
  }
}
