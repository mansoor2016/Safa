// MARK: - CalendarView.swift
// PURPOSE: Islamic calendar with Hijri dates and important events
// DEPENDENCIES: SwiftUI, CalendarEventModel, CalendarSubviews

import SwiftUI

struct CalendarView: View {
    @Environment(Dependencies.self) private var dependencies
    @State private var selectedDate = Date()
    @State private var currentMonth = Date()
    @State private var selectedEvent: CalendarEvent?
    @State private var showExportSheet = false
    @State private var searchText = ""

    private let calendar = Calendar.current
    private let hijriConverter = HijriDateConverter.shared

    private var filteredEvents: [CalendarEvent] {
        guard !searchText.isEmpty else { return [] }
        return CalendarEvent.allEvents.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.arabicName.contains(searchText)
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: SafaSpacing.lg) {
                SearchBar(
                    text: $searchText,
                    placeholder: "Search events..."
                )

                if searchText.isEmpty {
                    monthHeader
                    calendarGrid
                    selectedDateCard
                    upcomingEventsSection
                } else {
                    searchResultsSection
                }
            }
            .padding()
        }
        .navigationTitle("Calendar")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showExportSheet = true
                } label: {
                    Image(systemName: "square.and.arrow.up")
                }
            }
        }
        .sheet(item: $selectedEvent) { event in
            EventDetailSheet(event: event)
                .compactSheet()
        }
        .sheet(isPresented: $showExportSheet) {
            CalendarExportSheet()
                .compactSheet()
        }
    }

    // MARK: - Month Header

    private var monthHeader: some View {
        HStack {
            Button {
                withAnimation {
                    currentMonth = calendar.date(byAdding: .month, value: -1, to: currentMonth) ?? currentMonth
                }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.title2)
                    .foregroundColor(.accentColor)
            }

            Spacer()

            VStack(spacing: SafaSpacing.xxs) {
                Text(currentMonth.formatted(.dateTime.month(.wide).year()))
                    .font(SafaTypography.titleMedium)
                    .foregroundColor(SafaColors.Fallback.text)

                Text(hijriConverter.hijriDateString(from: currentMonth, style: .monthYear))
                    .font(SafaTypography.bodySmall)
                    .foregroundColor(SafaColors.Fallback.secondaryText)
            }

            Spacer()

            Button {
                withAnimation {
                    currentMonth = calendar.date(byAdding: .month, value: 1, to: currentMonth) ?? currentMonth
                }
            } label: {
                Image(systemName: "chevron.right")
                    .font(.title2)
                    .foregroundColor(.accentColor)
            }
        }
        .padding(.horizontal)
    }

    // MARK: - Calendar Grid

    private var calendarGrid: some View {
        VStack(spacing: SafaSpacing.sm) {
            // Day headers
            HStack {
                ForEach(["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"], id: \.self) { day in
                    Text(day)
                        .font(SafaTypography.labelSmall)
                        .foregroundColor(day == "Fri" ? .accentColor : SafaColors.Fallback.secondaryText)
                        .frame(maxWidth: .infinity)
                }
            }

            // Days grid
            let days = daysInMonth()
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: SafaSpacing.xs) {
                ForEach(days, id: \.self) { date in
                    if let date = date {
                        CalendarDayCell(
                            date: date,
                            isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                            isToday: calendar.isDateInToday(date),
                            hasEvent: hasEvent(on: date),
                            isFriday: calendar.component(.weekday, from: date) == 6
                        ) {
                            selectedDate = date
                        }
                    } else {
                        Color.clear
                            .frame(minHeight: 44)
                    }
                }
            }
            .dynamicTypeSize(...DynamicTypeSize.accessibility3)
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: SafaSpacing.CornerRadius.lg))
    }

    private func daysInMonth() -> [Date?] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: currentMonth) else {
            return []
        }

        let firstWeekday = calendar.component(.weekday, from: monthInterval.start)
        var days: [Date?] = Array(repeating: nil, count: firstWeekday - 1)

        var current = monthInterval.start
        while current < monthInterval.end {
            days.append(current)
            current = calendar.date(byAdding: .day, value: 1, to: current) ?? current
        }

        while days.count % 7 != 0 {
            days.append(nil)
        }

        return days
    }

    private func hasEvent(on date: Date) -> Bool {
        let (_, hijriMonth, hijriDay) = hijriConverter.hijriComponents(from: date)
        return CalendarEvent.allEvents.contains { event in
            event.hijriMonth == hijriMonth && event.hijriDay == hijriDay
        }
    }

    // MARK: - Selected Date Card

    private var selectedDateCard: some View {
        ContentCard {
            VStack(alignment: .leading, spacing: SafaSpacing.sm) {
                HStack {
                    VStack(alignment: .leading, spacing: SafaSpacing.xxs) {
                        Text(selectedDate.formatted(date: .complete, time: .omitted))
                            .font(SafaTypography.titleSmall)
                            .foregroundColor(SafaColors.Fallback.text)

                        Text(hijriConverter.hijriDateString(from: selectedDate, style: .full))
                            .font(SafaTypography.bodyMedium)
                            .foregroundColor(.accentColor)
                    }

                    Spacer()

                    if calendar.isDateInToday(selectedDate) {
                        Text("Today")
                            .font(SafaTypography.labelSmall)
                            .foregroundColor(.white)
                            .padding(.horizontal, SafaSpacing.sm)
                            .padding(.vertical, SafaSpacing.xxs)
                            .background(Color.accentColor)
                            .clipShape(Capsule())
                    }
                }

                let events = eventsOnDate(selectedDate)
                if !events.isEmpty {
                    Divider()

                    ForEach(events) { event in
                        Button {
                            selectedEvent = event
                        } label: {
                            HStack {
                                Circle()
                                    .fill(event.color)
                                    .frame(width: 8, height: 8)

                                Text(event.name)
                                    .font(SafaTypography.bodyMedium)
                                    .foregroundColor(SafaColors.Fallback.text)

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(SafaColors.Fallback.tertiaryText)
                            }
                        }
                    }
                }
            }
        }
    }

    private func eventsOnDate(_ date: Date) -> [CalendarEvent] {
        let (_, hijriMonth, hijriDay) = hijriConverter.hijriComponents(from: date)
        return CalendarEvent.allEvents.filter { event in
            event.hijriMonth == hijriMonth && event.hijriDay == hijriDay
        }
    }

    // MARK: - Upcoming Events Section

    private var upcomingEventsSection: some View {
        TitledCard(title: "Upcoming Events", subtitle: "Islamic calendar") {
            VStack(spacing: SafaSpacing.sm) {
                ForEach(upcomingEvents().prefix(5)) { event in
                    Button {
                        selectedEvent = event
                    } label: {
                        HStack {
                            Circle()
                                .fill(event.color)
                                .frame(width: 12, height: 12)

                            VStack(alignment: .leading, spacing: SafaSpacing.xxs) {
                                Text(event.name)
                                    .font(SafaTypography.bodyMedium)
                                    .foregroundColor(SafaColors.Fallback.text)

                                if let gregorianDate = event.nextOccurrence() {
                                    Text(gregorianDate.formatted(date: .abbreviated, time: .omitted))
                                        .font(SafaTypography.labelSmall)
                                        .foregroundColor(SafaColors.Fallback.secondaryText)
                                }
                            }

                            Spacer()

                            if let daysUntil = event.daysUntilNextOccurrence() {
                                Text("\(daysUntil) days")
                                    .font(SafaTypography.labelSmall)
                                    .foregroundColor(.accentColor)
                            }
                        }
                    }

                    if event.id != upcomingEvents().prefix(5).last?.id {
                        Divider()
                    }
                }
            }
        }
    }

    private func upcomingEvents() -> [CalendarEvent] {
        CalendarEvent.allEvents.sorted { event1, event2 in
            (event1.daysUntilNextOccurrence() ?? 365) < (event2.daysUntilNextOccurrence() ?? 365)
        }
    }

    // MARK: - Search Results

    private var searchResultsSection: some View {
        Group {
            if filteredEvents.isEmpty {
                ContentUnavailableView(
                    "No Events Found",
                    systemImage: "magnifyingglass",
                    description: Text("No events matching \"\(searchText)\"")
                )
            } else {
                VStack(spacing: SafaSpacing.sm) {
                    ForEach(filteredEvents) { event in
                        Button {
                            selectedEvent = event
                        } label: {
                            HStack {
                                Circle()
                                    .fill(event.color)
                                    .frame(width: 12, height: 12)

                                VStack(alignment: .leading, spacing: SafaSpacing.xxs) {
                                    Text(event.name)
                                        .font(SafaTypography.bodyMedium)
                                        .foregroundColor(SafaColors.Fallback.text)

                                    Text(event.arabicName)
                                        .font(SafaTypography.labelSmall)
                                        .foregroundColor(SafaColors.Fallback.secondaryText)
                                        .environment(\.layoutDirection, .rightToLeft)
                                        .accessibilityArabic()
                                }

                                Spacer()

                                if let daysUntil = event.daysUntilNextOccurrence() {
                                    Text("\(daysUntil) days")
                                        .font(SafaTypography.labelSmall)
                                        .foregroundColor(.accentColor)
                                }
                            }
                            .padding(SafaSpacing.md)
                            .background(Color(UIColor.secondarySystemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: SafaSpacing.CornerRadius.lg))
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        CalendarView()
            .environment(Dependencies())
    }
}
