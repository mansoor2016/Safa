// MARK: - DataLoader.swift
// PURPOSE: Load sample and bundled JSON data files
// DEPENDENCIES: Foundation

import Foundation

final class DataLoader {
    static let shared = DataLoader()

    private init() {}

    // MARK: - Generic JSON Loading

    func load<T: Decodable>(_ filename: String, as type: T.Type) -> T? {
        guard let url = Bundle.main.url(forResource: filename, withExtension: "json") else {
            print("Failed to locate \(filename).json in bundle")
            return nil
        }

        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            return try decoder.decode(T.self, from: data)
        } catch {
            print("Failed to decode \(filename).json: \(error)")
            return nil
        }
    }

    // MARK: - Quran Data

    struct QuranDataFile: Codable {
        let surahs: [SurahData]
        let ayahs: [String: [AyahData]]
        let juz: [JuzData]

        struct SurahData: Codable {
            let number: Int
            let nameArabic: String
            let nameEnglish: String
            let nameTranslation: String
            let ayahCount: Int
            let revelationType: String
            let juzNumber: Int
        }

        struct AyahData: Codable {
            let number: Int
            let arabic: String
            let transliteration: String
            let translation: String
        }

        struct JuzData: Codable {
            let number: Int
            let name: String
            let startSurah: Int
            let startAyah: Int
            let endSurah: Int
            let endAyah: Int
        }
    }

    func loadQuranData() -> QuranDataFile? {
        return load("SampleQuranData", as: QuranDataFile.self)
    }

    // MARK: - Hadith Data

    struct HadithDataFile: Codable {
        let collections: [CollectionData]
        let books: [String: [BookData]]
        let hadiths: [HadithData]
        let dailyHadith: [String: String]

        struct CollectionData: Codable {
            let id: String
            let name: String
            let arabicName: String
            let compiler: String
            let totalHadith: Int
            let description: String
        }

        struct BookData: Codable {
            let id: String
            let name: String
            let arabicName: String
            let hadithCount: Int
        }

        struct HadithData: Codable {
            let id: String
            let collection: String
            let bookId: String
            let number: Int
            let arabic: String
            let english: String
            let narrator: String
            let grade: String
            let reference: String
            let topics: [String]
        }
    }

    func loadHadithData() -> HadithDataFile? {
        return load("SampleHadithData", as: HadithDataFile.self)
    }

    // MARK: - Dua Data

    struct DuaDataFile: Codable {
        let categories: [CategoryData]
        let duas: [DuaData]
        let dhikr: DhikrData

        struct CategoryData: Codable {
            let id: String
            let name: String
            let arabicName: String
            let iconName: String
            let duaCount: Int
        }

        struct DuaData: Codable {
            let id: String
            let category: String
            let arabic: String
            let transliteration: String
            let translation: String
            let reference: String
            let repeatCount: Int
            let benefit: String?
        }

        struct DhikrData: Codable {
            let morning: [String]
            let evening: [String]
            let sleep: [String]
        }
    }

    func loadDuaData() -> DuaDataFile? {
        return load("SampleDuaData", as: DuaDataFile.self)
    }

    // MARK: - Learning Data

    struct LearningDataFile: Codable {
        let tracks: [TrackData]
        let lessons: [String: [LessonData]]
        let progress: ProgressData

        struct TrackData: Codable {
            let id: String
            let name: String
            let arabicName: String
            let description: String
            let iconName: String
            let difficulty: String
            let estimatedHours: Int
            let lessonCount: Int
        }

        struct LessonData: Codable {
            let id: String
            let title: String
            let description: String
            let orderIndex: Int
            let content: [ContentData]
        }

        struct ContentData: Codable {
            let type: String
            let title: String
            let body: String
            let arabicText: String?
            let transliteration: String?
            let audioFileName: String?
            let imageName: String?
            let options: [String]?
            let correctAnswer: String?
            let explanation: String?
        }

        struct ProgressData: Codable {
            let completedLessons: [String]
            let currentTrack: String?
            let totalXP: Int
        }
    }

    func loadLearningData() -> LearningDataFile? {
        return load("SampleLearningData", as: LearningDataFile.self)
    }
}

// MARK: - Model Conversion Extensions

extension DataLoader.QuranDataFile.SurahData {
    func toSurah() -> Surah {
        Surah(
            id: number,
            nameArabic: nameArabic,
            nameEnglish: nameEnglish,
            nameTransliteration: nameTranslation,
            revelationType: revelationType == "Meccan" ? .meccan : .medinan,
            ayahCount: ayahCount,
            juzStart: juzNumber
        )
    }
}

extension DataLoader.HadithDataFile.CollectionData {
    func toHadithCollection() -> HadithCollection {
        HadithCollection(
            id: id,
            nameEnglish: name,
            nameArabic: arabicName,
            compilerName: compiler,
            totalHadiths: totalHadith,
            totalBooks: 1
        )
    }
}

extension DataLoader.HadithDataFile.HadithData {
    func toHadith() -> Hadith {
        Hadith(
            id: id,
            collectionId: collection,
            bookId: bookId,
            hadithNumber: number,
            textArabic: arabic,
            textEnglish: english,
            narrator: narrator,
            grading: HadithGrading(rawValue: grade),
            reference: reference
        )
    }
}

extension DataLoader.LearningDataFile.TrackData {
    func toLearningTrack() -> LearningTrack {
        LearningTrack(
            id: id,
            titleEnglish: name,
            titleArabic: arabicName,
            description: description,
            iconName: iconName,
            lessonCount: 10,
            estimatedMinutes: Int(estimatedHours * 60)
        )
    }
}

extension DataLoader.LearningDataFile.LessonData {
    func toLesson(trackId: String) -> Lesson {
        Lesson(
            id: id,
            trackId: trackId,
            order: orderIndex,
            titleEnglish: title,
            description: description,
            durationMinutes: 10,
            type: .reading,
            content: content.map { $0.toLessonStep() }
        )
    }
}

extension DataLoader.LearningDataFile.ContentData {
    func toLessonStep() -> LessonStep {
        LessonStep(
            id: UUID().uuidString,
            type: LessonStep.StepType(rawValue: type) ?? .reading,
            title: title,
            body: body,
            arabicText: arabicText,
            transliteration: transliteration,
            audioFileName: audioFileName,
            imageName: imageName,
            options: options,
            correctAnswer: correctAnswer,
            explanation: explanation
        )
    }
}
