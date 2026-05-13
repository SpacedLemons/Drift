//
//  ExportServiceTests.swift
//  DriftTests
//
//  Created by Lucas Stuart West Rogers on 13/05/2026.
//

import Foundation
import Testing

@testable import Drift

struct ExportServiceTests {
  @Test
  func exportsEntriesAsMarkdownNewestFirst() async throws {
    let outputDirectory = FileManager.default.temporaryDirectory
      .appendingPathComponent("drift.export.tests.\(UUID().uuidString)", isDirectory: true)
    defer { try? FileManager.default.removeItem(at: outputDirectory) }

    let service = LocalMarkdownExportService(
      outputDirectory: outputDirectory,
      calendar: Calendar(identifier: .gregorian),
      locale: Locale(identifier: "en_GB"),
      timeZone: TimeZone(identifier: "UTC") ?? .current
    )
    let olderEntry = makeEntry(
      title: "Older thought",
      createdAt: date(year: 2026, month: 5, day: 12, hour: 8, minute: 15),
      transcript: "An older note."
    )
    let newerEntry = makeEntry(
      title: "Focused morning",
      createdAt: date(year: 2026, month: 5, day: 13, hour: 6, minute: 38),
      transcript: "I felt focused today."
    )

    let fileURL = try await service.export(
      entries: [olderEntry, newerEntry],
      exportedAt: date(year: 2026, month: 5, day: 13, hour: 10, minute: 0)
    )
    let markdown = try String(contentsOf: fileURL, encoding: .utf8)

    #expect(fileURL.lastPathComponent == "drift-export-2026-05-13-100000.md")
    #expect(markdown.contains("# Drift Export"))
    #expect(markdown.contains("Exported: 2026-05-13 10:00"))
    #expect(markdown.contains("Entries: 2"))
    #expect(
      markdown.contains("Exports are created locally. You choose where to save or share them."))
    #expect(markdown.contains("## Focused morning"))
    #expect(markdown.contains("Date: 2026-05-13 06:38"))
    #expect(markdown.contains("Mood: Positive"))
    #expect(markdown.contains("Themes: Productivity, Work"))
    #expect(markdown.contains("Tags: focus"))
    #expect(markdown.contains("Duration: 1m 12s"))
    #expect(markdown.contains("Favorite: Yes"))
    #expect(markdown.contains("I felt focused today."))

    let newerEntryRange = markdown.range(of: "## Focused morning")
    let olderEntryRange = markdown.range(of: "## Older thought")
    #expect(newerEntryRange != nil)
    #expect(olderEntryRange != nil)

    if let newerEntryRange, let olderEntryRange {
      #expect(newerEntryRange.lowerBound < olderEntryRange.lowerBound)
    }
  }

  @Test
  func exportsEmptyEntriesAsReadableMarkdown() async throws {
    let outputDirectory = FileManager.default.temporaryDirectory
      .appendingPathComponent("drift.export.empty.tests.\(UUID().uuidString)", isDirectory: true)
    defer { try? FileManager.default.removeItem(at: outputDirectory) }

    let service = LocalMarkdownExportService(
      outputDirectory: outputDirectory,
      calendar: Calendar(identifier: .gregorian),
      locale: Locale(identifier: "en_GB"),
      timeZone: TimeZone(identifier: "UTC") ?? .current
    )

    let fileURL = try await service.export(
      entries: [],
      exportedAt: date(year: 2026, month: 5, day: 13, hour: 10, minute: 0)
    )
    let markdown = try String(contentsOf: fileURL, encoding: .utf8)

    #expect(fileURL.lastPathComponent == "drift-export-2026-05-13-100000.md")
    #expect(markdown.contains("# Drift Export"))
    #expect(markdown.contains("Entries: 0"))
    #expect(
      markdown.contains("Exports are created locally. You choose where to save or share them."))
  }

  private func makeEntry(
    title: String,
    createdAt: Date,
    transcript: String
  ) -> JournalEntry {
    JournalEntry(
      id: UUID(),
      createdAt: createdAt,
      transcript: transcript,
      title: title,
      mood: .positive,
      themes: [.productivity, .work],
      tags: ["focus"],
      duration: 72,
      source: .voice,
      isFavorite: true
    )
  }
}

private func date(
  year: Int,
  month: Int,
  day: Int,
  hour: Int,
  minute: Int
) -> Date {
  var calendar = Calendar(identifier: .gregorian)
  calendar.timeZone = TimeZone(identifier: "UTC") ?? .current

  return calendar.date(
    from: DateComponents(
      year: year,
      month: month,
      day: day,
      hour: hour,
      minute: minute
    )
  ) ?? Date(timeIntervalSince1970: 0)
}
