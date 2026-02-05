// MARK: - AchievementsView.swift
// PURPOSE: Display and track user achievements
// DEPENDENCIES: SwiftUI

import SwiftUI

// MARK: - Achievements View Model

@Observable
final class AchievementsViewModel {
    var achievements: [Achievement] = []
    var selectedCategory: Achievement.AchievementCategory?

    var filteredAchievements: [Achievement] {
        if let category = selectedCategory {
            return achievements.filter { $0.category == category }
        }
        return achievements
    }

    var unlockedCount: Int {
        achievements.filter { $0.isUnlocked }.count
    }

    var totalCount: Int {
        achievements.count
    }

    var progressPercentage: Double {
        guard totalCount > 0 else { return 0 }
        return Double(unlockedCount) / Double(totalCount)
    }

    init() {
        loadAchievements()
    }

    func loadAchievements() {
        // Load achievements with some unlocked for demo
        achievements = Achievement.allAchievements.map { achievement in
            var updated = achievement
            // Unlock some achievements for demo
            if ["prayer_first", "quran_first_page", "dhikr_first", "prayer_perfect_day"].contains(achievement.id) {
                updated.isUnlocked = true
                updated.unlockedAt = Date().addingTimeInterval(-Double.random(in: 86400...864000))
            }
            return updated
        }
    }
}

// MARK: - Achievements View

struct AchievementsView: View {
    @State private var viewModel = AchievementsViewModel()
    @State private var selectedAchievement: Achievement?
    @State private var showingDetail = false

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                // Header Stats
                headerStats

                // Category Filter
                categoryFilter

                // Achievements Grid
                achievementsGrid
            }
            .padding()
            .padding(.bottom, 80)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Achievements")
        .navigationBarTitleDisplayMode(.large)
        .sheet(item: $selectedAchievement) { achievement in
            AchievementDetailSheet(achievement: achievement)
        }
    }

    private var headerStats: some View {
        VStack(spacing: 16) {
            // Progress circle
            ZStack {
                Circle()
                    .stroke(Color(.systemGray4), lineWidth: 12)
                    .frame(width: 120, height: 120)

                Circle()
                    .trim(from: 0, to: viewModel.progressPercentage)
                    .stroke(Color.yellow, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))

                VStack(spacing: 2) {
                    Text("\(viewModel.unlockedCount)")
                        .font(.system(size: 32, weight: .bold))

                    Text("of \(viewModel.totalCount)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Text("\(Int(viewModel.progressPercentage * 100))% Complete")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.vertical)
    }

    private var categoryFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                CategoryFilterButton(
                    title: "All",
                    isSelected: viewModel.selectedCategory == nil
                ) {
                    viewModel.selectedCategory = nil
                }

                ForEach(Achievement.AchievementCategory.allCases, id: \.self) { category in
                    CategoryFilterButton(
                        title: category.displayName,
                        isSelected: viewModel.selectedCategory == category
                    ) {
                        viewModel.selectedCategory = category
                    }
                }
            }
        }
    }

    private var achievementsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            ForEach(viewModel.filteredAchievements) { achievement in
                AchievementCard(achievement: achievement)
                    .onTapGesture {
                        selectedAchievement = achievement
                    }
            }
        }
    }
}

// MARK: - Category Filter Button

struct CategoryFilterButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.accentColor : Color(.secondarySystemGroupedBackground))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(20)
        }
    }
}

// MARK: - Achievement Card

struct AchievementCard: View {
    let achievement: Achievement

    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(achievement.isUnlocked ? achievement.color.opacity(0.15) : Color(.systemGray5))
                    .frame(width: 60, height: 60)

                Image(systemName: achievement.icon)
                    .font(.title2)
                    .foregroundColor(achievement.isUnlocked ? achievement.color : .secondary)
            }

            Text(achievement.title)
                .font(.subheadline)
                .fontWeight(.medium)
                .multilineTextAlignment(.center)
                .lineLimit(2)

            if achievement.isUnlocked {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.caption)
            } else {
                Image(systemName: "lock.fill")
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .opacity(achievement.isUnlocked ? 1 : 0.7)
    }
}

// MARK: - Achievement Detail Sheet

struct AchievementDetailSheet: View {
    let achievement: Achievement
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Icon
                ZStack {
                    Circle()
                        .fill(achievement.isUnlocked ? achievement.color.opacity(0.15) : Color(.systemGray5))
                        .frame(width: 100, height: 100)

                    Image(systemName: achievement.icon)
                        .font(.system(size: 44))
                        .foregroundColor(achievement.isUnlocked ? achievement.color : .secondary)
                }
                .padding(.top, 32)

                // Title
                Text(achievement.title)
                    .font(.title2)
                    .fontWeight(.bold)

                // Category
                Text(achievement.category.displayName)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color(.tertiarySystemGroupedBackground))
                    .cornerRadius(8)

                // Description
                Text(achievement.description)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                Spacer()

                // Status
                if achievement.isUnlocked {
                    VStack(spacing: 8) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 48))
                            .foregroundColor(.green)

                        Text("Unlocked!")
                            .font(.headline)
                            .foregroundColor(.green)

                        if let unlockedAt = achievement.unlockedAt {
                            Text(unlockedAt.formatted(date: .abbreviated, time: .omitted))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                } else {
                    VStack(spacing: 8) {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)

                        Text("Locked")
                            .font(.headline)
                            .foregroundColor(.secondary)

                        Text("Keep going to unlock this achievement!")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()
            }
            .navigationTitle("Achievement")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        AchievementsView()
    }
}
