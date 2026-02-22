// MARK: - RamadanDuasView.swift
// PURPOSE: Collection of Ramadan-specific duas (Iftar, Suhoor, Taraweeh, Laylatul Qadr)
// DEPENDENCIES: SwiftUI, DuaRepositoryProtocol

import SwiftUI

// MARK: - Ramadan Dua Occasion

enum RamadanDuaOccasion: String, CaseIterable {
    case iftar = "Iftar"
    case suhoor = "Suhoor"
    case taraweeh = "Taraweeh"
    case laylatulQadr = "Laylatul Qadr"

    var iconName: String {
        switch self {
        case .iftar: return "sunset.fill"
        case .suhoor: return "sunrise.fill"
        case .taraweeh: return "moon.stars.fill"
        case .laylatulQadr: return "sparkles"
        }
    }

    var color: Color {
        switch self {
        case .iftar: return .orange
        case .suhoor: return .blue
        case .taraweeh: return .purple
        case .laylatulQadr: return .yellow
        }
    }
}

// MARK: - Ramadan Duas View

struct RamadanDuasView: View {
    @Environment(Dependencies.self) private var dependencies
    @State private var selectedOccasion: RamadanDuaOccasion = .iftar
    @State private var ramadanDuas: [Dua] = []

    var body: some View {
        ScrollView {
            VStack(spacing: SafaSpacing.lg) {
                occasionPicker

                ForEach(filteredDuas) { dua in
                    RamadanDuaCard(dua: dua, occasion: occasionFor(dua))
                }
            }
            .padding()
        }
        .navigationTitle("Ramadan Duas")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(UIColor.systemGroupedBackground))
        .task {
            ramadanDuas = (try? await dependencies.duaRepository.getDuas(forCategory: "ramadan")) ?? []
        }
    }

    // MARK: - Occasion Picker

    private var occasionPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: SafaSpacing.sm) {
                ForEach(RamadanDuaOccasion.allCases, id: \.self) { occasion in
                    occasionButton(occasion)
                }
            }
            .padding(.horizontal, SafaSpacing.xs)
        }
    }

    private func occasionButton(_ occasion: RamadanDuaOccasion) -> some View {
        Button {
            withAnimation {
                selectedOccasion = occasion
            }
        } label: {
            HStack(spacing: SafaSpacing.xs) {
                Image(systemName: occasion.iconName)
                    .font(.subheadline)

                Text(occasion.rawValue)
                    .font(SafaTypography.labelMedium)
            }
            .padding(.horizontal, SafaSpacing.md)
            .padding(.vertical, SafaSpacing.sm)
            .background(
                selectedOccasion == occasion
                    ? occasion.color
                    : Color(UIColor.secondarySystemBackground)
            )
            .foregroundColor(
                selectedOccasion == occasion
                    ? .white
                    : SafaColors.Fallback.text
            )
            .clipShape(Capsule())
        }
    }

    // MARK: - Filtered Duas

    private var filteredDuas: [Dua] {
        ramadanDuas.filter { $0.occasion == selectedOccasion.rawValue }
    }

    private func occasionFor(_ dua: Dua) -> RamadanDuaOccasion {
        RamadanDuaOccasion(rawValue: dua.occasion ?? "") ?? .iftar
    }
}

// MARK: - Ramadan Dua Card

struct RamadanDuaCard: View {
    let dua: Dua
    let occasion: RamadanDuaOccasion
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: SafaSpacing.md) {
            // Header
            HStack {
                Image(systemName: occasion.iconName)
                    .foregroundColor(occasion.color)

                VStack(alignment: .leading, spacing: 2) {
                    Text(dua.titleEnglish)
                        .font(SafaTypography.titleSmall)
                        .foregroundColor(SafaColors.Fallback.text)

                    if let titleArabic = dua.titleArabic {
                        Text(titleArabic)
                            .font(SafaTypography.arabicSmall)
                            .foregroundColor(SafaColors.Fallback.secondaryText)
                    }
                }

                Spacer()

                Button {
                    withAnimation {
                        isExpanded.toggle()
                    }
                } label: {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(SafaColors.Fallback.tertiaryText)
                }
            }

            // Arabic text
            Text(dua.textArabic)
                .font(SafaTypography.arabicMedium)
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .foregroundColor(SafaColors.Fallback.text)
                .environment(\.layoutDirection, .rightToLeft)
                .accessibilityArabic()

            if isExpanded {
                Divider()

                // Transliteration
                VStack(alignment: .leading, spacing: SafaSpacing.xs) {
                    Text("Transliteration")
                        .font(SafaTypography.labelSmall)
                        .foregroundColor(SafaColors.Fallback.tertiaryText)

                    Text(dua.textTransliteration)
                        .font(SafaTypography.bodyMedium)
                        .italic()
                        .foregroundColor(SafaColors.Fallback.secondaryText)
                }

                // Translation
                VStack(alignment: .leading, spacing: SafaSpacing.xs) {
                    Text("Translation")
                        .font(SafaTypography.labelSmall)
                        .foregroundColor(SafaColors.Fallback.tertiaryText)

                    Text(dua.textTranslation)
                        .font(SafaTypography.bodyMedium)
                        .foregroundColor(SafaColors.Fallback.text)
                }

                // Source
                if let source = dua.source {
                    Text("Source: \(source)")
                        .font(SafaTypography.labelSmall)
                        .foregroundColor(SafaColors.Fallback.tertiaryText)
                }
            }
        }
        .padding(SafaSpacing.md)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: SafaSpacing.CornerRadius.md))
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        RamadanDuasView()
    }
}
