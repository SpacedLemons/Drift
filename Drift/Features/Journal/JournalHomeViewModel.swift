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
  @ObservationIgnored
  private let calendar: Calendar
  @ObservationIgnored
  private let now: () -> Date
  @ObservationIgnored
  private var daysWithEntries: Set<Date> = []

  private(set) var entries: [JournalEntry] = []
  private(set) var spacesByID: [UUID: DriftSpace] = [:]
  private(set) var isLoading = false
  private(set) var errorMessage: String?
  private(set) var monthTransitionDirection: CalendarMonthTransitionDirection = .none

  var searchText = ""
  var selectedDriftTypeFilter: DriftType?
  var selectedDate: Date?
  var selectedMonth: Date
  var isCalendarExpanded = false

  var shouldShowFirstRunIntro: Bool {
    !isLoading && errorMessage == nil && entries.isEmpty && !isSearching
  }

  init(
    journalRepository: any JournalRepository,
    spaceRepository: any SpaceRepository = LocalSpaceRepository(),
    searchRankingService: DriftSearchRankingService = DriftSearchRankingService(),
    calendar: Calendar = .current,
    now: @escaping () -> Date = Date.init
  ) {
    self.journalRepository = journalRepository
    self.spaceRepository = spaceRepository
    self.searchRankingService = searchRankingService
    self.calendar = calendar
    self.now = now
    selectedDate = calendar.startOfDay(for: now())
    selectedMonth = Self.startOfMonth(for: now(), calendar: calendar)
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

  var dateStripDays: [Date] {
    let today = calendar.startOfDay(for: now())

    return (0..<7)
      .reversed()
      .compactMap { offset in
        calendar.date(byAdding: .day, value: -offset, to: today)
      }
  }

  var selectedMonthTitle: String {
    selectedMonth.formatted(.dateTime.month(.wide).year())
  }

  var selectedMonthID: String {
    Self.calendarIdentity(for: selectedMonth, calendar: calendar)
  }

  var weekdaySymbols: [String] {
    let symbols = calendar.veryShortStandaloneWeekdaySymbols
    guard !symbols.isEmpty else {
      return []
    }

    let firstIndex = (calendar.firstWeekday - 1 + symbols.count) % symbols.count
    return Array(symbols[firstIndex...] + symbols[..<firstIndex])
  }

  var calendarDays: [CalendarDayState] {
    guard
      let monthRange = calendar.range(of: .day, in: .month, for: selectedMonth),
      let firstDayOfMonth = calendar.date(
        from: calendar.dateComponents([.year, .month], from: selectedMonth))
    else {
      return []
    }

    let monthID = Self.calendarIdentity(for: firstDayOfMonth, calendar: calendar)
    let leadingBlankCount =
      (calendar.component(.weekday, from: firstDayOfMonth) - calendar.firstWeekday + 7) % 7
    var days = (0..<leadingBlankCount).map { index in
      CalendarDayState.empty(id: "capture-\(monthID)-leading-\(index)")
    }

    days += monthRange.compactMap { day -> CalendarDayState? in
      guard let date = calendar.date(byAdding: .day, value: day - 1, to: firstDayOfMonth) else {
        return nil
      }

      return CalendarDayState(
        id: "capture-\(monthID)-day-\(day)",
        date: date,
        dayNumber: day,
        hasEntries: dateHasEntries(date),
        isSelected: selectedDate.map { calendar.isDate($0, inSameDayAs: date) } ?? false,
        isToday: calendar.isDateInToday(date)
      )
    }

    let trailingBlankCount = (7 - (days.count % 7)) % 7
    days += (0..<trailingBlankCount).map { index in
      CalendarDayState.empty(id: "capture-\(monthID)-trailing-\(index)")
    }

    return days
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
      daysWithEntries = Set(entries.map { calendar.startOfDay(for: $0.createdAt) })
      spacesByID = await loadSpacesByID()
    } catch {
      errorMessage = userFacingErrorMessage(for: error)
      entries = []
      daysWithEntries = []
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

  func selectDate(_ date: Date?) {
    if let date, selectedDate.map({ calendar.isDate($0, inSameDayAs: date) }) == true {
      selectedDate = nil
    } else {
      selectedDate = date
      if let date {
        updateSelectedMonth(Self.startOfMonth(for: date, calendar: calendar))
      }
    }
  }

  func toggleCalendarExpansion() {
    isCalendarExpanded.toggle()
  }

  func moveSelectedMonth(by value: Int) {
    guard value != 0 else {
      monthTransitionDirection = .none
      return
    }

    if let month = calendar.date(byAdding: .month, value: value, to: selectedMonth) {
      monthTransitionDirection = value > 0 ? .next : .previous
      selectedMonth = Self.startOfMonth(for: month, calendar: calendar)
    }
  }

  func dateHasEntries(_ date: Date) -> Bool {
    daysWithEntries.contains(calendar.startOfDay(for: date))
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

  private func updateSelectedMonth(_ month: Date) {
    if calendar.isDate(month, equalTo: selectedMonth, toGranularity: .month) {
      monthTransitionDirection = .none
    } else {
      monthTransitionDirection = month > selectedMonth ? .next : .previous
      selectedMonth = month
    }
  }

  private func userFacingErrorMessage(for error: any Error) -> String {
    if let repositoryError = error as? JournalRepositoryError {
      return repositoryError.localizedDescription
    }

    return "We could not load your Drifts."
  }

  private static func startOfMonth(for date: Date, calendar: Calendar) -> Date {
    let components = calendar.dateComponents([.year, .month], from: date)
    return calendar.date(from: components) ?? calendar.startOfDay(for: date)
  }

  private static func calendarIdentity(for date: Date, calendar: Calendar) -> String {
    let components = calendar.dateComponents([.year, .month], from: date)
    return "\(components.year ?? 0)-\(components.month ?? 0)"
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
