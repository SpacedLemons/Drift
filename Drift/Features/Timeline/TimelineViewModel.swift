//
//  TimelineViewModel.swift
//  Drift
//
//  Created by Lucas Stuart West Rogers on 23/05/2026.
//

import Foundation
import Observation

enum CalendarMonthTransitionDirection: Equatable {
  case none
  case previous
  case next
}

@MainActor
@Observable
final class TimelineViewModel {
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

  var selectedDate: Date?
  var selectedMonth: Date
  var selectedDriftTypeFilter: DriftType?
  var isCalendarExpanded = true
  private(set) var monthTransitionDirection: CalendarMonthTransitionDirection = .none

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
      .filter(matchesSelectedDriftType)
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
      CalendarDayState.empty(id: "timeline-\(monthID)-leading-\(index)")
    }

    days += monthRange.compactMap { day -> CalendarDayState? in
      guard let date = calendar.date(byAdding: .day, value: day - 1, to: firstDayOfMonth) else {
        return nil
      }

      return CalendarDayState(
        id: "timeline-\(monthID)-day-\(day)",
        date: date,
        dayNumber: day,
        hasEntries: dateHasEntries(date),
        isSelected: selectedDate.map { calendar.isDate($0, inSameDayAs: date) } ?? false,
        isToday: calendar.isDateInToday(date)
      )
    }

    let trailingBlankCount = (7 - (days.count % 7)) % 7
    days += (0..<trailingBlankCount).map { index in
      CalendarDayState.empty(id: "timeline-\(monthID)-trailing-\(index)")
    }

    return days
  }

  func load() async {
    guard !isLoading else { return }

    isLoading = true
    errorMessage = nil

    do {
      entries = try await journalRepository.fetchEntries()
      entryDaysWithEntries = Set(entries.map { calendar.startOfDay(for: $0.createdAt) })
    } catch {
      entries = []
      entryDaysWithEntries = []
      errorMessage = "We could not load your Timeline."
    }

    isLoading = false
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

  func selectDriftTypeFilter(_ driftType: DriftType?) {
    selectedDriftTypeFilter = driftType
  }

  func dateHasEntries(_ date: Date) -> Bool {
    entryDaysWithEntries.contains(calendar.startOfDay(for: date))
  }

  private func matchesSelectedDate(_ entry: JournalEntry) -> Bool {
    guard let selectedDate else { return true }
    return calendar.isDate(entry.createdAt, inSameDayAs: selectedDate)
  }

  private func matchesSelectedDriftType(_ entry: JournalEntry) -> Bool {
    guard let selectedDriftTypeFilter else { return true }
    return entry.driftType == selectedDriftTypeFilter
  }

  private func updateSelectedMonth(_ month: Date) {
    if calendar.isDate(month, equalTo: selectedMonth, toGranularity: .month) {
      monthTransitionDirection = .none
      selectedMonth = month
      return
    }

    monthTransitionDirection = month > selectedMonth ? .next : .previous
    selectedMonth = month
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
