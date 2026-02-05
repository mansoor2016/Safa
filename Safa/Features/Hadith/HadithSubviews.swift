// MARK: - HadithSubviews.swift
// PURPOSE: Supporting views for hadith feature
// DEPENDENCIES: SwiftUI

import SwiftUI

// MARK: - Collection Row

struct HadithCollectionRow: View {
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
                        .font(SafaTypography.arabicSmall)
                        .foregroundColor(SafaColors.Fallback.secondaryText)
                        .environment(\.layoutDirection, .rightToLeft)
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

struct HadithSearchResultRow: View {
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
                            HadithGradeBadge(grade: grading)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Hadith Grade Badge

struct HadithGradeBadge: View {
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

// MARK: - Hadith List Row

struct HadithListRow: View {
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
                            HadithGradeBadge(grade: grading)
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

// MARK: - Collection Detail View

struct CollectionDetailView: View {
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
                    bookRow(book)
                }
            }
        }
        .navigationTitle(collection.nameEnglish)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Done") { dismiss() }
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
            } catch {}
            isLoading = false
        }
    }

    private func bookRow(_ book: HadithBook) -> some View {
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

// MARK: - Book Hadith List View

struct BookHadithListView: View {
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
                Button("Done") { dismiss() }
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
            } catch {}
            isLoading = false
        }
    }
}

// MARK: - Hadith Detail View

struct HadithDetailView: View {
    let hadith: Hadith
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: SafaSpacing.lg) {
                headerSection
                Divider()
                arabicSection
                Divider()
                translationSection
                Divider()
                narratorSection
                referenceSection
                actionsSection
            }
            .padding()
        }
        .navigationTitle("Hadith")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Done") { dismiss() }
            }
        }
    }

    // MARK: - Sections

    private var headerSection: some View {
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
                HadithGradeBadge(grade: grading)
            }
        }
    }

    private var arabicSection: some View {
        VStack(alignment: .trailing, spacing: SafaSpacing.sm) {
            Text("Arabic")
                .font(SafaTypography.labelMedium)
                .foregroundColor(SafaColors.Fallback.secondaryText)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(hadith.textArabic)
                .font(SafaTypography.arabicMedium)
                .foregroundColor(SafaColors.Fallback.text)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .environment(\.layoutDirection, .rightToLeft)
        }
    }

    private var translationSection: some View {
        VStack(alignment: .leading, spacing: SafaSpacing.sm) {
            Text("Translation")
                .font(SafaTypography.labelMedium)
                .foregroundColor(SafaColors.Fallback.secondaryText)

            Text(hadith.textEnglish)
                .font(SafaTypography.bodyMedium)
                .foregroundColor(SafaColors.Fallback.text)
        }
    }

    private var narratorSection: some View {
        VStack(alignment: .leading, spacing: SafaSpacing.xs) {
            Text("Narrator")
                .font(SafaTypography.labelMedium)
                .foregroundColor(SafaColors.Fallback.secondaryText)

            Text(hadith.narrator)
                .font(SafaTypography.bodyMedium)
                .foregroundColor(SafaColors.Fallback.text)
        }
    }

    private var referenceSection: some View {
        VStack(alignment: .leading, spacing: SafaSpacing.xs) {
            Text("Reference")
                .font(SafaTypography.labelMedium)
                .foregroundColor(SafaColors.Fallback.secondaryText)

            Text(hadith.reference)
                .font(SafaTypography.bodySmall)
                .foregroundColor(SafaColors.Fallback.secondaryText)
        }
    }

    private var actionsSection: some View {
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
                UIPasteboard.general.string = hadith.textEnglish
            } label: {
                Label("Copy", systemImage: "doc.on.doc")
            }
            .buttonStyle(.bordered)
        }
        .frame(maxWidth: .infinity)
    }
}
