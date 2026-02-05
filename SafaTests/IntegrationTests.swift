// MARK: - IntegrationTests.swift
// PURPOSE: Integration tests for user flows
// DEPENDENCIES: XCTest

import XCTest
@testable import Safa

// MARK: - Prayer Flow Integration Tests

final class PrayerFlowIntegrationTests: XCTestCase {

    func testCompletePrayerLoggingFlow() async {
        // Given
        let prayerRepo = MockPrayerRepository()
        let streakUseCase = UpdateStreakUseCase()
        let hasanatService = HasanatService()

        let initialHasanat = hasanatService.totalHasanat

        // When - Log a prayer
        await prayerRepo.logPrayer(.fajr, at: Date())

        // Then - Verify prayer was logged
        let logs = await prayerRepo.getPrayerLogs(from: Date(), to: Date())
        XCTAssertFalse(logs.isEmpty, "Prayer should be logged")

        // Award hasanat
        hasanatService.award(for: .prayerLogged(.fajr))
        XCTAssertGreaterThan(hasanatService.totalHasanat, initialHasanat)

        // Update streak
        let result = streakUseCase.recordActivity(.prayer(.fajr), at: Date())
        XCTAssertEqual(result.newCount, 1)
    }

    func testAllFivePrayersCompletionFlow() async {
        // Given
        let prayerRepo = MockPrayerRepository()
        let hasanatService = HasanatService()

        // When - Log all 5 prayers
        for prayer in PrayerType.allCases {
            await prayerRepo.logPrayer(prayer, at: Date())
        }

        // Then - Award bonus hasanat
        hasanatService.award(for: .allFivePrayersLogged)
        XCTAssertEqual(hasanatService.totalHasanat, 25) // All five prayers bonus
    }
}

// MARK: - Quran Reading Integration Tests

final class QuranReadingIntegrationTests: XCTestCase {

    func testCompleteQuranReadingFlow() async {
        // Given
        let quranRepo = MockQuranRepository()
        let hasanatService = HasanatService()
        let streakUseCase = UpdateStreakUseCase()

        // When - Read ayahs
        let ayahs = await quranRepo.getAyahs(forSurah: 1)
        XCTAssertFalse(ayahs.isEmpty)

        // Award hasanat for reading
        hasanatService.award(for: .quranPageRead)

        // Update reading progress
        let progress = ReadingProgress(lastSurah: 1, lastAyah: 7, lastReadDate: Date())
        await quranRepo.updateProgress(progress)

        // Update streak
        let result = streakUseCase.recordActivity(.quranReading, at: Date())
        XCTAssertEqual(result.newCount, 1)

        // Then - Verify state
        let savedProgress = await quranRepo.getReadingProgress()
        XCTAssertEqual(savedProgress?.lastSurah, 1)
        XCTAssertEqual(savedProgress?.lastAyah, 7)
    }

    func testBookmarkFlow() async {
        // Given
        let quranRepo = MockQuranRepository()

        // When - Add bookmark
        let bookmark = QuranBookmark(
            id: UUID(),
            surahNumber: 2,
            ayahNumber: 255,
            note: "Ayatul Kursi",
            createdAt: Date()
        )
        await quranRepo.addBookmark(bookmark)

        // Then - Verify bookmark saved
        let bookmarks = await quranRepo.getBookmarks()
        XCTAssertTrue(bookmarks.contains { $0.ayahNumber == 255 })
    }

    func testSearchFlow() async {
        // Given
        let quranRepo = MockQuranRepository()

        // When - Search for ayahs
        let results = await quranRepo.searchAyahs(query: "mercy")

        // Then - Verify results
        XCTAssertFalse(results.isEmpty)
    }
}

// MARK: - Learning Integration Tests

final class LearningIntegrationTests: XCTestCase {

    func testCompleteLessonFlow() async {
        // Given
        let learningRepo = MockLearningRepository()
        let hasanatService = HasanatService()
        let achievementUseCase = CheckAchievementsUseCase()

        // When - Get tracks and lessons
        let tracks = await learningRepo.getTracks()
        XCTAssertFalse(tracks.isEmpty)

        let lessons = await learningRepo.getLessons(forTrack: "arabic")
        XCTAssertFalse(lessons.isEmpty)

        // Complete a lesson
        await learningRepo.markLessonComplete("lesson1")

        // Award hasanat
        hasanatService.award(for: .lessonCompleted)

        // Then - Verify progress
        let progress = await learningRepo.getLessonProgress()
        XCTAssertTrue(progress.completedLessonIds.contains("lesson1"))
    }
}

// MARK: - Gamification Integration Tests

final class GamificationIntegrationTests: XCTestCase {

    func testLevelUpFlow() {
        // Given
        var stats = UserStats()
        let achievementUseCase = CheckAchievementsUseCase()

        // When - Accumulate hasanat to level 2
        stats.totalHasanat = 100

        // Then - Verify level
        let expectedLevel = UserStats.calculateLevel(from: stats.totalHasanat)
        XCTAssertEqual(expectedLevel, 2)
    }

    func testAchievementUnlockFlow() {
        // Given
        let achievementUseCase = CheckAchievementsUseCase()
        let stats = UserStats(
            totalHasanat: 100,
            currentLevel: 2,
            unlockedAchievements: [],
            lessonsCompleted: 1,
            totalPrayersLogged: 1,
            totalAyahsRead: 10,
            totalTasbeehCount: 100,
            streakFreezes: 0
        )

        // When - Check achievements
        let results = achievementUseCase.checkAllAchievements(with: stats)

        // Then - Verify some achievements unlocked
        let unlockedCount = results.filter { $0.progress >= 1.0 }.count
        XCTAssertGreaterThan(unlockedCount, 0, "Should have some achievements unlocked")
    }

    func testStreakMilestoneFlow() {
        // Given
        let streakUseCase = UpdateStreakUseCase()
        let hasanatService = HasanatService()
        let calendar = Calendar.current
        var date = Date()

        // When - Build 7-day streak
        for _ in 0..<7 {
            let result = streakUseCase.recordActivity(.prayer(.fajr), at: date)

            if result.milestoneReached == 7 {
                hasanatService.award(for: .streakMilestone(days: 7))
            }

            date = calendar.date(byAdding: .day, value: 1, to: date)!
        }

        // Then - Verify streak and bonus
        let streak = streakUseCase.getStreak(for: .prayer)
        XCTAssertEqual(streak.currentCount, 7)
        XCTAssertGreaterThan(hasanatService.totalHasanat, 0)
    }
}

// MARK: - Dhikr Integration Tests

final class DhikrIntegrationTests: XCTestCase {

    func testTasbeehSessionFlow() async {
        // Given
        let duaRepo = MockDuaRepository()
        let hasanatService = HasanatService()

        // When - Complete tasbeeh
        let session = TasbeehSession(
            id: UUID(),
            dhikrType: "subhanallah",
            count: 33,
            completedAt: Date()
        )
        await duaRepo.saveTasbeehSession(session)

        // Award hasanat
        hasanatService.award(for: .tasbeeh(count: 33))

        // Then
        XCTAssertGreaterThan(hasanatService.totalHasanat, 0)
    }

    func testMorningAdhkarFlow() async {
        // Given
        let duaRepo = MockDuaRepository()
        let hasanatService = HasanatService()
        let streakUseCase = UpdateStreakUseCase()

        // When - Get and complete adhkar
        let adhkar = await duaRepo.getAdhkar(type: .morning)
        XCTAssertFalse(adhkar.isEmpty)

        // Award hasanat
        hasanatService.award(for: .morningAdhkarCompleted)

        // Update streak
        _ = streakUseCase.recordActivity(.dhikr, at: Date())

        // Then
        XCTAssertGreaterThan(hasanatService.totalHasanat, 0)
    }
}

// MARK: - Family Integration Tests

final class FamilyIntegrationTests: XCTestCase {

    func testJoinFamilyCircleFlow() async {
        // Given
        let familyRepo = MockFamilyRepository()

        // When - Join circle
        let success = await familyRepo.joinCircle(inviteCode: "ABC123")

        // Then
        XCTAssertTrue(success)

        let circle = await familyRepo.getCircle()
        XCTAssertNotNil(circle)
    }

    func testViewFamilyMembersFlow() async {
        // Given
        let familyRepo = MockFamilyRepository()

        // When - Get members
        let members = await familyRepo.getMembers()

        // Then
        XCTAssertFalse(members.isEmpty)
    }
}

// MARK: - Onboarding Integration Tests

final class OnboardingIntegrationTests: XCTestCase {

    func testOnboardingCompletionFlow() {
        // Given
        var preferences = UserPreferences()
        XCTAssertFalse(preferences.hasCompletedOnboarding)

        // When - Complete onboarding steps
        preferences.calculationMethod = .mwl
        preferences.madhab = .hanafi
        preferences.notificationsEnabled = true
        preferences.hasCompletedOnboarding = true

        // Then
        XCTAssertTrue(preferences.hasCompletedOnboarding)
        XCTAssertEqual(preferences.calculationMethod, .mwl)
        XCTAssertEqual(preferences.madhab, .hanafi)
    }
}

// MARK: - Reminder Integration Tests

final class ReminderIntegrationTests: XCTestCase {

    func testContextualReminderGeneration() {
        // Given
        let reminderService = ContextualReminderService()
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: Date())
        components.hour = 6 // Morning time

        let morningDate = calendar.date(from: components)!

        // When
        let reminders = reminderService.getReminders(currentDate: morningDate)

        // Then
        XCTAssertFalse(reminders.isEmpty, "Should have reminders for morning")
    }

    func testPrayerReminderGeneration() {
        // Given
        let reminderService = ContextualReminderService()
        let nextPrayer = PrayerTime(type: .fajr, time: Date().addingTimeInterval(600)) // 10 min from now

        // When
        let reminders = reminderService.getReminders(
            currentDate: Date(),
            nextPrayer: nextPrayer
        )

        // Then
        XCTAssertFalse(reminders.isEmpty)
    }
}

// MARK: - Sharing Integration Tests

final class SharingIntegrationTests: XCTestCase {

    func testVerseShareFlow() {
        // Given
        let shareService = ShareService()
        let content = ShareableContent.quranVerse(
            surah: "Al-Fatiha",
            ayah: 1,
            arabicText: "بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ",
            translation: "In the name of Allah..."
        )

        // When
        let shareText = shareService.generateShareText(for: content)

        // Then
        XCTAssertTrue(shareText.contains("Al-Fatiha"))
        XCTAssertTrue(shareText.contains("Safa"))
    }

    func testAchievementShareFlow() {
        // Given
        let shareService = ShareService()
        let content = ShareableContent.achievement(
            title: "First Prayer",
            description: "Logged first prayer"
        )

        // When
        let shareText = shareService.generateShareText(for: content)

        // Then
        XCTAssertTrue(shareText.contains("Achievement"))
        XCTAssertTrue(shareText.contains("First Prayer"))
    }
}

// MARK: - Wind Down Integration Tests

final class WindDownIntegrationTests: XCTestCase {

    func testWindDownCompletionFlow() {
        // Given
        let viewModel = WindDownViewModel()
        let hasanatService = HasanatService()

        // When - Complete all adhkar
        for adhkar in viewModel.sleepAdhkar {
            viewModel.toggleAdhkar(adhkar.id)
        }

        // Then
        XCTAssertTrue(viewModel.allAdhkarCompleted)
        XCTAssertEqual(viewModel.completionPercentage, 100)

        // Award hasanat for completion
        if viewModel.allAdhkarCompleted {
            hasanatService.award(for: .eveningAdhkarCompleted)
        }

        XCTAssertGreaterThan(hasanatService.totalHasanat, 0)
    }
}
