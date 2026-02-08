// MARK: - Dua.swift
// PURPOSE: Domain entities for Duas, Dhikr, and categories

import Foundation

// MARK: - Dua Category
struct DuaCategory: Identifiable, Codable, Hashable {
    let id: String
    let nameEnglish: String
    let nameArabic: String
    let iconName: String
    let duaCount: Int

    static let dailyLife = DuaCategory(
        id: "daily",
        nameEnglish: "Daily Life",
        nameArabic: "الحياة اليومية",
        iconName: "sun.max",
        duaCount: 0
    )

    static let salah = DuaCategory(
        id: "salah",
        nameEnglish: "Prayer (Salah)",
        nameArabic: "الصلاة",
        iconName: "figure.stand",
        duaCount: 0
    )

    static let protection = DuaCategory(
        id: "protection",
        nameEnglish: "Protection",
        nameArabic: "الحماية",
        iconName: "shield",
        duaCount: 0
    )

    static let forgiveness = DuaCategory(
        id: "forgiveness",
        nameEnglish: "Forgiveness",
        nameArabic: "الاستغفار",
        iconName: "heart",
        duaCount: 0
    )

    static let hardship = DuaCategory(
        id: "hardship",
        nameEnglish: "Hardship & Anxiety",
        nameArabic: "الشدة والقلق",
        iconName: "cloud.rain",
        duaCount: 0
    )
}

// MARK: - Dua
struct Dua: Identifiable, Codable, Hashable {
    let id: String
    let categoryId: String
    let titleEnglish: String
    let titleArabic: String?
    let textArabic: String
    let textTransliteration: String
    let textTranslation: String
    let source: String? // e.g., "Sahih Bukhari 6306"
    let occasion: String? // When to recite
    let repetitions: Int // How many times to repeat
    let audioFileName: String?
    var isFavorite: Bool

    init(
        id: String,
        categoryId: String,
        titleEnglish: String,
        titleArabic: String? = nil,
        textArabic: String,
        textTransliteration: String,
        textTranslation: String,
        source: String? = nil,
        occasion: String? = nil,
        repetitions: Int = 1,
        audioFileName: String? = nil,
        isFavorite: Bool = false
    ) {
        self.id = id
        self.categoryId = categoryId
        self.titleEnglish = titleEnglish
        self.titleArabic = titleArabic
        self.textArabic = textArabic
        self.textTransliteration = textTransliteration
        self.textTranslation = textTranslation
        self.source = source
        self.occasion = occasion
        self.repetitions = repetitions
        self.audioFileName = audioFileName
        self.isFavorite = isFavorite
    }
}

// MARK: - Tasbeeh Counter
struct TasbeehSession: Identifiable, Codable, Hashable {
    let id: UUID
    let dhikrText: String
    let targetCount: Int
    var currentCount: Int
    let startedAt: Date
    var completedAt: Date?

    init(
        id: UUID = UUID(),
        dhikrText: String,
        targetCount: Int = 33,
        currentCount: Int = 0,
        startedAt: Date = Date(),
        completedAt: Date? = nil
    ) {
        self.id = id
        self.dhikrText = dhikrText
        self.targetCount = targetCount
        self.currentCount = currentCount
        self.startedAt = startedAt
        self.completedAt = completedAt
    }

    var isComplete: Bool {
        currentCount >= targetCount
    }

    var progress: Double {
        Double(currentCount) / Double(targetCount)
    }
}

// MARK: - Dhikr Type
enum DhikrType: String, Codable, CaseIterable {
    case morning
    case evening
    case sleep

    var displayName: String {
        switch self {
        case .morning: return "Morning Dhikr"
        case .evening: return "Evening Dhikr"
        case .sleep: return "Sleep Dhikr"
        }
    }
}

// MARK: - Simple Dua Category Enum (for views)
enum DuaCategoryEnum: String, Codable, CaseIterable {
    case morning
    case evening
    case prayer
    case sleep
    case food
    case travel
    case general

    var displayName: String {
        switch self {
        case .morning: return "Morning"
        case .evening: return "Evening"
        case .prayer: return "Prayer"
        case .sleep: return "Sleep"
        case .food: return "Food"
        case .travel: return "Travel"
        case .general: return "General"
        }
    }
}

// MARK: - Simple Dua Model (for views)
struct SimpleDua: Identifiable, Codable, Hashable {
    let id: String
    let category: DuaCategoryEnum
    let arabic: String
    let transliteration: String
    let translation: String
    let reference: String
    let repeatCount: Int
    let benefit: String?
}

// Type alias for backward compatibility
typealias DuaCategoryType = DuaCategoryEnum

// MARK: - Common Dhikr
enum CommonDhikr: String, CaseIterable {
    case subhanAllah = "SubhanAllah"
    case alhamdulillah = "Alhamdulillah"
    case allahuAkbar = "Allahu Akbar"
    case laIlahaIllallah = "La ilaha illallah"
    case astaghfirullah = "Astaghfirullah"

    var arabic: String {
        switch self {
        case .subhanAllah: return "سُبْحَانَ اللهِ"
        case .alhamdulillah: return "الْحَمْدُ للهِ"
        case .allahuAkbar: return "اللهُ أَكْبَرُ"
        case .laIlahaIllallah: return "لَا إِلَٰهَ إِلَّا اللهُ"
        case .astaghfirullah: return "أَسْتَغْفِرُ اللهَ"
        }
    }

    var translation: String {
        switch self {
        case .subhanAllah: return "Glory be to Allah"
        case .alhamdulillah: return "All praise is due to Allah"
        case .allahuAkbar: return "Allah is the Greatest"
        case .laIlahaIllallah: return "There is no god but Allah"
        case .astaghfirullah: return "I seek forgiveness from Allah"
        }
    }

    var defaultCount: Int {
        switch self {
        case .subhanAllah, .alhamdulillah, .allahuAkbar: return 33
        case .laIlahaIllallah: return 100
        case .astaghfirullah: return 100
        }
    }
}
