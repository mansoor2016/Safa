// MARK: - ChatOrchestrator.swift
// PURPOSE: Coordinates the full AI chat pipeline: safety → RAG → prompt → LLM → validation → output
// DEPENDENCIES: LLMService, RAGService, InputSafetyServiceProtocol, OutputSafetyServiceProtocol, CitationValidationServiceProtocol

import Foundation

final class ChatOrchestrator: ChatOrchestratorProtocol {

    // MARK: - Dependencies

    private let llmService: LLMServiceProtocol
    private let ragService: RAGServiceProtocol
    private let inputSafety: InputSafetyServiceProtocol
    private let outputSafety: OutputSafetyServiceProtocol
    private let citationValidation: CitationValidationServiceProtocol

    // MARK: - Constants

    private static let cannedFallback = AIResponse.canned(
        "I apologize, but I'm unable to provide a response right now. Please try again or rephrase your question."
    )

    // MARK: - Init

    init(
        llmService: LLMServiceProtocol,
        ragService: RAGServiceProtocol,
        inputSafety: InputSafetyServiceProtocol,
        outputSafety: OutputSafetyServiceProtocol,
        citationValidation: CitationValidationServiceProtocol
    ) {
        self.llmService = llmService
        self.ragService = ragService
        self.inputSafety = inputSafety
        self.outputSafety = outputSafety
        self.citationValidation = citationValidation
    }

    // MARK: - Pipeline

    func process(_ request: ChatRequest) -> AsyncThrowingStream<OrchestratorEvent, Error> {
        let (stream, continuation) = AsyncThrowingStream.makeStream(of: OrchestratorEvent.self, throwing: Error.self)

        let task = Task {
            do {
                try await self.runPipeline(request: request, continuation: continuation)
            } catch is CancellationError {
                continuation.finish()
            } catch {
                continuation.finish(throwing: error)
            }
        }

        continuation.onTermination = { _ in
            task.cancel()
        }

        return stream
    }

    // MARK: - Private Pipeline Steps

    private func runPipeline(
        request: ChatRequest,
        continuation: AsyncThrowingStream<OrchestratorEvent, Error>.Continuation
    ) async throws {
        // Step 1: Input Safety
        let safetyDecision = inputSafety.evaluate(request.text, context: request.context)

        switch safetyDecision {
        case .decline(let refusalText):
            continuation.yield(.safetyDeclined(refusalText: refusalText))
            continuation.finish()
            return

        case .allowWithCaution(let warning):
            continuation.yield(.cautionBanner(warning: warning))
            // Fall through to continue pipeline

        case .allow:
            break
        }

        try Task.checkCancellation()

        // Step 2: RAG Retrieval (biased by ChatContext if present)
        let ragContext = await ragService.retrieveContext(for: request.text, context: request.context)
        continuation.yield(.ragContextRetrieved(
            topic: ragContext.topic,
            sourceCount: ragContext.quranReferences.count + ragContext.hadithReferences.count
        ))

        try Task.checkCancellation()

        // Step 3: Build System Prompt
        let systemPrompt = SystemPrompts.buildPrompt(
            context: request.context,
            ragContext: ragContext.isEmpty ? nil : ragContext.formattedContext
        )

        try Task.checkCancellation()

        // Step 4: LLM Generation (streaming)
        var fullResponse = ""
        for try await chunk in llmService.generateResponseStreaming(
            prompt: request.text,
            systemPrompt: systemPrompt,
            context: request.context
        ) {
            try Task.checkCancellation()
            fullResponse += chunk
            continuation.yield(.streamingChunk(chunk))
        }

        try Task.checkCancellation()

        // Step 5: Citation Validation
        // For now, extract citations from the response text (placeholder until @Generable)
        let rawCitations = extractCitations(from: fullResponse, ragContext: ragContext)
        let validatedCitations = citationValidation.validate(citations: rawCitations, ragContext: ragContext)

        // Step 6: Output Safety
        let outputDecision = outputSafety.validate(answer: fullResponse, citations: validatedCitations)

        switch outputDecision {
        case .pass:
            let response = AIResponse(
                answer: fullResponse,
                citations: validatedCitations,
                confidence: validatedCitations.isEmpty ? .low : .medium
            )
            continuation.yield(.completed(response))

        case .fail(let reason):
            let fallback = Self.cannedFallback
            continuation.yield(.fallback(reason: reason, response: fallback))
        }

        continuation.finish()
    }

    // MARK: - Citation Extraction (Placeholder)

    /// Extracts citations from response text by matching against RAG results.
    /// This is a placeholder until @Generable produces structured output.
    private func extractCitations(from text: String, ragContext: RAGContext) -> [Citation] {
        var citations: [Citation] = []

        for ref in ragContext.quranReferences {
            let pattern = "\(ref.surahNumber):\(ref.ayahNumber)"
            if text.contains(pattern) {
                citations.append(Citation(
                    source: "Quran",
                    reference: "\(ref.surahName) \(ref.surahNumber):\(ref.ayahNumber)"
                ))
            }
        }

        for ref in ragContext.hadithReferences {
            let pattern = "\(ref.hadithNumber)"
            if text.contains(pattern) {
                citations.append(Citation(
                    source: ref.collection,
                    reference: "\(ref.collection) \(ref.hadithNumber)"
                ))
            }
        }

        return citations
    }
}
