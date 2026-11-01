// VEX AI Food v2 — پارچە هاوبەشەکان
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../core/theme.dart';
import 'food_ai_data.dart';
import 'food_ai_store.dart';

const Color kPro = Color(0xFF7FB8FF);
const Color kCarb = Color(0xFFFFC35C);
const Color kFat = Color(0xFFFF7A8A);
const Color kWarn = Color(0xFFFFB347);
const Color kInk = Color(0xFF04252B);
const Color kCy = Color(0xFF2FE6F3);
const Color kMint = Color(0xFF3CF08A);
const String kWood = 'assets/food_ai/wood.jpg';

const Curve kEase = Cubic(0.2, 0.9, 0.2, 1);
const Curve kSpring = Cubic(0.2, 1.5, 0.4, 1);

/// ئایکۆنەکان (24×24)
class FI {
  FI._();
  static const x = '<path d="M6 6l12 12M18 6L6 18"/>';
  static const back = '<path d="M9 6l6 6-6 6"/>';
  static const cam = '<path d="M4 8h3l2-3h6l2 3h3v11H4z"/><circle cx="12" cy="13" r="3.5"/>';
  static const gal = '<rect x="4" y="5" width="16" height="14" rx="3"/><path d="M4 16l5-5 4 4 3-3 4 4"/>';
  static const edit = '<path d="M5 19h4L19 9l-4-4L5 15z"/>';
  static const trash = '<path d="M5 7h14M10 7V4h4v3M7 7l1 13h8l1-13"/>';
  static const clock = '<circle cx="12" cy="12" r="8"/><path d="M12 8v4l3 2"/>';
  static const spark = '<path d="M12 2l2.2 6.2L20 10l-5.8 1.8L12 18l-2.2-6.2L4 10l5.8-1.8z"/>';
  static const plus = '<path d="M12 5v14M5 12h14"/>';
  static const check = '<path d="M5 12.5l4.5 4.5L19 7.5"/>';
  static const save = '<path d="M7 4h10v16l-5-3.6L7 20z"/>';
  static const chev = '<path d="M7 10l5 5 5-5"/>';
}

Widget ic(String inner, Color c, {double size = 20, double stroke = 2.1, bool fill = false}) {
  final h = vexHex(c);
  return SvgPicture.string(
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="${fill ? h : 'none'}" stroke="${fill ? 'none' : h}" '
    'stroke-width="$stroke" stroke-linecap="round" stroke-linejoin="round">$inner</svg>',
    width: size,
    height: size,
  );
}

/// ژمارە بە ڕەقەمی ئینگلیزی لەناو دەقی کوردیدا
String n0(num v) => ltr(fmt(v));
String g0(double v) => v >= 10 || v == 0 ? '${v.round()}' : v.toStringAsFixed(1);

// ─────────────────────────── وێنەکان ───────────────────────────

/// وێنەی PNG ی خواردن (بێ باگراوند)
class DishPng extends StatelessWidget {
  const DishPng(this.d, {super.key, required this.size});
  final FDish d;
  final double size;

  @override
  Widget build(BuildContext context) {
    Widget fb() => Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(shape: BoxShape.circle, color: op(V.cy, 0.10), border: Border.all(color: op(V.cy, 0.3))),
          child: ic(FI.spark, V.cy, size: size * .36, fill: true),
        );
    if (d.img != null) {
      return Image.asset(d.img!, width: size, height: size, fit: BoxFit.contain, filterQuality: FilterQuality.medium, gaplessPlayback: true,
          errorBuilder: (_, __, ___) => fb());
    }
    if (d.net != null) {
      return Image.network(d.net!, width: size, height: size, fit: BoxFit.contain, errorBuilder: (_, __, ___) => fb());
    }
    return fb();
  }
}

/// «وێنەی کامێرا»: خواردنەکە لەسەر مێزی دار (نموونە) یان وێنەی ڕاستەقینە
class ShotView extends StatelessWidget {
  const ShotView({super.key, required this.shot, this.zoom = 1.0, this.rot = 0});
  final FShot shot;
  final double zoom;
  final double rot;

  @override
  Widget build(BuildContext context) {
    final b = shot.bytes;
    if (b != null) return Image.memory(b, fit: BoxFit.cover, gaplessPlayback: true);
    final d = dishById(shot.sample ?? '');
    return LayoutBuilder(builder: (context, c) {
      final s = math.min(c.maxWidth, c.maxHeight) * 0.92 * zoom;
      return Stack(fit: StackFit.expand, children: [
        Image.asset(kWood, fit: BoxFit.cover),
        if (d != null)
          Center(
            child: Transform.rotate(
              angle: rot,
              child: Container(
                decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withAlpha(110), blurRadius: s * .08, offset: Offset(0, s * .04))]),
                child: DishPng(d, size: s),
              ),
            ),
          ),
      ]);
    });
  }
}

/// باگراوندی چوارخانە (نیشانەی PNG ی بێ باگراوند)
class CheckerBox extends StatelessWidget {
  const CheckerBox({super.key, this.child, this.radius = 16, this.cell = 6});
  final Widget? child;
  final double radius;
  final double cell;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: CustomPaint(painter: _Checker(cell), child: child),
    );
  }
}

class _Checker extends CustomPainter {
  _Checker(this.cell);
  final double cell;
  @override
  void paint(Canvas canvas, Size size) {
    final light = VexTheme.I.isLight;
    canvas.drawRect(Offset.zero & size, Paint()..color = light ? const Color(0xFFEFF4F5) : const Color(0xFF16343B));
    final p = Paint()..color = light ? const Color(0xFFE1EAEC) : const Color(0xFF1F444C);
    for (var y = 0.0; y < size.height; y += cell) {
      for (var x = ((y / cell).round().isOdd ? cell : 0.0); x < size.width; x += cell * 2) {
        canvas.drawRect(Rect.fromLTWH(x, y, cell, cell), p);
      }
    }
  }

  @override
  bool shouldRepaint(_Checker o) => o.cell != cell;
}

/// وێنۆچکەی خواردن: سەرەتا وێنەی کامێرا، پاشان PNG (لە پشتەوە ئامادە دەبێت — کەس چاوەڕێ ناکات)
class ItemThumb extends StatelessWidget {
  const ItemThumb({super.key, required this.item, required this.shot, this.size = 58});
  final FItem item;
  final FShot? shot;
  final double size;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<double>(
      valueListenable: item.png,
      builder: (context, v, _) {
        final ready = v >= 1;
        final r = size * .28;
        return SizedBox(
          width: size,
          height: size,
          child: Stack(clipBehavior: Clip.none, children: [
            // وێنەی کامێرا
            Positioned.fill(
              child: AnimatedOpacity(
                opacity: ready ? 0 : 1,
                duration: const Duration(milliseconds: 600),
                child: AnimatedScale(
                  scale: ready ? 1.25 : 1,
                  duration: const Duration(milliseconds: 700),
                  curve: kEase,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(r),
                    child: shot == null
                        ? ColoredBox(color: const Color(0xFF3A2414), child: Center(child: DishPng(item.dish, size: size * 1.1)))
                        : ShotView(shot: shot!, zoom: 1.25),
                  ),
                ),
              ),
            ),
            // PNG
            Positioned.fill(
              child: AnimatedOpacity(
                opacity: ready ? 1 : 0,
                duration: const Duration(milliseconds: 600),
                child: AnimatedScale(
                  scale: ready ? 1 : 0.5,
                  duration: const Duration(milliseconds: 700),
                  curve: kSpring,
                  child: CheckerBox(radius: r, child: Center(child: DishPng(item.dish, size: size * .92))),
                ),
              ),
            ),
            // ئامادەکردنی PNG
            if (!ready && v > 0)
              Center(
                child: SizedBox(
                  width: 26,
                  height: 26,
                  child: CustomPaint(painter: _ProgRing(v)),
                ),
              ),
            // درەوشانەوە کاتێک PNG ئامادە دەبێت
            if (ready)
              Positioned.fill(
                child: IgnorePointer(
                  child: TweenAnimationBuilder<double>(
                    key: ValueKey<String>('spark-${item.dish.id}'),
                    tween: Tween(begin: 1, end: 0),
                    duration: const Duration(milliseconds: 1000),
                    builder: (context, a, _) => Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(r),
                        border: Border.all(color: kCy.withAlpha((a * 255).round()), width: 2),
                        boxShadow: [BoxShadow(color: kCy.withAlpha((a * 200).round()), blurRadius: 18)],
                      ),
                    ),
                  ),
                ),
              ),
          ]),
        );
      },
    );
  }
}

class _ProgRing extends CustomPainter {
  _ProgRing(this.v);
  final double v;
  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2 - 2;
    canvas.drawCircle(c, r + 1.5, Paint()..color = const Color(0xCC04252B));
    canvas.drawCircle(c, r - 1, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = const Color(0x33FFFFFF));
    canvas.drawArc(Rect.fromCircle(center: c, radius: r - 1), -math.pi / 2, math.pi * 2 * v, false, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..color = kCy);
  }

  @override
  bool shouldRepaint(_ProgRing o) => o.v != v;
}

// ─────────────────────────── ژمارە و بار ───────────────────────────

/// ژمارەی جووڵاو (کاتێک دەگۆڕێت دەژمێرێت)
class CountNum extends StatelessWidget {
  const CountNum(this.value, {super.key, required this.style, this.ms = 650});
  final double value;
  final TextStyle style;
  final int ms;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(end: value),
      duration: Duration(milliseconds: ms),
      curve: Curves.easeOutCubic,
      builder: (context, v, _) => Text(fmt(v), style: style, textDirection: TextDirection.ltr),
    );
  }
}

/// باری پرۆتین / کاربۆهیدرات / چەوری
class MacroBar extends StatelessWidget {
  const MacroBar({super.key, required this.n, this.h = 10});
  final FNut n;
  final double h;

  @override
  Widget build(BuildContext context) {
    final p = n.p * 4, c = n.c * 4, f = n.f * 9;
    final s = math.max(1.0, p + c + f);
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: Container(
        height: h,
        color: V.track,
        child: LayoutBuilder(builder: (context, k) {
          Widget seg(double v, Color col) => AnimatedContainer(
                duration: const Duration(milliseconds: 600),
                curve: kEase,
                width: k.maxWidth * v / s,
                color: col,
              );
          return Row(textDirection: TextDirection.ltr, children: [seg(p, kPro), seg(c, kCarb), seg(f, kFat)]);
        }),
      ),
    );
  }
}

class MacroLegend extends StatelessWidget {
  const MacroLegend({super.key, required this.n});
  final FNut n;

  @override
  Widget build(BuildContext context) {
    Widget it(String l, double v, Color c) => Row(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(3))),
          const SizedBox(width: 4),
          Text(l, style: ku(11.5, c: V.mu)),
          const SizedBox(width: 4),
          Text('${v.round()}g', style: nu(12.5, w: FontWeight.w700), textDirection: TextDirection.ltr),
        ]);
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      it('پرۆتین', n.p, kPro),
      it('کاربۆهیدرات', n.c, kCarb),
      it('چەوری', n.f, kFat),
    ]);
  }
}

/// + / − بە وشەی ڕوون
class QtyStepper extends StatelessWidget {
  const QtyStepper({super.key, required this.word, required this.onMinus, required this.onPlus, required this.dir, this.idx = 0});
  final String word;
  final VoidCallback onMinus;
  final VoidCallback onPlus;

  /// ئاراستەی دوایین گۆڕان (بۆ جووڵەی وشەکە)
  final int dir;
  final int idx;

  @override
  Widget build(BuildContext context) {
    Widget b(String t, VoidCallback f, String k) => Press(
          key: ValueKey<String>(k),
          onTap: f,
          scale: 0.86,
          child: SizedBox(width: 36, height: 32, child: Center(child: Text(t, style: nu(20, w: FontWeight.w700, c: V.cy)))),
        );
    return Container(
      height: 34,
      decoration: BoxDecoration(color: VexTheme.I.isLight ? V.surf2 : const Color(0xFF0B2329), borderRadius: BorderRadius.circular(99), border: Border.all(color: V.line)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        b('−', onMinus, 'fa-minus-$idx'),
        SizedBox(
          width: 104,
          height: 32,
          child: ClipRect(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              switchInCurve: kEase,
              switchOutCurve: kEase,
              transitionBuilder: (child, a) {
                final incoming = child.key == ValueKey<String>(word);
                final from = incoming ? (dir > 0 ? -1.0 : 1.0) : (dir > 0 ? 1.0 : -1.0);
                return FadeTransition(
                  opacity: a,
                  child: SlideTransition(
                    position: Tween<Offset>(begin: Offset(0, from), end: Offset.zero).animate(a),
                    child: child,
                  ),
                );
              },
              child: Center(
                key: ValueKey<String>(word),
                child: FittedBox(fit: BoxFit.scaleDown, child: Text(word, maxLines: 1, style: ku(13.5, w: FontWeight.w700))),
              ),
            ),
          ),
        ),
        b('+', onPlus, 'fa-plus-$idx'),
      ]),
    );
  }
}

// ─────────────────────────── بازنە و پای ───────────────────────────

class KcalRing extends StatelessWidget {
  const KcalRing({super.key, required this.v, required this.goal, this.size = 104, this.stroke = 10});
  final double v;
  final double goal;
  final double size;
  final double stroke;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: v),
      duration: const Duration(milliseconds: 1400),
      curve: kEase,
      builder: (context, x, _) => SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: _Ring(goal <= 0 ? 0 : (x / goal).clamp(0.0, 1.0).toDouble(), stroke, V.track),
          child: Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text(fmt(x), style: nu(size * .18, c: V.tx), textDirection: TextDirection.ltr),
              Text('لە ${n0(goal)}', style: ku(size * .087, c: V.mu, h: 1.2)),
            ]),
          ),
        ),
      ),
    );
  }
}

class _Ring extends CustomPainter {
  _Ring(this.f, this.w, this.track);
  final double f;
  final double w;
  final Color track;
  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2 - w / 2;
    canvas.drawCircle(c, r, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = w
      ..color = track);
    if (f <= 0) return;
    final rect = Rect.fromCircle(center: c, radius: r);
    canvas.drawArc(rect, -math.pi / 2, math.pi * 2 * f, false, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = w
      ..strokeCap = StrokeCap.round
      ..shader = const SweepGradient(colors: [kCy, kMint, kCy], transform: GradientRotation(-math.pi / 2)).createShader(rect));
  }

  @override
  bool shouldRepaint(_Ring o) => o.f != f || o.track != track;
}

/// پای بۆ بڕ (چارەک، نیو، یەک، یەک و نیو، دوو)
class PortionPie extends StatelessWidget {
  const PortionPie(this.f, {super.key, required this.on});
  final double f;
  final bool on;

  @override
  Widget build(BuildContext context) => SizedBox(width: 36, height: 26, child: CustomPaint(painter: _Pie(f, on ? kCy : V.cy, V.mu)));
}

class _Pie extends CustomPainter {
  _Pie(this.f, this.fill, this.line);
  final double f;
  final Color fill;
  final Color line;

  void _one(Canvas c, Offset o, double r, double x) {
    c.drawCircle(o, r + 2, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = line.withAlpha(150));
    final p = Paint()..color = fill;
    if (x >= 1) {
      c.drawCircle(o, r, p);
    } else if (x > 0) {
      c.drawArc(Rect.fromCircle(center: o, radius: r), -math.pi / 2, math.pi * 2 * x, true, p);
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final cy = size.height / 2;
    if (f <= 1) {
      _one(canvas, Offset(size.width / 2, cy), 8, f);
    } else {
      _one(canvas, Offset(size.width / 2 - 7, cy), 7, 1);
      _one(canvas, Offset(size.width / 2 + 9, cy), 5.5, f - 1);
    }
  }

  @override
  bool shouldRepaint(_Pie o) => o.f != f || o.fill != fill;
}

// ─────────────────────────── شیت ───────────────────────────

Future<T?> showFoodSheet<T>(BuildContext context, Widget Function(BuildContext) b) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    backgroundColor: Colors.transparent,
    barrierColor: const Color(0x99010709),
    builder: (ctx) => Directionality(
     textDirection: TextDirection.rtl,
     child: Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: VexTheme.I.isLight ? V.sheet : const Color(0xFF0F262D),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          border: Border.all(color: V.line),
        ),
        padding: EdgeInsets.fromLTRB(16, 10, 16, 22 + MediaQuery.of(ctx).padding.bottom),
        child: SafeArea(
          top: false,
          bottom: false,
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Center(child: Container(width: 44, height: 5, margin: const EdgeInsets.only(top: 2, bottom: 12), decoration: BoxDecoration(color: V.line2, borderRadius: BorderRadius.circular(5)))),
            Flexible(child: SingleChildScrollView(child: b(ctx))),
          ]),
        ),
      ),
     ),
    ),
  );
}

/// دوگمەی سەرەکی (cyan → mint)
class GradBtn extends StatelessWidget {
  const GradBtn({super.key, required this.label, required this.onTap, this.icon, this.pad = const EdgeInsets.all(15), this.size = 15.5, this.enabled = true});
  final String label;
  final VoidCallback? onTap;
  final String? icon;
  final EdgeInsets pad;
  final double size;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Press(
      onTap: enabled ? onTap : null,
      child: AnimatedOpacity(
        opacity: enabled ? 1 : 0.4,
        duration: const Duration(milliseconds: 250),
        child: Container(
          padding: pad,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [kCy, kMint]),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [BoxShadow(color: kCy.withAlpha(enabled ? 90 : 0), blurRadius: 24, offset: const Offset(0, 10), spreadRadius: -10)],
          ),
          child: Row(mainAxisSize: MainAxisSize.min, mainAxisAlignment: MainAxisAlignment.center, children: [
            if (icon != null) ...[ic(icon!, kInk, size: size + 2, stroke: 2.4), const SizedBox(width: 7)],
            Flexible(child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: ku(size, w: FontWeight.w800, c: kInk))),
          ]),
        ),
      ),
    );
  }
}

/// دوگمەی لاوەکی
class SoftBtn extends StatelessWidget {
  const SoftBtn({super.key, required this.label, required this.onTap, this.icon, this.color, this.on = false});
  final String label;
  final VoidCallback? onTap;
  final String? icon;
  final Color? color;
  final bool on;

  @override
  Widget build(BuildContext context) {
    final c = color ?? V.tx;
    return Press(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
        decoration: BoxDecoration(
          color: on ? op(V.cy, 0.14) : V.surf,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: on ? V.cy : V.line),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, mainAxisAlignment: MainAxisAlignment.center, children: [
          if (icon != null) ...[ic(icon!, on ? V.cy : c, size: 16), const SizedBox(width: 6)],
          Flexible(child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: ku(12.5, w: FontWeight.w700, c: on ? V.cy : c))),
        ]),
      ),
    );
  }
}

class FChip extends StatelessWidget {
  const FChip({super.key, required this.child, this.color, this.dark = false});
  final Widget child;
  final Color? color;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final c = color ?? V.cy;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: dark ? const Color(0xCC04252B) : op(c, 0.10),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: c.withAlpha(90)),
      ),
      child: DefaultTextStyle.merge(style: TextStyle(color: c), child: child),
    );
  }
}

// ─────────────────────────── کۆنفێتی ───────────────────────────

class Confetti extends StatefulWidget {
  const Confetti({super.key, this.n = 34});
  final int n;
  @override
  State<Confetti> createState() => _ConfettiState();
}

class _ConfettiState extends State<Confetti> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))..forward();
  late final List<List<double>> _p;

  @override
  void initState() {
    super.initState();
    final r = math.Random(11);
    _p = List.generate(widget.n, (i) => [r.nextDouble() * 340 - 170, r.nextDouble() * 300 - 210, r.nextDouble() * .2, i % 5 + 0.0, r.nextDouble() * 6]);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(child: AnimatedBuilder(animation: _c, builder: (context, _) => CustomPaint(painter: _Conf(_c.value, _p))));
}

class _Conf extends CustomPainter {
  _Conf(this.t, this.p);
  final double t;
  final List<List<double>> p;
  static const cols = [kCy, kMint, kCarb, kFat, kPro];
  @override
  void paint(Canvas canvas, Size size) {
    final o = size.center(Offset.zero);
    for (final x in p) {
      final k = ((t - x[2]) / (1 - x[2])).clamp(0.0, 1.0);
      if (k <= 0 || k >= 1) continue;
      final e = 1 - math.pow(1 - k, 3).toDouble();
      canvas.save();
      canvas.translate(o.dx + x[0] * e, o.dy + x[1] * e + 120 * k * k);
      canvas.rotate(x[4] + k * 9.4);
      canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(-3.5, -6, 7, 12), const Radius.circular(2)), Paint()..color = cols[x[3].toInt()].withAlpha(((1 - k) * 255).round()));
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_Conf o) => o.t != t;
}

/// پەڕە بە جووڵەی نەرم
Route<T> foodRoute<T>(Widget page) => PageRouteBuilder<T>(
      transitionDuration: const Duration(milliseconds: 420),
      reverseTransitionDuration: const Duration(milliseconds: 260),
      pageBuilder: (context, a, b) => page,
      transitionsBuilder: (context, a, b, child) {
        final c = CurvedAnimation(parent: a, curve: kEase);
        return FadeTransition(
          opacity: c,
          child: SlideTransition(position: Tween<Offset>(begin: const Offset(-0.06, 0), end: Offset.zero).animate(c), child: child),
        );
      },
    );

Uint8List? firstBytes(List<FShot> s) {
  for (final x in s) {
    if (x.bytes != null) return x.bytes;
  }
  return null;
}
