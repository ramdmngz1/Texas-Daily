//
//  TexasFacts.swift
//  Texas Daily
//
//  Created by Ramon Dominguez on 12/3/25.
//
// TexasFact.swift
// TexasFact.swift
// TexasFact.swift
import Foundation

struct TexasFact: Identifiable, Codable {
    let id: Int
    let fact: String
    let category: String
    let date: String?
    let background: String
    let source: String
}
