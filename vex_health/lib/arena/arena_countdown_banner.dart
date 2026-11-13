// VEX Health — بانەری «VEX Arena دەستپێدەکات» (دیزاینی ٢ · ژمێرەری زیندوو)
//
// • ٧ ڕۆژ پێش دەستپێکردنی Arena لە شوێنی دۆخی Band (ماڵەوە) دەردەکەوێت.
// • ژمێرەرەکە چرکە بە چرکە دەڕوات: ڕۆژ : کاتژمێر : خولەک : چرکە.
// • پەنجە لێدان ← onTap (یەکسەر پەڕەی تۆمارکردن بۆ VEX Arena).
// • کاتێک کاتەکە تەواو دەبێت، بانەرەکە بە نەرمی لادەچێت و [fallback] (دۆخی Band) دەگەڕێتەوە.
//
// سەربەخۆیە: تەنها package:flutter/material.dart بەکاردەهێنێت.
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

/// ڕەنگەکانی بانەر (هەمان ڕەنگەکانی ماڵەوەی ئەپ)
class ArenaBannerColors {
  static const surface = Color(0xFF0F2E3A);
  static const line = Color(0xFF1D4552);
  static const cyan = Color(0xFF22E3EE);
  static const onCyan = Color(0xFF062A33);
  static const gold = Color(0xFFFFCF4A);
  static const goldLight = Color(0xFFFFE7A3);
  static const goldDeep = Color(0xFFF5A30B);
  static const mint = Color(0xFF3EE6A8);
  static const text = Color(0xFFF4F8F9);
  static const muted = Color(0xFF9FC1C9);
  static const unit = Color(0xFF93B4BD);
  static const colon = Color(0xFF3B6672);
}

/// ماوەی ماوە بۆ دەستپێکردن، دابەشکراو بۆ ڕۆژ / کاتژمێر / خولەک / چرکە
class ArenaTimeLeft {
  ArenaTimeLeft(Duration d)
      : total = d.isNegative ? Duration.zero : d,
        days = (d.isNegative ? 0 : d.inSeconds) ~/ 86400,
        hours = ((d.isNegative ? 0 : d.inSeconds) ~/ 3600) % 24,
        minutes = ((d.isNegative ? 0 : d.inSeconds) ~/ 60) % 60,
        seconds = (d.isNegative ? 0 : d.inSeconds) % 60;

  final Duration total;
  final int days, hours, minutes, seconds;

  static String two(int v) => v.toString().padLeft(2, '0');
}

/// شوێنی بانەر: لە ماوەی [showBefore] پێش [startsAt] بانەرەکە پیشان دەدات، دەنا [fallback].
class ArenaCountdownSlot extends StatefulWidget {
  const ArenaCountdownSlot({
    super.key,
    required this.startsAt,
    required this.onTap,
    required this.fallback,
    this.showBefore = const Duration(days: 7),
    this.margin = const EdgeInsets.only(top: 12),
    this.clock,
    this.onEnded,
  });

  /// کاتی دەستپێکردنی VEX Arena
  final DateTime startsAt;

  /// پەنجە لێدان ← پەڕەی تۆمارکردن
  final VoidCallback onTap;

  /// ئەوەی لە دەرەوەی ماوەکە پیشان دەدرێت (دۆخی Band)
  final Widget fallback;

  /// چەند پێش دەستپێکردن دەردەکەوێت (٧ ڕۆژ)
  final Duration showBefore;

  final EdgeInsetsGeometry margin;

  /// بۆ تاقیکردنەوە: کاتژمێری دەستکرد
  final DateTime Function()? clock;

  /// کاتێک ژمێرەرەکە دەگاتە سفر (یەک جار)
  final VoidCallback? onEnded;

  @override
  State<ArenaCountdownSlot> createState() => _ArenaCountdownSlotState();
}

class _ArenaCountdownSlotState extends State<ArenaCountdownSlot> {
  Timer? _timer;
  late DateTime _now = _clock();
  bool _endedFired = false;

  DateTime _clock() => (widget.clock ?? DateTime.now)();

  Duration get _left => widget.startsAt.difference(_now);
  bool get _active => _left > Duration.zero && _left <= widget.showBefore;

  @override
  void initState() {
    super.initState();
    _endedFired = _left <= Duration.zero;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  @override
  void didUpdateWidget(covariant ArenaCountdownSlot old) {
    super.didUpdateWidget(old);
    if (old.startsAt != widget.startsAt) {
      _now = _clock();
      _endedFired = _left <= Duration.zero;
    }
  }

  void _tick() {
    if (!mounted) return;
    setState(() => _now = _clock());
    if (!_endedFired && _left <= Duration.zero) {
      _endedFired = true;
      widget.onEnded?.call();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final active = _active;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 450),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, a) => FadeTransition(
        opacity: a,
        child: SizeTransition(sizeFactor: a, axisAlignment: -1, child: child),
      ),
      child: active
          ? Padding(
              key: const ValueKey('arena-banner'),
              padding: widget.margin,
              child: ArenaCountdownBanner(left: ArenaTimeLeft(_left), onTap: widget.onTap),
            )
          : KeyedSubtree(key: const ValueKey('arena-fallback'), child: widget.fallback),
    );
  }
}

/// بانەرەکە خۆی (٥٦ px)
class ArenaCountdownBanner extends StatefulWidget {
  const ArenaCountdownBanner({super.key, required this.left, required this.onTap});

  final ArenaTimeLeft left;
  final VoidCallback onTap;

  @override
  State<ArenaCountdownBanner> createState() => _ArenaCountdownBannerState();
}

class _ArenaCountdownBannerState extends State<ArenaCountdownBanner> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 3000))..repeat();
  bool _down = false;

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _setDown(bool v) {
    if (_down != v) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    final l = widget.left;
    final reduce = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final secGold = l.seconds.isEven;

    return Semantics(
      button: true,
      label: 'VEX Arena دەستپێدەکات لە ${l.days} ڕۆژ، ${l.hours} کاتژمێر، ${l.minutes} خولەک. بۆ تۆمارکردن دایبگرە',
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _setDown(true),
        onTapCancel: () => _setDown(false),
        onTapUp: (_) => _setDown(false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _down ? 0.97 : 1,
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          child: Container(
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: ArenaBannerColors.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: ArenaBannerColors.line),
            ),
            child: Row(
              children: [
                // کاسە (دەلەرێتەوە)
                AnimatedBuilder(
                  animation: _c,
                  builder: (_, child) => Transform.rotate(
                    angle: reduce ? 0 : math.sin(_c.value * 2 * math.pi) * 0.105,
                    alignment: const Alignment(0, 0.8),
                    child: child,
                  ),
                  child: ShaderMask(
                    blendMode: BlendMode.srcIn,
                    shaderCallback: (r) => const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFFFFF0A8), ArenaBannerColors.goldDeep],
                    ).createShader(r),
                    child: const Icon(Icons.emoji_events_rounded, size: 28, color: Colors.white),
                  ),
                ),
                const SizedBox(width: 10),
                // ناو + «دەستپێدەکات لە»
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'VEX Arena',
                      textDirection: TextDirection.ltr,
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 0.3, color: ArenaBannerColors.text, height: 1.3),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedBuilder(
                          animation: _c,
                          builder: (_, __) {
                            final t = reduce ? 0.0 : (math.sin(_c.value * 2 * math.pi * 2.5) + 1) / 2;
                            return Container(
                              width: 7,
                              height: 7,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: ArenaBannerColors.mint.withValues(alpha: 1 - 0.45 * t),
                                boxShadow: [BoxShadow(color: ArenaBannerColors.mint.withValues(alpha: 0.5 * (1 - t)), blurRadius: 6 * t, spreadRadius: 3 * t)],
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 5),
                        const Text('دەستپێدەکات لە', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: ArenaBannerColors.muted, height: 1.35)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(width: 8),
                // ژمێرەر (هەمیشە چەپ بۆ ڕاست: ڕۆژ : کاتژمێر : خولەک : چرکە)
                Expanded(
                  child: Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Directionality(
                        textDirection: TextDirection.ltr,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _Unit(value: ArenaTimeLeft.two(l.days), label: 'ڕۆژ', color: ArenaBannerColors.gold),
                            const _Colon(),
                            _Unit(value: ArenaTimeLeft.two(l.hours), label: 'کاتژ', color: ArenaBannerColors.text),
                            const _Colon(),
                            _Unit(value: ArenaTimeLeft.two(l.minutes), label: 'خولەک', color: ArenaBannerColors.text),
                            const _Colon(),
                            _Unit(
                              value: ArenaTimeLeft.two(l.seconds),
                              label: 'چرکە',
                              color: secGold ? ArenaBannerColors.gold : ArenaBannerColors.goldLight,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // دوگمەی چوونە ناوەوە
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(color: ArenaBannerColors.cyan, borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.chevron_left_rounded, size: 22, color: ArenaBannerColors.onCyan),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Unit extends StatelessWidget {
  const _Unit({required this.value, required this.label, required this.color});
  final String value, label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 32,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: color,
              height: 1.2,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          Text(
            label,
            textDirection: TextDirection.rtl,
            style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w600, color: ArenaBannerColors.unit, height: 1.2),
          ),
        ],
      ),
    );
  }
}

class _Colon extends StatelessWidget {
  const _Colon();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Text(':', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: ArenaBannerColors.colon)),
    );
  }
}
