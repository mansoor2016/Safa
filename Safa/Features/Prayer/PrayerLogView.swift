// MARK: - PrayerLogView.swift
// PURPOSE: View for logging and reviewing prayer history
// DEPENDENCIES: SwiftUI

import SwiftUI

// MARK: - Prayer Log View Model

@Observable
final class PrayerLogViewModel {
    var selectedDate: Date = Date()
    var selectedPrayer: PrayerType?
    var prayerLogs: [Date: [PrayerLogEntry]] = [:]
    var showingLogSheet = false
    var logQuality: PrayerQuality = .onTime
    var logNotes: String = ""
    var isLoading = false

    // Weekly summary data
    var weeklyStats: WeeklyPrayerStats {
        calculateWeeklyStats()
    }

    // Get logs for a specific date
    func logs(for date: Date) -> [PrayerLogEntry] {
        let calendar = Calendar.current
        let dateKey = prayerLogs.keys.first { calendar.isDate($0, inSameDayAs: date) }
        return dateKey.flatMap { prayerLogs[$0] } ?? []
    }

    // Check if prayer is logged for date
    func isLogged(_ prayer: PrayerType, on date: Date) -> Bool {
        logs(for: date).contains { $0.prayerType == prayer }
    }

    // Log a prayer
    func logPrayer(_ prayer: PrayerType, quality: PrayerQuality, notes: String?) {
        let log = PrayerLogEntry(
            id: UUID(),
            prayerType: prayer,
            date: selectedDate,
            quality: quality,
            notes: notes
        )

        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: selectedDate)

        if prayerLogs[startOfDay] != nil {
            prayerLogs[startOfDay]?.append(log)
        } else {
            prayerLogs[startOfDay] = [log]
        }
    }

    // Remove a prayer log
    func removeLog(for prayer: PrayerType, on date: Date) {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)

        prayerLogs[startOfDay]?.removeAll { $0.prayerType == prayer }
    }

    // Calculate weekly statistics
    private func calculateWeeklyStats() -> WeeklyPrayerStats {
        let calendar = Calendar.current
        let today = Date()
        var totalPrayers = 0
        var onTimePrayers = 0
        var missedPrayers = 0
        var daysWithAllPrayers = 0

        for dayOffset in 0..<7 {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) else { continue }
            let dailyLogs = logs(for: date)

            totalPrayers += dailyLogs.count
            onTimePrayers += dailyLogs.filter { $0.quality == .onTime }.count

            // Count days with all 5 prayers
            if dailyLogs.count >= 5 {
                daysWithAllPrayers += 1
            }
        }

        missedPrayers = (7 * 5) - totalPrayers // 7 days × 5 prayers

        return WeeklyPrayerStats(
            totalLogged: totalPrayers,
            onTime: onTimePrayers,
            late: totalPrayers - onTimePrayers,
            missed: max(0, missedPrayers),
            perfectDays: daysWithAllPrayers
        )
    }

    // Load sample data
    func loadSampleData() {
        let calendar = Calendar.current
        let today = Date()

        // Generate some sample prayer logs for the past week
        for dayOffset in 0..<7 {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) else { continue }
            let startOfDay = calendar.startOfDay(for: date)

            var dailyLogs: [PrayerLogEntry] = []

            // Add random prayers for each day
            let prayersToLog = PrayerType.allCases.filter { _ in Bool.random() || dayOffset == 0 }

            for prayer in prayersToLog {
                let quality: PrayerQuality = Bool.random() ? .onTime : .delayed
                dailyLogs.append(PrayerLogEntry(
                    id: UUID(),
                    prayerType: prayer,
                    date: date,
                    quality: quality,
                    notes: nil
                ))
            }

            prayerLogs[startOfDay] = dailyLogs
        }
    }
}

// MARK: - Supporting Models

struct PrayerLogEntry: Identifiable, Codable, Equatable {
    let id: UUID
    let prayerType: PrayerType
    let date: Date
    let quality: PrayerQuality
    let notes: String?

    var timestamp: Date {
        date
    }
}

enum PrayerQuality: String, Codable, CaseIterable {
    case onTime = "on_time"
    case delayed = "delayed"
    case qada = "qada"

    var displayName: String {
        switch self {
        case .onTime: return "On Time"
        case .delayed: return "Delayed"
        case .qada: return "Qada (Makeup)"
        }
    }

    var color: Color {
        switch self {
        case .onTime: return .green
        case .delayed: return .orange
        case .qada: return .blue
        }
    }

    var iconName: String {
        switch self {
        case .onTime: return "checkmark.circle.fill"
        case .delayed: return "clock.fill"
        case .qada: return "arrow.counterclockwise"
        }
    }
}

struct WeeklyPrayerStats {
    let totalLogged: Int
    let onTime: Int
    let late: Int
    let missed: Int
    let perfectDays: Int

    var completionPercentage: Double {
        let expected = 7 * 5 // 7 days × 5 prayers
        return Double(totalLogged) / Double(expected) * 100
    }
}

// MARK: - Prayer Log View

struct PrayerLogView: View {
    @State private var viewModel = PrayerLogViewModel()
    @State private var selectedTab = 0

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Tab selector
                Picker("View", selection: $selectedTab) {
                    Text("Log").tag(0)
                    Text("History").tag(1)
                    Text("Stats").tag(2)
                }
                .pickerStyle(.segmented)
                .padding()

                TabView(selection: $selectedTab) {
                    // Log Tab
                    logTabView
                        .tag(0)

                    // History Tab
                    historyTabView
                        .tag(1)

                    // Stats Tab
                    statsTabView
                        .tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
            .navigationTitle("Prayer Log")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                viewModel.loadSampleData()
            }
            .sheet(isPresented: $viewModel.showingLogSheet) {
                if let prayer = viewModel.selectedPrayer {
                    LogPrayerSheet(
                        prayer: prayer,
                        viewModel: viewModel
                    )
                }
            }
        }
    }

    // MARK: - Log Tab

    private var logTabView: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Date selector
                DatePicker(
                    "Select Date",
                    selection: $viewModel.selectedDate,
                    in: ...Date(),
                    displayedComponents: .date
                )
                .datePickerStyle(.graphical)
                .padding()
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16))

                // Daily prayer grid
                dailyPrayerGrid
            }
            .padding()
        }
    }

    private var dailyPrayerGrid: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Prayers for \(viewModel.selectedDate.formatted(date: .abbreviated, time: .omitted))")
                    .font(.headline)

                Spacer()

                let loggedCount = viewModel.logs(for: viewModel.selectedDate).count
                Text("\(loggedCount)/5")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            ForEach(PrayerType.allCases, id: \.self) { prayer in
                PrayerLogRow(
                    prayer: prayer,
                    isLogged: viewModel.isLogged(prayer, on: viewModel.selectedDate),
                    log: viewModel.logs(for: viewModel.selectedDate).first { $0.prayerType == prayer },
                    onTap: {
                        if viewModel.isLogged(prayer, on: viewModel.selectedDate) {
                            // Show options to edit or remove
                            viewModel.selectedPrayer = prayer
                            viewModel.showingLogSheet = true
                        } else {
                            viewModel.selectedPrayer = prayer
                            viewModel.showingLogSheet = true
                        }
                    }
                )
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - History Tab

    private var historyTabView: some View {
        List {
            ForEach(Array(viewModel.prayerLogs.keys.sorted(by: >)), id: \.self) { date in
                Section {
                    if let logs = viewModel.prayerLogs[date] {
                        ForEach(logs) { log in
                            HStack {
                                Image(systemName: log.prayerType.iconName)
                                    .foregroundStyle(log.quality.color)

                                VStack(alignment: .leading) {
                                    Text(log.prayerType.displayName)
                                        .font(.subheadline.weight(.medium))

                                    Text(log.quality.displayName)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }

                                Spacer()

                                Image(systemName: log.quality.iconName)
                                    .foregroundStyle(log.quality.color)
                            }
                        }
                    }
                } header: {
                    Text(date.formatted(date: .abbreviated, time: .omitted))
                }
            }
        }
        .listStyle(.insetGrouped)
        .overlay {
            if viewModel.prayerLogs.isEmpty {
                ContentUnavailableView(
                    "No Prayer History",
                    systemImage: "calendar.badge.exclamationmark",
                    description: Text("Start logging your prayers to see your history here")
                )
            }
        }
    }

    // MARK: - Stats Tab

    private var statsTabView: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Weekly summary card
                weeklySummaryCard

                // Streak info
                streakCard

                // Prayer breakdown
                prayerBreakdownCard
            }
            .padding()
        }
    }

    private var weeklySummaryCard: some View {
        VStack(spacing: 16) {
            HStack {
                Text("This Week")
                    .font(.headline)
                Spacer()
            }

            // Circular progress
            ZStack {
                Circle()
                    .stroke(Color(.systemGray5), lineWidth: 12)

                Circle()
                    .trim(from: 0, to: viewModel.weeklyStats.completionPercentage / 100)
                    .stroke(
                        LinearGradient(colors: [.green, .blue], startPoint: .leading, endPoint: .trailing),
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))

                VStack {
                    Text("\(Int(viewModel.weeklyStats.completionPercentage))%")
                        .font(.system(size: 36, weight: .bold, design: .rounded))

                    Text("Complete")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 140, height: 140)

            // Stats grid
            HStack(spacing: 0) {
                StatItem(
                    value: viewModel.weeklyStats.totalLogged,
                    label: "Logged",
                    color: .blue
                )

                Divider()
                    .frame(height: 40)

                StatItem(
                    value: viewModel.weeklyStats.onTime,
                    label: "On Time",
                    color: .green
                )

                Divider()
                    .frame(height: 40)

                StatItem(
                    value: viewModel.weeklyStats.perfectDays,
                    label: "Perfect Days",
                    color: .orange
                )
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var streakCard: some View {
        HStack(spacing: 16) {
            Image(systemName: "flame.fill")
                .font(.system(size: 32))
                .foregroundStyle(.orange.gradient)

            VStack(alignment: .leading) {
                Text("Prayer Streak")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Text("\(viewModel.weeklyStats.perfectDays) days")
                    .font(.title2.weight(.bold))
            }

            Spacer()

            VStack(alignment: .trailing) {
                Text("Best")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text("14 days")
                    .font(.headline)
                    .foregroundStyle(.orange)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var prayerBreakdownCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Prayer Breakdown")
                .font(.headline)

            ForEach(PrayerType.allCases, id: \.self) { prayer in
                let count = viewModel.prayerLogs.values.flatMap { $0 }.filter { $0.prayerType == prayer }.count

                HStack {
                    Image(systemName: prayer.iconName)
                        .frame(width: 24)
                        .foregroundStyle(.secondary)

                    Text(prayer.displayName)
                        .font(.subheadline)

                    Spacer()

                    Text("\(count)/7")
                        .font(.subheadline.monospacedDigit())
                        .foregroundStyle(.secondary)

                    // Mini progress bar
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color(.systemGray5))

                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.green)
                                .frame(width: geometry.size.width * Double(count) / 7.0)
                        }
                    }
                    .frame(width: 60, height: 8)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Prayer Log Row

struct PrayerLogRow: View {
    let prayer: PrayerType
    let isLogged: Bool
    let log: PrayerLogEntry?
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Image(systemName: prayer.iconName)
                    .font(.title2)
                    .foregroundStyle(isLogged ? .green : .secondary)
                    .frame(width: 32)

                VStack(alignment: .leading, spacing: 2) {
                    Text(prayer.displayName)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.primary)

                    if let log = log {
                        Text(log.quality.displayName)
                            .font(.caption)
                            .foregroundStyle(log.quality.color)
                    } else {
                        Text("Tap to log")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                if isLogged {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                } else {
                    Image(systemName: "plus.circle")
                        .foregroundStyle(.blue)
                }
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Stat Item

struct StatItem: View {
    let value: Int
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text("\(value)")
                .font(.title2.weight(.bold))
                .foregroundStyle(color)

            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Log Prayer Sheet

struct LogPrayerSheet: View {
    let prayer: PrayerType
    let viewModel: PrayerLogViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var selectedQuality: PrayerQuality = .onTime
    @State private var notes: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Prayer") {
                    HStack {
                        Image(systemName: prayer.iconName)
                            .foregroundStyle(.blue)
                        Text(prayer.displayName)
                            .font(.headline)
                    }
                }

                Section("Quality") {
                    ForEach(PrayerQuality.allCases, id: \.self) { quality in
                        Button {
                            selectedQuality = quality
                        } label: {
                            HStack {
                                Image(systemName: quality.iconName)
                                    .foregroundStyle(quality.color)

                                Text(quality.displayName)
                                    .foregroundStyle(.primary)

                                Spacer()

                                if selectedQuality == quality {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.blue)
                                }
                            }
                        }
                    }
                }

                Section("Notes (Optional)") {
                    TextField("Add any notes...", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }

                if viewModel.isLogged(prayer, on: viewModel.selectedDate) {
                    Section {
                        Button(role: .destructive) {
                            viewModel.removeLog(for: prayer, on: viewModel.selectedDate)
                            dismiss()
                        } label: {
                            HStack {
                                Spacer()
                                Text("Remove Log")
                                Spacer()
                            }
                        }
                    }
                }
            }
            .navigationTitle("Log \(prayer.displayName)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if viewModel.isLogged(prayer, on: viewModel.selectedDate) {
                            viewModel.removeLog(for: prayer, on: viewModel.selectedDate)
                        }
                        viewModel.logPrayer(prayer, quality: selectedQuality, notes: notes.isEmpty ? nil : notes)
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    PrayerLogView()
}
