//
//  LocalMarkdownExportService.swift
//  Drift
//
//  Created by Lucas Stuart West Rogers on 13/05/2026.
//

import Foundation

actor LocalMarkdownExportService: ExportService {
  private let outputDirectory: URL
  private let calendar: Calendar
  private let locale: Locale
  private let timeZone: TimeZone

  init(
    outputDirectory: URL = FileManager.default.temporaryDirectory,
    calendar: Calendar = .current,
    locale: Locale = .current,
    timeZone: TimeZone = .current
  ) {
    self.outputDirectory = outputDirectory
    self.calendar = calendar
    self.locale = locale
    self.timeZone = timeZone
  }

  func export(
    entries: [JournalEntry],
    exportedAt: Date
  ) async throws -> URL {
    let markdown = makeMarkdown(entries: entries, exportedAt: exportedAt)
    let fileURL =
      outputDirectory
      .appendingPathComponent(fileName(for: exportedAt), isDirectory: false)

    do {
      try FileManager.default.createDirectory(
        at: outputDirectory,
        withIntermediateDirectories: true
      )
      try markdown.write(to: fileURL, atomically: true, encoding: .utf8)
      return fileURL
    } catch {
      throw ExportServiceError.writeFailed
    }
  }

  private func makeMarkdown(
    entries: [JournalEntry],
    exportedAt: Date
  ) -> String {
    var lines = [
      "# Drift Export",
      "",
      "Exported: \(dateTimeString(for: exportedAt))",
      "Entries: \(entries.count)",
      "",
      "Exports are created locally. You choose where to save or share them.",
      "",
    ]

    for entry in entries.sorted(by: { $0.createdAt > $1.createdAt }) {
      lines.append(contentsOf: markdownLines(for: entry))
    }

    return lines.joined(separator: "\n")
  }

  private func markdownLines(for entry: JournalEntry) -> [String] {
    var lines = [
      "## \(entry.displayTitle)",
      "Date: \(dateTimeString(for: entry.createdAt))",
      "Mood: \(entry.mood?.displayName ?? "Not set")",
      "Themes: \(joinedDisplayNames(themeNames(for: entry)))",
      "Tags: \(joinedDisplayNames(entry.tags))",
    ]

    if let duration = entry.duration {
      lines.append("Duration: \(durationString(for: duration))")
    }

    if entry.isFavorite {
      lines.append("Favorite: Yes")
    }

    if !entry.imageAttachments.isEmpty {
      lines.append("Images: \(entry.imageAttachments.count) stored locally with this entry")
    }

    lines.append("")
    lines.append(entry.transcript.trimmingCharacters(in: .whitespacesAndNewlines))
    lines.append("")

    return lines
  }

  private func joinedDisplayNames(_ values: [String]) -> String {
    values.isEmpty ? "None" : values.joined(separator: ", ")
  }

  private func themeNames(for entry: JournalEntry) -> [String] {
    entry.themes.map(\.displayName) + entry.customThemes.map(\.displayName)
  }

  private func dateTimeString(for date: Date) -> String {
    let formatter = DateFormatter()
    formatter.calendar = calendar
    formatter.locale = locale
    formatter.timeZone = timeZone
    formatter.dateFormat = "yyyy-MM-dd HH:mm"
    return formatter.string(from: date)
  }

  private func fileName(for exportedAt: Date) -> String {
    let formatter = DateFormatter()
    formatter.calendar = calendar
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.timeZone = timeZone
    formatter.dateFormat = "yyyy-MM-dd-HHmmss"
    return "drift-export-\(formatter.string(from: exportedAt)).md"
  }

  private func durationString(for duration: TimeInterval) -> String {
    let totalSeconds = max(Int(duration), 0)
    let minutes = totalSeconds / 60
    let seconds = totalSeconds % 60
    return "\(minutes)m \(seconds)s"
  }
}
