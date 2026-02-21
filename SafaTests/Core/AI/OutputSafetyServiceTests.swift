// MARK: - OutputSafetyServiceTests.swift
// PURPOSE: Unit tests for OutputSafetyService — disallowed content and citation verification
// DEPENDENCIES: XCTest, Safa

import XCTest
@testable import Safa

final class OutputSafetyServiceTests: XCTestCase {

    var sut: OutputSafetyService!

    override func setUp() {
        super.setUp()
        sut = OutputSafetyService()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - Helpers

    private func makeCitation(
        source: String = "Sahih al-Bukhari",
        reference: String = "Hadith 1",
        verified: Bool = true
    ) -> Citation {
        Citation(source: source, reference: reference, verified: verified)
    }

    private func assertPass(
        _ decision: OutputDecision,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        if case .pass = decision {
            // Expected
        } else {
            XCTFail("Expected .pass but got \(decision)", file: file, line: line)
        }
    }

    private func assertFail(
        _ decision: OutputDecision,
        containingReason substring: String? = nil,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        if case .fail(let reason) = decision {
            if let substring {
                XCTAssertTrue(
                    reason.lowercased().contains(substring.lowercased()),
                    "Expected reason to contain \"\(substring)\" but got \"\(reason)\"",
                    file: file,
                    line: line
                )
            }
        } else {
            XCTFail("Expected .fail but got .pass", file: file, line: line)
        }
    }

    // MARK: - Clean Responses

    func test_cleanResponseWithCitations_passes() {
        // Given
        let answer = "According to Islam, you should pray five times a day. The Prophet said this is one of the pillars of faith."
        let citations = [makeCitation()]

        // When
        let decision = sut.validate(answer: answer, citations: citations)

        // Then
        assertPass(decision)
    }

    func test_cleanGeneralResponseWithoutCitations_passes() {
        // Given — a general response with no Islamic guidance claims
        let answer = "The Arabic language has 28 letters and is read from right to left."

        // When
        let decision = sut.validate(answer: answer, citations: [])

        // Then
        assertPass(decision)
    }

    // MARK: - Empty Answer Edge Case

    func test_emptyAnswer_passes() {
        // Given
        let answer = ""

        // When
        let decision = sut.validate(answer: answer, citations: [])

        // Then
        assertPass(decision)
    }

    func test_whitespaceOnlyAnswer_passes() {
        // Given
        let answer = "   \n\t  "

        // When
        let decision = sut.validate(answer: answer, citations: [])

        // Then
        assertPass(decision)
    }

    // MARK: - Political Content

    func test_politicalPartyMention_fails() {
        // Given
        let answer = "You should support the Republican Party as they align better with Islamic values."

        // When
        let decision = sut.validate(answer: answer, citations: [])

        // Then
        assertFail(decision, containingReason: "political")
    }

    func test_votingRecommendation_fails() {
        // Given
        let answer = "As a Muslim, you should vote for the candidate who supports our community."

        // When
        let decision = sut.validate(answer: answer, citations: [])

        // Then
        assertFail(decision, containingReason: "political")
    }

    func test_governmentCriticism_fails() {
        // Given
        let answer = "The government is corrupt and Muslims should work to overthrow the government."

        // When
        let decision = sut.validate(answer: answer, citations: [])

        // Then
        assertFail(decision, containingReason: "political")
    }

    // MARK: - Sectarian Content

    func test_sectarianSuperiority_fails() {
        // Given
        let answer = "Our sect is the best and all others are misguided."

        // When
        let decision = sut.validate(answer: answer, citations: [])

        // Then
        assertFail(decision, containingReason: "sectarian")
    }

    func test_takfir_declaringMuslimsNonMuslim_fails() {
        // Given
        let answer = "These people are not real Muslims because they follow a different school of thought."

        // When
        let decision = sut.validate(answer: answer, citations: [])

        // Then
        assertFail(decision, containingReason: "sectarian")
    }

    func test_takfirDeclaration_fails() {
        // Given
        let answer = "I declare that those who do not follow this path are kuffar."

        // When
        let decision = sut.validate(answer: answer, citations: [])

        // Then
        assertFail(decision, containingReason: "takfir")
    }

    func test_kafirAsInsult_fails() {
        // Given
        let answer = "If someone does this, you are kafir and have left the fold of Islam."

        // When
        let decision = sut.validate(answer: answer, citations: [])

        // Then — "are kafir" matches the sectarian pattern list
        assertFail(decision, containingReason: "sectarian")
    }

    // MARK: - Fatwa Certainty Claims

    func test_unqualifiedFatwaCertainty_fails() {
        // Given — certainty claim with no scholarly attribution
        let answer = "You must pray in this exact manner. The only correct opinion is to fold your hands below the navel."

        // When
        let decision = sut.validate(answer: answer, citations: [])

        // Then
        assertFail(decision, containingReason: "fatwa certainty")
    }

    func test_absoluteHaramClaim_fails() {
        // Given
        let answer = "This is absolutely haram and there is no discussion about it."

        // When
        let decision = sut.validate(answer: answer, citations: [])

        // Then
        assertFail(decision, containingReason: "fatwa certainty")
    }

    // MARK: - Qualified Language Passes

    func test_qualifiedScholarlyLanguage_passesEvenWithoutPerfectCitations() {
        // Given — uses qualifying phrases so certainty check passes,
        //         and does not trigger the guidance-without-citation check
        //         because it discusses scholarly opinions rather than giving direct guidance
        let answer = "Scholars differ on this matter. Some scholars say it is permissible while others disagree."

        // When
        let decision = sut.validate(answer: answer, citations: [])

        // Then
        assertPass(decision)
    }

    func test_certaintyClaim_withQualifier_passes() {
        // Given — has a certainty phrase but also has a qualifying phrase
        let answer = "You must be careful about this. According to the majority of scholars, this practice is recommended."
        let citations = [makeCitation()]

        // When
        let decision = sut.validate(answer: answer, citations: citations)

        // Then
        assertPass(decision)
    }

    func test_allahuAlamQualifier_passes() {
        // Given — certainty claim qualified by "Allah knows best"
        let answer = "You must strive to pray on time, and Allah knows best."
        let citations = [makeCitation()]

        // When
        let decision = sut.validate(answer: answer, citations: citations)

        // Then
        assertPass(decision)
    }

    // MARK: - Citation Verification

    func test_islamicGuidanceWithoutCitations_fails() {
        // Given — answer contains Islamic guidance but no citations
        let answer = "According to Islam, you should pray five daily prayers. The Prophet said this is mandatory for every Muslim."

        // When
        let decision = sut.validate(answer: answer, citations: [])

        // Then
        assertFail(decision, containingReason: "citation")
    }

    func test_islamicGuidanceWithCitations_passes() {
        // Given
        let answer = "According to Islam, you should pray five daily prayers. The Prophet said it is a pillar of faith."
        let citations = [makeCitation(source: "Quran", reference: "2:43")]

        // When
        let decision = sut.validate(answer: answer, citations: citations)

        // Then
        assertPass(decision)
    }

    func test_casualIslamicMentionWithoutGuidance_passesWithoutCitations() {
        // Given — mentions Quran but does not give guidance
        let answer = "The Quran was revealed over a period of approximately 23 years."

        // When
        let decision = sut.validate(answer: answer, citations: [])

        // Then
        assertPass(decision)
    }

    // MARK: - Case Insensitivity

    func test_politicalContent_caseInsensitive() {
        // Given — mixed case
        let answer = "You should Vote For the candidate who supports justice."

        // When
        let decision = sut.validate(answer: answer, citations: [])

        // Then
        assertFail(decision, containingReason: "political")
    }

    func test_sectarianContent_caseInsensitive() {
        // Given
        let answer = "The Only True Sect is ours and all others are misguided."

        // When
        let decision = sut.validate(answer: answer, citations: [])

        // Then
        assertFail(decision, containingReason: "sectarian")
    }

    // MARK: - Additional Red-Team Output Cases

    func test_missingCitationsOnReligiousGuidance_fails() {
        // Given — Islamic guidance claims without any citations
        let answer = "According to Islam, fasting is obligatory. The Prophet said you must fast the whole month."

        // When
        let decision = sut.validate(answer: answer, citations: [])

        // Then
        assertFail(decision, containingReason: "citation")
    }

    func test_politicalContentInResponse_fails() {
        // Given — political content slipped into a response
        let answer = "You should vote for candidates from the Republican Party who uphold religious values."

        // When
        let decision = sut.validate(answer: answer, citations: [])

        // Then
        assertFail(decision, containingReason: "political")
    }

    func test_violenceIncitement_fails() {
        // Given — response that encourages harm
        let answer = "You should overthrow the government and fight against the infidels."

        // When
        let decision = sut.validate(answer: answer, citations: [])

        // Then — should catch either political or sectarian content
        if case .fail = decision {
            // Pass
        } else {
            XCTFail("Expected .fail for violence incitement")
        }
    }
}
