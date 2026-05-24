//
//  GPTProposalServiceTests.swift
//  DriftTests
//
//  Created by Lucas Stuart West Rogers on 24/05/2026.
//

import Foundation
import Testing

@testable import Drift

struct GPTProposalServiceTests {
  @Test
  func creatingGPTProposalAddsPendingProposal() async throws {
    let harness = makeHarness()
    let space = DriftSpace(
      id: fixtureUUID("C5000000-0000-0000-0000-000000000001"),
      name: "Drift App",
      description: "Drift product context.",
      icon: AppIcons.sparkles
    )

    _ = try await harness.proposalService.createMockProposals(spaces: [space])
    let proposals = try await harness.proposalService.pendingProposals()

    #expect(proposals.count == 3)
    #expect(proposals.allSatisfy { $0.status == .pending })
    #expect(proposals.contains { $0.action == .createNewDrift })
  }

  @Test
  func acceptingCreateNewDriftProposalCreatesLocalDrift() async throws {
    let harness = makeHarness()
    let proposal = DriftProposal(
      id: fixtureUUID("C5000000-0000-0000-0000-000000000002"),
      createdAt: Date(timeIntervalSince1970: 1_779_000_000),
      action: .createNewDrift,
      title: "Drift as AI context board",
      body: "Drift can collect useful context from GPT conversations.",
      suggestedDriftType: .idea,
      suggestedTags: ["gpt"],
      summary: "Save the product idea."
    )

    try await harness.repository.saveProposal(proposal)
    let savedProposal = try await harness.proposalService.acceptProposal(proposal)
    let drifts = try await harness.driftRepository.fetchDrifts()

    #expect(savedProposal.status == .saved)
    #expect(drifts.contains { $0.id == proposal.id })
    #expect(drifts.first { $0.id == proposal.id }?.title == "Drift as AI context board")
  }

  @Test
  func rejectingProposalMarksRejected() async throws {
    let harness = makeHarness()
    let proposal = DriftProposal(
      id: fixtureUUID("C5000000-0000-0000-0000-000000000003"),
      action: .suggestSpace,
      title: "Backend Architecture",
      body: "Use Drift App for backend notes.",
      suggestedDriftType: .context,
      summary: "Suggest a Space."
    )

    try await harness.repository.saveProposal(proposal)
    let rejectedProposal = try await harness.proposalService.rejectProposal(proposal)
    let proposals = try await harness.proposalService.allProposals()

    #expect(rejectedProposal.status == .rejected)
    #expect(proposals.first { $0.id == proposal.id }?.status == .rejected)
  }

  @Test
  func disconnectingDoesNotDeleteLocalDrifts() async throws {
    let harness = makeHarness(
      entries: [
        JournalEntry(
          id: fixtureUUID("C5000000-0000-0000-0000-000000000004"),
          createdAt: Date(timeIntervalSince1970: 1_779_000_000),
          transcript: "Local Drift stays.",
          title: "Local Drift"
        )
      ]
    )

    _ = try await harness.connectionService.connect(method: .passkey)
    _ = try await harness.connectionService.disconnect()
    let drifts = try await harness.driftRepository.fetchDrifts()

    #expect(drifts.map(\.displayTitle) == ["Local Drift"])
  }

  private func makeHarness(entries: [JournalEntry] = []) -> GPTHarness {
    let suiteName = "DriftTests.GPTProposal.\(UUID().uuidString)"
    let userDefaults = UserDefaults(suiteName: suiteName) ?? .standard
    userDefaults.removePersistentDomain(forName: suiteName)
    let connectionService = LocalGPTConnectionService(userDefaults: userDefaults)
    let repository = LocalDriftProposalRepository(userDefaults: userDefaults)
    let driftRepository = JournalBackedDriftRepository(
      journalRepository: PreviewJournalRepository(entries: entries)
    )
    let proposalService = LocalGPTProposalService(
      proposalRepository: repository,
      driftRepository: driftRepository,
      connectionService: connectionService,
      now: { Date(timeIntervalSince1970: 1_779_000_000) }
    )
    return GPTHarness(
      connectionService: connectionService,
      repository: repository,
      proposalService: proposalService,
      driftRepository: driftRepository
    )
  }
}

private struct GPTHarness {
  let connectionService: LocalGPTConnectionService
  let repository: LocalDriftProposalRepository
  let proposalService: LocalGPTProposalService
  let driftRepository: JournalBackedDriftRepository
}
