// MARK: - AppRouter.swift
// PURPOSE: Centralized navigation coordinator with deep link support
// DEPENDENCIES: SwiftUI, CoreSpotlight

import SwiftUI
import CoreSpotlight

@Observable
final class AppRouter {
    // MARK: - Tab Enum
    enum Tab: String, CaseIterable {
        case home
        case quran
        case prayer
        case duas
        case more

        var title: String {
            switch self {
            case .home: return "Home"
            case .quran: return "Quran"
            case .prayer: return "Prayer"
            case .duas: return "Duas"
            case .more: return "More"
            }
        }

        var icon: String {
            switch self {
            case .home: return "house"
            case .quran: return "book"
            case .prayer: return "clock"
            case .duas: return "heart.text.square"
            case .more: return "ellipsis.circle"
            }
        }

        var selectedIcon: String {
            switch self {
            case .home: return "house.fill"
            case .quran: return "book.fill"
            case .prayer: return "clock.fill"
            case .duas: return "heart.text.square.fill"
            case .more: return "ellipsis.circle.fill"
            }
        }
    }

    // MARK: - Routing Action
    enum RoutingAction: Equatable {
        case switchTab(Tab)
        case navigate(Destination)
        case switchTabAndNavigate(tab: Tab, destination: Destination)
        case none
    }

    // MARK: - Navigation State
    var path: [Destination] = []
    var selectedTab: Tab = .home
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
        let maghrib: Date? = {
            guard let t = UserDefaults.standard.object(forKey: AppConstants.StorageKeys.todayMaghribTime) as? Date,
                  Calendar.current.isDate(t, inSameDayAs: Date()) else { return nil }
            return t
        }()
        return (HijriDateConverter.shared.isRamadan(maghribTime: maghrib)
            || FeatureFlags.shared.isEnabled(.ramadanMode))
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

    @discardableResult
    func navigate(to destination: Destination) -> Bool {
        // Gate AI companion behind feature flag
        if case .chat = destination, FeatureFlags.shared.isDisabled(.aiCompanion) {
            pendingChatInput = nil
            pendingChatContext = nil
            pendingChatLaunchMode = .prefillOnly
            onNavigationBlocked(.aiCompanion)
            return false
        }

        // Chat lives in the Home tab's NavigationStack — switch tab first
        if case .chat = destination {
            selectedTab = .home
        }

        path.append(destination)
        return true
    }

    func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }

    func popToRoot() {
        path.removeAll()
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

    @discardableResult
    func handleDeepLink(_ url: URL) -> Bool {
        let action = DeepLinkResolver.resolve(url, isRamadanActive: isRamadanActive())
        return apply(action)
    }

    // MARK: - Spotlight Result Handling

    @discardableResult
    func handleSpotlightResult(_ userActivity: NSUserActivity) -> Bool {
        guard userActivity.activityType == CSSearchableItemActionType,
              let identifier = userActivity.userInfo?[CSSearchableItemActivityIdentifier] as? String else {
            return false
        }

        return handleSpotlightIdentifier(identifier)
    }

    @discardableResult
    func handleSpotlightIdentifier(_ identifier: String) -> Bool {
        let action = SpotlightResolver.resolve(identifier: identifier)
        return apply(action)
    }

    // MARK: - Private

    @discardableResult
    private func apply(_ action: RoutingAction) -> Bool {
        switch action {
        case .switchTab(let tab):
            selectedTab = tab
            return true
        case .navigate(let destination):
            return navigate(to: destination)
        case .switchTabAndNavigate(let tab, let destination):
            selectedTab = tab
            return navigate(to: destination)
        case .none:
            return false
        }
    }
}
