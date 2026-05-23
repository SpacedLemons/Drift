//
//  DriftSource.swift
//  Drift
//
//  Created by Lucas Stuart West Rogers on 23/05/2026.
//

enum DriftSource: String, CaseIterable, Identifiable, Codable, Hashable, Sendable {
  case voice
  case typed
  case imported
  case visual

  var id: String { rawValue }

  init(entrySource: EntrySource) {
    switch entrySource {
    case .voice: self = .voice
    case .typed: self = .typed
    case .imported: self = .imported
    }
  }

  var entrySource: EntrySource {
    switch self {
    case .voice: .voice
    case .typed: .typed
    case .imported: .imported
    case .visual: .typed
    }
  }
}
