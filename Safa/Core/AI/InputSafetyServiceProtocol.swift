// MARK: - InputSafetyServiceProtocol.swift
// PURPOSE: Protocol for pre-LLM input safety gate
// DEPENDENCIES: Foundation

import Foundation

/// Decision returned by the input safety layer.
enum SafetyDecision {
    /// Input is safe to process.
    case allow
    /// Input is allowed but may touch sensitive topics. Warning text is displayed to the user.
    case allowWithCaution(warning: String)
    /// Input is declined. The provided text is shown as a refusal response.
    case decline(refusalText: String)
}

/// Pre-LLM input gate. Evaluates raw user text before any model call.
protocol InputSafetyServiceProtocol {
    /// Evaluate the safety of user input.
    /// - Parameters:
    ///   - text: Raw user input text.
    ///   - context: Optional chat context for topic awareness.
    /// - Returns: A safety decision.
    func evaluate(_ text: String, context: ChatContext?) -> SafetyDecision
}

/// Pass-through stub that always allows input. Used until real implementation is wired.
struct PassthroughInputSafetyService: InputSafetyServiceProtocol {
    func evaluate(_ text: String, context: ChatContext?) -> SafetyDecision {
        .allow
    }
}
