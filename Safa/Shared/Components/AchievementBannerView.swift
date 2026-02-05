// MARK: - AchievementBannerView.swift
// PURPOSE: In-app achievement unlock banner UI
// DEPENDENCIES: SwiftUI, Achievement, AchievementManager

import SwiftUI

// MARK: - Achievement Banner View

/// In-app achievement unlock banner
struct AchievementBannerView: View {
    let achievement: Achievement
    let onDismiss: () -> Void

    @State private var isVisible = false

    var body: some View {
        VStack {
            HStack(spacing: 16) {
                achievementIcon
                achievementInfo
                Spacer()
                dismissButton
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

    // MARK: - Subviews

    private var achievementIcon: some View {
        ZStack {
            Circle()
                .fill(Color.accentColor.opacity(0.2))
                .frame(width: 50, height: 50)

            Image(systemName: achievement.iconName)
                .font(.title2)
                .foregroundStyle(Color.accentColor)
        }
    }

    private var achievementInfo: some View {
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
    }

    private var dismissButton: some View {
        Button(action: onDismiss) {
            Image(systemName: "xmark.circle.fill")
                .foregroundStyle(.secondary)
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

// MARK: - View Extension

extension View {
    func achievementBanner(manager: AchievementManager) -> some View {
        modifier(AchievementBannerModifier(achievementManager: manager))
    }
}

// MARK: - Preview

#Preview {
    VStack {
        AchievementBannerView(
            achievement: Achievement(
                id: "test",
                title: "First Prayer",
                description: "Log your first prayer",
                iconName: "moon.stars.fill",
                category: .prayer,
                requirement: "Log 1 prayer"
            ),
            onDismiss: {}
        )
    }
}
