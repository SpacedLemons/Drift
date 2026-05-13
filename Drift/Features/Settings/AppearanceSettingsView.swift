//
//  AppearanceSettingsView.swift
//  Drift
//
//  Created by Lucas Stuart West Rogers on 12/05/2026.
//

import SwiftUI

struct AppearanceSettingsView: View {
  @State private var viewModel: AppearanceSettingsViewModel

  init(viewModel: AppearanceSettingsViewModel) {
    _viewModel = State(initialValue: viewModel)
  }

  var body: some View {
    ZStack {
      AppTheme.backgroundGradient
        .ignoresSafeArea()

      ScrollView {
        VStack(alignment: .leading, spacing: AppSpacing.l) {
          SettingsInfoCard(
            icon: AppIcons.paintPalette,
            title: "Appearance",
            message:
              "These choices are saved locally. Full app-wide theming will be expanded in a later chunk.",
            accent: viewModel.selectedAccentColor
          )

          SettingsSectionCard(title: "Mode") {
            Picker(
              "Mode",
              selection: Binding(
                get: { viewModel.settings.mode },
                set: { mode in
                  Task { await viewModel.setMode(mode) }
                }
              )
            ) {
              ForEach(AppearanceMode.allCases) { mode in
                Text(mode.displayName)
                  .tag(mode)
              }
            }
            .pickerStyle(.segmented)
            .padding(AppSpacing.m)
            .accessibilityLabel("Appearance mode")
          }

          SettingsSectionCard(title: "Accent colour") {
            FlowLayout(spacing: AppSpacing.s) {
              ForEach(viewModel.availableThemes) { theme in
                Button(
                  action: {
                    Task { await viewModel.setColorTheme(theme) }
                  },
                  label: {
                    HStack(spacing: AppSpacing.xs) {
                      Circle()
                        .fill(AppColors.accent(for: theme))
                        .frame(width: 18, height: 18)

                      Text(theme.displayName)
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.textPrimary)

                      if viewModel.settings.colorTheme == theme {
                        Image(systemName: AppIcons.checkmark)
                          .font(.caption)
                          .foregroundStyle(AppColors.accent(for: theme))
                      }
                    }
                    .padding(.horizontal, AppSpacing.s)
                    .padding(.vertical, AppSpacing.xs)
                    .background(
                      AppColors.surfaceRaised,
                      in: Capsule()
                    )
                  }
                )
                .buttonStyle(.plain)
                .accessibilityLabel("\(theme.displayName) accent colour")
                .accessibilityValue(
                  viewModel.settings.colorTheme == theme ? "Selected" : "Not selected")
              }
            }
            .padding(AppSpacing.m)
          }

          SettingsSectionCard(title: "Layout density") {
            Picker(
              "Layout density",
              selection: Binding(
                get: { viewModel.settings.layoutDensity },
                set: { density in
                  Task { await viewModel.setLayoutDensity(density) }
                }
              )
            ) {
              ForEach(LayoutDensity.allCases) { density in
                Text(density.displayName)
                  .tag(density)
              }
            }
            .pickerStyle(.segmented)
            .padding(AppSpacing.m)
            .accessibilityLabel("Layout density")
          }

          SettingsSectionCard(title: "App icon") {
            SettingsInfoCard(
              icon: AppIcons.settings,
              title: "Standard icon",
              message: "Alternate icons will be prepared later.",
              accent: viewModel.selectedAccentColor
            )
            .padding(AppSpacing.m)
          }

          SettingsSectionCard(title: "Typography") {
            SettingsInfoCard(
              icon: AppIcons.book,
              title: "Standard type",
              message: "More typography options will be available later.",
              accent: viewModel.selectedAccentColor
            )
            .padding(AppSpacing.m)
          }

          Text("More appearance options will be available later.")
            .font(AppTypography.caption)
            .foregroundStyle(AppColors.textSecondary)
            .padding(.horizontal, AppSpacing.xs)

          if let errorMessage = viewModel.errorMessage {
            Text(errorMessage)
              .font(AppTypography.body)
              .foregroundStyle(AppColors.warmAccent)
          }
        }
        .padding(AppSpacing.l)
      }
    }
    .navigationTitle("Appearance")
    .tint(viewModel.selectedAccentColor)
    .task {
      await viewModel.load()
    }
  }
}

#Preview {
  NavigationStack {
    AppearanceSettingsView(
      viewModel: AppearanceSettingsViewModel(
        customisationService: LocalCustomisationService(),
        subscriptionService: DisabledSubscriptionService()
      )
    )
  }
}
