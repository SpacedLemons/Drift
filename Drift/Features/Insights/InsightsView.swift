//
//  InsightsView.swift
//  Drift
//
//  Created by Lucas Stuart West Rogers on 12/05/2026.
//

import Charts
import SwiftUI

struct InsightsView: View {
  @State private var viewModel: InsightsViewModel

  let reloadToken: UUID

  init(
    viewModel: InsightsViewModel,
    reloadToken: UUID
  ) {
    _viewModel = State(initialValue: viewModel)
    self.reloadToken = reloadToken
  }

  var body: some View {
    ZStack {
      AppTheme.backgroundGradient
        .ignoresSafeArea()

      ScrollView {
        VStack(alignment: .leading, spacing: AppSpacing.l) {
          header

          if viewModel.isLoading {
            ProgressView()
              .tint(AppColors.accent)
              .frame(maxWidth: .infinity, minHeight: 180)
          } else if let errorMessage = viewModel.errorMessage {
            EmptyStateView(
              title: "Insights unavailable",
              message: errorMessage,
              icon: AppIcons.chart
            )
          } else if viewModel.entries.isEmpty {
            EmptyStateView(
              title: "No insights yet",
              message: "Insights will appear once you have a few entries.",
              icon: AppIcons.chart
            )
          } else {
            content
          }
        }
        .padding(AppSpacing.l)
      }
    }
    .navigationTitle("Insights")
    .task(id: reloadToken) {
      await viewModel.load()
    }
  }

  private var header: some View {
    VStack(alignment: .leading, spacing: AppSpacing.s) {
      Text("Insights")
        .font(AppTypography.appTitle)
        .foregroundStyle(AppColors.textPrimary)

      Text("Local patterns from your journal entries.")
        .font(AppTypography.body)
        .foregroundStyle(AppColors.textSecondary)
    }
  }

  private var content: some View {
    VStack(alignment: .leading, spacing: AppSpacing.l) {
      sectionTitle("Weekly overview")

      HStack(spacing: AppSpacing.s) {
        insightCard(
          title: "This week",
          value: "\(viewModel.summary.entriesThisWeek)",
          icon: AppIcons.calendar
        )

        insightCard(
          title: "Streak",
          value: "\(viewModel.summary.currentStreak)d",
          icon: AppIcons.checkmark
        )
      }

      HStack(spacing: AppSpacing.s) {
        insightCard(
          title: "Total entries",
          value: "\(viewModel.summary.totalEntries)",
          icon: AppIcons.book
        )

        insightCard(
          title: "Common mood",
          value: viewModel.summary.mostCommonMood?.displayName ?? "None",
          icon: AppIcons.mood
        )
      }

      moodTrendSection
      moodSection
      themesSection
    }
  }

  private var moodTrendSection: some View {
    VStack(alignment: .leading, spacing: AppSpacing.s) {
      HStack {
        sectionTitle("Mood trend")

        Spacer()

        Picker("Mood trend range", selection: moodTrendRangeBinding) {
          ForEach(MoodTrendRange.allCases) { range in
            Text(range.title).tag(range)
          }
        }
        .pickerStyle(.segmented)
        .frame(maxWidth: 210)
      }

      VStack(alignment: .leading, spacing: AppSpacing.m) {
        if viewModel.summary.moodTrend.count < 2 {
          EmptyStateView(
            title: "Mood trend needs more entries",
            message: "Save at least two entries with moods to see a local trend.",
            icon: AppIcons.chartLine
          )
          .padding(.vertical, AppSpacing.s)
        } else {
          Chart(viewModel.summary.moodTrend) { point in
            LineMark(
              x: .value("Date", point.date),
              y: .value("Mood", point.score)
            )
            .interpolationMethod(.catmullRom)
            .foregroundStyle(AppColors.accent)
            .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round))

            PointMark(
              x: .value("Date", point.date),
              y: .value("Mood", point.score)
            )
            .foregroundStyle(AppColors.accentSecondary)
          }
          .chartYScale(domain: 1...5)
          .chartYAxis {
            AxisMarks(values: [1, 3, 5]) { value in
              AxisGridLine()
                .foregroundStyle(AppColors.border)
              AxisValueLabel {
                if let score = value.as(Int.self) {
                  Text(moodAxisLabel(for: score))
                    .foregroundStyle(AppColors.textTertiary)
                }
              }
            }
          }
          .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: 4)) {
              AxisGridLine()
                .foregroundStyle(AppColors.border.opacity(0.5))
              AxisValueLabel()
                .foregroundStyle(AppColors.textTertiary)
            }
          }
          .frame(height: 180)

          Text("A simple local mood direction, not a mental health score.")
            .font(AppTypography.caption)
            .foregroundStyle(AppColors.textTertiary)
        }
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
  }

  private var moodSection: some View {
    VStack(alignment: .leading, spacing: AppSpacing.s) {
      sectionTitle("Mood")

      VStack(alignment: .leading, spacing: AppSpacing.s) {
        HStack {
          Text("Most common")
            .font(AppTypography.bodyEmphasis)
            .foregroundStyle(AppColors.textPrimary)
          Spacer()
          MoodPill(mood: viewModel.summary.mostCommonMood)
        }

        Text("Mood trend uses local saved entries only.")
          .font(AppTypography.body)
          .foregroundStyle(AppColors.textSecondary)
      }
      .padding(AppSpacing.m)
      .background(
        AppColors.surface.opacity(0.84),
        in: RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius)
      )
      .accessibilityElement(children: .contain)
      .accessibilityLabel("Mood insights")
    }
  }

  private var themesSection: some View {
    VStack(alignment: .leading, spacing: AppSpacing.s) {
      sectionTitle("Themes")

      VStack(alignment: .leading, spacing: AppSpacing.s) {
        HStack {
          Text("Most common")
            .font(AppTypography.bodyEmphasis)
            .foregroundStyle(AppColors.textPrimary)
          Spacer()
          Text(viewModel.summary.mostCommonThemeName ?? "None")
            .font(AppTypography.caption)
            .foregroundStyle(AppColors.textSecondary)
            .padding(.horizontal, AppSpacing.s)
            .padding(.vertical, AppSpacing.xs)
            .background(AppColors.surfaceRaised, in: Capsule())
        }

        FlowLayout(spacing: AppSpacing.xs) {
          ForEach(viewModel.summary.recentThemeNames, id: \.self) { theme in
            Label(theme, systemImage: AppIcons.tag)
              .font(AppTypography.caption)
              .foregroundStyle(AppColors.textSecondary)
              .padding(.horizontal, AppSpacing.s)
              .padding(.vertical, AppSpacing.xs)
              .background(AppColors.surfaceRaised, in: Capsule())
              .accessibilityLabel("Recent theme \(theme)")
          }
        }
      }
      .padding(AppSpacing.m)
      .background(
        AppColors.surface.opacity(0.84),
        in: RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius)
      )
      .accessibilityElement(children: .contain)
      .accessibilityLabel("Theme insights")
    }
  }

  private func insightCard(title: String, value: String, icon: String) -> some View {
    VStack(alignment: .leading, spacing: AppSpacing.s) {
      Image(systemName: icon)
        .font(.system(size: 18, weight: .semibold))
        .foregroundStyle(AppColors.accent)

      Text(value)
        .font(AppTypography.screenTitle)
        .foregroundStyle(AppColors.textPrimary)
        .lineLimit(1)

      Text(title)
        .font(AppTypography.caption)
        .foregroundStyle(AppColors.textSecondary)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(AppSpacing.m)
    .background(
      AppColors.surface.opacity(0.84), in: RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius)
    )
    .accessibilityElement(children: .combine)
    .accessibilityLabel("\(title): \(value)")
  }

  private func sectionTitle(_ title: String) -> some View {
    Text(title)
      .font(AppTypography.cardTitle)
      .foregroundStyle(AppColors.textPrimary)
  }

  private var moodTrendRangeBinding: Binding<MoodTrendRange> {
    Binding(
      get: { viewModel.selectedMoodTrendRange },
      set: viewModel.selectMoodTrendRange
    )
  }

  private func moodAxisLabel(for score: Int) -> String {
    switch score {
    case 1: "Low"
    case 3: "Neutral"
    case 5: "Positive"
    default: ""
    }
  }
}

#Preview {
  InsightsView(
    viewModel: InsightsViewModel(
      journalRepository: PreviewJournalRepository(),
      now: { PreviewData.baseDate }
    ),
    reloadToken: UUID()
  )
}
