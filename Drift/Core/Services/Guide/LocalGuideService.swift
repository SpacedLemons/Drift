//
//  LocalGuideService.swift
//  Drift
//
//  Created by Lucas Stuart West Rogers on 13/05/2026.
//

import Foundation

actor LocalGuideService: GuideService {
  private let userDefaults: UserDefaults
  private let dismissedKey: String

  init(
    userDefaults: UserDefaults = .standard,
    dismissedKey: String = "drift.guide.dismissed"
  ) {
    self.userDefaults = userDefaults
    self.dismissedKey = dismissedKey
  }

  func isGuideDismissed() async -> Bool {
    userDefaults.bool(forKey: dismissedKey)
  }

  func setGuideDismissed(_ isDismissed: Bool) async {
    userDefaults.set(isDismissed, forKey: dismissedKey)
  }
}
