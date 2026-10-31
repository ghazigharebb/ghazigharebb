// =============================================================================
//  VEX Arena — پێشبڕکێی تەندروستی (Flutter)
//  هاوتای تەواوی وەشانی وێبی VEX Arena (v10)
//
//  ناوەڕۆک
//   1. زمان (6 زمان: کوردی سۆرانی، کوردی بادینی، English، العربية، فارسی، Türkçe)
//   2. ڕەنگ (تاریک / ڕووناک / خۆکار — لە VexTheme ـەوە)
//   3. وەرز، دوو لیگ (Band / مۆبایل)، خەڵات، بەشەکان
//   4. بزوێنەری پشتڕاستکردنەوە (دژی فێڵ) و خاڵ
//   5. ArenaHost — پەیوەندی بە ئەپەکەوە
//   6. ArenaStore — پاشەکەوتکردن (shared_preferences) + واژۆی دژی دەستکاری
//   7. VexArenaPage: دەروازەی تۆمارکردن، ئەمڕۆ، پلەکان، کارتەکەم
//   8. شیتەکان (خەڵات، یاسا، پشتڕاستکردنەوە، سکە، کارەکتەر، ...)
//
//  پێویستی pubspec.yaml: shared_preferences، فۆنتی NotoAr، assets/chars/
// =============================================================================
// ignore_for_file: prefer_single_quotes, use_build_context_synchronously

import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/theme.dart' show VexTheme;
import '../onboarding/reg_lang_state.dart' show LangState;

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
// 2. ڕەنگ
// =============================================================================

class AC {
  static bool get l => VexTheme.I.isLight;
  static Color get bg => l ? const Color(0xFFEEF2FA) : const Color(0xFF070C22);
  static Color get bg2 => l ? const Color(0xFFE2E8F5) : const Color(0xFF0B1433);
  static Color get card => l ? const Color(0xFFFFFFFF) : const Color(0xFF111A3A);
  static Color get surf => l ? const Color(0xFFF3F5FB) : const Color(0xFF16204A);
  static Color get line => l ? const Color(0x1A0A1F44) : const Color(0x1AFFFFFF);
  static Color get line2 => l ? const Color(0x2E0A1F44) : const Color(0x2EFFFFFF);
  static Color get tx => l ? const Color(0xFF0E1A33) : const Color(0xFFEEF3FF);
  static Color get mu => l ? const Color(0xFF5B6785) : const Color(0xFF9AA6C8);
  static Color get gold => l ? const Color(0xFFB07400) : const Color(0xFFFFD36B);
  static Color get mint => l ? const Color(0xFF12A35A) : const Color(0xFF3CF08A);
  static Color get cyan => l ? const Color(0xFF0B8FA3) : const Color(0xFF7FD8FF);
  static Color get coral => l ? const Color(0xFFD93355) : const Color(0xFFFF6F86);
  static Color get violet => l ? const Color(0xFF6C4DE0) : const Color(0xFFB9A6FF);
  static Color get orange => l ? const Color(0xFFDB6420) : const Color(0xFFFF8A4D);
  static Color get track => l ? const Color(0x140A1F44) : const Color(0x14FFFFFF);
  static Color get sheet => l ? const Color(0xFFFFFFFF) : const Color(0xFF0C1533);
  static List<BoxShadow> get sh => l
      ? const [BoxShadow(color: Color(0x140A1F44), blurRadius: 18, offset: Offset(0, 8))]
      : const [BoxShadow(color: Color(0x66000000), blurRadius: 24, offset: Offset(0, 12))];

  // ستەیجی تاریک (قارەمان و خەڵاتەکان لە هەردوو دۆخدا تاریکن)
  static const stage1 = Color(0xFF1A2152);
  static const stage2 = Color(0xFF0A0F2C);
  static const stageTx = Color(0xFFEEF3FF);
  static const stageMu = Color(0xFFB9C4E6);
  static const goldS = Color(0xFFFFD36B);
  static const accent = Color(0xFFF2B21C);
  static const onGold = Color(0xFF2A1A00);
  static const goldG = LinearGradient(
      colors: [Color(0xFFFFF0B0), Color(0xFFFFD25A), Color(0xFFE7A514)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight);
}

const String _kFont = 'NotoAr';

TextStyle ats(double s, {FontWeight w = FontWeight.w500, Color? c, double? h, double? ls}) => TextStyle(
      fontFamily: _kFont,
      fontSize: s,
      fontWeight: w,
      color: c ?? AC.tx,
      height: h,
      letterSpacing: ls,
      fontFeatures: const [FontFeature.tabularFigures()],
    );

Color _a(Color c, double o) => c.withAlpha((o.clamp(0.0, 1.0) * 255).round());

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
String maskPhone(String p) => p.length == 11 ? '\u200E${p.substring(0, 4)} *** ${p.substring(7)}\u200E' : p;

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

// =============================================================================
// 3. وەرز، لیگ، خەڵات، بەشەکان
// =============================================================================

class ArenaCat {
  const ArenaCat(this.id, this.icon, this.color, this.max, this.phone, this.band);
  final String id;
  final IconData icon;
  final Color color;
  final int max; // لیگی Band
  final int phone; // لیگی مۆبایل (0 = نییە)
  final bool band; // پێویستی بە Band هەیە
  String get name => tr('cat_$id');
}

const List<ArenaCat> kCats = [
  ArenaCat('walk', Icons.directions_walk_rounded, Color(0xFF3CF08A), 60, 50, false),
  ArenaCat('run', Icons.directions_run_rounded, Color(0xFFFF9466), 60, 50, false),
  ArenaCat('gym', Icons.fitness_center_rounded, Color(0xFFFF6F86), 60, 40, false),
  ArenaCat('sleep', Icons.bedtime_rounded, Color(0xFF9B7BFF), 60, 0, true),
  ArenaCat('food', Icons.restaurant_rounded, Color(0xFFFFBE4D), 30, 30, false),
  ArenaCat('water', Icons.water_drop_rounded, Color(0xFF2FB8F3), 30, 30, false),
  ArenaCat('heart', Icons.favorite_rounded, Color(0xFFFF5F7E), 40, 0, true),
  ArenaCat('o2', Icons.air_rounded, Color(0xFF4FD2E6), 20, 0, true),
  ArenaCat('calm', Icons.self_improvement_rounded, Color(0xFFA58CFF), 40, 0, true),
  ArenaCat('rec', Icons.battery_charging_full_rounded, Color(0xFF3FD69A), 40, 0, true),
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
  const Prize(this.r, this.key, this.icon);
  final int r;
  final String key;
  final IconData icon;
  String get name => tr(key);
}

const Map<Div, List<Prize>> kPrizes = {
  Div.band: [
    Prize(1, 'pz_car', Icons.directions_car_filled_rounded),
    Prize(2, 'pz_iphone', Icons.phone_iphone_rounded),
    Prize(3, 'pz_1m', Icons.payments_rounded),
  ],
  Div.phone: [
    Prize(1, 'pz_250', Icons.payments_rounded),
    Prize(2, 'pz_150', Icons.payments_rounded),
    Prize(3, 'pz_100', Icons.payments_rounded),
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
  const League(this.min, this.key, this.color);
  final int min;
  final String key;
  final Color color;
  String get name => tr(key);
}

const List<League> kLeagues = [
  League(0, 'lg_bronze', Color(0xFFE29A5F)),
  League(600, 'lg_silver', Color(0xFFD9E6EE)),
  League(1500, 'lg_gold', Color(0xFFFFD56B)),
  League(3000, 'lg_plat', Color(0xFF7FE7FF)),
  League(5000, 'lg_dia', Color(0xFFB9A6FF)),
  League(7500, 'lg_legend', Color(0xFFFF6F86)),
];

League leagueOf(num p, [Div d = Div.band]) {
  final f = d == Div.phone ? 1 / 3 : 1.0;
  var l = kLeagues.first;
  for (final x in kLeagues) {
    if (p >= x.min * f) l = x;
  }
  return l;
}

int leagueIndex(League l) => kLeagues.indexOf(l);
int levelOf(num p) => math.sqrt(math.max(0, p) / 25).floor() + 1;
int levelStart(int l) => 25 * (l - 1) * (l - 1);
int ratingOf(num p) => math.min(99, (52 + math.log(math.max(p, 50) / 50) * 9).round());

const List<String> kCities = [
  'هەولێر', 'سلێمانی', 'دهۆک', 'کەرکووک', 'هەڵەبجە', 'زاخۆ', 'ڕانیە', 'کۆیە', 'سۆران', 'چەمچەماڵ',
  'ئاکرێ', 'ئامێدی', 'شێخان', 'سمێل', 'شەقڵاوە', 'ڕواندز', 'مێرگەسور', 'قەڵادزێ', 'پێنجوێن', 'سەیدسادق',
  'دەربەندیخان', 'کەلار', 'کفری', 'خانەقین', 'دووکان', 'دەبەگ', 'مەخموور', 'شنگال', 'خورماتوو', 'تەلکێف',
  'بەغدا', 'موسڵ', 'بەسرە', 'نەجەف', 'کەربەلا', 'ئەنبار', 'دیالە', 'تکریت', 'کووت', 'عەمارە',
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

String charRarity(String id) {
  final c = charCost(id);
  return c == 0 ? 'r_common' : c <= 60 ? 'r_rare' : c <= 80 ? 'r_epic' : 'r_legend';
}

String charAsset(String id) => 'assets/chars/$id.webp';
const Duration kCharLock = Duration(days: 30);

// دیزاینی کارت
class CardSkin {
  const CardSkin(this.id, this.cost, this.rar, this.c1, this.c2, this.accent, {this.lg = 0, this.fx = ''});
  final String id;
  final int cost;
  final String rar; // f c r e l
  final Color c1, c2, accent;
  final int lg; // پێویستی بە لیگ (ئیندێکس)
  final String fx;
  String get name => tr('sk_$id');
}

const List<CardSkin> kSkins = [
  CardSkin('auto', 0, 'f', Color(0xFF5A3417), Color(0xFFA8642F), Color(0xFFE29A5F)),
  CardSkin('neon', 30, 'c', Color(0xFF0B1A4A), Color(0xFF3A1A7A), Color(0xFF2FE6F3)),
  CardSkin('night', 40, 'c', Color(0xFF070B1F), Color(0xFF1C2A5A), Color(0xFF9FB4FF)),
  CardSkin('carbon', 50, 'c', Color(0xFF15181F), Color(0xFF3A3F4A), Color(0xFFB8C2D6)),
  CardSkin('kurd', 60, 'r', Color(0xFF7A1010), Color(0xFF0F6A3A), Color(0xFFFFD56B)),
  CardSkin('marble', 70, 'r', Color(0xFF2C2C34), Color(0xFF6E6A62), Color(0xFFFFD78A)),
  CardSkin('zagros', 80, 'r', Color(0xFF0E3B5A), Color(0xFF2E7D5B), Color(0xFFFFC46B)),
  CardSkin('newroz', 90, 'e', Color(0xFF8A1A00), Color(0xFFE0751A), Color(0xFFFFE08A)),
  CardSkin('holo', 100, 'e', Color(0xFF3A2A8A), Color(0xFF1A8AA0), Color(0xFFB6F3FF), fx: 'holo'),
  CardSkin('royal', 120, 'l', Color(0xFF2A0A4A), Color(0xFF6A1A7A), Color(0xFFFFD56B), fx: 'royal'),
  CardSkin('gold', 0, 'e', Color(0xFF6B4A0A), Color(0xFFD9A21F), Color(0xFFFFE08A), lg: 2),
  CardSkin('dia', 0, 'l', Color(0xFF2A1A6E), Color(0xFF7B5CFF), Color(0xFFD9CCFF), lg: 4),
  CardSkin('legend', 0, 'l', Color(0xFF5A0F22), Color(0xFFD62F55), Color(0xFFFFB3C2), lg: 5, fx: 'royal'),
];

CardSkin skinById(String id) => kSkins.firstWhere((s) => s.id == id, orElse: () => kSkins.first);

const List<List<Object>> kTitles = [
  ['t0', 0],
  ['t1', 0],
  ['t2', 0],
  ['t3', 1],
  ['t4', 5],
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
  bool cbP = false, eco = false;
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
  final IconData icon;
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
      events.add(ArenaEvent(tr('ev_band'), Icons.watch_rounded, confetti: true));
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
        events.add(ArenaEvent(tr('ev_guess'), Icons.auto_awesome_rounded, confetti: true));
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
      events.add(ArenaEvent(tr('ev_back'), Icons.star_rounded));
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
      events.add(ArenaEvent('+${c - paid}', Icons.toll_rounded));
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
      events.add(ArenaEvent(tr('ev_counted'), Icons.check_circle_rounded));
    }
    if (today.tot >= goal && st.gd != tk) {
      st.gd = tk;
      st.ad = tk;
      _dirty = true;
      events.add(ArenaEvent(tr('ev_goal'), Icons.emoji_events_rounded, confetti: true));
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
    return req == 0 || (req == 1 && store.bestPower >= 1) || (req == 5 && leagueIndex(leagueOf(myTotal, div)) >= 5);
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
  'ئاراس کەریم': 'Aras Karim', 'سارا ئەحمەد': 'Sara Ahmad', 'هێمن ڕەشید': 'Hemin Rashid', 'ڤیان عەلی': 'Vian Ali',
  'دانا سەعید': 'Dana Saeed', 'ڕێبین حەسەن': 'Rebin Hasan', 'ژیلا مەحموود': 'Zhila Mahmood', 'ئازاد قادر': 'Azad Qadir',
  'لانە جەمال': 'Lana Jamal', 'کارزان عومەر': 'Karzan Omar',
};

/// ناوی شار یان کەس بەپێی زمان
String nm(String s) => arenaLtr ? (_kLatin[s] ?? s) : s;

// =============================================================================
// 9. ئامرازە هاوبەشەکانی ڕووکار
// =============================================================================

class _Box extends StatelessWidget {
  const _Box({required this.child, this.border, this.gradient});
  final Widget child;
  final Color? border;
  final Gradient? gradient;
  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: gradient == null ? AC.card : null,
          gradient: gradient,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: border ?? AC.line),
          boxShadow: AC.sh,
        ),
        child: child,
      );
}

class _Head extends StatelessWidget {
  const _Head(this.title, {this.small, this.color});
  final String title;
  final String? small;
  final Color? color;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(children: [
          Expanded(child: Text(title, style: ats(17, w: FontWeight.w800, c: color), maxLines: 2)),
          if (small != null)
            Flexible(child: Text(small!, textAlign: TextAlign.end, style: ats(12, c: color != null ? AC.stageMu : AC.mu), maxLines: 2)),
        ]),
      );
}

class _Btn extends StatelessWidget {
  const _Btn(this.label, {this.icon, this.onTap, this.primary = true, this.small = false, this.danger = false});
  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
  final bool primary, small, danger;
  @override
  Widget build(BuildContext context) {
    final off = onTap == null;
    final fg = primary ? AC.onGold : (danger ? AC.coral : AC.tx);
    return Opacity(
      opacity: off ? 0.5 : 1,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: off
              ? null
              : () {
                  HapticFeedback.selectionClick();
                  onTap!();
                },
          child: Ink(
            height: small ? 42 : 52,
            decoration: BoxDecoration(
              gradient: primary ? AC.goldG : null,
              color: primary ? null : AC.surf,
              borderRadius: BorderRadius.circular(16),
              border: primary ? null : Border.all(color: danger ? _a(AC.coral, .5) : AC.line2),
              boxShadow: primary ? const [BoxShadow(color: Color(0x55F2B21C), blurRadius: 18, offset: Offset(0, 8))] : null,
            ),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  if (icon != null) ...[Icon(icon, size: small ? 17 : 19, color: fg), const SizedBox(width: 7)],
                  Flexible(
                      child: Text(label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: ats(small ? 13 : 15, w: FontWeight.w800, c: fg))),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
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

class CatTile extends StatelessWidget {
  const CatTile(this.cat, {super.key, this.size = 40, this.dim = false});
  final ArenaCat cat;
  final double size;
  final bool dim;
  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(size * .32),
          gradient: LinearGradient(
              colors: dim ? [AC.surf, AC.surf] : [_a(cat.color, .95), _a(cat.color, .6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight),
          boxShadow: dim ? null : [BoxShadow(color: _a(cat.color, .35), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Icon(cat.icon, size: size * .54, color: dim ? AC.mu : Colors.white),
      );
}

/// وێنەی کارەکتەر لە بازنەیەکدا (یان یەکەم پیتی ناو)
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
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: const Alignment(0, -.5),
          colors: gold
              ? const [Color(0xFFFFF3C4), Color(0xFFF2B21C), Color(0xFF8A5A06)]
              : const [Color(0xFFE3FCFF), Color(0xFF2FE6F3), Color(0xFF0B5F73)],
        ),
        border: ring == null ? null : Border.all(color: ring!, width: size > 60 ? 3 : 2),
      ),
      clipBehavior: Clip.antiAlias,
      child: ch.isEmpty
          ? fallback
          : Transform.translate(
              offset: Offset(0, size * .06),
              child: Transform.scale(
                scale: 1.14,
                child: Image.asset(charAsset(ch),
                    fit: BoxFit.contain,
                    alignment: Alignment.bottomCenter,
                    filterQuality: FilterQuality.medium,
                    gaplessPlayback: true,
                    errorBuilder: (_, __, ___) => fallback),
              ),
            ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill(this.text, {this.color, this.icon, this.solid = false});
  final String text;
  final Color? color;
  final IconData? icon;
  final bool solid;
  @override
  Widget build(BuildContext context) {
    final c = color ?? AC.mu;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: solid ? null : _a(c, .14),
        gradient: solid ? AC.goldG : null,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (icon != null) ...[Icon(icon, size: 12, color: solid ? AC.onGold : c), const SizedBox(width: 3)],
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 210),
          child: Text(text, maxLines: 1, overflow: TextOverflow.ellipsis, style: ats(11, w: FontWeight.w800, c: solid ? AC.onGold : c)),
        ),
      ]),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar(this.f, {this.color, this.h = 6});
  final double f;
  final Color? color;
  final double h;
  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(h),
        child: SizedBox(
          height: h,
          child: Stack(children: [
            Positioned.fill(child: ColoredBox(color: AC.track)),
            FractionallySizedBox(
              widthFactor: f.clamp(0.0, 1.0).toDouble(),
              heightFactor: 1,
              alignment: AlignmentDirectional.centerStart,
              child: DecoratedBox(
                  decoration: BoxDecoration(
                      color: color, gradient: color == null ? AC.goldG : null, borderRadius: BorderRadius.circular(h))),
            ),
          ]),
        ),
      );
}

// ---- پەیام و کۆنفێتی ----
OverlayEntry? _toastE;
Timer? _toastT;
void arenaToast(BuildContext context, String text, [IconData icon = Icons.check_circle_rounded]) {
  final ov = Overlay.maybeOf(context, rootOverlay: true);
  if (ov == null) return;
  _toastT?.cancel();
  _toastE?.remove();
  _toastE = OverlayEntry(
    builder: (_) => Positioned(
      left: 20,
      right: 20,
      bottom: 34 + MediaQuery.of(context).padding.bottom,
      child: IgnorePointer(
        child: Directionality(
          textDirection: arenaDir,
          child: Center(
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  gradient: AC.goldG,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 20, offset: Offset(0, 8))],
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(icon, size: 18, color: AC.onGold),
                  const SizedBox(width: 8),
                  Flexible(child: Text(text, style: ats(13.5, w: FontWeight.w800, c: AC.onGold))),
                ]),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  ov.insert(_toastE!);
  _toastT = Timer(const Duration(milliseconds: 2300), () {
    _toastE?.remove();
    _toastE = null;
  });
}

void arenaConfetti(BuildContext context) {
  final ov = Overlay.maybeOf(context, rootOverlay: true);
  if (ov == null) return;
  late OverlayEntry e;
  e = OverlayEntry(builder: (_) => IgnorePointer(child: _Confetti(onDone: () => e.remove())));
  ov.insert(e);
}

class _Confetti extends StatefulWidget {
  const _Confetti({required this.onDone});
  final VoidCallback onDone;
  @override
  State<_Confetti> createState() => _ConfettiState();
}

class _ConfettiState extends State<_Confetti> with SingleTickerProviderStateMixin {
  late final AnimationController a = AnimationController(vsync: this, duration: const Duration(milliseconds: 2200))
    ..forward().whenComplete(widget.onDone);
  final _r = math.Random();
  late final List<List<double>> p = List.generate(28, (_) => [_r.nextDouble(), _r.nextDouble() * .4, .6 + _r.nextDouble() * .8, _r.nextDouble() * 6]);
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
  static const cols = [Color(0xFFFFD56B), Color(0xFF3CF08A), Color(0xFF2FE6F3), Color(0xFF9B7BFF), Color(0xFFFF6F86)];
  @override
  void paint(Canvas c, Size s) {
    for (var i = 0; i < p.length; i++) {
      final q = p[i];
      final tt = ((t - q[1]) / (1 - q[1])).clamp(0.0, 1.0);
      if (tt <= 0) continue;
      final x = q[0] * s.width + math.sin(tt * 6 + q[3]) * 18;
      final y = -20 + tt * (s.height + 40) * q[2];
      c.save();
      c.translate(x, y);
      c.rotate(tt * 8 + q[3]);
      c.drawRect(const Rect.fromLTWH(-4, -2.5, 8, 5), Paint()..color = _a(cols[i % 5], 1 - tt * .6));
      c.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter o) => o.t != t;
}

Future<T?> arenaSheet<T>(BuildContext context, Widget Function(BuildContext) b) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: const Color(0x99010616),
    builder: (ctx) => Directionality(
      textDirection: arenaDir,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * .9),
        child: Container(
          decoration: BoxDecoration(
            color: AC.sheet,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border(top: BorderSide(color: AC.line2)),
          ),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(18, 10, 18, 18 + MediaQuery.of(ctx).viewInsets.bottom),
              child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Center(
                    child: Container(
                        width: 42, height: 5, margin: const EdgeInsets.only(bottom: 14), decoration: BoxDecoration(color: AC.line2, borderRadius: BorderRadius.circular(9)))),
                b(ctx),
              ]),
            ),
          ),
        ),
      ),
    ),
  );
}

// =============================================================================
// 10. پەڕەی سەرەکی
// =============================================================================

class VexArenaPage extends StatefulWidget {
  const VexArenaPage({super.key, required this.host, this.store, this.sponsor});
  final ArenaHost host;
  final ArenaStore? store;

  /// سپۆنسەری وەرز. null = شوێنەکە بەتاڵە و ئامادەیە بۆ سپۆنسەر
  final Widget? sponsor;

  @override
  State<VexArenaPage> createState() => _VexArenaPageState();
}

class _VexArenaPageState extends State<VexArenaPage> with WidgetsBindingObserver {
  late final ArenaStore store = widget.store ?? ArenaStore();
  late final ArenaCtl c = ArenaCtl(widget.host, store);
  final ValueNotifier<DateTime> clock = ValueNotifier<DateTime>(DateTime.now());
  Timer? _tick, _poll, _deb;
  bool ready = false;
  int tab = 0;
  Div? rankDiv;
  String seg = 'all';
  Div? przDiv;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _init();
  }

  Future<void> _init() async {
    if (!store.loaded) await store.load();
    c.events.clear();
    c.refresh();
    c.events.clear();
    if (!mounted) return;
    setState(() => ready = true);
    c.addListener(_onCtl);
    widget.host.changes?.addListener(_onData);
    VexTheme.I.addListener(_re);
    LangState.I.addListener(_re);
    _tick = Timer.periodic(const Duration(seconds: 1), (_) => clock.value = DateTime.now());
    _poll = Timer.periodic(const Duration(seconds: 20), (_) => c.refresh());
  }

  void _re() {
    if (mounted) setState(() {});
  }

  void _onData() {
    _deb?.cancel();
    _deb = Timer(const Duration(milliseconds: 250), () {
      if (mounted) c.refresh();
    });
  }

  void _onCtl() {
    if (!mounted) return;
    setState(() {});
    if (c.events.isEmpty) return;
    final ev = List<ArenaEvent>.from(c.events);
    c.events.clear();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      var shown = false;
      for (final e in ev) {
        if (e.icon == Icons.toll_rounded) continue;
        if (!shown) {
          arenaToast(context, e.text, e.icon);
          shown = true;
        }
        if (e.confetti) arenaConfetti(context);
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState s) {
    if (s == AppLifecycleState.resumed && ready) c.refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    c.removeListener(_onCtl);
    widget.host.changes?.removeListener(_onData);
    VexTheme.I.removeListener(_re);
    LangState.I.removeListener(_re);
    _tick?.cancel();
    _poll?.cancel();
    _deb?.cancel();
    clock.dispose();
    super.dispose();
  }

  void goTab(int t) {
    if (t == tab) return;
    HapticFeedback.selectionClick();
    setState(() => tab = t);
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: arenaDir,
      child: Scaffold(
        backgroundColor: AC.bg,
        resizeToAvoidBottomInset: true,
        body: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [AC.bg2, AC.bg], begin: Alignment.topCenter, end: const Alignment(0, -.2)),
          ),
          child: SafeArea(
            bottom: false,
            child: !ready
                ? Center(child: CircularProgressIndicator(color: AC.gold))
                : !c.regd
                    ? _Gate(c: c, clock: clock, onDone: _afterReg)
                    : Column(children: [
                        _header(),
                        _tabs(),
                        Expanded(
                          child: IndexedStack(index: tab, children: [
                            _TodayTab(s: this),
                            _RankTab(s: this),
                            _CardTab(s: this),
                          ]),
                        ),
                      ]),
          ),
        ),
      ),
    );
  }

  void _afterReg() {
    setState(() => tab = 2);
    showArenaReveal(context, c);
  }

  Widget _header() {
    final S = c.S;
    final sub = S.live
        ? tr('hdr_live', [S.n, S.daysLeft])
        : tr('hdr_pre', [S.n, math.max(0, S.start.difference(DateTime.now()).inDays + 1)]);
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 6, 14, 8),
      child: Row(children: [
        if (Navigator.of(context).canPop())
          IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: Icon(arenaLtr ? Icons.arrow_back_ios_new_rounded : Icons.arrow_forward_ios_rounded, size: 20, color: AC.tx),
          ),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            Text('VEX Arena', style: ats(22, w: FontWeight.w900)),
            Text(sub, maxLines: 1, overflow: TextOverflow.ellipsis, style: ats(12, c: AC.mu)),
          ]),
        ),
        _Tap(
          radius: 99,
          onTap: () => coinSheet(context, c),
          child: Container(
            padding: const EdgeInsets.fromLTRB(12, 7, 8, 7),
            decoration: BoxDecoration(color: AC.card, borderRadius: BorderRadius.circular(99), border: Border.all(color: AC.line2)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Text(afmt(store.coins), style: ats(15, w: FontWeight.w900)),
              const SizedBox(width: 6),
              const _Coin(20),
            ]),
          ),
        ),
        const SizedBox(width: 8),
        _Tap(
          radius: 99,
          onTap: () => rulesSheet(context, c),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: AC.card, shape: BoxShape.circle, border: Border.all(color: AC.line2)),
            child: Icon(Icons.help_outline_rounded, size: 20, color: AC.tx),
          ),
        ),
      ]),
    );
  }

  Widget _tabs() {
    final names = [tr('tab_today'), tr('tab_rank'), tr('tab_card')];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Container(
        height: 50,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(color: AC.card, borderRadius: BorderRadius.circular(18), border: Border.all(color: AC.line)),
        child: LayoutBuilder(builder: (ctx, bc) {
          final w = bc.maxWidth / 3;
          return Stack(children: [
            AnimatedPositionedDirectional(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
              start: w * tab,
              top: 0,
              bottom: 0,
              width: w,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: AC.goldG,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: const [BoxShadow(color: Color(0x44F2B21C), blurRadius: 12, offset: Offset(0, 4))],
                ),
              ),
            ),
            Row(children: [
              for (var i = 0; i < 3; i++)
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => goTab(i),
                    child: Center(
                      child: AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 200),
                        style: ats(14.5, w: FontWeight.w800, c: i == tab ? AC.onGold : AC.mu),
                        child: Text(names[i], maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                    ),
                  ),
                ),
            ]),
          ]);
        }),
      ),
    );
  }

  Widget sponsorSlot() => widget.sponsor ?? const SponsorSlot();

  void upd(VoidCallback f) {
    if (mounted) setState(f);
  }
}

class _Coin extends StatelessWidget {
  const _Coin(this.s);
  final double s;
  @override
  Widget build(BuildContext context) => Container(
        width: s,
        height: s,
        decoration: const BoxDecoration(shape: BoxShape.circle, gradient: AC.goldG),
        child: Icon(Icons.star_rounded, size: s * .62, color: const Color(0xFF7A4E00)),
      );
}

/// شوێنی سپۆنسەری وەرز — بەتاڵ و ئامادە
class SponsorSlot extends StatelessWidget {
  const SponsorSlot({super.key});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: CustomPaint(
          painter: _DashPainter(AC.line2, 20),
          child: Container(
            height: 72,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(color: _a(AC.card, .55), borderRadius: BorderRadius.circular(20)),
            child: Row(children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(color: AC.surf, borderRadius: BorderRadius.circular(14), border: Border.all(color: AC.line)),
                child: Icon(Icons.handshake_outlined, color: AC.mu, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(tr('sp_t'), maxLines: 1, overflow: TextOverflow.ellipsis, style: ats(14, w: FontWeight.w800, c: AC.mu)),
                  Text(tr('sp_s'), maxLines: 1, overflow: TextOverflow.ellipsis, style: ats(11.5, c: _a(AC.mu, .8))),
                ]),
              ),
              _Pill(tr('sp_free'), color: AC.mu),
            ]),
          ),
        ),
      );
}

class _DashPainter extends CustomPainter {
  _DashPainter(this.color, this.r);
  final Color color;
  final double r;
  @override
  void paint(Canvas canvas, Size s) {
    final path = Path()..addRRect(RRect.fromRectAndRadius(Offset.zero & s, Radius.circular(r)));
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    for (final m in path.computeMetrics()) {
      var d = 0.0;
      while (d < m.length) {
        canvas.drawPath(m.extractPath(d, math.min(d + 7, m.length)), p);
        d += 12;
      }
    }
  }

  @override
  bool shouldRepaint(_DashPainter o) => o.color != color;
}

// =============================================================================
// 11. دەروازەی تۆمارکردن — پێش چوونە ژوورەوە پێویستە
// =============================================================================

class _Gate extends StatefulWidget {
  const _Gate({required this.c, required this.clock, required this.onDone});
  final ArenaCtl c;
  final ValueNotifier<DateTime> clock;
  final VoidCallback onDone;
  @override
  State<_Gate> createState() => _GateState();
}

class _GateState extends State<_Gate> {
  ArenaCtl get c => widget.c;
  int step = 1;
  String err = '';
  final name = TextEditingController();
  final phone = TextEditingController();
  final q = TextEditingController();
  final body = ScrollController();
  String city = '';
  String age = 'a';
  String ch = '';
  bool agree = false;

  static const List<String> _free = ['00', '01', '02', '03', '07', '08', '10', '11'];

  @override
  void initState() {
    super.initState();
    final a = c.store.acc;
    final p = c.host.profile;
    name.text = a?.name ?? p.name;
    final ph = a?.phone ?? p.phone;
    if (RegExp(r'^07\d{9}$').hasMatch(ph)) phone.text = _fmtPhone(ph.substring(1));
    city = a?.city ?? '';
    age = a?.age ?? (p.age < 18 ? 'y' : p.age < 40 ? 'a' : p.age < 60 ? 'm' : 's');
    ch = _free.contains(c.store.ch) ? c.store.ch : '';
  }

  @override
  void dispose() {
    name.dispose();
    phone.dispose();
    q.dispose();
    body.dispose();
    super.dispose();
  }

  String _fmtPhone(String d) {
    d = d.replaceAll(RegExp(r'\D'), '');
    if (d.startsWith('0')) d = d.substring(1);
    if (d.length > 10) d = d.substring(0, 10);
    final b = StringBuffer();
    for (var i = 0; i < d.length; i++) {
      if (i == 3 || i == 6) b.write(' ');
      b.write(d[i]);
    }
    return b.toString();
  }

  void _go(int s) {
    setState(() {
      step = s;
      err = '';
    });
    if (body.hasClients) body.jumpTo(0);
  }

  void _next() {
    if (step == 1) {
      final n = name.text.trim().replaceAll(RegExp(r'\s+'), ' ');
      final p = '0${phone.text.replaceAll(RegExp(r'\D'), '')}';
      if (n.length < 3 || !n.contains(' ')) return setState(() => err = tr('e_name'));
      if (!RegExp(r'^07[3-9]\d{8}$').hasMatch(p)) return setState(() => err = tr('e_phone'));
      _go(2);
    } else if (step == 2) {
      if (city.isEmpty) return setState(() => err = tr('e_city'));
      _go(3);
    } else if (step == 3) {
      if (ch.isEmpty) return setState(() => err = tr('e_char'));
      _go(4);
    } else {
      if (!agree) return setState(() => err = tr('e_agree'));
      final n = name.text.trim().replaceAll(RegExp(r'\s+'), ' ');
      c.register(
        name: n.length > 24 ? n.substring(0, 24) : n,
        phone: '0${phone.text.replaceAll(RegExp(r'\D'), '')}',
        city: city,
        age: age,
        ch: ch,
      );
      HapticFeedback.mediumImpact();
      widget.onDone();
    }
  }

  @override
  Widget build(BuildContext context) {
    final steps = [tr('st_id'), tr('st_city'), tr('st_char'), tr('st_rules')];
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(6, 4, 14, 0),
        child: Row(children: [
          if (Navigator.of(context).canPop())
            IconButton(
              onPressed: () => Navigator.of(context).maybePop(),
              icon: Icon(arenaLtr ? Icons.arrow_back_ios_new_rounded : Icons.arrow_forward_ios_rounded, size: 20, color: AC.tx),
            )
          else
            const SizedBox(width: 12),
          Text('VEX Arena', style: ats(18, w: FontWeight.w900)),
          const Spacer(),
          _Pill(c.S.live ? tr('live') : tr('soon'), color: c.S.live ? AC.coral : AC.gold, icon: Icons.circle),
        ]),
      ),
      Expanded(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440, maxHeight: 720),
              child: Container(
                decoration: BoxDecoration(
                  color: AC.card,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: _a(AC.accent, .25)),
                  boxShadow: AC.sh,
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(children: [
                  // سەر
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                    child: Row(children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(gradient: AC.goldG, borderRadius: BorderRadius.circular(14)),
                        child: const Icon(Icons.emoji_events_rounded, color: Color(0xFF5A3A00), size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(tr('g_title'), style: ats(16.5, w: FontWeight.w800)),
                          Text(tr('g_sub'), style: ats(11.5, c: AC.mu)),
                        ]),
                      ),
                    ]),
                  ),
                  Divider(height: 1, color: AC.line),
                  // هەنگاوەکان
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
                    child: Row(children: [
                      for (var i = 0; i < 4; i++)
                        Expanded(
                          child: Column(children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 250),
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: i + 1 == step ? AC.goldG : null,
                                color: i + 1 < step ? _a(AC.mint, .18) : (i + 1 == step ? null : AC.surf),
                                border: Border.all(color: i + 1 < step ? _a(AC.mint, .6) : (i + 1 == step ? Colors.transparent : AC.line2)),
                              ),
                              child: Center(
                                child: i + 1 < step
                                    ? Icon(Icons.check_rounded, size: 16, color: AC.mint)
                                    : Text('${i + 1}', style: ats(12.5, w: FontWeight.w800, c: i + 1 == step ? AC.onGold : AC.mu)),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(steps[i],
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: ats(11, w: FontWeight.w700, c: i + 1 == step ? AC.tx : AC.mu)),
                          ]),
                        ),
                    ]),
                  ),
                  // ناوەڕۆک
                  Expanded(
                    child: SingleChildScrollView(
                      controller: body,
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 220),
                        child: KeyedSubtree(key: ValueKey(step), child: _stepBody()),
                      ),
                    ),
                  ),
                  // خوارەوە (هەمیشە جێگیر)
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 14),
                    decoration: BoxDecoration(border: Border(top: BorderSide(color: AC.line))),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      SizedBox(
                        height: 20,
                        child: Center(
                          child: Text(err, maxLines: 1, overflow: TextOverflow.ellipsis, style: ats(12, w: FontWeight.w700, c: AC.coral)),
                        ),
                      ),
                      Row(children: [
                        if (step > 1) ...[
                          SizedBox(
                            width: 120,
                            child: _Btn(tr('back'), icon: arenaLtr ? Icons.chevron_left_rounded : Icons.chevron_right_rounded, primary: false, onTap: () => _go(step - 1)),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Expanded(
                          child: _Btn(step < 4 ? tr('next') : (c.S.live ? tr('join') : tr('register')),
                              icon: step < 4 ? (arenaLtr ? Icons.chevron_right_rounded : Icons.chevron_left_rounded) : Icons.rocket_launch_rounded,
                              onTap: _next),
                        ),
                      ]),
                    ]),
                  ),
                ]),
              ),
            ),
          ),
        ),
      ),
    ]);
  }

  InputDecoration _dec(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: ats(14, c: _a(AC.mu, .7)),
        filled: true,
        fillColor: AC.surf,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: AC.line)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: AC.line)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: AC.cyan, width: 1.5)),
      );

  Widget _lbl(String t, [IconData? i]) => Padding(
        padding: const EdgeInsets.only(top: 10, bottom: 6),
        child: Row(children: [
          if (i != null) ...[Icon(i, size: 15, color: AC.mu), const SizedBox(width: 5)],
          Flexible(child: Text(t, style: ats(13, w: FontWeight.w800, c: AC.mu))),
        ]),
      );

  Widget _hint(String t, IconData i) => Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(padding: const EdgeInsets.only(top: 2), child: Icon(i, size: 14, color: AC.mu)),
          const SizedBox(width: 6),
          Expanded(child: Text(t, style: ats(11.5, c: AC.mu, h: 1.6))),
        ]),
      );

  Widget _stepBody() {
    switch (step) {
      case 1:
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          _lbl(tr('f_name')),
          TextField(
            controller: name,
            maxLength: 24,
            textInputAction: TextInputAction.next,
            style: ats(15),
            scrollPadding: const EdgeInsets.only(bottom: 140),
            decoration: _dec(tr('f_name_h')).copyWith(counterText: ''),
            onChanged: (_) {
              if (err.isNotEmpty) setState(() => err = '');
            },
          ),
          _lbl(tr('f_phone')),
          Directionality(
            textDirection: TextDirection.ltr,
            child: Row(children: [
              Container(
                height: 52,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                alignment: Alignment.center,
                decoration: BoxDecoration(color: AC.surf, borderRadius: BorderRadius.circular(14), border: Border.all(color: AC.line)),
                child: Text('+964', style: ats(15, w: FontWeight.w800, c: AC.mu)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: phone,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.done,
                  style: ats(16, ls: .6),
                  scrollPadding: const EdgeInsets.only(bottom: 140),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9 ٠-٩]')),
                    TextInputFormatter.withFunction((o, n) {
                      var d = n.text.replaceAllMapped(RegExp('[٠-٩]'), (m) => '${m[0]!.codeUnitAt(0) - 0x660}');
                      final f = _fmtPhone(d);
                      return TextEditingValue(text: f, selection: TextSelection.collapsed(offset: f.length));
                    }),
                  ],
                  decoration: _dec('750 123 4567'),
                  onChanged: (_) {
                    if (err.isNotEmpty) setState(() => err = '');
                  },
                  onSubmitted: (_) => _next(),
                ),
              ),
            ]),
          ),
          _hint(tr('f_phone_h'), Icons.lock_outline_rounded),
        ]);
      case 2:
        final ql = q.text.trim();
        final list = kCities.where((x) => ql.isEmpty || x.contains(ql) || nm(x).toLowerCase().contains(ql.toLowerCase())).toList();
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          _lbl(tr('f_city'), Icons.place_outlined),
          TextField(
            controller: q,
            style: ats(14),
            decoration: _dec(tr('f_city_h')).copyWith(prefixIcon: Icon(Icons.search_rounded, color: AC.mu)),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 8),
          Container(
            height: 196,
            decoration: BoxDecoration(color: AC.surf, borderRadius: BorderRadius.circular(16), border: Border.all(color: AC.line)),
            child: list.isEmpty
                ? Center(child: Text(tr('f_city_none'), style: ats(13, c: AC.mu)))
                : ListView.builder(
                    padding: const EdgeInsets.all(6),
                    itemCount: list.length,
                    itemExtent: 44,
                    itemBuilder: (_, i) {
                      final x = list[i], on = x == city;
                      return _Tap(
                        radius: 12,
                        onTap: () => setState(() {
                          city = x;
                          err = '';
                        }),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 160),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: on ? _a(AC.mint, .14) : null,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: on ? _a(AC.mint, .6) : Colors.transparent, width: 1.5),
                          ),
                          child: Row(children: [
                            Expanded(child: Text(nm(x), style: ats(15, w: on ? FontWeight.w800 : FontWeight.w600))),
                            if (on) Icon(Icons.check_circle_rounded, size: 18, color: AC.mint),
                          ]),
                        ),
                      );
                    },
                  ),
          ),
          _lbl(tr('f_age')),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final a in kAges)
              ChoiceChip(
                label: Text(a[1], style: ats(13.5, w: FontWeight.w800, c: age == a[0] ? AC.onGold : AC.tx)),
                selected: age == a[0],
                showCheckmark: false,
                selectedColor: AC.accent,
                backgroundColor: AC.surf,
                side: BorderSide(color: age == a[0] ? AC.accent : AC.line2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
                onSelected: (_) => setState(() => age = a[0]),
              ),
          ]),
          if (age == 'y') _hint(tr('f_age_y'), Icons.info_outline_rounded),
        ]);
      case 3:
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          _hint(tr('f_char_h'), Icons.face_retouching_natural_rounded),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 4,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            children: [
              for (final id in _free)
                GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() {
                      ch = id;
                      err = '';
                    });
                  },
                  child: AnimatedScale(
                    scale: ch == id ? 1.08 : 1,
                    duration: const Duration(milliseconds: 180),
                    child: Stack(clipBehavior: Clip.none, children: [
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: ch == id ? const [BoxShadow(color: Color(0x88F2B21C), blurRadius: 16)] : null,
                          ),
                          child: CharAvatar(ch: id, name: '', size: 80, gold: ch == id, ring: ch == id ? AC.accent : AC.line2),
                        ),
                      ),
                      if (ch == id)
                        Positioned(
                          top: -2,
                          right: -2,
                          child: Container(
                            width: 22,
                            height: 22,
                            decoration: const BoxDecoration(shape: BoxShape.circle, color: AC.accent),
                            child: const Icon(Icons.check_rounded, size: 15, color: AC.onGold),
                          ),
                        ),
                    ]),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Center(child: Text(ch.isEmpty ? tr('f_char_pick') : tr('f_char_ok'), style: ats(12.5, w: FontWeight.w700, c: AC.mu))),
        ]);
      default:
        final band = c.host.hasBand;
        final live = c.S.live;
        final rem = c.S.daysLeft;
        final elig = <List<Object>>[
          if (!live) [Icons.star_rounded, tr('el_pre'), AC.gold],
          if (live) [Icons.schedule_rounded, tr('el_day', [c.S.day, rem]), AC.cyan],
          if (live && rem >= 25) [Icons.emoji_events_rounded, tr('el_all'), AC.mint],
          if (live && rem < 25 && rem >= 20) [Icons.card_giftcard_rounded, tr('el_guar'), AC.orange],
          if (live && rem < 20) [Icons.groups_rounded, tr('el_week'), AC.orange],
        ];
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: AC.surf, borderRadius: BorderRadius.circular(16), border: Border.all(color: AC.line)),
            child: Row(children: [
              CharAvatar(ch: ch, name: name.text, size: 44, ring: AC.accent),
              const SizedBox(width: 10),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(name.text.trim(), maxLines: 1, overflow: TextOverflow.ellipsis, style: ats(15, w: FontWeight.w800)),
                  Text('${nm(city)} · ${maskPhone('0${phone.text.replaceAll(RegExp(r'\D'), '')}')}',
                      textDirection: arenaDir, maxLines: 1, overflow: TextOverflow.ellipsis, style: ats(12, c: AC.mu)),
                ]),
              ),
              IconButton(onPressed: () => _go(1), icon: Icon(Icons.edit_outlined, size: 18, color: AC.mu)),
            ]),
          ),
          const SizedBox(height: 10),
          _InfoBox(
            icon: band ? Icons.watch_rounded : Icons.smartphone_rounded,
            color: band ? AC.mint : AC.cyan,
            title: band ? tr('dv_band_t') : tr('dv_phone_t'),
            text: band ? tr('dv_band_s') : tr('dv_phone_s'),
          ),
          for (final e in elig) _InfoBox(icon: e[0] as IconData, color: e[2] as Color, text: e[1] as String),
          const SizedBox(height: 4),
          const _ThreeCalls(),
          const SizedBox(height: 10),
          for (final k in ['r_data', 'r_cheat', 'r_lock', 'r_18'])
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Padding(padding: const EdgeInsets.only(top: 2), child: Icon(Icons.check_rounded, size: 15, color: AC.mint)),
                const SizedBox(width: 6),
                Expanded(child: Text(tr(k), style: ats(12, c: AC.mu, h: 1.6))),
              ]),
            ),
          const SizedBox(height: 6),
          _Tap(
            onTap: () => setState(() {
              agree = !agree;
              err = '';
            }),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AC.surf, borderRadius: BorderRadius.circular(14), border: Border.all(color: agree ? AC.accent : AC.line)),
              child: Row(children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: agree ? AC.accent : Colors.transparent,
                    borderRadius: BorderRadius.circular(7),
                    border: Border.all(color: agree ? AC.accent : AC.mu, width: 1.6),
                  ),
                  child: agree ? const Icon(Icons.check_rounded, size: 16, color: AC.onGold) : null,
                ),
                const SizedBox(width: 10),
                Expanded(child: Text(tr('agree'), style: ats(13.5, w: FontWeight.w800))),
              ]),
            ),
          ),
        ]);
    }
  }
}

class _InfoBox extends StatelessWidget {
  const _InfoBox({required this.icon, required this.color, required this.text, this.title});
  final IconData icon;
  final Color color;
  final String text;
  final String? title;
  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          color: _a(color, .09),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _a(color, .38)),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (title != null) Text(title!, style: ats(13.5, w: FontWeight.w800)),
              Text(text, style: ats(12.2, c: title != null ? AC.mu : AC.tx, h: 1.6)),
            ]),
          ),
        ]),
      );
}

/// ئاگاداری: براوە 3 جار پەیوەندی پێوە دەکرێت
class _ThreeCalls extends StatelessWidget {
  const _ThreeCalls();
  @override
  Widget build(BuildContext context) {
    final o = AC.orange;
    Widget dot(Widget ch, Color c) => Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(shape: BoxShape.circle, color: _a(c, .12), border: Border.all(color: _a(c, .7), width: 1.5)),
          child: Center(child: ch),
        );
    Widget call(int n) => Stack(clipBehavior: Clip.none, children: [
          dot(Icon(Icons.call_rounded, size: 15, color: o), o),
          Positioned(
            bottom: -5,
            right: -5,
            child: Container(
              width: 17,
              height: 17,
              decoration: BoxDecoration(shape: BoxShape.circle, color: o),
              child: Center(child: Text('$n', style: ats(10, w: FontWeight.w900, c: Colors.white, h: 1))),
            ),
          ),
        ]);
    Widget dash() => Expanded(child: Container(height: 1.5, margin: const EdgeInsets.symmetric(horizontal: 4), color: _a(o, .45)));
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [_a(o, .14), _a(o, .03)]),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _a(o, .45)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.phone_in_talk_rounded, size: 18, color: o),
          const SizedBox(width: 6),
          Text(tr('win_t'), style: ats(14, w: FontWeight.w800)),
        ]),
        const SizedBox(height: 6),
        Text(tr('win_s'), style: ats(12.5, h: 1.7)),
        const SizedBox(height: 12),
        Row(children: [call(1), dash(), call(2), dash(), call(3), dash(), dot(Icon(Icons.close_rounded, size: 16, color: AC.coral), AC.coral)]),
      ]),
    );
  }
}

// =============================================================================
// 12. تابی «ئەمڕۆ»
// =============================================================================

class _TodayTab extends StatelessWidget {
  const _TodayTab({required this.s});
  final _VexArenaPageState s;
  ArenaCtl get c => s.c;

  @override
  Widget build(BuildContext context) {
    final live = c.S.live;
    final pad = MediaQuery.of(context).padding.bottom;
    return ListView(
      key: const PageStorageKey('arena_today'),
      padding: EdgeInsets.fromLTRB(16, 4, 16, 28 + pad),
      children: [
        s.sponsorSlot(),
        _Hero(c: c, clock: s.clock),
        if (c.div == Div.phone)
          _InfoBox(icon: Icons.smartphone_rounded, color: AC.cyan, title: tr('pb_t'), text: tr('pb_s')),
        if (!live) _RegisteredCard(c: c),
        if (live) _GoalCard(c: c),
        if (live && c.store.cb == c.tk) _InfoBox(icon: Icons.star_rounded, color: AC.mint, title: tr('cb_t'), text: tr('cb_s')),
        _Missions(c: c),
        if (live) _WeekStrip(s: s),
        if (live) _PowerCard(c: c),
        _PrizePanel(s: s),
        if (!live) const _EarlyJoin(),
        if (live) _YouCard(c: c),
        _Activities(c: c, practice: !live),
        Row(children: [
          Expanded(child: _Btn(tr('fair_t'), icon: Icons.verified_user_rounded, primary: false, small: true, onTap: () => fairSheet(context, c))),
          const SizedBox(width: 8),
          Expanded(child: _Btn(tr('rules'), icon: Icons.menu_book_rounded, primary: false, small: true, onTap: () => rulesSheet(context, c))),
        ]),
      ],
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.c, required this.clock});
  final ArenaCtl c;
  final ValueNotifier<DateTime> clock;
  @override
  Widget build(BuildContext context) {
    final S = c.S;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const RadialGradient(center: Alignment(0, -1.1), radius: 1.3, colors: [Color(0xFF2A2F6A), AC.stage1, AC.stage2]),
        border: Border.all(color: _a(AC.goldS, .3)),
        boxShadow: AC.sh,
      ),
      child: Column(children: [
        Row(children: [
          _Pill(S.live ? tr('live') : tr('soon'), color: S.live ? const Color(0xFFFF6F86) : AC.goldS, icon: Icons.circle),
          const SizedBox(width: 8),
          Expanded(
            child: Text('VEX ARENA · SEASON ${S.n}',
                maxLines: 1, overflow: TextOverflow.ellipsis, style: ats(11.5, w: FontWeight.w800, c: AC.goldS, ls: 2)),
          ),
        ]),
        const SizedBox(height: 10),
        Text(S.live ? tr('hero_t') : tr('hero_pre', [S.n]),
            textAlign: TextAlign.center, style: ats(25, w: FontWeight.w900, c: AC.stageTx, h: 1.3)),
        const SizedBox(height: 4),
        Text(tr('hero_s'), textAlign: TextAlign.center, style: ats(13, c: AC.stageMu)),
        const SizedBox(height: 14),
        const _Trophy(),
        const SizedBox(height: 12),
        Text(S.live ? tr('cd_end') : tr('cd_start'), style: ats(13, w: FontWeight.w800, c: AC.goldS)),
        const SizedBox(height: 8),
        ValueListenableBuilder<DateTime>(
          valueListenable: clock,
          builder: (_, now, __) {
            final d = S.end.difference(now);
            final t = d.isNegative ? Duration.zero : d;
            final v = [t.inDays, t.inHours % 24, t.inMinutes % 60, t.inSeconds % 60];
            final l = [tr('u_d'), tr('u_h'), tr('u_m'), tr('u_s')];
            return Row(children: [
              for (var i = 0; i < 4; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0x14FFFFFF),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0x26FFFFFF)),
                    ),
                    child: Column(children: [
                      FittedBox(
                        child: Text(_p2(v[i]),
                            style: ats(26, w: FontWeight.w900, c: i == 3 ? AC.goldS : AC.stageTx, h: 1.1)),
                      ),
                      Text(l[i], style: ats(11, c: AC.stageMu)),
                    ]),
                  ),
                ),
              ],
            ]);
          },
        ),
        const SizedBox(height: 12),
        Wrap(alignment: WrapAlignment.center, spacing: 14, runSpacing: 4, children: [
          _meta(Icons.groups_rounded, tr('m_players', [afmt(c.players().length)])),
          if (S.live) _meta(Icons.calendar_month_rounded, tr('m_day', [S.day])),
          _meta(Icons.emoji_events_rounded, tr('m_prizes')),
        ]),
      ]),
    );
  }

  Widget _meta(IconData i, String t) => Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(i, size: 14, color: AC.stageMu),
        const SizedBox(width: 4),
        Text(t, style: ats(12.5, w: FontWeight.w700, c: AC.stageTx)),
      ]);
}

class _Trophy extends StatelessWidget {
  const _Trophy();
  @override
  Widget build(BuildContext context) => SizedBox(
        height: 170,
        child: Stack(alignment: Alignment.center, children: [
          Container(
            width: 190,
            height: 190,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [Color(0x55FFD36B), Color(0x14FFD36B), Color(0x00FFD36B)]),
            ),
          ),
          Positioned(
            top: 6,
            child: ShaderMask(
              shaderCallback: (r) => AC.goldG.createShader(r),
              child: const Icon(Icons.emoji_events_rounded, size: 124, color: Colors.white),
            ),
          ),
          Positioned(
            bottom: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                gradient: AC.goldG,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF8A5A06), width: 1.5),
                boxShadow: const [BoxShadow(color: Color(0x66F2B21C), blurRadius: 14)],
              ),
              child: Text('VEX 2026', textDirection: TextDirection.ltr, style: ats(15, w: FontWeight.w900, c: const Color(0xFF3A2600), ls: 2)),
            ),
          ),
        ]),
      );
}

class _RegisteredCard extends StatelessWidget {
  const _RegisteredCard({required this.c});
  final ArenaCtl c;
  @override
  Widget build(BuildContext context) => _Box(
        border: _a(AC.mint, .45),
        child: Row(children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), color: _a(AC.mint, .16)),
            child: Icon(Icons.verified_rounded, color: AC.mint, size: 28),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(tr('reg_k', [c.S.n]), style: ats(11.5, w: FontWeight.w800, c: AC.mint)),
              Text(tr('reg_t', [c.store.acc?.name ?? '']), style: ats(15.5, w: FontWeight.w800)),
              Text(tr('reg_s'), style: ats(12, c: AC.mu, h: 1.6)),
            ]),
          ),
        ]),
      );
}

class _Ring extends CustomPainter {
  _Ring(this.f, this.mark, this.track, this.markOn);
  final double f, mark;
  final Color track;
  final bool markOn;
  @override
  void paint(Canvas c, Size s) {
    final r = s.width / 2 - 8;
    final ctr = s.center(Offset.zero);
    c.drawCircle(ctr, r, Paint()
      ..color = track
      ..style = PaintingStyle.stroke
      ..strokeWidth = 11);
    if (f > 0) {
      final rect = Rect.fromCircle(center: ctr, radius: r);
      c.drawArc(
          rect,
          -math.pi / 2,
          math.pi * 2 * f.clamp(0.0, 1.0),
          false,
          Paint()
            ..shader = const SweepGradient(colors: [Color(0xFFFFF0B0), Color(0xFFFFD25A), Color(0xFFE7A514), Color(0xFFFFF0B0)])
                .createShader(rect)
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.round
            ..strokeWidth = 11);
    }
    final a = -math.pi / 2 + math.pi * 2 * mark.clamp(0.0, 1.0);
    final p = ctr + Offset(math.cos(a) * r, math.sin(a) * r);
    c.drawCircle(p, 5, Paint()..color = markOn ? const Color(0xFF3CF08A) : const Color(0xFF0B1433));
    c.drawCircle(p, 5, Paint()
      ..color = const Color(0xFF3CF08A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2);
  }

  @override
  bool shouldRepaint(_Ring o) => o.f != f || o.mark != mark || o.track != track || o.markOn != markOn;
}

class _GoalCard extends StatelessWidget {
  const _GoalCard({required this.c});
  final ArenaCtl c;
  @override
  Widget build(BuildContext context) {
    final t = c.today.tot, g = c.goal, act = c.active;
    final counted = t >= act, done = t >= g;
    final bm = c.bestMoves();
    final sh = c.shield();
    final lost = sh.where((x) => x == 'x').length;
    final streak = c.store.streak + (counted ? 1 : 0);
    return _Box(
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          SizedBox(
            width: 126,
            height: 126,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: (t / g).clamp(0.0, 1.0).toDouble()),
              duration: const Duration(milliseconds: 1100),
              curve: Curves.easeOutCubic,
              builder: (_, v, __) => CustomPaint(
                painter: _Ring(v, act / g, AC.track, counted),
                child: Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    FittedBox(child: Text(afmt(t), style: ats(30, w: FontWeight.w900, h: 1.05))),
                    Text(tr('of_n', [g]), style: ats(12, c: AC.mu, w: FontWeight.w700)),
                  ]),
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(tr('goal_k'), style: ats(12, w: FontWeight.w800, c: AC.gold)),
              const SizedBox(height: 4),
              if (done) ...[
                _okLine(tr('goal_done')),
                Text(tr('goal_more'), style: ats(12.5, c: AC.mu, h: 1.6)),
              ] else if (counted) ...[
                _okLine(tr('counted')),
                Text(tr('to_goal', [g - t, g]), style: ats(12.5, c: AC.mu, h: 1.6)),
              ] else ...[
                Text(tr('to_count', [act - t]), style: ats(15.5, w: FontWeight.w800, h: 1.4)),
                Text(tr('day_n_of', [c.activeDays + 1, 25]), style: ats(12.5, c: AC.mu, h: 1.6)),
              ],
            ]),
          ),
        ]),
        if (bm.isNotEmpty && !done) ...[
          const SizedBox(height: 14),
          _Tap(
            onTap: () => catSheet(context, c, bm.first.cat),
            child: Ink(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(gradient: AC.goldG, borderRadius: BorderRadius.circular(16)),
              child: Row(children: [
                CatTile(bm.first.cat, size: 30),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(tr('do_now', [bm.first.cat.name, bm.first.cap - bm.first.base]),
                      style: ats(14, w: FontWeight.w800, c: AC.onGold)),
                ),
                Icon(arenaLtr ? Icons.chevron_right_rounded : Icons.chevron_left_rounded, color: AC.onGold),
              ]),
            ),
          ),
          if (bm.length > 1) ...[
            const SizedBox(height: 8),
            Wrap(spacing: 6, runSpacing: 6, children: [
              for (final r in bm.skip(1))
                _Tap(
                  radius: 99,
                  onTap: () => catSheet(context, c, r.cat),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(color: AC.surf, borderRadius: BorderRadius.circular(99), border: Border.all(color: AC.line)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(r.cat.icon, size: 14, color: r.cat.color),
                      const SizedBox(width: 4),
                      Text('${r.cat.name} ', style: ats(12, w: FontWeight.w700)),
                      Text('+${r.cap - r.base}', style: ats(12, w: FontWeight.w800, c: AC.mint)),
                    ]),
                  ),
                ),
            ]),
          ],
        ],
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _MiniPill(icon: Icons.local_fire_department_rounded, color: AC.orange, value: '$streak', label: tr('streak'), onTap: () => arenaToast(context, tr('streak_toast', [streak]), Icons.local_fire_department_rounded))),
          const SizedBox(width: 6),
          Expanded(child: _MiniPill(icon: Icons.shield_rounded, color: AC.cyan, value: '${c.store.frz}/2', label: tr('freeze'), onTap: () => freezeSheet(context, c))),
          const SizedBox(width: 6),
          Expanded(child: _MiniPill(icon: Icons.event_busy_rounded, color: AC.violet, value: '${3 - c.store.exc.length}/3', label: tr('excuse'), onTap: () => excuseSheet(context, c))),
        ]),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(colors: [_a(AC.orange, .12), _a(AC.orange, .02)]),
            border: Border.all(color: _a(AC.orange, .3)),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [
              Icon(Icons.shield_outlined, size: 15, color: AC.tx),
              const SizedBox(width: 5),
              Expanded(child: Text(tr('shield_t'), style: ats(13, w: FontWeight.w800))),
              Text(tr('plus_pts', [math.max(0, 70 - lost * 10)]), style: ats(13, w: FontWeight.w800, c: AC.orange)),
            ]),
            const SizedBox(height: 10),
            Row(children: [
              for (var i = 0; i < 7; i++) ...[
                if (i > 0) const SizedBox(width: 5),
                Expanded(child: _ShieldSeg(sh[i])),
              ],
            ]),
            const SizedBox(height: 8),
            Text(lost > 0 ? '${tr('shield_lost', [lost])} ${tr('shield_s')}' : tr('shield_s'), style: ats(11.5, c: AC.mu, h: 1.6)),
          ]),
        ),
      ]),
    );
  }

  Widget _okLine(String t) => Row(children: [
        Icon(Icons.check_circle_rounded, size: 16, color: AC.mint),
        const SizedBox(width: 5),
        Flexible(child: Text(t, style: ats(15.5, w: FontWeight.w800, c: AC.mint, h: 1.4))),
      ]);
}

class _ShieldSeg extends StatelessWidget {
  const _ShieldSeg(this.k);
  final String k;
  @override
  Widget build(BuildContext context) {
    final o = AC.orange;
    final ok = k == 'ok', now = k == 'now', x = k == 'x';
    return Container(
      height: 30,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        gradient: ok ? const LinearGradient(colors: [Color(0xFFFFB36B), Color(0xFFFF6A3D)], begin: Alignment.topCenter, end: Alignment.bottomCenter) : null,
        color: ok ? null : (x ? AC.surf : _a(o, now ? .18 : .1)),
        border: now ? Border.all(color: o, width: 1.5) : null,
      ),
      child: Icon(x ? Icons.close_rounded : Icons.local_fire_department_rounded,
          size: 14, color: ok ? Colors.white : (x ? AC.mu : _a(o, now ? 1 : .6))),
    );
  }
}

class _MiniPill extends StatelessWidget {
  const _MiniPill({required this.icon, required this.color, required this.value, required this.label, this.onTap});
  final IconData icon;
  final Color color;
  final String value, label;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => _Tap(
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
          decoration: BoxDecoration(color: AC.surf, borderRadius: BorderRadius.circular(16), border: Border.all(color: AC.line)),
          child: Column(children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(color: _a(color, .16), borderRadius: BorderRadius.circular(11)),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(height: 4),
            Text(value, textDirection: TextDirection.ltr, style: ats(17, w: FontWeight.w900)),
            Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: ats(11, w: FontWeight.w700, c: AC.mu)),
          ]),
        ),
      );
}

class _Missions extends StatelessWidget {
  const _Missions({required this.c});
  final ArenaCtl c;
  @override
  Widget build(BuildContext context) {
    final ms = c.missions();
    final done = ms.where((m) => m.ok).length;
    final open = c.chestOpen;
    final ready = done == 3 && !open;
    return _Box(
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        _Head(tr('ms_t'), small: tr('n_of_3', [done])),
        for (var i = 0; i < ms.length; i++) ...[
          if (i > 0) Divider(height: 14, color: AC.line),
          Row(children: [
            CatTile(ms[i].cat, size: 34),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(tr(ms[i].key, [ms[i].target]), style: ats(13.5, w: FontWeight.w800, c: ms[i].ok ? AC.mint : AC.tx)),
                const SizedBox(height: 5),
                _Bar(ms[i].v / ms[i].target, color: ms[i].cat.color, h: 4),
              ]),
            ),
            const SizedBox(width: 10),
            SizedBox(
              width: 46,
              child: Center(
                child: ms[i].ok
                    ? Icon(Icons.check_rounded, color: AC.mint, size: 20)
                    : Text('${ms[i].v}/${ms[i].target}', textDirection: TextDirection.ltr, style: ats(12, w: FontWeight.w800, c: AC.mu)),
              ),
            ),
          ]),
        ],
        const SizedBox(height: 12),
        _Tap(
          onTap: () {
            if (ready) {
              chestSheet(context, c);
            } else if (!open) {
              arenaToast(context, tr('chest_need', [3 - done]), Icons.card_giftcard_rounded);
            }
          },
          child: Ink(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: ready ? LinearGradient(colors: [_a(AC.accent, .22), _a(AC.accent, .05)]) : null,
              border: Border.all(color: ready ? AC.accent : AC.line2, width: ready ? 1.5 : 1),
            ),
            child: Row(children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: ready ? AC.goldG : null,
                  color: ready ? null : (open ? _a(AC.mint, .16) : AC.surf),
                ),
                child: Icon(Icons.card_giftcard_rounded, color: ready ? const Color(0xFF5A3A00) : (open ? AC.mint : AC.mu)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(open ? tr('chest_got', [c.store.chest?['c'] ?? 0]) : (ready ? tr('chest_ready') : tr('chest_t')),
                      style: ats(14, w: FontWeight.w800)),
                  Text(open ? tr('chest_tomorrow') : (ready ? tr('chest_range') : tr('chest_need', [3 - done])), style: ats(12, c: AC.mu)),
                ]),
              ),
            ]),
          ),
        ),
      ]),
    );
  }
}

class _WeekStrip extends StatelessWidget {
  const _WeekStrip({required this.s});
  final _VexArenaPageState s;
  @override
  Widget build(BuildContext context) {
    final c = s.c;
    final g = c.weekGroup();
    final me = g.firstWhere((x) => x.me, orElse: () => g.first);
    final small = g.length < 5;
    final idx = g.indexOf(me);
    final near = g.sublist(math.max(0, idx - 2), math.min(g.length, idx + 3));
    final above = idx > 0 ? g[idx - 1] : null;
    final zoneGap = me.r > 10 && g.length >= 10 ? g[9].p - me.p + 1 : 0;
    final w = weekInfo(c.now);
    return _Box(
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        _Tap(
          onTap: () {
            s.upd(() => s.seg = 'week');
            s.goTab(1);
          },
          child: Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(tr('wk_k', [tr(c.div == Div.band ? 'dv_band' : 'dv_phone')]), style: ats(11.5, w: FontWeight.w700, c: AC.mu)),
                Text(tr('rank_of', [me.r, g.length]), style: ats(24, w: FontWeight.w900)),
                Text(tr('wk_left', [w.left + 1]), style: ats(11.5, c: AC.mu)),
              ]),
            ),
            if (small)
              _Pill(tr('wk_members', [g.length]), icon: Icons.groups_rounded)
            else
              _Pill(
                me.r <= 3 ? tr('wk_champ', [weekReward(me.r)]) : (me.r <= 10 ? tr('wk_zone') : tr('wk_gap', [zoneGap])),
                color: me.r <= 10 ? AC.mint : AC.mu,
                solid: me.r <= 3,
              ),
          ]),
        ),
        const SizedBox(height: 10),
        for (final x in near)
          Container(
            margin: const EdgeInsets.only(bottom: 3),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: x.me ? _a(AC.accent, .14) : null,
              borderRadius: BorderRadius.circular(12),
              border: x.me ? Border.all(color: _a(AC.accent, .45)) : null,
            ),
            child: Row(children: [
              SizedBox(width: 24, child: Text('${x.r}', textAlign: TextAlign.center, style: ats(13, w: FontWeight.w800, c: x.me ? AC.gold : AC.mu))),
              const SizedBox(width: 6),
              CharAvatar(ch: x.ch, name: x.n, size: 28, ring: x.me ? AC.cyan : null),
              const SizedBox(width: 8),
              Expanded(child: Text(x.me ? tr('you') : nm(x.n), maxLines: 1, overflow: TextOverflow.ellipsis, style: ats(13, w: FontWeight.w700, c: x.me ? AC.gold : AC.tx))),
              Text(afmt(x.p), style: ats(13.5, w: FontWeight.w800)),
            ]),
          ),
        const SizedBox(height: 6),
        Row(children: [
          Icon(above != null ? Icons.trending_up_rounded : Icons.workspace_premium_rounded, size: 15, color: AC.mint),
          const SizedBox(width: 5),
          Expanded(
            child: Text(above != null ? tr('rival', [nm(above.n), above.p - me.p + 1]) : tr('rival_top'),
                style: ats(12.5, c: AC.mu)),
          ),
        ]),
      ]),
    );
  }
}

class _PowerCard extends StatelessWidget {
  const _PowerCard({required this.c});
  final ArenaCtl c;
  @override
  Widget build(BuildContext context) {
    final g = c.store.guess[c.tk];
    final early = c.now.hour < 6;
    final y = c.store.days[c.yk];
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(colors: [Color(0xFF2B1F5E), Color(0xFF151036)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        border: Border.all(color: const Color(0x669B7BFF)),
        boxShadow: AC.sh,
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: const LinearGradient(colors: [Color(0xFFC6B4FF), Color(0xFF7B5CFF)]),
              boxShadow: const [BoxShadow(color: Color(0x667B5CFF), blurRadius: 16)],
            ),
            child: Center(child: Text('?', style: ats(30, w: FontWeight.w900, c: Colors.white))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(tr('pw_t'), style: ats(17, w: FontWeight.w800, c: Colors.white)),
              Text(tr('pw_s'), style: ats(12.5, c: const Color(0xFFD6CCFF), h: 1.6)),
            ]),
          ),
        ]),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: const Color(0x14FFFFFF), borderRadius: BorderRadius.circular(14)),
          child: Row(children: [
            const Icon(Icons.lightbulb_outline_rounded, size: 18, color: Color(0xFFFFD36B)),
            const SizedBox(width: 8),
            Expanded(child: Text(tr('hint_${c.today.power}'), style: ats(13, w: FontWeight.w700, c: Colors.white))),
          ]),
        ),
        const SizedBox(height: 10),
        if (g == null)
          _Tap(
            onTap: () => guessSheet(context, c),
            child: Ink(
              height: 50,
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
              child: Center(child: Text(tr('pw_go'), style: ats(15, w: FontWeight.w900, c: const Color(0xFF2B1F5E)))),
            ),
          )
        else
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: const Color(0x14FFFFFF), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0x33FFFFFF))),
            child: Row(children: [
              CatTile(catById(g), size: 34),
              const SizedBox(width: 10),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(tr('pw_mine', [catById(g).name]), style: ats(13.5, w: FontWeight.w800, c: Colors.white)),
                  Text(tr('pw_when'), style: ats(11.5, c: const Color(0xFFD6CCFF))),
                ]),
              ),
              const Icon(Icons.lock_rounded, color: Color(0xFFD6CCFF), size: 18),
            ]),
          ),
        const SizedBox(height: 8),
        _Tap(
          onTap: () => early ? arenaToast(context, tr('y_early'), Icons.schedule_rounded) : yesterdaySheet(context, c),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            child: Row(children: [
              Expanded(
                child: Text(
                  early
                      ? tr('y_early')
                      : tr('y_line', [catById(powerOf(c.yk)).name, catById(secondOf(c.yk)).name, afmt(y?.t ?? 0)]),
                  style: ats(12.5, c: const Color(0xFFD6CCFF)),
                ),
              ),
              Icon(arenaLtr ? Icons.chevron_right_rounded : Icons.chevron_left_rounded, color: const Color(0xFFD6CCFF)),
            ]),
          ),
        ),
      ]),
    );
  }
}

class _PrizePanel extends StatelessWidget {
  const _PrizePanel({required this.s});
  final _VexArenaPageState s;
  @override
  Widget build(BuildContext context) {
    final c = s.c;
    final d = s.przDiv ?? c.div;
    final z = kPrizes[d]!;
    Widget col(Prize p, double h, Color c1, Color c3) => Expanded(
          child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
            Container(
              width: p.r == 1 ? 64 : 52,
              height: p.r == 1 ? 64 : 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _a(c3, .14),
                border: Border.all(color: _a(c3, .55)),
                boxShadow: [BoxShadow(color: _a(c3, .3), blurRadius: 18)],
              ),
              child: Icon(p.icon, color: c3, size: p.r == 1 ? 32 : 26),
            ),
            const SizedBox(height: 6),
            Text(p.name, textAlign: TextAlign.center, maxLines: 2, style: ats(p.r == 1 ? 13.5 : 12, w: FontWeight.w800, c: p.r == 1 ? AC.goldS : AC.stageTx, h: 1.3)),
            const SizedBox(height: 6),
            Container(
              height: h,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                gradient: LinearGradient(colors: [c1, _a(c1, .35)], begin: Alignment.topCenter, end: Alignment.bottomCenter),
                border: Border.all(color: _a(c3, .5)),
              ),
              child: Center(child: Text('${p.r}', style: ats(p.r == 1 ? 34 : 26, w: FontWeight.w900, c: c3))),
            ),
          ]),
        );
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(colors: [AC.stage1, AC.stage2], begin: Alignment.topCenter, end: Alignment.bottomCenter),
        border: Border.all(color: _a(AC.goldS, .35)),
        boxShadow: AC.sh,
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        _Head(tr('pz_t', [tr(d == Div.band ? 'dv_band' : 'dv_phone')]), small: tr(d == Div.band ? 'pz_big' : 'pz_norm'), color: AC.stageTx),
        _Tap(
          onTap: () => prizeSheet(context, c, d),
          child: SizedBox(
            height: 216,
            child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              col(z[1], 72, const Color(0x52D2DCF5), const Color(0xFFDFE6FB)),
              const SizedBox(width: 8),
              col(z[0], 104, const Color(0x99FFD26E), AC.goldS),
              const SizedBox(width: 8),
              col(z[2], 56, const Color(0x73E69650), const Color(0xFFFFB27A)),
            ]),
          ),
        ),
        const SizedBox(height: 12),
        _stageLine(Icons.emoji_events_rounded, tr('pz_week_t'), tr('pz_week_s')),
        _stageLine(Icons.card_giftcard_rounded, tr('pz_guar_t'), tr(d == Div.band ? 'pz_guar_b' : 'pz_guar_p')),
        const SizedBox(height: 4),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.flag_rounded, size: 15, color: AC.stageMu),
          const SizedBox(width: 5),
          Flexible(child: Text(tr('pz_rule', [activeMin(d)]), textAlign: TextAlign.center, style: ats(12.5, c: AC.stageMu, w: FontWeight.w700))),
        ]),
        const SizedBox(height: 10),
        _Tap(
          onTap: () => s.upd(() => s.przDiv = d == Div.band ? Div.phone : Div.band),
          child: Ink(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(color: const Color(0x0DFFFFFF), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0x24FFFFFF))),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(d == Div.band ? Icons.smartphone_rounded : Icons.watch_rounded, size: 15, color: AC.stageMu),
              const SizedBox(width: 6),
              Text(tr('pz_other', [tr(d == Div.band ? 'dv_phone' : 'dv_band')]), style: ats(12.5, w: FontWeight.w700, c: AC.stageMu)),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _stageLine(IconData i, String t, String s) => Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: const Color(0x0FFFFFFF), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0x38FFD678))),
        child: Row(children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(color: const Color(0x29FFC846), borderRadius: BorderRadius.circular(10)),
            child: Icon(i, size: 18, color: AC.goldS),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(t, style: ats(13, w: FontWeight.w800, c: Colors.white)),
              Text(s, style: ats(11.5, c: const Color(0xFFC9CFEA), h: 1.5)),
            ]),
          ),
        ]),
      );
}

class _EarlyJoin extends StatelessWidget {
  const _EarlyJoin();
  @override
  Widget build(BuildContext context) {
    Widget seg(int f, Color c, String t, {bool dark = true}) => Expanded(
          flex: f,
          child: Container(
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(8)),
            child: FittedBox(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: Text(t, style: ats(11, w: FontWeight.w800, c: dark ? const Color(0xFF1C1300) : AC.mu)))),
          ),
        );
    final rows = [
      [Icons.star_rounded, tr('ej_badge'), ''],
      [Icons.toll_rounded, '+50', '+20'],
      [Icons.calendar_month_rounded, tr('ej_all30'), tr('ej_left')],
      [Icons.emoji_events_rounded, tr('ej_allpz'), tr('ej_to6')],
      [Icons.groups_rounded, tr('ej_week'), tr('ej_week')],
      [Icons.workspace_premium_rounded, tr('ej_tie'), ''],
    ];
    return _Box(
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        _Head(tr('ej_t'), small: tr('ej_s')),
        Row(children: [
          seg(4, const Color(0xFFFFD25A), tr('now')),
          const SizedBox(width: 3),
          seg(6, const Color(0xFF4FE08F), '1–6'),
          const SizedBox(width: 3),
          seg(5, const Color(0xFFFFB06B), '7–11'),
          const SizedBox(width: 3),
          seg(9, AC.track, '12–30', dark: false),
        ]),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: AC.line)),
          clipBehavior: Clip.antiAlias,
          child: Column(children: [
            Row(children: [
              const SizedBox(width: 40),
              Expanded(child: Container(color: AC.accent, padding: const EdgeInsets.all(10), child: Text(tr('ej_before'), textAlign: TextAlign.center, style: ats(12, w: FontWeight.w800, c: AC.onGold)))),
              Expanded(child: Padding(padding: const EdgeInsets.all(10), child: Text(tr('ej_after'), textAlign: TextAlign.center, style: ats(12, w: FontWeight.w800, c: AC.mu)))),
            ]),
            for (final r in rows)
              Container(
                decoration: BoxDecoration(border: Border(top: BorderSide(color: AC.line))),
                child: IntrinsicHeight(
                  child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    SizedBox(width: 40, child: Icon(r[0] as IconData, size: 16, color: AC.mu)),
                    Expanded(
                      child: Container(
                        color: _a(AC.accent, .1),
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
                        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Icon(Icons.check_rounded, size: 14, color: AC.mint),
                          const SizedBox(width: 3),
                          Flexible(child: Text(r[1] as String, textAlign: TextAlign.center, style: ats(12, w: FontWeight.w800, c: AC.gold))),
                        ]),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
                        child: (r[2] as String).isEmpty
                            ? Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                                Icon(Icons.close_rounded, size: 14, color: AC.coral),
                                Text(' ${tr('none')}', style: ats(12, w: FontWeight.w700, c: AC.coral)),
                              ])
                            : Text(r[2] as String, textAlign: TextAlign.center, style: ats(12, w: FontWeight.w700, c: AC.mu)),
                      ),
                    ),
                  ]),
                ),
              ),
          ]),
        ),
      ]),
    );
  }
}

class _YouCard extends StatelessWidget {
  const _YouCard({required this.c});
  final ArenaCtl c;
  @override
  Widget build(BuildContext context) {
    final tot = c.myTotal, lg = leagueOf(tot, c.div);
    final have = c.activeDays + c.store.exc.length, need = 25, left = c.S.daysLeft;
    final ok = have >= need, can = have + left - 1 >= need;
    return _Box(
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Expanded(
            child: Wrap(spacing: 6, runSpacing: 4, crossAxisAlignment: WrapCrossAlignment.center, children: [
              Text(tr('you_t'), style: ats(15, w: FontWeight.w800, c: AC.gold)),
              _Pill(tr(c.div == Div.band ? 'dv_band' : 'dv_phone'), icon: c.div == Div.band ? Icons.watch_rounded : Icons.smartphone_rounded, color: c.div == Div.band ? AC.mint : AC.cyan),
              if (c.founder) _Pill(tr('founder'), icon: Icons.star_rounded, solid: true) else _Pill(tr('joined_day', [math.max(1, c.joinDay)])),
            ]),
          ),
          Text('#${afmt(c.rankOf(tot))}', style: ats(16, w: FontWeight.w900, c: AC.gold)),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: Text(tr('act_days'), style: ats(13, w: FontWeight.w700))),
          Text(tr('n_of', [have, need]), style: ats(13, w: FontWeight.w800, c: AC.gold)),
        ]),
        const SizedBox(height: 6),
        _Bar(have / need, h: 8),
        const SizedBox(height: 8),
        Text(
          ok ? tr('el_ok') : can ? tr('el_can', [left, need - have]) : (have + left - 1 >= 20 ? tr('el_no25') : tr('el_noall')),
          style: ats(12.5, c: AC.mu, h: 1.6),
        ),
        Divider(height: 24, color: AC.line),
        Row(children: [
          _Stat(Icon(Icons.shield_rounded, color: lg.color, size: 22), lg.name, tr('league')),
          _Stat(Icon(Icons.bar_chart_rounded, color: AC.cyan, size: 22), afmt(tot), tr('season_tot')),
          _Stat(Icon(Icons.star_rounded, color: AC.violet, size: 22), '${levelOf(tot)}', tr('level')),
          _Stat(Icon(Icons.track_changes_rounded, color: AC.orange, size: 22), afmt(c.avgDaily), tr('avg')),
        ]),
      ]),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.icon, this.v, this.l);
  final Widget icon;
  final String v, l;
  @override
  Widget build(BuildContext context) => Expanded(
        child: Column(children: [
          icon,
          const SizedBox(height: 4),
          FittedBox(child: Text(v, style: ats(15, w: FontWeight.w900))),
          Text(l, maxLines: 1, overflow: TextOverflow.ellipsis, style: ats(11, c: AC.mu)),
        ]),
      );
}

class _Activities extends StatelessWidget {
  const _Activities({required this.c, required this.practice});
  final ArenaCtl c;
  final bool practice;
  @override
  Widget build(BuildContext context) {
    final rows = [...c.today.rows]..sort((a, b) {
        if ((a.cap > 0) != (b.cap > 0)) return a.cap > 0 ? -1 : 1;
        if ((a.base > 0) != (b.base > 0)) return a.base > 0 ? -1 : 1;
        return (b.cap == 0 ? 0 : b.base / b.cap).compareTo(a.cap == 0 ? 0 : a.base / a.cap);
      });
    final n = rows.where((r) => r.cap > 0).length, done = rows.where((r) => r.base > 0).length;
    final ls = c.lastSync;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Padding(
        padding: const EdgeInsets.only(bottom: 10, top: 2),
        child: Row(children: [
          Expanded(child: Text(practice ? tr('act_t_pre') : tr('act_t'), style: ats(19, w: FontWeight.w900))),
          _Tap(
            radius: 99,
            onTap: () {
              c.refresh();
              arenaToast(context, tr('synced'), Icons.sync_rounded);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(color: _a(AC.mint, .08), borderRadius: BorderRadius.circular(99), border: Border.all(color: _a(AC.mint, .4))),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.verified_user_rounded, size: 13, color: AC.mint),
                const SizedBox(width: 4),
                Text('${tr('sync')} · ${_p2(ls.hour)}:${_p2(ls.minute)}', style: ats(11.5, w: FontWeight.w800, c: AC.mint)),
                const SizedBox(width: 4),
                Icon(Icons.sync_rounded, size: 13, color: AC.mint),
              ]),
            ),
          ),
        ]),
      ),
      for (final r in rows) _ActRow(c: c, r: r, d: c.data[r.cat.id] ?? const CatValue('', 0, 'none')),
      _Box(
        border: _a(AC.accent, .4),
        gradient: LinearGradient(colors: [_a(AC.accent, .12), _a(AC.accent, .03)]),
        child: Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(practice ? tr('tot_pre') : tr('tot_t'), style: ats(15, w: FontWeight.w800)),
              Text(tr('tot_s', [done, n]), style: ats(12, c: AC.mu)),
            ]),
          ),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(afmt(c.today.tot), style: ats(28, w: FontWeight.w900, c: AC.gold, h: 1.1)),
            Text(tr('of_n', [maxDay(c.div)]), style: ats(12, c: AC.mu)),
          ]),
        ]),
      ),
    ]);
  }
}

class _ActRow extends StatelessWidget {
  const _ActRow({required this.c, required this.r, required this.d});
  final ArenaCtl c;
  final PointRow r;
  final CatValue d;
  @override
  Widget build(BuildContext context) {
    final na = r.cap == 0;
    final f = na ? 0.0 : r.base / r.cap;
    Widget badge() {
      if (na || d.st == 'na') return _Pill('Band', icon: Icons.lock_rounded, color: AC.mu);
      if (d.st == 'rej') return _Pill(tr('rejected'), icon: Icons.close_rounded, color: AC.coral);
      if (d.st == 'wait') return _Pill('Band', icon: Icons.schedule_rounded, color: AC.mu);
      if (d.note.isNotEmpty) return _Pill(tr('partial'), icon: Icons.info_outline_rounded, color: AC.orange);
      if (d.st == 'ok') return Icon(Icons.verified_rounded, size: 14, color: AC.mint);
      return const SizedBox.shrink();
    }

    return Opacity(
      opacity: na ? .55 : 1,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(color: AC.card, borderRadius: BorderRadius.circular(22), border: Border.all(color: AC.line), boxShadow: AC.sh),
        child: _Tap(
          radius: 22,
          onTap: () => catSheet(context, c, r.cat),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(children: [
              CatTile(r.cat, size: 46, dim: na),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(r.cat.name, style: ats(15, w: FontWeight.w800)),
                  const SizedBox(height: 2),
                  Row(children: [
                    Flexible(child: Text(d.label, maxLines: 1, overflow: TextOverflow.ellipsis, style: ats(12.5, c: AC.mu))),
                    const SizedBox(width: 6),
                    badge(),
                  ]),
                  const SizedBox(height: 8),
                  _Bar(f, color: r.cat.color, h: 5),
                ]),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 54,
                child: Column(children: [
                  FittedBox(child: Text(na ? '—' : '${r.base}', style: ats(24, w: FontWeight.w900, h: 1.1, c: na ? AC.mu : AC.tx))),
                  Text(na ? tr('dv_band') : tr('of_n', [r.cap]), maxLines: 1, overflow: TextOverflow.ellipsis, style: ats(11, c: AC.mu)),
                ]),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// 13. تابی «پلەکان»
// =============================================================================

class _RankTab extends StatelessWidget {
  const _RankTab({required this.s});
  final _VexArenaPageState s;

  @override
  Widget build(BuildContext context) {
    final c = s.c;
    final d = s.rankDiv ?? c.div;
    final pad = MediaQuery.of(context).padding.bottom;
    final mine = d == c.div;
    var seg = s.seg;
    if (!const ['all', 'week', 'age', 'guess'].contains(seg)) seg = 'all';

    List<APlayer> list;
    if (seg == 'week') {
      list = mine ? c.weekGroup() : _rankBy(c.divPlayers(d), (x) => x.wp);
    } else if (seg == 'age') {
      final ag = c.store.acc?.age ?? 'a';
      list = _rankBy(c.divPlayers(d).where((x) => x.age == ag).toList(), (x) => x.p);
    } else if (seg == 'guess') {
      list = _rankBy(c.divPlayers(d), (x) => x.gp);
    } else {
      list = c.divPlayers(d);
    }
    int val(APlayer x) => seg == 'guess' ? x.gp : x.p;
    final unit = seg == 'guess' ? tr('u_right') : tr('pts');
    final me = list.where((x) => x.me).toList();

    return ListView(
      key: const PageStorageKey('arena_rank'),
      padding: EdgeInsets.fromLTRB(16, 4, 16, 28 + pad),
      children: [
        s.sponsorSlot(),
        // دوو لیگ
        Container(
          height: 46,
          padding: const EdgeInsets.all(4),
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(color: AC.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: AC.line)),
          child: Row(children: [
            for (final x in Div.values)
              Expanded(
                child: _Tap(
                  radius: 12,
                  onTap: () => s.upd(() => s.rankDiv = x),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    decoration: BoxDecoration(
                      color: x == d ? (x == Div.band ? _a(AC.mint, .16) : _a(AC.cyan, .16)) : null,
                      borderRadius: BorderRadius.circular(12),
                      border: x == d ? Border.all(color: x == Div.band ? _a(AC.mint, .5) : _a(AC.cyan, .5)) : null,
                    ),
                    child: Center(
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(x == Div.band ? Icons.watch_rounded : Icons.smartphone_rounded,
                            size: 16, color: x == d ? (x == Div.band ? AC.mint : AC.cyan) : AC.mu),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(tr(x == Div.band ? 'dv_band' : 'dv_phone'),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: ats(13.5, w: FontWeight.w800, c: x == d ? AC.tx : AC.mu)),
                        ),
                        if (x == c.div) ...[const SizedBox(width: 6), _Pill(tr('you'), color: AC.gold)],
                      ]),
                    ),
                  ),
                ),
              ),
          ]),
        ),
        if (!c.live)
          _Box(
            child: Column(children: [
              Icon(Icons.lock_clock_rounded, size: 40, color: AC.gold),
              const SizedBox(height: 8),
              Text(tr('rk_pre_t'), textAlign: TextAlign.center, style: ats(16, w: FontWeight.w800)),
              const SizedBox(height: 4),
              Text(tr('rk_pre_s'), textAlign: TextAlign.center, style: ats(12.5, c: AC.mu, h: 1.6)),
            ]),
          )
        else ...[
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: [
              for (final k in const ['all', 'week', 'age', 'guess'])
                Padding(
                  padding: const EdgeInsetsDirectional.only(end: 6, bottom: 12),
                  child: _Tap(
                    radius: 99,
                    onTap: () => s.upd(() => s.seg = k),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: k == seg ? AC.goldG : null,
                        color: k == seg ? null : AC.card,
                        borderRadius: BorderRadius.circular(99),
                        border: Border.all(color: k == seg ? Colors.transparent : AC.line2),
                      ),
                      child: Text(tr('sg_$k'), style: ats(12.5, w: FontWeight.w800, c: k == seg ? AC.onGold : AC.mu)),
                    ),
                  ),
                ),
            ]),
          ),
          if (!mine)
            _InfoBox(
              icon: Icons.info_outline_rounded,
              color: AC.cyan,
              title: tr('rk_other_t', [tr(d == Div.band ? 'dv_band' : 'dv_phone')]),
              text: tr(d == Div.band ? 'rk_other_band' : 'rk_other_phone'),
            ),
          if (seg == 'week')
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(tr('rk_week_s', [weekInfo(c.now).left + 1]), style: ats(12.5, c: AC.mu, h: 1.6)),
            ),
          if (list.isEmpty)
            _Box(child: Center(child: Text(tr('rk_empty'), style: ats(13, c: AC.mu))))
          else ...[
            if (list.length >= 3) _Podium(c: c, top: list.take(3).toList(), val: val, unit: unit, prizes: seg == 'all' ? kPrizes[d] : null),
            for (final x in list.skip(list.length >= 3 ? 3 : 0)) _RankRow(c: c, x: x, v: val(x), unit: unit),
          ],
          if (me.isNotEmpty && mine && seg == 'all') _MyRankNote(c: c, me: me.first, d: d),
        ],
      ],
    );
  }

  static List<APlayer> _rankBy(List<APlayer> l, int Function(APlayer) f) {
    final o = [...l]..sort((a, b) => f(b) != f(a) ? f(b).compareTo(f(a)) : a.at.compareTo(b.at));
    final out = <APlayer>[];
    for (var i = 0; i < o.length; i++) {
      final x = o[i];
      final y = APlayer(
          id: x.id, n: x.n, city: x.city, age: x.age, ch: x.ch, dv: x.dv, p: x.p, wp: x.wp, st: x.st, gp: x.gp,
          skin: x.skin, title: x.title, stats: x.stats, pre: x.pre, at: x.at, me: x.me);
      y.r = i + 1;
      out.add(y);
    }
    return out;
  }
}

class _Podium extends StatelessWidget {
  const _Podium({required this.c, required this.top, required this.val, required this.unit, this.prizes});
  final ArenaCtl c;
  final List<APlayer> top;
  final int Function(APlayer) val;
  final String unit;
  final List<Prize>? prizes;

  @override
  Widget build(BuildContext context) {
    Widget col(APlayer x, double h, Color c3) => Expanded(
          child: _Tap(
            onTap: () => playerSheet(context, c, x),
            child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
              Stack(clipBehavior: Clip.none, alignment: Alignment.topCenter, children: [
                CharAvatar(ch: x.ch, name: nm(x.n), size: x.r == 1 ? 74 : 60, ring: c3, gold: x.r == 1),
                if (x.r == 1)
                  const Positioned(top: -18, child: Icon(Icons.workspace_premium_rounded, color: AC.goldS, size: 24)),
                if (x.pre)
                  PositionedDirectional(
                    end: -2,
                    bottom: -2,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(gradient: AC.goldG, shape: BoxShape.circle, border: Border.all(color: AC.stage2, width: 2)),
                      child: const Icon(Icons.star_rounded, size: 12, color: AC.onGold),
                    ),
                  ),
              ]),
              const SizedBox(height: 6),
              Text(x.me ? tr('you') : nm(x.n),
                  maxLines: 1, overflow: TextOverflow.ellipsis, style: ats(13, w: FontWeight.w800, c: x.me ? AC.goldS : AC.stageTx)),
              Text('${afmt(val(x))} $unit', style: ats(12, w: FontWeight.w700, c: AC.stageMu)),
              const SizedBox(height: 6),
              Container(
                height: h,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                  gradient: LinearGradient(colors: [_a(c3, .45), _a(c3, .08)], begin: Alignment.topCenter, end: Alignment.bottomCenter),
                  border: Border.all(color: _a(c3, .5)),
                ),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text('${x.r}', style: ats(x.r == 1 ? 30 : 24, w: FontWeight.w900, c: c3)),
                  if (prizes != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(prizes![x.r - 1].icon, size: 16, color: _a(c3, .9)),
                    ),
                ]),
              ),
            ]),
          ),
        );
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.fromLTRB(10, 28, 10, 0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: const LinearGradient(colors: [AC.stage1, AC.stage2], begin: Alignment.topCenter, end: Alignment.bottomCenter),
        border: Border.all(color: _a(AC.goldS, .3)),
      ),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        height: 236,
        child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          col(top[1], 70, const Color(0xFFDFE6FB)),
          const SizedBox(width: 8),
          col(top[0], 98, AC.goldS),
          const SizedBox(width: 8),
          col(top[2], 54, const Color(0xFFFFB27A)),
        ]),
      ),
    );
  }
}

class _RankRow extends StatelessWidget {
  const _RankRow({required this.c, required this.x, required this.v, required this.unit});
  final ArenaCtl c;
  final APlayer x;
  final int v;
  final String unit;
  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: x.me ? null : AC.card,
          gradient: x.me ? LinearGradient(colors: [_a(AC.accent, .2), _a(AC.accent, .05)]) : null,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: x.me ? _a(AC.accent, .6) : AC.line, width: x.me ? 1.5 : 1),
        ),
        child: _Tap(
          radius: 18,
          onTap: () => playerSheet(context, c, x),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(children: [
              SizedBox(width: 28, child: Text('${x.r}', textAlign: TextAlign.center, style: ats(15, w: FontWeight.w900, c: x.me ? AC.gold : AC.mu))),
              const SizedBox(width: 8),
              CharAvatar(ch: x.ch, name: nm(x.n), size: 40, ring: x.me ? AC.cyan : null),
              const SizedBox(width: 10),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Flexible(
                      child: Text(x.me ? '${nm(x.n)} · ${tr('you')}' : nm(x.n),
                          maxLines: 1, overflow: TextOverflow.ellipsis, style: ats(14, w: FontWeight.w800, c: x.me ? AC.gold : AC.tx)),
                    ),
                    if (x.pre) ...[const SizedBox(width: 4), Icon(Icons.star_rounded, size: 14, color: AC.gold)],
                  ]),
                  Text('${leagueOf(x.p, x.dv).name} · ${tr('ti_${x.title}')}', maxLines: 1, overflow: TextOverflow.ellipsis, style: ats(11.5, c: AC.mu)),
                ]),
              ),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text(afmt(v), style: ats(16, w: FontWeight.w900)),
                Text(unit, style: ats(10.5, c: AC.mu)),
              ]),
            ]),
          ),
        ),
      );
}

class _MyRankNote extends StatelessWidget {
  const _MyRankNote({required this.c, required this.me, required this.d});
  final ArenaCtl c;
  final APlayer me;
  final Div d;
  @override
  Widget build(BuildContext context) {
    final gap3 = me.r > 3 ? c.ptsAt(3, d) - me.p + 1 : 0;
    return _Box(
      border: _a(AC.accent, .4),
      child: Row(children: [
        Icon(me.r <= 3 ? Icons.emoji_events_rounded : Icons.trending_up_rounded, color: AC.gold, size: 26),
        const SizedBox(width: 10),
        Expanded(
          child: Text(me.r <= 3 ? tr('rk_me_top', [me.r]) : tr('rk_me_gap', [afmt(gap3)]), style: ats(13, w: FontWeight.w700, h: 1.6)),
        ),
      ]),
    );
  }
}

// =============================================================================
// 14. کارتی یاریزان + تابی «کارتەکەم»
// =============================================================================

class ArenaCardView extends StatelessWidget {
  const ArenaCardView({
    super.key,
    required this.name,
    required this.ch,
    required this.skin,
    required this.pts,
    required this.div,
    required this.title,
    required this.stats,
    this.founder = false,
    this.width = 300,
  });
  final String name, ch, title;
  final CardSkin skin;
  final int pts;
  final Div div;
  final List<int> stats;
  final bool founder;
  final double width;

  @override
  Widget build(BuildContext context) {
    final lg = leagueOf(pts, div);
    final sk = skin.id == 'auto' ? _autoSkin(lg) : skin;
    final k = width / 300;
    const labels = ['WLK', 'RUN', 'SLP', 'FUD', 'HRT', 'CLM'];
    return SizedBox(
      width: width,
      height: width * 1.42,
      child: Stack(children: [
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(26 * k),
              gradient: LinearGradient(colors: [sk.c2, sk.c1], begin: Alignment.topLeft, end: Alignment.bottomRight),
              border: Border.all(color: _a(sk.accent, .8), width: 2.2),
              boxShadow: [BoxShadow(color: _a(sk.accent, .35), blurRadius: 28 * k, offset: Offset(0, 12 * k))],
            ),
          ),
        ),
        if (sk.fx.isNotEmpty)
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(26 * k),
                  gradient: LinearGradient(
                    colors: sk.fx == 'holo'
                        ? const [Color(0x00FFFFFF), Color(0x3384F5FF), Color(0x00FFFFFF), Color(0x33FF9BF0), Color(0x00FFFFFF)]
                        : const [Color(0x00FFFFFF), Color(0x26FFE08A), Color(0x00FFFFFF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
          ),
        // لای سەرەوە: ڕەیتینگ + لیگ
        PositionedDirectional(
          top: 16 * k,
          start: 18 * k,
          child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
            Text('${ratingOf(pts)}', style: ats(40 * k, w: FontWeight.w900, c: Colors.white, h: 1)),
            Text(div == Div.band ? 'BAND' : 'PHONE', style: ats(10 * k, w: FontWeight.w900, c: sk.accent, ls: 1.5)),
            SizedBox(height: 6 * k),
            Icon(Icons.shield_rounded, color: lg.color, size: 26 * k),
          ]),
        ),
        PositionedDirectional(
          top: 16 * k,
          end: 16 * k,
          child: founder
              ? Container(
                  padding: EdgeInsets.symmetric(horizontal: 8 * k, vertical: 4 * k),
                  decoration: BoxDecoration(gradient: AC.goldG, borderRadius: BorderRadius.circular(99)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.star_rounded, size: 13 * k, color: AC.onGold),
                    SizedBox(width: 3 * k),
                    Text(tr('founder'), style: ats(10.5 * k, w: FontWeight.w900, c: AC.onGold)),
                  ]),
                )
              : Text('S${seasonNow().n}', style: ats(13 * k, w: FontWeight.w900, c: _a(Colors.white, .7))),
        ),
        // کارەکتەر
        Positioned(
          top: 40 * k,
          left: 0,
          right: 0,
          child: Center(
            child: SizedBox(
              width: 190 * k,
              height: 190 * k,
              child: ch.isEmpty
                  ? Icon(Icons.person_rounded, size: 150 * k, color: _a(Colors.white, .5))
                  : Image.asset(charAsset(ch),
                      fit: BoxFit.contain,
                      gaplessPlayback: true,
                      errorBuilder: (_, __, ___) => Icon(Icons.person_rounded, size: 150 * k, color: _a(Colors.white, .5))),
            ),
          ),
        ),
        // ناو + نازناو + ئامار
        Positioned(
          left: 14 * k,
          right: 14 * k,
          bottom: 14 * k,
          child: Column(children: [
            Text(nm(name).toUpperCase(),
                maxLines: 1, overflow: TextOverflow.ellipsis, style: ats(20 * k, w: FontWeight.w900, c: Colors.white, h: 1.2)),
            Text(tr('ti_$title'), maxLines: 1, overflow: TextOverflow.ellipsis, style: ats(12 * k, w: FontWeight.w700, c: sk.accent)),
            SizedBox(height: 8 * k),
            Container(height: 1, color: _a(sk.accent, .5)),
            SizedBox(height: 8 * k),
            Directionality(
              textDirection: TextDirection.ltr,
              child: Row(children: [
                for (var i = 0; i < 6; i++)
                  Expanded(
                    child: Column(children: [
                      Text('${i < stats.length ? stats[i] : 50}', style: ats(17 * k, w: FontWeight.w900, c: Colors.white, h: 1.1)),
                      Text(labels[i], style: ats(9.5 * k, w: FontWeight.w800, c: _a(Colors.white, .7))),
                    ]),
                  ),
              ]),
            ),
          ]),
        ),
      ]),
    );
  }

  static CardSkin _autoSkin(League lg) {
    switch (lg.key) {
      case 'lg_silver':
        return const CardSkin('auto', 0, 'f', Color(0xFF3A4452), Color(0xFF8A99AA), Color(0xFFD9E6EE));
      case 'lg_gold':
        return const CardSkin('auto', 0, 'f', Color(0xFF6B4A0A), Color(0xFFD9A21F), Color(0xFFFFE08A));
      case 'lg_plat':
        return const CardSkin('auto', 0, 'f', Color(0xFF0B3A4A), Color(0xFF2A9AB0), Color(0xFF7FE7FF));
      case 'lg_dia':
        return const CardSkin('auto', 0, 'f', Color(0xFF2A1A6E), Color(0xFF7B5CFF), Color(0xFFD9CCFF));
      case 'lg_legend':
        return const CardSkin('auto', 0, 'f', Color(0xFF5A0F22), Color(0xFFD62F55), Color(0xFFFFB3C2), fx: 'royal');
      default:
        return kSkins.first;
    }
  }
}

class _CardTab extends StatelessWidget {
  const _CardTab({required this.s});
  final _VexArenaPageState s;

  @override
  Widget build(BuildContext context) {
    final c = s.c;
    final st = c.store;
    final a = st.acc!;
    final pad = MediaQuery.of(context).padding.bottom;
    final cs = c.charState();
    final w = math.min(MediaQuery.of(context).size.width - 64, 320.0);
    final lgI = leagueIndex(leagueOf(c.myTotal, c.div));
    return ListView(
      key: const PageStorageKey('arena_card'),
      padding: EdgeInsets.fromLTRB(16, 4, 16, 28 + pad),
      children: [
        s.sponsorSlot(),
        Center(
          child: ArenaCardView(
            name: a.name,
            ch: st.ch,
            skin: skinById(st.skin),
            pts: c.myTotal,
            div: c.div,
            title: st.title,
            stats: c.myStats(),
            founder: a.pre,
            width: w,
          ),
        ),
        const SizedBox(height: 10),
        if (st.bio.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text('“${st.bio}”', textAlign: TextAlign.center, style: ats(13, c: AC.mu)),
          ),
        Row(children: [
          Expanded(child: _Btn(tr('edit'), icon: Icons.edit_rounded, primary: false, small: true, onTap: () => editSheet(context, c))),
          const SizedBox(width: 8),
          Expanded(child: _Btn(tr('coins_t'), icon: Icons.toll_rounded, primary: false, small: true, onTap: () => coinSheet(context, c))),
        ]),
        const SizedBox(height: 14),

        // کارەکتەر
        _Box(
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _Head(tr('ch_t'), small: tr('ch_rule')),
            _InfoBox(
              icon: cs == 'ok' || cs == 'first' ? Icons.lock_open_rounded : Icons.lock_rounded,
              color: cs == 'ok' || cs == 'first' ? AC.mint : AC.orange,
              title: tr('ch_st_$cs', [c.charDaysLeft]),
              text: tr(cs == 'live' ? 'ch_live_s' : 'ch_any_s'),
            ),
            GridView.count(
              crossAxisCount: 4,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: .78,
              children: [for (final x in kChars) _CharCell(c: c, id: x[0] as String)],
            ),
          ]),
        ),

        // دیزاینی کارت
        _Box(
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _Head(tr('sk_t'), small: tr('sk_s')),
            SizedBox(
              height: 128,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: kSkins.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (ctx, i) {
                  final k = kSkins[i];
                  final own = c.skinOwned(k), on = st.skin == k.id;
                  return _Tap(
                    onTap: () {
                      if (own) {
                        c.useSkin(k);
                      } else if (k.lg > 0) {
                        arenaToast(context, tr('sk_need_lg', [kLeagues[k.lg].name]), Icons.lock_rounded);
                      } else {
                        buySheet(context, c, k.name, k.cost, () => c.buySkin(k));
                      }
                    },
                    child: SizedBox(
                      width: 84,
                      child: Column(children: [
                        Container(
                          width: 84,
                          height: 84,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: LinearGradient(colors: [k.c2, k.c1], begin: Alignment.topLeft, end: Alignment.bottomRight),
                            border: Border.all(color: on ? AC.accent : _a(k.accent, .6), width: on ? 3 : 1.5),
                          ),
                          child: Center(
                            child: on
                                ? const Icon(Icons.check_circle_rounded, color: Colors.white, size: 26)
                                : !own
                                    ? Icon(Icons.lock_rounded, color: _a(Colors.white, .85), size: 22)
                                    : Icon(Icons.style_rounded, color: _a(Colors.white, .7), size: 22),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(k.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: ats(11.5, w: FontWeight.w800)),
                        Text(
                          own ? (on ? tr('in_use') : tr('owned')) : (k.lg > 0 ? kLeagues[k.lg].name : '${k.cost}'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: ats(10.5, w: FontWeight.w700, c: own ? AC.mint : AC.gold),
                        ),
                      ]),
                    ),
                  );
                },
              ),
            ),
          ]),
        ),

        // نازناو
        _Box(
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _Head(tr('ti_head')),
            Wrap(spacing: 6, runSpacing: 6, children: [
              for (final t in kTitles)
                () {
                  final id = t[0] as String;
                  final ok = c.titleOk(id), on = st.title == id;
                  return _Tap(
                    radius: 99,
                    onTap: () => ok ? c.setTitle(id) : arenaToast(context, tr('ti_need_$id'), Icons.lock_rounded),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        gradient: on ? AC.goldG : null,
                        color: on ? null : AC.surf,
                        borderRadius: BorderRadius.circular(99),
                        border: Border.all(color: on ? Colors.transparent : AC.line2),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        if (!ok) ...[Icon(Icons.lock_rounded, size: 12, color: AC.mu), const SizedBox(width: 4)],
                        Text(tr('ti_$id'), style: ats(12.5, w: FontWeight.w800, c: on ? AC.onGold : (ok ? AC.tx : AC.mu))),
                      ]),
                    ),
                  );
                }(),
            ]),
          ]),
        ),

        // هەژمار
        _Box(
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _Head(tr('acc_t')),
            _kv(Icons.person_rounded, tr('f_name'), a.name),
            _kv(Icons.phone_rounded, tr('f_phone'), maskPhone(a.phone)),
            _kv(Icons.location_on_rounded, tr('f_city'), nm(a.city)),
            _kv(Icons.cake_rounded, tr('f_age'), kAges.firstWhere((x) => x[0] == a.age, orElse: () => kAges[1])[1]),
            _kv(c.div == Div.band ? Icons.watch_rounded : Icons.smartphone_rounded, tr('league_div'), tr(c.div == Div.band ? 'dv_band' : 'dv_phone')),
            _kv(Icons.flag_rounded, tr('joined'), a.pre ? tr('founder') : tr('joined_day', [math.max(1, a.day)])),
            _kv(Icons.shield_rounded, tr('league'), kLeagues[lgI].name),
            const SizedBox(height: 10),
            _InfoBox(icon: Icons.phone_in_talk_rounded, color: AC.gold, title: tr('win_t'), text: tr('win_s')),
            _Btn(tr('logout'), icon: Icons.logout_rounded, primary: false, danger: true, small: true, onTap: () => logoutSheet(context, c)),
          ]),
        ),
      ],
    );
  }

  Widget _kv(IconData i, String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(children: [
          Icon(i, size: 18, color: AC.mu),
          const SizedBox(width: 10),
          Expanded(child: Text(k, style: ats(13, c: AC.mu))),
          Flexible(child: Text(v, textAlign: TextAlign.end, maxLines: 1, overflow: TextOverflow.ellipsis, style: ats(13.5, w: FontWeight.w800))),
        ]),
      );
}

class _CharCell extends StatelessWidget {
  const _CharCell({required this.c, required this.id});
  final ArenaCtl c;
  final String id;
  @override
  Widget build(BuildContext context) {
    final on = c.store.ch == id, own = c.charOwned(id), cost = charCost(id);
    final rar = charRarity(id);
    final rc = rar == 'r_legend' ? AC.coral : rar == 'r_epic' ? AC.violet : rar == 'r_rare' ? AC.cyan : AC.mu;
    return _Tap(
      onTap: () => charSheet(context, c, id),
      child: Container(
        decoration: BoxDecoration(
          color: AC.surf,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: on ? AC.accent : _a(rc, .35), width: on ? 2.5 : 1),
        ),
        child: Column(children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Opacity(
                opacity: own ? 1 : .55,
                child: Image.asset(charAsset(id),
                    fit: BoxFit.contain,
                    gaplessPlayback: true,
                    errorBuilder: (_, __, ___) => Icon(Icons.person_rounded, color: AC.mu, size: 36)),
              ),
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 3),
            decoration: BoxDecoration(
              color: on ? AC.accent : _a(rc, .14),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(15)),
            ),
            child: on
                ? const Icon(Icons.check_rounded, size: 14, color: AC.onGold)
                : own
                    ? Text(cost == 0 ? tr('free') : tr('owned'), textAlign: TextAlign.center, style: ats(10, w: FontWeight.w800, c: rc))
                    : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        const _Coin(11),
                        const SizedBox(width: 3),
                        Text('$cost', style: ats(10.5, w: FontWeight.w900, c: AC.gold)),
                      ]),
          ),
        ]),
      ),
    );
  }
}

// =============================================================================
// 15. شیتەکان
// =============================================================================

class _SheetHead extends StatelessWidget {
  const _SheetHead({required this.icon, required this.color, required this.title, this.sub});
  final IconData icon;
  final Color color;
  final String title;
  final String? sub;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Row(children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(color: _a(color, .16), borderRadius: BorderRadius.circular(16)),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: ats(18, w: FontWeight.w900)),
              if (sub != null) Text(sub!, style: ats(12.5, c: AC.mu, h: 1.5)),
            ]),
          ),
        ]),
      );
}

Widget _line(IconData i, Color col, String t, [String? s]) => Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(color: _a(col, .14), borderRadius: BorderRadius.circular(10)),
          child: Icon(i, size: 16, color: col),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(t, style: ats(13.5, w: FontWeight.w800, h: 1.5)),
            if (s != null && s.isNotEmpty) Text(s, style: ats(12.5, c: AC.mu, h: 1.6)),
          ]),
        ),
      ]),
    );

// ---- سکە ----
void coinSheet(BuildContext context, ArenaCtl c) {
  arenaSheet(
    context,
    (ctx) => AnimatedBuilder(
      animation: c,
      builder: (_, __) {
        final st = c.store;
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          _SheetHead(icon: Icons.toll_rounded, color: AC.gold, title: tr('coins_t'), sub: tr('coins_s')),
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(gradient: AC.goldG, borderRadius: BorderRadius.circular(20)),
            child: Row(children: [
              const _Coin(40),
              const SizedBox(width: 12),
              Expanded(child: Text(tr('balance'), style: ats(15, w: FontWeight.w800, c: AC.onGold))),
              Text(afmt(st.coins), style: ats(30, w: FontWeight.w900, c: AC.onGold)),
            ]),
          ),
          if (st.tamper) _InfoBox(icon: Icons.gpp_bad_rounded, color: AC.coral, title: tr('tamper_t'), text: tr('tamper_s')),
          if (!st.clockOk) _InfoBox(icon: Icons.schedule_rounded, color: AC.coral, title: tr('clock_t'), text: tr('clock_s')),
          Text(tr('earn_t'), style: ats(15, w: FontWeight.w800)),
          const SizedBox(height: 8),
          _line(Icons.directions_walk_rounded, AC.mint, tr('earn_day', [coinMax(c.div)]), tr('earn_day_s', [c.coinsToday, coinMax(c.div)])),
          _line(Icons.emoji_events_rounded, AC.gold, tr('earn_week')),
          _line(Icons.local_fire_department_rounded, AC.orange, tr('earn_streak')),
          _line(Icons.auto_awesome_rounded, AC.violet, tr('earn_guess')),
          _line(Icons.card_giftcard_rounded, AC.cyan, tr('earn_chest')),
          const SizedBox(height: 6),
          Text(tr('spend_t'), style: ats(15, w: FontWeight.w800)),
          const SizedBox(height: 8),
          _line(Icons.face_rounded, AC.violet, tr('spend_char')),
          _line(Icons.style_rounded, AC.cyan, tr('spend_skin')),
          _line(Icons.shield_rounded, AC.mint, tr('spend_frz')),
          _InfoBox(icon: Icons.info_outline_rounded, color: AC.mu, title: tr('coin_note_t'), text: tr('coin_note_s')),
          Text(tr('hist_t'), style: ats(15, w: FontWeight.w800)),
          const SizedBox(height: 8),
          if (st.clog.isEmpty)
            Padding(padding: const EdgeInsets.symmetric(vertical: 10), child: Text(tr('hist_empty'), style: ats(12.5, c: AC.mu)))
          else
            for (final e in st.clog.take(20))
              Container(
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(border: Border(bottom: BorderSide(color: AC.line))),
                child: Row(children: [
                  Expanded(child: Text(tr('co_${e.t}'), style: ats(13, w: FontWeight.w700))),
                  Text(_ago(e.at), style: ats(11.5, c: AC.mu)),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 52,
                    child: Text(e.c > 0 ? '+${e.c}' : '${e.c}',
                        textAlign: TextAlign.end,
                        textDirection: TextDirection.ltr,
                        style: ats(14, w: FontWeight.w900, c: e.c > 0 ? AC.mint : (e.c < 0 ? AC.coral : AC.mu))),
                  ),
                ]),
              ),
        ]);
      },
    ),
  );
}

String _ago(int ms) {
  final d = DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(ms));
  if (d.inMinutes < 1) return tr('ago_now');
  if (d.inHours < 1) return tr('ago_m', [d.inMinutes]);
  if (d.inDays < 1) return tr('ago_h', [d.inHours]);
  return tr('ago_d', [d.inDays]);
}

// ---- یاساکان ----
void rulesSheet(BuildContext context, ArenaCtl c) {
  const sec = [
    [Icons.sports_score_rounded, 'ru1'],
    [Icons.calendar_month_rounded, 'ru2'],
    [Icons.watch_rounded, 'ru3'],
    [Icons.bar_chart_rounded, 'ru4'],
    [Icons.check_circle_rounded, 'ru5'],
    [Icons.verified_rounded, 'ru6'],
    [Icons.emoji_events_rounded, 'ru7'],
    [Icons.groups_rounded, 'ru8'],
    [Icons.toll_rounded, 'ru9'],
    [Icons.local_fire_department_rounded, 'ru10'],
    [Icons.auto_awesome_rounded, 'ru11'],
    [Icons.gpp_good_rounded, 'ru12'],
    [Icons.phone_in_talk_rounded, 'ru13'],
  ];
  arenaSheet(
    context,
    (ctx) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _SheetHead(icon: Icons.menu_book_rounded, color: AC.gold, title: tr('rules'), sub: tr('rules_s', [c.S.n])),
      for (var i = 0; i < sec.length; i++) ...[
        Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: AC.surf, borderRadius: BorderRadius.circular(18), border: Border.all(color: AC.line)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [
              Container(
                width: 26,
                height: 26,
                alignment: Alignment.center,
                decoration: BoxDecoration(gradient: AC.goldG, borderRadius: BorderRadius.circular(8)),
                child: Text('${i + 1}', style: ats(12, w: FontWeight.w900, c: AC.onGold)),
              ),
              const SizedBox(width: 8),
              Icon(sec[i][0] as IconData, size: 18, color: AC.gold),
              const SizedBox(width: 6),
              Expanded(child: Text(tr('${sec[i][1]}_t'), style: ats(14.5, w: FontWeight.w800))),
            ]),
            const SizedBox(height: 8),
            Text(tr('${sec[i][1]}_s'), style: ats(12.8, c: AC.mu, h: 1.75)),
            if (sec[i][1] == 'ru4') ...[const SizedBox(height: 10), _PointsTable(div: c.div)],
          ]),
        ),
      ],
    ]),
  );
}

class _PointsTable extends StatelessWidget {
  const _PointsTable({required this.div});
  final Div div;
  @override
  Widget build(BuildContext context) {
    Widget cell(String t, {bool b = false, Color? col, TextAlign a = TextAlign.center}) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 6),
          child: Text(t, textAlign: a, style: ats(12, w: b ? FontWeight.w800 : FontWeight.w600, c: col)),
        );
    return Container(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), border: Border.all(color: AC.line2)),
      clipBehavior: Clip.antiAlias,
      child: Table(
        columnWidths: const {0: FlexColumnWidth(2.2), 1: FlexColumnWidth(1), 2: FlexColumnWidth(1)},
        border: TableBorder(horizontalInside: BorderSide(color: AC.line)),
        children: [
          TableRow(decoration: BoxDecoration(color: _a(AC.accent, .14)), children: [
            cell(tr('ru_cat'), b: true, a: TextAlign.start),
            cell(tr('dv_band'), b: true, col: div == Div.band ? AC.gold : null),
            cell(tr('dv_phone'), b: true, col: div == Div.phone ? AC.gold : null),
          ]),
          for (final k in kCats)
            TableRow(children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 6),
                child: Row(children: [
                  Icon(k.icon, size: 15, color: k.color),
                  const SizedBox(width: 6),
                  Flexible(child: Text(k.name, style: ats(12, w: FontWeight.w700))),
                ]),
              ),
              cell('${k.max}'),
              k.phone > 0 ? cell('${k.phone}') : Center(child: Icon(Icons.lock_rounded, size: 13, color: AC.mu)),
            ]),
          TableRow(decoration: BoxDecoration(color: AC.surf), children: [
            cell(tr('ru_max'), b: true, a: TextAlign.start),
            cell('600', b: true, col: AC.gold),
            cell('200', b: true, col: AC.gold),
          ]),
          TableRow(children: [
            cell(tr('ru_active'), b: true, a: TextAlign.start),
            cell('100+', b: true, col: AC.mint),
            cell('60+', b: true, col: AC.mint),
          ]),
        ],
      ),
    );
  }
}

// ---- خەڵات ----
void prizeSheet(BuildContext context, ArenaCtl c, Div d) {
  final z = kPrizes[d]!;
  arenaSheet(
    context,
    (ctx) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _SheetHead(
          icon: Icons.emoji_events_rounded, color: AC.gold, title: tr('pz_t', [tr(d == Div.band ? 'dv_band' : 'dv_phone')]), sub: tr('pz_sheet_s', [c.S.n])),
      for (final p in z)
        Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: p.r == 1 ? LinearGradient(colors: [_a(AC.accent, .22), _a(AC.accent, .05)]) : null,
            color: p.r == 1 ? null : AC.surf,
            border: Border.all(color: p.r == 1 ? _a(AC.accent, .6) : AC.line),
          ),
          child: Row(children: [
            Container(
              width: 46,
              height: 46,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: p.r == 1 ? AC.goldG : null,
                color: p.r == 1 ? null : AC.card,
                border: Border.all(color: AC.line2),
              ),
              child: Text('${p.r}', style: ats(20, w: FontWeight.w900, c: p.r == 1 ? AC.onGold : AC.tx)),
            ),
            const SizedBox(width: 12),
            Icon(p.icon, color: AC.gold, size: 26),
            const SizedBox(width: 10),
            Expanded(child: Text(p.name, style: ats(15, w: FontWeight.w800))),
          ]),
        ),
      const SizedBox(height: 4),
      _line(Icons.calendar_month_rounded, AC.mint, tr('pz_c1')),
      _line(Icons.flag_rounded, AC.mint, tr('pz_c2', [activeMin(d)])),
      _line(Icons.verified_user_rounded, AC.mint, tr('pz_c3')),
      _line(Icons.person_rounded, AC.mint, tr('pz_c4')),
      _line(Icons.phone_in_talk_rounded, AC.gold, tr('win_t'), tr('win_s')),
      _line(Icons.workspace_premium_rounded, AC.gold, tr('pz_guar_t'), tr(d == Div.band ? 'pz_guar_b' : 'pz_guar_p')),
    ]),
  );
}

// ---- یاری دادپەروەرانە ----
void fairSheet(BuildContext context, ArenaCtl c) {
  arenaSheet(
    context,
    (ctx) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _SheetHead(icon: Icons.verified_user_rounded, color: AC.mint, title: tr('fair_t'), sub: tr('fair_s')),
      for (var i = 1; i <= 7; i++)
        _line(
          const [
            Icons.watch_rounded,
            Icons.directions_run_rounded,
            Icons.favorite_rounded,
            Icons.water_drop_rounded,
            Icons.restaurant_rounded,
            Icons.lock_clock_rounded,
            Icons.gpp_bad_rounded,
          ][i - 1],
          AC.mint,
          tr('fair_${i}_t'),
          tr('fair_${i}_s'),
        ),
    ]),
  );
}

// ---- پاراستنی زنجیرە ----
void freezeSheet(BuildContext context, ArenaCtl c) {
  arenaSheet(
    context,
    (ctx) => AnimatedBuilder(
      animation: c,
      builder: (_, __) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        _SheetHead(icon: Icons.shield_rounded, color: AC.cyan, title: tr('freeze'), sub: tr('frz_s')),
        Center(child: Text('${c.store.frz} / 2', textDirection: TextDirection.ltr, style: ats(34, w: FontWeight.w900, c: AC.cyan))),
        const SizedBox(height: 10),
        _line(Icons.autorenew_rounded, AC.cyan, tr('frz_1')),
        _line(Icons.local_fire_department_rounded, AC.orange, tr('frz_2')),
        const SizedBox(height: 6),
        _Btn(
          c.store.frz >= 2 ? tr('frz_full') : tr('frz_buy'),
          icon: Icons.toll_rounded,
          onTap: c.store.frz >= 2
              ? null
              : () {
                  if (c.buyFreeze()) {
                    arenaToast(ctx, tr('frz_ok'), Icons.shield_rounded);
                  } else {
                    arenaToast(ctx, tr('no_coins'), Icons.toll_rounded);
                  }
                },
        ),
      ]),
    ),
  );
}

// ---- ڕۆژی بیانوو ----
void excuseSheet(BuildContext context, ArenaCtl c) {
  arenaSheet(
    context,
    (ctx) => AnimatedBuilder(
      animation: c,
      builder: (_, __) {
        final used = c.store.exc.contains(c.tk);
        final done = c.today.tot >= c.active;
        final left = 3 - c.store.exc.length;
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          _SheetHead(icon: Icons.event_busy_rounded, color: AC.violet, title: tr('excuse'), sub: tr('exc_s')),
          Center(child: Text('$left / 3', textDirection: TextDirection.ltr, style: ats(34, w: FontWeight.w900, c: AC.violet))),
          const SizedBox(height: 10),
          _line(Icons.sick_rounded, AC.violet, tr('exc_1')),
          _line(Icons.info_outline_rounded, AC.mu, tr('exc_2')),
          const SizedBox(height: 6),
          _Btn(
            used ? tr('exc_used') : (done ? tr('exc_done') : tr('exc_use')),
            icon: Icons.event_available_rounded,
            onTap: used || done || left <= 0 || !c.live
                ? null
                : () {
                    if (c.useExcuse()) arenaToast(ctx, tr('exc_ok'), Icons.event_available_rounded);
                  },
          ),
        ]);
      },
    ),
  );
}

// ---- سندوق ----
void chestSheet(BuildContext context, ArenaCtl c) {
  arenaSheet(
    context,
    (ctx) => AnimatedBuilder(
      animation: c,
      builder: (_, __) {
        final open = c.chestOpen;
        return Column(children: [
          const SizedBox(height: 6),
          TweenAnimationBuilder<double>(
            key: ValueKey(open),
            tween: Tween(begin: .6, end: 1),
            duration: const Duration(milliseconds: 520),
            curve: Curves.elasticOut,
            builder: (_, v, ch) => Transform.scale(scale: v, child: ch),
            child: Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                gradient: AC.goldG,
                borderRadius: BorderRadius.circular(32),
                boxShadow: const [BoxShadow(color: Color(0x66F2B21C), blurRadius: 30)],
              ),
              child: Icon(open ? Icons.redeem_rounded : Icons.card_giftcard_rounded, size: 60, color: const Color(0xFF5A3A00)),
            ),
          ),
          const SizedBox(height: 14),
          Text(open ? tr('chest_got', [c.store.chest?['c'] ?? 0]) : tr('chest_ready'), textAlign: TextAlign.center, style: ats(20, w: FontWeight.w900)),
          const SizedBox(height: 4),
          Text(open ? tr('chest_tomorrow') : tr('chest_range'), textAlign: TextAlign.center, style: ats(13, c: AC.mu)),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: open
                ? _Btn(tr('close'), primary: false, onTap: () => Navigator.of(ctx).pop())
                : _Btn(tr('chest_open'), icon: Icons.lock_open_rounded, onTap: () {
                    if (c.openChest()) arenaConfetti(ctx);
                  }),
          ),
        ]);
      },
    ),
  );
}

// ---- هێزی نهێنی ----
void guessSheet(BuildContext context, ArenaCtl c) {
  String? pick;
  arenaSheet(
    context,
    (ctx) => StatefulBuilder(
      builder: (ctx, set) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        _SheetHead(icon: Icons.auto_awesome_rounded, color: AC.violet, title: tr('pw_t'), sub: tr('pw_rule')),
        GridView.count(
          crossAxisCount: 5,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: .78,
          children: [
            for (final k in kCats)
              _Tap(
                onTap: () => set(() => pick = k.id),
                child: Container(
                  decoration: BoxDecoration(
                    color: pick == k.id ? _a(k.color, .18) : AC.surf,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: pick == k.id ? k.color : AC.line, width: pick == k.id ? 2 : 1),
                  ),
                  padding: const EdgeInsets.all(4),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    CatTile(k, size: 34),
                    const SizedBox(height: 4),
                    Text(k.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: ats(10.5, w: FontWeight.w800)),
                  ]),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        _line(Icons.lightbulb_outline_rounded, AC.gold, tr('hint_${c.today.power}')),
        _Btn(
          pick == null ? tr('pw_pick') : tr('pw_confirm', [catById(pick!).name]),
          icon: Icons.lock_rounded,
          onTap: pick == null
              ? null
              : () {
                  c.guessPower(pick!);
                  Navigator.of(ctx).pop();
                  arenaToast(context, tr('pw_saved'), Icons.auto_awesome_rounded);
                },
        ),
      ]),
    ),
  );
}

void yesterdaySheet(BuildContext context, ArenaCtl c) {
  final k = c.yk;
  final p = catById(powerOf(k)), s2 = catById(secondOf(k));
  final g = c.store.guess[k];
  final r = c.store.days[k];
  arenaSheet(
    context,
    (ctx) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _SheetHead(icon: Icons.history_rounded, color: AC.violet, title: tr('y_t'), sub: tr('y_s')),
      Row(children: [
        Expanded(child: _revealTile(p, '×3', tr('y_power'))),
        const SizedBox(width: 10),
        Expanded(child: _revealTile(s2, '×1.5', tr('y_second'))),
      ]),
      const SizedBox(height: 12),
      if (g != null)
        _InfoBox(
          icon: g == p.id ? Icons.check_circle_rounded : Icons.cancel_rounded,
          color: g == p.id ? AC.mint : AC.coral,
          title: g == p.id ? tr('y_right') : tr('y_wrong', [catById(g).name]),
          text: g == p.id ? tr('y_right_s') : tr('y_wrong_s'),
        )
      else
        _InfoBox(icon: Icons.help_outline_rounded, color: AC.mu, title: tr('y_none'), text: tr('y_none_s')),
      _line(Icons.bar_chart_rounded, AC.gold, tr('y_pts', [afmt(r?.t ?? 0)]), r == null ? '' : (r.a ? tr('y_active') : tr('y_inactive'))),
    ]),
  );
}

Widget _revealTile(ArenaCat k, String m, String l) => Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: _a(k.color, .12), borderRadius: BorderRadius.circular(18), border: Border.all(color: _a(k.color, .45))),
      child: Column(children: [
        CatTile(k, size: 46),
        const SizedBox(height: 6),
        Text(k.name, style: ats(14, w: FontWeight.w800)),
        Text('$l · $m', textAlign: TextAlign.center, style: ats(12, w: FontWeight.w800, c: k.color)),
      ]),
    );

// ---- وردەکاری بەش ----
void catSheet(BuildContext context, ArenaCtl c, ArenaCat k) {
  arenaSheet(
    context,
    (ctx) => AnimatedBuilder(
      animation: c,
      builder: (_, __) {
        final r = c.today.rows.firstWhere((x) => x.cat.id == k.id);
        final d = c.data[k.id] ?? const CatValue('', 0, 'none');
        final na = r.cap == 0;
        final appealed = c.store.apl.contains('${k.id}${c.tk}');
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            CatTile(k, size: 56, dim: na),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(k.name, style: ats(20, w: FontWeight.w900)),
                Text(d.label.isEmpty ? '—' : d.label, style: ats(13, c: AC.mu)),
              ]),
            ),
            Column(children: [
              Text(na ? '—' : '${r.base}', style: ats(30, w: FontWeight.w900, c: AC.gold, h: 1.1)),
              Text(na ? tr('dv_band') : tr('of_n', [r.cap]), style: ats(11.5, c: AC.mu)),
            ]),
          ]),
          const SizedBox(height: 12),
          if (!na) ...[_Bar(r.cap == 0 ? 0 : r.base / r.cap, color: k.color, h: 8), const SizedBox(height: 14)],
          if (d.st == 'na')
            _InfoBox(icon: Icons.lock_rounded, color: AC.mu, title: tr('band_only'), text: tr('why_na'))
          else if (d.st == 'wait')
            _InfoBox(icon: Icons.watch_off_rounded, color: AC.orange, title: tr('band_off'), text: tr('why_band'))
          else if (d.st == 'rej')
            _InfoBox(icon: Icons.gpp_bad_rounded, color: AC.coral, title: tr('rejected'), text: tr(d.why))
          else if (d.st == 'ok')
            _InfoBox(icon: Icons.verified_rounded, color: AC.mint, title: tr('verified'), text: d.chk.isEmpty ? tr('chk_gen') : tr(d.chk))
          else
            _InfoBox(icon: Icons.hourglass_empty_rounded, color: AC.mu, title: tr('not_yet'), text: tr('ny_s')),
          if (d.note.isNotEmpty) _InfoBox(icon: Icons.info_outline_rounded, color: AC.orange, title: tr('partial'), text: d.note),
          _line(Icons.tips_and_updates_rounded, AC.gold, tr('how_t'), tr('how_${k.id}')),
          if (d.st == 'rej')
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _Btn(
                appealed ? tr('apl_sent') : tr('apl'),
                icon: Icons.support_agent_rounded,
                primary: false,
                small: true,
                onTap: appealed
                    ? null
                    : () {
                        c.appeal(k.id);
                        arenaToast(ctx, tr('apl_ok'), Icons.support_agent_rounded);
                      },
              ),
            ),
          if (!na)
            _Btn(tr('go_sec', [k.name]), icon: k.icon, onTap: () {
              Navigator.of(ctx).pop();
              c.host.openSection(context, k.id);
            }),
        ]);
      },
    ),
  );
}

// ---- یاریزان ----
void playerSheet(BuildContext context, ArenaCtl c, APlayer x) {
  final w = math.min(MediaQuery.of(context).size.width - 90, 280.0);
  arenaSheet(
    context,
    (ctx) => Column(children: [
      ArenaCardView(name: x.n, ch: x.ch, skin: skinById(x.skin), pts: x.p, div: x.dv, title: x.title, stats: x.stats, founder: x.pre, width: w),
      const SizedBox(height: 14),
      Row(children: [
        _Stat(Icon(Icons.leaderboard_rounded, color: AC.gold, size: 22), '#${x.r}', tr('rank')),
        _Stat(Icon(Icons.bar_chart_rounded, color: AC.cyan, size: 22), afmt(x.p), tr('season_tot')),
        _Stat(Icon(Icons.local_fire_department_rounded, color: AC.orange, size: 22), '${x.st}', tr('streak')),
        _Stat(Icon(Icons.auto_awesome_rounded, color: AC.violet, size: 22), '${x.gp}', tr('u_right')),
      ]),
      const SizedBox(height: 12),
      _line(x.dv == Div.band ? Icons.watch_rounded : Icons.smartphone_rounded, x.dv == Div.band ? AC.mint : AC.cyan,
          tr(x.dv == Div.band ? 'dv_band' : 'dv_phone'), x.pre ? tr('founder') : null),
    ]),
  );
}

// ---- دەستکاری ----
void editSheet(BuildContext context, ArenaCtl c) {
  final n = TextEditingController(text: c.store.acc?.name ?? '');
  final b = TextEditingController(text: c.store.bio);
  InputDecoration dec(String l) => InputDecoration(
        labelText: l,
        labelStyle: ats(13, c: AC.mu),
        filled: true,
        fillColor: AC.surf,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: AC.line2)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: AC.line2)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AC.accent, width: 1.5)),
      );
  arenaSheet(
    context,
    (ctx) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _SheetHead(icon: Icons.edit_rounded, color: AC.gold, title: tr('edit'), sub: tr('edit_s')),
      TextField(controller: n, maxLength: 24, style: ats(15, w: FontWeight.w700), decoration: dec(tr('f_name'))),
      const SizedBox(height: 8),
      TextField(controller: b, maxLength: 60, style: ats(14), decoration: dec(tr('bio'))),
      const SizedBox(height: 8),
      _line(Icons.lock_rounded, AC.mu, tr('edit_lock')),
      _Btn(tr('save'), icon: Icons.check_rounded, onTap: () {
        c.editProfile(n.text, b.text);
        Navigator.of(ctx).pop();
        arenaToast(context, tr('saved'));
      }),
    ]),
  );
}

void logoutSheet(BuildContext context, ArenaCtl c) {
  arenaSheet(
    context,
    (ctx) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _SheetHead(icon: Icons.logout_rounded, color: AC.coral, title: tr('logout'), sub: tr('logout_s')),
      _Btn(tr('logout_yes'), icon: Icons.logout_rounded, primary: false, danger: true, onTap: () {
        Navigator.of(ctx).pop();
        c.logout();
      }),
      const SizedBox(height: 8),
      _Btn(tr('cancel'), primary: false, onTap: () => Navigator.of(ctx).pop()),
    ]),
  );
}

void buySheet(BuildContext context, ArenaCtl c, String name, int cost, bool Function() buy) {
  arenaSheet(
    context,
    (ctx) => AnimatedBuilder(
      animation: c,
      builder: (_, __) {
        final can = c.store.coins >= cost;
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          _SheetHead(icon: Icons.shopping_bag_rounded, color: AC.gold, title: tr('buy_t', [name]), sub: tr('buy_s', [cost, afmt(c.store.coins)])),
          if (!can) _InfoBox(icon: Icons.toll_rounded, color: AC.coral, title: tr('no_coins'), text: tr('no_coins_s', [cost - c.store.coins])),
          _Btn(tr('buy_go', [cost]), icon: Icons.toll_rounded, onTap: !can
              ? null
              : () {
                  if (buy()) {
                    Navigator.of(ctx).pop();
                    arenaToast(context, tr('bought'), Icons.check_circle_rounded);
                  }
                }),
        ]);
      },
    ),
  );
}

void charSheet(BuildContext context, ArenaCtl c, String id) {
  arenaSheet(
    context,
    (ctx) => AnimatedBuilder(
      animation: c,
      builder: (_, __) {
        final own = c.charOwned(id), on = c.store.ch == id, cost = charCost(id);
        final cs = c.charState();
        final canSet = cs == 'first' || cs == 'ok';
        final rar = charRarity(id);
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Center(
            child: Container(
              width: 170,
              height: 170,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [_a(AC.accent, .3), _a(AC.accent, 0)]),
              ),
              child: Image.asset(charAsset(id),
                  fit: BoxFit.contain, errorBuilder: (_, __, ___) => Icon(Icons.person_rounded, size: 100, color: AC.mu)),
            ),
          ),
          const SizedBox(height: 8),
          Center(child: _Pill(tr(rar), color: rar == 'r_legend' ? AC.coral : rar == 'r_epic' ? AC.violet : rar == 'r_rare' ? AC.cyan : AC.mu)),
          const SizedBox(height: 12),
          if (!canSet && !on) _InfoBox(icon: Icons.lock_rounded, color: AC.orange, title: tr('ch_st_$cs', [c.charDaysLeft]), text: tr(cs == 'live' ? 'ch_live_s' : 'ch_any_s')),
          if (on)
            _Btn(tr('in_use'), icon: Icons.check_rounded, primary: false, onTap: null)
          else if (!own)
            _Btn(tr('buy_go', [cost]), icon: Icons.toll_rounded, onTap: c.store.coins < cost
                ? null
                : () {
                    if (c.buyChar(id)) {
                      arenaToast(ctx, tr('bought'), Icons.check_circle_rounded);
                    }
                  })
          else
            _Btn(tr('ch_use'), icon: Icons.face_rounded, onTap: !canSet
                ? null
                : () {
                    if (c.setChar(id)) {
                      Navigator.of(ctx).pop();
                      arenaToast(context, tr('ch_done'), Icons.face_rounded);
                    }
                  }),
          if (!own && c.store.coins < cost)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(tr('no_coins_s', [cost - c.store.coins]), textAlign: TextAlign.center, style: ats(12, c: AC.coral)),
            ),
        ]);
      },
    ),
  );
}

// ---- پیشاندانی کارت دوای تۆمارکردن ----
void showArenaReveal(BuildContext context, ArenaCtl c) {
  final a = c.store.acc;
  if (a == null) return;
  final w = math.min(MediaQuery.of(context).size.width - 80, 290.0);
  showGeneralDialog(
    context: context,
    barrierDismissible: false,
    barrierLabel: 'reveal',
    barrierColor: const Color(0xE6010616),
    transitionDuration: const Duration(milliseconds: 380),
    pageBuilder: (ctx, _, __) => Directionality(
      textDirection: arenaDir,
      child: Center(
        child: Material(
          color: Colors.transparent,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text(tr('rv_t'), textAlign: TextAlign.center, style: ats(22, w: FontWeight.w900, c: AC.goldS)),
              const SizedBox(height: 4),
              Text(a.pre ? tr('rv_pre') : tr('rv_live'), textAlign: TextAlign.center, style: ats(13, c: AC.stageMu, h: 1.6)),
              const SizedBox(height: 16),
              ArenaCardView(name: a.name, ch: c.store.ch, skin: skinById(c.store.skin), pts: c.myTotal, div: c.div, title: c.store.title, stats: c.myStats(), founder: a.pre, width: w),
              const SizedBox(height: 16),
              Row(mainAxisSize: MainAxisSize.min, children: [
                const _Coin(22),
                const SizedBox(width: 6),
                Text('+${a.pre ? 50 : 20}', style: ats(20, w: FontWeight.w900, c: AC.goldS)),
              ]),
              const SizedBox(height: 16),
              SizedBox(width: w, child: _Btn(tr('rv_go'), icon: Icons.arrow_forward_rounded, onTap: () => Navigator.of(ctx).pop())),
            ]),
          ),
        ),
      ),
    ),
    transitionBuilder: (ctx, an, _, child) {
      final v = CurvedAnimation(parent: an, curve: Curves.easeOutBack);
      return FadeTransition(opacity: an, child: ScaleTransition(scale: Tween(begin: .85, end: 1.0).animate(v), child: child));
    },
  ).then((_) {
    if (context.mounted) arenaConfetti(context);
  });
}

// =============================================================================
// 99. وەرگێڕانەکان — [ckb, kmr, en, ar, fa, tr]
// =============================================================================

const Map<String, List<String>> kArenaT = {
  'acc_t': ['هەژمارەکەم', 'هەژمارا من', 'My account', 'حسابي', 'حساب من', 'Hesabım'],
  'act_days': ['ڕۆژە چالاکەکان', 'ڕۆژێن چالاک', 'Active days', 'الأيام النشطة', 'روزهای فعال', 'Aktif günler'],
  'act_t': ['چالاکییەکانی ئەمڕۆ', 'چالاکیێن ئەڤرۆ', 'Today\'s activities', 'أنشطة اليوم', 'فعالیت‌های امروز', 'Bugünün aktiviteleri'],
  'act_t_pre': ['ڕاهێنان (خاڵ حیساب ناکرێت)', 'ڕاهێنان (خال ناهێنە حیسابکرن)', 'Practice (points don\'t count yet)', 'تدريب (لا تُحتسب النقاط بعد)', 'تمرین (امتیاز هنوز حساب نمی‌شود)', 'Antrenman (puanlar henüz sayılmaz)'],
  'ago_d': ['{0} ڕۆژ', '{0} ڕۆژ', '{0}d', '{0} ي', '{0} روز', '{0} g'],
  'ago_h': ['{0} کاتژمێر', '{0} دەمژمێر', '{0}h', '{0} س', '{0} ساعت', '{0} sa'],
  'ago_m': ['{0} خولەک', '{0} خولەک', '{0}m', '{0} د', '{0} دقیقه', '{0} dk'],
  'ago_now': ['ئێستا', 'نوکە', 'now', 'الآن', 'الان', 'şimdi'],
  'agree': ['یاساکانم خوێندەوە و ڕازیم', 'من یاسا خواندن و ڕازیمە', 'I have read and agree to the rules', 'قرأت القوانين وأوافق عليها', 'قوانین را خواندم و موافقم', 'Kuralları okudum ve kabul ediyorum'],
  'apl': ['داوای پێداچوونەوە', 'داخوازا پێداچوونێ', 'Request review', 'طلب مراجعة', 'درخواست بازبینی', 'İnceleme iste'],
  'apl_ok': ['تیمی VEX پێیدا دەچێتەوە', 'تیما VEX دێ پێدا چیت', 'The VEX team will review it', 'سيراجعه فريق VEX', 'تیم VEX بررسی می‌کند', 'VEX ekibi inceleyecek'],
  'apl_sent': ['داواکاری نێردرا', 'داخواز هاتە هنارتن', 'Request sent', 'تم إرسال الطلب', 'درخواست ارسال شد', 'İstek gönderildi'],
  'avg': ['تێکڕای ڕۆژانە', 'تێکڕایا ڕۆژانە', 'Daily avg', 'معدل يومي', 'میانگین روزانه', 'Günlük ort.'],
  'back': ['گەڕانەوە', 'زڤڕین', 'Back', 'رجوع', 'بازگشت', 'Geri'],
  'balance': ['باڵانس', 'باڵانس', 'Balance', 'الرصيد', 'موجودی', 'Bakiye'],
  'band_off': ['Band پەیوەست نییە', 'Band نە گرێدایە', 'Band not connected', 'Band غير متصل', 'Band وصل نیست', 'Band bağlı değil'],
  'band_only': ['تەنها لیگی Band', 'بتنێ لیگا Band', 'Band league only', 'دوري Band فقط', 'فقط لیگ Band', 'Sadece Band ligi'],
  'bio': ['دەربارەی من (ئارەزوومەندانە)', 'دەربارێ من (ب دلێ خۆ)', 'About me (optional)', 'نبذة عني (اختياري)', 'درباره من (اختیاری)', 'Hakkımda (isteğe bağlı)'],
  'bought': ['کڕدرا!', 'هاتە کڕین!', 'Purchased!', 'تم الشراء!', 'خریداری شد!', 'Satın alındı!'],
  'buy_go': ['کڕین بە {0} سکە', 'کڕین ب {0} پارە', 'Buy for {0} coins', 'شراء بـ {0} عملة', 'خرید با {0} سکه', '{0} coin ile al'],
  'buy_s': ['نرخ: {0} سکە · باڵانسی تۆ: {1}', 'بها: {0} پارە · باڵانسێ تە: {1}', 'Price: {0} coins · Your balance: {1}', 'السعر: {0} عملة · رصيدك: {1}', 'قیمت: {0} سکه · موجودی شما: {1}', 'Fiyat: {0} coin · Bakiyen: {1}'],
  'buy_t': ['کڕینی {0}', 'کڕینا {0}', 'Buy {0}', 'شراء {0}', 'خرید {0}', '{0} satın al'],
  'cancel': ['پاشگەزبوونەوە', 'پاشڤەبوون', 'Cancel', 'إلغاء', 'لغو', 'Vazgeç'],
  'cat_calm': ['ئارامی', 'ئارامی', 'Calm', 'الهدوء', 'آرامش', 'Sakinlik'],
  'cat_food': ['خۆراک', 'خوارن', 'Food', 'الطعام', 'غذا', 'Yemek'],
  'cat_gym': ['جیم', 'جیم', 'Gym', 'النادي', 'باشگاه', 'Spor salonu'],
  'cat_heart': ['دڵ', 'دل', 'Heart', 'القلب', 'قلب', 'Kalp'],
  'cat_o2': ['ئۆکسجین', 'ئۆکسجین', 'Oxygen', 'الأكسجين', 'اکسیژن', 'Oksijen'],
  'cat_rec': ['چاکبوونەوە', 'باشبوون', 'Recovery', 'التعافي', 'ریکاوری', 'Toparlanma'],
  'cat_run': ['ڕاکردن', 'ڕەڤین', 'Running', 'الجري', 'دویدن', 'Koşu'],
  'cat_sleep': ['خەو', 'نڤستن', 'Sleep', 'النوم', 'خواب', 'Uyku'],
  'cat_walk': ['پیاسە', 'پیاسە', 'Walking', 'المشي', 'پیاده‌روی', 'Yürüyüş'],
  'cat_water': ['ئاو', 'ئاڤ', 'Water', 'الماء', 'آب', 'Su'],
  'cb_s': ['دوای ڕۆژێکی بێ چالاکی گەڕایتەوە: +50 خاڵی دیاری', 'پشتی ڕۆژەکا بێ چالاکی تو زڤڕی: +50 خالێن دیاری', 'Back after an inactive day: +50 bonus points', 'عدت بعد يوم بلا نشاط: +50 نقطة مكافأة', 'بعد از یک روز بی‌تحرک برگشتید: +50 امتیاز هدیه', 'Pasif bir günden sonra döndün: +50 bonus puan'],
  'cb_t': ['گەڕانەوەیەکی جوان!', 'زڤڕینەکا جوان!', 'Great comeback!', 'عودة رائعة!', 'بازگشت عالی!', 'Harika dönüş!'],
  'cd_end': ['کۆتایی وەرز', 'دووماهیا وەرزی', 'Season ends in', 'ينتهي الموسم بعد', 'پایان فصل تا', 'Sezon bitimine'],
  'cd_start': ['دەستپێکردنی وەرز', 'دەستپێکرنا وەرزی', 'Season starts in', 'يبدأ الموسم بعد', 'شروع فصل تا', 'Sezon başlangıcına'],
  'ch_any_s': ['کارەکتەرە بەخۆڕاییەکان و ئەوانەی کڕیوتن دەتوانیت هەڵیانبژێریت.', 'کارەکتەرێن بێ بەرامبەر و یێن تە کڕین دشێی هەلبژێری.', 'You can pick free characters and the ones you bought.', 'يمكنك اختيار الشخصيات المجانية وما اشتريته.', 'کاراکترهای رایگان و خریداری‌شده را می‌توانی انتخاب کنی.', 'Ücretsiz ve satın aldığın karakterleri seçebilirsin.'],
  'ch_done': ['کارەکتەرەکەت گۆڕدرا', 'کارەکتەرێ تە هاتە گوهۆڕین', 'Character updated', 'تم تغيير الشخصية', 'کاراکتر عوض شد', 'Karakter güncellendi'],
  'ch_live_s': ['بۆ دادپەروەری، کارەکتەر لە کاتی وەرزدا ناگۆڕدرێت. دەتوانیت ئێستا بیکڕیت و دوای وەرز بەکاری بهێنیت.', 'بۆ دادپەروەریێ، کارەکتەر د دەمێ وەرزی دا ناهێتە گوهۆڕین. دشێی نوکە بکڕی و پشتی وەرزی بکاربینی.', 'For fairness, characters are fixed during a season. You can buy now and use it after the season.', 'للعدالة، لا تتغير الشخصية أثناء الموسم. يمكنك الشراء الآن والاستخدام بعد الموسم.', 'برای عدالت، کاراکتر در طول فصل ثابت است. الان بخر و بعد از فصل استفاده کن.', 'Adalet için karakter sezon boyunca sabittir. Şimdi alıp sezondan sonra kullanabilirsin.'],
  'ch_rule': ['یەکجار لە 30 ڕۆژدا', 'ئێک جار د 30 ڕۆژان دا', 'Once every 30 days', 'مرة كل 30 يوماً', 'یک بار در 30 روز', '30 günde bir'],
  'ch_st_first': ['کارەکتەرێک هەڵبژێرە', 'کارەکتەرەکێ هەلبژێرە', 'Choose a character', 'اختر شخصية', 'یک کاراکتر انتخاب کن', 'Bir karakter seç'],
  'ch_st_live': ['لە کاتی وەرزدا داخراوە', 'د دەمێ وەرزی دا یا گرتییە', 'Locked during the season', 'مقفل أثناء الموسم', 'در طول فصل قفل است', 'Sezon boyunca kilitli'],
  'ch_st_ok': ['دەتوانیت ئێستا کارەکتەرەکەت بگۆڕیت', 'دشێی نوکە کارەکتەرێ خۆ بگوهۆڕی', 'You can change your character now', 'يمكنك تغيير شخصيتك الآن', 'الان می‌توانی کاراکترت را عوض کنی', 'Karakterini şimdi değiştirebilirsin'],
  'ch_st_wait': ['{0} ڕۆژی تر دەتوانیت بیگۆڕیت', 'پشتی {0} ڕۆژان دشێی بگوهۆڕی', 'You can change it in {0} days', 'يمكنك تغييرها بعد {0} أيام', '{0} روز دیگر می‌توانی عوضش کنی', '{0} gün sonra değiştirebilirsin'],
  'ch_t': ['کارەکتەرەکەم', 'کارەکتەرێ من', 'My character', 'شخصيتي', 'کاراکتر من', 'Karakterim'],
  'ch_use': ['بەکارهێنانی ئەم کارەکتەرە', 'بکارئینانا ڤی کارەکتەری', 'Use this character', 'استخدم هذه الشخصية', 'استفاده از این کاراکتر', 'Bu karakteri kullan'],
  'chest_got': ['+{0} سکەت بردەوە!', 'تە +{0} پارە ب دەستڤەئینان!', 'You won +{0} coins!', 'ربحت +{0} عملة!', '+{0} سکه بردی!', '+{0} coin kazandın!'],
  'chest_need': ['{0} ئەرکی تر بۆ کردنەوەی سندوق', '{0} ئەرکێن دی بۆ ڤەکرنا سندوقێ', '{0} more missions to open the chest', '{0} مهام أخرى لفتح الصندوق', '{0} مأموریت دیگر برای باز کردن صندوق', 'Sandığı açmak için {0} görev daha'],
  'chest_open': ['کردنەوەی سندوق', 'ڤەکرنا سندوقێ', 'Open chest', 'افتح الصندوق', 'باز کردن صندوق', 'Sandığı aç'],
  'chest_range': ['5 بۆ 25 سکە', '5 هەتا 25 پارە', '5 to 25 coins', 'من 5 إلى 25 عملة', '5 تا 25 سکه', '5 ile 25 coin arası'],
  'chest_ready': ['سندوقەکە ئامادەیە!', 'سندوق یا ئامادەیە!', 'Chest is ready!', 'الصندوق جاهز!', 'صندوق آماده است!', 'Sandık hazır!'],
  'chest_t': ['سندوقی ئەمڕۆ', 'سندوقا ئەڤرۆ', 'Today\'s chest', 'صندوق اليوم', 'صندوق امروز', 'Bugünün sandığı'],
  'chest_tomorrow': ['سبەینێ سندوقێکی نوێ', 'سوبەهی سندوقەکا نوو', 'A new chest tomorrow', 'صندوق جديد غداً', 'فردا صندوق جدید', 'Yarın yeni sandık'],
  'chk_calm': ['ئاستی سترێس لە HRV ی Band ـەوە ژمێردرا.', 'ئاستێ سترێسێ ژ HRV یا Band ـێ هاتە هەژمارتن.', 'Stress level computed from Band HRV.', 'حُسب مستوى التوتر من HRV في Band.', 'سطح استرس از HRV باند محاسبه شد.', 'Stres seviyesi Band HRV\'sinden hesaplandı.'],
  'chk_food': ['ژەمەکان لانیکەم 90 خولەک لێک دوورن، زۆرترین 3 ژەم.', 'ژەم کێمتر 90 خولەکان ژێک دوورن، زێدەتر 3 ژەم.', 'Meals at least 90 minutes apart, max 3 meals.', 'الوجبات تفصلها 90 دقيقة على الأقل، 3 وجبات كحد أقصى.', 'وعده‌ها حداقل 90 دقیقه فاصله، حداکثر 3 وعده.', 'Öğünler en az 90 dk arayla, en fazla 3 öğün.'],
  'chk_gen': ['داتاکە لە سەرچاوەی پشتڕاستکراوەوە هاتووە.', 'داتا ژ ژێدەرەکێ پشتڕاستکری هاتیە.', 'Data came from a verified source.', 'البيانات من مصدر موثوق.', 'داده از منبع تأییدشده آمده است.', 'Veri doğrulanmış kaynaktan geldi.'],
  'chk_gym': ['ماوە و ناوچەکانی لێدانی دڵ پشکنران.', 'دەم و دەڤەرێن لێدانێن دلی هاتنە پشکنین.', 'Duration and heart-rate zones were checked.', 'تم فحص المدة ومناطق نبض القلب.', 'مدت و مناطق ضربان قلب بررسی شد.', 'Süre ve nabız bölgeleri kontrol edildi.'],
  'chk_gym_p': ['ماوەی وەرزش لە بەشی وەرزشی ئەپەکەوە تۆمارکرا.', 'دەمێ وەرزشێ ژ پشکا وەرزشێ یا ئەپی هاتە تۆمارکرن.', 'Workout duration logged in the app sports section.', 'سُجلت مدة التمرين من قسم الرياضة في التطبيق.', 'مدت ورزش از بخش ورزش اپ ثبت شد.', 'Antrenman süresi uygulamanın spor bölümünden kaydedildi.'],
  'chk_heart': ['خولەکەکانی چالاکی دڵ لەگەڵ جووڵە بەراورد کران.', 'خولەکێن چالاکیا دلی دگەل لڤینێ هاتنە بەراوردکرن.', 'Active heart minutes matched with movement.', 'قورنت دقائق نشاط القلب بالحركة.', 'دقایق فعالیت قلب با حرکت مقایسه شد.', 'Aktif kalp dakikaları hareketle eşleştirildi.'],
  'chk_o2': ['SpO₂ لە Band ـەوە خوێندرایەوە (80–100%).', 'SpO₂ ژ Band ـێ هاتە خواندن (80–100%).', 'SpO₂ read from the Band (80–100%).', 'قُرئ SpO₂ من Band (80–100%).', 'SpO₂ از Band خوانده شد (80–100%).', 'SpO₂ Band\'den okundu (%80–100).'],
  'chk_rec': ['HRV لە کاتی خەودا خوێندرایەوە.', 'HRV د دەمێ نڤستنێ دا هاتە خواندن.', 'HRV read during sleep.', 'قُرئ HRV أثناء النوم.', 'HRV در طول خواب خوانده شد.', 'HRV uyku sırasında okundu.'],
  'chk_run': ['GPS و خێرایی و لێدانی دڵ پشکنران.', 'GPS و لەز و لێدانێن دلی هاتنە پشکنین.', 'GPS, pace and heart rate were checked.', 'تم فحص GPS والسرعة ونبض القلب.', 'GPS، سرعت و ضربان قلب بررسی شد.', 'GPS, tempo ve nabız kontrol edildi.'],
  'chk_sleep': ['خەو لە Band ـەوە بە لێدانی دڵ و جووڵە دیاریکرا.', 'نڤستن ژ Band ـێ ب لێدانێن دلی و لڤینێ هاتە دیارکرن.', 'Sleep detected by the Band using heart rate and motion.', 'تم رصد النوم بواسطة Band عبر النبض والحركة.', 'خواب توسط Band با ضربان و حرکت تشخیص داده شد.', 'Uyku Band tarafından nabız ve hareketle algılandı.'],
  'chk_walk': ['هەنگاوەکان لە Band ـەوە خوێندرانەوە و لەگەڵ جووڵەی دەست بەراورد کران.', 'پێنگاڤ ژ Band ـێ هاتنە خواندن و دگەل لڤینا دەستی هاتنە بەراوردکرن.', 'Steps read from the Band and checked against wrist motion.', 'قُرئت الخطوات من Band وقورنت بحركة المعصم.', 'قدم‌ها از Band خوانده و با حرکت مچ مقایسه شد.', 'Adımlar Band\'den okundu ve bilek hareketiyle karşılaştırıldı.'],
  'chk_walk_p': ['هەنگاوەکان لە هەستەوەری مۆبایلەوە خوێندرانەوە.', 'پێنگاڤ ژ هەستەوەرا مۆبایلێ هاتنە خواندن.', 'Steps read from the phone sensor.', 'قُرئت الخطوات من مستشعر الهاتف.', 'قدم‌ها از حسگر گوشی خوانده شد.', 'Adımlar telefon sensöründen okundu.'],
  'chk_water': ['کاتی هەر پەرداخێک تۆمار دەکرێت؛ 500ml لە یەک جاردا، 1 لیتر لە کاتژمێرێکدا.', 'دەمێ هەر پەرداخەکێ دهێتە تۆمارکرن؛ 500ml ب ئێک جار، 1 لیتر د دەمژمێرەکێ دا.', 'Each glass is time-stamped; max 500 ml at once, 1 liter per hour.', 'يُسجل وقت كل كوب؛ 500 مل دفعة واحدة كحد أقصى، ولتر في الساعة.', 'زمان هر لیوان ثبت می‌شود؛ حداکثر 500 ml یکجا و 1 لیتر در ساعت.', 'Her bardak zaman damgalı; tek seferde en fazla 500 ml, saatte 1 litre.'],
  'clock_s': ['تا کاتەکە ڕاست نەکرێتەوە سکە زیاد ناکرێت.', 'هەتا دەم نەهێتە ڕاستکرن پارە زێدە نابن.', 'No coins are added until the clock is corrected.', 'لن تُضاف عملات حتى تصحيح الساعة.', 'تا اصلاح ساعت سکه اضافه نمی‌شود.', 'Saat düzeltilene kadar coin eklenmez.'],
  'clock_t': ['کاتی ئامێرەکە گۆڕدراوە', 'دەمێ ئامیری هاتیە گوهۆڕین', 'Device clock was changed', 'تم تغيير ساعة الجهاز', 'ساعت دستگاه تغییر کرده', 'Cihaz saati değiştirilmiş'],
  'close': ['داخستن', 'گرتن', 'Close', 'إغلاق', 'بستن', 'Kapat'],
  'co_buy': ['کڕینی دیزاینی کارت', 'کڕینا دیزاینا کارتێ', 'Card design purchase', 'شراء تصميم بطاقة', 'خرید طرح کارت', 'Kart tasarımı alımı'],
  'co_char': ['کڕینی کارەکتەر', 'کڕینا کارەکتەری', 'Character purchase', 'شراء شخصية', 'خرید کاراکتر', 'Karakter alımı'],
  'co_chest': ['سندوقی ئەرکەکان', 'سندوقا ئەرکان', 'Mission chest', 'صندوق المهام', 'صندوق مأموریت', 'Görev sandığı'],
  'co_day': ['چالاکی ڕۆژانە', 'چالاکیا ڕۆژانە', 'Daily activity', 'النشاط اليومي', 'فعالیت روزانه', 'Günlük aktivite'],
  'co_founder': ['دیاریی دامەزرێنەر', 'دیاریا دامەزرێنەری', 'Founder gift', 'هدية المؤسس', 'هدیه بنیان‌گذار', 'Kurucu hediyesi'],
  'co_freeze': ['پاراستنی زنجیرە بەکارهات', 'پاراستنا زنجیرێ هاتە بکارئینان', 'Streak shield used', 'تم استخدام حماية السلسلة', 'محافظ زنجیره استفاده شد', 'Seri kalkanı kullanıldı'],
  'co_frzbuy': ['کڕینی پاراستنی زنجیرە', 'کڕینا پاراستنا زنجیرێ', 'Streak shield purchase', 'شراء حماية السلسلة', 'خرید محافظ زنجیره', 'Seri kalkanı alımı'],
  'co_guess': ['پێشبینیی ڕاست', 'پێشبینیا دروست', 'Correct guess', 'تخمين صحيح', 'حدس درست', 'Doğru tahmin'],
  'co_streak': ['زنجیرەی 7 ڕۆژ', 'زنجیرا 7 ڕۆژان', '7-day streak', 'سلسلة 7 أيام', 'زنجیره 7 روزه', '7 günlük seri'],
  'co_week': ['خەڵاتی هەفتە', 'خەڵاتا حەفتیێ', 'Weekly reward', 'مكافأة الأسبوع', 'جایزه هفته', 'Haftalık ödül'],
  'co_welcome': ['دیاریی بەخێرهاتن', 'دیاریا بخێرهاتنێ', 'Welcome gift', 'هدية الترحيب', 'هدیه خوش‌آمد', 'Hoş geldin hediyesi'],
  'coin_note_s': ['سکە تەنها لەناو VEX Arena بەکاردێت و ناگۆڕدرێتەوە بە پارە. خەڵاتەکان تەنها بە پلەی وەرز دەدرێن.', 'پارە بتنێ د ناڤ VEX Arena دا دهێنە بکارئینان و ب پارەیێ ڕاستەقینە ناهێنە گوهۆڕین. خەڵات بتنێ ب پلا وەرزی دهێنە دان.', 'Coins are only used inside VEX Arena and cannot be exchanged for money. Prizes go only by season rank.', 'تُستخدم العملات داخل VEX Arena فقط ولا تُستبدل بالمال. الجوائز حسب ترتيب الموسم فقط.', 'سکه فقط داخل VEX Arena استفاده می‌شود و قابل تبدیل به پول نیست. جوایز فقط بر اساس رتبه فصل است.', 'Coin\'ler sadece VEX Arena içinde kullanılır, paraya çevrilemez. Ödüller yalnızca sezon sırasına göre verilir.'],
  'coin_note_t': ['سکە پارە نییە', 'پارە نە پارەیێ ڕاستەقینەیە', 'Coins are not money', 'العملات ليست نقوداً', 'سکه پول نیست', 'Coin para değildir'],
  'coins_s': ['سکە بە چالاکی ڕۆژانە کۆدەکرێتەوە', 'پارە ب چالاکیا ڕۆژانە دهێنە کۆمکرن', 'Coins are earned through daily activity', 'تُكسب العملات بالنشاط اليومي', 'سکه با فعالیت روزانه به دست می‌آید', 'Coin günlük aktiviteyle kazanılır'],
  'coins_t': ['سکەکانم', 'پارێن من', 'My coins', 'عملاتي', 'سکه‌های من', 'Coin\'lerim'],
  'counted': ['ئەمڕۆ حیساب کرا', 'ئەڤرۆ هاتە حیسابکرن', 'Today counts', 'تم احتساب اليوم', 'امروز حساب شد', 'Bugün sayıldı'],
  'day_n_of': ['ئەمە ڕۆژی چالاکی {0} دەبێت لە {1}', 'ئەڤە دێ بیتە ڕۆژا چالاکیێ {0} ژ {1}', 'This would be active day {0} of {1}', 'سيكون هذا اليوم النشط {0} من {1}', 'این روز فعال {0} از {1} خواهد بود', 'Bu, {1} günden {0}. aktif gün olur'],
  'do_now': ['ئێستا {0} بکە: تا +{1} خاڵ', 'نوکە {0} بکە: هەتا +{1} خال', 'Do {0} now: up to +{1} pts', 'قم بـ{0} الآن: حتى +{1} نقطة', 'الان {0}: تا +{1} امتیاز', 'Şimdi {0}: +{1} puana kadar'],
  'dv_band': ['لیگی Band', 'لیگا Band', 'Band league', 'دوري Band', 'لیگ Band', 'Band ligi'],
  'dv_band_s': ['هەموو 10 بەش · تا 600 خاڵ لە ڕۆژێکدا · خەڵات: ئۆتۆمبێل، iPhone 17 Pro، 1,000,000 دینار', 'هەمی 10 پشک · هەتا 600 خال د ڕۆژەکێ دا · خەڵات: ترومبێل، iPhone 17 Pro، 1,000,000 دینار', 'All 10 categories · up to 600 pts a day · prizes: car, iPhone 17 Pro, 1,000,000 IQD', 'جميع الأقسام العشرة · حتى 600 نقطة يومياً · الجوائز: سيارة، iPhone 17 Pro، مليون دينار', 'همه 10 بخش · تا 600 امتیاز در روز · جوایز: خودرو، iPhone 17 Pro، 1,000,000 دینار', '10 kategorinin tamamı · günde 600 puana kadar · ödüller: araba, iPhone 17 Pro, 1.000.000 IQD'],
  'dv_band_t': ['تۆ دەچیتە لیگی Band', 'تو دێ چییە لیگا Band', 'You join the Band league', 'ستنضم إلى دوري Band', 'شما وارد لیگ Band می‌شوید', 'Band ligine katılıyorsun'],
  'dv_phone': ['لیگی مۆبایل', 'لیگا مۆبایلێ', 'Phone league', 'دوري الهاتف', 'لیگ موبایل', 'Telefon ligi'],
  'dv_phone_s': ['بێ Band · 5 بەش · تا 200 خاڵ لە ڕۆژێکدا · خەڵات: 250,000 / 150,000 / 100,000 دینار. کاتێک Band ـت پەیوەست کرد، ئۆتۆماتیک دەچیتە لیگی Band.', 'بێ Band · 5 پشک · هەتا 200 خال د ڕۆژەکێ دا · خەڵات: 250,000 / 150,000 / 100,000 دینار. دەمێ Band گرێدای، ب خۆ دێ چییە لیگا Band.', 'No Band · 5 categories · up to 200 pts a day · prizes: 250,000 / 150,000 / 100,000 IQD. Connect a Band and you move up automatically.', 'بدون Band · 5 أقسام · حتى 200 نقطة يومياً · الجوائز: 250,000 / 150,000 / 100,000 دينار. عند ربط Band تنتقل تلقائياً.', 'بدون Band · 5 بخش · تا 200 امتیاز در روز · جوایز: 250,000 / 150,000 / 100,000 دینار. با وصل کردن Band خودکار ارتقا می‌یابید.', 'Band yok · 5 kategori · günde 200 puana kadar · ödüller: 250.000 / 150.000 / 100.000 IQD. Band bağlayınca otomatik yükselirsin.'],
  'dv_phone_t': ['تۆ دەچیتە لیگی مۆبایل', 'تو دێ چییە لیگا مۆبایلێ', 'You join the Phone league', 'ستنضم إلى دوري الهاتف', 'شما وارد لیگ موبایل می‌شوید', 'Telefon ligine katılıyorsun'],
  'e_agree': ['تکایە ڕەزامەندی لەسەر یاساکان بدە', 'هیڤیە ڕەزامەندیێ ل سەر یاسایان بدە', 'Please agree to the rules', 'يرجى الموافقة على القوانين', 'لطفاً با قوانین موافقت کنید', 'Lütfen kuralları kabul et'],
  'e_char': ['کارەکتەرێک هەڵبژێرە', 'کارەکتەرەکێ هەلبژێرە', 'Choose a character', 'اختر شخصية', 'یک کاراکتر انتخاب کنید', 'Bir karakter seç'],
  'e_city': ['شارەکەت هەڵبژێرە', 'باژێرێ خۆ هەلبژێرە', 'Choose your city', 'اختر مدينتك', 'شهر خود را انتخاب کنید', 'Şehrini seç'],
  'e_name': ['ناوی تەواو بنووسە (ناو و پاشناو)', 'ناڤێ تەمام بنڤیسە (ناڤ و پاشناڤ)', 'Enter your full name (first and last)', 'اكتب الاسم الكامل (الاسم والكنية)', 'نام کامل را بنویسید (نام و نام خانوادگی)', 'Tam adını yaz (ad ve soyad)'],
  'e_phone': ['ژمارەی مۆبایلی عێراقی دروست بنووسە (07XX XXX XXXX)', 'ژمارا مۆبایلا عیراقی یا دروست بنڤیسە (07XX XXX XXXX)', 'Enter a valid Iraqi mobile number (07XX XXX XXXX)', 'أدخل رقم هاتف عراقي صحيح (07XX XXX XXXX)', 'یک شماره موبایل عراقی معتبر وارد کنید (07XX XXX XXXX)', 'Geçerli bir Irak cep numarası gir (07XX XXX XXXX)'],
  'earn_chest': ['سندوقی ئەرکەکان: 5 بۆ 25 سکە', 'سندوقا ئەرکان: 5 هەتا 25 پارە', 'Mission chest: 5 to 25 coins', 'صندوق المهام: 5 إلى 25 عملة', 'صندوق مأموریت: 5 تا 25 سکه', 'Görev sandığı: 5–25 coin'],
  'earn_day': ['هەر 25 خاڵ = 1 سکە (تا {0} لە ڕۆژێکدا)', 'هەر 25 خال = 1 پارە (هەتا {0} د ڕۆژەکێ دا)', 'Every 25 pts = 1 coin (up to {0} a day)', 'كل 25 نقطة = عملة (حتى {0} يومياً)', 'هر 25 امتیاز = 1 سکه (تا {0} در روز)', 'Her 25 puan = 1 coin (günde {0}\'a kadar)'],
  'earn_day_s': ['ئەمڕۆ: {0} / {1}', 'ئەڤرۆ: {0} / {1}', 'Today: {0} / {1}', 'اليوم: {0} / {1}', 'امروز: {0} / {1}', 'Bugün: {0} / {1}'],
  'earn_guess': ['پێشبینیی ڕاستی هێزی نهێنی: +10 سکە', 'پێشبینیا دروست یا هێزا نهێنی: +10 پارە', 'Correct secret-power guess: +10 coins', 'تخمين صحيح للقوة السرية: +10 عملات', 'حدس درست قدرت مخفی: +10 سکه', 'Doğru gizli güç tahmini: +10 coin'],
  'earn_streak': ['هەر 7 ڕۆژ زنجیرە: +15 سکە', 'هەر 7 ڕۆژێن زنجیرێ: +15 پارە', 'Every 7-day streak: +15 coins', 'كل سلسلة 7 أيام: +15 عملة', 'هر زنجیره 7 روزه: +15 سکه', 'Her 7 günlük seri: +15 coin'],
  'earn_t': ['چۆن سکە کۆبکەمەوە', 'چاوا پارێ کۆم بکەم', 'How to earn', 'كيف تكسب', 'چطور سکه بگیرم', 'Nasıl kazanılır'],
  'earn_week': ['پلەی هەفتە: تا 50 سکە', 'پلا حەفتیێ: هەتا 50 پارە', 'Weekly rank: up to 50 coins', 'ترتيب الأسبوع: حتى 50 عملة', 'رتبه هفته: تا 50 سکه', 'Haftalık sıra: 50 coin\'e kadar'],
  'edit': ['دەستکاری پرۆفایل', 'دەستکاریا پرۆفایلێ', 'Edit profile', 'تعديل الملف', 'ویرایش پروفایل', 'Profili düzenle'],
  'edit_lock': ['ژمارەی مۆبایل و شار ناگۆڕدرێن بۆ پاراستنی دادپەروەری.', 'ژمارا مۆبایلێ و باژێر ناهێنە گوهۆڕین بۆ پاراستنا دادپەروەریێ.', 'Phone and city cannot be changed, for fairness.', 'لا يمكن تغيير الهاتف والمدينة حفاظاً على العدالة.', 'شماره و شهر برای عدالت قابل تغییر نیست.', 'Adalet için telefon ve şehir değiştirilemez.'],
  'edit_s': ['ناو و دەربارەی خۆت بگۆڕە', 'ناڤ و دەربارێ خۆ بگوهۆڕە', 'Change your name and bio', 'غيّر اسمك ونبذتك', 'نام و بیوگرافی را عوض کن', 'Adını ve biyografini değiştir'],
  'ej_after': ['دوای دەستپێکردن', 'پشتی دەستپێکرنێ', 'After start', 'بعد البدء', 'بعد از شروع', 'Başladıktan sonra'],
  'ej_all30': ['هەموو 30 ڕۆژ', 'هەمی 30 ڕۆژ', 'All 30 days', 'كل الـ30 يوماً', 'همه 30 روز', '30 günün tamamı'],
  'ej_allpz': ['هەموو خەڵاتەکان', 'هەمی خەڵات', 'All prizes', 'كل الجوائز', 'همه جوایز', 'Tüm ödüller'],
  'ej_badge': ['نیشانی دامەزرێنەر', 'نیشانا دامەزرێنەری', 'Founder badge', 'شارة المؤسس', 'نشان بنیان‌گذار', 'Kurucu rozeti'],
  'ej_before': ['پێش دەستپێکردن', 'بەری دەستپێکرنێ', 'Before start', 'قبل البدء', 'قبل از شروع', 'Başlamadan önce'],
  'ej_left': ['ڕۆژە ماوەکان', 'ڕۆژێن مای', 'Remaining days', 'الأيام المتبقية', 'روزهای باقی‌مانده', 'Kalan günler'],
  'ej_s': ['ئێستا تۆمار بکە، دامەزرێنەر بە', 'نوکە تۆمار بکە، ببە دامەزرێنەر', 'Register now, become a founder', 'سجّل الآن وكن مؤسساً', 'الان ثبت‌نام کن، بنیان‌گذار شو', 'Şimdi kaydol, kurucu ol'],
  'ej_t': ['بەشداربوونی زوو', 'بەشداربوونا زوو', 'Join early', 'الانضمام المبكر', 'پیوستن زودهنگام', 'Erken katıl'],
  'ej_tie': ['پێشەنگی لە یەکسانیدا', 'پێشەنگی د وەکهەڤیێ دا', 'Wins ties', 'الأفضلية عند التعادل', 'برتری در تساوی', 'Eşitlikte öncelik'],
  'ej_to6': ['تا ڕۆژی 6', 'هەتا ڕۆژا 6', 'Until day 6', 'حتى اليوم 6', 'تا روز 6', '6. güne kadar'],
  'ej_week': ['خەڵاتی هەفتانە', 'خەڵاتێن حەفتیانە', 'Weekly rewards', 'مكافآت أسبوعية', 'جوایز هفتگی', 'Haftalık ödüller'],
  'el_all': ['هێشتا دەتوانیت هەموو خەڵاتەکان ببەیتەوە', 'هێشتا دشێی هەمی خەڵاتان ببەی', 'You can still win every prize', 'لا يزال بإمكانك الفوز بكل الجوائز', 'هنوز می‌توانی همه جوایز را ببری', 'Hâlâ tüm ödülleri kazanabilirsin'],
  'el_can': ['{0} ڕۆژ ماوە، {1} ڕۆژی چالاکی ترت پێویستە', '{0} ڕۆژ مایە، {1} ڕۆژێن چالاک یێن دی پێدڤینە', '{0} days left, you need {1} more active days', 'بقي {0} يوماً، تحتاج {1} أيام نشطة أخرى', '{0} روز مانده، {1} روز فعال دیگر لازم است', '{0} gün kaldı, {1} aktif gün daha gerekli'],
  'el_day': ['ئەمڕۆ ڕۆژی {0}ی وەرزە · {1} ڕۆژ ماوە', 'ئەڤرۆ ڕۆژا {0} یا وەرزیە · {1} ڕۆژ مایە', 'Today is season day {0} · {1} days left', 'اليوم هو اليوم {0} من الموسم · بقي {1} يوماً', 'امروز روز {0} فصل است · {1} روز مانده', 'Bugün sezonun {0}. günü · {1} gün kaldı'],
  'el_guar': ['خەڵاتە گەورەکان ناگەیتێ، بەڵام خەڵاتی هەفتانە و سکە هەیە', 'خەڵاتێن مەزن ناگەهیێ، بەلێ خەڵاتێن حەفتیانە و پارە هەنە', 'Grand prizes are out of reach, but weekly rewards and coins remain', 'الجوائز الكبرى لم تعد متاحة، لكن المكافآت الأسبوعية والعملات متاحة', 'جوایز بزرگ دیگر ممکن نیست، اما جوایز هفتگی و سکه هست', 'Büyük ödüller artık mümkün değil, ama haftalık ödüller ve coin var'],
  'el_no25': ['ناگەیتە 25 ڕۆژ، بەڵام خەڵاتی هەفتانە بەردەوامە', 'ناگەهیە 25 ڕۆژان، بەلێ خەڵاتێن حەفتیانە بەردەوامن', 'You can\'t reach 25 days, but weekly rewards continue', 'لن تصل إلى 25 يوماً، لكن المكافآت الأسبوعية مستمرة', 'به 25 روز نمی‌رسی، اما جوایز هفتگی ادامه دارد', '25 güne ulaşamazsın, ama haftalık ödüller sürüyor'],
  'el_noall': ['ئەم وەرزە بۆ خەڵاتی هەفتانە و سکە یاری بکە', 'ئەڤی وەرزی بۆ خەڵاتێن حەفتیانە و پارێ یاری بکە', 'Play this season for weekly rewards and coins', 'العب هذا الموسم للمكافآت الأسبوعية والعملات', 'این فصل برای جوایز هفتگی و سکه بازی کن', 'Bu sezon haftalık ödüller ve coin için oyna'],
  'el_ok': ['مەرجی خەڵاتت پڕکردەوە! بەردەوام بە بۆ پلەی باشتر', 'تە مەرجێ خەڵاتی تەمامکر! بەردەوام بە بۆ پلەکا باشتر', 'You met the prize condition! Keep going for a better rank', 'استوفيت شرط الجوائز! استمر لترتيب أفضل', 'شرط جایزه را کامل کردی! برای رتبه بهتر ادامه بده', 'Ödül şartını tamamladın! Daha iyi sıra için devam et'],
  'el_pre': ['تۆ دامەزرێنەر دەبیت: +50 سکە و نیشانی تایبەت', 'تو دێ بیە دامەزرێنەر: +50 پارە و نیشانا تایبەت', 'You will be a founder: +50 coins and a special badge', 'ستكون مؤسساً: +50 عملة وشارة خاصة', 'بنیان‌گذار می‌شوی: +50 سکه و نشان ویژه', 'Kurucu olacaksın: +50 coin ve özel rozet'],
  'el_week': ['تەنها خەڵاتی هەفتانە و سکە بەردەستە', 'بتنێ خەڵاتێن حەفتیانە و پارە هەنە', 'Only weekly rewards and coins are available', 'المتاح فقط المكافآت الأسبوعية والعملات', 'فقط جوایز هفتگی و سکه در دسترس است', 'Sadece haftalık ödüller ve coin mevcut'],
  'ev_back': ['بەخێربێیتەوە! +50 خاڵ', 'بخێر زڤڕی! +50 خال', 'Welcome back! +50 pts', 'مرحباً بعودتك! +50 نقطة', 'خوش برگشتی! +50 امتیاز', 'Tekrar hoş geldin! +50 puan'],
  'ev_band': ['Band پەیوەست کرا: تۆ ئێستا لە لیگی Band ـیت!', 'Band هاتە گرێدان: تو نوکە ل لیگا Band دای!', 'Band connected: you are now in the Band league!', 'تم ربط Band: أنت الآن في دوري Band!', 'Band وصل شد: اکنون در لیگ Band هستید!', 'Band bağlandı: artık Band ligindesin!'],
  'ev_counted': ['ئەمڕۆ وەک ڕۆژێکی چالاک حیساب کرا', 'ئەڤرۆ وەک ڕۆژەکا چالاک هاتە حیسابکرن', 'Today counts as an active day', 'احتُسب اليوم يوماً نشطاً', 'امروز روز فعال حساب شد', 'Bugün aktif gün sayıldı'],
  'ev_goal': ['ئامانجی ئەمڕۆت پێکا!', 'تە ئارمانجا ئەڤرۆ پێکا!', 'You hit today\'s goal!', 'حققت هدف اليوم!', 'به هدف امروز رسیدی!', 'Bugünün hedefine ulaştın!'],
  'ev_guess': ['پێشبینییەکەت ڕاست بوو! +10 سکە', 'پێشبینیا تە دروست بوو! +10 پارە', 'Your guess was right! +10 coins', 'كان تخمينك صحيحاً! +10 عملات', 'حدست درست بود! +10 سکه', 'Tahminin doğruydu! +10 coin'],
  'exc_1': ['3 جار لە هەر وەرزێکدا', '3 جاران د هەر وەرزەکێ دا', '3 times per season', '3 مرات في كل موسم', '3 بار در هر فصل', 'Sezonda 3 kez'],
  'exc_2': ['خاڵ نادات، تەنها ڕۆژەکە دەپارێزێت', 'خالان نادەت، بتنێ ڕۆژێ دپارێزیت', 'Gives no points, only protects the day', 'لا يمنح نقاطاً، يحمي اليوم فقط', 'امتیاز نمی‌دهد، فقط روز را حفظ می‌کند', 'Puan vermez, sadece günü korur'],
  'exc_done': ['ئەمڕۆ چالاکیت، پێویست ناکات', 'ئەڤرۆ تو چالاکی، پێدڤی ناکەت', 'You\'re active today, not needed', 'أنت نشط اليوم، لا حاجة', 'امروز فعالی، لازم نیست', 'Bugün aktifsin, gerek yok'],
  'exc_ok': ['ئەمڕۆ پارێزرا', 'ئەڤرۆ هاتە پاراستن', 'Today is protected', 'تمت حماية اليوم', 'امروز محافظت شد', 'Bugün korundu'],
  'exc_s': ['بۆ نەخۆشی یان گەشت: ڕۆژەکە وەک چالاک حیساب دەکرێت بۆ مەرجی 25 ڕۆژ', 'بۆ نەخۆشیێ یان گەشتێ: ڕۆژ وەک چالاک دهێتە حیسابکرن بۆ مەرجێ 25 ڕۆژان', 'For illness or travel: the day counts toward the 25-day condition', 'للمرض أو السفر: يُحتسب اليوم ضمن شرط الـ25 يوماً', 'برای بیماری یا سفر: روز برای شرط 25 روزه حساب می‌شود', 'Hastalık veya seyahat için: gün 25 gün şartına sayılır'],
  'exc_use': ['ئەمڕۆ بەکاری بهێنە', 'ئەڤرۆ بکاربینە', 'Use today', 'استخدمه اليوم', 'امروز استفاده کن', 'Bugün kullan'],
  'exc_used': ['ئەمڕۆ بەکارهاتووە', 'ئەڤرۆ هاتیە بکارئینان', 'Used today', 'مُستخدم اليوم', 'امروز استفاده شد', 'Bugün kullanıldı'],
  'excuse': ['ڕۆژی بیانوو', 'ڕۆژا بیانوو', 'Excuse day', 'يوم عذر', 'روز معذوریت', 'Mazeret günü'],
  'f_age': ['تەمەن', 'ژی', 'Age', 'العمر', 'سن', 'Yaş'],
  'f_age_y': ['ژێر 18 ساڵ دەتوانیت یاری بکەیت؛ خەڵات بە دایک یان باوک دەدرێت.', 'ژێر 18 ساڵان دشێی یاری بکەی؛ خەڵات دێ دەنە دایک یان بابی.', 'Under 18 can play; prizes are handed to a parent or guardian.', 'يمكن لمن هم دون 18 المشاركة؛ تُسلم الجوائز لولي الأمر.', 'زیر 18 سال می‌توانید بازی کنید؛ جایزه به والدین تحویل داده می‌شود.', '18 yaş altı oynayabilir; ödüller veliye teslim edilir.'],
  'f_char_h': ['کارەکتەرێک هەڵبژێرە بۆ کارتەکەت. دواتر دەتوانیت کارەکتەری تر بە سکە بکڕیت.', 'کارەکتەرەکێ بۆ کارتا خۆ هەلبژێرە. پاشی دشێی کارەکتەرێن دی ب پارە بکڕی.', 'Pick a character for your card. You can buy more with coins later.', 'اختر شخصية لبطاقتك. يمكنك شراء المزيد بالعملات لاحقاً.', 'یک کاراکتر برای کارتت انتخاب کن. بعداً می‌توانی با سکه بیشتر بخری.', 'Kartın için bir karakter seç. Sonra coin ile daha fazlasını alabilirsin.'],
  'f_char_ok': ['هەڵبژاردنێکی جوان!', 'هەلبژارتنەکا جوان!', 'Great choice!', 'اختيار رائع!', 'انتخاب عالی!', 'Harika seçim!'],
  'f_char_pick': ['یەکێک هەڵبژێرە', 'ئێکێ هەلبژێرە', 'Pick one', 'اختر واحدة', 'یکی را انتخاب کن', 'Birini seç'],
  'f_city': ['شارەکەت', 'باژێرێ تە', 'Your city', 'مدينتك', 'شهر شما', 'Şehrin'],
  'f_city_h': ['گەڕان بۆ شار...', 'گەڕیان بۆ باژێری...', 'Search city...', 'ابحث عن مدينة...', 'جستجوی شهر...', 'Şehir ara...'],
  'f_city_none': ['هیچ شارێک نەدۆزرایەوە', 'چ باژێر نەهاتنە دیتن', 'No city found', 'لم يتم العثور على مدينة', 'شهری پیدا نشد', 'Şehir bulunamadı'],
  'f_name': ['ناوی تەواو', 'ناڤێ تەمام', 'Full name', 'الاسم الكامل', 'نام کامل', 'Ad soyad'],
  'f_name_h': ['نموونە: ئاراس کەریم', 'نموونە: ئاراس کەریم', 'e.g. Aras Karim', 'مثال: آراس كريم', 'مثال: آراس کریم', 'örn. Aras Karim'],
  'f_phone': ['ژمارەی مۆبایل', 'ژمارا مۆبایلێ', 'Mobile number', 'رقم الهاتف', 'شماره موبایل', 'Cep numarası'],
  'f_phone_h': ['تەنها بۆ پەیوەندیکردن بە براوەکان بەکاردێت و بە کەس نیشان نادرێت.', 'بتنێ بۆ پەیوەندیکرنا دگەل سەرکەفتیان دهێتە بکارئینان و نیشانی کەسێ نادەین.', 'Used only to contact winners; never shown to anyone.', 'يُستخدم فقط للتواصل مع الفائزين ولا يُعرض لأحد.', 'فقط برای تماس با برندگان استفاده می‌شود و به کسی نمایش داده نمی‌شود.', 'Sadece kazananlarla iletişim için kullanılır, kimseye gösterilmez.'],
  'fair_1_s': ['هەنگاو، خەو، دڵ، ئۆکسجین و HRV ڕاستەوخۆ لە Band ـەوە دێن و دەستکاری ناکرێن.', 'پێنگاڤ، نڤستن، دل، ئۆکسجین و HRV ڕاستەوخۆ ژ Band ـێ دهێن و ناهێنە دەستکاریکرن.', 'Steps, sleep, heart, oxygen and HRV come straight from the Band and cannot be edited.', 'الخطوات والنوم والقلب والأكسجين وHRV تأتي مباشرة من Band ولا يمكن تعديلها.', 'قدم، خواب، قلب، اکسیژن و HRV مستقیم از Band می‌آیند و قابل ویرایش نیستند.', 'Adım, uyku, kalp, oksijen ve HRV doğrudan Band\'den gelir, düzenlenemez.'],
  'fair_1_t': ['داتای ڕاستەوخۆ لە Band', 'داتا ڕاستەوخۆ ژ Band', 'Live data from the Band', 'بيانات مباشرة من Band', 'داده زنده از Band', 'Band\'den canlı veri'],
  'fair_2_s': ['GPS، خێرایی (2.8 تا 13 خولەک بۆ هەر km) و لێدانی دڵ پشکنراون. ئۆتۆمبێل و پاسکیل ڕەتدەکرێنەوە.', 'GPS، لەز (2.8 هەتا 13 خولەک بۆ هەر km) و لێدانێن دلی دهێنە پشکنین. ترومبێل و پاسکیل دهێنە ڕەتکرن.', 'GPS, pace (2.8–13 min per km) and heart rate are checked. Cars and bikes are rejected.', 'يتم فحص GPS والسرعة (2.8–13 دقيقة/كم) ونبض القلب. تُرفض السيارات والدراجات.', 'GPS، سرعت (2.8 تا 13 دقیقه در هر km) و ضربان بررسی می‌شود. ماشین و دوچرخه رد می‌شود.', 'GPS, tempo (km başına 2,8–13 dk) ve nabız kontrol edilir. Araba ve bisiklet reddedilir.'],
  'fair_2_t': ['پشکنینی ڕاکردن', 'پشکنینا ڕەڤینێ', 'Run checks', 'فحص الجري', 'بررسی دویدن', 'Koşu kontrolü'],
  'fair_3_s': ['وەرزشی بێ بەرزبوونەوەی لێدانی دڵ، یان لێدانی بەرز بێ جووڵە، حیساب ناکرێت.', 'وەرزشا بێ بلندبوونا لێدانێن دلی، یان لێدانێن بلند بێ لڤین، ناهێتە حیسابکرن.', 'Workouts without a heart-rate rise, or high heart rate without movement, do not count.', 'لا يُحتسب التمرين دون ارتفاع النبض، أو النبض المرتفع دون حركة.', 'ورزش بدون بالا رفتن ضربان یا ضربان بالا بدون حرکت حساب نمی‌شود.', 'Nabız yükselmeyen antrenman veya hareketsiz yüksek nabız sayılmaz.'],
  'fair_3_t': ['دڵ و جووڵە', 'دل و لڤین', 'Heart and motion', 'القلب والحركة', 'قلب و حرکت', 'Kalp ve hareket'],
  'fair_4_s': ['کاتی هەر پەرداخێک تۆمار دەکرێت. زیاتر لە 500ml لە یەک جاردا، 1 لیتر لە کاتژمێرێکدا، یان شەوی درەنگ حیساب ناکرێت.', 'دەمێ هەر پەرداخەکێ دهێتە تۆمارکرن. زێدەتر ژ 500ml ب ئێک جار، 1 لیتر د دەمژمێرەکێ دا، یان شەڤا درەنگ ناهێتە حیسابکرن.', 'Each glass is time-stamped. Over 500 ml at once, over 1 liter an hour, or late-night logs do not count.', 'يُسجل وقت كل كوب. لا يُحتسب أكثر من 500 مل دفعة، أو لتر في الساعة، أو التسجيل ليلاً.', 'زمان هر لیوان ثبت می‌شود. بیش از 500ml یکجا، 1 لیتر در ساعت یا نیمه‌شب حساب نمی‌شود.', 'Her bardak zaman damgalı. Tek seferde 500 ml, saatte 1 litre üstü veya gece kayıtları sayılmaz.'],
  'fair_4_t': ['ئاوی ڕاستەقینە', 'ئاڤا ڕاستەقینە', 'Real water', 'ماء حقيقي', 'آب واقعی', 'Gerçek su'],
  'fair_5_s': ['ژەمەکان دەبێت 90 خولەک لێک دوور بن و کاتی داهاتوویان نەبێت.', 'دڤێت ژەم 90 خولەکان ژێک دوور بن و دەمێ پاشەڕۆژێ نەبیت.', 'Meals must be 90 minutes apart and not in the future.', 'يجب أن تفصل الوجبات 90 دقيقة وألا تكون في المستقبل.', 'وعده‌ها باید 90 دقیقه فاصله داشته باشند و زمان آینده نداشته باشند.', 'Öğünler 90 dk arayla olmalı ve gelecekte olmamalı.'],
  'fair_5_t': ['ژەمی ڕاستەقینە', 'ژەمێن ڕاستەقینە', 'Real meals', 'وجبات حقيقية', 'وعده واقعی', 'Gerçek öğünler'],
  'fair_6_s': ['گۆڕینی کاتی ئامێر دەدۆزرێتەوە و سکە زیاد ناکرێت.', 'گوهۆڕینا دەمێ ئامیری دهێتە دیتن و پارە زێدە نابن.', 'Changing the device clock is detected and no coins are added.', 'يتم اكتشاف تغيير ساعة الجهاز ولا تُضاف عملات.', 'تغییر ساعت دستگاه شناسایی می‌شود و سکه اضافه نمی‌شود.', 'Cihaz saatinin değiştirilmesi tespit edilir, coin eklenmez.'],
  'fair_6_t': ['پاراستنی کات', 'پاراستنا دەمی', 'Clock protection', 'حماية الوقت', 'محافظت از زمان', 'Saat koruması'],
  'fair_7_s': ['داتای پاشەکەوتکراو واژۆ دەکرێت؛ هەر دەستکارییەک سکە و خاڵ سفر دەکاتەوە.', 'داتایێن پاراستی دهێنە واژۆکرن؛ هەر دەستکاریەک پارە و خالان سفر دکەت.', 'Saved data is signed; any tampering resets coins and points.', 'البيانات المحفوظة موقّعة؛ أي تلاعب يُصفّر العملات والنقاط.', 'داده ذخیره‌شده امضا می‌شود؛ هر دستکاری سکه و امتیاز را صفر می‌کند.', 'Kayıtlı veriler imzalıdır; her müdahale coin ve puanları sıfırlar.'],
  'fair_7_t': ['واژۆی داتا', 'واژۆیا داتایێ', 'Data signature', 'توقيع البيانات', 'امضای داده', 'Veri imzası'],
  'fair_s': ['هەموو خاڵێک پێش حیسابکردن پشتڕاست دەکرێتەوە', 'هەر خالەک بەری حیسابکرنێ دهێتە پشتڕاستکرن', 'Every point is verified before it counts', 'يتم التحقق من كل نقطة قبل احتسابها', 'هر امتیاز قبل از حساب شدن تأیید می‌شود', 'Her puan sayılmadan önce doğrulanır'],
  'fair_t': ['یاری دادپەروەرانە', 'یاریا دادپەروەر', 'Fair play', 'اللعب النظيف', 'بازی منصفانه', 'Adil oyun'],
  'founder': ['دامەزرێنەر', 'دامەزرێنەر', 'Founder', 'مؤسس', 'بنیان‌گذار', 'Kurucu'],
  'free': ['بەخۆڕایی', 'بێ بەرامبەر', 'Free', 'مجاني', 'رایگان', 'Ücretsiz'],
  'freeze': ['پاراستنی زنجیرە', 'پاراستنا زنجیرێ', 'Streak shield', 'حماية السلسلة', 'محافظ زنجیره', 'Seri kalkanı'],
  'frz_1': ['هەموو هەفتەیەک 1 دانە بەخۆڕایی (زۆرترین 2)', 'هەمی حەفتیان 1 بێ بەرامبەر (زێدەتر 2)', '1 free every week (max 2)', 'واحدة مجاناً كل أسبوع (حد أقصى 2)', 'هر هفته 1 رایگان (حداکثر 2)', 'Her hafta 1 ücretsiz (en fazla 2)'],
  'frz_2': ['ئۆتۆماتیک بەکاردێت کاتێک ڕۆژێکت لەدەست دەچێت', 'ب خۆ دهێتە بکارئینان دەمێ ڕۆژەک ژ دەست دچیت', 'Used automatically when you miss a day', 'تُستخدم تلقائياً عند تفويت يوم', 'هنگام از دست دادن روز خودکار استفاده می‌شود', 'Bir gün kaçırınca otomatik kullanılır'],
  'frz_buy': ['کڕین بە 30 سکە', 'کڕین ب 30 پارە', 'Buy for 30 coins', 'شراء بـ30 عملة', 'خرید با 30 سکه', '30 coin ile al'],
  'frz_full': ['پڕە (2 / 2)', 'یا تژییە (2 / 2)', 'Full (2 / 2)', 'ممتلئ (2 / 2)', 'پر است (2 / 2)', 'Dolu (2 / 2)'],
  'frz_ok': ['پاراستنێک زیاد کرا', 'پاراستنەک هاتە زێدەکرن', 'Shield added', 'تمت إضافة حماية', 'محافظ اضافه شد', 'Kalkan eklendi'],
  'frz_s': ['ئەگەر ڕۆژێک چالاک نەبوویت، زنجیرەکەت دەپارێزێت', 'ئەگەر ڕۆژەکێ چالاک نەبووی، زنجیرا تە دپارێزیت', 'Protects your streak if you miss a day', 'يحمي سلسلتك إذا فاتك يوم', 'اگر روزی را از دست بدهی، زنجیره‌ات را حفظ می‌کند', 'Bir gün kaçırırsan serini korur'],
  'g_sub': ['4 هەنگاوی کورت · کەمتر لە 1 خولەک', '4 گاڤێن کورت · کێمتر ژ 1 خولەکێ', '4 short steps · under 1 minute', '4 خطوات قصيرة · أقل من دقيقة', '4 مرحله کوتاه · کمتر از 1 دقیقه', '4 kısa adım · 1 dakikadan az'],
  'g_title': ['بەشداربوون لە VEX Arena', 'بەشداربوون د VEX Arena دا', 'Join VEX Arena', 'الانضمام إلى VEX Arena', 'پیوستن به VEX Arena', 'VEX Arena\'ya katıl'],
  'go_sec': ['بڕۆ بۆ {0}', 'هەرە بۆ {0}', 'Go to {0}', 'اذهب إلى {0}', 'برو به {0}', '{0} bölümüne git'],
  'goal_done': ['ئامانجت پێکا!', 'تە ئارمانج پێکا!', 'Goal reached!', 'حققت الهدف!', 'به هدف رسیدی!', 'Hedefe ulaştın!'],
  'goal_k': ['ئامانجی ئەمڕۆ', 'ئارمانجا ئەڤرۆ', 'Today\'s goal', 'هدف اليوم', 'هدف امروز', 'Bugünün hedefi'],
  'goal_more': ['هەر خاڵێکی زیاتر پلەکەت بەرز دەکاتەوە', 'هەر خالەکا زێدە پلا تە بلند دکەت', 'Every extra point lifts your rank', 'كل نقطة إضافية ترفع ترتيبك', 'هر امتیاز اضافه رتبه‌ات را بالا می‌برد', 'Her ekstra puan sıranı yükseltir'],
  'hdr_live': ['وەرزی {0} · {1} ڕۆژ ماوە', 'وەرزێ {0} · {1} ڕۆژ مایە', 'Season {0} · {1} days left', 'الموسم {0} · بقي {1} يوماً', 'فصل {0} · {1} روز مانده', 'Sezon {0} · {1} gün kaldı'],
  'hdr_pre': ['وەرزی {0} · {1} ڕۆژی تر دەستپێدەکات', 'وەرزێ {0} · پشتی {1} ڕۆژان دەستپێدکەت', 'Season {0} · starts in {1} days', 'الموسم {0} · يبدأ بعد {1} يوم', 'فصل {0} · {1} روز دیگر شروع می‌شود', 'Sezon {0} · {1} gün sonra başlıyor'],
  'hero_pre': ['وەرزی {0} بەم زووانە', 'وەرزێ {0} ب زوویی', 'Season {0} is coming', 'الموسم {0} قريباً', 'فصل {0} به‌زودی', 'Sezon {0} yakında'],
  'hero_s': ['تەندروست بە، خاڵ کۆبکەوە، خەڵات ببە', 'ساخلەم بە، خالان کۆم بکە، خەڵاتان ببە', 'Stay healthy, earn points, win prizes', 'كن بصحة جيدة، اجمع النقاط، اربح الجوائز', 'سالم بمان، امتیاز بگیر، جایزه ببر', 'Sağlıklı kal, puan topla, ödül kazan'],
  'hero_t': ['پێشبڕکێ دەستیپێکرد!', 'پێشبڕکێ دەستپێکر!', 'The competition is on!', 'انطلقت المنافسة!', 'رقابت شروع شد!', 'Yarışma başladı!'],
  'hint_calm': ['ئاماژە: ئارامی و کەمی سترێس', 'ئاماژە: ئارامی و کێمیا سترێسێ', 'Hint: calm and low stress', 'تلميح: الهدوء وقلة التوتر', 'راهنما: آرامش و استرس کم', 'İpucu: sakinlik ve düşük stres'],
  'hint_food': ['ئاماژە: ژەمە ڕێکخراوەکانت', 'ئاماژە: ژەمێن تە یێن ڕێکخستی', 'Hint: your regular meals', 'تلميح: وجباتك المنتظمة', 'راهنما: وعده‌های منظم', 'İpucu: düzenli öğünlerin'],
  'hint_gym': ['ئاماژە: ماسولکەکانت ئەمڕۆ گرنگن', 'ئاماژە: ماسولکێن تە ئەڤرۆ گرنگن', 'Hint: muscles matter today', 'تلميح: العضلات مهمة اليوم', 'راهنما: امروز عضلات مهم‌اند', 'İpucu: bugün kaslar önemli'],
  'hint_heart': ['ئاماژە: کاتی چالاکی دڵت', 'ئاماژە: دەمێ چالاکیا دلی', 'Hint: your active heart minutes', 'تلميح: دقائق نشاط القلب', 'راهنما: دقایق فعالیت قلب', 'İpucu: aktif kalp dakikaların'],
  'hint_o2': ['ئاماژە: هەناسەی قووڵ', 'ئاماژە: بێهنا کویر', 'Hint: deep breathing', 'تلميح: التنفس العميق', 'راهنما: تنفس عمیق', 'İpucu: derin nefes'],
  'hint_rec': ['ئاماژە: پشوودان و چاکبوونەوە', 'ئاماژە: بێهنڤەدان و باشبوون', 'Hint: rest and recovery', 'تلميح: الراحة والتعافي', 'راهنما: استراحت و ریکاوری', 'İpucu: dinlenme ve toparlanma'],
  'hint_run': ['ئاماژە: خێرایی دڵت بەرز بکەرەوە بە ڕاکردن', 'ئاماژە: ب ڕەڤینێ لێدانێن دلی بلند بکە', 'Hint: get your heart racing with a run', 'تلميح: ارفع نبضك بالجري', 'راهنما: با دویدن ضربانت را بالا ببر', 'İpucu: koşarak nabzını yükselt'],
  'hint_sleep': ['ئاماژە: شەوێکی باش خەڵات دەکرێت', 'ئاماژە: شەڤەکا باش دێ خەڵات بیت', 'Hint: a good night is rewarded', 'تلميح: الليلة الجيدة تُكافأ', 'راهنما: یک شب خوب پاداش دارد', 'İpucu: iyi bir gece ödüllendirilir'],
  'hint_walk': ['ئاماژە: هەنگاوەکانت گرنگن', 'ئاماژە: پێنگاڤێن تە گرنگن', 'Hint: your steps matter', 'تلميح: خطواتك مهمة', 'راهنما: قدم‌هایت مهم است', 'İpucu: adımların önemli'],
  'hint_water': ['ئاماژە: لە ڕۆژدا بە ڕێکی بخۆرەوە', 'ئاماژە: د ڕۆژێ دا ب ڕێکی ڤەخۆ', 'Hint: drink steadily through the day', 'تلميح: اشرب بانتظام طوال اليوم', 'راهنما: در طول روز منظم بنوش', 'İpucu: gün boyunca düzenli iç'],
  'hist_empty': ['هێشتا هیچ جووڵەیەک نییە', 'هێشتا چ لڤین نینن', 'No activity yet', 'لا توجد حركة بعد', 'هنوز تراکنشی نیست', 'Henüz hareket yok'],
  'hist_t': ['مێژوو', 'دیرۆک', 'History', 'السجل', 'تاریخچه', 'Geçmiş'],
  'how_calm': ['سترێسی 30 یان کەمتر = خاڵی تەواو. هەناسەدانی قووڵ یارمەتی دەدات.', 'سترێسا 30 یان کێمتر = خالێن تەمام. بێهنا کویر هاریکار دبیت.', 'Stress of 30 or less = full points. Deep breathing helps.', 'توتر 30 أو أقل = النقاط كاملة. التنفس العميق يساعد.', 'استرس 30 یا کمتر = امتیاز کامل. تنفس عمیق کمک می‌کند.', '30 veya altı stres = tam puan. Derin nefes yardımcı olur.'],
  'how_food': ['3 ژەم لە بەشی خۆراک تۆمار بکە.', '3 ژەمان ل پشکا خوارنێ تۆمار بکە.', 'Log 3 meals in the Food section.', 'سجّل 3 وجبات في قسم الطعام.', '3 وعده در بخش غذا ثبت کن.', 'Yemek bölümüne 3 öğün kaydet.'],
  'how_gym': ['45 خولەک وەرزش = خاڵی تەواو.', '45 خولەک وەرزش = خالێن تەمام.', '45 minutes of workout = full points.', '45 دقيقة تمرين = النقاط كاملة.', '45 دقیقه ورزش = امتیاز کامل.', '45 dk antrenman = tam puan.'],
  'how_heart': ['30 خولەک چالاکی دڵ = خاڵی تەواو.', '30 خولەک چالاکیا دلی = خالێن تەمام.', '30 active heart minutes = full points.', '30 دقيقة نشاط قلب = النقاط كاملة.', '30 دقیقه فعالیت قلب = امتیاز کامل.', '30 aktif kalp dakikası = tam puan.'],
  'how_o2': ['SpO₂ ی 95% یان زیاتر = خاڵی تەواو.', 'SpO₂ یا 95% یان زێدەتر = خالێن تەمام.', 'SpO₂ of 95% or more = full points.', 'SpO₂ بنسبة 95% أو أكثر = النقاط كاملة.', 'SpO₂ برابر 95% یا بیشتر = امتیاز کامل.', '%95 veya üzeri SpO₂ = tam puan.'],
  'how_rec': ['HRV ی 70 یان زیاتر = خاڵی تەواو. خەوی باش یارمەتی دەدات.', 'HRV یا 70 یان زێدەتر = خالێن تەمام. نڤستنا باش هاریکار دبیت.', 'HRV of 70 or more = full points. Good sleep helps.', 'HRV بقيمة 70 أو أكثر = النقاط كاملة. النوم الجيد يساعد.', 'HRV برابر 70 یا بیشتر = امتیاز کامل. خواب خوب کمک می‌کند.', '70 veya üzeri HRV = tam puan. İyi uyku yardımcı olur.'],
  'how_run': ['30 خولەک ڕاکردن بە GPS = خاڵی تەواو.', '30 خولەک ڕەڤین ب GPS = خالێن تەمام.', '30 minutes of GPS running = full points.', '30 دقيقة جري مع GPS = النقاط كاملة.', '30 دقیقه دویدن با GPS = امتیاز کامل.', 'GPS ile 30 dk koşu = tam puan.'],
  'how_sleep': ['8 کاتژمێر خەو بە Band = خاڵی تەواو.', '8 دەمژمێر نڤستن ب Band = خالێن تەمام.', '8 hours of sleep with the Band = full points.', '8 ساعات نوم مع Band = النقاط كاملة.', '8 ساعت خواب با Band = امتیاز کامل.', 'Band ile 8 saat uyku = tam puan.'],
  'how_t': ['چۆن خاڵی زیاتر وەربگرم؟', 'چاوا خالێن زێدەتر وەرگرم؟', 'How to earn more?', 'كيف أحصل على المزيد؟', 'چطور امتیاز بیشتری بگیرم؟', 'Nasıl daha fazla kazanırım?'],
  'how_walk': ['10,000 هەنگاو = خاڵی تەواو.', '10,000 پێنگاڤ = خالێن تەمام.', '10,000 steps = full points.', '10,000 خطوة = النقاط كاملة.', '10,000 قدم = امتیاز کامل.', '10.000 adım = tam puan.'],
  'how_water': ['ئامانجی ئاوەکەت پڕبکەوە و لە ماوەی ڕۆژدا دابەشی بکە.', 'ئارمانجا ئاڤێ تەمام بکە و د ڕۆژێ دا بەلاڤ بکە.', 'Hit your water goal and spread it through the day.', 'حقق هدف الماء ووزعه على اليوم.', 'به هدف آب برس و در طول روز پخش کن.', 'Su hedefini tamamla ve güne yay.'],
  'in_use': ['بەکاردێت', 'دهێتە بکارئینان', 'In use', 'مستخدم', 'در حال استفاده', 'Kullanılıyor'],
  'join': ['بەشداربوون', 'بەشداربوون', 'Join', 'انضمام', 'پیوستن', 'Katıl'],
  'joined': ['بەشداربوون', 'بەشداربوون', 'Joined', 'الانضمام', 'پیوستن', 'Katılım'],
  'joined_day': ['بەشداربوو لە ڕۆژی {0}', 'بەشداربوو ل ڕۆژا {0}', 'Joined day {0}', 'انضم في اليوم {0}', 'پیوستن در روز {0}', '{0}. gün katıldı'],
  'league': ['لیگ', 'لیگ', 'League', 'الدرجة', 'لیگ', 'Lig'],
  'league_div': ['لیگ', 'لیگ', 'Division', 'الدوري', 'لیگ', 'Lig'],
  'level': ['ئاست', 'ئاست', 'Level', 'المستوى', 'سطح', 'Seviye'],
  'lg_bronze': ['بڕۆنز', 'بڕۆنز', 'Bronze', 'برونزي', 'برنز', 'Bronz'],
  'lg_dia': ['ئەڵماس', 'ئەلماس', 'Diamond', 'ماسي', 'الماس', 'Elmas'],
  'lg_gold': ['زێڕ', 'زێڕ', 'Gold', 'ذهبي', 'طلا', 'Altın'],
  'lg_legend': ['ئەفسانە', 'ئەفسانە', 'Legend', 'أسطورة', 'افسانه', 'Efsane'],
  'lg_plat': ['پلاتین', 'پلاتین', 'Platinum', 'بلاتيني', 'پلاتین', 'Platin'],
  'lg_silver': ['زیو', 'زیڤ', 'Silver', 'فضي', 'نقره', 'Gümüş'],
  'live': ['ڕاستەوخۆ', 'ڕاستەوخۆ', 'LIVE', 'مباشر', 'زنده', 'CANLI'],
  'logout': ['چوونەدەرەوە لە Arena', 'دەرکەفتن ژ Arena', 'Leave Arena', 'الخروج من Arena', 'خروج از Arena', 'Arena\'dan çık'],
  'logout_s': ['هەموو داتاکانی Arena لەسەر ئەم ئامێرە دەسڕێنەوە (خاڵ، سکە، کارەکتەر).', 'هەمی داتایێن Arena ل سەر ڤی ئامیری دێ هێنە ژێبرن (خال، پارە، کارەکتەر).', 'All Arena data on this device will be erased (points, coins, character).', 'سيتم حذف كل بيانات Arena على هذا الجهاز (النقاط، العملات، الشخصية).', 'همه داده‌های Arena روی این دستگاه پاک می‌شود (امتیاز، سکه، کاراکتر).', 'Bu cihazdaki tüm Arena verileri silinecek (puan, coin, karakter).'],
  'logout_yes': ['بەڵێ، دەربچۆ', 'بەلێ، دەرکەڤە', 'Yes, leave', 'نعم، اخرج', 'بله، خروج', 'Evet, çık'],
  'm_day': ['ڕۆژی {0} / 30', 'ڕۆژا {0} / 30', 'Day {0} / 30', 'اليوم {0} / 30', 'روز {0} / 30', 'Gün {0} / 30'],
  'm_players': ['{0} بەشداربوو', '{0} بەشداربوو', '{0} players', '{0} مشارك', '{0} شرکت‌کننده', '{0} oyuncu'],
  'm_prizes': ['6 خەڵاتی گەورە', '6 خەڵاتێن مەزن', '6 grand prizes', '6 جوائز كبرى', '6 جایزه بزرگ', '6 büyük ödül'],
  'ms_calm': ['{0} خاڵ لە ئارامیدا', '{0} خال د ئارامیێ دا', '{0} pts from calm', '{0} نقطة من الهدوء', '{0} امتیاز از آرامش', 'Sakinlikten {0} puan'],
  'ms_food': ['{0} خاڵ لە خۆراکدا', '{0} خال د خوارنێ دا', '{0} pts from food', '{0} نقطة من الطعام', '{0} امتیاز از غذا', 'Yemekten {0} puan'],
  'ms_gym': ['{0} خاڵ لە جیمدا', '{0} خال د جیمێ دا', '{0} pts from gym', '{0} نقطة من النادي', '{0} امتیاز از باشگاه', 'Spor salonundan {0} puan'],
  'ms_heart': ['{0} خاڵ لە دڵدا', '{0} خال د دلی دا', '{0} pts from heart', '{0} نقطة من القلب', '{0} امتیاز از قلب', 'Kalpten {0} puan'],
  'ms_o2': ['{0} خاڵ لە ئۆکسجیندا', '{0} خال د ئۆکسجینێ دا', '{0} pts from oxygen', '{0} نقطة من الأكسجين', '{0} امتیاز از اکسیژن', 'Oksijenden {0} puan'],
  'ms_rec': ['{0} خاڵ لە چاکبوونەوەدا', '{0} خال د باشبوونێ دا', '{0} pts from recovery', '{0} نقطة من التعافي', '{0} امتیاز از ریکاوری', 'Toparlanmadan {0} puan'],
  'ms_run': ['{0} خاڵ لە ڕاکردندا', '{0} خال د ڕەڤینێ دا', '{0} pts from running', '{0} نقطة من الجري', '{0} امتیاز از دویدن', 'Koşudan {0} puan'],
  'ms_sleep': ['{0} خاڵ لە خەودا', '{0} خال د نڤستنێ دا', '{0} pts from sleep', '{0} نقطة من النوم', '{0} امتیاز از خواب', 'Uykudan {0} puan'],
  'ms_t': ['ئەرکەکانی ئەمڕۆ', 'ئەرکێن ئەڤرۆ', 'Today\'s missions', 'مهام اليوم', 'مأموریت‌های امروز', 'Bugünün görevleri'],
  'ms_walk': ['{0} خاڵ لە پیاسەدا', '{0} خال د پیاسێ دا', '{0} pts from walking', '{0} نقطة من المشي', '{0} امتیاز از پیاده‌روی', 'Yürüyüşten {0} puan'],
  'ms_water': ['{0} خاڵ لە ئاودا', '{0} خال د ئاڤێ دا', '{0} pts from water', '{0} نقطة من الماء', '{0} امتیاز از آب', 'Sudan {0} puan'],
  'n_of': ['⁦{0} / {1}⁩', '⁦{0} / {1}⁩', '{0} / {1}', '⁦{0} / {1}⁩', '⁦{0} / {1}⁩', '{0} / {1}'],
  'n_of_3': ['{0} لە 3', '{0} ژ 3', '{0} of 3', '{0} من 3', '{0} از 3', '{0} / 3'],
  'next': ['دواتر', 'پاشی', 'Next', 'التالي', 'بعدی', 'İleri'],
  'no_coins': ['سکەت بەس نییە', 'پارێن تە بەس نینن', 'Not enough coins', 'العملات غير كافية', 'سکه کافی نیست', 'Yeterli coin yok'],
  'no_coins_s': ['{0} سکەی ترت پێویستە', '{0} پارێن دی پێدڤینە', 'You need {0} more coins', 'تحتاج {0} عملة إضافية', '{0} سکه دیگر لازم است', '{0} coin daha gerekli'],
  'none': ['نییە', 'نینە', 'None', 'لا يوجد', 'ندارد', 'Yok'],
  'not_yet': ['هێشتا نییە', 'هێشتا نینە', 'Not yet', 'ليس بعد', 'هنوز نه', 'Henüz yok'],
  'now': ['ئێستا', 'نوکە', 'Now', 'الآن', 'اکنون', 'Şimdi'],
  'ny_s': ['ئەم بەشە ئەمڕۆ هێشتا هیچ داتایەکی نییە. چالاکییەکە بکە و ئۆتۆماتیک لێرە دەردەکەوێت.', 'ئەڤ پشکە ئەڤرۆ هێشتا چ داتا نینن. چالاکیێ بکە و ب خۆ دێ ل ڤێرێ دیار بیت.', 'No data for this category today yet. Do the activity and it will appear here automatically.', 'لا توجد بيانات لهذا القسم اليوم بعد. قم بالنشاط وسيظهر هنا تلقائياً.', 'هنوز داده‌ای برای این بخش ثبت نشده. فعالیت را انجام دهید تا خودکار اینجا نمایش داده شود.', 'Bu kategori için bugün henüz veri yok. Aktiviteyi yap, otomatik olarak burada görünür.'],
  'of_n': ['لە {0}', 'ژ {0}', 'of {0}', 'من {0}', 'از {0}', '/ {0}'],
  'owned': ['هی تۆیە', 'یێ تەیە', 'Owned', 'مملوك', 'داری', 'Sende'],
  'partial': ['بەشێکی', 'پشکەک', 'Partial', 'جزئي', 'جزئی', 'Kısmi'],
  'pb_s': ['بێ Band: پیاسە، ڕاکردن، جیم، خۆراک و ئاو حیساب دەکرێن (زۆرترین 200 خاڵ لە ڕۆژێکدا). هەر کاتێک Band ـت پەیوەست کرد، ئۆتۆماتیک دەچیتە لیگی Band.', 'بێ Band: پیاسە، ڕەڤین، جیم، خوارن و ئاڤ دهێنە حیسابکرن (زێدەتر 200 خال د ڕۆژەکێ دا). هەر دەمەکێ Band گرێدای، ب خۆ دێ چییە لیگا Band.', 'Without a Band: walking, running, gym, food and water count (max 200 pts a day). Connect a Band any time and you move to the Band league automatically.', 'بدون Band: يُحتسب المشي والجري والنادي والطعام والماء (حتى 200 نقطة يومياً). عند ربط Band تنتقل تلقائياً إلى دوري Band.', 'بدون Band: پیاده‌روی، دویدن، باشگاه، غذا و آب حساب می‌شود (حداکثر 200 امتیاز در روز). هر وقت Band وصل کنید، خودکار به لیگ Band می‌روید.', 'Band olmadan: yürüyüş, koşu, spor salonu, yemek ve su sayılır (günde en fazla 200 puan). Band bağladığında otomatik olarak Band ligine geçersin.'],
  'pb_t': ['تۆ لە لیگی مۆبایلیت', 'تو ل لیگا مۆبایلێ دای', 'You are in the Phone league', 'أنت في دوري الهاتف', 'شما در لیگ موبایل هستید', 'Telefon ligindesin'],
  'plus_pts': ['+{0} خاڵ', '+{0} خال', '+{0} pts', '+{0} نقطة', '+{0} امتیاز', '+{0} puan'],
  'pts': ['خاڵ', 'خال', 'pts', 'نقطة', 'امتیاز', 'puan'],
  'pw_confirm': ['دڵنیام: {0}', 'پشتڕاستم: {0}', 'Lock in: {0}', 'تأكيد: {0}', 'تأیید: {0}', 'Onayla: {0}'],
  'pw_go': ['پێشبینی بکە · +10 سکە', 'پێشبینی بکە · +10 پارە', 'Guess · +10 coins', 'خمّن · +10 عملات', 'حدس بزن · +10 سکه', 'Tahmin et · +10 coin'],
  'pw_mine': ['پێشبینیی تۆ: {0}', 'پێشبینیا تە: {0}', 'Your guess: {0}', 'تخمينك: {0}', 'حدس شما: {0}', 'Tahminin: {0}'],
  'pw_pick': ['بەشێک هەڵبژێرە', 'پشکەکێ هەلبژێرە', 'Pick a category', 'اختر قسماً', 'یک بخش انتخاب کن', 'Bir kategori seç'],
  'pw_rule': ['ئەگەر ڕاست بێت: +10 سکە و +50 خاڵی وەرز', 'ئەگەر دروست بیت: +10 پارە و +50 خالێن وەرزی', 'If correct: +10 coins and +50 season points', 'إذا كان صحيحاً: +10 عملات و+50 نقطة', 'اگر درست باشد: +10 سکه و +50 امتیاز فصل', 'Doğruysa: +10 coin ve +50 sezon puanı'],
  'pw_s': ['یەک بەش ئەمڕۆ ×3 خاڵ دەدات و یەکێکی تر ×1.5. سبەینێ کاتژمێر 6ی بەیانی ئاشکرا دەکرێت.', 'ئێک پشک ئەڤرۆ ×3 خالان ددەت و ئێکا دی ×1.5. سوبەهی دەمژمێر 6 یێ سپێدێ دێ ئاشکرا بیت.', 'One category gives ×3 points today and another ×1.5. Revealed tomorrow at 6:00 AM.', 'قسم واحد يمنح ×3 نقاط اليوم وآخر ×1.5. يُكشف غداً الساعة 6 صباحاً.', 'امروز یک بخش ×3 امتیاز می‌دهد و یکی دیگر ×1.5. فردا ساعت 6 صبح فاش می‌شود.', 'Bugün bir kategori ×3, diğeri ×1.5 puan verir. Yarın sabah 6:00\'da açıklanır.'],
  'pw_saved': ['پێشبینییەکەت پاشەکەوت کرا', 'پێشبینیا تە هاتە پاراستن', 'Your guess is locked', 'تم حفظ تخمينك', 'حدس شما ثبت شد', 'Tahminin kaydedildi'],
  'pw_t': ['هێزی نهێنی ئەمڕۆ', 'هێزا نهێنی یا ئەڤرۆ', 'Today\'s secret power', 'القوة السرية اليوم', 'قدرت مخفی امروز', 'Bugünün gizli gücü'],
  'pw_when': ['سبەینێ کاتژمێر 6ی بەیانی ئەنجام', 'سوبەهی دەمژمێر 6 ئەنجام', 'Result tomorrow at 6:00 AM', 'النتيجة غداً الساعة 6 صباحاً', 'نتیجه فردا ساعت 6 صبح', 'Sonuç yarın 06:00\'da'],
  'pz_100': ['100,000 دینار', '100,000 دینار', '100,000 IQD', '100,000 دينار', '100,000 دینار', '100.000 IQD'],
  'pz_150': ['150,000 دینار', '150,000 دینار', '150,000 IQD', '150,000 دينار', '150,000 دینار', '150.000 IQD'],
  'pz_1m': ['1,000,000 دینار', '1,000,000 دینار', '1,000,000 IQD', '1,000,000 دينار', '1,000,000 دینار', '1.000.000 IQD'],
  'pz_250': ['250,000 دینار', '250,000 دینار', '250,000 IQD', '250,000 دينار', '250,000 دینار', '250.000 IQD'],
  'pz_big': ['خەڵاتی گەورە', 'خەڵاتێن مەزن', 'Grand prizes', 'جوائز كبرى', 'جوایز بزرگ', 'Büyük ödüller'],
  'pz_c1': ['کۆی خاڵەکانی وەرز براوە دیاری دەکات', 'کۆما خالێن وەرزی سەرکەفتی دیار دکەت', 'Total season points decide the winners', 'مجموع نقاط الموسم يحدد الفائزين', 'مجموع امتیاز فصل برندگان را تعیین می‌کند', 'Kazananları sezon toplam puanı belirler'],
  'pz_c2': ['لانیکەم 25 ڕۆژی چالاک ({0}+ خاڵ)', 'کێمتر 25 ڕۆژێن چالاک ({0}+ خال)', 'At least 25 active days ({0}+ pts)', '25 يوماً نشطاً على الأقل ({0}+ نقطة)', 'حداقل 25 روز فعال ({0}+ امتیاز)', 'En az 25 aktif gün ({0}+ puan)'],
  'pz_c3': ['هەموو داتاکان دەبێت پشتڕاستکراوە بن (دژی فێڵ)', 'دڤێت هەمی داتا یێن پشتڕاستکری بن (دژی فێلێ)', 'All data must pass verification (anti-cheat)', 'يجب أن تجتاز كل البيانات التحقق (مكافحة الغش)', 'همه داده‌ها باید تأیید شوند (ضد تقلب)', 'Tüm veriler doğrulamadan geçmeli (hile karşıtı)'],
  'pz_c4': ['ناو و ژمارەی تەلەفۆن دەبێت ڕاست بن', 'ناڤ و ژمارا تەلەفۆنێ دڤێت دروست بن', 'Name and phone number must be real', 'يجب أن يكون الاسم والرقم حقيقيين', 'نام و شماره تلفن باید واقعی باشد', 'Ad ve telefon numarası gerçek olmalı'],
  'pz_car': ['ئۆتۆمبێل', 'ترومبێل', 'A car', 'سيارة', 'خودرو', 'Araba'],
  'pz_guar_b': ['هەر کەسێک 25 ڕۆژی چالاک تەواو بکات بەرگێکی تایبەتی کارت و نازناوی «پاڵەوانی وەرز» وەردەگرێت', 'هەر کەسەکێ 25 ڕۆژێن چالاک تەمام بکەت دێ بەرگەکێ تایبەت یێ کارتێ و نازناڤێ «پاڵەوانێ وەرزی» وەرگریت', 'Anyone completing 25 active days gets a special card skin and the "Season Hero" title', 'كل من يكمل 25 يوماً نشطاً يحصل على تصميم بطاقة خاص ولقب «بطل الموسم»', 'هر کس 25 روز فعال کامل کند، طرح ویژه کارت و لقب «قهرمان فصل» می‌گیرد', '25 aktif günü tamamlayan herkes özel kart teması ve "Sezon Kahramanı" unvanı alır'],
  'pz_guar_p': ['هەر کەسێک 25 ڕۆژی چالاک تەواو بکات نازناوی «پاڵەوانی وەرز» و 100 سکە وەردەگرێت', 'هەر کەسەکێ 25 ڕۆژێن چالاک تەمام بکەت دێ نازناڤێ «پاڵەوانێ وەرزی» و 100 پارە وەرگریت', 'Anyone completing 25 active days gets the "Season Hero" title and 100 coins', 'كل من يكمل 25 يوماً نشطاً يحصل على لقب «بطل الموسم» و100 عملة', 'هر کس 25 روز فعال کامل کند، لقب «قهرمان فصل» و 100 سکه می‌گیرد', '25 aktif günü tamamlayan herkes "Sezon Kahramanı" unvanı ve 100 coin alır'],
  'pz_guar_t': ['خەڵاتی دڵنیا', 'خەڵاتێ مسۆگەر', 'Guaranteed reward', 'مكافأة مضمونة', 'جایزه تضمینی', 'Garantili ödül'],
  'pz_iphone': ['iPhone 17 Pro', 'iPhone 17 Pro', 'iPhone 17 Pro', 'iPhone 17 Pro', 'iPhone 17 Pro', 'iPhone 17 Pro'],
  'pz_norm': ['خەڵاتی پارە', 'خەڵاتێن پارەی', 'Cash prizes', 'جوائز نقدية', 'جوایز نقدی', 'Nakit ödüller'],
  'pz_other': ['بینینی خەڵاتەکانی {0}', 'دیتنا خەڵاتێن {0}', 'See {0} prizes', 'عرض جوائز {0}', 'مشاهده جوایز {0}', '{0} ödüllerini gör'],
  'pz_rule': ['مەرج: 25 ڕۆژی چالاک ({0}+ خاڵ لە ڕۆژێکدا)', 'مەرج: 25 ڕۆژێن چالاک ({0}+ خال د ڕۆژەکێ دا)', 'Condition: 25 active days ({0}+ pts a day)', 'الشرط: 25 يوماً نشطاً ({0}+ نقطة يومياً)', 'شرط: 25 روز فعال ({0}+ امتیاز در روز)', 'Şart: 25 aktif gün (günde {0}+ puan)'],
  'pz_sheet_s': ['وەرزی {0} · 30 ڕۆژ', 'وەرزێ {0} · 30 ڕۆژ', 'Season {0} · 30 days', 'الموسم {0} · 30 يوماً', 'فصل {0} · 30 روز', 'Sezon {0} · 30 gün'],
  'pz_t': ['خەڵاتەکانی {0}', 'خەڵاتێن {0}', '{0} prizes', 'جوائز {0}', 'جوایز {0}', '{0} ödülleri'],
  'pz_week_s': ['هەموو هەفتەیەک: یەکەم 50، دووەم 30، سێیەم 20، تا 10ی یەکەم 15 سکە', 'هەمی حەفتیان: ئێکێ 50، دووێ 30، سێیێ 20، هەتا 10 یێن ئێکێ 15 پارە', 'Every week: 1st 50, 2nd 30, 3rd 20, top 10 get 15 coins', 'كل أسبوع: الأول 50، الثاني 30، الثالث 20، العشرة الأوائل 15 عملة', 'هر هفته: اول 50، دوم 30، سوم 20، تا 10 نفر اول 15 سکه', 'Her hafta: 1. 50, 2. 30, 3. 20, ilk 10 15 coin'],
  'pz_week_t': ['پاڵەوانی هەفتە', 'پاڵەوانێ حەفتیێ', 'Weekly champion', 'بطل الأسبوع', 'قهرمان هفته', 'Haftanın şampiyonu'],
  'r_18': ['براوەی ژێر 18 ساڵ خەڵاتەکەی بە دایک یان باوکی دەدرێت.', 'سەرکەفتیێ ژێر 18 ساڵان خەڵاتا وی دێ دەنە دایک یان بابی.', 'Winners under 18 receive prizes through a parent or guardian.', 'الفائز دون 18 يستلم الجائزة عبر ولي الأمر.', 'برنده زیر 18 سال جایزه را از طریق والدین دریافت می‌کند.', '18 yaş altı kazananlar ödülü veli aracılığıyla alır.'],
  'r_cheat': ['هەر فێڵێک خاڵەکان سفر دەکاتەوە و لە خەڵات دەردەکرێیت.', 'هەر فێلەک خالان سفر دکەت و تو ژ خەڵاتان دهێیە دەرێخستن.', 'Any cheating resets points and removes you from prizes.', 'أي غش يُصفّر النقاط ويحرمك من الجوائز.', 'هر تقلبی امتیازها را صفر می‌کند و از جوایز حذف می‌شوید.', 'Her türlü hile puanları sıfırlar ve ödüllerden çıkarır.'],
  'r_common': ['ئاسایی', 'ئاسایی', 'Common', 'عادي', 'معمولی', 'Sıradan'],
  'r_data': ['داتاکان لە Band و ئەپەکەوە ئۆتۆماتیک دێن؛ دەستکاری دەستی قبوڵ ناکرێت.', 'داتا ژ Band و ئەپی ب خۆ دهێن؛ دەستکاریا دەستی ناهێتە قەبووڵکرن.', 'Data comes automatically from the Band and app; manual edits are not accepted.', 'تأتي البيانات تلقائياً من Band والتطبيق؛ لا تُقبل التعديلات اليدوية.', 'داده‌ها خودکار از Band و اپ می‌آیند؛ ویرایش دستی پذیرفته نیست.', 'Veriler Band ve uygulamadan otomatik gelir; elle düzenleme kabul edilmez.'],
  'r_epic': ['داستانی', 'داستانی', 'Epic', 'ملحمي', 'حماسی', 'Epik'],
  'r_legend': ['ئەفسانەیی', 'ئەفسانەیی', 'Legendary', 'أسطوري', 'افسانه‌ای', 'Efsanevi'],
  'r_lock': ['گۆڕینی کارەکتەر لە کاتی وەرزدا داخراوە.', 'گوهۆڕینا کارەکتەری د دەمێ وەرزی دا یا گرتییە.', 'Character changes are locked during a live season.', 'تغيير الشخصية مقفل أثناء الموسم.', 'تغییر کاراکتر در طول فصل قفل است.', 'Sezon sırasında karakter değişimi kilitlidir.'],
  'r_rare': ['دەگمەن', 'کێمدیتی', 'Rare', 'نادر', 'کمیاب', 'Nadir'],
  'rank': ['پلە', 'پلە', 'Rank', 'المرتبة', 'رتبه', 'Sıra'],
  'rank_of': ['پلەی {0} لە {1}', 'پلا {0} ژ {1}', '#{0} of {1}', 'المركز {0} من {1}', 'رتبه {0} از {1}', '#{0} / {1}'],
  'reg_k': ['تۆمارکرای · وەرزی {0}', 'تۆمارکری · وەرزێ {0}', 'Registered · Season {0}', 'مسجّل · الموسم {0}', 'ثبت‌نام شده · فصل {0}', 'Kayıtlı · Sezon {0}'],
  'reg_s': ['کاتێک وەرز دەستپێدەکات، خاڵەکانت لێرە حیساب دەکرێن. ئێستا دەتوانیت ڕاهێنان بکەیت.', 'دەمێ وەرز دەستپێدکەت، خالێن تە ل ڤێرێ دێ حیسابکرن. نوکە دشێی ڕاهێنانێ بکەی.', 'When the season starts your points count here. You can practice now.', 'عند بدء الموسم تُحتسب نقاطك هنا. يمكنك التدرب الآن.', 'وقتی فصل شروع شود امتیازهایت اینجا حساب می‌شود. الان می‌توانی تمرین کنی.', 'Sezon başladığında puanların burada sayılır. Şimdi antrenman yapabilirsin.'],
  'reg_t': ['ئامادەیت، {0}!', 'تو ئامادەیی، {0}!', 'You are in, {0}!', 'أنت جاهز يا {0}!', 'آماده‌ای، {0}!', 'Hazırsın, {0}!'],
  'register': ['تۆمارکردن', 'تۆمارکرن', 'Register', 'تسجيل', 'ثبت‌نام', 'Kaydol'],
  'rejected': ['ڕەتکرایەوە', 'هاتە ڕەتکرن', 'Rejected', 'مرفوض', 'رد شد', 'Reddedildi'],
  'rival': ['{1} خاڵ بۆ تێپەڕاندنی {0}', '{1} خال بۆ دەربازکرنا {0}', '{1} pts to pass {0}', '{1} نقطة لتجاوز {0}', '{1} امتیاز تا رد شدن از {0}', '{0} adlı oyuncuyu geçmek için {1} puan'],
  'rival_top': ['تۆ یەکەمیت! پلەکەت بپارێزە', 'تو ئێکێ یی! پلا خۆ بپارێزە', 'You are first! Hold your spot', 'أنت الأول! حافظ على مركزك', 'نفر اولی! جایگاهت را حفظ کن', 'Birincisin! Yerini koru'],
  'rk_empty': ['هێشتا کەس لێرە نییە', 'هێشتا کەس ل ڤێرێ نینە', 'No one here yet', 'لا أحد هنا بعد', 'هنوز کسی اینجا نیست', 'Henüz kimse yok'],
  'rk_me_gap': ['{0} خاڵ بۆ گەیشتن بە 3ی یەکەم', '{0} خال بۆ گەهشتنا 3 یێن ئێکێ', '{0} pts to reach the top 3', '{0} نقطة للوصول إلى الثلاثة الأوائل', '{0} امتیاز تا رسیدن به 3 نفر اول', 'İlk 3\'e girmek için {0} puan'],
  'rk_me_top': ['تۆ لە پلەی {0}ی! خەڵاتەکەت بپارێزە', 'تو ل پلا {0} یی! خەڵاتا خۆ بپارێزە', 'You are #{0}! Protect your prize', 'أنت في المركز {0}! احمِ جائزتك', 'رتبه {0} هستی! جایزه‌ات را حفظ کن', '{0}. sıradasın! Ödülünü koru'],
  'rk_other_band': ['ئەم لیگە بۆ خاوەنانی VEX Band ـە. Band پەیوەست بکە بۆ ئەوەی بچیتە ناوی.', 'ئەڤ لیگە بۆ خودانێن VEX Band ـێ یە. Band گرێبدە دا بچییە تێدا.', 'This league is for VEX Band owners. Connect a Band to join it.', 'هذا الدوري لمالكي VEX Band. اربط Band للانضمام.', 'این لیگ برای دارندگان VEX Band است. برای ورود Band وصل کنید.', 'Bu lig VEX Band sahipleri içindir. Katılmak için Band bağla.'],
  'rk_other_phone': ['ئەم لیگە بۆ ئەوانەیە کە Band یان نییە.', 'ئەڤ لیگە بۆ وانە یێن Band نەی.', 'This league is for players without a Band.', 'هذا الدوري لمن لا يملكون Band.', 'این لیگ برای کسانی است که Band ندارند.', 'Bu lig Band\'i olmayan oyuncular içindir.'],
  'rk_other_t': ['تۆ ئێستا {0} دەبینیت', 'تو نوکە {0} دبینی', 'You are viewing the {0}', 'أنت تشاهد {0}', 'در حال دیدن {0} هستید', 'Şu an {0} görüyorsun'],
  'rk_pre_s': ['هەموو کەس لە 0 دەستپێدەکات. تۆمارکەرانی زوو لە کاتی یەکسانیدا پێشدەکەون.', 'هەمی کەس ژ 0 دەستپێدکەن. تۆمارکەرێن زوو د وەکهەڤیێ دا پێش دکەڤن.', 'Everyone starts from 0. Early registrants win ties.', 'الجميع يبدأ من الصفر. المسجلون مبكراً يتقدمون عند التعادل.', 'همه از 0 شروع می‌کنند. ثبت‌نام‌کنندگان زودهنگام در تساوی جلو می‌افتند.', 'Herkes 0\'dan başlar. Erken kaydolanlar eşitlikte öne geçer.'],
  'rk_pre_t': ['پلەکان لەگەڵ دەستپێکردنی وەرز دەکرێنەوە', 'پلە دگەل دەستپێکرنا وەرزی دێ ڤەبن', 'Rankings open when the season starts', 'يُفتح الترتيب مع بدء الموسم', 'رتبه‌بندی با شروع فصل باز می‌شود', 'Sıralama sezon başlayınca açılır'],
  'rk_week_s': ['پلەکانی هەفتە هەموو شەممەیەک سفر دەبنەوە · {0} ڕۆژ ماوە', 'پلێن حەفتیێ هەمی شەمبیان سفر دبن · {0} ڕۆژ مایە', 'Weekly ranks reset every Saturday · {0} days left', 'يُعاد ترتيب الأسبوع كل سبت · بقي {0} أيام', 'رتبه هفتگی هر شنبه صفر می‌شود · {0} روز مانده', 'Haftalık sıralama her cumartesi sıfırlanır · {0} gün kaldı'],
  'ru10_s': ['هەر 7 ڕۆژی چالاک بە دوای یەکدا +15 سکە. پاراستنی زنجیرە ڕۆژێکی لەدەستچوو دەپارێزێت (1 بەخۆڕایی لە هەفتەدا، زۆرترین 2). ڕۆژی بیانوو 3 جار لە وەرزدا.', 'هەر 7 ڕۆژێن چالاک ل دویڤ ئێک +15 پارە. پاراستنا زنجیرێ ڕۆژەکا ژ دەست چووی دپارێزیت (1 بێ بەرامبەر د حەفتیێ دا، زێدەتر 2). ڕۆژا بیانوو 3 جاران د وەرزی دا.', 'Every 7 active days in a row: +15 coins. A streak shield saves a missed day (1 free per week, max 2). Excuse days: 3 per season.', 'كل 7 أيام نشطة متتالية: +15 عملة. حماية السلسلة تنقذ يوماً فائتاً (واحدة مجانية أسبوعياً، حد أقصى 2). أيام العذر: 3 في الموسم.', 'هر 7 روز فعال پشت سر هم: +15 سکه. محافظ زنجیره یک روز از دست رفته را حفظ می‌کند (1 رایگان در هفته، حداکثر 2). روز معذوریت: 3 بار در فصل.', 'Art arda her 7 aktif gün: +15 coin. Seri kalkanı kaçan bir günü kurtarır (haftada 1 ücretsiz, en fazla 2). Mazeret günü: sezonda 3.'],
  'ru10_t': ['زنجیرە، پاراستن و بیانوو', 'زنجیرە، پاراستن و بیانوو', 'Streak, shield and excuse', 'السلسلة والحماية والعذر', 'زنجیره، محافظ و معذوریت', 'Seri, kalkan ve mazeret'],
  'ru11_s': ['هەموو ڕۆژێک بەشێک ×3 و یەکێکی تر ×1.5. پێشبینی بکە کامەیە؛ سبەینێ کاتژمێر 6ی بەیانی ئاشکرا دەکرێت. پێشبینیی ڕاست: +10 سکە و +50 خاڵی وەرز.', 'هەمی ڕۆژان پشکەک ×3 و ئێکا دی ×1.5. پێشبینی بکە کیژە؛ سوبەهی دەمژمێر 6 یێ سپێدێ دێ ئاشکرا بیت. پێشبینیا دروست: +10 پارە و +50 خالێن وەرزی.', 'Every day one category is ×3 and another ×1.5. Guess which; it is revealed at 6:00 AM next day. Correct guess: +10 coins and +50 season points.', 'كل يوم قسم ×3 وآخر ×1.5. خمّن أيهما؛ يُكشف الساعة 6 صباح اليوم التالي. التخمين الصحيح: +10 عملات و+50 نقطة.', 'هر روز یک بخش ×3 و دیگری ×1.5 است. حدس بزن کدام؛ فردا ساعت 6 صبح فاش می‌شود. حدس درست: +10 سکه و +50 امتیاز فصل.', 'Her gün bir kategori ×3, diğeri ×1,5. Hangisi olduğunu tahmin et; ertesi gün 06:00\'da açıklanır. Doğru tahmin: +10 coin ve +50 sezon puanı.'],
  'ru11_t': ['هێزی نهێنی', 'هێزا نهێنی', 'Secret power', 'القوة السرية', 'قدرت مخفی', 'Gizli güç'],
  'ru12_s': ['هەموو داتایەک پشتڕاست دەکرێتەوە: GPS، خێرایی، لێدانی دڵ، کاتی ئاو و ژەم، کاتی ئامێر و واژۆی داتا. هەر فێڵێک خاڵ و سکە سفر دەکاتەوە و لە خەڵات دەردەکرێیت. دەتوانیت داوای پێداچوونەوە بکەیت.', 'هەمی داتا دهێنە پشتڕاستکرن: GPS، لەز، لێدانێن دلی، دەمێ ئاڤێ و ژەمان، دەمێ ئامیری و واژۆیا داتایێ. هەر فێلەک خال و پارێ سفر دکەت و تو ژ خەڵاتان دهێیە دەرێخستن. دشێی داخوازا پێداچوونێ بکەی.', 'All data is verified: GPS, pace, heart rate, water and meal timing, device clock and a data signature. Any cheating resets points and coins and removes you from prizes. You can request a review.', 'يتم التحقق من كل البيانات: GPS والسرعة والنبض وتوقيت الماء والوجبات وساعة الجهاز وتوقيع البيانات. أي غش يُصفّر النقاط والعملات ويحرمك من الجوائز. يمكنك طلب مراجعة.', 'همه داده‌ها تأیید می‌شود: GPS، سرعت، ضربان، زمان آب و غذا، ساعت دستگاه و امضای داده. هر تقلبی امتیاز و سکه را صفر و شما را از جوایز حذف می‌کند. می‌توانید درخواست بازبینی کنید.', 'Tüm veriler doğrulanır: GPS, tempo, nabız, su ve öğün zamanları, cihaz saati ve veri imzası. Her hile puan ve coinleri sıfırlar, ödüllerden çıkarır. İnceleme isteyebilirsin.'],
  'ru12_t': ['دژی فێڵ', 'دژی فێلێ', 'Anti-cheat', 'مكافحة الغش', 'ضد تقلب', 'Hile karşıtı'],
  'ru13_s': ['لە کۆتایی وەرزدا تیمی VEX 3 جار پەیوەندی بە ژمارە تۆمارکراوەکەتەوە دەکات. ئەگەر وەڵام نەدرایەوە خەڵاتەکە دەچێت بۆ کەسی دواتر. VEX هەرگیز داوای پارە یان وشەی نهێنیت لێ ناکات.', 'د دووماهیا وەرزی دا تیما VEX دێ 3 جاران پەیوەندیێ ب ژمارا تە یا تۆمارکری کەت. ئەگەر بەرسڤ نەهاتە دان خەڵات دێ چیتە بۆ کەسێ دی. VEX چ جاران داخوازا پارەی یان پەیڤا نهێنی ژ تە ناکەت.', 'At season end the VEX team calls your registered number 3 times. If unanswered, the prize goes to the next player. VEX will never ask you for money or passwords.', 'في نهاية الموسم يتصل فريق VEX برقمك المسجل 3 مرات. إذا لم يُرد، تنتقل الجائزة للاعب التالي. لن يطلب VEX منك مالاً أو كلمات مرور أبداً.', 'در پایان فصل تیم VEX سه بار با شماره ثبت‌شده‌ات تماس می‌گیرد. اگر پاسخ ندهی، جایزه به نفر بعدی می‌رسد. VEX هرگز از شما پول یا رمز نمی‌خواهد.', 'Sezon sonunda VEX ekibi kayıtlı numaranı 3 kez arar. Cevap yoksa ödül sıradaki oyuncuya geçer. VEX senden asla para veya şifre istemez.'],
  'ru13_t': ['پەیوەندی بە براوەکان', 'پەیوەندی دگەل سەرکەفتیان', 'Contacting winners', 'التواصل مع الفائزين', 'تماس با برندگان', 'Kazananlarla iletişim'],
  'ru1_s': ['پێشبڕکێیەکی تەندروستییە: چالاکی ڕۆژانەت دەبێتە خاڵ، خاڵەکان پلەت دیاری دەکەن و 3ی یەکەمی هەر لیگێک خەڵات دەبەنەوە.', 'پێشبڕکێیەکا ساخلەمیێ یە: چالاکیا تە یا ڕۆژانە دبیتە خال، خال پلا تە دیار دکەن و 3 یێن ئێکێ ژ هەر لیگەکێ خەڵاتان دبەن.', 'A health competition: your daily activity becomes points, points decide your rank, and the top 3 of each league win prizes.', 'منافسة صحية: يتحول نشاطك اليومي إلى نقاط، والنقاط تحدد ترتيبك، والثلاثة الأوائل في كل دوري يفوزون بالجوائز.', 'یک رقابت سلامتی: فعالیت روزانه‌ات امتیاز می‌شود، امتیاز رتبه‌ات را تعیین می‌کند و 3 نفر اول هر لیگ جایزه می‌برند.', 'Bir sağlık yarışması: günlük aktiviten puana dönüşür, puanlar sıranı belirler ve her ligin ilk 3\'ü ödül kazanır.'],
  'ru1_t': ['VEX Arena چییە؟', 'VEX Arena چییە؟', 'What is VEX Arena?', 'ما هو VEX Arena؟', 'VEX Arena چیست؟', 'VEX Arena nedir?'],
  'ru2_s': ['هەر وەرزێک 30 ڕۆژە. وەرزی 1: 31ی ئۆکتۆبەر 2026 کاتژمێر 6ی بەیانی (کاتی بەغدا). وەرزی 2: 10ی دیسەمبەر 2026. لە کۆتایی هەر وەرزێکدا خاڵەکان سفر دەبنەوە، بەڵام سکە و کارەکتەرەکانت دەمێنن.', 'هەر وەرزەک 30 ڕۆژن. وەرزێ 1: 31 ئۆکتۆبەر 2026 دەمژمێر 6 یێ سپێدێ (دەمێ بەغدا). وەرزێ 2: 10 دیسەمبەر 2026. د دووماهیا هەر وەرزەکێ دا خال سفر دبن، بەلێ پارە و کارەکتەرێن تە دمینن.', 'Each season lasts 30 days. Season 1: 31 October 2026 at 6:00 AM (Baghdad time). Season 2: 10 December 2026. Points reset at the end of each season; coins and characters stay.', 'كل موسم 30 يوماً. الموسم 1: 31 أكتوبر 2026 الساعة 6 صباحاً (بتوقيت بغداد). الموسم 2: 10 ديسمبر 2026. تُصفّر النقاط في نهاية كل موسم وتبقى العملات والشخصيات.', 'هر فصل 30 روز است. فصل 1: 31 اکتبر 2026 ساعت 6 صبح (به وقت بغداد). فصل 2: 10 دسامبر 2026. امتیازها در پایان هر فصل صفر می‌شود؛ سکه و کاراکترها می‌مانند.', 'Her sezon 30 gün sürer. Sezon 1: 31 Ekim 2026 saat 06:00 (Bağdat saati). Sezon 2: 10 Aralık 2026. Puanlar her sezon sonunda sıfırlanır; coin ve karakterler kalır.'],
  'ru2_t': ['وەرزەکان', 'وەرز', 'Seasons', 'المواسم', 'فصل‌ها', 'Sezonlar'],
  'ru3_s': ['لیگی Band: بۆ ئەوانەی VEX Band یان هەیە، هەموو 10 بەش، تا 600 خاڵ لە ڕۆژێکدا. لیگی مۆبایل: بێ Band، 5 بەش، تا 200 خاڵ. ئەپەکە بەپێی وەڵامی سەرەتات ئۆتۆماتیک دیاری دەکات و کاتێک Band ـت پەیوەست کرد دەچیتە لیگی Band.', 'لیگا Band: بۆ وان یێن VEX Band هەی، هەمی 10 پشک، هەتا 600 خال د ڕۆژەکێ دا. لیگا مۆبایلێ: بێ Band، 5 پشک، هەتا 200 خال. ئەپ ل دویڤ بەرسڤا تە یا دەستپێکێ ب خۆ دیار دکەت و دەمێ Band گرێدای دێ چییە لیگا Band.', 'Band league: for VEX Band owners, all 10 categories, up to 600 pts a day. Phone league: no Band, 5 categories, up to 200 pts. The app decides automatically from your setup answer and moves you up when you connect a Band.', 'دوري Band: لمالكي VEX Band، جميع الأقسام العشرة، حتى 600 نقطة يومياً. دوري الهاتف: بدون Band، 5 أقسام، حتى 200 نقطة. يحدد التطبيق ذلك تلقائياً وينقلك عند ربط Band.', 'لیگ Band: برای دارندگان VEX Band، همه 10 بخش، تا 600 امتیاز در روز. لیگ موبایل: بدون Band، 5 بخش، تا 200 امتیاز. اپ خودکار تعیین می‌کند و با وصل کردن Band ارتقا می‌دهد.', 'Band ligi: VEX Band sahipleri için, 10 kategori, günde 600 puana kadar. Telefon ligi: Band yok, 5 kategori, 200 puana kadar. Uygulama otomatik belirler, Band bağlayınca seni yükseltir.'],
  'ru3_t': ['دوو لیگ', 'دوو لیگ', 'Two leagues', 'دوريان', 'دو لیگ', 'İki lig'],
  'ru4_s': ['هەر بەشێک زۆرترین خاڵی خۆی هەیە. هێزی نهێنی ڕۆژانە یەک بەش ×3 و یەکێکی تر ×1.5 دەکات، بەڵام کۆی ڕۆژ لە سنووری لیگەکەت تێناپەڕێت.', 'هەر پشکەکێ زێدەترین خالێن خۆ هەنە. هێزا نهێنی یا ڕۆژانە ئێک پشک ×3 و ئێکا دی ×1.5 دکەت، بەلێ کۆما ڕۆژێ ژ سنوورێ لیگا تە دەرباز نابیت.', 'Each category has its own maximum. The daily secret power makes one category ×3 and another ×1.5, but the daily total never exceeds your league cap.', 'لكل قسم حد أقصى. القوة السرية اليومية تجعل قسماً ×3 وآخر ×1.5، لكن مجموع اليوم لا يتجاوز حد دوريك.', 'هر بخش سقف خودش را دارد. قدرت مخفی روزانه یک بخش را ×3 و دیگری را ×1.5 می‌کند، اما مجموع روز از سقف لیگ بیشتر نمی‌شود.', 'Her kategorinin kendi üst sınırı var. Günlük gizli güç bir kategoriyi ×3, diğerini ×1,5 yapar, ama günlük toplam lig sınırını aşmaz.'],
  'ru4_t': ['خاڵەکان', 'خال', 'Points', 'النقاط', 'امتیازها', 'Puanlar'],
  'ru5_s': ['ڕۆژێک چالاکە ئەگەر 100+ خاڵ (لیگی Band) یان 60+ خاڵ (لیگی مۆبایل) کۆبکەیتەوە. ڕۆژ کاتژمێر 12ی شەو دادەخرێت.', 'ڕۆژەک چالاکە ئەگەر 100+ خال (لیگا Band) یان 60+ خال (لیگا مۆبایلێ) کۆم بکەی. ڕۆژ دەمژمێر 12 یێ شەڤێ دهێتە گرتن.', 'A day is active with 100+ pts (Band league) or 60+ pts (Phone league). The day closes at midnight.', 'اليوم نشط عند 100+ نقطة (دوري Band) أو 60+ نقطة (دوري الهاتف). يُغلق اليوم عند منتصف الليل.', 'روز فعال است اگر 100+ امتیاز (لیگ Band) یا 60+ امتیاز (لیگ موبایل) بگیری. روز ساعت 12 شب بسته می‌شود.', 'Bir gün 100+ puan (Band ligi) veya 60+ puan (Telefon ligi) ile aktiftir. Gün gece yarısı kapanır.'],
  'ru5_t': ['ڕۆژی چالاک', 'ڕۆژا چالاک', 'Active day', 'اليوم النشط', 'روز فعال', 'Aktif gün'],
  'ru6_s': ['بۆ خەڵاتە گەورەکان پێویستە لانیکەم 25 ڕۆژی چالاکت هەبێت لە 30 ڕۆژ. ڕۆژی بیانوو (3 جار) وەک چالاک حیساب دەکرێت. ئەوانەی دواتر بەشداردەبن تەنها ڕۆژە ماوەکانیان هەیە.', 'بۆ خەڵاتێن مەزن پێدڤییە کێمتر 25 ڕۆژێن چالاک هەبن ژ 30 ڕۆژان. ڕۆژا بیانوو (3 جار) وەک چالاک دهێتە حیسابکرن. یێن پاشی بەشداردبن بتنێ ڕۆژێن مای بۆ وان هەنە.', 'Grand prizes require at least 25 active days out of 30. Excuse days (3) count as active. Late joiners only have the remaining days.', 'تتطلب الجوائز الكبرى 25 يوماً نشطاً على الأقل من 30. أيام العذر (3) تُحتسب نشطة. المنضمون متأخراً لديهم الأيام المتبقية فقط.', 'جوایز بزرگ حداقل 25 روز فعال از 30 روز لازم دارد. روز معذوریت (3 بار) فعال حساب می‌شود. دیرپیوستگان فقط روزهای باقی‌مانده را دارند.', 'Büyük ödüller 30 günden en az 25 aktif gün gerektirir. Mazeret günleri (3) aktif sayılır. Geç katılanların sadece kalan günleri vardır.'],
  'ru6_t': ['مەرجی خەڵات', 'مەرجێ خەڵاتی', 'Prize condition', 'شرط الجوائز', 'شرط جایزه', 'Ödül şartı'],
  'ru7_s': ['لیگی Band: 1. ئۆتۆمبێل · 2. iPhone 17 Pro · 3. 1,000,000 دینار. لیگی مۆبایل: 1. 250,000 · 2. 150,000 · 3. 100,000 دینار. لە یەکسانیدا ئەوەی زووتر تۆماری کردووە پێشدەکەوێت.', 'لیگا Band: 1. ترومبێل · 2. iPhone 17 Pro · 3. 1,000,000 دینار. لیگا مۆبایلێ: 1. 250,000 · 2. 150,000 · 3. 100,000 دینار. د وەکهەڤیێ دا یێ زووتر تۆمارکری پێش دکەڤیت.', 'Band league: 1. car · 2. iPhone 17 Pro · 3. 1,000,000 IQD. Phone league: 1. 250,000 · 2. 150,000 · 3. 100,000 IQD. Ties go to whoever registered first.', 'دوري Band: 1. سيارة · 2. iPhone 17 Pro · 3. مليون دينار. دوري الهاتف: 1. 250,000 · 2. 150,000 · 3. 100,000 دينار. عند التعادل يتقدم الأسبق تسجيلاً.', 'لیگ Band: 1. خودرو · 2. iPhone 17 Pro · 3. 1,000,000 دینار. لیگ موبایل: 1. 250,000 · 2. 150,000 · 3. 100,000 دینار. در تساوی، ثبت‌نام زودتر جلو است.', 'Band ligi: 1. araba · 2. iPhone 17 Pro · 3. 1.000.000 IQD. Telefon ligi: 1. 250.000 · 2. 150.000 · 3. 100.000 IQD. Eşitlikte önce kaydolan öne geçer.'],
  'ru7_t': ['خەڵاتەکان', 'خەڵات', 'Prizes', 'الجوائز', 'جوایز', 'Ödüller'],
  'ru8_s': ['هەفتە لە شەممەوە دەستپێدەکات. ئەگەر گرووپەکەت 5 کەس یان زیاتر بێت: یەکەم 50، دووەم 30، سێیەم 20، 4 تا 10 هەریەکە 15 سکە.', 'حەفتی ژ شەمبیێ دەستپێدکەت. ئەگەر گرووپا تە 5 کەس یان زێدەتر بن: ئێکێ 50، دووێ 30، سێیێ 20، 4 هەتا 10 هەر ئێک 15 پارە.', 'Weeks start on Saturday. If your group has 5+ players: 1st 50, 2nd 30, 3rd 20, 4th–10th 15 coins each.', 'يبدأ الأسبوع يوم السبت. إذا كانت مجموعتك 5 أو أكثر: الأول 50، الثاني 30، الثالث 20، من 4 إلى 10 لكلٍ 15 عملة.', 'هفته از شنبه شروع می‌شود. اگر گروهت 5 نفر یا بیشتر باشد: اول 50، دوم 30، سوم 20، 4 تا 10 هر کدام 15 سکه.', 'Hafta cumartesi başlar. Grubun 5+ kişiyse: 1. 50, 2. 30, 3. 20, 4.–10. her biri 15 coin.'],
  'ru8_t': ['گرووپی هەفتە', 'گرووپا حەفتیێ', 'Weekly group', 'مجموعة الأسبوع', 'گروه هفته', 'Haftalık grup'],
  'ru9_s': ['هەر 25 خاڵ = 1 سکە (تا 24 لە لیگی Band، 8 لە لیگی مۆبایل). دیاریی بەخێرهاتن 20، دامەزرێنەران +30. سکە بۆ کارەکتەر، دیزاینی کارت و پاراستنی زنجیرە بەکاردێت.', 'هەر 25 خال = 1 پارە (هەتا 24 ل لیگا Band، 8 ل لیگا مۆبایلێ). دیاریا بخێرهاتنێ 20، دامەزرێنەر +30. پارە بۆ کارەکتەر، دیزاینا کارتێ و پاراستنا زنجیرێ دهێنە بکارئینان.', 'Every 25 pts = 1 coin (up to 24 in the Band league, 8 in the Phone league). Welcome gift 20, founders +30. Coins buy characters, card designs and streak shields.', 'كل 25 نقطة = عملة (حتى 24 في دوري Band و8 في دوري الهاتف). هدية ترحيب 20، والمؤسسون +30. تُستخدم العملات للشخصيات والتصاميم وحماية السلسلة.', 'هر 25 امتیاز = 1 سکه (تا 24 در لیگ Band، 8 در لیگ موبایل). هدیه خوش‌آمد 20، بنیان‌گذاران +30. سکه برای کاراکتر، طرح کارت و محافظ زنجیره است.', 'Her 25 puan = 1 coin (Band liginde 24\'e, Telefon liginde 8\'e kadar). Hoş geldin hediyesi 20, kurucular +30. Coin ile karakter, kart tasarımı ve seri kalkanı alınır.'],
  'ru9_t': ['سکە', 'پارە', 'Coins', 'العملات', 'سکه', 'Coin'],
  'ru_active': ['ڕۆژی چالاک', 'ڕۆژا چالاک', 'Active day', 'يوم نشط', 'روز فعال', 'Aktif gün'],
  'ru_cat': ['بەش', 'پشک', 'Category', 'القسم', 'بخش', 'Kategori'],
  'ru_max': ['زۆرترین لە ڕۆژێکدا', 'زێدەترین د ڕۆژەکێ دا', 'Daily max', 'الحد اليومي', 'حداکثر روزانه', 'Günlük maks.'],
  'rules': ['یاساکان', 'یاسا', 'Rules', 'القوانين', 'قوانین', 'Kurallar'],
  'rules_s': ['هەموو یاساکانی وەرزی {0}', 'هەمی یاسایێن وەرزێ {0}', 'All rules of season {0}', 'جميع قوانين الموسم {0}', 'همه قوانین فصل {0}', 'Sezon {0} kurallarının tamamı'],
  'rv_go': ['دەستپێبکە', 'دەستپێبکە', 'Let\'s go', 'لنبدأ', 'شروع کن', 'Başla'],
  'rv_live': ['بەخێربێیت بۆ پێشبڕکێ! خاڵەکانی ئەمڕۆت ئێستا حیساب دەکرێن.', 'بخێربێی بۆ پێشبڕکێ! خالێن ئەڤرۆ نوکە دهێنە حیسابکرن.', 'Welcome to the competition! Today\'s points count right now.', 'مرحباً بك في المنافسة! نقاط اليوم تُحتسب الآن.', 'به رقابت خوش آمدی! امتیازهای امروز از الان حساب می‌شود.', 'Yarışmaya hoş geldin! Bugünün puanları şimdi sayılıyor.'],
  'rv_pre': ['تۆ یەکێکی لە دامەزرێنەرانی وەرز. کاتێک وەرز دەستپێدەکات، هەموو خاڵێک حیساب دەکرێت.', 'تو ئێک ژ دامەزرێنەرێن وەرزی یی. دەمێ وەرز دەستپێدکەت، هەمی خال دێ هێنە حیسابکرن.', 'You are one of the season founders. Every point counts once the season starts.', 'أنت من مؤسسي الموسم. كل نقطة تُحتسب عند بدء الموسم.', 'تو از بنیان‌گذاران فصل هستی. با شروع فصل همه امتیازها حساب می‌شود.', 'Sezonun kurucularındansın. Sezon başlayınca her puan sayılır.'],
  'rv_t': ['کارتەکەت ئامادەیە!', 'کارتا تە یا ئامادەیە!', 'Your card is ready!', 'بطاقتك جاهزة!', 'کارتت آماده است!', 'Kartın hazır!'],
  'save': ['پاشەکەوت', 'پاراستن', 'Save', 'حفظ', 'ذخیره', 'Kaydet'],
  'saved': ['پاشەکەوت کرا', 'هاتە پاراستن', 'Saved', 'تم الحفظ', 'ذخیره شد', 'Kaydedildi'],
  'season_tot': ['کۆی وەرز', 'کۆما وەرزی', 'Season total', 'مجموع الموسم', 'مجموع فصل', 'Sezon toplamı'],
  'sg_age': ['تەمەنی من', 'ژیێ من', 'My age', 'عمري', 'سن من', 'Yaşım'],
  'sg_all': ['هەموو وەرز', 'هەمی وەرز', 'Season', 'الموسم', 'کل فصل', 'Sezon'],
  'sg_guess': ['پێشبینی', 'پێشبینی', 'Guesses', 'التخمين', 'حدس', 'Tahmin'],
  'sg_week': ['ئەم هەفتەیە', 'ئەڤ حەفتیە', 'This week', 'هذا الأسبوع', 'این هفته', 'Bu hafta'],
  'shield_lost': ['{0} ڕۆژ لەدەستچوو.', '{0} ڕۆژ ژ دەست چوون.', '{0} day(s) missed.', 'فاتك {0} يوم.', '{0} روز از دست رفت.', '{0} gün kaçırıldı.'],
  'shield_s': ['7 ڕۆژ چالاک بە و 70 خاڵی دیاری وەربگرە', '7 ڕۆژان چالاک بە و 70 خالێن دیاری وەرگرە', 'Be active 7 days for 70 bonus points', 'كن نشطاً 7 أيام لتحصل على 70 نقطة', '7 روز فعال باش و 70 امتیاز هدیه بگیر', '7 gün aktif ol, 70 bonus puan kazan'],
  'shield_t': ['قەڵغانی هەفتە', 'قەڵغانێ حەفتیێ', 'Weekly shield', 'درع الأسبوع', 'سپر هفته', 'Haftalık kalkan'],
  'sk_auto': ['بەپێی لیگ', 'ل دویڤ لیگێ', 'By league', 'حسب الدرجة', 'بر اساس لیگ', 'Lige göre'],
  'sk_carbon': ['کاربۆن', 'کاربۆن', 'Carbon', 'كربون', 'کربن', 'Karbon'],
  'sk_dia': ['ئەڵماس', 'ئەلماس', 'Diamond', 'ماسي', 'الماس', 'Elmas'],
  'sk_gold': ['زێڕین', 'زێڕین', 'Gold', 'ذهبي', 'طلایی', 'Altın'],
  'sk_holo': ['هۆلۆگرام', 'هۆلۆگرام', 'Hologram', 'هولوغرام', 'هولوگرام', 'Hologram'],
  'sk_kurd': ['کوردستان', 'کوردستان', 'Kurdistan', 'كردستان', 'کردستان', 'Kürdistan'],
  'sk_legend': ['ئەفسانە', 'ئەفسانە', 'Legend', 'أسطورة', 'افسانه', 'Efsane'],
  'sk_marble': ['مەڕمەڕ', 'مەڕمەڕ', 'Marble', 'رخام', 'مرمر', 'Mermer'],
  'sk_need_lg': ['پێویستە بگەیتە لیگی {0}', 'پێدڤییە بگەهییە لیگا {0}', 'Reach the {0} league to unlock', 'يجب الوصول إلى درجة {0}', 'باید به لیگ {0} برسی', '{0} ligine ulaşman gerekiyor'],
  'sk_neon': ['نیۆن', 'نیۆن', 'Neon', 'نيون', 'نئون', 'Neon'],
  'sk_newroz': ['نەورۆز', 'نەورۆز', 'Newroz', 'نوروز', 'نوروز', 'Nevruz'],
  'sk_night': ['شەو', 'شەڤ', 'Night', 'ليل', 'شب', 'Gece'],
  'sk_royal': ['شاهانە', 'شاهانە', 'Royal', 'ملكي', 'سلطنتی', 'Kraliyet'],
  'sk_s': ['بە سکە یان لیگ', 'ب پارە یان لیگ', 'With coins or league', 'بالعملات أو الدرجة', 'با سکه یا لیگ', 'Coin veya lig ile'],
  'sk_t': ['دیزاینی کارت', 'دیزاینا کارتێ', 'Card design', 'تصميم البطاقة', 'طرح کارت', 'Kart tasarımı'],
  'sk_zagros': ['زاگرۆس', 'زاگرۆس', 'Zagros', 'زاغروس', 'زاگرس', 'Zagros'],
  'soon': ['بەم زووانە', 'ب زوویی', 'SOON', 'قريباً', 'به‌زودی', 'YAKINDA'],
  'sp_free': ['بەتاڵە', 'یێ ڤالایە', 'Available', 'متاح', 'خالی', 'Boş'],
  'sp_s': ['ئەم شوێنە بۆ سپۆنسەری فەرمی ئامادەیە', 'ئەڤ جهە بۆ سپۆنسەرێ فەرمی یێ ئامادەیە', 'Reserved for the official sponsor', 'مخصصة للراعي الرسمي', 'برای اسپانسر رسمی رزرو شده', 'Resmi sponsor için ayrıldı'],
  'sp_t': ['شوێنی سپۆنسەری وەرز', 'جهێ سپۆنسەرێ وەرزی', 'Season sponsor spot', 'مساحة راعي الموسم', 'جایگاه اسپانسر فصل', 'Sezon sponsoru alanı'],
  'spend_char': ['کارەکتەری نوێ (40 بۆ 150)', 'کارەکتەرێن نوو (40 هەتا 150)', 'New characters (40 to 150)', 'شخصيات جديدة (40 إلى 150)', 'کاراکتر جدید (40 تا 150)', 'Yeni karakterler (40–150)'],
  'spend_frz': ['پاراستنی زنجیرە (30)', 'پاراستنا زنجیرێ (30)', 'Streak shield (30)', 'حماية السلسلة (30)', 'محافظ زنجیره (30)', 'Seri kalkanı (30)'],
  'spend_skin': ['دیزاینی کارت (30 بۆ 120)', 'دیزاینا کارتێ (30 هەتا 120)', 'Card designs (30 to 120)', 'تصاميم البطاقة (30 إلى 120)', 'طرح کارت (30 تا 120)', 'Kart tasarımları (30–120)'],
  'spend_t': ['سکە بۆ چی بەکاردێت', 'پارە بۆ چ دهێنە بکارئینان', 'What coins buy', 'ماذا تشتري العملات', 'سکه برای چه', 'Coin ile ne alınır'],
  'st_char': ['کارەکتەر', 'کارەکتەر', 'Character', 'الشخصية', 'کاراکتر', 'Karakter'],
  'st_city': ['شار', 'باژێر', 'City', 'المدينة', 'شهر', 'Şehir'],
  'st_id': ['ناسنامە', 'ناسنامە', 'Identity', 'الهوية', 'هویت', 'Kimlik'],
  'st_rules': ['یاسا', 'یاسا', 'Rules', 'القوانين', 'قوانین', 'Kurallar'],
  'streak': ['زنجیرە', 'زنجیرە', 'Streak', 'سلسلة', 'زنجیره', 'Seri'],
  'streak_toast': ['زنجیرەی {0} ڕۆژ! بەردەوام بە', 'زنجیرا {0} ڕۆژان! بەردەوام بە', '{0}-day streak! Keep going', 'سلسلة {0} أيام! استمر', 'زنجیره {0} روزه! ادامه بده', '{0} günlük seri! Devam et'],
  'sync': ['هاوکاتکرا', 'هاتە هاوکاتکرن', 'Synced', 'تمت المزامنة', 'همگام شد', 'Senkron'],
  'synced': ['داتاکان نوێکرانەوە', 'داتا هاتنە نووکرن', 'Data refreshed', 'تم تحديث البيانات', 'داده‌ها به‌روز شد', 'Veriler yenilendi'],
  'tab_card': ['کارتەکەم', 'کارتێ من', 'My card', 'بطاقتي', 'کارت من', 'Kartım'],
  'tab_rank': ['پلەکان', 'پلە', 'Ranking', 'الترتيب', 'رتبه‌بندی', 'Sıralama'],
  'tab_today': ['ئەمڕۆ', 'ئەڤرۆ', 'Today', 'اليوم', 'امروز', 'Bugün'],
  'tamper_s': ['داتای پاشەکەوتکراو دەستکاری کرابوو، بۆیە سکە و خاڵەکان سفر کرانەوە.', 'داتایێن پاراستی هاتبوونە دەستکاریکرن، لەوما پارە و خال هاتنە سفرکرن.', 'Saved data was modified, so coins and points were reset.', 'تم تعديل البيانات المحفوظة، لذا صُفّرت العملات والنقاط.', 'داده ذخیره‌شده دستکاری شده بود، پس سکه و امتیاز صفر شد.', 'Kayıtlı veriler değiştirilmiş, bu yüzden coin ve puanlar sıfırlandı.'],
  'tamper_t': ['دەستکاری دۆزرایەوە', 'دەستکاری هاتە دیتن', 'Tampering detected', 'تم اكتشاف تلاعب', 'دستکاری شناسایی شد', 'Değişiklik tespit edildi'],
  'ti_head': ['نازناو', 'نازناڤ', 'Title', 'اللقب', 'لقب', 'Unvan'],
  'ti_need_t0': ['', '', '', '', '', ''],
  'ti_need_t1': ['', '', '', '', '', ''],
  'ti_need_t2': ['', '', '', '', '', ''],
  'ti_need_t3': ['یەک پێشبینیی ڕاستت پێویستە', 'ئێک پێشبینیا دروست پێدڤییە', 'Needs one correct guess', 'يتطلب تخميناً صحيحاً واحداً', 'یک حدس درست لازم است', 'Bir doğru tahmin gerekli'],
  'ti_need_t4': ['پێویستە بگەیتە لیگی ئەفسانە', 'پێدڤییە بگەهییە لیگا ئەفسانە', 'Reach the Legend league', 'يجب الوصول إلى درجة الأسطورة', 'باید به لیگ افسانه برسی', 'Efsane ligine ulaşman gerekiyor'],
  'ti_t0': ['وەرزشوان', 'وەرزشڤان', 'Athlete', 'رياضي', 'ورزشکار', 'Sporcu'],
  'ti_t1': ['ڕێکخەر', 'ڕێکخەر', 'Disciplined', 'منضبط', 'منظم', 'Disiplinli'],
  'ti_t2': ['تەندروستی یەکەم', 'ساخلەمی ئێکێ', 'Health first', 'الصحة أولاً', 'سلامتی اول', 'Önce sağlık'],
  'ti_t3': ['پێشبینیکەر', 'پێشبینیکەر', 'Oracle', 'العرّاف', 'پیشگو', 'Kâhin'],
  'ti_t4': ['ئەفسانە', 'ئەفسانە', 'Legend', 'أسطورة', 'افسانه', 'Efsane'],
  'to_count': ['{0} خاڵی تر بۆ ئەوەی ئەمڕۆ حیساب بکرێت', '{0} خالێن دی دا کو ئەڤرۆ بێتە حیسابکرن', '{0} more pts for today to count', '{0} نقطة أخرى ليُحتسب اليوم', '{0} امتیاز دیگر تا امروز حساب شود', 'Bugünün sayılması için {0} puan daha'],
  'to_goal': ['{0} خاڵی تر بۆ ئامانجی {1}', '{0} خالێن دی بۆ ئارمانجا {1}', '{0} more to reach {1}', '{0} نقطة أخرى للوصول إلى {1}', '{0} امتیاز دیگر تا {1}', '{1} için {0} puan daha'],
  'tot_pre': ['کۆی ڕاهێنان', 'کۆما ڕاهێنانێ', 'Practice total', 'مجموع التدريب', 'مجموع تمرین', 'Antrenman toplamı'],
  'tot_s': ['{0} لە {1} بەش', '{0} ژ {1} پشکان', '{0} of {1} categories', '{0} من {1} أقسام', '{0} از {1} بخش', '{1} kategoriden {0}'],
  'tot_t': ['کۆی ئەمڕۆ', 'کۆما ئەڤرۆ', 'Today\'s total', 'مجموع اليوم', 'مجموع امروز', 'Bugünün toplamı'],
  'u_active_rest': ['{0} خولەک چالاک · پشوو {1}', '{0} خولەک چالاک · بێهنڤەدان {1}', '{0} active min · rest {1}', '{0} دقيقة نشاط · راحة {1}', '{0} دقیقه فعال · استراحت {1}', '{0} aktif dk · dinlenme {1}'],
  'u_d': ['ڕۆژ', 'ڕۆژ', 'days', 'يوم', 'روز', 'gün'],
  'u_h': ['کاتژمێر', 'دەمژمێر', 'hrs', 'ساعة', 'ساعت', 'saat'],
  'u_hm': ['{0} کاتژمێر', '{0} دەمژمێر', '{0} h', '{0} ساعة', '{0} ساعت', '{0} sa'],
  'u_m': ['خولەک', 'خولەک', 'min', 'دقيقة', 'دقیقه', 'dk'],
  'u_meals': ['{0} ژەم', '{0} ژەم', '{0} meals', '{0} وجبات', '{0} وعده', '{0} öğün'],
  'u_min': ['{0} خولەک', '{0} خولەک', '{0} min', '{0} دقيقة', '{0} دقیقه', '{0} dk'],
  'u_min_km': ['{0} خولەک · ⁦{1} km⁩', '{0} خولەک · ⁦{1} km⁩', '{0} min · {1} km', '{0} دقيقة · {1} كم', '{0} دقیقه · ⁦{1} km⁩', '{0} dk · {1} km'],
  'u_ml': ['⁦{0} / {1} ml⁩', '⁦{0} / {1} ml⁩', '{0} / {1} ml', '⁦{0} / {1} مل⁩', '⁦{0} / {1} ml⁩', '{0} / {1} ml'],
  'u_rest': ['لێدانی پشوو {0}', 'لێدانا بێهنڤەدانێ {0}', 'Resting HR {0}', 'نبض الراحة {0}', 'ضربان استراحت {0}', 'Dinlenme nabzı {0}'],
  'u_right': ['ڕاست', 'دروست', 'correct', 'صحيح', 'درست', 'doğru'],
  'u_s': ['چرکە', 'چرکە', 'sec', 'ثانية', 'ثانیه', 'sn'],
  'u_steps': ['{0} هەنگاو', '{0} پێنگاڤ', '{0} steps', '{0} خطوة', '{0} قدم', '{0} adım'],
  'u_stress': ['سترێس {0}', 'سترێس {0}', 'Stress {0}', 'التوتر {0}', 'استرس {0}', 'Stres {0}'],
  'verified': ['پشتڕاستکرایەوە', 'هاتە پشتڕاستکرن', 'Verified', 'تم التحقق', 'تأیید شد', 'Doğrulandı'],
  'w_burst': ['زیاتر لە 500 ml لە یەک جاردا', 'زێدەتر ژ 500 ml ب ئێک جار', 'over 500 ml at once', 'أكثر من 500 مل دفعة واحدة', 'بیش از 500 ml یکجا', 'tek seferde 500 ml\'den fazla'],
  'w_hour': ['زیاتر لە 1 لیتر لە یەک کاتژمێردا', 'زێدەتر ژ 1 لیترێ د ئێک دەمژمێرێ دا', 'over 1 liter in one hour', 'أكثر من لتر في ساعة واحدة', 'بیش از 1 لیتر در یک ساعت', 'bir saatte 1 litreden fazla'],
  'w_night': ['لە نێوان 12 تا 6ی بەیانی', 'د ناڤبەرا 12 تا 6 یێن سپێدێ', 'between midnight and 6 AM', 'بين منتصف الليل و6 صباحاً', 'بین 12 شب تا 6 صبح', 'gece 12 ile sabah 6 arası'],
  'w_note': ['{0} ml حیساب نەکرا: {1}', '{0} ml نەهاتە حیسابکرن: {1}', '{0} ml not counted: {1}', 'لم يُحتسب {0} مل: {1}', '{0} ml حساب نشد: {1}', '{0} ml sayılmadı: {1}'],
  'w_pre': ['زیاتر لە 1 لیتر پێش کردنەوەی VEX Arena تۆمارکرابوو', 'زێدەتر ژ 1 لیترێ بەری ڤەکرنا VEX Arena هاتبوو تۆمارکرن', 'over 1 liter logged before VEX Arena was opened', 'أكثر من لتر سُجّل قبل فتح VEX Arena', 'بیش از 1 لیتر قبل از باز کردن VEX Arena ثبت شده بود', 'VEX Arena açılmadan önce 1 litreden fazla kaydedildi'],
  'w_spread': ['ئاو لە ماوەی ڕۆژدا دابەش بکە بۆ خاڵی تەواو', 'ئاڤێ د ڕۆژێ دا بەلاڤ بکە بۆ خالێن تەمام', 'Spread water through the day for full points', 'وزّع شرب الماء على اليوم لتحصل على النقاط كاملة', 'آب را در طول روز پخش کن تا امتیاز کامل بگیری', 'Tam puan için suyu güne yay'],
  'why_band': ['Band ـەکەت لە دەست بکە و پەیوەستی بکە بۆ ئەوەی ئەم بەشە حیساب بکرێت.', 'Band ـێ ل دەستێ خۆ بکە و گرێبدە دا ئەڤ پشکە بێتە حیسابکرن.', 'Wear and connect your Band for this category to count.', 'ارتدِ Band وقم بتوصيله ليُحتسب هذا القسم.', 'Band را ببند و وصل کن تا این بخش حساب شود.', 'Bu kategorinin sayılması için Band\'ini tak ve bağla.'],
  'why_fast': ['خێرایی زۆر بەرز بوو بۆ ڕاکردن (ئۆتۆمبێل یان پاسکیل؟).', 'لەز گەلەک بلند بوو بۆ ڕەڤینێ (ترومبێل یان پاسکیل؟).', 'Pace too fast for running (car or bike?).', 'السرعة عالية جداً للجري (سيارة أو دراجة؟).', 'سرعت برای دویدن خیلی زیاد بود (ماشین یا دوچرخه؟).', 'Koşu için tempo çok hızlı (araba veya bisiklet?).'],
  'why_future': ['ژەمێک کاتی داهاتووی هەبوو.', 'ژەمەکێ دەمێ پاشەڕۆژێ هەبوو.', 'A meal had a future time.', 'وجبة بوقت في المستقبل.', 'یک وعده زمان آینده داشت.', 'Bir öğünün saati gelecekteydi.'],
  'why_gps': ['مەودای GPS تۆمار نەکرا.', 'دووراتیا GPS نەهاتە تۆمارکرن.', 'No GPS distance was recorded.', 'لم تُسجل مسافة GPS.', 'مسافت GPS ثبت نشد.', 'GPS mesafesi kaydedilmedi.'],
  'why_hrflat': ['لێدانی دڵ لە کاتی وەرزشدا بەرز نەبووەوە.', 'لێدانێن دلی د دەمێ وەرزشێ دا بلند نەبوون.', 'Heart rate did not rise during the workout.', 'لم يرتفع نبض القلب أثناء التمرين.', 'ضربان قلب در طول ورزش بالا نرفت.', 'Antrenman sırasında nabız yükselmedi.'],
  'why_hrstill': ['لێدانی چالاکی بێ جووڵە (هەنگاو کەمتر لە 300).', 'لێدانێن چالاک بێ لڤین (پێنگاڤ کێمتر ژ 300).', 'Active heart rate without movement (under 300 steps).', 'نبض نشط بدون حركة (أقل من 300 خطوة).', 'ضربان فعال بدون حرکت (کمتر از 300 قدم).', 'Hareketsiz aktif nabız (300 adımdan az).'],
  'why_hrv': ['خوێندنەوەی HRV هەڵەیە.', 'خواندنا HRV یا شاشە.', 'Invalid HRV reading.', 'قراءة HRV غير صالحة.', 'خوانش HRV نامعتبر است.', 'Geçersiz HRV ölçümü.'],
  'why_na': ['ئەم بەشە پێویستی بە VEX Band ـە و تەنها لە لیگی Band حیساب دەکرێت.', 'ئەڤ پشکە پێدڤی ب VEX Band ـێ یە و بتنێ ل لیگا Band دهێتە حیسابکرن.', 'This category needs a VEX Band and only counts in the Band league.', 'هذا القسم يحتاج VEX Band ويُحتسب في دوري Band فقط.', 'این بخش به VEX Band نیاز دارد و فقط در لیگ Band حساب می‌شود.', 'Bu kategori VEX Band gerektirir ve sadece Band liginde sayılır.'],
  'why_read': ['خوێندنەوەی SpO₂ هەڵەیە.', 'خواندنا SpO₂ یا شاشە.', 'Invalid SpO₂ reading.', 'قراءة SpO₂ غير صالحة.', 'خوانش SpO₂ نامعتبر است.', 'Geçersiz SpO₂ ölçümü.'],
  'why_shake': ['هەنگاوی ناسروشتی (هەژاندنی دەست؟).', 'پێنگاڤێن نە سروشتی (هەژاندنا دەستی؟).', 'Unnatural steps (hand shaking?).', 'خطوات غير طبيعية (هز اليد؟).', 'قدم‌های غیرطبیعی (تکان دادن دست؟).', 'Doğal olmayan adımlar (el sallama?).'],
  'why_short': ['وەرزش کەمتر لە 10 خولەک بوو.', 'وەرزش کێمتر ژ 10 خولەکان بوو.', 'Workout was shorter than 10 minutes.', 'كان التمرين أقل من 10 دقائق.', 'ورزش کمتر از 10 دقیقه بود.', 'Antrenman 10 dakikadan kısaydı.'],
  'why_sleep12': ['خەوی زیاتر لە 12 کاتژمێر حیساب ناکرێت.', 'نڤستنا زێدەتر ژ 12 دەمژمێران ناهێتە حیسابکرن.', 'Sleep over 12 hours is not counted.', 'لا يُحتسب النوم لأكثر من 12 ساعة.', 'خواب بیش از 12 ساعت حساب نمی‌شود.', '12 saatten uzun uyku sayılmaz.'],
  'why_slow': ['خێرایی زۆر نزم بوو بۆ ڕاکردن.', 'لەز گەلەک نزم بوو بۆ ڕەڤینێ.', 'Pace too slow for running.', 'السرعة منخفضة جداً للجري.', 'سرعت برای دویدن خیلی کم بود.', 'Koşu için tempo çok yavaş.'],
  'why_steps': ['هەنگاوی ناسروشتی (زیاتر لە 40,000).', 'پێنگاڤێن نە سروشتی (زێدەتر ژ 40,000).', 'Unnatural step count (over 40,000).', 'عدد خطوات غير طبيعي (أكثر من 40,000).', 'تعداد قدم غیرطبیعی (بیش از 40,000).', 'Doğal olmayan adım sayısı (40.000 üzeri).'],
  'win_s': ['لە کۆتایی وەرزدا، تیمی VEX 3 جار پەیوەندی بە ژمارەکەتەوە دەکات. ئەگەر وەڵام نەدرایەوە، خەڵاتەکە دەچێت بۆ کەسی دواتر.', 'د دووماهیا وەرزی دا، تیما VEX دێ 3 جاران پەیوەندیێ ب ژمارا تە کەت. ئەگەر بەرسڤ نەهاتە دان، خەڵات دێ چیتە بۆ کەسێ دی.', 'At season end the VEX team calls your number 3 times. If there is no answer, the prize passes to the next player.', 'في نهاية الموسم يتصل فريق VEX برقمك 3 مرات. إذا لم يتم الرد، تنتقل الجائزة للاعب التالي.', 'در پایان فصل تیم VEX سه بار با شماره شما تماس می‌گیرد. اگر پاسخ ندهید، جایزه به نفر بعدی می‌رسد.', 'Sezon sonunda VEX ekibi numaranı 3 kez arar. Cevap verilmezse ödül sıradaki oyuncuya geçer.'],
  'win_t': ['براوەکان 3 جار پەیوەندییان پێوە دەکرێت', 'سەرکەفتی 3 جاران پەیوەندی دگەل دهێتە کرن', 'Winners are called 3 times', 'يتم الاتصال بالفائزين 3 مرات', 'با برندگان 3 بار تماس گرفته می‌شود', 'Kazananlar 3 kez aranır'],
  'wk_champ': ['پاڵەوان · +{0} سکە', 'پاڵەوان · +{0} پارە', 'Champion · +{0} coins', 'بطل · +{0} عملة', 'قهرمان · +{0} سکه', 'Şampiyon · +{0} coin'],
  'wk_gap': ['{0} خاڵ بۆ 10ی یەکەم', '{0} خال بۆ 10 یێن ئێکێ', '{0} pts to top 10', '{0} نقطة للوصول إلى العشرة الأوائل', '{0} امتیاز تا 10 نفر اول', 'İlk 10 için {0} puan'],
  'wk_k': ['گرووپی هەفتە · {0}', 'گرووپا حەفتیێ · {0}', 'Weekly group · {0}', 'مجموعة الأسبوع · {0}', 'گروه هفته · {0}', 'Haftalık grup · {0}'],
  'wk_left': ['{0} ڕۆژ بۆ کۆتایی هەفتە', '{0} ڕۆژ بۆ دووماهیا حەفتیێ', '{0} days until week ends', '{0} أيام حتى نهاية الأسبوع', '{0} روز تا پایان هفته', 'Hafta bitimine {0} gün'],
  'wk_members': ['{0} ئەندام', '{0} ئەندام', '{0} members', '{0} أعضاء', '{0} عضو', '{0} üye'],
  'wk_zone': ['ناوچەی خەڵات', 'دەڤەرا خەڵاتی', 'Reward zone', 'منطقة المكافأة', 'منطقه جایزه', 'Ödül bölgesi'],
  'y_active': ['ڕۆژێکی چالاک حیساب کرا', 'ڕۆژەکا چالاک هاتە حیسابکرن', 'Counted as an active day', 'احتُسب يوماً نشطاً', 'روز فعال حساب شد', 'Aktif gün olarak sayıldı'],
  'y_early': ['ئەنجامی دوێنێ کاتژمێر 6ی بەیانی ئاشکرا دەکرێت', 'ئەنجامێ دهی دەمژمێر 6 یێ سپێدێ دێ ئاشکرا بیت', 'Yesterday\'s result is revealed at 6:00 AM', 'تُكشف نتيجة الأمس الساعة 6 صباحاً', 'نتیجه دیروز ساعت 6 صبح فاش می‌شود', 'Dünün sonucu 06:00\'da açıklanır'],
  'y_inactive': ['ڕۆژێکی چالاک نەبوو', 'ڕۆژەکا چالاک نەبوو', 'Not an active day', 'لم يكن يوماً نشطاً', 'روز فعال نبود', 'Aktif gün değildi'],
  'y_line': ['دوێنێ: {0} ×3 · {1} ×1.5 · تۆ {2} خاڵ', 'دهی: {0} ×3 · {1} ×1.5 · تە {2} خال', 'Yesterday: {0} ×3 · {1} ×1.5 · you {2} pts', 'أمس: {0} ×3 · {1} ×1.5 · أنت {2} نقطة', 'دیروز: {0} ×3 · {1} ×1.5 · شما {2} امتیاز', 'Dün: {0} ×3 · {1} ×1.5 · sen {2} puan'],
  'y_none': ['دوێنێ پێشبینیت نەکرد', 'دهی تە پێشبینی نەکر', 'You didn\'t guess yesterday', 'لم تخمّن أمس', 'دیروز حدس نزدی', 'Dün tahmin yapmadın'],
  'y_none_s': ['هەموو ڕۆژێک دەتوانیت پێشبینی بکەیت', 'هەمی ڕۆژان دشێی پێشبینیێ بکەی', 'You can guess every day', 'يمكنك التخمين كل يوم', 'هر روز می‌توانی حدس بزنی', 'Her gün tahmin edebilirsin'],
  'y_power': ['هێزی سەرەکی', 'هێزا سەرەکی', 'Main power', 'القوة الرئيسية', 'قدرت اصلی', 'Ana güç'],
  'y_pts': ['خاڵەکانی دوێنێ: {0}', 'خالێن دهی: {0}', 'Yesterday\'s points: {0}', 'نقاط الأمس: {0}', 'امتیاز دیروز: {0}', 'Dünün puanı: {0}'],
  'y_right': ['پێشبینییەکەت ڕاست بوو!', 'پێشبینیا تە دروست بوو!', 'Your guess was right!', 'كان تخمينك صحيحاً!', 'حدست درست بود!', 'Tahminin doğruydu!'],
  'y_right_s': ['+10 سکە و +50 خاڵی وەرز وەرگیرا', '+10 پارە و +50 خالێن وەرزی هاتنە وەرگرتن', '+10 coins and +50 season points added', 'أُضيفت +10 عملات و+50 نقطة', '+10 سکه و +50 امتیاز فصل اضافه شد', '+10 coin ve +50 sezon puanı eklendi'],
  'y_s': ['هێزی نهێنی دوێنێ ئاشکرا کرا', 'هێزا نهێنی یا دهی هاتە ئاشکراکرن', 'Yesterday\'s secret power revealed', 'تم كشف القوة السرية للأمس', 'قدرت مخفی دیروز فاش شد', 'Dünün gizli gücü açıklandı'],
  'y_second': ['هێزی دووەم', 'هێزا دووێ', 'Second power', 'القوة الثانية', 'قدرت دوم', 'İkinci güç'],
  'y_t': ['ئەنجامی دوێنێ', 'ئەنجامێ دهی', 'Yesterday\'s result', 'نتيجة الأمس', 'نتیجه دیروز', 'Dünün sonucu'],
  'y_wrong': ['پێشبینیی تۆ {0} بوو', 'پێشبینیا تە {0} بوو', 'You guessed {0}', 'كان تخمينك {0}', 'حدس شما {0} بود', 'Tahminin {0} idi'],
  'y_wrong_s': ['ئەمڕۆ دووبارە هەوڵ بدەرەوە', 'ئەڤرۆ دووبارە هەوڵ بدە', 'Try again today', 'حاول مجدداً اليوم', 'امروز دوباره امتحان کن', 'Bugün tekrar dene'],
  'you': ['تۆ', 'تو', 'You', 'أنت', 'شما', 'Sen'],
  'you_t': ['تۆ لە وەرزدا', 'تو د وەرزی دا', 'You this season', 'أنت في الموسم', 'شما در این فصل', 'Bu sezon sen'],
};
