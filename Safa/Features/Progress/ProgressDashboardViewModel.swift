// MARK: - ProgressDashboardViewModel.swift
// PURPOSE: ViewModel for Progress Dashboard — prayer consistency focus
// DEPENDENCIES: UserStateManager, PrayerRepositoryProtocol, QuranRepositoryProtocol,
//               LearningRepositoryProtocol, LocationServiceProtocol, PreferencesManager

import SwiftUI

@Observable
final class ProgressDashboardViewModel {
    // MARK: - Published State (preserved from original)
    var userStats = UserStats()
    var streaks: [Streak] = []
    var weeklyData: [DailyProgress] = []
    var monthlyPrayerData: [DayPrayerCount] = []
    private(set) var isLoading = false

    // MARK: - New Prayer Consistency State
    private(set) var todayPrayerStatuses: [PrayerDayStatus] = []
    private(set) var weeklyPrayerGrid: [DayPrayerSummary] = []
    private(set) var consistencyTrend: ConsistencyTrend?
    private(set) var prayerStreak: Streak?
    private(set) var todayScheduleAvailable = false

    // MARK: - Preserved Types

    struct DailyProgress: Identifiable {
        let id = UUID()
        let date: Date
        let hasanat: Int
    }

    struct DayPrayerCount: Identifiable {
        let id = UUID()
        let day: Int
        let count: Int // 0-5 prayers
    }

    // MARK: - Dependencies
    private let userState: UserStateManager
    private let prayerRepository: PrayerRepositoryProtocol
    private let quranRepository: QuranRepositoryProtocol
    private let learningRepository: LearningRepositoryProtocol
    private let locationService: LocationServiceProtocol?
    private let preferencesManager: PreferencesManager?
    private let now: () -> Date
    private let calendar: Calendar

    // MARK: - Init
    init(
        userState: UserStateManager,
        prayerRepository: PrayerRepositoryProtocol,
        quranRepository: QuranRepositoryProtocol,
        learningRepository: LearningRepositoryProtocol,
        locationService: LocationServiceProtocol? = nil,
        preferencesManager: PreferencesManager? = nil,
        now: @escaping () -> Date = { Date() },
        calendar: Calendar = .current
    ) {
        self.userState = userState
        self.prayerRepository = prayerRepository
        self.quranRepository = quranRepository
        self.learningRepository = learningRepository
        self.locationService = locationService
        self.preferencesManager = preferencesManager
        self.now = now
        self.calendar = calendar
    }

    // MARK: - Load

    func load() async {
        isLoading = true
        defer { isLoading = false }

        // Refresh gamification state
        await userState.loadUserData()
        userStats = userState.userStats
        streaks = userState.streaks
        prayerStreak = streaks.first { $0.type == .prayer }

        // Query external stats
        await loadExternalStats()

        // Weekly hasanat (preserved)
        weeklyData = HasanatTracker.weeklyPoints().map { entry in
            DailyProgress(date: entry.date, hasanat: entry.points)
        }

        // Single 30-day prayer log fetch
        let currentDate = now()
        let thirtyDaysAgo = calendar.date(byAdding: .day, value: -29, to: calendar.startOfDay(for: currentDate)) ?? currentDate
        let allLogs = (try? await prayerRepository.getPrayerLogs(from: thirtyDaysAgo, to: currentDate)) ?? []

        // Derive all prayer consistency data from the single fetch
        await loadTodayStatus(from: allLogs)
        loadWeeklyGrid(from: allLogs)
        loadMonthlyPrayerData(from: allLogs)
        loadConsistencyTrend(from: allLogs)
    }

    // MARK: - Computed Properties (preserved)

    var levelProgress: Double {
        let currentLevelHasanat = UserStats.hasanatForLevel(userStats.currentLevel)
        let nextLevelHasanat = UserStats.hasanatForLevel(userStats.currentLevel + 1)
        let range = nextLevelHasanat - currentLevelHasanat
        guard range > 0 else { return 1.0 }
        let progress = userStats.totalHasanat - currentLevelHasanat
        return min(1.0, Double(progress) / Double(range))
    }

    var hasanatToNextLevel: Int {
        let nextLevelHasanat = UserStats.hasanatForLevel(userStats.currentLevel + 1)
        return max(0, nextLevelHasanat - userStats.totalHasanat)
    }

    // MARK: - Private: External Stats

    private func loadExternalStats() async {
        if let progress = try? await learningRepository.getOverallProgress() {
            userStats.lessonsCompleted = progress.totalLessonsCompleted
        }
        if let quranProgress = try? await quranRepository.getReadingProgress() {
            userStats.totalAyahsRead = quranProgress.totalAyahsRead
        }
    }

    // MARK: - Private: Today Status

    private func loadTodayStatus(from allLogs: [PrayerLog]) async {
        let currentDate = now()
        let startOfToday = calendar.startOfDay(for: currentDate)

        // Filter today's logs (obligatory only, dedup by prayer type)
        let todayLogs = allLogs.filter { log in
            log.prayerType.isObligatory && calendar.isDate(log.date, inSameDayAs: startOfToday)
        }
        var seenTypes = Set<String>()
        let dedupedLogs = todayLogs.filter { seenTypes.insert($0.prayerType.rawValue).inserted }

        // Try to get today's prayer schedule for isPast determination
        var prayerTimes: [PrayerTime]?
        if let coords = resolveCoordinates(), let prefs = await resolvePreferences() {
            prayerTimes = try? await prayerRepository.getPrayers(
                for: startOfToday,
                location: coords,
                method: prefs.calculationMethod,
                madhab: prefs.madhab
            )
        }

        todayScheduleAvailable = prayerTimes != nil

        todayPrayerStatuses = PrayerType.obligatoryPrayers.map { prayerType in
            let log = dedupedLogs.first { $0.prayerType == prayerType }
            let isPast: Bool
            if let times = prayerTimes,
               let prayerTime = times.first(where: { $0.type == prayerType }) {
                isPast = currentDate > prayerTime.time
            } else {
                // No schedule: treat unlogged as neutral (not past = not missed)
                isPast = log != nil
            }
            return PrayerDayStatus(prayerType: prayerType, date: startOfToday, log: log, isPast: isPast)
        }
    }

    // MARK: - Private: Weekly Grid

    func loadWeeklyGrid(from allLogs: [PrayerLog]) {
        let currentDate = now()
        let weekStart = startOfWeek(for: currentDate)

        weeklyPrayerGrid = (0..<7).compactMap { dayOffset in
            guard let date = calendar.date(byAdding: .day, value: dayOffset, to: weekStart) else { return nil }
            let startOfDay = calendar.startOfDay(for: date)

            // Filter logs for this day, obligatory only, dedup
            let dayLogs = allLogs.filter { log in
                log.prayerType.isObligatory && calendar.isDate(log.date, inSameDayAs: startOfDay)
            }
            var seenTypes = Set<String>()
            let dedupedLogs = dayLogs.filter { seenTypes.insert($0.prayerType.rawValue).inserted }

            let isFutureDay = startOfDay > calendar.startOfDay(for: currentDate)

            let prayers = PrayerType.obligatoryPrayers.map { prayerType in
                let log = dedupedLogs.first { $0.prayerType == prayerType }
                let isPast = !isFutureDay && (log != nil || calendar.startOfDay(for: currentDate) > startOfDay)
                return PrayerDayStatus(prayerType: prayerType, date: startOfDay, log: log, isPast: isPast)
            }

            return DayPrayerSummary(date: startOfDay, prayers: prayers)
        }
    }

    // MARK: - Private: Monthly Prayer Data (preserved + enhanced)

    private func loadMonthlyPrayerData(from allLogs: [PrayerLog]) {
        let currentDate = now()
        guard let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: currentDate)) else { return }

        let daysInMonth = calendar.range(of: .day, in: .month, for: currentDate)?.count ?? 30

        // Filter logs to current month
        let monthLogs = allLogs.filter { log in
            log.prayerType.isObligatory && calendar.isDate(log.date, equalTo: startOfMonth, toGranularity: .month)
        }

        var dayCounts: [Int: Set<String>] = [:]
        for log in monthLogs {
            let day = calendar.component(.day, from: log.date)
            dayCounts[day, default: []].insert(log.prayerType.rawValue)
        }

        monthlyPrayerData = (1...daysInMonth).map { day in
            DayPrayerCount(day: day, count: min(5, dayCounts[day]?.count ?? 0))
        }
    }

    // MARK: - Private: Consistency Trend

    func loadConsistencyTrend(from allLogs: [PrayerLog]) {
        let currentDate = now()
        let thisWeekStart = startOfWeek(for: currentDate)

        guard let lastWeekStart = calendar.date(byAdding: .day, value: -7, to: thisWeekStart),
              let lastWeekEnd = calendar.date(byAdding: .day, value: -1, to: thisWeekStart)
        else { return }

        let obligatoryLogs = allLogs.filter { $0.prayerType.isObligatory }

        // This week: elapsed opportunities
        let elapsedDaysThisWeek = max(1, (calendar.dateComponents([.day], from: thisWeekStart, to: calendar.startOfDay(for: currentDate)).day ?? 0) + 1)
        let thisWeekOpportunities = elapsedDaysThisWeek * 5

        // Count this week's logged prayers (dedup by day+type)
        let thisWeekLogs = obligatoryLogs.filter { $0.date >= thisWeekStart }
        let (thisWeekLogged, thisWeekOnTime) = countDedupedLogs(thisWeekLogs)

        // Last week: full 7 days
        let lastWeekLogs = obligatoryLogs.filter { $0.date >= lastWeekStart && $0.date <= lastWeekEnd }
        let hasBaseline = !lastWeekLogs.isEmpty
        let lastWeekOpportunities = hasBaseline ? 35 : 0
        let (lastWeekLogged, _) = countDedupedLogs(lastWeekLogs)

        let onTimeRate: Double
        if thisWeekOpportunities > 0 {
            onTimeRate = Double(thisWeekOnTime) / Double(thisWeekOpportunities)
        } else {
            onTimeRate = 0
        }

        consistencyTrend = ConsistencyTrend(
            thisWeekLogged: thisWeekLogged,
            thisWeekOpportunities: thisWeekOpportunities,
            lastWeekLogged: lastWeekLogged,
            lastWeekOpportunities: lastWeekOpportunities,
            onTimeRate: onTimeRate,
            hasBaseline: hasBaseline
        )
    }

    // MARK: - Helpers

    private func resolveCoordinates() -> Coordinates? {
        locationService?.coordinates
    }

    private func resolvePreferences() async -> UserPreferences? {
        await preferencesManager?.getPreferences()
    }

    private func startOfWeek(for date: Date) -> Date {
        let cal = calendar
        let components = cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        return cal.date(from: components) ?? calendar.startOfDay(for: date)
    }

    /// Count deduped logged prayers and on-time prayers from a set of logs.
    /// Returns (loggedCount, onTimeCount). On-time excludes makeup.
    private func countDedupedLogs(_ logs: [PrayerLog]) -> (logged: Int, onTime: Int) {
        var seen = Set<String>()
        var logged = 0
        var onTime = 0
        for log in logs {
            let key = "\(Int(calendar.startOfDay(for: log.date).timeIntervalSince1970))_\(log.prayerType.rawValue)"
            if seen.insert(key).inserted {
                logged += 1
                if log.isOnTime && !log.isMakeup {
                    onTime += 1
                }
            }
        }
        return (logged, onTime)
    }

}
