//
//  ManageGPTConnectionView.swift
//  Drift
//
//  Created by Lucas Stuart West Rogers on 24/05/2026.
//

import SwiftUI

struct ManageGPTConnectionView: View {
  @Bindable var viewModel: GPTConnectionViewModel
  @Environment(\.dismiss) private var dismiss
  @State private var isShowingDisconnectConfirmation = false

  var body: some View {
    NavigationStack {
      ZStack {
        AppTheme.backgroundGradient
          .ignoresSafeArea()

        ScrollView {
          VStack(alignment: .leading, spacing: AppSpacing.l) {
            statusSection
            capabilitiesSection
            preferencesSection
            spacesSection
            disconnectSection
          }
          .padding(AppSpacing.l)
        }
      }
      .navigationTitle("Manage GPT Connection")
      .toolbar {
        ToolbarItem(placement: .confirmationAction) {
          Button("Done") {
            viewModel.activeSheet = nil
            dismiss()
          }
        }
      }
      .confirmationDialog(
        "Disconnect GPT?",
        isPresented: $isShowingDisconnectConfirmation,
        titleVisibility: .visible
      ) {
        Button("Disconnect", role: .destructive) {
          Task {
            await viewModel.disconnect()
            dismiss()
          }
        }

        Button("Cancel", role: .cancel) {}
      } message: {
        Text("Disconnecting GPT does not delete local Drifts.")
      }
    }
  }

  private var statusSection: some View {
    SettingsSectionCard(title: "Connection") {
      SettingsRow(
        icon: AppIcons.link,
        title: "Connection status",
        subtitle: "Local mock connection. Real GPT/MCP connection will require passkeys/OAuth.",
        trailingValue: viewModel.snapshot.state == .connected ? "Connected" : "Not connected"
      )
    }
  }

  private var capabilitiesSection: some View {
    SettingsSectionCard(title: "Capabilities") {
      VStack(spacing: 0) {
        ForEach(viewModel.capabilities) { capability in
          SettingsRow(
            icon: capability.icon,
            title: capability.title,
            subtitle: "Enabled for reviewed GPT proposals.",
            trailingValue: "On"
          )

          if capability.id != viewModel.capabilities.last?.id {
            Divider().overlay(AppColors.border)
          }
        }
      }
    }
  }

  private var preferencesSection: some View {
    SettingsSectionCard(title: "Preferences") {
      VStack(spacing: 0) {
        SettingsToggleRow(
          icon: AppIcons.checkmarkCircle,
          title: "Require review before saving",
          subtitle: "GPT-created Drifts stay pending until you approve them.",
          isOn: Binding(
            get: { viewModel.snapshot.settings.requireReviewBeforeSaving },
            set: { isEnabled in
              Task { await viewModel.setRequireReviewBeforeSaving(isEnabled) }
            }
          )
        )

        Divider().overlay(AppColors.border)

        SettingsToggleRow(
          icon: AppIcons.wand,
          title: "Auto Drift conversations",
          subtitle:
            "When enabled in the future, GPT will be able to save useful conversation moments as Drift proposals automatically.",
          isOn: Binding(
            get: { viewModel.snapshot.settings.autoDriftConversations },
            set: { isEnabled in
              Task { await viewModel.setAutoDriftConversations(isEnabled) }
            }
          )
        )
        .disabled(true)
      }
    }
  }

  private var spacesSection: some View {
    SettingsSectionCard(title: "Spaces GPT can suggest/use") {
      if viewModel.spaces.isEmpty {
        SettingsRow(
          icon: AppIcons.spaces,
          title: "No Spaces yet",
          subtitle: "Create Spaces before choosing what GPT can suggest.",
          trailingValue: nil
        )
      } else {
        VStack(spacing: 0) {
          ForEach(viewModel.spaces) { space in
            SettingsToggleRow(
              icon: space.icon,
              title: space.name,
              subtitle: space.description,
              isOn: Binding(
                get: { viewModel.snapshot.settings.selectedSpaceIds.contains(space.id) },
                set: { _ in
                  Task { await viewModel.toggleSelectedSpace(space) }
                }
              )
            )

            if space.id != viewModel.spaces.last?.id {
              Divider().overlay(AppColors.border)
            }
          }
        }
      }
    }
  }

  private var disconnectSection: some View {
    SettingsSectionCard(title: "Disconnect") {
      SettingsDestructiveRow(
        icon: AppIcons.stop,
        title: "Disconnect GPT",
        subtitle: "Disconnecting GPT does not delete local Drifts.",
        action: {
          isShowingDisconnectConfirmation = true
        }
      )
    }
  }
}

#Preview {
  ManageGPTConnectionView(
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
