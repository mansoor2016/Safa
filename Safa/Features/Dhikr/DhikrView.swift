// MARK: - DhikrView.swift
// PURPOSE: Dhikr and Tasbeeh counter view
// DEPENDENCIES: SwiftUI

import SwiftUI

struct DhikrView: View {
    @Environment(Dependencies.self) private var dependencies
    @State private var selectedTab = 0
    @State private var showTasbeehCounter = false
    @State private var selectedDhikr: CommonDhikr = .subhanAllah

    var body: some View {
        VStack(spacing: 0) {
            // Tab selector
            Picker("View", selection: $selectedTab) {
                Text("Tasbeeh").tag(0)
                Text("Morning").tag(1)
                Text("Evening").tag(2)
                Text("Sleep").tag(3)
            }
            .pickerStyle(.segmented)
            .padding()

            // Content
            TabView(selection: $selectedTab) {
                tasbeehView.tag(0)
                dhikrListView(type: .morning).tag(1)
                dhikrListView(type: .evening).tag(2)
                dhikrListView(type: .sleep).tag(3)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
        }
        .navigationTitle("Dhikr")
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showTasbeehCounter) {
            TasbeehCounterView(dhikr: selectedDhikr)
                .environment(dependencies)
                .compactSheet()
        }
    }

    // MARK: - Tasbeeh View

    private var tasbeehView: some View {
        ScrollView {
            VStack(spacing: SafaSpacing.lg) {
                // Quick start with common dhikr
                TitledCard(title: "Quick Start", subtitle: "Tap to begin counting") {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: SafaSpacing.md) {
                        ForEach(CommonDhikr.allCases, id: \.rawValue) { dhikr in
                            DhikrQuickButton(dhikr: dhikr) {
                                selectedDhikr = dhikr
                                showTasbeehCounter = true
                            }
                        }
                    }
                }

                // Recent sessions
                TitledCard(title: "After Prayer Tasbeeh", subtitle: "33x each") {
                    VStack(spacing: SafaSpacing.sm) {
                        AfterPrayerRow(
                            title: "SubhanAllah",
                            arabic: IslamicConstants.Phrases.subhanAllah,
                            count: 33
                        ) {
                            selectedDhikr = .subhanAllah
                            showTasbeehCounter = true
                        }

                        Divider()

                        AfterPrayerRow(
                            title: "Alhamdulillah",
                            arabic: IslamicConstants.Phrases.alhamdulillah,
                            count: 33
                        ) {
                            selectedDhikr = .alhamdulillah
                            showTasbeehCounter = true
                        }

                        Divider()

                        AfterPrayerRow(
                            title: "Allahu Akbar",
                            arabic: IslamicConstants.Phrases.allahuAkbar,
                            count: 34
                        ) {
                            selectedDhikr = .allahuAkbar
                            showTasbeehCounter = true
                        }
                    }
                }
            }
            .padding()
        }
    }

    // MARK: - Dhikr List View

    private func dhikrListView(type: DhikrType) -> some View {
        DhikrListView(type: type)
            .environment(dependencies)
    }
}

// MARK: - Dhikr Quick Button

private struct DhikrQuickButton: View {
    let dhikr: CommonDhikr
    let action: () -> Void

    var body: some View {
        Button(action: {
            HapticFeedbackService.shared.play(.commit)
            action()
        }) {
            VStack(spacing: SafaSpacing.xs) {
                Text(dhikr.arabic)
                    .font(SafaTypography.arabicSmall)
                    .foregroundColor(SafaColors.Fallback.text)
                    .environment(\.layoutDirection, .rightToLeft)

                Text(dhikr.rawValue)
                    .font(SafaTypography.labelSmall)
                    .foregroundColor(SafaColors.Fallback.secondaryText)

                Text("×\(dhikr.defaultCount)")
                    .font(SafaTypography.labelSmall)
                    .foregroundColor(.accentColor)
            }
            .frame(maxWidth: .infinity)
            .padding(SafaSpacing.md)
            .background(Color(UIColor.tertiarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: SafaSpacing.CornerRadius.md))
        }
    }
}

// MARK: - After Prayer Row

private struct AfterPrayerRow: View {
    let title: String
    let arabic: String
    let count: Int
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: SafaSpacing.xxs) {
                    Text(title)
                        .font(SafaTypography.bodyMedium)
                        .foregroundColor(SafaColors.Fallback.text)

                    Text(arabic)
                        .font(SafaTypography.arabicSmall)
                        .foregroundColor(SafaColors.Fallback.secondaryText)
                        .environment(\.layoutDirection, .rightToLeft)
                }

                Spacer()

                Text("×\(count)")
                    .font(SafaTypography.titleMedium)
                    .foregroundColor(.accentColor)
            }
        }
    }
}

// MARK: - Dhikr List View

private struct DhikrListView: View {
    @Environment(Dependencies.self) private var dependencies

    let type: DhikrType
    @State private var dhikr: [Dua] = []
    @State private var completedIds: Set<String> = []
    @State private var isLoading = true

    var body: some View {
        Group {
            if isLoading {
                LoadingView()
            } else if dhikr.isEmpty {
                EmptyStateView.noDhikr
            } else {
                ScrollView {
                    LazyVStack(spacing: SafaSpacing.sm) {
                        // Progress
                        progressHeader

                        ForEach(dhikr) { dua in
                            DhikrRow(
                                dua: dua,
                                isCompleted: completedIds.contains(dua.id)
                            ) {
                                Task { await markCompleted(dua) }
                            }
                        }
                    }
                    .padding()
                }
            }
        }
        .task {
            await loadDhikr()
        }
    }

    private var progressHeader: some View {
        ContentCard {
            HStack {
                VStack(alignment: .leading) {
                    Text("\(type.rawValue.capitalized) Dhikr")
                        .font(SafaTypography.titleMedium)

                    Text("\(completedIds.count)/\(dhikr.count) completed")
                        .font(SafaTypography.bodySmall)
                        .foregroundColor(SafaColors.Fallback.secondaryText)
                }

                Spacer()

                CircularProgressView(
                    progress: dhikr.isEmpty ? 0 : Double(completedIds.count) / Double(dhikr.count)
                )
            }
        }
    }

    private func loadDhikr() async {
        do {
            switch type {
            case .morning:
                dhikr = try await dependencies.duaRepository.getMorningDhikr()
            case .evening:
                dhikr = try await dependencies.duaRepository.getEveningDhikr()
            case .sleep:
                dhikr = try await dependencies.duaRepository.getSleepDhikr()
            }

            let completed = try await dependencies.duaRepository.getDhikrCompletionStatus(for: type)
            completedIds = Set(completed)

            isLoading = false
        } catch {
            isLoading = false
        }
    }

    private func markCompleted(_ dua: Dua) async {
        do {
            try await dependencies.duaRepository.markDhikrCompleted(dua, type: type)
            completedIds.insert(dua.id)

            // Award Hasanat if all completed
            if completedIds.count == dhikr.count {
                if type == .morning {
                    await dependencies.userState.awardHasanat(.morningDhikr)
                } else if type == .evening {
                    await dependencies.userState.awardHasanat(.eveningDhikr)
                }
                await dependencies.userState.recordActivity(type: .dhikr)
            }
        } catch {
            // Handle error
        }
    }
}

// MARK: - Dhikr Row

private struct DhikrRow: View {
    let dua: Dua
    let isCompleted: Bool
    let onComplete: () -> Void

    @State private var isExpanded = false

    var body: some View {
        ContentCard {
            VStack(alignment: .leading, spacing: SafaSpacing.sm) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: SafaSpacing.xxs) {
                        Text(dua.titleEnglish)
                            .font(SafaTypography.bodyLarge)
                            .foregroundColor(SafaColors.Fallback.text)

                        if dua.repetitions > 1 {
                            Text("×\(dua.repetitions)")
                                .font(SafaTypography.labelSmall)
                                .foregroundColor(.accentColor)
                        }
                    }

                    Spacer()

                    Button(action: onComplete) {
                        Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                            .font(.title2)
                            .foregroundColor(isCompleted ? .green : SafaColors.Fallback.tertiaryText)
                    }
                    .disabled(isCompleted)
                }

                // Arabic text
                Text(dua.textArabic)
                    .font(SafaTypography.arabicMedium)
                    .foregroundColor(SafaColors.Fallback.text)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .environment(\.layoutDirection, .rightToLeft)

                // Expandable content
                if isExpanded {
                    VStack(alignment: .leading, spacing: SafaSpacing.xs) {
                        Text(dua.textTransliteration)
                            .font(SafaTypography.bodySmall)
                            .italic()
                            .foregroundColor(SafaColors.Fallback.secondaryText)

                        Text(dua.textTranslation)
                            .font(SafaTypography.bodyMedium)
                            .foregroundColor(SafaColors.Fallback.text)

                        if let source = dua.source {
                            Text(source)
                                .font(SafaTypography.labelSmall)
                                .foregroundColor(SafaColors.Fallback.tertiaryText)
                        }
                    }
                }

                // Expand button
                Button {
                    withAnimation {
                        isExpanded.toggle()
                    }
                } label: {
                    HStack {
                        Text(isExpanded ? "Show less" : "Show more")
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    }
                    .font(SafaTypography.labelSmall)
                    .foregroundColor(.accentColor)
                }
            }
        }
    }
}

// MARK: - Circular Progress View

private struct CircularProgressView: View {
    let progress: Double

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.gray.opacity(0.2), lineWidth: 6)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                .rotationEffect(.degrees(-90))

            Text("\(Int(progress * 100))%")
                .font(SafaTypography.labelSmall)
                .foregroundColor(SafaColors.Fallback.secondaryText)
        }
        .frame(width: 50, height: 50)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        DhikrView()
            .environment(Dependencies())
    }
}
