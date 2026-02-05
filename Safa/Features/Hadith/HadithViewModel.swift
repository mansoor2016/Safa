// MARK: - HadithViewModel.swift
// PURPOSE: View model for hadith browsing
// DEPENDENCIES: Foundation

import Foundation

@Observable
final class HadithViewModel {
    var collections: [HadithCollection] = []
    var dailyHadith: Hadith?
    var selectedCollection: HadithCollection?
    var selectedHadith: Hadith?
    var searchQuery = ""
    var searchResults: [Hadith] = []
    var isLoading = false
    var isSearching = false
    var error: Error?

    let hadithRepository: HadithRepositoryProtocol

    init(hadithRepository: HadithRepositoryProtocol) {
        self.hadithRepository = hadithRepository
    }

    func loadCollections() async {
        isLoading = true
        do {
            collections = try await hadithRepository.getCollections()
        } catch {
            self.error = error
        }
        isLoading = false
    }

    func loadDailyHadith() async {
        do {
            dailyHadith = try await hadithRepository.getDailyHadith(for: Date())
        } catch {
            self.error = error
        }
    }

    func search() async {
        guard !searchQuery.isEmpty else { return }

        isSearching = true
        isLoading = true

        do {
            searchResults = try await hadithRepository.searchHadiths(query: searchQuery)
        } catch {
            self.error = error
        }

        isLoading = false
    }

    func clearSearch() {
        searchQuery = ""
        searchResults = []
        isSearching = false
    }
}
