// MARK: - HadithView.swift
// PURPOSE: Hadith browsing and search interface
// DEPENDENCIES: SwiftUI, HadithViewModel, HadithSubviews

import SwiftUI

struct HadithView: View {
    @Environment(Dependencies.self) private var dependencies
    @State private var viewModel: HadithViewModel?

    var body: some View {
        Group {
            if let viewModel = viewModel {
                HadithContentView(viewModel: viewModel)
            } else {
                LoadingView(message: "Loading collections...")
            }
        }
        .task {
            if viewModel == nil {
                viewModel = HadithViewModel(
                    hadithRepository: dependencies.hadithRepository
                )
            }
        }
    }
}

// MARK: - Hadith Content View

enum HadithSearchFilter: String, Hashable {
    case all = "All"
    case bukhari = "Bukhari"
    case muslim = "Muslim"
    case abuDawud = "Abu Dawud"
    case tirmidhi = "Tirmidhi"
}

struct HadithContentView: View {
    @Environment(Dependencies.self) private var dependencies
    @Bindable var viewModel: HadithViewModel
    @State private var selectedFilter: HadithSearchFilter = .all

    private var hadithFilterOptions: [FilterOption<HadithSearchFilter>] {
        [
            FilterOption(label: "All", value: .all),
            FilterOption(label: "Bukhari", value: .bukhari),
            FilterOption(label: "Muslim", value: .muslim),
            FilterOption(label: "Abu Dawud", value: .abuDawud),
            FilterOption(label: "Tirmidhi", value: .tirmidhi),
        ]
    }

    var body: some View {
        VStack(spacing: 0) {
            searchBar

            // Filter pills (visible when searching)
            if viewModel.isSearching {
                FilterPillsView(options: hadithFilterOptions, selected: $selectedFilter)
            }

            if viewModel.error != nil, !viewModel.isSearching {
                ErrorView.loadFailed(retry: { await viewModel.loadCollections() })
            } else if viewModel.isLoading {
                LoadingView()
            } else if viewModel.isSearching {
                searchResultsView
            } else {
                collectionsListView
            }
        }
        .navigationTitle("Hadith")
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
        .task {
            await viewModel.loadCollections()
            await viewModel.loadDailyHadith()
        }
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        SearchBar(
            text: $viewModel.searchQuery,
            placeholder: "Search hadith...",
            onSubmit: { Task { await viewModel.search() } },
            onClear: { viewModel.clearSearch() }
        )
    }

    // MARK: - Collections List View

    private var collectionsListView: some View {
        ScrollView {
            LazyVStack(spacing: SafaSpacing.lg) {
                if let daily = viewModel.dailyHadith {
                    dailyHadithCard(daily)
                }

                TitledCard(title: "Collections", subtitle: "Browse by collection") {
                    VStack(spacing: SafaSpacing.sm) {
                        ForEach(viewModel.collections) { collection in
                            HadithCollectionRow(collection: collection) {
                                viewModel.selectedCollection = collection
                            }

                            if collection.id != viewModel.collections.last?.id {
                                Divider()
                            }
                        }
                    }
                }

                categoriesSection
            }
            .padding()
        }
        .sheet(item: $viewModel.selectedCollection) { collection in
            NavigationStack {
                CollectionDetailView(
                    collection: collection,
                    hadithRepository: viewModel.hadithRepository
                )
            }
            .fullSheet()
        }
        .sheet(item: $viewModel.selectedHadith) { hadith in
            NavigationStack {
                HadithDetailView(hadith: hadith)
            }
            .fullSheet()
        }
    }

    // MARK: - Daily Hadith Card

    private func dailyHadithCard(_ hadith: Hadith) -> some View {
        InteractiveCard(action: {
            viewModel.selectedHadith = hadith
            // Award dailyHadith hasanat when user taps (once per day)
            Task {
                await HasanatTracker.awardOnce(.dailyHadith, key: "dailyHadith", via: dependencies.userState)
            }
        }) {
            VStack(alignment: .leading, spacing: SafaSpacing.sm) {
                HStack {
                    Label("Daily Hadith", systemImage: "star.fill")
                        .font(SafaTypography.labelMedium)
                        .foregroundColor(.accentColor)

                    Spacer()

                    Text(hadith.collectionId)
                        .font(SafaTypography.labelSmall)
                        .foregroundColor(SafaColors.Fallback.secondaryText)
                }

                Text(hadith.textArabic)
                    .font(SafaTypography.arabicSmall)
                    .foregroundColor(SafaColors.Fallback.text)
                    .lineLimit(3)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .environment(\.layoutDirection, .rightToLeft)
                    .accessibilityArabic()

                Text(hadith.textEnglish)
                    .font(SafaTypography.bodySmall)
                    .foregroundColor(SafaColors.Fallback.secondaryText)
                    .lineLimit(3)

                HStack {
                    Text(hadith.narrator)
                        .font(SafaTypography.labelSmall)
                        .foregroundColor(SafaColors.Fallback.tertiaryText)

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(SafaColors.Fallback.tertiaryText)
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Daily Hadith from \(hadith.collectionId). \(hadith.textEnglish). Narrated by \(hadith.narrator)")
    }

    // MARK: - Categories Section

    private var categoriesSection: some View {
        TitledCard(title: "Topics", subtitle: "Browse by subject") {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: SafaSpacing.sm) {
                categoryButton(icon: "heart.fill", title: "Faith", color: .red)
                categoryButton(icon: "figure.stand", title: "Prayer", color: .blue)
                categoryButton(icon: "dollarsign.circle", title: "Charity", color: .green)
                categoryButton(icon: "moon.stars", title: "Fasting", color: .purple)
                categoryButton(icon: "airplane", title: "Hajj", color: .orange)
                categoryButton(icon: "person.2", title: "Family", color: .teal)
                categoryButton(icon: "book", title: "Knowledge", color: .indigo)
                categoryButton(icon: "hand.raised", title: "Manners", color: .pink)
            }
        }
    }

    private func categoryButton(icon: String, title: String, color: Color) -> some View {
        Button {
            viewModel.searchQuery = title
            Task { await viewModel.search() }
        } label: {
            VStack(spacing: SafaSpacing.xs) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)

                Text(title)
                    .font(SafaTypography.labelSmall)
                    .foregroundColor(SafaColors.Fallback.text)
            }
            .frame(maxWidth: .infinity)
            .padding(SafaSpacing.md)
            .background(color.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: SafaSpacing.CornerRadius.md))
        }
    }

    // MARK: - Filtered Results

    private var filteredSearchResults: [Hadith] {
        guard selectedFilter != .all else { return viewModel.searchResults }
        let collectionId: String = {
            switch selectedFilter {
            case .all: return ""
            case .bukhari: return "bukhari"
            case .muslim: return "muslim"
            case .abuDawud: return "abudawud"
            case .tirmidhi: return "tirmidhi"
            }
        }()
        return viewModel.searchResults.filter { $0.collectionId == collectionId }
    }

    // MARK: - Search Results View

    private var searchResultsView: some View {
        Group {
            if filteredSearchResults.isEmpty && !viewModel.isLoading {
                EmptyStateView(
                    icon: "magnifyingglass",
                    title: "No Results",
                    message: "Try a different search term"
                )
            } else {
                ScrollView {
                    LazyVStack(spacing: SafaSpacing.sm) {
                        Text("\(filteredSearchResults.count) results")
                            .font(SafaTypography.labelMedium)
                            .foregroundColor(SafaColors.Fallback.secondaryText)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        ForEach(filteredSearchResults) { hadith in
                            HadithSearchResultRow(hadith: hadith) {
                                viewModel.selectedHadith = hadith
                            }
                        }
                    }
                    .padding()
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        HadithView()
            .environment(Dependencies())
    }
}
