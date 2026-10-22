// VEX Health — پارچە هاوبەشەکانی دۆخی «Band پەیوەست نییە» (دیزاینی B)
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'band_pair_card.dart';
import '../core/theme.dart';
import 'band_state.dart';

/// ڕەنگەکانی دۆخی نەپەیوەست
class BandColors {
  BandColors._();
  static Color get dot => V.coral; // خاڵی سوور
  static Color get label => V.amber; // نووسینی «پەیوەست نییە»
  static Color get mute => V.mu;
}

/// بنیاتنەر: کاتێک دۆخەکە دەگۆڕێت خۆی نوێ دەبێتەوە
class BandBuilder extends StatelessWidget {
  const BandBuilder({super.key, required this.builder});
  final Widget Function(BuildContext context, bool connected) builder;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: BandState.I,
      builder: (context, _) => builder(context, BandState.I.connected),
    );
  }
}

/// «دوایین هاوکاتکردن: 12:42»
Widget lastSyncText({double size = 12, Color? color}) { color ??= BandColors.mute;
  final t = BandState.I.lastSync;
  if (t.isEmpty) return VText('هێشتا هاوکات نەکراوە', style: ku(size, c: color));
  return VText.rich(
    TextSpan(children: [
      const TextSpan(text: 'دوایین هاوکاتکردن: '),
      TextSpan(text: t, style: nu(size, w: FontWeight.w700, c: color)),
    ]),
    style: ku(size, c: color),
  );
}

/// دوگمەی «پەیوەستکردنەوە» (یان چاوەڕوانی)
class ReconnectButton extends StatelessWidget {
  const ReconnectButton({super.key, this.compact = false});
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: BandState.I,
      builder: (context, _) {
        final busy = BandState.I.reconnecting;
        return Press(
          onTap: busy ? null : showBandPair,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: compact ? 11 : 14, vertical: compact ? 6 : 9),
            decoration: BoxDecoration(color: V.cy, borderRadius: BorderRadius.circular(99)),
            child: busy
                ? SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2, color: kOnAcc),
                  )
                : VText('پەیوەستکردنەوە', style: ku(compact ? 11.5 : 12.5, w: FontWeight.w800, c: kOnAcc, h: 1.2)),
          ),
        );
      },
    );
  }
}

/// بانەری سەرەوەی شاشەی تەندروستی (تەنها کاتێک پەیوەست نییە)
class BandBanner extends StatelessWidget {
  const BandBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return BandBuilder(
      builder: (context, on) {
        if (on) return const SizedBox.shrink();
        if (!BandState.I.everPaired) return const BandPairCard();
        return Container(
          margin: const EdgeInsets.only(top: 14),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: op(BandColors.dot, 0.07),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: op(BandColors.dot, 0.4)),
          ),
          child: Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(shape: BoxShape.circle, color: BandColors.dot),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    VText('Band پەیوەست نییە', style: ku(14, w: FontWeight.w800, h: 1.5)),
                    lastSyncText(),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              const ReconnectButton(),
            ],
          ),
        );
      },
    );
  }
}

/// هێڵی خاڵخاڵی ناوەڕاست (جێگرەوەی هێڵی ECG و ...)
class DashedLinePainter extends CustomPainter {
  DashedLinePainter({Color? color, this.opacity = 0.55}) : color = color ?? BandColors.mute;
  final Color color;
  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = op(color, opacity)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    final y = size.height / 2;
    double x = 2;
    while (x < size.width - 2) {
      canvas.drawLine(Offset(x, y), Offset(math.min(x + 4, size.width - 2), y), p);
      x += 8;
    }
  }

  @override
  bool shouldRepaint(covariant DashedLinePainter old) => old.color != color || old.opacity != opacity;
}

/// بازنەی خاڵخاڵ لەسەر canvas
void paintDashedCircle(Canvas canvas, Offset c, double r, Color color, double stroke,
    {double dash = 2.5, double gap = 8}) {
  final p = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = stroke
    ..strokeCap = StrokeCap.round
    ..color = color;
  final circ = 2 * math.pi * r;
  final n = math.max(8, (circ / (dash + gap)).floor());
  final step = 2 * math.pi / n;
  final sweep = step * dash / (dash + gap);
  final rect = Rect.fromCircle(center: c, radius: r);
  for (int i = 0; i < n; i++) {
    canvas.drawArc(rect, -math.pi / 2 + i * step, math.max(0.001, sweep), false, p);
  }
}

/// دوو دێڕی ژێر ژمارە: «پەیوەست نییە» + «دوایین: 68 bpm»
class OfflineCaption extends StatelessWidget {
  const OfflineCaption({super.key, this.last, this.unit = ''});
  final String? last;
  final String unit;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        VText('پەیوەست نییە', style: ku(12, w: FontWeight.w700, c: BandColors.label, h: 1.5)),
        if (last != null)
          VText.rich(
            TextSpan(children: [
              const TextSpan(text: 'دوایین: '),
              TextSpan(
                text: unit.isEmpty ? last! : '$last $unit',
                style: nu(11.5, w: FontWeight.w600, c: V.tx),
              ),
            ]),
            style: ku(11.5, c: BandColors.mute, h: 1.5),
          ),
      ],
    );
  }
}
