// MARK: - StreakTests.swift
// PURPOSE: Correctness tests for Streak computed properties
// DEPENDENCIES: XCTest, Safa

import XCTest
@testable import Safa

final class StreakTests: XCTestCase {

    // MARK: - isActiveToday Correctness Tests

    func testStreakIsActiveTodayWithTodayActivity() {
        let streak = Streak(
            type: .daily,
            currentCount: 5,
            longestCount: 10,
            lastActivityDate: Date()
        )

        XCTAssertTrue(streak.isActiveToday)
    }

    func testStreakIsActiveTodayWithYesterdayActivity() {
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let streak = Streak(
            type: .daily,
            currentCount: 5,
            longestCount: 10,
            lastActivityDate: yesterday
        )

        XCTAssertFalse(streak.isActiveToday)
    }

    func testStreakIsActiveTodayWithNoActivity() {
        let streak = Streak(type: .daily)

        XCTAssertFalse(streak.isActiveToday)
    }
}
