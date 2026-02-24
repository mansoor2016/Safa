// MARK: - ProgressDashboardView.swift
// PURPOSE: Display user's prayer consistency and overall progress
// DEPENDENCIES: SwiftUI, ProgressDashboardViewModel, all card components

import SwiftUI

struct ProgressDashboardView: View {
    @Environment(Dependencies.self) private var dependencies
    @State private var viewModel: ProgressDashboardViewModel?

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
                learningRepository: dependencies.learningRepository,
                locationService: dependencies.locationService,
                preferencesManager: PreferencesManager.shared
            )
            viewModel = vm
            await vm.load()
        }
    }

    // MARK: - Content

    private func scrollContent(_ viewModel: ProgressDashboardViewModel) -> some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                Text("Track your prayers and build consistent habits")
                    .font(SafaTypography.bodySmall)
                    .foregroundStyle(SafaColors.Fallback.secondaryText)
                    .frame(maxWidth: .infinity, alignment: .leading)

                TodayPrayerStatusCard(
                    statuses: viewModel.todayPrayerStatuses,
                    scheduleAvailable: viewModel.todayScheduleAvailable
                )

                if let trend = viewModel.consistencyTrend {
                    ConsistencyTrendCard(trend: trend)
                }

                if !viewModel.weeklyPrayerGrid.isEmpty {
                    WeeklyPrayerGrid(
                        grid: viewModel.weeklyPrayerGrid,
                        calendar: .current
                    )
                }

                MonthlyConsistencyCard(
                    monthlyData: viewModel.monthlyPrayerData,
                    prayerStreak: viewModel.prayerStreak,
                    streakFreezes: viewModel.userStats.streakFreezes,
                    calendar: .current,
                    now: Date()
                )

                ProgressStatsFooter(
                    userStats: viewModel.userStats,
                    levelProgress: viewModel.levelProgress,
                    hasanatToNextLevel: viewModel.hasanatToNextLevel
                )
            }
            .padding()
            .padding(.bottom, 80)
        }
    }
}

#Preview {
    NavigationStack {
        ProgressDashboardView()
            .environment(Dependencies())
    }
}
