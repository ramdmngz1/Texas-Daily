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

    /// ✅ Replace with your real AdMob Banner Ad Unit ID (NOT the test ID)
    private let adUnitID = "ca-app-pub-2130345513930124/4850016311"

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

        func bannerViewDidReceiveAd(_ bannerView: BannerView) { }

        func bannerView(_ bannerView: BannerView, didFailToReceiveAdWithError error: Error) { }
    }
}
