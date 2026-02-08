// MARK: - ContextualReminderService.swift
// PURPOSE: Service for generating contextual reminders based on time, user activity, and Islamic calendar
// DEPENDENCIES: Foundation

import Foundation

// MARK: - Contextual Reminder

struct ContextualReminder: Identifiable, Equatable {
    let id: String
    let title: String
    let subtitle: String
    let iconName: String
    let actionType: ReminderActionType
    let priority: ReminderPriority

    enum ReminderPriority: Int, Comparable {
        case low = 1
        case medium = 2
        case high = 3
        case urgent = 4

        static func < (lhs: ReminderPriority, rhs: ReminderPriority) -> Bool {
            lhs.rawValue < rhs.rawValue
        }
    }
}

enum ReminderActionType: Equatable {
    case prayer(PrayerType)
    case morningDhikr
    case eveningDhikr
    case sleepDhikr
    case quranReading
    case fridayPreparation
    case tahajjud
    case fasting
    case ramadanReminder
    case streakAtRisk(StreakType)
    case weeklyReflection
    case duaTime
    case general(String)
}

// MARK: - Contextual Reminder Service

@Observable
final class ContextualReminderService {

    // MARK: - Properties

    private let calendar = Calendar.current
    private let islamicCalendar = Calendar(identifier: .islamicUmmAlQura)

    // MARK: - Public Methods

    /// Get contextual reminders for the current time and user state
    func getReminders(
        currentDate: Date = Date(),
        nextPrayer: PrayerTime? = nil,
        userStats: UserStats? = nil,
        streaks: [Streak] = []
    ) -> [ContextualReminder] {
        var reminders: [ContextualReminder] = []

        // Time-based reminders
        reminders.append(contentsOf: getTimeBasedReminders(currentDate: currentDate))

        // Prayer-based reminders
        if let prayer = nextPrayer {
            reminders.append(contentsOf: getPrayerReminders(nextPrayer: prayer, currentDate: currentDate))
        }

        // Day-specific reminders
        reminders.append(contentsOf: getDaySpecificReminders(currentDate: currentDate))

        // Streak-based reminders
        reminders.append(contentsOf: getStreakReminders(streaks: streaks))

        // Islamic calendar reminders
        reminders.append(contentsOf: getIslamicCalendarReminders(currentDate: currentDate))

        // Sort by priority and return top reminders
        return reminders
            .sorted { $0.priority > $1.priority }
            .prefix(3)
            .map { $0 }
    }

    /// Get the most relevant single reminder
    func getPrimaryReminder(
        currentDate: Date = Date(),
        nextPrayer: PrayerTime? = nil,
        userStats: UserStats? = nil,
        streaks: [Streak] = []
    ) -> ContextualReminder? {
        return getReminders(
            currentDate: currentDate,
            nextPrayer: nextPrayer,
            userStats: userStats,
            streaks: streaks
        ).first
    }

    // MARK: - Private Methods - Time Based

    private func getTimeBasedReminders(currentDate: Date) -> [ContextualReminder] {
        var reminders: [ContextualReminder] = []
        let hour = calendar.component(.hour, from: currentDate)

        // Early morning (before Fajr) - Tahajjud time
        if hour >= 3 && hour < 5 {
            reminders.append(ContextualReminder(
                id: "tahajjud",
                title: "Tahajjud Time",
                subtitle: "The last third of the night - a blessed time for prayer and dua",
                iconName: "moon.stars.fill",
                actionType: .tahajjud,
                priority: .high
            ))
        }

        // Morning dhikr time (after Fajr until sunrise)
        if hour >= 5 && hour < 8 {
            reminders.append(ContextualReminder(
                id: "morning_dhikr",
                title: "Morning Dhikr",
                subtitle: "Start your day with remembrance of Allah",
                iconName: "sunrise.fill",
                actionType: .morningDhikr,
                priority: .high
            ))
        }

        // Quran reading reminder (morning)
        if hour >= 8 && hour < 11 {
            reminders.append(ContextualReminder(
                id: "quran_morning",
                title: "Quran Reading",
                subtitle: "A peaceful time to connect with the Quran",
                iconName: "book.fill",
                actionType: .quranReading,
                priority: .medium
            ))
        }

        // Midday dua time
        if hour >= 12 && hour < 14 {
            reminders.append(ContextualReminder(
                id: "dua_midday",
                title: "Make Dua",
                subtitle: "Remember Allah in the middle of your day",
                iconName: "hands.sparkles.fill",
                actionType: .duaTime,
                priority: .low
            ))
        }

        // Evening dhikr time (after Asr until Maghrib)
        if hour >= 16 && hour < 19 {
            reminders.append(ContextualReminder(
                id: "evening_dhikr",
                title: "Evening Dhikr",
                subtitle: "End your day with remembrance",
                iconName: "sunset.fill",
                actionType: .eveningDhikr,
                priority: .high
            ))
        }

        // Sleep dhikr time (night)
        if hour >= 21 || hour < 1 {
            reminders.append(ContextualReminder(
                id: "sleep_dhikr",
                title: "Sleep Dhikr",
                subtitle: "Prepare for restful sleep with dhikr",
                iconName: "moon.zzz.fill",
                actionType: .sleepDhikr,
                priority: .medium
            ))
        }

        return reminders
    }

    // MARK: - Private Methods - Prayer Based

    private func getPrayerReminders(nextPrayer: PrayerTime, currentDate: Date) -> [ContextualReminder] {
        var reminders: [ContextualReminder] = []

        let timeUntilPrayer = nextPrayer.time.timeIntervalSince(currentDate)
        let minutesUntil = Int(timeUntilPrayer / 60)

        // Prayer is very soon (within 15 minutes)
        if minutesUntil > 0 && minutesUntil <= 15 {
            reminders.append(ContextualReminder(
                id: "prayer_soon_\(nextPrayer.type.rawValue)",
                title: "\(nextPrayer.type.displayName) in \(minutesUntil) min",
                subtitle: "Time to prepare for prayer",
                iconName: nextPrayer.type.iconName,
                actionType: .prayer(nextPrayer.type),
                priority: .urgent
            ))
        }
        // Prayer is coming up (within 30 minutes)
        else if minutesUntil > 15 && minutesUntil <= 30 {
            reminders.append(ContextualReminder(
                id: "prayer_coming_\(nextPrayer.type.rawValue)",
                title: "\(nextPrayer.type.displayName) Coming Up",
                subtitle: "In about \(minutesUntil) minutes",
                iconName: nextPrayer.type.iconName,
                actionType: .prayer(nextPrayer.type),
                priority: .high
            ))
        }

        return reminders
    }

    // MARK: - Private Methods - Day Specific

    private func getDaySpecificReminders(currentDate: Date) -> [ContextualReminder] {
        var reminders: [ContextualReminder] = []

        let weekday = calendar.component(.weekday, from: currentDate)
        let hour = calendar.component(.hour, from: currentDate)

        // Friday reminders
        if weekday == 6 { // Friday
            if hour >= 6 && hour < 12 {
                reminders.append(ContextualReminder(
                    id: "friday_prep",
                    title: "Jumu'ah Mubarak",
                    subtitle: "Prepare for Friday prayer - read Surah Al-Kahf",
                    iconName: "star.fill",
                    actionType: .fridayPreparation,
                    priority: .high
                ))
            }

            // Friday dua time
            if hour >= 14 && hour < 16 {
                reminders.append(ContextualReminder(
                    id: "friday_dua",
                    title: "Special Friday Hour",
                    subtitle: "A time when duas are especially accepted",
                    iconName: "hands.sparkles.fill",
                    actionType: .duaTime,
                    priority: .high
                ))
            }
        }

        // Thursday night (leads to Friday)
        if weekday == 5 && hour >= 18 {
            reminders.append(ContextualReminder(
                id: "thursday_night",
                title: "Night Before Jumu'ah",
                subtitle: "Send salawat upon the Prophet ﷺ",
                iconName: "moon.stars",
                actionType: .general("salawat"),
                priority: .medium
            ))
        }

        // Sunday - weekly reflection
        if weekday == 1 && hour >= 18 && hour < 21 {
            reminders.append(ContextualReminder(
                id: "weekly_reflection",
                title: "Weekly Reflection",
                subtitle: "Review your spiritual progress this week",
                iconName: "chart.line.uptrend.xyaxis",
                actionType: .weeklyReflection,
                priority: .low
            ))
        }

        return reminders
    }

    // MARK: - Private Methods - Streak Based

    private func getStreakReminders(streaks: [Streak]) -> [ContextualReminder] {
        var reminders: [ContextualReminder] = []

        for streak in streaks {
            if streak.isAtRisk && streak.currentCount > 3 {
                reminders.append(ContextualReminder(
                    id: "streak_risk_\(streak.type.rawValue)",
                    title: "\(streak.type.displayName) Streak at Risk!",
                    subtitle: "Don't lose your \(streak.currentCount)-day streak",
                    iconName: "flame.fill",
                    actionType: .streakAtRisk(streak.type),
                    priority: .urgent
                ))
            }
        }

        return reminders
    }

    // MARK: - Private Methods - Islamic Calendar

    private func getIslamicCalendarReminders(currentDate: Date) -> [ContextualReminder] {
        var reminders: [ContextualReminder] = []

        let islamicMonth = islamicCalendar.component(.month, from: currentDate)
        let islamicDay = islamicCalendar.component(.day, from: currentDate)

        // Ramadan
        if islamicMonth == 9 {
            reminders.append(ContextualReminder(
                id: "ramadan_active",
                title: "Ramadan Mubarak",
                subtitle: "Day \(islamicDay) of the blessed month",
                iconName: "moon.fill",
                actionType: .ramadanReminder,
                priority: .high
            ))

            // Last 10 nights
            if islamicDay >= 21 {
                reminders.append(ContextualReminder(
                    id: "last_ten_nights",
                    title: "The Last Ten Nights",
                    subtitle: "Seek Laylatul Qadr with extra worship",
                    iconName: "sparkles",
                    actionType: .tahajjud,
                    priority: .urgent
                ))
            }
        }

        // Dhul Hijjah - first 10 days
        if islamicMonth == 12 && islamicDay <= 10 {
            reminders.append(ContextualReminder(
                id: "dhul_hijjah",
                title: "Blessed Days of Dhul Hijjah",
                subtitle: "The best days for good deeds",
                iconName: "star.fill",
                actionType: .general("dhul_hijjah"),
                priority: .high
            ))

            // Day of Arafah
            if islamicDay == 9 {
                reminders.append(ContextualReminder(
                    id: "day_of_arafah",
                    title: "Day of Arafah",
                    subtitle: "Fast today for forgiveness of two years",
                    iconName: "sun.max.fill",
                    actionType: .fasting,
                    priority: .urgent
                ))
            }
        }

        // Muharram - Day of Ashura
        if islamicMonth == 1 && (islamicDay == 9 || islamicDay == 10) {
            reminders.append(ContextualReminder(
                id: "ashura",
                title: "Day of Ashura",
                subtitle: "Recommended to fast today",
                iconName: "calendar",
                actionType: .fasting,
                priority: .high
            ))
        }

        // Monday and Thursday fasting
        let weekday = calendar.component(.weekday, from: currentDate)
        let hour = calendar.component(.hour, from: currentDate)

        if (weekday == 2 || weekday == 5) && hour < 8 {
            reminders.append(ContextualReminder(
                id: "sunnah_fasting",
                title: "Sunnah Fasting Day",
                subtitle: "The Prophet ﷺ used to fast on \(weekday == 2 ? "Mondays" : "Thursdays")",
                iconName: "leaf.fill",
                actionType: .fasting,
                priority: .low
            ))
        }

        // White days (13th, 14th, 15th of Islamic month)
        if islamicDay >= 13 && islamicDay <= 15 {
            reminders.append(ContextualReminder(
                id: "white_days",
                title: "Al-Ayyam Al-Beed",
                subtitle: "The white days - recommended to fast",
                iconName: "moon.circle.fill",
                actionType: .fasting,
                priority: .low
            ))
        }

        return reminders
    }
}

// MARK: - Reminder Card View Model

@Observable
final class ReminderCardViewModel {
    let reminderService = ContextualReminderService()
    var currentReminders: [ContextualReminder] = []

    func refreshReminders(
        nextPrayer: PrayerTime? = nil,
        userStats: UserStats? = nil,
        streaks: [Streak] = []
    ) {
        currentReminders = reminderService.getReminders(
            currentDate: Date(),
            nextPrayer: nextPrayer,
            userStats: userStats,
            streaks: streaks
        )
    }

    var primaryReminder: ContextualReminder? {
        currentReminders.first
    }
}
