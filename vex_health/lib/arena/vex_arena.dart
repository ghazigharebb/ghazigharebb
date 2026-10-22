// =============================================================================
//  VEX Arena — پێشبڕکێی تەندروستی
//  هەموو بەشی VEX Arena لە یەک فایلدا (Flutter)، هاوتای وەشانی وێبی VEX Health
//
//  ناوەڕۆک:
//   1. ڕەنگ و ستایل
//   2. بەشەکانی تەندروستی (11 بەش) + خاڵ + هێزی نهێنی
//   3. پەیوەندی بە بەشەکانی تری ئەپ  (ArenaHost)
//   4. هەژمار: لیگ، پلە، ئاست، یاریزانەکان، دیزاینی کارت، نازناو
//   5. پاشەکەوتکردن (ArenaStore — shared_preferences)
//   6. پەڕەی سەرەکی (VexArenaPage): ئەمڕۆ / پلەکان / کارتەکەم
//   7. کارتی یاریزان + جووڵەی 3D
//   8. شیتەکان: خەڵاتەکان، بەشداربوون، کارەکتەر، یاسا، یاریزان، دەستکاری...
//   9. ئەنیمەیشنی دروستبوونی کارت (3D) و کۆنفێتی
//
//  پێویستییەکان (pubspec.yaml):
//    dependencies:
//      shared_preferences: ^2.2.2
//    flutter:
//      assets:
//        - assets/chars/          # هەمان 33 کارەکتەری بەشی خێزان و هاوڕێ (00.webp ... 33.webp)
//      fonts:
//        - family: NotoAr          # Noto Sans Arabic (Regular / SemiBold 600 / Bold 700)
//
//  بەکارهێنان:
//    Navigator.push(context, MaterialPageRoute(
//      builder: (_) => VexArenaPage(host: MyArenaHost()),   // یان DemoArenaHost()
//    ));
// =============================================================================

import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/theme.dart';

// =============================================================================
// 1. ڕەنگ و ستایل
// =============================================================================

class VA {
  static Color get bg => vk(0xFF04202A);
  static Color get bg2 => vk(0xFF073241);
  static Color get surf => vk(0x9E0C3A48);
  static Color get surf2 => vk(0x0EFFFFFF);
  static Color get line => vk(0x218CEBF5);
  static Color get line2 => vk(0x428CEBF5);
  static Color get text => vk(0xFFEAFBFD);
  static Color get muted => vk(0xFF8FB4BC);
  static Color get cyan => vk(0xFF2FE6F3);
  static Color get cyanSoft => vk(0xFF8FF3F9);
  static Color get mint => vk(0xFF3CF08A);
  static Color get violet => vk(0xFF9B7BFF);
  static Color get coral => vk(0xFFFF6F86);
  static Color get amber => vk(0xFFFFBE4D);
  static Color get gold => vk(0xFFFFD56B);
  static Color get silver => vk(0xFFD9E6EE);
  static Color get bronze => vk(0xFFE29A5F);
  static Color get sheet => vk(0xFF062A35);
  static Color get ink => vk(0xFF04323A);

  static get prime => LinearGradient(
    colors: [vk(0xFF8FF3F9), vk(0xFF3CF08A)],
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
  );
  static get goldG => LinearGradient(
    colors: [vk(0xFFFFF3C4), vk(0xFFFFD56B), vk(0xFFD9971F)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

const _kFont = 'NotoAr';

Color _al(Color c, double o) => c.withAlpha((o.clamp(0.0, 1.0) * 255).round());

TextStyle _ts(double size,
        {FontWeight w = FontWeight.w400, Color? c, double? h, double? ls}) { c ??= VA.text; return
    TextStyle(
      fontFamily: _kFont,
      fontSize: size,
      fontWeight: w,
      color: c,
      height: h,
      letterSpacing: ls,
      fontFeatures: const [FontFeature.tabularFigures()],
    ); }

/// 1234567 → 1,234,567
String _fmt(num n) {
  final s = n.round().abs().toString();
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
    b.write(s[i]);
  }
  return (n < 0 ? '-' : '') + b.toString();
}

String _p2(int n) => n.toString().padLeft(2, '0');

Color _hex(String h) => Color(int.parse('FF${h.replaceAll('#', '')}', radix: 16));

// =============================================================================
// 2. بەشەکانی تەندروستی + خاڵ + هێزی نهێنی
// =============================================================================

class ArenaCat {
  final String id, name, src;
  final IconData icon;
  final Color color;
  final int max;
  const ArenaCat(this.id, this.icon, this.name, this.color, this.max, this.src);
}

List<ArenaCat> get kArenaCats => vexCache<List<ArenaCat>>('vex_arena.dart:kArenaCats', () => [
  ArenaCat('walk', Icons.directions_walk_rounded, 'پیاسە', vk(0xFF3CF08A), 60, 'هەنگاوی Band + لێدانی دڵ'),
  ArenaCat('run', Icons.directions_run_rounded, 'ڕاکردن', vk(0xFFFF9466), 60, 'GPS + لێدانی دڵ + خێرایی'),
  ArenaCat('gym', Icons.fitness_center_rounded, 'وەرزش', vk(0xFFFF6F86), 60, 'خولەکی لێدانی دڵی بەرز'),
  ArenaCat('sleep', Icons.bedtime_rounded, 'خەو', vk(0xFF9B7BFF), 60, 'خەوی Band (لێدانی دڵ + جووڵە)'),
  ArenaCat('food', Icons.restaurant_rounded, 'خۆراک', vk(0xFFFFBE4D), 50, 'وێنەی ڕاستەوخۆی ژەم + AI'),
  ArenaCat('water', Icons.water_drop_rounded, 'ئاو', vk(0xFF2FB8F3), 30, 'تۆماری ئاو + ئامانج'),
  ArenaCat('heart', Icons.favorite_rounded, 'دڵ', vk(0xFFFF5F7E), 40, 'خولەک لە ناوچەی دڵی تەندروست'),
  ArenaCat('o2', Icons.air_rounded, 'ئۆکسجین', vk(0xFF4FD2E6), 20, 'لەبەرکردنی Band لە شەودا'),
  ArenaCat('calm', Icons.spa_rounded, 'ئارامی', vk(0xFFA58CFF), 40, 'کاتی سترێسی نزم + هەناسەدان'),
  ArenaCat('rec', Icons.battery_charging_full_rounded, 'چاکبوونەوە', vk(0xFF3FD69A), 40, 'HRV + خەو + لێدانی پشوو'),
  ArenaCat('body', Icons.monitor_weight_rounded, 'لەشی تەندروست', vk(0xFFE29A5F), 30, 'ڕەوتی کێشی تەندروست (هەفتانە)'),
]);

ArenaCat catById(String id) => kArenaCats.firstWhere((c) => c.id == id, orElse: () => kArenaCats.first);

const Map<String, String> kHints = {
  'walk': 'ئەمڕۆ ڕێگا درێژەکان دەدرەوشێنەوە',
  'run': 'ئەمڕۆ خێرایی گرنگە',
  'gym': 'ئەمڕۆ ماسولکەکان قسە دەکەن',
  'sleep': 'نهێنیی ئەمڕۆ لە تاریکیدایە',
  'food': 'ئەمڕۆ قاپەکەت چیرۆکێک دەگێڕێتەوە',
  'water': 'ئەمڕۆ ڕووبارێک لە ناوتدایە',
  'heart': 'ئەمڕۆ گوێ لە لێدانەکانت بگرە',
  'o2': 'ئەمڕۆ هەناسەیەکی قووڵ هەڵبکێشە',
  'calm': 'ئەمڕۆ هێمنی هێزە',
  'rec': 'ئەمڕۆ پشوو هێزت پێدەدات',
  'body': 'ئەمڕۆ هاوسەنگی دەباتەوە',
};

/// FNV-1a — هەمان hashـی وەشانی وێب، بۆ ئەوەی هێزی ڕۆژ لە هەموو ئامێرێک یەک بێت
int _fnv(String s) {
  var h = 2166136261;
  for (final c in s.runes) {
    h ^= c;
    h = (h * 16777619) & 0xFFFFFFFF;
  }
  return h;
}

/// کلیلی ڕۆژ بۆ هێزی نهێنی (بێ سفر، وەک وێب): 2026-10-16
String arenaDayKey(DateTime d) => '${d.year}-${d.month}-${d.day}';

/// کلیلی ڕۆژ بۆ داتا (بە سفر): 2026-10-16
String dataDayKey(DateTime d) => '${d.year}-${_p2(d.month)}-${_p2(d.day)}';

// لە ئەپی ڕاستەقینەدا هێزی ڕۆژ تا نیوەشەو تەنها لە سێرڤەرە
String powerOf(String k) => kArenaCats[_fnv('vex-power-$k') % kArenaCats.length].id;

String secondOf(String k) {
  final a = powerOf(k);
  var i = _fnv('vex-2nd-$k') % kArenaCats.length;
  if (kArenaCats[i].id == a) i = (i + 1) % kArenaCats.length;
  return kArenaCats[i].id;
}

class PointRow {
  final ArenaCat cat;
  final int base, pts;
  final double mul;
  const PointRow(this.cat, this.base, this.mul, this.pts);
}

class DayPoints {
  final List<PointRow> rows;
  final int total;
  final String power, second;
  const DayPoints(this.rows, this.total, this.power, this.second);
  PointRow row(String id) => rows.firstWhere((r) => r.cat.id == id);
}

const int kDailyCap = 600;

DayPoints dayPoints(Map<String, double> f, String key) {
  final p = powerOf(key), s2 = secondOf(key);
  final rows = kArenaCats.map((c) {
    final base = (c.max * math.min(f[c.id] ?? 0, 1.0)).round();
    final m = c.id == p ? 3.0 : c.id == s2 ? 1.5 : 1.0;
    return PointRow(c, base, m, (base * m).round());
  }).toList();
  final tot = math.min(kDailyCap, rows.fold<int>(0, (a, r) => a + r.pts));
  return DayPoints(rows, tot, p, s2);
}

// =============================================================================
// 3. پەیوەندی بە بەشەکانی تری ئەپ
//    ئەپەکەت ArenaHost دروست دەکات و داتای ڕاستەقینە دەداتێ:
//    هەنگاو و دڵ و خەو (Band)، وەرزش (بەشی وەرزش)، ژەم و ئاو و کێش (بەشی خواردن)
// =============================================================================

class ArenaSportSession {
  /// هەمان ناسنامەی بەشی وەرزش: run, walk, hike, treadmill, tri, football, gym, swim ...
  final String sportId;
  final int minutes;
  final double distanceKm;
  final int steps;

  /// چرکە لە هەر 5 ناوچەی لێدانی دڵ
  final List<int> hrZoneSec;
  const ArenaSportSession({
    required this.sportId,
    required this.minutes,
    this.distanceKm = 0,
    this.steps = 0,
    this.hrZoneSec = const [0, 0, 0, 0, 0],
  });
}

class ArenaMeal {
  final String name;
  final int kcal;

  /// good / ok / bad — نمرەی AIـی بەشی خواردن
  final String quality;
  const ArenaMeal(this.name, this.kcal, this.quality);
}

class ArenaWeight {
  final DateTime day;
  final double kg;
  const ArenaWeight(this.day, this.kg);
}

/// زانیاریی پڕۆفایل کە لە سەرەتای ئەپەکەدا تۆمار کراوە
class ArenaProfile {
  final String name, phone;
  final int age;

  /// lose / gain / keep
  final String weightGoal;
  const ArenaProfile({this.name = '', this.phone = '', this.age = 0, this.weightGoal = ''});
}

class ArenaDayInputs {
  /// هەنگاوی Band (بێ هەنگاوی وەرزشەکان — Arena خۆی زیادیان دەکات)
  final int bandSteps;
  final double sleepHours;
  final int spo2, stress, hrv;
  final List<ArenaSportSession> sessions;
  final List<ArenaMeal> meals;
  final int waterGlasses, waterGoalGlasses;
  final List<ArenaWeight> weights;
  const ArenaDayInputs({
    this.bandSteps = 0,
    this.sleepHours = 0,
    this.spo2 = 0,
    this.stress = 50,
    this.hrv = 0,
    this.sessions = const [],
    this.meals = const [],
    this.waterGlasses = 0,
    this.waterGoalGlasses = 8,
    this.weights = const [],
  });
}

/// ئەم کلاسە لە ئەپەکەتدا دابنێ و بە بەشەکانی ترەوە بیبەستەوە
abstract class ArenaHost {
  ArenaProfile get profile;

  /// داتای ئەمڕۆ
  ArenaDayInputs today();

  /// داتای دوێنێ (بۆ «هێزی دوێنێ»)
  ArenaDayInputs yesterday();

  /// کاتێک داتا دەگۆڕێت (وەرزشێکی نوێ، پەرداخێک ئاو، ژەمێک...) notify بکە
  Listenable? get changes;

  /// «بڕۆ بۆ بەشی ...»: walk→هەنگاو، run/gym→وەرزش، sleep→خەو، food/water/body→خواردن،
  /// heart→دڵ، o2→ئۆکسجین، calm→سترێس، rec→تەندروستی
  void openSection(BuildContext context, String catId);

  /// سکەکانی Arena لەگەڵ بەشی وەرزش هاوبەشن (خەڵاتی وەرزش سکە دەدات)
  int takePendingCoins() => 0;
}

/// داتای نموونە — هەمان ژمارەکانی شاشەی سەرەکی و تەندروستی تا Band دەبەسترێت
class DemoArenaHost extends ArenaHost {
  final ChangeNotifier _n = ChangeNotifier();
  @override
  ArenaProfile get profile => const ArenaProfile(name: 'غازی غەریب', phone: '07501234567', age: 28, weightGoal: 'lose');
  @override
  ArenaDayInputs today() => ArenaDayInputs(
        bandSteps: 2225,
        sleepHours: 6.3,
        spo2: 93,
        stress: 55,
        hrv: 54,
        sessions: const [
          ArenaSportSession(sportId: 'run', minutes: 25, distanceKm: 4.2, steps: 4000, hrZoneSec: [60, 300, 600, 400, 100]),
        ],
        meals: const [ArenaMeal('هێلکە و نان', 256, 'good'), ArenaMeal('برنج و شلە', 650, 'ok')],
        waterGlasses: 5,
        waterGoalGlasses: 11,
        weights: [
          ArenaWeight(DateTime.now().subtract(const Duration(days: 12)), 78.4),
          ArenaWeight(DateTime.now(), 77.6),
        ],
      );
  @override
  ArenaDayInputs yesterday() => const ArenaDayInputs(
        bandSteps: 7800,
        sleepHours: 7.6,
        spo2: 96,
        stress: 50,
        hrv: 56,
        sessions: [ArenaSportSession(sportId: 'run', minutes: 15, distanceKm: 2.5, hrZoneSec: [0, 200, 500, 200, 0])],
        meals: [ArenaMeal('ژەم', 500, 'good'), ArenaMeal('ژەم', 600, 'ok')],
        waterGlasses: 9,
        waterGoalGlasses: 11,
      );
  @override
  Listenable? get changes => _n;
  @override
  void openSection(BuildContext context, String catId) => _toast(context, 'لە ئەپەکەدا بەشی ${catById(catId).name} دەکرێتەوە');
}

/// نرخ و ڕێژەی هەر بەشێک بۆ ئەمڕۆ (هەمان یاسای وەشانی وێب)
class CatValue {
  final String v;
  final double f;
  const CatValue(this.v, this.f);
}

const _runIds = {'run', 'treadmill', 'tri'};
const _walkIds = {'walk', 'hike'};

Map<String, CatValue> computeDay(ArenaDayInputs d, ArenaProfile u) {
  var runM = 0, gymM = 0, spSteps = 0;
  var runKm = 0.0;
  final zt = [0, 0, 0, 0, 0];
  for (final h in d.sessions) {
    spSteps += h.steps;
    if (_runIds.contains(h.sportId)) {
      runM += h.minutes;
      runKm += h.distanceKm;
    } else if (!_walkIds.contains(h.sportId)) {
      gymM += h.minutes;
    }
    for (var i = 0; i < 5 && i < h.hrZoneSec.length; i++) {
      zt[i] += h.hrZoneSec[i];
    }
  }
  // هەمان یاسای شاشەی سەرەکی: هەنگاوی Band + هەنگاوی وەرزشەکانی ئەمڕۆ
  final steps = d.bandSteps + spSteps;
  var q = 0.0, kcal = 0;
  for (final m in d.meals) {
    kcal += m.kcal;
    q += m.quality == 'good' ? 1 : m.quality == 'bad' ? .3 : .7;
  }
  final meals = d.meals.length;
  final wG = math.max(6, d.waterGoalGlasses);
  final hz = ((zt[1] + zt[2] + zt[3]) / 60).round();
  final sl = d.sleepHours;

  var body = const CatValue('کێشەکەت تۆمار بکە', 0);
  if (d.weights.isNotEmpty) {
    final w = [...d.weights]..sort((a, b) => a.day.compareTo(b.day));
    final last = w.last;
    final from = DateTime.now().subtract(const Duration(days: 14));
    final old = w.firstWhere((x) => !x.day.isBefore(from), orElse: () => w.first);
    final dl = last.kg - old.kg;
    final want = u.weightGoal == 'lose' ? -1 : u.weightGoal == 'gain' ? 1 : 0;
    double f;
    if (w.length < 2) {
      f = .33;
    } else if (want == 0) {
      f = dl.abs() < 1 ? .9 : .4;
    } else {
      f = (dl.sign == want && dl.abs() <= 1.5) ? 1.0 : dl.abs() < .3 ? .5 : .2;
    }
    final ch = w.length > 1 && dl.abs() >= .1 ? ' · ${dl > 0 ? '+' : '−'}${dl.abs().toStringAsFixed(1)}' : '';
    body = CatValue('${last.kg.toStringAsFixed(1)} کگ$ch', f);
  }

  return {
    'walk': CatValue('${_fmt(steps)} هەنگاو', math.min(1.0, steps / 10000)),
    'run': CatValue(runM > 0 ? '$runM خولەک${runKm >= .05 ? ' · ${runKm.toStringAsFixed(1)} کم' : ''}' : 'هێشتا نییە', math.min(1.0, runM / 30)),
    'gym': CatValue(gymM > 0 ? '$gymM خولەک' : 'هێشتا نییە', math.min(1.0, gymM / 45)),
    'sleep': CatValue(sl > 0 ? '${sl.floor()}:${_p2((sl % 1 * 60).round())} کاتژمێر' : 'تۆمار نەکراوە', math.min(1.0, sl / 8)),
    'food': CatValue(meals > 0 ? '$meals ژەم · ${_fmt(kcal)} کالۆری' : 'هێشتا نییە',
        meals > 0 ? math.min(1.0, meals / 3) * .5 + (q / meals) * .5 : 0.0),
    'water': CatValue('${d.waterGlasses}/$wG پەرداخ', math.min(1.0, d.waterGlasses / wG)),
    'heart': CatValue(hz > 0 ? '$hz خولەک' : 'هێشتا نییە', math.min(1.0, hz / 20)),
    'o2': CatValue(d.spo2 > 0 ? '${d.spo2}%' : 'تۆمار نەکراوە', d.spo2 >= 95 ? 1.0 : math.max(0.0, (d.spo2 - 88) / 7)),
    'calm': CatValue('سترێس ${d.stress}', ((100 - d.stress) / 70).clamp(0, 1).toDouble()),
    'rec': CatValue('HRV ${d.hrv}', math.min(1.0, d.hrv / 70)),
    'body': body,
  };
}

Map<String, double> _fractions(Map<String, CatValue> m) => m.map((k, v) => MapEntry(k, v.f));

// =============================================================================
// 4. لیگ، پلە، ئاست، یاریزانەکان، دیزاینی کارت، نازناو
// =============================================================================

class League {
  final int min, idx;
  final String name;
  final Color accent, c1, c2;
  const League(this.min, this.idx, this.name, this.accent, this.c1, this.c2);
}

List<League> get kLeagues => vexCache<List<League>>('vex_arena.dart:kLeagues', () => [
  League(0, 0, 'برۆنز', vk(0xFFE29A5F), vk(0xFF5A3417), vk(0xFFA8642F)),
  League(600, 1, 'زیو', vk(0xFFD9E6EE), vk(0xFF4A5866), vk(0xFF9FB1BF)),
  League(1500, 2, 'ئاڵتوون', vk(0xFFFFD56B), vk(0xFF6B4A0A), vk(0xFFD9A21F)),
  League(3000, 3, 'پلاتین', vk(0xFF7FE7FF), vk(0xFF0B4D5C), vk(0xFF2BB5C9)),
  League(5000, 4, 'ئەڵماس', vk(0xFFB9A6FF), vk(0xFF2A1A6E), vk(0xFF7B5CFF)),
  League(7500, 5, 'VEX Legend', vk(0xFFFF6F86), vk(0xFF5A0F22), vk(0xFFD62F55)),
]);

League leagueOf(num p) {
  var l = kLeagues.first;
  for (final x in kLeagues) {
    if (p >= x.min) l = x;
  }
  return l;
}

int levelOf(num p) => math.sqrt(p / 25).floor() + 1;
int levelStart(int l) => 25 * (l - 1) * (l - 1);

class Season {
  static const int number = 1, length = 30, needDays = 25;
  final int day, total;
  final DateTime end;
  const Season(this.day, this.total, this.end);
}

int rankOf(num p, Season s) =>
    math.max(1, math.min(s.total, (-2600 * math.log(math.max(p, 1) / 7800)).round() + 1));
double ptsAt(int r) => 7800 * math.exp(-(r - 1) / 2600);
int ratingOf(num p) => math.min(99, (52 + math.log(math.max(p, 50) / 50) * 9).round());

const kCities = ['هەولێر', 'سلێمانی', 'دهۆک', 'کەرکووک', 'هەڵەبجە', 'زاخۆ', 'ڕانیە', 'کۆیە', 'سۆران', 'چەمچەماڵ'];
const kAllCities = [
  'هەولێر', 'سلێمانی', 'دهۆک', 'کەرکووک', 'هەڵەبجە', 'زاخۆ', 'ڕانیە', 'کۆیە', 'سۆران', 'چەمچەماڵ',
  'ئاکرێ', 'ئامێدی', 'شێخان', 'سمێل', 'سەرسەنگ', 'بەردەڕەش', 'دیانا', 'ڕواندز', 'شەقڵاوە', 'مێرگەسور',
  'پشدەر', 'قەڵادزێ', 'بێتواتە', 'پێنجوێن', 'سیتەک', 'سەیدسادق', 'دەربەندیخان', 'کەلار', 'کفری', 'خانەقین',
  'جەلەولا', 'قەرەتەپە', 'تاقتاق', 'دووکان', 'دەبەگ', 'حەویجە', 'مەخموور', 'شنگال', 'تەلعەفەر', 'خورماتوو',
  'تۆزخورماتوو', 'بەعشیقە', 'تەلکێف', 'عەقرە', 'زێباری', 'قۆشتەپە', 'مەهاباد', 'سنە', 'کرماشان', 'ورمێ',
  'بانە', 'مەریوان', 'سەقز', 'بۆکان', 'پیرانشار', 'نەغەدە', 'ئیلام', 'دیاربەکر', 'وان', 'ماردین', 'باتمان',
  'هەکاری', 'جزیر', 'ئورفە', 'قامیشلۆ', 'کۆبانی', 'عەفرین', 'دێرک', 'عامودا', 'حەسەکە', 'سەرێکانی', 'تەبریز',
  'تاران', 'هەمەدان',
];

const kAges = [
  ['y', '12-17'],
  ['a', '18-39'],
  ['m', '40-59'],
  ['s', '60+'],
];
String ageGroup(int age) => age < 18 ? 'y' : age < 40 ? 'a' : age < 60 ? 'm' : 's';

class ArenaPlayer {
  final String name, city, age, fav, skin, bio, ch;
  final int points, move, streak, guess;
  final List<Color> grad;
  int rank = 0;
  ArenaPlayer({
    required this.name,
    required this.city,
    required this.age,
    required this.points,
    required this.move,
    required this.grad,
    required this.streak,
    required this.guess,
    required this.fav,
    required this.skin,
    required this.bio,
    required this.ch,
  });
}

/// یاریزانی نموونە — هەمان هاوکێشەی وێب (seed 11) بۆ ئەوەی هەمان ناوەکان دەربکەون
/// لە ئەپی ڕاستەقینەدا لە سێرڤەرەوە دێن
List<ArenaPlayer> buildPlayers() {
  var seed = 11;
  double rnd() {
    seed = (seed * 16807) % 2147483647;
    return seed / 2147483647;
  }

  T pick<T>(List<T> a) => a[(rnd() * a.length).floor()];
  const fn = ['ئاراس', 'هێمن', 'دانا', 'ڕێبین', 'سارا', 'ڤیان', 'ئاوات', 'شادی', 'کارزان', 'هاوژین', 'نیگار', 'بەرزان', 'ژیلا', 'ئازاد', 'لانە', 'سۆران', 'ڕۆژان', 'هەڵۆ', 'چنار', 'بڕوا', 'پەیام', 'شیلان', 'دیار', 'هێرۆ', 'ئاکۆ', 'ناز', 'زانا', 'گوڵاڵە', 'ڕێکار', 'بەفرین'];
  const ln = ['ک.', 'م.', 'ع.', 'ح.', 'س.', 'ڕ.', 'ب.', 'ج.'];
  final gr = [
    [_hex('2b5876'), _hex('4e4376')],
    [_hex('0f9b8e'), _hex('1d4e89')],
    [_hex('c94b4b'), _hex('4b134f')],
    [_hex('d38312'), _hex('a83279')],
    [_hex('1d976c'), _hex('2c3e50')],
    [_hex('614385'), _hex('516395')],
    [_hex('e65c00'), _hex('9b2c2c')],
    [_hex('2193b0'), _hex('3a1c71')],
  ];
  const skins = ['auto', 'auto', 'neon', 'kurd', 'night', 'newroz'];
  const bios = ['هەموو ڕۆژێک 10 هەزار هەنگاو', 'بۆ تەندروستیی خێزانەکەم', 'ڕاکەری بەیانیان', 'تەمەن تەنها ژمارەیەکە', 'خەوی باش نهێنییەکەیە'];
  final cityList = kCities.toList();
  final ageList = kAges.map((e) => e[0]).toList();
  final list = <ArenaPlayer>[];
  for (var k = 0; k < 60; k++) {
    final f = pick(fn);
    final p = (7800 * math.exp(-(k + 1) / 2600) * (0.985 + rnd() * 0.03)).round();
    final n = '$f ${pick(ln)}';
    final city = pick(cityList);
    final age = pick(ageList);
    final mv = ((rnd() - 0.4) * 8).round();
    final g = pick(gr);
    final streak = (4 + rnd() * 8).floor();
    final guess = (rnd() * 9).floor();
    final fav = pick(kArenaCats).id;
    final sk = pick(skins);
    final bio = pick(bios);
    list.add(ArenaPlayer(
      name: n, city: city, age: age, points: p, move: mv, grad: g, streak: streak, guess: guess,
      fav: fav, skin: sk, bio: bio, ch: kCharIds[k % kCharIds.length],
    ));
  }
  list.sort((a, b) => b.points.compareTo(a.points));
  for (var i = 0; i < list.length; i++) {
    list[i].rank = i + 1;
  }
  return list;
}

/// کارەکتەرەکان — هەمان 33 وێنەی بەشی خێزان و هاوڕێ
const List<String> kCharIds = [
  '00', '01', '02', '03', '04', '05', '06', '07', '08', '09', '10', '11', '12', '13', '14', '15', '16',
  '17', '18', '19', '20', '21', '22', '23', '24', '25', '26', '27', '29', '30', '31', '32', '33',
];
String charAsset(String id) => 'assets/chars/$id.webp';

enum SkinPattern { none, grid, stars, kurd, fire, diamond, gloss }

class CardSkin {
  final String id, name;
  final int cost;

  /// پێویستی بە لیگ (ئیندێکس) — 0 واتە نییە
  final int league;
  final Color? c1, c2, accent;
  final SkinPattern pattern;
  const CardSkin(this.id, this.name,
      {this.cost = 0, this.league = 0, this.c1, this.c2, this.accent, this.pattern = SkinPattern.none});
}

List<CardSkin> get kSkins => vexCache<List<CardSkin>>('vex_arena.dart:kSkins', () => [
  CardSkin('auto', 'لیگەکەم', pattern: SkinPattern.gloss),
  CardSkin('neon', 'نیۆنی VEX', cost: 120, c1: vk(0xFF05313D), c2: vk(0xFF0B5160), accent: vk(0xFF2FE6F3), pattern: SkinPattern.grid),
  CardSkin('night', 'شەوی ئەستێرە', cost: 160, c1: vk(0xFF0B1033), c2: vk(0xFF1D2B6B), accent: vk(0xFF9B7BFF), pattern: SkinPattern.stars),
  CardSkin('kurd', 'نەخشی کوردی', cost: 220, c1: vk(0xFF5A1414), c2: vk(0xFF8A2B1C), accent: vk(0xFFFFD56B), pattern: SkinPattern.kurd),
  CardSkin('newroz', 'ئاگری نەورۆز', cost: 260, c1: vk(0xFF3A0D05), c2: vk(0xFFA8320C), accent: vk(0xFFFFBE4D), pattern: SkinPattern.fire),
  CardSkin('gold', 'ئاڵتوونی', league: 2, c1: vk(0xFF6B4A0A), c2: vk(0xFFE6B13A), accent: vk(0xFFFFD56B), pattern: SkinPattern.gloss),
  CardSkin('dia', 'ئەڵماس', league: 4, c1: vk(0xFF1D1250), c2: vk(0xFF6A4FE0), accent: vk(0xFFD6C8FF), pattern: SkinPattern.diamond),
]);

CardSkin skinById(String id) => kSkins.firstWhere((s) => s.id == id, orElse: () => kSkins.first);

class SkinColors {
  final Color c1, c2, accent;
  final SkinPattern pattern;
  const SkinColors(this.c1, this.c2, this.accent, this.pattern);
}

SkinColors skinColors(String id, num points) {
  final s = skinById(id);
  if (s.id == 'auto') {
    final l = leagueOf(points);
    return SkinColors(l.c1, l.c2, l.accent, SkinPattern.gloss);
  }
  return SkinColors(s.c1!, s.c2!, s.accent!, s.pattern);
}

class ArenaTitle {
  final String id, name;

  /// 0 ئازاد · 1 یەکەم پێشبینیی ڕاست · 5 لیگی Legend
  final int req;
  final IconData icon;
  const ArenaTitle(this.id, this.name, this.req, this.icon);
}

const List<ArenaTitle> kTitles = [
  ArenaTitle('t0', 'وەرزشکاری نوێ', 0, Icons.rocket_launch_rounded),
  ArenaTitle('t1', 'پاشای خەو', 0, Icons.bedtime_rounded),
  ArenaTitle('t2', 'ڕاکەری بەیانیان', 0, Icons.directions_run_rounded),
  ArenaTitle('t3', 'پێشبینیکەری بلیمەت', 1, Icons.auto_awesome_rounded),
  ArenaTitle('t4', 'شێری هەولێر', 0, Icons.flag_rounded),
  ArenaTitle('t5', 'ئەفسانەی VEX', 5, Icons.workspace_premium_rounded),
];

String titleName(String id) => kTitles.firstWhere((t) => t.id == id, orElse: () => kTitles.first).name;

const kStatNames = ['پیاسە', 'ڕاکردن', 'خەو', 'خۆراک', 'دڵ', 'ئارامی'];
const kStatIds = ['walk', 'run', 'sleep', 'food', 'heart', 'calm'];

String maskPhone(String p) => p.length == 11 ? '${p.substring(0, 4)} *** ${p.substring(7)}' : '';

String normPhone(String v) {
  const ar = '٠١٢٣٤٥٦٧٨٩';
  var d = v.split('').map((c) {
    final i = ar.indexOf(c);
    return i >= 0 ? '$i' : c;
  }).join();
  d = d.replaceAll(RegExp(r'[^\d+]'), '');
  if (d.startsWith('+964')) d = '0${d.substring(4)}';
  if (d.startsWith('00964')) d = '0${d.substring(5)}';
  if (d.startsWith('964')) d = '0${d.substring(3)}';
  if (d.length == 10 && d.startsWith('7')) d = '0$d';
  return d;
}

// =============================================================================
// 5. پاشەکەوتکردن
// =============================================================================

class ArenaAccount {
  String name, city, age, phone;
  final int joinDay;
  ArenaAccount({required this.name, required this.city, required this.age, required this.phone, required this.joinDay});
  Map<String, dynamic> toJson() => {'name': name, 'city': city, 'age': age, 'phone': phone, 'day': joinDay};
  static ArenaAccount? fromJson(dynamic o) {
    if (o is! Map) return null;
    return ArenaAccount(
      name: '${o['name'] ?? ''}',
      city: '${o['city'] ?? kCities.first}',
      age: '${o['age'] ?? 'a'}',
      phone: '${o['phone'] ?? ''}',
      joinDay: (o['day'] as num?)?.toInt() ?? 1,
    );
  }
}

class ArenaStore extends ChangeNotifier {
  static const _key = 'vex_arena_v3';
  static const _famKey = 'vex_family_v1'; // کارەکتەری «تۆ» لە بەشی خێزان
  static const _meChKey = 'vex_me_ch';

  ArenaAccount? acc;
  String skin = 'auto', title = 't0', bio = 'بۆ تەندروستی', ch = '';
  int coins = 340, season = 2140, bestPower = 0;
  Set<String> owned = {};
  Map<String, String> guess = {};
  Set<String> revealed = {};
  DateTime? seasonEnd;
  bool loaded = false;

  Season get seasonInfo => Season(12, 12847, seasonEnd ?? DateTime.now().add(const Duration(days: 18, hours: 7)));

  Future<void> load() async {
    try {
      final sp = await SharedPreferences.getInstance();
      final s = sp.getString(_key);
      if (s != null) {
        final o = jsonDecode(s);
        if (o is Map && o['v'] == 3) {
          acc = ArenaAccount.fromJson(o['acc']);
          skin = '${o['skin'] ?? 'auto'}';
          title = '${o['title'] ?? 't0'}';
          bio = '${o['bio'] ?? bio}';
          ch = '${o['ch'] ?? ''}';
          coins = (o['coins'] as num?)?.toInt() ?? 340;
          season = (o['season'] as num?)?.toInt() ?? 2140;
          bestPower = (o['bestPower'] as num?)?.toInt() ?? 0;
          owned = ((o['owned'] as List?) ?? const []).map((e) => '$e').toSet();
          guess = ((o['guess'] as Map?) ?? const {}).map((k, v) => MapEntry('$k', '$v'));
          revealed = ((o['rev'] as List?) ?? const []).map((e) => '$e').toSet();
          final se = o['seasonEnd'];
          if (se is num) seasonEnd = DateTime.fromMillisecondsSinceEpoch(se.toInt());
        }
      }
      seasonEnd ??= DateTime.now().add(const Duration(days: 18, hours: 7));
      if (ch.isEmpty) {
        ch = sp.getString(_meChKey) ?? '';
        final f = sp.getString(_famKey);
        if (ch.isEmpty && f != null) {
          final o = jsonDecode(f);
          if (o is Map && o['meCh'] is String) ch = o['meCh'] as String;
        }
      }
    } catch (_) {}
    loaded = true;
    notifyListeners();
  }

  Future<void> save() async {
    notifyListeners();
    try {
      final sp = await SharedPreferences.getInstance();
      await sp.setString(
          _key,
          jsonEncode({
            'v': 3,
            'acc': acc?.toJson(),
            'skin': skin,
            'title': title,
            'bio': bio,
            'ch': ch,
            'coins': coins,
            'season': season,
            'bestPower': bestPower,
            'owned': owned.toList(),
            'guess': guess,
            'rev': revealed.toList(),
            'seasonEnd': seasonEnd?.millisecondsSinceEpoch,
          }));
    } catch (_) {}
  }

  /// هەمان کارەکتەر لە بەشی خێزان و هاوڕێش دادەنرێت
  Future<void> setCharacter(String id) async {
    ch = id;
    await save();
    try {
      final sp = await SharedPreferences.getInstance();
      await sp.setString(_meChKey, id);
      final f = sp.getString(_famKey);
      if (f != null) {
        final o = jsonDecode(f);
        if (o is Map) {
          final m = Map<String, dynamic>.from(o);
          m['meCh'] = id;
          await sp.setString(_famKey, jsonEncode(m));
        }
      }
    } catch (_) {}
  }

  Future<void> logout() async {
    acc = null;
    skin = 'auto';
    title = 't0';
    bio = 'بۆ تەندروستی';
    coins = 340;
    season = 2140;
    bestPower = 0;
    owned = {};
    guess = {};
    revealed = {};
    await save();
  }
}

// =============================================================================
// 6. پەڕەی سەرەکی
// =============================================================================

class VexArenaPage extends StatefulWidget {
  final ArenaHost host;
  final ArenaStore? store;
  const VexArenaPage({super.key, required this.host, this.store});
  @override
  State<VexArenaPage> createState() => _VexArenaPageState();
}

class _VexArenaPageState extends State<VexArenaPage> {
  late final ArenaStore st = widget.store ?? ArenaStore();
  late final List<ArenaPlayer> players = buildPlayers();
  String tab = 'today', lb = 'all';
  int shown = 11;
  late Map<String, CatValue> data;
  late DayPoints today, yest;
  late String tk, yk;
  Timer? _poll;
  final _scroll = ScrollController();
  int _cardDrop = 0;

  @override
  void initState() {
    super.initState();
    _compute();
    if (!st.loaded) st.load();
    st.addListener(_onStore);
    widget.host.changes?.addListener(_refresh);
    _poll = Timer.periodic(const Duration(seconds: 20), (_) => _refresh());
  }

  @override
  void dispose() {
    _poll?.cancel();
    st.removeListener(_onStore);
    widget.host.changes?.removeListener(_refresh);
    _scroll.dispose();
    super.dispose();
  }

  void _onStore() {
    if (mounted) setState(() {});
  }

  void _compute() {
    final now = DateTime.now();
    tk = arenaDayKey(now);
    yk = arenaDayKey(now.subtract(const Duration(days: 1)));
    data = computeDay(widget.host.today(), widget.host.profile);
    today = dayPoints(_fractions(data), tk);
    yest = dayPoints(_fractions(computeDay(widget.host.yesterday(), widget.host.profile)), yk);
  }

  void _refresh() {
    if (!mounted) return;
    final c = widget.host.takePendingCoins();
    if (c > 0) {
      st.coins += c;
      st.save();
    }
    setState(_compute);
  }

  // ---- هەژمار ----
  bool get won => st.revealed.contains(tk) && st.guess[tk] == today.power;
  int get myTotal => st.season + today.total + (won ? 50 : 0);
  Season get season => st.seasonInfo;
  int get activeDays => st.acc == null ? 0 : math.max(1, season.day - st.acc!.joinDay + 1);

  List<List<Object>> myStats() {
    final yf = _fractions(computeDay(widget.host.yesterday(), widget.host.profile));
    return List.generate(6, (i) {
      final id = kStatIds[i];
      final v = (45 + ((yf[id] ?? 0) * .6 + (data[id]?.f ?? 0) * .4) * 50).round();
      return [kStatNames[i], math.min(99, v)];
    });
  }

  CardData myCard() => CardData(
        name: st.acc?.name ?? 'ناوی تۆ',
        city: st.acc?.city ?? 'شارەکەت',
        ch: st.ch,
        points: myTotal,
        skin: st.skin,
        title: titleName(st.title),
        stats: myStats(),
        rank: rankOf(myTotal, season),
        grad: [vk(0xFF0F9B8E), vk(0xFF1D4E89)],
      );

  bool skinOwned(CardSkin s) =>
      (s.cost == 0 && s.league == 0) || st.owned.contains('skin:${s.id}') || (s.league > 0 && leagueOf(myTotal).idx >= s.league);

  void _go(String t) {
    if (t == tab) return;
    HapticFeedback.selectionClick();
    setState(() => tab = t);
    if (_scroll.hasClients) _scroll.animateTo(0, duration: const Duration(milliseconds: 350), curve: Curves.easeOut);
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: VA.bg,
        body: Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(0, -1.1),
              radius: 1.3,
              colors: [vk(0xFF0B4556), VA.bg],
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: !st.loaded
                ? Center(child: CircularProgressIndicator(color: VA.cyan))
                : ListView(
                    controller: _scroll,
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 40),
                    children: [
                      _header(),
                      const SizedBox(height: 12),
                      _PrizeTicker(daysLeft: season.end.difference(DateTime.now()).inDays, onTap: _openPrizes),
                      const SizedBox(height: 12),
                      _Seg(
                        items: const [
                          ['today', 'ئەمڕۆ', Icons.bolt_rounded],
                          ['rank', 'پلەکان', Icons.emoji_events_rounded],
                          ['card', 'کارتەکەم', Icons.star_rounded],
                        ],
                        value: tab,
                        onChanged: _go,
                      ),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 320),
                        transitionBuilder: (c, a) => FadeTransition(
                          opacity: a,
                          child: SlideTransition(
                              position: Tween(begin: const Offset(0, .03), end: Offset.zero).animate(a), child: c),
                        ),
                        child: KeyedSubtree(
                          key: ValueKey('$tab-${st.acc != null}'),
                          child: st.acc == null && tab != 'rank'
                              ? _joinView()
                              : tab == 'today'
                                  ? _todayView()
                                  : tab == 'rank'
                                      ? _rankView()
                                      : _cardView(),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------- header
  Widget _header() {
    final s = season;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            if (Navigator.of(context).canPop())
              _IconBtn(icon: Icons.chevron_right_rounded, onTap: () => Navigator.of(context).maybePop()),
            if (Navigator.of(context).canPop()) const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('پێشبڕکێ', style: _ts(24, w: FontWeight.w700)),
                  Text('وەرزی ${Season.number} · ڕۆژی ${s.day} لە ${Season.length}', style: _ts(12.5, c: VA.muted, w: FontWeight.w600)),
                ],
              ),
            ),
            _CoinPill(coins: st.coins),
            const SizedBox(width: 8),
            _IconBtn(icon: Icons.help_outline_rounded, onTap: () => _sheet(const _HowSheet())),
          ],
        ),
        const SizedBox(height: 10),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
            decoration: BoxDecoration(color: VA.surf2, borderRadius: BorderRadius.circular(99), border: Border.all(color: VA.line)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.groups_rounded, size: 15, color: VA.muted),
              const SizedBox(width: 5),
              Text(_fmt(s.total + (st.acc != null ? 1 : 0)), style: _ts(12, w: FontWeight.w700)),
              const SizedBox(width: 4),
              Text('بەشداربوو', style: _ts(11.5, c: VA.muted, w: FontWeight.w700)),
            ]),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------- join
  Widget _joinView() {
    final demo = CardData(
      name: widget.host.profile.name.isNotEmpty ? widget.host.profile.name : 'ناوی تۆ',
      city: 'شارەکەت',
      ch: st.ch,
      points: 0,
      skin: 'auto',
      title: 'وەرزشکاری نوێ',
      stats: kStatNames.map((n) => <Object>[n, '??']).toList(),
      rank: season.total + 1,
      grad: [vk(0xFF0F9B8E), vk(0xFF1D4E89)],
    );
    return _Card(
      child: Column(children: [
        TiltCard(child: ArenaCardView(data: demo)),
        const SizedBox(height: 16),
        Text('کارتی وەرزشکاریی خۆت دروست بکە', textAlign: TextAlign.center, style: _ts(19, w: FontWeight.w700)),
        const SizedBox(height: 6),
        Text.rich(
          TextSpan(children: [
            const TextSpan(text: 'هەموو کارێکی تەندروست خاڵت پێدەدات: پیاسە، ڕاکردن، خەو، خۆراک، ئاو، ئارامی و زیاتر. هەموو ڕۆژێک '),
            TextSpan(text: 'هێزێکی نهێنی', style: _ts(13, c: VA.violet, w: FontWeight.w700)),
            const TextSpan(text: ' هەیە کە خاڵەکەی سێ هێندەیە، و کەس نازانێت کامەیە.'),
          ]),
          textAlign: TextAlign.center,
          style: _ts(13, c: VA.muted, h: 1.6),
        ),
        const SizedBox(height: 14),
        _Btn(label: 'بەخۆڕایی بەشدار بە', icon: Icons.rocket_launch_rounded, onTap: _openJoin),
      ]),
    );
  }

  Future<void> _openJoin() async {
    final r = await _sheet<_JoinResult>(_JoinSheet(profile: widget.host.profile));
    if (r == null || !mounted) return;
    st.acc = ArenaAccount(name: r.name, city: r.city, age: r.age, phone: widget.host.profile.phone, joinDay: season.day - 6);
    await st.save();
    if (!mounted) return;
    await Navigator.of(context).push(PageRouteBuilder<void>(
      opaque: false,
      barrierDismissible: false,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (_, __, ___) => _CardReveal(data: myCard(), league: leagueOf(myTotal)),
      transitionsBuilder: (_, a, __, c) => FadeTransition(opacity: a, child: c),
    ));
    if (!mounted) return;
    setState(() {
      tab = 'card';
      _cardDrop++;
    });
    _toast(context, 'کارتەکەت دانرا!', Icons.star_rounded);
    if (st.ch.isEmpty) {
      await Future<void>.delayed(const Duration(milliseconds: 900));
      if (mounted) _openCharPicker();
    }
  }

  // ---------------------------------------------------------------- today
  Widget _todayView() {
    final t = today, tot = myTotal, lg = leagueOf(tot), r = rankOf(tot, season), yr = rankOf(tot - t.total, season);
    final g = st.guess[tk], rev = st.revealed.contains(tk);
    final seg = (t.total / kDailyCap * 12).round();
    final streak = activeDays;
    final p = catById(t.power);
    final yg = st.guess[yk];
    final pct = 23 + _fnv(yk) % 20;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      // ---- score ----
      _Card(
        glow: true,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('خاڵی ئەمڕۆ', style: _ts(13, c: VA.muted, w: FontWeight.w600)),
                _CountUp(
                  value: t.total,
                  style: _ts(68, w: FontWeight.w800, h: 1.05),
                  shader: LinearGradient(colors: [kW, VA.cyanSoft], begin: Alignment.topCenter, end: Alignment.bottomCenter),
                ),
              ]),
            ),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('پلەکەت', style: _ts(13, c: VA.muted, w: FontWeight.w600)),
              Text('#${_fmt(r)}', style: _ts(30, w: FontWeight.w800)),
              if (yr > r)
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(color: _al(VA.mint, .14), borderRadius: BorderRadius.circular(99)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.arrow_drop_up_rounded, color: VA.mint, size: 18),
                    Text(_fmt(yr - r), style: _ts(14, c: VA.mint, w: FontWeight.w800)),
                  ]),
                ),
            ]),
          ]),
          const SizedBox(height: 12),
          Row(
            children: List.generate(
              12,
              (i) => Expanded(
                child: Container(
                  height: 9,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    gradient: i < seg ? VA.prime : null,
                    color: i < seg ? null : _al(kW, .08),
                    borderRadius: BorderRadius.circular(9),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Row(children: [
            Expanded(child: Text('سنووری ڕۆژانە', style: _ts(12.5, c: VA.muted, w: FontWeight.w600))),
            Text('${t.total} / $kDailyCap', style: _ts(12.5, c: VA.muted, w: FontWeight.w700)),
          ]),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 3.1,
            children: [
              _StatTile(label: 'کۆی وەرز', value: Text(_fmt(tot), style: _ts(19, w: FontWeight.w800))),
              _StatTile(
                  label: 'لیگ',
                  value: Row(mainAxisSize: MainAxisSize.min, children: [
                    LeagueEmblem(league: lg, size: 18),
                    const SizedBox(width: 6),
                    Text(lg.name, style: _ts(15, w: FontWeight.w800)),
                  ])),
              _StatTile(label: 'ئاست', value: Text('${levelOf(tot)}', style: _ts(19, w: FontWeight.w800))),
              _StatTile(
                  label: 'بەردەوامی',
                  value: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.local_fire_department_rounded, color: vk(0xFFFF9466), size: 18),
                    const SizedBox(width: 4),
                    Text('$streak', style: _ts(19, w: FontWeight.w800)),
                  ])),
            ],
          ),
        ]),
      ),

      // ---- mystery power ----
      _MysteryCard(
        power: t.power,
        guess: g,
        revealed: rev,
        onGuess: (id) {
          if (st.guess[tk] != null || rev) return;
          HapticFeedback.mediumImpact();
          st.guess[tk] = id;
          st.save();
          _toast(context, 'پێشبینییەکەت تۆمار کرا', Icons.lock_rounded);
        },
        onDemoReveal: () {
          st.revealed.add(tk);
          if (st.guess[tk] == today.power) {
            st.coins += 30;
            st.bestPower += 1;
            showConfetti(context);
            _toast(context, 'ڕاستت پێکا! +50 خاڵ و 30 سکە', Icons.star_rounded);
          } else {
            _toast(context, 'هێزی ئەمڕۆ ${p.name} بوو', Icons.lightbulb_rounded);
          }
          st.save();
        },
      ),

      // ---- yesterday ----
      _Card(
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            CatTile(cat: catById(yest.power), size: 52),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('ئاشکرا کرا · هێزی دوێنێ', style: _ts(12, c: VA.muted)),
                Text('${catById(yest.power).name} ×3 · ${catById(yest.second).name} ×1.5', style: _ts(15, w: FontWeight.w800)),
                Text('$pct%ی خەڵک ڕاستیان پێکا${yg != null && yg == yest.power ? ' · تۆش یەکێک بوویت' : ''}',
                    style: _ts(12, c: VA.muted)),
              ]),
            ),
          ]),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: (yest.rows.where((x) => x.pts > 0).toList()..sort((a, b) => b.pts.compareTo(a.pts)))
                .map((x) => Container(
                      padding: const EdgeInsetsDirectional.fromSTEB(4, 4, 10, 4),
                      decoration: BoxDecoration(
                          color: _al(x.cat.color, .12),
                          borderRadius: BorderRadius.circular(99),
                          border: Border.all(color: _al(x.cat.color, .3))),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        CatTile(cat: x.cat, size: 20),
                        const SizedBox(width: 5),
                        Text('${x.pts}', style: _ts(12.5, w: FontWeight.w800)),
                        if (x.mul > 1) ...[
                          const SizedBox(width: 4),
                          Text('×${x.mul == 3 ? 3 : 1.5}', style: _ts(11, c: x.cat.color, w: FontWeight.w800)),
                        ],
                      ]),
                    ))
                .toList(),
          ),
          const SizedBox(height: 10),
          Text('خاڵی دوێنێت: ${_fmt(yest.total)} · ڕاپۆرتی هێزی ڕۆژ هەموو بەیانییەک دێت.', style: _ts(12.5, c: VA.muted)),
        ]),
      ),

      // ---- activities ----
      _Card(
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const _Title(icon: Icons.bar_chart_rounded, text: 'چالاکییەکانی ئەمڕۆ', note: 'AI پشتڕاستی کردوونەتەوە'),
          const SizedBox(height: 10),
          GridView.count(
            crossAxisCount: 4,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: .58,
            children: kArenaCats.map((c) {
              final d = data[c.id]!, row = t.row(c.id);
              return _ActivityTile(
                cat: c,
                value: d.v,
                active: d.f > 0,
                points: rev ? '+${row.pts}' : '؟؟',
                onTap: () => _openCat(c),
              );
            }).toList(),
          ),
        ]),
      ),

      // ---- AI report ----
      _Card(
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const _Title(icon: Icons.verified_user_rounded, text: 'ڕاپۆرتی AI', note: 'یاریی پاک'),
          const SizedBox(height: 8),
          _AiRow(ok: true, title: '${data['walk']!.v} پشتڕاست کرایەوە', sub: 'لێدانی دڵ لەگەڵ ڕۆیشتن بەرز بووەوە'),
          _AiRow(ok: true, title: 'خەوی ${data['sleep']!.v}', sub: 'لێدانی دڵ و جووڵەی شەو لەگەڵ یەک گونجان'),
          _AiRow(ok: true, title: 'خۆراک: ${data['food']!.v}', sub: 'تۆمارکراو لە بەشی خواردن · وێنەی ڕاستەوخۆ'),
          const _AiRow(ok: false, title: '1,180 هەنگاو ڕەتکرایەوە', sub: 'جووڵەی دەست بێ بەرزبوونەوەی لێدانی دڵ · 22:15'),
          const _AiRow(ok: false, title: 'وێنەی ژەم ڕەتکرایەوە', sub: 'وێنەکە لە گەلەرییەوە بوو، نەک لە کامێرای ڕاستەوخۆ'),
        ]),
      ),

      // ---- prizes ----
      _Card(
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const _Title(icon: Icons.card_giftcard_rounded, text: 'خەڵاتەکانی وەرز', note: 'بۆ ئەوانەی 25 ڕۆژ چالاک دەبن'),
          const SizedBox(height: 12),
          GestureDetector(onTap: _openPrizes, child: const _PrizeRow()),
          const SizedBox(height: 12),
          _Btn(
              label: 'خاڵەکان چۆن کۆدەکرێنەوە و بۆچی کەس ناتوانێت فێڵ بکات؟',
              icon: Icons.shield_rounded,
              secondary: true,
              onTap: () => _sheet(const _HowSheet())),
        ]),
      ),
    ]);
  }

  void _openCat(ArenaCat c) {
    _sheet(Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Center(child: CatTile(cat: c, size: 60)),
      const SizedBox(height: 10),
      Text(c.name, textAlign: TextAlign.center, style: _ts(18, w: FontWeight.w800)),
      Text.rich(
          TextSpan(children: [
            const TextSpan(text: 'ئەمڕۆ: '),
            TextSpan(text: data[c.id]!.v, style: _ts(13.5, w: FontWeight.w800)),
          ]),
          textAlign: TextAlign.center,
          style: _ts(13.5, c: VA.muted)),
      const SizedBox(height: 12),
      _Card(
        margin: EdgeInsets.zero,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          _InfoLine(icon: Icons.shield_rounded, text: 'پشتڕاستکردنەوە: ${c.src}'),
          _InfoLine(icon: Icons.track_changes_rounded, text: 'زۆرترین خاڵی ئاسایی: ${c.max}'),
          _InfoLine(icon: Icons.favorite_rounded, text: 'تەنها ڕەفتاری تەندروست دەژمێردرێت؛ زیادەڕۆیی خاڵی زیاتر نادات.'),
        ]),
      ),
      const SizedBox(height: 12),
      Builder(
        builder: (ctx) => _Btn(
          label: 'بڕۆ بۆ بەشی ${c.name}',
          icon: Icons.open_in_new_rounded,
          onTap: () {
            Navigator.of(ctx).pop();
            widget.host.openSection(context, c.id);
          },
        ),
      ),
      const SizedBox(height: 8),
      Builder(builder: (ctx) => _Btn(label: 'داخستن', secondary: true, onTap: () => Navigator.of(ctx).pop())),
    ]));
  }

  void _openPrizes() {
    _sheet(_PrizeSheet(
      season: season,
      joined: st.acc != null,
      myPoints: myTotal,
      activeDays: activeDays,
      onHow: () => _sheet(const _HowSheet()),
    ));
  }

  // ---------------------------------------------------------------- rank
  Widget _rankView() {
    final a = st.acc;
    var list = [...players];
    if (lb == 'city' && a != null) list = list.where((x) => x.city == a.city).toList();
    if (lb == 'age' && a != null) list = list.where((x) => x.age == a.age).toList();
    if (lb == 'friends') list = list.sublist(5, 9);
    if (lb == 'guess') list.sort((x, y) => y.guess.compareTo(x.guess));
    final gs = lb == 'guess';
    int rr(ArenaPlayer x) => lb == 'all' ? x.rank : list.indexOf(x) + 1;
    final pod = list.length >= 3;
    final rest = list.sublist(pod ? 3 : 0);
    final vis = rest.take(shown).toList();
    final my = myTotal, rk = rankOf(my, season);
    final gap = math.max(1, (ptsAt(math.max(1, rk - 1)) - my).round());
    Widget val(ArenaPlayer x, {double size = 14}) => gs
        ? Row(mainAxisSize: MainAxisSize.min, children: [
            Text('${x.guess}', style: _ts(size, w: FontWeight.w800)),
            const SizedBox(width: 3),
            Icon(Icons.auto_awesome_rounded, size: size, color: VA.violet),
          ])
        : Text(_fmt(x.points), style: _ts(size, w: FontWeight.w800));

    return _Card(
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        _Title(icon: Icons.emoji_events_rounded, text: 'تابلۆی پلەکان', note: '${_fmt(season.total + (a != null ? 1 : 0))} بەشداربوو'),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: const [
              ['all', 'گشتی', Icons.emoji_events_rounded],
              ['city', 'شارەکەم', Icons.place_rounded],
              ['age', 'تەمەنم', Icons.groups_rounded],
              ['friends', 'هاوڕێکان', Icons.person_add_alt_1_rounded],
              ['guess', 'پێشبینیکەران', Icons.auto_awesome_rounded],
            ]
                .map((t) => Padding(
                      padding: const EdgeInsetsDirectional.only(end: 6),
                      child: _Chip(
                        label: t[1] as String,
                        icon: t[2] as IconData,
                        on: lb == t[0],
                        onTap: () => setState(() {
                          lb = t[0] as String;
                          shown = 11;
                        }),
                      ),
                    ))
                .toList(),
          ),
        ),
        if (a != null) ...[
          const SizedBox(height: 10),
          InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () => _go('card'),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [_al(VA.mint, .14), _al(VA.cyan, .06)]),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: _al(VA.mint, .35))),
              child: Row(children: [
                CharAvatar(ch: st.ch, name: a.name, size: 44, ring: leagueOf(my).accent),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('${a.name} (تۆ)', style: _ts(14.5, w: FontWeight.w800), overflow: TextOverflow.ellipsis),
                    Text(rk > 1 ? 'تەنها ${_fmt(gap)} خاڵ ماوە بۆ پلەی #${_fmt(rk - 1)}' : 'تۆ یەکەمیت', style: _ts(12, c: VA.muted)),
                  ]),
                ),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text('#${_fmt(rk)}', style: _ts(17, w: FontWeight.w800)),
                  Text('${_fmt(my)} خاڵ', style: _ts(11, c: VA.muted)),
                ]),
              ]),
            ),
          ),
        ],
        if (pod) ...[
          const SizedBox(height: 14),
          Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Expanded(child: _Podium(p: list[1], place: 2, h: 62, color: VA.silver, size: 62, val: val(list[1]), onTap: _openPlayer)),
            Expanded(child: _Podium(p: list[0], place: 1, h: 88, color: VA.gold, size: 78, val: val(list[0]), onTap: _openPlayer)),
            Expanded(child: _Podium(p: list[2], place: 3, h: 48, color: VA.bronze, size: 62, val: val(list[2]), onTap: _openPlayer)),
          ]),
        ],
        const SizedBox(height: 8),
        ...vis.map((x) => _RankRow(
              rank: '#${rr(x)}',
              p: x,
              value: val(x),
              onTap: () => _openPlayer(x),
            )),
        if (rest.length > shown)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: _Btn(label: 'زیاتر پیشان بدە', icon: Icons.expand_more_rounded, secondary: true, onTap: () => setState(() => shown += 15)),
          ),
        if (a != null) ...[
          Center(child: Padding(padding: const EdgeInsets.all(6), child: Text('• • •', style: _ts(14, c: VA.muted)))),
          InkWell(
            onTap: () => _go('card'),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                  color: _al(VA.mint, .1), borderRadius: BorderRadius.circular(16), border: Border.all(color: _al(VA.mint, .3))),
              child: Row(children: [
                SizedBox(width: 50, child: Text(lb == 'all' ? '#${_fmt(rk)}' : 'تۆ', style: _ts(13, w: FontWeight.w800))),
                CharAvatar(ch: st.ch, name: a.name, size: 40, ring: leagueOf(my).accent),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('${a.name} (تۆ)', style: _ts(14, w: FontWeight.w800), overflow: TextOverflow.ellipsis),
                    Text('${a.city} · ${leagueOf(my).name}', style: _ts(11.5, c: VA.muted)),
                  ]),
                ),
                gs
                    ? Row(mainAxisSize: MainAxisSize.min, children: [
                        Text('${st.bestPower}', style: _ts(14, w: FontWeight.w800)),
                        Icon(Icons.auto_awesome_rounded, size: 14, color: VA.violet),
                      ])
                    : Text(_fmt(my), style: _ts(14, w: FontWeight.w800)),
              ]),
            ),
          ),
        ] else
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: _Btn(label: 'بەشداربوون', icon: Icons.rocket_launch_rounded, onTap: _openJoin),
          ),
        if (rest.isEmpty && !pod)
          Padding(
            padding: const EdgeInsets.only(top: 14),
            child: Text('هێشتا کەس لێرە نییە.', textAlign: TextAlign.center, style: _ts(13, c: VA.muted)),
          ),
      ]),
    );
  }

  void _openPlayer(ArenaPlayer x) {
    var s = _fnv('${x.name}${x.rank}');
    final stats = kStatNames.map((n) {
      s = (s * 1103515245 + 12345) & 0xFFFFFFFF;
      return <Object>[n, math.min(99, ratingOf(x.points) - 20 + (s % 21))];
    }).toList();
    final d = CardData(
        name: x.name, city: x.city, ch: x.ch, points: x.points, skin: x.skin, title: x.bio, stats: stats, rank: x.rank, grad: x.grad);
    _sheet(Builder(
      builder: (ctx) => Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Center(child: TiltCard(child: ArenaCardView(data: d))),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(
              child: _StatTile(
                  label: 'بەردەوامی',
                  value: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.local_fire_department_rounded, color: vk(0xFFFF9466), size: 17),
                    Text('${x.streak}', style: _ts(17, w: FontWeight.w800)),
                  ]))),
          const SizedBox(width: 8),
          Expanded(
              child: _StatTile(
                  label: 'پێشبینیی ڕاست',
                  value: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.auto_awesome_rounded, color: VA.violet, size: 17),
                    Text('${x.guess}', style: _ts(17, w: FontWeight.w800)),
                  ]))),
          const SizedBox(width: 8),
          Expanded(child: _StatTile(label: 'دڵخواز', value: CatTile(cat: catById(x.fav), size: 26))),
        ]),
        const SizedBox(height: 10),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.visibility_off_rounded, size: 15, color: VA.muted),
          const SizedBox(width: 6),
          Text('داتای تەندروستیی ئەم کەسە نهێنییە و دەرناکەوێت', style: _ts(12.5, c: VA.muted)),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(
            child: _Btn(
                label: 'هاندان',
                icon: Icons.thumb_up_rounded,
                onTap: () {
                  Navigator.of(ctx).pop();
                  _toast(context, 'هاندانت نارد بۆ ${x.name.split(' ').first}', Icons.thumb_up_rounded);
                }),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _Btn(
                label: 'هاوڕێ',
                icon: Icons.person_add_alt_1_rounded,
                secondary: true,
                onTap: () {
                  Navigator.of(ctx).pop();
                  _toast(context, 'داواکاریی هاوڕێیەتی نێردرا', Icons.check_rounded);
                }),
          ),
        ]),
      ]),
    ));
  }

  // ---------------------------------------------------------------- card
  List<List<Object>> _badges() {
    final t = myTotal;
    return [
      [Icons.rocket_launch_rounded, 'یەکەم ڕۆژ', st.acc != null, vk(0xFF3CF08A)],
      [Icons.local_fire_department_rounded, '7 ڕۆژ', activeDays >= 7, vk(0xFFFF9466)],
      [Icons.auto_awesome_rounded, 'پێشبینیکەر', st.bestPower >= 1, vk(0xFFA58CFF)],
      [Icons.track_changes_rounded, '3 پێشبینیی ڕاست', st.bestPower >= 3, vk(0xFFFF6F86)],
      [Icons.bedtime_rounded, 'خەوی ئاڵتوونی', (data['sleep']?.f ?? 0) >= 1, vk(0xFF9B7BFF)],
      [Icons.restaurant_rounded, 'خۆراکی پاک', (data['food']?.f ?? 0) >= .95, vk(0xFFFFBE4D)],
      [Icons.directions_run_rounded, '50 کیلۆمەتر', false, vk(0xFFFF9466)],
      [Icons.emoji_events_rounded, 'لیگی ئاڵتوون', t >= 1500, vk(0xFFE6B13A)],
      [Icons.water_drop_rounded, 'ڕووباری ئاو', (data['water']?.f ?? 0) >= 1, vk(0xFF2FB8F3)],
      [Icons.spa_rounded, 'ئارامی', (data['calm']?.f ?? 0) >= 1, vk(0xFFA58CFF)],
      [Icons.groups_rounded, '5 هاوڕێ', false, vk(0xFF3FD69A)],
      [Icons.workspace_premium_rounded, 'VEX Legend', t >= 7500, vk(0xFFFF5577)],
    ];
  }

  Widget _cardView() {
    final a = st.acc!;
    final d = myCard(), t = myTotal, lv = levelOf(t), xs = levelStart(lv), xe = levelStart(lv + 1);
    final fill = ((t - xs) / (xe - xs) * 20).round();
    final b = _badges();
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _Card(
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Center(child: _DropIn(key: ValueKey('drop$_cardDrop'), child: TiltCard(child: ArenaCardView(data: d)))),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(
                child: _Btn(
                    label: st.ch.isEmpty ? 'کارەکتەرەکەت هەڵبژێرە' : 'گۆڕینی کارەکتەر',
                    icon: Icons.face_rounded,
                    onTap: _openCharPicker)),
            const SizedBox(width: 8),
            _SqBtn(icon: Icons.ios_share_rounded, onTap: _openShare),
            const SizedBox(width: 8),
            _SqBtn(icon: Icons.edit_rounded, onTap: _openEdit),
          ]),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(child: Text('ئاست $lv · XP', style: _ts(12.5, c: VA.muted, w: FontWeight.w700))),
            Text('${_fmt(t)} / ${_fmt(xe)}', style: _ts(12.5, c: VA.muted, w: FontWeight.w700)),
          ]),
          const SizedBox(height: 6),
          Row(
            children: List.generate(
              20,
              (i) => Expanded(
                child: Container(
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 1.5),
                  decoration: BoxDecoration(
                      gradient: i < fill ? VA.prime : null,
                      color: i < fill ? null : _al(kW, .08),
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ),
        ]),
      ),
      // ---- skins ----
      _Card(
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const _Title(icon: Icons.star_rounded, text: 'دیزاینی کارت', note: 'بە سکە یان بە لیگ دەکرێتەوە'),
          const SizedBox(height: 10),
          GridView.count(
            crossAxisCount: 4,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: .72,
            children: kSkins.map((s) {
              final ok = skinOwned(s);
              final sc = skinColors(s.id, t);
              return GestureDetector(
                onTap: () {
                  if (!ok) {
                    if (s.league > 0) {
                      _toast(context, 'دەبێت بگەیتە لیگی ${kLeagues[s.league].name}', Icons.lock_rounded);
                      return;
                    }
                    if (st.coins < s.cost) {
                      _toast(context, '${s.cost - st.coins} سکەی ترت پێویستە', Icons.lock_rounded);
                      return;
                    }
                    st.coins -= s.cost;
                    st.owned.add('skin:${s.id}');
                    _toast(context, 'کڕدرا: ${s.name}', Icons.check_rounded);
                  }
                  HapticFeedback.selectionClick();
                  st.skin = s.id;
                  st.save();
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    gradient: LinearGradient(colors: [sc.c1, sc.c2], begin: Alignment.topLeft, end: Alignment.bottomRight),
                    border: Border.all(color: st.skin == s.id ? sc.accent : _al(kW, .15), width: st.skin == s.id ? 2.5 : 1),
                    boxShadow: st.skin == s.id ? [BoxShadow(color: _al(sc.accent, .45), blurRadius: 14)] : null,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Stack(children: [
                      Positioned.fill(child: CustomPaint(painter: _PatternPainter(sc.pattern))),
                      if (!ok)
                        Positioned(
                          top: 6,
                          left: 6,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(color: _al(Colors.black, .35), borderRadius: BorderRadius.circular(8)),
                            child: Icon(Icons.lock_rounded, size: 12, color: kW),
                          ),
                        ),
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 3),
                          color: _al(Colors.black, .28),
                          child: Text(
                            ok ? s.name : s.league > 0 ? '${s.name} · ${kLeagues[s.league].name}' : '${s.name} · ${s.cost}',
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            style: _ts(10, c: kW, w: FontWeight.w700, h: 1.3),
                          ),
                        ),
                      ),
                    ]),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 10),
          Text('سکە لە خاڵی ڕۆژانە و پێشبینیی ڕاستەوە دێت. خەرجکردنی سکە خاڵی پێشبڕکێکەت کەم ناکاتەوە، بۆیە کەس ناتوانێت پلە بکڕێت.',
              style: _ts(12.5, c: VA.muted, h: 1.6)),
        ]),
      ),
      // ---- titles ----
      _Card(
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const _Title(icon: Icons.flag_rounded, text: 'نازناو', note: 'لەسەر کارتەکەت دەردەکەوێت'),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: kTitles.map((x) {
              final ok = x.req == 0 || (x.req == 1 && st.bestPower >= 1) || (x.req == 5 && t >= 7500);
              return _Chip(
                label: x.name,
                icon: ok ? x.icon : Icons.lock_rounded,
                on: st.title == x.id,
                dim: !ok,
                onTap: () {
                  if (!ok) {
                    _toast(context, 'هێشتا نەکراوەتەوە', Icons.lock_rounded);
                    return;
                  }
                  st.title = x.id;
                  st.save();
                },
              );
            }).toList(),
          ),
        ]),
      ),
      // ---- badges ----
      _Card(
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          _Title(icon: Icons.emoji_events_rounded, text: 'مێدالیاکان', note: '${b.where((x) => x[2] == true).length}/${b.length}'),
          const SizedBox(height: 10),
          GridView.count(
            crossAxisCount: 4,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 8,
            childAspectRatio: .9,
            children: b.map((x) {
              final on = x[2] == true;
              return Opacity(
                opacity: on ? 1 : .35,
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  _IconTile(icon: x[0] as IconData, color: x[3] as Color, size: 40),
                  const SizedBox(height: 5),
                  Text(x[1] as String, textAlign: TextAlign.center, maxLines: 2, style: _ts(10.5, w: FontWeight.w700, h: 1.25)),
                ]),
              );
            }).toList(),
          ),
        ]),
      ),
      // ---- privacy ----
      _Card(
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          _Title(icon: Icons.visibility_rounded, text: 'تایبەتمەندی', note: 'کەسانی تر چی دەبینن'),
          SizedBox(height: 8),
          _InfoLine(icon: Icons.visibility_rounded, text: 'کارەکتەر، ناو، شار، کارت، لیگ، پلە و مێدالیا', color: VA.mint),
          _InfoLine(
              icon: Icons.visibility_off_rounded,
              text: 'هیچ داتایەکی تەندروستی (لێدانی دڵ، کێش، خەو، ئۆکسجین) بۆ کەس دەرناکەوێت',
              color: VA.coral),
        ]),
      ),
      // ---- account ----
      _Card(
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const _Title(icon: Icons.face_rounded, text: 'ئەکاونت'),
          const SizedBox(height: 10),
          Row(children: [
            CharAvatar(ch: st.ch, name: a.name, size: 46, ring: leagueOf(t).accent),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(a.name, style: _ts(15, w: FontWeight.w800)),
                Text(maskPhone(a.phone), textDirection: TextDirection.ltr, style: _ts(12, c: VA.muted)),
              ]),
            ),
          ]),
          const SizedBox(height: 14),
          _Btn(label: 'چوونە دەرەوە', icon: Icons.logout_rounded, danger: true, onTap: _openLogout),
        ]),
      ),
    ]);
  }

  Future<void> _openCharPicker() async {
    final id = await _sheet<String>(_CharPickerSheet(current: st.ch, preview: (ch) => myCard().copyWith(ch: ch)));
    if (id == null || !mounted) return;
    await st.setCharacter(id);
    if (!mounted) return;
    setState(() => _cardDrop++);
    showConfetti(context);
    _toast(context, 'کارەکتەرەکەت دانرا', Icons.check_rounded);
  }

  void _openShare() {
    const txt = 'ئەزانی هێزی نهێنیی ئەمڕۆ چییە؟ ئەپی VEX دابەزێنە';
    _sheet(Builder(
      builder: (ctx) => Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text('کارتەکەت بڵاو بکەرەوە', textAlign: TextAlign.center, style: _ts(18, w: FontWeight.w800)),
        const SizedBox(height: 10),
        Center(child: TiltCard(child: ArenaCardView(data: myCard()))),
        const SizedBox(height: 10),
        Text('کارتەکە وەک وێنە دەچێتە TikTok، Instagram و Snapchat، لەگەڵ ئەم نووسینە: «$txt»',
            textAlign: TextAlign.center, style: _ts(12.5, c: VA.muted, h: 1.6)),
        const SizedBox(height: 12),
        _Btn(
            label: 'کۆپیکردنی نووسین',
            icon: Icons.copy_rounded,
            onTap: () async {
              await Clipboard.setData(const ClipboardData(text: txt));
              if (ctx.mounted) Navigator.of(ctx).pop();
              if (mounted) _toast(context, 'نووسینەکە کۆپی کرا', Icons.check_rounded);
            }),
        const SizedBox(height: 8),
        _Btn(label: 'داخستن', secondary: true, onTap: () => Navigator.of(ctx).pop()),
      ]),
    ));
  }

  Future<void> _openEdit() async {
    final r = await _sheet<List<String>>(_EditSheet(name: st.acc!.name, bio: st.bio));
    if (r == null) return;
    if (r[0].trim().length >= 2) st.acc!.name = r[0].trim().characters.take(24).toString();
    st.bio = r[1].trim().characters.take(60).toString();
    await st.save();
    if (mounted) _toast(context, 'پاشەکەوت کرا', Icons.check_rounded);
  }

  Future<void> _openLogout() async {
    final ok = await _sheet<bool>(Builder(
      builder: (ctx) => Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Center(child: _IconTile(icon: Icons.logout_rounded, color: VA.coral, size: 60)),
        const SizedBox(height: 10),
        Text('دڵنیایت لەوەی دەتەوێت بچیتە دەرەوە؟', textAlign: TextAlign.center, style: _ts(17, w: FontWeight.w800)),
        const SizedBox(height: 6),
        Text('کارت، سکە و دیزاینەکانت لەم ئامێرە دەسڕێنەوە. خاڵەکانت لە سێرڤەر دەمێننەوە و بە ژمارەی مۆبایلەکەت دەگەڕێنەوە.',
            textAlign: TextAlign.center, style: _ts(13, c: VA.muted, h: 1.6)),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(child: _Btn(label: 'بەڵێ، دەچمە دەرەوە', danger: true, onTap: () => Navigator.of(ctx).pop(true))),
          const SizedBox(width: 8),
          Expanded(child: _Btn(label: 'نەخێر', secondary: true, onTap: () => Navigator.of(ctx).pop(false))),
        ]),
      ]),
    ));
    if (ok != true) return;
    await st.logout();
    if (!mounted) return;
    setState(() {
      tab = 'today';
      lb = 'all';
      shown = 11;
    });
    _toast(context, 'چوویتە دەرەوە', Icons.logout_rounded);
  }

  Future<T?> _sheet<T>(Widget child) => showArenaSheet<T>(context, child);
}

// =============================================================================
// 7. کارتی یاریزان + جووڵەی 3D
// =============================================================================

class CardData {
  final String name, city, ch, skin, title;
  final int points, rank;
  final List<List<Object>> stats;
  final List<Color> grad;
  const CardData({
    required this.name,
    required this.city,
    required this.ch,
    required this.points,
    required this.skin,
    required this.title,
    required this.stats,
    required this.rank,
    required this.grad,
  });
  CardData copyWith({String? ch}) => CardData(
      name: name, city: city, ch: ch ?? this.ch, points: points, skin: skin, title: title, stats: stats, rank: rank, grad: grad);
}

class ArenaCardView extends StatefulWidget {
  final CardData data;
  final double width;
  const ArenaCardView({super.key, required this.data, this.width = 236});
  @override
  State<ArenaCardView> createState() => _ArenaCardViewState();
}

class _ArenaCardViewState extends State<ArenaCardView> with SingleTickerProviderStateMixin {
  late final AnimationController _sheen = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat();

  @override
  void dispose() {
    _sheen.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.data, w = widget.width, k = w / 236;
    final sc = skinColors(d.skin, d.points);
    final lg = leagueOf(d.points);
    return SizedBox(
      width: w,
      height: w * 330 / 236,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.vertical(top: Radius.circular(30 * k), bottom: Radius.circular(26 * k)),
          boxShadow: [BoxShadow(color: _al(sc.accent, .45), blurRadius: 30 * k, offset: Offset(0, 14 * k), spreadRadius: -12 * k)],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.vertical(top: Radius.circular(30 * k), bottom: Radius.circular(26 * k)),
          child: Stack(children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                      colors: [sc.c1, sc.c2], begin: const Alignment(-.6, -1), end: const Alignment(.6, 1)),
                ),
              ),
            ),
            Positioned.fill(child: CustomPaint(painter: _PatternPainter(sc.pattern))),
            // sheen
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _sheen,
                builder: (_, __) {
                  final t = (_sheen.value / .38).clamp(0.0, 1.0);
                  return IgnorePointer(
                    child: FractionalTranslation(
                      translation: Offset(-1.3 + t * 2.8, 0),
                      child: Transform(
                        transform: Matrix4.skewX(-.25),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: [
                              _al(kW, 0),
                              _al(kW, .28),
                              _al(kW, 0),
                            ], stops: const [.3, .5, .7]),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(30 * k), bottom: Radius.circular(26 * k)),
                  border: Border.all(color: _al(kW, .18), width: 1.5),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(16 * k, 20 * k, 16 * k, 0),
              child: Column(children: [
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Column(children: [
                    Text('${ratingOf(d.points)}',
                        style: TextStyle(
                            fontSize: 40 * k,
                            fontWeight: FontWeight.w800,
                            color: kW,
                            height: 1,
                            shadows: [Shadow(color: _al(Colors.black, .35), blurRadius: 10)])),
                    SizedBox(height: 4 * k),
                    Text('VEX', style: TextStyle(fontSize: 10 * k, letterSpacing: 1, color: _al(kW, .85))),
                    SizedBox(height: 5 * k),
                    LeagueEmblem(league: lg, size: 32 * k),
                    SizedBox(height: 5 * k),
                    Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.place_rounded, size: 11 * k, color: _al(kW, .9)),
                      Text(d.city, style: _ts(10 * k, c: _al(kW, .9))),
                    ]),
                  ]),
                  const Spacer(),
                  Container(
                    width: 126 * k,
                    height: 126 * k,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: sc.accent, spreadRadius: 3 * k),
                        BoxShadow(color: _al(Colors.black, .5), blurRadius: 20 * k, offset: Offset(0, 10 * k)),
                      ],
                    ),
                    child: CharAvatar(ch: d.ch, name: d.name, size: 126 * k, grad: d.grad, breathe: true),
                  ),
                ]),
                SizedBox(height: 10 * k),
                Container(
                  padding: EdgeInsets.only(bottom: 6 * k),
                  decoration: BoxDecoration(border: Border(bottom: BorderSide(color: _al(kW, .22)))),
                  child: Text(d.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: _ts(18 * k, c: kW, w: FontWeight.w800)),
                ),
                SizedBox(height: 5 * k),
                Text(d.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _ts(11 * k, c: _al(kW, .88))),
                SizedBox(height: 8 * k),
                Wrap(
                  alignment: WrapAlignment.center,
                  runSpacing: 4 * k,
                  children: d.stats
                      .map((s) => SizedBox(
                            width: (w - 32 * k) / 3,
                            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                              Text('${s[1]}', style: TextStyle(fontSize: 15 * k, fontWeight: FontWeight.w800, color: kW)),
                              SizedBox(width: 4 * k),
                              Text('${s[0]}', style: _ts(10 * k, c: kW)),
                            ]),
                          ))
                      .toList(),
                ),
              ]),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 10 * k,
              child: Text('VEX ARENA · SEASON ${Season.number} · #${_fmt(d.rank)}',
                  textAlign: TextAlign.center,
                  textDirection: TextDirection.ltr,
                  style: TextStyle(fontSize: 9 * k, letterSpacing: 1.1, color: _al(kW, .78))),
            ),
          ]),
        ),
      ),
    );
  }
}

/// بە پەنجە کارتەکە دەجووڵێت (3D) و کاتێک بەری دەدەیت دەگەڕێتەوە
class TiltCard extends StatefulWidget {
  final Widget child;
  const TiltCard({super.key, required this.child});
  @override
  State<TiltCard> createState() => _TiltCardState();
}

class _TiltCardState extends State<TiltCard> with SingleTickerProviderStateMixin {
  Offset _t = Offset.zero;
  late final AnimationController _back = AnimationController(vsync: this, duration: const Duration(milliseconds: 450));
  Offset _from = Offset.zero;

  @override
  void initState() {
    super.initState();
    _back.addListener(() => setState(() => _t = Offset.lerp(_from, Offset.zero, Curves.elasticOut.transform(_back.value))!));
  }

  @override
  void dispose() {
    _back.dispose();
    super.dispose();
  }

  void _update(Offset local, Size size) {
    _back.stop();
    setState(() => _t = Offset(
          (local.dx / size.width - .5).clamp(-.5, .5),
          (local.dy / size.height - .5).clamp(-.5, .5),
        ));
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final size = Size(c.maxWidth.isFinite ? c.maxWidth : 236, c.maxHeight.isFinite ? c.maxHeight : 330);
      void release() {
        _from = _t;
        _back.forward(from: 0);
      }

      // Listener (نەک GestureDetector) بۆ ئەوەی سکڕۆڵی پەڕەکە نەگرێت
      return Listener(
        onPointerDown: (e) => _update(e.localPosition, size),
        onPointerMove: (e) => _update(e.localPosition, size),
        onPointerUp: (_) => release(),
        onPointerCancel: (_) => release(),
        child: Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, .0012)
            ..rotateX(-_t.dy * .45)
            ..rotateY(_t.dx * .45),
          child: widget.child,
        ),
      );
    });
  }
}

/// کاتێک کارتەکە دادەنرێت لە سەرەوە دەکەوێتە خوارەوە
class _DropIn extends StatefulWidget {
  final Widget child;
  const _DropIn({super.key, required this.child});
  @override
  State<_DropIn> createState() => _DropInState();
}

class _DropInState extends State<_DropIn> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))..forward();
  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _c,
        child: widget.child,
        builder: (_, child) {
          final t = Curves.easeOutBack.transform(_c.value);
          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, .001)
              ..translate(0.0, -60 * (1 - t))
              ..scale(1 + .18 * (1 - t))
              ..rotateX(.3 * (1 - t)),
            child: child,
          );
        },
      );
}

class CharAvatar extends StatefulWidget {
  final String ch, name;
  final double size;
  final Color? ring;
  final List<Color>? grad;
  final bool breathe;
  const CharAvatar({super.key, required this.ch, required this.name, required this.size, this.ring, this.grad, this.breathe = false});
  @override
  State<CharAvatar> createState() => _CharAvatarState();
}

class _CharAvatarState extends State<CharAvatar> with SingleTickerProviderStateMixin {
  AnimationController? _b;
  @override
  void initState() {
    super.initState();
    if (widget.breathe) _b = AnimationController(vsync: this, duration: const Duration(milliseconds: 3400))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _b?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.size;
    final has = widget.ch.isNotEmpty;
    Widget inner = has
        ? Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(center: Alignment(0, -.55), colors: [vk(0xFFE3FCFF), vk(0xFF2FE6F3), vk(0xFF0B5F73)], stops: [0, .7, 1]),
            ),
            child: ClipOval(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: _b == null
                    ? _charImg(s, 0)
                    : AnimatedBuilder(animation: _b!, builder: (_, __) => _charImg(s, Curves.easeInOut.transform(_b!.value))),
              ),
            ),
          )
        : Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(colors: widget.grad ?? [vk(0xFF0F9B8E), vk(0xFF1D4E89)]),
            ),
            child: Text(widget.name.trim().isEmpty ? '?' : widget.name.trim().characters.first,
                style: _ts(s * .38, c: kW, w: FontWeight.w800)),
          );
    return Container(
      width: s,
      height: s,
      decoration: widget.ring == null
          ? null
          : BoxDecoration(shape: BoxShape.circle, boxShadow: [
              BoxShadow(color: VA.bg, spreadRadius: 2),
              BoxShadow(color: widget.ring!, spreadRadius: 4),
            ]),
      child: inner,
    );
  }

  Widget _charImg(double s, double t) => Transform.translate(
        offset: Offset(0, s * (.04 - .03 * t)),
        child: Transform.scale(
          scale: 1.12,
          alignment: Alignment.bottomCenter,
          child: Image.asset(charAsset(widget.ch), width: s, height: s, fit: BoxFit.contain, alignment: Alignment.bottomCenter,
              errorBuilder: (_, __, ___) => Icon(Icons.person_rounded, size: s * .6, color: kW)),
        ),
      );
}

class LeagueEmblem extends StatelessWidget {
  final League league;
  final double size;
  const LeagueEmblem({super.key, required this.league, this.size = 24});
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size * 56 / 48,
      child: CustomPaint(painter: _EmblemPainter(league.accent, league.idx)),
    );
  }
}

class _EmblemPainter extends CustomPainter {
  final Color c;
  final int idx;
  _EmblemPainter(this.c, this.idx);
  @override
  void paint(Canvas canvas, Size s) {
    final w = s.width, h = s.height;
    final p = Path()
      ..moveTo(w / 2, 0)
      ..lineTo(w, h * .18)
      ..lineTo(w, h * .52)
      ..quadraticBezierTo(w * .95, h * .85, w / 2, h)
      ..quadraticBezierTo(w * .05, h * .85, 0, h * .52)
      ..lineTo(0, h * .18)
      ..close();
    final rect = Offset.zero & s;
    canvas.drawPath(
        p,
        Paint()
          ..shader = LinearGradient(
            colors: [Color.lerp(c, kW, .45)!, c, Color.lerp(c, Colors.black, .35)!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(rect));
    canvas.drawPath(p, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * .06
      ..color = _al(kW, .55));
    // chevrons = league level
    final cp = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * .09
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = _al(kW, .92);
    final n = math.min(3, idx + 1);
    for (var i = 0; i < n; i++) {
      final y = h * (.34 + i * .15);
      canvas.drawPath(
          Path()
            ..moveTo(w * .28, y)
            ..lineTo(w * .5, y + h * .1)
            ..lineTo(w * .72, y),
          cp);
    }
    if (idx >= 3) {
      canvas.drawCircle(Offset(w / 2, h * .2), w * .07, Paint()..color = kW);
    }
  }

  @override
  bool shouldRepaint(_EmblemPainter o) => o.c != c || o.idx != idx;
}

class _PatternPainter extends CustomPainter {
  final SkinPattern p;
  _PatternPainter(this.p);
  @override
  void paint(Canvas canvas, Size s) {
    switch (p) {
      case SkinPattern.none:
        break;
      case SkinPattern.gloss:
        canvas.drawRect(
            Offset.zero & s,
            Paint()
              ..shader = LinearGradient(
                colors: [_al(kW, .18), _al(kW, 0)],
                begin: Alignment.topLeft,
                end: const Alignment(.1, -.1),
              ).createShader(Offset.zero & s));
        break;
      case SkinPattern.grid:
        final g = Paint()..color = _al(vk(0xFF8FF3F9), .09);
        for (double x = 0; x < s.width; x += 14) {
          canvas.drawRect(Rect.fromLTWH(x, 0, 1, s.height), g);
        }
        for (double y = 0; y < s.height; y += 14) {
          canvas.drawRect(Rect.fromLTWH(0, y, s.width, 1), g);
        }
        break;
      case SkinPattern.stars:
        final a = Paint()..color = kW;
        final b = Paint()..color = _al(kW, .55);
        for (double y = 0; y < s.height; y += 22) {
          for (double x = 0; x < s.width; x += 22) {
            canvas.drawCircle(Offset(x, y), 1.1, a);
            canvas.drawCircle(Offset(x + 11, y + 11), 1, b);
          }
        }
        break;
      case SkinPattern.kurd:
        final a = Paint()
          ..color = _al(vk(0xFFFFD56B), .22)
          ..strokeWidth = 5;
        final b = Paint()
          ..color = _al(vk(0xFFDC3C3C), .3)
          ..strokeWidth = 5;
        for (double d = -s.height; d < s.width + s.height; d += 16) {
          canvas.drawLine(Offset(d, 0), Offset(d + s.height, s.height), a);
          canvas.drawLine(Offset(d + s.height, 0), Offset(d, s.height), b);
        }
        break;
      case SkinPattern.fire:
        for (final f in [
          [.2, vk(0xFFFFD56B), .65],
          [.8, vk(0xFFFF7800), .6],
          [.5, vk(0xFFFF3C00), .5],
        ]) {
          final c = Offset(s.width * (f[0] as double), s.height * 1.15);
          final r = s.width * .55;
          canvas.drawCircle(
              c,
              r,
              Paint()
                ..shader = RadialGradient(colors: [_al(f[1] as Color, f[2] as double), _al(f[1] as Color, 0)])
                    .createShader(Rect.fromCircle(center: c, radius: r)));
        }
        break;
      case SkinPattern.diamond:
        final a = Paint()..color = _al(kW, .12);
        for (double y = 0; y < s.height; y += 24) {
          for (double x = 0; x < s.width; x += 24) {
            canvas.drawPath(
                Path()
                  ..moveTo(x, y)
                  ..lineTo(x + 12, y)
                  ..lineTo(x, y + 12)
                  ..close(),
                a);
          }
        }
        break;
    }
  }

  @override
  bool shouldRepaint(_PatternPainter o) => o.p != p;
}

// =============================================================================
// 8. شیتەکان
// =============================================================================

Future<T?> showArenaSheet<T>(BuildContext context, Widget child) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: _al(vk(0xFF010C10), .7),
    builder: (ctx) => Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * .92),
        decoration: BoxDecoration(
          color: VA.sheet,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          border: Border(top: BorderSide(color: VA.line2)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 22),
              child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Center(
                  child: Container(
                    width: 46,
                    height: 5,
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(color: _al(kW, .2), borderRadius: BorderRadius.circular(9)),
                  ),
                ),
                child,
              ]),
            ),
          ),
        ),
      ),
    ),
  );
}

void _toast(BuildContext context, String text, [IconData? icon]) {
  final m = ScaffoldMessenger.maybeOf(context);
  if (m == null) return;
  m.hideCurrentSnackBar();
  m.showSnackBar(SnackBar(
    behavior: SnackBarBehavior.floating,
    backgroundColor: Colors.transparent,
    elevation: 0,
    duration: Duration(milliseconds: text.length > 40 ? 3600 : 2000),
    content: Directionality(
      textDirection: TextDirection.rtl,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(gradient: VA.prime, borderRadius: BorderRadius.circular(18), boxShadow: [
            BoxShadow(color: _al(VA.mint, .35), blurRadius: 18, offset: const Offset(0, 8)),
          ]),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            if (icon != null) ...[Icon(icon, size: 17, color: VA.ink), const SizedBox(width: 8)],
            Flexible(child: Text(text, style: _ts(13.5, c: VA.ink, w: FontWeight.w800))),
          ]),
        ),
      ),
    ),
  ));
}

// ---------------------------------------------------------------- prize sheet
class _PrizeSheet extends StatefulWidget {
  final Season season;
  final bool joined;
  final int myPoints, activeDays;
  final VoidCallback onHow;
  const _PrizeSheet({required this.season, required this.joined, required this.myPoints, required this.activeDays, required this.onHow});
  @override
  State<_PrizeSheet> createState() => _PrizeSheetState();
}

class _PrizeSheetState extends State<_PrizeSheet> with SingleTickerProviderStateMixin {
  Timer? _t;
  late final AnimationController _bob = AnimationController(vsync: this, duration: const Duration(milliseconds: 2600))..repeat(reverse: true);
  @override
  void initState() {
    super.initState();
    _t = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    _bob.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.season;
    final left = s.end.difference(DateTime.now());
    final l = left.isNegative ? Duration.zero : left;
    final dayLeft = Season.length - s.day + 1;
    final need = Season.needDays, act = widget.activeDays;
    final ok = act >= need, canReach = act + dayLeft - 1 >= need;
    final rk = rankOf(widget.myPoints, s);
    final gap3 = math.max(0, (ptsAt(3) - widget.myPoints).round());
    final e = s.end;
    final endS = '${e.day}/${e.month}/${e.year} · ${_p2(e.hour)}:${_p2(e.minute)}';

    Widget cd(String v, String u, {bool pulse = false}) => Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 3.5),
            padding: const EdgeInsets.symmetric(vertical: 9),
            decoration: BoxDecoration(
                color: _al(Colors.black, .28),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _al(VA.gold, .22))),
            child: Column(children: [
              TweenAnimationBuilder<double>(
                key: ValueKey(pulse ? v : u),
                tween: Tween(begin: pulse ? 1.12 : 1, end: 1),
                duration: const Duration(milliseconds: 400),
                builder: (_, sc, child) => Transform.scale(scale: sc, child: child),
                child: Text(v, style: _ts(26, c: vk(0xFFFFE9A8), w: FontWeight.w900, h: 1.1)),
              ),
              Text(u, style: _ts(10.5, c: _al(vk(0xFFFFF3C4), .7), w: FontWeight.w700)),
            ]),
          ),
        );

    Widget prize(int place, String name, IconData ic, Color c, String sub) {
      final big = place == 1;
      return Expanded(
        flex: big ? 23 : 20,
        child: Stack(clipBehavior: Clip.none, alignment: Alignment.topCenter, children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            padding: EdgeInsets.fromLTRB(6, big ? 22 : 16, 6, 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: LinearGradient(colors: [_al(c, .22), _al(c, .05)], begin: Alignment.topCenter, end: Alignment.bottomCenter),
              border: Border.all(color: _al(c, .45)),
              boxShadow: big ? [BoxShadow(color: _al(c, .4), blurRadius: 30, offset: const Offset(0, 14), spreadRadius: -14)] : null,
            ),
            child: Column(children: [
              AnimatedBuilder(
                animation: _bob,
                builder: (_, child) => Transform.translate(offset: Offset(0, -4 * Curves.easeInOut.transform(_bob.value)), child: child),
                child: Container(
                  width: big ? 66 : 54,
                  height: big ? 66 : 54,
                  decoration: BoxDecoration(color: _al(c, .18), borderRadius: BorderRadius.circular(big ? 22 : 18)),
                  child: Icon(ic, size: big ? 36 : 28, color: Color.lerp(c, VA.text, .28)),
                ),
              ),
              const SizedBox(height: 6),
              SizedBox(
                height: 36,
                child: Center(
                  child: Text(name, textAlign: TextAlign.center, maxLines: 2, style: _ts(13, w: FontWeight.w900, h: 1.3)),
                ),
              ),
              Text(sub, style: _ts(10.5, c: VA.muted, w: FontWeight.w700)),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: _al(c, .18), borderRadius: BorderRadius.circular(99)),
                child: Text('${_fmt(ptsAt(place))} خاڵ', style: _ts(10.5, w: FontWeight.w800)),
              ),
            ]),
          ),
          Container(
            width: 26,
            height: 26,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: c, shape: BoxShape.circle, border: Border.all(color: VA.sheet, width: 3)),
            child: Text('$place', style: _ts(12, c: vk(0xFF2B1D05), w: FontWeight.w900)),
          ),
        ]),
      );
    }

    Widget status() {
      if (ok) return _Note(color: VA.mint, icon: Icons.check_rounded, text: 'مەرجی ڕۆژە چالاکەکانت تەواوە. ئێستا تەنها پلەکەت گرنگە.');
      if (canReach) {
        return _Note(
            color: VA.cyan,
            icon: Icons.lightbulb_rounded,
            text: '${need - act} ڕۆژی چالاکی ترت ماوە بۆ ئەوەی شایستەی خەڵاتە گەورەکان بیت. وەرزەکە $dayLeft ڕۆژی ماوە.');
      }
      return _Note(
          color: VA.amber,
          icon: Icons.schedule_rounded,
          text:
              'ئەم وەرزە ناتوانیت بگەیتە $need ڕۆژی چالاکی، چونکە تەنها $dayLeft ڕۆژ ماوە. هێشتا خاڵ و پلە و سکە کۆدەکەیتەوە، و لە ڕۆژی یەکەمی وەرزی داهاتووەوە شایستەی خەڵاتە گەورەکان دەبیت.');
    }

    return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      // ---- golden hero ----
      Container(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          gradient: RadialGradient(
              center: Alignment(0, -1), radius: 1.4, colors: [vk(0xFF5A3D06), vk(0xFF2B1D05), vk(0xFF140D02)], stops: [0, .55, 1]),
          border: Border.all(color: _al(VA.gold, .35)),
          boxShadow: [BoxShadow(color: _al(VA.amber, .4), blurRadius: 40, offset: const Offset(0, 16), spreadRadius: -18)],
        ),
        child: Column(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
                color: _al(VA.gold, .16), borderRadius: BorderRadius.circular(99), border: Border.all(color: _al(VA.gold, .3))),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.emoji_events_rounded, size: 14, color: VA.gold),
              const SizedBox(width: 6),
              Text('وەرزی ${Season.number} · خەڵاتەکان', style: _ts(12, c: VA.gold, w: FontWeight.w800)),
            ]),
          ),
          const SizedBox(height: 10),
          Text('خەڵاتە گەورەکانی وەرز', style: _ts(22, c: vk(0xFFFFF3C4), w: FontWeight.w800)),
          Text('کێبڕکێ کۆتایی دێت لە', style: _ts(12.5, c: _al(vk(0xFFFFF3C4), .72))),
          const SizedBox(height: 14),
          Row(children: [
            cd('${l.inDays}', 'ڕۆژ'),
            cd(_p2(l.inHours % 24), 'کاتژمێر'),
            cd(_p2(l.inMinutes % 60), 'خولەک'),
            cd(_p2(l.inSeconds % 60), 'چرکە', pulse: true),
          ]),
          const SizedBox(height: 10),
          Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.flag_rounded, size: 14, color: _al(vk(0xFFFFF3C4), .8)),
            const SizedBox(width: 6),
            Text('کۆتایی: $endS', style: _ts(12, c: _al(vk(0xFFFFF3C4), .8), w: FontWeight.w700)),
          ]),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(9),
            child: LinearProgressIndicator(
              value: s.day / Season.length,
              minHeight: 8,
              backgroundColor: _al(Colors.white, .12),
              valueColor: AlwaysStoppedAnimation(VA.gold),
            ),
          ),
          const SizedBox(height: 5),
          Row(children: [
            Expanded(child: Text('ڕۆژی ${s.day}', style: _ts(11, c: _al(vk(0xFFFFF3C4), .7), w: FontWeight.w700))),
            Text('$dayLeft ڕۆژ ماوە', style: _ts(11, c: _al(vk(0xFFFFF3C4), .7), w: FontWeight.w700)),
          ]),
        ]),
      ),
      const SizedBox(height: 16),
      // ---- podium ----
      Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        prize(2, 'iPhone 17 Pro', Icons.phone_iphone_rounded, VA.silver, 'پلەی دووەم'),
        const SizedBox(width: 8),
        prize(1, 'ئۆتۆمبێل', Icons.directions_car_filled_rounded, VA.gold, 'پلەی یەکەم'),
        const SizedBox(width: 8),
        prize(3, '1,000,000 دینار', Icons.payments_rounded, VA.bronze, 'پلەی سێیەم'),
      ]),
      const SizedBox(height: 8),
      Text('ژمارەی ژێر هەر خەڵاتێک خاڵی ئێستای ئەو پلەیەیە', textAlign: TextAlign.center, style: _ts(11.5, c: VA.muted)),
      // ---- my status ----
      _Box(
        child: widget.joined
            ? Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                const _Title(icon: Icons.track_changes_rounded, text: 'دۆخی تۆ'),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(child: _MiniStat(label: 'پلەکەت ئێستا', value: '#${_fmt(rk)}')),
                  const SizedBox(width: 8),
                  Expanded(
                      child: _MiniStat(
                          label: rk <= 3 ? 'لە نێو سێیەکەمیت' : 'ماوە بۆ پلەی سێیەم', value: rk <= 3 ? '🏆' : _fmt(gap3), unit: rk <= 3 ? null : 'خاڵ')),
                ]),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(child: Text('ڕۆژە چالاکەکانت', style: _ts(12.5, w: FontWeight.w800))),
                  Text('$act / $need', style: _ts(12.5, w: FontWeight.w800)),
                ]),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(9),
                  child: Stack(children: [
                    Container(height: 10, color: _al(VA.cyan, .12)),
                    FractionallySizedBox(
                      widthFactor: math.min(1.0, act / need),
                      child: Container(height: 10, decoration: BoxDecoration(gradient: VA.prime)),
                    ),
                  ]),
                ),
                const SizedBox(height: 10),
                status(),
              ])
            : _Note(color: VA.cyan, icon: Icons.rocket_launch_rounded, text: 'هێشتا بەشدار نەبوویت. بەشداریکردن بەخۆڕاییە.'),
      ),
      _Box(
        child: Row(children: [
          _IconTile(icon: Icons.card_giftcard_rounded, color: VA.violet, size: 46),
          const SizedBox(width: 12),
          Expanded(
            child: Text.rich(
              TextSpan(children: [
                TextSpan(text: 'خەڵاتی بەشداری\n', style: _ts(13.5, w: FontWeight.w800)),
                const TextSpan(text: 'هەموو ئەوانەی هەر 30 ڕۆژی وەرزەکە تەواو دەکەن خەڵاتیان هەیە، جگە لە سێ خەڵاتە گەورەکە.'),
              ]),
              style: _ts(13, h: 1.6),
            ),
          ),
        ]),
      ),
      _Box(
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: const [
          _Title(icon: Icons.shield_rounded, text: 'مەرجەکان'),
          SizedBox(height: 10),
          _RuleLine(icon: Icons.schedule_rounded, text: 'بۆ خەڵاتە گەورەکان دەبێت لانیکەم 25 ڕۆژ لە 30 ڕۆژ چالاک بیت.'),
          _RuleLine(icon: Icons.emoji_events_rounded, text: 'ڕیزبەندی بەپێی کۆی خاڵی هەموو وەرزەکەیە. هەر ڕۆژێک سنووری 600 خاڵی هەیە.'),
          _RuleLine(icon: Icons.smart_toy_rounded, text: 'AI هەموو چالاکییەک پشتڕاست دەکاتەوە (GPS، لێدانی دڵ، کامێرای ڕاستەوخۆ). خاڵی ساختە ڕەت دەکرێتەوە.'),
          _RuleLine(icon: Icons.flag_rounded, text: 'براوەکان لە کۆتایی وەرزدا، کاتی سفربوونەوەی کاتژمێرەکەی سەرەوە، ڕادەگەیەنرێن.'),
        ]),
      ),
      const SizedBox(height: 12),
      _Btn(
          label: 'خاڵەکان چۆن کۆدەکرێنەوە؟',
          icon: Icons.help_outline_rounded,
          secondary: true,
          onTap: () {
            Navigator.of(context).pop();
            widget.onHow();
          }),
    ]);
  }
}

// ---------------------------------------------------------------- how sheet
class _HowSheet extends StatelessWidget {
  const _HowSheet();
  @override
  Widget build(BuildContext context) {
    const rules = [
      'خاڵ لە سێرڤەر دەژمێردرێت، نەک لە مۆبایل. ئەپەکە تەنها داتای خاوی Band دەنێرێت.',
      'هەنگاو بێ بەرزبوونەوەی لێدانی دڵ ڕەت دەکرێتەوە، بۆیە لەقاندنی مۆبایل و Band کار ناکات.',
      'AI شێوازی جووڵە دەناسێتەوە: پانکە، مەکینە، ئاژەڵ، یان دانی Band بە کەسێکی تر.',
      'ڕاکردن بە GPS و خێرایی و لێدانی دڵ پشتڕاست دەکرێتەوە؛ ئۆتۆمبێل و پاسکیل جیا دەکرێنەوە.',
      'وێنەی ژەم تەنها لە کامێرای ڕاستەوخۆ وەردەگیرێت. وێنەی دووبارە و وێنەی ئینتەرنێت دەناسرێنەوە، و خاڵی خۆراک بۆ کوالێتییە نەک زۆری.',
      'کێش تەنها لە تەرازووی زیرەکی بەستراو یان پشکنینی دوکان دەژمێردرێت.',
      'هەر ژمارەی مۆبایلێک یەک ئەکاونت، و هەر Band ـێک یەک کەس؛ گۆڕینی Band چاوەڕوانی 7 ڕۆژی هەیە.',
      'ڕۆژانە زۆرترین 600 خاڵ، و ئەگەر دوو کەس خاڵیان یەکسان بوو، ئەوەی ڕۆژی چالاکیی زیاترە پێشتر دەکەوێت.',
      '100 کەسی یەکەم بە دەست پشکنینیان بۆ دەکرێت، و براوەکان بە ناسنامە و ڤیدیۆ پشتڕاست دەکرێنەوە.',
      'فێڵکردن: یەکەمجار ئاگادارکردنەوە، دووەمجار سفرکردنەوەی خاڵی وەرز، سێیەمجار لابردنی ئەکاونت.',
    ];
    Widget h4(IconData i, String t) => Padding(
          padding: const EdgeInsets.only(top: 14, bottom: 8),
          child: Row(children: [Icon(i, size: 18, color: VA.cyan), const SizedBox(width: 7), Text(t, style: _ts(15, w: FontWeight.w800))]),
        );
    return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text('خاڵەکان چۆن کۆدەکرێنەوە', textAlign: TextAlign.center, style: _ts(18, w: FontWeight.w800)),
      h4(Icons.favorite_rounded, 'هەموو کارێکی تەندروست'),
      ...kArenaCats.map((c) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(children: [
              CatTile(cat: c, size: 24),
              const SizedBox(width: 8),
              SizedBox(width: 84, child: Text(c.name, style: _ts(12.5, w: FontWeight.w700))),
              Expanded(child: Text(c.src, style: _ts(11.5, c: VA.muted))),
              Text('${c.max}', style: _ts(13, w: FontWeight.w800)),
            ]),
          )),
      const SizedBox(height: 6),
      Text(
          'ژمارەکان زۆرترین خاڵی ئاسایی هەر بەشێکن. هەموویان سنووریان هەیە: خەوی 12 کاتژمێر یان وەرزشی 5 کاتژمێر خاڵی زیاتر نادات. کەمکردنەوەی کێش تەنها بە ڕێژەیەکی تەندروست دەژمێردرێت (کەمتر لە 1kg لە هەفتەیەکدا). بۆ ئۆکسجین، خاڵەکە بۆ لەبەرکردنی Band ـە، نەک بۆ ژمارەکە.',
          style: _ts(12.5, c: VA.muted, h: 1.6)),
      h4(Icons.auto_awesome_rounded, 'هێزی نهێنیی ڕۆژ'),
      Text(
          'هەموو ڕۆژێک سێرڤەر بە هەڕەمەکی یەک بەش ×3 و یەکێکی تر ×1.5 دەکات. تا نیوەشەو بۆ هیچ مۆبایلێک نانێردرێت. پێش هەر ڕۆژێک کۆدێکی شاراوەی (hash) هێزەکە بڵاو دەکرێتەوە، بۆیە دوای ئاشکراکردن هەر کەسێک دەتوانێت بیپشکنێت و بزانێت هێزەکە نەگۆڕدراوە.',
          style: _ts(13, h: 1.6)),
      h4(Icons.shield_rounded, 'بۆچی کەس ناتوانێت فێڵ بکات'),
      ...List.generate(
          rules.length,
          (i) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  SizedBox(width: 22, child: Text('${i + 1}.', style: _ts(13, c: VA.cyan, w: FontWeight.w800))),
                  Expanded(child: Text(rules[i], style: _ts(13, h: 1.6))),
                ]),
              )),
      h4(Icons.flag_rounded, 'یاسا'),
      Text('بەشداربوون بەخۆڕاییە. بۆ خەڵاتە گەورەکان دەبێت لانیکەم 25 ڕۆژ لە 30 ڕۆژ چالاک بیت. Apple و Google هیچ بەشێکیان لەم پێشبڕکێیەدا نییە.',
          style: _ts(12.5, c: VA.muted, h: 1.6)),
      const SizedBox(height: 14),
      _Btn(label: 'تێگەیشتم', secondary: true, onTap: () => Navigator.of(context).pop()),
    ]);
  }
}

// ---------------------------------------------------------------- join sheet
class _JoinResult {
  final String name, city, age;
  const _JoinResult(this.name, this.city, this.age);
}

class _JoinSheet extends StatefulWidget {
  final ArenaProfile profile;
  const _JoinSheet({required this.profile});
  @override
  State<_JoinSheet> createState() => _JoinSheetState();
}

class _JoinSheetState extends State<_JoinSheet> {
  final _name = TextEditingController();
  final _q = TextEditingController();
  final _wheel = FixedExtentScrollController();
  List<String> list = kAllCities;
  int idx = 0;
  late String age = widget.profile.age > 0 ? ageGroup(widget.profile.age) : 'a';
  String err = '';

  @override
  void dispose() {
    _name.dispose();
    _q.dispose();
    _wheel.dispose();
    super.dispose();
  }

  void _filter(String q) {
    setState(() {
      list = q.trim().isEmpty ? kAllCities : kAllCities.where((c) => c.contains(q.trim())).toList();
      idx = 0;
    });
    if (_wheel.hasClients) _wheel.jumpToItem(0);
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.profile;
    final hasName = p.name.trim().isNotEmpty;
    return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text('بەشداربوون لە VEX Arena', textAlign: TextAlign.center, style: _ts(18, w: FontWeight.w800)),
      Text('بەخۆڕاییە · تەنها شارەکەت هەڵبژێرە', textAlign: TextAlign.center, style: _ts(12.5, c: VA.muted)),
      const SizedBox(height: 14),
      if (hasName)
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: _al(VA.cyan, .09), borderRadius: BorderRadius.circular(20), border: Border.all(color: VA.line2)),
          child: Row(children: [
            Container(
              width: 46,
              height: 46,
              alignment: Alignment.center,
              decoration: BoxDecoration(shape: BoxShape.circle, gradient: VA.prime),
              child: Text(p.name.trim().characters.first, style: _ts(20, c: VA.ink, w: FontWeight.w900)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(p.name, style: _ts(16, w: FontWeight.w900)),
                Text(
                    [
                      if (p.age > 0) 'تەمەن ${p.age}',
                      if (p.phone.isNotEmpty) maskPhone(normPhone(p.phone)),
                    ].join(' · '),
                    style: _ts(12, c: VA.muted, w: FontWeight.w700)),
              ]),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(color: _al(VA.mint, .14), borderRadius: BorderRadius.circular(99)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.check_rounded, size: 14, color: VA.mint),
                const SizedBox(width: 3),
                Text('لە پڕۆفایلەکەت', style: _ts(11, c: VA.mint, w: FontWeight.w800)),
              ]),
            ),
          ]),
        )
      else ...[
        Text('ناوت', style: _ts(13, c: VA.muted, w: FontWeight.w700)),
        const SizedBox(height: 6),
        _Input(controller: _name, hint: 'بۆ نموونە: ئاراس کەریم', maxLength: 24),
      ],
      const SizedBox(height: 14),
      Row(children: [
        Icon(Icons.place_rounded, size: 15, color: VA.muted),
        const SizedBox(width: 4),
        Text('لە چ شارێکیت؟', style: _ts(13, c: VA.muted, w: FontWeight.w700)),
      ]),
      const SizedBox(height: 6),
      _Input(controller: _q, hint: 'بگەڕێ بۆ شارەکەت...', onChanged: _filter),
      const SizedBox(height: 8),
      Container(
        height: 170,
        decoration: BoxDecoration(color: VA.surf2, borderRadius: BorderRadius.circular(18), border: Border.all(color: VA.line)),
        child: list.isEmpty
            ? Center(child: Text('شارەکە نەدۆزرایەوە', style: _ts(14, c: VA.muted)))
            : Stack(alignment: Alignment.center, children: [
                Container(
                  height: 44,
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                      color: _al(VA.mint, .14), borderRadius: BorderRadius.circular(14), border: Border.all(color: _al(VA.mint, .6), width: 1.5)),
                ),
                ListWheelScrollView.useDelegate(
                  controller: _wheel,
                  itemExtent: 44,
                  diameterRatio: 1.6,
                  physics: const FixedExtentScrollPhysics(),
                  onSelectedItemChanged: (i) {
                    HapticFeedback.selectionClick();
                    setState(() => idx = i);
                  },
                  childDelegate: ListWheelChildBuilderDelegate(
                    childCount: list.length,
                    builder: (_, i) => Center(
                      child: Text(list[i],
                          style: _ts(i == idx ? 18 : 16, w: i == idx ? FontWeight.w800 : FontWeight.w600, c: i == idx ? VA.text : VA.muted)),
                    ),
                  ),
                ),
              ]),
      ),
      if (p.age <= 0) ...[
        const SizedBox(height: 14),
        Text('تەمەنت (بۆ پێشبڕکێیەکی دادپەروەرانە)', style: _ts(13, c: VA.muted, w: FontWeight.w700)),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          children: kAges.map((a) => _Chip(label: a[1], on: age == a[0], onTap: () => setState(() => age = a[0]))).toList(),
        ),
      ],
      SizedBox(
        height: 26,
        child: Center(child: Text(err, style: _ts(12.5, c: VA.coral))),
      ),
      _Btn(
        label: 'دەستپێبکە · کارتەکەم دروست بکە',
        icon: Icons.rocket_launch_rounded,
        big: true,
        onTap: () {
          final n = hasName ? p.name.trim() : _name.text.trim();
          if (n.length < 2) {
            setState(() => err = 'ناوت بنووسە (لانیکەم 2 پیت).');
            return;
          }
          if (list.isEmpty) {
            setState(() => err = 'شارێک هەڵبژێرە.');
            return;
          }
          HapticFeedback.mediumImpact();
          Navigator.of(context).pop(_JoinResult(n.characters.take(24).toString(), list[math.max(0, math.min(idx, list.length - 1))], age));
        },
      ),
    ]);
  }
}

// ---------------------------------------------------------------- character picker
class _CharPickerSheet extends StatefulWidget {
  final String current;
  final CardData Function(String ch) preview;
  const _CharPickerSheet({required this.current, required this.preview});
  @override
  State<_CharPickerSheet> createState() => _CharPickerSheetState();
}

class _CharPickerSheetState extends State<_CharPickerSheet> with SingleTickerProviderStateMixin {
  late String cur = widget.current.isNotEmpty ? widget.current : kCharIds.first;
  late final AnimationController _bob = AnimationController(vsync: this, duration: const Duration(milliseconds: 3400))..repeat(reverse: true);
  int _flip = 0;

  @override
  void dispose() {
    _bob.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text('کارەکتەرەکەت هەڵبژێرە', textAlign: TextAlign.center, style: _ts(18, w: FontWeight.w800)),
      Text('هەمان کارەکتەرەکانی بەشی خێزان و هاوڕێکانە', textAlign: TextAlign.center, style: _ts(12.5, c: VA.muted)),
      const SizedBox(height: 12),
      Center(
        child: TweenAnimationBuilder<double>(
          key: ValueKey(_flip),
          tween: Tween(begin: _flip == 0 ? 0 : 1, end: 0),
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOutBack,
          builder: (_, v, child) => Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, .001)
              ..rotateY(v * 1.2),
            child: Opacity(opacity: (1 - v * .7).clamp(0.0, 1.0), child: child),
          ),
          child: ArenaCardView(data: widget.preview(cur), width: 189),
        ),
      ),
      const SizedBox(height: 14),
      GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, mainAxisSpacing: 10, crossAxisSpacing: 10),
        itemCount: kCharIds.length,
        itemBuilder: (_, i) {
          final id = kCharIds[i];
          final on = id == cur;
          return AnimatedBuilder(
            animation: _bob,
            builder: (_, child) {
              final ph = ((i % 8) / 8 + _bob.value) % 1.0;
              return Transform.translate(offset: Offset(0, -3 * math.sin(ph * math.pi)), child: child);
            },
            child: GestureDetector(
              onTap: () {
                if (on) return;
                HapticFeedback.selectionClick();
                setState(() {
                  cur = id;
                  _flip++;
                });
              },
              child: AnimatedScale(
                scale: on ? 1.06 : 1,
                duration: const Duration(milliseconds: 200),
                child: Stack(children: [
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: [
                        BoxShadow(color: on ? VA.mint : VA.line2, spreadRadius: on ? 3 : 2),
                        if (on) BoxShadow(color: _al(VA.mint, .6), blurRadius: 18, offset: const Offset(0, 6)),
                      ]),
                      child: CharAvatar(ch: id, name: '', size: 80),
                    ),
                  ),
                  Positioned(
                    top: 2,
                    right: 2,
                    child: AnimatedScale(
                      scale: on ? 1 : 0,
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOutBack,
                      child: Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(color: VA.mint, shape: BoxShape.circle),
                        child: Icon(Icons.check_rounded, size: 14, color: VA.ink),
                      ),
                    ),
                  ),
                ]),
              ),
            ),
          );
        },
      ),
      const SizedBox(height: 14),
      _Btn(label: 'لەسەر کارتەکەم دایبنێ', icon: Icons.check_rounded, big: true, onTap: () => Navigator.of(context).pop(cur)),
    ]);
  }
}

// ---------------------------------------------------------------- edit sheet
class _EditSheet extends StatefulWidget {
  final String name, bio;
  const _EditSheet({required this.name, required this.bio});
  @override
  State<_EditSheet> createState() => _EditSheetState();
}

class _EditSheetState extends State<_EditSheet> {
  late final _n = TextEditingController(text: widget.name);
  late final _b = TextEditingController(text: widget.bio);
  @override
  void dispose() {
    _n.dispose();
    _b.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text('دەستکاریی پرۆفایل', textAlign: TextAlign.center, style: _ts(18, w: FontWeight.w800)),
        const SizedBox(height: 12),
        Text('ناو', style: _ts(13, c: VA.muted, w: FontWeight.w700)),
        const SizedBox(height: 6),
        _Input(controller: _n, maxLength: 24),
        const SizedBox(height: 10),
        Text('دەربارەی من', style: _ts(13, c: VA.muted, w: FontWeight.w700)),
        const SizedBox(height: 6),
        _Input(controller: _b, maxLength: 60),
        const SizedBox(height: 14),
        _Btn(label: 'پاشەکەوتکردن', icon: Icons.check_rounded, onTap: () => Navigator.of(context).pop([_n.text, _b.text])),
      ]);
}

// =============================================================================
// 9. ئەنیمەیشنی دروستبوونی کارت (3D) + کۆنفێتی
// =============================================================================

class _CardReveal extends StatefulWidget {
  final CardData data;
  final League league;
  const _CardReveal({required this.data, required this.league});
  @override
  State<_CardReveal> createState() => _CardRevealState();
}

class _CardRevealState extends State<_CardReveal> with TickerProviderStateMixin {
  late final AnimationController _in = AnimationController(vsync: this, duration: const Duration(milliseconds: 2050));
  late final AnimationController _rays = AnimationController(vsync: this, duration: const Duration(seconds: 26))..repeat();
  late final AnimationController _burst = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100));
  late final AnimationController _out = AnimationController(vsync: this, duration: const Duration(milliseconds: 520));
  bool landed = false;

  @override
  void initState() {
    super.initState();
    HapticFeedback.lightImpact();
    _in.forward().whenComplete(() {
      if (!mounted) return;
      setState(() => landed = true);
      HapticFeedback.heavyImpact();
      _burst.forward();
      showConfetti(context);
    });
  }

  @override
  void dispose() {
    _in.dispose();
    _rays.dispose();
    _burst.dispose();
    _out.dispose();
    super.dispose();
  }

  /// هەمان ڕێڕەوی وێب: لە دوورەوە دێت و 3 جار دەسووڕێتەوە، پاشان کەمێک تێدەپەڕێت و دادەنیشێت
  Matrix4 _cardMatrix(double t) {
    double ry, rx, z, y;
    if (t < .72) {
      final k = Curves.easeOutCubic.transform(t / .72);
      ry = _lerp(-6 * math.pi, -8 * math.pi / 180, k);
      rx = _lerp(28 * math.pi / 180, -6 * math.pi / 180, k);
      z = _lerp(-1600, 90, k);
      y = _lerp(40, -14, k);
    } else if (t < .86) {
      final k = Curves.easeInOut.transform((t - .72) / .14);
      ry = _lerp(-8, 4, k) * math.pi / 180;
      rx = _lerp(-6, 2, k) * math.pi / 180;
      z = _lerp(90, 0, k);
      y = _lerp(-14, 4, k);
    } else {
      final k = Curves.easeOut.transform((t - .86) / .14);
      ry = _lerp(4, 0, k) * math.pi / 180;
      rx = _lerp(2, 0, k) * math.pi / 180;
      z = 0;
      y = _lerp(4, 0, k);
    }
    final scale = 1200 / (1200 - z); // perspective 1200px
    return Matrix4.identity()
      ..setEntry(3, 2, 1 / 1200)
      ..translate(0.0, y)
      ..scale(scale)
      ..rotateX(rx)
      ..rotateY(ry);
  }

  double _lerp(double a, double b, double t) => a + (b - a) * t;

  @override
  Widget build(BuildContext context) {
    final d = widget.data;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: AnimatedBuilder(
        animation: _out,
        builder: (_, child) => Opacity(opacity: 1 - _out.value, child: child),
        child: Material(
          color: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                  center: Alignment(0, -.24), radius: 1.1, colors: [vk(0xFF0D4F5E), vk(0xFF04202A), vk(0xFF010B10)], stops: [0, .45, 1]),
            ),
            child: Stack(alignment: Alignment.center, children: [
              // rotating rays
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _rays,
                  builder: (_, __) => CustomPaint(painter: _RaysPainter(_rays.value * 2 * math.pi, _in.value)),
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    SizedBox(
                      width: 236,
                      height: 330,
                      child: Stack(clipBehavior: Clip.none, alignment: Alignment.center, children: [
                        // sparks + ring burst
                        AnimatedBuilder(
                          animation: _burst,
                          builder: (_, __) => CustomPaint(size: const Size(236, 330), painter: _BurstPainter(_burst.value)),
                        ),
                        AnimatedBuilder(
                          animation: Listenable.merge([_in, _out]),
                          builder: (_, __) {
                            final m = _cardMatrix(_in.value);
                            final outT = Curves.easeIn.transform(_out.value);
                            final angle = _faceAngle(m);
                            final front = angle;
                            return Transform.translate(
                              offset: Offset(0, MediaQuery.of(context).size.height * .3 * outT),
                              child: Transform.scale(
                                scale: 1 - .5 * outT,
                                child: Transform(
                                  alignment: Alignment.center,
                                  transform: m,
                                  child: front
                                      ? ArenaCardView(data: d)
                                      : Transform(
                                          alignment: Alignment.center,
                                          transform: Matrix4.rotationY(math.pi),
                                          child: const _CardBack(),
                                        ),
                                ),
                              ),
                            );
                          },
                        ),
                      ]),
                    ),
                    const SizedBox(height: 30),
                    AnimatedOpacity(
                      opacity: landed ? 1 : 0,
                      duration: const Duration(milliseconds: 600),
                      child: AnimatedSlide(
                        offset: landed ? Offset.zero : const Offset(0, .15),
                        duration: const Duration(milliseconds: 600),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 360),
                          child: Column(children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                  color: _al(VA.mint, .14), borderRadius: BorderRadius.circular(99), border: Border.all(color: _al(VA.mint, .35))),
                              child: Row(mainAxisSize: MainAxisSize.min, children: [
                                Icon(Icons.auto_awesome_rounded, size: 14, color: vk(0xFF7CF7B4)),
                                const SizedBox(width: 6),
                                Text('وەرزی ${Season.number} · بەشدارییەکەت قبوڵ کرا', style: _ts(12, c: vk(0xFF7CF7B4), w: FontWeight.w800)),
                              ]),
                            ),
                            const SizedBox(height: 10),
                            ShaderMask(
                              shaderCallback: (r) => VA.prime.createShader(r),
                              child: Text('کارتەکەت ئامادەیە!', style: _ts(26, c: kW, w: FontWeight.w900)),
                            ),
                            const SizedBox(height: 4),
                            Text.rich(
                              TextSpan(children: [
                                TextSpan(text: 'بەخێربێیت ${d.name} · لە لیگی '),
                                TextSpan(text: widget.league.name, style: _ts(13.5, c: kW, w: FontWeight.w800)),
                                const TextSpan(text: ' دەست پێدەکەیت · پلەی '),
                                TextSpan(text: '#${_fmt(d.rank)}', style: _ts(13.5, c: kW, w: FontWeight.w800)),
                              ]),
                              textAlign: TextAlign.center,
                              style: _ts(13.5, c: _al(vk(0xFFEAFCFF), .78), h: 1.6),
                            ),
                            const SizedBox(height: 16),
                            _Btn(
                              label: 'کارتەکەم دابنێ',
                              icon: Icons.check_rounded,
                              big: true,
                              onTap: () async {
                                if (!landed) return;
                                HapticFeedback.mediumImpact();
                                await _out.forward();
                                if (mounted) Navigator.of(context).pop();
                              },
                            ),
                          ]),
                        ),
                      ),
                    ),
                  ]),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  /// ڕووی پێشەوە یان پشتەوە دیارە؟ (وەک backface-visibility)
  bool _faceAngle(Matrix4 m) {
    // نۆرماڵی کارت (0,0,1) دوای گۆڕان: ستوونی سێیەمی ماتریکس
    final nz = m.entry(2, 2);
    return nz >= 0;
  }
}

class _CardBack extends StatelessWidget {
  const _CardBack();
  @override
  Widget build(BuildContext context) => Container(
        width: 236,
        height: 330,
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30), bottom: Radius.circular(26)),
          gradient: RadialGradient(
              center: Alignment(0, -.3), colors: [vk(0xFF1FD4C4), vk(0xFF0B5E74), vk(0xFF06303C)], stops: [0, .55, 1]),
          border: Border.all(color: _al(kW, .22), width: 1.5),
        ),
        alignment: Alignment.center,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('VEX',
              style: TextStyle(
                  fontSize: 46,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2,
                  color: kW,
                  shadows: [Shadow(color: _al(Colors.black, .35), blurRadius: 20, offset: const Offset(0, 4))])),
          const SizedBox(height: 6),
          Text('ARENA', style: TextStyle(fontSize: 12, letterSpacing: 6, color: _al(kW, .85))),
        ]),
      );
}

class _RaysPainter extends CustomPainter {
  final double angle, appear;
  _RaysPainter(this.angle, this.appear);
  @override
  void paint(Canvas canvas, Size s) {
    final c = Offset(s.width / 2, s.height * .38);
    final r = 450.0;
    final o = (appear * 2).clamp(0.0, 1.0);
    final p = Paint()
      ..shader = RadialGradient(colors: [_al(vk(0xFF8FF3F9), .09 * o), _al(vk(0xFF8FF3F9), 0)], stops: const [0, .6])
          .createShader(Rect.fromCircle(center: c, radius: r));
    for (var i = 0; i < 16; i++) {
      final a = angle + i * (2 * math.pi / 16);
      final path = Path()
        ..moveTo(c.dx, c.dy)
        ..lineTo(c.dx + r * math.cos(a), c.dy + r * math.sin(a))
        ..lineTo(c.dx + r * math.cos(a + .14), c.dy + r * math.sin(a + .14))
        ..close();
      canvas.drawPath(path, p);
    }
  }

  @override
  bool shouldRepaint(_RaysPainter o) => o.angle != angle || o.appear != appear;
}

class _BurstPainter extends CustomPainter {
  final double t;
  _BurstPainter(this.t);
  @override
  void paint(Canvas canvas, Size s) {
    if (t <= 0 || t >= 1) return;
    final c = Offset(s.width / 2, s.height / 2);
    // ring
    canvas.drawCircle(
        c,
        118 * (.6 + 1.6 * t),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = _al(vk(0xFF8FF3F9), .9 * (1 - t)));
    // sparks
    for (var i = 0; i < 18; i++) {
      final delay = (i % 6) * .08;
      final k = ((t - delay) / (1 - delay)).clamp(0.0, 1.0);
      if (k <= 0) continue;
      final e = Curves.easeOutCubic.transform(k);
      final a = i * 20 * math.pi / 180;
      final d = 30 + 180 * e;
      final col = i % 3 == 2 ? vk(0xFFFFD56B) : vk(0xFF8FF3F9);
      final pos = c + Offset(math.cos(a) * d, math.sin(a) * d);
      canvas.drawCircle(pos, 3 * (1 - .6 * e), Paint()..color = _al(col, 1 - e));
      canvas.drawCircle(pos, 7 * (1 - .6 * e), Paint()..color = _al(col, .25 * (1 - e)));
    }
  }

  @override
  bool shouldRepaint(_BurstPainter o) => o.t != t;
}

/// کۆنفێتی بەسەر هەموو شاشەکەدا
void showConfetti(BuildContext context) {
  final ov = Overlay.maybeOf(context, rootOverlay: true);
  if (ov == null) return;
  late OverlayEntry e;
  e = OverlayEntry(builder: (_) => _Confetti(onDone: () => e.remove()));
  ov.insert(e);
}

class _Confetti extends StatefulWidget {
  final VoidCallback onDone;
  const _Confetti({required this.onDone});
  @override
  State<_Confetti> createState() => _ConfettiState();
}

class _ConfettiState extends State<_Confetti> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 3200));
  final _r = math.Random();
  late final List<List<double>> bits = List.generate(70, (_) => [_r.nextDouble(), _r.nextDouble() * .6, .6 + _r.nextDouble() * .7, _r.nextDouble() * 6, _r.nextInt(5).toDouble(), 5 + _r.nextDouble() * 5]);

  @override
  void initState() {
    super.initState();
    _c.forward().whenComplete(widget.onDone);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: AnimatedBuilder(animation: _c, builder: (_, __) => CustomPaint(size: Size.infinite, painter: _ConfettiPainter(_c.value, bits))),
      );
}

class _ConfettiPainter extends CustomPainter {
  final double t;
  final List<List<double>> bits;
  _ConfettiPainter(this.t, this.bits);
  static get cols => [vk(0xFFFFD56B), vk(0xFF3CF08A), vk(0xFF2FE6F3), vk(0xFF9B7BFF), vk(0xFFFF6F86)];
  @override
  void paint(Canvas canvas, Size s) {
    for (final b in bits) {
      final k = ((t - b[1] * .5) / (1 - b[1] * .5)).clamp(0.0, 1.0);
      if (k <= 0) continue;
      final x = b[0] * s.width + math.sin(k * 6 + b[3]) * 18;
      final y = -20 + k * (s.height * 1.1) * b[2];
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(k * 12 + b[3]);
      canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: b[5], height: b[5] * .55),
          Paint()..color = _al(cols[b[4].toInt()], (1 - k * .6).clamp(0.0, 1.0)));
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter o) => o.t != t;
}

// =============================================================================
// 10. ویجێتە بچووکەکان
// =============================================================================

class _Card extends StatelessWidget {
  final Widget child;
  final bool glow;
  final EdgeInsets margin;
  const _Card({required this.child, this.glow = false, this.margin = const EdgeInsets.only(top: 14)});
  @override
  Widget build(BuildContext context) => Container(
        margin: margin,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: VA.surf,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: glow ? VA.line2 : VA.line),
          gradient: glow
              ? LinearGradient(colors: [_al(vk(0xFF0F5566), .9), _al(vk(0xFF0A3644), .9)], begin: Alignment.topLeft, end: Alignment.bottomRight)
              : null,
          boxShadow: glow ? [BoxShadow(color: _al(VA.cyan, .12), blurRadius: 30, offset: const Offset(0, 12))] : null,
        ),
        child: child,
      );
}

class _Box extends StatelessWidget {
  final Widget child;
  const _Box({required this.child});
  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(top: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: VA.surf, borderRadius: BorderRadius.circular(22), border: Border.all(color: VA.line)),
        child: child,
      );
}

class _Title extends StatelessWidget {
  final IconData icon;
  final String text;
  final String? note;
  const _Title({required this.icon, required this.text, this.note});
  @override
  Widget build(BuildContext context) => Row(children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(color: _al(VA.cyan, .12), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, size: 16, color: VA.cyan),
        ),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: _ts(15.5, w: FontWeight.w800))),
        if (note != null) Flexible(child: Text(note!, textAlign: TextAlign.end, style: _ts(11.5, c: VA.muted))),
      ]);
}

class _Btn extends StatefulWidget {
  final String label;
  final IconData? icon;
  final VoidCallback onTap;
  final bool secondary, danger, big;
  const _Btn({required this.label, required this.onTap, this.icon, this.secondary = false, this.danger = false, this.big = false});
  @override
  State<_Btn> createState() => _BtnState();
}

class _BtnState extends State<_Btn> {
  bool _down = false;
  @override
  Widget build(BuildContext context) {
    final fg = widget.danger ? VA.coral : widget.secondary ? VA.text : VA.ink;
    return GestureDetector(
      onTapDown: (_) => setState(() => _down = true),
      onTapCancel: () => setState(() => _down = false),
      onTapUp: (_) => setState(() => _down = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _down ? .97 : 1,
        duration: const Duration(milliseconds: 120),
        child: Container(
          height: widget.big ? 56 : 50,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            gradient: widget.secondary || widget.danger ? null : VA.prime,
            color: widget.danger ? _al(VA.coral, .12) : widget.secondary ? VA.surf2 : null,
            borderRadius: BorderRadius.circular(18),
            border: widget.secondary ? Border.all(color: VA.line2) : widget.danger ? Border.all(color: _al(VA.coral, .35)) : null,
            boxShadow: !widget.secondary && !widget.danger
                ? [BoxShadow(color: _al(VA.mint, .3), blurRadius: 22, offset: const Offset(0, 10), spreadRadius: -8)]
                : null,
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            if (widget.icon != null) ...[Icon(widget.icon, size: 19, color: fg), const SizedBox(width: 8)],
            Flexible(
              child: Text(widget.label,
                  textAlign: TextAlign.center, maxLines: 2, style: _ts(widget.big ? 15.5 : 14.5, c: fg, w: FontWeight.w800, h: 1.3)),
            ),
          ]),
        ),
      ),
    );
  }
}

class _SqBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _SqBtn({required this.icon, required this.onTap});
  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(color: VA.surf2, borderRadius: BorderRadius.circular(18), border: Border.all(color: VA.line2)),
          child: Icon(icon, size: 19, color: VA.text),
        ),
      );
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _IconBtn({required this.icon, required this.onTap});
  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(color: VA.surf, borderRadius: BorderRadius.circular(14), border: Border.all(color: VA.line)),
          child: Icon(icon, size: 21, color: VA.text),
        ),
      );
}

class _CoinPill extends StatelessWidget {
  final int coins;
  const _CoinPill({required this.coins});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsetsDirectional.fromSTEB(12, 7, 10, 7),
        decoration: BoxDecoration(color: VA.surf, borderRadius: BorderRadius.circular(99), border: Border.all(color: VA.line)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          TweenAnimationBuilder<double>(
            tween: Tween(end: coins.toDouble()),
            duration: const Duration(milliseconds: 700),
            builder: (_, v, __) => Text(_fmt(v), style: _ts(13, w: FontWeight.w800)),
          ),
          const SizedBox(width: 6),
          Container(
            width: 19,
            height: 19,
            decoration: BoxDecoration(shape: BoxShape.circle, gradient: VA.goldG),
            child: Icon(Icons.star_rounded, size: 12, color: vk(0xFF6B4300)),
          ),
        ]),
      );
}

class _Seg extends StatelessWidget {
  final List<List<Object>> items;
  final String value;
  final ValueChanged<String> onChanged;
  const _Seg({required this.items, required this.value, required this.onChanged});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: vk(0xFF06303C),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: VA.line),
          boxShadow: [BoxShadow(color: _al(Colors.black, .4), blurRadius: 18, offset: const Offset(0, 8), spreadRadius: -12)],
        ),
        child: Row(
          children: items.map((t) {
            final on = t[0] == value;
            return Expanded(
              child: GestureDetector(
                onTap: () => onChanged(t[0] as String),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    gradient: on ? VA.prime : null,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: on ? [BoxShadow(color: _al(VA.mint, .35), blurRadius: 18, offset: const Offset(0, 6), spreadRadius: -6)] : null,
                  ),
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(t[2] as IconData, size: 16, color: on ? VA.ink : VA.muted),
                    const SizedBox(width: 6),
                    Text(t[1] as String, style: _ts(13, w: FontWeight.w800, c: on ? VA.ink : VA.muted)),
                  ]),
                ),
              ),
            );
          }).toList(),
        ),
      );
}

class _Chip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool on, dim;
  final VoidCallback onTap;
  const _Chip({required this.label, required this.on, required this.onTap, this.icon, this.dim = false});
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
          decoration: BoxDecoration(
            color: on ? _al(VA.mint, .14) : VA.surf2,
            borderRadius: BorderRadius.circular(99),
            border: Border.all(color: on ? VA.mint : VA.line),
          ),
          child: Opacity(
            opacity: dim ? .5 : 1,
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              if (icon != null) ...[Icon(icon, size: 14, color: on ? VA.mint : VA.muted), const SizedBox(width: 5)],
              Text(label, style: _ts(12.5, w: FontWeight.w800, c: on ? VA.mint : VA.text)),
            ]),
          ),
        ),
      );
}

class _Input extends StatelessWidget {
  final TextEditingController controller;
  final String? hint;
  final int? maxLength;
  final ValueChanged<String>? onChanged;
  const _Input({required this.controller, this.hint, this.maxLength, this.onChanged});
  @override
  Widget build(BuildContext context) => TextField(
        controller: controller,
        onChanged: onChanged,
        maxLength: maxLength,
        style: _ts(15),
        cursorColor: VA.cyan,
        decoration: InputDecoration(
          counterText: '',
          hintText: hint,
          hintStyle: _ts(15, c: _al(VA.muted, .7)),
          filled: true,
          fillColor: VA.surf2,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: VA.line)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: VA.cyan, width: 1.5)),
        ),
      );
}

class _StatTile extends StatelessWidget {
  final String label;
  final Widget value;
  const _StatTile({required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(color: _al(kW, .04), borderRadius: BorderRadius.circular(16), border: Border.all(color: VA.line)),
        child: Row(children: [
          Expanded(child: Text(label, style: _ts(12, c: VA.muted, w: FontWeight.w600))),
          value,
        ]),
      );
}

class _MiniStat extends StatelessWidget {
  final String label, value;
  final String? unit;
  const _MiniStat({required this.label, required this.value, this.unit});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: _al(VA.cyan, .09), borderRadius: BorderRadius.circular(16)),
        child: Column(children: [
          Text(label, style: _ts(11, c: VA.muted, w: FontWeight.w700)),
          Text(value, style: _ts(20, w: FontWeight.w900)),
          if (unit != null) Text(unit!, style: _ts(11, c: VA.muted, w: FontWeight.w700)),
        ]),
      );
}

class _Note extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String text;
  const _Note({required this.color, required this.icon, required this.text});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
            color: _al(color, .12), borderRadius: BorderRadius.circular(14), border: Border.all(color: _al(color, .3))),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(padding: const EdgeInsets.only(top: 2), child: Icon(icon, size: 16, color: color)),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: _ts(12.5, h: 1.6))),
        ]),
      );
}

class _RuleLine extends StatelessWidget {
  final IconData icon;
  final String text;
  const _RuleLine({required this.icon, required this.text});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 9),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(color: _al(VA.cyan, .12), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, size: 15, color: VA.cyan),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: _ts(13, h: 1.6))),
        ]),
      );
}

class _InfoLine extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  _InfoLine({required this.icon, required this.text, Color? color}) : color = color ?? VA.muted;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(padding: const EdgeInsets.only(top: 2), child: Icon(icon, size: 15, color: color)),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: _ts(13, c: VA.text, h: 1.55))),
        ]),
      );
}

class _AiRow extends StatelessWidget {
  final bool ok;
  final String title, sub;
  const _AiRow({required this.ok, required this.title, required this.sub});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: VA.line))),
        child: Row(children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(color: _al(ok ? VA.mint : VA.coral, .14), borderRadius: BorderRadius.circular(10)),
            child: Icon(ok ? Icons.check_rounded : Icons.close_rounded, size: 16, color: ok ? VA.mint : VA.coral),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: _ts(13.5, w: FontWeight.w700)),
              Text(sub, style: _ts(11.5, c: VA.muted)),
            ]),
          ),
        ]),
      );
}

class CatTile extends StatelessWidget {
  final ArenaCat cat;
  final double size;
  const CatTile({super.key, required this.cat, this.size = 40});
  @override
  Widget build(BuildContext context) => _IconTile(icon: cat.icon, color: cat.color, size: size);
}

class _IconTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;
  const _IconTile({required this.icon, required this.color, this.size = 40});
  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(size * .32),
          gradient: LinearGradient(
            colors: [Color.lerp(color, kW, .15)!, Color.lerp(color, Colors.black, .25)!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [BoxShadow(color: _al(color, .35), blurRadius: size * .3, offset: Offset(0, size * .12), spreadRadius: -size * .1)],
        ),
        child: Icon(icon, size: size * .54, color: kW),
      );
}

class _ActivityTile extends StatelessWidget {
  final ArenaCat cat;
  final String value, points;
  final bool active;
  final VoidCallback onTap;
  const _ActivityTile({required this.cat, required this.value, required this.points, required this.active, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Opacity(
          opacity: active ? 1 : .55,
          child: Container(
            padding: const EdgeInsets.fromLTRB(4, 10, 4, 8),
            decoration: BoxDecoration(color: _al(kW, .04), borderRadius: BorderRadius.circular(18), border: Border.all(color: VA.line)),
            child: Stack(children: [
              if (active)
                Positioned(
                  top: 0,
                  right: 4,
                  child: Container(width: 7, height: 7, decoration: BoxDecoration(color: VA.mint, shape: BoxShape.circle)),
                ),
              Column(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                CatTile(cat: cat, size: 38),
                Text(cat.name, textAlign: TextAlign.center, maxLines: 2, style: _ts(11.5, w: FontWeight.w800, h: 1.25)),
                Text(value, textAlign: TextAlign.center, maxLines: 2, style: _ts(9.5, c: VA.muted, h: 1.3)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: _al(VA.violet, .16), borderRadius: BorderRadius.circular(99)),
                  child: Text(points, style: _ts(10.5, c: vk(0xFFC9B8FF), w: FontWeight.w800)),
                ),
              ]),
            ]),
          ),
        ),
      );
}

class _Podium extends StatelessWidget {
  final ArenaPlayer p;
  final int place;
  final double h, size;
  final Color color;
  final Widget val;
  final ValueChanged<ArenaPlayer> onTap;
  const _Podium({required this.p, required this.place, required this.h, required this.color, required this.size, required this.val, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: () => onTap(p),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          if (place == 1) Icon(Icons.workspace_premium_rounded, color: VA.gold, size: 26),
          CharAvatar(ch: p.ch, name: p.name, size: size, ring: color, grad: p.grad),
          const SizedBox(height: 6),
          Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: _ts(12.5, w: FontWeight.w800)),
          Text(p.city, style: _ts(10.5, c: VA.muted)),
          val,
          const SizedBox(height: 4),
          Container(
            height: h,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
              gradient: LinearGradient(colors: [color, _al(color, .45)], begin: Alignment.topCenter, end: Alignment.bottomCenter),
            ),
            child: Text('$place', style: _ts(22, c: vk(0xFF2B1D05), w: FontWeight.w900)),
          ),
        ]),
      );
}

class _RankRow extends StatelessWidget {
  final String rank;
  final ArenaPlayer p;
  final Widget value;
  final VoidCallback onTap;
  const _RankRow({required this.rank, required this.p, required this.value, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final lg = leagueOf(p.points);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: VA.line))),
        child: Row(children: [
          SizedBox(width: 44, child: Text(rank, style: _ts(13, c: VA.muted, w: FontWeight.w800))),
          CharAvatar(ch: p.ch, name: p.name, size: 40, ring: lg.accent, grad: p.grad),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(p.name, style: _ts(14, w: FontWeight.w800), overflow: TextOverflow.ellipsis),
              Row(children: [
                Flexible(child: Text('${p.city} · ${lg.name} · ', style: _ts(11.5, c: VA.muted), overflow: TextOverflow.ellipsis)),
                Icon(Icons.local_fire_department_rounded, size: 12, color: vk(0xFFFF9466)),
                Text('${p.streak}', style: _ts(11.5, c: VA.muted)),
              ]),
            ]),
          ),
          SizedBox(
            width: 34,
            child: p.move == 0
                ? Text('–', textAlign: TextAlign.center, style: _ts(12, c: VA.muted))
                : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(p.move > 0 ? Icons.arrow_drop_up_rounded : Icons.arrow_drop_down_rounded,
                        size: 18, color: p.move > 0 ? VA.mint : VA.coral),
                    Text('${p.move.abs()}', style: _ts(11.5, c: p.move > 0 ? VA.mint : VA.coral, w: FontWeight.w800)),
                  ]),
          ),
          const SizedBox(width: 6),
          value,
        ]),
      ),
    );
  }
}

class _PrizeRow extends StatelessWidget {
  const _PrizeRow();
  @override
  Widget build(BuildContext context) {
    Widget pz(int n, IconData ic, String name, Color c, {bool big = false}) => Expanded(
          flex: big ? 23 : 20,
          child: Stack(clipBehavior: Clip.none, alignment: Alignment.topCenter, children: [
            Container(
              margin: const EdgeInsets.only(top: 10),
              padding: EdgeInsets.fromLTRB(4, big ? 18 : 14, 4, 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                color: _al(c, .1),
                border: Border.all(color: _al(c, .4)),
              ),
              child: Column(children: [
                Icon(ic, size: big ? 30 : 24, color: c),
                const SizedBox(height: 6),
                Text(name, textAlign: TextAlign.center, maxLines: 2, style: _ts(12, w: FontWeight.w800, h: 1.3)),
              ]),
            ),
            Container(
              width: 22,
              height: 22,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: c, shape: BoxShape.circle),
              child: Text('$n', style: _ts(11, c: vk(0xFF2B1D05), w: FontWeight.w900)),
            ),
          ]),
        );
    return Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
      pz(2, Icons.phone_iphone_rounded, 'iPhone 17 Pro', VA.silver),
      const SizedBox(width: 8),
      pz(1, Icons.directions_car_filled_rounded, 'ئۆتۆمبێل', VA.gold, big: true),
      const SizedBox(width: 8),
      pz(3, Icons.payments_rounded, '1,000,000 دینار', VA.bronze),
    ]);
  }
}

/// نوارە جووڵاوەکەی خەڵاتەکان — پەنجەی لێبدە وردەکارییەکان دەکرێتەوە
class _PrizeTicker extends StatefulWidget {
  final int daysLeft;
  final VoidCallback onTap;
  const _PrizeTicker({required this.daysLeft, required this.onTap});
  @override
  State<_PrizeTicker> createState() => _PrizeTickerState();
}

class _PrizeTickerState extends State<_PrizeTicker> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(seconds: 30))..repeat();
  final _k = GlobalKey();
  double _w = 0;
  bool _down = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
  }

  void _measure() {
    final b = _k.currentContext?.findRenderObject() as RenderBox?;
    if (b != null && b.hasSize && mounted) setState(() => _w = b.size.width);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Widget _items({Key? key}) {
    Widget it(IconData i, Color c, String a, String b) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 13),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(i, size: 15, color: c),
            const SizedBox(width: 5),
            Text(a, style: _ts(13, w: FontWeight.w700)),
            Text(b, style: _ts(13, c: VA.gold, w: FontWeight.w800)),
          ]),
        );
    return Row(key: key, mainAxisSize: MainAxisSize.min, children: [
      it(Icons.workspace_premium_rounded, VA.gold, 'پلەی یەکەم: ', 'ئۆتۆمبێل'),
      it(Icons.phone_iphone_rounded, VA.silver, 'پلەی دووەم: ', 'iPhone 17 Pro'),
      it(Icons.payments_rounded, VA.bronze, 'پلەی سێیەم: ', '1,000,000 دینار'),
      it(Icons.card_giftcard_rounded, VA.gold, 'هەموو ئەوانەی 30 ڕۆژ تەواو دەکەن ', 'خەڵاتیان هەیە'),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _down = true),
      onTapCancel: () => setState(() => _down = false),
      onTapUp: (_) => setState(() => _down = false),
      onTap: () {
        HapticFeedback.selectionClick();
        widget.onTap();
      },
      child: AnimatedScale(
        scale: _down ? .98 : 1,
        duration: const Duration(milliseconds: 150),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: LinearGradient(colors: [_al(VA.gold, .13), _al(VA.gold, .03)]),
            border: Border.all(color: _al(VA.gold, .28)),
          ),
          child: Row(children: [
            Expanded(
              child: ShaderMask(
                shaderCallback: (r) => const LinearGradient(
                  colors: [Colors.transparent, Colors.black, Colors.black, Colors.transparent],
                  stops: [0, .08, .92, 1],
                ).createShader(r),
                blendMode: BlendMode.dstIn,
                child: ClipRect(
                  child: SizedBox(
                    height: 22,
                    child: AnimatedBuilder(
                      animation: _c,
                      builder: (_, child) => OverflowBox(
                        alignment: AlignmentDirectional.centerStart,
                        maxWidth: double.infinity,
                        child: Transform.translate(offset: Offset(_w * _c.value, 0), child: child),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [_items(key: _k), _items()]),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.hourglass_bottom_rounded, size: 14, color: VA.gold),
            const SizedBox(width: 3),
            Text('${widget.daysLeft} ڕۆژ', style: _ts(12, c: VA.gold, w: FontWeight.w800)),
            const SizedBox(width: 8),
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(color: _al(VA.gold, .18), shape: BoxShape.circle),
              child: Icon(Icons.chevron_left_rounded, size: 18, color: VA.gold),
            ),
          ]),
        ),
      ),
    );
  }
}

class _MysteryCard extends StatefulWidget {
  final String power;
  final String? guess;
  final bool revealed;
  final ValueChanged<String> onGuess;
  final VoidCallback onDemoReveal;
  const _MysteryCard({required this.power, required this.guess, required this.revealed, required this.onGuess, required this.onDemoReveal});
  @override
  State<_MysteryCard> createState() => _MysteryCardState();
}

class _MysteryCardState extends State<_MysteryCard> with SingleTickerProviderStateMixin {
  late final AnimationController _spin = AnimationController(vsync: this, duration: const Duration(seconds: 24))..repeat();
  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final g = widget.guess, rev = widget.revealed, p = catById(widget.power);
    final won = rev && g == widget.power;
    Widget lock;
    if (rev) {
      lock = _Note(
          color: won ? VA.mint : VA.amber,
          icon: won ? Icons.check_rounded : Icons.lightbulb_rounded,
          text: won ? 'ڕاستت پێکا! هێزی ئەمڕۆ ${p.name} بوو · +50 خاڵ' : 'هێزی ئەمڕۆ ${p.name} بوو · سبەینێ هێزێکی نوێ دەبێت');
    } else if (g != null) {
      lock = _Note(color: VA.violet, icon: Icons.lock_rounded, text: 'پێشبینییەکەت: ${catById(g).name} · ئەنجام لە نیوەشەو ئاشکرا دەبێت');
    } else {
      lock = _Note(color: VA.violet, icon: Icons.auto_awesome_rounded, text: 'پێشبینی بکە کامەیە؛ ئەگەر ڕاست بێت +50 خاڵ وەردەگریت');
    }
    return Container(
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: LinearGradient(colors: [vk(0xFF3A2378), vk(0xFF221453)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        border: Border.all(color: _al(VA.violet, .45)),
        boxShadow: [BoxShadow(color: _al(VA.violet, .25), blurRadius: 30, offset: const Offset(0, 12))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('هێزی نهێنیی ئەمڕۆ', style: _ts(19, w: FontWeight.w800)),
              const SizedBox(height: 4),
              Text.rich(
                TextSpan(children: [
                  const TextSpan(text: 'یەکێک لەم 11 بەشە ئەمڕۆ '),
                  TextSpan(text: '×3', style: _ts(13, w: FontWeight.w900)),
                  const TextSpan(text: 'ـە و یەکێکی تر '),
                  TextSpan(text: '×1.5', style: _ts(13, w: FontWeight.w900)),
                  const TextSpan(text: '. تا نیوەشەو کەس نازانێت.'),
                ]),
                style: _ts(13, c: _al(VA.text, .8), h: 1.6),
              ),
            ]),
          ),
          SizedBox(
            width: 112,
            height: 112,
            child: AnimatedBuilder(
              animation: _spin,
              builder: (_, __) => Stack(alignment: Alignment.center, children: [
                Container(
                  width: 104,
                  height: 104,
                  decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: _al(kW, .15), style: BorderStyle.solid)),
                ),
                ...List.generate(kArenaCats.length, (i) {
                  final a = i / kArenaCats.length * 2 * math.pi + _spin.value * 2 * math.pi;
                  return Transform.translate(
                    offset: Offset(math.cos(a) * 49, math.sin(a) * 49),
                    child: Icon(kArenaCats[i].icon, size: 14, color: _al(kW, .75)),
                  );
                }),
                Container(
                  width: 58,
                  height: 58,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(colors: [vk(0xFFB79CFF), vk(0xFF6A3AE8)]),
                    boxShadow: [BoxShadow(color: _al(VA.violet, .7), blurRadius: 24)],
                  ),
                  child: rev ? Icon(p.icon, size: 26, color: kW) : Text('?', style: _ts(30, c: kW, w: FontWeight.w900)),
                ),
              ]),
            ),
          ),
        ]),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(color: _al(Colors.black, .2), borderRadius: BorderRadius.circular(16)),
          child: Row(children: [
            Icon(Icons.lightbulb_rounded, size: 18, color: VA.gold),
            const SizedBox(width: 8),
            Expanded(child: Text('ئاماژە: ${kHints[widget.power]}', style: _ts(13.5, w: FontWeight.w700))),
          ]),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: kArenaCats.map((c) {
            final on = g == c.id, win = rev && c.id == widget.power;
            final disabled = g != null || rev;
            return GestureDetector(
              onTap: disabled ? null : () => widget.onGuess(c.id),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: win ? _al(VA.mint, .22) : on ? _al(VA.violet, .4) : _al(kW, .06),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: win ? VA.mint : on ? VA.violet : _al(kW, .12), width: on || win ? 2 : 1),
                ),
                child: Opacity(opacity: disabled && !on && !win ? .5 : 1, child: Icon(c.icon, size: 21, color: kW)),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 10),
        lock,
        if (g != null && !rev) ...[
          const SizedBox(height: 8),
          TextButton(
            onPressed: widget.onDemoReveal,
            child: Text('تاقیکردنەوە: نیوەشەو ئاشکرا بکە (دیمۆ)', style: _ts(12, c: _al(VA.text, .7))),
          ),
        ],
      ]),
    );
  }
}

class _CountUp extends StatelessWidget {
  final int value;
  final TextStyle style;
  final Gradient? shader;
  const _CountUp({required this.value, required this.style, this.shader});
  @override
  Widget build(BuildContext context) {
    final t = TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value.toDouble()),
      duration: const Duration(milliseconds: 1300),
      curve: Curves.easeOutCubic,
      builder: (_, v, __) => Text(_fmt(v), style: style),
    );
    if (shader == null) return t;
    return ShaderMask(shaderCallback: (r) => shader!.createShader(r), child: t);
  }
}

// =============================================================================
// 11. ڕاکردنی بە تەنیا:  flutter run -t lib/vex_arena.dart
// =============================================================================

class VexArenaDemoApp extends StatelessWidget {
  const VexArenaDemoApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'VEX Arena',
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark(useMaterial3: true).copyWith(
          scaffoldBackgroundColor: VA.bg,
          colorScheme: ColorScheme.dark(primary: VA.cyan, secondary: VA.mint, surface: VA.bg2),
        ),
        builder: (context, child) => Directionality(textDirection: TextDirection.rtl, child: child!),
        home: VexArenaPage(host: DemoArenaHost()),
      );
}

void main() => runApp(const VexArenaDemoApp());
