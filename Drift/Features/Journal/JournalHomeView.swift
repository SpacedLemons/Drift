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

          SearchBar(
            text: Binding(
              get: { viewModel.searchQuery },
              set: viewModel.applySearchQuery
            )
          )

          CalendarStripView(
            compactDays: viewModel.dateStripDays,
            selectedDate: viewModel.selectedDate,
            selectedMonthTitle: viewModel.selectedMonthTitle,
            weekdaySymbols: viewModel.weekdaySymbols,
            calendarDays: viewModel.calendarDays,
            isExpanded: viewModel.isCalendarExpanded,
            toggleExpansion: viewModel.toggleCalendarExpansion,
            selectDate: viewModel.selectDate,
            moveMonth: viewModel.moveSelectedMonth
          )

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
          .accessibilityLabel("Private local journal")
      }

      Text("Your entries are stored on this device. No account is required.")
        .font(AppTypography.body)
        .foregroundStyle(AppColors.textSecondary)
        .fixedSize(horizontal: false, vertical: true)
    }
  }

  @ViewBuilder
  private var entryContent: some View {
    if viewModel.isLoading {
      ProgressView()
        .tint(AppColors.accent)
        .frame(maxWidth: .infinity, minHeight: 160)
    } else if let errorMessage = viewModel.errorMessage {
      EmptyStateView(
        title: "Entries unavailable",
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
      VStack(spacing: AppSpacing.m) {
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
      return "No entries yet."
    }

    if viewModel.selectedDateHasNoEntries {
      return "No entries for this date."
    }

    return "No matching entries."
  }

  private var emptyEntriesMessage: String {
    if viewModel.entries.isEmpty {
      return "Tap the microphone when you are ready to capture a thought."
    }

    if viewModel.selectedDateHasNoEntries {
      return "Choose another date or tap the microphone when you are ready."
    }

    return "Try another word or phrase."
  }

  private var firstRunIntroCard: some View {
    VStack(alignment: .leading, spacing: AppSpacing.s) {
      Label("Private voice journal", systemImage: AppIcons.shield)
        .font(AppTypography.cardTitle)
        .foregroundStyle(AppColors.textPrimary)

      Text(
        "Entries stay on this device and no account is needed. Drift needs microphone access so you can record voice journal entries. Drift uses speech recognition to turn your voice journal entries into text. Reminders are optional."
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

#Preview("Preview entries") {
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
