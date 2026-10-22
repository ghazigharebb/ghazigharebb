// VEX Health — لیستی خواردنەکان (assets/data/foods.json) + گەڕان
//
// • 500 خواردن و خواردنەوە، بۆ هەر 100 گرام: کالۆری، پڕۆتین، کارب، چەوری، ڕیشاڵ، شەکر
// • یەکەکان (دانە، قاپ، پارچە، پەرداخ...) + گرام
// • وێنە (ئارەزوومەندانە): assets/foods/<id>.webp یان assets/foods/<ناوی کوردی>.jpg
//   — هەر وێنەیەک دابنێیت خۆی دەناسرێتەوە، پێویست بە گۆڕینی کۆد ناکات.
// • بۆ زیادکردن یان گۆڕینی خواردن: tools/foods_src.txt ← python3 tools/build_foods.py
import 'dart:convert';

import 'package:flutter/services.dart';

import '../core/vx_ar.dart' show arFood;
import '../core/vx_fa.dart' show faFood;
import '../core/vx_tr.dart' show trFood;
import '../core/vx_bd.dart' show bdFood;
import '../core/vx_en.dart';

class FoodUnit {
  const FoodUnit(this.name, this.g);
  final String name;
  final double g;

  bool get isGram => name == kGramUnit;
}

const String kGramUnit = 'گرام';

class FoodCat {
  const FoodCat(this.k, this.t, this.e);
  final String k;
  final String t;
  final String e;
}

class FoodEntry {
  FoodEntry({
    required this.id,
    required this.ku,
    required this.ar,
    required this.en,
    required this.al,
    required this.cat,
    required this.e,
    required this.kcal,
    required this.p,
    required this.c,
    required this.f,
    required this.fib,
    required this.sug,
    required this.units,
  });

  final String id;
  final String ku;
  final String ar;
  final String en;
  final List<String> al;
  final String cat;
  final String e;

  /// بۆ 100 گرام
  final double kcal, p, c, f, fib, sug;

  /// یەکەکان (یەکەم = ئاسایی)، دواین = گرام
  final List<FoodUnit> units;

  FoodUnit get unit0 => units.first;

  /// ناوی پیشاندان: English کاتێک زمان ئینگلیزی بێت، ئەگەرنا کوردی
  String get label => kIsEn && en.trim().isNotEmpty ? en.trim() : (kIsBd ? bdFood(ku) : (kIsAr ? arFood(ku) : (kIsFa ? faFood(ku) : (kIsTr ? trFood(ku) : ku))));

  /// کلیلەکانی گەڕان (ئاسایی کراو)
  late final List<String> keys = _buildKeys();

  List<String> _buildKeys() {
    final raw = <String>[];
    void add(String x) {
      raw.add(x);
      // «برنج (پڵاو)» ← «برنج» و «پڵاو»
      final i = x.indexOf('(');
      if (i > 0) {
        raw.add(x.substring(0, i));
        final j = x.indexOf(')', i);
        final inner = j > i ? x.substring(i + 1, j).trim() : '';
        if (inner.length >= 3 && !RegExp(r'^(بێ|بە|لە|\d)').hasMatch(inner) && !_genericInner.contains(inner)) {
          raw.add(inner);
        }
      }
    }

    for (final x in [ku, ...al, ...ar.split('/'), en]) {
      add(x);
    }
    final out = <String>[];
    for (final r in raw) {
      final n = normFood(r);
      if (n.length >= 2 && !out.contains(n)) out.add(n);
    }
    return out;
  }

  double gramsOf(FoodUnit u, double n) => u.g * n;
  double kcalOf(FoodUnit u, double n) => kcal * u.g * n / 100;
  double pOf(FoodUnit u, double n) => p * u.g * n / 100;
  double cOf(FoodUnit u, double n) => c * u.g * n / 100;
  double fOf(FoodUnit u, double n) => f * u.g * n / 100;
  double fibOf(FoodUnit u, double n) => fib * u.g * n / 100;
  double sugOf(FoodUnit u, double n) => sug * u.g * n / 100;

  /// هەڵسەنگاندنی سادە بۆ نیشانەی ژەم (good / ok / bad)
  String verdictFor(double kcalTotal) {
    final d = kcal; // چڕی کالۆری
    if (cat == 'sweets' || cat == 'extras') return kcalTotal > 150 ? 'bad' : 'ok';
    if (sug >= 20 && cat != 'fruit' && cat != 'dates') return 'bad';
    if (cat == 'fast' && kcalTotal > 450) return 'bad';
    if (cat == 'veg' || cat == 'fruit' || cat == 'salad' || cat == 'soup') return d > 250 ? 'ok' : 'good';
    if (p * 4 >= kcal * 0.25 && kcalTotal < 500) return 'good';
    if (fib >= 4 && kcalTotal < 600) return 'good';
    return kcalTotal > 800 ? 'bad' : 'ok';
  }

  static FoodEntry? fromJson(dynamic j) {
    if (j is! Map) return null;
    final n = j['n'];
    if (n is! List || n.length < 6) return null;
    double d(int i) => n[i] is num ? (n[i] as num).toDouble() : 0;
    final us = <FoodUnit>[];
    final u = j['u'];
    if (u is List) {
      for (final x in u) {
        if (x is List && x.length >= 2 && x[1] is num && (x[1] as num) > 0) {
          us.add(FoodUnit('${x[0]}', (x[1] as num).toDouble()));
        }
      }
    }
    us.add(const FoodUnit(kGramUnit, 1));
    final id = '${j['id'] ?? ''}';
    final ku = '${j['ku'] ?? ''}';
    if (id.isEmpty || ku.isEmpty) return null;
    return FoodEntry(
      id: id,
      ku: ku,
      ar: '${j['ar'] ?? ''}',
      en: '${j['en'] ?? ''}',
      al: j['al'] is List ? (j['al'] as List).map((x) => '$x').toList() : const <String>[],
      cat: '${j['c'] ?? ''}',
      e: '${j['e'] ?? '🍽️'}',
      kcal: d(0),
      p: d(1),
      c: d(2),
      f: d(3),
      fib: d(4),
      sug: d(5),
      units: us,
    );
  }
}

const Set<String> _genericInner = {'تێکەڵ', 'خورما', 'قاپ', 'لەفە', 'mixed', 'cooked', 'dry', 'no meat', 'lamb', 'water'};

class FoodHit {
  const FoodHit(this.food, this.score);
  final FoodEntry food;
  final int score;
}

class FoodDb {
  FoodDb._();
  static final FoodDb I = FoodDb._();

  List<FoodEntry> foods = const [];
  List<FoodCat> cats = const [];
  final Map<String, FoodEntry> _byId = {};
  final Map<String, String> _img = {}; // id ← asset
  bool loaded = false;

  FoodEntry? byId(String id) => _byId[id];
  String? imageOf(FoodEntry f) => _img[f.id];
  int get imageCount => _img.length;

  FoodCat? catOf(String k) {
    for (final c in cats) {
      if (c.k == k) return c;
    }
    return null;
  }

  Future<void> load() async {
    try {
      final raw = await rootBundle.loadString('assets/data/foods.json');
      final j = jsonDecode(raw);
      if (j is Map) {
        final cs = <FoodCat>[];
        if (j['cats'] is List) {
          for (final c in j['cats'] as List) {
            if (c is Map) cs.add(FoodCat('${c['k']}', '${c['t']}', '${c['e']}'));
          }
        }
        final fs = <FoodEntry>[];
        if (j['foods'] is List) {
          for (final x in j['foods'] as List) {
            final f = FoodEntry.fromJson(x);
            if (f != null && !_byId.containsKey(f.id)) {
              fs.add(f);
              _byId[f.id] = f;
            }
          }
        }
        cats = cs;
        foods = fs;
        loaded = fs.isNotEmpty;
      }
    } catch (_) {
      // ئەگەر فایلەکە نەخوێنرایەوە، ئەپەکە بێ لیست بەردەوام دەبێت
    }
    await _loadImages();
  }

  /// وێنەکانی assets/foods/ دەدۆزێتەوە (بە id یان بە ناوی کوردی)
  Future<void> _loadImages() async {
    try {
      final m = await AssetManifest.loadFromAssetBundle(rootBundle);
      final byName = <String, FoodEntry>{};
      for (final f in foods) {
        byName.putIfAbsent(normFood(f.ku), () => f);
        for (final a in f.al) {
          byName.putIfAbsent(normFood(a), () => f);
        }
      }
      for (final a in m.listAssets()) {
        if (!a.startsWith('assets/foods/')) continue;
        final lower = a.toLowerCase();
        if (!(lower.endsWith('.webp') || lower.endsWith('.jpg') || lower.endsWith('.jpeg') || lower.endsWith('.png'))) {
          continue;
        }
        var name = a.substring('assets/foods/'.length);
        try {
          name = Uri.decodeFull(name);
        } catch (_) {}
        final dot = name.lastIndexOf('.');
        if (dot > 0) name = name.substring(0, dot);
        final f = _byId[name] ?? byName[normFood(name.replaceAll(RegExp(r'[_\-]+'), ' '))];
        if (f != null) _img.putIfAbsent(f.id, () => a);
      }
    } catch (_) {}
  }

  /// گەڕان: کوردی، عەرەبی، ئینگلیزی، ناوە جیاوازەکان، بە هەڵەی نووسینی کەمیشەوە
  List<FoodEntry> search(String query, {String? cat, int limit = 80}) {
    final q = normFood(query);
    final pool = cat == null ? foods : foods.where((f) => f.cat == cat);
    if (q.isEmpty) return pool.take(limit).toList();
    final hits = <FoodHit>[];
    for (final f in pool) {
      final s = _score(f, q);
      if (s > 0) hits.add(FoodHit(f, s));
    }
    if (hits.any((h) => h.score >= 40)) hits.removeWhere((h) => h.score < 30);
    hits.sort((a, b) {
      final d = b.score.compareTo(a.score);
      return d != 0 ? d : a.food.ku.length.compareTo(b.food.ku.length);
    });
    return hits.take(limit).map((h) => h.food).toList();
  }

  int _score(FoodEntry f, String q) {
    final qc = q.replaceAll(' ', '');
    final qw = q.split(' ').where((w) => w.isNotEmpty).toList();
    int best = 0;
    for (int i = 0; i < f.keys.length; i++) {
      final k = f.keys[i];
      final kc = k.replaceAll(' ', '');
      int s = 0;
      if (k == q || kc == qc) {
        s = 100;
      } else if (k.startsWith(q) || kc.startsWith(qc)) {
        s = 80;
      } else if (k.split(' ').any((w) => w.startsWith(q))) {
        s = 65;
      } else if (q.length >= 2 && kc.contains(qc)) {
        s = 45;
      } else if (qw.length > 1 && qw.every((w) => k.contains(w))) {
        s = 40;
      } else if (q.length >= 4 && k.split(' ').any((w) => _near(w, q))) {
        s = 22;
      }
      if (s > 0 && i == 0) s += 6; // ناوی سەرەکی
      if (s > best) best = s;
    }
    return best;
  }

  /// هەڵەی یەک پیت (یان پیتی زیادە/کەم)
  static bool _near(String w, String q) {
    for (final n in [q.length, q.length - 1, q.length + 1]) {
      if (n < 3 || n > w.length) continue;
      if (_lev(w.substring(0, n), q) <= 1) return true;
    }
    return false;
  }

  static int _lev(String a, String b) {
    if ((a.length - b.length).abs() > 1) return 2;
    final prev = List<int>.generate(b.length + 1, (i) => i);
    final cur = List<int>.filled(b.length + 1, 0);
    for (int i = 1; i <= a.length; i++) {
      cur[0] = i;
      int rowMin = cur[0];
      for (int j = 1; j <= b.length; j++) {
        final cost = a.codeUnitAt(i - 1) == b.codeUnitAt(j - 1) ? 0 : 1;
        final v = [prev[j] + 1, cur[j - 1] + 1, prev[j - 1] + cost].reduce((x, y) => x < y ? x : y);
        cur[j] = v;
        if (v < rowMin) rowMin = v;
      }
      if (rowMin > 1) return 2;
      for (int j = 0; j <= b.length; j++) {
        prev[j] = cur[j];
      }
    }
    return prev[b.length];
  }

  /// باشترین خواردن لە ناو دەقێکدا («2 قاپ برنج» ← برنج)
  FoodEntry? best(String text) {
    final t = normFood(text);
    if (t.isEmpty) return null;
    // ئەگەر دەقەکە سەرەتای ناوی خواردنێک بێت («شەربەتی پرتەقاڵ»)
    final top = search(text, limit: 1);
    if (top.isNotEmpty && _score(top.first, t) >= 80) return top.first;
    final tc = ' $t ';
    // «نانێک» ← نان، «قاپی» ← قاپ، «سێوەکە» ← سێو
    final ts = ' ${t.split(' ').map(_stem).join(' ')} ';
    FoodEntry? out;
    int len = 0;
    for (final f in foods) {
      for (final k in f.keys) {
        if (k.length <= len) continue;
        // وشەی تەواو، یان کلیلی درێژ لە ناو دەقدا
        if (tc.contains(' $k ') || ts.contains(' $k ') || (k.length >= 4 && t.contains(k))) {
          out = f;
          len = k.length;
        }
      }
    }
    if (out != null) return out;
    if (top.isNotEmpty && _score(top.first, t) >= 65) return top.first;
    return null;
  }

  static String _stem(String w) {
    if (w.length > 5 && w.endsWith('ەکان')) return w.substring(0, w.length - 4);
    if (w.length > 4 && w.endsWith('ەکە')) return w.substring(0, w.length - 3);
    if (w.length > 3 && w.endsWith('یک')) return w.substring(0, w.length - 2);
    if (w.length > 3 && w.endsWith('ی')) return w.substring(0, w.length - 1);
    return w;
  }

  /// یەکەی ناو دەق («2 قاپ برنج» ← قاپ؛ «200 گرام» ← گرام)
  FoodUnit unitIn(FoodEntry f, String text) {
    final t = ' ${normFood(text)} ';
    if (RegExp(r'\d\s*(g|gm|gr)\b').hasMatch(text.toLowerCase()) || t.contains(' ${normFood(kGramUnit)} ')) {
      return f.units.last;
    }
    for (final u in f.units) {
      final w = normFood(u.name.split(' ').first);
      if (w.length >= 2 && (t.contains(' $w ') || t.contains(' ${w}ی ') || t.contains(' ${w}یک '))) return u;
    }
    return f.unit0;
  }
}

/// ئاسایی کردنی دەق بۆ گەڕان: ي/ی، ك/ک، ە/ه/ة، ڕ/ر، ڵ/ل، ۆ/و، ژمارەی کوردی، پیتی دووبارە...
String normFood(String s) {
  final b = StringBuffer();
  int last = -1;
  void put(int c) {
    if (c == last && (c < 0x30 || c > 0x39)) return; // «شووتی» = «شوتی» (ژمارە نا)
    b.writeCharCode(c);
    last = c;
  }

  for (final r in s.toLowerCase().runes) {
    if (r >= 0x0660 && r <= 0x0669) {
      put(0x30 + r - 0x0660);
    } else if (r >= 0x06F0 && r <= 0x06F9) {
      put(0x30 + r - 0x06F0);
    } else if ((r >= 0x064B && r <= 0x065F) || r == 0x0670 || r == 0x0640 || r == 0x0621 || r == 0x0626 ||
        r == 0x200B || r == 0x200C || r == 0x200D || r == 0x200E || r == 0x200F || (r >= 0x2066 && r <= 0x2069)) {
      continue; // حەرەکە، ـ، ء، ئ، نیشانە نادیارەکان
    } else {
      switch (r) {
        case 0x064A: // ي
        case 0x0649: // ى
        case 0x06CC: // ی
        case 0x06CE: // ێ
          put(0x06CC);
          break;
        case 0x0643: // ك
        case 0x06A9: // ک
          put(0x06A9);
          break;
        case 0x0629: // ة
        case 0x0647: // ه
        case 0x06D5: // ە
        case 0x06BE: // ھ
        case 0x06C1: // ہ
          put(0x06D5);
          break;
        case 0x0623: // أ
        case 0x0625: // إ
        case 0x0622: // آ
        case 0x0671:
          put(0x0627);
          break;
        case 0x0624: // ؤ
        case 0x06C6: // ۆ
        case 0x06C7:
        case 0x06C9:
          put(0x0648);
          break;
        case 0x0695: // ڕ
          put(0x0631);
          break;
        case 0x06B5: // ڵ
          put(0x0644);
          break;
        case 0x06A4: // ڤ
          put(0x0641);
          break;
        case 0x0686: // چ
        case 0x0698: // ژ
        case 0x06AF: // گ
        case 0x067E: // پ
          put(r);
          break;
        default:
          final ch = String.fromCharCode(r);
          if (RegExp(r'[\s\-_/،,.()«»"]').hasMatch(ch)) {
            if (b.isNotEmpty && last != 0x20) put(0x20);
          } else {
            put(r);
          }
      }
    }
  }
  return b.toString().trim();
}
