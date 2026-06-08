import SwiftUI

enum AppColors {

    static let accent = Color(red: 0.52, green: 0.65, blue: 0.23)

    static func background(for scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color(red: 0.07, green: 0.08, blue: 0.10)
            : Color(red: 0.961, green: 0.961, blue: 0.863)
    }

    static func ink(for scheme: ColorScheme) -> Color {
        scheme == .dark ? .white : Color(red: 0.30, green: 0.21, blue: 0.16)
    }

    static func card(for scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color(red: 0.16, green: 0.18, blue: 0.20)
            : Color.white.opacity(0.98)
    }

    static func chip(for scheme: ColorScheme) -> Color {
        scheme == .dark
            ? accent.opacity(0.28)
            : Color(red: 0.92, green: 0.95, blue: 0.90)
    }
}
