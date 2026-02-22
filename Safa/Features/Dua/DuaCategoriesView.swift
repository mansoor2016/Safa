// MARK: - DuaCategoriesView.swift
// PURPOSE: Browse duas by category
// DEPENDENCIES: SwiftUI, DuaCategoriesViewModel

import SwiftUI

// MARK: - Dua Categories View

struct DuaCategoriesView: View {
    @Environment(Dependencies.self) private var dependencies
    @State private var viewModel: DuaCategoriesViewModel
    @State private var searchText = ""
    @State private var favoriteIds: Set<String> = []

    init(viewModel: DuaCategoriesViewModel? = nil) {
        _viewModel = State(initialValue: viewModel ?? DuaCategoriesViewModel(
            repository: Dependencies.shared.duaRepository
        ))
    }

    var body: some View {
        ScrollableScreen {
            LazyVStack(spacing: 12) {
                headerView
                quickAccessSection
                categoriesSection
            }
            .padding(.bottom, 100)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Duas")
        .navigationBarTitleDisplayMode(.large)
        .searchable(text: $searchText, prompt: "Search duas...")
        .task {
            await viewModel.load()
            let storedIds = UserDefaults.standard.stringArray(forKey: AppConstants.StorageKeys.duaFavorites) ?? []
            favoriteIds = Set(storedIds)
        }
    }

    private var headerView: some View {
        VStack(spacing: 8) {
            Text("أدعية وأذكار")
                .font(SafaTypography.arabicMedium)
                .environment(\.layoutDirection, .rightToLeft)
                .accessibilityArabic()

            Text("Supplications & Remembrances")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 20)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Supplications and Remembrances")
    }

    private var quickAccessSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Access")
                .font(.caption)
                .foregroundColor(.secondary)
                .textCase(.uppercase)
                .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    NavigationLink(destination: FavouriteDuasListView(
                        duas: viewModel.favoriteDuas(ids: favoriteIds),
                        favoriteIds: $favoriteIds
                    )) {
                        QuickAccessButton(title: "Favourites", arabicTitle: "المفضلة", iconName: "heart.fill", color: .pink)
                    }
                    .buttonStyle(.plain)

                    NavigationLink(destination: DuaListView(
                        categoryName: "Morning",
                        duas: viewModel.duas(forCategory: "morning"),
                        favoriteIds: $favoriteIds
                    )) {
                        QuickAccessButton(title: "Morning", arabicTitle: "أذكار الصباح", iconName: "sunrise.fill", color: .orange)
                    }
                    .buttonStyle(.plain)

                    NavigationLink(destination: DuaListView(
                        categoryName: "Prayer",
                        duas: viewModel.duas(forCategory: "prayer"),
                        favoriteIds: $favoriteIds
                    )) {
                        QuickAccessButton(title: "Prayer", arabicTitle: "أدعية الصلاة", iconName: "hands.sparkles.fill", color: .teal)
                    }
                    .buttonStyle(.plain)

                    NavigationLink(destination: DuaListView(
                        categoryName: "Food & Drink",
                        duas: viewModel.duas(forCategory: "food"),
                        favoriteIds: $favoriteIds
                    )) {
                        QuickAccessButton(title: "Eating", arabicTitle: "أذكار الطعام", iconName: "fork.knife", color: .indigo)
                    }
                    .buttonStyle(.plain)

                    NavigationLink(destination: DuaListView(
                        categoryName: "Sleep",
                        duas: viewModel.duas(forCategory: "sleep"),
                        favoriteIds: $favoriteIds
                    )) {
                        QuickAccessButton(title: "Sleep", arabicTitle: "أذكار النوم", iconName: "moon.zzz.fill", color: .purple)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal)
            }
        }
    }

    private var categoriesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Categories")
                .font(.caption)
                .foregroundColor(.secondary)
                .textCase(.uppercase)
                .padding(.horizontal)

            ForEach(viewModel.filteredCategories(query: searchText)) { category in
                NavigationLink(destination: DuaListView(
                    categoryName: category.nameEnglish,
                    duas: viewModel.duas(forCategory: category.id),
                    favoriteIds: $favoriteIds
                )) {
                    CategoryRow(category: category)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal)
        }
    }
}

// MARK: - Quick Access Button

struct QuickAccessButton: View {
    let title: String
    let arabicTitle: String
    let iconName: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 56, height: 56)

                Image(systemName: iconName)
                    .font(.title2)
                    .foregroundColor(color)
            }

            VStack(spacing: 2) {
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.center)

                Text(arabicTitle)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .environment(\.layoutDirection, .rightToLeft)
                    .accessibilityArabic()
            }
            .frame(height: 36, alignment: .top)
        }
        .frame(width: 80, alignment: .top)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title) duas")
    }
}

// MARK: - Category Row

struct CategoryRow: View {
    let category: DuaCategory

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.accentColor.opacity(0.1))
                    .frame(width: 48, height: 48)

                Image(systemName: category.iconName)
                    .font(.title3)
                    .foregroundColor(.accentColor)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(category.nameEnglish)
                    .font(.headline)

                Text(category.nameArabic)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .environment(\.layoutDirection, .rightToLeft)
                    .accessibilityArabic()
            }

            Spacer()

            Text("\(category.duaCount)")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color(.tertiarySystemGroupedBackground))
                .cornerRadius(8)

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(category.nameEnglish), \(category.duaCount) duas")
    }
}

// MARK: - Dua List View

struct DuaListView: View {
    let categoryName: String
    let duas: [Dua]
    @Environment(Dependencies.self) private var dependencies
    @Binding var favoriteIds: Set<String>

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(duas) { dua in
                    DuaCard(
                        dua: dua,
                        isFavorite: favoriteIds.contains(dua.id),
                        onToggleFavorite: { toggleFavorite(dua) }
                    )
                }

                if duas.isEmpty {
                    ContentUnavailableView(
                        "No Duas Yet",
                        systemImage: "text.book.closed",
                        description: Text("Duas for this category are coming soon.")
                    )
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(categoryName)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func toggleFavorite(_ dua: Dua) {
        Task {
            if favoriteIds.contains(dua.id) {
                try? await dependencies.duaRepository.removeFromFavorites(dua)
                favoriteIds.remove(dua.id)
            } else {
                try? await dependencies.duaRepository.addToFavorites(dua)
                favoriteIds.insert(dua.id)
            }
        }
    }
}

// MARK: - Dua Card

struct DuaCard: View {
    @Environment(Dependencies.self) private var dependencies
    let dua: Dua
    var isFavorite: Bool = false
    var onToggleFavorite: (() -> Void)? = nil
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(dua.textArabic)
                .font(.system(size: 24, weight: .regular, design: .serif))
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .lineSpacing(12)
                .environment(\.layoutDirection, .rightToLeft)
                .accessibilityArabic()

            if !dua.textTransliteration.isEmpty {
                Text(dua.textTransliteration)
                    .font(.subheadline)
                    .italic()
                    .foregroundColor(.secondary)
            }

            Text(dua.textTranslation)
                .font(.subheadline)

            HStack {
                if let occasion = dua.occasion, isExpanded {
                    Text(occasion)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                if dua.repetitions > 1 {
                    Label("\(dua.repetitions)x", systemImage: "repeat")
                        .font(.caption)
                        .foregroundColor(.accentColor)
                }
            }

            HStack {
                Text(dua.source ?? "")
                    .font(.caption2)
                    .foregroundColor(.secondary)

                Spacer()

                if let onToggleFavorite {
                    Button {
                        onToggleFavorite()
                        HapticFeedbackService.shared.play(.selection)
                    } label: {
                        Image(systemName: isFavorite ? "heart.fill" : "heart")
                            .foregroundColor(isFavorite ? .pink : .secondary)
                    }
                }

                Button {
                    withAnimation { isExpanded.toggle() }
                } label: {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .contextMenu {
            if dependencies.llmService.availability.isAvailable {
                Button {
                    let router = AppRouter.shared
                    router.pendingChatContext = ChatContext(
                        topic: .dua,
                        duaId: dua.id
                    )
                    router.pendingChatInput = "Tell me about this dua: \(dua.titleEnglish)"
                    router.navigate(to: .chat)
                } label: {
                    Label("Learn about this dua", systemImage: "sparkles")
                }
            }
        }
    }
}

// MARK: - Favourite Duas List View

struct FavouriteDuasListView: View {
    @Environment(Dependencies.self) private var dependencies
    let duas: [Dua]
    @Binding var favoriteIds: Set<String>

    private var filteredDuas: [Dua] {
        duas.filter { favoriteIds.contains($0.id) }
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(filteredDuas) { dua in
                    DuaCard(
                        dua: dua,
                        isFavorite: true,
                        onToggleFavorite: { toggleFavorite(dua) }
                    )
                }

                if filteredDuas.isEmpty {
                    ContentUnavailableView(
                        "No Favourites Yet",
                        systemImage: "heart.slash",
                        description: Text("Tap the heart on any dua to save it here.")
                    )
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Favourites")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func toggleFavorite(_ dua: Dua) {
        Task {
            if favoriteIds.contains(dua.id) {
                try? await dependencies.duaRepository.removeFromFavorites(dua)
                favoriteIds.remove(dua.id)
            } else {
                try? await dependencies.duaRepository.addToFavorites(dua)
                favoriteIds.insert(dua.id)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        DuaCategoriesView()
    }
}
