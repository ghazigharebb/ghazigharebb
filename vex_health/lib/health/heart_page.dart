// VEX Health — پەڕەی لێدانی دڵ
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../core/icons.dart';
import '../core/theme.dart';
import 'detail_common.dart';
import 'hc.dart';

class _HP {
  const _HP(this.l, this.t, this.lo, this.avg, this.hi);
  final String l;
  final String t;
  final int lo;
  final int avg;
  final int hi;
}

class _HMode {
  const _HMode(this.lab, this.p);
  final String lab;
  final List<_HP?> p;
}

List<_HMode> _heartData() {
  final mn = monthName();
  return [
    _HMode(todayLabel(), const [
      _HP('06:00', '06:00am - 07:00am', 50, 58, 64),
      _HP('07:00', '07:00am - 08:00am', 58, 66, 76),
      _HP('08:00', '08:00am - 09:00am', 62, 74, 81),
      _HP('09:00', '09:00am - 10:00am', 60, 70, 78),
      _HP('10:00', '10:00am - 10:45am', 64, 70, 72),
      _HP('10:45', '10:45am - 11:00am', 64, 67, 70),
    ]),
    const _HMode('ئەم هەفتەیە', [
      _HP('شەممە', 'شەممە', 52, 66, 92),
      _HP('یەکشەممە', 'یەکشەممە', 49, 64, 88),
      _HP('ئەمڕۆ', 'ئەمڕۆ', 50, 68, 81),
      null,
      null,
      null,
      null,
    ]),
    _HMode(monthLabel(), [
      _HP('1', '1ی $mn', 51, 65, 90),
      _HP('2', '2ی $mn', 48, 63, 95),
      _HP('3', '3ی $mn', 52, 66, 92),
      _HP('4', '4ی $mn', 49, 64, 88),
      _HP('5', '5ی $mn', 50, 68, 81),
      for (int i = 0; i < 26; i++) null,
    ]),
  ];
}

class HeartPage extends StatefulWidget {
  const HeartPage({super.key});

  @override
  State<HeartPage> createState() => _HeartPageState();
}

class _HeartPageState extends State<HeartPage> with TickerProviderStateMixin {
  late final List<_HMode> data = _heartData();
  late final AnimationController beat =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat();
  late final AnimationController draw =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1300));
  late final Animation<double> beatScale = TweenSequence<double>([
    TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 1.22), weight: 12),
    TweenSequenceItem(tween: Tween<double>(begin: 1.22, end: 1.0), weight: 14),
    TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 1.12), weight: 12),
    TweenSequenceItem(tween: Tween<double>(begin: 1.12, end: 1.0), weight: 14),
    TweenSequenceItem(tween: ConstantTween<double>(1.0), weight: 48),
  ]).animate(beat);

  int mode = 0;
  int sel = 0;
  bool open = false;

  @override
  void initState() {
    super.initState();
    _render();
  }

  @override
  void dispose() {
    beat.dispose();
    draw.dispose();
    super.dispose();
  }

  _HMode get cur => data[mode];

  void _render() {
    int last = 0;
    for (int i = 0; i < cur.p.length; i++) {
      if (cur.p[i] != null) last = i;
    }
    sel = last;
    _setBeat();
    draw.forward(from: 0);
  }

  void _setBeat() {
    final p = cur.p[sel];
    if (p == null) return;
    beat.duration = Duration(milliseconds: (60000 / p.avg).round());
    beat.repeat();
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
      _setBeat();
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = cur.p[sel]!;
    final bpm = p.avg;
    final list = cur.p.whereType<_HP>().toList();
    int mn = 999, mx = 0, tot = 0;
    for (final q in list) {
      mn = math.min(mn, q.lo);
      mx = math.max(mx, q.hi);
      tot += q.avg;
    }
    final avg = (tot / list.length).round();
    final chip = bpm < 60 ? 'هێواش' : (bpm > 100 ? 'بەرز' : 'ئاسایی');
    final frac = clampD((bpm - 40) / 100, 0.02, 0.98);

    return DetailScaffold(
      children: [
        DetailHeader(title: 'لێدانی دڵ', mode: mode, onMode: _setMode),
        DateRow(cur.lab),
        // ---- ژمارەی گەورە ----
        Padding(
          padding: const EdgeInsets.only(top: 14),
          child: Column(
            children: [
              SizedBox(
                height: 22,
                child: Text(p.t, textDirection: TextDirection.ltr, style: ku(14, c: HC.mu)),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  ScaleTransition(
                    scale: beatScale,
                    child: Container(
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: Color(0x55FF5C7A), blurRadius: 18)],
                      ),
                      child: svgIcon(HI.heartFill, HX.hr, size: 46, fill: true),
                    ),
                  ),
                  const SizedBox(width: 14),
                  ShaderMask(
                    blendMode: BlendMode.srcIn,
                    shaderCallback: (r) => const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.white, HC.hr2],
                    ).createShader(r),
                    child: Text('$bpm',
                        textDirection: TextDirection.ltr, style: nu(84, c: Colors.white, h: 1.0, ls: -2)),
                  ),
                  const SizedBox(width: 14),
                  Padding(
                    padding: const EdgeInsets.only(top: 40),
                    child: Text('BPM', style: ku(15, w: FontWeight.w600, c: HC.mu)),
                  ),
                ],
              ),
            ],
          ),
        ),
        // ---- ECG ----
        Padding(
          padding: const EdgeInsets.only(top: 10),
          child: LayoutBuilder(
            builder: (context, cons) => SizedBox(
              height: 60,
              child: OverflowBox(
                minWidth: cons.maxWidth + 36,
                maxWidth: cons.maxWidth + 36,
                child: ShaderMask(
                  blendMode: BlendMode.dstIn,
                  shaderCallback: (r) => const LinearGradient(
                    colors: [Color(0x00000000), Color(0xFF000000), Color(0xFF000000), Color(0x00000000)],
                    stops: [0.0, 0.18, 0.82, 1.0],
                  ).createShader(r),
                  child: SizedBox(
                    width: cons.maxWidth + 36,
                    height: 60,
                    child: CustomPaint(painter: _EcgStrip(beat)),
                  ),
                ),
              ),
            ),
          ),
        ),
        // ---- ناوچە ----
        Padding(
          padding: const EdgeInsets.only(top: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(child: Text('ناوچەی لێدانی دڵ', style: ku(13, c: HC.mu))),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: HC.card,
                      borderRadius: BorderRadius.circular(99),
                      border: Border.all(color: HC.line),
                    ),
                    child: Text(chip, style: ku(12, w: FontWeight.w600, c: HC.c2)),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 18,
                child: Directionality(
                  textDirection: TextDirection.ltr,
                  child: Stack(
                    children: [
                      Positioned(
                        left: 0,
                        right: 0,
                        top: 4,
                        height: 10,
                        child: Opacity(
                          opacity: 0.9,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(99),
                              gradient: const LinearGradient(
                                colors: [Color(0xFF3A7BD5), Color(0xFF3A7BD5), HC.c, HC.c2, HC.hr, HC.hr2],
                                stops: [0.0, 0.2, 0.2, 0.6, 0.6, 1.0],
                              ),
                            ),
                          ),
                        ),
                      ),
                      Positioned.fill(
                        child: AnimatedAlign(
                          duration: const Duration(milliseconds: 600),
                          curve: const Cubic(0.2, 0.9, 0.2, 1.0),
                          alignment: Alignment(-1 + 2 * frac, 0),
                          child: Container(
                            width: 18,
                            height: 18,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              border: Border.all(color: HC.bg, width: 3),
                              boxShadow: const [
                                BoxShadow(color: HC.c2, spreadRadius: 2),
                                BoxShadow(color: Color(0x66000000), blurRadius: 10, offset: Offset(0, 2)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 6),
              XLabels(const ['40', '60', '100', '140'], padLeft: 0, padRight: 0, top: 0),
            ],
          ),
        ),
        // ---- هێڵکاری ----
        HCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ChartHead(
                'مەودا و ناوەندی لێدان',
                '${p.l} — ${p.lo}–${p.hi} BPM',
                tipColor: HC.hr2,
                tipBg: const Color(0x1FFF5C7A),
              ),
              AspectRatio(
                aspectRatio: 360 / 190,
                child: LayoutBuilder(
                  builder: (context, cons) => GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTapUp: (d) {
                      final k = cons.maxWidth / 360;
                      final sl = (360 - 34 - 10) / cur.p.length;
                      _select(((d.localPosition.dx / k - 34) / sl).floor());
                    },
                    child: AnimatedBuilder(
                      animation: draw,
                      builder: (context, _) => CustomPaint(
                        size: Size(cons.maxWidth, cons.maxHeight),
                        painter: _HeartChart(cur.p, sel, avg, draw.value),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        StatRow([
          StatItem('$mn', 'کەمترین', const Color(0xFF3A7BD5)),
          StatItem('$mx', 'زۆرترین', HC.hr),
          StatItem('$avg', 'ناوەند', HC.c),
        ]),
        // ---- هەموو زانیارییەکان ----
        Padding(
          padding: const EdgeInsets.only(top: 14),
          child: Press(
            onTap: () => setState(() => open = !open),
            scale: 0.98,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              decoration: BoxDecoration(
                color: HC.card,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: HC.line),
              ),
              child: Row(
                children: [
                  Expanded(child: Text('هەموو زانیارییەکان پیشان بدە', style: ku(15, w: FontWeight.w600, c: HC.tx))),
                  AnimatedRotation(
                    turns: open ? -0.25 : 0,
                    duration: const Duration(milliseconds: 300),
                    child: svgIcon(HI.chev, HX.tx, size: 20, stroke: 2.4),
                  ),
                ],
              ),
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 450),
          curve: Curves.easeOut,
          alignment: Alignment.topCenter,
          child: open
              ? Container(
                  margin: const EdgeInsets.only(top: 14),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: HC.card,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: HC.line),
                  ),
                  child: Column(
                    children: [
                      for (int i = 0; i < list.length; i++)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
                          decoration: BoxDecoration(
                            border: i < list.length - 1 ? const Border(bottom: BorderSide(color: HC.line)) : null,
                          ),
                          child: Row(
                            children: [
                              Text(list[i].l, style: ku(14, c: HC.tx)),
                              const SizedBox(width: 8),
                              Text('${list[i].avg}', style: nu(16, c: HC.hr2)),
                              const Spacer(),
                              Text('${list[i].lo} – ${list[i].hi} BPM',
                                  textDirection: TextDirection.ltr, style: ku(13, c: HC.mu)),
                            ],
                          ),
                        ),
                    ],
                  ),
                )
              : const SizedBox(width: double.infinity),
        ),
        const SourcesNote(),
      ],
    );
  }
}

/// هێڵی ECG ی جووڵاو
class _EcgStrip extends CustomPainter {
  _EcgStrip(this.a) : super(repaint: a);
  final Animation<double> a;

  static const List<List<double>> _q = [
    [22, 30], [28, 24], [34, 30], [44, 30], [48, 38], [54, 4], [60, 52], [66, 30], [90, 30],
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final shift = -90 * a.value;
    final path = Path()..moveTo(shift, 30);
    final n = (size.width / 90).ceil() + 2;
    for (int i = 0; i < n; i++) {
      final x = shift + i * 90.0;
      for (final q in _q) {
        path.lineTo(x + q[0], q[1]);
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeJoin = StrokeJoin.round
        ..color = const Color(0x66FF5C7A)
        ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 5),
    );
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round
        ..color = HC.hr,
    );
  }

  @override
  bool shouldRepaint(covariant _EcgStrip oldDelegate) => false;
}

/// هێڵکاری مەودا و ناوەندی لێدان
class _HeartChart extends CustomPainter {
  _HeartChart(this.p, this.sel, this.avg, this.t);
  final List<_HP?> p;
  final int sel;
  final int avg;
  final double t;

  static final TextStyle _lab = ku(10, c: HC.mu);

  @override
  void paint(Canvas canvas, Size size) {
    final k = size.width / 360;
    canvas.save();
    canvas.scale(k);
    const w = 360.0, h = 190.0, l = 34.0, r = 10.0, tp = 10.0, b = 8.0;
    const pw = w - l - r, ph = h - tp - b;
    final n = p.length;
    final sl = pw / n;
    final cw = math.min(14.0, sl * 0.55);
    double x(int i) => l + (i + 0.5) * sl;
    double y(num v) => tp + (100 - v) / 60 * ph;

    final gl = Paint()
      ..color = HC.line
      ..strokeWidth = 1;
    for (final v in const [40, 60, 80, 100]) {
      canvas.drawLine(Offset(l, y(v)), Offset(w - r, y(v)), gl);
      paintText(canvas, '$v', Offset(l - 6, y(v) + 3), _lab, align: TextAlign.right);
    }

    final pts = <Offset>[];
    for (int i = 0; i < n; i++) {
      final q = p[i];
      if (q == null) continue;
      pts.add(Offset(x(i), y(q.avg)));
      final rect = Rect.fromLTRB(x(i) - cw / 2, y(q.hi), x(i) + cw / 2, y(q.lo));
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, Radius.circular(cw / 2)),
        Paint()
          ..shader = ui.Gradient.linear(
            rect.topCenter,
            rect.bottomCenter,
            [op(HC.hr, i == sel ? 1 : 0.4), op(HC.hr, i == sel ? 0.25 : 0.1)],
          ),
      );
    }

    dashLine(
      canvas,
      Offset(l, y(avg)),
      Offset(w - r, y(avg)),
      Paint()
        ..color = op(HC.c2, 0.7)
        ..strokeWidth = 1.2,
    );

    if (pts.length > 1) {
      final full = smoothPath(pts, 6);
      final part = partialPath(full, ChartAnim(t).line(1.3));
      final shader = ui.Gradient.linear(Offset(pts.first.dx, 0), Offset(pts.last.dx, 0), const [HC.hr2, HC.hr]);
      canvas.drawPath(
        part,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5
          ..strokeCap = StrokeCap.round
          ..color = const Color(0x55FF5C7A)
          ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 5),
      );
      canvas.drawPath(
        part,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..shader = shader,
      );
    }

    for (int i = 0; i < n; i++) {
      final q = p[i];
      if (q == null) continue;
      final c = Offset(x(i), y(q.avg));
      final s = i == sel;
      canvas.drawCircle(c, s ? 6 : 3.5, Paint()..color = s ? Colors.white : HC.bg);
      canvas.drawCircle(
        c,
        s ? 6 : 3.5,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = s ? 4 : 2
          ..color = HC.hr,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _HeartChart oldDelegate) => true;
}
