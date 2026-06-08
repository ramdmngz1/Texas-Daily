//  OnboardingView.swift
//  Texas Daily

import SwiftUI

// Custom 5-pointed star with sharp points (innerRatio controls pointedness — lower = sharper)
private struct PointedStar: Shape {
    var innerRatio: CGFloat = 0.38

    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let outerRadius = min(rect.width, rect.height) / 2
        let innerRadius = outerRadius * innerRatio
        var path = Path()
        for i in 0 ..< 10 {
            let angle = CGFloat(i) * .pi / 5 - .pi / 2
            let radius = i.isMultiple(of: 2) ? outerRadius : innerRadius
            let point = CGPoint(x: center.x + radius * cos(angle),
                                y: center.y + radius * sin(angle))
            if i == 0 { path.move(to: point) } else { path.addLine(to: point) }
        }
        path.closeSubpath()
        return path
    }
}

private struct OnboardingPage {
    let systemImage: String
    let title: String
    let description: String
}

private let pages: [OnboardingPage] = [
    OnboardingPage(
        systemImage: "star.fill",
        title: "Welcome to Texas Daily",
        description: "Discover something new about the Lone Star State every single day — from its rich history to its wide-open landscapes."
    ),
    OnboardingPage(
        systemImage: "book.fill",
        title: "700+ Curated Facts",
        description: "Explore verified facts across History, Geography, Culture, Sports, Science, and more — all about Texas."
    ),
    OnboardingPage(
        systemImage: "magnifyingglass",
        title: "Browse by Category",
        description: "Filter facts by topic so you always see what interests you most. Tap the filter icon anytime to change it."
    ),
    OnboardingPage(
        systemImage: "bell.fill",
        title: "Never Miss a Day",
        description: "Turn on daily reminders in Settings to get a nudge at the time that works best for you."
    )
]

struct OnboardingView: View {
    var onFinished: () -> Void

    @Environment(\.colorScheme) private var colorScheme
    @State private var currentPage = 0

    private var accentGreen: Color { AppColors.accent }
    private var inkColor: Color { AppColors.ink(for: colorScheme) }

    var body: some View {
        VStack(spacing: 0) {
            // Skip button
            HStack {
                Spacer()
                if currentPage < pages.count - 1 {
                    Button("Skip") { onFinished() }
                        .foregroundColor(inkColor.opacity(0.7))
                        .padding(.horizontal, 24)
                        .padding(.top, 16)
                }
            }
            .frame(height: 52)

            // Pager
            TabView(selection: $currentPage) {
                ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                    PageView(page: page, accentGreen: accentGreen, isFirst: index == 0)
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut, value: currentPage)

            // Dot indicators
            HStack(spacing: 8) {
                ForEach(0 ..< pages.count, id: \.self) { index in
                    Capsule()
                        .fill(index == currentPage ? accentGreen : Color.secondary.opacity(0.3))
                        .frame(width: index == currentPage ? 24 : 8, height: 8)
                        .animation(.easeInOut(duration: 0.25), value: currentPage)
                }
            }
            .padding(.bottom, 24)

            // Action button
            Button {
                if currentPage < pages.count - 1 {
                    withAnimation { currentPage += 1 }
                } else {
                    onFinished()
                }
            } label: {
                Text(currentPage < pages.count - 1 ? "Next" : "Get Started")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(accentGreen)
                    .cornerRadius(14)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
    }
}

private struct PageView: View {
    @Environment(\.colorScheme) private var colorScheme
    let page: OnboardingPage
    let accentGreen: Color
    var isFirst: Bool = false
    private var inkColor: Color { AppColors.ink(for: colorScheme) }

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            ZStack {
                Circle()
                    .fill(accentGreen.opacity(0.12))
                    .frame(width: 128, height: 128)
                if isFirst {
                    PointedStar(innerRatio: 0.40)
                        .fill(accentGreen)
                        .frame(width: 68, height: 68)
                } else {
                    Image(systemName: page.systemImage)
                        .font(.system(size: 52, weight: .semibold))
                        .foregroundColor(accentGreen)
                }
            }

            Spacer().frame(height: 40)

            Text(page.title)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(inkColor)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Spacer().frame(height: 16)

            Text(page.description)
                .font(.body)
                .foregroundColor(inkColor.opacity(0.72))
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.horizontal, 32)

            Spacer()
        }
    }
}
