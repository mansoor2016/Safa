// MARK: - PrayerProgressIndicatorTests.swift
// PURPOSE: Tests for prayer progress indicator state classification and icon mapping
// DEPENDENCIES: XCTest

import XCTest
import SwiftUI
@testable import Safa

final class PrayerProgressIndicatorTests: XCTestCase {

    typealias PrayerState = PrayerProgressIndicator.PrayerState

    // MARK: - Status Icon Mapping Tests

    func test_loggedPrayer_showsFilledCheckmark() {
        let state = PrayerState(type: .fajr, isLogged: true, isNext: false, isPastUnlogged: false, canTap: true)
        let (icon, _) = PrayerProgressIndicator.expandedStatusIconInfo(for: state)
        XCTAssertEqual(icon, "checkmark.circle.fill")
    }

    func test_nextPrayer_showsDottedCircle() {
        let state = PrayerState(type: .dhuhr, isLogged: false, isNext: true, isPastUnlogged: false, canTap: true)
        let (icon, _) = PrayerProgressIndicator.expandedStatusIconInfo(for: state)
        XCTAssertEqual(icon, "circle.dotted")
    }

    func test_missedPrayer_showsMinusCircle() {
        let state = PrayerState(type: .fajr, isLogged: false, isNext: false, isPastUnlogged: true, canTap: true)
        let (icon, _) = PrayerProgressIndicator.expandedStatusIconInfo(for: state)
        XCTAssertEqual(icon, "minus.circle")
    }

    func test_futurePrayer_showsEmptyCircle() {
        let state = PrayerState(type: .isha, isLogged: false, isNext: false, isPastUnlogged: false, canTap: false)
        let (icon, _) = PrayerProgressIndicator.expandedStatusIconInfo(for: state)
        XCTAssertEqual(icon, "circle")
    }

    // MARK: - Priority Tests (logged overrides all other states)

    func test_loggedAndNext_showsCheckmarkNotDotted() {
        // If a prayer is both logged AND marked as next, logged state should win
        let state = PrayerState(type: .dhuhr, isLogged: true, isNext: true, isPastUnlogged: false, canTap: true)
        let (icon, _) = PrayerProgressIndicator.expandedStatusIconInfo(for: state)
        XCTAssertEqual(icon, "checkmark.circle.fill",
            "Logged state should take priority over next-prayer state")
    }

    func test_loggedAndPastUnlogged_showsCheckmark() {
        // Edge case: both logged and isPastUnlogged shouldn't happen, but logged should win
        let state = PrayerState(type: .fajr, isLogged: true, isNext: false, isPastUnlogged: true, canTap: true)
        let (icon, _) = PrayerProgressIndicator.expandedStatusIconInfo(for: state)
        XCTAssertEqual(icon, "checkmark.circle.fill",
            "Logged state should take priority over past-unlogged state")
    }

    func test_nextAndPastUnlogged_showsDottedCircle() {
        // If somehow both next and past-unlogged, next should win (isNext checked before isPastUnlogged)
        let state = PrayerState(type: .asr, isLogged: false, isNext: true, isPastUnlogged: true, canTap: true)
        let (icon, _) = PrayerProgressIndicator.expandedStatusIconInfo(for: state)
        XCTAssertEqual(icon, "circle.dotted",
            "Next-prayer state should take priority over past-unlogged state")
    }

    // MARK: - Color Tests

    func test_loggedPrayer_usesSuccessColor() {
        let state = PrayerState(type: .fajr, isLogged: true, isNext: false, isPastUnlogged: false, canTap: true)
        let (_, color) = PrayerProgressIndicator.expandedStatusIconInfo(for: state)
        XCTAssertEqual(color, SafaColors.success)
    }

    func test_missedPrayer_usesOrangeColor() {
        let state = PrayerState(type: .fajr, isLogged: false, isNext: false, isPastUnlogged: true, canTap: true)
        let (_, color) = PrayerProgressIndicator.expandedStatusIconInfo(for: state)
        XCTAssertEqual(color, .orange)
    }

    // MARK: - All Five States Coverage

    func test_typicalDayMidAfternoon_correctIcons() {
        // Scenario: Fajr logged, Dhuhr logged, Asr is next, Maghrib+Isha future
        let states: [PrayerState] = [
            PrayerState(type: .fajr, isLogged: true, isNext: false, isPastUnlogged: false, canTap: true),
            PrayerState(type: .dhuhr, isLogged: true, isNext: false, isPastUnlogged: false, canTap: true),
            PrayerState(type: .asr, isLogged: false, isNext: true, isPastUnlogged: false, canTap: true),
            PrayerState(type: .maghrib, isLogged: false, isNext: false, isPastUnlogged: false, canTap: false),
            PrayerState(type: .isha, isLogged: false, isNext: false, isPastUnlogged: false, canTap: false),
        ]

        let icons = states.map { PrayerProgressIndicator.expandedStatusIconInfo(for: $0).icon }
        XCTAssertEqual(icons, [
            "checkmark.circle.fill",  // Fajr: logged
            "checkmark.circle.fill",  // Dhuhr: logged
            "circle.dotted",          // Asr: next
            "circle",                 // Maghrib: future
            "circle",                 // Isha: future
        ])
    }

    func test_missedMorningPrayers_correctIcons() {
        // Scenario: Fajr missed, Dhuhr missed, Asr is next
        let states: [PrayerState] = [
            PrayerState(type: .fajr, isLogged: false, isNext: false, isPastUnlogged: true, canTap: true),
            PrayerState(type: .dhuhr, isLogged: false, isNext: false, isPastUnlogged: true, canTap: true),
            PrayerState(type: .asr, isLogged: false, isNext: true, isPastUnlogged: false, canTap: true),
            PrayerState(type: .maghrib, isLogged: false, isNext: false, isPastUnlogged: false, canTap: false),
            PrayerState(type: .isha, isLogged: false, isNext: false, isPastUnlogged: false, canTap: false),
        ]

        let icons = states.map { PrayerProgressIndicator.expandedStatusIconInfo(for: $0).icon }
        XCTAssertEqual(icons, [
            "minus.circle",           // Fajr: missed
            "minus.circle",           // Dhuhr: missed
            "circle.dotted",          // Asr: next
            "circle",                 // Maghrib: future
            "circle",                 // Isha: future
        ])
    }

    func test_allPrayersLogged_allCheckmarks() {
        let states: [PrayerState] = PrayerType.obligatoryPrayers.map {
            PrayerState(type: $0, isLogged: true, isNext: false, isPastUnlogged: false, canTap: true)
        }

        let icons = states.map { PrayerProgressIndicator.expandedStatusIconInfo(for: $0).icon }
        XCTAssertTrue(icons.allSatisfy { $0 == "checkmark.circle.fill" })
    }
}
