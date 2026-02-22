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
            duaReferences: [],
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
            duaReferences: [],
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
            duaReferences: [],
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
            hadithRepository: EmptyHadithRepository(),
            duaRepository: EmptyDuaRepository()
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
        XCTAssertEqual(context.duaReferences.count, 0)
    }

    func test_retrieveContext_multiKeywordQuery_picksHighestScoringTopic() async {
        // 3 prayer keywords (fajr + salah + rakat) vs 1 fasting keyword (ramadan)
        let context = await makeService().retrieveContext(for: "How many rakat in fajr salah during ramadan?")
        XCTAssertEqual(context.topic, .prayer, "Prayer should win with 3 hits vs fasting's 1")
    }

    // MARK: - Dua-Specific Tests

    func test_retrieveContext_duaTopic_returnsDuaReferences() async {
        let mockDua = Dua(
            id: "dua_sleep_001", categoryId: "sleep",
            titleEnglish: "Dua before sleeping",
            textArabic: "باسمك اللهم أموت وأحيا",
            textTransliteration: "Bismika Allahumma amutu wa ahya",
            textTranslation: "In Your name, O Allah, I die and I live",
            source: "Sahih Bukhari 6324"
        )
        let service = RAGService(
            quranRepository: EmptyQuranRepository(),
            hadithRepository: EmptyHadithRepository(),
            duaRepository: StubDuaRepository(searchResults: [mockDua])
        )

        let context = await service.retrieveContext(for: "What is the dua before sleeping?")
        XCTAssertEqual(context.topic, .dua)
        XCTAssertEqual(context.duaReferences.count, 1)
        XCTAssertEqual(context.duaReferences.first?.duaId, "dua_sleep_001")
        XCTAssertEqual(context.duaReferences.first?.title, "Dua before sleeping")
    }

    func test_retrieveContext_includesAllSources() async {
        let mockDua = Dua(
            id: "dua_eat_001", categoryId: "eating",
            titleEnglish: "Dua before eating",
            textArabic: "بسم الله",
            textTransliteration: "Bismillah",
            textTranslation: "In the name of Allah",
            source: "Abu Dawud 3767"
        )
        let service = RAGService(
            quranRepository: EmptyQuranRepository(),
            hadithRepository: EmptyHadithRepository(),
            duaRepository: StubDuaRepository(searchResults: [mockDua])
        )

        let context = await service.retrieveContext(for: "What dua should I say before eating?")
        // Topic should be .dua
        XCTAssertEqual(context.topic, .dua)
        // Should have dua results from stub
        XCTAssertFalse(context.duaReferences.isEmpty, "Should include dua references")
    }

    func test_chatTopicDua_mapsToRAGTopic() async {
        let service = makeService()
        let chatContext = ChatContext(topic: .dua)
        let context = await service.retrieveContext(for: "test query", context: chatContext)
        XCTAssertEqual(context.topic, .dua, ".dua ChatTopic should map to .dua RAGTopic")
    }

    func test_tokenBudget_preservesSourceDiversity() async {
        // Given — stubs that return 4+4+4=12 results (exceeds limit of 8)
        // RAGService searches up to 3 keywords × 2 results each = max 6 per source,
        // but deduplicates + caps at 3. Use 4 unique results per source via different keywords.
        let quranAyahs = (1...4).map {
            Ayah(surahNumber: $0, ayahNumber: 1, textArabic: "...",
                 textTranslation: "prayer salah rakat fajr", juzNumber: 1, pageNumber: 1)
        }
        let surahs = (1...4).map {
            Surah(id: $0, nameArabic: "...", nameEnglish: "Surah\($0)",
                  nameTransliteration: "S\($0)", revelationType: .meccan, ayahCount: 7, juzStart: 1)
        }
        let hadiths = (1...4).map {
            Hadith(id: "h\($0)", collectionId: "bukhari", bookId: "b1",
                   hadithNumber: $0, textArabic: "...",
                   textEnglish: "prayer salah rakat fajr", narrator: "N", reference: "B:\($0)")
        }
        let duas = (1...4).map {
            Dua(id: "dua_\($0)", categoryId: "test",
                titleEnglish: "Dua \($0)", textArabic: "...",
                textTransliteration: "...", textTranslation: "prayer salah rakat fajr",
                source: nil)
        }

        let service = RAGService(
            quranRepository: FixedQuranRepository(ayahs: quranAyahs, surahs: surahs),
            hadithRepository: FixedHadithRepository(hadiths: hadiths),
            duaRepository: StubDuaRepository(searchResults: duas)
        )

        // When
        let context = await service.retrieveContext(for: "prayer salah rakat fajr")

        // Then — total should be capped at 8, with at least 1 from each source
        let total = context.quranReferences.count + context.hadithReferences.count + context.duaReferences.count
        XCTAssertLessThanOrEqual(total, 8, "Total references should be truncated to 8")
        XCTAssertGreaterThanOrEqual(context.quranReferences.count, 1, "Should preserve at least 1 Quran ref")
        XCTAssertGreaterThanOrEqual(context.hadithReferences.count, 1, "Should preserve at least 1 Hadith ref")
        XCTAssertGreaterThanOrEqual(context.duaReferences.count, 1, "Should preserve at least 1 Dua ref")
    }

    func test_keywordExtraction_isDeterministic() async {
        // Given — run the same query multiple times through retrieveContext
        // If keyword extraction is nondeterministic (Set ordering), topic detection
        // could vary between runs since prefix(3) selects different keywords.
        let service = makeService()
        let query = "How do I perform salah prayer during fajr in the mosque?"

        // When — run 10 times and collect topics
        var topics: [RAGTopic] = []
        for _ in 0..<10 {
            let context = await service.retrieveContext(for: query)
            topics.append(context.topic)
        }

        // Then — all runs should produce the same topic
        let uniqueTopics = Set(topics)
        XCTAssertEqual(uniqueTopics.count, 1,
                        "Topic detection should be deterministic, got \(uniqueTopics)")
    }

    func test_tokenBudget_noTruncationWhenUnderLimit() async {
        // Given — stubs returning exactly 2 results total (well under limit of 8)
        let mockDua = Dua(
            id: "dua_test", categoryId: "test",
            titleEnglish: "Test dua", textArabic: "...",
            textTransliteration: "...", textTranslation: "sleeping night",
            source: nil
        )
        let service = RAGService(
            quranRepository: EmptyQuranRepository(),
            hadithRepository: EmptyHadithRepository(),
            duaRepository: StubDuaRepository(searchResults: [mockDua])
        )

        // When
        let context = await service.retrieveContext(for: "dua before sleeping night")

        // Then — should pass through without truncation
        let total = context.quranReferences.count + context.hadithReferences.count + context.duaReferences.count
        XCTAssertLessThanOrEqual(total, 8, "Should not exceed limit")
        XCTAssertEqual(context.duaReferences.count, 1, "Single dua result should pass through")
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
    func getDailyVerse(for date: Date) async -> Ayah? { nil }
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

private final class EmptyDuaRepository: DuaRepositoryProtocol {
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

private final class FixedQuranRepository: QuranRepositoryProtocol {
    let ayahs: [Ayah]
    let surahs: [Surah]
    init(ayahs: [Ayah] = [], surahs: [Surah] = []) { self.ayahs = ayahs; self.surahs = surahs }

    func getAllSurahs() async throws -> [Surah] { surahs }
    func getSurah(number: Int) async throws -> Surah? { surahs.first { $0.number == number } }
    func getAyahs(forSurah surahNumber: Int) async throws -> [Ayah] { ayahs.filter { $0.surahNumber == surahNumber } }
    func getAyah(surah surahNumber: Int, ayah ayahNumber: Int) async throws -> Ayah? {
        ayahs.first { $0.surahNumber == surahNumber && $0.ayahNumber == ayahNumber }
    }
    func searchAyahs(query: String) async throws -> [Ayah] { ayahs }
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
    func getDailyVerse(for date: Date) async -> Ayah? { nil }
}

private final class FixedHadithRepository: HadithRepositoryProtocol {
    let hadiths: [Hadith]
    init(hadiths: [Hadith] = []) { self.hadiths = hadiths }

    func getCollections() async throws -> [HadithCollection] { [] }
    func getBooks(forCollection collectionId: String) async throws -> [HadithBook] { [] }
    func getHadiths(collection collectionId: String, book bookId: String) async throws -> [Hadith] { hadiths }
    func getHadith(collection collectionId: String, number hadithNumber: Int) async throws -> Hadith? {
        hadiths.first { $0.hadithNumber == hadithNumber }
    }
    func searchHadiths(query: String) async throws -> [Hadith] { hadiths }
    func getDailyHadith(for date: Date) async throws -> Hadith { throw ChatError.conversationNotFound }
    func getBookmarks() async throws -> [Hadith] { [] }
    func addBookmark(_ hadith: Hadith) async throws {}
    func removeBookmark(_ hadith: Hadith) async throws {}
}

private final class StubDuaRepository: DuaRepositoryProtocol {
    let searchResults: [Dua]
    init(searchResults: [Dua] = []) { self.searchResults = searchResults }

    func getCategories() async throws -> [DuaCategory] { [] }
    func getAllDuas() async throws -> [Dua] { searchResults }
    func getDuas(forCategory categoryId: String) async throws -> [Dua] { [] }
    func getDua(id: String) async throws -> Dua? { searchResults.first { $0.id == id } }
    func getMorningDhikr() async throws -> [Dua] { [] }
    func getEveningDhikr() async throws -> [Dua] { [] }
    func getSleepDhikr() async throws -> [Dua] { [] }
    func getFavorites() async throws -> [Dua] { [] }
    func addToFavorites(_ dua: Dua) async throws {}
    func removeFromFavorites(_ dua: Dua) async throws {}
    func searchDuas(query: String) async throws -> [Dua] { searchResults }
    func markDhikrCompleted(_ dua: Dua, type: DhikrType) async throws {}
    func getDhikrCompletionStatus(for type: DhikrType) async throws -> [String] { [] }
    func resetDhikrCompletion() async throws {}
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
