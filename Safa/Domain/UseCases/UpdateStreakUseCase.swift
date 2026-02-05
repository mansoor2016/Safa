// MARK: - UpdateStreakUseCase.swift
// PURPOSE: Use case for managing and updating user streaks
// DEPENDENCIES: Foundation

import Foundation

// MARK: - Streak Activity

/// Represents an activity that can contribute to a streak
enum StreakActivity {
    case prayer(PrayerType)
    case allPrayers
    case quranReading
    case dhikr
    case learning
    case anyActivity // For daily streak

    var associatedStreakType: StreakType {
        switch self {
        case .prayer, .allPrayers:
            return .prayer
        case .quranReading:
            return .quran
        case .dhikr:
            return .dhikr
        case .learning:
            return .learning
        case .anyActivity:
            return .daily
        }
    }
}

// MARK: - Streak Update Result

struct StreakUpdateResult {
    let streakType: StreakType
    let previousCount: Int
    let newCount: Int
    let isNewRecord: Bool
    let milestoneReached: Int? // e.g., 7, 30, 100
    let streakBroken: Bool
    let freezeUsed: Bool

    var countIncreased: Bool {
        newCount > previousCount
    }
}

// MARK: - Update Streak Use Case Protocol

protocol UpdateStreakUseCaseProtocol {
    func recordActivity(_ activity: StreakActivity, at date: Date) -> StreakUpdateResult
    func checkAndUpdateStreaks(for date: Date) -> [StreakUpdateResult]
    func useStreakFreeze(for streakType: StreakType) -> Bool
    func getStreak(for type: StreakType) -> Streak
    func getAllStreaks() -> [Streak]
}

// MARK: - Update Streak Use Case Implementation

final class UpdateStreakUseCase: UpdateStreakUseCaseProtocol {

    // MARK: - Properties

    private var streaks: [StreakType: Streak]
    private var activityLog: [Date: Set<StreakType>] = [:]
    private var availableFreezes: Int = 0
    private let calendar = Calendar.current

    // MARK: - Streak Milestones

    private let milestones = [3, 7, 14, 21, 30, 60, 90, 100, 150, 200, 300, 365]

    // MARK: - Initialization

    init() {
        // Initialize all streak types
        var initialStreaks: [StreakType: Streak] = [:]
        for type in StreakType.allCases {
            initialStreaks[type] = Streak(type: type)
        }
        self.streaks = initialStreaks
    }

    // MARK: - Public Methods

    /// Record an activity and update the appropriate streak
    func recordActivity(_ activity: StreakActivity, at date: Date = Date()) -> StreakUpdateResult {
        let streakType = activity.associatedStreakType
        var streak = streaks[streakType] ?? Streak(type: streakType)

        let startOfDay = calendar.startOfDay(for: date)
        let previousCount = streak.currentCount
        let previousLongest = streak.longestCount

        // Check if already logged today
        if let todayActivities = activityLog[startOfDay], todayActivities.contains(streakType) {
            // Already logged today, no change
            return StreakUpdateResult(
                streakType: streakType,
                previousCount: previousCount,
                newCount: streak.currentCount,
                isNewRecord: false,
                milestoneReached: nil,
                streakBroken: false,
                freezeUsed: false
            )
        }

        // Check streak continuity
        let (streakValid, freezeUsed) = checkStreakContinuity(for: streak, at: date)

        if !streakValid {
            // Streak broken, reset to 1
            streak.currentCount = 1
            streak.lastActivityDate = date
            streaks[streakType] = streak

            // Log activity
            logActivity(streakType, on: startOfDay)

            // Also update daily streak
            if streakType != .daily {
                _ = recordActivity(.anyActivity, at: date)
            }

            return StreakUpdateResult(
                streakType: streakType,
                previousCount: previousCount,
                newCount: 1,
                isNewRecord: false,
                milestoneReached: nil,
                streakBroken: true,
                freezeUsed: false
            )
        }

        // Increment streak
        streak.currentCount += 1
        streak.lastActivityDate = date

        // Update longest if needed
        let isNewRecord = streak.currentCount > streak.longestCount
        if isNewRecord {
            streak.longestCount = streak.currentCount
        }

        // Check for milestone
        let milestoneReached = milestones.first { $0 == streak.currentCount }

        // Save updated streak
        streaks[streakType] = streak

        // Log activity
        logActivity(streakType, on: startOfDay)

        // Also update daily streak if this isn't the daily streak
        if streakType != .daily {
            _ = recordActivity(.anyActivity, at: date)
        }

        return StreakUpdateResult(
            streakType: streakType,
            previousCount: previousCount,
            newCount: streak.currentCount,
            isNewRecord: isNewRecord,
            milestoneReached: milestoneReached,
            streakBroken: false,
            freezeUsed: freezeUsed
        )
    }

    /// Check all streaks and update them based on current date
    func checkAndUpdateStreaks(for date: Date = Date()) -> [StreakUpdateResult] {
        var results: [StreakUpdateResult] = []

        for (type, streak) in streaks {
            let (continuityValid, _) = checkStreakContinuity(for: streak, at: date)

            if !continuityValid && streak.currentCount > 0 {
                // Streak needs to be broken
                var updatedStreak = streak
                let previousCount = updatedStreak.currentCount
                updatedStreak.currentCount = 0
                streaks[type] = updatedStreak

                results.append(StreakUpdateResult(
                    streakType: type,
                    previousCount: previousCount,
                    newCount: 0,
                    isNewRecord: false,
                    milestoneReached: nil,
                    streakBroken: true,
                    freezeUsed: false
                ))
            }
        }

        return results
    }

    /// Use a streak freeze to preserve a streak
    func useStreakFreeze(for streakType: StreakType) -> Bool {
        guard availableFreezes > 0 else { return false }

        availableFreezes -= 1

        // Mark the streak as "frozen" for today
        var streak = streaks[streakType] ?? Streak(type: streakType)
        streak.lastActivityDate = Date()
        streaks[streakType] = streak

        return true
    }

    /// Get a specific streak
    func getStreak(for type: StreakType) -> Streak {
        return streaks[type] ?? Streak(type: type)
    }

    /// Get all streaks
    func getAllStreaks() -> [Streak] {
        return Array(streaks.values).sorted { $0.type.rawValue < $1.type.rawValue }
    }

    /// Add streak freezes (earned through activity)
    func addStreakFreezes(_ count: Int) {
        availableFreezes += count
    }

    /// Get available freezes count
    func getAvailableFreezes() -> Int {
        return availableFreezes
    }

    // MARK: - Private Methods

    private func checkStreakContinuity(for streak: Streak, at date: Date) -> (isValid: Bool, freezeUsed: Bool) {
        guard let lastActivity = streak.lastActivityDate else {
            // No previous activity, this is the first one
            return (true, false)
        }

        let lastActivityDay = calendar.startOfDay(for: lastActivity)
        let currentDay = calendar.startOfDay(for: date)

        // Check if same day
        if lastActivityDay == currentDay {
            return (true, false)
        }

        // Check if yesterday
        if let yesterday = calendar.date(byAdding: .day, value: -1, to: currentDay),
           lastActivityDay == yesterday {
            return (true, false)
        }

        // Check if day before yesterday (could use freeze)
        if let twoDaysAgo = calendar.date(byAdding: .day, value: -2, to: currentDay),
           lastActivityDay == twoDaysAgo,
           availableFreezes > 0 {
            // Auto-use freeze if available
            return (true, true)
        }

        // Streak is broken
        return (false, false)
    }

    private func logActivity(_ type: StreakType, on date: Date) {
        if activityLog[date] == nil {
            activityLog[date] = Set<StreakType>()
        }
        activityLog[date]?.insert(type)
    }
}

// MARK: - Streak Manager

/// Manager class that coordinates streak updates across the app
@Observable
final class StreakManager {
    private let updateStreakUseCase: UpdateStreakUseCaseProtocol
    private let hasanatService: HasanatService

    var dailyStreak: Streak { updateStreakUseCase.getStreak(for: .daily) }
    var prayerStreak: Streak { updateStreakUseCase.getStreak(for: .prayer) }
    var quranStreak: Streak { updateStreakUseCase.getStreak(for: .quran) }
    var dhikrStreak: Streak { updateStreakUseCase.getStreak(for: .dhikr) }
    var learningStreak: Streak { updateStreakUseCase.getStreak(for: .learning) }

    var allStreaks: [Streak] { updateStreakUseCase.getAllStreaks() }

    init(
        updateStreakUseCase: UpdateStreakUseCaseProtocol = UpdateStreakUseCase(),
        hasanatService: HasanatService = HasanatService()
    ) {
        self.updateStreakUseCase = updateStreakUseCase
        self.hasanatService = hasanatService
    }

    /// Record a prayer and update relevant streaks
    func recordPrayer(_ prayer: PrayerType) {
        let result = updateStreakUseCase.recordActivity(.prayer(prayer), at: Date())
        handleStreakResult(result)
    }

    /// Record all five prayers completed
    func recordAllPrayersCompleted() {
        let result = updateStreakUseCase.recordActivity(.allPrayers, at: Date())
        handleStreakResult(result)
    }

    /// Record Quran reading
    func recordQuranReading() {
        let result = updateStreakUseCase.recordActivity(.quranReading, at: Date())
        handleStreakResult(result)
    }

    /// Record dhikr completion
    func recordDhikr() {
        let result = updateStreakUseCase.recordActivity(.dhikr, at: Date())
        handleStreakResult(result)
    }

    /// Record learning activity
    func recordLearning() {
        let result = updateStreakUseCase.recordActivity(.learning, at: Date())
        handleStreakResult(result)
    }

    /// Check streaks at app launch or midnight
    func checkStreaks() {
        let results = updateStreakUseCase.checkAndUpdateStreaks(for: Date())
        for result in results {
            if result.streakBroken {
                // Could trigger UI notification about broken streak
            }
        }
    }

    // MARK: - Private Methods

    private func handleStreakResult(_ result: StreakUpdateResult) {
        // Award Hasanat for milestones
        if let milestone = result.milestoneReached {
            hasanatService.award(for: .streakMilestone(days: milestone))
        }

        // Award Hasanat for new records
        if result.isNewRecord && result.newCount > 7 {
            // Bonus for new personal records
            hasanatService.award(for: .streakMilestone(days: result.newCount))
        }

        // Award streak freeze for 7-day milestones
        if let milestone = result.milestoneReached, milestone % 7 == 0 {
            if let useCase = updateStreakUseCase as? UpdateStreakUseCase {
                useCase.addStreakFreezes(1)
            }
        }
    }
}

// MARK: - Streak Extensions

extension Streak {
    /// Check if at risk of breaking (no activity yesterday)
    var isAtRisk: Bool {
        guard let lastActivity = lastActivityDate else { return false }
        let calendar = Calendar.current
        let yesterday = calendar.date(byAdding: .day, value: -1, to: Date())!
        return calendar.isDate(lastActivity, inSameDayAs: yesterday) == false &&
               calendar.isDateInToday(lastActivity) == false
    }

    /// Days until streak is at risk
    var daysUntilRisk: Int {
        guard let lastActivity = lastActivityDate else { return 0 }
        let calendar = Calendar.current

        if calendar.isDateInToday(lastActivity) {
            return 1 // Activity today, safe for tomorrow
        } else {
            let daysSince = calendar.dateComponents([.day], from: lastActivity, to: Date()).day ?? 0
            return max(0, 1 - daysSince)
        }
    }
}
