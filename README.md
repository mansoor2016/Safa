# Safa - Islamic Companion App

**Your beautiful, intelligent Islamic companion for iPhone.**

Safa (صفا - meaning purity/clarity) is a comprehensive Islamic app designed with privacy, simplicity, and intelligence at its core. No ads, no clutter, no tracking - just you and your faith.

## Why Safa?

| Problem with existing apps | Safa's approach |
|---------------------------|-----------------|
| Cluttered, outdated UI | Clean, calm design inspired by Apple's design language |
| Aggressive advertisements | No ads, ever |
| Need 5+ apps for different features | All-in-one: Prayer, Quran, Hadith, Learning, AI |
| No intelligence | Contextually aware - adapts to time, date, and Islamic calendar |
| No habit formation | Duolingo-style gamification with Hasanat points and streaks |

## Features

### Core Features
- **Prayer Times** - Accurate calculations with multiple methods (ISNA, MWL, Makkah, etc.)
- **Qibla Compass** - Find the direction to Makkah with haptic feedback
- **Quran Reader** - Full Quran with Arabic text, translations, and audio recitation
- **Hadith Collections** - Sahih Bukhari, Muslim, and other major collections
- **Dua & Adhkar** - Morning/evening adhkar, categorized duas with audio
- **AI Companion** - On-device Islamic Q&A powered by Apple Foundation Models (iOS 18.4+)
- **Learning** - Arabic alphabet, Tajweed rules, pronunciation practice

### Intelligent Features
- **Contextual Reminders** - Relevant prompts based on time and Islamic calendar
- **Ramadan Mode** - Auto-activates with fasting tracker, Iftar countdown, Quran goals
- **Wind-Down Mode** - Evening routine with sleep adhkar and Fajr alarm

### iOS Integration
- **Widgets** - Prayer times, streaks, daily verse on your home screen
- **Interactive Widgets** - Log prayers or count tasbeeh without opening the app
- **Live Activities** - Prayer countdown on Lock Screen and Dynamic Island
- **StandBy Mode** - Prayer times on your bedside clock
- **Spotlight Search** - Find Quran verses, hadith, and duas from iOS search
- **Siri Shortcuts** - "Hey Siri, what's the next prayer?"
- **Focus Mode** - Distraction-free prayer time
- **Apple Health** - Sync Ramadan fasting hours
- **Calendar Export** - Add Islamic events to Apple Calendar or export .ics

### Gamification
- **Hasanat Points** - Earn rewards for prayers, Quran reading, and learning
- **Streaks** - Track daily consistency across multiple activities
- **Achievements** - Unlock badges for milestones
- **Levels** - Progress from Beginner to Muhsin

### Privacy First
- **No account required** - Works immediately after download
- **On-device AI** - Questions never leave your phone
- **No tracking** - We don't collect or sell your data
- **iCloud Sync** - Your data syncs through your personal Apple account

## Requirements

- **iOS 17.0+** (for widgets, Live Activities)
- **iOS 18.4+** (for AI Companion feature)
- **iPhone** (iPad optimization planned for future)

## Tech Stack

| Layer | Technology |
|-------|------------|
| UI | SwiftUI |
| Architecture | MVVM + Clean Architecture |
| Persistence | Core Data + CloudKit |
| AI | Apple Foundation Models + RAG |
| Audio | AVFoundation |
| Widgets | WidgetKit |
| Notifications | UserNotifications |

## Project Structure

```
Safa/
├── App/                    # App entry point, router, dependencies
├── Core/                   # Shared utilities, design system, services
├── Domain/                 # Entities, use cases, protocols
├── Data/                   # Repositories, Core Data, CloudKit
├── Features/               # Feature modules (Prayer, Quran, Learn, etc.)
├── Shared/                 # Reusable UI components
├── SafaWidgets/            # Widget extension
└── Resources/              # Assets, bundled data, fonts
```

## Building

```bash
# Clone the repository
git clone https://github.com/mansoor2016/Safa.git
cd Safa

# Open in Xcode
open Safa.xcodeproj

# Build
xcodebuild -scheme Safa -destination 'platform=iOS Simulator,name=iPhone 17' build
```

## Documentation

- [Design Document](.docs/DESIGN.md) - Product vision, features, and UX
- [Technical Requirements](.docs/TECHNICAL.md) - Architecture and implementation details
- [Task Breakdown](.docs/TASKS.md) - Development progress and task tracking
- [Development Guide](CLAUDE.md) - Coding conventions and patterns

## Content Sources

| Content | Source | License |
|---------|--------|---------|
| Quran Arabic | [Tanzil.net](https://tanzil.net) | Free |
| Translation | Sahih International | Free |
| Hadith | [Sunnah.com](https://sunnah.com) | Free (non-commercial) |
| Audio | [Everyayah.com](https://everyayah.com) | Free for Islamic apps |

## Contributing

Contributions are welcome! Please read the [Development Guide](CLAUDE.md) for coding conventions.

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the Apache License 2.0 - see the [LICENSE](LICENSE) file for details.

## Contact

- **GitHub**: [@mansoor2016](https://github.com/mansoor2016)
- **Email**: mansoor.aman11@gmail.com

---

*Bismillah. May Safa be a means of benefit for you in this life and the next.*
