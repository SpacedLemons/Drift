//
//  DriftRepository.swift
//  Drift
//
//  Created by Lucas Stuart West Rogers on 23/05/2026.
//

import Foundation
import Mockable

@Mockable
protocol DriftRepository {
  func fetchDrifts() async throws -> [DriftItem]
  func fetchDrift(id: UUID) async throws -> DriftItem?
  func saveDrift(_ drift: DriftItem) async throws
  func updateDrift(_ drift: DriftItem) async throws
  func deleteDrift(id: UUID) async throws
  func searchDrifts(query: String) async throws -> [DriftItem]
}
