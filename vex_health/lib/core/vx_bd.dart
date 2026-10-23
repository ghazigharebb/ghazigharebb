// VEX Health — کوردی بادینی (Kurmanji بە پیتی عەرەبی)
// ----------------------------------------------------------------------------
// کاتێک زمانی ئەپ 'kmr' بێت، هەموو دەقە سۆرانییەکان لە کاتی پیشاندانەوە دەگۆڕدرێن
// بۆ بادینی. ئاراستە هەر ڕاست بۆ چەپە و فۆنتیش هەر ئەوەیە.
// فەرهەنگ لە lib/lang/lang_kmr_kurdish_badini.dart دایە (خۆکار دروست کراوە).
import 'package:flutter/foundation.dart';

import '../lang/lang_kmr_kurdish_badini.dart';
import '../lang/lang_en_english.dart' show kEnStatic;

const String _arCls = 'ء-يٱ-ۓە۰-۹‌';
final RegExp _has = RegExp('[؀-ۿ‌]');
final RegExp _run = RegExp('[$_arCls]+(?: [$_arCls]+)*');
final RegExp _dayOrd = RegExp('(\\d)ی(?![$_arCls])');
// «22ی تشرینی یەکەم» ← «22ێ تشرینا ئێکێ»
final RegExp _dayOrdMonth = RegExp('(\\d)ی(?= [$_arCls])');
final RegExp _ph = RegExp(r'\{(\d+)\}');

class _BdTpl {
  _BdTpl(String key, this.out) {
    final b = StringBuffer('^');
    var last = 0;
    for (final m in _ph.allMatches(key)) {
      b.write(RegExp.escape(key.substring(last, m.start)));
      b.write('(.*?)');
      last = m.end;
    }
    b.write(RegExp.escape(key.substring(last)));
    b.write(r'$');
    re = RegExp(b.toString(), dotAll: true);
  }
  late final RegExp re;
  final String out;

  String? apply(String s) {
    final m = re.firstMatch(s);
    if (m == null) return null;
    return out.replaceAllMapped(_ph, (x) => m.group(int.parse(x[1]!) + 1) ?? '');
  }
}

final List<_BdTpl> _tpls = [for (final t in kBdTpl) _BdTpl(t[0], t[1])];
final Map<String, String> _cache = <String, String>{};
final Set<String> _loggedMiss = <String>{};

String _seg(String m) {
  final e = kBdDict[m];
  if (e != null) return e;
  final w = m.split(' ');
  final n = w.length;
  if (n == 1) return kBdFood[m] ?? _word(m);
  final out = <String>[];
  var i = 0;
  while (i < n) {
    var hit = false;
    for (var j = n; j > i; j--) {
      final d = kBdDict[w.sublist(i, j).join(' ')];
      if (d != null) {
        out.add(d);
        i = j;
        hit = true;
        break;
      }
    }
    if (!hit) {
      out.add(_word(w[i]));
      i++;
    }
  }
  return out.where((x) => x.isNotEmpty).join(' ');
}

String _conv(String s) {
  final f = kBdFood[s];
  if (f != null) return f;
  final lit = kBdLit[s];
  if (lit != null) return lit;
  var r = s;
  if (!kEnStatic.contains(s)) {
    for (final t in _tpls) {
      final x = t.apply(r);
      if (x != null) {
        r = x;
        break;
      }
    }
  }
  r = r.replaceAllMapped(_dayOrdMonth, (m) => '${m[1]}ێ');
  r = r.replaceAllMapped(_dayOrd, (m) => m[1]!);
  return r.replaceAllMapped(_run, (m) => _seg(m[0]!));
}


// ---------------------------------------------------------------------------
// وشەی نەزانراو: فەرهەنگی وشە + یاسای ڕێزمانی بادینی
// ---------------------------------------------------------------------------
final Set<String> _missWords = <String>{};

/// پاشگرە سۆرانییەکان ← بادینی (لەسەر ڕەگی وشە)
const List<List<String>> _sfx = [
  ['ەکانی', 'ێن'],
  ['ەکان', ''],
  ['ەکەی', 'ێ'],
  ['ەکە', ''],
  ['یەکان', ''],
  ['یان', 'ان'],
  ['یەک', 'ەک'],
  ['ێک', 'ەک'],
  ['ی', 'ێ'],
];

String _word(String w) {
  final d = kBdWord[w];
  if (d != null) return d;
  // ڕەگ + پاشگر
  for (final r in _sfx) {
    if (w.length > r[0].length + 1 && w.endsWith(r[0])) {
      final stem = w.substring(0, w.length - r[0].length);
      final s = kBdWord[stem] ?? kBdFood[stem] ?? kBdDict[stem];
      if (s != null) return s + r[1];
    }
  }
  // یاسای گشتی
  var x = w;
  if (x.endsWith('کردنەوە')) {
    x = '${x.substring(0, x.length - 7)}کرنەڤە';
  } else if (x.endsWith('کردنی')) {
    x = '${x.substring(0, x.length - 5)}کرنا';
  } else if (x.endsWith('کردن')) {
    x = '${x.substring(0, x.length - 4)}کرن';
  } else if (x.endsWith('ەوە') && x.length > 5) {
    x = '${x.substring(0, x.length - 3)}ەڤە';
  }
  // فرمانی ئێستا: دەکات ← دکەت (ڕەگی نەزانراو: تەنها «دە» ← «د»)
  if (x.length > 5 && x.startsWith('دە') && (x.endsWith('ات') || x.endsWith('ێت') || x.endsWith('یت'))) {
    x = 'د${x.substring(2)}';
  }
  if (x == w && kDebugMode && RegExp('[ڕڵۆێە]').hasMatch(w)) _missWords.add(w);
  return x;
}

/// تەنها لە debug: وشە سۆرانییەکانی کە وەرنەگێڕدراون (بۆ تەواوکردنی فەرهەنگ)
List<String> bdMissingWords() => (_missWords.toList()..sort());

/// سۆرانی ← بادینی (بۆ هەر String ێک)
String bdTr(String s) {
  if (s.isEmpty || !_has.hasMatch(s)) return s;
  final hit = _cache[s];
  if (hit != null) return hit;
  final before = _missWords.length;
  final out = _conv(s);
  if (kDebugMode && (out == s || _missWords.length > before) && !_loggedMiss.contains(s) && _loggedMiss.length < 4000) {
    _loggedMiss.add(s);
    debugPrint('BD-MISSING: $s');
  }
  if (_cache.length > 6000) _cache.clear();
  _cache[s] = out;
  return out;
}

/// ناوی خواردن بە بادینی
String bdFood(String ku) => kBdFood[ku] ?? ku;
