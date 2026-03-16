import SwiftUI

struct ProPaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var purchaseManager: PurchaseManager

    var onPurchased: (() -> Void)? = nil

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    heroCard
                    benefitsCard
                    purchaseCard
                }
                .padding(.horizontal, 20)
                .padding(.top, 18)
                .padding(.bottom, 32)
            }
            .background(SharedStyles.blockGradient(SharedStyles.GradientSet.warmCanvas).ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(L10n.Common.cancel) {
                        dismiss()
                    }
                }
            }
        }
        .task {
            await purchaseManager.loadProductsIfNeeded()
        }
    }

    private var heroCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 10) {
                    Text(L10n.Pro.badge)
                        .sharedTextStyle(SharedStyles.Text.microCaption, color: SharedStyles.primaryColor)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(SharedStyles.primaryColor.opacity(0.12))
                        .clipShape(Capsule())

                    Text(L10n.Pro.lifetimeTitle)
                        .sharedTextStyle(SharedStyles.Text.screenTitle)

                    Text(L10n.Pro.lifetimeSubtitle)
                        .sharedTextStyle(
                            SharedStyles.Text.body,
                            color: SharedStyles.secondaryTextColor,
                            lineSpacing: SharedStyles.bodyLineSpacing
                        )
                }

                Spacer()

                ZStack {
                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [SharedStyles.Accent.sky.opacity(0.22), SharedStyles.Accent.mint.opacity(0.36)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 74, height: 74)

                    Image(systemName: "crown.fill")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(SharedStyles.primaryColor)
                }
            }
        }
        .padding(22)
        .clayCard(tint: SharedStyles.Accent.sky, radius: 28)
    }

    private var benefitsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            benefitRow(
                icon: "icloud",
                tint: SharedStyles.Accent.sky,
                title: L10n.Pro.benefitICloudTitle,
                body: L10n.Pro.benefitICloudBody
            )

            Divider()

            benefitRow(
                icon: "scope",
                tint: SharedStyles.Accent.orange,
                title: L10n.Pro.benefitVisualTitle,
                body: L10n.Pro.benefitVisualBody
            )

            Divider()

            benefitRow(
                icon: "chart.xyaxis.line",
                tint: SharedStyles.Accent.teal,
                title: L10n.Pro.benefitAnalysisTitle,
                body: L10n.Pro.benefitAnalysisBody
            )
        }
        .padding(20)
        .clayCard(tint: SharedStyles.Accent.mint, radius: 24)
    }

    private var purchaseCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 4) {
                    if purchaseManager.isLoadingProduct {
                        ProgressView()
                    } else if let product = purchaseManager.proProduct {
                        Text(product.displayPrice)
                            .sharedTextStyle(SharedStyles.Text.metricValue)
                    }
                }

                Spacer()

                if purchaseManager.isProUnlocked {
                    Text(L10n.Pro.alreadyUnlocked)
                        .sharedTextStyle(SharedStyles.Text.caption, color: SharedStyles.primaryColor)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(SharedStyles.primaryColor.opacity(0.12))
                        .clipShape(Capsule())
                }
            }

            if let purchaseErrorMessage = purchaseManager.purchaseErrorMessage, !purchaseErrorMessage.isEmpty {
                Text(purchaseErrorMessage)
                    .sharedTextStyle(SharedStyles.Text.caption, color: SharedStyles.Accent.coral)
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(SharedStyles.Accent.coral.opacity(0.10))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }

            Button {
                Task {
                    let success = await purchaseManager.purchasePro()
                    if success {
                        onPurchased?()
                        dismiss()
                    }
                }
            } label: {
                HStack {
                    Spacer()

                    if purchaseManager.isPurchasing {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text(L10n.Pro.unlockNow)
                            .font(SharedStyles.Text.bodyEmphasis)
                    }

                    Spacer()
                }
                .foregroundStyle(.white)
                .padding(.vertical, 16)
            }
            .buttonStyle(.plain)
            .disabled(purchaseManager.isPurchasing || purchaseManager.isProUnlocked)
            .blockSurface(colors: SharedStyles.GradientSet.sunrise, radius: 18)
            .opacity((purchaseManager.isPurchasing || purchaseManager.isProUnlocked) ? 0.72 : 1)

            Button {
                Task {
                    await purchaseManager.restorePurchases()
                    if purchaseManager.isProUnlocked {
                        onPurchased?()
                        dismiss()
                    }
                }
            } label: {
                Text(L10n.Pro.restore)
                    .sharedTextStyle(SharedStyles.Text.bodyEmphasis, color: SharedStyles.primaryColor)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.white.opacity(0.72))
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
            .buttonStyle(.plain)
        }
        .padding(20)
        .clayCard(tint: SharedStyles.Accent.violet, radius: 24)
    }

    private func benefitRow(icon: String, tint: Color, title: String, body: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: 38, height: 38)
                .background(tint.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .sharedTextStyle(SharedStyles.Text.bodyEmphasis)

                Text(body)
                    .sharedTextStyle(
                        SharedStyles.Text.caption,
                        color: SharedStyles.secondaryTextColor,
                        lineSpacing: SharedStyles.captionLineSpacing
                    )
            }

            Spacer(minLength: 0)
        }
    }
}

#Preview {
    ProPaywallView()
        .environmentObject(PurchaseManager())
}
