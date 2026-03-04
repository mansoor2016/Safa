# Safa - Islamic Companion App

**Your beautiful, intelligent Islamic companion for iPhone.**

Safa (meaning purity/clarity) is a comprehensive Islamic app designed with privacy, simplicity, and intelligence at its core. No ads, no clutter, no tracking — just you and your faith.

## Why Safa?

| Problem with existing apps | Safa's approach |
|---------------------------|-----------------|
| Cluttered, outdated UI | Clean, calm design inspired by Apple's design language |
| Aggressive advertisements | No ads, ever |
| Need 5+ apps for different features | All-in-one: Prayer, Quran, Hadith, Duas, Dhikr, and more |
| No intelligence | Contextually aware — adapts to time, location, and Islamic calendar |
| No habit formation | Gamification with Hasanat points, streaks, and daily goals |

## Features

### Core
- **Prayer Times** — Accurate astronomical calculations with 12 methods (ISNA, MWL, Makkah, Karachi, Egypt, Tehran, Jafari, Dubai, Kuwait, Qatar, Singapore, Turkey)
- **Qibla Compass** — Real-time compass with haptic feedback at alignment
- **Quran Reader** — Full 6,236 ayahs with Arabic (Uthmani), Sahih International translation, transliteration, and full-text search
- **Hadith Collections** — 34,178 hadiths across all 6 Kutub al-Sittah (Bukhari, Muslim, Abu Dawud, Tirmidhi, Nasa'i, Ibn Majah)
- **Dua & Dhikr** — Morning/evening dhikr, sleep duas (incl. Ayatul Kursi), categorized duas
- **AI Companion** — On-device Islamic Q&A powered by Apple Foundation Models (requires iOS 26+ with Apple Intelligence)
- **Ramadan Suite** — Fasting tracker, Iftar countdown, Taraweeh logging, Quran Khatm goals, Ramadan duas, Zakat calculator

### iOS Integration
- **Widgets** — Prayer times, interactive prayer log, tasbeeh counter, streak, and StandBy widgets
- **Live Activities** — Prayer countdown on Lock Screen and Dynamic Island
- **Spotlight Search** — Find Quran verses, hadith, and duas from iOS search
- **Siri Shortcuts** — 5 intents: prayer times, log prayer, Qibla direction, Islamic date, Quran search
- **Calendar Export** — Add Islamic events to Apple Calendar or export .ics
- **Notifications** — Prayer time alerts with custom sounds, `.timeSensitive` delivery, and Focus Mode categories

### Intelligence
- **Location Intelligence** — Auto-detects calculation method, madhab, and language from your location
- **Contextual Reminders** — Relevant prompts based on time of day and Islamic calendar
- **Ramadan Mode** — Auto-activates during Ramadan (Maghrib-aware Hijri detection)
- **Dark Mode** — System/Light/Dark with adaptive prayer colors

### Gamification
- **Hasanat Points** — Earn rewards for prayers, Quran reading, and dhikr
- **Streaks** — Track daily consistency across prayer, Quran, and dhikr
- **Levels** — Progress from Beginner to Muhsin (10 levels)

### Privacy First
- **No account required** — Works immediately after download
- **On-device AI** — Questions never leave your phone
- **No tracking** — Zero analytics, zero telemetry, zero data collection
- **Data Export** — Export all your data as JSON/CSV at any time

## Requirements

- **iOS 17.0+**
- **iPhone**

## Tech Stack

| Layer | Technology |
|-------|------------|
| UI | SwiftUI |
| State | @Observable |
| Architecture | MVVM + protocol-based DI |
| Local Data | SQLite (FTS5) + Core Data |
| AI | Apple Foundation Models + RAG |
| Audio | AVFoundation |
| Widgets | WidgetKit (App Group shared data) |
| Notifications | UserNotifications |
| Localization | String Catalogs — en, ar, ur, bn, id, ms, tr, fa, fr |

## Project Structure

```
Safa/
├── App/                    # App entry point, router, dependencies
├── Core/                   # Design system, services, utilities
├── Domain/                 # Entities, use cases, protocols
├── Data/                   # Repositories, Core Data, SQLite, ML
├── Features/               # Feature modules (Prayer, Quran, Hadith, etc.)
├── Shared/                 # Reusable UI components
├── Resources/              # Assets, bundled databases
SafaWidgetExtension/        # Widget extension
SafaShared/                 # Shared Swift package
```

## Building

```bash
git clone https://github.com/mansoor2016/Safa.git
cd Safa

# Build
xcodebuild -scheme Safa -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build

# Run tests (2,832)
xcodebuild -scheme Safa -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -only-testing:SafaTests -parallel-testing-enabled NO test
```

## Content Data

| Content | Source | Records |
|---------|--------|---------|
| Quran Arabic + Translation | [quran-json](https://github.com/AhmedBaset/hadith-json) (Tanzil.net data) | 6,236 ayahs |
| Hadith (6 collections) | [hadith-json](https://github.com/AhmedBaset/hadith-json) (Sunnah.com data) | 34,178 hadiths |
| Duas & Dhikr | Hisnul Muslim | 120 duas |

## Documentation

| Document | Purpose |
|----------|---------|
| [Design Document](.docs/DESIGN.md) | Product vision, UX principles, feature specs |
| [Technical Spec](.docs/TECHNICAL.md) | Architecture, patterns, performance budgets |
| [Task Breakdown](.docs/TASKS.md) | Development progress and backlog |
| [Development Guide](CLAUDE.md) | Coding conventions, templates, build workflow |
| [Testing Guide](.docs/TEST.md) | QA checklists and smoke tests |

## License

This project is licensed under CC BY-NC-SA 4.0 — see the [LICENSE](LICENSE) file for details.

## Contact

- **GitHub**: [@mansoor2016](https://github.com/mansoor2016)

---

*Bismillah. May Safa be a means of benefit for you in this life and the next.*
