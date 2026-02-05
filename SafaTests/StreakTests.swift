// MARK: - StreakTests.swift
// PURPOSE: Unit tests for Streak functionality
// DEPENDENCIES: XCTest

import XCTest
@testable import Safa

final class StreakTests: XCTestCase {

    // MARK: - Streak Type Tests

    func testStreakTypeRawValues() {
        XCTAssertEqual(StreakType.daily.rawValue, "daily")
        XCTAssertEqual(StreakType.prayer.rawValue, "prayer")
        XCTAssertEqual(StreakType.quran.rawValue, "quran")
        XCTAssertEqual(StreakType.dhikr.rawValue, "dhikr")
        XCTAssertEqual(StreakType.learning.rawValue, "learning")
    }

    func testStreakTypeDisplayNames() {
        XCTAssertEqual(StreakType.daily.displayName, "Daily")
        XCTAssertEqual(StreakType.prayer.displayName, "Prayer")
        XCTAssertEqual(StreakType.quran.displayName, "Quran")
    }

    func testStreakTypeIcons() {
        XCTAssertEqual(StreakType.daily.iconName, "flame")
        XCTAssertEqual(StreakType.prayer.iconName, "moon.stars")
        XCTAssertEqual(StreakType.quran.iconName, "book")
    }

    func testStreakTypeDescriptions() {
        XCTAssertFalse(StreakType.daily.description.isEmpty)
        XCTAssertFalse(StreakType.prayer.description.isEmpty)
    }

    // MARK: - Streak Initialization Tests

    func testStreakInitialization() {
        let streak = Streak(type: .daily)

        XCTAssertEqual(streak.type, .daily)
        XCTAssertEqual(streak.currentCount, 0)
        XCTAssertEqual(streak.longestCount, 0)
        XCTAssertNil(streak.lastActivityDate)
    }

    func testStreakWithValues() {
        let streak = Streak(
            type: .prayer,
            currentCount: 7,
            longestCount: 14,
            lastActivityDate: Date()
        )

        XCTAssertEqual(streak.type, .prayer)
        XCTAssertEqual(streak.currentCount, 7)
        XCTAssertEqual(streak.longestCount, 14)
        XCTAssertNotNil(streak.lastActivityDate)
    }

    // MARK: - Streak Active Today Tests

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

    // MARK: - Streak Equality Tests

    func testStreakEquality() {
        let id = UUID()
        let streak1 = Streak(id: id, type: .daily, currentCount: 5)
        let streak2 = Streak(id: id, type: .daily, currentCount: 5)

        XCTAssertEqual(streak1, streak2)
    }

    // MARK: - Encoding/Decoding Tests

    func testStreakCodable() throws {
        let original = Streak(
            type: .quran,
            currentCount: 10,
            longestCount: 20,
            lastActivityDate: Date()
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(Streak.self, from: data)

        XCTAssertEqual(original.id, decoded.id)
        XCTAssertEqual(original.type, decoded.type)
        XCTAssertEqual(original.currentCount, decoded.currentCount)
        XCTAssertEqual(original.longestCount, decoded.longestCount)
    }

    // MARK: - All Cases Tests

    func testStreakTypeAllCases() {
        let allCases = StreakType.allCases

        XCTAssertEqual(allCases.count, 5)
        XCTAssertTrue(allCases.contains(.daily))
        XCTAssertTrue(allCases.contains(.prayer))
        XCTAssertTrue(allCases.contains(.quran))
        XCTAssertTrue(allCases.contains(.dhikr))
        XCTAssertTrue(allCases.contains(.learning))
    }

    // MARK: - Longest Count Update Tests

    func testStreakLongestCountUpdate() {
        var streak = Streak(type: .daily, currentCount: 5, longestCount: 5)

        // Simulate updating current count
        streak.currentCount = 10

        // Verify longest should be updated separately in business logic
        XCTAssertEqual(streak.currentCount, 10)
        XCTAssertEqual(streak.longestCount, 5) // Longest isn't auto-updated
    }
}
