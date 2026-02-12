// MARK: - PlaceholderViews.swift
// PURPOSE: Temporary placeholder views for features not yet fully implemented
// DEPENDENCIES: SwiftUI

import SwiftUI

// MARK: - Surah Detail Placeholder

struct SurahDetailView: View {
    let surahNumber: Int

    var body: some View {
        Text("Surah \(surahNumber)")
            .navigationTitle("Surah")
    }
}

// MARK: - Lesson Detail Placeholder

struct LessonDetailView: View {
    let trackId: String
    let lessonId: String

    var body: some View {
        Text("Lesson: \(trackId)/\(lessonId)")
            .navigationTitle("Lesson")
    }
}
