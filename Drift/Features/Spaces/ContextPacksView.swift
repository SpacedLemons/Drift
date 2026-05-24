//
//  ContextPacksView.swift
//  Drift
//
//  Created by Lucas Stuart West Rogers on 23/05/2026.
//

import SwiftUI
import UIKit

struct ContextPacksView: View {
  @State private var viewModel: ContextPacksViewModel
  @State private var previewMarkdown = ""
  @State private var sharePayload: ContextSharePayload?
  @State private var packPendingDeletion: ContextPack?

  init(viewModel: ContextPacksViewModel) {
    _viewModel = State(initialValue: viewModel)
  }

  var body: some View {
    ZStack {
      AppTheme.backgroundGradient
        .ignoresSafeArea()

      ScrollView {
        VStack(alignment: .leading, spacing: AppSpacing.l) {
          header
          statusMessages
          builderCard
          markdownPreviewCard
          savedPacksSection
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppSpacing.l)
      }
    }
    .navigationTitle("Context Packs")
    .navigationBarTitleDisplayMode(.inline)
    .task {
      await reload()
    }
    .sheet(item: $sharePayload) { payload in
      ActivityView(activityItems: [payload.markdown])
    }
    .confirmationDialog(
      "Delete this Context Pack?",
      isPresented: Binding(
        get: { packPendingDeletion != nil },
        set: { if !$0 { packPendingDeletion = nil } }
      ),
      titleVisibility: .visible
    ) {
      Button("Delete Context Pack", role: .destructive) {
        guard let pack = packPendingDeletion else { return }
        Task {
          await viewModel.deletePack(pack)
          packPendingDeletion = nil
        }
      }

      Button("Cancel", role: .cancel) {
        packPendingDeletion = nil
      }
    }
  }

  private var header: some View {
    VStack(alignment: .leading, spacing: AppSpacing.s) {
      Text("Context Packs")
        .font(AppTypography.appTitle)
        .foregroundStyle(AppColors.textPrimary)
        .accessibilityAddTraits(.isHeader)

      Text("Context Packs let you collect Drifts and share them with AI when you choose.")
        .font(AppTypography.body)
        .foregroundStyle(AppColors.textSecondary)
        .fixedSize(horizontal: false, vertical: true)

      Text("No AI integration is active. Copy and share only use local Markdown you choose.")
        .font(AppTypography.caption)
        .foregroundStyle(AppColors.textTertiary)
        .fixedSize(horizontal: false, vertical: true)
    }
  }

  @ViewBuilder
  private var statusMessages: some View {
    if let copiedMessage = viewModel.copiedMessage {
      Text(copiedMessage)
        .font(AppTypography.caption)
        .foregroundStyle(AppColors.accentSecondary)
    }

    if let errorMessage = viewModel.errorMessage {
      Text(errorMessage)
        .font(AppTypography.caption)
        .foregroundStyle(AppColors.warmAccent)
    }
  }

  private var builderCard: some View {
    VStack(alignment: .leading, spacing: AppSpacing.m) {
      Label("Build a Context Pack", systemImage: AppIcons.contextPack)
        .font(AppTypography.cardTitle)
        .foregroundStyle(AppColors.textPrimary)

      TextField(
        "Pack name",
        text: Binding(
          get: { viewModel.draftName },
          set: {
            viewModel.draftName = $0
            refreshPreview()
          }
        )
      )
      .textFieldStyle(.roundedBorder)

      TextField(
        "Description",
        text: Binding(
          get: { viewModel.draftDescription },
          set: {
            viewModel.draftDescription = $0
            refreshPreview()
          }
        ),
        axis: .vertical
      )
      .textFieldStyle(.roundedBorder)
      .lineLimit(2...4)

      selectionSection(
        title: "Spaces Included",
        emptyMessage: "Create a Space first.",
        items: viewModel.spaces.map { space in
          ContextSelectionItem(
            id: space.id,
            title: space.name,
            icon: space.icon,
            isSelected: viewModel.selectedSpaceIds.contains(space.id),
            toggle: {
              viewModel.toggleSpace(space)
              refreshPreview()
            }
          )
        }
      )

      selectionSection(
        title: "Drifts Included",
        emptyMessage: "Save a Drift first.",
        items: viewModel.recentDrifts.map { drift in
          ContextSelectionItem(
            id: drift.id,
            title: drift.displayTitle,
            icon: drift.type.symbolName,
            isSelected: viewModel.selectedDriftIds.contains(drift.id),
            toggle: {
              viewModel.toggleDrift(drift)
              refreshPreview()
            }
          )
        }
      )

      VStack(spacing: AppSpacing.s) {
        Button {
          Task {
            await viewModel.saveDraftPack()
          }
        } label: {
          Label("Save Pack", systemImage: AppIcons.checkmark)
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
        .tint(AppColors.accent)

        Button {
          copy(pack: viewModel.draftPack)
        } label: {
          Label("Copy for ChatGPT", systemImage: AppIcons.copy)
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .tint(AppColors.accent)

        Button {
          share(pack: viewModel.draftPack)
        } label: {
          Label("Share Context", systemImage: AppIcons.share)
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
        .tint(AppColors.accentSecondary)

        Button {
          viewModel.startNewDraft()
          refreshPreview()
        } label: {
          Label("New Pack", systemImage: AppIcons.pencil)
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
        .tint(AppColors.textSecondary)
      }
    }
    .padding(AppSpacing.m)
    .background(
      AppColors.surface.opacity(0.86),
      in: RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius)
    )
    .overlay {
      RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius)
        .stroke(AppColors.border, lineWidth: 1)
    }
  }

  private var markdownPreviewCard: some View {
    VStack(alignment: .leading, spacing: AppSpacing.s) {
      Text("Markdown Preview")
        .font(AppTypography.cardTitle)
        .foregroundStyle(AppColors.textPrimary)

      ScrollView(.horizontal, showsIndicators: false) {
        Text(previewMarkdown)
          .font(.system(.caption, design: .monospaced))
          .foregroundStyle(AppColors.textSecondary)
          .textSelection(.enabled)
          .padding(AppSpacing.s)
      }
      .frame(maxWidth: .infinity, minHeight: 180, alignment: .topLeading)
      .background(
        AppColors.backgroundElevated.opacity(0.72),
        in: RoundedRectangle(cornerRadius: AppTheme.controlCornerRadius)
      )
    }
    .padding(AppSpacing.m)
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
  private var savedPacksSection: some View {
    if !viewModel.contextPacks.isEmpty {
      VStack(alignment: .leading, spacing: AppSpacing.m) {
        Text("Saved Packs")
          .font(AppTypography.cardTitle)
          .foregroundStyle(AppColors.textPrimary)

        ForEach(viewModel.contextPacks) { pack in
          savedPackRow(pack)
        }
      }
    }
  }

  private func savedPackRow(_ pack: ContextPack) -> some View {
    VStack(alignment: .leading, spacing: AppSpacing.s) {
      HStack(alignment: .top) {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
          Text(pack.name)
            .font(AppTypography.bodyEmphasis)
            .foregroundStyle(AppColors.textPrimary)

          Text(packSummary(pack))
            .font(AppTypography.caption)
            .foregroundStyle(AppColors.textSecondary)
        }

        Spacer()

        Menu {
          Button("Copy for ChatGPT") {
            copy(pack: pack)
          }
          Button("Share Context") {
            share(pack: pack)
          }
          Button("Delete", role: .destructive) {
            packPendingDeletion = pack
          }
        } label: {
          Image(systemName: "ellipsis")
            .frame(width: 32, height: 32)
        }
      }

      Text(pack.description)
        .font(AppTypography.caption)
        .foregroundStyle(AppColors.textSecondary)
        .lineLimit(2)
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

  private func selectionSection(
    title: String,
    emptyMessage: String,
    items: [ContextSelectionItem]
  ) -> some View {
    VStack(alignment: .leading, spacing: AppSpacing.s) {
      Text(title)
        .font(AppTypography.bodyEmphasis)
        .foregroundStyle(AppColors.textPrimary)

      if items.isEmpty {
        Text(emptyMessage)
          .font(AppTypography.caption)
          .foregroundStyle(AppColors.textTertiary)
      } else {
        FlowLayout(spacing: AppSpacing.xs) {
          ForEach(items) { item in
            Button(action: item.toggle) {
              Label(item.title, systemImage: item.icon)
                .font(AppTypography.caption)
                .foregroundStyle(item.isSelected ? AppColors.textPrimary : AppColors.textSecondary)
                .padding(.horizontal, AppSpacing.s)
                .padding(.vertical, AppSpacing.xs)
                .background(
                  item.isSelected ? AppColors.accent.opacity(0.22) : AppColors.surfaceRaised,
                  in: Capsule()
                )
                .overlay {
                  Capsule()
                    .stroke(item.isSelected ? AppColors.accent : AppColors.border, lineWidth: 1)
                }
            }
            .buttonStyle(.plain)
          }
        }
      }
    }
  }

  private func packSummary(_ pack: ContextPack) -> String {
    "\(viewModel.spaces(for: pack).count) Spaces, \(viewModel.drifts(for: pack).count) Drifts"
  }

  private func reload() async {
    await viewModel.load()
    previewMarkdown = await viewModel.markdownPreview()
  }

  private func refreshPreview() {
    Task {
      previewMarkdown = await viewModel.markdownPreview()
    }
  }

  private func copy(pack: ContextPack) {
    Task {
      if let markdown = await viewModel.copyMarkdown(for: pack) {
        UIPasteboard.general.string = markdown
        previewMarkdown = markdown
      }
    }
  }

  private func share(pack: ContextPack) {
    Task {
      if let markdown = await viewModel.shareMarkdown(for: pack) {
        sharePayload = ContextSharePayload(markdown: markdown)
        previewMarkdown = markdown
      }
    }
  }
}

private struct ContextSelectionItem: Identifiable {
  let id: UUID
  let title: String
  let icon: String
  let isSelected: Bool
  let toggle: () -> Void
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

#Preview {
  NavigationStack {
    ContextPacksView(
      viewModel: ContextPacksViewModel(
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
