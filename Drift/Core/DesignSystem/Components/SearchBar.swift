//
//  SearchBar.swift
//  Drift
//
//  Created by Lucas Stuart West Rogers on 12/05/2026.
//

import SwiftUI

struct SearchBar: View {
  @Binding var text: String
  var placeholder = "Search entries"

  var body: some View {
    HStack(spacing: AppSpacing.s) {
      Image(systemName: AppIcons.search)
        .font(.system(size: 16, weight: .medium))
        .foregroundStyle(AppColors.textTertiary)

      TextField(placeholder, text: $text)
        .font(AppTypography.body)
        .foregroundStyle(AppColors.textPrimary)
        .submitLabel(.search)
    }
    .padding(.horizontal, AppSpacing.m)
    .frame(minHeight: 50)
    .background(AppColors.surface, in: RoundedRectangle(cornerRadius: AppTheme.controlCornerRadius))
    .overlay {
      RoundedRectangle(cornerRadius: AppTheme.controlCornerRadius)
        .stroke(AppColors.border, lineWidth: 1)
    }
    .accessibilityElement(children: .contain)
  }
}
