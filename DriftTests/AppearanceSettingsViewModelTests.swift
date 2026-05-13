//
//  AppearanceSettingsViewModelTests.swift
//  DriftTests
//
//  Created by Lucas Stuart West Rogers on 12/05/2026.
//

import Foundation
import Testing

@testable import Drift

@MainActor
struct AppearanceSettingsViewModelTests {
  @Test
  func loadUsesDefaultAppearanceSettingsAndFreeEntitlement() async throws {
    let viewModel = makeViewModel()

    await viewModel.load()

    #expect(viewModel.settings == .default)
    #expect(viewModel.availableThemes == ColorTheme.allCases)
    #expect(viewModel.availableAppIcons == AppIconOption.allCases)
    #expect(viewModel.entitlement == .free)
    #expect(viewModel.errorMessage == nil)
  }

  @Test
  func changesAccentColour() async throws {
    let viewModel = makeViewModel()

    await viewModel.load()
    await viewModel.setColorTheme(.green)

    #expect(viewModel.settings.colorTheme == .green)
  }

  @Test
  func changesLayoutDensity() async throws {
    let viewModel = makeViewModel()

    await viewModel.load()
    await viewModel.setLayoutDensity(.spacious)

    #expect(viewModel.settings.layoutDensity == .spacious)
  }

  @Test
  func loadFailureShowsUserFriendlyError() async throws {
    let viewModel = AppearanceSettingsViewModel(
      customisationService: AppearanceFailingCustomisationService(),
      subscriptionService: DisabledSubscriptionService()
    )

    await viewModel.load()

    #expect(viewModel.errorMessage == "We could not load appearance settings.")
  }

  @Test
  func saveFailureShowsUserFriendlyError() async throws {
    let viewModel = AppearanceSettingsViewModel(
      customisationService: AppearanceFailingCustomisationService(
        loadResult: .default,
        shouldFailSave: true
      ),
      subscriptionService: DisabledSubscriptionService()
    )

    await viewModel.load()
    await viewModel.setColorTheme(.green)

    #expect(viewModel.settings.colorTheme == .driftPurple)
    #expect(viewModel.errorMessage == "We could not save this setting. Please try again.")
    #expect(!viewModel.isSaving)
  }

  private func makeViewModel() -> AppearanceSettingsViewModel {
    let suiteName = "drift.appearance.tests.\(UUID().uuidString)"
    let userDefaults = UserDefaults(suiteName: suiteName) ?? .standard
    userDefaults.removePersistentDomain(forName: suiteName)

    return AppearanceSettingsViewModel(
      customisationService: LocalCustomisationService(
        userDefaults: userDefaults,
        settingsKey: "\(suiteName).settings"
      ),
      subscriptionService: DisabledSubscriptionService()
    )
  }
}

private actor AppearanceFailingCustomisationService: CustomisationService {
  let loadResult: AppAppearanceSettings?
  let shouldFailSave: Bool

  init(
    loadResult: AppAppearanceSettings? = nil,
    shouldFailSave: Bool = false
  ) {
    self.loadResult = loadResult
    self.shouldFailSave = shouldFailSave
  }

  func loadAppearanceSettings() async throws -> AppAppearanceSettings {
    guard let loadResult else {
      throw DriftServiceError.unavailable("Appearance unavailable")
    }

    return loadResult
  }

  func saveAppearanceSettings(_ settings: AppAppearanceSettings) async throws {
    if shouldFailSave {
      throw DriftServiceError.unavailable("Appearance unavailable")
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
