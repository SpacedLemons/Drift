//
//  ExportShareItem.swift
//  Drift
//
//  Created by Lucas Stuart West Rogers on 13/05/2026.
//

import Foundation

struct ExportShareItem: Identifiable, Equatable, Sendable {
  let url: URL

  var id: URL { url }
}
