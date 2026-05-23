//
//  DriftCapturePipeline.swift
//  Drift
//
//  Created by Lucas Stuart West Rogers on 23/05/2026.
//

import Foundation
import Mockable

@Mockable
protocol DriftCapturePipeline {
  func proposeCapture(
    transcript: String,
    createdAt: Date,
    source: DriftSource
  ) async throws -> DriftCaptureProposal
}

struct LocalDriftCapturePipeline: DriftCapturePipeline, Sendable {
  private let classificationService: any DriftClassificationService & Sendable

  init(classificationService: any DriftClassificationService & Sendable) {
    self.classificationService = classificationService
  }

  func proposeCapture(
    transcript: String,
    createdAt: Date,
    source: DriftSource
  ) async throws -> DriftCaptureProposal {
    let suggestedType = try await classificationService.suggestType(for: transcript)
    return DriftCaptureProposal(
      createdAt: createdAt,
      body: transcript,
      suggestedType: suggestedType,
      source: source
    )
  }
}
