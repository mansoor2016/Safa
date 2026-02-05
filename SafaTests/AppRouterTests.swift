// MARK: - AppRouterTests.swift
// PURPOSE: Unit tests for AppRouter deep link and navigation handling
// DEPENDENCIES: XCTest, SwiftUI

import XCTest
import SwiftUI
@testable import Safa

final class AppRouterTests: XCTestCase {

    var sut: AppRouter!

    override func setUp() {
        super.setUp()
        sut = AppRouter()
    }

    override func tearDown() {
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

    // MARK: - Deep Link Tests

    func testDeepLinkInvalidSchemeReturnsFalse() {
        let url = URL(string: "https://example.com/prayer")!
        XCTAssertFalse(sut.handleDeepLink(url))
    }

    func testDeepLinkPrayer() {
        let url = URL(string: "safa://prayer")!
        XCTAssertTrue(sut.handleDeepLink(url))
        XCTAssertEqual(sut.path.count, 1)
    }

    func testDeepLinkQibla() {
        let url = URL(string: "safa://qibla")!
        XCTAssertTrue(sut.handleDeepLink(url))
        XCTAssertEqual(sut.path.count, 1)
    }

    func testDeepLinkQuran() {
        let url = URL(string: "safa://quran")!
        XCTAssertTrue(sut.handleDeepLink(url))
        XCTAssertEqual(sut.path.count, 1)
    }

    func testDeepLinkQuranWithSurah() {
        let url = URL(string: "safa://quran/2")!
        XCTAssertTrue(sut.handleDeepLink(url))
        XCTAssertEqual(sut.path.count, 1)
    }

    func testDeepLinkQuranWithSurahAndAyah() {
        let url = URL(string: "safa://quran/2/255")!
        XCTAssertTrue(sut.handleDeepLink(url))
        XCTAssertEqual(sut.path.count, 1)
    }

    func testDeepLinkLearn() {
        let url = URL(string: "safa://learn")!
        XCTAssertTrue(sut.handleDeepLink(url))
        XCTAssertEqual(sut.path.count, 1)
    }

    func testDeepLinkLearnWithLesson() {
        let url = URL(string: "safa://learn/arabic/lesson1")!
        XCTAssertTrue(sut.handleDeepLink(url))
        XCTAssertEqual(sut.path.count, 1)
    }

    func testDeepLinkChat() {
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

    func testDeepLinkRamadan() {
        let url = URL(string: "safa://ramadan")!
        XCTAssertTrue(sut.handleDeepLink(url))
        XCTAssertEqual(sut.path.count, 1)
    }

    func testDeepLinkSettings() {
        let url = URL(string: "safa://settings")!
        XCTAssertTrue(sut.handleDeepLink(url))
        XCTAssertEqual(sut.path.count, 1)
    }

    func testDeepLinkFamily() {
        let url = URL(string: "safa://family")!
        XCTAssertTrue(sut.handleDeepLink(url))
        XCTAssertEqual(sut.path.count, 1)
    }

    func testDeepLinkUnknownReturnsFalse() {
        let url = URL(string: "safa://unknown")!
        XCTAssertFalse(sut.handleDeepLink(url))
        XCTAssertTrue(sut.path.isEmpty)
    }

    // MARK: - Spotlight Identifier Tests

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
}
