//
//  SpaceDetailView.swift
//  Drift
//
//  Created by Lucas Stuart West Rogers on 23/05/2026.
//

import SwiftUI

struct SpaceDetailView: View {
  @Environment(\.dismiss) private var dismiss

  let viewModel: SpacesViewModel
  let space: DriftSpace
  let contextPacksViewModel: ContextPacksViewModel
  let onCaptureInSpace: (DriftSpace) -> Void

  @State private var isShowingAddDriftSheet = false
  @State private var isShowingDeleteConfirmation = false
  @State private var editorDraft: SpaceEditorDraft?

  private var currentSpace: DriftSpace {
    viewModel.summaries.first { $0.id == space.id }?.space ?? space
  }

  private var drifts: [DriftItem] {
    viewModel.drifts(in: currentSpace)
  }

  var body: some View {
    ZStack {
      AppTheme.backgroundGradient
        .ignoresSafeArea()

      ScrollView {
        VStack(alignment: .leading, spacing: AppSpacing.l) {
          header
          actionBar
          statusMessages
          driftsSection
        }
        .padding(AppSpacing.l)
      }
    }
    .navigationTitle(currentSpace.name)
    .navigationBarTitleDisplayMode(.large)
    .toolbar {
      ToolbarItem(placement: .topBarTrailing) {
        Menu {
          Button("Edit Space") {
            viewModel.clearMessages()
            editorDraft = SpaceEditorDraft(space: currentSpace)
          }

          Button("Delete Space", role: .destructive) {
            viewModel.clearMessages()
            isShowingDeleteConfirmation = true
          }
        } label: {
          Image(systemName: "ellipsis.circle")
        }
        .accessibilityLabel("Space actions")
      }
    }
    .sheet(isPresented: $isShowingAddDriftSheet) {
      AddDriftToSpaceView(
        space: currentSpace,
        drifts: viewModel.availableDrifts(for: currentSpace),
        addDrift: { drift in
          Task {
            if await viewModel.addDrift(drift, to: currentSpace) {
              isShowingAddDriftSheet = false
            }
          }
        }
      )
    }
    .sheet(item: $editorDraft) { draft in
      SpaceEditorView(draft: draft, errorMessage: viewModel.errorMessage) { updatedDraft in
        Task {
          if await viewModel.updateSpace(currentSpace, from: updatedDraft) {
            editorDraft = nil
          }
        }
      }
    }
    .confirmationDialog(
      "Delete this Space?",
      isPresented: $isShowingDeleteConfirmation,
      titleVisibility: .visible
    ) {
      Button("Delete Space", role: .destructive) {
        Task {
          if await viewModel.deleteSpace(currentSpace) {
            dismiss()
          }
        }
      }

      Button("Cancel", role: .cancel) {}
    } message: {
      Text("Drifts in this Space will stay in your Timeline.")
    }
    .task {
      await viewModel.load()
    }
  }

  private var header: some View {
    VStack(alignment: .leading, spacing: AppSpacing.m) {
      HStack(alignment: .top, spacing: AppSpacing.m) {
        Image(systemName: currentSpace.icon)
          .font(.system(size: 32, weight: .semibold))
          .foregroundStyle(currentSpace.accentColor)
          .frame(width: 56, height: 56)
          .background(currentSpace.accentColor.opacity(0.14), in: Circle())

        VStack(alignment: .leading, spacing: AppSpacing.xs) {
          Text(currentSpace.description)
            .font(AppTypography.body)
            .foregroundStyle(AppColors.textSecondary)
            .fixedSize(horizontal: false, vertical: true)
        }
      }

      Label("\(drifts.count) Drifts", systemImage: AppIcons.waveform)
        .font(AppTypography.caption)
        .foregroundStyle(AppColors.textSecondary)
        .padding(.horizontal, AppSpacing.s)
        .padding(.vertical, AppSpacing.xs)
        .background(AppColors.surfaceRaised, in: Capsule())
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

  private var actionBar: some View {
    VStack(spacing: AppSpacing.s) {
      Button {
        viewModel.clearMessages()
        isShowingAddDriftSheet = true
      } label: {
        Label("Add Drift", systemImage: "plus")
          .frame(maxWidth: .infinity)
      }
      .buttonStyle(.bordered)
      .tint(AppColors.accent)

      Button {
        viewModel.clearMessages()
        onCaptureInSpace(currentSpace)
      } label: {
        Label("Capture Drift", systemImage: AppIcons.mic)
          .frame(maxWidth: .infinity)
      }
      .buttonStyle(.bordered)
      .tint(AppColors.accentSecondary)

      Button {
        viewModel.clearMessages()
        Task {
          _ = await viewModel.createContextPack(from: currentSpace)
          await contextPacksViewModel.load()
        }
      } label: {
        Label("Create Context Pack", systemImage: AppIcons.contextPack)
          .frame(maxWidth: .infinity)
      }
      .buttonStyle(.borderedProminent)
      .tint(AppColors.accent)
    }
  }

  @ViewBuilder
  private var statusMessages: some View {
    if let statusMessage = viewModel.statusMessage {
      Text(statusMessage)
        .font(AppTypography.caption)
        .foregroundStyle(AppColors.accentSecondary)
    }

    if let errorMessage = viewModel.errorMessage {
      Text(errorMessage)
        .font(AppTypography.caption)
        .foregroundStyle(AppColors.warmAccent)
    }
  }

  @ViewBuilder
  private var driftsSection: some View {
    if drifts.isEmpty {
      EmptyStateView(
        title: "No Drifts in this Space yet.",
        message: "Add thoughts, goals, ideas, or memories when they belong here.",
        icon: currentSpace.icon
      )
    } else {
      VStack(alignment: .leading, spacing: AppSpacing.m) {
        Text("Drifts")
          .font(AppTypography.cardTitle)
          .foregroundStyle(AppColors.textPrimary)

        ForEach(drifts) { drift in
          SpaceDriftRow(
            drift: drift,
            remove: {
              Task {
                _ = await viewModel.removeDrift(drift, from: currentSpace)
              }
            }
          )
        }
      }
    }
  }
}

private struct SpaceDriftRow: View {
  let drift: DriftItem
  let remove: () -> Void

  var body: some View {
    HStack(alignment: .top, spacing: AppSpacing.m) {
      Image(systemName: drift.type.symbolName)
        .font(.system(size: 16, weight: .semibold))
        .foregroundStyle(AppColors.accent)
        .frame(width: 32, height: 32)
        .background(AppColors.accent.opacity(0.14), in: Circle())

      VStack(alignment: .leading, spacing: AppSpacing.xs) {
        Text(drift.displayTitle)
          .font(AppTypography.bodyEmphasis)
          .foregroundStyle(AppColors.textPrimary)
          .lineLimit(2)

        Text(drift.previewText)
          .font(AppTypography.caption)
          .foregroundStyle(AppColors.textSecondary)
          .lineLimit(2)
      }

      Spacer(minLength: AppSpacing.s)

      Button(action: remove) {
        Image(systemName: AppIcons.xmark)
          .font(.caption)
          .foregroundStyle(AppColors.textSecondary)
          .frame(width: 32, height: 32)
      }
      .buttonStyle(.plain)
      .accessibilityLabel("Remove Drift from Space")
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

private struct AddDriftToSpaceView: View {
  @Environment(\.dismiss) private var dismiss

  let space: DriftSpace
  let drifts: [DriftItem]
  let addDrift: (DriftItem) -> Void

  var body: some View {
    NavigationStack {
      ZStack {
        AppTheme.backgroundGradient
          .ignoresSafeArea()

        ScrollView {
          VStack(alignment: .leading, spacing: AppSpacing.m) {
            if drifts.isEmpty {
              EmptyStateView(
                title: "No available Drifts",
                message: "Every current Drift is already in \(space.name).",
                icon: AppIcons.waveform
              )
            } else {
              ForEach(drifts) { drift in
                Button {
                  addDrift(drift)
                } label: {
                  HStack(spacing: AppSpacing.m) {
                    Image(systemName: drift.type.symbolName)
                      .foregroundStyle(AppColors.accent)

                    VStack(alignment: .leading, spacing: AppSpacing.xs) {
                      Text(drift.displayTitle)
                        .font(AppTypography.bodyEmphasis)
                        .foregroundStyle(AppColors.textPrimary)
                        .lineLimit(1)

                      Text(drift.previewText)
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.textSecondary)
                        .lineLimit(2)
                    }

                    Spacer()
                  }
                  .padding(AppSpacing.m)
                  .background(
                    AppColors.surface.opacity(0.84),
                    in: RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius)
                  )
                }
                .buttonStyle(.plain)
              }
            }
          }
          .padding(AppSpacing.l)
        }
      }
      .navigationTitle("Add Drift")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Done") {
            dismiss()
          }
        }
      }
    }
  }
}

#Preview {
  NavigationStack {
    SpaceDetailView(
      viewModel: SpacesViewModel(),
      space: DriftSpace.defaultSpaces[0],
      contextPacksViewModel: ContextPacksViewModel(
        driftRepository: JournalBackedDriftRepository(
          journalRepository: PreviewJournalRepository()
        ),
        spaceRepository: LocalSpaceRepository(),
        contextPackService: LocalContextPackService(),
        contextExportService: LocalContextExportService()
      ),
      onCaptureInSpace: { _ in }
    )
  }
}
