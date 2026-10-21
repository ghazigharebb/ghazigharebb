// VEX Health — داتا و حیسابەکانی بەشی سەرەتا (تۆمارکردن و چوونە ژوورەوە)
//
// هەمان لۆجیکی وەشانی وێب: هەنگاوەکان، BMI، کێشی ئامانج، پلانی ڕۆژانە.
import 'dart:math' as math;

import 'package:flutter/material.dart';

int get kThisYear => DateTime.now().year;

/// یەکەم وشەی ناو (بۆ "سڵاو، ئاری")
String firstWord(String s) {
  final t = s.trim();
  if (t.isEmpty) return '';
  return t.split(RegExp(r'\s+')).first;
}

/// 7501234567 ← 750 123 4567
String fmtPhone(String d) {
  final s = d.replaceAll(RegExp(r'\D'), '');
  final b = StringBuffer();
  for (int i = 0; i < s.length; i++) {
    if (i == 3 || i == 6) b.write(' ');
    b.write(s[i]);
  }
  return b.toString();
}

/// ژمارەی مۆبایل پاک دەکاتەوە: 964 و 0 ی سەرەتا لادەبات، زۆرترین 10 ژمارە
String cleanPhone(String raw) {
  var d = raw.replaceAll(RegExp(r'[^0-9]'), '');
  if (d.startsWith('964')) d = d.substring(3);
  if (d.startsWith('0')) d = d.substring(1);
  if (d.length > 10) d = d.substring(0, 10);
  return d;
}

bool validPhone(String d) => RegExp(r'^7\d{9}$').hasMatch(d);

double asD(dynamic v, [double d = 0]) {
  if (v is num) return v.toDouble();
  return double.tryParse('$v') ?? d;
}

int asI(dynamic v, [int d = 0]) {
  if (v is num) return v.round();
  return int.tryParse('$v') ?? d;
}

String numTxt(double v) => v % 1 == 0 ? v.toStringAsFixed(0) : v.toStringAsFixed(1);

// ---------- لیستەکان ----------
class ROpt {
  const ROpt(this.k, this.e, this.t, [this.s = '', this.femaleOnly = false]);
  final String k;
  final String e;
  final String t;
  final String s;
  final bool femaleOnly;
}

const List<ROpt> kActs = [
  ROpt('sed', '🛋️', 'کەم جووڵە', 'زۆربەی ڕۆژ دانیشتوویت، وەک کاری ئۆفیس'),
  ROpt('light', '🚶', 'سووک', 'پیاسە و کاری ڕۆژانەی ئاسایی'),
  ROpt('active', '🏃', 'چالاک', '3 بۆ 5 ڕۆژ لە هەفتەدا وەرزش دەکەیت'),
  ROpt('very', '🏋️', 'زۆر چالاک', 'وەرزشی ڕۆژانە یان کاری جەستەیی قورس'),
];

const List<ROpt> kGoals = [
  ROpt('sleep', '😴', 'خەوی باشتر'),
  ROpt('stress', '🧘', 'سترێسی کەمتر'),
  ROpt('move', '👣', 'جووڵەی زیاتر'),
  ROpt('heart', '❤️', 'چاودێری دڵ'),
  ROpt('weight', '⚖️', 'کێشی تەندروست'),
  ROpt('fit', '💪', 'وەرزش و لەش جوانی'),
  ROpt('family', '👨‍👩‍👧', 'ئاگاداری خێزان'),
  ROpt('energy', '⚡', 'وزەی زیاتر'),
];

const List<ROpt> kConds = [
  ROpt('diab', '🩸', 'شەکرە'),
  ROpt('bp', '💓', 'فشاری خوێن'),
  ROpt('heart', '❤️', 'نەخۆشی دڵ'),
  ROpt('chol', '🫀', 'کۆلیسترۆڵ'),
  ROpt('asth', '🫁', 'ڕەبۆ'),
  ROpt('thy', '🦋', 'تیرۆید'),
  ROpt('kid', '🫘', 'گورچیلە'),
  ROpt('preg', '🤰', 'دووگیانی', '', true),
  ROpt('bf', '🤱', 'شیردان', '', true),
];

const List<ROpt> kNotif = [
  ROpt('water', '💧', 'یادخستنەوەی ئاو', 'چەند جارێک لە ڕۆژدا، بە پێی کێشەکەت'),
  ROpt('move', '🚶', 'کاتی جووڵە', 'ئەگەر ماوەیەکی زۆر دانیشتیت'),
  ROpt('sleep', '🌙', 'کاتی خەوتن', '30 خولەک پێش کاتی خەوتنت'),
  ROpt('heart', '❤️', 'ئاگاداری دڵ', 'ئەگەر لێدانی دڵ یان SpO₂ نائاسایی بوو'),
  ROpt('fam', '👨‍👩‍👧', 'بازنەی خێزان', 'هاندان و ئاگادارکردنەوەی ئازیزانت'),
];

class RPill {
  const RPill(this.e, this.t, this.c);
  final String e;
  final String t;
  final int c;
}

/// چوار ڕیزی تایبەتمەندییەکان لە بەخێرهاتندا (32 دانە)
const List<List<RPill>> kFeatRows = [
  [
    RPill('❤️', 'لێدانی دڵ 24/7', 0xFFFF5F7E),
    RPill('📈', 'ECG ی دڵ', 0xFFFF5F7E),
    RPill('🫁', 'ئۆکسجینی خوێن', 0xFF2FE6F3),
    RPill('🧠', 'سترێس و HRV', 0xFF9B7BFF),
    RPill('🌙', 'شیکاری خەو', 0xFFB9A4FF),
    RPill('🌡️', 'پلەی گەرمی پێست', 0xFFFFBE4D),
    RPill('🧬', 'تەمەنی جەستە', 0xFF3CF08A),
    RPill('🚨', 'ئاگاداری نائاسایی', 0xFFFF8A5F),
  ],
  [
    RPill('📸', 'سکانی خواردن بە AI', 0xFFFFBE4D),
    RPill('🥗', 'پلانی ژەمی تایبەت', 0xFF3CF08A),
    RPill('🔥', 'کالۆری و پڕۆتین', 0xFFFF9466),
    RPill('💧', 'ئاوی ڕۆژانە', 0xFF2FE6F3),
    RPill('⚖️', 'ئامانجی کێش', 0xFF3CF08A),
    RPill('🧑‍🏫', 'ڕاهێنەری خۆراک', 0xFF9B7BFF),
    RPill('🥜', 'ئاگاداری هەستیاری', 0xFFFFBE4D),
    RPill('💊', 'ڤیتامین و کانزا', 0xFF3CF08A),
  ],
  [
    RPill('✨', 'VEX AI بە کوردی', 0xFF9B7BFF),
    RPill('🩺', 'کورتەی تەندروستی AI', 0xFF2FE6F3),
    RPill('🏋️', 'وەرزش و تایمەر', 0xFF3CF08A),
    RPill('👣', 'هەنگاو و جووڵە', 0xFF2FE6F3),
    RPill('🧘', 'هەناسە و ئارامی', 0xFFB9A4FF),
    RPill('📊', 'ڕاپۆرتی هەفتانە', 0xFF2FE6F3),
    RPill('🔔', 'یادخستنەوەی زیرەک', 0xFFFF9466),
    RPill('📅', 'مێژووی تەندروستی', 0xFF8FF3F9),
  ],
  [
    RPill('👨‍👩‍👧', 'بازنەی خێزان', 0xFFFF8FC8),
    RPill('🍼', 'خواردنی منداڵ', 0xFFFF8FC8),
    RPill('🏆', 'VEX Arena', 0xFFFFBE4D),
    RPill('🎁', 'خاڵ و خەڵات', 0xFFFFBE4D),
    RPill('⌚', 'VEX Band', 0xFF8FF3F9),
    RPill('🆘', 'ئاگاداری فریاکەوتن', 0xFFFF5F7E),
    RPill('🔒', 'پاراستنی نهێنی', 0xFF3CF08A),
    RPill('🌙', 'کاتی خەوتنی زیرەک', 0xFFB9A4FF),
  ],
];

int get kFeatCount => kFeatRows.fold<int>(0, (a, r) => a + r.length);

class RFeat {
  const RFeat(this.e, this.c, this.t, this.s);
  final String e;
  final int c;
  final String t;
  final String s;
}

/// کارتەکانی کاتی دروستکردنی پلان
const List<RFeat> kBuildFeats = [
  RFeat('❤️', 0xFFFF5F7E, 'چاودێری دڵ 24/7', 'لێدانی دڵ، HRV و ECG، لەگەڵ ئاگاداری کاتێک شتێک نائاسایی بێت'),
  RFeat('✨', 0xFF9B7BFF, 'VEX AI، ڕاهێنەری تایبەتت', 'پرسیار بکە و شیکاری و پلانی ڕۆژانە بە کوردی وەربگرە'),
  RFeat('📸', 0xFFFFBE4D, 'سکانی خواردن بە وێنە', 'کالۆری و پێکهاتەی هەر ژەمێک لە چەند چرکەیەکدا'),
  RFeat('🌙', 0xFFB9A4FF, 'شیکاری قووڵی خەو', 'قۆناغەکانی خەو و نمرەی خەوی هەموو بەیانییەک'),
  RFeat('🫁', 0xFF2FE6F3, 'ئۆکسجین و سترێس', 'SpO₂ و ئاستی سترێس بە درێژایی ڕۆژ'),
  RFeat('👨‍👩‍👧', 0xFFFF8FC8, 'بازنەی خێزان', 'ئاگاداری تەندروستی دایک و باوک و ئازیزانت بە'),
  RFeat('🏆', 0xFF3CF08A, 'VEX Arena', 'پێشبڕکێ لەگەڵ هاوڕێکانت و خەڵات ببەوە'),
];

// ---------- ناوچەکانی BMI بۆ پێوەری ئامانج ----------
class RZone {
  const RZone(this.lo, this.hi, this.label, this.color, this.deg, this.text);
  final double lo;
  final double hi;
  final String label;
  final Color color;
  final double deg;
  final String text;
}

const List<RZone> kZones = [
  RZone(0, 17.5, 'خراپ', Color(0xFFFF5F7E), 22, '⚠️ خراپ · زۆر کەمە'),
  RZone(17.5, 18.5, 'کەم', Color(0xFF6AA8FF), 24, 'کەم · کەمتر لە تەندروست'),
  RZone(18.5, 25, 'باش', Color(0xFF3CF08A), 56, '✓ باش · تەندروست'),
  RZone(25, 30, 'ناوەند', Color(0xFFFFBE4D), 34, 'ناوەند · کەمێک زیاتر'),
  RZone(30, 35, 'زۆر', Color(0xFFFF9466), 24, 'زۆر · قەڵەوی'),
  RZone(35, 99, 'خراپ', Color(0xFFFF5F7E), 20, '⚠️ خراپ · قەڵەوی زۆر'),
];

int zoneIdx(double b) {
  for (int i = 0; i < kZones.length; i++) {
    if (b < kZones[i].hi) return i;
  }
  return kZones.length - 1;
}

/// گۆشەی BMI لەسەر نیوەبازنەکە (0 = چەپ، 180 = ڕاست)
double bmiAngle(double b) {
  double a0 = 0;
  for (int i = 0; i < kZones.length; i++) {
    final z = kZones[i];
    final lo = i == 0 ? 14.0 : z.lo;
    final hi = i == kZones.length - 1 ? 42.0 : z.hi;
    if (b < hi || i == kZones.length - 1) {
      final t = ((b - lo) / (hi - lo)).clamp(0.0, 1.0);
      return a0 + t * z.deg;
    }
    a0 += z.deg;
  }
  return 180;
}

class BmiCat {
  const BmiCat(this.label, this.color, this.text);
  final String label;
  final Color color;
  final String text;
}

BmiCat bmiCat(double b) {
  if (b < 18.5) {
    return const BmiCat('کەمتر لە ئاسایی', Color(0xFF6AA8FF),
        'کێشت کەمێک کەمترە لە ئاستی تەندروست. VEX یارمەتیت دەدات بە شێوەیەکی تەندروست زیادی بکەیت.');
  }
  if (b < 25) return const BmiCat('تەندروست', Color(0xFF3CF08A), 'کێشت لە ئاستی تەندروستدایە 👏 بەردەوام بە.');
  if (b < 30) {
    return const BmiCat(
        'کەمێک زیاتر', Color(0xFFFFBE4D), 'کەمێک لە ئاستی تەندروست زیاترە. هەنگاوی بچووک جیاوازی گەورە دروست دەکەن.');
  }
  return const BmiCat('زیاتر', Color(0xFFFF8A5F), 'پێکەوە هەنگاو بە هەنگاو بەرەو کێشێکی تەندروستتر دەڕۆین 💚');
}

// ---------- کات ----------
int toMin(String t) {
  final p = t.split(':');
  final h = int.tryParse(p.isNotEmpty ? p[0] : '') ?? 0;
  final m = int.tryParse(p.length > 1 ? p[1] : '') ?? 0;
  return h * 60 + m;
}

String toHM(int m) {
  final x = ((m % 1440) + 1440) % 1440;
  return '${(x ~/ 60).toString().padLeft(2, '0')}:${(x % 60).toString().padLeft(2, '0')}';
}

// ---------- Band ----------
class RegBand {
  bool? has;
  bool paired = false;
  String code = '';
  String wrist = 'left';

  Map<String, dynamic> toJson() => {'has': has, 'paired': paired, 'code': code, 'wrist': wrist};

  static RegBand fromJson(dynamic j) {
    final b = RegBand();
    if (j is Map) {
      final h = j['has'];
      b.has = h is bool ? h : null;
      b.paired = j['paired'] == true;
      b.code = '${j['code'] ?? ''}';
      b.wrist = j['wrist'] == 'right' ? 'right' : 'left';
    }
    return b;
  }
}

// ---------- ڕەشنووسی تۆمارکردن ----------
class RegDraft {
  String mode = 'new'; // new | login
  String name = '';
  String phone = '';
  String sex = '';
  int year = kThisYear - 30;
  int h = 0;
  double w = 0;
  bool hSet = false;
  bool wSet = false;
  String uh = 'cm';
  String uw = 'kg';
  String act = '';
  List<String> goals = [];
  RegBand band = RegBand();
  String bed = '23:00';
  String wake = '07:00';
  double tw = 0;
  bool twSet = false;
  List<String> conds = [];
  bool condsDone = false;
  Map<String, bool> notif = defaultNotif();
  bool built = false;

  static Map<String, bool> defaultNotif() => {'water': true, 'move': true, 'sleep': true, 'heart': true, 'fam': true};

  Map<String, dynamic> toJson() => {
        'mode': mode,
        'name': name,
        'phone': phone,
        'sex': sex,
        'year': year,
        'h': h,
        'w': w,
        'hSet': hSet,
        'wSet': wSet,
        'uh': uh,
        'uw': uw,
        'act': act,
        'goals': goals,
        'band': band.toJson(),
        'bed': bed,
        'wake': wake,
        'tw': tw,
        'twSet': twSet,
        'conds': conds,
        'condsDone': condsDone,
        'notif': notif,
        'built': built,
      };

  static RegDraft fromJson(Map j) {
    final d = RegDraft();
    d.mode = j['mode'] == 'login' ? 'login' : 'new';
    d.name = '${j['name'] ?? ''}';
    d.phone = cleanPhone('${j['phone'] ?? ''}');
    d.sex = j['sex'] == 'f' ? 'f' : (j['sex'] == 'm' ? 'm' : '');
    final y = asI(j['year'], kThisYear - 30);
    d.year = y.clamp(kThisYear - 95, kThisYear - 13);
    d.h = asI(j['h']);
    d.w = asD(j['w']);
    d.hSet = j['hSet'] == true;
    d.wSet = j['wSet'] == true;
    d.uh = j['uh'] == 'ft' ? 'ft' : 'cm';
    d.uw = j['uw'] == 'lb' ? 'lb' : 'kg';
    d.act = kActs.any((a) => a.k == j['act']) ? '${j['act']}' : '';
    d.goals = _strList(j['goals']).where((g) => kGoals.any((x) => x.k == g)).take(3).toList();
    d.band = RegBand.fromJson(j['band']);
    d.bed = _hm(j['bed'], '23:00');
    d.wake = _hm(j['wake'], '07:00');
    d.tw = asD(j['tw']);
    d.twSet = j['twSet'] == true;
    d.conds = _strList(j['conds']).where((c) => kConds.any((x) => x.k == c)).toList();
    d.condsDone = j['condsDone'] == true;
    final n = j['notif'];
    if (n is Map) {
      for (final k in d.notif.keys.toList()) {
        final v = n[k];
        if (v is bool) d.notif[k] = v;
      }
    }
    d.built = j['built'] == true;
    return d;
  }

  static List<String> _strList(dynamic v) => v is List ? v.map((e) => '$e').toList() : <String>[];
  static String _hm(dynamic v, String d) => RegExp(r'^\d{1,2}:\d{2}$').hasMatch('$v') ? toHM(toMin('$v')) : d;

  // ---------- حیسابەکان ----------
  int get age => kThisYear - year;
  double get bmi => h > 0 && w > 0 ? w / math.pow(h / 100, 2) : 0;

  int get sleepMin => (toMin(wake) - toMin(bed) + 1440) % 1440;

  List<int> get sleepRec {
    final a = age;
    if (a < 18) return [8, 10];
    if (a >= 65) return [7, 8];
    return [7, 9];
  }

  /// ماوەی کێشی تەندروست بۆ ئەم باڵایە (BMI 18.5 – 24.9)
  List<int> get healthyRange {
    final m = math.pow(h / 100, 2).toDouble();
    return [(18.5 * m).ceil(), (24.9 * m).floor()];
  }

  double defTarget() {
    final b = bmi;
    final r = healthyRange;
    double t = w;
    if (b >= 25) {
      t = math.max(r[1].toDouble(), w * 0.9);
    } else if (b < 18.5) {
      t = math.min(r[0] + 2.0, w * 1.08);
    }
    return (t * 2).round() / 2;
  }

  String get wGoal {
    final d = tw - w;
    if (d <= -0.5) return 'lose';
    if (d >= 0.5) return 'gain';
    return 'keep';
  }

  String kgTxt(double kg) => uw == 'lb' ? '${(kg * 2.20462).round()} lb' : '${numTxt(kg)} kg';

  RegPlan plan() {
    final a = age;
    int steps = const {'sed': 6000, 'light': 8000, 'active': 10000, 'very': 12000}[act] ?? 8000;
    if (goals.contains('move') || goals.contains('weight')) steps = math.min(12000, steps + 1000);
    if (a >= 65) steps = math.min(steps, 7000);
    int actMin = const {'sed': 20, 'light': 30, 'active': 40, 'very': 60}[act] ?? 30;
    if (a >= 65) actMin = math.min(actMin, 30);
    final liters = ((w * 0.033 * 4).round() / 4).clamp(1.5, 4.0);
    final sl = a < 18 ? 9.0 : (a >= 65 ? 7.5 : 8.0);
    return RegPlan(
      steps: steps,
      act: actMin,
      water: (liters * 1000).round(),
      glasses: (liters / 0.25).round(),
      sleep: sl,
      hrMax: 220 - a,
      bmi: double.parse(bmi.toStringAsFixed(1)),
    );
  }
}

class RegPlan {
  const RegPlan({
    required this.steps,
    required this.act,
    required this.water,
    required this.glasses,
    required this.sleep,
    required this.hrMax,
    required this.bmi,
  });
  final int steps;
  final int act;
  final int water;
  final int glasses;
  final double sleep;
  final int hrMax;
  final double bmi;
}

/// ئامانجی کالۆری ڕۆژانە لە زانیارییەکانی هەژمارەوە (Mifflin-St Jeor — هەمان بەشی خواردن)
int kcalGoalFor(Map u) {
  final w = asD(u['w']);
  final h = asD(u['h']);
  if (w <= 0 || h <= 0) return 0;
  int age = asI(u['age']);
  if (age <= 0) {
    final y = asI(u['year']);
    age = y > 0 ? kThisYear - y : 30;
  }
  final act = const {'sed': 1.2, 'light': 1.375, 'active': 1.55, 'very': 1.725}['${u['act']}'] ?? 1.375;
  final female = u['sex'] == 'f';
  final bmr = 10 * w + 6.25 * h - 5 * age + (female ? -161 : 5);
  double kcal = bmr * act;
  if (u['wgoal'] == 'lose') kcal -= 500;
  if (u['wgoal'] == 'gain') kcal += 300;
  kcal = math.max(kcal, female ? 1200.0 : 1500.0);
  return ((kcal / 10).round() * 10);
}
