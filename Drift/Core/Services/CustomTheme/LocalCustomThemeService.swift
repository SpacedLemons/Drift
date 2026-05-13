//
//  LocalCustomThemeService.swift
//  Drift
//
//  Created by Lucas Stuart West Rogers on 13/05/2026.
//

import Foundation

actor LocalCustomThemeService: CustomThemeService {
  private let userDefaults: UserDefaults
  private let storageKey: String
  private let now: () -> Date
  private var cachedThemes: [CustomJournalTheme]?

  init(
    userDefaults: UserDefaults = .standard,
    storageKey: String = "drift.custom.themes",
    now: @escaping () -> Date = Date.init
  ) {
    self.userDefaults = userDefaults
    self.storageKey = storageKey
    self.now = now
  }

  func loadCustomThemes() async throws -> [CustomJournalTheme] {
    if let cachedThemes {
      return cachedThemes.sorted { $0.createdAt < $1.createdAt }
    }

    guard let data = userDefaults.data(forKey: storageKey) else {
      cachedThemes = []
      return []
    }

    do {
      let themes = try JSONDecoder().decode([CustomJournalTheme].self, from: data)
      cachedThemes = themes
      return themes.sorted { $0.createdAt < $1.createdAt }
    } catch {
      throw CustomThemeServiceError.loadFailed
    }
  }

  func createCustomTheme(named name: String) async throws -> CustomJournalTheme {
    let cleanedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !cleanedName.isEmpty else {
      throw CustomThemeServiceError.invalidName
    }

    var themes = try await loadCustomThemes()
    guard
      !themes.contains(where: { $0.displayName.caseInsensitiveCompare(cleanedName) == .orderedSame }
      )
    else {
      throw CustomThemeServiceError.duplicateName
    }

    let theme = CustomJournalTheme(name: cleanedName, createdAt: now())
    themes.append(theme)
    try save(themes)
    return theme
  }

  func deleteCustomTheme(id: UUID) async throws {
    var themes = try await loadCustomThemes()
    themes.removeAll { $0.id == id }
    try save(themes)
  }

  private func save(_ themes: [CustomJournalTheme]) throws {
    do {
      let data = try JSONEncoder().encode(themes)
      userDefaults.set(data, forKey: storageKey)
      cachedThemes = themes
    } catch {
      throw CustomThemeServiceError.saveFailed
    }
  }
}
