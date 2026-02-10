// MARK: - AyahReaderViewModel.swift
// PURPOSE: ViewModel for the ayah-by-ayah reader view
// DEPENDENCIES: Foundation, QuranRepositoryProtocol

import Foundation

@Observable
final class AyahReaderViewModel {
    // MARK: - Published State
    private(set) var surah: Surah?
    private(set) var ayahs: [Ayah] = []
    private(set) var isLoading = true
    private(set) var error: Error?
    private(set) var bookmarkedAyahs: Set<String> = []
    var showTranslation = true
    var fontPreferences = QuranFontPreferences.load() {
        didSet { fontPreferences.save() }
    }
    private(set) var surahReadProgress: SurahReadProgress?
    var isAutoScrolling = false
    var autoScrollSpeed: AutoScrollSpeed = .normal

    // MARK: - Config
    let surahNumber: Int
    let startAyah: Int

    // MARK: - Dependencies
    private let repository: QuranRepositoryProtocol

    // MARK: - Init
    init(surahNumber: Int, startAyah: Int = 1, repository: QuranRepositoryProtocol) {
        self.surahNumber = surahNumber
        self.startAyah = startAyah
        self.repository = repository
    }

    // MARK: - Computed Properties

    var hasNextSurah: Bool {
        surahNumber < 114
    }

    var nextSurahNumber: Int {
        surahNumber + 1
    }

    var progressFraction: Double {
        surahReadProgress?.fractionComplete ?? 0
    }

    var isSurahComplete: Bool {
        surahReadProgress?.isComplete ?? false
    }

    // MARK: - Auto-Scroll Helpers

    func scrollIntervalForAyah(_ ayah: Ayah) -> TimeInterval {
        let charCount = Double(ayah.textArabic.count)
        let baseReadingPace = 15.0 // characters per second at 1x speed
        let interval = charCount / (baseReadingPace * autoScrollSpeed.rawValue)
        return max(2.0, interval) // Minimum 2 seconds
    }

    // MARK: - Public Methods

    func loadAyahs() async {
        isLoading = true
        error = nil

        do {
            if surah == nil {
                let surahs = try await repository.getAllSurahs()
                surah = surahs.first { $0.number == surahNumber }
            }

            ayahs = try await repository.getAyahs(forSurah: surahNumber)

            let bookmarks = try await repository.getBookmarks()
            bookmarkedAyahs = Set(
                bookmarks
                    .filter { $0.surahNumber == surahNumber }
                    .map { "\($0.surahNumber):\($0.ayahNumber)" }
            )

            surahReadProgress = try await repository.getSurahReadProgress(surahNumber: surahNumber)
                ?? SurahReadProgress(surahNumber: surahNumber, totalAyahs: ayahs.count)

            isLoading = false
        } catch {
            self.error = error
            isLoading = false
        }
    }

    func isBookmarked(_ ayah: Ayah) -> Bool {
        bookmarkedAyahs.contains(ayah.id)
    }

    func markAyahVisible(_ ayahNumber: Int) {
        guard surahReadProgress != nil else { return }
        let isNewAyah = !(surahReadProgress?.readAyahs.contains(ayahNumber) ?? false)
        if isNewAyah {
            surahReadProgress?.readAyahs.insert(ayahNumber)
        }
        Task {
            if isNewAyah {
                try? await repository.markAyahRead(
                    surahNumber: surahNumber,
                    ayahNumber: ayahNumber,
                    totalAyahs: ayahs.count
                )
            }
            try? await repository.updateProgress(surah: surahNumber, ayah: ayahNumber)
        }
    }

    func toggleBookmark(_ ayah: Ayah) async {
        do {
            if isBookmarked(ayah) {
                try await repository.removeBookmark(surah: ayah.surahNumber, ayah: ayah.ayahNumber)
                bookmarkedAyahs.remove(ayah.id)
            } else {
                try await repository.addBookmark(surah: ayah.surahNumber, ayah: ayah.ayahNumber)
                bookmarkedAyahs.insert(ayah.id)
            }
        } catch {
            self.error = error
        }
    }

    func markAllAyahsRead() async {
        guard let progress = surahReadProgress else { return }
        for ayahNumber in 1...progress.totalAyahs {
            surahReadProgress?.readAyahs.insert(ayahNumber)
        }
        Task {
            for ayahNumber in 1...progress.totalAyahs {
                try? await repository.markAyahRead(
                    surahNumber: surahNumber,
                    ayahNumber: ayahNumber,
                    totalAyahs: progress.totalAyahs
                )
            }
        }
    }
}
