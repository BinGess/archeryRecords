import Foundation
import OSLog
import StoreKit

private enum ProPurchaseLogging {
    static let log = Logger(subsystem: Bundle.main.bundleIdentifier ?? "archeryRecord", category: "IAP")
}

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
    /// Coalesces concurrent `loadProductsIfNeeded` callers so purchase can await one shared request.
    private var productsRequestTask: Task<Void, Never>?

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
        if proProduct != nil { return }
        if let productsRequestTask {
            await productsRequestTask.value
            return
        }

        let task = Task { @MainActor [weak self] in
            guard let self else { return }
            await self.executeProductsRequest()
        }
        productsRequestTask = task
        await task.value
    }

    func purchasePro() async -> Bool {
        ProPurchaseLogging.log.debug("purchasePro started, id=\(self.productIdentifier, privacy: .public)")

        guard !isPurchasing else {
            ProPurchaseLogging.log.debug("purchasePro skipped: already in progress")
            return false
        }

        isPurchasing = true
        defer { isPurchasing = false }

        await loadProductsIfNeeded()

        guard let proProduct else {
            ProPurchaseLogging.log.error("purchasePro aborted: no Product loaded")
            if purchaseErrorMessage == nil {
                purchaseErrorMessage = L10n.Pro.purchaseUnavailable
            }
            return false
        }

        purchaseErrorMessage = nil
        ProPurchaseLogging.log.debug("purchasePro calling StoreKit purchase()")

        do {
            let result = try await proProduct.purchase()

            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await unlock(with: transaction)
                await transaction.finish()
                ProPurchaseLogging.log.debug("purchasePro success")
                return true
            case .pending:
                purchaseErrorMessage = L10n.Pro.purchasePending
                ProPurchaseLogging.log.debug("purchasePro pending (e.g. Ask to Buy)")
                return false
            case .userCancelled:
                ProPurchaseLogging.log.debug("purchasePro user cancelled")
                return false
            @unknown default:
                purchaseErrorMessage = L10n.Pro.purchaseFailed
                ProPurchaseLogging.log.error("purchasePro unknown result")
                return false
            }
        } catch {
            purchaseErrorMessage = error.localizedDescription
            ProPurchaseLogging.log.error("purchasePro error: \(error.localizedDescription, privacy: .public)")
            return false
        }
    }

    private func executeProductsRequest() async {
        isLoadingProduct = true
        defer {
            isLoadingProduct = false
            productsRequestTask = nil
        }

        do {
            let products = try await Product.products(for: [productIdentifier])
            if products.isEmpty {
                ProPurchaseLogging.log.error("Product.products returned empty for id=\(self.productIdentifier, privacy: .public)")
                purchaseErrorMessage = L10n.Pro.purchaseUnavailable
            } else {
                purchaseErrorMessage = nil
                proProduct = products.first
                ProPurchaseLogging.log.debug("Loaded product count=\(products.count, privacy: .public)")
            }
        } catch {
            ProPurchaseLogging.log.error("Product.products failed: \(error.localizedDescription, privacy: .public)")
            purchaseErrorMessage = error.localizedDescription
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
