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
  private let calendar: Calendar
  @ObservationIgnored
  private let now: () -> Date
  @ObservationIgnored
  private var entryDaysWithEntries: Set<Date> = []

  private(set) var entries: [JournalEntry] = []
  private(set) var isLoading = false
  private(set) var errorMessage: String?

  var searchQuery = ""
  var selectedDate: Date?
  var selectedMonth: Date
  var isCalendarExpanded = false

  var shouldShowFirstRunIntro: Bool {
    !isLoading && errorMessage == nil && entries.isEmpty
  }

  init(
    journalRepository: any JournalRepository,
    calendar: Calendar = .current,
    now: @escaping () -> Date = Date.init
  ) {
    self.journalRepository = journalRepository
    self.calendar = calendar
    self.now = now
    selectedMonth = Self.startOfMonth(for: now(), calendar: calendar)
  }

  var visibleEntries: [JournalEntry] {
    entries
      .filter(matchesSelectedDate)
      .filter(matchesSearch)
      .sorted { $0.createdAt > $1.createdAt }
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

  var weekdaySymbols: [String] {
    guard
      let firstDayOfMonth = calendar.date(
        from: calendar.dateComponents([.year, .month], from: selectedMonth))
    else {
      return []
    }

    let symbols = calendar.veryShortStandaloneWeekdaySymbols
    let firstIndex = max(calendar.component(.weekday, from: firstDayOfMonth) - 1, 0)
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

    var days = monthRange.compactMap { day -> CalendarDayState? in
      guard let date = calendar.date(byAdding: .day, value: day - 1, to: firstDayOfMonth) else {
        return nil
      }

      return CalendarDayState(
        id: "day-\(day)",
        date: date,
        dayNumber: day,
        hasEntries: hasEntry(on: date),
        isSelected: selectedDate.map { calendar.isDate($0, inSameDayAs: date) } ?? false,
        isToday: calendar.isDateInToday(date)
      )
    }

    let trailingBlankCount = (7 - (days.count % 7)) % 7
    days += (0..<trailingBlankCount).map { index in
      CalendarDayState.empty(id: "trailing-\(index)")
    }

    return days
  }

  var selectedDateHasNoEntries: Bool {
    guard let selectedDate else { return false }
    return !hasEntry(on: selectedDate)
  }

  func load() async {
    guard !isLoading else { return }

    isLoading = true
    errorMessage = nil

    do {
      entries = try await journalRepository.fetchEntries()
      updateEntryDayCache()
    } catch {
      errorMessage = userFacingErrorMessage(for: error)
      entries = []
      updateEntryDayCache()
    }

    isLoading = false
  }

  func applySearchQuery(_ query: String) {
    searchQuery = query
  }

  func selectDate(_ date: Date?) {
    if let date, selectedDate.map({ calendar.isDate($0, inSameDayAs: date) }) == true {
      selectedDate = nil
    } else {
      selectedDate = date
      if let date {
        selectedMonth = Self.startOfMonth(for: date, calendar: calendar)
      }
    }
  }

  func toggleCalendarExpansion() {
    isCalendarExpanded.toggle()
  }

  func moveSelectedMonth(by value: Int) {
    if let month = calendar.date(byAdding: .month, value: value, to: selectedMonth) {
      selectedMonth = Self.startOfMonth(for: month, calendar: calendar)
    }
  }

  func entry(id: UUID) -> JournalEntry? {
    entries.first { $0.id == id }
  }

  private func matchesSelectedDate(_ entry: JournalEntry) -> Bool {
    guard let selectedDate else { return true }
    return calendar.isDate(entry.createdAt, inSameDayAs: selectedDate)
  }

  private func matchesSearch(_ entry: JournalEntry) -> Bool {
    let query = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !query.isEmpty else { return true }

    let searchableText = [
      entry.title ?? "",
      entry.transcript,
      entry.mood?.displayName ?? "",
      entry.driftType.displayName,
      entry.themes.map(\.displayName).joined(separator: " "),
      entry.customThemes.map(\.displayName).joined(separator: " "),
      entry.tags.joined(separator: " "),
    ]
    .joined(separator: " ")
    .lowercased()

    return searchableText.contains(query.lowercased())
  }

  private func userFacingErrorMessage(for error: any Error) -> String {
    if let repositoryError = error as? JournalRepositoryError {
      return repositoryError.localizedDescription
    }

    return "We could not load your Drifts."
  }

  private func hasEntry(on date: Date) -> Bool {
    entryDaysWithEntries.contains(calendar.startOfDay(for: date))
  }

  private func updateEntryDayCache() {
    entryDaysWithEntries = Set(entries.map { calendar.startOfDay(for: $0.createdAt) })
  }

  private static func startOfMonth(for date: Date, calendar: Calendar) -> Date {
    let components = calendar.dateComponents([.year, .month], from: date)
    return calendar.date(from: components) ?? calendar.startOfDay(for: date)
  }
}

struct CalendarDayState: Identifiable, Equatable {
  let id: String
  let date: Date?
  let dayNumber: Int?
  let hasEntries: Bool
  let isSelected: Bool
  let isToday: Bool

  static func empty(id: String) -> CalendarDayState {
    CalendarDayState(
      id: id,
      date: nil,
      dayNumber: nil,
      hasEntries: false,
      isSelected: false,
      isToday: false
    )
  }
}
