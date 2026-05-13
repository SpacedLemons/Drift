//
//  PremiumBadge.swift
//  Drift
//
//  Created by Lucas Stuart West Rogers on 12/05/2026.
//

import SwiftUI

struct PremiumBadge: View {
  var body: some View {
    Label("Later", systemImage: AppIcons.sparkles)
      .font(AppTypography.caption)
      .foregroundStyle(AppColors.accent)
      .padding(.horizontal, AppSpacing.s)
      .padding(.vertical, AppSpacing.xs)
      .background(AppColors.accent.opacity(0.14), in: Capsule())
      .accessibilityLabel("Future feature")
  }
}
