// MARK: - RepositoryCorrectnessTests.swift
// PURPOSE: Behavioral correctness tests for repository implementations.
// Tests data contracts, dedup logic, state transitions, and edge cases
// that affect user-visible behavior.

import XCTest
@testable import Safa

// MARK: - Prayer Repository Dedup Tests

final class PrayerRepositoryDedupTests: XCTestCase {

    var sut: StatefulMockPrayerRepository!

    override func setUp() {
        super.setUp()
        sut = StatefulMockPrayerRepository()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    func test_logPrayer_thenCheckLogged_returnsTrue() async throws {
        let today = Date()
        try await sut.logPrayer(.fajr, for: today, at: today, isOnTime: true)

        let isLogged = try await sut.isPrayerLogged(.fajr, for: today)
        XCTAssertTrue(isLogged)
    }

    func test_differentPrayer_notLogged() async throws {
        let today = Date()
        try await sut.logPrayer(.fajr, for: today, at: today, isOnTime: true)

        let isLogged = try await sut.isPrayerLogged(.dhuhr, for: today)
        XCTAssertFalse(isLogged, "Logging Fajr should not mark Dhuhr as logged")
    }

    func test_differentDate_notLogged() async throws {
        let today = Date()
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        try await sut.logPrayer(.fajr, for: today, at: today, isOnTime: true)

        let isLogged = try await sut.isPrayerLogged(.fajr, for: tomorrow)
        XCTAssertFalse(isLogged, "Logging Fajr today should not affect tomorrow")
    }

    func test_deletePrayerLog_removesLog() async throws {
        let today = Date()
        try await sut.logPrayer(.asr, for: today, at: today, isOnTime: true)

        let logs = try await sut.getPrayerLogs(for: today)
        XCTAssertEqual(logs.count, 1)

        try await sut.deletePrayerLog(logs[0])

        let logsAfter = try await sut.getPrayerLogs(for: today)
        XCTAssertTrue(logsAfter.isEmpty)
    }

    func test_logAllFivePrayers_returnsAllFive() async throws {
        let today = Date()
        for prayer in PrayerType.obligatoryPrayers {
            try await sut.logPrayer(prayer, for: today, at: today, isOnTime: true)
        }

        let logs = try await sut.getPrayerLogs(for: today)
        XCTAssertEqual(logs.count, 5)

        let loggedTypes = Set(logs.map { $0.prayerType })
        XCTAssertEqual(loggedTypes, Set(PrayerType.obligatoryPrayers))
    }

    func test_getPrayerLogs_dateRange_filtersCorrectly() async throws {
        let calendar = Calendar.current
        let today = Date()
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        let twoDaysAgo = calendar.date(byAdding: .day, value: -2, to: today)!

        try await sut.logPrayer(.fajr, for: twoDaysAgo, at: twoDaysAgo, isOnTime: true)
        try await sut.logPrayer(.dhuhr, for: yesterday, at: yesterday, isOnTime: true)
        try await sut.logPrayer(.asr, for: today, at: today, isOnTime: true)

        let lastTwoDays = try await sut.getPrayerLogs(from: yesterday, to: today)
        XCTAssertEqual(lastTwoDays.count, 2, "Should include yesterday and today, not two days ago")
    }
}

// MARK: - Quran Repository Bookmark Dedup Tests

final class QuranBookmarkDedupTests: XCTestCase {

    var sut: MockQuranRepository!

    override func setUp() {
        super.setUp()
        sut = MockQuranRepository()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    func test_addBookmark_thenRemove_isNotBookmarked() async throws {
        try await sut.addBookmark(surah: 2, ayah: 255)
        let isBookmarked = try await sut.isBookmarked(surah: 2, ayah: 255)
        XCTAssertTrue(isBookmarked)

        try await sut.removeBookmark(surah: 2, ayah: 255)
        let isNotBookmarked = try await sut.isBookmarked(surah: 2, ayah: 255)
        XCTAssertFalse(isNotBookmarked)
    }

    func test_removeBookmark_doesNotAffectOtherBookmarks() async throws {
        try await sut.addBookmark(surah: 1, ayah: 1)
        try await sut.addBookmark(surah: 2, ayah: 255)

        try await sut.removeBookmark(surah: 1, ayah: 1)

        let isFirstRemoved = try await sut.isBookmarked(surah: 1, ayah: 1)
        let isSecondStillBookmarked = try await sut.isBookmarked(surah: 2, ayah: 255)
        XCTAssertFalse(isFirstRemoved)
        XCTAssertTrue(isSecondStillBookmarked, "Removing one bookmark should not affect another")
    }

    func test_bookmarkList_reflectsAdditions() async throws {
        try await sut.addBookmark(surah: 36, ayah: 1)
        try await sut.addBookmark(surah: 67, ayah: 1)

        let bookmarks = try await sut.getBookmarks()
        XCTAssertEqual(bookmarks.count, 2)

        let surahNumbers = Set(bookmarks.map { $0.surahNumber })
        XCTAssertTrue(surahNumbers.contains(36))
        XCTAssertTrue(surahNumbers.contains(67))
    }
}

// MARK: - Dua Repository Completion Tests

final class DuaCompletionTests: XCTestCase {

    var sut: MockDuaRepository!

    override func setUp() {
        super.setUp()
        sut = MockDuaRepository()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    func test_markDhikrCompleted_tracksPerType() async throws {
        let dua = Dua(
            id: "dua1", categoryId: "morning",
            titleEnglish: "Test", textArabic: "اختبار",
            textTransliteration: "test", textTranslation: "test"
        )

        try await sut.markDhikrCompleted(dua, type: .morning)

        let morningStatus = try await sut.getDhikrCompletionStatus(for: .morning)
        let eveningStatus = try await sut.getDhikrCompletionStatus(for: .evening)

        XCTAssertEqual(morningStatus.count, 1)
        XCTAssertTrue(eveningStatus.isEmpty,
                      "Morning completion should not affect evening status")
    }

    func test_resetDhikrCompletion_clearsAllTypes() async throws {
        let dua = Dua(
            id: "dua1", categoryId: "morning",
            titleEnglish: "Test", textArabic: "اختبار",
            textTransliteration: "test", textTranslation: "test"
        )

        try await sut.markDhikrCompleted(dua, type: .morning)
        try await sut.markDhikrCompleted(dua, type: .evening)

        try await sut.resetDhikrCompletion()

        let morningStatus = try await sut.getDhikrCompletionStatus(for: .morning)
        let eveningStatus = try await sut.getDhikrCompletionStatus(for: .evening)

        XCTAssertTrue(morningStatus.isEmpty)
        XCTAssertTrue(eveningStatus.isEmpty)
    }

    func test_favorites_addAndRemove() async throws {
        let dua = Dua(
            id: "fav1", categoryId: "daily",
            titleEnglish: "Favorite", textArabic: "مفضل",
            textTransliteration: "mufaddal", textTranslation: "Favorite"
        )

        try await sut.addToFavorites(dua)
        var favorites = try await sut.getFavorites()
        XCTAssertEqual(favorites.count, 1)

        try await sut.removeFromFavorites(dua)
        favorites = try await sut.getFavorites()
        XCTAssertTrue(favorites.isEmpty)
    }
}

// MARK: - Learning Repository Progress Tests

final class LearningProgressTests: XCTestCase {

    var sut: MockLearningRepository!

    override func setUp() {
        super.setUp()
        sut = MockLearningRepository()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    func test_markLessonComplete_incrementsProgress() async throws {
        try await sut.markLessonComplete(lessonId: "lesson1", score: 85)

        let progress = try await sut.getTrackProgress(trackId: "arabic_foundations")
        XCTAssertEqual(progress.completedLessons, 1)
    }

    func test_getNextLesson_returnsLesson() async throws {
        let next = try await sut.getNextLesson()
        XCTAssertNotNil(next, "Should always have a next lesson recommendation")
    }

    func test_getOverallProgress_returnsValid() async throws {
        let progress = try await sut.getOverallProgress()
        XCTAssertGreaterThanOrEqual(progress.totalLessonsCompleted, 0)
        XCTAssertGreaterThanOrEqual(progress.totalMinutesLearned, 0)
    }
}

// MARK: - Hadith Repository Daily Selection Tests

final class HadithDailySelectionTests: XCTestCase {

    var sut: MockHadithRepository!

    override func setUp() {
        super.setUp()
        sut = MockHadithRepository()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    func test_dailyHadith_returnsNonEmpty() async throws {
        let hadith = try await sut.getDailyHadith(for: Date())

        XCTAssertFalse(hadith.textArabic.isEmpty)
        XCTAssertFalse(hadith.textEnglish.isEmpty)
    }

    func test_dailyHadith_hasValidGrading() async throws {
        let hadith = try await sut.getDailyHadith(for: Date())

        // Daily hadith should be authentic
        XCTAssertEqual(hadith.grading, .sahih)
    }

    func test_collections_containMajorCompilations() async throws {
        let collections = try await sut.getCollections()

        let names = collections.map { $0.nameEnglish }
        XCTAssertTrue(names.contains("Sahih al-Bukhari"))
        XCTAssertTrue(names.contains("Sahih Muslim"))
    }

    func test_bookmarkWorkflow_addAndRetrieve() async throws {
        let hadith = try await sut.getDailyHadith(for: Date())

        try await sut.addBookmark(hadith)
        let bookmarks = try await sut.getBookmarks()

        XCTAssertEqual(bookmarks.count, 1)
        XCTAssertEqual(bookmarks.first?.textArabic, hadith.textArabic)
    }

    func test_removeBookmark_onlyRemovesTarget() async throws {
        let hadith1 = Hadith(
            id: "h1", collectionId: "bukhari", bookId: "1", hadithNumber: 1,
            textArabic: "حديث ١", textEnglish: "Hadith 1",
            narrator: "Abu Hurairah", grading: .sahih, reference: "Bukhari 1"
        )
        let hadith2 = Hadith(
            id: "h2", collectionId: "muslim", bookId: "1", hadithNumber: 1,
            textArabic: "حديث ٢", textEnglish: "Hadith 2",
            narrator: "Aisha", grading: .sahih, reference: "Muslim 1"
        )

        try await sut.addBookmark(hadith1)
        try await sut.addBookmark(hadith2)
        try await sut.removeBookmark(hadith1)

        let bookmarks = try await sut.getBookmarks()
        XCTAssertEqual(bookmarks.count, 1)
        XCTAssertEqual(bookmarks.first?.id, "h2")
    }
}

// MARK: - Chat Repository Title Generation Tests

final class ChatTitleGenerationTests: XCTestCase {

    // ChatRepository.generateTitle is private, but we can test the
    // Conversation.displayTitle contract which is the public-facing behavior.

    func test_displayTitle_withTitle_returnsTitle() {
        let conv = Conversation(title: "Questions about Ramadan")
        XCTAssertEqual(conv.displayTitle, "Questions about Ramadan")
    }

    func test_displayTitle_withoutTitle_returnsFallback() {
        let conv = Conversation()
        XCTAssertEqual(conv.displayTitle, "New Conversation")
    }

    func test_displayTitle_withEmptyTitle_treatedAsTitle() {
        // Empty string is still a non-nil title
        let conv = Conversation(title: "")
        XCTAssertEqual(conv.displayTitle, "")
    }

    func test_chatError_generationFailed_includesReason() {
        let error = ChatError.generationFailed("context too long")
        XCTAssertTrue(error.errorDescription?.contains("context too long") ?? false,
                      "Error should include the failure reason")
    }

    func test_chatMessage_systemRole_isNeitherUserNorAssistant() {
        let msg = ChatMessage(conversationId: UUID(), role: .system, content: "prompt")
        XCTAssertFalse(msg.isUser)
        XCTAssertFalse(msg.isAssistant)
    }
}

// MARK: - Streak Freeze Mechanics Tests

final class StreakFreezeMechanicsTests: XCTestCase {

    var sut: UpdateStreakUseCase!

    override func setUp() {
        super.setUp()
        sut = UpdateStreakUseCase()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    func test_consecutiveDays_extendsStreak() {
        let today = Date()
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!

        _ = sut.recordActivity(.quranReading, at: yesterday)
        let result = sut.recordActivity(.quranReading, at: today)

        XCTAssertEqual(result.newCount, 2)
        XCTAssertFalse(result.streakBroken)
    }

    func test_missedTwoDays_breaksStreak() {
        let today = Date()
        let threeDaysAgo = Calendar.current.date(byAdding: .day, value: -3, to: today)!

        _ = sut.recordActivity(.dhikr, at: threeDaysAgo)
        let result = sut.recordActivity(.dhikr, at: today)

        XCTAssertTrue(result.streakBroken)
        XCTAssertEqual(result.newCount, 1, "Streak should reset to 1 after break")
    }

    func test_sameDay_doesNotIncrementStreak() {
        let today = Date()

        _ = sut.recordActivity(.prayer(.fajr), at: today)
        let result = sut.recordActivity(.prayer(.dhuhr), at: today)

        XCTAssertFalse(result.countIncreased, "Same day should not increment")
    }

    func test_buildingLongStreak_tracksLongestCount() {
        let today = Date()

        // Build a 5-day streak
        for i in (0..<5).reversed() {
            let date = Calendar.current.date(byAdding: .day, value: -i, to: today)!
            _ = sut.recordActivity(.learning, at: date)
        }

        let streak = sut.getStreak(for: .learning)
        XCTAssertEqual(streak.currentCount, 5)
        XCTAssertEqual(streak.longestCount, 5)
    }

    func test_streakBreak_preservesLongestCount() {
        let today = Date()

        // Build a 3-day streak, break it, start new
        for i in [5, 4, 3] {
            let date = Calendar.current.date(byAdding: .day, value: -i, to: today)!
            _ = sut.recordActivity(.quranReading, at: date)
        }
        // Skip day -2, record today (breaks streak)
        _ = sut.recordActivity(.quranReading, at: today)

        let streak = sut.getStreak(for: .quran)
        XCTAssertEqual(streak.currentCount, 1, "Current should reset")
        XCTAssertEqual(streak.longestCount, 3, "Longest should be preserved")
    }
}

// MARK: - Multiplier Integration Tests

final class HasanatMultiplierTests: XCTestCase {

    var sut: CalculateHasanatUseCase!

    override func setUp() {
        super.setUp()
        sut = CalculateHasanatUseCase()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    func test_ramadanMultiplier_doublesAllPrayers() {
        for prayer in PrayerType.obligatoryPrayers {
            let base = sut.calculatePoints(for: .prayerLogged(prayer))
            let ramadan = sut.calculateWithMultipliers(
                for: .prayerLogged(prayer), isRamadan: true, isFriday: false
            )
            XCTAssertEqual(ramadan, base * 2,
                           "Ramadan should double \(prayer) points")
        }
    }

    func test_fridayMultiplier_isOnePointFive() {
        let base = sut.calculatePoints(for: .prayerLogged(.dhuhr))
        let friday = sut.calculateWithMultipliers(
            for: .prayerLogged(.dhuhr), isRamadan: false, isFriday: true
        )
        XCTAssertEqual(friday, Int(Double(base) * 1.5))
    }

    func test_ramadanTakesPrecedenceOverFriday() {
        let base = sut.calculatePoints(for: .prayerLogged(.fajr))
        let both = sut.calculateWithMultipliers(
            for: .prayerLogged(.fajr), isRamadan: true, isFriday: true
        )
        // Ramadan (2x) should take precedence over Friday (1.5x)
        XCTAssertEqual(both, base * 2)
    }

    func test_noMultiplier_returnsBasePoints() {
        let base = sut.calculatePoints(for: .quranPageRead)
        let noMultiplier = sut.calculateWithMultipliers(
            for: .quranPageRead, isRamadan: false, isFriday: false
        )
        XCTAssertEqual(base, noMultiplier)
    }

    func test_tasbeeh_tieredPoints() {
        let small = sut.calculatePoints(for: .tasbeeh(count: 10))
        let medium = sut.calculatePoints(for: .tasbeeh(count: 33))
        let large = sut.calculatePoints(for: .tasbeeh(count: 100))

        // Higher counts should yield more points
        XCTAssertLessThanOrEqual(small, medium)
        XCTAssertLessThanOrEqual(medium, large)
    }

    func test_surahCompletion_longSurahsWorthMore() {
        let shortSurah = sut.calculatePoints(for: .quranSurahCompleted(surahNumber: 112)) // Al-Ikhlas (4 ayahs)
        let longSurah = sut.calculatePoints(for: .quranSurahCompleted(surahNumber: 2))   // Al-Baqarah (286 ayahs)

        XCTAssertGreaterThan(longSurah, shortSurah,
                             "Al-Baqarah should award more than Al-Ikhlas")
    }

    func test_streakMilestone_higherDaysWorthMore() {
        let week = sut.calculatePoints(for: .streakMilestone(days: 7))
        let month = sut.calculatePoints(for: .streakMilestone(days: 30))
        let hundred = sut.calculatePoints(for: .streakMilestone(days: 100))

        XCTAssertLessThan(week, month)
        XCTAssertLessThan(month, hundred)
    }
}
