//
//  EntryDetailView.swift
//  Drift
//
//  Created by Lucas Stuart West Rogers on 12/05/2026.
//

import SwiftUI

struct EntryDetailView: View {
  @Environment(\.dismiss) private var dismiss
  @State private var viewModel: EntryDetailViewModel
  @State private var isShowingDeleteConfirmation = false

  let reloadToken: UUID
  let onEditRequested: () -> Void
  let onEntryChanged: () -> Void
  let onEntryDeleted: () -> Void

  init(
    viewModel: EntryDetailViewModel,
    reloadToken: UUID,
    onEditRequested: @escaping () -> Void,
    onEntryChanged: @escaping () -> Void,
    onEntryDeleted: @escaping () -> Void
  ) {
    _viewModel = State(initialValue: viewModel)
    self.reloadToken = reloadToken
    self.onEditRequested = onEditRequested
    self.onEntryChanged = onEntryChanged
    self.onEntryDeleted = onEntryDeleted
  }

  var body: some View {
    ZStack {
      AppTheme.backgroundGradient
        .ignoresSafeArea()

      content
    }
    .navigationBarBackButtonHidden()
    .toolbar {
      ToolbarItem(placement: .topBarLeading) {
        Button(
          action: {
            dismiss()
          },
          label: {
            Image(systemName: AppIcons.back)
          }
        )
        .accessibilityLabel("Back to Journal")
      }

      ToolbarItemGroup(placement: .topBarTrailing) {
        Button(
          action: {
            Task {
              if await viewModel.toggleFavorite() {
                onEntryChanged()
              }
            }
          },
          label: {
            Image(
              systemName: viewModel.entry?.isFavorite == true
                ? AppIcons.favorite : AppIcons.favoriteEmpty)
          }
        )
        .disabled(viewModel.entry == nil)
        .accessibilityLabel(
          viewModel.entry?.isFavorite == true ? "Remove favorite" : "Favorite entry")
      }
    }
    .confirmationDialog(
      "Delete this entry?",
      isPresented: $isShowingDeleteConfirmation,
      titleVisibility: .visible
    ) {
      Button(
        role: .destructive,
        action: {
          Task {
            if await viewModel.deleteEntry() {
              onEntryDeleted()
            }
          }
        },
        label: {
          Text("Delete Entry")
        }
      )

      Button(
        role: .cancel,
        action: {},
        label: {
          Text("Cancel")
        }
      )
    } message: {
      Text("This will remove it from this device.")
    }
    .task(id: reloadToken) {
      await viewModel.load()
    }
  }

  @ViewBuilder
  private var content: some View {
    if viewModel.isLoading {
      ProgressView()
        .tint(AppColors.accent)
    } else if viewModel.entry == nil {
      EmptyStateView(
        title: "Entry unavailable",
        message: viewModel.errorMessage ?? "We could not find this entry.",
        icon: AppIcons.waveform
      )
      .padding(AppSpacing.l)
    } else {
      ScrollView {
        VStack(alignment: .leading, spacing: AppSpacing.l) {
          if let entry = viewModel.entry {
            displayContent(entry)
          }

          if let errorMessage = viewModel.errorMessage {
            Text(errorMessage)
              .font(AppTypography.body)
              .foregroundStyle(AppColors.warmAccent)
          }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppSpacing.l)
      }
    }
  }

  private func displayContent(_ entry: JournalEntry) -> some View {
    VStack(alignment: .leading, spacing: AppSpacing.l) {
      VStack(alignment: .leading, spacing: AppSpacing.s) {
        Text(entry.displayTitle)
          .font(AppTypography.appTitle)
          .foregroundStyle(AppColors.textPrimary)
          .accessibilityAddTraits(.isHeader)

        Text(entry.createdAt, format: .dateTime.weekday(.wide).month().day().hour().minute())
          .font(AppTypography.caption)
          .foregroundStyle(AppColors.textTertiary)
      }

      detailMeta(entry)

      detailCard(title: "Transcript", icon: AppIcons.waveform) {
        Text(entry.transcript)
          .font(AppTypography.body)
          .foregroundStyle(AppColors.textSecondary)
          .lineSpacing(4)
          .fixedSize(horizontal: false, vertical: true)
      }

      if !entry.imageAttachments.isEmpty {
        detailCard(title: "Images", icon: AppIcons.photo) {
          VStack(alignment: .leading, spacing: AppSpacing.s) {
            ImageAttachmentGrid(
              attachments: entry.imageAttachments,
              imageAttachmentService: viewModel.imageAttachmentService,
              removeAttachment: nil
            )

            Text("Images are stored on this device with your journal entry.")
              .font(AppTypography.caption)
              .foregroundStyle(AppColors.textTertiary)
          }
        }
      }

      detailCard(title: "Notes", icon: AppIcons.sparkles) {
        Text(
          "Summary and notes will be added later. Drift is using local journal details only for now."
        )
        .font(AppTypography.body)
        .foregroundStyle(AppColors.textSecondary)
        .fixedSize(horizontal: false, vertical: true)
      }

      actionRows
    }
  }

  private func detailMeta(_ entry: JournalEntry) -> some View {
    FlowLayout(spacing: AppSpacing.xs) {
      MoodPill(mood: entry.mood)

      if let durationText = viewModel.durationText {
        Label(durationText, systemImage: AppIcons.clock)
          .font(AppTypography.caption)
          .foregroundStyle(AppColors.textSecondary)
          .padding(.horizontal, AppSpacing.s)
          .padding(.vertical, AppSpacing.xs)
          .background(AppColors.surfaceRaised, in: Capsule())
      }

      ForEach(entry.themes) { theme in
        Label(theme.displayName, systemImage: AppIcons.tag)
          .font(AppTypography.caption)
          .foregroundStyle(AppColors.textSecondary)
          .padding(.horizontal, AppSpacing.s)
          .padding(.vertical, AppSpacing.xs)
          .background(AppColors.surfaceRaised, in: Capsule())
          .accessibilityLabel("Theme \(theme.displayName)")
      }

      ForEach(entry.customThemes) { theme in
        Label(theme.displayName, systemImage: AppIcons.tag)
          .font(AppTypography.caption)
          .foregroundStyle(AppColors.textSecondary)
          .padding(.horizontal, AppSpacing.s)
          .padding(.vertical, AppSpacing.xs)
          .background(AppColors.surfaceRaised, in: Capsule())
          .accessibilityLabel("Custom theme \(theme.displayName)")
      }

      if !entry.imageAttachments.isEmpty {
        Label("\(entry.imageAttachments.count)", systemImage: AppIcons.photo)
          .font(AppTypography.caption)
          .foregroundStyle(AppColors.textSecondary)
          .padding(.horizontal, AppSpacing.s)
          .padding(.vertical, AppSpacing.xs)
          .background(AppColors.surfaceRaised, in: Capsule())
          .accessibilityLabel("\(entry.imageAttachments.count) attached images")
      }

      ForEach(entry.tags, id: \.self) { tag in
        Text("#\(tag)")
          .font(AppTypography.caption)
          .foregroundStyle(AppColors.textSecondary)
          .padding(.horizontal, AppSpacing.s)
          .padding(.vertical, AppSpacing.xs)
          .background(AppColors.surfaceRaised, in: Capsule())
      }
    }
  }

  private var actionRows: some View {
    VStack(spacing: AppSpacing.s) {
      Button(
        action: {
          onEditRequested()
        },
        label: {
          detailActionLabel("Edit Entry", icon: AppIcons.pencil)
        }
      )
      .accessibilityLabel("Edit entry")

      Button(
        role: .destructive,
        action: {
          isShowingDeleteConfirmation = true
        },
        label: {
          detailActionLabel("Delete Entry", icon: AppIcons.trash)
        }
      )
      .accessibilityLabel("Delete entry")
    }
    .buttonStyle(.plain)
  }

  private func detailActionLabel(_ title: String, icon: String) -> some View {
    HStack(spacing: AppSpacing.s) {
      Image(systemName: icon)
        .font(.system(size: 16, weight: .semibold))
        .foregroundStyle(AppColors.accent)
        .frame(width: 32, height: 32)
        .background(AppColors.accent.opacity(0.12), in: Circle())

      Text(title)
        .font(AppTypography.bodyEmphasis)
        .foregroundStyle(AppColors.textPrimary)

      Spacer()

      Image(systemName: AppIcons.chevronRight)
        .font(.caption)
        .foregroundStyle(AppColors.textTertiary)
    }
    .padding(AppSpacing.m)
    .background(
      AppColors.surface.opacity(0.84),
      in: RoundedRectangle(cornerRadius: AppTheme.controlCornerRadius))
  }

  private func detailCard<Content: View>(
    title: String,
    icon: String,
    @ViewBuilder content: () -> Content
  ) -> some View {
    VStack(alignment: .leading, spacing: AppSpacing.m) {
      Label(title, systemImage: icon)
        .font(AppTypography.cardTitle)
        .foregroundStyle(AppColors.textPrimary)

      content()
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(AppSpacing.m)
    .background(
      AppColors.surface.opacity(0.86), in: RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius)
    )
    .overlay {
      RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius)
        .stroke(AppColors.border, lineWidth: 1)
    }
  }
}

#Preview {
  NavigationStack {
    EntryDetailView(
      viewModel: EntryDetailViewModel(
        entryID: PreviewData.journalEntries[0].id,
        journalRepository: PreviewJournalRepository()
      ),
      reloadToken: UUID(),
      onEditRequested: {},
      onEntryChanged: {},
      onEntryDeleted: {}
    )
  }
}
