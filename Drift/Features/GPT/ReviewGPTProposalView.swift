//
//  ReviewGPTProposalView.swift
//  Drift
//
//  Created by Lucas Stuart West Rogers on 24/05/2026.
//

import SwiftUI

struct ReviewGPTProposalView: View {
  @State private var viewModel: ReviewGPTProposalViewModel
  let spaces: [DriftSpace]
  let onFinished: () -> Void
  @Environment(\.dismiss) private var dismiss

  init(
    viewModel: ReviewGPTProposalViewModel,
    spaces: [DriftSpace],
    onFinished: @escaping () -> Void
  ) {
    _viewModel = State(initialValue: viewModel)
    self.spaces = spaces
    self.onFinished = onFinished
  }

  var body: some View {
    ZStack {
      AppTheme.backgroundGradient
        .ignoresSafeArea()

      ScrollView {
        VStack(alignment: .leading, spacing: AppSpacing.l) {
          header
          editor
          actions

          if let errorMessage = viewModel.errorMessage {
            Text(errorMessage)
              .font(AppTypography.caption)
              .foregroundStyle(AppColors.warmAccent)
          }
        }
        .padding(AppSpacing.l)
      }
    }
    .navigationTitle("Review GPT Proposal")
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItem(placement: .cancellationAction) {
        Button("Close") {
          dismiss()
        }
      }
    }
  }

  private var header: some View {
    SettingsInfoCard(
      icon: AppIcons.checkmarkCircle,
      title: "Review before saving",
      message: "GPT-created Drifts stay pending until you approve them."
    )
  }

  @ViewBuilder
  private var editor: some View {
    @Bindable var bindableViewModel = viewModel

    VStack(alignment: .leading, spacing: AppSpacing.m) {
      EditorField(title: "Title", text: $bindableViewModel.title)
      MultilineEditorField(title: "Body", text: $bindableViewModel.body, minHeight: 180)
      MultilineEditorField(title: "Summary", text: $bindableViewModel.summary, minHeight: 110)

      Picker("Drift Type", selection: $bindableViewModel.selectedDriftType) {
        ForEach(DriftType.reviewSelectionOrder) { type in
          Label(type.displayName, systemImage: type.symbolName)
            .tag(type)
        }
      }
      .pickerStyle(.menu)
      .tint(AppColors.accent)

      Picker("Space", selection: $bindableViewModel.selectedSpaceId) {
        Text("No Space")
          .tag(Optional<UUID>.none)

        ForEach(spaces) { space in
          Text(space.name)
            .tag(Optional(space.id))
        }
      }
      .pickerStyle(.menu)
      .tint(AppColors.accent)

      EditorField(title: "Tags", text: $bindableViewModel.tagsText)
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

  private var actions: some View {
    HStack(spacing: AppSpacing.s) {
      Button {
        Task {
          if await viewModel.accept() != nil {
            onFinished()
            dismiss()
          }
        }
      } label: {
        Label(viewModel.isSaving ? "Saving" : "Accept & Save", systemImage: AppIcons.checkmark)
      }
      .buttonStyle(GPTPrimaryButtonStyle())
      .disabled(viewModel.isSaving)

      Button(role: .destructive) {
        Task {
          if await viewModel.reject() != nil {
            onFinished()
            dismiss()
          }
        }
      } label: {
        Label("Reject", systemImage: AppIcons.xmark)
      }
      .buttonStyle(GPTDestructiveButtonStyle())
      .disabled(viewModel.isSaving)
    }
  }
}

private struct EditorField: View {
  let title: String
  @Binding var text: String

  var body: some View {
    VStack(alignment: .leading, spacing: AppSpacing.xs) {
      Text(title)
        .font(AppTypography.caption)
        .foregroundStyle(AppColors.textTertiary)

      TextField(title, text: $text)
        .textFieldStyle(.plain)
        .font(AppTypography.body)
        .foregroundStyle(AppColors.textPrimary)
        .padding(AppSpacing.s)
        .background(
          AppColors.background.opacity(0.58),
          in: RoundedRectangle(cornerRadius: AppTheme.controlCornerRadius)
        )
    }
  }
}

private struct MultilineEditorField: View {
  let title: String
  @Binding var text: String
  let minHeight: CGFloat

  var body: some View {
    VStack(alignment: .leading, spacing: AppSpacing.xs) {
      Text(title)
        .font(AppTypography.caption)
        .foregroundStyle(AppColors.textTertiary)

      TextEditor(text: $text)
        .font(AppTypography.body)
        .foregroundStyle(AppColors.textPrimary)
        .scrollContentBackground(.hidden)
        .frame(minHeight: minHeight)
        .padding(AppSpacing.s)
        .background(
          AppColors.background.opacity(0.58),
          in: RoundedRectangle(cornerRadius: AppTheme.controlCornerRadius)
        )
    }
  }
}

#Preview {
  NavigationStack {
    ReviewGPTProposalView(
      viewModel: ReviewGPTProposalViewModel(
        proposal: DriftProposal(
          action: .createNewDrift,
          title: "Drift as AI context board",
          body: "Drift can become a personal context board for AI.",
          suggestedDriftType: .idea,
          summary: "Save the product idea."
        ),
        proposalService: LocalGPTProposalService(
          proposalRepository: LocalDriftProposalRepository(),
          driftRepository: JournalBackedDriftRepository(
            journalRepository: PreviewJournalRepository()),
          connectionService: LocalGPTConnectionService()
        )
      ),
      spaces: DriftSpace.defaultSpaces,
      onFinished: {}
    )
  }
}
