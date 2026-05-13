//
//  CustomThemeServiceTests.swift
//  DriftTests
//
//  Created by Lucas Stuart West Rogers on 13/05/2026.
//

import Foundation
import Testing

@testable import Drift

struct CustomThemeServiceTests {
  @Test
  func createsAndLoadsCustomTheme() async throws {
    let defaults = try makeDefaults()
    let service = LocalCustomThemeService(userDefaults: defaults)

    let theme = try await service.createCustomTheme(named: " Side project ")
    let themes = try await service.loadCustomThemes()

    #expect(theme.displayName == "Side project")
    #expect(themes == [theme])
  }

  @Test
  func duplicateCustomThemeNamesAreRejected() async throws {
    let defaults = try makeDefaults()
    let service = LocalCustomThemeService(userDefaults: defaults)

    _ = try await service.createCustomTheme(named: "Home")

    await #expect(throws: CustomThemeServiceError.duplicateName) {
      try await service.createCustomTheme(named: "home")
    }
  }

  @Test
  func deleteCustomThemeRemovesItFromStorage() async throws {
    let defaults = try makeDefaults()
    let service = LocalCustomThemeService(userDefaults: defaults)
    let theme = try await service.createCustomTheme(named: "Home")

    try await service.deleteCustomTheme(id: theme.id)
    let themes = try await service.loadCustomThemes()

    #expect(themes.isEmpty)
  }

  private func makeDefaults() throws -> UserDefaults {
    let suiteName = "drift-custom-theme-tests-\(UUID().uuidString)"
    let defaults = try #require(UserDefaults(suiteName: suiteName))
    defaults.removePersistentDomain(forName: suiteName)
    return defaults
  }
}
