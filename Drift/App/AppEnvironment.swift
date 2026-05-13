//
//  AppEnvironment.swift
//  Drift
//
//  Created by Lucas Stuart West Rogers on 12/05/2026.
//

import SwiftData

struct AppEnvironment: Sendable {
  let dependencies: AppDependencyContainer

  static func live(modelContainer: ModelContainer) -> AppEnvironment {
    AppEnvironment(
      dependencies: .live(modelContainer: modelContainer)
    )
  }
}
