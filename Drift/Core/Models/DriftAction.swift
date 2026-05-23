//
//  DriftAction.swift
//  Drift
//
//  Created by Lucas Stuart West Rogers on 23/05/2026.
//

enum DriftAction: String, CaseIterable, Identifiable, Codable, Hashable, Sendable {
  case capture
  case review
  case save
  case link
  case archive
  case exportContext

  var id: String { rawValue }

  var displayName: String {
    switch self {
    case .capture: "Capture"
    case .review: "Review"
    case .save: "Save"
    case .link: "Link"
    case .archive: "Archive"
    case .exportContext: "Export Context"
    }
  }
}
