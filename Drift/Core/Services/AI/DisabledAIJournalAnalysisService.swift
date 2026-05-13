//
//  DisabledAIJournalAnalysisService.swift
//  Drift
//
//  Created by Lucas Stuart West Rogers on 12/05/2026.
//

final class DisabledAIJournalAnalysisService: AIJournalAnalysisService, Sendable {
  func analyseEntry(transcript: String) async throws -> AIJournalAnalysis {
    throw DriftServiceError.unavailable("AI analysis is not active in the MVP.")
  }

  func generateWeeklySummary(entries: [JournalEntry]) async throws -> String {
    throw DriftServiceError.unavailable("AI summaries are not active in the MVP.")
  }

  func semanticSearch(query: String) async throws -> [JournalEntry] {
    throw DriftServiceError.unavailable("Semantic search is not active in the MVP.")
  }
}
