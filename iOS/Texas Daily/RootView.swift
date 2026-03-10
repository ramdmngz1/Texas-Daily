//  RootView.swift
//  Texas Daily

import SwiftUI

struct RootView: View {
    @EnvironmentObject var viewModel: TexasAppViewModel
    @Environment(\.colorScheme) private var colorScheme

    @State private var showingSettings = false

    // Match TodayFactView background so everything feels cohesive
    private var backgroundColor: Color {
        if colorScheme == .dark {
            return Color(red: 0.07, green: 0.08, blue: 0.10)   // deep charcoal
        } else {
            return Color(red: 0.97, green: 0.96, blue: 0.90)   // limestone
        }
    }

    private var accentGreen: Color {
        Color(red: 0.52, green: 0.65, blue: 0.23)
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            // Base background (TodayFactView also paints its own, this just
            // guarantees no weird stripes during transitions)
            backgroundColor
                .ignoresSafeArea()

            VStack(spacing: 0) {
                TodayFactView()
                    .environmentObject(viewModel)

                // Only show banner once StoreKit is verified, ads SDK is initialized, and ads are not removed
                if !viewModel.isVerifyingEntitlements && viewModel.adsSDKReady && !viewModel.adsRemoved {
                    BannerAdView()
                        .frame(height: 50)
                        .background(
                            Color.black.opacity(colorScheme == .dark ? 0.35 : 0.05)
                        )
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
        }
    }
}
