import Foundation
import StoreKit

@MainActor
final class StoreKitManager: ObservableObject {

    @Published var adsRemoved: Bool
    @Published var isVerifying: Bool = true
    @Published var statusMessage: String? = nil

    private var transactionTask: Task<Void, Never>?

    init() {
        // S1 FIX: Default to false (show ads) until server-signed entitlements are verified.
        // The cached value is only used after at least one successful verification this session.
        self.adsRemoved = false
    }

    func startListener() {
        guard transactionTask == nil else { return }
        transactionTask = Task { [weak self] in
            guard let self else { return }
            for await update in Transaction.updates {
                do {
                    _ = try self.verify(update)
                    await self.refreshEntitlements()
                } catch {}
            }
        }
    }

    func buy() async {
        statusMessage = nil
        do {
            let products = try await Product.products(for: [PreferenceKeys.removeAdsProductId])
            guard let product = products.first else {
                statusMessage = "Remove Ads product not found."
                return
            }
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                let transaction = try verify(verification)
                await transaction.finish()
                await refreshEntitlements()
            case .userCancelled:
                statusMessage = "Purchase cancelled."
            case .pending:
                statusMessage = "Purchase pending — check back soon."
            @unknown default:
                statusMessage = "Unknown purchase result."
            }
        } catch {
            #if DEBUG
            print("Purchase error: \(error.localizedDescription)")
            #endif
            statusMessage = "Purchase failed. Please try again."
        }
    }

    func restore() async {
        statusMessage = nil
        await refreshEntitlements()
        if adsRemoved { return }
        do {
            try await AppStore.sync()
            await refreshEntitlements()
            if !adsRemoved {
                statusMessage = "No purchases found to restore."
            }
        } catch {
            #if DEBUG
            print("Restore error: \(error.localizedDescription)")
            #endif
            statusMessage = "Restore failed. Please try again."
        }
    }

    func refreshEntitlements() async {
        var hasRemoveAds = false
        for await result in Transaction.currentEntitlements {
            guard let transaction = try? verify(result) else { continue }
            if transaction.productID == PreferenceKeys.removeAdsProductId {
                hasRemoveAds = true
            }
        }
        adsRemoved = hasRemoveAds
        UserDefaults.standard.set(hasRemoveAds, forKey: PreferenceKeys.adsRemovedCached)
        isVerifying = false
    }

    private func verify<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified(_, let error): throw error
        case .verified(let signed): return signed
        }
    }

    deinit {
        transactionTask?.cancel()
    }
}
