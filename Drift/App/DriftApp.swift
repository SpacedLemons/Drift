//
//  DriftApp.swift
//  Drift
//
//  Created by Lucas Stuart West Rogers on 12/05/2026.
//

import SwiftData
import SwiftUI
import UserNotifications

@main
struct DriftApp: App {
  private let appEnvironment: AppEnvironment?
  private let launchActionStore: AppLaunchActionStore
  private let modelContainer: ModelContainer?
  private let notificationDelegate: AppNotificationDelegate?
  private let startupErrorMessage: String?

  @State private var coordinator = AppCoordinator()

  init() {
    let launchActionStore = AppLaunchActionStore()
    self.launchActionStore = launchActionStore

    do {
      let container = try SwiftDataContainer.make()
      modelContainer = container
      let environment = AppEnvironment.live(modelContainer: container)
      appEnvironment = environment

      let notificationDelegate = AppNotificationDelegate(
        reminderService: environment.dependencies.reminderService,
        launchActionStore: launchActionStore
      )
      self.notificationDelegate = notificationDelegate
      UNUserNotificationCenter.current().delegate = notificationDelegate
      environment.dependencies.reminderService.registerNotificationActions()
      startupErrorMessage = nil
    } catch {
      modelContainer = nil
      appEnvironment = nil
      notificationDelegate = nil
      startupErrorMessage =
        "Drift could not open local Drift storage. Please restart the app."
    }
  }

  var body: some Scene {
    WindowGroup {
      if let appEnvironment, let modelContainer {
        AppShellView(
          environment: appEnvironment,
          coordinator: coordinator,
          launchActionStore: launchActionStore
        )
        .modelContainer(modelContainer)
      } else {
        StartupFailureView(
          message: startupErrorMessage
            ?? "Drift could not start. Please restart the app."
        )
      }
    }
  }
}

private struct StartupFailureView: View {
  let message: String

  var body: some View {
    ZStack {
      AppTheme.backgroundGradient
        .ignoresSafeArea()

      EmptyStateView(
        title: "Drift could not start",
        message: message,
        icon: AppIcons.warning
      )
      .padding(AppSpacing.l)
    }
  }
}
