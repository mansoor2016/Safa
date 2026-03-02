// MARK: - SpotlightResolver.swift
// PURPOSE: Pure Spotlight identifier → RoutingAction resolver
// DEPENDENCIES: Foundation

import Foundation

struct SpotlightResolver {

    /// Resolves a CoreSpotlight item identifier into a routing action.
    /// - Parameter identifier: The unique identifier from CoreSpotlight (e.g. "surah_2", "ayah_2_255")
    /// - Returns: The routing action to apply
    static func resolve(identifier: String) -> AppRouter.RoutingAction {
        let components = identifier.split(separator: "_")
        guard components.count >= 2 else { return .none }

        let type = String(components[0])

        switch type {
        case "surah":
            guard let number = Int(components[1]) else { return .none }
            return .navigate(.surah(number: number))

        case "ayah":
            guard components.count >= 3,
                  let surah = Int(components[1]),
                  let ayah = Int(components[2]) else { return .none }
            return .navigate(.ayah(surah: surah, ayah: ayah))

        case "hadith":
            let collection = String(components[1])
            let hadithId = components.count > 2 ? String(components[2]) : nil
            return .navigate(.hadith(collection: collection, hadithId: hadithId))

        case "dua":
            return .navigate(.dhikr)

        case "name":
            return .navigate(.dhikr)

        case "prayer":
            return .switchTab(.prayer)

        case "feature":
            let featureId = components.dropFirst().joined(separator: "_")
            switch featureId {
            case "prayer_times":
                return .switchTab(.prayer)
            case "qibla":
                return .navigate(.qibla)
            case "quran":
                return .switchTab(.quran)
            case "hadith":
                return .navigate(.hadith(collection: nil, hadithId: nil))
            case "dhikr":
                return .navigate(.dhikr)
            case "calendar":
                return .navigate(.calendar)
            case "dua":
                return .switchTab(.duas)
            default:
                return .none
            }

        default:
            return .none
        }
    }
}
