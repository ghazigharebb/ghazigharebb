// VEX Health — ڕەنگ، فۆنت و پارچە هاوبەشەکان
import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'vex_theme.dart';
import 'vx_en.dart';

export 'vex_theme.dart' show VexTheme, VexMode, VexPal, ThemeModePicker, VD, kDarkIslandChrome, vk, vkRGBO, vkARGB, kW, kOnAcc, kOnPrime, vexHex, vexMapHex, vexCache;
export 'vx_en.dart' show VText, vxTr, vxSpan, kIsEn, kIsBd, kIsAr, kIsFa, kIsTr, kIsLtr, kDir, LangScope;

/// Navigator ـی سەرەکی — بۆ کردنەوەی شیت و تۆست لە هەر شوێنێکەوە
final GlobalKey<NavigatorState> navKey = GlobalKey<NavigatorState>();

/// ڕەنگەکانی دیزاین (هەمان ڕەنگەکانی وێبەکە)
class V {
  V._();
  static Color get bg => VexTheme.I.p.bg;
  static Color get surf => VexTheme.I.p.surf;
  static Color get surf2 => VexTheme.I.p.surf2;
  static Color get line => VexTheme.I.p.line;
  static Color get line2 => VexTheme.I.p.line2;
  static Color get cy => VexTheme.I.p.cy;
  static Color get c2 => VexTheme.I.p.c2;
  static Color get mint => VexTheme.I.p.mint;
  static Color get violet => VexTheme.I.p.violet;
  static Color get coral => VexTheme.I.p.coral;
  static Color get amber => VexTheme.I.p.amber;
  static Color get orange => VexTheme.I.p.orange;
  static Color get tx => VexTheme.I.p.tx;
  static Color get mu => VexTheme.I.p.mu;
  static Color get track => VexTheme.I.p.track;
  static Color get nav => VexTheme.I.p.nav;
  static Color get sheet => VexTheme.I.p.sheet;
  static Color get ink => VexTheme.I.p.ink;
  static const LinearGradient prime = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF8FF3F9), Color(0xFF3CF08A)],
  );
  static const LinearGradient ai = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF7B4DFF), Color(0xFF4D6BFF), Color(0xFF14B8D6)],
    stops: [0.0, 0.45, 1.0],
  );
}

// ---------- یارمەتیدەرەکان ----------
Color op(Color c, double o) => c.withAlpha((clampD(o, 0, 1) * 255).round());
Color mix(Color a, Color b, double t) => Color.lerp(a, b, t) ?? a;
double clampD(double v, double lo, double hi) => v < lo ? lo : (v > hi ? hi : v);
int clampI(int v, int lo, int hi) => v < lo ? lo : (v > hi ? hi : v);
double rad(double deg) => deg * 3.141592653589793 / 180.0;

/// دەقی کوردی
TextStyle ku(double size, {FontWeight w = FontWeight.w400, Color? c, double? h, List<Shadow>? shadows}) { c ??= V.tx; return kIsLtr
    // English: فۆنتی Sora و هێڵی نزمتر (دیزاینی کوردی بۆ پیتی عەرەبی گەورەتر بوو)
    ? GoogleFonts.sora(fontSize: size, fontWeight: w, color: c, height: h == null ? null : h * 0.86, shadows: shadows)
    : GoogleFonts.notoSansArabic(fontSize: size, fontWeight: w, color: c, height: h, shadows: shadows); }

/// ژمارە (Sora)
TextStyle nu(double size, {FontWeight w = FontWeight.w800, Color? c, double? h, double? ls}) { c ??= V.tx; return
    GoogleFonts.sora(fontSize: size, fontWeight: w, color: c, height: h, letterSpacing: ls); }

/// ژمارە لەناو دەقی کوردیدا وەک خۆی (چەپ بۆ ڕاست) دەمێنێتەوە
String ltr(String s) => '⁦$s⁩';
String pad2(int n) => n.toString().padLeft(2, '0');
String nowHM() {
  final d = DateTime.now();
  return '${pad2(d.hour)}:${pad2(d.minute)}';
}

String fmt(num v) {
  final n = v.round();
  final s = n.abs().toString();
  final b = StringBuffer();
  for (int i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
    b.write(s[i]);
  }
  return (n < 0 ? '-' : '') + b.toString();
}

const List<String> kDays = ['یەکشەممە', 'دووشەممە', 'سێشەممە', 'چوارشەممە', 'پێنجشەممە', 'هەینی', 'شەممە'];
const List<String> kMonths = [
  'کانوونی دووەم', 'شوبات', 'ئازار', 'نیسان', 'ئایار', 'حوزەیران',
  'تەممووز', 'ئاب', 'ئەیلوول', 'تشرینی یەکەم', 'تشرینی دووەم', 'کانوونی یەکەم'
];
/// «پێنجشەممە، 22/10/2026» — ڕۆژ و بەروار لە کاتی ئامێرەکەوە (weekday: 1=دووشەممە … 7=یەکشەممە)
String kurdishDate() {
  final t = DateTime.now();
  final dd = t.day.toString().padLeft(2, '0');
  final mm = t.month.toString().padLeft(2, '0');
  // \u2066 … \u2069 = ڕاستەوخۆ چەپ‌بۆ‌ڕاست، تا 22/10 نەگۆڕدرێت بۆ 10/22
  return '${kDays[t.weekday % 7]}، \u2066$dd/$mm/${t.year}\u2069';
}

BoxDecoration box({double r = 14, Color? color, Color? border}) => BoxDecoration(
      color: color ?? V.surf2,
      borderRadius: BorderRadius.circular(r),
      border: Border.all(color: border ?? V.line),
    );

// ---------- کارت ----------
class VCard extends StatelessWidget {
  const VCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin = const EdgeInsets.only(top: 14),
    this.radius = 26,
  });
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: margin,
      child: CustomPaint(
        foregroundPainter: _GradBorder(radius),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(color: V.surf, borderRadius: BorderRadius.circular(radius)),
          child: child,
        ),
      ),
    );
  }
}

class _GradBorder extends CustomPainter {
  _GradBorder(this.r);
  final double r;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..shader = LinearGradient(
        begin: Alignment(-0.6, -1),
        end: Alignment(0.6, 1),
        colors: [V.line2, Color(0x008CEBF5)],
        stops: [0.0, 0.6],
      ).createShader(rect);
    canvas.drawRRect(RRect.fromRectAndRadius(rect.deflate(0.5), Radius.circular(r)), p);
  }

  @override
  bool shouldRepaint(covariant _GradBorder oldDelegate) => oldDelegate.r != r;
}

/// سەردێڕی کارت + بەستەر
class CardTitle extends StatelessWidget {
  const CardTitle(this.title, {super.key, this.link, this.onLink});
  final String title;
  final String? link;
  final VoidCallback? onLink;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(child: VText(title, style: ku(16, w: FontWeight.w800))),
          if (link != null) LinkBtn(link!, onTap: onLink),
        ],
      ),
    );
  }
}

class LinkBtn extends StatelessWidget {
  const LinkBtn(this.label, {super.key, this.onTap});
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: VText(label, style: ku(12, w: FontWeight.w700, c: V.cy)),
      ),
    );
  }
}

// ---------- دوگمە ----------
class Press extends StatefulWidget {
  const Press({super.key, required this.child, this.onTap, this.scale = 0.97});
  final Widget child;
  final VoidCallback? onTap;
  final double scale;

  @override
  State<Press> createState() => _PressState();
}

class _PressState extends State<Press> {
  bool _down = false;

  void _set(bool v) {
    if (_down != v && mounted) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: enabled ? (_) => _set(true) : null,
      onTapUp: enabled ? (_) => _set(false) : null,
      onTapCancel: enabled ? () => _set(false) : null,
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _down ? widget.scale : 1.0,
        duration: const Duration(milliseconds: 120),
        child: widget.child,
      ),
    );
  }
}

enum BtnKind { prime, soft, ai }

class VBtn extends StatelessWidget {
  const VBtn(this.label, {super.key, this.kind = BtnKind.soft, this.onTap, this.fontSize = 14});
  final String label;
  final BtnKind kind;
  final VoidCallback? onTap;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    BoxDecoration d;
    Color fg;
    if (kind == BtnKind.prime) {
      d = BoxDecoration(gradient: V.prime, borderRadius: BorderRadius.circular(15));
      fg = V.ink;
    } else if (kind == BtnKind.ai) {
      d = BoxDecoration(gradient: V.ai, borderRadius: BorderRadius.circular(15));
      fg = Colors.white;
    } else {
      d = BoxDecoration(color: V.surf2, borderRadius: BorderRadius.circular(15), border: Border.all(color: V.line));
      fg = V.tx;
    }
    return Press(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: d,
        child: VText(label, textAlign: TextAlign.center, style: ku(fontSize, w: FontWeight.w800, c: fg)),
      ),
    );
  }
}

// ---------- جووڵەی هاتنە ژوورەوە ----------
class Rise extends StatefulWidget {
  const Rise({super.key, required this.child, this.delayMs = 0});
  final Widget child;
  final int delayMs;

  @override
  State<Rise> createState() => _RiseState();
}

class _RiseState extends State<Rise> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
  Timer? _t;

  @override
  void initState() {
    super.initState();
    _t = Timer(Duration(milliseconds: widget.delayMs), () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        final v = Curves.easeOutCubic.transform(_c.value);
        return Opacity(
          opacity: v,
          child: Transform.translate(offset: Offset(0, 14 * (1 - v)), child: child),
        );
      },
      child: widget.child,
    );
  }
}

/// خاڵی زیندوو (چاوتروکاندن)
class BlinkDot extends StatefulWidget {
  BlinkDot({super.key, this.size = 8, Color? color, this.glow = false}) : color = color ?? V.mint;
  final double size;
  final Color color;
  final bool glow;

  @override
  State<BlinkDot> createState() => _BlinkDotState();
}

class _BlinkDotState extends State<BlinkDot> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 800))..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 1, end: 0.35).animate(_c),
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: widget.color,
          boxShadow: widget.glow ? [BoxShadow(color: widget.color, blurRadius: 8)] : null,
        ),
      ),
    );
  }
}

// ---------- تۆست ----------
OverlayEntry? _toastEntry;
Timer? _toastTimer;

void toast(String msg) {
  final overlay = navKey.currentState?.overlay;
  if (overlay == null) return;
  _toastTimer?.cancel();
  _toastEntry?.remove();
  _toastEntry = null;
  final entry = OverlayEntry(builder: (_) => _ToastView(msg: msg));
  _toastEntry = entry;
  overlay.insert(entry);
  _toastTimer = Timer(Duration(milliseconds: msg.length > 40 ? 3400 : 2000), () {
    if (_toastEntry == entry) {
      entry.remove();
      _toastEntry = null;
    }
  });
}

class _ToastView extends StatelessWidget {
  const _ToastView({required this.msg});
  final String msg;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom + 150;
    return Positioned(
      left: 24,
      right: 24,
      bottom: bottom,
      child: IgnorePointer(
        child: Material(
          type: MaterialType.transparency,
          child: Center(
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: 1),
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeOutCubic,
              builder: (context, v, child) => Opacity(
                opacity: v,
                child: Transform.translate(offset: Offset(0, 20 * (1 - v)), child: child),
              ),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 380),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
                decoration: BoxDecoration(
                  gradient: V.prime,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 20, offset: Offset(0, 8))],
                ),
                child: VText(
                  msg,
                  textAlign: TextAlign.center,
                  style: ku(13, w: FontWeight.w800, c: V.ink, h: 1.7),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------- شیتی خوارەوە ----------
Future<T?> showVSheet<T>({required WidgetBuilder builder, bool plain = false, Color? color}) { color ??= V.sheet;
  final ctx = navKey.currentContext;
  if (ctx == null) return Future<T?>.value(null);
  return showModalBottomSheet<T>(
    context: ctx,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: const Color(0x9E010C10),
    elevation: 0,
    builder: (c) => VSheet(plain: plain, color: color, child: builder(c)),
  );
}

class VSheet extends StatelessWidget {
  VSheet({super.key, required this.child, this.plain = false, Color? color}) : color = color ?? V.sheet;
  final Widget child;
  final bool plain;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    const radius = BorderRadius.vertical(top: Radius.circular(30));
    return Padding(
      padding: EdgeInsets.only(bottom: mq.viewInsets.bottom),
      child: Container(
        constraints: BoxConstraints(maxHeight: mq.size.height * 0.92),
        decoration: BoxDecoration(color: color, borderRadius: radius, border: Border.all(color: V.line2)),
        child: ClipRRect(
          borderRadius: radius,
          child: SingleChildScrollView(
            padding: plain
                ? EdgeInsets.only(bottom: mq.padding.bottom + 18)
                : EdgeInsets.fromLTRB(16, 12, 16, mq.padding.bottom + 22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (!plain)
                  Center(
                    child: Container(
                      width: 46,
                      height: 5,
                      margin: const EdgeInsets.only(bottom: 14),
                      decoration: BoxDecoration(color: V.line2, borderRadius: BorderRadius.circular(9)),
                    ),
                  ),
                child,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class SheetTitle extends StatelessWidget {
  const SheetTitle(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: VText(text, style: ku(19, w: FontWeight.w800)),
    );
  }
}

/// ژمارەی گەورە + ڕوونکردنەوە
class DBig extends StatelessWidget {
  DBig(this.value, this.sub, {super.key, Color? color}) : color = color ?? V.mint;
  final String value;
  final String sub;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          VText(value, textDirection: TextDirection.ltr, style: nu(46, c: color, h: 1.1)),
          const SizedBox(width: 8),
          Flexible(child: VText(sub, style: ku(13, c: V.mu))),
        ],
      ),
    );
  }
}

class K3Item {
  const K3Item(this.label, this.value, {this.isNum = true, this.labelColor});
  final String label;
  final String value;
  final bool isNum;
  final Color? labelColor;
}

/// سێ خانەی بچووک
class K3 extends StatelessWidget {
  const K3(this.items, {super.key});
  final List<K3Item> items;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        children: [
          for (int i = 0; i < items.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                decoration: box(r: 14),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    VText(items[i].label,
                        textAlign: TextAlign.center,
                        style: ku(11, w: FontWeight.w700, c: items[i].labelColor ?? V.mu)),
                    const SizedBox(height: 2),
                    VText(
                      items[i].value,
                      textAlign: TextAlign.center,
                      textDirection: items[i].isNum ? TextDirection.ltr : null,
                      style: items[i].isNum ? nu(17) : ku(17, w: FontWeight.w800),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// بۆکسی تێبینی
class Note extends StatelessWidget {
  const Note(this.child, {super.key, this.top = 12});
  final Widget child;
  final double top;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(top: top),
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
      decoration: box(r: 15),
      child: DefaultTextStyle.merge(style: ku(13, h: 1.8), child: child),
    );
  }
}

/// ستوونەکان
class BarsChart extends StatelessWidget {
  const BarsChart(this.values, this.color, this.min, this.max, {super.key});
  final List<double> values;
  final Color color;
  final double min;
  final double max;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 120,
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (int i = 0; i < values.length; i++) ...[
              if (i > 0) const SizedBox(width: 4),
              Expanded(
                child: Container(
                  height: 120 * clampD((values[i] - min) / (max - min), 0.06, 1),
                  decoration: BoxDecoration(
                    color: op(color, 0.9),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(5), bottom: Radius.circular(2)),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// پاشبنەمای ڕووناکی سەرەوە
class Aurora extends StatelessWidget {
  const Aurora({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(child: ColoredBox(color: V.bg)),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0, -1.16),
                radius: 0.95,
                colors: [Color(0x2E2FE6F3), Color(0x002FE6F3)],
                stops: [0.0, 0.7],
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(1, -0.2),
                radius: 0.8,
                colors: [Color(0x123CF08A), Color(0x003CF08A)],
                stops: [0.0, 0.7],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// شووشەی تەڵخ (blur)
class Glass extends StatelessWidget {
  Glass({super.key, required this.child, this.radius = 26, this.sigma = 18, Color? color, Color? border}) : color = color ?? V.nav, border = border ?? V.line;
  final Widget child;
  final double radius;
  final double sigma;
  final Color color;
  final Color border;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
        child: Container(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: border),
          ),
          child: child,
        ),
      ),
    );
  }
}
