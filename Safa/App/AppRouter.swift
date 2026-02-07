// MARK: - AppRouter.swift
// PURPOSE: Centralized navigation coordinator with deep link support
// DEPENDENCIES: SwiftUI, CoreSpotlight

import SwiftUI
import CoreSpotlight

@Observable
final class AppRouter {
    // MARK: - Navigation State
    var path = NavigationPath()
    var selectedTab: String = "home"
    var activeSheet: Sheet?
    var activeAlert: AlertType?

    // MARK: - App-Wide State
    var accentColor: Color = AccentColorOption.teal.color

    // MARK: - Destination Enum
    enum Destination: Hashable {
        // Quran
        case quran
        case surah(number: Int)
        case ayah(surah: Int, ayah: Int)

        // Prayer
        case prayer
        case qibla
        case prayerLog

        // Learn
        case learn
        case lesson(trackId: String, lessonId: String)

        // Chat
        case chat

        // Hadith
        case hadith(collection: String?, hadithId: String?)

        // Dhikr
        case dhikr

        // Calendar
        case calendar

        // Ramadan
        case ramadan

        // Wind Down
        case windDown

        // Settings
        case settings

        // Family
        case family
    }

    // MARK: - Sheet Enum
    enum Sheet: Identifiable {
        case share(content: ShareContent)
        case invite
        case downloads

        var id: String {
            switch self {
            case .share: return "share"
            case .invite: return "invite"
            case .downloads: return "downloads"
            }
        }
    }

    // MARK: - Alert Enum
    enum AlertType: Identifiable {
        case error(message: String)
        case confirmation(title: String, message: String, action: () -> Void)

        var id: String {
            switch self {
            case .error: return "error"
            case .confirmation: return "confirmation"
            }
        }
    }

    // MARK: - Share Content
    struct ShareContent: Hashable {
        let text: String
        let url: URL?
    }

    // MARK: - Navigation Methods

    func navigate(to destination: Destination) {
        path.append(destination)
    }

    func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }

    func popToRoot() {
        path.removeLast(path.count)
    }

    func presentSheet(_ sheet: Sheet) {
        activeSheet = sheet
    }

    func dismissSheet() {
        activeSheet = nil
    }

    func showAlert(_ alert: AlertType) {
        activeAlert = alert
    }

    func dismissAlert() {
        activeAlert = nil
    }

    // MARK: - Deep Link Handling

    /// Handles incoming deep links in the format: safa://destination/param1/param2
    /// - Parameter url: The deep link URL to handle
    /// - Returns: True if the deep link was handled successfully
    @discardableResult
    func handleDeepLink(_ url: URL) -> Bool {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              components.scheme == "safa" else {
            return false
        }

        let pathComponents = url.pathComponents.filter { $0 != "/" }

        switch components.host {
        case "quran":
            if pathComponents.count >= 2,
               let surah = Int(pathComponents[0]),
               let ayah = Int(pathComponents[1]) {
                navigate(to: .ayah(surah: surah, ayah: ayah))
            } else if pathComponents.count >= 1,
                      let surah = Int(pathComponents[0]) {
                navigate(to: .surah(number: surah))
            } else {
                navigate(to: .quran)
            }
            return true

        case "prayer":
            navigate(to: .prayer)
            return true

        case "qibla":
            navigate(to: .qibla)
            return true

        case "learn":
            if pathComponents.count >= 2 {
                navigate(to: .lesson(trackId: pathComponents[0], lessonId: pathComponents[1]))
            } else {
                navigate(to: .learn)
            }
            return true

        case "chat":
            navigate(to: .chat)
            return true

        case "hadith":
            let collection = pathComponents.first
            let hadithId = pathComponents.count > 1 ? pathComponents[1] : nil
            navigate(to: .hadith(collection: collection, hadithId: hadithId))
            return true

        case "dhikr":
            navigate(to: .dhikr)
            return true

        case "calendar":
            navigate(to: .calendar)
            return true

        case "ramadan":
            navigate(to: .ramadan)
            return true

        case "settings":
            navigate(to: .settings)
            return true

        case "family":
            navigate(to: .family)
            return true

        default:
            return false
        }
    }

    // MARK: - Spotlight Result Handling

    /// Handles Spotlight search result selection
    /// - Parameter userActivity: The user activity from Spotlight
    /// - Returns: True if the result was handled successfully
    @discardableResult
    func handleSpotlightResult(_ userActivity: NSUserActivity) -> Bool {
        guard userActivity.activityType == CSSearchableItemActionType,
              let identifier = userActivity.userInfo?[CSSearchableItemActivityIdentifier] as? String else {
            return false
        }

        return handleSpotlightIdentifier(identifier)
    }

    /// Handles a Spotlight item identifier
    /// - Parameter identifier: The unique identifier from CoreSpotlight
    /// - Returns: True if the identifier was handled successfully
    @discardableResult
    func handleSpotlightIdentifier(_ identifier: String) -> Bool {
        let components = identifier.split(separator: "_")
        guard components.count >= 2 else { return false }

        let type = String(components[0])

        switch type {
        case "surah":
            guard let number = Int(components[1]) else { return false }
            navigate(to: .surah(number: number))
            return true

        case "ayah":
            guard components.count >= 3,
                  let surah = Int(components[1]),
                  let ayah = Int(components[2]) else { return false }
            navigate(to: .ayah(surah: surah, ayah: ayah))
            return true

        case "hadith":
            let collection = String(components[1])
            let hadithId = components.count > 2 ? String(components[2]) : nil
            navigate(to: .hadith(collection: collection, hadithId: hadithId))
            return true

        case "dua":
            // Navigate to dhikr view for duas
            navigate(to: .dhikr)
            return true

        case "name":
            // Navigate to a names of Allah destination (could be added later)
            // For now, navigate to dhikr which contains related content
            navigate(to: .dhikr)
            return true

        default:
            return false
        }
    }
}
