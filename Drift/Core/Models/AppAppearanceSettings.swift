//
//  AppAppearanceSettings.swift
//  Drift
//
//  Created by Lucas Stuart West Rogers on 12/05/2026.
//

struct AppAppearanceSettings: Hashable, Codable, Sendable {
  var colorTheme: ColorTheme
  var appIcon: AppIconOption
  var mode: AppearanceMode
  var layoutDensity: LayoutDensity
  var fontStyle: FontStyle

  static let `default` = AppAppearanceSettings(
    colorTheme: .driftPurple,
    appIcon: .standard,
    mode: .system,
    layoutDensity: .cozy,
    fontStyle: .standard
  )
}

enum ColorTheme: String, CaseIterable, Identifiable, Codable, Hashable, Sendable {
  case driftPurple
  case tideTeal
  case blue
  case green
  case orange
  case pink

  var id: String { rawValue }

  var displayName: String {
    switch self {
    case .driftPurple: "Purple"
    case .tideTeal: "Teal"
    case .blue: "Blue"
    case .green: "Green"
    case .orange: "Orange"
    case .pink: "Pink"
    }
  }
}

enum AppIconOption: String, CaseIterable, Identifiable, Codable, Hashable, Sendable {
  case standard

  var id: String { rawValue }
}

enum AppearanceMode: String, CaseIterable, Identifiable, Codable, Hashable, Sendable {
  case system
  case light
  case dark

  var id: String { rawValue }

  var displayName: String {
    switch self {
    case .system: "System"
    case .light: "Light"
    case .dark: "Dark"
    }
  }
}

enum LayoutDensity: String, CaseIterable, Identifiable, Codable, Hashable, Sendable {
  case cozy
  case spacious

  var id: String { rawValue }

  var displayName: String {
    switch self {
    case .cozy: "Cozy"
    case .spacious: "Spacious"
    }
  }
}

enum FontStyle: String, CaseIterable, Identifiable, Codable, Hashable, Sendable {
  case standard
  case rounded

  var id: String { rawValue }
}
