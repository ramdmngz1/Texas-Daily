//
//  PaperBackground.swift
//  Texas Daily
//
//  Created by Ramon Dominguez on 12/3/25.
//
import SwiftUI

struct PaperBackground: View {
    var body: some View {
        ZStack {
            // Base background
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(.systemBackground),
                    Color(.secondarySystemBackground)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Subtle paper texture using overlays
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.white,
                            Color(.systemGray6)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 8)
                .padding(.horizontal, 16)
                .padding(.vertical, 24)
        }
        .ignoresSafeArea()
    }
}

#Preview {
    PaperBackground()
}
