// MARK: - QuranViewModel.swift
// PURPOSE: ViewModel for Quran reader feature
// DEPENDENCIES: Foundation, QuranRepository

import Foundation

@Observable
final class QuranViewModel {
    // MARK: - Published State
    var surahs: [Surah] = []
    var juzList: [Juz] = []
    var bookmarks: [QuranBookmark] = []
    var readingProgress: QuranProgress?
    var searchResults: [Ayah] = []
    var isLoading = false
    var error: Error?

    // MARK: - Search State
    var searchQuery = ""

    // MARK: - Dependencies
    private let quranRepository: QuranRepositoryProtocol
    private let userState: UserStateManager

    // MARK: - Init
    init(quranRepository: QuranRepositoryProtocol, userState: UserStateManager) {
        self.quranRepository = quranRepository
        self.userState = userState
    }

    // MARK: - Computed Properties

    var filteredSurahs: [Surah] {
        guard !searchQuery.isEmpty else { return surahs }
        return surahs.filter { surah in
            surah.nameEnglish.localizedCaseInsensitiveContains(searchQuery) ||
            surah.nameArabic.contains(searchQuery) ||
            surah.nameTransliteration.localizedCaseInsensitiveContains(searchQuery)
        }
    }

    // MARK: - Load Methods

    func loadSurahs() async {
        guard surahs.isEmpty else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            surahs = try await quranRepository.getAllSurahs()
            readingProgress = try await quranRepository.getReadingProgress()
        } catch {
            self.error = error
        }
    }

    func refreshReadingProgress() async {
        do {
            readingProgress = try await quranRepository.getReadingProgress()
        } catch {
            // Non-critical — don't overwrite existing error
        }
    }

    func loadJuz() async {
        guard juzList.isEmpty else { return }

        do {
            juzList = try await quranRepository.getAllJuz()
        } catch {
            self.error = error
        }
    }

    func loadBookmarks() async {
        do {
            bookmarks = try await quranRepository.getBookmarks()
        } catch {
            self.error = error
        }
    }

    // MARK: - Search

    func search(query: String) async {
        searchQuery = query
        guard !query.isEmpty else {
            searchResults = []
            return
        }

        do {
            searchResults = try await quranRepository.searchAyahs(query: query)
        } catch {
            self.error = error
        }
    }

    // MARK: - Bookmarks

    func addBookmark(surah: Int, ayah: Int) async {
        do {
            try await quranRepository.addBookmark(surah: surah, ayah: ayah)
            await loadBookmarks()
        } catch {
            self.error = error
        }
    }

    func removeBookmark(_ bookmark: QuranBookmark) async {
        do {
            try await quranRepository.removeBookmark(surah: bookmark.surahNumber, ayah: bookmark.ayahNumber)
            await loadBookmarks()
        } catch {
            self.error = error
        }
    }

    func isBookmarked(surah: Int, ayah: Int) async -> Bool {
        do {
            return try await quranRepository.isBookmarked(surah: surah, ayah: ayah)
        } catch {
            return false
        }
    }

    func updateBookmarkNote(_ bookmark: QuranBookmark, note: String?) async {
        do {
            try await quranRepository.updateBookmarkNote(
                surahNumber: bookmark.surahNumber,
                ayahNumber: bookmark.ayahNumber,
                note: note
            )
            await loadBookmarks()
        } catch {
            self.error = error
        }
    }

    // MARK: - Juz Navigation Helper

    func navigationTargetForJuz(_ juzNumber: Int) -> QuranNavigationTarget? {
        guard let juz = juzList.first(where: { $0.number == juzNumber }) else { return nil }
        return QuranNavigationTarget(surahNumber: juz.startSurah, startAyah: juz.startAyah)
    }

    // MARK: - Helpers

    func getSurahName(_ number: Int) -> String {
        surahs.first { $0.number == number }?.nameEnglish ?? "Surah \(number)"
    }
}
