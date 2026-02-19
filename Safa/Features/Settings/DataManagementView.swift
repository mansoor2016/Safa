// MARK: - DataManagementView.swift
// PURPOSE: Per-category data deletion UI for granular user data control
// DEPENDENCIES: SwiftUI, AppConstants, ToastService

import SwiftUI

// MARK: - Data Category

enum DataCategory: String, CaseIterable, Identifiable {
    case prayerHistory
    case quranProgress
    case hadithBookmarks
    case chatHistory
    case streaksAndProgress
    case ramadanData

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .prayerHistory: return "Prayer History"
        case .quranProgress: return "Quran Progress"
        case .hadithBookmarks: return "Hadith Bookmarks"
        case .chatHistory: return "Chat History"
        case .streaksAndProgress: return "Streaks & Progress"
        case .ramadanData: return "Ramadan Data"
        }
    }

    var iconName: String {
        switch self {
        case .prayerHistory: return "clock.arrow.circlepath"
        case .quranProgress: return "book"
        case .hadithBookmarks: return "bookmark"
        case .chatHistory: return "bubble.left.and.bubble.right"
        case .streaksAndProgress: return "flame"
        case .ramadanData: return "moon.stars"
        }
    }

    var description: String {
        switch self {
        case .prayerHistory: return "All logged prayers and prayer history"
        case .quranProgress: return "Bookmarks, reading position, and progress"
        case .hadithBookmarks: return "All saved hadith bookmarks"
        case .chatHistory: return "All conversations and messages"
        case .streaksAndProgress: return "Streak counts, hasanat, and progress data"
        case .ramadanData: return "Fasting logs, taraweeh days, and daily goals"
        }
    }

    /// Storage keys to clear for this category
    var storageKeys: [String] {
        switch self {
        case .prayerHistory:
            return [AppConstants.StorageKeys.prayerLogs]
        case .quranProgress:
            return [
                AppConstants.StorageKeys.quranBookmarks,
                AppConstants.StorageKeys.quranProgress,
                AppConstants.StorageKeys.lastQuranPosition,
            ]
        case .hadithBookmarks:
            return [AppConstants.StorageKeys.hadithBookmarks]
        case .chatHistory:
            // Chat deletion is handled by ChatRepository (Core Data), not UserDefaults
            return []
        case .streaksAndProgress:
            return [
                AppConstants.StorageKeys.userStats,
                AppConstants.StorageKeys.userStreaks,
                AppConstants.StorageKeys.userAchievements,
            ]
        case .ramadanData:
            return [
                AppConstants.StorageKeys.ramadanFastingDays,
                AppConstants.StorageKeys.ramadanTaraweehDays,
            ]
        }
    }

    /// Prefix-based keys that need to be cleared by scanning UserDefaults
    var prefixKeys: [String] {
        switch self {
        case .chatHistory:
            // Chat deletion is handled by ChatRepository (Core Data), not UserDefaults
            return []
        case .streaksAndProgress:
            return ["com.safa.hasanat.awarded.", "com.safa.hasanat.daily."]
        case .ramadanData:
            return ["dailyGoals_"]
        default:
            return []
        }
    }
}

// MARK: - Data Deletion Service

struct DataDeletionService {

    /// Deletes data for a single category from the given UserDefaults store
    static func deleteCategory(_ category: DataCategory, from defaults: UserDefaults = .standard, appGroupDefaults: UserDefaults? = nil) {
        let stores = appGroupDefaults != nil ? [defaults, appGroupDefaults!] : [defaults]

        for store in stores {
            // Remove exact keys
            for key in category.storageKeys {
                store.removeObject(forKey: key)
            }

            // Remove prefix-matched keys
            for prefix in category.prefixKeys {
                let allKeys = store.dictionaryRepresentation().keys
                for key in allKeys where key.hasPrefix(prefix) {
                    store.removeObject(forKey: key)
                }
            }
        }
    }

    /// Deletes data for all categories
    static func deleteAllCategories(from defaults: UserDefaults = .standard, appGroupDefaults: UserDefaults? = nil) {
        for category in DataCategory.allCases {
            deleteCategory(category, from: defaults, appGroupDefaults: appGroupDefaults)
        }
    }
}

// MARK: - DataManagementView

struct DataManagementView: View {
    @Environment(Dependencies.self) private var dependencies

    @State private var categoryToDelete: DataCategory?
    @State private var showDeleteAllConfirmation = false

    private var appGroupDefaults: UserDefaults? {
        UserDefaults(suiteName: AppConstants.appGroupId)
    }

    var body: some View {
        List {
            Section {
                ForEach(DataCategory.allCases) { category in
                    categoryRow(category)
                }
            } header: {
                Text("Data Categories")
            } footer: {
                Text("Deleting a category only removes that data. Your app settings and preferences are not affected.")
            }

            Section {
                Button(role: .destructive) {
                    showDeleteAllConfirmation = true
                } label: {
                    Label("Delete All Data", systemImage: "trash")
                        .foregroundColor(.red)
                }
            } footer: {
                Text("This permanently removes all your data across every category. Your app settings are preserved.")
            }
        }
        .navigationTitle("Manage Data")
        .navigationBarTitleDisplayMode(.large)
        .alert("Delete \(categoryToDelete?.displayName ?? "")?", isPresented: categoryDeleteBinding) {
            Button("Cancel", role: .cancel) {
                categoryToDelete = nil
            }
            Button("Delete", role: .destructive) {
                if let category = categoryToDelete {
                    performDelete(category)
                }
                categoryToDelete = nil
            }
        } message: {
            Text("This will permanently delete your \(categoryToDelete?.description.lowercased() ?? "data"). This action cannot be undone.")
        }
        .alert("Delete All Data?", isPresented: $showDeleteAllConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete Everything", role: .destructive) {
                performDeleteAll()
            }
        } message: {
            Text("This will permanently delete all your progress, bookmarks, prayer history, chat history, and more. This action cannot be undone.")
        }
    }

    // MARK: - Subviews

    private func categoryRow(_ category: DataCategory) -> some View {
        HStack {
            Image(systemName: category.iconName)
                .foregroundColor(.accentColor)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(category.displayName)
                    .font(SafaTypography.bodyMedium)
                Text(category.description)
                    .font(SafaTypography.labelSmall)
                    .foregroundColor(SafaColors.Fallback.secondaryText)
            }

            Spacer()

            Button(role: .destructive) {
                categoryToDelete = category
            } label: {
                Image(systemName: "trash")
                    .font(.body)
            }
            .buttonStyle(.borderless)
        }
    }

    // MARK: - Computed Bindings

    private var categoryDeleteBinding: Binding<Bool> {
        Binding(
            get: { categoryToDelete != nil },
            set: { if !$0 { categoryToDelete = nil } }
        )
    }

    // MARK: - Actions

    private func performDelete(_ category: DataCategory) {
        DataDeletionService.deleteCategory(category, from: .standard, appGroupDefaults: appGroupDefaults)

        // Also clear chat via repository if it's chat history
        if category == .chatHistory {
            Task {
                do {
                    try await dependencies.chatRepository.clearHistory()
                    ToastService.shared.show(Toast(message: "\(category.displayName) deleted", type: .success))
                } catch {
                    ToastService.shared.show(Toast(message: "Failed to delete \(category.displayName)", type: .warning))
                }
            }
            return
        }

        // Reload user state if streaks/progress were cleared
        if category == .streaksAndProgress {
            Task { await dependencies.userState.loadUserData() }
        }

        ToastService.shared.show(Toast(message: "\(category.displayName) deleted", type: .success))
    }

    private func performDeleteAll() {
        DataDeletionService.deleteAllCategories(from: .standard, appGroupDefaults: appGroupDefaults)
        Task {
            do {
                try await dependencies.chatRepository.clearHistory()
            } catch {
                ToastService.shared.show(Toast(message: "Failed to delete chat history", type: .warning))
                return
            }
            await dependencies.userState.loadUserData()
            ToastService.shared.show(Toast(message: "All data deleted", type: .success))
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        DataManagementView()
            .environment(Dependencies())
    }
}
