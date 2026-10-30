// VEX Health — خواردن دیزاین (food_design.dart)
//
// هەموو بەشی خواردنی ئەپی VEX (وەک وێبەکە) لە یەک فایلدا:
//   • ئەمڕۆ   : ڕینگی کالۆری + ماکرۆکان، «برسیمە!»، ژەمەکان، ئاو، ڕاهێنەر
//   • گەڕان    : گەڕان لە 10 خواردنی نموونە، پۆل، دڵخواز، زیادکردن، خواردنی تایبەت
//   • ڕاهێنەر  : کارتی ڕاهێنەر، ئامۆژگاری، پرسیار (وەڵامی ناوخۆیی)
//   • شیکاری  : 7 ڕۆژ، دابەشبوونی ماکرۆ، کێش
//   • من       : پرۆفایل، پلان، BMI، کێش، بەردەوامی
//   • ویزارد    : who ← basic ← goal ← act ← health ← sum (پلانی تایبەت)
//
// بانگکردن لە هەر شوێنێک:   openFoodDesign();
// یان بەکارهێنانی ڕاستەوخۆ:  const FoodDesignPage()
//
// پێویستی:  pubspec.yaml ← assets/food_design/   (WebP ـەکان)  +  flutter_svg + shared_preferences (هەیە)
// ڕەنگ: خۆکار / ڕووناک / تاریک (V لە core/theme.dart). داتا لە SharedPreferences (کلیل vexfd_v1).
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/theme.dart';
import 'food_db.dart';

part 'food_coach.dart';

/// کردنەوەی بەشی خواردن
Future<void> openFoodDesign() async {
  final nav = navKey.currentState;
  if (nav == null) return;
  await nav.push<void>(MaterialPageRoute<void>(builder: (_) => const FoodDesignPage()));
}

/// بۆ پەیوەستکردن بە AI / کامێرا: ئەگەر دایبنێیت، دوگمەکانی کامێرا و گەلەری ئەمە بانگ دەکەن
class FoodDesignHooks {
  FoodDesignHooks._();
  static void Function(bool camera)? onScan;
}

// ═════════════════════════════ ئایکۆنەکان ═════════════════════════════
/// ئایکۆنی WebP ـی ئەپ (assets/food_design/<name>.webp)
class _Ic extends StatelessWidget {
  const _Ic(this.name, {this.size = 28});
  final String name;
  final double size;
  @override
  Widget build(BuildContext context) => Image.asset(
        'assets/food_design/$name.webp',
        width: size,
        height: size,
        fit: BoxFit.contain,
        errorBuilder: (c, e, s) => SizedBox(width: size, height: size),
      );
}

/// ئایکۆنی SVG ـی گلۆسی (_kSvg)
class _Sv extends StatelessWidget {
  const _Sv(this.name, {this.size = 28});
  final String name;
  final double size;
  @override
  Widget build(BuildContext context) {
    final raw = _kSvg[name];
    if (raw == null) return _Ic(name == 'scale' ? 'weight' : name, size: size);
    return SvgPicture.string(raw.replaceAll('{p}', '${name}_'), width: size, height: size);
  }
}

// ═════════════════════════════ داتا ═════════════════════════════
double _d(dynamic v) => v is num ? v.toDouble() : (double.tryParse('$v') ?? 0);
int _i(dynamic v) => v is num ? v.toInt() : (int.tryParse('$v') ?? 0);
String _f1(num v) => v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);

class _Food {
  const _Food(this.id, this.n, this.serv, this.g, this.cat, this.kcal, this.p, this.c, this.f, this.fib, this.sug, this.salt,
      this.tags, this.ic);
  final String id, n, serv, cat, ic;
  final double g, kcal, p, c, f, fib, sug, salt;
  final List<String> tags; // gluten lact nuts egg · sweet salty hot cold fast nomeat
}

/// 10 خواردنی نموونە (بۆ هەر بەشێک)
const List<_Food> _kFoods = [
  _Food('tanur', 'نانی تەنووری', '1 دانە (~100g)', 100, 'bread', 275, 9, 55, 1.5, 2.5, 2, 1.2, ['gluten', 'hot', 'nomeat'], 'bread'),
  _Food('rice', 'برنجی سپی', '1 کوپ (~160g)', 160, 'bread', 205, 4.3, 45, 0.4, 0.6, 0, 0.1, ['hot', 'nomeat'], 'carbs'),
  _Food('fasolia', 'شلەی فاسۆلیا', '1 کوپ (~250g)', 250, 'kurd', 230, 11, 30, 7, 9, 5, 1.6, ['hot', 'salty', 'nomeat'], 'regional'),
  _Food('dolma', 'دۆڵمە / یاپراخ', '6 دانە (~150g)', 150, 'kurd', 270, 6, 35, 12, 4, 3, 1.4, ['hot', 'salty'], 'regional'),
  _Food('kofta', 'کفتە', '3 دانە (~120g)', 120, 'kurd', 300, 20, 6, 22, 1, 1, 1.8, ['hot', 'salty', 'fast'], 'regional'),
  _Food('kebab', 'کەباب', '2 شیش (~150g)', 150, 'prot', 380, 28, 2, 29, 0, 0, 1.5, ['hot', 'salty'], 'protein'),
  _Food('egg', 'هێلکەی کوڵاو', '2 دانە (~100g)', 100, 'prot', 155, 13, 1, 11, 0, 1, 0.3, ['egg', 'fast', 'nomeat'], 'protein'),
  _Food('mast', 'ماست', '1 کوپ (~245g)', 245, 'dairy', 150, 8, 11, 8, 0, 11, 0.2, ['lact', 'cold', 'fast', 'nomeat'], 'dairy'),
  _Food('apple', 'سێو', '1 دانەی مامناوەند (~180g)', 180, 'fruit', 95, 0.5, 25, 0.3, 4.4, 19, 0, ['sweet', 'cold', 'fast', 'nomeat'], 'fruit'),
  _Food('baklava', 'پاقلاوە', '1 پارچە (~60g)', 60, 'sweet', 230, 3, 26, 13, 1, 16, 0.1, ['sweet', 'gluten', 'nuts', 'nomeat'], 'sweets'),
];

/// پۆلەکان: [کلیل، ناو، ئایکۆن]
const List<List<String>> _kCats = [
  ['bread', 'نان و دانەوێڵە', 'bread'],
  ['kurd', 'خواردنی کوردی', 'regional'],
  ['prot', 'گۆشت و پرۆتین', 'protein'],
  ['dairy', 'شیرەمەنی', 'dairy'],
  ['fruit', 'میوە', 'fruit'],
  ['sweet', 'شیرینی', 'sweets'],
];

/// ژەمەکان: [کلیل، ناو، ئایکۆن، ماوە]
const List<List<String>> _kMeals = [
  ['b', 'نانی بەیانی', 'breakfast', '5 - 10:30'],
  ['l', 'نانی نیوەڕۆ', 'lunch', '12 - 4'],
  ['d', 'نانی ئێوارە', 'dinner', '6:30 - 10'],
  ['s', 'ژەمی سووک', 'snack', 'نێوان ژەمەکان'],
  ['n', 'خواردنی درەنگی شەو', 'dinner', '10 - 5ی بەیانی'],
];

String _mealByHour() {
  final d = DateTime.now();
  final h = d.hour + d.minute / 60;
  if (h >= 5 && h < 10.5) return 'b';
  if (h >= 10.5 && h < 12) return 's';
  if (h >= 12 && h < 16) return 'l';
  if (h >= 16 && h < 18.5) return 's';
  if (h >= 18.5 && h < 22) return 'd';
  return 'n';
}

List<String> _mealOf(String k) => _kMeals.firstWhere((m) => m[0] == k, orElse: () => _kMeals[3]);

Color _mealColor(String k) {
  switch (k) {
    case 'b':
      return V.amber;
    case 'l':
      return V.orange;
    case 'd':
      return V.violet;
    case 's':
      return V.mint;
    default:
      return const Color(0xFF7FA8FF);
  }
}

// ----- ئامانجەکان / نەخۆشی / هەستیاری -----
/// [کلیل، ناو، ڕوونکردنەوە، ئایکۆنی SVG]
const List<List<String>> _kGoals = [
  ['lose', 'کەمکردنی کێش', 'لاواز بوون بە شێوەی تەندروست', 'g_lose'],
  ['keep', 'پاراستنی تەندروستی', 'کێشی ئێستا بپارێزە', 'scale'],
  ['muscle', 'ماسولکە و لەش جوانی', 'ڕاهێنان و ماسولکە دروستکردن', 'g_muscle'],
  ['gain', 'زیادکردنی کێش', 'کێشی تەندروست زیاد بکە', 'g_gain'],
  ['aging', 'تەندروستی بەتەمەنی', 'بەهێزی، ئێسک و دڵی تەندروست', 'g_aging'],
];
List<String> _goalOf(String k) => _kGoals.firstWhere((g) => g[0] == k, orElse: () => _kGoals[1]);

/// [کلیل، ناو، ئایکۆن]
const List<List<String>> _kConds = [
  ['diab', 'شەکرە', 'glucose'],
  ['bp', 'فشاری خوێن', 'bp'],
  ['chol', 'کۆلیسترۆڵ', 'chol'],
  ['heart', 'نەخۆشی دڵ', 'heart'],
  ['kid', 'نەخۆشی گورچیلە', 'kidney'],
  ['gout', 'نیقرس', 'foot'],
  ['gerd', 'ڕیفلاکس / سووتانی ورگ', 'flame'],
  ['preg', 'دووگیانی', 'preg'],
  ['bf', 'شیردان', 'bottle'],
];
const List<List<String>> _kAllg = [
  ['gluten', 'گلوتین', 'wheat'],
  ['lact', 'لاکتۆز', 'milk'],
  ['nuts', 'گوێز و بادەم', 'walnut'],
  ['egg', 'هێلکە', 'egg'],
  ['fish', 'ماسی', 'fish'],
  ['shell', 'میگۆ و دەریایی', 'shrimp'],
  ['sesame', 'کونجی و تەحین', 'sesame'],
  ['soy', 'سۆیا', 'soy'],
];
const List<List<Object>> _kPace = [
  [0.25, 'هێواش', '0.25kg'],
  [0.5, 'ئاسایی', '0.5kg'],
  [0.75, 'خێرا', '0.75kg'],
];
/// [زانیاری چالاکی، ئایکۆن، ناو، ڕوونکردنەوە]
const List<List<Object>> _kActs = [
  [1.2, 'w_rest', 'کەم جووڵە', 'زۆربەی کات دانیشتوویت'],
  [1.375, 't_shoe', 'سووک', 'پیاسە و کاری ماڵ'],
  [1.55, 'w_home', 'مامناوەند', '3-5 ڕۆژ وەرزش'],
  [1.725, 'w_gym', 'زۆر', '6-7 ڕۆژ وەرزش'],
  [1.9, 'g_muscle', 'زۆر زۆر', 'کاری قورس یان وەرزشی ڕۆژانەی بەهێز'],
];

// ----- کەس و پلان -----
class _Prof {
  _Prof({
    this.name = '',
    this.sex = '',
    this.age = 0,
    this.h = 0,
    this.w = 0,
    this.tw = 0,
    this.goal = '',
    this.pace = 0.5,
    this.act = 1.375,
    this.days = 0,
    List<String>? conds,
    List<String>? allg,
    this.note = '',
    this.where = '',
  })  : conds = conds ?? <String>[],
        allg = allg ?? <String>[];
  String name, sex, goal, note, where;
  double age, h, w, tw, pace, act;
  int days;
  List<String> conds, allg;

  _Prof copy() => _Prof(
        name: name, sex: sex, age: age, h: h, w: w, tw: tw, goal: goal, pace: pace, act: act, days: days,
        conds: List<String>.of(conds), allg: List<String>.of(allg), note: note, where: where,
      );

  Map<String, dynamic> toJson() => {
        'name': name, 'sex': sex, 'age': age, 'h': h, 'w': w, 'tw': tw, 'goal': goal, 'pace': pace, 'act': act,
        'days': days, 'conds': conds, 'allg': allg, 'note': note, 'where': where,
      };
  factory _Prof.fromJson(Map<String, dynamic> j) => _Prof(
        name: '${j['name'] ?? ''}', sex: '${j['sex'] ?? ''}', age: _d(j['age']), h: _d(j['h']), w: _d(j['w']), tw: _d(j['tw']),
        goal: '${j['goal'] ?? ''}', pace: _d(j['pace']) == 0 ? 0.5 : _d(j['pace']), act: _d(j['act']) == 0 ? 1.375 : _d(j['act']),
        days: _i(j['days']),
        conds: ((j['conds'] as List?) ?? const []).map((e) => '$e').toList(),
        allg: ((j['allg'] as List?) ?? const []).map((e) => '$e').toList(),
        note: '${j['note'] ?? ''}', where: '${j['where'] ?? ''}',
      );
}

class _Plan {
  _Plan({
    required this.bmr, required this.tdee, required this.kcal, required this.p, required this.c, required this.f,
    required this.fib, required this.sug, required this.salt, required this.water, required this.steps,
    required this.weeks, required this.flags,
  });
  final int bmr, tdee, kcal, p, c, f, fib, sug, salt, water, steps, weeks;
  final List<String> flags;
}

/// هاوکێشەی Mifflin-St Jeor (هەمان planFor ی وێبەکە)
_Plan _planFor(_Prof P) {
  final bmr = 10 * P.w + 6.25 * P.h - 5 * P.age + (P.sex == 'm' ? 5 : -161);
  final tdee = bmr * P.act;
  final c = P.conds;
  final risky = c.any((x) => const ['preg', 'bf', 'kid', 'heart'].contains(x));
  double k = tdee;
  final flags = <String>[];
  if (P.goal == 'lose') {
    double d = (P.pace * 1100).roundToDouble();
    if (risky) {
      d = math.min(d, 300);
      flags.add('بەهۆی دۆخی تەندروستییەوە کەمکردنەوەکە هێواش کراوە؛ پێش دەستپێکردن لەگەڵ پزیشکەکەت قسە بکە.');
    }
    if (P.age >= 65) d = math.min(d, 400);
    k = tdee - d;
  }
  if (P.goal == 'muscle') k = tdee + 250;
  if (P.goal == 'gain') k = tdee + math.min(500, (P.pace * 1100).roundToDouble());
  if (c.contains('preg')) {
    k = math.max(k, tdee + 250);
    flags.add('دووگیانی: کەمکردنەوەی کێش پێشنیار ناکرێت؛ پلانەکە بە پزیشکی ئافرەتان پشتڕاست بکەرەوە.');
  }
  if (c.contains('bf')) k = math.max(k, tdee + 300);
  final floor = P.sex == 'm' ? 1500.0 : 1200.0;
  if (k < floor) {
    k = floor;
    flags.add('با کالۆرییەکەت لە خوار کەمترین سنووری سەلامەت نەبێت.');
  }
  k = (k / 10).round() * 10.0;
  double pk = const {'lose': 1.8, 'keep': 1.4, 'muscle': 2.0, 'gain': 1.6, 'aging': 1.2}[P.goal] ?? 1.4;
  if (c.contains('kid')) {
    pk = 0.8;
    flags.add('نەخۆشی گورچیلە: بڕی پرۆتین دەبێت پزیشک دیاری بکات.');
  }
  final pr = (P.w * pk).round();
  final fat = (k * 0.28 / 9).round();
  int carb = math.max(0, ((k - pr * 4 - fat * 9) / 4).round());
  if (c.contains('diab')) carb = math.min(carb, (k * 0.4 / 4).round());
  final sug = c.contains('diab') ? 25 : (k * 0.1 / 4).round();
  final water = (P.w * 35 / 250).round() * 250 + (P.days >= 3 ? 500 : 0);
  final steps = const {'lose': 10000, 'keep': 8000, 'muscle': 8000, 'gain': 7000, 'aging': 7000}[P.goal] ?? 8000;
  int weeks = 0;
  if (P.goal == 'lose' && P.tw > 0 && P.tw < P.w) weeks = ((P.w - P.tw) / math.max(0.25, (tdee - k) / 1100)).ceil();
  if (P.goal == 'gain' && P.tw > 0 && P.tw > P.w) weeks = ((P.tw - P.w) / math.max(0.1, (k - tdee) / 1100)).ceil();
  if (P.goal == 'muscle' && P.tw > 0 && P.tw > P.w) weeks = ((P.tw - P.w) / 0.25).ceil();
  return _Plan(
    bmr: bmr.round(), tdee: tdee.round(), kcal: k.round(), p: pr, c: carb, f: fat, fib: (k / 1000 * 14).round(), sug: sug,
    salt: (c.contains('bp') || c.contains('heart') || c.contains('kid')) ? 5 : 6, water: water, steps: steps, weeks: weeks, flags: flags,
  );
}

/// ڕێنماییەکانی ڕاهێنەر: [ئایکۆنی SVG، دەق]
List<List<String>> _coachRules(_Prof P) {
  final r = <List<String>>[];
  final c = P.conds;
  final st = fmt(_planFor(P).steps);
  if (P.goal == 'lose') {
    r.add(['t_cola', 'خواردنەوەی شیرین (کۆکا، شەربەت) بە تەواوی ڕابگرە، چونکە زۆرترین کالۆری بێسوود لێرەوە دێت.']);
    r.add(['t_plate', 'نیوەی قاپەکەت سەوزە بێت، چارەکێک پرۆتین، و چارەکێک برنج یان نان.']);
    r.add(['t_fries', 'خواردنی سورەوەکراو بگۆڕە بە برژاو یان کوڵاو.']);
    r.add(['t_shoe', 'ڕۆژانە $st هەنگاو بڕۆ؛ پیاسەی دوای نانخواردن شەکری خوێن کەم دەکاتەوە.']);
  }
  if (P.goal == 'muscle') {
    r.add(['g_muscle', 'لە هەر ژەمێکدا 25-40 گرام پرۆتین بخۆ: هێلکە، مریشک، ماست، نیسک، ماسی.']);
    r.add(['t_banana', '1-2 کاتژمێر پێش ڕاهێنان کارب بخۆ (مۆز، نان، برنج).']);
    r.add(['milk', 'لە ماوەی 2 کاتژمێر دوای ڕاهێنان ژەمێکی پرۆتیندار بخۆ.']);
    r.add(['t_sleep', '7-9 کاتژمێر بخەوە؛ ماسولکە لە کاتی خەودا گەورە دەبێت.']);
  }
  if (P.goal == 'gain') {
    r.add(['walnut', 'ژەمی سووکی پڕ وزە زیاد بکە: گوێز، خورما، ماست، ڕۆنی زەیتوون.']);
    r.add(['t_dish', 'لە جیاتی 3 ژەم، 5 ژەمی بچووکتر بخۆ.']);
  }
  if (P.goal == 'aging') {
    r.add(['t_bone', 'ڕۆژانە شیرەمەنی بخۆ بۆ کالسیۆم، و 10-15 خولەک هەتاوی بەیانی بۆ ڤیتامین D.']);
    r.add(['g_muscle', 'لە هەر ژەمێکدا پرۆتین هەبێت بۆ پاراستنی ماسولکە.']);
    r.add(['t_cola', 'هەستی تینووێتی لە تەمەنی گەورەدا کەم دەبێتەوە؛ هەر 2 کاتژمێر ئاو بخۆرەوە.']);
    r.add(['salt2', 'خوێ کەم بکەرەوە، و ترشی و پەنیری سوێر بە کەمی بخۆ.']);
  }
  if (P.goal == 'keep') {
    r.add(['t_rainbow', 'ڕۆژانە 5 ڕەنگی جیاوازی میوە و سەوزە بخۆ.']);
    r.add(['t_plate', 'نانی جۆ و دانەوێڵەی تەواو لە جیاتی نانی سپی.']);
  }
  if (c.contains('diab')) r.add(['glucose', 'شەکرە: خورما، شیرینی و شەربەت کەم بکەرەوە؛ کارب هەمیشە لەگەڵ پرۆتین یان سەوزە بخۆ.']);
  if (c.contains('bp')) r.add(['bp', 'فشار: خوێ کەمتر لە 5 گرام (یەک کەوچکی چا) لە ڕۆژێکدا؛ مۆز و سەوزە پۆتاسیۆم دەدەن.']);
  if (c.contains('chol')) r.add(['chol', 'کۆلیسترۆڵ: چەوری ئاژەڵی و سورەوەکراو کەم بکەرەوە؛ جۆ، ماسی و گوێز زیاد بکە.']);
  if (c.contains('preg')) r.add(['preg', 'دووگیانی: گۆشت و هێلکەی کاڵ و ماسی کاڵ مەخۆ، و قاوە کەم بکەرەوە.']);
  return r;
}

// ----- تۆمارەکان -----
class _Entry {
  _Entry({
    required this.n,
    required this.kcal,
    this.p = 0,
    this.c = 0,
    this.f = 0,
    this.fib = 0,
    this.sug = 0,
    this.salt = 0,
    this.q = '',
    this.at = '',
    this.fid = '',
    this.v = 'ok',
    this.note = '',
  });
  String n, q, at, fid, v, note;
  double kcal, p, c, f, fib, sug, salt;

  _Entry copy() => _Entry(
        n: n, kcal: kcal, p: p, c: c, f: f, fib: fib, sug: sug, salt: salt, q: q, at: at, fid: fid, v: v, note: note,
      );
  Map<String, dynamic> toJson() => {
        'n': n, 'kcal': kcal, 'p': p, 'c': c, 'f': f, 'fib': fib, 'sug': sug, 'salt': salt, 'q': q, 'at': at, 'fid': fid,
        'v': v, 'note': note,
      };
  factory _Entry.fromJson(Map<String, dynamic> j) => _Entry(
        n: '${j['n'] ?? ''}', kcal: _d(j['kcal']), p: _d(j['p']), c: _d(j['c']), f: _d(j['f']), fib: _d(j['fib']),
        sug: _d(j['sug']), salt: _d(j['salt']), q: '${j['q'] ?? ''}', at: '${j['at'] ?? ''}', fid: '${j['fid'] ?? ''}',
        v: '${j['v'] ?? 'ok'}', note: '${j['note'] ?? ''}',
      );
}

class _Day {
  _Day() : m = {for (final k in const ['b', 'l', 'd', 's', 'n']) k: <_Entry>[]};
  final Map<String, List<_Entry>> m;
  int water = 0; // 250ml
  Map<String, dynamic> toJson() => {'water': water, 'm': m.map((k, v) => MapEntry(k, v.map((e) => e.toJson()).toList()))};
  factory _Day.fromJson(Map<String, dynamic> j) {
    final d = _Day();
    d.water = _i(j['water']);
    final mm = j['m'];
    if (mm is Map) {
      mm.forEach((k, v) {
        if (v is List) d.m['$k'] = v.whereType<Map>().map((e) => _Entry.fromJson(Map<String, dynamic>.from(e))).toList();
      });
    }
    return d;
  }
}

class _Tot {
  double kcal = 0, p = 0, c = 0, f = 0, fib = 0, sug = 0, salt = 0;
  int n = 0;
}

class _Wt {
  _Wt(this.d, this.kg);
  final String d;
  final double kg;
}

class _Cus {
  _Cus(this.n, this.kcal, this.p, this.c, this.f);
  final String n;
  final double kcal, p, c, f;
}

String _key(DateTime d) => '${d.year}-${pad2(d.month)}-${pad2(d.day)}';
DateTime _fromKey(String k) {
  final p = k.split('-');
  if (p.length != 3) return DateTime.now();
  return DateTime(_i(p[0]), _i(p[1]), _i(p[2]));
}

String _dayTitle(String k) {
  final d = _fromKey(k);
  return '⁦${pad2(d.day)}/${pad2(d.month)}/${d.year}⁩';
}

// ----- کۆگا (SharedPreferences) -----
class _FD extends ChangeNotifier {
  _FD._();
  static final _FD I = _FD._();
  static const _kPref = 'vexfd_v1';
  bool loaded = false;
  _Prof? prof;
  final Map<String, _Day> days = {};
  final Set<String> fav = {};
  final List<_Wt> weights = [];
  final List<_Cus> custom = [];

  _Plan? get plan => prof == null ? null : _planFor(prof!);

  Future<void> load() async {
    if (loaded) return;
    try {
      final sp = await SharedPreferences.getInstance();
      final raw = sp.getString(_kPref);
      if (raw != null && raw.isNotEmpty) {
        final j = jsonDecode(raw);
        if (j is Map) {
          if (j['prof'] is Map) prof = _Prof.fromJson(Map<String, dynamic>.from(j['prof'] as Map));
          if (j['days'] is Map) {
            (j['days'] as Map).forEach((k, v) {
              if (v is Map) days['$k'] = _Day.fromJson(Map<String, dynamic>.from(v));
            });
          }
          if (j['fav'] is List) fav.addAll((j['fav'] as List).map((e) => '$e'));
          if (j['weights'] is List) {
            for (final w in (j['weights'] as List)) {
              if (w is Map) weights.add(_Wt('${w['d']}', _d(w['kg'])));
            }
          }
          if (j['custom'] is List) {
            for (final c in (j['custom'] as List)) {
              if (c is Map) custom.add(_Cus('${c['n']}', _d(c['kcal']), _d(c['p']), _d(c['c']), _d(c['f'])));
            }
          }
        }
      }
    } catch (_) {}
    loaded = true;
    notifyListeners();
  }

  Future<void> save() async {
    notifyListeners();
    try {
      final cut = _key(DateTime.now().subtract(const Duration(days: 90)));
      days.removeWhere((k, v) => k.compareTo(cut) < 0);
      final sp = await SharedPreferences.getInstance();
      await sp.setString(
        _kPref,
        jsonEncode({
          'prof': prof?.toJson(),
          'days': days.map((k, v) => MapEntry(k, v.toJson())),
          'fav': fav.toList(),
          'weights': weights.map((w) => {'d': w.d, 'kg': w.kg}).toList(),
          'custom': custom.map((c) => {'n': c.n, 'kcal': c.kcal, 'p': c.p, 'c': c.c, 'f': c.f}).toList(),
        }),
      );
    } catch (_) {}
  }

  Future<void> reset() async {
    prof = null;
    days.clear();
    fav.clear();
    weights.clear();
    custom.clear();
    await save();
  }

  _Day day(String k) => days.putIfAbsent(k, () => _Day());
  bool hasLog(String k) {
    final d = days[k];
    return d != null && d.m.values.any((l) => l.isNotEmpty);
  }

  _Tot totals(String k) {
    final t = _Tot();
    final d = days[k];
    if (d == null) return t;
    for (final l in d.m.values) {
      for (final e in l) {
        t.kcal += e.kcal;
        t.p += e.p;
        t.c += e.c;
        t.f += e.f;
        t.fib += e.fib;
        t.sug += e.sug;
        t.salt += e.salt;
        t.n++;
      }
    }
    return t;
  }

  void add(String k, String meal, _Entry e) {
    day(k).m.putIfAbsent(meal, () => <_Entry>[]).add(e);
    save();
  }

  void setWeight(double kg) {
    final t = _key(DateTime.now());
    weights.removeWhere((w) => w.d == t);
    weights.add(_Wt(t, kg));
    weights.sort((a, b) => a.d.compareTo(b.d));
    if (prof != null) prof!.w = kg;
    save();
  }

  /// ڕۆژی بەردەوامی: [ئێستا، باشترین]
  List<int> streaks() {
    int cur = 0, best = 0, run = 0;
    final keys = days.keys.where(hasLog).toList()..sort();
    DateTime? prev;
    for (final k in keys) {
      final d = _fromKey(k);
      if (prev != null && d.difference(prev).inDays == 1) {
        run++;
      } else {
        run = 1;
      }
      if (run > best) best = run;
      prev = d;
    }
    final today = DateTime.now();
    var c = DateTime(today.year, today.month, today.day);
    if (!hasLog(_key(c))) c = c.subtract(const Duration(days: 1));
    while (hasLog(_key(c))) {
      cur++;
      c = c.subtract(const Duration(days: 1));
    }
    return [cur, best];
  }
}

// ----- حوکمی خواردن بۆ ئەم کەسە -----
class _Why {
  const _Why(this.ic, this.t, this.bad);
  final String ic, t;
  final bool bad;
}

class _Verdict {
  _Verdict(this.v, this.why);
  final String v; // ok | mid | bad
  final List<_Why> why;
}

_Verdict _judge({
  required String name,
  required double kcal,
  required double p,
  required double f,
  required double fib,
  required double sug,
  required double salt,
  required List<String> tags,
  required _Prof? P,
  int? hour,
}) {
  final why = <_Why>[];
  int score = 0;
  final c = P?.conds ?? const <String>[];
  final al = P?.allg ?? const <String>[];
  for (final a in al) {
    if (tags.contains(a)) {
      final nm = _kAllg.firstWhere((x) => x[0] == a, orElse: () => _kAllg[0])[1];
      why.add(_Why(_kAllg.firstWhere((x) => x[0] == a, orElse: () => _kAllg[0])[2], 'هەستیاریت هەیە بۆ $nm؛ ئەم خواردنە دەبێتە هۆی کێشە.', true));
      score -= 4;
    }
  }
  if (c.contains('diab') && sug > 12) {
    why.add(const _Why('glucose', 'شەکری زۆرە بۆ شەکرە؛ بە بڕێکی کەم و لەگەڵ پرۆتین بیخۆ.', true));
    score -= 3;
  } else if (!c.contains('diab') && sug > 25) {
    why.add(const _Why('t_cola', 'شەکری زۆرە.', true));
    score -= 2;
  }
  final saltLimit = c.contains('bp') ? 1.5 : 2.5;
  if (salt > saltLimit || ((c.contains('bp') || c.contains('kid')) && salt > 1.2)) {
    why.add(_Why('salt2', c.contains('bp') ? 'خوێی زۆرە بۆ فشاری خوێن.' : 'خوێی زۆرە.', true));
    score -= 2;
  }
  if (c.contains('chol') && f > 18) {
    why.add(const _Why('chol', 'چەوری زۆرە بۆ کۆلیسترۆڵ.', true));
    score -= 2;
  }
  if (P != null && P.goal == 'lose' && kcal > 650) {
    why.add(const _Why('scale', 'کالۆری زۆرە بۆ ئامانجی کەمکردنەوەی کێش؛ نیوەی بخۆ.', true));
    score -= 1;
  }
  if (p >= 20) {
    why.add(_Why('g_muscle', P != null && P.goal == 'muscle' ? 'پرۆتینی باشە بۆ ماسولکە.' : 'پرۆتینی باشی تێدایە.', false));
    score += 1;
  }
  if (fib >= 5) {
    why.add(const _Why('wheat', 'فایبەری باشە، تێرت دەکات.', false));
    score += 1;
  }
  final h = hour ?? DateTime.now().hour;
  if ((h >= 22 || h < 5) && kcal > 350) {
    why.add(const _Why('t_sleep', 'بەم کاتی شەوە ژەمێکی قورسە و کاریگەری لەسەر خەو و کێش دەکات.', true));
    score -= 2;
  }
  final v = score <= -3 ? 'bad' : (score < 0 ? 'mid' : 'ok');
  return _Verdict(v, why);
}

Color _vCol(String v) => v == 'bad' ? V.coral : (v == 'mid' ? V.amber : V.mint);
IconData _vIco(String v) =>
    v == 'bad' ? Icons.sentiment_dissatisfied_rounded : (v == 'mid' ? Icons.sentiment_neutral_rounded : Icons.sentiment_satisfied_rounded);

const Color _pink = Color(0xFFFF7AB8);
const int _kBurn = 110; // کالۆری سووتاو (نموونە لە Band)
const int _kSteps = 4300; // هەنگاوی ئەمڕۆ (نموونە لە Band)

// ═════════════════════════════ یارمەتیدەرەکانی دیزاین ═════════════════════════════
/// دەقی کوردی (وەرگێڕدراو بەپێی زمانی ئەپ)
Widget _t(String s, {double size = 13, FontWeight w = FontWeight.w700, Color? c, TextAlign? align, double? h, int? lines}) =>
    VText(s, textAlign: align, maxLines: lines, overflow: lines == null ? null : TextOverflow.ellipsis, style: ku(size, w: w, c: c, h: h));

/// ژمارە (Sora، چەپ بۆ ڕاست)
Widget _n(String s, double size, {Color? c, FontWeight w = FontWeight.w800, TextAlign? align}) =>
    Text(s, textDirection: TextDirection.ltr, textAlign: align, style: nu(size, w: w, c: c));

/// ڕەنگی تێکەڵی گلاس بۆ بۆکسەکان
BoxDecoration _glass({double r = 18, Color? tint, double a = 0.08, Color? line}) => BoxDecoration(
      color: tint == null ? V.surf2 : op(tint, a),
      borderRadius: BorderRadius.circular(r),
      border: Border.all(color: line ?? (tint == null ? V.line : op(tint, 0.32))),
    );

LinearGradient get _gK => const LinearGradient(colors: [Color(0xFFFFD36B), Color(0xFFFF5F7E)]);
LinearGradient get _gP => const LinearGradient(colors: [Color(0xFFFFA3A3), Color(0xFFFF4F73)]);
LinearGradient get _gC => const LinearGradient(colors: [Color(0xFFFFE08A), Color(0xFFFF9F2E)]);
LinearGradient get _gF => const LinearGradient(colors: [Color(0xFFC7B5FF), Color(0xFF7B5CFF)]);
LinearGradient get _gW => const LinearGradient(colors: [Color(0xFF9BF3FF), Color(0xFF2FB4F0)]);

// ═════════════════════════════ کێشانەکان ═════════════════════════════
class _RingP extends CustomPainter {
  _RingP(this.frac, this.colors, this.track, this.w);
  final double frac;
  final List<Color> colors;
  final Color track;
  final double w;
  @override
  void paint(Canvas c, Size s) {
    final r = (math.min(s.width, s.height) - w) / 2;
    final ctr = Offset(s.width / 2, s.height / 2);
    final rect = Rect.fromCircle(center: ctr, radius: r);
    c.drawCircle(ctr, r, Paint()..style = PaintingStyle.stroke..strokeWidth = w..color = track);
    final f = frac.clamp(0.0, 1.0);
    if (f <= 0.001) return;
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = w
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        startAngle: 0,
        endAngle: 2 * math.pi * math.max(f, 0.02),
        colors: colors.length > 1 ? colors : [colors.first, colors.first],
        transform: const GradientRotation(-math.pi / 2),
      ).createShader(rect);
    c.drawArc(rect, -math.pi / 2, 2 * math.pi * f, false, p);
  }

  @override
  bool shouldRepaint(covariant _RingP o) => o.frac != frac || o.track != track || o.w != w;
}

/// ڕینگ بە جووڵە
class _Ring extends StatelessWidget {
  const _Ring({required this.frac, required this.colors, required this.size, required this.w, this.child});
  final double frac, size, w;
  final List<Color> colors;
  final Widget? child;
  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: frac.isNaN ? 0 : frac),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (c, v, _) => SizedBox(
        width: size,
        height: size,
        child: CustomPaint(painter: _RingP(v, colors, V.track, w), child: Center(child: child)),
      ),
    );
  }
}

class _BottleP extends CustomPainter {
  _BottleP(this.level);
  final double level; // 0..1
  Path _path() {
    final p = Path()
      ..moveTo(44, 6)
      ..lineTo(76, 6)
      ..lineTo(76, 26)
      ..cubicTo(76, 31, 100, 39, 100, 64)
      ..lineTo(100, 166)
      ..cubicTo(100, 176, 92, 184, 82, 184)
      ..lineTo(38, 184)
      ..cubicTo(28, 184, 20, 176, 20, 166)
      ..lineTo(20, 64)
      ..cubicTo(20, 39, 44, 31, 44, 26)
      ..close();
    return p;
  }

  @override
  void paint(Canvas c, Size s) {
    c.save();
    c.scale(s.width / 120, s.height / 190);
    final p = _path();
    c.drawPath(p, Paint()..color = op(const Color(0xFF6CF0F7), 0.08));
    c.save();
    c.clipPath(p);
    final lvl = 184 - level.clamp(0.0, 1.0) * 150;
    final wave = Path()..moveTo(-10, lvl);
    for (double x = -10; x <= 130; x += 4) {
      wave.lineTo(x, lvl + math.sin(x / 60 * math.pi * 2) * 3.5);
    }
    wave
      ..lineTo(130, 200)
      ..lineTo(-10, 200)
      ..close();
    c.drawPath(
      wave,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF7FF4FB), Color(0xFF0B8FB8)],
        ).createShader(Rect.fromLTRB(0, lvl, 120, 200)),
    );
    c.restore();
    c.drawPath(p, Paint()..style = PaintingStyle.stroke..strokeWidth = 2..color = op(const Color(0xFFA0F5FA), 0.55));
    c.drawRRect(RRect.fromLTRBR(30, 70, 36, 160, const Radius.circular(3)), Paint()..color = op(Colors.white, 0.18));
    c.restore();
  }

  @override
  bool shouldRepaint(covariant _BottleP o) => o.level != level;
}

class _GaugeP extends CustomPainter {
  _GaugeP(this.bmi, this.fg, this.bg);
  final double bmi;
  final Color fg, bg;
  @override
  void paint(Canvas c, Size s) {
    c.save();
    c.scale(s.width / 220, s.height / 130);
    final rect = Rect.fromCircle(center: const Offset(110, 110), radius: 85);
    c.drawArc(
      rect,
      math.pi,
      math.pi,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 16
        ..strokeCap = StrokeCap.round
        ..shader = const LinearGradient(
          colors: [Color(0xFF6AA8FF), Color(0xFF3CF08A), Color(0xFFFFC04D), Color(0xFFFF4F73)],
          stops: [0, 0.3, 0.6, 1],
        ).createShader(Rect.fromLTRB(25, 25, 195, 110)),
    );
    final ang = math.pi * (1 - ((bmi - 15) / 20).clamp(0.0, 1.0));
    final nx = 110 + 70 * math.cos(ang);
    final ny = 110 - 70 * math.sin(ang);
    c.drawLine(const Offset(110, 110), Offset(nx, ny), Paint()..color = fg..strokeWidth = 4..strokeCap = StrokeCap.round);
    c.drawCircle(const Offset(110, 110), 8, Paint()..color = fg);
    c.drawCircle(const Offset(110, 110), 3, Paint()..color = bg);
    c.restore();
  }

  @override
  bool shouldRepaint(covariant _GaugeP o) => o.bmi != bmi || o.fg != fg || o.bg != bg;
}

class _DonutP extends CustomPainter {
  _DonutP(this.vals, this.cols, this.track);
  final List<double> vals;
  final List<Color> cols;
  final Color track;
  @override
  void paint(Canvas c, Size s) {
    final w = 22.0;
    final r = (math.min(s.width, s.height) - w) / 2;
    final rect = Rect.fromCircle(center: Offset(s.width / 2, s.height / 2), radius: r);
    final tot = vals.fold<double>(0, (a, b) => a + b);
    if (tot <= 0) {
      c.drawArc(rect, 0, 2 * math.pi, false, Paint()..style = PaintingStyle.stroke..strokeWidth = w..color = track);
      return;
    }
    double a0 = -math.pi / 2;
    for (int i = 0; i < vals.length; i++) {
      final sw = vals[i] / tot * 2 * math.pi;
      c.drawArc(rect, a0, math.max(0, sw - 0.04), false, Paint()..style = PaintingStyle.stroke..strokeWidth = w..color = cols[i]);
      a0 += sw;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutP o) => o.vals != vals;
}

class _LineP extends CustomPainter {
  _LineP(this.pts, this.col, this.goal);
  final List<double> pts;
  final Color col;
  final double goal;
  @override
  void paint(Canvas c, Size s) {
    if (pts.isEmpty) return;
    final all = [...pts, if (goal > 0) goal];
    double lo = all.reduce(math.min), hi = all.reduce(math.max);
    if (hi - lo < 2) {
      hi += 1;
      lo -= 1;
    }
    final pad = 14.0;
    Offset pt(int i) {
      final x = pts.length == 1 ? s.width / 2 : pad + (s.width - pad * 2) * i / (pts.length - 1);
      final y = pad + (s.height - pad * 2) * (1 - (pts[i] - lo) / (hi - lo));
      return Offset(x, y);
    }

    if (goal > 0) {
      final gy = pad + (s.height - pad * 2) * (1 - (goal - lo) / (hi - lo));
      double x = 0;
      while (x < s.width) {
        c.drawLine(Offset(x, gy), Offset(math.min(x + 6, s.width), gy), Paint()..color = op(V.mint, 0.7)..strokeWidth = 1.4);
        x += 10;
      }
    }
    final path = Path()..moveTo(pt(0).dx, pt(0).dy);
    for (int i = 1; i < pts.length; i++) {
      path.lineTo(pt(i).dx, pt(i).dy);
    }
    c.drawPath(path, Paint()..style = PaintingStyle.stroke..strokeWidth = 3..strokeCap = StrokeCap.round..strokeJoin = StrokeJoin.round..color = col);
    for (int i = 0; i < pts.length; i++) {
      c.drawCircle(pt(i), 4.5, Paint()..color = col);
      c.drawCircle(pt(i), 2, Paint()..color = V.bg);
    }
  }

  @override
  bool shouldRepaint(covariant _LineP o) => o.pts != pts || o.goal != goal || o.col != col;
}

class _DashP extends CustomPainter {
  _DashP(this.col);
  final Color col;
  @override
  void paint(Canvas c, Size s) {
    double x = 0;
    while (x < s.width) {
      c.drawLine(Offset(x, 0), Offset(math.min(x + 5, s.width), 0), Paint()..color = col..strokeWidth = 1.4);
      x += 9;
    }
  }

  @override
  bool shouldRepaint(covariant _DashP o) => o.col != col;
}

// ═════════════════════════════ پارچە هاوبەشەکان ═════════════════════════════
class _PlusBtn extends StatelessWidget {
  const _PlusBtn({required this.color, required this.onTap, this.size = 42});
  final Color color;
  final VoidCallback onTap;
  final double size;
  @override
  Widget build(BuildContext context) => Press(
        onTap: onTap,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [op(color, 0.95), op(mix(color, Colors.black, 0.32), 0.95)]),
            borderRadius: BorderRadius.circular(size * 0.34),
            boxShadow: [BoxShadow(color: op(color, 0.35), blurRadius: 14, offset: const Offset(0, 5))],
          ),
          child: Icon(Icons.add_rounded, color: Colors.white, size: size * 0.55),
        ),
      );
}

class _Chp extends StatelessWidget {
  const _Chp({required this.child, required this.on, required this.onTap, this.color});
  final Widget child;
  final bool on;
  final VoidCallback onTap;
  final Color? color;
  @override
  Widget build(BuildContext context) {
    final col = color ?? V.mint;
    return Press(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: on ? op(col, 0.14) : V.surf2,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: on ? col : V.line, width: on ? 1.4 : 1),
        ),
        child: child,
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({required this.c, this.hint = '', this.isNum = false, this.onChanged, this.align, this.lines = 1});
  final TextEditingController c;
  final String hint;
  final bool isNum;
  final ValueChanged<String>? onChanged;
  final TextAlign? align;
  final int lines;
  @override
  Widget build(BuildContext context) => TextField(
        controller: c,
        onChanged: onChanged,
        maxLines: lines,
        textAlign: align ?? TextAlign.start,
        keyboardType: isNum ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
        style: isNum ? nu(16, w: FontWeight.w700) : ku(15, w: FontWeight.w600),
        cursorColor: V.cy,
        decoration: InputDecoration(
          hintText: vxTr(hint),
          hintStyle: ku(14, c: op(V.mu, 0.8)),
          filled: true,
          fillColor: V.surf2,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: V.line)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: V.line)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: V.cy, width: 1.4)),
        ),
      );
}

class _Lbl extends StatelessWidget {
  const _Lbl(this.s, {this.top = 16});
  final String s;
  final double top;
  @override
  Widget build(BuildContext context) => Padding(padding: EdgeInsets.only(top: top, bottom: 8), child: _t(s, size: 13, c: V.mu));
}

class _Sec extends StatelessWidget {
  const _Sec(this.title, {this.sub});
  final String title;
  final String? sub;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 22, 4, 10),
        child: Row(children: [
          _t(title, size: 20, w: FontWeight.w800),
          const Spacer(),
          if (sub != null) _t(sub!, size: 12, c: V.mu),
        ]),
      );
}

/// ڕینگی ماکرۆ لەگەڵ ئایکۆن
class _MacroTile extends StatelessWidget {
  const _MacroTile({required this.icon, required this.val, required this.goal, required this.unit, required this.label, required this.color, required this.grad});
  final String icon, unit, label;
  final String val, goal;
  final Color color;
  final LinearGradient grad;
  @override
  Widget build(BuildContext context) {
    final v = double.tryParse(val.replaceAll(',', '')) ?? 0;
    final g = double.tryParse(goal.replaceAll(',', '')) ?? 1;
    return Container(
      padding: const EdgeInsets.fromLTRB(4, 12, 4, 10),
      decoration: _glass(r: 20, tint: color, a: 0.09),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        _Ring(frac: g <= 0 ? 0 : v / g, colors: grad.colors, size: 52, w: 5, child: _Ic(icon, size: 30)),
        const SizedBox(height: 8),
        _n(val, 21, c: color),
        const SizedBox(height: 2),
        _n('/ $goal$unit', 12, c: V.mu, w: FontWeight.w700),
        const SizedBox(height: 4),
        _t(label, size: 12.5, w: FontWeight.w800),
      ]),
    );
  }
}

_Day _peek(String k) => _FD.I.days[k] ?? _Day();
String _todayKey() => _key(DateTime.now());

// ═════════════════════════════ پەڕەی سەرەکی ═════════════════════════════
class FoodDesignPage extends StatefulWidget {
  const FoodDesignPage({super.key, this.tab = 'today'});

  /// بەشی سەرەتا: today | search | plan (ڕاهێنەر) | ask | stats | me
  final String tab;
  @override
  State<FoodDesignPage> createState() => _FoodDesignState();
}

class _FoodDesignState extends State<FoodDesignPage> {
  late String tab = widget.tab; // today | search | plan | ask | stats | me
  String cur = _todayKey();
  bool wiz = false;
  _Prof? wizProf;
  int wizStep = 0;

  void _on() {
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _FD.I.addListener(_on);
    _FD.I.load();
  }

  @override
  void dispose() {
    _FD.I.removeListener(_on);
    super.dispose();
  }

  void go(String t) {
    setState(() => tab = t);
  }

  void startWizard(_Prof? edit, {int step = 0}) {
    setState(() {
      wiz = true;
      wizProf = edit?.copy();
      wizStep = step;
    });
  }

  void _done(_Prof p) {
    final fd = _FD.I;
    final isNew = fd.prof == null;
    fd.prof = p;
    fd.setWeight(p.w);
    setState(() => wiz = false);
    if (isNew) toast('🎉 پلانەکەت ئامادەیە!');
  }

  @override
  Widget build(BuildContext context) {
    final fd = _FD.I;
    Widget body;
    if (!fd.loaded) {
      body = Center(child: CircularProgressIndicator(color: V.cy));
    } else if (fd.prof == null || wiz) {
      body = _Wizard(
        key: ValueKey<String>('wiz${wizProf == null}$wizStep'),
        initial: wizProf,
        startStep: wizStep,
        canCancel: fd.prof != null,
        onDone: _done,
        onCancel: () => setState(() => wiz = false),
      );
    } else {
      Widget view;
      switch (tab) {
        case 'search':
          view = _SearchTab(go: go);
          break;
        case 'plan':
        case 'ask':
          view = _CoachTab(key: ValueKey<String>('coach$tab'), ask: tab == 'ask', go: go, onWizard: startWizard);
          break;
        case 'stats':
          view = const _StatsTab();
          break;
        case 'me':
          view = _MeTab(onWizard: startWizard);
          break;
        default:
          view = _TodayTab(cur: cur, onCur: (k) => setState(() => cur = k), go: go);
      }
      body = Column(children: [
        _topBar(),
        Expanded(child: view),
      ]);
    }
    return Directionality(
      textDirection: kDir,
      child: Scaffold(
        backgroundColor: V.bg,
        body: Stack(children: [
          const Positioned.fill(child: Aurora()),
          SafeArea(child: body),
        ]),
      ),
    );
  }

  Widget _topBar() {
    const items = [
      ['today', 'today', 'ئەمڕۆ'],
      ['search', 'search', 'گەڕان'],
      ['plan', 'coach', 'ڕاهێنەر'],
      ['stats', 'analytics', 'شیکاری'],
      ['me', 'me', 'من'],
    ];
    final canPop = Navigator.of(context).canPop();
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 4),
      child: Row(children: [
        if (canPop)
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 8),
            child: Press(
              onTap: () => Navigator.of(context).maybePop(),
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(color: V.surf, shape: BoxShape.circle, border: Border.all(color: V.line)),
                child: Icon(kIsLtr ? Icons.chevron_left_rounded : Icons.chevron_right_rounded, color: V.tx),
              ),
            ),
          ),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(color: V.surf, borderRadius: BorderRadius.circular(26), border: Border.all(color: V.line)),
            child: Row(children: [
              for (final it in items)
                Expanded(
                  child: Press(
                    onTap: () => go(it[0]),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      decoration: BoxDecoration(
                        color: (tab == it[0] || (tab == 'ask' && it[0] == 'plan')) ? op(V.cy, 0.12) : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: (tab == it[0] || (tab == 'ask' && it[0] == 'plan')) ? op(V.cy, 0.55) : Colors.transparent),
                      ),
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        _Ic(it[1], size: 30),
                        const SizedBox(height: 2),
                        _t(it[2], size: 11.5, w: FontWeight.w800, c: (tab == it[0] || (tab == 'ask' && it[0] == 'plan')) ? V.tx : V.mu),
                      ]),
                    ),
                  ),
                ),
            ]),
          ),
        ),
      ]),
    );
  }
}

// ═════════════════════════════ ئەمڕۆ ═════════════════════════════
class _TodayTab extends StatefulWidget {
  const _TodayTab({required this.cur, required this.onCur, required this.go});
  final String cur;
  final ValueChanged<String> onCur;
  final ValueChanged<String> go;
  @override
  State<_TodayTab> createState() => _TodayTabState();
}

class _TodayTabState extends State<_TodayTab> {
  bool openScore = false;

  void _shift(int d) {
    final dt = _fromKey(widget.cur).add(Duration(days: d));
    final k = _key(dt);
    if (k.compareTo(_todayKey()) > 0) return;
    widget.onCur(k);
  }

  @override
  Widget build(BuildContext context) {
    final fd = _FD.I;
    final P = fd.prof!;
    final plan = fd.plan!;
    final cur = widget.cur;
    final isT = cur == _todayKey();
    final t = fd.totals(cur);
    final d = _peek(cur);
    final burn = isT ? _kBurn : 0;
    final budget = plan.kcal + burn;
    final left = budget - t.kcal;
    final lateNow = _mealByHour() == 'n';
    final nowMeal = _mealByHour();
    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 6, 14, 40),
      physics: const BouncingScrollPhysics(),
      children: [
        _dayBar(isT, cur),
        const SizedBox(height: 10),
        _hero(t, plan, burn, budget, left, d),
        if (isT) _hungry(left, nowMeal, cur),
        _Sec('ژەمەکان', sub: '${t.n} خواردن'),
        Stack(children: [
          PositionedDirectional(
            start: 23,
            top: 26,
            bottom: 26,
            child: Container(width: 2, decoration: BoxDecoration(color: op(V.cy, 0.16), borderRadius: BorderRadius.circular(2))),
          ),
          Column(children: [
            for (final m in _kMeals)
              if (m[0] != 'n' || (d.m['n'] ?? const <_Entry>[]).isNotEmpty || (isT && lateNow)) _mealCard(m, d, plan, isT && m[0] == nowMeal, cur),
          ]),
        ]),
        const SizedBox(height: 4),
        _water(d, plan, P, cur),
        _coachCard(P, plan, t, d),
        if (t.n > 0) _score(t, plan, d),
      ],
    );
  }

  Widget _dayBar(bool isT, String cur) {
    Widget arrow(IconData i, VoidCallback? f) => Press(
          onTap: f,
          child: Opacity(
            opacity: f == null ? 0.35 : 1,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: V.surf, borderRadius: BorderRadius.circular(14), border: Border.all(color: V.line)),
              child: Icon(i, color: V.tx, size: 22),
            ),
          ),
        );
    return Row(children: [
      arrow(kIsLtr ? Icons.chevron_left_rounded : Icons.chevron_right_rounded, () => _shift(-1)),
      Expanded(
        child: Column(children: [
          _t(isT ? 'ئەمڕۆ' : _dayTitle(cur), size: 17, w: FontWeight.w800),
          GestureDetector(
            onTap: isT ? null : () => widget.onCur(_todayKey()),
            child: isT
                ? Text(kurdishDate(), style: ku(12, c: V.mu))
                : _t('گەڕانەوە بۆ ئەمڕۆ', size: 12, c: V.cy),
          ),
        ]),
      ),
      arrow(kIsLtr ? Icons.chevron_right_rounded : Icons.chevron_left_rounded, isT ? null : () => _shift(1)),
    ]);
  }

  Widget _statBox(String v, String l, Color line, {Color? fill}) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5),
      decoration: BoxDecoration(
        color: fill ?? const Color(0x14FFFFFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x1FFFFFFF)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Column(children: [
          Container(height: 3, color: line),
          Padding(
            padding: const EdgeInsets.fromLTRB(6, 8, 6, 9),
            child: Column(children: [
              _n(v, 19, c: const Color(0xFFEAFFFF)),
              const SizedBox(height: 1),
              _t(l, size: 12, c: const Color(0xFFB4D4D9)),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _hero(_Tot t, _Plan plan, int burn, int budget, double left, _Day d) {
    final over = left < 0;
    final tx = const Color(0xFFEAFFFF);
    const mu = Color(0xFF8FC3CB);
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF0E4A59), Color(0xFF07303C)]),
        border: Border.all(color: const Color(0x4D6CF0F7)),
        boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 24, offset: Offset(0, 12))],
      ),
      child: Column(children: [
        Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          Expanded(
            child: Column(children: [
              _statBox(fmt(burn), 'سووتاو', const Color(0xFF2FE6F3)),
              _statBox('${t.n}', 'خواردن', const Color(0xFF3CF08A)),
            ]),
          ),
          const SizedBox(width: 8),
          _Ring(
            frac: budget <= 0 ? 0 : t.kcal / budget,
            colors: over ? const [Color(0xFFFF4F73), Color(0xFFFF4F73)] : const [Color(0xFF2FE6F3), Color(0xFF6CF0F7)],
            size: 138,
            w: 13,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              _n(fmt(t.kcal), 31, c: tx),
              _n('/ ${fmt(budget)} kcal', 11.5, c: mu, w: FontWeight.w700),
            ]),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(children: [
              _statBox(fmt(plan.kcal), 'ئامانج', const Color(0xFFFFBE4D)),
              Container(
                margin: const EdgeInsets.symmetric(vertical: 5),
                padding: const EdgeInsets.symmetric(vertical: 9),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: over ? const Color(0x33FF4F73) : const Color(0x263CF08A),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: over ? const Color(0x66FF4F73) : const Color(0x663CF08A)),
                ),
                child: Column(children: [
                  _n(fmt(left.abs()), 18, c: over ? const Color(0xFFFF8AA0) : const Color(0xFF3CF08A)),
                  _t(over ? 'kcal زیاد' : 'ماوە kcal', size: 11.5, c: over ? const Color(0xFFFF8AA0) : const Color(0xFF3CF08A)),
                ]),
              ),
            ]),
          ),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _MacroTile(icon: 'protein2', val: fmt(t.p), goal: fmt(plan.p), unit: 'g', label: 'پرۆتین', color: const Color(0xFFFF5F7E), grad: _gP)),
          const SizedBox(width: 8),
          Expanded(child: _MacroTile(icon: 'carbs', val: fmt(t.c), goal: fmt(plan.c), unit: 'g', label: 'کارب', color: const Color(0xFFFFA52E), grad: _gC)),
          const SizedBox(width: 8),
          Expanded(child: _MacroTile(icon: 'fat', val: fmt(t.f), goal: fmt(plan.f), unit: 'g', label: 'چەوری', color: const Color(0xFF9B7BFF), grad: _gF)),
          const SizedBox(width: 8),
          Expanded(
            child: _MacroTile(
              icon: 'water',
              val: (d.water * 0.25).toStringAsFixed(1),
              goal: (plan.water / 1000).toStringAsFixed(1),
              unit: 'L',
              label: 'ئاو',
              color: const Color(0xFF2FC4F0),
              grad: _gW,
            ),
          ),
        ]),
      ]),
    );
  }

  Widget _hungry(double left, String meal, String cur) {
    final m = _mealOf(meal);
    return Press(
      onTap: () => _openHungry(cur),
      child: Container(
        margin: const EdgeInsets.only(top: 14),
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          gradient: LinearGradient(colors: [op(V.surf, 1), op(const Color(0xFF3A2430), VexTheme.I.isLight ? 0.18 : 0.55)]),
          border: Border.all(color: op(const Color(0xFFFF9F6E), 0.45)),
          boxShadow: [BoxShadow(color: op(const Color(0xFFFF5F7E), 0.16), blurRadius: 24, offset: const Offset(0, 8))],
        ),
        child: Row(children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFFFF9F6E), Color(0xFFFF4F8B)]),
            ),
            child: const Icon(Icons.restaurant_rounded, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _t('برسیمە! ئێستا چی بخۆم؟', size: 16, w: FontWeight.w800),
              const SizedBox(height: 8),
              Wrap(spacing: 6, runSpacing: 6, children: [
                _miniPill(nowHM(), null),
                _miniPill(m[1], null),
                _miniPill('${fmt(left > 0 ? left : 0)} kcal ماوە', V.mint),
              ]),
            ]),
          ),
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(shape: BoxShape.circle, color: V.surf2, border: Border.all(color: V.line)),
            child: Icon(kIsLtr ? Icons.chevron_right_rounded : Icons.chevron_left_rounded, color: V.tx, size: 20),
          ),
        ]),
      ),
    );
  }

  Widget _miniPill(String s, Color? c) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(color: c == null ? V.surf2 : op(c, 0.14), borderRadius: BorderRadius.circular(20), border: Border.all(color: c == null ? V.line : op(c, 0.4))),
        child: _t(s, size: 11.5, w: FontWeight.w800, c: c ?? V.tx),
      );

  Widget _mealCard(List<String> m, _Day d, _Plan plan, bool isNow, String cur) {
    final col = _mealColor(m[0]);
    final L = d.m[m[0]] ?? <_Entry>[];
    final k = L.fold<double>(0, (a, e) => a + e.kcal);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 48,
          height: 48,
          margin: const EdgeInsets.only(top: 12),
          decoration: BoxDecoration(color: op(col, 0.14), borderRadius: BorderRadius.circular(16), border: Border.all(color: op(col, 0.55)), boxShadow: [BoxShadow(color: op(col, 0.3), blurRadius: 12)]),
          child: Center(child: _Ic(m[2], size: 34)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isNow ? op(col, 0.07) : V.surf,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: isNow ? op(col, 0.6) : V.line),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Row(children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    _t(m[1], size: 15.5, w: FontWeight.w800),
                    const SizedBox(height: 4),
                    Wrap(spacing: 6, crossAxisAlignment: WrapCrossAlignment.center, children: [
                      if (isNow)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(color: op(col, 0.16), borderRadius: BorderRadius.circular(12)),
                          child: _t('ئێستا', size: 11, w: FontWeight.w800, c: col),
                        ),
                      _t('${m[3]}${L.isNotEmpty ? ' · ${L.length} خواردن' : ''}', size: 11.5, c: V.mu),
                    ]),
                  ]),
                ),
                Column(children: [_n(fmt(k), 22, c: col), Text('kcal', style: nu(11, c: V.mu, w: FontWeight.w700))]),
                const SizedBox(width: 10),
                _PlusBtn(color: col, onTap: () => _openAdd(m[0], cur, widget.go)),
              ]),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Container(
                  height: 5,
                  color: V.track,
                  alignment: AlignmentDirectional.centerStart,
                  child: FractionallySizedBox(widthFactor: (plan.kcal <= 0 ? 0.0 : (k / plan.kcal)).clamp(0.0, 1.0), child: Container(color: col)),
                ),
              ),
              for (int i = 0; i < L.length; i++) _entryRow(m[0], i, L[i], col, cur),
              if (L.isEmpty && isNow)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Press(
                    onTap: () => _openAdd(m[0], cur, widget.go),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: op(col, 0.5))),
                      child: Center(child: _t('+ خواردن زیاد بکە', size: 13.5, w: FontWeight.w800, c: col)),
                    ),
                  ),
                ),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _entryRow(String meal, int i, _Entry e, Color col, String cur) {
    final vc = _vCol(e.v);
    return Press(
      onTap: () => _openItem(cur, meal, i),
      child: Container(
        margin: const EdgeInsets.only(top: 10),
        padding: const EdgeInsets.fromLTRB(10, 9, 10, 9),
        decoration: BoxDecoration(color: V.surf2, borderRadius: BorderRadius.circular(16), border: Border.all(color: V.line)),
        child: Row(children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: op(vc, 0.7), width: 1.6)),
            child: Icon(_vIco(e.v), color: vc, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _t(e.n, size: 14, w: FontWeight.w800),
              const SizedBox(height: 2),
              Text('P ${_f1(e.p)} · C ${_f1(e.c)} · F ${_f1(e.f)}${e.q.isEmpty ? '' : ' · ${e.q}'}', style: ku(11, c: V.mu), textDirection: TextDirection.ltr),
              if (e.note.isNotEmpty) _t(e.note, size: 11, c: V.cy),
            ]),
          ),
          if (e.at.isNotEmpty) Padding(padding: const EdgeInsetsDirectional.only(end: 8), child: Text(e.at, style: nu(10.5, w: FontWeight.w600, c: V.mu))),
          _n(fmt(e.kcal), 17, c: col),
        ]),
      ),
    );
  }

  Widget _water(_Day d, _Plan plan, _Prof P, String cur) {
    final ml = d.water * 250;
    final wp = plan.water <= 0 ? 0.0 : (ml / plan.water).clamp(0.0, 1.0);
    void change(int by) {
      final day = _FD.I.day(cur);
      day.water = math.max(0, day.water + by);
      _FD.I.save();
    }

    Widget wbtn(String s, VoidCallback f, {bool prime = false}) => Expanded(
          child: Press(
            onTap: f,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                gradient: prime ? const LinearGradient(colors: [Color(0xFF9BF3FF), Color(0xFF2FC4F0)]) : null,
                color: prime ? null : V.surf2,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: prime ? Colors.transparent : V.line),
              ),
              child: Center(child: _n(s, 14, c: prime ? const Color(0xFF05303A) : V.tx)),
            ),
          ),
        );
    return VCard(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [const _Ic('water', size: 24), const SizedBox(width: 6), _t('ئاو', size: 14, w: FontWeight.w800, c: V.mu)]),
            const SizedBox(height: 6),
            Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
              _n(fmt(ml), 34, c: V.c2),
              const SizedBox(width: 4),
              Text('ml', style: nu(13, c: V.mu, w: FontWeight.w700)),
            ]),
            const SizedBox(height: 4),
            Wrap(spacing: 6, crossAxisAlignment: WrapCrossAlignment.center, children: [
              _t('لە', size: 12, c: V.mu),
              _n('${(plan.water / 1000).toStringAsFixed(1)}L', 18, c: V.cy),
              _t('· بەپێی کێشی ${_f1(P.w)}kg', size: 12, c: V.mu),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              wbtn('−', () => change(-1)),
              const SizedBox(width: 6),
              wbtn('+ 250ml', () => change(1), prime: true),
              const SizedBox(width: 6),
              wbtn('+ 500', () => change(2)),
            ]),
            const SizedBox(height: 8),
            _t(ml >= plan.water ? '🎉 ئامانجی ئاوت تەواو کرد!' : 'ماوە ${fmt(plan.water - ml)} ml', size: 12, c: V.mu),
          ]),
        ),
        const SizedBox(width: 12),
        TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: wp),
          duration: const Duration(milliseconds: 900),
          curve: Curves.easeOutCubic,
          builder: (c, v, _) => SizedBox(width: 62, height: 98, child: CustomPaint(painter: _BottleP(v))),
        ),
      ]),
    );
  }

  Widget _coachCard(_Prof P, _Plan plan, _Tot t, _Day d) {
    final hr = DateTime.now().hour;
    final tips = <String>[];
    if (t.p < plan.p * 0.5 && hr >= 13) tips.add('تا ئێستا ${t.p.round()} گرام پرۆتینت خواردووە لە ${plan.p}. لە ژەمی داهاتوودا هێلکە، مریشک یان نیسک زیاد بکە.');
    if (t.sug > plan.sug * 0.8) tips.add('شەکری ئەمڕۆت نزیکی سنوورە (${t.sug.round()}/${plan.sug}g). تا سبەینێ شیرینی مەخۆ.');
    if (_kSteps < plan.steps) tips.add('${fmt(plan.steps - _kSteps)} هەنگاوت ماوە بۆ ئامانجی ئەمڕۆ، نزیکەی ${((plan.steps - _kSteps) / 100).round()} خولەک پیاسە.');
    if (d.water * 250 < plan.water * 0.5 && hr >= 12) tips.add('کەمتر لە نیوەی ئاوت خواردووەتەوە؛ ئێستا پەرداخێک بخۆرەوە.');
    if (tips.isEmpty) tips.add('ئەمڕۆ لەسەر ڕێگای ڕاستیت، بەردەوام بە!');
    final g = _goalOf(P.goal);
    final fd = _FD.I;
    final w0 = fd.weights.isEmpty ? P.w : fd.weights.first.kg;
    final wl = fd.weights.isEmpty ? P.w : fd.weights.last.kg;
    final hasT = P.tw > 0 && (P.goal == 'lose' || P.goal == 'gain');
    final prog = hasT && (w0 - P.tw).abs() > 0.01 ? ((w0 - wl).abs() / (w0 - P.tw).abs()).clamp(0.03, 1.0) : 0.0;
    return VCard(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(color: op(V.mint, 0.14), borderRadius: BorderRadius.circular(16)),
            child: const Center(child: _Ic('coach', size: 34)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _t('ڕاهێنەرەکەت', size: 15, w: FontWeight.w800),
              const SizedBox(height: 2),
              Row(children: [
                _Sv(g[3], size: 18),
                const SizedBox(width: 5),
                Flexible(child: _t(g[1] + (hasT ? ' · ${_f1(wl)} → ${_f1(P.tw)}kg' : ''), size: 12, c: V.mu, lines: 1)),
              ]),
            ]),
          ),
          Press(
            onTap: () => widget.go('plan'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(color: op(V.mint, 0.14), borderRadius: BorderRadius.circular(14), border: Border.all(color: op(V.mint, 0.4))),
              child: _t('ڕاهێنەر', size: 12.5, w: FontWeight.w800, c: V.mint),
            ),
          ),
        ]),
        const SizedBox(height: 10),
        _t(tips[0], size: 13.5, h: 1.75, w: FontWeight.w600),
        if (tips.length > 1) ...[const SizedBox(height: 6), _t(tips[1], size: 12.5, h: 1.7, w: FontWeight.w500, c: V.mu)],
        if (hasT) ...[
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Container(
              height: 6,
              color: V.track,
              alignment: AlignmentDirectional.centerStart,
              child: FractionallySizedBox(widthFactor: prog, child: Container(color: V.mint)),
            ),
          ),
          const SizedBox(height: 4),
          _t('${(w0 - wl).abs().toStringAsFixed(1)}kg لە ${(w0 - P.tw).abs().toStringAsFixed(1)}kg', size: 11.5, c: V.mu),
        ],
        const SizedBox(height: 12),
        Press(
          onTap: () => widget.go('ask'),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(color: V.surf2, borderRadius: BorderRadius.circular(15), border: Border.all(color: V.line)),
            child: Center(child: _t('پرسیار لە ڕاهێنەرەکەم بکە', size: 13.5, w: FontWeight.w800)),
          ),
        ),
      ]),
    );
  }

  Widget _score(_Tot t, _Plan plan, _Day d) {
    double sc = 40;
    if (t.kcal >= plan.kcal * 0.8 && t.kcal <= plan.kcal * 1.1) sc += 20;
    if (t.p >= plan.p * 0.8) sc += 15;
    if (t.fib >= plan.fib * 0.7) sc += 10;
    if (t.sug <= plan.sug) sc += 8;
    if (d.water * 250 >= plan.water * 0.8) sc += 7;
    sc = sc.clamp(0, 100);
    Widget bar(String l, double v, double goal, Color c, {bool limit = false}) => Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Column(children: [
            Row(children: [
              _t(l, size: 12.5, w: FontWeight.w800),
              const Spacer(),
              _n('${_f1(v)} / ${_f1(goal)}g', 12, c: V.mu, w: FontWeight.w700),
            ]),
            const SizedBox(height: 5),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Container(
                height: 6,
                color: V.track,
                alignment: AlignmentDirectional.centerStart,
                child: FractionallySizedBox(widthFactor: (goal <= 0 ? 0.0 : v / goal).clamp(0.0, 1.0), child: Container(color: limit && v > goal ? V.coral : c)),
              ),
            ),
          ]),
        );
    return VCard(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(14),
      child: Column(children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => setState(() => openScore = !openScore),
          child: Row(children: [
            const _Ic('analytics', size: 28),
            const SizedBox(width: 8),
            Expanded(child: _t('نمرەی ڕۆژ و ڤیتامین و کانزا', size: 14, w: FontWeight.w800)),
            Icon(openScore ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded, color: V.mu),
          ]),
        ),
        if (openScore) ...[
          const SizedBox(height: 14),
          Row(children: [
            _Ring(frac: sc / 100, colors: const [Color(0xFF3CF08A), Color(0xFF2FE6F3)], size: 76, w: 8, child: _n('${sc.round()}', 22)),
            const SizedBox(width: 14),
            Expanded(child: _t(sc >= 80 ? 'ئەمڕۆ زۆر باشە، بەردەوام بە!' : (sc >= 60 ? 'باشە؛ کەمێک پرۆتین و فایبەر زیاد بکە.' : 'ڕۆژەکە هێشتا تەواو نەبووە یان ژەمەکان کەمن.'), size: 13, h: 1.7)),
          ]),
          bar('پرۆتین', t.p, plan.p.toDouble(), V.coral),
          bar('فایبەر', t.fib, plan.fib.toDouble(), V.mint),
          bar('شەکر', t.sug, plan.sug.toDouble(), _pink, limit: true),
        ],
      ]),
    );
  }
}

// ═════════════════════════════ یارمەتیدەرەکانی خواردن ═════════════════════════════
List<_Food> _allFoods() {
  final L = <_Food>[..._kFoods];
  for (final c in _FD.I.custom) {
    L.add(_Food('c:${c.n}', c.n, '1 پشک', 100, 'cus', c.kcal, c.p, c.c, c.f, 0, 0, 0, const <String>[], 'custom'));
  }
  return L;
}

_Verdict _judgeFood(_Food f, double x, {int? hour}) => _judge(
      name: f.n,
      kcal: f.kcal * x,
      p: f.p * x,
      f: f.f * x,
      fib: f.fib * x,
      sug: f.sug * x,
      salt: f.salt * x,
      tags: f.tags,
      P: _FD.I.prof,
      hour: hour,
    );

String _vTitle(String v) => v == 'bad' ? 'باش نییە بۆ تۆ' : (v == 'mid' ? 'بە کەمی بیخۆ' : 'باشە بۆ تۆ');

Color _catColor(String c) {
  switch (c) {
    case 'bread':
      return V.amber;
    case 'kurd':
      return V.orange;
    case 'prot':
      return V.coral;
    case 'dairy':
      return const Color(0xFF7FA8FF);
    case 'fruit':
      return V.mint;
    case 'sweet':
      return _pink;
    default:
      return V.cy;
  }
}

class _VBadge extends StatelessWidget {
  const _VBadge(this.v, {this.size = 30});
  final String v;
  final double size;
  @override
  Widget build(BuildContext context) {
    final vc = _vCol(v);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: op(vc, 0.12), border: Border.all(color: op(vc, 0.75), width: 1.6)),
      child: Icon(_vIco(v), color: vc, size: size * 0.66),
    );
  }
}

class _WhyRow extends StatelessWidget {
  const _WhyRow(this.w);
  final _Why w;
  @override
  Widget build(BuildContext context) {
    final col = w.bad ? V.coral : V.mint;
    return Padding(
      padding: const EdgeInsets.only(top: 9),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(color: op(col, 0.12), borderRadius: BorderRadius.circular(12)),
          child: Center(child: _Sv(w.ic, size: 24)),
        ),
        const SizedBox(width: 10),
        Expanded(child: Padding(padding: const EdgeInsets.only(top: 4), child: _t(w.t, size: 13, h: 1.65, w: FontWeight.w600))),
      ]),
    );
  }
}

Widget _verdictBox(_Verdict vd) {
  final vc = _vCol(vd.v);
  return Container(
    margin: const EdgeInsets.only(top: 14),
    padding: const EdgeInsets.all(14),
    decoration: _glass(r: 20, tint: vc, a: 0.09),
    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Row(children: [
        _VBadge(vd.v, size: 34),
        const SizedBox(width: 10),
        _t(_vTitle(vd.v), size: 15.5, w: FontWeight.w800, c: vc),
      ]),
      for (final w in vd.why) _WhyRow(w),
      if (vd.why.isEmpty) Padding(padding: const EdgeInsets.only(top: 8), child: _t('هیچ کێشەیەکی تایبەتی بۆ تۆ نییە.', size: 12.5, c: V.mu)),
    ]),
  );
}

Widget _miniMacro(String l, double v, Color c) => Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: _glass(r: 16, tint: c, a: 0.1),
        child: Column(children: [
          _n(_f1(double.parse(v.toStringAsFixed(1))), 18, c: c),
          const SizedBox(height: 2),
          _t('$l g', size: 11.5, c: V.mu),
        ]),
      ),
    );

Widget _sheetTitle(String s, {String? sub, String? icon}) => Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(children: [
        if (icon != null) ...[_Ic(icon, size: 34), const SizedBox(width: 10)],
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _t(s, size: 18, w: FontWeight.w800),
            if (sub != null) Padding(padding: const EdgeInsets.only(top: 2), child: _t(sub, size: 12, c: V.mu)),
          ]),
        ),
      ]),
    );

Widget _bigBtn(String s, VoidCallback f, {Color? color, bool ghost = false}) => Press(
      onTap: f,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          gradient: ghost ? null : V.prime,
          color: ghost ? V.surf2 : null,
          borderRadius: BorderRadius.circular(18),
          border: ghost ? Border.all(color: color ?? V.line) : null,
          boxShadow: ghost ? null : [BoxShadow(color: op(V.mint, 0.3), blurRadius: 18, offset: const Offset(0, 6))],
        ),
        child: Center(child: _t(s, size: 15, w: FontWeight.w800, c: ghost ? (color ?? V.tx) : const Color(0xFF05303A))),
      ),
    );

/// ڕیزی خواردن (گەڕان / زیادکردن)
class _FoodRow extends StatelessWidget {
  const _FoodRow({required this.f, required this.onTap, required this.onAdd, this.color});
  final _Food f;
  final VoidCallback onTap, onAdd;
  final Color? color;
  @override
  Widget build(BuildContext context) {
    final vd = _judgeFood(f, 1);
    final col = color ?? _catColor(f.cat);
    final fav = _FD.I.fav.contains(f.id);
    return Press(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
        decoration: BoxDecoration(color: V.surf, borderRadius: BorderRadius.circular(22), border: Border.all(color: V.line)),
        child: Row(children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(color: op(col, 0.13), borderRadius: BorderRadius.circular(18), border: Border.all(color: op(col, 0.4))),
            child: Center(child: _Ic(f.ic, size: 38)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Flexible(child: _t(f.n, size: 14.5, w: FontWeight.w800, lines: 1)),
                if (fav) Padding(padding: const EdgeInsetsDirectional.only(start: 5), child: Icon(Icons.favorite_rounded, size: 14, color: _pink)),
              ]),
              const SizedBox(height: 2),
              _t(f.serv, size: 11.5, c: V.mu, lines: 1),
              const SizedBox(height: 4),
              Text('P ${_f1(f.p)} · C ${_f1(f.c)} · F ${_f1(f.f)}', style: nu(10.5, w: FontWeight.w600, c: V.mu), textDirection: TextDirection.ltr),
            ]),
          ),
          Column(mainAxisSize: MainAxisSize.min, children: [
            _n(fmt(f.kcal), 18, c: col),
            Text('kcal', style: nu(10, c: V.mu, w: FontWeight.w700)),
          ]),
          const SizedBox(width: 8),
          _VBadge(vd.v, size: 26),
          const SizedBox(width: 8),
          _PlusBtn(color: col, onTap: onAdd, size: 36),
        ]),
      ),
    );
  }
}

// ═════════════════════════════ شیتەکان ═════════════════════════════
Future<bool?> _openDetail(_Food f, String meal, String cur) =>
    showVSheet<bool>(builder: (c) => _DetailSheet(f: f, meal: meal, cur: cur));

Future<void> _openAdd(String meal, String cur, ValueChanged<String> go) =>
    showVSheet<void>(builder: (c) => _AddSheet(meal: meal, cur: cur, go: go));

Future<void> _openHungry(String cur) => showVSheet<void>(builder: (c) => _HungrySheet(cur: cur));

Future<void> _openItem(String cur, String meal, int i) => showVSheet<void>(builder: (c) => _ItemSheet(cur: cur, meal: meal, i: i));

Future<void> _openCustom({String? meal, String? cur}) => showVSheet<void>(builder: (c) => _CustomSheet(meal: meal, cur: cur));

class _DetailSheet extends StatefulWidget {
  const _DetailSheet({required this.f, required this.meal, required this.cur});
  final _Food f;
  final String meal, cur;
  @override
  State<_DetailSheet> createState() => _DetailSheetState();
}

class _DetailSheetState extends State<_DetailSheet> {
  double x = 1;
  late String meal = widget.meal;

  @override
  Widget build(BuildContext context) {
    final f = widget.f;
    final vd = _judgeFood(f, x);
    final col = _catColor(f.cat);
    final fav = _FD.I.fav.contains(f.id);
    Widget step(IconData i, VoidCallback fn) => Press(
          onTap: fn,
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: V.surf2, borderRadius: BorderRadius.circular(15), border: Border.all(color: V.line)),
            child: Icon(i, color: V.tx),
          ),
        );
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Row(children: [
        Container(
          width: 66,
          height: 66,
          decoration: BoxDecoration(color: op(col, 0.14), borderRadius: BorderRadius.circular(22), border: Border.all(color: op(col, 0.45))),
          child: Center(child: _Ic(f.ic, size: 48)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _t(f.n, size: 19, w: FontWeight.w800),
            const SizedBox(height: 3),
            _t(f.serv, size: 12.5, c: V.mu),
          ]),
        ),
        Press(
          onTap: () {
            if (fav) {
              _FD.I.fav.remove(f.id);
            } else {
              _FD.I.fav.add(f.id);
            }
            _FD.I.save();
            setState(() {});
          },
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(shape: BoxShape.circle, color: fav ? op(_pink, 0.16) : V.surf2, border: Border.all(color: fav ? _pink : V.line)),
            child: Icon(fav ? Icons.favorite_rounded : Icons.favorite_border_rounded, color: fav ? _pink : V.mu),
          ),
        ),
      ]),
      const SizedBox(height: 16),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        step(Icons.remove_rounded, () => setState(() => x = math.max(0.5, x - 0.5))),
        const SizedBox(width: 18),
        Column(children: [
          _n('${_f1(x)}×', 26),
          _t('${(f.g * x).round()} g', size: 12, c: V.mu),
        ]),
        const SizedBox(width: 18),
        step(Icons.add_rounded, () => setState(() => x = math.min(10, x + 0.5))),
      ]),
      const SizedBox(height: 16),
      Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: _glass(r: 22, tint: col, a: 0.09),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
          _n(fmt(f.kcal * x), 36, c: col),
          const SizedBox(width: 6),
          Text('kcal', style: nu(14, c: V.mu, w: FontWeight.w700)),
        ]),
      ),
      const SizedBox(height: 10),
      Row(children: [
        _miniMacro('پرۆتین', f.p * x, const Color(0xFFFF5F7E)),
        const SizedBox(width: 8),
        _miniMacro('کارب', f.c * x, const Color(0xFFFFA52E)),
        const SizedBox(width: 8),
        _miniMacro('چەوری', f.f * x, const Color(0xFF9B7BFF)),
      ]),
      const SizedBox(height: 8),
      Row(children: [
        _miniMacro('فایبەر', f.fib * x, V.mint),
        const SizedBox(width: 8),
        _miniMacro('شەکر', f.sug * x, _pink),
        const SizedBox(width: 8),
        _miniMacro('خوێ', f.salt * x, V.cy),
      ]),
      _verdictBox(vd),
      _Lbl('بۆ کام ژەم؟'),
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(children: [
          for (final m in _kMeals)
            if (m[0] != 'n')
              Padding(
                padding: const EdgeInsetsDirectional.only(end: 8),
                child: _Chp(
                  on: meal == m[0],
                  color: _mealColor(m[0]),
                  onTap: () => setState(() => meal = m[0]),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [_Ic(m[2], size: 22), const SizedBox(width: 6), _t(m[1], size: 12.5, w: FontWeight.w800)]),
                ),
              ),
        ]),
      ),
      const SizedBox(height: 18),
      _bigBtn('+ زیادکردن بۆ ${_mealOf(meal)[1]}', () {
        _FD.I.add(
          widget.cur,
          meal,
          _Entry(
            n: f.n,
            kcal: f.kcal * x,
            p: f.p * x,
            c: f.c * x,
            f: f.f * x,
            fib: f.fib * x,
            sug: f.sug * x,
            salt: f.salt * x,
            q: '${_f1(x)}× ${f.serv}',
            at: widget.cur == _todayKey() ? nowHM() : '',
            fid: f.id,
            v: vd.v,
          ),
        );
        toast('زیاد کرا ✓');
        Navigator.of(context).pop(true);
      }),
    ]);
  }
}

class _AddSheet extends StatefulWidget {
  const _AddSheet({required this.meal, required this.cur, required this.go});
  final String meal, cur;
  final ValueChanged<String> go;
  @override
  State<_AddSheet> createState() => _AddSheetState();
}

class _AddSheetState extends State<_AddSheet> {
  final TextEditingController q = TextEditingController();

  @override
  void dispose() {
    q.dispose();
    super.dispose();
  }

  Widget _tile(String ic, String s, VoidCallback f, Color col) => Expanded(
        child: Press(
          onTap: f,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: _glass(r: 18, tint: col, a: 0.09),
            child: Column(children: [_Ic(ic, size: 34), const SizedBox(height: 4), _t(s, size: 11.5, w: FontWeight.w800)]),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final m = _mealOf(widget.meal);
    final txt = q.text.trim();
    var list = _allFoods().where((f) => txt.isEmpty || f.n.contains(txt)).toList();
    list.sort((a, b) {
      final fa = _FD.I.fav.contains(a.id) ? 0 : 1;
      final fb = _FD.I.fav.contains(b.id) ? 0 : 1;
      return fa.compareTo(fb);
    });
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _sheetTitle('زیادکردن بۆ ${m[1]}', sub: m[3], icon: m[2]),
      Row(children: [
        _tile('scan', 'کامێرا', () {
          Navigator.of(context).pop();
          final h = FoodDesignHooks.onScan;
          if (h != null) {
            h(true);
          } else {
            toast('کامێرا بەم زووانە');
          }
        }, V.cy),
        const SizedBox(width: 8),
        _tile('aitext', 'گەلەری', () {
          Navigator.of(context).pop();
          final h = FoodDesignHooks.onScan;
          if (h != null) {
            h(false);
          } else {
            toast('گەلەری بەم زووانە');
          }
        }, V.violet),
        const SizedBox(width: 8),
        _tile('custom', 'تایبەت', () {
          Navigator.of(context).pop();
          _openCustom(meal: widget.meal, cur: widget.cur);
        }, V.orange),
      ]),
      const SizedBox(height: 12),
      _Field(c: q, hint: 'گەڕان بۆ خواردن...', onChanged: (_) => setState(() {})),
      const SizedBox(height: 12),
      if (list.isEmpty) Padding(padding: const EdgeInsets.all(20), child: Center(child: _t('هیچ خواردنێک نەدۆزرایەوە', c: V.mu))),
      for (final f in list)
        _FoodRow(
          f: f,
          onTap: () async {
            final r = await _openDetail(f, widget.meal, widget.cur);
            if (r == true && mounted) Navigator.of(context).pop();
          },
          onAdd: () async {
            final r = await _openDetail(f, widget.meal, widget.cur);
            if (r == true && mounted) Navigator.of(context).pop();
          },
        ),
    ]);
  }
}

class _HungrySheet extends StatelessWidget {
  const _HungrySheet({required this.cur});
  final String cur;
  @override
  Widget build(BuildContext context) {
    final fd = _FD.I;
    final plan = fd.plan!;
    final t = fd.totals(cur);
    final left = plan.kcal + (cur == _todayKey() ? _kBurn : 0) - t.kcal;
    final meal = _mealByHour();
    final m = _mealOf(meal);
    final rows = <List<Object>>[];
    for (final f in _allFoods()) {
      final vd = _judgeFood(f, 1);
      rows.add([f, vd]);
    }
    int rank(String v) => v == 'ok' ? 0 : (v == 'mid' ? 1 : 2);
    rows.sort((a, b) {
      final va = (a[1] as _Verdict).v, vb = (b[1] as _Verdict).v;
      final r = rank(va).compareTo(rank(vb));
      if (r != 0) return r;
      return (b[0] as _Food).p.compareTo((a[0] as _Food).p);
    });
    final good = rows.where((r) => (r[1] as _Verdict).v != 'bad' && (r[0] as _Food).kcal <= math.max(left, 120)).take(5).toList();
    final avoid = rows.where((r) => (r[1] as _Verdict).v == 'bad').take(3).toList();
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _sheetTitle('ئێستا چی بخۆم؟', sub: '${m[1]} · ${nowHM()}', icon: m[2]),
      Container(
        padding: const EdgeInsets.all(14),
        decoration: _glass(r: 20, tint: left >= 0 ? V.mint : V.coral, a: 0.09),
        child: Row(children: [
          Expanded(child: _t(left >= 0 ? 'ئەمڕۆ ماوە:' : 'لە ئامانج تێپەڕیوی بە:', size: 13.5, w: FontWeight.w800)),
          _n(fmt(left.abs()), 26, c: left >= 0 ? V.mint : V.coral),
          const SizedBox(width: 4),
          Text('kcal', style: nu(12, c: V.mu, w: FontWeight.w700)),
        ]),
      ),
      _Lbl('باشترین بۆ ئێستا'),
      if (good.isEmpty) _t('بۆ ئەم کاتە شتێکی گونجاو نییە؛ ئاو بخۆرەوە.', c: V.mu, size: 13),
      for (final r in good)
        _FoodRow(
          f: r[0] as _Food,
          onTap: () async {
            final ok = await _openDetail(r[0] as _Food, meal == 'n' ? 's' : meal, cur);
            if (ok == true && context.mounted) Navigator.of(context).pop();
          },
          onAdd: () async {
            final ok = await _openDetail(r[0] as _Food, meal == 'n' ? 's' : meal, cur);
            if (ok == true && context.mounted) Navigator.of(context).pop();
          },
        ),
      if (avoid.isNotEmpty) ...[
        _Lbl('خۆت لێ بپارێزە'),
        for (final r in avoid)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: _glass(r: 18, tint: V.coral, a: 0.07),
            child: Row(children: [
              _Ic((r[0] as _Food).ic, size: 32),
              const SizedBox(width: 10),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _t((r[0] as _Food).n, size: 13.5, w: FontWeight.w800),
                  if ((r[1] as _Verdict).why.isNotEmpty) _t((r[1] as _Verdict).why.first.t, size: 11.5, c: V.mu, h: 1.5),
                ]),
              ),
            ]),
          ),
      ],
    ]);
  }
}

class _ItemSheet extends StatelessWidget {
  const _ItemSheet({required this.cur, required this.meal, required this.i});
  final String cur, meal;
  final int i;
  @override
  Widget build(BuildContext context) {
    final d = _peek(cur);
    final L = d.m[meal] ?? <_Entry>[];
    if (i < 0 || i >= L.length) return const SizedBox(height: 40);
    final e = L[i];
    final vc = _vCol(e.v);
    final m = _mealOf(meal);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _sheetTitle(e.n, sub: '${m[1]}${e.at.isEmpty ? '' : ' · ${e.at}'}', icon: m[2]),
      Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: _glass(r: 22, tint: vc, a: 0.09),
        child: Column(children: [
          Row(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
            _n(fmt(e.kcal), 34, c: vc),
            const SizedBox(width: 6),
            Text('kcal', style: nu(13, c: V.mu, w: FontWeight.w700)),
          ]),
          if (e.q.isNotEmpty) _t(e.q, size: 12, c: V.mu),
        ]),
      ),
      const SizedBox(height: 10),
      Row(children: [
        _miniMacro('پرۆتین', e.p, const Color(0xFFFF5F7E)),
        const SizedBox(width: 8),
        _miniMacro('کارب', e.c, const Color(0xFFFFA52E)),
        const SizedBox(width: 8),
        _miniMacro('چەوری', e.f, const Color(0xFF9B7BFF)),
      ]),
      const SizedBox(height: 8),
      Row(children: [
        _miniMacro('فایبەر', e.fib, V.mint),
        const SizedBox(width: 8),
        _miniMacro('شەکر', e.sug, _pink),
        const SizedBox(width: 8),
        _miniMacro('خوێ', e.salt, V.cy),
      ]),
      Container(
        margin: const EdgeInsets.only(top: 14),
        padding: const EdgeInsets.all(12),
        decoration: _glass(r: 18, tint: vc, a: 0.09),
        child: Row(children: [_VBadge(e.v, size: 30), const SizedBox(width: 10), _t(_vTitle(e.v), size: 14.5, w: FontWeight.w800, c: vc)]),
      ),
      const SizedBox(height: 18),
      Row(children: [
        Expanded(
          child: _bigBtn('دووبارەکردنەوە', () {
            _FD.I.add(cur, meal, e.copy()..at = cur == _todayKey() ? nowHM() : '');
            toast('دووبارە کرایەوە ✓');
            Navigator.of(context).pop();
          }, ghost: true),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _bigBtn('سڕینەوە', () {
            L.removeAt(i);
            _FD.I.save();
            Navigator.of(context).pop();
          }, ghost: true, color: V.coral),
        ),
      ]),
    ]);
  }
}

class _CustomSheet extends StatefulWidget {
  const _CustomSheet({this.meal, this.cur});
  final String? meal, cur;
  @override
  State<_CustomSheet> createState() => _CustomSheetState();
}

class _CustomSheetState extends State<_CustomSheet> {
  final n = TextEditingController();
  final k = TextEditingController();
  final p = TextEditingController();
  final c = TextEditingController();
  final f = TextEditingController();

  @override
  void dispose() {
    n.dispose();
    k.dispose();
    p.dispose();
    c.dispose();
    f.dispose();
    super.dispose();
  }

  double _v(TextEditingController x) => double.tryParse(x.text.trim().replaceAll(',', '.')) ?? 0;

  @override
  Widget build(BuildContext context) {
    Widget row(String l, TextEditingController x, {bool isN = true, String hint = ''}) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          _Lbl(l, top: 12),
          _Field(c: x, isNum: isN, hint: hint),
        ]);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _sheetTitle('خواردنی تایبەت', sub: 'بۆ خواردنێک کە لە لیستەکەدا نییە', icon: 'custom'),
      row('ناوی خواردن', n, isN: false, hint: 'بۆ نموونە: ساندویچی ماڵەوە'),
      row('کالۆری (kcal)', k, hint: '0'),
      Row(children: [
        Expanded(child: row('پرۆتین g', p, hint: '0')),
        const SizedBox(width: 8),
        Expanded(child: row('کارب g', c, hint: '0')),
        const SizedBox(width: 8),
        Expanded(child: row('چەوری g', f, hint: '0')),
      ]),
      const SizedBox(height: 18),
      _bigBtn(widget.meal != null ? 'پاشەکەوت و زیادکردن' : 'پاشەکەوت', () {
        final name = n.text.trim();
        if (name.isEmpty || _v(k) <= 0) {
          toast('ناو و کالۆری پێویستە');
          return;
        }
        final fd = _FD.I;
        fd.custom.removeWhere((x) => x.n == name);
        fd.custom.add(_Cus(name, _v(k), _v(p), _v(c), _v(f)));
        if (widget.meal != null && widget.cur != null) {
          final food = _Food('c:$name', name, '1 پشک', 100, 'cus', _v(k), _v(p), _v(c), _v(f), 0, 0, 0, const <String>[], 'custom');
          final vd = _judgeFood(food, 1);
          fd.add(widget.cur!, widget.meal!, _Entry(n: name, kcal: _v(k), p: _v(p), c: _v(c), f: _v(f), q: '1 پشک', at: widget.cur == _todayKey() ? nowHM() : '', fid: food.id, v: vd.v));
        } else {
          fd.save();
        }
        toast('پاشەکەوت کرا ✓');
        Navigator.of(context).pop();
      }),
    ]);
  }
}

// ═════════════════════════════ گەڕان ═════════════════════════════
class _SearchTab extends StatefulWidget {
  const _SearchTab({required this.go});
  final ValueChanged<String> go;
  @override
  State<_SearchTab> createState() => _SearchTabState();
}

class _SearchTabState extends State<_SearchTab> {
  final TextEditingController q = TextEditingController();
  String cat = 'all';

  @override
  void dispose() {
    q.dispose();
    super.dispose();
  }

  String get _meal {
    final m = _mealByHour();
    return m == 'n' ? 's' : m;
  }

  void _open(_Food f) {
    _openDetail(f, _meal, _todayKey());
  }

  @override
  Widget build(BuildContext context) {
    final fd = _FD.I;
    final txt = q.text.trim();
    final all = _allFoods();
    final list = all.where((f) {
      if (txt.isNotEmpty && !f.n.contains(txt)) return false;
      if (cat == 'fav') return fd.fav.contains(f.id);
      if (cat != 'all' && f.cat != cat) return false;
      return true;
    }).toList();
    Widget chip(String key, String icon, String label, Color col) => Padding(
          padding: const EdgeInsetsDirectional.only(end: 8),
          child: _Chp(
            on: cat == key,
            color: col,
            onTap: () => setState(() => cat = key),
            child: Row(mainAxisSize: MainAxisSize.min, children: [_Ic(icon, size: 24), const SizedBox(width: 6), _t(label, size: 12.5, w: FontWeight.w800)]),
          ),
        );
    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 40),
      physics: const BouncingScrollPhysics(),
      children: [
        Row(children: [
          const _Ic('search', size: 34),
          const SizedBox(width: 10),
          _t('گەڕان بۆ خواردن', size: 20, w: FontWeight.w800),
          const Spacer(),
          _t('${all.length} خواردن', size: 12, c: V.mu),
        ]),
        const SizedBox(height: 12),
        _Field(c: q, hint: 'ناوی خواردن بنووسە...', onChanged: (_) => setState(() {})),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: [
            chip('all', 'all', 'هەموو', V.cy),
            chip('fav', 'fav', 'دڵخواز', _pink),
            for (final c in _kCats) chip(c[0], c[2], c[1], _catColor(c[0])),
          ]),
        ),
        const SizedBox(height: 14),
        if (list.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Column(children: [
              const _Ic('search', size: 64),
              const SizedBox(height: 10),
              _t(cat == 'fav' ? 'هێشتا دڵخوازت نییە؛ لە وردەکاری خواردن دڵ دابگرە' : 'هیچ خواردنێک نەدۆزرایەوە', c: V.mu, align: TextAlign.center),
            ]),
          ),
        for (final f in list) _FoodRow(f: f, onTap: () => _open(f), onAdd: () => _open(f)),
        const SizedBox(height: 6),
        Press(
          onTap: () async {
            await _openCustom(meal: _meal, cur: _todayKey());
            if (mounted) setState(() {});
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), border: Border.all(color: op(V.orange, 0.6), width: 1.4), color: op(V.orange, 0.07)),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const _Ic('custom', size: 28),
              const SizedBox(width: 8),
              _t('+ خواردنی تایبەتی خۆت زیاد بکە', size: 14, w: FontWeight.w800, c: V.orange),
            ]),
          ),
        ),
      ],
    );
  }
}

// ═════════════════════════════ شیکاری ═════════════════════════════
class _StatsTab extends StatefulWidget {
  const _StatsTab();
  @override
  State<_StatsTab> createState() => _StatsTabState();
}

class _StatsTabState extends State<_StatsTab> {
  final TextEditingController wc = TextEditingController();

  @override
  void dispose() {
    wc.dispose();
    super.dispose();
  }

  Widget _kpi(String icon, String v, String l, Color c) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: _glass(r: 20, tint: c, a: 0.09),
          child: Column(children: [
            _Ic(icon, size: 30),
            const SizedBox(height: 4),
            _n(v, 18, c: c),
            const SizedBox(height: 2),
            _t(l, size: 11.5, c: V.mu),
          ]),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final fd = _FD.I;
    final plan = fd.plan!;
    final P = fd.prof!;
    final now = DateTime.now();
    final keys = <String>[];
    for (int i = 6; i >= 0; i--) {
      keys.add(_key(DateTime(now.year, now.month, now.day).subtract(Duration(days: i))));
    }
    final tots = keys.map((k) => fd.totals(k)).toList();
    final logged = tots.where((t) => t.n > 0).toList();
    final avgK = logged.isEmpty ? 0.0 : logged.fold<double>(0, (a, t) => a + t.kcal) / logged.length;
    final avgP = logged.isEmpty ? 0.0 : logged.fold<double>(0, (a, t) => a + t.p) / logged.length;
    final aP = logged.fold<double>(0, (a, t) => a + t.p * 4);
    final aC = logged.fold<double>(0, (a, t) => a + t.c * 4);
    final aF = logged.fold<double>(0, (a, t) => a + t.f * 9);
    final sum = aP + aC + aF;
    final st = fd.streaks();
    final maxK = math.max(plan.kcal * 1.25, tots.fold<double>(0, (a, t) => math.max(a, t.kcal)));
    const barH = 130.0;

    Widget bar(int i) {
      final t = tots[i];
      final d = _fromKey(keys[i]);
      final h = t.n == 0 ? 6.0 : math.max(8.0, barH * t.kcal / maxK);
      Color col = V.track;
      if (t.n > 0) col = t.kcal > plan.kcal * 1.1 ? V.coral : (t.kcal >= plan.kcal * 0.8 ? V.mint : V.amber);
      final isToday = i == 6;
      return Expanded(
        child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
          if (t.n > 0) _n(fmt(t.kcal), 10, c: V.mu, w: FontWeight.w700),
          const SizedBox(height: 4),
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: h),
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeOutCubic,
            builder: (c, v, _) => Container(
              width: 24,
              height: v,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(9),
                gradient: t.n == 0 ? null : LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [col, op(col, 0.55)]),
                color: t.n == 0 ? V.track : null,
                border: isToday ? Border.all(color: V.tx.withAlpha(150), width: 1.2) : null,
              ),
            ),
          ),
          const SizedBox(height: 6),
          _t(kDays[d.weekday % 7].substring(0, 3), size: 10.5, c: isToday ? V.tx : V.mu, w: isToday ? FontWeight.w800 : FontWeight.w600),
        ]),
      );
    }

    final goalY = barH * plan.kcal / maxK;
    final ws = fd.weights.length > 10 ? fd.weights.sublist(fd.weights.length - 10) : fd.weights;
    final wpts = ws.map((w) => w.kg).toList();
    final wFirst = fd.weights.isEmpty ? P.w : fd.weights.first.kg;
    final wLast = fd.weights.isEmpty ? P.w : fd.weights.last.kg;
    final diff = wLast - wFirst;

    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 40),
      physics: const BouncingScrollPhysics(),
      children: [
        Row(children: [
          const _Ic('analytics', size: 34),
          const SizedBox(width: 10),
          _t('شیکاری ٧ ڕۆژ', size: 20, w: FontWeight.w800),
        ]),
        const SizedBox(height: 14),
        Row(children: [
          _kpi('kcal', logged.isEmpty ? '—' : fmt(avgK), 'کالۆری ناوەند', V.cy),
          const SizedBox(width: 8),
          _kpi('protein2', logged.isEmpty ? '—' : '${avgP.round()}g', 'پرۆتین ناوەند', const Color(0xFFFF5F7E)),
          const SizedBox(width: 8),
          _kpi('today', '${logged.length}/7', 'ڕۆژی تۆمارکراو', V.mint),
        ]),
        VCard(
          margin: const EdgeInsets.only(top: 14),
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [_t('کالۆری ڕۆژانە', size: 15, w: FontWeight.w800), const Spacer(), _t('ئامانج ${fmt(plan.kcal)}', size: 11.5, c: V.mint)]),
            const SizedBox(height: 14),
            SizedBox(
              height: barH + 44,
              child: Stack(children: [
                PositionedDirectional(
                  start: 0,
                  end: 0,
                  bottom: 22 + goalY,
                  child: SizedBox(height: 2, child: CustomPaint(painter: _DashP(op(V.mint, 0.75)))),
                ),
                Row(crossAxisAlignment: CrossAxisAlignment.end, children: [for (int i = 0; i < 7; i++) bar(i)]),
              ]),
            ),
          ]),
        ),
        VCard(
          margin: const EdgeInsets.only(top: 12),
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _t('دابەشبوونی ماکرۆکان', size: 15, w: FontWeight.w800),
            const SizedBox(height: 12),
            Row(children: [
              SizedBox(
                width: 130,
                height: 130,
                child: CustomPaint(
                  painter: _DonutP([aP, aC, aF], const [Color(0xFFFF5F7E), Color(0xFFFFA52E), Color(0xFF9B7BFF)], V.track),
                  child: Center(child: _n(sum <= 0 ? '—' : fmt(avgK), 17)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(children: [
                  for (final r in [
                    ['پرۆتین', aP, const Color(0xFFFF5F7E)],
                    ['کارب', aC, const Color(0xFFFFA52E)],
                    ['چەوری', aF, const Color(0xFF9B7BFF)],
                  ])
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(children: [
                        Container(width: 12, height: 12, decoration: BoxDecoration(color: r[2] as Color, shape: BoxShape.circle)),
                        const SizedBox(width: 8),
                        _t(r[0] as String, size: 13.5, w: FontWeight.w700),
                        const Spacer(),
                        _n(sum <= 0 ? '—' : '${((r[1] as double) / sum * 100).round()}%', 14, c: r[2] as Color),
                      ]),
                    ),
                ]),
              ),
            ]),
          ]),
        ),
        VCard(
          margin: const EdgeInsets.only(top: 12),
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _t('بەردەوامی', size: 15, w: FontWeight.w800),
                const SizedBox(height: 4),
                _t('ڕۆژانی یەک لە دوای یەک کە خواردنت تۆمار کردووە', size: 11.5, c: V.mu, h: 1.5),
              ]),
            ),
            const _Sv('flame', size: 34),
            const SizedBox(width: 6),
            Column(children: [_n('${st[0]}', 26, c: V.orange), _t('ئێستا', size: 10.5, c: V.mu)]),
            const SizedBox(width: 16),
            Column(children: [_n('${st[1]}', 26, c: V.amber), _t('باشترین', size: 10.5, c: V.mu)]),
          ]),
        ),
        VCard(
          margin: const EdgeInsets.only(top: 12),
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [
              const _Ic('weight', size: 30),
              const SizedBox(width: 8),
              _t('کێش', size: 15, w: FontWeight.w800),
              const Spacer(),
              _n('${_f1(wLast)} kg', 18, c: V.cy),
            ]),
            const SizedBox(height: 10),
            if (wpts.length >= 2)
              SizedBox(height: 110, child: CustomPaint(painter: _LineP(wpts, V.cy, P.tw > 0 ? P.tw : 0)))
            else
              Padding(padding: const EdgeInsets.symmetric(vertical: 18), child: Center(child: _t('کێشی ٢ ڕۆژ تۆمار بکە تا هێڵکارییەکە دەرکەوێت', size: 12, c: V.mu))),
            if (fd.weights.length >= 2)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: _t('گۆڕانکاری: ${diff >= 0 ? '+' : ''}${diff.toStringAsFixed(1)}kg', size: 12.5, c: diff.abs() < 0.05 ? V.mu : ((diff < 0) == (P.goal == 'lose') ? V.mint : V.amber)),
              ),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _Field(c: wc, isNum: true, hint: 'کێشی ئەمڕۆ (kg)')),
              const SizedBox(width: 8),
              _PlusBtn(
                color: V.cy,
                size: 50,
                onTap: () {
                  final v = double.tryParse(wc.text.trim().replaceAll(',', '.')) ?? 0;
                  if (v < 20 || v > 300) {
                    toast('کێشێکی دروست بنووسە');
                    return;
                  }
                  fd.setWeight(v);
                  wc.clear();
                  FocusManager.instance.primaryFocus?.unfocus();
                  toast('کێش تۆمار کرا ✓');
                },
              ),
            ]),
          ]),
        ),
      ],
    );
  }
}

// ═════════════════════════════ من ═════════════════════════════
class _MeTab extends StatefulWidget {
  const _MeTab({required this.onWizard});
  final void Function(_Prof?, {int step}) onWizard;
  @override
  State<_MeTab> createState() => _MeTabState();
}

class _MeTabState extends State<_MeTab> {
  bool confirm = false;

  Widget _row(String l, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(children: [_t(l, size: 13, c: V.mu), const Spacer(), Text(v, style: ku(14, w: FontWeight.w800), textDirection: TextDirection.ltr)]),
      );

  @override
  Widget build(BuildContext context) {
    final fd = _FD.I;
    final P = fd.prof!;
    final plan = fd.plan!;
    final g = _goalOf(P.goal);
    final hm = P.h / 100;
    final bmi = hm <= 0 ? 0.0 : P.w / (hm * hm);
    String cat;
    Color cc;
    if (bmi < 18.5) {
      cat = 'کێشت کەمە';
      cc = const Color(0xFF6AA8FF);
    } else if (bmi < 25) {
      cat = 'کێشی ئاسایی';
      cc = V.mint;
    } else if (bmi < 30) {
      cat = 'کێشی زیادە';
      cc = V.amber;
    } else {
      cat = 'قەڵەوی';
      cc = V.coral;
    }
    final st = fd.streaks();
    final init = P.name.trim().isEmpty ? '؟' : P.name.trim().substring(0, 1);
    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 40),
      physics: const BouncingScrollPhysics(),
      children: [
        VCard(
          margin: EdgeInsets.zero,
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            Container(
              width: 62,
              height: 62,
              decoration: const BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF8FF3F9), Color(0xFF3CF08A)])),
              child: Center(child: Text(init, style: ku(26, w: FontWeight.w800, c: const Color(0xFF05303A)))),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _t(P.name.isEmpty ? 'بەکارهێنەر' : P.name, size: 18, w: FontWeight.w800),
                const SizedBox(height: 4),
                Row(children: [_Sv(g[3], size: 20), const SizedBox(width: 6), Flexible(child: _t(g[1], size: 12.5, c: V.mu, lines: 1))]),
              ]),
            ),
            Press(
              onTap: () => widget.onWizard(P, step: 0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                decoration: BoxDecoration(color: V.surf2, borderRadius: BorderRadius.circular(14), border: Border.all(color: V.line)),
                child: _t('دەستکاری', size: 12.5, w: FontWeight.w800),
              ),
            ),
          ]),
        ),
        VCard(
          margin: const EdgeInsets.only(top: 12),
          padding: const EdgeInsets.all(14),
          child: Column(children: [
            Row(children: [
              const _Ic('weight', size: 28),
              const SizedBox(width: 8),
              _t('پێوانەی BMI', size: 15, w: FontWeight.w800),
            ]),
            const SizedBox(height: 8),
            SizedBox(width: 220, height: 130, child: CustomPaint(painter: _GaugeP(bmi, V.tx, V.surf))),
            _n(bmi.toStringAsFixed(1), 30, c: cc),
            _t(cat, size: 14, c: cc, w: FontWeight.w800),
          ]),
        ),
        VCard(
          margin: const EdgeInsets.only(top: 12),
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: Column(children: [
            _row('تەمەن', '${P.age.round()}'),
            Divider(height: 1, color: V.line),
            _row('باڵا', '${_f1(P.h)} cm'),
            Divider(height: 1, color: V.line),
            _row('کێش', '${_f1(P.w)} kg'),
            if (P.tw > 0) ...[Divider(height: 1, color: V.line), _row('کێشی ئامانج', '${_f1(P.tw)} kg')],
            Divider(height: 1, color: V.line),
            _row('کالۆری ڕۆژانە', '${fmt(plan.kcal)} kcal'),
            Divider(height: 1, color: V.line),
            _row('پرۆتین / کارب / چەوری', '${plan.p} / ${plan.c} / ${plan.f} g'),
            Divider(height: 1, color: V.line),
            _row('ئاو', '${(plan.water / 1000).toStringAsFixed(1)} L'),
            Divider(height: 1, color: V.line),
            _row('بەردەوامی', '${st[0]} / ${st[1]}'),
          ]),
        ),
        if (P.conds.isNotEmpty || P.allg.isNotEmpty)
          VCard(
            margin: const EdgeInsets.only(top: 12),
            padding: const EdgeInsets.all(14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              if (P.conds.isNotEmpty) ...[
                _t('دۆخی تەندروستی', size: 14, w: FontWeight.w800),
                const SizedBox(height: 8),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  for (final k in P.conds)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      decoration: _glass(r: 20, tint: V.coral, a: 0.09),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        _Sv(_kConds.firstWhere((x) => x[0] == k, orElse: () => _kConds[0])[2], size: 22),
                        const SizedBox(width: 6),
                        _t(_kConds.firstWhere((x) => x[0] == k, orElse: () => _kConds[0])[1], size: 12.5),
                      ]),
                    ),
                ]),
              ],
              if (P.allg.isNotEmpty) ...[
                const SizedBox(height: 12),
                _t('هەستیاری', size: 14, w: FontWeight.w800),
                const SizedBox(height: 8),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  for (final k in P.allg)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      decoration: _glass(r: 20, tint: V.amber, a: 0.09),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        _Sv(_kAllg.firstWhere((x) => x[0] == k, orElse: () => _kAllg[0])[2], size: 22),
                        const SizedBox(width: 6),
                        _t(_kAllg.firstWhere((x) => x[0] == k, orElse: () => _kAllg[0])[1], size: 12.5),
                      ]),
                    ),
                ]),
              ],
            ]),
          ),
        const SizedBox(height: 16),
        _bigBtn('دروستکردنەوەی پلان', () => widget.onWizard(P, step: 1)),
        const SizedBox(height: 10),
        if (!confirm)
          _bigBtn('سڕینەوەی هەموو داتا', () => setState(() => confirm = true), ghost: true, color: V.coral)
        else
          Container(
            padding: const EdgeInsets.all(14),
            decoration: _glass(r: 20, tint: V.coral, a: 0.1),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              _t('دڵنیایت؟ هەموو تۆمار و پلانەکەت دەسڕێتەوە.', size: 13, h: 1.6),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(child: _bigBtn('نەخێر', () => setState(() => confirm = false), ghost: true)),
                const SizedBox(width: 8),
                Expanded(
                  child: _bigBtn('بەڵێ، بیسڕەوە', () async {
                    await _FD.I.reset();
                    if (mounted) setState(() => confirm = false);
                  }, ghost: true, color: V.coral),
                ),
              ]),
            ]),
          ),
      ],
    );
  }
}

// ═════════════════════════════ ویزارد ═════════════════════════════
class _Wizard extends StatefulWidget {
  const _Wizard({super.key, required this.initial, required this.startStep, required this.canCancel, required this.onDone, required this.onCancel});
  final _Prof? initial;
  final int startStep;
  final bool canCancel;
  final ValueChanged<_Prof> onDone;
  final VoidCallback onCancel;
  @override
  State<_Wizard> createState() => _WizardState();
}

class _WizardState extends State<_Wizard> {
  late _Prof p = widget.initial?.copy() ?? _Prof();
  late int step = widget.startStep.clamp(0, 5).toInt();
  late final TextEditingController nameC = TextEditingController(text: p.name);
  late final TextEditingController ageC = TextEditingController(text: p.age > 0 ? _f1(p.age) : '');
  late final TextEditingController hC = TextEditingController(text: p.h > 0 ? _f1(p.h) : '');
  late final TextEditingController wC = TextEditingController(text: p.w > 0 ? _f1(p.w) : '');
  late final TextEditingController twC = TextEditingController(text: p.tw > 0 ? _f1(p.tw) : '');
  late final TextEditingController noteC = TextEditingController(text: p.note);

  static const List<String> _titles = ['تۆ کێیت؟', 'زانیارییە سەرەتاییەکان', 'ئامانجت چییە؟', 'چالاکییەکەت', 'تەندروستی', 'پلانەکەت'];
  static const List<String> _subs = [
    'ناو و ڕەگەز بۆ هەژمارکردنی ورد',
    'تەمەن، باڵا و کێشی ئێستا',
    'ئامانجی سەرەکی دیاری بکە',
    'ڕۆژانە چەند چالاکیت؟',
    'نەخۆشی و هەستیاری (ئارەزوومەندانە)',
    'پلانی تایبەتی تۆ ئامادەیە',
  ];

  @override
  void dispose() {
    nameC.dispose();
    ageC.dispose();
    hC.dispose();
    wC.dispose();
    twC.dispose();
    noteC.dispose();
    super.dispose();
  }

  double _v(TextEditingController c) => double.tryParse(c.text.trim().replaceAll(',', '.')) ?? 0;

  bool _validate() {
    if (step == 0) {
      if (p.sex.isEmpty) {
        toast('ڕەگەزەکەت هەڵبژێرە');
        return false;
      }
      p.name = nameC.text.trim();
    }
    if (step == 1) {
      final a = _v(ageC), h = _v(hC), w = _v(wC);
      if (a < 10 || a > 100) {
        toast('تەمەنێکی دروست بنووسە');
        return false;
      }
      if (h < 100 || h > 230) {
        toast('باڵایەکی دروست بنووسە (cm)');
        return false;
      }
      if (w < 25 || w > 300) {
        toast('کێشێکی دروست بنووسە (kg)');
        return false;
      }
      p.age = a;
      p.h = h;
      p.w = w;
    }
    if (step == 2) {
      if (p.goal.isEmpty) {
        toast('ئامانجێک هەڵبژێرە');
        return false;
      }
      final tw = _v(twC);
      if (p.goal == 'lose' || p.goal == 'gain' || p.goal == 'muscle') {
        if (tw > 0 && p.goal == 'lose' && tw >= p.w) {
          toast('کێشی ئامانج دەبێت لە کێشی ئێستا کەمتر بێت');
          return false;
        }
        if (tw > 0 && (p.goal == 'gain' || p.goal == 'muscle') && tw <= p.w) {
          toast('کێشی ئامانج دەبێت لە کێشی ئێستا زیاتر بێت');
          return false;
        }
        p.tw = tw;
      } else {
        p.tw = 0;
      }
    }
    if (step == 4) p.note = noteC.text.trim();
    return true;
  }

  void _next() {
    FocusManager.instance.primaryFocus?.unfocus();
    if (!_validate()) return;
    if (step >= 5) {
      widget.onDone(p);
      return;
    }
    setState(() => step++);
  }

  void _back() {
    FocusManager.instance.primaryFocus?.unfocus();
    if (step == 0) {
      if (widget.canCancel) widget.onCancel();
      return;
    }
    setState(() => step--);
  }

  Widget _choice({required bool on, required VoidCallback onTap, required Widget icon, required String title, String? sub, Color? color}) {
    final col = color ?? V.mint;
    return Press(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: on ? op(col, 0.12) : V.surf,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: on ? col : V.line, width: on ? 1.6 : 1),
        ),
        child: Row(children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(color: op(col, on ? 0.18 : 0.08), borderRadius: BorderRadius.circular(16)),
            child: Center(child: icon),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _t(title, size: 15, w: FontWeight.w800),
              if (sub != null) Padding(padding: const EdgeInsets.only(top: 2), child: _t(sub, size: 11.5, c: V.mu, h: 1.5)),
            ]),
          ),
          Icon(on ? Icons.check_circle_rounded : Icons.circle_outlined, color: on ? col : V.line2, size: 24),
        ]),
      ),
    );
  }

  Widget _toggleChip(String label, Widget icon, bool on, VoidCallback f, Color col) => _Chp(
        on: on,
        color: col,
        onTap: f,
        child: Row(mainAxisSize: MainAxisSize.min, children: [icon, const SizedBox(width: 6), _t(label, size: 12.5, w: FontWeight.w800)]),
      );

  Widget _stepBody() {
    switch (step) {
      case 0:
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          _Lbl('ناوەکەت (ئارەزوومەندانە)', top: 4),
          _Field(c: nameC, hint: 'ناو'),
          _Lbl('ڕەگەز'),
          Row(children: [
            Expanded(
              child: _choiceBox('m', 'نێر', Icons.man_rounded, const Color(0xFF6AA8FF)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _choiceBox('f', 'مێ', Icons.woman_rounded, _pink),
            ),
          ]),
        ]);
      case 1:
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          _Lbl('تەمەن (ساڵ)', top: 4),
          _Field(c: ageC, isNum: true, hint: '25'),
          _Lbl('باڵا (cm)'),
          _Field(c: hC, isNum: true, hint: '170'),
          _Lbl('کێشی ئێستا (kg)'),
          _Field(c: wC, isNum: true, hint: '70'),
        ]);
      case 2:
        final needT = p.goal == 'lose' || p.goal == 'gain' || p.goal == 'muscle';
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          for (final g in _kGoals) _choice(on: p.goal == g[0], onTap: () => setState(() => p.goal = g[0]), icon: _Sv(g[3], size: 38), title: g[1], sub: g[2]),
          if (needT) ...[
            _Lbl('کێشی ئامانج (kg) — ئارەزوومەندانە'),
            _Field(c: twC, isNum: true, hint: p.goal == 'lose' ? '65' : '75'),
          ],
          if (p.goal == 'lose' || p.goal == 'gain') ...[
            _Lbl('خێرایی'),
            Row(children: [
              for (final r in _kPace)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsetsDirectional.only(end: 8),
                    child: Press(
                      onTap: () => setState(() => p.pace = r[0] as double),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: (p.pace - (r[0] as double)).abs() < 0.01 ? op(V.mint, 0.14) : V.surf2,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: (p.pace - (r[0] as double)).abs() < 0.01 ? V.mint : V.line),
                        ),
                        child: Column(children: [_t(r[1] as String, size: 13, w: FontWeight.w800), Text('${r[2]}/هەفتە', style: nu(10.5, c: V.mu, w: FontWeight.w600))]),
                      ),
                    ),
                  ),
                ),
            ]),
          ],
          _Lbl('زۆرتر کێ خواردن ئامادە دەکات؟'),
          Wrap(spacing: 8, runSpacing: 8, children: [
            _toggleChip('ماڵەوە', const Icon(Icons.home_rounded, size: 18), p.where == 'home', () => setState(() => p.where = 'home'), V.mint),
            _toggleChip('دەرەوە / ڕێستورانت', const Icon(Icons.storefront_rounded, size: 18), p.where == 'out', () => setState(() => p.where = 'out'), V.orange),
            _toggleChip('هەردووکی', const Icon(Icons.swap_horiz_rounded, size: 18), p.where == 'both', () => setState(() => p.where = 'both'), V.cy),
          ]),
        ]);
      case 3:
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          for (final a in _kActs)
            _choice(
              on: (p.act - (a[0] as double)).abs() < 0.001,
              onTap: () => setState(() => p.act = a[0] as double),
              icon: _Sv(a[1] as String, size: 38),
              title: a[2] as String,
              sub: a[3] as String,
            ),
          _Lbl('ڕۆژی وەرزش لە هەفتەیەکدا'),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (int d = 0; d <= 7; d++)
              _Chp(on: p.days == d, onTap: () => setState(() => p.days = d), child: _n('$d', 14, c: p.days == d ? V.mint : V.tx)),
          ]),
        ]);
      case 4:
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          _Lbl('نەخۆشی', top: 4),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final c in _kConds)
              _toggleChip(c[1], _Sv(c[2], size: 22), p.conds.contains(c[0]), () {
                setState(() {
                  if (p.conds.contains(c[0])) {
                    p.conds.remove(c[0]);
                  } else {
                    p.conds.add(c[0]);
                  }
                });
              }, V.coral),
          ]),
          _Lbl('هەستیاری خواردن'),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final a in _kAllg)
              _toggleChip(a[1], _Sv(a[2], size: 22), p.allg.contains(a[0]), () {
                setState(() {
                  if (p.allg.contains(a[0])) {
                    p.allg.remove(a[0]);
                  } else {
                    p.allg.add(a[0]);
                  }
                });
              }, V.amber),
          ]),
          _Lbl('تێبینی'),
          _Field(c: noteC, hint: 'هەر شتێکی تر کە ڕاهێنەر بیزانێت...', lines: 3),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: _glass(r: 16, tint: V.cy, a: 0.07),
            child: _t('ئەمە جێگای پزیشک ناگرێتەوە؛ بۆ نەخۆشی پەیوەندی بە پزیشکەکەتەوە بکە.', size: 12, c: V.mu, h: 1.6),
          ),
        ]);
      default:
        final pl = _planFor(p);
        final g = _goalOf(p.goal);
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF0E4A59), Color(0xFF07303C)]),
              border: Border.all(color: const Color(0x4D6CF0F7)),
            ),
            child: Column(children: [
              Row(children: [
                _Sv(g[3], size: 40),
                const SizedBox(width: 10),
                Expanded(child: _t(g[1], size: 16, w: FontWeight.w800, c: const Color(0xFFEAFFFF))),
              ]),
              const SizedBox(height: 14),
              _n(fmt(pl.kcal), 50, c: const Color(0xFFEAFFFF)),
              Text('kcal / ڕۆژ', style: nu(13, c: const Color(0xFF8FC3CB), w: FontWeight.w700)),
              const SizedBox(height: 14),
              Row(children: [
                _sumTile('protein2', '${pl.p}g', 'پرۆتین', const Color(0xFFFF5F7E)),
                const SizedBox(width: 8),
                _sumTile('carbs', '${pl.c}g', 'کارب', const Color(0xFFFFA52E)),
                const SizedBox(width: 8),
                _sumTile('fat', '${pl.f}g', 'چەوری', const Color(0xFF9B7BFF)),
              ]),
              const SizedBox(height: 8),
              Row(children: [
                _sumTile('water', '${(pl.water / 1000).toStringAsFixed(1)}L', 'ئاو', const Color(0xFF2FC4F0)),
                const SizedBox(width: 8),
                _sumTile('fiber', '${pl.fib}g', 'فایبەر', V.mint),
                const SizedBox(width: 8),
                _sumTile('sugar', '${pl.sug}g', 'شەکر', _pink),
              ]),
              if (pl.weeks > 0) ...[
                const SizedBox(height: 12),
                _t('نزیکەی ${pl.weeks} هەفتە بۆ گەیشتن بە ${_f1(p.tw)}kg', size: 12.5, c: const Color(0xFFEAFFFF), align: TextAlign.center),
              ],
            ]),
          ),
          for (final f in pl.flags)
            Container(
              margin: const EdgeInsets.only(top: 10),
              padding: const EdgeInsets.all(12),
              decoration: _glass(r: 18, tint: V.amber, a: 0.1),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Icon(Icons.warning_amber_rounded, color: V.amber, size: 22),
                const SizedBox(width: 8),
                Expanded(child: _t(f, size: 12.5, h: 1.65, w: FontWeight.w600)),
              ]),
            ),
        ]);
    }
  }

  Widget _sumTile(String icon, String v, String l, Color c) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(color: const Color(0x14FFFFFF), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0x1FFFFFFF))),
          child: Column(children: [_Ic(icon, size: 26), const SizedBox(height: 3), _n(v, 16, c: c), _t(l, size: 11, c: const Color(0xFFB4D4D9))]),
        ),
      );

  Widget _choiceBox(String key, String label, IconData ic, Color col) {
    final on = p.sex == key;
    return Press(
      onTap: () => setState(() => p.sex = key),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(vertical: 22),
        decoration: BoxDecoration(
          color: on ? op(col, 0.14) : V.surf,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: on ? col : V.line, width: on ? 1.8 : 1),
        ),
        child: Column(children: [Icon(ic, size: 54, color: on ? col : V.mu), const SizedBox(height: 6), _t(label, size: 15, w: FontWeight.w800, c: on ? col : V.tx)]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final last = step >= 5;
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 4),
        child: Row(children: [
          Opacity(
            opacity: (step == 0 && !widget.canCancel) ? 0 : 1,
            child: Press(
              onTap: _back,
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(color: V.surf, shape: BoxShape.circle, border: Border.all(color: V.line)),
                child: Icon(kIsLtr ? Icons.chevron_left_rounded : Icons.chevron_right_rounded, color: V.tx),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Row(children: [
                for (int i = 0; i < 6; i++)
                  Expanded(
                    child: Container(
                      height: 5,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(color: i <= step ? V.mint : V.track, borderRadius: BorderRadius.circular(4)),
                    ),
                  ),
              ]),
            ]),
          ),
        ]),
      ),
      Expanded(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
          physics: const BouncingScrollPhysics(),
          children: [
            _t(_titles[step], size: 24, w: FontWeight.w800),
            const SizedBox(height: 4),
            _t(_subs[step], size: 13, c: V.mu),
            const SizedBox(height: 16),
            _stepBody(),
          ],
        ),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
        child: _bigBtn(last ? 'دەست پێ بکە 🎉' : 'دواتر', _next),
      ),
    ]);
  }
}
const Map<String, String> _kSvg = {
  'glucose': r'''<svg viewBox='0 0 64 64'><defs><radialGradient id='{p}a' cx='0.35' cy='0.3' r='0.8'><stop offset='0' stop-color='#ff9aa8'/><stop offset='0.55' stop-color='#ec3a62'/><stop offset='1' stop-color='#b3123f'/></radialGradient><linearGradient id='{p}c' x1='0' y1='0' x2='0' y2='1'><stop offset='0' stop-color='#ffffff'/><stop offset='1' stop-color='#dbe7f5'/></linearGradient></defs><g stroke='none'><path d='M28 5C28 5 11 25 11 37a17 17 0 0034 0C45 25 28 5 28 5z' fill='url(#{p}a)' stroke='#9c0f38' stroke-width='1' /><ellipse cx='21' cy='33' rx='3.2' ry='7' fill='#fff' opacity='.55' transform='rotate(18 21 33)'/><path d='M40 36l10-4 10 4v11l-10 5-10-5z' fill='url(#{p}c)' stroke='#8fb0d6' stroke-width='1.2'/><path d='M40 36l10 4 10-4M50 40v12' fill='none' stroke='#8fb0d6' stroke-width='1.2'/><path d='M40 36l10-4 10 4-10 4z' fill='#fff'/></g></svg>''',
  'bp': r'''<svg viewBox='0 0 64 64'><defs><linearGradient id='{p}a' x1='0' y1='0' x2='0' y2='1'><stop offset='0' stop-color='#ffffff'/><stop offset='1' stop-color='#cfd9e6'/></linearGradient><linearGradient id='{p}b' x1='0' y1='0' x2='0' y2='1'><stop offset='0' stop-color='#2f3a4a'/><stop offset='1' stop-color='#161d29'/></linearGradient><linearGradient id='{p}c' x1='0' y1='0' x2='0' y2='1'><stop offset='0' stop-color='#ff6b6b'/><stop offset='1' stop-color='#d62839'/></linearGradient></defs><g stroke='none'><circle cx='32' cy='30' r='24' fill='url(#{p}b)'/><circle cx='32' cy='30' r='20' fill='url(#{p}a)' stroke='#9fb0c4' stroke-width='1'/><path d='M15.5 38A17 17 0 0119 22' fill='none' stroke='#3cc477' stroke-width='5' stroke-linecap='butt'/><path d='M19 22A17 17 0 0145 22' fill='none' stroke='#ffc107' stroke-width='5' stroke-linecap='butt'/><path d='M45 22A17 17 0 0148.5 38' fill='none' stroke='#e53935' stroke-width='5' stroke-linecap='butt'/><path d='M32 30l9-11' stroke='#1a2233' stroke-width='3' stroke-linecap='round' fill='none'/><circle cx='32' cy='30' r='4' fill='#1a2233'/><circle cx='32' cy='30' r='1.6' fill='#fff'/><path d='M22 58h20' stroke='#5b6b80' stroke-width='4' stroke-linecap='round' fill='none'/><path d='M32 54v4' stroke='#5b6b80' stroke-width='3' fill='none'/><ellipse cx='22' cy='15' rx='7' ry='2.5' fill='#fff' opacity='.55' transform='rotate(-30 22 15)'/></g></svg>''',
  'chol': r'''<svg viewBox='0 0 64 64'><defs><radialGradient id='{p}a' cx='0.35' cy='0.3' r='0.8'><stop offset='0' stop-color='#ff9a8a'/><stop offset='0.55' stop-color='#e04a3c'/><stop offset='1' stop-color='#a4231a'/></radialGradient><radialGradient id='{p}b' cx='0.35' cy='0.3' r='0.8'><stop offset='0' stop-color='#fff3b0'/><stop offset='0.55' stop-color='#ffc533'/><stop offset='1' stop-color='#e0900a'/></radialGradient><radialGradient id='{p}c' cx='0.35' cy='0.3' r='0.8'><stop offset='0' stop-color='#7d1b1b'/><stop offset='0.55' stop-color='#4a0d0d'/><stop offset='1' stop-color='#2a0606'/></radialGradient></defs><g stroke='none'><circle cx='32' cy='32' r='26' fill='url(#{p}a)'/><path d='M32 12a20 20 0 0120 20c0 11-9 20-20 20-4 0-8-1-11-3 6 1 13-3 13-10 0-8-12-8-12-17 0-6 4-10 10-10z' fill='url(#{p}b)'/><circle cx='32' cy='32' r='10' fill='url(#{p}c)'/><circle cx='23' cy='26' r='3.2' fill='#ffe27a' opacity='.9'/><circle cx='41' cy='41' r='2.4' fill='#ffe27a' opacity='.9'/><ellipse cx='20' cy='17' rx='8' ry='3' fill='#fff' opacity='.55' transform='rotate(-35 20 17)'/></g></svg>''',
  'heart': r'''<svg viewBox='0 0 64 64'><defs><radialGradient id='{p}a' cx='0.35' cy='0.3' r='0.8'><stop offset='0' stop-color='#ff8fa3'/><stop offset='0.55' stop-color='#f0345c'/><stop offset='1' stop-color='#b30f3b'/></radialGradient></defs><g stroke='none'><path d='M32 56C14 44 6 33 6 22 6 13 13 7 21 7c5 0 9 2 11 7 2-5 6-7 11-7 8 0 15 6 15 15 0 11-8 22-26 34z' fill='url(#{p}a)' stroke='#a30d35' stroke-width='1'/><ellipse cx='18' cy='20' rx='4' ry='7' fill='#fff' opacity='.55' transform='rotate(30 18 20)'/><path d='M12 32h9l4-7 6 14 4-9h17' fill='none' stroke='#fff' stroke-width='3' stroke-linecap='round' stroke-linejoin='round' opacity='.95'/></g></svg>''',
  'kidney': r'''<svg viewBox='0 0 64 64'><defs><radialGradient id='{p}a' cx='0.35' cy='0.3' r='0.8'><stop offset='0' stop-color='#ff9c8c'/><stop offset='0.55' stop-color='#d9503f'/><stop offset='1' stop-color='#8f1f17'/></radialGradient><linearGradient id='{p}v' x1='0' y1='0' x2='0' y2='1'><stop offset='0' stop-color='#7aa7ff'/><stop offset='1' stop-color='#3b6fe0'/></linearGradient><linearGradient id='{p}u' x1='0' y1='0' x2='0' y2='1'><stop offset='0' stop-color='#ffd27a'/><stop offset='1' stop-color='#e8a135'/></linearGradient></defs><g stroke='none'><path d='M28 52c-1 3 0 5-3 8' stroke='#e8a135' stroke-width='4.5' stroke-linecap='round' fill='none'/><path d='M22 30c-6 1-10-1-13-7' stroke='#3b6fe0' stroke-width='4.5' stroke-linecap='round' fill='none'/><path d='M22 34c-6 4-10 5-14 3' stroke='#e5484d' stroke-width='4' stroke-linecap='round' fill='none'/><path d='M38 5c13 0 21 12 19 27-2 16-12 25-24 23-9-1-11-9-6-13 4-3 4-7 1-11C23 27 13 24 13 16 13 8 25 5 38 5z' fill='url(#{p}a)' stroke='#7a150f' stroke-width='1'/><ellipse cx='42' cy='15' rx='9' ry='3' fill='#fff' opacity='.55' transform='rotate(-20 42 15)'/><path d='M44 24c3 3 4 9 3 14' fill='none' stroke='#fff' stroke-width='2' opacity='.3' stroke-linecap='round'/></g></svg>''',
  'foot': r'''<svg viewBox='0 0 64 64'><defs><radialGradient id='{p}a' cx='0.35' cy='0.3' r='0.8'><stop offset='0' stop-color='#ffe0c4'/><stop offset='0.55' stop-color='#f3b98c'/><stop offset='1' stop-color='#d98f5e'/></radialGradient><radialGradient id='{p}r' cx='0.35' cy='0.3' r='0.8'><stop offset='0' stop-color='#ff8a80'/><stop offset='0.55' stop-color='#f0443a'/><stop offset='1' stop-color='#b3150f'/></radialGradient></defs><g stroke='none'><circle cx='27' cy='15' r='13' fill='#ff5a4d' opacity='.2'/><path d='M25 22c9-3 20 1 22 13 1 8-2 13-2 19 0 6-5 8-11 8s-11-3-11-9c0-6 2-9 2-17 0-8-1-11 0-14z' fill='url(#{p}a)' stroke='#b9794a' stroke-width='1'/><ellipse cx='28' cy='14' rx='6.500' ry='8' fill='url(#{p}r)' stroke='#9c120c' stroke-width='1'/><circle cx='37' cy='13' r='4' fill='url(#{p}a)' stroke='#b9794a' stroke-width='.8'/><circle cx='43.500' cy='17' r='3.600' fill='url(#{p}a)' stroke='#b9794a' stroke-width='.8'/><circle cx='48' cy='23' r='3.200' fill='url(#{p}a)' stroke='#b9794a' stroke-width='.8'/><circle cx='50' cy='30' r='2.800' fill='url(#{p}a)' stroke='#b9794a' stroke-width='.8'/><ellipse cx='25.500' cy='10.500' rx='2.200' ry='3.200' fill='#fff' opacity='.55'/><path d='M10 6l5 4M7 15h6M10 24l5-3' stroke='#ff7a6e' stroke-width='2.200' stroke-linecap='round' fill='none'/></g></svg>''',
  'flame': r'''<svg viewBox='0 0 64 64'><defs><linearGradient id='{p}a' x1='0' y1='0' x2='0' y2='1'><stop offset='0' stop-color='#ffc15a'/><stop offset='1' stop-color='#f04a14'/></linearGradient><linearGradient id='{p}b' x1='0' y1='0' x2='0' y2='1'><stop offset='0' stop-color='#fff7b0'/><stop offset='1' stop-color='#ffc21f'/></linearGradient></defs><g stroke='none'><path d='M33 4c2 10 15 16 15 33 0 12-8 21-18 21S13 49 13 39c0-8 5-13 8-18 1 6 4 9 7 10-1-10-1-19 5-27z' fill='url(#{p}a)' stroke='#c2380b' stroke-width='1'/><path d='M31 28c1 7 9 11 9 20 0 6-4 9-9 9s-9-3-9-9c0-5 3-7 5-10 1 3 2 4 4 4-1-6-1-10 0-14z' fill='url(#{p}b)'/><ellipse cx='22' cy='30' rx='2.400' ry='6' fill='#fff' opacity='.55' transform='rotate(15 22 30)'/></g></svg>''',
  'preg': r'''<svg viewBox='0 0 64 64'><defs><radialGradient id='{p}s' cx='0.35' cy='0.3' r='0.8'><stop offset='0' stop-color='#ffe3cc'/><stop offset='0.55' stop-color='#f4bd96'/><stop offset='1' stop-color='#d78f62'/></radialGradient><linearGradient id='{p}d' x1='0' y1='0' x2='0' y2='1'><stop offset='0' stop-color='#ff9fcb'/><stop offset='1' stop-color='#e0559b'/></linearGradient><linearGradient id='{p}h' x1='0' y1='0' x2='0' y2='1'><stop offset='0' stop-color='#6b4a3a'/><stop offset='1' stop-color='#3d2619'/></linearGradient></defs><g stroke='none'><path d='M26 21c6-3 11-1 13 5l1 7c8 2 12 9 10 17-2 8-9 12-18 11l-2 5H24l1-11c-3-8-5-20 1-34z' fill='url(#{p}d)' stroke='#b73b7e' stroke-width='1'/><circle cx='28' cy='13' r='8.500' fill='url(#{p}s)' stroke='#c58558' stroke-width='.8'/><path d='M20 13c-1-8 6-11 11-9 5 1 7 6 6 10-2-3-6-5-10-4-3 1-5 3-7 3z' fill='url(#{p}h)'/><ellipse cx='42' cy='46' rx='5' ry='8' fill='#fff' opacity='.55' transform='rotate(-15 42 46)'/><path d='M29 55v6M23 55v6' stroke='#d78f62' stroke-width='3.500' stroke-linecap='round' fill='none'/></g></svg>''',
  'bottle': r'''<svg viewBox='0 0 64 64'><defs><linearGradient id='{p}g' x1='0' y1='0' x2='0' y2='1'><stop offset='0' stop-color='#ffffff'/><stop offset='1' stop-color='#d6ecff'/></linearGradient><linearGradient id='{p}m' x1='0' y1='0' x2='0' y2='1'><stop offset='0' stop-color='#ffffff'/><stop offset='1' stop-color='#f3ead9'/></linearGradient><linearGradient id='{p}n' x1='0' y1='0' x2='0' y2='1'><stop offset='0' stop-color='#ffd27a'/><stop offset='1' stop-color='#e8a135'/></linearGradient><linearGradient id='{p}r' x1='0' y1='0' x2='0' y2='1'><stop offset='0' stop-color='#ff9fcb'/><stop offset='1' stop-color='#e0559b'/></linearGradient></defs><g stroke='none'><path d='M28 4c0 3 1 4 4 4s4-1 4-4c3 0 5 2 5 4 0 3-3 4-4 6H27c-1-2-4-3-4-6 0-2 2-4 5-4z' fill='url(#{p}n)' stroke='#b9791b' stroke-width='1'/><rect x='20' y='14' width='24' height='8' rx='3' fill='url(#{p}r)' stroke='#b73b7e' stroke-width='1'/><path d='M22 22h20c3 0 5 2 5 5v26c0 4-3 7-7 7H24c-4 0-7-3-7-7V27c0-3 2-5 5-5z' fill='url(#{p}g)' stroke='#8fb6df' stroke-width='1.200'/><path d='M17 36h30v17c0 4-3 7-7 7H24c-4 0-7-3-7-7z' fill='url(#{p}m)'/><path d='M40 30h5M40 36h3M40 42h5M40 48h3' stroke='#6f98c6' stroke-width='1.800' stroke-linecap='round' fill='none'/><ellipse cx='24' cy='38' rx='2.600' ry='9' fill='#fff' opacity='.55'/></g></svg>''',
  'wheat': r'''<svg viewBox='0 0 64 64'><defs><linearGradient id='{p}a' x1='0' y1='0' x2='0' y2='1'><stop offset='0' stop-color='#ffe89a'/><stop offset='1' stop-color='#e2a42a'/></linearGradient><linearGradient id='{p}s' x1='0' y1='0' x2='0' y2='1'><stop offset='0' stop-color='#a6c45a'/><stop offset='1' stop-color='#6f9a2c'/></linearGradient></defs><g stroke='none'><path d='M32 22v38' stroke='url(#{p}s)' stroke-width='3.500' stroke-linecap='round' fill='none'/><path d='M32 6c3 3 3 7 0 11-3-4-3-8 0-11z' fill='url(#{p}a)' stroke='#a8700f' stroke-width='.7'/><path d='M0-7c4 2 5 7 0 14-5-7-4-12 0-14z' fill='url(#{p}a)' stroke='#a8700f' stroke-width='.7' transform='translate(24 20) rotate(-38)'/><path d='M0-7c4 2 5 7 0 14-5-7-4-12 0-14z' fill='url(#{p}a)' stroke='#a8700f' stroke-width='.7' transform='translate(40 20) rotate(38)'/><path d='M0-7c4 2 5 7 0 14-5-7-4-12 0-14z' fill='url(#{p}a)' stroke='#a8700f' stroke-width='.7' transform='translate(24 29) rotate(-38)'/><path d='M0-7c4 2 5 7 0 14-5-7-4-12 0-14z' fill='url(#{p}a)' stroke='#a8700f' stroke-width='.7' transform='translate(40 29) rotate(38)'/><path d='M0-7c4 2 5 7 0 14-5-7-4-12 0-14z' fill='url(#{p}a)' stroke='#a8700f' stroke-width='.7' transform='translate(24 38) rotate(-38)'/><path d='M0-7c4 2 5 7 0 14-5-7-4-12 0-14z' fill='url(#{p}a)' stroke='#a8700f' stroke-width='.7' transform='translate(40 38) rotate(38)'/><path d='M0-7c4 2 5 7 0 14-5-7-4-12 0-14z' fill='url(#{p}a)' stroke='#a8700f' stroke-width='.7' transform='translate(24 47) rotate(-38)'/><path d='M0-7c4 2 5 7 0 14-5-7-4-12 0-14z' fill='url(#{p}a)' stroke='#a8700f' stroke-width='.7' transform='translate(40 47) rotate(38)'/><path d='M0-7c4 2 5 7 0 14-5-7-4-12 0-14z' fill='url(#{p}a)' stroke='#a8700f' stroke-width='.7' transform='translate(32 12) rotate(0)'/></g></svg>''',
  'shrimp': r'''<svg viewBox='0 0 64 64'><defs><linearGradient id='{p}a' x1='0' y1='0' x2='0' y2='1'><stop offset='0' stop-color='#ffb08a'/><stop offset='1' stop-color='#ee6a3c'/></linearGradient><linearGradient id='{p}b' x1='0' y1='0' x2='0' y2='1'><stop offset='0' stop-color='#ffd8c0'/><stop offset='1' stop-color='#f7946a'/></linearGradient></defs><g stroke='none'><path d='M40 14C28 8 14 16 14 30c0 12 9 20 20 19' stroke='url(#{p}a)' stroke-width='13' stroke-linecap='round' fill='none'/><path d='M40 14C28 8 14 16 14 30c0 12 9 20 20 19' stroke='#fff' stroke-width='2' stroke-linecap='round' fill='none' opacity='.28' transform='translate(-1 -3)'/><path d='M22 18l-4 6M16 27l-5 2M16 36l-5 0M21 44l-4 4' stroke='#c4421a' stroke-width='2' stroke-linecap='round' fill='none'/><path d='M36 49l8 6 4-8-6-3zM36 49l2 9 8-3' fill='url(#{p}b)' stroke='#c4421a' stroke-width='1'/><path d='M46 13c4-6 9-7 13-5M45 16c5-2 9 0 11 3' stroke='#c4421a' stroke-width='1.800' stroke-linecap='round' fill='none'/><circle cx='44' cy='17' r='3.400' fill='#fff'/><circle cx='44.800' cy='17' r='1.700' fill='#1a1a1a'/></g></svg>''',
  'soy': r'''<svg viewBox='0 0 64 64'><defs><linearGradient id='{p}p' x1='0' y1='0' x2='0' y2='1'><stop offset='0' stop-color='#a9d96a'/><stop offset='1' stop-color='#5f9a2a'/></linearGradient><radialGradient id='{p}b' cx='0.35' cy='0.3' r='0.8'><stop offset='0' stop-color='#f3ffd0'/><stop offset='0.55' stop-color='#c4e48a'/><stop offset='1' stop-color='#8fbd4a'/></radialGradient></defs><g stroke='none'><path d='M10 50C14 28 30 12 54 10c0 22-14 40-38 44-4 1-6-1-6-4z' fill='url(#{p}p)' stroke='#3f6f17' stroke-width='1.200'/><circle cx='22' cy='42' r='6.500' fill='url(#{p}b)' stroke='#7ea63a' stroke-width='.8'/><circle cx='33' cy='31' r='6.500' fill='url(#{p}b)' stroke='#7ea63a' stroke-width='.8'/><circle cx='44' cy='21' r='6' fill='url(#{p}b)' stroke='#7ea63a' stroke-width='.8'/><path d='M16 20c3-2 6-3 9-3M30 10c-3 0-5 0-8 2' stroke='#4f8a22' stroke-width='2.500' stroke-linecap='round' fill='none'/><ellipse cx='20' cy='40' rx='1.800' ry='2.600' fill='#fff' opacity='.55'/></g></svg>''',
  'g_lose': r'''<svg viewBox='0 0 64 64'><defs><linearGradient id='{p}a' x1='0' y1='0' x2='0' y2='1'><stop offset='0' stop-color='#ffb199'/><stop offset='1' stop-color='#ef4a3c'/></linearGradient><linearGradient id='{p}g' x1='0' y1='0' x2='0' y2='1'><stop offset='0' stop-color='#7dffc0'/><stop offset='1' stop-color='#12b868'/></linearGradient></defs><g stroke='none'><rect x='8' y='14' width='14' height='40' rx='4' fill='url(#{p}a)' stroke='#b9291f' stroke-width='1'/><rect x='10' y='16' width='3.5' height='34' rx='1.7' fill='#fff' opacity='.55'/><rect x='24' y='26' width='14' height='28' rx='4' fill='url(#{p}a)' stroke='#b9291f' stroke-width='1'/><rect x='26' y='28' width='3.5' height='22' rx='1.7' fill='#fff' opacity='.55'/><rect x='40' y='38' width='14' height='16' rx='4' fill='url(#{p}a)' stroke='#b9291f' stroke-width='1'/><rect x='42' y='40' width='3.5' height='10' rx='1.7' fill='#fff' opacity='.55'/><path d='M8 14L26 26l10-8 18 14' fill='none' stroke='#0c8c4e' stroke-width='7' stroke-linecap='round' stroke-linejoin='round'/><path d='M8 14L26 26l10-8 18 14' fill='none' stroke='url(#{p}g)' stroke-width='4.5' stroke-linecap='round' stroke-linejoin='round'/><path d='M42 38h12V26' fill='none' stroke='#0c8c4e' stroke-width='7' stroke-linecap='round' stroke-linejoin='round'/><path d='M42 38h12V26' fill='none' stroke='url(#{p}g)' stroke-width='4.5' stroke-linecap='round' stroke-linejoin='round'/></g></svg>''',
  'g_gain': r'''<svg viewBox='0 0 64 64'><defs><linearGradient id='{p}a' x1='0' y1='0' x2='0' y2='1'><stop offset='0' stop-color='#a8f0ff'/><stop offset='1' stop-color='#1f9bd8'/></linearGradient><linearGradient id='{p}g' x1='0' y1='0' x2='0' y2='1'><stop offset='0' stop-color='#ffe27a'/><stop offset='1' stop-color='#f2a500'/></linearGradient></defs><g stroke='none'><rect x='8' y='38' width='14' height='16' rx='4' fill='url(#{p}a)' stroke='#146e9c' stroke-width='1'/><rect x='10' y='40' width='3.5' height='10' rx='1.7' fill='#fff' opacity='.55'/><rect x='24' y='26' width='14' height='28' rx='4' fill='url(#{p}a)' stroke='#146e9c' stroke-width='1'/><rect x='26' y='28' width='3.5' height='22' rx='1.7' fill='#fff' opacity='.55'/><rect x='40' y='14' width='14' height='40' rx='4' fill='url(#{p}a)' stroke='#146e9c' stroke-width='1'/><rect x='42' y='16' width='3.5' height='34' rx='1.7' fill='#fff' opacity='.55'/><path d='M8 40L26 28l10 8 16-18' fill='none' stroke='#b87400' stroke-width='7' stroke-linecap='round' stroke-linejoin='round'/><path d='M8 40L26 28l10 8 16-18' fill='none' stroke='url(#{p}g)' stroke-width='4.5' stroke-linecap='round' stroke-linejoin='round'/><path d='M42 14h12v12' fill='none' stroke='#b87400' stroke-width='7' stroke-linecap='round' stroke-linejoin='round'/><path d='M42 14h12v12' fill='none' stroke='url(#{p}g)' stroke-width='4.5' stroke-linecap='round' stroke-linejoin='round'/></g></svg>''',
  'g_muscle': r'''<svg viewBox='0 0 64 64'><defs><radialGradient id='{p}a' cx='0.35' cy='0.3' r='0.8'><stop offset='0' stop-color='#8a99b3'/><stop offset='0.55' stop-color='#46546e'/><stop offset='1' stop-color='#222b3d'/></radialGradient><linearGradient id='{p}h' x1='0' y1='0' x2='0' y2='1'><stop offset='0' stop-color='#ffb35c'/><stop offset='1' stop-color='#ff7a1a'/></linearGradient></defs><g stroke='none'><path d='M20 24a12 12 0 0124 0' fill='none' stroke='#1b2335' stroke-width='9' stroke-linecap='round'/><path d='M20 24a12 12 0 0124 0' fill='none' stroke='#5d6b86' stroke-width='5' stroke-linecap='round'/><circle cx='32' cy='40' r='20' fill='url(#{p}a)' stroke='#161d2c' stroke-width='1.2'/><ellipse cx='24' cy='32' rx='5' ry='8' fill='#fff' opacity='.55' transform='rotate(25 24 32)'/><rect x='22' y='38' width='20' height='8' rx='4' fill='url(#{p}h)'/><rect x='24' y='39.5' width='9' height='2' rx='1' fill='#fff' opacity='.55'/></g></svg>''',
  'g_aging': r'''<svg viewBox='0 0 64 64'><defs><linearGradient id='{p}a' x1='0' y1='0' x2='0' y2='1'><stop offset='0' stop-color='#c8ff8a'/><stop offset='1' stop-color='#3fbf3f'/></linearGradient><linearGradient id='{p}b' x1='0' y1='0' x2='0' y2='1'><stop offset='0' stop-color='#9be26a'/><stop offset='1' stop-color='#1f9a47'/></linearGradient><linearGradient id='{p}s' x1='0' y1='0' x2='0' y2='1'><stop offset='0' stop-color='#c98f5e'/><stop offset='1' stop-color='#8a5530'/></linearGradient></defs><g stroke='none'><path d='M30 54c0-12 0-20 2-30' fill='none' stroke='#18803c' stroke-width='4' stroke-linecap='round'/><path d='M31 30C16 32 8 22 8 10c14-2 24 4 23 20z' fill='url(#{p}a)' stroke='#2a8d2e' stroke-width='1.2'/><path d='M33 24C34 11 44 6 57 8c1 13-8 22-24 16z' fill='url(#{p}b)' stroke='#17803c' stroke-width='1.2'/><path d='M12 14c8 2 14 6 17 13M38 18c6-3 11-5 16-5' fill='none' stroke='#fff' stroke-width='1.4' opacity='.55' stroke-linecap='round'/><ellipse cx='32' cy='55' rx='17' ry='5.5' fill='url(#{p}s)' stroke='#6c4020' stroke-width='1'/><ellipse cx='26' cy='53.5' rx='6' ry='1.6' fill='#fff' opacity='.55'/></g></svg>''',
  'w_gym': r'''<svg viewBox='0 0 64 64'><defs><linearGradient id='{p}m' x1='0' y1='0' x2='0' y2='1'><stop offset='0' stop-color='#ffb35c'/><stop offset='1' stop-color='#ee6a12'/></linearGradient><linearGradient id='{p}d' x1='0' y1='0' x2='0' y2='1'><stop offset='0' stop-color='#59667f'/><stop offset='1' stop-color='#242d42'/></linearGradient><linearGradient id='{p}c' x1='0' y1='0' x2='0' y2='1'><stop offset='0' stop-color='#e6ecf5'/><stop offset='1' stop-color='#a9b6ca'/></linearGradient></defs><g stroke='none'><rect x='18' y='28' width='28' height='8' rx='3' fill='url(#{p}c)' stroke='#8392aa' stroke-width='1'/><rect x='9' y='17' width='10' height='30' rx='4' fill='url(#{p}d)' stroke='#161d2c' stroke-width='1'/><rect x='45' y='17' width='10' height='30' rx='4' fill='url(#{p}d)' stroke='#161d2c' stroke-width='1'/><rect x='3' y='23' width='8' height='18' rx='3' fill='url(#{p}m)' stroke='#b04a0a' stroke-width='1'/><rect x='53' y='23' width='8' height='18' rx='3' fill='url(#{p}m)' stroke='#b04a0a' stroke-width='1'/><rect x='11' y='19' width='3' height='12' rx='1.5' fill='#fff' opacity='.55'/><rect x='47' y='19' width='3' height='12' rx='1.5' fill='#fff' opacity='.55'/></g></svg>''',
  'w_home': r'''<svg viewBox='0 0 64 64'><defs><linearGradient id='{p}r' x1='0' y1='0' x2='0' y2='1'><stop offset='0' stop-color='#ff8f7a'/><stop offset='1' stop-color='#d93a35'/></linearGradient><linearGradient id='{p}w' x1='0' y1='0' x2='0' y2='1'><stop offset='0' stop-color='#fff4dc'/><stop offset='1' stop-color='#f0c987'/></linearGradient><linearGradient id='{p}d' x1='0' y1='0' x2='0' y2='1'><stop offset='0' stop-color='#6fb4ff'/><stop offset='1' stop-color='#2c6fd6'/></linearGradient></defs><g stroke='none'><rect x='11' y='27' width='42' height='28' rx='3' fill='url(#{p}w)' stroke='#c89a4c' stroke-width='1.2'/><path d='M4 30L32 8l28 22z' fill='url(#{p}r)' stroke='#a32420' stroke-width='1.4' stroke-linejoin='round'/><path d='M12 27L32 12' fill='none' stroke='#fff' stroke-width='2' opacity='.5' stroke-linecap='round'/><rect x='26' y='38' width='12' height='17' rx='3' fill='url(#{p}d)' stroke='#1d4fa5' stroke-width='1'/><circle cx='35' cy='47' r='1.2' fill='#fff'/><rect x='15' y='34' width='8' height='8' rx='1.5' fill='url(#{p}d)' stroke='#1d4fa5' stroke-width='1'/><rect x='41' y='34' width='8' height='8' rx='1.5' fill='url(#{p}d)' stroke='#1d4fa5' stroke-width='1'/></g></svg>''',
  'w_rest': r'''<svg viewBox='0 0 64 64'><defs><linearGradient id='{p}a' x1='0' y1='0' x2='0' y2='1'><stop offset='0' stop-color='#c9a8ff'/><stop offset='1' stop-color='#7a4fe0'/></linearGradient><linearGradient id='{p}b' x1='0' y1='0' x2='0' y2='1'><stop offset='0' stop-color='#b08cf5'/><stop offset='1' stop-color='#5f36c4'/></linearGradient></defs><g stroke='none'><rect x='6' y='26' width='10' height='24' rx='5' fill='url(#{p}b)' stroke='#4a2aa0' stroke-width='1'/><rect x='48' y='26' width='10' height='24' rx='5' fill='url(#{p}b)' stroke='#4a2aa0' stroke-width='1'/><rect x='13' y='12' width='38' height='28' rx='9' fill='url(#{p}a)' stroke='#4a2aa0' stroke-width='1.2'/><rect x='11' y='34' width='42' height='16' rx='6' fill='url(#{p}b)' stroke='#4a2aa0' stroke-width='1.2'/><rect x='18' y='16' width='20' height='3.5' rx='1.7' fill='#fff' opacity='.55'/><rect x='15' y='37' width='14' height='3' rx='1.5' fill='#fff' opacity='.55'/><rect x='14' y='50' width='5' height='6' rx='2' fill='#3b2380'/><rect x='45' y='50' width='5' height='6' rx='2' fill='#3b2380'/></g></svg>''',
  't_cola': r'''<svg viewBox='0 0 64 64'><defs><linearGradient id='{p}a' x1='0' y1='0' x2='0' y2='1'><stop offset='0' stop-color='#ff7b6b'/><stop offset='1' stop-color='#c81f2d'/></linearGradient><linearGradient id='{p}l' x1='0' y1='0' x2='0' y2='1'><stop offset='0' stop-color='#ffffff'/><stop offset='1' stop-color='#dfe6ef'/></linearGradient><linearGradient id='{p}w' x1='0' y1='0' x2='0' y2='1'><stop offset='0' stop-color='#fff'/><stop offset='1' stop-color='#ffd9d3'/></linearGradient></defs><g stroke='none'><path d='M40 4L36 22' fill='none' stroke='#d8dee8' stroke-width='3.6' stroke-linecap='round'/><path d='M40 4L36 22' fill='none' stroke='#fff' stroke-width='1.4' stroke-linecap='round'/><path d='M14 20h36l-4 36a3 3 0 01-3 3H21a3 3 0 01-3-3z' fill='url(#{p}a)' stroke='#8e1220' stroke-width='1.2'/><path d='M16 33h32l-1 9H17z' fill='url(#{p}w)'/><circle cx='32' cy='37.500' r='3.800' fill='#c81f2d'/><circle cx='25' cy='47' r='1.8' fill='#fff' opacity='.7'/><circle cx='39' cy='50' r='1.4' fill='#fff' opacity='.7'/><rect x='11' y='15' width='42' height='8' rx='4' fill='url(#{p}l)' stroke='#a9b6ca' stroke-width='1'/><rect x='18' y='25' width='3.500' height='20' rx='1.7' fill='#fff' opacity='.55'/></g></svg>''',
  't_plate': r'''<svg viewBox='0 0 64 64'><defs><linearGradient id='{p}p' x1='0' y1='0' x2='0' y2='1'><stop offset='0' stop-color='#ffffff'/><stop offset='1' stop-color='#d7e0ec'/></linearGradient><linearGradient id='{p}g' x1='0' y1='0' x2='0' y2='1'><stop offset='0' stop-color='#9be26a'/><stop offset='1' stop-color='#27a84b'/></linearGradient><linearGradient id='{p}o' x1='0' y1='0' x2='0' y2='1'><stop offset='0' stop-color='#ffb35c'/><stop offset='1' stop-color='#ee7a1a'/></linearGradient><linearGradient id='{p}y' x1='0' y1='0' x2='0' y2='1'><stop offset='0' stop-color='#ffe27a'/><stop offset='1' stop-color='#f2b400'/></linearGradient></defs><g stroke='none'><circle cx='32' cy='33' r='27' fill='url(#{p}p)' stroke='#9fb0c4' stroke-width='1.2'/><circle cx='32' cy='33' r='20.500' fill='#f4f7fb' stroke='#c3cfde' stroke-width='1'/><path d='M32 33V12.500A20.500 20.500 0 0152.500 33 20.500 20.500 0 0132 53.500z' fill='url(#{p}g)'/><path d='M32 33V12.500A20.500 20.500 0 0011.500 33z' fill='url(#{p}y)'/><path d='M32 33H11.500A20.500 20.500 0 0032 53.500z' fill='url(#{p}o)'/><path d='M32 12.500v41M11.500 33h41' fill='none' stroke='#fff' stroke-width='1.6'/><ellipse cx='20' cy='22' rx='3' ry='6' fill='#fff' opacity='.55' transform='rotate(35 20 22)'/></g></svg>''',
  't_fries': r'''<svg viewBox='0 0 64 64'><defs><linearGradient id='{p}a' x1='0' y1='0' x2='0' y2='1'><stop offset='0' stop-color='#ff7b6b'/><stop offset='1' stop-color='#c81f2d'/></linearGradient><linearGradient id='{p}y' x1='0' y1='0' x2='0' y2='1'><stop offset='0' stop-color='#fff0a0'/><stop offset='1' stop-color='#f5b400'/></linearGradient></defs><g stroke='none'><rect x='14' y='6' width='6' height='26' rx='2.500' fill='url(#{p}y)' stroke='#c58a00' stroke-width='1' transform='rotate(-10 17 19)'/><rect x='22' y='3' width='6' height='28' rx='2.500' fill='url(#{p}y)' stroke='#c58a00' stroke-width='1' transform='rotate(-4 25 17)'/><rect x='31' y='4' width='6' height='28' rx='2.500' fill='url(#{p}y)' stroke='#c58a00' stroke-width='1' transform='rotate(4 34 18)'/><rect x='40' y='6' width='6' height='26' rx='2.500' fill='url(#{p}y)' stroke='#c58a00' stroke-width='1' transform='rotate(11 43 19)'/><path d='M10 26h44l-5 30a3 3 0 01-3 2.500H18a3 3 0 01-3-2.500z' fill='url(#{p}a)' stroke='#8e1220' stroke-width='1.2'/><path d='M32 36c-3-4-9-1-6 4l6 7 6-7c3-5-3-8-6-4z' fill='#ffd54a' stroke='#c58a00' stroke-width='.8'/><rect x='16' y='30' width='3.500' height='20' rx='1.7' fill='#fff' opacity='.55'/></g></svg>''',
  't_shoe': r'''<svg viewBox='0 0 64 64'><defs><linearGradient id='{p}a' x1='0' y1='0' x2='0' y2='1'><stop offset='0' stop-color='#7fd4ff'/><stop offset='1' stop-color='#1f7fe0'/></linearGradient><linearGradient id='{p}s' x1='0' y1='0' x2='0' y2='1'><stop offset='0' stop-color='#ffffff'/><stop offset='1' stop-color='#cfd9e6'/></linearGradient><linearGradient id='{p}c' x1='0' y1='0' x2='0' y2='1'><stop offset='0' stop-color='#ffb35c'/><stop offset='1' stop-color='#ee7a1a'/></linearGradient></defs><g stroke='none'><path d='M6 38c0-8 4-14 8-17l6 5c3 2 6 2 9-1l3-4 8 5c6 3 14 6 17 11 2 3 1 7-3 7H10c-3 0-4-3-4-6z' fill='url(#{p}a)' stroke='#145aa8' stroke-width='1.3' stroke-linejoin='round'/><path d='M4 46h56v4a5 5 0 01-5 5H9a5 5 0 01-5-5z' fill='url(#{p}s)' stroke='#9fb0c4' stroke-width='1.2'/><path d='M26 25l4 5M32 22l4 5M38 25l3 5' stroke='#fff' stroke-width='2.200' stroke-linecap='round'/><path d='M9 40c8 3 18 3 26-1' fill='none' stroke='url(#{p}c)' stroke-width='3.200' stroke-linecap='round'/><ellipse cx='14' cy='30' rx='2.200' ry='4.500' fill='#fff' opacity='.55' transform='rotate(35 14 30)'/></g></svg>''',
  't_banana': r'''<svg viewBox='0 0 64 64'><defs><linearGradient id='{p}a' x1='0' y1='0' x2='0' y2='1'><stop offset='0' stop-color='#fff08a'/><stop offset='1' stop-color='#f5b800'/></linearGradient><linearGradient id='{p}t' x1='0' y1='0' x2='0' y2='1'><stop offset='0' stop-color='#9a7b3a'/><stop offset='1' stop-color='#5d4416'/></linearGradient></defs><g stroke='none'><path d='M10 14c4 22 20 38 46 36-8 8-26 9-38-3C8 36 5 24 10 14z' fill='url(#{p}a)' stroke='#b17f00' stroke-width='1.4' stroke-linejoin='round'/><path d='M10 14l4-8 5 2-3 9z' fill='url(#{p}t)' stroke='#3e2d0d' stroke-width='1'/><path d='M56 50l3 3-5 2z' fill='#5d4416'/><path d='M14 22c5 14 16 24 32 28' fill='none' stroke='#fff' stroke-width='3' opacity='.5' stroke-linecap='round'/></g></svg>''',
  't_sleep': r'''<svg viewBox='0 0 64 64'><defs><radialGradient id='{p}a' cx='0.35' cy='0.3' r='0.8'><stop offset='0' stop-color='#fff2b5'/><stop offset='0.55' stop-color='#ffc93c'/><stop offset='1' stop-color='#e59a00'/></radialGradient></defs><g stroke='none'><path d='M36 6a24 24 0 1020 34A19 19 0 0136 6z' fill='url(#{p}a)' stroke='#b87400' stroke-width='1.3' stroke-linejoin='round'/><ellipse cx='20' cy='28' rx='3' ry='7' fill='#fff' opacity='.55' transform='rotate(20 20 28)'/><path d='M40 10h10l-10 10h10' fill='none' stroke='#6f6bff' stroke-width='3.200' stroke-linecap='round' stroke-linejoin='round'/><path d='M50 26h7l-7 7h7' fill='none' stroke='#8e8bff' stroke-width='2.600' stroke-linecap='round' stroke-linejoin='round'/></g></svg>''',
  't_dish': r'''<svg viewBox='0 0 64 64'><defs><linearGradient id='{p}p' x1='0' y1='0' x2='0' y2='1'><stop offset='0' stop-color='#ffffff'/><stop offset='1' stop-color='#d7e0ec'/></linearGradient><linearGradient id='{p}f' x1='0' y1='0' x2='0' y2='1'><stop offset='0' stop-color='#e8eef7'/><stop offset='1' stop-color='#9fb0c4'/></linearGradient></defs><g stroke='none'><circle cx='32' cy='33' r='20' fill='url(#{p}p)' stroke='#9fb0c4' stroke-width='1.2'/><circle cx='32' cy='33' r='13.500' fill='#f6f9fc' stroke='#c3cfde' stroke-width='1'/><ellipse cx='25' cy='25' rx='2.600' ry='5' fill='#fff' opacity='.55' transform='rotate(35 25 25)'/><path d='M5 10v14c0 3 2 4 4 4v26M5 10v10M9 10v10M13 10v14c0 3-2 4-4 4' fill='none' stroke='url(#{p}f)' stroke-width='3' stroke-linecap='round' stroke-linejoin='round'/><path d='M5 10v14c0 3 2 4 4 4v26M5 10v10M9 10v10M13 10v14c0 3-2 4-4 4' fill='none' stroke='#8a9ab0' stroke-width='.8' stroke-linecap='round'/><path d='M55 10c-5 4-6 14-5 22h5v22' fill='none' stroke='url(#{p}f)' stroke-width='3.400' stroke-linecap='round' stroke-linejoin='round'/></g></svg>''',
  't_bone': r'''<svg viewBox='0 0 64 64'><defs><linearGradient id='{p}a' x1='0' y1='0' x2='0' y2='1'><stop offset='0' stop-color='#ffffff'/><stop offset='1' stop-color='#d9cdb4'/></linearGradient></defs><g stroke='none'><g transform='rotate(-40 32 32)'><rect x='14' y='26' width='36' height='12' rx='5' fill='url(#{p}a)' stroke='#a89a78' stroke-width='1.3'/><circle cx='13' cy='24' r='7' fill='url(#{p}a)' stroke='#a89a78' stroke-width='1.3'/><circle cx='13' cy='40' r='7' fill='url(#{p}a)' stroke='#a89a78' stroke-width='1.3'/><circle cx='51' cy='24' r='7' fill='url(#{p}a)' stroke='#a89a78' stroke-width='1.3'/><circle cx='51' cy='40' r='7' fill='url(#{p}a)' stroke='#a89a78' stroke-width='1.3'/><rect x='18' y='28' width='20' height='2.600' rx='1.300' fill='#fff'/></g></g></svg>''',
  't_rainbow': r'''<svg viewBox='0 0 64 64'><defs><linearGradient id='{p}c' x1='0' y1='0' x2='0' y2='1'><stop offset='0' stop-color='#ffffff'/><stop offset='1' stop-color='#dfe9f7'/></linearGradient></defs><g stroke='none'><path d='M6 48a26 26 0 0152 0' fill='none' stroke='#e8403f' stroke-width='6'/><path d='M12 48a20 20 0 0140 0' fill='none' stroke='#ffa51f' stroke-width='6'/><path d='M18 48a14 14 0 0128 0' fill='none' stroke='#ffd83a' stroke-width='6'/><path d='M24 48a8 8 0 0116 0' fill='none' stroke='#2fc468' stroke-width='6'/><g fill='url(#{p}c)' stroke='#aab9cf' stroke-width='1'><circle cx='9' cy='50' r='6'/><circle cx='17' cy='51' r='6'/><circle cx='13' cy='46' r='5'/><circle cx='55' cy='50' r='6'/><circle cx='47' cy='51' r='6'/><circle cx='51' cy='46' r='5'/></g></g></svg>''',
  'salt2': r'''<svg viewBox='0 0 64 64'><defs><linearGradient id='{p}g' x1='0' y1='0' x2='0' y2='1'><stop offset='0' stop-color='#f3fbff'/><stop offset='1' stop-color='#b9d3ea'/></linearGradient><linearGradient id='{p}c' x1='0' y1='0' x2='0' y2='1'><stop offset='0' stop-color='#9aa8bc'/><stop offset='1' stop-color='#566379'/></linearGradient><linearGradient id='{p}p' x1='0' y1='0' x2='0' y2='1'><stop offset='0' stop-color='#ffffff'/><stop offset='1' stop-color='#e2ebf6'/></linearGradient></defs><g stroke='none'><g transform='translate(-6.4 0) scale(1.2 1)'><path d='M20 24h24l3 28a5 5 0 01-5 5H22a5 5 0 01-5-5z' fill='url(#{p}g)' stroke='#7f9bb8' stroke-width='1.3' fill-opacity='.9'/><path d='M19 40h26l1.500 12a4 4 0 01-4 4.500H21.500a4 4 0 01-4-4.500z' fill='url(#{p}p)'/><path d='M21 14a11 9 0 0122 0v10H21z' fill='url(#{p}c)' stroke='#3f4b61' stroke-width='1.2'/><circle cx='27' cy='15' r='1.500' fill='#2b3446'/><circle cx='32' cy='12.500' r='1.500' fill='#2b3446'/><circle cx='37' cy='15' r='1.500' fill='#2b3446'/><circle cx='32' cy='18.500' r='1.500' fill='#2b3446'/><rect x='22' y='26' width='3.600' height='24' rx='1.800' fill='#fff' opacity='.55'/></g><g fill='#fff' stroke='#c3cfde' stroke-width='.6'><rect x='47' y='46' width='5' height='5' rx='1' transform='rotate(20 49 48)'/><rect x='52' y='52' width='4' height='4' rx='1' transform='rotate(-15 54 54)'/><rect x='43' y='55' width='4' height='4' rx='1' transform='rotate(35 45 57)'/></g></g></svg>''',
  'milk': r'''<svg viewBox='0 0 64 64'><defs><linearGradient id='{p}g' x1='0' y1='0' x2='0' y2='1'><stop offset='0' stop-color='#ffffff'/><stop offset='1' stop-color='#d4e8ff'/></linearGradient><linearGradient id='{p}c' x1='0' y1='0' x2='0' y2='1'><stop offset='0' stop-color='#5aa8ff'/><stop offset='1' stop-color='#2a6fe0'/></linearGradient></defs><ellipse cx='32' cy='58' rx='17' ry='3' fill='#000' opacity='.22'/><path d='M22 22h20l3 8v22c0 3-2 5-5 5H24c-3 0-5-2-5-5V30z' fill='url(#{p}g)' stroke='#9cc4f0' stroke-width='1.2'/><rect x='24' y='12' width='16' height='8' rx='3' fill='url(#{p}c)'/><rect x='20' y='30' width='24' height='8' fill='#e6f1ff' opacity='.7'/><ellipse cx='25' cy='38' rx='2.5' ry='10' fill='#fff' opacity='0.7' transform='rotate(0 25 38)'/></svg>''',
  'walnut': r'''<svg viewBox='0 0 64 64'><defs><radialGradient id='{p}w' cx='0.35' cy='0.3' r='0.75'><stop offset='0' stop-color='#e8c28a'/><stop offset='0.6' stop-color='#b98a4a'/><stop offset='1' stop-color='#7a5420'/></radialGradient><radialGradient id='{p}k' cx='0.5' cy='0.4' r='0.75'><stop offset='0' stop-color='#f6e6c2'/><stop offset='1' stop-color='#d4b078'/></radialGradient></defs><ellipse cx='32' cy='58' rx='17' ry='3' fill='#000' opacity='.22'/><circle cx='26' cy='34' r='19' fill='url(#{p}w)' stroke='#5e3f12' stroke-width='1'/><path d='M26 16c-4 6-4 12 0 18s4 12 0 18M14 24c6 2 8 6 8 10M38 24c-6 2-8 6-8 10M12 38c6 0 10 2 14 8M40 38c-6 0-10 2-14 8' stroke='#6b4a18' stroke-width='1.600' fill='none' stroke-linecap='round'/><path d='M40 30c8-4 16 0 16 8 0 10-10 16-18 12-6-3-6-14 2-20z' fill='url(#{p}k)' stroke='#a8803f' stroke-width='1'/><path d='M44 34c4-2 6 2 4 6-3 3-7 1-4-6zM46 42c3-1 4 2 2 4' stroke='#b98a4a' stroke-width='1.400' fill='none'/><ellipse cx='17' cy='26' rx='5' ry='2.5' fill='#fff' opacity='0.45' transform='rotate(-35 17 26)'/></svg>''',
  'egg': r'''<svg viewBox='0 0 64 64'><defs><radialGradient id='{p}a' cx='0.35' cy='0.3' r='0.75'><stop offset='0' stop-color='#fffaf0'/><stop offset='0.6' stop-color='#f3dfc0'/><stop offset='1' stop-color='#d9b98c'/></radialGradient><radialGradient id='{p}b' cx='0.35' cy='0.3' r='0.75'><stop offset='0' stop-color='#ffffff'/><stop offset='0.6' stop-color='#f6e6cd'/><stop offset='1' stop-color='#d9b98c'/></radialGradient></defs><ellipse cx='32' cy='58' rx='17' ry='3' fill='#000' opacity='.22'/><path d='M24 14c7-4 17 5 17 21 0 9-5 16-12 16S14 44 14 35c0-10 4-17 10-21z' transform='translate(6 0)' fill='url(#{p}a)'/><path d='M17 20c6-5 15 2 15 18 0 8-4 14-10 14s-11-6-11-15c0-8 2-13 6-17z' fill='url(#{p}b)' stroke='#c9a475' stroke-width='.8' stroke-opacity='.6'/><ellipse cx='19' cy='27' rx='3' ry='6' fill='#fff' opacity='0.6' transform='rotate(12 19 27)'/></svg>''',
  'fish': r'''<svg viewBox='0 0 64 64'><defs><linearGradient id='{p}f' x1='0' y1='0' x2='0' y2='1'><stop offset='0' stop-color='#9fd8ff'/><stop offset='1' stop-color='#2f7fd8'/></linearGradient><linearGradient id='{p}b' x1='0' y1='0' x2='0' y2='1'><stop offset='0' stop-color='#ffffff'/><stop offset='1' stop-color='#cfe6fb'/></linearGradient></defs><ellipse cx='32' cy='58' rx='17' ry='3' fill='#000' opacity='.22'/><path d='M6 32c8-12 24-16 36-8l14-8v32l-14-8c-12 8-28 4-36-8z' fill='url(#{p}f)' stroke='#1f5fb0' stroke-width='1'/><path d='M10 33c10 7 22 7 30-1-8 6-20 6-30 1z' fill='url(#{p}b)'/><path d='M42 26l14-10v32l-14-10z' fill='#4e9be8' opacity='.9'/><circle cx='19' cy='28' r='3' fill='#fff'/><circle cx='19.500' cy='28' r='1.500' fill='#12233f'/><path d='M26 22c4 4 4 16 0 20M32 22c3 4 3 16 0 20' stroke='#fff' stroke-width='1.200' opacity='.35' fill='none'/><ellipse cx='20' cy='22' rx='8' ry='2' fill='#fff' opacity='0.45' transform='rotate(-12 20 22)'/></svg>''',
  'sesame': r'''<svg viewBox='0 0 64 64'><defs><radialGradient id='{p}b' cx='0.4' cy='0.2' r='0.75'><stop offset='0' stop-color='#d29a63'/><stop offset='1' stop-color='#8a5226'/></radialGradient></defs><ellipse cx='32' cy='58' rx='17' ry='3' fill='#000' opacity='.22'/><path d='M8 34h48c0 12-9 20-24 20S8 46 8 34z' fill='url(#{p}b)'/><ellipse cx='32' cy='34' rx='24' ry='6' fill='#a36a35'/><path d='M12 33c4-12 14-16 20-16s16 4 20 16c-6 3-13 4-20 4s-14-1-20-4z' fill='#f0e2c0'/><ellipse cx='22' cy='28' rx='2' ry='1' fill='#fff7e0' transform='rotate(20 22 28)' stroke='#c9b07a' stroke-width='.4'/><ellipse cx='30' cy='24' rx='2' ry='1' fill='#fff7e0' transform='rotate(-30 30 24)' stroke='#c9b07a' stroke-width='.4'/><ellipse cx='38' cy='27' rx='2' ry='1' fill='#fff7e0' transform='rotate(40 38 27)' stroke='#c9b07a' stroke-width='.4'/><ellipse cx='44' cy='32' rx='2' ry='1' fill='#fff7e0' transform='rotate(10 44 32)' stroke='#c9b07a' stroke-width='.4'/><ellipse cx='27' cy='31' rx='2' ry='1' fill='#fff7e0' transform='rotate(-10 27 31)' stroke='#c9b07a' stroke-width='.4'/><ellipse cx='35' cy='31' rx='2' ry='1' fill='#fff7e0' transform='rotate(60 35 31)' stroke='#c9b07a' stroke-width='.4'/><ellipse cx='18' cy='33' rx='2' ry='1' fill='#fff7e0' transform='rotate(0 18 33)' stroke='#c9b07a' stroke-width='.4'/><ellipse cx='32' cy='29' rx='2' ry='1' fill='#fff7e0' transform='rotate(25 32 29)' stroke='#c9b07a' stroke-width='.4'/><ellipse cx='16' cy='44' rx='2.5' ry='5' fill='#fff' opacity='0.4' transform='rotate(25 16 44)'/></svg>''',
};
