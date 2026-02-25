// MARK: - SupportPromptServiceTests.swift
// PURPOSE: Tests for SupportPromptService session-based frequency, opt-out, subscription guard, and entitlements guard

import XCTest
@testable import Safa

final class SupportPromptServiceTests: XCTestCase {
    private var defaults: UserDefaults!

    override func setUp() {
        super.setUp()
        defaults = UserDefaults(suiteName: "SupportPromptServiceTests")!
        SupportPromptService.resetForTesting(defaults: defaults)
    }

    override func tearDown() {
        SupportPromptService.resetForTesting(defaults: defaults)
        defaults.removePersistentDomain(forName: "SupportPromptServiceTests")
        defaults = nil
        super.tearDown()
    }

    // MARK: - Guard Tests

    func test_entitlementsNotInitialized_returnsFalse() {
        setSessions(5)
        XCTAssertFalse(
            SupportPromptService.shouldShowPrompt(
                hasActiveSubscription: false,
                entitlementsInitialized: false,
                defaults: defaults
            ),
            "Should not prompt before entitlements are initialized"
        )
    }

    func test_activeSubscription_returnsFalse() {
        setSessions(3) // Eligible session
        XCTAssertFalse(
            SupportPromptService.shouldShowPrompt(
                hasActiveSubscription: true,
                entitlementsInitialized: true,
                defaults: defaults
            ),
            "Active subscriber should never see support prompt"
        )
    }

    func test_optedOut_returnsFalse() {
        setSessions(3) // Eligible session
        SupportPromptService.optOut(defaults: defaults)
        XCTAssertFalse(
            shouldShow(),
            "Opted-out user should never see prompt"
        )
    }

    // MARK: - Session-Based Frequency Tests

    func test_gracePeriod_sessions0to2_hidden() {
        for session in 0..<SupportPromptService.initialGraceSessions {
            setSessions(session)
            XCTAssertFalse(
                shouldShow(),
                "Session \(session) is within grace period, should not show"
            )
        }
    }

    func test_session3_firstEligible_visible() {
        setSessions(3) // initialGraceSessions = 3
        XCTAssertTrue(
            shouldShow(),
            "Session 3 is first eligible session (grace period ends)"
        )
    }

    func test_sessions4to12_hidden() {
        for session in 4...12 {
            setSessions(session)
            XCTAssertFalse(
                shouldShow(),
                "Session \(session) should not show (not on interval boundary)"
            )
        }
    }

    func test_session13_nextInterval_visible() {
        setSessions(13) // (13 - 3) % 10 == 0
        XCTAssertTrue(
            shouldShow(),
            "Session 13 should be visible (next interval after session 3)"
        )
    }

    func test_session23_thirdInterval_visible() {
        setSessions(23) // (23 - 3) % 10 == 0
        XCTAssertTrue(
            shouldShow(),
            "Session 23 should be visible (third interval)"
        )
    }

    // MARK: - recordSessionStart Tests

    func test_recordSessionStart_incrementsCounter() {
        SupportPromptService.resetForTesting(defaults: defaults) // Resets didRecordThisProcess
        XCTAssertEqual(defaults.integer(forKey: AppConstants.StorageKeys.supportSessionCount), 0)

        SupportPromptService.recordSessionStart(defaults: defaults)
        XCTAssertEqual(defaults.integer(forKey: AppConstants.StorageKeys.supportSessionCount), 1)
    }

    func test_recordSessionStart_idempotentPerProcess() {
        SupportPromptService.resetForTesting(defaults: defaults)

        SupportPromptService.recordSessionStart(defaults: defaults)
        SupportPromptService.recordSessionStart(defaults: defaults)
        SupportPromptService.recordSessionStart(defaults: defaults)

        XCTAssertEqual(
            defaults.integer(forKey: AppConstants.StorageKeys.supportSessionCount), 1,
            "recordSessionStart should only increment once per process"
        )
    }

    // MARK: - Behavioral Tests

    func test_optOut_preventsAllSubsequentPrompts() {
        setSessions(3) // Eligible
        XCTAssertTrue(shouldShow())

        SupportPromptService.optOut(defaults: defaults)

        // Not eligible anymore, even on eligible sessions
        XCTAssertFalse(shouldShow(), "After opt-out, prompt should never show")

        setSessions(13)
        XCTAssertFalse(shouldShow(), "After opt-out, prompt should never show on any session")
    }

    func test_subscriberNeverSeesPrompt_evenOnEligibleSession() {
        setSessions(3)
        XCTAssertFalse(
            SupportPromptService.shouldShowPrompt(
                hasActiveSubscription: true,
                entitlementsInitialized: true,
                defaults: defaults
            ),
            "Active subscriber should never see prompt regardless of session count"
        )
    }

    // MARK: - Helpers

    private func setSessions(_ count: Int) {
        defaults.set(count, forKey: AppConstants.StorageKeys.supportSessionCount)
    }

    private func shouldShow() -> Bool {
        SupportPromptService.shouldShowPrompt(
            hasActiveSubscription: false,
            entitlementsInitialized: true,
            defaults: defaults
        )
    }
}
