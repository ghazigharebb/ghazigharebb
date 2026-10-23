// VEX Health — Türkçe (Turkish)
// ----------------------------------------------------------------------------
// کاتێک زمانی ئەپ 'tr' بێت، هەموو دەقە سۆرانییەکان لە کاتی پیشاندانەوە دەگۆڕدرێن
// بۆ تورکی (لاتینی، چەپ بۆ ڕاست). فەرهەنگ لە lib/lang/lang_tr_turkish.dart دایە (خۆکار دروست کراوە).
import '../lang/lang_tr_turkish.dart';
import '../lang/lang_en_english.dart' show kEnStatic;

const String _arCls = 'ء-يٱ-ۓە۰-۹‌';
final RegExp _has = RegExp('[؀-ۿ]');
final RegExp _run = RegExp('[$_arCls]+(?: [$_arCls]+)*');
final RegExp _dayOrd = RegExp('([0-9٠-٩۰-۹])ی(?![$_arCls])');
final RegExp _unitH = RegExp('([0-9٠-٩۰-۹])ک(?![$_arCls])');
final RegExp _unitM = RegExp('([0-9٠-٩۰-۹])خ(?![$_arCls])');
final RegExp _ph = RegExp(r'\{(\d+)\}');
final RegExp _letter = RegExp(r'\p{L}', unicode: true);
final RegExp _sent = RegExp(r'([.!?]\s+)([a-zçğıöşü])');
final RegExp _ecg = RegExp(r'\bECG\b');

class _TrTpl {
  _TrTpl(String key, this.out) {
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
}

final List<_TrTpl> _tpls = [for (final t in kTrTpl) _TrTpl(t[0], t[1])];
final Map<String, String> _cache = <String, String>{};

String _up(String c) {
  if (c == 'i') return 'İ';
  if (c == 'ı') return 'I';
  return c.toUpperCase();
}

// ژمارەی کوردی/عەرەبی ← 0-9 ، خاڵبەندی هەزاران: 1.800 ، نیشانەکان لاتینی
String _post(String r) {
  r = r.replaceAllMapped(RegExp('[٠-٩]'), (m) => String.fromCharCode(m[0]!.codeUnitAt(0) - 0x660 + 0x30));
  r = r.replaceAllMapped(RegExp('[۰-۹]'), (m) => String.fromCharCode(m[0]!.codeUnitAt(0) - 0x6f0 + 0x30));
  r = r.replaceAllMapped(RegExp(r'(?<=[0-9]),(?=[0-9]{3})'), (m) => '.');
  r = r
      .replaceAll('٪', '%')
      .replaceAll('٬', '.')
      .replaceAll('٫', ',')
      .replaceAll('،', ',')
      .replaceAll('؟', '?')
      .replaceAll('؛', ';');
  r = r.replaceAll(_ecg, 'EKG');
  r = r.replaceAllMapped(_sent, (m) => '${m[1]}${_up(m[2]!)}');
  return r;
}

// یەکەم پیتی دەق گەورە دەکات (تەنها ئەگەر بە بۆشایی دەست پێنەکات — ئەوانە پارچەی ڕستەن)
String _cap(String r) {
  if (r.isEmpty || r.trimLeft().length != r.length) return r;
  final it = r.runes.toList();
  for (var i = 0; i < it.length; i++) {
    final ch = String.fromCharCode(it[i]);
    if (_letter.hasMatch(ch)) {
      return String.fromCharCodes(it.sublist(0, i)) + _up(ch) + String.fromCharCodes(it.sublist(i + 1));
    }
    if (RegExp('[0-9]').hasMatch(ch)) return r;
  }
  return r;
}

String _seg(String m) {
  final e = kTrDict[m];
  if (e != null) return e;
  final f = kTrFood[m];
  if (f != null) return f;
  final w = m.split(' ');
  final n = w.length;
  if (n == 1) return m;
  final out = <String>[];
  var i = 0;
  while (i < n) {
    var hit = false;
    for (var j = n; j > i; j--) {
      final d = kTrDict[w.sublist(i, j).join(' ')];
      if (d != null) {
        out.add(d);
        i = j;
        hit = true;
        break;
      }
    }
    if (!hit) {
      out.add(w[i]);
      i++;
    }
  }
  return out.where((x) => x.isNotEmpty).join(' ');
}

String _conv(String s, [bool top = true]) {
  if (s.isEmpty || !_has.hasMatch(s)) return s.isEmpty ? s : _post(s);
  final f = kTrFood[s];
  if (f != null) return _post(f);
  final lit = kTrLit[s];
  if (lit != null) return _post(lit);
  if (!kEnStatic.contains(s)) {
    for (final t in _tpls) {
      final m = t.re.firstMatch(s);
      if (m != null) {
        final filled = t.out.replaceAllMapped(_ph, (x) => _conv(m.group(int.parse(x[1]!) + 1) ?? '', false));
        final res = _post(filled);
        return top ? _cap(res) : res;
      }
    }
  }
  var r = s.replaceAllMapped(_dayOrd, (m) => m[1]!);
  r = r.replaceAllMapped(_unitH, (m) => '${m[1]} sa');
  r = r.replaceAllMapped(_unitM, (m) => '${m[1]} dk');
  r = r.replaceAllMapped(_run, (m) => _seg(m[0]!));
  r = _post(r);
  return top ? _cap(r) : r;
}

/// سۆرانی ← تورکی (بۆ هەر String ێک)
String trTr(String s) {
  if (s.isEmpty || !_has.hasMatch(s)) return s;
  final hit = _cache[s];
  if (hit != null) return hit;
  final out = _conv(s);
  if (_cache.length > 6000) _cache.clear();
  _cache[s] = out;
  return out;
}

/// ناوی خواردن بە تورکی
String trFood(String ku) => kTrFood[ku] ?? ku;
