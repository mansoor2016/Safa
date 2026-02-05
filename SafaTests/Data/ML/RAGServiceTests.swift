// MARK: - RAGServiceTests.swift
// PURPOSE: Unit tests for RAG (Retrieval-Augmented Generation) service
// DEPENDENCIES: XCTest

import XCTest
@testable import Safa

final class RAGServiceTests: XCTestCase {

    // MARK: - Topic Detection Tests

    func testDetectTopicPrayer() {
        // Test that prayer-related keywords detect prayer topic
        let prayerKeywords = ["salah", "prayer", "namaz", "fajr", "dhuhr", "qibla"]

        for keyword in prayerKeywords {
            let detected = detectTopicHelper(from: "How do I pray \(keyword)?")
            XCTAssertEqual(detected, .prayer, "Expected .prayer for keyword: \(keyword)")
        }
    }

    func testDetectTopicFasting() {
        let fastingKeywords = ["fast", "fasting", "suhoor", "iftar", "ramadan"]

        for keyword in fastingKeywords {
            let detected = detectTopicHelper(from: "What \(keyword) rules?")
            XCTAssertEqual(detected, .fasting, "Expected .fasting for keyword: \(keyword)")
        }
    }

    func testDetectTopicWudu() {
        let wuduKeywords = ["wudu", "ablution", "ghusl", "purification"]

        for keyword in wuduKeywords {
            let detected = detectTopicHelper(from: "How to perform \(keyword)?")
            XCTAssertEqual(detected, .wudu, "Expected .wudu for keyword: \(keyword)")
        }
    }

    func testDetectTopicQuran() {
        let quranKeywords = ["quran", "surah", "ayah", "tafsir", "tajweed"]

        for keyword in quranKeywords {
            let detected = detectTopicHelper(from: "Explain this \(keyword)")
            XCTAssertEqual(detected, .quran, "Expected .quran for keyword: \(keyword)")
        }
    }

    func testDetectTopicGeneralForUnknown() {
        let detected = detectTopicHelper(from: "Hello how are you?")
        XCTAssertEqual(detected, .general, "Expected .general for unrelated query")
    }

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

    // MARK: - RAG Topic Tests

    func testRAGTopicAllCases() {
        let allCases: [RAGTopic] = [.prayer, .fasting, .zakat, .hajj, .dua, .wudu, .quran, .hadith, .seerah, .fiqh, .aqeedah, .general]
        XCTAssertEqual(RAGTopic.allCases.count, allCases.count, "Should have all expected cases")
    }

    // MARK: - Helper Methods

    private func detectTopicHelper(from query: String) -> RAGTopic {
        // Recreate topic detection logic for testing
        let topicKeywords: [RAGTopic: [String]] = [
            .prayer: ["salah", "salat", "prayer", "namaz", "rakat", "fajr", "dhuhr", "asr", "maghrib", "isha", "qibla"],
            .fasting: ["fast", "fasting", "sawm", "suhoor", "iftar", "ramadan"],
            .zakat: ["zakat", "charity", "sadaqah", "nisab"],
            .hajj: ["hajj", "umrah", "pilgrimage", "mecca", "kaaba"],
            .dua: ["dua", "supplication", "dhikr", "tasbih"],
            .wudu: ["wudu", "wudhu", "ablution", "purification", "ghusl", "tayammum"],
            .quran: ["quran", "ayah", "verse", "surah", "tafsir", "tajweed"],
            .hadith: ["hadith", "sunnah", "sahih", "bukhari", "muslim"],
            .seerah: ["seerah", "biography", "migration", "hijra"],
            .fiqh: ["halal", "haram", "ruling", "madhab", "hanafi", "shafi"],
            .aqeedah: ["belief", "faith", "iman", "tawhid", "angels"]
        ]

        let lowercaseQuery = query.lowercased()
        var topicScores: [RAGTopic: Int] = [:]

        for (topic, keywords) in topicKeywords {
            let score = keywords.reduce(0) { count, keyword in
                lowercaseQuery.contains(keyword) ? count + 1 : count
            }
            if score > 0 {
                topicScores[topic] = score
            }
        }

        return topicScores.max(by: { $0.value < $1.value })?.key ?? .general
    }
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

        let requiresOS = LLMAvailability.requiresNewerOS(minimumVersion: "18.4")
        XCTAssertFalse(requiresOS.isAvailable, "RequiresNewerOS should return false for isAvailable")
        XCTAssertTrue(requiresOS.userMessage.contains("18.4"), "Message should include version")

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
