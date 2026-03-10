//  SettingsView.swift
//  Texas Daily
//
//  Reworked for Texas Daily look & features:
//  - Daily reminder toggle + time picker
//  - Dark / Light theme picker using ThemeMode + AppStorage
//
//
//  SettingsView.swift
//  Texas Daily
//
//  Settings:
//  - Daily reminder toggle + time picker + "Save & Schedule" acknowledgment
//  - Light/Dark mode picker (AppStorage themeMode)
//  - Support Us: Remove Ads + Restore Purchases (StoreKit restore mechanism)
//

import SwiftUI
import UserMessagingPlatform
import GoogleMobileAds
import UIKit

struct SettingsView: View {
    @EnvironmentObject var viewModel: TexasAppViewModel

    @AppStorage("themeMode") private var themeModeRaw: String = ThemeMode.light.rawValue
    @AppStorage("tx_dailyReminderEnabled") private var dailyReminderEnabled: Bool = false

    @Environment(\.dismiss) private var dismiss

    // Saved banner + “current time” display state
    @State private var showSavedBanner = false
    @State private var lastSavedNotificationTime: Date? = nil

    // Optional: simple loading states for buttons (no dependency on viewModel internals)
    @State private var isAttemptingPurchase = false
    @State private var isAttemptingRestore = false
    @State private var isPresentingPrivacyChoices = false
    @State private var privacyStatusMessage: String? = nil

    // MARK: - Theme helpers

    private var themeMode: ThemeMode {
        ThemeMode(rawValue: themeModeRaw) ?? .light
    }

    /// Use the user's selection for how Settings renders *immediately*.
    private var effectiveColorScheme: ColorScheme {
        (themeMode == .dark) ? .dark : .light
    }

    // MARK: - Palette (match TodayFactView)

    private var backgroundColor: Color {
        effectiveColorScheme == .dark
        ? Color(red: 0.07, green: 0.08, blue: 0.10)   // deep charcoal
        : Color(red: 0.97, green: 0.96, blue: 0.90)   // limestone
    }

    private var inkColor: Color {
        effectiveColorScheme == .dark
        ? .white
        : Color(red: 0.30, green: 0.21, blue: 0.16)   // pecan brown
    }

    private var cardColor: Color {
        effectiveColorScheme == .dark
        ? Color(red: 0.16, green: 0.18, blue: 0.20)
        : Color.white.opacity(0.98)
    }

    private var accentGreen: Color {
        Color(red: 0.52, green: 0.65, blue: 0.23)
    }

    private var privacyOptionsRequired: Bool {
        ConsentInformation.shared.privacyOptionsRequirementStatus == .required
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            backgroundColor
                .ignoresSafeArea()

            PaperBackground()
                .ignoresSafeArea()
                .opacity(effectiveColorScheme == .dark ? 0 : 0.35)

            VStack(spacing: 0) {
                header

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        reminderCard
                        appearanceCard
                        supportCard
                        aboutSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .padding(.bottom, 24)
                }
            }

            // Lightweight “Saved” banner
            if showSavedBanner {
                VStack {
                    HStack(spacing: 10) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(accentGreen)
                        Text("Saved & scheduled.")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(inkColor)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(cardColor)
                    )
                    .shadow(color: Color.black.opacity(0.10), radius: 10, x: 0, y: 6)
                    .padding(.top, 10)

                    Spacer()
                }
                .transition(.move(edge: .top).combined(with: .opacity))
                .animation(.spring(response: 0.3, dampingFraction: 0.85), value: showSavedBanner)
            }
        }
        // IMPORTANT: This makes the Settings screen re-render instantly when user changes theme.
        .environment(\.colorScheme, effectiveColorScheme)
        .onAppear {
            // Show something sensible right away
            lastSavedNotificationTime = viewModel.notificationTime
        }
        .onChange(of: dailyReminderEnabled) { _ in
            // Turning reminders off should immediately cancel the pending notification.
            guard dailyReminderEnabled == false else { return }
            Task { await viewModel.scheduleDailyReminderIfEnabled() }
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Button {
                Haptics.light()
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(inkColor)
                    .padding(8)
                    .frame(minWidth: 44, minHeight: 44)
                    .background(
                        Circle()
                            .fill(effectiveColorScheme == .dark ? backgroundColor : Color.white.opacity(0.90))
                    )
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Close settings")

            Spacer()

            Text("Settings")
                .font(.system(size: 22, weight: .bold, design: .serif))
                .foregroundColor(inkColor)

            Spacer()

            Color.clear.frame(width: 32, height: 32)
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
    }

    // MARK: - Daily Reminder Card

    private var reminderCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Daily Reminder")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(inkColor)

                    Text("Get a Texas fact at a time you choose.")
                        .font(.system(size: 14))
                        .foregroundColor(inkColor.opacity(0.7))
                }

                Spacer()

                Toggle(isOn: $dailyReminderEnabled) { EmptyView() }
                    .labelsHidden()
                    .tint(accentGreen)
                    .accessibilityLabel("Daily reminder")
                    .accessibilityHint(dailyReminderEnabled ? "On. Double tap to turn off." : "Off. Double tap to turn on.")
            }

            if dailyReminderEnabled {
                Divider().opacity(0.25)

                VStack(alignment: .leading, spacing: 10) {
                    Text("Reminder Time")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(inkColor)

                    DatePicker(
                        "",
                        selection: $viewModel.notificationTime,
                        displayedComponents: .hourAndMinute
                    )
                    .datePickerStyle(.wheel)
                    .labelsHidden()
                    .frame(maxWidth: .infinity)
                    .clipped()

                    if let lastSaved = lastSavedNotificationTime {
                        Text("Saved time: \(formattedTime(lastSaved))")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(inkColor.opacity(0.8))
                    }

                    Button {
                        Haptics.medium()
                        viewModel.saveNotificationTime()
                        lastSavedNotificationTime = viewModel.notificationTime

                        withAnimation {
                            showSavedBanner = true
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            withAnimation {
                                showSavedBanner = false
                            }
                        }
                    } label: {
                        Text("Save & Schedule")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(accentGreen)
                            )
                    }
                    .buttonStyle(.plain)

                    Text("We’ll send a daily notification at \(formattedTime(viewModel.notificationTime)).")
                        .font(.system(size: 12))
                        .foregroundColor(inkColor.opacity(0.6))
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(cardColor)
        )
        .shadow(color: Color.black.opacity(0.06), radius: 14, x: 0, y: 8)
    }

    // MARK: - Appearance Card

    private var appearanceCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Appearance")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(inkColor)

            Text("Choose how Texas Daily looks on your device.")
                .font(.system(size: 14))
                .foregroundColor(inkColor.opacity(0.7))

            Picker("Theme", selection: $themeModeRaw) {
                ForEach(ThemeMode.allCases) { mode in
                    Text(mode.displayName).tag(mode.rawValue)
                }
            }
            .pickerStyle(.segmented)
            .padding(.top, 6)

            HStack(spacing: 8) {
                Image(systemName: themeMode == .dark ? "moon.stars.fill" : "sun.max.fill")
                    .foregroundColor(accentGreen)

                Text(themeMode == .dark ? "Dark Mode is active." : "Light Mode is active.")
                    .font(.system(size: 13))
                    .foregroundColor(inkColor.opacity(0.7))
            }
            .padding(.top, 2)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(cardColor)
        )
        .shadow(color: Color.black.opacity(0.06), radius: 14, x: 0, y: 8)
    }

    // MARK: - Support / Remove Ads

    private var supportCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Support Us")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(inkColor)

            if viewModel.adsRemoved {
                HStack(alignment: .center, spacing: 10) {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundColor(accentGreen)
                        .font(.system(size: 20))

                    Text("Ads are turned off on this device.")
                        .font(.system(size: 14))
                        .foregroundColor(inkColor.opacity(0.8))
                }
                .padding(.top, 4)

                Text("Thank you for supporting Texas Daily!")
                    .font(.system(size: 13))
                    .foregroundColor(inkColor.opacity(0.7))
            } else {
                Button {
                    Haptics.medium()
                    isAttemptingPurchase = true
                    Task {
                        await viewModel.buyRemoveAds()
                        isAttemptingPurchase = false
                    }
                } label: {
                    HStack(spacing: 10) {
                        if isAttemptingPurchase {
                            ProgressView().tint(.white)
                        }
                        Text("Remove Ads")
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(accentGreen)
                    )
                }
                .buttonStyle(.plain)
                .padding(.top, 4)

                Text("Enjoy Texas Daily without ads, $1.99 one-time purchase.")
                    .font(.system(size: 13))
                    .foregroundColor(inkColor.opacity(0.7))
            }

            // ✅ Proper restore mechanism: no Apple ID/password fields; just StoreKit restore.
            Button {
                Haptics.light()
                isAttemptingRestore = true
                Task {
                    await viewModel.restorePurchases()
                    isAttemptingRestore = false
                }
            } label: {
                HStack(spacing: 10) {
                    if isAttemptingRestore {
                        ProgressView().tint(accentGreen)
                    } else {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(accentGreen)
                    }

                    Text("Restore Purchases")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(inkColor)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(cardColor.opacity(effectiveColorScheme == .dark ? 0.75 : 1.0))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(inkColor.opacity(effectiveColorScheme == .dark ? 0.18 : 0.10), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)

            Text("If you previously purchased Remove Ads, you can restore it here.")
                .font(.system(size: 12))
                .foregroundColor(inkColor.opacity(0.6))

            if privacyOptionsRequired {
                Button {
                    presentPrivacyChoices()
                } label: {
                    HStack(spacing: 10) {
                        if isPresentingPrivacyChoices {
                            ProgressView().tint(accentGreen)
                        } else {
                            Image(systemName: "hand.raised.fill")
                                .foregroundColor(accentGreen)
                        }

                        Text("Privacy Choices")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(inkColor)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(cardColor.opacity(effectiveColorScheme == .dark ? 0.75 : 1.0))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(inkColor.opacity(effectiveColorScheme == .dark ? 0.18 : 0.10), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
                .disabled(isPresentingPrivacyChoices)

                Text("Manage your ad privacy choices for your region.")
                    .font(.system(size: 12))
                    .foregroundColor(inkColor.opacity(0.6))
            }

            if let message = viewModel.purchaseStatusMessage {
                Text(message)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(message.contains("error") || message.contains("not found")
                                     ? .red.opacity(0.85)
                                     : inkColor.opacity(0.7))
                    .padding(.top, 2)
                    .transition(.opacity)
            }

            if let privacyStatusMessage {
                Text(privacyStatusMessage)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.red.opacity(0.85))
                    .padding(.top, 2)
                    .transition(.opacity)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(cardColor)
        )
        .shadow(color: Color.black.opacity(0.06), radius: 14, x: 0, y: 8)
        .animation(.easeInOut(duration: 0.2), value: viewModel.purchaseStatusMessage)
        .animation(.easeInOut(duration: 0.2), value: privacyStatusMessage)
    }

    // MARK: - About

    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("About Texas Daily")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(inkColor)

            Text("Texas Daily shares short facts about Texas history, culture, geography, and people. Sources are provided for learning and exploration; this app is not affiliated with the State of Texas.")
                .font(.system(size: 13))
                .foregroundColor(inkColor.opacity(0.7))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 4)
        .padding(.top, 8)
    }

    // MARK: - Helpers

    private static let timeFormatter: DateFormatter = {
        let df = DateFormatter()
        df.timeStyle = .short
        df.dateStyle = .none
        return df
    }()

    private func formattedTime(_ date: Date) -> String {
        Self.timeFormatter.string(from: date)
    }

    private func presentPrivacyChoices() {
        Haptics.light()
        isPresentingPrivacyChoices = true
        privacyStatusMessage = nil

        ConsentForm.presentPrivacyOptionsForm(from: rootViewController) { error in
            Task { @MainActor in
                isPresentingPrivacyChoices = false

                if let error {
                    privacyStatusMessage = "Privacy choices unavailable: \(error.localizedDescription)"
                }

                let canRequestAds = ConsentInformation.shared.canRequestAds
                if canRequestAds {
                    await MobileAds.shared.start()
                }
                viewModel.adsSDKReady = canRequestAds
            }
        }
    }

    private var rootViewController: UIViewController? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first(where: { $0.isKeyWindow })?
            .rootViewController
    }
}
