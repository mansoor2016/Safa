// MARK: - CalendarView.swift
// PURPOSE: Islamic calendar with Hijri dates and important events
// DEPENDENCIES: SwiftUI

import SwiftUI

struct CalendarView: View {
    @Environment(Dependencies.self) private var dependencies
    @State private var selectedDate = Date()
    @State private var currentMonth = Date()
    @State private var selectedEvent: CalendarEvent?

    private let calendar = Calendar.current
    private let hijriConverter = HijriDateConverter.shared

    var body: some View {
        ScrollView {
            VStack(spacing: SafaSpacing.lg) {
                // Month header
                monthHeader

                // Calendar grid
                calendarGrid

                // Selected date info
                selectedDateCard

                // Upcoming events
                upcomingEventsSection
            }
            .padding()
        }
        .navigationTitle("Calendar")
        .navigationBarTitleDisplayMode(.large)
        .sheet(item: $selectedEvent) { event in
            EventDetailSheet(event: event)
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
                        DayCell(
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
                            .frame(height: 44)
                    }
                }
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: SafaSpacing.CornerRadius.lg))
    }

    private func daysInMonth() -> [Date?] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: currentMonth),
              let monthFirstWeek = calendar.dateInterval(of: .weekOfMonth, for: monthInterval.start) else {
            return []
        }

        let firstWeekday = calendar.component(.weekday, from: monthInterval.start)
        var days: [Date?] = Array(repeating: nil, count: firstWeekday - 1)

        var current = monthInterval.start
        while current < monthInterval.end {
            days.append(current)
            current = calendar.date(byAdding: .day, value: 1, to: current) ?? current
        }

        // Fill remaining cells
        while days.count % 7 != 0 {
            days.append(nil)
        }

        return days
    }

    private func hasEvent(on date: Date) -> Bool {
        // Check if there's an Islamic event on this date
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

                // Events on this date
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
}

// MARK: - Day Cell

private struct DayCell: View {
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
                    .font(.system(size: 8))
                    .foregroundColor(isSelected ? .white.opacity(0.7) : SafaColors.Fallback.tertiaryText)

                if hasEvent {
                    Circle()
                        .fill(isSelected ? Color.white : Color.accentColor)
                        .frame(width: 4, height: 4)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 44)
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

// MARK: - Islamic Event

struct CalendarEvent: Identifiable {
    let id = UUID()
    let name: String
    let arabicName: String
    let description: String
    let hijriMonth: Int
    let hijriDay: Int
    let type: EventType
    let isHoliday: Bool

    enum EventType {
        case holiday, observance, specialNight, blessed
    }

    var color: Color {
        switch type {
        case .holiday: return .green
        case .observance: return .blue
        case .specialNight: return .purple
        case .blessed: return .orange
        }
    }

    func nextOccurrence() -> Date? {
        let hijriCalendar = Calendar(identifier: .islamicUmmAlQura)
        var components = hijriCalendar.dateComponents([.year], from: Date())
        components.month = hijriMonth
        components.day = hijriDay

        if let date = hijriCalendar.date(from: components), date > Date() {
            return date
        }

        // Try next year
        components.year = (components.year ?? 0) + 1
        return hijriCalendar.date(from: components)
    }

    func daysUntilNextOccurrence() -> Int? {
        guard let occurrence = nextOccurrence() else { return nil }
        return Calendar.current.dateComponents([.day], from: Date(), to: occurrence).day
    }

    static let allEvents: [CalendarEvent] = [
        // Muharram
        CalendarEvent(
            name: "Islamic New Year",
            arabicName: "رأس السنة الهجرية",
            description: "The first day of the Islamic calendar year.",
            hijriMonth: 1, hijriDay: 1,
            type: .holiday, isHoliday: true
        ),
        CalendarEvent(
            name: "Day of Ashura",
            arabicName: "يوم عاشوراء",
            description: "The 10th day of Muharram, commemorating various historical events. It is recommended to fast on this day.",
            hijriMonth: 1, hijriDay: 10,
            type: .observance, isHoliday: false
        ),

        // Rabi' al-Awwal
        CalendarEvent(
            name: "Mawlid al-Nabi",
            arabicName: "المولد النبوي",
            description: "The birthday of Prophet Muhammad (PBUH).",
            hijriMonth: 3, hijriDay: 12,
            type: .holiday, isHoliday: true
        ),

        // Rajab
        CalendarEvent(
            name: "Isra and Mi'raj",
            arabicName: "الإسراء والمعراج",
            description: "The night journey of Prophet Muhammad (PBUH) from Makkah to Jerusalem and his ascension to the heavens.",
            hijriMonth: 7, hijriDay: 27,
            type: .specialNight, isHoliday: false
        ),

        // Sha'ban
        CalendarEvent(
            name: "Laylat al-Bara'at",
            arabicName: "ليلة البراءة",
            description: "The Night of Forgiveness, a blessed night in the middle of Sha'ban.",
            hijriMonth: 8, hijriDay: 15,
            type: .specialNight, isHoliday: false
        ),

        // Ramadan
        CalendarEvent(
            name: "Beginning of Ramadan",
            arabicName: "بداية رمضان",
            description: "The first day of the blessed month of fasting.",
            hijriMonth: 9, hijriDay: 1,
            type: .holiday, isHoliday: true
        ),
        CalendarEvent(
            name: "Laylat al-Qadr",
            arabicName: "ليلة القدر",
            description: "The Night of Power, better than a thousand months. It falls in the last 10 nights of Ramadan, most likely on the 27th.",
            hijriMonth: 9, hijriDay: 27,
            type: .specialNight, isHoliday: false
        ),

        // Shawwal
        CalendarEvent(
            name: "Eid al-Fitr",
            arabicName: "عيد الفطر",
            description: "The Festival of Breaking the Fast, celebrating the end of Ramadan.",
            hijriMonth: 10, hijriDay: 1,
            type: .holiday, isHoliday: true
        ),

        // Dhul Hijjah
        CalendarEvent(
            name: "Day of Arafah",
            arabicName: "يوم عرفة",
            description: "The most important day of Hajj. Fasting on this day expiates sins of the previous and coming year.",
            hijriMonth: 12, hijriDay: 9,
            type: .blessed, isHoliday: false
        ),
        CalendarEvent(
            name: "Eid al-Adha",
            arabicName: "عيد الأضحى",
            description: "The Festival of Sacrifice, commemorating Prophet Ibrahim's willingness to sacrifice his son.",
            hijriMonth: 12, hijriDay: 10,
            type: .holiday, isHoliday: true
        ),
    ]
}

// MARK: - Event Detail Sheet

private struct EventDetailSheet: View {
    let event: CalendarEvent
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: SafaSpacing.lg) {
                    // Header
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
                            .font(SafaTypography.arabicMediumFallback)
                            .foregroundColor(SafaColors.Fallback.secondaryText)
                    }

                    Divider()

                    // Date info
                    VStack(alignment: .leading, spacing: SafaSpacing.sm) {
                        Text("Date")
                            .font(SafaTypography.labelMedium)
                            .foregroundColor(SafaColors.Fallback.secondaryText)

                        let hijriMonths = ["", "Muharram", "Safar", "Rabi' al-Awwal", "Rabi' al-Thani", "Jumada al-Awwal", "Jumada al-Thani", "Rajab", "Sha'ban", "Ramadan", "Shawwal", "Dhul Qi'dah", "Dhul Hijjah"]
                        Text("\(event.hijriDay) \(hijriMonths[event.hijriMonth])")
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

                    Divider()

                    // Description
                    VStack(alignment: .leading, spacing: SafaSpacing.sm) {
                        Text("About")
                            .font(SafaTypography.labelMedium)
                            .foregroundColor(SafaColors.Fallback.secondaryText)

                        Text(event.description)
                            .font(SafaTypography.bodyMedium)
                            .foregroundColor(SafaColors.Fallback.text)
                    }

                    // Add to Calendar button
                    Button {
                        // Add to system calendar
                    } label: {
                        Label("Add to Calendar", systemImage: "calendar.badge.plus")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .padding(.top)
                }
                .padding()
            }
            .navigationTitle("Event Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        CalendarView()
            .environment(Dependencies())
    }
}
