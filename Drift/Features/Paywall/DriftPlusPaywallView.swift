//
//  DriftPlusPaywallView.swift
//  Drift
//
//  Created by Lucas Stuart West Rogers on 16/05/2026.
//

import SwiftUI

struct DriftPlusPaywallView: View {
  @Environment(\.dismiss) private var dismiss
  @State private var viewModel: DriftPlusPaywallViewModel

  init(viewModel: DriftPlusPaywallViewModel) {
    _viewModel = State(initialValue: viewModel)
  }

  var body: some View {
    @Bindable var bindableViewModel = viewModel

    ZStack(alignment: .topTrailing) {
      AppTheme.backgroundGradient
        .ignoresSafeArea()

      ScrollView {
        VStack(alignment: .leading, spacing: AppSpacing.xl) {
          heroSection

          if let reasonMessage = viewModel.reasonMessage {
            PaywallMessageCard(
              icon: AppIcons.warning,
              message: reasonMessage,
              tint: AppColors.warmAccent
            )
          }

          benefitsSection
          subscriptionSection(selection: $bindableViewModel.selectedPlan)
          reassuranceSection
        }
        .padding(.horizontal, AppSpacing.l)
        .padding(.top, AppSpacing.xxl + AppSpacing.l)
        .padding(.bottom, AppSpacing.xxl)
      }

      closeButton
    }
    .safeAreaInset(edge: .bottom) {
      if viewModel.hasStoreKitProducts {
        bottomPurchaseBar
      }
    }
    .task {
      await viewModel.load()
    }
  }

  private var closeButton: some View {
    Button {
      dismiss()
    } label: {
      Image(systemName: AppIcons.xmark)
        .font(.system(size: 17, weight: .semibold))
        .foregroundStyle(AppColors.textPrimary)
        .frame(width: 44, height: 44)
        .background(.ultraThinMaterial, in: Circle())
        .overlay {
          Circle()
            .stroke(AppColors.border, lineWidth: 1)
        }
    }
    .buttonStyle(.plain)
    .accessibilityLabel("Close Drift Plus")
    .safeAreaPadding(.top, AppSpacing.s)
    .padding(.trailing, AppSpacing.l)
  }

  private var heroSection: some View {
    VStack(alignment: .leading, spacing: AppSpacing.m) {
      HStack(spacing: AppSpacing.s) {
        Image(systemName: AppIcons.sparkles)
          .font(.system(size: 18, weight: .semibold))
          .foregroundStyle(AppColors.accent)
          .frame(width: 36, height: 36)
          .background(AppColors.accent.opacity(0.14), in: Circle())

        Text("Drift Plus")
          .font(AppTypography.cardTitle)
          .foregroundStyle(AppColors.textPrimary)
      }

      Text("Understand your thoughts over time.")
        .font(AppTypography.appTitle)
        .foregroundStyle(AppColors.textPrimary)
        .fixedSize(horizontal: false, vertical: true)
        .accessibilityAddTraits(.isHeader)

      Text(
        "More room for daily capture today, with Plus features ready to grow over time. Your Drifts stay on this device."
      )
      .font(AppTypography.body)
      .foregroundStyle(AppColors.textSecondary)
      .fixedSize(horizontal: false, vertical: true)
    }
  }

  private var benefitsSection: some View {
    VStack(alignment: .leading, spacing: AppSpacing.m) {
      Text("Included now")
        .font(AppTypography.cardTitle)
        .foregroundStyle(AppColors.textPrimary)

      PaywallFeatureCard(
        icon: AppIcons.mic,
        title: "Up to 100 Drifts per day",
        subtitle: "A higher daily protection limit for heavier capture days."
      )

      Text("Coming to Drift Plus")
        .font(AppTypography.cardTitle)
        .foregroundStyle(AppColors.textPrimary)
        .padding(.top, AppSpacing.s)

      LazyVGrid(
        columns: [
          GridItem(.flexible(), spacing: AppSpacing.s),
          GridItem(.flexible(), spacing: AppSpacing.s),
        ],
        alignment: .leading,
        spacing: AppSpacing.s
      ) {
        PaywallBenefitPill(icon: AppIcons.waveform, title: "Enhanced transcription")
        PaywallBenefitPill(icon: AppIcons.chartLine, title: "Deeper mood history")
        PaywallBenefitPill(icon: "app.badge", title: "Custom app icons")
        PaywallBenefitPill(icon: AppIcons.paintPalette, title: "Theme builder")
        PaywallBenefitPill(icon: AppIcons.share, title: "Premium exports")
        PaywallBenefitPill(icon: AppIcons.lockShield, title: "Optional iCloud backup")
      }
    }
  }

  private func subscriptionSection(
    selection: Binding<SubscriptionProduct.Plan>
  ) -> some View {
    VStack(alignment: .leading, spacing: AppSpacing.m) {
      HStack {
        Text("Choose a plan")
          .font(AppTypography.cardTitle)
          .foregroundStyle(AppColors.textPrimary)

        Spacer()

        if viewModel.isLoadingProducts {
          ProgressView()
            .tint(AppColors.accent)
        }
      }

      if viewModel.isLoadingProducts {
        PaywallLoadingCard()
      } else if viewModel.hasStoreKitProducts {
        VStack(spacing: AppSpacing.s) {
          ForEach(viewModel.sortedProducts) { product in
            PaywallPlanOption(
              product: product,
              isSelected: selection.wrappedValue == product.plan,
              action: {
                selection.wrappedValue = product.plan
              }
            )
          }
        }
      } else {
        PaywallUnavailableCard(
          retry: {
            Task { await viewModel.load() }
          }
        )
      }

      restoreButton

      if let errorMessage = viewModel.errorMessage, viewModel.hasStoreKitProducts {
        PaywallMessageCard(
          icon: AppIcons.warning,
          message: errorMessage,
          tint: AppColors.warmAccent
        )
      }

      if let statusMessage = viewModel.statusMessage {
        PaywallMessageCard(
          icon: AppIcons.success,
          message: statusMessage,
          tint: AppColors.accentSecondary
        )
      }
    }
  }

  private var restoreButton: some View {
    Button {
      Task { await viewModel.restorePurchases() }
    } label: {
      HStack {
        if viewModel.isRestoring {
          ProgressView()
            .tint(AppColors.accent)
        } else {
          Image(systemName: AppIcons.repeatArrows)
        }

        Text("Restore Purchases")
      }
      .font(AppTypography.bodyEmphasis)
      .foregroundStyle(AppColors.accent)
      .frame(maxWidth: .infinity)
      .padding(.vertical, AppSpacing.s)
    }
    .buttonStyle(.plain)
    .disabled(viewModel.isPurchaseInFlight)
  }

  private var reassuranceSection: some View {
    VStack(alignment: .leading, spacing: AppSpacing.s) {
      Label("Existing Drifts always stay yours.", systemImage: AppIcons.lockShield)
        .font(AppTypography.bodyEmphasis)
        .foregroundStyle(AppColors.textPrimary)

      Text(
        "Subscription status only changes future Plus access. Existing local Drifts remain readable, editable, and exportable."
      )
      .font(AppTypography.caption)
      .foregroundStyle(AppColors.textSecondary)
      .fixedSize(horizontal: false, vertical: true)
    }
  }

  private var bottomPurchaseBar: some View {
    VStack(spacing: AppSpacing.s) {
      Button {
        Task { await viewModel.purchaseSelectedPlan() }
      } label: {
        HStack {
          if viewModel.purchasingPlan == viewModel.selectedPlan {
            ProgressView()
              .tint(.white)
          } else {
            Text("Continue with \(viewModel.selectedPlan.displayShortName)")
          }

          Spacer()

          Text(viewModel.selectedProduct.displayPrice)
        }
        .font(AppTypography.bodyEmphasis)
        .foregroundStyle(.white)
        .padding(.horizontal, AppSpacing.m)
        .frame(maxWidth: .infinity, minHeight: 54)
      }
      .buttonStyle(.plain)
      .background(AppColors.accent, in: RoundedRectangle(cornerRadius: 16))
      .disabled(viewModel.isPurchaseInFlight)

      Text("Existing Drifts always stay yours.")
        .font(AppTypography.caption)
        .foregroundStyle(AppColors.textTertiary)
    }
    .padding(.horizontal, AppSpacing.l)
    .padding(.top, AppSpacing.m)
    .padding(.bottom, AppSpacing.s)
    .background(.ultraThinMaterial)
  }
}

private struct PaywallFeatureCard: View {
  let icon: String
  let title: String
  let subtitle: String

  var body: some View {
    HStack(alignment: .top, spacing: AppSpacing.m) {
      Image(systemName: icon)
        .font(.system(size: 18, weight: .semibold))
        .foregroundStyle(AppColors.accent)
        .frame(width: 38, height: 38)
        .background(AppColors.accent.opacity(0.14), in: Circle())

      VStack(alignment: .leading, spacing: AppSpacing.xs) {
        Text(title)
          .font(AppTypography.bodyEmphasis)
          .foregroundStyle(AppColors.textPrimary)

        Text(subtitle)
          .font(AppTypography.caption)
          .foregroundStyle(AppColors.textSecondary)
          .fixedSize(horizontal: false, vertical: true)
      }
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
}

private struct PaywallBenefitPill: View {
  let icon: String
  let title: String

  var body: some View {
    HStack(spacing: AppSpacing.xs) {
      Image(systemName: icon)
        .font(.system(size: 13, weight: .semibold))
        .foregroundStyle(AppColors.accent)

      Text(title)
        .font(AppTypography.caption)
        .foregroundStyle(AppColors.textSecondary)
        .lineLimit(2)
        .fixedSize(horizontal: false, vertical: true)
    }
    .padding(.horizontal, AppSpacing.s)
    .padding(.vertical, AppSpacing.s)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(
      AppColors.surface.opacity(0.66),
      in: RoundedRectangle(cornerRadius: AppTheme.controlCornerRadius)
    )
  }
}

private struct PaywallPlanOption: View {
  let product: SubscriptionProduct
  let isSelected: Bool
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      HStack(spacing: AppSpacing.m) {
        Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
          .font(.system(size: 20, weight: .semibold))
          .foregroundStyle(isSelected ? AppColors.accent : AppColors.textTertiary)

        VStack(alignment: .leading, spacing: AppSpacing.xs) {
          Text(product.plan.displayShortName)
            .font(AppTypography.bodyEmphasis)
            .foregroundStyle(AppColors.textPrimary)

          Text(product.displayName)
            .font(AppTypography.caption)
            .foregroundStyle(AppColors.textSecondary)
        }

        Spacer()

        Text(product.displayPrice)
          .font(AppTypography.bodyEmphasis)
          .foregroundStyle(AppColors.textPrimary)
      }
      .padding(AppSpacing.m)
      .frame(maxWidth: .infinity)
      .background(
        isSelected ? AppColors.accent.opacity(0.16) : AppColors.surface.opacity(0.78),
        in: RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius)
      )
      .overlay {
        RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius)
          .stroke(isSelected ? AppColors.accent.opacity(0.7) : AppColors.border, lineWidth: 1)
      }
    }
    .buttonStyle(.plain)
  }
}

private struct PaywallLoadingCard: View {
  var body: some View {
    HStack(spacing: AppSpacing.m) {
      ProgressView()
        .tint(AppColors.accent)

      Text("Loading subscription options")
        .font(AppTypography.body)
        .foregroundStyle(AppColors.textSecondary)
    }
    .padding(AppSpacing.m)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(
      AppColors.surface.opacity(0.78),
      in: RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius)
    )
  }
}

private struct PaywallUnavailableCard: View {
  let retry: () -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: AppSpacing.m) {
      PaywallMessageCard(
        icon: AppIcons.warning,
        message: unavailableMessage,
        tint: AppColors.warmAccent
      )

      Button(action: retry) {
        Label("Retry Loading Options", systemImage: AppIcons.repeatArrows)
          .font(AppTypography.bodyEmphasis)
          .frame(maxWidth: .infinity)
          .padding(.vertical, AppSpacing.s)
      }
      .buttonStyle(.plain)
      .foregroundStyle(AppColors.textPrimary)
      .background(
        AppColors.surfaceRaised,
        in: RoundedRectangle(cornerRadius: AppTheme.controlCornerRadius)
      )
    }
  }

  private var unavailableMessage: String {
    #if DEBUG
      "Subscription options are unavailable. For local testing, run the Drift scheme from Xcode with DriftPlus.storekit selected."
    #else
      "We couldn't load subscription options. Please try again."
    #endif
  }
}

private struct PaywallMessageCard: View {
  let icon: String
  let message: String
  let tint: Color

  var body: some View {
    HStack(alignment: .top, spacing: AppSpacing.s) {
      Image(systemName: icon)
        .font(.system(size: 15, weight: .semibold))
        .foregroundStyle(tint)
        .frame(width: 22)

      Text(message)
        .font(AppTypography.caption)
        .foregroundStyle(tint)
        .fixedSize(horizontal: false, vertical: true)
    }
    .padding(AppSpacing.m)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(
      tint.opacity(0.1),
      in: RoundedRectangle(cornerRadius: AppTheme.controlCornerRadius)
    )
    .overlay {
      RoundedRectangle(cornerRadius: AppTheme.controlCornerRadius)
        .stroke(tint.opacity(0.2), lineWidth: 1)
    }
  }
}

extension SubscriptionProduct.Plan {
  fileprivate var displayShortName: String {
    switch self {
    case .monthly: "Monthly"
    case .yearly: "Yearly"
    }
  }
}

#Preview {
  DriftPlusPaywallView(
    viewModel: DriftPlusPaywallViewModel(
      subscriptionService: DisabledSubscriptionService(),
      reasonMessage:
        "You've used today's 10 free Drifts. Come back tomorrow or upgrade for more daily Drifts."
    )
  )
}
