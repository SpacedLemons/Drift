//
//  SettingsView.swift
//  Drift
//
//  Created by Lucas Stuart West Rogers on 12/05/2026.
//

import SwiftUI
import UIKit

struct SettingsView: View {
  @State private var viewModel: SettingsViewModel
  let coordinator: SettingsCoordinator
  let onShowPaywall: () -> Void
  let onEntriesDeleted: () -> Void

  @State private var isShowingDeleteAllConfirmation = false
  #if DEBUG
    @State private var isShowingResetIdentityConfirmation = false
  #endif

  init(
    viewModel: SettingsViewModel,
    coordinator: SettingsCoordinator,
    onShowPaywall: @escaping () -> Void = {},
    onEntriesDeleted: @escaping () -> Void
  ) {
    _viewModel = State(initialValue: viewModel)
    self.coordinator = coordinator
    self.onShowPaywall = onShowPaywall
    self.onEntriesDeleted = onEntriesDeleted
  }

  var body: some View {
    @Bindable var bindableViewModel = viewModel

    ZStack {
      AppTheme.backgroundGradient
        .ignoresSafeArea()

      ScrollView {
        VStack(alignment: .leading, spacing: AppSpacing.l) {
          header
          settingsSections

          if let errorMessage = viewModel.errorMessage {
            Text(errorMessage)
              .font(AppTypography.body)
              .foregroundStyle(AppColors.warmAccent)
          }
        }
        .padding(AppSpacing.l)
      }
    }
    .navigationTitle("Settings")
    .alert(
      "Delete all Drifts?",
      isPresented: $isShowingDeleteAllConfirmation
    ) {
      Button(role: .destructive) {
        deleteAllEntries()
      } label: {
        Text("Delete All Drifts")
      }

      Button(role: .cancel) {
      } label: {
        Text("Cancel")
      }
    } message: {
      Text("This will remove your Drifts from this device.")
    }
    #if DEBUG
      .alert(
        "Reset local identity?",
        isPresented: $isShowingResetIdentityConfirmation
      ) {
        Button(role: .destructive) {
          viewModel.resetLocalIdentityForDebugOnly()
        } label: {
          Text("Reset Identity")
        }

        Button(role: .cancel) {
        } label: {
          Text("Cancel")
        }
      } message: {
        Text("This replaces the hidden local install ID. It is for debug use only.")
      }
    #endif
    .sheet(item: $bindableViewModel.exportShareItem) { exportItem in
      ActivityView(activityItems: [exportItem.url])
    }
    .task {
      await viewModel.load()
    }
  }

  private var header: some View {
    VStack(alignment: .leading, spacing: AppSpacing.s) {
      Text("Local preferences for reminders, appearance, privacy, and data.")
        .font(AppTypography.body)
        .foregroundStyle(AppColors.textSecondary)
        .fixedSize(horizontal: false, vertical: true)
    }
  }

  private var settingsSections: some View {
    VStack(alignment: .leading, spacing: AppSpacing.l) {
      SettingsSectionCard(title: "Drift Plus") {
        SettingsNavigationRow(
          icon: AppIcons.sparkles,
          title: viewModel.entitlement.isPremium ? "Drift Plus active" : "Upgrade to Drift Plus",
          subtitle: "Existing Drifts always stay yours.",
          trailingValue: viewModel.entitlement.tier.displayName,
          action: onShowPaywall
        )
      }

      SettingsSectionCard(title: "Account / Connection") {
        SettingsRow(
          icon: AppIcons.lockShield,
          title: viewModel.localIdentityTitle,
          subtitle: viewModel.localIdentitySubtitle,
          trailingValue: viewModel.localIdentityTrailingValue
        )

        Divider().overlay(AppColors.border)

        settingsNavigationRow(
          for: .chatGPTConnection,
          action: coordinator.showChatGPTConnection
        )
      }

      SettingsSectionCard(title: "Reminders") {
        settingsNavigationRow(for: .reminders, action: coordinator.showReminders)
      }

      SettingsSectionCard(title: "Voice & Transcription") {
        settingsNavigationRow(for: .voiceTranscription, action: coordinator.showVoiceTranscription)
      }

      SettingsSectionCard(title: "Appearance") {
        settingsNavigationRow(for: .appearance, action: coordinator.showAppearance)
      }

      SettingsSectionCard(title: "Backup & Restore") {
        settingsNavigationRow(for: .backupRestore, action: coordinator.showBackupRestore)
      }

      SettingsSectionCard(title: "Data") {
        SettingsNavigationRow(
          icon: AppIcons.share,
          title: viewModel.isExportingEntries ? "Preparing Export" : "Export All Drifts",
          subtitle: viewModel.exportPrivacyMessage,
          action: exportAllEntries
        )
        .disabled(viewModel.isExportingEntries)
        .accessibilityLabel("Export all Drifts")
        .accessibilityHint("Creates a local Markdown file and opens sharing options.")

        Divider().overlay(AppColors.border)

        SettingsDestructiveRow(
          icon: AppIcons.trash,
          title: viewModel.isDeletingAllEntries ? "Deleting Drifts" : "Delete All Drifts",
          subtitle: "Remove Drifts from this device.",
          action: showDeleteAllConfirmation
        )
        .disabled(viewModel.isDeletingAllEntries)
        .accessibilityLabel("Delete all Drifts")
      }

      SettingsSectionCard(title: "Privacy") {
        settingsNavigationRow(for: .privacy, action: coordinator.showPrivacy)
          .accessibilityLabel("Privacy settings")
      }

      SettingsSectionCard(title: "About") {
        settingsNavigationRow(for: .about, action: coordinator.showAbout)
          .accessibilityLabel("About Drift")
      }

      #if DEBUG
        developerSettingsSection
      #endif
    }
  }

  private func settingsNavigationRow(
    for route: SettingsRoute,
    action: @escaping () -> Void
  ) -> some View {
    let row = viewModel.navigationRow(for: route)

    return SettingsNavigationRow(
      icon: row.icon,
      title: row.title,
      subtitle: row.subtitle,
      trailingValue: row.trailingValue,
      action: action
    )
  }

  #if DEBUG
    private var developerSettingsSection: some View {
      SettingsSectionCard(title: "Developer Settings") {
        VStack(alignment: .leading, spacing: AppSpacing.s) {
          HStack(spacing: AppSpacing.m) {
            SettingsIcon(symbol: AppIcons.settings)

            VStack(alignment: .leading, spacing: AppSpacing.xs) {
              Text("Entitlement Mode")
                .font(AppTypography.bodyEmphasis)
                .foregroundStyle(AppColors.textPrimary)

              Picker(
                "Entitlement Mode",
                selection: Binding(
                  get: { viewModel.debugEntitlementSettings.mode },
                  set: { mode in
                    Task { await viewModel.setDebugEntitlementMode(mode) }
                  }
                )
              ) {
                ForEach(DebugEntitlementMode.allCases) { mode in
                  Text(mode.displayName)
                    .tag(mode)
                }
              }
              .pickerStyle(.menu)
              .tint(AppColors.accent)
            }
          }
          .padding(AppSpacing.m)

          Divider().overlay(AppColors.border)

          SettingsToggleRow(
            icon: AppIcons.warning,
            title: "Simulate free Drift limit reached",
            subtitle: "Blocks new Free Drifts and opens the Drift Plus paywall.",
            isOn: Binding(
              get: { viewModel.debugEntitlementSettings.simulateFreeEntryLimitReached },
              set: { isEnabled in
                Task { await viewModel.setSimulateFreeEntryLimitReached(isEnabled) }
              }
            )
          )

          Divider().overlay(AppColors.border)

          SettingsToggleRow(
            icon: AppIcons.warning,
            title: "Simulate Plus Drift limit reached",
            subtitle: "Blocks new Plus Drifts with the reliability limit message.",
            isOn: Binding(
              get: { viewModel.debugEntitlementSettings.simulatePlusEntryLimitReached },
              set: { isEnabled in
                Task { await viewModel.setSimulatePlusEntryLimitReached(isEnabled) }
              }
            )
          )

          Divider().overlay(AppColors.border)

          SettingsDestructiveRow(
            icon: AppIcons.trash,
            title: "Clear local data",
            subtitle: "Uses the same delete confirmation as the Data section.",
            action: showDeleteAllConfirmation
          )

          Divider().overlay(AppColors.border)

          SettingsRow(
            icon: AppIcons.lockShield,
            title: "Local identity diagnostics",
            subtitle: viewModel.debugLocalIdentityCreatedAtText,
            trailingValue: "Hidden"
          )

          Divider().overlay(AppColors.border)

          SettingsDestructiveRow(
            icon: AppIcons.trash,
            title: "Reset local identity",
            subtitle: "Debug only. Future connected features must not trust this as auth.",
            action: {
              isShowingResetIdentityConfirmation = true
            }
          )
        }
      }
    }
  #endif

  private func showDeleteAllConfirmation() {
    isShowingDeleteAllConfirmation = true
  }

  private func deleteAllEntries() {
    Task {
      if await viewModel.deleteAllEntries() {
        onEntriesDeleted()
      }
    }
  }

  private func exportAllEntries() {
    Task {
      await viewModel.exportAllEntries()
    }
  }
}

private struct ActivityView: UIViewControllerRepresentable {
  let activityItems: [Any]

  func makeUIViewController(context: Context) -> UIActivityViewController {
    UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
  }

  func updateUIViewController(
    _ uiViewController: UIActivityViewController,
    context: Context
  ) {}
}

#Preview {
  NavigationStack {
    SettingsView(
      viewModel: SettingsViewModel(
        journalRepository: PreviewJournalRepository(),
        subscriptionService: DisabledSubscriptionService(),
        exportService: LocalMarkdownExportService(),
        userIdentityService: PreviewUserIdentityService()
      ),
      coordinator: SettingsCoordinator(),
      onShowPaywall: {},
      onEntriesDeleted: {}
    )
  }
}
