//
//  ActivityView.swift
//  Texas Daily
//
//  Thin UIViewControllerRepresentable wrapper around UIActivityViewController
//  so SwiftUI views can present the native iOS share sheet with multiple items.
//

import SwiftUI

struct ActivityView: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
