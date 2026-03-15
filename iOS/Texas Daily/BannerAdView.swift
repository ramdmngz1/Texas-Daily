//
//  BannerAdView.swift
//  Texas Daily
//
//  Created by Ramon Dominguez on 12/5/25.
//
//
//  BannerAdView.swift
//  Texas Daily
//
import SwiftUI
import GoogleMobileAds
import UIKit

struct BannerAdView: UIViewRepresentable {

    /// Use Google's test unit on simulator/debug for reliable ad loading.
    private var adUnitID: String {
#if DEBUG
#if targetEnvironment(simulator)
        return "ca-app-pub-3940256099942544/2435281174"
#else
        return "ca-app-pub-2130345513930124/4850016311"
#endif
#else
        return "ca-app-pub-2130345513930124/4850016311"
#endif
    }

    func makeUIView(context: Context) -> BannerView {
        let banner = BannerView(adSize: AdSizeBanner)
        banner.adUnitID = adUnitID
        banner.delegate = context.coordinator
        banner.rootViewController = context.coordinator.rootViewController
        banner.load(Request())
        return banner
    }

    func updateUIView(_ uiView: BannerView, context: Context) {
        // If the root VC changes (rare), keep it updated
        uiView.rootViewController = context.coordinator.rootViewController
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    final class Coordinator: NSObject, BannerViewDelegate {
        var rootViewController: UIViewController? {
            UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .flatMap { $0.windows }
                .first(where: { $0.isKeyWindow })?
                .rootViewController
        }

        func bannerViewDidReceiveAd(_ bannerView: BannerView) {
            #if DEBUG
            print("✅ Banner ad loaded (\(bannerView.adUnitID ?? "unknown ad unit")).")
            #endif
        }

        func bannerView(_ bannerView: BannerView, didFailToReceiveAdWithError error: Error) {
            #if DEBUG
            print("⚠️ Banner failed to load: \(error.localizedDescription)")
            #endif
        }
    }
}
