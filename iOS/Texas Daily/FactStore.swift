//
//  FactStore.swift
//  Texas Daily
//
//  Created by Ramon Dominguez on 12/3/25.
//
// FactStore.swift
import Foundation

final class FactStore {
    static let shared = FactStore()

    let facts: [TexasFact]
    private let categoryIndex: [String: [TexasFact]]

    private struct Wrapper: Codable {
        let facts: [TexasFact]
    }

    private init(fileName: String = "texas_facts") {
        guard let url = Bundle.main.url(forResource: fileName, withExtension: "json") else {
            self.facts = []
            self.categoryIndex = [:]
            return
        }

        do {
            let data = try Data(contentsOf: url)
            let decoded = try JSONDecoder().decode(Wrapper.self, from: data)
            self.facts = decoded.facts
            #if DEBUG
            print("✅ Loaded \(decoded.facts.count) facts")
            #endif
        } catch {
            self.facts = []
            #if DEBUG
            print("⚠️ Failed to load texas_facts.json: \(error)")
            #endif
        }
        self.categoryIndex = Dictionary(grouping: facts, by: { $0.category })
    }

    func randomFact(from categories: Set<String> = [], excluding excludedID: Int? = nil) -> TexasFact? {
        let pool: [TexasFact]
        if categories.isEmpty {
            pool = facts
        } else {
            pool = categories.flatMap { categoryIndex[$0] ?? [] }
        }
        guard !pool.isEmpty else { return nil }

        if let id = excludedID {
            let filtered = pool.filter { $0.id != id }
            if !filtered.isEmpty { return filtered.randomElement() }
        }

        return pool.randomElement()
    }
}
