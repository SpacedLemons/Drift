//
//  EmptyStateView.swift
//  Drift
//
//  Created by Lucas Stuart West Rogers on 12/05/2026.
//

import SwiftUI

struct EmptyStateView: View {
  let title: String
  let message: String
  let icon: String

  var body: some View {
    VStack(spacing: AppSpacing.m) {
      Image(systemName: icon)
        .font(.system(size: 28, weight: .semibold))
        .foregroundStyle(AppColors.accent)
        .frame(width: 58, height: 58)
        .background(AppColors.accent.opacity(0.14), in: Circle())

      VStack(spacing: AppSpacing.xs) {
        Text(title)
          .font(AppTypography.cardTitle)
          .foregroundStyle(AppColors.textPrimary)

        Text(message)
          .font(AppTypography.body)
          .foregroundStyle(AppColors.textSecondary)
          .multilineTextAlignment(.center)
          .fixedSize(horizontal: false, vertical: true)
      }
    }
    .frame(maxWidth: .infinity)
    .padding(.vertical, AppSpacing.xl)
    .padding(.horizontal, AppSpacing.l)
    .background(
      AppColors.surface.opacity(0.72), in: RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius)
    )
    .overlay {
      RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius)
        .stroke(AppColors.border, lineWidth: 1)
    }
  }
}
