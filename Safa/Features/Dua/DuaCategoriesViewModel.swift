// MARK: - DuaCategoriesViewModel.swift
// PURPOSE: Loads dua categories and duas from the repository
// DEPENDENCIES: DuaRepositoryProtocol

import SwiftUI

@Observable
final class DuaCategoriesViewModel {
    // MARK: - Published State
    private(set) var categories: [DuaCategory] = []
    private(set) var allDuas: [Dua] = []
    private(set) var isLoading = false
    private(set) var error: Error?

    // MARK: - Dependencies
    private let repository: DuaRepositoryProtocol

    // MARK: - Init
    init(repository: DuaRepositoryProtocol) {
        self.repository = repository
    }

    // MARK: - Public Methods

    func load() async {
        isLoading = true
        defer { isLoading = false }

        do {
            async let cats = repository.getCategories()
            async let duas = repository.getAllDuas()
            categories = try await cats
            allDuas = try await duas
        } catch {
            self.error = error
        }
    }

    func duas(forCategory categoryId: String) -> [Dua] {
        allDuas.filter { $0.categoryId == categoryId }
    }

    func filteredCategories(query: String) -> [DuaCategory] {
        if query.isEmpty {
            return categories
        }
        return categories.filter {
            $0.nameEnglish.localizedCaseInsensitiveContains(query) ||
            $0.nameArabic.contains(query)
        }
    }

    func favoriteDuas(ids: Set<String>) -> [Dua] {
        allDuas.filter { ids.contains($0.id) }
    }
}
