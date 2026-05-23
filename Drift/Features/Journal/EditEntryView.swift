//
//  EditEntryView.swift
//  Drift
//
//  Created by Lucas Stuart West Rogers on 13/05/2026.
//

import SwiftUI

struct EditEntryView: View {
  @State private var viewModel: EntryDetailViewModel
  @State private var isShowingDiscardChangesConfirmation = false

  let onCancel: () -> Void
  let onSaved: () -> Void

  init(
    viewModel: EntryDetailViewModel,
    onCancel: @escaping () -> Void,
    onSaved: @escaping () -> Void
  ) {
    _viewModel = State(initialValue: viewModel)
    self.onCancel = onCancel
    self.onSaved = onSaved
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
            requestCancelEditing()
          },
          label: {
            Image(systemName: AppIcons.back)
          }
        )
        .accessibilityLabel("Back to Drift Detail")
      }
    }
    .confirmationDialog(
      "Discard changes?",
      isPresented: $isShowingDiscardChangesConfirmation,
      titleVisibility: .visible
    ) {
      Button(
        role: .destructive,
        action: {
          cancelEditing()
        },
        label: {
          Text("Discard Changes")
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
      Text("Your unsaved edits will be removed.")
    }
    .task {
      await loadForEditing()
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
          editForm

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

  private var editForm: some View {
    @Bindable var bindableViewModel = viewModel

    return VStack(alignment: .leading, spacing: AppSpacing.l) {
      Text("Edit Drift")
        .font(AppTypography.appTitle)
        .foregroundStyle(AppColors.textPrimary)
        .accessibilityAddTraits(.isHeader)

      VStack(alignment: .leading, spacing: AppSpacing.s) {
        Text("Title")
          .font(AppTypography.cardTitle)
          .foregroundStyle(AppColors.textPrimary)

        TextField("Title", text: $bindableViewModel.editedTitle)
          .padding(AppSpacing.s)
          .background(
            AppColors.surface.opacity(0.82),
            in: RoundedRectangle(cornerRadius: AppTheme.controlCornerRadius)
          )
      }

      VStack(alignment: .leading, spacing: AppSpacing.s) {
        Text("Transcript")
          .font(AppTypography.cardTitle)
          .foregroundStyle(AppColors.textPrimary)

        TextEditor(text: $bindableViewModel.editedTranscript)
          .font(AppTypography.body)
          .foregroundStyle(AppColors.textPrimary)
          .scrollContentBackground(.hidden)
          .frame(minHeight: 220)
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
        Text("Mood")
          .font(AppTypography.cardTitle)
          .foregroundStyle(AppColors.textPrimary)

        MoodPicker(selection: $bindableViewModel.editedMood)
          .accessibilityLabel("Mood selector")
      }

      VStack(alignment: .leading, spacing: AppSpacing.s) {
        Text("Drift type")
          .font(AppTypography.cardTitle)
          .foregroundStyle(AppColors.textPrimary)

        DriftTypeSelectionGrid(selection: $bindableViewModel.editedDriftType)
      }

      VStack(alignment: .leading, spacing: AppSpacing.s) {
        Text("Themes")
          .font(AppTypography.cardTitle)
          .foregroundStyle(AppColors.textPrimary)

        ThemeSelector(
          selectedThemes: viewModel.editedThemes,
          selectedCustomThemes: viewModel.editedCustomThemes,
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
        attachments: viewModel.editedImageAttachments,
        imageAttachmentService: viewModel.imageAttachmentService,
        isProcessing: viewModel.isProcessingImages,
        addImageInputs: viewModel.addImageInputs,
        removeAttachment: viewModel.removeImageAttachment
      )

      editTags
      editActions
    }
  }

  private var editTags: some View {
    VStack(alignment: .leading, spacing: AppSpacing.s) {
      Text("Tags")
        .font(AppTypography.cardTitle)
        .foregroundStyle(AppColors.textPrimary)

      FlowLayout(spacing: AppSpacing.xs) {
        ForEach(viewModel.editedTags, id: \.self) { tag in
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
          in: RoundedRectangle(cornerRadius: AppTheme.controlCornerRadius)
        )

        IconButton(
          icon: AppIcons.checkmark,
          accessibilityLabel: "Add tag",
          action: viewModel.addPendingTag
        )
      }
    }
  }

  private var editActions: some View {
    HStack(spacing: AppSpacing.s) {
      Button(
        action: {
          requestCancelEditing()
        },
        label: {
          Text("Cancel")
        }
      )
      .buttonStyle(.bordered)
      .tint(AppColors.textSecondary)

      Button(
        action: {
          saveChanges()
        },
        label: {
          if viewModel.isSaving {
            ProgressView()
              .tint(.white)
          } else {
            Label("Save Changes", systemImage: AppIcons.checkmark)
          }
        }
      )
      .buttonStyle(.borderedProminent)
      .tint(AppColors.accent)
      .disabled(viewModel.isSaving)
    }
  }

  private func loadForEditing() async {
    await viewModel.load()
    await viewModel.loadCustomThemes()
    viewModel.beginEditing()
  }

  private func cancelEditing() {
    viewModel.cancelEditing()
    onCancel()
  }

  private func requestCancelEditing() {
    if viewModel.hasUnsavedChanges {
      isShowingDiscardChangesConfirmation = true
    } else {
      cancelEditing()
    }
  }

  private func saveChanges() {
    Task {
      if await viewModel.saveChanges() {
        onSaved()
      }
    }
  }
}

#Preview {
  NavigationStack {
    EditEntryView(
      viewModel: EntryDetailViewModel(
        entryID: PreviewData.journalEntries[0].id,
        journalRepository: PreviewJournalRepository()
      ),
      onCancel: {},
      onSaved: {}
    )
  }
}
