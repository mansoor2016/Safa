// MARK: - SystemPromptsTests.swift
// PURPOSE: Unit tests for AI system prompts
// DEPENDENCIES: XCTest

import XCTest
@testable import Safa

final class SystemPromptsTests: XCTestCase {

    // MARK: - Base Prompt Tests

    func testIslamicCompanionPromptNotEmpty() {
        let prompt = SystemPrompts.islamicCompanion
        XCTAssertFalse(prompt.isEmpty, "Islamic companion prompt should not be empty")
    }

    func testIslamicCompanionPromptContainsGuidelines() {
        let prompt = SystemPrompts.islamicCompanion

        XCTAssertTrue(prompt.contains("Islamic Knowledge"), "Should contain Islamic knowledge section")
        XCTAssertTrue(prompt.contains("Madhab Neutrality"), "Should contain madhab neutrality section")
        XCTAssertTrue(prompt.contains("Citation Format"), "Should contain citation format section")
        XCTAssertTrue(prompt.contains("Boundaries"), "Should contain boundaries section")
    }

    func testIslamicCompanionPromptContainsCitationFormats() {
        let prompt = SystemPrompts.islamicCompanion

        XCTAssertTrue(prompt.contains("Quran"), "Should mention Quran citation format")
        XCTAssertTrue(prompt.contains("Hadith"), "Should mention Hadith citation format")
        XCTAssertTrue(prompt.contains("Sahih Bukhari"), "Should mention Sahih Bukhari")
        XCTAssertTrue(prompt.contains("Sahih Muslim"), "Should mention Sahih Muslim")
    }

    func testIslamicCompanionPromptContainsResponseStyle() {
        let prompt = SystemPrompts.islamicCompanion

        XCTAssertTrue(prompt.contains("warm"), "Should mention warm response style")
        XCTAssertTrue(prompt.contains("encouraging"), "Should mention encouraging tone")
        XCTAssertTrue(prompt.contains("Arabic"), "Should mention Arabic terms")
        XCTAssertTrue(prompt.contains("transliteration"), "Should mention transliteration")
    }

    // MARK: - Contextual Prompt Tests

    func testQuranContextPromptNotEmpty() {
        let prompt = SystemPrompts.quranContext
        XCTAssertFalse(prompt.isEmpty, "Quran context prompt should not be empty")
    }

    func testQuranContextContainsRelevantInfo() {
        let prompt = SystemPrompts.quranContext

        XCTAssertTrue(prompt.contains("Tafsir"), "Should mention tafsir")
        XCTAssertTrue(prompt.contains("Arabic"), "Should mention Arabic")
        XCTAssertTrue(prompt.contains("revelation"), "Should mention revelation circumstances")
    }

    func testPrayerContextPromptNotEmpty() {
        let prompt = SystemPrompts.prayerContext
        XCTAssertFalse(prompt.isEmpty, "Prayer context prompt should not be empty")
    }

    func testPrayerContextContainsRelevantInfo() {
        let prompt = SystemPrompts.prayerContext

        XCTAssertTrue(prompt.contains("prayer"), "Should mention prayer")
        XCTAssertTrue(prompt.contains("wudu") || prompt.contains("Qada"), "Should mention related topics")
    }

    func testRamadanContextPromptNotEmpty() {
        let prompt = SystemPrompts.ramadanContext
        XCTAssertFalse(prompt.isEmpty, "Ramadan context prompt should not be empty")
    }

    func testRamadanContextContainsRelevantInfo() {
        let prompt = SystemPrompts.ramadanContext

        XCTAssertTrue(prompt.contains("Fasting") || prompt.contains("fast"), "Should mention fasting")
        XCTAssertTrue(prompt.contains("Suhoor") || prompt.contains("Iftar"), "Should mention meals")
        XCTAssertTrue(prompt.contains("Taraweeh"), "Should mention Taraweeh")
    }

    func testLearningContextPromptNotEmpty() {
        let prompt = SystemPrompts.learningContext
        XCTAssertFalse(prompt.isEmpty, "Learning context prompt should not be empty")
    }

    // MARK: - Prompt Builder Tests

    func testBuildPromptWithoutContext() {
        let builder = PromptBuilder()
        let prompt = builder.build()

        XCTAssertFalse(prompt.isEmpty)
        XCTAssertTrue(prompt.contains(SystemPrompts.islamicCompanion))
    }

    func testBuildPromptWithQuranContext() {
        let context = ChatContext(topic: .quran, surahNumber: 2, ayahNumber: 255)
        let builder = PromptBuilder(context: context)
        let prompt = builder.build()

        XCTAssertTrue(prompt.contains("Quran"), "Should include Quran context")
        XCTAssertTrue(prompt.contains("Surah 2"), "Should include surah number")
        XCTAssertTrue(prompt.contains("Ayah 255"), "Should include ayah number")
    }

    func testBuildPromptWithHadithContext() {
        let context = ChatContext(topic: .hadith)
        let builder = PromptBuilder(context: context)
        let prompt = builder.build()

        XCTAssertTrue(prompt.contains("hadith"), "Should include hadith context")
    }

    func testBuildPromptWithUserHistory() {
        let context = ChatContext(topic: .general)
        let history = ["Asked about prayer times", "Discussed fasting rules"]
        let builder = PromptBuilder(context: context, userHistory: history)
        let prompt = builder.build()

        XCTAssertTrue(prompt.contains("prayer times"), "Should include user history")
        XCTAssertTrue(prompt.contains("fasting rules"), "Should include user history")
    }

    // MARK: - Decline Template Tests

    func testPoliticalDeclineNotEmpty() {
        let decline = SystemPrompts.politicalDecline
        XCTAssertFalse(decline.isEmpty)
    }

    func testPoliticalDeclineIsPolite() {
        let decline = SystemPrompts.politicalDecline

        XCTAssertTrue(decline.contains("appreciate") || decline.contains("understand"),
                     "Decline should be polite")
        XCTAssertTrue(decline.contains("help") || decline.contains("assist"),
                     "Should offer alternative help")
    }

    func testSectarianDeclineNotEmpty() {
        let decline = SystemPrompts.sectarianDecline
        XCTAssertFalse(decline.isEmpty)
    }

    func testPersonalFatwaDeclineRecommendsScholar() {
        let decline = SystemPrompts.personalFatwaDecline

        XCTAssertTrue(decline.contains("scholar"), "Should recommend consulting a scholar")
        XCTAssertTrue(decline.contains("personal") || decline.contains("specific"),
                     "Should acknowledge personal nature")
    }

    // MARK: - Response Template Tests

    func testDuaResponseTemplate() {
        let response = ResponseTemplates.duaResponse(
            title: "Dua Before Eating",
            arabic: "بِسْمِ اللَّهِ",
            transliteration: "Bismillah",
            translation: "In the name of Allah",
            source: "Sahih Bukhari",
            benefit: "Brings blessing to food"
        )

        XCTAssertTrue(response.contains("Dua Before Eating"), "Should include title")
        XCTAssertTrue(response.contains("بِسْمِ اللَّهِ"), "Should include Arabic")
        XCTAssertTrue(response.contains("Bismillah"), "Should include transliteration")
        XCTAssertTrue(response.contains("In the name of Allah"), "Should include translation")
        XCTAssertTrue(response.contains("Sahih Bukhari"), "Should include source")
        XCTAssertTrue(response.contains("blessing"), "Should include benefit")
    }

    func testDuaResponseTemplateWithoutBenefit() {
        let response = ResponseTemplates.duaResponse(
            title: "Test Dua",
            arabic: "Arabic",
            transliteration: "Trans",
            translation: "Translation",
            source: "Source"
        )

        XCTAssertFalse(response.contains("Benefit:"), "Should not include benefit section when nil")
    }

    func testFiqhResponseTemplate() {
        let positions = [
            (madhab: "Hanafi", view: "View A"),
            (madhab: "Shafi'i", view: "View B")
        ]

        let response = ResponseTemplates.fiqhResponse(
            topic: "Test Topic",
            positions: positions,
            recommendation: "Follow your local scholar"
        )

        XCTAssertTrue(response.contains("Test Topic"), "Should include topic")
        XCTAssertTrue(response.contains("Hanafi"), "Should include madhab names")
        XCTAssertTrue(response.contains("Shafi'i"), "Should include madhab names")
        XCTAssertTrue(response.contains("View A"), "Should include views")
        XCTAssertTrue(response.contains("View B"), "Should include views")
        XCTAssertTrue(response.contains("local scholar"), "Should include recommendation")
    }
}

// MARK: - Chat Context Tests

final class ChatContextTests: XCTestCase {

    func testChatContextInitialization() {
        let context = ChatContext(topic: .quran, surahNumber: 1, ayahNumber: 1)

        XCTAssertEqual(context.topic, .quran)
        XCTAssertEqual(context.surahNumber, 1)
        XCTAssertEqual(context.ayahNumber, 1)
    }

    func testChatContextWithoutLocation() {
        let context = ChatContext(topic: .hadith)

        XCTAssertEqual(context.topic, .hadith)
        XCTAssertNil(context.surahNumber)
        XCTAssertNil(context.ayahNumber)
    }

    func testChatTopicValues() {
        XCTAssertEqual(ChatTopic.general.rawValue, "general")
        XCTAssertEqual(ChatTopic.quran.rawValue, "quran")
        XCTAssertEqual(ChatTopic.hadith.rawValue, "hadith")
        XCTAssertEqual(ChatTopic.fiqh.rawValue, "fiqh")
        XCTAssertEqual(ChatTopic.seerah.rawValue, "seerah")
    }
}
