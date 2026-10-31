// =============================================================================
//  VEX Arena — پێشبڕکێی تەندروستی (Flutter)
//  هەمان دیزاین و هەمان یاسای وەشانی وێبی VEX Arena (v10)
//
//  فایلەکان (هەموویان لە lib/arena/):
//   vex_arena.dart      زمان، ڕەنگ، داتا، دژی فێڵ، پاشەکەوتکردن، کۆنترۆڵەر
//   arena_page.dart     پەڕە، ستەیج، سەرپەڕە، سپۆنسەر، تابەکان، دەروازەی تۆمارکردن
//   arena_today.dart    تابی «ئەمڕۆ» (وەرزی ڕاستەوخۆ + پێش وەرز)
//   arena_rank.dart     تابی «پلەکان»
//   arena_card.dart     تابی «کارتەکەم» + کارتی یاریزان
//   arena_sheets.dart   هەموو شیتەکان
//   arena_svg.dart      ئایکۆنە SVG ـەکان (هەمان وێنەی وێب)
//   arena_i18n.dart     وەرگێڕان: سۆرانی، بادینی، English، العربية، فارسی، Türkçe
//   arena_host.dart     بەستنەوە بە داتای ئەپەکە
//
//  pubspec.yaml: shared_preferences، flutter_svg، google_fonts، فۆنتی NotoAr،
//                assets/chars/ و assets/arena/
// =============================================================================
// ignore_for_file: prefer_single_quotes, use_build_context_synchronously

import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/theme.dart' show VexTheme;
import '../onboarding/reg_lang_state.dart' show LangState;

part 'arena_page.dart';
part 'arena_today.dart';
part 'arena_rank.dart';
part 'arena_card.dart';
part 'arena_sheets.dart';
part 'arena_svg.dart';
part 'arena_i18n.dart';

// =============================================================================
// 1. زمان
// =============================================================================

const List<String> _kLangs = ['ckb', 'kmr', 'en', 'ar', 'fa', 'tr'];

String get _lc => LangState.I.code;
int get _li {
  final i = _kLangs.indexOf(_lc);
  return i < 0 ? 0 : i;
}

bool get arenaLtr => _lc == 'en' || _lc == 'tr';
TextDirection get arenaDir => arenaLtr ? TextDirection.ltr : TextDirection.rtl;

/// وەرگێڕان: tr('key', [a, b]) → {0} {1} پڕ دەکاتەوە
String tr(String k, [List<Object?> a = const []]) {
  final v = kArenaT[k];
  var s = v == null ? k : v[_li];
  for (var i = 0; i < a.length; i++) {
    s = s.replaceAll('{$i}', '${a[i]}');
  }
  return s;
}

// =============================================================================
// 2. ڕەنگ — هەمان تۆکنەکانی وێب (تاریک / ڕووناک)
// =============================================================================

class AC {
  static bool get l => VexTheme.I.isLight;
  static Color get bg => l ? const Color(0xFFEEF9FB) : const Color(0xFF070D22);
  static Color get bg2 => l ? const Color(0xFFD5F0F4) : const Color(0xFF0D1838);
  static Color get surf => l ? const Color(0xE6FFFFFF) : const Color(0x8C182654);
  static Color get surf2 => l ? const Color(0xFFFFFFFF) : const Color(0x0DFFFFFF);
  static Color get line => l ? const Color(0x17062832) : const Color(0x21AABEFF);
  static Color get line2 => l ? const Color(0x3306788C) : const Color(0x57FFD678);
  static Color get solid => l ? const Color(0xFFF4FCFD) : const Color(0xFF0C1533);
  static Color get sheet => l ? const Color(0xFFF7FDFE) : const Color(0xFF0B1430);
  static Color get mu => l ? const Color(0xFF4D7680) : const Color(0xFF9DAAD2);
  static Color get tx => l ? const Color(0xFF062832) : const Color(0xFFEFFEFF);
  static Color get cy => l ? const Color(0xFF0AA7B8) : const Color(0xFF2FE6F3);
  static Color get c2 => l ? const Color(0xFF077F8C) : const Color(0xFF8FF3F9);
  static Color get mint => l ? const Color(0xFF13A85C) : const Color(0xFF3CF08A);
  static Color get violet => l ? const Color(0xFF6D4FE0) : const Color(0xFF9B7BFF);
  static Color get coral => l ? const Color(0xFFE5405F) : const Color(0xFFFF6F86);
  static Color get amber => l ? const Color(0xFFC47F05) : const Color(0xFFFFBE4D);
  static Color get track => l ? const Color(0x12062832) : const Color(0x12FFFFFF);
  static Color get inp => l ? const Color(0x0D062832) : const Color(0x0FFFFFFF);
  static Color get t3g => l ? const Color(0xFF9A6400) : const Color(0xFFFFD36B);
  static Color get t3gl => l ? const Color(0x66C48C14) : const Color(0x59FFD678);
  static Color get gold => l ? const Color(0xFFA87000) : const Color(0xFFFFD56B);
  static Color get silver => l ? const Color(0xFF6B7F8C) : const Color(0xFFD9E6EE);
  static Color get bronze => l ? const Color(0xFFA8622B) : const Color(0xFFE29A5F);
  static Color get orange => const Color(0xFFFF8A4D);
  static Color get skyb => const Color(0xFF7FD8FF);

  /// کارتی سەرەکی (ئامانج، تۆ لەم وەرزەدا)
  static Gradient? get t3card =>
      l ? null : cssLin(160, const [Color(0xFF13224A), Color(0xFF0A1330)]);
  static List<BoxShadow> get t3sh => l
      ? [cssSh(0, 18, 40, -22, const Color(0x59966400))]
      : [cssSh(0, 24, 50, -26, const Color(0x73FFBE3C))];

  /// کارتی ئاسایی (.card)
  static Color get card => l ? const Color(0xE6FFFFFF) : const Color(0x8C182654);

  // ستەیج و زێڕ
  static const stageTx = Color(0xFFEEF3FF);
  static const stageMu = Color(0xFFB9C4E6);
  static const goldS = Color(0xFFFFD36B);
  static const accent = Color(0xFFF2B21C);
  static const onGold = Color(0xFF2A1A00);
  static const goldG = LinearGradient(
      colors: [Color(0xFFFFF0B0), Color(0xFFFFD25A), Color(0xFFE7A514)],
      stops: [0, .45, 1],
      begin: Alignment(-1, -1),
      end: Alignment(1, 1));
  static const tabG = LinearGradient(
      colors: [Color(0xFFFFE48F), Color(0xFFF2B21C)], begin: Alignment.topCenter, end: Alignment.bottomCenter);
}

/// linear-gradient(<deg>, ...) ی CSS
LinearGradient cssLin(double deg, List<Color> c, [List<double>? stops]) {
  final r = deg * math.pi / 180;
  final x = math.sin(r), y = -math.cos(r);
  return LinearGradient(colors: c, stops: stops, begin: Alignment(-x, -y), end: Alignment(x, y));
}

/// box-shadow: x y blur spread color
BoxShadow cssSh(double x, double y, double blur, double spread, Color c) =>
    BoxShadow(color: c, offset: Offset(x, y), blurRadius: blur * .86, spreadRadius: spread);

const String _kFont = 'NotoAr';

TextStyle ats(double s, {FontWeight w = FontWeight.w500, Color? c, double? h, double? ls}) => TextStyle(
      fontFamily: _kFont,
      fontSize: s,
      fontWeight: w,
      color: c ?? AC.tx,
      height: h,
      letterSpacing: ls,
    );

/// ژمارە (فۆنتی Sora وەک وێب)
TextStyle atn(double s, {FontWeight w = FontWeight.w800, Color? c, double? h, double? ls}) {
  final base = ats(s, w: w, c: c, h: h, ls: ls);
  try {
    return GoogleFonts.sora(textStyle: base).copyWith(fontFamilyFallback: const [_kFont]);
  } catch (_) {
    return base;
  }
}

Color _a(Color c, double o) => c.withAlpha((o.clamp(0.0, 1.0) * 255).round());
Color _mix(Color a, Color b, double t) => Color.lerp(b, a, t)!;

String afmt(num n) {
  final s = n.round().abs().toString();
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
    b.write(s[i]);
  }
  return (n < 0 ? '-' : '') + b.toString();
}

String _p2(int n) => n.toString().padLeft(2, '0');

/// 07501234567 → 0750 *** 4567
String maskPhone(String p) => p.length == 11 ? '${p.substring(0, 4)} *** ${p.substring(7)}' : p;

int _fnv(String s) {
  var h = 2166136261;
  for (final c in s.codeUnits) {
    h ^= c;
    h = (h * 16777619) & 0xFFFFFFFF;
  }
  return h;
}

/// ژمارەی هەڕەمەکیی جێگیر بۆ کلیلێک
class _Seeded {
  _Seeded(String k) : _s = _fnv(k) % 2147483646 + 1;
  int _s;
  double next() {
    _s = (_s * 16807) % 2147483647;
    return _s / 2147483647;
  }
}

String dayKey(DateTime d) => '${d.year}-${d.month}-${d.day}';
DateTime _dayStart(DateTime d) => DateTime(d.year, d.month, d.day);

/// 10/12/2026
String kDate(DateTime d) {
  final l = d.toLocal();
  return '${l.day}/${l.month}/${l.year}';
}

// =============================================================================
// 3. وەرز، لیگ، خەڵات، بەشەکان
// =============================================================================

class ArenaCat {
  const ArenaCat(this.id, this.icon, this.color, this.max, this.phone, this.band);
  final String id;
  final String icon; // ناوی ئایکۆن (kArenaIco)
  final Color color;
  final int max; // لیگی Band
  final int phone; // لیگی مۆبایل (0 = نییە)
  final bool band; // پێویستی بە Band هەیە
  String get name => tr('cat_$id');
}

const List<ArenaCat> kCats = [
  ArenaCat('walk', 'walk', Color(0xFF3CF08A), 60, 50, false),
  ArenaCat('run', 'run', Color(0xFFFF9466), 60, 50, false),
  ArenaCat('gym', 'gym', Color(0xFFFF6F86), 60, 40, false),
  ArenaCat('sleep', 'sleep', Color(0xFF9B7BFF), 60, 0, true),
  ArenaCat('food', 'food', Color(0xFFFFBE4D), 30, 30, false),
  ArenaCat('water', 'water', Color(0xFF2FB8F3), 30, 30, false),
  ArenaCat('heart', 'heart', Color(0xFFFF5F7E), 40, 0, true),
  ArenaCat('o2', 'o2', Color(0xFF4FD2E6), 20, 0, true),
  ArenaCat('calm', 'calm', Color(0xFFA58CFF), 40, 0, true),
  ArenaCat('rec', 'rec', Color(0xFF3FD69A), 40, 0, true),
];

ArenaCat catById(String id) => kCats.firstWhere((c) => c.id == id, orElse: () => kCats.first);

/// لیگەکان: band = هەموو 10 بەش · phone = بێ Band
enum Div { band, phone }

Div divOf(String s) => s == 'phone' ? Div.phone : Div.band;
String divId(Div d) => d == Div.phone ? 'phone' : 'band';
int capOf(ArenaCat c, Div d) => d == Div.phone ? c.phone : c.max;
int maxDay(Div d) => d == Div.phone ? 200 : 600;
int activeMin(Div d) => d == Div.phone ? 60 : 100;
int coinMax(Div d) => maxDay(d) ~/ 25;

class Prize {
  const Prize(this.r, this.key, this.il);
  final int r;
  final String key;
  final String il; // car · phone · cash
  String get name => tr(key);
}

const Map<Div, List<Prize>> kPrizes = {
  Div.band: [
    Prize(1, 'pz_car', 'car'),
    Prize(2, 'pz_iphone', 'phone'),
    Prize(3, 'pz_1m', 'cash'),
  ],
  Div.phone: [
    Prize(1, 'pz_250', 'cash'),
    Prize(2, 'pz_150', 'cash'),
    Prize(3, 'pz_100', 'cash'),
  ],
};

class SeasonDef {
  const SeasonDef(this.n, this.start, this.days);
  final int n;
  final DateTime start;
  final int days;
  DateTime get end => start.add(Duration(days: days));
}

/// وەرزەکان لەسەر ڕۆژژمێر جێگیرن (کاتی بەغدا +03:00)
final List<SeasonDef> kSeasons = [
  SeasonDef(1, DateTime.utc(2026, 10, 31, 3), 30),
  SeasonDef(2, DateTime.utc(2026, 12, 10, 3), 30),
];

class SeasonNow {
  SeasonNow({required this.n, required this.live, required this.start, required this.end, required this.day, this.prevEnd});
  final int n;
  final bool live;
  final DateTime start; // pre: کاتی دەستپێکردن
  final DateTime end; // live: کۆتایی · pre: هەمان دەستپێکردن
  final int day; // 1..30 لە کاتی وەرزدا، 0 پێش وەرز
  final DateTime? prevEnd;
  int get daysLeft => live ? math.max(0, 30 - day + 1) : 30;
}

SeasonNow seasonNow([DateTime? at]) {
  final now = at ?? DateTime.now();
  for (final s in kSeasons) {
    if (!now.isBefore(s.start) && now.isBefore(s.end)) {
      final d = math.min(s.days, now.difference(s.start).inDays + 1);
      return SeasonNow(n: s.n, live: true, start: s.start, end: s.end, day: d);
    }
  }
  SeasonDef? prev;
  for (final s in kSeasons) {
    if (!now.isBefore(s.end)) prev = s;
  }
  for (final s in kSeasons) {
    if (now.isBefore(s.start)) {
      return SeasonNow(n: s.n, live: false, start: s.start, end: s.start, day: 0, prevEnd: prev?.end);
    }
  }
  final n = (prev?.n ?? 0) + 1;
  final st = (prev?.end ?? now).add(const Duration(days: 10));
  return SeasonNow(n: n, live: false, start: st, end: st, day: 0, prevEnd: prev?.end);
}

class League {
  const League(this.min, this.idx, this.key, this.color, this.c1, this.c2);
  final int min, idx;
  final String key;
  final Color color, c1, c2;
  String get name => tr(key);
}

const List<League> kLeagues = [
  League(0, 0, 'lg_bronze', Color(0xFFE29A5F), Color(0xFF5A3417), Color(0xFFA8642F)),
  League(600, 1, 'lg_silver', Color(0xFFD9E6EE), Color(0xFF4A5866), Color(0xFF9FB1BF)),
  League(1500, 2, 'lg_gold', Color(0xFFFFD56B), Color(0xFF6B4A0A), Color(0xFFD9A21F)),
  League(3000, 3, 'lg_plat', Color(0xFF7FE7FF), Color(0xFF0B4D5C), Color(0xFF2BB5C9)),
  League(5000, 4, 'lg_dia', Color(0xFFB9A6FF), Color(0xFF2A1A6E), Color(0xFF7B5CFF)),
  League(7500, 5, 'lg_legend', Color(0xFFFF6F86), Color(0xFF5A0F22), Color(0xFFD62F55)),
];

League leagueOf(num p, [Div d = Div.band]) {
  var l = kLeagues.first;
  for (final x in kLeagues) {
    if (p >= x.min) l = x;
  }
  return l;
}

int leagueIndex(League l) => kLeagues.indexOf(l);
int levelOf(num p) => math.sqrt(math.max(0, p) / 25).floor() + 1;
int lvlStart(int l) => 25 * (l - 1) * (l - 1);
int ratingOf(num p) => math.min(99, (52 + math.log(math.max(p, 50) / 50) * 9).round());

const List<String> kCities = [
  'هەولێر', 'سلێمانی', 'دهۆک', 'کەرکووک', 'هەڵەبجە', 'زاخۆ', 'ڕانیە', 'کۆیە', 'سۆران', 'چەمچەماڵ', 'ئاکرێ', 'ئامێدی', 'شێخان',
  'سمێل', 'سەرسەنگ', 'بەردەڕەش', 'دیانا', 'ڕواندز', 'شەقڵاوە', 'مێرگەسور', 'پشدەر', 'قەڵادزێ', 'بێتواتە', 'پێنجوێن', 'سیتەک',
  'سەیدسادق', 'دەربەندیخان', 'کەلار', 'کفری', 'خانەقین', 'جەلەولا', 'قەرەتەپە', 'تاقتاق', 'دووکان', 'دەبەگ', 'حەویجە', 'مەخموور',
  'شنگال', 'تەلعەفەر', 'خورماتوو', 'تۆزخورماتوو', 'بەعشیقە', 'تەلکێف', 'عەقرە', 'زێباری', 'قۆشتەپە', 'مەهاباد', 'سنە', 'کرماشان',
  'ورمێ', 'بانە', 'مەریوان', 'سەقز', 'بۆکان', 'پیرانشار', 'نەغەدە', 'ئیلام', 'دیاربەکر', 'وان', 'ماردین', 'باتمان', 'هەکاری',
  'جزیر', 'ئورفە', 'قامیشلۆ', 'کۆبانی', 'عەفرین', 'دێرک', 'عامودا', 'حەسەکە', 'سەرێکانی', 'تەبریز', 'تاران', 'هەمەدان',
];

const List<List<String>> kAges = [
  ['y', '12-17'],
  ['a', '18-39'],
  ['m', '40-59'],
  ['s', '60+'],
];

// کارەکتەرەکان: هەمان کارەکتەرەکانی بەشی خێزان (assets/chars/XX.webp)
const List<List<Object>> kChars = [
  ['00', 0], ['01', 0], ['02', 0], ['03', 0], ['07', 0], ['08', 0], ['10', 0], ['11', 0],
  ['05', 40], ['06', 40], ['09', 40], ['17', 40], ['29', 40],
  ['04', 60], ['12', 60], ['18', 60], ['19', 60], ['23', 60], ['25', 60], ['26', 60], ['27', 60], ['30', 60], ['31', 60],
  ['13', 80], ['15', 80], ['16', 80], ['20', 80], ['22', 80], ['32', 80], ['33', 80],
  ['14', 150], ['21', 150], ['24', 150],
];
int charCost(String id) {
  for (final c in kChars) {
    if (c[0] == id) return c[1] as int;
  }
  return 0;
}

/// c ئاسایی · r دەگمەن · e ناوازە · l ئەفسانەیی
String charRarity(String id) {
  final c = charCost(id);
  return c == 0 ? 'c' : c <= 60 ? 'r' : c <= 80 ? 'e' : 'l';
}

Color rarColor(String r) => r == 'r' ? const Color(0xFF7FD8FF) : r == 'e' ? const Color(0xFFB9A6FF) : r == 'l' ? const Color(0xFFFFD36B) : const Color(0xFF9FB1BF);

String charAsset(String id) => 'assets/chars/$id.webp';
const Duration kCharLock = Duration(days: 30);

// دیزاینی کارت (وێنەکان: assets/arena/skin_*.webp)
class CardSkin {
  const CardSkin(this.id, this.cost, this.rar, {this.lg = 0});
  final String id;
  final int cost;
  final String rar; // f بەخۆڕایی · c ئاسایی · r دەگمەن · e ئەفسانەیی · l لیگ
  final int lg; // پێویستی بە لیگ (ئیندێکس)
  String get name => tr('sk_$id');
  String get desc => tr('skd_$id');
  String asset(num pts) => id == 'auto' ? 'assets/arena/skin_auto${leagueOf(pts).idx}.webp' : 'assets/arena/skin_$id.webp';
  Color accent(num pts) => id == 'auto' ? leagueOf(pts).color : (kSkinAccent[id] ?? const Color(0xFFFFD36B));
}

const Map<String, Color> kSkinAccent = {
  'neon': Color(0xFF2FE6F3), 'night': Color(0xFF9B7BFF), 'carbon': Color(0xFFA9BDD4), 'kurd': Color(0xFFFFD56B),
  'marble': Color(0xFFFFD36B), 'zagros': Color(0xFFFFC46B), 'newroz': Color(0xFFFFB36B), 'holo': Color(0xFFB6F3FF),
  'royal': Color(0xFFFFD56B), 'gold': Color(0xFFFFD56B), 'dia': Color(0xFFD6C8FF), 'legend': Color(0xFFFF8FA3),
};

const List<CardSkin> kSkins = [
  CardSkin('auto', 0, 'f'),
  CardSkin('neon', 30, 'c'),
  CardSkin('night', 40, 'c'),
  CardSkin('carbon', 50, 'c'),
  CardSkin('kurd', 60, 'r'),
  CardSkin('marble', 70, 'r'),
  CardSkin('zagros', 80, 'r'),
  CardSkin('newroz', 90, 'r'),
  CardSkin('holo', 100, 'e'),
  CardSkin('royal', 120, 'e'),
  CardSkin('gold', 0, 'l', lg: 2),
  CardSkin('dia', 0, 'l', lg: 4),
  CardSkin('legend', 0, 'l', lg: 5),
];

Color skinRarColor(String r) => switch (r) {
      'f' => const Color(0xFF8FD3FF),
      'r' => const Color(0xFFB49BFF),
      'e' => const Color(0xFFFFD36B),
      'l' => const Color(0xFF7FE7FF),
      _ => const Color(0xFF9FB3CF),
    };

CardSkin skinById(String id) => kSkins.firstWhere((s) => s.id == id, orElse: () => kSkins.first);

const List<List<Object>> kTitles = [
  ['t0', 0, 'rocket'],
  ['t1', 0, 'sleep'],
  ['t2', 0, 'run'],
  ['t3', 1, 'crystal'],
  ['t4', 0, 'flag'],
  ['t5', 5, 'crown'],
];

// =============================================================================
// 4. پەیوەندی بە ئەپەکەوە
// =============================================================================

class ArenaProfile {
  const ArenaProfile({this.name = '', this.phone = '', this.age = 30});
  final String name;
  final String phone; // 07XXXXXXXXX
  final int age;
}

class ArenaSportSession {
  const ArenaSportSession({required this.sportId, required this.minutes, this.km = 0, this.hrZones = const []});
  final String sportId; // run · treadmill · walk · gym · ...
  final int minutes;
  final double km;
  final List<int> hrZones; // چرکە لە هەر ناوچەیەکی دڵ (5 ناوچە)
}

class ArenaMeal {
  const ArenaMeal(this.name, this.kcal, this.at);
  final String name;
  final int kcal;
  final String at; // HH:mm
}

class ArenaDayInputs {
  const ArenaDayInputs({
    this.steps = 0,
    this.sleepHours = 0,
    this.spo2 = 0,
    this.stress = 0,
    this.hrv = 0,
    this.restHr = 0,
    this.activeMinutes = 0,
    this.sessions = const [],
    this.meals = const [],
    this.waterGlasses = 0,
    this.waterGoalGlasses = 8,
  });
  final int steps;
  final double sleepHours;
  final int spo2, stress, hrv, restHr, activeMinutes;
  final List<ArenaSportSession> sessions;
  final List<ArenaMeal> meals;
  final int waterGlasses; // پەرداخی 250ml
  final int waterGoalGlasses;
}

/// ئەپەکە ئەمە پڕ دەکاتەوە (بڕوانە arena_host.dart)
abstract class ArenaHost {
  ArenaProfile get profile;

  /// داتای ئەمڕۆ (Band + بەشەکانی ئەپ)
  ArenaDayInputs today();

  /// ئایا بەکارهێنەر VEX Band ی هەیە و پەیوەستی کردووە؟ (نەخێر ← لیگی مۆبایل)
  bool get hasBand;

  /// ئایا ئێستا Band لە دەستە و پەیوەستە؟
  bool get bandConnected => hasBand;

  /// هەر کاتێک داتا دەگۆڕێت notify بکە
  Listenable? get changes => null;

  /// دوگمەی «بڕۆ بۆ بەشی ...»
  void openSection(BuildContext context, String catId) {}
}

class DemoArenaHost extends ArenaHost {
  DemoArenaHost({this.band = true});
  bool band;
  @override
  ArenaProfile get profile => const ArenaProfile(name: '', phone: '', age: 30);
  @override
  bool get hasBand => band;
  @override
  ArenaDayInputs today() => const ArenaDayInputs(
        steps: 2225,
        sleepHours: 6.3,
        spo2: 93,
        stress: 55,
        hrv: 54,
        restHr: 70,
        activeMinutes: 22,
        waterGlasses: 0,
        waterGoalGlasses: 8,
      );
}

// =============================================================================
// 5. بزوێنەری پشتڕاستکردنەوە (دژی فێڵ) و خاڵ
// =============================================================================

/// ok = پشتڕاستکرایەوە · rej = ڕەتکرایەوە · wait = چاوەڕێی Band · na = تەنها لیگی Band · none = هێشتا نییە
class CatValue {
  const CatValue(this.label, this.f, this.st, {this.why = '', this.note = '', this.chk = ''});
  final String label;
  final double f;
  final String st;
  final String why, note, chk;
}

class WaterLog {
  WaterLog(this.k, this.n0, this.last, this.e);
  String k;
  int? n0;
  int last;
  List<List<int>> e; // [ms, glasses]
  Map<String, dynamic> toJson() => {'k': k, 'n0': n0, 'last': last, 'e': e};
  static WaterLog? fromJson(dynamic j) {
    if (j is! Map) return null;
    final e = <List<int>>[];
    if (j['e'] is List) {
      for (final x in j['e'] as List) {
        if (x is List && x.length == 2) e.add([(x[0] as num).toInt(), (x[1] as num).toInt()]);
      }
    }
    return WaterLog('${j['k'] ?? ''}', j['n0'] is num ? (j['n0'] as num).toInt() : null, (j['last'] as num?)?.toInt() ?? 0, e);
  }
}

class _WaterEval {
  _WaterEval(this.ok, this.rej, this.why, this.spread);
  final int ok, rej;
  final String why;
  final double spread;
}

_WaterEval _waterEval(WaterLog o, int goal) {
  var ok = math.min(o.n0 ?? 0, 4);
  var rej = math.max(0, (o.n0 ?? 0) - 4);
  var why = rej > 0 ? 'w_pre' : '';
  final hrs = <int>{};
  if ((o.n0 ?? 0) > 0) hrs.add(-1);
  final perH = <int, int>{};
  for (final x in o.e) {
    final hh = DateTime.fromMillisecondsSinceEpoch(x[0]).hour;
    var c = x[1];
    if (c > 2) {
      rej += c - 2;
      c = 2;
      why = 'w_burst';
    }
    if (hh < 6) {
      rej += c;
      why = 'w_night';
      continue;
    }
    final u = math.max(0, math.min(c, 4 - (perH[hh] ?? 0)));
    perH[hh] = (perH[hh] ?? 0) + u;
    if (u < c) {
      rej += c - u;
      why = 'w_hour';
    }
    ok += u;
    if (u > 0) hrs.add(hh);
  }
  return _WaterEval(math.min(ok, goal), rej, why, math.min(1.0, 0.4 + 0.15 * hrs.length));
}

int? _toMin(String at) {
  final p = at.split(':');
  if (p.length != 2) return null;
  final h = int.tryParse(p[0]), m = int.tryParse(p[1]);
  if (h == null || m == null) return null;
  return h * 60 + m;
}

Map<String, CatValue> verifyDay(ArenaDayInputs d, Div div, bool band, WaterLog wl, DateTime now) {
  final out = <String, CatValue>{};
  final phone = div == Div.phone;
  final nob = phone
      ? const CatValue('', 0, 'na', why: 'why_na')
      : const CatValue('', 0, 'wait', why: 'why_band');
  CatValue r(String label, double f, String chk, [String note = '']) =>
      CatValue(label, f.clamp(0.0, 1.0).toDouble(), f > 0 ? 'ok' : 'none', chk: chk, note: note);
  CatValue x(String label, String why) => CatValue(label, 0, 'rej', why: why);
  String n(num v) => afmt(v);

  // وەرزش
  var runM = 0, gymM = 0;
  var runKm = 0.0;
  var zt = [0, 0, 0, 0, 0];
  final rejR = <String>[], rejG = <String>[];
  for (final s in d.sessions) {
    final isRun = s.sportId == 'run' || s.sportId == 'treadmill' || s.sportId == 'tri';
    if (s.sportId == 'walk' || s.sportId == 'hike') continue;
    final bag = isRun ? rejR : rejG;
    if (s.minutes < 10) {
      bag.add('why_short');
      continue;
    }
    final z = List<int>.generate(5, (i) => i < s.hrZones.length ? s.hrZones[i] : 0);
    final zs = z.fold<int>(0, (a, b) => a + b), hard = z[2] + z[3] + z[4];
    if (!phone && zs >= 60 && hard / zs < 0.2) {
      bag.add('why_hrflat');
      continue;
    }
    if (isRun && s.sportId != 'treadmill') {
      if (s.km < 0.2) {
        bag.add('why_gps');
        continue;
      }
      final pace = s.minutes / s.km;
      if (pace < 2.8) {
        bag.add('why_fast');
        continue;
      }
      if (pace > 13) {
        bag.add('why_slow');
        continue;
      }
    }
    if (isRun) {
      runM += s.minutes;
      runKm += s.km;
    } else {
      gymM += s.minutes;
    }
    for (var i = 0; i < 5; i++) {
      zt[i] += z[i];
    }
  }
  runM = math.min(runM, 90);
  gymM = math.min(gymM, 90);

  // پیاسە
  final st = d.steps;
  if (phone) {
    out['walk'] = st > 40000 ? x(tr('u_steps', [n(st)]), 'why_steps') : r(tr('u_steps', [n(st)]), st / 10000, 'chk_walk_p');
  } else if (!band) {
    out['walk'] = CatValue(tr('band_off'), 0, nob.st, why: nob.why);
  } else {
    out['walk'] = st > 50000 ? x(tr('u_steps', [n(st)]), 'why_shake') : r(tr('u_steps', [n(st)]), st / 10000, 'chk_walk');
  }
  out['run'] = runM > 0
      ? r(tr('u_min_km', [runM, runKm.toStringAsFixed(1)]), runM / 30, 'chk_run')
      : rejR.isNotEmpty
          ? x(tr('rejected'), rejR.first)
          : r(tr('not_yet'), 0, '');
  out['gym'] = gymM > 0
      ? r(tr('u_min', [gymM]), gymM / 45, phone ? 'chk_gym_p' : 'chk_gym')
      : rejG.isNotEmpty
          ? x(tr('rejected'), rejG.first)
          : r(tr('not_yet'), 0, '');

  // خەو
  final sl = d.sleepHours;
  if (phone || !band) {
    out['sleep'] = CatValue(phone ? tr('band_only') : tr('band_off'), 0, nob.st, why: nob.why);
  } else {
    final lbl = tr('u_hm', ['${sl.floor()}:${_p2((sl % 1 * 60).round())}']);
    out['sleep'] = sl > 12 ? x(lbl, 'why_sleep12') : r(lbl, sl < 3 ? 0 : sl / 8, 'chk_sleep');
  }

  // خۆراک — ژەمەکان 90 خولەک لێک دوور، زۆرترین 3
  final nowM = now.hour * 60 + now.minute;
  var meals = 0, lastM = -999;
  var fRej = '';
  final ms = <List<int>>[];
  for (final m in d.meals) {
    final t = _toMin(m.at);
    if (t != null) ms.add([t, m.kcal]);
  }
  ms.sort((a, b) => a[0].compareTo(b[0]));
  for (final m in ms) {
    if (m[0] > nowM + 5) {
      fRej = 'why_future';
      continue;
    }
    if (m[1] < 40) continue;
    if (m[0] - lastM < 90) continue;
    meals++;
    lastM = m[0];
  }
  meals = math.min(meals, 3);
  out['food'] = meals > 0
      ? r(tr('u_meals', [meals]), meals / 3, 'chk_food', fRej)
      : fRej.isNotEmpty
          ? x(tr('rejected'), fRej)
          : r(tr('not_yet'), 0, '');

  // ئاو
  final goal = math.max(6, d.waterGoalGlasses);
  final we = _waterEval(wl, goal);
  final wl0 = tr('u_ml', [n(d.waterGlasses * 250), n(goal * 250)]);
  final wNote = we.rej > 0 ? tr('w_note', [n(we.rej * 250), tr(we.why)]) : (we.ok > 0 && we.spread < 1 ? tr('w_spread') : '');
  out['water'] = r(wl0, we.ok / goal * we.spread, 'chk_water', wNote);

  // دڵ
  final hz = ((zt[1] + zt[2] + zt[3]) / 60).round() + d.activeMinutes;
  if (phone || !band) {
    out['heart'] = CatValue(phone ? tr('band_only') : tr('band_off'), 0, nob.st, why: nob.why);
  } else if (hz > 0 && st < 300) {
    out['heart'] = x(tr('u_min', [hz]), 'why_hrstill');
  } else {
    out['heart'] = hz > 0 ? r(tr('u_active_rest', [hz, d.restHr]), hz / 30, 'chk_heart') : r(tr('u_rest', [d.restHr]), 0, '');
  }
  // ئۆکسجین، ئارامی، چاکبوونەوە
  if (phone || !band) {
    for (final id in ['o2', 'calm', 'rec']) {
      out[id] = CatValue(phone ? tr('band_only') : tr('band_off'), 0, nob.st, why: nob.why);
    }
  } else {
    out['o2'] = (d.spo2 < 80 || d.spo2 > 100)
        ? x('${d.spo2}%', 'why_read')
        : r('${d.spo2}%', d.spo2 >= 95 ? 1 : (d.spo2 - 88) / 7, 'chk_o2');
    out['calm'] = r(tr('u_stress', [d.stress]), (100 - d.stress) / 70, 'chk_calm');
    out['rec'] = (d.hrv < 10 || d.hrv > 200) ? x('HRV ${d.hrv}', 'why_hrv') : r('HRV ${d.hrv}', d.hrv / 70, 'chk_rec');
  }
  return out;
}

class PointRow {
  const PointRow(this.cat, this.cap, this.base, this.mult, this.pts);
  final ArenaCat cat;
  final int cap, base;
  final double mult;
  final int pts;
}

class DayPoints {
  const DayPoints(this.rows, this.tot, this.power, this.second);
  final List<PointRow> rows;
  final int tot;
  final String power, second;
}

String powerOf(String k) => kCats[_fnv('vex-power-$k') % kCats.length].id;
String secondOf(String k) {
  final a = powerOf(k);
  var i = _fnv('vex-2nd-$k') % kCats.length;
  if (kCats[i].id == a) i = (i + 1) % kCats.length;
  return kCats[i].id;
}

DayPoints dayPoints(Map<String, double> f, String k, Div d) {
  final p = powerOf(k), s2 = secondOf(k);
  final rows = <PointRow>[];
  var t = 0;
  for (final c in kCats) {
    final cap = capOf(c, d);
    final base = (cap * (f[c.id] ?? 0).clamp(0.0, 1.0)).round();
    final m = c.id == p ? 3.0 : c.id == s2 ? 1.5 : 1.0;
    final pts = (base * m).round();
    t += pts;
    rows.add(PointRow(c, cap, base, m, pts));
  }
  return DayPoints(rows, math.min(maxDay(d), t), p, s2);
}

// =============================================================================
// 6. هەژمار و پاشەکەوتکردن
// =============================================================================

class ArenaAccount {
  ArenaAccount({
    required this.name,
    required this.phone,
    required this.city,
    required this.age,
    required this.sn,
    required this.day,
    required this.pre,
    required this.at,
    required this.dv,
  });
  String name, phone, city, age, dv;
  int sn, day, at;
  bool pre;
  Map<String, dynamic> toJson() =>
      {'name': name, 'phone': phone, 'city': city, 'age': age, 'sn': sn, 'day': day, 'pre': pre, 'at': at, 'dv': dv};
  static ArenaAccount? fromJson(dynamic j) {
    if (j is! Map) return null;
    return ArenaAccount(
      name: '${j['name'] ?? ''}',
      phone: '${j['phone'] ?? ''}',
      city: '${j['city'] ?? ''}',
      age: '${j['age'] ?? 'a'}',
      sn: (j['sn'] as num?)?.toInt() ?? 0,
      day: (j['day'] as num?)?.toInt() ?? 0,
      pre: j['pre'] == true,
      at: (j['at'] as num?)?.toInt() ?? 0,
      dv: j['dv'] == 'phone' ? 'phone' : 'band',
    );
  }
}

class DayRec {
  DayRec(this.t, this.a, this.f);
  int t;
  bool a;
  Map<String, double> f;
  Map<String, dynamic> toJson() => {'t': t, 'a': a ? 1 : 0, 'f': f};
  static DayRec fromJson(dynamic j) {
    final m = <String, double>{};
    if (j is Map && j['f'] is Map) {
      (j['f'] as Map).forEach((k, v) => m['$k'] = (v as num).toDouble());
    }
    return DayRec(j is Map ? (j['t'] as num?)?.toInt() ?? 0 : 0, j is Map && (j['a'] == 1 || j['a'] == true), m);
  }
}

class CoinLog {
  CoinLog(this.t, this.c, this.k, this.at);
  final String t;
  int c;
  final String k;
  int at;
  Map<String, dynamic> toJson() => {'t': t, 'c': c, 'k': k, 'at': at};
}

class ArenaStore extends ChangeNotifier {
  static const String key = 'vex_arena_v4';

  ArenaAccount? acc;
  int coins = 0, season = 0, sn = 0, streak = 0, frz = 1, bestPower = 0, flag = 0, lt = 0, chAt = 0;
  String ch = '', skin = 'auto', title = 't0', bio = '', frzW = '', cb = '', gd = '', ad = '';
  bool cbP = false, eco = false, rmd = false;
  Set<String> chOwn = <String>{}, owned = <String>{}, rev = <String>{}, apl = <String>{};
  List<String> exc = <String>[];
  Map<String, String> guess = <String, String>{};
  Map<String, DayRec> days = <String, DayRec>{};
  Map<String, dynamic>? cd; // {k,c,act,pts,sn,paid}
  Map<String, dynamic>? chest; // {k,c}
  Map<String, dynamic>? wkr; // {k,r,n}
  List<CoinLog> clog = <CoinLog>[];
  WaterLog? wl;

  bool tamper = false;
  bool clockOk = true;
  bool loaded = false;
  SharedPreferences? _sp;

  void reset() {
    acc = null;
    coins = 0;
    season = 0;
    sn = 0;
    streak = 0;
    frz = 1;
    bestPower = 0;
    flag = 0;
    lt = 0;
    chAt = 0;
    ch = '';
    skin = 'auto';
    title = 't0';
    bio = '';
    frzW = '';
    cb = '';
    gd = '';
    ad = '';
    cbP = false;
    eco = false;
    rmd = false;
    chOwn = <String>{};
    owned = <String>{};
    rev = <String>{};
    apl = <String>{};
    exc = <String>[];
    guess = <String, String>{};
    days = <String, DayRec>{};
    cd = null;
    chest = null;
    wkr = null;
    clog = <CoinLog>[];
    wl = null;
    tamper = false;
    clockOk = true;
  }

  int _sig() => _fnv('vex·arena·${jsonEncode([
        coins,
        season,
        sn,
        chOwn.toList()..sort(),
        owned.toList()..sort(),
        acc?.phone,
        acc?.day,
        acc?.sn,
        streak,
        frz,
        bestPower,
        clog.length,
        days.length,
      ])}');

  Map<String, dynamic> toJson() => {
        'v': 4,
        'acc': acc?.toJson(),
        'coins': coins,
        'season': season,
        'sn': sn,
        'streak': streak,
        'frz': frz,
        'bestPower': bestPower,
        'flag': flag,
        'lt': lt,
        'chAt': chAt,
        'ch': ch,
        'skin': skin,
        'title': title,
        'bio': bio,
        'frzW': frzW,
        'cb': cb,
        'gd': gd,
        'ad': ad,
        'cbP': cbP,
        'eco': eco,
        'rmd': rmd,
        'chOwn': chOwn.toList(),
        'owned': owned.toList(),
        'rev': rev.toList(),
        'apl': apl.toList(),
        'exc': exc,
        'guess': guess,
        'days': days.map((k, v) => MapEntry(k, v.toJson())),
        'cd': cd,
        'chest': chest,
        'wkr': wkr,
        'clog': clog.map((e) => e.toJson()).toList(),
        'wl': wl?.toJson(),
        'sig': _sig(),
      };

  void _from(Map j) {
    acc = ArenaAccount.fromJson(j['acc']);
    int i(String k, [int d = 0]) => (j[k] as num?)?.toInt() ?? d;
    String s(String k, [String d = '']) => j[k] == null ? d : '${j[k]}';
    Set<String> ss(String k) => j[k] is List ? (j[k] as List).map((e) => '$e').toSet() : <String>{};
    coins = i('coins');
    season = i('season');
    sn = i('sn');
    streak = i('streak');
    frz = i('frz', 1);
    bestPower = i('bestPower');
    flag = i('flag');
    lt = i('lt');
    chAt = i('chAt');
    ch = s('ch');
    skin = s('skin', 'auto');
    title = s('title', 't0');
    bio = s('bio');
    frzW = s('frzW');
    cb = s('cb');
    gd = s('gd');
    ad = s('ad');
    cbP = j['cbP'] == true;
    eco = j['eco'] == true;
    rmd = j['rmd'] == true;
    chOwn = ss('chOwn');
    owned = ss('owned');
    rev = ss('rev');
    apl = ss('apl');
    exc = j['exc'] is List ? (j['exc'] as List).map((e) => '$e').toList() : <String>[];
    guess = j['guess'] is Map ? (j['guess'] as Map).map((k, v) => MapEntry('$k', '$v')) : <String, String>{};
    days = j['days'] is Map ? (j['days'] as Map).map((k, v) => MapEntry('$k', DayRec.fromJson(v))) : <String, DayRec>{};
    cd = j['cd'] is Map ? Map<String, dynamic>.from(j['cd'] as Map) : null;
    chest = j['chest'] is Map ? Map<String, dynamic>.from(j['chest'] as Map) : null;
    wkr = j['wkr'] is Map ? Map<String, dynamic>.from(j['wkr'] as Map) : null;
    clog = j['clog'] is List
        ? (j['clog'] as List)
            .whereType<Map>()
            .map((e) => CoinLog('${e['t']}', (e['c'] as num?)?.toInt() ?? 0, '${e['k']}', (e['at'] as num?)?.toInt() ?? 0))
            .toList()
        : <CoinLog>[];
    wl = WaterLog.fromJson(j['wl']);
  }

  Future<void> load() async {
    try {
      _sp ??= await SharedPreferences.getInstance();
      final raw = _sp!.getString(key);
      reset();
      if (raw != null) {
        final j = jsonDecode(raw);
        if (j is Map && j['v'] == 4) {
          _from(j);
          final sig = (j['sig'] as num?)?.toInt();
          if (sig != null && sig != _sig()) {
            // دەستکاری لە داتای پاشەکەوتکراو: سکە و خاڵ سفر دەبنەوە
            tamper = true;
            coins = 0;
            season = 0;
            chOwn = <String>{};
            owned = <String>{};
            clog = <CoinLog>[];
            flag++;
            cd = {'k': dayKey(DateTime.now()), 'c': 99, 'act': false, 'pts': 0, 'sn': 0, 'paid': 99};
          }
          if (lt > 0 && DateTime.now().millisecondsSinceEpoch < lt - 10 * 60000) clockOk = false;
        }
      }
    } catch (_) {
      reset();
    }
    loaded = true;
    notifyListeners();
  }

  Future<void> save() async {
    if (clockOk) lt = math.max(lt, DateTime.now().millisecondsSinceEpoch);
    try {
      _sp ??= await SharedPreferences.getInstance();
      await _sp!.setString(key, jsonEncode(toJson()));
    } catch (_) {}
    notifyListeners();
  }

  void log(String t, int c, String k) {
    clog.insert(0, CoinLog(t, c, k, DateTime.now().millisecondsSinceEpoch));
    if (clog.length > 30) clog = clog.sublist(0, 30);
  }
}

// =============================================================================
// 7. کۆنترۆڵەر — هەموو ژماردنەکان لێرەن
// =============================================================================

class APlayer {
  APlayer({
    required this.id,
    required this.n,
    required this.city,
    required this.age,
    required this.ch,
    required this.dv,
    required this.p,
    required this.wp,
    required this.st,
    required this.gp,
    required this.skin,
    required this.title,
    required this.stats,
    required this.pre,
    required this.at,
    this.me = false,
  });
  final String id, n, city, age, ch, skin, title;
  final Div dv;
  final int p, wp, st, gp, at;
  final List<int> stats;
  final bool pre, me;
  int r = 0;
}

class WeekInfo {
  const WeekInfo(this.i, this.k, this.left, this.start);
  final int i, left;
  final String k;
  final DateTime start;
}

WeekInfo weekInfo(DateTime now) {
  final i = (now.weekday % 7 + 1) % 7; // شەممە = 0
  final st = _dayStart(now).subtract(Duration(days: i));
  return WeekInfo(i, dayKey(st), 6 - i, st);
}

int weekReward(int r) => r == 1 ? 50 : r == 2 ? 30 : r == 3 ? 20 : r <= 10 ? 15 : 0;

class Mission {
  const Mission(this.cat, this.target, this.v, this.key);
  final ArenaCat cat;
  final int target, v;
  final String key;
  bool get ok => v >= target;
}

const List<List<Object>> _kMissions = [
  ['walk', 30, 'ms_walk'], ['sleep', 40, 'ms_sleep'], ['water', 15, 'ms_water'], ['calm', 25, 'ms_calm'],
  ['o2', 15, 'ms_o2'], ['rec', 25, 'ms_rec'], ['food', 10, 'ms_food'], ['heart', 20, 'ms_heart'],
  ['gym', 20, 'ms_gym'], ['run', 20, 'ms_run'],
];

// 10 بەشداربووی نموونە (7 لە لیگی Band، 3 لە لیگی مۆبایل)
const List<List<Object>> _kSample = [
  ['s01', 'ئاراس کەریم', 'هەولێر', 'a', '21', 'band', 548, 'holo'],
  ['s02', 'سارا ئەحمەد', 'سلێمانی', 'a', '09', 'band', 521, 'royal'],
  ['s03', 'هێمن ڕەشید', 'دهۆک', 'm', '27', 'band', 497, 'zagros'],
  ['s04', 'ڤیان عەلی', 'کەرکووک', 'a', '11', 'band', 462, 'kurd'],
  ['s05', 'دانا سەعید', 'هەڵەبجە', 'a', '17', 'band', 430, 'neon'],
  ['s06', 'ڕێبین حەسەن', 'زاخۆ', 'y', '25', 'band', 388, 'night'],
  ['s07', 'ژیلا مەحموود', 'کۆیە', 'm', '10', 'band', 341, 'marble'],
  ['s08', 'ئازاد قادر', 'سۆران', 'a', '26', 'phone', 164, 'carbon'],
  ['s09', 'لانە جەمال', 'ڕانیە', 'a', '06', 'phone', 141, 'auto'],
  ['s10', 'کارزان عومەر', 'چەمچەماڵ', 'm', '12', 'phone', 118, 'auto'],
];

class ArenaEvent {
  const ArenaEvent(this.text, this.icon, {this.confetti = false});
  final String text;
  final String icon;
  final bool confetti;
}

class ArenaCtl extends ChangeNotifier {
  ArenaCtl(this.host, this.store);
  final ArenaHost host;
  final ArenaStore store;

  SeasonNow S = seasonNow();
  DateTime now = DateTime.now();
  Map<String, CatValue> data = {};
  DayPoints today = dayPoints(const {}, '', Div.band);
  DateTime lastSync = DateTime.now();
  final List<ArenaEvent> events = [];
  bool _dirty = false;

  String get tk => dayKey(now);
  String get yk => dayKey(now.subtract(const Duration(days: 1)));
  Div get div => store.acc != null ? divOf(store.acc!.dv) : (host.hasBand ? Div.band : Div.phone);
  bool get live => S.live;
  bool get regd => store.acc != null && store.acc!.sn == S.n;
  bool get founder => regd && store.acc!.pre;
  int get active => activeMin(div);

  void refresh() {
    now = DateTime.now();
    S = seasonNow(now);
    _divCheck();
    final inp = host.today();
    _water(inp);
    data = verifyDay(inp, div, host.bandConnected, store.wl!, now);
    today = dayPoints({for (final e in data.entries) e.key: e.value.st == 'ok' ? e.value.f : 0.0}, tk, div);
    _seasonStart();
    _reveal();
    _settle();
    _track();
    lastSync = now;
    if (_dirty) {
      _dirty = false;
      store.save();
    }
    notifyListeners();
  }

  void _divCheck() {
    final a = store.acc;
    if (a != null && a.dv == 'phone' && host.hasBand) {
      a.dv = 'band';
      _dirty = true;
      events.add(ArenaEvent(tr('ev_band'), 'shield', confetti: true));
    }
  }

  void _water(ArenaDayInputs d) {
    final dk = tk;
    var o = store.wl;
    if (o == null || o.k != dk) {
      o = WaterLog(dk, null, 0, []);
      _dirty = true;
    }
    final n = d.waterGlasses;
    if (o.n0 == null) {
      o.n0 = n;
      o.last = n;
      _dirty = true;
    } else if (n > o.last) {
      o.e.add([now.millisecondsSinceEpoch, n - o.last]);
      o.last = n;
      _dirty = true;
    } else if (n < o.last) {
      var r = o.last - n;
      while (r > 0 && o.e.isNotEmpty) {
        final x = o.e.last;
        final k = math.min(r, x[1]);
        x[1] -= k;
        r -= k;
        if (x[1] == 0) o.e.removeLast();
      }
      if (r > 0) o.n0 = math.max(0, (o.n0 ?? 0) - r);
      o.last = n;
      _dirty = true;
    }
    store.wl = o;
  }

  void _seasonStart() {
    if (!live || store.acc == null || store.acc!.sn != S.n) return;
    if (store.sn != S.n) {
      store.sn = S.n;
      store.season = 0;
      store.exc = <String>[];
      _dirty = true;
    }
  }

  void _reveal() {
    for (final k in store.guess.keys.toList()) {
      if (store.rev.contains(k) || k == tk) continue;
      final p = k.split('-').map(int.tryParse).toList();
      if (p.length != 3 || p.contains(null)) continue;
      final at = DateTime(p[0]!, p[1]!, p[2]! + 1, 6);
      if (now.isBefore(at)) continue;
      store.rev.add(k);
      _dirty = true;
      if (store.guess[k] == powerOf(k) && store.clockOk) {
        store.bestPower++;
        store.coins += 10;
        store.log('guess', 10, k);
        if (live && regd && store.sn == S.n) store.season += 50;
        events.add(ArenaEvent(tr('ev_guess'), 'crystal', confetti: true));
      }
    }
  }

  void _settle() {
    final st = store;
    if (!st.eco) {
      st.eco = true;
      st.cd = null;
      st.streak = 0;
      _dirty = true;
    }
    final W = weekInfo(now);
    if (st.frzW != W.k) {
      final w = st.wkr;
      if (st.frzW.isNotEmpty && w != null && w['k'] == st.frzW && (w['n'] as num? ?? 0) >= 5 && st.clockOk) {
        final c = weekReward((w['r'] as num? ?? 99).toInt());
        if (c > 0) {
          st.coins += c;
          st.log('week', c, st.frzW);
        }
      }
      st.frz = math.min(2, st.frz + 1);
      st.frzW = W.k;
      _dirty = true;
    }
    final cd = st.cd;
    if (cd != null && cd['k'] != tk) {
      final rest = ((cd['c'] as num?) ?? 0).toInt() - ((cd['paid'] as num?) ?? 0).toInt();
      if (rest > 0) {
        st.coins += rest;
        _dayLog(((cd['c'] as num?) ?? 0).toInt(), '${cd['k']}');
      }
      final pts = ((cd['pts'] as num?) ?? 0).toInt();
      if (pts > 0 && cd['sn'] == st.sn) st.season += pts;
      if (cd['act'] == true) {
        st.streak++;
        if (st.streak % 7 == 0) {
          st.coins += 15;
          st.log('streak', 15, '${cd['k']}');
        }
      } else {
        if (st.exc.contains('${cd['k']}')) {
        } else if (st.frz > 0) {
          st.frz--;
          st.log('freeze', 0, '${cd['k']}');
        } else {
          st.streak = 0;
        }
        st.cbP = true;
      }
      st.cd = null;
      _dirty = true;
    }
  }

  void _dayLog(int c, String k) {
    for (final e in store.clog) {
      if (e.t == 'day' && e.k == k) {
        e.c = c;
        e.at = DateTime.now().millisecondsSinceEpoch;
        return;
      }
    }
    store.log('day', c, k);
  }

  int get coinsToday => math.min(coinMax(div), today.tot ~/ 25);

  void _track() {
    final st = store;
    if (st.acc == null) return;
    if (st.cbP && today.tot >= active) {
      st.cbP = false;
      st.cb = tk;
      _dirty = true;
      events.add(ArenaEvent(tr('ev_back'), 'star'));
    }
    final c = coinsToday, a = today.tot >= active;
    final pts = live && regd ? myTotal - seasonPts : 0;
    final cd = st.cd;
    final paid = cd != null && cd['k'] == tk ? ((cd['paid'] as num?) ?? 0).toInt() : 0;
    var pay = paid;
    if (c > paid && st.clockOk) {
      st.coins += c - paid;
      _dayLog(c, tk);
      pay = c;
      events.add(ArenaEvent('+${c - paid}', 'coin'));
    }
    final nc = {'k': tk, 'c': c, 'act': a, 'pts': pts, 'sn': pts > 0 ? S.n : 0, 'paid': math.max(pay, paid)};
    if (cd == null || jsonEncode(cd) != jsonEncode(nc)) {
      st.cd = nc;
      _dirty = true;
    }
    final f = <String, double>{for (final r in today.rows) r.cat.id: r.cap > 0 ? (r.base / r.cap * 100).round() / 100 : 0.0};
    final old = st.days[tk];
    if (old == null || old.t != today.tot || old.a != a || jsonEncode(old.f) != jsonEncode(f)) {
      st.days[tk] = DayRec(today.tot, a, f);
      if (st.days.length > 45) {
        final ks = st.days.keys.toList()..sort((x, y) => _kd(x).compareTo(_kd(y)));
        for (final k in ks.take(st.days.length - 45)) {
          st.days.remove(k);
        }
      }
      _dirty = true;
    }
    if (a && st.ad != tk && today.tot < goal) {
      st.ad = tk;
      _dirty = true;
      events.add(ArenaEvent(tr('ev_counted'), 'check'));
    }
    if (today.tot >= goal && st.gd != tk) {
      st.gd = tk;
      st.ad = tk;
      _dirty = true;
      events.add(ArenaEvent(tr('ev_goal'), 'star', confetti: true));
    }
  }

  DateTime _kd(String k) {
    final p = k.split('-').map((e) => int.tryParse(e) ?? 1).toList();
    return p.length == 3 ? DateTime(p[0], p[1], p[2]) : DateTime(2000);
  }

  // ---- خاڵ ----
  int get seasonPts => live && regd && store.sn == S.n ? store.season : 0;
  int get myTotal => !live ? 0 : seasonPts + today.tot + (store.cb == tk ? 50 : 0);

  int get activeDays {
    if (!live || store.acc == null) return 0;
    final joined = DateTime.fromMillisecondsSinceEpoch(store.acc!.at);
    var n = 0;
    store.days.forEach((k, r) {
      final d = _kd(k).add(const Duration(hours: 23, minutes: 59));
      if (r.a && !d.isBefore(S.start) && !d.isBefore(_dayStart(joined)) && d.isBefore(S.end.add(const Duration(days: 1)))) n++;
    });
    return n;
  }

  int get joinDay => store.acc == null ? S.day : (store.acc!.sn == S.n ? store.acc!.day : S.day);
  int get daysSinceJoin => math.max<int>(1, S.day - math.max<int>(1, joinDay) + 1);
  int get avgDaily => math.max((active * 0.8).round(), (seasonPts / math.max<int>(1, daysSinceJoin - 1)).round());
  int get goal => math.min(maxDay(div) ~/ 2, math.max(active, ((avgDaily * 1.1) / 10).round() * 10));

  int weekPts() {
    final W = weekInfo(now);
    var t = 0;
    for (var j = 0; j < W.i; j++) {
      final r = store.days[dayKey(W.start.add(Duration(days: j)))];
      if (r != null) t += r.t;
    }
    return t + today.tot + (store.cb == tk ? 50 : 0);
  }

  List<int> myStats() {
    const ids = ['walk', 'run', 'sleep', 'food', 'heart', 'calm'];
    final ks = store.days.keys.where((k) => k != tk).toList()..sort((a, b) => _kd(a).compareTo(_kd(b)));
    final last = ks.length > 6 ? ks.sublist(ks.length - 6) : ks;
    return [
      for (final id in ids)
        () {
          final v = [for (final k in last) store.days[k]!.f[id] ?? 0.0];
          final d = data[id];
          v.add(d != null && d.st == 'ok' ? d.f : 0.0);
          return math.min(99, (45 + v.fold<double>(0, (a, b) => a + b) / v.length * 54).round());
        }()
    ];
  }

  String get myTitle => tr('ti_${store.title}');

  // ---- بەشداربووان ----
  List<APlayer> players() {
    final out = <APlayer>[];
    final W = weekInfo(now);
    if (live) {
      for (var i = 0; i < _kSample.length; i++) {
        final x = _kSample[i];
        final R = _Seeded('smp${x[0]}$tk');
        final base = x[6] as int;
        final f = 0.85 + R.next() * 0.15;
        out.add(APlayer(
          id: x[0] as String,
          n: x[1] as String,
          city: x[2] as String,
          age: x[3] as String,
          ch: x[4] as String,
          dv: divOf(x[5] as String),
          p: (base * S.day * (S.day == 1 ? 1 : f)).round(),
          wp: (base * math.min(S.day, W.i + 1) * (S.day == 1 ? 1 : f)).round(),
          st: math.min(S.day, 1 + (R.next() * 3).floor()),
          gp: (R.next() * 2).floor(),
          skin: x[7] as String,
          title: ['t0', 't1', 't2'][i % 3],
          stats: [for (final v in [55, 45, 60, 50, 58, 52]) math.min(99, v + (R.next() * 20).floor())],
          pre: i < 6,
          at: S.start.millisecondsSinceEpoch - (10 - i) * 3600000,
        ));
      }
    }
    final a = store.acc;
    if (regd && a != null) {
      out.add(APlayer(
        id: 'me',
        n: a.name,
        city: a.city,
        age: a.age,
        ch: store.ch,
        dv: div,
        p: myTotal,
        wp: weekPts(),
        st: store.streak,
        gp: store.bestPower,
        skin: store.skin,
        title: store.title,
        stats: myStats(),
        pre: a.pre,
        at: a.at,
        me: true,
      ));
    }
    out.sort((x, y) => y.p != x.p ? y.p.compareTo(x.p) : x.at.compareTo(y.at));
    final n = {Div.band: 0, Div.phone: 0};
    for (final p in out) {
      n[p.dv] = n[p.dv]! + 1;
      p.r = n[p.dv]!;
    }
    return out;
  }

  List<APlayer> divPlayers([Div? d]) => players().where((x) => x.dv == (d ?? div)).toList();
  int rankOf(int p) => 1 + divPlayers().where((x) => !x.me && x.p > p).length;
  int ptsAt(int r, Div d) {
    final l = divPlayers(d);
    return r - 1 < l.length ? l[r - 1].p : 0;
  }

  List<APlayer> weekGroup() {
    final l = divPlayers();
    final rows = [
      for (final x in l)
        APlayer(
            id: x.id, n: x.n, city: x.city, age: x.age, ch: x.ch, dv: x.dv, p: x.me ? weekPts() : x.wp, wp: x.wp,
            st: x.st, gp: x.gp, skin: x.skin, title: x.title, stats: x.stats, pre: x.pre, at: x.at, me: x.me)
    ]..sort((x, y) => y.p != x.p ? y.p.compareTo(x.p) : (x.me ? -1 : 1));
    final g = rows.take(30).toList();
    for (var i = 0; i < g.length; i++) {
      g[i].r = i + 1;
    }
    if (live && regd) {
      final me = g.where((x) => x.me).toList();
      if (me.isNotEmpty) {
        final w = {'k': weekInfo(now).k, 'r': me.first.r, 'n': g.length};
        if (jsonEncode(store.wkr) != jsonEncode(w)) {
          store.wkr = w;
          _dirty = true;
        }
      }
    }
    return g;
  }

  List<Mission> missions() {
    final R = _Seeded('ms$tk');
    final pool = _kMissions.where((m) => capOf(catById(m[0] as String), div) >= (m[1] as int)).toList();
    final out = <Mission>[];
    while (out.length < 3 && pool.isNotEmpty) {
      final m = pool.removeAt((R.next() * pool.length).floor() % pool.length);
      final row = today.rows.firstWhere((r) => r.cat.id == m[0]);
      out.add(Mission(row.cat, m[1] as int, math.min(m[1] as int, row.base), m[2] as String));
    }
    return out;
  }

  int get chestAmount => 5 + _fnv('chest$tk${store.acc?.name ?? ''}') % 21;
  bool get chestOpen => store.chest != null && store.chest!['k'] == tk;

  List<PointRow> bestMoves() {
    final l = today.rows.where((r) => r.cap > 0 && r.cap - r.base > 0 && !const ['sleep', 'o2', 'rec'].contains(r.cat.id)).toList()
      ..sort((a, b) => (b.cap - b.base).compareTo(a.cap - a.base));
    return l.take(3).toList();
  }

  /// قەڵغانی هەفتە: 'ok' 'x' 'now' 'fut'
  List<String> shield() {
    final W = weekInfo(now);
    final joined = store.acc?.at ?? now.millisecondsSinceEpoch;
    return [
      for (var j = 0; j < 7; j++)
        () {
          final d = W.start.add(Duration(days: j));
          if (j < W.i) {
            if (d.add(const Duration(hours: 23, minutes: 59)).millisecondsSinceEpoch < joined) return 'fut';
            final r = store.days[dayKey(d)];
            return (r != null && r.a) || store.exc.contains(dayKey(d)) ? 'ok' : 'x';
          }
          return j == W.i ? (today.tot >= goal ? 'ok' : 'now') : 'fut';
        }()
    ];
  }

  // ---- کارەکان ----
  void register({required String name, required String phone, required String city, required String age, required String ch}) {
    final st = store;
    st.acc = ArenaAccount(
      name: name,
      phone: phone,
      city: city,
      age: age,
      sn: S.n,
      day: live ? S.day : 0,
      pre: !live,
      at: DateTime.now().millisecondsSinceEpoch,
      dv: host.hasBand ? 'band' : 'phone',
    );
    if (ch.isNotEmpty) {
      st.ch = ch;
      st.chAt = DateTime.now().millisecondsSinceEpoch;
    }
    st.coins += 20;
    st.log('welcome', 20, tk);
    if (live) {
      st.sn = S.n;
      st.season = 0;
    } else {
      st.coins += 30;
      st.log('founder', 30, tk);
    }
    _dirty = true;
    refresh();
  }

  void logout() {
    store.reset();
    store.eco = false;
    _dirty = true;
    refresh();
  }

  void guessPower(String id) {
    if (store.guess[tk] != null) return;
    store.guess[tk] = id;
    _dirty = true;
    refresh();
  }

  bool openChest() {
    if (chestOpen || missions().where((m) => m.ok).length < 3) return false;
    final c = chestAmount;
    store.chest = {'k': tk, 'c': c};
    store.coins += c;
    store.log('chest', c, tk);
    _dirty = true;
    refresh();
    return true;
  }

  bool buyFreeze() {
    if (store.frz >= 2 || store.coins < 30) return false;
    store.coins -= 30;
    store.frz++;
    store.log('frzbuy', -30, tk);
    _dirty = true;
    refresh();
    return true;
  }

  bool useExcuse() {
    if (store.exc.length >= 3 || store.exc.contains(tk) || today.tot >= active) return false;
    store.exc.add(tk);
    _dirty = true;
    refresh();
    return true;
  }

  /// گۆڕینی کارەکتەر: یەکەم جار بەخۆڕایی · دواتر یەکجار لە 30 ڕۆژدا · لە کاتی وەرزدا داخراوە
  String charState() {
    if (store.ch.isEmpty) return 'first';
    if (live && regd) return 'live';
    final left = store.chAt + kCharLock.inMilliseconds - now.millisecondsSinceEpoch;
    return left > 0 ? 'wait' : 'ok';
  }

  int get charDaysLeft => math.max(0, ((store.chAt + kCharLock.inMilliseconds - now.millisecondsSinceEpoch) / 86400000).ceil());
  bool charOwned(String id) => charCost(id) == 0 || store.chOwn.contains(id);

  bool buyChar(String id) {
    final c = charCost(id);
    if (charOwned(id) || store.coins < c) return false;
    store.coins -= c;
    store.chOwn.add(id);
    store.log('char', -c, tk);
    _dirty = true;
    refresh();
    return true;
  }

  bool setChar(String id) {
    final s = charState();
    if ((s != 'first' && s != 'ok') || !charOwned(id)) return false;
    store.ch = id;
    store.chAt = DateTime.now().millisecondsSinceEpoch;
    _dirty = true;
    refresh();
    return true;
  }

  bool skinOwned(CardSkin s) {
    if (s.lg > 0) return leagueIndex(leagueOf(myTotal, div)) >= s.lg;
    return s.cost == 0 || store.owned.contains('skin:${s.id}');
  }

  bool buySkin(CardSkin s) {
    if (skinOwned(s) || s.lg > 0 || store.coins < s.cost) return false;
    store.coins -= s.cost;
    store.owned.add('skin:${s.id}');
    store.log('buy', -s.cost, tk);
    store.skin = s.id;
    _dirty = true;
    refresh();
    return true;
  }

  void useSkin(CardSkin s) {
    if (!skinOwned(s)) return;
    store.skin = s.id;
    _dirty = true;
    refresh();
  }

  bool titleOk(String id) {
    final req = kTitles.firstWhere((t) => t[0] == id, orElse: () => kTitles.first)[1] as int;
    return req == 0 || (req == 1 && store.bestPower >= 1) || (req == 5 && myTotal >= 7500);
  }

  /// مێدالیاکان: [ئایکۆن، کلیل، کراوە؟، ڕەنگ]
  List<List<Object>> badges() {
    final t = myTotal;
    return [
      ['rocket', 'bd_first', store.acc != null, const Color(0xFF3CF08A)],
      ['fire', 'bd_7', live && activeDays >= 7, const Color(0xFFFF9466)],
      ['crystal', 'bd_guess', store.bestPower >= 1, const Color(0xFFA58CFF)],
      ['target', 'bd_guess3', store.bestPower >= 3, const Color(0xFFFF6F86)],
      ['sleep', 'bd_sleep', false, const Color(0xFF9B7BFF)],
      ['food', 'bd_food', false, const Color(0xFFFFBE4D)],
      ['run', 'bd_50km', false, const Color(0xFFFF9466)],
      ['trophy', 'bd_gold', t >= 1500, const Color(0xFFE6B13A)],
      ['water', 'bd_water', false, const Color(0xFF2FB8F3)],
      ['calm', 'bd_calm', false, const Color(0xFFA58CFF)],
      ['users', 'bd_5f', false, const Color(0xFF3FD69A)],
      ['crown', 'bd_legend', t >= 7500, const Color(0xFFFF5577)],
    ];
  }

  void setTitle(String id) {
    if (!titleOk(id)) return;
    store.title = id;
    _dirty = true;
    refresh();
  }

  void editProfile(String name, String bio) {
    final a = store.acc;
    if (a == null) return;
    if (name.trim().length >= 2) a.name = name.trim().length > 24 ? name.trim().substring(0, 24) : name.trim();
    store.bio = bio.trim().length > 60 ? bio.trim().substring(0, 60) : bio.trim();
    _dirty = true;
    refresh();
  }

  void appeal(String id) {
    store.apl.add('$id$tk');
    _dirty = true;
    refresh();
  }
}

// =============================================================================
// 8. ناوی لاتینی (بۆ English و Türkçe)
// =============================================================================

const Map<String, String> _kLatin = {
  'هەولێر': 'Erbil', 'سلێمانی': 'Sulaymaniyah', 'دهۆک': 'Duhok', 'کەرکووک': 'Kirkuk', 'هەڵەبجە': 'Halabja',
  'زاخۆ': 'Zakho', 'ڕانیە': 'Ranya', 'کۆیە': 'Koya', 'سۆران': 'Soran', 'چەمچەماڵ': 'Chamchamal', 'ئاکرێ': 'Akre',
  'ئامێدی': 'Amedi', 'شێخان': 'Shekhan', 'سمێل': 'Semel', 'شەقڵاوە': 'Shaqlawa', 'ڕواندز': 'Rawanduz',
  'مێرگەسور': 'Mergasur', 'قەڵادزێ': 'Qaladze', 'پێنجوێن': 'Penjwen', 'سەیدسادق': 'Sayid Sadiq',
  'دەربەندیخان': 'Darbandikhan', 'کەلار': 'Kalar', 'کفری': 'Kifri', 'خانەقین': 'Khanaqin', 'دووکان': 'Dukan',
  'دەبەگ': 'Debaga', 'مەخموور': 'Makhmur', 'شنگال': 'Sinjar', 'خورماتوو': 'Tuz Khurmatu', 'تەلکێف': 'Tel Keppe',
  'بەغدا': 'Baghdad', 'موسڵ': 'Mosul', 'بەسرە': 'Basra', 'نەجەف': 'Najaf', 'کەربەلا': 'Karbala', 'ئەنبار': 'Anbar',
  'دیالە': 'Diyala', 'تکریت': 'Tikrit', 'کووت': 'Kut', 'عەمارە': 'Amarah',
  'سەرسەنگ': 'Sarsang', 'بەردەڕەش': 'Bardarash', 'دیانا': 'Diana', 'پشدەر': 'Pshdar', 'بێتواتە': 'Betwata', 'سیتەک': 'Sitak',
  'جەلەولا': 'Jalawla', 'قەرەتەپە': 'Qaratapa', 'تاقتاق': 'Taqtaq', 'حەویجە': 'Hawija', 'تەلعەفەر': 'Tal Afar',
  'تۆزخورماتوو': 'Tuz', 'بەعشیقە': 'Bashiqa', 'عەقرە': 'Aqrah', 'زێباری': 'Zebar', 'قۆشتەپە': 'Qushtapa', 'مەهاباد': 'Mahabad',
  'سنە': 'Sanandaj', 'کرماشان': 'Kermanshah', 'ورمێ': 'Urmia', 'بانە': 'Baneh', 'مەریوان': 'Marivan', 'سەقز': 'Saqqez',
  'بۆکان': 'Bukan', 'پیرانشار': 'Piranshahr', 'نەغەدە': 'Naqadeh', 'ئیلام': 'Ilam', 'دیاربەکر': 'Diyarbakır', 'وان': 'Van',
  'ماردین': 'Mardin', 'باتمان': 'Batman', 'هەکاری': 'Hakkari', 'جزیر': 'Cizre', 'ئورفە': 'Urfa', 'قامیشلۆ': 'Qamishli',
  'کۆبانی': 'Kobani', 'عەفرین': 'Afrin', 'دێرک': 'Derik', 'عامودا': 'Amuda', 'حەسەکە': 'Hasakah', 'سەرێکانی': 'Serêkaniyê',
  'تەبریز': 'Tabriz', 'تاران': 'Tehran', 'هەمەدان': 'Hamadan',
  'ئاراس کەریم': 'Aras Karim', 'سارا ئەحمەد': 'Sara Ahmad', 'هێمن ڕەشید': 'Hemin Rashid', 'ڤیان عەلی': 'Vian Ali',
  'دانا سەعید': 'Dana Saeed', 'ڕێبین حەسەن': 'Rebin Hasan', 'ژیلا مەحموود': 'Zhila Mahmood', 'ئازاد قادر': 'Azad Qadir',
  'لانە جەمال': 'Lana Jamal', 'کارزان عومەر': 'Karzan Omar',
};

/// ناوی شار یان کەس بەپێی زمان
String nm(String s) => arenaLtr ? (_kLatin[s] ?? s) : s;


// =============================================================================
// 9. ئامرازە هاوبەشەکانی ڕووکار
// =============================================================================

String _hex(Color c) => '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';

final Map<String, String> _svgCache = {};

/// ئایکۆنی وێب (هەمان SVG)
class AIcon extends StatelessWidget {
  const AIcon(this.name, {super.key, this.size = 18, this.color, this.sw = 1.8});
  final String name;
  final double size;
  final Color? color;
  final double sw;
  @override
  Widget build(BuildContext context) {
    final c = color ?? DefaultTextStyle.of(context).style.color ?? AC.tx;
    final op = c.a;
    final k = '$name|${_hex(c)}|$sw';
    final svg = _svgCache[k] ??=
        '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="${_hex(c)}" stroke-width="$sw" stroke-linecap="round" stroke-linejoin="round">${(kArenaIco[name] ?? '').replaceAll('currentColor', _hex(c))}</svg>';
    final w = SvgPicture.string(svg, width: size, height: size);
    return op < .99 ? Opacity(opacity: op, child: w) : w;
  }
}

/// تایلی بەش (.tl)
class CatTile extends StatelessWidget {
  const CatTile(this.icon, this.k, {super.key, this.size = 40, this.idle = false, this.strong = false});
  CatTile.cat(ArenaCat c, {Key? key, double size = 40, bool idle = false, bool strong = false})
      : this(c.icon, c.color, key: key, size: size, idle: idle, strong: strong);
  final String icon;
  final Color k;
  final double size;
  final bool idle, strong;
  @override
  Widget build(BuildContext context) {
    var c1 = _mix(k, Colors.white, .88), c2 = _mix(k, const Color(0xFF001418), .58);
    if (idle) {
      c1 = _desat(c1, .45, .9);
      c2 = _desat(c2, .45, .9);
    }
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * .32),
        gradient: cssLin(145, [c1, c2]),
        boxShadow: idle ? null : [strong ? cssSh(0, 10, 20, -10, k) : cssSh(0, 6, 14, -8, k)],
        border: Border(top: BorderSide(color: Colors.white.withAlpha(strong ? 115 : 89), width: 1)),
      ),
      alignment: Alignment.center,
      child: AIcon(icon, size: (size * .54).roundToDouble(), color: Colors.white),
    );
  }
}

Color _desat(Color c, double s, double b) {
  final h = HSLColor.fromColor(c);
  return h.withSaturation(h.saturation * s).withLightness((h.lightness * b).clamp(0.0, 1.0)).toColor();
}

/// نیشانەی لیگ (قەڵغان)
class Emblem extends StatelessWidget {
  const Emblem(this.i, {super.key, this.size = 24});
  final int i;
  final double size;
  @override
  Widget build(BuildContext context) =>
      SvgPicture.string(kArenaEmb[i.clamp(0, kArenaEmb.length - 1)], width: size, height: (size * 56 / 48).roundToDouble());
}

/// وێنەی کارەکتەر لە بازنەدا (.ava.chv)
class CharAvatar extends StatelessWidget {
  const CharAvatar({super.key, required this.ch, required this.name, this.size = 40, this.ring, this.gold = false});
  final String ch, name;
  final double size;
  final Color? ring;
  final bool gold;
  @override
  Widget build(BuildContext context) {
    final ini = name.trim().isEmpty ? '?' : name.trim().characters.first;
    final fallback = Center(child: Text(ini, style: ats(size * .38, w: FontWeight.w800, c: Colors.white)));
    final inner = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: const Alignment(0, -.52),
          radius: .9,
          colors: gold
              ? const [Color(0xFFFFF3C4), Color(0xFFF2B21C), Color(0xFF8A5A06)]
              : const [Color(0xFFE3FCFF), Color(0xFF2FE6F3), Color(0xFF0B5F73)],
          stops: const [0, .7, 1],
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: ch.isEmpty
          ? fallback
          : OverflowBox(
              maxWidth: size * 1.12,
              maxHeight: size * 1.12,
              alignment: Alignment.bottomCenter,
              child: Transform.translate(
                offset: Offset(0, size * .04),
                child: Image.asset(charAsset(ch),
                    width: size * 1.12,
                    height: size * 1.12,
                    fit: BoxFit.contain,
                    alignment: Alignment.bottomCenter,
                    filterQuality: FilterQuality.medium,
                    gaplessPlayback: true,
                    errorBuilder: (_, __, ___) => fallback),
              ),
            ),
    );
    if (ring == null) return inner;
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(shape: BoxShape.circle, color: ring),
      child: Container(
          padding: const EdgeInsets.all(2), decoration: BoxDecoration(shape: BoxShape.circle, color: AC.bg), child: inner),
    );
  }
}

/// سکە (.cn)
class _Coin extends StatelessWidget {
  const _Coin(this.s);
  final double s;
  @override
  Widget build(BuildContext context) => Container(
        width: s,
        height: s,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: cssLin(135, const [Color(0xFFFFF3C4), Color(0xFFFFD56B), Color(0xFFD9971F)], const [0, .45, 1]),
          boxShadow: const [BoxShadow(color: Color(0x40FFD56B), spreadRadius: 2)],
        ),
        alignment: Alignment.center,
        child: AIcon('star', size: (s * .58).roundToDouble(), color: const Color(0xFF6B4300), sw: 2.2),
      );
}

class _Tap extends StatelessWidget {
  const _Tap({required this.child, this.onTap, this.radius = 16});
  final Widget child;
  final VoidCallback? onTap;
  final double radius;
  @override
  Widget build(BuildContext context) => Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(radius),
          onTap: onTap == null
              ? null
              : () {
                  HapticFeedback.selectionClick();
                  onTap!();
                },
          child: child,
        ),
      );
}

/// دوگمە: p زێڕ · s ئاسایی · d سوور
class _Btn extends StatelessWidget {
  const _Btn(this.label, {this.icon, this.lead, this.onTap, this.kind = 'p', this.h = 52, this.trail});
  final String label;
  final String? icon;
  final Widget? lead, trail;
  final VoidCallback? onTap;
  final String kind;
  final double h;
  @override
  Widget build(BuildContext context) {
    final off = onTap == null;
    final p = kind == 'p', d = kind == 'd';
    final fg = p ? AC.onGold : (d ? AC.coral : AC.tx);
    return Opacity(
      opacity: off ? .5 : 1,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(15),
          onTap: off
              ? null
              : () {
                  HapticFeedback.selectionClick();
                  onTap!();
                },
          child: Ink(
            height: h,
            decoration: BoxDecoration(
              gradient: p ? AC.goldG : null,
              color: p ? null : (d ? const Color(0x1FFF5F7E) : AC.surf2),
              borderRadius: BorderRadius.circular(15),
              border: p ? null : Border.all(color: d ? const Color(0x66FF5F7E) : AC.line),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                if (lead != null) ...[lead!, const SizedBox(width: 8)],
                if (icon != null) ...[AIcon(icon!, size: 18, color: fg), const SizedBox(width: 8)],
                if (label.isNotEmpty)
                  Flexible(
                      child: Text(label,
                          maxLines: 1, overflow: TextOverflow.ellipsis, style: ats(14, w: FontWeight.w800, c: fg))),
                if (trail != null) ...[const SizedBox(width: 8), trail!],
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

/// کارتی گشتی (.card) — سنووری زێڕینی لار
class _Card extends StatelessWidget {
  const _Card({required this.child, this.margin = const EdgeInsets.only(top: 14)});
  final Widget child;
  final EdgeInsets margin;
  static const EdgeInsets pad = EdgeInsets.all(16);
  @override
  Widget build(BuildContext context) => Container(
        margin: margin,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: cssLin(150, [AC.l ? const Color(0x3306788C) : const Color(0x57FFD678), Colors.transparent], const [0, .6]),
        ),
        padding: const EdgeInsets.all(1),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(23),
            color: AC.l ? Colors.white.withAlpha(240) : Color.alphaBlend(AC.card, AC.bg),
          ),
          padding: pad,
          child: child,
        ),
      );
}

/// سەردێڕی کارت (.ttl)
class _Ttl extends StatelessWidget {
  const _Ttl(this.icon, this.title, {this.small, this.smallW});
  final String icon;
  final String title;
  final String? small;
  final Widget? smallW;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AC.l ? const Color(0x1FE6A014) : const Color(0x1FFFC846),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AC.line),
            ),
            alignment: Alignment.center,
            child: AIcon(icon, size: 16, color: AC.t3g),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: ats(15, w: FontWeight.w800))),
          if (smallW != null) smallW!,
          if (small != null) Text(small!, style: ats(11.5, w: FontWeight.w600, c: AC.mu)),
        ]),
      );
}

/// سەردێڕی بەش (.t3h)
class _H extends StatelessWidget {
  const _H(this.title, {this.small, this.color, this.smallColor, this.pad = const EdgeInsets.only(bottom: 10)});
  final String title;
  final String? small;
  final Color? color, smallColor;
  final EdgeInsets pad;
  @override
  Widget build(BuildContext context) => Padding(
        padding: pad,
        child: Row(children: [
          Expanded(child: Text(title, maxLines: 2, style: ats(18, w: FontWeight.w800, c: color))),
          if (small != null) ...[
            const SizedBox(width: 10),
            Text(small!, style: ats(12, w: FontWeight.w700, c: smallColor ?? AC.mu)),
          ],
        ]),
      );
}

class _Bar extends StatelessWidget {
  const _Bar(this.f, {this.color, this.gradient, this.h = 5, this.glow = false});
  final double f;
  final Color? color;
  final Gradient? gradient;
  final double h;
  final bool glow;
  @override
  Widget build(BuildContext context) => Container(
        height: h,
        decoration: BoxDecoration(color: AC.track, borderRadius: BorderRadius.circular(9)),
        child: Align(
          alignment: AlignmentDirectional.centerStart,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: f.clamp(0.0, 1.0).toDouble()),
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeOutCubic,
            builder: (_, v, __) => FractionallySizedBox(
              widthFactor: v,
              heightFactor: 1,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: gradient == null ? (color ?? AC.accent) : null,
                  gradient: gradient,
                  borderRadius: BorderRadius.circular(9),
                  boxShadow: glow ? const [BoxShadow(color: Color(0x8CFFC846), blurRadius: 12)] : null,
                ),
              ),
            ),
          ),
        ),
      );
}

/// ڕستە لەگەڵ ئایکۆن (p.v6hn و هتد)
class _IconLine extends StatelessWidget {
  const _IconLine(this.icon, this.text, {this.color, this.iconColor, this.size = 12.5, this.gap = 6});
  static const FontWeight w = FontWeight.w400;
  final String icon;
  final String text;
  final Color? color, iconColor;
  final double size, gap;
  @override
  Widget build(BuildContext context) => Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(padding: const EdgeInsets.only(top: 3), child: AIcon(icon, size: size + 1.5, color: iconColor ?? color ?? AC.mu)),
        SizedBox(width: gap),
        Expanded(child: Text(text, style: ats(size, w: w, c: color ?? AC.mu, h: 1.65))),
      ]);
}

// ---- پەیام و کۆنفێتی ----
OverlayEntry? _toastE;
Timer? _toastT;
void arenaToast(BuildContext context, String text, [String icon = 'check']) {
  final ov = Overlay.maybeOf(context, rootOverlay: true);
  if (ov == null) return;
  _toastT?.cancel();
  _toastE?.remove();
  _toastE = OverlayEntry(
    builder: (_) => Positioned(
      left: 0,
      right: 0,
      bottom: 110 + MediaQuery.of(context).padding.bottom,
      child: IgnorePointer(
        child: Center(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 280),
            builder: (_, v, ch) => Opacity(opacity: v, child: Transform.translate(offset: Offset(0, 20 * (1 - v)), child: ch)),
            child: Directionality(
              textDirection: arenaDir,
              child: Container(
                constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * .88),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
                decoration: BoxDecoration(
                  gradient: AC.goldG,
                  borderRadius: BorderRadius.circular(99),
                  boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 24, offset: Offset(0, 10))],
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  AIcon(icon, size: 16, color: AC.onGold),
                  const SizedBox(width: 8),
                  Flexible(
                      child: Material(
                          type: MaterialType.transparency,
                          child: Text(text, textAlign: TextAlign.center, style: ats(13, w: FontWeight.w800, c: AC.onGold)))),
                ]),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  ov.insert(_toastE!);
  _toastT = Timer(const Duration(milliseconds: 2400), () {
    _toastE?.remove();
    _toastE = null;
  });
}

void arenaConfetti(BuildContext context, [int n = 60]) {
  final ov = Overlay.maybeOf(context, rootOverlay: true);
  if (ov == null) return;
  late OverlayEntry e;
  e = OverlayEntry(builder: (_) => IgnorePointer(child: _Confetti(n: n, onDone: () => e.remove())));
  ov.insert(e);
}

class _Confetti extends StatefulWidget {
  const _Confetti({required this.onDone, this.n = 60});
  final VoidCallback onDone;
  final int n;
  @override
  State<_Confetti> createState() => _ConfettiState();
}

class _ConfettiState extends State<_Confetti> with SingleTickerProviderStateMixin {
  late final AnimationController a = AnimationController(vsync: this, duration: const Duration(milliseconds: 2200))
    ..forward().whenComplete(widget.onDone);
  late final List<List<double>> p = List.generate(widget.n, (i) {
    final r = _Seeded('cf$i${DateTime.now().millisecond}');
    return [r.next(), r.next(), r.next(), r.next(), r.next()];
  });
  @override
  void dispose() {
    a.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: a,
        builder: (_, __) => CustomPaint(size: MediaQuery.of(context).size, painter: _ConfettiPainter(a.value, p)),
      );
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.t, this.p);
  final double t;
  final List<List<double>> p;
  static const cols = [Color(0xFFFFD36B), Color(0xFF3CF08A), Color(0xFF2FE6F3), Color(0xFFFF6F86), Color(0xFF9B7BFF)];
  @override
  void paint(Canvas c, Size s) {
    for (final q in p) {
      final x = q[0] * s.width + math.sin(t * 6 + q[1] * 9) * 26;
      final y = -20 + (s.height + 40) * (t * (.7 + q[2] * .5)) + q[3] * -120;
      final paint = Paint()..color = cols[(q[4] * cols.length).floor() % cols.length].withAlpha(((1 - t * .6) * 255).round());
      c.save();
      c.translate(x, y);
      c.rotate(t * 10 * (q[1] - .5));
      c.drawRect(const Rect.fromLTWH(-4, -2.5, 8, 5), paint);
      c.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter o) => o.t != t;
}

/// شیتی خوارەوە (.shc)
Future<T?> arenaSheet<T>(BuildContext context, Widget Function(BuildContext) b) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    barrierColor: const Color(0xB3010C10),
    builder: (ctx) => Directionality(
      textDirection: arenaDir,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * .92, maxWidth: 440),
        child: Container(
          decoration: BoxDecoration(
            color: AC.sheet,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
            border: Border(top: BorderSide(color: AC.line2)),
          ),
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 22 + MediaQuery.of(ctx).viewInsets.bottom + MediaQuery.of(ctx).padding.bottom),
            child: DefaultTextStyle(
              style: ats(14),
              child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Center(
                    child: Container(
                        width: 46,
                        height: 5,
                        margin: const EdgeInsets.only(bottom: 14),
                        decoration: BoxDecoration(color: AC.line2, borderRadius: BorderRadius.circular(9)))),
                b(ctx),
              ]),
            ),
          ),
        ),
      ),
    ),
  );
}

/// سەردێڕی ناوەڕاستی شیت (.shc h3)
Widget _sh3(String t, {double top = 0}) =>
    Padding(padding: EdgeInsets.only(top: top, bottom: 8), child: Text(t, textAlign: TextAlign.center, style: ats(18, w: FontWeight.w800)));



/// تەنها بۆ تاقیکردنەوە: کۆنترۆڵەری دوایین پەڕە
@visibleForTesting
ArenaCtl? arenaDebugCtl;
