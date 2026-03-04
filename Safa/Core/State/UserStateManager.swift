// MARK: - UserStateManager.swift
// PURPOSE: Global state manager for user gamification data
// DEPENDENCIES: Foundation, UserRepositoryProtocol

import Foundation

@Observable
final class UserStateManager {
    // MARK: - Published State
    var userStats: UserStats
    var streaks: [Streak]
    var isLoading: Bool = false
    var error: Error?

    // MARK: - Dependencies
    private let userRepository: UserRepositoryProtocol

    // MARK: - Init
    init(userRepository: UserRepositoryProtocol) {
        self.userRepository = userRepository
        self.userStats = UserStats()
        self.streaks = StreakType.allCases.map { Streak(type: $0) }

        // Listen for invite hasanat notification (from InviteFriendsService)
        NotificationCenter.default.addObserver(
            forName: .inviteHasanatAwarded,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            Task {
                await HasanatTracker.awardOnceEver(.inviteAccepted, key: "inviteAccepted", via: self)
            }
        }

        // Load initial data
        Task {
            await loadUserData()
        }
    }

    // MARK: - Load Data

    func loadUserData() async {
        isLoading = true
        defer { isLoading = false }

        do {
            userStats = try await userRepository.getUserStats()
            streaks = try await userRepository.getStreaks()
            syncStreakToWidget()
        } catch {
            self.error = error
        }
    }

    // MARK: - Hasanat

    @discardableResult
    func awardHasanat(_ award: HasanatAward) async -> Bool {
        do {
            let previousLevel = userStats.currentLevel

            // Check for Ramadan multiplier (Maghrib-aware, same-day validated)
            let maghrib: Date? = {
                guard let t = UserDefaults.standard.object(forKey: AppConstants.StorageKeys.todayMaghribTime) as? Date,
                      Calendar.current.isDate(t, inSameDayAs: Date()) else { return nil }
                return t
            }()
            let points = HijriDateConverter.shared.isRamadan(maghribTime: maghrib) ? award.points * 2 : award.points
            let newTotal = try await userRepository.addHasanat(points)

            // Update local state
            userStats.totalHasanat = newTotal
            userStats.currentLevel = UserStats.calculateLevel(from: newTotal)

            // Record daily hasanat for progress dashboard
            HasanatTracker.recordDailyPoints(points)

            // Congratulate on level-up
            if userStats.currentLevel > previousLevel {
                let level = userStats.currentLevel
                let title = UserStats.levelTitle(for: level)
                Task { @MainActor in
                    ToastService.shared.show(Toast(
                        message: "Level \(level) — \(title)!",
                        type: .success,
                        duration: 3.5
                    ))
                }
            }

            return true
        } catch {
            self.error = error
            return false
        }
    }

    // MARK: - Prayer Counter

    func incrementPrayersLogged() async {
        userStats.totalPrayersLogged += 1
        do {
            try await userRepository.updateUserStats(userStats)
        } catch {
            self.error = error
        }
    }

    // MARK: - Tasbeeh Counter

    func incrementTasbeehCount(by count: Int) async {
        userStats.totalTasbeehCount += count
        do {
            try await userRepository.updateUserStats(userStats)
        } catch {
            self.error = error
        }
    }

    // MARK: - Streaks

    func recordActivity(type: StreakType) async {
        do {
            try await userRepository.recordStreakActivity(type: type)
            streaks = try await userRepository.getStreaks()

            // Award daily open hasanat (once per day, deduped by tracker)
            if type == .daily {
                await HasanatTracker.awardOnce(.dailyOpen, key: "dailyOpen", via: self)
            }

            // Sync streak to widget
            syncStreakToWidget()
        } catch {
            self.error = error
        }
    }

    // MARK: - Computed Properties

    var currentLevel: Int {
        userStats.currentLevel
    }

    var levelTitle: String {
        UserStats.levelTitle(for: currentLevel)
    }

    var totalHasanat: Int {
        userStats.totalHasanat
    }

    var hasanatToNextLevel: Int {
        let nextLevelHasanat = UserStats.hasanatForLevel(currentLevel + 1)
        let currentLevelHasanat = UserStats.hasanatForLevel(currentLevel)
        return nextLevelHasanat - currentLevelHasanat
    }

    var hasanatProgressInLevel: Int {
        let currentLevelHasanat = UserStats.hasanatForLevel(currentLevel)
        return totalHasanat - currentLevelHasanat
    }

    var levelProgress: Double {
        guard hasanatToNextLevel > 0 else { return 1.0 }
        return Double(hasanatProgressInLevel) / Double(hasanatToNextLevel)
    }

    var dailyStreak: Streak? {
        streaks.first { $0.type == .daily }
    }

    var prayerStreak: Streak? {
        streaks.first { $0.type == .prayer }
    }

    // MARK: - Widget Sync

    private func syncStreakToWidget() {
        let streak = dailyStreak ?? prayerStreak
        WidgetDataService.shared.writeStreakData(
            currentCount: streak?.currentCount ?? 0,
            longestCount: streak?.longestCount ?? 0,
            isActiveToday: streak?.isActiveToday ?? false
        )
    }
}
