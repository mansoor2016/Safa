// MARK: - AppRouterTests.swift
// PURPOSE: Unit tests for AppRouter navigation, sheets, alerts, and routing integration
// DEPENDENCIES: XCTest, SwiftUI

import XCTest
import SwiftUI
@testable import Safa

final class AppRouterTests: XCTestCase {

    var sut: AppRouter!

    override func setUp() {
        super.setUp()
        FeatureFlags.shared.removeOverride(.aiCompanion)
        sut = AppRouter()
        sut.onNavigationBlocked = { _ in }
    }

    override func tearDown() {
        FeatureFlags.shared.removeOverride(.aiCompanion)
        sut = nil
        super.tearDown()
    }

    // MARK: - Navigation Tests

    func testNavigateAddsToPath() {
        XCTAssertTrue(sut.path.isEmpty)
        sut.navigate(to: .prayer)
        XCTAssertEqual(sut.path.count, 1)
    }

    func testPopRemovesFromPath() {
        sut.navigate(to: .prayer)
        sut.navigate(to: .qibla)
        XCTAssertEqual(sut.path.count, 2)

        sut.pop()
        XCTAssertEqual(sut.path.count, 1)
    }

    func testPopOnEmptyPathDoesNothing() {
        XCTAssertTrue(sut.path.isEmpty)
        sut.pop()
        XCTAssertTrue(sut.path.isEmpty)
    }

    func testPopToRootClearsPath() {
        sut.navigate(to: .prayer)
        sut.navigate(to: .qibla)
        sut.navigate(to: .settings)
        XCTAssertEqual(sut.path.count, 3)

        sut.popToRoot()
        XCTAssertTrue(sut.path.isEmpty)
    }

    // MARK: - Sheet Tests

    func testPresentSheet() {
        XCTAssertNil(sut.activeSheet)
        sut.presentSheet(.invite)
        XCTAssertNotNil(sut.activeSheet)
    }

    func testDismissSheet() {
        sut.presentSheet(.invite)
        XCTAssertNotNil(sut.activeSheet)

        sut.dismissSheet()
        XCTAssertNil(sut.activeSheet)
    }

    // MARK: - Alert Tests

    func testShowAlert() {
        XCTAssertNil(sut.activeAlert)
        sut.showAlert(.error(message: "Test error"))
        XCTAssertNotNil(sut.activeAlert)
    }

    func testDismissAlert() {
        sut.showAlert(.error(message: "Test error"))
        XCTAssertNotNil(sut.activeAlert)

        sut.dismissAlert()
        XCTAssertNil(sut.activeAlert)
    }

    // MARK: - Deep Link Integration Tests

    func testDeepLinkInvalidSchemeReturnsFalse() {
        let url = URL(string: "https://example.com/prayer")!
        XCTAssertFalse(sut.handleDeepLink(url))
    }

    func testDeepLinkPrayer() {
        let url = URL(string: "safa://prayer")!
        XCTAssertTrue(sut.handleDeepLink(url))
        XCTAssertEqual(sut.selectedTab, .prayer)
    }

    func testDeepLinkQibla() {
        let url = URL(string: "safa://qibla")!
        XCTAssertTrue(sut.handleDeepLink(url))
        XCTAssertEqual(sut.path.count, 1)
    }

    func testDeepLinkQuran() {
        let url = URL(string: "safa://quran")!
        XCTAssertTrue(sut.handleDeepLink(url))
        XCTAssertEqual(sut.selectedTab, .quran)
    }

    func testDeepLinkQuranWithSurah() {
        let url = URL(string: "safa://quran/2")!
        XCTAssertTrue(sut.handleDeepLink(url))
        XCTAssertEqual(sut.selectedTab, .quran)
    }

    func testDeepLinkQuranWithSurahAndAyah() {
        let url = URL(string: "safa://quran/2/255")!
        XCTAssertTrue(sut.handleDeepLink(url))
        XCTAssertEqual(sut.selectedTab, .quran)
    }

    func testDeepLinkLearn_switchesToHomeAndPushesLearn() {
        let url = URL(string: "safa://learn")!
        XCTAssertTrue(sut.handleDeepLink(url))
        XCTAssertEqual(sut.selectedTab, .home)
        XCTAssertEqual(sut.path.count, 1, "Learn should push onto Home's NavigationStack")
    }

    func testDeepLinkLearn_fromNonHomeTab_switchesToHome() {
        sut.selectedTab = .prayer
        let url = URL(string: "safa://learn")!
        XCTAssertTrue(sut.handleDeepLink(url))
        XCTAssertEqual(sut.selectedTab, .home, "Must switch to home since path is Home's NavigationStack")
        XCTAssertEqual(sut.path.count, 1)
    }

    func testDeepLinkChat_whenAIDisabled_returnsFalse() {
        FeatureFlags.shared.setOverride(.aiCompanion, enabled: false)
        let url = URL(string: "safa://chat")!
        XCTAssertFalse(sut.handleDeepLink(url))
        XCTAssertTrue(sut.path.isEmpty, "Path should remain empty when AI is disabled")
    }

    func testDeepLinkChat_whenAIEnabled_returnsTrue() {
        FeatureFlags.shared.setOverride(.aiCompanion, enabled: true)
        defer { FeatureFlags.shared.removeOverride(.aiCompanion) }

        let url = URL(string: "safa://chat")!
        XCTAssertTrue(sut.handleDeepLink(url))
        XCTAssertEqual(sut.path.count, 1)
    }

    func testDeepLinkHadith() {
        let url = URL(string: "safa://hadith")!
        XCTAssertTrue(sut.handleDeepLink(url))
        XCTAssertEqual(sut.path.count, 1)
    }

    func testDeepLinkHadithWithCollection() {
        let url = URL(string: "safa://hadith/bukhari")!
        XCTAssertTrue(sut.handleDeepLink(url))
        XCTAssertEqual(sut.path.count, 1)
    }

    func testDeepLinkDhikr() {
        let url = URL(string: "safa://dhikr")!
        XCTAssertTrue(sut.handleDeepLink(url))
        XCTAssertEqual(sut.path.count, 1)
    }

    func testDeepLinkCalendar() {
        let url = URL(string: "safa://calendar")!
        XCTAssertTrue(sut.handleDeepLink(url))
        XCTAssertEqual(sut.path.count, 1)
    }

    func testDeepLinkRamadan_outsideRamadan_pushesOntoHome() {
        sut.isRamadanActive = { false }
        let url = URL(string: "safa://ramadan")!
        XCTAssertTrue(sut.handleDeepLink(url))
        XCTAssertEqual(sut.selectedTab, .home)
        XCTAssertEqual(sut.path.count, 1)
    }

    func testDeepLinkRamadan_duringRamadan_switchesToPrayerTab() {
        sut.isRamadanActive = { true }
        let url = URL(string: "safa://ramadan")!
        XCTAssertTrue(sut.handleDeepLink(url))
        XCTAssertEqual(sut.selectedTab, .prayer)
        XCTAssertTrue(sut.path.isEmpty, "During Ramadan, should switch tab not push")
    }

    func testDeepLinkSettings() {
        let url = URL(string: "safa://settings")!
        XCTAssertTrue(sut.handleDeepLink(url))
        XCTAssertEqual(sut.path.count, 1)
    }

    func testDeepLinkUnknownReturnsFalse() {
        let url = URL(string: "safa://unknown")!
        XCTAssertFalse(sut.handleDeepLink(url))
        XCTAssertTrue(sut.path.isEmpty)
    }

    func testDeepLinkInvalid_noStateChange() {
        let url = URL(string: "https://example.com")!
        let initialTab = sut.selectedTab
        XCTAssertFalse(sut.handleDeepLink(url))
        XCTAssertEqual(sut.selectedTab, initialTab)
        XCTAssertTrue(sut.path.isEmpty)
    }

    // MARK: - Spotlight Integration Tests

    func testSpotlightIdentifierSurah() {
        XCTAssertTrue(sut.handleSpotlightIdentifier("surah_2"))
        XCTAssertEqual(sut.path.count, 1)
    }

    func testSpotlightIdentifierAyah() {
        XCTAssertTrue(sut.handleSpotlightIdentifier("ayah_2_255"))
        XCTAssertEqual(sut.path.count, 1)
    }

    func testSpotlightIdentifierHadith() {
        XCTAssertTrue(sut.handleSpotlightIdentifier("hadith_bukhari_1"))
        XCTAssertEqual(sut.path.count, 1)
    }

    func testSpotlightIdentifierDua() {
        XCTAssertTrue(sut.handleSpotlightIdentifier("dua_morning"))
        XCTAssertEqual(sut.path.count, 1)
    }

    func testSpotlightIdentifierName() {
        XCTAssertTrue(sut.handleSpotlightIdentifier("name_1"))
        XCTAssertEqual(sut.path.count, 1)
    }

    func testSpotlightIdentifierInvalidReturnsFalse() {
        XCTAssertFalse(sut.handleSpotlightIdentifier("invalid"))
        XCTAssertTrue(sut.path.isEmpty)
    }

    func testSpotlightIdentifierUnknownTypeReturnsFalse() {
        XCTAssertFalse(sut.handleSpotlightIdentifier("unknown_123"))
        XCTAssertTrue(sut.path.isEmpty)
    }

    func testSpotlightIdentifierPrayer() {
        XCTAssertTrue(sut.handleSpotlightIdentifier("prayer_fajr"))
        XCTAssertEqual(sut.selectedTab, .prayer)
        XCTAssertTrue(sut.path.isEmpty, "Prayer should switch tab, not push")
    }

    func testSpotlightIdentifierFeatureQibla() {
        XCTAssertTrue(sut.handleSpotlightIdentifier("feature_qibla"))
        XCTAssertEqual(sut.path.count, 1)
    }

    func testSpotlightIdentifierFeaturePrayerTimes() {
        XCTAssertTrue(sut.handleSpotlightIdentifier("feature_prayer_times"))
        XCTAssertEqual(sut.selectedTab, .prayer)
        XCTAssertTrue(sut.path.isEmpty, "Prayer times should switch tab, not push")
    }

    func testSpotlightIdentifierFeatureQuran() {
        XCTAssertTrue(sut.handleSpotlightIdentifier("feature_quran"))
        XCTAssertEqual(sut.selectedTab, .quran)
        XCTAssertTrue(sut.path.isEmpty, "Quran should switch tab, not push")
    }

    func testSpotlightIdentifierFeatureDua() {
        XCTAssertTrue(sut.handleSpotlightIdentifier("feature_dua"))
        XCTAssertEqual(sut.selectedTab, .duas)
        XCTAssertTrue(sut.path.isEmpty, "Dua should switch tab, not push")
    }

    func testSpotlightIdentifierFeatureCalendar() {
        XCTAssertTrue(sut.handleSpotlightIdentifier("feature_calendar"))
        XCTAssertEqual(sut.path.count, 1)
    }

    func testSpotlightIdentifierFeatureUnknown() {
        XCTAssertFalse(sut.handleSpotlightIdentifier("feature_nonexistent"))
        XCTAssertTrue(sut.path.isEmpty)
    }

    // MARK: - Spotlight Result Glue Tests

    func testSpotlightResult_validActivity_routesCorrectly() {
        let activity = NSUserActivity(activityType: "com.apple.corespotlightitem")
        activity.userInfo = ["kCSSearchableItemActivityIdentifier": "surah_2"]
        XCTAssertTrue(sut.handleSpotlightResult(activity))
        XCTAssertEqual(sut.path.count, 1)
    }

    func testSpotlightResult_wrongActivityType_returnsFalse() {
        let activity = NSUserActivity(activityType: "com.apple.wrong")
        XCTAssertFalse(sut.handleSpotlightResult(activity))
    }

    func testSpotlightResult_missingIdentifier_returnsFalse() {
        let activity = NSUserActivity(activityType: "com.apple.corespotlightitem")
        activity.userInfo = [:]
        XCTAssertFalse(sut.handleSpotlightResult(activity))
    }

    // MARK: - Blocked Chat Navigation Clears Pending State

    func testNavigateToChat_whenDisabled_clearsPendingInput() {
        FeatureFlags.shared.setOverride(.aiCompanion, enabled: false)
        sut.pendingChatInput = "How do I pray Fajr?"

        sut.navigate(to: .chat)

        XCTAssertNil(sut.pendingChatInput, "Pending input should be cleared when navigation is blocked")
        XCTAssertTrue(sut.path.isEmpty, "Path should remain empty when AI is disabled")
    }

    func testNavigateToChat_whenDisabled_clearsPendingContext() {
        FeatureFlags.shared.setOverride(.aiCompanion, enabled: false)
        sut.pendingChatContext = ChatContext(topic: .quran, surahNumber: 2, ayahNumber: 255)

        sut.navigate(to: .chat)

        XCTAssertNil(sut.pendingChatContext, "Pending context should be cleared when navigation is blocked")
        XCTAssertTrue(sut.path.isEmpty)
    }

    func testNavigateToChat_whenDisabled_clearsBothPendingInputAndContext() {
        FeatureFlags.shared.setOverride(.aiCompanion, enabled: false)
        sut.pendingChatInput = "Explain this ayah"
        sut.pendingChatContext = ChatContext(topic: .hadith, hadithId: "bukhari_1")

        sut.navigate(to: .chat)

        XCTAssertNil(sut.pendingChatInput)
        XCTAssertNil(sut.pendingChatContext)
    }

    func testNavigateToChat_whenEnabled_preservesPendingState() {
        FeatureFlags.shared.setOverride(.aiCompanion, enabled: true)
        sut.pendingChatInput = "How do I pray?"
        sut.pendingChatContext = ChatContext(topic: .quran, surahNumber: 1)

        sut.navigate(to: .chat)

        XCTAssertEqual(sut.pendingChatInput, "How do I pray?")
        XCTAssertNotNil(sut.pendingChatContext)
        XCTAssertEqual(sut.path.count, 1)
    }

    // MARK: - Chat Launch Mode Tests

    func test_pendingChatLaunchMode_defaultsToPreFillOnly() {
        if case .prefillOnly = sut.pendingChatLaunchMode {
            // Expected
        } else {
            XCTFail("Default launch mode should be .prefillOnly")
        }
    }

    func test_navigateToChat_whenDisabled_resetsLaunchMode() {
        FeatureFlags.shared.setOverride(.aiCompanion, enabled: false)
        sut.pendingChatLaunchMode = .autoSend

        sut.navigate(to: .chat)

        if case .prefillOnly = sut.pendingChatLaunchMode {
            // Expected
        } else {
            XCTFail("Launch mode should be reset to .prefillOnly when navigation is blocked")
        }
    }

    // MARK: - Cross-Tab Chat Navigation Tests

    func test_navigateToChat_switchesToHomeTab() {
        FeatureFlags.shared.setOverride(.aiCompanion, enabled: true)
        defer { FeatureFlags.shared.removeOverride(.aiCompanion) }
        sut.selectedTab = .prayer

        sut.navigate(to: .chat)

        XCTAssertEqual(sut.selectedTab, .home)
        XCTAssertEqual(sut.path.count, 1)
    }

    func test_navigateToChat_fromMoreTab_switchesAndPushes() {
        FeatureFlags.shared.setOverride(.aiCompanion, enabled: true)
        defer { FeatureFlags.shared.removeOverride(.aiCompanion) }
        sut.selectedTab = .more

        sut.navigate(to: .chat)

        XCTAssertEqual(sut.selectedTab, .home)
        XCTAssertEqual(sut.path.count, 1)
    }

    // MARK: - Destination Enum Tests

    func testDestinationIsHashable() {
        let destinations: Set<AppRouter.Destination> = [
            .prayer,
            .qibla,
            .quran,
            .chat
        ]
        XCTAssertEqual(destinations.count, 4)
    }

    func testDestinationWithAssociatedValues() {
        let surah1 = AppRouter.Destination.surah(number: 1)
        let surah2 = AppRouter.Destination.surah(number: 2)
        XCTAssertNotEqual(surah1, surah2)

        let surah1Copy = AppRouter.Destination.surah(number: 1)
        XCTAssertEqual(surah1, surah1Copy)
    }

    // MARK: - Sheet ID Tests

    func testSheetIdUnique() {
        let shareSheet = AppRouter.Sheet.share(content: AppRouter.ShareContent(text: "test", url: nil))
        let inviteSheet = AppRouter.Sheet.invite
        let downloadsSheet = AppRouter.Sheet.downloads

        XCTAssertNotEqual(shareSheet.id, inviteSheet.id)
        XCTAssertNotEqual(inviteSheet.id, downloadsSheet.id)
        XCTAssertNotEqual(shareSheet.id, downloadsSheet.id)
    }

    // MARK: - Alert ID Tests

    func testAlertIdUnique() {
        let errorAlert = AppRouter.AlertType.error(message: "Error")
        let confirmationAlert = AppRouter.AlertType.confirmation(title: "Title", message: "Message", action: {})

        XCTAssertNotEqual(errorAlert.id, confirmationAlert.id)
    }

    // MARK: - ShareContent Tests

    func testShareContentIsHashable() {
        let content1 = AppRouter.ShareContent(text: "test", url: nil)
        let content2 = AppRouter.ShareContent(text: "test", url: nil)
        XCTAssertEqual(content1, content2)

        let content3 = AppRouter.ShareContent(text: "different", url: nil)
        XCTAssertNotEqual(content1, content3)
    }

    // MARK: - Tab Selection Tests

    func testSelectedTab_defaultsToHome() {
        XCTAssertEqual(sut.selectedTab, .home)
    }

    func testSelectedTab_canSwitchToPrayer() {
        sut.selectedTab = .prayer
        XCTAssertEqual(sut.selectedTab, .prayer)
    }

    func testSelectedTab_canSwitchToQuran() {
        sut.selectedTab = .quran
        XCTAssertEqual(sut.selectedTab, .quran)
    }

    func testSelectedTab_canSwitchBetweenTabs() {
        sut.selectedTab = .prayer
        XCTAssertEqual(sut.selectedTab, .prayer)

        sut.selectedTab = .home
        XCTAssertEqual(sut.selectedTab, .home)

        sut.selectedTab = .more
        XCTAssertEqual(sut.selectedTab, .more)
    }

    // MARK: - Navigate Returns Bool

    func test_navigate_returnsTrue_forNonChat() {
        XCTAssertTrue(sut.navigate(to: .prayer))
    }

    func test_navigate_returnsFalse_whenChatDisabled() {
        FeatureFlags.shared.setOverride(.aiCompanion, enabled: false)
        XCTAssertFalse(sut.navigate(to: .chat))
    }

    func test_navigate_returnsTrue_whenChatEnabled() {
        FeatureFlags.shared.setOverride(.aiCompanion, enabled: true)
        defer { FeatureFlags.shared.removeOverride(.aiCompanion) }
        XCTAssertTrue(sut.navigate(to: .chat))
    }
}
