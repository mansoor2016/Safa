// MARK: - ShareBannerTests.swift
// PURPOSE: Unit tests for ShareBanner dismiss persistence
// DEPENDENCIES: XCTest, Safa

import XCTest
@testable import Safa

final class ShareBannerTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Clean up UserDefaults before each test
        UserDefaults.standard.removeObject(forKey: "share_banner_dismissed")
    }

    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: "share_banner_dismissed")
        super.tearDown()
    }

    func test_isDismissed_defaultsFalse() {
        XCTAssertFalse(ShareBanner.isDismissed)
    }

    func test_isDismissed_trueAfterSettingUserDefaults() {
        UserDefaults.standard.set(true, forKey: "share_banner_dismissed")
        XCTAssertTrue(ShareBanner.isDismissed)
    }

    func test_isDismissed_persistsAcrossReads() {
        UserDefaults.standard.set(true, forKey: "share_banner_dismissed")
        XCTAssertTrue(ShareBanner.isDismissed)
        XCTAssertTrue(ShareBanner.isDismissed) // second read
    }
}
