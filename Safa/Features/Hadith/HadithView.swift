// MARK: - HadithView.swift
// PURPOSE: Hadith browsing and search interface
// DEPENDENCIES: SwiftUI

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

private struct HadithContentView: View {
    @Bindable var viewModel: HadithViewModel

    var body: some View {
        VStack(spacing: 0) {
            // Search bar
            searchBar

            // Content
            if viewModel.isLoading {
                LoadingView()
            } else if viewModel.isSearching {
                searchResultsView
            } else {
                collectionsListView
            }
        }
        .navigationTitle("Hadith")
        .navigationBarTitleDisplayMode(.large)
        .task {
            await viewModel.loadCollections()
            await viewModel.loadDailyHadith()
        }
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(SafaColors.Fallback.secondaryText)

            TextField("Search hadith...", text: $viewModel.searchQuery)
                .textFieldStyle(.plain)
                .onSubmit {
                    Task { await viewModel.search() }
                }

            if !viewModel.searchQuery.isEmpty {
                Button {
                    viewModel.clearSearch()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(SafaColors.Fallback.tertiaryText)
                }
            }
        }
        .padding(SafaSpacing.sm)
        .background(Color(UIColor.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: SafaSpacing.CornerRadius.md))
        .padding()
    }

    // MARK: - Collections List View

    private var collectionsListView: some View {
        ScrollView {
            LazyVStack(spacing: SafaSpacing.lg) {
                // Daily Hadith
                if let daily = viewModel.dailyHadith {
                    dailyHadithCard(daily)
                }

                // Collections
                TitledCard(title: "Collections", subtitle: "Browse by collection") {
                    VStack(spacing: SafaSpacing.sm) {
                        ForEach(viewModel.collections) { collection in
                            CollectionRow(collection: collection) {
                                viewModel.selectedCollection = collection
                            }

                            if collection.id != viewModel.collections.last?.id {
                                Divider()
                            }
                        }
                    }
                }

                // Categories
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
        }
        .sheet(item: $viewModel.selectedHadith) { hadith in
            NavigationStack {
                HadithDetailView(hadith: hadith)
            }
        }
    }

    // MARK: - Daily Hadith Card

    private func dailyHadithCard(_ hadith: Hadith) -> some View {
        InteractiveCard(action: {
            viewModel.selectedHadith = hadith
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
                    .font(SafaTypography.arabicSmallFallback)
                    .foregroundColor(SafaColors.Fallback.text)
                    .lineLimit(3)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .environment(\.layoutDirection, .rightToLeft)

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

    // MARK: - Search Results View

    private var searchResultsView: some View {
        Group {
            if viewModel.searchResults.isEmpty && !viewModel.isLoading {
                EmptyStateView(
                    icon: "magnifyingglass",
                    title: "No Results",
                    message: "Try a different search term"
                )
            } else {
                ScrollView {
                    LazyVStack(spacing: SafaSpacing.sm) {
                        Text("\(viewModel.searchResults.count) results")
                            .font(SafaTypography.labelMedium)
                            .foregroundColor(SafaColors.Fallback.secondaryText)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        ForEach(viewModel.searchResults) { hadith in
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

// MARK: - Hadith View Model

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

// MARK: - Collection Row

private struct CollectionRow: View {
    let collection: HadithCollection
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: SafaSpacing.xxs) {
                    Text(collection.nameEnglish)
                        .font(SafaTypography.bodyLarge)
                        .foregroundColor(SafaColors.Fallback.text)

                    Text(collection.nameArabic)
                        .font(SafaTypography.arabicSmallFallback)
                        .foregroundColor(SafaColors.Fallback.secondaryText)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: SafaSpacing.xxs) {
                    Text("\(collection.totalHadiths)")
                        .font(SafaTypography.bodyMedium)
                        .foregroundColor(.accentColor)

                    Text("hadith")
                        .font(SafaTypography.labelSmall)
                        .foregroundColor(SafaColors.Fallback.tertiaryText)
                }

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(SafaColors.Fallback.tertiaryText)
            }
        }
    }
}

// MARK: - Hadith Search Result Row

private struct HadithSearchResultRow: View {
    let hadith: Hadith
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ContentCard {
                VStack(alignment: .leading, spacing: SafaSpacing.sm) {
                    HStack {
                        Text(hadith.collectionId)
                            .font(SafaTypography.labelSmall)
                            .foregroundColor(.accentColor)

                        Spacer()

                        Text("#\(hadith.hadithNumber)")
                            .font(SafaTypography.labelSmall)
                            .foregroundColor(SafaColors.Fallback.tertiaryText)
                    }

                    Text(hadith.textEnglish)
                        .font(SafaTypography.bodyMedium)
                        .foregroundColor(SafaColors.Fallback.text)
                        .lineLimit(4)
                        .multilineTextAlignment(.leading)

                    HStack {
                        Text(hadith.narrator)
                            .font(SafaTypography.labelSmall)
                            .foregroundColor(SafaColors.Fallback.secondaryText)

                        Spacer()

                        if let grading = hadith.grading {
                            GradeBadge(grade: grading)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Grade Badge

private struct GradeBadge: View {
    let grade: HadithGrading

    var body: some View {
        Text(grade.displayName)
            .font(SafaTypography.labelSmall)
            .foregroundColor(.white)
            .padding(.horizontal, SafaSpacing.xs)
            .padding(.vertical, 2)
            .background(gradeColor)
            .clipShape(Capsule())
    }

    private var gradeColor: Color {
        switch grade {
        case .sahih: return .green
        case .hasan: return .blue
        case .daif: return .orange
        case .mawdu: return .red
        case .unknown: return .gray
        }
    }
}

// MARK: - Collection Detail View

private struct CollectionDetailView: View {
    let collection: HadithCollection
    let hadithRepository: HadithRepositoryProtocol
    @Environment(\.dismiss) private var dismiss

    @State private var books: [HadithBook] = []
    @State private var selectedBook: HadithBook?
    @State private var isLoading = true

    var body: some View {
        Group {
            if isLoading {
                LoadingView()
            } else {
                List(books) { book in
                    Button {
                        selectedBook = book
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: SafaSpacing.xxs) {
                                Text(book.nameEnglish)
                                    .font(SafaTypography.bodyMedium)
                                    .foregroundColor(SafaColors.Fallback.text)

                                Text("\(book.hadithCount) hadith")
                                    .font(SafaTypography.labelSmall)
                                    .foregroundColor(SafaColors.Fallback.secondaryText)
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(SafaColors.Fallback.tertiaryText)
                        }
                    }
                }
            }
        }
        .navigationTitle(collection.nameEnglish)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Done") {
                    dismiss()
                }
            }
        }
        .sheet(item: $selectedBook) { book in
            NavigationStack {
                BookHadithListView(
                    book: book,
                    collectionId: collection.id,
                    hadithRepository: hadithRepository
                )
            }
        }
        .task {
            do {
                books = try await hadithRepository.getBooks(forCollection: collection.id)
            } catch {
                // Handle error
            }
            isLoading = false
        }
    }
}

// MARK: - Book Hadith List View

private struct BookHadithListView: View {
    let book: HadithBook
    let collectionId: String
    let hadithRepository: HadithRepositoryProtocol
    @Environment(\.dismiss) private var dismiss

    @State private var hadiths: [Hadith] = []
    @State private var selectedHadith: Hadith?
    @State private var isLoading = true

    var body: some View {
        Group {
            if isLoading {
                LoadingView()
            } else {
                ScrollView {
                    LazyVStack(spacing: SafaSpacing.sm) {
                        ForEach(hadiths) { hadith in
                            HadithListRow(hadith: hadith) {
                                selectedHadith = hadith
                            }
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationTitle(book.nameEnglish)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Done") {
                    dismiss()
                }
            }
        }
        .sheet(item: $selectedHadith) { hadith in
            NavigationStack {
                HadithDetailView(hadith: hadith)
            }
        }
        .task {
            do {
                hadiths = try await hadithRepository.getHadiths(
                    collection: collectionId,
                    book: book.id
                )
            } catch {
                // Handle error
            }
            isLoading = false
        }
    }
}

// MARK: - Hadith List Row

private struct HadithListRow: View {
    let hadith: Hadith
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ContentCard {
                VStack(alignment: .leading, spacing: SafaSpacing.sm) {
                    HStack {
                        Text("#\(hadith.hadithNumber)")
                            .font(SafaTypography.labelMedium)
                            .foregroundColor(.accentColor)

                        Spacer()

                        if let grading = hadith.grading {
                            GradeBadge(grade: grading)
                        }
                    }

                    Text(hadith.textEnglish)
                        .font(SafaTypography.bodyMedium)
                        .foregroundColor(SafaColors.Fallback.text)
                        .lineLimit(4)
                        .multilineTextAlignment(.leading)

                    Text(hadith.narrator)
                        .font(SafaTypography.labelSmall)
                        .foregroundColor(SafaColors.Fallback.secondaryText)
                }
            }
        }
    }
}

// MARK: - Hadith Detail View

private struct HadithDetailView: View {
    let hadith: Hadith
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: SafaSpacing.lg) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: SafaSpacing.xxs) {
                        Text(hadith.collectionId)
                            .font(SafaTypography.titleMedium)
                            .foregroundColor(.accentColor)

                        Text("Hadith #\(hadith.hadithNumber)")
                            .font(SafaTypography.bodyMedium)
                            .foregroundColor(SafaColors.Fallback.secondaryText)
                    }

                    Spacer()

                    if let grading = hadith.grading {
                        GradeBadge(grade: grading)
                    }
                }

                Divider()

                // Arabic text
                VStack(alignment: .trailing, spacing: SafaSpacing.sm) {
                    Text("Arabic")
                        .font(SafaTypography.labelMedium)
                        .foregroundColor(SafaColors.Fallback.secondaryText)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Text(hadith.textArabic)
                        .font(SafaTypography.arabicMediumFallback)
                        .foregroundColor(SafaColors.Fallback.text)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .environment(\.layoutDirection, .rightToLeft)
                }

                Divider()

                // English translation
                VStack(alignment: .leading, spacing: SafaSpacing.sm) {
                    Text("Translation")
                        .font(SafaTypography.labelMedium)
                        .foregroundColor(SafaColors.Fallback.secondaryText)

                    Text(hadith.textEnglish)
                        .font(SafaTypography.bodyMedium)
                        .foregroundColor(SafaColors.Fallback.text)
                }

                Divider()

                // Narrator
                VStack(alignment: .leading, spacing: SafaSpacing.xs) {
                    Text("Narrator")
                        .font(SafaTypography.labelMedium)
                        .foregroundColor(SafaColors.Fallback.secondaryText)

                    Text(hadith.narrator)
                        .font(SafaTypography.bodyMedium)
                        .foregroundColor(SafaColors.Fallback.text)
                }

                // Reference
                VStack(alignment: .leading, spacing: SafaSpacing.xs) {
                    Text("Reference")
                        .font(SafaTypography.labelMedium)
                        .foregroundColor(SafaColors.Fallback.secondaryText)

                    Text(hadith.reference)
                        .font(SafaTypography.bodySmall)
                        .foregroundColor(SafaColors.Fallback.secondaryText)
                }

                // Actions
                HStack(spacing: SafaSpacing.md) {
                    Button {
                        // Share
                    } label: {
                        Label("Share", systemImage: "square.and.arrow.up")
                    }
                    .buttonStyle(.bordered)

                    Button {
                        // Bookmark
                    } label: {
                        Label("Save", systemImage: "bookmark")
                    }
                    .buttonStyle(.bordered)

                    Button {
                        // Copy
                        UIPasteboard.general.string = hadith.textEnglish
                    } label: {
                        Label("Copy", systemImage: "doc.on.doc")
                    }
                    .buttonStyle(.bordered)
                }
                .frame(maxWidth: .infinity)
            }
            .padding()
        }
        .navigationTitle("Hadith")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Done") {
                    dismiss()
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
