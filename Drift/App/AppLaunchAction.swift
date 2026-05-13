//
//  AppLaunchAction.swift
//  Drift
//
//  Created by Lucas Stuart West Rogers on 13/05/2026.
//

import Foundation
import Observation

enum AppLaunchAction: Equatable, Sendable {
  case startJournalEntry
}

@Observable
final class AppLaunchActionStore: @unchecked Sendable {
  private(set) var pendingAction: AppLaunchAction?
  private(set) var routingErrorMessage: String?

  @MainActor
  func enqueue(_ action: AppLaunchAction) {
    pendingAction = action
  }

  @MainActor
  func consumePendingAction() -> AppLaunchAction? {
    let action = pendingAction
    pendingAction = nil
    return action
  }

  @MainActor
  func reportRoutingError(
    _ message: String = ReminderServiceError.routingFailed.localizedDescription
  ) {
    routingErrorMessage = message
  }

  @MainActor
  func clearRoutingError() {
    routingErrorMessage = nil
  }
}
