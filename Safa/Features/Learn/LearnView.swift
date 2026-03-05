// MARK: - LearnView.swift
// PURPOSE: Main learning tracks view with lesson progress
// DEPENDENCIES: SwiftUI, LearnViewModel

import SwiftUI

struct LearnView: View {
    @Environment(Dependencies.self) private var dependencies
    @State private var viewModel: LearnViewModel?

    var body: some View {
        Group {
            if FeatureFlags.shared.isDisabled(.learning) {
                comingSoonView
            } else if let viewModel = viewModel {
                LearnContentView(viewModel: viewModel)
            } else {
                LoadingView(message: "Loading lessons...")
            }
        }
        .navigationTitle("Learn")
        .navigationBarTitleDisplayMode(.large)
        .task {
            if viewModel == nil && FeatureFlags.shared.isEnabled(.learning) {
                viewModel = LearnViewModel(
                    learningRepository: dependencies.learningRepository,
                    userState: dependencies.userState
                )
            }
        }
    }

    private var comingSoonView: some View {
        VStack(spacing: SafaSpacing.lg) {
            Spacer()

            Image(systemName: "graduationcap.fill")
                .font(.system(size: 60))
                .foregroundColor(.accentColor.opacity(0.3))

            Text("Learn")
                .font(SafaTypography.headlineMedium)
                .foregroundColor(SafaColors.Fallback.text)

            Text(String(localized: "Arabic, Tajweed, and Islamic studies lessons are coming soon."))
                .font(SafaTypography.bodyMedium)
                .foregroundColor(SafaColors.Fallback.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, SafaSpacing.xl)

            Text("Coming Soon")
                .font(SafaTypography.labelMedium)
                .foregroundColor(.secondary)
                .padding(.horizontal, SafaSpacing.md)
                .padding(.vertical, SafaSpacing.xs)
                .background(Color.gray.opacity(0.2))
                .clipShape(Capsule())

            Spacer()
        }
    }
}

// MARK: - Learn Content View

private struct LearnContentView: View {
    @Bindable var viewModel: LearnViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: SafaSpacing.lg) {
                // Progress overview
                progressOverview

                // Learning tracks
                ForEach(viewModel.tracks) { track in
                    TrackCard(
                        track: track,
                        progress: viewModel.getProgress(for: track.id)
                    ) {
                        viewModel.selectedTrack = track
                    }
                }

                // Daily recommendation
                if let nextLesson = viewModel.nextLesson {
                    recommendedLessonCard(nextLesson)
                }
            }
            .padding()
        }
        .navigationTitle("Learn")
        .navigationBarTitleDisplayMode(.large)
        .sheet(item: $viewModel.selectedTrack) { track in
            NavigationStack {
                TrackDetailView(
                    track: track,
                    viewModel: viewModel
                )
            }
            .fullSheet()
        }
        .task {
            await viewModel.loadTracks()
        }
    }

    // MARK: - Progress Overview

    private var progressOverview: some View {
        ContentCard {
            VStack(spacing: SafaSpacing.md) {
                HStack {
                    VStack(alignment: .leading) {
                        Text("Your Progress")
                            .font(SafaTypography.titleMedium)
                        Text("\(viewModel.overallProgress.totalLessonsCompleted) lessons completed")
                            .font(SafaTypography.bodySmall)
                            .foregroundColor(SafaColors.Fallback.secondaryText)
                    }

                    Spacer()

                    // Streak
                    VStack {
                        Text("\(viewModel.overallProgress.currentStreak)")
                            .font(SafaTypography.headlineLarge)
                            .foregroundColor(.accentColor)
                        Text("day streak")
                            .font(SafaTypography.labelSmall)
                            .foregroundColor(SafaColors.Fallback.secondaryText)
                    }
                }

                // Progress bars for each track
                HStack(spacing: SafaSpacing.xs) {
                    ForEach(viewModel.tracks) { track in
                        let progress = viewModel.getProgress(for: track.id)
                        VStack(spacing: SafaSpacing.xxs) {
                            ProgressView(value: progress.completionPercentage / 100)
                                .tint(.accentColor)

                            Text(track.titleEnglish.prefix(8))
                                .font(SafaTypography.labelSmall)
                                .foregroundColor(SafaColors.Fallback.tertiaryText)
                                .lineLimit(1)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Recommended Lesson

    private func recommendedLessonCard(_ lesson: Lesson) -> some View {
        TitledCard(title: "Continue Learning", subtitle: "Recommended for you") {
            Button {
                viewModel.startLesson(lesson)
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: SafaSpacing.xxs) {
                        Text(lesson.titleEnglish)
                            .font(SafaTypography.bodyLarge)
                            .foregroundColor(SafaColors.Fallback.text)

                        Text("\(lesson.durationMinutes) min • \(lesson.type.rawValue.capitalized)")
                            .font(SafaTypography.labelSmall)
                            .foregroundColor(SafaColors.Fallback.secondaryText)
                    }

                    Spacer()

                    Image(systemName: "play.circle.fill")
                        .font(.system(size: 36))
                        .foregroundColor(.accentColor)
                }
            }
        }
    }
}

// MARK: - Track Card

private struct TrackCard: View {
    let track: LearningTrack
    let progress: TrackProgress
    let action: () -> Void

    var body: some View {
        InteractiveCard(action: action) {
            HStack(spacing: SafaSpacing.md) {
                // Icon
                Image(systemName: track.iconName)
                    .font(.system(size: 28))
                    .foregroundColor(.accentColor)
                    .frame(width: 50, height: 50)
                    .background(Color.accentColor.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                // Info
                VStack(alignment: .leading, spacing: SafaSpacing.xxs) {
                    Text(track.titleEnglish)
                        .font(SafaTypography.titleMedium)
                        .foregroundColor(SafaColors.Fallback.text)

                    Text(track.description)
                        .font(SafaTypography.bodySmall)
                        .foregroundColor(SafaColors.Fallback.secondaryText)
                        .lineLimit(2)

                    // Progress
                    HStack(spacing: SafaSpacing.xs) {
                        ProgressView(value: progress.completionPercentage / 100)
                            .tint(.accentColor)
                            .frame(width: 80)

                        Text("\(progress.completedLessons)/\(progress.totalLessons)")
                            .font(SafaTypography.labelSmall)
                            .foregroundColor(SafaColors.Fallback.tertiaryText)
                    }
                }

                Spacer()

                Image(systemName: "chevron.forward")
                    .foregroundColor(SafaColors.Fallback.tertiaryText)
            }
        }
    }
}

// MARK: - Track Detail View

private struct TrackDetailView: View {
    let track: LearningTrack
    @Bindable var viewModel: LearnViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(spacing: SafaSpacing.lg) {
                // Track header
                trackHeader

                // Lessons
                LazyVStack(spacing: SafaSpacing.sm) {
                    ForEach(viewModel.getLessons(for: track.id)) { lesson in
                        LessonRow(lesson: lesson) {
                            viewModel.startLesson(lesson)
                        }
                    }
                }
            }
            .padding()
        }
        .navigationTitle(track.titleEnglish)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Done") {
                    dismiss()
                }
            }
        }
        .task {
            await viewModel.loadLessons(for: track.id)
        }
    }

    private var trackHeader: some View {
        ContentCard {
            VStack(spacing: SafaSpacing.md) {
                Image(systemName: track.iconName)
                    .font(.system(size: 48))
                    .foregroundColor(.accentColor)

                if let arabic = track.titleArabic {
                    Text(arabic)
                        .font(SafaTypography.arabicMedium)
                }

                Text(track.description)
                    .font(SafaTypography.bodyMedium)
                    .foregroundColor(SafaColors.Fallback.secondaryText)
                    .multilineTextAlignment(.center)

                HStack(spacing: SafaSpacing.lg) {
                    Label("\(track.lessonCount) lessons", systemImage: "book")
                    Label("~\(track.estimatedMinutes) min", systemImage: "clock")
                }
                .font(SafaTypography.labelSmall)
                .foregroundColor(SafaColors.Fallback.tertiaryText)
            }
        }
    }
}

// MARK: - Lesson Row

private struct LessonRow: View {
    let lesson: Lesson
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: SafaSpacing.md) {
                // Status indicator
                ZStack {
                    Circle()
                        .stroke(lesson.isCompleted ? Color.green : Color.gray.opacity(0.3), lineWidth: 2)
                        .frame(width: 32, height: 32)

                    if lesson.isCompleted {
                        Image(systemName: "checkmark")
                            .foregroundColor(.green)
                    } else {
                        Text("\(lesson.order)")
                            .font(SafaTypography.labelMedium)
                            .foregroundColor(SafaColors.Fallback.secondaryText)
                    }
                }

                // Lesson info
                VStack(alignment: .leading, spacing: SafaSpacing.xxs) {
                    Text(lesson.titleEnglish)
                        .font(SafaTypography.bodyLarge)
                        .foregroundColor(SafaColors.Fallback.text)

                    HStack(spacing: SafaSpacing.xs) {
                        Label("\(lesson.durationMinutes) min", systemImage: "clock")
                        Text("•")
                        Label(lesson.type.rawValue.capitalized, systemImage: lessonTypeIcon)
                    }
                    .font(SafaTypography.labelSmall)
                    .foregroundColor(SafaColors.Fallback.secondaryText)
                }

                Spacer()

                // Score if completed
                if let score = lesson.bestScore {
                    Text("\(score)%")
                        .font(SafaTypography.labelMedium)
                        .foregroundColor(score >= 80 ? .green : .orange)
                        .padding(.horizontal, SafaSpacing.xs)
                        .padding(.vertical, SafaSpacing.xxs)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill((score >= 80 ? Color.green : Color.orange).opacity(0.1))
                        )
                }

                Image(systemName: "chevron.forward")
                    .foregroundColor(SafaColors.Fallback.tertiaryText)
            }
            .padding(SafaSpacing.md)
            .background(Color(UIColor.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: SafaSpacing.CornerRadius.md))
        }
        .buttonStyle(.plain)
    }

    private var lessonTypeIcon: String {
        switch lesson.type {
        case .reading: return "book"
        case .listening: return "headphones"
        case .quiz: return "questionmark.circle"
        case .practice: return "pencil"
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        LearnView()
            .environment(Dependencies())
    }
}
