// MARK: - AyahReaderView.swift
// PURPOSE: Ayah-by-ayah reader view for a surah
// DEPENDENCIES: SwiftUI, AyahReaderViewModel

import SwiftUI
import UIKit

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
    @State private var autoScrollTimer: Timer?
    @State private var currentScrollIndex = 0
    @State private var isAutoScrollControlVisible = true
    @State private var autoHideTask: Task<Void, Never>?
    @State private var autoScrollEnabled = false

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
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                HStack(spacing: 8) {
                    Text(viewModel.surah?.nameEnglish ?? "Surah")
                        .font(SafaTypography.titleSmall)
                    CircularProgressRing(
                        progress: viewModel.progressFraction,
                        size: 20,
                        lineWidth: 2.5,
                        progressColor: viewModel.isSurahComplete ? .green : .accentColor
                    )
                    .contextMenu {
                        ForEach(ProgressRingMode.allCases, id: \.self) { mode in
                            Button {
                                viewModel.progressRingMode = mode
                            } label: {
                                Label(
                                    mode.label,
                                    systemImage: viewModel.progressRingMode == mode
                                        ? "checkmark.circle.fill"
                                        : "circle"
                                )
                            }
                        }
                        Divider()
                        Button(role: .destructive) {
                            viewModel.resetProgress()
                        } label: {
                            Label("Reset Progress", systemImage: "arrow.counterclockwise")
                        }
                    }
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Toggle("Show Translation", isOn: $viewModel.showTranslation)

                    Menu("Arabic Text Size") {
                        Picker("Arabic Text Size", selection: $viewModel.fontPreferences.arabicFontSize) {
                            ForEach(QuranFontPreferences.ArabicFontSize.allCases, id: \.self) { size in
                                Text(size.label).tag(size)
                            }
                        }
                    }

                    Menu("Translation Text Size") {
                        Picker("Translation Text Size", selection: $viewModel.fontPreferences.translationFontSize) {
                            ForEach(QuranFontPreferences.TranslationFontSize.allCases, id: \.self) { size in
                                Text(size.label).tag(size)
                            }
                        }
                    }
                } label: {
                    Image(systemName: "textformat.size")
                }
            }
        }
    }

    // MARK: - Reader Content

    private func readerContent(surah: Surah) -> some View {
        ScrollViewReader { proxy in
            ZStack(alignment: .bottom) {
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
                                surahName: surah.nameEnglish,
                                showTranslation: viewModel.showTranslation,
                                isBookmarked: viewModel.isBookmarked(ayah),
                                arabicFontSize: viewModel.fontPreferences.arabicFontSize.pointSize,
                                translationFontSize: viewModel.fontPreferences.translationFontSize.pointSize,
                                onBookmarkToggle: {
                                    Task {
                                        let wasAdded = await viewModel.toggleBookmark(ayah)
                                        let message = wasAdded
                                            ? "Ayah \(ayah.reference) bookmarked"
                                            : "Bookmark removed"
                                        let toast = Toast.undoAction(message: message) {
                                            Task { await viewModel.toggleBookmark(ayah) }
                                        }
                                        ToastService.shared.show(toast)
                                    }
                                }
                            )
                            .id(ayah.ayahNumber)
                            .onAppear { viewModel.markAyahVisible(ayah.ayahNumber) }

                            if index < viewModel.ayahs.count - 1 {
                                Divider()
                                    .padding(.horizontal)
                            }
                        }

                        // End of surah
                        endOfSurahView(surah: surah)
                    }
                }
                .background(SafaSurface.quranReading.color)
                .accessibilityRotor("Ayahs") {
                    ForEach(viewModel.ayahs, id: \.id) { ayah in
                        AccessibilityRotorEntry(
                            "Ayah \(ayah.ayahNumber)",
                            id: ayah.ayahNumber
                        )
                    }
                }
                .accessibilityRotor("Bookmarks") {
                    ForEach(viewModel.ayahs.filter { viewModel.isBookmarked($0) }, id: \.id) { ayah in
                        AccessibilityRotorEntry(
                            "Ayah \(ayah.ayahNumber), bookmarked",
                            id: ayah.ayahNumber
                        )
                    }
                }

                // Auto-scroll control (only visible if enabled in settings)
                if autoScrollEnabled {
                    AutoScrollControl(
                        isScrolling: viewModel.isAutoScrolling,
                        speed: viewModel.autoScrollSpeed,
                        onToggle: { toggleAutoScroll(proxy: proxy) },
                        onSpeedChange: { newSpeed in
                            viewModel.autoScrollSpeed = newSpeed
                            if viewModel.isAutoScrolling {
                                restartAutoScroll(proxy: proxy)
                            }
                            resetAutoHideTimer()
                        }
                    )
                    .padding(.bottom, SafaSpacing.lg)
                    .opacity(isAutoScrollControlVisible ? 1 : 0)
                    .animation(.easeInOut(duration: 0.3), value: isAutoScrollControlVisible)
                    .onTapGesture {
                        // Tapping the control makes it stay visible
                        resetAutoHideTimer()
                    }
                }
            }
            .onAppear {
                loadAutoScrollSetting()
                if viewModel.startAyah > 1 {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        withAnimation {
                            proxy.scrollTo(viewModel.startAyah, anchor: .top)
                        }
                    }
                }
            }
            .onDisappear {
                stopAutoScroll()
                autoHideTask?.cancel()
                autoHideTask = nil
            }
        }
    }

    // MARK: - Auto Scroll Settings

    private func loadAutoScrollSetting() {
        let prefs = PreferencesManager.loadPreferencesSync()
        autoScrollEnabled = prefs.autoScrollEnabled
    }

    private func resetAutoHideTimer() {
        autoHideTask?.cancel()
        isAutoScrollControlVisible = true
        autoHideTask = Task {
            try? await Task.sleep(for: .seconds(7))
            if !viewModel.isAutoScrolling {
                withAnimation {
                    isAutoScrollControlVisible = false
                }
            }
        }
    }

    // MARK: - Auto Scroll

    private func toggleAutoScroll(proxy: ScrollViewProxy) {
        resetAutoHideTimer()
        if viewModel.isAutoScrolling {
            stopAutoScroll()
        } else {
            startAutoScroll(proxy: proxy)
        }
    }

    private func startAutoScroll(proxy: ScrollViewProxy) {
        viewModel.isAutoScrolling = true
        currentScrollIndex = 0
        isAutoScrollControlVisible = true // Keep visible while scrolling
        autoHideTask?.cancel()
        scheduleNextAyahScroll(proxy: proxy)
        UIAccessibility.post(notification: .announcement, argument: "Auto scroll started")
    }

    private func restartAutoScroll(proxy: ScrollViewProxy) {
        autoScrollTimer?.invalidate()
        autoScrollTimer = nil
        scheduleNextAyahScroll(proxy: proxy)
    }

    private func scheduleNextAyahScroll(proxy: ScrollViewProxy) {
        guard currentScrollIndex < viewModel.ayahs.count else {
            stopAutoScroll()
            return
        }
        let currentAyah = viewModel.ayahs[currentScrollIndex]
        let interval = viewModel.scrollIntervalForAyah(currentAyah)
        autoScrollTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { _ in
            Task { @MainActor in
                self.scrollToNextAyah(proxy: proxy)
            }
        }
    }

    private func stopAutoScroll() {
        viewModel.isAutoScrolling = false
        autoScrollTimer?.invalidate()
        autoScrollTimer = nil
        UIAccessibility.post(notification: .announcement, argument: "Auto scroll stopped")
    }

    private func scrollToNextAyah(proxy: ScrollViewProxy) {
        currentScrollIndex += 1
        guard currentScrollIndex < viewModel.ayahs.count else {
            Task { await viewModel.markAllAyahsRead() }
            stopAutoScroll()
            return
        }
        let ayahNumber = viewModel.ayahs[currentScrollIndex].ayahNumber
        withAnimation(.easeInOut(duration: 0.5)) {
            proxy.scrollTo(ayahNumber, anchor: .top)
        }
        scheduleNextAyahScroll(proxy: proxy)
    }

    // MARK: - Surah Header

    private func surahHeader(surah: Surah) -> some View {
        VStack(spacing: SafaSpacing.lg) {
            Text(surah.nameArabic)
                .font(SafaTypography.arabicLarge)
                .foregroundColor(SafaColors.Fallback.text)
                .accessibilityArabic()

            Text(IslamicConstants.Phrases.bismillah)
                .font(SafaTypography.arabicMedium)
                .foregroundColor(SafaColors.Fallback.text)
                .padding(.vertical, SafaSpacing.md)
                .accessibilityArabic(label: "Bismillah ir-Rahman ir-Raheem")

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
        .accessibilityGrouped(label: "\(surah.nameEnglish), \(surah.revelationType.rawValue), \(surah.ayahCount) ayahs")
    }

    // MARK: - End of Surah

    private func endOfSurahView(surah: Surah) -> some View {
        VStack(spacing: SafaSpacing.md) {
            Image(systemName: viewModel.isSurahComplete ? "checkmark.circle.fill" : "star.fill")
                .font(.system(size: 48))
                .foregroundColor(viewModel.isSurahComplete ? .green : SafaColors.Fallback.tertiaryText)
                .accessibilityHidden(true)

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
        .accessibilityElement(children: .contain)
        .accessibilityLabel("End of \(surah.nameEnglish)\(viewModel.isSurahComplete ? ", reading complete" : "")")
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
    let surahName: String
    let showTranslation: Bool
    let isBookmarked: Bool
    let arabicFontSize: CGFloat
    let translationFontSize: CGFloat
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
                .font(.system(size: arabicFontSize, weight: .medium, design: .serif))
                .foregroundColor(SafaColors.Fallback.text)
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .environment(\.layoutDirection, .rightToLeft)
                .accessibilityArabic()

            // Translation
            if showTranslation {
                Text(ayah.textTranslation)
                    .font(.system(size: translationFontSize))
                    .foregroundColor(SafaColors.Fallback.text)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(SafaSpacing.md)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(formatAyahAccessibilityLabel(
            surahName: surahName,
            ayahNumber: ayah.ayahNumber,
            translation: showTranslation ? ayah.textTranslation : nil
        ))
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        AyahReaderView(surahNumber: 1)
            .environment(Dependencies())
    }
}
