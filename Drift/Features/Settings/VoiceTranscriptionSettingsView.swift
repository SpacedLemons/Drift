//
//  VoiceTranscriptionSettingsView.swift
//  Drift
//
//  Created by Lucas Stuart West Rogers on 17/05/2026.
//

import SwiftUI

struct VoiceTranscriptionSettingsView: View {
  @State private var viewModel: VoiceTranscriptionSettingsViewModel

  init(viewModel: VoiceTranscriptionSettingsViewModel) {
    _viewModel = State(initialValue: viewModel)
  }

  var body: some View {
    ZStack {
      AppTheme.backgroundGradient
        .ignoresSafeArea()

      ScrollView {
        VStack(alignment: .leading, spacing: AppSpacing.l) {
          recognitionSection
          recordingSection
          privacyCard
        }
        .padding(AppSpacing.l)
      }
    }
    .navigationTitle("Voice & Transcription")
    .task {
      await viewModel.load()
    }
  }

  private var recognitionSection: some View {
    SettingsSectionCard(title: "Transcription") {
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
        subtitle: "Drift uses speech recognition to turn your voice captures into text.",
        trailingValue: viewModel.speechPermissionStatusText
      )

      Divider().overlay(AppColors.border)

      SettingsRow(
        icon: AppIcons.mic,
        title: "Microphone permission",
        subtitle: "Drift needs microphone access so you can record voice-first Drifts.",
        trailingValue: viewModel.microphonePermissionStatusText
      )

      if viewModel.shouldShowSystemSettingsLink {
        Divider().overlay(AppColors.border)

        SystemSettingsLink()
          .padding(.horizontal, AppSpacing.m)
          .padding(.bottom, AppSpacing.m)
      }
    }
  }

  private var recordingSection: some View {
    SettingsSectionCard(title: "Recording") {
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
        subtitle: "Temporary audio is discarded after transcription in the MVP.",
        trailingValue: "Later"
      )

      Divider().overlay(AppColors.border)

      SettingsRow(
        icon: AppIcons.waveform,
        title: "Silence handling",
        subtitle: "Drift can suggest pausing after a quiet moment during recording.",
        trailingValue: "On"
      )
    }
  }

  private var privacyCard: some View {
    SettingsInfoCard(
      icon: AppIcons.shield,
      title: "Local-first voice capture",
      message:
        "Recordings are temporary before saving. Your Drifts remain on this device, and transcription uses Apple Speech."
    )
  }
}

#Preview {
  NavigationStack {
    VoiceTranscriptionSettingsView(
      viewModel: VoiceTranscriptionSettingsViewModel(
        transcriptionService: PreviewTranscriptionService(),
        audioRecordingService: PreviewAudioRecordingService()
      )
    )
  }
}
