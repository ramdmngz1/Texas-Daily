//
//  FactShareCard.swift
//  Texas Daily
//
//  Rendered to UIImage via ImageRenderer and shared via ShareLink.
//

import SwiftUI

// MARK: - Card view

struct FactShareCard: View {
    let fact: TexasFact

    private var accentGreen: Color { Color(red: 0.52, green: 0.65, blue: 0.23) }
    private var inkColor: Color    { Color(red: 0.30, green: 0.21, blue: 0.16) }
    private var bgColor: Color     { Color(red: 0.97, green: 0.96, blue: 0.90) }
    private var chipBg: Color      { Color(red: 0.92, green: 0.95, blue: 0.90) }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            // Branding header
            HStack {
                Text("TEXAS DAILY")
                    .font(.system(size: 12, weight: .bold))
                    .tracking(2)
                    .foregroundColor(accentGreen)
                Spacer()
                Image(systemName: "star.fill")
                    .font(.system(size: 13))
                    .foregroundColor(accentGreen)
            }
            .padding(.bottom, 20)

            // Category chip
            if !fact.category.isEmpty {
                Text(fact.category)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(accentGreen)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 5)
                    .background(Capsule().fill(chipBg))
                    .padding(.bottom, 16)
            }

            // Fact
            Text(fact.fact)
                .font(.system(size: 24, weight: .bold, design: .serif))
                .foregroundColor(inkColor)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.bottom, 24)

            // Source
            if !fact.source.isEmpty {
                Divider().opacity(0.25).padding(.bottom, 14)
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("Source:")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(inkColor)
                    Text(fact.source)
                        .font(.system(size: 13))
                        .foregroundColor(inkColor.opacity(0.6))
                }
            }
        }
        .padding(28)
        .frame(width: 390)
        .background(bgColor)
    }
}

