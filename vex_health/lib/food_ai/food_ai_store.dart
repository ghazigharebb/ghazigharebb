// VEX AI Food v2 — ناسینەوە (AI)، خەزنکردن و خواردنەکانی تۆ
//
// • AI ـی ڕاستەقینە: تەنها لە ڕێگەی سێرڤەرەکەتەوە (AiConfig.endpoint). کلیلی API هەرگیز لەناو ئەپدا نییە.
// • دۆخی نموونە (endpoint بەتاڵ): 10 خواردنی نموونە ڕێک دەناسرێنەوە؛ وێنەی ڕاستەقینە وەک «دڵنیا نییە» دێت
//   تا بەکارهێنەر خۆی دیاری بکات (هیچ ژمارەیەکی هەڵە بە بێدەنگی تۆمار ناکرێت).
// • تۆمارکردن: لۆگی ئەمڕۆ + کارتی ماڵەوە (Store) + vexfd_v1 (بۆ ڕاپۆرتی گشتی)
import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../core/store.dart';
import '../core/theme.dart' show nowHM;
import '../scan/scan_ai.dart' show AiConfig, FoodAI, ScanFail;
import 'food_ai_data.dart';

/// وێنەیەک بۆ شیکردنەوە: یان وێنەی ڕاستەقینە (bytes) یان وێنەی نموونە (sample = id ی خواردن)
class FShot {
  const FShot({this.bytes, this.sample});
  final Uint8List? bytes;
  final String? sample;
}

/// یەک خواردن لە ژەمەکەدا
class FItem {
  FItem({
    required this.dish,
    required String unit,
    required this.q,
    this.conf = 0.97,
    this.alts = const [],
    this.shot = -1,
    this.guess,
  }) : unit = dish.units.containsKey(unit) ? unit : dish.u0;

  FDish dish;
  String unit;
  double q;

  /// دڵنیایی AI (0-1)
  double conf;
  List<FDish> alts;

  /// ژمارەی وێنەکە (لە 0)
  int shot;

  /// ئەو ناوەی AI بە نادڵنیایی گوتی
  String? guess;

  /// ئامادەبوونی وێنەی PNG (0 ← 1)
  final ValueNotifier<double> png = ValueNotifier<double>(0);

  bool get sure => conf >= 0.8;
  FNut get nut => dish.nut(unit, q);
  String get word => qtyWord(q, unit);

  void setDish(FDish d) {
    dish = d;
    if (!d.units.containsKey(unit)) {
      unit = d.u0;
      q = d.q0;
    }
    conf = 0.99;
    guess = null;
  }

  /// + یان − بە پێی بڕە دیاریکراوەکانی یەکەکە
  bool step(int dir) {
    final s = unitOf(unit).steps;
    if (dir > 0) {
      final n = s.where((v) => v > q + 1e-6);
      if (n.isEmpty) return false;
      q = n.first;
    } else {
      final n = s.where((v) => v < q - 1e-6);
      if (n.isEmpty) return false;
      q = n.last;
    }
    return true;
  }
}

class FResult {
  const FResult(this.items, {this.demoReal = false});
  final List<FItem> items;

  /// وێنەی ڕاستەقینە لە دۆخی نموونەدا (AI نەبەستراوە)
  final bool demoReal;
}

/// ناسینەوەی خواردن
class FoodAiEngine {
  FoodAiEngine._();

  static bool get live => FoodAI.connected;

  static Future<FResult> analyse(List<FShot> shots) async {
    final real = shots.where((s) => s.bytes != null).toList();
    if (live && real.isNotEmpty) return _server(shots);
    return FResult(_demo(shots), demoReal: real.isNotEmpty);
  }

  static List<FItem> _demo(List<FShot> shots) {
    final out = <FItem>[];
    for (var i = 0; i < shots.length; i++) {
      final s = shots[i];
      final d = s.sample == null ? null : dishById(s.sample!);
      if (d != null) {
        if (d.id == 'doogh') {
          // نموونەی ڕاستکردنەوە: AI دۆ ـی بە شیر ناسی بەڵام دڵنیا نییە
          out.add(FItem(dish: dishById('milk')!, unit: 'kup', q: 1, conf: 0.58, shot: i, guess: 'شیر', alts: [d, dishById('milk')!, dishById('yogurt')!]));
        } else {
          out.add(FItem(dish: d, unit: d.u0, q: d.q0, conf: 0.97, shot: i));
        }
        continue;
      }
      // وێنەی ڕاستەقینە بێ AI: پێشنیار، بەڵام دەبێت بەکارهێنەر دڵنیای بکاتەوە
      final b = s.bytes ?? Uint8List(0);
      var h = b.length;
      for (var k = 0; k < b.length; k += 997) {
        h = (h * 31 + b[k]) & 0x7fffffff;
      }
      final a = kDishes[h % kDishes.length];
      final alts = <FDish>[a, kDishes[(h ~/ 7 + 3) % kDishes.length], kDishes[(h ~/ 13 + 6) % kDishes.length]];
      final uniq = <String, FDish>{for (final x in alts) x.id: x};
      out.add(FItem(dish: a, unit: a.u0, q: a.q0, conf: 0.45, shot: i, guess: a.name, alts: uniq.values.toList()));
    }
    return out;
  }

  static const String _prompt = 'You are VEX AI, an expert dietitian for a Kurdish health app. '
      'Look at the attached meal photos (up to 5, possibly of the same meal from different angles). '
      'List every separate food or drink exactly once across all photos (do not double count the same plate seen twice). '
      'Names in Central Kurdish (Sorani, Arabic script), short and common (e.g. برنج، کەباب، زەڵاتە، دۆڵمە، دۆ). '
      'unit = one of: qap (plate), kasa (bowl), kup (cup/glass), parcha (slice), shish (skewer), dana (piece), mlak (spoon), g, ml. '
      'qty = how many of that unit, as a half or whole number (0.5, 1, 1.5, 2...). units = grams (or ml) for one of each unit that makes sense for this food. '
      'per100 = [kcal, protein_g, carbs_g, fat_g, sugar_g, fiber_g, salt_g, cholesterol_mg] per 100 g. conf = 0-1. '
      'If conf < 0.8 add up to 3 alternatives with the same fields. shot = index of the photo it was seen in. '
      'png = true when the server will render a transparent PNG for a food that is not in the known list. '
      'Known ids (reuse when it matches): rice, kebab, salad, dolma, doogh, kunafa, tea, bread, hummus, kubba, milk, yogurt. '
      'Reply with ONLY JSON: {"items":[{"id":"rice|null","name":"…","ing":"…","unit":"qap","qty":1,"units":{"qap":250,"g":1},'
      '"per100":[170,3,28,5,0.1,0.4,0.5,0],"conf":0.95,"shot":0,"png":"https://… or null","alts":[]}]}';

  static Future<FResult> _server(List<FShot> shots) async {
    final imgs = <Map<String, dynamic>>[];
    for (final s in shots) {
      if (s.bytes != null) imgs.add({'media_type': 'image/jpeg', 'data': base64Encode(s.bytes!)});
    }
    final j = await _post({'task': 'food_scan_v2', 'prompt': _prompt, 'images': imgs});
    return FResult(parseItems(j));
  }

  /// شیکردنەوەی نووسین (لە سێرڤەر) — تەنها کاتێک AI بەستراوە
  static Future<List<FItem>> text(String t) async {
    final j = await _post({'task': 'food_text_v2', 'prompt': _prompt, 'text': t});
    return parseItems(j);
  }

  static Future<dynamic> _post(Map<String, dynamic> body) async {
    try {
      final res = await http
          .post(
            Uri.parse(AiConfig.endpoint.trim()),
            headers: {
              'content-type': 'application/json',
              if (AiConfig.appKey.isNotEmpty) 'x-app-key': AiConfig.appKey,
            },
            body: jsonEncode(body),
          )
          .timeout(AiConfig.timeout);
      if (res.statusCode == 429) throw ScanFail('rate_limited');
      if (res.statusCode >= 400) throw ScanFail('server');
      final j = FoodAI.extractJson(utf8.decode(res.bodyBytes));
      if (j == null) throw ScanFail('invalid_json');
      return j;
    } on ScanFail {
      rethrow;
    } on TimeoutException {
      throw ScanFail('timeout');
    } catch (_) {
      throw ScanFail('network');
    }
  }

  static double _d(Object? v) => v is num ? v.toDouble() : double.tryParse('$v') ?? 0;

  static FDish? _dish(Object? o) {
    if (o is! Map) return null;
    final known = o['id'] is String ? dishById(o['id'] as String) : null;
    final per = o['per100'];
    final u = o['units'];
    if (known != null && (per is! List || per.length < 8)) return known;
    if (per is! List || per.length < 8) return null;
    final units = <String, double>{};
    if (u is Map) {
      for (final e in u.entries) {
        if (kUnits.containsKey('${e.key}') && _d(e.value) > 0) units['${e.key}'] = _d(e.value);
      }
    }
    final unit = '${o['unit'] ?? ''}';
    if (units.isEmpty) units[kUnits.containsKey(unit) && !unitOf(unit).grams ? unit : 'g'] = kUnits.containsKey(unit) && !unitOf(unit).grams ? 200 : 1;
    if (!units.containsKey('g') && !units.containsKey('ml')) units['g'] = 1;
    final name = '${o['name'] ?? known?.name ?? ''}'.trim();
    if (name.isEmpty) return null;
    return FDish(
      id: known?.id ?? 'ai_${name.hashCode.toUnsigned(31)}',
      name: name,
      ing: '${o['ing'] ?? known?.ing ?? ''}',
      units: units,
      q0: _d(o['qty']) > 0 ? _d(o['qty']) : 1,
      k: _d(per[0]),
      p: _d(per[1]),
      c: _d(per[2]),
      f: _d(per[3]),
      sug: _d(per[4]),
      fib: _d(per[5]),
      salt: _d(per[6]),
      chol: _d(per[7]),
      img: known?.img,
      net: o['png'] is String && (o['png'] as String).startsWith('http') ? o['png'] as String : null,
    );
  }

  static List<FItem> parseItems(dynamic j) {
    final out = <FItem>[];
    final l = j is Map ? j['items'] : null;
    if (l is! List) throw ScanFail('invalid_json');
    for (final o in l.take(12)) {
      final d = _dish(o);
      if (d == null || o is! Map) continue;
      final alts = <FDish>[];
      if (o['alts'] is List) {
        for (final a in o['alts'] as List) {
          final x = _dish(a);
          if (x != null) alts.add(x);
        }
      }
      final conf = _d(o['conf']).clamp(0, 1).toDouble();
      final unit = '${o['unit'] ?? d.u0}';
      out.add(FItem(
        dish: d,
        unit: d.units.containsKey(unit) ? unit : d.u0,
        q: d.q0,
        conf: conf == 0 ? 0.9 : conf,
        shot: _d(o['shot']).round(),
        guess: conf < 0.8 ? d.name : null,
        alts: alts.isEmpty || alts.first.id == d.id ? alts : [d, ...alts],
      ));
    }
    return out;
  }

  /// نووسین بە بێ ئینتەرنێت: «2 شیش کەباب و قاپێک برنج و چا»
  static List<FItem> parseLocal(String text, List<FDish> mine) {
    final out = <FItem>[];
    final parts = text.split(RegExp(r'\s+و\s+|[،,؛\n+]'));
    for (final raw in parts) {
      var t = normKu(raw);
      if (t.isEmpty) continue;
      double? q;
      String? unit;
      final dm = RegExp(r'(\d+(?:[.,]\d+)?)').firstMatch(t);
      if (dm != null) {
        q = double.tryParse(dm.group(1)!.replaceAll(',', '.'));
        t = t.replaceFirst(dm.group(0)!, ' ').trim();
      }
      const words = {'نیو': 0.5, 'یەک': 1.0, 'دوو': 2.0, 'سێ': 3.0, 'چوار': 4.0, 'پێنج': 5.0, 'شەش': 6.0, 'حەوت': 7.0, 'هەشت': 8.0, 'نۆ': 9.0, 'دە': 10.0};
      final toks = t.split(' ');
      final keep = <String>[];
      for (final w in toks) {
        if (q == null && words.containsKey(w)) {
          q = words[w];
          continue;
        }
        String? hit;
        for (final u in kUnits.values) {
          if (w == u.word || w == '${u.word}ێک' || w == '${u.word}ی' || w == '${u.word}ە') hit = u.id;
        }
        if (hit != null && unit == null) {
          unit = hit;
          if (w.endsWith('ێک')) q ??= 1;
          continue;
        }
        keep.add(w);
      }
      final name = keep.join(' ').trim();
      if (name.isEmpty) continue;
      FDish? best;
      var bs = 0.0;
      for (final d in [...mine, ...kDishes, ...kAltDishes]) {
        final s = matchScore(d, name);
        if (s > bs) {
          bs = s;
          best = d;
        }
      }
      if (best == null || bs < 0.7) continue;
      final u = unit != null && best.units.containsKey(unit) ? unit : best.u0;
      out.add(FItem(dish: best, unit: u, q: q ?? (u == best.u0 ? best.q0 : 1), conf: 0.99));
    }
    return out;
  }
}

/// یەک تۆمار لە لۆگی ڕۆژانە
class FLog {
  FLog({required this.dish, required this.unit, required this.q, required this.slot, required this.at, required this.id});
  final FDish dish;
  final String unit;
  final double q;
  final String slot;
  final String at;
  final String id;
  FNut get nut => dish.nut(unit, q);

  Map<String, dynamic> toJson() => {'d': dish.toJson(), 'u': unit, 'q': q, 's': slot, 'at': at, 'id': id};
  static FLog? fromJson(Object? o) {
    if (o is! Map) return null;
    final d = FDish.fromJson(o['d']);
    if (d == null) return null;
    final known = dishById(d.id);
    return FLog(
      dish: known != null && known.name == d.name ? known : d,
      unit: '${o['u']}',
      q: o['q'] is num ? (o['q'] as num).toDouble() : 1,
      slot: '${o['s']}',
      at: '${o['at']}',
      id: '${o['id']}',
    );
  }
}

/// خەزنکردن: لۆگی ڕۆژانە (30 ڕۆژ) + خواردنەکانی تۆ
class FoodAiStore extends ChangeNotifier {
  FoodAiStore._();
  static final FoodAiStore I = FoodAiStore._();

  static const String key = 'vexai_food_v2';
  static const int keepDays = 30;

  final Map<String, List<FLog>> days = {};
  final List<FDish> mine = [];
  bool _ready = false;

  static String dayKey(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  static String get todayKey => dayKey(DateTime.now());

  List<FLog> get today => days[todayKey] ?? const [];

  FNut get todayNut => today.fold(FNut.zero, (a, x) => a + x.nut);

  Future<void> init() async {
    if (_ready) return;
    _ready = true;
    try {
      final sp = await SharedPreferences.getInstance();
      final raw = sp.getString(key);
      days.clear();
      mine.clear();
      if (raw != null) {
        final o = jsonDecode(raw);
        if (o is Map) {
          final dd = o['days'];
          if (dd is Map) {
            dd.forEach((k, v) {
              if (v is List) days['$k'] = v.map(FLog.fromJson).whereType<FLog>().toList();
            });
          }
          final m = o['mine'];
          if (m is List) mine.addAll(m.map(FDish.fromJson).whereType<FDish>());
        }
      }
      _prune();
    } catch (_) {}
    notifyListeners();
  }

  /// بۆ تاقیکردنەوە: دەستپێکردنەوە
  @visibleForTesting
  void reset() {
    _ready = false;
    days.clear();
    mine.clear();
  }

  void _prune() {
    final cut = dayKey(DateTime.now().subtract(const Duration(days: keepDays - 1)));
    days.removeWhere((k, v) => k.compareTo(cut) < 0 || v.isEmpty);
  }

  Future<void> _persist() async {
    try {
      final sp = await SharedPreferences.getInstance();
      await sp.setString(key, jsonEncode({
        'days': {for (final e in days.entries) e.key: [for (final x in e.value) x.toJson()]},
        'mine': [for (final d in mine) d.toJson()],
      }));
    } catch (_) {}
  }

  /// ژەمێک تۆمار دەکات (لۆگ + کارتی ماڵەوە + ڕاپۆرت)
  Future<void> saveMeal(List<FItem> items, String slot) async {
    if (items.isEmpty) return;
    final at = nowHM();
    final k = todayKey;
    final list = days.putIfAbsent(k, () => <FLog>[]);
    final base = DateTime.now().microsecondsSinceEpoch;
    for (var i = 0; i < items.length; i++) {
      final it = items[i];
      final id = '${base + i}';
      list.add(FLog(dish: it.dish, unit: it.unit, q: it.q, slot: slot, at: at, id: id));
      final n = it.nut;
      Store.I.addFood(FoodItem(n: it.dish.name, kcal: n.k.round(), p: n.p.round(), c: n.c.round(), f: n.f.round(), at: at, e: '🍽️', slot: slot, ref: 'ai2:$id'));
    }
    _prune();
    notifyListeners();
    await _persist();
    await _report(k);
  }

  Future<void> remove(FLog x) async {
    final l = days[todayKey];
    if (l == null || !l.remove(x)) return;
    Store.I.removeFoodWhere((f) => f.ref == 'ai2:${x.id}');
    notifyListeners();
    await _persist();
    await _report(todayKey);
  }

  bool isMine(String name) => mine.any((d) => d.name == name);

  /// «دۆڵمەی ماڵەوە» — بڕ و یەکەی خۆت پاشەکەوت دەبێت
  Future<FDish> saveMine(FItem it) async {
    final name = '${it.dish.name}ی ماڵەوە';
    mine.removeWhere((d) => d.name == name);
    final d = it.dish.copyWith(id: 'mine_${it.dish.id}', name: name, q0: it.q, units: {
      it.unit: it.dish.units[it.unit] ?? 1,
      for (final e in it.dish.units.entries)
        if (e.key != it.unit) e.key: e.value,
    });
    mine.insert(0, d);
    notifyListeners();
    await _persist();
    return d;
  }

  Future<void> removeMine(FDish d) async {
    mine.removeWhere((x) => x.name == d.name);
    notifyListeners();
    await _persist();
  }

  /// ڕاپۆرتی گشتی vexfd_v1 دەخوێنێتەوە: days[YYYY-MM-DD].m[slot] = [{n,kcal,p,c,f,fib,sug,salt}]
  Future<void> _report(String k) async {
    try {
      final sp = await SharedPreferences.getInstance();
      Map<String, dynamic> o = {};
      final raw = sp.getString('vexfd_v1');
      if (raw != null && raw.isNotEmpty) {
        final j = jsonDecode(raw);
        if (j is Map) o = Map<String, dynamic>.from(j);
      }
      final dd = o['days'] is Map ? Map<String, dynamic>.from(o['days'] as Map) : <String, dynamic>{};
      final day = dd[k] is Map ? Map<String, dynamic>.from(dd[k] as Map) : <String, dynamic>{};
      final m = day['m'] is Map ? Map<String, dynamic>.from(day['m'] as Map) : <String, dynamic>{};
      // تۆمارە کۆنەکانی ئەم بەشە لادەبرێن و ئەوانەی ئێستا دەنووسرێنەوە (بێ دووبارەبوونەوە)
      for (final s in m.keys.toList()) {
        final l = m[s] is List ? (m[s] as List).where((x) => !(x is Map && x['src'] == 'ai2')).toList() : <dynamic>[];
        m[s] = l;
      }
      for (final x in days[k] ?? const <FLog>[]) {
        final n = x.nut;
        final l = (m[x.slot] is List ? m[x.slot] as List : <dynamic>[]);
        l.add({
          'n': x.dish.name,
          'kcal': n.k.round(),
          'p': n.p.round(),
          'c': n.c.round(),
          'f': n.f.round(),
          'fib': double.parse(n.fib.toStringAsFixed(1)),
          'sug': double.parse(n.sug.toStringAsFixed(1)),
          'salt': double.parse(n.salt.toStringAsFixed(2)),
          'src': 'ai2',
        });
        m[x.slot] = l;
      }
      m.removeWhere((_, v) => v is List && v.isEmpty);
      day['m'] = m;
      if (day['water'] == null) day['water'] = Store.I.waterN;
      dd[k] = day;
      o['days'] = dd;
      await sp.setString('vexfd_v1', jsonEncode(o));
    } catch (_) {}
  }
}
