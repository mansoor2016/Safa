// MARK: - WindDownView.swift
// PURPOSE: Wind down mode for pre-sleep Islamic routine
// DEPENDENCIES: SwiftUI, Combine

import SwiftUI

// MARK: - Wind Down View Model

@Observable
final class WindDownViewModel {
    var completedAdhkar: Set<String> = []
    var isPlayingRecitation: Bool = false
    var selectedReciter: String = "Mishary Rashid Alafasy"
    var fajrAlarmEnabled: Bool = false
    var fajrAlarmTime: Date = Date()
    var selectedSurah: String = "Surah Al-Mulk"
    var playbackProgress: Double = 0.0

    let sleepAdhkar: [SleepAdhkar] = [
        SleepAdhkar(
            id: "ayat-kursi",
            title: "Ayatul Kursi",
            arabic: "اللَّهُ لَا إِلَٰهَ إِلَّا هُوَ الْحَيُّ الْقَيُّومُ...",
            transliteration: "Allahu la ilaha illa Huwal-Hayyul-Qayyum...",
            translation: "Allah - there is no deity except Him, the Ever-Living, the Sustainer of existence...",
            benefit: "Protection throughout the night",
            count: 1
        ),
        SleepAdhkar(
            id: "surah-ikhlas",
            title: "Surah Al-Ikhlas",
            arabic: "قُلْ هُوَ اللَّهُ أَحَدٌ ۝ اللَّهُ الصَّمَدُ...",
            transliteration: "Qul Huwa Allahu Ahad, Allahus-Samad...",
            translation: "Say, He is Allah, [who is] One, Allah, the Eternal Refuge...",
            benefit: "Equal to one-third of the Quran",
            count: 3
        ),
        SleepAdhkar(
            id: "surah-falaq",
            title: "Surah Al-Falaq",
            arabic: "قُلْ أَعُوذُ بِرَبِّ الْفَلَقِ...",
            transliteration: "Qul A'udhu bi Rabbil-Falaq...",
            translation: "Say, I seek refuge in the Lord of daybreak...",
            benefit: "Protection from evil",
            count: 3
        ),
        SleepAdhkar(
            id: "surah-nas",
            title: "Surah An-Nas",
            arabic: "قُلْ أَعُوذُ بِرَبِّ النَّاسِ...",
            transliteration: "Qul A'udhu bi Rabbin-Nas...",
            translation: "Say, I seek refuge in the Lord of mankind...",
            benefit: "Protection from whispers of Satan",
            count: 3
        ),
        SleepAdhkar(
            id: "sleep-dua",
            title: "Dua Before Sleep",
            arabic: "بِاسْمِكَ اللَّهُمَّ أَمُوتُ وَأَحْيَا",
            transliteration: "Bismika Allahumma amutu wa ahya",
            translation: "In Your name, O Allah, I die and I live",
            benefit: "Sunnah of the Prophet ﷺ",
            count: 1
        ),
        SleepAdhkar(
            id: "hands-blow",
            title: "Blowing into Hands",
            arabic: "اللَّهُمَّ قِنِي عَذَابَكَ يَوْمَ تَبْعَثُ عِبَادَكَ",
            transliteration: "Allahumma qini 'adhabaka yawma tab'athu 'ibadak",
            translation: "O Allah, protect me from Your punishment on the Day You resurrect Your servants",
            benefit: "Recite and wipe over body",
            count: 1
        ),
        SleepAdhkar(
            id: "tasbih-33",
            title: "SubhanAllah",
            arabic: "سُبْحَانَ اللَّهِ",
            transliteration: "SubhanAllah",
            translation: "Glory be to Allah",
            benefit: "33 times before sleep",
            count: 33
        ),
        SleepAdhkar(
            id: "hamd-33",
            title: "Alhamdulillah",
            arabic: "الْحَمْدُ لِلَّهِ",
            transliteration: "Alhamdulillah",
            translation: "Praise be to Allah",
            benefit: "33 times before sleep",
            count: 33
        ),
        SleepAdhkar(
            id: "takbir-34",
            title: "Allahu Akbar",
            arabic: "اللَّهُ أَكْبَرُ",
            transliteration: "Allahu Akbar",
            translation: "Allah is the Greatest",
            benefit: "34 times before sleep",
            count: 34
        )
    ]

    let calmingSurahs: [String] = [
        "Surah Al-Mulk",
        "Surah As-Sajdah",
        "Surah Yasin",
        "Surah Ar-Rahman",
        "Surah Al-Waqiah"
    ]

    let reciters: [String] = [
        "Mishary Rashid Alafasy",
        "Abdul Rahman Al-Sudais",
        "Saad Al-Ghamdi",
        "Abu Bakr Al-Shatri",
        "Maher Al-Muaiqly"
    ]

    var completionPercentage: Double {
        guard !sleepAdhkar.isEmpty else { return 0 }
        return Double(completedAdhkar.count) / Double(sleepAdhkar.count) * 100
    }

    var allAdhkarCompleted: Bool {
        completedAdhkar.count == sleepAdhkar.count
    }

    func toggleAdhkar(_ id: String) {
        if completedAdhkar.contains(id) {
            completedAdhkar.remove(id)
        } else {
            completedAdhkar.insert(id)
        }
    }

    func toggleRecitation() {
        isPlayingRecitation.toggle()
    }

    func resetProgress() {
        completedAdhkar.removeAll()
        isPlayingRecitation = false
        playbackProgress = 0.0
    }
}

// MARK: - Sleep Adhkar Model

struct SleepAdhkar: Identifiable {
    let id: String
    let title: String
    let arabic: String
    let transliteration: String
    let translation: String
    let benefit: String
    let count: Int
}

// MARK: - Wind Down View

struct WindDownView: View {
    @State private var viewModel = WindDownViewModel()
    @State private var showingFajrAlarm = false
    @State private var selectedAdhkar: SleepAdhkar?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header with calming message
                    headerSection

                    // Progress indicator
                    progressSection

                    // Calming recitation player
                    recitationPlayerSection

                    // Sleep adhkar checklist
                    adhkarChecklistSection

                    // Fajr alarm setup
                    fajrAlarmSection

                    // Completion message
                    if viewModel.allAdhkarCompleted {
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
            .sheet(item: $selectedAdhkar) { adhkar in
                AdhkarDetailSheet(adhkar: adhkar, viewModel: viewModel)
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

            Text("Complete your nightly adhkar and set your Fajr alarm")
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
                Text("\(viewModel.completedAdhkar.count)/\(viewModel.sleepAdhkar.count)")
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

            // Surah selector
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

            // Reciter selector
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

            // Playback controls
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

            // Progress bar
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
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Adhkar Checklist Section

    private var adhkarChecklistSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "checkmark.circle")
                    .font(.title2)
                    .foregroundStyle(.indigo)

                Text("Sleep Adhkar")
                    .font(.headline)

                Spacer()
            }

            ForEach(viewModel.sleepAdhkar) { adhkar in
                SleepAdhkarRow(
                    adhkar: adhkar,
                    isCompleted: viewModel.completedAdhkar.contains(adhkar.id),
                    onTap: {
                        selectedAdhkar = adhkar
                    },
                    onToggle: {
                        viewModel.toggleAdhkar(adhkar.id)
                    }
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

            Text("You've completed your nightly adhkar. May Allah grant you peaceful sleep and an easy awakening for Fajr.")
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

// MARK: - Sleep Adhkar Row

struct SleepAdhkarRow: View {
    let adhkar: SleepAdhkar
    let isCompleted: Bool
    let onTap: () -> Void
    let onToggle: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button {
                onToggle()
            } label: {
                Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(isCompleted ? .green : .secondary)
            }

            Button {
                onTap()
            } label: {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(adhkar.title)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(isCompleted ? .secondary : .primary)
                            .strikethrough(isCompleted)

                        if adhkar.count > 1 {
                            Text("×\(adhkar.count)")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.indigo)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.indigo.opacity(0.15))
                                .clipShape(Capsule())
                        }
                    }

                    Text(adhkar.benefit)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Adhkar Detail Sheet

struct AdhkarDetailSheet: View {
    let adhkar: SleepAdhkar
    let viewModel: WindDownViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var currentCount: Int = 0

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Arabic text
                    Text(adhkar.arabic)
                        .font(.system(size: 32, weight: .medium, design: .serif))
                        .multilineTextAlignment(.center)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 16))

                    // Transliteration
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Transliteration")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Text(adhkar.transliteration)
                            .font(.body)
                            .italic()
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    // Translation
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Translation")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Text(adhkar.translation)
                            .font(.body)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    // Benefit
                    HStack(spacing: 12) {
                        Image(systemName: "sparkles")
                            .foregroundStyle(.indigo)

                        Text(adhkar.benefit)
                            .font(.subheadline)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.indigo.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                    // Counter for repeated adhkar
                    if adhkar.count > 1 {
                        VStack(spacing: 16) {
                            Text("\(currentCount) / \(adhkar.count)")
                                .font(.system(size: 48, weight: .bold, design: .rounded))
                                .foregroundStyle(currentCount >= adhkar.count ? .green : .primary)

                            Button {
                                if currentCount < adhkar.count {
                                    currentCount += 1
                                    // Haptic feedback
                                    let impact = UIImpactFeedbackGenerator(style: .medium)
                                    impact.impactOccurred()
                                }

                                if currentCount >= adhkar.count {
                                    viewModel.toggleAdhkar(adhkar.id)
                                }
                            } label: {
                                Text(currentCount >= adhkar.count ? "Completed" : "Tap to Count")
                                    .font(.headline)
                                    .foregroundStyle(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(currentCount >= adhkar.count ? Color.green : Color.indigo)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                            .disabled(currentCount >= adhkar.count)
                        }
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    } else {
                        // Single recitation - mark complete button
                        Button {
                            viewModel.toggleAdhkar(adhkar.id)
                            dismiss()
                        } label: {
                            Text(viewModel.completedAdhkar.contains(adhkar.id) ? "Mark Incomplete" : "Mark Complete")
                                .font(.headline)
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(viewModel.completedAdhkar.contains(adhkar.id) ? Color.gray : Color.indigo)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                }
                .padding()
            }
            .navigationTitle(adhkar.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Fajr Alarm Sheet

struct FajrAlarmSheet: View {
    let viewModel: WindDownViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTime: Date
    @State private var isEnabled: Bool

    init(viewModel: WindDownViewModel) {
        self.viewModel = viewModel
        _selectedTime = State(initialValue: viewModel.fajrAlarmTime)
        _isEnabled = State(initialValue: viewModel.fajrAlarmEnabled)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Toggle("Enable Fajr Alarm", isOn: $isEnabled)

                    if isEnabled {
                        DatePicker(
                            "Alarm Time",
                            selection: $selectedTime,
                            displayedComponents: .hourAndMinute
                        )
                    }
                }

                Section {
                    HStack {
                        Image(systemName: "info.circle")
                            .foregroundStyle(.blue)

                        Text("The alarm will be set based on Fajr prayer time for your location. You can adjust the offset if needed.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Alarm Options") {
                    NavigationLink {
                        Text("Sound selection coming soon")
                    } label: {
                        HStack {
                            Text("Sound")
                            Spacer()
                            Text("Adhan")
                                .foregroundStyle(.secondary)
                        }
                    }

                    NavigationLink {
                        Text("Snooze settings coming soon")
                    } label: {
                        HStack {
                            Text("Snooze")
                            Spacer()
                            Text("9 minutes")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Fajr Alarm")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        viewModel.fajrAlarmEnabled = isEnabled
                        viewModel.fajrAlarmTime = selectedTime
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    WindDownView()
}
