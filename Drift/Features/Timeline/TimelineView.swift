//
//  TimelineView.swift
//  Drift
//
//  Created by Lucas Stuart West Rogers on 23/05/2026.
//

import SwiftUI

struct TimelineView: View {
  @State private var viewModel: TimelineViewModel

  let reloadToken: UUID
  let onEntrySelected: (JournalEntry) -> Void

  init(
    viewModel: TimelineViewModel,
    reloadToken: UUID = UUID(),
    onEntrySelected: @escaping (JournalEntry) -> Void
  ) {
    _viewModel = State(initialValue: viewModel)
    self.reloadToken = reloadToken
    self.onEntrySelected = onEntrySelected
  }

  var body: some View {
    ZStack {
      AppTheme.backgroundGradient
        .ignoresSafeArea()

      ScrollView {
        VStack(alignment: .leading, spacing: AppSpacing.l) {
          header
          filterPills
          timelineContent
        }
        .padding(AppSpacing.l)
      }
    }
    .navigationTitle("Timeline")
    .navigationBarTitleDisplayMode(.large)
    .task(id: reloadToken) {
      await viewModel.load()
    }
  }

  private var header: some View {
    VStack(alignment: .leading, spacing: AppSpacing.s) {
      Text("Browse historical Drifts by type.")
        .font(AppTypography.body)
        .foregroundStyle(AppColors.textSecondary)
    }
  }

  private var filterPills: some View {
    VStack(alignment: .leading, spacing: AppSpacing.s) {
      Text("Drift Type")
        .font(AppTypography.caption)
        .foregroundStyle(AppColors.textSecondary)

      ScrollView(.horizontal, showsIndicators: false) {
        HStack(spacing: AppSpacing.xs) {
          filterButton(title: "All", icon: AppIcons.clock, driftType: nil)

          ForEach(DriftType.allCases) { driftType in
            filterButton(
              title: driftType.displayName,
              icon: driftType.symbolName,
              driftType: driftType
            )
          }
        }
      }
    }
  }

  private func filterButton(
    title: String,
    icon: String,
    driftType: DriftType?
  ) -> some View {
    let isSelected = viewModel.selectedDriftTypeFilter == driftType

    return Button {
      withAnimation(AppAnimation.gentle) {
        viewModel.selectDriftTypeFilter(driftType)
      }
    } label: {
      Label(title, systemImage: icon)
        .font(AppTypography.caption)
        .foregroundStyle(isSelected ? AppColors.textPrimary : AppColors.textSecondary)
        .padding(.horizontal, AppSpacing.s)
        .padding(.vertical, AppSpacing.xs)
        .background(
          isSelected ? AppColors.accent.opacity(0.22) : AppColors.surfaceRaised,
          in: Capsule()
        )
        .overlay {
          Capsule()
            .stroke(isSelected ? AppColors.accent : AppColors.border, lineWidth: 1)
        }
    }
    .buttonStyle(.plain)
    .accessibilityAddTraits(isSelected ? .isSelected : [])
  }

  @ViewBuilder
  private var timelineContent: some View {
    if viewModel.isLoading {
      ProgressView()
        .tint(AppColors.accent)
        .frame(maxWidth: .infinity, minHeight: 180)
    } else if let errorMessage = viewModel.errorMessage {
      EmptyStateView(
        title: "Timeline unavailable",
        message: errorMessage,
        icon: AppIcons.clock
      )
    } else if viewModel.visibleEntries.isEmpty {
      EmptyStateView(
        title: "No Drifts here",
        message: "Choose another date or Drift Type.",
        icon: AppIcons.clock
      )
    } else {
      VStack(spacing: AppSpacing.m) {
        ForEach(viewModel.visibleEntries) { entry in
          Button {
            onEntrySelected(entry)
          } label: {
            JournalCard(entry: entry)
          }
          .buttonStyle(.plain)
        }
      }
    }
  }
}

#Preview {
  NavigationStack {
    TimelineView(
      viewModel: TimelineViewModel(
        journalRepository: PreviewJournalRepository()
      ),
      onEntrySelected: { _ in }
    )
  }
}
