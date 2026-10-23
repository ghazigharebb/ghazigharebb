// VEX Health — نیشانە زیندووەکان، بازنەکانی چالاکی و ڕوونکردنەوەی ڕەنگەکان
import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../band/band_widgets.dart';
import '../core/icons.dart';
import '../core/theme.dart';
import 'hc.dart';
import 'heart_page.dart';
import 'spo2_page.dart';
import 'steps_page.dart';
import 'stress_page.dart';
import '../plus/gate.dart';

enum Viz { ecg, drop, gauge, hrv, active }

class _Tile {
  const _Tile(this.n, this.icon, this.v, this.u, this.f, this.st, this.k, this.hex, this.viz, this.open);
  final String n;
  final String icon;
  final String v;
  final String u;
  final String f;
  final String st;
  final Color k;
  final String hex;
  final Viz viz;
  final VoidCallback open;
}

void _openHeart() => pushPage(const GatePage(kind: GateKind.band, id: 'heart', child: HeartPage()));
void _openSpo2() => pushPage(const GatePage(kind: GateKind.band, id: 'spo2', child: Spo2Page()));
void _openStress() => pushPage(const GatePage(kind: GateKind.band, id: 'stress', child: StressPage()));
void _openSteps() => pushPage(const StepsPage());

/// تایلی نیشانەیەک
class _VitalTile extends StatelessWidget {
  const _VitalTile({required this.t, required this.viz, this.iconWrap});
  final _Tile t;
  final Widget viz;
  final Widget Function(Widget icon)? iconWrap;

  @override
  Widget build(BuildContext context) => BandBuilder(builder: (context, on) => on ? _online() : _offline());

  /// دۆخی «Band پەیوەست نییە» (دیزاینی B): ژمارە «—»، هێڵی خاڵخاڵ، «پەیوەست نییە» + دوایین بەها
  Widget _offline() {
    return Press(
      onTap: t.open,
      child: _TileShell(
        k: HC.mu,
        off: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: vk(0x0FFFFFFF), borderRadius: BorderRadius.circular(12)),
                  child: svgIcon(t.icon, HX.mu, size: 19),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: VText(t.n,
                      maxLines: 1, overflow: TextOverflow.ellipsis, style: ku(14, w: FontWeight.w600, c: HC.tx)),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 4),
              child: SizedBox(height: 34, width: double.infinity, child: CustomPaint(painter: DashedLinePainter())),
            ),
            VText.rich(
              TextSpan(children: [
                TextSpan(text: '—', style: nu(30, c: HC.mu, h: 1.0)),
                if (t.u.isNotEmpty) TextSpan(text: ' ${t.u}', style: ku(12, c: HC.mu)),
              ]),
              textDirection: TextDirection.ltr,
            ),
            const SizedBox(height: 6),
            OfflineCaption(last: t.v, unit: t.u),
          ],
        ),
      ),
    );
  }

  Widget _online() {
    final sc = statusColor(t.f);
    Widget icon = svgIcon(t.icon, t.hex, size: 19);
    final wrap = iconWrap;
    if (wrap != null) icon = wrap(icon);
    return Press(
      onTap: t.open,
      child: _TileShell(
        k: t.k,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: op(t.k, 0.18), borderRadius: BorderRadius.circular(12)),
                  child: icon,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: VText(t.n,
                      maxLines: 1, overflow: TextOverflow.ellipsis, style: ku(14, w: FontWeight.w600, c: HC.tx)),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 4),
              child: SizedBox(height: 54, width: double.infinity, child: viz),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                VText.rich(
                  TextSpan(children: [
                    TextSpan(text: t.v, style: nu(30, c: HC.tx, h: 1.0)),
                    if (t.u.isNotEmpty) TextSpan(text: ' ${t.u}', style: ku(12, c: HC.mu)),
                  ]),
                  textDirection: TextDirection.ltr,
                ),
                const Spacer(),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    svgIcon(HI.face[t.f]!, statusHex(t.f), size: 17, stroke: 1.8),
                    const SizedBox(width: 4),
                    VText(t.st, style: ku(12, w: FontWeight.w700, c: sc)),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// چوارچێوەی تایل (ڕەنگ، هێڵ و ڕووناکی سەرەوە)
class _TileShell extends StatelessWidget {
  const _TileShell({required this.k, required this.child, this.center = false, this.off = false});
  final Color k;
  final Widget child;
  final bool center;

  /// دۆخی Band پەیوەست نییە: بێ ڕووناکی ڕەنگاوڕەنگ و بێ پڕکردنەوە
  final bool off;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: off ? Colors.transparent : HC.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: off ? HC.line : mix(HC.line, k, 0.35)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            if (!off)
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0.6, -1.1),
                    radius: 0.85,
                    colors: [op(k, 0.18), op(k, 0)],
                    stops: const [0.0, 0.7],
                  ),
                ),
              ),
            ),
            Padding(padding: const EdgeInsets.all(14), child: center ? Center(child: child) : child),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// نیشانە زیندووەکان (٤ تایل)
// ============================================================
class VitalsGrid extends StatefulWidget {
  const VitalsGrid({super.key});

  @override
  State<VitalsGrid> createState() => _VitalsGridState();
}

class _VitalsGridState extends State<VitalsGrid> with TickerProviderStateMixin {
  late final AnimationController beat =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 882))..repeat();
  late final AnimationController ecg =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1700))..repeat();
  late final AnimationController wave =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 3000))..repeat();
  late final AnimationController hrv =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 2800))..repeat();
  late final AnimationController needle =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));
  late final Animation<double> beatScale = TweenSequence<double>([
    TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 1.2), weight: 14),
    TweenSequenceItem(tween: Tween<double>(begin: 1.2, end: 1.0), weight: 14),
    TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 1.1), weight: 14),
    TweenSequenceItem(tween: Tween<double>(begin: 1.1, end: 1.0), weight: 14),
    TweenSequenceItem(tween: ConstantTween<double>(1.0), weight: 44),
  ]).animate(beat);
  Timer? _t;

  List<_Tile> get tiles => [
    _Tile('لێدانی دڵ', HI.heart, '68', 'bpm', 'ok', 'باش', HC.bd, HX.bd, Viz.ecg, _openHeart),
    _Tile('ئۆکسجین', HI.drop, '95', '%', 'ok', 'باش', HC.c, HX.c, Viz.drop, _openSpo2),
    _Tile('سترێس', HI.brain, '60', '', 'wn', 'مامناوەند', HC.wn, HX.wn, Viz.gauge, _openStress),
    _Tile('HRV', HI.wave, '48', 'ms', 'ok', 'ئاسایی', HC.c2, HX.c2, Viz.hrv, _openStress),
  ];

  @override
  void initState() {
    super.initState();
    _t = Timer(const Duration(milliseconds: 350), () {
      if (mounted) needle.forward();
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    beat.dispose();
    ecg.dispose();
    wave.dispose();
    hrv.dispose();
    needle.dispose();
    super.dispose();
  }

  Widget _viz(Viz v) {
    switch (v) {
      case Viz.ecg:
        return CustomPaint(painter: _EcgViz(ecg));
      case Viz.drop:
        return CustomPaint(painter: _DropViz(wave));
      case Viz.gauge:
        return CustomPaint(painter: _GaugeViz(needle));
      case Viz.hrv:
        return CustomPaint(painter: _HrvViz(hrv));
      case Viz.active:
        return const CustomPaint(painter: _ActiveViz());
    }
  }

  Widget _tile(int i) {
    final t = tiles[i];
    return Rise(
      delayMs: 150 + i * 80,
      child: _VitalTile(
        t: t,
        viz: _viz(t.viz),
        iconWrap: t.viz == Viz.ecg ? (w) => ScaleTransition(scale: beatScale, child: w) : null,
      ),
    );
  }

  Widget _row(int a, int b) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: _tile(a)),
          const SizedBox(width: 12),
          Expanded(child: _tile(b)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Column(
        children: [
          _row(0, 1),
          const SizedBox(height: 12),
          _row(2, 3),
        ],
      ),
    );
  }
}

// ============================================================
// خولەکی چالاک + ئامانجی هەنگاو
// ============================================================
class ActivityGrid2 extends StatelessWidget {
  const ActivityGrid2({super.key});

  @override
  Widget build(BuildContext context) {
    final active = _Tile('خولەکی چالاک', HI.timer, '0', 'min', 'wn', 'کەم', HC.wn, HX.wn, Viz.active, _openSteps);
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Rise(
                delayMs: 470,
                child: _VitalTile(t: active, viz: const CustomPaint(painter: _ActiveViz())),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Rise(
                delayMs: 600,
                child: BandBuilder(
                  builder: (context, on) => Press(
                    onTap: _openSteps,
                    child: _TileShell(
                      k: on ? HC.c : HC.mu,
                      off: !on,
                      center: true,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 34,
                            height: 34,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                                color: on ? op(HC.c, 0.18) : vk(0x0FFFFFFF),
                                borderRadius: BorderRadius.circular(12)),
                            child: svgIcon(HI.step, on ? HX.c : HX.mu, size: 19),
                          ),
                          const SizedBox(height: 8),
                          VText('ئامانجی هەنگاوی ئەمڕۆ', textAlign: TextAlign.center, style: ku(13, c: HC.mu)),
                          const SizedBox(height: 8),
                          if (on)
                            VText('24%', textDirection: TextDirection.ltr, style: nu(24, c: HC.tx))
                          else ...[
                            VText('—', textDirection: TextDirection.ltr, style: nu(24, c: HC.mu)),
                            const SizedBox(height: 4),
                            const OfflineCaption(),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// بازنەکانی چالاکی
// ============================================================
class _Ring {
  const _Ring(this.n, this.v, this.g, this.f, this.k, this.hex, this.icon, this.r);
  final String n;
  final String v;
  final String g;
  final double f;
  final Color k;
  final String hex;
  final String icon;
  final double r;
}

class ActivityRingsCard extends StatefulWidget {
  const ActivityRingsCard({super.key});

  @override
  State<ActivityRingsCard> createState() => _ActivityRingsCardState();
}

class _ActivityRingsCardState extends State<ActivityRingsCard> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600));
  Timer? _t;

  List<_Ring> get rings => [
    _Ring('هەنگاو', '2,416', '/ 10,000', 0.2416, HC.c, HX.c, HI.step, 62),
    _Ring('کالۆری', '70', 'kcal', 70 / 300, HC.ok, HX.ok, HI.fire, 47),
    _Ring('مەودا', '1.62', 'km', 1.62 / 5, HC.orange, HX.orange, HI.pin, 32),
  ];

  @override
  void initState() {
    super.initState();
    _t = Timer(const Duration(milliseconds: 350), () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    _c.dispose();
    super.dispose();
  }

  Widget _row(_Ring r, bool on) {
    return Row(
      children: [
        Container(
          width: 30,
          height: 30,
          alignment: Alignment.center,
          decoration: BoxDecoration(
              color: on ? op(r.k, 0.16) : vk(0x0FFFFFFF), borderRadius: BorderRadius.circular(10)),
          child: svgIcon(r.icon, on ? r.hex : HX.mu, size: 17),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(child: VText(r.n, style: ku(13, c: HC.mu))),
                  if (on)
                    VText.rich(
                      TextSpan(children: [
                        TextSpan(text: r.v, style: nu(16, c: HC.tx)),
                        TextSpan(text: ' ${r.g}', style: ku(11, c: HC.mu)),
                      ]),
                      textDirection: TextDirection.ltr,
                    )
                  else
                    VText('—', textDirection: TextDirection.ltr, style: nu(16, c: HC.mu)),
                ],
              ),
              const SizedBox(height: 4),
              if (!on)
                SizedBox(height: 6, width: double.infinity, child: CustomPaint(painter: DashedLinePainter(opacity: 0.45)))
              else
              ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: Container(
                  height: 6,
                  color: HC.track,
                  alignment: Alignment.centerLeft,
                  child: AnimatedBuilder(
                    animation: _c,
                    builder: (context, _) => FractionallySizedBox(
                      widthFactor: clampD(r.f, 0, 1) *
                          const Cubic(0.2, 0.9, 0.2, 1.0).transform(clampD(_c.value * 1.6 / 1.4, 0, 1)),
                      heightFactor: 1,
                      child: DecoratedBox(
                        decoration: BoxDecoration(color: r.k, borderRadius: BorderRadius.circular(99)),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) => BandBuilder(builder: (context, on) => _card(on));

  Widget _card(bool on) {
    final body = Press(
      onTap: _openSteps,
      scale: 0.98,
      child: Container(
        margin: const EdgeInsets.only(top: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: on ? HC.card : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: HC.line),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 132,
              height: 132,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: AnimatedBuilder(
                      animation: _c,
                      builder: (context, _) => CustomPaint(
                        painter: _RingsPainter(rings, const Cubic(0.2, 0.9, 0.2, 1.0).transform(_c.value), off: !on),
                      ),
                    ),
                  ),
                  Center(child: svgIcon(HI.step, on ? HX.c : HX.mu, size: 21)),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                children: [
                  for (int i = 0; i < rings.length; i++) ...[
                    if (i > 0) const SizedBox(height: 11),
                    _row(rings[i], on),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
    if (on) return body;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        body,
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 10, 4, 0),
          child: VText.rich(
            TextSpan(children: [
              const TextSpan(text: 'پەیوەست نییە. دوایین ژمارە: '),
              TextSpan(text: rings[0].v, style: nu(12.5, w: FontWeight.w700, c: BandColors.label)),
              const TextSpan(text: ' هەنگاو'),
            ]),
            style: ku(12.5, w: FontWeight.w600, c: BandColors.label, h: 1.6),
          ),
        ),
      ],
    );
  }
}

class _RingsPainter extends CustomPainter {
  _RingsPainter(this.rings, this.t, {this.off = false});
  final List<_Ring> rings;
  final double t;
  final bool off;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 150;
    final c = Offset(size.width / 2, size.height / 2);
    for (final r in rings) {
      final rad0 = r.r * s;
      if (off) {
        paintDashedCircle(canvas, c, rad0, op(HC.mu, 0.6), 6 * s);
        continue;
      }
      canvas.drawCircle(
        c,
        rad0,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 11 * s
          ..color = op(r.k, 0.16),
      );
      final sweep = math.pi * 2 * clampD(r.f, 0, 1) * t;
      if (sweep <= 0.001) continue;
      final rect = Rect.fromCircle(center: c, radius: rad0);
      canvas.drawArc(
        rect,
        -math.pi / 2,
        sweep,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 11 * s
          ..strokeCap = StrokeCap.round
          ..color = op(r.k, 0.6)
          ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 4),
      );
      canvas.drawArc(
        rect,
        -math.pi / 2,
        sweep,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 11 * s
          ..strokeCap = StrokeCap.round
          ..color = r.k,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RingsPainter oldDelegate) => oldDelegate.t != t || oldDelegate.off != off;
}

// ============================================================
// ڕوونکردنەوەی ڕەنگەکان (باش، مامناوەند ...)
// ============================================================
class HealthLegend extends StatelessWidget {
  const HealthLegend({super.key});

  @override
  Widget build(BuildContext context) {
    const items = [
      ['ok', 'باش'],
      ['wn', 'مامناوەند'],
      ['bd', 'خراپ'],
      ['nd', 'داتا نییە'],
    ];
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final it in items)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: HC.card,
                borderRadius: BorderRadius.circular(99),
                border: Border.all(color: op(statusColor(it[0]), 0.45)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  svgIcon(HI.face[it[0]]!, statusHex(it[0]), size: 16, stroke: 1.8),
                  const SizedBox(width: 5),
                  VText(it[1], style: ku(12, w: FontWeight.w600, c: statusColor(it[0]))),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ============================================================
// وێنەکانی ناو تایلەکان
// ============================================================

/// گۆڕینی viewBox بۆ قەبارەی ڕاستەقینە (وەک SVG: meet + ناوەڕاست)
double _fit(Canvas canvas, Size size, double vw, double vh) {
  final s = math.min(size.width / vw, size.height / vh);
  canvas.translate((size.width - vw * s) / 2, (size.height - vh * s) / 2);
  canvas.scale(s);
  return s;
}

/// ECG ـی دڵ
class _EcgViz extends CustomPainter {
  _EcgViz(this.a) : super(repaint: a);
  final Animation<double> a;

  static const List<List<double>> _q = [
    [10, 28], [14, 22], [18, 28], [22, 28], [24, 34], [27, 6], [30, 44], [33, 28], [40, 28],
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / 120, sy = size.height / 50;
    final path = Path()..moveTo(0, 28 * sy);
    for (int i = 0; i < 3; i++) {
      final x = i * 40.0;
      for (final q in _q) {
        path.lineTo((x + q[0]) * sx, q[1] * sy);
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = op(HC.bd, 0.2),
    );
    final metrics = path.computeMetrics().toList();
    if (metrics.isEmpty) return;
    final m = metrics.first;
    final len = m.length;
    final seg = len * 46 / 246;
    final s0 = a.value * len;
    final part = Path()..addPath(m.extractPath(s0, math.min(len, s0 + seg)), Offset.zero);
    if (s0 + seg > len) part.addPath(m.extractPath(0, s0 + seg - len), Offset.zero);
    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(
      part,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round
        ..color = op(HC.bd, 0.7)
        ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 4),
    );
    canvas.drawPath(part, base..color = HC.bd);
  }

  @override
  bool shouldRepaint(covariant _EcgViz oldDelegate) => false;
}

/// دڵۆپی ئۆکسجین
class _DropViz extends CustomPainter {
  _DropViz(this.a) : super(repaint: a);
  final Animation<double> a;

  static TextStyle get _o2 => ku(11, w: FontWeight.w800, c: kW);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    _fit(canvas, size, 120, 54);
    final drop = Path()
      ..moveTo(60, 2)
      ..cubicTo(60, 2, 80, 23, 80, 36)
      ..arcToPoint(const Offset(40, 36), radius: const Radius.circular(20), clockwise: true)
      ..cubicTo(40, 23, 60, 2, 60, 2)
      ..close();
    canvas.drawPath(drop, Paint()..color = vk(0x0FFFFFFF));
    canvas.drawPath(
      drop,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = op(HC.c, 0.5),
    );
    canvas.save();
    canvas.clipPath(drop);
    canvas.translate(-40 * a.value, 0);
    final w = Path()
      ..moveTo(20, 9)
      ..quadraticBezierTo(30, 5, 40, 9)
      ..quadraticBezierTo(50, 13, 60, 9)
      ..quadraticBezierTo(70, 5, 80, 9)
      ..quadraticBezierTo(90, 13, 100, 9)
      ..quadraticBezierTo(110, 5, 120, 9)
      ..quadraticBezierTo(130, 13, 140, 9)
      ..lineTo(140, 60)
      ..lineTo(20, 60)
      ..close();
    canvas.drawPath(w, Paint()..color = op(HC.c, 0.75));
    canvas.restore();
    paintText(canvas, 'O₂', const Offset(60, 42), _o2, align: TextAlign.center);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _DropViz oldDelegate) => false;
}

/// پێوەری سترێس
class _GaugeViz extends CustomPainter {
  _GaugeViz(this.a) : super(repaint: a);
  final Animation<double> a;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    _fit(canvas, size, 100, 52);
    Paint arc(Color c) => Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round
      ..color = c;
    const r = Radius.circular(40);
    canvas.drawPath(Path()
      ..moveTo(10, 46)
      ..arcToPoint(const Offset(30, 11.4), radius: r, clockwise: true), arc(HC.ok));
    canvas.drawPath(Path()
      ..moveTo(31.5, 10.6)
      ..arcToPoint(const Offset(68.5, 10.6), radius: r, clockwise: true), arc(HC.wn));
    canvas.drawPath(Path()
      ..moveTo(70, 11.4)
      ..arcToPoint(const Offset(90, 46), radius: r, clockwise: true), arc(HC.bd));
    final e = const Cubic(0.2, 0.9, 0.3, 1.2).transform(a.value);
    final ang = -90 + 108 * e;
    canvas.save();
    canvas.translate(50, 46);
    canvas.rotate(rad(ang));
    canvas.drawLine(
      Offset.zero,
      const Offset(0, -30),
      Paint()
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..color = HC.tx,
    );
    canvas.restore();
    canvas.drawCircle(const Offset(50, 46), 5, Paint()..color = HC.tx);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _GaugeViz oldDelegate) => false;
}

/// ستوونەکانی HRV
class _HrvViz extends CustomPainter {
  _HrvViz(this.a) : super(repaint: a);
  final Animation<double> a;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    _fit(canvas, size, 120, 50);
    final p = Paint()..color = HC.c2;
    for (int i = 0; i < 12; i++) {
      final h = 14.0 + ((i * 37) % 30);
      final tt = (a.value * 2.8 + i * 0.13) % 2.8;
      final ph = tt < 1.4 ? tt / 1.4 : (2.8 - tt) / 1.4;
      final s = 0.35 + 0.65 * Curves.easeInOut.transform(clampD(ph, 0, 1));
      final hh = h * s;
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(4.0 + i * 10, 48 - hh, 5, hh), const Radius.circular(2.5)),
        p,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _HrvViz oldDelegate) => false;
}

/// خولەکی چالاک
class _ActiveViz extends CustomPainter {
  const _ActiveViz();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    _fit(canvas, size, 120, 50);
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(4, 20, 112, 10), const Radius.circular(5)),
      Paint()..color = vk(0x14FFFFFF),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(4, 20, 4, 10), const Radius.circular(2)),
      Paint()..color = HC.wn,
    );
    final st = ku(10, c: HC.mu);
    paintText(canvas, '30 min', const Offset(116, 46), st, align: TextAlign.right);
    paintText(canvas, '0', const Offset(4, 46), st);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _ActiveViz oldDelegate) => false;
}
