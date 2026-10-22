// VEX Health — پەڕەی ئۆکسجینی خوێن (SpO₂)
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../core/theme.dart';
import 'detail_common.dart';
import 'hc.dart';

class _SP {
  const _SP(this.l, this.t, this.v);
  final String l;
  final String t;
  final int v;
}

class _SMode {
  const _SMode(this.lab, this.xl, this.p);
  final String lab;
  final List<String> xl;
  final List<_SP?> p;
}

const double _lo = 90, _hi = 100;
Color get _cy => vk(0xFF03EAFB);
Color get _am => vk(0xFFFFB84D);
Color get _rd => vk(0xFFFF5C7A);

/// ڕەنگ بەپێی ئاستی ئۆکسجین
Color _colorAt(double v) {
  if (v >= 95) return _cy;
  if (v >= 94) return mix(_am, _cy, v - 94);
  if (v >= 91) return _am;
  if (v >= 90) return mix(_rd, _am, v - 90);
  return _rd;
}

int _zi(double v) => v >= 95 ? 0 : (v >= 91 ? 1 : 2);

List<ZoneItem> get _zones => vexCache<List<ZoneItem>>('spo2_page.dart:_zones', () => [
  ZoneItem('ئاسایی', '≥ 95%', _cy),
  ZoneItem('کەمێک نزم', '91 – 94%', _am),
  ZoneItem('نزم', '≤ 90%', _rd),
]);

List<_SMode> _spo2Data() {
  const raw = [92, 98, 100, 100, 100, 100, 100, 100, 100, 100, 98, 100, 100, 100, 100, 100, 100, 99, 100, 100, 100, 98, 97];
  final day = <_SP?>[];
  for (int i = 0; i < raw.length; i++) {
    final m = i * 30;
    final l = '${pad2(m ~/ 60)}:${pad2(m % 60)}';
    day.add(i == 22 ? _SP('11:02', '11:02am', raw[i]) : _SP(l, '${l}am', raw[i]));
  }
  final mn = monthName();
  return [
    _SMode(todayLabel(), const ['00', '03', '06', '09', '11'], day),
    const _SMode('ئەم هەفتەیە', ['شەم', 'یەک', 'دوو', 'سێ', 'چوار', 'پێنج', 'هەینی'], [
      _SP('شەممە', 'شەممە', 98),
      _SP('یەکشەممە', 'یەکشەممە', 97),
      _SP('ئەمڕۆ', 'ئەمڕۆ', 97),
      null,
      null,
      null,
      null,
    ]),
    _SMode(monthLabel(), const ['1', '10', '20', '31'], [
      _SP('1', '1ی $mn', 98),
      _SP('2', '2ی $mn', 97),
      _SP('3', '3ی $mn', 98),
      _SP('4', '4ی $mn', 99),
      _SP('5', '5ی $mn', 97),
      for (int i = 0; i < 26; i++) null,
    ]),
  ];
}

class Spo2Page extends StatefulWidget {
  const Spo2Page({super.key});

  @override
  State<Spo2Page> createState() => _Spo2PageState();
}

class _Spo2PageState extends State<Spo2Page> with TickerProviderStateMixin {
  late final List<_SMode> data = _spo2Data();
  late final AnimationController valC =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1100));
  late final AnimationController breath =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 5000))..repeat();
  late final AnimationController bubbles =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 6000))..repeat();
  late final AnimationController draw =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1700));

  int mode = 0;
  int sel = 0;
  int? ov;
  double _from = _lo;
  double _to = _lo;

  double get val => _from + (_to - _from) * Curves.easeOutCubic.transform(valC.value);

  @override
  void initState() {
    super.initState();
    _render();
  }

  @override
  void dispose() {
    valC.dispose();
    breath.dispose();
    bubbles.dispose();
    draw.dispose();
    super.dispose();
  }

  _SMode get cur => data[mode];

  void _render() {
    ov = null;
    int last = 0;
    for (int i = 0; i < cur.p.length; i++) {
      if (cur.p[i] != null) last = i;
    }
    sel = last;
    draw.forward(from: 0);
    _hero();
  }

  void _hero() {
    final p = cur.p[sel]!;
    final v = (ov ?? p.v).toDouble();
    _from = val;
    _to = v;
    valC.forward(from: 0);
    final bt = v >= 95 ? 5000 : (v >= 91 ? 3600 : 2600);
    if (breath.duration?.inMilliseconds != bt) {
      breath.duration = Duration(milliseconds: bt);
      breath.repeat();
    }
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
      ov = null;
      _hero();
    });
  }

  void _preview(int v) {
    setState(() {
      ov = v;
      _hero();
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = cur.p[sel]!;
    final v = (ov ?? p.v).toDouble();
    final zc = _colorAt(v);
    final z = _zones[_zi(v)];
    final list = cur.p.whereType<_SP>().toList();
    int mn = 999, mx = 0, tot = 0;
    for (final q in list) {
      mn = math.min(mn, q.v);
      mx = math.max(mx, q.v);
      tot += q.v;
    }
    final av = (tot / list.length).round();

    return DetailScaffold(
      children: [
        DetailHeader(title: 'SpO₂', mode: mode, onMode: _setMode),
        DateRow(cur.lab),
        // ---- بازنە ----
        Center(
          child: Padding(
            padding: const EdgeInsets.only(top: 10),
            child: SizedBox(
              width: 262,
              height: 262,
              child: AnimatedBuilder(
                animation: Listenable.merge([valC, breath, bubbles]),
                builder: (context, _) {
                  final cv = val;
                  return Stack(
                    children: [
                      Positioned.fill(
                        child: CustomPaint(
                          painter: _Spo2Hero(
                            value: cv,
                            color: _colorAt(cv),
                            breath: breath.value,
                            bubbles: bubbles.value,
                          ),
                        ),
                      ),
                      Positioned.fill(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              height: 16,
                              child: VText(
                                ov != null ? 'نموونەی دۆخ' : p.t,
                                textDirection: TextDirection.ltr,
                                style: ku(12, c: vk(0xD9D8F7FA)),
                              ),
                            ),
                            Directionality(
                              textDirection: TextDirection.ltr,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  VText('${cv.round()}',
                                      style: nu(62, c: kW, h: 1.05, ls: -2)
                                          .copyWith(shadows: [Shadow(color: vk(0x66000000), blurRadius: 18, offset: Offset(0, 3))])),
                                  Padding(
                                    padding: const EdgeInsets.only(top: 10, left: 2),
                                    child: VText('%', style: ku(22, w: FontWeight.w600, c: vk(0xFFE6FBFD))),
                                  ),
                                ],
                              ),
                            ),
                            VText('ئۆکسجینی خوێن', style: ku(12, c: vk(0xCCD8F7FA))),
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
        // ---- دۆخ ----
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              decoration: BoxDecoration(
                color: HC.card,
                borderRadius: BorderRadius.circular(99),
                border: Border.all(color: zc),
                boxShadow: [BoxShadow(color: op(zc, 0.6), blurRadius: 18, spreadRadius: -4)],
              ),
              child: VText(z.name, style: ku(14, w: FontWeight.w600, c: zc)),
            ),
          ),
        ),
        // ---- هێڵکاری ----
        HCard(
          top: 16,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ChartHead('ئۆکسجین بەپێی کات', '${p.l} — ${p.v}%'),
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
                        painter: _Spo2Chart(cur.p, sel, av, mn, draw.value),
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
          StatItem('$mn', 'کەمترین', _colorAt(mn.toDouble()), unit: '%'),
          StatItem('$mx', 'زۆرترین', _colorAt(mx.toDouble()), unit: '%'),
          StatItem('$av', 'ناوەند', _colorAt(av.toDouble()), unit: '%'),
        ]),
        ZoneList(_zones, _zi(v)),
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 14, 4, 0),
          child: VText(
            'ئەم ژمارانە تەنها بۆ زانیاری گشتین و جێگەی پشکنینی پزیشکی ناگرنەوە. ئەگەر هەستت بە سەخت هەناسەدان یان سەرگێژی کرد، سەردانی پزیشک بکە.',
            style: ku(12, c: HC.mu, h: 1.8),
          ),
        ),
        // ---- نموونەی دۆخەکان ----
        Padding(
          padding: const EdgeInsets.only(top: 20),
          child: Center(
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: HC.card,
                borderRadius: BorderRadius.circular(99),
                border: Border.all(color: HC.line),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final o in const [
                    [97, 'ئاسایی'],
                    [93, 'کەمێک نزم'],
                    [89, 'نزم'],
                  ])
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => _preview(o[0] as int),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        decoration: BoxDecoration(
                          color: ov == o[0] ? vk(0x2603EAFB) : Colors.transparent,
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: VText(o[1] as String, style: ku(12, c: ov == o[0] ? HC.c2 : HC.mu)),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        const SourcesNote(sources: false, demo: 'دیمۆی دیزاین · داتاکان نموونەن'),
      ],
    );
  }
}

/// بازنەی ئۆکسجین (هەناسەدان، بڵقەکان و پێشکەوتن)
class _Spo2Hero extends CustomPainter {
  _Spo2Hero({required this.value, required this.color, required this.breath, required this.bubbles});
  final double value;
  final Color color;
  final double breath;
  final double bubbles;

  static const List<List<double>> _bb = [
    [96, 176], [112, 186], [150, 180], [166, 170], [130, 190], [182, 150], [80, 150],
  ];

  double _wave(double phase) => (1 - math.cos(2 * math.pi * (phase % 1.0))) / 2;

  @override
  void paint(Canvas canvas, Size size) {
    final k = size.width / 262;
    canvas.save();
    canvas.scale(k);
    const c = Offset(131, 131);

    // بنەڕەت + پێشکەوتن
    canvas.drawCircle(
      c,
      100,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..color = vk(0x14FFFFFF),
    );
    final f = clampD((value - _lo) / (_hi - _lo), 0, 1);
    if (f > 0.001) {
      final rect = Rect.fromCircle(center: c, radius: 100);
      canvas.drawArc(
        rect,
        -math.pi / 2,
        math.pi * 2 * f,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 8
          ..strokeCap = StrokeCap.round
          ..color = op(color, 0.6)
          ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 6),
      );
      canvas.drawArc(
        rect,
        -math.pi / 2,
        math.pi * 2 * f,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5
          ..strokeCap = StrokeCap.round
          ..color = color,
      );
    }

    // بازنەکانی هەناسە
    const radii = [92.0, 80.0, 68.0];
    for (int i = 0; i < 3; i++) {
      final w = _wave(breath - i * 0.05);
      canvas.drawCircle(
        c,
        radii[i] * (0.93 + 0.14 * w),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = op(color, 0.12 + 0.58 * w),
      );
    }

    // گۆی ناوەڕاست
    final ow = _wave(breath);
    final orbR = 58 * (0.97 + 0.08 * ow);
    final orbRect = Rect.fromCircle(center: c, radius: orbR);
    canvas.drawCircle(
      c,
      orbR,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0, -0.2),
          radius: 0.62,
          colors: [op(color, 0.65), op(color, 0.1)],
        ).createShader(orbRect),
    );
    canvas.drawCircle(
      c,
      orbR,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = vk(0x38FFFFFF),
    );

    // بڵقەکان
    for (int i = 0; i < _bb.length; i++) {
      final t = ((bubbles * 6 - i * 0.8) % 6.0) / 6.0;
      final e = Curves.easeIn.transform(t);
      final o = t < 0.15 ? 0.55 * t / 0.15 : 0.55 * (1 - (t - 0.15) / 0.85);
      canvas.drawCircle(
        Offset(_bb[i][0], _bb[i][1] - 80 * e),
        1.8 + (i % 3) * 0.7,
        Paint()..color = op(kW, o),
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _Spo2Hero oldDelegate) => true;
}

/// هێڵکاری ئۆکسجین
class _Spo2Chart extends CustomPainter {
  _Spo2Chart(this.p, this.sel, this.av, this.mn, this.t);
  final List<_SP?> p;
  final int sel;
  final int av;
  final int mn;
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
    double y(num v) => tp + (_hi - v) / (_hi - _lo) * ph;

    canvas.drawRect(Rect.fromLTRB(l, y(95), l + pw, y(_lo)), Paint()..color = vk(0x12FFB84D));
    final gl = Paint()
      ..color = HC.line
      ..strokeWidth = 1;
    for (final v in const [90, 92, 94, 96, 98, 100]) {
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
    dashLine(
      canvas,
      Offset(l, y(av)),
      Offset(w - r, y(av)),
      Paint()
        ..color = op(HC.c2, 0.7)
        ..strokeWidth = 1.2,
    );
    paintText(canvas, '$av', Offset(w - r, y(av) - 5), _lab, align: TextAlign.right);

    final an = ChartAnim(t);
    if (pts.length > 1) {
      final line = smoothPath(pts, 7);
      canvas.save();
      canvas.clipRect(Rect.fromLTWH(l, tp, pw, ph));
      final area = Path()
        ..addPath(line, Offset.zero)
        ..lineTo(pts.last.dx, y(_lo))
        ..lineTo(pts.first.dx, y(_lo))
        ..close();
      final ao = an.area(1.7);
      if (ao > 0) {
        canvas.drawPath(
          area,
          Paint()
            ..shader = ui.Gradient.linear(
              Offset(0, tp),
              Offset(0, y(_lo)),
              [op(HC.c, 0.3 * ao), op(HC.c, 0)],
            ),
        );
      }
      final part = partialPath(line, an.line(1.7, dur: 1.4));
      canvas.drawPath(
        part,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5
          ..strokeCap = StrokeCap.round
          ..color = op(HC.c, 0.35)
          ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 5),
      );
      canvas.drawPath(
        part,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..shader = ui.Gradient.linear(Offset(pts.first.dx, 0), Offset(pts.last.dx, 0), [HC.c2, HC.c]),
      );
      canvas.restore();
    }

    final selQ = p[sel];
    if (selQ != null) {
      final sp = Offset(x(sel), y(selQ.v));
      final zc = _colorAt(selQ.v.toDouble());
      dashLine(
        canvas,
        Offset(sp.dx, tp),
        Offset(sp.dx, y(_lo)),
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
    if (pts.length > 8) {
      int mi = -1;
      for (int j = 0; j < idx.length; j++) {
        if (p[idx[j]]!.v == mn) {
          mi = idx[j];
          break;
        }
      }
      if (mi >= 0 && mi != sel) {
        final q = Offset(x(mi), y(mn));
        canvas.drawCircle(q, 3.5, Paint()..color = HC.bg);
        canvas.drawCircle(
          q,
          3.5,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2
            ..color = _colorAt(mn.toDouble()),
        );
      }
    } else {
      for (int j = 0; j < pts.length; j++) {
        if (idx[j] == sel) continue;
        canvas.drawCircle(pts[j], 3.5, Paint()..color = HC.bg);
        canvas.drawCircle(
          pts[j],
          3.5,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2
            ..color = HC.c2,
        );
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _Spo2Chart oldDelegate) => true;
}
