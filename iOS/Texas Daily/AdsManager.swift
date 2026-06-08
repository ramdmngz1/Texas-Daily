import Foundation
import GoogleMobileAds
import UserMessagingPlatform
import UIKit

@MainActor
final class AdsManager {

    static let shared = AdsManager()
    private init() {}

    func requestConsentAndStartAds() async -> Bool {
        let parameters = RequestParameters()

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
            #if DEBUG
            print("⚠️ Consent info update failed: \(error.localizedDescription)")
            #endif
            return false
        }

        do {
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                ConsentForm.loadAndPresentIfRequired(from: UIApplication.shared.keyWindowRootViewController) { error in
                    if let error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume()
                    }
                }
            }
        } catch {
            #if DEBUG
            print("⚠️ Consent form failed: \(error.localizedDescription)")
            #endif
            return false
        }

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
}
