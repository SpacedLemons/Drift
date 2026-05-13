//
//  ProcessingChecklist.swift
//  Drift
//
//  Created by Lucas Stuart West Rogers on 12/05/2026.
//

import SwiftUI

struct ProcessingChecklist: View {
  let items: [ProcessingChecklistItem]

  var body: some View {
    VStack(spacing: AppSpacing.s) {
      ForEach(items) { item in
        HStack(spacing: AppSpacing.s) {
          statusIcon(for: item.status)

          Text(item.step.title)
            .font(AppTypography.bodyEmphasis)
            .foregroundStyle(AppColors.textPrimary)

          Spacer()
        }
        .padding(AppSpacing.m)
        .background(
          AppColors.surface.opacity(0.84),
          in: RoundedRectangle(cornerRadius: AppTheme.controlCornerRadius)
        )
        .overlay {
          RoundedRectangle(cornerRadius: AppTheme.controlCornerRadius)
            .stroke(AppColors.border, lineWidth: 1)
        }
        .accessibilityElement(children: .combine)
        .accessibilityValue(accessibilityStatus(for: item.status))
      }
    }
  }

  @ViewBuilder
  private func statusIcon(for status: ProcessingStepStatus) -> some View {
    switch status {
    case .pending:
      Circle()
        .stroke(AppColors.textTertiary, lineWidth: 1)
        .frame(width: 24, height: 24)
    case .active:
      ProgressView()
        .tint(AppColors.accent)
        .frame(width: 24, height: 24)
    case .complete:
      Image(systemName: AppIcons.checkmark)
        .font(.system(size: 12, weight: .bold))
        .foregroundStyle(.white)
        .frame(width: 24, height: 24)
        .background(AppColors.accentSecondary, in: Circle())
    case .failed:
      Image(systemName: AppIcons.xmark)
        .font(.system(size: 12, weight: .bold))
        .foregroundStyle(.white)
        .frame(width: 24, height: 24)
        .background(AppColors.warmAccent, in: Circle())
    }
  }

  private func accessibilityStatus(for status: ProcessingStepStatus) -> String {
    switch status {
    case .pending: "Pending"
    case .active: "In progress"
    case .complete: "Complete"
    case .failed: "Failed"
    }
  }
}
