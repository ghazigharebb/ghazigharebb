// VEX Health — بازنەی تەندروستیی ئەمڕۆ (هەمان دیزاینی وێب)
import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../band/band_widgets.dart';
import '../core/icons.dart';
import '../core/store.dart';
import '../core/theme.dart';
import 'detail_sheets.dart';

class Metric {
  const Metric({
    required this.k,
    required this.hex,
    required this.c,
    required this.g0,
    required this.g1,
    required this.sn,
    required this.n,
    required this.u,
    required this.sc,
  });

  final String k;
  final String hex;
  final Color c;
  final Color g0;
  final Color g1;
  final String sn;
  final String n;
  final String u;
  final double sc;

  String value(Health h) {
    switch (k) {
      case 'sleep':
        return '7:10';
      case 'hr':
        return '${h.hr}';
      case 'temp':
        return h.temp.toStringAsFixed(1);
      case 'act':
        return '${h.active}';
      case 'spo2':
        return '${h.spo2}';
      default:
        return '${h.stress}';
    }
  }
}

/// هەر یەکێک ڕەنگی تایبەتی خۆی: خەو = شەو، دڵ = سووری خوێن ...
const List<Metric> kMetrics = [
  Metric(k: 'sleep', hex: '#8b7bff', c: Color(0xFF8B7BFF), g0: Color(0xFFB9ADFF), g1: Color(0xFF6A55FF), sn: 'خەو', n: 'خەو', u: 'کاتژمێر', sc: 0.86),
  Metric(k: 'hr', hex: '#ff3d5e', c: Color(0xFFFF3D5E), g0: Color(0xFFFF8A9C), g1: Color(0xFFE8173F), sn: 'دڵ', n: 'لێدانی دڵ', u: 'BPM', sc: 0.9),
  Metric(k: 'temp', hex: '#ffc23d', c: Color(0xFFFFC23D), g0: Color(0xFFFFE08A), g1: Color(0xFFFFA91F), sn: 'پێست', n: 'پلەی پێست', u: '°C', sc: 0.88),
  Metric(k: 'act', hex: '#3cf08a', c: Color(0xFF3CF08A), g0: Color(0xFF8DFFC0), g1: Color(0xFF1FCF6E), sn: 'چالاکی', n: 'چالاکی', u: 'خولەک', sc: 0.55),
  Metric(k: 'spo2', hex: '#3db8ff', c: Color(0xFF3DB8FF), g0: Color(0xFF9BE0FF), g1: Color(0xFF1A8CFF), sn: 'ئۆکسجین', n: 'SpO₂', u: '%', sc: 0.62),
  Metric(k: 'stress', hex: '#ff8a3d', c: Color(0xFFFF8A3D), g0: Color(0xFFFFB37A), g1: Color(0xFFFF6A1F), sn: 'سترێس', n: 'سترێس', u: '', sc: 0.5),
];

class StatusTag {
  const StatusTag(this.t, this.c);
  final String t;
  final Color c;
}

StatusTag metricStatus(double sc) {
  if (sc >= 0.75) return const StatusTag('باش', Color(0xFF3CF08A));
  if (sc >= 0.5) return const StatusTag('ئاگاداربە', Color(0xFFFFBE4D));
  return const StatusTag('لاواز', Color(0xFFFF5D6C));
}

int ringScore() {
  double s = 0;
  for (final m in kMetrics) {
    s += m.sc;
  }
  return (s / kMetrics.length * 100).round();
}

StatusTag ringStatus() {
  final s = ringScore();
  if (s >= 85) return const StatusTag('نایاب', Color(0xFF3CF08A));
  if (s >= 70) return const StatusTag('باش', Color(0xFF3CF08A));
  if (s >= 55) return const StatusTag('مامناوەند', Color(0xFFFFBE4D));
  return const StatusTag('گرنگی پێبدە', Color(0xFFFF5D6C));
}

const int kYesterdayScore = 68;

// ئەندازە (هەمان viewBox ـی 360×340)
const double _cx = 180;
const double _cy = 170;
const double _vh = 340;
const double _rr = 94;
const double _sw = 20;
const double _gap = 9;
const double _ri = 67;
const double _span = 60 - _gap;
const Cubic _ease = Cubic(0.2, 0.9, 0.2, 1.0);
const Cubic _easeIn = Cubic(0.2, 0.9, 0.3, 1.0);

Offset _pt(double r, double a) {
  final t = rad(a);
  return Offset(_cx + r * math.sin(t), _cy - r * math.cos(t));
}

// ============================================================
// کارتی تەندروستیی ئەمڕۆ
// ============================================================
class HealthCard extends StatelessWidget {
  const HealthCard({super.key});

  @override
  Widget build(BuildContext context) {
    final good = kMetrics.where((m) => m.sc >= 0.75).map((m) => m.n).toList();
    final weak = kMetrics.where((m) => m.sc < 0.75).toList()..sort((a, b) => a.sc.compareTo(b.sc));
    final w2 = weak.take(2).toList();
    final bold = ku(12.5, w: FontWeight.w800, c: V.tx, h: 1.7);

    return VCard(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Row(
              children: [
                Expanded(child: Text('تەندروستیی ئەمڕۆ', style: ku(16, w: FontWeight.w800))),
                BandBuilder(
                  builder: (context, on) => Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (on)
                        const BlinkDot(size: 7, glow: true)
                      else
                        Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(shape: BoxShape.circle, color: BandColors.dot),
                        ),
                      const SizedBox(width: 6),
                      Text(on ? 'زیندوو لە Band ـەوە' : 'پەیوەست نییە',
                          style: ku(12, w: FontWeight.w600, c: on ? V.mu : BandColors.label)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          BandBuilder(builder: (context, on) => on ? const HealthRing() : const OfflineHealthRing()),
          BandBuilder(builder: (context, on) => !on ? Padding(
            padding: const EdgeInsets.fromLTRB(6, 2, 6, 8),
            child: Text(
              'نمرەی تەندروستی دوای پەیوەستکردنی Band دەردەکەوێت.',
              textAlign: TextAlign.center,
              style: ku(12.5, w: FontWeight.w700, c: V.mu, h: 1.7),
            ),
          ) : Padding(
            padding: const EdgeInsets.fromLTRB(6, 2, 6, 8),
            child: Text.rich(
              TextSpan(children: [
                TextSpan(text: '✨ ${good.join('، ')} باشن'),
                if (w2.isNotEmpty) ...[
                  const TextSpan(text: ' · '),
                  TextSpan(text: w2[0].n, style: bold),
                  if (w2.length > 1) ...[
                    const TextSpan(text: ' و '),
                    TextSpan(text: w2[1].n, style: bold),
                  ],
                  const TextSpan(text: ' پێویستیان بە سەرنجە'),
                ],
              ]),
              textAlign: TextAlign.center,
              style: ku(12.5, w: FontWeight.w700, c: V.mu, h: 1.7),
            ),
          )),
          Press(
            onTap: openVitalAge,
            scale: 0.98,
            child: Container(
              margin: const EdgeInsets.only(top: 2),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: box(r: 16),
              child: Row(
                children: [
                  const Text('🧬', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('تەمەنی ژیانی (VitalAge)', style: ku(13, w: FontWeight.w700)),
                        Text('خەو، HRV و چالاکی هاوکات بکە بۆ کردنەوە', style: ku(12, c: V.mu, h: 1.8)),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(99),
                          child: Container(
                            height: 5,
                            color: V.track,
                            alignment: Alignment.centerLeft,
                            child: const FractionallySizedBox(
                              widthFactor: 0.22,
                              heightFactor: 1,
                              child: DecoratedBox(decoration: BoxDecoration(gradient: V.prime)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text('‹', style: ku(14, c: V.mu)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// بازنەکە
// ============================================================
class HealthRing extends StatefulWidget {
  const HealthRing({super.key});

  @override
  State<HealthRing> createState() => _HealthRingState();
}

class _HealthRingState extends State<HealthRing> with TickerProviderStateMixin {
  late final AnimationController intro =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 2400));
  late final AnimationController breath =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 2500));
  late final AnimationController arc =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));
  late final AnimationController focusC =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
  late final AnimationController beat =
      AnimationController(vsync: this, duration: Duration(milliseconds: (60000 / Store.I.h.hr).round()));
  late final Animation<double> beatScale = TweenSequence<double>([
    TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 1.2), weight: 15),
    TweenSequenceItem(tween: Tween<double>(begin: 1.2, end: 0.96), weight: 15),
    TweenSequenceItem(tween: Tween<double>(begin: 0.96, end: 1.1), weight: 15),
    TweenSequenceItem(tween: Tween<double>(begin: 1.1, end: 1.0), weight: 55),
  ]).animate(beat);

  int focus = -1;
  int focusFrom = -1;
  double arcFrom = 0;
  double arcTo = 0;
  Color? arcColor;
  Timer? _unfocusT;
  Timer? _hrT;
  final math.Random _rnd = math.Random();

  double get introT => intro.value * 2.4;
  double get arcVal => arcFrom + (arcTo - arcFrom) * _ease.transform(arc.value);

  double _opFor(int f, int i) => (f < 0 || f == i) ? 1.0 : 0.22;
  double segOp(int i) => _opFor(focusFrom, i) + (_opFor(focus, i) - _opFor(focusFrom, i)) * focusC.value;

  @override
  void initState() {
    super.initState();
    intro.forward();
    breath.repeat(reverse: true);
    beat.repeat();
    arcFrom = 0;
    arcTo = ringScore() / 100;
    arc.forward(from: 0);
    // لێدانی دڵی زیندوو (هەر 4 چرکە)
    _hrT = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted) return;
      final hr = 70 + _rnd.nextInt(7);
      Store.I.h.hr = hr;
      beat.duration = Duration(milliseconds: (60000 / hr).round());
      beat.repeat();
      setState(() {});
    });
  }

  @override
  void dispose() {
    _unfocusT?.cancel();
    _hrT?.cancel();
    intro.dispose();
    breath.dispose();
    arc.dispose();
    focusC.dispose();
    beat.dispose();
    super.dispose();
  }

  void setFocus(int i) {
    _unfocusT?.cancel();
    final cur = arcVal;
    setState(() {
      focusFrom = focus;
      focus = i;
      arcFrom = cur;
      if (i < 0) {
        arcTo = ringScore() / 100;
        arcColor = null;
      } else {
        arcTo = kMetrics[i].sc;
        arcColor = kMetrics[i].c;
      }
    });
    focusC.forward(from: 0);
    arc.forward(from: 0);
    if (i >= 0) {
      _unfocusT = Timer(const Duration(seconds: 6), () {
        if (mounted) setFocus(-1);
      });
    }
  }

  void _tapSeg(int i) {
    if (focus == i) {
      openMetricDetail(kMetrics[i].k);
    } else {
      setFocus(i);
    }
  }

  void _onTapUp(TapUpDetails d) {
    final p = d.localPosition;
    final dx = p.dx - _cx, dy = p.dy - _cy;
    final dist = math.sqrt(dx * dx + dy * dy);
    if (dist < _rr - _sw / 2 - 8) {
      if (focus >= 0) openMetricDetail(kMetrics[focus].k);
      return;
    }
    if ((dist - _rr).abs() <= _sw / 2 + 13) {
      var a = math.atan2(dx, -dy) * 180 / math.pi;
      if (a < 0) a += 360;
      final i = math.min(5, math.max(0, a ~/ 60));
      _tapSeg(i);
      return;
    }
    if (focus != -1) setFocus(-1);
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 360 / _vh,
      child: FittedBox(
        fit: BoxFit.contain,
        child: SizedBox(
          width: 360,
          height: _vh,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapUp: _onTapUp,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(child: RepaintBoundary(child: CustomPaint(painter: _AuraPainter(breath)))),
                Positioned.fill(child: RepaintBoundary(child: CustomPaint(painter: _RingPainter(this)))),
                Positioned.fill(
                  child: AnimatedBuilder(
                    animation: Listenable.merge([intro, focusC]),
                    builder: (context, _) => Stack(
                      clipBehavior: Clip.none,
                      children: [for (int i = 0; i < kMetrics.length; i++) _pill(i)],
                    ),
                  ),
                ),
                Positioned.fill(
                  child: IgnorePointer(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      child: focus < 0 ? _scoreCenter() : _metricCenter(focus),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---- کارتە بچووکەکانی دەوروبەر (callout) ----
  Widget _pill(int i) {
    final m = kMetrics[i];
    final am = i * 60 + _gap / 2 + _span / 2;
    final tr = rad(am);
    final px = _cx + math.sin(tr) * 138;
    final py = _cy - math.cos(tr) * 140;
    final lp = clampD((introT - (0.5 + i * 0.1)) / 0.6, 0, 1);
    final e = _easeIn.transform(lp);
    final s = metricStatus(m.sc);
    final isFocus = focus == i;
    Widget icon = SvgPicture.string(iconSvg(kRingIcons[m.k]!, m.hex, stroke: 2.3), width: 14, height: 14);
    if (m.k == 'hr') icon = ScaleTransition(scale: beatScale, child: icon);

    return Positioned(
      left: px - 40,
      top: py - 20,
      width: 80,
      height: 40,
      child: Opacity(
        opacity: clampD(lp * segOp(i), 0, 1),
        child: Transform.scale(
          scale: 0.85 + 0.15 * e,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _tapSeg(i),
            child: Container(
              decoration: BoxDecoration(
                color: mix(const Color(0xFF062B35), m.c, 0.07),
                borderRadius: BorderRadius.circular(13),
                border: Border.all(color: op(m.c, 0.5)),
                boxShadow: isFocus ? [BoxShadow(color: op(m.c, 0.6), blurRadius: 18, spreadRadius: -4)] : null,
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    left: 51,
                    top: 8,
                    width: 22,
                    height: 22,
                    child: Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: op(m.c, 0.16)),
                      child: icon,
                    ),
                  ),
                  Positioned(
                    right: 35,
                    top: 4,
                    child: Text(
                      m.value(Store.I.h),
                      textDirection: TextDirection.ltr,
                      style: nu(14.5, c: const Color(0xFFF2FFFF), h: 1.15),
                    ),
                  ),
                  Positioned(
                    right: 35,
                    top: 21,
                    child: Text(m.sn, style: ku(10, w: FontWeight.w800, c: m.c, h: 1.2)),
                  ),
                  Positioned(
                    left: 2,
                    top: 2,
                    width: 12,
                    height: 12,
                    child: Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: op(s.c, 0.22)),
                      child: Container(
                        width: 6.4,
                        height: 6.4,
                        decoration: BoxDecoration(shape: BoxShape.circle, color: s.c),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _cText(double top, double height, Widget child) =>
      Positioned(left: 80, width: 200, top: top, height: height, child: Center(child: child));

  Widget _gradNum(String s, double size) => ShaderMask(
        blendMode: BlendMode.srcIn,
        shaderCallback: (r) => const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.white, Color(0xFFA9F6FF)],
        ).createShader(r),
        child: Text(s, textDirection: TextDirection.ltr, style: nu(size, c: Colors.white, h: 1.0, ls: -1.5)),
      );

  Widget _pillTag(StatusTag st, double w, double h, double fs) => Container(
        width: w,
        height: h,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: op(st.c, 0.15),
          borderRadius: BorderRadius.circular(h / 2),
          border: Border.all(color: op(st.c, 0.5)),
        ),
        child: Text(st.t, style: ku(fs, w: FontWeight.w800, c: st.c, h: 1.1)),
      );

  // ناوەڕاست: نمرەی گشتی
  Widget _scoreCenter() {
    final st = ringStatus();
    final score = ringScore();
    final dlt = score - kYesterdayScore;
    return SizedBox(
      key: const ValueKey<String>('score'),
      width: 360,
      height: _vh,
      child: Stack(
        children: [
          _cText(_cy - 45, 16, Text('نمرەی تەندروستی', style: ku(10, w: FontWeight.w700, c: const Color(0xFF7FB9C2), h: 1.2))),
          _cText(
            _cy - 36,
            52,
            AnimatedBuilder(
              animation: intro,
              builder: (context, _) {
                final p = clampD(introT / 1.5, 0, 1);
                final v = (score * (1 - math.pow(1 - p, 3))).round();
                return _gradNum('$v', 46);
              },
            ),
          ),
          Positioned(left: _cx - 27, top: _cy + 17, child: _pillTag(st, 54, 20, 11)),
          _cText(
            _cy + 42,
            16,
            Text(
              '${dlt >= 0 ? '▲' : '▼'} ${dlt.abs()} لە دوێنێ',
              style: ku(9.5, w: FontWeight.w800, c: dlt >= 0 ? const Color(0xFF3CF08A) : const Color(0xFFFF8A9D), h: 1.2),
            ),
          ),
        ],
      ),
    );
  }

  // ناوەڕاست: کاتێک یەکێک هەڵدەبژێردرێت
  Widget _metricCenter(int i) {
    final m = kMetrics[i];
    final s = metricStatus(m.sc);
    return SizedBox(
      key: ValueKey<String>('m$i'),
      width: 360,
      height: _vh,
      child: Stack(
        children: [
          Positioned(
            left: _cx - 8,
            top: _cy - 52,
            width: 16,
            height: 16,
            child: SvgPicture.string(iconSvg(kRingIcons[m.k]!, m.hex, stroke: 2.4), width: 16, height: 16),
          ),
          _cText(_cy - 31, 16, Text(m.n, style: ku(10.5, w: FontWeight.w800, c: m.c, h: 1.2))),
          _cText(_cy - 21, 38, _gradNum(m.value(Store.I.h), 36)),
          _cText(_cy + 17, 14, Text(m.u, textDirection: TextDirection.ltr, style: ku(9.5, w: FontWeight.w700, c: const Color(0xFF7FB9C2), h: 1.2))),
          Positioned(left: _cx - 30, top: _cy + 33, child: _pillTag(s, 60, 19, 10.5)),
        ],
      ),
    );
  }
}

// ---- پاشبنەمای هەناسەدان ----
class _AuraPainter extends CustomPainter {
  _AuraPainter(this.a) : super(repaint: a);
  final Animation<double> a;

  @override
  void paint(Canvas canvas, Size size) {
    final v = Curves.easeInOut.transform(a.value);
    final o = 1 - 0.3 * v;
    final r = 150 * (1 + 0.08 * v);
    const c = Offset(_cx, _cy);
    final p = Paint()
      ..shader = ui.Gradient.radial(
        c,
        r,
        [op(V.cy, 0.16 * o), op(V.cy, 0.05 * o), op(V.cy, 0)],
        [0.0, 0.55, 1.0],
      );
    canvas.drawCircle(c, r, p);
  }

  @override
  bool shouldRepaint(covariant _AuraPainter oldDelegate) => false;
}

// ---- بازنە و پارچەکان ----
class _RingPainter extends CustomPainter {
  _RingPainter(this.s) : super(repaint: Listenable.merge([s.intro, s.arc, s.focusC]));
  final _HealthRingState s;

  Paint _stroke(double w) => Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = w
    ..strokeCap = StrokeCap.round;

  void _dash(Canvas canvas, Offset a, Offset b, Paint p) {
    final d = b - a;
    final len = d.distance;
    if (len <= 0) return;
    final u = d / len;
    double x = 0;
    while (x < len) {
      final x2 = math.min(len, x + 2.0);
      canvas.drawLine(a + u * x, a + u * x2, p);
      x += 5;
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    const c = Offset(_cx, _cy);
    final t = s.introT;

    // ناوکی تاریک
    const coreR = _rr - _sw / 2 - 8;
    final coreRect = Rect.fromCircle(center: c, radius: coreR);
    canvas.drawCircle(
      c,
      coreR,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(0, -0.3),
          radius: 0.5,
          colors: [Color(0xFF0E3D4B), Color(0xFF04202A)],
        ).createShader(coreRect),
    );
    canvas.drawCircle(c, coreR, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = op(V.cy, 0.12));

    // هێڵی ناوەوە + نمرە
    canvas.drawCircle(c, _ri, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..color = op(Colors.white, 0.06));
    final av = s.arcVal;
    if (av > 0.002) {
      final r = Rect.fromCircle(center: c, radius: _ri);
      final sweep = math.pi * 2 * av;
      final glow = _stroke(4.5)
        ..color = op(s.arcColor ?? V.cy, 0.55)
        ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 3);
      canvas.drawArc(r, -math.pi / 2, sweep, false, glow);
      final p = _stroke(3.5);
      final ac = s.arcColor;
      if (ac != null) {
        p.color = ac;
      } else {
        p.shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF8FF3F9), Color(0xFF2FE6F3), Color(0xFF3CF08A)],
          stops: [0.0, 0.55, 1.0],
        ).createShader(r);
      }
      canvas.drawArc(r, -math.pi / 2, sweep, false, p);
    }

    // شەش پارچەکە
    final rect = Rect.fromCircle(center: c, radius: _rr);
    for (int i = 0; i < kMetrics.length; i++) {
      final m = kMetrics[i];
      final a0 = i * 60 + _gap / 2;
      final o = s.segOp(i);
      final layer = o < 0.999;
      if (layer) {
        canvas.saveLayer(Rect.fromLTWH(-40, -40, 440, _vh + 80), Paint()..color = Color.fromRGBO(0, 0, 0, o));
      }

      canvas.drawArc(rect, rad(a0 - 90), rad(_span), false, _stroke(_sw)..color = op(Colors.white, 0.07));

      final fp = clampD((t - (0.25 + i * 0.12)) / 1.3, 0, 1);
      final f = m.sc * _ease.transform(fp);
      if (f > 0.001) {
        final sweep = rad(_span * f);
        canvas.drawArc(
          rect,
          rad(a0 - 90),
          sweep,
          false,
          _stroke(_sw + 8)
            ..color = op(m.c, 0.28)
            ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 5),
        );
        final p0 = _pt(_rr, a0);
        final p1 = _pt(_rr, a0 + _span);
        canvas.drawArc(rect, rad(a0 - 90), sweep, false, _stroke(_sw)..shader = ui.Gradient.linear(p0, p1, [m.g0, m.g1]));
      }

      final so = clampD((t - (0.9 + i * 0.12)) / 0.5, 0, 1);
      if (so > 0) {
        const rs = _rr + _sw / 2 - 3.5;
        final st = a0 + 1.5;
        final en = a0 + math.max(2.0, _span * m.sc - 1.5);
        canvas.drawArc(
          Rect.fromCircle(center: c, radius: rs),
          rad(st - 90),
          rad(en - st),
          false,
          _stroke(1.2)..color = op(Colors.white, 0.35 * so),
        );
      }

      final co = clampD((t - (1.1 + i * 0.12)) / 0.5, 0, 1);
      if (co > 0) {
        canvas.drawCircle(_pt(_rr, a0 + _span * m.sc), 3, Paint()..color = op(Colors.white, co));
      }

      // هێڵی پەیوەندی بۆ کارتەکە
      final lo = clampD((t - (0.5 + i * 0.1)) / 0.6, 0, 1);
      if (lo > 0) {
        final am = a0 + _span / 2;
        final e0 = _pt(_rr + _sw / 2 + 3, am);
        final tr = rad(am);
        final pe = Offset(_cx + math.sin(tr) * 138, _cy - math.cos(tr) * 140);
        _dash(canvas, e0, pe, Paint()
          ..color = op(m.c, 0.55 * lo)
          ..strokeWidth = 1.4);
        canvas.drawCircle(e0, 6, Paint()..color = op(m.c, 0.2 * lo));
        canvas.drawCircle(e0, 3, Paint()..color = op(m.c, lo));
      }

      if (layer) canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) => true;
}


// ============================================================
// بازنەی نەپەیوەست: کاتێک Band پەیوەست نییە (دیزاینی B)
// ============================================================
class OfflineHealthRing extends StatelessWidget {
  const OfflineHealthRing({super.key});

  Widget _pill(int i) {
    final m = kMetrics[i];
    final am = i * 60 + _gap / 2 + _span / 2;
    final tr = rad(am);
    final px = _cx + math.sin(tr) * 138;
    final py = _cy - math.cos(tr) * 140;
    return Positioned(
      left: px - 40,
      top: py - 20,
      width: 80,
      height: 40,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: op(BandColors.mute, 0.35)),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: 51,
              top: 8,
              width: 22,
              height: 22,
              child: Container(
                alignment: Alignment.center,
                decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0x0FFFFFFF)),
                child: SvgPicture.string(iconSvg(kRingIcons[m.k]!, '#80b4bc', stroke: 2.3), width: 14, height: 14),
              ),
            ),
            Positioned(
              right: 35,
              top: 4,
              child: Text('—', textDirection: TextDirection.ltr, style: nu(14.5, c: BandColors.mute, h: 1.15)),
            ),
            Positioned(
              right: 35,
              top: 21,
              child: Text(m.sn, style: ku(10, w: FontWeight.w800, c: BandColors.mute, h: 1.2)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _cText(double top, double height, Widget child) =>
      Positioned(left: 80, width: 200, top: top, height: height, child: Center(child: child));

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 360 / _vh,
      child: FittedBox(
        fit: BoxFit.contain,
        child: SizedBox(
          width: 360,
          height: _vh,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              const Positioned.fill(child: CustomPaint(painter: _OffRingPainter())),
              for (int i = 0; i < kMetrics.length; i++) _pill(i),
              _cText(_cy - 45, 16,
                  Text('نمرەی تەندروستی', style: ku(10, w: FontWeight.w700, c: const Color(0xFF7FB9C2), h: 1.2))),
              _cText(_cy - 36, 52, Text('—', textDirection: TextDirection.ltr, style: nu(46, c: BandColors.mute, h: 1.0))),
              Positioned(
                left: _cx - 44,
                top: _cy + 17,
                child: Container(
                  width: 88,
                  height: 22,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: op(BandColors.label, 0.12),
                    borderRadius: BorderRadius.circular(11),
                    border: Border.all(color: op(BandColors.label, 0.45)),
                  ),
                  child: Text('پەیوەست نییە', style: ku(11, w: FontWeight.w800, c: BandColors.label, h: 1.1)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OffRingPainter extends CustomPainter {
  const _OffRingPainter();

  @override
  void paint(Canvas canvas, Size size) {
    paintDashedCircle(canvas, const Offset(_cx, _cy), _rr, op(BandColors.mute, 0.55), 6, dash: 2.5, gap: 9);
    paintDashedCircle(canvas, const Offset(_cx, _cy), _ri, op(BandColors.mute, 0.25), 3, dash: 2, gap: 9);
  }

  @override
  bool shouldRepaint(covariant _OffRingPainter oldDelegate) => false;
}
