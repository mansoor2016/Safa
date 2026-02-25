// MARK: - SubscriptionServiceTests.swift
// PURPOSE: Tests for SubscriptionService entitlement side-effect logic

import XCTest
@testable import Safa

final class SubscriptionServiceTests: XCTestCase {

    // MARK: - Thank-You Toast

    func test_newSubscription_afterInitialization_showsThankYouToast() {
        let result = SubscriptionService.resolveEntitlementEffects(
            foundActive: true, wasActive: false, wasInitialized: true
        )
        XCTAssertTrue(result.showThankYouToast,
                      "Should show thank-you toast when subscription is newly activated")
        XCTAssertFalse(result.shouldRevertIcon)
    }

    func test_newSubscription_duringInitialization_doesNotShowToast() {
        let result = SubscriptionService.resolveEntitlementEffects(
            foundActive: true, wasActive: false, wasInitialized: false
        )
        XCTAssertFalse(result.showThankYouToast,
                       "Should not toast on initial launch — user already knows they subscribed")
    }

    func test_alreadySubscribed_doesNotShowToast() {
        let result = SubscriptionService.resolveEntitlementEffects(
            foundActive: true, wasActive: true, wasInitialized: true
        )
        XCTAssertFalse(result.showThankYouToast,
                       "Should not toast every entitlement check — only on transition")
    }

    // MARK: - Icon Revert

    func test_subscriptionLapsed_shouldRevertIcon() {
        let result = SubscriptionService.resolveEntitlementEffects(
            foundActive: false, wasActive: true, wasInitialized: true
        )
        XCTAssertTrue(result.shouldRevertIcon,
                      "Should revert icon when subscription transitions from active to inactive")
        XCTAssertFalse(result.showThankYouToast)
    }

    func test_neverSubscribed_doesNotRevertIcon() {
        let result = SubscriptionService.resolveEntitlementEffects(
            foundActive: false, wasActive: false, wasInitialized: true
        )
        XCTAssertFalse(result.shouldRevertIcon,
                       "Should not revert icon if user was never subscribed")
    }

    func test_stillSubscribed_doesNotRevertIcon() {
        let result = SubscriptionService.resolveEntitlementEffects(
            foundActive: true, wasActive: true, wasInitialized: true
        )
        XCTAssertFalse(result.shouldRevertIcon)
    }

    // MARK: - Edge Cases

    func test_lapsedDuringInitialization_stillRevertsIcon() {
        // Unlikely but defensive: wasActive=true, wasInitialized=false
        // This can't happen in practice (wasActive implies prior initialization),
        // but the function should still revert the icon.
        let result = SubscriptionService.resolveEntitlementEffects(
            foundActive: false, wasActive: true, wasInitialized: false
        )
        XCTAssertTrue(result.shouldRevertIcon)
        XCTAssertFalse(result.showThankYouToast)
    }

    func test_noSubscription_noHistory_noEffects() {
        let result = SubscriptionService.resolveEntitlementEffects(
            foundActive: false, wasActive: false, wasInitialized: false
        )
        XCTAssertFalse(result.showThankYouToast)
        XCTAssertFalse(result.shouldRevertIcon)
    }

    // MARK: - Product IDs

    func test_productIDs_containsMonthlyAndAnnual() {
        XCTAssertTrue(SubscriptionService.productIDs.contains("com.safa.support.monthly"))
        XCTAssertTrue(SubscriptionService.productIDs.contains("com.safa.support.annual"))
        XCTAssertEqual(SubscriptionService.productIDs.count, 2)
    }
}
