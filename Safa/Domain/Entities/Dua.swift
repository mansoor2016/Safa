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

    init(
        id: String,
        nameEnglish: String,
        nameArabic: String,
        iconName: String,
        duaCount: Int = 0
    ) {
        self.id = id
        self.nameEnglish = nameEnglish
        self.nameArabic = nameArabic
        self.iconName = iconName
        self.duaCount = duaCount
    }

    private enum CodingKeys: String, CodingKey {
        case id, nameEnglish, nameArabic, iconName, duaCount
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        nameEnglish = try container.decode(String.self, forKey: .nameEnglish)
        nameArabic = try container.decode(String.self, forKey: .nameArabic)
        iconName = try container.decode(String.self, forKey: .iconName)
        duaCount = try container.decodeIfPresent(Int.self, forKey: .duaCount) ?? 0
    }
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

    private enum CodingKeys: String, CodingKey {
        case id, categoryId, titleEnglish, titleArabic, textArabic
        case textTransliteration, textTranslation, source, occasion
        case repetitions, audioFileName, isFavorite
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        categoryId = try container.decode(String.self, forKey: .categoryId)
        titleEnglish = try container.decode(String.self, forKey: .titleEnglish)
        titleArabic = try container.decodeIfPresent(String.self, forKey: .titleArabic)
        textArabic = try container.decode(String.self, forKey: .textArabic)
        textTransliteration = try container.decode(String.self, forKey: .textTransliteration)
        textTranslation = try container.decode(String.self, forKey: .textTranslation)
        source = try container.decodeIfPresent(String.self, forKey: .source)
        occasion = try container.decodeIfPresent(String.self, forKey: .occasion)
        repetitions = try container.decodeIfPresent(Int.self, forKey: .repetitions) ?? 1
        audioFileName = try container.decodeIfPresent(String.self, forKey: .audioFileName)
        isFavorite = try container.decodeIfPresent(Bool.self, forKey: .isFavorite) ?? false
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
