// VEX Health — کارتی "کورتەی ئەمڕۆ" (AI)
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../band/band_state.dart';
import '../core/ai_service.dart';
import '../core/icons.dart';
import '../core/theme.dart';
import 'hc.dart';

class _M {
  const _M(this.icon, this.v, this.label, this.k, this.hex, this.w);
  final String icon;
  final String v;
  final String label;
  final Color k;
  final String hex;
  final double w;
}

const List<String> _steps = [
  'خوێندنەوەی لێدانی دڵ و HRV',
  'شیکردنەوەی سترێس و ئۆکسجین',
  'بەراوردی چالاکی لەگەڵ ئامانجەکەت',
  'دروستکردنی پلانی ئێستات',
];

enum _Stage { idle, scan, done }

class AiBriefCard extends StatefulWidget {
  const AiBriefCard({super.key});

  @override
  State<AiBriefCard> createState() => _AiBriefCardState();
}

class _AiBriefCardState extends State<AiBriefCard> with TickerProviderStateMixin {
  late final AnimationController rot =
      AnimationController(vsync: this, duration: const Duration(seconds: 16))..repeat();
  late final AnimationController pulse =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 2600))..repeat();
  late final AnimationController tw =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat(reverse: true);
  late final AnimationController shine =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 3200))..repeat();
  late final AnimationController beam = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100));
  late final AnimationController spin = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
  late final AnimationController res = AnimationController(vsync: this, duration: const Duration(milliseconds: 1300));

  final GlobalKey _cardKey = GlobalKey();
  _Stage stage = _Stage.idle;
  int step = 0;
  bool busy = false;
  HealthBrief brief = kDemoBrief;
  final Set<int> doneActs = <int>{};

  List<_M> get metrics => [
    _M(HI.step, '2,416', 'هەنگاو', vk(0xFF2FE6F3), '#2fe6f3', 24),
    _M(HI.fire, '70', 'kcal', vk(0xFFFF9A52), '#ff9a52', 23),
    _M(HI.heart, '68', 'bpm', vk(0xFFFF3D5E), '#ff3d5e', 80),
    _M(HI.wave, '48', 'HRV ms', vk(0xFF9D86FF), '#9d86ff', 62),
  ];

  @override
  void dispose() {
    rot.dispose();
    pulse.dispose();
    tw.dispose();
    shine.dispose();
    beam.dispose();
    spin.dispose();
    res.dispose();
    super.dispose();
  }

  String _greet() {
    final h = DateTime.now().hour;
    final g = h < 5
        ? 'شەوت باش'
        : h < 12
            ? 'بەیانیت باش'
            : h < 17
                ? 'ڕۆژت باش'
                : h < 21
                    ? 'ئێوارەت باش'
                    : 'شەوت باش';
    return '$g، ghazi 👋';
  }

  Future<void> _run() async {
    if (busy) return;
    // شیکاری AI لەسەر داتای Band دامەزراوە؛ بێ Band ژمارەی ساختە شیکار ناکرێت
    if (!BandState.I.connected) {
      toast('Band پەیوەست نییە. شیکاری پێویستی بە داتای Band هەیە.');
      return;
    }
    busy = true;
    setState(() {
      stage = _Stage.scan;
      step = 0;
      doneActs.clear();
    });
    beam.repeat();
    spin.repeat();
    // catchError: ئەگەر داواکاری سێرڤەر شکستی هێنا، هەڵەکە وەک "unhandled" ڕاپۆرت ناکرێت
    final ai = analyzeHealth().catchError((Object _) => kDemoBrief);
    for (int i = 0; i < _steps.length; i++) {
      if (!mounted) return;
      setState(() => step = i);
      await Future<void>.delayed(const Duration(milliseconds: 520));
    }
    if (!mounted) return;
    setState(() => step = _steps.length);
    HealthBrief r;
    try {
      r = await ai;
    } catch (_) {
      r = kDemoBrief;
    }
    if (!mounted) return;
    beam.stop();
    spin.stop();
    setState(() {
      brief = r;
      stage = _Stage.done;
    });
    res.forward(from: 0);
    busy = false;
    await Future<void>.delayed(const Duration(milliseconds: 200));
    final ctx = _cardKey.currentContext;
    if (mounted && ctx != null) {
      Scrollable.ensureVisible(ctx, duration: const Duration(milliseconds: 500), curve: Curves.easeOutCubic);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      key: _cardKey,
      margin: const EdgeInsets.only(top: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: vk(0x529D86FF)),
        boxShadow: [
          BoxShadow(color: vk(0xE67A4FF0), blurRadius: 44, offset: Offset(0, 22), spreadRadius: -26),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment(-0.34, -1),
                    end: Alignment(0.34, 1),
                    colors: [vk(0xFF0D3340), vk(0xFF082731)],
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.topRight,
                    radius: 1.1,
                    colors: [vk(0x807A4FF0), vk(0x007A4FF0)],
                    stops: [0.0, 0.58],
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.bottomLeft,
                    radius: 0.9,
                    colors: [vk(0x382FE6F3), vk(0x002FE6F3)],
                    stops: [0.0, 0.6],
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: OverflowBox(
                // minWidth/minHeight: 0 — ئەگەر کارتەکە لە 900 بەرزتر بوو (فۆنتی گەورە) هەڵە ڕوونادات
                minWidth: 0,
                minHeight: 0,
                maxWidth: 900,
                maxHeight: 900,
                child: RotationTransition(
                  turns: rot,
                  child: SizedBox(
                    width: 900,
                    height: 900,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: SweepGradient(
                          colors: [
                            vk(0x009D86FF),
                            vk(0x299D86FF),
                            vk(0x009D86FF),
                            vk(0x1F2FE6F3),
                            vk(0x002FE6F3),
                            vk(0x002FE6F3),
                          ],
                          stops: [0.0, 0.125, 0.25, 0.4, 0.55, 1.0],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: AnimatedSize(
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeOutCubic,
                alignment: Alignment.topCenter,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _header(),
                    const SizedBox(height: 12),
                    _metricsRow(),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(2, 10, 2, 0),
                      child: AnimatedOpacity(
                        opacity: stage == _Stage.scan ? 0.5 : 1.0,
                        duration: const Duration(milliseconds: 300),
                        child: VText.rich(
                          TextSpan(children: [
                            const TextSpan(text: 'ڕۆژێکی '),
                            TextSpan(text: 'ئارامە', style: ku(12.5, w: FontWeight.w800, c: kW, h: 1.75)),
                            const TextSpan(text: ': دڵ و ئۆکسجینت ئاسایین، بەڵام '),
                            TextSpan(text: 'جووڵەت کەمە', style: ku(12.5, w: FontWeight.w800, c: kW, h: 1.75)),
                            const TextSpan(text: '.'),
                          ]),
                          style: ku(12.5, c: vk(0xFFD6E3F0), h: 1.75),
                        ),
                      ),
                    ),
                    if (stage == _Stage.idle) _button(),
                    if (stage == _Stage.scan) _scanList(),
                    if (stage == _Stage.done) ..._result(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---- سەرەوە ----
  Widget _header() {
    return Row(
      children: [
        SizedBox(
          width: 34,
          height: 34,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: -3,
                top: -3,
                right: -3,
                bottom: -3,
                child: AnimatedBuilder(
                  animation: pulse,
                  builder: (context, _) {
                    final v = Curves.easeOut.transform(pulse.value);
                    return Opacity(
                      opacity: 0.9 * (1 - v),
                      child: Transform.scale(
                        scale: 0.9 + 0.45 * v,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: vk(0x809D86FF), width: 1.5),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              Positioned.fill(
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [vk(0xFF8B6CFF), vk(0xFF2FE6F3)],
                    ),
                    boxShadow: [
                      BoxShadow(color: vk(0xFF8B6CFF), blurRadius: 22, offset: Offset(0, 8), spreadRadius: -8),
                    ],
                  ),
                  child: AnimatedBuilder(
                    animation: tw,
                    builder: (context, child) {
                      final v = Curves.easeInOut.transform(tw.value);
                      return Opacity(
                        opacity: 1 - 0.25 * v,
                        child: Transform.rotate(
                          angle: rad(15 * v),
                          child: Transform.scale(scale: 1 + 0.2 * v, child: child),
                        ),
                      );
                    },
                    child: svgIcon(HI.spark2, '#ffffff', size: 17, fill: true),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              VText(_greet(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: ku(11.5, w: FontWeight.w700, c: vk(0xFFB9C9F5))),
              VText('کورتەی ئەمڕۆ', style: ku(15.5, w: FontWeight.w800, c: kW)),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: vk(0x14FFFFFF),
            borderRadius: BorderRadius.circular(99),
            border: Border.all(color: vk(0x1FFFFFFF)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              BlinkDot(size: 6, color: vk(0xFF3CF08A), glow: true),
              const SizedBox(width: 6),
              VText('AI · ${nowHM()}', style: nu(11, w: FontWeight.w700, c: vk(0xFFD9E6FF))),
            ],
          ),
        ),
      ],
    );
  }

  // ---- چوار ژمارەکە ----
  Widget _metricsRow() {
    return Stack(
      children: [
        Row(
          children: [
            for (int i = 0; i < metrics.length; i++) ...[
              if (i > 0) const SizedBox(width: 6),
              Expanded(child: _metric(metrics[i])),
            ],
          ],
        ),
        if (stage == _Stage.scan)
          Positioned.fill(
            child: IgnorePointer(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: AnimatedBuilder(
                  animation: beam,
                  builder: (context, child) => FractionalTranslation(
                    translation: Offset(1.0 - 2.0 * beam.value, 0),
                    child: child,
                  ),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [vk(0x009D86FF), vk(0x009D86FF), vk(0x8CBEF0FF), vk(0x009D86FF), vk(0x009D86FF)],
                        stops: [0.0, 0.35, 0.5, 0.65, 1.0],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _metric(_M m) {
    return Container(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 7),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [op(m.k, 0.14), vk(0x08FFFFFF)],
        ),
        border: Border.all(color: op(m.k, 0.26)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 22,
            height: 22,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: op(m.k, 0.2), borderRadius: BorderRadius.circular(8)),
            child: svgIcon(m.icon, m.hex, size: 13, stroke: 2.2),
          ),
          const SizedBox(height: 4),
          VText(m.v, textDirection: TextDirection.ltr, style: nu(14, c: kW, h: 1.2)),
          VText(m.label,
              maxLines: 1,
              overflow: TextOverflow.clip,
              style: ku(9.5, w: FontWeight.w700, c: vk(0xFFA9C0C8), h: 1.4)),
          const SizedBox(height: 5),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: Container(
                height: 3,
                color: vk(0x14FFFFFF),
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: m.w / 100,
                  heightFactor: 1,
                  child: ColoredBox(color: m.k),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---- دوگمەی شیکاری ----
  Widget _button() {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Press(
        onTap: _run,
        scale: 0.98,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [vk(0xFF8B6CFF), vk(0xFF5B7BFF), vk(0xFF2FC8E8)],
              stops: [0.0, 0.5, 1.0],
            ),
            boxShadow: [
              BoxShadow(color: vk(0xFF8B6CFF), blurRadius: 26, offset: Offset(0, 12), spreadRadius: -12),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Stack(
              children: [
                Positioned.fill(
                  child: AnimatedBuilder(
                    animation: shine,
                    builder: (context, child) {
                      final v = shine.value;
                      final p = v < 0.55 ? Curves.easeInOut.transform(v / 0.55) : 1.0;
                      return FractionalTranslation(translation: Offset(-1.2 + 2.4 * p, 0), child: child);
                    },
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment(-1, -0.27),
                          end: Alignment(1, 0.27),
                          colors: [vk(0x00FFFFFF), vk(0x59FFFFFF), vk(0x00FFFFFF)],
                          stops: [0.35, 0.5, 0.65],
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(11),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      svgIcon(HI.spark, '#ffffff', size: 18, fill: true),
                      const SizedBox(width: 8),
                      VText('شیکاری داتاکانم بکە', style: ku(14, w: FontWeight.w800, c: Colors.white)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---- هەنگاوەکانی شیکاری ----
  Widget _scanList() {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (int i = 0; i < _steps.length; i++)
            Padding(
              padding: EdgeInsets.only(top: i > 0 ? 6 : 0),
              child: AnimatedOpacity(
                opacity: i <= step ? 1.0 : 0.35,
                duration: const Duration(milliseconds: 300),
                child: Row(
                  children: [
                    _dotFor(i),
                    const SizedBox(width: 10),
                    Expanded(
                      child: VText(
                        _steps[i],
                        style: ku(
                          12.5,
                          w: FontWeight.w700,
                          c: i == step
                              ? kW
                              : (i < step ? vk(0xFFCFE6EC) : vk(0xFFB9C9D4)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _dotFor(int i) {
    if (i < step) {
      return Container(
        width: 18,
        height: 18,
        alignment: Alignment.center,
        decoration: BoxDecoration(shape: BoxShape.circle, color: vk(0xFF3CF08A)),
        child: VText('✓', style: ku(10, w: FontWeight.w900, c: HC.ink, h: 1.0)),
      );
    }
    if (i == step) {
      return RotationTransition(
        turns: spin,
        child: const SizedBox(width: 18, height: 18, child: CustomPaint(painter: _SpinArc())),
      );
    }
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: vk(0x33FFFFFF), width: 2),
      ),
    );
  }

  // ---- ئەنجام ----
  Widget _fade(int i, Widget child) {
    return AnimatedBuilder(
      animation: res,
      builder: (context, c) {
        final t = clampD((res.value * 1.3 - i * 0.12) / 0.55, 0, 1);
        final e = const Cubic(0.2, 0.9, 0.3, 1.0).transform(t);
        return Opacity(opacity: e, child: Transform.translate(offset: Offset(0, 10 * (1 - e)), child: c));
      },
      child: child,
    );
  }

  Widget _insight(int i, String emoji, String title, String body, Color k) {
    return _fade(
      i,
      Container(
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [op(k, 0.12), vk(0x08FFFFFF)],
          ),
          border: Border.all(color: op(k, 0.28)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: op(k, 0.2), borderRadius: BorderRadius.circular(9)),
              child: VText(emoji, style: const TextStyle(fontSize: 13)),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  VText(title, style: ku(12, w: FontWeight.w800, c: k)),
                  const SizedBox(height: 2),
                  VText(body, style: ku(12.5, c: vk(0xFFE8F3F6), h: 1.7)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _result() {
    final b = brief;
    return [
      const SizedBox(height: 10),
      _fade(
        0,
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: vk(0x0DFFFFFF),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: vk(0x1AFFFFFF)),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 52,
                height: 52,
                child: AnimatedBuilder(
                  animation: res,
                  builder: (context, _) {
                    final t = const Cubic(0.2, 0.9, 0.2, 1.0).transform(clampD(res.value * 1.3 / 1.1, 0, 1));
                    return CustomPaint(
                      painter: _ScoreRing(b.score / 100 * t),
                      child: Center(
                        child: VText('${b.score}', textDirection: TextDirection.ltr, style: nu(14, c: kW)),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    VText(b.verdict, style: ku(14.5, w: FontWeight.w800, c: kW)),
                    const SizedBox(height: 2),
                    VText.rich(
                      TextSpan(children: [
                        const TextSpan(text: 'نمرەی ئامادەیی ئەمڕۆ لە 100 · '),
                        TextSpan(
                          text: '▲ 4 لە دوێنێ',
                          style: ku(11.5, w: FontWeight.w800, c: vk(0xFF3CF08A), h: 1.6),
                        ),
                      ]),
                      style: ku(11.5, c: vk(0xFFB3C6CF), h: 1.6),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      _insight(1, '✅', 'چی باشە', b.good, vk(0xFF3CF08A)),
      _insight(2, '⚠️', 'ئاگاداربە', b.watch, vk(0xFFFFBE4D)),
      _insight(3, '💡', 'پێشنیاری AI', b.tip, vk(0xFF2FE6F3)),
      _fade(
        4,
        Container(
          margin: const EdgeInsets.only(top: 8),
          child: CustomPaint(
            foregroundPainter: _DashedBorder(vk(0x669D86FF), 18),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: vk(0x0AFFFFFF), borderRadius: BorderRadius.circular(18)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  VText('✨ پلانی ئێستات · دەست لێدە کاتێک تەواوت کرد',
                      style: ku(12.5, w: FontWeight.w700, c: vk(0xFFD9D0FF))),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 7,
                    runSpacing: 7,
                    children: [
                      for (int i = 0; i < math.min(3, b.actions.length); i++) _act(i, b.actions[i]),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      _fade(
        5,
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 10, 4, 0),
          child: VText(
            'VEX AI · ئەمە ئامۆژگاریی پزیشکی نییە',
            textAlign: TextAlign.center,
            style: ku(10.5, c: vk(0xFF88A7B0)),
          ),
        ),
      ),
      _fade(
        5,
        Center(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _run,
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: VText('↻ دووبارە شیکاری بکە', style: ku(12, w: FontWeight.w700, c: vk(0xFFB9A8FF))),
            ),
          ),
        ),
      ),
    ];
  }

  Widget _act(int i, String text) {
    final done = doneActs.contains(i);
    final base = ku(12, w: FontWeight.w700, c: done ? vk(0xFFBFFFD9) : kW);
    return Press(
      onTap: () => setState(() {
        if (done) {
          doneActs.remove(i);
        } else {
          doneActs.add(i);
        }
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
        decoration: BoxDecoration(
          color: done ? vk(0x293CF08A) : vk(0x0FFFFFFF),
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: done ? vk(0xFF3CF08A) : vk(0x29FFFFFF)),
        ),
        child: VText(
          text,
          style: done
              ? base.copyWith(decoration: TextDecoration.lineThrough, decorationColor: vk(0xFFBFFFD9))
              : base,
        ),
      ),
    );
  }
}

class _SpinArc extends CustomPainter {
  const _SpinArc();

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = vk(0xFF8B6CFF);
    canvas.drawArc((Offset.zero & size).deflate(1), -math.pi / 4, math.pi * 1.5, false, p);
  }

  @override
  bool shouldRepaint(covariant _SpinArc oldDelegate) => false;
}

class _ScoreRing extends CustomPainter {
  _ScoreRing(this.f);
  final double f;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 64;
    final c = Offset(size.width / 2, size.height / 2);
    final r = 26 * s;
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6 * s
        ..color = vk(0x1AFFFFFF),
    );
    if (f <= 0.001) return;
    final rect = Rect.fromCircle(center: c, radius: r);
    canvas.drawArc(
      rect,
      -math.pi / 2,
      math.pi * 2 * f,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6 * s
        ..strokeCap = StrokeCap.round
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [vk(0xFF8B6CFF), vk(0xFF3CF08A)],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(covariant _ScoreRing oldDelegate) => oldDelegate.f != f;
}

class _DashedBorder extends CustomPainter {
  const _DashedBorder(this.color, this.radius);
  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final rr = RRect.fromRectAndRadius((Offset.zero & size).deflate(0.5), Radius.circular(radius));
    final path = Path()..addRRect(rr);
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = color;
    for (final m in path.computeMetrics()) {
      double d = 0;
      while (d < m.length) {
        canvas.drawPath(m.extractPath(d, math.min(m.length, d + 4)), p);
        d += 7;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorder oldDelegate) => false;
}
