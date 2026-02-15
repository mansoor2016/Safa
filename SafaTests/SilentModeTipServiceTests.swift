// MARK: - SilentModeTipServiceTests.swift
// PURPOSE: Tests for one-time silent mode tip behavior

import XCTest
@testable import Safa

final class SilentModeTipServiceTests: XCTestCase {
    private var defaults: UserDefaults!
    private let suiteName = "SilentModeTipServiceTests"

    override func setUp() {
        super.setUp()
        defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        defaults = nil
        super.tearDown()
    }

    func test_shouldShowTip_returnsTrueInitially() {
        XCTAssertTrue(SilentModeTipService.shouldShowTip(defaults: defaults))
    }

    func test_shouldShowTip_returnsFalseAfterMarked() {
        SilentModeTipService.markTipShown(defaults: defaults)
        XCTAssertFalse(SilentModeTipService.shouldShowTip(defaults: defaults))
    }

    func test_markTipShown_isIdempotent() {
        SilentModeTipService.markTipShown(defaults: defaults)
        SilentModeTipService.markTipShown(defaults: defaults)
        XCTAssertFalse(SilentModeTipService.shouldShowTip(defaults: defaults))
    }

    func test_usesProvidedDefaults() {
        let otherDefaults = UserDefaults(suiteName: "SilentModeTipOther")!
        defer { otherDefaults.removePersistentDomain(forName: "SilentModeTipOther") }

        SilentModeTipService.markTipShown(defaults: defaults)

        // Other defaults instance should still show tip
        XCTAssertTrue(SilentModeTipService.shouldShowTip(defaults: otherDefaults))
        // Original defaults should not
        XCTAssertFalse(SilentModeTipService.shouldShowTip(defaults: defaults))
    }
}
