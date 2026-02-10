// MARK: - ProgressDashboardView.swift
// PURPOSE: Display user's overall progress and statistics
// DEPENDENCIES: SwiftUI

import SwiftUI

// MARK: - Progress Dashboard View Model

@Observable
final class ProgressDashboardViewModel {
    var userStats = UserStats()
    var streaks: [Streak] = []
    var weeklyData: [DailyProgress] = []
    var monthlyPrayerData: [DayPrayerCount] = []

    struct DailyProgress: Identifiable {
        let id = UUID()
        let date: Date
        let hasanat: Int
        let activities: Int
    }

    struct DayPrayerCount: Identifiable {
        let id = UUID()
        let day: Int
        let count: Int // 0-5 prayers
    }

    init() {
        loadData()
    }

    func loadData() {
        // Sample data for demonstration
        userStats = UserStats(
            totalHasanat: 1250,
            currentLevel: 5,
            unlockedAchievements: ["prayer_first", "quran_first_page", "dhikr_first"],
            lessonsCompleted: 12,
            totalPrayersLogged: 145,
            totalAyahsRead: 420,
            totalTasbeehCount: 3300,
            streakFreezes: 2
        )

        streaks = [
            Streak(type: .daily, currentCount: 15, longestCount: 23, lastActivityDate: Date()),
            Streak(type: .prayer, currentCount: 7, longestCount: 14, lastActivityDate: Date()),
            Streak(type: .quran, currentCount: 3, longestCount: 10, lastActivityDate: Date()),
            Streak(type: .dhikr, currentCount: 5, longestCount: 12, lastActivityDate: Date())
        ]

        // Generate sample weekly data
        let calendar = Calendar.current
        weeklyData = (0..<7).map { dayOffset in
            let date = calendar.date(byAdding: .day, value: -6 + dayOffset, to: Date())!
            return DailyProgress(
                date: date,
                hasanat: Int.random(in: 15...80),
                activities: Int.random(in: 2...8)
            )
        }

        // Generate sample monthly prayer data
        monthlyPrayerData = (1...30).map { day in
            DayPrayerCount(day: day, count: Int.random(in: 0...5))
        }
    }

    var levelProgress: Double {
        let currentLevelHasanat = UserStats.hasanatForLevel(userStats.currentLevel)
        let nextLevelHasanat = UserStats.hasanatForLevel(userStats.currentLevel + 1)
        let range = nextLevelHasanat - currentLevelHasanat
        let progress = userStats.totalHasanat - currentLevelHasanat
        return min(1.0, Double(progress) / Double(range))
    }

    var hasanatToNextLevel: Int {
        let nextLevelHasanat = UserStats.hasanatForLevel(userStats.currentLevel + 1)
        return max(0, nextLevelHasanat - userStats.totalHasanat)
    }
}

// MARK: - Progress Dashboard View

struct ProgressDashboardView: View {
    @State private var viewModel = ProgressDashboardViewModel()
    @State private var selectedTimeRange: TimeRange = .week
    @ScaledMetric(relativeTo: .title) private var levelRingSize: CGFloat = 80

    enum TimeRange: String, CaseIterable {
        case week = "Week"
        case month = "Month"
        case year = "Year"
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                // Level Card
                levelCard

                // Statistics Grid
                statisticsGrid

                // Streaks Section
                streaksSection

                // Activity Chart
                activityChart

                // Prayer Consistency
                prayerConsistencySection

                // Quick Stats
                quickStatsSection
            }
            .padding()
            .padding(.bottom, 80)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Progress")
        .navigationBarTitleDisplayMode(.large)
    }

    // MARK: - Level Card

    private var levelCard: some View {
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

    private var statisticsGrid: some View {
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

    private var streaksSection: some View {
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

    private var activityChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Activity")
                    .font(.headline)

                Spacer()

                Picker("Time Range", selection: $selectedTimeRange) {
                    ForEach(TimeRange.allCases, id: \.self) { range in
                        Text(range.rawValue).tag(range)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 180)
            }

            // Simple bar chart
            HStack(alignment: .bottom, spacing: 8) {
                ForEach(viewModel.weeklyData) { day in
                    VStack(spacing: 4) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.accentColor)
                            .frame(width: 32, height: CGFloat(day.hasanat))

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

    private var prayerConsistencySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Prayer Consistency")
                .font(.headline)

            // Calendar-style grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 7), spacing: 4) {
                // Day headers
                ForEach(["S", "M", "T", "W", "T", "F", "S"], id: \.self) { day in
                    Text(day)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .frame(width: 32, height: 20)
                }

                // Days
                ForEach(viewModel.monthlyPrayerData) { day in
                    PrayerDayCell(count: day.count)
                }
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(12)

            // Legend
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

    // MARK: - Quick Stats Section

    private var quickStatsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Achievements")
                .font(.headline)

            HStack {
                Image(systemName: "trophy.fill")
                    .font(.title)
                    .foregroundColor(.yellow)

                VStack(alignment: .leading, spacing: 2) {
                    Text("\(viewModel.userStats.unlockedAchievements.count) Unlocked")
                        .font(.subheadline)
                        .fontWeight(.medium)

                    Text("of \(Achievement.allAchievements.count) total")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                NavigationLink(destination: AchievementsView()) {
                    Text("View All")
                        .font(.caption)
                        .foregroundColor(.accentColor)
                }
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(12)
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
        formatter.dateFormat = "E"
        return String(formatter.string(from: date).prefix(1))
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

struct StatCard: View {
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

struct StreakCard: View {
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

struct PrayerDayCell: View {
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
    }
}
