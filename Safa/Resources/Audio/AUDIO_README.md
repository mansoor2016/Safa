# Audio Files — Sourcing & Re-encoding Guide

## Current State

Full-length adhan files are AAC-compressed M4A at 128kbps.
Notification sounds are AAC-compressed CAF at 64kbps/22kHz.

These were re-encoded from higher-quality originals to reduce bundle size.
If audio quality is insufficient, follow the steps below to restore or upgrade.

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

To re-encode at higher quality (e.g. 256kbps):
```bash
afconvert original.wav output.m4a -d aac -f m4af -b 256000
```

To restore to uncompressed CAF (maximum quality, large file):
```bash
afconvert original.wav output.caf -d LEI16 -f caff
```

Current encoding (128kbps, good quality, small size):
```bash
afconvert original.wav output.m4a -d aac -f m4af -b 128000
```

### Notification sounds (CAF, required by Apple)

Apple requires notification sounds to be CAF format, ≤30 seconds.

To re-encode at higher quality:
```bash
afconvert original.wav output_notification.caf -d aac -f caff -r 44100 -b 128000
```

Current encoding (64kbps, 22kHz — smallest while maintaining clarity):
```bash
afconvert original.wav output_notification.caf -d aac -f caff -r 22050 -b 64000
```

### Batch re-encode all full-length files

```bash
for f in Safa/Resources/Audio/Adhan/*.m4a; do
  base=$(basename "$f" .m4a)
  # Replace with path to your high-quality originals
  afconvert "originals/${base}.wav" "$f" -d aac -f m4af -b 256000
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
