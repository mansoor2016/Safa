// MARK: - DownloadsView.swift
// PURPOSE: Manage downloaded content (audio, recitations, etc.)
// DEPENDENCIES: SwiftUI

import SwiftUI

// MARK: - Download Item Model

struct DownloadItem: Identifiable {
    let id: String
    let title: String
    let subtitle: String
    let category: DownloadCategory
    let size: Int64 // in bytes
    var status: DownloadStatus
    var progress: Double // 0.0 to 1.0
}

enum DownloadCategory: String, CaseIterable {
    case quranAudio = "Quran Audio"
    case adhkarAudio = "Adhkar Audio"
    case learningContent = "Learning Content"
    case aiModel = "AI Model"

    var iconName: String {
        switch self {
        case .quranAudio: return "book.fill"
        case .adhkarAudio: return "waveform"
        case .learningContent: return "graduationcap.fill"
        case .aiModel: return "cpu"
        }
    }

    var color: Color {
        switch self {
        case .quranAudio: return .green
        case .adhkarAudio: return .purple
        case .learningContent: return .blue
        case .aiModel: return .orange
        }
    }
}

enum DownloadStatus: Equatable {
    case notDownloaded
    case downloading
    case downloaded
    case updateAvailable
    case error(String)

    var displayText: String {
        switch self {
        case .notDownloaded: return "Not Downloaded"
        case .downloading: return "Downloading..."
        case .downloaded: return "Downloaded"
        case .updateAvailable: return "Update Available"
        case .error(let message): return "Error: \(message)"
        }
    }
}

// MARK: - Downloads View Model

@Observable
final class DownloadsViewModel {
    var downloads: [DownloadItem] = []
    var isLoading = false
    var wifiOnlyEnabled = true
    var autoUpdateEnabled = false
    var retentionPeriod: RetentionPeriod = .threeMonths
    var smartCleanupEnabled = true

    var totalDownloadedSize: Int64 {
        downloads.filter { $0.status == .downloaded }.reduce(0) { $0 + $1.size }
    }

    var formattedTotalSize: String {
        ByteCountFormatter.string(fromByteCount: totalDownloadedSize, countStyle: .file)
    }

    var downloadsByCategory: [DownloadCategory: [DownloadItem]] {
        Dictionary(grouping: downloads, by: { $0.category })
    }

    init() {
        loadDownloads()
    }

    func loadDownloads() {
        // Sample download items
        downloads = [
            // Quran Audio - Reciters
            DownloadItem(
                id: "quran-mishary",
                title: "Mishary Rashid Alafasy",
                subtitle: "Full Quran Recitation",
                category: .quranAudio,
                size: 450_000_000, // ~450 MB
                status: .downloaded,
                progress: 1.0
            ),
            DownloadItem(
                id: "quran-sudais",
                title: "Abdul Rahman Al-Sudais",
                subtitle: "Full Quran Recitation",
                category: .quranAudio,
                size: 480_000_000,
                status: .notDownloaded,
                progress: 0
            ),
            DownloadItem(
                id: "quran-ghamdi",
                title: "Saad Al-Ghamdi",
                subtitle: "Full Quran Recitation",
                category: .quranAudio,
                size: 420_000_000,
                status: .notDownloaded,
                progress: 0
            ),
            DownloadItem(
                id: "quran-maher",
                title: "Maher Al-Muaiqly",
                subtitle: "Full Quran Recitation",
                category: .quranAudio,
                size: 460_000_000,
                status: .notDownloaded,
                progress: 0
            ),

            // Adhkar Audio
            DownloadItem(
                id: "adhkar-morning",
                title: "Morning Adhkar",
                subtitle: "Audio with text",
                category: .adhkarAudio,
                size: 25_000_000,
                status: .downloaded,
                progress: 1.0
            ),
            DownloadItem(
                id: "adhkar-evening",
                title: "Evening Adhkar",
                subtitle: "Audio with text",
                category: .adhkarAudio,
                size: 25_000_000,
                status: .downloaded,
                progress: 1.0
            ),
            DownloadItem(
                id: "adhkar-sleep",
                title: "Sleep Adhkar",
                subtitle: "Audio with text",
                category: .adhkarAudio,
                size: 15_000_000,
                status: .notDownloaded,
                progress: 0
            ),

            // Learning Content
            DownloadItem(
                id: "learn-arabic",
                title: "Arabic Alphabet",
                subtitle: "Letters & pronunciation audio",
                category: .learningContent,
                size: 50_000_000,
                status: .downloaded,
                progress: 1.0
            ),
            DownloadItem(
                id: "learn-tajweed",
                title: "Tajweed Basics",
                subtitle: "Rules & examples",
                category: .learningContent,
                size: 75_000_000,
                status: .notDownloaded,
                progress: 0
            ),

            // AI Model
            DownloadItem(
                id: "ai-model",
                title: "Safa AI Companion",
                subtitle: "On-device language model",
                category: .aiModel,
                size: 500_000_000, // ~500 MB
                status: .updateAvailable,
                progress: 1.0
            )
        ]
    }

    func startDownload(_ item: DownloadItem) {
        guard let index = downloads.firstIndex(where: { $0.id == item.id }) else { return }

        downloads[index].status = .downloading
        downloads[index].progress = 0

        // Simulate download progress
        simulateDownload(index: index)
    }

    func pauseDownload(_ item: DownloadItem) {
        guard let index = downloads.firstIndex(where: { $0.id == item.id }) else { return }
        // In real implementation, pause the actual download
        downloads[index].status = .notDownloaded
    }

    func deleteDownload(_ item: DownloadItem) {
        guard let index = downloads.firstIndex(where: { $0.id == item.id }) else { return }
        downloads[index].status = .notDownloaded
        downloads[index].progress = 0
    }

    func deleteAllDownloads() {
        for index in downloads.indices {
            downloads[index].status = .notDownloaded
            downloads[index].progress = 0
        }
    }

    private func simulateDownload(index: Int) {
        // Simulated download progress
        Task { @MainActor in
            for progress in stride(from: 0.0, through: 1.0, by: 0.1) {
                try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 second
                if downloads[index].status == .downloading {
                    downloads[index].progress = progress
                }
            }
            if downloads[index].status == .downloading {
                downloads[index].status = .downloaded
                downloads[index].progress = 1.0
            }
        }
    }
}

// MARK: - Downloads View

struct DownloadsView: View {
    @State private var viewModel = DownloadsViewModel()
    @State private var showingDeleteAlert = false
    @State private var itemToDelete: DownloadItem?
    @State private var showingDeleteAllAlert = false

    var body: some View {
        List {
            // Storage summary section
            storageSummarySection

            // Settings section
            settingsSection

            // Smart cleanup section
            smartCleanupSection

            // Downloads by category
            ForEach(DownloadCategory.allCases, id: \.self) { category in
                if let items = viewModel.downloadsByCategory[category], !items.isEmpty {
                    Section {
                        ForEach(items) { item in
                            DownloadItemRow(
                                item: item,
                                onDownload: { viewModel.startDownload(item) },
                                onPause: { viewModel.pauseDownload(item) },
                                onDelete: {
                                    itemToDelete = item
                                    showingDeleteAlert = true
                                }
                            )
                        }
                    } header: {
                        Label(category.rawValue, systemImage: category.iconName)
                            .foregroundStyle(category.color)
                    }
                }
            }

            // Delete all section
            if viewModel.totalDownloadedSize > 0 {
                Section {
                    Button(role: .destructive) {
                        showingDeleteAllAlert = true
                    } label: {
                        HStack {
                            Spacer()
                            Text("Delete All Downloads")
                            Spacer()
                        }
                    }
                }
            }
        }
        .navigationTitle("Downloads")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Delete Download?", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                if let item = itemToDelete {
                    viewModel.deleteDownload(item)
                }
            }
        } message: {
            if let item = itemToDelete {
                Text("This will remove \(item.title) from your device. You can download it again later.")
            }
        }
        .alert("Delete All Downloads?", isPresented: $showingDeleteAllAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete All", role: .destructive) {
                viewModel.deleteAllDownloads()
            }
        } message: {
            Text("This will remove all downloaded content (\(viewModel.formattedTotalSize)). You can download content again later.")
        }
    }

    // MARK: - Storage Summary Section

    private var storageSummarySection: some View {
        Section {
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: "internaldrive.fill")
                        .font(.title2)
                        .foregroundStyle(.blue)

                    VStack(alignment: .leading) {
                        Text("Storage Used")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        Text(viewModel.formattedTotalSize)
                            .font(.title2.weight(.semibold))
                    }

                    Spacer()
                }

                // Storage breakdown by category
                HStack(spacing: 16) {
                    ForEach(DownloadCategory.allCases, id: \.self) { category in
                        if let items = viewModel.downloadsByCategory[category] {
                            let categorySize = items.filter { $0.status == .downloaded }.reduce(0) { $0 + $1.size }
                            if categorySize > 0 {
                                VStack(spacing: 4) {
                                    Circle()
                                        .fill(category.color)
                                        .frame(width: 12, height: 12)

                                    Text(ByteCountFormatter.string(fromByteCount: categorySize, countStyle: .file))
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
            }
            .padding(.vertical, 8)
        }
    }

    // MARK: - Settings Section

    private var settingsSection: some View {
        Section {
            Toggle(isOn: $viewModel.wifiOnlyEnabled) {
                HStack {
                    Image(systemName: "wifi")
                        .foregroundStyle(.blue)
                    Text("Download on Wi-Fi Only")
                }
            }

            Toggle(isOn: $viewModel.autoUpdateEnabled) {
                HStack {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .foregroundStyle(.green)
                    Text("Auto-Update Content")
                }
            }
        } header: {
            Text("Settings")
        } footer: {
            Text("Wi-Fi only prevents large downloads from using cellular data. Auto-update keeps your content current when connected to Wi-Fi.")
        }
    }

    // MARK: - Smart Cleanup Section

    private var smartCleanupSection: some View {
        Section {
            Toggle(isOn: $viewModel.smartCleanupEnabled) {
                HStack {
                    Image(systemName: "sparkles")
                        .foregroundStyle(.purple)
                    Text("Smart Cleanup")
                }
            }

            if viewModel.smartCleanupEnabled {
                Picker(selection: $viewModel.retentionPeriod) {
                    ForEach(RetentionPeriod.allCases) { period in
                        Text(period.displayName).tag(period)
                    }
                } label: {
                    HStack {
                        Image(systemName: "clock.arrow.circlepath")
                            .foregroundStyle(.orange)
                        Text("Retention Period")
                    }
                }
            }
        } header: {
            Text("Smart Cleanup")
        } footer: {
            if viewModel.smartCleanupEnabled {
                Text(viewModel.retentionPeriod.description)
            } else {
                Text("Enable Smart Cleanup to automatically remove audio files you haven't listened to in a while.")
            }
        }
    }
}

// MARK: - Download Item Row

struct DownloadItemRow: View {
    let item: DownloadItem
    let onDownload: () -> Void
    let onPause: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Icon
            Image(systemName: item.category.iconName)
                .font(.title3)
                .foregroundStyle(item.category.color)
                .frame(width: 32)

            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.subheadline.weight(.medium))

                HStack(spacing: 8) {
                    Text(item.subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text("•")
                        .foregroundStyle(.secondary)

                    Text(ByteCountFormatter.string(fromByteCount: item.size, countStyle: .file))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                // Progress bar for downloading items
                if case .downloading = item.status {
                    ProgressView(value: item.progress)
                        .tint(item.category.color)
                }
            }

            Spacer()

            // Action button
            downloadButton
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private var downloadButton: some View {
        switch item.status {
        case .notDownloaded:
            Button {
                onDownload()
            } label: {
                Image(systemName: "arrow.down.circle")
                    .font(.title2)
                    .foregroundStyle(.blue)
            }
            .buttonStyle(.plain)

        case .downloading:
            Button {
                onPause()
            } label: {
                Image(systemName: "pause.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.orange)
            }
            .buttonStyle(.plain)

        case .downloaded:
            Menu {
                Button(role: .destructive) {
                    onDelete()
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            } label: {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.green)
            }

        case .updateAvailable:
            Button {
                onDownload()
            } label: {
                Image(systemName: "arrow.down.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.blue)
            }
            .buttonStyle(.plain)

        case .error:
            Button {
                onDownload()
            } label: {
                Image(systemName: "exclamationmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.red)
            }
            .buttonStyle(.plain)
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        DownloadsView()
    }
}
