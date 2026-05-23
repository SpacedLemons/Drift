//
//  JournalCard.swift
//  Drift
//
//  Created by Lucas Stuart West Rogers on 12/05/2026.
//

import SwiftUI

struct JournalCard: View {
  let entry: JournalEntry

  var body: some View {
    VStack(alignment: .leading, spacing: AppSpacing.m) {
      HStack(alignment: .top, spacing: AppSpacing.m) {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
          Text(entry.displayTitle)
            .font(AppTypography.cardTitle)
            .foregroundStyle(AppColors.textPrimary)
            .lineLimit(2)

          HStack(spacing: AppSpacing.xs) {
            Image(systemName: AppIcons.clock)
              .font(.caption)
            Text(entry.createdAt, format: .dateTime.weekday(.abbreviated).hour().minute())
          }
          .font(AppTypography.caption)
          .foregroundStyle(AppColors.textTertiary)
        }

        Spacer(minLength: AppSpacing.s)

        if entry.isFavorite {
          Image(systemName: AppIcons.favorite)
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(AppColors.warmAccent)
            .accessibilityLabel("Favorite Drift")
        }
      }

      Text(entry.previewText)
        .font(AppTypography.body)
        .foregroundStyle(AppColors.textSecondary)
        .lineLimit(3)
        .fixedSize(horizontal: false, vertical: true)

      HStack(spacing: AppSpacing.xs) {
        MoodPill(mood: entry.mood)

        Label(entry.driftType.displayName, systemImage: entry.driftType.symbolName)
          .font(AppTypography.caption)
          .foregroundStyle(AppColors.textSecondary)
          .padding(.horizontal, AppSpacing.s)
          .padding(.vertical, AppSpacing.xs)
          .background(AppColors.surfaceRaised, in: Capsule())
          .lineLimit(1)

        ForEach(entry.themes.prefix(2)) { theme in
          Label(theme.displayName, systemImage: AppIcons.tag)
            .font(AppTypography.caption)
            .foregroundStyle(AppColors.textSecondary)
            .padding(.horizontal, AppSpacing.s)
            .padding(.vertical, AppSpacing.xs)
            .background(AppColors.surfaceRaised, in: Capsule())
            .lineLimit(1)
        }

        ForEach(entry.customThemes.prefix(max(0, 2 - entry.themes.count))) { theme in
          Label(theme.displayName, systemImage: AppIcons.tag)
            .font(AppTypography.caption)
            .foregroundStyle(AppColors.textSecondary)
            .padding(.horizontal, AppSpacing.s)
            .padding(.vertical, AppSpacing.xs)
            .background(AppColors.surfaceRaised, in: Capsule())
            .lineLimit(1)
        }

        if !entry.imageAttachments.isEmpty {
          Label("\(entry.imageAttachments.count)", systemImage: AppIcons.photo)
            .font(AppTypography.caption)
            .foregroundStyle(AppColors.textSecondary)
            .padding(.horizontal, AppSpacing.s)
            .padding(.vertical, AppSpacing.xs)
            .background(AppColors.surfaceRaised, in: Capsule())
            .accessibilityLabel("\(entry.imageAttachments.count) attached images")
        }
      }
    }
    .padding(AppSpacing.m)
    .background(
      AppColors.surface.opacity(0.92), in: RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius)
    )
    .overlay {
      RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius)
        .stroke(AppColors.border, lineWidth: 1)
    }
    .contentShape(RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius))
    .accessibilityElement(children: .combine)
  }
}
