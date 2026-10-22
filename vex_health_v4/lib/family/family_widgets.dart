// VEX Health — پارچەکانی بازنەی خێزان: وێنەی ئەندام، QR، سویچ، تەقینەوەی ئیمۆجی
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme.dart';
import 'family_data.dart';

// ============================================================
// شوێنی دوایین دەستلێدان (بۆ تەقینەوەی ئیمۆجی)
// ============================================================
Offset? _lastTap;

/// هەر دەستلێدانێک لە ناو ئەم بەشەدا شوێنەکەی تۆمار دەکات
class TapTracker extends StatelessWidget {
  const TapTracker({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (e) => _lastTap = e.position,
      child: child,
    );
  }
}

/// تەقینەوەی ئیمۆجی لە شوێنی دەستلێدانەوە
void burst(List<String> emo, {bool center = false}) {
  final overlay = navKey.currentState?.overlay;
  final ctx = navKey.currentContext;
  if (overlay == null || ctx == null) return;
  final size = MediaQuery.of(ctx).size;
  final at = (!center && _lastTap != null) ? _lastTap! : Offset(size.width / 2, size.height / 2);
  final rnd = math.Random();
  for (int i = 0; i < 7; i++) {
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _BurstBit(
        emoji: emo[i % emo.length],
        at: at,
        dx: rnd.nextDouble() * 120 - 60,
        delayMs: i * 50,
        onDone: () {
          if (entry.mounted) entry.remove();
        },
      ),
    );
    overlay.insert(entry);
  }
}

class _BurstBit extends StatefulWidget {
  const _BurstBit({required this.emoji, required this.at, required this.dx, required this.delayMs, required this.onDone});
  final String emoji;
  final Offset at;
  final double dx;
  final int delayMs;
  final VoidCallback onDone;

  @override
  State<_BurstBit> createState() => _BurstBitState();
}

class _BurstBitState extends State<_BurstBit> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1300));

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(Duration(milliseconds: widget.delayMs), () {
      if (mounted) _c.forward().whenComplete(widget.onDone);
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: widget.at.dx - 16,
      top: widget.at.dy - 18,
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, child) {
            final t = Curves.easeOut.transform(_c.value);
            return Opacity(
              opacity: _c.value == 0 ? 0 : (1 - t).clamp(0.0, 1.0).toDouble(),
              child: Transform.translate(
                offset: Offset(widget.dx * t, -180 * t),
                child: Transform.scale(scale: 1 + 0.4 * t, child: child),
              ),
            );
          },
          child: Material(
            type: MaterialType.transparency,
            child: VText(widget.emoji, style: const TextStyle(fontSize: 28)),
          ),
        ),
      ),
    );
  }
}

/// کردار لەسەر ئەندامێک (هاندان، یادخستنەوە، پەیوەندی، ئاو، دەرمان)
void memberAction(String t, FMember m) {
  switch (t) {
    case 'cheer':
      burst(const ['👏', '💚', '🔥', '⭐']);
      toast('👏 هاندانت نارد بۆ ${m.n}');
      break;
    case 'remind':
      toast('🔔 یادخستنەوە نێردرا بۆ ${m.n}');
      break;
    case 'call':
      toast('📞 پەیوەندی دەکرێت بە ${m.n}...');
      break;
    case 'water':
      toast('💧 یادخستنەوەی ئاو نێردرا بۆ ${m.n}');
      break;
    case 'med':
      toast('💊 یادخستنەوەی دەرمان نێردرا بۆ ${m.n}');
      break;
  }
}

String actionLabel(String a) => a == 'call'
    ? '📞 پەیوەندی'
    : a == 'remind'
        ? '🔔 یادخستنەوە'
        : '👏 هاندان';

// ============================================================
// وێنەی ئەندام: بازنەی هەنگاو + ئیمۆجی + خاڵی دۆخ
// ============================================================
class MemberAvatar extends StatelessWidget {
  const MemberAvatar(this.m, {super.key, this.size = 60});
  final FMember m;
  final double size;

  @override
  Widget build(BuildContext context) {
    final s = size / 60;
    if (m.pend) return PendingAvatar(size: size);
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: m.stepFrac),
              duration: const Duration(milliseconds: 1100),
              curve: const Cubic(0.2, 0.9, 0.2, 1.0),
              builder: (context, v, _) => CustomPaint(painter: _RingPainter(v, m.color, s)),
            ),
          ),
          Positioned(
            left: 7 * s,
            top: 7 * s,
            right: 7 * s,
            bottom: 7 * s,
            child: Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [m.grad0, m.grad1],
                ),
              ),
              child: VText(m.e, style: TextStyle(fontSize: 24 * s, height: 1.1)),
            ),
          ),
          Positioned(
            left: 2 * s,
            bottom: 0,
            child: StatusDot(color: m.stColor, size: 16 * s, pulse: m.st == 'r'),
          ),
        ],
      ),
    );
  }
}

/// وێنەی بانگهێشتی چاوەڕوان
class PendingAvatar extends StatelessWidget {
  const PendingAvatar({super.key, this.size = 60});
  final double size;

  @override
  Widget build(BuildContext context) {
    final s = size / 60;
    return Opacity(
      opacity: 0.45,
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: 7 * s,
              top: 7 * s,
              right: 7 * s,
              bottom: 7 * s,
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [vk(0xFF445566), vk(0xFF223344)],
                  ),
                ),
                child: VText('⏳', style: TextStyle(fontSize: 24 * s, height: 1.1)),
              ),
            ),
            Positioned(left: 2 * s, bottom: 0, child: StatusDot(color: FK.y, size: 16 * s)),
          ],
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.f, this.color, this.s);
  final double f;
  final Color color;
  final double s;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = 28 * s;
    final w = 4 * s;
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = w
        ..color = V.track,
    );
    if (f <= 0) return;
    final rect = Rect.fromCircle(center: c, radius: r);
    final sweep = math.pi * 2 * f;
    canvas.drawArc(
      rect,
      -math.pi / 2,
      sweep,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = w
        ..strokeCap = StrokeCap.round
        ..color = op(color, 0.75)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );
    canvas.drawArc(
      rect,
      -math.pi / 2,
      sweep,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = w
        ..strokeCap = StrokeCap.round
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) => old.f != f || old.color != color || old.s != s;
}

/// خاڵی دۆخ (سوور: لێدەدات)
class StatusDot extends StatefulWidget {
  const StatusDot({super.key, required this.color, this.size = 16, this.pulse = false, this.border = 3});
  final Color color;
  final double size;
  final bool pulse;
  final double border;

  @override
  State<StatusDot> createState() => _StatusDotState();
}

class _StatusDotState extends State<StatusDot> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));

  @override
  void initState() {
    super.initState();
    if (widget.pulse) _c.repeat();
  }

  @override
  void didUpdateWidget(covariant StatusDot old) {
    super.didUpdateWidget(old);
    if (widget.pulse && !_c.isAnimating) {
      _c.repeat();
    } else if (!widget.pulse && _c.isAnimating) {
      _c.stop();
      _c.value = 0;
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        // 0 → 0.5 → 1 : بچووک → گەورە → بچووک (هەمان keyframes ـی وێب)
        final v = _c.value;
        final k = widget.pulse ? (v < 0.5 ? v * 2 : (1 - v) * 2) : 0.0;
        return Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.color,
            border: Border.all(color: V.bg, width: widget.border * widget.size / 16),
            boxShadow: k > 0
                ? [BoxShadow(color: op(widget.color, 0.3), spreadRadius: 6 * Curves.easeInOut.transform(k))]
                : null,
          ),
        );
      },
    );
  }
}

// ============================================================
// QR ـی بانگهێشت (نموونەی بینراو، هەمان شێوازی وێب)
// ============================================================
class InviteQr extends StatelessWidget {
  const InviteQr(this.seed, {super.key, this.size = 96});
  final String seed;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: kW, borderRadius: BorderRadius.circular(14)),
      child: CustomPaint(painter: _QrPainter(seed)),
    );
  }
}

class _QrPainter extends CustomPainter {
  _QrPainter(this.seed);
  final String seed;

  static const int n = 21;
  static Color get ink => vk(0xFF062832);

  bool _finder(int x, int y) => (x < 7 && y < 7) || (x >= n - 7 && y < 7) || (x < 7 && y >= n - 7);

  @override
  void paint(Canvas canvas, Size size) {
    final u = size.width / n;
    final p = Paint()..color = ink;
    int h = 0;
    for (final ch in seed.codeUnits) {
      h = (h * 31 + ch) & 0xFFFFFFFF;
    }
    for (int y = 0; y < n; y++) {
      for (int x = 0; x < n; x++) {
        if (_finder(x, y)) continue;
        h = (h * 1103515245 + 12345) & 0xFFFFFFFF;
        if (h % 2 == 1) canvas.drawRect(Rect.fromLTWH(x * u, y * u, u + 0.3, u + 0.3), p);
      }
    }
    final w = Paint()..color = kW;
    void f(int x, int y) {
      canvas.drawRect(Rect.fromLTWH(x * u, y * u, 7 * u, 7 * u), p);
      canvas.drawRect(Rect.fromLTWH((x + 1) * u, (y + 1) * u, 5 * u, 5 * u), w);
      canvas.drawRect(Rect.fromLTWH((x + 2) * u, (y + 2) * u, 3 * u, 3 * u), p);
    }

    f(0, 0);
    f(n - 7, 0);
    f(0, n - 7);
  }

  @override
  bool shouldRepaint(covariant _QrPainter old) => old.seed != seed;
}

/// بۆکسی کۆدی بانگهێشت (QR + کۆد)
class InviteCodeBox extends StatelessWidget {
  const InviteCodeBox({super.key, required this.code, required this.caption});
  final String code;
  final String caption;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      foregroundPainter: DashedRRect(radius: 20),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: V.surf2, borderRadius: BorderRadius.circular(20)),
        child: Row(
          children: [
            InviteQr(code),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  VText(caption, style: ku(11, c: V.mu, h: 1.6)),
                  const SizedBox(height: 2),
                  VText(code, textDirection: TextDirection.ltr, style: nu(24, ls: 3)),
                  const SizedBox(height: 2),
                  VText('7 ڕۆژ کارایە', style: ku(11, c: V.mu)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// چوارگۆشەی خاڵ خاڵ
class DashedRRect extends CustomPainter {
  DashedRRect({this.radius = 20, Color? color}) : color = color ?? V.line2;
  final double radius;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..addRRect(RRect.fromRectAndRadius((Offset.zero & size).deflate(0.5), Radius.circular(radius)));
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = color;
    for (final m in path.computeMetrics()) {
      double d = 0;
      while (d < m.length) {
        canvas.drawPath(m.extractPath(d, math.min(d + 5, m.length)), p);
        d += 9;
      }
    }
  }

  @override
  bool shouldRepaint(covariant DashedRRect old) => old.radius != radius || old.color != color;
}

// ============================================================
// سویچ
// ============================================================
class VSwitch extends StatelessWidget {
  const VSwitch({super.key, required this.on, required this.onTap, this.label});
  final bool on;
  final VoidCallback onTap;
  final String? label;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      toggled: on,
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: 46,
            height: 28,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: on ? V.mint : V.track,
              borderRadius: BorderRadius.circular(99),
            ),
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                // وەک وێب: کوژاوە = ڕاست، داگیرساو = چەپ
                alignment: (on != kIsLtr) ? Alignment.centerLeft : Alignment.centerRight,
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: kW,
                    boxShadow: [BoxShadow(color: vk(0x33000000), blurRadius: 4, offset: Offset(0, 1))],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// کارت (هەمان .card ـی وێب)
// ============================================================
class FCard extends StatelessWidget {
  const FCard({super.key, required this.child, this.top = 14});
  final Widget child;
  final double top;

  @override
  Widget build(BuildContext context) => VCard(margin: EdgeInsets.only(top: top), child: child);
}

/// سەردێڕی کارت: ناونیشان + نووسینی بچووک
class FTitle extends StatelessWidget {
  const FTitle(this.title, this.small, {super.key, this.bottom = 12});
  final String title;
  final String small;
  final double bottom;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Row(
        children: [
          Expanded(child: VText(title, style: ku(16, w: FontWeight.w800))),
          const SizedBox(width: 8),
          VText(small, style: ku(12, c: V.mu)),
        ],
      ),
    );
  }
}

/// دوگمەی بچووکی ناو ئاگادارکردنەوە
class SmallBtn extends StatelessWidget {
  const SmallBtn(this.label, {super.key, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Press(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: box(r: 11, border: V.line2),
        child: VText(label, style: ku(12, w: FontWeight.w800)),
      ),
    );
  }
}
