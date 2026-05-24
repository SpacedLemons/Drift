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
  private let spaceRepository: any SpaceRepository & Sendable
  @ObservationIgnored
  private let contextPackService: any ContextPackService & Sendable
  @ObservationIgnored
  private let contextExportService: any ContextExportService & Sendable
  @ObservationIgnored
  private let now: () -> Date
  @ObservationIgnored
  private var draftID: UUID
  @ObservationIgnored
  private var draftCreatedAt: Date

  private(set) var contextPacks: [ContextPack] = []
  private(set) var recentDrifts: [DriftItem] = []
  private(set) var spaces: [DriftSpace] = []
  private(set) var isLoading = false
  private(set) var copiedMessage: String?
  private(set) var errorMessage: String?

  var draftName = "OpenAI Application Context"
  var draftDescription = "Curated context from Drift."
  var selectedSpaceIds: Set<UUID> = []
  var selectedDriftIds: Set<UUID> = []

  init(
    driftRepository: any DriftRepository & Sendable,
    spaceRepository: any SpaceRepository & Sendable,
    contextPackService: any ContextPackService & Sendable,
    contextExportService: any ContextExportService & Sendable,
    now: @escaping () -> Date = Date.init
  ) {
    self.driftRepository = driftRepository
    self.spaceRepository = spaceRepository
    self.contextPackService = contextPackService
    self.contextExportService = contextExportService
    self.now = now
    draftID = UUID()
    draftCreatedAt = now()
  }

  var draftPack: ContextPack {
    ContextPack(
      id: draftID,
      name: draftName.trimmedNonEmpty ?? "Context Pack",
      description: draftDescription.trimmedNonEmpty ?? "Curated context from Drift.",
      driftIds: selectedDriftIds.sorted { $0.uuidString < $1.uuidString },
      spaceIds: selectedSpaceIds.sorted { $0.uuidString < $1.uuidString },
      createdAt: draftCreatedAt,
      updatedAt: now(),
      aiVisibility: .privateLocalOnly
    )
  }

  var draftDrifts: [DriftItem] {
    drifts(for: draftPack)
  }

  var draftSpaces: [DriftSpace] {
    spaces(for: draftPack)
  }

  func load() async {
    guard !isLoading else { return }

    isLoading = true
    errorMessage = nil

    do {
      async let loadedPacks = contextPackService.fetchContextPacks()
      async let loadedDrifts = driftRepository.fetchDrifts()
      async let loadedSpaces = spaceRepository.fetchSpaces()
      contextPacks = try await loadedPacks
      recentDrifts = try await loadedDrifts
      spaces = try await loadedSpaces
    } catch {
      contextPacks = []
      recentDrifts = []
      spaces = []
      errorMessage = "We could not load Context Packs yet."
    }

    isLoading = false
  }

  func toggleSpace(_ space: DriftSpace) {
    if selectedSpaceIds.contains(space.id) {
      selectedSpaceIds.remove(space.id)
    } else {
      selectedSpaceIds.insert(space.id)
    }
  }

  func toggleDrift(_ drift: DriftItem) {
    if selectedDriftIds.contains(drift.id) {
      selectedDriftIds.remove(drift.id)
    } else {
      selectedDriftIds.insert(drift.id)
    }
  }

  func saveDraftPack() async {
    do {
      try await contextPackService.saveContextPack(draftPack)
      copiedMessage = "Context Pack saved locally."
      errorMessage = nil
      await load()
    } catch {
      copiedMessage = nil
      errorMessage = "We could not save that Context Pack."
    }
  }

  func deletePack(_ pack: ContextPack) async {
    do {
      try await contextPackService.deleteContextPack(id: pack.id)
      copiedMessage = "Context Pack deleted."
      errorMessage = nil
      await load()
    } catch {
      copiedMessage = nil
      errorMessage = "We could not delete that Context Pack."
    }
  }

  func editPack(_ pack: ContextPack) {
    draftID = pack.id
    draftCreatedAt = pack.createdAt
    draftName = pack.name
    draftDescription = pack.description
    selectedSpaceIds = Set(pack.spaceIds)
    selectedDriftIds = Set(pack.driftIds)
    copiedMessage = "Editing Context Pack."
    errorMessage = nil
  }

  func startNewDraft() {
    draftID = UUID()
    draftCreatedAt = now()
    draftName = "Context Pack"
    draftDescription = "Curated context from Drift."
    selectedSpaceIds = []
    selectedDriftIds = []
    copiedMessage = "New Context Pack ready."
    errorMessage = nil
  }

  func copyMarkdown(for pack: ContextPack) async -> String? {
    do {
      let markdown = try await markdown(for: pack)
      copiedMessage = "Context copied. Nothing was shared automatically."
      errorMessage = nil
      return markdown
    } catch {
      errorMessage = "We could not prepare that context."
      return nil
    }
  }

  func shareMarkdown(for pack: ContextPack) async -> String? {
    do {
      let markdown = try await markdown(for: pack)
      copiedMessage = "Context prepared for sharing. Nothing was uploaded."
      errorMessage = nil
      return markdown
    } catch {
      errorMessage = "We could not prepare that context."
      return nil
    }
  }

  func markdownPreview() async -> String {
    (try? await markdown(for: draftPack)) ?? "Select Drifts or Spaces to preview local context."
  }

  func drifts(for pack: ContextPack) -> [DriftItem] {
    let selectedSpaceIds = Set(pack.spaceIds)
    let selectedDriftIds = Set(pack.driftIds)

    return
      recentDrifts
      .filter { drift in
        selectedDriftIds.contains(drift.id)
          || !selectedSpaceIds.isDisjoint(with: Set(drift.spaces))
      }
      .sorted { $0.createdAt > $1.createdAt }
  }

  func spaces(for pack: ContextPack) -> [DriftSpace] {
    let ids = Set(pack.spaceIds)
    return spaces.filter { ids.contains($0.id) }
  }

  private func markdown(for pack: ContextPack) async throws -> String {
    try await contextExportService.markdown(
      for: pack,
      drifts: drifts(for: pack),
      spaces: spaces(for: pack),
      exportedAt: now()
    )
  }
}

struct ContextSharePayload: Identifiable, Equatable {
  let id = UUID()
  let markdown: String
}
