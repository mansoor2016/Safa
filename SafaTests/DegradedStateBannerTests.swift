// MARK: - DegradedStateBannerTests.swift
// PURPOSE: Unit tests for DegradedStateBanner component variants
// DEPENDENCIES: XCTest, Safa

import XCTest
import SwiftUI
@testable import Safa

final class DegradedStateBannerTests: XCTestCase {

    func test_locationFallback_hasCorrectIcon() {
        let banner = DegradedStateBanner.locationFallback(locationName: "London, UK")
        XCTAssertEqual(banner.icon, "location.slash")
    }

    func test_locationFallback_includesLocationName() {
        let banner = DegradedStateBanner.locationFallback(locationName: "Tokyo, Japan")
        XCTAssertTrue(banner.message.contains("Tokyo, Japan"))
    }

    func test_locationFallback_hasUpdateAction_whenProvided() {
        let banner = DegradedStateBanner.locationFallback(locationName: "London", action: {})
        XCTAssertEqual(banner.actionLabel, "Update")
    }

    func test_locationFallback_noAction_whenNil() {
        let banner = DegradedStateBanner.locationFallback(locationName: "London")
        XCTAssertNil(banner.actionLabel)
    }

    func test_offline_hasCorrectIcon() {
        let banner = DegradedStateBanner.offline()
        XCTAssertEqual(banner.icon, "wifi.slash")
    }

    func test_offline_hasNoAction() {
        let banner = DegradedStateBanner.offline()
        XCTAssertNil(banner.actionLabel)
    }

    func test_compassLowAccuracy_hasCorrectIcon() {
        let banner = DegradedStateBanner.compassLowAccuracy()
        XCTAssertEqual(banner.icon, "exclamationmark.circle")
    }

    func test_syncPaused_hasCorrectIcon() {
        let banner = DegradedStateBanner.syncPaused()
        XCTAssertEqual(banner.icon, "icloud.slash")
    }

    func test_storageLow_hasRedColor() {
        let banner = DegradedStateBanner.storageLow()
        XCTAssertEqual(banner.color, .red)
    }

    func test_storageLow_hasManageAction_whenProvided() {
        let banner = DegradedStateBanner.storageLow(action: {})
        XCTAssertEqual(banner.actionLabel, "Manage")
    }

    func test_customBanner_acceptsAllParameters() {
        let banner = DegradedStateBanner(
            icon: "bolt.slash",
            message: "Custom issue",
            actionLabel: "Fix",
            action: {},
            color: .purple
        )
        XCTAssertEqual(banner.icon, "bolt.slash")
        XCTAssertEqual(banner.message, "Custom issue")
        XCTAssertEqual(banner.actionLabel, "Fix")
        XCTAssertEqual(banner.color, .purple)
    }
}
