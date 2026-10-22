// VEX Health — سکانی خواردن: داتا و حیسابەکان
//
// هەمان لۆجیکی وەشانی وێب: خواردنەکان، بڕ، کالۆری، خۆراک، تێبینی، ژەمی خۆکار.
import 'dart:convert';
import 'dart:math' as math;

import '../food/food_db.dart';

double _d(dynamic v, [double d = 0]) {
  if (v is num) return v.toDouble();
  final x = double.tryParse('$v');
  return x == null || x.isNaN || x.isInfinite ? d : x;
}

bool _has(dynamic v) => v != null && '$v'.isNotEmpty && double.tryParse('$v') != null;
double _pick(dynamic a, dynamic b) => _has(a) ? _d(a) : _d(b);

/// یەک خواردن یان خواردنەوە لە ژەمەکەدا. نرخەکان بۆ هەموو بڕی سەرەتایی (c0) ن.
class ScanItem {
  ScanItem({
    required this.name,
    this.inside = '',
    this.unit = 'بەش',
    this.c0 = 1,
    double? n,
    this.grams = 0,
    this.kcal = 0,
    this.p = 0,
    this.c = 0,
    this.f = 0,
    this.e = '',
  }) : n = n ?? c0;

  String name;
  String inside;
  String unit;
  double c0;
  double n;
  double grams;
  double kcal;
  double p;
  double c;
  double f;
  String e;

  double get q => c0 > 0 ? n / c0 : 0;

  ScanItem copy() => ScanItem(
      name: name, inside: inside, unit: unit, c0: c0, n: n, grams: grams, kcal: kcal, p: p, c: c, f: f, e: e);

  Map<String, dynamic> toJson() => {
        'name': name,
        'inside': inside,
        'unit': unit,
        'c0': c0,
        'n': n,
        'grams': grams,
        'kcal': kcal,
        'p': p,
        'c': c,
        'f': f,
        'e': e,
      };
}

class ScanTotals {
  const ScanTotals(this.k, this.g, this.p, this.c, this.f, this.q, this.act, this.fib, this.sug, this.sod);
  final double k;
  final double g;
  final double p;
  final double c;
  final double f;
  final double q;
  final int act;
  final double fib;
  final double sug;
  final double sod;
}

class ScanResult {
  ScanResult({
    required this.isFood,
    required this.name,
    this.emoji = '🍽️',
    this.confidence = 80,
    List<ScanItem>? items,
    this.fib = 0,
    this.sug = 0,
    this.sod = 0,
    this.dmin = 2,
    this.dmax = 3,
    this.score = 60,
    this.verdict = 'ok',
    this.summary = '',
    this.mealType = '',
    this.demo = false,
  }) : items = items ?? <ScanItem>[];

  bool isFood;
  String name;
  String emoji;
  int confidence;
  List<ScanItem> items;
  double fib;
  double sug;
  double sod;
  double dmin;
  double dmax;
  int score;
  String verdict;
  String summary;
  String mealType; // meal | snack | ''
  bool demo;

  // تێبینی
  String note = '';
  bool noteOk = false;
  List<ScanItem>? base; // نرخە سەرەتاییەکان پێش تێبینی (بۆ ئەوەی تێبینی دووبارە نەکرێتەوە)
  double? sug0;
  int? score0;

  ScanTotals get totals {
    double k = 0, g = 0, p = 0, c = 0, f = 0, k0 = 0;
    int act = 0;
    for (final it in items) {
      final q = it.q;
      k += it.kcal * q;
      g += it.grams * q;
      p += it.p * q;
      c += it.c * q;
      f += it.f * q;
      k0 += it.kcal;
      if (it.n > 0) act++;
    }
    final q = k0 > 0 ? k / k0 : (act > 0 ? 1.0 : 0.0);
    return ScanTotals(k, g, p, c, f, q, act, fib * q, sug * q, sod * q);
  }

  /// ئەنجامی AI (JSON) پاک دەکاتەوە و دەیکاتە ScanResult
  static ScanResult? fromJson(dynamic raw) {
    if (raw is String) {
      try {
        raw = jsonDecode(raw);
      } catch (_) {
        return null;
      }
    }
    if (raw is! Map) return null;
    final r = raw;
    if (r['is_food'] == false) return ScanResult(isFood: false, name: '${r['name'] ?? ''}');
    final items = <ScanItem>[];
    final list = r['items'];
    if (list is List) {
      for (final x in list.take(6)) {
        if (x is! Map) continue;
        final name = '${x['name'] ?? ''}'.trim();
        if (name.isEmpty) continue;
        final cnt = _pick(x['c0'], x['count']);
        final c0 = math.min(50.0, math.max(0.25, cnt == 0 ? 1.0 : cnt));
        items.add(ScanItem(
          name: name.length > 40 ? name.substring(0, 40) : name,
          inside: _cut('${x['inside'] ?? ''}', 80),
          unit: _cut('${x['unit'] ?? 'بەش'}', 14),
          c0: c0,
          n: _has(x['n']) ? _d(x['n']).clamp(0.0, 50.0) : c0,
          grams: math.max(0.0, _d(x['grams'])),
          kcal: math.max(0.0, _d(x['kcal'])),
          p: math.max(0.0, _pick(x['p'], x['protein_g'])),
          c: math.max(0.0, _pick(x['c'], x['carbs_g'])),
          f: math.max(0.0, _pick(x['f'], x['fat_g'])),
          e: '${x['e'] ?? ''}',
        ));
      }
    }
    if (items.isEmpty) {
      items.add(ScanItem(
        name: _cut('${r['name'] ?? 'خواردن'}', 40),
        kcal: _d(r['kcal']),
        p: _d(r['protein_g']),
        c: _d(r['carbs_g']),
        f: _d(r['fat_g']),
      ));
    }
    final fib = _pick(r['fib'], r['fiber_g']);
    final sug = _pick(r['sug'], r['sugar_g']);
    final sod = _pick(r['sod'], r['sodium_mg']);
    double a = _pick(r['dmin'], r['digest_h_min']);
    double b = _pick(r['dmax'], r['digest_h_max']);
    if (!(a > 0)) {
      final k0 = items.fold<double>(0, (s, i) => s + i.kcal);
      final pt = items.fold<double>(0, (s, i) => s + i.p);
      final ft = items.fold<double>(0, (s, i) => s + i.f);
      a = math.min(5.0, math.max(0.3, 0.4 + ft * 0.045 + pt * 0.02 + fib * 0.03 + k0 * 0.0012));
      b = a + (a < 1 ? 0.4 : 1);
    }
    if (!(b >= a)) b = a + (a < 1 ? 0.4 : 1);
    a = a.clamp(0.15, 10.0);
    b = b.clamp(a, 12.0);
    final sc = _d(r['score'], 60).round().clamp(0, 100);
    final v0 = '${r['verdict'] ?? ''}';
    final v = (v0 == 'good' || v0 == 'ok' || v0 == 'bad') ? v0 : (sc >= 70 ? 'good' : (sc >= 45 ? 'ok' : 'bad'));
    final mt = '${r['meal_type'] ?? ''}';
    return ScanResult(
      isFood: true,
      name: _cut('${r['name'] ?? 'خواردن'}', 60),
      emoji: _cut('${r['emoji'] ?? '🍽️'}', 4),
      confidence: _d(r['confidence'], 80).round().clamp(0, 99),
      items: items,
      fib: fib,
      sug: sug,
      sod: sod,
      dmin: a,
      dmax: b,
      score: sc,
      verdict: v,
      summary: '${r['summary'] ?? ''}',
      mealType: mt == 'snack' || mt == 'meal' ? mt : '',
      demo: r['demo'] == true,
    );
  }

  /// بۆ ناردن بۆ AI لە کاتی حیسابکردنەوە بە پێی تێبینی
  Map<String, dynamic> toPrevJson() {
    final t = totals;
    return {
      'name': name,
      'items': items.where((i) => i.n > 0).map((i) {
        final k = i.q;
        return {
          'name': i.name,
          'inside': i.inside,
          'count': i.n,
          'unit': i.unit,
          'grams': (i.grams * k).round(),
          'kcal': (i.kcal * k).round(),
          'protein_g': double.parse((i.p * k).toStringAsFixed(1)),
          'carbs_g': double.parse((i.c * k).toStringAsFixed(1)),
          'fat_g': double.parse((i.f * k).toStringAsFixed(1)),
        };
      }).toList(),
      'fiber_g': double.parse(t.fib.toStringAsFixed(1)),
      'sugar_g': double.parse(t.sug.toStringAsFixed(1)),
      'sodium_mg': t.sod.round(),
      'digest_h_min': dmin,
      'digest_h_max': dmax,
    };
  }

  /// ناوی ژەمەکە بۆ تۆمار: «پیتزا + کۆلا + سێو»
  String get mealName {
    final l = items.where((i) => i.n > 0).map((i) => i.name).toList();
    final s = l.length > 1 ? l.join(' + ') : name;
    return s.length > 70 ? '${s.substring(0, 68)}…' : s;
  }
}

String _cut(String s, int n) => s.length > n ? s.substring(0, n) : s;

// ---------- بڕ ----------
/// − / + : بۆ دانە (1، 2، 3...) یەک یەک، بۆ بڕی نیوە نیوە
double stepQ(ScanItem it, int d) {
  final one = it.c0 >= 1 && it.c0 % 1 == 0;
  double n = it.n;
  if (one) {
    if (d > 0) {
      n = n < 0.5 ? 0.5 : (n < 1 ? 1 : n.floorToDouble() + 1);
    } else {
      n = n > 1 ? n.ceilToDouble() - 1 : (n > 0.5 ? 0.5 : 0);
    }
  } else {
    n = d > 0 ? (n * 2 + 1e-9).floorToDouble() / 2 + 0.5 : (n * 2 - 1e-9).ceilToDouble() / 2 - 0.5;
  }
  return n.clamp(0.0, 50.0);
}

/// ژمارەی نووسراو (کوردی/ئینگلیزی، ½) دەخوێنێتەوە
double? parseQ(String s) {
  var t = s.replaceAllMapped(RegExp('[٠-٩]'), (m) => '${m[0]!.codeUnitAt(0) - 0x0660}');
  t = t.replaceAllMapped(RegExp('[۰-۹]'), (m) => '${m[0]!.codeUnitAt(0) - 0x06F0}');
  t = t.replaceAll(RegExp('[٫,،]'), '.').replaceAll('½', '.5').replaceAll('¼', '.25').replaceAll('¾', '.75');
  t = t.replaceAll(RegExp(r'[^\d.]'), '');
  final v = double.tryParse(t);
  if (v == null) return null;
  return ((v * 100).round() / 100).clamp(0.0, 50.0);
}

String nf(double n) {
  final r = (n * 100).round() / 100;
  return r % 1 == 0 ? r.toStringAsFixed(0) : '$r';
}

// ---------- کاتی ژەم ----------
const Map<String, String> kSlotName = {
  'b': 'نانی بەیانی',
  'l': 'نانی نیوەڕۆ',
  's': 'ژەمی سووک',
  'd': 'نانی ئێوارە',
  'n': 'خواردنی شەو',
};

String mealSlotNow() {
  final h = DateTime.now().hour;
  if (h >= 5 && h < 11) return 'b';
  if (h >= 11 && h < 16) return 'l';
  if (h >= 16 && h < 22) return 'd';
  return 'n';
}

/// ژەمی سووک بە پێی خواردنەکە، ئەگەرنا بە پێی کاتژمێر
String autoSlot(ScanResult r) {
  final k = r.totals.k;
  final snack = r.mealType == 'snack' || (r.mealType != 'meal' && k > 0 && k < 250);
  return snack ? 's' : mealSlotNow();
}

// ---------- نمرە بە پێی بڕ ----------
class LiveScore {
  const LiveScore(this.s, this.v);
  final int s;
  final String v;
}

LiveScore liveScore(ScanResult r, double budget, double eatenBefore) {
  final t = r.totals;
  final q = t.q;
  double s = r.score.toDouble();
  if (q > 1.001) {
    s -= math.min(40, (q - 1) * 14);
  } else if (q > 0 && q < 0.999) {
    s += math.min(10, (1 - q) * 10);
  }
  final after = budget - eatenBefore - t.k;
  if (after < 0) s -= math.min(20, -after / 40);
  final si = s.round().clamp(5, 98);
  final v = (q - 1).abs() < 0.001 && after >= 0 ? r.verdict : (si >= 70 ? 'good' : (si >= 45 ? 'ok' : 'bad'));
  return LiveScore(si, v);
}

// ---------- پێکهاتەکان (ئیمۆجی) ----------
final List<MapEntry<RegExp, String>> _ing = [
  MapEntry(RegExp('پیتزا|\\b(?:pizza)(?:s|es)?\\b', caseSensitive: false), '🍕'),
  MapEntry(RegExp('کۆلا|پیپسی|سۆدا|\\b(?:cola|pepsi|soda|coke)(?:s|es)?\\b', caseSensitive: false), '🥤'),
  MapEntry(RegExp('شەربەت|عەسیر|\\b(?:juice|sherbet)(?:s|es)?\\b', caseSensitive: false), '🧃'),
  MapEntry(RegExp('بەرگر|همبرگر|\\b(?:burger|hamburger)(?:s|es)?\\b', caseSensitive: false), '🍔'),
  MapEntry(RegExp('شاورمە|لەفە|\\b(?:shawarma|wrap)(?:s|es)?\\b', caseSensitive: false), '🌯'),
  MapEntry(RegExp('دۆڵمە|یاپراخ|\\b(?:dolma|stuffed)(?:s|es)?\\b', caseSensitive: false), '🫑'),
  MapEntry(RegExp('پەنیر|\\b(?:cheese)(?:s|es)?\\b', caseSensitive: false), '🧀'),
  MapEntry(RegExp('هەویر|ئارد|\\b(?:dough|flour|pastry)(?:s|es)?\\b', caseSensitive: false), '🫓'),
  MapEntry(RegExp('تەماتە|\\b(?:tomato)(?:s|es)?\\b', caseSensitive: false), '🍅'),
  MapEntry(RegExp('پیپەرۆنی|سۆسیج|سجق|سوجوق|\\b(?:pepperoni|sausage|sujuk)(?:s|es)?\\b', caseSensitive: false), '🌭'),
  MapEntry(RegExp('گۆشت|کەباب|قیمە|\\b(?:meat|kebab|beef|lamb|mince|steak)(?:s|es)?\\b', caseSensitive: false), '🥩'),
  MapEntry(RegExp('مریشک|بالدار|\\b(?:chicken|poultry)(?:s|es)?\\b', caseSensitive: false), '🍗'),
  MapEntry(RegExp('ماسی|\\b(?:fish|salmon|tuna)(?:s|es)?\\b', caseSensitive: false), '🐟'),
  MapEntry(RegExp('برنج|\\b(?:rice)(?:s|es)?\\b', caseSensitive: false), '🍚'),
  MapEntry(RegExp('نان|سەمون|\\b(?:bread|toast|bun|loaf)(?:s|es)?\\b', caseSensitive: false), '🍞'),
  MapEntry(RegExp('هێلکە|\\b(?:egg)(?:s|es)?\\b', caseSensitive: false), '🥚'),
  MapEntry(RegExp('کاهو|زەڵاتە|سەوزە|\\b(?:lettuce|salad|greens|vegetable)(?:s|es)?\\b', caseSensitive: false), '🥬'),
  MapEntry(RegExp('پیاز|\\b(?:onion)(?:s|es)?\\b', caseSensitive: false), '🧅'),
  MapEntry(RegExp('سیر|\\b(?:garlic)(?:s|es)?\\b', caseSensitive: false), '🧄'),
  MapEntry(RegExp('خەیار|\\b(?:cucumber)(?:s|es)?\\b', caseSensitive: false), '🥒'),
  MapEntry(RegExp('بیبەر|فلفل|\\b(?:pepper|capsicum)(?:s|es)?\\b', caseSensitive: false), '🫑'),
  MapEntry(RegExp('کارتۆل|پەتاتە|\\b(?:potato|fries|chips)(?:s|es)?\\b', caseSensitive: false), '🥔'),
  MapEntry(RegExp('فاسۆلیا|نیسک|نۆک|لۆبیا|\\b(?:bean|lentil|chickpea|pea)(?:s|es)?\\b', caseSensitive: false), '🫘'),
  MapEntry(RegExp('قارچک|کەڕوو|\\b(?:mushroom)(?:s|es)?\\b', caseSensitive: false), '🍄'),
  MapEntry(RegExp('زەیتوون|\\b(?:olive)(?:s|es)?\\b', caseSensitive: false), '🫒'),
  MapEntry(RegExp('زەیت|ڕۆن|\\b(?:oil)(?:s|es)?\\b', caseSensitive: false), '🫒'),
  MapEntry(RegExp('کەرە|\\b(?:butter)(?:s|es)?\\b', caseSensitive: false), '🧈'),
  MapEntry(RegExp('شیر|ماست|دۆ|\\b(?:milk|yogurt|yoghurt|ayran|doogh)(?:s|es)?\\b', caseSensitive: false), '🥛'),
  MapEntry(RegExp('شەکر|شیرینی|هەنگوین|\\b(?:sugar|sweet|honey|dessert)(?:s|es)?\\b', caseSensitive: false), '🍯'),
  MapEntry(RegExp('سێو|\\b(?:apple)(?:s|es)?\\b', caseSensitive: false), '🍎'),
  MapEntry(RegExp('مۆز|\\b(?:banana)(?:s|es)?\\b', caseSensitive: false), '🍌'),
  MapEntry(RegExp('پرتەقاڵ|\\b(?:orange)(?:s|es)?\\b', caseSensitive: false), '🍊'),
  MapEntry(RegExp('ترێ|\\b(?:grape)(?:s|es)?\\b', caseSensitive: false), '🍇'),
  MapEntry(RegExp('لیمۆ|\\b(?:lemon)(?:s|es)?\\b', caseSensitive: false), '🍋'),
  MapEntry(RegExp('گێزەر|\\b(?:carrot)(?:s|es)?\\b', caseSensitive: false), '🥕'),
  MapEntry(RegExp('باینجان|\\b(?:eggplant|aubergine)(?:s|es)?\\b', caseSensitive: false), '🍆'),
  MapEntry(RegExp('سۆس|کەچەپ|مایۆنیز|\\b(?:sauce|ketchup|mayo|mayonnaise)(?:s|es)?\\b', caseSensitive: false), '🥫'),
  MapEntry(RegExp('قاوە|\\b(?:coffee)(?:s|es)?\\b', caseSensitive: false), '☕'),
  MapEntry(RegExp('چا|\\b(?:tea)(?:s|es)?\\b', caseSensitive: false), '🍵'),
  MapEntry(RegExp('گوێز|بادەم|فستق|بندق|\\b(?:nut|walnut|almond|pistachio|hazelnut)(?:s|es)?\\b', caseSensitive: false), '🥜'),
];

String ingEmoji(String t) {
  for (final e in _ing) {
    if (e.key.hasMatch(t)) return e.value;
  }
  return '•';
}

class Anno {
  const Anno(this.t, this.e, [this.i]);
  final String t;
  final String e;
  final int? i; // ئەگەر خواردنێکی جیاواز بێت (بۆ نیشاندانی کالۆری)
}

/// ئەوەی لەسەر وێنەکە دەنووسرێت: پێکهاتەکانی یەک خواردن، یان ناوی هەر خواردنێک
List<Anno> annoList(ScanResult r) {
  if (r.items.length == 1) {
    final it = r.items.first;
    var l = it.inside.split(RegExp(r'[،,؛;]|\sو\s')).map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    final seen = <String>{};
    l = l.where(seen.add).take(6).toList();
    if (l.isEmpty) l = [it.name];
    return l.map((t) => Anno(t, ingEmoji(t))).toList();
  }
  final out = <Anno>[];
  for (int i = 0; i < r.items.length && i < 6; i++) {
    final it = r.items[i];
    final e = it.e.isNotEmpty ? it.e : (ingEmoji(it.name) != '•' ? ingEmoji(it.name) : ingEmoji(it.inside));
    out.add(Anno(it.name, e, i));
  }
  return out;
}

// ---------- زیادکردنی خێرا ----------
class AddOn {
  const AddOn(this.t, this.e, this.u, this.g, this.k, this.p, this.c, this.f,
      {this.sug = 0, this.fib = 0, this.bad = false, this.good = false, this.name = ''});
  final String t;

  /// ناوی تەواو لە لیستەکەدا (بۆ تۆمار)
  final String name;
  final String e;
  final String u;
  final double g;
  final double k;
  final double p;
  final double c;
  final double f;
  final double sug;
  final double fib;
  final bool bad;
  final bool good;
}

/// زیادکردنی خێرا: لە لیستی خواردنەکانەوە (assets/data/foods.json)
class _AddRef {
  const _AddRef(this.id, this.t, {this.bad = false, this.good = false});
  final String id;
  final String t;
  final bool bad;
  final bool good;
}

const List<_AddRef> _kAddRefs = [
  _AddRef('cola', 'کۆلا', bad: true),
  _AddRef('do', 'دۆ'),
  _AddRef('cha', 'چا'),
  _AddRef('zalata', 'زەڵاتە', good: true),
  _AddRef('nani_tanur', 'نان'),
  _AddRef('patata_sorkraw', 'پەتاتەی سوورکراو', bad: true),
  _AddRef('sharbat_prtaqal', 'شەربەتی پرتەقاڵ', bad: true),
  _AddRef('mast', 'ماست'),
  _AddRef('tirshi', 'ترشی'),
  _AddRef('aw', 'ئاو', good: true),
];

List<AddOn>? _addOnsCache;

/// دوگمەکانی «شتێکی ترت لەگەڵی خوارد؟» (یەکەی ئاسایی هەر خواردنێک)
List<AddOn> addOns() {
  final c = _addOnsCache;
  if (c != null && c.isNotEmpty) return c;
  final out = <AddOn>[];
  for (final r in _kAddRefs) {
    final f = FoodDb.I.byId(r.id);
    if (f == null) continue;
    final u = f.unit0;
    out.add(AddOn(r.t, f.e, u.name, u.g, f.kcalOf(u, 1), f.pOf(u, 1), f.cOf(u, 1), f.fOf(u, 1),
        sug: f.sugOf(u, 1), fib: f.fibOf(u, 1), bad: r.bad, good: r.good, name: f.label));
  }
  _addOnsCache = out;
  return out;
}

/// خواردنێک لە لیستەکەوە ← بڕگەیەکی سکان
ScanItem scanItemOf(FoodEntry f, FoodUnit unit, double n) {
  var u = unit;
  var cnt = n;
  // سکان بە یەکەی ئاسایی کار دەکات (نەک گرام)
  if (u.isGram) {
    u = f.unit0;
    cnt = math.max(0.25, ((n / u.g) * 4).round() / 4);
  }
  cnt = cnt.clamp(0.25, 50.0);
  return ScanItem(
    name: f.label,
    e: f.e,
    unit: u.name,
    c0: cnt,
    grams: f.gramsOf(u, cnt),
    kcal: f.kcalOf(u, cnt),
    p: f.pOf(u, cnt),
    c: f.cOf(u, cnt),
    f: f.fOf(u, cnt),
  );
}

// ---------- دوگمەکانی تێبینی (بە پێی خواردنەکە) ----------
List<String> noteChips(ScanResult r) {
  final t = '${r.items.map((i) => '${i.name} ${i.inside}').join(' ')} ${r.name}';
  final nm = r.items.map((i) => i.name).join(' ');
  final l = <String>['ڕۆنی کەم', 'بێ ڕۆن'];
  if (t.contains('پەنیر')) l.addAll(['پەنیری کەم', 'بێ پەنیر']);
  if (t.contains('هێلکە')) l.add('بێ هێلکە');
  if (RegExp(r'(^|\s)نان').hasMatch(nm)) l.add('بێ نان');
  if (RegExp('سۆس|کەچەپ|مایۆنیز').hasMatch(t)) l.add('بێ سۆس');
  final m = RegExp('پیپەرۆنی|سۆسیج|بیکن|گۆشت|مریشک').firstMatch(t);
  if (m != null && l.length < 7) l.add('بێ ${m[0]}');
  if ((r.sug > 12 || RegExp('شەکر|چا|قاوە|شیرین|شەربەت|کێک').hasMatch(t)) && l.length < 7) l.add('بێ شەکر');
  return l.take(6).toList();
}

/// تێبینی بێ AI جێبەجێ دەکات (ڕۆن، پەنیر، هێلکە، نان، شەکر، سۆس، ژمارە، نیوە)
bool applyLocalNote(ScanResult r, String note) {
  var t = note.replaceAllMapped(RegExp('[٠-٩]'), (m) => '${m[0]!.codeUnitAt(0) - 0x0660}');
  t = t.replaceAllMapped(RegExp('[۰-۹]'), (m) => '${m[0]!.codeUnitAt(0) - 0x06F0}');
  t = t.replaceAll('ي', 'ی').replaceAll('ك', 'ک');
  final base = r.base ?? r.items.map((i) => i.copy()).toList();
  final sug0 = r.sug0 ?? r.sug;
  final score0 = r.score0 ?? r.score;
  final items = <ScanItem>[];
  for (int i = 0; i < r.items.length; i++) {
    final b = i < base.length ? base[i] : r.items[i];
    final it = r.items[i].copy();
    it.kcal = b.kcal;
    it.p = b.p;
    it.c = b.c;
    it.f = b.f;
    it.grams = b.grams;
    items.add(it);
  }
  int hit = 0;
  bool cnt = false;
  double sug = sug0;
  bool has(String re) => RegExp(re).hasMatch(t);
  String txt(ScanItem it) => '${it.name} ${it.inside}';
  void adj(ScanItem it, double df, [double dp = 0, double dc = 0]) {
    df = math.min(it.f, df);
    dp = math.min(it.p, dp);
    dc = math.min(it.c, dc);
    it.f -= df;
    it.p -= dp;
    it.c -= dc;
    it.kcal = math.max(0.0, it.kcal - 9 * df - 4 * dp - 4 * dc);
    it.grams = math.max(0.0, it.grams - (df + dp + dc) * 0.9);
  }

  if (has(r'بێ\s*ڕۆن|ڕۆن\S*\s*(تێ\s*)?نەکرد')) {
    for (final it in items) {
      adj(it, it.f * 0.45);
    }
    hit++;
  } else if (has(r'ڕۆن\S*\s*کەم|کەم\s*ڕۆن')) {
    for (final it in items) {
      adj(it, it.f * 0.25);
    }
    hit++;
  }
  if (has(r'بێ\s*پەنیر|پەنیر\S*\s*(تێ\s*)?نەکرد|پەنیری?\s*نەبوو')) {
    for (final it in items.where((i) => txt(i).contains('پەنیر'))) {
      adj(it, it.f * 0.38, it.p * 0.25);
    }
    hit++;
  } else if (has(r'پەنیر\S*\s*کەم|کەم\s*پەنیر')) {
    for (final it in items.where((i) => txt(i).contains('پەنیر'))) {
      adj(it, it.f * 0.19, it.p * 0.12);
    }
    hit++;
  }
  if (has(r'بێ\s*هێلکە|هێلکە\S*\s*(تێ\s*)?نەکرد')) {
    for (final it in items) {
      if (it.name.contains('هێلکە')) {
        it.n = 0;
      } else if (it.inside.contains('هێلکە')) {
        adj(it, it.f * 0.12, it.p * 0.2);
      }
    }
    hit++;
  }
  if (has(r'بێ\s*نان|نان\S*\s*نەخوارد')) {
    for (final it in items) {
      if (RegExp(r'(^|\s)نان').hasMatch(it.name)) it.n = 0;
    }
    hit++;
  }
  if (has(r'بێ\s*سۆس|سۆس\S*\s*کەم')) {
    for (final it in items.where((i) => RegExp('سۆس|کەچەپ|مایۆنیز').hasMatch(txt(i)))) {
      adj(it, it.f * 0.05, 0, it.c * 0.07);
    }
    sug *= 0.75;
    hit++;
  }
  final mm = RegExp(r'بێ\s*(پیپەرۆنی|سۆسیج|بیکن|گۆشت|مریشک)').firstMatch(t);
  if (mm != null) {
    for (final it in items.where((i) => txt(i).contains(mm[1]!))) {
      adj(it, it.f * 0.3, it.p * 0.3);
    }
    hit++;
  }
  if (has(r'بێ\s*شەکر|شەکر\S*\s*(تێ\s*)?نەکرد')) {
    final ds = sug * 0.85;
    sug -= ds;
    if (items.isNotEmpty) {
      final big = items.reduce((a, b) => b.c > a.c ? b : a);
      adj(big, 0, 0, ds);
    }
    hit++;
  }
  final cm = RegExp(r'(\d+(?:\.\d+)?)\s*(پارچە|دانە|قاپ|کاسە|پەرداخ|کەوچک|سیخ|لەفە|قوتوو|بەش)').firstMatch(t);
  if (cm != null) {
    ScanItem? it;
    for (final x in items) {
      if (x.unit == cm[2]) {
        it = x;
        break;
      }
    }
    if (it == null && items.length == 1) it = items.first;
    if (it != null) {
      it.n = (double.tryParse(cm[1]!) ?? it.n).clamp(0.0, 50.0);
      cnt = true;
      hit++;
    }
  }
  if (!cnt && has(r'نیوە\S*\s*(م\s*)?خوارد|نیوەیم|نیوەم')) {
    for (final it in items) {
      it.n = (it.n * 50).round() / 100;
    }
    hit++;
  }
  if (hit == 0) return false;
  r.items = items;
  r.sug = sug;
  r.base = base;
  r.sug0 = sug0;
  r.score0 = score0;
  r.note = note;
  r.noteOk = true;
  r.score = math.min(96, score0 + (hit > (cnt ? 1 : 0) ? 5 : 0));
  return true;
}

// ---------- دەق ----------
String durTxt(double m) {
  final mm = math.max(1, m.round());
  final h = mm ~/ 60, r = mm % 60;
  return h > 0 ? '$h کاتژمێر${r > 0 ? ' و $r خولەک' : ''}' : '$r خولەک';
}

String digTxt(double a, double b) {
  String one(double x) => x < 1 ? '${math.max(5, (x * 12).round() * 5)}' : nf((x * 2).round() / 2);
  final ua = a < 1 ? 'خولەک' : 'کاتژمێر', ub = b < 1 ? 'خولەک' : 'کاتژمێر';
  final sa = one(a), sb = one(b);
  if (ua == ub) return sa == sb ? '$sb $ub' : '$sa–$sb $ub';
  return '$sa $ua – $sb $ub';
}

String clockAfter(double hours) {
  var d = DateTime.now().add(Duration(minutes: (hours * 60).round()));
  final m = (d.minute / 5).round() * 5;
  d = DateTime(d.year, d.month, d.day, d.hour).add(Duration(minutes: m));
  return '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
}

/// نموونە (کاتێک AI هێشتا نەبەستراوەتەوە)
Map<String, dynamic> demoPizza() => {
      'is_food': true,
      'demo': true,
      'name': 'پیتزای پیپەرۆنی',
      'emoji': '🍕',
      'confidence': 93,
      'items': [
        {
          'name': 'پیتزای پیپەرۆنی',
          'inside': 'هەویر، پەنیری مۆتزارێلا، پیپەرۆنی، سۆسی تەماتە',
          'count': 2,
          'unit': 'پارچە',
          'grams': 230,
          'kcal': 600,
          'protein_g': 26,
          'carbs_g': 62,
          'fat_g': 27,
        }
      ],
      'fiber_g': 3,
      'sugar_g': 6,
      'sodium_mg': 1380,
      'digest_h_min': 3,
      'digest_h_max': 4,
      'meal_type': 'meal',
      'score': 52,
      'verdict': 'ok',
      'summary': 'پڕۆتینی باشی هەیە، تەنها خوێ و چەورییەکەی کەمێک زۆرە.',
    };
