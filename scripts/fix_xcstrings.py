#!/usr/bin/env python3
"""
fix_xcstrings.py — Localization follow-up: populate empty keys, add interpolated
template keys, add Eid-specific keys. Minimal-diff serialization.

Fixes addressed:
  1. Populate 11 existing empty {} keys with translations
  2. Add new interpolated template keys with translations
  3. Add Eid-specific + EidReminder keys with translations
  4. Serialize using same json.dumps format as current file (minimal diff)

Run from repo root:
    python3 scripts/fix_xcstrings.py
"""

import copy
import json
import re
import sys
from collections import OrderedDict
from pathlib import Path

XCSTRINGS_PATH = Path(__file__).resolve().parent.parent / "Safa" / "Localizable.xcstrings"

LANGS = ["ar", "bn", "fa", "fr", "id", "ms", "tr", "ur"]


def make_loc(translations: dict) -> OrderedDict:
    """Build a localizations dict from {lang: value} mapping."""
    locs = OrderedDict()
    for lang in sorted(translations.keys()):
        locs[lang] = OrderedDict([
            ("stringUnit", OrderedDict([
                ("state", "translated"),
                ("value", translations[lang])
            ]))
        ])
    return OrderedDict([("localizations", locs)])


# ── Fix 1: 11 empty keys that need translations ──────────────────────────────

FIX1_TRANSLATIONS = {
    "Support Safa": {
        "ar": "دعم صفا",
        "bn": "সাফা সমর্থন করুন",
        "fa": "حمایت از صفا",
        "fr": "Soutenir Safa",
        "id": "Dukung Safa",
        "ms": "Sokong Safa",
        "tr": "Safa'yı Destekle",
        "ur": "صفا کی حمایت کریں",
    },
    "Manage Subscription": {
        "ar": "إدارة الاشتراك",
        "bn": "সাবস্ক্রিপশন পরিচালনা করুন",
        "fa": "مدیریت اشتراک",
        "fr": "Gérer l'abonnement",
        "id": "Kelola Langganan",
        "ms": "Urus Langganan",
        "tr": "Aboneliği Yönet",
        "ur": "سبسکرپشن کا انتظام کریں",
    },
    "Active": {
        "ar": "نشط",
        "bn": "সক্রিয়",
        "fa": "فعال",
        "fr": "Actif",
        "id": "Aktif",
        "ms": "Aktif",
        "tr": "Aktif",
        "ur": "فعال",
    },
    "Restore Purchases": {
        "ar": "استعادة المشتريات",
        "bn": "কেনাকাটা পুনরুদ্ধার করুন",
        "fa": "بازیابی خریدها",
        "fr": "Restaurer les achats",
        "id": "Pulihkan Pembelian",
        "ms": "Pulihkan Pembelian",
        "tr": "Satın Almaları Geri Yükle",
        "ur": "خریداریاں بحال کریں",
    },
    "Subscriber": {
        "ar": "مشترك",
        "bn": "সাবস্ক্রাইবার",
        "fa": "مشترک",
        "fr": "Abonné",
        "id": "Pelanggan",
        "ms": "Pelanggan",
        "tr": "Abone",
        "ur": "سبسکرائبر",
    },
    "Subscribers get custom app icons and early access to new features.": {
        "ar": "يحصل المشتركون على أيقونات مخصصة للتطبيق ووصول مبكر للميزات الجديدة.",
        "bn": "সাবস্ক্রাইবাররা কাস্টম অ্যাপ আইকন এবং নতুন ফিচারে আগাম অ্যাক্সেস পান।",
        "fa": "مشترکین آیکون‌های سفارشی و دسترسی زودهنگام به ویژگی‌های جدید دریافت می‌کنند.",
        "fr": "Les abonnés bénéficient d'icônes personnalisées et d'un accès anticipé aux nouvelles fonctionnalités.",
        "id": "Pelanggan mendapatkan ikon aplikasi kustom dan akses awal ke fitur baru.",
        "ms": "Pelanggan mendapat ikon aplikasi tersuai dan akses awal ke ciri baharu.",
        "tr": "Aboneler özel uygulama simgeleri ve yeni özelliklere erken erişim elde eder.",
        "ur": "سبسکرائبرز کو کسٹم ایپ آئیکنز اور نئی خصوصیات تک جلد رسائی ملتی ہے۔",
    },
    "Thank you for supporting Safa.": {
        "ar": "شكرًا لدعمك صفا.",
        "bn": "সাফা সমর্থন করার জন্য ধন্যবাদ।",
        "fa": "از حمایت شما از صفا سپاسگزاریم.",
        "fr": "Merci de soutenir Safa.",
        "id": "Terima kasih telah mendukung Safa.",
        "ms": "Terima kasih kerana menyokong Safa.",
        "tr": "Safa'yı desteklediğiniz için teşekkürler.",
        "ur": "صفا کی حمایت کے لیے شکریہ۔",
    },
    "App Icon": {
        "ar": "أيقونة التطبيق",
        "bn": "অ্যাপ আইকন",
        "fa": "آیکون برنامه",
        "fr": "Icône de l'app",
        "id": "Ikon Aplikasi",
        "ms": "Ikon Aplikasi",
        "tr": "Uygulama Simgesi",
        "ur": "ایپ آئیکن",
    },
    "Hold for rak'ah count": {
        "ar": "اضغط مطولاً لعدد الركعات",
        "bn": "রাকআত সংখ্যার জন্য ধরে রাখুন",
        "fa": "برای تعداد رکعت نگه دارید",
        "fr": "Maintenez pour le nombre de rak'ah",
        "id": "Tahan untuk jumlah rakaat",
        "ms": "Tahan untuk bilangan rakaat",
        "tr": "Rekât sayısı için basılı tutun",
        "ur": "رکعت کی تعداد کے لیے دبائے رکھیں",
    },
    "Tahajjud: 2 to 12 rak'ahs (pairs of 2)": {
        "ar": "تهجد: ٢ إلى ١٢ ركعة (أزواج من ٢)",
        "bn": "তাহাজ্জুদ: ২ থেকে ১২ রাকআত (২ এর জোড়ায়)",
        "fa": "تهجد: ۲ تا ۱۲ رکعت (جفت‌های ۲ تایی)",
        "fr": "Tahajjud : 2 à 12 rak'ahs (paires de 2)",
        "id": "Tahajud: 2 hingga 12 rakaat (berpasangan 2)",
        "ms": "Tahajjud: 2 hingga 12 rakaat (pasangan 2)",
        "tr": "Teheccüd: 2 ila 12 rekât (2'li çiftler)",
        "ur": "تہجد: ٢ سے ١٢ رکعات (٢ کے جوڑوں میں)",
    },
    "Best time for Qiyam al-Layl": {
        "ar": "أفضل وقت لقيام الليل",
        "bn": "কিয়ামুল লাইলের সেরা সময়",
        "fa": "بهترین زمان برای قیام اللیل",
        "fr": "Meilleur moment pour Qiyam al-Layl",
        "id": "Waktu terbaik untuk Qiyamul Lail",
        "ms": "Masa terbaik untuk Qiyamul Lail",
        "tr": "Kıyamu'l-Leyl için en iyi zaman",
        "ur": "قیام اللیل کا بہترین وقت",
    },
}

# ── Fix 2: Interpolated template keys ─────────────────────────────────────────

FIX2_TRANSLATIONS = {
    "Next prayer is %@ at %@, %lld hours and %lld minutes remaining": {
        "ar": "%1$@ الصلاة التالية هي في %2$@، متبقي %3$lld ساعة و%4$lld دقيقة",
        "bn": "%1$@ পরবর্তী নামাজ সময় %2$@, %3$lld ঘণ্টা এবং %4$lld মিনিট বাকি",
        "fa": "%1$@ نماز بعدی در ساعت %2$@، %3$lld ساعت و %4$lld دقیقه باقیمانده",
        "fr": "La prochaine prière est %1$@ à %2$@, %3$lld heures et %4$lld minutes restantes",
        "id": "Salat berikutnya %1$@ pukul %2$@, %3$lld jam dan %4$lld menit lagi",
        "ms": "Solat seterusnya %1$@ pukul %2$@, %3$lld jam dan %4$lld minit lagi",
        "tr": "Sonraki namaz %1$@ saat %2$@, %3$lld saat ve %4$lld dakika kaldı",
        "ur": "%1$@ اگلی نماز وقت %2$@ پر، %3$lld گھنٹے اور %4$lld منٹ باقی",
    },
    "Next prayer is %@ at %@, %lld minutes remaining": {
        "ar": "%1$@ الصلاة التالية هي في %2$@، متبقي %3$lld دقيقة",
        "bn": "%1$@ পরবর্তী নামাজ সময় %2$@, %3$lld মিনিট বাকি",
        "fa": "%1$@ نماز بعدی در ساعت %2$@، %3$lld دقیقه باقیمانده",
        "fr": "La prochaine prière est %1$@ à %2$@, %3$lld minutes restantes",
        "id": "Salat berikutnya %1$@ pukul %2$@, %3$lld menit lagi",
        "ms": "Solat seterusnya %1$@ pukul %2$@, %3$lld minit lagi",
        "tr": "Sonraki namaz %1$@ saat %2$@, %3$lld dakika kaldı",
        "ur": "%1$@ اگلی نماز وقت %2$@ پر، %3$lld منٹ باقی",
    },
    "%@ - Day %lld": {
        "ar": "%1$@ - اليوم %2$lld",
        "bn": "%1$@ - দিন %2$lld",
        "fa": "%1$@ - روز %2$lld",
        "fr": "%1$@ - Jour %2$lld",
        "id": "%1$@ - Hari %2$lld",
        "ms": "%1$@ - Hari %2$lld",
        "tr": "%1$@ - %2$lld. Gün",
        "ur": "%1$@ - دن %2$lld",
    },
    "%lld day(s) until %@": {
        "ar": "%1$lld يوم حتى %2$@",
        "bn": "%2$@ পর্যন্ত %1$lld দিন",
        "fa": "%1$lld روز تا %2$@",
        "fr": "%1$lld jour(s) avant %2$@",
        "id": "%1$lld hari menuju %2$@",
        "ms": "%1$lld hari menuju %2$@",
        "tr": "%2$@ için %1$lld gün kaldı",
        "ur": "%2$@ تک %1$lld دن",
    },
    "Lv.%lld": {
        "ar": "م.%lld",
        "bn": "লে.%lld",
        "fa": "سطح %lld",
        "fr": "Nv.%lld",
        "id": "Lv.%lld",
        "ms": "Lv.%lld",
        "tr": "Sv.%lld",
        "ur": "سطح %lld",
    },
    "%lld-day streak at risk": {
        "ar": "سلسلة %lld يوم في خطر",
        "bn": "%lld দিনের ধারা ঝুঁকিতে",
        "fa": "رشته %lld روزه در خطر",
        "fr": "Série de %lld jours en danger",
        "id": "Streak %lld hari terancam",
        "ms": "Streak %lld hari terancam",
        "tr": "%lld günlük seri tehlikede",
        "ur": "%lld دن کا سلسلہ خطرے میں",
    },
    "%@ at %@, Tahajjud: 2 to 12 rak'ahs in pairs of 2": {
        "ar": "%1$@ في %2$@، تهجد: ٢ إلى ١٢ ركعة في أزواج من ٢",
        "bn": "%1$@ সময় %2$@, তাহাজ্জুদ: ২ থেকে ১২ রাকআত ২ এর জোড়ায়",
        "fa": "%1$@ در %2$@، تهجد: ۲ تا ۱۲ رکعت در جفت‌های ۲ تایی",
        "fr": "%1$@ à %2$@, Tahajjud : 2 à 12 rak'ahs en paires de 2",
        "id": "%1$@ pukul %2$@, Tahajud: 2 hingga 12 rakaat berpasangan 2",
        "ms": "%1$@ pukul %2$@, Tahajjud: 2 hingga 12 rakaat berpasangan 2",
        "tr": "%1$@ saat %2$@, Teheccüd: 2 ila 12 rekât 2'li çiftler halinde",
        "ur": "%1$@ وقت %2$@، تہجد: ٢ سے ١٢ رکعات ٢ کے جوڑوں میں",
    },
    "%@ at %@, Best time for Qiyam al-Layl": {
        "ar": "%1$@ في %2$@، أفضل وقت لقيام الليل",
        "bn": "%1$@ সময় %2$@, কিয়ামুল লাইলের সেরা সময়",
        "fa": "%1$@ در %2$@، بهترین زمان برای قیام اللیل",
        "fr": "%1$@ à %2$@, Meilleur moment pour Qiyam al-Layl",
        "id": "%1$@ pukul %2$@, Waktu terbaik untuk Qiyamul Lail",
        "ms": "%1$@ pukul %2$@, Masa terbaik untuk Qiyamul Lail",
        "tr": "%1$@ saat %2$@, Kıyamu'l-Leyl için en iyi zaman",
        "ur": "%1$@ وقت %2$@، قیام اللیل کا بہترین وقت",
    },
}

# ── Fix 3: Eid-specific + EidReminder keys ────────────────────────────────────

FIX3_TRANSLATIONS = {
    "May Allah accept from us and you": {
        "ar": "تقبل الله منا ومنكم",
        "bn": "আল্লাহ আমাদের ও আপনাদের থেকে কবুল করুন",
        "fa": "خداوند از ما و شما بپذیرد",
        "fr": "Qu'Allah accepte de nous et de vous",
        "id": "Semoga Allah menerima dari kami dan kamu",
        "ms": "Semoga Allah menerima daripada kami dan kamu",
        "tr": "Allah bizden ve sizden kabul etsin",
        "ur": "اللہ ہم سے اور آپ سے قبول فرمائے",
    },
    "completed": {
        "ar": "مكتمل",
        "bn": "সম্পন্ন",
        "fa": "انجام شده",
        "fr": "terminé",
        "id": "selesai",
        "ms": "selesai",
        "tr": "tamamlandı",
        "ur": "مکمل",
    },
    "not completed": {
        "ar": "غير مكتمل",
        "bn": "অসম্পন্ন",
        "fa": "انجام نشده",
        "fr": "non terminé",
        "id": "belum selesai",
        "ms": "belum selesai",
        "tr": "tamamlanmadı",
        "ur": "نامکمل",
    },
    "Double tap to unmark": {
        "ar": "انقر مرتين لإلغاء التحديد",
        "bn": "আনমার্ক করতে ডাবল ট্যাপ করুন",
        "fa": "برای لغو علامت دو بار ضربه بزنید",
        "fr": "Touchez deux fois pour décocher",
        "id": "Ketuk dua kali untuk menghapus tanda",
        "ms": "Ketuk dua kali untuk nyahtanda",
        "tr": "İşareti kaldırmak için çift dokunun",
        "ur": "نشان ہٹانے کے لیے ڈبل ٹیپ کریں",
    },
    "Double tap to mark as done": {
        "ar": "انقر مرتين للتحديد كمكتمل",
        "bn": "সম্পন্ন হিসেবে চিহ্নিত করতে ডাবল ট্যাপ করুন",
        "fa": "برای علامت‌گذاری به عنوان انجام شده دو بار ضربه بزنید",
        "fr": "Touchez deux fois pour marquer comme fait",
        "id": "Ketuk dua kali untuk menandai selesai",
        "ms": "Ketuk dua kali untuk tandakan selesai",
        "tr": "Tamamlandı olarak işaretlemek için çift dokunun",
        "ur": "مکمل کے طور پر نشان لگانے کے لیے ڈبل ٹیپ کریں",
    },
    # EidReminder titles
    "Eid Prayer": {
        "ar": "صلاة العيد",
        "bn": "ঈদের নামাজ",
        "fa": "نماز عید",
        "fr": "Prière de l'Aïd",
        "id": "Salat Ied",
        "ms": "Solat Hari Raya",
        "tr": "Bayram Namazı",
        "ur": "عید کی نماز",
    },
    "Fitrana (Zakat al-Fitr)": {
        "ar": "زكاة الفطر",
        "bn": "ফিতরা (যাকাতুল ফিতর)",
        "fa": "فطریه (زکات فطر)",
        "fr": "Fitrana (Zakat al-Fitr)",
        "id": "Fitrah (Zakat Fitrah)",
        "ms": "Fitrah (Zakat Fitrah)",
        "tr": "Fitre (Fıtır Sadakası)",
        "ur": "فطرانہ (زکاۃ الفطر)",
    },
    "Qurbani": {
        "ar": "أضحية",
        "bn": "কুরবানি",
        "fa": "قربانی",
        "fr": "Qurbani",
        "id": "Qurban",
        "ms": "Korban",
        "tr": "Kurban",
        "ur": "قربانی",
    },
    # EidReminder subtitles
    "Attend Eid prayer": {
        "ar": "حضور صلاة العيد",
        "bn": "ঈদের নামাজে যোগ দিন",
        "fa": "در نماز عید شرکت کنید",
        "fr": "Assister à la prière de l'Aïd",
        "id": "Menghadiri salat Ied",
        "ms": "Hadiri solat Hari Raya",
        "tr": "Bayram namazına katılın",
        "ur": "عید کی نماز میں شریک ہوں",
    },
    "Pay before Eid prayer — approx. £5-7/person": {
        "ar": "ادفع قبل صلاة العيد — تقريبًا ٥-٧ جنيهات/شخص",
        "bn": "ঈদের নামাজের আগে পরিশোধ করুন — প্রায় £৫-৭/জন",
        "fa": "قبل از نماز عید پرداخت کنید — تقریباً ۵-۷ پوند/نفر",
        "fr": "Payez avant la prière de l'Aïd — env. 5-7 £/personne",
        "id": "Bayar sebelum salat Ied — sekitar £5-7/orang",
        "ms": "Bayar sebelum solat Hari Raya — lebih kurang £5-7/orang",
        "tr": "Bayram namazından önce ödeyin — yakl. 5-7 £/kişi",
        "ur": "عید کی نماز سے پہلے ادا کریں — تقریباً £5-7/فرد",
    },
    "Arrange Qurbani for 10th-12th Dhul Hijjah": {
        "ar": "رتب الأضحية من ١٠ إلى ١٢ ذو الحجة",
        "bn": "১০-১২ জিলহজ্জের জন্য কুরবানির ব্যবস্থা করুন",
        "fa": "قربانی را برای ١٠ تا ١٢ ذوالحجه ترتیب دهید",
        "fr": "Organisez le Qurbani pour le 10-12 Dhul Hijjah",
        "id": "Siapkan Qurban untuk 10-12 Dzulhijjah",
        "ms": "Aturkan Korban untuk 10-12 Zulhijjah",
        "tr": "10-12 Zilhicce için Kurban hazırlayın",
        "ur": "١٠-١٢ ذوالحجہ کے لیے قربانی کا بندوبست کریں",
    },
    # PreEidBanner reminder template
    "Remember to %@": {
        "ar": "تذكر %@",
        "bn": "%@ মনে রাখুন",
        "fa": "%@ را به یاد داشته باشید",
        "fr": "N'oubliez pas %@",
        "id": "Ingat untuk %@",
        "ms": "Ingat untuk %@",
        "tr": "%@ unutmayın",
        "ur": "%@ یاد رکھیں",
    },
}

ALL_TRANSLATIONS = {}
ALL_TRANSLATIONS.update(FIX1_TRANSLATIONS)
ALL_TRANSLATIONS.update(FIX2_TRANSLATIONS)
ALL_TRANSLATIONS.update(FIX3_TRANSLATIONS)

# Keys that are expected to be new (don't already exist in the catalog).
# "Remember to %@" already exists — excluded from this set so it merges, not adds.
ALLOWED_NEW_KEYS = (set(FIX2_TRANSLATIONS.keys()) | set(FIX3_TRANSLATIONS.keys())) - {
    "Remember to %@",
}

# ── Placeholder validation ────────────────────────────────────────────────────

PLACEHOLDER_RE = re.compile(r"%(\d+\$)?(@|lld|llu|d|f|s)")


def extract_placeholders(fmt_string: str) -> list:
    """Extract format placeholders as list of (is_positional, type) tuples, in order."""
    results = []
    for m in PLACEHOLDER_RE.finditer(fmt_string):
        is_positional = m.group(1) is not None
        ptype = m.group(2)
        results.append((is_positional, ptype))
    return results


def validate_placeholders(key: str, translations: dict):
    """Assert each translation has matching placeholder count, types, and safe ordering."""
    en_phs = extract_placeholders(key)
    if not en_phs:
        return  # No placeholders to validate

    en_types_sorted = sorted(p[1] for p in en_phs)
    en_types_ordered = [p[1] for p in en_phs]

    for lang, value in translations.items():
        trans_phs = extract_placeholders(value)
        trans_types_sorted = sorted(p[1] for p in trans_phs)

        # 1. Count + types must match (regardless of order)
        if trans_types_sorted != en_types_sorted:
            raise ValueError(
                f"Placeholder type/count mismatch for key {key!r} in {lang!r}:\n"
                f"  English types (sorted): {en_types_sorted}\n"
                f"  {lang} types (sorted):  {trans_types_sorted}\n"
                f"  Value: {value!r}"
            )

        # 2. If translation has ANY non-positional placeholder, ordered types
        #    must match English exactly (no reordering without positional specifiers)
        all_positional = all(p[0] for p in trans_phs)
        if not all_positional:
            trans_types_ordered = [p[1] for p in trans_phs]
            if trans_types_ordered != en_types_ordered:
                has_any_positional = any(p[0] for p in trans_phs)
                if has_any_positional:
                    raise ValueError(
                        f"Mixed positional/non-positional placeholders for key "
                        f"{key!r} in {lang!r}. When reordering, ALL placeholders "
                        f"must use positional specifiers (e.g., %1$@).\n"
                        f"  Value: {value!r}"
                    )
                raise ValueError(
                    f"Placeholder order mismatch for key {key!r} in {lang!r}:\n"
                    f"  English order: {en_types_ordered}\n"
                    f"  {lang} order:  {trans_types_ordered}\n"
                    f"  Use positional specifiers (e.g., %1$@, %2$lld) to reorder.\n"
                    f"  Value: {value!r}"
                )


# ── Deep value extraction for preservation check ─────────────────────────────


def extract_lang_values(strings_dict: dict) -> dict:
    """Extract {(key, lang): value} for all translated entries."""
    result = {}
    for key, entry in strings_dict.items():
        if not entry or not isinstance(entry, dict):
            continue
        locs = entry.get("localizations", {})
        if not locs or not isinstance(locs, dict):
            continue
        for lang, lang_data in locs.items():
            if not isinstance(lang_data, dict):
                continue
            su = lang_data.get("stringUnit", {})
            if isinstance(su, dict):
                val = su.get("value")
                if val is not None:
                    result[(key, lang)] = val
    return result


# ── Main ──────────────────────────────────────────────────────────────────────


def main():
    print(f"Reading {XCSTRINGS_PATH}...")
    with open(XCSTRINGS_PATH, "r", encoding="utf-8") as f:
        data = json.load(f, object_pairs_hook=OrderedDict)

    strings = data["strings"]
    pre_keys = set(strings.keys())

    # ── Snapshot pre-edit values for preservation check ────────────────────
    pre_values = extract_lang_values(strings)

    # ── Validate placeholders before modifying ────────────────────────────
    print("Validating placeholders...")
    for key, translations in ALL_TRANSLATIONS.items():
        validate_placeholders(key, translations)
    print("  All placeholder checks passed.")

    # ── Build edit allowlist ───────────────────────────────────────────────
    edit_allowlist = {}  # key -> set of langs we're modifying
    for key, translations in ALL_TRANSLATIONS.items():
        edit_allowlist[key] = set(translations.keys())

    # ── Apply translations ────────────────────────────────────────────────
    for key, translations in ALL_TRANSLATIONS.items():
        loc_data = make_loc(translations)

        if key in strings:
            existing = strings[key]
            if not existing:
                # Empty {} — replace entirely
                strings[key] = loc_data
            else:
                # Has some data — merge into localizations
                if "localizations" not in existing:
                    existing["localizations"] = OrderedDict()
                for lang, lang_data in loc_data["localizations"].items():
                    existing["localizations"][lang] = lang_data
        else:
            # New key
            strings[key] = loc_data

    # ── Serialize using same format as current file (json.dumps) ──────────
    print("Serializing (json.dumps, matching current file format)...")
    output = json.dumps(data, indent=2, ensure_ascii=False) + "\n"

    print(f"Writing {XCSTRINGS_PATH}...")
    with open(XCSTRINGS_PATH, "w", encoding="utf-8") as f:
        f.write(output)

    # ── Post-write validation ─────────────────────────────────────────────
    print("Running post-write validation...")

    # 1. Re-parse as valid JSON
    with open(XCSTRINGS_PATH, "r", encoding="utf-8") as f:
        reloaded = json.load(f, object_pairs_hook=OrderedDict)
    post_keys = set(reloaded["strings"].keys())
    print("  Valid JSON: OK")

    # 2. No pre-existing keys deleted
    deleted = pre_keys - post_keys
    if deleted:
        raise ValueError(f"FATAL: Pre-existing keys were deleted: {deleted}")
    print(f"  No deletions: OK ({len(pre_keys)} pre → {len(post_keys)} post)")

    # 3. Only allowed new keys added
    new_keys = post_keys - pre_keys
    unexpected = new_keys - ALLOWED_NEW_KEYS
    if unexpected:
        raise ValueError(f"FATAL: Unexpected new keys: {unexpected}")
    print(f"  New keys ({len(new_keys)}): OK — {sorted(new_keys)}")

    # 4. Value preservation: every pre-existing (key, lang) NOT in edit
    #    allowlist must have the same value as before
    post_values = extract_lang_values(reloaded["strings"])
    violations = []
    for (key, lang), pre_val in pre_values.items():
        if key in edit_allowlist and lang in edit_allowlist[key]:
            continue  # Intentionally edited
        post_val = post_values.get((key, lang))
        if post_val != pre_val:
            violations.append(
                f"  {key!r} [{lang}]: {pre_val!r} → {post_val!r}"
            )
    if violations:
        detail = "\n".join(violations[:20])
        raise ValueError(
            f"FATAL: {len(violations)} value(s) changed outside edit allowlist:\n"
            f"{detail}"
        )
    print(f"  Value preservation: OK — {len(pre_values)} pre-existing (key,lang) pairs intact")

    # 5. Coverage: every targeted key has 8 non-English localizations
    reloaded_strings = reloaded["strings"]
    for key in ALL_TRANSLATIONS:
        entry = reloaded_strings.get(key, {})
        locs = entry.get("localizations", {})
        missing_langs = [l for l in LANGS if l not in locs]
        if missing_langs:
            raise ValueError(
                f"FATAL: Key {key!r} missing translations for: {missing_langs}"
            )
        for lang in LANGS:
            val = (
                locs.get(lang, {})
                .get("stringUnit", {})
                .get("value", "")
            )
            if not val:
                raise ValueError(
                    f"FATAL: Key {key!r} has empty translation for {lang}"
                )
    print(f"  Coverage: OK — all {len(ALL_TRANSLATIONS)} keys × {len(LANGS)} languages")

    print("\nDone! All validations passed.")
    print(f"  Total keys in catalog: {len(post_keys)}")
    print(f"  Keys modified/added: {len(ALL_TRANSLATIONS)}")


if __name__ == "__main__":
    try:
        main()
    except Exception as e:
        print(f"\nERROR: {e}", file=sys.stderr)
        sys.exit(1)
