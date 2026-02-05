// MARK: - LessonContentView.swift
// PURPOSE: Interactive lesson content display with exercises
// DEPENDENCIES: SwiftUI

import SwiftUI

struct LessonContentView: View {
    @Environment(Dependencies.self) private var dependencies
    @Environment(\.dismiss) private var dismiss

    let lesson: Lesson
    let trackId: String

    @State private var currentStep = 0
    @State private var score = 0
    @State private var showResult = false
    @State private var answers: [String: String] = [:]
    @State private var isComplete = false

    var body: some View {
        VStack(spacing: 0) {
            // Progress bar
            progressBar

            // Content
            TabView(selection: $currentStep) {
                ForEach(Array(lesson.content.enumerated()), id: \.offset) { index, step in
                    LessonStepView(
                        step: step,
                        answer: binding(for: step.id),
                        onNext: { advanceStep() }
                    )
                    .tag(index)
                }

                // Completion view
                completionView
                    .tag(lesson.content.count)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut, value: currentStep)
        }
        .navigationTitle(lesson.titleEnglish)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Exit") {
                    dismiss()
                }
            }
        }
        .interactiveDismissDisabled()
    }

    // MARK: - Progress Bar

    private var progressBar: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))

                Rectangle()
                    .fill(Color.accentColor)
                    .frame(width: geometry.size.width * progress)
                    .animation(.easeInOut, value: progress)
            }
        }
        .frame(height: 4)
    }

    private var progress: CGFloat {
        CGFloat(currentStep) / CGFloat(lesson.content.count)
    }

    // MARK: - Completion View

    private var completionView: some View {
        VStack(spacing: SafaSpacing.xl) {
            Spacer()

            // Result icon
            ZStack {
                Circle()
                    .fill(resultColor.opacity(0.1))
                    .frame(width: 120, height: 120)

                Image(systemName: resultIcon)
                    .font(.system(size: 60))
                    .foregroundColor(resultColor)
            }

            // Score
            VStack(spacing: SafaSpacing.sm) {
                Text("Lesson Complete!")
                    .font(SafaTypography.headlineMedium)

                Text("\(score)/\(totalQuestions) Correct")
                    .font(SafaTypography.titleLarge)
                    .foregroundColor(resultColor)

                Text(resultMessage)
                    .font(SafaTypography.bodyMedium)
                    .foregroundColor(SafaColors.Fallback.secondaryText)
                    .multilineTextAlignment(.center)
            }

            // Hasanat earned
            if score > 0 {
                HStack {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                    Text("+\(hasanatEarned) Hasanat")
                        .font(SafaTypography.bodyLarge)
                        .foregroundColor(.accentColor)
                }
                .padding()
                .background(Color.accentColor.opacity(0.1))
                .clipShape(Capsule())
            }

            Spacer()

            // Action buttons
            VStack(spacing: SafaSpacing.sm) {
                PrimaryButton(title: "Continue", action: {
                    completeLesson()
                })

                if score < totalQuestions {
                    SecondaryButton(title: "Try Again", action: {
                        resetLesson()
                    })
                }
            }
        }
        .padding()
    }

    private var totalQuestions: Int {
        lesson.content.filter { step in
            step.type == .quiz || step.type == .exercise
        }.count
    }

    private var resultColor: Color {
        let percentage = Double(score) / Double(max(totalQuestions, 1))
        if percentage >= 0.8 { return .green }
        if percentage >= 0.6 { return .orange }
        return .red
    }

    private var resultIcon: String {
        let percentage = Double(score) / Double(max(totalQuestions, 1))
        if percentage >= 0.8 { return "checkmark.circle.fill" }
        if percentage >= 0.6 { return "exclamationmark.circle.fill" }
        return "xmark.circle.fill"
    }

    private var resultMessage: String {
        let percentage = Double(score) / Double(max(totalQuestions, 1))
        if percentage >= 0.8 { return "Excellent work! You've mastered this lesson." }
        if percentage >= 0.6 { return "Good effort! Review the material for better results." }
        return "Keep practicing! Consider reviewing this lesson again."
    }

    private var hasanatEarned: Int {
        let base = HasanatAward.lessonComplete.points
        let bonus = score == totalQuestions ? HasanatAward.lessonPerfect.points : 0
        return base + bonus
    }

    // MARK: - Methods

    private func binding(for id: String) -> Binding<String> {
        Binding(
            get: { answers[id] ?? "" },
            set: { answers[id] = $0 }
        )
    }

    private func advanceStep() {
        if currentStep < lesson.content.count {
            // Check if current step was a quiz
            let step = lesson.content[currentStep]
            if step.type == .quiz || step.type == .exercise {
                if let answer = answers[step.id],
                   answer.lowercased() == step.correctAnswer?.lowercased() {
                    score += 1
                }
            }

            withAnimation {
                currentStep += 1
            }
        }
    }

    private func completeLesson() {
        Task {
            // Mark lesson complete
            let scorePercent = Int(Double(score) / Double(max(totalQuestions, 1)) * 100)
            try? await dependencies.learningRepository.markLessonComplete(
                lessonId: lesson.id,
                score: scorePercent
            )

            // Award Hasanat
            await dependencies.userState.awardHasanat(.lessonComplete)
            if score == totalQuestions && totalQuestions > 0 {
                await dependencies.userState.awardHasanat(.lessonPerfect)
            }

            // Record activity
            await dependencies.userState.recordActivity(type: .learning)

            dismiss()
        }
    }

    private func resetLesson() {
        withAnimation {
            currentStep = 0
            score = 0
            answers = [:]
        }
    }
}

// MARK: - Lesson Step View

private struct LessonStepView: View {
    let step: LessonStep
    @Binding var answer: String
    let onNext: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: SafaSpacing.lg) {
                switch step.type {
                case .reading:
                    readingContent
                case .listening:
                    listeningContent
                case .pronunciation:
                    pronunciationContent
                case .quiz:
                    quizContent
                case .exercise:
                    exerciseContent
                }

                Spacer(minLength: 100)
            }
            .padding()
        }
        .safeAreaInset(edge: .bottom) {
            PrimaryButton(title: step.type == .quiz ? "Check Answer" : "Continue") {
                onNext()
            }
            .padding()
            .background(Color(UIColor.systemBackground))
        }
    }

    // MARK: - Reading Content

    private var readingContent: some View {
        VStack(alignment: .leading, spacing: SafaSpacing.lg) {
            if let title = step.title {
                Text(title)
                    .font(SafaTypography.headlineMedium)
            }

            if let arabic = step.arabicText {
                Text(arabic)
                    .font(SafaTypography.arabicLarge)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .environment(\.layoutDirection, .rightToLeft)
                    .padding()
                    .background(Color.accentColor.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: SafaSpacing.CornerRadius.md))
            }

            if let body = step.body {
                Text(body)
                    .font(SafaTypography.bodyLarge)
                    .foregroundColor(SafaColors.Fallback.text)
            }

            if let image = step.imageName {
                Image(image)
                    .resizable()
                    .scaledToFit()
                    .clipShape(RoundedRectangle(cornerRadius: SafaSpacing.CornerRadius.md))
            }
        }
    }

    // MARK: - Listening Content

    private var listeningContent: some View {
        VStack(spacing: SafaSpacing.lg) {
            if let title = step.title {
                Text(title)
                    .font(SafaTypography.headlineMedium)
            }

            if let arabic = step.arabicText {
                Text(arabic)
                    .font(SafaTypography.arabicLarge)
                    .padding()
            }

            // Audio player
            LessonAudioPlayerView(audioFileName: step.audioFileName ?? "")

            if let body = step.body {
                Text(body)
                    .font(SafaTypography.bodyMedium)
                    .foregroundColor(SafaColors.Fallback.secondaryText)
            }
        }
    }

    // MARK: - Pronunciation Content

    private var pronunciationContent: some View {
        VStack(spacing: SafaSpacing.lg) {
            if let title = step.title {
                Text(title)
                    .font(SafaTypography.headlineMedium)
            }

            if let arabic = step.arabicText {
                Text(arabic)
                    .font(SafaTypography.arabicLarge)
                    .padding()
            }

            // Record button
            Button {
                // Start recording
            } label: {
                VStack(spacing: SafaSpacing.sm) {
                    Image(systemName: "mic.circle.fill")
                        .font(.system(size: 64))
                        .foregroundColor(.accentColor)

                    Text("Tap to Record")
                        .font(SafaTypography.bodyMedium)
                        .foregroundColor(SafaColors.Fallback.secondaryText)
                }
            }
            .padding()

            if let body = step.body {
                Text(body)
                    .font(SafaTypography.bodyMedium)
                    .foregroundColor(SafaColors.Fallback.secondaryText)
            }
        }
    }

    // MARK: - Quiz Content

    private var quizContent: some View {
        VStack(alignment: .leading, spacing: SafaSpacing.lg) {
            if let title = step.title {
                Text(title)
                    .font(SafaTypography.headlineMedium)
            }

            if let options = step.options {
                VStack(spacing: SafaSpacing.sm) {
                    ForEach(options, id: \.self) { option in
                        Button {
                            answer = option
                        } label: {
                            HStack {
                                Text(option)
                                    .font(SafaTypography.bodyLarge)
                                    .foregroundColor(SafaColors.Fallback.text)

                                Spacer()

                                if answer == option {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.accentColor)
                                } else {
                                    Image(systemName: "circle")
                                        .foregroundColor(SafaColors.Fallback.tertiaryText)
                                }
                            }
                            .padding()
                            .background(answer == option ? Color.accentColor.opacity(0.1) : Color(UIColor.secondarySystemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: SafaSpacing.CornerRadius.md))
                        }
                    }
                }
            }
        }
    }

    // MARK: - Exercise Content

    private var exerciseContent: some View {
        VStack(alignment: .leading, spacing: SafaSpacing.lg) {
            if let title = step.title {
                Text(title)
                    .font(SafaTypography.headlineMedium)
            }

            if let body = step.body {
                Text(body)
                    .font(SafaTypography.bodyLarge)
            }

            TextField("Your answer...", text: $answer)
                .textFieldStyle(.roundedBorder)
                .font(SafaTypography.bodyLarge)
        }
    }
}

// MARK: - Lesson Audio Player View

private struct LessonAudioPlayerView: View {
    let audioFileName: String
    @State private var isPlaying = false
    @State private var progress: Double = 0

    var body: some View {
        VStack(spacing: SafaSpacing.md) {
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.gray.opacity(0.2))

                    Capsule()
                        .fill(Color.accentColor)
                        .frame(width: geometry.size.width * progress)
                }
            }
            .frame(height: 6)

            // Controls
            HStack(spacing: SafaSpacing.xl) {
                Button {
                    // Rewind
                } label: {
                    Image(systemName: "gobackward.10")
                        .font(.title2)
                        .foregroundColor(SafaColors.Fallback.secondaryText)
                }

                Button {
                    isPlaying.toggle()
                } label: {
                    Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 56))
                        .foregroundColor(.accentColor)
                }

                Button {
                    // Forward
                } label: {
                    Image(systemName: "goforward.10")
                        .font(.title2)
                        .foregroundColor(SafaColors.Fallback.secondaryText)
                }
            }

            // Speed control
            HStack {
                Text("0.5x")
                    .font(SafaTypography.labelSmall)
                    .foregroundColor(SafaColors.Fallback.tertiaryText)

                Spacer()

                Text("1x")
                    .font(SafaTypography.labelSmall)
                    .foregroundColor(.accentColor)
                    .padding(.horizontal, SafaSpacing.xs)
                    .padding(.vertical, 2)
                    .background(Color.accentColor.opacity(0.1))
                    .clipShape(Capsule())

                Spacer()

                Text("1.5x")
                    .font(SafaTypography.labelSmall)
                    .foregroundColor(SafaColors.Fallback.tertiaryText)
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: SafaSpacing.CornerRadius.lg))
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        LessonContentView(
            lesson: Lesson(
                id: "preview",
                trackId: "arabic",
                order: 1,
                titleEnglish: "Arabic Alphabet",
                titleArabic: "الأبجدية العربية",
                durationMinutes: 10,
                type: .reading,
                content: [
                    LessonStep(
                        id: "1",
                        type: .reading,
                        title: "Introduction",
                        body: "Welcome to Arabic! Let's learn the alphabet."
                    )
                ]
            ),
            trackId: "arabic"
        )
        .environment(Dependencies())
    }
}
