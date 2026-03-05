// MARK: - RAGService.swift
// PURPOSE: Retrieval-Augmented Generation for Quran and Hadith context
// DEPENDENCIES: Foundation, QuranRepository, HadithRepository

import Foundation

// MARK: - RAG Context

struct RAGContext {
    let quranReferences: [QuranReference]
    let hadithReferences: [HadithReference]
    let duaReferences: [DuaReference]
    let topic: RAGTopic

    var isEmpty: Bool {
        quranReferences.isEmpty && hadithReferences.isEmpty && duaReferences.isEmpty
    }

    var formattedContext: String {
        var context = ""

        if !quranReferences.isEmpty {
            context += "## Relevant Quran Ayahs\n\n"
            for ref in quranReferences {
                context += """
                **Surah \(ref.surahName) (\(ref.surahNumber):\(ref.ayahNumber))**
                Arabic: \(ref.arabic)
                Translation: \(ref.translation)

                """
            }
        }

        if !hadithReferences.isEmpty {
            context += "\n## Relevant Hadith\n\n"
            for ref in hadithReferences {
                context += """
                **\(ref.collection)** - \(ref.narrator)
                \(ref.text)
                Grading: \(ref.grading)

                """
            }
        }

        if !duaReferences.isEmpty {
            context += "\n## Relevant Duas\n\n"
            for ref in duaReferences {
                context += """
                **\(ref.title)** (ID: \(ref.duaId))
                Arabic: \(ref.arabic)
                Translation: \(ref.translation)
                \(ref.source.map { "Source: \($0)" } ?? "")

                """
            }
        }

        return context
    }
}

struct QuranReference: Identifiable {
    let id = UUID()
    let surahNumber: Int
    let surahName: String
    let ayahNumber: Int
    let arabic: String
    let translation: String
    let relevanceScore: Double
}

struct HadithReference: Identifiable {
    let id = UUID()
    let collection: String
    let hadithNumber: Int
    let narrator: String
    let text: String
    let grading: String
    let relevanceScore: Double
}

struct DuaReference: Identifiable {
    let id = UUID()
    let duaId: String
    let title: String
    let arabic: String
    let translation: String
    let source: String?
    let relevanceScore: Double
}

enum RAGTopic: String, CaseIterable {
    case prayer
    case fasting
    case zakat
    case hajj
    case dua
    case wudu
    case quran
    case hadith
    case seerah
    case fiqh
    case aqeedah
    case general
}

// MARK: - RAG Service

final class RAGService: RAGServiceProtocol {
    // MARK: - Dependencies
    private let quranRepository: QuranRepositoryProtocol
    private let hadithRepository: HadithRepositoryProtocol
    private let duaRepository: DuaRepositoryProtocol

    // MARK: - Keyword Mappings
    private let topicKeywords: [RAGTopic: [String]] = [
        .prayer: ["salah", "salat", "prayer", "namaz", "rakat", "rakah", "sujud", "prostration", "ruku", "bow", "qibla", "imam", "jamaat", "congregation", "fajr", "dhuhr", "asr", "maghrib", "isha", "jummah", "friday", "taraweeh", "tahajjud", "witr", "sunnah prayer"],
        .fasting: ["fast", "fasting", "sawm", "siyam", "suhoor", "sehri", "iftar", "ramadan", "break fast", "exempt", "kaffarah", "fidyah"],
        .zakat: ["zakat", "zakah", "charity", "sadaqah", "nisab", "wealth", "poor", "needy", "2.5%"],
        .hajj: ["hajj", "umrah", "pilgrimage", "mecca", "makkah", "kaaba", "tawaf", "sai", "ihram", "arafat", "mina", "muzdalifah", "jamarat"],
        .dua: ["dua", "supplication", "asking", "request", "dhikr", "remembrance", "tasbih", "istighfar", "morning dhikr", "evening dhikr"],
        .wudu: ["wudu", "wudhu", "ablution", "purification", "ghusl", "tayammum", "wash", "ritual purity", "break wudu"],
        .quran: ["quran", "ayah", "verse", "surah", "chapter", "recitation", "tajweed", "tafsir", "meaning", "revelation"],
        .hadith: ["hadith", "prophet", "messenger", "sunnah", "sahih", "bukhari", "muslim", "tirmidhi", "abu dawud", "narrator"],
        .seerah: ["seerah", "prophet", "life", "biography", "migration", "hijra", "battle", "companion", "sahaba"],
        .fiqh: ["halal", "haram", "permissible", "forbidden", "ruling", "madhab", "hanafi", "maliki", "shafi", "hanbali", "allowed", "prohibited"],
        .aqeedah: ["belief", "faith", "iman", "tawhid", "angels", "prophets", "day of judgment", "qadr", "destiny", "jannah", "paradise", "jahannam", "hell"]
    ]

    // MARK: - Init
    init(quranRepository: QuranRepositoryProtocol, hadithRepository: HadithRepositoryProtocol, duaRepository: DuaRepositoryProtocol) {
        self.quranRepository = quranRepository
        self.hadithRepository = hadithRepository
        self.duaRepository = duaRepository
    }

    // MARK: - Retrieve Context

    func retrieveContext(for query: String, context: ChatContext? = nil) async -> RAGContext {
        let topic = context.map { mapChatTopic($0.topic) } ?? detectTopic(from: query)
        var keywords = extractKeywords(from: query)

        // Bias keywords from ChatContext if present
        if let ctx = context {
            if let surah = ctx.surahNumber {
                keywords.append("surah \(surah)")
            }
            if let ayah = ctx.ayahNumber {
                keywords.append("ayah \(ayah)")
            }
            if let hadithId = ctx.hadithId {
                keywords.append("hadith \(hadithId)")
            }
            if let duaId = ctx.duaId {
                keywords.append("dua \(duaId)")
            }
        }

        let resolvedKeywords = keywords
        async let quranResults = searchQuran(keywords: resolvedKeywords, topic: topic)
        async let hadithResults = searchHadith(keywords: resolvedKeywords, topic: topic)
        async let duaResults = searchDuas(keywords: resolvedKeywords, topic: topic)

        let quranRefs = await quranResults
        let hadithRefs = await hadithResults
        let duaRefs = await duaResults

        // Apply diversity-aware truncation when total references > 8
        let (truncQuran, truncHadith, truncDua) = truncateWithDiversity(
            quran: quranRefs, hadith: hadithRefs, dua: duaRefs, limit: 8
        )

        return RAGContext(
            quranReferences: truncQuran,
            hadithReferences: truncHadith,
            duaReferences: truncDua,
            topic: topic
        )
    }

    /// Map ChatTopic to RAGTopic for context-biased retrieval.
    private func mapChatTopic(_ chatTopic: ChatTopic) -> RAGTopic {
        switch chatTopic {
        case .quran: return .quran
        case .hadith: return .hadith
        case .fiqh: return .fiqh
        case .seerah: return .seerah
        case .dua: return .dua
        case .general: return .general
        }
    }

    // MARK: - Topic Detection

    private func detectTopic(from query: String) -> RAGTopic {
        let lowercaseQuery = query.lowercased()

        var topicScores: [RAGTopic: Int] = [:]

        for (topic, keywords) in topicKeywords {
            let score = keywords.reduce(0) { count, keyword in
                lowercaseQuery.contains(keyword) ? count + 1 : count
            }
            if score > 0 {
                topicScores[topic] = score
            }
        }

        // Return topic with highest score, with deterministic tie-breaking by priority order.
        // Priority: more specific topics win over general ones when scores are equal.
        let topicPriority: [RAGTopic] = [
            .prayer, .fasting, .zakat, .hajj, .wudu, .dua,
            .quran, .hadith, .seerah, .fiqh, .aqeedah, .general
        ]
        return topicScores
            .sorted { a, b in
                if a.value != b.value { return a.value > b.value }
                // Tie-break: lower index in priority list wins
                let aPriority = topicPriority.firstIndex(of: a.key) ?? Int.max
                let bPriority = topicPriority.firstIndex(of: b.key) ?? Int.max
                return aPriority < bPriority
            }
            .first?.key ?? .general
    }

    // MARK: - Keyword Extraction

    private func extractKeywords(from query: String) -> [String] {
        // Common stop words to filter out
        let stopWords = Set(["what", "how", "when", "where", "why", "which", "who",
                             "is", "are", "was", "were", "be", "been", "being",
                             "have", "has", "had", "do", "does", "did", "will", "would",
                             "could", "should", "may", "might", "must", "shall",
                             "the", "a", "an", "and", "or", "but", "in", "on", "at",
                             "to", "for", "of", "with", "by", "from", "as", "into",
                             "through", "during", "before", "after", "above", "below",
                             "i", "me", "my", "we", "our", "you", "your", "he", "she",
                             "it", "they", "them", "this", "that", "these", "those",
                             "can", "please", "tell", "explain", "about", "want", "need"])

        let words = query.lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty && !stopWords.contains($0) && $0.count > 2 }

        return Array(Set(words)).sorted()
    }

    // MARK: - Quran Search

    private func searchQuran(keywords: [String], topic: RAGTopic) async -> [QuranReference] {
        var references: [QuranReference] = []

        // Search for each keyword
        for keyword in keywords.prefix(3) { // Limit to 3 keywords for performance
            do {
                let ayahs = try await quranRepository.searchAyahs(query: keyword)

                for ayah in ayahs.prefix(2) { // Limit results per keyword
                    let surah = try await quranRepository.getSurah(number: ayah.surahNumber)

                    let reference = QuranReference(
                        surahNumber: ayah.surahNumber,
                        surahName: surah?.nameEnglish ?? "Unknown",
                        ayahNumber: ayah.ayahNumber,
                        arabic: ayah.textArabic,
                        translation: ayah.textTranslation,
                        relevanceScore: calculateRelevance(text: ayah.textTranslation, keywords: keywords)
                    )
                    references.append(reference)
                }
            } catch {
                // Continue with other keywords if one fails
                continue
            }
        }

        // Sort by relevance and deduplicate
        let uniqueRefs = Dictionary(grouping: references) { "\($0.surahNumber):\($0.ayahNumber)" }
            .compactMap { $0.value.first }
            .sorted { $0.relevanceScore > $1.relevanceScore }

        return Array(uniqueRefs.prefix(3)) // Return top 3 results
    }

    // MARK: - Hadith Search

    private func searchHadith(keywords: [String], topic: RAGTopic) async -> [HadithReference] {
        var references: [HadithReference] = []

        // Search for each keyword
        for keyword in keywords.prefix(3) {
            do {
                let hadiths = try await hadithRepository.searchHadiths(query: keyword)

                for hadith in hadiths.prefix(2) {
                    let reference = HadithReference(
                        collection: hadith.collectionId,
                        hadithNumber: hadith.hadithNumber,
                        narrator: hadith.narrator,
                        text: hadith.textEnglish,
                        grading: hadith.grading?.displayName ?? "Unknown",
                        relevanceScore: calculateRelevance(text: hadith.textEnglish, keywords: keywords)
                    )
                    references.append(reference)
                }
            } catch {
                continue
            }
        }

        // Sort by relevance and deduplicate
        let uniqueRefs = Dictionary(grouping: references) { "\($0.collection):\($0.hadithNumber)" }
            .compactMap { $0.value.first }
            .sorted { $0.relevanceScore > $1.relevanceScore }

        return Array(uniqueRefs.prefix(3))
    }

    // MARK: - Dua Search

    private func searchDuas(keywords: [String], topic: RAGTopic) async -> [DuaReference] {
        var references: [DuaReference] = []

        for keyword in keywords.prefix(3) {
            do {
                let duas = try await duaRepository.searchDuas(query: keyword)

                for dua in duas.prefix(2) {
                    let reference = DuaReference(
                        duaId: dua.id,
                        title: dua.titleEnglish,
                        arabic: dua.textArabic,
                        translation: dua.textTranslation,
                        source: dua.source,
                        relevanceScore: calculateRelevance(text: dua.textTranslation, keywords: keywords)
                    )
                    references.append(reference)
                }
            } catch {
                continue
            }
        }

        // Sort by relevance and deduplicate by duaId
        let uniqueRefs = Dictionary(grouping: references) { $0.duaId }
            .compactMap { $0.value.first }
            .sorted { $0.relevanceScore > $1.relevanceScore }

        return Array(uniqueRefs.prefix(3))
    }

    // MARK: - Diversity-Aware Truncation

    /// When total references exceed the limit, truncate while preserving at least 1 from each source type that has results.
    private func truncateWithDiversity(
        quran: [QuranReference],
        hadith: [HadithReference],
        dua: [DuaReference],
        limit: Int
    ) -> ([QuranReference], [HadithReference], [DuaReference]) {
        let total = quran.count + hadith.count + dua.count
        guard total > limit else { return (quran, hadith, dua) }

        // Tag each reference with its score for unified ranking
        enum TaggedRef: Comparable {
            case quran(Int, Double)
            case hadith(Int, Double)
            case dua(Int, Double)

            var score: Double {
                switch self {
                case .quran(_, let s), .hadith(_, let s), .dua(_, let s): return s
                }
            }

            static func < (lhs: TaggedRef, rhs: TaggedRef) -> Bool {
                lhs.score < rhs.score
            }
        }

        // Guarantee at least 1 per source type that has results
        var quranSlots = quran.isEmpty ? 0 : 1
        var hadithSlots = hadith.isEmpty ? 0 : 1
        var duaSlots = dua.isEmpty ? 0 : 1
        let guaranteed = quranSlots + hadithSlots + duaSlots
        let remaining = limit - guaranteed

        // Build ranked list of non-guaranteed items
        var ranked: [TaggedRef] = []
        for (i, ref) in quran.enumerated() where i >= quranSlots {
            ranked.append(.quran(i, ref.relevanceScore))
        }
        for (i, ref) in hadith.enumerated() where i >= hadithSlots {
            ranked.append(.hadith(i, ref.relevanceScore))
        }
        for (i, ref) in dua.enumerated() where i >= duaSlots {
            ranked.append(.dua(i, ref.relevanceScore))
        }
        ranked.sort(by: >)

        // Fill remaining slots by relevance
        for item in ranked.prefix(remaining) {
            switch item {
            case .quran: quranSlots += 1
            case .hadith: hadithSlots += 1
            case .dua: duaSlots += 1
            }
        }

        return (
            Array(quran.prefix(quranSlots)),
            Array(hadith.prefix(hadithSlots)),
            Array(dua.prefix(duaSlots))
        )
    }

    // MARK: - Relevance Scoring

    private func calculateRelevance(text: String, keywords: [String]) -> Double {
        let lowercaseText = text.lowercased()
        let matchCount = keywords.filter { lowercaseText.contains($0) }.count
        return Double(matchCount) / Double(max(keywords.count, 1))
    }

    // MARK: - Format Citations

    func formatCitations(from context: RAGContext) -> String {
        var citations: [String] = []

        for ref in context.quranReferences {
            citations.append("(Quran \(ref.surahNumber):\(ref.ayahNumber))")
        }

        for ref in context.hadithReferences {
            citations.append("(\(ref.collection) \(ref.hadithNumber))")
        }

        for ref in context.duaReferences {
            citations.append("(Dua: \(ref.title))")
        }

        return citations.joined(separator: ", ")
    }
}
