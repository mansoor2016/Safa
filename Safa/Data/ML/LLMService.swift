// MARK: - LLMService.swift
// PURPOSE: On-device LLM inference for AI companion chat with Apple Foundation Models
// DEPENDENCIES: Foundation, CoreML

import Foundation
import CoreML

#if canImport(FoundationModels)
import FoundationModels
#endif

// MARK: - LLM Availability

enum LLMAvailability {
    case available
    case requiresNewerOS(minimumVersion: String)
    case unsupportedDevice
    case notConfigured

    var isAvailable: Bool {
        if case .available = self { return true }
        return false
    }

    /// Developer-facing description. Not shown in UI — entry points are hidden on unsupported devices.
    var userMessage: String {
        switch self {
        case .available:
            return "AI Companion is ready"
        case .requiresNewerOS(let version):
            return "Requires iOS \(version) or later on a supported device"
        case .unsupportedDevice:
            return "Requires iPhone 16 or newer with iOS 26"
        case .notConfigured:
            return "AI model not yet configured"
        }
    }
}

// MARK: - LLM Service

final class LLMService: LLMServiceProtocol {
    // MARK: - Properties
    private var model: MLModel?
    private var isLoading = false

    // Minimum iOS version for Apple Foundation Models
    static let minimumIOSVersion = "26.0"

    // MARK: - Model State

    var isModelLoaded: Bool {
        model != nil
    }

    var availability: LLMAvailability {
        #if canImport(FoundationModels)
        if #available(iOS 26, *) {
            // Runtime check — covers both device and simulator.
            // On iOS 26 simulator: true (FM works). On older simulators: never reaches here.
            // On physical device: true for iPhone 16+, false for older hardware.
            if SystemLanguageModel.default.isAvailable {
                return .available
            }
            return .unsupportedDevice
        }
        #endif
        // Running on iOS <26 (device or simulator), or SDK doesn't include FoundationModels
        return .requiresNewerOS(minimumVersion: Self.minimumIOSVersion)
    }

    // MARK: - Init

    init() {
        // Model loading deferred until first use
    }

    // MARK: - Load Model

    func loadModel() async throws {
        guard availability.isAvailable else {
            throw LLMError.unavailable(availability.userMessage)
        }

        guard !isLoading && model == nil else { return }

        // For Foundation Models, no explicit model loading is needed —
        // LanguageModelSession handles model lifecycle internally.
        // This method exists for protocol compatibility and future use.
    }

    // MARK: - Generate Response

    func generateResponse(prompt: String, systemPrompt: String, context: ChatContext? = nil) async throws -> String {
        guard availability.isAvailable else {
            throw LLMError.unavailable(availability.userMessage)
        }

        #if canImport(FoundationModels)
        if #available(iOS 26, *) {
            return try await realFMResponse(prompt: prompt, systemPrompt: systemPrompt)
        }
        #endif

        // Unreachable in production — availability gate above ensures this.
        // Kept for compiler completeness on non-FM SDK builds.
        throw LLMError.unavailable(availability.userMessage)
    }

    func generateResponseStreaming(prompt: String, systemPrompt: String, context: ChatContext? = nil) -> AsyncThrowingStream<String, Error> {
        #if canImport(FoundationModels)
        if #available(iOS 26, *), availability.isAvailable {
            return realFMStream(prompt: prompt, systemPrompt: systemPrompt)
        }
        #endif

        // Unreachable in production — entry points hidden when FM unavailable.
        return AsyncThrowingStream { $0.finish(throwing: LLMError.unavailable(self.availability.userMessage)) }
    }

    // MARK: - Apple Foundation Models (iOS 26+)

    #if canImport(FoundationModels)
    @available(iOS 26, *)
    private func realFMResponse(prompt: String, systemPrompt: String) async throws -> String {
        let session = LanguageModelSession(instructions: systemPrompt)
        let response = try await session.respond(to: prompt)
        return response.content
    }

    @available(iOS 26, *)
    private func realFMStream(prompt: String, systemPrompt: String) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    let session = LanguageModelSession(instructions: systemPrompt)
                    var previousContent = ""
                    for try await snapshot in session.streamResponse(to: prompt) {
                        try Task.checkCancellation()
                        let currentContent = snapshot.content
                        // Each snapshot contains cumulative text — yield only the new delta
                        let newChunk = String(currentContent.dropFirst(previousContent.count))
                        if !newChunk.isEmpty {
                            continuation.yield(newChunk)
                        }
                        previousContent = currentContent
                    }
                    continuation.finish()
                } catch is CancellationError {
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }
    #endif
}

// MARK: - LLM Errors

enum LLMError: LocalizedError {
    case unavailable(String)
    case modelLoadFailed
    case generationFailed(String)

    var errorDescription: String? {
        switch self {
        case .unavailable(let message):
            return message
        case .modelLoadFailed:
            return String(localized: "Unable to load the AI model. Please restart the app and try again.")
        case .generationFailed(let reason):
            return String(localized: "Failed to generate response: \(reason)")
        }
    }
}
