//
//  ImageAttachmentSection.swift
//  Drift
//
//  Created by Lucas Stuart West Rogers on 13/05/2026.
//

import PhotosUI
import SwiftUI
import UIKit

struct ImageAttachmentPickerSection: View {
  let title: String
  let subtitle: String
  let attachments: [JournalImageAttachment]
  let imageAttachmentService: any ImageAttachmentService
  let isProcessing: Bool
  let addImageInputs: ([ImageAttachmentInput]) async -> Void
  let removeAttachment: (JournalImageAttachment) async -> Void

  @State private var selectedItems: [PhotosPickerItem] = []

  var body: some View {
    VStack(alignment: .leading, spacing: AppSpacing.s) {
      HStack(alignment: .firstTextBaseline) {
        VStack(alignment: .leading, spacing: AppSpacing.xxs) {
          Text(title)
            .font(AppTypography.cardTitle)
            .foregroundStyle(AppColors.textPrimary)

          Text(subtitle)
            .font(AppTypography.caption)
            .foregroundStyle(AppColors.textTertiary)
            .fixedSize(horizontal: false, vertical: true)
        }

        Spacer()

        PhotosPicker(
          selection: $selectedItems,
          maxSelectionCount: 8,
          matching: .images,
          photoLibrary: .shared()
        ) {
          Label("Add", systemImage: AppIcons.photoAdd)
            .font(AppTypography.caption)
            .foregroundStyle(AppColors.textPrimary)
            .padding(.horizontal, AppSpacing.s)
            .padding(.vertical, AppSpacing.xs)
            .background(AppColors.surfaceRaised, in: Capsule())
        }
        .disabled(isProcessing)
      }

      ImageAttachmentGrid(
        attachments: attachments,
        imageAttachmentService: imageAttachmentService,
        removeAttachment: removeAttachment
      )

      if isProcessing {
        ProgressView()
          .tint(AppColors.accent)
          .controlSize(.small)
      }
    }
    .onChange(of: selectedItems) { _, newItems in
      guard !newItems.isEmpty else { return }
      loadImages(from: newItems)
    }
  }

  private func loadImages(from items: [PhotosPickerItem]) {
    Task {
      var inputs: [ImageAttachmentInput] = []

      for item in items {
        guard let data = try? await item.loadTransferable(type: Data.self) else { continue }
        inputs.append(
          ImageAttachmentInput(
            data: data,
            originalFileName: item.itemIdentifier
          )
        )
      }

      selectedItems = []
      guard !inputs.isEmpty else { return }
      await addImageInputs(inputs)
    }
  }
}

struct ImageAttachmentGrid: View {
  let attachments: [JournalImageAttachment]
  let imageAttachmentService: any ImageAttachmentService
  var removeAttachment: ((JournalImageAttachment) async -> Void)?

  private let columns = [
    GridItem(.adaptive(minimum: 92), spacing: AppSpacing.s)
  ]

  var body: some View {
    if attachments.isEmpty {
      EmptyView()
    } else {
      LazyVGrid(columns: columns, spacing: AppSpacing.s) {
        ForEach(attachments) { attachment in
          attachmentTile(attachment)
        }
      }
    }
  }

  private func attachmentTile(_ attachment: JournalImageAttachment) -> some View {
    ZStack(alignment: .topTrailing) {
      LocalAttachmentImage(
        url: imageAttachmentService.thumbnailURL(for: attachment)
          ?? imageAttachmentService.imageURL(for: attachment)
      )
      .aspectRatio(1, contentMode: .fill)
      .frame(minHeight: 92)
      .clipShape(RoundedRectangle(cornerRadius: AppTheme.controlCornerRadius))
      .overlay {
        RoundedRectangle(cornerRadius: AppTheme.controlCornerRadius)
          .stroke(AppColors.border, lineWidth: 1)
      }

      if let removeAttachment {
        Button(
          action: {
            Task {
              await removeAttachment(attachment)
            }
          },
          label: {
            Image(systemName: AppIcons.xmark)
              .font(.caption.weight(.bold))
              .foregroundStyle(.white)
              .frame(width: 26, height: 26)
              .background(.black.opacity(0.56), in: Circle())
          }
        )
        .buttonStyle(.plain)
        .padding(AppSpacing.xs)
        .accessibilityLabel("Remove image")
      }
    }
    .accessibilityElement(children: .combine)
    .accessibilityLabel("Attached image")
  }
}

private struct LocalAttachmentImage: View {
  let url: URL

  var body: some View {
    Group {
      if let image = UIImage(contentsOfFile: url.path) {
        Image(uiImage: image)
          .resizable()
      } else {
        RoundedRectangle(cornerRadius: AppTheme.controlCornerRadius)
          .fill(AppColors.surfaceRaised)
          .overlay {
            Image(systemName: AppIcons.photo)
              .font(.system(size: 22, weight: .semibold))
              .foregroundStyle(AppColors.textTertiary)
          }
      }
    }
  }
}
