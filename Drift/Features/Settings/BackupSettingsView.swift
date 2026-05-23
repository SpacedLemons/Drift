//
//  BackupSettingsView.swift
//  Drift
//
//  Created by Lucas Stuart West Rogers on 17/05/2026.
//

import SwiftUI

struct BackupSettingsView: View {
  @State private var viewModel: BackupSettingsViewModel

  init(viewModel: BackupSettingsViewModel) {
    _viewModel = State(initialValue: viewModel)
  }

  var body: some View {
    ZStack {
      AppTheme.backgroundGradient
        .ignoresSafeArea()

      ScrollView {
        VStack(alignment: .leading, spacing: AppSpacing.l) {
          privacyCard
          iCloudBackupSection
          backupActionsSection
          freeFeatureCard

          if let successMessage = viewModel.successMessage {
            Text(successMessage)
              .font(AppTypography.body)
              .foregroundStyle(AppColors.accent)
          }

          if let errorMessage = viewModel.errorMessage {
            Text(errorMessage)
              .font(AppTypography.body)
              .foregroundStyle(AppColors.warmAccent)
          }
        }
        .padding(AppSpacing.l)
      }
    }
    .navigationTitle("Backup & Restore")
    .task {
      await viewModel.load()
    }
  }

  private var privacyCard: some View {
    SettingsInfoCard(
      icon: AppIcons.lockShield,
      title: "Private iCloud backup",
      message:
        "Drift can keep a private backup in your iCloud account so you can restore your Drifts on a new iPhone. Drift remains local-first. iCloud backup is optional."
    )
  }

  private var iCloudBackupSection: some View {
    SettingsSectionCard(title: "iCloud Backup") {
      SettingsToggleRow(
        icon: AppIcons.iCloudUpload,
        title: "iCloud Backup",
        subtitle: "Automatically back up your Drifts to your private iCloud account.",
        isOn: Binding(
          get: { viewModel.status.isICloudBackupEnabled },
          set: { isEnabled in
            Task { await viewModel.setICloudBackupEnabled(isEnabled) }
          }
        )
      )
      .disabled(!viewModel.canToggleICloudBackup)

      Divider().overlay(AppColors.border)

      SettingsRow(
        icon: AppIcons.info,
        title: "Status",
        subtitle: viewModel.iCloudAvailabilityMessage,
        trailingValue: viewModel.iCloudBackupValue
      )

      Divider().overlay(AppColors.border)

      SettingsRow(
        icon: AppIcons.clock,
        title: "Last backup status",
        subtitle: viewModel.lastBackupText,
        trailingValue: nil
      )
    }
  }

  private var backupActionsSection: some View {
    SettingsSectionCard(title: "Backup & Restore") {
      SettingsActionRow(
        icon: AppIcons.iCloudUpload,
        title: viewModel.isBackingUp ? "Backing Up" : "Back Up Now",
        subtitle: "Create or update your latest iCloud backup.",
        action: {
          Task { await viewModel.backUpNow() }
        }
      )
      .disabled(!viewModel.canBackUpNow)

      Divider().overlay(AppColors.border)

      SettingsActionRow(
        icon: AppIcons.iCloudDownload,
        title: viewModel.isRestoring ? "Restoring Drifts" : "Restore Drifts",
        subtitle:
          "Restore Drifts from your private iCloud backup. Existing Drifts stay on this device.",
        action: {
          Task { await viewModel.restoreJournal() }
        }
      )
      .disabled(!viewModel.canRestore)
    }
  }

  private var freeFeatureCard: some View {
    SettingsInfoCard(
      icon: AppIcons.success,
      title: "Free",
      message:
        "Backup & Restore is free. You can turn iCloud Backup off at any time."
    )
  }
}

#Preview {
  NavigationStack {
    BackupSettingsView(
      viewModel: BackupSettingsViewModel(
        backupService: PreviewBackupService()
      )
    )
  }
}
