// MARK: - SpotlightIndexService.swift
// PURPOSE: CoreSpotlight indexing for Quran, Hadith, and Dua search from iOS Spotlight
// DEPENDENCIES: CoreSpotlight, MobileCoreServices

import Foundation
import CoreSpotlight
import MobileCoreServices
import UniformTypeIdentifiers

// MARK: - Indexable Content Types

enum SpotlightContentType: String {
    case surah = "surah"
    case ayah = "ayah"
    case hadith = "hadith"
    case dua = "dua"
    case namesOfAllah = "names_of_allah"

    var domainIdentifier: String {
        "com.safa.\(rawValue)"
    }

    var activityType: String {
        "com.safa.activity.\(rawValue)"
    }
}

// MARK: - Spotlight Index Service

@Observable
final class SpotlightIndexService {
    static let shared = SpotlightIndexService()

    // MARK: - Properties

    private(set) var isIndexing = false
    private(set) var indexedItemCount = 0
    private(set) var lastIndexDate: Date?

    private let searchableIndex = CSSearchableIndex.default()
    private let userDefaults = UserDefaults.standard

    // Storage Keys
    private let indexedKey = "com.safa.spotlight.indexed"
    private let indexDateKey = "com.safa.spotlight.indexDate"
    private let indexCountKey = "com.safa.spotlight.indexCount"

    // MARK: - Init

    private init() {
        loadIndexState()
    }

    // MARK: - Public Methods

    /// Index all content (called on first launch or when content updates)
    func indexAllContent() async {
        guard !isIndexing else { return }

        isIndexing = true
        defer { isIndexing = false }

        var totalIndexed = 0

        // Index Surahs
        let surahCount = await indexSurahs()
        totalIndexed += surahCount

        // Index popular Ayahs
        let ayahCount = await indexPopularAyahs()
        totalIndexed += ayahCount

        // Index Duas
        let duaCount = await indexDuas()
        totalIndexed += duaCount

        // Index 99 Names of Allah
        let namesCount = await indexNamesOfAllah()
        totalIndexed += namesCount

        // Index Hadith Collections
        let hadithCount = await indexHadithCollections()
        totalIndexed += hadithCount

        indexedItemCount = totalIndexed
        lastIndexDate = Date()
        saveIndexState()
    }

    /// Index a single surah (when bookmarked)
    func indexSurah(_ surah: Surah) async {
        let item = createSearchableItem(for: surah)
        try? await searchableIndex.indexSearchableItems([item])
    }

    /// Index a single ayah (when bookmarked)
    func indexAyah(_ ayah: Ayah, surahName: String) async {
        let item = createSearchableItem(for: ayah, surahName: surahName)
        try? await searchableIndex.indexSearchableItems([item])
    }

    /// Remove all indexed items
    func removeAllIndexedItems() async {
        try? await searchableIndex.deleteAllSearchableItems()
        indexedItemCount = 0
        lastIndexDate = nil
        saveIndexState()
    }

    /// Remove items for a specific domain
    func removeItems(forDomain domain: SpotlightContentType) async {
        try? await searchableIndex.deleteSearchableItems(withDomainIdentifiers: [domain.domainIdentifier])
    }

    // MARK: - Deep Link Handling

    /// Handle Spotlight search result tap
    static func handleSpotlightResult(userActivity: NSUserActivity) -> SpotlightDestination? {
        guard let identifier = userActivity.userInfo?[CSSearchableItemActivityIdentifier] as? String else {
            return nil
        }

        return parseIdentifier(identifier)
    }

    /// Parse a Spotlight identifier into a destination
    static func parseIdentifier(_ identifier: String) -> SpotlightDestination? {
        let components = identifier.split(separator: "_")
        guard components.count >= 2 else { return nil }

        let type = String(components[0])

        switch type {
        case "surah":
            guard let number = Int(components[1]) else { return nil }
            return .surah(number: number)

        case "ayah":
            guard components.count >= 3,
                  let surah = Int(components[1]),
                  let ayah = Int(components[2]) else { return nil }
            return .ayah(surah: surah, ayah: ayah)

        case "hadith":
            let collection = String(components[1])
            let id = components.count > 2 ? String(components[2]) : nil
            return .hadith(collection: collection, id: id)

        case "dua":
            // Join remaining components for dua IDs like "dua_before_eating" → "before_eating"
            let idParts = components.dropFirst()
            let id = idParts.joined(separator: "_")
            return .dua(id: id)

        case "name":
            guard let number = Int(components[1]) else { return nil }
            return .nameOfAllah(number: number)

        default:
            return nil
        }
    }

    // MARK: - Index Surahs

    private func indexSurahs() async -> Int {
        var items: [CSSearchableItem] = []

        for surah in Surah.allSurahs {
            let item = createSearchableItem(for: surah)
            items.append(item)
        }

        do {
            try await searchableIndex.indexSearchableItems(items)
            return items.count
        } catch {
            print("SpotlightIndexService: Failed to index surahs: \(error)")
            return 0
        }
    }

    private func createSearchableItem(for surah: Surah) -> CSSearchableItem {
        let attributeSet = CSSearchableItemAttributeSet(contentType: .text)
        attributeSet.title = "\(surah.nameEnglish) (\(surah.nameArabic))"
        attributeSet.contentDescription = "Surah \(surah.id) - \(surah.nameTransliteration) - \(surah.ayahCount) verses - \(surah.revelationType.rawValue.capitalized)"
        attributeSet.keywords = [
            surah.nameEnglish,
            surah.nameArabic,
            surah.nameTransliteration,
            "Surah \(surah.id)",
            "Chapter \(surah.id)",
            "Quran"
        ]
        attributeSet.displayName = surah.nameEnglish

        let identifier = "surah_\(surah.id)"
        return CSSearchableItem(
            uniqueIdentifier: identifier,
            domainIdentifier: SpotlightContentType.surah.domainIdentifier,
            attributeSet: attributeSet
        )
    }

    // MARK: - Index Popular Ayahs

    private func indexPopularAyahs() async -> Int {
        var items: [CSSearchableItem] = []

        // Index Al-Fatiha ayahs
        for ayah in Ayah.alFatiha {
            let item = createSearchableItem(for: ayah, surahName: "Al-Fatiha")
            items.append(item)
        }

        // Index Ayatul Kursi (2:255)
        let ayatulKursi = CSSearchableItemAttributeSet(contentType: .text)
        ayatulKursi.title = "Ayatul Kursi (The Throne Verse)"
        ayatulKursi.contentDescription = "Surah Al-Baqarah, Ayah 255 - The most powerful verse in the Quran"
        ayatulKursi.keywords = ["Ayatul Kursi", "Throne Verse", "Al-Baqarah", "Protection", "Quran", "2:255"]
        items.append(CSSearchableItem(
            uniqueIdentifier: "ayah_2_255",
            domainIdentifier: SpotlightContentType.ayah.domainIdentifier,
            attributeSet: ayatulKursi
        ))

        // Index Surah Al-Ikhlas (112)
        let ikhlas = CSSearchableItemAttributeSet(contentType: .text)
        ikhlas.title = "Surah Al-Ikhlas (The Sincerity)"
        ikhlas.contentDescription = "Surah 112 - Equal to one-third of the Quran"
        ikhlas.keywords = ["Al-Ikhlas", "Ikhlas", "Sincerity", "Purity", "Quran", "Tawheed"]
        items.append(CSSearchableItem(
            uniqueIdentifier: "surah_112",
            domainIdentifier: SpotlightContentType.surah.domainIdentifier,
            attributeSet: ikhlas
        ))

        // Index Last 3 Surahs
        let lastThreeSurahs = [
            (112, "Al-Ikhlas", "Sincerity/Purity"),
            (113, "Al-Falaq", "The Daybreak"),
            (114, "An-Nas", "Mankind")
        ]

        for (number, name, meaning) in lastThreeSurahs {
            let attr = CSSearchableItemAttributeSet(contentType: .text)
            attr.title = "Surah \(name)"
            attr.contentDescription = "\(meaning) - Protection surahs"
            attr.keywords = [name, meaning, "Protection", "Quran", "Ruqyah"]
            items.append(CSSearchableItem(
                uniqueIdentifier: "surah_\(number)",
                domainIdentifier: SpotlightContentType.surah.domainIdentifier,
                attributeSet: attr
            ))
        }

        do {
            try await searchableIndex.indexSearchableItems(items)
            return items.count
        } catch {
            print("SpotlightIndexService: Failed to index ayahs: \(error)")
            return 0
        }
    }

    private func createSearchableItem(for ayah: Ayah, surahName: String) -> CSSearchableItem {
        let attributeSet = CSSearchableItemAttributeSet(contentType: .text)
        attributeSet.title = "\(surahName) \(ayah.surahNumber):\(ayah.ayahNumber)"
        attributeSet.contentDescription = ayah.textTranslation
        attributeSet.keywords = [
            surahName,
            "Ayah \(ayah.ayahNumber)",
            "Verse \(ayah.ayahNumber)",
            "Quran",
            "\(ayah.surahNumber):\(ayah.ayahNumber)"
        ]

        let identifier = "ayah_\(ayah.surahNumber)_\(ayah.ayahNumber)"
        return CSSearchableItem(
            uniqueIdentifier: identifier,
            domainIdentifier: SpotlightContentType.ayah.domainIdentifier,
            attributeSet: attributeSet
        )
    }

    // MARK: - Index Duas

    private func indexDuas() async -> Int {
        let popularDuas: [(String, String, String, [String])] = [
            ("dua_before_eating", "Dua Before Eating", "Bismillah - In the name of Allah", ["eating", "food", "meal", "bismillah"]),
            ("dua_after_eating", "Dua After Eating", "Alhamdulillah - Praise be to Allah who fed us", ["eating", "food", "alhamdulillah"]),
            ("dua_entering_home", "Dua When Entering Home", "Seeking Allah's blessing upon entering", ["home", "house", "entering"]),
            ("dua_leaving_home", "Dua When Leaving Home", "Seeking Allah's protection when going out", ["leaving", "travel", "protection"]),
            ("dua_before_sleep", "Dua Before Sleep", "Bismika Allahumma - Entrusting oneself to Allah", ["sleep", "night", "bedtime"]),
            ("dua_waking_up", "Dua When Waking Up", "Alhamdulillah - Thanks for giving us life", ["morning", "waking", "life"]),
            ("dua_istikhara", "Dua for Istikhara", "Seeking Allah's guidance in decisions", ["guidance", "decision", "istikhara", "choice"]),
            ("dua_anxiety", "Dua for Anxiety", "Seeking relief from worry and sadness", ["anxiety", "worry", "stress", "sadness"]),
            ("dua_protection", "Dua for Protection", "Morning and evening protection duas", ["protection", "morning", "evening", "dhikr"]),
            ("dua_forgiveness", "Dua for Forgiveness", "Seeking Allah's forgiveness", ["forgiveness", "tawbah", "repentance", "sins"])
        ]

        var items: [CSSearchableItem] = []

        for (id, title, description, keywords) in popularDuas {
            let attributeSet = CSSearchableItemAttributeSet(contentType: .text)
            attributeSet.title = title
            attributeSet.contentDescription = description
            attributeSet.keywords = keywords + ["dua", "supplication", "prayer", "islamic"]

            items.append(CSSearchableItem(
                uniqueIdentifier: id,
                domainIdentifier: SpotlightContentType.dua.domainIdentifier,
                attributeSet: attributeSet
            ))
        }

        do {
            try await searchableIndex.indexSearchableItems(items)
            return items.count
        } catch {
            print("SpotlightIndexService: Failed to index duas: \(error)")
            return 0
        }
    }

    // MARK: - Index Hadith Collections

    private func indexHadithCollections() async -> Int {
        // Index major hadith collections and popular hadiths
        let collections: [(String, String, String)] = [
            ("bukhari", "Sahih al-Bukhari", "The most authentic hadith collection compiled by Imam al-Bukhari"),
            ("muslim", "Sahih Muslim", "The second most authentic hadith collection compiled by Imam Muslim"),
            ("tirmidhi", "Jami at-Tirmidhi", "Hadith collection by Imam at-Tirmidhi"),
            ("abudawud", "Sunan Abu Dawud", "Hadith collection focusing on legal matters"),
            ("nasai", "Sunan an-Nasa'i", "Hadith collection by Imam an-Nasa'i"),
            ("ibnmajah", "Sunan Ibn Majah", "Hadith collection completing the six major books"),
            ("malik", "Muwatta Malik", "One of the earliest hadith collections by Imam Malik"),
            ("nawawi40", "40 Hadith an-Nawawi", "Essential collection of 40 hadiths by Imam an-Nawawi")
        ]

        var items: [CSSearchableItem] = []

        // Index collection entries
        for (id, name, description) in collections {
            let attributeSet = CSSearchableItemAttributeSet(contentType: .text)
            attributeSet.title = name
            attributeSet.contentDescription = description
            attributeSet.keywords = [
                name,
                id,
                "hadith",
                "sunnah",
                "prophet",
                "islamic"
            ]

            items.append(CSSearchableItem(
                uniqueIdentifier: "hadith_\(id)",
                domainIdentifier: SpotlightContentType.hadith.domainIdentifier,
                attributeSet: attributeSet
            ))
        }

        // Index popular individual hadiths
        let popularHadiths: [(String, String, String, String, [String])] = [
            ("bukhari_1", "Sahih al-Bukhari", "Actions are by intentions", "The reward of deeds depends upon the intentions", ["niyyah", "intention", "actions"]),
            ("bukhari_6011", "Sahih al-Bukhari", "The merciful will be shown mercy", "Allah will show mercy to those who show mercy to others", ["mercy", "rahma", "compassion"]),
            ("muslim_2564", "Sahih Muslim", "None of you truly believes", "None of you truly believes until he loves for his brother what he loves for himself", ["brotherhood", "iman", "faith"]),
            ("nawawi_1", "40 Hadith an-Nawawi", "Hadith of Jibreel", "Islam, Iman, and Ihsan explained", ["jibreel", "gabriel", "pillars", "faith"]),
            ("nawawi_2", "40 Hadith an-Nawawi", "Hadith of Intentions", "Actions are judged by intentions", ["niyyah", "intention"]),
            ("tirmidhi_1987", "Jami at-Tirmidhi", "Best among you", "The best among you are those with the best character", ["character", "akhlaq", "manners"])
        ]

        for (id, collection, title, text, keywords) in popularHadiths {
            let attributeSet = CSSearchableItemAttributeSet(contentType: .text)
            attributeSet.title = title
            attributeSet.contentDescription = "\(text) - \(collection)"
            attributeSet.keywords = keywords + ["hadith", "sunnah", "prophet", collection.lowercased()]

            items.append(CSSearchableItem(
                uniqueIdentifier: "hadith_\(id)",
                domainIdentifier: SpotlightContentType.hadith.domainIdentifier,
                attributeSet: attributeSet
            ))
        }

        do {
            try await searchableIndex.indexSearchableItems(items)
            return items.count
        } catch {
            print("SpotlightIndexService: Failed to index hadiths: \(error)")
            return 0
        }
    }

    // MARK: - Index 99 Names of Allah

    private func indexNamesOfAllah() async -> Int {
        let sampleNames: [(Int, String, String, String)] = [
            (1, "Ar-Rahman", "The Most Merciful", "الرحمن"),
            (2, "Ar-Raheem", "The Especially Merciful", "الرحيم"),
            (3, "Al-Malik", "The King", "الملك"),
            (4, "Al-Quddus", "The Holy", "القدوس"),
            (5, "As-Salam", "The Source of Peace", "السلام"),
            (99, "As-Sabur", "The Patient", "الصبور")
        ]

        var items: [CSSearchableItem] = []

        for (number, transliteration, meaning, arabic) in sampleNames {
            let attributeSet = CSSearchableItemAttributeSet(contentType: .text)
            attributeSet.title = "\(transliteration) - \(meaning)"
            attributeSet.contentDescription = "\(arabic) - Name #\(number) of Allah"
            attributeSet.keywords = [
                transliteration,
                meaning,
                arabic,
                "99 Names",
                "Names of Allah",
                "Asma ul Husna"
            ]

            items.append(CSSearchableItem(
                uniqueIdentifier: "name_\(number)",
                domainIdentifier: SpotlightContentType.namesOfAllah.domainIdentifier,
                attributeSet: attributeSet
            ))
        }

        do {
            try await searchableIndex.indexSearchableItems(items)
            return items.count
        } catch {
            print("SpotlightIndexService: Failed to index names: \(error)")
            return 0
        }
    }

    // MARK: - Persistence

    private func loadIndexState() {
        indexedItemCount = userDefaults.integer(forKey: indexCountKey)
        lastIndexDate = userDefaults.object(forKey: indexDateKey) as? Date
    }

    private func saveIndexState() {
        userDefaults.set(indexedItemCount, forKey: indexCountKey)
        userDefaults.set(lastIndexDate, forKey: indexDateKey)
    }
}

// MARK: - Spotlight Destination

enum SpotlightDestination: Hashable {
    case surah(number: Int)
    case ayah(surah: Int, ayah: Int)
    case hadith(collection: String, id: String?)
    case dua(id: String)
    case nameOfAllah(number: Int)
}

// MARK: - Feature Flag Integration

extension SpotlightIndexService {
    var isAvailable: Bool {
        FeatureFlags.shared.isEnabled(.spotlightSearch)
    }
}
