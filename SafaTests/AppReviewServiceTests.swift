// MARK: - AppReviewServiceTests.swift
// PURPOSE: Tests for AppReviewService exponential backoff, opt-out, and state management

import XCTest
@testable import Safa

final class AppReviewServiceTests: XCTestCase {
    private var defaults: UserDefaults!

    override func setUp() {
        super.setUp()
        defaults = UserDefaults(suiteName: "AppReviewServiceTests")!
        AppReviewService.resetForTesting(defaults: defaults)
    }

    override func tearDown() {
        AppReviewService.resetForTesting(defaults: defaults)
        defaults.removePersistentDomain(forName: "AppReviewServiceTests")
        defaults = nil
        super.tearDown()
    }

    // MARK: - Timing Tests

    func test_freshInstall_noTimeElapsed_returnsFalse() {
        let now = Date()
        defaults.set(now, forKey: AppConstants.StorageKeys.reviewFirstLaunchDate)

        XCTAssertFalse(
            AppReviewService.shouldShowPrompt(now: now, defaults: defaults),
            "Should not prompt immediately after install"
        )
    }

    func test_14MinutesElapsed_returnsFalse() {
        let now = Date()
        let firstLaunch = now.addingTimeInterval(-14 * 60)
        defaults.set(firstLaunch, forKey: AppConstants.StorageKeys.reviewFirstLaunchDate)

        XCTAssertFalse(
            AppReviewService.shouldShowPrompt(now: now, defaults: defaults),
            "Should not prompt at 14 minutes (threshold is 15)"
        )
    }

    func test_15MinutesElapsed_returnsTrue() {
        let now = Date()
        let firstLaunch = now.addingTimeInterval(-15 * 60)
        defaults.set(firstLaunch, forKey: AppConstants.StorageKeys.reviewFirstLaunchDate)

        XCTAssertTrue(
            AppReviewService.shouldShowPrompt(now: now, defaults: defaults),
            "Should prompt at exactly 15 minutes"
        )
    }

    func test_afterFirstPrompt_30MinSincePrompt_returnsFalse() {
        let now = Date()
        let firstLaunch = now.addingTimeInterval(-2 * 3600) // 2 hours ago
        defaults.set(firstLaunch, forKey: AppConstants.StorageKeys.reviewFirstLaunchDate)
        defaults.set(1, forKey: AppConstants.StorageKeys.reviewPromptCount)
        // Last prompt 30 min ago, but need 1 hour (15min * 4^1 = 60min)
        defaults.set(now.addingTimeInterval(-30 * 60), forKey: AppConstants.StorageKeys.reviewLastPromptDate)

        XCTAssertFalse(
            AppReviewService.shouldShowPrompt(now: now, defaults: defaults),
            "After 1st prompt, need 60 min between prompts (30 min is too soon)"
        )
    }

    func test_afterFirstPrompt_60MinSincePrompt_returnsTrue() {
        let now = Date()
        let firstLaunch = now.addingTimeInterval(-2 * 3600) // 2 hours ago
        defaults.set(firstLaunch, forKey: AppConstants.StorageKeys.reviewFirstLaunchDate)
        defaults.set(1, forKey: AppConstants.StorageKeys.reviewPromptCount)
        defaults.set(now.addingTimeInterval(-60 * 60), forKey: AppConstants.StorageKeys.reviewLastPromptDate)

        XCTAssertTrue(
            AppReviewService.shouldShowPrompt(now: now, defaults: defaults),
            "After 1st prompt, 60 min since last prompt should be eligible"
        )
    }

    func test_afterSecondPrompt_3HoursSincePrompt_returnsFalse() {
        let now = Date()
        let firstLaunch = now.addingTimeInterval(-24 * 3600) // 24 hours ago
        defaults.set(firstLaunch, forKey: AppConstants.StorageKeys.reviewFirstLaunchDate)
        defaults.set(2, forKey: AppConstants.StorageKeys.reviewPromptCount)
        // Need 4 hours (15min * 4^2 = 240min = 4hr)
        defaults.set(now.addingTimeInterval(-3 * 3600), forKey: AppConstants.StorageKeys.reviewLastPromptDate)

        XCTAssertFalse(
            AppReviewService.shouldShowPrompt(now: now, defaults: defaults),
            "After 2nd prompt, need 4 hours (3 hours is too soon)"
        )
    }

    func test_afterSecondPrompt_4HoursSincePrompt_returnsTrue() {
        let now = Date()
        let firstLaunch = now.addingTimeInterval(-24 * 3600)
        defaults.set(firstLaunch, forKey: AppConstants.StorageKeys.reviewFirstLaunchDate)
        defaults.set(2, forKey: AppConstants.StorageKeys.reviewPromptCount)
        defaults.set(now.addingTimeInterval(-4 * 3600), forKey: AppConstants.StorageKeys.reviewLastPromptDate)

        XCTAssertTrue(
            AppReviewService.shouldShowPrompt(now: now, defaults: defaults),
            "After 2nd prompt, 4 hours since last prompt should be eligible"
        )
    }

    func test_intervalFormula_count3_is16Hours() {
        // 15min * 4^3 = 15 * 64 = 960 min = 16 hours
        let now = Date()
        let firstLaunch = now.addingTimeInterval(-30 * 3600) // well past threshold
        defaults.set(firstLaunch, forKey: AppConstants.StorageKeys.reviewFirstLaunchDate)
        defaults.set(3, forKey: AppConstants.StorageKeys.reviewPromptCount)
        defaults.set(now.addingTimeInterval(-15 * 3600), forKey: AppConstants.StorageKeys.reviewLastPromptDate)

        XCTAssertFalse(
            AppReviewService.shouldShowPrompt(now: now, defaults: defaults),
            "Count 3 requires 16 hours; 15 hours is not enough"
        )

        defaults.set(now.addingTimeInterval(-16 * 3600), forKey: AppConstants.StorageKeys.reviewLastPromptDate)
        XCTAssertTrue(
            AppReviewService.shouldShowPrompt(now: now, defaults: defaults),
            "Count 3 at exactly 16 hours should be eligible"
        )
    }

    func test_intervalFormula_count4_is2point7Days() {
        // 15min * 4^4 = 15 * 256 = 3840 min = 64 hours ≈ 2.67 days
        let requiredSeconds: TimeInterval = 3840 * 60
        let now = Date()
        let firstLaunch = now.addingTimeInterval(-10 * 24 * 3600)
        defaults.set(firstLaunch, forKey: AppConstants.StorageKeys.reviewFirstLaunchDate)
        defaults.set(4, forKey: AppConstants.StorageKeys.reviewPromptCount)
        defaults.set(now.addingTimeInterval(-requiredSeconds + 60), forKey: AppConstants.StorageKeys.reviewLastPromptDate)

        XCTAssertFalse(
            AppReviewService.shouldShowPrompt(now: now, defaults: defaults),
            "Count 4 requires ~2.67 days; 1 minute short should not show"
        )

        defaults.set(now.addingTimeInterval(-requiredSeconds), forKey: AppConstants.StorageKeys.reviewLastPromptDate)
        XCTAssertTrue(
            AppReviewService.shouldShowPrompt(now: now, defaults: defaults),
            "Count 4 at exactly the threshold should be eligible"
        )
    }

    func test_intervalFormula_count5_is10point7Days() {
        // 15min * 4^5 = 15 * 1024 = 15360 min = 256 hours ≈ 10.67 days
        let requiredSeconds: TimeInterval = 15360 * 60
        let now = Date()
        let firstLaunch = now.addingTimeInterval(-30 * 24 * 3600)
        defaults.set(firstLaunch, forKey: AppConstants.StorageKeys.reviewFirstLaunchDate)
        defaults.set(5, forKey: AppConstants.StorageKeys.reviewPromptCount)
        defaults.set(now.addingTimeInterval(-requiredSeconds), forKey: AppConstants.StorageKeys.reviewLastPromptDate)

        XCTAssertTrue(
            AppReviewService.shouldShowPrompt(now: now, defaults: defaults),
            "Count 5 at the threshold should be eligible"
        )
    }

    // MARK: - Opt-Out Tests

    func test_optedOut_alwaysReturnsFalse() {
        let now = Date()
        let firstLaunch = now.addingTimeInterval(-24 * 3600)
        defaults.set(firstLaunch, forKey: AppConstants.StorageKeys.reviewFirstLaunchDate)
        AppReviewService.optOut(defaults: defaults)

        XCTAssertFalse(
            AppReviewService.shouldShowPrompt(now: now, defaults: defaults),
            "Opted-out user should never see prompt"
        )
    }

    func test_notOptedOut_eligible_returnsTrue() {
        let now = Date()
        let firstLaunch = now.addingTimeInterval(-20 * 60)
        defaults.set(firstLaunch, forKey: AppConstants.StorageKeys.reviewFirstLaunchDate)

        XCTAssertTrue(
            AppReviewService.shouldShowPrompt(now: now, defaults: defaults),
            "Non-opted-out user past threshold should see prompt"
        )
    }

    func test_optOut_preventsSubsequentPrompts() {
        let now = Date()
        let firstLaunch = now.addingTimeInterval(-20 * 60)
        defaults.set(firstLaunch, forKey: AppConstants.StorageKeys.reviewFirstLaunchDate)

        // First check: eligible
        XCTAssertTrue(AppReviewService.shouldShowPrompt(now: now, defaults: defaults))

        // User opts out
        AppReviewService.optOut(defaults: defaults)

        // Now ineligible
        XCTAssertFalse(
            AppReviewService.shouldShowPrompt(now: now, defaults: defaults),
            "After opt-out, prompt should not show"
        )
    }

    func test_promptCount_persistsAcrossCalls() {
        XCTAssertEqual(AppReviewService.promptCount(defaults: defaults), 0)

        AppReviewService.recordPromptShown(defaults: defaults)
        XCTAssertEqual(AppReviewService.promptCount(defaults: defaults), 1)

        AppReviewService.recordPromptShown(defaults: defaults)
        XCTAssertEqual(AppReviewService.promptCount(defaults: defaults), 2)
    }

    // MARK: - State Tests

    func test_recordFirstLaunchIfNeeded_onlySetsOnce() {
        let before = Date()
        AppReviewService.recordFirstLaunchIfNeeded(defaults: defaults)
        let firstDate = defaults.object(forKey: AppConstants.StorageKeys.reviewFirstLaunchDate) as? Date

        XCTAssertNotNil(firstDate)
        XCTAssertTrue(firstDate! >= before)

        // Wait briefly and call again — should not overwrite
        let savedDate = firstDate!
        AppReviewService.recordFirstLaunchIfNeeded(defaults: defaults)
        let secondDate = defaults.object(forKey: AppConstants.StorageKeys.reviewFirstLaunchDate) as? Date

        XCTAssertEqual(savedDate, secondDate, "recordFirstLaunchIfNeeded should not overwrite existing date")
    }

    func test_recordPromptShown_incrementsCountAndSetsDate() {
        let now = Date()
        AppReviewService.recordPromptShown(now: now, defaults: defaults)

        XCTAssertEqual(defaults.integer(forKey: AppConstants.StorageKeys.reviewPromptCount), 1)
        let lastPrompt = defaults.object(forKey: AppConstants.StorageKeys.reviewLastPromptDate) as? Date
        XCTAssertEqual(lastPrompt, now)
    }

    func test_noFirstLaunchDate_returnsFalse() {
        let now = Date()
        // Don't set firstLaunchDate
        XCTAssertFalse(
            AppReviewService.shouldShowPrompt(now: now, defaults: defaults),
            "Without firstLaunchDate, should not show prompt"
        )
    }

    // MARK: - Boundary Tests

    func test_exactlyAtThreshold_returnsTrue() {
        let now = Date()
        let firstLaunch = now.addingTimeInterval(-AppReviewService.baseInterval) // exactly 15 min
        defaults.set(firstLaunch, forKey: AppConstants.StorageKeys.reviewFirstLaunchDate)

        XCTAssertTrue(
            AppReviewService.shouldShowPrompt(now: now, defaults: defaults),
            "Exactly at 15 minute threshold should be eligible"
        )
    }

    func test_largePromptCount_stillComputable() {
        // Count 10: 15min * 4^10 = 15 * 1048576 ≈ 29.8 years — should not overflow
        let now = Date()
        let firstLaunch = now.addingTimeInterval(-1)
        defaults.set(firstLaunch, forKey: AppConstants.StorageKeys.reviewFirstLaunchDate)
        defaults.set(10, forKey: AppConstants.StorageKeys.reviewPromptCount)

        // Should not crash, and should return false (interval is ~30 years)
        XCTAssertFalse(
            AppReviewService.shouldShowPrompt(now: now, defaults: defaults),
            "Large prompt count should compute without overflow and return false"
        )
    }

    func test_lastPromptDateInFuture_returnsFalse() {
        let now = Date()
        let firstLaunch = now.addingTimeInterval(-24 * 3600)
        defaults.set(firstLaunch, forKey: AppConstants.StorageKeys.reviewFirstLaunchDate)
        // Last prompt date is in the future (clock skew)
        defaults.set(now.addingTimeInterval(3600), forKey: AppConstants.StorageKeys.reviewLastPromptDate)

        XCTAssertFalse(
            AppReviewService.shouldShowPrompt(now: now, defaults: defaults),
            "Future lastPromptDate (clock skew) should return false"
        )
    }

    func test_resetForTesting_clearsAllState() {
        defaults.set(Date(), forKey: AppConstants.StorageKeys.reviewFirstLaunchDate)
        defaults.set(3, forKey: AppConstants.StorageKeys.reviewPromptCount)
        defaults.set(true, forKey: AppConstants.StorageKeys.reviewOptedOut)
        defaults.set(Date(), forKey: AppConstants.StorageKeys.reviewLastPromptDate)

        AppReviewService.resetForTesting(defaults: defaults)

        XCTAssertNil(defaults.object(forKey: AppConstants.StorageKeys.reviewFirstLaunchDate))
        XCTAssertEqual(defaults.integer(forKey: AppConstants.StorageKeys.reviewPromptCount), 0)
        XCTAssertFalse(defaults.bool(forKey: AppConstants.StorageKeys.reviewOptedOut))
        XCTAssertNil(defaults.object(forKey: AppConstants.StorageKeys.reviewLastPromptDate))
    }

    // MARK: - Integration-Style Tests

    func test_fullLifecycle_firstThroughThirdPrompt() {
        let installDate = Date(timeIntervalSince1970: 1_000_000)
        defaults.set(installDate, forKey: AppConstants.StorageKeys.reviewFirstLaunchDate)

        // T+0: Not eligible
        XCTAssertFalse(AppReviewService.shouldShowPrompt(now: installDate, defaults: defaults))

        // T+15min: First prompt eligible
        let t1 = installDate.addingTimeInterval(15 * 60)
        XCTAssertTrue(AppReviewService.shouldShowPrompt(now: t1, defaults: defaults))
        AppReviewService.recordPromptShown(now: t1, defaults: defaults)

        // T+30min: Not eligible yet (need 60min since last prompt)
        let t2 = installDate.addingTimeInterval(30 * 60)
        XCTAssertFalse(AppReviewService.shouldShowPrompt(now: t2, defaults: defaults))

        // T+75min (60min after first prompt): Second prompt eligible
        let t3 = t1.addingTimeInterval(60 * 60)
        XCTAssertTrue(AppReviewService.shouldShowPrompt(now: t3, defaults: defaults))
        AppReviewService.recordPromptShown(now: t3, defaults: defaults)

        // T+3hr after second prompt: Not yet (need 4hr)
        let t4 = t3.addingTimeInterval(3 * 3600)
        XCTAssertFalse(AppReviewService.shouldShowPrompt(now: t4, defaults: defaults))

        // T+4hr after second prompt: Third prompt eligible
        let t5 = t3.addingTimeInterval(4 * 3600)
        XCTAssertTrue(AppReviewService.shouldShowPrompt(now: t5, defaults: defaults))
    }
}
