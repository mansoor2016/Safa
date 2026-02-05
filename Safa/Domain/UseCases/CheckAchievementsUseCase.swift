// MARK: - CheckAchievementsUseCase.swift
// PURPOSE: Use case for checking and unlocking achievements
// DEPENDENCIES: Foundation

import Foundation

// MARK: - Type Aliases
typealias AchievementCategory = Achievement.AchievementCategory

// MARK: - Achievement Criteria

/// Defines the requirements for unlocking an achievement
struct AchievementCriteria {
    let achievementId: String
    let requirement: AchievementRequirement
    let category: AchievementCategory
    let tier: AchievementTier

    enum AchievementTier: Int {
        case bronze = 1
        case silver = 2
        case gold = 3
        case platinum = 4
    }
}

/// Types of achievement requirements
enum AchievementRequirement {
    case singleAction(action: String)
    case cumulativeCount(action: String, count: Int)
    case streakDays(type: StreakType, days: Int)
    case levelReached(level: Int)
    case hasanatEarned(amount: Int)
    case prayerStreak(days: Int)
    case quranProgress(pages: Int)
    case quranComplete
    case lessonsCompleted(count: Int)
    case trackCompleted(trackId: String)
    case allTracksCompleted
    case familySize(members: Int)
    case shareCount(count: Int)
    case adhkarCompleted(type: AdhkarType, count: Int)
    case tasbeehCount(total: Int)
    case ramadanComplete
    case perfectWeek
    case perfectMonth
}

// MARK: - Achievement Check Result

struct AchievementCheckResult {
    let achievement: Achievement
    let wasUnlocked: Bool
    let progress: Double // 0.0 to 1.0
    let currentValue: Int
    let targetValue: Int
}

// MARK: - Check Achievements Use Case Protocol

protocol CheckAchievementsUseCaseProtocol {
    func checkAllAchievements(with stats: UserStats) -> [AchievementCheckResult]
    func checkSpecificAchievement(_ achievementId: String, with stats: UserStats) -> AchievementCheckResult?
    func getUnlockedAchievements() -> [Achievement]
    func getLockedAchievements() -> [Achievement]
    func getProgress(for achievementId: String, with stats: UserStats) -> Double
}

// MARK: - Check Achievements Use Case Implementation

final class CheckAchievementsUseCase: CheckAchievementsUseCaseProtocol {

    // MARK: - Properties

    private var unlockedAchievementIds: Set<String> = []
    private let allAchievements: [Achievement]
    private let criteria: [String: AchievementCriteria]

    // MARK: - Initialization

    init() {
        // Initialize all achievements
        self.allAchievements = Self.createAllAchievements()
        self.criteria = Self.createAllCriteria()
    }

    // MARK: - Public Methods

    /// Check all achievements against current stats
    func checkAllAchievements(with stats: UserStats) -> [AchievementCheckResult] {
        var results: [AchievementCheckResult] = []

        for achievement in allAchievements {
            let wasAlreadyUnlocked = unlockedAchievementIds.contains(achievement.id)
            let isNowUnlocked = checkUnlockCondition(for: achievement.id, with: stats)

            let progress = getProgress(for: achievement.id, with: stats)
            let (current, target) = getProgressValues(for: achievement.id, with: stats)

            // If newly unlocked, add to set
            if isNowUnlocked && !wasAlreadyUnlocked {
                unlockedAchievementIds.insert(achievement.id)
            }

            results.append(AchievementCheckResult(
                achievement: achievement,
                wasUnlocked: isNowUnlocked && !wasAlreadyUnlocked,
                progress: progress,
                currentValue: current,
                targetValue: target
            ))
        }

        return results
    }

    /// Check a specific achievement
    func checkSpecificAchievement(_ achievementId: String, with stats: UserStats) -> AchievementCheckResult? {
        guard let achievement = allAchievements.first(where: { $0.id == achievementId }) else {
            return nil
        }

        let wasAlreadyUnlocked = unlockedAchievementIds.contains(achievementId)
        let isNowUnlocked = checkUnlockCondition(for: achievementId, with: stats)

        if isNowUnlocked && !wasAlreadyUnlocked {
            unlockedAchievementIds.insert(achievementId)
        }

        let progress = getProgress(for: achievementId, with: stats)
        let (current, target) = getProgressValues(for: achievementId, with: stats)

        return AchievementCheckResult(
            achievement: achievement,
            wasUnlocked: isNowUnlocked && !wasAlreadyUnlocked,
            progress: progress,
            currentValue: current,
            targetValue: target
        )
    }

    /// Get all unlocked achievements
    func getUnlockedAchievements() -> [Achievement] {
        return allAchievements.filter { unlockedAchievementIds.contains($0.id) }
    }

    /// Get all locked achievements
    func getLockedAchievements() -> [Achievement] {
        return allAchievements.filter { !unlockedAchievementIds.contains($0.id) }
    }

    /// Get progress percentage for an achievement
    func getProgress(for achievementId: String, with stats: UserStats) -> Double {
        let (current, target) = getProgressValues(for: achievementId, with: stats)
        guard target > 0 else { return 0 }
        return min(1.0, Double(current) / Double(target))
    }

    // MARK: - Private Methods

    private func checkUnlockCondition(for achievementId: String, with stats: UserStats) -> Bool {
        guard let criteria = criteria[achievementId] else { return false }

        switch criteria.requirement {
        case .singleAction:
            // These are tracked separately when the action occurs
            return unlockedAchievementIds.contains(achievementId)

        case .cumulativeCount(let action, let count):
            return getCumulativeCount(for: action, stats: stats) >= count

        case .streakDays(_, let days):
            // Would need streak data
            return false // Simplified for now

        case .levelReached(let level):
            return stats.currentLevel >= level

        case .hasanatEarned(let amount):
            return stats.totalHasanat >= amount

        case .prayerStreak(let days):
            // Would need streak data
            return false

        case .quranProgress(let pages):
            return stats.totalAyahsRead / 15 >= pages // ~15 ayahs per page

        case .quranComplete:
            return stats.totalAyahsRead >= 6236 // Total ayahs in Quran

        case .lessonsCompleted(let count):
            return stats.lessonsCompleted >= count

        case .trackCompleted:
            // Would need learning progress data
            return false

        case .allTracksCompleted:
            return false

        case .familySize:
            return false // Would need family data

        case .shareCount:
            return false // Would need share tracking

        case .adhkarCompleted(_, let count):
            return false // Would need adhkar tracking

        case .tasbeehCount(let total):
            return stats.totalTasbeehCount >= total

        case .ramadanComplete:
            return false // Would need Ramadan tracking

        case .perfectWeek:
            return false // Would need calendar tracking

        case .perfectMonth:
            return false
        }
    }

    private func getCumulativeCount(for action: String, stats: UserStats) -> Int {
        switch action {
        case "prayer":
            return stats.totalPrayersLogged
        case "quran":
            return stats.totalAyahsRead
        case "lesson":
            return stats.lessonsCompleted
        case "tasbeeh":
            return stats.totalTasbeehCount
        default:
            return 0
        }
    }

    private func getProgressValues(for achievementId: String, with stats: UserStats) -> (current: Int, target: Int) {
        guard let criteria = criteria[achievementId] else { return (0, 1) }

        switch criteria.requirement {
        case .singleAction:
            return (unlockedAchievementIds.contains(achievementId) ? 1 : 0, 1)

        case .cumulativeCount(let action, let count):
            return (getCumulativeCount(for: action, stats: stats), count)

        case .streakDays(_, let days):
            return (0, days)

        case .levelReached(let level):
            return (stats.currentLevel, level)

        case .hasanatEarned(let amount):
            return (stats.totalHasanat, amount)

        case .prayerStreak(let days):
            return (0, days)

        case .quranProgress(let pages):
            return (stats.totalAyahsRead / 15, pages)

        case .quranComplete:
            return (stats.totalAyahsRead, 6236)

        case .lessonsCompleted(let count):
            return (stats.lessonsCompleted, count)

        case .trackCompleted:
            return (0, 1)

        case .allTracksCompleted:
            return (0, 4) // 4 tracks total

        case .familySize(let members):
            return (0, members)

        case .shareCount(let count):
            return (0, count)

        case .adhkarCompleted(_, let count):
            return (0, count)

        case .tasbeehCount(let total):
            return (stats.totalTasbeehCount, total)

        case .ramadanComplete:
            return (0, 30)

        case .perfectWeek:
            return (0, 7)

        case .perfectMonth:
            return (0, 30)
        }
    }

    // MARK: - Static Achievement Data

    private static func createAllAchievements() -> [Achievement] {
        return [
            // Prayer Achievements
            Achievement(
                id: "first_prayer",
                title: "First Prayer",
                description: "Log your first prayer",
                iconName: "moon.stars.fill",
                category: .prayer,
                requirement: "Log 1 prayer"
            ),
            Achievement(
                id: "prayer_warrior_7",
                title: "Prayer Warrior",
                description: "Maintain a 7-day prayer streak",
                iconName: "flame.fill",
                category: .prayer,
                requirement: "7-day prayer streak"
            ),
            Achievement(
                id: "prayer_master_30",
                title: "Prayer Master",
                description: "Maintain a 30-day prayer streak",
                iconName: "star.fill",
                category: .prayer,
                requirement: "30-day prayer streak"
            ),
            Achievement(
                id: "prayer_devotee_100",
                title: "Prayer Devotee",
                description: "Maintain a 100-day prayer streak",
                iconName: "crown.fill",
                category: .prayer,
                requirement: "100-day prayer streak"
            ),
            Achievement(
                id: "prayers_logged_100",
                title: "Centurion",
                description: "Log 100 prayers",
                iconName: "100.circle.fill",
                category: .prayer,
                requirement: "Log 100 prayers"
            ),
            Achievement(
                id: "prayers_logged_500",
                title: "Prayer Champion",
                description: "Log 500 prayers",
                iconName: "medal.fill",
                category: .prayer,
                requirement: "Log 500 prayers"
            ),

            // Quran Achievements
            Achievement(
                id: "first_ayah",
                title: "First Step",
                description: "Read your first ayah",
                iconName: "book.fill",
                category: .quran,
                requirement: "Read 1 ayah"
            ),
            Achievement(
                id: "quran_reader_100",
                title: "Avid Reader",
                description: "Read 100 ayahs",
                iconName: "books.vertical.fill",
                category: .quran,
                requirement: "Read 100 ayahs"
            ),
            Achievement(
                id: "juz_complete",
                title: "Juz Complete",
                description: "Complete reading one Juz",
                iconName: "bookmark.fill",
                category: .quran,
                requirement: "Complete 1 Juz"
            ),
            Achievement(
                id: "quran_khatm",
                title: "Khatm al-Quran",
                description: "Complete the entire Quran",
                iconName: "seal.fill",
                category: .quran,
                requirement: "Complete the Quran"
            ),

            // Learning Achievements
            Achievement(
                id: "first_lesson",
                title: "Eager Learner",
                description: "Complete your first lesson",
                iconName: "graduationcap.fill",
                category: .learning,
                requirement: "Complete 1 lesson"
            ),
            Achievement(
                id: "lessons_10",
                title: "Knowledge Seeker",
                description: "Complete 10 lessons",
                iconName: "brain.head.profile",
                category: .learning,
                requirement: "Complete 10 lessons"
            ),
            Achievement(
                id: "track_complete",
                title: "Track Master",
                description: "Complete an entire learning track",
                iconName: "trophy.fill",
                category: .learning,
                requirement: "Complete 1 track"
            ),
            Achievement(
                id: "perfect_pronunciation",
                title: "Perfect Pronunciation",
                description: "Get 100% on a pronunciation exercise",
                iconName: "waveform.path",
                category: .learning,
                requirement: "100% pronunciation score"
            ),

            // Dhikr Achievements
            Achievement(
                id: "first_tasbeeh",
                title: "Remembrance",
                description: "Complete your first tasbeeh session",
                iconName: "hands.sparkles.fill",
                category: .dhikr,
                requirement: "Complete 1 tasbeeh"
            ),
            Achievement(
                id: "tasbeeh_1000",
                title: "Devoted",
                description: "Count 1,000 total tasbeeh",
                iconName: "heart.fill",
                category: .dhikr,
                requirement: "1,000 total tasbeeh"
            ),
            Achievement(
                id: "tasbeeh_10000",
                title: "Steadfast Remembrance",
                description: "Count 10,000 total tasbeeh",
                iconName: "sparkles",
                category: .dhikr,
                requirement: "10,000 total tasbeeh"
            ),
            Achievement(
                id: "morning_adhkar",
                title: "Morning Light",
                description: "Complete morning adhkar",
                iconName: "sunrise.fill",
                category: .dhikr,
                requirement: "Complete morning adhkar"
            ),
            Achievement(
                id: "evening_adhkar",
                title: "Evening Peace",
                description: "Complete evening adhkar",
                iconName: "sunset.fill",
                category: .dhikr,
                requirement: "Complete evening adhkar"
            ),

            // Streak Achievements
            Achievement(
                id: "streak_7",
                title: "Week Warrior",
                description: "Maintain a 7-day daily streak",
                iconName: "flame",
                category: .streak,
                requirement: "7-day streak"
            ),
            Achievement(
                id: "streak_30",
                title: "Monthly Master",
                description: "Maintain a 30-day daily streak",
                iconName: "flame.fill",
                category: .streak,
                requirement: "30-day streak"
            ),
            Achievement(
                id: "streak_100",
                title: "Centurion",
                description: "Maintain a 100-day daily streak",
                iconName: "100.circle.fill",
                category: .streak,
                requirement: "100-day streak"
            ),
            Achievement(
                id: "streak_365",
                title: "Year of Devotion",
                description: "Maintain a 365-day streak",
                iconName: "calendar.badge.clock",
                category: .streak,
                requirement: "365-day streak"
            ),

            // Level Achievements
            Achievement(
                id: "level_5",
                title: "Rising Star",
                description: "Reach level 5",
                iconName: "star",
                category: .milestone,
                requirement: "Reach level 5"
            ),
            Achievement(
                id: "level_10",
                title: "Muhsin",
                description: "Reach the highest level",
                iconName: "star.fill",
                category: .milestone,
                requirement: "Reach level 10"
            ),
            Achievement(
                id: "hasanat_1000",
                title: "First Thousand",
                description: "Earn 1,000 Hasanat",
                iconName: "gift.fill",
                category: .milestone,
                requirement: "Earn 1,000 Hasanat"
            ),
            Achievement(
                id: "hasanat_10000",
                title: "Ten Thousand Blessings",
                description: "Earn 10,000 Hasanat",
                iconName: "sparkle",
                category: .milestone,
                requirement: "Earn 10,000 Hasanat"
            ),

            // Social Achievements
            Achievement(
                id: "family_join",
                title: "Family Bonds",
                description: "Join or create a family circle",
                iconName: "person.3.fill",
                category: .social,
                requirement: "Join family circle"
            ),
            Achievement(
                id: "share_first",
                title: "Spreader of Good",
                description: "Share your first verse or achievement",
                iconName: "square.and.arrow.up.fill",
                category: .social,
                requirement: "Share 1 item"
            ),
            Achievement(
                id: "invite_friend",
                title: "Guide",
                description: "Successfully invite a friend",
                iconName: "person.badge.plus",
                category: .social,
                requirement: "Invite 1 friend"
            ),

            // Special Achievements
            Achievement(
                id: "ramadan_complete",
                title: "Ramadan Mubarak",
                description: "Complete all 30 days of Ramadan tracking",
                iconName: "moon.fill",
                category: .special,
                requirement: "Complete Ramadan"
            ),
            Achievement(
                id: "perfect_week",
                title: "Perfect Week",
                description: "Log all 5 prayers every day for a week",
                iconName: "checkmark.seal.fill",
                category: .special,
                requirement: "All prayers for 7 days"
            ),
            Achievement(
                id: "night_owl",
                title: "Night Owl",
                description: "Log Tahajjud prayer",
                iconName: "moon.stars",
                category: .special,
                requirement: "Log Tahajjud"
            )
        ]
    }

    private static func createAllCriteria() -> [String: AchievementCriteria] {
        return [
            "first_prayer": AchievementCriteria(
                achievementId: "first_prayer",
                requirement: .cumulativeCount(action: "prayer", count: 1),
                category: .prayer,
                tier: .bronze
            ),
            "prayer_warrior_7": AchievementCriteria(
                achievementId: "prayer_warrior_7",
                requirement: .prayerStreak(days: 7),
                category: .prayer,
                tier: .silver
            ),
            "prayer_master_30": AchievementCriteria(
                achievementId: "prayer_master_30",
                requirement: .prayerStreak(days: 30),
                category: .prayer,
                tier: .gold
            ),
            "prayers_logged_100": AchievementCriteria(
                achievementId: "prayers_logged_100",
                requirement: .cumulativeCount(action: "prayer", count: 100),
                category: .prayer,
                tier: .silver
            ),
            "quran_reader_100": AchievementCriteria(
                achievementId: "quran_reader_100",
                requirement: .quranProgress(pages: 7),
                category: .quran,
                tier: .bronze
            ),
            "quran_khatm": AchievementCriteria(
                achievementId: "quran_khatm",
                requirement: .quranComplete,
                category: .quran,
                tier: .platinum
            ),
            "first_lesson": AchievementCriteria(
                achievementId: "first_lesson",
                requirement: .lessonsCompleted(count: 1),
                category: .learning,
                tier: .bronze
            ),
            "lessons_10": AchievementCriteria(
                achievementId: "lessons_10",
                requirement: .lessonsCompleted(count: 10),
                category: .learning,
                tier: .silver
            ),
            "tasbeeh_1000": AchievementCriteria(
                achievementId: "tasbeeh_1000",
                requirement: .tasbeehCount(total: 1000),
                category: .dhikr,
                tier: .silver
            ),
            "streak_7": AchievementCriteria(
                achievementId: "streak_7",
                requirement: .streakDays(type: .daily, days: 7),
                category: .streak,
                tier: .bronze
            ),
            "streak_30": AchievementCriteria(
                achievementId: "streak_30",
                requirement: .streakDays(type: .daily, days: 30),
                category: .streak,
                tier: .silver
            ),
            "level_5": AchievementCriteria(
                achievementId: "level_5",
                requirement: .levelReached(level: 5),
                category: .milestone,
                tier: .silver
            ),
            "level_10": AchievementCriteria(
                achievementId: "level_10",
                requirement: .levelReached(level: 10),
                category: .milestone,
                tier: .platinum
            ),
            "hasanat_1000": AchievementCriteria(
                achievementId: "hasanat_1000",
                requirement: .hasanatEarned(amount: 1000),
                category: .milestone,
                tier: .bronze
            ),
            "hasanat_10000": AchievementCriteria(
                achievementId: "hasanat_10000",
                requirement: .hasanatEarned(amount: 10000),
                category: .milestone,
                tier: .gold
            ),
            "ramadan_complete": AchievementCriteria(
                achievementId: "ramadan_complete",
                requirement: .ramadanComplete,
                category: .special,
                tier: .gold
            ),
            "perfect_week": AchievementCriteria(
                achievementId: "perfect_week",
                requirement: .perfectWeek,
                category: .special,
                tier: .gold
            )
        ]
    }
}

// MARK: - Achievement Manager

/// Manager class that coordinates achievement checking across the app
@Observable
final class AchievementManager {
    private let checkUseCase: CheckAchievementsUseCaseProtocol
    private let notificationService: NotificationService?
    private let hapticService: HapticFeedbackService?

    private(set) var recentlyUnlocked: [Achievement] = []
    private(set) var showingAchievementBanner = false
    private(set) var currentAchievementToShow: Achievement?

    var unlockedCount: Int { checkUseCase.getUnlockedAchievements().count }
    var totalCount: Int { checkUseCase.getUnlockedAchievements().count + checkUseCase.getLockedAchievements().count }

    init(
        checkUseCase: CheckAchievementsUseCaseProtocol = CheckAchievementsUseCase(),
        notificationService: NotificationService? = nil,
        hapticService: HapticFeedbackService? = nil
    ) {
        self.checkUseCase = checkUseCase
        self.notificationService = notificationService
        self.hapticService = hapticService
    }

    /// Check achievements with current stats
    func checkAchievements(with stats: UserStats) {
        let results = checkUseCase.checkAllAchievements(with: stats)

        // Collect newly unlocked achievements
        let newlyUnlocked = results.filter { $0.wasUnlocked }.map { $0.achievement }
        recentlyUnlocked.append(contentsOf: newlyUnlocked)

        // Notify user for each newly unlocked achievement
        for achievement in newlyUnlocked {
            notifyAchievementUnlocked(achievement)
        }
    }

    /// Notify user that an achievement was unlocked
    private func notifyAchievementUnlocked(_ achievement: Achievement) {
        // Play celebration haptic
        hapticService?.achievementUnlocked()

        // Show in-app banner
        showAchievementBanner(achievement)

        // Send push notification if app is in background
        Task {
            try? await notificationService?.showAchievementNotification(achievement: achievement)
        }
    }

    /// Show in-app achievement banner
    private func showAchievementBanner(_ achievement: Achievement) {
        currentAchievementToShow = achievement
        showingAchievementBanner = true

        // Auto-dismiss after 4 seconds
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(4))
            self.dismissAchievementBanner()
        }
    }

    /// Dismiss the achievement banner
    func dismissAchievementBanner() {
        showingAchievementBanner = false
        currentAchievementToShow = nil
    }

    /// Clear recently unlocked (after showing to user)
    func clearRecentlyUnlocked() {
        recentlyUnlocked.removeAll()
    }

    /// Get all unlocked achievements
    func getUnlockedAchievements() -> [Achievement] {
        return checkUseCase.getUnlockedAchievements()
    }

    /// Get locked achievements with progress
    func getLockedAchievementsWithProgress(stats: UserStats) -> [(achievement: Achievement, progress: Double)] {
        return checkUseCase.getLockedAchievements().map { achievement in
            let progress = checkUseCase.getProgress(for: achievement.id, with: stats)
            return (achievement, progress)
        }
    }
}

// MARK: - Achievement Banner View

import SwiftUI

/// In-app achievement unlock banner
struct AchievementBannerView: View {
    let achievement: Achievement
    let onDismiss: () -> Void

    @State private var isVisible = false

    var body: some View {
        VStack {
            HStack(spacing: 16) {
                // Achievement Icon
                ZStack {
                    Circle()
                        .fill(Color.accentColor.opacity(0.2))
                        .frame(width: 50, height: 50)

                    Image(systemName: achievement.iconName)
                        .font(.title2)
                        .foregroundStyle(Color.accentColor)
                }

                // Achievement Info
                VStack(alignment: .leading, spacing: 4) {
                    Text("Achievement Unlocked!")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text(achievement.title)
                        .font(.headline)
                        .fontWeight(.bold)

                    Text(achievement.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                // Dismiss Button
                Button(action: onDismiss) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
            .background {
                RoundedRectangle(cornerRadius: 16)
                    .fill(.regularMaterial)
                    .shadow(color: .black.opacity(0.1), radius: 10, y: 5)
            }
            .padding(.horizontal)

            Spacer()
        }
        .offset(y: isVisible ? 0 : -150)
        .opacity(isVisible ? 1 : 0)
        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: isVisible)
        .onAppear {
            isVisible = true
        }
    }
}

// MARK: - Achievement Banner Modifier

struct AchievementBannerModifier: ViewModifier {
    @Bindable var achievementManager: AchievementManager

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .top) {
                if achievementManager.showingAchievementBanner,
                   let achievement = achievementManager.currentAchievementToShow {
                    AchievementBannerView(
                        achievement: achievement,
                        onDismiss: {
                            achievementManager.dismissAchievementBanner()
                        }
                    )
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
    }
}

extension View {
    func achievementBanner(manager: AchievementManager) -> some View {
        modifier(AchievementBannerModifier(achievementManager: manager))
    }
}
