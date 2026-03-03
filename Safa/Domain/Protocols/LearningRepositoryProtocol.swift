// MARK: - LearningRepositoryProtocol.swift
// PURPOSE: Defines contract for learning tracks, lessons, and progress

import Foundation

protocol LearningRepositoryProtocol {
    /// Fetches all learning tracks
    /// - Returns: Array of learning tracks
    func getTracks() async throws -> [LearningTrack]

    /// Fetches a specific track
    /// - Parameter trackId: The track identifier
    /// - Returns: The track if found
    func getTrack(id trackId: String) async throws -> LearningTrack?

    /// Fetches lessons for a track
    /// - Parameter trackId: The track identifier
    /// - Returns: Array of lessons
    func getLessons(forTrack trackId: String) async throws -> [Lesson]

    /// Fetches a specific lesson
    /// - Parameters:
    ///   - trackId: The track identifier
    ///   - lessonId: The lesson identifier
    /// - Returns: The lesson if found
    func getLesson(trackId: String, lessonId: String) async throws -> Lesson?

    /// Gets lesson content (exercises, audio, etc.)
    /// - Parameter lessonId: The lesson identifier
    /// - Returns: The lesson content
    func getLessonContent(lessonId: String) async throws -> LessonContent?

    /// Marks a lesson as complete
    /// - Parameters:
    ///   - lessonId: The lesson identifier
    ///   - score: The score achieved (0-100)
    func markLessonComplete(lessonId: String, score: Int) async throws

    /// Gets progress for a track
    /// - Parameter trackId: The track identifier
    /// - Returns: Progress information
    func getTrackProgress(trackId: String) async throws -> TrackProgress

    /// Gets overall learning progress
    /// - Returns: Total lessons completed, tracks completed
    func getOverallProgress() async throws -> LearningProgress

    /// Gets next recommended lesson
    /// - Returns: The next lesson to study
    func getNextLesson() async throws -> Lesson?
}
