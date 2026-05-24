//
//  SettingsCoordinator.swift
//  Drift
//
//  Created by Lucas Stuart West Rogers on 12/05/2026.
//

import Observation

@MainActor
@Observable
final class SettingsCoordinator {
  var path: [SettingsRoute] = []

  func showChatGPTConnection() {
    path.append(.chatGPTConnection)
  }

  func showReminders() {
    path.append(.reminders)
  }

  func showVoiceTranscription() {
    path.append(.voiceTranscription)
  }

  func showAppearance() {
    path.append(.appearance)
  }

  func showBackupRestore() {
    path.append(.backupRestore)
  }

  func showPrivacy() {
    path.append(.privacy)
  }

  func showAbout() {
    path.append(.about)
  }
}
