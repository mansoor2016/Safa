// MARK: - LLMService.swift
// PURPOSE: On-device LLM inference for AI companion chat with Apple Foundation Models
// DEPENDENCIES: CoreML, Foundation

import Foundation
import CoreML

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

final class LLMService {
    // MARK: - Properties
    private var model: MLModel?
    private var isLoading = false
    private var ragService: RAGService?

    // Minimum iOS version for Apple Foundation Models
    private static let minimumIOSVersion = "18.4"

    // MARK: - Model State

    var isModelLoaded: Bool {
        model != nil
    }

    var availability: LLMAvailability {
        // Check iOS version for Apple Foundation Models
        if #available(iOS 18.4, *) {
            // TODO: Add device capability check when API is available
            return .available
        } else {
            return .requiresNewerOS(minimumVersion: Self.minimumIOSVersion)
        }
    }

    // MARK: - Init

    init() {
        // Model loading deferred until first use
    }

    // MARK: - Configure

    func configure(ragService: RAGService) {
        self.ragService = ragService
    }

    // MARK: - Load Model

    func loadModel() async throws {
        guard availability.isAvailable else {
            throw LLMError.unavailable(availability.userMessage)
        }

        guard !isLoading && model == nil else { return }

        isLoading = true
        defer { isLoading = false }

        // Apple Foundation Models integration placeholder
        // When iOS 18.4 is available, this will use:
        // import FoundationModels
        // let session = LanguageModelSession()

        // For now, simulate model loading
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 second
    }

    // MARK: - Generate Response

    func generateResponse(prompt: String, systemPrompt: String, context: ChatContext? = nil) async throws -> String {
        // Check availability
        guard availability.isAvailable else {
            throw LLMError.unavailable(availability.userMessage)
        }

        if !isModelLoaded {
            try await loadModel()
        }

        // Retrieve RAG context if service is configured
        var ragContext: RAGContext?
        if let ragService = ragService {
            ragContext = await ragService.retrieveContext(for: prompt)
        }

        // Build enhanced prompt with RAG context (used when Foundation Models inference is wired in)
        _ = buildEnhancedPrompt(
            userPrompt: prompt,
            systemPrompt: systemPrompt,
            ragContext: ragContext
        )

        // TODO: Replace with actual Apple Foundation Models inference
        // When iOS 18.4 is available:
        // let session = LanguageModelSession(systemPrompt: systemPrompt)
        // let response = try await session.respond(to: enhancedPrompt)
        // return response.content

        // For now, return placeholder response
        return generatePlaceholderResponse(for: prompt, ragContext: ragContext)
    }

    func generateResponseStreaming(prompt: String, systemPrompt: String, context: ChatContext? = nil) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    // Check availability
                    guard self.availability.isAvailable else {
                        continuation.finish(throwing: LLMError.unavailable(self.availability.userMessage))
                        return
                    }

                    if !self.isModelLoaded {
                        try await self.loadModel()
                    }

                    // Retrieve RAG context
                    var ragContext: RAGContext?
                    if let ragService = self.ragService {
                        ragContext = await ragService.retrieveContext(for: prompt)
                    }

                    // TODO: Replace with actual streaming when Apple FM is available
                    // When iOS 18.4 is available:
                    // let session = LanguageModelSession(systemPrompt: systemPrompt)
                    // for try await chunk in session.streamResponse(to: prompt) {
                    //     continuation.yield(chunk)
                    // }

                    // For now, stream placeholder response
                    let response = self.generatePlaceholderResponse(for: prompt, ragContext: ragContext)
                    let words = response.split(separator: " ")

                    for word in words {
                        continuation.yield(String(word) + " ")
                        try await Task.sleep(nanoseconds: 50_000_000) // 50ms per word
                    }

                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }

    // MARK: - Private Methods

    private func buildEnhancedPrompt(userPrompt: String, systemPrompt: String, ragContext: RAGContext?) -> String {
        var enhancedPrompt = userPrompt

        // Add RAG context if available
        if let context = ragContext, !context.isEmpty {
            enhancedPrompt = """
            User Question: \(userPrompt)

            ## Retrieved Knowledge Base Context
            \(context.formattedContext)

            Please use the above context to help answer the user's question. Cite sources when referencing specific ayahs or hadiths.
            """
        }

        return enhancedPrompt
    }

    private func generatePlaceholderResponse(for prompt: String, ragContext: RAGContext?) -> String {
        let lowercasePrompt = prompt.lowercased()

        // Include RAG citations if available
        var citations = ""
        if let context = ragContext, !context.isEmpty {
            var citationParts: [String] = []
            for ref in context.quranReferences.prefix(2) {
                citationParts.append("Quran \(ref.surahNumber):\(ref.ayahNumber)")
            }
            for ref in context.hadithReferences.prefix(2) {
                citationParts.append("\(ref.collection) \(ref.hadithNumber)")
            }
            if !citationParts.isEmpty {
                citations = "\n\n**Sources:** " + citationParts.joined(separator: ", ")
            }
        }

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

            Saying Bismillah brings barakah (blessing) to your food! 🤲
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

            Would you like me to explain any step in more detail? 🤲
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

            For complex situations, please consult a qualified scholar. 🤲
            """ + citations
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

            **Virtues:** The Prophet ﷺ said: "Whoever does not recite Al-Fatiha in his prayer, his prayer is incomplete." (Sahih Bukhari 756)

            Would you like me to explain the tafsir (interpretation) of any specific verse? 🤲
            """
        }

        // Default response with RAG citations if available
        return """
        Thank you for your question. I'm Safa, your Islamic companion assistant.

        This is a placeholder response while the AI model integration is being completed. In the full version, I will provide detailed, sourced answers to your questions about Islam, including:

        - Quran verses and their explanations
        - Authentic hadith with proper citations
        - Fiqh rulings from the major madhabs
        - Duas and dhikr with Arabic, transliteration, and translation

        **Note:** For complex religious rulings (fatawa), I recommend consulting a qualified scholar.
        """ + citations
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
