//
//  TexasDailyApp.swift
//  Texas Daily
//
//  Created by Ramon Dominguez on 12/3/25.
//
import SwiftUI
import GoogleMobileAds
import UserMessagingPlatform
import UIKit

@main
struct TexasDailyApp: App {
    @StateObject private var viewModel = TexasAppViewModel()
    @AppStorage("themeMode") private var themeModeRaw: String = ThemeMode.light.rawValue

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(viewModel)
                .preferredColorScheme(
                    (ThemeMode(rawValue: themeModeRaw) ?? .light) == .dark ? .dark : .light
                )
                .task {
                    viewModel.adsSDKReady = await requestConsentAndStartAds()
                    viewModel.startStoreKitListener()
                    await viewModel.scheduleDailyReminderIfEnabled()
                }
        }
    }

    // MARK: - Consent + Ads Initialization

    /// Gathers GDPR/CCPA consent via Google UMP, then starts the Mobile Ads SDK
    /// only when consent permits it. Safe to call on every launch.
    /// - Returns: True when ad requests are allowed for this session.
    private func requestConsentAndStartAds() async -> Bool {
        let parameters = RequestParameters()

        // Step 1: Fetch updated consent status from Google's servers.
        do {
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                ConsentInformation.shared.requestConsentInfoUpdate(with: parameters) { error in
                    if let error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume()
                    }
                }
            }
        } catch {
            // Consent info update failed; fall through and check canRequestAds below.
        }

        // Step 2: Present the consent form if one is required.
        // `from:` accepts nil; this avoids missing the flow when key window is not ready yet.
        do {
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                ConsentForm.loadAndPresentIfRequired(from: rootViewController) { error in
                    if let error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume()
                    }
                }
            }
        } catch {
            // Form failed to load or present; fall through.
        }

        // Step 3: Start ads only when consent has been obtained (or is not required).
        let canRequestAds = ConsentInformation.shared.canRequestAds
        if canRequestAds {
            await MobileAds.shared.start()
            #if DEBUG
            print("✅ AdMob started (consent allows ad requests).")
            #endif
        } else {
            #if DEBUG
            print("ℹ️ AdMob not started yet (consent currently does not allow ad requests).")
            #endif
        }
        return canRequestAds
    }

    private var rootViewController: UIViewController? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first(where: { $0.isKeyWindow })?
            .rootViewController
    }
}
