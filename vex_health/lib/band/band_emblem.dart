// VEX Health — ئایکۆنی تایبەتی VEX Band (هەمان ئایکۆنی وێب)
//
// بازنەی خولاوە + هەسارەی بچووک + Band ی دەقیق + هێڵی ECG ی کێشراو + خاڵی لێدانی دڵ.
// بەکارهێنان: BandEmblem(size: 84). بۆ ئایکۆنی بچووک (< 40) animate: false بکە.
import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../core/theme.dart';

class BandEmblem extends StatefulWidget {
  const BandEmblem({super.key, this.size = 80, this.animate = true});
  final double size;
  final bool animate;

  @override
  State<BandEmblem> createState() => _BandEmblemState();
}

class _BandEmblemState extends State<BandEmblem> with SingleTickerProviderStateMixin {
  // 4 کاتژمێر = ژمارەی تەواو بۆ هەموو خولەکان، بێ بڕین
  static const double _total = 14400;
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(seconds: 14400));

  @override
  void initState() {
    super.initState();
    if (widget.animate) _c.repeat();
  }

  @override
  void didUpdateWidget(covariant BandEmblem old) {
    super.didUpdateWidget(old);
    if (widget.animate && !_c.isAnimating) {
      _c.repeat();
    } else if (!widget.animate && _c.isAnimating) {
      _c.stop();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: AnimatedBuilder(
          animation: _c,
          builder: (_, __) => CustomPaint(painter: _EmblemPainter(widget.animate ? _c.value * _total : 3.2)),
        ),
      ),
    );
  }
}

class _EmblemPainter extends CustomPainter {
  _EmblemPainter(this.secs);
  final double secs;

  static Color get _cy => vk(0xFF2FE6F3);
  static Color get _mint => vk(0xFF3CF08A);
  static Color get _c1 => vk(0xFF8FF3F9);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 96, size.height / 96);

    final grad = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [_c1, _mint],
    );
    final box = const Rect.fromLTWH(0, 0, 96, 96);

    // درەوشانەوە
    canvas.drawCircle(
      const Offset(48, 48),
      47,
      Paint()
        ..shader = RadialGradient(colors: [vk(0x612FE6F3), vk(0x002FE6F3)]).createShader(
          Rect.fromCircle(center: const Offset(48, 48), radius: 47),
        ),
    );

    // بازنەی خولاوە (خاڵخاڵ)
    final orbit = secs / 16 * 2 * math.pi;
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round
      ..shader = grad.createShader(box)
      ..color = vk(0xFFFFFFFF).withAlpha(178);
    const dashes = [30.0, 10.0, 5.0, 10.0];
    var a = orbit;
    var i = 0;
    const r = 43.0;
    final rect = Rect.fromCircle(center: const Offset(48, 48), radius: r);
    while (a < orbit + 2 * math.pi - 0.001) {
      final len = dashes[i % 4] / r;
      if (i % 2 == 0) canvas.drawArc(rect, a, math.min(len, orbit + 2 * math.pi - a), false, ring);
      a += len;
      i++;
    }

    // هەسارە
    final sat = -secs / 9 * 2 * math.pi - math.pi / 2;
    final sp = Offset(48 + 43 * math.cos(sat), 48 + 43 * math.sin(sat));
    canvas.drawCircle(sp, 6, Paint()..color = _mint.withAlpha(64));
    canvas.drawCircle(sp, 3, Paint()..color = _mint);

    // بەندەکان
    final strap = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [vk(0xFF216374), vk(0xFF082A34)],
      ).createShader(box);
    canvas.drawPath(
      Path()
        ..moveTo(39, 11)
        ..lineTo(57, 11)
        ..lineTo(54.5, 29)
        ..lineTo(41.5, 29)
        ..close(),
      strap,
    );
    canvas.drawPath(
      Path()
        ..moveTo(41.5, 67)
        ..lineTo(54.5, 67)
        ..lineTo(57, 85)
        ..lineTo(39, 85)
        ..close(),
      strap,
    );
    final holes = Paint()
      ..color = _cy.withAlpha(89)
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;
    for (final l in const [
      [43.0, 17.0, 53.0, 17.0],
      [42.5, 21.0, 53.5, 21.0],
      [45.0, 75.0, 51.0, 75.0],
      [45.5, 79.0, 50.5, 79.0],
    ]) {
      canvas.drawLine(Offset(l[0], l[1]), Offset(l[2], l[3]), holes);
    }

    // لەشی سەعات
    final caseR = RRect.fromRectAndRadius(const Rect.fromLTWH(28, 25, 40, 46), const Radius.circular(14));
    canvas.drawRRect(
      caseR,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [vk(0xFF1A3A45), vk(0xFF04100F)],
        ).createShader(box),
    );
    canvas.drawRRect(
      caseR,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.7
        ..shader = grad.createShader(box),
    );
    // دوگمە
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(69, 41, 3.2, 10), const Radius.circular(1.6)),
      Paint()..shader = grad.createShader(box),
    );
    // شاشە
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(32.5, 29.5, 31, 37), const Radius.circular(10)),
      Paint()..color = vk(0xFF031318),
    );

    // خاڵی لێدانی دڵ
    final pulse = (secs % 1.3) / 1.3;
    final pr = 1.8 + 1.2 * (0.5 - 0.5 * math.cos(pulse * 2 * math.pi));
    canvas.drawCircle(const Offset(48, 37), pr, Paint()..color = vk(0xFFFF5F7E));

    // هێڵی ECG
    final ecg = Path()
      ..moveTo(36, 51)
      ..lineTo(42.5, 51)
      ..lineTo(45.5, 43)
      ..lineTo(50.5, 58)
      ..lineTo(53.5, 49)
      ..lineTo(55.5, 51)
      ..lineTo(60, 51);
    final m = ecg.computeMetrics().first;
    final ph = (secs % 2.8) / 2.8;
    double from = 0, to = 1;
    if (ph < .5) {
      to = ph / .5;
    } else if (ph > .8) {
      from = (ph - .8) / .2;
    }
    if (to > from) {
      canvas.drawPath(
        m.extractPath(m.length * from, m.length * to),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.3
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..shader = grad.createShader(box),
      );
    }
    // هێڵی بچووکی خوارەوە
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(41, 60, 14, 2.4), const Radius.circular(1.2)),
      Paint()..color = _cy.withAlpha(115),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _EmblemPainter old) => old.secs != secs;
}
