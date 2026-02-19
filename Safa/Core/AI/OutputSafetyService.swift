// MARK: - OutputSafetyService.swift
// PURPOSE: Post-LLM output safety validation — scans for disallowed content and citation gaps
// DEPENDENCIES: Foundation, OutputSafetyServiceProtocol, Citation

import Foundation

struct OutputSafetyService: OutputSafetyServiceProtocol {

    // MARK: - Public

    func validate(answer: String, citations: [Citation]) -> OutputDecision {
        let lowercased = answer.lowercased()

        // Empty answers are vacuously safe
        if lowercased.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return .pass
        }

        // 1. Disallowed content scan
        if let reason = scanForPoliticalContent(lowercased) {
            return .fail(reason: reason)
        }

        if let reason = scanForSectarianContent(lowercased) {
            return .fail(reason: reason)
        }

        if let reason = scanForFatwaCertainty(lowercased) {
            return .fail(reason: reason)
        }

        // 2. Citation verification — religious claims must have at least one verified citation
        if containsIslamicGuidance(lowercased) {
            let hasVerifiedCitation = citations.contains { $0.verified }
            if !hasVerifiedCitation {
                let reason = citations.isEmpty
                    ? "Religious guidance provided without any citations"
                    : "Religious guidance provided but no citations are verified"
                return .fail(reason: reason)
            }
        }

        return .pass
    }

    // MARK: - Political Content

    private static let politicalPartyPatterns: [String] = [
        "republican party",
        "democratic party",
        "labour party",
        "conservative party",
        "vote for",
        "voting recommendation",
        "election campaign",
        "government is corrupt",
        "overthrow the government",
        "regime change"
    ]

    private static let politicalKeywords: [String] = [
        "vote for",
        "elect ",
        "political party",
        "government criticism"
    ]

    private func scanForPoliticalContent(_ text: String) -> String? {
        for pattern in Self.politicalPartyPatterns {
            if text.contains(pattern) {
                return "Political content detected: references to political parties or electoral recommendations"
            }
        }
        return nil
    }

    // MARK: - Sectarian Content

    private static let sectarianPatterns: [String] = [
        "the only true sect",
        "the only true islam",
        "are not real muslims",
        "is not a real muslim",
        "are kafir",
        "is kafir",
        "they are infidels",
        "he is an infidel",
        "she is an infidel",
        "declare them non-muslim",
        "declare him non-muslim",
        "declare her non-muslim",
        "is superior to",
        "sect is the best",
        "sect is wrong",
        "sect is deviant"
    ]

    private static let takfirPatterns: [String] = [
        "i declare",
        "we declare them",
        "they are kuffar",
        "are apostates",
        "is an apostate"
    ]

    private func scanForSectarianContent(_ text: String) -> String? {
        for pattern in Self.sectarianPatterns {
            if text.contains(pattern) {
                return "Sectarian content detected: declaring one group superior or insulting another"
            }
        }

        for pattern in Self.takfirPatterns {
            if text.contains(pattern) {
                return "Takfir content detected: declaring Muslims as non-Muslim"
            }
        }

        // "kafir" used as insult — check surrounding context
        if let range = text.range(of: "kafir") {
            let start = text.index(range.lowerBound, offsetBy: -30, limitedBy: text.startIndex) ?? text.startIndex
            let end = text.index(range.upperBound, offsetBy: 30, limitedBy: text.endIndex) ?? text.endIndex
            let context = String(text[start..<end])

            let insultIndicators = ["you are", "he is", "she is", "they are", "call them", "called a"]
            for indicator in insultIndicators {
                if context.contains(indicator) {
                    return "Sectarian content detected: 'kafir' used as a personal insult"
                }
            }
        }

        return nil
    }

    // MARK: - Fatwa Certainty Claims

    private static let certaintyClaims: [String] = [
        "you must",
        "it is haram for you to",
        "it is obligatory for you to",
        "the only correct opinion is",
        "the only correct view is",
        "there is no difference of opinion",
        "this is absolutely haram",
        "this is absolutely forbidden",
        "anyone who does this"
    ]

    private static let qualifyingPhrases: [String] = [
        "scholars say",
        "scholars differ",
        "scholars have different",
        "according to",
        "in the view of",
        "the majority of scholars",
        "some scholars",
        "many scholars",
        "one opinion is",
        "there are different opinions",
        "allah knows best",
        "and allah knows best",
        "consult a scholar",
        "consult your local",
        "speak to a knowledgeable"
    ]

    private func scanForFatwaCertainty(_ text: String) -> String? {
        let hasCertaintyClaim = Self.certaintyClaims.contains { text.contains($0) }

        guard hasCertaintyClaim else {
            return nil
        }

        let hasQualifier = Self.qualifyingPhrases.contains { text.contains($0) }

        if hasQualifier {
            return nil
        }

        return "Fatwa certainty claim detected without qualifying scholarly attribution"
    }

    // MARK: - Islamic Guidance Detection

    private static let islamicTerms: [String] = [
        "quran",
        "qur'an",
        "hadith",
        "sunnah",
        "prophet muhammad",
        "prophet (pbuh)",
        "the prophet said",
        "allah says",
        "allah said",
        "surah",
        "ayah",
        "verse says",
        "fiqh",
        "shariah",
        "sharia",
        "haram",
        "halal",
        "wajib",
        "fard",
        "makruh",
        "sunnah prayer",
        "islamic ruling",
        "islamic law",
        "it is permissible",
        "it is not permissible",
        "it is recommended"
    ]

    private static let guidanceIndicators: [String] = [
        "you should pray",
        "you should fast",
        "you should give",
        "the ruling is",
        "the ruling on",
        "according to islam",
        "in islam,",
        "islam teaches",
        "islam says"
    ]

    private func containsIslamicGuidance(_ text: String) -> Bool {
        let hasIslamicTerms = Self.islamicTerms.contains { text.contains($0) }
        let hasGuidanceIndicators = Self.guidanceIndicators.contains { text.contains($0) }

        // Require both an Islamic term AND a guidance indicator to flag as religious guidance.
        // A casual mention of "Quran" alone does not constitute guidance.
        return hasIslamicTerms && hasGuidanceIndicators
    }
}
