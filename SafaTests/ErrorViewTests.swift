// MARK: - ErrorViewTests.swift
// PURPOSE: Tests for ErrorView presets and custom initialization
// DEPENDENCIES: XCTest, Safa

import XCTest
@testable import Safa

final class ErrorViewTests: XCTestCase {

    // MARK: - Load Failed Preset

    func test_loadFailed_hasCorrectIcon() {
        let view = ErrorView.loadFailed()
        XCTAssertEqual(view.icon, "exclamationmark.triangle")
    }

    func test_loadFailed_hasCorrectTitle() {
        let view = ErrorView.loadFailed()
        XCTAssertEqual(view.title, "Something Went Wrong")
    }

    func test_loadFailed_hasCorrectMessage() {
        let view = ErrorView.loadFailed()
        XCTAssertEqual(view.message, "We couldn't load this content. Please try again.")
    }

    func test_loadFailed_hasDefaultRetryTitle() {
        let view = ErrorView.loadFailed()
        XCTAssertEqual(view.retryTitle, "Try Again")
    }

    func test_loadFailed_withoutRetry_hasNilRetry() {
        let view = ErrorView.loadFailed()
        XCTAssertNil(view.retry)
    }

    func test_loadFailed_withRetry_hasRetry() {
        let view = ErrorView.loadFailed(retry: {})
        XCTAssertNotNil(view.retry)
    }

    // MARK: - Network Error Preset

    func test_networkError_hasCorrectIcon() {
        let view = ErrorView.networkError()
        XCTAssertEqual(view.icon, "wifi.exclamationmark")
    }

    func test_networkError_hasCorrectTitle() {
        let view = ErrorView.networkError()
        XCTAssertEqual(view.title, "Connection Issue")
    }

    func test_networkError_hasCorrectMessage() {
        let view = ErrorView.networkError()
        XCTAssertEqual(view.message, "Please check your internet connection and try again.")
    }

    // MARK: - Prayer Times Error Preset

    func test_prayerTimesError_hasCorrectIcon() {
        let view = ErrorView.prayerTimesError()
        XCTAssertEqual(view.icon, "clock.badge.exclamationmark")
    }

    func test_prayerTimesError_hasCorrectTitle() {
        let view = ErrorView.prayerTimesError()
        XCTAssertEqual(view.title, "Couldn't Load Prayer Times")
    }

    func test_prayerTimesError_hasCorrectMessage() {
        let view = ErrorView.prayerTimesError()
        XCTAssertEqual(view.message, "We couldn't calculate prayer times. Please check your location settings.")
    }

    // MARK: - Custom Init

    func test_customInit_setsAllProperties() {
        let view = ErrorView(
            icon: "custom.icon",
            title: "Custom Title",
            message: "Custom message",
            retryTitle: "Reload"
        )

        XCTAssertEqual(view.icon, "custom.icon")
        XCTAssertEqual(view.title, "Custom Title")
        XCTAssertEqual(view.message, "Custom message")
        XCTAssertEqual(view.retryTitle, "Reload")
    }

    func test_customInit_defaultRetryTitle() {
        let view = ErrorView(
            icon: "icon",
            title: "Title",
            message: "Message"
        )

        XCTAssertEqual(view.retryTitle, "Try Again")
    }
}
