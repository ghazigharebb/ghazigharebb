// VEX Health — پێوەری نیوەبازنەیی BMI بۆ کێشی ئامانج
// (خراپ · کەم · باش · ناوەند · زۆر · خراپ) — دەرزییەکە لە کێشی ئێستاوە دەجووڵێت بۆ ئامانج
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme.dart';
import 'reg_data.dart';
import 'reg_widgets.dart';

const double _gx = 150, _gy = 150, _gr = 118;

Offset _gp(double deg, double r) {
  final a = deg * math.pi / 180;
  return Offset(_gx - r * math.cos(a), _gy - r * math.sin(a));
}

class RGauge extends StatefulWidget {
  const RGauge({
    super.key,
    required this.heightCm,
    required this.weight,
    required this.target,
    required this.unit,
    required this.onMinus,
    required this.onPlus,
    this.compact = false,
  });
  final int heightCm;
  final double weight;
  final double target;
  final String unit; // kg | lb
  final VoidCallback onMinus;
  final VoidCallback onPlus;
  final bool compact;

  @override
  State<RGauge> createState() => _RGaugeState();
}

class _RGaugeState extends State<RGauge> with SingleTickerProviderStateMixin {
  late final AnimationController _intro =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1000))..forward();
  Timer? _t;
  bool _armed = false;

  double get _m => math.pow(widget.heightCm / 100, 2).toDouble();
  double get _bt => widget.target / _m;
  double get _bc => widget.weight / _m;

  @override
  void initState() {
    super.initState();
    // یەکەم جار دەرزییەکە لە کێشی ئێستاوە دەڕوات بۆ ئامانج
    _t = Timer(const Duration(milliseconds: 420), () {
      if (mounted) setState(() => _armed = true);
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    _intro.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final zi = zoneIdx(_bt);
    final z = kZones[zi];
    final at = bmiAngle(_bt);
    final ac = bmiAngle(_bc);
    final lb = widget.unit == 'lb';
    final shown = lb ? '${(widget.target * 2.20462).round()}' : numTxt(widget.target);
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: widget.compact ? 290 : 330),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AspectRatio(
              aspectRatio: 300 / 168,
              child: LayoutBuilder(
                builder: (context, cons) {
                  final s = cons.maxWidth / 300;
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned.fill(
                        child: TweenAnimationBuilder<double>(
                          tween: Tween<double>(end: _armed ? at : ac),
                          duration: const Duration(milliseconds: 550),
                          curve: Curves.easeOutBack,
                          builder: (context, knob, _) => AnimatedBuilder(
                            animation: _intro,
                            builder: (context, _) => CustomPaint(
                              painter: _GaugePainter(
                                intro: _intro.value,
                                zone: zi,
                                knob: knob,
                                now: ac,
                                target: at,
                              ),
                            ),
                          ),
                        ),
                      ),
                      // ژمارەی ئامانج لە ناوەڕاست
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 4 * s,
                        child: Directionality(
                          textDirection: TextDirection.ltr,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              RPM(plus: false, onTap: widget.onMinus, size: 40),
                              const SizedBox(width: 10),
                              SizedBox(
                                width: 112,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: ShaderMask(
                                        shaderCallback: (r) => LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: [kW, vk(0xFFBFF7FB)],
                                        ).createShader(r),
                                        blendMode: BlendMode.srcIn,
                                        child: VText(shown,
                                            style: nu(widget.compact ? 36 : 44, c: kW, h: 1, ls: -1.5)),
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    VText(lb ? 'پاوەند · ئامانج' : 'کیلۆگرام · ئامانج',
                                        textDirection: TextDirection.rtl,
                                        style: ku(12, w: FontWeight.w700, c: RC.mu, h: 1.3)),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                              RPM(plus: true, onTap: widget.onPlus, size: 40),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 5),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(99),
                color: op(z.color, 0.13),
                border: Border.all(color: op(z.color, 0.45)),
              ),
              child: VText.rich(
                TextSpan(children: [
                  TextSpan(text: '${z.text} · BMI '),
                  TextSpan(text: ltr(_bt.toStringAsFixed(1)), style: nu(12.5, c: z.color)),
                ]),
                style: ku(12.5, w: FontWeight.w800, c: z.color, h: 1.4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  _GaugePainter({required this.intro, required this.zone, required this.knob, required this.now, required this.target});
  final double intro;
  final int zone;
  final double knob;
  final double now;
  final double target;

  TextPainter _text(String s, Color c, double size, FontWeight w) {
    return TextPainter(
      text: TextSpan(text: vxTr(s), style: ku(size, w: w, c: c, h: 1)),
      textDirection: kDir,
    )..layout();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 300;
    canvas.save();
    canvas.scale(s);
    final rect = Rect.fromCircle(center: const Offset(_gx, _gy), radius: _gr);
    final kc = kZones[zone].color;

    // ڕێڕەوی پشتەوە
    canvas.drawArc(
      rect,
      math.pi,
      math.pi,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 28
        ..strokeCap = StrokeCap.round
        ..color = vk(0x0DFFFFFF),
    );

    // ناوچەکان
    double a0 = 0;
    for (int i = 0; i < kZones.length; i++) {
      final z = kZones[i];
      final st = a0 + 1.4;
      final sw = z.deg - 2.8;
      final p = ((intro * 1000 - 60 * i) / 700).clamp(0.0, 1.0);
      final e = Curves.easeOutCubic.transform(p);
      if (e > 0) {
        final on = i == zone;
        if (on) {
          canvas.drawArc(
            rect,
            math.pi + st * math.pi / 180,
            sw * e * math.pi / 180,
            false,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 15
              ..strokeCap = StrokeCap.round
              ..color = op(z.color, 0.55)
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
          );
        }
        canvas.drawArc(
          rect,
          math.pi + st * math.pi / 180,
          sw * e * math.pi / 180,
          false,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = on ? 15 : 13
            ..strokeCap = StrokeCap.round
            ..color = on ? z.color : op(z.color, 0.32),
        );
      }
      // ناوی ناوچە
      final m = _gp(a0 + z.deg / 2, _gr + 21);
      final tp = _text(z.label, i == zone ? z.color : op(z.color, 0.42), 11.5, FontWeight.w800);
      tp.paint(canvas, Offset(m.dx - tp.width / 2, m.dy - tp.height / 2));
      a0 += z.deg;
    }

    // هێڵە بچووکەکان
    final tk = Paint()
      ..color = vk(0x2E8CEBF5)
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;
    for (int a = 0; a <= 180; a += 6) {
      canvas.drawLine(_gp(a.toDouble(), _gr - 15), _gp(a.toDouble(), _gr - (a % 30 == 0 ? 23 : 19)), tk);
    }

    // ڕێگای نێوان ئێستا و ئامانج (خاڵخاڵ)
    final lo = math.min(now, target), hi = math.max(now, target);
    if (hi - lo > 0.8) {
      const r2 = _gr - 30;
      final dot = Paint()..color = op(kc, 0.85);
      final len = (hi - lo) * math.pi / 180 * r2;
      final n = math.max(1, (len / 7).floor());
      for (int i = 0; i <= n; i++) {
        final a = lo + (hi - lo) * i / n;
        canvas.drawCircle(_gp(a, r2), 1.5, dot);
      }
    }

    // نیشانەی کێشی ئێستا
    final np = _gp(now, _gr);
    canvas.drawCircle(np, 6.5, Paint()..color = RC.bg);
    canvas.drawCircle(
      np,
      6.5,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..color = RC.soft,
    );
    if ((target - now).abs() >= 14) {
      final tp = _text('ئێستا', RC.p, 9.5, FontWeight.w700);
      tp.paint(canvas, Offset(np.dx - tp.width / 2, np.dy - 13 - tp.height));
    }

    // دەرزی (بازنەی ئامانج)
    final kp = _gp(knob.clamp(0.0, 180.0), _gr);
    canvas.drawCircle(kp, 16, Paint()..color = op(kc, 0.22));
    canvas.drawCircle(kp, 9.5, Paint()..color = kW);
    canvas.drawCircle(
      kp,
      9.5,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.5
        ..color = kc,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_GaugePainter o) =>
      o.intro != intro || o.zone != zone || o.knob != knob || o.now != now || o.target != target;
}
