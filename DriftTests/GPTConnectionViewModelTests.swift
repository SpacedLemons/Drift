//
//  GPTConnectionViewModelTests.swift
//  DriftTests
//
//  Created by Lucas Stuart West Rogers on 24/05/2026.
//

import Foundation
import Testing

@testable import Drift

@MainActor
struct GPTConnectionViewModelTests {
  @Test
  func pendingProposalsAppearInGPTTabState() async throws {
    let harness = makeHarness()
    let space = DriftSpace(
      id: fixtureUUID("C6000000-0000-0000-0000-000000000001"),
      name: "Drift App",
      description: "Drift product context.",
      icon: AppIcons.sparkles
    )
    _ = try await harness.proposalService.createMockProposals(spaces: [space])
    let viewModel = harness.makeViewModel(spaces: [space])

    await viewModel.load()

    #expect(viewModel.pendingProposals.count == 3)
    #expect(viewModel.pendingProposals.contains { $0.title == "Drift as AI context board" })
  }

  @Test
  func localDriftIdentityIsReadyButNotAuth() async throws {
    let harness = makeHarness()
    let viewModel = harness.makeViewModel()

    await viewModel.load()

    #expect(viewModel.localIdentityValue == "Ready")
    #expect(viewModel.snapshot.state == .notConnected)
    #expect(!viewModel.localIdentityValue.contains("-"))
  }

  @Test
  func autoDriftModeDefaultsOff() async throws {
    let harness = makeHarness()
    let viewModel = harness.makeViewModel()

    await viewModel.load()

    #expect(!viewModel.snapshot.settings.autoDriftConversations)
    #expect(viewModel.snapshot.settings.requireReviewBeforeSaving)
  }

  private func makeHarness() -> GPTViewModelHarness {
    let suiteName = "DriftTests.GPTViewModel.\(UUID().uuidString)"
    let userDefaults = UserDefaults(suiteName: suiteName) ?? .standard
    userDefaults.removePersistentDomain(forName: suiteName)
    let connectionService = LocalGPTConnectionService(userDefaults: userDefaults)
    let repository = LocalDriftProposalRepository(userDefaults: userDefaults)
    let driftRepository = JournalBackedDriftRepository(
      journalRepository: PreviewJournalRepository(entries: [])
    )
    let proposalService = LocalGPTProposalService(
      proposalRepository: repository,
      driftRepository: driftRepository,
      connectionService: connectionService
    )
    return GPTViewModelHarness(
      connectionService: connectionService,
      proposalService: proposalService,
      driftRepository: driftRepository
    )
  }
}

private struct GPTViewModelHarness {
  let connectionService: LocalGPTConnectionService
  let proposalService: LocalGPTProposalService
  let driftRepository: JournalBackedDriftRepository

  @MainActor
  func makeViewModel(spaces: [DriftSpace] = []) -> GPTConnectionViewModel {
    GPTConnectionViewModel(
      userIdentityService: PreviewUserIdentityService(),
      gptConnectionService: connectionService,
      gptProposalService: proposalService,
      spaceRepository: LocalSpaceRepository(spaces: spaces)
    )
  }
}
