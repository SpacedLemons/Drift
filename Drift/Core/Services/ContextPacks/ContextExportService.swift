//
//  ContextExportService.swift
//  Drift
//
//  Created by Lucas Stuart West Rogers on 23/05/2026.
//

import Foundation
import Mockable

@Mockable
protocol ContextExportService {
  func markdown(
    for contextPack: ContextPack,
    drifts: [DriftItem],
    spaces: [DriftSpace],
    exportedAt: Date
  ) async throws -> String
}

struct LocalContextExportService: ContextExportService, Sendable {
  private let calendar: Calendar
  private let locale: Locale
  private let timeZone: TimeZone

  init(
    calendar: Calendar = .current,
    locale: Locale = .current,
    timeZone: TimeZone = .current
  ) {
    self.calendar = calendar
    self.locale = locale
    self.timeZone = timeZone
  }

  func markdown(
    for contextPack: ContextPack,
    drifts: [DriftItem],
    spaces: [DriftSpace],
    exportedAt: Date
  ) async throws -> String {
    var lines = [
      "# \(contextPack.name)",
      "",
      contextPack.description,
      "",
      "Exported: \(dateTimeString(for: exportedAt))",
      "Visibility: \(contextPack.aiVisibility.displayName)",
      "",
      "Drifts are private by default. You choose what to share with AI.",
      "",
    ]

    if !spaces.isEmpty {
      lines.append("## Spaces")
      lines.append("")
      for space in spaces {
        lines.append("- \(space.name): \(space.description)")
      }
      lines.append("")
    }

    lines.append("## Drifts")
    lines.append("")

    if drifts.isEmpty {
      lines.append("No Drifts selected yet.")
    } else {
      for drift in drifts.sorted(by: { $0.createdAt > $1.createdAt }) {
        lines.append(contentsOf: markdownLines(for: drift))
      }
    }

    return lines.joined(separator: "\n")
  }

  private func markdownLines(for drift: DriftItem) -> [String] {
    var lines = [
      "### \(drift.title?.trimmingCharacters(in: .whitespacesAndNewlines).nonEmpty ?? drift.type.displayName)",
      "Type: \(drift.type.displayName)",
      "Date: \(dateTimeString(for: drift.createdAt))",
      "Mood: \(drift.mood?.displayName ?? "Not set")",
      "Tags: \(drift.tags.isEmpty ? "None" : drift.tags.joined(separator: ", "))",
      "",
      drift.body.trimmingCharacters(in: .whitespacesAndNewlines),
      "",
    ]

    if !drift.attachments.isEmpty {
      lines.insert("Attachments: \(drift.attachments.count) local image(s)", at: 5)
    }

    return lines
  }

  private func dateTimeString(for date: Date) -> String {
    let formatter = DateFormatter()
    formatter.calendar = calendar
    formatter.locale = locale
    formatter.timeZone = timeZone
    formatter.dateFormat = "yyyy-MM-dd HH:mm"
    return formatter.string(from: date)
  }
}

extension String {
  fileprivate var nonEmpty: String? {
    isEmpty ? nil : self
  }
}
