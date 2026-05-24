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
      "# Context Pack: \(contextPack.name)",
      "",
      contextPack.description.trimmedNonEmpty ?? "Curated context from Drift.",
      "",
      "Exported: \(dateTimeString(for: exportedAt))",
      "Visibility: \(contextPack.aiVisibility.displayName)",
      "",
      "Drifts are private by default. You choose what to share.",
      "",
    ]

    if !spaces.isEmpty {
      lines.append("## Spaces Included")
      lines.append("")
      for space in spaces {
        lines.append("- \(space.name)")
      }
      lines.append("")
    }

    if drifts.isEmpty {
      lines.append("## Recent Drifts")
      lines.append("")
      lines.append("No Drifts selected yet.")
    } else {
      let groupedDrifts = Dictionary(grouping: drifts, by: \.type)

      for type in DriftType.allCases where groupedDrifts[type]?.isEmpty == false {
        lines.append("## \(type.sectionTitle)")
        lines.append("")

        for drift in (groupedDrifts[type] ?? []).sorted(by: { $0.createdAt > $1.createdAt }) {
          lines.append(contentsOf: markdownLines(for: drift))
        }
      }

      lines.append("## Recent Drifts")
      lines.append("")

      for drift in drifts.sorted(by: { $0.createdAt > $1.createdAt }).prefix(8) {
        lines.append(
          "- \(drift.displayTitle): \(drift.previewText)"
        )
      }
    }

    return lines.joined(separator: "\n")
  }

  private func markdownLines(for drift: DriftItem) -> [String] {
    let body = drift.previewText
    var lines = [
      "- \(drift.displayTitle)",
      "  - Date: \(dateTimeString(for: drift.createdAt))",
      "  - Type: \(drift.type.displayName)",
      "  - Mood: \(drift.mood?.displayName ?? "Not set")",
      "  - Tags: \(drift.tags.isEmpty ? "None" : drift.tags.joined(separator: ", "))",
      "  - Body: \(body)",
    ]

    if !drift.attachments.isEmpty {
      lines.insert("  - Attachments: \(drift.attachments.count) local image(s)", at: 5)
    }

    lines.append("")
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

extension DriftType {
  fileprivate var sectionTitle: String {
    switch self {
    case .thought: "Thoughts"
    case .reflection: "Reflections"
    case .goal: "Goals"
    case .idea: "Ideas"
    case .memory: "Memories"
    case .mood: "Moods"
    case .decision: "Decisions"
    case .task: "Tasks"
    case .visual: "Visuals"
    case .context: "Context"
    }
  }
}
