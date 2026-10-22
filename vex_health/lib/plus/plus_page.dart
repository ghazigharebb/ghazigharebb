// VEX Plus — پەڕەی بەشداربوون و پارەدان (1 / 6 / 12 مانگ، 50٪ داشکان)
// دیزاینی نوێ: پلانی خلیسکاو، لیستی FIB / Qi Card / FastPay، لاپەڕەی تایبەتمەندییەکان، فوتەری جێگیر.
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../band/band_pair_card.dart' show showBandPair;
import '../core/icons.dart';
import '../core/theme.dart';
import 'pay_sheet.dart';
import 'plus_state.dart';

const Color _gold1 = Color(0xFFFFE29A);
const Color _gold2 = Color(0xFFFFBF47);
const Color _gold3 = Color(0xFFFF9D3D);
const Color _brown = Color(0xFF3B2500);
const Color _bg = Color(0xFF04161C);
const Color _mu = Color(0xFF9CC4CB);
const Color _line = Color(0x298CEBF5);
const Color _surf = Color(0xFF0A2F3A);
const Color _surf2 = Color(0xFF0D3845);
const Color _coral = Color(0xFFFF5F7E);
const Color _tx = Color(0xFFF2FBFD);

// پەڕەی Plus دورگەیەکی تاریکە: ڕەنگی نووسین جێگیرە و بە تیمی ڕووناک ناگۆڕێت
TextStyle _ku(double size, {FontWeight w = FontWeight.w400, Color c = _tx, double? h}) => ku(size, w: w, c: c, h: h);
TextStyle _nu(double size, {FontWeight w = FontWeight.w800, Color c = _tx, double? h}) => nu(size, w: w, c: c, h: h);

Color _hex(String h) => Color(int.parse('FF${h.substring(1)}', radix: 16));

String _ar(int n) => n.toString().split('').map((d) => '٠١٢٣٤٥٦٧٨٩'[int.parse(d)]).join();

// ---------- ئایکۆنەکان ----------
class _P {
  static const cam = '<path d="M4 8h3l1.5-2h7L17 8h3v11H4z"/><circle cx="12" cy="13.5" r="3.5"/>';
  static const spark =
      '<path d="M12 3l1.8 5.2L19 10l-5.2 1.8L12 17l-1.8-5.2L5 10l5.2-1.8z"/><path d="M19 16l.7 1.8 1.8.7-1.8.7L19 21l-.7-1.8-1.8-.7 1.8-.7z"/>';
  static const chat = '<path d="M20 12a8 8 0 0 1-11.6 7.1L4 20l1-4A8 8 0 1 1 20 12z"/><path d="M9 11h6M9 14h4"/>';
  static const fork = '<path d="M7 3v8a2 2 0 0 0 2 2v8M7 3v5M11 3v5M17 3c-2 2-3 5-3 8h3v10"/>';
  static const plan = '<rect x="4" y="5" width="16" height="15" rx="3"/><path d="M8 3v4M16 3v4M4 10h16M8 14h3"/>';
  static const pill = '<rect x="3.5" y="9" width="17" height="6" rx="3" transform="rotate(-35 12 12)"/><path d="M10.5 8.2l3 7.6"/>';
  static const dna = '<path d="M8 3c0 5 8 5 8 10s-8 5-8 8M16 3c0 5-8 5-8 10s8 5 8 8M9 7h6M9 17h6"/>';
  static const ecg = '<path d="M3 12h4l2-5 4 10 2-5h6"/>';
  static const book = '<path d="M5 4h10a3 3 0 0 1 3 3v13H8a3 3 0 0 1-3-3z"/><path d="M8 8h6M8 12h6"/>';
  static const brain =
      '<path d="M9.5 4.5a3 3 0 0 0-3 3 3 3 0 0 0-2 5.2 3 3 0 0 0 2 4.8 3 3 0 0 0 5.5 1V6.3a3 3 0 0 0-2.5-1.8z"/><path d="M14.5 4.5a3 3 0 0 1 3 3 3 3 0 0 1 2 5.2 3 3 0 0 1-2 4.8 3 3 0 0 1-5.5 1"/>';
  static const chart = '<path d="M4 20V4M4 20h16"/><path d="M8 15l3-4 3 2 5-7"/>';
  static const mail = '<rect x="3" y="5" width="18" height="14" rx="3"/><path d="M3 8l9 6 9-6"/>';
  static const run = '<circle cx="14" cy="4.5" r="2"/><path d="M8 21l3-6-2.5-2.5L10 8l4 1 2 3M11 15l3 2 1 4M10 8L7 11"/>';
  static const users =
      '<circle cx="9" cy="8" r="3.5"/><path d="M2.5 20c.6-3.6 3.2-5.5 6.5-5.5s5.9 1.9 6.5 5.5M16 4.8a3.4 3.4 0 0 1 0 6.4M18 14.8c1.9.7 3.2 2.3 3.5 5.2"/>';
  static const gift =
      '<rect x="3" y="9" width="18" height="12" rx="2"/><path d="M12 9v12M3 13h18M12 9c-2-4-6-3-5 0M12 9c2-4 6-3 5 0"/>';
  static const lock = '<rect x="5" y="11" width="14" height="9" rx="3"/><path d="M8 11V8a4 4 0 0 1 8 0v3"/>';
  static const check = '<path d="M5 12.5l4.5 4.5L19 7.5"/>';
  static const star = '<path d="M12 2c.6 4.9 2.4 8.6 10 10-7.6 1.4-9.4 5.1-10 10-.6-4.9-2.4-8.6-10-10 7.6-1.4 9.4-5.1 10-10z"/>';
}

class _Feat {
  const _Feat(this.icon, this.hex, this.title, this.desc);
  final String icon;
  final String hex;
  final String title;
  final String desc;
}

class _Group {
  const _Group(this.title, this.hex, this.icon, this.items);
  final String title;
  final String hex;
  final String icon;
  final List<_Feat> items;
}

const List<_Group> _groups = [
  _Group('VEX AI', '#b79bff', _P.spark, [
    _Feat(_P.cam, '#2fe6f3', 'سکانی خواردنی بێسنوور', 'وێنەی خواردنەکە بگرە و کالۆری و ماکرۆکانی دەزانیت'),
    _Feat(_P.chat, '#b79bff', 'VEX AI بێسنوور', 'هەر کاتێک و هەر چەندێک پرسیار بکە'),
    _Feat(_P.spark, '#ffd36b', 'ڕاهێنەری خۆراک بە AI', 'ڕێنمایی تایبەت بەپێی کێش و ئامانجەکەت'),
    _Feat(_P.fork, '#ff9466', '«برسیمە! چی بخۆم؟»', 'لە چرکەیەکدا ژەمێکی گونجاوت بۆ پێشنیار دەکات'),
  ]),
  _Group('خۆراک', '#3cf08a', _P.fork, [
    _Feat(_P.plan, '#3cf08a', 'پلانی ژەم بە AI', 'پلانی ڕۆژانە، لەگەڵ ڕێسێپتی کوردی'),
    _Feat(_P.pill, '#ff8fc8', 'ڤیتامین و کانزاکان', 'بزانە چیت کەمە و چی بخۆیت'),
  ]),
  _Group('تەندروستی', '#2fe6f3', _P.ecg, [
    _Feat(_P.dna, '#2fe6f3', 'VitalAge', 'تەمەنی ڕاستەقینەی جەستەت'),
    _Feat(_P.ecg, '#ff5f7e', 'ECG و ڕاپۆرتی AI', 'خوێندنەوەی ڕیتمی دڵ لەگەڵ ڕاپۆرت'),
    _Feat(_P.book, '#9b7bff', 'ڕۆژەکەت', 'نەخشەی تەواوی ڕۆژت، کاتژمێر بە کاتژمێر'),
    _Feat(_P.brain, '#ffbe4d', 'شیکاری AI بۆ تەندروستی', 'هەموو داتاکانی Band پێکەوە شیدەکاتەوە'),
    _Feat(_P.chart, '#3cf08a', 'مێژووی هەفتە و مانگ', 'گۆڕانکارییەکانت بە درێژایی کات ببینە'),
    _Feat(_P.mail, '#8ff3f9', 'ڕاپۆرتی هەفتانە بە AI', 'چی باش بوو و چی بگۆڕیت'),
  ]),
  _Group('وەرزش', '#ff9466', _P.run, [
    _Feat(_P.run, '#ff9466', 'پلانی ڕاهێنان بە AI', 'هەفتانە، بەپێی دڵ و خەو و ئامانجەکەت'),
  ]),
  _Group('خێزان', '#ff8fc8', _P.users, [
    _Feat(_P.users, '#ff8fc8', 'پرۆفایلی خێزان', 'تەندروستی هەموو ئەندامانی خێزان لە یەک شوێن، هەر یەکە بە پرۆفایلی خۆی'),
  ]),
];

int get _featCount => _groups.fold<int>(0, (a, g) => a + g.items.length);

class _Cmp {
  const _Cmp(this.label, this.free, this.plus);
  final String label;
  final String free; // y | n | دەق
  final String plus;
}

const List<_Cmp> _cmp = [
  _Cmp('ئامارەکانی Band', 'y', 'y'),
  _Cmp('تۆمارکردنی خواردن بە دەست', 'y', 'y'),
  _Cmp('سکانی خواردن بە وێنە', 'سنووردار', 'بێسنوور'),
  _Cmp('پرسیار لە VEX AI', 'n', 'y'),
  _Cmp('پلانی ژەم و ڕاهێنان', 'n', 'y'),
  _Cmp('ECG و VitalAge', 'n', 'y'),
  _Cmp('ڕاپۆرتی هەفتانە', 'n', 'y'),
  _Cmp('پرۆفایلی خێزان', 'n', 'y'),
];

enum _View { main, feats, paying, ok, fail }

/// پەڕەی VEX Plus. بانگ بکە: `PlusPage.open()`
class PlusPage extends StatefulWidget {
  const PlusPage({super.key, this.title, this.desc});
  final String? title;
  final String? desc;

  static Future<void> open({String? title, String? desc}) {
    final nav = navKey.currentState;
    if (nav == null) return Future<void>.value();
    return nav.push<void>(
      PageRouteBuilder<void>(
        opaque: true,
        transitionDuration: const Duration(milliseconds: 360),
        reverseTransitionDuration: const Duration(milliseconds: 260),
        pageBuilder: (c, a, b) => PlusPage(title: title, desc: desc),
        transitionsBuilder: (c, a, b, child) {
          final cv = CurvedAnimation(parent: a, curve: const Cubic(0.2, 0.9, 0.25, 1), reverseCurve: Curves.easeInCubic);
          return SlideTransition(
            position: Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero).animate(cv),
            child: FadeTransition(opacity: cv, child: child),
          );
        },
      ),
    );
  }

  @override
  State<PlusPage> createState() => _PlusPageState();
}

class _PlusPageState extends State<PlusPage> with TickerProviderStateMixin {
  // یەک AnimationController بۆ هەموو ئەنیمەیشنە بەردەوامەکان (لاگ ناکات)
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(seconds: 6))..repeat();
  // ئەنیمەیشنی هاتنەژوورەوەی لاپەڕەی تایبەتمەندییەکان
  late final AnimationController _enter = AnimationController(vsync: this, duration: const Duration(milliseconds: 1900));
  PlusPlan _plan = kPlusPlans[1];
  String _method = 'fib';
  _View _view = _View.main;
  bool _busy = false;
  bool _doneTrial = false;

  @override
  void dispose() {
    _c.dispose();
    _enter.dispose();
    super.dispose();
  }

  bool get _trial => PlusState.I.canTrial;

  Future<void> _pay() async {
    if (_busy) return; // دوو جار پەنجەلێدان ناچێتە ناو
    HapticFeedback.mediumImpact();
    final plan = _plan;
    final trial = _trial;
    // تاقیکردنەوەی خۆڕایی پارە ناڕوات؛ ئەگەرنا شیتی پارەدان (بارکۆد) بە شێوازی هەڵبژێردراو
    if (!trial) {
      final paid = await showPlusPay(plan, method: _method);
      if (paid != true || !mounted) return;
    }
    setState(() {
      _busy = true;
      _view = _View.paying;
    });
    try {
      await PlusState.I.activate(plan, trial: trial);
      if (!mounted) return;
      setState(() {
        _busy = false;
        _view = _View.ok;
        _doneTrial = trial;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _view = _View.fail;
      });
    }
  }

  void _openFeats() {
    HapticFeedback.selectionClick();
    setState(() => _view = _View.feats);
    _enter.forward(from: 0);
  }

  void _backToMain() => setState(() => _view = _View.main);

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final showBar = _view == _View.main || _view == _View.feats;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: kDarkIslandChrome, // پەڕەی Plus هەمیشە تاریکە ← ئایکۆنی شریتی سپی
      child: PopScope(
        canPop: !_busy && _view != _View.feats,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop && _view == _View.feats) _backToMain();
        },
        child: Scaffold(
          backgroundColor: _bg,
          body: Directionality(
            textDirection: kDir,
            child: Stack(
              children: [
                const Positioned.fill(child: DecoratedBox(decoration: BoxDecoration(color: _bg))),
                Positioned.fill(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 260),
                    child: switch (_view) {
                      _View.main => _mainView(mq),
                      _View.feats => _featsView(mq),
                      _View.paying => _paying(),
                      _View.ok => _success(),
                      _View.fail => _failed(),
                    },
                  ),
                ),
                if (showBar) Positioned(top: 0, left: 0, right: 0, child: _header(mq)),
                if (showBar) Positioned(left: 0, right: 0, bottom: 0, child: _footer(mq)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================ هێدەر ============================
  Widget _header(MediaQueryData mq) {
    final feats = _view == _View.feats;
    return Container(
      height: mq.padding.top + 58,
      padding: EdgeInsets.fromLTRB(16, mq.padding.top + 8, 16, 0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_bg, _bg, op(_bg, 0)],
          stops: const [0, 0.72, 1],
        ),
      ),
      child: Row(
        children: [
          Press(
            onTap: () => feats ? _backToMain() : Navigator.of(context).maybePop(),
            child: Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(13),
                color: _surf,
                border: Border.all(color: _line),
              ),
              child: Icon(kIsLtr ? Icons.arrow_back_ios_new_rounded : Icons.arrow_forward_ios_rounded, size: 17, color: const Color(0xFFCFE9EE)),
            ),
          ),
          Expanded(
            child: SizedBox(
              height: 38,
              child: Center(
                child: feats
                    ? VText('ئەوەی بە Plus وەریدەگریت', style: _ku(16, w: FontWeight.w800, h: 1.4))
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('VEX Plus', textDirection: TextDirection.ltr, style: _nu(18, h: 1.3)),
                          const SizedBox(width: 7),
                          svgIcon(_P.star, '#ffbe4d', size: 17, fill: true),
                        ],
                      ),
              ),
            ),
          ),
          const SizedBox(width: 38),
        ],
      ),
    );
  }

  Widget _sec(String t) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 20, 4, 10),
        child: VText(t, style: _ku(13, w: FontWeight.w800, c: _mu, h: 1.4)),
      );

  Widget _pill(String s, List<Color> cs, Color fg, {double size = 11}) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 2),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(99), gradient: LinearGradient(colors: cs)),
        child: VText(s, style: _ku(size, w: FontWeight.w800, c: fg, h: 1.6)),
      );

  // ============================ ناوەکی ============================
  Widget _mainView(MediaQueryData mq) {
    return SingleChildScrollView(
      key: const ValueKey('main'),
      padding: EdgeInsets.fromLTRB(16, mq.padding.top + 58, 16, 112 + mq.padding.bottom),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 470),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (widget.title != null) _ctxBanner(),
              _sec('ماوەی ئابوونە'),
              _planChips(),
              const SizedBox(height: 12),
              _planSub(),
              _sec('شێوازی پارەدان'),
              _methods(),
              const SizedBox(height: 14),
              _featLink(),
              const SizedBox(height: 14),
              _bandGift(),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  svgIcon(_P.lock, '#9cc4cb', size: 13),
                  const SizedBox(width: 6),
                  VText('پارەدانەکە لە ئەپی هەڵبژێردراو تەواو دەکرێت', style: _ku(11.5, c: _mu, h: 1.4)),
                ],
              ),
              const SizedBox(height: 6),
              VText('دیمۆی تاقیکردنەوە · هیچ پارەیەکی ڕاستەقینە ناڕوات',
                  textAlign: TextAlign.center, style: _ku(10.5, c: const Color(0xFF6F969D), h: 1.6)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _ctxBanner() {
    return Container(
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: op(_gold2, 0.1),
        border: Border.all(color: op(_gold2, 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          VText(widget.title!, style: _ku(14.5, w: FontWeight.w800, c: _gold1, h: 1.5)),
          if (widget.desc != null) VText(widget.desc!, style: _ku(12.5, c: _mu, h: 1.7)),
        ],
      ),
    );
  }

  /// هەڵبژاردنی پلان: سێ چیپ + چوارچێوەیەکی زێڕین کە بە نەرمی دەخلیسکێت
  Widget _planChips() {
    const gap = 8.0, h = 100.0, head = 12.0;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final idx = kPlusPlans.indexWhere((p) => p.key == _plan.key);
    final slot = rtl ? (kPlusPlans.length - 1 - idx) : idx; // شوێنی ڕاستەقینە لە چەپەوە
    return LayoutBuilder(builder: (ctx, cs) {
      final w = (cs.maxWidth - gap * 2) / 3;
      return SizedBox(
        height: h + head,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              top: head,
              child: Row(
                children: [
                  for (int i = 0; i < kPlusPlans.length; i++) ...[
                    if (i > 0) const SizedBox(width: gap),
                    Expanded(child: _chip(kPlusPlans[i])),
                  ],
                ],
              ),
            ),
            AnimatedPositioned(
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutBack,
              left: slot * (w + gap),
              top: head,
              width: w,
              height: h,
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [op(_gold2, 0.26), op(_gold2, 0.05)],
                    ),
                    border: Border.all(color: op(_gold2, 0.75), width: 1.5),
                    boxShadow: [BoxShadow(color: op(const Color(0xFFFFAA32), 0.5), blurRadius: 26, offset: const Offset(0, 10), spreadRadius: -10)],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _chip(PlusPlan p) {
    final on = p.key == _plan.key;
    return Press(
      scale: 0.96,
      onTap: () {
        if (on) return;
        HapticFeedback.selectionClick();
        setState(() => _plan = p);
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                color: _surf,
                border: Border.all(color: _line, width: 1.5),
              ),
            ),
          ),
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(4, 18, 4, 10),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  VText(plusTxt(p.name), style: _ku(13, w: FontWeight.w700, c: _mu, h: 1.4)),
                  AnimatedScale(
                    scale: on ? 1.08 : 1,
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.elasticOut,
                    child: TweenAnimationBuilder<Color?>(
                      tween: ColorTween(end: on ? _gold1 : Colors.white),
                      duration: const Duration(milliseconds: 300),
                      builder: (_, col, __) => Text(fmt(p.price), textDirection: TextDirection.ltr, style: _nu(20, c: col ?? Colors.white, h: 1.3)),
                    ),
                  ),
                  Text(fmt(p.oldPrice),
                      textDirection: TextDirection.ltr,
                      style: _nu(11.5, w: FontWeight.w600, c: op(_mu, 0.85), h: 1.3)
                          .copyWith(decoration: TextDecoration.lineThrough, decorationColor: op(_mu, 0.85))),
                ],
              ),
            ),
          ),
          if (p.badge.isNotEmpty)
            Positioned(
              top: -11,
              left: 0,
              right: 0,
              child: Center(child: _pill(plusTxt(p.badge), const [_gold1, Color(0xFFFFB84D)], _brown, size: 10.5)),
            ),
        ],
      ),
    );
  }

  /// ڕیزی «٥٠٪ داشکان + نرخی مانگانە»: بەرزییەکەی جێگیرە، بۆیە شتەکانی خوارەوە ناگۆڕێن
  Widget _planSub() {
    return SizedBox(
      height: 34,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _pill('٥٠٪ داشکان', const [_gold1, Color(0xFFFFB84D)], _brown),
          const SizedBox(width: 8),
          Flexible(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              transitionBuilder: (child, a) => FadeTransition(
                opacity: a,
                child: SlideTransition(position: Tween<Offset>(begin: const Offset(0, 0.4), end: Offset.zero).animate(a), child: child),
              ),
              child: VText(plusTxt(_plan.sub), key: ValueKey(_plan.key), maxLines: 1, overflow: TextOverflow.ellipsis, style: _ku(12.5, c: _mu, h: 1.4)),
            ),
          ),
        ],
      ),
    );
  }

  /// لیستی شێوازەکانی پارەدان (یەک کارتی پاک، هەر ڕیزێک بە ڕەنگی برەندەکەی)
  Widget _methods() {
    return Container(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), color: _surf, border: Border.all(color: _line)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(19),
        child: Column(
          children: [
            for (int i = 0; i < kPayMethods.length; i++) ...[
              if (i > 0) Container(height: 1, color: _line),
              _methodRow(kPayMethods[i]),
            ],
          ],
        ),
      ),
    );
  }

  Widget _methodRow(PayMethod m) {
    final on = m.id == _method;
    return Press(
      scale: 0.99,
      onTap: () {
        if (on) return;
        HapticFeedback.selectionClick();
        setState(() => _method = m.id);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        color: on ? _surf2 : Colors.transparent,
        foregroundDecoration: BoxDecoration(border: Border.all(color: on ? m.accent : Colors.transparent, width: 2)),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(m.asset, width: 42, height: 42, fit: BoxFit.cover),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(m.name, textDirection: TextDirection.ltr, style: _nu(16, h: 1.4)),
                  VText(m.sub, style: _ku(12, c: _mu, h: 1.5)),
                ],
              ),
            ),
            AnimatedScale(
              scale: on ? 1.08 : 1,
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutBack,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 24,
                height: 24,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: on ? m.accent : Colors.transparent,
                  border: Border.all(color: on ? m.accent : const Color(0x668CEBF5), width: 2),
                ),
                child: on ? svgIcon(_P.check, '#ffffff', size: 14, stroke: 3.2) : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ڕیزی «ئەوەی بە Plus وەریدەگریت»
  Widget _featLink() {
    return Press(
      onTap: _openFeats,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: _surf,
          border: Border.all(color: op(_gold2, 0.6)),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 24.0 * 4 - 8.0 * 3,
              height: 26,
              child: Stack(
                children: [
                  for (int i = 0; i < 4; i++)
                    PositionedDirectional(
                      start: i * 16.0,
                      child: Container(
                        width: 26,
                        height: 26,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(colors: [_gold1, _gold2, _gold3]),
                          border: Border.all(color: _surf, width: 2),
                        ),
                        child: svgIcon(_P.check, '#3b2500', size: 12, stroke: 3.2),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: VText('ئەوەی بە Plus وەریدەگریت', style: _ku(13.5, w: FontWeight.w800, h: 1.5))),
            Icon(kIsLtr ? Icons.chevron_right_rounded : Icons.chevron_left_rounded, color: _mu, size: 22),
          ],
        ),
      ),
    );
  }

  Widget _bandGift() {
    final used = PlusState.I.bandGiftUsed;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(colors: [op(const Color(0xFFFFBE4D), 0.16), op(const Color(0xFFFFBE4D), 0.04)]),
        border: Border.all(color: op(const Color(0xFFFFBE4D), 0.38)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: op(const Color(0xFFFFBE4D), 0.15), borderRadius: BorderRadius.circular(14)),
            child: svgIcon(_P.gift, '#ffbe4d', size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                VText('VEX Band ت کڕیوە؟', style: _ku(13.5, w: FontWeight.w800, c: _gold1, h: 1.4)),
                VText(used ? 'دیارییەکە پێشتر وەرگیراوە' : '6 مانگ Plus بە خۆڕایی وەربگرە', style: _ku(11.5, c: const Color(0xFFD9BF85), h: 1.4)),
              ],
            ),
          ),
          if (!used)
            Press(
              onTap: () {
                Navigator.of(context).maybePop();
                showBandPair();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: op(const Color(0xFFFFBE4D), 0.1),
                  border: Border.all(color: op(const Color(0xFFFFBE4D), 0.5)),
                ),
                child: VText('پەیوەستکردن', style: _ku(12, w: FontWeight.w700, c: _gold1, h: 1.3)),
              ),
            ),
        ],
      ),
    );
  }

  // ============================ لاپەڕەی تایبەتمەندییەکان ============================
  /// دەرکەوتنی پلەپلە (fade + slide) بۆ هەر توخمێک
  Widget _rv(int i, Widget child) {
    final s = (i * 0.05).clamp(0.0, 0.62).toDouble();
    final a = _enter.drive(CurveTween(curve: Interval(s, math.min(1.0, s + 0.38), curve: Curves.easeOutCubic)));
    return FadeTransition(
      opacity: a,
      child: SlideTransition(position: a.drive(Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)), child: child),
    );
  }

  Widget _featsView(MediaQueryData mq) {
    int n = 0;
    final kids = <Widget>[_rv(n++, _featHero())];
    for (final g in _groups) {
      kids.add(_rv(n++, _groupHead(g)));
      final it = g.items;
      for (int i = 0; i < it.length; i += 2) {
        final two = i + 1 < it.length;
        kids.add(Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _rv(
            n++,
            two
                ? IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(child: _featCard(it[i], i, false)),
                        const SizedBox(width: 10),
                        Expanded(child: _featCard(it[i + 1], i + 1, false)),
                      ],
                    ),
                  )
                : _featCard(it[i], i, true),
          ),
        ));
      }
    }
    kids.add(_rv(n++, _compare()));
    kids.add(const SizedBox(height: 18));
    kids.add(_rv(
      n++,
      Column(
        children: [
          VText('هەموو ئەمانە بە یەک ئابوونە.', textAlign: TextAlign.center, style: _ku(13, w: FontWeight.w800, h: 1.8)),
          VText('هەر کاتێک بتەوێت دەتوانیت دەست پێبکەیت.', textAlign: TextAlign.center, style: _ku(13, c: _mu, h: 1.8)),
        ],
      ),
    ));
    return SingleChildScrollView(
      key: const ValueKey('feats'),
      padding: EdgeInsets.fromLTRB(16, mq.padding.top + 58, 16, 112 + mq.padding.bottom),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 470),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: kids),
        ),
      ),
    );
  }

  Widget _featHero() {
    Widget p(String s, {Widget? lead}) => Flexible(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(99),
              color: _surf,
              border: Border.all(color: op(_gold2, 0.5)),
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                if (lead != null) ...[lead, const SizedBox(width: 5)],
                VText(s, maxLines: 1, style: _ku(11.5, w: FontWeight.w700, h: 1.4)),
              ]),
            ),
          ),
        );
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [op(_gold2, 0.3), op(_gold2, 0.07), op(const Color(0xFF2FE6F3), 0.1)],
          ),
          border: Border.all(color: op(_gold2, 0.5), width: 1.5),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: IgnorePointer(
                child: RepaintBoundary(
                  child: AnimatedBuilder(animation: _c, builder: (_, __) => CustomPaint(painter: _HeroBg(_c.value))),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 34, 14, 24),
              child: Column(
                children: [
                  ShaderMask(
                    shaderCallback: (r) => const LinearGradient(colors: [Color(0xFFFFF2C2), _gold2]).createShader(r),
                    child: Text('VEX Plus', textDirection: TextDirection.ltr, style: _nu(34, c: Colors.white, h: 1.2)),
                  ),
                  const SizedBox(height: 6),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 320),
                    child: VText('هەموو تەندروستیت لە یەک شوێن، لەگەڵ ڕاوێژکارێکی AI تایبەت بە تۆ',
                        textAlign: TextAlign.center, style: _ku(14.5, w: FontWeight.w600, c: _gold1, h: 1.9)),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      p('تایبەتمەندی', lead: Text(_ar(_featCount), style: _nu(12, c: _gold2, h: 1.2))),
                      const SizedBox(width: 6),
                      p('AI بێسنوور'),
                      const SizedBox(width: 6),
                      p('٥٠٪ داشکان'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _groupHead(_Group g) {
    final c = _hex(g.hex);
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 26, 4, 12),
      child: Row(
        children: [
          AnimatedBuilder(
            animation: _c,
            builder: (_, child) => Transform.translate(offset: Offset(0, -2.5 * math.sin(_c.value * 2 * math.pi)), child: child),
            child: Container(
              width: 30,
              height: 30,
              alignment: Alignment.center,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), color: c),
              child: svgIcon(g.icon, '#062832', size: 17),
            ),
          ),
          const SizedBox(width: 10),
          VText(g.title, style: _ku(16, w: FontWeight.w800, h: 1.4)),
          const Spacer(),
          VText('${_ar(g.items.length)} تایبەتمەندی', style: _ku(11.5, w: FontWeight.w700, c: _mu, h: 1.4)),
        ],
      ),
    );
  }

  Widget _neonTile(_Feat f, int i) {
    final c = _hex(f.hex);
    return AnimatedBuilder(
      animation: _c,
      builder: (_, child) {
        final s = math.sin((_c.value + i * 0.12) * 2 * math.pi);
        return Transform.translate(offset: Offset(0, -4 * s), child: Transform.rotate(angle: -0.05 * s, child: child));
      },
      child: Container(
        width: 46,
        height: 46,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [op(c, 0.3), op(c, 0.06)]),
          border: Border.all(color: op(c, 0.65), width: 1.5),
          boxShadow: [BoxShadow(color: op(c, 0.4), blurRadius: 18, spreadRadius: -6)],
        ),
        child: svgIcon(f.icon, f.hex, size: 24),
      ),
    );
  }

  Widget _featCard(_Feat f, int i, bool wide) {
    final c = _hex(f.hex);
    final text = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        VText(f.title, style: _ku(13.5, w: FontWeight.w800, h: 1.55)),
        const SizedBox(height: 2),
        VText(f.desc, style: _ku(12, c: _mu, h: 1.7)),
      ],
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.fromLTRB(13, 14, 13, 15),
        decoration: BoxDecoration(
          color: _surf,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: _line),
          gradient: RadialGradient(center: const Alignment(1, -1), radius: 1.0, colors: [op(c, 0.2), op(_surf, 0)]),
        ),
        child: wide
            ? Row(children: [_neonTile(f, i), const SizedBox(width: 13), Expanded(child: text)])
            : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_neonTile(f, i), const SizedBox(height: 10), text]),
      ),
    );
  }

  Widget _cmpCell(String v, bool plus) {
    if (v == 'y') {
      return Container(
        width: 22,
        height: 22,
        alignment: Alignment.center,
        decoration: plus
            ? const BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [_gold1, _gold2, _gold3]))
            : BoxDecoration(shape: BoxShape.circle, color: const Color(0x14FFFFFF), border: Border.all(color: _line)),
        child: svgIcon(_P.check, plus ? '#3b2500' : '#9cc4cb', size: 13, stroke: 3.2),
      );
    }
    if (v == 'n') {
      return Container(
        width: 22,
        height: 22,
        alignment: Alignment.center,
        decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0x14FFFFFF), border: Border.all(color: _line)),
        child: svgIcon(_P.lock, '#9cc4cb', size: 12),
      );
    }
    return VText(v, textAlign: TextAlign.center, style: _ku(11.5, w: FontWeight.w800, c: plus ? _gold2 : _mu, h: 1.4));
  }

  Widget _compare() {
    const cw = 74.0;
    Widget head() => SizedBox(
          height: 48,
          child: Row(
            children: [
              const Expanded(child: SizedBox()),
              SizedBox(width: cw, child: Center(child: VText('بێ بەرامبەر', style: _ku(11, w: FontWeight.w700, c: _mu, h: 1.3)))),
              Container(
                width: cw,
                height: 48,
                alignment: Alignment.center,
                decoration: const BoxDecoration(gradient: LinearGradient(colors: [_gold1, _gold2, _gold3])),
                child: VText('Plus', style: _ku(12, w: FontWeight.w800, c: _brown, h: 1.3)),
              ),
            ],
          ),
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 26, 4, 12),
          child: Row(
            children: [
              Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), color: const Color(0xFFFFBE4D)),
                child: svgIcon(_P.chart, '#062832', size: 17),
              ),
              const SizedBox(width: 10),
              VText('بێ بەرامبەر یان Plus؟', style: _ku(16, w: FontWeight.w800, h: 1.4)),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(24), color: _surf, border: Border.all(color: _line)),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(23),
            child: Column(
              children: [
                head(),
                for (final r in _cmp) ...[
                  Container(height: 1, color: _line),
                  SizedBox(
                    height: 52,
                    child: Row(
                      children: [
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            child: VText(r.label, style: _ku(12.5, w: FontWeight.w700, h: 1.5)),
                          ),
                        ),
                        SizedBox(width: cw, child: Center(child: _cmpCell(r.free, false))),
                        Container(width: cw, height: 52, alignment: Alignment.center, color: op(const Color(0xFFFFBE4D), 0.1), child: _cmpCell(r.plus, true)),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ============================ خوارەوەی جێگیر ============================
  /// نرخ (بەرپانی جێگیر) + دوگمەی پارەدان بە ڕەنگی شێوازەکە. لۆگۆکە هەرگیز گەورە و بچووک نابێت.
  Widget _footer(MediaQueryData mq) {
    final p = _plan;
    final trial = _trial;
    final m = payMethodOf(_method);
    final btn = trial ? _gold2 : m.btn;
    final fg = trial ? _brown : m.btnText;
    return Container(
      padding: EdgeInsets.fromLTRB(16, 10, 16, mq.padding.bottom + 10),
      decoration: BoxDecoration(
        color: _bg,
        border: const Border(top: BorderSide(color: Color(0x24FFD678))),
        boxShadow: [BoxShadow(color: op(Colors.black, 0.35), blurRadius: 24, offset: const Offset(0, -10), spreadRadius: -12)],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 132,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                VText('کۆی گشتی', style: _ku(11.5, w: FontWeight.w600, c: _mu, h: 1.3)),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    TweenAnimationBuilder<double>(
                      tween: Tween<double>(end: p.price.toDouble()),
                      duration: const Duration(milliseconds: 420),
                      curve: Curves.easeOutCubic,
                      builder: (_, v, __) => Text(fmt(v.round()), textDirection: TextDirection.ltr, style: _nu(21, h: 1.3)),
                    ),
                    const SizedBox(width: 4),
                    Text('IQD', textDirection: TextDirection.ltr, style: _nu(11, w: FontWeight.w700, c: _mu, h: 1.3)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Press(
              onTap: _pay,
              scale: 0.97,
              child: AnimatedBuilder(
                animation: _c,
                builder: (_, __) {
                  final t = _c.value;
                  final glow = 0.32 + 0.2 * (0.5 + 0.5 * math.sin(t * 2 * math.pi * 2));
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 260),
                    height: 50,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(17),
                      color: btn,
                      boxShadow: [BoxShadow(color: op(btn, glow), blurRadius: 24, offset: const Offset(0, 9), spreadRadius: -8)],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(17),
                      child: LayoutBuilder(builder: (ctx, cs) {
                        final w = cs.maxWidth;
                        final k = (t * 1.6) % 1.0; // هەر ~3.7 چرکە جارێک تیشکەکە تێدەپەڕێت
                        final x = -0.6 * w + 2.0 * w * (k < 0.5 ? k / 0.5 : 1.0);
                        return Stack(
                          alignment: Alignment.center,
                          children: [
                            if (k < 0.5)
                              Positioned(
                                left: x,
                                top: 0,
                                bottom: 0,
                                width: w * 0.45,
                                child: Transform(
                                  transform: Matrix4.skewX(-0.3),
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(colors: [op(Colors.white, 0), op(Colors.white, 0.28), op(Colors.white, 0)]),
                                    ),
                                  ),
                                ),
                              ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (!trial) ...[
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(9),
                                      child: Image.asset(m.asset, width: 30, height: 30, fit: BoxFit.cover),
                                    ),
                                    const SizedBox(width: 10),
                                  ],
                                  Flexible(
                                    child: VText(trial ? '7 ڕۆژ بە خۆڕایی دەستپێبکە' : 'پارەدان بە ${m.name}',
                                        maxLines: 1, overflow: TextOverflow.ellipsis, style: _ku(16, w: FontWeight.w800, c: fg, h: 1.3)),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      }),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================ دۆخەکانی تر ============================
  Widget _paying() {
    return Center(
      key: const ValueKey('pay'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 52,
            height: 52,
            child: CircularProgressIndicator(strokeWidth: 4, color: _gold2, backgroundColor: Color(0x1FFFFFFF)),
          ),
          const SizedBox(height: 18),
          VText('چالاک دەکرێت…', style: _ku(16, w: FontWeight.w800, h: 1.5)),
          VText('تکایە ئەم پەڕەیە دامەخە', style: _ku(12.5, c: _mu, h: 1.6)),
        ],
      ),
    );
  }

  Widget _success() {
    const perks = ['سکانی خواردنی بێسنوور', 'VEX AI', 'پلانی AI', 'ECG و VitalAge'];
    return Center(
      key: const ValueKey('ok'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0.6, end: 1),
              duration: const Duration(milliseconds: 650),
              curve: Curves.elasticOut,
              builder: (_, v, child) => Transform.scale(scale: v, child: child),
              child: Container(
                width: 88,
                height: 88,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFFFFE9A8), _gold2, _gold3]),
                  boxShadow: [BoxShadow(color: op(const Color(0xFFFFB43C), 0.7), blurRadius: 40, offset: const Offset(0, 16), spreadRadius: -10)],
                ),
                child: svgIcon(_P.check, '#3b2500', size: 44, stroke: 2.8),
              ),
            ),
            const SizedBox(height: 20),
            VText(_doneTrial ? '7 ڕۆژی Plus دەستی پێکرد' : 'بەخێربێیت بۆ VEX Plus', textAlign: TextAlign.center, style: _ku(22, w: FontWeight.w800, h: 1.5)),
            const SizedBox(height: 4),
            if (_doneTrial)
              VText('هەموو تواناکان کرانەوە. دوای 7 ڕۆژ دەگەڕێیتەوە بۆ خۆڕایی ئەگەر بەشدار نەبیت.',
                  textAlign: TextAlign.center, style: _ku(13, c: _mu, h: 1.8))
            else ...[
              VText('ئابوونەکەت چالاک کرا', textAlign: TextAlign.center, style: _ku(13, c: _mu, h: 1.8)),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  VText('چالاکە تا', style: _ku(12.5, c: _mu, h: 1.6)),
                  const SizedBox(width: 6),
                  VText(PlusState.I.untilText, textDirection: TextDirection.ltr, style: _nu(13, c: _gold1, h: 1.6)),
                ],
              ),
            ],
            const SizedBox(height: 18),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final s in perks)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(99), color: _surf, border: Border.all(color: op(_gold2, 0.5))),
                    child: VText(s, style: _ku(12.5, w: FontWeight.w700, h: 1.4)),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            Press(
              onTap: () => Navigator.of(context).maybePop(),
              child: Container(
                height: 54,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: const LinearGradient(colors: [_gold1, _gold2, _gold3]),
                ),
                child: VText('دەستپێبکە', style: _ku(15.5, w: FontWeight.w800, c: _brown, h: 1.3)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _failed() {
    return Center(
      key: const ValueKey('fail'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              alignment: Alignment.center,
              decoration: BoxDecoration(shape: BoxShape.circle, color: op(_coral, 0.15), border: Border.all(color: op(_coral, 0.5))),
              child: Icon(Icons.close_rounded, color: _coral, size: 36),
            ),
            const SizedBox(height: 16),
            VText('پارەدانەکە سەرنەکەوت', style: _ku(20, w: FontWeight.w800, h: 1.5)),
            VText('هیچ پارەیەک نەبڕدرا. دووبارە هەوڵ بدەوە یان شێوازێکی تر هەڵبژێرە.', textAlign: TextAlign.center, style: _ku(13, c: _mu, h: 1.8)),
            const SizedBox(height: 20),
            Press(
              onTap: _pay,
              child: Container(
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(18), gradient: const LinearGradient(colors: [_gold1, _gold2, _gold3])),
                child: VText('دووبارە هەوڵ بدەوە', style: _ku(15, w: FontWeight.w800, c: _brown, h: 1.3)),
              ),
            ),
            const SizedBox(height: 10),
            Press(
              onTap: _backToMain,
              child: Container(
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: _line)),
                child: VText('گۆڕینی پلان یان شێوازی پارەدان', style: _ku(13.5, w: FontWeight.w700, h: 1.3)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================ پاشبنەمای کارتی سەرەوە (بلۆبی زێڕین/سەوز + ئەستێرە) ============================
class _HeroBg extends CustomPainter {
  _HeroBg(this.t);
  final double t; // 0..1 (6 چرکە)

  @override
  void paint(Canvas canvas, Size size) {
    final a = t * 2 * math.pi;
    void blob(Offset c, double r, Color col, double alpha) {
      canvas.drawCircle(c, r, Paint()..shader = RadialGradient(colors: [op(col, alpha), op(col, 0)]).createShader(Rect.fromCircle(center: c, radius: r)));
    }

    blob(Offset(size.width * 0.9 + 16 * math.sin(a), -10 - 10 * math.cos(a)), 130, _gold2, 0.55);
    blob(Offset(size.width * 0.05 - 14 * math.cos(a), size.height + 10 + 12 * math.sin(a)), 120, const Color(0xFF2FE6F3), 0.34);
    blob(Offset(size.width * 0.5 + 18 * math.cos(a + 1), size.height * 0.45 + 10 * math.sin(a)), 80, const Color(0xFFB79BFF), 0.22);

    void star(Offset c, double r, double alpha) {
      final p = Path()
        ..moveTo(c.dx, c.dy - r)
        ..quadraticBezierTo(c.dx + r * 0.12, c.dy - r * 0.12, c.dx + r, c.dy)
        ..quadraticBezierTo(c.dx + r * 0.12, c.dy + r * 0.12, c.dx, c.dy + r)
        ..quadraticBezierTo(c.dx - r * 0.12, c.dy + r * 0.12, c.dx - r, c.dy)
        ..quadraticBezierTo(c.dx - r * 0.12, c.dy - r * 0.12, c.dx, c.dy - r)
        ..close();
      canvas.drawPath(p, Paint()..color = op(_gold2, alpha));
    }

    double tw(double ph) {
      final k = math.sin(a * 2 + ph);
      return 0.15 + 0.85 * (0.5 + 0.5 * k);
    }

    star(Offset(size.width * 0.74, 26), 7, tw(0));
    star(Offset(size.width * 0.12, 58), 5, tw(2));
    star(Offset(size.width * 0.28, 18), 6, tw(4));
  }

  @override
  bool shouldRepaint(covariant _HeroBg o) => o.t != t;
}
