//
//  ExportServiceError.swift
//  Drift
//
//  Created by Lucas Stuart West Rogers on 13/05/2026.
//

import Foundation

enum ExportServiceError: Error, Equatable, LocalizedError, Sendable {
  case writeFailed

  var errorDescription: String? {
    switch self {
    case .writeFailed:
      "We could not create your export. Please try again."
    }
  }
}
