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
  let moodGraphViewModel: InsightsViewModel?
  let moodGraphReloadToken: UUID
  let onEntrySelected: (JournalEntry) -> Void

  init(
    viewModel: TimelineViewModel,
    reloadToken: UUID = UUID(),
    moodGraphViewModel: InsightsViewModel? = nil,
    moodGraphReloadToken: UUID = UUID(),
    onEntrySelected: @escaping (JournalEntry) -> Void
  ) {
    _viewModel = State(initialValue: viewModel)
    self.reloadToken = reloadToken
    self.moodGraphViewModel = moodGraphViewModel
    self.moodGraphReloadToken = moodGraphReloadToken
    self.onEntrySelected = onEntrySelected
  }

  var body: some View {
    ZStack {
      AppTheme.backgroundGradient
        .ignoresSafeArea()

      ScrollView {
        VStack(alignment: .leading, spacing: AppSpacing.l) {
          header

          CalendarStripView(
            compactDays: viewModel.dateStripDays,
            selectedDate: viewModel.selectedDate,
            selectedMonthTitle: viewModel.selectedMonthTitle,
            weekdaySymbols: viewModel.weekdaySymbols,
            calendarDays: viewModel.calendarDays,
            isExpanded: viewModel.isCalendarExpanded,
            toggleExpansion: viewModel.toggleCalendarExpansion,
            selectDate: viewModel.selectDate,
            moveMonth: viewModel.moveSelectedMonth,
            dateHasEntries: viewModel.dateHasEntries
          )

          filterPills
          moodGraphLink
          timelineContent
        }
        .padding(AppSpacing.l)
      }
    }
    .navigationTitle("Timeline")
    .navigationBarTitleDisplayMode(.inline)
    .task(id: reloadToken) {
      await viewModel.load()
    }
  }

  private var header: some View {
    VStack(alignment: .leading, spacing: AppSpacing.s) {
      Text("Timeline")
        .font(AppTypography.appTitle)
        .foregroundStyle(AppColors.textPrimary)
        .accessibilityAddTraits(.isHeader)

      Text("Browse historical Drifts by date and type.")
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
  private var moodGraphLink: some View {
    if let moodGraphViewModel {
      NavigationLink {
        InsightsView(
          viewModel: moodGraphViewModel,
          reloadToken: moodGraphReloadToken
        )
      } label: {
        HStack(spacing: AppSpacing.m) {
          Image(systemName: AppIcons.chartLine)
            .font(.system(size: 18, weight: .semibold))
            .foregroundStyle(AppColors.accentSecondary)
            .frame(width: 40, height: 40)
            .background(AppColors.accentSecondary.opacity(0.14), in: Circle())

          VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text("Mood history")
              .font(AppTypography.bodyEmphasis)
              .foregroundStyle(AppColors.textPrimary)

            Text("View local mood patterns from saved Drifts.")
              .font(AppTypography.caption)
              .foregroundStyle(AppColors.textSecondary)
          }

          Spacer()

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
      }
      .buttonStyle(.plain)
    }
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
        journalRepository: PreviewJournalRepository(),
        now: { PreviewData.baseDate }
      ),
      moodGraphViewModel: InsightsViewModel(
        journalRepository: PreviewJournalRepository(),
        now: { PreviewData.baseDate }
      ),
      onEntrySelected: { _ in }
    )
  }
}
