//
//  SpacesViewModel.swift
//  Drift
//
//  Created by Lucas Stuart West Rogers on 23/05/2026.
//

import Foundation
import Observation

@MainActor
@Observable
final class SpacesViewModel {
  @ObservationIgnored
  private let spaceRepository: any SpaceRepository & Sendable
  @ObservationIgnored
  private let driftRepository: any DriftRepository & Sendable
  @ObservationIgnored
  private let contextPackService: any ContextPackService & Sendable
  @ObservationIgnored
  private let now: () -> Date

  private(set) var spaces: [DriftSpace] = []
  private(set) var drifts: [DriftItem] = []
  private(set) var isLoading = false
  private(set) var errorMessage: String?
  private(set) var statusMessage: String?

  init(
    spaceRepository: any SpaceRepository & Sendable = LocalSpaceRepository(),
    driftRepository: any DriftRepository & Sendable = JournalBackedDriftRepository(
      journalRepository: PreviewJournalRepository()
    ),
    contextPackService: any ContextPackService & Sendable = LocalContextPackService(),
    now: @escaping () -> Date = Date.init
  ) {
    self.spaceRepository = spaceRepository
    self.driftRepository = driftRepository
    self.contextPackService = contextPackService
    self.now = now
  }

  var summaries: [SpaceSummary] {
    spaces.map { space in
      SpaceSummary(
        space: space,
        driftCount: drifts.filter { $0.spaces.contains(space.id) }.count
      )
    }
  }

  func load() async {
    guard !isLoading else { return }

    isLoading = true
    errorMessage = nil

    do {
      async let loadedSpaces = spaceRepository.fetchSpaces()
      async let loadedDrifts = driftRepository.fetchDrifts()
      spaces = try await loadedSpaces
      drifts = try await loadedDrifts
    } catch {
      spaces = []
      drifts = []
      errorMessage = "We could not load Spaces."
    }

    isLoading = false
  }

  func clearMessages() {
    statusMessage = nil
    errorMessage = nil
  }

  func createSpace(from draft: SpaceEditorDraft) async -> Bool {
    let space = DriftSpace(
      name: draft.cleanedName,
      description: draft.cleanedDescription,
      icon: draft.icon,
      accentColorHex: draft.accentColorHex,
      createdAt: now(),
      isPinned: draft.isPinned
    )
    return await saveSpace(space)
  }

  func updateSpace(_ space: DriftSpace, from draft: SpaceEditorDraft) async -> Bool {
    var updatedSpace = space
    updatedSpace.name = draft.cleanedName
    updatedSpace.description = draft.cleanedDescription
    updatedSpace.icon = draft.icon
    updatedSpace.accentColorHex = draft.accentColorHex
    updatedSpace.isPinned = draft.isPinned
    updatedSpace.updatedAt = now()
    return await updateExistingSpace(updatedSpace)
  }

  func deleteSpace(_ space: DriftSpace) async -> Bool {
    do {
      let affectedDrifts = drifts.filter { $0.spaces.contains(space.id) }

      for drift in affectedDrifts {
        var updatedDrift = drift
        updatedDrift.spaces.removeAll { $0 == space.id }
        updatedDrift.updatedAt = now()
        try await driftRepository.updateDrift(updatedDrift)
      }

      try await spaceRepository.deleteSpace(id: space.id)
      statusMessage = "Space deleted. Drifts were kept."
      errorMessage = nil
      await load()
      return true
    } catch {
      statusMessage = nil
      errorMessage = "We could not delete that Space."
      return false
    }
  }

  func drifts(in space: DriftSpace) -> [DriftItem] {
    drifts
      .filter { $0.spaces.contains(space.id) }
      .sorted { $0.createdAt > $1.createdAt }
  }

  func availableDrifts(for space: DriftSpace) -> [DriftItem] {
    drifts
      .filter { !$0.spaces.contains(space.id) }
      .sorted { $0.createdAt > $1.createdAt }
  }

  func addDrift(_ drift: DriftItem, to space: DriftSpace) async -> Bool {
    guard !drift.spaces.contains(space.id) else { return true }

    var updatedDrift = drift
    updatedDrift.spaces.append(space.id)
    updatedDrift.updatedAt = now()
    return await updateDriftMembership(
      updatedDrift,
      successMessage: "Drift added to \(space.name)."
    )
  }

  func removeDrift(_ drift: DriftItem, from space: DriftSpace) async -> Bool {
    var updatedDrift = drift
    updatedDrift.spaces.removeAll { $0 == space.id }
    updatedDrift.updatedAt = now()
    return await updateDriftMembership(
      updatedDrift,
      successMessage: "Drift removed from \(space.name)."
    )
  }

  func createContextPack(from space: DriftSpace) async -> ContextPack? {
    let pack = ContextPack(
      name: "\(space.name) Context",
      description: "Curated context from the \(space.name) Space.",
      driftIds: drifts(in: space).map(\.id),
      spaceIds: [space.id],
      createdAt: now(),
      aiVisibility: .privateLocalOnly
    )

    do {
      try await contextPackService.saveContextPack(pack)
      statusMessage = "Context Pack created from \(space.name)."
      errorMessage = nil
      return pack
    } catch {
      statusMessage = nil
      errorMessage = "We could not create that Context Pack."
      return nil
    }
  }

  private func saveSpace(_ space: DriftSpace) async -> Bool {
    guard !space.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
      statusMessage = nil
      errorMessage = "Name this Space before saving."
      return false
    }

    do {
      try await spaceRepository.saveSpace(space)
      statusMessage = "Space saved."
      errorMessage = nil
      await load()
      return true
    } catch {
      statusMessage = nil
      errorMessage = "We could not save that Space."
      return false
    }
  }

  private func updateExistingSpace(_ space: DriftSpace) async -> Bool {
    guard !space.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
      statusMessage = nil
      errorMessage = "Name this Space before saving."
      return false
    }

    do {
      try await spaceRepository.updateSpace(space)
      statusMessage = "Space saved."
      errorMessage = nil
      await load()
      return true
    } catch {
      statusMessage = nil
      errorMessage = "We could not save that Space."
      return false
    }
  }

  private func updateDriftMembership(
    _ drift: DriftItem,
    successMessage: String
  ) async -> Bool {
    do {
      try await driftRepository.updateDrift(drift)
      statusMessage = successMessage
      errorMessage = nil
      await load()
      return true
    } catch {
      statusMessage = nil
      errorMessage = "We could not update that Drift."
      return false
    }
  }
}

struct SpaceSummary: Identifiable, Hashable {
  var space: DriftSpace
  var driftCount: Int

  var id: UUID { space.id }
}

struct SpaceEditorDraft: Identifiable, Equatable {
  var id = UUID()
  var name: String
  var description: String
  var icon: String
  var accentColorHex: String?
  var isPinned: Bool
  var editingSpace: DriftSpace?

  init(space: DriftSpace? = nil) {
    id = space?.id ?? UUID()
    name = space?.name ?? ""
    description = space?.description ?? ""
    icon = space?.icon ?? "square.grid.2x2"
    accentColorHex = space?.accentColorHex
    isPinned = space?.isPinned ?? false
    editingSpace = space
  }

  var cleanedName: String {
    name.trimmingCharacters(in: .whitespacesAndNewlines)
  }

  var cleanedDescription: String {
    description.trimmingCharacters(in: .whitespacesAndNewlines)
  }
}
