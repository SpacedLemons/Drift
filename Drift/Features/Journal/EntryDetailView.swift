//
//  EntryDetailView.swift
//  Drift
//
//  Created by Lucas Stuart West Rogers on 12/05/2026.
//

import SwiftUI
import UIKit

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
    @Bindable var bindableViewModel = viewModel

    ZStack {
      AppTheme.backgroundGradient
        .ignoresSafeArea()

      content
    }
    .navigationTitle(viewModel.entry?.displayTitle ?? "Drift")
    .navigationBarTitleDisplayMode(.large)
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
        .accessibilityLabel("Back")
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
          viewModel.entry?.isFavorite == true ? "Remove favorite" : "Favorite Drift")
      }
    }
    .confirmationDialog(
      "Delete this Drift?",
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
          Text("Delete Drift")
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
    .sheet(item: $bindableViewModel.exportShareItem) { exportItem in
      ActivityView(activityItems: [exportItem.url])
    }
  }

  @ViewBuilder
  private var content: some View {
    if viewModel.isLoading {
      ProgressView()
        .tint(AppColors.accent)
    } else if viewModel.entry == nil {
      EmptyStateView(
        title: "Drift unavailable",
        message: viewModel.errorMessage ?? "We could not find this Drift.",
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
        Text(
          "Created \(entry.createdAt.formatted(.dateTime.weekday(.wide).month().day().hour().minute()))"
        )
        .font(AppTypography.caption)
        .foregroundStyle(AppColors.textTertiary)

        if entry.updatedAt != entry.createdAt {
          Text("Updated \(entry.updatedAt.formatted(.dateTime.month().day().hour().minute()))")
            .font(AppTypography.caption)
            .foregroundStyle(AppColors.textTertiary)
        }
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

            Text("Images are stored on this device with your Drift.")
              .font(AppTypography.caption)
              .foregroundStyle(AppColors.textTertiary)
          }
        }
      }

      if !viewModel.spaceLabels(for: entry).isEmpty {
        detailCard(title: "Spaces", icon: AppIcons.spaces) {
          FlowLayout(spacing: AppSpacing.xs) {
            ForEach(viewModel.spaceLabels(for: entry), id: \.self) { spaceName in
              Label(spaceName, systemImage: AppIcons.spaces)
                .font(AppTypography.caption)
                .foregroundStyle(AppColors.textSecondary)
                .padding(.horizontal, AppSpacing.s)
                .padding(.vertical, AppSpacing.xs)
                .background(AppColors.surfaceRaised, in: Capsule())
            }
          }
        }
      }

      if !viewModel.relatedContextPacks.isEmpty {
        detailCard(title: "Context Packs", icon: AppIcons.contextPack) {
          VStack(alignment: .leading, spacing: AppSpacing.s) {
            ForEach(viewModel.relatedContextPacks) { pack in
              VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text(pack.name)
                  .font(AppTypography.bodyEmphasis)
                  .foregroundStyle(AppColors.textPrimary)

                Text(pack.description)
                  .font(AppTypography.caption)
                  .foregroundStyle(AppColors.textSecondary)
                  .lineLimit(2)
              }
              .frame(maxWidth: .infinity, alignment: .leading)
              .padding(AppSpacing.s)
              .background(
                AppColors.surfaceRaised,
                in: RoundedRectangle(cornerRadius: AppTheme.controlCornerRadius))
            }
          }
        }
      }

      actionRows
    }
  }

  private func detailMeta(_ entry: JournalEntry) -> some View {
    FlowLayout(spacing: AppSpacing.xs) {
      if let mood = entry.mood {
        MoodPill(mood: mood)
      }

      Label(entry.driftType.displayName, systemImage: entry.driftType.symbolName)
        .font(AppTypography.caption)
        .foregroundStyle(AppColors.textSecondary)
        .padding(.horizontal, AppSpacing.s)
        .padding(.vertical, AppSpacing.xs)
        .background(AppColors.surfaceRaised, in: Capsule())
        .accessibilityLabel("Drift type \(entry.driftType.displayName)")

      if let durationText = viewModel.durationText {
        Label(durationText, systemImage: AppIcons.clock)
          .font(AppTypography.caption)
          .foregroundStyle(AppColors.textSecondary)
          .padding(.horizontal, AppSpacing.s)
          .padding(.vertical, AppSpacing.xs)
          .background(AppColors.surfaceRaised, in: Capsule())
      }

      ForEach(viewModel.spaceNames(for: entry), id: \.self) { spaceName in
        Label(spaceName, systemImage: AppIcons.spaces)
          .font(AppTypography.caption)
          .foregroundStyle(AppColors.textSecondary)
          .padding(.horizontal, AppSpacing.s)
          .padding(.vertical, AppSpacing.xs)
          .background(AppColors.surfaceRaised, in: Capsule())
          .accessibilityLabel("Space \(spaceName)")
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
          detailActionLabel("Edit Drift", icon: AppIcons.pencil)
        }
      )
      .accessibilityLabel("Edit Drift")

      Button(
        action: {
          Task {
            await viewModel.exportCurrentEntry()
          }
        },
        label: {
          if viewModel.isExporting {
            ProgressView()
              .tint(AppColors.accent)
              .frame(maxWidth: .infinity, alignment: .leading)
              .padding(AppSpacing.m)
              .background(
                AppColors.surface.opacity(0.84),
                in: RoundedRectangle(cornerRadius: AppTheme.controlCornerRadius)
              )
          } else {
            detailActionLabel("Share Drift", icon: AppIcons.share)
          }
        }
      )
      .disabled(viewModel.entry == nil || viewModel.isExporting)
      .accessibilityLabel("Share Drift")

      Button(
        role: .destructive,
        action: {
          isShowingDeleteConfirmation = true
        },
        label: {
          detailActionLabel("Delete Drift", icon: AppIcons.trash)
        }
      )
      .accessibilityLabel("Delete Drift")
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

private struct ActivityView: UIViewControllerRepresentable {
  let activityItems: [Any]

  func makeUIViewController(context: Context) -> UIActivityViewController {
    let controller = UIActivityViewController(
      activityItems: activityItems,
      applicationActivities: nil
    )
    controller.popoverPresentationController?.sourceView = controller.view
    controller.popoverPresentationController?.sourceRect = CGRect(
      x: controller.view.bounds.midX,
      y: controller.view.bounds.midY,
      width: 0,
      height: 0
    )
    controller.popoverPresentationController?.permittedArrowDirections = []
    return controller
  }

  func updateUIViewController(
    _ uiViewController: UIActivityViewController,
    context: Context
  ) {}
}
