#!/usr/bin/env python3
"""
Translate missing widget string catalog entries.

Copies from main app where possible, uses glossary for Islamic terms,
and falls back to Google Translate via deep-translator for the rest.

Usage:
    python3 scripts/translate_widget_strings.py [--dry-run]
"""

import copy
import json
import os
import re
import sys
import time
import argparse
from pathlib import Path

# ---------------------------------------------------------------------------
# Paths
# ---------------------------------------------------------------------------

SCRIPT_DIR = Path(__file__).resolve().parent
PROJECT_ROOT = SCRIPT_DIR.parent
WIDGET_XCSTRINGS = PROJECT_ROOT / "SafaWidgetExtension" / "Localizable.xcstrings"
MAIN_XCSTRINGS = PROJECT_ROOT / "Safa" / "Localizable.xcstrings"
CACHE_FILE = SCRIPT_DIR / ".widget_translation_cache.json"

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

TARGET_LANGS = ["ar", "bn", "fa", "fr", "id", "ms", "tr", "ur"]

FORMAT_ONLY_KEYS = {"·", "/ 5", "/ %lld", "%lld", "%lld/5"}

# ISO 639-1 codes for deep-translator GoogleTranslator target parameter.
# Codes are more stable than language name aliases ("arabic", "persian", etc.).
LANG_CODES = {
    "ar": "ar",
    "bn": "bn",
    "fa": "fa",
    "fr": "fr",
    "id": "id",
    "ms": "ms",
    "tr": "tr",
    "ur": "ur",
}

# ---------------------------------------------------------------------------
# Islamic Glossary
# ---------------------------------------------------------------------------

GLOSSARY: dict[str, dict[str, str]] = {
    "Fajr": {
        "ar": "الفجر", "bn": "ফজর", "fa": "فجر", "fr": "Fajr",
        "id": "Subuh", "ms": "Subuh", "tr": "Sabah", "ur": "فجر",
    },
    "Dhuhr": {
        "ar": "الظهر", "bn": "যোহর", "fa": "ظهر", "fr": "Dhuhr",
        "id": "Dzuhur", "ms": "Zohor", "tr": "Öğle", "ur": "ظہر",
    },
    "Asr": {
        "ar": "العصر", "bn": "আসর", "fa": "عصر", "fr": "Asr",
        "id": "Ashar", "ms": "Asar", "tr": "İkindi", "ur": "عصر",
    },
    "Maghrib": {
        "ar": "المغرب", "bn": "মাগরিব", "fa": "مغرب", "fr": "Maghrib",
        "id": "Maghrib", "ms": "Maghrib", "tr": "Akşam", "ur": "مغرب",
    },
    "Isha": {
        "ar": "العشاء", "bn": "ইশা", "fa": "عشاء", "fr": "Isha",
        "id": "Isya", "ms": "Isyak", "tr": "Yatsı", "ur": "عشاء",
    },
    "Wudhu": {
        "ar": "الوضوء", "bn": "ওযু", "fa": "وضو", "fr": "woudou",
        "id": "wudhu", "ms": "wuduk", "tr": "abdest", "ur": "وضو",
    },
    "Dhikr": {
        "ar": "الذكر", "bn": "যিকির", "fa": "ذکر", "fr": "dhikr",
        "id": "dzikir", "ms": "zikir", "tr": "zikir", "ur": "ذکر",
    },
    "Tasbeeh": {
        "ar": "تسبيح", "bn": "তাসবীহ", "fa": "تسبیح", "fr": "tasbih",
        "id": "tasbih", "ms": "tasbih", "tr": "tesbih", "ur": "تسبیح",
    },
    "Mashallah": {
        "ar": "ما شاء الله", "bn": "মাশাআল্লাহ", "fa": "ماشاءالله", "fr": "Mashallah",
        "id": "Mashallah", "ms": "Mashallah", "tr": "Maşallah", "ur": "ماشاء اللہ",
    },
    "SubhanAllah": {
        "ar": "سبحان الله", "bn": "সুবহানাল্লাহ", "fa": "سبحان\u200cالله", "fr": "SubhanAllah",
        "id": "SubhanAllah", "ms": "SubhanAllah", "tr": "Sübhanallah", "ur": "سبحان اللہ",
    },
    "Alhamdulillah": {
        "ar": "الحمد لله", "bn": "আলহামদুলিল্লাহ", "fa": "الحمدلله", "fr": "Alhamdulillah",
        "id": "Alhamdulillah", "ms": "Alhamdulillah", "tr": "Elhamdülillah", "ur": "الحمد للہ",
    },
    "Allahu Akbar": {
        "ar": "الله أكبر", "bn": "আল্লাহু আকবার", "fa": "الله اکبر", "fr": "Allahu Akbar",
        "id": "Allahu Akbar", "ms": "Allahu Akbar", "tr": "Allahu Ekber", "ur": "اللہ اکبر",
    },
}

# ---------------------------------------------------------------------------
# Manual Overrides
# ---------------------------------------------------------------------------
# Corrections for MT errors that are systematically wrong. These take priority
# over MT/cache results. Key = xcstrings key, value = {lang: corrected_text}.
#
# Common MT failure: Google Translate renders "prayer" as "doa"/"dua"
# (supplication) instead of "shalat"/"namaz" (the five daily ritual prayers).
# "to go" is rendered as physical movement instead of "remaining".

MANUAL_OVERRIDES: dict[str, dict[str, str]] = {
    "%lld to go": {
        "ar": "%lld متبقي",
        "bn": "%lld বাকি",
        "fa": "%lld باقی‌مانده",
        "fr": "%lld restant",
        "id": "%lld lagi",
        "ms": "%lld lagi",
        "tr": "%lld kaldı",
        "ur": "%lld باقی",
    },
    "prayers completed": {
        "ar": "صلوات مكتملة",
        "bn": "নামাজ সম্পন্ন",
        "fa": "نماز تمام شد",
        "fr": "prières accomplies",
        "id": "shalat selesai",
        "ms": "solat selesai",
        "tr": "namazlar tamamlandı",
        "ur": "نمازیں مکمل",
    },
    "prayers today": {
        "ar": "صلوات اليوم",
        "bn": "আজ নামাজ",
        "fa": "نماز امروز",
        "fr": "prières aujourd'hui",
        "id": "shalat hari ini",
        "ms": "solat hari ini",
        "tr": "bugün namazlar",
        "ur": "آج کی نمازیں",
    },
}

# ---------------------------------------------------------------------------
# Glossary Compile Check
# ---------------------------------------------------------------------------

def validate_glossary() -> None:
    """Verify every glossary term has exactly TARGET_LANGS entries.

    Raises SystemExit on mismatch so we catch typos early.
    """
    errors = []
    for term, translations in GLOSSARY.items():
        missing = [lang for lang in TARGET_LANGS if lang not in translations]
        extra = [lang for lang in translations if lang not in TARGET_LANGS]
        if missing:
            errors.append(f"  GLOSSARY['{term}'] missing langs: {missing}")
        if extra:
            errors.append(f"  GLOSSARY['{term}'] has extra langs: {extra}")
        for lang, value in translations.items():
            if not isinstance(value, str) or not value.strip():
                errors.append(f"  GLOSSARY['{term}']['{lang}'] is empty or not a string")
    if errors:
        print("GLOSSARY VALIDATION FAILED:")
        for e in errors:
            print(e)
        sys.exit(1)


# ---------------------------------------------------------------------------
# Placeholder Validation
# ---------------------------------------------------------------------------

PLACEHOLDER_RE = re.compile(r"%%|%\d+\$@|%@|%l{0,2}d")


def extract_placeholders(text: str) -> tuple:
    """Returns (ordered specifiers excluding %%, count of %%)."""
    tokens = PLACEHOLDER_RE.findall(text)
    literals = tokens.count("%%")
    specifiers = [t for t in tokens if t != "%%"]
    return specifiers, literals


def validate_placeholders(english: str, translated: str) -> bool:
    """Validate that translated text has the same format specifiers as English.

    Positional specifiers (%1$@, %2$@) may appear in any order — translations
    legitimately reorder arguments (e.g. Turkish "%2$@ saatinde %1$@").
    Non-positional specifiers (%@, %lld) are compared as a multiset (count must
    match). Literal %% count must also match.
    """
    en_specs, en_lits = extract_placeholders(english)
    tr_specs, tr_lits = extract_placeholders(translated)
    return sorted(en_specs) == sorted(tr_specs) and en_lits == tr_lits


# ---------------------------------------------------------------------------
# Glossary Post-Replacement
# ---------------------------------------------------------------------------

def apply_glossary_post_replacement(text: str, lang: str) -> str:
    """Replace English Islamic terms in translated text with correct localized forms."""
    for english_term, translations in GLOSSARY.items():
        if lang in translations:
            localized = translations[lang]
            # Word-boundary match to avoid substring hits (e.g. "Asr" inside "Nasruddin").
            # Lambda replacement avoids re.sub interpreting \1 etc. in the value.
            text = re.sub(
                r"\b" + re.escape(english_term) + r"\b",
                lambda _m, _val=localized: _val,
                text,
                flags=re.IGNORECASE,
            )
    return text


# ---------------------------------------------------------------------------
# English Reference Text
# ---------------------------------------------------------------------------

def get_english_reference(key: str, key_data: dict) -> str:
    """Get the English reference text for a key.

    Uses the 'en' localization value if it exists (may have positional
    placeholders like %1$@ instead of %@), otherwise falls back to the key.
    """
    localizations = key_data.get("localizations", {})
    en_loc = localizations.get("en", {})
    en_unit = en_loc.get("stringUnit", {})
    en_value = en_unit.get("value")
    if en_value:
        return en_value
    return key


# ---------------------------------------------------------------------------
# Translation via deep-translator
# ---------------------------------------------------------------------------

_translator_cache = {}


def get_translator(lang: str):
    """Get or create a GoogleTranslator instance for the given language."""
    if lang not in _translator_cache:
        from deep_translator import GoogleTranslator
        _translator_cache[lang] = GoogleTranslator(source="en", target=LANG_CODES[lang])
    return _translator_cache[lang]


def _protect_placeholders(text: str) -> tuple:
    """Replace format specifiers with tokens MT won't mangle.

    Returns (protected_text, restore_map) where restore_map is a list of
    (token, original) pairs in the order they should be restored.
    """
    tokens = PLACEHOLDER_RE.findall(text)
    if not tokens:
        return text, []

    restore_map = []
    protected = text
    for i, token in enumerate(tokens):
        sentinel = f"XFMT{i}X"
        # Replace first occurrence only (preserves positional order)
        protected = protected.replace(token, sentinel, 1)
        restore_map.append((sentinel, token))
    return protected, restore_map


def _restore_placeholders(text: str, restore_map: list) -> str:
    """Restore original format specifiers from sentinel tokens."""
    for sentinel, original in restore_map:
        text = text.replace(sentinel, original, 1)
    return text


def mt_translate(text: str, lang: str, max_retries: int = 3) -> str | None:
    """Translate text using Google Translate with retries.

    Protects format specifiers (%@, %lld, %1$@, etc.) by replacing them
    with sentinel tokens before translation and restoring them after.
    """
    protected_text, restore_map = _protect_placeholders(text)
    translator = get_translator(lang)
    for attempt in range(max_retries):
        try:
            result = translator.translate(protected_text)
            if result:
                return _restore_placeholders(result, restore_map)
        except Exception as e:
            if attempt < max_retries - 1:
                wait = 2 ** attempt  # 1s, 2s, 4s
                print(f"  MT retry {attempt + 1}/{max_retries} for '{text}' -> {lang}: {e}")
                time.sleep(wait)
            else:
                print(f"  MT failed after {max_retries} retries for '{text}' -> {lang}: {e}")
                return None
    return None


# ---------------------------------------------------------------------------
# Cache
# ---------------------------------------------------------------------------

def load_cache() -> dict:
    """Load file-based translation cache."""
    if CACHE_FILE.exists():
        try:
            with open(CACHE_FILE, "r", encoding="utf-8") as f:
                return json.load(f)
        except (json.JSONDecodeError, OSError):
            return {}
    return {}


def save_cache(cache: dict) -> None:
    """Save translation cache to file."""
    with open(CACHE_FILE, "w", encoding="utf-8") as f:
        json.dump(cache, f, indent=2, ensure_ascii=False)


# ---------------------------------------------------------------------------
# Structural Integrity Check
# ---------------------------------------------------------------------------

def check_structural_integrity(original: dict, modified: dict) -> list:
    """Verify no keys removed, no existing values overwritten.

    Returns list of error strings (empty = pass).
    """
    errors = []

    # sourceLanguage and version must be unchanged
    if original.get("sourceLanguage") != modified.get("sourceLanguage"):
        errors.append("sourceLanguage changed")
    if original.get("version") != modified.get("version"):
        errors.append("version changed")

    orig_strings = original.get("strings", {})
    mod_strings = modified.get("strings", {})

    # Key set must be identical
    orig_keys = set(orig_strings.keys())
    mod_keys = set(mod_strings.keys())
    added_keys = mod_keys - orig_keys
    removed_keys = orig_keys - mod_keys
    if added_keys:
        errors.append(f"Keys added: {added_keys}")
    if removed_keys:
        errors.append(f"Keys removed: {removed_keys}")

    # For each key, existing lang entries must be identical
    for key in orig_keys & mod_keys:
        orig_locs = orig_strings[key].get("localizations", {})
        mod_locs = mod_strings[key].get("localizations", {})
        for lang, orig_entry in orig_locs.items():
            if lang not in mod_locs:
                errors.append(f"Key '{key}', lang '{lang}' removed")
            elif mod_locs[lang] != orig_entry:
                errors.append(f"Key '{key}', lang '{lang}' overwritten")

    return errors


# ---------------------------------------------------------------------------
# Main Pipeline
# ---------------------------------------------------------------------------

def main():
    parser = argparse.ArgumentParser(description="Translate missing widget strings")
    parser.add_argument("--dry-run", action="store_true",
                        help="Run pipeline but don't write xcstrings file")
    args = parser.parse_args()

    # 0. GLOSSARY COMPILE CHECK
    validate_glossary()

    # 1. LOAD
    print("Loading xcstrings files...")
    with open(WIDGET_XCSTRINGS, "r", encoding="utf-8") as f:
        widget_data = json.load(f)
    with open(MAIN_XCSTRINGS, "r", encoding="utf-8") as f:
        main_data = json.load(f)

    # Deep copy original for integrity check
    original_widget = copy.deepcopy(widget_data)

    cache = load_cache()
    main_strings = main_data.get("strings", {})
    widget_strings = widget_data.get("strings", {})

    # Counters
    stats = {
        "copied": 0,
        "glossary": 0,
        "manual_override": 0,
        "mt": 0,
        "cached": 0,
        "skipped_placeholder": 0,
        "skipped_mt_error": 0,
        "already_translated": 0,
        "format_only": 0,
    }

    # 2. PROCESS EACH KEY
    for key, key_data in widget_strings.items():
        # Skip format-only keys
        if key in FORMAT_ONLY_KEYS:
            stats["format_only"] += 1
            continue

        english_ref = get_english_reference(key, key_data)
        localizations = key_data.get("localizations", {})

        # Check which langs are missing
        missing_langs = [lang for lang in TARGET_LANGS if lang not in localizations]

        if not missing_langs:
            stats["already_translated"] += len(TARGET_LANGS)
            continue

        # Ensure localizations dict exists
        if "localizations" not in key_data:
            key_data["localizations"] = {}

        for lang in missing_langs:
            translation = None
            provenance = None
            state = "translated"

            # (i) Copy from main app
            if key in main_strings:
                main_locs = main_strings[key].get("localizations", {})
                if lang in main_locs:
                    main_unit = main_locs[lang].get("stringUnit", {})
                    main_value = main_unit.get("value")
                    if main_value and validate_placeholders(english_ref, main_value):
                        translation = main_value
                        provenance = "copied"

            # (ii) Standalone glossary key
            if translation is None and key in GLOSSARY and lang in GLOSSARY[key]:
                translation = GLOSSARY[key][lang]
                provenance = "glossary"

            # (ii-b) Manual override (corrects known MT errors)
            if translation is None and key in MANUAL_OVERRIDES:
                override = MANUAL_OVERRIDES[key].get(lang)
                if override and validate_placeholders(english_ref, override):
                    translation = override
                    provenance = "manual_override"

            # (iii) Cached translation
            if translation is None:
                cached_value = cache.get(key, {}).get(lang)
                if cached_value:
                    post_replaced = apply_glossary_post_replacement(cached_value, lang)
                    if validate_placeholders(english_ref, post_replaced):
                        translation = post_replaced
                        provenance = "cached"
                    else:
                        # Discard invalid cache entry
                        if key in cache and lang in cache[key]:
                            del cache[key][lang]

            # (iv) MT translate
            if translation is None:
                raw = mt_translate(english_ref, lang)
                if raw:
                    post_replaced = apply_glossary_post_replacement(raw, lang)
                    if validate_placeholders(english_ref, post_replaced):
                        translation = post_replaced
                        provenance = "mt"
                        # Save to cache
                        cache.setdefault(key, {})[lang] = raw
                    else:
                        # Placeholder mismatch — skip rather than write English
                        # fallback with needs_review. Skipping leaves the entry
                        # visibly missing in Xcode so it's clear a human must
                        # translate it, rather than showing English text that
                        # could be mistaken for a real translation.
                        provenance = "skipped_placeholder"
                        print(f"  Placeholder mismatch (skipped): '{key}' -> {lang}")
                else:
                    # MT failed — same rationale: skip to surface the gap
                    provenance = "skipped_mt_error"

                # Rate limit between MT calls
                if provenance in ("mt", "skipped_placeholder"):
                    time.sleep(0.3)

            # Write entry only if we have a real translation
            if translation is not None:
                key_data["localizations"][lang] = {
                    "stringUnit": {
                        "state": state,
                        "value": translation,
                    }
                }
            stats[provenance] += 1

    # 3. STRUCTURAL INTEGRITY CHECK
    print("\nRunning structural integrity check...")
    errors = check_structural_integrity(original_widget, widget_data)
    if errors:
        print("STRUCTURAL INTEGRITY CHECK FAILED:")
        for e in errors:
            print(f"  - {e}")
        print("\nAborting — xcstrings file NOT written.")
        sys.exit(1)
    print("Structural integrity check passed.")

    # 4. WRITE (unless dry-run)
    if not args.dry_run:
        print(f"\nWriting {WIDGET_XCSTRINGS}...")
        tmp_file = WIDGET_XCSTRINGS.with_suffix(".tmp")
        content = json.dumps(widget_data, indent=2, ensure_ascii=False, separators=(",", " : "))
        content += "\n"
        with open(tmp_file, "w", encoding="utf-8") as f:
            f.write(content)
        os.replace(tmp_file, WIDGET_XCSTRINGS)
        print("Written successfully.")
    else:
        print("\n[DRY RUN] Skipping file write.")

    # 5. SAVE CACHE (skip in dry-run to keep it side-effect free)
    if not args.dry_run:
        save_cache(cache)
        print(f"Cache saved to {CACHE_FILE}")
    else:
        print("[DRY RUN] Skipping cache write.")

    # 6. REPORT
    total_translatable_keys = len([k for k in widget_strings if k not in FORMAT_ONLY_KEYS])
    already_full = stats["already_translated"] // len(TARGET_LANGS) if stats["already_translated"] else 0

    # Count keys by completeness
    fully_translated = 0
    partially_missing = 0
    for key, key_data in widget_strings.items():
        if key in FORMAT_ONLY_KEYS:
            continue
        locs = key_data.get("localizations", {})
        has_all = all(lang in locs for lang in TARGET_LANGS)
        if has_all:
            fully_translated += 1
        elif any(lang in locs for lang in TARGET_LANGS):
            partially_missing += 1

    skipped_total = stats["skipped_placeholder"] + stats["skipped_mt_error"]
    print(f"""
=== Widget Translation Report ===
Copied from main app:        {stats['copied']} entries
Glossary (direct):           {stats['glossary']} entries
Manual overrides:            {stats['manual_override']} entries
Translated via MT:           {stats['mt']} entries
Reused from cache:           {stats['cached']} entries
Skipped (placeholder):       {stats['skipped_placeholder']} entries  <- MT broke placeholders, left untranslated
Skipped (MT error):          {stats['skipped_mt_error']} entries  <- MT call failed, left untranslated
Already translated:          {stats['already_translated']} entries  ({already_full} keys x {len(TARGET_LANGS)} langs)
Format-only (excluded):      {stats['format_only']} keys
---------------------------------------------
Fully translated:  {fully_translated}/{total_translatable_keys} keys (all {len(TARGET_LANGS)} langs present)
Partially missing: {partially_missing}/{total_translatable_keys} keys (some langs still need translation)
Skipped total:     {skipped_total} lang entries left empty for human translation
""")


if __name__ == "__main__":
    main()
