//
//  RecordingView.swift
//  Drift
//
//  Created by Lucas Stuart West Rogers on 12/05/2026.
//

import SwiftUI

struct RecordingView: View {
  @State private var viewModel: RecordingViewModel
  @State private var isShowingCancelConfirmation = false

  let onCancel: () -> Void
  let onFinished: (RecordingResult) -> Void

  init(
    viewModel: RecordingViewModel,
    onCancel: @escaping () -> Void,
    onFinished: @escaping (RecordingResult) -> Void
  ) {
    _viewModel = State(initialValue: viewModel)
    self.onCancel = onCancel
    self.onFinished = onFinished
  }

  var body: some View {
    ZStack {
      AppTheme.backgroundGradient
        .ignoresSafeArea()

      VStack(spacing: AppSpacing.xl) {
        Spacer(minLength: AppSpacing.xl)

        VStack(spacing: AppSpacing.l) {
          RecordingOrb(
            isRecording: viewModel.isRecording,
            isPaused: viewModel.isPaused,
            audioLevel: viewModel.audioLevel
          )

          VStack(spacing: AppSpacing.xs) {
            Text(viewModel.formattedElapsedTime)
              .font(.system(size: 54, weight: .semibold, design: .rounded))
              .foregroundStyle(AppColors.textPrimary)
              .monospacedDigit()
              .accessibilityLabel("Recording time \(viewModel.formattedElapsedTime)")

            Text(viewModel.statusText)
              .font(AppTypography.caption)
              .foregroundStyle(AppColors.textSecondary)

            if viewModel.isPreparing {
              ProgressView()
                .tint(AppColors.accent)
                .controlSize(.small)
                .accessibilityLabel("Preparing recorder")
            }
          }
        }

        if let errorMessage = viewModel.errorMessage {
          VStack(spacing: AppSpacing.s) {
            Text(errorMessage)
              .font(AppTypography.body)
              .foregroundStyle(AppColors.warmAccent)
              .multilineTextAlignment(.center)

            if viewModel.shouldShowSettingsLink {
              SystemSettingsLink()
            }
          }
          .padding(.horizontal, AppSpacing.l)
        }

        if viewModel.shouldShowSilencePrompt {
          silencePromptCard
        }

        Label("Recording stays on your device", systemImage: AppIcons.lockShield)
          .font(AppTypography.body)
          .foregroundStyle(AppColors.textSecondary)
          .padding(.horizontal, AppSpacing.m)
          .padding(.vertical, AppSpacing.s)
          .background(AppColors.surface.opacity(0.76), in: Capsule())

        Spacer()

        HStack(spacing: AppSpacing.m) {
          recordingControlButton(
            title: "Cancel",
            icon: AppIcons.xmark,
            style: .secondary
          ) { showCancelConfirmation() }
          .disabled(!viewModel.canCancel)

          recordingControlButton(
            title: viewModel.pauseResumeTitle,
            icon: viewModel.pauseResumeIcon,
            style: .secondary
          ) { togglePause() }
          .disabled(!viewModel.canPauseOrFinish)

          recordingControlButton(
            title: "Finish",
            icon: AppIcons.checkmark,
            style: .primary
          ) { finishRecording() }
          .disabled(!viewModel.canPauseOrFinish)
        }
      }
      .padding(AppSpacing.l)
    }
    .navigationBarBackButtonHidden()
    .confirmationDialog(
      "Discard this recording?",
      isPresented: $isShowingCancelConfirmation,
      titleVisibility: .visible
    ) {
      Button(
        role: .destructive,
        action: {
          cancelRecording()
        },
        label: {
          Text("Discard Recording")
        }
      )

      Button(
        role: .cancel,
        action: {},
        label: {
          Text("Keep Recording")
        }
      )
    } message: {
      Text("This temporary recording will be removed from this device.")
    }
    .task {
      await viewModel.start()
    }
  }

  private func showCancelConfirmation() {
    isShowingCancelConfirmation = true
  }

  private func cancelRecording() {
    Task {
      await viewModel.cancel()
      onCancel()
    }
  }

  private func togglePause() {
    Task {
      await viewModel.togglePause()
    }
  }

  private func finishRecording() {
    Task {
      if let result = await viewModel.finish() {
        onFinished(result)
      }
    }
  }

  private var silencePromptCard: some View {
    VStack(alignment: .leading, spacing: AppSpacing.s) {
      Label(viewModel.silencePromptTitle, systemImage: AppIcons.waveform)
        .font(AppTypography.cardTitle)
        .foregroundStyle(AppColors.textPrimary)

      Text(viewModel.silencePromptMessage)
        .font(AppTypography.body)
        .foregroundStyle(AppColors.textSecondary)
        .fixedSize(horizontal: false, vertical: true)

      ViewThatFits(in: .horizontal) {
        HStack(spacing: AppSpacing.s) {
          silencePromptButtons
        }

        VStack(alignment: .leading, spacing: AppSpacing.s) {
          silencePromptButtons
        }
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
    .padding(.horizontal, AppSpacing.l)
  }

  @ViewBuilder
  private var silencePromptButtons: some View {
    Button(
      action: {
        viewModel.keepRecordingAfterSilencePrompt()
      },
      label: {
        Text("Keep Recording")
      }
    )
    .buttonStyle(.bordered)

    Button(
      action: {
        finishRecording()
      },
      label: {
        Text("Stop Recording")
      }
    )
    .buttonStyle(.borderedProminent)
    .tint(AppColors.accent)

    Button(
      role: .destructive,
      action: {
        cancelRecording()
      },
      label: {
        Text("Discard")
      }
    )
    .buttonStyle(.bordered)
  }

  private func recordingControlButton(
    title: String,
    icon: String,
    style: RecordingControlStyle,
    action: @escaping () -> Void
  ) -> some View {
    Button(
      action: {
        action()
      },
      label: {
        VStack(spacing: AppSpacing.xs) {
          Image(systemName: icon)
            .font(.system(size: 18, weight: .semibold))
            .frame(width: 50, height: 50)
            .background(style.background, in: Circle())
            .overlay {
              Circle().stroke(AppColors.border, lineWidth: 1)
            }

          Text(title)
            .font(AppTypography.caption)
        }
        .foregroundStyle(style.foreground)
        .frame(maxWidth: .infinity)
      }
    )
    .buttonStyle(.plain)
    .accessibilityLabel(title)
  }
}

private enum RecordingControlStyle {
  case primary
  case secondary

  var background: Color {
    switch self {
    case .primary: AppColors.accent
    case .secondary: AppColors.surfaceRaised
    }
  }

  var foreground: Color {
    switch self {
    case .primary: .white
    case .secondary: AppColors.textPrimary
    }
  }
}

#Preview {
  RecordingView(
    viewModel: RecordingViewModel(audioRecordingService: PreviewAudioRecordingService()),
    onCancel: {},
    onFinished: { _ in }
  )
}
