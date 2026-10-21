// VEX Health — دروستکردنی پلان (بازنەی سەدی + کارتی تایبەتمەندییەکان) و کورتەی پلان
import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../core/theme.dart';
import 'reg_data.dart';
import 'reg_icons.dart';
import 'reg_widgets.dart';

/// کاتێک پلانەکە دروست دەکرێت، 7 تایبەتمەندی یەک لە دوای یەک نیشان دەدرێن
class RBuildShow extends StatefulWidget {
  const RBuildShow({super.key, required this.bandHas, required this.onDone, this.compact = false});
  final bool bandHas;
  final VoidCallback onDone;
  final bool compact;

  @override
  State<RBuildShow> createState() => _RBuildShowState();
}

class _RBuildShowState extends State<RBuildShow> with TickerProviderStateMixin {
  static const int _per = 1050;
  late final AnimationController _c =
      AnimationController(vsync: this, duration: Duration(milliseconds: kBuildFeats.length * _per));
  late final AnimationController _spin =
      AnimationController(vsync: this, duration: const Duration(seconds: 14))..repeat();
  Timer? _end;

  late final List<String> _steps = [
    'شیکردنەوەی زانیاری جەستەت',
    'دانانی ئامانجی هەنگاو و جووڵە',
    'ڕێکخستنی خەو و یادخستنەوەکان',
    widget.bandHas ? 'پەیوەستکردنی داتای Band' : 'ئامادەکردنی داشبۆردەکەت',
  ];

  @override
  void initState() {
    super.initState();
    _c.addStatusListener((s) {
      if (s == AnimationStatus.completed) {
        _end = Timer(const Duration(milliseconds: 500), () {
          if (mounted) widget.onDone();
        });
      }
    });
    _c.forward();
  }

  @override
  void dispose() {
    _end?.cancel();
    _c.dispose();
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ring = widget.compact ? 124.0 : 150.0;
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final p = _c.value;
        final e = 1 - math.pow(1 - p, 1.6).toDouble();
        final fi = math.min(kBuildFeats.length - 1, (p * kBuildFeats.length).floor());
        final si = math.min(_steps.length - 1, (p * _steps.length).floor());
        final f = kBuildFeats[fi];
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: widget.compact ? 2 : 12),
            SizedBox(
              width: ring + 20,
              height: ring + 20,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  RotationTransition(
                    turns: _spin,
                    child: CustomPaint(size: Size(ring + 20, ring + 20), painter: _Dashed()),
                  ),
                  CustomPaint(size: Size(ring, ring), painter: _Ring(e)),
                  Directionality(
                    textDirection: TextDirection.ltr,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('${(e * 100).round()}', style: nu(widget.compact ? 30 : 36, h: 1)),
                        Padding(
                          padding: const EdgeInsets.only(left: 2, bottom: 3),
                          child: Text('%', style: nu(widget.compact ? 15 : 18, c: RC.mu, h: 1)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const RTitle('پلانەکەت دروست دەکەین…', center: true),
            const RPara([TextSpan(text: 'تا ئامادە دەبێت، ئەمە ئەوەیە کە VEX بۆت دەکات:')], center: true, bottom: 14),
            SizedBox(
              height: 118,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 450),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                layoutBuilder: (cur, prev) => Stack(
                  fit: StackFit.expand,
                  children: [...prev, if (cur != null) cur],
                ),
                transitionBuilder: (child, anim) {
                  final incoming = child.key == ValueKey<int>(fi);
                  return AnimatedBuilder(
                    animation: anim,
                    builder: (context, ch) {
                      final v = anim.value;
                      final dy = incoming ? 14 * (1 - v) : -14 * (1 - v);
                      return Opacity(
                        opacity: v,
                        child: Transform.translate(
                          offset: Offset(0, dy),
                          child: Transform.scale(scale: 0.97 + 0.03 * v, child: ch),
                        ),
                      );
                    },
                    child: child,
                  );
                },
                child: _FeatCard(key: ValueKey<int>(fi), f: f),
              ),
            ),
            const SizedBox(height: 12),
            Directionality(
              textDirection: TextDirection.ltr,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (int i = 0; i < kBuildFeats.length; i++)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: i == fi ? 18 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(9),
                        color: i == fi ? V.mint : RC.white(0.18),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text.rich(
              TextSpan(children: [
                TextSpan(text: '✓ ', style: ku(13, w: FontWeight.w800, c: V.mint)),
                TextSpan(text: '${_steps[si]}…'),
              ]),
              textAlign: TextAlign.center,
              style: ku(13, w: FontWeight.w700, c: RC.mu),
            ),
          ],
        );
      },
    );
  }
}

class _FeatCard extends StatelessWidget {
  const _FeatCard({super.key, required this.f});
  final RFeat f;

  @override
  Widget build(BuildContext context) {
    final k = Color(f.c);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [op(k, 0.18), RC.white(0.03)],
        ),
        border: Border.all(color: op(k, 0.40)),
        boxShadow: [BoxShadow(color: op(k, 0.35), blurRadius: 40, offset: const Offset(0, 18), spreadRadius: -26)],
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              color: op(k, 0.22),
              boxShadow: [BoxShadow(color: op(k, 0.6), blurRadius: 26, spreadRadius: -6)],
            ),
            child: RIco(f.e, size: 58, radius: 18, color: k),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(f.t, maxLines: 1, overflow: TextOverflow.ellipsis, style: ku(16, w: FontWeight.w800, h: 1.45)),
                const SizedBox(height: 2),
                Text(f.s, maxLines: 2, overflow: TextOverflow.ellipsis, style: ku(12.5, c: const Color(0xFFA9CFD5), h: 1.6)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Ring extends CustomPainter {
  _Ring(this.p);
  final double p;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2 - 5;
    final rect = Rect.fromCircle(center: c, radius: r);
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7
        ..color = const Color(0x12FFFFFF),
    );
    if (p <= 0) return;
    canvas.drawArc(
      rect,
      -math.pi / 2,
      math.pi * 2 * p,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 9
        ..strokeCap = StrokeCap.round
        ..color = const Color(0x663CF08A)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7),
    );
    canvas.drawArc(
      rect,
      -math.pi / 2,
      math.pi * 2 * p,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7
        ..strokeCap = StrokeCap.round
        ..shader = ui.Gradient.linear(rect.topLeft, rect.bottomRight, const [Color(0xFF8FF3F9), Color(0xFF3CF08A)]),
    );
  }

  @override
  bool shouldRepaint(_Ring o) => o.p != p;
}

class _Dashed extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2 - 1;
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = const Color(0x338CEBF5);
    const n = 48;
    for (int i = 0; i < n; i++) {
      canvas.drawArc(Rect.fromCircle(center: c, radius: r), i / n * math.pi * 2, math.pi * 2 / n * 0.5, false, p);
    }
  }

  @override
  bool shouldRepaint(_Dashed o) => false;
}

/// کورتەی پلانەکە پاش دروستبوون
class RPlanSummary extends StatelessWidget {
  const RPlanSummary({super.key, required this.d, this.compact = false});
  final RegDraft d;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final p = d.plan();
    final c = bmiCat(p.bmi);
    ROpt? a;
    for (final x in kActs) {
      if (x.k == d.act) a = x;
    }
    final first = firstWord(d.name);
    final ini = first.isEmpty ? 'V' : String.fromCharCode(first.runes.first).toUpperCase();
    final showGoal = d.tw > 0 && d.wGoal != 'keep';
    final tiles = <Widget>[
      RPlanTile(icon: '👣', label: 'هەنگاوی ڕۆژانە', value: fmt(p.steps), sub: 'بە پێی ئاستی چالاکیت', color: V.cy, compact: compact),
      RPlanTile(
          icon: '🌙',
          label: 'ئامانجی خەو',
          value: numTxt(p.sleep),
          unit: 'کاتژمێر',
          sub: 'خەوتن ${d.bed} · هەستان ${d.wake}',
          color: RC.lilac,
          compact: compact),
      RPlanTile(
          icon: '💧',
          label: 'ئاوی ڕۆژانە',
          value: _liters(p.water),
          unit: 'لیتر',
          sub: 'نزیکەی ${p.glasses} پەرداخ',
          color: V.cy,
          compact: compact),
      RPlanTile(icon: '⏱️', label: 'جووڵەی چالاک', value: '${p.act}', unit: 'خولەک', sub: 'لە ڕۆژێکدا', color: V.mint, compact: compact),
      RPlanTile(icon: '⚖️', label: 'BMI', value: p.bmi.toStringAsFixed(1), sub: c.label, color: c.color, compact: compact),
      RPlanTile(
          icon: '❤️',
          label: 'زۆرترین لێدانی دڵ',
          value: '${p.hrMax}',
          unit: 'bpm',
          sub: d.band.has == true ? 'Band لە کاتی وەرزشدا چاودێری دەکات' : 'بۆ وەرزشی سەلامەت',
          color: V.coral,
          compact: compact),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Rise(
          child: Container(
            padding: EdgeInsets.all(compact ? 11 : 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(26),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0x242FE6F3), Color(0x0F3CF08A)],
              ),
              border: Border.all(color: const Color(0x472FE6F3)),
            ),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      center: Alignment(-0.3, -0.4),
                      colors: [Color(0xFF8FF3F9), Color(0xFF14B8D6), Color(0xFF0B5F73)],
                      stops: [0, 0.6, 1],
                    ),
                    boxShadow: [
                      BoxShadow(color: Color(0x242FE6F3), spreadRadius: 5),
                      BoxShadow(color: Color(0x732FE6F3), blurRadius: 30),
                    ],
                  ),
                  child: Text(ini, style: ku(21, w: FontWeight.w800, c: V.ink, h: 1.2)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('پلانەکەت ئامادەیە، $first!', style: ku(17.5, w: FontWeight.w800, h: 1.45)),
                      Text.rich(
                        TextSpan(children: [
                          numSpan('${d.age}', size: 12, c: RC.p, w: FontWeight.w700),
                          const TextSpan(text: ' ساڵ · '),
                          numSpan('${d.h}', size: 12, c: RC.p, w: FontWeight.w700),
                          const TextSpan(text: ' cm · '),
                          numSpan(numTxt(d.w), size: 12, c: RC.p, w: FontWeight.w700),
                          TextSpan(text: ' kg${a != null ? ' · ${a.t}' : ''}'),
                          if (showGoal) ...[
                            const TextSpan(text: '\n'),
                            ricoSpan('🎯', size: 13, color: V.amber),
                            const TextSpan(text: 'ئامانج: '),
                            numSpan('${d.kgTxt(d.w)} → ${d.kgTxt(d.tw)}', size: 12, c: RC.p, w: FontWeight.w700),
                          ],
                        ]),
                        style: ku(12, c: RC.p, h: 1.6),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: compact ? 8 : 10),
        LayoutBuilder(
          builder: (context, cons) {
            final w = (cons.maxWidth - 8) / 2;
            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (int i = 0; i < tiles.length; i++)
                  SizedBox(width: w, child: Rise(delayMs: 50 + i * 50, child: tiles[i])),
              ],
            );
          },
        ),
        SizedBox(height: compact ? 8 : 10),
        Rise(
          delayMs: 300,
          child: Container(
            padding: EdgeInsets.all(compact ? 11 : 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: const LinearGradient(
                begin: Alignment.centerRight,
                end: Alignment.centerLeft,
                colors: [Color(0x1FFFBE4D), Color(0x0FFF5F7E)],
              ),
              border: Border.all(color: const Color(0x4DFFBE4D)),
            ),
            child: Row(
              children: [
                const RIco('🍽️', size: 46, radius: 15),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('پلانی خواردنت لە بەشی خواردن دادەنرێت', style: ku(13.5, w: FontWeight.w800, h: 1.5)),
                      if (!compact)
                        Text(
                          'یەکەم جار کە دەچیتە بەشی خواردن، چەند پرسیارێکی کورتی خواردنت لێدەکەین و کالۆری ڕۆژانەت دادەنێین.',
                          style: ku(11.5, c: const Color(0xFFD9C9A8), h: 1.6),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  static String _liters(int ml) {
    final l = ml / 1000;
    final s = l.toStringAsFixed(2);
    return s.endsWith('0') ? (s.endsWith('00') ? l.toStringAsFixed(0) : l.toStringAsFixed(1)) : s;
  }
}
