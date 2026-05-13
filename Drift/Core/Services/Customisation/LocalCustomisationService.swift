//
//  LocalCustomisationService.swift
//  Drift
//
//  Created by Lucas Stuart West Rogers on 12/05/2026.
//

import Foundation

actor LocalCustomisationService: CustomisationService {
  private let userDefaults: UserDefaults
  private let settingsKey: String
  private var settings: AppAppearanceSettings

  init(
    settings: AppAppearanceSettings = .default,
    userDefaults: UserDefaults = .standard,
    settingsKey: String = "drift.appearance.settings"
  ) {
    self.userDefaults = userDefaults
    self.settingsKey = settingsKey
    self.settings = settings
  }

  func loadAppearanceSettings() async throws -> AppAppearanceSettings {
    guard let data = userDefaults.data(forKey: settingsKey) else {
      return settings
    }

    do {
      settings = try JSONDecoder().decode(AppAppearanceSettings.self, from: data)
    } catch {
      throw CustomisationServiceError.loadFailed
    }

    return settings
  }

  func saveAppearanceSettings(_ settings: AppAppearanceSettings) async throws {
    do {
      let data = try JSONEncoder().encode(settings)
      self.settings = settings
      userDefaults.set(data, forKey: settingsKey)
    } catch {
      throw CustomisationServiceError.saveFailed
    }
  }

  func availableColorThemes() async -> [ColorTheme] {
    ColorTheme.allCases
  }

  func availableAppIcons() async -> [AppIconOption] {
    AppIconOption.allCases
  }

  func isCustomisationUnlocked() async throws -> Bool {
    false
  }
}
