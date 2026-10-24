// ═══════════════════════════════════════════════════════════════════════════
// VEX Health — کاتەکانی بانگ (فایلی تەواو)
//
// هەمووی لەم فایلەدایە:
//   1) دەقەکان بە 6 زمان (سۆرانی، بادینی، English، عربي، فارسی، Türkçe)
//   2) ژماردنی کاتەکان (Muslim World League · فەجر 18° · عیشا 17° · عەسری شافیعی) — بێ ئینتەرنێت
//   3) شوێن تەنها بە GPS (هیچ لیستی شار نییە) + ناوی شوێن
//   4) ئەنجن: هەر بانگێک → لە کاتی بانگ یان 5 / 10 / 15 خولەک پێش بانگ، جۆری لەرینەوە، لە کاتی بانگیش
//   5) لەرینەوە کاتێک ئەپ داخراوە:
//        • کاتژمێری ناو Band خۆی (فرمانی 0x23 ی SDK) ← Band خۆی دەلەرێتەوە بێ مۆبایل و بێ ئەپ
//        • ئاگادارکردنەوەی خشتەکراوی سیستەم (exact alarm) لەگەڵ لەرینەوەی مۆبایل
//      کاتێک ئەپ کراوەیە: پەنجەرەی لەرین + لەرینی Band (find) + لەرینی مۆبایل
//   6) کارتی سەرەکی (PrayerCard) و پەڕەی ڕێکخستن (openPrayerPage)
//
// دانان:
//   main.dart        → await VexPrayer.I.init();   (دوای VexBand.I.init)
//   home_screen.dart → PrayerCard() لە ژێر WaterCard()
// ═══════════════════════════════════════════════════════════════════════════
import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../band/ble/vex_ble.dart';
import '../band/ble/vex_frame.dart';
import '../core/theme.dart';
import '../onboarding/reg_lang_state.dart';

// ───────────────────────────────────────────────────────────────────────────
// 1) دەقەکان
// ───────────────────────────────────────────────────────────────────────────
const List<String> kPrayFive = ['fajr', 'dhuhr', 'asr', 'maghrib', 'isha'];
const List<String> kPraySix = ['fajr', 'sunrise', 'dhuhr', 'asr', 'maghrib', 'isha'];

/// هەڵبژاردەکانی «پێش بانگ» (خولەک). 0 = لە کاتی بانگ
const List<int> kPrayLeads = [0, 5, 10, 15];
const List<String> kPrayPats = ['short', 'long', 'triple'];

const Map<String, Map<String, String>> _tx = {
  'ckb': {
    'next': 'بانگی داهاتوو', 'left': 'ماوە', 'title': 'کاتەکانی بانگ',
    'master': 'لەرینەوەی Band بۆ بانگ', 'mOn': 'هەر بانگێک بە ڕێکخستنی خۆی', 'mOff': 'کوژاوە · بۆ هەڵکردن دەستی لێبدە',
    'loc': 'شوێن', 'here': 'شوێنی ئێستا', 'notConn': 'GPS کۆنێکت نەکراوە', 'hint': 'کۆنێکت بکە بۆ کاتی وردی شوێنی خۆت',
    'connect': 'کۆنێکت', 'refresh': 'نوێکردنەوە', 'locating': 'دۆزینەوە…',
    'prayers': 'بانگەکان', 'before': 'ئاگادارکردنەوە پێش بانگ', 'min': 'خولەک', 'vt': 'جۆری لەرینەوە',
    'alsoAt': 'لە کاتی بانگیش بلەرێتەوە', 'test': 'تاقیکردنەوەی لەرینەوە',
    'method': 'ڕێگای Muslim World League (فەجر 18° · عیشا 17°) · عەسری شافیعی',
    'back': 'گەڕانەوە', 'stop': 'ڕاگرتن', 'off': 'لەرینەوە کوژاوە', 'info': 'تەنها زانیاری', 'at': 'لە کاتی بانگ',
    'tNext': 'داهاتوو', 'tTom': 'سبەی', 'tPast': 'تێپەڕی', 'tToday': 'ئەمڕۆ',
    'noGeo': 'شوێن بەردەست نییە', 'geoNo': 'ڕێپێدانی شوێن نەدرا', 'gpsOff': 'GPS ی مۆبایل کوژاوە',
    'bandOk': 'Band ئامادەیە · بێ ئەپیش دەلەرێتەوە', 'bandNo': 'Band پەیوەست نییە · کاتێک پەیوەست بوو خۆی ڕێکدەخرێت',
    'short': 'کورت', 'long': 'درێژ', 'triple': 'سێ جار',
    'fajr': 'بەیانی', 'sunrise': 'خۆرهەڵات', 'dhuhr': 'نیوەڕۆ', 'asr': 'عەسر', 'maghrib': 'ئێوارە', 'isha': 'خەوتنان',
  },
  'kmr': {
    'next': 'بانگا بێت', 'left': 'مایە', 'title': 'دەمێن بانگێ',
    'master': 'لەرزینا Band بۆ بانگێ', 'mOn': 'هەر بانگەک ب ڕێکخستنا خۆ', 'mOff': 'ڤەمراندییە · بۆ ڤەکرنێ ل سەر بدە',
    'loc': 'جه', 'here': 'جهێ نوکە', 'notConn': 'GPS نەهاتییە گرێدان', 'hint': 'گرێبدە بۆ دەمێن دروست یێن جهێ تە',
    'connect': 'گرێدان', 'refresh': 'نووکرن', 'locating': 'دیتن…',
    'prayers': 'بانگ', 'before': 'ئاگەهداری بەری بانگێ', 'min': 'دەقە', 'vt': 'جۆرێ لەرزینێ',
    'alsoAt': 'د دەمێ بانگێ ژی بلەرزیت', 'test': 'تاقیکرنا لەرزینێ',
    'method': 'ڕێکا Muslim World League (فەجر 18° · عیشا 17°) · عەسرا شافیعی',
    'back': 'زڤڕین', 'stop': 'ڕاگرتن', 'off': 'لەرزین ڤەمراندییە', 'info': 'تنێ زانیاری', 'at': 'د دەمێ بانگێ دا',
    'tNext': 'یا بێت', 'tTom': 'سوبەهی', 'tPast': 'بۆری', 'tToday': 'ئەڤرۆ',
    'noGeo': 'جه بەردەست نینە', 'geoNo': 'دەستووریا جهی نەهاتە دان', 'gpsOff': 'GPS یا مۆبایلێ ڤەمراندییە',
    'bandOk': 'Band ئامادەیە · بێی ئەپێ ژی دلەرزیت', 'bandNo': 'Band نە گرێدایە · دەمێ گرێدای خۆ ڕێکدئێخیت',
    'short': 'کورت', 'long': 'درێژ', 'triple': 'سێ جاران',
    'fajr': 'سپێدە', 'sunrise': 'ڕۆژهەلات', 'dhuhr': 'نیڤرۆ', 'asr': 'عەسر', 'maghrib': 'ئێڤار', 'isha': 'عیشا',
  },
  'en': {
    'next': 'Next prayer', 'left': 'left', 'title': 'Prayer times',
    'master': 'Band vibration for prayers', 'mOn': 'Each prayer with its own settings', 'mOff': 'Off · tap to turn on',
    'loc': 'Location', 'here': 'Current location', 'notConn': 'GPS not connected', 'hint': 'Connect to get exact times for where you are',
    'connect': 'Connect', 'refresh': 'Refresh', 'locating': 'Locating…',
    'prayers': 'Prayers', 'before': 'Alert before the adhan', 'min': 'min', 'vt': 'Vibration type',
    'alsoAt': 'Also vibrate at the adhan', 'test': 'Test vibration',
    'method': "Muslim World League method (Fajr 18° · Isha 17°) · Shafi'i Asr",
    'back': 'Back', 'stop': 'Stop', 'off': 'Vibration off', 'info': 'Info only', 'at': 'At the adhan',
    'tNext': 'Next', 'tTom': 'Tomorrow', 'tPast': 'Passed', 'tToday': 'Today',
    'noGeo': 'Location unavailable', 'geoNo': 'Location permission denied', 'gpsOff': 'Phone location is off',
    'bandOk': 'Band ready · vibrates even with the app closed', 'bandNo': 'Band not connected · set up automatically when it connects',
    'short': 'Short', 'long': 'Long', 'triple': '3 times',
    'fajr': 'Fajr', 'sunrise': 'Sunrise', 'dhuhr': 'Dhuhr', 'asr': 'Asr', 'maghrib': 'Maghrib', 'isha': 'Isha',
  },
  'ar': {
    'next': 'الأذان القادم', 'left': 'متبقٍ', 'title': 'أوقات الصلاة',
    'master': 'اهتزاز Band للأذان', 'mOn': 'لكل أذان إعداداته الخاصة', 'mOff': 'متوقف · اضغط للتشغيل',
    'loc': 'الموقع', 'here': 'الموقع الحالي', 'notConn': 'GPS غير متصل', 'hint': 'اتصل للحصول على أوقات دقيقة لموقعك',
    'connect': 'اتصال', 'refresh': 'تحديث', 'locating': 'جارٍ التحديد…',
    'prayers': 'الصلوات', 'before': 'تنبيه قبل الأذان', 'min': 'دقيقة', 'vt': 'نوع الاهتزاز',
    'alsoAt': 'اهتز أيضاً عند الأذان', 'test': 'اختبار الاهتزاز',
    'method': 'طريقة رابطة العالم الإسلامي (الفجر 18° · العشاء 17°) · العصر الشافعي',
    'back': 'رجوع', 'stop': 'إيقاف', 'off': 'الاهتزاز متوقف', 'info': 'للمعلومات فقط', 'at': 'عند الأذان',
    'tNext': 'التالي', 'tTom': 'غداً', 'tPast': 'مضى', 'tToday': 'اليوم',
    'noGeo': 'الموقع غير متاح', 'geoNo': 'رُفض إذن الموقع', 'gpsOff': 'خدمة الموقع متوقفة',
    'bandOk': 'Band جاهز · يهتز حتى والتطبيق مغلق', 'bandNo': 'Band غير متصل · يُضبط تلقائياً عند الاتصال',
    'short': 'قصير', 'long': 'طويل', 'triple': '3 مرات',
    'fajr': 'الفجر', 'sunrise': 'الشروق', 'dhuhr': 'الظهر', 'asr': 'العصر', 'maghrib': 'المغرب', 'isha': 'العشاء',
  },
  'fa': {
    'next': 'اذان بعدی', 'left': 'مانده', 'title': 'اوقات نماز',
    'master': 'لرزش Band برای اذان', 'mOn': 'هر اذان با تنظیمات خودش', 'mOff': 'خاموش · برای روشن کردن بزنید',
    'loc': 'موقعیت', 'here': 'موقعیت فعلی', 'notConn': 'GPS متصل نیست', 'hint': 'برای اوقات دقیق موقعیت خود متصل شوید',
    'connect': 'اتصال', 'refresh': 'به‌روزرسانی', 'locating': 'در حال یافتن…',
    'prayers': 'نمازها', 'before': 'هشدار پیش از اذان', 'min': 'دقیقه', 'vt': 'نوع لرزش',
    'alsoAt': 'هنگام اذان هم بلرزد', 'test': 'آزمایش لرزش',
    'method': 'روش اتحادیه جهان اسلام (فجر 18° · عشاء 17°) · عصر شافعی',
    'back': 'بازگشت', 'stop': 'توقف', 'off': 'لرزش خاموش است', 'info': 'فقط اطلاعات', 'at': 'هنگام اذان',
    'tNext': 'بعدی', 'tTom': 'فردا', 'tPast': 'گذشت', 'tToday': 'امروز',
    'noGeo': 'موقعیت در دسترس نیست', 'geoNo': 'اجازهٔ موقعیت داده نشد', 'gpsOff': 'موقعیت‌یاب گوشی خاموش است',
    'bandOk': 'Band آماده است · حتی با برنامهٔ بسته می‌لرزد', 'bandNo': 'Band متصل نیست · هنگام اتصال خودکار تنظیم می‌شود',
    'short': 'کوتاه', 'long': 'بلند', 'triple': '3 بار',
    'fajr': 'صبح', 'sunrise': 'طلوع آفتاب', 'dhuhr': 'ظهر', 'asr': 'عصر', 'maghrib': 'مغرب', 'isha': 'عشاء',
  },
  'tr': {
    'next': 'Sıradaki vakit', 'left': 'kaldı', 'title': 'Namaz vakitleri',
    'master': 'Ezan için Band titreşimi', 'mOn': 'Her vakit kendi ayarıyla', 'mOff': 'Kapalı · açmak için dokun',
    'loc': 'Konum', 'here': 'Mevcut konum', 'notConn': 'GPS bağlı değil', 'hint': 'Bulunduğun yerin tam vakitleri için bağlan',
    'connect': 'Bağlan', 'refresh': 'Yenile', 'locating': 'Bulunuyor…',
    'prayers': 'Vakitler', 'before': 'Ezandan önce uyarı', 'min': 'dk', 'vt': 'Titreşim türü',
    'alsoAt': 'Ezan vaktinde de titreşsin', 'test': 'Titreşimi test et',
    'method': 'Müslüman Dünya Birliği yöntemi (İmsak 18° · Yatsı 17°) · Şafii ikindi',
    'back': 'Geri', 'stop': 'Durdur', 'off': 'Titreşim kapalı', 'info': 'Yalnızca bilgi', 'at': 'Ezan vaktinde',
    'tNext': 'Sıradaki', 'tTom': 'Yarın', 'tPast': 'Geçti', 'tToday': 'Bugün',
    'noGeo': 'Konum kullanılamıyor', 'geoNo': 'Konum izni verilmedi', 'gpsOff': 'Telefonun konumu kapalı',
    'bandOk': 'Band hazır · uygulama kapalıyken de titrer', 'bandNo': 'Band bağlı değil · bağlanınca otomatik ayarlanır',
    'short': 'Kısa', 'long': 'Uzun', 'triple': '3 kez',
    'fajr': 'İmsak', 'sunrise': 'Güneş', 'dhuhr': 'Öğle', 'asr': 'İkindi', 'maghrib': 'Akşam', 'isha': 'Yatsı',
  },
};

String get _lg => _tx.containsKey(LangState.I.code) ? LangState.I.code : 'ckb';
bool get _rtl => _lg != 'en' && _lg != 'tr';
TextDirection get _dir => _rtl ? TextDirection.rtl : TextDirection.ltr;

/// دەقی وەرگێڕدراو
String pt(String k) => _tx[_lg]![k] ?? _tx['ckb']![k] ?? k;

/// ناوی نوێژ
String prayName(String k) => pt(k);

/// «بانگی عەسر»
String _adhan(String n) => switch (_lg) {
      'kmr' => 'بانگا $n',
      'en' => '$n adhan',
      'ar' => 'أذان $n',
      'fa' => 'اذان $n',
      'tr' => '$n ezanı',
      _ => 'بانگی $n',
    };

/// «کاتی بانگی عەسر هات»
String _nowTx(String n) => switch (_lg) {
      'kmr' => 'دەمێ بانگا $n هات',
      'en' => 'Time for $n',
      'ar' => 'حان وقت $n',
      'fa' => 'وقت اذان $n',
      'tr' => '$n vakti geldi',
      _ => 'کاتی بانگی $n',
    };

/// «10 خولەک پێش بانگ» یان «لە کاتی بانگ»
String prayWhen(int m) {
  if (m <= 0) return pt('at');
  return switch (_lg) {
    'kmr' => '$m دەقە بەری بانگێ',
    'en' => '$m min before the adhan',
    'ar' => 'قبل الأذان بـ$m ${m <= 10 ? 'دقائق' : 'دقيقة'}',
    'fa' => '$m دقیقه پیش از اذان',
    'tr' => 'Ezandan $m dk önce',
    _ => '$m خولەک پێش بانگ',
  };
}

const Map<String, List<String>> _days = {
  'ckb': ['یەکشەممە', 'دووشەممە', 'سێشەممە', 'چوارشەممە', 'پێنجشەممە', 'هەینی', 'شەممە'],
  'kmr': ['یەکشەمب', 'دووشەمب', 'سێشەمب', 'چارشەمب', 'پێنجشەمب', 'ئەینی', 'شەمبی'],
  'en': ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'],
  'ar': ['الأحد', 'الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت'],
  'fa': ['یکشنبه', 'دوشنبه', 'سه‌شنبه', 'چهارشنبه', 'پنجشنبه', 'جمعه', 'شنبه'],
  'tr': ['Pazar', 'Pazartesi', 'Salı', 'Çarşamba', 'Perşembe', 'Cuma', 'Cumartesi'],
};
const Map<String, List<String>> _months = {
  'ckb': ['کانوونی دووەم', 'شوبات', 'ئازار', 'نیسان', 'ئایار', 'حوزەیران', 'تەممووز', 'ئاب', 'ئەیلوول', 'تشرینی یەکەم', 'تشرینی دووەم', 'کانوونی یەکەم'],
  'kmr': ['کانوونا دووێ', 'شوبات', 'ئادار', 'نیسان', 'گولان', 'حزیران', 'تیرمەه', 'تەباخ', 'ئیلون', 'چریا ئێکێ', 'چریا دووێ', 'کانوونا ئێکێ'],
  'en': ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'],
  'ar': ['كانون الثاني', 'شباط', 'آذار', 'نيسان', 'أيار', 'حزيران', 'تموز', 'آب', 'أيلول', 'تشرين الأول', 'تشرين الثاني', 'كانون الأول'],
  'fa': ['ژانویه', 'فوریه', 'مارس', 'آوریل', 'مه', 'ژوئن', 'ژوئیه', 'اوت', 'سپتامبر', 'اکتبر', 'نوامبر', 'دسامبر'],
  'tr': ['Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran', 'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'],
};

String _dateTx(DateTime d) {
  final day = _days[_lg]![d.weekday % 7];
  final mo = _months[_lg]![d.month - 1];
  return switch (_lg) {
    'ckb' => '$day، ${d.day}ی $mo',
    'kmr' => '$day، ${d.day}ێ $mo',
    'en' => '$day ${d.day} $mo',
    'tr' => '${d.day} $mo $day',
    _ => '$day، ${d.day} $mo',
  };
}

String _p2(int n) => n.toString().padLeft(2, '0');

/// خولەک (0..1439) ← «2:52» و «PM»
({String t, String a}) h12(int mins) {
  final h = (mins ~/ 60) % 24, m = mins % 60;
  return (t: '${(h + 11) % 12 + 1}:${_p2(m)}', a: h < 12 ? 'AM' : 'PM');
}

String _cd(int s) {
  final h = s ~/ 3600, m = (s % 3600) ~/ 60, c = s % 60;
  return h > 0 ? '$h:${_p2(m)}:${_p2(c)}' : '$m:${_p2(c)}';
}

String _clock(DateTime d) {
  final x = h12(d.hour * 60 + d.minute);
  return '${x.t}:${_p2(d.second)} ${x.a}';
}

String _coord(double a, double b) =>
    '${a.abs().toStringAsFixed(2)}°${a >= 0 ? 'N' : 'S'}  ${b.abs().toStringAsFixed(2)}°${b >= 0 ? 'E' : 'W'}';

// ───────────────────────────────────────────────────────────────────────────
// 2) ژماردنی کاتەکان
// ───────────────────────────────────────────────────────────────────────────
class PrayCalc {
  PrayCalc._();

  // ڕێکخستنی بچووک بۆ نزیککردنەوە لە IslamicFinder (خولەک)
  static const Map<String, double> _off = {
    'fajr': 1.4, 'sunrise': -0.5, 'dhuhr': 0.6, 'asr': 0.2, 'maghrib': 1.55, 'isha': 0.3,
  };
  static const double _r = math.pi / 180;
  static double _sin(double d) => math.sin(d * _r);
  static double _cos(double d) => math.cos(d * _r);
  static double _tan(double d) => math.tan(d * _r);
  static double _asin(double x) => math.asin(x.clamp(-1.0, 1.0)) / _r;
  static double _acos(double x) => math.acos(x.clamp(-1.0, 1.0)) / _r;
  static double _acot(double x) => math.atan(1 / x) / _r;
  static double _fix(double a, double b) => a - b * (a / b).floorToDouble();

  /// کاتەکان وەک خولەک لە نیوەشەوی ناوخۆییەوە (0..1439)
  static Map<String, int> compute(DateTime date, double lat, double lng) {
    final zone = date.timeZoneOffset.inMinutes / 60.0;
    var y = date.year, m = date.month;
    final d = date.day;
    if (m <= 2) {
      y--;
      m += 12;
    }
    final a = (y / 100).floor();
    final b = 2 - a + (a / 4).floor();
    final jd = (365.25 * (y + 4716)).floorToDouble() + (30.6001 * (m + 1)).floorToDouble() + d + b - 1524.5 - lng / (15 * 24);

    ({double dec, double eq}) sp(double j) {
      final dd = j - 2451545;
      final g = _fix(357.529 + 0.98560028 * dd, 360);
      final q = _fix(280.459 + 0.98564736 * dd, 360);
      final l = _fix(q + 1.915 * _sin(g) + 0.020 * _sin(2 * g), 360);
      final e = 23.439 - 0.00000036 * dd;
      final ra = math.atan2(_cos(e) * _sin(l), _cos(l)) / _r / 15;
      return (dec: _asin(_sin(e) * _sin(l)), eq: q / 15 - _fix(ra, 24));
    }

    final s0 = sp(jd + 0.5);
    final noon = _fix(12 - s0.eq, 24) - lng / 15 + zone;

    double ang(double angle, bool rising) {
      var tt = noon;
      for (var i = 0; i < 2; i++) {
        final s = sp(jd + (tt - zone + lng / 15) / 24);
        final h = _acos((-_sin(angle) - _sin(s.dec) * _sin(lat)) / (_cos(s.dec) * _cos(lat))) / 15;
        tt = noon + (rising ? -h : h);
      }
      return tt;
    }

    double asr() {
      final s = sp(jd + 0.5);
      final aa = -_acot(1 + _tan((lat - s.dec).abs()));
      final h = _acos((-_sin(aa) - _sin(s.dec) * _sin(lat)) / (_cos(s.dec) * _cos(lat))) / 15;
      return noon + h;
    }

    const hz = 0.833;
    final raw = <String, double>{
      'fajr': ang(18, true),
      'sunrise': ang(hz, true),
      'dhuhr': noon + 1 / 60,
      'asr': asr(),
      'maghrib': ang(hz, false),
      'isha': ang(17, false),
    };
    final out = <String, int>{};
    raw.forEach((k, v) {
      final mins = (v * 60 + (_off[k] ?? 0)).round();
      out[k] = ((mins % 1440) + 1440) % 1440;
    });
    return out;
  }
}

// ───────────────────────────────────────────────────────────────────────────
// 3) ڕێکخستنی هەر بانگێک
// ───────────────────────────────────────────────────────────────────────────
class PrayCfg {
  PrayCfg({this.lead = 0, this.pat = 'short', this.at = true});

  /// 0 / 5 / 10 / 15 خولەک پێش بانگ
  int lead;
  String pat;

  /// ئەگەر lead > 0: لە کاتی بانگیش بلەرێتەوە
  bool at;

  Map<String, Object> toJson() => {'lead': lead, 'pat': pat, 'at': at};

  static int snap(num v) {
    var b = 0;
    for (final x in kPrayLeads) {
      if ((x - v).abs() < (b - v).abs()) b = x;
    }
    return b;
  }

  factory PrayCfg.fromJson(Map j) => PrayCfg(
        lead: snap((j['lead'] ?? j['min'] ?? 0) as num),
        pat: kPrayPats.contains(j['pat']) ? j['pat'] as String : 'short',
        at: j['at'] != false && j['at'] != 0,
      );
}

/// دۆخی ئێستا (بۆ کارت و پەڕە)
class PrayState {
  const PrayState({
    required this.now, required this.nm, required this.t, required this.next,
    required this.nextAt, required this.tomorrow, required this.phase, required this.left, required this.sun,
  });
  final DateTime now;
  final double nm; // خولەکی ئێستا
  final Map<String, int> t;
  final String next;
  final int nextAt;
  final bool tomorrow;
  final String phase; // night/dawn/morning/noon/asr/sunset/dusk
  final int left; // چرکە
  final double sun; // 0 خۆرهەڵات … 1 خۆرئاوا

  bool passed(String k) => tomorrow ? k != 'fajr' : t[k]! <= nm;
}

// ───────────────────────────────────────────────────────────────────────────
// 4) ئەنجن
// ───────────────────────────────────────────────────────────────────────────
class VexPrayer extends ChangeNotifier with WidgetsBindingObserver {
  VexPrayer._();
  static final VexPrayer I = VexPrayer._();

  static const String _key = 'vex_prayer_v2';
  static const String _bandKey = 'vex_prayer_band_sig';
  static const int _idBase = 1700000000; // ئایدی ئاگادارکردنەوەکان (جیا لە BandAlerts)
  static const int _idSpan = 140; // 7 ڕۆژ × 20

  /// تەنها تا GPS کۆنێکت دەکرێت (هیچ کات وەک ناوی شوێن نیشان نادرێت)
  static const double _fbLat = 36.19, _fbLng = 44.01;

  // ── دۆخ ──
  bool on = false;
  final Map<String, bool> items = {for (final k in kPrayFive) k: true};
  final Map<String, PrayCfg> cfg = {for (final k in kPrayFive) k: PrayCfg()};
  double? lat, lng;
  String? placeName;
  int fixAt = 0;
  bool locating = false;

  /// هەر چرکەیەک +1 (بۆ کاتژمێر و ژمێرەری کارت)
  final ValueNotifier<int> clock = ValueNotifier<int>(0);

  final FlutterLocalNotificationsPlugin _np = FlutterLocalNotificationsPlugin();
  SharedPreferences? _sp;
  Timer? _tick, _deb;
  bool _ready = false;
  bool _wasLinked = false;
  String _bandSig = '';
  final Set<String> _fired = {};
  final Map<String, Map<String, int>> _cache = {};

  bool get hasGps => lat != null && lng != null;
  bool get bandLinked => VexBand.I.linked;
  PrayCfg cfgOf(String k) => cfg[k] ??= PrayCfg();

  // ── دەستپێکردن ──
  Future<void> init() async {
    if (_ready) return;
    try {
      _sp = await SharedPreferences.getInstance();
      final raw = _sp!.getString(_key);
      if (raw != null) {
        _fromJson(jsonDecode(raw) as Map);
      } else {
        _migrate();
      }
      _bandSig = _sp!.getString(_bandKey) ?? '';
    } catch (e) {
      if (kDebugMode) debugPrint('VexPrayer.load: $e');
    }
    await _initNotify();
    _ready = true;
    WidgetsBinding.instance.addObserver(this);
    _wasLinked = VexBand.I.linked;
    VexBand.I.addListener(_onBand);
    LangState.I.addListener(_onLang);
    _tick = Timer.periodic(const Duration(seconds: 1), (_) => _onTick());
    _schedule();
    unawaited(_refreshGpsQuietly());
  }

  void _fromJson(Map j) {
    on = j['on'] == true;
    final it = (j['items'] ?? const {}) as Map;
    for (final k in kPrayFive) {
      items[k] = it[k] != false && it[k] != 0;
    }
    final c = (j['cfg'] ?? const {}) as Map;
    for (final k in kPrayFive) {
      if (c[k] is Map) cfg[k] = PrayCfg.fromJson(c[k] as Map);
    }
    lat = (j['lat'] as num?)?.toDouble();
    lng = (j['lng'] as num?)?.toDouble();
    placeName = j['place'] as String?;
    fixAt = ((j['fixAt'] ?? 0) as num).toInt();
  }

  /// گواستنەوە لە ڕێکخستنی کۆنی BandAlerts (ئەگەر هەبێت)
  void _migrate() {
    try {
      final old = _sp?.getString('vex_band_alerts');
      if (old == null) return;
      final p = ((jsonDecode(old) as Map)['pray'] ?? const {}) as Map;
      on = p['on'] == true;
      if (p['city'] == 'gps') {
        lat = (p['lat'] as num?)?.toDouble();
        lng = (p['lng'] as num?)?.toDouble();
      }
      final it = (p['items'] ?? const {}) as Map;
      for (final k in kPrayFive) {
        items[k] = it[k] != false;
      }
      final lead = PrayCfg.snap((p['lead'] ?? 0) as num);
      for (final k in kPrayFive) {
        cfg[k] = PrayCfg(lead: lead);
      }
    } catch (_) {}
  }

  Future<void> _save() async {
    try {
      await _sp?.setString(
        _key,
        jsonEncode({
          'on': on,
          'items': items,
          'cfg': {for (final k in kPrayFive) k: cfgOf(k).toJson()},
          'lat': lat,
          'lng': lng,
          'place': placeName,
          'fixAt': fixAt,
        }),
      );
    } catch (_) {}
  }

  /// دوای هەر گۆڕانکارییەک
  void changed() {
    notifyListeners();
    unawaited(_save());
    _schedule();
  }

  void setOn(bool v) {
    on = v;
    if (v) unawaited(ensurePermissions());
    changed();
  }

  void toggle(String k) {
    if (!on) {
      on = true;
      items[k] = true;
      unawaited(ensurePermissions());
    } else {
      items[k] = !(items[k] ?? false);
    }
    changed();
  }

  void setLead(String k, int m) {
    cfgOf(k).lead = PrayCfg.snap(m);
    changed();
  }

  void setPat(String k, String p) {
    cfgOf(k).pat = p;
    buzz(p);
    changed();
  }

  void setAt(String k, bool v) {
    cfgOf(k).at = v;
    changed();
  }

  // ── کاتەکان ──
  Map<String, int> times(DateTime d) {
    final la = lat ?? _fbLat, lo = lng ?? _fbLng;
    final key = '${d.year}-${d.month}-${d.day}|$la,$lo';
    final hit = _cache[key];
    if (hit != null) return hit;
    if (_cache.length > 40) _cache.clear();
    return _cache[key] = PrayCalc.compute(DateTime(d.year, d.month, d.day, 12), la, lo);
  }

  PrayState state([DateTime? at]) {
    final now = at ?? DateTime.now();
    final nm = now.hour * 60 + now.minute + now.second / 60.0;
    final t = times(now);
    var next = 'fajr';
    var nextAt = -1;
    var tom = false;
    for (final k in kPrayFive) {
      if (t[k]! > nm) {
        next = k;
        nextAt = t[k]!;
        break;
      }
    }
    if (nextAt < 0) {
      tom = true;
      nextAt = times(DateTime(now.year, now.month, now.day + 1)).fajr;
    }
    var ph = 'night';
    if (nm < t['fajr']!) {
      ph = 'night';
    } else if (nm < t['sunrise']!) {
      ph = 'dawn';
    } else if (nm < t['dhuhr']!) {
      ph = 'morning';
    } else if (nm < t['asr']!) {
      ph = 'noon';
    } else if (nm < t['maghrib']! - 40) {
      ph = 'asr';
    } else if (nm < t['maghrib']!) {
      ph = 'sunset';
    } else if (nm < t['isha']!) {
      ph = 'dusk';
    }
    final base = DateTime(now.year, now.month, now.day + (tom ? 1 : 0));
    final tgt = base.add(Duration(minutes: nextAt));
    final left = math.max(0, tgt.difference(now).inSeconds);
    final sr = t['sunrise']!, ss = t['maghrib']!;
    final f = ((nm - sr) / math.max(1, ss - sr)).clamp(0.0, 1.0);
    return PrayState(now: now, nm: nm, t: t, next: next, nextAt: nextAt, tomorrow: tom, phase: ph, left: left, sun: f);
  }

  // ── GPS ──
  /// شوێنی ئێستا بە GPS. null = سەرکەوتوو، ئەگەرنا دەقی هەڵە.
  Future<String?> connectGps() async {
    if (locating) return null;
    locating = true;
    notifyListeners();
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return pt('gpsOff');
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) return pt('geoNo');
      Position? pos;
      try {
        pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.low,
          timeLimit: const Duration(seconds: 15),
        );
      } catch (_) {
        pos = await Geolocator.getLastKnownPosition();
      }
      if (pos == null) return pt('noGeo');
      await _setFix(pos.latitude, pos.longitude);
      return null;
    } catch (e) {
      if (kDebugMode) debugPrint('VexPrayer.gps: $e');
      return pt('noGeo');
    } finally {
      locating = false;
      notifyListeners();
    }
  }

  Future<void> _setFix(double la, double lo) async {
    lat = double.parse(la.toStringAsFixed(4));
    lng = double.parse(lo.toStringAsFixed(4));
    fixAt = DateTime.now().millisecondsSinceEpoch;
    _cache.clear();
    changed();
    // ناوی شوێن (بە زمانی ئامێر) — ئەگەر نەبوو، پلەکان نیشان دەدرێن
    try {
      final pm = await placemarkFromCoordinates(la, lo).timeout(const Duration(seconds: 8));
      if (pm.isNotEmpty) {
        final p = pm.first;
        final parts = <String>[
          for (final s in [p.locality, p.subAdministrativeArea, p.administrativeArea])
            if (s != null && s.trim().isNotEmpty) s.trim(),
        ];
        if (parts.isNotEmpty) {
          placeName = parts.first;
          changed();
        }
      }
    } catch (_) {}
  }

  /// ئەگەر پێشتر ڕێگە درابێت و شوێن کۆن بێت (> 6 کاتژمێر) بێدەنگ نوێ دەکرێتەوە
  Future<void> _refreshGpsQuietly() async {
    if (!hasGps) return;
    if (DateTime.now().millisecondsSinceEpoch - fixAt < 6 * 3600 * 1000) return;
    try {
      final perm = await Geolocator.checkPermission();
      if (perm != LocationPermission.always && perm != LocationPermission.whileInUse) return;
      if (!await Geolocator.isLocationServiceEnabled()) return;
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
        timeLimit: const Duration(seconds: 15),
      );
      final moved = Geolocator.distanceBetween(lat!, lng!, pos.latitude, pos.longitude);
      if (moved > 3000) {
        await _setFix(pos.latitude, pos.longitude);
      } else {
        fixAt = DateTime.now().millisecondsSinceEpoch;
        unawaited(_save());
      }
    } catch (_) {}
  }

  String get placeLabel => !hasGps ? '' : (placeName?.isNotEmpty == true ? placeName! : pt('here'));

  // ── چرکە بە چرکە ──
  String _dk(DateTime d) => '${d.year}-${d.month}-${d.day}';

  void _onTick() {
    clock.value++;
    final now = DateTime.now();
    final dk = _dk(now);
    _fired.removeWhere((x) => !x.startsWith(dk));
    if (on) {
      final t = times(now);
      final ns = now.hour * 3600 + now.minute * 60 + now.second;
      for (final k in kPrayFive) {
        if (items[k] != true) continue;
        final c = cfgOf(k);
        final adh = t[k]! * 60;
        if (c.lead > 0) {
          final at = adh - c.lead * 60;
          final id = '${dk}L$k';
          if (ns >= at && ns < at + 90 && _fired.add(id)) {
            _ring(_adhan(prayName(k)), prayWhen(c.lead), c.pat);
          }
        }
        if (c.lead == 0 || c.at) {
          final id = '${dk}A$k';
          if (ns >= adh && ns < adh + 90 && _fired.add(id)) {
            final x = h12(t[k]!);
            final pl = placeLabel;
            _ring(_nowTx(prayName(k)), '${pl.isEmpty ? '' : '$pl · '}⁦${x.t} ${x.a}⁩', c.pat);
          }
        }
      }
    }
    // هەر 10 خولەک: پشکنینی کاتژمێرەکانی Band (کاتەکان ڕۆژانە دەگۆڕێن)
    if (now.second == 7 && now.minute % 10 == 0) unawaited(_syncBand());
  }

  void _onBand() {
    final l = VexBand.I.linked;
    if (l != _wasLinked) {
      _wasLinked = l;
      notifyListeners();
      if (l) {
        // دوای پەیوەستبوون: کاتەکەی Band دادەنرێت، پاشان کاتژمێرەکان
        Future<void>.delayed(const Duration(seconds: 3), () => _syncBand(force: true));
      }
    }
  }

  void _onLang() => _schedule();

  @override
  void didChangeAppLifecycleState(AppLifecycleState s) {
    if (s == AppLifecycleState.resumed) {
      _cache.clear();
      notifyListeners();
      _schedule();
      unawaited(_refreshGpsQuietly());
    }
  }

  void _schedule() {
    if (!_ready) return;
    _deb?.cancel();
    _deb = Timer(const Duration(milliseconds: 700), () {
      unawaited(_scheduleNotifications());
      unawaited(_syncBand());
    });
  }

  // ── لەرینەوە ──
  static const Map<String, List<int>> _patMs = {
    'short': [0, 450],
    'long': [0, 1300],
    'triple': [0, 320, 180, 320, 180, 320],
  };

  /// لەرینی مۆبایل + Band بەپێی جۆر
  Future<void> buzz(String pat) async {
    final n = pat == 'triple' ? 3 : 1;
    for (var i = 0; i < n; i++) {
      if (pat == 'long') {
        unawaited(HapticFeedback.vibrate());
        await Future<void>.delayed(const Duration(milliseconds: 420));
        unawaited(HapticFeedback.vibrate());
        await Future<void>.delayed(const Duration(milliseconds: 420));
        unawaited(HapticFeedback.vibrate());
      } else {
        unawaited(HapticFeedback.heavyImpact());
      }
      if (VexBand.I.linked) {
        try {
          await VexBand.I.find();
        } catch (_) {}
      }
      if (i < n - 1) await Future<void>.delayed(const Duration(milliseconds: 520));
    }
  }

  bool _ringing = false;

  void test(String k) {
    final c = cfgOf(k);
    _ring(_adhan(prayName(k)), prayWhen(c.lead), c.pat, test: true);
  }

  void _ring(String title, String sub, String pat, {bool test = false}) {
    final ctx = navKey.currentContext;
    unawaited(buzz(pat));
    if (ctx == null || _ringing) return;
    _ringing = true;
    final rep = Timer.periodic(const Duration(milliseconds: 2600), (_) => buzz(pat));
    final auto = Timer(Duration(seconds: test ? 6 : 45), () {
      final nav = navKey.currentState;
      if (_ringing && nav != null && nav.canPop()) nav.pop();
    });
    showGeneralDialog<void>(
      context: ctx,
      barrierDismissible: false,
      barrierColor: const Color(0xD1040A18),
      transitionDuration: const Duration(milliseconds: 320),
      pageBuilder: (c, a1, a2) => _RingView(title: title, sub: sub),
      transitionBuilder: (c, a, b, child) => FadeTransition(
        opacity: a,
        child: ScaleTransition(scale: Tween(begin: 0.9, end: 1.0).animate(CurvedAnimation(parent: a, curve: Curves.easeOutBack)), child: child),
      ),
    ).whenComplete(() {
      rep.cancel();
      auto.cancel();
      _ringing = false;
    });
  }

  // ── مۆڵەتەکان ──
  Future<void> ensurePermissions() async {
    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        await Permission.notification.request();
        if (await Permission.scheduleExactAlarm.isDenied) await Permission.scheduleExactAlarm.request();
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        await _np
            .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
            ?.requestPermissions(alert: true, sound: true, badge: false);
      }
    } catch (_) {}
  }

  // ── ئاگادارکردنەوەی سیستەم (کاتێک ئەپ داخراوە) ──
  Future<void> _initNotify() async {
    try {
      tzdata.initializeTimeZones();
      await _np.initialize(const InitializationSettings(
        android: AndroidInitializationSettings('ic_stat_steps'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestSoundPermission: false,
          requestBadgePermission: false,
        ),
      ));
    } catch (e) {
      if (kDebugMode) debugPrint('VexPrayer.notify: $e');
    }
  }

  NotificationDetails _details(String pat) => NotificationDetails(
        android: AndroidNotificationDetails(
          'vex_pray_$pat',
          '${pt('title')} · ${pt(pat)}',
          channelDescription: pt('master'),
          importance: Importance.max,
          priority: Priority.high,
          category: AndroidNotificationCategory.alarm,
          enableVibration: true,
          vibrationPattern: Int64List.fromList(_patMs[pat] ?? _patMs['short']!),
          playSound: true,
          icon: 'ic_stat_steps',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentSound: true,
          interruptionLevel: InterruptionLevel.timeSensitive,
        ),
      );

  Future<void> _scheduleNotifications() async {
    try {
      for (var i = 0; i < _idSpan; i++) {
        await _np.cancel(_idBase + i);
      }
      if (!on) return;
      final now = DateTime.now();
      final days = defaultTargetPlatform == TargetPlatform.iOS ? 3 : 7;
      final pl = placeLabel;
      for (var d = 0; d < days; d++) {
        final day = DateTime(now.year, now.month, now.day + d);
        final t = times(day);
        for (var i = 0; i < kPrayFive.length; i++) {
          final k = kPrayFive[i];
          if (items[k] != true) continue;
          final c = cfgOf(k);
          final x = h12(t[k]!);
          final adh = day.add(Duration(minutes: t[k]!));
          final jobs = <({int id, DateTime at, String title, String body})>[
            if (c.lead > 0)
              (id: _idBase + d * 20 + i * 2, at: adh.subtract(Duration(minutes: c.lead)), title: '🕌 ${_adhan(prayName(k))}', body: prayWhen(c.lead)),
            if (c.lead == 0 || c.at)
              (id: _idBase + d * 20 + i * 2 + 1, at: adh, title: '🕌 ${_nowTx(prayName(k))}', body: '${pl.isEmpty ? '' : '$pl · '}${x.t} ${x.a}'),
          ];
          for (final j in jobs) {
            if (!j.at.isAfter(now)) continue;
            final when = tz.TZDateTime.from(j.at, tz.UTC);
            try {
              await _np.zonedSchedule(j.id, j.title, j.body, when, _details(c.pat),
                  androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
                  uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime);
            } catch (_) {
              // ئەگەر ڕێگەی «کاتژمێری ورد» نەدرابێت
              await _np.zonedSchedule(j.id, j.title, j.body, when, _details(c.pat),
                  androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
                  uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime);
            }
          }
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('VexPrayer.schedule: $e');
    }
  }

  // ── کاتژمێرەکانی ناو Band (کاتێک ئەپ داخراوە، Band خۆی دەلەرێتەوە) ──
  static const Map<String, String> _bandName = {
    'fajr': 'Fajr', 'dhuhr': 'Dhuhr', 'asr': 'Asr', 'maghrib': 'Maghrib', 'isha': 'Isha',
  };

  List<VexAlarm> _bandAlarms() {
    if (!on) return const [];
    final t = times(DateTime.now());
    final out = <({int m, VexAlarm a})>[];
    for (final k in kPrayFive) {
      if (items[k] != true) continue;
      final c = cfgOf(k);
      final adh = t[k]!;
      const type = 1; // کاتژمێری ئاسایی (Band دەلەرێتەوە)
      if (c.lead > 0) {
        final m = (adh - c.lead + 1440) % 1440;
        out.add((m: m, a: VexAlarm(hour: m ~/ 60, minute: m % 60, type: type, text: '${_bandName[k]} -${c.lead}m')));
      }
      if (c.lead == 0 || c.at) {
        out.add((m: adh, a: VexAlarm(hour: adh ~/ 60, minute: adh % 60, type: type, text: _bandName[k]!)));
      }
    }
    out.sort((a, b) => a.m.compareTo(b.m));
    return [for (final x in out.take(VexFrame.maxAlarms)) x.a];
  }

  bool _syncing = false;

  Future<void> _syncBand({bool force = false}) async {
    if (_syncing || !VexBand.I.linked) return;
    final list = _bandAlarms();
    final sig = list.isEmpty ? 'none' : list.map((a) => a.sig).join('|');
    if (!force && sig == _bandSig) return;
    // ئەگەر هیچ کاتێک لە Band دامان نەنابێت، کاتژمێرەکانی تری Band ناسڕینەوە
    if (list.isEmpty && (_bandSig.isEmpty || _bandSig == 'none')) return;
    _syncing = true;
    try {
      final ok = await VexBand.I.setAlarms(list);
      if (ok) {
        _bandSig = sig;
        await _sp?.setString(_bandKey, sig);
        notifyListeners();
      }
    } finally {
      _syncing = false;
    }
  }

  @override
  void dispose() {
    _tick?.cancel();
    _deb?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    VexBand.I.removeListener(_onBand);
    LangState.I.removeListener(_onLang);
    super.dispose();
  }
}

extension on Map<String, int> {
  int get fajr => this['fajr']!;
}

// ───────────────────────────────────────────────────────────────────────────
// 5) ڕەنگەکان بەپێی کاتی ڕۆژ
// ───────────────────────────────────────────────────────────────────────────
class _Ph {
  const _Ph(this.pa, this.pd, this.g, this.st);
  final Color pa; // ڕەنگی ڕووناکی (ئاڵتوونی/خۆر)
  final Color pd; // ڕەنگی تاریکی بۆ ڕووکاری ڕووناک
  final List<Color> g; // ئاسمان
  final List<double> st;
}

const Map<String, _Ph> _phases = {
  'night': _Ph(Color(0xFFF2C46D), Color(0xFF13294A), [Color(0xFF13294A), Color(0xFF0B1830)], [0, 0.78]),
  'dawn': _Ph(Color(0xFFFFD2A6), Color(0xFF5B3F86), [Color(0xFF1F2558), Color(0xFF4E3B7D), Color(0xFFC9727A), Color(0xFFF2A27C)], [0, 0.52, 0.88, 1]),
  'morning': _Ph(Color(0xFFFFE08A), Color(0xFF1D5FA8), [Color(0xFF1A56A0), Color(0xFF2F7FCB), Color(0xFFE9B979)], [0, 0.58, 1]),
  'noon': _Ph(Color(0xFFFFF1A8), Color(0xFF0F6FC2), [Color(0xFF0B5FAE), Color(0xFF1E86D9), Color(0xFF6FBDEB)], [0, 0.6, 1]),
  'asr': _Ph(Color(0xFFFFE2A0), Color(0xFF9A5212), [Color(0xFF7A3F0E), Color(0xFFB1661F), Color(0xFFE6A54A)], [0, 0.52, 1]),
  'sunset': _Ph(Color(0xFFFFD38A), Color(0xFFB23F5C), [Color(0xFF4A2366), Color(0xFFA23D68), Color(0xFFE8723A), Color(0xFFF6A646)], [0, 0.5, 0.86, 1]),
  'dusk': _Ph(Color(0xFFF5BCD6), Color(0xFF3E2C6E), [Color(0xFF191A47), Color(0xFF3A2A63), Color(0xFF8C4774)], [0, 0.55, 1]),
};
_Ph _phOf(String p) => _phases[p] ?? _phases['night']!;

LinearGradient _skyGrad(String p) {
  final x = _phOf(p);
  return LinearGradient(begin: const Alignment(-0.25, -1), end: const Alignment(0.25, 1), colors: x.g, stops: x.st);
}

bool get _light => VexTheme.I.isLight;
Color get _sa => _light ? const Color(0xFF13294A) : const Color(0xFFF2C46D); // ڕەنگی هەڵبژێردراو
Color get _sf => _light ? Colors.white : const Color(0xFF13294A); // دەق لەسەر _sa
Color get _off => _light ? const Color(0xFFC5D1DA) : const Color(0x29FFFFFF);

// ───────────────────────────────────────────────────────────────────────────
// 6) وێنەی ئاسمان (خۆر لە خۆرهەڵاتەوە بۆ خۆرئاوا، مانگ، ئەستێرە، مزگەوت)
// ───────────────────────────────────────────────────────────────────────────
class _SkyPainter extends CustomPainter {
  _SkyPainter(this.ph, this.f, this.rtl);
  final String ph;
  final double f;
  final bool rtl;

  static const List<List<double>> _stars = [
    [22, 20, 1.1], [60, 12, .8], [96, 26, 1], [134, 14, .9], [150, 44, .7], [30, 62, .8],
    [78, 52, .7], [118, 70, .6], [12, 100, .7], [160, 92, .6], [52, 92, .6],
  ];

  @override
  void paint(Canvas c, Size s) {
    final w = s.width, h = s.height;
    final night = ph == 'night', dusk = ph == 'dusk', dawn = ph == 'dawn';
    final sunUp = !(night || dusk || dawn);
    final pa = _phOf(ph).pa;
    // لە کوردی/عەرەبی خۆر لە ڕاستەوە هەڵدێت (وەک وێب)؛ لە ئینگلیزی لە چەپەوە
    double fx(double x) => rtl ? x : w - x;

    // ئەستێرە
    final so = night ? 1.0 : dusk ? .75 : dawn ? .45 : 0.0;
    if (so > 0) {
      for (final a in _stars) {
        c.drawCircle(Offset(fx(a[0] * w / 170), a[1] * h / 164), a[2],
            Paint()..color = Colors.white.withValues(alpha: (so * (.45 + (a[2] - .6))).clamp(0.0, 1.0)));
      }
    }
    // مانگ
    if (night || dusk || dawn) {
      final mo = dawn ? .55 : 1.0;
      final o = Offset(fx(34 * w / 170), math.min(36, h * .35));
      c.drawCircle(o, 24, Paint()..color = pa.withValues(alpha: .08 * mo));
      final fr = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = pa.withValues(alpha: .32 * mo);
      c.save();
      c.translate(o.dx, o.dy);
      c.drawRect(const Rect.fromLTWH(-14, -14, 28, 28), fr);
      c.rotate(math.pi / 4);
      c.drawRect(const Rect.fromLTWH(-14, -14, 28, 28), fr);
      c.restore();
      final moon = Path.combine(
        PathOperation.difference,
        Path()..addOval(Rect.fromCircle(center: o, radius: 10)),
        Path()..addOval(Rect.fromCircle(center: o + const Offset(5, -2), radius: 8)),
      );
      c.drawPath(moon, Paint()..color = pa.withValues(alpha: mo));
    }
    // ڕووناکی ئاسۆ
    void glow(double cx, double rx, double ry, Color col, double a) {
      final r = Rect.fromCenter(center: Offset(cx, h), width: rx * 2, height: ry * 2);
      c.drawOval(r, Paint()..shader = RadialGradient(colors: [col.withValues(alpha: a), col.withValues(alpha: 0)]).createShader(r));
    }

    if (dawn) glow(fx(w * .8), w * .75, h * .45, const Color(0xFFFFC59A), .75);
    if (dusk) glow(fx(w * .15), w * .7, h * .38, const Color(0xFFE57AA8), .75);
    // خۆر
    if (sunUp) {
      if (ph == 'sunset') glow(fx(w * .1), w * .8, h * .42, const Color(0xFFFFB060), .75);
      final x = fx(w + 8 - (w + 16) * f);
      final y = h + 4 - (h * .8) * math.sin(math.pi * f);
      final r = ph == 'sunset' ? 20.0 : ph == 'noon' ? 14.0 : 16.0;
      final rtlX = rtl ? x : w - x;
      final under = w < 200 && rtlX > w * .3 && y > h * .3; // خۆر لە ژێر نووسینەکەیە ← کاڵتر
      final op = under ? .5 : 1.0;
      final hot = ph == 'sunset' ? const Color(0xFFFFB25A) : const Color(0xFFFFF4C2);
      final mid = ph == 'sunset' ? const Color(0xFFFF8A3D) : const Color(0xFFFFD36B);
      final gr = Rect.fromCircle(center: Offset(x, y), radius: r * 3.2);
      c.drawCircle(
          Offset(x, y),
          r * 3.2,
          Paint()
            ..shader = RadialGradient(
              colors: [hot.withValues(alpha: .95 * op), mid.withValues(alpha: .45 * op), mid.withValues(alpha: 0)],
              stops: const [0, .35, 1],
            ).createShader(gr));
      final core = ph == 'sunset' ? const Color(0xFFFFB04A) : ph == 'asr' ? const Color(0xFFFFD36B) : const Color(0xFFFFF1B8);
      c.drawCircle(Offset(x, y), under ? r * .8 : r, Paint()..color = core.withValues(alpha: op));
    }
    // گرد و مزگەوت (زۆر کاڵ)
    final hill = Path()
      ..moveTo(0, h - 14)
      ..quadraticBezierTo(w * .25, h - 26, w * .5, h - 16)
      ..quadraticBezierTo(w * .75, h - 6, w, h - 18)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    c.drawPath(hill, Paint()..color = const Color(0x29000000));
    final mq = Paint()..color = const Color(0x38000000);
    final bx = fx(w * .14);
    final dirX = rtl ? 1.0 : -1.0;
    c.drawPath(
        Path()
          ..moveTo(bx - 12, h - 16)
          ..arcToPoint(Offset(bx + 12, h - 16), radius: const Radius.elliptical(12, 11)),
        mq);
    c.drawRect(Rect.fromLTWH(bx - 13, h - 16, 26, 16), mq);
    final mx = bx + dirX * 18;
    c.drawRect(Rect.fromCenter(center: Offset(mx, h - 19), width: 4, height: 38), mq);
    c.drawPath(
        Path()
          ..moveTo(mx - 3, h - 38)
          ..lineTo(mx, h - 44)
          ..lineTo(mx + 3, h - 38)
          ..close(),
        mq);
  }

  @override
  bool shouldRepaint(covariant _SkyPainter o) => o.ph != ph || (o.f - f).abs() > .002 || o.rtl != rtl;
}

// ───────────────────────────────────────────────────────────────────────────
// 7) پارچە بچووکەکان (جووڵەی نەرم)
// ───────────────────────────────────────────────────────────────────────────
/// هەر شتێک کە پەنجەی لێدەدرێت: بچووکبوونەوە و گەڕانەوە بە بازدان
class _Tap extends StatefulWidget {
  const _Tap({required this.child, this.onTap, this.scale = .95, this.label});
  final Widget child;
  final VoidCallback? onTap;
  final double scale;
  final String? label;

  @override
  State<_Tap> createState() => _TapState();
}

class _TapState extends State<_Tap> {
  bool _d = false;

  void _s(bool v) {
    if (_d != v && mounted) setState(() => _d = v);
  }

  @override
  Widget build(BuildContext context) {
    final en = widget.onTap != null;
    return Semantics(
      button: true,
      label: widget.label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: en ? (_) => _s(true) : null,
        onTapUp: en ? (_) => _s(false) : null,
        onTapCancel: en ? () => _s(false) : null,
        onTap: en
            ? () {
                HapticFeedback.selectionClick();
                widget.onTap!();
              }
            : null,
        child: AnimatedScale(
          scale: _d ? widget.scale : 1,
          duration: Duration(milliseconds: _d ? 90 : 320),
          curve: _d ? Curves.easeOut : Curves.easeOutBack,
          child: widget.child,
        ),
      ),
    );
  }
}

/// سویچ: خڕەکە بە بازدانەوە دەجووڵێت، و لە کاتی پەنجە لێدان درێژ دەبێتەوە
class _Switch extends StatefulWidget {
  const _Switch({required this.value, required this.onChanged, this.label});
  final bool value;
  final ValueChanged<bool> onChanged;
  final String? label;

  @override
  State<_Switch> createState() => _SwitchState();
}

class _SwitchState extends State<_Switch> {
  bool _d = false;
  late bool _v = widget.value;

  @override
  void didUpdateWidget(covariant _Switch o) {
    super.didUpdateWidget(o);
    _v = widget.value;
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      toggled: _v,
      label: widget.label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _d = true),
        onTapCancel: () => setState(() => _d = false),
        onTapUp: (_) => setState(() => _d = false),
        onTap: () {
          HapticFeedback.lightImpact();
          setState(() => _v = !_v); // جووڵە یەکسەر دەست پێدەکات
          widget.onChanged(_v);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          width: 48,
          height: 28,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: _v ? _sa : _off,
            borderRadius: BorderRadius.circular(14),
            boxShadow: _v ? [BoxShadow(color: _sa.withValues(alpha: .35), blurRadius: 12, spreadRadius: -4)] : const [],
          ),
          child: AnimatedAlign(
            duration: const Duration(milliseconds: 380),
            curve: Curves.easeOutBack,
            alignment: _v ? AlignmentDirectional.centerEnd : AlignmentDirectional.centerStart,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              width: _d ? 27 : 22,
              height: 22,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(11),
                boxShadow: const [BoxShadow(color: Color(0x4D000000), blurRadius: 3, offset: Offset(0, 1))],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// کات بە AM/PM ـی بچووک
Widget _time(int mins, {double size = 17, Color? c, FontWeight w = FontWeight.w700}) {
  final x = h12(mins);
  final col = c ?? V.tx;
  return Directionality(
    textDirection: TextDirection.ltr,
    child: Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(x.t, style: nu(size, w: w, c: col)),
        const SizedBox(width: 2),
        Text(x.a, style: nu(size * .58, w: FontWeight.w700, c: col.withValues(alpha: .7))),
      ],
    ),
  );
}

TextStyle _k(double s, {FontWeight w = FontWeight.w700, Color? c, double? h}) => ku(s, w: w, c: c, h: h);

// ───────────────────────────────────────────────────────────────────────────
// 8) کارتی سەرەکی (لاکێشەیی · دوو بەش)
// ───────────────────────────────────────────────────────────────────────────
class PrayerCard extends StatelessWidget {
  const PrayerCard({super.key});

  @override
  Widget build(BuildContext context) {
    LangScope.of(context);
    final P = VexPrayer.I;
    return ListenableBuilder(
      listenable: Listenable.merge([P, P.clock, VexTheme.I]),
      builder: (context, _) {
        final S = P.state();
        final ph = _phOf(S.phase);
        final x = h12(S.nextAt);
        return Directionality(
          textDirection: _dir,
          child: Padding(
            padding: const EdgeInsets.only(top: 14),
            child: _Tap(
              scale: .985,
              label: pt('title'),
              onTap: () => openPrayerPage(),
              child: Container(
                height: 164,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: V.surf2,
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(color: _light ? const Color(0x1A0A1E3C) : V.line),
                  boxShadow: [
                    BoxShadow(
                      color: _light ? const Color(0x470A1830) : const Color(0x8C000000),
                      blurRadius: 30,
                      offset: const Offset(0, 14),
                      spreadRadius: -16,
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── بەشی ئاسمان ──
                    Expanded(
                      flex: 47,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 1200),
                        decoration: BoxDecoration(gradient: _skyGrad(S.phase)),
                        child: Stack(
                          children: [
                            Positioned.fill(child: CustomPaint(painter: _SkyPainter(S.phase, S.sun, _rtl))),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(children: [
                                    _Blink(color: ph.pa),
                                    const SizedBox(width: 6),
                                    Flexible(child: Text(pt('next'), maxLines: 1, overflow: TextOverflow.ellipsis, style: _k(11, w: FontWeight.w800, c: ph.pa))),
                                  ]),
                                  const SizedBox(height: 2),
                                  AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 400),
                                    child: Text(prayName(S.next),
                                        key: ValueKey(S.next),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: _k(18, w: FontWeight.w800, c: Colors.white, h: 1.35)
                                            .copyWith(shadows: const [Shadow(color: Color(0x59000000), blurRadius: 10)])),
                                  ),
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: AlignmentDirectional.centerStart,
                                    child: Directionality(
                                      textDirection: TextDirection.ltr,
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment: CrossAxisAlignment.baseline,
                                        textBaseline: TextBaseline.alphabetic,
                                        children: [
                                          Text(x.t,
                                              style: nu(36, w: FontWeight.w300, c: Colors.white, ls: -1.5, h: 1)
                                                  .copyWith(shadows: [Shadow(color: ph.pa.withValues(alpha: .55), blurRadius: 18)])),
                                          const SizedBox(width: 4),
                                          Text(x.a, style: nu(12, w: FontWeight.w700, c: Colors.white.withValues(alpha: .9))),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const Spacer(),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0x38000000),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: const Color(0x38FFFFFF)),
                                    ),
                                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                                      Text(_cd(S.left), textDirection: TextDirection.ltr, style: nu(12.5, w: FontWeight.w700, c: ph.pa)),
                                      const SizedBox(width: 5),
                                      Text(pt('left'), style: _k(11.5, w: FontWeight.w800, c: Colors.white)),
                                    ]),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // ── لیستی 5 بانگ ──
                    Expanded(
                      flex: 53,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [for (final k in kPrayFive) _CardRow(k: k, S: S, ph: ph)],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CardRow extends StatelessWidget {
  const _CardRow({required this.k, required this.S, required this.ph});
  final String k;
  final PrayState S;
  final _Ph ph;

  @override
  Widget build(BuildContext context) {
    final P = VexPrayer.I;
    final nx = k == S.next;
    final ps = !nx && S.passed(k);
    final col = ps ? V.mu : V.tx;
    final bell = P.on && P.items[k] == true;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
      height: 25,
      padding: const EdgeInsets.symmetric(horizontal: 9),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: nx ? (_light ? Color.lerp(Colors.white, ph.pd, .12) : ph.pa.withValues(alpha: .18)) : Colors.transparent,
        border: Border.all(color: nx ? (_light ? ph.pd.withValues(alpha: .4) : ph.pa.withValues(alpha: .45)) : Colors.transparent),
      ),
      child: Row(children: [
        Expanded(
          child: Text('${prayName(k)}${ps ? ' ✓' : ''}',
              maxLines: 1, overflow: TextOverflow.ellipsis, style: _k(12.5, w: FontWeight.w700, c: col)),
        ),
        if (bell) ...[
          Icon(Icons.notifications_none_rounded, size: 12, color: col.withValues(alpha: .6)),
          const SizedBox(width: 4),
        ],
        _time(S.t[k]!, size: 13, c: nx ? V.tx : col),
      ]),
    );
  }
}

class _Blink extends StatefulWidget {
  const _Blink({required this.color});
  final Color color;

  @override
  State<_Blink> createState() => _BlinkState();
}

class _BlinkState extends State<_Blink> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
        opacity: Tween(begin: 1.0, end: .35).animate(_c),
        child: Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.color,
            boxShadow: [BoxShadow(color: widget.color, blurRadius: 8)],
          ),
        ),
      );
}

// ───────────────────────────────────────────────────────────────────────────
// 9) پەڕەی ڕێکخستن
// ───────────────────────────────────────────────────────────────────────────
/// کردنەوەی پەڕەی بانگ (k = ئەو بانگەی کراوە دەبێت)
Future<void> openPrayerPage([String? k]) async {
  final nav = navKey.currentState;
  if (nav == null) return;
  await nav.push(PageRouteBuilder<void>(
    transitionDuration: const Duration(milliseconds: 380),
    reverseTransitionDuration: const Duration(milliseconds: 300),
    pageBuilder: (c, a, b) => PrayerPage(open: k),
    transitionsBuilder: (c, a, b, child) {
      final cv = CurvedAnimation(parent: a, curve: Curves.easeOutCubic, reverseCurve: Curves.easeInCubic);
      return SlideTransition(
        position: Tween(begin: Offset(_rtl ? -1 : 1, 0), end: Offset.zero).animate(cv),
        child: child,
      );
    },
  ));
}

class PrayerPage extends StatefulWidget {
  const PrayerPage({super.key, this.open});
  final String? open;

  @override
  State<PrayerPage> createState() => _PrayerPageState();
}

class _PrayerPageState extends State<PrayerPage> {
  String _open = '';

  @override
  void initState() {
    super.initState();
    _open = widget.open ?? VexPrayer.I.state().next;
  }

  Future<void> _gps() async {
    final err = await VexPrayer.I.connectGps();
    if (err != null && mounted) {
      toast(err);
      if (err == pt('gpsOff')) unawaited(Geolocator.openLocationSettings());
      if (err == pt('geoNo') && await Geolocator.checkPermission() == LocationPermission.deniedForever) {
        unawaited(Geolocator.openAppSettings());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    LangScope.of(context);
    final P = VexPrayer.I;
    final mq = MediaQuery.of(context);
    return Directionality(
      textDirection: _dir,
      child: Scaffold(
        backgroundColor: V.bg,
        body: ListenableBuilder(
          listenable: Listenable.merge([P, P.clock, VexTheme.I]),
          builder: (context, _) {
            final S = P.state();
            final ph = _phOf(S.phase);
            final x = h12(S.nextAt);
            final pl = P.placeLabel;
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: ListView(
                  padding: EdgeInsets.fromLTRB(16, mq.padding.top + 14, 16, mq.padding.bottom + 28),
                  children: [
                    // سەرەوە
                    Row(children: [
                      _Tap(
                        label: pt('back'),
                        onTap: () => Navigator.of(context).maybePop(),
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(color: V.surf2, borderRadius: BorderRadius.circular(14), border: Border.all(color: V.line)),
                          child: Icon(_rtl ? Icons.chevron_right_rounded : Icons.chevron_left_rounded, color: V.tx, size: 26),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(pt('title'), style: _k(19, w: FontWeight.w800)),
                          Text('${pl.isEmpty ? '' : '$pl · '}${_dateTx(S.now)}',
                              maxLines: 1, overflow: TextOverflow.ellipsis, style: _k(12, w: FontWeight.w400, c: V.mu)),
                        ]),
                      ),
                    ]),
                    const SizedBox(height: 12),
                    // ئاسمان
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 1200),
                      height: 104,
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(gradient: _skyGrad(S.phase), borderRadius: BorderRadius.circular(26)),
                      child: Stack(children: [
                        Positioned.fill(child: CustomPaint(painter: _SkyPainter(S.phase, S.sun, _rtl))),
                        Padding(
                          padding: const EdgeInsetsDirectional.fromSTEB(16, 0, 14, 0),
                          child: Row(children: [
                            Expanded(
                              child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(pt('next'), style: _k(11, w: FontWeight.w800, c: ph.pa)),
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: AlignmentDirectional.centerStart,
                                  child: Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
                                    Text(prayName(S.next), style: _k(19, w: FontWeight.w800, c: Colors.white)),
                                    const SizedBox(width: 8),
                                    Directionality(
                                      textDirection: TextDirection.ltr,
                                      child: Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
                                        Text(x.t, style: nu(30, w: FontWeight.w300, c: Colors.white, ls: -1)),
                                        const SizedBox(width: 3),
                                        Text(x.a, style: nu(12, w: FontWeight.w700, c: Colors.white)),
                                      ]),
                                    ),
                                  ]),
                                ),
                              ]),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0x38000000),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: const Color(0x38FFFFFF)),
                              ),
                              child: Column(mainAxisSize: MainAxisSize.min, children: [
                                Text(_cd(S.left), textDirection: TextDirection.ltr, style: nu(16, w: FontWeight.w700, c: ph.pa)),
                                Text(pt('left'), style: _k(10.5, c: const Color(0xD9FFFFFF))),
                              ]),
                            ),
                          ]),
                        ),
                      ]),
                    ),
                    // سویچی سەرەکی
                    _Box(
                      child: _Row(
                        icon: Icons.vibration_rounded,
                        title: pt('master'),
                        sub: P.on ? pt('mOn') : pt('mOff'),
                        sub2: P.on ? (P.bandLinked ? pt('bandOk') : pt('bandNo')) : null,
                        sub2Ok: P.bandLinked,
                        trailing: _Switch(value: P.on, label: pt('master'), onChanged: P.setOn),
                      ),
                    ),
                    _Sec(pt('loc')),
                    _Box(
                      child: _Row(
                        icon: Icons.location_on_outlined,
                        iconOk: P.hasGps,
                        title: P.hasGps ? pl : pt('notConn'),
                        sub: P.hasGps ? _coord(P.lat!, P.lng!) : pt('hint'),
                        subLtr: P.hasGps,
                        sub2: '🕐 ${_clock(S.now)}',
                        trailing: _Tap(
                          onTap: P.locating ? null : _gps,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                            decoration: BoxDecoration(
                              color: _sa.withValues(alpha: P.locating ? .6 : 1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(mainAxisSize: MainAxisSize.min, children: [
                              if (P.locating) ...[
                                SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: _sf)),
                                const SizedBox(width: 6),
                              ],
                              Text(P.locating ? pt('locating') : (P.hasGps ? pt('refresh') : pt('connect')),
                                  style: _k(12.5, w: FontWeight.w800, c: _sf)),
                            ]),
                          ),
                        ),
                      ),
                    ),
                    _Sec(pt('prayers')),
                    for (final k in kPraySix)
                      _Item(
                        k: k,
                        S: S,
                        ph: ph,
                        open: _open == k,
                        onOpen: () => setState(() => _open = _open == k ? '' : k),
                      ),
                    Padding(
                      padding: const EdgeInsets.only(top: 14),
                      child: Text(pt('method'), textAlign: TextAlign.center, style: _k(11.5, w: FontWeight.w400, c: V.mu, h: 1.7)),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _Sec extends StatelessWidget {
  const _Sec(this.t);
  final String t;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 16, 4, 6),
        child: Text(t, style: _k(13, w: FontWeight.w800, c: V.mu)),
      );
}

class _Box extends StatelessWidget {
  const _Box({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(top: 10),
        decoration: BoxDecoration(color: V.surf2, borderRadius: BorderRadius.circular(20), border: Border.all(color: V.line)),
        child: child,
      );
}

class _Row extends StatelessWidget {
  const _Row({
    required this.icon, required this.title, required this.sub, required this.trailing,
    this.sub2, this.sub2Ok = false, this.iconOk = false, this.subLtr = false,
  });
  final IconData icon;
  final String title, sub;
  final String? sub2;
  final bool sub2Ok, iconOk, subLtr;
  final Widget trailing;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 64),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: iconOk ? const Color(0x383CF08A) : V.track,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 20, color: iconOk ? const Color(0xFF1FAE63) : V.tx),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: _k(15, w: FontWeight.w800)),
                const SizedBox(height: 2),
                Text(sub, textDirection: subLtr ? TextDirection.ltr : null, style: (subLtr ? nu(12, w: FontWeight.w600, c: V.mu) : _k(12, w: FontWeight.w400, c: V.mu, h: 1.5))),
                if (sub2 != null)
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: Text(sub2!,
                        key: ValueKey(sub2Ok),
                        textDirection: sub2!.startsWith('🕐') ? TextDirection.ltr : null,
                        style: _k(11.5, w: FontWeight.w600, c: sub2Ok ? const Color(0xFF1FAE63) : V.mu, h: 1.6)),
                  ),
              ]),
            ),
            const SizedBox(width: 10),
            trailing,
          ]),
        ),
      );
}

class _Item extends StatelessWidget {
  const _Item({required this.k, required this.S, required this.ph, required this.open, required this.onOpen});
  final String k;
  final PrayState S;
  final _Ph ph;
  final bool open;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final P = VexPrayer.I;
    final sun = k == 'sunrise';
    final c = sun ? PrayCfg() : P.cfgOf(k);
    final on = !sun && P.on && P.items[k] == true;
    final nx = k == S.next;
    final ps = !nx && S.passed(k);
    final tag = nx ? pt('tNext') : (S.tomorrow && k == 'fajr') ? pt('tTom') : ps ? pt('tPast') : pt('tToday');
    final sum = sun ? pt('info') : (on ? '${prayWhen(c.lead)} · ${pt(c.pat)}' : pt('off'));
    final icon = switch (k) {
      'isha' => Icons.nightlight_round,
      'dhuhr' || 'asr' => Icons.wb_sunny_outlined,
      _ => Icons.wb_twilight_rounded,
    };
    final isOpen = open && !sun;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
      margin: const EdgeInsets.only(top: 8),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: V.surf2,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: nx ? (_light ? ph.pd : ph.pa.withValues(alpha: .7)) : V.line,
          width: nx ? 1.5 : 1,
        ),
        boxShadow: isOpen ? [BoxShadow(color: _sa.withValues(alpha: .12), blurRadius: 20, spreadRadius: -6)] : const [],
      ),
      child: Column(children: [
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 64),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(children: [
              Expanded(
                child: _Tap(
                  scale: .98,
                  onTap: sun ? null : onOpen,
                  child: Row(children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 500),
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        gradient: nx ? _skyGrad(S.phase) : null,
                        color: nx ? null : V.track,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, size: 20, color: nx ? Colors.white : V.tx),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          Flexible(child: Text(prayName(k), maxLines: 1, overflow: TextOverflow.ellipsis, style: _k(15, w: FontWeight.w800))),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
                            decoration: BoxDecoration(
                              color: nx ? ph.pa.withValues(alpha: .26) : V.track,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(tag, style: _k(10.5, w: FontWeight.w800, c: nx ? V.tx : V.mu)),
                          ),
                        ]),
                        const SizedBox(height: 2),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 250),
                          child: Text(sum, key: ValueKey(sum), style: _k(12, w: FontWeight.w400, c: V.mu, h: 1.5)),
                        ),
                      ]),
                    ),
                    const SizedBox(width: 8),
                    _time(S.t[k]!, c: ps ? V.mu : V.tx),
                  ]),
                ),
              ),
              if (!sun) ...[
                const SizedBox(width: 12),
                _Switch(value: on, label: prayName(k), onChanged: (_) => P.toggle(k)),
              ],
            ]),
          ),
        ),
        // بەشی کراوە (جووڵەی نەرم)
        AnimatedSize(
          duration: const Duration(milliseconds: 340),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 260),
            transitionBuilder: (child, a) => FadeTransition(
              opacity: a,
              child: SlideTransition(position: Tween(begin: const Offset(0, -.06), end: Offset.zero).animate(a), child: child),
            ),
            child: isOpen ? _Expanded(key: ValueKey(k), k: k, c: c) : const SizedBox(width: double.infinity),
          ),
        ),
      ]),
    );
  }
}

class _Expanded extends StatelessWidget {
  const _Expanded({super.key, required this.k, required this.c});
  final String k;
  final PrayCfg c;

  @override
  Widget build(BuildContext context) {
    final P = VexPrayer.I;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(border: Border(top: BorderSide(color: V.line))),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(pt('before'), style: _k(12.5, w: FontWeight.w800, c: V.mu)),
        const SizedBox(height: 8),
        Row(children: [
          for (var i = 0; i < kPrayLeads.length; i++) ...[
            if (i > 0) const SizedBox(width: 6),
            Expanded(
              child: _Chip(
                on: c.lead == kPrayLeads[i],
                height: 54,
                onTap: () => P.setLead(k, kPrayLeads[i]),
                child: (col) => kPrayLeads[i] == 0
                    ? Column(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.notifications_none_rounded, size: 18, color: col),
                        Text(pt('at'), maxLines: 1, overflow: TextOverflow.ellipsis, style: _k(10.5, c: col)),
                      ])
                    : Column(mainAxisSize: MainAxisSize.min, children: [
                        Text('${kPrayLeads[i]}', style: nu(18, w: FontWeight.w800, c: col, h: 1.1)),
                        Text(pt('min'), maxLines: 1, style: _k(10.5, c: col)),
                      ]),
              ),
            ),
          ],
        ]),
        const SizedBox(height: 14),
        Text(pt('vt'), style: _k(12.5, w: FontWeight.w800, c: V.mu)),
        const SizedBox(height: 8),
        Row(children: [
          for (var i = 0; i < kPrayPats.length; i++) ...[
            if (i > 0) const SizedBox(width: 6),
            Expanded(
              child: _Chip(
                on: c.pat == kPrayPats[i],
                height: 40,
                onTap: () => P.setPat(k, kPrayPats[i]),
                child: (col) => Text(pt(kPrayPats[i]), style: _k(12.5, w: FontWeight.w800, c: col)),
              ),
            ),
          ],
        ]),
        AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          child: c.lead > 0
              ? Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Row(children: [
                    Expanded(child: Text(pt('alsoAt'), style: _k(13.5, w: FontWeight.w800))),
                    _Switch(value: c.at, label: pt('alsoAt'), onChanged: (v) => P.setAt(k, v)),
                  ]),
                )
              : const SizedBox(width: double.infinity),
        ),
        const SizedBox(height: 12),
        _Tap(
          scale: .96,
          onTap: () => P.test(k),
          child: Container(
            height: 46,
            decoration: BoxDecoration(color: const Color(0xFF13294A), borderRadius: BorderRadius.circular(14)),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.vibration_rounded, size: 18, color: Color(0xFFF2C46D)),
              const SizedBox(width: 8),
              Text(pt('test'), style: _k(13.5, w: FontWeight.w800, c: Colors.white)),
            ]),
          ),
        ),
      ]),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.on, required this.onTap, required this.child, this.height = 40});
  final bool on;
  final VoidCallback onTap;
  final Widget Function(Color) child;
  final double height;

  @override
  Widget build(BuildContext context) {
    final col = on ? _sf : V.tx;
    return _Tap(
      scale: .92,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
        height: height,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: on ? _sa : V.track,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: on ? _sa : V.line),
          boxShadow: on ? [BoxShadow(color: _sa.withValues(alpha: .45), blurRadius: 16, offset: const Offset(0, 6), spreadRadius: -8)] : const [],
        ),
        child: child(col),
      ),
    );
  }
}

// ───────────────────────────────────────────────────────────────────────────
// 10) پەنجەرەی لەرین
// ───────────────────────────────────────────────────────────────────────────
class _RingView extends StatefulWidget {
  const _RingView({required this.title, required this.sub});
  final String title, sub;

  @override
  State<_RingView> createState() => _RingViewState();
}

class _RingViewState extends State<_RingView> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 500))..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: _dir,
      child: PopScope(
        canPop: false,
        child: Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: math.min(340, MediaQuery.of(context).size.width * .86),
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF13294A), Color(0xFF0B1830)]),
                border: Border.all(color: const Color(0x73F2C46D)),
                boxShadow: const [BoxShadow(color: Color(0x66F2C46D), blurRadius: 60, spreadRadius: -12)],
              ),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                AnimatedBuilder(
                  animation: _c,
                  builder: (_, child) => Transform.rotate(angle: (_c.value - .5) * .42, child: child),
                  child: const Icon(Icons.nightlight_round, size: 64, color: Color(0xFFF2C46D)),
                ),
                const SizedBox(height: 10),
                Text(widget.title, textAlign: TextAlign.center, style: _k(21, w: FontWeight.w800, c: Colors.white)),
                const SizedBox(height: 4),
                Text(widget.sub, textAlign: TextAlign.center, style: _k(13, w: FontWeight.w700, c: const Color(0xFFC9D6EA))),
                const SizedBox(height: 22),
                _Tap(
                  scale: .96,
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    height: 50,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: const Color(0xFFF2C46D), borderRadius: BorderRadius.circular(16)),
                    child: Text(pt('stop'), style: _k(15, w: FontWeight.w800, c: const Color(0xFF13294A))),
                  ),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
