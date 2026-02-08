// MARK: - AchievementDefinitions.swift
// PURPOSE: Static achievement data definitions
// DEPENDENCIES: Foundation

import Foundation

// MARK: - Achievement Data Provider

enum AchievementDefinitions {

    // MARK: - All Achievements

    static func createAllAchievements() -> [Achievement] {
        return prayerAchievements + quranAchievements + learningAchievements +
               dhikrAchievements + streakAchievements + milestoneAchievements +
               socialAchievements + specialAchievements
    }

    // MARK: - Prayer Achievements

    static let prayerAchievements: [Achievement] = [
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
        )
    ]

    // MARK: - Quran Achievements

    static let quranAchievements: [Achievement] = [
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
        )
    ]

    // MARK: - Learning Achievements

    static let learningAchievements: [Achievement] = [
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
        )
    ]

    // MARK: - Dhikr Achievements

    static let dhikrAchievements: [Achievement] = [
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
            id: "morning_dhikr",
            title: "Morning Light",
            description: "Complete morning dhikr",
            iconName: "sunrise.fill",
            category: .dhikr,
            requirement: "Complete morning dhikr"
        ),
        Achievement(
            id: "evening_dhikr",
            title: "Evening Peace",
            description: "Complete evening dhikr",
            iconName: "sunset.fill",
            category: .dhikr,
            requirement: "Complete evening dhikr"
        )
    ]

    // MARK: - Streak Achievements

    static let streakAchievements: [Achievement] = [
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
        )
    ]

    // MARK: - Milestone Achievements

    static let milestoneAchievements: [Achievement] = [
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
        )
    ]

    // MARK: - Social Achievements

    static let socialAchievements: [Achievement] = [
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
        )
    ]

    // MARK: - Special Achievements

    static let specialAchievements: [Achievement] = [
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

    // MARK: - All Criteria

    static func createAllCriteria() -> [String: AchievementCriteria] {
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
