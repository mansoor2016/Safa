// MARK: - GoldenQATests.swift
// PURPOSE: Tier 1 golden QA pairs — deterministic, mocked LLM, CI-safe
// DEPENDENCIES: XCTest, Safa

import XCTest
@testable import Safa

final class GoldenQATests: XCTestCase {

    // MARK: - JSON Models

    private struct GoldenQA: Decodable {
        let id: String
        let question: String
        let expectedTopic: String
        let expectedSafetyDecision: String
    }

    // MARK: - Helpers

    private lazy var goldenQASet: [GoldenQA] = {
        guard let url = Bundle(for: type(of: self)).url(forResource: "GoldenQASet", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let items = try? JSONDecoder().decode([GoldenQA].self, from: data) else {
            XCTFail("Failed to load GoldenQASet.json")
            return []
        }
        return items
    }()

    private let inputSafety = InputSafetyService()

    private func makeRAGService() -> RAGService {
        RAGService(
            quranRepository: StubQuranRepository(),
            hadithRepository: StubHadithRepository(),
            duaRepository: StubDuaRepository()
        )
    }

    // MARK: - Safety Decision Tests

    func test_goldenQA_safetyDecisions() {
        for qa in goldenQASet {
            let decision = inputSafety.evaluate(qa.question, context: nil)
            let actual: String
            switch decision {
            case .allow: actual = "allow"
            case .allowWithCaution: actual = "allowWithCaution"
            case .decline: actual = "decline"
            }
            XCTAssertEqual(actual, qa.expectedSafetyDecision,
                           "[\(qa.id)] \"\(qa.question)\" — expected \(qa.expectedSafetyDecision) but got \(actual)")
        }
    }

    // MARK: - Topic Detection Tests

    func test_goldenQA_topicDetection() async {
        let ragService = makeRAGService()

        for qa in goldenQASet {
            let context = await ragService.retrieveContext(for: qa.question)
            XCTAssertEqual(context.topic.rawValue, qa.expectedTopic,
                           "[\(qa.id)] \"\(qa.question)\" — expected topic \(qa.expectedTopic) but got \(context.topic.rawValue)")
        }
    }
}

// MARK: - Stub Repositories (return empty — we're testing topic classification, not search)

private final class StubQuranRepository: QuranRepositoryProtocol {
    func getAllSurahs() async throws -> [Surah] { [] }
    func getSurah(number: Int) async throws -> Surah? { nil }
    func getAyahs(forSurah surahNumber: Int) async throws -> [Ayah] { [] }
    func getAyah(surah surahNumber: Int, ayah ayahNumber: Int) async throws -> Ayah? { nil }
    func searchAyahs(query: String) async throws -> [Ayah] { [] }
    func getBookmarks() async throws -> [QuranBookmark] { [] }
    func addBookmark(surah: Int, ayah: Int) async throws {}
    func removeBookmark(surah: Int, ayah: Int) async throws {}
    func isBookmarked(surah: Int, ayah: Int) async throws -> Bool { false }
    func getReadingProgress() async throws -> QuranProgress? { nil }
    func updateProgress(surah: Int, ayah: Int) async throws {}
    func getJuz(number: Int) async throws -> Juz? { nil }
    func getAllJuz() async throws -> [Juz] { [] }
    func getSurahReadProgress(surahNumber: Int) async throws -> SurahReadProgress? { nil }
    func markAyahRead(surahNumber: Int, ayahNumber: Int, totalAyahs: Int) async throws {}
    func updateBookmarkNote(surahNumber: Int, ayahNumber: Int, note: String?) async throws {}
    func getCompletedSurahNumbers() async throws -> Set<Int> { [] }
    func resetSurahProgress(surahNumber: Int) async throws {}
}

private final class StubHadithRepository: HadithRepositoryProtocol {
    func getCollections() async throws -> [HadithCollection] { [] }
    func getBooks(forCollection collectionId: String) async throws -> [HadithBook] { [] }
    func getHadiths(collection collectionId: String, book bookId: String) async throws -> [Hadith] { [] }
    func getHadith(collection collectionId: String, number hadithNumber: Int) async throws -> Hadith? { nil }
    func searchHadiths(query: String) async throws -> [Hadith] { [] }
    func getDailyHadith(for date: Date) async throws -> Hadith { throw ChatError.conversationNotFound }
    func getBookmarks() async throws -> [Hadith] { [] }
    func addBookmark(_ hadith: Hadith) async throws {}
    func removeBookmark(_ hadith: Hadith) async throws {}
}

private final class StubDuaRepository: DuaRepositoryProtocol {
    func getCategories() async throws -> [DuaCategory] { [] }
    func getAllDuas() async throws -> [Dua] { [] }
    func getDuas(forCategory categoryId: String) async throws -> [Dua] { [] }
    func getDua(id: String) async throws -> Dua? { nil }
    func getMorningDhikr() async throws -> [Dua] { [] }
    func getEveningDhikr() async throws -> [Dua] { [] }
    func getSleepDhikr() async throws -> [Dua] { [] }
    func getFavorites() async throws -> [Dua] { [] }
    func addToFavorites(_ dua: Dua) async throws {}
    func removeFromFavorites(_ dua: Dua) async throws {}
    func searchDuas(query: String) async throws -> [Dua] { [] }
    func markDhikrCompleted(_ dua: Dua, type: DhikrType) async throws {}
    func getDhikrCompletionStatus(for type: DhikrType) async throws -> [String] { [] }
    func resetDhikrCompletion() async throws {}
}
