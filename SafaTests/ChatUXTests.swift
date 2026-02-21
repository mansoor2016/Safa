// MARK: - ChatUXTests.swift
// PURPOSE: Tests for chat UX data contracts (citations, accessibility-relevant data)
// DEPENDENCIES: XCTest, Safa

import XCTest
@testable import Safa

final class ChatUXTests: XCTestCase {

    // MARK: - Citation Data Contract Tests

    func test_citationAccessibilityLabel_includesReference() {
        // Given — a citation with a reference string
        let citation = Citation(
            source: "Quran",
            reference: "Al-Baqarah 2:255",
            verified: false,
            type: .quran,
            surahNumber: 2,
            ayahNumber: 255
        )

        // Then — reference is non-empty and usable for accessibility labels
        XCTAssertFalse(citation.reference.isEmpty, "Citation reference must be non-empty for accessibility")
        XCTAssertTrue(citation.reference.contains("Al-Baqarah"), "Reference should include surah name")
    }

    func test_citationAccessibilityLabel_showsVerified() {
        // Given — a verified citation
        let verifiedCitation = Citation(
            source: "Quran",
            reference: "Al-Fatiha 1:1",
            verified: true,
            type: .quran,
            surahNumber: 1,
            ayahNumber: 1
        )

        // Given — an unverified citation
        let unverifiedCitation = Citation(
            source: "General",
            reference: "Some reference",
            verified: false
        )

        // Then — verified flag distinguishes the two
        XCTAssertTrue(verifiedCitation.verified, "Verified citation should have verified = true")
        XCTAssertFalse(unverifiedCitation.verified, "Unverified citation should have verified = false")
    }

    // MARK: - ChatMessage Status Tests

    func test_abortedMessageStatus_isPreserved() {
        // Given — a message created with .aborted status
        let message = ChatMessage(
            conversationId: UUID(),
            role: .assistant,
            content: "Partial response...",
            status: .aborted
        )

        // Then — status is preserved for UI rendering
        XCTAssertEqual(message.status, .aborted)
        XCTAssertFalse(message.content.isEmpty, "Aborted message should preserve partial content")
    }

    func test_streamingMessageStatus_isDistinctFromComplete() {
        // Given
        let streaming = ChatMessage(conversationId: UUID(), role: .assistant, content: "Partial...", status: .streaming)
        let complete = ChatMessage(conversationId: UUID(), role: .assistant, content: "Full response", status: .complete)

        // Then
        XCTAssertNotEqual(streaming.status, complete.status)
    }
}
