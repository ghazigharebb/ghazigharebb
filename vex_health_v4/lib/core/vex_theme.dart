// VEX Health — all color fix
// ڕووناک / تاریک / خۆکار — یەک سەرچاوەی ڕەنگ بۆ هەموو ئەپەکە.
//
//  • VexTheme.I.setMode(VexMode.light | dark | auto)  ← گۆڕینی دۆخ
//  • خۆکار: کاتێک کەشی سیستەم دەگۆڕێت (ڕۆژ ↔ شەو، یان ڕێکخستنی خۆکاری ئەندرۆید/iOS)
//    ئەپەکە خۆی لە ساتەکەدا ڕەنگەکان نوێ دەکاتەوە، بێ کردنەوەی دووبارە.
//  • V.* ، HC.* ، HX.* ، BandColors.* هەموویان لێرەوە ڕەنگی چالاک دەخوێننەوە.
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'vx_en.dart' show VText;

enum VexMode { auto, light, dark }

/// پاڵێتێکی تەواو (هەموو ڕەنگەکانی V و HC و BandColors)
class VexPal {
  const VexPal({
    required this.dark,
    required this.bg,
    required this.surf,
    required this.surf2,
    required this.line,
    required this.line2,
    required this.cy,
    required this.c2,
    required this.mint,
    required this.violet,
    required this.coral,
    required this.amber,
    required this.orange,
    required this.tx,
    required this.mu,
    required this.track,
    required this.nav,
    required this.sheet,
    required this.ink,
    required this.hBg,
    required this.hBg2,
    required this.hCard,
    required this.hLine,
    required this.hC,
    required this.hC2,
    required this.hTx,
    required this.hMu,
    required this.hTrack,
    required this.hGlow,
    required this.hOk,
    required this.hWn,
    required this.hBd,
    required this.hNd,
    required this.hOrange,
    required this.hHr,
    required this.hHr2,
    required this.hInk,
  });

  final bool dark;
  // ---- V
  final Color bg, surf, surf2, line, line2, cy, c2, mint, violet, coral, amber, orange, tx, mu, track, nav, sheet, ink;
  // ---- HC
  final Color hBg, hBg2, hCard, hLine, hC, hC2, hTx, hMu, hTrack, hGlow, hOk, hWn, hBd, hNd, hOrange, hHr, hHr2, hInk;

  /// تاریک — هەمان ڕەنگەکانی پێشووی ئەپەکە (هیچ گۆڕانکارییەک)
  static const VexPal darkPal = VexPal(
    dark: true,
    bg: Color(0xFF04202A),
    surf: Color(0x940C3A48),
    surf2: Color(0x0EFFFFFF),
    line: Color(0x218CEBF5),
    line2: Color(0x428CEBF5),
    cy: Color(0xFF2FE6F3),
    c2: Color(0xFF8FF3F9),
    mint: Color(0xFF3CF08A),
    violet: Color(0xFF9B7BFF),
    coral: Color(0xFFFF5F7E),
    amber: Color(0xFFFFBE4D),
    orange: Color(0xFFFF9466),
    tx: Color(0xFFEFFEFF),
    mu: Color(0xFF8CB7BF),
    track: Color(0x14FFFFFF),
    nav: Color(0xE606242E),
    sheet: Color(0xFF062A35),
    ink: Color(0xFF04323A),
    hBg: Color(0xFF062832),
    hBg2: Color(0xFF0A3F4C),
    hCard: Color(0x0BFFFFFF),
    hLine: Color(0x266CF0F7),
    hC: Color(0xFF03EAFB),
    hC2: Color(0xFF6CF0F7),
    hTx: Color(0xFFEAFFFF),
    hMu: Color(0xFF80B4BC),
    hTrack: Color(0x14FFFFFF),
    hGlow: Color(0x4D03EAFB),
    hOk: Color(0xFF5BE3A4),
    hWn: Color(0xFFFFB84D),
    hBd: Color(0xFFFF6B7F),
    hNd: Color(0xFF6F8F96),
    hOrange: Color(0xFFFF8A5C),
    hHr: Color(0xFFFF5C7A),
    hHr2: Color(0xFFFF8FA3),
    hInk: Color(0xFF04323A),
  );

  /// ڕووناک — ڕەنگە پەسەندکراوەکان (دەق ≥ 4.5:1 لەسەر هەموو زەمینەکان)
  static const VexPal lightPal = VexPal(
    dark: false,
    bg: Color(0xFFE8F2F4),
    surf: Color(0xFFFFFFFF),
    surf2: Color(0xFFEEF5F7),
    line: Color(0xFFB7D1D8),
    line2: Color(0xFF8FB5BF),
    cy: Color(0xFF07707F),
    c2: Color(0xFF0B7384),
    mint: Color(0xFF087A41),
    violet: Color(0xFF5B3BD1),
    coral: Color(0xFFC01C42),
    amber: Color(0xFF8F5400),
    orange: Color(0xFFA9400A),
    tx: Color(0xFF05303A),
    mu: Color(0xFF3E6670),
    track: Color(0x1F05303A),
    nav: Color(0xF5FFFFFF),
    sheet: Color(0xFFFFFFFF),
    ink: Color(0xFF04323A),
    hBg: Color(0xFFE8F2F4),
    hBg2: Color(0xFFDCEBEE),
    hCard: Color(0xFFFFFFFF),
    hLine: Color(0xFFB7D1D8),
    hC: Color(0xFF07707F),
    hC2: Color(0xFF0B7384),
    hTx: Color(0xFF05303A),
    hMu: Color(0xFF3E6670),
    hTrack: Color(0x1F05303A),
    hGlow: Color(0x2607707F),
    hOk: Color(0xFF087A41),
    hWn: Color(0xFF8F5400),
    hBd: Color(0xFFC01C42),
    hNd: Color(0xFF4F7078),
    hOrange: Color(0xFFA9400A),
    hHr: Color(0xFFC01C42),
    hHr2: Color(0xFFB8325A),
    hInk: Color(0xFF04323A),
  );
}

/// دۆخی ڕەنگی ئەپەکە (singleton)
class VexTheme extends ChangeNotifier with WidgetsBindingObserver {
  VexTheme._();
  static final VexTheme I = VexTheme._();
  static const String _key = 'vex_theme_mode';

  VexMode _mode = VexMode.auto;
  bool _light = false; // ئەنجامی کۆتایی
  bool _hold = false; // بۆ سپلاش: هەمیشە تاریک
  bool _inited = false;
  int _rev = 0; // هەر گۆڕانێک +1

  VexMode get mode => _mode;
  int get rev => _rev;

  /// ئێستا ڕووناکە؟ (پاش هەڵبژاردن یان کەشی سیستەم)
  bool get isLight => !_hold && _light;
  bool get isDark => !isLight;
  Brightness get brightness => isLight ? Brightness.light : Brightness.dark;
  VexPal get p => isLight ? VexPal.lightPal : VexPal.darkPal;

  bool _sysLight() => ui.PlatformDispatcher.instance.platformBrightness == Brightness.light;

  bool _resolve() {
    switch (_mode) {
      case VexMode.light:
        return true;
      case VexMode.dark:
        return false;
      case VexMode.auto:
        return _sysLight();
    }
  }

  /// لە main() پێش runApp بانگ بکە
  Future<void> init() async {
    if (_inited) return;
    _inited = true;
    WidgetsBinding.instance.addObserver(this);
    try {
      final sp = await SharedPreferences.getInstance();
      final s = sp.getString(_key);
      _mode = VexMode.values.firstWhere((m) => m.name == s, orElse: () => VexMode.auto);
    } catch (_) {
      _mode = VexMode.auto;
    }
    _light = _resolve();
    _applyChrome();
  }

  Future<void> setMode(VexMode m) async {
    if (m == _mode) return;
    _mode = m;
    try {
      final sp = await SharedPreferences.getInstance();
      await sp.setString(_key, m.name);
    } catch (_) {}
    _refresh();
  }

  /// سپلاش: بۆ ماوەیەک تاریک (ئەگەر true)، پاشان دەگەڕێتەوە
  void hold(bool on) {
    if (_hold == on) return;
    _hold = on;
    _refresh(force: true);
  }

  // ---- کەشی سیستەم گۆڕا (ڕۆژ ↔ شەو، یان گۆڕینی دەستی لە ڕێکخستنەکانی مۆبایل)
  @override
  void didChangePlatformBrightness() {
    if (_mode == VexMode.auto) _refresh();
  }

  void _refresh({bool force = false}) {
    final now = _resolve();
    final changed = now != _light;
    _light = now;
    if (!changed && !force) return;
    _rev++;
    _applyChrome();
    notifyListeners(); // MaterialApp: ThemeData نوێ دەبێتەوە
    _repaintEverything(); // هەموو widget و painter ـەکان: ڕەنگ لە سەرەتاوە دەخوێننەوە
  }

  /// شریتی دۆخ و ناڤیگەیشن — بەپێی ڕووناک/تاریک
  SystemUiOverlayStyle get chromeStyle {
    final l = isLight;
    return SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: l ? Brightness.dark : Brightness.light,
      statusBarBrightness: l ? Brightness.light : Brightness.dark, // iOS
      systemNavigationBarColor: l ? VexPal.lightPal.bg : VexPal.darkPal.bg,
      systemNavigationBarIconBrightness: l ? Brightness.dark : Brightness.light,
      systemNavigationBarDividerColor: Colors.transparent,
    );
  }

  void _applyChrome() {
    SystemChrome.setSystemUIOverlayStyle(chromeStyle);
  }

  /// هەموو element و render object ـەکان دووبارە دەکێشرێنەوە، بۆ ئەوەی widget ـی const و
  /// CustomPainter ـی cache کراویش ڕەنگی نوێ وەربگرن.
  void _repaintEverything() {
    void run() {
      final root = WidgetsBinding.instance.rootElement;
      if (root == null) return; // هێشتا ئەپەکە دروست نەبووە
      {
        void walk(Element e) {
          e.markNeedsBuild();
          e.visitChildren(walk);
        }

        walk(root);
      }
      void paintWalk(RenderObject r) {
        r.markNeedsPaint();
        r.visitChildren(paintWalk);
      }

      for (final rv in RendererBinding.instance.renderViews) {
        paintWalk(rv);
      }
    }

    final phase = SchedulerBinding.instance.schedulerPhase;
    if (phase == SchedulerPhase.idle || phase == SchedulerPhase.postFrameCallbacks) {
      run();
    } else {
      SchedulerBinding.instance.addPostFrameCallback((_) => run());
    }
  }

  // ---- ThemeData ی Material (هەردوو دۆخ)
  ThemeData themeData({required bool en}) {
    final pal = p;
    final base = ThemeData(brightness: pal.dark ? Brightness.dark : Brightness.light, useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: pal.bg,
      canvasColor: pal.bg,
      colorScheme: ColorScheme.fromSeed(seedColor: pal.cy, brightness: pal.dark ? Brightness.dark : Brightness.light).copyWith(
        surface: pal.dark ? pal.sheet : pal.surf,
        onSurface: pal.tx,
        primary: pal.cy,
        onPrimary: pal.dark ? pal.ink : Colors.white,
        outline: pal.line2,
        error: pal.coral,
      ),
      dividerColor: pal.line,
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: pal.cy,
        selectionColor: pal.cy.withAlpha(70),
        selectionHandleColor: pal.cy,
      ),
    );
  }
}

// ============================================================
//  یارمەتیدەرەکانی ڕەنگ
// ============================================================

/// ڕەنگی hex ی `#rrggbb` بۆ ئایکۆنەکانی SVG
String vexHex(Color c) {
  final v = c.value & 0xFFFFFF;
  return '#${v.toRadixString(16).padLeft(6, '0')}';
}

/// hex ی SVG لە ڕووناکدا بە ڕەنگی هاوتای پاڵێتی ڕووناک دەگۆڕدرێت (ئایکۆنەکان نابنە ون)
String vexMapHex(String hex) {
  if (!VexTheme.I.isLight || hex.length != 7 || !hex.startsWith('#')) return hex;
  final v = int.tryParse(hex.substring(1), radix: 16);
  if (v == null) return hex;
  return vexHex(vk(0xFF000000 | v));
}

/// «سپی»ی دەق/ئایکۆن: سپی لە تاریک، ڕەنگی دەق لە ڕووناک
Color get kW => VexTheme.I.isLight ? VexPal.lightPal.tx : Colors.white;

/// دەق/ئایکۆن لەسەر زەمینەی ڕەنگاوڕەنگی تۆخ (لە ڕووناکدا سپی؛ لە تاریکدا ink)
Color get kOnAcc => VexTheme.I.isLight ? Colors.white : VexPal.darkPal.ink;

/// دەق لەسەر گرادیەنتی سەرەکی (prime: کاڵ لە هەردوو دۆخ) — لە ڕووناکدا ink، لە تاریکدا سپی
Color get kOnPrime => VexTheme.I.isLight ? VexPal.lightPal.ink : Colors.white;

/// ڕەنگە بە دەستنووسکراوەکان (Color(0x…)) — لە تاریکدا وەک خۆی؛ لە ڕووناکدا بە نزیکترین ڕەنگی پاڵێتی ڕووناک
Color vk(int argb) {
  final c = Color(argb);
  if (!VexTheme.I.isLight) return c;
  return _lightCache.putIfAbsent(argb, () => _toLight(c));
}

/// لیست/map ی ڕەنگدار: یەک جار بۆ هەر دۆخێکی ڕەنگ دروست دەبێت (نەک لە هەر فریمێکدا)
final Map<String, Object?> _vexCache = <String, Object?>{};
int _vexCacheRev = -1;
T vexCache<T>(String key, T Function() make) {
  final r = VexTheme.I.rev;
  if (_vexCacheRev != r) {
    _vexCache.clear();
    _vexCacheRev = r;
  }
  return (_vexCache[key] ??= make()) as T;
}

/// Color.fromRGBO(r, g, b, o) ی دەستنووسکراو
Color vkRGBO(int r, int g, int b, double o) {
  final a = (o.clamp(0.0, 1.0) * 255).round();
  return vk((a << 24) | (r << 16) | (g << 8) | b);
}

/// Color.fromARGB(a, r, g, b) ی دەستنووسکراو
Color vkARGB(int a, int r, int g, int b) => vk((a << 24) | (r << 16) | (g << 8) | b);

final Map<int, Color> _lightCache = <int, Color>{};

// ڕەنگی تاریک (RGB) ← ڕەنگی ڕووناکی هاوتا
const Map<int, int> _pairs = <int, int>{
  // زەمینە و کارت
  0x04202A: 0xE8F2F4, 0x031A22: 0xDCEBEE, 0x03181F: 0xE8F2F4, 0x062832: 0xE8F2F4,
  0x062A35: 0xFFFFFF, 0x0A3F4C: 0xDCEBEE, 0x0C3A48: 0xFFFFFF, 0x0B3442: 0xFFFFFF,
  0x06242E: 0xFFFFFF, 0x0A3441: 0xFFFFFF, 0x0D3D4B: 0xEEF5F7,
  // دەق
  0xEFFEFF: 0x05303A, 0xEAFFFF: 0x05303A, 0xFFFFFF: 0x05303A,
  0x8CB7BF: 0x3E6670, 0x9CC4CB: 0x3E6670, 0x80B4BC: 0x3E6670, 0x7FA6AD: 0x3E6670,
  0x7FB9C2: 0x3E6670, 0x5F8A92: 0x4F7078, 0x6F8F96: 0x4F7078, 0xCFE6EC: 0x2F5560,
  0xCFE9EE: 0x2F5560,
  // هێڵ
  0x8CEBF5: 0x8FB5BF, 0x6CF0F7: 0x0B7384,
  // ڕەنگە سەرەکییەکان
  0x2FE6F3: 0x07707F, 0x03EAFB: 0x07707F, 0x8FF3F9: 0x0B7384, 0x14B8D6: 0x0A7C8C,
  0x3CF08A: 0x087A41, 0x5BE3A4: 0x087A41,
  0x9B7BFF: 0x5B3BD1, 0x8B6CFF: 0x5B3BD1, 0x8B6BFF: 0x5B3BD1, 0xB79BFF: 0x5B3BD1, 0xB9A4FF: 0x5B3BD1,
  0x9D86FF: 0x5B3BD1, 0x7B4DFF: 0x5B3BD1, 0x4D6BFF: 0x3F58D6,
  0xFF5F7E: 0xC01C42, 0xFF5C7A: 0xC01C42, 0xFF6B7F: 0xC01C42, 0xFF7D96: 0xC01C42, 0xFF8A9D: 0xC01C42,
  0xFF5F5F: 0xC01C42, 0xFF8FA3: 0xB8325A, 0xFF8FC8: 0xB8325A,
  0xFFBE4D: 0x8F5400, 0xFFB84D: 0x8F5400, 0xFFC95E: 0x8F5400,
0xFF9466: 0xA9400A, 0xFF8A5C: 0xA9400A, 0xFF8A5F: 0xA9400A,
  0x3DB8FF: 0x1A5FB4, 0x1A8CFF: 0x1A5FB4, 0x3A7BD5: 0x1A5FB4,
  // دەق لەسەر دوگمە + ڕەنگە زێڕینەکانی VEX Plus (هەمیشە وەک خۆیان)
  0x04323A: 0x04323A,
  0xFFE29A: 0xFFE29A, 0xFFBF47: 0xFFBF47, 0xFF9D3D: 0xFF9D3D, 0xFFE9A8: 0xFFE9A8, 0xFFF2C2: 0xFFF2C2,
  0xFFD56B: 0xFFD56B, 0xD9A23C: 0xD9A23C, 0xFFF1CF: 0xFFF1CF, 0xFFD36B: 0xFFD36B, 0x3B2500: 0x3B2500, 0x5E3A00: 0x5E3A00, 0xFFE7A3: 0xFFE7A3, 0xFFC857: 0xFFC857,
};

Color _toLight(Color c) {
  final a = (c.value >> 24) & 0xFF; // 0..255
  final rgb = c.value & 0xFFFFFF;
  if (rgb == 0x000000) return c; // سێبەر و ماسک
  final hit = _pairs[rgb];
  if (hit != null) return Color(hit | 0xFF000000).withAlpha(a);
  final hsl = HSLColor.fromColor(Color(rgb | 0xFF000000));
  final s = hsl.saturation, l = hsl.lightness;
  const lp = VexPal.lightPal;
  if (l > 0.88) return lp.tx.withAlpha(a); // نزیک-سپی (دەق/هایلایت) ← ڕەنگی دەق
  if (s < 0.22) {
    // خۆڵەمێشی: ڕووناک ← دەق ؛ تاریک ← زەمینە ؛ ناوەند ← muted
    if (l > 0.8) return lp.tx.withAlpha(a);
    if (l < 0.22) return (a < 128 ? lp.tx : lp.bg).withAlpha(a);
    return lp.mu.withAlpha(a);
  }
  if (l < 0.28) {
    // تۆخی ڕەنگاوڕەنگ (زەمینەی کارت / سێبەر) ← زۆر ڕووناک
    return hsl.withLightness(0.95).withSaturation(s < 0.35 ? s : 0.3).toColor().withAlpha(a);
  }
  // ڕەنگی لێدراو (accent) ← هەمان hue، تا ئەو ڕادەیە تۆخ کە دەق/ئایکۆن لەسەر زەمینەی ڕووناک بخوێنرێتەوە
  return _darkenTo(hsl, 0.15).withAlpha(a);
}

Color _darkenTo(HSLColor hsl, double maxLum) {
  final s = hsl.saturation > 0.85 ? 0.85 : hsl.saturation;
  var c = hsl.withSaturation(s).toColor();
  if (c.computeLuminance() <= maxLum) return c;
  double lo = 0.12, hi = hsl.lightness;
  for (int i = 0; i < 12; i++) {
    final mid = (lo + hi) / 2;
    c = hsl.withSaturation(s).withLightness(mid).toColor();
    if (c.computeLuminance() > maxLum) {
      hi = mid;
    } else {
      lo = mid;
    }
  }
  return hsl.withSaturation(s).withLightness(lo).toColor();
}

// ============================================================
//  گۆڕینی دۆخ — دوگمەی سێ بەشی (خۆکار / ڕووناک / تاریک)
// ============================================================
class ThemeModePicker extends StatelessWidget {
  const ThemeModePicker({super.key, this.labels = const ['خۆکار', 'ڕووناک', 'تاریک']});
  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: VexTheme.I,
      builder: (context, _) {
        final p = VexTheme.I.p;
        final cur = VexTheme.I.mode;
        const modes = [VexMode.auto, VexMode.light, VexMode.dark];
        return Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: p.surf2,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: p.line),
          ),
          child: Row(
            children: [
              for (int i = 0; i < 3; i++)
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => VexTheme.I.setMode(modes[i]),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: cur == modes[i] ? p.cy.withAlpha(p.dark ? 40 : 30) : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: cur == modes[i] ? p.cy.withAlpha(p.dark ? 120 : 110) : Colors.transparent),
                      ),
                      child: VText(
                        labels[i],
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                          color: cur == modes[i] ? p.cy : p.mu,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

// ============================================================
//  «دورگە»ی تاریک — پەڕەی VEX Plus هەمیشە بە شێوازی تاریکی پریمیۆم دەمێنێتەوە
//  (هەمان ڕەنگە const ـەکانی پێشوو؛ apply.py خۆی V.* ← VD.* دەکات لەو فایلانەی ISLAND)
// ============================================================
class VD {
  VD._();
  static const Color bg = Color(0xFF04202A);
  static const Color surf = Color(0x940C3A48);
  static const Color surf2 = Color(0x0EFFFFFF);
  static const Color line = Color(0x218CEBF5);
  static const Color line2 = Color(0x428CEBF5);
  static const Color cy = Color(0xFF2FE6F3);
  static const Color c2 = Color(0xFF8FF3F9);
  static const Color mint = Color(0xFF3CF08A);
  static const Color violet = Color(0xFF9B7BFF);
  static const Color coral = Color(0xFFFF5F7E);
  static const Color amber = Color(0xFFFFBE4D);
  static const Color orange = Color(0xFFFF9466);
  static const Color tx = Color(0xFFEFFEFF);
  static const Color mu = Color(0xFF8CB7BF);
  static const Color track = Color(0x14FFFFFF);
  static const Color nav = Color(0xE606242E);
  static const Color sheet = Color(0xFF062A35);
  static const Color ink = Color(0xFF04323A);
}

/// دۆخی ڕووناک بۆ سپلاش/Plus نییە؛ بۆ SystemUi لە دورگەی تاریک
const SystemUiOverlayStyle kDarkIslandChrome = SystemUiOverlayStyle(
  statusBarColor: Colors.transparent,
  statusBarIconBrightness: Brightness.light,
  statusBarBrightness: Brightness.dark,
  systemNavigationBarColor: Color(0xFF04161C),
  systemNavigationBarIconBrightness: Brightness.light,
);
