// MARK: - HasanatUseCaseTests.swift
// PURPOSE: Unit tests for Hasanat calculation use case
// DEPENDENCIES: XCTest

import XCTest
@testable import Safa

final class HasanatUseCaseTests: XCTestCase {

    var sut: CalculateHasanatUseCase!

    override func setUp() {
        super.setUp()
        sut = CalculateHasanatUseCase()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - Prayer Points Tests

    func testPrayerLoggedPoints() {
        let points = sut.calculatePoints(for: .prayerLogged(.fajr))
        XCTAssertEqual(points, 10, "Prayer logged should award 10 points")
    }

    func testAllFivePrayersPoints() {
        let points = sut.calculatePoints(for: .allFivePrayersLogged)
        XCTAssertEqual(points, 25, "All five prayers should award 25 points")
    }

    func testPrayerOnTimeBonus() {
        let points = sut.calculatePoints(for: .prayerOnTime)
        XCTAssertEqual(points, 5, "Prayer on time bonus should be 5 points")
    }

    func testTahajjudPoints() {
        let points = sut.calculatePoints(for: .tahajjudPrayer)
        XCTAssertEqual(points, 30, "Tahajjud should award 30 points")
    }

    func testFridayPrayerPoints() {
        let points = sut.calculatePoints(for: .fridayPrayer)
        XCTAssertEqual(points, 20, "Friday prayer should award 20 points")
    }

    // MARK: - Quran Points Tests

    func testQuranPagePoints() {
        let points = sut.calculatePoints(for: .quranPageRead)
        XCTAssertEqual(points, 5, "Quran page should award 5 points")
    }

    func testQuranSurahCompletedFatiha() {
        let points = sut.calculatePoints(for: .quranSurahCompleted(surahNumber: 1))
        XCTAssertEqual(points, 20, "Al-Fatiha should award 20 points (15 base + 5 special)")
    }

    func testQuranSurahCompletedBaqarah() {
        let points = sut.calculatePoints(for: .quranSurahCompleted(surahNumber: 2))
        XCTAssertEqual(points, 75, "Al-Baqarah should award 75 points (15 × 5)")
    }

    func testQuranJuzPoints() {
        let points = sut.calculatePoints(for: .quranJuzCompleted)
        XCTAssertEqual(points, 50, "Juz completion should award 50 points")
    }

    func testQuranKhatmPoints() {
        let points = sut.calculatePoints(for: .quranKhatm)
        XCTAssertEqual(points, 500, "Quran completion should award 500 points")
    }

    // MARK: - Learning Points Tests

    func testLessonCompletedPoints() {
        let points = sut.calculatePoints(for: .lessonCompleted)
        XCTAssertEqual(points, 10, "Lesson completion should award 10 points")
    }

    func testTrackCompletedPoints() {
        let points = sut.calculatePoints(for: .trackCompleted)
        XCTAssertEqual(points, 100, "Track completion should award 100 points")
    }

    func testPerfectPronunciationPoints() {
        let points = sut.calculatePoints(for: .perfectPronunciation)
        XCTAssertEqual(points, 5, "Perfect pronunciation should award 5 points")
    }

    // MARK: - Dhikr Points Tests

    func testMorningAdhkarPoints() {
        let points = sut.calculatePoints(for: .morningAdhkarCompleted)
        XCTAssertEqual(points, 15, "Morning adhkar should award 15 points")
    }

    func testEveningAdhkarPoints() {
        let points = sut.calculatePoints(for: .eveningAdhkarCompleted)
        XCTAssertEqual(points, 15, "Evening adhkar should award 15 points")
    }

    func testTasbeehUnder33() {
        let points = sut.calculatePoints(for: .tasbeeh(count: 20))
        XCTAssertEqual(points, 2, "20 tasbeeh should award 2 points (1 per 10)")
    }

    func testTasbeeh33() {
        let points = sut.calculatePoints(for: .tasbeeh(count: 33))
        XCTAssertEqual(points, 10, "33 tasbeeh should award 10 points")
    }

    func testTasbeeh100() {
        let points = sut.calculatePoints(for: .tasbeeh(count: 100))
        XCTAssertEqual(points, 20, "100 tasbeeh should award 20 points")
    }

    func testDuaRecitedPoints() {
        let points = sut.calculatePoints(for: .duaRecited)
        XCTAssertEqual(points, 5, "Dua recited should award 5 points")
    }

    // MARK: - Social Points Tests

    func testInviteFriendPoints() {
        let points = sut.calculatePoints(for: .invitedFriend)
        XCTAssertEqual(points, 10, "Inviting friend should award 10 points")
    }

    func testFriendJoinedPoints() {
        let points = sut.calculatePoints(for: .friendJoined)
        XCTAssertEqual(points, 25, "Friend joining should award 25 points")
    }

    func testShareVersePoints() {
        let points = sut.calculatePoints(for: .sharedVerse)
        XCTAssertEqual(points, 5, "Sharing verse should award 5 points")
    }

    // MARK: - Streak Points Tests

    func testStreakMilestone7() {
        let points = sut.calculatePoints(for: .streakMilestone(days: 7))
        XCTAssertEqual(points, 50, "7-day streak milestone should award 50 points")
    }

    func testStreakMilestone30() {
        let points = sut.calculatePoints(for: .streakMilestone(days: 30))
        XCTAssertEqual(points, 150, "30-day streak milestone should award 150 points")
    }

    func testStreakMilestone100() {
        let points = sut.calculatePoints(for: .streakMilestone(days: 100))
        XCTAssertEqual(points, 500, "100-day streak milestone should award 500 points")
    }

    func testPerfectWeekPoints() {
        let points = sut.calculatePoints(for: .perfectWeek)
        XCTAssertEqual(points, 100, "Perfect week should award 100 points")
    }

    func testPerfectMonthPoints() {
        let points = sut.calculatePoints(for: .perfectMonth)
        XCTAssertEqual(points, 300, "Perfect month should award 300 points")
    }

    // MARK: - First Time Action Tests

    func testFirstTimeActionPoints() {
        let points = sut.calculatePoints(for: .firstTimeAction(action: "prayer"))
        XCTAssertEqual(points, 20, "First time actions should award 20 points")
    }

    // MARK: - Multiplier Tests

    func testRamadanMultiplier() {
        // Note: This test depends on current date being Ramadan
        // In production, you'd mock the date
        let basePoints = sut.calculatePoints(for: .prayerLogged(.fajr))
        let ramadanPoints = sut.calculateWithMultipliers(for: .prayerLogged(.fajr), isRamadan: true, isFriday: false)

        XCTAssertEqual(ramadanPoints, basePoints * 2, "Ramadan should double the points")
    }

    func testFridayMultiplier() {
        let basePoints = sut.calculatePoints(for: .quranPageRead)
        let fridayPoints = sut.calculateWithMultipliers(for: .quranPageRead, isRamadan: false, isFriday: true)

        XCTAssertEqual(fridayPoints, Int(Double(basePoints) * 1.5), "Friday should multiply points by 1.5")
    }

    func testNonFridayBonusAction() {
        // Lesson completion shouldn't get Friday bonus
        let basePoints = sut.calculatePoints(for: .lessonCompleted)
        let fridayPoints = sut.calculateWithMultipliers(for: .lessonCompleted, isRamadan: false, isFriday: true)

        XCTAssertEqual(fridayPoints, basePoints, "Non-eligible actions shouldn't get Friday bonus")
    }

    func testRamadanTakesPrecedence() {
        // When both Ramadan and Friday, Ramadan's 2x should be used (higher)
        let basePoints = sut.calculatePoints(for: .prayerLogged(.fajr))
        let bothPoints = sut.calculateWithMultipliers(for: .prayerLogged(.fajr), isRamadan: true, isFriday: true)

        XCTAssertEqual(bothPoints, basePoints * 2, "Ramadan 2x should take precedence over Friday 1.5x")
    }
}
