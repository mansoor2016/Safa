// MARK: - DeepLinkResolver.swift
// PURPOSE: Pure URL → RoutingAction resolver for safa:// deep links
// DEPENDENCIES: Foundation

import Foundation

struct DeepLinkResolver {

    /// Resolves a deep link URL into a routing action.
    /// - Parameters:
    ///   - url: The deep link URL (must use `safa://` scheme)
    ///   - isRamadanActive: Whether Ramadan mode is currently active
    /// - Returns: The routing action to apply
    static func resolve(_ url: URL, isRamadanActive: Bool) -> AppRouter.RoutingAction {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              components.scheme == "safa" else {
            return .none
        }

        let pathComponents = url.pathComponents.filter { $0 != "/" }

        switch components.host {
        case "quran":
            return .switchTab(.quran)

        case "prayer":
            return .switchTab(.prayer)

        case "qibla":
            return .navigate(.qibla)

        case "learn":
            return .switchTabAndNavigate(tab: .home, destination: .learn)

        case "chat":
            return .navigate(.chat)

        case "hadith":
            let collection = pathComponents.first
            let hadithId = pathComponents.count > 1 ? pathComponents[1] : nil
            return .navigate(.hadith(collection: collection, hadithId: hadithId))

        case "dhikr":
            return .navigate(.dhikr)

        case "calendar":
            return .navigate(.calendar)

        case "ramadan":
            if isRamadanActive {
                return .switchTab(.prayer)
            } else {
                return .switchTabAndNavigate(tab: .home, destination: .ramadan)
            }

        case "eid":
            return .switchTab(.home)

        case "settings":
            return .navigate(.settings)

        default:
            return .none
        }
    }
}
