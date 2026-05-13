//
//  MoodPill.swift
//  Drift
//
//  Created by Lucas Stuart West Rogers on 12/05/2026.
//

import SwiftUI

struct MoodPill: View {
  let mood: Mood?

  var body: some View {
    HStack(spacing: AppSpacing.xs) {
      Circle()
        .fill(AppColors.moodColor(mood))
        .frame(width: 7, height: 7)

      Text(mood?.displayName ?? "Unspecified")
        .font(AppTypography.caption)
        .foregroundStyle(AppColors.textSecondary)
        .lineLimit(1)
    }
    .padding(.horizontal, AppSpacing.s)
    .padding(.vertical, AppSpacing.xs)
    .background(AppColors.moodColor(mood).opacity(0.14), in: Capsule())
    .accessibilityLabel("Suggested mood \(mood?.displayName ?? "unspecified")")
  }
}
