//
//  SpacesView.swift
//  Drift
//
//  Created by Lucas Stuart West Rogers on 23/05/2026.
//

import SwiftUI

struct SpacesView: View {
  @State private var viewModel: SpacesViewModel
  @State private var contextPacksViewModel: ContextPacksViewModel
  @State private var editorDraft: SpaceEditorDraft?
  @State private var spacePendingDeletion: DriftSpace?

  let reloadToken: UUID
  let onCaptureInSpace: (DriftSpace) -> Void

  private let columns = [
    GridItem(.flexible(), spacing: AppSpacing.m),
    GridItem(.flexible(), spacing: AppSpacing.m),
  ]

  init(
    viewModel: SpacesViewModel,
    contextPacksViewModel: ContextPacksViewModel,
    reloadToken: UUID = UUID(),
    onCaptureInSpace: @escaping (DriftSpace) -> Void = { _ in }
  ) {
    _viewModel = State(initialValue: viewModel)
    _contextPacksViewModel = State(initialValue: contextPacksViewModel)
    self.reloadToken = reloadToken
    self.onCaptureInSpace = onCaptureInSpace
  }

  var body: some View {
    ZStack {
      AppTheme.backgroundGradient
        .ignoresSafeArea()

      ScrollView {
        VStack(alignment: .leading, spacing: AppSpacing.l) {
          header
          privacyCard
          statusMessages
          spacesGrid
          contextPacksLink
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppSpacing.l)
      }
    }
    .navigationTitle("Spaces")
    .navigationBarTitleDisplayMode(.large)
    .toolbar {
      ToolbarItem(placement: .topBarTrailing) {
        Button {
          viewModel.clearMessages()
          editorDraft = SpaceEditorDraft()
        } label: {
          Image(systemName: "plus")
        }
        .accessibilityLabel("Create Space")
      }
    }
    .task(id: reloadToken) {
      await viewModel.load()
      await contextPacksViewModel.load()
    }
    .sheet(item: $editorDraft) { draft in
      SpaceEditorView(draft: draft, errorMessage: viewModel.errorMessage) { updatedDraft in
        Task {
          let didSave: Bool
          if let space = updatedDraft.editingSpace {
            didSave = await viewModel.updateSpace(space, from: updatedDraft)
          } else {
            didSave = await viewModel.createSpace(from: updatedDraft)
          }

          if didSave {
            editorDraft = nil
          }
        }
      }
    }
    .confirmationDialog(
      "Delete this Space?",
      isPresented: Binding(
        get: { spacePendingDeletion != nil },
        set: { if !$0 { spacePendingDeletion = nil } }
      ),
      titleVisibility: .visible
    ) {
      Button("Delete Space", role: .destructive) {
        guard let space = spacePendingDeletion else { return }
        Task {
          _ = await viewModel.deleteSpace(space)
          spacePendingDeletion = nil
        }
      }

      Button("Cancel", role: .cancel) {
        spacePendingDeletion = nil
      }
    } message: {
      Text("Drifts in this Space will stay in your saved Drifts.")
    }
  }

  private var header: some View {
    VStack(alignment: .leading, spacing: AppSpacing.s) {
      Text("Boards for grouping Drifts into goals, ideas, moodboards, and projects.")
        .font(AppTypography.body)
        .foregroundStyle(AppColors.textSecondary)
        .fixedSize(horizontal: false, vertical: true)
    }
  }

  private var privacyCard: some View {
    Label {
      Text("Drifts are private by default. You choose what to share.")
        .font(AppTypography.body)
        .foregroundStyle(AppColors.textSecondary)
        .fixedSize(horizontal: false, vertical: true)
    } icon: {
      Image(systemName: AppIcons.lockShield)
        .foregroundStyle(AppColors.accentSecondary)
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
  private var spacesGrid: some View {
    if viewModel.isLoading {
      ProgressView()
        .tint(AppColors.accent)
        .frame(maxWidth: .infinity, minHeight: 160)
    } else if viewModel.summaries.isEmpty {
      EmptyStateView(
        title: "No Spaces yet",
        message: "Create a Space to group related Drifts.",
        icon: AppIcons.spaces
      )
    } else {
      LazyVGrid(columns: columns, spacing: AppSpacing.m) {
        ForEach(viewModel.summaries) { summary in
          ZStack(alignment: .topTrailing) {
            NavigationLink {
              SpaceDetailView(
                viewModel: viewModel,
                space: summary.space,
                contextPacksViewModel: contextPacksViewModel,
                onCaptureInSpace: onCaptureInSpace
              )
            } label: {
              SpaceCard(summary: summary)
            }
            .buttonStyle(.plain)

            spaceActionsMenu(for: summary.space)
              .padding(.top, AppSpacing.s)
              .padding(.trailing, AppSpacing.s)
          }
        }
      }
    }
  }

  private func spaceActionsMenu(for space: DriftSpace) -> some View {
    Menu {
      Button("Edit") {
        viewModel.clearMessages()
        editorDraft = SpaceEditorDraft(space: space)
      }

      Button("Delete", role: .destructive) {
        viewModel.clearMessages()
        spacePendingDeletion = space
      }
    } label: {
      Image(systemName: "ellipsis")
        .font(.system(size: 16, weight: .semibold))
        .foregroundStyle(AppColors.textSecondary)
        .frame(width: 32, height: 32)
        .background(AppColors.surfaceRaised.opacity(0.86), in: Circle())
    }
    .accessibilityLabel("Space actions")
  }

  private var contextPacksLink: some View {
    NavigationLink {
      ContextPacksView(viewModel: contextPacksViewModel)
    } label: {
      HStack(spacing: AppSpacing.m) {
        SettingsIcon(symbol: AppIcons.contextPack)

        VStack(alignment: .leading, spacing: AppSpacing.xs) {
          Text("Context Packs")
            .font(AppTypography.bodyEmphasis)
            .foregroundStyle(AppColors.textPrimary)

          Text("Collect Drifts into local context you can copy or share when you choose.")
            .font(AppTypography.caption)
            .foregroundStyle(AppColors.textSecondary)
            .fixedSize(horizontal: false, vertical: true)
        }

        Spacer(minLength: AppSpacing.s)

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
      .contentShape(RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius))
    }
    .buttonStyle(.plain)
  }
}

private struct SpaceCard: View {
  let summary: SpaceSummary

  var body: some View {
    VStack(alignment: .leading, spacing: AppSpacing.m) {
      HStack(alignment: .top) {
        Image(systemName: summary.space.icon)
          .font(.system(size: 28, weight: .semibold))
          .foregroundStyle(summary.space.accentColor)
          .frame(width: 44, height: 44)
          .background(summary.space.accentColor.opacity(0.14), in: Circle())

        Spacer()
      }

      VStack(alignment: .leading, spacing: AppSpacing.xs) {
        HStack(spacing: AppSpacing.xs) {
          Text(summary.space.name)
            .font(AppTypography.cardTitle)
            .foregroundStyle(AppColors.textPrimary)
            .lineLimit(2)

          if summary.space.isPinned {
            Image(systemName: "pin.fill")
              .font(.caption2)
              .foregroundStyle(AppColors.accent)
              .accessibilityLabel("Pinned")
          }
        }

        Text("\(summary.driftCount) Drifts")
          .font(AppTypography.caption)
          .foregroundStyle(AppColors.textSecondary)
      }
    }
    .frame(maxWidth: .infinity, minHeight: 148, alignment: .topLeading)
    .padding(AppSpacing.m)
    .background(
      AppColors.surface.opacity(0.88),
      in: RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius)
    )
    .overlay {
      RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius)
        .stroke(
          summary.space.accentColor.opacity(summary.space.isPinned ? 0.5 : 0.14),
          lineWidth: 1
        )
    }
    .contentShape(RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius))
    .accessibilityElement(children: .combine)
  }
}

struct SpaceEditorView: View {
  @Environment(\.dismiss) private var dismiss
  @State private var draft: SpaceEditorDraft

  let errorMessage: String?
  let onSave: (SpaceEditorDraft) -> Void

  private let icons = [
    "square.grid.2x2",
    "target",
    "lightbulb",
    "clock.arrow.circlepath",
    "sparkles",
    "app.badge",
    AppIcons.mood,
  ]
  private let accentOptions = SpaceAccentOption.allOptions

  init(
    draft: SpaceEditorDraft,
    errorMessage: String? = nil,
    onSave: @escaping (SpaceEditorDraft) -> Void
  ) {
    _draft = State(initialValue: draft)
    self.errorMessage = errorMessage
    self.onSave = onSave
  }

  var body: some View {
    NavigationStack {
      Form {
        Section("Space") {
          TextField("Name", text: $draft.name)
          TextField("Description", text: $draft.description, axis: .vertical)
            .lineLimit(2...4)
          Toggle("Pinned", isOn: $draft.isPinned)
        }

        if let errorMessage {
          Section {
            Text(errorMessage)
              .foregroundStyle(AppColors.warmAccent)
          }
        }

        Section("Icon") {
          LazyVGrid(columns: [GridItem(.adaptive(minimum: 48))], spacing: AppSpacing.s) {
            ForEach(icons, id: \.self) { icon in
              Button {
                draft.icon = icon
              } label: {
                Image(systemName: icon)
                  .font(.system(size: 20, weight: .semibold))
                  .foregroundStyle(draft.icon == icon ? .white : AppColors.textSecondary)
                  .frame(width: 44, height: 44)
                  .background(
                    draft.icon == icon ? AppColors.accent : AppColors.surfaceRaised,
                    in: Circle()
                  )
              }
              .buttonStyle(.plain)
              .accessibilityLabel(icon)
            }
          }
        }

        Section("Accent") {
          HStack(spacing: AppSpacing.s) {
            ForEach(accentOptions) { option in
              Button {
                draft.accentColorHex = option.hex
              } label: {
                Circle()
                  .fill(option.color)
                  .frame(width: 34, height: 34)
                  .overlay {
                    Circle()
                      .stroke(
                        draft.accentColorHex == option.hex
                          ? AppColors.textPrimary : AppColors.border,
                        lineWidth: draft.accentColorHex == option.hex ? 2 : 1
                      )
                  }
              }
              .buttonStyle(.plain)
              .accessibilityLabel(option.name)
              .accessibilityAddTraits(draft.accentColorHex == option.hex ? .isSelected : [])
            }
          }
        }
      }
      .scrollContentBackground(.hidden)
      .background(AppTheme.backgroundGradient)
      .navigationTitle(draft.editingSpace == nil ? "New Space" : "Edit Space")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel") {
            dismiss()
          }
        }

        ToolbarItem(placement: .confirmationAction) {
          Button("Save") {
            onSave(draft)
          }
          .disabled(draft.cleanedName.isEmpty)
        }
      }
    }
  }
}

struct SpaceAccentOption: Identifiable {
  let name: String
  let hex: String
  let color: Color

  var id: String { hex }

  static let allOptions = [
    SpaceAccentOption(name: "Drift purple", hex: "#9E78FF", color: AppColors.accent),
    SpaceAccentOption(name: "Tide teal", hex: "#45D1C2", color: AppColors.accentSecondary),
    SpaceAccentOption(name: "Warm amber", hex: "#FFA36B", color: AppColors.warmAccent),
    SpaceAccentOption(
      name: "Sky blue",
      hex: "#5C94FF",
      color: Color(red: 0.36, green: 0.58, blue: 1.0)
    ),
  ]
}

extension DriftSpace {
  var accentColor: Color {
    guard let accentColorHex else { return AppColors.accent }

    return SpaceAccentOption.allOptions.first { $0.hex == accentColorHex }?.color
      ?? AppColors.accent
  }
}

#Preview {
  NavigationStack {
    SpacesView(
      viewModel: SpacesViewModel(),
      contextPacksViewModel: ContextPacksViewModel(
        driftRepository: JournalBackedDriftRepository(
          journalRepository: PreviewJournalRepository()
        ),
        spaceRepository: LocalSpaceRepository(),
        contextPackService: LocalContextPackService(),
        contextExportService: LocalContextExportService()
      )
    )
  }
}
