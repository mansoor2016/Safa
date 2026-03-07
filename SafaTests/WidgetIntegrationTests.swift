// MARK: - WidgetIntegrationTests.swift
// PURPOSE: Integration-seam tests for widget plumbing — snippet validation, deep-link routing, entry assembly
// DEPENDENCIES: XCTest, Safa, SafaShared

import XCTest
@testable import Safa
import SafaShared

final class WidgetIntegrationTests: XCTestCase {

    private var widgetDataService: WidgetDataService!
    private let testSuiteName = "group.com.safa.app.test.integration.\(UUID().uuidString)"
    private var defaults: UserDefaults!

    override func setUp() {
        super.setUp()
        defaults = UserDefaults(suiteName: testSuiteName)
        widgetDataService = WidgetDataService(suiteName: testSuiteName)
    }

    override func tearDown() {
        defaults?.removePersistentDomain(forName: testSuiteName)
        defaults = nil
        widgetDataService = nil
        super.tearDown()
    }

    // MARK: - writePostPrayerContent Integration

    func test_writePostPrayerContent_writesAllSnippetKeys() {
        widgetDataService.writePostPrayerContent(for: "fajr")

        XCTAssertNotNil(defaults.string(forKey: WidgetAppGroupKeys.snippetArabic),
                        "Arabic text should be written")
        XCTAssertNotNil(defaults.string(forKey: WidgetAppGroupKeys.snippetTranslation),
                        "Translation should be written")
        XCTAssertNotNil(defaults.string(forKey: WidgetAppGroupKeys.snippetReference),
                        "Reference should be written")
        XCTAssertEqual(defaults.string(forKey: WidgetAppGroupKeys.snippetPrayerId), "fajr",
                       "Prayer ID should match the prayer that triggered the write")
        XCTAssertNotNil(defaults.string(forKey: WidgetAppGroupKeys.snippetDeepLink),
                        "Deep link should be written")
    }

    func test_writePostPrayerContent_readableViaReadSnippet() {
        widgetDataService.writePostPrayerContent(for: "dhuhr")

        let snippet = widgetDataService.readSnippet()
        XCTAssertNotNil(snippet, "readSnippet should return data after writePostPrayerContent")
        XCTAssertEqual(snippet?.prayerId, "dhuhr")
        XCTAssertFalse(snippet?.arabic.isEmpty ?? true, "Arabic should not be empty")
        XCTAssertFalse(snippet?.translation.isEmpty ?? true, "Translation should not be empty")
    }

    func test_writePostPrayerContent_differentPrayersWriteDifferentPrayerIds() {
        widgetDataService.writePostPrayerContent(for: "fajr")
        let fajrId = widgetDataService.readSnippet()?.prayerId

        widgetDataService.writePostPrayerContent(for: "isha")
        let ishaId = widgetDataService.readSnippet()?.prayerId

        XCTAssertEqual(fajrId, "fajr")
        XCTAssertEqual(ishaId, "isha")
    }

    // MARK: - Snippet/Deep-Link Resolution (WidgetSnippetResolver)

    func test_resolveSnippetAndDeepLink_preAdhan_returnsPrayerDeepLink() {
        let state = WidgetPrayerState.preAdhan(prayerName: "Dhuhr", prayerTime: Date(), prayerId: "dhuhr")
        let result = resolveSnippetAndDeepLink(state: state, snippet: nil)

        XCTAssertNil(result.snippetArabic)
        XCTAssertEqual(result.deepLink, "safa://prayer")
    }

    func test_resolveSnippetAndDeepLink_prayerWindow_returnsPrayerDeepLink() {
        let state = WidgetPrayerState.prayerWindow(prayerName: "Asr", prayerTime: Date(), prayerId: "asr")
        let result = resolveSnippetAndDeepLink(state: state, snippet: nil)

        XCTAssertNil(result.snippetArabic)
        XCTAssertEqual(result.deepLink, "safa://prayer")
    }

    func test_resolveSnippetAndDeepLink_gracePrompt_returnsPrayerDeepLink() {
        let state = WidgetPrayerState.gracePrompt(prayerName: "Maghrib", prayerId: "maghrib")
        let result = resolveSnippetAndDeepLink(state: state, snippet: nil)

        XCTAssertNil(result.snippetArabic)
        XCTAssertEqual(result.deepLink, "safa://prayer")
    }

    func test_resolveSnippetAndDeepLink_allComplete_returnsDhikrDeepLink() {
        let state = WidgetPrayerState.allComplete(streakCount: 5)
        let result = resolveSnippetAndDeepLink(state: state, snippet: nil)

        XCTAssertNil(result.snippetArabic)
        XCTAssertEqual(result.deepLink, "safa://dhikr")
    }

    func test_resolveSnippetAndDeepLink_dayEnded_returnsPrayerDeepLink() {
        let state = WidgetPrayerState.dayEnded
        let result = resolveSnippetAndDeepLink(state: state, snippet: nil)

        XCTAssertNil(result.snippetArabic)
        XCTAssertEqual(result.deepLink, "safa://prayer")
    }

    func test_resolveSnippetAndDeepLink_postPrayer_matchingSnippet_returnsContent() {
        let state = WidgetPrayerState.postPrayer(prayerId: "fajr")
        let snippet = (arabic: "بسم الله", translation: "In the name of Allah", reference: "Quran 1:1", prayerId: "fajr", deepLink: "safa://quran")
        let result = resolveSnippetAndDeepLink(state: state, snippet: snippet)

        XCTAssertEqual(result.snippetArabic, "بسم الله")
        XCTAssertEqual(result.snippetTranslation, "In the name of Allah")
        XCTAssertEqual(result.snippetReference, "Quran 1:1")
        XCTAssertEqual(result.deepLink, "safa://quran")
    }

    func test_resolveSnippetAndDeepLink_postPrayer_staleSnippet_rejectsContent() {
        // State says postPrayer for "dhuhr" but snippet was written for "fajr"
        let state = WidgetPrayerState.postPrayer(prayerId: "dhuhr")
        let snippet = (arabic: "بسم الله", translation: "In the name of Allah", reference: "Quran 1:1", prayerId: "fajr", deepLink: "safa://quran")
        let result = resolveSnippetAndDeepLink(state: state, snippet: snippet)

        XCTAssertNil(result.snippetArabic, "Stale snippet (wrong prayer) should be rejected")
        XCTAssertNil(result.snippetTranslation)
        XCTAssertEqual(result.deepLink, "safa://prayer",
                       "Should fall back to prayer deep link when snippet is stale")
    }

    func test_resolveSnippetAndDeepLink_postPrayer_noSnippet_returnsPrayerDeepLink() {
        let state = WidgetPrayerState.postPrayer(prayerId: "asr")
        let result = resolveSnippetAndDeepLink(state: state, snippet: nil)

        XCTAssertNil(result.snippetArabic)
        XCTAssertEqual(result.deepLink, "safa://prayer")
    }

    // MARK: - State Resolver + Snippet Integration

    func test_loggedPrayer_producesPostPrayerState_withMatchingSnippet() {
        // Set up: Fajr was 10 minutes ago and is logged
        let now = Date()
        let fajrTime = now.addingTimeInterval(-600) // 10 min ago
        let prayers: [PrayerInfo] = [
            PrayerInfo(id: "fajr", name: "Fajr", time: fajrTime),
            PrayerInfo(id: "dhuhr", name: "Dhuhr", time: now.addingTimeInterval(7200)),
            PrayerInfo(id: "asr", name: "Asr", time: now.addingTimeInterval(14400)),
            PrayerInfo(id: "maghrib", name: "Maghrib", time: now.addingTimeInterval(21600)),
            PrayerInfo(id: "isha", name: "Isha", time: now.addingTimeInterval(28800)),
        ]

        let state = WidgetPrayerStateResolver.resolve(
            prayers: prayers,
            loggedPrayerIds: ["fajr"],
            streakCount: 3,
            at: now
        )

        // Should be postPrayer for fajr
        if case .postPrayer(let prayerId) = state {
            XCTAssertEqual(prayerId, "fajr")

            // Now write snippet and verify it's accepted
            widgetDataService.writePostPrayerContent(for: prayerId)
            let snippet = widgetDataService.readSnippet()
            let result = resolveSnippetAndDeepLink(
                state: state,
                snippet: snippet.map { ($0.arabic, $0.translation, $0.reference, $0.prayerId, $0.deepLink) }
            )

            XCTAssertNotNil(result.snippetArabic, "Matching snippet should be accepted")
            XCTAssertNotEqual(result.deepLink, "safa://prayer",
                              "Should use snippet deep link, not prayer fallback")
        } else {
            XCTFail("Expected .postPrayer(fajr), got \(state)")
        }
    }

    func test_unloggedPrayer_inGrace_producesPrayerWindowState() {
        let now = Date()
        let fajrTime = now.addingTimeInterval(-300) // 5 min ago
        let prayers: [PrayerInfo] = [
            PrayerInfo(id: "fajr", name: "Fajr", time: fajrTime),
            PrayerInfo(id: "dhuhr", name: "Dhuhr", time: now.addingTimeInterval(7200)),
            PrayerInfo(id: "asr", name: "Asr", time: now.addingTimeInterval(14400)),
            PrayerInfo(id: "maghrib", name: "Maghrib", time: now.addingTimeInterval(21600)),
            PrayerInfo(id: "isha", name: "Isha", time: now.addingTimeInterval(28800)),
        ]

        let state = WidgetPrayerStateResolver.resolve(
            prayers: prayers,
            loggedPrayerIds: [],
            streakCount: 0,
            at: now
        )

        if case .prayerWindow(_, _, let prayerId) = state {
            XCTAssertEqual(prayerId, "fajr")

            // Snippet resolution should return nil (not in postPrayer state)
            let result = resolveSnippetAndDeepLink(state: state, snippet: nil)
            XCTAssertNil(result.snippetArabic)
            XCTAssertEqual(result.deepLink, "safa://prayer")
        } else {
            XCTFail("Expected .prayerWindow(fajr), got \(state)")
        }
    }

    // MARK: - Private Helpers

    /// Delegates to WidgetSnippetResolver in SafaShared — the same code used by the widget extension.
    private func resolveSnippetAndDeepLink(
        state: WidgetPrayerState,
        snippet: (arabic: String, translation: String, reference: String, prayerId: String, deepLink: String)?
    ) -> (snippetArabic: String?, snippetTranslation: String?, snippetReference: String?, deepLink: String) {
        WidgetSnippetResolver.resolve(state: state, snippet: snippet)
    }
}
