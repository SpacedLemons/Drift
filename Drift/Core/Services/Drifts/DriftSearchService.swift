//
//  DriftSearchService.swift
//  Drift
//
//  Created by Lucas Stuart West Rogers on 23/05/2026.
//

import Mockable

@Mockable
protocol DriftSearchService {
  func searchDrifts(query: String) async throws -> [DriftItem]
}

struct LocalDriftSearchService: DriftSearchService, Sendable {
  private let driftRepository: any DriftRepository & Sendable

  init(driftRepository: any DriftRepository & Sendable) {
    self.driftRepository = driftRepository
  }

  func searchDrifts(query: String) async throws -> [DriftItem] {
    try await driftRepository.searchDrifts(query: query)
  }
}
