// VEX Health — کارتی ئاو (پەرداخەکان)
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../core/icons.dart';
import '../core/store.dart';
import '../core/theme.dart';

class WaterCard extends StatefulWidget {
  const WaterCard({super.key});

  @override
  State<WaterCard> createState() => _WaterCardState();
}

class _WaterCardState extends State<WaterCard> with SingleTickerProviderStateMixin {
  late final AnimationController wave =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 2400))..repeat();
  int popIdx = -1;
  int popTick = 0;

  @override
  void dispose() {
    wave.dispose();
    super.dispose();
  }

  void setW(int n) {
    final s = Store.I;
    final prev = s.waterN;
    s.setWater(n);
    final now = s.waterN;
    if (now > prev) {
      setState(() {
        popIdx = now - 1;
        popTick++;
      });
      toast(now >= s.waterGlasses ? '🎉 ئامانجی ئاوت تەواو کرد!' : '💧 ${fmt(now * Store.glassMl)} ml');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(animation: Store.I, builder: (context, _) => _card());
  }

  Widget _card() {
    final s = Store.I;
    final wg = s.waterGlasses;
    final wn = s.waterN;
    final ml = wn * Store.glassMl;
    final gm = wg * Store.glassMl;
    final pct = math.min(100, (wn / wg * 100).round());
    final now = DateTime.now();
    final hh = now.hour + now.minute / 60;
    final exp = clampD((hh - 7) / 15, 0, 1);
    final expN = (exp * wg).round();
    final cols = wg <= 8 ? wg : (wg / 2).ceil();
    final rows = (wg / cols).ceil();
    final ok = wn >= expN;

    InlineSpan tip;
    if (wn >= wg) {
      tip = const TextSpan(text: '🎉 ئامانجی ئاوی ئەمڕۆت تەواو کرد! جەستەت سوپاست دەکات.');
    } else if (ok) {
      tip = TextSpan(
        text: '👍 بەپێی کاتەکە لە پێشیت. '
            '${hh < 20 ? 'بەردەوام بە، پەرداخی داهاتوو نزیکەی کاتژمێرێکی تر.' : 'ئەمشەو تەنها کەمێک بخۆرەوە بۆ ئەوەی خەوت تێک نەچێت.'}',
      );
    } else {
      final behind = expN - wn;
      tip = TextSpan(children: [
        const TextSpan(text: '⏰ تا ئێستا دەبوو '),
        TextSpan(text: '$expN', style: nu(12.5, c: V.tx)),
        TextSpan(
          text: ' پەرداخ خواردبێتەوە. ئێستا پەرداخێک بخۆرەوە، '
              '${behind > 1 ? 'هێشتا $behind پەرداخ لە دواوەیت.' : 'تەنها یەک پەرداخ لە دواوەیت.'}',
        ),
      ]);
    }

    return VCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [vk(0x403DB8FF), vk(0x1F2FE6F3)],
                  ),
                  border: Border.all(color: vk(0x593DB8FF)),
                ),
                child: svgIcon(Ico.drop, '#3db8ff', size: 20, fill: true),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    VText('ئاو', style: ku(16, w: FontWeight.w800)),
                    VText(wn >= wg ? 'ئامانج تەواو بوو 💙' : 'پەرداخێک = 250ml', style: ku(12, c: V.mu)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  VText(fmt(ml), textDirection: TextDirection.ltr, style: nu(19, c: vk(0xFF8FDCFF))),
                  VText('/ ${fmt(gm)} ml', textDirection: TextDirection.ltr, style: nu(11, w: FontWeight.w600, c: V.mu)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          for (int r = 0; r < rows; r++)
            Padding(
              padding: EdgeInsets.only(top: r > 0 ? 8 : 0, left: 2, right: 2),
              child: Row(
                children: [
                  for (int c = 0; c < cols; c++) ...[
                    if (c > 0) const SizedBox(width: 7),
                    Expanded(
                      child: (r * cols + c) < wg
                          ? AspectRatio(
                              aspectRatio: 40 / 52,
                              child: _Glass(
                                index: r * cols + c,
                                filled: (r * cols + c) < wn,
                                next: (r * cols + c) == wn,
                                wave: wave,
                                pop: (r * cols + c) == popIdx ? popTick : 0,
                                onTap: () {
                                  final i = r * cols + c;
                                  setW(i < wn ? i : i + 1);
                                },
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                  ],
                ],
              ),
            ),
          const SizedBox(height: 14),
          SizedBox(
            height: 8,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(9),
              child: Stack(
                children: [
                  Positioned.fill(child: ColoredBox(color: vk(0x12FFFFFF))),
                  Positioned.fill(
                    child: Align(
                      alignment: kIsLtr ? Alignment.centerLeft : Alignment.centerRight,
                      child: TweenAnimationBuilder<double>(
                        tween: Tween<double>(begin: pct / 100, end: pct / 100),
                        duration: const Duration(milliseconds: 700),
                        curve: const Cubic(0.2, 0.9, 0.25, 1.0),
                        builder: (context, v, _) => FractionallySizedBox(
                          widthFactor: clampD(v, 0, 1),
                          heightFactor: 1,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius: const BorderRadius.all(Radius.circular(9)),
                              gradient: LinearGradient(
                                begin: kIsLtr ? Alignment.centerLeft : Alignment.centerRight,
                                end: kIsLtr ? Alignment.centerRight : Alignment.centerLeft,
                                colors: [vk(0xFF1A8CFF), vk(0xFF3DB8FF), vk(0xFF8FF3F9)],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: Align(
                      alignment: Alignment(kIsLtr ? 2 * exp - 1 : 1 - 2 * exp, 0),
                      child: Container(width: 2, color: op(kW, 0.55)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: VText('$pct% · $wn لە $wg پەرداخ', style: ku(11, w: FontWeight.w700, c: V.mu)),
              ),
              if (wn >= wg)
                VText('✓ تەواو', style: ku(11, w: FontWeight.w700, c: V.mu))
              else
                VText.rich(
                  TextSpan(children: [
                    TextSpan(text: '${fmt(gm - ml)} ml', style: nu(11, w: FontWeight.w700, c: V.mu)),
                    const TextSpan(text: ' ماوە'),
                  ]),
                  style: ku(11, w: FontWeight.w700, c: V.mu),
                ),
            ],
          ),
          Container(
            margin: const EdgeInsets.only(top: 12),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: ok ? vk(0x143CF08A) : vk(0x143DB8FF),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: ok ? vk(0x403CF08A) : vk(0x383DB8FF)),
            ),
            child: VText.rich(tip, style: ku(12.5, h: 1.7)),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Press(
                onTap: () => setW(wn - 1),
                child: Container(
                  width: 48,
                  height: 46,
                  alignment: Alignment.center,
                  decoration: box(r: 15),
                  child: VText('−', style: nu(18, w: FontWeight.w700)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Press(
                  onTap: () => setW(wn + 1),
                  child: Container(
                    height: 46,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [vk(0xFF3DB8FF), vk(0xFF1A8CFF)],
                      ),
                      boxShadow: [
                        BoxShadow(color: vk(0x991A8CFF), blurRadius: 22, offset: Offset(0, 10), spreadRadius: -10),
                      ],
                    ),
                    child: VText('💧 پەرداخێک خواردمەوە', style: ku(14, w: FontWeight.w800, c: Colors.white)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Glass extends StatefulWidget {
  const _Glass({
    required this.index,
    required this.filled,
    required this.next,
    required this.wave,
    required this.pop,
    required this.onTap,
  });

  final int index;
  final bool filled;
  final bool next;
  final Animation<double> wave;
  final int pop;
  final VoidCallback onTap;

  @override
  State<_Glass> createState() => _GlassState();
}

class _GlassState extends State<_Glass> with SingleTickerProviderStateMixin {
  late final AnimationController _pop =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 500));

  @override
  void didUpdateWidget(covariant _Glass oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.pop != oldWidget.pop && widget.pop > 0) _pop.forward(from: 0);
  }

  @override
  void dispose() {
    _pop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final target = widget.filled ? 1.0 : 0.0;
    return Press(
      onTap: widget.onTap,
      scale: 0.9,
      child: AnimatedBuilder(
        animation: _pop,
        builder: (context, child) => Transform.scale(
          scale: 1 + 0.14 * math.sin(math.pi * _pop.value),
          child: child,
        ),
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: target, end: target),
          duration: const Duration(milliseconds: 700),
          curve: const Cubic(0.2, 0.9, 0.25, 1.0),
          builder: (context, lv, _) => CustomPaint(
            painter: _GlassPainter(
              level: lv,
              filled: widget.filled,
              next: widget.next,
              wave: widget.wave,
              phase: ((widget.index * 0.37) % 2.4) / 2.4,
            ),
          ),
        ),
      ),
    );
  }
}

class _GlassPainter extends CustomPainter {
  _GlassPainter({
    required this.level,
    required this.filled,
    required this.next,
    required this.wave,
    required this.phase,
  }) : super(repaint: wave);

  final double level;
  final bool filled;
  final bool next;
  final Animation<double> wave;
  final double phase;

  static TextStyle get _plusStyle => nu(16, c: vk(0xE63DB8FF));

  static Path _cup() => Path()
    ..moveTo(6, 4)
    ..lineTo(34, 4)
    ..lineTo(30.4, 47.6)
    ..quadraticBezierTo(30, 50, 27.6, 50)
    ..lineTo(12.4, 50)
    ..quadraticBezierTo(10, 50, 9.6, 47.6)
    ..close();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 40, size.height / 52);
    final cup = _cup();

    canvas.drawPath(cup, Paint()..color = filled ? vk(0x0F3DB8FF) : vk(0x09FFFFFF));

    if (level > 0.001) {
      canvas.save();
      canvas.clipPath(cup);
      canvas.translate(0, 46 * (1 - level));
      final wx = -40 * ((wave.value + phase) % 1.0);
      final w = Path()
        ..moveTo(-40 + wx, 12)
        ..quadraticBezierTo(-30 + wx, 8, -20 + wx, 12);
      for (int k = 0; k < 5; k++) {
        final x0 = -20.0 + 20 * k + wx;
        w.quadraticBezierTo(x0 + 10, k.isEven ? 16.0 : 8.0, x0 + 20, 12);
      }
      w
        ..lineTo(80 + wx, 60)
        ..lineTo(-40 + wx, 60)
        ..close();
      canvas.drawPath(
        w,
        Paint()
          ..shader = ui.Gradient.linear(
            const Offset(0, 8),
            const Offset(0, 60),
            [vk(0xFF8FF3F9), vk(0xFF3DB8FF), vk(0xFF1A6DFF)],
            const [0.0, 0.5, 1.0],
          ),
      );
      final shine = Path()
        ..moveTo(10, 14)
        ..lineTo(12, 44)
        ..lineTo(14, 44)
        ..lineTo(12.5, 14)
        ..close();
      canvas.drawPath(shine, Paint()..color = vk(0x59FFFFFF));
      canvas.restore();
    }

    final ol = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeJoin = StrokeJoin.round;
    if (next) {
      final pulse = 0.675 + 0.325 * math.cos(math.pi * 2 * wave.value);
      ol.color = op(vk(0xFF3DB8FF), pulse);
      for (final m in cup.computeMetrics()) {
        double d = 0;
        while (d < m.length) {
          canvas.drawPath(m.extractPath(d, math.min(m.length, d + 3)), ol);
          d += 6;
        }
      }
      final tp = TextPainter(
        text: TextSpan(text: '+', style: _plusStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      final base = tp.computeDistanceToActualBaseline(TextBaseline.alphabetic);
      tp.paint(canvas, Offset(20 - tp.width / 2, 33 - base));
    } else {
      ol.color = filled ? vk(0xBF8FDCFF) : vk(0x478FDCFF);
      canvas.drawPath(cup, ol);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _GlassPainter oldDelegate) => true;
}
