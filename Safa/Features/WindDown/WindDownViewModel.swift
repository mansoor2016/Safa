// MARK: - WindDownViewModel.swift
// PURPOSE: View model and model for wind down feature
// DEPENDENCIES: Foundation

import Foundation

// MARK: - Sleep Adhkar Model

struct SleepAdhkar: Identifiable {
    let id: String
    let title: String
    let arabic: String
    let transliteration: String
    let translation: String
    let benefit: String
    let count: Int
}

// MARK: - Wind Down View Model

@Observable
final class WindDownViewModel {

    // MARK: - State

    var completedAdhkar: Set<String> = []
    var isPlayingRecitation: Bool = false
    var selectedReciter: String = "Mishary Rashid Alafasy"
    var fajrAlarmEnabled: Bool = false
    var fajrAlarmTime: Date = Date()
    var selectedSurah: String = "Surah Al-Mulk"
    var playbackProgress: Double = 0.0

    // MARK: - Static Data

    let sleepAdhkar: [SleepAdhkar] = SleepAdhkarData.allAdhkar

    let calmingSurahs: [String] = [
        "Surah Al-Mulk",
        "Surah As-Sajdah",
        "Surah Yasin",
        "Surah Ar-Rahman",
        "Surah Al-Waqiah"
    ]

    let reciters: [String] = [
        "Mishary Rashid Alafasy",
        "Abdul Rahman Al-Sudais",
        "Saad Al-Ghamdi",
        "Abu Bakr Al-Shatri",
        "Maher Al-Muaiqly"
    ]

    // MARK: - Computed Properties

    var completionPercentage: Double {
        guard !sleepAdhkar.isEmpty else { return 0 }
        return Double(completedAdhkar.count) / Double(sleepAdhkar.count) * 100
    }

    var allAdhkarCompleted: Bool {
        completedAdhkar.count == sleepAdhkar.count
    }

    // MARK: - Methods

    func toggleAdhkar(_ id: String) {
        if completedAdhkar.contains(id) {
            completedAdhkar.remove(id)
        } else {
            completedAdhkar.insert(id)
        }
    }

    func toggleRecitation() {
        isPlayingRecitation.toggle()
    }

    func resetProgress() {
        completedAdhkar.removeAll()
        isPlayingRecitation = false
        playbackProgress = 0.0
    }
}

// MARK: - Sleep Adhkar Data

enum SleepAdhkarData {
    static let allAdhkar: [SleepAdhkar] = [
        SleepAdhkar(
            id: "ayat-kursi",
            title: "Ayatul Kursi",
            arabic: "اللَّهُ لَا إِلَٰهَ إِلَّا هُوَ الْحَيُّ الْقَيُّومُ...",
            transliteration: "Allahu la ilaha illa Huwal-Hayyul-Qayyum...",
            translation: "Allah - there is no deity except Him, the Ever-Living, the Sustainer of existence...",
            benefit: "Protection throughout the night",
            count: 1
        ),
        SleepAdhkar(
            id: "surah-ikhlas",
            title: "Surah Al-Ikhlas",
            arabic: "قُلْ هُوَ اللَّهُ أَحَدٌ ۝ اللَّهُ الصَّمَدُ...",
            transliteration: "Qul Huwa Allahu Ahad, Allahus-Samad...",
            translation: "Say, He is Allah, [who is] One, Allah, the Eternal Refuge...",
            benefit: "Equal to one-third of the Quran",
            count: 3
        ),
        SleepAdhkar(
            id: "surah-falaq",
            title: "Surah Al-Falaq",
            arabic: "قُلْ أَعُوذُ بِرَبِّ الْفَلَقِ...",
            transliteration: "Qul A'udhu bi Rabbil-Falaq...",
            translation: "Say, I seek refuge in the Lord of daybreak...",
            benefit: "Protection from evil",
            count: 3
        ),
        SleepAdhkar(
            id: "surah-nas",
            title: "Surah An-Nas",
            arabic: "قُلْ أَعُوذُ بِرَبِّ النَّاسِ...",
            transliteration: "Qul A'udhu bi Rabbin-Nas...",
            translation: "Say, I seek refuge in the Lord of mankind...",
            benefit: "Protection from whispers of Satan",
            count: 3
        ),
        SleepAdhkar(
            id: "sleep-dua",
            title: "Dua Before Sleep",
            arabic: "بِاسْمِكَ اللَّهُمَّ أَمُوتُ وَأَحْيَا",
            transliteration: "Bismika Allahumma amutu wa ahya",
            translation: "In Your name, O Allah, I die and I live",
            benefit: "Sunnah of the Prophet ﷺ",
            count: 1
        ),
        SleepAdhkar(
            id: "hands-blow",
            title: "Blowing into Hands",
            arabic: "اللَّهُمَّ قِنِي عَذَابَكَ يَوْمَ تَبْعَثُ عِبَادَكَ",
            transliteration: "Allahumma qini 'adhabaka yawma tab'athu 'ibadak",
            translation: "O Allah, protect me from Your punishment on the Day You resurrect Your servants",
            benefit: "Recite and wipe over body",
            count: 1
        ),
        SleepAdhkar(
            id: "tasbih-33",
            title: "SubhanAllah",
            arabic: "سُبْحَانَ اللَّهِ",
            transliteration: "SubhanAllah",
            translation: "Glory be to Allah",
            benefit: "33 times before sleep",
            count: 33
        ),
        SleepAdhkar(
            id: "hamd-33",
            title: "Alhamdulillah",
            arabic: "الْحَمْدُ لِلَّهِ",
            transliteration: "Alhamdulillah",
            translation: "Praise be to Allah",
            benefit: "33 times before sleep",
            count: 33
        ),
        SleepAdhkar(
            id: "takbir-34",
            title: "Allahu Akbar",
            arabic: "اللَّهُ أَكْبَرُ",
            transliteration: "Allahu Akbar",
            translation: "Allah is the Greatest",
            benefit: "34 times before sleep",
            count: 34
        )
    ]
}
