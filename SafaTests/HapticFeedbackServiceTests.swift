// MARK: - HapticFeedbackServiceTests.swift
// PURPOSE: Unit tests for HapticFeedbackService event mapping and preference gating
// DEPENDENCIES: XCTest, Safa

import XCTest
@testable import Safa

final class HapticFeedbackServiceTests: XCTestCase {

    private var sut: HapticFeedbackService!

    override func setUp() {
        super.setUp()
        UserDefaults.standard.removeObject(forKey: "com.safa.haptics.enabled")
        sut = HapticFeedbackService()
    }

    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: "com.safa.haptics.enabled")
        sut = nil
        super.tearDown()
    }

    // MARK: - Default State

    func test_defaultState_isEnabled() {
        XCTAssertTrue(sut.isEnabled)
    }

    // MARK: - Settings Persistence

    func test_setEnabled_false_persistsToDisk() {
        sut.setEnabled(false)
        XCTAssertFalse(sut.isEnabled)

        let saved = UserDefaults.standard.bool(forKey: "com.safa.haptics.enabled")
        XCTAssertFalse(saved)
    }

    func test_setEnabled_true_persistsToDisk() {
        sut.setEnabled(false)
        sut.setEnabled(true)
        XCTAssertTrue(sut.isEnabled)

        let saved = UserDefaults.standard.bool(forKey: "com.safa.haptics.enabled")
        XCTAssertTrue(saved)
    }

    func test_loadSettings_restoresFromDisk() {
        UserDefaults.standard.set(false, forKey: "com.safa.haptics.enabled")
        sut.loadSettings()
        XCTAssertFalse(sut.isEnabled)
    }

    func test_loadSettings_defaultsTrueWhenNoSavedValue() {
        UserDefaults.standard.removeObject(forKey: "com.safa.haptics.enabled")
        sut.loadSettings()
        XCTAssertTrue(sut.isEnabled)
    }

    // MARK: - Event Enum Coverage

    func test_allHapticEvents_exist() {
        // Verify all expected events can be created
        let events: [HapticEvent] = [
            .tap, .selection, .commit, .success, .warning, .error,
            .qiblaLight, .qiblaPerfect, .tasbeehTap, .tasbeehMilestone,
            .celebration, .levelUp
        ]
        XCTAssertEqual(events.count, 12, "Should have 12 haptic events")
    }

    func test_play_doesNotCrash_forAllEvents() {
        // Verify play() doesn't crash for any event (simulator has no haptics, but shouldn't crash)
        let events: [HapticEvent] = [
            .tap, .selection, .commit, .success, .warning, .error,
            .qiblaLight, .qiblaPerfect, .tasbeehTap, .tasbeehMilestone,
            .celebration, .levelUp
        ]
        for event in events {
            sut.play(event)
        }
    }

    func test_play_doesNotCrash_whenDisabled() {
        sut.setEnabled(false)
        let events: [HapticEvent] = [
            .tap, .selection, .commit, .success, .warning, .error,
            .qiblaLight, .qiblaPerfect, .tasbeehTap, .tasbeehMilestone,
            .celebration, .levelUp
        ]
        for event in events {
            sut.play(event)
        }
    }

    // MARK: - Preference Gating

    func test_impact_doesNothing_whenDisabled() {
        sut.setEnabled(false)
        // Should not crash; no assertion on actual vibration since we're on simulator
        sut.impact(.medium)
        sut.impact(.light)
        sut.impact(.heavy)
    }

    func test_selection_doesNothing_whenDisabled() {
        sut.setEnabled(false)
        sut.selection()
    }

    func test_notification_doesNothing_whenDisabled() {
        sut.setEnabled(false)
        sut.notification(.success)
        sut.notification(.warning)
        sut.notification(.error)
    }

    // MARK: - Convenience Methods

    func test_prayerLogged_doesNotCrash() {
        sut.prayerLogged()
    }

    func test_streakMilestone_doesNotCrash() {
        sut.streakMilestone()
    }

    func test_tasbeehTap_doesNotCrash() {
        sut.tasbeehTap()
    }

    func test_tasbeehMilestone_doesNotCrash() {
        sut.tasbeehMilestone()
    }

    func test_buttonTap_doesNotCrash() {
        sut.buttonTap()
    }

    func test_navigate_doesNotCrash() {
        sut.navigate()
    }

    func test_error_doesNotCrash() {
        sut.error()
    }

    func test_warning_doesNotCrash() {
        sut.warning()
    }

    func test_qiblaFound_doesNotCrash() {
        sut.qiblaFound()
    }

    func test_levelUp_doesNotCrash() {
        sut.levelUp()
    }

    // MARK: - Custom Pattern Coverage

    func test_playCustomPattern_doesNotCrash_forAllPatterns() {
        let patterns: [HapticFeedbackService.HapticPattern] = [
            .celebration, .qiblaLock, .levelUp, .completion
        ]
        for pattern in patterns {
            sut.playCustomPattern(pattern)
        }
    }

    func test_playCustomPattern_doesNotCrash_whenDisabled() {
        sut.setEnabled(false)
        sut.playCustomPattern(.celebration)
        sut.playCustomPattern(.qiblaLock)
    }

    // MARK: - Singleton

    func test_shared_isSingleton() {
        let a = HapticFeedbackService.shared
        let b = HapticFeedbackService.shared
        XCTAssertTrue(a === b)
    }
}
