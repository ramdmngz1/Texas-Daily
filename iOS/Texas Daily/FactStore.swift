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

    // Matches { "facts": [ ... ] }
    private struct Wrapper: Codable {
        let facts: [TexasFact]
    }

    private init(fileName: String = "texas_facts") {
        guard let url = Bundle.main.url(forResource: fileName, withExtension: "json") else {
            self.facts = []
            return
        }

        do {
            let data = try Data(contentsOf: url)
            let decoded = try JSONDecoder().decode(Wrapper.self, from: data)
            self.facts = decoded.facts
            print("✅ Loaded \(decoded.facts.count) facts")
        } catch {
            self.facts = []
            print("⚠️ Failed to load texas_facts.json: \(error)")
        }
    }

    func randomFact(from categories: Set<String> = [], excluding excludedID: Int? = nil) -> TexasFact? {
        var pool = categories.isEmpty ? facts : facts.filter { categories.contains($0.category) }
        if let id = excludedID, pool.count > 1 {
            pool = pool.filter { $0.id != id }
        }
        return pool.randomElement()
    }
}
