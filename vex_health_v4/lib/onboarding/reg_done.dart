// VEX Health — کۆتایی تۆمارکردن: بازنە دەکێشرێت، ✓ دەردەکەوێت،
// پاشان کونێکی بازنەیی لە ناوەڕاستەوە گەورە دەبێت و ئەپەکە لە ژێرەوە دەردەکەوێت.
//
// تەنها یەک CustomPaint ـی سووک دەجووڵێت؛ ئەپەکە لە ژێرەوە هیچ جووڵەیەکی نییە (بێ لاگ).
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../core/theme.dart';
import 'reg_widgets.dart';

class RDone extends StatefulWidget {
  const RDone({super.key, required this.title, required this.sub, required this.onFinished});
  final String title;
  final String sub;
  final VoidCallback onFinished;

  @override
  State<RDone> createState() => _RDoneState();
}

class _RDoneState extends State<RDone> with SingleTickerProviderStateMixin {
  static const int _intro = 1900, _hold = 260, _dur = 1050;
  static const int _total = _intro + _hold + _dur;

  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: _total));
  final GlobalKey _orb = GlobalKey();
  final GlobalKey _box = GlobalKey();
  Offset? _center;
  double _r0 = 57;
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    buzz(2);
    _c.addStatusListener((s) {
      if (s == AnimationStatus.completed) _finish();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_c.isAnimating && !_finished && _c.value == 0) {
      if (MediaQuery.of(context).disableAnimations) {
        // جووڵەی کەم: ڕاستەوخۆ دەچێتە ناو ئەپەکە
        Future<void>.delayed(const Duration(milliseconds: 1200), _finish);
      } else {
        _c.forward();
      }
    }
  }

  void _finish() {
    if (_finished) return;
    _finished = true;
    widget.onFinished();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  /// شوێنی ناوەڕاستی بازنەکە بەرامبەر بە ئەم پەڕەیە
  void _measure(Size size) {
    if (_center != null) return;
    final ob = _orb.currentContext?.findRenderObject();
    final bb = _box.currentContext?.findRenderObject();
    if (ob is RenderBox && bb is RenderBox && ob.hasSize && ob.attached && bb.attached) {
      final p = ob.localToGlobal(ob.size.center(Offset.zero), ancestor: bb);
      _center = p;
      _r0 = ob.size.width * 52 / 120;
    } else {
      _center = Offset(size.width / 2, size.height * 0.45);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      key: _box,
      builder: (context, cons) {
        final size = Size(cons.maxWidth, cons.maxHeight);
        return AnimatedBuilder(
          animation: _c,
          builder: (context, _) {
            final ms = _c.value * _total;
            if (ms < _intro) return _content(ms);
            _measure(size);
            final c = _center ?? Offset(size.width / 2, size.height * 0.45);
            final maxR = math.sqrt(math.pow(math.max(c.dx, size.width - c.dx), 2) +
                    math.pow(math.max(c.dy, size.height - c.dy), 2)) +
                24;
            final el = ms - _intro;
            double hole, rr, a;
            if (el < _hold) {
              final k = el / _hold;
              hole = _r0 * (1 - math.pow(1 - k, 2));
              rr = _r0;
              a = 1;
            } else {
              final p = ((el - _hold) / _dur).clamp(0.0, 1.0);
              final e = p < 0.5 ? 4 * p * p * p : 1 - math.pow(-2 * p + 2, 3) / 2;
              hole = _r0 + e * (maxR - _r0);
              rr = hole;
              a = p < 0.7 ? 1.0 : math.max(0.0, 1 - (p - 0.7) / 0.3);
            }
            return IgnorePointer(
              child: CustomPaint(
                size: size,
                painter: _RevealPainter(center: c, hole: hole, ring: rr, alpha: a),
              ),
            );
          },
        );
      },
    );
  }

  Widget _content(double ms) {
    double ph(double start, double dur) => ((ms - start) / dur).clamp(0.0, 1.0);
    final ring = Curves.easeInOutCubic.transform(ph(0, 800));
    final check = Curves.easeOutCubic.transform(ph(700, 450));
    final t1 = Curves.easeOutCubic.transform(ph(900, 500));
    final t2 = Curves.easeOutCubic.transform(ph(1050, 500));
    return Container(
      color: RC.bg,
      child: DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0, -0.1),
          radius: 0.8,
          colors: [vk(0x292FE6F3), vk(0x002FE6F3)],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              key: _orb,
              width: 132,
              height: 132,
              child: CustomPaint(painter: _OrbPainter(ring: ring, check: check, t: ms / 1000)),
            ),
            const SizedBox(height: 18),
            Opacity(
              opacity: t1,
              child: Transform.translate(
                offset: Offset(0, 10 * (1 - t1)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: VText(widget.title, textAlign: TextAlign.center, style: ku(25, w: FontWeight.w800, h: 1.45)),
                ),
              ),
            ),
            const SizedBox(height: 2),
            Opacity(
              opacity: t2,
              child: Transform.translate(
                offset: Offset(0, 10 * (1 - t2)),
                child: VText(widget.sub, textAlign: TextAlign.center, style: ku(14, c: RC.p)),
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}

class _OrbPainter extends CustomPainter {
  _OrbPainter({required this.ring, required this.check, required this.t});
  final double ring;
  final double check;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 120;
    final c = size.center(Offset.zero);

    // ڕووناکی ناوەوە (لێدان)
    final pulse = 0.5 + 0.5 * math.sin(t * math.pi);
    canvas.drawCircle(
      c,
      46 * s * (0.92 + 0.08 * pulse),
      Paint()
        ..shader = ui.Gradient.radial(c, 46 * s, [
          vkRGBO(60, 240, 138, 0.28 * (0.55 + 0.45 * pulse)),
          vk(0x003CF08A),
        ]),
    );

    // سێ خاڵی خولاوە
    final rot = t / 3.2 * math.pi * 2;
    final sr = 60 * s + 18;
    void sat(double ang, double r, Color col) {
      final p = c + Offset(math.cos(ang + rot), math.sin(ang + rot)) * sr;
      canvas.drawCircle(p, r + 3, Paint()..color = op(col, 0.35)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5));
      canvas.drawCircle(p, r, Paint()..color = col);
    }

    sat(-math.pi / 2, 4.5, vk(0xFF8FF3F9));
    sat(math.pi * 0.78, 3.5, V.mint);
    sat(math.pi * 0.22, 3, RC.lilac);

    // بازنەی پشتەوە
    final rect = Rect.fromCircle(center: c, radius: 52 * s);
    canvas.drawCircle(
      c,
      52 * s,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..color = vk(0x12FFFFFF),
    );
    if (ring > 0) {
      final grad = ui.Gradient.linear(rect.topLeft, rect.bottomRight, [vk(0xFF8FF3F9), vk(0xFF3CF08A)]);
      canvas.drawArc(
        rect,
        -math.pi / 2,
        math.pi * 2 * ring,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 9
          ..strokeCap = StrokeCap.round
          ..color = vk(0x553CF08A)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );
      canvas.drawArc(
        rect,
        -math.pi / 2,
        math.pi * 2 * ring,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5
          ..strokeCap = StrokeCap.round
          ..shader = grad,
      );
    }

    // ✓
    if (check > 0) {
      final path = Path()
        ..moveTo(40 * s, 61 * s)
        ..lineTo(53 * s, 74 * s)
        ..lineTo(80 * s, 46 * s);
      final p = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = V.mint;
      final out = Path();
      for (final m in path.computeMetrics()) {
        out.addPath(m.extractPath(0, m.length * check), Offset.zero);
      }
      canvas.drawPath(out, p);
    }
  }

  @override
  bool shouldRepaint(_OrbPainter o) => o.ring != ring || o.check != check || o.t != t;
}

class _RevealPainter extends CustomPainter {
  _RevealPainter({required this.center, required this.hole, required this.ring, required this.alpha});
  final Offset center;
  final double hole;
  final double ring;
  final double alpha;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Offset.zero & size);
    if (hole > 0) path.addOval(Rect.fromCircle(center: center, radius: hole));
    canvas.drawPath(path, Paint()..color = RC.bg);
    final gr = math.max(size.width, size.height) * 0.6;
    canvas.drawPath(
      path,
      Paint()
        ..shader = ui.Gradient.radial(center, gr, [vk(0x212FE6F3), vk(0x002FE6F3)]),
    );
    if (alpha > 0) {
      canvas.drawCircle(
        center,
        ring + 10,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 18
          ..color = vkRGBO(47, 230, 243, 0.2 * alpha),
      );
      canvas.drawCircle(
        center,
        ring + 1.6,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.2
          ..color = vkRGBO(143, 243, 249, alpha),
      );
    }
  }

  @override
  bool shouldRepaint(_RevealPainter o) =>
      o.center != center || o.hole != hole || o.ring != ring || o.alpha != alpha;
}
