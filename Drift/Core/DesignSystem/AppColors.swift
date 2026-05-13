//
//  AppColors.swift
//  Drift
//
//  Created by Lucas Stuart West Rogers on 12/05/2026.
//

import SwiftUI

enum AppColors {
  static let background = Color(red: 0.025, green: 0.027, blue: 0.045)
  static let backgroundElevated = Color(red: 0.055, green: 0.057, blue: 0.085)
  static let surface = Color(red: 0.09, green: 0.085, blue: 0.13)
  static let surfaceRaised = Color(red: 0.13, green: 0.115, blue: 0.18)
  static let accent = Color(red: 0.62, green: 0.47, blue: 1.0)
  static let accentSecondary = Color(red: 0.27, green: 0.82, blue: 0.76)
  static let warmAccent = Color(red: 1.0, green: 0.64, blue: 0.42)
  static let textPrimary = Color(red: 0.95, green: 0.94, blue: 0.98)
  static let textSecondary = Color(red: 0.70, green: 0.70, blue: 0.78)
  static let textTertiary = Color(red: 0.50, green: 0.50, blue: 0.60)
  static let border = Color.white.opacity(0.10)

  static func accent(for theme: ColorTheme) -> Color {
    switch theme {
    case .driftPurple: accent
    case .tideTeal: accentSecondary
    case .blue: Color(red: 0.36, green: 0.58, blue: 1.0)
    case .green: Color(red: 0.35, green: 0.78, blue: 0.52)
    case .orange: warmAccent
    case .pink: Color(red: 1.0, green: 0.45, blue: 0.70)
    }
  }

  static func moodColor(_ mood: Mood?) -> Color {
    switch mood {
    case .positive: accentSecondary
    case .neutral: Color(red: 0.63, green: 0.67, blue: 0.76)
    case .low: Color(red: 0.45, green: 0.60, blue: 0.88)
    case .anxious: warmAccent
    case .stressed: Color(red: 1.0, green: 0.42, blue: 0.46)
    case .reflective: accent
    case .unknown, .none: textTertiary
    }
  }
}
