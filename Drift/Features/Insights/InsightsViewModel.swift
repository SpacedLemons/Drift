//
//  InsightsViewModel.swift
//  Drift
//
//  Created by Lucas Stuart West Rogers on 12/05/2026.
//

import Foundation
import Observation

@MainActor
@Observable
final class InsightsViewModel {
  @ObservationIgnored
  private let journalRepository: any JournalRepository
  @ObservationIgnored
  private let calendar: Calendar
  @ObservationIgnored
  private let now: () -> Date

  private(set) var entries: [JournalEntry] = []
  private(set) var summary = InsightsSummary.empty
  private(set) var isLoading = false
  private(set) var errorMessage: String?
  var selectedMoodTrendRange: MoodTrendRange = .last7Days

  init(
    journalRepository: any JournalRepository,
    calendar: Calendar = .current,
    now: @escaping () -> Date = Date.init
  ) {
    self.journalRepository = journalRepository
    self.calendar = calendar
    self.now = now
  }

  func load() async {
    isLoading = true
    errorMessage = nil

    do {
      entries = try await journalRepository.fetchEntries()
        .filter(Self.isMoodHistoryEligible)
      summary = calculateSummary(from: entries)
    } catch {
      entries = []
      summary = .empty
      errorMessage = "We could not load mood history right now."
    }

    isLoading = false
  }

  func calculateSummary(from entries: [JournalEntry]) -> InsightsSummary {
    Self.calculateSummary(
      from: entries,
      range: selectedMoodTrendRange,
      calendar: calendar,
      now: now()
    )
  }

  func selectMoodTrendRange(_ range: MoodTrendRange) {
    selectedMoodTrendRange = range
    summary = calculateSummary(from: entries)
  }

  static func isMoodHistoryEligible(_ entry: JournalEntry) -> Bool {
    if entry.mood != nil {
      return true
    }

    if entry.driftType == .mood {
      return true
    }

    return entry.driftType == .reflection && entry.hasJournalStyleMetadata
  }

  static func calculateSummary(
    from entries: [JournalEntry],
    range: MoodTrendRange,
    calendar: Calendar,
    now: Date
  ) -> InsightsSummary {
    let sortedEntries = entries.sorted { $0.createdAt > $1.createdAt }

    return InsightsSummary(
      totalEntries: entries.count,
      entriesThisWeek: entriesThisWeek(entries, calendar: calendar, now: now),
      currentStreak: currentStreak(entries, calendar: calendar, now: now),
      mostCommonMood: mostCommonMood(entries),
      mostCommonThemeName: mostCommonThemeName(entries),
      moodTrend: moodTrend(sortedEntries, range: range, calendar: calendar, now: now),
      recentThemeNames: recentThemeNames(sortedEntries)
    )
  }

  private static func entriesThisWeek(
    _ entries: [JournalEntry],
    calendar: Calendar,
    now: Date
  ) -> Int {
    guard let week = calendar.dateInterval(of: .weekOfYear, for: now) else { return 0 }
    return entries.filter { week.contains($0.createdAt) }.count
  }

  private static func currentStreak(
    _ entries: [JournalEntry],
    calendar: Calendar,
    now: Date
  ) -> Int {
    let entryDays = Set(entries.map { calendar.startOfDay(for: $0.createdAt) })
    var day = calendar.startOfDay(for: now)
    var streak = 0

    while entryDays.contains(day) {
      streak += 1
      guard let previousDay = calendar.date(byAdding: .day, value: -1, to: day) else { break }
      day = previousDay
    }

    return streak
  }

  private static func mostCommonMood(_ entries: [JournalEntry]) -> Mood? {
    let moods = entries.compactMap(\.mood)
    return mostCommonValue(moods)
  }

  private static func mostCommonThemeName(_ entries: [JournalEntry]) -> String? {
    let themes = entries.flatMap { entry in
      entry.themes.map(\.displayName) + entry.customThemes.map(\.displayName)
    }
    return mostCommonValue(themes)
  }

  private static func moodTrend(
    _ entries: [JournalEntry],
    range: MoodTrendRange,
    calendar: Calendar,
    now: Date
  ) -> [MoodTrendPoint] {
    let startDate = range.startDate(now: now, calendar: calendar)
    let groupedScores = Dictionary(grouping: entries) { entry in
      calendar.startOfDay(for: entry.createdAt)
    }

    return
      groupedScores
      .compactMap { day, dayEntries -> MoodTrendPoint? in
        guard day >= startDate else { return nil }
        let scores = dayEntries.compactMap { $0.mood?.trendScore }
        guard !scores.isEmpty else { return nil }

        let score = scores.reduce(0, +) / Double(scores.count)
        return MoodTrendPoint(date: day, score: score)
      }
      .sorted { $0.date < $1.date }
  }

  private static func recentThemeNames(_ entries: [JournalEntry]) -> [String] {
    var themes: [String] = []

    for theme in entries.flatMap({ entry in
      entry.themes.map(\.displayName) + entry.customThemes.map(\.displayName)
    }) where !themes.contains(theme) {
      themes.append(theme)
      if themes.count == 6 { break }
    }

    return themes
  }

  private static func mostCommonValue<Value: Hashable>(_ values: [Value]) -> Value? {
    let counts = Dictionary(grouping: values, by: { $0 }).mapValues(\.count)
    return counts.max { lhs, rhs in lhs.value < rhs.value }?.key
  }
}

extension JournalEntry {
  fileprivate var hasJournalStyleMetadata: Bool {
    source == .voice || duration != nil || !themes.isEmpty || !customThemes.isEmpty
  }
}

struct InsightsSummary: Hashable {
  var totalEntries: Int
  var entriesThisWeek: Int
  var currentStreak: Int
  var mostCommonMood: Mood?
  var mostCommonThemeName: String?
  var moodTrend: [MoodTrendPoint]
  var recentThemeNames: [String]

  static let empty = InsightsSummary(
    totalEntries: 0,
    entriesThisWeek: 0,
    currentStreak: 0,
    mostCommonMood: nil,
    mostCommonThemeName: nil,
    moodTrend: [],
    recentThemeNames: []
  )
}

struct MoodTrendPoint: Identifiable, Hashable {
  var date: Date
  var score: Double

  var id: Date { date }
}

enum MoodTrendRange: String, CaseIterable, Identifiable, Hashable {
  case last7Days
  case last30Days
  case thisMonth

  var id: String { rawValue }

  var title: String {
    switch self {
    case .last7Days: "7D"
    case .last30Days: "30D"
    case .thisMonth: "Month"
    }
  }

  func startDate(now: Date, calendar: Calendar) -> Date {
    switch self {
    case .last7Days:
      return calendar.date(byAdding: .day, value: -6, to: calendar.startOfDay(for: now))
        ?? calendar.startOfDay(for: now)
    case .last30Days:
      return calendar.date(byAdding: .day, value: -29, to: calendar.startOfDay(for: now))
        ?? calendar.startOfDay(for: now)
    case .thisMonth:
      let components = calendar.dateComponents([.year, .month], from: now)
      return calendar.date(from: components) ?? calendar.startOfDay(for: now)
    }
  }
}
