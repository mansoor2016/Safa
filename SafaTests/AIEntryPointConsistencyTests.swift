// MARK: - AIEntryPointConsistencyTests.swift
// PURPOSE: Verify all AI entry points behave consistently under enabled/disabled/unsupported states
// DEPENDENCIES: XCTest, Safa

import XCTest
import SwiftUI
@testable import Safa

/// All AI entry points must go through `AppRouter.navigate(to: .chat)`.
/// When `.aiCompanion` is disabled, navigation should be blocked and pending state cleared.
/// When enabled, navigation should succeed and pending state preserved for ChatView.
final class AIEntryPointConsistencyTests: XCTestCase {

    var router: AppRouter!

    override func setUp() {
        super.setUp()
        FeatureFlags.shared.removeOverride(.aiCompanion)
        router = AppRouter()
    }

    override func tearDown() {
        FeatureFlags.shared.removeOverride(.aiCompanion)
        router = nil
        super.tearDown()
    }

    // MARK: - Disabled State: All Entry Points Blocked

    /// Simulates Home toolbar sparkles button path
    func test_homeToolbarPath_whenDisabled_blocksNavigation() {
        // Home toolbar does: router.navigate(to: .chat)
        router.navigate(to: .chat)

        XCTAssertTrue(router.path.isEmpty, "Home path should be blocked when AI disabled")
    }

    /// Simulates More tab "Ask Safa" button path
    func test_moreTabPath_whenDisabled_blocksNavigation() {
        // More tab does: router.navigate(to: .chat)
        router.navigate(to: .chat)

        XCTAssertTrue(router.path.isEmpty, "More path should be blocked when AI disabled")
    }

    /// Simulates Quran "Ask about this ayah" context menu path
    func test_quranContextPath_whenDisabled_blocksAndClearsPending() {
        // Quran context menu sets pending state then navigates
        router.pendingChatContext = ChatContext(topic: .quran, surahNumber: 2, ayahNumber: 255)
        router.pendingChatInput = "Explain Al-Baqarah 2:255"
        router.navigate(to: .chat)

        XCTAssertTrue(router.path.isEmpty)
        XCTAssertNil(router.pendingChatContext, "Context should be cleared on blocked navigation")
        XCTAssertNil(router.pendingChatInput, "Input should be cleared on blocked navigation")
    }

    /// Simulates Hadith "Explain this hadith" button path
    func test_hadithContextPath_whenDisabled_blocksAndClearsPending() {
        router.pendingChatContext = ChatContext(topic: .hadith, hadithId: "bukhari_1")
        router.pendingChatInput = "Explain hadith #1 from bukhari"
        router.navigate(to: .chat)

        XCTAssertTrue(router.path.isEmpty)
        XCTAssertNil(router.pendingChatContext)
        XCTAssertNil(router.pendingChatInput)
    }

    /// Simulates Dua "Learn about this dua" context menu path
    func test_duaContextPath_whenDisabled_blocksAndClearsPending() {
        router.pendingChatContext = ChatContext(topic: .dua, duaId: "dua_sleep_001")
        router.pendingChatInput = "Tell me about this dua: Sleep Dua"
        router.navigate(to: .chat)

        XCTAssertTrue(router.path.isEmpty)
        XCTAssertNil(router.pendingChatContext)
        XCTAssertNil(router.pendingChatInput)
    }

    /// Simulates Siri "Ask Safa about wudu" intent path
    func test_siriIntentPath_whenDisabled_blocksAndClearsPending() {
        router.pendingChatInput = "How do I perform wudu?"
        router.navigate(to: .chat)

        XCTAssertTrue(router.path.isEmpty)
        XCTAssertNil(router.pendingChatInput)
    }

    /// Simulates deep link safa://chat path
    func test_deepLinkPath_whenDisabled_blocksNavigation() {
        let url = URL(string: "safa://chat")!
        let handled = router.handleDeepLink(url)

        XCTAssertFalse(handled, "Deep link should return false when AI disabled")
        XCTAssertTrue(router.path.isEmpty)
    }

    // MARK: - Enabled State: All Entry Points Succeed

    func test_homeToolbarPath_whenEnabled_navigates() {
        FeatureFlags.shared.setOverride(.aiCompanion, enabled: true)

        router.navigate(to: .chat)

        XCTAssertEqual(router.path.count, 1)
    }

    func test_moreTabPath_whenEnabled_navigates() {
        FeatureFlags.shared.setOverride(.aiCompanion, enabled: true)

        router.navigate(to: .chat)

        XCTAssertEqual(router.path.count, 1)
    }

    func test_quranContextPath_whenEnabled_navigatesAndPreservesPending() {
        FeatureFlags.shared.setOverride(.aiCompanion, enabled: true)

        router.pendingChatContext = ChatContext(topic: .quran, surahNumber: 1, ayahNumber: 1)
        router.pendingChatInput = "Explain Al-Fatiha 1:1"
        router.navigate(to: .chat)

        XCTAssertEqual(router.path.count, 1)
        XCTAssertNotNil(router.pendingChatContext, "Context preserved for ChatView to consume")
        XCTAssertNotNil(router.pendingChatInput, "Input preserved for ChatView to consume")
    }

    func test_hadithContextPath_whenEnabled_navigatesAndPreservesPending() {
        FeatureFlags.shared.setOverride(.aiCompanion, enabled: true)

        router.pendingChatContext = ChatContext(topic: .hadith, hadithId: "muslim_1")
        router.pendingChatInput = "Explain hadith #1 from muslim"
        router.navigate(to: .chat)

        XCTAssertEqual(router.path.count, 1)
        XCTAssertNotNil(router.pendingChatContext)
        XCTAssertNotNil(router.pendingChatInput)
    }

    func test_duaContextPath_whenEnabled_navigatesAndPreservesPending() {
        FeatureFlags.shared.setOverride(.aiCompanion, enabled: true)

        router.pendingChatContext = ChatContext(topic: .dua, duaId: "dua_morning_001")
        router.pendingChatInput = "Tell me about this dua"
        router.navigate(to: .chat)

        XCTAssertEqual(router.path.count, 1)
        XCTAssertNotNil(router.pendingChatContext)
    }

    func test_siriIntentPath_whenEnabled_navigatesAndPreservesPending() {
        FeatureFlags.shared.setOverride(.aiCompanion, enabled: true)

        router.pendingChatInput = "How do I perform wudu?"
        router.navigate(to: .chat)

        XCTAssertEqual(router.path.count, 1)
        XCTAssertEqual(router.pendingChatInput, "How do I perform wudu?")
    }

    func test_deepLinkPath_whenEnabled_navigates() {
        FeatureFlags.shared.setOverride(.aiCompanion, enabled: true)

        let url = URL(string: "safa://chat")!
        let handled = router.handleDeepLink(url)

        XCTAssertTrue(handled)
        XCTAssertEqual(router.path.count, 1)
    }

    // MARK: - Availability Gate (Finding 3)
    // UI entry points use `llmService.availability.isAvailable` to show/hide.
    // We can't test SwiftUI view rendering, but we verify the gate logic itself.

    func test_availableState_isAvailableReturnsTrue() {
        let availability = LLMAvailability.available
        XCTAssertTrue(availability.isAvailable)
    }

    func test_requiresNewerOS_isAvailableReturnsFalse() {
        let availability = LLMAvailability.requiresNewerOS(minimumVersion: "26")
        XCTAssertFalse(availability.isAvailable, "Entry points should be hidden when OS is too old")
    }

    func test_unsupportedDevice_isAvailableReturnsFalse() {
        let availability = LLMAvailability.unsupportedDevice
        XCTAssertFalse(availability.isAvailable, "Entry points should be hidden on unsupported devices")
    }

    func test_notConfigured_isAvailableReturnsFalse() {
        let availability = LLMAvailability.notConfigured
        XCTAssertFalse(availability.isAvailable, "Entry points should be hidden when not configured")
    }

    func test_onlyAvailableState_showsEntryPoints() {
        // Verify that exactly one case returns true — all UI entry points
        // use the same `isAvailable` check, so this proves consistency
        let allStates: [LLMAvailability] = [
            .available,
            .requiresNewerOS(minimumVersion: "26"),
            .unsupportedDevice,
            .notConfigured
        ]
        let visibleCount = allStates.filter(\.isAvailable).count
        XCTAssertEqual(visibleCount, 1, "Only .available should show AI entry points")
    }
}
