// MARK: - Hadith.swift
// PURPOSE: Domain entities for Hadith collections, books, and individual hadiths

import Foundation

// MARK: - Hadith Collection
struct HadithCollection: Identifiable, Codable, Hashable {
    let id: String
    let nameEnglish: String
    let nameArabic: String
    let compilerName: String
    let totalHadiths: Int
    let totalBooks: Int

    static let sahihBukhari = HadithCollection(
        id: "bukhari",
        nameEnglish: "Sahih al-Bukhari",
        nameArabic: "صحيح البخاري",
        compilerName: "Imam Bukhari",
        totalHadiths: 7563,
        totalBooks: 97
    )

    static let sahihMuslim = HadithCollection(
        id: "muslim",
        nameEnglish: "Sahih Muslim",
        nameArabic: "صحيح مسلم",
        compilerName: "Imam Muslim",
        totalHadiths: 7563,
        totalBooks: 56
    )
}

// MARK: - Hadith Book
struct HadithBook: Identifiable, Codable, Hashable {
    let id: String
    let collectionId: String
    let bookNumber: Int
    let nameEnglish: String
    let nameArabic: String
    let hadithCount: Int
}

// MARK: - Hadith
struct Hadith: Identifiable, Codable, Hashable {
    let id: String
    let collectionId: String
    let bookId: String
    let hadithNumber: Int
    let textArabic: String
    let textEnglish: String
    let narratorChain: String? // Isnad
    let narrator: String // Main narrator
    let grading: HadithGrading?
    let reference: String // e.g., "Bukhari 1"
    var isBookmarked: Bool

    init(
        id: String,
        collectionId: String,
        bookId: String,
        hadithNumber: Int,
        textArabic: String,
        textEnglish: String,
        narratorChain: String? = nil,
        narrator: String,
        grading: HadithGrading? = nil,
        reference: String,
        isBookmarked: Bool = false
    ) {
        self.id = id
        self.collectionId = collectionId
        self.bookId = bookId
        self.hadithNumber = hadithNumber
        self.textArabic = textArabic
        self.textEnglish = textEnglish
        self.narratorChain = narratorChain
        self.narrator = narrator
        self.grading = grading
        self.reference = reference
        self.isBookmarked = isBookmarked
    }
}

// MARK: - Hadith Grading
enum HadithGrading: String, Codable {
    case sahih = "Sahih"
    case hasan = "Hasan"
    case daif = "Da'if"
    case mawdu = "Mawdu'"
    case unknown = "Unknown"

    var displayName: String { rawValue }

    var description: String {
        switch self {
        case .sahih: return "Authentic"
        case .hasan: return "Good"
        case .daif: return "Weak"
        case .mawdu: return "Fabricated"
        case .unknown: return "Grading unknown"
        }
    }
}
