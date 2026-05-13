//
//  ThemeSelector.swift
//  Drift
//
//  Created by Lucas Stuart West Rogers on 12/05/2026.
//

import SwiftUI

struct ThemeSelector: View {
  let selectedThemes: [JournalTheme]
  var selectedCustomThemes: [CustomJournalTheme] = []
  var availableCustomThemes: [CustomJournalTheme] = []
  var pendingCustomThemeName: String = ""
  let toggleTheme: (JournalTheme) -> Void
  var toggleCustomTheme: (CustomJournalTheme) -> Void = { _ in }
  var updatePendingCustomThemeName: (String) -> Void = { _ in }
  var createCustomTheme: () -> Void = {}
  var deleteCustomTheme: (CustomJournalTheme) -> Void = { _ in }

  var body: some View {
    VStack(alignment: .leading, spacing: AppSpacing.s) {
      LazyVGrid(
        columns: [GridItem(.adaptive(minimum: 112), spacing: AppSpacing.s)],
        spacing: AppSpacing.s
      ) {
        ForEach(JournalTheme.allCases) { theme in
          builtInThemeButton(theme)
        }
      }

      if !availableCustomThemes.isEmpty {
        FlowLayout(spacing: AppSpacing.xs) {
          ForEach(availableCustomThemes) { theme in
            customThemeButton(theme)
          }
        }
      }

      HStack(spacing: AppSpacing.s) {
        TextField(
          "Create theme",
          text: Binding(
            get: { pendingCustomThemeName },
            set: updatePendingCustomThemeName
          )
        )
        .textInputAutocapitalization(.words)
        .submitLabel(.done)
        .onSubmit(createCustomTheme)
        .padding(AppSpacing.s)
        .background(
          AppColors.surface.opacity(0.82),
          in: RoundedRectangle(cornerRadius: AppTheme.controlCornerRadius)
        )

        IconButton(
          icon: AppIcons.checkmark,
          accessibilityLabel: "Create custom theme",
          action: createCustomTheme
        )
      }
    }
  }

  private func builtInThemeButton(_ theme: JournalTheme) -> some View {
    Button(
      action: {
        toggleTheme(theme)
      },
      label: {
        Label(theme.displayName, systemImage: AppIcons.tag)
          .font(AppTypography.caption)
          .foregroundStyle(selectedThemes.contains(theme) ? .white : AppColors.textSecondary)
          .lineLimit(1)
          .frame(maxWidth: .infinity, minHeight: 36)
          .background(
            selectedThemes.contains(theme) ? AppColors.accent : AppColors.surfaceRaised,
            in: Capsule()
          )
      }
    )
    .buttonStyle(.plain)
    .accessibilityLabel("Theme \(theme.displayName)")
    .accessibilityValue(selectedThemes.contains(theme) ? "Selected" : "Not selected")
  }

  private func customThemeButton(_ theme: CustomJournalTheme) -> some View {
    let isSelected = selectedCustomThemes.contains(theme)

    return HStack(spacing: AppSpacing.xxs) {
      Button(
        action: {
          toggleCustomTheme(theme)
        },
        label: {
          Label(theme.displayName, systemImage: AppIcons.tag)
            .font(AppTypography.caption)
            .foregroundStyle(isSelected ? .white : AppColors.textSecondary)
            .lineLimit(1)
            .padding(.leading, AppSpacing.s)
            .padding(.vertical, AppSpacing.xs)
        }
      )
      .buttonStyle(.plain)
      .accessibilityLabel("Custom theme \(theme.displayName)")
      .accessibilityValue(isSelected ? "Selected" : "Not selected")

      Button(
        action: {
          deleteCustomTheme(theme)
        },
        label: {
          Image(systemName: AppIcons.xmark)
            .font(.caption.weight(.semibold))
            .frame(width: 24, height: 24)
        }
      )
      .buttonStyle(.plain)
      .accessibilityLabel("Delete custom theme \(theme.displayName)")
    }
    .background(isSelected ? AppColors.accent : AppColors.surfaceRaised, in: Capsule())
  }
}
