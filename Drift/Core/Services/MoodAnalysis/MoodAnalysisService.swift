//
//  MoodAnalysisService.swift
//  Drift
//
//  Created by Lucas Stuart West Rogers on 12/05/2026.
//

import Mockable

@Mockable
protocol MoodAnalysisService {
  func suggestMood(from transcript: String) async throws -> Mood
  func suggestThemes(from transcript: String) async throws -> [JournalTheme]
}
