// VEX Health — پەڕەی سترێس
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../core/icons.dart';
import '../core/theme.dart';
import 'detail_common.dart';
import 'hc.dart';

class _TP {
  const _TP(this.l, this.t, this.v);
  final String l;
  final String t;
  final int v;
}

class _TMode {
  const _TMode(this.lab, this.xl, this.p);
  final String lab;
  final List<String> xl;
  final List<_TP?> p;
}

class _Zone {
  const _Zone(this.n, this.r, this.a, this.b, this.c, this.t);
  final String n;
  final String r;
  final double a;
  final double b;
  final Color c;
  final String t;
}

List<_Zone> get _z => vexCache<List<_Zone>>('stress_page.dart:_z', () => [
  _Zone('ئارام', '< 25', 0, 25, vk(0xFF03EAFB), 'ئاستت زۆر باشە، بەم شێوەیە بەردەوام بە.'),
  _Zone('مامناوەند', '25 – 50', 25, 50, vk(0xFF5BE3A4), 'ئاساییە؛ پشوویەکی کورت بۆ هەناسە و ئاو باشە.'),
  _Zone('سترێس', '51 – 75', 50, 75, vk(0xFFFFB84D), 'چەند خولەکێک هەناسەی قووڵ هەڵبکێشە و لە شاشە دوور بکەوە.'),
  _Zone('سەخت', '> 75', 75, 100, vk(0xFFFF5C7A), 'پشوو بدە، و ئەگەر بەردەوام بوو لەگەڵ پزیشک بدوێ.'),
]);

int _zi(num v) => v < 25 ? 0 : (v <= 50 ? 1 : (v <= 75 ? 2 : 3));

List<_TMode> _stressData() {
  const raw = [34, 31, 28, 30, 36, 42, 48, 52, 45, 40, 44, 50, 58, 63, 66, 61, 57, 62, 64, 60];
  final day = <_TP?>[];
  for (int i = 0; i < raw.length; i++) {
    final m = 360 + i * 15;
    final l = '${pad2(m ~/ 60)}:${pad2(m % 60)}';
    day.add(i == 19 ? _TP('10:59', '10:59am', raw[i]) : _TP(l, '${l}am', raw[i]));
  }
  final mn = monthName();
  return [
    _TMode(todayLabel(), const ['06:00', '07:30', '09:00', '10:30'], day),
    const _TMode('ئەم هەفتەیە', ['شەم', 'یەک', 'دوو', 'سێ', 'چوار', 'پێنج', 'هەینی'], [
      _TP('شەممە', 'شەممە', 42),
      _TP('یەکشەممە', 'یەکشەممە', 55),
      _TP('ئەمڕۆ', 'ئەمڕۆ', 60),
      null,
      null,
      null,
      null,
    ]),
    _TMode(monthLabel(), const ['1', '10', '20', '31'], [
      _TP('1', '1ی $mn', 38),
      _TP('2', '2ی $mn', 47),
      _TP('3', '3ی $mn', 44),
      _TP('4', '4ی $mn', 55),
      _TP('5', '5ی $mn', 60),
      for (int i = 0; i < 26; i++) null,
    ]),
  ];
}

class StressPage extends StatefulWidget {
  const StressPage({super.key});

  @override
  State<StressPage> createState() => _StressPageState();
}

class _StressPageState extends State<StressPage> with TickerProviderStateMixin {
  late final List<_TMode> data = _stressData();
  late final AnimationController valC =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
  late final AnimationController draw =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1600));

  int mode = 0;
  int sel = 0;
  double _from = 0;
  double _to = 0;

  double get val => _from + (_to - _from) * Curves.easeOutCubic.transform(valC.value);

  @override
  void initState() {
    super.initState();
    _render();
  }

  @override
  void dispose() {
    valC.dispose();
    draw.dispose();
    super.dispose();
  }

  _TMode get cur => data[mode];

  void _render() {
    int last = 0;
    for (int i = 0; i < cur.p.length; i++) {
      if (cur.p[i] != null) last = i;
    }
    sel = last;
    draw.forward(from: 0);
    _hero();
  }

  void _hero() {
    _from = val;
    _to = cur.p[sel]!.v.toDouble();
    valC.forward(from: 0);
  }

  void _setMode(int m) {
    if (m == mode) return;
    setState(() {
      mode = m;
      _render();
    });
  }

  void _select(int i) {
    if (i < 0 || i >= cur.p.length || cur.p[i] == null) return;
    setState(() {
      sel = i;
      _hero();
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = cur.p[sel]!;
    final z = _z[_zi(p.v)];
    final list = cur.p.whereType<_TP>().toList();
    int mn = 999, mx = 0, tot = 0;
    for (final q in list) {
      mn = math.min(mn, q.v);
      mx = math.max(mx, q.v);
      tot += q.v;
    }
    final av = (tot / list.length).round();

    return DetailScaffold(
      children: [
        DetailHeader(title: 'سترێس', mode: mode, onMode: _setMode),
        DateRow(cur.lab),
        // ---- پێوەر ----
        Center(
          child: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 310),
              child: AspectRatio(
                aspectRatio: 280 / 150,
                child: AnimatedBuilder(
                  animation: valC,
                  builder: (context, _) {
                    final cv = val;
                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Positioned.fill(child: CustomPaint(painter: _Gauge(cv))),
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 2,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              VText(p.t, textDirection: TextDirection.ltr, style: ku(13, c: HC.mu)),
                              VText('${cv.round()}',
                                  textDirection: TextDirection.ltr, style: nu(68, c: z.c, h: 1.0, ls: -2)),
                              const SizedBox(height: 8),
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 5),
                                decoration: BoxDecoration(
                                  color: HC.card,
                                  borderRadius: BorderRadius.circular(99),
                                  border: Border.all(color: z.c),
                                  boxShadow: [BoxShadow(color: op(z.c, 0.6), blurRadius: 18, spreadRadius: -4)],
                                ),
                                child: VText(z.n, style: ku(14, w: FontWeight.w600, c: z.c)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
        // ---- ئامۆژگاری ----
        Container(
          margin: const EdgeInsets.only(top: 18),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: HC.card,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: HC.line),
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: vk(0x1A03EAFB), borderRadius: BorderRadius.circular(12)),
                child: svgIcon(HI.bulb, HX.c2, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(child: VText(z.t, style: ku(14, c: HC.tx, h: 1.7))),
            ],
          ),
        ),
        // ---- هێڵکاری ----
        HCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ChartHead('ئاستی سترێس بەپێی کات', '${p.l} — ${p.v}'),
              AspectRatio(
                aspectRatio: 360 / 170,
                child: LayoutBuilder(
                  builder: (context, cons) => GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTapUp: (d) {
                      final k = cons.maxWidth / 360;
                      final sl = (360 - 30 - 10) / cur.p.length;
                      _select(((d.localPosition.dx / k - 30) / sl).floor());
                    },
                    child: AnimatedBuilder(
                      animation: draw,
                      builder: (context, _) => CustomPaint(
                        size: Size(cons.maxWidth, cons.maxHeight),
                        painter: _StressChart(cur.p, sel, draw.value),
                      ),
                    ),
                  ),
                ),
              ),
              XLabels(cur.xl),
            ],
          ),
        ),
        StatRow([
          StatItem('$mn', 'کەمترین', _z[_zi(mn)].c),
          StatItem('$mx', 'زۆرترین', _z[_zi(mx)].c),
          StatItem('$av', 'ناوەند', _z[_zi(av)].c),
        ]),
        ZoneList([for (final x in _z) ZoneItem(x.n, x.r, x.c)], _zi(p.v)),
        const SourcesNote(sources: false),
      ],
    );
  }
}

/// پێوەری نیوە بازنە
class _Gauge extends CustomPainter {
  _Gauge(this.v);
  final double v;

  static const double cx = 140, cy = 132, r = 108, gp = 1.4;
  static TextStyle get _lab => ku(11, c: HC.mu);

  Offset _pt(double val, double rad0) {
    final a = math.pi - val / 100 * math.pi;
    return Offset(cx + rad0 * math.cos(a), cy - rad0 * math.sin(a));
  }

  @override
  void paint(Canvas canvas, Size size) {
    final k = size.width / 280;
    canvas.save();
    canvas.scale(k);
    final rect = Rect.fromCircle(center: const Offset(cx, cy), radius: r);
    for (final z in _z) {
      final a = z.a + gp, b = z.b - gp;
      final start = a / 100 * math.pi - math.pi;
      final full = (b - a) / 100 * math.pi;
      canvas.drawArc(
        rect,
        start,
        full,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 16
          ..color = op(z.c, 0.16),
      );
      final f = clampD(v - a, 0, b - a) / 100 * math.pi;
      if (f > 0.0005) {
        canvas.drawArc(
          rect,
          start,
          f,
          false,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 16
            ..color = op(z.c, 0.55)
            ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 3),
        );
        canvas.drawArc(
          rect,
          start,
          f,
          false,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 16
            ..color = z.c,
        );
      }
    }
    final kn = _pt(clampD(v, 0, 100), r);
    canvas.drawCircle(
      kn + const Offset(0, 2),
      12,
      Paint()
        ..color = vk(0x80000000)
        ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 4),
    );
    canvas.drawCircle(kn, 11, Paint()..color = kW);
    canvas.drawCircle(
      kn,
      11,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..color = HC.bg,
    );
    for (final lv in const [0.0, 50.0, 100.0]) {
      final q = _pt(lv, r - 26);
      paintText(canvas, '${lv.round()}', Offset(q.dx, q.dy + 4), _lab, align: TextAlign.center);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _Gauge oldDelegate) => oldDelegate.v != v;
}

/// هێڵکاری سترێس
class _StressChart extends CustomPainter {
  _StressChart(this.p, this.sel, this.t);
  final List<_TP?> p;
  final int sel;
  final double t;

  static TextStyle get _lab => ku(10, c: HC.mu);

  @override
  void paint(Canvas canvas, Size size) {
    final k = size.width / 360;
    canvas.save();
    canvas.scale(k);
    const w = 360.0, h = 170.0, l = 30.0, r = 10.0, tp = 8.0, b = 6.0;
    const pw = w - l - r, ph = h - tp - b;
    final n = p.length;
    final sl = pw / n;
    double x(int i) => l + (i + 0.5) * sl;
    double y(num v) => tp + (100 - v) / 100 * ph;

    for (final z in _z) {
      canvas.drawRect(Rect.fromLTRB(l, y(z.b), l + pw, y(z.a)), Paint()..color = op(z.c, 0.06));
    }
    final gl = Paint()
      ..color = HC.line
      ..strokeWidth = 1;
    for (final v in const [0, 25, 50, 75, 100]) {
      canvas.drawLine(Offset(l, y(v)), Offset(w - r, y(v)), gl);
      paintText(canvas, '$v', Offset(l - 6, y(v) + 3), _lab, align: TextAlign.right);
    }

    final pts = <Offset>[];
    final idx = <int>[];
    for (int i = 0; i < n; i++) {
      final q = p[i];
      if (q == null) continue;
      pts.add(Offset(x(i), y(q.v)));
      idx.add(i);
    }
    final an = ChartAnim(t);
    if (pts.length > 1) {
      final line = smoothPath(pts, 6);
      final area = Path()
        ..addPath(line, Offset.zero)
        ..lineTo(pts.last.dx, y(0))
        ..lineTo(pts.first.dx, y(0))
        ..close();
      final ao = an.area(1.6, delay: 0.7);
      if (ao > 0) {
        canvas.drawPath(
          area,
          Paint()
            ..shader = ui.Gradient.linear(
              Offset(0, tp),
              Offset(0, y(0)),
              [op(HC.wn, 0.35 * ao), op(HC.wn, 0)],
            ),
        );
      }
      canvas.drawPath(
        partialPath(line, an.line(1.6, dur: 1.3)),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..shader = ui.Gradient.linear(
            Offset(pts.first.dx, 0),
            Offset(pts.last.dx, 0),
            [vk(0xFF03EAFB), vk(0xFFFFB84D), vk(0xFFFF8A5C)],
            const [0.0, 0.5, 1.0],
          ),
      );
    }

    final selQ = p[sel];
    if (selQ != null) {
      final sp = Offset(x(sel), y(selQ.v));
      final zc = _z[_zi(selQ.v)].c;
      dashLine(
        canvas,
        Offset(sp.dx, tp),
        Offset(sp.dx, y(0)),
        Paint()
          ..color = op(HC.c2, 0.35)
          ..strokeWidth = 1,
        on: 3,
        off: 4,
      );
      canvas.drawCircle(sp, 13, Paint()..color = op(zc, 0.22));
      canvas.drawCircle(sp, 6, Paint()..color = kW);
      canvas.drawCircle(
        sp,
        6,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.5
          ..color = zc,
      );
    }
    if (pts.length <= 8) {
      for (int j = 0; j < pts.length; j++) {
        if (idx[j] == sel) continue;
        canvas.drawCircle(pts[j], 3.5, Paint()..color = HC.bg);
        canvas.drawCircle(
          pts[j],
          3.5,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2
            ..color = HC.wn,
        );
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _StressChart oldDelegate) => true;
}
