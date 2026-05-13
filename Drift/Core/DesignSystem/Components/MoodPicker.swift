//
//  MoodPicker.swift
//  Drift
//
//  Created by Lucas Stuart West Rogers on 12/05/2026.
//

import SwiftUI

struct MoodPicker: View {
  @Binding var selection: Mood

  var body: some View {
    ScrollView(.horizontal, showsIndicators: false) {
      HStack(spacing: AppSpacing.s) {
        ForEach(Mood.allCases.filter { $0 != .unknown }) { mood in
          Button(
            action: {
              selection = mood
            },
            label: {
              HStack(spacing: AppSpacing.xs) {
                Circle()
                  .fill(AppColors.moodColor(mood))
                  .frame(width: 8, height: 8)

                Text(mood.displayName)
                  .font(AppTypography.caption)
              }
              .foregroundStyle(selection == mood ? .white : AppColors.textSecondary)
              .padding(.horizontal, AppSpacing.s)
              .padding(.vertical, AppSpacing.xs)
              .background(
                selection == mood ? AppColors.accent : AppColors.surfaceRaised, in: Capsule())
            }
          )
          .buttonStyle(.plain)
          .accessibilityLabel("Mood \(mood.displayName)")
          .accessibilityValue(selection == mood ? "Selected" : "Not selected")
        }
      }
    }
  }
}
