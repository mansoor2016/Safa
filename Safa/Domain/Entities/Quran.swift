// MARK: - Quran.swift
// PURPOSE: Domain entities for Quran surahs, ayahs, bookmarks, and progress

import Foundation

// MARK: - Surah
struct Surah: Identifiable, Codable, Hashable {
    let id: Int // 1-114
    let nameArabic: String
    let nameEnglish: String
    let nameTransliteration: String
    let revelationType: RevelationType
    let ayahCount: Int
    let juzStart: Int

    var number: Int { id }

    enum RevelationType: String, Codable {
        case meccan = "Meccan"
        case medinan = "Medinan"
    }
}

// MARK: - Ayah
struct Ayah: Identifiable, Codable, Hashable {
    let id: String // "surah:ayah" e.g., "2:255"
    let surahNumber: Int
    let ayahNumber: Int
    let textArabic: String
    let textTranslation: String
    let textTransliteration: String?
    let juzNumber: Int
    let pageNumber: Int

    init(
        surahNumber: Int,
        ayahNumber: Int,
        textArabic: String,
        textTranslation: String,
        textTransliteration: String? = nil,
        juzNumber: Int,
        pageNumber: Int
    ) {
        self.id = "\(surahNumber):\(ayahNumber)"
        self.surahNumber = surahNumber
        self.ayahNumber = ayahNumber
        self.textArabic = textArabic
        self.textTranslation = textTranslation
        self.textTransliteration = textTransliteration
        self.juzNumber = juzNumber
        self.pageNumber = pageNumber
    }

    var reference: String {
        "\(surahNumber):\(ayahNumber)"
    }
}

// MARK: - Juz
struct Juz: Identifiable, Codable, Hashable {
    let id: Int // 1-30
    let startSurah: Int
    let startAyah: Int
    let endSurah: Int
    let endAyah: Int

    var number: Int { id }
}

// MARK: - Quran Bookmark
struct QuranBookmark: Identifiable, Codable, Hashable {
    let id: UUID
    let surahNumber: Int
    let ayahNumber: Int
    let createdAt: Date
    let note: String?

    init(
        id: UUID = UUID(),
        surahNumber: Int,
        ayahNumber: Int,
        createdAt: Date = Date(),
        note: String? = nil
    ) {
        self.id = id
        self.surahNumber = surahNumber
        self.ayahNumber = ayahNumber
        self.createdAt = createdAt
        self.note = note
    }

    var reference: String {
        "\(surahNumber):\(ayahNumber)"
    }
}

// MARK: - Quran Progress
struct QuranProgress: Codable, Hashable {
    var lastSurah: Int
    var lastAyah: Int
    var lastReadAt: Date
    var totalAyahsRead: Int
    var khatmCount: Int // Number of complete readings

    init(
        lastSurah: Int = 1,
        lastAyah: Int = 1,
        lastReadAt: Date = Date(),
        totalAyahsRead: Int = 0,
        khatmCount: Int = 0
    ) {
        self.lastSurah = lastSurah
        self.lastAyah = lastAyah
        self.lastReadAt = lastReadAt
        self.totalAyahsRead = totalAyahsRead
        self.khatmCount = khatmCount
    }

    var progressPercentage: Double {
        // Total ayahs in Quran: 6236
        return Double(totalAyahsRead) / 6236.0 * 100.0
    }
}

// MARK: - Quran Font Preferences
struct QuranFontPreferences: Codable, Equatable {
    var arabicFontSize: ArabicFontSize
    var translationFontSize: TranslationFontSize
    var transliterationFontSize: TransliterationFontSize

    init(
        arabicFontSize: ArabicFontSize = .medium,
        translationFontSize: TranslationFontSize = .medium,
        transliterationFontSize: TransliterationFontSize = .medium
    ) {
        self.arabicFontSize = arabicFontSize
        self.translationFontSize = translationFontSize
        self.transliterationFontSize = transliterationFontSize
    }

    enum ArabicFontSize: String, Codable, CaseIterable {
        case small, medium, large, extraLarge

        var label: String {
            switch self {
            case .small: return "Small"
            case .medium: return "Medium"
            case .large: return "Large"
            case .extraLarge: return "Extra Large"
            }
        }

        var pointSize: CGFloat {
            switch self {
            case .small: return 22
            case .medium: return 28
            case .large: return 34
            case .extraLarge: return 42
            }
        }
    }

    enum TranslationFontSize: String, Codable, CaseIterable {
        case small, medium, large

        var label: String {
            switch self {
            case .small: return "Small"
            case .medium: return "Medium"
            case .large: return "Large"
            }
        }

        var pointSize: CGFloat {
            switch self {
            case .small: return 14
            case .medium: return 16
            case .large: return 20
            }
        }
    }

    enum TransliterationFontSize: String, Codable, CaseIterable {
        case small, medium, large

        var label: String {
            switch self {
            case .small: return "Small"
            case .medium: return "Medium"
            case .large: return "Large"
            }
        }

        var pointSize: CGFloat {
            switch self {
            case .small: return 14
            case .medium: return 16
            case .large: return 20
            }
        }
    }

    private static let storageKey = "quranFontPreferences"

    static func load() -> QuranFontPreferences {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let prefs = try? JSONDecoder().decode(QuranFontPreferences.self, from: data) else {
            return QuranFontPreferences()
        }
        return prefs
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        arabicFontSize = try container.decode(ArabicFontSize.self, forKey: .arabicFontSize)
        translationFontSize = try container.decode(TranslationFontSize.self, forKey: .translationFontSize)
        transliterationFontSize = try container.decodeIfPresent(TransliterationFontSize.self, forKey: .transliterationFontSize) ?? .medium
    }

    private enum CodingKeys: String, CodingKey {
        case arabicFontSize, translationFontSize, transliterationFontSize
    }

    func save() {
        if let data = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(data, forKey: Self.storageKey)
        }
    }
}

// MARK: - Surah Read Progress
struct SurahReadProgress: Codable, Equatable {
    let surahNumber: Int
    var readAyahs: Set<Int>
    let totalAyahs: Int

    init(surahNumber: Int, readAyahs: Set<Int> = [], totalAyahs: Int) {
        self.surahNumber = surahNumber
        self.readAyahs = readAyahs
        self.totalAyahs = totalAyahs
    }

    var fractionComplete: Double {
        guard totalAyahs > 0 else { return 0 }
        return Double(readAyahs.count) / Double(totalAyahs)
    }

    var isComplete: Bool {
        readAyahs.count >= totalAyahs
    }
}

// MARK: - Progress Ring Mode
enum ProgressRingMode: String, CaseIterable {
    case highWaterMark
    case currentPosition

    var label: String {
        switch self {
        case .highWaterMark: return "Furthest Read"
        case .currentPosition: return "Current Position"
        }
    }

    private static let storageKey = "progressRingMode"

    static func load() -> ProgressRingMode {
        guard let raw = UserDefaults.standard.string(forKey: storageKey),
              let mode = ProgressRingMode(rawValue: raw) else {
            return .highWaterMark
        }
        return mode
    }

    func save() {
        UserDefaults.standard.set(rawValue, forKey: Self.storageKey)
    }
}

// MARK: - Quran Navigation Target
struct QuranNavigationTarget: Hashable {
    let surahNumber: Int
    let startAyah: Int

    init(surahNumber: Int, startAyah: Int = 1) {
        self.surahNumber = surahNumber
        self.startAyah = startAyah
    }
}

// MARK: - Reciter
struct Reciter: Identifiable, Codable, Hashable {
    let id: String
    let nameEnglish: String
    let nameArabic: String
    let style: String? // e.g., "Murattal", "Mujawwad"
    let audioBaseURL: URL?
}
