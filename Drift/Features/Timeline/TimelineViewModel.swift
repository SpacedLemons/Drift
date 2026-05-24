//
//  TimelineViewModel.swift
//  Drift
//
//  Created by Lucas Stuart West Rogers on 23/05/2026.
//

import Foundation
import Observation

@MainActor
@Observable
final class TimelineViewModel {
  @ObservationIgnored
  private let journalRepository: any JournalRepository

  private(set) var entries: [JournalEntry] = []
  private(set) var isLoading = false
  private(set) var errorMessage: String?

  var selectedDriftTypeFilter: DriftType?

  init(
    journalRepository: any JournalRepository
  ) {
    self.journalRepository = journalRepository
  }

  var visibleEntries: [JournalEntry] {
    entries
      .filter(matchesSelectedDriftType)
      .sorted { $0.createdAt > $1.createdAt }
  }

  func load() async {
    guard !isLoading else { return }

    isLoading = true
    errorMessage = nil

    do {
      entries = try await journalRepository.fetchEntries()
    } catch {
      entries = []
      errorMessage = "We could not load your Timeline."
    }

    isLoading = false
  }

  func selectDriftTypeFilter(_ driftType: DriftType?) {
    selectedDriftTypeFilter = driftType
  }

  private func matchesSelectedDriftType(_ entry: JournalEntry) -> Bool {
    guard let selectedDriftTypeFilter else { return true }
    return entry.driftType == selectedDriftTypeFilter
  }
}
