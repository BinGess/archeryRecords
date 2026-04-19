import SwiftUI

struct ProPaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var purchaseManager: PurchaseManager

    var onPurchased: (() -> Void)? = nil

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    Group {
                        if purchaseManager.isProUnlocked {
                            memberStatusHero
                        } else {
                            marketingHeroCard
                        }
                    }
                    benefitsCard
                }
                .padding(.horizontal, 20)
                .padding(.top, 18)
                .padding(.bottom, 32)
            }
            .background(SharedStyles.blockGradient(SharedStyles.GradientSet.warmCanvas).ignoresSafeArea())
            .safeAreaInset(edge: .bottom, spacing: 0) {
                purchaseFooter
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .padding(.bottom, 10)
            }
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

    /// Shown when the user already owns Pro — strong visual confirmation.
    private var memberStatusHero: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top, spacing: 18) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    SharedStyles.Accent.mint.opacity(0.85),
                                    SharedStyles.Accent.teal.opacity(0.72)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 76, height: 76)
                        .overlay {
                            Circle()
                                .stroke(Color.white.opacity(0.38), lineWidth: 1.2)
                                .allowsHitTesting(false)
                        }
                        .shadow(color: SharedStyles.Accent.teal.opacity(0.35), radius: 12, x: 0, y: 8)

                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 36, weight: .semibold))
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.15), radius: 2, x: 0, y: 1)
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text(L10n.Pro.memberStatusBadge)
                        .sharedTextStyle(SharedStyles.Text.microCaption, color: SharedStyles.primaryColor)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            LinearGradient(
                                colors: [
                                    SharedStyles.Accent.mint.opacity(0.28),
                                    SharedStyles.Accent.teal.opacity(0.14)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(Capsule())

                    Text(L10n.Pro.memberStatusTitle)
                        .sharedTextStyle(SharedStyles.Text.screenTitle)

                    Text(L10n.Pro.memberStatusSubtitle)
                        .sharedTextStyle(
                            SharedStyles.Text.body,
                            color: SharedStyles.secondaryTextColor,
                            lineSpacing: SharedStyles.bodyLineSpacing
                        )
                }
            }
        }
        .padding(22)
        .clayCard(tint: SharedStyles.Accent.mint, radius: 28)
    }

    private var marketingHeroCard: some View {
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
            if purchaseManager.isProUnlocked {
                Text(L10n.Pro.memberBenefitsSectionTitle)
                    .sharedTextStyle(SharedStyles.Text.bodyEmphasis, color: SharedStyles.primaryColor)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            benefitRow(
                icon: "icloud",
                tint: SharedStyles.Accent.sky,
                title: L10n.Pro.benefitICloudTitle,
                body: L10n.Pro.benefitICloudBody,
                showIncluded: purchaseManager.isProUnlocked
            )

            Divider()

            benefitRow(
                icon: "scope",
                tint: SharedStyles.Accent.orange,
                title: L10n.Pro.benefitVisualTitle,
                body: L10n.Pro.benefitVisualBody,
                showIncluded: purchaseManager.isProUnlocked
            )

            Divider()

            benefitRow(
                icon: "chart.xyaxis.line",
                tint: SharedStyles.Accent.teal,
                title: L10n.Pro.benefitAnalysisTitle,
                body: L10n.Pro.benefitAnalysisBody,
                showIncluded: purchaseManager.isProUnlocked
            )
        }
        .padding(20)
        .clayCard(tint: SharedStyles.Accent.mint, radius: 24)
    }

    @ViewBuilder
    private var purchaseFooter: some View {
        if purchaseManager.isProUnlocked {
            memberPurchaseFooter
        } else {
            standardPurchaseFooter
        }
    }

    private var memberPurchaseFooter: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 14) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 32, weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [SharedStyles.Accent.mint, SharedStyles.Accent.teal],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                VStack(alignment: .leading, spacing: 8) {
                    Text(L10n.Pro.memberOwnedBanner)
                        .sharedTextStyle(SharedStyles.Text.bodyEmphasis)

                    Text(L10n.Pro.memberFooterHint)
                        .sharedTextStyle(
                            SharedStyles.Text.caption,
                            color: SharedStyles.secondaryTextColor,
                            lineSpacing: SharedStyles.captionLineSpacing
                        )
                }
            }
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                SharedStyles.Accent.mint.opacity(0.18),
                                SharedStyles.Accent.teal.opacity(0.10)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(SharedStyles.Accent.mint.opacity(0.35), lineWidth: 1)
                    .allowsHitTesting(false)
            }

            Button {
                NSLog("ArcheryRecord IAP: restore tapped")
                Task { @MainActor in
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
        .frame(maxWidth: .infinity, alignment: .leading)
        .clayCard(tint: SharedStyles.Accent.violet, radius: 24)
    }

    private var standardPurchaseFooter: some View {
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
                NSLog("ArcheryRecord IAP: unlock button action fired")
                print("ArcheryRecord IAP: unlock button action fired")
                Task { @MainActor in
                    NSLog("ArcheryRecord IAP: purchase Task started")
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
            .contentShape(Rectangle())
            .blockSurface(colors: SharedStyles.GradientSet.sunrise, radius: 18)
            .opacity((purchaseManager.isPurchasing || purchaseManager.isProUnlocked) ? 0.72 : 1)

            Button {
                NSLog("ArcheryRecord IAP: restore tapped")
                Task { @MainActor in
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
        .frame(maxWidth: .infinity, alignment: .leading)
        .clayCard(tint: SharedStyles.Accent.violet, radius: 24)
    }

    private func benefitRow(icon: String, tint: Color, title: String, body: String, showIncluded: Bool = false) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: 38, height: 38)
                .background(tint.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(title)
                        .sharedTextStyle(SharedStyles.Text.bodyEmphasis)

                    if showIncluded {
                        Text(L10n.Pro.benefitIncludedChip)
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(SharedStyles.Accent.teal)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(SharedStyles.Accent.mint.opacity(0.22))
                            .clipShape(Capsule())
                    }
                }

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
