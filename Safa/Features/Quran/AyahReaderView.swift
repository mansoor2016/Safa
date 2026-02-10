// MARK: - AyahReaderView.swift
// PURPOSE: Ayah-by-ayah reader view for a surah
// DEPENDENCIES: SwiftUI, AyahReaderViewModel

import SwiftUI

struct AyahReaderView: View {
    @Environment(Dependencies.self) private var dependencies
    @State private var viewModel: AyahReaderViewModel?

    let surahNumber: Int
    var startAyah: Int = 1

    init(surahNumber: Int, startAyah: Int = 1) {
        self.surahNumber = surahNumber
        self.startAyah = startAyah
    }

    var body: some View {
        Group {
            if let viewModel = viewModel {
                AyahReaderContent(viewModel: viewModel)
            } else {
                LoadingView(message: "Loading surah...")
            }
        }
        .task {
            if viewModel == nil {
                viewModel = AyahReaderViewModel(
                    surahNumber: surahNumber,
                    startAyah: startAyah,
                    repository: dependencies.quranRepository
                )
                await viewModel?.loadAyahs()
            }
        }
    }
}

// MARK: - Reader Content

private struct AyahReaderContent: View {
    @Bindable var viewModel: AyahReaderViewModel

    var body: some View {
        Group {
            if viewModel.isLoading {
                LoadingView(message: "Loading surah...")
            } else if let error = viewModel.error {
                errorView(error)
            } else if let surah = viewModel.surah {
                readerContent(surah: surah)
            } else {
                LoadingView(message: "Loading...")
            }
        }
        .navigationTitle(viewModel.surah?.nameEnglish ?? "Surah")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Toggle("Show Translation", isOn: $viewModel.showTranslation)
                } label: {
                    Image(systemName: "textformat.size")
                }
            }
        }
    }

    // MARK: - Reader Content

    private func readerContent(surah: Surah) -> some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 0) {
                    // Surah header (Bismillah)
                    if surah.number != 9 {
                        surahHeader(surah: surah)
                    }

                    // Ayahs
                    ForEach(Array(viewModel.ayahs.enumerated()), id: \.element.id) { index, ayah in
                        AyahRow(
                            ayah: ayah,
                            showTranslation: viewModel.showTranslation,
                            isBookmarked: viewModel.isBookmarked(ayah),
                            onBookmarkToggle: {
                                Task { await viewModel.toggleBookmark(ayah) }
                            }
                        )
                        .id(ayah.ayahNumber)

                        if index < viewModel.ayahs.count - 1 {
                            Divider()
                                .padding(.horizontal)
                        }
                    }

                    // End of surah
                    endOfSurahView(surah: surah)
                }
            }
            .onAppear {
                if viewModel.startAyah > 1 {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        withAnimation {
                            proxy.scrollTo(viewModel.startAyah, anchor: .top)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Surah Header

    private func surahHeader(surah: Surah) -> some View {
        VStack(spacing: SafaSpacing.lg) {
            Text(surah.nameArabic)
                .font(SafaTypography.arabicLarge)
                .foregroundColor(SafaColors.Fallback.text)

            Text(IslamicConstants.Phrases.bismillah)
                .font(SafaTypography.arabicMedium)
                .foregroundColor(SafaColors.Fallback.text)
                .padding(.vertical, SafaSpacing.md)

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
            Image(systemName: "star.fill")
                .font(.system(size: 48))
                .foregroundColor(SafaColors.Fallback.tertiaryText)

            Text("End of \(surah.nameEnglish)")
                .font(SafaTypography.titleMedium)

            if viewModel.hasNextSurah {
                NavigationLink(value: QuranNavigationTarget(surahNumber: viewModel.nextSurahNumber)) {
                    Text("Next Surah")
                        .font(SafaTypography.labelMedium)
                        .padding(.horizontal, SafaSpacing.lg)
                        .padding(.vertical, SafaSpacing.sm)
                        .background(Color.accentColor.opacity(0.1))
                        .foregroundColor(.accentColor)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
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
                Task { await viewModel.loadAyahs() }
            }, fullWidth: false)
        }
        .padding()
    }
}

// MARK: - Ayah Row

private struct AyahRow: View {
    let ayah: Ayah
    let showTranslation: Bool
    let isBookmarked: Bool
    let onBookmarkToggle: () -> Void

    var body: some View {
        VStack(alignment: .trailing, spacing: SafaSpacing.md) {
            // Tappable ayah number badge (toggles bookmark)
            HStack {
                Button(action: onBookmarkToggle) {
                    Text("\(ayah.ayahNumber)")
                        .font(SafaTypography.labelSmall)
                        .foregroundColor(isBookmarked ? .white : SafaColors.Fallback.tertiaryText)
                        .frame(width: 28, height: 28)
                        .background(isBookmarked ? Color.accentColor : Color.clear)
                        .overlay {
                            Circle()
                                .strokeBorder(
                                    isBookmarked ? Color.accentColor : SafaColors.Fallback.tertiaryText,
                                    lineWidth: 1.5
                                )
                        }
                        .clipShape(Circle())
                }
                .accessibilityLabel(isBookmarked ? "Ayah \(ayah.ayahNumber), bookmarked" : "Ayah \(ayah.ayahNumber)")
                .accessibilityHint(isBookmarked ? "Double tap to remove bookmark" : "Double tap to bookmark")

                Spacer()
            }

            // Arabic text
            Text(ayah.textArabic)
                .font(SafaTypography.arabicLarge)
                .foregroundColor(SafaColors.Fallback.text)
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .environment(\.layoutDirection, .rightToLeft)

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
}

// MARK: - Preview

#Preview {
    NavigationStack {
        AyahReaderView(surahNumber: 1)
            .environment(Dependencies())
    }
}
