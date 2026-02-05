// MARK: - DuaRepository.swift
// PURPOSE: Implementation of Dua and Adhkar data access
// DEPENDENCIES: CoreData, DuaRepositoryProtocol

import Foundation
import CoreData

final class DuaRepository: DuaRepositoryProtocol {
    // MARK: - Dependencies
    private let coreData: CoreDataStack

    // MARK: - Storage Keys
    private let favoritesKey = "com.safa.dua.favorites"
    private let adhkarCompletionKey = "com.safa.adhkar.completion"
    private let adhkarDateKey = "com.safa.adhkar.date"

    // MARK: - Init
    init(coreData: CoreDataStack) {
        self.coreData = coreData
    }

    // MARK: - Categories

    func getCategories() async throws -> [DuaCategory] {
        // TODO: Load from bundled JSON
        return DuaCategory.allCategories
    }

    func getDuas(forCategory categoryId: String) async throws -> [Dua] {
        // TODO: Load from bundled JSON
        return Dua.allDuas.filter { $0.categoryId == categoryId }
    }

    func getDua(id: String) async throws -> Dua? {
        return Dua.allDuas.first { $0.id == id }
    }

    // MARK: - Adhkar

    func getMorningAdhkar() async throws -> [Dua] {
        // TODO: Load from bundled JSON
        return Dua.morningAdhkar
    }

    func getEveningAdhkar() async throws -> [Dua] {
        // TODO: Load from bundled JSON
        return Dua.eveningAdhkar
    }

    func getSleepAdhkar() async throws -> [Dua] {
        // TODO: Load from bundled JSON
        return Dua.sleepAdhkar
    }

    // MARK: - Favorites

    func getFavorites() async throws -> [Dua] {
        let favoriteIds = getFavoriteIds()
        return Dua.allDuas.filter { favoriteIds.contains($0.id) }
            .map { dua in
                var favorite = dua
                favorite.isFavorite = true
                return favorite
            }
    }

    func addToFavorites(_ dua: Dua) async throws {
        var ids = getFavoriteIds()
        guard !ids.contains(dua.id) else { return }
        ids.append(dua.id)
        saveFavoriteIds(ids)
    }

    func removeFromFavorites(_ dua: Dua) async throws {
        var ids = getFavoriteIds()
        ids.removeAll { $0 == dua.id }
        saveFavoriteIds(ids)
    }

    // MARK: - Search

    func searchDuas(query: String) async throws -> [Dua] {
        return Dua.allDuas.filter { dua in
            dua.titleEnglish.localizedCaseInsensitiveContains(query) ||
            dua.textTranslation.localizedCaseInsensitiveContains(query) ||
            dua.textArabic.contains(query)
        }
    }

    // MARK: - Adhkar Completion

    func markAdhkarCompleted(_ dua: Dua, type: AdhkarType) async throws {
        checkAndResetIfNewDay()

        var completion = getAdhkarCompletion()
        var typeCompletion = completion[type.rawValue] ?? []

        guard !typeCompletion.contains(dua.id) else { return }
        typeCompletion.append(dua.id)
        completion[type.rawValue] = typeCompletion

        saveAdhkarCompletion(completion)
    }

    func getAdhkarCompletionStatus(for type: AdhkarType) async throws -> [String] {
        checkAndResetIfNewDay()
        let completion = getAdhkarCompletion()
        return completion[type.rawValue] ?? []
    }

    func resetAdhkarCompletion() async throws {
        UserDefaults.standard.removeObject(forKey: adhkarCompletionKey)
        UserDefaults.standard.set(Date(), forKey: adhkarDateKey)
    }

    // MARK: - Private Helpers

    private func getFavoriteIds() -> [String] {
        UserDefaults.standard.stringArray(forKey: favoritesKey) ?? []
    }

    private func saveFavoriteIds(_ ids: [String]) {
        UserDefaults.standard.set(ids, forKey: favoritesKey)
    }

    private func getAdhkarCompletion() -> [String: [String]] {
        guard let data = UserDefaults.standard.data(forKey: adhkarCompletionKey),
              let completion = try? JSONDecoder().decode([String: [String]].self, from: data) else {
            return [:]
        }
        return completion
    }

    private func saveAdhkarCompletion(_ completion: [String: [String]]) {
        guard let data = try? JSONEncoder().encode(completion) else { return }
        UserDefaults.standard.set(data, forKey: adhkarCompletionKey)
    }

    private func checkAndResetIfNewDay() {
        guard let lastDate = UserDefaults.standard.object(forKey: adhkarDateKey) as? Date else {
            UserDefaults.standard.set(Date(), forKey: adhkarDateKey)
            return
        }

        if !Calendar.current.isDateInToday(lastDate) {
            UserDefaults.standard.removeObject(forKey: adhkarCompletionKey)
            UserDefaults.standard.set(Date(), forKey: adhkarDateKey)
        }
    }
}

// MARK: - Static Data Extensions

extension DuaCategory {
    static let allCategories: [DuaCategory] = [
        .dailyLife,
        .salah,
        .protection,
        .forgiveness,
        .hardship,
        DuaCategory(id: "travel", nameEnglish: "Travel", nameArabic: "السفر", iconName: "airplane", duaCount: 0),
        DuaCategory(id: "food", nameEnglish: "Food & Drink", nameArabic: "الطعام والشراب", iconName: "fork.knife", duaCount: 0),
        DuaCategory(id: "sleep", nameEnglish: "Sleep", nameArabic: "النوم", iconName: "moon.zzz", duaCount: 0),
    ]
}

extension Dua {
    static let allDuas: [Dua] = morningAdhkar + eveningAdhkar + sleepAdhkar + dailyDuas

    static let morningAdhkar: [Dua] = [
        Dua(
            id: "morning_1",
            categoryId: "morning",
            titleEnglish: "Waking Up Dua",
            titleArabic: "دعاء الاستيقاظ",
            textArabic: "الْحَمْدُ لِلَّهِ الَّذِي أَحْيَانَا بَعْدَ مَا أَمَاتَنَا وَإِلَيْهِ النُّشُورُ",
            textTransliteration: "Alhamdu lillahil-lathee ahyana ba'da ma amatana wa ilayhin-nushoor",
            textTranslation: "All praise is for Allah who gave us life after having taken it from us and unto Him is the resurrection.",
            source: "Sahih al-Bukhari 6324",
            occasion: "Upon waking up",
            repetitions: 1
        ),
        Dua(
            id: "morning_2",
            categoryId: "morning",
            titleEnglish: "Morning Remembrance",
            titleArabic: "أذكار الصباح",
            textArabic: "أَصْبَحْنَا وَأَصْبَحَ الْمُلْكُ لِلَّهِ، وَالْحَمْدُ لِلَّهِ",
            textTransliteration: "Asbahna wa asbahal-mulku lillah, walhamdu lillah",
            textTranslation: "We have reached the morning and at this very time the whole kingdom belongs to Allah. All praise is for Allah.",
            source: "Muslim 2723",
            occasion: "In the morning",
            repetitions: 1
        ),
        Dua(
            id: "morning_3",
            categoryId: "morning",
            titleEnglish: "Seeking Protection - Morning",
            titleArabic: "طلب الحماية - صباحاً",
            textArabic: "اللَّهُمَّ بِكَ أَصْبَحْنَا، وَبِكَ أَمْسَيْنَا، وَبِكَ نَحْيَا، وَبِكَ نَمُوتُ، وَإِلَيْكَ النُّشُورُ",
            textTransliteration: "Allahumma bika asbahna, wa bika amsayna, wa bika nahya, wa bika namootu, wa ilaykan-nushoor",
            textTranslation: "O Allah, by Your leave we have reached the morning and by Your leave we have reached the evening, by Your leave we live and die and unto You is our resurrection.",
            source: "Tirmidhi 3391",
            occasion: "In the morning",
            repetitions: 1
        ),
    ]

    static let eveningAdhkar: [Dua] = [
        Dua(
            id: "evening_1",
            categoryId: "evening",
            titleEnglish: "Evening Remembrance",
            titleArabic: "أذكار المساء",
            textArabic: "أَمْسَيْنَا وَأَمْسَى الْمُلْكُ لِلَّهِ، وَالْحَمْدُ لِلَّهِ",
            textTransliteration: "Amsayna wa amsal-mulku lillah, walhamdu lillah",
            textTranslation: "We have reached the evening and at this very time the whole kingdom belongs to Allah. All praise is for Allah.",
            source: "Muslim 2723",
            occasion: "In the evening",
            repetitions: 1
        ),
        Dua(
            id: "evening_2",
            categoryId: "evening",
            titleEnglish: "Seeking Protection - Evening",
            titleArabic: "طلب الحماية - مساءً",
            textArabic: "اللَّهُمَّ بِكَ أَمْسَيْنَا، وَبِكَ أَصْبَحْنَا، وَبِكَ نَحْيَا، وَبِكَ نَمُوتُ، وَإِلَيْكَ الْمَصِيرُ",
            textTransliteration: "Allahumma bika amsayna, wa bika asbahna, wa bika nahya, wa bika namootu, wa ilaykal-maseer",
            textTranslation: "O Allah, by Your leave we have reached the evening and by Your leave we have reached the morning, by Your leave we live and die and unto You is our return.",
            source: "Tirmidhi 3391",
            occasion: "In the evening",
            repetitions: 1
        ),
    ]

    static let sleepAdhkar: [Dua] = [
        Dua(
            id: "sleep_1",
            categoryId: "sleep",
            titleEnglish: "Before Sleeping",
            titleArabic: "قبل النوم",
            textArabic: "بِاسْمِكَ اللَّهُمَّ أَمُوتُ وَأَحْيَا",
            textTransliteration: "Bismika Allahumma amootu wa ahya",
            textTranslation: "In Your name O Allah, I die and I live.",
            source: "Sahih al-Bukhari 6324",
            occasion: "Before sleeping",
            repetitions: 1
        ),
        Dua(
            id: "sleep_2",
            categoryId: "sleep",
            titleEnglish: "Ayat al-Kursi",
            titleArabic: "آية الكرسي",
            textArabic: "اللَّهُ لَا إِلَٰهَ إِلَّا هُوَ الْحَيُّ الْقَيُّومُ ۚ لَا تَأْخُذُهُ سِنَةٌ وَلَا نَوْمٌ",
            textTransliteration: "Allahu la ilaha illa huwal-Hayyul-Qayyum, la ta'khuthuhu sinatun wa la nawm",
            textTranslation: "Allah - there is no deity except Him, the Ever-Living, the Sustainer of existence. Neither drowsiness overtakes Him nor sleep.",
            source: "Quran 2:255",
            occasion: "Before sleeping",
            repetitions: 1
        ),
    ]

    static let dailyDuas: [Dua] = [
        Dua(
            id: "daily_eating",
            categoryId: "daily",
            titleEnglish: "Before Eating",
            titleArabic: "قبل الأكل",
            textArabic: "بِسْمِ اللَّهِ",
            textTransliteration: "Bismillah",
            textTranslation: "In the name of Allah.",
            source: "Sahih al-Bukhari",
            occasion: "Before eating",
            repetitions: 1
        ),
        Dua(
            id: "daily_after_eating",
            categoryId: "daily",
            titleEnglish: "After Eating",
            titleArabic: "بعد الأكل",
            textArabic: "الْحَمْدُ لِلَّهِ الَّذِي أَطْعَمَنِي هَٰذَا وَرَزَقَنِيهِ مِنْ غَيْرِ حَوْلٍ مِنِّي وَلَا قُوَّةٍ",
            textTransliteration: "Alhamdu lillahil-lathee at'amani hatha wa razaqanihi min ghayri hawlin minni wa la quwwah",
            textTranslation: "All praise is for Allah who has given me this food and provided it without any effort or power on my part.",
            source: "Tirmidhi 3458",
            occasion: "After eating",
            repetitions: 1
        ),
    ]
}
