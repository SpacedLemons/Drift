//
//  CustomThemeService.swift
//  Drift
//
//  Created by Lucas Stuart West Rogers on 13/05/2026.
//

import Foundation
import Mockable

@Mockable
protocol CustomThemeService {
  func loadCustomThemes() async throws -> [CustomJournalTheme]
  func createCustomTheme(named name: String) async throws -> CustomJournalTheme
  func deleteCustomTheme(id: UUID) async throws
}
