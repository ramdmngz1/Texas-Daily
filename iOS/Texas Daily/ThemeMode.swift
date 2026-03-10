//
//  ThemeMode.swift
//  Texas Daily
//
//  Created by Ramon Dominguez on 12/3/25.
//
//
//  ThemeMode.swift
//  Texas Daily
//
import Foundation

enum ThemeMode: String, CaseIterable, Identifiable {
    case light
    case dark

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .light: return "Light"
        case .dark:  return "Dark"
        }
    }
}
