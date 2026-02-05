// MARK: - QuranSearchView.swift
// PURPOSE: Search functionality for the Quran
// DEPENDENCIES: SwiftUI

import SwiftUI

// MARK: - Quran Search View Model

@Observable
final class QuranSearchViewModel {
    var searchText: String = ""
    var searchResults: [QuranSearchResult] = []
    var isSearching: Bool = false
    var recentSearches: [String] = []
    var selectedFilter: SearchFilter = .all

    enum SearchFilter: String, CaseIterable {
        case all = "All"
        case arabic = "Arabic"
        case translation = "Translation"
        case surahName = "Surah Name"
    }

    // Sample Quran data for search
    private let sampleAyahs: [QuranSearchResult] = [
        QuranSearchResult(
            surahNumber: 1,
            surahName: "Al-Fatiha",
            ayahNumber: 1,
            arabicText: "بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ",
            translation: "In the name of Allah, the Most Gracious, the Most Merciful"
        ),
        QuranSearchResult(
            surahNumber: 1,
            surahName: "Al-Fatiha",
            ayahNumber: 2,
            arabicText: "الْحَمْدُ لِلَّهِ رَبِّ الْعَالَمِينَ",
            translation: "All praise is due to Allah, the Lord of all the worlds"
        ),
        QuranSearchResult(
            surahNumber: 2,
            surahName: "Al-Baqarah",
            ayahNumber: 255,
            arabicText: "اللَّهُ لَا إِلَٰهَ إِلَّا هُوَ الْحَيُّ الْقَيُّومُ",
            translation: "Allah - there is no deity except Him, the Ever-Living, the Sustainer of existence"
        ),
        QuranSearchResult(
            surahNumber: 2,
            surahName: "Al-Baqarah",
            ayahNumber: 286,
            arabicText: "لَا يُكَلِّفُ اللَّهُ نَفْسًا إِلَّا وُسْعَهَا",
            translation: "Allah does not charge a soul except with that within its capacity"
        ),
        QuranSearchResult(
            surahNumber: 3,
            surahName: "Al-Imran",
            ayahNumber: 139,
            arabicText: "وَلَا تَهِنُوا وَلَا تَحْزَنُوا وَأَنتُمُ الْأَعْلَوْنَ",
            translation: "So do not weaken and do not grieve, and you will be superior"
        ),
        QuranSearchResult(
            surahNumber: 12,
            surahName: "Yusuf",
            ayahNumber: 86,
            arabicText: "إِنَّمَا أَشْكُو بَثِّي وَحُزْنِي إِلَى اللَّهِ",
            translation: "I only complain of my suffering and my grief to Allah"
        ),
        QuranSearchResult(
            surahNumber: 13,
            surahName: "Ar-Ra'd",
            ayahNumber: 28,
            arabicText: "أَلَا بِذِكْرِ اللَّهِ تَطْمَئِنُّ الْقُلُوبُ",
            translation: "Verily, in the remembrance of Allah do hearts find rest"
        ),
        QuranSearchResult(
            surahNumber: 55,
            surahName: "Ar-Rahman",
            ayahNumber: 13,
            arabicText: "فَبِأَيِّ آلَاءِ رَبِّكُمَا تُكَذِّبَانِ",
            translation: "So which of the favors of your Lord would you deny?"
        ),
        QuranSearchResult(
            surahNumber: 94,
            surahName: "Ash-Sharh",
            ayahNumber: 5,
            arabicText: "فَإِنَّ مَعَ الْعُسْرِ يُسْرًا",
            translation: "For indeed, with hardship comes ease"
        ),
        QuranSearchResult(
            surahNumber: 112,
            surahName: "Al-Ikhlas",
            ayahNumber: 1,
            arabicText: "قُلْ هُوَ اللَّهُ أَحَدٌ",
            translation: "Say: He is Allah, the One"
        )
    ]

    func search() {
        guard !searchText.isEmpty else {
            searchResults = []
            return
        }

        isSearching = true
        let query = searchText.lowercased()

        // Add to recent searches
        if !recentSearches.contains(searchText) {
            recentSearches.insert(searchText, at: 0)
            if recentSearches.count > 10 {
                recentSearches.removeLast()
            }
        }

        // Perform search based on filter
        searchResults = sampleAyahs.filter { result in
            switch selectedFilter {
            case .all:
                return result.translation.lowercased().contains(query) ||
                       result.arabicText.contains(searchText) ||
                       result.surahName.lowercased().contains(query)
            case .arabic:
                return result.arabicText.contains(searchText)
            case .translation:
                return result.translation.lowercased().contains(query)
            case .surahName:
                return result.surahName.lowercased().contains(query)
            }
        }

        isSearching = false
    }

    func clearRecentSearches() {
        recentSearches.removeAll()
    }

    func selectRecentSearch(_ search: String) {
        searchText = search
        self.search()
    }
}

// MARK: - Quran Search Result

struct QuranSearchResult: Identifiable {
    let id = UUID()
    let surahNumber: Int
    let surahName: String
    let ayahNumber: Int
    let arabicText: String
    let translation: String

    var reference: String {
        "\(surahName) (\(surahNumber):\(ayahNumber))"
    }
}

// MARK: - Quran Search View

struct QuranSearchView: View {
    @State private var viewModel = QuranSearchViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search bar
                searchBar

                // Filter pills
                filterPills

                // Content
                if viewModel.searchText.isEmpty {
                    recentSearchesView
                } else if viewModel.isSearching {
                    loadingView
                } else if viewModel.searchResults.isEmpty {
                    noResultsView
                } else {
                    searchResultsList
                }
            }
            .navigationTitle("Search Quran")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)

            TextField("Search Quran...", text: $viewModel.searchText)
                .textFieldStyle(.plain)
                .autocorrectionDisabled()
                .onSubmit {
                    viewModel.search()
                }

            if !viewModel.searchText.isEmpty {
                Button {
                    viewModel.searchText = ""
                    viewModel.searchResults = []
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding()
    }

    // MARK: - Filter Pills

    private var filterPills: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(QuranSearchViewModel.SearchFilter.allCases, id: \.self) { filter in
                    FilterPill(
                        title: filter.rawValue,
                        isSelected: viewModel.selectedFilter == filter,
                        action: {
                            viewModel.selectedFilter = filter
                            if !viewModel.searchText.isEmpty {
                                viewModel.search()
                            }
                        }
                    )
                }
            }
            .padding(.horizontal)
        }
        .padding(.bottom, 8)
    }

    // MARK: - Recent Searches

    private var recentSearchesView: some View {
        VStack(alignment: .leading, spacing: 16) {
            if !viewModel.recentSearches.isEmpty {
                HStack {
                    Text("Recent Searches")
                        .font(.headline)

                    Spacer()

                    Button("Clear") {
                        viewModel.clearRecentSearches()
                    }
                    .font(.subheadline)
                    .foregroundStyle(.blue)
                }
                .padding(.horizontal)

                ForEach(viewModel.recentSearches, id: \.self) { search in
                    Button {
                        viewModel.selectRecentSearch(search)
                    } label: {
                        HStack {
                            Image(systemName: "clock.arrow.circlepath")
                                .foregroundStyle(.secondary)

                            Text(search)
                                .foregroundStyle(.primary)

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 12)
                    }
                }
            }

            // Popular searches suggestion
            VStack(alignment: .leading, spacing: 12) {
                Text("Popular Searches")
                    .font(.headline)
                    .padding(.horizontal)

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 8) {
                    ForEach(["mercy", "patience", "prayer", "paradise", "guidance", "peace"], id: \.self) { term in
                        Button {
                            viewModel.searchText = term
                            viewModel.search()
                        } label: {
                            Text(term.capitalized)
                                .font(.subheadline)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Color(.secondarySystemBackground))
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)
            }
            .padding(.top)

            Spacer()
        }
        .padding(.top)
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack {
            Spacer()
            ProgressView("Searching...")
            Spacer()
        }
    }

    // MARK: - No Results View

    private var noResultsView: some View {
        ContentUnavailableView(
            "No Results",
            systemImage: "magnifyingglass",
            description: Text("No ayahs found for \"\(viewModel.searchText)\".\nTry a different search term.")
        )
    }

    // MARK: - Search Results List

    private var searchResultsList: some View {
        List {
            Section {
                Text("\(viewModel.searchResults.count) results found")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            ForEach(viewModel.searchResults) { result in
                NavigationLink {
                    // Navigate to ayah reader
                    AyahDetailView(result: result)
                } label: {
                    SearchResultRow(result: result, searchQuery: viewModel.searchText)
                }
            }
        }
        .listStyle(.plain)
    }
}

// MARK: - Filter Pill

struct FilterPill: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(isSelected ? .semibold : .regular))
                .foregroundStyle(isSelected ? .white : .primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.green : Color(.secondarySystemBackground))
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Search Result Row

struct SearchResultRow: View {
    let result: QuranSearchResult
    let searchQuery: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Reference
            HStack {
                Image(systemName: "book.fill")
                    .font(.caption)
                    .foregroundStyle(.green)

                Text(result.reference)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.green)
            }

            // Arabic text
            Text(result.arabicText)
                .font(.system(size: 18, weight: .medium, design: .serif))
                .lineLimit(2)

            // Translation with highlighted search term
            highlightedText(result.translation, query: searchQuery)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(3)
        }
        .padding(.vertical, 4)
    }

    private func highlightedText(_ text: String, query: String) -> Text {
        guard !query.isEmpty else { return Text(text) }

        let lowercasedText = text.lowercased()
        let lowercasedQuery = query.lowercased()

        guard let range = lowercasedText.range(of: lowercasedQuery) else {
            return Text(text)
        }

        let beforeRange = text.startIndex..<range.lowerBound
        let matchRange = range
        let afterRange = range.upperBound..<text.endIndex

        let beforeText = String(text[beforeRange])
        let matchText = String(text[matchRange])
        let afterText = String(text[afterRange])

        return Text(beforeText) +
               Text(matchText).bold().foregroundColor(.green) +
               Text(afterText)
    }
}

// MARK: - Ayah Detail View

struct AyahDetailView: View {
    let result: QuranSearchResult

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Arabic text
                Text(result.arabicText)
                    .font(.system(size: 32, weight: .medium, design: .serif))
                    .multilineTextAlignment(.center)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                // Translation
                VStack(alignment: .leading, spacing: 8) {
                    Text("Translation")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text(result.translation)
                        .font(.body)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // Actions
                HStack(spacing: 16) {
                    ActionButton(icon: "bookmark", title: "Bookmark")
                    ActionButton(icon: "square.and.arrow.up", title: "Share")
                    ActionButton(icon: "speaker.wave.2", title: "Play")
                    ActionButton(icon: "doc.on.doc", title: "Copy")
                }
                .padding(.top)

                Spacer()
            }
            .padding()
        }
        .navigationTitle(result.reference)
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Action Button

struct ActionButton: View {
    let icon: String
    let title: String

    var body: some View {
        Button {
            // Action
        } label: {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)

                Text(title)
                    .font(.caption)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    QuranSearchView()
}
