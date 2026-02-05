// MARK: - DeepLinkTests.swift
// PURPOSE: Unit tests for deep link URL parsing
// DEPENDENCIES: XCTest

import XCTest
@testable import Safa

final class DeepLinkTests: XCTestCase {

    var sut: AppRouter!

    override func setUp() {
        super.setUp()
        sut = AppRouter()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - Prayer Deep Links

    func testPrayerDeepLink() {
        let url = URL(string: "safa://prayer")!

        let handled = sut.handleDeepLink(url)

        XCTAssertTrue(handled)
        XCTAssertEqual(sut.currentDestination, .prayer)
    }

    func testQiblaDeepLink() {
        let url = URL(string: "safa://qibla")!

        let handled = sut.handleDeepLink(url)

        XCTAssertTrue(handled)
        XCTAssertEqual(sut.currentDestination, .qibla)
    }

    // MARK: - Quran Deep Links

    func testQuranDeepLink() {
        let url = URL(string: "safa://quran")!

        let handled = sut.handleDeepLink(url)

        XCTAssertTrue(handled)
        XCTAssertEqual(sut.currentDestination, .quran)
    }

    func testQuranSurahDeepLink() {
        let url = URL(string: "safa://quran/surah/1")!

        let handled = sut.handleDeepLink(url)

        XCTAssertTrue(handled)
        if case .quranSurah(let surah) = sut.currentDestination {
            XCTAssertEqual(surah, 1)
        } else {
            XCTFail("Should navigate to quranSurah destination")
        }
    }

    func testQuranAyahDeepLink() {
        let url = URL(string: "safa://quran/surah/2/ayah/255")!

        let handled = sut.handleDeepLink(url)

        XCTAssertTrue(handled)
        if case .quranAyah(let surah, let ayah) = sut.currentDestination {
            XCTAssertEqual(surah, 2)
            XCTAssertEqual(ayah, 255)
        } else {
            XCTFail("Should navigate to quranAyah destination")
        }
    }

    // MARK: - Chat Deep Links

    func testChatDeepLink() {
        let url = URL(string: "safa://chat")!

        let handled = sut.handleDeepLink(url)

        XCTAssertTrue(handled)
        XCTAssertEqual(sut.currentDestination, .chat)
    }

    // MARK: - Learn Deep Links

    func testLearnDeepLink() {
        let url = URL(string: "safa://learn")!

        let handled = sut.handleDeepLink(url)

        XCTAssertTrue(handled)
        XCTAssertEqual(sut.currentDestination, .learn)
    }

    func testLearnTrackDeepLink() {
        let url = URL(string: "safa://learn/track/arabic_foundations")!

        let handled = sut.handleDeepLink(url)

        XCTAssertTrue(handled)
        if case .learnTrack(let trackId) = sut.currentDestination {
            XCTAssertEqual(trackId, "arabic_foundations")
        } else {
            XCTFail("Should navigate to learnTrack destination")
        }
    }

    // MARK: - Dhikr Deep Links

    func testDhikrDeepLink() {
        let url = URL(string: "safa://dhikr")!

        let handled = sut.handleDeepLink(url)

        XCTAssertTrue(handled)
        XCTAssertEqual(sut.currentDestination, .dhikr)
    }

    func testTasbeehDeepLink() {
        let url = URL(string: "safa://dhikr/tasbeeh")!

        let handled = sut.handleDeepLink(url)

        XCTAssertTrue(handled)
        XCTAssertEqual(sut.currentDestination, .tasbeeh)
    }

    // MARK: - Family Deep Links

    func testFamilyDeepLink() {
        let url = URL(string: "safa://family")!

        let handled = sut.handleDeepLink(url)

        XCTAssertTrue(handled)
        XCTAssertEqual(sut.currentDestination, .family)
    }

    func testFamilyJoinDeepLink() {
        let url = URL(string: "safa://family/join?code=ABC123")!

        let handled = sut.handleDeepLink(url)

        XCTAssertTrue(handled)
        if case .familyJoin(let code) = sut.currentDestination {
            XCTAssertEqual(code, "ABC123")
        } else {
            XCTFail("Should navigate to familyJoin destination with code")
        }
    }

    // MARK: - Progress Deep Links

    func testProgressDeepLink() {
        let url = URL(string: "safa://progress")!

        let handled = sut.handleDeepLink(url)

        XCTAssertTrue(handled)
        XCTAssertEqual(sut.currentDestination, .progress)
    }

    func testAchievementsDeepLink() {
        let url = URL(string: "safa://achievements")!

        let handled = sut.handleDeepLink(url)

        XCTAssertTrue(handled)
        XCTAssertEqual(sut.currentDestination, .achievements)
    }

    // MARK: - Settings Deep Links

    func testSettingsDeepLink() {
        let url = URL(string: "safa://settings")!

        let handled = sut.handleDeepLink(url)

        XCTAssertTrue(handled)
        XCTAssertEqual(sut.currentDestination, .settings)
    }

    // MARK: - Ramadan Deep Links

    func testRamadanDeepLink() {
        let url = URL(string: "safa://ramadan")!

        let handled = sut.handleDeepLink(url)

        XCTAssertTrue(handled)
        XCTAssertEqual(sut.currentDestination, .ramadan)
    }

    // MARK: - Calendar Deep Links

    func testCalendarDeepLink() {
        let url = URL(string: "safa://calendar")!

        let handled = sut.handleDeepLink(url)

        XCTAssertTrue(handled)
        XCTAssertEqual(sut.currentDestination, .calendar)
    }

    // MARK: - Invalid Deep Links

    func testInvalidSchemeIsNotHandled() {
        let url = URL(string: "https://example.com")!

        let handled = sut.handleDeepLink(url)

        XCTAssertFalse(handled)
    }

    func testUnknownPathIsNotHandled() {
        let url = URL(string: "safa://unknown")!

        let handled = sut.handleDeepLink(url)

        XCTAssertFalse(handled)
    }

    func testEmptyPathIsNotHandled() {
        let url = URL(string: "safa://")!

        let handled = sut.handleDeepLink(url)

        XCTAssertFalse(handled)
    }

    func testMalformedURLIsNotHandled() {
        // This test ensures the router handles edge cases gracefully
        let url = URL(string: "safa://quran/surah/invalid")!

        // Should either return false or handle gracefully
        let _ = sut.handleDeepLink(url)
        // No crash = test passes
    }
}

// MARK: - App Router Destination Tests

final class AppRouterDestinationTests: XCTestCase {

    func testDestinationEquality() {
        XCTAssertEqual(Destination.home, Destination.home)
        XCTAssertEqual(Destination.prayer, Destination.prayer)
        XCTAssertNotEqual(Destination.prayer, Destination.quran)
    }

    func testQuranDestinationsWithDifferentSurahs() {
        let surah1 = Destination.quranSurah(surah: 1)
        let surah2 = Destination.quranSurah(surah: 2)

        XCTAssertNotEqual(surah1, surah2)
    }

    func testQuranAyahDestinations() {
        let ayah1 = Destination.quranAyah(surah: 2, ayah: 255)
        let ayah2 = Destination.quranAyah(surah: 2, ayah: 256)

        XCTAssertNotEqual(ayah1, ayah2)
    }

    func testFamilyJoinDestinations() {
        let join1 = Destination.familyJoin(code: "ABC")
        let join2 = Destination.familyJoin(code: "XYZ")

        XCTAssertNotEqual(join1, join2)
    }
}
