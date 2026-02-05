// MARK: - AchievementUseCaseTests.swift
// PURPOSE: Unit tests for Achievement checking use case
// DEPENDENCIES: XCTest

import XCTest
@testable import Safa

final class AchievementUseCaseTests: XCTestCase {

    var sut: CheckAchievementsUseCase!

    override func setUp() {
        super.setUp()
        sut = CheckAchievementsUseCase()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - Initial State Tests

    func testInitiallyNoUnlockedAchievements() {
        let unlocked = sut.getUnlockedAchievements()
        XCTAssertTrue(unlocked.isEmpty, "No achievements should be unlocked initially")
    }

    func testAllAchievementsAreLocked() {
        let locked = sut.getLockedAchievements()
        XCTAssertFalse(locked.isEmpty, "All achievements should be locked initially")
    }

    // MARK: - Prayer Achievement Tests

    func testFirstPrayerAchievementUnlocks() {
        let stats = UserStats(
            totalHasanat: 10,
            currentLevel: 1,
            unlockedAchievements: [],
            lessonsCompleted: 0,
            totalPrayersLogged: 1,
            totalAyahsRead: 0,
            totalTasbeehCount: 0,
            streakFreezes: 0
        )

        let results = sut.checkAllAchievements(with: stats)
        let firstPrayerResult = results.first { $0.achievement.id == "first_prayer" }

        XCTAssertNotNil(firstPrayerResult)
        XCTAssertEqual(firstPrayerResult?.progress, 1.0)
    }

    func testPrayers100AchievementProgress() {
        let stats = UserStats(
            totalHasanat: 500,
            currentLevel: 3,
            unlockedAchievements: [],
            lessonsCompleted: 0,
            totalPrayersLogged: 50,
            totalAyahsRead: 0,
            totalTasbeehCount: 0,
            streakFreezes: 0
        )

        let progress = sut.getProgress(for: "prayers_logged_100", with: stats)
        XCTAssertEqual(progress, 0.5, "50/100 prayers should be 50% progress")
    }

    func testPrayers100AchievementUnlocks() {
        let stats = UserStats(
            totalHasanat: 1000,
            currentLevel: 5,
            unlockedAchievements: [],
            lessonsCompleted: 0,
            totalPrayersLogged: 100,
            totalAyahsRead: 0,
            totalTasbeehCount: 0,
            streakFreezes: 0
        )

        let results = sut.checkAllAchievements(with: stats)
        let result = results.first { $0.achievement.id == "prayers_logged_100" }

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.progress, 1.0)
    }

    // MARK: - Learning Achievement Tests

    func testFirstLessonAchievementUnlocks() {
        let stats = UserStats(
            totalHasanat: 10,
            currentLevel: 1,
            unlockedAchievements: [],
            lessonsCompleted: 1,
            totalPrayersLogged: 0,
            totalAyahsRead: 0,
            totalTasbeehCount: 0,
            streakFreezes: 0
        )

        let results = sut.checkAllAchievements(with: stats)
        let result = results.first { $0.achievement.id == "first_lesson" }

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.progress, 1.0)
    }

    func testLessons10Progress() {
        let stats = UserStats(
            totalHasanat: 50,
            currentLevel: 2,
            unlockedAchievements: [],
            lessonsCompleted: 5,
            totalPrayersLogged: 0,
            totalAyahsRead: 0,
            totalTasbeehCount: 0,
            streakFreezes: 0
        )

        let progress = sut.getProgress(for: "lessons_10", with: stats)
        XCTAssertEqual(progress, 0.5, "5/10 lessons should be 50% progress")
    }

    // MARK: - Level Achievement Tests

    func testLevel5AchievementProgress() {
        let stats = UserStats(
            totalHasanat: 500,
            currentLevel: 3,
            unlockedAchievements: [],
            lessonsCompleted: 0,
            totalPrayersLogged: 0,
            totalAyahsRead: 0,
            totalTasbeehCount: 0,
            streakFreezes: 0
        )

        let progress = sut.getProgress(for: "level_5", with: stats)
        XCTAssertEqual(progress, 0.6, "Level 3/5 should be 60% progress")
    }

    func testLevel5AchievementUnlocks() {
        let stats = UserStats(
            totalHasanat: 1000,
            currentLevel: 5,
            unlockedAchievements: [],
            lessonsCompleted: 0,
            totalPrayersLogged: 0,
            totalAyahsRead: 0,
            totalTasbeehCount: 0,
            streakFreezes: 0
        )

        let results = sut.checkAllAchievements(with: stats)
        let result = results.first { $0.achievement.id == "level_5" }

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.progress, 1.0)
    }

    func testLevel10AchievementUnlocks() {
        let stats = UserStats(
            totalHasanat: 20000,
            currentLevel: 10,
            unlockedAchievements: [],
            lessonsCompleted: 0,
            totalPrayersLogged: 0,
            totalAyahsRead: 0,
            totalTasbeehCount: 0,
            streakFreezes: 0
        )

        let results = sut.checkAllAchievements(with: stats)
        let result = results.first { $0.achievement.id == "level_10" }

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.progress, 1.0)
    }

    // MARK: - Hasanat Achievement Tests

    func testHasanat1000Progress() {
        let stats = UserStats(
            totalHasanat: 500,
            currentLevel: 3,
            unlockedAchievements: [],
            lessonsCompleted: 0,
            totalPrayersLogged: 0,
            totalAyahsRead: 0,
            totalTasbeehCount: 0,
            streakFreezes: 0
        )

        let progress = sut.getProgress(for: "hasanat_1000", with: stats)
        XCTAssertEqual(progress, 0.5, "500/1000 hasanat should be 50% progress")
    }

    func testHasanat1000Unlocks() {
        let stats = UserStats(
            totalHasanat: 1000,
            currentLevel: 5,
            unlockedAchievements: [],
            lessonsCompleted: 0,
            totalPrayersLogged: 0,
            totalAyahsRead: 0,
            totalTasbeehCount: 0,
            streakFreezes: 0
        )

        let results = sut.checkAllAchievements(with: stats)
        let result = results.first { $0.achievement.id == "hasanat_1000" }

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.progress, 1.0)
    }

    // MARK: - Dhikr Achievement Tests

    func testTasbeeh1000Progress() {
        let stats = UserStats(
            totalHasanat: 100,
            currentLevel: 1,
            unlockedAchievements: [],
            lessonsCompleted: 0,
            totalPrayersLogged: 0,
            totalAyahsRead: 0,
            totalTasbeehCount: 500,
            streakFreezes: 0
        )

        let progress = sut.getProgress(for: "tasbeeh_1000", with: stats)
        XCTAssertEqual(progress, 0.5, "500/1000 tasbeeh should be 50% progress")
    }

    func testTasbeeh1000Unlocks() {
        let stats = UserStats(
            totalHasanat: 200,
            currentLevel: 2,
            unlockedAchievements: [],
            lessonsCompleted: 0,
            totalPrayersLogged: 0,
            totalAyahsRead: 0,
            totalTasbeehCount: 1000,
            streakFreezes: 0
        )

        let results = sut.checkAllAchievements(with: stats)
        let result = results.first { $0.achievement.id == "tasbeeh_1000" }

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.progress, 1.0)
    }

    // MARK: - Quran Achievement Tests

    func testQuranReader100Progress() {
        let stats = UserStats(
            totalHasanat: 50,
            currentLevel: 1,
            unlockedAchievements: [],
            lessonsCompleted: 0,
            totalPrayersLogged: 0,
            totalAyahsRead: 50, // ~3 pages
            totalTasbeehCount: 0,
            streakFreezes: 0
        )

        let progress = sut.getProgress(for: "quran_reader_100", with: stats)
        // 50 ayahs / 15 = 3 pages, target is 7 pages
        XCTAssertEqual(progress, Double(3) / Double(7), accuracy: 0.01)
    }

    func testQuranKhatmProgress() {
        let stats = UserStats(
            totalHasanat: 5000,
            currentLevel: 8,
            unlockedAchievements: [],
            lessonsCompleted: 0,
            totalPrayersLogged: 0,
            totalAyahsRead: 3118, // Half the Quran
            totalTasbeehCount: 0,
            streakFreezes: 0
        )

        let progress = sut.getProgress(for: "quran_khatm", with: stats)
        XCTAssertEqual(progress, 0.5, accuracy: 0.01, "Half Quran should be ~50% progress")
    }

    // MARK: - Multiple Achievement Unlock Tests

    func testMultipleAchievementsUnlock() {
        let stats = UserStats(
            totalHasanat: 1500,
            currentLevel: 5,
            unlockedAchievements: [],
            lessonsCompleted: 15,
            totalPrayersLogged: 150,
            totalAyahsRead: 200,
            totalTasbeehCount: 1500,
            streakFreezes: 0
        )

        let results = sut.checkAllAchievements(with: stats)
        let unlockedCount = results.filter { $0.progress >= 1.0 }.count

        // Should unlock: first_prayer, prayers_100, first_lesson, lessons_10,
        // level_5, hasanat_1000, first_tasbeeh, tasbeeh_1000, first_ayah, quran_reader_100
        XCTAssertGreaterThan(unlockedCount, 5, "Multiple achievements should unlock")
    }

    // MARK: - Get Achievements Tests

    func testGetUnlockedAchievementsAfterCheck() {
        let stats = UserStats(
            totalHasanat: 100,
            currentLevel: 1,
            unlockedAchievements: [],
            lessonsCompleted: 1,
            totalPrayersLogged: 1,
            totalAyahsRead: 1,
            totalTasbeehCount: 1,
            streakFreezes: 0
        )

        _ = sut.checkAllAchievements(with: stats)
        let unlocked = sut.getUnlockedAchievements()

        XCTAssertFalse(unlocked.isEmpty, "Some achievements should be unlocked")
    }

    func testGetLockedAchievementsAfterCheck() {
        let stats = UserStats(
            totalHasanat: 100,
            currentLevel: 1,
            unlockedAchievements: [],
            lessonsCompleted: 1,
            totalPrayersLogged: 1,
            totalAyahsRead: 1,
            totalTasbeehCount: 1,
            streakFreezes: 0
        )

        _ = sut.checkAllAchievements(with: stats)
        let locked = sut.getLockedAchievements()

        XCTAssertFalse(locked.isEmpty, "Most achievements should still be locked")
    }

    // MARK: - Check Specific Achievement Tests

    func testCheckSpecificAchievementExists() {
        let stats = UserStats(
            totalHasanat: 10,
            currentLevel: 1,
            unlockedAchievements: [],
            lessonsCompleted: 0,
            totalPrayersLogged: 1,
            totalAyahsRead: 0,
            totalTasbeehCount: 0,
            streakFreezes: 0
        )

        let result = sut.checkSpecificAchievement("first_prayer", with: stats)

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.achievement.id, "first_prayer")
    }

    func testCheckSpecificAchievementNotFound() {
        let stats = UserStats()
        let result = sut.checkSpecificAchievement("nonexistent_achievement", with: stats)

        XCTAssertNil(result, "Nonexistent achievement should return nil")
    }
}
