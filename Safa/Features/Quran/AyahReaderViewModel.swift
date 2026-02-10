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

            try await repository.updateProgress(surah: surahNumber, ayah: 1)

            isLoading = false
        } catch {
            self.error = error
            isLoading = false
        }
    }

    func isBookmarked(_ ayah: Ayah) -> Bool {
        bookmarkedAyahs.contains(ayah.id)
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
}
