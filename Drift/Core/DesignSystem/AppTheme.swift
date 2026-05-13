//
//  AppTheme.swift
//  Drift
//
//  Created by Lucas Stuart West Rogers on 12/05/2026.
//

import SwiftUI

enum AppTheme {
  static let cardCornerRadius: CGFloat = 20
  static let controlCornerRadius: CGFloat = 16

  static var backgroundGradient: LinearGradient {
    LinearGradient(
      colors: [
        AppColors.background,
        Color(red: 0.04, green: 0.035, blue: 0.075),
        AppColors.background,
      ],
      startPoint: .topLeading,
      endPoint: .bottomTrailing
    )
  }

  static func cardStroke(_ color: Color = AppColors.border) -> some ShapeStyle {
    color
  }
}
