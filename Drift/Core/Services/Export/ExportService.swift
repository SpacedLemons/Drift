//
//  ExportService.swift
//  Drift
//
//  Created by Lucas Stuart West Rogers on 13/05/2026.
//

import Foundation
import Mockable

@Mockable
protocol ExportService {
  func export(
    entries: [JournalEntry],
    exportedAt: Date
  ) async throws -> URL
}
