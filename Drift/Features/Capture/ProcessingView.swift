//
//  ProcessingView.swift
//  Drift
//
//  Created by Lucas Stuart West Rogers on 12/05/2026.
//

import SwiftUI

struct ProcessingView: View {
  @State private var viewModel: ProcessingViewModel

  let onCancel: () -> Void
  let onRecordAgain: () -> Void
  let onPrepared: (ReviewEntryDraft) -> Void

  init(
    viewModel: ProcessingViewModel,
    onCancel: @escaping () -> Void,
    onRecordAgain: @escaping () -> Void,
    onPrepared: @escaping (ReviewEntryDraft) -> Void
  ) {
    _viewModel = State(initialValue: viewModel)
    self.onCancel = onCancel
    self.onRecordAgain = onRecordAgain
    self.onPrepared = onPrepared
  }

  var body: some View {
    ZStack {
      AppTheme.backgroundGradient
        .ignoresSafeArea()

      VStack(alignment: .leading, spacing: AppSpacing.xl) {
        VStack(alignment: .leading, spacing: AppSpacing.s) {
          Image(systemName: AppIcons.waveform)
            .font(.system(size: 28, weight: .semibold))
            .foregroundStyle(AppColors.accent)

          Text("Preparing Drift")
            .font(AppTypography.appTitle)
            .foregroundStyle(AppColors.textPrimary)

          Text("Processed on your device where available.")
            .font(AppTypography.body)
            .foregroundStyle(AppColors.textSecondary)
        }

        ProcessingChecklist(items: viewModel.steps)

        if let errorMessage = viewModel.errorMessage {
          VStack(alignment: .leading, spacing: AppSpacing.m) {
            Text(errorMessage)
              .font(AppTypography.body)
              .foregroundStyle(AppColors.warmAccent)

            if viewModel.shouldShowSettingsLink {
              SystemSettingsLink()
            }

            retryButton
            recordAgainSection
            secondaryFallbackActions
          }
        }

        if let cleanupWarningMessage = viewModel.cleanupWarningMessage {
          Text(cleanupWarningMessage)
            .font(AppTypography.caption)
            .foregroundStyle(AppColors.textTertiary)
        }

        Spacer()
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(AppSpacing.l)
    }
    .navigationBarBackButtonHidden()
    .task {
      await prepareEntry()
    }
  }

  private func prepareEntry() async {
    if let draft = await viewModel.prepareEntry() {
      onPrepared(draft)
    }
  }

  private var retryButton: some View {
    Button(
      action: {
        Task {
          viewModel.reset()
          await prepareEntry()
        }
      },
      label: {
        Text("Try Again")
      }
    )
    .buttonStyle(.borderedProminent)
  }

  private var recordAgainSection: some View {
    VStack(alignment: .leading, spacing: AppSpacing.xs) {
      Button(
        action: {
          Task {
            await viewModel.discardEntry()
            onRecordAgain()
          }
        },
        label: {
          Label("Record Again", systemImage: AppIcons.mic)
        }
      )
      .buttonStyle(.bordered)
      .accessibilityLabel("Record again")

      Text("Trying again will discard this Drift")
        .font(AppTypography.caption)
        .foregroundStyle(AppColors.textTertiary)
        .fixedSize(horizontal: false, vertical: true)
    }
  }

  private var secondaryFallbackActions: some View {
    ViewThatFits(in: .horizontal) {
      HStack(spacing: AppSpacing.s) {
        manualButton
        cancelButton
      }

      VStack(alignment: .leading, spacing: AppSpacing.s) {
        manualButton
        cancelButton
      }
    }
  }

  private var manualButton: some View {
    Button(
      action: {
        Task {
          onPrepared(await viewModel.makeManualEntryDraft())
        }
      },
      label: {
        Text("Write Manually")
      }
    )
    .buttonStyle(.bordered)
  }

  private var cancelButton: some View {
    Button(
      action: {
        Task {
          await viewModel.discardEntry()
          onCancel()
        }
      },
      label: {
        Text("Cancel")
      }
    )
    .buttonStyle(.bordered)
  }
}

#Preview {
  ProcessingView(
    viewModel: ProcessingViewModel(
      recordingResult: RecordingResult(
        audioURL: URL(fileURLWithPath: "/tmp/drift-preview-recording.m4a"),
        duration: 72,
        finishedAt: PreviewData.baseDate
      ),
      transcriptionService: PreviewTranscriptionService(),
      moodAnalysisService: PreviewMoodAnalysisService()
    ),
    onCancel: {},
    onRecordAgain: {},
    onPrepared: { _ in }
  )
}
