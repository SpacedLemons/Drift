//
//  AIJournalAnalysisService.swift
//  Drift
//
//  Created by Lucas Stuart West Rogers on 12/05/2026.
//

import Mockable

@Mockable
protocol AIJournalAnalysisService {
  func analyseEntry(transcript: String) async throws -> AIJournalAnalysis
  func generateWeeklySummary(entries: [JournalEntry]) async throws -> String
  func semanticSearch(query: String) async throws -> [JournalEntry]
}
