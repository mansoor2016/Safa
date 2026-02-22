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
    var pendingQuranTarget: QuranNavigationTarget?
    var pendingNotificationAction: NotificationAction?
    var pendingChatInput: String?
    var pendingChatContext: ChatContext?
    var pendingChatLaunchMode: ChatLaunchMode = .prefillOnly

    // MARK: - Chat Launch Mode
    enum ChatLaunchMode {
        case prefillOnly    // Contextual entries: fill input, user reviews before sending
        case autoSend       // Siri intent: send immediately
    }

    // MARK: - Injectable State
    var isRamadanActive: () -> Bool = {
        (HijriDateConverter.shared.isRamadan() || FeatureFlags.shared.isEnabled(.ramadanMode))
            && !FeatureFlags.shared.isEnabled(.forcePrayerPage)
    }
    var onNavigationBlocked: ((Feature) -> Void) = { feature in
        ToastService.shared.showComingSoon(feature.displayName)
    }

    // MARK: - Shared Instance (for notification handler access before SwiftUI mounts)
    static let shared = AppRouter()

    // MARK: - Notification Action
    enum NotificationAction: Equatable {
        case openQibla
        case logPrayer(prayerType: PrayerType)
    }

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

        // Progress
        case progress

        // Settings
        case settings
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

    /// Handles "Ask Safa" intent — sets pending chat state and navigates.
    /// Feature flag check gates the entire flow.
    func handleAskSafa(question: String?) {
        guard !FeatureFlags.shared.isDisabled(.aiCompanion) else { return }
        if let question {
            pendingChatLaunchMode = .autoSend
            pendingChatInput = question
        }
        navigate(to: .chat)
    }

    func navigate(to destination: Destination) {
        // Gate AI companion behind feature flag
        if case .chat = destination, FeatureFlags.shared.isDisabled(.aiCompanion) {
            pendingChatInput = nil
            pendingChatContext = nil
            pendingChatLaunchMode = .prefillOnly
            onNavigationBlocked(.aiCompanion)
            return
        }

        // Chat lives in the Home tab's NavigationStack — switch tab first
        if case .chat = destination {
            selectedTab = "home"
        }

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
            selectedTab = "quran"
            // TODO: deep link to specific surah/ayah within Quran tab
            return true

        case "prayer":
            selectedTab = "prayer"
            return true

        case "qibla":
            // Qibla opens as a sheet, not a tab — navigate is correct here
            navigate(to: .qibla)
            return true

        case "learn":
            selectedTab = "learn"
            return true

        case "chat":
            // navigate(to:) checks feature flag and shows toast if disabled
            navigate(to: .chat)
            return !FeatureFlags.shared.isDisabled(.aiCompanion)

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
            if isRamadanActive() {
                selectedTab = "prayer"
            } else {
                selectedTab = "home"
                navigate(to: .ramadan)
            }
            return true

        case "eid":
            selectedTab = "home"
            return true

        case "settings":
            navigate(to: .settings)
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

        case "prayer":
            selectedTab = "prayer"
            return true

        case "feature":
            let featureId = components.dropFirst().joined(separator: "_")
            switch featureId {
            case "prayer_times":
                selectedTab = "prayer"
            case "qibla":
                navigate(to: .qibla)
            case "quran":
                selectedTab = "quran"
            case "hadith":
                navigate(to: .hadith(collection: nil, hadithId: nil))
            case "dhikr":
                navigate(to: .dhikr)
            case "calendar":
                navigate(to: .calendar)
            case "dua":
                selectedTab = "duas"
            default:
                return false
            }
            return true

        default:
            return false
        }
    }
}
