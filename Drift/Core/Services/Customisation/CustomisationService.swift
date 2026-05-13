//
//  CustomisationService.swift
//  Drift
//
//  Created by Lucas Stuart West Rogers on 12/05/2026.
//

import Mockable

@Mockable
protocol CustomisationService {
  func loadAppearanceSettings() async throws -> AppAppearanceSettings
  func saveAppearanceSettings(_ settings: AppAppearanceSettings) async throws
  func availableColorThemes() async -> [ColorTheme]
  func availableAppIcons() async -> [AppIconOption]
  func isCustomisationUnlocked() async throws -> Bool
}
