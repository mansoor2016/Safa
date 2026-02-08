// MARK: - Learning.swift
// PURPOSE: Domain entities for learning tracks, lessons, and progress

import Foundation

// MARK: - Learning Track
struct LearningTrack: Identifiable, Codable, Hashable {
    let id: String
    let titleEnglish: String
    let titleArabic: String?
    let description: String
    let iconName: String
    let lessonCount: Int
    let estimatedMinutes: Int

    static let arabicFoundations = LearningTrack(
        id: "arabic_foundations",
        titleEnglish: "Arabic Foundations",
        titleArabic: "أساسيات العربية",
        description: "Learn the Arabic alphabet and basic pronunciation",
        iconName: "textformat.abc",
        lessonCount: 28,
        estimatedMinutes: 120
    )

    static let tajweed = LearningTrack(
        id: "tajweed",
        titleEnglish: "Tajweed Rules",
        titleArabic: "أحكام التجويد",
        description: "Master the rules of Quranic recitation",
        iconName: "waveform",
        lessonCount: 20,
        estimatedMinutes: 180
    )

    static let quranRecitation = LearningTrack(
        id: "quran_recitation",
        titleEnglish: "Quran Recitation",
        titleArabic: "تلاوة القرآن",
        description: "Practice reciting the Quran with feedback",
        iconName: "book",
        lessonCount: 30,
        estimatedMinutes: 300
    )

    static let dhikrMastery = LearningTrack(
        id: "dhikr_mastery",
        titleEnglish: "Dhikr & Dua Mastery",
        titleArabic: "إتقان الذكر والدعاء",
        description: "Learn proper pronunciation of common dhikr and duas",
        iconName: "heart",
        lessonCount: 15,
        estimatedMinutes: 90
    )

    static let allTracks: [LearningTrack] = [
        .arabicFoundations,
        .tajweed,
        .quranRecitation,
        .dhikrMastery
    ]
}

// MARK: - Lesson
struct Lesson: Identifiable, Codable, Hashable {
    let id: String
    let trackId: String
    let order: Int
    let titleEnglish: String
    let titleArabic: String?
    let description: String
    let durationMinutes: Int
    let type: LessonType
    var isCompleted: Bool
    var bestScore: Int?
    var content: [LessonStep]

    enum LessonType: String, Codable {
        case reading
        case listening
        case pronunciation
        case quiz
        case practice
    }

    init(
        id: String,
        trackId: String,
        order: Int,
        titleEnglish: String,
        titleArabic: String? = nil,
        description: String = "",
        durationMinutes: Int,
        type: LessonType,
        isCompleted: Bool = false,
        bestScore: Int? = nil,
        content: [LessonStep] = []
    ) {
        self.id = id
        self.trackId = trackId
        self.order = order
        self.titleEnglish = titleEnglish
        self.titleArabic = titleArabic
        self.description = description
        self.durationMinutes = durationMinutes
        self.type = type
        self.isCompleted = isCompleted
        self.bestScore = bestScore
        self.content = content
    }
}

// MARK: - Lesson Step (simplified content structure)
struct LessonStep: Identifiable, Codable, Hashable {
    let id: String
    let type: StepType
    var title: String?
    var body: String?
    var arabicText: String?
    var transliteration: String?
    var audioFileName: String?
    var imageName: String?
    var options: [String]?
    var correctAnswer: String?
    var explanation: String?

    enum StepType: String, Codable {
        case reading
        case listening
        case pronunciation
        case quiz
        case exercise
    }

    init(
        id: String = UUID().uuidString,
        type: StepType,
        title: String? = nil,
        body: String? = nil,
        arabicText: String? = nil,
        transliteration: String? = nil,
        audioFileName: String? = nil,
        imageName: String? = nil,
        options: [String]? = nil,
        correctAnswer: String? = nil,
        explanation: String? = nil
    ) {
        self.id = id
        self.type = type
        self.title = title
        self.body = body
        self.arabicText = arabicText
        self.transliteration = transliteration
        self.audioFileName = audioFileName
        self.imageName = imageName
        self.options = options
        self.correctAnswer = correctAnswer
        self.explanation = explanation
    }
}

// MARK: - Lesson Content
struct LessonContent: Codable, Hashable {
    let lessonId: String
    let sections: [LessonSection]

    struct LessonSection: Codable, Hashable, Identifiable {
        let id: String
        let type: SectionType
        let content: SectionContent

        enum SectionType: String, Codable {
            case text
            case audio
            case image
            case pronunciation
            case quiz
        }

        enum SectionContent: Codable, Hashable {
            case text(String)
            case audio(AudioContent)
            case image(ImageContent)
            case pronunciation(PronunciationContent)
            case quiz(QuizContent)
        }
    }

    struct AudioContent: Codable, Hashable {
        let audioFileName: String
        let arabicText: String
        let transliteration: String
        let translation: String
    }

    struct ImageContent: Codable, Hashable {
        let imageName: String
        let caption: String?
    }

    struct PronunciationContent: Codable, Hashable {
        let arabicText: String
        let transliteration: String
        let audioFileName: String
        let acceptableVariations: [String]
    }

    struct QuizContent: Codable, Hashable {
        let question: String
        let options: [String]
        let correctIndex: Int
        let explanation: String?
    }
}

// MARK: - Track Progress
struct TrackProgress: Codable, Hashable {
    let trackId: String
    var completedLessons: Int
    var totalLessons: Int
    var averageScore: Double?
    var lastLessonId: String?
    var lastActivityDate: Date?

    var completionPercentage: Double {
        guard totalLessons > 0 else { return 0 }
        return Double(completedLessons) / Double(totalLessons) * 100
    }

    var isComplete: Bool {
        completedLessons >= totalLessons
    }
}

// MARK: - Overall Learning Progress
struct LearningProgress: Codable, Hashable {
    var totalLessonsCompleted: Int
    var totalTracksCompleted: Int
    var totalMinutesLearned: Int
    var currentStreak: Int
    var pronunciationAttempts: Int
    var averagePronunciationScore: Double?
}
