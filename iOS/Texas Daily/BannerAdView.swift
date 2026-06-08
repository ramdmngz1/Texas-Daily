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

    private var adUnitID: String {
#if DEBUG
        return "ca-app-pub-3940256099942544/2435281174"
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
            UIApplication.shared.keyWindowRootViewController
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
