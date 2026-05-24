//
//  ChatGPTConnectionView.swift
//  Drift
//
//  Created by Lucas Stuart West Rogers on 24/05/2026.
//

import SwiftUI
import UIKit

struct ChatGPTConnectionView: View {
  @State private var viewModel: ChatGPTConnectionViewModel

  init(viewModel: ChatGPTConnectionViewModel) {
    _viewModel = State(initialValue: viewModel)
  }

  var body: some View {
    @Bindable var bindableViewModel = viewModel

    ZStack {
      AppTheme.backgroundGradient
        .ignoresSafeArea()

      ScrollView {
        VStack(alignment: .leading, spacing: AppSpacing.l) {
          header
          statusCard
          howItWorksSection
          futureSecureConnectionCard
          preferencesSection
          selectableContextSection
          starterPromptSection
          pendingUpdatesSection

          if let statusMessage = viewModel.statusMessage {
            Text(statusMessage)
              .font(AppTypography.caption)
              .foregroundStyle(AppColors.accentSecondary)
              .fixedSize(horizontal: false, vertical: true)
          }

          if let errorMessage = viewModel.errorMessage {
            Text(errorMessage)
              .font(AppTypography.caption)
              .foregroundStyle(AppColors.warmAccent)
              .fixedSize(horizontal: false, vertical: true)
          }
        }
        .padding(AppSpacing.l)
      }
    }
    .navigationTitle("ChatGPT Connection")
    .task {
      await viewModel.load()
    }
    .sheet(item: $bindableViewModel.shareItem) { item in
      ActivityView(activityItems: [item.prompt])
    }
  }

  private var header: some View {
    VStack(alignment: .leading, spacing: AppSpacing.s) {
      Text("Connect Drift to ChatGPT")
        .font(AppTypography.appTitle)
        .foregroundStyle(AppColors.textPrimary)
        .fixedSize(horizontal: false, vertical: true)

      Text("Let ChatGPT use the context you choose.")
        .font(AppTypography.body)
        .foregroundStyle(AppColors.textSecondary)
        .fixedSize(horizontal: false, vertical: true)

      Label(
        "Drifts are private by default. Nothing is shared unless you choose it.",
        systemImage: AppIcons.lockShield
      )
      .font(AppTypography.caption)
      .foregroundStyle(AppColors.accentSecondary)
      .fixedSize(horizontal: false, vertical: true)
    }
  }

  private var statusCard: some View {
    ConnectionCard {
      VStack(alignment: .leading, spacing: AppSpacing.m) {
        HStack(spacing: AppSpacing.m) {
          SettingsIcon(symbol: AppIcons.sparkles)

          VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text(viewModel.connectionState.displayName)
              .font(AppTypography.screenTitle)
              .foregroundStyle(AppColors.textPrimary)

            Text(
              "You can use Drift locally without an account. A secure connection will only be needed when you choose to connect Drift to ChatGPT."
            )
            .font(AppTypography.body)
            .foregroundStyle(AppColors.textSecondary)
            .fixedSize(horizontal: false, vertical: true)
          }
        }

        Divider().overlay(AppColors.border)

        SettingsRow(
          icon: AppIcons.lockShield,
          title: "Local identity",
          subtitle: viewModel.localIdentitySummary,
          trailingValue: "Hidden"
        )
      }
    }
  }

  private var howItWorksSection: some View {
    VStack(alignment: .leading, spacing: AppSpacing.s) {
      SectionTitle("How It Works")

      VStack(spacing: AppSpacing.s) {
        HowItWorksCard(
          icon: AppIcons.contextPack,
          title: "Choose context",
          message: "Pick Spaces or Context Packs you want ChatGPT to use."
        )
        HowItWorksCard(
          icon: AppIcons.link,
          title: "Connect securely",
          message: "Future connection will use a secure native sign-in flow."
        )
        HowItWorksCard(
          icon: AppIcons.sparkles,
          title: "Create and update Drifts",
          message: "ChatGPT can suggest new Drifts or updates to existing ones."
        )
        HowItWorksCard(
          icon: AppIcons.checkmarkCircle,
          title: "Review before saving",
          message: "You stay in control of what gets stored."
        )
      }
    }
  }

  private var futureSecureConnectionCard: some View {
    SettingsInfoCard(
      icon: AppIcons.lockShield,
      title: "Future Secure Connection",
      message:
        "Future ChatGPT connection will use a secure native flow such as passkeys or Sign in with Apple. No email/password account is needed for local Drift use."
    )
  }

  private var preferencesSection: some View {
    VStack(alignment: .leading, spacing: AppSpacing.s) {
      SectionTitle("Local Connection Preferences")

      SettingsInfoCard(
        icon: AppIcons.info,
        title: "Preparation only",
        message:
          "These settings prepare how Drift should behave once ChatGPT connection is available. Nothing is shared yet."
      )

      ConnectionCard {
        VStack(spacing: 0) {
          SettingsToggleRow(
            icon: AppIcons.contextPack,
            title: "Allow Space suggestions",
            subtitle: "ChatGPT may suggest where a reviewed Drift belongs.",
            isOn: Binding(
              get: { viewModel.settings.allowChatGPTSpaceSuggestions },
              set: { isEnabled in
                Task { await viewModel.setAllowSpaceSuggestions(isEnabled) }
              }
            )
          )

          Divider().overlay(AppColors.border)

          SettingsToggleRow(
            icon: AppIcons.checkmarkCircle,
            title: "Require review before saving",
            subtitle: "GPT-created Drifts stay pending until you approve them.",
            isOn: Binding(
              get: { viewModel.settings.requireReviewBeforeSaving },
              set: { isEnabled in
                Task { await viewModel.setRequireReviewBeforeSaving(isEnabled) }
              }
            )
          )

          Divider().overlay(AppColors.border)

          SettingsToggleRow(
            icon: AppIcons.sparkles,
            title: "Allow Drift proposals",
            subtitle: "ChatGPT may prepare local placeholder proposals for review.",
            isOn: Binding(
              get: { viewModel.settings.allowChatGPTDriftProposals },
              set: { isEnabled in
                Task { await viewModel.setAllowDriftProposals(isEnabled) }
              }
            )
          )

          Divider().overlay(AppColors.border)

          SettingsToggleRow(
            icon: AppIcons.pencil,
            title: "Allow Drift update suggestions",
            subtitle: "ChatGPT may suggest edits to existing Drifts for review.",
            isOn: Binding(
              get: { viewModel.settings.allowChatGPTDriftUpdates },
              set: { isEnabled in
                Task { await viewModel.setAllowDriftUpdates(isEnabled) }
              }
            )
          )
        }
      }
    }
  }

  private var selectableContextSection: some View {
    VStack(alignment: .leading, spacing: AppSpacing.s) {
      SectionTitle("Selectable Context")

      VStack(alignment: .leading, spacing: AppSpacing.s) {
        Text("Spaces ChatGPT can use")
          .font(AppTypography.cardTitle)
          .foregroundStyle(AppColors.textPrimary)

        ConnectionCard {
          if viewModel.spaces.isEmpty {
            EmptyContextRow(message: "No Spaces available yet.")
          } else {
            VStack(spacing: 0) {
              ForEach(viewModel.spaces) { space in
                SelectableContextRow(
                  icon: space.icon,
                  title: space.name,
                  subtitle: space.description,
                  countText: "\(viewModel.driftCount(for: space)) Drifts",
                  isSelected: viewModel.settings.selectedSpaceIds.contains(space.id),
                  action: {
                    Task { await viewModel.toggleSpaceSelection(space) }
                  }
                )

                if space.id != viewModel.spaces.last?.id {
                  Divider().overlay(AppColors.border)
                }
              }
            }
          }
        }
      }

      VStack(alignment: .leading, spacing: AppSpacing.s) {
        Text("Context Packs ChatGPT can use")
          .font(AppTypography.cardTitle)
          .foregroundStyle(AppColors.textPrimary)

        ConnectionCard {
          if viewModel.contextPacks.isEmpty {
            EmptyContextRow(message: "No Context Packs saved yet.")
          } else {
            VStack(spacing: 0) {
              ForEach(viewModel.contextPacks) { pack in
                SelectableContextRow(
                  icon: AppIcons.contextPack,
                  title: pack.name,
                  subtitle: pack.description,
                  countText: "\(pack.driftIds.count) Drifts",
                  isSelected: viewModel.settings.selectedContextPackIds.contains(pack.id),
                  action: {
                    Task { await viewModel.toggleContextPackSelection(pack) }
                  }
                )

                if pack.id != viewModel.contextPacks.last?.id {
                  Divider().overlay(AppColors.border)
                }
              }
            }
          }
        }
      }
    }
  }

  private var starterPromptSection: some View {
    VStack(alignment: .leading, spacing: AppSpacing.s) {
      SectionTitle("Start in ChatGPT")

      ConnectionCard {
        VStack(alignment: .leading, spacing: AppSpacing.m) {
          Text(viewModel.starterPromptPreview)
            .font(.system(.caption, design: .monospaced))
            .foregroundStyle(AppColors.textSecondary)
            .lineSpacing(3)
            .textSelection(.enabled)
            .fixedSize(horizontal: false, vertical: true)
            .padding(AppSpacing.m)
            .background(
              AppColors.background.opacity(0.72),
              in: RoundedRectangle(cornerRadius: AppTheme.controlCornerRadius)
            )

          HStack(spacing: AppSpacing.s) {
            Button {
              viewModel.copyStarterPrompt()
            } label: {
              Label("Copy Prompt", systemImage: AppIcons.copy)
            }
            .buttonStyle(ConnectionButtonStyle())

            Button {
              viewModel.prepareStarterPromptForSharing()
            } label: {
              Label("Share", systemImage: AppIcons.share)
            }
            .buttonStyle(ConnectionButtonStyle(isSecondary: true))
          }
        }
      }
    }
  }

  private var pendingUpdatesSection: some View {
    VStack(alignment: .leading, spacing: AppSpacing.s) {
      SectionTitle("Pending ChatGPT Updates")

      ConnectionCard {
        if viewModel.pendingUpdates.isEmpty {
          VStack(alignment: .leading, spacing: AppSpacing.s) {
            Label("No pending updates.", systemImage: AppIcons.sparkles)
              .font(AppTypography.cardTitle)
              .foregroundStyle(AppColors.textPrimary)

            Text("When ChatGPT suggests a new Drift or update, it will appear here for review.")
              .font(AppTypography.body)
              .foregroundStyle(AppColors.textSecondary)
              .fixedSize(horizontal: false, vertical: true)
          }
          .padding(AppSpacing.m)
        } else {
          VStack(spacing: AppSpacing.s) {
            ForEach(viewModel.pendingUpdates) { update in
              SettingsRow(
                icon: AppIcons.sparkles,
                title: update.title,
                subtitle: "Prepared locally for review.",
                trailingValue: "Pending"
              )
            }
          }
        }
      }
    }
  }
}

private struct SectionTitle: View {
  let title: String

  init(_ title: String) {
    self.title = title
  }

  var body: some View {
    Text(title)
      .font(AppTypography.screenTitle)
      .foregroundStyle(AppColors.textPrimary)
  }
}

private struct ConnectionCard<Content: View>: View {
  @ViewBuilder let content: () -> Content

  var body: some View {
    content()
      .frame(maxWidth: .infinity, alignment: .leading)
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

private struct HowItWorksCard: View {
  let icon: String
  let title: String
  let message: String

  var body: some View {
    ConnectionCard {
      HStack(alignment: .top, spacing: AppSpacing.m) {
        SettingsIcon(symbol: icon)

        VStack(alignment: .leading, spacing: AppSpacing.xs) {
          Text(title)
            .font(AppTypography.bodyEmphasis)
            .foregroundStyle(AppColors.textPrimary)

          Text(message)
            .font(AppTypography.caption)
            .foregroundStyle(AppColors.textSecondary)
            .fixedSize(horizontal: false, vertical: true)
        }
      }
    }
  }
}

private struct SelectableContextRow: View {
  let icon: String
  let title: String
  let subtitle: String
  let countText: String
  let isSelected: Bool
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      HStack(spacing: AppSpacing.m) {
        SettingsIcon(symbol: icon, tint: isSelected ? AppColors.accent : AppColors.textTertiary)

        VStack(alignment: .leading, spacing: AppSpacing.xs) {
          Text(title)
            .font(AppTypography.bodyEmphasis)
            .foregroundStyle(AppColors.textPrimary)

          Text(subtitle)
            .font(AppTypography.caption)
            .foregroundStyle(AppColors.textSecondary)
            .fixedSize(horizontal: false, vertical: true)

          HStack(spacing: AppSpacing.xs) {
            Text(countText)
            Text("Private by default")
          }
          .font(AppTypography.caption)
          .foregroundStyle(AppColors.textTertiary)
        }

        Spacer(minLength: AppSpacing.s)

        Image(systemName: isSelected ? AppIcons.checkmarkCircle : AppIcons.circle)
          .font(.title3)
          .foregroundStyle(isSelected ? AppColors.accent : AppColors.textTertiary)
      }
      .padding(AppSpacing.m)
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .accessibilityLabel("\(title), \(countText), \(isSelected ? "Selected" : "Not selected")")
  }
}

private struct EmptyContextRow: View {
  let message: String

  var body: some View {
    HStack(spacing: AppSpacing.m) {
      SettingsIcon(symbol: AppIcons.info, tint: AppColors.textTertiary)

      Text(message)
        .font(AppTypography.body)
        .foregroundStyle(AppColors.textSecondary)
        .fixedSize(horizontal: false, vertical: true)
    }
    .padding(AppSpacing.m)
  }
}

private struct ConnectionButtonStyle: ButtonStyle {
  var isSecondary = false

  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .font(AppTypography.bodyEmphasis)
      .foregroundStyle(isSecondary ? AppColors.textPrimary : AppColors.background)
      .lineLimit(1)
      .minimumScaleFactor(0.86)
      .padding(.vertical, AppSpacing.s)
      .padding(.horizontal, AppSpacing.m)
      .frame(maxWidth: .infinity)
      .background(
        isSecondary ? AppColors.surfaceRaised : AppColors.accent,
        in: RoundedRectangle(cornerRadius: AppTheme.controlCornerRadius)
      )
      .overlay {
        RoundedRectangle(cornerRadius: AppTheme.controlCornerRadius)
          .stroke(AppColors.border, lineWidth: isSecondary ? 1 : 0)
      }
      .opacity(configuration.isPressed ? 0.72 : 1)
  }
}

private struct ActivityView: UIViewControllerRepresentable {
  let activityItems: [Any]

  func makeUIViewController(context: Context) -> UIActivityViewController {
    UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
  }

  func updateUIViewController(
    _ uiViewController: UIActivityViewController,
    context: Context
  ) {}
}

#Preview {
  NavigationStack {
    ChatGPTConnectionView(
      viewModel: ChatGPTConnectionViewModel(
        userIdentityService: PreviewUserIdentityService(),
        chatGPTConnectionService: LocalChatGPTConnectionService(),
        spaceRepository: LocalSpaceRepository(),
        contextPackService: LocalContextPackService(
          contextPacks: [
            ContextPack(
              name: "Drift App",
              description: "Product notes and decisions.",
              driftIds: PreviewData.journalEntries.map(\.id),
              spaceIds: [DriftSpace.defaultSpaces[0].id]
            )
          ]
        ),
        driftRepository: JournalBackedDriftRepository(
          journalRepository: PreviewJournalRepository()
        )
      )
    )
  }
}
