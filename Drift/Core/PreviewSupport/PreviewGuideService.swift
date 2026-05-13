//
//  PreviewGuideService.swift
//  Drift
//
//  Created by Lucas Stuart West Rogers on 13/05/2026.
//

actor PreviewGuideService: GuideService {
  private var dismissed: Bool

  init(dismissed: Bool = false) {
    self.dismissed = dismissed
  }

  func isGuideDismissed() async -> Bool {
    dismissed
  }

  func setGuideDismissed(_ isDismissed: Bool) async {
    dismissed = isDismissed
  }
}
