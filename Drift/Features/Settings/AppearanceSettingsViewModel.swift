//
//  AppearanceSettingsViewModel.swift
//  Drift
//
//  Created by Lucas Stuart West Rogers on 12/05/2026.
//

import Observation
import SwiftUI

@MainActor
@Observable
final class AppearanceSettingsViewModel {
  @ObservationIgnored
  private let customisationService: any CustomisationService & Sendable
  @ObservationIgnored
  private let subscriptionService: any SubscriptionService & Sendable

  private(set) var settings: AppAppearanceSettings = .default
  private(set) var availableThemes: [ColorTheme] = ColorTheme.allCases
  private(set) var availableAppIcons: [AppIconOption] = AppIconOption.allCases
  private(set) var entitlement: SubscriptionEntitlement = .free
  private(set) var isSaving = false
  private(set) var errorMessage: String?

  init(
    customisationService: any CustomisationService & Sendable,
    subscriptionService: any SubscriptionService & Sendable
  ) {
    self.customisationService = customisationService
    self.subscriptionService = subscriptionService
  }

  var selectedAccentColor: Color {
    AppColors.accent(for: settings.colorTheme)
  }

  func load() async {
    errorMessage = nil

    do {
      settings = try await customisationService.loadAppearanceSettings()
      availableThemes = await customisationService.availableColorThemes()
      availableAppIcons = await customisationService.availableAppIcons()
      entitlement = try await subscriptionService.currentEntitlement()
    } catch {
      errorMessage = "We could not load appearance settings."
    }
  }

  func setMode(_ mode: AppearanceMode) async {
    var updatedSettings = settings
    updatedSettings.mode = mode
    await save(updatedSettings)
  }

  func setColorTheme(_ theme: ColorTheme) async {
    var updatedSettings = settings
    updatedSettings.colorTheme = theme
    await save(updatedSettings)
  }

  func setLayoutDensity(_ density: LayoutDensity) async {
    var updatedSettings = settings
    updatedSettings.layoutDensity = density
    await save(updatedSettings)
  }

  private func save(_ updatedSettings: AppAppearanceSettings) async {
    isSaving = true
    errorMessage = nil

    do {
      try await customisationService.saveAppearanceSettings(updatedSettings)
      settings = updatedSettings
    } catch {
      errorMessage = "We could not save this setting. Please try again."
    }

    isSaving = false
  }
}
