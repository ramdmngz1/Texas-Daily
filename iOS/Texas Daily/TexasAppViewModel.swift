//
//  TexasAppViewModel.swift
//  Texas Daily
//
//  Created by Ramon Dominguez on 12/03/25.
//

import Foundation
import Combine
import StoreKit
import SwiftUI

@MainActor
final class TexasAppViewModel: ObservableObject {

    // MARK: - Published state used by the UI
    @Published var todayFact: TexasFact? = nil
    @Published var selectedCategories: Set<String> = []
    @Published var notificationTime: Date
    @Published var adsRemoved: Bool
    @Published var isVerifyingEntitlements: Bool = true
    @Published var adsSDKReady: Bool = false

    // Computed once at init — facts are immutable at runtime
    let availableCategories: [String]

    // Purchase / restore status shown in SettingsView
    @Published var purchaseStatusMessage: String? = nil

    // MARK: - Storage keys
    private let selectedCategoriesKey = "tx_selectedCategories"
    private let reminderHourKey = "tx_reminder_hour"
    private let reminderMinuteKey = "tx_reminder_minute"
    private let dailyReminderEnabledKey = "tx_dailyReminderEnabled"

    // ✅ Put your real StoreKit product id here
    private let removeAdsProductId = "com.refuge.texasdaily.removead"

    // StoreKit listener task
    private var transactionUpdatesTask: Task<Void, Never>?

    // MARK: - Init
    init() {
        // adsRemoved is always false on launch; StoreKit is the sole source of truth
        self.adsRemoved = false

        // Cache sorted unique categories once — facts never change at runtime
        self.availableCategories = Array(Set(FactStore.shared.facts.map { $0.category })).sorted()

        // Load persisted category selection, filtering out any stale categories
        // that no longer exist in the current fact set (e.g. after a content update)
        if let arr = UserDefaults.standard.array(forKey: selectedCategoriesKey) as? [String] {
            let validCategories = Set(self.availableCategories)
            self.selectedCategories = Set(arr).intersection(validCategories)
        } else {
            self.selectedCategories = []
        }

        // Load notification time (default 9:00 AM)
        let hour: Int
        let minute: Int

        if UserDefaults.standard.object(forKey: reminderHourKey) != nil {
            hour = UserDefaults.standard.integer(forKey: reminderHourKey)
            minute = UserDefaults.standard.integer(forKey: reminderMinuteKey)
        } else {
            hour = 9
            minute = 0
        }

        var comps = DateComponents()
        comps.hour = hour
        comps.minute = minute
        self.notificationTime = Calendar.current.date(from: comps) ?? Date()

        // Seed the first fact
        refreshTodayFact(haptic: false)

        // Refresh entitlements on launch (important for restore)
        Task { await refreshEntitlements() }
    }

    // MARK: - Facts
    func refreshTodayFact(haptic: Bool = true) {
        if haptic { Haptics.light() }
        let currentID = todayFact?.id
        let next = FactStore.shared.randomFact(from: selectedCategories, excluding: currentID)
                ?? FactStore.shared.randomFact(excluding: currentID)
        withAnimation(.easeInOut(duration: 0.25)) {
            todayFact = next
        }
    }

    // MARK: - Category Selection

    func toggleCategory(_ category: String) {
        if selectedCategories.contains(category) {
            selectedCategories.remove(category)
        } else {
            selectedCategories.insert(category)
        }
        saveSelectedCategories()
        refreshTodayFact(haptic: false)
    }

    func clearCategories() {
        selectedCategories = []
        saveSelectedCategories()
        refreshTodayFact(haptic: false)
    }

    private func saveSelectedCategories() {
        UserDefaults.standard.set(Array(selectedCategories), forKey: selectedCategoriesKey)
    }

    // MARK: - Notifications
    /// Called by SettingsView "Save" button.
    func saveNotificationTime() {
        let comps = Calendar.current.dateComponents([.hour, .minute], from: notificationTime)
        UserDefaults.standard.set(comps.hour ?? 9, forKey: reminderHourKey)
        UserDefaults.standard.set(comps.minute ?? 0, forKey: reminderMinuteKey)

        Task { await scheduleDailyReminderIfEnabled() }
    }

    /// Called on app launch (TexasDailyApp.swift) and after saving time.
    func scheduleDailyReminderIfEnabled() async {
        let enabled = UserDefaults.standard.object(forKey: dailyReminderEnabledKey) as? Bool ?? false
        let center = NotificationManager.shared

        if !enabled {
            await center.cancelDailyFactNotification()
            return
        }

        let comps = Calendar.current.dateComponents([.hour, .minute], from: notificationTime)

        // Use the currently displayed fact, or grab one
        let factToSend = todayFact ?? FactStore.shared.randomFact(from: selectedCategories)

        await center.scheduleDailyFactNotification(at: comps, fact: factToSend)
    }

    // MARK: - StoreKit (Remove Ads)
    func buyRemoveAds() async {
        purchaseStatusMessage = nil
        do {
            let products = try await Product.products(for: [removeAdsProductId])
            guard let product = products.first else {
                purchaseStatusMessage = "Remove Ads product not found."
                return
            }

            let result = try await product.purchase()

            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await transaction.finish()
                await refreshEntitlements()
            case .userCancelled:
                purchaseStatusMessage = "Purchase cancelled."
            case .pending:
                purchaseStatusMessage = "Purchase pending — check back soon."
            @unknown default:
                purchaseStatusMessage = "Unknown purchase result."
            }
        } catch {
            purchaseStatusMessage = "Purchase error: \(error.localizedDescription)"
        }
    }

    func restorePurchases() async {
        purchaseStatusMessage = nil
        await refreshEntitlements()
        if adsRemoved { return }

        do {
            try await AppStore.sync()
            await refreshEntitlements()
            if !adsRemoved {
                purchaseStatusMessage = "No purchases found to restore."
            }
        } catch {
            purchaseStatusMessage = "Restore error: \(error.localizedDescription)"
        }
    }

    /// ✅ Fixed: no Task.detached, so we can safely call @MainActor methods.
    func startStoreKitListener() {
        if transactionUpdatesTask != nil { return }

        transactionUpdatesTask = Task { [weak self] in
            guard let self else { return }

            for await update in Transaction.updates {
                do {
                    _ = try self.checkVerified(update)
                    await self.refreshEntitlements()
                } catch {
                    // Ignore unverified transactions
                }
            }
        }
    }

    private func refreshEntitlements() async {
        var hasRemoveAds = false

        for await result in Transaction.currentEntitlements {
            guard let transaction = try? checkVerified(result) else { continue }
            if transaction.productID == removeAdsProductId {
                hasRemoveAds = true
            }
        }

        adsRemoved = hasRemoveAds
        isVerifyingEntitlements = false
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified(_, let error):
            throw error
        case .verified(let signed):
            return signed
        }
    }

    deinit {
        transactionUpdatesTask?.cancel()
    }
}
