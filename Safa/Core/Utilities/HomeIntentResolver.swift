// MARK: - HomeIntentResolver.swift
// PURPOSE: Resolves 4 prioritized quick actions for the Home screen based on context
// DEPENDENCIES: Foundation, Gamification (Streak, StreakType), Prayer (PrayerTime, PrayerType)

import Foundation

// MARK: - HomeAction

struct HomeAction: Identifiable, Equatable {
    let id: String
    let icon: String
    let title: String
    let subtitle: String
    let colorName: HomeActionColor
    let destination: HomeActionDestination

    enum HomeActionColor: String, Equatable {
        case green, blue, purple, orange, red, teal, indigo
    }

    enum HomeActionDestination: Equatable {
        case tab(String)
        case route(String)
        case disabled(String)
    }

    /// Equality based on id only — allows subtitle variants to deduplicate.
    static func == (lhs: HomeAction, rhs: HomeAction) -> Bool {
        lhs.id == rhs.id
    }

    func with(subtitle newSubtitle: String) -> HomeAction {
        HomeAction(
            id: id, icon: icon, title: title,
            subtitle: newSubtitle,
            colorName: colorName, destination: destination
        )
    }
}

// MARK: - HomeIntentResolver

struct HomeIntentResolver {

    // MARK: - Catalog (default subtitles)

    static let prayer = HomeAction(
        id: "prayer", icon: "clock.fill", title: "Prayer",
        subtitle: "Times & logging", colorName: .green, destination: .tab("prayer")
    )
    static let quran = HomeAction(
        id: "quran", icon: "book.fill", title: "Quran",
        subtitle: "Read & listen", colorName: .teal, destination: .tab("quran")
    )
    static let duas = HomeAction(
        id: "duas", icon: "heart.text.square.fill", title: "Duas",
        subtitle: "Daily supplications", colorName: .blue, destination: .tab("duas")
    )
    static let dhikr = HomeAction(
        id: "dhikr", icon: "circle.grid.3x3.fill", title: "Dhikr",
        subtitle: "Remembrance", colorName: .purple, destination: .route("dhikr")
    )
    static let qibla = HomeAction(
        id: "qibla", icon: "location.north.fill", title: "Qibla",
        subtitle: "Find direction", colorName: .orange, destination: .route("qibla")
    )
    static let learn = HomeAction(
        id: "learn", icon: "graduationcap.fill", title: "Learn",
        subtitle: "Arabic & Tajweed", colorName: .purple, destination: .disabled("learning")
    )
    static let hadith = HomeAction(
        id: "hadith", icon: "text.book.closed.fill", title: "Hadith",
        subtitle: "Prophetic traditions", colorName: .indigo, destination: .route("hadith")
    )
    static let askSafa = HomeAction(
        id: "askSafa", icon: "sparkles", title: "Ask Safa",
        subtitle: "AI companion", colorName: .orange, destination: .route("chat")
    )

    // MARK: - Resolve

    /// Returns 4 prioritized quick actions with context-aware subtitles.
    static func resolve(
        currentDate: Date = Date(),
        nextPrayer: PrayerTime? = nil,
        loggedPrayers: Set<PrayerType> = [],
        streaks: [Streak] = []
    ) -> [HomeAction] {
        var ranked: [HomeAction] = []

        let hour = Calendar.current.component(.hour, from: currentDate)
        let minutesUntilPrayer = minutesUntil(nextPrayer, from: currentDate)

        // Rule 1: Prayer within 30 minutes → Prayer first with countdown subtitle
        if let mins = minutesUntilPrayer, mins <= 30, mins > 0, let prayerType = nextPrayer?.type {
            ranked.append(prayer.with(subtitle: "\(prayerType.displayName) in \(mins) min"))
        }

        // Rule 2: Streak at risk → promote with streak context
        for streak in streaks where streak.isAtRisk && streak.currentCount > 3 {
            if let action = actionForStreakType(streak.type), !ranked.contains(action) {
                ranked.append(action.with(subtitle: "\(streak.currentCount)-day streak at risk"))
            }
        }

        // Rule 3: Seasonal promotions with contextual subtitles
        let seasonal = seasonalPromotions(for: currentDate)
        for action in seasonal where !ranked.contains(action) {
            ranked.append(action)
            if ranked.count >= 4 { break }
        }

        // Rule 4: Time-based defaults fill remaining slots (default subtitles)
        let timeDefaults = timeBasedDefaults(hour: hour)
        for action in timeDefaults where !ranked.contains(action) {
            ranked.append(action)
            if ranked.count >= 4 { break }
        }

        // Pad to 4 if needed (Prayer, Quran, Duas omitted — accessible via tab bar)
        let fallback = [hadith, dhikr, askSafa, qibla]
        for action in fallback where ranked.count < 4 {
            if !ranked.contains(action) {
                ranked.append(action)
            }
        }

        return Array(ranked.prefix(4))
    }

    // MARK: - Private Helpers

    private static func minutesUntil(_ prayer: PrayerTime?, from date: Date) -> Int? {
        guard let prayer else { return nil }
        let interval = prayer.time.timeIntervalSince(date)
        guard interval > 0 else { return nil }
        return Int(interval / 60)
    }

    private static func actionForStreakType(_ type: StreakType) -> HomeAction? {
        switch type {
        case .prayer: return prayer
        case .quran: return quran
        case .dhikr: return dhikr
        case .daily: return nil
        case .learning: return learn
        }
    }

    // MARK: - Seasonal Promotions

    private static let islamicCalendar = Calendar(identifier: .islamicUmmAlQura)

    /// Returns actions with context-specific subtitles based on Islamic calendar and weekly cycle.
    static func seasonalPromotions(for date: Date) -> [HomeAction] {
        var promotions: [HomeAction] = []

        let islamicMonth = islamicCalendar.component(.month, from: date)
        let islamicDay = islamicCalendar.component(.day, from: date)
        let weekday = Calendar.current.component(.weekday, from: date)

        // Ramadan (month 9)
        if islamicMonth == 9 {
            promotions.append(quran.with(subtitle: "Ramadan reading"))
            promotions.append(duas.with(subtitle: "Daily supplications"))
        }

        // Dhul Hijjah first 10 days (month 12)
        if islamicMonth == 12 && islamicDay <= 10 {
            promotions.append(dhikr.with(subtitle: "Blessed days of Dhul Hijjah"))
            if islamicDay == 9 {
                promotions.append(duas.with(subtitle: "Day of Arafah duas"))
            }
        }

        // Friday
        if weekday == 6 {
            promotions.append(quran.with(subtitle: "Read Surah Al-Kahf"))
        }

        // Monday/Thursday (sunnah fasting)
        if weekday == 2 || weekday == 5 {
            promotions.append(dhikr.with(subtitle: "Sunnah fasting day"))
            promotions.append(duas.with(subtitle: "Sunnah fasting day"))
        }

        return promotions
    }

    /// Returns 4 actions ordered by time-of-day relevance.
    /// Prayer, Quran, Duas omitted — they're accessible via the tab bar.
    static func timeBasedDefaults(hour: Int) -> [HomeAction] {
        switch hour {
        case 4..<9:
            return [dhikr.with(subtitle: "Morning adhkar"), hadith, askSafa, qibla]
        case 9..<14:
            return [hadith, dhikr, askSafa, qibla]
        case 14..<17:
            return [hadith, dhikr, askSafa, qibla]
        case 17..<21:
            return [dhikr.with(subtitle: "Evening adhkar"), hadith, askSafa, qibla]
        default:
            return [dhikr, hadith, askSafa, qibla]
        }
    }
}
