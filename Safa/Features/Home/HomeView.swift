// MARK: - HomeView.swift
// PURPOSE: Main home screen with prayer countdown and quick actions
// DEPENDENCIES: SwiftUI, Combine

import SwiftUI
import Combine
import SafaShared

struct HomeView: View {
    @Environment(Dependencies.self) private var dependencies
    @Environment(AppRouter.self) private var router

    @State private var nextPrayer: PrayerTime?
    @State private var todayPrayers: [PrayerTime] = []
    @State private var loggedPrayers: Set<PrayerType> = []
    @State private var hijriDate = ""
    @State private var dailyVerse: Ayah?
    @State private var quranProgress: QuranProgress?
    @State private var isRamadan = false
    @State private var showRamadanBanner = true
    @State private var suhoorTime: Date?
    @State private var iftarTime: Date?
    @State private var currentRamadanDay: Int = 0
    @State private var daysUntilRamadan: Int?
    @State private var isLastTenNights = false
    @State private var isRamadanBannerExpanded = false
    @State private var showShareBanner = !ShareBanner.isDismissed
    @State private var loadError: Error?
    @State private var resolvedActions: [HomeAction] = []
    @State private var hideResumeCard = false
    @State private var isResumeCardExpanded = false
    @State private var isDailyVerseExpanded = true

    // Timer to advance nextPrayer when grace window expires
    let graceExpiryTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    // Eid state
    @State private var currentEidType: EidType?
    @State private var eidDayNumber: Int = 0
    @State private var showEidBanner = true
    @State private var isEidBannerExpanded = false
    @State private var daysUntilNextEid: Int?
    @State private var nextEidType: EidType?

    // Banner dismiss key (reappears next day)
    private var bannerDismissKey: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        return "ramadan_banner_dismissed_\(dateFormatter.string(from: Date()))"
    }

    private var eidBannerDismissKey: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        return "\(AppConstants.StorageKeys.eidBannerDismissedPrefix)\(dateFormatter.string(from: Date()))"
    }

    private var resumeCardDismissKey: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        return "resume_card_dismissed_\(dateFormatter.string(from: Date()))"
    }

    // MARK: - Banner Resolver Inputs

    private var calendarState: HomeBannerResolver.IslamicCalendarState {
        HomeBannerResolver.IslamicCalendarState(
            isRamadan: isRamadan,
            currentRamadanDay: currentRamadanDay,
            isLastTenNights: isLastTenNights,
            daysUntilRamadan: daysUntilRamadan,
            currentEidType: currentEidType,
            eidDayNumber: eidDayNumber,
            nextEidType: nextEidType,
            daysUntilNextEid: daysUntilNextEid,
            isForceRamadanMode: FeatureFlags.shared.isEnabled(.ramadanMode),
            isForceEidAlFitr: FeatureFlags.shared.isEnabled(.forceEidAlFitr),
            isForceEidAlAdha: FeatureFlags.shared.isEnabled(.forceEidAlAdha)
        )
    }

    private var dismissState: HomeBannerResolver.DismissState {
        HomeBannerResolver.DismissState(
            isRamadanBannerDismissedToday: !showRamadanBanner || UserDefaults.standard.bool(forKey: bannerDismissKey),
            isEidBannerDismissedToday: !showEidBanner || UserDefaults.standard.bool(forKey: eidBannerDismissKey),
            isShareBannerDismissedPermanently: !showShareBanner,
            isResumeCardDismissedToday: hideResumeCard || UserDefaults.standard.bool(forKey: resumeCardDismissKey)
        )
    }

    var body: some View {
        ScrollableScreen(stickyContent: nextPrayerChip) {
            if todayPrayers.isEmpty && hijriDate.isEmpty {
                if loadError != nil {
                    ErrorView.loadFailed(retry: { await loadHomeData() })
                } else {
                    HomeSkeletonView()
                }
            } else {
            VStack(spacing: SafaSpacing.lg) {
                // Date subheader (Option 4: visible below large title, scrolls away)
                dateSubheader

                // Next prayer card
                if let prayer = nextPrayer {
                    NextPrayerHomeCard(prayer: prayer) {
                        router.selectedTab = "prayer"
                    }
                }

                // Ramadan banner (collapsible, reappears next day)
                ramadanBannerSection

                // Eid banner (during Eid or 7 days before)
                eidBannerSection

                // Resume where you left off (dismissable, reappears next day)
                if let progress = quranProgress,
                   case .visible = HomeBannerResolver.resolveResumeCard(
                       quran: .init(lastSurah: progress.lastSurah, lastAyah: progress.lastAyah),
                       dismiss: dismissState
                   ) {
                    resumeQuranCard(progress)
                }

                // Quick actions
                quickActions

                // Daily verse
                if let verse = dailyVerse {
                    dailyVerseCard(verse)
                }

                // Progress summary
                progressCard

                // Contextual reminders
                contextualReminders

                // Share app banner (hidden once user shares)
                if HomeBannerResolver.resolveShareBanner(dismiss: dismissState) == .visible {
                    ShareBanner {
                        withAnimation {
                            showShareBanner = false
                        }
                    }
                }
            }
            .padding()
            } // end else (skeleton)
        }
        .navigationTitle("Safa")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: SafaSpacing.sm) {
                    if dependencies.llmService.availability.isAvailable {
                        Button { router.navigate(to: .chat) } label: {
                            Image(systemName: "sparkles")
                        }
                    }
                    Button { router.navigate(to: .settings) } label: {
                        Image(systemName: "gearshape")
                    }
                }
            }
        }
        .task {
            await loadHomeData()
        }
        .onReceive(graceExpiryTimer) { _ in
            let now = Date()
            // If current nextPrayer's grace window has expired, advance to the truly-next prayer
            if let current = nextPrayer,
               now.timeIntervalSince(current.time) >= PrayerTimeConstants.graceInterval {
                nextPrayer = todayPrayers.first { $0.time > now && $0.type.isObligatory }
            }
        }
        .onAppear {
            Task { await reloadLoggedPrayers() }
            // Recalculate next prayer (may have changed since last appear)
            // Include prayers in grace window (0-15 min after prayer time)
            let now = Date()
            nextPrayer = todayPrayers.first {
                $0.type.isObligatory && ($0.time > now || isPrayerTimeNow($0.time, at: now))
            }
            // Re-check Ramadan state (respects Force Ramadan Mode toggle)
            isRamadan = HijriDateConverter.shared.isRamadan() || FeatureFlags.shared.isEnabled(.ramadanMode)
            if isRamadan && !HijriDateConverter.shared.isRamadan() {
                // Forced mode — set a sensible day
                currentRamadanDay = max(currentRamadanDay, 1)
                daysUntilRamadan = nil
            }
            // Re-check banner dismiss state (synced with Settings toggle)
            showRamadanBanner = !UserDefaults.standard.bool(forKey: bannerDismissKey)
            // Re-check Eid state (respects Force Eid Mode toggles)
            updateEidState()
            showEidBanner = !UserDefaults.standard.bool(forKey: eidBannerDismissKey)
            // Re-resolve quick actions (time/prayer may have changed)
            resolvedActions = HomeIntentResolver.resolve(
                currentDate: Date(),
                nextPrayer: nextPrayer,
                loggedPrayers: loggedPrayers,
                streaks: dependencies.userState.streaks
            )
        }
    }

    // MARK: - Ramadan Banner Section

    @ViewBuilder
    private var ramadanBannerSection: some View {
        let visibility = HomeBannerResolver.resolveRamadanBanner(
            calendar: calendarState,
            dismiss: dismissState
        )

        // Hide banner after iftar until next suhoor countdown begins.
        // Only evaluate when times are loaded — if nil, show the banner (don't hide it).
        let isPostIftar: Bool = {
            guard isRamadan, suhoorTime != nil || iftarTime != nil else { return false }
            let target = RamadanCountdownHelpers.resolveTarget(
                now: Date(), suhoorTime: suhoorTime, iftarTime: iftarTime
            )
            switch target {
            case .nextSuhoor, .complete: return true
            case .suhoor, .iftar: return false
            }
        }()

        if visibility != .hidden && !isPostIftar {
            ramadanBannerExpandedContent
                .onTapGesture {
                    if isRamadan {
                        router.selectedTab = "prayer"
                    } else {
                        router.navigate(to: .ramadan)
                    }
                }
        }
    }

    @ViewBuilder
    private var ramadanBannerExpandedContent: some View {
        if isRamadan {
            if isLastTenNights {
                LastTenNightsBanner(
                    currentNight: currentRamadanDay,
                    onDismiss: dismissBanner
                )
            } else {
                RamadanBanner(
                    suhoorTime: suhoorTime,
                    iftarTime: iftarTime,
                    onDismiss: dismissBanner
                )
            }
        } else if let days = daysUntilRamadan, days <= 30, days > 0 {
            PreRamadanBanner(
                daysUntil: days,
                onDismiss: dismissBanner
            )
        }
    }

    private func dismissBanner() {
        withAnimation {
            UserDefaults.standard.set(true, forKey: bannerDismissKey)
            showRamadanBanner = false
            // Turn off Force Ramadan flag so Settings toggle reflects dismissal
            FeatureFlags.shared.removeOverride(.ramadanMode)
        }
    }

    // MARK: - Eid Banner Section

    @ViewBuilder
    private var eidBannerSection: some View {
        let eidVisibility = HomeBannerResolver.resolveEidBanner(
            calendar: calendarState,
            dismiss: dismissState
        )

        if eidVisibility != .hidden {
            VStack(spacing: 0) {
                // Collapsed header row
                eidBannerCollapsedRow
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            isEidBannerExpanded.toggle()
                        }
                    }

                // Expanded content
                if isEidBannerExpanded {
                    eidBannerExpandedContent
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: SafaSpacing.CornerRadius.lg))
        }
    }

    private var eidBannerCollapsedRow: some View {
        HStack(spacing: SafaSpacing.sm) {
            Image(systemName: currentEidType?.icon ?? nextEidType?.icon ?? "sparkles")
                .font(.body)
                .foregroundColor(currentEidType != nil ? .green : .accentColor)

            Text(eidBannerSummaryText)
                .font(SafaTypography.titleSmall)
                .foregroundColor(SafaColors.Fallback.text)

            Spacer()

            Image(systemName: isEidBannerExpanded ? "chevron.down" : "chevron.right")
                .font(.caption)
                .foregroundColor(SafaColors.Fallback.tertiaryText)

            Button {
                dismissEidBanner()
            } label: {
                Image(systemName: "xmark")
                    .font(.caption2)
                    .foregroundColor(SafaColors.Fallback.tertiaryText)
                    .padding(SafaSpacing.xxs)
            }
        }
        .padding(.horizontal, SafaSpacing.md)
        .padding(.vertical, SafaSpacing.sm)
        .background(Color(UIColor.secondarySystemBackground))
    }

    @ViewBuilder
    private var eidBannerExpandedContent: some View {
        if let eidType = currentEidType {
            EidBanner(
                eidType: eidType,
                dayNumber: eidDayNumber,
                eidPrayerTime: nil,
                onShare: { shareEidGreeting(eidType: eidType) },
                onDismiss: dismissEidBanner
            )
        } else if let eidType = nextEidType, let days = daysUntilNextEid, days <= 7, days > 0 {
            PreEidBanner(
                eidType: eidType,
                daysUntil: days,
                onDismiss: dismissEidBanner
            )
        }
    }

    private var eidBannerSummaryText: String {
        if let eidType = currentEidType {
            return "\(eidType.displayName) - Day \(eidDayNumber)"
        } else if let eidType = nextEidType, let days = daysUntilNextEid, days <= 7, days > 0 {
            return "\(days) day\(days == 1 ? "" : "s") until \(eidType.displayName)"
        }
        return "Eid"
    }

    private func dismissEidBanner() {
        withAnimation {
            UserDefaults.standard.set(true, forKey: eidBannerDismissKey)
            showEidBanner = false
            // Turn off Force Eid flags so Settings toggle reflects dismissal
            FeatureFlags.shared.removeOverride(.forceEidAlFitr)
            FeatureFlags.shared.removeOverride(.forceEidAlAdha)
        }
    }

    private func shareEidGreeting(eidType: EidType) {
        guard let message = eidType.shareMessages.randomElement() else { return }
        let hijriYear = HijriDateConverter.shared.hijriComponents(from: Date()).year
        let shareService = ShareService(userState: dependencies.userState)
        shareService.shareEidGreeting(eidType: eidType, message: message, hijriYear: hijriYear)
    }

    private func updateEidState() {
        // Check for forced Eid mode (developer options)
        if FeatureFlags.shared.isEnabled(.forceEidAlFitr) {
            currentEidType = .fitr
            eidDayNumber = 1
            daysUntilNextEid = nil
            nextEidType = nil
            return
        }
        if FeatureFlags.shared.isEnabled(.forceEidAlAdha) {
            currentEidType = .adha
            eidDayNumber = 1
            daysUntilNextEid = nil
            nextEidType = nil
            return
        }

        currentEidType = HijriDateConverter.shared.currentEidType()
        eidDayNumber = HijriDateConverter.shared.eidDayNumber() ?? 0

        if currentEidType == nil {
            if let nearest = HijriDateConverter.shared.nearestUpcomingEid() {
                nextEidType = nearest.type
                daysUntilNextEid = nearest.daysUntil
            } else {
                nextEidType = nil
                daysUntilNextEid = nil
            }
        } else {
            nextEidType = nil
            daysUntilNextEid = nil
        }
    }

    // MARK: - Next Prayer Chip (Sticky Toolbar)

    private func nextPrayerChip() -> some View {
        Group {
            if let prayer = nextPrayer {
                NextPrayerChip(prayer: prayer) {
                    router.selectedTab = "prayer"
                }
            }
        }
    }

    // MARK: - Date Subheader

    /// Date line below large title (scrolls away with content)
    private var dateSubheader: some View {
        HStack {
            Text(Date().formatted(.dateTime.weekday(.wide).day().month(.wide)))
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Spacer()

            if isRamadan {
                Label(hijriDate, systemImage: "moon.stars.fill")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.purple)
            } else {
                Text(hijriDate)
                    .font(.subheadline.weight(.medium))
            }
        }
    }

    // MARK: - Quick Actions

    private var quickActions: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: SafaSpacing.md) {
            ForEach(resolvedActions) { action in
                quickActionCard(for: action)
            }
        }
    }

    @ViewBuilder
    private func quickActionCard(for action: HomeAction) -> some View {
        let card = QuickActionCard(
            icon: action.icon,
            title: action.title,
            subtitle: action.subtitle,
            color: color(for: action.colorName)
        ) {
            navigate(to: action.destination)
        }

        switch action.destination {
        case .disabled(let feature):
            card.disabledFeature(isDisabled: true, name: feature)
        default:
            card
        }
    }

    private func color(for name: HomeAction.HomeActionColor) -> Color {
        switch name {
        case .green: return .green
        case .blue: return .blue
        case .purple: return .purple
        case .orange: return .orange
        case .red: return .red
        case .teal: return .teal
        case .indigo: return .indigo
        }
    }

    private func navigate(to destination: HomeAction.HomeActionDestination) {
        switch destination {
        case .tab(let tabId):
            router.selectedTab = tabId
        case .route(let routeName):
            switch routeName {
            case "dhikr": router.navigate(to: .dhikr)
            case "qibla": router.navigate(to: .qibla)
            case "learn": router.navigate(to: .learn)
            case "hadith": router.navigate(to: .hadith(collection: nil, hadithId: nil))
            case "chat": router.navigate(to: .chat)
            default: break
            }
        case .disabled:
            break // handled by .disabledFeature modifier
        }
    }

    // MARK: - Daily Verse Card

    private func dailyVerseCard(_ verse: Ayah) -> some View {
        VStack(spacing: 0) {
            // Collapsed header
            HStack(spacing: SafaSpacing.sm) {
                Image(systemName: "sun.max.fill")
                    .font(.body)
                    .foregroundColor(.orange)

                Text("Daily Verse")
                    .font(SafaTypography.titleSmall)
                    .foregroundColor(SafaColors.Fallback.text)

                Text("Surah \(verse.surahNumber):\(verse.ayahNumber)")
                    .font(SafaTypography.labelSmall)
                    .foregroundColor(SafaColors.Fallback.tertiaryText)

                Spacer()

                Image(systemName: isDailyVerseExpanded ? "chevron.down" : "chevron.right")
                    .font(.caption)
                    .foregroundColor(SafaColors.Fallback.tertiaryText)
            }
            .padding(.horizontal, SafaSpacing.md)
            .padding(.vertical, SafaSpacing.sm)
            .background(Color(UIColor.secondarySystemBackground))
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isDailyVerseExpanded.toggle()
                }
            }

            // Expanded content
            if isDailyVerseExpanded {
                VStack(alignment: .trailing, spacing: SafaSpacing.sm) {
                    Text(verse.textArabic)
                        .font(SafaTypography.arabicMedium)
                        .foregroundColor(SafaColors.Fallback.text)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .environment(\.layoutDirection, .rightToLeft)
                        .accessibilityArabic()

                    Text(verse.textTranslation)
                        .font(SafaTypography.bodySmall)
                        .foregroundColor(SafaColors.Fallback.secondaryText)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.horizontal, SafaSpacing.md)
                .padding(.vertical, SafaSpacing.sm)
                .background(Color(UIColor.secondarySystemBackground))
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: SafaSpacing.CornerRadius.lg))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Daily Verse, Surah \(verse.surahNumber) Ayah \(verse.ayahNumber). \(verse.textTranslation)")
        .accessibilityHint(isDailyVerseExpanded ? "Double tap to collapse" : "Double tap to expand")
    }

    // MARK: - Resume Card

    private func resumeQuranCard(_ progress: QuranProgress) -> some View {
        VStack(spacing: 0) {
            // Collapsed header row (matches Ramadan banner style)
            HStack(spacing: SafaSpacing.sm) {
                Image(systemName: "book.fill")
                    .font(.body)
                    .foregroundColor(.green)

                Text("Continue Reading Quran")
                    .font(SafaTypography.titleSmall)
                    .foregroundColor(SafaColors.Fallback.text)

                Spacer()

                Image(systemName: isResumeCardExpanded ? "chevron.down" : "chevron.right")
                    .font(.caption)
                    .foregroundColor(SafaColors.Fallback.tertiaryText)

                Button {
                    withAnimation {
                        UserDefaults.standard.set(true, forKey: resumeCardDismissKey)
                        hideResumeCard = true
                    }
                } label: {
                    Image(systemName: "xmark")
                        .font(.caption2)
                        .foregroundColor(SafaColors.Fallback.tertiaryText)
                        .padding(SafaSpacing.xxs)
                }
            }
            .padding(.horizontal, SafaSpacing.md)
            .padding(.vertical, SafaSpacing.sm)
            .background(Color(UIColor.secondarySystemBackground))
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isResumeCardExpanded.toggle()
                }
            }

            // Expanded content (tap to navigate)
            if isResumeCardExpanded {
                Button {
                    router.pendingQuranTarget = QuranNavigationTarget(
                        surahNumber: progress.lastSurah,
                        startAyah: progress.lastAyah
                    )
                    router.selectedTab = "quran"
                } label: {
                    HStack(spacing: SafaSpacing.md) {
                        VStack(alignment: .leading, spacing: SafaSpacing.xxs) {
                            Text("Surah \(progress.lastSurah), Ayah \(progress.lastAyah)")
                                .font(SafaTypography.bodyMedium)
                                .foregroundColor(SafaColors.Fallback.text)

                            Text("Juz \(progress.lastSurah.juzNumber) · \(Int(progress.progressPercentage))% complete")
                                .font(SafaTypography.labelSmall)
                                .foregroundColor(SafaColors.Fallback.secondaryText)
                        }

                        Spacer()

                        Image(systemName: "arrow.right.circle.fill")
                            .font(.title3)
                            .foregroundColor(.green)
                    }
                    .padding(.horizontal, SafaSpacing.md)
                    .padding(.vertical, SafaSpacing.sm)
                    .background(Color(UIColor.secondarySystemBackground))
                }
                .buttonStyle(.plain)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: SafaSpacing.CornerRadius.lg))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Continue Reading Quran, Surah \(progress.lastSurah), Ayah \(progress.lastAyah)")
        .accessibilityHint("Double tap to expand, then tap to open Quran")
    }


    // MARK: - Progress Card

    private var progressCard: some View {
        InteractiveCard(action: {
            router.navigate(to: .progress)
        }) {
            HStack {
                VStack(alignment: .leading, spacing: SafaSpacing.xxs) {
                    Text("Your Progress")
                        .font(SafaTypography.titleSmall)

                    HStack(spacing: SafaSpacing.md) {
                        HomeStatItem(
                            value: "\(dependencies.userState.totalHasanat)",
                            label: "Hasanat"
                        )

                        HomeStatItem(
                            value: "\(dependencies.userState.dailyStreak?.currentCount ?? 0)",
                            label: "Day Streak"
                        )

                        HomeStatItem(
                            value: "Lv.\(dependencies.userState.currentLevel)",
                            label: dependencies.userState.levelTitle
                        )
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundColor(SafaColors.Fallback.tertiaryText)
            }
        }
    }

    // MARK: - Contextual Reminders

    @ViewBuilder
    private var contextualReminders: some View {
        let hour = Calendar.current.component(.hour, from: Date())

        if hour >= 4 && hour < 6 {
            ReminderCard(
                icon: "moon.stars",
                title: "Tahajjud Time",
                message: "The last third of the night is a blessed time for prayer."
            )
        }
    }

    private func reloadLoggedPrayers() async {
        do {
            let logs = try await dependencies.prayerRepository.getPrayerLogs(for: Date())
            loggedPrayers = Set(logs.map { $0.prayerType })
        } catch {
            // Keep existing state
        }
    }

    // MARK: - Load Data

    private func loadHomeData() async {
        loadError = nil

        // Load Hijri date
        hijriDate = HijriDateConverter.shared.hijriDateString(from: Date(), style: .full)
        isRamadan = HijriDateConverter.shared.isRamadan() || FeatureFlags.shared.isEnabled(.ramadanMode)

        // Load Ramadan data
        let ramadanService = dependencies.ramadanService
        ramadanService.checkRamadanStatus()
        currentRamadanDay = isRamadan ? max(ramadanService.currentRamadanDay, 1) : 0
        daysUntilRamadan = isRamadan ? nil : ramadanService.daysUntilRamadan
        isLastTenNights = currentRamadanDay >= 21 && currentRamadanDay <= 30

        // Expanded by default during Ramadan, collapsed otherwise
        isRamadanBannerExpanded = isRamadan

        // Check if banner was dismissed today
        showRamadanBanner = !UserDefaults.standard.bool(forKey: bannerDismissKey)

        // Load Eid state
        updateEidState()
        showEidBanner = !UserDefaults.standard.bool(forKey: eidBannerDismissKey)
        isEidBannerExpanded = currentEidType != nil

        // Load prayer times (use launch cache if available)
        do {
            if let cached = dependencies.cachedTodayPrayers {
                todayPrayers = cached
                dependencies.cachedTodayPrayers = nil // consumed
            } else if let location = dependencies.locationService.coordinates {
                let prefs = PreferencesManager.loadPreferencesSync()
                todayPrayers = try await dependencies.prayerRepository.getPrayers(
                    for: Date(),
                    location: location,
                    method: prefs.calculationMethod,
                    madhab: prefs.madhab
                )
            }
            if !todayPrayers.isEmpty {
                let loadNow = Date()
                nextPrayer = todayPrayers.first {
                    $0.type.isObligatory && ($0.time > loadNow || isPrayerTimeNow($0.time, at: loadNow))
                }

                // Load logged prayers for today
                let logs = try await dependencies.prayerRepository.getPrayerLogs(for: Date())
                loggedPrayers = Set(logs.map { $0.prayerType })

                // Sync to widgets via App Group
                WidgetDataService.shared.writePrayerTimes(todayPrayers)
                WidgetDataService.shared.writeLoggedPrayers(loggedPrayers, for: Date())
                WidgetDataService.shared.writeHijriDate(hijriDate)

                // Set Suhoor (Fajr) and Iftar (Maghrib) times for Ramadan banner
                suhoorTime = todayPrayers.first { $0.type == .fajr }?.time
                iftarTime = todayPrayers.first { $0.type == .maghrib }?.time
            }
        } catch {
            loadError = error
        }

        // Resolve context-aware quick actions
        resolvedActions = HomeIntentResolver.resolve(
            currentDate: Date(),
            nextPrayer: nextPrayer,
            loggedPrayers: loggedPrayers,
            streaks: dependencies.userState.streaks
        )

        // Load Quran reading progress for resume card
        quranProgress = try? await dependencies.quranRepository.getReadingProgress()

        // Load daily verse (deterministic — same verse all day)
        dailyVerse = await dependencies.quranRepository.getDailyVerse(for: Date())

        // Award dailyVerse hasanat (once per day)
        if dailyVerse != nil {
            await HasanatTracker.awardOnce(.dailyVerse, key: "dailyVerse", via: dependencies.userState)
        }
    }
}

// MARK: - Next Prayer Home Card

private struct NextPrayerHomeCard: View {
    let prayer: PrayerTime
    let action: () -> Void

    @State private var countdown = ""
    @State private var isGrace = false
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        InteractiveCard(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: SafaSpacing.xxs) {
                    Text(isGrace ? "Time to pray" : "Next Prayer")
                        .font(SafaTypography.labelMedium)
                        .foregroundColor(SafaColors.Fallback.secondaryText)

                    Text(prayer.type.displayName)
                        .font(SafaTypography.headlineMedium)
                        .foregroundColor(prayer.type.color)

                    Text(prayer.time.formatted(date: .omitted, time: .shortened))
                        .font(SafaTypography.bodySmall)
                        .foregroundColor(SafaColors.Fallback.secondaryText)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: SafaSpacing.xxs) {
                    Text(isGrace ? "Time to pray" : "Time until next prayer")
                        .font(SafaTypography.labelSmall)
                        .foregroundColor(SafaColors.Fallback.secondaryText)

                    Text(countdown)
                        .font(SafaTypography.counterSmall)
                        .foregroundColor(SafaColors.Fallback.text)
                        .monospacedDigit()
                        .contentTransition(.numericText())
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityText)
        .accessibilityHint("Double tap to view prayer times")
        .onReceive(timer) { _ in
            updateCountdown()
        }
        .onAppear {
            updateCountdown()
        }
    }

    private func updateCountdown() {
        if isPrayerTimeNow(prayer.time) || prayer.time <= Date() {
            // During grace, or grace expired but parent hasn't advanced nextPrayer yet
            countdown = String(localized: "Prayer time")
            isGrace = true
        } else {
            let (hours, minutes, seconds) = prayer.time.countdown()
            countdown = String(format: "%02d:%02d:%02d", hours, minutes, seconds)
            isGrace = false
        }
    }

    private var accessibilityText: String {
        if isPrayerTimeNow(prayer.time) || prayer.time <= Date() {
            return String(localized: "It's time for \(prayer.type.displayName)")
        }
        let (hours, minutes, _) = prayer.time.countdown()
        return formatNextPrayerAccessibilityLabel(
            prayerName: prayer.type.displayName,
            hours: hours,
            minutes: minutes
        ) + " at \(prayer.time.formatted(date: .omitted, time: .shortened))"
    }
}

// MARK: - Quick Action Card

private struct QuickActionCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: {
            HapticFeedbackService.shared.play(.tap)
            action()
        }) {
            VStack(alignment: .leading, spacing: SafaSpacing.sm) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)

                VStack(alignment: .leading, spacing: SafaSpacing.xxs) {
                    Text(title)
                        .font(SafaTypography.titleSmall)
                        .foregroundColor(SafaColors.Fallback.text)

                    Text(subtitle)
                        .font(SafaTypography.labelSmall)
                        .foregroundColor(SafaColors.Fallback.secondaryText)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(SafaSpacing.md)
            .background(Color(UIColor.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: SafaSpacing.CornerRadius.lg))
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title). \(subtitle)")
    }
}

// MARK: - Home Stat Item

private struct HomeStatItem: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: SafaSpacing.xxs) {
            Text(value)
                .font(SafaTypography.titleMedium)
                .foregroundColor(.accentColor)

            Text(label)
                .font(SafaTypography.labelSmall)
                .foregroundColor(SafaColors.Fallback.tertiaryText)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }
}

// MARK: - Reminder Card

private struct ReminderCard: View {
    let icon: String
    let title: String
    let message: String

    var body: some View {
        HStack(spacing: SafaSpacing.md) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.accentColor)
                .frame(width: 40, height: 40)
                .background(Color.accentColor.opacity(0.1))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: SafaSpacing.xxs) {
                Text(title)
                    .font(SafaTypography.titleSmall)
                    .foregroundColor(SafaColors.Fallback.text)

                Text(message)
                    .font(SafaTypography.bodySmall)
                    .foregroundColor(SafaColors.Fallback.secondaryText)
            }

            Spacer()
        }
        .padding(SafaSpacing.md)
        .background(Color(UIColor.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: SafaSpacing.CornerRadius.md))
        .accessibilityElement(children: .contain)
        .accessibilityLabel("\(title). \(message)")
    }
}

// MARK: - Next Prayer Accessibility Helper

func formatNextPrayerAccessibilityLabel(prayerName: String, hours: Int, minutes: Int) -> String {
    var parts: [String] = []
    if hours > 0 { parts.append("\(hours) hour\(hours == 1 ? "" : "s")") }
    if minutes > 0 { parts.append("\(minutes) minute\(minutes == 1 ? "" : "s")") }
    let timeText = parts.isEmpty ? "now" : "in \(parts.joined(separator: " "))"
    return "Next prayer: \(prayerName) \(timeText)"
}

// MARK: - Next Prayer Chip (Sticky Toolbar)

private struct NextPrayerChip: View {
    let prayer: PrayerTime
    let action: () -> Void

    @State private var countdown = ""
    @State private var isGrace = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        Button(action: action) {
            HStack(spacing: SafaSpacing.xs) {
                Circle()
                    .fill(prayer.type.color)
                    .frame(width: 8, height: 8)

                Text(prayer.type.displayName)
                    .font(SafaTypography.labelMedium)
                    .foregroundColor(SafaColors.Fallback.text)

                Text("·")
                    .foregroundColor(SafaColors.Fallback.tertiaryText)

                Text(countdown)
                    .font(SafaTypography.labelMedium)
                    .monospacedDigit()
                    .foregroundColor(SafaColors.Fallback.secondaryText)
                    .contentTransition(.numericText())
                    .animation(
                        reduceMotion ? nil : .default,
                        value: countdown
                    )
            }
            .padding(.horizontal, SafaSpacing.sm)
            .padding(.vertical, SafaSpacing.xxs)
            .background(Color(UIColor.secondarySystemBackground))
            .clipShape(Capsule())
        }
        .accessibilityLabel(accessibilityText)
        .onReceive(timer) { _ in
            updateCountdown()
        }
        .onAppear {
            updateCountdown()
        }
    }

    private func updateCountdown() {
        if isPrayerTimeNow(prayer.time) || prayer.time <= Date() {
            // During grace, or grace expired but parent hasn't advanced nextPrayer yet
            countdown = String(localized: "Prayer time")
            isGrace = true
        } else {
            let (hours, minutes, seconds) = prayer.time.countdown()
            countdown = String(format: "%02d:%02d:%02d", hours, minutes, seconds)
            isGrace = false
        }
    }

    private var accessibilityText: String {
        if isPrayerTimeNow(prayer.time) || prayer.time <= Date() {
            return String(localized: "It's time for \(prayer.type.displayName)")
        }
        let (hours, minutes, _) = prayer.time.countdown()
        return formatNextPrayerAccessibilityLabel(
            prayerName: prayer.type.displayName,
            hours: hours,
            minutes: minutes
        )
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        HomeView()
            .environment(Dependencies())
            .environment(AppRouter())
    }
}
