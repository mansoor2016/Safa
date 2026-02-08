// MARK: - RepositoryTests.swift
// PURPOSE: Unit tests for repository protocol conformance
// DEPENDENCIES: XCTest

import XCTest
@testable import Safa

// MARK: - Prayer Repository Tests

final class PrayerRepositoryTests: XCTestCase {

    func testPrayerRepositoryProtocolExists() {
        // Verify protocol can be used as a type constraint
        let mockRepo: any PrayerRepositoryProtocol = MockPrayerRepository()
        XCTAssertNotNil(mockRepo)
    }

    func testMockGetPrayers() async throws {
        let mockRepo = MockPrayerRepository()
        let location = Coordinates(latitude: 40.7128, longitude: -74.0060) // New York

        let times = try await mockRepo.getPrayers(for: Date(), location: location, method: .muslimWorldLeague)

        XCTAssertFalse(times.isEmpty, "Should return prayer times")
        XCTAssertEqual(times.count, 6) // 5 prayers + sunrise
    }

    func testMockLogPrayer() async throws {
        let mockRepo = MockPrayerRepository()

        try await mockRepo.logPrayer(.fajr, for: Date(), at: Date(), isOnTime: true)

        let logs = try await mockRepo.getPrayerLogs(for: Date())
        XCTAssertFalse(logs.isEmpty, "Should have logged prayer")
    }
}

// MARK: - Mock Prayer Repository

final class MockPrayerRepository: PrayerRepositoryProtocol {
    private var logs: [PrayerLog] = []

    func getPrayers(for date: Date, location: Coordinates, method: CalculationMethod) async throws -> [PrayerTime] {
        let baseTime = Calendar.current.startOfDay(for: date)

        return [
            PrayerTime(type: .fajr, time: baseTime.addingTimeInterval(5 * 3600)),
            PrayerTime(type: .sunrise, time: baseTime.addingTimeInterval(6.5 * 3600)),
            PrayerTime(type: .dhuhr, time: baseTime.addingTimeInterval(12 * 3600)),
            PrayerTime(type: .asr, time: baseTime.addingTimeInterval(15 * 3600)),
            PrayerTime(type: .maghrib, time: baseTime.addingTimeInterval(18 * 3600)),
            PrayerTime(type: .isha, time: baseTime.addingTimeInterval(19.5 * 3600))
        ]
    }

    func logPrayer(_ prayer: PrayerType, for date: Date, at time: Date, isOnTime: Bool) async throws {
        let log = PrayerLog(
            prayerType: prayer,
            date: date,
            loggedAt: time,
            isOnTime: isOnTime
        )
        logs.append(log)
    }

    func getPrayerLogs(from: Date, to: Date) async throws -> [PrayerLog] {
        return logs.filter { log in
            log.date >= from && log.date <= to
        }
    }

    func getPrayerLogs(for date: Date) async throws -> [PrayerLog] {
        let calendar = Calendar.current
        return logs.filter { log in
            calendar.isDate(log.date, inSameDayAs: date)
        }
    }

    func deletePrayerLog(_ log: PrayerLog) async throws {
        logs.removeAll { $0.id == log.id }
    }

    func isPrayerLogged(_ prayer: PrayerType, for date: Date) async throws -> Bool {
        let calendar = Calendar.current
        return logs.contains { log in
            log.prayerType == prayer && calendar.isDate(log.date, inSameDayAs: date)
        }
    }
}

// MARK: - Quran Repository Tests

final class QuranRepositoryTests: XCTestCase {

    var sut: MockQuranRepository!

    override func setUp() {
        super.setUp()
        sut = MockQuranRepository()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    func testQuranRepositoryProtocolExists() {
        let mockRepo: any QuranRepositoryProtocol = MockQuranRepository()
        XCTAssertNotNil(mockRepo)
    }

    func testMockGetAllSurahs() async throws {
        let surahs = try await sut.getAllSurahs()

        XCTAssertFalse(surahs.isEmpty)
        XCTAssertEqual(surahs.first?.number, 1)
        XCTAssertEqual(surahs.first?.nameEnglish, "Al-Fatiha")
    }

    func testMockGetAyahsForSurah() async throws {
        let ayahs = try await sut.getAyahs(forSurah: 1)

        XCTAssertEqual(ayahs.count, 7, "Al-Fatiha should have 7 ayahs")
    }

    func testGetSurah_existingNumber_returnsSurah() async throws {
        let surah = try await sut.getSurah(number: 1)

        XCTAssertNotNil(surah)
        XCTAssertEqual(surah?.nameEnglish, "Al-Fatiha")
        XCTAssertEqual(surah?.ayahCount, 7)
    }

    func testGetSurah_nonExistingNumber_returnsNil() async throws {
        let surah = try await sut.getSurah(number: 999)

        XCTAssertNil(surah)
    }

    func testGetAyah_existingAyah_returnsAyah() async throws {
        let ayah = try await sut.getAyah(surah: 1, ayah: 1)

        XCTAssertNotNil(ayah)
        XCTAssertEqual(ayah?.surahNumber, 1)
        XCTAssertEqual(ayah?.ayahNumber, 1)
    }

    func testSearchAyahs_returnsResults() async throws {
        let results = try await sut.searchAyahs(query: "Allah")

        XCTAssertFalse(results.isEmpty)
    }

    func testBookmark_addAndRemove() async throws {
        // Initially not bookmarked
        var isBookmarked = try await sut.isBookmarked(surah: 1, ayah: 1)
        XCTAssertFalse(isBookmarked)

        // Add bookmark
        try await sut.addBookmark(surah: 1, ayah: 1)
        isBookmarked = try await sut.isBookmarked(surah: 1, ayah: 1)
        XCTAssertTrue(isBookmarked)

        // Verify in bookmarks list
        var bookmarks = try await sut.getBookmarks()
        XCTAssertEqual(bookmarks.count, 1)
        XCTAssertEqual(bookmarks.first?.surahNumber, 1)
        XCTAssertEqual(bookmarks.first?.ayahNumber, 1)

        // Remove bookmark
        try await sut.removeBookmark(surah: 1, ayah: 1)
        isBookmarked = try await sut.isBookmarked(surah: 1, ayah: 1)
        XCTAssertFalse(isBookmarked)

        // Verify removed from list
        bookmarks = try await sut.getBookmarks()
        XCTAssertTrue(bookmarks.isEmpty)
    }

    func testGetReadingProgress_returnsProgress() async throws {
        let progress = try await sut.getReadingProgress()

        XCTAssertNotNil(progress)
        XCTAssertEqual(progress?.lastSurah, 1)
        XCTAssertEqual(progress?.lastAyah, 5)
    }

    func testGetJuz_existingJuz_returnsJuz() async throws {
        let juz = try await sut.getJuz(number: 1)

        XCTAssertNotNil(juz)
        XCTAssertEqual(juz?.number, 1)
    }

    func testGetAllJuz_returns30Juz() async throws {
        let allJuz = try await sut.getAllJuz()

        XCTAssertEqual(allJuz.count, 30)
        XCTAssertEqual(allJuz.first?.number, 1)
        XCTAssertEqual(allJuz.last?.number, 30)
    }

    func testSurahProperties() async throws {
        let surahs = try await sut.getAllSurahs()

        // Test Al-Fatiha (Meccan)
        let fatiha = surahs.first
        XCTAssertEqual(fatiha?.revelationType, .meccan)

        // Test Al-Baqarah (Medinan)
        let baqarah = surahs.first { $0.number == 2 }
        XCTAssertEqual(baqarah?.revelationType, .medinan)
        XCTAssertEqual(baqarah?.ayahCount, 286)
    }

    func testAyahContainsExpectedFields() async throws {
        let ayahs = try await sut.getAyahs(forSurah: 1)
        guard let ayah = ayahs.first else {
            XCTFail("Expected at least one ayah")
            return
        }

        XCTAssertEqual(ayah.surahNumber, 1)
        XCTAssertEqual(ayah.ayahNumber, 1)
        XCTAssertFalse(ayah.textArabic.isEmpty)
        XCTAssertFalse(ayah.textTranslation.isEmpty)
        XCTAssertGreaterThan(ayah.juzNumber, 0)
        XCTAssertGreaterThan(ayah.pageNumber, 0)
    }
}

// MARK: - Mock Quran Repository

final class MockQuranRepository: QuranRepositoryProtocol {
    private var bookmarkedAyahs: Set<String> = []

    func getAllSurahs() async throws -> [Surah] {
        return [
            Surah(
                id: 1,
                nameArabic: "الفاتحة",
                nameEnglish: "Al-Fatiha",
                nameTransliteration: "Al-Fatihah",
                revelationType: .meccan,
                ayahCount: 7,
                juzStart: 1
            ),
            Surah(
                id: 2,
                nameArabic: "البقرة",
                nameEnglish: "Al-Baqarah",
                nameTransliteration: "Al-Baqarah",
                revelationType: .medinan,
                ayahCount: 286,
                juzStart: 1
            )
        ]
    }

    func getSurah(number: Int) async throws -> Surah? {
        let surahs = try await getAllSurahs()
        return surahs.first { $0.number == number }
    }

    func getAyahs(forSurah surahNumber: Int) async throws -> [Ayah] {
        if surahNumber == 1 {
            return (1...7).map { number in
                Ayah(
                    surahNumber: 1,
                    ayahNumber: number,
                    textArabic: "Arabic text for ayah \(number)",
                    textTranslation: "Translation for ayah \(number)",
                    juzNumber: 1,
                    pageNumber: 1
                )
            }
        }
        return []
    }

    func getAyah(surah surahNumber: Int, ayah ayahNumber: Int) async throws -> Ayah? {
        let ayahs = try await getAyahs(forSurah: surahNumber)
        return ayahs.first { $0.ayahNumber == ayahNumber }
    }

    func searchAyahs(query: String) async throws -> [Ayah] {
        return [
            Ayah(
                surahNumber: 1,
                ayahNumber: 1,
                textArabic: "بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ",
                textTranslation: "In the name of Allah, the Most Gracious, the Most Merciful",
                juzNumber: 1,
                pageNumber: 1
            )
        ]
    }

    func getBookmarks() async throws -> [QuranBookmark] {
        return bookmarkedAyahs.compactMap { key in
            let parts = key.split(separator: "_")
            guard parts.count == 2,
                  let surah = Int(parts[0]),
                  let ayah = Int(parts[1]) else { return nil }
            return QuranBookmark(surahNumber: surah, ayahNumber: ayah)
        }
    }

    func addBookmark(surah: Int, ayah: Int) async throws {
        bookmarkedAyahs.insert("\(surah)_\(ayah)")
    }

    func removeBookmark(surah: Int, ayah: Int) async throws {
        bookmarkedAyahs.remove("\(surah)_\(ayah)")
    }

    func isBookmarked(surah: Int, ayah: Int) async throws -> Bool {
        return bookmarkedAyahs.contains("\(surah)_\(ayah)")
    }

    func getReadingProgress() async throws -> QuranProgress? {
        return QuranProgress(lastSurah: 1, lastAyah: 5)
    }

    func updateProgress(surah: Int, ayah: Int) async throws {
        // Mock implementation
    }

    func getJuz(number: Int) async throws -> Juz? {
        return Juz(id: number, startSurah: 1, startAyah: 1, endSurah: 2, endAyah: 141)
    }

    func getAllJuz() async throws -> [Juz] {
        return (1...30).map { Juz(id: $0, startSurah: 1, startAyah: 1, endSurah: 2, endAyah: 141) }
    }
}

// MARK: - Hadith Repository Tests

final class HadithRepositoryTests: XCTestCase {

    func testHadithRepositoryProtocolExists() {
        let mockRepo: any HadithRepositoryProtocol = MockHadithRepository()
        XCTAssertNotNil(mockRepo)
    }

    func testMockGetCollections() async throws {
        let mockRepo = MockHadithRepository()

        let collections = try await mockRepo.getCollections()

        XCTAssertFalse(collections.isEmpty)
        XCTAssertTrue(collections.contains { $0.nameEnglish == "Sahih al-Bukhari" })
    }

    func testMockGetDailyHadith() async throws {
        let mockRepo = MockHadithRepository()

        let hadith = try await mockRepo.getDailyHadith(for: Date())

        XCTAssertFalse(hadith.textArabic.isEmpty)
    }
}

// MARK: - Mock Hadith Repository

final class MockHadithRepository: HadithRepositoryProtocol {
    private var bookmarkedHadiths: [Hadith] = []

    func getCollections() async throws -> [HadithCollection] {
        return [
            HadithCollection(
                id: "bukhari",
                nameEnglish: "Sahih al-Bukhari",
                nameArabic: "صحيح البخاري",
                compilerName: "Imam Bukhari",
                totalHadiths: 7563,
                totalBooks: 97
            ),
            HadithCollection(
                id: "muslim",
                nameEnglish: "Sahih Muslim",
                nameArabic: "صحيح مسلم",
                compilerName: "Imam Muslim",
                totalHadiths: 7500,
                totalBooks: 56
            )
        ]
    }

    func getBooks(forCollection collectionId: String) async throws -> [HadithBook] {
        return [
            HadithBook(
                id: "1",
                collectionId: collectionId,
                bookNumber: 1,
                nameEnglish: "Revelation",
                nameArabic: "بدء الوحي",
                hadithCount: 7
            )
        ]
    }

    func getHadiths(collection collectionId: String, book bookId: String) async throws -> [Hadith] {
        return [
            Hadith(
                id: "\(collectionId)_\(bookId)_1",
                collectionId: collectionId,
                bookId: bookId,
                hadithNumber: 1,
                textArabic: "Arabic hadith text",
                textEnglish: "English translation",
                narrator: "Abu Hurairah",
                grading: .sahih,
                reference: "\(collectionId) 1"
            )
        ]
    }

    func getHadith(collection collectionId: String, number hadithNumber: Int) async throws -> Hadith? {
        return Hadith(
            id: "\(collectionId)_\(hadithNumber)",
            collectionId: collectionId,
            bookId: "1",
            hadithNumber: hadithNumber,
            textArabic: "Arabic hadith text",
            textEnglish: "English translation",
            narrator: "Abu Hurairah",
            grading: .sahih,
            reference: "\(collectionId) \(hadithNumber)"
        )
    }

    func searchHadiths(query: String) async throws -> [Hadith] {
        return []
    }

    func getDailyHadith(for date: Date) async throws -> Hadith {
        return Hadith(
            id: "daily_\(date.timeIntervalSince1970)",
            collectionId: "bukhari",
            bookId: "1",
            hadithNumber: 1,
            textArabic: "إنما الأعمال بالنيات",
            textEnglish: "Actions are judged by intentions",
            narrator: "Umar ibn Al-Khattab",
            grading: .sahih,
            reference: "Bukhari 1"
        )
    }

    func getBookmarks() async throws -> [Hadith] {
        return bookmarkedHadiths
    }

    func addBookmark(_ hadith: Hadith) async throws {
        bookmarkedHadiths.append(hadith)
    }

    func removeBookmark(_ hadith: Hadith) async throws {
        bookmarkedHadiths.removeAll { $0.id == hadith.id }
    }
}

// MARK: - Learning Repository Tests

final class LearningRepositoryProtocolTests: XCTestCase {

    func testLearningRepositoryProtocolExists() {
        let mockRepo: any LearningRepositoryProtocol = MockLearningRepository()
        XCTAssertNotNil(mockRepo)
    }

    func testMockGetTracks() async throws {
        let mockRepo = MockLearningRepository()

        let tracks = try await mockRepo.getTracks()

        XCTAssertFalse(tracks.isEmpty)
    }

    func testMockGetLessons() async throws {
        let mockRepo = MockLearningRepository()

        let lessons = try await mockRepo.getLessons(forTrack: "arabic_foundations")

        XCTAssertFalse(lessons.isEmpty)
    }
}

// MARK: - Mock Learning Repository

final class MockLearningRepository: LearningRepositoryProtocol {
    private var completedLessons: Set<String> = []

    func getTracks() async throws -> [LearningTrack] {
        return [
            LearningTrack(
                id: "arabic_foundations",
                titleEnglish: "Arabic Foundations",
                titleArabic: "أساسيات العربية",
                description: "Learn the Arabic letters",
                iconName: "textformat",
                lessonCount: 28,
                estimatedMinutes: 120
            ),
            LearningTrack(
                id: "tajweed",
                titleEnglish: "Tajweed Rules",
                titleArabic: "أحكام التجويد",
                description: "Learn Quran recitation rules",
                iconName: "waveform",
                lessonCount: 15,
                estimatedMinutes: 180
            )
        ]
    }

    func getTrack(id trackId: String) async throws -> LearningTrack? {
        let tracks = try await getTracks()
        return tracks.first { $0.id == trackId }
    }

    func getLessons(forTrack trackId: String) async throws -> [Lesson] {
        return (1...5).map { index in
            Lesson(
                id: "lesson\(index)",
                trackId: trackId,
                order: index,
                titleEnglish: "Lesson \(index)",
                description: "Description",
                durationMinutes: 10,
                type: .reading
            )
        }
    }

    func getLesson(trackId: String, lessonId: String) async throws -> Lesson? {
        let lessons = try await getLessons(forTrack: trackId)
        return lessons.first { $0.id == lessonId }
    }

    func getLessonContent(lessonId: String) async throws -> LessonContent? {
        return nil
    }

    func markLessonComplete(lessonId: String, score: Int) async throws {
        completedLessons.insert(lessonId)
    }

    func getTrackProgress(trackId: String) async throws -> TrackProgress {
        return TrackProgress(
            trackId: trackId,
            completedLessons: completedLessons.count,
            totalLessons: 5
        )
    }

    func getOverallProgress() async throws -> LearningProgress {
        return LearningProgress(
            totalLessonsCompleted: completedLessons.count,
            totalTracksCompleted: 0,
            totalMinutesLearned: 30,
            currentStreak: 0,
            pronunciationAttempts: 0
        )
    }

    func recordPronunciationAttempt(lessonId: String, score: Int) async throws {
        // Mock implementation
    }

    func getNextLesson() async throws -> Lesson? {
        return Lesson(
            id: "lesson1",
            trackId: "arabic_foundations",
            order: 1,
            titleEnglish: "Lesson 1",
            description: "First lesson",
            durationMinutes: 10,
            type: .reading
        )
    }
}

// MARK: - Dua Repository Tests

final class DuaRepositoryTests: XCTestCase {

    func testDuaRepositoryProtocolExists() {
        let mockRepo: any DuaRepositoryProtocol = MockDuaRepository()
        XCTAssertNotNil(mockRepo)
    }

    func testMockGetCategories() async throws {
        let mockRepo = MockDuaRepository()

        let categories = try await mockRepo.getCategories()

        XCTAssertFalse(categories.isEmpty)
    }

    func testMockGetMorningDhikr() async throws {
        let mockRepo = MockDuaRepository()

        let dhikr = try await mockRepo.getMorningDhikr()

        XCTAssertFalse(dhikr.isEmpty)
    }
}

// MARK: - Mock Dua Repository

final class MockDuaRepository: DuaRepositoryProtocol {
    private var favorites: [Dua] = []
    private var completedDhikr: [DhikrType: [String]] = [:]

    func getCategories() async throws -> [DuaCategory] {
        return [
            DuaCategory(
                id: "morning",
                nameEnglish: "Morning",
                nameArabic: "الصباح",
                iconName: "sunrise",
                duaCount: 10
            ),
            DuaCategory(
                id: "evening",
                nameEnglish: "Evening",
                nameArabic: "المساء",
                iconName: "sunset",
                duaCount: 10
            )
        ]
    }

    func getDuas(forCategory categoryId: String) async throws -> [Dua] {
        return [
            Dua(
                id: UUID().uuidString,
                categoryId: categoryId,
                titleEnglish: "Morning Dua",
                textArabic: "Arabic dua",
                textTransliteration: "Transliteration",
                textTranslation: "Translation"
            )
        ]
    }

    func getDua(id: String) async throws -> Dua? {
        return Dua(
            id: id,
            categoryId: "general",
            titleEnglish: "General Dua",
            textArabic: "Arabic",
            textTransliteration: "Trans",
            textTranslation: "Translation"
        )
    }

    func getMorningDhikr() async throws -> [Dua] {
        return [
            Dua(
                id: "morning_1",
                categoryId: "morning",
                titleEnglish: "Morning Dhikr",
                textArabic: "أَصْبَحْنَا وَأَصْبَحَ الْمُلْكُ لِلَّهِ",
                textTransliteration: "Asbahna wa asbahal mulku lillah",
                textTranslation: "We have entered a new morning and with it all dominion is Allah's"
            )
        ]
    }

    func getEveningDhikr() async throws -> [Dua] {
        return [
            Dua(
                id: "evening_1",
                categoryId: "evening",
                titleEnglish: "Evening Dhikr",
                textArabic: "أَمْسَيْنَا وَأَمْسَى الْمُلْكُ لِلَّهِ",
                textTransliteration: "Amsayna wa amsal mulku lillah",
                textTranslation: "We have entered a new evening and with it all dominion is Allah's"
            )
        ]
    }

    func getSleepDhikr() async throws -> [Dua] {
        return []
    }

    func getFavorites() async throws -> [Dua] {
        return favorites
    }

    func addToFavorites(_ dua: Dua) async throws {
        favorites.append(dua)
    }

    func removeFromFavorites(_ dua: Dua) async throws {
        favorites.removeAll { $0.id == dua.id }
    }

    func searchDuas(query: String) async throws -> [Dua] {
        return []
    }

    func markDhikrCompleted(_ dua: Dua, type: DhikrType) async throws {
        var completed = completedDhikr[type] ?? []
        completed.append(dua.id)
        completedDhikr[type] = completed
    }

    func getDhikrCompletionStatus(for type: DhikrType) async throws -> [String] {
        return completedDhikr[type] ?? []
    }

    func resetDhikrCompletion() async throws {
        completedDhikr = [:]
    }
}

// MARK: - Family Repository Tests

final class FamilyRepositoryProtocolTests: XCTestCase {

    func testFamilyRepositoryProtocolExists() {
        let mockRepo: any FamilyRepositoryProtocol = MockFamilyRepository()
        XCTAssertNotNil(mockRepo)
    }

    func testMockGetCircle() async throws {
        let mockRepo = MockFamilyRepository()

        let circle = try await mockRepo.getFamilyCircle()

        XCTAssertNotNil(circle)
    }
}

// MARK: - Mock Family Repository

final class MockFamilyRepository: FamilyRepositoryProtocol {
    private var circle: FamilyCircle?
    private var members: [FamilyMember] = []
    private var activities: [FamilyActivity] = []
    private var privacySettings = FamilyPrivacySettings.default

    func getFamilyCircle() async throws -> FamilyCircle? {
        return FamilyCircle(name: "Test Family", ownerId: "user1")
    }

    func createFamilyCircle(name: String) async throws -> FamilyCircle {
        let newCircle = FamilyCircle(name: name, ownerId: "currentUser")
        circle = newCircle
        return newCircle
    }

    func joinFamilyCircle(inviteCode: String) async throws {
        circle = FamilyCircle(name: "Joined Family", ownerId: "otherUser")
    }

    func leaveFamilyCircle() async throws {
        circle = nil
    }

    func getInviteCode() async throws -> String {
        return "ABC123"
    }

    func generateInviteLink() async throws -> URL {
        return URL(string: "https://safa.app/invite/ABC123")!
    }

    func getFamilyMembers() async throws -> [FamilyMember] {
        return [
            FamilyMember(
                circleId: UUID(),
                name: "Ahmed",
                currentStreak: 7
            )
        ]
    }

    func getMember(id memberId: String) async throws -> FamilyMember? {
        return FamilyMember(
            circleId: UUID(),
            name: "Ahmed",
            currentStreak: 7
        )
    }

    func removeMember(id memberId: String) async throws {
        // Mock implementation
    }

    func getActivityFeed(limit: Int) async throws -> [FamilyActivity] {
        return Array(activities.prefix(limit))
    }

    func shareActivity(_ activity: FamilyActivity) async throws {
        activities.append(activity)
    }

    func getPrivacySettings() async throws -> FamilyPrivacySettings {
        return privacySettings
    }

    func updatePrivacySettings(_ settings: FamilyPrivacySettings) async throws {
        privacySettings = settings
    }

    func setFamilyNotifications(enabled: Bool) async throws {
        // Mock implementation
    }
}

// MARK: - User Repository Tests

final class UserRepositoryTests: XCTestCase {

    // MARK: - UserStats Tests

    func testUserStatsDefaultValues() {
        // Given
        let stats = UserStats()

        // Then
        XCTAssertEqual(stats.totalHasanat, 0)
        XCTAssertEqual(stats.currentLevel, 1)
        XCTAssertTrue(stats.unlockedAchievements.isEmpty)
        XCTAssertEqual(stats.streakFreezes, 0)
    }

    func testUserStatsIsCodable() throws {
        // Given
        let original = UserStats(
            totalHasanat: 100,
            currentLevel: 2,
            unlockedAchievements: ["first_prayer"],
            lessonsCompleted: 5,
            totalPrayersLogged: 10,
            totalAyahsRead: 50,
            totalTasbeehCount: 100,
            streakFreezes: 2
        )

        // When
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(UserStats.self, from: data)

        // Then
        XCTAssertEqual(decoded.totalHasanat, 100)
        XCTAssertEqual(decoded.currentLevel, 2)
        XCTAssertEqual(decoded.unlockedAchievements, ["first_prayer"])
        XCTAssertEqual(decoded.streakFreezes, 2)
    }

    func testUserStatsLevelCalculation() {
        // Given/When/Then
        XCTAssertEqual(UserStats.calculateLevel(from: 0), 1)
        XCTAssertEqual(UserStats.calculateLevel(from: 99), 1)
        XCTAssertEqual(UserStats.calculateLevel(from: 100), 2)
        XCTAssertEqual(UserStats.calculateLevel(from: 500), 3)
    }

    func testUserStatsLevelTitle() {
        // Given/When/Then
        XCTAssertFalse(UserStats.levelTitle(for: 1).isEmpty)
        XCTAssertFalse(UserStats.levelTitle(for: 5).isEmpty)
        XCTAssertFalse(UserStats.levelTitle(for: 10).isEmpty)
    }

    // MARK: - Streak Tests

    func testStreakDefaultValues() {
        // Given
        let streak = Streak(type: .daily)

        // Then
        XCTAssertEqual(streak.type, .daily)
        XCTAssertEqual(streak.currentCount, 0)
        XCTAssertEqual(streak.longestCount, 0)
        XCTAssertNil(streak.lastActivityDate)
    }

    func testStreakIsCodable() throws {
        // Given
        var original = Streak(type: .prayer)
        original.currentCount = 7
        original.longestCount = 14
        original.lastActivityDate = Date()

        // When
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Streak.self, from: data)

        // Then
        XCTAssertEqual(decoded.type, .prayer)
        XCTAssertEqual(decoded.currentCount, 7)
        XCTAssertEqual(decoded.longestCount, 14)
        XCTAssertNotNil(decoded.lastActivityDate)
    }

    func testAllStreakTypesExist() {
        // Given
        let allTypes = StreakType.allCases

        // Then
        XCTAssertTrue(allTypes.contains(.daily))
        XCTAssertTrue(allTypes.contains(.prayer))
        XCTAssertTrue(allTypes.contains(.quran))
        XCTAssertTrue(allTypes.contains(.dhikr))
        XCTAssertTrue(allTypes.contains(.learning))
    }

    // MARK: - Achievement Tests

    func testAchievementAllAchievementsNotEmpty() {
        // Given
        let achievements = Achievement.allAchievements

        // Then
        XCTAssertFalse(achievements.isEmpty)
    }

    func testAchievementHasRequiredProperties() {
        // Given
        let achievement = Achievement.allAchievements.first!

        // Then
        XCTAssertFalse(achievement.id.isEmpty)
        XCTAssertFalse(achievement.title.isEmpty)
        XCTAssertFalse(achievement.description.isEmpty)
    }

    func testAchievementIsCodable() throws {
        // Given
        var original = Achievement.allAchievements.first!
        original.isUnlocked = true

        // When
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Achievement.self, from: data)

        // Then
        XCTAssertEqual(decoded.id, original.id)
        XCTAssertEqual(decoded.title, original.title)
        XCTAssertTrue(decoded.isUnlocked)
    }

    // MARK: - UserPreferences Tests

    func testUserPreferencesDefaultValues() {
        // Given
        let prefs = UserPreferences()

        // Then - should have reasonable defaults
        XCTAssertNotNil(prefs)
    }

    func testUserPreferencesIsCodable() throws {
        // Given
        let original = UserPreferences()

        // When
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(UserPreferences.self, from: data)

        // Then
        XCTAssertNotNil(decoded)
    }
}

// MARK: - Chat Repository Tests

final class ChatRepositoryTests: XCTestCase {

    // MARK: - Conversation Tests

    func testConversationDefaultValues() {
        // Given
        let conversation = Conversation()

        // Then
        XCTAssertNotNil(conversation.id)
        XCTAssertNil(conversation.title)
        XCTAssertEqual(conversation.messageCount, 0)
    }

    func testConversationDisplayTitle() {
        // Given
        let withTitle = Conversation(title: "My Chat")
        let withoutTitle = Conversation()

        // Then
        XCTAssertEqual(withTitle.displayTitle, "My Chat")
        XCTAssertEqual(withoutTitle.displayTitle, "New Conversation")
    }

    func testConversationIsCodable() throws {
        // Given
        let original = Conversation(
            title: "Test Conversation",
            messageCount: 5
        )

        // When
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Conversation.self, from: data)

        // Then
        XCTAssertEqual(decoded.id, original.id)
        XCTAssertEqual(decoded.title, "Test Conversation")
        XCTAssertEqual(decoded.messageCount, 5)
    }

    func testConversationIsHashable() {
        // Given
        let conv1 = Conversation(title: "Chat 1")
        let conv2 = Conversation(title: "Chat 2")
        let conv1Copy = conv1

        // Then
        XCTAssertNotEqual(conv1.hashValue, conv2.hashValue)
        XCTAssertEqual(conv1.hashValue, conv1Copy.hashValue)
    }

    // MARK: - ChatMessage Tests

    func testChatMessageUserRole() {
        // Given
        let message = ChatMessage(
            conversationId: UUID(),
            role: .user,
            content: "Hello"
        )

        // Then
        XCTAssertTrue(message.isUser)
        XCTAssertFalse(message.isAssistant)
    }

    func testChatMessageAssistantRole() {
        // Given
        let message = ChatMessage(
            conversationId: UUID(),
            role: .assistant,
            content: "Hi there!"
        )

        // Then
        XCTAssertFalse(message.isUser)
        XCTAssertTrue(message.isAssistant)
    }

    func testChatMessageIsCodable() throws {
        // Given
        let conversationId = UUID()
        let original = ChatMessage(
            conversationId: conversationId,
            role: .user,
            content: "Test message"
        )

        // When
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(ChatMessage.self, from: data)

        // Then
        XCTAssertEqual(decoded.id, original.id)
        XCTAssertEqual(decoded.conversationId, conversationId)
        XCTAssertEqual(decoded.role, .user)
        XCTAssertEqual(decoded.content, "Test message")
    }

    func testChatMessageRoles() {
        // Given
        let roles: [ChatMessage.Role] = [.user, .assistant, .system]

        // Then
        XCTAssertEqual(roles.count, 3)
    }

    // MARK: - ChatError Tests

    func testChatErrorDescriptions() {
        // Given
        let errors: [ChatError] = [
            .modelNotLoaded,
            .generationFailed("test reason"),
            .conversationNotFound,
            .messageTooLong
        ]

        // Then - all should have descriptions
        for error in errors {
            XCTAssertNotNil(error.errorDescription)
            XCTAssertFalse(error.errorDescription!.isEmpty)
        }
    }

    // MARK: - ChatTopic Tests

    func testChatTopicAllCases() {
        // Given
        let topics = ChatTopic.allCases

        // Then
        XCTAssertTrue(topics.contains(.general))
        XCTAssertTrue(topics.contains(.quran))
        XCTAssertTrue(topics.contains(.hadith))
        XCTAssertTrue(topics.contains(.fiqh))
        XCTAssertTrue(topics.contains(.seerah))
    }

    func testChatTopicDisplayName() {
        // Given
        let topic = ChatTopic.quran

        // Then
        XCTAssertEqual(topic.displayName, "Quran")
    }

    // MARK: - ChatContext Tests

    func testChatContextDefault() {
        // Given
        let context = ChatContext(topic: .general)

        // Then
        XCTAssertEqual(context.topic, .general)
        XCTAssertNil(context.surahNumber)
        XCTAssertNil(context.ayahNumber)
        XCTAssertNil(context.hadithId)
    }

    func testChatContextWithSurah() {
        // Given
        let context = ChatContext(
            topic: .quran,
            surahNumber: 2,
            ayahNumber: 255
        )

        // Then
        XCTAssertEqual(context.surahNumber, 2)
        XCTAssertEqual(context.ayahNumber, 255)
    }

    // MARK: - SuggestedQuestion Tests

    func testSuggestedQuestionProperties() {
        // Given
        let question = SuggestedQuestion(
            text: "What is the importance of prayer?",
            category: "Basics"
        )

        // Then
        XCTAssertFalse(question.id.isEmpty)
        XCTAssertEqual(question.text, "What is the importance of prayer?")
        XCTAssertEqual(question.category, "Basics")
    }
}
