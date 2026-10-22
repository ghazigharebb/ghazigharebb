// VEX Health — پەڕەی بازنەی خێزان و هاوڕێ
// بازنەی خولاوە، ئاگادارکردنەوەکان، چالێنجی هەفتانە، ئەندامەکان، هاوبەشکردن
// و شیتەکانی: وردەکاری ئەندام، بانگهێشتی چاوەڕوان، زیادکردنی کەس
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/icons.dart';
import '../core/theme.dart';
import 'family_data.dart';
import 'family_widgets.dart';

const Cubic _ease = Cubic(0.2, 0.9, 0.2, 1.0);
const Cubic _popCurve = Cubic(0.2, 0.9, 0.3, 1.4);

/// هەر کاتێک داتای بازنەکە گۆڕا، ئەم بەشە نوێ دەبێتەوە
Widget _listen(WidgetBuilder b) => AnimatedBuilder(animation: FamilyStore.I, builder: (context, _) => b(context));

class FamilyPage extends StatefulWidget {
  const FamilyPage({super.key, this.openAdd = false, this.openMemberId});

  /// ڕاستەوخۆ شیتی زیادکردن بکەرەوە
  final bool openAdd;

  /// ڕاستەوخۆ وردەکاری ئەم ئەندامە بکەرەوە
  final String? openMemberId;

  @override
  State<FamilyPage> createState() => _FamilyPageState();
}

class _FamilyPageState extends State<FamilyPage> {
  Timer? _t;

  @override
  void initState() {
    super.initState();
    if (widget.openAdd || widget.openMemberId != null) {
      // دوای تەواوبوونی جووڵەی هاتنی پەڕەکە
      _t = Timer(const Duration(milliseconds: 420), () {
        if (!mounted) return;
        if (widget.openAdd) {
          openAddSheet();
        } else {
          final m = FamilyStore.I.byId(widget.openMemberId!);
          if (m != null) openMemberOrPending(m);
        }
      });
    }
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    return Scaffold(
      backgroundColor: V.bg,
      body: TapTracker(
        child: Stack(
          children: [
            const Positioned.fill(child: _FamBg()),
            Positioned.fill(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(16, mq.padding.top + 12, 16, mq.padding.bottom + 40),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    // هەر بەشێک خۆی گوێ لە گۆڕانکارییەکانی FamilyStore دەگرێت
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _TopBar(),
                        _Orbit(),
                        _Legend(),
                        _AlertsCard(),
                        _ChallengeCard(),
                        _MembersSection(),
                        _PrivacyCard(),
                      ],
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

/// پاشبنەما: ڕووناکی پەمەیی لە سەرەوە و شین لە لاوە
class _FamBg extends StatelessWidget {
  const _FamBg();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(child: ColoredBox(color: V.bg)),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0, -0.76),
                radius: 0.75,
                colors: [vk(0x24FF8FC8), vk(0x00FF8FC8)],
                stops: [0.0, 0.7],
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(-1, -0.2),
                radius: 0.7,
                colors: [vk(0x1F2FE6F3), vk(0x002FE6F3)],
                stops: [0.0, 0.7],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================
// سەرەوە
// ============================================================
class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) => _listen(_build);

  Widget _build(BuildContext context) {
    final s = FamilyStore.I;
    final cnt = '${s.members.length} ئەندام${s.pending.isNotEmpty ? ' · ${s.pending.length} چاوەڕوان' : ''}';
    return Row(
      children: [
        Semantics(
          button: true,
          label: 'گەڕانەوە',
          child: Press(
            onTap: () => Navigator.of(context).maybePop(),
            child: Container(
              width: 42,
              height: 42,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: V.surf,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: V.line),
              ),
              child: svgIcon('<path d="M9 6l6 6-6 6"/>', '#effeff', size: 20),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              VText('بازنەی خێزان و هاوڕێ',
                  maxLines: 1, overflow: TextOverflow.ellipsis, style: ku(20, w: FontWeight.w800, h: 1.4)),
              VText(cnt, style: ku(12, w: FontWeight.w600, c: V.mu)),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Press(
          onTap: openAddSheet,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              gradient: V.prime,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [BoxShadow(color: op(V.mint, 0.5), blurRadius: 22, spreadRadius: -12, offset: const Offset(0, 10))],
            ),
            child: VText('+ زیادکردن', style: ku(13, w: FontWeight.w800, c: V.ink)),
          ),
        ),
      ],
    );
  }
}

// ============================================================
// بازنەی خولاوە
// ============================================================
class _Orbit extends StatefulWidget {
  const _Orbit();

  @override
  State<_Orbit> createState() => _OrbitState();
}

class _OrbitState extends State<_Orbit> with TickerProviderStateMixin {
  late final AnimationController _ringA =
      AnimationController(vsync: this, duration: const Duration(seconds: 40))..repeat();
  late final AnimationController _ringB =
      AnimationController(vsync: this, duration: const Duration(seconds: 28))..repeat();
  late final AnimationController _dash =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..repeat();

  @override
  void dispose() {
    _ringA.dispose();
    _ringB.dispose();
    _dash.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _listen(_build);

  Widget _build(BuildContext context) {
    final st = FamilyStore.I;
    final all = <FMember>[...st.members, ...st.pending];
    final w = MediaQuery.of(context).size.width;
    final size = math.min(330.0, w * 0.88);
    final u = size / 100;
    final pts = <Offset>[];
    for (int i = 0; i < all.length; i++) {
      final a = rad(-90 + i * 360 / math.max(all.length, 1));
      pts.add(Offset(50 + 36 * math.cos(a), 50 + 36 * math.sin(a)));
    }
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 16),
      child: Center(
        child: SizedBox(
          width: size,
          height: size,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: Padding(
                  padding: EdgeInsets.all(size * 0.12),
                  child: RotationTransition(
                    turns: _ringA,
                    child: CustomPaint(painter: _DashedCircle(V.line2)),
                  ),
                ),
              ),
              Positioned.fill(
                child: Padding(
                  padding: EdgeInsets.all(size * 0.28),
                  child: Opacity(
                    opacity: 0.6,
                    child: RotationTransition(
                      turns: Tween<double>(begin: 0, end: -1).animate(_ringB),
                      child: CustomPaint(painter: _DashedCircle(V.line2)),
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: IgnorePointer(
                  child: AnimatedBuilder(
                    animation: _dash,
                    builder: (context, _) => CustomPaint(
                      painter: _LinesPainter(
                        pts: pts,
                        colors: [for (final m in all) m.pend ? op(FK.y, 0.14) : op(m.color, 0.35)],
                        t: _dash.value,
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(left: size / 2 - 46, top: size / 2 - 46, child: const _MeBubble()),
              for (int i = 0; i < all.length; i++)
                Positioned(
                  key: ValueKey<String>('orb-${all[i].id}'),
                  left: pts[i].dx * u - 37,
                  top: pts[i].dy * u - 37,
                  width: 74,
                  child: _PopIn(
                    delayMs: i * 80,
                    child: _OrbitMember(all[i]),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MeBubble extends StatelessWidget {
  const _MeBubble();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 92,
      height: 92,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: Alignment(-0.3, -0.4),
          radius: 0.9,
          colors: [Color(0xFF8FF3F9), Color(0xFF14B8D6), Color(0xFF0B5F73)],
          stops: [0.0, 0.6, 1.0],
        ),
        boxShadow: [
          BoxShadow(color: vk(0x262FE6F3), spreadRadius: 6),
          BoxShadow(color: vk(0x732FE6F3), blurRadius: 40),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          VText(FMe.letter, style: nu(26, c: V.ink, h: 1.0)),
          const SizedBox(height: 2),
          VText(FMe.name, style: ku(10, w: FontWeight.w800, c: V.ink, h: 1.3)),
        ],
      ),
    );
  }
}

class _OrbitMember extends StatelessWidget {
  const _OrbitMember(this.m);
  final FMember m;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: m.n,
      child: Press(
        onTap: () => openMemberOrPending(m),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            MemberAvatar(m),
            const SizedBox(height: 3),
            VText(m.n, maxLines: 1, softWrap: false, overflow: TextOverflow.visible, style: ku(11, w: FontWeight.w700, h: 1.4)),
            if (m.pend)
              VText('چاوەڕوانی ڕەزامەندی',
                  maxLines: 1, softWrap: false, overflow: TextOverflow.visible, style: ku(10, c: V.amber, h: 1.4))
            else
              VText('${fmtN(m.steps)} 👣', textDirection: TextDirection.ltr, style: nu(10, w: FontWeight.w400, c: V.mu, h: 1.4)),
          ],
        ),
      ),
    );
  }
}

/// دەرکەوتنی ئەندام بە جووڵەی "پۆپ"
class _PopIn extends StatefulWidget {
  const _PopIn({required this.child, this.delayMs = 0});
  final Widget child;
  final int delayMs;

  @override
  State<_PopIn> createState() => _PopInState();
}

class _PopInState extends State<_PopIn> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
  Timer? _t;

  @override
  void initState() {
    super.initState();
    _t = Timer(Duration(milliseconds: widget.delayMs), () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        final v = _popCurve.transform(_c.value);
        return Opacity(
          opacity: (_c.value * 1.6).clamp(0.0, 1.0).toDouble(),
          child: Transform.scale(scale: 0.4 + 0.6 * v, child: child),
        );
      },
      child: widget.child,
    );
  }
}

class _DashedCircle extends CustomPainter {
  const _DashedCircle(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2 - 0.75;
    if (r <= 0) return;
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = color;
    final n = math.max(12, (2 * math.pi * r / 9).floor());
    final step = 2 * math.pi / n;
    final rect = Rect.fromCircle(center: c, radius: r);
    for (int i = 0; i < n; i++) {
      canvas.drawArc(rect, i * step, step * 0.5, false, p);
    }
  }

  @override
  bool shouldRepaint(covariant _DashedCircle old) => old.color != color;
}

/// هێڵە خاڵ خاڵە جووڵاوەکان لە ناوەڕاستەوە بۆ هەر ئەندامێک
class _LinesPainter extends CustomPainter {
  _LinesPainter({required this.pts, required this.colors, required this.t});
  final List<Offset> pts;
  final List<Color> colors;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final u = size.width / 100;
    final c = Offset(50 * u, 50 * u);
    final on = 1.5 * u;
    final period = 3 * u;
    final shift = (6 * u * t) % period;
    for (int i = 0; i < pts.length; i++) {
      final p = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1.0, 0.4 * u)
        ..color = colors[i];
      final b = pts[i] * u;
      final d = b - c;
      final len = d.distance;
      if (len <= 0) continue;
      final dir = d / len;
      for (double x = shift - period; x < len; x += period) {
        final s0 = math.max(0.0, x);
        final s1 = math.min(len, x + on);
        if (s1 > s0) canvas.drawLine(c + dir * s0, c + dir * s1, p);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _LinesPainter old) => true;
}

// ============================================================
// ڕێبەری ڕەنگەکان
// ============================================================
class _Legend extends StatelessWidget {
  const _Legend();

  Widget _i(Color k, String t) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: k, shape: BoxShape.circle)),
          const SizedBox(width: 5),
          VText(t, style: ku(11, w: FontWeight.w700, c: V.mu)),
        ],
      );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 14,
        runSpacing: 6,
        children: [_i(FK.g, 'باشە'), _i(FK.y, 'ئاگاداربە'), _i(FK.r, 'پێویستی بە سەرنجە')],
      ),
    );
  }
}

// ============================================================
// ئاگادارکردنەوەکان
// ============================================================
class _AlertsCard extends StatelessWidget {
  const _AlertsCard();

  @override
  Widget build(BuildContext context) => _listen(_build);

  Widget _build(BuildContext context) {
    final a = FamilyStore.I.alerts();
    return FCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FTitle('🔔 ئاگادارکردنەوەکان', '${a.length} نوێ', bottom: 4),
          if (a.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: VText('هەموو کەس باشن 💚', style: ku(12, c: V.mu, h: 1.8)),
            )
          else
            for (final x in a) AlertRow(x),
        ],
      ),
    );
  }
}

/// دێڕی ئاگادارکردنەوە (لە پەڕەکە و کارتی سەرەکیش بەکاردێت)
class AlertRow extends StatelessWidget {
  const AlertRow(this.a, {super.key, this.top = 8});
  final FAlert a;
  final double top;

  @override
  Widget build(BuildContext context) {
    final k = FK.of(a.kind);
    return Container(
      margin: EdgeInsets.only(top: top),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: op(k, 0.09),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: op(k, 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          VText(a.emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                VText.rich(
                  TextSpan(children: [
                    TextSpan(text: a.m.n, style: ku(13, w: FontWeight.w800, h: 1.75)),
                    TextSpan(text: a.text),
                  ]),
                  style: ku(13, h: 1.75),
                ),
                VText(a.sub, style: ku(11, c: V.mu, h: 1.6)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SmallBtn(actionLabel(a.action), onTap: () => memberAction(a.action, a.m)),
        ],
      ),
    );
  }
}

// ============================================================
// چالێنجی هەفتانە
// ============================================================
class _ChallengeCard extends StatelessWidget {
  const _ChallengeCard();

  @override
  Widget build(BuildContext context) => _listen(_build);

  Widget _build(BuildContext context) {
    final ppl = FamilyStore.I.players();
    final tot = ppl.fold<double>(0, (a, p) => a + p.steps);
    final sorted = [...ppl]..sort((a, b) => b.steps.compareTo(a.steps));
    final d = challengeDaysLeft();
    const medals = ['🥇', '🥈', '🥉'];
    return FCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FTitle('🏆 چالێنجی هەفتانەی خێزان', d == 0 ? 'ئەمڕۆ کۆتایی دێت' : '$d ڕۆژی ماوە'),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: tot),
                duration: const Duration(milliseconds: 1400),
                curve: Curves.easeOutCubic,
                builder: (context, v, _) => VText(fmtN(v), textDirection: TextDirection.ltr, style: nu(30, h: 1.2)),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: VText.rich(
                  TextSpan(children: [
                    const TextSpan(text: 'لە '),
                    TextSpan(text: ltr(fmtN(kChallengeGoal)), style: nu(13, w: FontWeight.w600, c: V.mu)),
                    const TextSpan(text: ' هەنگاو پێکەوە'),
                  ]),
                  style: ku(13, c: V.mu),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _StackBar(ppl),
          const SizedBox(height: 12),
          for (int i = 0; i < sorted.length; i++)
            Container(
              margin: EdgeInsets.only(top: i == 0 ? 0 : 6),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(color: V.surf2, borderRadius: BorderRadius.circular(14)),
              child: Row(
                children: [
                  SizedBox(
                    width: 24,
                    child: Center(
                      child: i < 3
                          ? VText(medals[i], style: const TextStyle(fontSize: 16))
                          : VText('${i + 1}', style: nu(13, w: FontWeight.w600, c: V.mu)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(color: sorted[i].color, borderRadius: BorderRadius.circular(3)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: VText(sorted[i].n,
                        maxLines: 1, overflow: TextOverflow.ellipsis, style: ku(13, w: FontWeight.w700)),
                  ),
                  VText(fmtN(sorted[i].steps), textDirection: TextDirection.ltr, style: nu(15)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _StackBar extends StatelessWidget {
  const _StackBar(this.ppl);
  final List<FPlayer> ppl;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(99),
      child: Container(
        height: 16,
        color: V.track,
        child: LayoutBuilder(
          builder: (context, c) => TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: 1),
            duration: const Duration(milliseconds: 1400),
            curve: _ease,
            builder: (context, v, _) {
              double left = 1;
              final parts = <Widget>[];
              for (final p in ppl) {
                final f = math.min(left, p.steps / kChallengeGoal);
                if (f <= 0) break;
                left -= f;
                // بە 0.01 بۆ خوارەوە، بۆ ئەوەی کۆی پانییەکان هەرگیز لە هێڵەکە تێنەپەڕێت
                final w = (c.maxWidth * f * v * 100).floorToDouble() / 100;
                parts.add(SizedBox(width: w, height: 16, child: ColoredBox(color: p.color)));
              }
              return Directionality(
                textDirection: TextDirection.ltr,
                child: Row(children: parts),
              );
            },
          ),
        ),
      ),
    );
  }
}

// ============================================================
// ئەندامەکان
// ============================================================
class _MembersSection extends StatelessWidget {
  const _MembersSection();

  @override
  Widget build(BuildContext context) => _listen(_build);

  Widget _build(BuildContext context) {
    final s = FamilyStore.I;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 20, 4, 0),
          child: Row(
            children: [
              Expanded(child: VText('👥 ئەندامەکان', style: ku(16, w: FontWeight.w800))),
              VText('پەنجە بنێ بۆ وردەکاری', style: ku(12, c: V.mu)),
            ],
          ),
        ),
        for (final m in s.members) _MemberCard(m, key: ValueKey<String>('mc-${m.id}')),
        for (final p in s.pending) _PendingCard(p, key: ValueKey<String>('pc-${p.id}')),
        if (s.members.isEmpty && s.pending.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Press(
              onTap: openAddSheet,
              child: CustomPaint(
                foregroundPainter: DashedRRect(radius: 22),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(color: V.surf2, borderRadius: BorderRadius.circular(22)),
                  child: Column(
                    children: [
                      const VText('👨‍👩‍👧', style: TextStyle(fontSize: 30)),
                      const SizedBox(height: 6),
                      VText('هێشتا کەست زیاد نەکردووە', style: ku(14, w: FontWeight.w800)),
                      VText('+ یەکەم کەس زیاد بکە', style: ku(12, w: FontWeight.w700, c: V.cy)),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _MemberCard extends StatelessWidget {
  const _MemberCard(this.m, {super.key});
  final FMember m;

  Widget _stat(String t, {Color? c}) => VText(t, textDirection: TextDirection.ltr, style: nu(12, w: FontWeight.w700, c: c ?? V.tx));

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Press(
        onTap: () => openMemberSheet(m),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: V.surf,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: V.line),
          ),
          child: Row(
            children: [
              MemberAvatar(m),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    VText.rich(
                      TextSpan(children: [
                        TextSpan(text: m.n, style: ku(15, w: FontWeight.w700)),
                        TextSpan(text: ' · ${m.rel}', style: ku(11, c: V.mu)),
                      ]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    VText.rich(
                      TextSpan(children: [
                        TextSpan(text: '${FK.dot(m.st)} ${m.note} · '),
                        TextSpan(text: ltr('${m.sync}'), style: nu(11, w: FontWeight.w600, c: V.mu)),
                        const TextSpan(text: ' خولەک لەمەوبەر'),
                      ]),
                      style: ku(11, c: V.mu, h: 1.6),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 10,
                      runSpacing: 4,
                      children: [
                        _stat('❤️ ${m.hr}'),
                        _stat('👣 ${fmtN(m.steps)}'),
                        _stat('🌙 ${fmtSleep(m.sleep)}h'),
                        _stat('🫁 ${m.spo2}%', c: m.spo2 < 93 ? FK.r : null),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Semantics(
                button: true,
                label: 'هاندان',
                child: Press(
                  onTap: () => memberAction('cheer', m),
                  child: Container(
                    width: 42,
                    height: 42,
                    alignment: Alignment.center,
                    decoration: box(r: 14),
                    child: const VText('👏', style: TextStyle(fontSize: 20)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PendingCard extends StatelessWidget {
  const _PendingCard(this.p, {super.key});
  final FMember p;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Press(
        onTap: () => openPendingSheet(p),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: V.surf,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: V.line),
          ),
          child: Row(
            children: [
              const PendingAvatar(),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    VText.rich(
                      TextSpan(children: [
                        TextSpan(text: p.n, style: ku(15, w: FontWeight.w700)),
                        TextSpan(text: ' · ${p.rel}', style: ku(11, c: V.mu)),
                      ]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    VText('بانگهێشت نێردرا · چاوەڕوانی ڕەزامەندی', style: ku(11, c: V.amber, h: 1.6)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// چی هاوبەش دەکەم
// ============================================================
class _PrivacyCard extends StatelessWidget {
  const _PrivacyCard();

  @override
  Widget build(BuildContext context) => _listen(_build);

  Widget _build(BuildContext context) {
    final s = FamilyStore.I;
    return FCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FTitle('🔒 چی هاوبەش دەکەم', 'تەنها بۆ بازنەکەت', bottom: 0),
          for (int i = 0; i < kShares.length; i++)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                border: i == 0 ? null : Border(top: BorderSide(color: V.line)),
              ),
              child: Row(
                children: [
                  VText(kShares[i].emoji, style: const TextStyle(fontSize: 18)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        VText(kShares[i].label, style: ku(14, w: FontWeight.w700)),
                        if (kShares[i].sub != null)
                          VText(kShares[i].sub!, style: ku(11, w: FontWeight.w600, c: V.mu)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  VSwitch(
                    on: s.share[kShares[i].key] ?? false,
                    label: kShares[i].label,
                    onTap: () {
                      final k = kShares[i].key;
                      FamilyStore.I.toggleShare(k);
                      toast((FamilyStore.I.share[k] ?? false) ? '✓ هاوبەش دەکرێت' : '🔒 شاردرایەوە');
                    },
                  ),
                ],
              ),
            ),
          const SizedBox(height: 10),
          VText(
            'هەر کەسێک خۆی هەڵدەبژێرێت چی هاوبەش بکات، و هەر کاتێک بیەوێت دەتوانێت بیگۆڕێت یان لە بازنەکە بچێتە دەرەوە.',
            style: ku(12, c: V.mu, h: 1.8),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// شیتەکان
// ============================================================
void openMemberOrPending(FMember m) => m.pend ? openPendingSheet(m) : openMemberSheet(m);

void openMemberSheet(FMember m) {
  showVSheet<void>(builder: (_) => TapTracker(child: _MemberSheet(m)));
}

void openPendingSheet(FMember p) {
  showVSheet<void>(builder: (_) => TapTracker(child: _PendingSheet(p)));
}

void openAddSheet() {
  if (FamilyStore.I.full) {
    toast('بازنەکەت پڕە (تا $kMaxCircle کەس). سەرەتا کەسێک لابەرە.');
    return;
  }
  showVSheet<void>(builder: (_) => const TapTracker(child: _AddSheet()));
}

Widget _lbl(String t) => Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: VText(t, style: ku(12, w: FontWeight.w800, c: V.mu)),
    );

Widget _sheetTitle(String t) => Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: VText(t, textAlign: TextAlign.center, style: ku(19, w: FontWeight.w800, h: 1.5)),
    );

Widget _sheetSub(String t) => Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: VText(t, textAlign: TextAlign.center, style: ku(13, c: V.mu, h: 1.7)),
    );

/// دوگمەی پانی تەواو (سەرەکی / نەرم / سوور)
class _WideBtn extends StatelessWidget {
  const _WideBtn(this.label, {required this.onTap, this.prime = false, this.danger = false});
  final String label;
  final VoidCallback onTap;
  final bool prime;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    return Press(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        alignment: Alignment.center,
        decoration: prime
            ? BoxDecoration(gradient: V.prime, borderRadius: BorderRadius.circular(15))
            : BoxDecoration(color: V.surf2, borderRadius: BorderRadius.circular(15), border: Border.all(color: V.line)),
        child: VText(
          label,
          textAlign: TextAlign.center,
          style: ku(14, w: FontWeight.w800, c: prime ? V.ink : danger ? V.coral : V.tx),
        ),
      ),
    );
  }
}

// ---------- وردەکاری ئەندام ----------
class _MemberSheet extends StatefulWidget {
  const _MemberSheet(this.m);
  final FMember m;

  @override
  State<_MemberSheet> createState() => _MemberSheetState();
}

class _MemberSheetState extends State<_MemberSheet> {
  bool _confirm = false;
  Timer? _t;

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  void _remove() {
    final m = widget.m;
    if (!_confirm) {
      setState(() => _confirm = true);
      _t?.cancel();
      _t = Timer(const Duration(milliseconds: 3000), () {
        if (mounted) setState(() => _confirm = false);
      });
      return;
    }
    FamilyStore.I.remove(m.id);
    Navigator.of(context).pop();
    toast('${m.n} لابرا');
  }

  Widget _vit(String label, String value, String unit, String em, Color k) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: box(r: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          VText(label, style: ku(12, w: FontWeight.w700, c: V.mu)),
          const SizedBox(height: 2),
          VText.rich(
            TextSpan(children: [
              TextSpan(text: value, style: nu(22)),
              if (unit.isNotEmpty) TextSpan(text: ' $unit', style: nu(12, w: FontWeight.w600, c: V.mu)),
            ]),
            textDirection: TextDirection.ltr,
          ),
          const SizedBox(height: 2),
          VText(em, style: ku(11, w: FontWeight.w800, c: k)),
        ],
      ),
    );
  }

  Widget _act(String e, String t, String a) => Expanded(
        child: Press(
          onTap: () => memberAction(a, widget.m),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 12),
            decoration: box(r: 16),
            child: Column(
              children: [
                VText(e, style: const TextStyle(fontSize: 22)),
                const SizedBox(height: 4),
                VText(t, style: ku(11, w: FontWeight.w700)),
              ],
            ),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final m = widget.m;
    final hrOk = m.hr >= 50 && m.hr <= 100;
    final pct = m.goal > 0 ? (m.steps / m.goal * 100).round() : 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(child: MemberAvatar(m, size: 84)),
        const SizedBox(height: 12),
        VText.rich(
          TextSpan(children: [
            TextSpan(text: m.full, style: ku(19, w: FontWeight.w800)),
            TextSpan(text: ' · ${m.rel}', style: ku(12, c: V.mu)),
          ]),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        VText.rich(
          TextSpan(children: [
            TextSpan(text: '${FK.dot(m.st)} ${m.note} · 🔋 '),
            TextSpan(text: ltr('${m.bat}%'), style: nu(13, w: FontWeight.w600, c: m.bat < 20 ? V.amber : V.mu)),
            const TextSpan(text: ' · '),
            TextSpan(text: ltr('${m.sync}'), style: nu(13, w: FontWeight.w600, c: V.mu)),
            const TextSpan(text: ' خولەک لەمەوبەر'),
          ]),
          textAlign: TextAlign.center,
          style: ku(13, c: V.mu, h: 1.7),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _vit('❤️ لێدانی دڵ', '${m.hr}', 'BPM', hrOk ? 'ئاسایی' : 'پێویستی بە سەرنجە', hrOk ? FK.g : FK.r)),
            const SizedBox(width: 8),
            Expanded(
              child: _vit('👣 هەنگاو', fmtN(m.steps), '', '$pct% لە ئامانج', m.steps >= m.goal ? FK.g : FK.y),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _vit('🌙 خەو', '${fmtSleep(m.sleep)}h', '', m.sleep >= 7 ? 'باش' : 'کەمێک کەم', m.sleep >= 7 ? FK.g : FK.y),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _vit('🫁 SpO₂', '${m.spo2}%', '', m.spo2 < 93 ? 'پێویستی بە سەرنجە' : 'ئاسایی', m.spo2 < 93 ? FK.r : FK.g),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _act('👏', 'هاندان', 'cheer'),
            const SizedBox(width: 8),
            _act('💧', 'ئاو', 'water'),
            const SizedBox(width: 8),
            _act('💊', 'دەرمان', 'med'),
            const SizedBox(width: 8),
            _act('📞', 'پەیوەندی', 'call'),
          ],
        ),
        const SizedBox(height: 12),
        VText(
          'تەنها ئەو داتایانە دەبینیت کە ${m.n} هاوبەشی کردوون.',
          textAlign: TextAlign.center,
          style: ku(12, c: V.mu, h: 1.8),
        ),
        const SizedBox(height: 6),
        _WideBtn(_confirm ? 'دڵنیایت؟ دووبارە دایبگرە بۆ لابردن' : 'لابردن لە بازنە', danger: true, onTap: _remove),
      ],
    );
  }
}

// ---------- بانگهێشتی چاوەڕوان ----------
class _PendingSheet extends StatelessWidget {
  const _PendingSheet(this.p);
  final FMember p;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _sheetTitle('⏳ ${p.n}'),
        _sheetSub('بانگهێشتەکە نێردراوە. کاتێک ${p.n} ئەپی VEX دابەزێنێت و قبوڵی بکات، لێرە دەردەکەوێت.'),
        InviteCodeBox(code: p.code.isEmpty ? 'VX-0000' : p.code, caption: 'کۆدی بانگهێشت'),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _WideBtn('📤 دووبارە ناردن', onTap: () => shareInvite('wa', p.code, again: true)),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _WideBtn('✓ قبوڵ کرا (دیمۆ)', prime: true, onTap: () {
                final m = FamilyStore.I.accept(p.id);
                Navigator.of(context).pop();
                burst(const ['🎉', '💚', '✨'], center: true);
                toast('🎉 ${m.n} هاتە ناو بازنەکەت!');
              }),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _WideBtn('هەڵوەشاندنەوە', danger: true, onTap: () {
          FamilyStore.I.cancelInvite(p.id);
          Navigator.of(context).pop();
          toast('بانگهێشتەکەی ${p.n} هەڵوەشێنرایەوە');
        }),
      ],
    );
  }
}

// ---------- زیادکردنی کەس ----------
class _AddSheet extends StatefulWidget {
  const _AddSheet();

  @override
  State<_AddSheet> createState() => _AddSheetState();
}

class _AddSheetState extends State<_AddSheet> {
  final TextEditingController _name = TextEditingController();
  final FocusNode _focus = FocusNode();
  final String _code = newInviteCode();
  String _rel = '';
  String _emoji = '🙂';

  @override
  void dispose() {
    _name.dispose();
    _focus.dispose();
    super.dispose();
  }

  String get _hint {
    if (_rel.isEmpty) return 'بۆ نموونە: دایکم';
    return relDefaultName(_rel) ?? 'ناوی بنووسە';
  }

  void _send() {
    if (_rel.isEmpty) {
      toast('پەیوەندیتان هەڵبژێرە');
      return;
    }
    final typed = _name.text.trim();
    final name = typed.isNotEmpty ? typed : relDefaultName(_rel);
    if (name == null) {
      toast('ناوەکەی بنووسە');
      _focus.requestFocus();
      return;
    }
    if (FamilyStore.I.full) {
      toast('بازنەکەت پڕە (تا $kMaxCircle کەس)');
      return;
    }
    final n = name.length > 20 ? name.substring(0, 20) : name;
    FamilyStore.I.invite(name: n, rel: _rel, emoji: _emoji, code: _code);
    Navigator.of(context).pop();
    toast('📤 بانگهێشت نێردرا بۆ $n');
  }

  Widget _chip(List<String> r) {
    final on = _rel == r[0];
    return Press(
      onTap: () => setState(() {
        _rel = r[0];
        _emoji = r[1];
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: on ? op(V.mint, 0.14) : V.surf2,
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: on ? op(V.mint, 0.55) : V.line),
        ),
        child: VText('${r[1]} ${r[0]}', style: ku(13, w: FontWeight.w700, c: on ? V.mint : V.tx)),
      ),
    );
  }

  Widget _share(String e, String t, String via) => Expanded(
        child: Press(
          onTap: () => shareInvite(via, _code),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
            decoration: box(r: 16),
            child: Column(
              children: [
                VText(e, style: const TextStyle(fontSize: 22)),
                const SizedBox(height: 4),
                VText(t, maxLines: 1, overflow: TextOverflow.ellipsis, style: ku(12, w: FontWeight.w700)),
              ],
            ),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: V.line2),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _sheetTitle('➕ زیادکردنی کەس'),
        _sheetSub('پێکەوە ئاگاتان لە تەندروستی یەکتر دەبێت'),
        _lbl('پەیوەندیتان چییە؟'),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 7,
          runSpacing: 7,
          children: [for (final r in kRelations) _chip(r)],
        ),
        _lbl('ناوی'),
        TextField(
          controller: _name,
          focusNode: _focus,
          maxLength: 20,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _focus.unfocus(),
          style: ku(15),
          cursorColor: V.cy,
          decoration: InputDecoration(
            hintText: vxTr(_hint),
            hintStyle: ku(15, c: op(V.mu, 0.7)),
            counterText: '',
            filled: true,
            fillColor: V.surf2,
            isDense: true,
            contentPadding: const EdgeInsets.all(13),
            border: border,
            enabledBorder: border,
            focusedBorder: border.copyWith(borderSide: BorderSide(color: V.cy)),
          ),
        ),
        _lbl('بانگهێشتی بکە'),
        InviteCodeBox(code: _code, caption: 'با ئەم QR ـە سکان بکات، یان کۆدەکە بنووسێت'),
        const SizedBox(height: 10),
        Row(
          children: [
            _share('💬', 'WhatsApp', 'wa'),
            const SizedBox(width: 8),
            _share('📱', 'Viber / SMS', 'vb'),
            const SizedBox(width: 8),
            _share('📋', 'کۆپی لینک', 'cp'),
          ],
        ),
        const SizedBox(height: 12),
        VText.rich(
          TextSpan(children: [
            const TextSpan(text: '🔒 کەسەکە دەبێت بانگهێشتەکە '),
            TextSpan(text: 'قبوڵ بکات', style: ku(12, w: FontWeight.w800, c: V.tx, h: 1.8)),
            const TextSpan(text: ' و خۆی هەڵبژێرێت چی هاوبەش بکات. هیچ داتایەک بێ ڕەزامەندی نابینرێت.'),
          ]),
          style: ku(12, c: V.mu, h: 1.8),
        ),
        const SizedBox(height: 6),
        _WideBtn('📤 ناردنی بانگهێشت', prime: true, onTap: _send),
      ],
    );
  }
}

// ============================================================
// ناردنی بانگهێشت (WhatsApp / Viber / SMS / کۆپی)
// ============================================================
Future<bool> _open(String url) async {
  try {
    return await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  } catch (_) {
    return false;
  }
}

Future<void> shareInvite(String via, String code, {bool again = false}) async {
  final link = 'https://vex.app/join/$code';
  final msg = vxTr('وەرە ناو بازنەی تەندروستیم لە VEX 💚\nکۆدی بانگهێشت: $code\n$link');
  if (via == 'cp') {
    await Clipboard.setData(ClipboardData(text: link));
    toast('📋 لینک کۆپی کرا');
    return;
  }
  final text = Uri.encodeComponent(msg);
  bool ok;
  if (via == 'wa') {
    ok = await _open('https://wa.me/?text=$text');
  } else {
    ok = await _open('viber://forward?text=$text');
    if (!ok) ok = await _open('sms:?body=$text');
  }
  if (ok) {
    if (again) toast('📤 بانگهێشت دووبارە نێردرا');
    return;
  }
  await Clipboard.setData(ClipboardData(text: msg));
  toast('📋 نامەی بانگهێشت کۆپی کرا، لە هەر ئەپێکدا دایبنێ');
}
