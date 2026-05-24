//
//  GPTConnectionViewModel.swift
//  Drift
//
//  Created by Lucas Stuart West Rogers on 24/05/2026.
//

import Foundation
import Observation

@MainActor
@Observable
final class GPTConnectionViewModel {
  @ObservationIgnored
  private let userIdentityService: any UserIdentityService & Sendable
  @ObservationIgnored
  private let gptConnectionService: any GPTConnectionService & Sendable
  @ObservationIgnored
  let gptProposalService: any GPTProposalService & Sendable
  @ObservationIgnored
  private let spaceRepository: any SpaceRepository & Sendable
  @ObservationIgnored
  private let now: () -> Date

  private(set) var snapshot: GPTConnectionSnapshot = .default
  private(set) var identityStatus: LocalIdentityStatus = .unknown
  private(set) var activityItems: [GPTActivityItem] = []
  private(set) var pendingProposals: [DriftProposal] = []
  private(set) var spaces: [DriftSpace] = []
  private(set) var isLoading = false
  private(set) var errorMessage: String?
  private(set) var statusMessage: String?
  var activeSheet: GPTConnectionSheet?
  var proposalPendingReview: DriftProposal?
  var proposalPendingRejection: DriftProposal?
  var isShowingDisconnectConfirmation = false

  init(
    userIdentityService: any UserIdentityService & Sendable,
    gptConnectionService: any GPTConnectionService & Sendable,
    gptProposalService: any GPTProposalService & Sendable,
    spaceRepository: any SpaceRepository & Sendable,
    now: @escaping () -> Date = Date.init
  ) {
    self.userIdentityService = userIdentityService
    self.gptConnectionService = gptConnectionService
    self.gptProposalService = gptProposalService
    self.spaceRepository = spaceRepository
    self.now = now
  }

  var isConnected: Bool {
    snapshot.state == .connected
  }

  var localIdentityValue: String {
    switch identityStatus {
    case .unknown: "Checking"
    case .ready: "Ready"
    case .unavailable: "Unavailable"
    }
  }

  var capabilities: [GPTCapability] {
    [
      GPTCapability(title: "Create Drifts", icon: AppIcons.wand),
      GPTCapability(title: "Update ongoing topics", icon: AppIcons.pencil),
      GPTCapability(title: "Suggest Spaces", icon: AppIcons.spaces),
      GPTCapability(title: "Review before saving", icon: AppIcons.checkmarkCircle),
    ]
  }

  func load() async {
    guard !isLoading else { return }

    isLoading = true
    errorMessage = nil
    loadIdentity()

    do {
      async let loadedSnapshot = gptConnectionService.loadConnection()
      async let loadedActivity = gptConnectionService.fetchActivity()
      async let loadedProposals = gptProposalService.pendingProposals()
      async let loadedSpaces = spaceRepository.fetchSpaces()
      snapshot = try await loadedSnapshot
      activityItems = try await loadedActivity
      pendingProposals = try await loadedProposals
      spaces = try await loadedSpaces
    } catch {
      errorMessage = "We could not load GPT yet."
    }

    isLoading = false
  }

  func showConnectFlow() {
    activeSheet = .connect
  }

  func connect(method: GPTConnectionMethod) async {
    do {
      snapshot = try await gptConnectionService.connect(method: method)
      activeSheet = nil
      statusMessage = "Connected to GPT in local mock mode."
      await refreshAfterMutation()
    } catch {
      errorMessage = "We could not connect to GPT locally."
    }
  }

  func showManageConnection() {
    activeSheet = .manage
  }

  func setAutoDriftConversations(_ isEnabled: Bool) async {
    var settings = snapshot.settings
    settings.autoDriftConversations = isEnabled
    await saveSettings(settings)
  }

  func setRequireReviewBeforeSaving(_ isEnabled: Bool) async {
    var settings = snapshot.settings
    settings.requireReviewBeforeSaving = isEnabled
    await saveSettings(settings)
  }

  func toggleSelectedSpace(_ space: DriftSpace) async {
    var settings = snapshot.settings
    if settings.selectedSpaceIds.contains(space.id) {
      settings.selectedSpaceIds.remove(space.id)
    } else {
      settings.selectedSpaceIds.insert(space.id)
    }
    await saveSettings(settings)
  }

  func disconnect() async {
    do {
      snapshot = try await gptConnectionService.disconnect()
      activeSheet = nil
      isShowingDisconnectConfirmation = false
      statusMessage = "Disconnected. Local Drifts stayed on this device."
      await refreshAfterMutation()
    } catch {
      errorMessage = "We could not disconnect GPT."
    }
  }

  func simulateGPTDrift() async {
    do {
      _ = try await gptProposalService.createMockProposals(spaces: spaces)
      statusMessage = "Mock GPT proposals created locally."
      await refreshAfterMutation()
    } catch {
      errorMessage = "We could not create mock GPT proposals."
    }
  }

  func accept(_ proposal: DriftProposal) async {
    do {
      _ = try await gptProposalService.acceptProposal(proposal)
      statusMessage = "GPT proposal saved locally."
      await refreshAfterMutation()
    } catch {
      errorMessage = "We could not save that GPT proposal."
    }
  }

  func reject(_ proposal: DriftProposal) async {
    do {
      _ = try await gptProposalService.rejectProposal(proposal)
      proposalPendingRejection = nil
      statusMessage = "GPT proposal rejected."
      await refreshAfterMutation()
    } catch {
      errorMessage = "We could not reject that GPT proposal."
    }
  }

  func refreshAfterMutation() async {
    do {
      async let loadedActivity = gptConnectionService.fetchActivity()
      async let loadedProposals = gptProposalService.pendingProposals()
      activityItems = try await loadedActivity
      pendingProposals = try await loadedProposals
    } catch {
      errorMessage = "We could not refresh GPT updates."
    }
  }

  private func saveSettings(_ settings: GPTConnectionSettings) async {
    do {
      snapshot = try await gptConnectionService.saveSettings(settings)
      statusMessage = "GPT connection preferences saved locally."
      errorMessage = nil
    } catch {
      errorMessage = "We could not save GPT connection preferences."
    }
  }

  private func loadIdentity() {
    do {
      let identity = try userIdentityService.currentIdentity()
      identityStatus = .ready(createdAt: identity.createdAt)
    } catch {
      identityStatus = .unavailable
    }
  }
}

struct GPTCapability: Identifiable, Equatable {
  let title: String
  let icon: String

  var id: String { title }
}

enum GPTConnectionSheet: Identifiable, Equatable {
  case connect
  case manage

  var id: String {
    switch self {
    case .connect: "connect"
    case .manage: "manage"
    }
  }
}
