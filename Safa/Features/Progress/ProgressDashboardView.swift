// MARK: - ProgressDashboardView.swift
// PURPOSE: Display user's overall progress and statistics
// DEPENDENCIES: SwiftUI, UserStateManager, PrayerRepositoryProtocol, QuranRepositoryProtocol, LearningRepositoryProtocol

import SwiftUI

// MARK: - Progress Dashboard View Model

@Observable
final class ProgressDashboardViewModel {
    // MARK: - Published State
    var userStats = UserStats()
    var streaks: [Streak] = []
    var weeklyData: [DailyProgress] = []
    var monthlyPrayerData: [DayPrayerCount] = []
    private(set) var isLoading = false

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

    // MARK: - Init
    init(
        userState: UserStateManager,
        prayerRepository: PrayerRepositoryProtocol,
        quranRepository: QuranRepositoryProtocol,
        learningRepository: LearningRepositoryProtocol
    ) {
        self.userState = userState
        self.prayerRepository = prayerRepository
        self.quranRepository = quranRepository
        self.learningRepository = learningRepository
    }

    // MARK: - Load

    func load() async {
        isLoading = true
        defer { isLoading = false }

        // Always refresh to ensure fresh data (handles async init race)
        await userState.loadUserData()

        // Snapshot gamification stats
        userStats = userState.userStats
        streaks = userState.streaks
        // Query source-of-truth for lessons completed
        if let progress = try? await learningRepository.getOverallProgress() {
            userStats.lessonsCompleted = progress.totalLessonsCompleted
        }

        // Query source-of-truth for ayahs read
        if let quranProgress = try? await quranRepository.getReadingProgress() {
            userStats.totalAyahsRead = quranProgress.totalAyahsRead
        }

        // Weekly hasanat from daily recording keys
        weeklyData = HasanatTracker.weeklyPoints().map { entry in
            DailyProgress(date: entry.date, hasanat: entry.points)
        }

        // Monthly prayer data
        await loadMonthlyPrayerData()
    }

    // MARK: - Computed Properties

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

    // MARK: - Private

    private func loadMonthlyPrayerData() async {
        let calendar = Calendar.current
        let now = Date()
        guard let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now)),
              let startOfNextMonth = calendar.date(byAdding: .month, value: 1, to: startOfMonth)
        else { return }

        let daysInMonth = calendar.range(of: .day, in: .month, for: now)?.count ?? 30

        let endOfMonth = startOfNextMonth.addingTimeInterval(-1)

        do {
            let logs = try await prayerRepository.getPrayerLogs(from: startOfMonth, to: endOfMonth)
            var dayCounts: [Int: Set<String>] = [:]
            for log in logs where log.prayerType.isObligatory {
                let day = calendar.component(.day, from: log.date)
                dayCounts[day, default: []].insert(log.prayerType.rawValue)
            }
            monthlyPrayerData = (1...daysInMonth).map { day in
                DayPrayerCount(day: day, count: min(5, dayCounts[day]?.count ?? 0))
            }
        } catch {
            monthlyPrayerData = (1...daysInMonth).map { DayPrayerCount(day: $0, count: 0) }
        }
    }
}

// MARK: - Progress Dashboard View

struct ProgressDashboardView: View {
    @Environment(Dependencies.self) private var dependencies
    @State private var viewModel: ProgressDashboardViewModel?
    @ScaledMetric(relativeTo: .title) private var levelRingSize: CGFloat = 80

    var body: some View {
        Group {
            if let viewModel, !viewModel.isLoading {
                scrollContent(viewModel)
            } else {
                ProgressView()
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Progress")
        .navigationBarTitleDisplayMode(.large)
        .task {
            guard viewModel == nil else { return }
            let vm = ProgressDashboardViewModel(
                userState: dependencies.userState,
                prayerRepository: dependencies.prayerRepository,
                quranRepository: dependencies.quranRepository,
                learningRepository: dependencies.learningRepository
            )
            viewModel = vm
            await vm.load()
        }
    }

    private func scrollContent(_ viewModel: ProgressDashboardViewModel) -> some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                levelCard(viewModel)
                statisticsGrid(viewModel)
                streaksSection(viewModel)
                activityChart(viewModel)
                prayerConsistencySection(viewModel)
            }
            .padding()
            .padding(.bottom, 80)
        }
    }

    // MARK: - Level Card

    private func levelCard(_ viewModel: ProgressDashboardViewModel) -> some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Level \(viewModel.userStats.currentLevel)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)

                    Text(UserStats.levelTitle(for: viewModel.userStats.currentLevel))
                        .font(.title)
                        .fontWeight(.bold)
                }

                Spacer()

                ZStack {
                    Circle()
                        .stroke(Color.accentColor.opacity(0.2), lineWidth: 8)
                        .frame(width: levelRingSize, height: levelRingSize)

                    Circle()
                        .trim(from: 0, to: viewModel.levelProgress)
                        .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .frame(width: levelRingSize, height: levelRingSize)
                        .rotationEffect(.degrees(-90))

                    Text("\(Int(viewModel.levelProgress * 100))%")
                        .font(.subheadline)
                        .fontWeight(.bold)
                }
            }

            VStack(spacing: 8) {
                HStack {
                    Text("\(viewModel.userStats.totalHasanat) Hasanat")
                        .font(.subheadline)
                        .fontWeight(.medium)

                    Spacer()

                    Text("\(viewModel.hasanatToNextLevel) to Level \(viewModel.userStats.currentLevel + 1)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.accentColor.opacity(0.2))

                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.accentColor)
                            .frame(width: geometry.size.width * viewModel.levelProgress)
                    }
                }
                .frame(height: 8)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
    }

    // MARK: - Statistics Grid

    private func statisticsGrid(_ viewModel: ProgressDashboardViewModel) -> some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            StatCard(
                title: "Prayers",
                value: "\(viewModel.userStats.totalPrayersLogged)",
                icon: "moon.stars",
                color: .blue
            )

            StatCard(
                title: "Ayahs Read",
                value: "\(viewModel.userStats.totalAyahsRead)",
                icon: "book",
                color: .green
            )

            StatCard(
                title: "Lessons",
                value: "\(viewModel.userStats.lessonsCompleted)",
                icon: "graduationcap",
                color: .purple
            )

            StatCard(
                title: "Tasbeeh",
                value: formatNumber(viewModel.userStats.totalTasbeehCount),
                icon: "circle.circle",
                color: .orange
            )
        }
    }

    // MARK: - Streaks Section

    private func streaksSection(_ viewModel: ProgressDashboardViewModel) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Streaks")
                    .font(.headline)

                Spacer()

                HStack(spacing: 4) {
                    Image(systemName: "snowflake")
                        .font(.caption)
                    Text("\(viewModel.userStats.streakFreezes)")
                        .font(.caption)
                }
                .foregroundColor(.blue)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(viewModel.streaks) { streak in
                        StreakCard(streak: streak)
                    }
                }
            }
        }
    }

    // MARK: - Activity Chart

    private func activityChart(_ viewModel: ProgressDashboardViewModel) -> some View {
        let maxHasanat = max(1, viewModel.weeklyData.map(\.hasanat).max() ?? 1)

        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Activity")
                    .font(.headline)

                Spacer()

                Text("This Week")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            HStack(alignment: .bottom, spacing: 8) {
                ForEach(viewModel.weeklyData) { day in
                    VStack(spacing: 4) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.accentColor)
                            .frame(width: 32, height: max(4, CGFloat(day.hasanat) / CGFloat(maxHasanat) * 100))

                        Text(formatWeekday(day.date))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .frame(height: 120)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(12)
        }
    }

    // MARK: - Prayer Consistency Section

    private func prayerConsistencySection(_ viewModel: ProgressDashboardViewModel) -> some View {
        let calendar = Calendar.current
        let now = Date()
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
        let firstDayWeekday = calendar.component(.weekday, from: startOfMonth) // 1=Sun...7=Sat
        let offset = firstDayWeekday - 1

        return VStack(alignment: .leading, spacing: 12) {
            Text("Prayer Consistency")
                .font(.headline)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 7), spacing: 4) {
                ForEach(["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"], id: \.self) { day in
                    Text(day)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .frame(width: 32, height: 20)
                }

                // Empty cells for weekday alignment
                ForEach(0..<offset, id: \.self) { _ in
                    Color.clear
                        .frame(width: 32, height: 32)
                }

                ForEach(viewModel.monthlyPrayerData) { day in
                    PrayerDayCell(count: day.count)
                }
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(12)

            HStack(spacing: 16) {
                ForEach(0...5, id: \.self) { count in
                    HStack(spacing: 4) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(colorForPrayerCount(count))
                            .frame(width: 12, height: 12)
                        Text("\(count)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .center)
        }
    }

    // MARK: - Helpers

    private func formatNumber(_ number: Int) -> String {
        if number >= 1000 {
            return String(format: "%.1fK", Double(number) / 1000)
        }
        return "\(number)"
    }

    private func formatWeekday(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return String(formatter.string(from: date).prefix(3))
    }

    private func colorForPrayerCount(_ count: Int) -> Color {
        switch count {
        case 0: return Color(.systemGray5)
        case 1: return Color.green.opacity(0.2)
        case 2: return Color.green.opacity(0.4)
        case 3: return Color.green.opacity(0.6)
        case 4: return Color.green.opacity(0.8)
        case 5: return Color.green
        default: return Color.green
        }
    }
}

// MARK: - Supporting Views

private struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Spacer()
            }

            Text(value)
                .font(.title2)
                .fontWeight(.bold)

            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
}

private struct StreakCard: View {
    let streak: Streak

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: streak.type.iconName)
                .font(.title2)
                .foregroundColor(streak.isActiveToday ? .orange : .secondary)

            Text("\(streak.currentCount)")
                .font(.title)
                .fontWeight(.bold)

            Text(streak.type.displayName)
                .font(.caption)
                .foregroundColor(.secondary)

            if streak.currentCount == streak.longestCount && streak.currentCount > 0 {
                Text("Best!")
                    .font(.caption2)
                    .foregroundColor(.orange)
            }
        }
        .frame(width: 80)
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
}

private struct PrayerDayCell: View {
    let count: Int

    private var color: Color {
        switch count {
        case 0: return Color(.systemGray5)
        case 1: return Color.green.opacity(0.2)
        case 2: return Color.green.opacity(0.4)
        case 3: return Color.green.opacity(0.6)
        case 4: return Color.green.opacity(0.8)
        case 5: return Color.green
        default: return Color.green
        }
    }

    var body: some View {
        RoundedRectangle(cornerRadius: 4)
            .fill(color)
            .frame(width: 32, height: 32)
    }
}

#Preview {
    NavigationStack {
        ProgressDashboardView()
            .environment(Dependencies())
    }
}
