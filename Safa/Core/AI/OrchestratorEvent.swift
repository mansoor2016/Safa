// MARK: - OrchestratorEvent.swift
// PURPOSE: Streaming events emitted by the ChatOrchestrator pipeline
// DEPENDENCIES: Foundation

import Foundation

/// Events emitted by the ChatOrchestrator as a request moves through the pipeline.
enum OrchestratorEvent {
    /// Input safety declined the request. No LLM call was made.
    case safetyDeclined(refusalText: String)

    /// Input safety allowed with caution — a warning banner should be shown above the response.
    case cautionBanner(warning: String)

    /// A chunk of streaming text from the LLM.
    case streamingChunk(String)

    /// RAG context was retrieved (informational, for logging/debugging).
    case ragContextRetrieved(topic: RAGTopic, sourceCount: Int)

    /// The pipeline completed with a final response.
    case completed(AIResponse)

    /// The pipeline encountered an error and returned a canned fallback.
    case fallback(reason: String, response: AIResponse)
}

/// The structured response from the AI pipeline.
struct AIResponse {
    let answer: String
    let citations: [Citation]
    let confidence: ConfidenceBand

    static func canned(_ text: String) -> AIResponse {
        AIResponse(answer: text, citations: [], confidence: .low)
    }
}

/// Type of citation source for navigation routing.
enum CitationType: String, Codable {
    case quran
    case hadith
    case dua
}

/// A source citation attached to an AI response.
struct Citation: Codable, Hashable {
    let source: String
    let reference: String
    let verified: Bool
    let type: CitationType?
    let surahNumber: Int?
    let ayahNumber: Int?
    let collectionId: String?
    let hadithNumber: Int?
    let duaId: String?

    init(
        source: String,
        reference: String,
        verified: Bool = false,
        type: CitationType? = nil,
        surahNumber: Int? = nil,
        ayahNumber: Int? = nil,
        collectionId: String? = nil,
        hadithNumber: Int? = nil,
        duaId: String? = nil
    ) {
        self.source = source
        self.reference = reference
        self.verified = verified
        self.type = type
        self.surahNumber = surahNumber
        self.ayahNumber = ayahNumber
        self.collectionId = collectionId
        self.hadithNumber = hadithNumber
        self.duaId = duaId
    }

    func withVerified(_ verified: Bool) -> Citation {
        Citation(
            source: source,
            reference: reference,
            verified: verified,
            type: type,
            surahNumber: surahNumber,
            ayahNumber: ayahNumber,
            collectionId: collectionId,
            hadithNumber: hadithNumber,
            duaId: duaId
        )
    }

    /// Returns the navigation destination for this citation, if navigable.
    func navigationDestination() -> AppRouter.Destination? {
        guard let type else { return nil }
        switch type {
        case .quran:
            if let surah = surahNumber, let ayah = ayahNumber {
                return .ayah(surah: surah, ayah: ayah)
            } else if let surah = surahNumber {
                return .surah(number: surah)
            }
            return nil
        case .hadith:
            guard collectionId != nil else { return nil }
            return .hadith(
                collection: collectionId,
                hadithId: hadithNumber.map(String.init)
            )
        case .dua:
            return .dhikr
        }
    }
}

/// Confidence level of the AI response.
enum ConfidenceBand: String, Codable {
    case high
    case medium
    case low
}
