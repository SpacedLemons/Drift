//
//  EntrySource.swift
//  Drift
//
//  Created by Lucas Stuart West Rogers on 12/05/2026.
//

enum EntrySource: String, CaseIterable, Identifiable, Codable, Hashable, Sendable {
  case voice
  case typed
  case imported

  var id: String { rawValue }
}
