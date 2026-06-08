import SwiftUI

@main
struct TexasDailyApp: App {
    @StateObject private var viewModel = TexasAppViewModel()
    @StateObject private var storeKit = StoreKitManager()
    @AppStorage("themeMode") private var themeModeRaw: String = ThemeMode.light.rawValue

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(viewModel)
                .environmentObject(storeKit)
                .preferredColorScheme(
                    (ThemeMode(rawValue: themeModeRaw) ?? .light) == .dark ? .dark : .light
                )
                .task {
                    storeKit.startListener()
                    await storeKit.refreshEntitlements()
                    await viewModel.scheduleDailyReminderIfEnabled()
                    viewModel.adsSDKReady = await AdsManager.shared.requestConsentAndStartAds()
                }
        }
    }
}
