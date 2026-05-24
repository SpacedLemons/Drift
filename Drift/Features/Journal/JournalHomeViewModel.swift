//
//  JournalHomeViewModel.swift
//  Drift
//
//  Created by Lucas Stuart West Rogers on 12/05/2026.
//

import Foundation
import Observation

@MainActor
@Observable
final class JournalHomeViewModel {
  @ObservationIgnored
  private let journalRepository: any JournalRepository

  private(set) var entries: [JournalEntry] = []
  private(set) var isLoading = false
  private(set) var errorMessage: String?

  var selectedDriftTypeFilter: DriftType?

  var shouldShowFirstRunIntro: Bool {
    !isLoading && errorMessage == nil && entries.isEmpty
  }

  init(journalRepository: any JournalRepository) {
    self.journalRepository = journalRepository
  }

  var visibleEntries: [JournalEntry] {
    entries
      .filter(matchesSelectedDriftType)
      .sorted { $0.createdAt > $1.createdAt }
  }

  var driftTypeFilters: [DriftType] {
    [.thought, .goal, .idea, .reflection, .memory]
  }

  func load() async {
    guard !isLoading else { return }

    isLoading = true
    errorMessage = nil

    do {
      entries = try await journalRepository.fetchEntries()
    } catch {
      errorMessage = userFacingErrorMessage(for: error)
      entries = []
    }

    isLoading = false
  }

  func selectDriftTypeFilter(_ driftType: DriftType?) {
    selectedDriftTypeFilter = driftType
  }

  func entry(id: UUID) -> JournalEntry? {
    entries.first { $0.id == id }
  }

  private func matchesSelectedDriftType(_ entry: JournalEntry) -> Bool {
    guard let selectedDriftTypeFilter else { return true }
    return entry.driftType == selectedDriftTypeFilter
  }

  private func userFacingErrorMessage(for error: any Error) -> String {
    if let repositoryError = error as? JournalRepositoryError {
      return repositoryError.localizedDescription
    }

    return "We could not load your Drifts."
  }
}
