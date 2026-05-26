//
//  JournalHomeView.swift
//  Drift
//
//  Created by Lucas Stuart West Rogers on 12/05/2026.
//

import SwiftUI

struct JournalHomeView: View {
  @State private var viewModel: JournalHomeViewModel
  @State private var isSearchPresented = false
  @State private var isCalendarPresented = true

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
    @Bindable var bindableViewModel = viewModel

    ZStack(alignment: .bottomTrailing) {
      AppTheme.backgroundGradient
        .ignoresSafeArea()

      ScrollView {
        VStack(alignment: .leading, spacing: AppSpacing.l) {
          header

          if isSearchPresented {
            SearchBar(
              text: $bindableViewModel.searchText,
              placeholder: "Search your Drifts"
            )
            .transition(.move(edge: .top).combined(with: .opacity))
          }

          if isCalendarPresented {
            calendarSection
              .transition(.move(edge: .top).combined(with: .opacity))
          }

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
      .animation(AppAnimation.gentle, value: viewModel.visibleEntries.map(\.id))

      FloatingRecordButton(action: onRecordTapped)
        .padding(.trailing, AppSpacing.l)
        .padding(.bottom, AppSpacing.l)
    }
    .navigationTitle("Drift")
    .navigationBarTitleDisplayMode(.large)
    .toolbar {
      ToolbarItem(placement: .topBarTrailing) {
        toolbarButtons
      }
    }
    .task(id: reloadToken) {
      await viewModel.load()
    }
    .animation(AppAnimation.gentle, value: isSearchPresented)
    .animation(AppAnimation.gentle, value: isCalendarPresented)
  }

  private var header: some View {
    VStack(alignment: .leading, spacing: AppSpacing.s) {
      Text("Let your thoughts Drift.")
        .font(AppTypography.body)
        .foregroundStyle(AppColors.textSecondary)
        .fixedSize(horizontal: false, vertical: true)
    }
  }

  private var calendarSection: some View {
    CalendarStripView(
      compactDays: viewModel.dateStripDays,
      selectedDate: viewModel.selectedDate,
      selectedMonthTitle: viewModel.selectedMonthTitle,
      selectedMonthID: viewModel.selectedMonthID,
      monthTransitionDirection: viewModel.monthTransitionDirection,
      weekdaySymbols: viewModel.weekdaySymbols,
      calendarDays: viewModel.calendarDays,
      isExpanded: viewModel.isCalendarExpanded,
      toggleExpansion: viewModel.toggleCalendarExpansion,
      selectDate: viewModel.selectDate,
      moveMonth: viewModel.moveSelectedMonth,
      dateHasEntries: viewModel.dateHasEntries
    )
    .padding(.horizontal, AppSpacing.xs)
    .padding(.vertical, AppSpacing.xs)
    .background(
      AppColors.surface.opacity(0.72),
      in: RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius)
    )
    .overlay {
      RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius)
        .stroke(AppColors.border, lineWidth: 1)
    }
  }

  @ViewBuilder
  private var toolbarButtons: some View {
    if #available(iOS 26.0, *) {
      GlassEffectContainer(spacing: AppSpacing.xs) {
        HStack(spacing: AppSpacing.xs) {
          toolbarButton(
            systemImage: AppIcons.search,
            isSelected: isSearchPresented,
            accessibilityLabel: isSearchPresented ? "Hide search" : "Show search",
            action: toggleSearch
          )

          toolbarButton(
            systemImage: AppIcons.calendar,
            isSelected: isCalendarPresented,
            accessibilityLabel: isCalendarPresented ? "Hide calendar" : "Show calendar",
            action: toggleCalendarVisibility
          )
        }
      }
    } else {
      HStack(spacing: AppSpacing.xs) {
        toolbarButton(
          systemImage: AppIcons.search,
          isSelected: isSearchPresented,
          accessibilityLabel: isSearchPresented ? "Hide search" : "Show search",
          action: toggleSearch
        )

        toolbarButton(
          systemImage: AppIcons.calendar,
          isSelected: isCalendarPresented,
          accessibilityLabel: isCalendarPresented ? "Hide calendar" : "Show calendar",
          action: toggleCalendarVisibility
        )
      }
    }
  }

  @ViewBuilder
  private func toolbarButton(
    systemImage: String,
    isSelected: Bool,
    accessibilityLabel: String,
    action: @escaping () -> Void
  ) -> some View {
    if #available(iOS 26.0, *) {
      Button(action: action) {
        toolbarButtonIcon(systemImage: systemImage, isSelected: isSelected)
      }
      .buttonStyle(.plain)
      .glassEffect(
        .regular.tint(toolbarButtonTint(isSelected: isSelected)).interactive(),
        in: .rect(cornerRadius: 19)
      )
      .accessibilityLabel(accessibilityLabel)
      .accessibilityAddTraits(isSelected ? .isSelected : [])
    } else {
      Button(action: action) {
        toolbarButtonIcon(systemImage: systemImage, isSelected: isSelected)
          .background(
            isSelected ? AppColors.accent.opacity(0.18) : AppColors.surfaceRaised.opacity(0.86),
            in: Circle()
          )
          .overlay {
            Circle()
              .stroke(isSelected ? AppColors.accent.opacity(0.42) : AppColors.border, lineWidth: 1)
          }
      }
      .buttonStyle(.plain)
      .accessibilityLabel(accessibilityLabel)
      .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
  }

  private func toolbarButtonIcon(systemImage: String, isSelected: Bool) -> some View {
    Image(systemName: systemImage)
      .font(.system(size: 16, weight: .semibold))
      .foregroundStyle(isSelected ? AppColors.accent : AppColors.textPrimary)
      .frame(width: 38, height: 38)
      .contentShape(Circle())
  }

  private func toolbarButtonTint(isSelected: Bool) -> Color {
    isSelected ? AppColors.accent.opacity(0.18) : AppColors.surface.opacity(0.44)
  }

  private func toggleSearch() {
    withAnimation(AppAnimation.gentle) {
      isSearchPresented.toggle()
      if !isSearchPresented {
        viewModel.searchText = ""
      }
    }
  }

  private func toggleCalendarVisibility() {
    withAnimation(AppAnimation.gentle) {
      isCalendarPresented.toggle()
      if !isCalendarPresented && viewModel.isCalendarExpanded {
        viewModel.toggleCalendarExpansion()
      }
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
        title: viewModel.emptyEntriesTitle,
        message: viewModel.emptyEntriesMessage,
        icon: AppIcons.mic
      )
    } else {
      VStack(alignment: .leading, spacing: AppSpacing.m) {
        Text(viewModel.visibleEntriesSectionTitle)
          .font(AppTypography.cardTitle)
          .foregroundStyle(AppColors.textPrimary)

        ForEach(viewModel.visibleEntries) { entry in
          Button(
            action: {
              onEntrySelected(entry)
            },
            label: {
              JournalCard(
                entry: entry,
                spaceNames: viewModel.spaceNames(for: entry)
              )
            }
          )
          .buttonStyle(.plain)
        }
      }
    }
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
