//
//  GPTConnectionView.swift
//  Drift
//
//  Created by Lucas Stuart West Rogers on 24/05/2026.
//

import SwiftUI

struct GPTConnectionView: View {
  @State private var viewModel: GPTConnectionViewModel

  init(viewModel: GPTConnectionViewModel) {
    _viewModel = State(initialValue: viewModel)
  }

  var body: some View {
    @Bindable var bindableViewModel = viewModel

    ZStack {
      AppTheme.backgroundGradient
        .ignoresSafeArea()

      ScrollView {
        VStack(alignment: .leading, spacing: AppSpacing.l) {
          header

          if viewModel.isConnected {
            connectedContent
          } else {
            notConnectedContent
          }

          pendingUpdatesSection
          messages
        }
        .padding(AppSpacing.l)
      }
    }
    .navigationTitle("GPT")
    .task {
      await viewModel.load()
    }
    .fullScreenCover(item: $bindableViewModel.activeSheet) { sheet in
      switch sheet {
      case .connect:
        ConnectGPTView(viewModel: viewModel)
      case .manage:
        ManageGPTConnectionView(viewModel: viewModel)
      }
    }
    .sheet(item: $bindableViewModel.proposalPendingReview) { proposal in
      NavigationStack {
        ReviewGPTProposalView(
          viewModel: ReviewGPTProposalViewModel(
            proposal: proposal,
            proposalService: viewModel.gptProposalService
          ),
          spaces: viewModel.spaces,
          onFinished: {
            Task { await viewModel.refreshAfterMutation() }
          }
        )
      }
    }
    .confirmationDialog(
      "Reject this GPT update?",
      isPresented: Binding(
        get: { viewModel.proposalPendingRejection != nil },
        set: { if !$0 { viewModel.proposalPendingRejection = nil } }
      ),
      titleVisibility: .visible
    ) {
      Button("Reject", role: .destructive) {
        guard let proposal = viewModel.proposalPendingRejection else { return }
        Task { await viewModel.reject(proposal) }
      }

      Button("Cancel", role: .cancel) {
        viewModel.proposalPendingRejection = nil
      }
    } message: {
      Text("Rejected proposals stay out of your local Drifts.")
    }
  }

  private var header: some View {
    VStack(alignment: .leading, spacing: AppSpacing.s) {
      Text(
        viewModel.isConnected
          ? "Connected and ready to help."
          : "Connect Drift to GPT for seamless thought capture and updates."
      )
      .font(AppTypography.body)
      .foregroundStyle(AppColors.textSecondary)
      .fixedSize(horizontal: false, vertical: true)
    }
  }

  private var notConnectedContent: some View {
    VStack(alignment: .leading, spacing: AppSpacing.m) {
      GPTCard {
        VStack(alignment: .leading, spacing: AppSpacing.m) {
          SettingsIcon(symbol: AppIcons.sparkles)

          Text("GPT can create Drifts, continue ongoing topics, and keep your thoughts organised.")
            .font(AppTypography.screenTitle)
            .foregroundStyle(AppColors.textPrimary)
            .fixedSize(horizontal: false, vertical: true)

          Button {
            viewModel.showConnectFlow()
          } label: {
            Label("Connect to GPT", systemImage: AppIcons.link)
          }
          .buttonStyle(GPTPrimaryButtonStyle())
        }
      }

      HStack(spacing: AppSpacing.s) {
        GPTStatusCard(
          icon: AppIcons.lockShield,
          title: "Private by default",
          value: "Drift only shares what you allow.",
          accent: AppColors.accentSecondary
        )
        GPTStatusCard(
          icon: AppIcons.link,
          title: "Connection",
          value: "Not connected"
        )
      }

      GPTStatusCard(
        icon: AppIcons.lockShield,
        title: "Local Drift identity",
        value: viewModel.localIdentityValue,
        accent: AppColors.accentSecondary
      )
    }
  }

  private var connectedContent: some View {
    VStack(alignment: .leading, spacing: AppSpacing.l) {
      GPTCard {
        VStack(alignment: .leading, spacing: AppSpacing.m) {
          Label("Connected to GPT", systemImage: AppIcons.success)
            .font(AppTypography.screenTitle)
            .foregroundStyle(AppColors.textPrimary)

          Text("Secure connection active")
            .font(AppTypography.body)
            .foregroundStyle(AppColors.textSecondary)

          Text(
            "Local mock mode. Future GPT connection requires passkeys/OAuth and backend token exchange."
          )
          .font(AppTypography.caption)
          .foregroundStyle(AppColors.textTertiary)
          .fixedSize(horizontal: false, vertical: true)
        }
      }

      VStack(alignment: .leading, spacing: AppSpacing.s) {
        SectionTitle("What GPT can do")

        GPTCard {
          VStack(spacing: 0) {
            ForEach(viewModel.capabilities) { capability in
              CapabilityRow(capability: capability)

              if capability.id != viewModel.capabilities.last?.id {
                Divider().overlay(AppColors.border)
              }
            }
          }
        }
      }

      recentActivitySection

      HStack(spacing: AppSpacing.s) {
        Button {
          viewModel.showManageConnection()
        } label: {
          Label("Manage connection", systemImage: AppIcons.settings)
        }
        .buttonStyle(GPTSecondaryButtonStyle())

        Button(role: .destructive) {
          viewModel.isShowingDisconnectConfirmation = true
        } label: {
          Label("Disconnect", systemImage: AppIcons.stop)
        }
        .buttonStyle(GPTDestructiveButtonStyle())
      }

      #if DEBUG
        Button {
          Task { await viewModel.simulateGPTDrift() }
        } label: {
          Label("Simulate GPT Drift", systemImage: AppIcons.wand)
        }
        .buttonStyle(GPTPrimaryButtonStyle())
        .accessibilityHint("Creates local mock GPT proposals for testing.")
      #endif
    }
    .confirmationDialog(
      "Disconnect GPT?",
      isPresented: Binding(
        get: { viewModel.isShowingDisconnectConfirmation },
        set: { viewModel.isShowingDisconnectConfirmation = $0 }
      ),
      titleVisibility: .visible
    ) {
      Button("Disconnect", role: .destructive) {
        Task { await viewModel.disconnect() }
      }

      Button("Cancel", role: .cancel) {
        viewModel.isShowingDisconnectConfirmation = false
      }
    } message: {
      Text("Disconnecting GPT does not delete local Drifts.")
    }
  }

  private var recentActivitySection: some View {
    VStack(alignment: .leading, spacing: AppSpacing.s) {
      SectionTitle("Recent activity")

      GPTCard {
        if viewModel.activityItems.isEmpty {
          Text("Recent GPT activity appears here after proposals are created or reviewed.")
            .font(AppTypography.body)
            .foregroundStyle(AppColors.textSecondary)
            .fixedSize(horizontal: false, vertical: true)
            .padding(AppSpacing.m)
        } else {
          VStack(spacing: 0) {
            ForEach(viewModel.activityItems.prefix(5)) { item in
              ActivityRow(item: item)

              if item.id != viewModel.activityItems.prefix(5).last?.id {
                Divider().overlay(AppColors.border)
              }
            }
          }
        }
      }
    }
  }

  private var pendingUpdatesSection: some View {
    VStack(alignment: .leading, spacing: AppSpacing.s) {
      SectionTitle("Pending GPT Updates")

      if viewModel.pendingProposals.isEmpty {
        GPTCard {
          VStack(alignment: .leading, spacing: AppSpacing.s) {
            Label("No pending updates.", systemImage: AppIcons.tray)
              .font(AppTypography.cardTitle)
              .foregroundStyle(AppColors.textPrimary)

            Text("When GPT suggests a new Drift or update, it will appear here for review.")
              .font(AppTypography.body)
              .foregroundStyle(AppColors.textSecondary)
              .fixedSize(horizontal: false, vertical: true)
          }
          .padding(AppSpacing.m)
        }
      } else {
        VStack(spacing: AppSpacing.s) {
          ForEach(viewModel.pendingProposals) { proposal in
            ProposalCard(
              proposal: proposal,
              spaceName: viewModel.spaceName(for: proposal),
              onReview: {
                viewModel.proposalPendingReview = proposal
              },
              onAccept: {
                Task { await viewModel.accept(proposal) }
              },
              onReject: {
                viewModel.proposalPendingRejection = proposal
              }
            )
          }
        }
      }
    }
  }

  @ViewBuilder
  private var messages: some View {
    if let statusMessage = viewModel.statusMessage {
      Text(statusMessage)
        .font(AppTypography.caption)
        .foregroundStyle(AppColors.accentSecondary)
    }

    if let errorMessage = viewModel.errorMessage {
      Text(errorMessage)
        .font(AppTypography.caption)
        .foregroundStyle(AppColors.warmAccent)
    }
  }
}

extension GPTConnectionViewModel {
  fileprivate func spaceName(for proposal: DriftProposal) -> String {
    guard let spaceID = proposal.suggestedSpaceIds.first ?? proposal.targetSpaceId,
      let space = spaces.first(where: { $0.id == spaceID })
    else {
      return "No Space selected"
    }

    return space.name
  }
}

private struct GPTCard<Content: View>: View {
  @ViewBuilder let content: () -> Content

  var body: some View {
    content()
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(AppSpacing.m)
      .background(
        AppColors.surface.opacity(0.86),
        in: RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius)
      )
      .overlay {
        RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius)
          .stroke(AppColors.border, lineWidth: 1)
      }
  }
}

private struct SectionTitle: View {
  let title: String

  init(_ title: String) {
    self.title = title
  }

  var body: some View {
    Text(title)
      .font(AppTypography.screenTitle)
      .foregroundStyle(AppColors.textPrimary)
  }
}

private struct GPTStatusCard: View {
  let icon: String
  let title: String
  let value: String
  var accent: Color = AppColors.accent

  var body: some View {
    VStack(alignment: .leading, spacing: AppSpacing.s) {
      SettingsIcon(symbol: icon, tint: accent)

      Text(title)
        .font(AppTypography.caption)
        .foregroundStyle(AppColors.textTertiary)

      Text(value)
        .font(AppTypography.bodyEmphasis)
        .foregroundStyle(AppColors.textPrimary)
        .fixedSize(horizontal: false, vertical: true)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(AppSpacing.m)
    .background(
      AppColors.surface.opacity(0.86),
      in: RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius)
    )
    .overlay {
      RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius)
        .stroke(AppColors.border, lineWidth: 1)
    }
  }
}

private struct CapabilityRow: View {
  let capability: GPTCapability

  var body: some View {
    HStack(spacing: AppSpacing.m) {
      SettingsIcon(symbol: capability.icon)

      Text(capability.title)
        .font(AppTypography.bodyEmphasis)
        .foregroundStyle(AppColors.textPrimary)

      Spacer()

      Image(systemName: AppIcons.checkmarkCircle)
        .foregroundStyle(AppColors.accentSecondary)
    }
    .padding(AppSpacing.m)
  }
}

private struct ActivityRow: View {
  let item: GPTActivityItem

  var body: some View {
    HStack(spacing: AppSpacing.m) {
      SettingsIcon(symbol: item.kind.icon)

      VStack(alignment: .leading, spacing: AppSpacing.xs) {
        Text("\(item.kind.displayName) · \(item.title)")
          .font(AppTypography.bodyEmphasis)
          .foregroundStyle(AppColors.textPrimary)

        Text(item.subtitle)
          .font(AppTypography.caption)
          .foregroundStyle(AppColors.textSecondary)
      }

      Spacer()
    }
    .padding(AppSpacing.m)
  }
}

private struct ProposalCard: View {
  let proposal: DriftProposal
  let spaceName: String
  let onReview: () -> Void
  let onAccept: () -> Void
  let onReject: () -> Void

  var body: some View {
    GPTCard {
      VStack(alignment: .leading, spacing: AppSpacing.m) {
        HStack(alignment: .top, spacing: AppSpacing.m) {
          SettingsIcon(symbol: proposal.action.icon)

          VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text(proposal.title)
              .font(AppTypography.cardTitle)
              .foregroundStyle(AppColors.textPrimary)

            Text(proposal.action.displayName)
              .font(AppTypography.caption)
              .foregroundStyle(AppColors.accent)
          }

          Spacer()

          Text(proposal.status.displayName)
            .font(AppTypography.caption)
            .foregroundStyle(AppColors.textTertiary)
        }

        Text(proposal.summary)
          .font(AppTypography.body)
          .foregroundStyle(AppColors.textSecondary)
          .fixedSize(horizontal: false, vertical: true)

        Text("Suggested Space: \(spaceName)")
          .font(AppTypography.caption)
          .foregroundStyle(AppColors.textTertiary)

        Text("Created: \(proposal.createdAt.formatted(date: .abbreviated, time: .shortened))")
          .font(AppTypography.caption)
          .foregroundStyle(AppColors.textTertiary)

        HStack(spacing: AppSpacing.s) {
          Button(action: onReview) {
            Label("Review", systemImage: AppIcons.rectangleAndPencil)
          }
          .buttonStyle(GPTSecondaryButtonStyle())

          Button("Accept", action: onAccept)
            .buttonStyle(GPTPrimaryButtonStyle())

          Button("Reject", role: .destructive, action: onReject)
            .buttonStyle(GPTDestructiveButtonStyle())
        }
      }
    }
  }
}

extension GPTActivityKind {
  fileprivate var icon: String {
    switch self {
    case .createdDrift: AppIcons.wand
    case .updatedDrift: AppIcons.pencil
    case .suggestedSpace: AppIcons.spaces
    case .createdProposal: AppIcons.sparkles
    case .acceptedProposal: AppIcons.checkmarkCircle
    case .rejectedProposal: AppIcons.xmark
    }
  }
}

extension DriftProposalAction {
  fileprivate var icon: String {
    switch self {
    case .createNewDrift: AppIcons.wand
    case .updateExistingDrift: AppIcons.pencil
    case .appendToSpace: AppIcons.spaces
    case .suggestSpace: AppIcons.spaces
    case .createContextPack: AppIcons.contextPack
    }
  }
}

struct GPTPrimaryButtonStyle: ButtonStyle {
  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .font(AppTypography.bodyEmphasis)
      .foregroundStyle(AppColors.background)
      .lineLimit(1)
      .minimumScaleFactor(0.8)
      .padding(.vertical, AppSpacing.s)
      .padding(.horizontal, AppSpacing.m)
      .frame(maxWidth: .infinity)
      .background(
        AppColors.accent,
        in: RoundedRectangle(cornerRadius: AppTheme.controlCornerRadius)
      )
      .opacity(configuration.isPressed ? 0.72 : 1)
  }
}

struct GPTSecondaryButtonStyle: ButtonStyle {
  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .font(AppTypography.bodyEmphasis)
      .foregroundStyle(AppColors.textPrimary)
      .lineLimit(1)
      .minimumScaleFactor(0.78)
      .padding(.vertical, AppSpacing.s)
      .padding(.horizontal, AppSpacing.m)
      .frame(maxWidth: .infinity)
      .background(
        AppColors.surfaceRaised,
        in: RoundedRectangle(cornerRadius: AppTheme.controlCornerRadius)
      )
      .overlay {
        RoundedRectangle(cornerRadius: AppTheme.controlCornerRadius)
          .stroke(AppColors.border, lineWidth: 1)
      }
      .opacity(configuration.isPressed ? 0.72 : 1)
  }
}

struct GPTDestructiveButtonStyle: ButtonStyle {
  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .font(AppTypography.bodyEmphasis)
      .foregroundStyle(AppColors.warmAccent)
      .lineLimit(1)
      .minimumScaleFactor(0.78)
      .padding(.vertical, AppSpacing.s)
      .padding(.horizontal, AppSpacing.m)
      .frame(maxWidth: .infinity)
      .background(
        AppColors.warmAccent.opacity(0.12),
        in: RoundedRectangle(cornerRadius: AppTheme.controlCornerRadius)
      )
      .overlay {
        RoundedRectangle(cornerRadius: AppTheme.controlCornerRadius)
          .stroke(AppColors.warmAccent.opacity(0.22), lineWidth: 1)
      }
      .opacity(configuration.isPressed ? 0.72 : 1)
  }
}

#Preview {
  NavigationStack {
    GPTConnectionView(
      viewModel: GPTConnectionViewModel(
        userIdentityService: PreviewUserIdentityService(),
        gptConnectionService: LocalGPTConnectionService(),
        gptProposalService: LocalGPTProposalService(
          proposalRepository: LocalDriftProposalRepository(),
          driftRepository: JournalBackedDriftRepository(
            journalRepository: PreviewJournalRepository()),
          connectionService: LocalGPTConnectionService()
        ),
        spaceRepository: LocalSpaceRepository()
      )
    )
  }
}
