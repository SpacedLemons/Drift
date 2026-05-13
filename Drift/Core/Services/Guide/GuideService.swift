//
//  GuideService.swift
//  Drift
//
//  Created by Lucas Stuart West Rogers on 13/05/2026.
//

import Mockable

@Mockable
protocol GuideService {
  func isGuideDismissed() async -> Bool
  func setGuideDismissed(_ isDismissed: Bool) async
}
