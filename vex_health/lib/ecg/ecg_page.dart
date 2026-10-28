// VEX Health — پێوانەی ECG (دیزاینی E)
//
//   1) ڕێنمایی  : وێنەی دەست و Band، هەڵبژاردنی دەست (چەپ / ڕاست)، 4 ئامۆژگاری، «دەستپێکردنی پێوانە»
//   2) پێوانە    : پەنجەی بزۆک ← (کە پەنجە لەسەر ئەلیکترۆدە بوو) ← شەپۆلی زیندوو، 30 چرکە، چیپەکان
//   3) ڕاپۆرت    : ئەنجام، هێڵکاریی لێدان، کاغەزی ECG (3 ڕیز × 10 چرکە)، PDF
//   4) مێژوو     : هەموو پێوانەکان (لەسەر مۆبایل هەڵدەگیرێن)
//
// بانگکردن لە هەر شوێنێک:   openEcgPage();
//
// ڕەنگەکان: خۆکار / ڕووناک / تاریک — بەپێی VexTheme.I (isDark). دەقەکان 6 زمان (kEcgTx).
// پێوانە تەواو بەپێی SDK ی Band: EcgController (measure 0x28 ← stream 0x07 ← 255Hz).
import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/theme.dart';
import '../health/hc.dart';
import 'ecg_controller.dart';
import 'ecg_history.dart';
import 'ecg_i18n.dart';
import 'ecg_pdf.dart';
import 'ecg_signal.dart';

void openEcgPage() => pushPage(const EcgPage());

// ───────────────────────── ڕەنگەکان (هەموو دۆخەکان) ─────────────────────────
class _P {
  _P._();
  static bool get d => VexTheme.I.isDark;
  static Color get bg => d ? const Color(0xFF000000) : const Color(0xFFF3F5F7);
  static Color get tx => d ? const Color(0xFFFFFFFF) : const Color(0xFF111418);
  static Color get mu => d ? const Color(0xFF8E8E93) : const Color(0xFF5F6670);
  static Color get dim => d ? const Color(0xFF6E6E73) : const Color(0xFF7B828B);
  static Color get card => d ? const Color(0xFF0E0E10) : const Color(0xFFFFFFFF);
  static Color get cardLine => d ? const Color(0xFF1F1F22) : const Color(0xFFE2E6EB);
  static Color get chip => d ? const Color(0xFF111113) : const Color(0xFFE9EDF1);
  static Color get chipLine => d ? const Color(0xFF222225) : const Color(0xFFD8DDE3);
  static Color get chipTx => d ? const Color(0xFFC7C7CC) : const Color(0xFF3A4048);
  static Color get ring => d ? const Color(0xFF3A3A3E) : const Color(0xFFC3C9D0);
  static Color get track => d ? const Color(0xFF1C1C1E) : const Color(0xFFDCE0E5);
  static Color get tipBg => d ? const Color(0xFF0B0B0C) : const Color(0xFFFFFFFF);
  static Color get tipOn => d ? const Color(0xFF0E1210) : const Color(0xFFF3FADB);
  static Color get tipLine => d ? const Color(0xFF222225) : const Color(0xFFDDE1E6);
  static Color get greenTx => d ? const Color(0xFF7FE0A8) : const Color(0xFF1B8A52);
  static Color get amber => d ? const Color(0xFFFFB84D) : const Color(0xFFB86E00);
  static Color get coral => d ? const Color(0xFFFF6B5E) : const Color(0xFFD93025);
  static Color get selTx => d ? const Color(0xFF000000) : const Color(0xFFFFFFFF);
  static List<Color> get thumb => d ? const [Color(0xFFFAFBFC), Color(0xFFC7CAD0)] : const [Color(0xFF2A2E34), Color(0xFF14171B)];
  static const Color red = Color(0xFFF2463A);
  static const Color green = Color(0xFF5CC68A);
  static const Color mint = Color(0xFF9EDCCB);
  static const Color lime = Color(0xFFD6F55B);
  static const Color stage = Color(0xFF000000); // کارتی پێوانە هەمیشە ڕەشە
  static const Color stageMu = Color(0xFF8E8E93);
}

String _t(String lg, String k) => kEcgTx[lg]?[k] ?? kEcgTx['en']![k] ?? k;

TextStyle _k(double s, {FontWeight w = FontWeight.w700, Color? c, double? h}) => ku(s, w: w, c: c ?? _P.tx, h: h);
TextStyle _n(double s, {FontWeight w = FontWeight.w700, Color? c, double? ls}) => nu(s, w: w, c: c ?? _P.tx, ls: ls);

double _eio(double x) {
  final v = x.clamp(0.0, 1.0).toDouble();
  return v < .5 ? 4 * v * v * v : 1 - math.pow(-2 * v + 2, 3).toDouble() / 2;
}

String _stamp(DateTime d) => '${d.year}/${pad2(d.month)}/${pad2(d.day)} · ${pad2(d.hour)}:${pad2(d.minute)}';

// ───────────────────────── کورتەی ئەنجام ─────────────────────────
class _Sum {
  _Sum(EcgResult r)
      : avg = (r.bpm ?? r.stats.bpm ?? 0).toDouble(),
        mn = (r.stats.minBpm ?? r.bpm ?? 0).round(),
        mx = (r.stats.maxBpm ?? r.bpm ?? 0).round(),
        beats = r.stats.beats,
        hrv = r.hrv ?? r.stats.rmssd?.round(),
        q = (r.quality * 100).round().clamp(0, 100).toInt(),
        irr = r.stats.irregular;
  final double avg;
  final int mn, mx, beats, q;
  final int? hrv;
  final bool irr;
  int get a => avg.round();
  bool get weak => q < 50;
}

/// هێڵکاریی لێدان: بۆ هەر لێدانێک (کات، bpm)، نەرم کراوە
(List<double>, List<double>) _series(EcgResult r) {
  final n = math.min(r.beatT.length, r.beatBpm.length);
  if (n < 2) return (<double>[], <double>[]);
  final ts = <double>[], vs = <double>[];
  for (var i = 0; i < n; i++) {
    final lo = math.max(0, i - 1), hi = math.min(n - 1, i + 1);
    var s = 0.0;
    for (var j = lo; j <= hi; j++) {
      s += r.beatBpm[j];
    }
    ts.add(r.beatT[i]);
    vs.add(s / (hi - lo + 1));
  }
  return (ts, vs);
}

// ───────────────────────── پەڕەکە ─────────────────────────
enum _Scr { guide, measure, report, history }

class EcgPage extends StatefulWidget {
  const EcgPage({super.key});
  @override
  State<EcgPage> createState() => _EcgPageState();
}

class _EcgPageState extends State<EcgPage> with TickerProviderStateMixin {
  static const String _wristKey = 'vex_ecg_wrist';

  _Scr scr = _Scr.guide;
  _Scr rFrom = _Scr.guide, hFrom = _Scr.guide;
  bool right = true;
  final List<bool> ok = [false, false, false, false];

  EcgController? ctl;
  EcgResult? cur;
  List<EcgResult> hist = <EcgResult>[];

  // کاتژمێری پێوانە (پەنجە + ڕیپڵ + ...)
  late final Ticker _ticker = createTicker(_onTick);
  final ValueNotifier<int> _tick = ValueNotifier<int>(0);
  double _T = 0, _lastT = 0, _tf0 = 0, _la = 0;
  bool _prevLive = false;

  // ڕاپۆرت
  late final AnimationController _rep = AnimationController(vsync: this, duration: const Duration(milliseconds: 3200));
  final GlobalKey _paperKey = GlobalKey();

  String? _toast;
  Timer? _toastT;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((sp) {
      final v = sp.getBool(_wristKey);
      if (v != null && mounted) setState(() => right = v);
    }).catchError((_) {});
    EcgHistory.load().then((l) {
      if (mounted) setState(() => hist = l);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    for (final n in const ['ecg_guide_r', 'ecg_guide_l', 'ecg_bg_r', 'ecg_bg_l', 'ecg_finger_r', 'ecg_finger_l']) {
      precacheImage(AssetImage('assets/ecg/$n.webp'), context).catchError((_) {});
    }
  }

  @override
  void dispose() {
    _toastT?.cancel();
    _ticker.dispose();
    _tick.dispose();
    _rep.dispose();
    final c = ctl;
    if (c != null) {
      c.removeListener(_onCtl);
      c.cancel();
      c.dispose();
    }
    super.dispose();
  }

  // ───────── یارمەتیدەر ─────────
  String get lg => LangScope.of(context);

  void _say(String msg) {
    setState(() => _toast = msg);
    _toastT?.cancel();
    _toastT = Timer(const Duration(milliseconds: 2400), () {
      if (mounted) setState(() => _toast = null);
    });
  }

  void _setWrist(bool r) {
    if (r == right) return;
    HapticFeedback.selectionClick();
    setState(() => right = r);
    SharedPreferences.getInstance().then((sp) => sp.setBool(_wristKey, r)).catchError((_) => false);
  }

  void _go(_Scr s) => setState(() => scr = s);

  // ───────── پێوانە ─────────
  void _onTick(Duration d) {
    final t = d.inMicroseconds / 1e6;
    final dt = (t - _lastT).clamp(0.0, 0.1).toDouble();
    _lastT = t;
    _T = t;
    final live = ctl?.phase == EcgPhase.measuring;
    if (_prevLive && !live) _tf0 = t; // پەنجە لابرا ← دووبارە ئەنیمەیشن
    _prevLive = live;
    final target = live ? 1.0 : 0.0;
    if (_la < target) _la = math.min(target, _la + dt / .6);
    if (_la > target) _la = math.max(target, _la - dt / .6);
    _tick.value++;
  }

  void _onCtl() {
    if (mounted) setState(() {});
  }

  void _startMeas() {
    HapticFeedback.lightImpact();
    final old = ctl;
    if (old != null) {
      old.removeListener(_onCtl);
      old.cancel();
      old.dispose();
    }
    final c = EcgController(rightWrist: right, onDone: _onDone);
    c.addListener(_onCtl);
    ctl = c;
    _la = 0;
    _prevLive = false;
    _lastT = 0;
    _tf0 = 0;
    if (_ticker.isActive) _ticker.stop();
    _ticker.start();
    setState(() => scr = _Scr.measure);
    c.start();
  }

  Future<void> _cancelMeas() async {
    final c = ctl;
    if (c != null) {
      c.removeListener(_onCtl);
      ctl = null;
      await c.cancel();
      c.dispose();
    }
    if (_ticker.isActive) _ticker.stop();
    if (mounted) setState(() => scr = _Scr.guide);
  }

  Future<void> _onDone(EcgResult r) async {
    if (!mounted) return;
    final l = await EcgHistory.add(r);
    if (!mounted) return;
    if (_ticker.isActive) _ticker.stop();
    final c = ctl;
    if (c != null) {
      c.removeListener(_onCtl);
      ctl = null;
      c.dispose();
    }
    setState(() {
      hist = l;
      _openReport(r, from: _Scr.guide, anim: true);
    });
  }

  // ───────── ڕاپۆرت ─────────
  void _openReport(EcgResult r, {required _Scr from, bool anim = true}) {
    cur = r;
    rFrom = from;
    scr = _Scr.report;
    if (anim) {
      _rep.forward(from: 0);
    } else {
      _rep.value = 1;
    }
  }

  Future<void> _exportPdf() async {
    final r = cur;
    if (r == null || _busy) return;
    _busy = true;
    HapticFeedback.selectionClick();
    try {
      if (_rep.value < 1) {
        _rep.value = 1;
        await WidgetsBinding.instance.endOfFrame;
      }
      final ro = _paperKey.currentContext?.findRenderObject();
      if (ro is! RenderRepaintBoundary) throw StateError('no paper');
      final img = await ro.toImage(pixelRatio: 3.0);
      final bd = await img.toByteData(format: ui.ImageByteFormat.png);
      if (bd == null) throw StateError('png');
      final png = bd.buffer.asUint8List();
      final name = 'VEX-ECG-${r.at.year}${pad2(r.at.month)}${pad2(r.at.day)}-${pad2(r.at.hour)}${pad2(r.at.minute)}.pdf';
      if (!mounted) return;
      final sz = MediaQuery.of(context).size;
      await shareEcgPdf(png, img.width / img.height, name, Rect.fromLTWH(sz.width / 2, sz.height - 80, 1, 1));
    } catch (_) {
      if (mounted) _say(_t(lg, 'pdfFail'));
    } finally {
      _busy = false;
    }
  }

  // ───────── مێژوو ─────────
  void _openHist() {
    hFrom = (scr == _Scr.report) ? _Scr.report : _Scr.guide;
    _go(_Scr.history);
  }

  Future<void> _delete(EcgResult r) async {
    final lang = lg;
    final yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: kDir,
        child: AlertDialog(
          backgroundColor: _P.card,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          content: Text(_t(lang, 'delQ'), style: _k(15, h: 1.6)),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text(_t(lang, 'cancel'), style: _k(14, c: _P.mu))),
            TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: Text(_t(lang, 'del'), style: _k(14, c: _P.coral))),
          ],
        ),
      ),
    );
    if (yes != true) return;
    final l = await EcgHistory.remove(r);
    if (mounted) setState(() => hist = l);
  }

  // ───────── دووگمەی دواوە ─────────
  void _back() {
    switch (scr) {
      case _Scr.guide:
        Navigator.of(context).maybePop();
      case _Scr.measure:
        _cancelMeas();
      case _Scr.report:
        _rep.stop();
        _go(rFrom == _Scr.history ? _Scr.history : _Scr.guide);
      case _Scr.history:
        _go(hFrom == _Scr.report && cur != null ? _Scr.report : _Scr.guide);
    }
  }

  // ═══════════════════════════ build ═══════════════════════════
  @override
  Widget build(BuildContext context) {
    final lang = LangScope.of(context);
    return ListenableBuilder(
      listenable: VexTheme.I,
      builder: (context, _) {
        final dark = _P.d;
        final Widget body;
        switch (scr) {
          case _Scr.guide:
            body = _guide(lang);
          case _Scr.measure:
            body = _measure(lang);
          case _Scr.report:
            body = _report(lang);
          case _Scr.history:
            body = _history(lang);
        }
        return Directionality(
          textDirection: kDir,
          child: PopScope(
            canPop: scr == _Scr.guide,
            onPopInvokedWithResult: (didPop, _) {
              if (!didPop) _back();
            },
            child: AnnotatedRegion<SystemUiOverlayStyle>(
              value: SystemUiOverlayStyle(
                statusBarColor: Colors.transparent,
                statusBarIconBrightness: dark ? Brightness.light : Brightness.dark,
                statusBarBrightness: dark ? Brightness.dark : Brightness.light,
                systemNavigationBarColor: _P.bg,
                systemNavigationBarIconBrightness: dark ? Brightness.light : Brightness.dark,
              ),
              child: Scaffold(
                backgroundColor: _P.bg,
                body: Stack(children: [
                  Positioned.fill(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 280),
                      switchInCurve: Curves.easeOut,
                      transitionBuilder: (child, a) => FadeTransition(opacity: a, child: child),
                      child: KeyedSubtree(key: ValueKey<_Scr>(scr), child: body),
                    ),
                  ),
                  PositionedDirectional(
                    start: 24,
                    end: 24,
                    bottom: MediaQuery.of(context).padding.bottom + 28,
                    child: IgnorePointer(
                      child: AnimatedSlide(
                        offset: _toast == null ? const Offset(0, .4) : Offset.zero,
                        duration: const Duration(milliseconds: 260),
                        child: AnimatedOpacity(
                          opacity: _toast == null ? 0 : 1,
                          duration: const Duration(milliseconds: 260),
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(18),
                                gradient: const LinearGradient(colors: [_P.mint, _P.green]),
                              ),
                              child: Text(_toast ?? '', textAlign: TextAlign.center, style: _k(13, w: FontWeight.w800, c: const Color(0xFF04231A))),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ]),
              ),
            ),
          ),
        );
      },
    );
  }

  // ───────── بەشە هاوبەشەکان ─────────
  Widget _top({required VoidCallback onBack, Widget? mid, Widget? end}) {
    return SizedBox(
      height: 48,
      child: Row(children: [
        _IconBtn(icon: Icons.arrow_back_rounded, onTap: onBack),
        Expanded(child: Center(child: mid ?? const SizedBox.shrink())),
        end ?? const SizedBox(width: 44),
      ]),
    );
  }

  Widget _scroll(List<Widget> kids) {
    return SafeArea(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 6, 20, 26),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: kids),
      ),
    );
  }

  // ═══════════════════════════ 1) ڕێنمایی ═══════════════════════════
  Widget _guide(String lang) {
    final done = ok.where((e) => e).length;
    return _scroll([
      _top(
        onBack: _back,
        end: _Tap(
          onTap: _openHist,
          child: Container(
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: _P.chip,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _P.chipLine),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.history_rounded, size: 17, color: _P.tx),
              const SizedBox(width: 6),
              Text(_t(lang, 'hist'), style: _k(13, w: FontWeight.w800)),
            ]),
          ),
        ),
      ),
      const SizedBox(height: 8),
      Text(_t(lang, 'title'), style: _k(24, w: FontWeight.w800, h: 1.35)),
      const SizedBox(height: 4),
      Text(_t(lang, 'sub'), style: _k(13, w: FontWeight.w600, c: _P.mu)),
      const SizedBox(height: 16),
      ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: ColoredBox(
          color: _P.stage,
          child: AspectRatio(
            aspectRatio: 780 / 328,
            child: Stack(fit: StackFit.expand, children: [
              AnimatedOpacity(
                duration: const Duration(milliseconds: 160),
                opacity: right ? 1 : 0,
                child: Image.asset('assets/ecg/ecg_guide_r.webp', fit: BoxFit.cover, gaplessPlayback: true),
              ),
              AnimatedOpacity(
                duration: const Duration(milliseconds: 160),
                opacity: right ? 0 : 1,
                child: Image.asset('assets/ecg/ecg_guide_l.webp', fit: BoxFit.cover, gaplessPlayback: true),
              ),
            ]),
          ),
        ),
      ),
      const SizedBox(height: 16),
      Text(_t(lang, 'which'), style: _k(13, c: _P.mu)),
      const SizedBox(height: 10),
      _Seg(left: _t(lang, 'left'), right: _t(lang, 'right'), isRight: right, onChanged: _setWrist),
      const SizedBox(height: 14),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Text(_t(lang, 'wear'), style: _k(12.5, w: FontWeight.w600, c: _P.mu, h: 1.75)),
      ),
      const SizedBox(height: 16),
      Row(children: [
        Text(_t(lang, 'before'), style: _k(13, c: _P.mu)),
        const SizedBox(width: 6),
        Directionality(textDirection: TextDirection.ltr, child: Text('($done/4)', style: _n(13, c: _P.mu))),
      ]),
      const SizedBox(height: 10),
      for (var i = 0; i < 4; i++) ...[
        _tip(lang, i),
        const SizedBox(height: 8),
      ],
      const SizedBox(height: 10),
      _GoBtn(label: _t(lang, 'start'), onTap: _startMeas),
    ]);
  }

  Widget _tip(String lang, int i) {
    final on = ok[i];
    return _Tap(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => ok[i] = !ok[i]);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: on ? _P.tipOn : _P.tipBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: on ? _P.lime.withValues(alpha: .45) : _P.tipLine),
        ),
        child: Row(children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: on ? _P.lime : Colors.transparent,
              border: Border.all(color: on ? _P.lime : _P.ring, width: 1.5),
            ),
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: on ? 1 : 0,
              child: const Icon(Icons.check_rounded, size: 17, color: Colors.black),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(_t(lang, 't${i + 1}'), style: _k(15.5, w: FontWeight.w800, h: 1.5)),
              const SizedBox(height: 2),
              Text(_t(lang, 's${i + 1}'), style: _k(12.5, w: FontWeight.w600, c: _P.mu, h: 1.55)),
            ]),
          ),
        ]),
      ),
    );
  }

  // ═══════════════════════════ 2) پێوانە ═══════════════════════════
  Widget _measure(String lang) {
    final c = ctl;
    if (c == null) return const SizedBox.shrink();
    if (c.phase == EcgPhase.failed) return _failed(lang, c);

    return SafeArea(
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverFillRemaining(
            hasScrollBody: false,
            child: ListenableBuilder(
              listenable: Listenable.merge([c, _tick]),
              builder: (context, _) => _measureBody(lang, c),
            ),
          ),
        ],
      ),
    );
  }

  Widget _measureBody(String lang, EcgController c) {
    final live = c.phase == EcgPhase.measuring;
    final lost = c.fingerLost && live;
    final finishing = c.phase == EcgPhase.done;
    final sig = c.sig;
    final noPkt = sig.lastPacket == null;

    // چیپی پەیوەندی
    String t1;
    Color c1;
    if (lost) {
      t1 = _t(lang, 'lost');
      c1 = _P.coral;
    } else if (live || finishing) {
      t1 = _t(lang, 'cGood');
      c1 = _P.greenTx;
    } else {
      t1 = noPkt ? _t(lang, 'cSync') : _t(lang, 'cWait');
      c1 = _P.amber;
    }
    // کوالیتی (4 خانە)
    final q = (live && !lost) ? (sig.quality * 4).ceil().clamp(1, 4).toInt() : 0;
    // ڕیتم
    String rh = _t(lang, 'rhPend');
    Color rhC = _P.mu;
    if (live && sig.beatCount >= 6) {
      final st = EcgStats.from(sig.rrLog);
      if (st.irregular) {
        rh = _t(lang, 'irregular');
        rhC = _P.amber;
      } else {
        rh = _t(lang, 'rhOk');
        rhC = _P.greenTx;
      }
    }
    // تێبینی
    String note;
    Color noteC;
    if (finishing) {
      note = _t(lang, 'nDone');
      noteC = _P.greenTx;
    } else if (lost) {
      note = _t(lang, 'lost');
      noteC = _P.amber;
    } else if (live) {
      note = _t(lang, 'nMeas');
      noteC = _P.greenTx;
    } else {
      note = _t(lang, 'nCalib');
      noteC = _P.mu;
    }
    final barV = live ? (1 - c.progress).clamp(0.0, 1.0).toDouble() : (finishing ? 0.0 : 1.0);

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: _top(onBack: _back)),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 22),
        child: Text(_t(lang, 'meas'), style: _k(22, w: FontWeight.w800)),
      ),
      const SizedBox(height: 10),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 22),
        child: Wrap(spacing: 8, runSpacing: 8, children: [
          _Chip(
            color: c1,
            bg: c1.withValues(alpha: .13),
            line: c1.withValues(alpha: .3),
            glow: live && !lost,
            child: Text(t1, style: _k(12, w: FontWeight.w800, c: c1)),
          ),
          _Chip(
            color: _P.mu,
            bg: _P.chip,
            line: _P.chipLine,
            dot: false,
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Directionality(
                textDirection: TextDirection.ltr,
                child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  for (var i = 1; i <= 4; i++)
                    Container(
                      width: 3,
                      height: 2.0 + i * 3,
                      margin: const EdgeInsets.only(right: 2),
                      decoration: BoxDecoration(color: q >= i ? _P.green : _P.ring.withValues(alpha: .6), borderRadius: BorderRadius.circular(1)),
                    ),
                ]),
              ),
              const SizedBox(width: 6),
              Text(_t(lang, 'signal'), style: _k(12, w: FontWeight.w800, c: _P.chipTx)),
            ]),
          ),
          _Chip(color: rhC, bg: _P.chip, line: _P.chipLine, dot: false, child: Text(rh, style: _k(12, w: FontWeight.w800, c: rhC))),
        ]),
      ),
      const SizedBox(height: 8),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: ClipRRect(borderRadius: BorderRadius.circular(28), child: _stage(c)),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(22, 18, 22, 0),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Container(
            height: 10,
            decoration: BoxDecoration(color: _P.track, borderRadius: BorderRadius.circular(5)),
            child: Align(
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: barV,
                child: Container(
                  height: 10,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(5),
                    gradient: const LinearGradient(colors: [_P.mint, _P.green]),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(22, 20, 22, 0),
        child: Text(_t(lang, 'instr'), style: _k(19, w: FontWeight.w800, h: 1.6)),
      ),
      const Spacer(),
      Padding(
        padding: const EdgeInsets.fromLTRB(22, 14, 22, 0),
        child: Text(note, style: _k(12.5, w: FontWeight.w600, c: noteC, h: 1.6)),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(22, 12, 22, 14),
        child: _Ghost(label: _t(lang, 'cancel'), onTap: _back, strong: true),
      ),
    ]);
  }

  /// کارتی ڕەشی پێوانە (کۆردینەیتی دیزاین 390×400)
  Widget _stage(EcgController c) {
    final live = c.phase == EcgPhase.measuring;
    final sig = c.sig;
    final handA = (1 - _la).clamp(0.0, 1.0).toDouble();
    final liveA = _la.clamp(0.0, 1.0).toDouble();

    // پەنجە
    final tf = _T - _tf0;
    final s = _eio((tf - .4) / 1.5);
    final press = (tf > 1.9 && tf < 2.25) ? math.sin(math.pi * (tf - 1.9) / .35) : 0.0;
    final sg = right ? 1.0 : -1.0;
    final ox = right ? 193.0 : 197.0, oy = 104.0;
    final sc = 1 - .02 * press;
    final fm = Matrix4.translationValues(sg * 95 * (1 - s), 235 * (1 - s), 0) *
        Matrix4.translationValues(ox, oy, 0) *
        Matrix4.rotationZ(sg * 7 * (1 - s) * math.pi / 180) *
        Matrix4.diagonal3Values(sc, sc, 1) *
        Matrix4.translationValues(-ox, -oy, 0);
    final fa = ((tf - .35) / .4).clamp(0.0, 1.0).toDouble();
    final touching = tf >= 1.9 && !live;
    final k1 = touching ? ((tf - 1.9) % 1.3) / 1.3 : 0.0;
    final k2 = (touching && tf > 2.55) ? ((tf - 2.55) % 1.3) / 1.3 : 0.0;

    // خوێندنەوەکان
    final bpm = sig.bpm;
    final bpmTxt = (live && bpm != null) ? bpm.round().toString() : '--';
    String hrvTxt = '--';
    if (live && c.elapsed.inSeconds >= 10 && sig.rrLog.length >= 6) {
      final r = EcgStats.from(sig.rrLog).rmssd;
      if (r != null) hrvTxt = r.round().toString();
    }
    final per = 60.0 / (bpm ?? 70);
    final ph = (_T % per) / per;
    final pulse = 1 + .16 * math.max(0.0, math.sin(math.pi * math.min(1.0, ph * 4)));

    return AspectRatio(
      aspectRatio: 390 / 400,
      child: ColoredBox(
        color: _P.stage,
        child: FittedBox(
          fit: BoxFit.fill,
          child: SizedBox(
            width: 390,
            height: 400,
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: Stack(clipBehavior: Clip.hardEdge, children: [
                // تۆڕی کاغەزی ECG
                Positioned.fill(child: Opacity(opacity: liveA, child: const CustomPaint(painter: _GridPainter()))),
                // دەست + Band + پەنجە
                if (handA > 0.003)
                  Positioned.fill(
                    child: Opacity(
                      opacity: handA,
                      child: Stack(children: [
                        Positioned(
                          left: 0,
                          top: 16,
                          width: 390,
                          height: 289,
                          child: Image.asset(right ? 'assets/ecg/ecg_bg_r.webp' : 'assets/ecg/ecg_bg_l.webp', fit: BoxFit.fill, gaplessPlayback: true),
                        ),
                        Positioned(
                          left: 0,
                          top: 16,
                          width: 390,
                          height: 289,
                          child: Opacity(
                            opacity: fa,
                            child: Transform(
                              transform: fm,
                              child: Image.asset(right ? 'assets/ecg/ecg_finger_r.webp' : 'assets/ecg/ecg_finger_l.webp', fit: BoxFit.fill, gaplessPlayback: true),
                            ),
                          ),
                        ),
                        Positioned.fill(child: CustomPaint(painter: _RipplePainter(cx: ox, cy: 122, k1: k1, k2: k2, on1: touching, on2: touching && tf > 2.55))),
                        const Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          height: 130,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [Color(0x00000000), Color(0xFF000000)],
                                stops: [0, .75],
                              ),
                            ),
                          ),
                        ),
                      ]),
                    ),
                  ),
                // شەپۆلی زیندوو
                if (liveA > 0.003)
                  Positioned(
                    left: 0,
                    top: 34,
                    width: 390,
                    height: 300,
                    child: Opacity(opacity: liveA, child: CustomPaint(painter: _SweepPainter(sig, _tick.value))),
                  ),
                // لێدانی دڵ
                Positioned(
                  left: 22,
                  top: 18,
                  child: Opacity(
                    opacity: liveA,
                    child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                      Transform.scale(scale: pulse, child: const Icon(Icons.favorite_rounded, color: _P.red, size: 27)),
                      const SizedBox(width: 6),
                      Text(bpmTxt, style: _n(30, c: Colors.white)),
                      const SizedBox(width: 6),
                      Text('bpm', style: _n(15, w: FontWeight.w500, c: _P.stageMu)),
                    ]),
                  ),
                ),
                // چرکەژمێر
                Positioned(
                  left: 20,
                  bottom: 0,
                  child: Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
                    Text('${c.secondsLeft}', style: _n(96, c: Colors.white, ls: -3).copyWith(height: .95)),
                    const SizedBox(width: 10),
                    Text('s', style: _n(20, c: _P.stageMu)),
                  ]),
                ),
                // HRV
                Positioned(
                  right: 22,
                  bottom: 12,
                  child: Opacity(
                    opacity: liveA,
                    child: Column(crossAxisAlignment: CrossAxisAlignment.end, mainAxisSize: MainAxisSize.min, children: [
                      Text('HRV', style: _n(11, c: _P.stageMu, ls: 1)),
                      Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, mainAxisSize: MainAxisSize.min, children: [
                        Text(hrvTxt, style: _n(22, c: Colors.white)),
                        const SizedBox(width: 4),
                        Text('ms', style: _n(12, w: FontWeight.w500, c: _P.stageMu)),
                      ]),
                    ]),
                  ),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  Widget _failed(String lang, EcgController c) {
    final why = c.failReason;
    final msg = (why == 'band' || why == 'noband' || why == 'nofinger') ? _t(lang, why) : _t(lang, 'nofinger');
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 6, 20, 26),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          _top(onBack: _back),
          const Spacer(),
          Icon(Icons.monitor_heart_outlined, size: 72, color: _P.ring),
          const SizedBox(height: 18),
          Text(msg, textAlign: TextAlign.center, style: _k(19, w: FontWeight.w800, h: 1.6)),
          const SizedBox(height: 8),
          Text(_t(lang, 'failHint'), textAlign: TextAlign.center, style: _k(13, w: FontWeight.w600, c: _P.mu, h: 1.7)),
          const Spacer(),
          _GoBtn(label: _t(lang, 'retry'), onTap: _startMeas),
          const SizedBox(height: 12),
          _Ghost(label: _t(lang, 'cancel'), onTap: _back),
        ]),
      ),
    );
  }

  // ═══════════════════════════ 3) ڕاپۆرت ═══════════════════════════
  Widget _report(String lang) {
    final r = cur;
    if (r == null) return const SizedBox.shrink();
    final sum = _Sum(r);
    final wrist = r.rightWrist ? _t(lang, 'wR') : _t(lang, 'wL');
    final wristEn = r.rightWrist ? 'Right wrist' : 'Left wrist';

    return AnimatedBuilder(
      animation: _rep,
      builder: (context, _) {
        final t = _rep.value * 3.2;
        double e(double a, double d) => _eio((t - a) / d);

        final rhPill = sum.irr ? _t(lang, 'irregular') : _t(lang, 'rhOk');
        final rhCol = sum.irr ? _P.amber : _P.greenTx;
        final cards = <(String, String, String, Color?)>[
          (_t(lang, 'range'), '${sum.mn}–${sum.mx}', 'bpm', null),
          ('HRV (RMSSD)', sum.hrv == null ? '--' : '${sum.hrv}', 'ms', null),
          (_t(lang, 'beats'), '${sum.beats}', '', null),
          (_t(lang, 'qual'), '${sum.q}', '%', sum.weak ? _P.amber : _P.greenTx),
        ];

        return _scroll([
          _top(
            onBack: _back,
            mid: Text(_t(lang, 'res'), style: _k(16, w: FontWeight.w800)),
            end: _IconBtn(icon: Icons.ios_share_rounded, size: 23, onTap: _exportPdf),
          ),
          const SizedBox(height: 8),
          Row(children: [
            SizedBox(
              width: 46,
              height: 46,
              child: CustomPaint(painter: _OkPainter(ring: e(.05, .7), check: e(.55, .4), track: _P.ring)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(_t(lang, 'ok'), style: _k(18, w: FontWeight.w800)),
                const SizedBox(height: 1),
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Text('${_stamp(r.at)} · $wrist', style: _n(13, w: FontWeight.w500, c: _P.mu)),
                  ),
                ),
              ]),
            ),
          ]),
          const SizedBox(height: 22),
          Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(_t(lang, 'avg'), style: _k(13, c: _P.mu)),
                const SizedBox(height: 6),
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Row(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
                      Text('${(sum.a * e(.2, .9)).round()}', style: _n(72, ls: -3).copyWith(height: .95)),
                      const SizedBox(width: 8),
                      Text('bpm', style: _n(17, w: FontWeight.w500, c: _P.mu)),
                    ]),
                  ),
                ),
              ]),
            ),
            Container(
              height: 36,
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: rhCol.withValues(alpha: .12),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: rhCol.withValues(alpha: .35)),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Container(width: 8, height: 8, decoration: BoxDecoration(color: rhCol, shape: BoxShape.circle)),
                const SizedBox(width: 7),
                Text(rhPill, style: _k(14, w: FontWeight.w800, c: rhCol)),
              ]),
            ),
          ]),
          const SizedBox(height: 18),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.9,
            padding: EdgeInsets.zero,
            children: [
              for (var i = 0; i < cards.length; i++)
                Opacity(
                  opacity: ((t - (.45 + i * .08)) / .5).clamp(0.0, 1.0).toDouble(),
                  child: Transform.translate(
                    offset: Offset(0, 10 * (1 - ((t - (.45 + i * .08)) / .5).clamp(0.0, 1.0).toDouble())),
                    child: _metric(cards[i].$1, cards[i].$2, cards[i].$3, cards[i].$4),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          _trendCard(lang, r, sum, e(.7, 1.1)),
          const SizedBox(height: 14),
          // کاغەزی ECG
          ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: SizedBox(
              width: double.infinity,
              child: FittedBox(
                fit: BoxFit.fitWidth,
                child: RepaintBoundary(
                  key: _paperKey,
                  child: _Paper(r: r, sum: sum, wristEn: wristEn, reveal: [e(1.0, 1.0), e(1.45, 1.0), e(1.9, 1.0)]),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            decoration: BoxDecoration(
              color: (sum.irr || sum.weak ? _P.amber : _P.green).withValues(alpha: .08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: (sum.irr || sum.weak ? _P.amber : _P.green).withValues(alpha: .24)),
            ),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Icon(sum.irr || sum.weak ? Icons.info_outline_rounded : Icons.monitor_heart_outlined, size: 22, color: sum.irr || sum.weak ? _P.amber : _P.greenTx),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  sum.irr ? _t(lang, 'irrNote') : (sum.weak ? _t(lang, 'weakNote') : _t(lang, 'interp')),
                  style: _k(13.5, w: FontWeight.w700, h: 1.75),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 18),
          _GoBtn(label: _t(lang, 'pdf'), icon: Icons.download_rounded, onTap: _exportPdf, size: 17),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: _Ghost(label: _t(lang, 'again'), onTap: _startMeas)),
            const SizedBox(width: 10),
            Expanded(child: _Ghost(label: _t(lang, 'histBtn'), onTap: _openHist)),
          ]),
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 18, 4, 0),
            child: Text(_t(lang, 'disc'), style: _k(12.5, w: FontWeight.w600, c: _P.dim, h: 1.8)),
          ),
        ]);
      },
    );
  }

  Widget _metric(String label, String value, String unit, Color? col) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(color: _P.card, borderRadius: BorderRadius.circular(20), border: Border.all(color: _P.cardLine)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
        Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: _k(12.5, c: _P.mu)),
        const SizedBox(height: 6),
        Directionality(
          textDirection: TextDirection.ltr,
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: Row(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
              Text(value, style: _n(24, c: col)),
              if (unit.isNotEmpty) ...[
                const SizedBox(width: 5),
                Text(unit, style: _n(12, w: FontWeight.w500, c: _P.mu)),
              ],
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _trendCard(String lang, EcgResult r, _Sum sum, double reveal) {
    final (ts, vs) = _series(r);
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
      decoration: BoxDecoration(color: _P.card, borderRadius: BorderRadius.circular(22), border: Border.all(color: _P.cardLine)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Flexible(child: Text(_t(lang, 'hr30'), style: _k(14, w: FontWeight.w800))),
          const SizedBox(width: 8),
          Directionality(textDirection: TextDirection.ltr, child: Text('${sum.mn}–${sum.mx} bpm', style: _n(12, w: FontWeight.w600, c: _P.mu))),
        ]),
        const SizedBox(height: 8),
        SizedBox(
          height: 92,
          child: CustomPaint(
            painter: _TrendPainter(ts: ts, vs: vs, avg: sum.avg, reveal: reveal, card: _P.card, grid: _P.ring),
          ),
        ),
        const SizedBox(height: 4),
        Directionality(
          textDirection: TextDirection.ltr,
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            for (final s in const ['0s', '10s', '20s', '30s']) Text(s, style: _n(10.5, w: FontWeight.w600, c: _P.dim)),
          ]),
        ),
      ]),
    );
  }

  // ═══════════════════════════ 4) مێژوو ═══════════════════════════
  Widget _history(String lang) {
    return _scroll([
      _top(onBack: _back, mid: Text(_t(lang, 'histT'), style: _k(16, w: FontWeight.w800))),
      if (hist.isEmpty)
        Padding(
          padding: const EdgeInsets.only(top: 80, bottom: 80),
          child: Column(children: [
            Icon(Icons.monitor_heart_outlined, size: 64, color: _P.ring),
            const SizedBox(height: 12),
            Text(_t(lang, 'empty'), textAlign: TextAlign.center, style: _k(14, c: _P.mu, h: 1.8)),
          ]),
        )
      else
        for (final r in hist) ...[
          const SizedBox(height: 10),
          _histRow(lang, r),
        ],
      const SizedBox(height: 24),
      _GoBtn(label: _t(lang, 'start'), onTap: _startMeas),
    ]);
  }

  Widget _histRow(String lang, EcgResult r) {
    final sum = _Sum(r);
    final wrist = r.rightWrist ? _t(lang, 'wR') : _t(lang, 'wL');
    return _Tap(
      onTap: () => setState(() => _openReport(r, from: _Scr.history)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(color: _P.card, borderRadius: BorderRadius.circular(20), border: Border.all(color: _P.cardLine)),
        child: Row(children: [
          SizedBox(width: 86, height: 36, child: CustomPaint(painter: _SparkPainter(r.trace, r.sampleRate))),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(sum.irr ? _t(lang, 'irrT') : _t(lang, 'rhOk'), style: _k(14.5, w: FontWeight.w800, c: sum.irr ? _P.amber : null)),
              const SizedBox(height: 2),
              Directionality(
                textDirection: TextDirection.ltr,
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text('${_stamp(r.at)} · $wrist', maxLines: 1, overflow: TextOverflow.ellipsis, style: _n(11.5, w: FontWeight.w500, c: _P.mu)),
                ),
              ),
            ]),
          ),
          Directionality(
            textDirection: TextDirection.ltr,
            child: Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
              Text('${sum.a}', style: _n(24)),
              const SizedBox(width: 4),
              Text('bpm', style: _n(11, w: FontWeight.w500, c: _P.mu)),
            ]),
          ),
          _IconBtn(icon: Icons.delete_outline_rounded, size: 21, color: _P.dim, onTap: () => _delete(r)),
        ]),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//   ویجێتە بچووکەکان
// ═══════════════════════════════════════════════════════════════════

/// کاتێک دەگیرێت کەمێک بچووک دەبێتەوە
class _Tap extends StatefulWidget {
  const _Tap({required this.child, required this.onTap});
  final Widget child;
  final VoidCallback onTap;
  @override
  State<_Tap> createState() => _TapState();
}

class _TapState extends State<_Tap> {
  bool _down = false;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _down = true),
      onTapCancel: () => setState(() => _down = false),
      onTapUp: (_) => setState(() => _down = false),
      onTap: widget.onTap,
      child: AnimatedScale(scale: _down ? .98 : 1, duration: const Duration(milliseconds: 110), child: widget.child),
    );
  }
}

class _IconBtn extends StatelessWidget {
  const _IconBtn({required this.icon, required this.onTap, this.size = 26, this.color});
  final IconData icon;
  final VoidCallback onTap;
  final double size;
  final Color? color;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(width: 44, height: 44, child: Center(child: Icon(icon, size: size, color: color ?? _P.tx))),
    );
  }
}

class _GoBtn extends StatelessWidget {
  const _GoBtn({required this.label, required this.onTap, this.icon, this.size = 18});
  final String label;
  final VoidCallback onTap;
  final IconData? icon;
  final double size;
  @override
  Widget build(BuildContext context) {
    return _Tap(
      onTap: onTap,
      child: Container(
        height: 56,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: const LinearGradient(begin: Alignment.centerRight, end: Alignment.centerLeft, colors: [_P.mint, _P.green]),
          boxShadow: [BoxShadow(color: _P.green.withValues(alpha: .35), blurRadius: 26, offset: const Offset(0, 10), spreadRadius: -8)],
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          if (icon != null) ...[Icon(icon, size: 22, color: Colors.black), const SizedBox(width: 10)],
          Flexible(child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: _k(size, w: FontWeight.w800, c: Colors.black))),
        ]),
      ),
    );
  }
}

class _Ghost extends StatelessWidget {
  const _Ghost({required this.label, required this.onTap, this.strong = false});
  final String label;
  final VoidCallback onTap;
  final bool strong;
  @override
  Widget build(BuildContext context) {
    return _Tap(
      onTap: onTap,
      child: Container(
        height: strong ? 56 : 52,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: strong ? _P.tx : _P.ring, width: 1.5),
        ),
        child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: _k(strong ? 18 : 15, w: FontWeight.w800)),
      ),
    );
  }
}

/// هەڵبژاردنی دەست (چەپ / ڕاست)
class _Seg extends StatelessWidget {
  const _Seg({required this.left, required this.right, required this.isRight, required this.onChanged});
  final String left, right;
  final bool isRight;
  final ValueChanged<bool> onChanged;
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 58,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(29), border: Border.all(color: _P.ring, width: 1.5)),
      child: LayoutBuilder(builder: (context, bc) {
        final w = (bc.maxWidth - 8) / 2;
        return Stack(children: [
          AnimatedPositionedDirectional(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutBack,
            top: 4,
            bottom: 4,
            start: isRight ? 4 + w : 4,
            width: w,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(25),
                gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: _P.thumb),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(4),
            child: Row(children: [
              Expanded(child: _segBtn(left, !isRight, () => onChanged(false))),
              Expanded(child: _segBtn(right, isRight, () => onChanged(true))),
            ]),
          ),
        ]);
      }),
    );
  }

  Widget _segBtn(String t, bool sel, VoidCallback f) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: f,
        child: Center(
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: _k(18, w: FontWeight.w800, c: sel ? _P.selTx : _P.tx),
            child: Text(t),
          ),
        ),
      );
}

class _Chip extends StatelessWidget {
  const _Chip({required this.child, required this.bg, required this.line, required this.color, this.dot = true, this.glow = false});
  final Widget child;
  final Color bg, line, color;
  final bool dot, glow;
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 11),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(15), border: Border.all(color: line)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (dot) ...[
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle, boxShadow: glow ? [BoxShadow(color: color, blurRadius: 8)] : null),
          ),
          const SizedBox(width: 6),
        ],
        child,
      ]),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//   کاغەزی ECG (700 پیکسل پانی — بۆ PDF دەگیرێت)
// ═══════════════════════════════════════════════════════════════════
class _Paper extends StatelessWidget {
  const _Paper({required this.r, required this.sum, required this.wristEn, required this.reveal});
  final EcgResult r;
  final _Sum sum;
  final String wristEn;
  final List<double> reveal;

  static const Color _ink = Color(0xFF111111);
  static const Color _gr = Color(0xFF888888);
  static const Color _hd = Color(0xFF0E1A1F);

  TextStyle _s(double sz, {FontWeight w = FontWeight.w400, Color c = _ink, double? ls}) => nu(sz, w: w, c: c, ls: ls);

  @override
  Widget build(BuildContext context) {
    final rate = r.sampleRate <= 0 ? 85.0 : r.sampleRate;
    final per = (rate * 10).round();
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Container(
        width: 700,
        color: Colors.white,
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          // سەرەوە
          Container(
            color: _hd,
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: Row(children: [
              Container(
                width: 56,
                height: 56,
                alignment: Alignment.center,
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [_P.mint, _P.green])),
                child: Text('VX', style: _s(23, w: FontWeight.w900, c: const Color(0xFF062018), ls: -1)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('VEX HEALTH · ECG REPORT', style: _s(23, w: FontWeight.w900, c: Colors.white, ls: .6)),
                  const SizedBox(height: 4),
                  Text('${_stamp(r.at)} · 30 s · $wristEn', style: _s(17, c: const Color(0xFF9FB3BA))),
                ]),
              ),
              const Icon(Icons.favorite_rounded, color: _P.red, size: 24),
              const SizedBox(width: 6),
              Text('${sum.a}', style: _s(34, w: FontWeight.w900, c: Colors.white)),
              const SizedBox(width: 5),
              Text('bpm', style: _s(17, c: const Color(0xFF9FB3BA))),
            ]),
          ),
          // ژمارەکان
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE)))),
            child: Row(children: [
              _pm('AVG HR', '${sum.a} bpm', const Color(0xFFD32F2F)),
              _pm('RANGE', '${sum.mn}–${sum.mx}', _ink),
              _pm('HRV', sum.hrv == null ? '--' : '${sum.hrv} ms', _ink),
              _pm('RHYTHM', sum.irr ? 'Irregular' : 'Regular', sum.irr ? const Color(0xFFB86E00) : const Color(0xFF2E7D32)),
            ]),
          ),
          // 3 ڕیزی 10 چرکە
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 22, 24, 0),
            child: Column(children: [
              for (var i = 0; i < 3; i++) ...[
                if (i > 0) const SizedBox(height: 14),
                SizedBox(
                  height: 130,
                  child: Stack(children: [
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _StripPainter(r.trace, i * per, math.min(r.trace.length, (i + 1) * per), reveal[i]),
                      ),
                    ),
                    Positioned(right: 8, top: 5, child: Text('${i * 10}–${i * 10 + 10} s', style: _s(15, c: const Color(0xFF999999)))),
                  ]),
                ),
              ],
            ]),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 22),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Flexible(child: Text('25 mm/s · 10 mm/mV · 255 Hz · Lead I · $wristEn', style: _s(15, c: _gr))),
                Text('VEX Band V8', style: _s(15, c: _gr)),
              ]),
              const SizedBox(height: 8),
              Text('Similar to a Lead I ECG. For wellness and record keeping only — not a medical diagnosis.', style: _s(14, c: const Color(0xFF9E9E9E)).copyWith(height: 1.5)),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _pm(String k, String v, Color c) => Expanded(
        child: Column(children: [
          Text(k, style: _s(14, c: _gr, ls: .8)),
          const SizedBox(height: 3),
          Text(v, style: _s(24, w: FontWeight.w900, c: c)),
        ]),
      );
}

// ═══════════════════════════════════════════════════════════════════
//   پێنتەرەکان
// ═══════════════════════════════════════════════════════════════════

/// تۆڕی کاغەزی ECG لەسەر کارتی پێوانە
class _GridPainter extends CustomPainter {
  const _GridPainter();
  @override
  void paint(Canvas c, Size s) {
    final p = Paint()
      ..color = const Color(0x12FFFFFF)
      ..strokeWidth = 1;
    for (double x = 0; x <= s.width; x += 15) {
      c.drawLine(Offset(x, 0), Offset(x, s.height), p);
    }
    for (double y = 0; y <= s.height; y += 15) {
      c.drawLine(Offset(0, y), Offset(s.width, y), p);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

/// ڕیپڵی ژێر پەنجە
class _RipplePainter extends CustomPainter {
  _RipplePainter({required this.cx, required this.cy, required this.k1, required this.k2, required this.on1, required this.on2});
  final double cx, cy, k1, k2;
  final bool on1, on2;
  @override
  void paint(Canvas c, Size s) {
    void ring(double k, bool on) {
      if (!on) return;
      c.drawCircle(
        Offset(cx, cy),
        10 + k * 36,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = _P.mint.withValues(alpha: (.85 * (1 - k)).clamp(0.0, 1.0).toDouble()),
      );
    }

    ring(k1, on1);
    ring(k2, on2);
  }

  @override
  bool shouldRepaint(covariant _RipplePainter o) => o.k1 != k1 || o.k2 != k2 || o.on1 != on1 || o.on2 != on2 || o.cx != cx;
}

/// شەپۆلی زیندوو (شێوازی مۆنیتەر: خەت لە چەپەوە بۆ ڕاست، بۆشایی لە پێشیەوە)
class _SweepPainter extends CustomPainter {
  _SweepPainter(this.sig, this.tick);
  final EcgSignal sig;
  final int tick;

  @override
  void paint(Canvas c, Size s) {
    const mid = 150.0, amp = 70.0;
    c.drawLine(
      const Offset(0, mid),
      Offset(s.width, mid),
      Paint()
        ..color = const Color(0x59FFFFFF)
        ..strokeWidth = 1,
    );
    final buf = sig.sweep;
    final n = buf.length;
    if (n < 2) return;
    final dx = s.width / (n - 1);
    final gap = (n * .07).round();
    final cur = sig.cursor.clamp(0, n).toInt();
    final line = Paint()
      ..color = _P.red
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;
    final glow = Paint()
      ..color = _P.red.withValues(alpha: .35)
      ..strokeWidth = 8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);

    Path seg(int a, int b) {
      final p = Path();
      for (var i = a; i < b; i++) {
        final x = i * dx, y = mid - buf[i] * amp;
        if (i == a) {
          p.moveTo(x, y);
        } else {
          p.lineTo(x, y);
        }
      }
      return p;
    }

    final parts = <Path>[if (cur > 1) seg(0, cur), if (sig.sweepFull && cur + gap < n - 1) seg(cur + gap, n)];
    for (final p in parts) {
      c.drawPath(p, glow);
      c.drawPath(p, line);
    }
    if (cur > 0) {
      final head = Offset((cur - 1) * dx, mid - buf[cur - 1] * amp);
      c.drawCircle(
        head,
        8,
        Paint()
          ..color = _P.red.withValues(alpha: .3)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
      c.drawCircle(head, 3.6, Paint()..color = const Color(0xFFFF7A70));
    }
  }

  @override
  bool shouldRepaint(covariant _SweepPainter o) => true;
}

/// بازنەی تەواوبوون: بازنە + نیشانەی ✓
class _OkPainter extends CustomPainter {
  _OkPainter({required this.ring, required this.check, required this.track});
  final double ring, check;
  final Color track;
  @override
  void paint(Canvas c, Size s) {
    final ctr = Offset(s.width / 2, s.height / 2);
    final r = s.width * 20 / 46;
    c.drawCircle(ctr, r, Paint()..color = _P.green.withValues(alpha: .12));
    c.drawCircle(
      ctr,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = track,
    );
    c.drawArc(
      Rect.fromCircle(center: ctr, radius: r),
      -math.pi / 2,
      2 * math.pi * ring,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..color = _P.green,
    );
    if (check > 0) {
      final k = s.width / 46;
      final path = Path()
        ..moveTo(15 * k, 23.5 * k)
        ..lineTo(20.5 * k, 29 * k)
        ..lineTo(31 * k, 18 * k);
      for (final m in path.computeMetrics()) {
        c.drawPath(
          m.extractPath(0, m.length * check),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3.2
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round
            ..color = _P.greenTx,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _OkPainter o) => o.ring != ring || o.check != check || o.track != track;
}

/// هێڵکاریی لێدانی دڵ لە ماوەی 30 چرکەدا
class _TrendPainter extends CustomPainter {
  _TrendPainter({required this.ts, required this.vs, required this.avg, required this.reveal, required this.card, required this.grid});
  final List<double> ts, vs;
  final double avg, reveal;
  final Color card, grid;

  @override
  void paint(Canvas c, Size s) {
    final w = s.width, h = s.height;
    double lo = avg - 8, hi = avg + 8;
    for (final v in vs) {
      lo = math.min(lo, v - 3);
      hi = math.max(hi, v + 3);
    }
    double yOf(double b) => 6 + (h - 14) * (1 - (b - lo) / (hi - lo));
    final maxT = math.max(30.0, ts.isEmpty ? 30.0 : ts.last);
    double xOf(double t) => (t / maxT).clamp(0.0, 1.0).toDouble() * w;

    c.save();
    c.clipRect(Rect.fromLTWH(0, 0, w * reveal, h));
    // هێڵی ناوەند (پچڕپچڕ)
    final ay = yOf(avg);
    final dp = Paint()
      ..color = grid
      ..strokeWidth = 1;
    for (double x = 0; x < w; x += 7) {
      c.drawLine(Offset(x, ay), Offset(math.min(w, x + 3), ay), dp);
    }
    if (ts.length >= 2) {
      final line = Path();
      for (var i = 0; i < ts.length; i++) {
        final x = xOf(ts[i]), y = yOf(vs[i]);
        if (i == 0) {
          line.moveTo(x, y);
        } else {
          line.lineTo(x, y);
        }
      }
      final area = Path.from(line)
        ..lineTo(xOf(ts.last), h)
        ..lineTo(xOf(ts.first), h)
        ..close();
      c.drawPath(
        area,
        Paint()..shader = ui.Gradient.linear(Offset.zero, Offset(0, h), [_P.red.withValues(alpha: .35), _P.red.withValues(alpha: 0)]),
      );
      c.drawPath(
        line,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.4
          ..strokeJoin = StrokeJoin.round
          ..strokeCap = StrokeCap.round
          ..color = _P.red,
      );
      var imn = 0, imx = 0;
      for (var i = 1; i < vs.length; i++) {
        if (vs[i] < vs[imn]) imn = i;
        if (vs[i] > vs[imx]) imx = i;
      }
      void dot(int i, Color col) {
        final o = Offset(xOf(ts[i]), yOf(vs[i]));
        c.drawCircle(o, 4, Paint()..color = card);
        c.drawCircle(
          o,
          4,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2
            ..color = col,
        );
      }

      dot(imx, _P.red);
      dot(imn, _P.mint);
    }
    c.restore();
  }

  @override
  bool shouldRepaint(covariant _TrendPainter o) => o.reveal != reveal || o.ts != ts || o.vs != vs || o.avg != avg || o.card != card || o.grid != grid;
}

/// ڕیزی 10 چرکەیی لەسەر کاغەزی سوور (25mm/s)
class _StripPainter extends CustomPainter {
  _StripPainter(this.tr, this.a, this.b, this.reveal);
  final List<double> tr;
  final int a, b;
  final double reveal;

  @override
  void paint(Canvas c, Size s) {
    c.drawRect(Offset.zero & s, Paint()..color = Colors.white);
    // 10 چرکە = 250mm
    final mm = s.width / 250;
    final small = Paint()
      ..color = const Color(0x12E53935)
      ..strokeWidth = 1;
    final big = Paint()
      ..color = const Color(0x2EE53935)
      ..strokeWidth = 1;
    for (var i = 0; i * mm <= s.width + .5; i++) {
      c.drawLine(Offset(i * mm, 0), Offset(i * mm, s.height), i % 5 == 0 ? big : small);
    }
    for (var j = 0; j * mm <= s.height + .5; j++) {
      c.drawLine(Offset(0, j * mm), Offset(s.width, j * mm), j % 5 == 0 ? big : small);
    }
    c.drawRect(
      Offset.zero & s,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = const Color(0xFFF0D6D6),
    );
    final n = b - a;
    if (n < 2 || tr.length < b) return;
    final mid = s.height * .52, amp = s.height * .40;
    final path = Path();
    final last = (n * reveal).floor().clamp(1, n - 1).toInt();
    for (var i = 0; i <= last; i++) {
      final x = i / (n - 1) * s.width, y = mid - tr[a + i] * amp;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    c.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xFFD32F2F),
    );
  }

  @override
  bool shouldRepaint(covariant _StripPainter o) => o.reveal != reveal || o.tr != tr || o.a != a || o.b != b;
}

/// هێڵی بچووکی مێژوو (3 چرکەی ناوەڕاستی تۆمارەکە)
class _SparkPainter extends CustomPainter {
  _SparkPainter(this.tr, this.rate);
  final List<double> tr;
  final double rate;
  @override
  void paint(Canvas c, Size s) {
    if (tr.length < 20) return;
    final r = rate <= 0 ? 85.0 : rate;
    final n = math.min(tr.length, (r * 3).round());
    final a = ((tr.length - n) / 3).floor().clamp(0, tr.length - n).toInt();
    final p = Path();
    for (var i = 0; i < n; i++) {
      final x = i / (n - 1) * s.width, y = s.height * .55 - tr[a + i] * s.height * .42;
      if (i == 0) {
        p.moveTo(x, y);
      } else {
        p.lineTo(x, y);
      }
    }
    c.drawPath(
      p,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round
        ..color = _P.red,
    );
  }

  @override
  bool shouldRepaint(covariant _SparkPainter o) => o.tr != tr;
}
