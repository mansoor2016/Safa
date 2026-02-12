// MARK: - DuaRepository.swift
// PURPOSE: Implementation of Dua and Dhikr data access
// DEPENDENCIES: CoreData, DuaRepositoryProtocol, DuaDataLoader

import Foundation
import CoreData

final class DuaRepository: DuaRepositoryProtocol {
    // MARK: - Dependencies
    private let coreData: CoreDataStack
    private let duaBundle: DuaDataLoader.DuaBundle

    // MARK: - Storage Keys
    private let favoritesKey = AppConstants.StorageKeys.duaFavorites
    private let dhikrCompletionKey = AppConstants.StorageKeys.dhikrCompletion
    private let dhikrDateKey = AppConstants.StorageKeys.dhikrDate

    // MARK: - Init
    init(coreData: CoreDataStack, bundle: Bundle = .main) {
        self.coreData = coreData
        // Load bundled JSON data; fatal error if file is missing (bundled resource)
        // swiftlint:disable:next force_try
        self.duaBundle = try! DuaDataLoader.load(from: bundle)
    }

    // MARK: - Categories

    func getCategories() async throws -> [DuaCategory] {
        duaBundle.categories
    }

    func getAllDuas() async throws -> [Dua] {
        duaBundle.duas
    }

    func getDuas(forCategory categoryId: String) async throws -> [Dua] {
        duaBundle.duas.filter { $0.categoryId == categoryId }
    }

    func getDua(id: String) async throws -> Dua? {
        duaBundle.duas.first { $0.id == id }
    }

    // MARK: - Dhikr

    func getMorningDhikr() async throws -> [Dua] {
        duaBundle.duas.filter { $0.categoryId == "morning" }
    }

    func getEveningDhikr() async throws -> [Dua] {
        duaBundle.duas.filter { $0.categoryId == "evening" }
    }

    func getSleepDhikr() async throws -> [Dua] {
        duaBundle.duas.filter { $0.categoryId == "sleep" }
    }

    // MARK: - Favorites

    func getFavorites() async throws -> [Dua] {
        let favoriteIds = getFavoriteIds()
        return duaBundle.duas.filter { favoriteIds.contains($0.id) }
            .map { dua in
                var favorite = dua
                favorite.isFavorite = true
                return favorite
            }
    }

    func addToFavorites(_ dua: Dua) async throws {
        var ids = getFavoriteIds()
        guard !ids.contains(dua.id) else { return }
        ids.append(dua.id)
        saveFavoriteIds(ids)
    }

    func removeFromFavorites(_ dua: Dua) async throws {
        var ids = getFavoriteIds()
        ids.removeAll { $0 == dua.id }
        saveFavoriteIds(ids)
    }

    // MARK: - Search

    func searchDuas(query: String) async throws -> [Dua] {
        duaBundle.duas.filter { dua in
            dua.titleEnglish.localizedCaseInsensitiveContains(query) ||
            dua.textTranslation.localizedCaseInsensitiveContains(query) ||
            dua.textArabic.contains(query)
        }
    }

    // MARK: - Dhikr Completion

    func markDhikrCompleted(_ dua: Dua, type: DhikrType) async throws {
        checkAndResetIfNewDay()

        var completion = getDhikrCompletion()
        var typeCompletion = completion[type.rawValue] ?? []

        guard !typeCompletion.contains(dua.id) else { return }
        typeCompletion.append(dua.id)
        completion[type.rawValue] = typeCompletion

        saveDhikrCompletion(completion)
    }

    func getDhikrCompletionStatus(for type: DhikrType) async throws -> [String] {
        checkAndResetIfNewDay()
        let completion = getDhikrCompletion()
        return completion[type.rawValue] ?? []
    }

    func resetDhikrCompletion() async throws {
        UserDefaults.standard.removeObject(forKey: dhikrCompletionKey)
        UserDefaults.standard.set(Date(), forKey: dhikrDateKey)
    }

    // MARK: - Private Helpers

    private func getFavoriteIds() -> [String] {
        UserDefaults.standard.stringArray(forKey: favoritesKey) ?? []
    }

    private func saveFavoriteIds(_ ids: [String]) {
        UserDefaults.standard.set(ids, forKey: favoritesKey)
    }

    private func getDhikrCompletion() -> [String: [String]] {
        guard let data = UserDefaults.standard.data(forKey: dhikrCompletionKey),
              let completion = try? JSONDecoder().decode([String: [String]].self, from: data) else {
            return [:]
        }
        return completion
    }

    private func saveDhikrCompletion(_ completion: [String: [String]]) {
        guard let data = try? JSONEncoder().encode(completion) else { return }
        UserDefaults.standard.set(data, forKey: dhikrCompletionKey)
    }

    private func checkAndResetIfNewDay() {
        guard let lastDate = UserDefaults.standard.object(forKey: dhikrDateKey) as? Date else {
            UserDefaults.standard.set(Date(), forKey: dhikrDateKey)
            return
        }

        if !Calendar.current.isDateInToday(lastDate) {
            UserDefaults.standard.removeObject(forKey: dhikrCompletionKey)
            UserDefaults.standard.set(Date(), forKey: dhikrDateKey)
        }
    }
}
