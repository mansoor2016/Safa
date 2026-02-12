// MARK: - RepositoryTests.swift
// PURPOSE: Mock repository implementations for use in unit tests
// DEPENDENCIES: XCTest, Safa

import XCTest
@testable import Safa

// MARK: - Mock Prayer Repository

final class StatefulMockPrayerRepository: PrayerRepositoryProtocol {
    private var logs: [PrayerLog] = []

    func getPrayers(for date: Date, location: Coordinates, method: CalculationMethod, madhab: Madhab? = nil) async throws -> [PrayerTime] {
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

    func getSurahReadProgress(surahNumber: Int) async throws -> SurahReadProgress? { nil }
    func markAyahRead(surahNumber: Int, ayahNumber: Int, totalAyahs: Int) async throws {}
    func updateBookmarkNote(surahNumber: Int, ayahNumber: Int, note: String?) async throws {}
    func getCompletedSurahNumbers() async throws -> Set<Int> { [] }
    func resetSurahProgress(surahNumber: Int) async throws {}
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

    func getAllDuas() async throws -> [Dua] {
        return [
            Dua(
                id: "test_1",
                categoryId: "morning",
                titleEnglish: "Morning Dua",
                textArabic: "Arabic dua",
                textTransliteration: "Transliteration",
                textTranslation: "Translation"
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
