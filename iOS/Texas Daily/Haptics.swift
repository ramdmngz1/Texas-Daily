//
//  Haptics.swift
//  Texas Daily
//
//  Created by Ramon Dominguez on 12/3/25.
//
//
//  Haptics.swift
//  Texas Daily
//
import UIKit

enum Haptics {
    static func light() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    static func medium() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }
}
