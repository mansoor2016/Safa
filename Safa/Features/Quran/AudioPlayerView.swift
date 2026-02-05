// MARK: - AudioPlayerView.swift
// PURPOSE: Audio player UI for Quran recitation
// DEPENDENCIES: SwiftUI

import SwiftUI

// MARK: - Audio Player View Model

@Observable
final class AudioPlayerViewModel {
    var isPlaying: Bool = false
    var isLoading: Bool = false
    var currentTime: TimeInterval = 0
    var duration: TimeInterval = 0
    var playbackRate: Float = 1.0
    var volume: Float = 1.0

    var selectedReciter: QuranReciter = .mishary
    var repeatMode: RepeatMode = .none
    var isShuffleEnabled: Bool = false

    var currentSurah: Int = 1
    var currentAyah: Int = 1
    var totalAyahs: Int = 7

    var surahName: String = "Al-Fatiha"
    var currentAyahText: String = "بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ"

    // Playback rates
    let playbackRates: [Float] = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0]

    var formattedCurrentTime: String {
        formatTime(currentTime)
    }

    var formattedDuration: String {
        formatTime(duration)
    }

    var progress: Double {
        guard duration > 0 else { return 0 }
        return currentTime / duration
    }

    var ayahProgress: Double {
        guard totalAyahs > 0 else { return 0 }
        return Double(currentAyah) / Double(totalAyahs)
    }

    func togglePlayPause() {
        isPlaying.toggle()
    }

    func seek(to progress: Double) {
        currentTime = duration * progress
    }

    func skipForward() {
        currentTime = min(currentTime + 15, duration)
    }

    func skipBackward() {
        currentTime = max(currentTime - 15, 0)
    }

    func nextAyah() {
        if currentAyah < totalAyahs {
            currentAyah += 1
        }
    }

    func previousAyah() {
        if currentAyah > 1 {
            currentAyah -= 1
        }
    }

    func cycleRepeatMode() {
        switch repeatMode {
        case .none:
            repeatMode = .one
        case .one:
            repeatMode = .all
        case .all:
            repeatMode = .none
        }
    }

    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Quran Reciter

enum QuranReciter: String, CaseIterable, Identifiable {
    case mishary = "Mishary Rashid Alafasy"
    case sudais = "Abdul Rahman Al-Sudais"
    case ghamdi = "Saad Al-Ghamdi"
    case maher = "Maher Al-Muaiqly"
    case minshawi = "Mohamed Siddiq Al-Minshawi"
    case husary = "Mahmoud Khalil Al-Husary"

    var id: String { rawValue }

    var shortName: String {
        switch self {
        case .mishary: return "Alafasy"
        case .sudais: return "Al-Sudais"
        case .ghamdi: return "Al-Ghamdi"
        case .maher: return "Al-Muaiqly"
        case .minshawi: return "Al-Minshawi"
        case .husary: return "Al-Husary"
        }
    }
}

// MARK: - Repeat Mode

enum RepeatMode {
    case none
    case one
    case all

    var iconName: String {
        switch self {
        case .none: return "repeat"
        case .one: return "repeat.1"
        case .all: return "repeat"
        }
    }

    var isActive: Bool {
        self != .none
    }
}

// MARK: - Audio Player View

struct AudioPlayerView: View {
    @State private var viewModel = AudioPlayerViewModel()
    @State private var showingReciterPicker = false
    @State private var showingSpeedPicker = false
    @State private var isExpanded = false

    var body: some View {
        VStack(spacing: 0) {
            if isExpanded {
                expandedPlayer
            } else {
                miniPlayer
            }
        }
        .animation(.spring(response: 0.3), value: isExpanded)
        .sheet(isPresented: $showingReciterPicker) {
            ReciterPickerSheet(selectedReciter: $viewModel.selectedReciter)
        }
        .sheet(isPresented: $showingSpeedPicker) {
            SpeedPickerSheet(
                selectedRate: $viewModel.playbackRate,
                rates: viewModel.playbackRates
            )
        }
    }

    // MARK: - Mini Player

    private var miniPlayer: some View {
        VStack(spacing: 0) {
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color(.systemGray5))

                    Rectangle()
                        .fill(Color.green)
                        .frame(width: geometry.size.width * viewModel.progress)
                }
            }
            .frame(height: 3)

            // Content
            HStack(spacing: 12) {
                // Expand button
                Button {
                    isExpanded = true
                } label: {
                    Image(systemName: "chevron.up")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                // Info
                VStack(alignment: .leading, spacing: 2) {
                    Text(viewModel.surahName)
                        .font(.subheadline.weight(.medium))

                    Text("Ayah \(viewModel.currentAyah) of \(viewModel.totalAyahs)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                // Controls
                HStack(spacing: 16) {
                    Button {
                        viewModel.previousAyah()
                    } label: {
                        Image(systemName: "backward.fill")
                            .font(.title3)
                    }

                    Button {
                        viewModel.togglePlayPause()
                    } label: {
                        Image(systemName: viewModel.isPlaying ? "pause.fill" : "play.fill")
                            .font(.title2)
                    }

                    Button {
                        viewModel.nextAyah()
                    } label: {
                        Image(systemName: "forward.fill")
                            .font(.title3)
                    }
                }
                .foregroundStyle(.primary)
            }
            .padding()
        }
        .background(Color(.secondarySystemBackground))
    }

    // MARK: - Expanded Player

    private var expandedPlayer: some View {
        VStack(spacing: 24) {
            // Handle
            Capsule()
                .fill(Color(.systemGray4))
                .frame(width: 36, height: 5)
                .padding(.top, 8)
                .onTapGesture {
                    isExpanded = false
                }

            // Surah info
            VStack(spacing: 8) {
                Text(viewModel.surahName)
                    .font(.title2.weight(.semibold))

                Text("Ayah \(viewModel.currentAyah) of \(viewModel.totalAyahs)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            // Current ayah text
            Text(viewModel.currentAyahText)
                .font(.system(size: 28, weight: .medium, design: .serif))
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Spacer()

            // Progress slider
            VStack(spacing: 8) {
                Slider(
                    value: Binding(
                        get: { viewModel.progress },
                        set: { viewModel.seek(to: $0) }
                    ),
                    in: 0...1
                )
                .tint(.green)

                HStack {
                    Text(viewModel.formattedCurrentTime)
                    Spacer()
                    Text(viewModel.formattedDuration)
                }
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)
            }
            .padding(.horizontal)

            // Main controls
            HStack(spacing: 40) {
                // Repeat
                Button {
                    viewModel.cycleRepeatMode()
                } label: {
                    Image(systemName: viewModel.repeatMode.iconName)
                        .font(.title3)
                        .foregroundStyle(viewModel.repeatMode.isActive ? .green : .secondary)
                }

                // Previous
                Button {
                    viewModel.previousAyah()
                } label: {
                    Image(systemName: "backward.fill")
                        .font(.title)
                }

                // Play/Pause
                Button {
                    viewModel.togglePlayPause()
                } label: {
                    Image(systemName: viewModel.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 72))
                        .foregroundStyle(.green)
                }

                // Next
                Button {
                    viewModel.nextAyah()
                } label: {
                    Image(systemName: "forward.fill")
                        .font(.title)
                }

                // Speed
                Button {
                    showingSpeedPicker = true
                } label: {
                    Text("\(String(format: "%.1fx", viewModel.playbackRate))")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)
                }
            }
            .foregroundStyle(.primary)

            // Reciter info
            Button {
                showingReciterPicker = true
            } label: {
                HStack {
                    Image(systemName: "person.wave.2")
                    Text(viewModel.selectedReciter.shortName)
                    Image(systemName: "chevron.down")
                        .font(.caption)
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color(.tertiarySystemBackground))
                .clipShape(Capsule())
            }

            // Ayah progress
            HStack(spacing: 4) {
                ForEach(1...min(viewModel.totalAyahs, 20), id: \.self) { ayah in
                    Circle()
                        .fill(ayah <= viewModel.currentAyah ? Color.green : Color(.systemGray4))
                        .frame(width: 8, height: 8)
                }

                if viewModel.totalAyahs > 20 {
                    Text("...")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.bottom)
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(radius: 10)
    }
}

// MARK: - Reciter Picker Sheet

struct ReciterPickerSheet: View {
    @Binding var selectedReciter: QuranReciter
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List(QuranReciter.allCases) { reciter in
                Button {
                    selectedReciter = reciter
                    dismiss()
                } label: {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(reciter.rawValue)
                                .font(.subheadline)
                                .foregroundStyle(.primary)
                        }

                        Spacer()

                        if reciter == selectedReciter {
                            Image(systemName: "checkmark")
                                .foregroundStyle(.green)
                        }
                    }
                }
            }
            .navigationTitle("Select Reciter")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

// MARK: - Speed Picker Sheet

struct SpeedPickerSheet: View {
    @Binding var selectedRate: Float
    let rates: [Float]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List(rates, id: \.self) { rate in
                Button {
                    selectedRate = rate
                    dismiss()
                } label: {
                    HStack {
                        Text("\(String(format: "%.2fx", rate))")
                            .font(.subheadline)
                            .foregroundStyle(.primary)

                        if rate == 1.0 {
                            Text("Normal")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        if rate == selectedRate {
                            Image(systemName: "checkmark")
                                .foregroundStyle(.green)
                        }
                    }
                }
            }
            .navigationTitle("Playback Speed")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

// MARK: - Floating Audio Player

struct FloatingAudioPlayer: View {
    @State private var viewModel = AudioPlayerViewModel()
    @State private var isExpanded = false

    var body: some View {
        VStack {
            Spacer()

            if viewModel.isPlaying || viewModel.currentTime > 0 {
                AudioPlayerView()
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.3), value: viewModel.isPlaying)
    }
}

// MARK: - Preview

#Preview("Mini Player") {
    VStack {
        Spacer()
        AudioPlayerView()
    }
}

#Preview("Expanded Player") {
    AudioPlayerView()
}
