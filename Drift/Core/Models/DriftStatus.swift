//
//  DriftStatus.swift
//  Drift
//
//  Created by Lucas Stuart West Rogers on 23/05/2026.
//

enum DriftStatus: String, CaseIterable, Identifiable, Codable, Hashable, Sendable {
  case active
  case archived
  case completed

  var id: String { rawValue }

  var displayName: String {
    switch self {
    case .active: "Active"
    case .archived: "Archived"
    case .completed: "Completed"
    }
  }
}
