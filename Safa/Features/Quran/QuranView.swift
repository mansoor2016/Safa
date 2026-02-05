// MARK: - QuranView.swift
// PURPOSE: Main Quran reader entry view with surah list
// DEPENDENCIES: SwiftUI, QuranViewModel

import SwiftUI

struct QuranView: View {
    @Environment(Dependencies.self) private var dependencies
    @State private var viewModel: QuranViewModel?

    var body: some View {
        Group {
            if let viewModel = viewModel {
                QuranContentView(viewModel: viewModel)
            } else {
                LoadingView(message: "Loading Quran...")
            }
        }
        .task {
            if viewModel == nil {
                viewModel = QuranViewModel(
                    quranRepository: dependencies.quranRepository,
                    userState: dependencies.userState
                )
            }
        }
    }
}

// MARK: - Quran Content View

private struct QuranContentView: View {
    @Bindable var viewModel: QuranViewModel
    @State private var searchText = ""
    @State private var selectedTab = 0
    @State private var showingSearch = false

    var body: some View {
        VStack(spacing: 0) {
            // Tab selector
            Picker("View", selection: $selectedTab) {
                Text("Surahs").tag(0)
                Text("Juz").tag(1)
                Text("Bookmarks").tag(2)
            }
            .pickerStyle(.segmented)
            .padding()

            // Content
            TabView(selection: $selectedTab) {
                surahListView.tag(0)
                juzListView.tag(1)
                bookmarksView.tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
        }
        .navigationTitle("Quran")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingSearch = true
                } label: {
                    Image(systemName: "magnifyingglass")
                }
            }
        }
        .sheet(isPresented: $showingSearch) {
            QuranSearchView()
        }
        .searchable(text: $searchText, prompt: "Search ayahs...")
        .onChange(of: searchText) { _, newValue in
            Task {
                await viewModel.search(query: newValue)
            }
        }
        .task {
            await viewModel.loadSurahs()
        }
    }

    // MARK: - Surah List

    private var surahListView: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                // Resume reading card
                if let progress = viewModel.readingProgress {
                    ResumeReadingCard(
                        surahNumber: progress.lastSurah,
                        ayahNumber: progress.lastAyah,
                        surahName: viewModel.getSurahName(progress.lastSurah)
                    ) {
                        viewModel.navigateToAyah(
                            surah: progress.lastSurah,
                            ayah: progress.lastAyah
                        )
                    }
                    .padding()
                }

                ForEach(viewModel.filteredSurahs) { surah in
                    SurahRow(surah: surah) {
                        viewModel.selectedSurah = surah
                    }
                    Divider()
                        .padding(.leading, SafaSpacing.xl + SafaSpacing.md)
                }
            }
        }
    }

    // MARK: - Juz List

    private var juzListView: some View {
        ScrollView {
            LazyVStack(spacing: SafaSpacing.sm) {
                ForEach(viewModel.juzList) { juz in
                    JuzRow(juz: juz) {
                        viewModel.navigateToJuz(juz.number)
                    }
                }
            }
            .padding()
        }
        .task {
            await viewModel.loadJuz()
        }
    }

    // MARK: - Bookmarks

    private var bookmarksView: some View {
        Group {
            if viewModel.bookmarks.isEmpty {
                EmptyStateView.noBookmarks
            } else {
                ScrollView {
                    LazyVStack(spacing: SafaSpacing.sm) {
                        ForEach(viewModel.bookmarks) { bookmark in
                            BookmarkRow(bookmark: bookmark) {
                                viewModel.navigateToAyah(
                                    surah: bookmark.surahNumber,
                                    ayah: bookmark.ayahNumber
                                )
                            } onDelete: {
                                Task {
                                    await viewModel.removeBookmark(bookmark)
                                }
                            }
                        }
                    }
                    .padding()
                }
            }
        }
        .task {
            await viewModel.loadBookmarks()
        }
    }
}

// MARK: - Resume Reading Card

private struct ResumeReadingCard: View {
    let surahNumber: Int
    let ayahNumber: Int
    let surahName: String
    let action: () -> Void

    var body: some View {
        InteractiveCard(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: SafaSpacing.xxs) {
                    Text("Continue Reading")
                        .font(SafaTypography.labelMedium)
                        .foregroundColor(SafaColors.Fallback.secondaryText)

                    Text(surahName)
                        .font(SafaTypography.titleMedium)
                        .foregroundColor(SafaColors.Fallback.text)

                    Text("Ayah \(ayahNumber)")
                        .font(SafaTypography.bodySmall)
                        .foregroundColor(SafaColors.Fallback.secondaryText)
                }

                Spacer()

                Image(systemName: "play.circle.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.accentColor)
            }
        }
    }
}

// MARK: - Surah Row

private struct SurahRow: View {
    let surah: Surah
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: SafaSpacing.md) {
                // Surah number
                Text("\(surah.number)")
                    .font(SafaTypography.labelMedium)
                    .foregroundColor(.white)
                    .frame(width: 36, height: 36)
                    .background(Color.accentColor)
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                // Surah info
                VStack(alignment: .leading, spacing: SafaSpacing.xxs) {
                    Text(surah.nameEnglish)
                        .font(SafaTypography.bodyLarge)
                        .foregroundColor(SafaColors.Fallback.text)

                    HStack(spacing: SafaSpacing.xs) {
                        Text(surah.revelationType.rawValue)
                        Text("•")
                        Text("\(surah.ayahCount) ayahs")
                    }
                    .font(SafaTypography.bodySmall)
                    .foregroundColor(SafaColors.Fallback.secondaryText)
                }

                Spacer()

                // Arabic name
                Text(surah.nameArabic)
                    .font(SafaTypography.arabicMedium)
                    .foregroundColor(SafaColors.Fallback.text)
            }
            .padding(.horizontal, SafaSpacing.md)
            .padding(.vertical, SafaSpacing.sm)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Juz Row

private struct JuzRow: View {
    let juz: Juz
    let action: () -> Void

    var body: some View {
        InteractiveCard(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: SafaSpacing.xxs) {
                    Text("Juz \(juz.number)")
                        .font(SafaTypography.titleMedium)
                        .foregroundColor(SafaColors.Fallback.text)

                    Text("Surah \(juz.startSurah):\(juz.startAyah) - \(juz.endSurah):\(juz.endAyah)")
                        .font(SafaTypography.bodySmall)
                        .foregroundColor(SafaColors.Fallback.secondaryText)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundColor(SafaColors.Fallback.tertiaryText)
            }
        }
    }
}

// MARK: - Bookmark Row

private struct BookmarkRow: View {
    let bookmark: QuranBookmark
    let action: () -> Void
    let onDelete: () -> Void

    var body: some View {
        InteractiveCard(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: SafaSpacing.xxs) {
                    Text(bookmark.reference)
                        .font(SafaTypography.titleMedium)
                        .foregroundColor(SafaColors.Fallback.text)

                    if let note = bookmark.note {
                        Text(note)
                            .font(SafaTypography.bodySmall)
                            .foregroundColor(SafaColors.Fallback.secondaryText)
                            .lineLimit(1)
                    }

                    Text(bookmark.createdAt.relativeString)
                        .font(SafaTypography.labelSmall)
                        .foregroundColor(SafaColors.Fallback.tertiaryText)
                }

                Spacer()

                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .foregroundColor(SafaColors.Fallback.error)
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        QuranView()
            .environment(Dependencies())
    }
}
