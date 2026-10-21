// VEX Health — دیمەنی دەستپێک (Splash) — هەمان دیزاینی ئەپەکە، نزیکەی 2 چرکە
//
// ڕیزبەندی جووڵەکان (بە چرکە):
//   0.00 – 0.72  هێڵی ECG لە چەپەوە بۆ ڕاست دەڕوات
//   0.50 – 1.30  لۆگۆی VX لە تەڵخییەوە ڕوون دەبێتەوە + ڕووناکی
//   0.55 / 0.72  دوو بازنە بڵاو دەبنەوە
//   0.78 – 1.55  پیتەکانی VEX HEALTH یەک لە دوای یەک دێن
//   0.80 – 1.90  هێڵی بارکردن پڕ دەبێتەوە
//   1.15 – 2.15  تیشکێک بە سەر لۆگۆدا تێدەپەڕێت
//   2.00 – 2.50  دیمەنەکە بە نەرمی لادەچێت
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../core/theme.dart';

const String kLogoAsset = 'assets/brand/vx_logo.webp';

class _Particle {
  const _Particle(this.x, this.y, this.r, this.v, this.a, this.s);
  final double x;
  final double y;
  final double r;
  final double v;
  final double a;
  final double s;
}

class VexSplash extends StatefulWidget {
  const VexSplash({super.key, required this.onDone});
  final VoidCallback onDone;

  @override
  State<VexSplash> createState() => _VexSplashState();
}

class _VexSplashState extends State<VexSplash> with SingleTickerProviderStateMixin {
  static const double _total = 2.5;

  late final AnimationController c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 2500));
  final math.Random _rnd = math.Random();
  late final List<_Particle> parts = List<_Particle>.generate(
    34,
    (_) => _Particle(
      _rnd.nextDouble(),
      _rnd.nextDouble(),
      0.6 + _rnd.nextDouble() * 1.6,
      0.15 + _rnd.nextDouble() * 0.45,
      0.15 + _rnd.nextDouble() * 0.45,
      _rnd.nextDouble() * 6,
    ),
  );
  bool _precached = false;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    c.addStatusListener(_onStatus);
    c.forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_precached) {
      _precached = true;
      precacheImage(const AssetImage(kLogoAsset), context);
    }
  }

  void _onStatus(AnimationStatus s) {
    if (s == AnimationStatus.completed && !_done) {
      _done = true;
      widget.onDone();
    }
  }

  @override
  void dispose() {
    c.removeStatusListener(_onStatus);
    c.dispose();
    super.dispose();
  }

  /// پێشکەوتنی بەشێک لە کات (0 بۆ 1)
  double _seg(double t, double delay, double dur) => clampD((t - delay) / dur, 0, 1);

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    return AnimatedBuilder(
      animation: c,
      builder: (context, _) {
        final t = c.value * _total;
        final exO = 1 - Curves.ease.transform(_seg(t, 2.0, 0.45));
        final exS = 1 + 0.06 * const Cubic(0.6, 0.0, 0.4, 1.0).transform(_seg(t, 2.0, 0.5));
        return IgnorePointer(
          ignoring: t >= 2.0,
          child: AbsorbPointer(
            absorbing: t < 2.0,
            child: Opacity(
              opacity: clampD(exO, 0, 1),
              child: Transform.scale(scale: exS, child: _body(t, mq)),
            ),
          ),
        );
      },
    );
  }

  Widget _body(double t, MediaQueryData mq) {
    final w = mq.size.width;
    final h = mq.size.height;
    // ستوونی ناوەڕاست: لۆگۆ (96) + 26 + نووسین (28)
    final colTop = h * 0.48 - 75;
    final logoCy = colTop + 48;
    final ecgCy = colTop + 96 * 0.516;

    return Stack(
      children: [
        // پاشبنەما
        const Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0, -0.08),
                radius: 1.4,
                colors: [Color(0xFF07303B), Color(0xFF041A22), Color(0xFF020C11)],
                stops: [0.0, 0.46, 1.0],
              ),
            ),
          ),
        ),
        // ڕووناکی سوڕاوە
        Positioned.fill(
          child: OverflowBox(
            minWidth: 0,
            minHeight: 0,
            maxWidth: w * 1.4,
            maxHeight: h * 1.4,
            child: Transform.rotate(
              angle: t / 14 * 2 * math.pi,
              child: SizedBox(
                width: w * 1.4,
                height: h * 1.4,
                child: const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: SweepGradient(
                      transform: GradientRotation(1.92),
                      colors: [
                        Color(0x002FE6F3),
                        Color(0x142FE6F3),
                        Color(0x002FE6F3),
                        Color(0x0F3CF08A),
                        Color(0x003CF08A),
                        Color(0x102FE6F3),
                        Color(0x002FE6F3),
                      ],
                      stops: [0.0, 0.15, 0.3, 0.45, 0.6, 0.8, 1.0],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        // تەنۆلکەکان + ECG
        Positioned.fill(child: CustomPaint(painter: _SplashPainter(t, parts, ecgCy))),
        // ڕووناکی دەوری لۆگۆ
        _halo(t, w, logoCy),
        _ring(t, w, logoCy, 0.55, const Color(0xB38FF3F9)),
        _ring(t, w, logoCy, 0.72, const Color(0x8C3CF08A)),
        // لۆگۆ
        Positioned(left: w / 2 - 88, top: colTop, width: 176, height: 96, child: _logo(t)),
        // VEX HEALTH
        Positioned(left: 0, right: 0, top: colTop + 96 + 26, child: Center(child: _word(t))),
        // خوارەوە
        Positioned(left: 0, right: 0, bottom: mq.padding.bottom + 42, child: _foot(t)),
      ],
    );
  }

  Widget _halo(double t, double w, double cy) {
    final p = _seg(t, 0.5, 1.1);
    double o, s;
    if (p <= 0) {
      o = 0;
      s = 0.4;
    } else if (p < 0.4) {
      final e = Curves.easeOut.transform(p / 0.4);
      o = e;
      s = 0.4 + 0.65 * e;
    } else {
      final e = Curves.easeOut.transform((p - 0.4) / 0.6);
      o = 1 - 0.45 * e;
      s = 1.05 - 0.05 * e;
    }
    return Positioned(
      left: w / 2 - 120,
      top: cy - 120,
      width: 240,
      height: 240,
      child: Opacity(
        opacity: clampD(o, 0, 1),
        child: Transform.scale(
          scale: s,
          child: const DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                radius: 0.707,
                colors: [Color(0x522FE6F3), Color(0x142FE6F3), Color(0x002FE6F3)],
                stops: [0.0, 0.45, 0.7],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _ring(double t, double w, double cy, double delay, Color col) {
    final p = _seg(t, delay, 1.2);
    if (p <= 0 || p >= 1) return const SizedBox.shrink();
    final e = const Cubic(0.1, 0.6, 0.3, 1.0).transform(p);
    return Positioned(
      left: w / 2 - 60,
      top: cy - 60,
      width: 120,
      height: 120,
      child: Opacity(
        opacity: clampD(0.9 * (1 - e), 0, 1),
        child: Transform.scale(
          scale: 0.5 + 2.1 * e,
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: col, width: 1.5),
            ),
          ),
        ),
      ),
    );
  }

  Widget _logo(double t) {
    final p = _seg(t, 0.5, 0.8);
    if (p <= 0) return const SizedBox.shrink();
    double opacity, blur, glowA, glowR;
    if (p < 0.6) {
      final e = Curves.easeOutCubic.transform(p / 0.6);
      opacity = e;
      blur = 10 * (1 - e);
      glowA = 0.95 * e;
      glowR = 26 * e;
    } else {
      final e = Curves.easeOut.transform((p - 0.6) / 0.4);
      opacity = 1;
      blur = 0;
      glowA = 0.95 - 0.40 * e;
      glowR = 26 - 12 * e;
    }
    final scale = 0.72 + 0.28 * const Cubic(0.2, 0.9, 0.25, 1.15).transform(p);

    Widget img() => Image.asset(kLogoAsset, width: 176, height: 96, fit: BoxFit.contain, filterQuality: FilterQuality.medium);

    // تیشکی سەر لۆگۆ
    Widget crisp = img();
    final sp = _seg(t, 1.15, 1.0);
    if (sp > 0 && sp < 1) {
      final e = const Cubic(0.45, 0.05, 0.3, 1.0).transform(sp);
      final so = sp < 0.85 ? 1.0 : 1 - (sp - 0.85) / 0.15;
      final bx = -158 + 492 * e;
      crisp = ShaderMask(
        blendMode: BlendMode.srcATop,
        shaderCallback: (r) {
          const d = Offset(0.94, 0.34);
          final c0 = Offset(bx, 48);
          return ui.Gradient.linear(
            c0 - d * 64,
            c0 + d * 63,
            [
              const Color(0x00FFFFFF),
              const Color(0x00E1FFFF),
              op(const Color(0xFFE1FFFF), 0.95 * so),
              op(const Color(0xFF8FF3F9), 0.35 * so),
              const Color(0x008FF3F9),
            ],
            const [0.0, 0.083, 0.5, 0.75, 1.0],
          );
        },
        child: crisp,
      );
    }
    if (blur > 0.05) {
      crisp = ImageFiltered(imageFilter: ui.ImageFilter.blur(sigmaX: blur / 2, sigmaY: blur / 2), child: crisp);
    }

    final children = <Widget>[];
    if (glowA > 0.01 && glowR > 0.5) {
      children.add(
        Positioned.fill(
          child: ImageFiltered(
            imageFilter: ui.ImageFilter.blur(sigmaX: glowR / 2, sigmaY: glowR / 2),
            child: ColorFiltered(
              colorFilter: ColorFilter.mode(op(V.cy, glowA), BlendMode.srcIn),
              child: img(),
            ),
          ),
        ),
      );
    }
    children.add(Positioned.fill(child: crisp));

    return Opacity(
      opacity: clampD(opacity, 0, 1),
      child: Transform.scale(
        scale: scale,
        child: Stack(clipBehavior: Clip.none, children: children),
      ),
    );
  }

  Widget _word(double t) {
    const text = 'VEX HEALTH';
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int i = 0; i < text.length; i++) _letter(t, i, text[i], i == text.length - 1),
        ],
      ),
    );
  }

  Widget _letter(double t, int i, String ch, bool last) {
    final p = _seg(t, 0.78 + i * 0.035, 0.45);
    final e = const Cubic(0.2, 0.9, 0.3, 1.0).transform(p);
    Widget w = Text(ch == ' ' ? ' ' : ch, style: nu(22, c: const Color(0xFFEFFEFF), h: 1.25));
    if (i < 3) {
      w = ShaderMask(
        blendMode: BlendMode.srcIn,
        shaderCallback: (r) => const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFBFF9FF), Color(0xFF2FE6F3)],
        ).createShader(r),
        child: w,
      );
    }
    final b = 3 * (1 - e);
    if (b > 0.05) {
      w = ImageFiltered(imageFilter: ui.ImageFilter.blur(sigmaX: b, sigmaY: b), child: w);
    }
    return Padding(
      padding: EdgeInsets.only(right: last ? 0 : 9),
      child: Opacity(
        opacity: clampD(e, 0, 1),
        child: Transform.translate(offset: Offset(0, 10 * (1 - e)), child: w),
      ),
    );
  }

  Widget _foot(double t) {
    final fe = Curves.ease.transform(_seg(t, 0.9, 0.5));
    final bp = const Cubic(0.4, 0.0, 0.2, 1.0).transform(_seg(t, 0.8, 1.1));
    return Opacity(
      opacity: clampD(fe, 0, 1),
      child: Transform.translate(
        offset: Offset(0, 6 * (1 - fe)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 120,
              height: 2,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: ColoredBox(
                  color: const Color(0x14FFFFFF),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: FractionallySizedBox(
                      widthFactor: clampD(bp, 0, 1),
                      heightFactor: 1,
                      child: const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [Color(0xFF2FE6F3), Color(0xFF3CF08A)]),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text('VEX BAND · AI HEALTH', style: nu(10.5, w: FontWeight.w600, c: const Color(0x998CB7BF), ls: 2.5)),
          ],
        ),
      ),
    );
  }
}

/// تەنۆلکەکان و هێڵی ECG
class _SplashPainter extends CustomPainter {
  _SplashPainter(this.t, this.parts, this.cy);
  final double t;
  final List<_Particle> parts;
  final double cy;

  static const List<List<double>> _spike = [
    [-34.0, 0.0], [-26.0, -4.0], [-20.0, 0.0], [-12.0, 0.0], [-8.0, 10.0], [-2.0, -46.0],
    [4.0, 30.0], [10.0, 0.0], [18.0, 0.0], [26.0, -8.0], [34.0, 0.0],
  ];

  static double _ecgY(double u) {
    if (u < -34 || u > 34) return 0;
    for (int i = 0; i < _spike.length - 1; i++) {
      final a = _spike[i][0], ya = _spike[i][1];
      final b = _spike[i + 1][0], yb = _spike[i + 1][1];
      if (u >= a && u <= b) return ya + (yb - ya) * (u - a) / (b - a);
    }
    return 0;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;

    // تەنۆلکەکان
    for (final p in parts) {
      final y = ((p.y * h + 10 - p.v * 60 * t) % (h + 20)) - 10;
      final x = p.x * w + math.sin(t * 0.6 + p.s) * 9;
      final a = p.a * (0.6 + 0.4 * math.sin(t * 2 + p.s));
      canvas.drawCircle(Offset(x, y), p.r, Paint()..color = op(const Color(0xFF8FF3F9), a));
    }

    // ECG
    final prog = math.min(t / 0.72, 1.0);
    final head = -20 + (w + 40) * (1 - math.pow(1 - prog, 2.2).toDouble());
    final fade = t < 0.95 ? 1.0 : math.max(0.0, 1 - (t - 0.95) / 0.5);
    if (fade <= 0) return;
    final cx = w / 2;
    final path = Path()..moveTo(-20, cy);
    for (final q in _spike) {
      final x = cx + q[0];
      if (x >= head) break;
      if (x > -20) path.lineTo(x, cy + q[1]);
    }
    final hy = cy + _ecgY(head - cx);
    path.lineTo(head, hy);

    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round
        ..color = op(const Color(0xFF2FE6F3), 0.45 * fade)
        ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 7),
    );
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round
        ..shader = ui.Gradient.linear(
          Offset(head - w * 0.7, 0),
          Offset(head, 0),
          [
            const Color(0x002FE6F3),
            op(const Color(0xFF2FE6F3), 0.55 * fade),
            op(const Color(0xFFDCFFFF), fade),
          ],
          const [0.0, 0.7, 1.0],
        ),
    );
    if (prog < 1) {
      canvas.drawCircle(
        Offset(head, hy),
        8,
        Paint()
          ..color = const Color(0x992FE6F3)
          ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 8),
      );
      canvas.drawCircle(Offset(head, hy), 3.5, Paint()..color = Colors.white);
    }
  }

  @override
  bool shouldRepaint(covariant _SplashPainter oldDelegate) => true;
}
