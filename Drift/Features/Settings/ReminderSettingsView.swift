//
//  ReminderSettingsView.swift
//  Drift
//
//  Created by Lucas Stuart West Rogers on 12/05/2026.
//

import SwiftUI

struct ReminderSettingsView: View {
  @State private var viewModel: ReminderSettingsViewModel

  init(viewModel: ReminderSettingsViewModel) {
    _viewModel = State(initialValue: viewModel)
  }

  var body: some View {
    ZStack {
      AppTheme.backgroundGradient
        .ignoresSafeArea()

      ScrollView {
        VStack(alignment: .leading, spacing: AppSpacing.l) {
          permissionStatusCard
          reminderSection
          ReminderNotificationPreviewCard(message: viewModel.configuration.message)
          privacyCard

          if let errorMessage = viewModel.errorMessage {
            Text(errorMessage)
              .font(AppTypography.body)
              .foregroundStyle(AppColors.warmAccent)
          }
        }
        .padding(AppSpacing.l)
      }
    }
    .navigationTitle("Reminders")
    .task {
      await viewModel.load()
    }
  }

  private var permissionStatusCard: some View {
    VStack(alignment: .leading, spacing: AppSpacing.s) {
      SettingsInfoCard(
        icon: permissionIcon,
        title: "Notification permission",
        message: viewModel.permissionStatusMessage,
        accent: permissionAccent
      )

      if viewModel.shouldShowSettingsLink {
        SystemSettingsLink()
      }
    }
  }

  private var reminderSection: some View {
    SettingsSectionCard(title: "Reminder") {
      SettingsToggleRow(
        icon: AppIcons.bell,
        title: "Journal reminder",
        subtitle: "Choose when Drift should nudge you.",
        isOn: Binding(
          get: { viewModel.configuration.isEnabled },
          set: { isEnabled in
            Task { await viewModel.setEnabled(isEnabled) }
          }
        )
      )

      Divider().overlay(AppColors.border)

      VStack(alignment: .leading, spacing: AppSpacing.s) {
        Label("Time", systemImage: AppIcons.clock)
          .font(AppTypography.bodyEmphasis)
          .foregroundStyle(AppColors.textPrimary)

        DatePicker(
          "Reminder time",
          selection: Binding(
            get: { viewModel.reminderTime },
            set: { date in
              Task { await viewModel.updateReminderTime(date) }
            }
          ),
          displayedComponents: .hourAndMinute
        )
        .labelsHidden()
        .tint(AppColors.accent)
        .accessibilityLabel("Reminder time")
      }
      .padding(AppSpacing.m)

      Divider().overlay(AppColors.border)

      VStack(alignment: .leading, spacing: AppSpacing.s) {
        Label("Repeat", systemImage: AppIcons.repeatArrows)
          .font(AppTypography.bodyEmphasis)
          .foregroundStyle(AppColors.textPrimary)

        Picker(
          "Reminder frequency",
          selection: Binding(
            get: { viewModel.configuration.repeatFrequency },
            set: { frequency in
              Task { await viewModel.setFrequency(frequency) }
            }
          )
        ) {
          ForEach(viewModel.availableFrequencies) { frequency in
            Text(frequency.displayName)
              .tag(frequency)
          }
        }
        .pickerStyle(.segmented)
        .accessibilityLabel("Reminder frequency")
      }
      .padding(AppSpacing.m)

      Divider().overlay(AppColors.border)

      VStack(alignment: .leading, spacing: AppSpacing.s) {
        Label("Message", systemImage: AppIcons.pencil)
          .font(AppTypography.bodyEmphasis)
          .foregroundStyle(AppColors.textPrimary)

        TextField(
          "Reminder message",
          text: Binding(
            get: { viewModel.configuration.message },
            set: viewModel.updateMessageDraft
          )
        )
        .submitLabel(.done)
        .onSubmit {
          Task { await viewModel.saveMessage() }
        }
        .padding(AppSpacing.s)
        .background(
          AppColors.surfaceRaised,
          in: RoundedRectangle(cornerRadius: AppTheme.controlCornerRadius)
        )
        .accessibilityLabel("Reminder message")

        Button(
          action: {
            Task { await viewModel.saveMessage() }
          },
          label: {
            Label("Save Message", systemImage: AppIcons.checkmark)
              .font(AppTypography.caption)
          }
        )
        .buttonStyle(.bordered)
        .tint(AppColors.accent)
      }
      .padding(AppSpacing.m)

      if viewModel.shouldShowPermissionRequest {
        Divider().overlay(AppColors.border)

        Button(
          action: {
            Task { await viewModel.requestPermission() }
          },
          label: {
            Label("Allow Notifications", systemImage: AppIcons.bell)
              .font(AppTypography.bodyEmphasis)
              .frame(maxWidth: .infinity)
          }
        )
        .buttonStyle(.borderedProminent)
        .tint(AppColors.accent)
        .padding(AppSpacing.m)
        .accessibilityLabel("Allow notifications")
      }
    }
  }

  private var privacyCard: some View {
    SettingsInfoCard(
      icon: AppIcons.shield,
      title: "Local only",
      message:
        "Reminders are scheduled on this device. Drift does not use remote push notifications or send journal data anywhere."
    )
  }

  private var permissionIcon: String {
    switch viewModel.permissionStatus {
    case .unknown: AppIcons.bell
    case .granted: AppIcons.success
    case .denied, .restricted: AppIcons.warning
    }
  }

  private var permissionAccent: Color {
    switch viewModel.permissionStatus {
    case .unknown, .granted: AppColors.accent
    case .denied, .restricted: AppColors.warmAccent
    }
  }
}

private struct ReminderNotificationPreviewCard: View {
  let message: String

  var body: some View {
    VStack(alignment: .leading, spacing: AppSpacing.m) {
      Label("Preview", systemImage: AppIcons.notification)
        .font(AppTypography.cardTitle)
        .foregroundStyle(AppColors.textPrimary)

      VStack(alignment: .leading, spacing: AppSpacing.s) {
        Text(
          message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? ReminderConfiguration.default.message
            : message
        )
        .font(AppTypography.bodyEmphasis)
        .foregroundStyle(AppColors.textPrimary)
        .fixedSize(horizontal: false, vertical: true)

        Text("Note journal entry · Remind me later · Not now")
          .font(AppTypography.caption)
          .foregroundStyle(AppColors.textSecondary)
          .fixedSize(horizontal: false, vertical: true)
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(AppSpacing.m)
    .background(
      AppColors.surface.opacity(0.84),
      in: RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius)
    )
    .overlay {
      RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius)
        .stroke(AppColors.border, lineWidth: 1)
    }
    .accessibilityElement(children: .combine)
  }
}

#Preview {
  NavigationStack {
    ReminderSettingsView(
      viewModel: ReminderSettingsViewModel(
        reminderService: PreviewReminderService()
      )
    )
  }
}
