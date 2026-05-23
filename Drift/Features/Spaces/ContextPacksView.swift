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
          primaryPackCard

          if let copiedMessage = viewModel.copiedMessage {
            Text(copiedMessage)
              .font(AppTypography.body)
              .foregroundStyle(AppColors.accentSecondary)
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
    .navigationTitle("Context Packs")
    .navigationBarTitleDisplayMode(.inline)
    .task {
      await viewModel.load()
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

      Text(
        "No AI integration is active. Copying context only places local Markdown on your clipboard."
      )
      .font(AppTypography.caption)
      .foregroundStyle(AppColors.textTertiary)
      .fixedSize(horizontal: false, vertical: true)
    }
  }

  private var primaryPackCard: some View {
    VStack(alignment: .leading, spacing: AppSpacing.m) {
      Label(viewModel.primaryPack.name, systemImage: AppIcons.contextPack)
        .font(AppTypography.cardTitle)
        .foregroundStyle(AppColors.textPrimary)

      Text(viewModel.primaryPack.description)
        .font(AppTypography.body)
        .foregroundStyle(AppColors.textSecondary)
        .fixedSize(horizontal: false, vertical: true)

      VStack(alignment: .leading, spacing: AppSpacing.xs) {
        Text("\(viewModel.selectedDrifts.count) recent Drifts")
        Text("\(viewModel.selectedSpaces.count) starter Spaces")
        Text(viewModel.primaryPack.aiVisibility.privacyCopy)
      }
      .font(AppTypography.caption)
      .foregroundStyle(AppColors.textTertiary)

      Button {
        Task {
          if let markdown = await viewModel.makeMarkdownForPrimaryPack() {
            UIPasteboard.general.string = markdown
          }
        }
      } label: {
        if viewModel.isLoading {
          ProgressView()
            .tint(.white)
            .frame(maxWidth: .infinity)
        } else {
          Label("Copy Context for ChatGPT", systemImage: AppIcons.share)
            .frame(maxWidth: .infinity)
        }
      }
      .buttonStyle(.borderedProminent)
      .tint(AppColors.accent)
      .disabled(viewModel.isLoading)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
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
}

#Preview {
  NavigationStack {
    ContextPacksView(
      viewModel: ContextPacksViewModel(
        driftRepository: JournalBackedDriftRepository(
          journalRepository: PreviewJournalRepository()
        ),
        contextPackService: LocalContextPackService(),
        contextExportService: LocalContextExportService()
      )
    )
  }
}
