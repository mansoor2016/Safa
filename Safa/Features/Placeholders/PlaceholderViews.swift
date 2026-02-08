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

// MARK: - Family View Placeholder

struct FamilyView: View {
    var body: some View {
        VStack(spacing: SafaSpacing.lg) {
            Image(systemName: "person.3.fill")
                .font(.system(size: 60))
                .foregroundColor(.blue)

            Text("Family Circle")
                .font(SafaTypography.headlineMedium)

            Text("Share your spiritual journey with family members.")
                .font(SafaTypography.bodyMedium)
                .foregroundColor(SafaColors.Fallback.secondaryText)
                .multilineTextAlignment(.center)

            Button("Invite Family Member") {
                // Invite action
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .navigationTitle("Family")
    }
}
