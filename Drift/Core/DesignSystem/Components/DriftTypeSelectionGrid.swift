//
//  DriftTypeSelectionGrid.swift
//  Drift
//
//  Created by Lucas Stuart West Rogers on 23/05/2026.
//

import SwiftUI

struct DriftTypeSelectionGrid: View {
  @Binding var selection: DriftType

  var body: some View {
    FlowLayout(spacing: AppSpacing.xs) {
      ForEach(DriftType.allCases) { driftType in
        Button {
          selection = driftType
        } label: {
          Label(driftType.displayName, systemImage: driftType.symbolName)
            .font(AppTypography.caption)
            .foregroundStyle(
              selection == driftType ? AppColors.textPrimary : AppColors.textSecondary
            )
            .padding(.horizontal, AppSpacing.s)
            .padding(.vertical, AppSpacing.xs)
            .background(
              selection == driftType ? AppColors.accent.opacity(0.22) : AppColors.surfaceRaised,
              in: Capsule()
            )
            .overlay {
              Capsule()
                .stroke(
                  selection == driftType ? AppColors.accent : AppColors.border,
                  lineWidth: 1
                )
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(driftType.displayName)
        .accessibilityAddTraits(selection == driftType ? .isSelected : [])
      }
    }
  }
}

#Preview {
  DriftTypeSelectionGridPreview()
}

private struct DriftTypeSelectionGridPreview: View {
  @State private var selection = DriftType.reflection

  var body: some View {
    ZStack {
      AppTheme.backgroundGradient
        .ignoresSafeArea()

      DriftTypeSelectionGrid(selection: $selection)
        .padding(AppSpacing.l)
    }
  }
}
