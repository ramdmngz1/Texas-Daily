//  RootView.swift
//  Texas Daily

import SwiftUI

struct RootView: View {
    @EnvironmentObject var viewModel: TexasAppViewModel
    @EnvironmentObject var storeKit: StoreKitManager
    @Environment(\.colorScheme) private var colorScheme

    @State private var showingSettings = false

    private var backgroundColor: Color { AppColors.background(for: colorScheme) }
    private var accentGreen: Color { AppColors.accent }

    var body: some View {
        if !viewModel.onboardingDone {
            OnboardingView { viewModel.completeOnboarding() }
                .background(backgroundColor.ignoresSafeArea())
        } else {
            mainContent
        }
    }

    @ViewBuilder
    private var mainContent: some View {
        ZStack(alignment: .topLeading) {
            // Base background (TodayFactView also paints its own, this just
            // guarantees no weird stripes during transitions)
            backgroundColor
                .ignoresSafeArea()

            VStack(spacing: 0) {
                TodayFactView()
                    .environmentObject(viewModel)

                // Show banner when ads are ready and not removed.
                if viewModel.adsSDKReady && !storeKit.adsRemoved {
                    BannerAdView()
                        .frame(height: 50)
                        .background(backgroundColor)
                }
            }

            // Settings gear (aligned with filter icon top padding from TodayFactView)
            Button {
                Haptics.light()
                showingSettings = true
            } label: {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(accentGreen)
                    .padding(4)
                    .frame(minWidth: 44, minHeight: 44)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Settings")
            .padding(.leading, 24)
            .padding(.top, 10)
        }
        // ⬇️ Full-screen cover instead of sheet – no rounded system card,
        // no extra halo around the edges, and theme changes apply immediately.
        .fullScreenCover(isPresented: $showingSettings) {
            SettingsView()
                .environmentObject(viewModel)
                .environmentObject(storeKit)
        }
    }
}
