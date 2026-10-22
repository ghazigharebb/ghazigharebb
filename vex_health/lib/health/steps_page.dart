// VEX Health — پەڕەی هەنگاوی ڕۆژانە
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../core/icons.dart';
import '../core/theme.dart';
import 'detail_common.dart';
import 'hc.dart';

class _StMode {
  const _StMode(this.lab, this.ct, this.gl, this.goal, this.gap, this.v, this.now, this.names, this.xl);
  final String lab;
  final String ct;
  final String gl;
  final int goal;
  final double gap;
  final List<int> v;
  final int now;
  final List<String> names;
  final List<String> xl;
}

List<_StMode> _stepsData() {
  final mn = monthName();
  return [
    _StMode(
      todayLabel(),
      'چالاکی بەپێی کاتژمێر',
      'ئامانجەکانی ئەمڕۆ',
      10000,
      5,
      // کۆی ئەمڕۆ 2,416 هەنگاوە (هەمان ژمارەی بەشی تەندروستی)
      const [0, 0, 0, 0, 0, 0, 0, 215, 533, 1031, 637, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      10,
      [for (int i = 0; i < 24; i++) '${pad2(i)}:00'],
      const ['00', '06', '12', '18', '23'],
    ),
    const _StMode(
      'ئەم هەفتەیە',
      'چالاکی بەپێی ڕۆژ',
      'ئامانجی هەفتە',
      70000,
      10,
      [8240, 6120, 2416, 0, 0, 0, 0],
      2,
      ['شەممە', 'یەکشەممە', 'ئەمڕۆ', 'سێشەممە', 'چوارشەممە', 'پێنجشەممە', 'هەینی'],
      ['شەم', 'یەک', 'دوو', 'سێ', 'چوار', 'پێنج', 'هەینی'],
    ),
    _StMode(
      monthLabel(),
      'چالاکی بەپێی ڕۆژ',
      'ئامانجی مانگ',
      300000,
      3,
      [7200, 9100, 5400, 8800, 2416, for (int i = 0; i < 26; i++) 0],
      4,
      [for (int i = 0; i < 31; i++) '${i + 1}ی $mn'],
      const ['1', '10', '20', '31'],
    ),
  ];
}

class StepsPage extends StatefulWidget {
  const StepsPage({super.key});

  @override
  State<StepsPage> createState() => _StepsPageState();
}

class _StepsPageState extends State<StepsPage> with TickerProviderStateMixin {
  late final List<_StMode> data = _stepsData();
  late final AnimationController grow =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));
  late final AnimationController numC =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1100));

  int mode = 0;
  int sel = -1;

  @override
  void initState() {
    super.initState();
    grow.forward();
    numC.forward();
  }

  @override
  void dispose() {
    grow.dispose();
    numC.dispose();
    super.dispose();
  }

  _StMode get cur => data[mode];

  void _setMode(int m) {
    if (m == mode) return;
    setState(() {
      mode = m;
      sel = -1;
    });
    grow.forward(from: 0);
    numC.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final c = cur;
    final tot = c.v.fold<int>(0, (a, b) => a + b);
    final mx = math.max(1, c.v.reduce(math.max));
    final pct = math.min(tot / c.goal * 100, 100.0);
    final pctTxt = pct < 10 ? '${pct.toStringAsFixed(1)}%' : '${pct.round()}%';
    final km = (tot * 0.00075).toStringAsFixed(tot > 2000 ? 1 : 2);
    final tip = sel >= 0 ? '${c.names[sel]} — ${fmt(c.v[sel])} هەنگاو' : 'پەنجە بنێ بە هەر ستوونێک';

    return DetailScaffold(
      children: [
        DetailHeader(title: 'هەنگاوی ڕۆژانە', mode: mode, onMode: _setMode),
        DateRow(c.lab, bottom: 6),
        // ---- بازنە ----
        Center(
          child: Padding(
            padding: const EdgeInsets.only(top: 14, bottom: 8),
            child: SizedBox(
              width: 250,
              height: 250,
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: math.max(pct / 100, 0.012)),
                duration: const Duration(milliseconds: 1300),
                curve: const Cubic(0.2, 0.9, 0.2, 1.0),
                builder: (context, f, _) => CustomPaint(
                  painter: _StepsRing(f),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedBuilder(
                          animation: numC,
                          builder: (context, _) => ShaderMask(
                            blendMode: BlendMode.srcIn,
                            shaderCallback: (r) => LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [kW, HC.c2],
                            ).createShader(r),
                            child: VText(
                              fmt(tot * Curves.easeOutCubic.transform(numC.value)),
                              textDirection: TextDirection.ltr,
                              style: nu(58, c: kW, h: 1.0, ls: -1),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        VText('هەنگاو', style: ku(15, c: HC.mu)),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: HC.card,
                            borderRadius: BorderRadius.circular(99),
                            border: Border.all(color: HC.line),
                          ),
                          child: VText(pctTxt, textDirection: TextDirection.ltr, style: ku(12, c: HC.c2)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        // ---- سێ خانە ----
        Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Row(
            children: [
              _stat(HI.route, km, 'کیلۆمەتر'),
              const SizedBox(width: 10),
              _stat(HI.fire, fmt(tot * 0.04), 'کالۆری'),
              const SizedBox(width: 10),
              _stat(HI.clock, fmt(tot / 100), 'خولەک'),
            ],
          ),
        ),
        // ---- ستوونەکان ----
        HCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: ChartHead(c.ct, tip, tipBg: vk(0x1F03EAFB), tipLtr: false),
              ),
              SizedBox(
                height: 150,
                child: CustomPaint(
                  painter: const _GridLines(),
                  child: Directionality(
                    textDirection: TextDirection.ltr,
                    child: AnimatedBuilder(
                      animation: grow,
                      builder: (context, _) => Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          for (int i = 0; i < c.v.length; i++) ...[
                            if (i > 0) SizedBox(width: c.gap),
                            Expanded(child: _bar(i, c, mx)),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              XLabels(c.xl, padLeft: 0, padRight: 0, top: 8),
            ],
          ),
        ),
        // ---- ئامانج ----
        HCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Expanded(child: VText(c.gl, style: ku(15, w: FontWeight.w600, c: HC.mu))),
                  VText.rich(
                    TextSpan(children: [
                      TextSpan(text: fmt(tot), style: nu(24, c: HC.tx)),
                      TextSpan(text: '  / ${fmt(c.goal)}', style: ku(15, c: HC.mu)),
                    ]),
                    textDirection: TextDirection.ltr,
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(top: 14, bottom: 10),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: Container(
                    height: 12,
                    color: HC.track,
                    alignment: Alignment.centerLeft,
                    child: TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0, end: math.max(pct, 1.5) / 100),
                      duration: const Duration(milliseconds: 1200),
                      curve: const Cubic(0.2, 0.9, 0.2, 1.0),
                      builder: (context, v, _) => FractionallySizedBox(
                        widthFactor: clampD(v, 0, 1),
                        heightFactor: 1,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(99),
                            gradient: LinearGradient(colors: [HC.c, HC.c2]),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              VText('${fmt(math.max(c.goal - tot, 0))} هەنگاو ماوە تا ئامانج', style: ku(13, c: HC.mu)),
            ],
          ),
        ),
        const SourcesNote(demo: 'دیمۆی دیزاین · داتاکان نموونەن'),
      ],
    );
  }

  Widget _stat(String icon, String v, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: HC.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: HC.line),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            svgIcon(icon, HX.c, size: 22),
            const SizedBox(height: 6),
            VText(v, textDirection: TextDirection.ltr, style: nu(18, c: HC.tx)),
            VText(label, style: ku(12, c: HC.mu)),
          ],
        ),
      ),
    );
  }

  Widget _bar(int i, _StMode c, int mx) {
    final v = c.v[i];
    final zero = v == 0;
    final future = zero && i > c.now;
    final target = zero ? 0.0 : math.max(v / mx, 0.05);
    final delay = 0.06 + i * 0.018;
    final p = const Cubic(0.2, 0.9, 0.2, 1.0).transform(clampD((grow.value * 1.4 - delay) / 0.7, 0, 1));
    final h = math.max(3.0, 150 * target * p);
    final isSel = i == sel;
    double opacity = 0.55;
    if (zero && !future) opacity = 1;
    if (future) opacity = 0.25;
    if (isSel) opacity = 1;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => setState(() => sel = i),
      child: SizedBox(
        height: 150,
        child: Align(
          alignment: Alignment.bottomCenter,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: opacity,
            child: Container(
              height: h,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(6), bottom: Radius.circular(2)),
                color: zero ? HC.track : null,
                gradient: zero
                    ? null
                    : LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [HC.c2, vk(0x4003EAFB)],
                      ),
                boxShadow: isSel ? [BoxShadow(color: vk(0x5903EAFB), blurRadius: 14)] : null,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// بازنەی هەنگاو
class _StepsRing extends CustomPainter {
  _StepsRing(this.f);
  final double f;

  @override
  void paint(Canvas canvas, Size size) {
    final k = size.width / 200;
    final c = Offset(size.width / 2, size.height / 2);
    final r = 88 * k;
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 16 * k
        ..color = HC.track,
    );
    if (f <= 0.001) return;
    final rect = Rect.fromCircle(center: c, radius: r);
    final sweep = math.pi * 2 * clampD(f, 0, 1);
    canvas.drawArc(
      rect,
      -math.pi / 2,
      sweep,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 16 * k
        ..strokeCap = StrokeCap.round
        ..color = vk(0x5903EAFB)
        ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 10),
    );
    canvas.drawArc(
      rect,
      -math.pi / 2,
      sweep,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 16 * k
        ..strokeCap = StrokeCap.round
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [HC.c, HC.c2],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(covariant _StepsRing oldDelegate) => oldDelegate.f != f;
}

/// هێڵەکانی پشتەوەی ستوونەکان
class _GridLines extends CustomPainter {
  const _GridLines();

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = HC.line
      ..strokeWidth = 1;
    for (int i = 1; i <= 3; i++) {
      final y = size.height - size.height * i / 3 + 0.5;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), p);
    }
    canvas.drawLine(Offset(0, size.height - 0.5), Offset(size.width, size.height - 0.5), p);
  }

  @override
  bool shouldRepaint(covariant _GridLines oldDelegate) => false;
}
