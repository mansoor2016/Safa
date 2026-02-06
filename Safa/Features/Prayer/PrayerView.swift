// MARK: - PrayerView.swift
// PURPOSE: Main prayer times view displaying daily prayers and Qibla
// DEPENDENCIES: SwiftUI, PrayerViewModel

import SwiftUI
import Combine

struct PrayerView: View {
    @Environment(Dependencies.self) private var dependencies
    @State private var viewModel: PrayerViewModel?

    var body: some View {
        Group {
            if let viewModel = viewModel {
                PrayerContentView(viewModel: viewModel)
            } else {
                LoadingView(message: "Loading prayer times...")
            }
        }
        .task {
            if viewModel == nil {
                viewModel = PrayerViewModel(
                    prayerRepository: dependencies.prayerRepository,
                    locationService: dependencies.locationService,
                    notificationService: dependencies.notificationService,
                    userState: dependencies.userState
                )
            }
        }
    }
}

// MARK: - Prayer Content View

private struct PrayerContentView: View {
    @Bindable var viewModel: PrayerViewModel
    @State private var showingQibla = false
    @State private var showingSettings = false

    var body: some View {
        ScrollView {
            VStack(spacing: SafaSpacing.lg) {
                // Date Header
                dateHeader

                // Next Prayer Card
                if let nextPrayer = viewModel.nextPrayer {
                    NextPrayerCard(prayer: nextPrayer)
                }

                // All Prayer Times
                PrayerTimesCard(
                    prayers: viewModel.todayPrayers,
                    notificationEnabledPrayers: viewModel.notificationEnabledPrayers,
                    onToggleNotification: { prayerType in
                        viewModel.toggleNotification(for: prayerType)
                    }
                )

                // Quick Actions
                quickActionsSection
            }
            .padding(SafaSpacing.md)
        }
        .navigationTitle("Prayer Times")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingSettings = true
                } label: {
                    Image(systemName: "gearshape")
                }
            }
        }
        .sheet(isPresented: $showingQibla) {
            NavigationStack {
                QiblaCompassView()
            }
        }
        .sheet(isPresented: $showingSettings) {
            NavigationStack {
                PrayerSettingsView(viewModel: viewModel)
            }
        }
        .refreshable {
            await viewModel.refreshPrayerTimes()
        }
        .task {
            await viewModel.loadPrayerTimes()
        }
        .onAppear {
            Task { await viewModel.reloadLoggedPrayers() }
        }
    }

    // MARK: - Date Header

    private var dateHeader: some View {
        VStack(spacing: SafaSpacing.sm) {
            VStack(spacing: SafaSpacing.xxs) {
                Text(viewModel.currentDate.formatted(date: .complete, time: .omitted))
                    .font(SafaTypography.titleMedium)
                    .foregroundColor(SafaColors.Fallback.text)

                Text(HijriDateConverter.shared.hijriDateString(from: viewModel.currentDate, style: .full))
                    .font(SafaTypography.bodySmall)
                    .foregroundColor(SafaColors.Fallback.secondaryText)
            }

            // Prayer progress indicator
            PrayerProgressIndicator(
                prayers: viewModel.todayPrayers,
                loggedPrayers: viewModel.loggedPrayers,
                nextPrayer: viewModel.nextPrayer,
                style: .expanded,
                onLogPrayer: { prayerType in
                    Task { await viewModel.togglePrayer(prayerType) }
                }
            )
            .padding(.top, SafaSpacing.sm)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Quick Actions

    private var quickActionsSection: some View {
        HStack(spacing: SafaSpacing.md) {
            QuickActionButton(
                icon: "location.north.fill",
                title: "Qibla",
                action: { showingQibla = true }
            )

            QuickActionButton(
                icon: "bell.fill",
                title: "Notifications",
                action: {
                    Task {
                        await viewModel.requestNotificationPermission()
                    }
                }
            )

            QuickActionButton(
                icon: "calendar",
                title: "Prayer Log",
                action: {
                    // Navigate to prayer log
                }
            )
        }
    }
}

// MARK: - Next Prayer Card

private struct NextPrayerCard: View {
    let prayer: PrayerTime
    @State private var countdown = ""
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        ContentCard {
            VStack(spacing: SafaSpacing.md) {
                Text("Next Prayer")
                    .font(SafaTypography.labelMedium)
                    .foregroundColor(SafaColors.Fallback.secondaryText)

                Text(prayer.type.displayName)
                    .font(SafaTypography.headlineMedium)
                    .foregroundColor(prayer.type.color)

                Text("Time until next prayer")
                    .font(SafaTypography.labelSmall)
                    .foregroundColor(SafaColors.Fallback.secondaryText)

                Text(countdown)
                    .font(SafaTypography.counterMedium)
                    .foregroundColor(SafaColors.Fallback.text)
                    .monospacedDigit()

                Text(prayer.time.formatted(date: .omitted, time: .shortened))
                    .font(SafaTypography.bodyMedium)
                    .foregroundColor(SafaColors.Fallback.secondaryText)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, SafaSpacing.md)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(nextPrayerAccessibilityLabel)
        .accessibilityHint("Shows time until next prayer")
        .onReceive(timer) { _ in
            updateCountdown()
        }
        .onAppear {
            updateCountdown()
        }
    }

    private var nextPrayerAccessibilityLabel: String {
        let (hours, minutes, _) = prayer.time.countdown()
        let timeString = prayer.time.formatted(date: .omitted, time: .shortened)
        if hours > 0 {
            return "Next prayer is \(prayer.type.displayName) at \(timeString), \(hours) hours and \(minutes) minutes remaining"
        } else {
            return "Next prayer is \(prayer.type.displayName) at \(timeString), \(minutes) minutes remaining"
        }
    }

    private func updateCountdown() {
        let (hours, minutes, seconds) = prayer.time.countdown()
        countdown = String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
}

// MARK: - Prayer Times Card

private struct PrayerTimesCard: View {
    let prayers: [PrayerTime]
    let notificationEnabledPrayers: Set<PrayerType>
    let onToggleNotification: (PrayerType) -> Void

    var body: some View {
        ContentCard {
            VStack(spacing: 0) {
                ForEach(prayers) { prayer in
                    PrayerTimeRow(
                        prayer: prayer,
                        isNotificationEnabled: notificationEnabledPrayers.contains(prayer.type),
                        onToggleNotification: { onToggleNotification(prayer.type) }
                    )

                    if prayer.id != prayers.last?.id {
                        Divider()
                            .padding(.horizontal, SafaSpacing.md)
                    }
                }
            }
        }
    }
}

// MARK: - Prayer Time Row

private struct PrayerTimeRow: View {
    let prayer: PrayerTime
    let isNotificationEnabled: Bool
    let onToggleNotification: () -> Void

    var body: some View {
        HStack {
            // Prayer indicator
            Circle()
                .fill(prayer.type.color)
                .frame(width: 8, height: 8)
                .accessibilityHidden(true)

            // Prayer name (with Sunset note for Maghrib)
            Text(prayer.type == .maghrib ? "Maghrib (Sunset)" : prayer.type.displayName)
                .font(SafaTypography.bodyLarge)
                .foregroundColor(SafaColors.Fallback.text)

            Spacer()

            // Time
            Text(prayer.time.formatted(date: .omitted, time: .shortened))
                .font(SafaTypography.bodyMedium)
                .foregroundColor(SafaColors.Fallback.secondaryText)
                .monospacedDigit()

            // Notification bell (obligatory prayers only)
            if prayer.type.isObligatory {
                Button {
                    onToggleNotification()
                } label: {
                    Image(systemName: isNotificationEnabled ? "bell.fill" : "bell.slash")
                        .font(.system(size: 14))
                        .foregroundColor(isNotificationEnabled ? .accentColor : SafaColors.Fallback.tertiaryText)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(isNotificationEnabled ? "Notification on for \(prayer.type.displayName)" : "Notification off for \(prayer.type.displayName)")
                .accessibilityHint("Double tap to toggle notification")
            }
        }
        .padding(.horizontal, SafaSpacing.md)
        .padding(.vertical, SafaSpacing.sm)
        .background(prayer.isNext ? Color.accentColor.opacity(0.1) : Color.clear)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(prayer.type.displayName) at \(prayer.time.formatted(date: .omitted, time: .shortened))\(prayer.isNext ? ", upcoming" : "")")
    }
}

// MARK: - Quick Action Button

private struct QuickActionButton: View {
    let icon: String
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            action()
        }) {
            VStack(spacing: SafaSpacing.xs) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(.accentColor)

                Text(title)
                    .font(SafaTypography.labelSmall)
                    .foregroundColor(SafaColors.Fallback.secondaryText)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, SafaSpacing.md)
            .background(Color(UIColor.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: SafaSpacing.CornerRadius.md))
        }
        .accessibilityLabel(title)
        .accessibilityHint("Double tap to open \(title)")
    }
}

// MARK: - Prayer Settings View (Placeholder)

private struct PrayerSettingsView: View {
    let viewModel: PrayerViewModel

    var body: some View {
        List {
            Section("Calculation Method") {
                ForEach(CalculationMethod.allCases) { method in
                    Button {
                        Task {
                            await viewModel.setCalculationMethod(method)
                        }
                    } label: {
                        HStack {
                            Text(method.displayName)
                            Spacer()
                            if viewModel.calculationMethod == method {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.accentColor)
                            }
                        }
                    }
                    .foregroundColor(SafaColors.Fallback.text)
                }
            }
        }
        .navigationTitle("Prayer Settings")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        PrayerView()
            .environment(Dependencies())
    }
}
