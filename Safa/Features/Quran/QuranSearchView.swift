// MARK: - QuranSearchView.swift
// PURPOSE: Search functionality for the Quran
// DEPENDENCIES: SwiftUI, QuranRepository

import SwiftUI

// MARK: - Quran Search View Model

@Observable
final class QuranSearchViewModel {
    var searchText: String = ""
    var searchResults: [QuranSearchResult] = []
    var isSearching: Bool = false
    var recentSearches: [String] = []
    private let repository: QuranRepositoryProtocol

    init(repository: QuranRepositoryProtocol? = nil) {
        self.repository = repository ?? Dependencies.shared.quranRepository
    }

    func search() async {
        guard !searchText.isEmpty else {
            searchResults = []
            return
        }

        isSearching = true
        defer { isSearching = false }

        // Add to recent searches
        if !recentSearches.contains(searchText) {
            recentSearches.insert(searchText, at: 0)
            if recentSearches.count > 10 {
                recentSearches.removeLast()
            }
        }

        do {
            // Search both Arabic and English via FTS, plus surah names
            let ayahs = try await repository.searchAyahs(query: searchText)
            let surahs = try await repository.getAllSurahs()

            searchResults = ayahs.map { ayah in
                let surahName = surahs.first(where: { $0.id == ayah.surahNumber })?.nameEnglish ?? "Unknown"
                return QuranSearchResult(
                    surahNumber: ayah.surahNumber,
                    surahName: surahName,
                    ayahNumber: ayah.ayahNumber,
                    arabicText: ayah.textArabic,
                    translation: ayah.textTranslation
                )
            }

            // Also search for matching surah names
            let matchingSurahs = surahs.filter { surah in
                surah.nameEnglish.lowercased().contains(searchText.lowercased()) ||
                surah.nameTransliteration.lowercased().contains(searchText.lowercased())
            }

            // Add first ayah of matching surahs
            for surah in matchingSurahs {
                if !searchResults.contains(where: { $0.surahNumber == surah.id && $0.ayahNumber == 1 }) {
                    if let firstAyah = try await repository.getAyah(surah: surah.id, ayah: 1) {
                        searchResults.append(QuranSearchResult(
                            surahNumber: surah.id,
                            surahName: surah.nameEnglish,
                            ayahNumber: 1,
                            arabicText: firstAyah.textArabic,
                            translation: firstAyah.textTranslation
                        ))
                    }
                }
            }
        } catch {
            searchResults = []
        }
    }

    func clearRecentSearches() {
        recentSearches.removeAll()
    }

    func selectRecentSearch(_ query: String) {
        searchText = query
        Task {
            await search()
        }
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

enum QuranSearchFilter: String, Hashable {
    case all = "All"
    case arabic = "Arabic"
    case translation = "Translation"
    case surahName = "Surah Name"
}

struct QuranSearchView: View {
    @State private var viewModel: QuranSearchViewModel
    @State private var selectedFilter: QuranSearchFilter = .all
    @Environment(\.dismiss) private var dismiss
    @Environment(Dependencies.self) private var dependencies

    init(repository: QuranRepositoryProtocol? = nil) {
        _viewModel = State(initialValue: QuranSearchViewModel(repository: repository))
    }

    private var filterOptions: [FilterOption<QuranSearchFilter>] {
        [
            FilterOption(label: "All", value: .all),
            FilterOption(label: "Arabic", value: .arabic),
            FilterOption(label: "Translation", value: .translation),
            FilterOption(label: "Surah Name", value: .surahName),
        ]
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search bar
                searchBar

                // Filter pills (visible when there's a search query)
                if !viewModel.searchText.isEmpty {
                    FilterPillsView(options: filterOptions, selected: $selectedFilter)
                        .onChange(of: selectedFilter) { _, _ in
                            Task { await viewModel.search() }
                        }
                }

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
                    Task {
                        await viewModel.search()
                    }
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
                            Task { await viewModel.search() }
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
                    AyahDetailView(result: result)
                } label: {
                    SearchResultRow(result: result, searchQuery: viewModel.searchText)
                }
            }
        }
        .listStyle(.plain)
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

                Spacer()
            }
            .padding()
        }
        .navigationTitle(result.reference)
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Preview

#Preview {
    QuranSearchView()
}
