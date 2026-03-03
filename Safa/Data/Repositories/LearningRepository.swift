// MARK: - LearningRepository.swift
// PURPOSE: Implementation of learning tracks, lessons, and progress
// DEPENDENCIES: CoreData, LearningRepositoryProtocol

import Foundation
import CoreData

final class LearningRepository: LearningRepositoryProtocol {
    // MARK: - Dependencies
    private let coreData: CoreDataStack

    // MARK: - Storage Keys
    private let progressKey = AppConstants.StorageKeys.learningProgress
    private let completedLessonsKey = AppConstants.StorageKeys.learningCompleted

    // MARK: - Init
    init(coreData: CoreDataStack) {
        self.coreData = coreData
    }

    // MARK: - Tracks

    func getTracks() async throws -> [LearningTrack] {
        return LearningTrack.allTracks
    }

    func getTrack(id trackId: String) async throws -> LearningTrack? {
        return LearningTrack.allTracks.first { $0.id == trackId }
    }

    // MARK: - Lessons

    func getLessons(forTrack trackId: String) async throws -> [Lesson] {
        // TODO: Load from bundled JSON
        let completedIds = getCompletedLessonIds()

        switch trackId {
        case "arabic_foundations":
            return Lesson.arabicFoundationsLessons.map { lesson in
                var updated = lesson
                updated.isCompleted = completedIds.contains(lesson.id)
                return updated
            }
        case "tajweed":
            return Lesson.tajweedLessons.map { lesson in
                var updated = lesson
                updated.isCompleted = completedIds.contains(lesson.id)
                return updated
            }
        default:
            return []
        }
    }

    func getLesson(trackId: String, lessonId: String) async throws -> Lesson? {
        let lessons = try await getLessons(forTrack: trackId)
        return lessons.first { $0.id == lessonId }
    }

    func getLessonContent(lessonId: String) async throws -> LessonContent? {
        // TODO: Load from bundled JSON
        return LessonContent.sampleContent[lessonId]
    }

    func markLessonComplete(lessonId: String, score: Int) async throws {
        var completedIds = getCompletedLessonIds()
        guard !completedIds.contains(lessonId) else { return }
        completedIds.append(lessonId)
        UserDefaults.standard.set(completedIds, forKey: completedLessonsKey)

        // Update progress
        var progress = try await getOverallProgress()
        progress.totalLessonsCompleted += 1
        try await saveOverallProgress(progress)
    }

    // MARK: - Progress

    func getTrackProgress(trackId: String) async throws -> TrackProgress {
        let lessons = try await getLessons(forTrack: trackId)
        let completedLessons = lessons.filter { $0.isCompleted }

        let scores = completedLessons.compactMap { $0.bestScore }
        let averageScore = scores.isEmpty ? nil : Double(scores.reduce(0, +)) / Double(scores.count)

        return TrackProgress(
            trackId: trackId,
            completedLessons: completedLessons.count,
            totalLessons: lessons.count,
            averageScore: averageScore,
            lastLessonId: completedLessons.last?.id,
            lastActivityDate: Date()
        )
    }

    func getOverallProgress() async throws -> LearningProgress {
        guard let data = UserDefaults.standard.data(forKey: progressKey),
              let progress = try? JSONDecoder().decode(LearningProgress.self, from: data) else {
            return LearningProgress(
                totalLessonsCompleted: 0,
                totalTracksCompleted: 0,
                totalMinutesLearned: 0,
                currentStreak: 0
            )
        }
        return progress
    }

    func getNextLesson() async throws -> Lesson? {
        for track in LearningTrack.allTracks {
            let lessons = try await getLessons(forTrack: track.id)
            if let nextIncomplete = lessons.first(where: { !$0.isCompleted }) {
                return nextIncomplete
            }
        }
        return nil
    }

    // MARK: - Private Helpers

    private func getCompletedLessonIds() -> [String] {
        UserDefaults.standard.stringArray(forKey: completedLessonsKey) ?? []
    }

    private func saveOverallProgress(_ progress: LearningProgress) async throws {
        let data = try JSONEncoder().encode(progress)
        UserDefaults.standard.set(data, forKey: progressKey)
    }
}

// MARK: - Sample Lesson Data

extension Lesson {
    static let arabicFoundationsLessons: [Lesson] = [
        Lesson(id: "arabic_1", trackId: "arabic_foundations", order: 1, titleEnglish: "Alif - ا", description: "Learn the first letter of the Arabic alphabet", durationMinutes: 5, type: .practice),
        Lesson(id: "arabic_2", trackId: "arabic_foundations", order: 2, titleEnglish: "Ba - ب", description: "Learn the letter Ba and its sounds", durationMinutes: 5, type: .practice),
        Lesson(id: "arabic_3", trackId: "arabic_foundations", order: 3, titleEnglish: "Ta - ت", description: "Learn the letter Ta and its sounds", durationMinutes: 5, type: .practice),
        Lesson(id: "arabic_4", trackId: "arabic_foundations", order: 4, titleEnglish: "Tha - ث", description: "Learn the letter Tha and its unique sound", durationMinutes: 5, type: .practice),
        Lesson(id: "arabic_5", trackId: "arabic_foundations", order: 5, titleEnglish: "Jeem - ج", description: "Learn the letter Jeem", durationMinutes: 5, type: .practice),
        Lesson(id: "arabic_6", trackId: "arabic_foundations", order: 6, titleEnglish: "Ha - ح", description: "Learn the letter Ha and its throaty sound", durationMinutes: 5, type: .practice),
        Lesson(id: "arabic_7", trackId: "arabic_foundations", order: 7, titleEnglish: "Kha - خ", description: "Learn the letter Kha", durationMinutes: 5, type: .practice),
        Lesson(id: "arabic_8", trackId: "arabic_foundations", order: 8, titleEnglish: "Dal - د", description: "Learn the letter Dal", durationMinutes: 5, type: .practice),
        // Abbreviated - full set would have 28 lessons
    ]

    static let tajweedLessons: [Lesson] = [
        Lesson(id: "tajweed_1", trackId: "tajweed", order: 1, titleEnglish: "Introduction to Tajweed", description: "Understanding the importance and basics of Tajweed", durationMinutes: 10, type: .reading),
        Lesson(id: "tajweed_2", trackId: "tajweed", order: 2, titleEnglish: "Makharij al-Huruf", description: "Points of articulation for Arabic letters", durationMinutes: 15, type: .reading),
        Lesson(id: "tajweed_3", trackId: "tajweed", order: 3, titleEnglish: "Noon Sakinah Rules", titleArabic: "أحكام النون الساكنة", description: "Learn the four rules of Noon Sakinah and Tanween", durationMinutes: 20, type: .reading),
        Lesson(id: "tajweed_4", trackId: "tajweed", order: 4, titleEnglish: "Ikhfa", titleArabic: "الإخفاء", description: "Practice the rule of concealment", durationMinutes: 15, type: .practice),
        Lesson(id: "tajweed_5", trackId: "tajweed", order: 5, titleEnglish: "Idgham", titleArabic: "الإدغام", description: "Practice the rule of merging", durationMinutes: 15, type: .practice),
    ]
}

extension LessonContent {
    static let sampleContent: [String: LessonContent] = [
        "arabic_1": LessonContent(
            lessonId: "arabic_1",
            sections: [
                LessonContent.LessonSection(
                    id: "arabic_1_intro",
                    type: .text,
                    content: .text("Alif (ا) is the first letter of the Arabic alphabet. It represents a glottal stop or a long 'a' sound.")
                ),
                LessonContent.LessonSection(
                    id: "arabic_1_audio",
                    type: .audio,
                    content: .audio(LessonContent.AudioContent(
                        audioFileName: "alif.mp3",
                        arabicText: "ا",
                        transliteration: "Alif",
                        translation: "Alif"
                    ))
                ),
            ]
        ),
    ]
}
