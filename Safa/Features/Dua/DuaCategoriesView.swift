// MARK: - DuaCategoriesView.swift
// PURPOSE: Browse duas by category
// DEPENDENCIES: SwiftUI

import SwiftUI

// MARK: - Dua Category Collection (for display)

struct DuaCategoryCollection: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let arabicName: String
    let iconName: String
    let duaCount: Int

    static let sampleCategories: [DuaCategoryCollection] = [
        DuaCategoryCollection(id: "morning_evening", name: "Morning & Evening", arabicName: "أذكار الصباح والمساء", iconName: "sunrise", duaCount: 15),
        DuaCategoryCollection(id: "prayer", name: "Prayer", arabicName: "أدعية الصلاة", iconName: "moon.stars", duaCount: 12),
        DuaCategoryCollection(id: "daily", name: "Daily Activities", arabicName: "أذكار اليومية", iconName: "sun.max", duaCount: 20),
        DuaCategoryCollection(id: "protection", name: "Protection", arabicName: "أدعية الحفظ", iconName: "shield", duaCount: 8),
        DuaCategoryCollection(id: "forgiveness", name: "Forgiveness", arabicName: "أدعية الاستغفار", iconName: "heart", duaCount: 10),
        DuaCategoryCollection(id: "travel", name: "Travel", arabicName: "أذكار السفر", iconName: "airplane", duaCount: 6),
        DuaCategoryCollection(id: "food", name: "Food & Drink", arabicName: "أذكار الطعام", iconName: "fork.knife", duaCount: 8),
        DuaCategoryCollection(id: "sleep", name: "Sleep", arabicName: "أذكار النوم", iconName: "moon.zzz", duaCount: 10),
        DuaCategoryCollection(id: "anxiety", name: "Anxiety & Distress", arabicName: "أدعية الهم والحزن", iconName: "heart.circle", duaCount: 7),
        DuaCategoryCollection(id: "gratitude", name: "Gratitude", arabicName: "أدعية الشكر", iconName: "hands.clap", duaCount: 5)
    ]
}

// MARK: - Dua Categories View Model

@Observable
final class DuaCategoriesViewModel {
    var categories: [DuaCategoryCollection] = []
    var searchText = ""

    var filteredCategories: [DuaCategoryCollection] {
        if searchText.isEmpty {
            return categories
        }
        return categories.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.arabicName.contains(searchText)
        }
    }

    init() {
        loadCategories()
    }

    private func loadCategories() {
        categories = DuaCategoryCollection.sampleCategories
    }
}

// MARK: - Dua Categories View

struct DuaCategoriesView: View {
    @State private var viewModel = DuaCategoriesViewModel()

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                // Header
                headerView

                // Quick Access
                quickAccessSection

                // Search
                searchBar

                // Categories
                categoriesSection
            }
            .padding(.bottom, 100)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Duas")
        .navigationBarTitleDisplayMode(.large)
    }

    private var headerView: some View {
        VStack(spacing: 8) {
            Text("أدعية وأذكار")
                .font(.system(size: 28, weight: .bold, design: .serif))
                .environment(\.layoutDirection, .rightToLeft)

            Text("Supplications & Remembrances")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 20)
    }

    private var quickAccessSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Access")
                .font(.caption)
                .foregroundColor(.secondary)
                .textCase(.uppercase)
                .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    QuickAccessButton(
                        title: "Morning",
                        arabicTitle: "أذكار الصباح",
                        iconName: "sunrise.fill",
                        color: .orange
                    )

                    QuickAccessButton(
                        title: "Evening",
                        arabicTitle: "أذكار المساء",
                        iconName: "sunset.fill",
                        color: .purple
                    )

                    QuickAccessButton(
                        title: "Sleep",
                        arabicTitle: "أذكار النوم",
                        iconName: "moon.zzz.fill",
                        color: .indigo
                    )

                    QuickAccessButton(
                        title: "After Prayer",
                        arabicTitle: "بعد الصلاة",
                        iconName: "hands.sparkles.fill",
                        color: .teal
                    )
                }
                .padding(.horizontal)
            }
        }
    }

    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)

            TextField("Search duas...", text: $viewModel.searchText)
                .textFieldStyle(.plain)

            if !viewModel.searchText.isEmpty {
                Button {
                    viewModel.searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
        .padding(.horizontal)
        .padding(.top, 8)
    }

    private var categoriesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Categories")
                .font(.caption)
                .foregroundColor(.secondary)
                .textCase(.uppercase)
                .padding(.horizontal)

            ForEach(viewModel.filteredCategories) { category in
                NavigationLink(destination: DuaListView(category: category)) {
                    CategoryRow(category: category)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal)
        }
    }
}

// MARK: - Quick Access Button

struct QuickAccessButton: View {
    let title: String
    let arabicTitle: String
    let iconName: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 56, height: 56)

                Image(systemName: iconName)
                    .font(.title2)
                    .foregroundColor(color)
            }

            Text(title)
                .font(.caption)
                .fontWeight(.medium)

            Text(arabicTitle)
                .font(.caption2)
                .foregroundColor(.secondary)
                .environment(\.layoutDirection, .rightToLeft)
        }
        .frame(width: 80)
    }
}

// MARK: - Category Row

struct CategoryRow: View {
    let category: DuaCategoryCollection

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.accentColor.opacity(0.1))
                    .frame(width: 48, height: 48)

                Image(systemName: category.iconName)
                    .font(.title3)
                    .foregroundColor(.accentColor)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(category.name)
                    .font(.headline)

                Text(category.arabicName)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .environment(\.layoutDirection, .rightToLeft)
            }

            Spacer()

            Text("\(category.duaCount)")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color(.tertiarySystemGroupedBackground))
                .cornerRadius(8)

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
    }
}

// MARK: - Dua List View

struct DuaListView: View {
    let category: DuaCategoryCollection
    @State private var duas: [Dua] = []

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(duas) { dua in
                    DuaCard(dua: dua)
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(category.name)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadDuas()
        }
    }

    private func loadDuas() {
        // Load sample duas for this category
        duas = Dua.sampleDuas.filter { $0.categoryId == category.id || category.id == "morning_evening" }
        if duas.isEmpty {
            duas = Dua.sampleDuas
        }
    }
}

// MARK: - Dua Card

struct DuaCard: View {
    let dua: Dua
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Arabic text
            Text(dua.textArabic)
                .font(.system(size: 24, weight: .regular, design: .serif))
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .lineSpacing(12)
                .environment(\.layoutDirection, .rightToLeft)

            // Transliteration
            if !dua.textTransliteration.isEmpty {
                Text(dua.textTransliteration)
                    .font(.subheadline)
                    .italic()
                    .foregroundColor(.secondary)
            }

            // Translation
            Text(dua.textTranslation)
                .font(.subheadline)

            // Reference and repeat count
            HStack {
                if let occasion = dua.occasion, isExpanded {
                    Text(occasion)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                if dua.repetitions > 1 {
                    Label("\(dua.repetitions)x", systemImage: "repeat")
                        .font(.caption)
                        .foregroundColor(.accentColor)
                }
            }

            // Reference
            HStack {
                Text(dua.source ?? "")
                    .font(.caption2)
                    .foregroundColor(.secondary)

                Spacer()

                Button {
                    withAnimation {
                        isExpanded.toggle()
                    }
                } label: {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
    }
}

// MARK: - Sample Duas

extension Dua {
    static let sampleDuas: [Dua] = [
        Dua(
            id: "1",
            categoryId: "morning",
            titleEnglish: "Morning Remembrance",
            textArabic: "أَصْبَحْنَا وَأَصْبَحَ الْمُلْكُ لِلَّهِ، وَالْحَمْدُ لِلَّهِ، لَا إِلَٰهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ",
            textTransliteration: "Asbahna wa asbahal-mulku lillah, walhamdu lillah, la ilaha illallahu wahdahu la shareeka lah",
            textTranslation: "We have reached the morning and at this very time the whole kingdom belongs to Allah. All praise is due to Allah.",
            source: "Abu Dawud 4:317",
            occasion: "Said upon waking in the morning",
            repetitions: 1
        ),
        Dua(
            id: "2",
            categoryId: "morning",
            titleEnglish: "Glorification",
            textArabic: "سُبْحَانَ اللَّهِ وَبِحَمْدِهِ",
            textTransliteration: "SubhanAllahi wa bihamdihi",
            textTranslation: "Glory is to Allah and praise is to Him.",
            source: "Muslim 4:2071",
            occasion: "Whoever says this 100 times in morning and evening will have their sins forgiven even if they were like the foam of the sea.",
            repetitions: 100
        ),
        Dua(
            id: "3",
            categoryId: "evening",
            titleEnglish: "Evening Remembrance",
            textArabic: "أَمْسَيْنَا وَأَمْسَى الْمُلْكُ لِلَّهِ، وَالْحَمْدُ لِلَّهِ",
            textTransliteration: "Amsayna wa amsal-mulku lillah, walhamdu lillah",
            textTranslation: "We have reached the evening and the whole kingdom belongs to Allah.",
            source: "Abu Dawud 4:317",
            occasion: "Said in the evening",
            repetitions: 1
        ),
        Dua(
            id: "4",
            categoryId: "sleep",
            titleEnglish: "Before Sleeping",
            textArabic: "بِاسْمِكَ اللَّهُمَّ أَمُوتُ وَأَحْيَا",
            textTransliteration: "Bismika Allahumma amootu wa ahya",
            textTranslation: "In Your name O Allah, I die and I live.",
            source: "Bukhari",
            occasion: "Said before going to sleep",
            repetitions: 1
        ),
        Dua(
            id: "5",
            categoryId: "general",
            titleEnglish: "Declaration of Faith",
            textArabic: "لَا إِلَٰهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ وَهُوَ عَلَىٰ كُلِّ شَيْءٍ قَدِيرٌ",
            textTransliteration: "La ilaha illallahu wahdahu la shareeka lah, lahul-mulku wa lahul-hamd, wa Huwa 'ala kulli shay'in Qadeer",
            textTranslation: "None has the right to be worshipped except Allah, alone, without partner. To Him belongs all sovereignty and praise and He is over all things omnipotent.",
            source: "Bukhari & Muslim",
            occasion: "Whoever says this 10 times will have the reward of freeing four slaves from the Children of Isma'il.",
            repetitions: 10
        )
    ]
}

#Preview {
    NavigationStack {
        DuaCategoriesView()
    }
}
