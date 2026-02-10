// MARK: - CalendarSubviews.swift
// PURPOSE: Supporting views for calendar feature
// DEPENDENCIES: SwiftUI, CalendarEventModel

import SwiftUI

// MARK: - Day Cell

struct CalendarDayCell: View {
    let date: Date
    let isSelected: Bool
    let isToday: Bool
    let hasEvent: Bool
    let isFriday: Bool
    let action: () -> Void

    private let calendar = Calendar.current
    private let hijriConverter = HijriDateConverter.shared

    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Text("\(calendar.component(.day, from: date))")
                    .font(SafaTypography.bodyMedium)
                    .foregroundColor(textColor)

                let (_, _, hijriDay) = hijriConverter.hijriComponents(from: date)
                Text("\(hijriDay)")
                    .font(SafaTypography.labelSmall)
                    .foregroundColor(isSelected ? .white.opacity(0.7) : SafaColors.Fallback.tertiaryText)

                if hasEvent {
                    Circle()
                        .fill(isSelected ? Color.white : Color.accentColor)
                        .frame(width: 4, height: 4)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(minHeight: 44)
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }

    private var textColor: Color {
        if isSelected {
            return .white
        } else if isToday {
            return .accentColor
        } else if isFriday {
            return .green
        } else {
            return SafaColors.Fallback.text
        }
    }

    private var backgroundColor: Color {
        if isSelected {
            return Color.accentColor
        } else if isToday {
            return Color.accentColor.opacity(0.1)
        } else {
            return Color.clear
        }
    }
}

// MARK: - Event Detail Sheet

struct EventDetailSheet: View {
    let event: CalendarEvent
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: SafaSpacing.lg) {
                    headerSection
                    Divider()
                    dateSection
                    Divider()
                    descriptionSection
                    addToCalendarButton
                }
                .padding()
            }
            .navigationTitle("Event Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(SafaSpacing.CornerRadius.xl)
    }

    // MARK: - Sections

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: SafaSpacing.sm) {
            HStack {
                Circle()
                    .fill(event.color)
                    .frame(width: 16, height: 16)

                Text(event.isHoliday ? "Holiday" : "Observance")
                    .font(SafaTypography.labelMedium)
                    .foregroundColor(event.color)
            }

            Text(event.name)
                .font(SafaTypography.headlineMedium)
                .foregroundColor(SafaColors.Fallback.text)

            Text(event.arabicName)
                .font(SafaTypography.arabicMedium)
                .foregroundColor(SafaColors.Fallback.secondaryText)
        }
    }

    private var dateSection: some View {
        VStack(alignment: .leading, spacing: SafaSpacing.sm) {
            Text("Date")
                .font(SafaTypography.labelMedium)
                .foregroundColor(SafaColors.Fallback.secondaryText)

            Text("\(event.hijriDay) \(CalendarEvent.hijriMonthNames[event.hijriMonth])")
                .font(SafaTypography.bodyLarge)
                .foregroundColor(SafaColors.Fallback.text)

            if let gregorianDate = event.nextOccurrence() {
                Text("Next occurrence: \(gregorianDate.formatted(date: .complete, time: .omitted))")
                    .font(SafaTypography.bodyMedium)
                    .foregroundColor(.accentColor)

                if let daysUntil = event.daysUntilNextOccurrence() {
                    Text("(\(daysUntil) days from now)")
                        .font(SafaTypography.bodySmall)
                        .foregroundColor(SafaColors.Fallback.secondaryText)
                }
            }
        }
    }

    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: SafaSpacing.sm) {
            Text("About")
                .font(SafaTypography.labelMedium)
                .foregroundColor(SafaColors.Fallback.secondaryText)

            Text(event.description)
                .font(SafaTypography.bodyMedium)
                .foregroundColor(SafaColors.Fallback.text)
        }
    }

    private var addToCalendarButton: some View {
        Button {
            // Add to system calendar
        } label: {
            Label("Add to Calendar", systemImage: "calendar.badge.plus")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
        .padding(.top)
    }
}

// MARK: - Calendar Export Sheet

struct CalendarExportSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var exportService = CalendarExportService.shared
    @State private var includeEid = true
    @State private var includeRamadan = true
    @State private var includeHolidays = true
    @State private var includePrayerTimes = false
    @State private var isExporting = false
    @State private var exportError: String?
    @State private var showShareSheet = false
    @State private var icsFileURL: URL?

    var body: some View {
        NavigationStack {
            List {
                eventsSection
                exportOptionsSection
                errorSection
            }
            .navigationTitle("Export Calendar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(isPresented: $showShareSheet) {
                if let url = icsFileURL {
                    ShareSheet(items: [url]) { _ in }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(SafaSpacing.CornerRadius.xl)
    }

    // MARK: - Sections

    private var eventsSection: some View {
        Section {
            Toggle("Eid al-Fitr & Eid al-Adha", isOn: $includeEid)
            Toggle("Ramadan (Start & Laylatul Qadr)", isOn: $includeRamadan)
            Toggle("Islamic Holidays", isOn: $includeHolidays)
            Toggle("Daily Prayer Times", isOn: $includePrayerTimes)
        } header: {
            Text("Events to Export")
        } footer: {
            Text("Select which Islamic events to add to your calendar.")
        }
    }

    private var exportOptionsSection: some View {
        Section("Export To") {
            Button {
                Task { await exportToAppleCalendar() }
            } label: {
                HStack {
                    Image(systemName: "calendar")
                        .foregroundColor(.red)
                    Text("Add to Apple Calendar")
                    Spacer()
                    if isExporting { ProgressView() }
                }
            }
            .disabled(isExporting || !hasSelection)

            Button {
                Task { await exportAsICS() }
            } label: {
                HStack {
                    Image(systemName: "doc.text")
                        .foregroundColor(.blue)
                    Text("Export as .ics File")
                    Spacer()
                    if isExporting { ProgressView() }
                }
            }
            .disabled(isExporting || !hasSelection)
        }
    }

    @ViewBuilder
    private var errorSection: some View {
        if let error = exportError {
            Section {
                Text(error)
                    .foregroundColor(.red)
            }
        }
    }

    // MARK: - Helpers

    private var hasSelection: Bool {
        includeEid || includeRamadan || includeHolidays
    }

    private func exportToAppleCalendar() async {
        isExporting = true
        exportError = nil

        let options = CalendarExportOptions(
            includeEid: includeEid,
            includeRamadan: includeRamadan,
            includeIslamicHolidays: includeHolidays,
            includePrayerTimes: includePrayerTimes
        )

        let events = exportService.getSampleEvents(options: options)

        do {
            let count = try await exportService.exportToCalendar(events: events)
            isExporting = false
            ToastService.shared.show(Toast(
                message: "\(count) events added to calendar",
                type: .success
            ))
            dismiss()
        } catch {
            isExporting = false
            exportError = error.localizedDescription
        }
    }

    private func exportAsICS() async {
        isExporting = true
        exportError = nil

        let options = CalendarExportOptions(
            includeEid: includeEid,
            includeRamadan: includeRamadan,
            includeIslamicHolidays: includeHolidays,
            includePrayerTimes: includePrayerTimes
        )

        let events = exportService.getSampleEvents(options: options)

        do {
            icsFileURL = try exportService.createICSFile(events: events)
            isExporting = false
            showShareSheet = true
        } catch {
            isExporting = false
            exportError = error.localizedDescription
        }
    }
}
