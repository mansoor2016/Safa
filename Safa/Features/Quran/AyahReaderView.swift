// MARK: - AyahReaderView.swift
// PURPOSE: Ayah-by-ayah reader view for a surah
// DEPENDENCIES: SwiftUI

import SwiftUI

struct AyahReaderView: View {
    @Environment(Dependencies.self) private var dependencies
    @Environment(\.dismiss) private var dismiss

    let surahNumber: Int
    var startAyah: Int = 1

    @State private var surah: Surah?
    @State private var ayahs: [Ayah] = []
    @State private var isLoading = true
    @State private var showTranslation = true
    @State private var showTransliteration = false
    @State private var currentAyahIndex = 0
    @State private var bookmarkedAyahs: Set<String> = []
    @State private var error: Error?

    // Legacy initializer for backward compatibility
    init(surah: Surah, startingAyah: Int = 1) {
        self.surahNumber = surah.number
        self.startAyah = startingAyah
        self._surah = State(initialValue: surah)
    }

    init(surahNumber: Int, startAyah: Int = 1) {
        self.surahNumber = surahNumber
        self.startAyah = startAyah
    }

    var body: some View {
        Group {
            if isLoading {
                LoadingView(message: "Loading surah...")
            } else if let error = error {
                errorView(error)
            } else if let surah = surah {
                readerContent(surah: surah)
            } else {
                LoadingView(message: "Loading...")
            }
        }
        .navigationTitle(surah?.nameEnglish ?? "Surah")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Toggle("Show Translation", isOn: $showTranslation)
                    Toggle("Show Transliteration", isOn: $showTransliteration)
                } label: {
                    Image(systemName: "textformat.size")
                }
            }
        }
        .task {
            await loadAyahs()
        }
    }

    // MARK: - Reader Content

    private func readerContent(surah: Surah) -> some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 0) {
                    // Surah header (Bismillah)
                    if surah.number != 9 { // At-Tawbah doesn't have Bismillah
                        surahHeader(surah: surah)
                    }

                    // Ayahs
                    ForEach(Array(ayahs.enumerated()), id: \.element.id) { index, ayah in
                        AyahRow(
                            ayah: ayah,
                            showTranslation: showTranslation,
                            showTransliteration: showTransliteration,
                            isBookmarked: bookmarkedAyahs.contains(ayah.id),
                            onBookmarkToggle: {
                                Task {
                                    await toggleBookmark(ayah)
                                }
                            },
                            onShare: {
                                shareAyah(ayah)
                            }
                        )
                        .id(ayah.ayahNumber)

                        if index < ayahs.count - 1 {
                            Divider()
                                .padding(.horizontal)
                        }
                    }

                    // End of surah
                    endOfSurahView(surah: surah)
                }
            }
            .onAppear {
                if startAyah > 1 {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        withAnimation {
                            proxy.scrollTo(startAyah, anchor: .top)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Surah Header

    private func surahHeader(surah: Surah) -> some View {
        VStack(spacing: SafaSpacing.lg) {
            // Surah name in Arabic
            Text(surah.nameArabic)
                .font(SafaTypography.arabicLargeFallback)
                .foregroundColor(SafaColors.Fallback.text)

            // Bismillah
            Text(IslamicConstants.Phrases.bismillah)
                .font(SafaTypography.arabicMediumFallback)
                .foregroundColor(SafaColors.Fallback.text)
                .padding(.vertical, SafaSpacing.md)

            // Surah info
            HStack(spacing: SafaSpacing.md) {
                Label(surah.revelationType.rawValue, systemImage: "mappin.circle")
                Label("\(surah.ayahCount) Ayahs", systemImage: "text.quote")
            }
            .font(SafaTypography.labelSmall)
            .foregroundColor(SafaColors.Fallback.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(SafaSpacing.xl)
        .background(Color.accentColor.opacity(0.05))
    }

    // MARK: - End of Surah

    private func endOfSurahView(surah: Surah) -> some View {
        VStack(spacing: SafaSpacing.md) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 48))
                .foregroundColor(.green)

            Text("End of \(surah.nameEnglish)")
                .font(SafaTypography.titleMedium)

            if surah.number < 114 {
                SecondaryButton(title: "Next Surah", action: {
                    // Navigate to next surah
                }, fullWidth: false)
            }
        }
        .padding(SafaSpacing.xl)
    }

    // MARK: - Error View

    private func errorView(_ error: Error) -> some View {
        VStack(spacing: SafaSpacing.md) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(SafaColors.Fallback.warning)

            Text("Unable to load surah")
                .font(SafaTypography.titleMedium)

            Text(error.localizedDescription)
                .font(SafaTypography.bodySmall)
                .foregroundColor(SafaColors.Fallback.secondaryText)

            PrimaryButton(title: "Try Again", action: {
                Task { await loadAyahs() }
            }, fullWidth: false)
        }
        .padding()
    }

    // MARK: - Methods

    private func loadAyahs() async {
        isLoading = true
        error = nil

        do {
            // Load surah info if not already set
            if surah == nil {
                let surahs = try await dependencies.quranRepository.getAllSurahs()
                surah = surahs.first { $0.number == surahNumber }
            }

            ayahs = try await dependencies.quranRepository.getAyahs(forSurah: surahNumber)

            // Load bookmarked status
            let bookmarks = try await dependencies.quranRepository.getBookmarks()
            bookmarkedAyahs = Set(bookmarks.filter { $0.surahNumber == surahNumber }.map { "\($0.surahNumber):\($0.ayahNumber)" })

            // Update reading progress
            try await dependencies.quranRepository.updateProgress(surah: surahNumber, ayah: 1)

            isLoading = false
        } catch {
            self.error = error
            isLoading = false
        }
    }

    private func toggleBookmark(_ ayah: Ayah) async {
        do {
            let isCurrentlyBookmarked = bookmarkedAyahs.contains(ayah.id)

            if isCurrentlyBookmarked {
                try await dependencies.quranRepository.removeBookmark(surah: ayah.surahNumber, ayah: ayah.ayahNumber)
                bookmarkedAyahs.remove(ayah.id)
            } else {
                try await dependencies.quranRepository.addBookmark(surah: ayah.surahNumber, ayah: ayah.ayahNumber)
                bookmarkedAyahs.insert(ayah.id)
            }
        } catch {
            self.error = error
        }
    }

    private func shareAyah(_ ayah: Ayah) {
        // TODO: Implement share functionality
    }
}

// MARK: - Ayah Row

private struct AyahRow: View {
    let ayah: Ayah
    let showTranslation: Bool
    let showTransliteration: Bool
    let isBookmarked: Bool
    let onBookmarkToggle: () -> Void
    let onShare: () -> Void

    var body: some View {
        VStack(alignment: .trailing, spacing: SafaSpacing.md) {
            // Ayah number badge
            HStack {
                ayahNumberBadge
                Spacer()
                actionButtons
            }

            // Arabic text
            Text(ayah.textArabic)
                .font(SafaTypography.arabicLargeFallback)
                .foregroundColor(SafaColors.Fallback.text)
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .environment(\.layoutDirection, .rightToLeft)

            // Transliteration
            if showTransliteration, let transliteration = ayah.textTransliteration {
                Text(transliteration)
                    .font(SafaTypography.bodyMedium)
                    .foregroundColor(SafaColors.Fallback.secondaryText)
                    .italic()
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            // Translation
            if showTranslation {
                Text(ayah.textTranslation)
                    .font(SafaTypography.bodyMedium)
                    .foregroundColor(SafaColors.Fallback.text)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(SafaSpacing.md)
    }

    private var ayahNumberBadge: some View {
        Text("\(ayah.ayahNumber)")
            .font(SafaTypography.labelSmall)
            .foregroundColor(.white)
            .frame(width: 28, height: 28)
            .background(Color.accentColor)
            .clipShape(Circle())
    }

    private var actionButtons: some View {
        HStack(spacing: SafaSpacing.sm) {
            Button(action: onBookmarkToggle) {
                Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
                    .foregroundColor(isBookmarked ? .accentColor : SafaColors.Fallback.tertiaryText)
            }

            Button(action: onShare) {
                Image(systemName: "square.and.arrow.up")
                    .foregroundColor(SafaColors.Fallback.tertiaryText)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        AyahReaderView(surahNumber: 1)
            .environment(Dependencies())
    }
}
