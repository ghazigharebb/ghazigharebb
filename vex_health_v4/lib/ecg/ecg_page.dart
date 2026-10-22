// VEX Health — پەڕەی پێوانەی ECG (چاوەڕێی پەنجە ← پێوانەی زیندوو ← تەواو)
//
// بانگکردن لە هەر شوێنێک:   openEcgPage();
// شەپۆلەکە لە Band ی ڕاستەقینەوە دێت (lib/band/ble/vex_ble.dart). تا پەنجە دانەنرێت هێڵێکی ڕاستە؛
// دوای دانانی پەنجە شەپۆلەکە بەپێی دڵی خۆت دەجووڵێت.
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/icons.dart';
import '../core/theme.dart';
import '../core/vx_en.dart';
import '../health/detail_common.dart' show HCard;
import '../health/hc.dart';
import 'ecg_controller.dart';

void openEcgPage() => pushPage(const EcgPage());

// ئایکۆنی پەنجە (viewBox 24)
const String _kFinger =
    '<path d="M12 11a2 2 0 0 0-2 2c0 3 .5 5.5 1.5 7.5"/><path d="M8 14c0-2.2 1.8-4 4-4s4 1.8 4 4c0 2-.3 4-1 6"/>'
    '<path d="M5 14a7 7 0 0 1 14 0c0 2-.2 3.6-.6 5"/><path d="M8.5 5.2A7.5 7.5 0 0 1 20 11.5"/><path d="M3.5 10.5A8.5 8.5 0 0 1 6 6.5"/>';
const String _kCheck = '<path d="M5 12l5 5 9-10"/>';

Color get _mint => vk(0xFF5BE3A4);
Color get _amber => vk(0xFFFFB84D);
Color get _rose => vk(0xFFFF6B7F);

TextStyle _num(double size, {Color? c, FontWeight w = FontWeight.w800}) { c ??= HC.tx; return
    GoogleFonts.sora(fontSize: size, fontWeight: w, color: c, height: 1.0, letterSpacing: -1); }

class EcgPage extends StatefulWidget {
  const EcgPage({super.key});
  @override
  State<EcgPage> createState() => _EcgPageState();
}

class _EcgPageState extends State<EcgPage> with TickerProviderStateMixin {
  late final EcgController c = EcgController();
  late final AnimationController _spin = AnimationController(vsync: this, duration: const Duration(seconds: 6))..repeat();
  late final AnimationController _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600))..repeat(reverse: true);

  @override
  void initState() {
    super.initState();
    c.start();
  }

  @override
  void dispose() {
    _spin.dispose();
    _pulse.dispose();
    c.dispose();
    super.dispose();
  }

  Future<void> _close() async {
    await c.cancel();
    if (mounted) Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) c.cancel();
      },
      child: Scaffold(
        backgroundColor: HC.bg,
        body: Stack(children: [
          const Positioned.fill(child: HealthBg(radius: 1.1)),
          Positioned.fill(
            child: ListenableBuilder(
              listenable: c,
              builder: (context, _) => SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(20, mq.padding.top + 16, 20, mq.padding.bottom + 22),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: 430, minHeight: mq.size.height - mq.padding.vertical - 38),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                      _header(),
                      const SizedBox(height: 14),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 320),
                        child: KeyedSubtree(key: ValueKey(c.phase == EcgPhase.waiting || c.phase == EcgPhase.failed ? 0 : 1), child: _body()),
                      ),
                    ]),
                  ),
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  // ───────────── سەرەوە ─────────────
  Widget _header() {
    final (Color col, String txt) = switch (c.phase) {
      EcgPhase.waiting => (_amber, 'چاوەڕێی پەنجە'),
      EcgPhase.measuring => c.fingerLost ? (_amber, 'پەنجە لابرا') : (_mint, 'تۆمار دەکرێت'),
      EcgPhase.done => (_mint, 'تەواو بوو'),
      EcgPhase.failed => (_rose, 'سەرنەکەوت'),
    };
    return Row(children: [
      Press(
        onTap: _close,
        child: Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: HC.card, borderRadius: BorderRadius.circular(13), border: Border.all(color: HC.line)),
          child: svgIcon(HI.back, HX.tx, size: 18, stroke: 2.4),
        ),
      ),
      const SizedBox(width: 12),
      Expanded(child: VText('پێوانەی ECG', style: ku(22, w: FontWeight.w800, c: HC.tx, h: 1.4))),
      if (c.demo)
        Container(
          margin: const EdgeInsetsDirectional.only(end: 8),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(color: op(_amber, .16), borderRadius: BorderRadius.circular(99)),
          child: VText('نموونە', style: ku(10.5, w: FontWeight.w800, c: _amber)),
        ),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
        decoration: BoxDecoration(color: op(col, .12), borderRadius: BorderRadius.circular(99), border: Border.all(color: op(col, .4))),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 6, height: 6, decoration: BoxDecoration(color: col, shape: BoxShape.circle, boxShadow: [BoxShadow(color: op(col, .7), blurRadius: 6)])),
          const SizedBox(width: 6),
          VText(txt, style: ku(11.5, w: FontWeight.w700, c: col)),
        ]),
      ),
    ]);
  }

  Widget _body() => (c.phase == EcgPhase.waiting || c.phase == EcgPhase.failed) ? _waiting() : _measuring();

  // ───────────── شاشەی ٢: چاوەڕێی پەنجە ─────────────
  Widget _waiting() {
    final failed = c.phase == EcgPhase.failed;
    final col = failed ? _rose : _amber;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      SizedBox(
        height: 290,
        child: Center(
          child: SizedBox(
            width: 290,
            height: 290,
            child: AnimatedBuilder(
              animation: Listenable.merge([_spin, _pulse]),
              builder: (_, __) => CustomPaint(
                painter: _OrbPainter(_spin.value, _pulse.value, col, failed),
                child: Center(
                  child: Container(
                    width: 148,
                    height: 148,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(center: Alignment(-.3, -.4), colors: [vk(0xFF12586A), vk(0xFF082F3A)], stops: [0, .75]),
                      border: Border.all(color: op(HC.c2, .3)),
                      boxShadow: [BoxShadow(color: op(HC.c, .18), blurRadius: 50)],
                    ),
                    child: svgIcon(failed ? '<path d="M6 6l12 12M18 6L6 18"/>' : _kFinger, failed ? '#ff6b7f' : HX.c, size: 66, stroke: 1.7),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Column(children: [
          VText(failed ? c.failReason : 'پەنجەت لەسەر ئەلیکترۆدی Band دابنێ',
              textAlign: TextAlign.center, style: ku(19, w: FontWeight.w800, c: HC.tx, h: 1.6)),
          const SizedBox(height: 4),
          VText(failed ? 'دڵنیابە Band پەیوەستە و بلووتوس کراوەیە.' : 'ژماردنەوەی ${c.targetSeconds} چرکە دوای دۆزینەوەی پەنجە دەستپێدەکات.',
              textAlign: TextAlign.center, style: ku(12.5, c: HC.mu, h: 1.8)),
        ]),
      ),
      const SizedBox(height: 16),
      _traceCard(height: 96, header: false),
      const SizedBox(height: 14),
      HCard(
        top: 0,
        radius: 20,
        child: Column(children: [
          _tip('Band بە توندی لەسەر دەستت بێت، نە زۆر شل نە زۆر تەنگ.'),
          _tip('ئەگەر پەنجەکەت ساردە یان تەڕە، پێشتر وشکی بکەرەوە و گەرمی بکە.'),
          _tip('تۆمارکردن تەنها کاتێک پەنجە دۆزرایەوە دەستپێدەکات.', last: true),
        ]),
      ),
      const SizedBox(height: 16),
      if (failed) ...[
        _primary('دووبارە هەوڵ بدەوە', c.start),
        const SizedBox(height: 10),
      ],
      _ghost('هەڵوەشاندنەوە', _close),
      const SizedBox(height: 10),
      _disclaimer(),
    ]);
  }

  // ───────────── شاشەی ٣: پێوانە ─────────────
  Widget _measuring() {
    final done = c.phase == EcgPhase.done;
    final lost = c.fingerLost && !done;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      SizedBox(
        height: 250,
        child: Center(
          child: SizedBox(
            width: 250,
            height: 250,
            child: AnimatedBuilder(
              animation: c.frame,
              builder: (_, __) => CustomPaint(
                painter: _RingPainter(done ? 1 : c.progress, lost ? _amber : _mint),
                child: Center(child: done ? _doneCenter() : _countdown(lost)),
              ),
            ),
          ),
        ),
      ),
      const SizedBox(height: 14),
      _traceCard(height: 150, header: true),
      const SizedBox(height: 12),
      done ? _doneTiles() : _liveTiles(),
      const SizedBox(height: 12),
      VText(
        done
            ? 'ئەم ئەنجامە بۆ شوێنکەوتنی تەندروستیی گشتییە. ئەگەر نیگەرانیت هەیە، پەیوەندی بە دکتۆر بکە.'
            : (lost ? 'پەنجەت لەسەر ئەلیکترۆد بگەڕێنەوە. ژماردنەوە ڕاوەستاوە.' : 'بێجووڵە بمێنەوە و پەنجەکەت لەسەر ئەلیکترۆد بهێڵەوە. قسە مەکە.'),
        textAlign: TextAlign.center,
        style: ku(12.5, c: lost ? _amber : vk(0xFFCFEEF2), h: 1.8),
      ),
      const SizedBox(height: 16),
      if (done) ...[
        _primary('دووبارە', c.start),
        const SizedBox(height: 10),
        _ghost('داخستن', _close),
      ] else
        _danger('وەستاندنی پێوانە', _close),
      const SizedBox(height: 10),
      _disclaimer(),
    ]);
  }

  Widget _countdown(bool lost) => Column(mainAxisSize: MainAxisSize.min, children: [
        ShaderMask(
          shaderCallback: (r) => LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [vk(0xFFEAFFFF), vk(0xFF8FF3F9)]).createShader(r),
          child: Text('${c.secondsLeft}', style: _num(80, c: kW)),
        ),
        const SizedBox(height: 6),
        VText(lost ? 'ڕاوەستاوە' : 'چرکە ماوە', style: ku(13, c: lost ? _amber : HC.mu)),
      ]);

  Widget _doneCenter() {
    final r = c.result;
    final b = r?.bpm;
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(color: op(_mint, .18), shape: BoxShape.circle, border: Border.all(color: op(_mint, .6))),
        child: Center(child: svgIcon(_kCheck, HX.ok, size: 16, stroke: 3)),
      ),
      const SizedBox(height: 8),
      Text(b == null ? '—' : '${b.round()}', style: _num(64, c: HC.tx)),
      const SizedBox(height: 4),
      Text('bpm', style: GoogleFonts.sora(fontSize: 13, fontWeight: FontWeight.w700, color: HC.mu)),
    ]);
  }

  // ───────────── کارتی شەپۆل ─────────────
  Widget _traceCard({required double height, required bool header}) {
    return Container(
      decoration: BoxDecoration(
        color: vk(0xFF03141A),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: op(HC.c2, .2)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: [
        if (header)
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: AnimatedBuilder(
                animation: c.frame,
                builder: (_, __) {
                  final b = c.phase == EcgPhase.done ? c.result?.bpm : c.sig.bpm;
                  return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text(c.phase == EcgPhase.done ? 'RECORDED' : 'LIVE', style: GoogleFonts.sora(fontSize: 11, fontWeight: FontWeight.w700, color: HC.mu, letterSpacing: 1.2)),
                    Row(children: [
                      AnimatedBuilder(
                        animation: _pulse,
                        builder: (_, __) => Transform.scale(
                          scale: b == null ? 1 : 1 + .22 * (c.sig.beatCount.isEven ? _pulse.value : 1 - _pulse.value),
                          child: svgIcon(HI.heartFill, '#ff6b7f', size: 13, fill: true),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(b == null ? '-- bpm' : '${b.round()} bpm', style: GoogleFonts.sora(fontSize: 13, fontWeight: FontWeight.w800, color: _rose)),
                    ]),
                  ]);
                },
              ),
            ),
          ),
        SizedBox(
          height: height,
          width: double.infinity,
          child: AnimatedBuilder(
            animation: c.frame,
            builder: (_, __) {
              final done = c.phase == EcgPhase.done;
              final data = done ? (c.result?.trace ?? const <double>[]) : c.sig.disp;
              final live = c.sig.contact() || done || (c.demo && c.phase == EcgPhase.measuring);
              return CustomPaint(painter: _TracePainter(data, live: live, frozen: done, tick: c.frame.value));
            },
          ),
        ),
      ]),
    );
  }

  // ───────────── کارتە بچووکەکان ─────────────
  Widget _liveTiles() {
    return AnimatedBuilder(
      animation: c.frame,
      builder: (_, __) {
        final q = c.sig.quality;
        final (String ql, Color qc) = q > .75 ? ('باش', _mint) : (q > .4 ? ('مامناوەند', _amber) : ('لاواز', _rose));
        final contact = c.sig.contact();
        return Row(children: [
          Expanded(child: _tile('کوالیتی ئاماژە', _bars(q, qc), ql, qc)),
          const SizedBox(width: 10),
          Expanded(child: _tile('پەیوەندی', svgIcon('<circle cx="12" cy="12" r="3"/><path d="M12 3v3M12 18v3M3 12h3M18 12h3"/>', contact ? HX.c : HX.wn, size: 24, stroke: 2.2), contact ? 'جێگیر' : 'لاواز', contact ? HC.c : _amber)),
          const SizedBox(width: 10),
          Expanded(child: _tile('پێشکەوتن', Text('${(c.progress * 100).round()}%', style: _num(26)), '', HC.tx)),
        ]);
      },
    );
  }

  Widget _doneTiles() {
    final r = c.result;
    final q = r?.quality ?? 0;
    final (String ql, Color qc) = q > .75 ? ('باش', _mint) : (q > .4 ? ('مامناوەند', _amber) : ('لاواز', _rose));
    return Row(children: [
      Expanded(child: _tile('HRV', Text(r?.hrv == null ? '—' : '${r!.hrv}', style: _num(26)), r?.hrv == null ? '' : 'ms', HC.c)),
      const SizedBox(width: 10),
      Expanded(child: _tile('سترێس', Text(r?.stress == null ? '—' : '${r!.stress}', style: _num(26)), '', _amber)),
      const SizedBox(width: 10),
      Expanded(child: _tile('کوالیتی', _bars(q, qc), ql, qc)),
    ]);
  }

  Widget _tile(String title, Widget mid, String sub, Color subCol) => Container(
        height: 108,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        decoration: BoxDecoration(color: op(kW, .045), borderRadius: BorderRadius.circular(18), border: Border.all(color: HC.line)),
        child: Column(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          VText(title, textAlign: TextAlign.center, style: ku(11, w: FontWeight.w700, c: HC.mu)),
          SizedBox(height: 28, child: Center(child: mid)),
          SizedBox(height: 18, child: sub.isEmpty ? null : VText(sub, style: ku(13, w: FontWeight.w800, c: subCol))),
        ]),
      );

  Widget _bars(double q, Color col) {
    final lv = q > .75 ? 4 : (q > .55 ? 3 : (q > .25 ? 2 : (q > 0 ? 1 : 0)));
    return Row(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.end, children: [
      for (var i = 0; i < 4; i++)
        Container(
          width: 5,
          height: 7.0 + i * 5,
          margin: const EdgeInsets.symmetric(horizontal: 1.5),
          decoration: BoxDecoration(color: i < lv ? col : op(kW, .16), borderRadius: BorderRadius.circular(2)),
        ),
    ]);
  }

  // ───────────── دوگمە و دەق ─────────────
  Widget _primary(String t, VoidCallback onTap) => Press(
        onTap: onTap,
        scale: .98,
        child: Container(
          height: 54,
          alignment: Alignment.center,
          decoration: BoxDecoration(gradient: V.prime, borderRadius: BorderRadius.circular(99), boxShadow: [BoxShadow(color: op(HC.c, .25), blurRadius: 26, offset: const Offset(0, 8))]),
          child: VText(t, style: ku(16, w: FontWeight.w800, c: HC.ink)),
        ),
      );

  Widget _ghost(String t, VoidCallback onTap) => Press(
        onTap: onTap,
        scale: .98,
        child: Container(
          height: 52,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: op(kW, .05), borderRadius: BorderRadius.circular(99), border: Border.all(color: op(HC.c2, .28))),
          child: VText(t, style: ku(16, w: FontWeight.w800, c: HC.tx)),
        ),
      );

  Widget _danger(String t, VoidCallback onTap) => Press(
        onTap: onTap,
        scale: .98,
        child: Container(
          height: 52,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: op(_rose, .08), borderRadius: BorderRadius.circular(99), border: Border.all(color: op(_rose, .4))),
          child: VText(t, style: ku(16, w: FontWeight.w800, c: vk(0xFFFF8FA0))),
        ),
      );

  Widget _tip(String t, {bool last = false}) => Padding(
        padding: EdgeInsets.only(bottom: last ? 0 : 10),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(padding: const EdgeInsets.only(top: 5), child: svgIcon(_kCheck, HX.ok, size: 14, stroke: 2.6)),
          const SizedBox(width: 10),
          Expanded(child: VText(t, style: ku(12.5, c: vk(0xFFCFEEF2), h: 1.8))),
        ]),
      );

  Widget _disclaimer() => VText(
        'ئەم پێوانەیە بۆ شوێنکەوتنی تەندروستیی گشتییە و بۆ دەستنیشانکردنی نەخۆشی نییە.',
        textAlign: TextAlign.center,
        style: ku(10.5, c: HC.nd, h: 1.8),
      );
}

// ═════════════ پەینتەرەکان ═════════════

/// بازنەی گەورەی چاوەڕێکردن
class _OrbPainter extends CustomPainter {
  _OrbPainter(this.rot, this.pulse, this.col, this.failed);
  final double rot, pulse;
  final Color col;
  final bool failed;

  @override
  void paint(Canvas canvas, Size s) {
    final c = Offset(s.width / 2, s.height / 2);
    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(c, 138, base..color = op(HC.c, .08));
    // خاڵخاڵ
    final dash = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = op(HC.c, .16);
    const n = 64;
    for (var i = 0; i < n; i++) {
      final a = i * 2 * math.pi / n;
      canvas.drawArc(Rect.fromCircle(center: c, radius: 115), a, .025, false, dash);
    }
    // لێدانی نەرم
    final pr = 92 + 8 * pulse;
    canvas.drawCircle(c, pr, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = op(col, .35 * (1 - pulse) + .1));
    canvas.drawCircle(c, 92, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = op(HC.c, .28));
    if (!failed) {
      final arc = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.4
        ..strokeCap = StrokeCap.round
        ..color = col;
      canvas.drawArc(Rect.fromCircle(center: c, radius: 92), rot * 2 * math.pi - 1.2, 1.25, false, arc);
    }
  }

  @override
  bool shouldRepaint(covariant _OrbPainter o) => o.rot != rot || o.pulse != pulse || o.col != col || o.failed != failed;
}

/// بازنەی ژماردنەوە
class _RingPainter extends CustomPainter {
  _RingPainter(this.p, this.col);
  final double p;
  final Color col;

  @override
  void paint(Canvas canvas, Size s) {
    final c = Offset(s.width / 2, s.height / 2);
    final r = s.width / 2 - 16;
    final rect = Rect.fromCircle(center: c, radius: r);
    canvas.drawCircle(c, r, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..color = op(kW, .07));
    canvas.drawCircle(c, r - 22, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = op(HC.c, .14));
    if (p <= 0) return;
    final sw = 2 * math.pi * p;
    canvas.drawArc(rect, -math.pi / 2, sw, false, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 20
      ..strokeCap = StrokeCap.round
      ..color = op(col, .28)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7));
    canvas.drawArc(rect, -math.pi / 2, sw, false, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round
      ..color = col);
  }

  @override
  bool shouldRepaint(covariant _RingPainter o) => o.p != p || o.col != col;
}

/// شەپۆلی ECG لەسەر تۆڕی کاغەز.
/// `live` نەبێت = هێڵێکی ڕاستی ئەمبەر (هیچ ئاماژەیەک نییە).
class _TracePainter extends CustomPainter {
  _TracePainter(this.data, {required this.live, required this.frozen, required this.tick});
  final List<double> data;
  final bool live, frozen;
  final int tick;

  @override
  void paint(Canvas canvas, Size s) {
    // تۆڕ
    final minor = Paint()
      ..color = op(HC.c2, .07)
      ..strokeWidth = 1;
    final major = Paint()
      ..color = op(HC.c2, .16)
      ..strokeWidth = 1;
    for (double x = 0; x <= s.width; x += 14) {
      canvas.drawLine(Offset(x, 0), Offset(x, s.height), (x % 70 == 0) ? major : minor);
    }
    for (double y = 0; y <= s.height; y += 14) {
      canvas.drawLine(Offset(0, y), Offset(s.width, y), (y % 70 == 0) ? major : minor);
    }
    final mid = s.height / 2;

    if (!live || data.length < 2) {
      // خەتێکی ڕاست
      final p = Paint()
        ..color = op(_amber, .85)
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round;
      for (double x = 0; x < s.width; x += 11) {
        canvas.drawLine(Offset(x, mid), Offset(math.min(x + 5, s.width), mid), p);
      }
      return;
    }

    final n = data.length;
    final amp = s.height * 0.36;
    final dx = s.width / (n - 1);
    final path = Path();
    for (var i = 0; i < n; i++) {
      final x = i * dx;
      final y = mid - data[i] * amp;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    final shader = ui.Gradient.linear(Offset.zero, Offset(s.width, 0), [op(_mint, 0), _mint, vk(0xFF8FF3F9)], [0, .35, 1]);
    canvas.drawPath(path, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeJoin = StrokeJoin.round
      ..shader = shader
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4)
      ..color = op(_mint, .4));
    canvas.drawPath(path, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round
      ..shader = frozen ? null : shader
      ..color = _mint);
    if (!frozen) {
      final hx = (n - 1) * dx;
      final hy = mid - data.last * amp;
      canvas.drawCircle(Offset(hx - 4, hy), 8, Paint()..color = op(vk(0xFF8FF3F9), .25));
      canvas.drawCircle(Offset(hx - 4, hy), 3.6, Paint()..color = HC.tx);
    }
  }

  @override
  bool shouldRepaint(covariant _TracePainter o) => o.tick != tick || o.live != live || o.frozen != frozen || !identical(o.data, data);
}
