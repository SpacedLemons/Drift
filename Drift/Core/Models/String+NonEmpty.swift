//
//  String+NonEmpty.swift
//  Drift
//
//  Created by Lucas Stuart West Rogers on 23/05/2026.
//

import Foundation

extension String {
  var nonEmpty: String? {
    isEmpty ? nil : self
  }

  var trimmedNonEmpty: String? {
    trimmingCharacters(in: .whitespacesAndNewlines).nonEmpty
  }

  var firstNonEmptyLine: String? {
    components(separatedBy: .newlines)
      .lazy
      .compactMap { $0.trimmedNonEmpty }
      .first
  }
}
