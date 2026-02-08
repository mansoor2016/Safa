// MARK: - WindDownView.swift
// PURPOSE: Wind down mode for pre-sleep Islamic routine
// DEPENDENCIES: SwiftUI, WindDownViewModel, WindDownSubviews

import SwiftUI

// MARK: - Wind Down View

struct WindDownView: View {
    @State private var viewModel = WindDownViewModel()
    @State private var showingFajrAlarm = false
    @State private var selectedDhikr: SleepDhikr?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    headerSection
                    progressSection
                    recitationPlayerSection
                    dhikrChecklistSection
                    fajrAlarmSection

                    if viewModel.allDhikrCompleted {
                        completionSection
                    }
                }
                .padding()
            }
            .background(Color(.systemBackground).gradient)
            .navigationTitle("Wind Down")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Reset") {
                        viewModel.resetProgress()
                    }
                }
            }
            .sheet(item: $selectedDhikr) { dhikr in
                DhikrDetailSheet(dhikr: dhikr, viewModel: viewModel)
            }
            .sheet(isPresented: $showingFajrAlarm) {
                FajrAlarmSheet(viewModel: viewModel)
            }
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "moon.stars.fill")
                .font(.system(size: 48))
                .foregroundStyle(.indigo.gradient)

            Text("Prepare for Restful Sleep")
                .font(.title2.weight(.semibold))

            Text("Complete your nightly dhikr and set your Fajr alarm")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical)
    }

    // MARK: - Progress Section

    private var progressSection: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Tonight's Progress")
                    .font(.headline)
                Spacer()
                Text("\(viewModel.completedDhikr.count)/\(viewModel.sleepDhikr.count)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(.systemGray5))

                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.indigo.gradient)
                        .frame(width: geometry.size.width * viewModel.completionPercentage / 100)
                }
            }
            .frame(height: 12)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Recitation Player Section

    private var recitationPlayerSection: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "waveform")
                    .font(.title2)
                    .foregroundStyle(.indigo)

                Text("Calming Recitation")
                    .font(.headline)

                Spacer()
            }

            surahSelector
            reciterSelector
            playbackControls
            playbackProgressBar
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var surahSelector: some View {
        Menu {
            ForEach(viewModel.calmingSurahs, id: \.self) { surah in
                Button(surah) {
                    viewModel.selectedSurah = surah
                }
            }
        } label: {
            HStack {
                Text(viewModel.selectedSurah)
                    .foregroundStyle(.primary)
                Spacer()
                Image(systemName: "chevron.down")
                    .foregroundStyle(.secondary)
            }
            .padding()
            .background(Color(.tertiarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private var reciterSelector: some View {
        Menu {
            ForEach(viewModel.reciters, id: \.self) { reciter in
                Button(reciter) {
                    viewModel.selectedReciter = reciter
                }
            }
        } label: {
            HStack {
                Image(systemName: "person.wave.2")
                    .foregroundStyle(.secondary)
                Text(viewModel.selectedReciter)
                    .foregroundStyle(.primary)
                Spacer()
                Image(systemName: "chevron.down")
                    .foregroundStyle(.secondary)
            }
            .padding()
            .background(Color(.tertiarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private var playbackControls: some View {
        HStack(spacing: 24) {
            Button {
                // Previous
            } label: {
                Image(systemName: "backward.fill")
                    .font(.title2)
            }
            .disabled(true)

            Button {
                viewModel.toggleRecitation()
            } label: {
                Image(systemName: viewModel.isPlayingRecitation ? "pause.circle.fill" : "play.circle.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(.indigo)
            }

            Button {
                // Next
            } label: {
                Image(systemName: "forward.fill")
                    .font(.title2)
            }
            .disabled(true)
        }
        .padding(.top, 8)
    }

    private var playbackProgressBar: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(.systemGray5))

                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.indigo)
                    .frame(width: geometry.size.width * viewModel.playbackProgress)
            }
        }
        .frame(height: 4)
    }

    // MARK: - Dhikr Checklist Section

    private var dhikrChecklistSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "checkmark.circle")
                    .font(.title2)
                    .foregroundStyle(.indigo)

                Text("Sleep Dhikr")
                    .font(.headline)

                Spacer()
            }

            ForEach(viewModel.sleepDhikr) { dhikr in
                SleepDhikrRow(
                    dhikr: dhikr,
                    isCompleted: viewModel.completedDhikr.contains(dhikr.id),
                    onTap: { selectedDhikr = dhikr },
                    onToggle: { viewModel.toggleDhikr(dhikr.id) }
                )
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Fajr Alarm Section

    private var fajrAlarmSection: some View {
        Button {
            showingFajrAlarm = true
        } label: {
            HStack(spacing: 16) {
                Image(systemName: "alarm.fill")
                    .font(.title2)
                    .foregroundStyle(.orange)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Fajr Alarm")
                        .font(.headline)
                        .foregroundStyle(.primary)

                    Text(viewModel.fajrAlarmEnabled ? "Enabled" : "Tap to set up")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if viewModel.fajrAlarmEnabled {
                    Text(viewModel.fajrAlarmTime, style: .time)
                        .font(.headline.monospacedDigit())
                        .foregroundStyle(.orange)
                }

                Image(systemName: "chevron.right")
                    .foregroundStyle(.secondary)
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Completion Section

    private var completionSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 48))
                .foregroundStyle(.green)

            Text("Well Done!")
                .font(.title2.weight(.semibold))

            Text("You've completed your nightly dhikr. May Allah grant you peaceful sleep and an easy awakening for Fajr.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Text("+15 Hasanat")
                .font(.headline)
                .foregroundStyle(.green)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.green.opacity(0.15))
                .clipShape(Capsule())
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Preview

#Preview {
    WindDownView()
}
