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
import os
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

# ── Fix 4: Fasting grace-state keys ──────────────────────────────────────────

FIX4_GRACE_TRANSLATIONS = {
    "It's Suhoor time!": {
        "ar": "حان وقت السحور!",
        "bn": "সেহরির সময় হয়েছে!",
        "fa": "وقت سحری است!",
        "fr": "C'est l'heure du Suhoor !",
        "id": "Waktunya Sahur!",
        "ms": "Waktu Sahur!",
        "tr": "Sahur vakti!",
        "ur": "سحری کا وقت ہے!",
    },
    "It's Iftar time!": {
        "ar": "حان وقت الإفطار!",
        "bn": "ইফতারের সময় হয়েছে!",
        "fa": "وقت افطار است!",
        "fr": "C'est l'heure de l'Iftar !",
        "id": "Waktunya Iftar!",
        "ms": "Waktu Iftar!",
        "tr": "İftar vakti!",
        "ur": "افطار کا وقت ہے!",
    },
    "Suhoor time": {
        "ar": "وقت السحور",
        "bn": "সেহরির সময়",
        "fa": "وقت سحری",
        "fr": "Heure du Suhoor",
        "id": "Waktu Sahur",
        "ms": "Waktu Sahur",
        "tr": "Sahur vakti",
        "ur": "سحری کا وقت",
    },
    "Iftar time": {
        "ar": "وقت الإفطار",
        "bn": "ইফতারের সময়",
        "fa": "وقت افطار",
        "fr": "Heure de l'Iftar",
        "id": "Waktu Iftar",
        "ms": "Waktu Iftar",
        "tr": "İftar vakti",
        "ur": "افطار کا وقت",
    },
}

# ── Fix 5: Eid share-message localization ────────────────────────────────────

FIX5_SHARE_TRANSLATIONS = {
    # Eid al-Fitr messages
    "Wishing you and your family a joyous Eid al-Fitr! May the blessings of Ramadan continue throughout the year.": {
        "ar": "أتمنى لك ولعائلتك عيد فطر سعيد! أسأل الله أن تستمر بركات رمضان طوال العام.",
        "bn": "আপনাকে ও আপনার পরিবারকে ঈদুল ফিতরের শুভেচ্ছা! রমজানের বরকত সারা বছর অব্যাহত থাকুক।",
        "fa": "عید فطر مبارک! از خداوند می‌خواهم برکات رمضان در سراسر سال ادامه یابد.",
        "fr": "Joyeux Aïd al-Fitr à vous et votre famille ! Que les bénédictions du Ramadan continuent toute l'année.",
        "id": "Selamat Hari Raya Idul Fitri untuk Anda dan keluarga! Semoga berkah Ramadan terus sepanjang tahun.",
        "ms": "Selamat Hari Raya Aidilfitri untuk anda dan keluarga! Semoga keberkatan Ramadan berterusan sepanjang tahun.",
        "tr": "Size ve ailenize mutlu bir Ramazan Bayramı diliyorum! Ramazanın bereketi yıl boyunca devam etsin.",
        "ur": "آپ اور آپ کے خاندان کو عید الفطر مبارک! اللہ کرے رمضان کی برکات سال بھر جاری رہیں۔",
    },
    "Eid Mubarak! May Allah accept our fasts, prayers, and good deeds. Wishing you a blessed celebration.": {
        "ar": "عيد مبارك! تقبل الله صيامنا وصلاتنا وأعمالنا الصالحة. أتمنى لكم احتفالاً مباركاً.",
        "bn": "ঈদ মুবারক! আল্লাহ আমাদের রোজা, নামাজ ও সৎকর্ম কবুল করুন। শুভ উদযাপন কামনা করি।",
        "fa": "عید مبارک! خداوند روزه‌ها، نمازها و اعمال نیکمان را بپذیرد. جشنی پربرکت آرزومندم.",
        "fr": "Aïd Moubarak ! Qu'Allah accepte nos jeûnes, nos prières et nos bonnes actions. Bonne fête bénie.",
        "id": "Selamat Idul Fitri! Semoga Allah menerima puasa, salat, dan amal baik kita. Selamat merayakan.",
        "ms": "Selamat Hari Raya! Semoga Allah menerima puasa, solat, dan amal baik kita. Selamat menyambut.",
        "tr": "Bayramınız mübarek olsun! Allah oruçlarımızı, namazlarımızı ve hayırlı amellerimizi kabul etsin.",
        "ur": "عید مبارک! اللہ ہمارے روزے، نمازیں اور نیک اعمال قبول فرمائے۔ مبارک جشن کی دعا۔",
    },
    "As we celebrate the end of Ramadan, may this Eid bring you peace, happiness, and endless blessings.": {
        "ar": "مع احتفالنا بنهاية رمضان، أسأل الله أن يمنحكم هذا العيد السلام والسعادة والبركات.",
        "bn": "রমজানের সমাপ্তি উদযাপনে, এই ঈদ আপনার জন্য শান্তি, সুখ এবং অফুরন্ত বরকত নিয়ে আসুক।",
        "fa": "با پایان رمضان، از خداوند می‌خواهم این عید برایتان صلح، شادی و برکات بی‌پایان به ارمغان آورد.",
        "fr": "Alors que nous célébrons la fin du Ramadan, que cet Aïd vous apporte paix, bonheur et bénédictions infinies.",
        "id": "Menyambut akhir Ramadan, semoga Idul Fitri ini membawa kedamaian, kebahagiaan, dan berkah tanpa akhir.",
        "ms": "Menyambut akhir Ramadan, semoga Hari Raya ini membawa keamanan, kebahagiaan, dan keberkatan tanpa henti.",
        "tr": "Ramazanın sonunu kutlarken, bu bayram size huzur, mutluluk ve sonsuz bereket getirsin.",
        "ur": "رمضان کے اختتام کے ساتھ، اللہ کرے یہ عید آپ کو سکون، خوشی اور لامحدود برکات عطا کرے۔",
    },
    "Eid al-Fitr Mubarak! May this day of celebration bring joy to your heart and light to your home.": {
        "ar": "عيد الفطر مبارك! أسأل الله أن يملأ هذا اليوم قلبكم فرحاً وبيتكم نوراً.",
        "bn": "ঈদুল ফিতর মুবারক! এই উদযাপনের দিন আপনার হৃদয়ে আনন্দ এবং ঘরে আলো নিয়ে আসুক।",
        "fa": "عید فطر مبارک! این روز جشن شادی به قلبتان و نور به خانه‌تان بیاورد.",
        "fr": "Aïd al-Fitr Moubarak ! Que ce jour de fête apporte la joie à votre cœur et la lumière à votre foyer.",
        "id": "Selamat Idul Fitri! Semoga hari perayaan ini membawa kegembiraan di hati dan cahaya di rumah Anda.",
        "ms": "Selamat Hari Raya Aidilfitri! Semoga hari perayaan ini membawa kegembiraan di hati dan cahaya di rumah anda.",
        "tr": "Ramazan Bayramınız mübarek olsun! Bu kutlama günü kalbinize neşe, yuvanıza nur getirsin.",
        "ur": "عید الفطر مبارک! اللہ کرے جشن کا یہ دن آپ کے دل میں خوشی اور گھر میں روشنی لائے۔",
    },
    "Taqabbal Allahu minna wa minkum. Wishing you a wonderful Eid filled with love, laughter, and togetherness.": {
        "ar": "تقبل الله منا ومنكم. أتمنى لكم عيداً رائعاً مليئاً بالمحبة والضحك واللُّمّة.",
        "bn": "তাকাব্বালাল্লাহু মিন্না ওয়া মিনকুম। ভালোবাসা, হাসি ও একতায় ভরা চমৎকার ঈদ কামনা করি।",
        "fa": "تقبل الله منا و منکم. عیدی پر از عشق، خنده و صمیمیت آرزومندم.",
        "fr": "Taqabbal Allahu minna wa minkum. Je vous souhaite un merveilleux Aïd rempli d'amour, de rires et de convivialité.",
        "id": "Taqabbalallahu minna wa minkum. Semoga Idul Fitri ini penuh cinta, tawa, dan kebersamaan.",
        "ms": "Taqabbalallahu minna wa minkum. Semoga Hari Raya ini dipenuhi kasih sayang, gelak tawa, dan kebersamaan.",
        "tr": "Taqabbalallahu minna wa minkum. Sevgi, neşe ve birliktelikle dolu harika bir bayram diliyorum.",
        "ur": "تقبل اللہ منا و منکم۔ محبت، خوشی اور اپنوں کے ساتھ بھرپور عید کی دعا۔",
    },
    # Eid al-Adha messages
    "Wishing you a blessed Eid al-Adha! May the spirit of sacrifice bring you closer to Allah.": {
        "ar": "عيد أضحى مبارك! أسأل الله أن تقربكم روح التضحية من الله.",
        "bn": "ঈদুল আযহা মুবারক! কুরবানির চেতনা আপনাকে আল্লাহর নিকটবর্তী করুক।",
        "fa": "عید قربان مبارک! روح قربانی شما را به خداوند نزدیک‌تر کند.",
        "fr": "Joyeux Aïd al-Adha ! Que l'esprit du sacrifice vous rapproche d'Allah.",
        "id": "Selamat Idul Adha! Semoga semangat berkorban mendekatkan Anda kepada Allah.",
        "ms": "Selamat Hari Raya Haji! Semoga semangat berkorban mendekatkan anda kepada Allah.",
        "tr": "Kurban Bayramınız mübarek olsun! Kurban ruhunun sizi Allah'a yakınlaştırması dileğiyle.",
        "ur": "عید الاضحیٰ مبارک! اللہ کرے قربانی کا جذبہ آپ کو اللہ سے قریب تر کرے۔",
    },
    "Eid Mubarak! May Allah accept your sacrifices and shower you with His mercy and blessings.": {
        "ar": "عيد مبارك! تقبل الله ضحاياكم وأغدق عليكم رحمته وبركاته.",
        "bn": "ঈদ মুবারক! আল্লাহ আপনার কুরবানি কবুল করুন এবং আপনার উপর রহমত ও বরকত বর্ষণ করুন।",
        "fa": "عید مبارک! خداوند قربانی‌هایتان را بپذیرد و رحمت و برکاتش را بر شما نازل کند.",
        "fr": "Aïd Moubarak ! Qu'Allah accepte vos sacrifices et vous couvre de Sa miséricorde et de Ses bénédictions.",
        "id": "Selamat Idul Adha! Semoga Allah menerima qurban Anda dan melimpahkan rahmat dan berkah-Nya.",
        "ms": "Selamat Hari Raya! Semoga Allah menerima korban anda dan melimpahkan rahmat dan berkat-Nya.",
        "tr": "Bayramınız mübarek olsun! Allah kurbanlarınızı kabul etsin, rahmet ve bereketini üzerinize yağdırsın.",
        "ur": "عید مبارک! اللہ آپ کی قربانیاں قبول فرمائے اور اپنی رحمت و برکات سے نوازے۔",
    },
    "On this blessed day of sacrifice, may Allah grant you and your loved ones peace, joy, and prosperity.": {
        "ar": "في يوم التضحية المبارك، أسأل الله أن يمنحكم وأحبائكم السلام والسعادة والرخاء.",
        "bn": "কুরবানির এই মুবারক দিনে, আল্লাহ আপনাকে ও আপনার প্রিয়জনদের শান্তি, আনন্দ ও সমৃদ্ধি দান করুন।",
        "fa": "در این روز مبارک قربانی، خداوند به شما و عزیزانتان صلح، شادی و خوشبختی عطا کند.",
        "fr": "En ce jour béni du sacrifice, qu'Allah vous accorde à vous et vos proches paix, joie et prospérité.",
        "id": "Di hari berkurban yang penuh berkah ini, semoga Allah memberikan kedamaian, kebahagiaan, dan kemakmuran.",
        "ms": "Pada hari berkorban yang diberkati ini, semoga Allah mengurniakan keamanan, kegembiraan, dan kemakmuran.",
        "tr": "Bu mübarek kurban gününde, Allah size ve sevdiklerinize huzur, neşe ve bereket ihsan etsin.",
        "ur": "قربانی کے اس مبارک دن، اللہ آپ اور آپ کے پیاروں کو سکون، خوشی اور خوشحالی عطا فرمائے۔",
    },
    "Eid al-Adha Mubarak! May the lessons of devotion and sacrifice guide us all throughout the year.": {
        "ar": "عيد الأضحى مبارك! أسأل الله أن تهدينا دروس الإخلاص والتضحية طوال العام.",
        "bn": "ঈদুল আযহা মুবারক! ভক্তি ও কুরবানির শিক্ষা সারা বছর আমাদের পথ দেখাক।",
        "fa": "عید قربان مبارک! درس‌های فداکاری و قربانی ما را در سراسر سال راهنمایی کند.",
        "fr": "Aïd al-Adha Moubarak ! Que les leçons de dévotion et de sacrifice nous guident toute l'année.",
        "id": "Selamat Idul Adha! Semoga pelajaran keikhlasan dan pengorbanan membimbing kita sepanjang tahun.",
        "ms": "Selamat Hari Raya Haji! Semoga pengajaran keikhlasan dan pengorbanan membimbing kita sepanjang tahun.",
        "tr": "Kurban Bayramınız mübarek olsun! Bağlılık ve fedakârlık dersleri yıl boyunca bize yol göstersin.",
        "ur": "عید الاضحیٰ مبارک! اللہ کرے عقیدت اور قربانی کے اسباق سال بھر ہماری رہنمائی کریں۔",
    },
    "Taqabbal Allahu minna wa minkum. Wishing you and your family a joyful and blessed Eid al-Adha.": {
        "ar": "تقبل الله منا ومنكم. أتمنى لكم ولعائلتكم عيد أضحى سعيد ومبارك.",
        "bn": "তাকাব্বালাল্লাহু মিন্না ওয়া মিনকুম। আপনাকে ও আপনার পরিবারকে আনন্দময় ও বরকতপূর্ণ ঈদুল আযহার শুভেচ্ছা।",
        "fa": "تقبل الله منا و منکم. عید قربان شاد و مبارکی برای شما و خانواده‌تان آرزومندم.",
        "fr": "Taqabbal Allahu minna wa minkum. Je vous souhaite à vous et votre famille un joyeux et béni Aïd al-Adha.",
        "id": "Taqabbalallahu minna wa minkum. Semoga Idul Adha ini penuh kebahagiaan dan berkah untuk Anda sekeluarga.",
        "ms": "Taqabbalallahu minna wa minkum. Semoga Hari Raya Haji ini penuh kebahagiaan dan keberkatan untuk anda sekeluarga.",
        "tr": "Taqabbalallahu minna wa minkum. Size ve ailenize neşeli ve mübarek bir Kurban Bayramı diliyorum.",
        "ur": "تقبل اللہ منا و منکم۔ آپ اور آپ کے خاندان کو خوشگوار اور مبارک عید الاضحیٰ کی دعا۔",
    },
}

ALL_TRANSLATIONS = {}
ALL_TRANSLATIONS.update(FIX1_TRANSLATIONS)
ALL_TRANSLATIONS.update(FIX2_TRANSLATIONS)
ALL_TRANSLATIONS.update(FIX3_TRANSLATIONS)
ALL_TRANSLATIONS.update(FIX4_GRACE_TRANSLATIONS)
ALL_TRANSLATIONS.update(FIX5_SHARE_TRANSLATIONS)

# Keys that are expected to be new (don't already exist in the catalog).
# "Remember to %@" already exists — excluded from this set so it merges, not adds.
ALLOWED_NEW_KEYS = (
    set(FIX2_TRANSLATIONS.keys())
    | set(FIX3_TRANSLATIONS.keys())
    | set(FIX4_GRACE_TRANSLATIONS.keys())
    | set(FIX5_SHARE_TRANSLATIONS.keys())
) - {
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

    # ── Write to temp file first, validate, then atomic replace ──────────
    temp_path = XCSTRINGS_PATH.with_suffix(".xcstrings.tmp")
    print(f"Writing temp file {temp_path}...")
    with open(temp_path, "w", encoding="utf-8") as f:
        f.write(output)

    # ── Post-write validation (on temp file — original is untouched) ─────
    print("Running post-write validation...")

    # 1. Re-parse as valid JSON
    with open(temp_path, "r", encoding="utf-8") as f:
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

    # ── All validations passed — atomic replace ──────────────────────────
    print(f"\nAll validations passed. Replacing {XCSTRINGS_PATH}...")
    os.replace(temp_path, XCSTRINGS_PATH)

    print("Done!")
    print(f"  Total keys in catalog: {len(post_keys)}")
    print(f"  Keys modified/added: {len(ALL_TRANSLATIONS)}")


if __name__ == "__main__":
    try:
        main()
    except Exception as e:
        # Clean up temp file on failure
        temp_path = XCSTRINGS_PATH.with_suffix(".xcstrings.tmp")
        if temp_path.exists():
            temp_path.unlink()
            print(f"  Rolled back: temp file removed, original untouched.", file=sys.stderr)
        print(f"\nERROR: {e}", file=sys.stderr)
        sys.exit(1)
