// MARK: - InputSafetyService.swift
// PURPOSE: Pre-LLM input safety gate — sanitizes input, classifies topics, detects jailbreaks
// DEPENDENCIES: Foundation, InputSafetyServiceProtocol, RAGTopic

import Foundation

struct InputSafetyService: InputSafetyServiceProtocol {

    // MARK: - Constants

    private static let cautionWarning = "This topic may have varying scholarly interpretations. Sources are provided for your reference."

    private static let offTopicRefusal = "I'm designed to help with Islamic topics such as prayer, Quran, hadith, and fiqh. I'm not able to provide advice on this topic. Please feel free to ask me anything about Islam."

    private static let jailbreakRefusal = "I'm sorry, but I can only respond to genuine questions about Islam. Please ask a question about prayer, Quran, hadith, or other Islamic topics."

    // MARK: - Injection Markers

    private static let injectionMarkers: [String] = [
        "[INST]", "[/INST]", "<<SYS>>", "<</SYS>>", "</s>", "<s>",
        "[SYSTEM]", "[/SYSTEM]", "<<INST>>", "<|im_start|>", "<|im_end|>",
        "<|system|>", "<|user|>", "<|assistant|>"
    ]

    // MARK: - Jailbreak Patterns

    private static let jailbreakPatterns: [String] = [
        #"ignore\s+(all\s+)?(previous|prior|above|earlier)\s+(instructions?|prompts?|rules?|directives?)"#,
        #"disregard\s+(all\s+)?(previous|prior|above|earlier)\s+(instructions?|prompts?|rules?|directives?)"#,
        #"forget\s+(all\s+)?(previous|prior|above|earlier)\s+(instructions?|prompts?|rules?|directives?)"#,
        #"you\s+are\s+now\s+a"#,
        #"from\s+now\s+on\s+you\s+are"#,
        #"pretend\s+(you\s+are|to\s+be)"#,
        #"act\s+as\s+(if\s+you\s+are|a|an)"#,
        #"role\s*play\s+as"#,
        #"system\s*prompt"#,
        #"repeat\s+(your|the)\s+(instructions?|rules?|prompt|system\s*message)"#,
        #"what\s+are\s+your\s+(rules?|instructions?|directives?|system\s*prompt)"#,
        #"show\s+(me\s+)?(your|the)\s+(rules?|instructions?|prompt)"#,
        #"output\s+(your|the)\s+(system|initial)\s*(prompt|instructions?|message)"#,
        #"override\s+(your|the|all)\s+(rules?|instructions?|safety|filters?)"#,
        #"bypass\s+(your|the|all)\s+(rules?|instructions?|safety|filters?)"#,
        #"jailbreak"#,
        #"do\s+anything\s+now"#,
        #"developer\s+mode"#,
        #"dan\s+mode"#
    ]

    // MARK: - Off-Topic Keywords

    private static let politicalKeywords: [String] = [
        "election", "democrat", "republican", "liberal", "conservative",
        "vote", "voting", "candidate", "political party", "parliament",
        "geopolitics", "government policy", "legislation", "senator",
        "congressman", "prime minister", "president of", "foreign policy",
        "sanctions", "military strike", "political opinion", "left wing",
        "right wing", "propaganda", "partisan"
    ]

    private static let medicalKeywords: [String] = [
        "diagnose", "diagnosis", "prescription", "medication", "dosage",
        "medical treatment", "should i take", "symptoms of", "cure for",
        "medical advice", "side effects", "drug interaction", "surgery",
        "medical condition", "clinical trial", "therapy for",
        "is it safe to take", "what medicine"
    ]

    private static let financialKeywords: [String] = [
        "stock tip", "invest in", "buy stocks", "sell stocks",
        "cryptocurrency", "bitcoin", "forex trading", "financial advice",
        "portfolio", "investment strategy", "day trading", "hedge fund",
        "mutual fund", "retirement plan", "tax advice", "tax strategy",
        "financial planning", "which stock", "market prediction"
    ]

    // MARK: - Islamic Topic Keywords

    private static let islamicTopicKeywords: [RAGTopic: [String]] = [
        .prayer: ["salah", "salat", "prayer", "namaz", "rakat", "rakah", "sujud", "prostration",
                   "ruku", "bow", "qibla", "imam", "jamaat", "congregation", "fajr", "dhuhr",
                   "asr", "maghrib", "isha", "jummah", "friday prayer", "taraweeh", "tahajjud",
                   "witr", "sunnah prayer", "pray"],
        .fasting: ["fast", "fasting", "sawm", "siyam", "suhoor", "sehri", "iftar", "ramadan",
                    "break fast", "kaffarah", "fidyah"],
        .zakat: ["zakat", "zakah", "charity", "sadaqah", "nisab", "alms"],
        .hajj: ["hajj", "umrah", "pilgrimage", "mecca", "makkah", "kaaba", "tawaf", "sai",
                 "ihram", "arafat", "mina", "muzdalifah", "jamarat"],
        .dua: ["dua", "supplication", "dhikr", "remembrance", "tasbih", "istighfar",
                "morning dhikr", "evening dhikr", "azkar"],
        .wudu: ["wudu", "wudhu", "ablution", "purification", "ghusl", "tayammum",
                 "ritual purity", "break wudu"],
        .quran: ["quran", "ayah", "verse", "surah", "chapter", "recitation", "tajweed",
                  "tafsir", "revelation", "recite"],
        .hadith: ["hadith", "prophet said", "messenger said", "sunnah", "sahih", "bukhari",
                   "muslim", "tirmidhi", "abu dawud", "narrator", "narrated"],
        .seerah: ["seerah", "prophet muhammad", "biography", "migration", "hijra", "hijrah",
                   "battle of", "companion", "sahaba", "sahabi"],
        .fiqh: ["halal", "haram", "permissible", "forbidden", "ruling", "madhab", "hanafi",
                 "maliki", "shafi", "hanbali", "allowed", "prohibited", "fatwa", "jurisprudence",
                 "fiqh", "scholarly opinion"],
        .aqeedah: ["belief", "faith", "iman", "tawhid", "angels", "day of judgment", "qadr",
                    "destiny", "jannah", "paradise", "jahannam", "hell", "aqeedah", "creed",
                    "pillars of faith", "afterlife"],
        .general: ["islam", "muslim", "allah", "bismillah", "alhamdulillah", "subhanallah",
                    "inshallah", "mashallah", "assalamu", "salam", "islamic", "mosque", "masjid",
                    "eid", "sharia", "ummah", "dawah"]
    ]

    // MARK: - Topic Classification Result

    enum TopicResult {
        case allow
        case caution(warning: String)
        case decline(reason: String)
    }

    // MARK: - Protocol

    func evaluate(_ text: String, context: ChatContext?) -> SafetyDecision {
        let sanitized = sanitize(text)

        // Empty or whitespace-only input is harmless
        if sanitized.trimmingCharacters(in: .whitespaces).isEmpty {
            return .allow
        }

        // Check jailbreak first — highest priority
        if detectJailbreak(sanitized) {
            return .decline(refusalText: Self.jailbreakRefusal)
        }

        // Classify topic from text
        let topicResult = classifyTopic(sanitized)

        // If ChatContext provides a topic (from a contextual entry point like
        // "Ask about this ayah"), still enforce off-topic/political/medical/financial
        // declines, but use the context topic for the Islamic topic decision
        // to avoid false off-topic declines on short or ambiguous text.
        if let context {
            switch topicResult {
            case .decline(let reason):
                // Off-topic content is declined even with context
                return .decline(refusalText: reason)
            case .caution, .allow:
                // Use context topic to determine caution level
                switch context.topic {
                case .fiqh:
                    return .allowWithCaution(warning: Self.cautionWarning)
                case .quran, .hadith, .seerah, .dua, .general:
                    return .allow
                }
            }
        }

        switch topicResult {
        case .decline(let reason):
            return .decline(refusalText: reason)
        case .caution(let warning):
            return .allowWithCaution(warning: warning)
        case .allow:
            return .allow
        }
    }

    // MARK: - Input Sanitization

    func sanitize(_ text: String) -> String {
        var result = text

        // 1. Trim leading/trailing whitespace and newlines
        result = result.trimmingCharacters(in: .whitespacesAndNewlines)

        // 2. Normalize unicode to NFKC
        result = result.precomposedStringWithCompatibilityMapping

        // 3. Strip injection markers (case-insensitive)
        for marker in Self.injectionMarkers {
            // Use case-insensitive replacement
            let range = result.range(of: marker, options: .caseInsensitive)
            while let found = result.range(of: marker, options: .caseInsensitive) {
                result.replaceSubrange(found, with: "")
            }
            _ = range // suppress unused warning
        }

        // 4. Collapse repeated symbols (3+ of same char → 2)
        result = collapseRepeatedCharacters(result)

        // 5. Trim again after transformations
        result = result.trimmingCharacters(in: .whitespacesAndNewlines)

        return result
    }

    // MARK: - Collapse Repeated Characters

    private func collapseRepeatedCharacters(_ text: String) -> String {
        guard !text.isEmpty else { return text }

        var result: [Character] = []
        var lastChar: Character?
        var repeatCount = 0

        for char in text {
            if char == lastChar {
                repeatCount += 1
                if repeatCount < 2 {
                    result.append(char)
                }
                // If repeatCount >= 2, skip (already have 2 of this char)
            } else {
                result.append(char)
                lastChar = char
                repeatCount = 0
            }
        }

        return String(result)
    }

    // MARK: - Jailbreak Detection

    func detectJailbreak(_ text: String) -> Bool {
        let lowered = text.lowercased()

        for pattern in Self.jailbreakPatterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                let range = NSRange(lowered.startIndex..., in: lowered)
                if regex.firstMatch(in: lowered, range: range) != nil {
                    return true
                }
            }
        }

        return false
    }

    // MARK: - Topic Classification

    func classifyTopic(_ text: String) -> TopicResult {
        let lowered = text.lowercased()

        // Check off-topic categories first
        if matchesKeywords(lowered, keywords: Self.politicalKeywords) {
            return .decline(reason: Self.offTopicRefusal)
        }

        if matchesKeywords(lowered, keywords: Self.medicalKeywords) {
            return .decline(reason: Self.offTopicRefusal)
        }

        if matchesKeywords(lowered, keywords: Self.financialKeywords) {
            return .decline(reason: Self.offTopicRefusal)
        }

        // Score Islamic topics
        let detectedTopic = detectIslamicTopic(lowered)

        switch detectedTopic {
        case .fiqh:
            return .caution(warning: Self.cautionWarning)
        case .prayer, .fasting, .zakat, .hajj, .dua, .wudu,
             .quran, .hadith, .seerah, .aqeedah:
            return .allow
        case .general:
            // .general means no specific Islamic topic matched.
            // Check if any general Islamic keyword matched — if so, allow.
            // Otherwise the prompt is truly off-topic.
            let generalKeywords = Self.islamicTopicKeywords[.general] ?? []
            let hasGeneralMatch = generalKeywords.contains { lowered.contains($0) }
            return hasGeneralMatch ? .allow : .decline(reason: Self.offTopicRefusal)
        }
    }

    // MARK: - Islamic Topic Detection

    private func detectIslamicTopic(_ lowered: String) -> RAGTopic {
        var topicScores: [RAGTopic: Int] = [:]

        for (topic, keywords) in Self.islamicTopicKeywords {
            let score = keywords.reduce(0) { count, keyword in
                lowered.contains(keyword) ? count + 1 : count
            }
            if score > 0 {
                topicScores[topic] = score
            }
        }

        return topicScores.max(by: { $0.value < $1.value })?.key ?? .general
    }

    // MARK: - Keyword Matching

    private func matchesKeywords(_ text: String, keywords: [String]) -> Bool {
        keywords.contains { text.contains($0) }
    }
}
