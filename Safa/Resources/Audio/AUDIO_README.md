# Audio Files — Sourcing & Re-encoding Guide

## Current State

Full-length adhan files are AAC-compressed M4A at 128kbps.
Notification sounds are AAC-compressed CAF at 64kbps/22kHz.

These were encoded from higher-quality originals to reduce bundle size.

**IMPORTANT:** Re-encoding the current compressed files at a higher bitrate
will NOT improve quality — the information is already lost. You must go back
to the original lossless source files (WAV/AIFF) and re-encode from those.

## Original Sources

| Reciter | File | Original Format | Source |
|---------|------|----------------|--------|
| Mishary Rashid Alafasy | mishary_alafasy | WAV/AIFF | islamway.net / YouTube |
| Mishary Alafasy (Fajr) | mishary_alafasy_fajr | WAV/AIFF | islamway.net |
| Abdul Basit Abdul Samad | abdulbasit_abdusamad | WAV/AIFF | islamway.net |
| Adham Al Sharqawe | adham_al_sharqawe | WAV/AIFF | islamway.net |
| Ahmad Al Trablsi | ahmad_al_trablsi | WAV/AIFF | islamway.net |
| Ahmed El Kourdi | ahmed_el_kourdi | WAV/AIFF | islamway.net |
| Hamza Al Majale | hamza_al_majale | WAV/AIFF | islamway.net |
| Ismail Al Sheikh | ismail_al_sheikh | WAV/AIFF | islamway.net |
| Muhammad Al Damradash | muhammad_al_damradash | WAV/AIFF | islamway.net |
| Muhammad Ramadan Saad | muhammad_ramadan_saad_makkah | WAV/AIFF | islamway.net |
| Rabeh Ibn Darah | rabeh_ibn_darah | WAV/AIFF | islamway.net |

## Re-encoding Commands

### Full-length adhan (M4A, for in-app playback)

All commands below assume you have the original lossless files (WAV/AIFF).
Do NOT re-encode the existing .m4a files — you cannot recover lost quality.

```bash
# From original lossless → 256kbps AAC (excellent quality, larger)
afconvert original.wav output.m4a -d aac -f m4af -b 256000

# From original lossless → 128kbps AAC (current, good balance)
afconvert original.wav output.m4a -d aac -f m4af -b 128000

# From original lossless → uncompressed CAF (maximum quality, very large)
afconvert original.wav output.caf -d LEI16 -f caff
```

### Notification sounds (CAF, required by Apple)

Apple requires notification sounds to be CAF format, ≤30 seconds.

```bash
# From original lossless → higher quality notification
afconvert original.wav output_notification.caf -d aac -f caff -r 44100 -b 128000

# From original lossless → current encoding (smallest, still clear)
afconvert original.wav output_notification.caf -d aac -f caff -r 22050 -b 64000
```

### Batch re-encode all full-length files from originals

```bash
# Place original lossless files in an "originals/" directory first
for f in originals/*.wav; do
  base=$(basename "$f" .wav)
  afconvert "$f" "Safa/Resources/Audio/Adhan/${base}.m4a" -d aac -f m4af -b 256000
done
```

## File Locations

- Full-length adhan: `Safa/Resources/Audio/Adhan/*.m4a`
- Notification sounds: `Safa/Resources/Audio/Adhan/Notifications/*_notification.caf`

## Quality vs Size Tradeoffs

| Bitrate | Quality | ~Size per file (30s) | ~Size per file (3min) |
|---------|---------|---------------------|----------------------|
| 64kbps | Acceptable | ~240KB | ~1.4MB |
| 128kbps | Good | ~480KB | ~2.8MB |
| 256kbps | Excellent | ~960KB | ~5.6MB |
| Uncompressed | Perfect | ~2.6MB | ~15MB |

Current choice: 128kbps for full-length (good balance), 64kbps for notifications (clarity sufficient for short alerts).
