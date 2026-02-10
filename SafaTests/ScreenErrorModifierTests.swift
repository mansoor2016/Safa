// MARK: - ScreenErrorModifierTests.swift
// PURPOSE: Tests for ScreenErrorModifier property storage and view extension
// DEPENDENCIES: XCTest, Safa

import XCTest
import SwiftUI
@testable import Safa

final class ScreenErrorModifierTests: XCTestCase {

    // MARK: - Error Storage

    func test_modifier_withNilError_storesNil() {
        let modifier = ScreenErrorModifier(error: nil, retry: nil)
        XCTAssertNil(modifier.error)
    }

    func test_modifier_withError_storesError() {
        let error = NSError(domain: "test", code: 42)
        let modifier = ScreenErrorModifier(error: error, retry: nil)
        XCTAssertNotNil(modifier.error)
        XCTAssertEqual((modifier.error as? NSError)?.code, 42)
    }

    // MARK: - Retry Storage

    func test_modifier_withNilRetry_storesNil() {
        let modifier = ScreenErrorModifier(error: nil, retry: nil)
        XCTAssertNil(modifier.retry)
    }

    func test_modifier_withRetry_storesRetry() {
        let modifier = ScreenErrorModifier(error: nil, retry: {})
        XCTAssertNotNil(modifier.retry)
    }

    // MARK: - View Extension

    func test_screenError_extensionCreatesModifier() {
        // Verify the extension compiles and produces a valid modified view
        let baseView = Text("Content")
        let modified = baseView.screenError(nil)
        // If this compiles and doesn't crash, the extension works
        XCTAssertNotNil(modified)
    }

    func test_screenError_extensionAcceptsError() {
        let error = NSError(domain: "test", code: 1)
        let baseView = Text("Content")
        let modified = baseView.screenError(error, retry: {})
        XCTAssertNotNil(modified)
    }
}
