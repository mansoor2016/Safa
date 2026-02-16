// MARK: - QuranRepository.swift
// PURPOSE: Implementation of Quran data access and progress tracking
// DEPENDENCIES: CoreData, SQLiteService, QuranRepositoryProtocol

import Foundation
import CoreData
import OSLog

final class QuranRepository: QuranRepositoryProtocol {
    // MARK: - Dependencies
    private let coreData: CoreDataStack
    private let sqlite = SQLiteService.shared

    // MARK: - Storage Keys
    private let bookmarksKey = AppConstants.StorageKeys.quranBookmarks
    private let progressKey = AppConstants.StorageKeys.quranProgress

    // MARK: - Cache
    private var cachedSurahs: [Surah]?
    private var cachedJuz: [Juz]?

    // MARK: - Init
    init(coreData: CoreDataStack) {
        self.coreData = coreData
    }

    // MARK: - Surahs

    func getAllSurahs() async throws -> [Surah] {
        // Return cached if available
        if let cached = cachedSurahs {
            return cached
        }

        // Try loading from SQLite database
        do {
            let surahs = try sqlite.loadAllSurahs()
            if !surahs.isEmpty {
                cachedSurahs = surahs
                return surahs
            }
        } catch {
            Log.quran.error("SQLite load failed, using fallback: \(error)")
        }

        // Fallback to static data
        return Surah.allSurahs
    }

    func getSurah(number: Int) async throws -> Surah? {
        let surahs = try await getAllSurahs()
        return surahs.first { $0.id == number }
    }

    // MARK: - Ayahs

    func getAyahs(forSurah surahNumber: Int) async throws -> [Ayah] {
        // Try loading from SQLite database
        do {
            let ayahs = try sqlite.loadAyahs(forSurah: surahNumber)
            if !ayahs.isEmpty {
                return ayahs
            }
        } catch {
            Log.quran.error("SQLite ayah load failed, using fallback: \(error)")
        }

        // Fallback to static data
        guard let surah = try await getSurah(number: surahNumber) else {
            return []
        }

        // Return placeholder ayahs for Al-Fatiha
        if surahNumber == 1 {
            return Ayah.alFatiha
        }

        // Generate placeholder ayahs for other surahs
        return (1...surah.ayahCount).map { ayahNumber in
            Ayah(
                surahNumber: surahNumber,
                ayahNumber: ayahNumber,
                textArabic: "آية \(ayahNumber)",
                textTranslation: "Ayah \(ayahNumber) of Surah \(surah.nameEnglish)",
                juzNumber: surah.juzStart,
                pageNumber: 1
            )
        }
    }

    func getAyah(surah surahNumber: Int, ayah ayahNumber: Int) async throws -> Ayah? {
        let ayahs = try await getAyahs(forSurah: surahNumber)
        return ayahs.first { $0.ayahNumber == ayahNumber }
    }

    func searchAyahs(query: String) async throws -> [Ayah] {
        // Try full-text search on SQLite database
        do {
            let results = try sqlite.searchAyahs(query: query)
            if !results.isEmpty {
                return results
            }
        } catch {
            Log.quran.error("SQLite search failed, using fallback: \(error)")
        }

        // Fallback to searching static data
        let fatiha = Ayah.alFatiha
        return fatiha.filter { ayah in
            ayah.textTranslation.localizedCaseInsensitiveContains(query) ||
            ayah.textArabic.contains(query)
        }
    }

    // MARK: - Bookmarks

    func getBookmarks() async throws -> [QuranBookmark] {
        guard let data = UserDefaults.standard.data(forKey: bookmarksKey),
              let bookmarks = try? JSONDecoder().decode([QuranBookmark].self, from: data) else {
            return []
        }
        return bookmarks.sorted { $0.createdAt > $1.createdAt }
    }

    func addBookmark(surah: Int, ayah: Int) async throws {
        var bookmarks = try await getBookmarks()

        // Check if already bookmarked
        guard !bookmarks.contains(where: { $0.surahNumber == surah && $0.ayahNumber == ayah }) else {
            return
        }

        let bookmark = QuranBookmark(surahNumber: surah, ayahNumber: ayah)
        bookmarks.append(bookmark)

        let data = try JSONEncoder().encode(bookmarks)
        UserDefaults.standard.set(data, forKey: bookmarksKey)
    }

    func removeBookmark(surah: Int, ayah: Int) async throws {
        var bookmarks = try await getBookmarks()
        bookmarks.removeAll { $0.surahNumber == surah && $0.ayahNumber == ayah }

        let data = try JSONEncoder().encode(bookmarks)
        UserDefaults.standard.set(data, forKey: bookmarksKey)
    }

    func isBookmarked(surah: Int, ayah: Int) async throws -> Bool {
        let bookmarks = try await getBookmarks()
        return bookmarks.contains { $0.surahNumber == surah && $0.ayahNumber == ayah }
    }

    // MARK: - Progress

    func getReadingProgress() async throws -> QuranProgress? {
        guard let data = UserDefaults.standard.data(forKey: progressKey),
              let progress = try? JSONDecoder().decode(QuranProgress.self, from: data) else {
            return nil
        }
        return progress
    }

    func updateProgress(surah: Int, ayah: Int) async throws {
        var progress = try await getReadingProgress() ?? QuranProgress()
        progress.lastSurah = surah
        progress.lastAyah = ayah
        progress.lastReadAt = Date()
        progress.totalAyahsRead += 1

        // Check for Khatm (completing the Quran)
        if surah == 114 && ayah == 6 {
            progress.khatmCount += 1
        }

        let data = try JSONEncoder().encode(progress)
        UserDefaults.standard.set(data, forKey: progressKey)
    }

    // MARK: - Surah Read Progress

    private let surahReadProgressKeyPrefix = "surahReadProgress_"

    func getSurahReadProgress(surahNumber: Int) async throws -> SurahReadProgress? {
        let key = "\(surahReadProgressKeyPrefix)\(surahNumber)"
        guard let data = UserDefaults.standard.data(forKey: key),
              let progress = try? JSONDecoder().decode(SurahReadProgress.self, from: data) else {
            return nil
        }
        return progress
    }

    func markAyahRead(surahNumber: Int, ayahNumber: Int, totalAyahs: Int) async throws {
        let key = "\(surahReadProgressKeyPrefix)\(surahNumber)"
        var progress = (try await getSurahReadProgress(surahNumber: surahNumber))
            ?? SurahReadProgress(surahNumber: surahNumber, totalAyahs: totalAyahs)
        progress.readAyahs.insert(ayahNumber)
        let data = try JSONEncoder().encode(progress)
        UserDefaults.standard.set(data, forKey: key)
    }

    // MARK: - Bookmark Note

    func updateBookmarkNote(surahNumber: Int, ayahNumber: Int, note: String?) async throws {
        var bookmarks = try await getBookmarks()
        guard let index = bookmarks.firstIndex(where: { $0.surahNumber == surahNumber && $0.ayahNumber == ayahNumber }) else {
            return
        }
        let existing = bookmarks[index]
        let normalizedNote = (note?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true) ? nil : note
        let updated = QuranBookmark(
            id: existing.id,
            surahNumber: existing.surahNumber,
            ayahNumber: existing.ayahNumber,
            createdAt: existing.createdAt,
            note: normalizedNote
        )
        bookmarks[index] = updated
        let data = try JSONEncoder().encode(bookmarks)
        UserDefaults.standard.set(data, forKey: bookmarksKey)
    }

    // MARK: - Completed Surahs

    func getCompletedSurahNumbers() async throws -> Set<Int> {
        let defaults = UserDefaults.standard
        let allKeys = defaults.dictionaryRepresentation().keys
        var completed = Set<Int>()

        for key in allKeys {
            if key.hasPrefix(surahReadProgressKeyPrefix) {
                guard let data = defaults.data(forKey: key),
                      let progress = try? JSONDecoder().decode(SurahReadProgress.self, from: data),
                      progress.isComplete else {
                    continue
                }
                completed.insert(progress.surahNumber)
            }
        }

        return completed
    }

    func resetSurahProgress(surahNumber: Int) async throws {
        let key = "\(surahReadProgressKeyPrefix)\(surahNumber)"
        UserDefaults.standard.removeObject(forKey: key)
    }

    // MARK: - Juz

    func getJuz(number: Int) async throws -> Juz? {
        let allJuz = try await getAllJuz()
        return allJuz.first { $0.id == number }
    }

    func getAllJuz() async throws -> [Juz] {
        // Return cached if available
        if let cached = cachedJuz {
            return cached
        }

        // Try loading from SQLite database
        do {
            let juz = try sqlite.loadAllJuz()
            if !juz.isEmpty {
                cachedJuz = juz
                return juz
            }
        } catch {
            Log.quran.error("SQLite juz load failed, using fallback: \(error)")
        }

        // Fallback to static data
        return Juz.allJuz
    }
}

// MARK: - Static Data Extensions

extension Surah {
    static let allSurahs: [Surah] = [
        Surah(id: 1, nameArabic: "الفاتحة", nameEnglish: "Al-Fatiha", nameTransliteration: "Al-Fatihah", revelationType: .meccan, ayahCount: 7, juzStart: 1),
        Surah(id: 2, nameArabic: "البقرة", nameEnglish: "Al-Baqara", nameTransliteration: "Al-Baqarah", revelationType: .medinan, ayahCount: 286, juzStart: 1),
        Surah(id: 3, nameArabic: "آل عمران", nameEnglish: "Aal-E-Imran", nameTransliteration: "Ali 'Imran", revelationType: .medinan, ayahCount: 200, juzStart: 3),
        Surah(id: 4, nameArabic: "النساء", nameEnglish: "An-Nisa", nameTransliteration: "An-Nisa", revelationType: .medinan, ayahCount: 176, juzStart: 4),
        Surah(id: 5, nameArabic: "المائدة", nameEnglish: "Al-Maeda", nameTransliteration: "Al-Ma'idah", revelationType: .medinan, ayahCount: 120, juzStart: 6),
        Surah(id: 6, nameArabic: "الأنعام", nameEnglish: "Al-Anaam", nameTransliteration: "Al-An'am", revelationType: .meccan, ayahCount: 165, juzStart: 7),
        Surah(id: 7, nameArabic: "الأعراف", nameEnglish: "Al-Araf", nameTransliteration: "Al-A'raf", revelationType: .meccan, ayahCount: 206, juzStart: 8),
        Surah(id: 8, nameArabic: "الأنفال", nameEnglish: "Al-Anfal", nameTransliteration: "Al-Anfal", revelationType: .medinan, ayahCount: 75, juzStart: 9),
        Surah(id: 9, nameArabic: "التوبة", nameEnglish: "At-Tawba", nameTransliteration: "At-Tawbah", revelationType: .medinan, ayahCount: 129, juzStart: 10),
        Surah(id: 10, nameArabic: "يونس", nameEnglish: "Yunus", nameTransliteration: "Yunus", revelationType: .meccan, ayahCount: 109, juzStart: 11),
        // Remaining surahs abbreviated for now - will be loaded from database
        Surah(id: 112, nameArabic: "الإخلاص", nameEnglish: "Al-Ikhlas", nameTransliteration: "Al-Ikhlas", revelationType: .meccan, ayahCount: 4, juzStart: 30),
        Surah(id: 113, nameArabic: "الفلق", nameEnglish: "Al-Falaq", nameTransliteration: "Al-Falaq", revelationType: .meccan, ayahCount: 5, juzStart: 30),
        Surah(id: 114, nameArabic: "الناس", nameEnglish: "An-Nas", nameTransliteration: "An-Nas", revelationType: .meccan, ayahCount: 6, juzStart: 30),
    ]
}

extension Ayah {
    static let alFatiha: [Ayah] = [
        Ayah(surahNumber: 1, ayahNumber: 1, textArabic: "بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ", textTranslation: "In the name of Allah, the Entirely Merciful, the Especially Merciful.", textTransliteration: "Bismillah ir-Rahman ir-Raheem", juzNumber: 1, pageNumber: 1),
        Ayah(surahNumber: 1, ayahNumber: 2, textArabic: "الْحَمْدُ لِلَّهِ رَبِّ الْعَالَمِينَ", textTranslation: "All praise is due to Allah, Lord of the worlds.", textTransliteration: "Alhamdu lillahi Rabbil 'aalameen", juzNumber: 1, pageNumber: 1),
        Ayah(surahNumber: 1, ayahNumber: 3, textArabic: "الرَّحْمَٰنِ الرَّحِيمِ", textTranslation: "The Entirely Merciful, the Especially Merciful.", textTransliteration: "Ar-Rahman ir-Raheem", juzNumber: 1, pageNumber: 1),
        Ayah(surahNumber: 1, ayahNumber: 4, textArabic: "مَالِكِ يَوْمِ الدِّينِ", textTranslation: "Sovereign of the Day of Recompense.", textTransliteration: "Maliki yawmid-Deen", juzNumber: 1, pageNumber: 1),
        Ayah(surahNumber: 1, ayahNumber: 5, textArabic: "إِيَّاكَ نَعْبُدُ وَإِيَّاكَ نَسْتَعِينُ", textTranslation: "It is You we worship and You we ask for help.", textTransliteration: "Iyyaka na'budu wa iyyaka nasta'een", juzNumber: 1, pageNumber: 1),
        Ayah(surahNumber: 1, ayahNumber: 6, textArabic: "اهْدِنَا الصِّرَاطَ الْمُسْتَقِيمَ", textTranslation: "Guide us to the straight path.", textTransliteration: "Ihdinas-Siratal-Mustaqeem", juzNumber: 1, pageNumber: 1),
        Ayah(surahNumber: 1, ayahNumber: 7, textArabic: "صِرَاطَ الَّذِينَ أَنْعَمْتَ عَلَيْهِمْ غَيْرِ الْمَغْضُوبِ عَلَيْهِمْ وَلَا الضَّالِّينَ", textTranslation: "The path of those upon whom You have bestowed favor, not of those who have earned [Your] anger or of those who are astray.", textTransliteration: "Siratal-latheena an'amta 'alayhim, ghayril-maghdubi 'alayhim walad-daalleen", juzNumber: 1, pageNumber: 1),
    ]
}

extension Juz {
    static let allJuz: [Juz] = [
        Juz(id: 1, startSurah: 1, startAyah: 1, endSurah: 2, endAyah: 141),
        Juz(id: 2, startSurah: 2, startAyah: 142, endSurah: 2, endAyah: 252),
        Juz(id: 3, startSurah: 2, startAyah: 253, endSurah: 3, endAyah: 92),
        Juz(id: 4, startSurah: 3, startAyah: 93, endSurah: 4, endAyah: 23),
        Juz(id: 5, startSurah: 4, startAyah: 24, endSurah: 4, endAyah: 147),
        Juz(id: 6, startSurah: 4, startAyah: 148, endSurah: 5, endAyah: 81),
        Juz(id: 7, startSurah: 5, startAyah: 82, endSurah: 6, endAyah: 110),
        Juz(id: 8, startSurah: 6, startAyah: 111, endSurah: 7, endAyah: 87),
        Juz(id: 9, startSurah: 7, startAyah: 88, endSurah: 8, endAyah: 40),
        Juz(id: 10, startSurah: 8, startAyah: 41, endSurah: 9, endAyah: 92),
        // Abbreviated - will be loaded from database
        Juz(id: 30, startSurah: 78, startAyah: 1, endSurah: 114, endAyah: 6),
    ]
}
