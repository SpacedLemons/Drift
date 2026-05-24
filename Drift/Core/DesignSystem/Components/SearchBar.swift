//
//  SearchBar.swift
//  Drift
//
//  Created by Lucas Stuart West Rogers on 12/05/2026.
//

import SwiftUI

struct SearchBar: View {
  @Binding var text: String
  var placeholder = "Search your Drifts"

  var body: some View {
    HStack(spacing: AppSpacing.s) {
      Image(systemName: AppIcons.search)
        .font(.system(size: 16, weight: .medium))
        .foregroundStyle(AppColors.textTertiary)

      TextField(placeholder, text: $text)
        .font(AppTypography.body)
        .foregroundStyle(AppColors.textPrimary)
        .textInputAutocapitalization(.never)
        .autocorrectionDisabled()
        .submitLabel(.search)

      if !text.isEmpty {
        Button(
          action: {
            withAnimation(AppAnimation.gentle) {
              text = ""
            }
          },
          label: {
            Image(systemName: "xmark.circle.fill")
              .font(.system(size: 16, weight: .semibold))
              .foregroundStyle(AppColors.textTertiary)
              .frame(width: 28, height: 28)
          }
        )
        .buttonStyle(.plain)
        .accessibilityLabel("Clear search")
        .transition(.opacity.combined(with: .scale(scale: 0.88)))
      }
    }
    .padding(.horizontal, AppSpacing.m)
    .frame(minHeight: 48)
    .background(AppColors.surface.opacity(0.92), in: Capsule())
    .overlay {
      Capsule()
        .stroke(AppColors.border, lineWidth: 1)
    }
    .accessibilityElement(children: .contain)
    .animation(AppAnimation.gentle, value: text.isEmpty)
  }
}
