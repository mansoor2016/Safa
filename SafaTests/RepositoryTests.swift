// MARK: - RepositoryTests.swift
// PURPOSE: Unit tests for repository implementations
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

    func testMockGetPrayerTimes() async {
        let mockRepo = MockPrayerRepository()
        let location = Coordinates(latitude: 40.7128, longitude: -74.0060) // New York

        let times = await mockRepo.getPrayerTimes(for: Date(), location: location)

        XCTAssertNotNil(times, "Should return prayer times")
        XCTAssertEqual(times?.fajr.type, .fajr)
        XCTAssertEqual(times?.dhuhr.type, .dhuhr)
        XCTAssertEqual(times?.asr.type, .asr)
        XCTAssertEqual(times?.maghrib.type, .maghrib)
        XCTAssertEqual(times?.isha.type, .isha)
    }

    func testMockLogPrayer() async {
        let mockRepo = MockPrayerRepository()

        await mockRepo.logPrayer(.fajr, at: Date())

        let logs = await mockRepo.getPrayerLogs(from: Date(), to: Date())
        XCTAssertFalse(logs.isEmpty, "Should have logged prayer")
    }
}

// MARK: - Mock Prayer Repository

final class MockPrayerRepository: PrayerRepositoryProtocol {
    private var logs: [PrayerLog] = []

    func getPrayerTimes(for date: Date, location: Coordinates) async -> DailyPrayerTimes? {
        let baseTime = Calendar.current.startOfDay(for: date)

        return DailyPrayerTimes(
            date: date,
            fajr: PrayerTime(type: .fajr, time: baseTime.addingTimeInterval(5 * 3600)),
            sunrise: PrayerTime(type: .sunrise, time: baseTime.addingTimeInterval(6.5 * 3600)),
            dhuhr: PrayerTime(type: .dhuhr, time: baseTime.addingTimeInterval(12 * 3600)),
            asr: PrayerTime(type: .asr, time: baseTime.addingTimeInterval(15 * 3600)),
            maghrib: PrayerTime(type: .maghrib, time: baseTime.addingTimeInterval(18 * 3600)),
            isha: PrayerTime(type: .isha, time: baseTime.addingTimeInterval(19.5 * 3600))
        )
    }

    func logPrayer(_ prayer: PrayerType, at date: Date) async {
        let log = PrayerLog(
            id: UUID(),
            prayerType: prayer,
            date: date,
            quality: .onTime,
            notes: nil
        )
        logs.append(log)
    }

    func getPrayerLogs(from startDate: Date, to endDate: Date) async -> [PrayerLog] {
        return logs.filter { log in
            log.date >= startDate && log.date <= endDate
        }
    }

    func getQiblaDirection(from location: Coordinates) -> Double {
        return 58.5 // Mock direction for NYC
    }
}

// MARK: - Quran Repository Tests

final class QuranRepositoryTests: XCTestCase {

    func testQuranRepositoryProtocolExists() {
        let mockRepo: any QuranRepositoryProtocol = MockQuranRepository()
        XCTAssertNotNil(mockRepo)
    }

    func testMockGetAllSurahs() async {
        let mockRepo = MockQuranRepository()

        let surahs = await mockRepo.getAllSurahs()

        XCTAssertFalse(surahs.isEmpty)
        XCTAssertEqual(surahs.first?.number, 1)
        XCTAssertEqual(surahs.first?.nameEnglish, "Al-Fatiha")
    }

    func testMockGetAyahsForSurah() async {
        let mockRepo = MockQuranRepository()

        let ayahs = await mockRepo.getAyahs(forSurah: 1)

        XCTAssertEqual(ayahs.count, 7, "Al-Fatiha should have 7 ayahs")
    }

    func testMockSearchAyahs() async {
        let mockRepo = MockQuranRepository()

        let results = await mockRepo.searchAyahs(query: "mercy")

        XCTAssertFalse(results.isEmpty, "Should find ayahs containing 'mercy'")
    }

    func testMockBookmarks() async {
        let mockRepo = MockQuranRepository()

        // Add bookmark
        await mockRepo.addBookmark(QuranBookmark(
            id: UUID(),
            surahNumber: 1,
            ayahNumber: 1,
            note: "Test",
            createdAt: Date()
        ))

        // Get bookmarks
        let bookmarks = await mockRepo.getBookmarks()

        XCTAssertFalse(bookmarks.isEmpty)
    }
}

// MARK: - Mock Quran Repository

final class MockQuranRepository: QuranRepositoryProtocol {
    private var bookmarks: [QuranBookmark] = []

    func getAllSurahs() async -> [Surah] {
        return [
            Surah(
                number: 1,
                nameArabic: "الفاتحة",
                nameEnglish: "Al-Fatiha",
                nameTranslation: "The Opening",
                ayahCount: 7,
                revelationType: .meccan
            ),
            Surah(
                number: 2,
                nameArabic: "البقرة",
                nameEnglish: "Al-Baqarah",
                nameTranslation: "The Cow",
                ayahCount: 286,
                revelationType: .medinan
            )
        ]
    }

    func getAyahs(forSurah surahNumber: Int) async -> [Ayah] {
        if surahNumber == 1 {
            return (1...7).map { number in
                Ayah(
                    id: UUID(),
                    surahNumber: 1,
                    ayahNumber: number,
                    arabicText: "Arabic text for ayah \(number)",
                    translation: "Translation for ayah \(number)"
                )
            }
        }
        return []
    }

    func searchAyahs(query: String) async -> [Ayah] {
        return [
            Ayah(
                id: UUID(),
                surahNumber: 1,
                ayahNumber: 1,
                arabicText: "Arabic",
                translation: "In the name of Allah, the Most Gracious, the Most Merciful"
            )
        ]
    }

    func getBookmarks() async -> [QuranBookmark] {
        return bookmarks
    }

    func addBookmark(_ bookmark: QuranBookmark) async {
        bookmarks.append(bookmark)
    }

    func removeBookmark(_ bookmark: QuranBookmark) async {
        bookmarks.removeAll { $0.id == bookmark.id }
    }

    func updateProgress(_ progress: ReadingProgress) async {
        // Mock implementation
    }

    func getReadingProgress() async -> ReadingProgress? {
        return ReadingProgress(
            lastSurah: 1,
            lastAyah: 5,
            lastReadDate: Date()
        )
    }
}

// MARK: - Hadith Repository Tests

final class HadithRepositoryTests: XCTestCase {

    func testHadithRepositoryProtocolExists() {
        let mockRepo: any HadithRepositoryProtocol = MockHadithRepository()
        XCTAssertNotNil(mockRepo)
    }

    func testMockGetCollections() async {
        let mockRepo = MockHadithRepository()

        let collections = await mockRepo.getCollections()

        XCTAssertFalse(collections.isEmpty)
        XCTAssertTrue(collections.contains { $0.name == "Sahih Bukhari" })
    }

    func testMockGetDailyHadith() async {
        let mockRepo = MockHadithRepository()

        let hadith = await mockRepo.getDailyHadith()

        XCTAssertNotNil(hadith)
        XCTAssertFalse(hadith?.arabicText.isEmpty ?? true)
    }
}

// MARK: - Mock Hadith Repository

final class MockHadithRepository: HadithRepositoryProtocol {

    func getCollections() async -> [HadithCollection] {
        return [
            HadithCollection(
                id: "bukhari",
                name: "Sahih Bukhari",
                arabicName: "صحيح البخاري",
                hadithCount: 7563,
                description: "The most authentic collection"
            ),
            HadithCollection(
                id: "muslim",
                name: "Sahih Muslim",
                arabicName: "صحيح مسلم",
                hadithCount: 7500,
                description: "Second most authentic collection"
            )
        ]
    }

    func getHadiths(forCollection collectionId: String) async -> [Hadith] {
        return [
            Hadith(
                id: UUID(),
                collectionId: collectionId,
                bookNumber: 1,
                hadithNumber: 1,
                arabicText: "Arabic hadith text",
                englishText: "English translation",
                narrator: "Abu Hurairah",
                grade: .sahih
            )
        ]
    }

    func searchHadiths(query: String) async -> [Hadith] {
        return []
    }

    func getDailyHadith() async -> Hadith? {
        return Hadith(
            id: UUID(),
            collectionId: "bukhari",
            bookNumber: 1,
            hadithNumber: 1,
            arabicText: "إنما الأعمال بالنيات",
            englishText: "Actions are judged by intentions",
            narrator: "Umar ibn Al-Khattab",
            grade: .sahih
        )
    }

    func getBookmarks() async -> [HadithBookmark] {
        return []
    }

    func addBookmark(_ bookmark: HadithBookmark) async {}
    func removeBookmark(_ bookmark: HadithBookmark) async {}
}

// MARK: - Learning Repository Tests

final class LearningRepositoryTests: XCTestCase {

    func testLearningRepositoryProtocolExists() {
        let mockRepo: any LearningRepositoryProtocol = MockLearningRepository()
        XCTAssertNotNil(mockRepo)
    }

    func testMockGetTracks() async {
        let mockRepo = MockLearningRepository()

        let tracks = await mockRepo.getTracks()

        XCTAssertFalse(tracks.isEmpty)
        XCTAssertTrue(tracks.contains { $0.title.contains("Arabic") })
    }

    func testMockGetLessons() async {
        let mockRepo = MockLearningRepository()

        let lessons = await mockRepo.getLessons(forTrack: "arabic")

        XCTAssertFalse(lessons.isEmpty)
    }

    func testMockMarkLessonComplete() async {
        let mockRepo = MockLearningRepository()

        await mockRepo.markLessonComplete("lesson1")

        let progress = await mockRepo.getLessonProgress()
        XCTAssertTrue(progress.completedLessonIds.contains("lesson1"))
    }
}

// MARK: - Mock Learning Repository

final class MockLearningRepository: LearningRepositoryProtocol {
    private var completedLessons: Set<String> = []

    func getTracks() async -> [LearningTrack] {
        return [
            LearningTrack(
                id: "arabic",
                title: "Arabic Alphabet",
                description: "Learn the Arabic letters",
                iconName: "textformat",
                lessonCount: 28,
                estimatedMinutes: 120,
                difficulty: .beginner
            ),
            LearningTrack(
                id: "tajweed",
                title: "Tajweed Basics",
                description: "Learn Quran recitation rules",
                iconName: "waveform",
                lessonCount: 15,
                estimatedMinutes: 180,
                difficulty: .intermediate
            )
        ]
    }

    func getLessons(forTrack trackId: String) async -> [Lesson] {
        if trackId == "arabic" {
            return (1...5).map { index in
                Lesson(
                    id: "lesson\(index)",
                    trackId: trackId,
                    title: "Lesson \(index)",
                    description: "Description",
                    durationMinutes: 10,
                    order: index,
                    steps: []
                )
            }
        }
        return []
    }

    func markLessonComplete(_ lessonId: String) async {
        completedLessons.insert(lessonId)
    }

    func getLessonProgress() async -> LearningProgress {
        return LearningProgress(
            completedLessonIds: completedLessons,
            currentTrackId: "arabic",
            currentLessonId: "lesson1",
            totalTimeSpentMinutes: 30
        )
    }
}

// MARK: - Dua Repository Tests

final class DuaRepositoryTests: XCTestCase {

    func testDuaRepositoryProtocolExists() {
        let mockRepo: any DuaRepositoryProtocol = MockDuaRepository()
        XCTAssertNotNil(mockRepo)
    }

    func testMockGetCategories() async {
        let mockRepo = MockDuaRepository()

        let categories = await mockRepo.getCategories()

        XCTAssertFalse(categories.isEmpty)
    }

    func testMockGetMorningAdhkar() async {
        let mockRepo = MockDuaRepository()

        let adhkar = await mockRepo.getAdhkar(type: .morning)

        XCTAssertFalse(adhkar.isEmpty)
    }
}

// MARK: - Mock Dua Repository

final class MockDuaRepository: DuaRepositoryProtocol {

    func getCategories() async -> [DuaCategory] {
        return [
            DuaCategory(
                id: "morning",
                name: "Morning",
                arabicName: "الصباح",
                iconName: "sunrise",
                duaCount: 10
            ),
            DuaCategory(
                id: "evening",
                name: "Evening",
                arabicName: "المساء",
                iconName: "sunset",
                duaCount: 10
            )
        ]
    }

    func getDuas(forCategory categoryId: String) async -> [Dua] {
        return [
            Dua(
                id: UUID(),
                category: categoryId,
                arabicText: "Arabic dua",
                transliteration: "Transliteration",
                translation: "Translation",
                reference: "Quran 1:1",
                benefits: "Benefits",
                repetitions: 1
            )
        ]
    }

    func getAdhkar(type: AdhkarType) async -> [Adhkar] {
        return [
            Adhkar(
                id: UUID(),
                type: type,
                arabicText: "Arabic",
                transliteration: "Trans",
                translation: "Translation",
                count: 3,
                reference: "Sahih Bukhari"
            )
        ]
    }

    func saveTasbeehSession(_ session: TasbeehSession) async {}
    func getTasbeehSessions() async -> [TasbeehSession] { return [] }
}

// MARK: - Family Repository Tests

final class FamilyRepositoryTests: XCTestCase {

    func testFamilyRepositoryProtocolExists() {
        let mockRepo: any FamilyRepositoryProtocol = MockFamilyRepository()
        XCTAssertNotNil(mockRepo)
    }

    func testMockGetCircle() async {
        let mockRepo = MockFamilyRepository()

        let circle = await mockRepo.getCircle()

        XCTAssertNotNil(circle)
    }
}

// MARK: - Mock Family Repository

final class MockFamilyRepository: FamilyRepositoryProtocol {

    func getCircle() async -> FamilyCircle? {
        return FamilyCircle(
            name: "Test Family",
            ownerId: "user1"
        )
    }

    func createCircle(name: String) async -> FamilyCircle? {
        return FamilyCircle(name: name, ownerId: "currentUser")
    }

    func joinCircle(inviteCode: String) async -> Bool {
        return true
    }

    func leaveCircle() async {}

    func getMembers() async -> [FamilyMember] {
        return [
            FamilyMember(
                userId: "user1",
                displayName: "Ahmed",
                hasanat: 500,
                currentStreak: 7
            )
        ]
    }

    func getActivities() async -> [FamilyActivity] {
        return []
    }

    func updatePrivacySettings(_ settings: FamilyPrivacySettings) async {}

    func getPrivacySettings() async -> FamilyPrivacySettings {
        return .default
    }
}
