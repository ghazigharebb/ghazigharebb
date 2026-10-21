// VEX Health — چالاکی، بازنەی خێزان، ئامرازەکان
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../band/band_widgets.dart';
import '../core/icons.dart';
import '../core/store.dart';
import '../core/theme.dart';
import 'detail_sheets.dart';
import '../family/family_data.dart';
import '../family/family_page.dart';
import '../family/family_widgets.dart';
import '../health/hc.dart' show pushPage;

const Cubic _ease = Cubic(0.2, 0.9, 0.2, 1.0);

// ============================================================
// چالاکی ئەمڕۆ
// ============================================================
class ActivityCard extends StatelessWidget {
  const ActivityCard({super.key});

  static const String _pin = '<path d="M12 21s-6.5-6-6.5-11a6.5 6.5 0 0 1 13 0c0 5-6.5 11-6.5 11z"/><circle cx="12" cy="10" r="2.3"/>';
  static const String _flame =
      '<path d="M12 3c1 3 4 4.5 4 8.5a4 4 0 0 1-8 0c0-1.6.7-2.6 1.5-3.5C9.5 10 11 9 11 7c0-1.5.4-2.8 1-4z"/>';
  static const String _timer = '<circle cx="12" cy="13" r="7.5"/><path d="M12 9v4l2.5 1.5M9.5 3h5"/>';

  /// چیپی بچووک: ئایکۆن + ژمارە + ناونیشان
  Widget _chip(String icon, String hex, Color color, String v, String label, bool on) => Expanded(
        child: Container(
          padding: const EdgeInsets.fromLTRB(2, 7, 2, 6),
          decoration: BoxDecoration(
            color: op(color, 0.11),
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: op(color, 0.24)),
          ),
          child: Opacity(
            opacity: on ? 1 : 0.5,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                svgIcon(icon, hex, size: 15),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(on ? v : '—', textDirection: TextDirection.ltr, maxLines: 1, style: nu(14, c: on ? V.tx : V.mu, h: 1.2)),
                ),
                Text(label, style: ku(9.5, w: FontWeight.w700, c: V.mu, h: 1.3)),
              ],
            ),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) => BandBuilder(builder: (context, on) => _card(on));

  Widget _card(bool on) {
    final h = Store.I.h;
    final pct = (clampD(h.steps / 10000, 0, 1) * 100).round();
    final left = 10000 - h.steps;
    return VCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CardTitle('چالاکی ئەمڕۆ', link: 'وردەکاری ‹', onLink: openActivitySheet),
          Row(
            children: [
              SizedBox(width: 98, height: 98, child: StepsRing(steps: h.steps, off: !on, compact: true)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: !on
                              ? Text('Band پەیوەست نییە', style: ku(12, w: FontWeight.w700, c: V.mu, h: 1.5))
                              : left > 0
                                  ? Text.rich(
                                      TextSpan(children: [
                                        TextSpan(text: fmt(left), style: nu(12, c: V.tx)),
                                        const TextSpan(text: ' هەنگاو ماوە'),
                                      ]),
                                      style: ku(12, w: FontWeight.w700, c: V.mu, h: 1.5),
                                    )
                                  : Text('ئامانج تەواو بوو 🎉', style: ku(12, w: FontWeight.w700, c: V.mu, h: 1.5)),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 2),
                          decoration: BoxDecoration(color: op(V.mint, 0.16), borderRadius: BorderRadius.circular(99)),
                          child: Text(on ? '$pct%' : '—', textDirection: TextDirection.ltr, style: nu(11.5, c: V.mint, h: 1.5)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _chip(_pin, '#2fe6f3', V.cy, h.km.toStringAsFixed(2), 'کیلۆمەتر', on),
                        const SizedBox(width: 6),
                        _chip(_flame, '#ff9466', V.orange, fmt(h.kcal), 'کالۆری', on),
                        const SizedBox(width: 6),
                        _chip(_timer, '#9b7bff', V.violet, '${h.active}', 'خولەک', on),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (on)
            const HourBars(height: 34)
          else
            const SizedBox(height: 34, child: CustomPaint(painter: DashedLinePainter())),
          const SizedBox(height: 3),
          Directionality(
            textDirection: TextDirection.ltr,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (final l in const ['00', '06', '12', '18', '24'])
                  Text(l, style: nu(9, w: FontWeight.w400, c: V.mu)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: VBtn('🏃 دەستپێکردنی وەرزش',
                    kind: BtnKind.prime, fontSize: 13, onTap: () => toast('ئەم بەشە لە ئەپی ڕاستەقینەدا دەکرێتەوە')),
              ),
              const SizedBox(width: 8),
              VBtn('✨ پلانی AI', fontSize: 13, onTap: () => toast('ئەم بەشە لە ئەپی ڕاستەقینەدا دەکرێتەوە')),
            ],
          ),
        ],
      ),
    );
  }
}

class StepsRing extends StatelessWidget {
  const StepsRing({super.key, required this.steps, this.off = false, this.compact = false});
  final int steps;

  /// بچووک (کارتی سەرەکی)
  final bool compact;

  /// Band پەیوەست نییە: «—» + بازنەی خاڵخاڵ
  final bool off;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 1500),
      curve: _ease,
      builder: (context, v, _) => CustomPaint(
        painter: _StepsPainter(off ? 0 : clampD(steps / 10000, 0, 1) * v, off: off),
        child: Center(
          child: off
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('—', textDirection: TextDirection.ltr, style: nu(compact ? 21 : 27, c: V.mu, h: 1.0)),
                    const SizedBox(height: 4),
                    Text('پەیوەست نییە', style: ku(compact ? 9.5 : 11, w: FontWeight.w700, c: BandColors.label)),
                  ],
                )
              : Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(fmt(steps * v), textDirection: TextDirection.ltr, style: nu(compact ? 21 : 27, c: V.mint, h: 1.0)),
              SizedBox(height: compact ? 2 : 3),
              Text.rich(
                TextSpan(children: [
                  const TextSpan(text: 'لە '),
                  TextSpan(text: '10,000', style: nu(compact ? 9.5 : 11, w: FontWeight.w600, c: V.mu)),
                  if (!compact) const TextSpan(text: ' هەنگاو'),
                ]),
                style: ku(compact ? 9.5 : 11, c: V.mu),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepsPainter extends CustomPainter {
  _StepsPainter(this.f, {this.off = false});
  final double f;
  final bool off;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 132;
    final c = Offset(size.width / 2, size.height / 2);
    final r = 56 * s;
    if (off) {
      paintDashedCircle(canvas, c, r, op(BandColors.mute, 0.55), 6 * s, dash: 2.5, gap: 9);
      return;
    }
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 12 * s
        ..color = V.track,
    );
    if (f <= 0.001) return;
    final rect = Rect.fromCircle(center: c, radius: r);
    final sweep = math.pi * 2 * f;
    canvas.drawArc(
      rect,
      -math.pi / 2,
      sweep,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 12 * s
        ..strokeCap = StrokeCap.round
        ..color = op(V.mint, 0.5)
        ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 6),
    );
    canvas.drawArc(
      rect,
      -math.pi / 2,
      sweep,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 12 * s
        ..strokeCap = StrokeCap.round
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [V.c2, V.mint],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(covariant _StepsPainter oldDelegate) => oldDelegate.f != f || oldDelegate.off != off;
}

class HourBars extends StatelessWidget {
  const HourBars({super.key, this.height = 56});
  final double height;

  static const List<int> _hr = [0, 0, 0, 0, 0, 0, 0, 40, 15, 30, 60, 100, 20, 10, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now().hour;
    return SizedBox(
      height: height,
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (int i = 0; i < 24; i++) ...[
              if (i > 0) const SizedBox(width: 2),
              Expanded(
                child: Opacity(
                  opacity: i == now ? 1.0 : (i > now ? 0.08 : (_hr[i] > 0 ? 0.85 : 0.18)),
                  child: Container(
                    height: height * (_hr[i] > 0 ? math.max(8, _hr[i]) : 4) / 100,
                    decoration: BoxDecoration(
                      color: V.mint,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(2), bottom: Radius.circular(1)),
                      boxShadow: i == now ? [BoxShadow(color: op(V.mint, 0.6), blurRadius: 8)] : null,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ============================================================
// بازنەی خێزان
// ============================================================
class FamilyCard extends StatelessWidget {
  const FamilyCard({super.key});

  static void _open({bool add = false, String? memberId}) =>
      pushPage(FamilyPage(openAdd: add, openMemberId: memberId));

  Widget _avatar(FMember m) {
    final k = m.pend ? V.amber : m.stColor;
    return SizedBox(
      width: 57,
      height: 57,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(child: DecoratedBox(decoration: BoxDecoration(shape: BoxShape.circle, color: k))),
          const Positioned(
            left: 2,
            top: 2,
            right: 2,
            bottom: 2,
            child: DecoratedBox(decoration: BoxDecoration(shape: BoxShape.circle, color: V.bg)),
          ),
          Positioned(
            left: 4.5,
            top: 4.5,
            right: 4.5,
            bottom: 4.5,
            child: Opacity(
              opacity: m.pend ? 0.5 : 1,
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: m.pend ? const [Color(0xFF445566), Color(0xFF223344)] : [m.grad0, m.grad1],
                  ),
                ),
                child: Text(m.pend ? '⏳' : m.e, style: const TextStyle(fontSize: 24)),
              ),
            ),
          ),
          Positioned(
            left: 4.5,
            bottom: 4.5,
            child: (!m.pend && m.st == 'r') ? _PulseDot(color: k) : _dot(k),
          ),
        ],
      ),
    );
  }

  static Widget _dot(Color c) => Container(
        width: 13,
        height: 13,
        decoration: BoxDecoration(shape: BoxShape.circle, color: c, border: Border.all(color: V.bg, width: 2.5)),
      );

  Widget _member(FMember m) {
    return Press(
      onTap: () => _open(memberId: m.id),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _avatar(m),
          const SizedBox(height: 3),
          Text(m.n, maxLines: 1, overflow: TextOverflow.ellipsis, style: ku(11, w: FontWeight.w700)),
          if (m.pend)
            Text('چاوەڕوان', maxLines: 1, style: ku(10, c: V.amber))
          else
            Text('${fmt(m.steps)} 👣', textDirection: TextDirection.ltr, style: nu(10, w: FontWeight.w400, c: V.mu)),
        ],
      ),
    );
  }

  Widget _addMember() {
    return Press(
      onTap: () => _open(add: true),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 57,
            height: 57,
            child: Center(
              child: SizedBox(
                width: 48,
                height: 48,
                child: CustomPaint(
                  painter: const _DashedCircle(),
                  child: Center(child: Text('+', style: nu(24, c: V.cy, h: 1.0))),
                ),
              ),
            ),
          ),
          const SizedBox(height: 3),
          Text('زیادکردن', style: ku(11, w: FontWeight.w700)),
          Text(' ', style: nu(10, w: FontWeight.w400)),
        ],
      ),
    );
  }

  Widget _alert(FAlert a) {
    final k = FK.of(a.kind);
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: op(k, 0.08),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: op(k, 0.35)),
      ),
      child: Row(
        children: [
          Text(a.kind == 'r' ? '🔴' : a.kind == 'y' ? '🟡' : '🎉', style: const TextStyle(fontSize: 13)),
          const SizedBox(width: 10),
          Expanded(
            child: Text.rich(
              TextSpan(children: [
                TextSpan(text: a.m.n, style: ku(13, w: FontWeight.w800)),
                TextSpan(text: a.text),
              ]),
              style: ku(13, h: 1.6),
            ),
          ),
          const SizedBox(width: 8),
          Press(
            onTap: () => memberAction(a.action, a.m),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: box(r: 11, border: V.line2),
              child: Text(actionLabel(a.action), style: ku(12, w: FontWeight.w800)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return TapTracker(
      child: AnimatedBuilder(
        animation: FamilyStore.I,
        builder: (context, _) {
          final s = FamilyStore.I;
          final shown = <FMember>[...s.members, ...s.pending].take(4).toList();
          final a = s.topAlert();
          return VCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CardTitle('👨‍👩‍👧 بازنەی خێزان', link: 'بینینی هەموو ‹', onLink: () => _open()),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final m in shown) Expanded(child: _member(m)),
                    Expanded(child: _addMember()),
                    for (int i = shown.length; i < 4; i++) const Expanded(child: SizedBox.shrink()),
                  ],
                ),
                if (a != null) _alert(a),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _PulseDot extends StatefulWidget {
  const _PulseDot({required this.color});
  final Color color;

  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 600))..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) => Container(
        width: 13,
        height: 13,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: widget.color,
          border: Border.all(color: V.bg, width: 2.5),
          boxShadow: [BoxShadow(color: op(V.coral, 0.35), spreadRadius: 5 * Curves.easeInOut.transform(_c.value))],
        ),
      ),
    );
  }
}

class _DashedCircle extends CustomPainter {
  const _DashedCircle();

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2 - 0.75;
    canvas.drawCircle(c, r, Paint()..color = V.surf2);
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = V.line2;
    const n = 22;
    final step = math.pi * 2 / n;
    for (int i = 0; i < n; i++) {
      canvas.drawArc(Rect.fromCircle(center: c, radius: r), i * step, step * 0.55, false, p);
    }
  }

  @override
  bool shouldRepaint(covariant _DashedCircle oldDelegate) => false;
}

// ============================================================
// ئامرازەکان (ECG، VEX AI)
// ============================================================
class ToolsRow extends StatelessWidget {
  const ToolsRow({super.key});

  Widget _tool(String title, String sub, String icon, Color k, String hex) {
    return Press(
      onTap: () => toast('ئەم بەشە لە ئەپی ڕاستەقینەدا دەکرێتەوە'),
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: V.surf,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: V.line),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: op(k, 0.16), borderRadius: BorderRadius.circular(14)),
              child: svgIcon(icon, hex, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: ku(13, w: FontWeight.w800)),
                  Text(sub, maxLines: 1, overflow: TextOverflow.ellipsis, style: ku(11, c: V.mu)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Row(
        children: [
          Expanded(child: _tool('پێوانەی ECG', 'ئێلێکترۆکاردیۆگرام', Ico.ecg, V.coral, '#ff5f7e')),
          const SizedBox(width: 10),
          Expanded(child: _tool('VEX AI', 'پرسیاری تەندروستی', Ico.sparkTool, V.cy, '#2fe6f3')),
        ],
      ),
    );
  }
}
