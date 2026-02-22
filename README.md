# Safa - Islamic Companion App

**Your beautiful, intelligent Islamic companion for iPhone.**

Safa (صفا — meaning purity/clarity) is a comprehensive Islamic app designed with privacy, simplicity, and intelligence at its core. No ads, no clutter, no tracking — just you and your faith.

## Why Safa?

| Problem with existing apps | Safa's approach |
|---------------------------|-----------------|
| Cluttered, outdated UI | Clean, calm design inspired by Apple's design language |
| Aggressive advertisements | No ads |
| Need 5+ apps for different features | All-in-one: Prayer, Quran, Hadith, Duas, Dhikr, and more |
| No intelligence | Contextually aware — adapts to time, location, and Islamic calendar |
| No habit formation | Gamification with Hasanat points, streaks, and daily goals |

## Features

### Core Features
- **Prayer Times** — Accurate astronomical calculations with 12 methods (ISNA, MWL, Makkah, Karachi, Egypt, Tehran, Jafari, Dubai, Kuwait, Qatar, Singapore, Turkey)
- **Qibla Compass** — Real-time compass with haptic feedback at alignment
- **Quran Reader** — Full 6,236 ayahs with Arabic (Uthmani), Sahih International translation, and FTS search
- **Hadith Collections** — 34,178 hadiths across all 6 Kutub al-Sittah (Bukhari, Muslim, Abu Dawud, Tirmidhi, Nasa'i, Ibn Majah)
- **Dua & Dhikr** — Morning/evening dhikr, sleep duas (incl. Ayatul Kursi), categorized duas
- **AI Companion** — On-device Islamic Q&A powered by Apple Foundation Models (requires iOS 26+ with Apple Intelligence)
- **Learning** — Arabic alphabet, Tajweed rules, pronunciation practice (coming soon)

### Intelligent Features
- **Contextual Reminders** — Relevant prompts based on time of day and Islamic calendar
- **Ramadan Mode** — Auto-activates with fasting tracker, Iftar countdown, Taraweeh tracking, Quran Khatm goals
- **Wind-Down Mode** — Evening routine with sleep dhikr and Fajr alarm
- **Dark Mode** — System/Light/Dark with adaptive prayer colors and 13 semantic color tokens
- **Location Intelligence** — Auto-detects calculation method, madhab, and language from your location

### iOS Integration
- **6 Widgets** — Prayer times, interactive prayer log, tasbeeh counter, streak, StandBy, and lock screen widgets
- **Live Activities** — Prayer countdown on Lock Screen and Dynamic Island
- **Spotlight Search** — Find Quran verses, hadith, and duas from iOS search
- **Siri Shortcuts** — "Hey Siri, what's the next prayer?"
- **Focus Mode** — Distraction-free prayer time
- **Apple Health** — Sync Ramadan fasting hours
- **Calendar Export** — Add Islamic events to Apple Calendar or export .ics
- **Notifications** — Prayer time alerts with optional adhan sounds (11 reciters)

### Gamification
- **Hasanat Points** — Earn rewards for prayers, Quran reading, and dhikr
- **Streaks** — Track daily consistency across prayer, Quran, and dhikr
- **Levels** — Progress from Beginner to Muhsin (10 levels)

### Privacy First
- **No account required** — Works immediately after download
- **On-device AI** — Questions never leave your phone
- **No tracking** — Zero analytics, zero telemetry, zero data collection
- **iCloud Sync** — Your data syncs through your personal Apple account (optional)
- **Data Export** — Export all your data as JSON/CSV at any time

## Requirements

- **iOS 26.0+** (SwiftUI, @Observable, NavigationPath)
- **iPhone** (iPad layout support included)

## Tech Stack

| Layer | Technology |
|-------|------------|
| UI | SwiftUI (iOS 26+) |
| State | @Observable (no Combine) |
| Architecture | MVVM + protocol-based DI |
| Local Data | SQLite (FTS5) + Core Data |
| Cloud Sync | CloudKit (optional) |
| AI | Apple Foundation Models + RAG |
| Audio | AVFoundation |
| Widgets | WidgetKit (App Group shared data) |
| Notifications | UserNotifications + adhan CAF audio |
| Localization | String Catalogs (.xcstrings), Phase 1: en/ar/id/ur/bn |

## Project Structure

```
Safa/
├── App/                    # App entry point, router, dependencies
├── Core/                   # Design system, services, utilities, notifications
├── Domain/                 # Entities, use cases, protocols
├── Data/                   # Repositories, Core Data, SQLite, ML
├── Features/               # Feature modules (Prayer, Quran, Hadith, etc.)
├── Shared/                 # Reusable UI components
├── Resources/              # Assets, bundled databases, audio
SafaWidgetExtension/        # Widget extension (5 widgets)
SafaShared/                 # Shared Swift package (widget logic)
scripts/                    # Database generation scripts
```

## Building

```bash
# Clone the repository
git clone https://github.com/mansoor2016/Safa.git
cd Safa

# Build
xcodebuild -scheme Safa -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build

# Run unit tests (1,889)
xcodebuild -scheme Safa -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -only-testing:SafaTests test
```

## Content Data

| Content | Source | Records |
|---------|--------|---------|
| Quran Arabic + Translation | [quran-json](https://github.com/AhmedBaset/hadith-json) (Tanzil.net data) | 6,236 ayahs |
| Hadith (6 collections) | [hadith-json](https://github.com/AhmedBaset/hadith-json) (Sunnah.com data) | 34,178 hadiths |
| Duas & Dhikr | Hisnul Muslim | Sample data |
| Audio (Adhan) | Bundled CAF | 11 reciters |

## Documentation

| Document | Purpose |
|----------|---------|
| [Design Document](.docs/DESIGN.md) | Product vision, UX principles, feature specs |
| [Technical Spec](.docs/TECHNICAL.md) | Architecture, patterns, performance budgets |
| [Task Breakdown](.docs/TASKS.md) | Development progress and backlog |
| [Development Guide](CLAUDE.md) | Coding conventions, templates, build workflow |
| [Testing Guide](.docs/TEST.md) | QA checklists and smoke tests |

## Contributing

## License

This project is licensed under the Apache License 2.0 — see the [LICENSE](LICENSE) file for details.

## Contact

- **GitHub**: [@mansoor2016](https://github.com/mansoor2016)

---

*Bismillah. May Safa be a means of benefit for you in this life and the next.*
