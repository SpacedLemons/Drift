//
//  SavedEntryView.swift
//  Drift
//
//  Created by Lucas Stuart West Rogers on 12/05/2026.
//

import SwiftUI

struct SavedEntryView: View {
  let viewModel: SavedEntryViewModel
  let onViewEntry: () -> Void
  let onAddAnother: () -> Void
  let onBackToJournal: () -> Void

  var body: some View {
    ZStack {
      AppTheme.backgroundGradient
        .ignoresSafeArea()

      VStack(spacing: AppSpacing.xl) {
        Spacer()

        Image(systemName: AppIcons.success)
          .font(.system(size: 58, weight: .semibold))
          .foregroundStyle(AppColors.accentSecondary)
          .shadow(color: AppColors.accentSecondary.opacity(0.24), radius: 22, y: 10)

        VStack(spacing: AppSpacing.s) {
          Text("Drift saved")
            .font(AppTypography.appTitle)
            .foregroundStyle(AppColors.textPrimary)

          Text(
            "Your \(viewModel.entry.driftType.displayName.lowercased()) Drift is stored locally on this device."
          )
          .font(AppTypography.body)
          .foregroundStyle(AppColors.textSecondary)
          .multilineTextAlignment(.center)
        }

        VStack(spacing: AppSpacing.s) {
          Button(
            action: {
              onViewEntry()
            },
            label: {
              Label("View Drift", systemImage: AppIcons.chevronRight)
                .frame(maxWidth: .infinity)
            }
          )
          .buttonStyle(.borderedProminent)
          .tint(AppColors.accent)

          Button(
            action: {
              onAddAnother()
            },
            label: {
              Label("Add Another", systemImage: AppIcons.mic)
                .frame(maxWidth: .infinity)
            }
          )
          .buttonStyle(.bordered)
          .tint(AppColors.textSecondary)

          Button(
            action: {
              onBackToJournal()
            },
            label: {
              Text("Back to Capture")
            }
          )
          .buttonStyle(.plain)
          .foregroundStyle(AppColors.textSecondary)
          .padding(.top, AppSpacing.s)
        }

        Spacer()
      }
      .padding(AppSpacing.l)
    }
    .navigationBarBackButtonHidden()
  }
}

#Preview {
  SavedEntryView(
    viewModel: SavedEntryViewModel(entry: PreviewData.journalEntries[0]),
    onViewEntry: {},
    onAddAnother: {},
    onBackToJournal: {}
  )
}
