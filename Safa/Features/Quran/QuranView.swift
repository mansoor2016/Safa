// MARK: - QuranView.swift
// PURPOSE: Main Quran reader entry view with surah list
// DEPENDENCIES: SwiftUI, QuranViewModel

import SwiftUI

struct QuranView: View {
    @Environment(Dependencies.self) private var dependencies
    @Environment(AppRouter.self) private var router
    @State private var viewModel: QuranViewModel
    @State private var path = NavigationPath()
    @Namespace private var surahZoom

    init() {
        _viewModel = State(initialValue: QuranViewModel(
            quranRepository: Dependencies.shared.quranRepository,
            userState: Dependencies.shared.userState
        ))
    }

    var body: some View {
        NavigationStack(path: $path) {
            QuranContentView(viewModel: viewModel, path: $path, surahZoom: surahZoom)
                .navigationDestination(for: QuranNavigationTarget.self) { target in
                    AyahReaderView(surahNumber: target.surahNumber, startAyah: target.startAyah)
                        .modifier(ZoomTransitionModifier(sourceID: target.surahNumber, namespace: surahZoom))
                }
        }
        .onChange(of: router.pendingQuranTarget) { _, target in
            consumePendingTarget(target)
        }
        .onAppear {
            consumePendingTarget(router.pendingQuranTarget)
        }
    }

    private func consumePendingTarget(_ target: QuranNavigationTarget?) {
        if let target {
            path.append(target)
            router.pendingQuranTarget = nil
        }
    }
}

// MARK: - Quran Content View

private struct QuranContentView: View {
    @Bindable var viewModel: QuranViewModel
    @Binding var path: NavigationPath
    var surahZoom: Namespace.ID
    @State private var selectedTab = 0
    @State private var editingBookmark: QuranBookmark?
    @State private var editNoteText = ""
    @State private var showingSettings = false

    var body: some View {
        Group {
            if viewModel.error != nil {
                ErrorView.loadFailed(retry: { await viewModel.loadSurahs() })
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        // Tab selector
                        Picker("View", selection: $selectedTab) {
                            Text("Surahs").tag(0)
                            Text("Juz").tag(1)
                            Text("Bookmarks").tag(2)
                        }
                        .pickerStyle(.segmented)
                        .padding()

                        // Content
                        switch selectedTab {
                        case 0: surahContent
                        case 1: juzContent
                        case 2: bookmarksContent
                        default: EmptyView()
                        }
                    }
                }
            }
        }
        .navigationTitle("Quran")
        .navigationBarTitleDisplayMode(.large)
        .searchable(text: $viewModel.searchQuery, prompt: "Search surahs...")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingSettings = true
                } label: {
                    Image(systemName: "gearshape")
                }
            }
        }
        .sheet(isPresented: $showingSettings) {
            NavigationStack {
                QuranSettingsView()
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("Done") { showingSettings = false }
                        }
                    }
            }
            .fullSheet()
        }
        .task {
            await viewModel.loadSurahs()
        }
        .onAppear {
            Task {
                await viewModel.refreshReadingProgress()
                await viewModel.loadCompletedSurahs()
            }
        }
    }

    // MARK: - Surah Content

    private var surahContent: some View {
        Group {
            // Resume reading card
            if let progress = viewModel.readingProgress {
                ResumeReadingCard(
                    surahNumber: progress.lastSurah,
                    ayahNumber: progress.lastAyah,
                    surahName: viewModel.getSurahName(progress.lastSurah)
                ) {
                    path.append(QuranNavigationTarget(
                        surahNumber: progress.lastSurah,
                        startAyah: progress.lastAyah
                    ))
                }
                .padding()
            }

            ForEach(viewModel.filteredSurahs) { surah in
                NavigationLink(value: QuranNavigationTarget(surahNumber: surah.number)) {
                    SurahRow(
                        surah: surah,
                        isComplete: viewModel.completedSurahs.contains(surah.number),
                        onToggleComplete: {
                            Task { await viewModel.toggleSurahCompletion(surah.number) }
                        }
                    )
                }
                .buttonStyle(.plain)
                .modifier(MatchedTransitionSourceModifier(id: surah.number, namespace: surahZoom))

                Divider()
                    .padding(.leading, SafaSpacing.xl + SafaSpacing.md)
            }
        }
    }

    // MARK: - Juz Content

    private var juzContent: some View {
        LazyVStack(spacing: SafaSpacing.sm) {
            ForEach(viewModel.juzList) { juz in
                JuzRow(juz: juz) {
                    if let target = viewModel.navigationTargetForJuz(juz.number) {
                        path.append(target)
                    }
                }
            }
        }
        .padding()
        .task {
            await viewModel.loadJuz()
        }
    }

    // MARK: - Bookmarks Content

    private var bookmarksContent: some View {
        Group {
            if viewModel.bookmarks.isEmpty {
                EmptyStateView.noBookmarks
            } else {
                LazyVStack(spacing: SafaSpacing.sm) {
                    ForEach(viewModel.bookmarks) { bookmark in
                        BookmarkRow(bookmark: bookmark) {
                            path.append(QuranNavigationTarget(
                                surahNumber: bookmark.surahNumber,
                                startAyah: bookmark.ayahNumber
                            ))
                        } onEditNote: {
                            editNoteText = bookmark.note ?? ""
                            editingBookmark = bookmark
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
        .task {
            await viewModel.loadBookmarks()
        }
        .alert("Edit Note", isPresented: Binding(
            get: { editingBookmark != nil },
            set: { if !$0 { editingBookmark = nil } }
        )) {
            TextField("Add a note...", text: $editNoteText)
            Button("Save") {
                if let bookmark = editingBookmark {
                    Task {
                        await viewModel.updateBookmarkNote(bookmark, note: editNoteText)
                    }
                }
                editingBookmark = nil
            }
            Button("Cancel", role: .cancel) {
                editingBookmark = nil
            }
        } message: {
            if let bookmark = editingBookmark {
                Text("Note for \(bookmark.reference)")
            }
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
                    .accessibilityHidden(true)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Continue reading \(surahName) from ayah \(ayahNumber)")
        .accessibilityHint("Double tap to resume reading")
    }
}

// MARK: - Surah Row

private struct SurahRow: View {
    let surah: Surah
    let isComplete: Bool
    let onToggleComplete: () -> Void

    var body: some View {
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
                    Text("\u{2022}")
                    Text("\(surah.ayahCount) ayahs")
                }
                .font(SafaTypography.bodySmall)
                .foregroundColor(SafaColors.Fallback.secondaryText)
            }

            Spacer()

            // Completion indicator (tappable to toggle)
            Button {
                onToggleComplete()
            } label: {
                Image(systemName: isComplete ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isComplete ? .green : SafaColors.Fallback.tertiaryText)
                    .font(.system(size: 18))
                    .frame(width: 24)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(isComplete ? "Completed" : "Not completed")
            .accessibilityHint("Double tap to mark as \(isComplete ? "unread" : "read")")

            // Arabic name
            Text(surah.nameArabic)
                .font(SafaTypography.arabicMedium)
                .foregroundColor(SafaColors.Fallback.text)
                .frame(width: 90, alignment: .trailing)
        }
        .padding(.horizontal, SafaSpacing.md)
        .padding(.vertical, SafaSpacing.sm)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Surah \(surah.number), \(surah.nameEnglish), \(surah.revelationType.rawValue), \(surah.ayahCount) verses\(isComplete ? ", completed" : "")")
        .accessibilityHint("Double tap to read this surah")
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
                    .accessibilityHidden(true)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Juz \(juz.number), from Surah \(juz.startSurah) ayah \(juz.startAyah) to Surah \(juz.endSurah) ayah \(juz.endAyah)")
        .accessibilityHint("Double tap to read this juz")
    }
}

// MARK: - Bookmark Row

private struct BookmarkRow: View {
    let bookmark: QuranBookmark
    let action: () -> Void
    let onEditNote: () -> Void
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

                Button(action: onEditNote) {
                    Image(systemName: "pencil")
                        .foregroundColor(SafaColors.Fallback.secondaryText)
                }
                .accessibilityLabel("Edit note")
                .accessibilityHint("Double tap to edit bookmark note")

                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .foregroundColor(SafaColors.Fallback.error)
                }
                .accessibilityLabel("Delete bookmark")
                .accessibilityHint("Double tap to remove this bookmark")
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(bookmarkAccessibilityLabel)
        .accessibilityHint("Double tap to go to this ayah")
    }

    private var bookmarkAccessibilityLabel: String {
        var label = "Bookmark at \(bookmark.reference)"
        if let note = bookmark.note {
            label += ", note: \(note)"
        }
        label += ", bookmarked \(bookmark.createdAt.relativeString)"
        return label
    }
}

// MARK: - iOS 18+ Transition Wrappers

/// Wraps `.navigationTransition(.zoom())` which requires iOS 18+.
/// On iOS 17, navigation uses the default push transition.
private struct ZoomTransitionModifier: ViewModifier {
    let sourceID: Int
    let namespace: Namespace.ID

    func body(content: Content) -> some View {
        if #available(iOS 18.0, *) {
            content
                .navigationTransition(.zoom(sourceID: sourceID, in: namespace))
        } else {
            content
        }
    }
}

/// Wraps `.matchedTransitionSource()` which requires iOS 18+.
/// On iOS 17, no matched geometry source is set (standard navigation).
private struct MatchedTransitionSourceModifier: ViewModifier {
    let id: Int
    let namespace: Namespace.ID

    func body(content: Content) -> some View {
        if #available(iOS 18.0, *) {
            content
                .matchedTransitionSource(id: id, in: namespace)
        } else {
            content
        }
    }
}

// MARK: - Preview

#Preview {
    QuranView()
        .environment(Dependencies())
        .environment(AppRouter())
}
