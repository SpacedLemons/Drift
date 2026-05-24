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
  @ObservationIgnored
  private let spaceRepository: any SpaceRepository
  @ObservationIgnored
  private let searchRankingService: DriftSearchRankingService

  private(set) var entries: [JournalEntry] = []
  private(set) var spacesByID: [UUID: DriftSpace] = [:]
  private(set) var isLoading = false
  private(set) var errorMessage: String?

  var searchText = ""
  var selectedDriftTypeFilter: DriftType?

  var shouldShowFirstRunIntro: Bool {
    !isLoading && errorMessage == nil && entries.isEmpty && !isSearching
  }

  init(
    journalRepository: any JournalRepository,
    spaceRepository: any SpaceRepository = LocalSpaceRepository(),
    searchRankingService: DriftSearchRankingService = DriftSearchRankingService()
  ) {
    self.journalRepository = journalRepository
    self.spaceRepository = spaceRepository
    self.searchRankingService = searchRankingService
  }

  var visibleEntries: [JournalEntry] {
    let filteredEntries = entries.filter(matchesSelectedDriftType)
    return searchRankingService.rankedEntries(
      filteredEntries,
      query: searchText,
      spacesByID: spacesByID
    )
  }

  var driftTypeFilters: [DriftType] {
    [.thought, .reflection, .goal, .idea, .memory, .task]
  }

  var isSearching: Bool {
    !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
  }

  var visibleEntriesSectionTitle: String {
    isSearching ? "Matching Drifts" : "Recent Drifts"
  }

  var emptyEntriesTitle: String {
    if entries.isEmpty {
      return "No Drifts yet."
    }

    if isSearching {
      return "No matching Drifts."
    }

    return "No Drifts here."
  }

  var emptyEntriesMessage: String {
    if entries.isEmpty {
      return "Tap the microphone when you are ready to capture a thought."
    }

    if isSearching {
      return "Try another word or phrase."
    }

    return "Try another Drift Type."
  }

  func load() async {
    guard !isLoading else { return }

    isLoading = true
    errorMessage = nil

    do {
      entries = try await journalRepository.fetchEntries()
      spacesByID = await loadSpacesByID()
    } catch {
      errorMessage = userFacingErrorMessage(for: error)
      entries = []
      spacesByID = [:]
    }

    isLoading = false
  }

  func selectDriftTypeFilter(_ driftType: DriftType?) {
    selectedDriftTypeFilter = driftType
  }

  func spaceNames(for entry: JournalEntry) -> [String] {
    entry.spaceIds.compactMap { spacesByID[$0]?.name }
  }

  func entry(id: UUID) -> JournalEntry? {
    entries.first { $0.id == id }
  }

  private func loadSpacesByID() async -> [UUID: DriftSpace] {
    do {
      let spaces = try await spaceRepository.fetchSpaces()
      return spaces.reduce(into: [:]) { result, space in
        result[space.id] = space
      }
    } catch {
      return [:]
    }
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

struct DriftSearchRankingService {
  func rankedEntries(
    _ entries: [JournalEntry],
    query: String,
    spacesByID: [UUID: DriftSpace]
  ) -> [JournalEntry] {
    let normalizedQuery = normalize(query)
    guard !normalizedQuery.isEmpty else {
      return entries.sorted { $0.createdAt > $1.createdAt }
    }

    return
      entries
      .compactMap { entry -> RankedJournalEntry? in
        guard let score = score(entry, query: normalizedQuery, spacesByID: spacesByID) else {
          return nil
        }

        return RankedJournalEntry(entry: entry, score: score)
      }
      .sorted { lhs, rhs in
        if lhs.score != rhs.score {
          return lhs.score > rhs.score
        }

        return lhs.entry.createdAt > rhs.entry.createdAt
      }
      .map(\.entry)
  }

  private func score(
    _ entry: JournalEntry,
    query: String,
    spacesByID: [UUID: DriftSpace]
  ) -> Int? {
    var score = 0

    if fieldMatches(entry.title ?? "", query: query) {
      score += 300
    }

    if weightedMetadataValues(for: entry, spacesByID: spacesByID)
      .contains(where: { fieldMatches($0, query: query) })
    {
      score += 200
    }

    if fieldMatches(entry.transcript, query: query) {
      score += 100
    }

    guard score > 0 else { return nil }
    return score
  }

  private func weightedMetadataValues(
    for entry: JournalEntry,
    spacesByID: [UUID: DriftSpace]
  ) -> [String] {
    [
      entry.driftType.displayName,
      entry.driftType.rawValue,
      entry.mood?.displayName,
      entry.mood?.rawValue,
      entry.themes.map(\.displayName).joined(separator: " "),
      entry.themes.map(\.rawValue).joined(separator: " "),
      entry.customThemes.map(\.displayName).joined(separator: " "),
      entry.tags.joined(separator: " "),
      entry.spaceIds.compactMap { spacesByID[$0]?.name }.joined(separator: " "),
    ]
    .compactMap { $0 }
  }

  private func fieldMatches(_ value: String, query: String) -> Bool {
    let normalizedValue = normalize(value)
    guard !normalizedValue.isEmpty else { return false }

    if normalizedValue.contains(query) {
      return true
    }

    let terms = query.split(separator: " ").map(String.init)
    guard terms.count > 1 else { return false }
    return terms.allSatisfy { normalizedValue.contains($0) }
  }

  private func normalize(_ value: String) -> String {
    value
      .trimmingCharacters(in: .whitespacesAndNewlines)
      .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
      .lowercased()
  }
}

private struct RankedJournalEntry {
  let entry: JournalEntry
  let score: Int
}
