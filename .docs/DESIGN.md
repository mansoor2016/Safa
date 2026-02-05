# Safa - Islamic Companion App

## Design Document v0.2

---

## 1. Vision Statement

Safa is an all-in-one Islamic companion app for iPhone that prioritizes clean, intuitive design over the cluttered, ad-heavy experiences of existing apps. It serves as the single destination for Muslims to practice, learn, and deepen their faith.

**Key Differentiator**: Safa is an *intelligent* app that understands the Islamic calendar, time of day, and user context to proactively surface relevant features, reminders, and content without requiring manual configuration.

### 1.1 Why Safa? (Value Proposition)

**The Problem with Existing Apps:**
| Issue | Examples |
|-------|----------|
| Cluttered, outdated UI | Muslim Pro, Athan, Islamic Finder |
| Aggressive advertisements | Banner ads, video ads, pop-ups |
| Fragmented experience | Need 5+ apps for different features |
| No intelligence | Passive tools, no contextual awareness |
| No habit formation | No streaks, progress, or motivation |

**Why Users Will Choose Safa:**

1. **Beautiful, Calm Design**
   - Clean white aesthetic that feels peaceful, not cluttered
   - No ads, ever - the experience is sacred
   - Designed like a premium Apple app, not a 2012 Android port

2. **One App for Everything**
   - Prayer times, Quran, Hadith, Duas, Learning, AI - all in one place
   - No need to juggle multiple apps
   - Consistent experience across all features

3. **Actually Intelligent**
   - Knows when Ramadan is and adapts automatically
   - Reminds you about prayer when you open the app
   - Suggests relevant content based on time and context
   - Learns your habits and encourages consistency

4. **Makes You Better**
   - Duolingo-style gamification actually works
   - Streaks and Hasanat make worship feel rewarding
   - Learning tracks improve your Arabic and Tajweed
   - Progress visualization shows your spiritual journey

5. **Modern iOS Experience**
   - Widgets on your home screen
   - Dynamic Island prayer countdown
   - Focus mode integration
   - Feels native, not like a web wrapper

6. **Family Connection**
   - See your family's streaks and encourage each other
   - Share beautiful verses effortlessly
   - Grow together in faith

**The Pitch (One Sentence):**
> "Safa is the beautifully designed, intelligent Islamic companion that helps you pray, learn, and grow - without ads, without clutter, just you and your faith."

---

## 2. Design Philosophy

### 2.1 Visual Identity
- **Primary Palette**: Clean white backgrounds with subtle warm grays
- **Accent Colors**: User-configurable theme system
  - Default: Elegant gold
  - Alternatives: Teal, Deep blue, Emerald green, Rose
- **Typography**: Modern, highly legible fonts; beautiful Arabic calligraphy for Quranic text
- **Spacing**: Generous whitespace, breathing room between elements
- **Iconography**: Minimal line icons, consistent stroke weight

### 2.2 Theme Configuration
```
Settings → Appearance → Theme Color
┌─────────────────────────────────┐
│  Choose Accent Color            │
│                                 │
│  ◉ Gold (Default)               │
│  ○ Teal                         │
│  ○ Deep Blue                    │
│  ○ Emerald                      │
│  ○ Rose                         │
│                                 │
│  Preview:                       │
│  ┌─────────────────────────┐   │
│  │  [Button] [Link] [Icon] │   │
│  └─────────────────────────┘   │
└─────────────────────────────────┘
```

### 2.3 UX Principles
- Maximum 2-3 taps to reach any feature
- No advertisements disrupting the experience
- Intelligent contextual features (modes activate automatically)
- Gentle, non-intrusive notifications
- Seamless transitions and micro-animations
- Proactive in-app guidance and reminders

---

## 3. Intelligent Modes & Contextual Awareness

This is the heart of what makes Safa different. The app is aware of time, date, location, and Islamic calendar to provide a proactive, intelligent experience.

### 3.1 Contextual Engine

The app maintains awareness of:
- **Current time** (for prayer timing, morning/evening adhkar)
- **Hijri date** (for Islamic events and seasons)
- **User location** (for accurate prayer times, smart defaults)
- **User behavior** (prayer logging, Quran progress, streaks)

### 3.1.1 Location-Based Intelligence

When the user grants location permission, the app automatically infers optimal settings:

| User Location | Calculation Method | Madhab | Language |
|---------------|-------------------|--------|----------|
| US/Canada | ISNA | Hanafi | English |
| Saudi/Gulf | Makkah | Hanafi | Arabic |
| Pakistan/India/Bangladesh | Karachi | Hanafi | English/Urdu |
| Southeast Asia (ID, MY) | MWL | Shafi'i | Indonesian |
| Turkey/Central Asia | MWL | Hanafi | Turkish |
| North/West Africa | MWL | Shafi'i | Arabic/French |
| Europe | MWL | Hanafi | English |

**Onboarding Flow:**
- After location permission granted, show detected city/country
- Display recommended settings with "Use Recommended" toggle
- User can override any recommendation
- High latitude warning for polar regions (>48°)

### 3.2 In-App Reminders (On Open)

When the user opens the app, Safa displays contextual reminders as a dismissible card at the top of the home screen:

| Context | Reminder |
|---------|----------|
| 30-10 min before prayer | "Dhuhr begins in 25 minutes. Time to prepare for prayer." |
| Prayer time has entered | "It's time for Asr prayer." with quick link to Qibla |
| Morning (Fajr to Dhuhr) | "Have you completed your morning adhkar?" |
| Evening (Maghrib to Isha) | "Time for evening adhkar" |
| Friday before Dhuhr | "Jumu'ah Mubarak! Don't forget Surah Al-Kahf" |
| User hasn't opened Quran in 3+ days | "Continue your Quran journey? You left off at Surah X" |
| Approaching Islamic event | "Ashura is in 3 days" |

### 3.3 Seasonal Modes

The app automatically adapts its interface and features based on the Islamic calendar:

#### Ramadan Mode (Auto-activates 1st Ramadan)
- Home screen transforms to show Iftar/Suhoor countdown
- Fasting tracker prominently displayed
- Quran khatm progress tracker
- Taraweeh prayer tracking
- Special Ramadan duas surfaced
- Laylatul Qadr alerts (last 10 nights, odd nights highlighted)
- Zakat calculator accessible from home
- Suhoor alarm feature enabled

#### Dhul Hijjah Mode (First 10 days)
- Emphasis on extra worship during blessed days
- Day of Arafah reminder and special duas
- Eid al-Adha preparation
- Qurbani/Udhiyah reminders
- Takbeer of Tashreeq after prayers

#### Muharram Mode
- Ashura significance and fasting reminder
- Historical context in daily content
- Special duas for new Islamic year

#### General Sacred Times
- White Nights reminder (13th, 14th, 15th of each month) - fasting sunnah
- Monday/Thursday fasting reminders (optional, configurable)

### 3.4 Time-of-Day Awareness

| Time Period | Behavior |
|-------------|----------|
| Pre-Fajr | Tahajjud reminder if user enabled |
| Fajr to Sunrise | Morning adhkar prominent |
| Duha time | Optional Duha prayer reminder |
| Pre-Dhuhr | Jumu'ah prep on Fridays |
| Maghrib to Isha | Evening adhkar prominent |
| After Isha | Wind-down, sleep duas accessible |

### 3.5 Smart Notifications (Push)

In addition to in-app reminders, push notifications for:
- Prayer times (configurable: at time, 5/10/15/30 min before)
- Suhoor alarm (Ramadan)
- Iftar time (Ramadan)
- Daily verse/hadith (optional)
- Streak maintenance ("Keep your 7-day Quran streak!")
- Islamic events (day before and day of)

---

## 4. Core Features

### 4.1 Prayer Times & Salah Tracker
- Accurate prayer times based on location and calculation method
- Multiple calculation methods (ISNA, MWL, Egypt, Makkah, Karachi, etc.)
- Beautiful adhan notifications (customizable sound)
- Prayer tracking/logging with streaks
- Qibla compass with clean visual indicator
- Mosque finder with directions (MapKit integration)
- Makeup prayer (Qada) tracker

### 4.2 Quran
- Full Quran with Arabic text (multiple scripts: Uthmani, IndoPak)
- English translation (initial release)
- Audio recitations from renowned Qaris (Mishary, Sudais, Husary, etc.)
- Bookmarking and progress tracking
- Search by surah, ayah, or keyword
- Tafsir (commentary) integration - Ibn Kathir English
- Word-by-word translation view
- Repeat ayah for memorization
- Night mode for comfortable reading

### 4.3 AI Companion (Chat)
- **Local embedded lightweight LLM** (runs on-device)
- Fine-tuned on curated Islamic knowledge base
- Extensive system prompt for guidance and tone
- Answer questions about fiqh, history, practice
- Respectful of different schools of thought (madhabs)
- Clear disclaimers for complex rulings (consult a scholar)
- Conversational, warm tone
- Cites Quran and Hadith references
- No internet required for responses

### 4.4 Ramadan Mode
- Automatic activation during Ramadan (with manual override)
- Suhoor and Iftar time notifications
- Fasting tracker (days completed, days remaining)
- Ramadan-specific duas and adhkar
- Taraweeh prayer tracking (8 or 20 rakat options)
- Quran khatm (completion) progress tracker with daily goals
- Charity/Zakat calculator (Nisab thresholds, categories)
- Sadaqah tracker
- I'tikaf mode for last 10 nights
- Eid preparation checklist

### 4.5 Dhikr & Duas
- Tasbeeh counter (digital beads with haptic feedback)
- Multiple counter modes (33, 99, 100, custom)
- Morning adhkar (Adhkar al-Sabah)
- Evening adhkar (Adhkar al-Masa)
- Curated dua collections by category:
  - Daily (eating, sleeping, traveling, etc.)
  - Salah-related
  - Protection and healing
  - Forgiveness and repentance
  - Gratitude
  - Anxiety and hardship
- Custom dhikr goals and streaks
- Audio pronunciations for all duas
- Favorites system

### 4.6 Hadith Collections
- Sahih Bukhari
- Sahih Muslim
- Sunan Abu Dawood
- Jami at-Tirmidhi
- Sunan an-Nasa'i
- Sunan Ibn Majah
- Riyad as-Salihin (topical compilation)
- Search functionality
- Daily hadith feature (configurable notification)
- Bookmarking and sharing
- Chain of narration (isnad) view

### 4.7 Islamic Calendar
- Hijri calendar with Gregorian mapping
- Important dates highlighted with descriptions
- Event reminders (configurable)
- Key dates:
  - Ramadan start/end
  - Eid al-Fitr & Eid al-Adha
  - Laylatul Qadr (estimated)
  - Day of Arafah
  - Ashura
  - Mawlid an-Nabi (optional, configurable)
  - Isra and Mi'raj
  - Shab-e-Barat (optional, configurable)
- Sync with device calendar (optional)

### 4.8 Sleep & Wind-Down Mode

A dedicated mode for the end of the day to help users wind down spiritually.

**Activation**: Auto-suggests after Isha prayer, or manually enabled

**Features:**
- Bedtime duas with audio
- Sleep adhkar checklist
- Calming Quran recitation (select surahs: Al-Mulk, As-Sajdah, Ayatul Kursi)
- Ambient background sounds (optional: rain, nature)
- Screen dims to warm, low-light mode
- Morning Fajr alarm setup prompt
- Gratitude/reflection journal prompt (optional)

**Wind-Down Flow:**
```
┌─────────────────────────────────┐
│        Wind Down                │
├─────────────────────────────────┤
│                                 │
│   Prepare for rest...           │
│                                 │
│   ┌─────────────────────────┐  │
│   │ ☐ Ayatul Kursi          │  │
│   │ ☐ Last 3 Surahs         │  │
│   │ ☐ Sleep dua             │  │
│   └─────────────────────────┘  │
│                                 │
│   [Listen to Al-Mulk]          │
│                                 │
│   ┌─────────────────────────┐  │
│   │ Set Fajr alarm: 5:30 AM │  │
│   └─────────────────────────┘  │
│                                 │
├─────────────────────────────────┤
│           [Complete]            │
└─────────────────────────────────┘
```

### 4.9 Family Features & Sharing

Connect with family members to encourage each other in worship and learning.

#### Family Circle
- Invite family members via link/QR code
- See family members' streaks (opt-in visibility)
- Gentle encouragement: "Your father completed Fajr!"
- NO leaderboards or competition - just supportive visibility
- Each member controls what they share

#### Sharing Features
- Share daily verse/hadith to Messages, WhatsApp, etc.
- Share achievements when unlocked
- Share Quran reading progress
- Invite friends to join Safa (earns Hasanat)
- Beautiful, branded share cards

#### Family Dashboard
```
┌─────────────────────────────────┐
│        Family Circle            │
├─────────────────────────────────┤
│                                 │
│  👤 Ahmed (You)                 │
│     🔥 23 day streak            │
│                                 │
│  👤 Fatima                      │
│     🔥 45 day streak            │
│     ✓ Completed Fajr today      │
│                                 │
│  👤 Yusuf                       │
│     🔥 12 day streak            │
│     📖 Reading Surah Al-Baqarah │
│                                 │
│  [Invite Family Member]         │
│                                 │
└─────────────────────────────────┘
```

#### Privacy Controls
- Choose what to share: Streaks / Prayer / Quran progress / Nothing
- Mute notifications from family
- Leave circle anytime

---

## 5. iOS Platform Integration

Deep integration with iOS to provide a native, seamless experience.

### 5.1 Widgets

Widgets allow users to see key information without opening the app.

#### Small Widget - Prayer Time
```
┌───────────────┐
│     ASR       │
│   3:45 PM     │
│   in 2h 34m   │
└───────────────┘
```

#### Small Widget - Streak
```
┌───────────────┐
│  🔥 23 days   │
│    streak     │
│   Keep going! │
└───────────────┘
```

#### Medium Widget - Prayer Times
```
┌─────────────────────────────────┐
│  Safa · Today's Prayers         │
│                                 │
│  Fajr    Dhuhr   Asr   Mgrb  Isha
│  5:42✓  12:15✓  3:45  6:23  7:45│
│                                 │
│  Next: Asr in 2h 34m            │
└─────────────────────────────────┘
```

#### Medium Widget - Daily Verse
```
┌─────────────────────────────────┐
│  Today's Verse                  │
│                                 │
│  "Indeed, with hardship         │
│   comes ease."                  │
│                                 │
│  — Surah Ash-Sharh (94:6)       │
└─────────────────────────────────┘
```

#### Large Widget - Dashboard
```
┌─────────────────────────────────┐
│  Safa                           │
├─────────────────────────────────┤
│        ASR · in 2h 34m          │
│          3:45 PM                │
│                                 │
│  F ✓  D ✓  A ·  M ·  I ·       │
│                                 │
│  🔥 23 day streak               │
│  📖 Surah Al-Baqarah: 45%       │
│                                 │
│  "Verily, in the remembrance    │
│   of Allah do hearts find rest" │
└─────────────────────────────────┘
```

### 5.2 Live Activities & Dynamic Island

Real-time prayer countdown visible without unlocking the phone.

#### Lock Screen Live Activity
```
┌─────────────────────────────────┐
│  🕌 Safa        ASR in 12:34    │
│                         3:45 PM │
└─────────────────────────────────┘
```

#### Dynamic Island (Compact)
```
      ┌─────────────────────┐
      │ 🕌  ASR 12:34  3:45 │
      └─────────────────────┘
```

#### Dynamic Island (Expanded)
```
┌─────────────────────────────────┐
│  🕌 Safa                        │
│                                 │
│         ASR                     │
│       in 12:34                  │
│       3:45 PM                   │
│                                 │
│  [Open Qibla]    [Log Prayer]   │
└─────────────────────────────────┘
```

**Live Activity Triggers:**
- Activates 30 minutes before each prayer (configurable)
- Shows countdown until prayer time enters
- Optional: stays active until prayer is logged
- Ramadan: shows Iftar/Suhoor countdown

### 5.3 Focus Mode Integration

Safa integrates with iOS Focus modes for distraction-free worship.

#### "Prayer" Focus Mode
When enabled (manually or via automation):
- Silences all non-essential notifications
- Allows only Safa prayer notifications
- Shows prayer-focused Lock Screen
- Suggested duration: 10-15 minutes

**Setup prompt on first prayer log:**
```
┌─────────────────────────────────┐
│  Create Prayer Focus?           │
├─────────────────────────────────┤
│                                 │
│  Silence distractions during    │
│  your prayer time.              │
│                                 │
│  • Mutes all notifications      │
│  • Shows prayer Lock Screen     │
│  • Auto-ends after 15 min       │
│                                 │
│  [Set Up]        [Not Now]      │
│                                 │
└─────────────────────────────────┘
```

**Automation Suggestion:**
- "Enable Prayer Focus when Safa prayer notification arrives?"
- Uses iOS Shortcuts for automation

#### "Sleep" Focus Mode Integration
- Safa's Wind-Down mode can trigger Sleep Focus
- Morning Fajr alarm bypasses Sleep Focus
- Bedtime reminder syncs with iOS Sleep schedule

### 5.4 Siri Shortcuts

Voice-activated features for hands-free use.

**Pre-built Shortcuts:**
- "Hey Siri, what time is the next prayer?"
- "Hey Siri, start my morning adhkar"
- "Hey Siri, open Qibla compass"
- "Hey Siri, how long until Iftar?" (Ramadan)
- "Hey Siri, log my Fajr prayer"
- "Hey Siri, start tasbeeh counter"

**Shortcut Actions Available:**
- Get next prayer time
- Get all prayer times for today
- Open specific app section
- Start dhikr session
- Log prayer
- Get streak count

---

### 4.10 Learn (Unified Learning Hub)

The Learn section consolidates all educational features into a Duolingo-style gamified experience with points, streaks, and progression.

#### Learning Tracks

**Track 1: Arabic Foundations**
- Arabic alphabet recognition
- Letter forms (initial, medial, final, isolated)
- Basic pronunciation with speech recognition feedback
- Short vowels (harakat)
- Common Islamic vocabulary

**Track 2: Tajweed (Recitation Rules)**
- Noon Sakinah & Tanween rules
- Meem Sakinah rules
- Madd (elongation) rules
- Qalqalah
- Proper pronunciation of heavy/light letters
- Practice with example ayaat

**Track 3: Quran Recitation**
- Listen & repeat exercises
- Speech recognition scoring
- Start with short surahs (Juz Amma)
- Progress to longer passages
- Memorization mode with spaced repetition

**Track 4: Dhikr & Dua Mastery**
- Learn proper pronunciation of common adhkar
- Morning/evening adhkar completion challenges
- Tasbeeh sessions with goals
- Dua memorization with audio

---

## 6. Gamification & Progression System

The gamification system is designed to encourage consistent worship and learning through positive reinforcement, inspired by Duolingo's proven engagement model.

### 5.1 Points System: Hasanat (حسنات)

"Hasanat" (good deeds) serves as the in-app currency/points system - a meaningful Islamic concept.

#### Earning Hasanat

| Activity | Hasanat Earned |
|----------|----------------|
| **Prayer** | |
| Log a prayer on time | +10 |
| Log all 5 prayers in a day | +25 bonus |
| **Quran** | |
| Read 1 page | +5 |
| Complete a surah | +15 |
| Complete a juz | +50 |
| Listen to recitation (5 min) | +3 |
| **Learning** | |
| Complete a lesson | +10 |
| Perfect score on a lesson | +5 bonus |
| Pass a pronunciation check | +5 |
| Complete a Tajweed module | +20 |
| **Dhikr** | |
| Complete morning adhkar | +15 |
| Complete evening adhkar | +15 |
| Tasbeeh session (100 count) | +10 |
| Custom dhikr goal met | +10 |
| **Engagement** | |
| Daily app open | +5 |
| Read daily verse | +3 |
| Read daily hadith | +3 |
| **Sharing** | |
| Share a verse or hadith | +5 |
| Invite a friend (accepted) | +25 |
| Family member joins circle | +15 |
| **Ramadan Bonuses** | |
| Log a fasting day | +20 |
| Complete Taraweeh | +25 |
| Quran reading during Ramadan | 2x multiplier |

### 5.2 Streaks

Streaks encourage daily consistency:

| Streak Type | Description |
|-------------|-------------|
| **Daily Streak** | Open app and complete any activity |
| **Prayer Streak** | Log all 5 prayers |
| **Quran Streak** | Read any amount of Quran |
| **Dhikr Streak** | Complete morning OR evening adhkar |
| **Learning Streak** | Complete at least one lesson |

**Streak Protection**:
- One "streak freeze" earned per 7-day streak
- Can store up to 3 freezes
- Freezes auto-apply if a day is missed

### 5.3 Levels & Progression

Users progress through levels based on total Hasanat earned:

| Level | Title | Hasanat Required |
|-------|-------|------------------|
| 1 | Beginner | 0 |
| 2 | Seeker | 100 |
| 3 | Learner | 300 |
| 4 | Dedicated | 600 |
| 5 | Consistent | 1,000 |
| 6 | Devoted | 2,000 |
| 7 | Steadfast | 4,000 |
| 8 | Committed | 7,000 |
| 9 | Excellent | 12,000 |
| 10 | Muhsin | 20,000 |

Each level unlocks:
- New profile badge/frame
- Congratulatory message with relevant hadith about consistency

### 5.4 Achievements (Badges)

Achievements recognize specific milestones:

**Quran Achievements**
- 📖 First Page - Read your first page
- 📚 Surah Complete - Finish any surah
- 🏆 Juz Champion - Complete a full juz
- ⭐ Khatm - Complete the entire Quran
- 🎧 Listener - Listen to 10 hours of recitation

**Prayer Achievements**
- 🕌 First Prayer - Log your first prayer
- ✨ Perfect Day - Log all 5 prayers in a day
- 🔥 Week Warrior - 7-day prayer streak
- 💪 Month Strong - 30-day prayer streak
- 🏅 Fajr Fighter - 30 Fajr prayers logged

**Learning Achievements**
- 🔤 Alphabet Master - Learn all Arabic letters
- 🗣️ Clear Voice - Pass 50 pronunciation checks
- 📜 Tajweed Student - Complete Tajweed basics
- 🎓 Scholar's Path - Complete all learning tracks

**Dhikr Achievements**
- 📿 First Tasbeeh - Complete your first session
- 🌅 Morning Person - 7-day morning adhkar streak
- 🌙 Evening Devotee - 7-day evening adhkar streak
- ♾️ 10,000 Count - Lifetime tasbeeh count

**Ramadan Achievements**
- 🌙 Ramadan Ready - Complete first fast
- 🏆 Full Month - Fast all 30 days
- 📖 Khatm in Ramadan - Complete Quran during Ramadan
- 🌟 Night Worshipper - Complete Taraweeh for 10 nights

### 5.5 Daily Goals

Users can set personalized daily goals:

```
┌─────────────────────────────────┐
│  Today's Goals                  │
├─────────────────────────────────┤
│                                 │
│  ☐ Read 5 pages of Quran       │
│     ██████░░░░  3/5 pages      │
│                                 │
│  ☐ Complete morning adhkar     │
│     ████████░░  80%            │
│                                 │
│  ☐ 1 learning lesson           │
│     ░░░░░░░░░░  Not started    │
│                                 │
│  ☐ 100 tasbeeh                 │
│     ██████████  ✓ Complete     │
│                                 │
│  Today: 45 Hasanat earned      │
│                                 │
└─────────────────────────────────┘
```

**Goal Presets**:
- Light (15 min/day): 2 pages Quran, adhkar, 1 lesson
- Moderate (30 min/day): 5 pages, adhkar, 2 lessons, tasbeeh
- Dedicated (1 hr/day): 10 pages, adhkar, 3 lessons, extended dhikr
- Custom: User sets own targets

### 5.6 Weekly Challenges

Optional weekly challenges for extra engagement:

- "Memorize Surah Al-Fatiha pronunciation perfectly"
- "Complete morning adhkar every day this week"
- "Read Surah Al-Kahf on Friday"
- "Learn 5 new Tajweed rules"
- "Reach 500 Hasanat this week"

### 5.7 Progress Dashboard

```
┌─────────────────────────────────┐
│  Your Journey                   │
├─────────────────────────────────┤
│                                 │
│  Level 6: Devoted               │
│  ████████████░░░░  2,847/4,000  │
│                                 │
│  🔥 Streaks                     │
│  Daily: 23 days                 │
│  Prayer: 18 days                │
│  Quran: 12 days                 │
│                                 │
│  📊 This Week                   │
│  342 Hasanat earned             │
│  14 lessons completed           │
│  35 pages read                  │
│                                 │
│  🏆 Recent Achievements         │
│  [Fajr Fighter] [Week Warrior]  │
│                                 │
│  [View All Stats]               │
│                                 │
└─────────────────────────────────┘
```

### 5.8 Design Principles for Gamification

- **Positive reinforcement only** - Never punish, only encourage
- **Islamic framing** - Hasanat concept connects to real reward
- **No comparison/competition** - Personal journey, not leaderboards
- **Gentle reminders** - "You're 2 pages from your goal!" not "You're falling behind!"
- **Celebrate consistency** - Small daily efforts > occasional large ones
- **Meaningful milestones** - Achievements tied to Islamic significance

---

## 7. User Experience Flows

### 6.1 Home Screen (Default) - Minimal Design

The home screen prioritizes simplicity and calm. Clean, uncluttered, focused on the essentials.

```
┌─────────────────────────────────┐
│                                 │
│           ASR                   │
│          3:45 PM                │
│        in 2h 34m                │
│                                 │
│  ┌─────────────────────────┐   │
│  │ · · · ● ·               │   │  ← Prayer timeline
│  │ F   D   A   M   I       │   │    (current = filled)
│  └─────────────────────────┘   │
│                                 │
│                                 │
│                                 │
│                                 │
│                                 │
│                                 │
│                                 │
│                                 │
│                                 │
│                                 │
│                                 │
│                                 │
├─────────────────────────────────┤
│  [Home] [Quran] [Learn] [More] │
└─────────────────────────────────┘
```

**Design Notes:**
- Vast whitespace creates calm, contemplative feel
- Single focus: next prayer time, prominently displayed
- Minimal prayer timeline shows day's progress at a glance
- No cards, no clutter - just breathing room
- Additional features accessed via tab bar
- Contextual reminder appears only when relevant (subtle banner at top)

### 6.2 Home Screen with Contextual Alert

```
┌─────────────────────────────────┐
│ Dhuhr in 12 min            [✕] │  ← Subtle contextual banner
├─────────────────────────────────┤
│                                 │
│           DHUHR                 │
│          12:15 PM               │
│         in 12 min               │
│                                 │
│  ┌─────────────────────────┐   │
│  │ ● · · · ·               │   │
│  │ F   D   A   M   I       │   │
│  └─────────────────────────┘   │
│                                 │
│                                 │
│                                 │
│                                 │
│                                 │
│                                 │
│                                 │
│                                 │
│                                 │
│                                 │
├─────────────────────────────────┤
│  [Home] [Quran] [Learn] [More] │
└─────────────────────────────────┘
```

### 6.3 Home Screen (Ramadan Mode)

Ramadan mode maintains minimalism while surfacing essential fasting information.

```
┌─────────────────────────────────┐
│ Laylatul Qadr? (odd night) [✕] │
├─────────────────────────────────┤
│                                 │
│           IFTAR                 │
│          6:23 PM                │
│        in 2h 15m                │
│                                 │
│       Day 21 of 30              │
│     ████████████████░░░░        │
│                                 │
│  ┌─────────────────────────┐   │
│  │ ● ● ● · ·               │   │
│  │ F   D   A   M   I       │   │
│  └─────────────────────────┘   │
│                                 │
│                                 │
│                                 │
│                                 │
│                                 │
│                                 │
│                                 │
│                                 │
├─────────────────────────────────┤
│  [Home] [Quran] [Learn] [More] │
└─────────────────────────────────┘
```

**Ramadan additions:**
- Iftar/Suhoor countdown replaces next prayer
- Day progress bar
- Quick access to Ramadan features in More tab

### 5.3 Contextual Reminder Examples
```
┌─────────────────────────────────┐
│ 🕐 Asr begins in 10 minutes    │
│    Time to make wudu.     [✕]  │
└─────────────────────────────────┘

┌─────────────────────────────────┐
│ 🌅 Good morning! Have you      │
│    read your morning adhkar?   │
│    [Open Adhkar]          [✕]  │
└─────────────────────────────────┘

┌─────────────────────────────────┐
│ 📖 Jumu'ah Mubarak!            │
│    Read Surah Al-Kahf today.   │
│    [Read Now]             [✕]  │
└─────────────────────────────────┘

┌─────────────────────────────────┐
│ 📅 Ashura is tomorrow.         │
│    Consider fasting.           │
│    [Learn More]           [✕]  │
└─────────────────────────────────┘

┌─────────────────────────────────┐
│ 🔥 7-day Quran streak!         │
│    Keep it going today.        │
│    [Continue Reading]     [✕]  │
└─────────────────────────────────┘
```

---

## 8. Information Architecture

```
Safa
├── Home (Dashboard)
│   ├── Contextual Reminder Card
│   ├── Next Prayer / Iftar Card
│   ├── Prayer Times Strip
│   ├── Quick Actions Grid
│   └── Daily Inspiration
│
├── Quran
│   ├── Browse Surahs
│   ├── Browse by Juz
│   ├── Search
│   ├── Bookmarks
│   ├── Audio Player
│   ├── Tafsir
│   └── Reading Settings
│
├── Prayer
│   ├── Today's Times
│   ├── Monthly Calendar View
│   ├── Qibla Compass
│   ├── Prayer Log / Tracker
│   ├── Makeup Prayers (Qada)
│   └── Nearby Mosques
│
├── Dhikr & Dua
│   ├── Tasbeeh Counter
│   ├── Morning Adhkar
│   ├── Evening Adhkar
│   ├── Dua Categories
│   │   ├── Daily Life
│   │   ├── Salah
│   │   ├── Protection
│   │   ├── Forgiveness
│   │   └── Hardship
│   └── My Favorites
│
├── Learn (Gamified Hub)
│   ├── Dashboard (Goals, Streaks, Level)
│   ├── Tracks
│   │   ├── Arabic Foundations
│   │   ├── Tajweed
│   │   ├── Quran Recitation
│   │   └── Dhikr & Dua Mastery
│   ├── Weekly Challenges
│   ├── Achievements
│   └── Progress Stats
│
├── Chat (AI Companion)
│   ├── New Conversation
│   └── History
│
├── Hadith
│   ├── Collections
│   │   ├── Sahih Bukhari
│   │   ├── Sahih Muslim
│   │   └── [Others]
│   ├── Daily Hadith
│   ├── Search
│   └── Bookmarks
│
├── Calendar
│   ├── Hijri Calendar
│   ├── Important Dates
│   └── My Reminders
│
├── Ramadan (seasonal)
│   ├── Fasting Tracker
│   ├── Quran Khatm Progress
│   ├── Taraweeh Tracker
│   ├── Zakat Calculator
│   ├── Sadaqah Log
│   └── Special Duas
│
├── Family
│   ├── Family Circle
│   ├── Invite Members
│   ├── Activity Feed
│   └── Privacy Settings
│
├── Wind Down (after Isha)
│   ├── Sleep Adhkar Checklist
│   ├── Calming Recitation
│   ├── Fajr Alarm Setup
│   └── Reflection Journal
│
└── Settings
    ├── Prayer Settings
    │   ├── Calculation Method
    │   ├── Adjustments
    │   └── Notifications
    ├── Appearance
    │   ├── Theme Color
    │   └── Arabic Font Style
    ├── Notifications
    │   ├── Prayer Alerts
    │   ├── Daily Content
    │   └── Event Reminders
    ├── Widgets & Live Activities
    │   ├── Configure Widgets
    │   └── Live Activity Settings
    ├── Focus Mode
    │   ├── Prayer Focus Setup
    │   └── Sleep Integration
    ├── Intelligent Features
    │   ├── Contextual Reminders (on/off)
    │   ├── Auto Ramadan Mode
    │   ├── Friday Reminders
    │   └── Streak Notifications
    ├── Family & Sharing
    │   ├── Manage Circle
    │   └── Privacy Controls
    ├── Language
    └── About
```

---

## 9. AI Companion Specifications

### 9.1 Architecture
- **Deployment**: Fully on-device (local inference)
- **Model**: Lightweight LLM (target: <500MB)
- **Candidates**:
  - Quantized Phi-3 Mini
  - Quantized Gemma 2B
  - Fine-tuned TinyLlama
  - Apple's on-device models (if available)
- **Framework**: Core ML / MLX for Apple Silicon optimization

### 9.2 Fine-tuning Strategy
- Base model fine-tuned on curated Islamic Q&A dataset
- Sources: IslamQA, SeekersGuidance, authenticated scholarly content
- Supervised fine-tuning on expected interaction patterns
- Extensive evaluation on Islamic knowledge benchmarks

### 9.3 System Prompt (Summary)
The AI companion ("Safa Assistant") should:
- Be knowledgeable but humble
- Always cite sources (Quran chapter:verse, Hadith collection)
- Present multiple scholarly opinions when applicable
- Acknowledge differences between madhabs neutrally
- Strongly recommend consulting local scholars for:
  - Personal fatwa questions
  - Marriage/divorce matters
  - Financial rulings specific to circumstances
- Use warm, encouraging, supportive tone
- Include Arabic terms with transliteration and translation
- Avoid political topics and controversial contemporary issues
- Never claim to be a scholar or mufti

### 9.4 Example Interactions
```
User: What is the dua before eating?

Safa: Before eating, the Prophet ﷺ taught us to say:

"Bismillah"
(In the name of Allah)

If you forget to say it at the start, you can say:

"Bismillahi awwalahu wa akhirahu"
(In the name of Allah, at its beginning and at its end)

[Sunan Abu Dawood 3767, graded Sahih]

Would you like me to show you the full etiquette of eating in Islam?
```

```
User: Does using eye drops break my fast?

Safa: This is a matter where scholars have different opinions:

**Opinion 1 (Majority)**: Eye drops do NOT break the fast, as the eyes are not a normal pathway for food/drink to reach the stomach.

**Opinion 2 (Some scholars)**: If the taste reaches the throat, it may break the fast as a precaution.

The stronger opinion among contemporary scholars is that eye drops are permissible during fasting.

However, for your specific situation, I recommend consulting a local scholar or imam who can give you a personalized answer.

[See: Islamic Fiqh Council rulings]
```

### 9.5 Boundaries
The AI will decline to:
- Issue personal fatwas on complex matters
- Discuss sect-based conflicts
- Engage in political discussions
- Provide medical or legal advice
- Generate any content against Islamic principles

---

## 10. Localization Strategy

### 10.1 Initial Release
- **English only** (full app)
- Arabic script for Quranic text and duas (always present)
- Transliteration provided for all Arabic content

### 10.2 Expansion Roadmap (Priority Order)
Based on global Muslim population and app store demand:

| Priority | Language | Estimated Users |
|----------|----------|-----------------|
| 1 | Arabic | 300M+ |
| 2 | Urdu | 200M+ |
| 3 | Indonesian/Malay | 250M+ |
| 4 | Turkish | 80M+ |
| 5 | French | 50M+ (North/West Africa) |
| 6 | Bengali | 150M+ |
| 7 | Farsi | 80M+ |

### 10.3 Localization Scope
- UI strings
- Quran translations (per language)
- Dua translations
- Hadith translations (where available)
- AI companion responses (requires per-language fine-tuning)

---

## 11. Monetization Strategy

**Primary Goal: Explosive Growth**

The app will be **completely free** with no paywalls or premium tiers. Revenue comes later; user acquisition comes first.

### 11.1 Model: Free + Donations + Ethical Sponsorships

| Revenue Stream | Description |
|----------------|-------------|
| **100% Free App** | All features accessible to everyone, no exceptions |
| **Optional Donations** | "Support Safa" button in settings - voluntary contribution |
| **Ethical Sponsorships** | Non-intrusive partnerships with halal businesses, Islamic education institutions, Muslim charities |

### 11.2 Why Free-First Works

1. **Removes friction** - No barrier to download and try
2. **Aligns with Islamic ethos** - Knowledge should be accessible
3. **Enables word-of-mouth** - Users share freely without guilt
4. **Builds trust** - No hidden upsells or "premium" dark patterns
5. **Network effects** - Family features require multiple users

### 11.3 Future Revenue (Post-Growth)

Once user base is established:
- Ethical sponsorships (carefully curated, never intrusive)
- Voluntary "sadaqah" donations
- Enterprise/institution licensing
- Physical merchandise (prayer rugs, tasbeeh, etc.)

---

## 12. Success Metrics

**Engagement Metrics**
- Daily Active Users (DAU)
- App Store rating (target: 4.8+)
- User retention (Day 1, Day 7, Day 30)

**Feature-Specific Metrics**
- Prayer notification engagement rate
- Quran reading session duration and completion
- AI companion conversations per user
- Feature adoption across all modules
- Ramadan mode engagement lift

**Gamification Metrics**
- Average daily Hasanat earned per user
- Streak maintenance rates (7-day, 30-day)
- Learning track completion rates
- Achievement unlock rates
- Daily goal completion percentage
- Lesson completion rate
- Pronunciation check pass rate

---

## 13. Resolved Decisions

- [x] App name: **Safa** (confirmed)
- [x] Accent colors: **User-configurable** (gold default)
- [x] Scope: **Full feature set in v1** (no MVP split)
- [x] LLM strategy: **Local/embedded lightweight model**
- [x] Initial language: **English only**
- [x] Contextual intelligence: **Core differentiator**
- [x] Gamification: **Duolingo-style with Hasanat points, streaks, levels**
- [x] iOS Widgets: **Included in v1**
- [x] Live Activities / Dynamic Island: **Included in v1**
- [x] Focus Mode integration: **Included in v1**
- [x] Sleep & Wind-Down mode: **Included in v1**
- [x] Family features with sharing: **Included in v1**
- [x] Home screen: **Minimal, clean design with prayer focus**
- [x] Monetization: **Free app + optional donations + ethical sponsorships**
- [x] Growth strategy: **Explosive growth first, monetization later**

---

## 14. v2 Roadmap (Future Enhancements)

Features planned for future releases:

### Sharing as Sadaqah Jariyah
The Islamic concept of "ongoing charity" - when you share beneficial knowledge, you continue to receive reward even after death. This powerful concept will be deeply integrated:

- **Sadaqah Jariyah tracker**: See how many people you've introduced to beneficial content
- **Ripple effect visualization**: "Your shared verse was read by 47 people"
- **Ongoing reward counter**: Conceptual visualization of compounding good deeds
- **Family tree of knowledge**: See how your shares spread to others who then shared
- **Milestone celebrations**: "MashaAllah! Your shared content has been viewed 1000 times"

### Other v2 Features
- Apple Watch app (Qibla, prayer alerts, tasbeeh on wrist)
- Siri Shortcuts expansion
- Ambient audio library (nature sounds for reflection)
- Community features (local mosque integration)
- Advanced memorization tools (spaced repetition for Quran)
- Podcast-style Islamic lectures
- Integration with Muslim Pro/other apps for data import

---

## 15. Open Questions

- [ ] Specific lightweight LLM model selection
- [ ] Content licensing (Quran translations, Hadith databases)
- [ ] Audio recitation licensing
- [ ] Beta testing community/approach
- [ ] Content partnerships (scholars, institutions)
- [ ] App Store pricing decision
- [ ] Speech recognition API for pronunciation feedback

---

*Document Version: 1.0*
*Last Updated: February 2026*
*Status: Final*
