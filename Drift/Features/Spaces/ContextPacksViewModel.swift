//
//  ContextPacksViewModel.swift
//  Drift
//
//  Created by Lucas Stuart West Rogers on 23/05/2026.
//

import Foundation
import Observation

@MainActor
@Observable
final class ContextPacksViewModel {
  @ObservationIgnored
  private let driftRepository: any DriftRepository & Sendable
  @ObservationIgnored
  private let contextPackService: any ContextPackService & Sendable
  @ObservationIgnored
  private let contextExportService: any ContextExportService & Sendable
  @ObservationIgnored
  private let now: () -> Date

  private(set) var contextPacks: [ContextPack] = []
  private(set) var recentDrifts: [DriftItem] = []
  private(set) var isLoading = false
  private(set) var copiedMessage: String?
  private(set) var errorMessage: String?

  init(
    driftRepository: any DriftRepository & Sendable,
    contextPackService: any ContextPackService & Sendable,
    contextExportService: any ContextExportService & Sendable,
    now: @escaping () -> Date = Date.init
  ) {
    self.driftRepository = driftRepository
    self.contextPackService = contextPackService
    self.contextExportService = contextExportService
    self.now = now
  }

  var primaryPack: ContextPack {
    ContextPack(
      name: "Recent Drifts",
      description: "A local-only starter pack from your latest Drifts.",
      driftIds: recentDrifts.prefix(5).map(\.id),
      spaceIds: DriftSpace.placeholderSpaces.prefix(2).map(\.id),
      createdAt: now(),
      aiVisibility: .privateLocalOnly
    )
  }

  var selectedDrifts: [DriftItem] {
    let ids = Set(primaryPack.driftIds)
    return recentDrifts.filter { ids.contains($0.id) }
  }

  var selectedSpaces: [DriftSpace] {
    let ids = Set(primaryPack.spaceIds)
    return DriftSpace.placeholderSpaces.filter { ids.contains($0.id) }
  }

  func load() async {
    guard !isLoading else { return }

    isLoading = true
    errorMessage = nil
    copiedMessage = nil

    do {
      contextPacks = try await contextPackService.fetchContextPacks()
      recentDrifts = try await driftRepository.fetchDrifts()
    } catch {
      errorMessage = "We could not load Context Packs yet."
    }

    isLoading = false
  }

  func makeMarkdownForPrimaryPack() async -> String? {
    do {
      let markdown = try await contextExportService.markdown(
        for: primaryPack,
        drifts: selectedDrifts,
        spaces: selectedSpaces,
        exportedAt: now()
      )
      copiedMessage = "Context copied. Nothing was shared automatically."
      errorMessage = nil
      return markdown
    } catch {
      errorMessage = "We could not prepare that context."
      return nil
    }
  }
}
