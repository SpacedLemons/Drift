//
//  AppRoute.swift
//  Drift
//
//  Created by Lucas Stuart West Rogers on 12/05/2026.
//

import Foundation

enum AppRoute: Hashable {
  case journalEntry(UUID)
  case editJournalEntry(UUID)
  case capture(CaptureRoute)
}
