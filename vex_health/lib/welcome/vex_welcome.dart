// =============================================================================
//  VEX Health — شاشەی بەخێرهاتن (سەرەتای ئەپ)
//
//  تەواو لە یەک فایلدا: لۆگۆ، ناونیشان، ژمارەی تایبەتمەندییەکان، 4 ڕیزی
//  تایبەتمەندیی خولاوە، دوگمەی دەستپێکردن، چوونە ژوورەوە، دوگمەی زمان و
//  لیستی هەڵبژاردنی زمان. دەقەکان لە vex_welcome_i18n.dart ـدان (6 زمان).
//
//  پێویستی: flutter_svg، google_fonts، و assets/brand/vx_logo.webp
//
//  بەکارهێنان:
//    VexWelcome(
//      lang: 'ckb',                         // ckb · kmr · en · ar · fa · tr
//      dark: true,                          // دۆخی تاریک / ڕووناک
//      onStart: () { ... },                 // «دەستپێکردن»
//      onLogin: () { ... },                 // «پێشتر هەژمارم هەیە»
//      onLangChanged: (code) { ... },       // زمانی نوێ هەڵبژێردرا
//    )
// =============================================================================
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import 'vex_welcome_i18n.dart';

export 'vex_welcome_i18n.dart';

// -----------------------------------------------------------------------------
// تایبەتمەندییەکان: 4 ڕیز (8 · 8 · 8 · 7 = 31). ناوەکان لە WelcomeLang.feats ـدان
// بە هەمان ڕیزبەندی. بۆ زیاد/لابردن: لێرە و لە هەر 6 زمانەکە بە یەک شوێن.
// -----------------------------------------------------------------------------
class WelcomeFeat {
  const WelcomeFeat(this.color, this.svg);
  final int color;

  /// ناوەڕۆکی SVG ی ئایکۆن (viewBox 0 0 24 24، هێڵ)
  final String svg;
}

const List<List<WelcomeFeat>> kWelcomeRows = [
  [
    WelcomeFeat(0xFFFF5F7E, r'''<path d="M12 20.500S4 15.500 4 9.800A4.300 4.300 0 0 1 12 7.600 4.300 4.300 0 0 1 20 9.800c0 5.700-8 10.700-8 10.700z"/>'''),
    WelcomeFeat(0xFFFF5F7E, r'''<path d="M3 17l5.500-5.500 4 4L21 7M15 7h6v6"/>'''),
    WelcomeFeat(0xFF2FE6F3, r'''<path d="M12 4v9"/><path d="M12 8.500c-2.500 0-5.500 3-5.500 7 0 3 1.200 4 2.700 4S12 18 12 15.500"/><path d="M12 8.500c2.500 0 5.500 3 5.500 7 0 3-1.200 4-2.700 4S12 18 12 15.500"/>'''),
    WelcomeFeat(0xFF9B7BFF, r'''<path d="M9 4.500a3 3 0 0 0-3 3 3 3 0 0 0-2 2.800 3 3 0 0 0 1.200 2.400A3 3 0 0 0 6.500 17 3 3 0 0 0 12 18.500V5.500A3 3 0 0 0 9 4.500zM15 4.500a3 3 0 0 1 3 3 3 3 0 0 1 2 2.800 3 3 0 0 1-1.200 2.400A3 3 0 0 1 17.500 17 3 3 0 0 1 12 18.500"/>'''),
    WelcomeFeat(0xFFB9A4FF, r'''<path d="M20 14.500A8.500 8.500 0 1 1 9.500 4a6.800 6.800 0 0 0 10.500 10.500z"/>'''),
    WelcomeFeat(0xFFFFBE4D, r'''<path d="M14 14.500V5a2 2 0 0 0-4 0v9.500a4 4 0 1 0 4 0z"/><path d="M12 9v7"/>'''),
    WelcomeFeat(0xFF3CF08A, r'''<circle cx="12" cy="8" r="3.800"/><path d="M4.500 20.500c0-4 3.300-6.800 7.500-6.800s7.500 2.800 7.500 6.800"/>'''),
    WelcomeFeat(0xFFFF8A5F, r'''<path d="M7 18v-6a5 5 0 0 1 10 0v6M5 18h14M12 3v2M4.500 6.500l1.400 1.400M19.500 6.500l-1.400 1.400M9 21.500h6"/>'''),
  ],
  [
    WelcomeFeat(0xFFFFBE4D, r'''<path d="M4 8h3l1.500-2.500h7L17 8h3a1 1 0 0 1 1 1v9a1 1 0 0 1-1 1H4a1 1 0 0 1-1-1V9a1 1 0 0 1 1-1z"/><circle cx="12" cy="13.500" r="3.500"/>'''),
    WelcomeFeat(0xFF3CF08A, r'''<path d="M3 12h18a9 9 0 0 1-18 0zM8 12c0-3 1.500-5 4-6M13 12c.5-3 2-4.500 5-4.500"/>'''),
    WelcomeFeat(0xFFFF9466, r'''<path d="M12 22c4 0 7-3 7-7 0-3.300-2-5.300-3-7.500-1 2-2 3-3.200 3 .2-4-1-7-3.800-9.500 0 5.500-4 7.500-4 13 0 4.500 3 8 7 8z"/>'''),
    WelcomeFeat(0xFF2FE6F3, r'''<path d="M12 3s6 6 6 10.800a6 6 0 0 1-12 0C6 9 12 3 12 3z"/><path d="M9.500 14.500a2.700 2.700 0 0 0 2.500 2.500"/>'''),
    WelcomeFeat(0xFF3CF08A, r'''<path d="M12 3v18M6 21h12M5 7h14"/><path d="M5 7l-3 7.500a3.200 3.200 0 0 0 6 0zM19 7l-3 7.500a3.200 3.200 0 0 0 6 0z"/>'''),
    WelcomeFeat(0xFF9B7BFF, r'''<circle cx="12" cy="8" r="3.500"/><path d="M5 20.500c0-3.800 3-6.500 7-6.500s7 2.700 7 6.500M9.500 14.500L12 18l2.500-3.500"/>'''),
    WelcomeFeat(0xFFFFBE4D, r'''<path d="M12 3c-3 0-4.500 2-4.500 4 0 1.500 1 2 1 3.500S6.500 12 6.500 15.500C6.500 19 9 21 12 21s5.500-2 5.500-5.500c0-3.500-2-3.500-2-5S16.500 8.500 16.500 7c0-2-1.500-4-4.500-4zM8.500 10h7M8 15h8"/>'''),
    WelcomeFeat(0xFF3CF08A, r'''<rect x="3" y="9" width="18" height="6" rx="3" transform="rotate(-45 12 12)"/><path d="M9 9l6 6"/>'''),
  ],
  [
    WelcomeFeat(0xFF9B7BFF, r'''<path d="M11 3l1.900 5.600L18.500 10.500l-5.600 1.900L11 18l-1.900-5.600L3.500 10.500l5.600-1.900zM19 15l.8 2.200 2.200.8-2.200.8L19 21l-.8-2.200-2.200-.8 2.200-.8z"/>'''),
    WelcomeFeat(0xFF2FE6F3, r'''<path d="M6 3v6a4 4 0 0 0 8 0V3M4 3h4M12 3h4M10 13v2.500a4.500 4.500 0 0 0 9 0V13"/><circle cx="19" cy="11" r="2"/>'''),
    WelcomeFeat(0xFF3CF08A, r'''<path d="M6.500 6.500v11M17.500 6.500v11M3.500 9v6M20.500 9v6M6.500 12h11"/>'''),
    WelcomeFeat(0xFF2FE6F3, r'''<path d="M7 3c2 0 3 2 3 4.500S9 11 7.500 11 4 10 4 7.500 5 3 7 3z"/><path d="M5 14.500h5V16a2.500 2.500 0 0 1-5 0zM17 9c2 0 3 2 3 4.500S19 17 17.500 17 14 16 14 13.500 15 9 17 9z"/><path d="M15 20h5"/>'''),
    WelcomeFeat(0xFFB9A4FF, r'''<path d="M12 3c2.800 2.800 4 5.600 4 8.500S14.500 17 12 20c-2.500-3-4-5.600-4-8.500S9.200 5.800 12 3z"/><path d="M3 11c3 0 5.500 1.300 7.200 4M21 11c-3 0-5.500 1.300-7.200 4"/>'''),
    WelcomeFeat(0xFF2FE6F3, r'''<path d="M5 21V11M12 21V4M19 21v-7M3 21h18"/>'''),
    WelcomeFeat(0xFFFF9466, r'''<path d="M6 16.500V11a6 6 0 0 1 12 0v5.500l2 2H4z"/><path d="M10 21.500a2 2 0 0 0 4 0"/>'''),
    WelcomeFeat(0xFF8FF3F9, r'''<rect x="3.500" y="5" width="17" height="15.500" rx="3"/><path d="M3.500 10h17M8 3v4M16 3v4M8 14h2M12 14h2M8 17.500h2"/>'''),
  ],
  [
    WelcomeFeat(0xFFFF8FC8, r'''<circle cx="9" cy="8" r="3.200"/><path d="M3 20c0-3.500 2.800-6 6-6s6 2.500 6 6"/><circle cx="17" cy="9.500" r="2.300"/><path d="M16.500 14.200c2.700-.2 4.800 1.600 4.800 4.800"/>'''),
    WelcomeFeat(0xFFFFBE4D, r'''<path d="M8 4h8v6a4 4 0 0 1-8 0zM8 6H4.500v1.500A3 3 0 0 0 8 10.500M16 6h3.500v1.500a3 3 0 0 1-3.500 3M12 14v4M8.500 20.500h7M10 18h4"/>'''),
    WelcomeFeat(0xFFFFBE4D, r'''<rect x="3.500" y="8" width="17" height="4"/><path d="M5 12v8h14v-8M12 8v12M12 8c-2-4-6-3.500-5 0M12 8c2-4 6-3.500 5 0"/>'''),
    WelcomeFeat(0xFF8FF3F9, r'''<rect x="7" y="6.500" width="10" height="11" rx="3"/><path d="M9 6.500l.8-3.500h4.400l.8 3.500M9 17.500l.8 3.500h4.400l.8-3.500M12 10v2.500l1.600 1"/>'''),
    WelcomeFeat(0xFFFF5F7E, r'''<circle cx="12" cy="12" r="9"/><path d="M12 7.500v5M12 15.800v.2"/>'''),
    WelcomeFeat(0xFF3CF08A, r'''<rect x="5" y="11" width="14" height="10" rx="2.800"/><path d="M8 11V8a4 4 0 0 1 8 0v3M12 15.500v2"/>'''),
    WelcomeFeat(0xFFB9A4FF, r'''<path d="M20 14.500A8.500 8.500 0 1 1 9.500 4a6.800 6.800 0 0 0 10.500 10.500z"/>'''),
  ],
];

/// ژمارەی هەموو تایبەتمەندییەکان (لە سەرەوەی شاشە دەژمێردرێت)
int get kWelcomeFeatCount => kWelcomeRows.fold<int>(0, (a, r) => a + r.length);

int _rowStart(int i) {
  var n = 0;
  for (var j = 0; j < i; j++) {
    n += kWelcomeRows[j].length;
  }
  return n;
}

const String _kKuFlagSvg = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 60 40" preserveAspectRatio="xMidYMid slice" aria-hidden="true"><rect width="60" height="13.4" fill="#ED2024"/><rect y="13.3" width="60" height="13.4" fill="#fff"/><rect y="26.6" width="60" height="13.4" fill="#278E43"/><circle cx="30" cy="20" r="6.2" fill="#FEBD11"/><circle cx="30" cy="20" r="9.4" fill="none" stroke="#FEBD11" stroke-width="3.4" stroke-dasharray="1.45 1.45"/></svg>';

// -----------------------------------------------------------------------------
// ڕەنگەکان (تاریک = هەمان ڕەنگی ئەپ)
// -----------------------------------------------------------------------------
class _Pal {
  const _Pal(this.dark);
  final bool dark;
  Color get bg => dark ? const Color(0xFF03181F) : const Color(0xFFE8F2F4);
  Color get tx => dark ? const Color(0xFFEFFEFF) : const Color(0xFF05303A);
  Color get p => dark ? const Color(0xFF9CC4CB) : const Color(0xFF3E6670);
  Color get dim => dark ? const Color(0xFF5F8A92) : const Color(0xFF5B7C84);
  Color get c2 => dark ? const Color(0xFF8FF3F9) : const Color(0xFF0B7384);
  Color get ink => const Color(0xFF04323A);
  Color get dot => dark ? const Color(0xFF3D6870) : const Color(0xFF9DB8BF);
  Color get pillTx => dark ? const Color(0xFFE9FBFD) : const Color(0xFF05303A);
  Color get g1 => dark ? const Color(0xFF8FF3F9) : const Color(0xFF0B9AAE);
  Color get g2 => dark ? const Color(0xFF3CF08A) : const Color(0xFF0E9F55);
  Color line(double a) => dark ? Color.fromRGBO(140, 235, 245, a) : Color.fromRGBO(5, 48, 58, a * 0.9);
  Color white(double a) => dark ? Color.fromRGBO(255, 255, 255, a) : Color.fromRGBO(255, 255, 255, math.min(1, a * 9));
  Color pillColor(int c) {
    final k = Color(c);
    if (dark) return k;
    final h = HSLColor.fromColor(k);
    return h.withLightness((h.lightness * 0.55).clamp(0.22, 0.42)).withSaturation(math.min(1, h.saturation * 1.05)).toColor();
  }
}

Color _op(Color c, double o) => c.withAlpha((o.clamp(0.0, 1.0) * 255).round());

/// دەقی زمانەکە: عەرەبی/کوردی/فارسی بە Noto Sans Arabic، ئەوانی تر بە Noto Sans
TextStyle _lang(WelcomeLang l, double size, {FontWeight w = FontWeight.w400, required Color c, double? h}) => l.rtl
    ? GoogleFonts.notoSansArabic(fontSize: size, fontWeight: w, color: c, height: h).copyWith(fontFamilyFallback: _latin(w))
    : GoogleFonts.notoSans(fontSize: size, fontWeight: w, color: c, height: h);

/// پیتی لاتینی (ECG، AI، VEX Band، ·) لەناو دەقی عەرەبی/کوردیدا
List<String> _latin(FontWeight w) => [
      GoogleFonts.notoSans(fontWeight: w).fontFamily!,
      GoogleFonts.sora(fontWeight: w).fontFamily!,
    ];

/// دوگمە و تایبەتمەندییەکان: English/Türkçe بە Sora، ئەوانی تر بە Noto Sans Arabic
TextStyle _ui(WelcomeLang l, double size, {FontWeight w = FontWeight.w400, required Color c, double? h}) => !l.rtl
    ? GoogleFonts.sora(fontSize: size, fontWeight: w, color: c, height: h == null ? null : h * 0.86)
    : GoogleFonts.notoSansArabic(fontSize: size, fontWeight: w, color: c, height: h).copyWith(fontFamilyFallback: _latin(w));

/// ژمارە (Sora)
TextStyle _num(double size, {FontWeight w = FontWeight.w800, required Color c, double? h}) =>
    GoogleFonts.sora(fontSize: size, fontWeight: w, color: c, height: h);

void _buzz() {
  try {
    HapticFeedback.lightImpact();
  } catch (_) {}
}

// =============================================================================
//  شاشەکە
// =============================================================================
class VexWelcome extends StatelessWidget {
  const VexWelcome({
    super.key,
    this.lang = 'ckb',
    this.dark = true,
    required this.onStart,
    required this.onLogin,
    this.onLangChanged,
    this.onLangTap,
    this.logoAsset = 'assets/brand/vx_logo.webp',
  });

  /// کۆدی زمان: ckb · kmr · en · ar · fa · tr
  final String lang;
  final bool dark;
  final VoidCallback onStart;
  final VoidCallback onLogin;

  /// کاتێک بەکارهێنەر لە لیستی زماندا زمانێک هەڵدەبژێرێت
  final ValueChanged<String>? onLangChanged;

  /// ئەگەر دابنرێت، لەجیاتی لیستی ناوخۆیی بانگ دەکرێت (بۆ نموونە شاشەی زمانی خۆت)
  final VoidCallback? onLangTap;
  final String logoAsset;

  @override
  Widget build(BuildContext context) {
    final l = welcomeLang(lang);
    final c = _Pal(dark);
    final mq = MediaQuery.of(context);
    return Material(
      color: c.bg,
      child: Stack(
        children: [
          Positioned.fill(child: IgnorePointer(child: _Bg(c))),
          LayoutBuilder(
            builder: (context, cons) {
              final h = cons.maxHeight;
              final tight = h < 660;
              final compact = h < 720;
              return Padding(
                padding: EdgeInsets.only(top: mq.padding.top),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: Column(
                      children: [
                        Expanded(
                          child: _Body(
                            l: l,
                            c: c,
                            compact: compact,
                            tight: tight,
                            logo: logoAsset,
                            onLang: () {
                              _buzz();
                              if (onLangTap != null) {
                                onLangTap!();
                              } else {
                                showVexWelcomeLangPicker(context, current: l.code, dark: dark, onPick: (v) => onLangChanged?.call(v));
                              }
                            },
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.fromLTRB(22, 6, 22, mq.padding.bottom + (compact ? 12 : 18)),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _Go(label: l.start, l: l, c: c, onTap: () {
                                _buzz();
                                onStart();
                              }),
                              _Link(label: l.login, l: l, c: c, onTap: onLogin),
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  l.terms,
                                  textAlign: TextAlign.center,
                                  textDirection: l.rtl ? TextDirection.rtl : TextDirection.ltr,
                                  style: _lang(l, 10.5, c: c.dim, h: 1.6),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.l, required this.c, required this.compact, required this.tight, required this.logo, required this.onLang});
  final WelcomeLang l;
  final _Pal c;
  final bool compact, tight;
  final String logo;
  final VoidCallback onLang;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, cons) {
        final h = cons.maxHeight;
        final logoW = (h * 0.17).clamp(96.0, 136.0);
        return Stack(
          children: [
            SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: h),
                child: Padding(
                  padding: const EdgeInsets.only(top: 10, bottom: 6),
                  child: Directionality(
                    textDirection: l.rtl ? TextDirection.rtl : TextDirection.ltr,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _Rise(child: _Logo(width: logoW, asset: logo, c: c)),
                        const SizedBox(height: 4),
                        _Rise(
                          delayMs: 80,
                          child: Column(
                            children: [
                              Text(l.title,
                                  textAlign: TextAlign.center,
                                  style: _lang(l, tight ? 21 : (compact ? 23 : 26), w: FontWeight.w800, c: c.tx, h: 1.4)),
                              ShaderMask(
                                shaderCallback: (r) => LinearGradient(colors: [c.g1, c.g2]).createShader(r),
                                blendMode: BlendMode.srcIn,
                                child: Text('VEX Health',
                                    textDirection: TextDirection.ltr,
                                    style: _num(tight ? 27 : (compact ? 30 : 34), c: Colors.white, h: 1.25)),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: tight ? 8 : 6),
                        if (!tight)
                          _Rise(
                            delayMs: 140,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 34),
                              child: Text(l.para, textAlign: TextAlign.center, style: _lang(l, 13.5, c: c.p, h: 1.75)),
                            ),
                          ),
                        SizedBox(height: compact ? 10 : 16),
                        _Rise(delayMs: 180, child: Padding(padding: const EdgeInsets.symmetric(horizontal: 22), child: _Stats(l: l, c: c))),
                        SizedBox(height: compact ? 10 : 16),
                        _Marquee(l: l, c: c, compact: tight),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            PositionedDirectional(
              top: 6,
              start: 18,
              child: _Rise(delayMs: 200, child: _LangChip(l: l, c: c, onTap: onLang)),
            ),
          ],
        );
      },
    );
  }
}

// ---------- پشتەوە ----------
class _Bg extends StatelessWidget {
  const _Bg(this.c);
  final _Pal c;

  @override
  Widget build(BuildContext context) {
    final a = c.dark ? 1.0 : 0.55;
    Widget g(Alignment at, double r, Color k) => Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(gradient: RadialGradient(center: at, radius: r, colors: [k, k.withAlpha(0)])),
          ),
        );
    return Stack(children: [
      g(const Alignment(0, -1.08), 0.95, _op(const Color(0xFF2FE6F3), 0.22 * a)),
      g(const Alignment(1, 1.1), 0.8, _op(const Color(0xFF3CF08A), 0.12 * a)),
      g(const Alignment(-1, 0.2), 0.6, _op(const Color(0xFF9B7BFF), 0.07 * a)),
    ]);
  }
}

// ---------- جووڵەی هاتنە ژوورەوە ----------
class _Rise extends StatefulWidget {
  const _Rise({required this.child, this.delayMs = 0});
  final Widget child;
  final int delayMs;

  @override
  State<_Rise> createState() => _RiseState();
}

class _RiseState extends State<_Rise> with SingleTickerProviderStateMixin {
  late final AnimationController _a = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(Duration(milliseconds: widget.delayMs), () {
      if (mounted) _a.forward();
    });
  }

  @override
  void dispose() {
    _a.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _a,
        builder: (context, child) {
          final v = Curves.easeOutCubic.transform(_a.value);
          return Opacity(opacity: v, child: Transform.translate(offset: Offset(0, 14 * (1 - v)), child: child));
        },
        child: widget.child,
      );
}

// ---------- پەنجە لێدان (بچووکبوونەوەی کەم) ----------
class _Press extends StatefulWidget {
  const _Press({required this.child, this.onTap, this.scale = 0.97});
  final Widget child;
  final VoidCallback? onTap;
  final double scale;

  @override
  State<_Press> createState() => _PressState();
}

class _PressState extends State<_Press> {
  bool _down = false;
  void _set(bool v) {
    if (_down != v && mounted) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    final on = widget.onTap != null;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: on ? (_) => _set(true) : null,
      onTapUp: on ? (_) => _set(false) : null,
      onTapCancel: on ? () => _set(false) : null,
      onTap: widget.onTap,
      child: AnimatedScale(scale: _down ? widget.scale : 1, duration: const Duration(milliseconds: 120), child: widget.child),
    );
  }
}

// ---------- لۆگۆ ----------
class _Logo extends StatefulWidget {
  const _Logo({required this.width, required this.asset, required this.c});
  final double width;
  final String asset;
  final _Pal c;

  @override
  State<_Logo> createState() => _LogoState();
}

class _LogoState extends State<_Logo> with TickerProviderStateMixin {
  late final AnimationController _spin = AnimationController(vsync: this, duration: const Duration(seconds: 26))..repeat();
  late final AnimationController _glow =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1600))..repeat(reverse: true);

  @override
  void dispose() {
    _spin.dispose();
    _glow.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w = widget.width;
    final h = w / 1.36;
    return SizedBox(
      width: w,
      height: h,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          AnimatedBuilder(
            animation: _glow,
            builder: (context, _) {
              final t = Curves.easeInOut.transform(_glow.value);
              return Transform.scale(
                scale: 1 - 0.08 * t,
                child: Opacity(
                  opacity: 1 - 0.45 * t,
                  child: Container(
                    width: w * 0.72,
                    height: h * 0.84,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(colors: [Color(0x522FE6F3), Color(0x002FE6F3)], stops: [0, 0.68]),
                    ),
                  ),
                ),
              );
            },
          ),
          RotationTransition(
            turns: _spin,
            child: CustomPaint(size: Size(w * 0.76, h * 1.12), painter: _DashRing(widget.c.dark ? const Color(0x388CEBF5) : const Color(0x4D05303A))),
          ),
          Image.asset(
            widget.asset,
            width: w,
            height: h,
            fit: BoxFit.contain,
            errorBuilder: (context, e, s) => Text('VX', style: _num(w * 0.32, c: const Color(0xFF2FE6F3))),
          ),
        ],
      ),
    );
  }
}

class _DashRing extends CustomPainter {
  _DashRing(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final r = math.min(size.width, size.height) / 2;
    final ctr = size.center(Offset.zero);
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    const n = 54;
    for (var i = 0; i < n; i++) {
      final a = i / n * math.pi * 2;
      canvas.drawArc(Rect.fromCircle(center: ctr, radius: r), a, math.pi * 2 / n * 0.55, false, p);
    }
  }

  @override
  bool shouldRepaint(_DashRing o) => o.color != color;
}

// ---------- 31 تایبەتمەندی · AI ی کوردی · 24/7 چاودێری ----------
class _Stats extends StatelessWidget {
  const _Stats({required this.l, required this.c});
  final WelcomeLang l;
  final _Pal c;

  @override
  Widget build(BuildContext context) {
    Widget dot() => Container(
          width: 4,
          height: 4,
          margin: const EdgeInsets.symmetric(horizontal: 9),
          decoration: BoxDecoration(shape: BoxShape.circle, color: c.dot),
        );
    final st = _lang(l, 12.5, w: FontWeight.w700, c: c.p);
    return SizedBox(
      height: 28,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: kWelcomeFeatCount.toDouble()),
              duration: const Duration(milliseconds: 1300),
              curve: Curves.easeOutCubic,
              builder: (context, v, _) => SizedBox(
                width: 28,
                child: ShaderMask(
                  shaderCallback: (r) => LinearGradient(colors: [c.g1, c.g2]).createShader(r),
                  blendMode: BlendMode.srcIn,
                  child: Text('${v.round()}', textAlign: TextAlign.center, style: _num(19, c: Colors.white, h: 1.2)),
                ),
              ),
            ),
            const SizedBox(width: 4),
            Text(l.statFeatures, style: st),
            dot(),
            Text.rich(TextSpan(children: [
              TextSpan(text: 'AI', style: _num(12.5, c: c.tx)),
              TextSpan(text: ' ${l.statAi}'),
            ]), style: st),
            dot(),
            Text.rich(TextSpan(children: [
              TextSpan(text: '\u206624/7\u2069', style: _num(12.5, c: c.tx)),
              TextSpan(text: ' ${l.statCare}'),
            ]), style: st),
          ],
        ),
      ),
    );
  }
}

// ---------- 4 ڕیزی خولاوە ----------
class _Marquee extends StatelessWidget {
  const _Marquee({required this.l, required this.c, required this.compact});
  final WelcomeLang l;
  final _Pal c;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    const secs = [46, 56, 42, 52];
    return ShaderMask(
      shaderCallback: (r) => const LinearGradient(
        colors: [Colors.transparent, Colors.black, Colors.black, Colors.transparent],
        stops: [0, 0.16, 0.84, 1],
      ).createShader(r),
      blendMode: BlendMode.dstIn,
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < kWelcomeRows.length; i++) ...[
              if (i > 0) SizedBox(height: compact ? 6 : 8),
              _Rise(
                delayMs: 150 + i * 120,
                child: _Row(
                  feats: kWelcomeRows[i],
                  labels: l.feats.sublist(_rowStart(i), _rowStart(i) + kWelcomeRows[i].length),
                  l: l,
                  c: c,
                  seconds: secs[i % secs.length],
                  reverse: i.isOdd,
                  height: compact ? 31 : 36,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Row extends StatefulWidget {
  const _Row({required this.feats, required this.labels, required this.l, required this.c, required this.seconds, required this.reverse, required this.height});
  final List<WelcomeFeat> feats;
  final List<String> labels;
  final WelcomeLang l;
  final _Pal c;
  final int seconds;
  final bool reverse;
  final double height;

  @override
  State<_Row> createState() => _RowState();
}

class _RowState extends State<_Row> with SingleTickerProviderStateMixin {
  late final AnimationController _a = AnimationController(vsync: this, duration: Duration(seconds: widget.seconds));
  double _w = 0;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.of(context).disableAnimations) {
      _a.stop();
    } else if (!_started) {
      _started = true;
      _a.repeat();
    }
  }

  @override
  void dispose() {
    _a.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final group = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < widget.feats.length; i++)
          Padding(padding: const EdgeInsets.only(right: 8), child: _pill(widget.feats[i], widget.labels[i])),
      ],
    );
    return SizedBox(
      height: widget.height,
      child: ClipRect(
        child: RepaintBoundary(
          child: OverflowBox(
            alignment: Alignment.centerLeft,
            minWidth: 0,
            maxWidth: double.infinity,
            child: AnimatedBuilder(
              animation: _a,
              builder: (context, child) {
                final t = widget.reverse ? 1 - _a.value : _a.value;
                return Transform.translate(offset: Offset(-t * _w, 0), child: child);
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _SizeReport(
                    onSize: (s) {
                      if (mounted && (s.width - _w).abs() > 0.5) setState(() => _w = s.width);
                    },
                    child: group,
                  ),
                  group,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _pill(WelcomeFeat f, String label) {
    final c = widget.c;
    final k = c.pillColor(f.color);
    final hex = '#${(k.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';
    return Container(
      height: widget.height,
      padding: const EdgeInsets.only(left: 12, right: 13),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(99),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_op(k, c.dark ? 0.16 : 0.12), c.white(0.025)],
        ),
        border: Border.all(color: _op(k, 0.40)),
      ),
      child: Directionality(
        textDirection: widget.l.rtl ? TextDirection.rtl : TextDirection.ltr,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.string(
              '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="$hex" stroke-width="2" '
              'stroke-linecap="round" stroke-linejoin="round">${f.svg}</svg>',
              width: 16,
              height: 16,
            ),
            const SizedBox(width: 7),
            Text(label, style: _ui(widget.l, widget.height < 34 ? 12 : 12.5, w: FontWeight.w700, c: c.pillTx, h: 1.2)),
          ],
        ),
      ),
    );
  }
}

/// قەبارەی ڕیزەکە ڕادەگەیەنێت (بۆ ئەوەی بێ بڕین بخولێتەوە)
class _SizeReport extends SingleChildRenderObjectWidget {
  const _SizeReport({required this.onSize, super.child});
  final ValueChanged<Size> onSize;

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderSizeReport(onSize);

  @override
  void updateRenderObject(BuildContext context, _RenderSizeReport renderObject) => renderObject.onSize = onSize;
}

class _RenderSizeReport extends RenderProxyBox {
  _RenderSizeReport(this.onSize);
  ValueChanged<Size> onSize;
  Size? _old;

  @override
  void performLayout() {
    super.performLayout();
    final s = size;
    if (_old != s) {
      _old = s;
      WidgetsBinding.instance.addPostFrameCallback((_) => onSize(s));
    }
  }
}

// ---------- دوگمەی سەرەکی ----------
class _Go extends StatelessWidget {
  const _Go({required this.label, required this.l, required this.c, required this.onTap});
  final String label;
  final WelcomeLang l;
  final _Pal c;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: _Press(
        onTap: onTap,
        scale: 0.98,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: const LinearGradient(colors: [Color(0xFF8FF3F9), Color(0xFF3CF08A)]),
            boxShadow: const [BoxShadow(color: Color(0xD93CF08A), blurRadius: 34, offset: Offset(0, 16), spreadRadius: -14)],
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: _ui(l, 16, w: FontWeight.w800, c: c.ink),
          ),
        ),
      ),
    );
  }
}

// ---------- «پێشتر هەژمارم هەیە» ----------
class _Link extends StatelessWidget {
  const _Link({required this.label, required this.l, required this.c, required this.onTap});
  final String label;
  final WelcomeLang l;
  final _Pal c;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Center(
        child: _Press(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Text(label, textAlign: TextAlign.center, style: _ui(l, 13.5, w: FontWeight.w700, c: c.c2)),
          ),
        ),
      ),
    );
  }
}

// ---------- ئاڵا ----------
class _Flag extends StatelessWidget {
  const _Flag(this.l, this.c, {this.size = 24, this.on = false});
  final WelcomeLang l;
  final _Pal c;
  final double size;
  final bool on;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: c.white(0.07),
        border: Border.all(color: on ? c.g2 : c.white(0.14), width: 1.5),
      ),
      child: ClipOval(
        child: l.flag == 'KU'
            ? SvgPicture.string(_kKuFlagSvg, width: size, height: size, fit: BoxFit.cover)
            : Center(child: Text(l.flag, style: TextStyle(fontSize: size * 0.58, height: 1))),
      ),
    );
  }
}

// ---------- دوگمەی زمان (سەرەوە) ----------
class _LangChip extends StatelessWidget {
  const _LangChip({required this.l, required this.c, required this.onTap});
  final WelcomeLang l;
  final _Pal c;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: l.native,
      child: _Press(
        onTap: onTap,
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Container(
            padding: const EdgeInsets.fromLTRB(7, 6, 13, 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(99),
              color: c.white(0.06),
              border: Border.all(color: c.line(0.2)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _Flag(l, c, size: 24),
                const SizedBox(width: 8),
                Text(l.native, style: _lang(l, 12.5, w: FontWeight.w700, c: c.tx)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
//  لیستی هەڵبژاردنی زمان (کاتێک onLangTap دانەنرابێت)
// =============================================================================
Future<void> showVexWelcomeLangPicker(BuildContext context,
    {required String current, required bool dark, required ValueChanged<String> onPick}) {
  final c = _Pal(dark);
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) => Container(
      padding: EdgeInsets.fromLTRB(18, 10, 18, 18 + MediaQuery.of(ctx).padding.bottom),
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF062A35) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(top: BorderSide(color: c.line(0.25))),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 42, height: 5, margin: const EdgeInsets.only(bottom: 16), decoration: BoxDecoration(color: c.line(0.3), borderRadius: BorderRadius.circular(9))),
          LayoutBuilder(builder: (context, cons) {
            final w = (cons.maxWidth - 9) / 2;
            return Wrap(
              spacing: 9,
              runSpacing: 9,
              children: [
                for (final l in kWelcomeLangs)
                  SizedBox(
                    width: w,
                    child: _Press(
                      onTap: () {
                        _buzz();
                        Navigator.of(ctx).pop();
                        if (l.code != current) onPick(l.code);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          color: l.code == current ? _op(c.g2, 0.12) : c.white(0.05),
                          border: Border.all(color: l.code == current ? c.g2 : c.line(0.18), width: l.code == current ? 1.5 : 1),
                        ),
                        child: Row(children: [
                          _Flag(l, c, size: 30, on: l.code == current),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(l.native,
                                textDirection: l.rtl ? TextDirection.rtl : TextDirection.ltr,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: _lang(l, 14, w: FontWeight.w700, c: c.tx)),
                          ),
                        ]),
                      ),
                    ),
                  ),
              ],
            );
          }),
        ],
      ),
    ),
  );
}
