// MARK: - OutputSafetyServiceProtocol.swift
// PURPOSE: Protocol for post-LLM output safety validation
// DEPENDENCIES: Foundation

import Foundation

/// Decision returned by the output safety layer.
enum OutputDecision {
    /// Output passed validation.
    case pass
    /// Output failed validation with a reason.
    case fail(reason: String)
}

/// Post-LLM output validation. Scans the final answer for disallowed content.
protocol OutputSafetyServiceProtocol {
    /// Validate the AI-generated response.
    /// - Parameters:
    ///   - answer: The generated answer text.
    ///   - citations: Citations attached to the response.
    /// - Returns: An output decision.
    func validate(answer: String, citations: [Citation]) -> OutputDecision
}

/// Pass-through stub that always passes output. Used until real implementation is wired.
struct PassthroughOutputSafetyService: OutputSafetyServiceProtocol {
    func validate(answer: String, citations: [Citation]) -> OutputDecision {
        .pass
    }
}
