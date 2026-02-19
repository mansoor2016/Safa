// MARK: - RAGServiceTests.swift
// PURPOSE: Unit tests for RAG (Retrieval-Augmented Generation) service
// DEPENDENCIES: XCTest

import XCTest
@testable import Safa

final class RAGServiceTests: XCTestCase {

    // MARK: - RAG Context Tests

    func testRAGContextFormattedContextEmpty() {
        let context = RAGContext(
            quranReferences: [],
            hadithReferences: [],
            topic: .general
        )

        XCTAssertTrue(context.isEmpty, "Empty context should return true for isEmpty")
        XCTAssertTrue(context.formattedContext.isEmpty, "Formatted context should be empty")
    }

    func testRAGContextFormattedContextWithQuran() {
        let quranRef = QuranReference(
            surahNumber: 2,
            surahName: "Al-Baqarah",
            ayahNumber: 255,
            arabic: "اللَّهُ لَا إِلَٰهَ إِلَّا هُوَ الْحَيُّ الْقَيُّومُ",
            translation: "Allah - there is no deity except Him, the Ever-Living, the Sustainer of existence.",
            relevanceScore: 0.9
        )

        let context = RAGContext(
            quranReferences: [quranRef],
            hadithReferences: [],
            topic: .quran
        )

        XCTAssertFalse(context.isEmpty, "Context with references should not be empty")
        XCTAssertTrue(context.formattedContext.contains("Al-Baqarah"), "Should contain surah name")
        XCTAssertTrue(context.formattedContext.contains("2:255"), "Should contain reference")
    }

    func testRAGContextFormattedContextWithHadith() {
        let hadithRef = HadithReference(
            collection: "bukhari",
            hadithNumber: 1,
            narrator: "Umar ibn Al-Khattab",
            text: "Actions are but by intentions.",
            grading: "Sahih",
            relevanceScore: 0.95
        )

        let context = RAGContext(
            quranReferences: [],
            hadithReferences: [hadithRef],
            topic: .hadith
        )

        XCTAssertFalse(context.isEmpty, "Context with references should not be empty")
        XCTAssertTrue(context.formattedContext.contains("bukhari"), "Should contain collection name")
        XCTAssertTrue(context.formattedContext.contains("intentions"), "Should contain hadith text")
    }

    // MARK: - retrieveContext Integration Tests
    // These test the actual RAGService async code path (topic detection + repo search)

    private func makeService() -> RAGService {
        RAGService(
            quranRepository: EmptyQuranRepository(),
            hadithRepository: EmptyHadithRepository()
        )
    }

    func test_retrieveContext_detectsPrayerTopic() async {
        let context = await makeService().retrieveContext(for: "How do I perform salah prayer?")
        XCTAssertEqual(context.topic, .prayer)
    }

    func test_retrieveContext_detectsWuduTopic() async {
        let context = await makeService().retrieveContext(for: "What are the steps of wudu?")
        XCTAssertEqual(context.topic, .wudu)
    }

    func test_retrieveContext_detectsFastingTopic() async {
        let context = await makeService().retrieveContext(for: "When should I break my fast during Ramadan?")
        XCTAssertEqual(context.topic, .fasting)
    }

    func test_retrieveContext_returnsGeneralForUnrelatedQuery() async {
        // Avoid "hello" — contains "hell" (aqeedah keyword) via substring match
        let context = await makeService().retrieveContext(for: "What time is dinner tonight?")
        XCTAssertEqual(context.topic, .general)
    }

    func test_retrieveContext_emptyRepos_returnsEmptyReferences() async {
        let context = await makeService().retrieveContext(for: "Tell me about prayer and salah")
        XCTAssertTrue(context.isEmpty, "Empty repos should yield empty references")
        XCTAssertEqual(context.quranReferences.count, 0)
        XCTAssertEqual(context.hadithReferences.count, 0)
    }

    func test_retrieveContext_multiKeywordQuery_picksHighestScoringTopic() async {
        // 3 prayer keywords (fajr + salah + rakat) vs 1 fasting keyword (ramadan)
        let context = await makeService().retrieveContext(for: "How many rakat in fajr salah during ramadan?")
        XCTAssertEqual(context.topic, .prayer, "Prayer should win with 3 hits vs fasting's 1")
    }
}

// MARK: - Stub Repositories for RAGService Tests

private final class EmptyQuranRepository: QuranRepositoryProtocol {
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

private final class EmptyHadithRepository: HadithRepositoryProtocol {
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

// MARK: - LLM Service Tests

final class LLMServiceTests: XCTestCase {

    var sut: LLMService!

    override func setUp() {
        super.setUp()
        sut = LLMService()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    func testLLMServiceInitialization() {
        XCTAssertNotNil(sut, "LLM service should initialize")
        XCTAssertFalse(sut.isModelLoaded, "Model should not be loaded initially")
    }

    func testLLMAvailabilityMessage() {
        let availability = sut.availability

        // Availability message should not be empty
        XCTAssertFalse(availability.userMessage.isEmpty, "Availability message should not be empty")
    }

    func testLLMAvailabilityTypes() {
        // Test all availability cases have proper messages
        let available = LLMAvailability.available
        XCTAssertTrue(available.isAvailable, "Available should return true for isAvailable")

        let requiresOS = LLMAvailability.requiresNewerOS(minimumVersion: "26.0")
        XCTAssertFalse(requiresOS.isAvailable, "RequiresNewerOS should return false for isAvailable")
        XCTAssertTrue(requiresOS.userMessage.contains("26.0"), "Message should include version")

        let unsupported = LLMAvailability.unsupportedDevice
        XCTAssertFalse(unsupported.isAvailable, "Unsupported should return false for isAvailable")

        let notConfigured = LLMAvailability.notConfigured
        XCTAssertFalse(notConfigured.isAvailable, "NotConfigured should return false for isAvailable")
    }
}

// MARK: - LLM Error Tests

final class LLMErrorTests: XCTestCase {

    func testUnavailableErrorDescription() {
        let error = LLMError.unavailable("Test message")
        XCTAssertEqual(error.errorDescription, "Test message")
    }

    func testModelLoadFailedErrorDescription() {
        let error = LLMError.modelLoadFailed
        XCTAssertNotNil(error.errorDescription)
        XCTAssertTrue(error.errorDescription?.contains("load") ?? false)
    }

    func testGenerationFailedErrorDescription() {
        let error = LLMError.generationFailed("Network timeout")
        XCTAssertNotNil(error.errorDescription)
        XCTAssertTrue(error.errorDescription?.contains("Network timeout") ?? false)
    }
}
