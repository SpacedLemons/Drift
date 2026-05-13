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
  let onEntriesDeleted: () -> Void

  @State private var isShowingDeleteAllConfirmation = false
  @State private var isShowingGuide = false

  init(
    viewModel: SettingsViewModel,
    coordinator: SettingsCoordinator,
    onEntriesDeleted: @escaping () -> Void
  ) {
    _viewModel = State(initialValue: viewModel)
    self.coordinator = coordinator
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
      "Delete all entries?",
      isPresented: $isShowingDeleteAllConfirmation
    ) {
      Button(
        role: .destructive,
        action: {
          deleteAllEntries()
        },
        label: {
          Text("Delete All Entries")
        }
      )

      Button(
        role: .cancel,
        action: {},
        label: {
          Text("Cancel")
        }
      )
    } message: {
      Text("This will remove your journal entries from this device.")
    }
    .sheet(item: $bindableViewModel.exportShareItem) { exportItem in
      ActivityView(activityItems: [exportItem.url])
    }
    .sheet(isPresented: $isShowingGuide) {
      GuideAnnotationsView(
        viewModel: GuideViewModel(guideService: viewModel.guideService)
      )
    }
    .task {
      await viewModel.load()
    }
    .onChange(of: isShowingGuide) { _, isShowing in
      guard !isShowing else { return }

      Task {
        await viewModel.load()
      }
    }
  }

  private var header: some View {
    VStack(alignment: .leading, spacing: AppSpacing.s) {
      Text("Settings")
        .font(AppTypography.appTitle)
        .foregroundStyle(AppColors.textPrimary)
        .accessibilityAddTraits(.isHeader)

      Text("Local preferences for reminders, appearance, privacy, and data.")
        .font(AppTypography.body)
        .foregroundStyle(AppColors.textSecondary)
        .fixedSize(horizontal: false, vertical: true)
    }
  }

  private var settingsSections: some View {
    VStack(alignment: .leading, spacing: AppSpacing.l) {
      SettingsSectionCard(title: "Reminders") {
        SettingsNavigationRow(
          icon: AppIcons.bell,
          title: "Reminder Settings",
          subtitle: "Local journal nudges",
          trailingValue: "Local",
          action: coordinator.showReminders
        )
      }

      SettingsSectionCard(title: "Voice & Transcription") {
        SettingsRow(
          icon: AppIcons.waveform,
          title: "Voice recognition",
          subtitle:
            "Drift prefers on-device transcription where available. Some system transcription features may require network access depending on device, language, and iOS support.",
          trailingValue: viewModel.voiceRecognitionValue
        )

        Divider().overlay(AppColors.border)

        SettingsRow(
          icon: AppIcons.lockShield,
          title: "Speech permission",
          subtitle: "Drift uses speech recognition to turn your voice journal entries into text.",
          trailingValue: viewModel.speechPermissionStatusText
        )

        if viewModel.shouldShowSpeechSettingsLink {
          SystemSettingsLink()
            .padding(.horizontal, AppSpacing.m)
            .padding(.bottom, AppSpacing.m)
        }

        Divider().overlay(AppColors.border)

        SettingsRow(
          icon: AppIcons.book,
          title: "Language",
          subtitle: "Uses the current system language for now.",
          trailingValue: "System"
        )

        Divider().overlay(AppColors.border)

        SettingsRow(
          icon: AppIcons.pencil,
          title: "Transcript cleanup",
          subtitle: "Additional cleanup controls will arrive later.",
          trailingValue: "Later"
        )

        Divider().overlay(AppColors.border)

        SettingsRow(
          icon: AppIcons.externalDrive,
          title: "Keep audio recording",
          subtitle:
            "Future preference. Temporary audio is discarded after transcription in the MVP.",
          trailingValue: "Later"
        )
      }

      SettingsSectionCard(title: "Appearance") {
        SettingsNavigationRow(
          icon: AppIcons.paintPalette,
          title: "Appearance",
          subtitle: "Mode, accent colour, and layout density",
          action: coordinator.showAppearance
        )
      }

      SettingsSectionCard(title: "Guide") {
        SettingsNavigationRow(
          icon: AppIcons.question,
          title: "Drift Guide",
          subtitle: "Lightweight notes for recording, reviewing, images, calendar, and privacy",
          trailingValue: viewModel.isGuideDismissed ? "Dismissed" : "New",
          action: showGuide
        )
        .accessibilityLabel("Drift guide")
      }

      SettingsSectionCard(title: "Data") {
        SettingsNavigationRow(
          icon: AppIcons.share,
          title: viewModel.isExportingEntries ? "Preparing Export" : "Export All Entries",
          subtitle: viewModel.exportPrivacyMessage,
          action: exportAllEntries
        )
        .disabled(viewModel.isExportingEntries)
        .accessibilityLabel("Export all entries")
        .accessibilityHint("Creates a local Markdown file and opens sharing options.")

        Divider().overlay(AppColors.border)

        SettingsDestructiveRow(
          icon: AppIcons.trash,
          title: viewModel.isDeletingAllEntries ? "Deleting Entries" : "Delete All Entries",
          subtitle: "Remove journal entries from this device.",
          action: showDeleteAllConfirmation
        )
        .disabled(viewModel.isDeletingAllEntries)
        .accessibilityLabel("Delete all entries")
      }

      SettingsSectionCard(title: "Privacy") {
        SettingsNavigationRow(
          icon: AppIcons.lockShield,
          title: "Privacy",
          subtitle: "Device storage, transcription, and future AI",
          action: coordinator.showPrivacy
        )
        .accessibilityLabel("Privacy settings")
      }

      SettingsSectionCard(title: "About") {
        SettingsNavigationRow(
          icon: AppIcons.info,
          title: "About Drift",
          subtitle: "Version, privacy notes, and support",
          action: coordinator.showAbout
        )
        .accessibilityLabel("About Drift")
      }
    }
  }

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

  private func showGuide() {
    isShowingGuide = true
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
        transcriptionService: PreviewTranscriptionService(),
        subscriptionService: DisabledSubscriptionService(),
        exportService: LocalMarkdownExportService(),
        guideService: PreviewGuideService()
      ),
      coordinator: SettingsCoordinator(),
      onEntriesDeleted: {}
    )
  }
}
