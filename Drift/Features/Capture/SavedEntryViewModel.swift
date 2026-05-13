//
//  SavedEntryViewModel.swift
//  Drift
//
//  Created by Lucas Stuart West Rogers on 12/05/2026.
//

import Observation

@MainActor
@Observable
final class SavedEntryViewModel {
  let entry: JournalEntry

  init(entry: JournalEntry) {
    self.entry = entry
  }
}
