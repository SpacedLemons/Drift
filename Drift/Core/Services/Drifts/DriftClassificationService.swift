//
//  DriftClassificationService.swift
//  Drift
//
//  Created by Lucas Stuart West Rogers on 23/05/2026.
//

import Mockable

@Mockable
protocol DriftClassificationService {
  func suggestType(for transcript: String) async throws -> DriftType
}

struct LocalDriftClassificationService: DriftClassificationService, Sendable {
  func suggestType(for transcript: String) async throws -> DriftType {
    .reflection
  }
}
