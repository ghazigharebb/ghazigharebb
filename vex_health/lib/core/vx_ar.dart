// VEX Health — عەرەبی (فصحى مبسّطة)
// ----------------------------------------------------------------------------
// کاتێک زمانی ئەپ 'ar' بێت، هەموو دەقە سۆرانییەکان لە کاتی پیشاندانەوە دەگۆڕدرێن
// بۆ عەرەبی. ئاراستە هەر ڕاست بۆ چەپە. ژمارەکان ئەوروپی (0-9) ن.
// فەرهەنگ لە lib/lang/lang_ar_arabic.dart دایە (خۆکار دروست کراوە).
import '../lang/lang_ar_arabic.dart';
import '../lang/lang_en_english.dart' show kEnStatic;

const String _arCls = 'ء-يٱ-ۓە۰-۹‌';
final RegExp _has = RegExp('[؀-ۿ‌]');
final RegExp _run = RegExp('[$_arCls]+(?: [$_arCls]+)*');
final RegExp _dayOrd = RegExp('(\\d)ی(?![$_arCls])');
final RegExp _unitH = RegExp('(\\d)ک(?![$_arCls])');
final RegExp _unitM = RegExp('(\\d)خ(?![$_arCls])');
final RegExp _ph = RegExp(r'\{(\d+)\}');
// پیتی تایبەت بە کوردی — ئەگەر نەبێت دەقەکە پێشتر عەرەبییە و نابێت دووبارە وەربگێڕدرێت
final RegExp _kl = RegExp('[ڕۆێڵەکگپچژڤی۰-۹]');

class _ArTpl {
  _ArTpl(String key, this.out) {
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

final List<_ArTpl> _tpls = [for (final t in kArTpl) _ArTpl(t[0], t[1])];
final Map<String, String> _cache = <String, String>{};

// ژمارە + یەکە ← شێوەی دروستی عەرەبی (دقيقتان / 3 دقائق / 12 دقيقة)
class _Unit {
  _Unit(String forms, this.f) : rx = RegExp('(?<![\\d.:])(\\d[\\d,]*) ($forms)(?![ء-ي])');
  final RegExp rx;
  final List<String> f; // [مفرد، مثنى، جمع، تمييز]
}

final List<_Unit> _units = [
  _Unit('دقيقة|دقائق|دقيقتان', ['دقيقة', 'دقيقتان', 'دقائق', 'دقيقة']),
  _Unit('ساعة|ساعات|ساعتان', ['ساعة', 'ساعتان', 'ساعات', 'ساعة']),
  _Unit('ثانية|ثوانٍ|ثانيتان', ['ثانية', 'ثانيتان', 'ثوانٍ', 'ثانية']),
  _Unit('يوم|أيام|يومان', ['يوم', 'يومان', 'أيام', 'يوماً']),
  _Unit('أسبوع|أسابيع|أسبوعان', ['أسبوع', 'أسبوعان', 'أسابيع', 'أسبوعاً']),
  _Unit('شهر|أشهر|شهران', ['شهر', 'شهران', 'أشهر', 'شهراً']),
  _Unit('سنة|سنوات|سنتان', ['سنة', 'سنتان', 'سنوات', 'سنة']),
  _Unit('خطوة|خطوات', ['خطوة', 'خطوتان', 'خطوات', 'خطوة']),
  _Unit('كوب|أكواب', ['كوب', 'كوبان', 'أكواب', 'كوباً']),
];

String _numfix(String r) {
  for (final u in _units) {
    r = r.replaceAllMapped(u.rx, (m) {
      final n = int.tryParse(m[1]!.replaceAll(',', '')) ?? 0;
      if (n == 2) return u.f[1];
      if (n >= 3 && n <= 10) return '${m[1]} ${u.f[2]}';
      return '${m[1]} ${u.f[3]}';
    });
  }
  return r;
}

String _post(String r) {
  r = r.replaceAllMapped(RegExp('[٠-٩]'), (m) => '${m[0]!.codeUnitAt(0) - 0x660}');
  r = r.replaceAllMapped(RegExp('[۰-۹]'), (m) => '${m[0]!.codeUnitAt(0) - 0x6f0}');
  return r.replaceAll('٪', '%');
}

String _seg(String m) {
  final e = kArDict[m];
  if (e != null) return e;
  final f = kArFood[m];
  if (f != null) return f;
  final w = m.split(' ');
  final n = w.length;
  if (n == 1) return m;
  final out = <String>[];
  var i = 0;
  while (i < n) {
    var hit = false;
    for (var j = n; j > i; j--) {
      final d = kArDict[w.sublist(i, j).join(' ')];
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
  final f = kArFood[s];
  if (f != null) return _post(f);
  final lit = kArLit[s];
  if (lit != null) return _post(lit);
  if (!kEnStatic.contains(s)) {
    for (final t in _tpls) {
      final m = t.re.firstMatch(s);
      if (m != null) {
        final filled = t.out.replaceAllMapped(_ph, (x) => _conv(m.group(int.parse(x[1]!) + 1) ?? '', false));
        return _numfix(_post(filled));
      }
    }
  }
  if (top && !_kl.hasMatch(s) && !kArDict.containsKey(s) && !kEnStatic.contains(s)) return _post(s);
  var r = s.replaceAllMapped(_dayOrd, (m) => m[1]!);
  r = r.replaceAllMapped(_unitH, (m) => '${m[1]}س');
  r = r.replaceAllMapped(_unitM, (m) => '${m[1]}د');
  r = r.replaceAllMapped(_run, (m) => _seg(m[0]!));
  return _numfix(_post(r));
}

/// سۆرانی ← عەرەبی (بۆ هەر String ێک)
String arTr(String s) {
  if (s.isEmpty || !_has.hasMatch(s)) return s;
  final hit = _cache[s];
  if (hit != null) return hit;
  final out = _conv(s);
  if (_cache.length > 6000) _cache.clear();
  _cache[s] = out;
  return out;
}

/// ناوی خواردن بە عەرەبی
String arFood(String ku) => kArFood[ku] ?? ku;
