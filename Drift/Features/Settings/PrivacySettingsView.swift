//
//  PrivacySettingsView.swift
//  Drift
//
//  Created by Lucas Stuart West Rogers on 12/05/2026.
//

import SwiftUI

struct PrivacySettingsView: View {
  var body: some View {
    ZStack {
      AppTheme.backgroundGradient
        .ignoresSafeArea()

      ScrollView {
        VStack(alignment: .leading, spacing: AppSpacing.l) {
          SettingsInfoCard(
            icon: AppIcons.lockShield,
            title: "Local by default",
            message:
              "Your Drifts are stored on this device. Drift works offline, no account is required, and no cloud sync is used."
          )

          SettingsInfoCard(
            icon: AppIcons.photo,
            title: "Images",
            message: "Images are stored on this device with your Drift."
          )

          SettingsInfoCard(
            icon: AppIcons.waveform,
            title: "Transcription",
            message:
              "Drift prefers on-device transcription where available. Some system transcription features may require network access depending on device, language, and iOS support."
          )

          SettingsInfoCard(
            icon: AppIcons.externalDrive,
            title: "Data",
            message:
              "Exports are created locally and shared only when you choose. Audio playback uses the temporary recording before saving."
          )

          SettingsInfoCard(
            icon: AppIcons.contextPack,
            title: "Context Packs",
            message:
              "Context Packs are local Markdown previews. Nothing is sent anywhere unless you copy or share it yourself."
          )
        }
        .padding(AppSpacing.l)
      }
    }
    .navigationTitle("Privacy")
  }
}

#Preview {
  NavigationStack {
    PrivacySettingsView()
  }
}
