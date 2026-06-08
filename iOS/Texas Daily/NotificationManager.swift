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

    private func requestAuthorization() async throws -> Bool {
        try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
    }

    func openSystemNotificationSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }

    func cancelDailyFactNotification() {
        let center = UNUserNotificationCenter.current()
        var ids = (0..<60).map { "dailyTexasFact_\($0)" }
        ids.append("dailyTexasFact")
        center.removePendingNotificationRequests(withIdentifiers: ids)
        center.removeDeliveredNotifications(withIdentifiers: ids)
    }

    func scheduleDailyFactNotification(at time: DateComponents) async {
        let center = UNUserNotificationCenter.current()

        guard await ensureAuthorization() else { return }

        cancelDailyFactNotification()

        let allFacts = FactStore.shared.facts
        guard !allFacts.isEmpty else { return }
        let shuffled = allFacts.shuffled()

        let calendar = Calendar.current
        let now = Date()
        var scheduledCount = 0

        for dayOffset in 0..<60 {
            guard let baseDate = calendar.date(byAdding: .day, value: dayOffset, to: now) else { continue }

            var components = calendar.dateComponents([.year, .month, .day], from: baseDate)
            components.hour = time.hour
            components.minute = time.minute
            components.second = 0

            guard let fireDate = calendar.date(from: components), fireDate > now else { continue }

            let fact = shuffled[scheduledCount % shuffled.count]

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
