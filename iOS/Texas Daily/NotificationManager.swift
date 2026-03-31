//
//  NotificationManager.swift
//  Texas Daily
//
//  Created by Ramon Dominguez on 12/3/25.
//
//
import Foundation
import UserNotifications
import UIKit

@MainActor
final class NotificationManager {
    static let shared = NotificationManager()
    private init() {}

    // Call this anytime you need to ensure permissions exist.
    func ensureAuthorization() async -> Bool {
        let center = UNUserNotificationCenter.current()

        let settings = await center.notificationSettings()
        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            return true

        case .denied:
            return false

        case .notDetermined:
            do {
                let granted = try await requestAuthorization()
                return granted
            } catch {
                return false
            }

        @unknown default:
            return false
        }
    }

    // ✅ Was private before; keep it fileprivate/private to this type, but it's ONLY called internally now.
    private func requestAuthorization() async throws -> Bool {
        try await withCheckedThrowingContinuation { continuation in
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: granted)
                }
            }
        }
    }

    func openSystemNotificationSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }

    func cancelDailyFactNotification() async {
        let center = UNUserNotificationCenter.current()

        // Remove new-style batch notifications ("dailyTexasFact_0" … "dailyTexasFact_59")
        let pending = await center.pendingNotificationRequests()
        let pendingIds = pending.map { $0.identifier }.filter { $0.hasPrefix("dailyTexasFact") }
        center.removePendingNotificationRequests(withIdentifiers: pendingIds)

        // Remove old-style single repeating notification ("dailyTexasFact") and any
        // already-delivered notifications from both naming schemes from the notification center.
        let delivered = await center.deliveredNotifications()
        let deliveredIds = delivered.map { $0.request.identifier }.filter { $0.hasPrefix("dailyTexasFact") }
        center.removeDeliveredNotifications(withIdentifiers: deliveredIds)
    }

    func scheduleDailyFactNotification(at time: DateComponents) async {
        let center = UNUserNotificationCenter.current()

        guard await ensureAuthorization() else { return }

        // Remove all previously scheduled daily fact notifications
        await cancelDailyFactNotification()

        let calendar = Calendar.current
        let now = Date()
        var lastFactID: Int? = nil
        var scheduledCount = 0

        // Schedule up to 60 one-time notifications, one per day, each with a unique fact.
        // iOS caps pending local notifications at 64; 60 leaves headroom for other app notifications.
        for dayOffset in 0..<60 {
            guard let baseDate = calendar.date(byAdding: .day, value: dayOffset, to: now) else { continue }

            var components = calendar.dateComponents([.year, .month, .day], from: baseDate)
            components.hour = time.hour
            components.minute = time.minute
            components.second = 0

            // Skip fire times that have already passed today
            guard let fireDate = calendar.date(from: components), fireDate > now else { continue }

            guard let fact = FactStore.shared.randomFact(excluding: lastFactID) else { continue }
            lastFactID = fact.id

            let content = UNMutableNotificationContent()
            content.title = "Texas Daily Fact"
            content.body = fact.fact
            content.sound = .default

            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            let request = UNNotificationRequest(
                identifier: "dailyTexasFact_\(dayOffset)",
                content: content,
                trigger: trigger
            )

            do {
                try await center.add(request)
                scheduledCount += 1
            } catch {
                #if DEBUG
                print("⚠️ Failed to schedule notification for day \(dayOffset): \(error)")
                #endif
            }
        }

        #if DEBUG
        print("✅ Scheduled \(scheduledCount) daily fact notifications")
        #endif
    }

}
