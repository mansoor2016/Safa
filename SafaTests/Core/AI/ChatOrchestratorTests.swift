// MARK: - ChatOrchestratorTests.swift
// PURPOSE: Unit tests for ChatOrchestrator pipeline
// DEPENDENCIES: XCTest, Safa

import XCTest
@testable import Safa

final class ChatOrchestratorTests: XCTestCase {

    // MARK: - Helpers

    private func makeOrchestrator(
        llmService: LLMServiceProtocol? = nil,
        ragService: RAGServiceProtocol? = nil,
        inputSafety: InputSafetyServiceProtocol = PassthroughInputSafetyService(),
        outputSafety: OutputSafetyServiceProtocol = PassthroughOutputSafetyService(),
        citationValidation: CitationValidationServiceProtocol = PassthroughCitationValidationService()
    ) -> ChatOrchestrator {
        return ChatOrchestrator(
            llmService: llmService ?? StubLLMService(),
            ragService: ragService ?? StubRAGService(),
            inputSafety: inputSafety,
            outputSafety: outputSafety,
            citationValidation: citationValidation
        )
    }

    private func makeRequest(text: String = "What is wudu?") -> ChatRequest {
        ChatRequest(text: text, conversationId: UUID())
    }

    private func collectEvents(from stream: AsyncThrowingStream<OrchestratorEvent, Error>) async throws -> [OrchestratorEvent] {
        var events: [OrchestratorEvent] = []
        for try await event in stream {
            events.append(event)
        }
        return events
    }

    // MARK: - Pipeline Flow Tests

    func test_process_withPassthroughStubs_completesSuccessfully() async throws {
        let orchestrator = makeOrchestrator()
        let events = try await collectEvents(from: orchestrator.process(makeRequest()))

        // Should have at least RAG context + streaming chunks + completed
        XCTAssertTrue(events.contains(where: {
            if case .ragContextRetrieved = $0 { return true }
            return false
        }), "Should emit RAG context event")

        let hasCompletedOrChunks = events.contains(where: {
            if case .completed = $0 { return true }
            if case .streamingChunk = $0 { return true }
            return false
        })
        XCTAssertTrue(hasCompletedOrChunks, "Should emit completed or streaming events")
    }

    // MARK: - Input Safety Tests

    func test_process_inputDeclined_emitsSafetyDeclinedAndStops() async throws {
        let declining = DecliningInputSafetyService()
        let orchestrator = makeOrchestrator(inputSafety: declining)
        let events = try await collectEvents(from: orchestrator.process(makeRequest()))

        XCTAssertEqual(events.count, 1, "Should only emit safety declined event")
        if case .safetyDeclined(let text) = events.first {
            XCTAssertFalse(text.isEmpty)
        } else {
            XCTFail("Expected safetyDeclined event")
        }
    }

    func test_process_inputCaution_emitsCautionBannerThenContinues() async throws {
        let cautious = CautiousInputSafetyService()
        let orchestrator = makeOrchestrator(inputSafety: cautious)
        let events = try await collectEvents(from: orchestrator.process(makeRequest()))

        let hasCaution = events.contains(where: {
            if case .cautionBanner = $0 { return true }
            return false
        })
        XCTAssertTrue(hasCaution, "Should emit caution banner")

        let hasContent = events.contains(where: {
            if case .completed = $0 { return true }
            if case .streamingChunk = $0 { return true }
            return false
        })
        XCTAssertTrue(hasContent, "Should still continue pipeline after caution")
    }

    // MARK: - Output Safety Tests

    func test_process_outputFailed_emitsFallback() async throws {
        let failing = FailingOutputSafetyService()
        let orchestrator = makeOrchestrator(outputSafety: failing)
        let events = try await collectEvents(from: orchestrator.process(makeRequest()))

        let hasFallback = events.contains(where: {
            if case .fallback = $0 { return true }
            return false
        })
        XCTAssertTrue(hasFallback, "Should emit fallback when output safety fails")
    }

    // MARK: - Citation Extraction Tests

    func test_process_ragReferenceMatchedInResponse_extractsCitation() async throws {
        // Given — RAG returns a Quran reference, LLM echoes the reference pattern
        let ragContext = RAGContext(
            quranReferences: [QuranReference(
                surahNumber: 2, surahName: "Al-Baqarah", ayahNumber: 255,
                arabic: "...", translation: "...", relevanceScore: 0.9
            )],
            hadithReferences: [],
            duaReferences: [],
            topic: .quran
        )
        let orchestrator = makeOrchestrator(
            llmService: StubLLMService(chunks: ["Ayat al-Kursi ", "(2:255) ", "is about Allah's sovereignty."]),
            ragService: StubRAGService(context: ragContext)
        )

        // When
        let events = try await collectEvents(from: orchestrator.process(makeRequest()))

        // Then
        let response = events.compactMap { event -> AIResponse? in
            if case .completed(let r) = event { return r }
            return nil
        }.first

        XCTAssertNotNil(response)
        XCTAssertEqual(response?.citations.count, 1, "Should extract one citation for 2:255")
        XCTAssertEqual(response?.citations.first?.source, "Quran")
        XCTAssertTrue(response?.citations.first?.reference.contains("Al-Baqarah") ?? false)
        XCTAssertEqual(response?.confidence, .medium, "Presence of citations should yield medium confidence")
    }

    func test_process_ragReferenceNotInResponse_noCitations() async throws {
        // Given — RAG returns a reference but LLM response doesn't mention it
        let ragContext = RAGContext(
            quranReferences: [QuranReference(
                surahNumber: 2, surahName: "Al-Baqarah", ayahNumber: 255,
                arabic: "...", translation: "...", relevanceScore: 0.9
            )],
            hadithReferences: [],
            duaReferences: [],
            topic: .quran
        )
        let orchestrator = makeOrchestrator(
            llmService: StubLLMService(chunks: ["This is a general ", "response about Islam."]),
            ragService: StubRAGService(context: ragContext)
        )

        // When
        let events = try await collectEvents(from: orchestrator.process(makeRequest()))

        // Then
        let response = events.compactMap { event -> AIResponse? in
            if case .completed(let r) = event { return r }
            return nil
        }.first

        XCTAssertNotNil(response)
        XCTAssertTrue(response?.citations.isEmpty ?? false, "No citation should be extracted when response doesn't reference the pattern")
        XCTAssertEqual(response?.confidence, .low, "No citations should yield low confidence")
    }

    func test_process_hadithReferenceMatchedInResponse_extractsCitation() async throws {
        // Given — RAG returns a hadith reference, LLM echoes the hadith number
        let ragContext = RAGContext(
            quranReferences: [],
            hadithReferences: [HadithReference(
                collection: "Sahih al-Bukhari", hadithNumber: 1,
                narrator: "Umar", text: "Actions are by intentions.",
                grading: "Sahih", relevanceScore: 0.95
            )],
            duaReferences: [],
            topic: .hadith
        )
        let orchestrator = makeOrchestrator(
            llmService: StubLLMService(chunks: ["The Prophet said (Hadith 1): ", "actions are by intentions."]),
            ragService: StubRAGService(context: ragContext)
        )

        // When
        let events = try await collectEvents(from: orchestrator.process(makeRequest()))

        // Then
        let response = events.compactMap { event -> AIResponse? in
            if case .completed(let r) = event { return r }
            return nil
        }.first

        XCTAssertNotNil(response)
        XCTAssertEqual(response?.citations.count, 1)
        XCTAssertEqual(response?.citations.first?.source, "Sahih al-Bukhari")
    }

    // MARK: - Dua Citation Extraction

    func test_process_duaReferenceMatchedInResponse_extractsCitation() async throws {
        // Given — RAG returns a dua reference, LLM echoes the dua title
        let ragContext = RAGContext(
            quranReferences: [],
            hadithReferences: [],
            duaReferences: [DuaReference(
                duaId: "dua_sleep_001", title: "Dua before sleeping",
                arabic: "...", translation: "...", source: nil,
                relevanceScore: 0.8
            )],
            topic: .dua
        )
        let orchestrator = makeOrchestrator(
            llmService: StubLLMService(chunks: ["The ", "Dua before sleeping ", "is recited at night."]),
            ragService: StubRAGService(context: ragContext)
        )

        // When
        let events = try await collectEvents(from: orchestrator.process(makeRequest(text: "What dua before sleep?")))

        // Then
        let response = events.compactMap { event -> AIResponse? in
            if case .completed(let r) = event { return r }
            return nil
        }.first

        XCTAssertNotNil(response)
        XCTAssertEqual(response?.citations.count, 1, "Should extract dua citation from title match")
        XCTAssertEqual(response?.citations.first?.type, .dua)
        XCTAssertEqual(response?.citations.first?.duaId, "dua_sleep_001")
    }

    // MARK: - Context Threading Through Pipeline

    func test_process_passesContextToRAGService() async throws {
        // Given — RAG service that captures the context
        let capturingRAG = CapturingRAGService()
        let orchestrator = makeOrchestrator(ragService: capturingRAG)
        let context = ChatContext(topic: .quran, surahNumber: 2, ayahNumber: 255)
        let request = ChatRequest(text: "Explain this ayah", conversationId: UUID(), context: context)

        // When
        _ = try await collectEvents(from: orchestrator.process(request))

        // Then — RAG should receive the context
        XCTAssertEqual(capturingRAG.lastContext?.topic, .quran)
        XCTAssertEqual(capturingRAG.lastContext?.surahNumber, 2)
        XCTAssertEqual(capturingRAG.lastContext?.ayahNumber, 255)
    }

    // MARK: - Cancellation Tests

    func test_process_cancellation_stopsStream() async throws {
        let orchestrator = makeOrchestrator()
        let stream = orchestrator.process(makeRequest())

        let task = Task {
            var count = 0
            for try await _ in stream {
                count += 1
                if count >= 2 {
                    break
                }
            }
            return count
        }

        let count = try await task.value
        XCTAssertGreaterThanOrEqual(count, 1, "Should have received at least 1 event before stopping")
    }
}

// MARK: - Test Doubles

private struct DecliningInputSafetyService: InputSafetyServiceProtocol {
    func evaluate(_ text: String, context: ChatContext?) -> SafetyDecision {
        .decline(refusalText: "This topic is outside my scope.")
    }
}

private struct CautiousInputSafetyService: InputSafetyServiceProtocol {
    func evaluate(_ text: String, context: ChatContext?) -> SafetyDecision {
        .allowWithCaution(warning: "This topic may have varying scholarly interpretations.")
    }
}

private struct FailingOutputSafetyService: OutputSafetyServiceProtocol {
    func validate(answer: String, citations: [Citation]) -> OutputDecision {
        .fail(reason: "Disallowed content detected")
    }
}

// MARK: - Stub LLM Service

private struct StubLLMService: LLMServiceProtocol {
    let chunks: [String]

    init(chunks: [String] = ["This ", "is ", "a ", "test ", "response."]) {
        self.chunks = chunks
    }

    func generateResponseStreaming(
        prompt: String,
        systemPrompt: String,
        context: ChatContext?
    ) -> AsyncThrowingStream<String, Error> {
        // Yield synchronously to avoid unstructured Task scheduling issues on iOS 18.6+
        AsyncThrowingStream<String, Error> { continuation in
            for chunk in chunks {
                continuation.yield(chunk)
            }
            continuation.finish()
        }
    }
}

// MARK: - Capturing RAG Service

private final class CapturingRAGService: RAGServiceProtocol {
    var lastContext: ChatContext?

    func retrieveContext(for query: String, context: ChatContext?) async -> RAGContext {
        lastContext = context
        return RAGContext(quranReferences: [], hadithReferences: [], duaReferences: [], topic: .general)
    }
}

// MARK: - Stub RAG Service

private struct StubRAGService: RAGServiceProtocol {
    let context: RAGContext

    init(context: RAGContext = RAGContext(quranReferences: [], hadithReferences: [], duaReferences: [], topic: .general)) {
        self.context = context
    }

    func retrieveContext(for query: String, context: ChatContext? = nil) async -> RAGContext {
        self.context
    }
}
