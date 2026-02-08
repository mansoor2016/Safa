// MARK: - SkeletonView.swift
// PURPOSE: Shimmer-animated skeleton loading placeholders
// DEPENDENCIES: SwiftUI

import SwiftUI

// MARK: - Skeleton Shape

/// A rounded rectangle with a shimmer animation for loading states
struct SkeletonShape: View {
    var width: CGFloat? = nil
    var height: CGFloat = 16

    @State private var isAnimating = false

    var body: some View {
        RoundedRectangle(cornerRadius: 4)
            .fill(Color(UIColor.systemGray5))
            .frame(width: width, height: height)
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .fill(
                        LinearGradient(
                            colors: [.clear, Color(UIColor.systemGray4), .clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .offset(x: isAnimating ? 200 : -200)
            )
            .clipShape(RoundedRectangle(cornerRadius: 4))
            .onAppear {
                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    isAnimating = true
                }
            }
    }
}

// MARK: - Skeleton Card

/// A card-shaped skeleton placeholder
struct SkeletonCard: View {
    var height: CGFloat = 100

    var body: some View {
        RoundedRectangle(cornerRadius: SafaSpacing.CornerRadius.lg)
            .fill(Color(UIColor.secondarySystemBackground))
            .frame(height: height)
            .overlay(
                VStack(alignment: .leading, spacing: 12) {
                    SkeletonShape(width: 100, height: 12)
                    SkeletonShape(height: 20)
                    SkeletonShape(width: 150, height: 14)
                }
                .padding()
                , alignment: .topLeading
            )
    }
}

// MARK: - Prayer Skeleton

/// Skeleton for the Prayer screen (next prayer card + prayer list)
struct PrayerSkeletonView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: SafaSpacing.md) {
                // Next prayer card skeleton
                SkeletonCard(height: 120)

                // Prayer times list skeleton
                VStack(spacing: 0) {
                    ForEach(0..<6, id: \.self) { _ in
                        HStack {
                            SkeletonShape(width: 32, height: 32)
                            VStack(alignment: .leading, spacing: 4) {
                                SkeletonShape(width: 80, height: 14)
                                SkeletonShape(width: 50, height: 12)
                            }
                            Spacer()
                            SkeletonShape(width: 60, height: 14)
                        }
                        .padding(.vertical, 12)
                        .padding(.horizontal)

                        if true { Divider().padding(.leading, 60) }
                    }
                }
                .background(Color(UIColor.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: SafaSpacing.CornerRadius.lg))

                // Quick actions skeleton
                HStack(spacing: SafaSpacing.sm) {
                    ForEach(0..<3, id: \.self) { _ in
                        RoundedRectangle(cornerRadius: SafaSpacing.CornerRadius.md)
                            .fill(Color(UIColor.secondarySystemBackground))
                            .frame(height: 70)
                            .overlay(
                                VStack(spacing: 8) {
                                    SkeletonShape(width: 24, height: 24)
                                    SkeletonShape(width: 50, height: 10)
                                }
                            )
                    }
                }
            }
            .padding()
        }
    }
}

// MARK: - Quran Skeleton

/// Skeleton for the Quran screen (surah list)
struct QuranSkeletonView: View {
    var body: some View {
        List {
            ForEach(0..<15, id: \.self) { _ in
                HStack(spacing: 12) {
                    // Surah number badge
                    SkeletonShape(width: 36, height: 36)

                    // Names
                    VStack(alignment: .leading, spacing: 4) {
                        SkeletonShape(width: 120, height: 16)
                        SkeletonShape(width: 80, height: 12)
                    }

                    Spacer()

                    // Arabic name
                    SkeletonShape(width: 70, height: 20)
                }
                .padding(.vertical, 4)
                .listRowBackground(Color.clear)
            }
        }
        .listStyle(.plain)
    }
}

// MARK: - Home Skeleton

/// Skeleton for the Home screen (prayer card + quick actions + verse)
struct HomeSkeletonView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: SafaSpacing.lg) {
                // Date header skeleton
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        SkeletonShape(width: 140, height: 14)
                        SkeletonShape(width: 100, height: 12)
                    }
                    Spacer()
                }

                // Next prayer card skeleton
                SkeletonCard(height: 100)

                // Quick actions skeleton
                HStack(spacing: SafaSpacing.sm) {
                    ForEach(0..<4, id: \.self) { _ in
                        VStack(spacing: 8) {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(UIColor.secondarySystemBackground))
                                .frame(height: 60)
                                .overlay(SkeletonShape(width: 24, height: 24))
                            SkeletonShape(width: 40, height: 10)
                        }
                    }
                }

                // Daily verse skeleton
                SkeletonCard(height: 140)

                // Progress skeleton
                SkeletonCard(height: 80)
            }
            .padding()
        }
    }
}

// MARK: - Preview

#Preview("Prayer Skeleton") {
    PrayerSkeletonView()
}

#Preview("Quran Skeleton") {
    QuranSkeletonView()
}

#Preview("Home Skeleton") {
    HomeSkeletonView()
}
