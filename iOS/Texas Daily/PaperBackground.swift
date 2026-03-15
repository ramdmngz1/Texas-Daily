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
            // Base background — matches app icon tan #F5F5DC
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.961, green: 0.961, blue: 0.863),
                    Color(red: 0.925, green: 0.925, blue: 0.820)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Subtle paper texture using overlays
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(red: 0.961, green: 0.961, blue: 0.863),
                            Color(red: 0.925, green: 0.925, blue: 0.820)
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
