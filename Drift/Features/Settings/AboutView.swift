//
//  AboutView.swift
//  Drift
//
//  Created by Lucas Stuart West Rogers on 12/05/2026.
//

import SwiftUI

struct AboutView: View {
  private var appVersion: String {
    Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "MVP"
  }

  private var buildNumber: String {
    Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Local"
  }

  var body: some View {
    ZStack {
      AppTheme.backgroundGradient
        .ignoresSafeArea()

      ScrollView {
        VStack(alignment: .leading, spacing: AppSpacing.l) {
          VStack(alignment: .leading, spacing: AppSpacing.s) {
            Text("Drift")
              .font(AppTypography.appTitle)
              .foregroundStyle(AppColors.textPrimary)
              .accessibilityAddTraits(.isHeader)

            Text("Drift is a private voice journal for capturing thoughts quickly and calmly.")
              .font(AppTypography.body)
              .foregroundStyle(AppColors.textSecondary)
              .fixedSize(horizontal: false, vertical: true)
          }

          SettingsSectionCard(title: "App") {
            aboutRow(title: "Version", value: appVersion)
            Divider().overlay(AppColors.border)
            aboutRow(title: "Build", value: buildNumber)
            Divider().overlay(AppColors.border)
            aboutRow(title: "Privacy", value: "Entries are stored on this device.")
            Divider().overlay(AppColors.border)
            aboutRow(title: "Acknowledgements", value: "Apple frameworks and open-source tooling.")
            Divider().overlay(AppColors.border)
            aboutRow(title: "Support", value: "Internal TestFlight feedback.")
          }
        }
        .padding(AppSpacing.l)
      }
    }
    .navigationTitle("About")
  }

  private func aboutRow(title: String, value: String) -> some View {
    HStack {
      Text(title)
        .font(AppTypography.bodyEmphasis)
        .foregroundStyle(AppColors.textPrimary)

      Spacer()

      Text(value)
        .font(AppTypography.caption)
        .foregroundStyle(AppColors.textSecondary)
    }
    .padding(AppSpacing.m)
    .accessibilityElement(children: .combine)
    .accessibilityLabel("\(title), \(value)")
  }
}

#Preview {
  NavigationStack {
    AboutView()
  }
}
