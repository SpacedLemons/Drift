//
//  SettingsComponents.swift
//  Drift
//
//  Created by Lucas Stuart West Rogers on 12/05/2026.
//

import SwiftUI

struct SettingsSectionCard<Content: View>: View {
  let title: String
  @ViewBuilder let content: () -> Content

  var body: some View {
    VStack(alignment: .leading, spacing: AppSpacing.s) {
      Text(title)
        .font(AppTypography.cardTitle)
        .foregroundStyle(AppColors.textPrimary)

      VStack(spacing: 0) {
        content()
      }
      .background(
        AppColors.surface.opacity(0.84),
        in: RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius)
      )
      .overlay {
        RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius)
          .stroke(AppColors.border, lineWidth: 1)
      }
    }
  }
}

struct SettingsNavigationRow: View {
  let icon: String
  let title: String
  let subtitle: String?
  let trailingValue: String?
  let action: () -> Void

  init(
    icon: String,
    title: String,
    subtitle: String? = nil,
    trailingValue: String? = nil,
    action: @escaping () -> Void
  ) {
    self.icon = icon
    self.title = title
    self.subtitle = subtitle
    self.trailingValue = trailingValue
    self.action = action
  }

  var body: some View {
    Button(
      action: {
        action()
      },
      label: {
        rowContent(chevron: true)
      }
    )
    .buttonStyle(.plain)
    .accessibilityLabel(accessibilityText)
  }

  private func rowContent(chevron: Bool) -> some View {
    HStack(spacing: AppSpacing.m) {
      SettingsIcon(symbol: icon)

      VStack(alignment: .leading, spacing: AppSpacing.xs) {
        Text(title)
          .font(AppTypography.bodyEmphasis)
          .foregroundStyle(AppColors.textPrimary)

        if let subtitle {
          Text(subtitle)
            .font(AppTypography.caption)
            .foregroundStyle(AppColors.textSecondary)
            .fixedSize(horizontal: false, vertical: true)
        }
      }

      Spacer(minLength: AppSpacing.s)

      if let trailingValue {
        Text(trailingValue)
          .font(AppTypography.caption)
          .foregroundStyle(AppColors.textTertiary)
          .lineLimit(1)
      }

      if chevron {
        Image(systemName: AppIcons.chevronRight)
          .font(.caption)
          .foregroundStyle(AppColors.textTertiary)
      }
    }
    .padding(AppSpacing.m)
    .contentShape(Rectangle())
  }

  private var accessibilityText: String {
    [title, subtitle, trailingValue].compactMap { $0 }.joined(separator: ", ")
  }
}

struct SettingsRow: View {
  let icon: String
  let title: String
  let subtitle: String?
  let trailingValue: String?

  init(
    icon: String,
    title: String,
    subtitle: String? = nil,
    trailingValue: String? = nil
  ) {
    self.icon = icon
    self.title = title
    self.subtitle = subtitle
    self.trailingValue = trailingValue
  }

  var body: some View {
    HStack(spacing: AppSpacing.m) {
      SettingsIcon(symbol: icon)

      VStack(alignment: .leading, spacing: AppSpacing.xs) {
        Text(title)
          .font(AppTypography.bodyEmphasis)
          .foregroundStyle(AppColors.textPrimary)

        if let subtitle {
          Text(subtitle)
            .font(AppTypography.caption)
            .foregroundStyle(AppColors.textSecondary)
            .fixedSize(horizontal: false, vertical: true)
        }
      }

      Spacer(minLength: AppSpacing.s)

      if let trailingValue {
        Text(trailingValue)
          .font(AppTypography.caption)
          .foregroundStyle(AppColors.textTertiary)
          .multilineTextAlignment(.trailing)
      }
    }
    .padding(AppSpacing.m)
    .accessibilityElement(children: .combine)
    .accessibilityLabel([title, subtitle, trailingValue].compactMap { $0 }.joined(separator: ", "))
  }
}

struct SettingsToggleRow: View {
  let icon: String
  let title: String
  let subtitle: String?
  @Binding var isOn: Bool

  var body: some View {
    Toggle(isOn: $isOn) {
      HStack(spacing: AppSpacing.m) {
        SettingsIcon(symbol: icon)

        VStack(alignment: .leading, spacing: AppSpacing.xs) {
          Text(title)
            .font(AppTypography.bodyEmphasis)
            .foregroundStyle(AppColors.textPrimary)

          if let subtitle {
            Text(subtitle)
              .font(AppTypography.caption)
              .foregroundStyle(AppColors.textSecondary)
              .fixedSize(horizontal: false, vertical: true)
          }
        }
      }
    }
    .tint(AppColors.accent)
    .padding(AppSpacing.m)
    .accessibilityLabel(title)
    .accessibilityValue(isOn ? "On" : "Off")
  }
}

struct SettingsDestructiveRow: View {
  let icon: String
  let title: String
  let subtitle: String?
  let action: () -> Void

  var body: some View {
    Button(
      role: .destructive,
      action: {
        action()
      },
      label: {
        HStack(spacing: AppSpacing.m) {
          SettingsIcon(symbol: icon, tint: AppColors.warmAccent)

          VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text(title)
              .font(AppTypography.bodyEmphasis)
              .foregroundStyle(AppColors.warmAccent)

            if let subtitle {
              Text(subtitle)
                .font(AppTypography.caption)
                .foregroundStyle(AppColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
            }
          }

          Spacer()
        }
        .padding(AppSpacing.m)
        .contentShape(Rectangle())
      }
    )
    .buttonStyle(.plain)
    .accessibilityLabel([title, subtitle].compactMap { $0 }.joined(separator: ", "))
  }
}

struct SettingsInfoCard: View {
  let icon: String
  let title: String
  let message: String
  var accent: Color = AppColors.accent

  var body: some View {
    VStack(alignment: .leading, spacing: AppSpacing.s) {
      Label(title, systemImage: icon)
        .font(AppTypography.cardTitle)
        .foregroundStyle(AppColors.textPrimary)

      Text(message)
        .font(AppTypography.body)
        .foregroundStyle(AppColors.textSecondary)
        .fixedSize(horizontal: false, vertical: true)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(AppSpacing.m)
    .background(
      accent.opacity(0.12),
      in: RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius)
    )
    .overlay {
      RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius)
        .stroke(accent.opacity(0.25), lineWidth: 1)
    }
  }
}

struct SettingsIcon: View {
  let symbol: String
  var tint: Color = AppColors.accent

  var body: some View {
    Image(systemName: symbol)
      .font(.system(size: 16, weight: .semibold))
      .foregroundStyle(tint)
      .frame(width: 34, height: 34)
      .background(tint.opacity(0.12), in: Circle())
  }
}
