//
//  SpacesView.swift
//  Drift
//
//  Created by Lucas Stuart West Rogers on 23/05/2026.
//

import SwiftUI

struct SpacesView: View {
  @State private var viewModel: SpacesViewModel
  @State private var contextPacksViewModel: ContextPacksViewModel

  init(
    viewModel: SpacesViewModel,
    contextPacksViewModel: ContextPacksViewModel
  ) {
    _viewModel = State(initialValue: viewModel)
    _contextPacksViewModel = State(initialValue: contextPacksViewModel)
  }

  var body: some View {
    ZStack {
      AppTheme.backgroundGradient
        .ignoresSafeArea()

      ScrollView {
        VStack(alignment: .leading, spacing: AppSpacing.l) {
          header
          privacyCard
          spacesSection
          contextPacksLink
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppSpacing.l)
      }
    }
    .navigationBarTitleDisplayMode(.inline)
  }

  private var header: some View {
    VStack(alignment: .leading, spacing: AppSpacing.s) {
      Text("Spaces")
        .font(AppTypography.appTitle)
        .foregroundStyle(AppColors.textPrimary)
        .accessibilityAddTraits(.isHeader)

      Text("Spaces help you group related Drifts, like goals, ideas, moodboards, and projects.")
        .font(AppTypography.body)
        .foregroundStyle(AppColors.textSecondary)
        .fixedSize(horizontal: false, vertical: true)
    }
  }

  private var privacyCard: some View {
    Label {
      Text("Drifts are private by default. You choose what to share with AI.")
        .font(AppTypography.body)
        .foregroundStyle(AppColors.textSecondary)
        .fixedSize(horizontal: false, vertical: true)
    } icon: {
      Image(systemName: AppIcons.lockShield)
        .foregroundStyle(AppColors.accentSecondary)
    }
    .padding(AppSpacing.m)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(
      AppColors.surface.opacity(0.86),
      in: RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius)
    )
    .overlay {
      RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius)
        .stroke(AppColors.border, lineWidth: 1)
    }
  }

  private var spacesSection: some View {
    VStack(alignment: .leading, spacing: AppSpacing.s) {
      Text("Starter Spaces")
        .font(AppTypography.cardTitle)
        .foregroundStyle(AppColors.textPrimary)

      VStack(spacing: 0) {
        ForEach(viewModel.spaces) { space in
          spaceRow(space)

          if space.id != viewModel.spaces.last?.id {
            Divider()
              .overlay(AppColors.border)
              .padding(.leading, 56)
          }
        }
      }
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

  private var contextPacksLink: some View {
    NavigationLink {
      ContextPacksView(viewModel: contextPacksViewModel)
    } label: {
      HStack(spacing: AppSpacing.m) {
        SettingsIcon(symbol: AppIcons.contextPack)

        VStack(alignment: .leading, spacing: AppSpacing.xs) {
          Text("Context Packs")
            .font(AppTypography.bodyEmphasis)
            .foregroundStyle(AppColors.textPrimary)

          Text("Collect Drifts into local context you can copy when you choose.")
            .font(AppTypography.caption)
            .foregroundStyle(AppColors.textSecondary)
            .fixedSize(horizontal: false, vertical: true)
        }

        Spacer(minLength: AppSpacing.s)

        Image(systemName: AppIcons.chevronRight)
          .font(.caption)
          .foregroundStyle(AppColors.textTertiary)
      }
      .padding(AppSpacing.m)
      .background(
        AppColors.surface.opacity(0.84),
        in: RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius)
      )
      .overlay {
        RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius)
          .stroke(AppColors.border, lineWidth: 1)
      }
      .contentShape(RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius))
    }
    .buttonStyle(.plain)
  }

  private func spaceRow(_ space: DriftSpace) -> some View {
    HStack(spacing: AppSpacing.m) {
      SettingsIcon(symbol: space.icon)

      VStack(alignment: .leading, spacing: AppSpacing.xs) {
        HStack(spacing: AppSpacing.xs) {
          Text(space.name)
            .font(AppTypography.bodyEmphasis)
            .foregroundStyle(AppColors.textPrimary)

          if space.isPinned {
            Image(systemName: "pin.fill")
              .font(.caption2)
              .foregroundStyle(AppColors.accent)
              .accessibilityLabel("Pinned")
          }
        }

        Text(space.description)
          .font(AppTypography.caption)
          .foregroundStyle(AppColors.textSecondary)
          .fixedSize(horizontal: false, vertical: true)
      }

      Spacer()
    }
    .padding(AppSpacing.m)
    .accessibilityElement(children: .combine)
  }
}

#Preview {
  NavigationStack {
    SpacesView(
      viewModel: SpacesViewModel(),
      contextPacksViewModel: ContextPacksViewModel(
        driftRepository: JournalBackedDriftRepository(
          journalRepository: PreviewJournalRepository()
        ),
        contextPackService: LocalContextPackService(),
        contextExportService: LocalContextExportService()
      )
    )
  }
}
