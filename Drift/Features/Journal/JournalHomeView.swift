//
//  JournalHomeView.swift
//  Drift
//
//  Created by Lucas Stuart West Rogers on 12/05/2026.
//

import SwiftUI

struct JournalHomeView: View {
  @State private var viewModel: JournalHomeViewModel

  let reloadToken: UUID
  let onEntrySelected: (JournalEntry) -> Void
  let onRecordTapped: () -> Void

  init(
    viewModel: JournalHomeViewModel,
    reloadToken: UUID = UUID(),
    onEntrySelected: @escaping (JournalEntry) -> Void,
    onRecordTapped: @escaping () -> Void
  ) {
    _viewModel = State(initialValue: viewModel)
    self.reloadToken = reloadToken
    self.onEntrySelected = onEntrySelected
    self.onRecordTapped = onRecordTapped
  }

  var body: some View {
    ZStack(alignment: .bottomTrailing) {
      AppTheme.backgroundGradient
        .ignoresSafeArea()

      ScrollView {
        VStack(alignment: .leading, spacing: AppSpacing.l) {
          header

          filterPills

          if viewModel.shouldShowFirstRunIntro {
            firstRunIntroCard
          }

          entryContent
        }
        .padding(.horizontal, AppSpacing.m)
        .padding(.top, AppSpacing.l)
        .padding(.bottom, AppSpacing.xxl * 2)
      }

      FloatingRecordButton(action: onRecordTapped)
        .padding(.trailing, AppSpacing.l)
        .padding(.bottom, AppSpacing.l)
    }
    .navigationBarTitleDisplayMode(.inline)
    .task(id: reloadToken) {
      await viewModel.load()
    }
  }

  private var header: some View {
    VStack(alignment: .leading, spacing: AppSpacing.s) {
      HStack(alignment: .firstTextBaseline) {
        Text("Drift")
          .font(AppTypography.appTitle)
          .foregroundStyle(AppColors.textPrimary)
          .accessibilityAddTraits(.isHeader)

        Spacer()

        Image(systemName: AppIcons.shield)
          .font(.system(size: 18, weight: .semibold))
          .foregroundStyle(AppColors.accentSecondary)
          .frame(width: 38, height: 38)
          .background(AppColors.accentSecondary.opacity(0.12), in: Circle())
          .accessibilityLabel("Private local Drifts")
      }

      Text("Let your thoughts Drift")
        .font(AppTypography.body)
        .foregroundStyle(AppColors.textSecondary)
        .fixedSize(horizontal: false, vertical: true)
    }
  }

  private var filterPills: some View {
    VStack(alignment: .leading, spacing: AppSpacing.s) {
      Text("Filter Drifts")
        .font(AppTypography.caption)
        .foregroundStyle(AppColors.textSecondary)

      ScrollView(.horizontal, showsIndicators: false) {
        HStack(spacing: AppSpacing.xs) {
          filterButton(title: "All", icon: AppIcons.waveform, driftType: nil)

          ForEach(viewModel.driftTypeFilters) { driftType in
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
  private var entryContent: some View {
    if viewModel.isLoading {
      ProgressView()
        .tint(AppColors.accent)
        .frame(maxWidth: .infinity, minHeight: 160)
    } else if let errorMessage = viewModel.errorMessage {
      EmptyStateView(
        title: "Drifts unavailable",
        message: errorMessage,
        icon: AppIcons.waveform
      )
    } else if viewModel.visibleEntries.isEmpty {
      EmptyStateView(
        title: emptyEntriesTitle,
        message: emptyEntriesMessage,
        icon: AppIcons.mic
      )
    } else {
      VStack(alignment: .leading, spacing: AppSpacing.m) {
        Text("Recent Drifts")
          .font(AppTypography.cardTitle)
          .foregroundStyle(AppColors.textPrimary)

        ForEach(viewModel.visibleEntries) { entry in
          Button(
            action: {
              onEntrySelected(entry)
            },
            label: {
              JournalCard(entry: entry)
            }
          )
          .buttonStyle(.plain)
        }
      }
    }
  }

  private var emptyEntriesTitle: String {
    if viewModel.entries.isEmpty {
      return "No Drifts yet."
    }

    return "No matching Drifts."
  }

  private var emptyEntriesMessage: String {
    if viewModel.entries.isEmpty {
      return "Tap the microphone when you are ready to capture a thought."
    }

    return "Try another Drift Type."
  }

  private var firstRunIntroCard: some View {
    VStack(alignment: .leading, spacing: AppSpacing.s) {
      Label("Private voice capture", systemImage: AppIcons.shield)
        .font(AppTypography.cardTitle)
        .foregroundStyle(AppColors.textPrimary)

      Text(
        "Drifts stay on this device and no account is needed. Drift needs microphone access so you can capture thoughts by voice. Speech recognition turns your voice into text. Reminders are optional."
      )
      .font(AppTypography.body)
      .foregroundStyle(AppColors.textSecondary)
      .fixedSize(horizontal: false, vertical: true)
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
    .accessibilityElement(children: .combine)
  }
}

#Preview("Preview Drifts") {
  NavigationStack {
    JournalHomeView(
      viewModel: JournalHomeViewModel(
        journalRepository: PreviewJournalRepository()
      ),
      onEntrySelected: { _ in },
      onRecordTapped: {}
    )
  }
}

#Preview("Empty") {
  NavigationStack {
    JournalHomeView(
      viewModel: JournalHomeViewModel(
        journalRepository: PreviewJournalRepository(entries: [])
      ),
      onEntrySelected: { _ in },
      onRecordTapped: {}
    )
  }
}
