// MARK: - HadithRepository.swift
// PURPOSE: Implementation of Hadith data access
// DEPENDENCIES: CoreData, SQLiteService, HadithRepositoryProtocol

import Foundation
import CoreData

final class HadithRepository: HadithRepositoryProtocol {
    // MARK: - Dependencies
    private let coreData: CoreDataStack
    private let sqlite = SQLiteService.shared

    // MARK: - Storage Keys
    private let bookmarksKey = "com.safa.hadith.bookmarks"

    // MARK: - Cache
    private var cachedCollections: [HadithCollection]?

    // MARK: - Init
    init(coreData: CoreDataStack) {
        self.coreData = coreData
    }

    // MARK: - Collections

    func getCollections() async throws -> [HadithCollection] {
        // Return cached if available
        if let cached = cachedCollections {
            return cached
        }

        // Try loading from SQLite database
        do {
            let collections = try sqlite.loadAllCollections()
            if !collections.isEmpty {
                cachedCollections = collections
                return collections
            }
        } catch {
            print("HadithRepository: SQLite load failed, using fallback: \(error)")
        }

        // Fallback to static data
        return HadithCollection.allCollections
    }

    func getBooks(forCollection collectionId: String) async throws -> [HadithBook] {
        // Try loading from SQLite database
        do {
            let books = try sqlite.loadBooks(forCollection: collectionId)
            if !books.isEmpty {
                return books
            }
        } catch {
            print("HadithRepository: SQLite books load failed, using fallback: \(error)")
        }

        // Fallback to static data for Bukhari
        if collectionId == "bukhari" {
            return HadithBook.bukhariBooks
        }
        return []
    }

    func getHadiths(collection collectionId: String, book bookId: String) async throws -> [Hadith] {
        // Try loading from SQLite database
        do {
            let hadiths = try sqlite.loadHadiths(forBook: bookId)
            if !hadiths.isEmpty {
                return hadiths
            }
        } catch {
            print("HadithRepository: SQLite hadiths load failed, using fallback: \(error)")
        }

        // Fallback to static data
        return Hadith.sampleHadiths.filter { $0.collectionId == collectionId && $0.bookId == bookId }
    }

    func getHadith(collection collectionId: String, number hadithNumber: Int) async throws -> Hadith? {
        // For now, use static data (would need specific query for single hadith)
        return Hadith.sampleHadiths.first { $0.collectionId == collectionId && $0.hadithNumber == hadithNumber }
    }

    // MARK: - Search

    func searchHadiths(query: String) async throws -> [Hadith] {
        // Try full-text search on SQLite database
        do {
            let results = try sqlite.searchHadiths(query: query)
            if !results.isEmpty {
                return results
            }
        } catch {
            print("HadithRepository: SQLite search failed, using fallback: \(error)")
        }

        // Fallback to searching static data
        return Hadith.sampleHadiths.filter { hadith in
            hadith.textEnglish.localizedCaseInsensitiveContains(query) ||
            hadith.textArabic.contains(query)
        }
    }

    // MARK: - Daily Hadith

    func getDailyHadith(for date: Date) async throws -> Hadith {
        let calendar = Calendar.current
        let dayOfYear = calendar.ordinality(of: .day, in: .year, for: date) ?? 1

        // Try loading from SQLite database
        do {
            if let hadith = try sqlite.getRandomHadith(seed: dayOfYear) {
                return hadith
            }
        } catch {
            print("HadithRepository: SQLite daily hadith failed, using fallback: \(error)")
        }

        // Fallback to static data
        let index = (dayOfYear - 1) % Hadith.sampleHadiths.count
        return Hadith.sampleHadiths[index]
    }

    // MARK: - Bookmarks

    func getBookmarks() async throws -> [Hadith] {
        let bookmarkIds = getBookmarkIds()
        return Hadith.sampleHadiths.filter { bookmarkIds.contains($0.id) }
            .map { hadith in
                var bookmarked = hadith
                bookmarked.isBookmarked = true
                return bookmarked
            }
    }

    func addBookmark(_ hadith: Hadith) async throws {
        var ids = getBookmarkIds()
        guard !ids.contains(hadith.id) else { return }
        ids.append(hadith.id)
        saveBookmarkIds(ids)
    }

    func removeBookmark(_ hadith: Hadith) async throws {
        var ids = getBookmarkIds()
        ids.removeAll { $0 == hadith.id }
        saveBookmarkIds(ids)
    }

    // MARK: - Private Helpers

    private func getBookmarkIds() -> [String] {
        UserDefaults.standard.stringArray(forKey: bookmarksKey) ?? []
    }

    private func saveBookmarkIds(_ ids: [String]) {
        UserDefaults.standard.set(ids, forKey: bookmarksKey)
    }
}

// MARK: - Static Data Extensions

extension HadithCollection {
    static let allCollections: [HadithCollection] = [
        .sahihBukhari,
        .sahihMuslim,
        HadithCollection(
            id: "abudawud",
            nameEnglish: "Sunan Abu Dawood",
            nameArabic: "سنن أبي داود",
            compilerName: "Imam Abu Dawood",
            totalHadiths: 5274,
            totalBooks: 43
        ),
        HadithCollection(
            id: "tirmidhi",
            nameEnglish: "Jami` at-Tirmidhi",
            nameArabic: "جامع الترمذي",
            compilerName: "Imam Tirmidhi",
            totalHadiths: 3956,
            totalBooks: 49
        ),
        HadithCollection(
            id: "nasai",
            nameEnglish: "Sunan an-Nasa'i",
            nameArabic: "سنن النسائي",
            compilerName: "Imam Nasa'i",
            totalHadiths: 5761,
            totalBooks: 51
        ),
        HadithCollection(
            id: "ibnmajah",
            nameEnglish: "Sunan Ibn Majah",
            nameArabic: "سنن ابن ماجه",
            compilerName: "Imam Ibn Majah",
            totalHadiths: 4341,
            totalBooks: 37
        ),
    ]
}

extension HadithBook {
    static let bukhariBooks: [HadithBook] = [
        HadithBook(id: "bukhari_1", collectionId: "bukhari", bookNumber: 1, nameEnglish: "Revelation", nameArabic: "بدء الوحي", hadithCount: 7),
        HadithBook(id: "bukhari_2", collectionId: "bukhari", bookNumber: 2, nameEnglish: "Belief", nameArabic: "الإيمان", hadithCount: 51),
        HadithBook(id: "bukhari_3", collectionId: "bukhari", bookNumber: 3, nameEnglish: "Knowledge", nameArabic: "العلم", hadithCount: 76),
        HadithBook(id: "bukhari_4", collectionId: "bukhari", bookNumber: 4, nameEnglish: "Ablutions (Wudu')", nameArabic: "الوضوء", hadithCount: 113),
        HadithBook(id: "bukhari_5", collectionId: "bukhari", bookNumber: 5, nameEnglish: "Bathing (Ghusl)", nameArabic: "الغسل", hadithCount: 46),
    ]
}

extension Hadith {
    static let sampleHadiths: [Hadith] = [
        Hadith(
            id: "bukhari_1",
            collectionId: "bukhari",
            bookId: "bukhari_1",
            hadithNumber: 1,
            textArabic: "إِنَّمَا الأَعْمَالُ بِالنِّيَّاتِ، وَإِنَّمَا لِكُلِّ امْرِئٍ مَا نَوَى",
            textEnglish: "The reward of deeds depends upon the intentions and every person will get the reward according to what he has intended.",
            narrator: "Umar bin Al-Khattab",
            grading: .sahih,
            reference: "Bukhari 1"
        ),
        Hadith(
            id: "bukhari_6",
            collectionId: "bukhari",
            bookId: "bukhari_2",
            hadithNumber: 6,
            textArabic: "الْمُسْلِمُ مَنْ سَلِمَ الْمُسْلِمُونَ مِنْ لِسَانِهِ وَيَدِهِ",
            textEnglish: "A Muslim is the one who avoids harming Muslims with his tongue and hands.",
            narrator: "Abdullah bin Amr",
            grading: .sahih,
            reference: "Bukhari 6"
        ),
        Hadith(
            id: "bukhari_7",
            collectionId: "bukhari",
            bookId: "bukhari_2",
            hadithNumber: 7,
            textArabic: "وَالْمُهَاجِرُ مَنْ هَجَرَ مَا نَهَى اللَّهُ عَنْهُ",
            textEnglish: "And a Muhajir (emigrant) is the one who gives up (abandons) all what Allah has forbidden.",
            narrator: "Abdullah bin Amr",
            grading: .sahih,
            reference: "Bukhari 7"
        ),
        Hadith(
            id: "muslim_45",
            collectionId: "muslim",
            bookId: "muslim_1",
            hadithNumber: 45,
            textArabic: "لَا يُؤْمِنُ أَحَدُكُمْ حَتَّى يُحِبَّ لِأَخِيهِ مَا يُحِبُّ لِنَفْسِهِ",
            textEnglish: "None of you truly believes until he loves for his brother what he loves for himself.",
            narrator: "Anas bin Malik",
            grading: .sahih,
            reference: "Muslim 45"
        ),
    ]
}
