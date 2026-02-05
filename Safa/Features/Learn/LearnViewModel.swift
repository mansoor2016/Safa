// MARK: - LearnViewModel.swift
// PURPOSE: ViewModel for learning feature
// DEPENDENCIES: Foundation, LearningRepository

import Foundation

@Observable
final class LearnViewModel {
    // MARK: - State
    var tracks: [LearningTrack] = []
    var lessonsByTrack: [String: [Lesson]] = [:]
    var trackProgress: [String: TrackProgress] = [:]
    var overallProgress = LearningProgress(
        totalLessonsCompleted: 0,
        totalTracksCompleted: 0,
        totalMinutesLearned: 0,
        currentStreak: 0,
        pronunciationAttempts: 0,
        averagePronunciationScore: nil
    )
    var nextLesson: Lesson?
    var selectedTrack: LearningTrack?
    var selectedLesson: Lesson?
    var isLoading = false
    var error: Error?

    // MARK: - Dependencies
    private let learningRepository: LearningRepositoryProtocol
    private let userState: UserStateManager

    // MARK: - Init
    init(learningRepository: LearningRepositoryProtocol, userState: UserStateManager) {
        self.learningRepository = learningRepository
        self.userState = userState
    }

    // MARK: - Load Methods

    func loadTracks() async {
        guard tracks.isEmpty else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            tracks = try await learningRepository.getTracks()
            overallProgress = try await learningRepository.getOverallProgress()
            nextLesson = try await learningRepository.getNextLesson()

            // Load progress for each track
            for track in tracks {
                let progress = try await learningRepository.getTrackProgress(trackId: track.id)
                trackProgress[track.id] = progress
            }
        } catch {
            self.error = error
        }
    }

    func loadLessons(for trackId: String) async {
        guard lessonsByTrack[trackId] == nil else { return }

        do {
            let lessons = try await learningRepository.getLessons(forTrack: trackId)
            lessonsByTrack[trackId] = lessons
        } catch {
            self.error = error
        }
    }

    // MARK: - Progress

    func getProgress(for trackId: String) -> TrackProgress {
        trackProgress[trackId] ?? TrackProgress(
            trackId: trackId,
            completedLessons: 0,
            totalLessons: tracks.first { $0.id == trackId }?.lessonCount ?? 0
        )
    }

    func getLessons(for trackId: String) -> [Lesson] {
        lessonsByTrack[trackId] ?? []
    }

    // MARK: - Lesson Actions

    func startLesson(_ lesson: Lesson) {
        selectedLesson = lesson
    }

    func completeLesson(_ lesson: Lesson, score: Int) async {
        do {
            try await learningRepository.markLessonComplete(lessonId: lesson.id, score: score)

            // Update local state
            if var lessons = lessonsByTrack[lesson.trackId] {
                if let index = lessons.firstIndex(where: { $0.id == lesson.id }) {
                    lessons[index].isCompleted = true
                    lessons[index].bestScore = max(lessons[index].bestScore ?? 0, score)
                    lessonsByTrack[lesson.trackId] = lessons
                }
            }

            // Update track progress
            let progress = try await learningRepository.getTrackProgress(trackId: lesson.trackId)
            trackProgress[lesson.trackId] = progress

            // Update overall progress
            overallProgress = try await learningRepository.getOverallProgress()

            // Award Hasanat
            await userState.awardHasanat(.lessonComplete)
            if score >= 90 {
                await userState.awardHasanat(.lessonPerfect)
            }

            // Update learning streak
            await userState.recordActivity(type: .learning)

            // Get next lesson
            nextLesson = try await learningRepository.getNextLesson()

        } catch {
            self.error = error
        }
    }

    func recordPronunciation(lessonId: String, score: Int) async {
        do {
            try await learningRepository.recordPronunciationAttempt(lessonId: lessonId, score: score)

            if score >= 70 {
                await userState.awardHasanat(.pronunciationPass)
            }
        } catch {
            self.error = error
        }
    }
}
