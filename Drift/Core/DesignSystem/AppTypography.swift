//
//  AppTypography.swift
//  Drift
//
//  Created by Lucas Stuart West Rogers on 12/05/2026.
//

import SwiftUI

enum AppTypography {
  static let appTitle = Font.system(.largeTitle, design: .rounded, weight: .semibold)
  static let screenTitle = Font.system(.title2, design: .rounded, weight: .semibold)
  static let cardTitle = Font.system(.headline, design: .rounded, weight: .semibold)
  static let body = Font.system(.body, design: .default, weight: .regular)
  static let bodyEmphasis = Font.system(.body, design: .default, weight: .medium)
  static let caption = Font.system(.caption, design: .default, weight: .medium)
}
