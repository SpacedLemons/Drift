//
//  JournalDateStripView.swift
//  Drift
//
//  Created by Lucas Stuart West Rogers on 12/05/2026.
//

import SwiftUI

struct CalendarStripView: View {
  let compactDays: [Date]
  let selectedDate: Date?
  let selectedMonthTitle: String
  let weekdaySymbols: [String]
  let calendarDays: [CalendarDayState]
  let isExpanded: Bool
  let toggleExpansion: () -> Void
  let selectDate: (Date?) -> Void
  let moveMonth: (Int) -> Void

  @Namespace private var selectionNamespace

  private let calendar = Calendar.current
  private let selectionGeometryID = "calendar-selected-day"
  private let compactStripHeight: CGFloat = 62

  var body: some View {
    VStack(alignment: .leading, spacing: AppSpacing.s) {
      calendarHeader
      compactDateStrip
        .opacity(isExpanded ? 0 : 1)
        .scaleEffect(x: 1, y: isExpanded ? 0.96 : 1, anchor: .top)
        .frame(height: isExpanded ? 0 : compactStripHeight, alignment: .top)
        .clipped(antialiased: true)
        .allowsHitTesting(!isExpanded)
        .accessibilityHidden(isExpanded)

      if isExpanded {
        MonthCalendarView(
          selectedMonthTitle: selectedMonthTitle,
          weekdaySymbols: weekdaySymbols,
          calendarDays: calendarDays,
          selectionNamespace: selectionNamespace,
          selectionGeometryID: selectionGeometryID,
          selectionIsSource: isExpanded,
          selectDate: selectDate,
          moveMonth: moveMonth
        )
        .transition(.opacity.combined(with: .scale(scale: 0.98, anchor: .top)))
      }
    }
    .animation(AppAnimation.gentle, value: isExpanded)
  }

  private var calendarHeader: some View {
    HStack(spacing: AppSpacing.xs) {
      Image(systemName: AppIcons.calendar)
        .font(.caption)
        .foregroundStyle(AppColors.accentSecondary)

      Text(isExpanded ? "Calendar" : "Recent days")
        .font(AppTypography.caption)
        .foregroundStyle(AppColors.textSecondary)

      Spacer()

      Button(
        action: {
          withAnimation(AppAnimation.gentle) {
            toggleExpansion()
          }
        },
        label: {
          Image(systemName: isExpanded ? AppIcons.chevronUp : AppIcons.chevronDown)
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(AppColors.textPrimary)
            .frame(width: 34, height: 34)
            .background(AppColors.surface, in: Circle())
        }
      )
      .buttonStyle(.plain)
      .accessibilityLabel(isExpanded ? "Collapse calendar" : "Expand calendar")
    }
  }

  private var compactDateStrip: some View {
    ScrollView(.horizontal, showsIndicators: false) {
      HStack(spacing: AppSpacing.s) {
        ForEach(compactDays, id: \.self) { day in
          Button(
            action: {
              withAnimation(AppAnimation.gentle) {
                selectDate(day)
              }
            },
            label: {
              compactDateCell(for: day)
            }
          )
          .buttonStyle(.plain)
        }
      }
      .padding(.vertical, 1)
    }
  }

  private func compactDateCell(for day: Date) -> some View {
    let isSelected = selectedDate.map { calendar.isDate($0, inSameDayAs: day) } ?? false

    return ZStack {
      RoundedRectangle(cornerRadius: AppTheme.controlCornerRadius)
        .fill(AppColors.surface)

      if isSelected {
        RoundedRectangle(cornerRadius: AppTheme.controlCornerRadius)
          .fill(AppColors.accent)
          .matchedGeometryEffect(
            id: selectionGeometryID,
            in: selectionNamespace,
            properties: .frame,
            isSource: !isExpanded
          )
      }

      VStack(spacing: AppSpacing.xs) {
        Text(day, format: .dateTime.weekday(.narrow))
          .font(AppTypography.caption)
          .foregroundStyle(isSelected ? .white : AppColors.textTertiary)

        Text(day, format: .dateTime.day())
          .font(.system(.headline, design: .rounded, weight: .semibold))
          .foregroundStyle(isSelected ? .white : AppColors.textPrimary)
      }
    }
    .frame(width: 48, height: 60)
    .overlay {
      RoundedRectangle(cornerRadius: AppTheme.controlCornerRadius)
        .stroke(isSelected ? AppColors.accent.opacity(0.4) : AppColors.border, lineWidth: 1)
    }
    .accessibilityLabel(day.formatted(date: .complete, time: .omitted))
    .accessibilityValue(isSelected ? "Selected" : "Not selected")
  }
}

private struct MonthCalendarView: View {
  let selectedMonthTitle: String
  let weekdaySymbols: [String]
  let calendarDays: [CalendarDayState]
  let selectionNamespace: Namespace.ID
  let selectionGeometryID: String
  let selectionIsSource: Bool
  let selectDate: (Date?) -> Void
  let moveMonth: (Int) -> Void

  private let columns = Array(
    repeating: GridItem(.flexible(), spacing: AppSpacing.xs),
    count: 7
  )

  var body: some View {
    VStack(alignment: .leading, spacing: AppSpacing.m) {
      CalendarMonthHeader(
        selectedMonthTitle: selectedMonthTitle,
        moveMonth: moveMonth
      )

      LazyVGrid(columns: columns, spacing: AppSpacing.xs) {
        ForEach(Array(weekdaySymbols.enumerated()), id: \.offset) { _, symbol in
          Text(symbol)
            .font(AppTypography.caption)
            .foregroundStyle(AppColors.textTertiary)
            .frame(maxWidth: .infinity)
        }

        ForEach(calendarDays) { day in
          CalendarDayCell(
            day: day,
            selectionNamespace: selectionNamespace,
            selectionGeometryID: selectionGeometryID,
            selectionIsSource: selectionIsSource,
            selectDate: selectDate
          )
        }
      }
    }
    .padding(AppSpacing.m)
    .background(
      AppColors.surface.opacity(0.72),
      in: RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius)
    )
    .overlay {
      RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius)
        .stroke(AppColors.border, lineWidth: 1)
    }
    .gesture(
      DragGesture(minimumDistance: 32)
        .onEnded { value in
          if value.translation.width < -40 {
            moveMonth(1)
          } else if value.translation.width > 40 {
            moveMonth(-1)
          }
        }
    )
  }
}

private struct CalendarMonthHeader: View {
  let selectedMonthTitle: String
  let moveMonth: (Int) -> Void

  var body: some View {
    HStack {
      Button(
        action: {
          moveMonth(-1)
        },
        label: {
          Image(systemName: AppIcons.chevronLeft)
            .font(.system(size: 14, weight: .semibold))
            .frame(width: 34, height: 34)
        }
      )
      .buttonStyle(.plain)
      .accessibilityLabel("Previous month")

      Spacer()

      Text(selectedMonthTitle)
        .font(AppTypography.cardTitle)
        .foregroundStyle(AppColors.textPrimary)
        .accessibilityAddTraits(.isHeader)

      Spacer()

      Button(
        action: {
          moveMonth(1)
        },
        label: {
          Image(systemName: AppIcons.chevronRight)
            .font(.system(size: 14, weight: .semibold))
            .frame(width: 34, height: 34)
        }
      )
      .buttonStyle(.plain)
      .accessibilityLabel("Next month")
    }
  }
}

private struct CalendarDayCell: View {
  let day: CalendarDayState
  let selectionNamespace: Namespace.ID
  let selectionGeometryID: String
  let selectionIsSource: Bool
  let selectDate: (Date?) -> Void

  var body: some View {
    Group {
      if let date = day.date, let dayNumber = day.dayNumber {
        Button(
          action: {
            withAnimation(AppAnimation.gentle) {
              selectDate(date)
            }
          },
          label: {
            ZStack {
              RoundedRectangle(cornerRadius: AppTheme.controlCornerRadius)
                .fill(dayBaseBackground)

              if day.isSelected {
                RoundedRectangle(cornerRadius: AppTheme.controlCornerRadius)
                  .fill(AppColors.accent)
                  .matchedGeometryEffect(
                    id: selectionGeometryID,
                    in: selectionNamespace,
                    properties: .frame,
                    isSource: selectionIsSource
                  )
              }

              VStack(spacing: AppSpacing.xxs) {
                Text("\(dayNumber)")
                  .font(.system(.body, design: .rounded, weight: .semibold))
                  .foregroundStyle(day.isSelected ? .white : AppColors.textPrimary)

                Circle()
                  .fill(day.hasEntries ? AppColors.accentSecondary : .clear)
                  .frame(width: 5, height: 5)
              }
            }
            .frame(maxWidth: .infinity, minHeight: 44)
            .overlay {
              RoundedRectangle(cornerRadius: AppTheme.controlCornerRadius)
                .stroke(dayBorder, lineWidth: 1)
            }
          }
        )
        .buttonStyle(.plain)
        .accessibilityLabel(date.formatted(date: .complete, time: .omitted))
        .accessibilityValue(accessibilityValue)
      } else {
        Color.clear
          .frame(minHeight: 44)
          .accessibilityHidden(true)
      }
    }
  }

  private var dayBaseBackground: some ShapeStyle {
    if day.isToday {
      return AnyShapeStyle(AppColors.accent.opacity(0.16))
    }

    return AnyShapeStyle(AppColors.backgroundElevated.opacity(0.64))
  }

  private var dayBorder: Color {
    if day.isSelected {
      return AppColors.accent.opacity(0.5)
    }

    if day.isToday {
      return AppColors.accent.opacity(0.32)
    }

    return AppColors.border
  }

  private var accessibilityValue: String {
    [
      day.isSelected ? "Selected" : nil,
      day.hasEntries ? "Has Drifts" : "No Drifts",
      day.isToday ? "Today" : nil,
    ]
    .compactMap { $0 }
    .joined(separator: ", ")
  }
}

typealias JournalDateStripView = CalendarStripView
