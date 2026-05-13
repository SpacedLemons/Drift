//
//  PreviewCustomThemeService.swift
//  Drift
//
//  Created by Lucas Stuart West Rogers on 13/05/2026.
//

import Foundation

actor PreviewCustomThemeService: CustomThemeService {
  private var themes: [CustomJournalTheme]

  init(themes: [CustomJournalTheme] = PreviewData.customThemes) {
    self.themes = themes
  }

  func loadCustomThemes() async throws -> [CustomJournalTheme] {
    themes
  }

  func createCustomTheme(named name: String) async throws -> CustomJournalTheme {
    let cleanedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !cleanedName.isEmpty else {
      throw CustomThemeServiceError.invalidName
    }

    let theme = CustomJournalTheme(name: cleanedName)
    themes.append(theme)
    return theme
  }

  func deleteCustomTheme(id: UUID) async throws {
    themes.removeAll { $0.id == id }
  }
}
