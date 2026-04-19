import Combine
import Foundation
import StoreKit

enum ProFeature: String, Identifiable {
    case icloudSync
    case visualTargetInput
    case advancedAnalytics

    var id: String { rawValue }

    var title: String {
        switch self {
        case .icloudSync:
            return L10n.Pro.entryICloudTitle
        case .visualTargetInput:
            return L10n.Pro.entryVisualTitle
        case .advancedAnalytics:
            return L10n.Pro.entryAnalyticsTitle
        }
    }

    var subtitle: String {
        switch self {
        case .icloudSync:
            return L10n.Pro.entryICloudSubtitle
        case .visualTargetInput:
            return L10n.Pro.entryVisualSubtitle
        case .advancedAnalytics:
            return L10n.Pro.entryAnalyticsSubtitle
        }
    }

    var iconSystemName: String {
        switch self {
        case .icloudSync:
            return "icloud"
        case .visualTargetInput:
            return "scope"
        case .advancedAnalytics:
            return "chart.bar.xaxis"
        }
    }
}

@MainActor
final class PurchaseManager: ObservableObject {
    static let fallbackProductID = "com.timmy.archeryrecord.pro.lifetime"

    @Published private(set) var isProUnlocked: Bool
    @Published private(set) var proProduct: Product?
    @Published private(set) var isLoadingProduct = false
    @Published private(set) var isPurchasing = false
    @Published var purchaseErrorMessage: String?

    private let userDefaults: UserDefaults
    private let proUnlockedKey = "archeryRecord.proLifetimeUnlocked"
    private var transactionUpdatesTask: Task<Void, Never>?

    var productDisplayPrice: String {
        proProduct?.displayPrice ?? L10n.Pro.ctaPriceFallback
    }

    var productIdentifier: String {
        Bundle.main.object(forInfoDictionaryKey: "ProProductID") as? String ?? Self.fallbackProductID
    }

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        self.isProUnlocked = userDefaults.bool(forKey: proUnlockedKey)

        transactionUpdatesTask = Task {
            await observeTransactionUpdates()
        }

        Task {
            await refreshEntitlements()
            await loadProductsIfNeeded()
        }
    }

    deinit {
        transactionUpdatesTask?.cancel()
    }

    func loadProductsIfNeeded() async {
        guard proProduct == nil, !isLoadingProduct else { return }

        isLoadingProduct = true
        defer { isLoadingProduct = false }

        do {
            let products = try await Product.products(for: [productIdentifier])
            if products.isEmpty {
                purchaseErrorMessage = L10n.Pro.purchaseUnavailable
            } else {
                purchaseErrorMessage = nil
                proProduct = products.first
            }
        } catch {
            purchaseErrorMessage = error.localizedDescription
        }
    }

    func purchasePro() async -> Bool {
        await loadProductsIfNeeded()

        // If a concurrent load is already in progress, wait for it to finish
        if proProduct == nil && isLoadingProduct {
            for await loading in $isLoadingProduct.values {
                if !loading { break }
            }
        }

        guard let proProduct else {
            purchaseErrorMessage = L10n.Pro.purchaseUnavailable
            return false
        }

        isPurchasing = true
        purchaseErrorMessage = nil
        defer { isPurchasing = false }

        do {
            let result = try await proProduct.purchase()

            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await unlock(with: transaction)
                await transaction.finish()
                return true
            case .pending:
                purchaseErrorMessage = L10n.Pro.purchasePending
                return false
            case .userCancelled:
                return false
            @unknown default:
                purchaseErrorMessage = L10n.Pro.purchaseFailed
                return false
            }
        } catch {
            purchaseErrorMessage = error.localizedDescription
            return false
        }
    }

    func restorePurchases() async {
        purchaseErrorMessage = nil

        do {
            try await AppStore.sync()
            await refreshEntitlements()
        } catch {
            purchaseErrorMessage = error.localizedDescription
        }
    }

    private func observeTransactionUpdates() async {
        for await result in Transaction.updates {
            do {
                let transaction = try checkVerified(result)
                guard transaction.productID == productIdentifier else {
                    await transaction.finish()
                    continue
                }

                await unlock(with: transaction)
                await transaction.finish()
            } catch {
                await MainActor.run {
                    self.purchaseErrorMessage = error.localizedDescription
                }
            }
        }
    }

    private func refreshEntitlements() async {
        var unlocked = false

        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else { continue }
            guard transaction.productID == productIdentifier else { continue }
            guard transaction.revocationDate == nil else { continue }
            unlocked = true
            break
        }

        isProUnlocked = unlocked
        userDefaults.set(unlocked, forKey: proUnlockedKey)
    }

    private func unlock(with transaction: Transaction) async {
        guard transaction.revocationDate == nil else { return }

        isProUnlocked = true
        userDefaults.set(true, forKey: proUnlockedKey)
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .verified(let safe):
            return safe
        case .unverified:
            throw StoreError.failedVerification
        }
    }
}

extension PurchaseManager {
    enum StoreError: LocalizedError {
        case failedVerification

        var errorDescription: String? {
            switch self {
            case .failedVerification:
                return L10n.Pro.purchaseFailed
            }
        }
    }
}
