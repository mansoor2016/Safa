// MARK: - DuaDataLoader.swift
// PURPOSE: Loads and decodes duas.json from the app bundle
// DATA SOURCE: Bundled JSON

import Foundation

struct DuaDataLoader {

    // MARK: - Decoded Container

    struct DuaBundle {
        let categories: [DuaCategory]
        let duas: [Dua]
    }

    // MARK: - Load

    static func load(from bundle: Bundle = .main) throws -> DuaBundle {
        guard let url = bundle.url(forResource: "duas", withExtension: "json") else {
            throw NSError(domain: "DuaDataLoader", code: 1, userInfo: [
                NSLocalizedDescriptionKey: "duas.json not found in bundle"
            ])
        }

        let data = try Data(contentsOf: url)
        let raw = try JSONDecoder().decode(RawDuaBundle.self, from: data)

        // Compute duaCount per category from loaded duas
        let duaCounts = Dictionary(grouping: raw.duas, by: \.categoryId)
            .mapValues(\.count)

        let categories = raw.categories.map { category in
            DuaCategory(
                id: category.id,
                nameEnglish: category.nameEnglish,
                nameArabic: category.nameArabic,
                iconName: category.iconName,
                duaCount: duaCounts[category.id] ?? 0
            )
        }

        return DuaBundle(categories: categories, duas: raw.duas)
    }

    // MARK: - Raw Decodable Container

    private struct RawDuaBundle: Decodable {
        let categories: [DuaCategory]
        let duas: [Dua]
    }
}
