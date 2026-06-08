import SwiftUI

// MARK: - Card Modifier

struct CardStyle: ViewModifier {
    var fill: Color
    var cornerRadius: CGFloat
    var shadowRadius: CGFloat
    var shadowY: CGFloat

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(fill)
            )
            .shadow(color: Color.black.opacity(0.06), radius: shadowRadius, x: 0, y: shadowY)
    }
}

extension View {
    func appCard(
        fill: Color,
        cornerRadius: CGFloat = 22,
        shadowRadius: CGFloat = 14,
        shadowY: CGFloat = 8
    ) -> some View {
        modifier(CardStyle(fill: fill, cornerRadius: cornerRadius, shadowRadius: shadowRadius, shadowY: shadowY))
    }
}

// MARK: - Accent Button Style

struct AccentButtonStyle: ButtonStyle {
    var color: Color = AppColors.accent

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 17, weight: .semibold))
            .foregroundColor(.white)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(color)
                    .shadow(color: Color.black.opacity(0.18), radius: 14, x: 0, y: 8)
            )
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

// MARK: - Status Banner

struct StatusBanner: View {
    let message: String?
    var isError: Bool = false
    var autoDismissAfter: TimeInterval = 4
    var onDismiss: (() -> Void)? = nil

    @State private var visible = false

    var body: some View {
        if let message, !message.isEmpty {
            Text(message)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(isError ? .red.opacity(0.85) : Color.primary.opacity(0.7))
                .padding(.top, 2)
                .transition(.opacity)
                .task(id: message) {
                    try? await Task.sleep(nanoseconds: UInt64(autoDismissAfter * 1_000_000_000))
                    onDismiss?()
                }
        }
    }
}

// MARK: - Empty State

struct EmptyStateView: View {
    var icon: String = "tray"
    var title: String
    var subtitle: String = ""

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 40))
                .foregroundColor(AppColors.accent.opacity(0.6))

            Text(title)
                .font(.system(size: 18, weight: .semibold, design: .serif))
                .foregroundColor(AppColors.ink(for: colorScheme))
                .multilineTextAlignment(.center)

            if !subtitle.isEmpty {
                Text(subtitle)
                    .font(.system(size: 14))
                    .foregroundColor(AppColors.ink(for: colorScheme).opacity(0.6))
                    .multilineTextAlignment(.center)
            }
        }
        .padding(32)
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }
}
