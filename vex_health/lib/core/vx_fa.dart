// VEX Health — فارسی (Persian)
// ----------------------------------------------------------------------------
// کاتێک زمانی ئەپ 'fa' بێت، هەموو دەقە سۆرانییەکان لە کاتی پیشاندانەوە دەگۆڕدرێن
// بۆ فارسی. ژمارەکان فارسی (۰-۹) ن. فەرهەنگ لە lib/lang/lang_fa_persian.dart دایە (خۆکار دروست کراوە).
import '../lang/lang_fa_persian.dart';
import '../lang/lang_en_english.dart' show kEnStatic;

const String _faCls = 'ء-يٱ-ۓە۰-۹‌';
final RegExp _has = RegExp('[؀-ۿ‌]');
final RegExp _run = RegExp('[$_faCls]+(?: [$_faCls]+)*');
final RegExp _dayOrd = RegExp('([0-9۰-۹])ی(?![$_faCls])');
final RegExp _unitH = RegExp('([0-9۰-۹])ک(?![$_faCls])');
final RegExp _unitM = RegExp('([0-9۰-۹])خ(?![$_faCls])');
final RegExp _ph = RegExp(r'\{(\d+)\}');
// پیتی تایبەت بە سۆرانی (لە فارسیدا نین) — ئەگەر نەبێت دەقەکە پێشتر فارسییە و دووبارە وەرناگێڕدرێت
final RegExp _kl = RegExp('[ڕۆێڵەڤ]');
final RegExp _lat = RegExp(r'[A-Za-z][A-Za-z0-9\-]*');

class _FaTpl {
  _FaTpl(String key, this.out) {
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

final List<_FaTpl> _tpls = [for (final t in kFaTpl) _FaTpl(t[0], t[1])];
final Map<String, String> _cache = <String, String>{};

String _dg(String t) {
  t = t.replaceAllMapped(RegExp('[0-9]'), (m) => String.fromCharCode(0x6f0 + m[0]!.codeUnitAt(0) - 0x30));
  t = t.replaceAllMapped(RegExp('[٠-٩]'), (m) => String.fromCharCode(0x6f0 + m[0]!.codeUnitAt(0) - 0x660));
  t = t.replaceAllMapped(RegExp('(?<=[۰-۹]),(?=[۰-۹]{3})'), (m) => '٬');
  t = t.replaceAllMapped(RegExp(r'(?<=[۰-۹])\.(?=[۰-۹])'), (m) => '٫');
  return t.replaceAll('%', '٪');
}

// ژمارەکان بکە بە فارسی، بێجگە لە وشە لاتینییەکان (VX8-1234, B12, SpO₂ ...)
String _post(String r) {
  final out = StringBuffer();
  var p = 0;
  for (final m in _lat.allMatches(r)) {
    out.write(_dg(r.substring(p, m.start)));
    out.write(m[0]);
    p = m.end;
  }
  out.write(_dg(r.substring(p)));
  return out.toString();
}

String _seg(String m) {
  final e = kFaDict[m];
  if (e != null) return e;
  final f = kFaFood[m];
  if (f != null) return f;
  final w = m.split(' ');
  final n = w.length;
  if (n == 1) return m;
  final out = <String>[];
  var i = 0;
  while (i < n) {
    var hit = false;
    for (var j = n; j > i; j--) {
      final d = kFaDict[w.sublist(i, j).join(' ')];
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
  final f = kFaFood[s];
  if (f != null) return _post(f);
  final lit = kFaLit[s];
  if (lit != null) return _post(lit);
  if (!kEnStatic.contains(s)) {
    for (final t in _tpls) {
      final m = t.re.firstMatch(s);
      if (m != null) {
        final filled = t.out.replaceAllMapped(_ph, (x) => _conv(m.group(int.parse(x[1]!) + 1) ?? '', false));
        return _post(filled);
      }
    }
  }
  if (top && !_kl.hasMatch(s) && !kFaDict.containsKey(s) && !kEnStatic.contains(s)) return _post(s);
  var r = s.replaceAllMapped(_dayOrd, (m) => m[1]!);
  r = r.replaceAllMapped(_unitH, (m) => '${m[1]} ساعت');
  r = r.replaceAllMapped(_unitM, (m) => '${m[1]} دقیقه');
  r = r.replaceAllMapped(_run, (m) => _seg(m[0]!));
  return _post(r);
}

/// سۆرانی ← فارسی (بۆ هەر String ێک)
String faTr(String s) {
  if (s.isEmpty || !_has.hasMatch(s)) return s;
  final hit = _cache[s];
  if (hit != null) return hit;
  final out = _conv(s);
  if (_cache.length > 6000) _cache.clear();
  _cache[s] = out;
  return out;
}

/// ناوی خواردن بە فارسی
String faFood(String ku) => kFaFood[ku] ?? ku;
