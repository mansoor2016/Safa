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

    var userMessage: String {
        switch self {
        case .available:
            return "AI Companion is ready"
        case .requiresNewerOS(let version):
            return "AI Companion requires iOS \(version) or later. Please update your device to use this feature."
        case .unsupportedDevice:
            return "AI Companion is not supported on this device."
        case .notConfigured:
            return "AI Companion is being set up. Please try again later."
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
            // Runtime check — false on simulator, true on supported device
            if SystemLanguageModel.default.isAvailable {
                return .available
            }
            return .unsupportedDevice
        }
        #endif
        // iOS 26 SDK available but running on older OS, OR SDK not available at all
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
        if #available(iOS 26, *), availability.isAvailable {
            return try await realFMResponse(prompt: prompt, systemPrompt: systemPrompt)
        }
        #endif

        return generatePlaceholderResponse(for: prompt)
    }

    func generateResponseStreaming(prompt: String, systemPrompt: String, context: ChatContext? = nil) -> AsyncThrowingStream<String, Error> {
        #if canImport(FoundationModels)
        if #available(iOS 26, *), availability.isAvailable {
            return realFMStream(prompt: prompt, systemPrompt: systemPrompt)
        }
        #endif

        return placeholderStream(prompt: prompt)
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

    // MARK: - Placeholder Path (iOS <26 / Simulator)

    private func placeholderStream(prompt: String) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            let streamTask = Task {
                do {
                    let response = self.generatePlaceholderResponse(for: prompt)
                    let words = response.split(separator: " ")

                    for word in words {
                        try Task.checkCancellation()
                        continuation.yield(String(word) + " ")
                        try await Task.sleep(nanoseconds: 50_000_000) // 50ms per word
                    }

                    continuation.finish()
                } catch is CancellationError {
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }

            continuation.onTermination = { _ in
                streamTask.cancel()
            }
        }
    }

    // MARK: - Private Methods

    private func generatePlaceholderResponse(for prompt: String) -> String {
        let lowercasePrompt = prompt.lowercased()

        // Knowledge-based responses
        if lowercasePrompt.contains("dua") && lowercasePrompt.contains("eating") {
            return """
            Before eating, the Prophet ﷺ taught us to say:

            **Arabic:** بِسْمِ اللَّهِ
            **Transliteration:** Bismillah
            **Translation:** In the name of Allah

            If you forget to say it at the beginning, you can say:

            **Arabic:** بِسْمِ اللَّهِ فِي أَوَّلِهِ وَآخِرِهِ
            **Transliteration:** Bismillahi fi awwalihi wa akhirihi
            **Translation:** In the name of Allah at the beginning and at the end

            **Source:** Sunan Abu Dawud 3767, graded Sahih
            """
        }

        if lowercasePrompt.contains("wudu") || lowercasePrompt.contains("ablution") {
            return """
            The steps of Wudu (ablution) are:

            1. **Intention (Niyyah)** - Make the intention in your heart
            2. **Say Bismillah** - Begin in the name of Allah
            3. **Wash hands** - Three times
            4. **Rinse mouth** - Three times
            5. **Rinse nose** - Three times
            6. **Wash face** - Three times
            7. **Wash arms** - Including elbows, three times each
            8. **Wipe head** - Once
            9. **Wipe ears** - Once
            10. **Wash feet** - Including ankles, three times each

            **Source:** Based on hadith in Sahih Bukhari and Sahih Muslim
            """
        }

        if lowercasePrompt.contains("break") && lowercasePrompt.contains("fast") {
            return """
            Things that **break the fast**:

            **Definitely break the fast:**
            - Eating or drinking intentionally
            - Sexual intercourse
            - Intentional vomiting
            - Menstruation or post-partum bleeding

            **Do NOT break the fast:**
            - Eating or drinking forgetfully
            - Unintentional vomiting
            - Blood tests or injections (scholars differ on IV drips with nutrients)
            - Brushing teeth (be careful not to swallow water)
            - Swimming or showering
            - Using eye drops, ear drops (most scholars)

            **Requires making up the fast:**
            - If you broke your fast unintentionally, make up that day after Ramadan
            - Consult a scholar for the specific kaffarah (expiation) required for intentional breaking

            **Source:** Based on hadith in Sahih Bukhari, Sahih Muslim, and scholarly consensus

            For complex situations, please consult a qualified scholar.
            """
        }

        if lowercasePrompt.contains("fatiha") || lowercasePrompt.contains("opening") {
            return """
            **Surah Al-Fatiha (The Opening)**

            This is the first surah of the Quran and is recited in every unit (rak'ah) of prayer. It is also known as "Umm al-Kitab" (Mother of the Book).

            **Arabic:**
            بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ
            الْحَمْدُ لِلَّهِ رَبِّ الْعَالَمِينَ
            الرَّحْمَٰنِ الرَّحِيمِ
            مَالِكِ يَوْمِ الدِّينِ
            إِيَّاكَ نَعْبُدُ وَإِيَّاكَ نَسْتَعِينُ
            اهْدِنَا الصِّرَاطَ الْمُسْتَقِيمَ
            صِرَاطَ الَّذِينَ أَنْعَمْتَ عَلَيْهِمْ غَيْرِ الْمَغْضُوبِ عَلَيْهِمْ وَلَا الضَّالِّينَ

            **Translation:**
            In the name of Allah, the Most Gracious, the Most Merciful.
            All praise is for Allah—Lord of all worlds,
            the Most Gracious, the Most Merciful,
            Master of the Day of Judgment.
            You alone we worship and You alone we ask for help.
            Guide us along the Straight Path,
            the Path of those You have blessed—not those You are displeased with, or those who are astray.

            **Virtues:** The Prophet (peace be upon him) said: "Whoever does not recite Al-Fatiha in his prayer, his prayer is incomplete." (Sahih Bukhari 756)
            """
        }

        // Default response
        return """
        Thank you for your question. I'm Safa, your Islamic companion assistant.

        This is a placeholder response while the AI model integration is being completed. In the full version, I will provide detailed, sourced answers to your questions about Islam, including:

        - Quran verses and their explanations
        - Authentic hadith with proper citations
        - Fiqh rulings from the major madhabs
        - Duas and dhikr with Arabic, transliteration, and translation

        **Note:** For complex religious rulings (fatawa), I recommend consulting a qualified scholar.
        """
    }
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
            return String(localized: "Failed to load the AI model. Please try again.")
        case .generationFailed(let reason):
            return String(localized: "Failed to generate response: \(reason)")
        }
    }
}
