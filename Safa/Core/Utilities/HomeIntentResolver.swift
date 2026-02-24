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

    // MARK: - Catalog (non-tab-bar features only)

    static let dhikr = HomeAction(
        id: "dhikr", icon: "circle.grid.3x3.fill", title: "Dhikr",
        subtitle: "Remembrance", colorName: .purple, destination: .route("dhikr")
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
    static let qibla = HomeAction(
        id: "qibla", icon: "location.north.fill", title: "Qibla",
        subtitle: "Find direction", colorName: .orange, destination: .route("qibla")
    )

    // MARK: - Resolve

    /// Returns 2 prioritized quick actions for non-tab-bar features.
    /// `isAIAvailable` gates whether Ask Safa appears in the candidate pool.
    static func resolve(
        currentDate: Date = Date(),
        nextPrayer: PrayerTime? = nil,
        loggedPrayers: Set<PrayerType> = [],
        streaks: [Streak] = [],
        isAIAvailable: Bool = false
    ) -> [HomeAction] {
        var ranked: [HomeAction] = []

        let hour = Calendar.current.component(.hour, from: currentDate)

        // Rule 1: Streak at risk → promote with streak context
        for streak in streaks where streak.isAtRisk && streak.currentCount > 3 {
            if let action = actionForStreakType(streak.type), !ranked.contains(action) {
                ranked.append(action.with(subtitle: "\(streak.currentCount)-day streak at risk"))
            }
        }

        // Rule 2: Seasonal promotions with contextual subtitles
        let seasonal = seasonalPromotions(for: currentDate)
        for action in seasonal where !ranked.contains(action) {
            ranked.append(action)
            if ranked.count >= 2 { break }
        }

        // Rule 3: Time-based defaults fill remaining slots
        let timeDefaults = timeBasedDefaults(hour: hour)
            .filter { isAIAvailable || $0.id != "askSafa" }
        for action in timeDefaults where !ranked.contains(action) {
            ranked.append(action)
            if ranked.count >= 2 { break }
        }

        // Pad to 2 if needed
        var fallback = [dhikr, hadith, qibla]
        if isAIAvailable { fallback.insert(askSafa, at: 2) }
        for action in fallback where ranked.count < 2 {
            if !ranked.contains(action) {
                ranked.append(action)
            }
        }

        return Array(ranked.prefix(2))
    }

    // MARK: - Private Helpers

    private static func actionForStreakType(_ type: StreakType) -> HomeAction? {
        switch type {
        case .prayer: return nil   // tab bar
        case .quran: return nil    // tab bar
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
            promotions.append(dhikr.with(subtitle: "Ramadan dhikr"))
        }

        // Dhul Hijjah first 10 days (month 12)
        if islamicMonth == 12 && islamicDay <= 10 {
            promotions.append(dhikr.with(subtitle: "Blessed days of Dhul Hijjah"))
        }

        // Friday
        if weekday == 6 {
            promotions.append(hadith.with(subtitle: "Jumu'ah reading"))
        }

        // Monday/Thursday (sunnah fasting)
        if weekday == 2 || weekday == 5 {
            promotions.append(dhikr.with(subtitle: "Sunnah fasting day"))
        }

        return promotions
    }

    /// Returns actions ordered by time-of-day relevance.
    /// Only non-tab-bar features; resolve() picks the top 2.
    static func timeBasedDefaults(hour: Int) -> [HomeAction] {
        switch hour {
        case 4..<9:
            return [dhikr.with(subtitle: "Morning adhkar"), hadith, qibla, askSafa]
        case 9..<14:
            return [hadith, dhikr, askSafa, qibla]
        case 14..<17:
            return [hadith, dhikr, askSafa, qibla]
        case 17..<21:
            return [dhikr.with(subtitle: "Evening adhkar"), hadith, qibla, askSafa]
        default:
            return [dhikr, hadith, askSafa, qibla]
        }
    }
}
