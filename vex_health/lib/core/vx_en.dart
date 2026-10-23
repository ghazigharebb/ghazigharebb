// VEX Health — English layer
// ----------------------------------------------------------------------------
// کاتێک زمانی ئەپ English بێت (LangState.I.code == 'en')، هەموو دەقە کوردییەکان
// لە کاتی پیشاندانەوە دەگۆڕدرێن بۆ ئینگلیزی. کوردی ناگۆڕدرێت.
//
//   • VText / VText.rich  = Text ی ئاسایی + وەرگێڕان (لە هەموو ئەپەکەدا Text جێگۆڕکێ کراوە)
//   • vxTr('...')          = وەرگێڕانی هەر String ێک (بۆ hint، ئاگادارکردنەوە، پەیام…)
//   • kIsEn                = ئایا ئێستا ئینگلیزییە؟
//   • LangScope            = لە main.dart دایە؛ کاتێک زمان دەگۆڕێت هەموو VText ـەکان نوێ دەکاتەوە
//
// فەرهەنگ و ڕستەکان لە lib/lang/lang_en_english.dart دان (خۆکار دروست کراون).
import 'package:flutter/material.dart';

import '../onboarding/reg_lang_state.dart';
import 'vx_ar.dart';
import 'vx_fa.dart';
import 'vx_tr.dart';
import 'vx_bd.dart';
import '../lang/lang_en_english.dart';

/// ئایا ئێستا زمانی ئەپ ئینگلیزییە؟
bool get kIsEn => LangState.I.code == 'en';

/// ئایا ئێستا زمانی ئەپ کوردی بادینییە؟ (kmr)
bool get kIsBd => LangState.I.code == 'kmr';

/// ئایا ئێستا زمانی ئەپ عەرەبییە؟ (ar)
bool get kIsAr => LangState.I.code == 'ar';

/// ئایا ئێستا زمانی ئەپ فارسییە؟ (fa)
bool get kIsFa => LangState.I.code == 'fa';

/// ئایا ئێستا زمانی ئەپ تورکییە؟ (tr)
bool get kIsTr => LangState.I.code == 'tr';

/// زمانی لاتینی چەپ بۆ ڕاست (ئینگلیزی یان تورکی)
bool get kIsLtr => kIsEn || kIsTr;

/// کۆنتێکستی ئاراستە: چەپ بۆ ڕاست (ئینگلیزی) یان ڕاست بۆ چەپ (کوردی)
TextDirection get kDir => kIsLtr ? TextDirection.ltr : TextDirection.rtl;

/// کاتێک زمان دەگۆڕێت هەموو VText ـەکان نوێ دەبنەوە
class LangScope extends InheritedWidget {
  const LangScope({super.key, required this.code, required super.child});
  final String code;

  static String of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<LangScope>()?.code ?? LangState.I.code;

  @override
  bool updateShouldNotify(LangScope old) => old.code != code;
}

// ---------------------------------------------------------------------------
// بزوێنەر
// ---------------------------------------------------------------------------
const String _arCls = 'ء-يٱ-ۓە۰-۹‌';
final RegExp _has = RegExp('[؀-ۿ‌]');
final RegExp _run = RegExp('[$_arCls]+(?: [$_arCls]+)*');
final RegExp _cap0 = RegExp('^[ء-يٱ-ۓە]');
final RegExp _sing = RegExp(r'(^|[^\d.,])1 (hours|days|minutes|weeks|months|years|seconds|cups|items|members|glasses|steps|portions|meals|points|coins)\b');
final RegExp _keep = RegExp(KEEP_PATTERN);
final RegExp _stop = RegExp(STOP_PATTERN);
final RegExp _lcHead = RegExp(r'^[A-Z][a-z]');
final RegExp _lowHead = RegExp(r'^[a-z]');
final RegExp _ph = RegExp(r'\{(\d+)\}');
final RegExp _unitH = RegExp('(\\d)ک(?![$_arCls])');
final RegExp _unitM = RegExp('(\\d)خ(?![$_arCls])');
final RegExp _dDate = RegExp(r'^([^،]+)، (\d+)ی (.+)$');
final RegExp _dFull = RegExp(r'^(\d+)ی (\S+(?: \S+)?) (\d{4})$');
final RegExp _dDay = RegExp(r'^(\d+)ی (.+)$');
final RegExp _comma = RegExp(r'[,;(،؛]\s*$');

class _Tpl {
  _Tpl(String key, this.out) {
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

final List<_Tpl> _tpls = [for (final t in kEnTpl) _Tpl(t[0], t[1])];
final Map<String, String> _cache = <String, String>{};

String _lc1(String o) {
  if (o.isEmpty || !_lcHead.hasMatch(o) || _keep.hasMatch(o)) return o;
  return o[0].toLowerCase() + o.substring(1);
}

String _seg(String m) {
  final e = kEnDict[m];
  if (e != null) return e;
  final w = m.split(' ');
  final n = w.length;
  if (n == 1) return m;
  final out = <String>[];
  var i = 0;
  while (i < n) {
    var hit = false;
    for (var j = n; j > i; j--) {
      final k = w.sublist(i, j).join(' ');
      final d = kEnDict[k];
      if (d != null) {
        out.add(out.isEmpty ? d : _lc1(d));
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
  return out.join(' ');
}

String _conv(String s) {
  final lit = kEnLit[s];
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
  final d1 = _dDate.firstMatch(r);
  if (d1 != null) {
    r = '${d1[1]}, ${d1[3]} ${d1[2]}';
  } else {
    final d2 = _dFull.firstMatch(r);
    if (d2 != null) {
      r = '${d2[2]} ${d2[1]}, ${d2[3]}';
    } else {
      final d3 = _dDay.firstMatch(r);
      if (d3 != null) r = '${d3[2]} ${d3[1]}';
    }
  }
  r = r.replaceAllMapped(_unitH, (m) => '${m[1]}h');
  r = r.replaceAllMapped(_unitM, (m) => '${m[1]}m');
  if (_has.hasMatch(r)) {
    final src = r;
    r = src.replaceAllMapped(_run, (m) {
      var o = _seg(m[0]!);
      if (m.start > 0 && _comma.hasMatch(src.substring(m.start >= 3 ? m.start - 3 : 0, m.start))) o = _lc1(o);
      return o;
    });
  }
  r = r.replaceAllMapped(RegExp('[٠-٩]'), (m) => '${m[0]!.codeUnitAt(0) - 0x660}');
  r = r.replaceAllMapped(RegExp('[۰-۹]'), (m) => '${m[0]!.codeUnitAt(0) - 0x6f0}');
  r = r.replaceAll('،', ',').replaceAll('؟', '?').replaceAll('؛', ';').replaceAll('٪', '%').replaceAll('٫', '.').replaceAll('٬', ',');
  r = r.replaceAllMapped(_sing, (m) => '${m[1]}1 ${m[2]!.substring(0, m[2]!.length - 1)}');
  if (_cap0.hasMatch(s) && r != s && _lowHead.hasMatch(r) && !_stop.hasMatch(r)) {
    r = r[0].toUpperCase() + r.substring(1);
  }
  return r;
}

/// هەر String ێک: ئەگەر زمان ئینگلیزی بێت و دەقەکە کوردی بێت، دەیکات بە ئینگلیزی.
String vxTr(String s) {
  if (s.isEmpty || !_has.hasMatch(s)) return s;
  if (kIsBd) return bdTr(s);
  if (kIsAr) return arTr(s);
  if (kIsFa) return faTr(s);
  if (kIsTr) return trTr(s);
  if (!kIsEn) return s;
  final hit = _cache[s];
  if (hit != null) return hit;
  final out = _conv(s);
  if (_cache.length > 6000) _cache.clear();
  _cache[s] = out;
  return out;
}

InlineSpan vxSpan(InlineSpan s) {
  if ((!kIsEn && !kIsBd && !kIsAr && !kIsFa && !kIsTr) || s is! TextSpan) return s;
  return TextSpan(
    text: s.text == null ? null : vxTr(s.text!),
    children: s.children?.map(vxSpan).toList(),
    style: s.style,
    recognizer: s.recognizer,
    mouseCursor: s.mouseCursor,
    onEnter: s.onEnter,
    onExit: s.onExit,
    semanticsLabel: s.semanticsLabel,
    locale: s.locale,
    spellOut: s.spellOut,
  );
}

/// Text ی ئاسایی + وەرگێڕان بۆ ئینگلیزی (کوردی وەک خۆی دەمێنێتەوە)
class VText extends StatelessWidget {
  const VText(
    this.data, {
    super.key,
    this.style,
    this.strutStyle,
    this.textAlign,
    this.textDirection,
    this.locale,
    this.softWrap,
    this.overflow,
    this.textScaler,
    this.maxLines,
    this.semanticsLabel,
    this.textWidthBasis,
    this.textHeightBehavior,
    this.selectionColor,
  }) : textSpan = null;

  const VText.rich(
    InlineSpan this.textSpan, {
    super.key,
    this.style,
    this.strutStyle,
    this.textAlign,
    this.textDirection,
    this.locale,
    this.softWrap,
    this.overflow,
    this.textScaler,
    this.maxLines,
    this.semanticsLabel,
    this.textWidthBasis,
    this.textHeightBehavior,
    this.selectionColor,
  }) : data = null;

  final String? data;
  final InlineSpan? textSpan;
  final TextStyle? style;
  final StrutStyle? strutStyle;
  final TextAlign? textAlign;
  final TextDirection? textDirection;
  final Locale? locale;
  final bool? softWrap;
  final TextOverflow? overflow;
  final TextScaler? textScaler;
  final int? maxLines;
  final String? semanticsLabel;
  final TextWidthBasis? textWidthBasis;
  final TextHeightBehavior? textHeightBehavior;
  final Color? selectionColor;

  @override
  Widget build(BuildContext context) {
    LangScope.of(context); // زمان گۆڕا ← نوێ ببەوە
    final dir = kIsEn && textDirection == TextDirection.rtl ? TextDirection.ltr : textDirection;
    if (textSpan != null) {
      return Text.rich(
        vxSpan(textSpan!),
        style: style,
        strutStyle: strutStyle,
        textAlign: textAlign,
        textDirection: dir,
        locale: locale,
        softWrap: softWrap,
        overflow: overflow,
        textScaler: textScaler,
        maxLines: maxLines,
        semanticsLabel: semanticsLabel,
        textWidthBasis: textWidthBasis,
        textHeightBehavior: textHeightBehavior,
        selectionColor: selectionColor,
      );
    }
    return Text(
      vxTr(data ?? ''),
      style: style,
      strutStyle: strutStyle,
      textAlign: textAlign,
      textDirection: dir,
      locale: locale,
      softWrap: softWrap,
      overflow: overflow,
      textScaler: textScaler,
      maxLines: maxLines,
      semanticsLabel: semanticsLabel == null ? null : vxTr(semanticsLabel!),
      textWidthBasis: textWidthBasis,
      textHeightBehavior: textHeightBehavior,
      selectionColor: selectionColor,
    );
  }
}
