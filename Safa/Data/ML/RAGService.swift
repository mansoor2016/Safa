// MARK: - RAGService.swift
// PURPOSE: Retrieval-Augmented Generation for Quran and Hadith context
// DEPENDENCIES: Foundation, QuranRepository, HadithRepository

import Foundation

// MARK: - RAG Context

struct RAGContext {
    let quranReferences: [QuranReference]
    let hadithReferences: [HadithReference]
    let topic: RAGTopic

    var isEmpty: Bool {
        quranReferences.isEmpty && hadithReferences.isEmpty
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

final class RAGService {
    // MARK: - Dependencies
    private let quranRepository: QuranRepositoryProtocol
    private let hadithRepository: HadithRepositoryProtocol

    // MARK: - Keyword Mappings
    private let topicKeywords: [RAGTopic: [String]] = [
        .prayer: ["salah", "salat", "prayer", "namaz", "rakat", "rakah", "sujud", "prostration", "ruku", "bow", "qibla", "imam", "jamaat", "congregation", "fajr", "dhuhr", "asr", "maghrib", "isha", "jummah", "friday", "taraweeh", "tahajjud", "witr", "sunnah prayer"],
        .fasting: ["fast", "fasting", "sawm", "siyam", "suhoor", "sehri", "iftar", "ramadan", "break fast", "exempt", "kaffarah", "fidyah"],
        .zakat: ["zakat", "zakah", "charity", "sadaqah", "nisab", "wealth", "poor", "needy", "2.5%"],
        .hajj: ["hajj", "umrah", "pilgrimage", "mecca", "makkah", "kaaba", "tawaf", "sai", "ihram", "arafat", "mina", "muzdalifah", "jamarat"],
        .dua: ["dua", "supplication", "prayer", "asking", "request", "dhikr", "remembrance", "tasbih", "istighfar", "morning adhkar", "evening adhkar"],
        .wudu: ["wudu", "wudhu", "ablution", "purification", "ghusl", "tayammum", "wash", "ritual purity", "break wudu"],
        .quran: ["quran", "ayah", "verse", "surah", "chapter", "recitation", "tajweed", "tafsir", "meaning", "revelation"],
        .hadith: ["hadith", "prophet", "messenger", "sunnah", "sahih", "bukhari", "muslim", "tirmidhi", "abu dawud", "narrator"],
        .seerah: ["seerah", "prophet", "life", "biography", "migration", "hijra", "battle", "companion", "sahaba"],
        .fiqh: ["halal", "haram", "permissible", "forbidden", "ruling", "madhab", "hanafi", "maliki", "shafi", "hanbali", "allowed", "prohibited"],
        .aqeedah: ["belief", "faith", "iman", "tawhid", "angels", "prophets", "day of judgment", "qadr", "destiny", "jannah", "paradise", "jahannam", "hell"]
    ]

    // MARK: - Init
    init(quranRepository: QuranRepositoryProtocol, hadithRepository: HadithRepositoryProtocol) {
        self.quranRepository = quranRepository
        self.hadithRepository = hadithRepository
    }

    // MARK: - Retrieve Context

    func retrieveContext(for query: String) async -> RAGContext {
        let topic = detectTopic(from: query)
        let keywords = extractKeywords(from: query)

        async let quranResults = searchQuran(keywords: keywords, topic: topic)
        async let hadithResults = searchHadith(keywords: keywords, topic: topic)

        let quranRefs = await quranResults
        let hadithRefs = await hadithResults

        return RAGContext(
            quranReferences: quranRefs,
            hadithReferences: hadithRefs,
            topic: topic
        )
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

        // Return topic with highest score, or .general if no matches
        return topicScores.max(by: { $0.value < $1.value })?.key ?? .general
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

        return Array(Set(words))
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

        return citations.joined(separator: ", ")
    }
}
