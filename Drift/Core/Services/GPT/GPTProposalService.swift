//
//  GPTProposalService.swift
//  Drift
//
//  Created by Lucas Stuart West Rogers on 24/05/2026.
//

import Foundation
import Mockable

@Mockable
protocol DriftProposalRepository {
  func fetchProposals() async throws -> [DriftProposal]
  func saveProposal(_ proposal: DriftProposal) async throws
  func updateProposal(_ proposal: DriftProposal) async throws
}

@Mockable
protocol GPTProposalService {
  func pendingProposals() async throws -> [DriftProposal]
  func allProposals() async throws -> [DriftProposal]
  func createMockProposals(spaces: [DriftSpace]) async throws -> [DriftProposal]
  func acceptProposal(_ proposal: DriftProposal) async throws -> DriftProposal
  func rejectProposal(_ proposal: DriftProposal) async throws -> DriftProposal
}

enum DriftProposalServiceError: LocalizedError, Equatable {
  case loadFailed
  case saveFailed
  case unsupportedAction

  var errorDescription: String? {
    switch self {
    case .loadFailed: "We could not load GPT proposals."
    case .saveFailed: "We could not save that GPT proposal."
    case .unsupportedAction: "That GPT proposal cannot be saved yet."
    }
  }
}

actor LocalDriftProposalRepository: DriftProposalRepository {
  private let userDefaults: UserDefaults
  private let proposalsKey: String

  init(
    userDefaults: UserDefaults = .standard,
    proposalsKey: String = "drift.gpt.proposals"
  ) {
    self.userDefaults = userDefaults
    self.proposalsKey = proposalsKey
  }

  func fetchProposals() async throws -> [DriftProposal] {
    guard let data = userDefaults.data(forKey: proposalsKey) else {
      return []
    }

    do {
      return try JSONDecoder().decode([DriftProposal].self, from: data)
        .sorted { $0.createdAt > $1.createdAt }
    } catch {
      throw DriftProposalServiceError.loadFailed
    }
  }

  func saveProposal(_ proposal: DriftProposal) async throws {
    var proposals = try await fetchProposals()
    proposals.removeAll { $0.id == proposal.id }
    proposals.append(proposal)
    try persist(proposals)
  }

  func updateProposal(_ proposal: DriftProposal) async throws {
    try await saveProposal(proposal)
  }

  private func persist(_ proposals: [DriftProposal]) throws {
    do {
      let data = try JSONEncoder().encode(proposals.sorted { $0.createdAt > $1.createdAt })
      userDefaults.set(data, forKey: proposalsKey)
    } catch {
      throw DriftProposalServiceError.saveFailed
    }
  }
}

actor LocalGPTProposalService: GPTProposalService {
  private let proposalRepository: any DriftProposalRepository & Sendable
  private let driftRepository: any DriftRepository & Sendable
  private let connectionService: any GPTConnectionService & Sendable
  private let now: @Sendable () -> Date

  init(
    proposalRepository: any DriftProposalRepository & Sendable,
    driftRepository: any DriftRepository & Sendable,
    connectionService: any GPTConnectionService & Sendable,
    now: @escaping @Sendable () -> Date = Date.init
  ) {
    self.proposalRepository = proposalRepository
    self.driftRepository = driftRepository
    self.connectionService = connectionService
    self.now = now
  }

  func pendingProposals() async throws -> [DriftProposal] {
    try await allProposals().filter { $0.status == .pending || $0.status == .edited }
  }

  func allProposals() async throws -> [DriftProposal] {
    try await proposalRepository.fetchProposals()
  }

  func createMockProposals(spaces: [DriftSpace]) async throws -> [DriftProposal] {
    let driftAppSpace = spaces.first { $0.name == "Drift App" } ?? spaces.first
    let openAICareerSpace = spaces.first { $0.name == "OpenAI Career" } ?? driftAppSpace
    let createdAt = now()
    let proposals = [
      DriftProposal(
        createdAt: createdAt,
        action: .createNewDrift,
        title: "Drift as AI context board",
        body:
          "Drift can become a personal context board where GPT suggests useful Drifts from natural conversations.",
        suggestedDriftType: .idea,
        suggestedSpaceIds: driftAppSpace.map { [$0.id] } ?? [],
        suggestedTags: ["product", "gpt"],
        suggestedMood: .reflective,
        targetSpaceId: driftAppSpace?.id,
        confidence: 0.84,
        summary: "Save the product idea that Drift can act as an AI context board."
      ),
      DriftProposal(
        createdAt: createdAt.addingTimeInterval(-90),
        action: .updateExistingDrift,
        title: "OpenAI Career",
        body: "MCPKit could become a standout project.",
        suggestedDriftType: .goal,
        suggestedSpaceIds: openAICareerSpace.map { [$0.id] } ?? [],
        suggestedTags: ["career", "mcp"],
        targetSpaceId: openAICareerSpace?.id,
        confidence: 0.76,
        summary: "Append a new note to the OpenAI Career topic."
      ),
      DriftProposal(
        createdAt: createdAt.addingTimeInterval(-180),
        action: .suggestSpace,
        title: "Backend Architecture",
        body: "Create or use a backend architecture Space for GPT/MCP implementation details.",
        suggestedDriftType: .context,
        suggestedSpaceIds: driftAppSpace.map { [$0.id] } ?? [],
        suggestedTags: ["backend", "architecture"],
        targetSpaceId: driftAppSpace?.id,
        confidence: 0.7,
        summary: "Suggest grouping backend architecture notes inside Drift App."
      ),
    ]

    for proposal in proposals {
      try await proposalRepository.saveProposal(proposal)
      try await connectionService.appendActivity(
        GPTActivityItem(
          createdAt: proposal.createdAt,
          kind: .createdProposal,
          title: proposal.title,
          subtitle: proposal.action.displayName,
          status: .pending
        )
      )
    }

    return proposals
  }

  func acceptProposal(_ proposal: DriftProposal) async throws -> DriftProposal {
    var updatedProposal = proposal
    updatedProposal.updatedAt = now()

    switch proposal.action {
    case .createNewDrift:
      let drift = DriftItem(
        id: proposal.id,
        createdAt: proposal.createdAt,
        updatedAt: updatedProposal.updatedAt,
        title: proposal.title,
        body: proposal.body,
        type: proposal.suggestedDriftType,
        mood: proposal.suggestedMood,
        tags: proposal.suggestedTags,
        spaces: proposal.suggestedSpaceIds,
        source: .typed,
        aiVisibility: .privateLocalOnly
      )
      try await driftRepository.saveDrift(drift)
      updatedProposal.status = .saved
    case .updateExistingDrift:
      if let targetDriftId = proposal.targetDriftId,
        var existingDrift = try await driftRepository.fetchDrift(id: targetDriftId)
      {
        existingDrift.body += "\n\n\(proposal.body)"
        existingDrift.updatedAt = updatedProposal.updatedAt
        try await driftRepository.updateDrift(existingDrift)
        updatedProposal.status = .saved
      } else {
        // TODO: Future MCP/backend events should carry stable target Drift IDs for updates.
        updatedProposal.status = .accepted
      }
    case .appendToSpace, .suggestSpace, .createContextPack:
      // TODO: Wire these proposal actions into Space and Context Pack services once MCP events exist.
      updatedProposal.status = .accepted
    }

    try await proposalRepository.updateProposal(updatedProposal)
    try await connectionService.appendActivity(
      GPTActivityItem(
        createdAt: updatedProposal.updatedAt,
        kind: .acceptedProposal,
        title: updatedProposal.title,
        subtitle: updatedProposal.action.displayName
      )
    )
    return updatedProposal
  }

  func rejectProposal(_ proposal: DriftProposal) async throws -> DriftProposal {
    var updatedProposal = proposal
    updatedProposal.status = .rejected
    updatedProposal.updatedAt = now()
    try await proposalRepository.updateProposal(updatedProposal)
    try await connectionService.appendActivity(
      GPTActivityItem(
        createdAt: updatedProposal.updatedAt,
        kind: .rejectedProposal,
        title: updatedProposal.title,
        subtitle: updatedProposal.action.displayName
      )
    )
    return updatedProposal
  }
}
