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
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: ["dailyTexasFact"])
    }

    func scheduleDailyFactNotification(at time: DateComponents) async {
        let center = UNUserNotificationCenter.current()

        guard await ensureAuthorization() else {
            return
        }

        // Clear old requests for a single “daily” notification
        center.removePendingNotificationRequests(withIdentifiers: ["dailyTexasFact"])

        let content = UNMutableNotificationContent()
        content.title = "Texas Daily Fact"
        content.body = "Tap to read today's Texas fact."
        content.sound = .default

        let trigger = UNCalendarNotificationTrigger(dateMatching: time, repeats: true)

        let request = UNNotificationRequest(
            identifier: "dailyTexasFact",
            content: content,
            trigger: trigger
        )

        do {
            try await center.add(request)
        } catch {
            #if DEBUG
            print("⚠️ Failed to schedule daily fact notification: \(error)")
            #endif
        }
    }

}
