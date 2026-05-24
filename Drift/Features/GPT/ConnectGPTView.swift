//
//  ConnectGPTView.swift
//  Drift
//
//  Created by Lucas Stuart West Rogers on 24/05/2026.
//

import SwiftUI

struct ConnectGPTView: View {
  @Bindable var viewModel: GPTConnectionViewModel
  @Environment(\.dismiss) private var dismiss

  var body: some View {
    NavigationStack {
      ZStack {
        AppTheme.backgroundGradient
          .ignoresSafeArea()

        ScrollView {
          VStack(alignment: .leading, spacing: AppSpacing.l) {
            header
            options
            reassurance
          }
          .padding(AppSpacing.l)
        }
      }
      .navigationTitle("Connect to GPT")
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel") {
            viewModel.activeSheet = nil
            dismiss()
          }
        }
      }
    }
  }

  private var header: some View {
    VStack(alignment: .leading, spacing: AppSpacing.s) {
      Text("Use a secure native sign-in to connect Drift.")
        .font(AppTypography.screenTitle)
        .foregroundStyle(AppColors.textPrimary)
        .fixedSize(horizontal: false, vertical: true)

      Text(
        "This prototype uses local mock actions so the app can be tested before the real GPT/MCP backend exists."
      )
      .font(AppTypography.body)
      .foregroundStyle(AppColors.textSecondary)
      .fixedSize(horizontal: false, vertical: true)
    }
  }

  private var options: some View {
    VStack(spacing: AppSpacing.s) {
      Button {
        Task { await viewModel.connect(method: .passkey) }
      } label: {
        Label("Continue with Passkey", systemImage: AppIcons.personBadgeKey)
      }
      .buttonStyle(GPTPrimaryButtonStyle())

      Button {
        Task { await viewModel.connect(method: .apple) }
      } label: {
        Label("Continue with Apple", systemImage: "apple.logo")
      }
      .buttonStyle(GPTSecondaryButtonStyle())
    }
  }

  private var reassurance: some View {
    VStack(alignment: .leading, spacing: AppSpacing.m) {
      SettingsInfoCard(
        icon: AppIcons.lockShield,
        title: "Local Drift still works",
        message:
          "No email or password is needed for local Drift use. You can disconnect at any time."
      )

      SettingsInfoCard(
        icon: AppIcons.info,
        title: "Future implementation",
        message:
          "TODO: passkey registration, Apple sign-in fallback, OAuth for future MCP, and backend token exchange."
      )
    }
  }
}

#Preview {
  ConnectGPTView(
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
