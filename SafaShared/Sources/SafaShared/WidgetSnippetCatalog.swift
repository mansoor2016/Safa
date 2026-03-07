// MARK: - WidgetSnippetCatalog.swift
// PURPOSE: Single source of truth for post-prayer spiritual snippets used by both app and widget
// DEPENDENCIES: Foundation

import Foundation

/// Curated ayahs and duas for lock screen display.
/// Both the main app (WidgetDataService) and widget extension (WidgetDataStore) use this catalog.
public enum WidgetSnippetCatalog {
    public struct Snippet: Sendable {
        public let arabic: String
        public let translation: String
        public let reference: String
        public let context: String

        public init(arabic: String, translation: String, reference: String, context: String) {
            self.arabic = arabic
            self.translation = translation
            self.reference = reference
            self.context = context
        }
    }

    /// Selects a snippet for the given prayer and writes its fields to the provided UserDefaults.
    /// Uses deterministic rotation: same prayer on same day = same snippet.
    /// Shared between app-side (WidgetDataService) and widget-side (WidgetDataStore).
    public static func writeSnippet(for prayerId: String, to defaults: UserDefaults) {
        let contextTag = PrayerID.snippetContext(for: prayerId)
        let eligible = snippets.filter { $0.context == contextTag }
        let candidates = eligible.isEmpty ? snippets.filter { $0.context == "general" } : eligible
        guard !candidates.isEmpty else { return }

        let cal = Calendar.current
        let dayOfYear = cal.ordinality(of: .day, in: .year, for: Date()) ?? 1
        let index = (dayOfYear + PrayerID.index(for: prayerId)) % candidates.count
        let snippet = candidates[index]

        defaults.set(snippet.arabic, forKey: WidgetAppGroupKeys.snippetArabic)
        defaults.set(snippet.translation, forKey: WidgetAppGroupKeys.snippetTranslation)
        defaults.set(snippet.reference, forKey: WidgetAppGroupKeys.snippetReference)
        defaults.set(prayerId, forKey: WidgetAppGroupKeys.snippetPrayerId)
        defaults.set(snippet.reference.hasPrefix("Quran") ? "safa://quran" : "safa://dhikr",
                     forKey: WidgetAppGroupKeys.snippetDeepLink)
        defaults.synchronize()
    }

    public static let snippets: [Snippet] = [
        // General
        Snippet(arabic: "إِنَّ مَعَ الْعُسْرِ يُسْرًا", translation: "Indeed, with hardship comes ease.", reference: "Quran 94:6", context: "general"),
        Snippet(arabic: "وَمَن يَتَوَكَّلْ عَلَى اللَّهِ فَهُوَ حَسْبُهُ", translation: "Whoever relies on Allah, He is sufficient.", reference: "Quran 65:3", context: "general"),
        Snippet(arabic: "فَاذْكُرُونِي أَذْكُرْكُمْ", translation: "Remember Me, and I will remember you.", reference: "Quran 2:152", context: "general"),
        Snippet(arabic: "وَاللَّهُ يُحِبُّ الصَّابِرِينَ", translation: "Allah loves the patient.", reference: "Quran 3:146", context: "general"),
        Snippet(arabic: "رَبَّنَا آتِنَا فِي الدُّنْيَا حَسَنَةً", translation: "Our Lord, give us good in this world.", reference: "Quran 2:201", context: "general"),
        Snippet(arabic: "وَهُوَ مَعَكُمْ أَيْنَ مَا كُنتُمْ", translation: "He is with you wherever you are.", reference: "Quran 57:4", context: "general"),
        Snippet(arabic: "أَلَا بِذِكْرِ اللَّهِ تَطْمَئِنُّ الْقُلُوبُ", translation: "In the remembrance of Allah, hearts find rest.", reference: "Quran 13:28", context: "general"),
        Snippet(arabic: "إِنَّ اللَّهَ لَا يُضِيعُ أَجْرَ الْمُحْسِنِينَ", translation: "Allah does not waste the reward of the good.", reference: "Quran 9:120", context: "general"),
        Snippet(arabic: "وَاسْتَعِينُوا بِالصَّبْرِ وَالصَّلَاةِ", translation: "Seek help through patience and prayer.", reference: "Quran 2:45", context: "general"),
        Snippet(arabic: "وَرَحْمَتِي وَسِعَتْ كُلَّ شَيْءٍ", translation: "My mercy encompasses all things.", reference: "Quran 7:156", context: "general"),
        Snippet(arabic: "إِنَّ اللَّهَ مَعَ الصَّابِرِينَ", translation: "Indeed, Allah is with the patient.", reference: "Quran 2:153", context: "general"),
        Snippet(arabic: "فَإِنَّ مَعَ الْعُسْرِ يُسْرًا", translation: "For indeed, with hardship comes ease.", reference: "Quran 94:5", context: "general"),
        Snippet(arabic: "وَاللَّهُ خَيْرُ الرَّازِقِينَ", translation: "Allah is the best of providers.", reference: "Quran 62:11", context: "general"),
        Snippet(arabic: "وَتَوَكَّلْ عَلَى الْحَيِّ الَّذِي لَا يَمُوتُ", translation: "Put your trust in the Ever-Living who never dies.", reference: "Quran 25:58", context: "general"),
        Snippet(arabic: "سُبْحَانَ الَّذِي سَخَّرَ لَنَا هَٰذَا", translation: "Glory to Him who has subjected this to us.", reference: "Quran 43:13", context: "general"),
        Snippet(arabic: "وَمَن يَتَّقِ اللَّهَ يَجْعَل لَّهُ مَخْرَجًا", translation: "Whoever fears Allah, He makes a way out.", reference: "Quran 65:2", context: "general"),
        Snippet(arabic: "وَنَحْنُ أَقْرَبُ إِلَيْهِ مِنْ حَبْلِ الْوَرِيدِ", translation: "We are closer to him than his jugular vein.", reference: "Quran 50:16", context: "general"),
        Snippet(arabic: "ادْعُونِي أَسْتَجِبْ لَكُمْ", translation: "Call upon Me, I will respond to you.", reference: "Quran 40:60", context: "general"),
        Snippet(arabic: "وَإِذَا سَأَلَكَ عِبَادِي عَنِّي فَإِنِّي قَرِيبٌ", translation: "When My servants ask about Me, I am near.", reference: "Quran 2:186", context: "general"),
        // Morning
        Snippet(arabic: "رَبِّ اشْرَحْ لِي صَدْرِي", translation: "My Lord, expand my chest for me.", reference: "Quran 20:25", context: "morning"),
        Snippet(arabic: "وَقُل رَّبِّ زِدْنِي عِلْمًا", translation: "My Lord, increase me in knowledge.", reference: "Quran 20:114", context: "morning"),
        Snippet(arabic: "وَلَسَوْفَ يُعْطِيكَ رَبُّكَ فَتَرْضَىٰ", translation: "Your Lord will give you, and you will be pleased.", reference: "Quran 93:5", context: "morning"),
        Snippet(arabic: "رَبِّ أَوْزِعْنِي أَنْ أَشْكُرَ نِعْمَتَكَ", translation: "My Lord, inspire me to be grateful for Your favor.", reference: "Quran 27:19", context: "morning"),
        Snippet(arabic: "وَالْفَجْرِ وَلَيَالٍ عَشْرٍ", translation: "By the dawn and the ten nights.", reference: "Quran 89:1-2", context: "morning"),
        Snippet(arabic: "وَالشَّمْسِ وَضُحَاهَا", translation: "By the sun and its morning brightness.", reference: "Quran 91:1", context: "morning"),
        // Evening
        Snippet(arabic: "وَكَفَىٰ بِاللَّهِ وَكِيلًا", translation: "Sufficient is Allah as a Disposer of affairs.", reference: "Quran 4:81", context: "evening"),
        Snippet(arabic: "حَسْبُنَا اللَّهُ وَنِعْمَ الْوَكِيلُ", translation: "Sufficient for us is Allah, the best Disposer.", reference: "Quran 3:173", context: "evening"),
        // Night
        Snippet(arabic: "قُلْ هُوَ اللَّهُ أَحَدٌ", translation: "Say: He is Allah, the One.", reference: "Quran 112:1", context: "night"),
        Snippet(arabic: "وَاللَّيْلِ إِذَا سَجَىٰ", translation: "By the night when it covers with darkness.", reference: "Quran 93:2", context: "night"),
        Snippet(arabic: "سَلَامٌ هِيَ حَتَّىٰ مَطْلَعِ الْفَجْرِ", translation: "Peace it is until the emergence of dawn.", reference: "Quran 97:5", context: "night"),
    ]
}
