// MARK: - HomeView.swift
// PURPOSE: Main home screen with prayer countdown and quick actions
// DEPENDENCIES: SwiftUI, Combine

import SwiftUI
import Combine
import SafaShared

struct HomeView: View {
    @Environment(Dependencies.self) private var dependencies
    @Environment(AppRouter.self) private var router
    @Environment(\.locale) private var locale

    // MARK: - Support Card Bindings (owned by MainTabView)
    @Binding var showSupportCardThisSession: Bool
    @Binding var supportCardDismissed: Bool
    @Binding var debugForceSupport: Bool

    @State private var nextPrayer: PrayerTime?
    @State private var todayPrayers: [PrayerTime] = []
    @State private var loggedPrayers: Set<PrayerType> = []
    @State private var hijriDate = ""
    @State private var dailyVerse: Ayah?
    @State private var quranProgress: QuranProgress?
    @State private var isRamadan = false
    @State private var showRamadanBanner = true
    @State private var currentRamadanDay: Int = 0
    @State private var daysUntilRamadan: Int?
    @State private var isLastTenNights = false
    @State private var showShareBanner = !ShareBanner.isDismissed
    @State private var loadError: Error?
    @State private var resolvedActions: [HomeAction] = []
    @State private var hideResumeCard = false
    @State private var isResumeCardExpanded = false
    @State private var isDailyVerseExpanded = true

    // Ramadan goals (fasting tracker + Quran khatm)
    @State private var fastingDays: Set<Int> = []
    @State private var currentRamadanDayForFasting = 1
    @State private var juzCompleted = 0
    @State private var isFastingTrackerExpanded = false

    // Timer to advance nextPrayer when grace window expires + detect Maghrib crossing
    let graceExpiryTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    /// Tracks which civil date's Maghrib crossing we've already handled (resets on new day).
    /// Uses "yyyy-MM-dd" format to avoid month-boundary collisions.
    @State private var maghribCrossingHandledDate: String?

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
        ScrollableScreen {
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

                // Suhoor/Iftar platter (Ramadan only, once prayers are loaded)
                if isRamadan, !todayPrayers.isEmpty {
                    SuhoorIftarPlatter(
                        suhoorTime: todayPrayers.first { $0.type == .fajr }?.time,
                        iftarTime: todayPrayers.first { $0.type == .maghrib }?.time
                    )
                }

                // Ramadan banner (collapsible, reappears next day)
                ramadanBannerSection

                // Ramadan goals — immediately below Ramadan banner
                if isRamadan {
                    fastingTrackerCard
                    quranGoalCard
                }

                // Eid banner (during Eid or 7 days before)
                eidBannerSection

                // Resume where you left off (dismissable, reappears next day; hidden during Ramadan)
                if !isRamadan,
                   let progress = quranProgress,
                   case .visible = HomeBannerResolver.resolveResumeCard(
                       quran: .init(lastSurah: progress.lastSurah, lastAyah: progress.lastAyah),
                       dismiss: dismissState
                   ) {
                    resumeQuranCard(progress)
                }

                // Daily verse
                if let verse = dailyVerse {
                    dailyVerseCard(verse)
                }

                // Quick actions
                quickActions

                // Progress summary
                progressCard

                // Contextual reminders
                contextualReminders

                // Combined community card (share + support + subscriber thank-you)
                communitySupportSection
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
            // Detect Maghrib crossing — recompute Hijri/Ramadan/Eid state once per civil day.
            // Same-day guard: only act if Maghrib belongs to today (prevents stale prayer data from triggering).
            let todayKey = now.formatted(.iso8601.year().month().day())
            if maghribCrossingHandledDate != todayKey,
               let maghrib = todayPrayers.first(where: { $0.type == .maghrib })?.time,
               Calendar.current.isDate(now, inSameDayAs: maghrib),
               now >= maghrib {
                maghribCrossingHandledDate = todayKey
                hijriDate = HijriDateConverter.shared.hijriDateString(from: now, style: .dayMonth, maghribTime: maghrib)
                isRamadan = HijriDateConverter.shared.isRamadan(maghribTime: maghrib) || FeatureFlags.shared.isEnabled(.ramadanMode)
                let ramadanService = dependencies.ramadanService
                ramadanService.checkRamadanStatus(maghribTime: maghrib)
                currentRamadanDay = isRamadan ? max(ramadanService.currentRamadanDay, 1) : 0
                daysUntilRamadan = isRamadan ? nil : ramadanService.daysUntilRamadan
                isLastTenNights = currentRamadanDay >= 21 && currentRamadanDay <= 30
                updateEidState(maghribTime: maghrib)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.significantTimeChangeNotification)) { _ in
            // Midnight or timezone change — reload prayer times so todayPrayers is fresh
            Task { await loadHomeData() }
        }
        .onAppear {
            Task { await reloadLoggedPrayers() }
            // Recalculate next prayer (may have changed since last appear)
            // Include prayers in grace window (0-15 min after prayer time)
            let now = Date()
            nextPrayer = todayPrayers.first {
                $0.type.isObligatory && ($0.time > now || isPrayerTimeNow($0.time, at: now))
            }
            // Re-check Ramadan state (respects Force Ramadan Mode toggle, Maghrib-aware)
            let appearMaghrib = todayPrayers.first(where: { $0.type == .maghrib })?.time ?? dependencies.todayMaghribTime
            isRamadan = HijriDateConverter.shared.isRamadan(maghribTime: appearMaghrib) || FeatureFlags.shared.isEnabled(.ramadanMode)
            if isRamadan && !HijriDateConverter.shared.isRamadan(maghribTime: appearMaghrib) {
                // Forced mode — set a sensible day
                currentRamadanDay = max(currentRamadanDay, 1)
                daysUntilRamadan = nil
            }
            // Reload Ramadan goals AFTER isRamadan is recalculated
            if isRamadan { loadRamadanGoals() }
            // Re-check banner dismiss state (synced with Settings toggle)
            showRamadanBanner = !UserDefaults.standard.bool(forKey: bannerDismissKey)
            // Re-check Eid state (respects Force Eid Mode toggles, Maghrib-aware)
            updateEidState(maghribTime: appearMaghrib)
            showEidBanner = !UserDefaults.standard.bool(forKey: eidBannerDismissKey)
            // Re-resolve quick actions (time/prayer may have changed, Maghrib-aware)
            refreshResolvedActions()
        }
        .onChange(of: locale.identifier) { _, _ in
            refreshResolvedActions()
        }
    }

    // MARK: - Ramadan Banner Section

    @ViewBuilder
    private var ramadanBannerSection: some View {
        let visibility = HomeBannerResolver.resolveRamadanBanner(
            calendar: calendarState,
            dismiss: dismissState
        )

        if visibility != .hidden {
            // During Ramadan: only show Last Ten Nights banner (days 21-30).
            // Days 1-20: no banner — Prayer tab has the iftar platter.
            if case .duringRamadan(_, isLastTenNights: true) = visibility {
                LastTenNightsBanner(
                    currentNight: currentRamadanDay,
                    onDismiss: dismissBanner
                )
                .onTapGesture { router.selectedTab = .prayer }
            } else if case .preRamadan = visibility {
                PreRamadanBanner(
                    daysUntil: daysUntilRamadan ?? 0,
                    onDismiss: dismissBanner
                )
                .onTapGesture { router.navigate(to: .ramadan) }
            }
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

            Image(systemName: isEidBannerExpanded ? "chevron.down" : "chevron.forward")
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
            return String(localized: "\(eidType.localizedDisplayName) - Day \(eidDayNumber)")
        } else if let eidType = nextEidType, let days = daysUntilNextEid, days <= 7, days > 0 {
            return String(localized: "\(days) day(s) until \(eidType.localizedDisplayName)")
        }
        return String(localized: "Eid")
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

    private func updateEidState(maghribTime: Date? = nil) {
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

        currentEidType = HijriDateConverter.shared.currentEidType(maghribTime: maghribTime)
        eidDayNumber = HijriDateConverter.shared.eidDayNumber(maghribTime: maghribTime) ?? 0

        if currentEidType == nil {
            if let nearest = HijriDateConverter.shared.nearestUpcomingEid(maghribTime: maghribTime) {
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
            router.selectedTab = AppRouter.Tab(rawValue: tabId) ?? .home
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

                Image(systemName: isDailyVerseExpanded ? "chevron.down" : "chevron.forward")
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

                Image(systemName: isResumeCardExpanded ? "chevron.down" : "chevron.forward")
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
                    router.selectedTab = .quran
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

                        Image(systemName: "arrow.forward.circle.fill")
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
                            label: String(localized: "Hasanat")
                        )

                        HomeStatItem(
                            value: "\(dependencies.userState.dailyStreak?.currentCount ?? 0)",
                            label: String(localized: "Day Streak")
                        )

                        HomeStatItem(
                            value: String(localized: "Lv.\(dependencies.userState.currentLevel)"),
                            label: dependencies.userState.levelTitle
                        )
                    }
                }

                Spacer()

                Image(systemName: "chevron.forward")
                    .foregroundColor(SafaColors.Fallback.tertiaryText)
            }
        }
    }

    // MARK: - Fasting Tracker Card

    private var fastingTrackerCard: some View {
        VStack(spacing: 0) {
            // Header row (always visible)
            HStack(spacing: SafaSpacing.sm) {
                Image(systemName: "fork.knife")
                    .font(.body)
                    .foregroundColor(.orange)
                Text("Fasting Tracker")
                    .font(SafaTypography.titleSmall)
                    .foregroundColor(SafaColors.Fallback.text)
                Spacer()
                Text("\(fastingDays.count)/30")
                    .font(SafaTypography.labelSmall)
                    .foregroundColor(SafaColors.Fallback.secondaryText)
                Image(systemName: isFastingTrackerExpanded ? "chevron.down" : "chevron.forward")
                    .font(.caption)
                    .foregroundColor(SafaColors.Fallback.tertiaryText)
            }
            .padding(.horizontal, SafaSpacing.md)
            .padding(.vertical, SafaSpacing.sm)
            .background(Color(UIColor.secondarySystemBackground))
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isFastingTrackerExpanded.toggle()
                }
            }
            .accessibilityAddTraits(.isButton)
            .accessibilityLabel("Fasting Tracker, \(fastingDays.count) of 30 days completed")
            .accessibilityHint(isFastingTrackerExpanded ? "Double tap to collapse" : "Double tap to expand")

            // Expanded: 30-day grid
            if isFastingTrackerExpanded {
                VStack(spacing: SafaSpacing.md) {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: SafaSpacing.xs) {
                        ForEach(1...30, id: \.self) { day in
                            FastingDayCell(
                                day: day,
                                isFasted: fastingDays.contains(day),
                                isToday: day == currentRamadanDayForFasting,
                                isPast: day < currentRamadanDayForFasting
                            ) {
                                toggleFastingDay(day)
                            }
                        }
                    }
                    .dynamicTypeSize(...DynamicTypeSize.accessibility3)
                }
                .padding(.horizontal, SafaSpacing.md)
                .padding(.vertical, SafaSpacing.sm)
                .background(Color(UIColor.secondarySystemBackground))
                .transition(.opacity.combined(with: .move(edge: .top)))
            }

            // "Mark today" button (always visible when applicable)
            if currentRamadanDayForFasting <= 30 {
                Button { toggleFastingDay(currentRamadanDayForFasting) } label: {
                    HStack {
                        Image(systemName: fastingDays.contains(currentRamadanDayForFasting)
                              ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(fastingDays.contains(currentRamadanDayForFasting)
                                             ? .green : SafaColors.Fallback.tertiaryText)
                        Text(fastingDays.contains(currentRamadanDayForFasting)
                             ? "Fasted today" : "Mark today as fasted")
                            .font(SafaTypography.bodyMedium)
                            .foregroundColor(SafaColors.Fallback.text)
                        Spacer()
                    }
                    .padding(.horizontal, SafaSpacing.md)
                    .padding(.vertical, SafaSpacing.sm)
                    .background(Color(UIColor.secondarySystemBackground))
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: SafaSpacing.CornerRadius.lg))
    }

    private func toggleFastingDay(_ day: Int) {
        if fastingDays.contains(day) {
            fastingDays.remove(day)
        } else {
            fastingDays.insert(day)
            Task {
                await HasanatTracker.awardOnce(.fastingDay, key: "fastingDay_\(day)", via: dependencies.userState)
            }
        }
        let year = String(Calendar.current.component(.year, from: Date()))
        UserDefaults.standard.set(Array(fastingDays), forKey: "ramadan_fasting_days_\(year)")
    }

    // MARK: - Quran Goal Card

    private var dailyGoalsDateKey: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return "dailyGoals_\(formatter.string(from: Date()))"
    }

    private var todayJuzDone: Bool {
        let saved = UserDefaults.standard.stringArray(forKey: dailyGoalsDateKey) ?? []
        return saved.contains("juz")
    }

    private func toggleTodayJuz(markDone: Bool) {
        var goals = Set(UserDefaults.standard.stringArray(forKey: dailyGoalsDateKey) ?? [])
        if markDone && !goals.contains("juz") {
            goals.insert("juz")
        } else if !markDone && goals.contains("juz") {
            goals.remove("juz")
        } else {
            return
        }
        UserDefaults.standard.set(Array(goals), forKey: dailyGoalsDateKey)
        loadRamadanGoals()
    }

    private var quranGoalCard: some View {
        ContentCard {
            VStack(alignment: .leading, spacing: SafaSpacing.md) {
                HStack {
                    VStack(alignment: .leading, spacing: SafaSpacing.xxs) {
                        Text("Quran Khatm Goal")
                            .font(SafaTypography.titleSmall)
                        Text("Complete the Quran this Ramadan")
                            .font(SafaTypography.labelSmall)
                            .foregroundColor(SafaColors.Fallback.secondaryText)
                    }
                    Spacer()
                    VStack(alignment: .trailing) {
                        Text("\(juzCompleted)/30")
                            .font(SafaTypography.titleMedium)
                            .foregroundColor(.accentColor)
                            .contentTransition(.numericText())
                        Text("Juz")
                            .font(SafaTypography.labelSmall)
                            .foregroundColor(SafaColors.Fallback.secondaryText)
                    }
                }

                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.gray.opacity(0.2)).frame(height: 8)
                        Capsule().fill(Color.green)
                            .frame(width: geometry.size.width * CGFloat(juzCompleted) / 30, height: 8)
                            .animation(.easeInOut, value: juzCompleted)
                    }
                }
                .frame(height: 8)

                Text(todayJuzDone
                     ? "Today's juz complete — long press to undo"
                     : "Tap to mark today's juz as read")
                    .font(SafaTypography.labelSmall)
                    .foregroundColor(todayJuzDone ? .green : SafaColors.Fallback.tertiaryText)
            }
        }
        .contentShape(Rectangle())
        .highPriorityGesture(
            LongPressGesture(minimumDuration: 0.5)
                .onEnded { _ in toggleTodayJuz(markDone: false) }
        )
        .onTapGesture { toggleTodayJuz(markDone: true) }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Quran Khatm Goal, \(juzCompleted) of 30 juz completed")
        .accessibilityAction(named: "Mark today's juz as read") { toggleTodayJuz(markDone: true) }
        .accessibilityAction(named: "Undo today's juz") { toggleTodayJuz(markDone: false) }
    }

    private func loadRamadanGoals() {
        let hijriConverter = HijriDateConverter.shared
        let maghrib = todayPrayers.first(where: { $0.type == .maghrib })?.time ?? dependencies.todayMaghribTime
        let components = hijriConverter.islamicDate(from: Date(), adjustedFor: maghrib)
        let month = components.month ?? 0
        let day = components.day ?? 0
        if month == 9 { currentRamadanDayForFasting = day }

        // Load persisted fasting days
        let year = String(Calendar.current.component(.year, from: Date()))
        let savedFasting = UserDefaults.standard.array(forKey: "ramadan_fasting_days_\(year)") as? [Int] ?? []
        fastingDays = Set(savedFasting)

        // Count juz completed from daily goals
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let calendar = Calendar.current
        var count = 0
        for dayOffset in 0..<30 {
            if let date = calendar.date(byAdding: .day, value: -dayOffset, to: Date()) {
                let key = "dailyGoals_\(formatter.string(from: date))"
                let goals = UserDefaults.standard.stringArray(forKey: key) ?? []
                if goals.contains("juz") { count += 1 }
            }
        }
        withAnimation { juzCompleted = count }
    }

    // MARK: - Community Support Section

    @ViewBuilder
    private var communitySupportSection: some View {
        let shareEligible = HomeBannerResolver.resolveShareBanner(dismiss: dismissState) == .visible
        let supportEligible = HomeBannerResolver.resolveSupportCard(support: .init(
            isEligibleThisSession: showSupportCardThisSession,
            isDismissedThisSession: supportCardDismissed,
            hasActiveSubscription: dependencies.subscriptionService.hasActiveSubscription,
            isDebugForced: debugForceSupport
        )) == .visible
        let isSubscriber = dependencies.subscriptionService.hasActiveSubscription

        if shareEligible || supportEligible || isSubscriber {
            CommunitySupportCard(
                showShare: shareEligible,
                showSupport: supportEligible,
                isSubscriber: isSubscriber,
                onShareComplete: { withAnimation { showShareBanner = false } },
                onSupportDismiss: {
                    withAnimation {
                        supportCardDismissed = true
                        debugForceSupport = false
                    }
                }
            )
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

        // Load Hijri date (use persisted Maghrib for instant render before prayer times load)
        let persistedMaghrib = dependencies.todayMaghribTime
        hijriDate = HijriDateConverter.shared.hijriDateString(from: Date(), style: .dayMonth, maghribTime: persistedMaghrib)
        isRamadan = HijriDateConverter.shared.isRamadan(maghribTime: persistedMaghrib) || FeatureFlags.shared.isEnabled(.ramadanMode)

        // Load Ramadan data
        let ramadanService = dependencies.ramadanService
        ramadanService.checkRamadanStatus(maghribTime: persistedMaghrib)
        currentRamadanDay = isRamadan ? max(ramadanService.currentRamadanDay, 1) : 0
        daysUntilRamadan = isRamadan ? nil : ramadanService.daysUntilRamadan
        isLastTenNights = currentRamadanDay >= 21 && currentRamadanDay <= 30

        // Check if banner was dismissed today
        showRamadanBanner = !UserDefaults.standard.bool(forKey: bannerDismissKey)

        // Load Eid state
        updateEidState(maghribTime: persistedMaghrib)
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

                // Sync to widgets via App Group (also persists Maghrib and writes Hijri date)
                WidgetDataService.shared.writePrayerTimes(todayPrayers)
                WidgetDataService.shared.writeLoggedPrayers(loggedPrayers, for: Date())

                // Recompute all Maghrib-dependent state now that we have today's prayer times
                let maghrib = todayPrayers.first(where: { $0.type == .maghrib })?.time
                hijriDate = HijriDateConverter.shared.hijriDateString(from: Date(), style: .dayMonth, maghribTime: maghrib)
                isRamadan = HijriDateConverter.shared.isRamadan(maghribTime: maghrib) || FeatureFlags.shared.isEnabled(.ramadanMode)
                ramadanService.checkRamadanStatus(maghribTime: maghrib)
                currentRamadanDay = isRamadan ? max(ramadanService.currentRamadanDay, 1) : 0
                daysUntilRamadan = isRamadan ? nil : ramadanService.daysUntilRamadan
                isLastTenNights = currentRamadanDay >= 21 && currentRamadanDay <= 30
                updateEidState(maghribTime: maghrib)
            }
        } catch {
            loadError = error
        }

        // Resolve context-aware quick actions
        refreshResolvedActions()

        // Load Quran reading progress for resume card
        quranProgress = try? await dependencies.quranRepository.getReadingProgress()

        // Load daily verse (deterministic — same verse all day)
        dailyVerse = await dependencies.quranRepository.getDailyVerse(for: Date())

        // Award dailyVerse hasanat (once per day)
        if dailyVerse != nil {
            await HasanatTracker.awardOnce(.dailyVerse, key: "dailyVerse", via: dependencies.userState)
        }

        // Load Ramadan goals (fasting tracker + Quran khatm)
        if isRamadan {
            loadRamadanGoals()
        }
    }

    private func refreshResolvedActions() {
        resolvedActions = HomeIntentResolver.resolve(
            currentDate: Date(),
            nextPrayer: nextPrayer,
            loggedPrayers: loggedPrayers,
            streaks: dependencies.userState.streaks,
            isAIAvailable: dependencies.llmService.availability.isAvailable,
            maghribTime: todayPrayers.first(where: { $0.type == .maghrib })?.time
        )
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

// MARK: - Preview

#Preview {
    NavigationStack {
        HomeView(
            showSupportCardThisSession: .constant(false),
            supportCardDismissed: .constant(false),
            debugForceSupport: .constant(false)
        )
            .environment(Dependencies())
            .environment(AppRouter())
    }
}
