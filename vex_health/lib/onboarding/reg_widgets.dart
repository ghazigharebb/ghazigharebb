// VEX Health — پارچەکانی بەشی سەرەتا: دوگمە، هەڵبژاردن، ڕووەر، چەرخی ساڵ، کۆد، ...
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../core/theme.dart';
import 'reg_data.dart';
import 'reg_icons.dart';
import 'reg_lang_data.dart';
import 'reg_lang_state.dart';

/// ڕەنگەکانی بەشی سەرەتا
class RC {
  RC._();
  static const Color bg = Color(0xFF03181F);
  static const Color p = Color(0xFF9CC4CB);
  static const Color mu = Color(0xFF8CB7BF);
  static const Color dim = Color(0xFF5F8A92);
  static const Color hint = Color(0xFF7FA6AD);
  static const Color soft = Color(0xFFCFE6EC);
  static const Color err = Color(0xFFFF8A9D);
  static const Color lilac = Color(0xFFB9A4FF);
  static Color line(double a) => Color.fromRGBO(140, 235, 245, a);
  static Color white(double a) => Color.fromRGBO(255, 255, 255, a);
}

/// لەرینەوەی سووک (وەک navigator.vibrate)
void buzz([int level = 1]) {
  try {
    if (level <= 0) {
      HapticFeedback.selectionClick();
    } else if (level == 1) {
      HapticFeedback.lightImpact();
    } else {
      HapticFeedback.mediumImpact();
    }
  } catch (_) {}
}

/// ژمارە لە ناو دەقی کوردیدا
TextSpan numSpan(String s, {double size = 14, Color c = V.tx, FontWeight w = FontWeight.w800}) =>
    TextSpan(text: ltr(s), style: nu(size, c: c, w: w));

TextSpan txtSpan(String s, {double size = 14, Color c = RC.p, FontWeight w = FontWeight.w400}) =>
    TextSpan(text: s, style: ku(size, c: c, w: w));

// ---------- سەری هەر هەنگاوێک ----------
class RIcon extends StatelessWidget {
  const RIcon(this.emoji, {super.key, this.compact = false});
  final String emoji;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final s = compact ? 50.0 : 60.0;
    return Container(
      margin: EdgeInsets.only(top: compact ? 2 : 6, bottom: compact ? 8 : 12),
      child: RIco(emoji, size: s, radius: compact ? 16 : 20),
    );
  }
}

class RTitle extends StatelessWidget {
  const RTitle(this.text, {super.key, this.compact = false, this.center = false});
  final String text;
  final bool compact;
  final bool center;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: compact ? 4 : 6),
      child: Text(
        text,
        textAlign: center ? TextAlign.center : TextAlign.start,
        style: ku(compact ? 21 : 25, w: FontWeight.w800, h: 1.45),
      ),
    );
  }
}

class RPara extends StatelessWidget {
  const RPara(this.spans, {super.key, this.compact = false, this.center = false, this.bottom});
  final List<InlineSpan> spans;
  final bool compact;
  final bool center;
  final double? bottom;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: bottom ?? (compact ? 12 : 20)),
      child: Text.rich(
        TextSpan(style: ku(compact ? 13 : 14, c: RC.p, h: compact ? 1.7 : 1.85), children: spans),
        textAlign: center ? TextAlign.center : TextAlign.start,
      ),
    );
  }
}

// ---------- دوگمەی سەرەکی ----------
class RGo extends StatelessWidget {
  const RGo({super.key, required this.label, this.onTap, this.enabled = true, this.busy = false, this.compact = false});
  final String label;
  final VoidCallback? onTap;
  final bool enabled;
  final bool busy;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final on = enabled && !busy;
    return Semantics(
      button: true,
      enabled: on,
      label: label,
      child: Press(
        onTap: on ? onTap : null,
        scale: 0.98,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          width: double.infinity,
          padding: EdgeInsets.symmetric(vertical: compact ? 13 : 16, horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: enabled ? const LinearGradient(colors: [Color(0xFF8FF3F9), Color(0xFF3CF08A)]) : null,
            color: enabled ? null : RC.white(0.07),
            boxShadow: enabled
                ? const [BoxShadow(color: Color(0xD93CF08A), blurRadius: 34, offset: Offset(0, 16), spreadRadius: -14)]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (busy) ...[
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2.5, color: enabled ? V.ink : RC.dim),
                ),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: ku(compact ? 15 : 16, w: FontWeight.w800, c: enabled ? V.ink : RC.dim),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// دوگمەی دەقی (وەک «پێشتر هەژمارم هەیە»)
class RLink extends StatelessWidget {
  const RLink(this.label, {super.key, this.onTap, this.color = V.c2, this.top = 12});
  final String label;
  final VoidCallback? onTap;
  final Color color;
  final double top;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: top),
      child: Center(
        child: Press(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Text(label, textAlign: TextAlign.center, style: ku(13.5, w: FontWeight.w700, c: color)),
          ),
        ),
      ),
    );
  }
}

// ---------- کارتی هەڵبژاردن ----------
class ROptTile extends StatelessWidget {
  const ROptTile({
    super.key,
    required this.emoji,
    required this.title,
    this.sub = '',
    required this.on,
    required this.onTap,
    this.small = false,
    this.compact = false,
    this.check = true,
  });
  final String emoji;
  final String title;
  final String sub;
  final bool on;
  final VoidCallback onTap;
  final bool small;
  final bool compact;
  final bool check;

  @override
  Widget build(BuildContext context) {
    final es = small ? 40.0 : (compact ? 40.0 : 48.0);
    return Semantics(
      button: true,
      selected: on,
      label: title,
      child: Press(
        onTap: onTap,
        scale: 0.98,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(horizontal: small ? 12 : 15, vertical: small ? 13 : (compact ? 11 : 15)),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: on ? V.mint : RC.line(0.14), width: 1.5),
            gradient: on
                ? const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0x1A8FF3F9), Color(0x1A3CF08A)],
                  )
                : null,
            color: on ? null : RC.white(0.035),
            boxShadow: on
                ? const [BoxShadow(color: Color(0x663CF08A), blurRadius: 28, offset: Offset(0, 12), spreadRadius: -18)]
                : null,
          ),
          child: Row(
            children: [
              RIco(emoji, size: es, radius: small || compact ? 13 : 16),
              SizedBox(width: small ? 10 : (compact ? 12 : 14)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: ku(small ? 14 : (compact ? 14.5 : 15.5), w: FontWeight.w800, h: 1.4)),
                    if (sub.isNotEmpty)
                      Text(sub, style: ku(compact ? 11.5 : 12.5, c: RC.mu, h: 1.6)),
                  ],
                ),
              ),
              if (check) ...[
                const SizedBox(width: 10),
                RCheck(on: on),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class RCheck extends StatelessWidget {
  const RCheck({super.key, required this.on});
  final bool on;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 24,
      height: 24,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: on ? V.mint : Colors.transparent,
        border: Border.all(color: on ? V.mint : RC.line(0.3), width: 2),
      ),
      child: AnimatedOpacity(
        opacity: on ? 1 : 0,
        duration: const Duration(milliseconds: 200),
        child: Text('✓', style: ku(13, w: FontWeight.w900, c: V.ink, h: 1)),
      ),
    );
  }
}

/// کارتی گەورە (نێر / مێ)
class RBigOpt extends StatelessWidget {
  const RBigOpt({super.key, required this.emoji, this.art, required this.title, required this.on, required this.onTap, this.compact = false});
  final String emoji;

  /// وێنەی دیزاین کراو (ئەگەر هەبێت جێگەی ئیمۆجی دەگرێتەوە)
  final Widget? art;
  final String title;
  final bool on;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final es = compact ? 62.0 : 76.0;
    return Semantics(
      button: true,
      selected: on,
      label: title,
      child: Press(
        onTap: onTap,
        scale: 0.98,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(vertical: compact ? 16 : 22, horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: on ? V.mint : RC.line(0.14), width: 1.5),
            gradient: on
                ? const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0x1A8FF3F9), Color(0x1A3CF08A)],
                  )
                : null,
            color: on ? null : RC.white(0.035),
            boxShadow: on
                ? const [BoxShadow(color: Color(0x663CF08A), blurRadius: 28, offset: Offset(0, 12), spreadRadius: -18)]
                : null,
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    art ??
                        AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: es,
                      height: es,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: on ? const Color(0x293CF08A) : RC.white(0.05),
                      ),
                      child: Text(emoji, style: TextStyle(fontSize: compact ? 32 : 40)),
                    ),
                    const SizedBox(height: 10),
                    Text(title, style: ku(17, w: FontWeight.w800)),
                  ],
                ),
              ),
              Positioned(top: -10, left: -2, child: RCheck(on: on)),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------- دوگمەی − / + (بە ڕاگرتن دووبارە دەبێتەوە) ----------
class RPM extends StatefulWidget {
  const RPM({super.key, required this.plus, required this.onTap, this.size = 46});
  final bool plus;
  final VoidCallback onTap;
  final double size;

  @override
  State<RPM> createState() => _RPMState();
}

class _RPMState extends State<RPM> {
  Timer? _rep;
  bool _down = false;

  void _stop() {
    _rep?.cancel();
    _rep = null;
    if (_down && mounted) setState(() => _down = false);
  }

  @override
  void dispose() {
    _rep?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: widget.plus ? 'زیاتر' : 'کەمتر',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _down = true),
        onTapUp: (_) => _stop(),
        onTapCancel: _stop,
        onTap: widget.onTap,
        onLongPressStart: (_) {
          setState(() => _down = true);
          _rep?.cancel();
          _rep = Timer.periodic(const Duration(milliseconds: 90), (_) => widget.onTap());
        },
        onLongPressEnd: (_) => _stop(),
        onLongPressCancel: _stop,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          width: widget.size,
          height: widget.size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.size * 0.35),
            border: Border.all(color: RC.line(0.2)),
            color: _down ? const Color(0x242FE6F3) : RC.white(0.05),
          ),
          child: Text(widget.plus ? '+' : '−', style: nu(widget.size * 0.5, w: FontWeight.w600, c: V.c2, h: 1)),
        ),
      ),
    );
  }
}

/// نرخی گەورە لەگەڵ − و +
class RValue extends StatelessWidget {
  const RValue({super.key, required this.value, required this.unit, required this.onMinus, required this.onPlus, this.compact = false});
  final String value;
  final String unit;
  final VoidCallback onMinus;
  final VoidCallback onPlus;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: compact ? 6 : 14, bottom: compact ? 2 : 6),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            RPM(plus: false, onTap: onMinus),
            const SizedBox(width: 14),
            SizedBox(
              width: 160,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: ShaderMask(
                      shaderCallback: (r) => const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.white, Color(0xFFA8F6FB)],
                      ).createShader(r),
                      blendMode: BlendMode.srcIn,
                      child: Text(value, style: nu(compact ? 48 : 58, c: Colors.white, h: 1, ls: -2)),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(unit,
                      textDirection: TextDirection.rtl, style: ku(14, w: FontWeight.w700, c: RC.mu, h: 1.3)),
                ],
              ),
            ),
            const SizedBox(width: 14),
            RPM(plus: true, onTap: onPlus),
          ],
        ),
      ),
    );
  }
}

/// cm / ft  یان  kg / lb
class RUnitSeg extends StatelessWidget {
  const RUnitSeg({super.key, required this.values, required this.value, required this.onChanged});
  final List<String> values;
  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.only(top: 4),
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: RC.white(0.05),
          border: Border.all(color: RC.line(0.14)),
        ),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final u in values)
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    if (u != value) {
                      buzz(0);
                      onChanged(u);
                    }
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(11),
                      color: u == value ? V.tx : Colors.transparent,
                    ),
                    child: Text(u, style: nu(13, w: FontWeight.w700, c: u == value ? V.bg : RC.mu)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------- ڕووەر (باڵا / کێش / ئامانج) ----------

/// پەڕینەوە و وەستان ڕێک لەسەر هێڵێک
class SnapPhysics extends ScrollPhysics {
  const SnapPhysics({required this.unit, super.parent});
  final double unit;

  @override
  SnapPhysics applyTo(ScrollPhysics? ancestor) => SnapPhysics(unit: unit, parent: buildParent(ancestor));

  @override
  Simulation? createBallisticSimulation(ScrollMetrics position, double velocity) {
    if ((velocity <= 0.0 && position.pixels <= position.minScrollExtent) ||
        (velocity >= 0.0 && position.pixels >= position.maxScrollExtent)) {
      return super.createBallisticSimulation(position, velocity);
    }
    final tol = toleranceFor(position);
    final friction = FrictionSimulation(0.135, position.pixels, velocity);
    double target = velocity.abs() < tol.velocity ? position.pixels : friction.finalX;
    target = (target / unit).round() * unit;
    target = target.clamp(position.minScrollExtent, position.maxScrollExtent);
    if ((target - position.pixels).abs() < 0.5) return null;
    return ScrollSpringSimulation(spring, position.pixels, target, velocity, tolerance: tol);
  }

  @override
  bool get allowImplicitScrolling => false;
}

class RRuler extends StatefulWidget {
  const RRuler({
    super.key,
    required this.min,
    required this.max,
    required this.step,
    required this.value,
    required this.onChanged,
    this.height = 92,
  });
  final double min;
  final double max;
  final double step;
  final double value;
  final ValueChanged<double> onChanged;
  final double height;

  @override
  State<RRuler> createState() => _RRulerState();
}

class _RRulerState extends State<RRuler> {
  static const double u = 10;
  late double _last = _clamp(widget.value);
  late final ScrollController _c = ScrollController(initialScrollOffset: _pos(_last));
  int _anim = 0;

  int get _n => ((widget.max - widget.min) / widget.step).round();
  double _pos(double v) => (v - widget.min) / widget.step * u;
  double _clamp(double v) {
    final s = (v / widget.step).round() * widget.step;
    return double.parse(s.clamp(widget.min, widget.max).toStringAsFixed(2));
  }

  @override
  void initState() {
    super.initState();
    _c.addListener(_onScroll);
  }

  @override
  void didUpdateWidget(RRuler old) {
    super.didUpdateWidget(old);
    final v = _clamp(widget.value);
    if ((v - _last).abs() > 1e-6) {
      _last = v;
      _animateTo(v);
    }
  }

  @override
  void dispose() {
    _c.removeListener(_onScroll);
    _c.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_anim > 0 || !_c.hasClients) return;
    final v = _clamp(widget.min + (_c.offset / u).round() * widget.step);
    if ((v - _last).abs() > 1e-6) {
      _last = v;
      buzz(0);
      widget.onChanged(v);
    }
  }

  void _animateTo(double v) {
    if (!_c.hasClients) return;
    _anim++;
    _c
        .animateTo(_pos(v), duration: const Duration(milliseconds: 320), curve: Curves.easeOutCubic)
        .whenComplete(() {
      if (_anim > 0) _anim--;
    });
  }

  @override
  Widget build(BuildContext context) {
    final h = widget.height;
    return Directionality(
      textDirection: TextDirection.ltr,
      child: SizedBox(
        height: h,
        child: LayoutBuilder(
          builder: (context, cons) {
            final pad = cons.maxWidth / 2;
            return Stack(
              children: [
                Positioned.fill(
                  child: ShaderMask(
                    shaderCallback: (r) => const LinearGradient(
                      colors: [Colors.transparent, Colors.black, Colors.black, Colors.transparent],
                      stops: [0, 0.22, 0.78, 1],
                    ).createShader(r),
                    blendMode: BlendMode.dstIn,
                    child: SingleChildScrollView(
                      controller: _c,
                      scrollDirection: Axis.horizontal,
                      physics: SnapPhysics(unit: u, parent: const ClampingScrollPhysics()),
                      child: RepaintBoundary(
                        child: CustomPaint(
                          size: Size(pad * 2 + _n * u, h),
                          painter: _TickPainter(
                            pad: pad,
                            n: _n,
                            min: widget.min,
                            step: widget.step,
                            compact: h < 90,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                // نیشانەی ناوەڕاست
                Positioned(
                  top: 2,
                  left: pad - 2,
                  child: IgnorePointer(
                    child: CustomPaint(size: Size(4, h < 90 ? 56 : 62), painter: _MarkPainter()),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _TickPainter extends CustomPainter {
  _TickPainter({required this.pad, required this.n, required this.min, required this.step, required this.compact});
  final double pad;
  final int n;
  final double min;
  final double step;
  final bool compact;

  @override
  void paint(Canvas canvas, Size size) {
    const u = 10.0;
    final major = Paint()
      ..color = const Color(0xBF8CEBF5)
      ..strokeWidth = 2;
    final mid = Paint()
      ..color = const Color(0x738CEBF5)
      ..strokeWidth = 2;
    final minor = Paint()
      ..color = const Color(0x408CEBF5)
      ..strokeWidth = 1.5;
    const top = 10.0;
    final k = compact ? 0.88 : 1.0;
    for (int i = 0; i <= n; i++) {
      final x = pad + i * u;
      if (i % 10 == 0) {
        canvas.drawLine(Offset(x, top), Offset(x, top + 40 * k), major);
        final v = min + i * step;
        final tp = TextPainter(
          text: TextSpan(text: numTxt(v), style: nu(12, w: FontWeight.w700, c: RC.mu)),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, Offset(x - tp.width / 2, compact ? 54 : 62));
      } else if (i % 5 == 0) {
        canvas.drawLine(Offset(x, top), Offset(x, top + 28 * k), mid);
      } else {
        canvas.drawLine(Offset(x, top), Offset(x, top + 18 * k), minor);
      }
    }
  }

  @override
  bool shouldRepaint(_TickPainter o) =>
      o.pad != pad || o.n != n || o.min != min || o.step != step || o.compact != compact;
}

class _MarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final r = RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(4));
    canvas.drawRRect(
      r.inflate(3),
      Paint()
        ..color = const Color(0x803CF08A)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7),
    );
    canvas.drawRRect(
      r,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF8FF3F9), Color(0xFF3CF08A)],
        ).createShader(Offset.zero & size),
    );
    final tri = Path()
      ..moveTo(size.width / 2 - 6, -8)
      ..lineTo(size.width / 2 + 6, -8)
      ..lineTo(size.width / 2, -2)
      ..close();
    canvas.drawPath(tri, Paint()..color = const Color(0xFF8FF3F9));
  }

  @override
  bool shouldRepaint(_MarkPainter o) => false;
}

// ---------- BMI ----------
class RBmiCard extends StatelessWidget {
  const RBmiCard({super.key, required this.bmi, this.compact = false});
  final double bmi;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final c = bmiCat(bmi);
    final pos = ((bmi.clamp(15.0, 40.0) - 15) / 25);
    return Container(
      margin: EdgeInsets.only(top: compact ? 12 : 18),
      padding: EdgeInsets.symmetric(horizontal: compact ? 14 : 16, vertical: compact ? 12 : 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: RC.white(0.04),
        border: Border.all(color: RC.line(0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: Text('ڕێژەی کێش و بەرزی (BMI)', style: ku(12.5, w: FontWeight.w700, c: RC.mu))),
              Text(bmi.toStringAsFixed(1), textDirection: TextDirection.ltr, style: nu(20)),
              const SizedBox(width: 6),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 250),
                style: ku(13, w: FontWeight.w800, c: c.color),
                child: Text(c.label),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Directionality(
            textDirection: TextDirection.ltr,
            child: SizedBox(
              height: 16,
              child: LayoutBuilder(
                builder: (context, cons) {
                  final w = cons.maxWidth;
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned(
                        left: 0,
                        right: 0,
                        top: 4,
                        height: 8,
                        child: Row(
                          children: const [
                            _Seg(3.5, Color(0xBF6AA8FF)),
                            SizedBox(width: 3),
                            _Seg(6.5, Color(0xBF3CF08A)),
                            SizedBox(width: 3),
                            _Seg(5, Color(0xBFFFBE4D)),
                            SizedBox(width: 3),
                            _Seg(10, Color(0xBFFF8A5F)),
                          ],
                        ),
                      ),
                      AnimatedPositioned(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOutCubic,
                        left: pos * w - 8,
                        top: 0,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            border: Border.all(color: c.color, width: 3),
                            boxShadow: const [BoxShadow(color: Color(0x1FFFFFFF), spreadRadius: 4)],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 4),
          Directionality(
            textDirection: TextDirection.ltr,
            child: SizedBox(
              height: 16,
              child: LayoutBuilder(
                builder: (context, cons) {
                  final w = cons.maxWidth;
                  Widget lb(String t, double f) => Positioned(
                        left: w * f - 20,
                        width: 40,
                        top: 0,
                        child: Text(t, textAlign: TextAlign.center, style: nu(10.5, w: FontWeight.w600, c: RC.dim)),
                      );
                  return Stack(clipBehavior: Clip.none, children: [lb('18.5', 0.14), lb('25', 0.40), lb('30', 0.60)]);
                },
              ),
            ),
          ),
          if (!compact) ...[
            const SizedBox(height: 6),
            Text(c.text, style: ku(12.5, c: RC.p, h: 1.7)),
          ],
        ],
      ),
    );
  }
}

class _Seg extends StatelessWidget {
  const _Seg(this.flex, this.color);
  final double flex;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: (flex * 10).round(),
      child: Container(decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(9))),
    );
  }
}

// ---------- چەرخی ساڵی لەدایکبوون ----------
class RYearWheel extends StatefulWidget {
  const RYearWheel({super.key, required this.value, required this.onChanged, this.compact = false});
  final int value;
  final ValueChanged<int> onChanged;
  final bool compact;

  @override
  State<RYearWheel> createState() => _RYearWheelState();
}

class _RYearWheelState extends State<RYearWheel> {
  static const double ext = 48;
  late final List<int> years = [for (int y = kThisYear - 13; y >= kThisYear - 95; y--) y];
  late int _sel = _idx(widget.value);
  late final FixedExtentScrollController _c = FixedExtentScrollController(initialItem: _sel);

  int _idx(int y) {
    final i = years.indexOf(y);
    return i < 0 ? 0 : i;
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final h = widget.compact ? 192.0 : 240.0;
    return Center(
      child: SizedBox(
        width: 280,
        height: h,
        child: Stack(
          children: [
            Positioned(
              left: 0,
              right: 0,
              top: (h - ext) / 2,
              height: ext,
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: const Color(0x142FE6F3),
                    border: Border.all(color: const Color(0x4D2FE6F3)),
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: ShaderMask(
                shaderCallback: (r) => const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black, Colors.black, Colors.transparent],
                  stops: [0, 0.3, 0.7, 1],
                ).createShader(r),
                blendMode: BlendMode.dstIn,
                child: ListWheelScrollView(
                  controller: _c,
                  itemExtent: ext,
                  diameterRatio: 3.2,
                  physics: const FixedExtentScrollPhysics(),
                  onSelectedItemChanged: (i) {
                    if (i < 0 || i >= years.length) return;
                    setState(() => _sel = i);
                    buzz(0);
                    widget.onChanged(years[i]);
                  },
                  children: [
                    for (int i = 0; i < years.length; i++)
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => _c.animateToItem(i,
                            duration: const Duration(milliseconds: 300), curve: Curves.easeOutCubic),
                        child: Center(
                          child: AnimatedScale(
                            scale: i == _sel ? 1.25 : 1,
                            duration: const Duration(milliseconds: 150),
                            child: Text(
                              '${years[i]}',
                              style: nu(22, w: FontWeight.w700, c: i == _sel ? Colors.white : RC.dim),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------- خانەکانی کۆدی 6 ژمارەیی ----------
class ROtp extends StatefulWidget {
  const ROtp({
    super.key,
    required this.controller,
    required this.focus,
    required this.onChanged,
    required this.errorTick,
    this.bad = false,
    this.compact = false,
  });
  final TextEditingController controller;
  final FocusNode focus;
  final ValueChanged<String> onChanged;
  final int errorTick;
  final bool bad;
  final bool compact;

  @override
  State<ROtp> createState() => _ROtpState();
}

class _ROtpState extends State<ROtp> with SingleTickerProviderStateMixin {
  late final AnimationController _shake =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 400));

  @override
  void initState() {
    super.initState();
    widget.focus.addListener(_re);
    widget.controller.addListener(_re);
  }

  void _re() {
    if (mounted) setState(() {});
  }

  @override
  void didUpdateWidget(ROtp old) {
    super.didUpdateWidget(old);
    if (old.focus != widget.focus) {
      old.focus.removeListener(_re);
      widget.focus.addListener(_re);
    }
    if (old.controller != widget.controller) {
      old.controller.removeListener(_re);
      widget.controller.addListener(_re);
    }
    if (widget.errorTick != old.errorTick) _shake.forward(from: 0);
  }

  @override
  void dispose() {
    widget.focus.removeListener(_re);
    widget.controller.removeListener(_re);
    _shake.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final code = widget.controller.text;
    final bh = widget.compact ? 50.0 : 60.0;
    return AnimatedBuilder(
      animation: _shake,
      builder: (context, child) {
        final t = _shake.value;
        final dx = t == 0 || t == 1 ? 0.0 : math.sin(t * math.pi * 4) * 7 * (1 - t);
        return Transform.translate(offset: Offset(dx, 0), child: child);
      },
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: SizedBox(
          height: bh,
          child: Stack(
            children: [
              // خانەی نووسینی ڕاستەقینە (نادیار) — لکاندن و سڕینەوە و کۆدی SMS بە خۆکاری
              Positioned.fill(
                child: Opacity(
                  opacity: 0.011,
                  child: TextField(
                    controller: widget.controller,
                    focusNode: widget.focus,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.oneTimeCode],
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(6),
                    ],
                    showCursor: false,
                    enableInteractiveSelection: false,
                    autocorrect: false,
                    enableSuggestions: false,
                    style: const TextStyle(color: Colors.transparent, fontSize: 1),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      counterText: '',
                      isCollapsed: true,
                    ),
                    onChanged: widget.onChanged,
                  ),
                ),
              ),
              IgnorePointer(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (int i = 0; i < 6; i++) ...[
                      if (i > 0) const SizedBox(width: 8),
                      _box(i, code, bh),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _box(int i, String code, double bh) {
    final has = i < code.length;
    final cur = widget.focus.hasFocus && (i == code.length || (code.length == 6 && i == 5));
    final Color border = widget.bad ? V.coral : (cur ? V.cy : RC.line(0.22));
    return Flexible(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        constraints: const BoxConstraints(maxWidth: 48),
        height: bh,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: border, width: 1.5),
          color: cur ? const Color(0x0F2FE6F3) : RC.white(0.05),
        ),
        child: has
            ? Text(code[i], style: nu(24, c: Colors.white))
            : (cur ? const _Caret() : const SizedBox.shrink()),
      ),
    );
  }
}

class _Caret extends StatefulWidget {
  const _Caret();

  @override
  State<_Caret> createState() => _CaretState();
}

class _CaretState extends State<_Caret> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 520))..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _c,
      child: Container(width: 2, height: 24, color: V.cy),
    );
  }
}

// ---------- چیپ ----------
class RChip extends StatelessWidget {
  const RChip({super.key, required this.label, this.icon, required this.on, required this.onTap, this.compact = false});
  final String label;
  final String? icon;
  final bool on;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: on,
      label: label,
      child: Press(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: EdgeInsets.symmetric(horizontal: compact ? 13 : 15, vertical: compact ? 9 : 11),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(99),
            border: Border.all(color: on ? V.mint : RC.line(0.16), width: 1.5),
            color: on ? const Color(0x1F3CF08A) : RC.white(0.04),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Container(
                  width: 24,
                  height: 24,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: op(rIcoColor(icon!), 0.18)),
                  child: RIco(icon!, size: 14, tile: false),
                ),
                const SizedBox(width: 8),
              ],
              Text(label,
                  style: ku(compact ? 13 : 14, w: FontWeight.w700, c: on ? const Color(0xFFC9FFE0) : V.tx, h: 1.3)),
            ],
          ),
        ),
      ),
    );
  }
}

/// سویچ (داگیرساو = چەپ، وەک وێب)
class RSwitch extends StatelessWidget {
  const RSwitch({super.key, required this.on, required this.onTap, this.label = ''});
  final bool on;
  final VoidCallback onTap;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      toggled: on,
      label: label,
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: 48,
            height: 29,
            padding: const EdgeInsets.all(3.5),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(99),
              color: on ? V.mint : RC.white(0.12),
            ),
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                alignment: on ? Alignment.centerLeft : Alignment.centerRight,
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    boxShadow: [BoxShadow(color: Color(0x4D000000), blurRadius: 4, offset: Offset(0, 1))],
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

/// تێبینی پاراستن 🔒
class RLock extends StatelessWidget {
  const RLock(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 18),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: RC.white(0.035),
        border: Border.all(color: RC.line(0.1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const RIco('🔒', size: 34, radius: 12),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: ku(12.5, c: RC.p, h: 1.75))),
        ],
      ),
    );
  }
}

class RHint extends StatelessWidget {
  const RHint(this.spans, {super.key, this.top = 14});
  final List<InlineSpan> spans;
  final double top;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: top),
      child: Text.rich(
        TextSpan(style: ku(12.5, c: RC.hint, h: 1.6), children: spans),
        textAlign: TextAlign.center,
      ),
    );
  }
}

// ---------- خانەی نووسین ----------
InputDecoration rInputDeco(String hint, {bool compact = false, bool ltrHint = false}) => InputDecoration(
      hintText: hint,
      hintTextDirection: ltrHint ? TextDirection.ltr : null,
      hintStyle: ku(compact ? 16 : 17, w: FontWeight.w600, c: RC.dim),
      filled: true,
      fillColor: RC.white(0.05),
      isDense: true,
      counterText: '',
      contentPadding: EdgeInsets.symmetric(horizontal: compact ? 14 : 18, vertical: compact ? 12 : 16),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: RC.line(0.2), width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: V.cy, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: V.coral, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: V.coral, width: 1.5),
      ),
    );

/// ژمارەی مۆبایل لە کاتی نووسیندا ڕێک دەخات: 750 123 4567
class PhoneFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final d = cleanPhone(newValue.text);
    final t = fmtPhone(d);
    return TextEditingValue(text: t, selection: TextSelection.collapsed(offset: t.length));
  }
}

// ---------- تایبەتمەندییە ڕۆیشتووەکان (بەخێرهاتن) ----------
class RMarquee extends StatelessWidget {
  const RMarquee({super.key, this.compact = false});
  final bool compact;

  @override
  Widget build(BuildContext context) {
    const secs = [46, 56, 42, 52];
    return ShaderMask(
      shaderCallback: (r) => const LinearGradient(
        colors: [Colors.transparent, Colors.black, Colors.black, Colors.transparent],
        stops: [0, 0.16, 0.84, 1],
      ).createShader(r),
      blendMode: BlendMode.dstIn,
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (int i = 0; i < kFeatRows.length; i++) ...[
              if (i > 0) SizedBox(height: compact ? 6 : 8),
              Rise(
                delayMs: 150 + i * 120,
                child: _MqRow(
                  row: kFeatRows[i],
                  labels: LangState.I.isKu ? null : kFeatEn.sublist(i * 8, i * 8 + kFeatRows[i].length),
                  seconds: secs[i],
                  reverse: i.isOdd,
                  height: compact ? 31 : 36,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MqRow extends StatefulWidget {
  const _MqRow({required this.row, this.labels, required this.seconds, required this.reverse, required this.height});
  final List<RPill> row;
  final List<String>? labels;
  final int seconds;
  final bool reverse;
  final double height;

  @override
  State<_MqRow> createState() => _MqRowState();
}

class _MqRowState extends State<_MqRow> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: Duration(seconds: widget.seconds));
  double _w = 0;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final calm = MediaQuery.of(context).disableAnimations;
    if (calm) {
      _c.stop();
    } else if (!_started) {
      _started = true;
      _c.repeat();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final group = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < widget.row.length; i++)
          Padding(padding: const EdgeInsets.only(right: 8), child: _pill(widget.row[i], widget.labels?[i])),
      ],
    );
    return SizedBox(
      height: widget.height,
      child: ClipRect(
        child: RepaintBoundary(
          child: OverflowBox(
            alignment: Alignment.centerLeft,
            minWidth: 0,
            maxWidth: double.infinity,
            child: AnimatedBuilder(
              animation: _c,
              builder: (context, child) {
                final t = widget.reverse ? 1 - _c.value : _c.value;
                return Transform.translate(offset: Offset(-t * _w, 0), child: child);
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _SizeReport(
                    onSize: (s) {
                      if (mounted && (s.width - _w).abs() > 0.5) setState(() => _w = s.width);
                    },
                    child: group,
                  ),
                  group,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _pill(RPill p, String? label) {
    final k = Color(p.c);
    return Container(
      height: widget.height,
      padding: const EdgeInsets.only(left: 12, right: 13),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(99),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [op(k, 0.16), RC.white(0.025)],
        ),
        border: Border.all(color: op(k, 0.40)),
      ),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            RIco(p.e, size: 16, tile: false, color: k),
            const SizedBox(width: 7),
            Text(label ?? p.t, style: ku(widget.height < 34 ? 12 : 12.5, w: FontWeight.w700, c: const Color(0xFFE9FBFD), h: 1.2)),
          ],
        ),
      ),
    );
  }
}

/// قەبارەی منداڵەکەی ڕادەگەیەنێت (بۆ ئەوەی ڕیزەکە بە بێ بڕین بخولێتەوە)
class _SizeReport extends SingleChildRenderObjectWidget {
  const _SizeReport({required this.onSize, super.child});
  final ValueChanged<Size> onSize;

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderSizeReport(onSize);

  @override
  void updateRenderObject(BuildContext context, _RenderSizeReport renderObject) {
    renderObject.onSize = onSize;
  }
}

class _RenderSizeReport extends RenderProxyBox {
  _RenderSizeReport(this.onSize);
  ValueChanged<Size> onSize;
  Size? _old;

  @override
  void performLayout() {
    super.performLayout();
    final s = size;
    if (_old != s) {
      _old = s;
      WidgetsBinding.instance.addPostFrameCallback((_) => onSize(s));
    }
  }
}

// ---------- لۆگۆ ----------
class RLogo extends StatefulWidget {
  const RLogo({super.key, this.width = 136});
  final double width;

  @override
  State<RLogo> createState() => _RLogoState();
}

class _RLogoState extends State<RLogo> with TickerProviderStateMixin {
  late final AnimationController _spin =
      AnimationController(vsync: this, duration: const Duration(seconds: 26))..repeat();
  late final AnimationController _glow =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1600))..repeat(reverse: true);

  @override
  void dispose() {
    _spin.dispose();
    _glow.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w = widget.width;
    final h = w / 1.36;
    return SizedBox(
      width: w,
      height: h,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // ڕووناکی پشتەوە
          AnimatedBuilder(
            animation: _glow,
            builder: (context, _) {
              final t = Curves.easeInOut.transform(_glow.value);
              return Transform.scale(
                scale: 1 - 0.08 * t,
                child: Opacity(
                  opacity: 1 - 0.45 * t,
                  child: Container(
                    width: w * 0.72,
                    height: h * 0.84,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(colors: [Color(0x522FE6F3), Color(0x002FE6F3)], stops: [0, 0.68]),
                    ),
                  ),
                ),
              );
            },
          ),
          // بازنەی خاڵخاڵی خولاوە
          RotationTransition(
            turns: _spin,
            child: CustomPaint(size: Size(w * 0.76, h * 1.12), painter: _DashRing()),
          ),
          Image.asset(
            'assets/brand/vx_logo.webp',
            width: w,
            height: h,
            fit: BoxFit.contain,
            errorBuilder: (context, e, s) => Text('VX', style: nu(w * 0.32, c: V.cy)),
          ),
        ],
      ),
    );
  }
}

class _DashRing extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final r = math.min(size.width, size.height) / 2;
    final c = size.center(Offset.zero);
    final p = Paint()
      ..color = const Color(0x388CEBF5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    const n = 54;
    for (int i = 0; i < n; i++) {
      final a = i / n * math.pi * 2;
      canvas.drawArc(Rect.fromCircle(center: c, radius: r), a, math.pi * 2 / n * 0.55, false, p);
    }
  }

  @override
  bool shouldRepaint(_DashRing o) => false;
}

// ---------- ڕادار (گەڕان بە دوای Band) ----------
class RRadar extends StatefulWidget {
  const RRadar({super.key, required this.icon, this.rings = 3, this.size = 200});
  final String icon;
  final int rings;
  final double size;

  @override
  State<RRadar> createState() => _RRadarState();
}

class _RRadarState extends State<RRadar> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 2400))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.size;
    return SizedBox(
      width: s,
      height: s,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (widget.rings > 0)
            AnimatedBuilder(
              animation: _c,
              builder: (context, _) => CustomPaint(
                size: Size(s, s),
                painter: _RadarPainter(_c.value, widget.rings),
              ),
            ),
          Container(
            width: 78,
            height: 78,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                center: Alignment(-0.3, -0.4),
                colors: [Color(0xFF8FF3F9), Color(0xFF14B8D6), Color(0xFF0B5F73)],
                stops: [0, 0.6, 1],
              ),
              boxShadow: [BoxShadow(color: Color(0x802FE6F3), blurRadius: 40)],
            ),
            child: widget.icon == '⌚'
                ? Padding(
                    padding: const EdgeInsets.all(10),
                    child: Image.asset(
                      'assets/brand/vex_band.webp',
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const RIco('⌚', size: 36, tile: false, color: V.ink),
                    ),
                  )
                : RIco(widget.icon, size: 36, tile: false, color: V.ink, stroke: 2),
          ),
        ],
      ),
    );
  }
}

class _RadarPainter extends CustomPainter {
  _RadarPainter(this.t, this.rings);
  final double t;
  final int rings;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final maxR = size.width / 2;
    for (int i = 0; i < rings; i++) {
      final p = (t + i / 3) % 1.0;
      final e = Curves.easeOutCubic.transform(p);
      final r = maxR * (0.3 + 0.7 * e);
      final a = (0.9 * (1 - p)).clamp(0.0, 1.0);
      canvas.drawCircle(
        c,
        r,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = Color.fromRGBO(47, 230, 243, 0.5 * a / 0.9),
      );
    }
  }

  @override
  bool shouldRepaint(_RadarPainter o) => o.t != t || o.rings != rings;
}

// ---------- وێنەی VEX Band ----------
const String kBandSvg = '<svg viewBox="0 0 160 160" xmlns="http://www.w3.org/2000/svg"><defs>'
    '<linearGradient id="vbS" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#0b2f3a"/><stop offset=".5" stop-color="#1a5666"/><stop offset="1" stop-color="#0b2f3a"/></linearGradient>'
    '<linearGradient id="vbP" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#2c343c"/><stop offset="1" stop-color="#0d1115"/></linearGradient></defs>'
    '<path d="M60 2h40l-3 40H63z" fill="url(#vbS)"/><path d="M63 118h34l3 40H60z" fill="url(#vbS)"/>'
    '<rect x="47" y="36" width="66" height="88" rx="24" fill="url(#vbP)" stroke="#2fe6f3" stroke-opacity=".55" stroke-width="1.6"/>'
    '<rect x="54" y="43" width="52" height="74" rx="18" fill="#03141a"/>'
    '<path d="M58 84h11l4-9 6 18 5-13 3 4h15" fill="none" stroke="#3cf08a" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round"/>'
    '</svg>';

class RBandArt extends StatelessWidget {
  const RBandArt({super.key, this.size = 150});
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: size,
            height: size,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [Color(0x4D2FE6F3), Color(0x002FE6F3)], stops: [0, 0.65]),
            ),
          ),
          SizedBox(
            width: size,
            height: size,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SvgPicture.string(kBandSvg, width: size, height: size),
                // ژمارەکانی سەر شاشەی Band (بە فۆنتی ئەپ)
                Positioned(
                  top: size * 0.335,
                  child: Text('72', style: nu(size * 0.094, c: V.tx, h: 1)),
                ),
                Positioned(
                  top: size * 0.62,
                  child: Text('BPM', style: nu(size * 0.05, w: FontWeight.w700, c: RC.mu, h: 1)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------- کارتی بچووکی پلان ----------
class RPlanTile extends StatelessWidget {
  const RPlanTile({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.unit = '',
    required this.sub,
    required this.color,
    this.compact = false,
  });
  final String icon;
  final String label;
  final String value;
  final String unit;
  final String sub;
  final Color color;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 11 : 12, vertical: compact ? 8 : 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: RC.white(0.04),
        border: Border.all(color: RC.line(0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              RIco(icon, size: 14, tile: false, color: color),
              const SizedBox(width: 6),
              Expanded(child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: ku(12, w: FontWeight.w700, c: RC.mu))),
            ],
          ),
          const SizedBox(height: 2),
          Text.rich(
            TextSpan(children: [
              TextSpan(text: ltr(value), style: nu(compact ? 18 : 20, c: color)),
              if (unit.isNotEmpty) TextSpan(text: ' $unit', style: ku(12, w: FontWeight.w600, c: RC.mu)),
            ]),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(sub, maxLines: 1, overflow: TextOverflow.ellipsis, style: ku(11.5, c: RC.hint, h: 1.5)),
        ],
      ),
    );
  }
}
