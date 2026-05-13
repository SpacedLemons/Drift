//
//  GuideAnnotationsView.swift
//  Drift
//
//  Created by Lucas Stuart West Rogers on 13/05/2026.
//

import SwiftUI

struct GuideAnnotationsView: View {
  @Environment(\.dismiss) private var dismiss
  @State private var viewModel: GuideViewModel

  init(viewModel: GuideViewModel) {
    _viewModel = State(initialValue: viewModel)
  }

  var body: some View {
    NavigationStack {
      ZStack {
        AppTheme.backgroundGradient
          .ignoresSafeArea()

        ScrollView {
          VStack(alignment: .leading, spacing: AppSpacing.l) {
            header

            LazyVStack(spacing: AppSpacing.s) {
              ForEach(viewModel.annotations) { annotation in
                GuideAnnotationCard(annotation: annotation)
              }
            }

            Button(
              action: {
                Task {
                  await viewModel.dismissGuide()
                  dismiss()
                }
              },
              label: {
                Label("Dismiss Guide", systemImage: AppIcons.checkmark)
                  .frame(maxWidth: .infinity)
              }
            )
            .buttonStyle(.borderedProminent)
            .tint(AppColors.accent)
          }
          .padding(AppSpacing.l)
        }
      }
      .navigationTitle("Guide")
      .toolbar {
        ToolbarItem(placement: .topBarTrailing) {
          Button(
            action: {
              dismiss()
            },
            label: {
              Image(systemName: AppIcons.xmark)
            }
          )
          .accessibilityLabel("Close guide")
        }
      }
      .task {
        await viewModel.load()
      }
    }
  }

  private var header: some View {
    VStack(alignment: .leading, spacing: AppSpacing.s) {
      Text("Drift guide")
        .font(AppTypography.appTitle)
        .foregroundStyle(AppColors.textPrimary)

      Text("Small notes for the local-first journal flow.")
        .font(AppTypography.body)
        .foregroundStyle(AppColors.textSecondary)
        .fixedSize(horizontal: false, vertical: true)
    }
  }
}

private struct GuideAnnotationCard: View {
  let annotation: GuideAnnotation

  var body: some View {
    HStack(alignment: .top, spacing: AppSpacing.m) {
      Image(systemName: annotation.icon)
        .font(.system(size: 18, weight: .semibold))
        .foregroundStyle(AppColors.accent)
        .frame(width: 38, height: 38)
        .background(AppColors.accent.opacity(0.12), in: Circle())

      VStack(alignment: .leading, spacing: AppSpacing.xs) {
        Text(annotation.title)
          .font(AppTypography.cardTitle)
          .foregroundStyle(AppColors.textPrimary)

        Text(annotation.message)
          .font(AppTypography.body)
          .foregroundStyle(AppColors.textSecondary)
          .fixedSize(horizontal: false, vertical: true)
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(AppSpacing.m)
    .background(
      AppColors.surface.opacity(0.84),
      in: RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius)
    )
    .overlay {
      RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius)
        .stroke(AppColors.border, lineWidth: 1)
    }
  }
}

#Preview {
  GuideAnnotationsView(
    viewModel: GuideViewModel(guideService: PreviewGuideService())
  )
}
