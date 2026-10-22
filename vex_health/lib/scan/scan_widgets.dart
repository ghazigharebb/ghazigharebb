// VEX Health — سکانی خواردن: پارچەکانی پەڕەی ئەنجام
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/theme.dart';
import 'scan_model.dart';

const List<Color> kICol = [
  Color(0xFF3CF08A), Color(0xFF2FE6F3), Color(0xFFFFBE4D), Color(0xFFFF5F7E), Color(0xFF9B7BFF), Color(0xFFFF9466)
];
const List<Color> kACol = [
  Color(0xFFFFBE4D), Color(0xFF3CF08A), Color(0xFFFF5F7E), Color(0xFF2FE6F3), Color(0xFFB9A4FF), Color(0xFFFF9466)
];
const Color kPro = Color(0xFFFF5F7E);
const Color kCarb = Color(0xFFFFBE4D);
const Color kFat = Color(0xFF9B7BFF);
const Color kDim = Color(0xFF5F8A92);
const Color kSoft = Color(0xFFCFE6EC);
const Color kScanBg = Color(0xFF03181F);

class Verd {
  const Verd(this.c, this.t, this.e);
  final Color c;
  final String t;
  final String e;
}

const Map<String, Verd> kVerd = {
  'good': Verd(Color(0xFF3CF08A), 'هەڵبژاردنێکی باشە', '🌿'),
  'ok': Verd(Color(0xFFFFBE4D), 'بە ئەندازە، باشە', '👌'),
  'bad': Verd(Color(0xFFFF8A5F), 'بڕێکی کەمتر باشترە', '🤏'),
};

/// کارتی پەڕەی ئەنجام
class SCard extends StatelessWidget {
  const SCard({super.key, required this.child, this.padding = const EdgeInsets.all(16)});
  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: padding,
      decoration: BoxDecoration(
        color: V.surf,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: V.line),
      ),
      child: child,
    );
  }
}

Widget lab(String t) => VText(t, style: ku(12.5, w: FontWeight.w800, c: V.mu));

/// ژمارە لە ناو دەقدا
TextSpan nspan(String s, {double size = 13, Color? c, FontWeight w = FontWeight.w800}) { c ??= V.tx; return
    TextSpan(text: ltr(s), style: nu(size, c: c, w: w)); }

String gTxt(double v) => v < 10 ? nf((v * 10).round() / 10) : fmt(v);

// =====================================================================
//  وێنەی سەرەوە: ناوی خواردن لە ناوەڕاست + پێکهاتەکان بە دەوریدا
// =====================================================================
class ScanHero extends StatefulWidget {
  const ScanHero({super.key, required this.r, required this.image, required this.onClose});
  final ScanResult r;
  final ImageProvider? image;
  final VoidCallback onClose;

  @override
  State<ScanHero> createState() => _ScanHeroState();
}

class _Line {
  const _Line(this.a, this.b, this.c);
  final Offset a;
  final Offset b;
  final Color c;
}

class _ScanHeroState extends State<ScanHero> with SingleTickerProviderStateMixin {
  late final AnimationController _in =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..forward();
  final GlobalKey _stack = GlobalKey();
  final GlobalKey _pill = GlobalKey();
  final List<GlobalKey> _chips = List<GlobalKey>.generate(6, (_) => GlobalKey());
  List<_Line> _lines = const [];
  String _sig = '';

  static const List<List<double>> _slots = [
    [1, 0.26], [0, 0.26], [1, 0.74], [0, 0.74], [1, 0.89], [0, 0.89], // 1 = ڕاست، 0 = چەپ
  ];

  @override
  void initState() {
    super.initState();
    // پێکهاتەکان لە کاتی دەرکەوتندا بچووکترن؛ دوای تەواوبوون هێڵەکان ڕاست دەکرێنەوە
    _in.addStatusListener((s) {
      if (s == AnimationStatus.completed) _measure();
    });
  }

  @override
  void dispose() {
    _in.dispose();
    super.dispose();
  }

  void _measure() {
    if (!mounted) return;
    final sb = _stack.currentContext?.findRenderObject();
    final pb = _pill.currentContext?.findRenderObject();
    if (sb is! RenderBox || pb is! RenderBox || !sb.hasSize || !pb.hasSize) return;
    Rect rectOf(RenderBox b) =>
        Rect.fromPoints(b.localToGlobal(Offset.zero, ancestor: sb), b.localToGlobal(b.size.bottomRight(Offset.zero), ancestor: sb));
    final pr = rectOf(pb);
    final out = <_Line>[];
    final n = annoList(widget.r).length;
    for (int j = 0; j < n && j < 6; j++) {
      final cb = _chips[j].currentContext?.findRenderObject();
      if (cb is! RenderBox || !cb.hasSize) continue;
      final cr = rectOf(cb);
      final right = _slots[j][0] == 1;
      final x1 = right ? cr.left : cr.right;
      final y1 = cr.center.dy;
      final dx = math.min(40.0, (pr.center.dx - x1).abs() * 0.45);
      final x2 = (x1 + (right ? -dx : dx)).clamp(pr.left + 14, math.max(pr.left + 14, pr.right - 14));
      final y2 = y1 < pr.center.dy ? pr.top - 4 : pr.bottom + 4;
      out.add(_Line(Offset(x1, y1), Offset(x2.toDouble(), y2), kACol[j % 6]));
    }
    final sig = out.map((l) => '${l.a.dx.round()},${l.a.dy.round()},${l.b.dx.round()},${l.b.dy.round()}').join('|');
    if (sig != _sig) {
      setState(() {
        _sig = sig;
        _lines = out;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
    final r = widget.r;
    final t = r.totals;
    final annos = annoList(r);
    final one = r.items.length == 1;
    final it0 = r.items.first;
    final sub = one ? '${nf(it0.n)} ${it0.unit} · ≈ ${fmt(t.g)}g' : '${t.act} جۆر خواردن · ≈ ${fmt(t.g)}g';
    return AspectRatio(
      aspectRatio: 1 / 0.86,
      child: LayoutBuilder(
        builder: (context, cons) {
          final w = cons.maxWidth, h = cons.maxHeight;
          return ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: Stack(
              key: _stack,
              children: [
                Positioned.fill(
                  child: widget.image != null
                      ? TweenAnimationBuilder<double>(
                          tween: Tween<double>(begin: 1.1, end: 1),
                          duration: const Duration(milliseconds: 900),
                          curve: Curves.easeOutCubic,
                          builder: (context, s, child) => Transform.scale(scale: s, child: child),
                          child: Image(
                            image: widget.image!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, e, st) => _placeholder(r.emoji),
                          ),
                        )
                      : _placeholder(r.emoji),
                ),
                const Positioned.fill(
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: Alignment(0, 0.1),
                          radius: 0.85,
                          colors: [Color(0x1F020E12), Color(0x9E020E12)],
                        ),
                      ),
                    ),
                  ),
                ),
                const Positioned.fill(
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0x8C020E12), Color(0x00020E12)],
                          stops: [0, 0.26],
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: IgnorePointer(
                    child: AnimatedBuilder(
                      animation: _in,
                      builder: (context, _) => CustomPaint(painter: _LinePainter(_lines, _in.value)),
                    ),
                  ),
                ),
                // ✕
                Positioned(
                  top: 12,
                  left: 12,
                  child: Semantics(
                    button: true,
                    label: 'داخستن',
                    child: Press(
                      onTap: widget.onClose,
                      child: _glass(
                        const SizedBox(width: 40, height: 40, child: Center(child: VText('✕', style: TextStyle(fontSize: 16, color: Colors.white)))),
                        radius: 20,
                      ),
                    ),
                  ),
                ),
                // دڵنیایی
                Positioned(
                  top: 12,
                  right: 12,
                  child: _glass(
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: V.mint,
                              boxShadow: [BoxShadow(color: V.mint, blurRadius: 8)],
                            ),
                          ),
                          const SizedBox(width: 6),
                          VText.rich(
                            TextSpan(children: [
                              const TextSpan(text: 'دڵنیایی '),
                              nspan('${r.confidence}%', size: 12),
                            ]),
                            style: ku(12, w: FontWeight.w700, c: Colors.white),
                          ),
                        ],
                      ),
                    ),
                    radius: 99,
                  ),
                ),
                // پێکهاتەکان
                for (int j = 0; j < annos.length && j < 6; j++)
                  Positioned(
                    top: h * _slots[j][1],
                    right: _slots[j][0] == 1 ? 12 : null,
                    left: _slots[j][0] == 0 ? 12 : null,
                    child: FractionalTranslation(
                      translation: const Offset(0, -0.5),
                      child: AnimatedBuilder(
                        animation: _in,
                        builder: (context, child) {
                          final p = ((_in.value * 1500 - 450 - j * 120) / 450).clamp(0.0, 1.0);
                          final e = Curves.easeOutBack.transform(p);
                          return Opacity(opacity: p, child: Transform.scale(scale: 0.8 + 0.2 * e, child: child));
                        },
                        child: ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: w / 2 - 18),
                          child: _Chip(
                            key: _chips[j],
                            a: annos[j],
                            color: kACol[j % 6],
                            kcal: annos[j].i != null ? r.items[annos[j].i!].kcal * r.items[annos[j].i!].q : null,
                            off: annos[j].i != null && r.items[annos[j].i!].n <= 0,
                          ),
                        ),
                      ),
                    ),
                  ),
                // ناوی خواردن لە ناوەڕاست
                Positioned.fill(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: w - 44),
                      child: TweenAnimationBuilder<double>(
                        tween: Tween<double>(begin: 0, end: 1),
                        duration: const Duration(milliseconds: 550),
                        curve: Curves.easeOutBack,
                        builder: (context, v, child) => Opacity(
                          opacity: v.clamp(0.0, 1.0),
                          child: Transform.scale(scale: 0.92 + 0.08 * v, child: child),
                        ),
                        child: _glass(
                          Padding(
                            key: _pill,
                            padding: const EdgeInsetsDirectional.fromSTEB(7, 6, 12, 6),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 34,
                                  height: 34,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(shape: BoxShape.circle, color: RC2.white(0.1)),
                                  child: VText(r.emoji, style: const TextStyle(fontSize: 19)),
                                ),
                                const SizedBox(width: 9),
                                Flexible(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      VText(r.name,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: ku(14, w: FontWeight.w800, c: Colors.white, h: 1.35)),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        children: [
                                          TweenAnimationBuilder<double>(
                                            tween: Tween<double>(end: t.k),
                                            duration: const Duration(milliseconds: 900),
                                            curve: Curves.easeOutCubic,
                                            builder: (context, v, _) => VText.rich(
                                              TextSpan(children: [
                                                TextSpan(text: fmt(v), style: nu(18, c: const Color(0xFFFFE3CC), h: 1.1)),
                                                TextSpan(text: ' kcal', style: nu(10.5, w: FontWeight.w700, c: V.mu)),
                                              ]),
                                              textDirection: TextDirection.ltr,
                                            ),
                                          ),
                                          const SizedBox(width: 7),
                                          Flexible(
                                            child: VText(sub,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: ku(11, c: kSoft, h: 1.3)),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          radius: 18,
                          strong: true,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _placeholder(String e) => Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0B3442), Color(0xFF04202A)],
          ),
        ),
        alignment: Alignment.center,
        child: VText(e, style: const TextStyle(fontSize: 96)),
      );
}

Widget _glass(Widget child, {double radius = 18, bool strong = false}) {
  return ClipRRect(
    borderRadius: BorderRadius.circular(radius),
    child: BackdropFilter(
      filter: ui.ImageFilter.blur(sigmaX: strong ? 14 : 10, sigmaY: strong ? 14 : 10),
      child: Container(
        decoration: BoxDecoration(
          color: Color.fromRGBO(3, 22, 28, strong ? 0.74 : 0.62),
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: RC2.white(strong ? 0.18 : 0.14)),
        ),
        child: child,
      ),
    ),
  );
}

class RC2 {
  RC2._();
  static Color white(double a) => Color.fromRGBO(255, 255, 255, a);
  static Color line(double a) => Color.fromRGBO(140, 235, 245, a);
}

class _Chip extends StatelessWidget {
  const _Chip({super.key, required this.a, required this.color, this.kcal, this.off = false});
  final Anno a;
  final Color color;
  final double? kcal;
  final bool off;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 250),
      opacity: off ? 0.35 : 1,
      child: Container(
        padding: const EdgeInsetsDirectional.fromSTEB(4, 3, 9, 3),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(99),
          color: const Color(0xC703161C),
          border: Border.all(color: op(color, 0.65)),
          boxShadow: const [BoxShadow(color: Color(0x99000000), blurRadius: 18, offset: Offset(0, 6), spreadRadius: -8)],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 21,
              height: 21,
              alignment: Alignment.center,
              decoration: BoxDecoration(shape: BoxShape.circle, color: op(color, 0.22)),
              child: VText(a.e, style: const TextStyle(fontSize: 12, height: 1)),
            ),
            const SizedBox(width: 5),
            Flexible(
              child: VText(a.t,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: ku(11.5, w: FontWeight.w800, c: Colors.white, h: 1.3)),
            ),
            if (kcal != null) ...[
              const SizedBox(width: 5),
              VText(fmt(kcal!), style: nu(11, w: FontWeight.w700, c: color)),
            ],
          ],
        ),
      ),
    );
  }
}

class _LinePainter extends CustomPainter {
  _LinePainter(this.lines, this.t);
  final List<_Line> lines;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    for (int j = 0; j < lines.length; j++) {
      final p = ((t * 1500 - 500 - j * 120) / 500).clamp(0.0, 1.0);
      if (p <= 0) continue;
      final l = lines[j];
      final path = Path()
        ..moveTo(l.a.dx, l.a.dy)
        ..quadraticBezierTo(l.b.dx, l.a.dy, l.b.dx, l.b.dy);
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..strokeCap = StrokeCap.round
        ..color = op(l.c, 0.9 * p);
      for (final m in path.computeMetrics()) {
        double d = 0;
        while (d < m.length) {
          canvas.drawPath(m.extractPath(d, math.min(d + 3, m.length)), paint);
          d += 7;
        }
      }
      canvas.drawCircle(l.b, 3.2, Paint()..color = op(l.c, p));
    }
  }

  @override
  bool shouldRepaint(_LinePainter o) => o.t != t || o.lines != lines;
}

// =====================================================================
//  «ئەوەی خواردت»: بڕ، زیادکردنی خێرا، تێبینی
// =====================================================================
class ItemsCard extends StatefulWidget {
  const ItemsCard({
    super.key,
    required this.r,
    required this.onStep,
    required this.onSet,
    required this.onAddOn,
    required this.onCustom,
    required this.onRecalc,
    required this.recalcBusy,
    this.onMore,
  });
  final ScanResult r;

  /// «🔎 خواردنی تر» ← لیستی خواردنەکان
  final VoidCallback? onMore;
  final void Function(int i, int d) onStep;
  final void Function(int i, double v) onSet;
  final void Function(AddOn a) onAddOn;
  final String? Function(String name, String kcal) onCustom;
  final void Function(String note) onRecalc;
  final bool recalcBusy;

  @override
  State<ItemsCard> createState() => _ItemsCardState();
}

class _ItemsCardState extends State<ItemsCard> {
  late final TextEditingController _note = TextEditingController(text: widget.r.note);
  final TextEditingController _cn = TextEditingController();
  final TextEditingController _ck = TextEditingController();
  final FocusNode _cnF = FocusNode();
  final FocusNode _ckF = FocusNode();
  late bool _noteOpen = widget.r.note.isNotEmpty;
  bool _customOpen = false;

  @override
  void dispose() {
    _note.dispose();
    _cn.dispose();
    _ck.dispose();
    _cnF.dispose();
    _ckF.dispose();
    super.dispose();
  }

  List<String> get _noteParts =>
      _note.text.split(RegExp(r'[،,\n]+')).map((s) => s.trim()).where((s) => s.isNotEmpty).toList();

  void _toggleChip(String c) {
    final l = _noteParts;
    if (l.contains(c)) {
      l.remove(c);
    } else {
      l.add(c);
    }
    setState(() => _note.text = l.join('، '));
    HapticFeedback.selectionClick();
  }

  void _custom() {
    if (_cn.text.trim().length < 2) {
      _cnF.requestFocus();
      return;
    }
    final err = widget.onCustom(_cn.text.trim(), _ck.text.trim());
    if (err == null) {
      setState(() {
        _cn.clear();
        _ck.clear();
        _customOpen = false;
      });
      FocusManager.instance.primaryFocus?.unfocus();
    } else {
      toast(err);
      _ckF.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.r;
    final one = r.items.length == 1;
    final chips = noteChips(r);
    final noteTxt = _note.text.trim();
    final canRe = noteTxt.isNotEmpty && !(r.noteOk && noteTxt == r.note.trim()) && !widget.recalcBusy;
    return SCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              lab('ئەوەی خواردت'),
              const Spacer(),
              VText(one ? 'ژمارەکە ڕاست بکەرەوە' : 'بڕی هەر یەکێک ڕاست بکەرەوە',
                  style: ku(11.5, w: FontWeight.w700, c: kDim)),
            ],
          ),
          for (int i = 0; i < r.items.length; i++) _row(i, r.items[i]),
          if (!one)
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), color: RC2.white(0.04), border: Border.all(color: V.line)),
              child: Row(
                children: [
                  VText('کۆی گشتی', style: ku(13, w: FontWeight.w800)),
                  const Spacer(),
                  VText.rich(TextSpan(children: [
                    TextSpan(text: fmt(r.totals.k), style: nu(17)),
                    TextSpan(text: ' kcal', style: nu(11, w: FontWeight.w600, c: V.mu)),
                  ]), textDirection: TextDirection.ltr),
                ],
              ),
            ),
          // زیادکردنی خێرا
          _dash(),
          VText('➕ شتێکی ترت لەگەڵی خوارد؟', style: ku(12, w: FontWeight.w800, c: V.mu)),
          const SizedBox(height: 8),
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                if (widget.onMore != null) _pill('🔎 خواردنی تر', widget.onMore!, accent: true),
                for (final a in addOns()) _pill('${a.e} ${a.t}', () => widget.onAddOn(a)),
                _pill('✍️ بە دەست', () {
                  setState(() => _customOpen = !_customOpen);
                  if (_customOpen) Future<void>.delayed(const Duration(milliseconds: 80), () => _cnF.requestFocus());
                }, accent: widget.onMore == null, on: _customOpen),
              ],
            ),
          ),
          if (_customOpen)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _cn,
                      focusNode: _cnF,
                      maxLength: 40,
                      textInputAction: TextInputAction.next,
                      style: ku(15, w: FontWeight.w600),
                      cursorColor: V.cy,
                      decoration: _deco('ناوی خواردن یان خواردنەوە'),
                      onSubmitted: (_) => _ckF.requestFocus(),
                    ),
                  ),
                  const SizedBox(width: 6),
                  SizedBox(
                    width: 74,
                    child: TextField(
                      controller: _ck,
                      focusNode: _ckF,
                      maxLength: 4,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      textDirection: TextDirection.ltr,
                      textInputAction: TextInputAction.done,
                      style: nu(15, w: FontWeight.w700),
                      cursorColor: V.cy,
                      decoration: _deco('kcal'),
                      onSubmitted: (_) => _custom(),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Press(
                    onTap: _custom,
                    child: Container(
                      height: 44,
                      padding: const EdgeInsets.symmetric(horizontal: 13),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(13), gradient: V.prime),
                      child: VText('زیادکردن', style: ku(13, w: FontWeight.w800, c: V.ink)),
                    ),
                  ),
                ],
              ),
            ),
          // تێبینی
          _dash(),
          Press(
            onTap: () => setState(() => _noteOpen = !_noteOpen),
            child: Row(
              children: [
                VText('📝 تێبینی', style: ku(13, w: FontWeight.w800)),
                const SizedBox(width: 8),
                Expanded(
                  child: VText('بۆ نموونە: بێ پەنیر، ڕۆنی کەم',
                      maxLines: 1, overflow: TextOverflow.ellipsis, style: ku(11.5, c: kDim)),
                ),
                AnimatedRotation(
                  turns: _noteOpen ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(Icons.keyboard_arrow_down_rounded, color: V.mu, size: 22),
                ),
              ],
            ),
          ),
          if (_noteOpen) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final c in chips)
                  Press(
                    onTap: () => _toggleChip(c),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(99),
                        border: Border.all(color: _noteParts.contains(c) ? V.cy : V.line2),
                        color: _noteParts.contains(c) ? const Color(0x262FE6F3) : Colors.transparent,
                      ),
                      child: VText(c,
                          style: ku(12, w: FontWeight.w700, c: _noteParts.contains(c) ? V.tx : V.mu, h: 1.3)),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _note,
              minLines: 2,
              maxLines: 4,
              maxLength: 300,
              style: ku(15, h: 1.5),
              cursorColor: V.cy,
              decoration: _deco(
                  'بۆ نموونە: ${one ? '${nf(r.items.first.c0 + 1)} ${r.items.first.unit}م خوارد، ' : ''}${chips.length > 2 ? chips[2] : 'ڕۆنم کەم بەکارهێناوە'}'),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 8),
            Press(
              onTap: canRe
                  ? () {
                      FocusManager.instance.primaryFocus?.unfocus();
                      widget.onRecalc(noteTxt);
                    }
                  : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 11),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: canRe ? V.ai : null,
                  color: canRe ? null : RC2.white(0.06),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (widget.recalcBusy) ...[
                      const SizedBox(width: 15, height: 15, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                      const SizedBox(width: 8),
                    ],
                    VText(widget.recalcBusy ? 'AI حیسابی دەکاتەوە…' : '✨ بە پێی تێبینییەکە حیسابی بکەرەوە',
                        style: ku(13.5, w: FontWeight.w800, c: canRe || widget.recalcBusy ? Colors.white : kDim)),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _dash() => Container(
        margin: const EdgeInsets.symmetric(vertical: 10),
        height: 1,
        child: CustomPaint(painter: _DashLine()),
      );

  Widget _pill(String t, VoidCallback onTap, {bool accent = false, bool on = false}) => Padding(
        padding: const EdgeInsetsDirectional.only(end: 6),
        child: Press(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 11),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(99),
              color: RC2.white(0.04),
              border: Border.all(color: accent || on ? V.cy : V.line2),
            ),
            child: VText(t, style: ku(12.5, w: FontWeight.w700, c: accent || on ? V.c2 : V.tx, h: 1.2)),
          ),
        ),
      );

  InputDecoration _deco(String hint) => InputDecoration(
        hintText: vxTr(hint),
        hintStyle: ku(13.5, c: kDim),
        isDense: true,
        counterText: '',
        filled: true,
        fillColor: const Color(0x2E000000),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(13), borderSide: BorderSide(color: V.line2)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(13), borderSide: BorderSide(color: V.cy)),
      );

  Widget _row(int i, ScanItem it) {
    final k = it.q;
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 250),
      opacity: it.n <= 0 ? 0.42 : 1,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          border: i < widget.r.items.length - 1 ? Border(bottom: BorderSide(color: V.line)) : null,
        ),
        child: Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: kICol[i % 6],
                boxShadow: [BoxShadow(color: op(kICol[i % 6], 0.6), blurRadius: 8)],
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  VText(it.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: ku(14, w: FontWeight.w800, h: 1.4)),
                  VText.rich(
                    TextSpan(children: [
                      nspan(fmt(it.kcal * k), size: 12.5, c: const Color(0xFFDFF6F9), w: FontWeight.w700),
                      const TextSpan(text: ' kcal · '),
                      nspan('${fmt(it.grams * k)}g', size: 12.5, c: const Color(0xFFDFF6F9), w: FontWeight.w700),
                    ]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: ku(12, c: V.mu),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            QtyStepper(
              n: it.n,
              unit: it.unit,
              onMinus: () => widget.onStep(i, -1),
              onPlus: () => widget.onStep(i, 1),
              onSet: (v) => widget.onSet(i, v),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashLine extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = V.line2
      ..strokeWidth = 1;
    double x = 0;
    while (x < size.width) {
      canvas.drawLine(Offset(x, 0), Offset(math.min(x + 4, size.width), 0), p);
      x += 8;
    }
  }

  @override
  bool shouldRepaint(_DashLine o) => false;
}

/// − بڕ +  (ژمارەکەش دەنووسرێت)
class QtyStepper extends StatefulWidget {
  const QtyStepper({super.key, required this.n, required this.unit, required this.onMinus, required this.onPlus, required this.onSet});
  final double n;
  final String unit;
  final VoidCallback onMinus;
  final VoidCallback onPlus;
  final ValueChanged<double> onSet;

  @override
  State<QtyStepper> createState() => _QtyStepperState();
}

class _QtyStepperState extends State<QtyStepper> {
  late final TextEditingController _c = TextEditingController(text: nf(widget.n));
  final FocusNode _f = FocusNode();

  @override
  void initState() {
    super.initState();
    _f.addListener(() {
      if (_f.hasFocus) {
        _c.selection = TextSelection(baseOffset: 0, extentOffset: _c.text.length);
      } else {
        _commit();
      }
    });
  }

  @override
  void didUpdateWidget(QtyStepper old) {
    super.didUpdateWidget(old);
    if (!_f.hasFocus && _c.text != nf(widget.n)) _c.text = nf(widget.n);
  }

  @override
  void dispose() {
    _c.dispose();
    _f.dispose();
    super.dispose();
  }

  void _commit() {
    if (!mounted) return;
    final v = parseQ(_c.text);
    if (v != null && v != widget.n) {
      widget.onSet(v);
    } else {
      _c.text = nf(widget.n);
    }
  }

  Widget _btn(String t, VoidCallback? onTap) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap == null
            ? null
            : () {
                HapticFeedback.selectionClick();
                onTap();
              },
        child: SizedBox(
          width: 34,
          height: 40,
          child: Center(child: VText(t, style: nu(20, w: FontWeight.w600, c: onTap == null ? const Color(0xFF35575E) : V.c2, h: 1))),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: const Color(0x2E000000),
        border: Border.all(color: V.line2),
      ),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _btn('−', widget.n <= 0 ? null : widget.onMinus),
            SizedBox(
              width: 46,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _c,
                    focusNode: _f,
                    textAlign: TextAlign.center,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    textInputAction: TextInputAction.done,
                    style: nu(17, h: 1.15),
                    cursorColor: V.cy,
                    decoration: const InputDecoration(isDense: true, border: InputBorder.none, contentPadding: EdgeInsets.zero),
                    onSubmitted: (_) => _f.unfocus(),
                  ),
                  VText(widget.unit,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textDirection: TextDirection.rtl,
                      style: ku(10.5, w: FontWeight.w700, c: V.mu, h: 1.3)),
                ],
              ),
            ),
            _btn('+', widget.n >= 50 ? null : widget.onPlus),
          ],
        ),
      ),
    );
  }
}

// =====================================================================
//  پێکهاتەی خۆراک — تەنها ئەوانەی لە خواردنەکەدا هەن
// =====================================================================
class NutCard extends StatelessWidget {
  const NutCard({super.key, required this.t, required this.budget, required this.pro, required this.carb, required this.fat});
  final ScanTotals t;
  final double budget;
  final double pro;
  final double carb;
  final double fat;

  @override
  Widget build(BuildContext context) {
    final rows = <List<dynamic>>[
      ['💪', 'پڕۆتین', t.p, pro, kPro, 0.5],
      ['🌾', 'کارب', t.c, carb, kCarb, 0.5],
      ['🥑', 'چەوری', t.f, fat, kFat, 0.5],
      ['🥦', 'ڕیشاڵ', t.fib, 30.0, V.mint, 0.5],
      ['🍬', 'شەکر', t.sug, 50.0, const Color(0xFFFF8FC8), 0.5],
      ['🧂', 'خوێ', t.sod * 2.5 / 1000, 5.0, V.c2, 0.1],
    ].where((x) => (x[2] as double) >= (x[5] as double)).toList();
    final kp = budget > 0 ? (t.k / budget * 100).round() : 0;
    final pk = t.p * 4, ck = t.c * 4, fk = t.f * 9, tk = pk + ck + fk;
    final cols = rows.length == 1 ? 1 : (rows.length == 2 || rows.length == 4 ? 2 : 3);
    final chunks = <List<List<dynamic>>>[];
    for (int i = 0; i < rows.length; i += cols) {
      chunks.add(rows.sublist(i, math.min(rows.length, i + cols)));
    }
    return SCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              lab('پێکهاتەی خۆراک'),
              const SizedBox(width: 10),
              Expanded(
                child: VText.rich(
                  TextSpan(children: [
                    if (t.g > 0) ...[nspan('${fmt(t.g)}g', size: 12, c: V.mu, w: FontWeight.w700), const TextSpan(text: ' · ')],
                    nspan('$kp%', size: 12, c: V.mu, w: FontWeight.w700),
                    const TextSpan(text: ' ی ڕۆژت'),
                  ]),
                  textAlign: TextAlign.end,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: ku(12, w: FontWeight.w700, c: V.mu),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(9),
            child: Container(
              height: 10,
              color: RC2.white(0.06),
              child: tk <= 0
                  ? null
                  : Directionality(
                      textDirection: TextDirection.ltr,
                      child: Row(
                        children: [
                          for (final x in [
                            [pk, kPro],
                            [ck, kCarb],
                            [fk, kFat],
                          ])
                            if ((x[0] as double) > 0)
                              Expanded(
                                flex: math.max(1, ((x[0] as double) / tk * 1000).round()),
                                child: Container(margin: const EdgeInsets.symmetric(horizontal: 1), color: x[1] as Color),
                              ),
                        ],
                      ),
                    ),
            ),
          ),
          for (final ch in chunks)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  for (int i = 0; i < ch.length; i++) ...[
                    if (i > 0) const SizedBox(width: 8),
                    Expanded(child: _tile(ch[i])),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _tile(List<dynamic> x) {
    final v = x[2] as double, ref = x[3] as double, k = x[4] as Color;
    final pct = ref > 0 ? (v / ref * 100).round() : 0;
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 7),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: RC2.white(0.045),
        border: Border.all(color: op(k, 0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          VText('${x[0]} ${x[1]}', maxLines: 1, overflow: TextOverflow.ellipsis, style: ku(12, w: FontWeight.w700, c: V.mu)),
          const SizedBox(height: 2),
          VText.rich(
            TextSpan(children: [
              TextSpan(text: gTxt(v), style: nu(17)),
              TextSpan(text: ' g', style: nu(11, w: FontWeight.w600, c: V.mu)),
            ]),
            textDirection: TextDirection.ltr,
            textAlign: TextAlign.right,
          ),
          const SizedBox(height: 5),
          ClipRRect(
            borderRadius: BorderRadius.circular(9),
            child: SizedBox(
              height: 4,
              child: Stack(
                children: [
                  Positioned.fill(child: ColoredBox(color: RC2.white(0.07))),
                  Directionality(
                    textDirection: TextDirection.ltr,
                    child: TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0, end: (pct / 100).clamp(0.0, 1.0)),
                      duration: const Duration(milliseconds: 700),
                      curve: Curves.easeOutCubic,
                      builder: (context, f, _) => FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: f,
                        child: ColoredBox(color: k),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 5),
          VText.rich(
            TextSpan(children: [nspan('$pct%', size: 10.5, c: V.mu, w: FontWeight.w700), const TextSpan(text: ' ی ڕۆژت')]),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: ku(10.5, w: FontWeight.w700, c: V.mu),
          ),
        ],
      ),
    );
  }
}

// =====================================================================
//  گونجان بۆ تۆ
// =====================================================================
class VerdictCard extends StatelessWidget {
  const VerdictCard({super.key, required this.r, required this.live});
  final ScanResult r;
  final LiveScore live;

  @override
  Widget build(BuildContext context) {
    final v = kVerd[live.v] ?? kVerd['ok']!;
    return SCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              SizedBox(
                width: 62,
                height: 62,
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(end: live.s.toDouble()),
                  duration: const Duration(milliseconds: 1100),
                  curve: Curves.easeOutCubic,
                  builder: (context, s, _) => CustomPaint(
                    painter: _Ring(s / 100, v.c),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          VText('${s.round()}', style: nu(19, h: 1)),
                          VText('/100', style: nu(8.5, w: FontWeight.w600, c: V.mu, h: 1.2)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    lab('گونجان بۆ تۆ، ئێستا'),
                    AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 300),
                      style: ku(15.5, w: FontWeight.w800, c: v.c, h: 1.5),
                      child: VText('${v.e} ${v.t}', maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                    if (r.noteOk)
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(99),
                          color: const Color(0x1F3CF08A),
                          border: Border.all(color: const Color(0x663CF08A)),
                        ),
                        child: VText('✓ تێبینییەکەت حیساب کرا', style: ku(11, w: FontWeight.w800, c: V.mint)),
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (r.summary.isNotEmpty) ...[
            Container(
              margin: const EdgeInsets.only(top: 10, bottom: 8),
              height: 1,
              child: CustomPaint(painter: _DashLine()),
            ),
            VText(r.summary, style: ku(12.5, c: const Color(0xFFD6E8EC), h: 1.7)),
          ],
        ],
      ),
    );
  }
}

class _Ring extends CustomPainter {
  _Ring(this.p, this.c);
  final double p;
  final Color c;

  @override
  void paint(Canvas canvas, Size size) {
    final ctr = size.center(Offset.zero);
    final r = size.width / 2 - 4;
    canvas.drawCircle(
      ctr,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7
        ..color = RC2.white(0.08),
    );
    if (p <= 0) return;
    final rect = Rect.fromCircle(center: ctr, radius: r);
    canvas.drawArc(
      rect,
      -math.pi / 2,
      math.pi * 2 * p.clamp(0.0, 1.0),
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7
        ..strokeCap = StrokeCap.round
        ..color = c,
    );
  }

  @override
  bool shouldRepaint(_Ring o) => o.p != p || o.c != c;
}

// =====================================================================
//  لە ڕۆژەکەتدا
// =====================================================================
class DayCard extends StatelessWidget {
  const DayCard({super.key, required this.eaten, required this.meal, required this.budget, required this.color, required this.kpm});
  final double eaten;
  final double meal;
  final double budget;
  final Color color;
  final double kpm;

  @override
  Widget build(BuildContext context) {
    final after = budget - eaten - meal;
    final fe = budget > 0 ? (eaten / budget).clamp(0.0, 1.0) : 0.0;
    final fm = budget > 0 ? (meal / budget).clamp(0.0, 1.0 - fe) : 0.0;
    final k = after < 0 ? const Color(0xFFFF8A5F) : color;
    final InlineSpan note;
    if (meal <= 0) {
      note = const TextSpan(text: 'هیچ خواردنێک دیاری نەکراوە.');
    } else if (after >= 0) {
      note = TextSpan(children: [
        const TextSpan(text: 'دوای ئەم ژەمە '),
        nspan(fmt(after), size: 13),
        const TextSpan(text: ' کالۆریت ماوە بۆ ئەمڕۆ 👍'),
      ]);
    } else {
      note = TextSpan(children: [
        const TextSpan(text: 'ئەم ژەمە '),
        nspan(fmt(-after), size: 13),
        TextSpan(text: ' کالۆری لە ئامانجی ئەمڕۆ زیاتر دەکات. پیاسەیەکی ${durTxt(-after / kpm)}ی هاوسەنگی دەکاتەوە.'),
      ]);
    }
    Widget leg(Color c, String t, double v) => Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(width: 8, height: 8, decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(3))),
                  const SizedBox(width: 5),
                  Flexible(child: VText(t, maxLines: 1, overflow: TextOverflow.ellipsis, style: ku(11.5, w: FontWeight.w700, c: V.mu))),
                ],
              ),
              VText(fmt(v), textDirection: TextDirection.ltr, style: nu(15)),
            ],
          ),
        );
    return SCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          lab('لە ڕۆژەکەتدا'),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(9),
            child: SizedBox(
              height: 12,
              child: Directionality(
                textDirection: kDir,
                child: LayoutBuilder(
                  builder: (context, c) => Stack(
                    children: [
                      Positioned.fill(child: ColoredBox(color: RC2.white(0.07))),
                      AnimatedPositioned(
                        duration: const Duration(milliseconds: 500),
                        right: 0,
                        top: 0,
                        bottom: 0,
                        width: c.maxWidth * fe,
                        child: ColoredBox(color: V.cy),
                      ),
                      AnimatedPositioned(
                        duration: const Duration(milliseconds: 500),
                        right: c.maxWidth * fe,
                        top: 0,
                        bottom: 0,
                        width: c.maxWidth * fm,
                        child: ColoredBox(color: k),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              leg(V.cy, 'خواردووتە', eaten),
              leg(k, 'ئەم ژەمە', meal),
              leg(RC2.white(0.25), 'ئامانجی ڕۆژ', budget),
            ],
          ),
          Container(
            margin: const EdgeInsets.only(top: 10),
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: op(k, 0.08),
              border: Border.all(color: op(k, 0.3)),
            ),
            child: VText.rich(note, style: ku(12.5, c: const Color(0xFFDCEFF2), h: 1.7)),
          ),
        ],
      ),
    );
  }
}

// =====================================================================
//  پیاسە و هەرسکردن (کورت)
// =====================================================================
class WalkCard extends StatelessWidget {
  const WalkCard({super.key, required this.r, required this.t, required this.kpm});
  final ScanResult r;
  final ScanTotals t;
  final double kpm;

  @override
  Widget build(BuildContext context) {
    final wm = kpm > 0 ? t.k / kpm : 0.0;
    final has = t.k > 0;
    final s = math.pow(math.max(t.q, 0.05), 0.35).toDouble();
    final a = r.dmin * s, b = r.dmax * s;
    Widget row(String ic, Color bg, String label, String value, List<String> meta) => Row(
          children: [
            Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(13), color: bg),
              child: VText(ic, style: const TextStyle(fontSize: 19)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  VText(label, style: ku(11, w: FontWeight.w700, c: V.mu)),
                  VText(value, style: ku(14.5, w: FontWeight.w800, h: 1.5)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final m in meta)
                  VText(m, textDirection: TextDirection.ltr, style: nu(12, w: FontWeight.w700, c: m == meta.first ? V.tx : V.mu)),
              ],
            ),
          ],
        );
    return SCard(
      child: Column(
        children: [
          row('🚶', const Color(0x213CF08A), 'پیاسە بۆ سووتاندنی', has ? durTxt(wm) : '—',
              has ? ['👣 ${fmt((wm * 105 / 100).round() * 100)}', '${(wm * 5 / 60).toStringAsFixed(1)} km'] : []),
          Padding(padding: EdgeInsets.symmetric(vertical: 10), child: Divider(height: 1, color: V.line)),
          row('⏳', const Color(0x299B7BFF), 'کاتی هەرسکردن', has ? digTxt(a, b) : '—', has ? ['${clockAfter(b)} تا'] : []),
        ],
      ),
    );
  }
}
