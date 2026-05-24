//
//  ReviewEntryView.swift
//  Drift
//
//  Created by Lucas Stuart West Rogers on 12/05/2026.
//

import SwiftUI

struct ReviewEntryView: View {
  @State private var viewModel: ReviewEntryViewModel
  @State private var isShowingDiscardConfirmation = false

  let onCancel: () -> Void
  let onSaved: (JournalEntry) -> Void

  init(
    viewModel: ReviewEntryViewModel,
    onCancel: @escaping () -> Void,
    onSaved: @escaping (JournalEntry) -> Void
  ) {
    _viewModel = State(initialValue: viewModel)
    self.onCancel = onCancel
    self.onSaved = onSaved
  }

  var body: some View {
    @Bindable var bindableViewModel = viewModel

    ZStack {
      AppTheme.backgroundGradient
        .ignoresSafeArea()

      ScrollView {
        VStack(alignment: .leading, spacing: AppSpacing.l) {
          header

          playbackSection

          VStack(alignment: .leading, spacing: AppSpacing.s) {
            Text("Title")
              .font(AppTypography.cardTitle)
              .foregroundStyle(AppColors.textPrimary)

            TextField("New Drift", text: $bindableViewModel.title)
              .font(AppTypography.body)
              .foregroundStyle(AppColors.textPrimary)
              .padding(AppSpacing.s)
              .background(
                AppColors.surface.opacity(0.82),
                in: RoundedRectangle(cornerRadius: AppTheme.controlCornerRadius)
              )
              .overlay {
                RoundedRectangle(cornerRadius: AppTheme.controlCornerRadius)
                  .stroke(AppColors.border, lineWidth: 1)
              }
          }

          VStack(alignment: .leading, spacing: AppSpacing.s) {
            Text("Transcript")
              .font(AppTypography.cardTitle)
              .foregroundStyle(AppColors.textPrimary)

            TextEditor(text: $bindableViewModel.transcript)
              .font(AppTypography.body)
              .foregroundStyle(AppColors.textPrimary)
              .scrollContentBackground(.hidden)
              .frame(minHeight: 190)
              .padding(AppSpacing.s)
              .background(
                AppColors.surface.opacity(0.82),
                in: RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius)
              )
              .overlay {
                RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius)
                  .stroke(AppColors.border, lineWidth: 1)
              }
          }

          VStack(alignment: .leading, spacing: AppSpacing.s) {
            Text("Drift type")
              .font(AppTypography.cardTitle)
              .foregroundStyle(AppColors.textPrimary)

            DriftTypeSelectionGrid(selection: $bindableViewModel.selectedDriftType)

            Text("Voice captures start as Reflections. You can change the type before saving.")
              .font(AppTypography.caption)
              .foregroundStyle(AppColors.textTertiary)
              .fixedSize(horizontal: false, vertical: true)
          }

          VStack(alignment: .leading, spacing: AppSpacing.s) {
            Text("Suggested mood")
              .font(AppTypography.cardTitle)
              .foregroundStyle(AppColors.textPrimary)

            MoodPicker(selection: $bindableViewModel.selectedMood)
          }

          spaceSelector

          VStack(alignment: .leading, spacing: AppSpacing.s) {
            Text("Themes")
              .font(AppTypography.cardTitle)
              .foregroundStyle(AppColors.textPrimary)

            ThemeSelector(
              selectedThemes: viewModel.selectedThemes,
              selectedCustomThemes: viewModel.selectedCustomThemes,
              availableCustomThemes: viewModel.availableCustomThemes,
              pendingCustomThemeName: viewModel.pendingCustomThemeName,
              toggleTheme: viewModel.toggleTheme,
              toggleCustomTheme: viewModel.toggleCustomTheme,
              updatePendingCustomThemeName: { viewModel.pendingCustomThemeName = $0 },
              createCustomTheme: {
                Task {
                  await viewModel.createCustomTheme()
                }
              },
              deleteCustomTheme: { theme in
                Task {
                  await viewModel.deleteCustomTheme(theme)
                }
              }
            )
          }

          ImageAttachmentPickerSection(
            title: "Images",
            subtitle: "Images are stored on this device with your Drift.",
            attachments: viewModel.imageAttachments,
            imageAttachmentService: viewModel.imageAttachmentService,
            isProcessing: viewModel.isProcessingImages,
            addImageInputs: viewModel.addImageInputs,
            removeAttachment: viewModel.removeImageAttachment
          )

          tagEditor

          if let errorMessage = viewModel.errorMessage {
            Text(errorMessage)
              .font(AppTypography.body)
              .foregroundStyle(AppColors.warmAccent)
          }

          HStack(spacing: AppSpacing.s) {
            Button(
              role: .destructive,
              action: {
                requestDiscard()
              },
              label: {
                Label("Discard", systemImage: AppIcons.xmark)
              }
            )
            .buttonStyle(.bordered)
            .tint(AppColors.textSecondary)
            .disabled(viewModel.isSaving)

            Button(
              action: {
                Task {
                  if let entry = await viewModel.save() {
                    onSaved(entry)
                  }
                }
              },
              label: {
                if viewModel.isSaving {
                  ProgressView()
                    .tint(.white)
                } else {
                  Label("Save Drift", systemImage: AppIcons.checkmark)
                }
              }
            )
            .buttonStyle(.borderedProminent)
            .tint(AppColors.accent)
            .disabled(viewModel.isSaving)
          }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppSpacing.l)
      }
    }
    .navigationBarBackButtonHidden()
    .toolbar {
      ToolbarItem(placement: .topBarTrailing) {
        discardToolbarButton
      }
    }
    .confirmationDialog(
      "Discard this Drift?",
      isPresented: $isShowingDiscardConfirmation,
      titleVisibility: .visible
    ) {
      Button(
        role: .destructive,
        action: {
          Task {
            await viewModel.discardDraftAttachments()
            onCancel()
          }
        },
        label: {
          Text("Discard Drift")
        }
      )

      Button(
        role: .cancel,
        action: {},
        label: {
          Text("Keep Editing")
        }
      )
    } message: {
      Text("This unsaved Drift will be removed from this device.")
    }
    .task {
      await viewModel.loadSpaces()
      await viewModel.loadCustomThemes()
      await viewModel.loadPlayback()
    }
  }

  private var header: some View {
    VStack(alignment: .leading, spacing: AppSpacing.s) {
      Text("Review Drift")
        .font(AppTypography.appTitle)
        .foregroundStyle(AppColors.textPrimary)

      Text("You can edit the transcript, choose a type, and adjust suggestions before saving.")
        .font(AppTypography.body)
        .foregroundStyle(AppColors.textSecondary)
    }
  }

  @ViewBuilder
  private var discardToolbarButton: some View {
    if #available(iOS 26.0, *) {
      Button(
        action: requestDiscard,
        label: {
          discardToolbarIcon
        }
      )
      .buttonStyle(.plain)
      .disabled(viewModel.isSaving)
      .glassEffect(
        .regular.tint(AppColors.surface.opacity(0.44)).interactive(),
        in: .rect(cornerRadius: 17)
      )
      .accessibilityLabel("Discard Drift")
    } else {
      Button(
        action: requestDiscard,
        label: {
          discardToolbarIcon
            .background(AppColors.surfaceRaised.opacity(0.86), in: Circle())
            .overlay {
              Circle()
                .stroke(AppColors.border, lineWidth: 1)
            }
        }
      )
      .buttonStyle(.plain)
      .disabled(viewModel.isSaving)
      .accessibilityLabel("Discard Drift")
    }
  }

  private var discardToolbarIcon: some View {
    Image(systemName: AppIcons.xmark)
      .font(.system(size: 14, weight: .semibold))
      .foregroundStyle(AppColors.textPrimary)
      .frame(width: 34, height: 34)
  }

  private func requestDiscard() {
    isShowingDiscardConfirmation = true
  }

  @ViewBuilder
  private var spaceSelector: some View {
    VStack(alignment: .leading, spacing: AppSpacing.s) {
      Text("Spaces")
        .font(AppTypography.cardTitle)
        .foregroundStyle(AppColors.textPrimary)

      if viewModel.availableSpaces.isEmpty {
        Text("Save this Drift now, or add it to a Space later.")
          .font(AppTypography.caption)
          .foregroundStyle(AppColors.textTertiary)
      } else {
        FlowLayout(spacing: AppSpacing.xs) {
          ForEach(viewModel.availableSpaces) { space in
            Button {
              viewModel.toggleSpace(space)
            } label: {
              Label(space.name, systemImage: space.icon)
                .font(AppTypography.caption)
                .foregroundStyle(
                  viewModel.selectedSpaceIds.contains(space.id)
                    ? AppColors.textPrimary : AppColors.textSecondary
                )
                .padding(.horizontal, AppSpacing.s)
                .padding(.vertical, AppSpacing.xs)
                .background(
                  viewModel.selectedSpaceIds.contains(space.id)
                    ? AppColors.accent.opacity(0.22) : AppColors.surfaceRaised,
                  in: Capsule()
                )
                .overlay {
                  Capsule()
                    .stroke(
                      viewModel.selectedSpaceIds.contains(space.id)
                        ? AppColors.accent : AppColors.border,
                      lineWidth: 1
                    )
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel(space.name)
            .accessibilityAddTraits(
              viewModel.selectedSpaceIds.contains(space.id) ? .isSelected : []
            )
          }
        }
      }
    }
  }

  @ViewBuilder
  private var playbackSection: some View {
    if viewModel.shouldShowPlaybackSection {
      ZStack(alignment: .leading) {
        if viewModel.shouldShowPlaybackLoadingState {
          AudioPlaybackLoadingView()
            .transition(.opacity)
        } else {
          playbackControls
            .transition(.opacity)
        }
      }
      .frame(maxWidth: .infinity, minHeight: 104, alignment: .leading)
      .padding(AppSpacing.m)
      .background(
        AppColors.surface.opacity(0.84),
        in: RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius)
      )
      .overlay {
        RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius)
          .stroke(AppColors.border, lineWidth: 1)
      }
      .animation(AppAnimation.gentle, value: viewModel.isPreparingPlayback)
      .animation(AppAnimation.gentle, value: viewModel.shouldShowPlaybackLoadingState)
      .animation(AppAnimation.gentle, value: viewModel.shouldShowPlaybackControls)
    }
  }

  private var playbackControls: some View {
    VStack(alignment: .leading, spacing: AppSpacing.s) {
      if viewModel.shouldShowPlaybackControls {
        HStack(spacing: AppSpacing.s) {
          Button(
            action: {
              Task {
                await viewModel.togglePlayback()
              }
            },
            label: {
              Label(viewModel.playbackButtonTitle, systemImage: viewModel.playbackButtonIcon)
            }
          )
          .buttonStyle(.bordered)
          .tint(AppColors.accent)

          Text(viewModel.playbackTimeText)
            .font(AppTypography.caption)
            .foregroundStyle(AppColors.textSecondary)
            .monospacedDigit()

          Spacer()
        }

        ProgressView(value: viewModel.playbackProgress)
          .tint(AppColors.accent)

        Text("Audio playback uses the temporary recording before saving.")
          .font(AppTypography.caption)
          .foregroundStyle(AppColors.textTertiary)
          .fixedSize(horizontal: false, vertical: true)
      }

      if let playbackErrorMessage = viewModel.playbackErrorMessage {
        Label(playbackErrorMessage, systemImage: AppIcons.warning)
          .font(AppTypography.caption)
          .foregroundStyle(AppColors.warmAccent)
          .fixedSize(horizontal: false, vertical: true)
      }
    }
  }

  private var tagEditor: some View {
    VStack(alignment: .leading, spacing: AppSpacing.s) {
      Text("Tags")
        .font(AppTypography.cardTitle)
        .foregroundStyle(AppColors.textPrimary)

      FlowLayout(spacing: AppSpacing.xs) {
        ForEach(viewModel.tags, id: \.self) { tag in
          Button(
            action: {
              viewModel.removeTag(tag)
            },
            label: {
              Label(tag, systemImage: AppIcons.xmark)
                .font(AppTypography.caption)
                .foregroundStyle(AppColors.textSecondary)
                .padding(.horizontal, AppSpacing.s)
                .padding(.vertical, AppSpacing.xs)
                .background(AppColors.surfaceRaised, in: Capsule())
            }
          )
          .buttonStyle(.plain)
          .accessibilityLabel("Remove tag \(tag)")
        }
      }

      HStack(spacing: AppSpacing.s) {
        TextField(
          "Add tag",
          text: Binding(
            get: { viewModel.pendingTag },
            set: { viewModel.pendingTag = $0 }
          )
        )
        .textInputAutocapitalization(.never)
        .submitLabel(.done)
        .onSubmit(viewModel.addPendingTag)
        .padding(AppSpacing.s)
        .background(
          AppColors.surface.opacity(0.82),
          in: RoundedRectangle(cornerRadius: AppTheme.controlCornerRadius))

        IconButton(
          icon: AppIcons.checkmark,
          accessibilityLabel: "Add tag",
          action: viewModel.addPendingTag
        )
      }
    }
  }
}

private struct AudioPlaybackLoadingView: View {
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @State private var shimmerPhase: CGFloat = -1.1

  var body: some View {
    VStack(alignment: .leading, spacing: AppSpacing.s) {
      HStack(spacing: AppSpacing.s) {
        ShimmerPlaceholder(
          width: 86,
          height: 34,
          cornerRadius: AppTheme.controlCornerRadius,
          phase: shimmerPhase
        )

        ShimmerPlaceholder(
          width: 92,
          height: 14,
          cornerRadius: 7,
          phase: shimmerPhase
        )

        Spacer()
      }

      ShimmerPlaceholder(
        height: 4,
        cornerRadius: 2,
        phase: shimmerPhase
      )

      ShimmerPlaceholder(
        width: 252,
        height: 13,
        cornerRadius: 7,
        phase: shimmerPhase
      )
    }
    .accessibilityElement(children: .ignore)
    .accessibilityLabel("Preparing audio playback")
    .onAppear {
      guard !reduceMotion else {
        shimmerPhase = 0
        return
      }

      shimmerPhase = -1.1
      withAnimation(.linear(duration: 1.35).repeatForever(autoreverses: false)) {
        shimmerPhase = 1.8
      }
    }
  }
}

private struct ShimmerPlaceholder: View {
  let width: CGFloat?
  let height: CGFloat
  let cornerRadius: CGFloat
  let phase: CGFloat

  init(
    width: CGFloat? = nil,
    height: CGFloat,
    cornerRadius: CGFloat,
    phase: CGFloat
  ) {
    self.width = width
    self.height = height
    self.cornerRadius = cornerRadius
    self.phase = phase
  }

  var body: some View {
    RoundedRectangle(cornerRadius: cornerRadius)
      .fill(AppColors.surfaceRaised.opacity(0.78))
      .frame(width: width, height: height)
      .overlay {
        GeometryReader { proxy in
          LinearGradient(
            colors: [
              .clear,
              AppColors.textPrimary.opacity(0.14),
              .clear,
            ],
            startPoint: .leading,
            endPoint: .trailing
          )
          .frame(width: proxy.size.width * 0.64)
          .offset(x: proxy.size.width * phase)
        }
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
      }
  }
}

#Preview {
  ReviewEntryView(
    viewModel: ReviewEntryViewModel(
      draft: ReviewEntryDraft(
        id: UUID(),
        audioURL: URL(fileURLWithPath: "/tmp/drift-preview-recording.m4a"),
        duration: 72,
        createdAt: PreviewData.baseDate,
        transcript: PreviewData.journalEntries[0].transcript,
        suggestedMood: .positive,
        suggestedThemes: [.productivity, .work, .growth],
        tags: ["focus", "work"]
      ),
      journalRepository: PreviewJournalRepository()
    ),
    onCancel: {},
    onSaved: { _ in }
  )
}
