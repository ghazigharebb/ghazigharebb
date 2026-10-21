// VEX Plus — پەڕەی بەشداربوون و پارەدان (1 / 6 / 12 مانگ، 50٪ داشکان)
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../band/band_pair_card.dart' show showBandPair;
import '../core/icons.dart';
import '../core/theme.dart';
import 'plus_state.dart';

const Color _gold1 = Color(0xFFFFE29A);
const Color _gold2 = Color(0xFFFFBF47);
const Color _gold3 = Color(0xFFFF9D3D);
const Color _brown = Color(0xFF3B2500);
const Color _bg = Color(0xFF04161C);

Color _hex(String h) => Color(int.parse('FF${h.substring(1)}', radix: 16));

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
  static const baby =
      '<circle cx="12" cy="9" r="5"/><path d="M9.5 9.5h.01M14.5 9.5h.01M10 12c1 .9 3 .9 4 0M7 19c1-2 3-3 5-3s4 1 5 3"/>';
  static const users =
      '<circle cx="9" cy="8" r="3.5"/><path d="M2.5 20c.6-3.6 3.2-5.5 6.5-5.5s5.9 1.9 6.5 5.5M16 4.8a3.4 3.4 0 0 1 0 6.4M18 14.8c1.9.7 3.2 2.3 3.5 5.2"/>';
  static const gift =
      '<rect x="3" y="9" width="18" height="12" rx="2"/><path d="M12 9v12M3 13h18M12 9c-2-4-6-3-5 0M12 9c2-4 6-3 5 0"/>';
  static const shield = '<path d="M12 3l7 3v5c0 5-3 8.5-7 10-4-1.5-7-5-7-10V6z"/><path d="M9 12l2 2 4-4"/>';
  static const bolt = '<path d="M13 2L4 14h7l-1 8 9-12h-7z"/>';
  static const lock = '<rect x="5" y="11" width="14" height="9" rx="3"/><path d="M8 11V8a4 4 0 0 1 8 0v3"/>';
  static const check = '<path d="M5 12.5l4.5 4.5L19 7.5"/>';
}

class _Feat {
  const _Feat(this.icon, this.hex, this.title, this.desc);
  final String icon;
  final String hex;
  final String title;
  final String desc;
}

class _Group {
  const _Group(this.title, this.hex, this.items);
  final String title;
  final String hex;
  final List<_Feat> items;
}

const List<_Group> _groups = [
  _Group('VEX AI', '#b79bff', [
    _Feat(_P.cam, '#2fe6f3', 'سکانی خواردن بێسنوور', 'وێنەیەک بگرە، کالۆری و ماکرۆ دەزانیت'),
    _Feat(_P.chat, '#b79bff', 'VEX AI بێسنوور', 'هەر کاتێک و هەر چەندێک پرسیار بکە'),
    _Feat(_P.spark, '#ffd36b', 'ڕاهێنەری خۆراکی AI', 'وەڵامی تایبەت بەپێی کێش و ئامانجەکەت'),
    _Feat(_P.fork, '#ff9466', '«برسیمە! چی بخۆم؟»', 'پێشنیاری ژەمی گونجاو لە چرکەیەکدا'),
  ]),
  _Group('خۆراک و ژەم', '#3cf08a', [
    _Feat(_P.plan, '#3cf08a', 'پلانی ژەمی AI', 'ڕۆژانە، لەگەڵ ڕێسەتەی کوردی'),
    _Feat(_P.pill, '#ff8fc8', 'ڤیتامین و کانزاکان', 'بزانە چی کەمە و چی بخۆیت'),
  ]),
  _Group('تەندروستی قووڵ', '#2fe6f3', [
    _Feat(_P.dna, '#2fe6f3', 'VitalAge', 'تەمەنی ڕاستەقینەی جەستەت'),
    _Feat(_P.ecg, '#ff5f7e', 'ECG + ڕاپۆرتی AI', 'خوێندنەوەی ڕیتمی دڵ'),
    _Feat(_P.book, '#9b7bff', 'ڕۆژەکەت', 'نەخشەی تەواوی ڕۆژت، کاتژمێر بە کاتژمێر'),
    _Feat(_P.brain, '#ffbe4d', 'شیکاری AI ی تەندروستی', 'هەموو داتاکانی Band یەکەوە دەخوێنێتەوە'),
    _Feat(_P.chart, '#3cf08a', 'مێژووی هەفتە و مانگ', 'گۆڕانکاری بە درێژایی کات'),
    _Feat(_P.mail, '#8ff3f9', 'ڕاپۆرتی هەفتانەی AI', 'چی باش بوو و چی بگۆڕیت'),
  ]),
  _Group('وەرزش', '#ff9466', [
    _Feat(_P.run, '#ff9466', 'پلانی ڕاهێنانی AI', 'هەفتانە، بەپێی دڵ، خەو و ئامانج'),
  ]),
  _Group('خێزان', '#ff8fc8', [
    _Feat(_P.baby, '#ff8fc8', 'پرۆفایلی منداڵ', 'شیر، گەشە و خواردنی منداڵ'),
    _Feat(_P.users, '#ff8fc8', 'دایک و باوک', 'پرۆفایلی جیا بۆ هەر کەسێک'),
  ]),
];

enum _View { main, paying, ok, fail }

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

class _PlusPageState extends State<PlusPage> with SingleTickerProviderStateMixin {
  // یەک AnimationController بۆ هەموو ئەنیمەیشنەکان (لاگ ناکات)
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(seconds: 6))..repeat();
  PlusPlan _plan = kPlusPlans.last;
  String _method = 'FIB';
  _View _view = _View.main;
  bool _busy = false;
  String _done = '';
  String _doneDesc = '';

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  bool get _trial => PlusState.I.canTrial;

  Future<void> _pay() async {
    if (_busy) return; // دوو جار پەنجەلێدان ناچێتە ناو
    HapticFeedback.mediumImpact();
    setState(() {
      _busy = true;
      _view = _View.paying;
    });
    final plan = _plan;
    final trial = _trial;
    try {
      // تاقیکردنەوەی خۆڕایی پارە ناڕوات
      final ok = trial ? true : await PlusPayment.charge(_method, plan);
      if (!mounted) return;
      if (!ok) {
        setState(() {
          _busy = false;
          _view = _View.fail;
        });
        return;
      }
      await PlusState.I.activate(plan, trial: trial);
      if (!mounted) return;
      setState(() {
        _busy = false;
        _view = _View.ok;
        _done = trial ? '7 ڕۆژی Plus دەستی پێکرد' : 'بەخێربێیت بۆ VEX Plus';
        _doneDesc = trial
            ? 'هەموو تواناکان کرانەوە. دوای 7 ڕۆژ دەگەڕێیتەوە بۆ خۆڕایی ئەگەر بەشدار نەبیت.'
            : 'پلانی ${plan.name} چالاک کرا تا ${PlusState.I.untilText}. سوپاس بۆ پشتگیریت 💛';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _view = _View.fail;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    return PopScope(
      canPop: !_busy, // لە کاتی پارەدان ناگەڕێتەوە
      child: Scaffold(
        backgroundColor: _bg,
        body: Directionality(
          textDirection: TextDirection.rtl,
          child: Stack(
            children: [
              const Positioned.fill(child: DecoratedBox(decoration: BoxDecoration(color: _bg))),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 380,
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: const Alignment(0, -1),
                        radius: 1.1,
                        colors: [op(_gold2, 0.26), op(_gold2, 0.0)],
                      ),
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 260),
                  child: switch (_view) {
                    _View.main => _mainView(mq),
                    _View.paying => _paying(),
                    _View.ok => _success(),
                    _View.fail => _failed(),
                  },
                ),
              ),
              if (_view == _View.main)
                Positioned(
                  top: mq.padding.top + 10,
                  left: 14,
                  child: Press(
                    onTap: () => Navigator.of(context).maybePop(),
                    child: Container(
                      width: 38,
                      height: 38,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xD904161C),
                        border: Border.all(color: const Color(0x24FFFFFF)),
                      ),
                      child: const Icon(Icons.close_rounded, size: 19, color: Color(0xFFCFE9EE)),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================ ناوەکی ============================
  Widget _mainView(MediaQueryData mq) {
    return Stack(
      key: const ValueKey('main'),
      children: [
        Positioned.fill(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(14, mq.padding.top + 8, 14, 190 + mq.padding.bottom),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 470),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _hero(),
                    const SizedBox(height: 14),
                    for (final p in kPlusPlans) _planTile(p),
                    const SizedBox(height: 12),
                    _trust(),
                    const SizedBox(height: 22),
                    Text('ئەوەی بە Plus وەریدەگریت',
                        textAlign: TextAlign.center, style: ku(18, w: FontWeight.w800, h: 1.5)),
                    Text('14+ تایبەتمەندی کە ڕۆژانە بەکاری دەهێنیت',
                        textAlign: TextAlign.center, style: ku(12, c: const Color(0xFF8FB7BE), h: 1.6)),
                    const SizedBox(height: 10),
                    for (final g in _groups) _groupView(g),
                    const SizedBox(height: 4),
                    _compare(),
                    const SizedBox(height: 14),
                    _bandGift(),
                    const SizedBox(height: 14),
                    _pays(),
                    const SizedBox(height: 10),
                    Text('دیمۆی تاقیکردنەوە · هیچ پارەیەک نابڕدرێت',
                        textAlign: TextAlign.center, style: ku(10.5, c: const Color(0xFF6F969D))),
                  ],
                ),
              ),
            ),
          ),
        ),
        Positioned(left: 0, right: 0, bottom: 0, child: _footer(mq)),
      ],
    );
  }

  Widget _hero() {
    final title = widget.title ?? 'بێسنوور، زیرەکتر';
    final desc = widget.desc ?? 'هەموو تواناکانی VEX بکەرەوە.';
    return Column(
      children: [
        const SizedBox(height: 8),
        RepaintBoundary(
          child: AnimatedBuilder(
            animation: _c,
            builder: (_, __) => CustomPaint(size: const Size(260, 150), painter: _GemPainter(_c.value)),
          ),
        ),
        ShaderMask(
          shaderCallback: (r) => const LinearGradient(colors: [_gold1, _gold3]).createShader(r),
          child: Text('VEX PLUS', style: nu(15, c: Colors.white, ls: 5)),
        ),
        const SizedBox(height: 2),
        Text(title, textAlign: TextAlign.center, style: ku(25, w: FontWeight.w800, h: 1.4)),
        Text(desc, textAlign: TextAlign.center, style: ku(13, c: const Color(0xFF9CC4CB), h: 1.7)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(99),
            gradient: LinearGradient(colors: [op(const Color(0xFFFF5C5C), 0.2), op(_gold2, 0.2)]),
            border: Border.all(color: op(const Color(0xFFFF965A), 0.5)),
            boxShadow: [BoxShadow(color: op(const Color(0xFFFF783C), 0.4), blurRadius: 22, offset: const Offset(0, 8), spreadRadius: -10)],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🔥', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 7),
              Text('50٪ داشکان', style: ku(14, w: FontWeight.w800, c: _gold1, h: 1.4)),
              const SizedBox(width: 7),
              Text('لەسەر هەموو پلانەکان', style: ku(11.5, c: const Color(0xFFFFC9A0), h: 1.4)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _planTile(PlusPlan p) {
    final on = p.key == _plan.key;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Press(
        scale: 0.985,
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _plan = p);
        },
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.fromLTRB(14, 18, 14, 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: on ? LinearGradient(colors: [op(const Color(0xFFFFC95E), 0.15), op(const Color(0xFFFFC95E), 0.04)]) : null,
                color: on ? null : const Color(0x08FFFFFF),
                border: Border.all(color: on ? const Color(0xFFFFC95E) : const Color(0x2A8CEBF5), width: 1.5),
                boxShadow: on ? [BoxShadow(color: op(const Color(0xFFFFBE46), 0.4), blurRadius: 30, offset: const Offset(0, 14), spreadRadius: -16)] : null,
              ),
              child: Row(
                children: [
                  _radio(on),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p.name, style: ku(17, w: FontWeight.w800, h: 1.4)),
                        Text(p.sub, style: ku(11.5, c: const Color(0xFF9CC4CB), h: 1.5)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(fmt(p.oldPrice),
                          textDirection: TextDirection.ltr,
                          style: nu(12, w: FontWeight.w600, c: const Color(0xFFFF8A8A)).copyWith(
                              decoration: TextDecoration.lineThrough, decorationColor: const Color(0xFFFF5F5F))),
                      on
                          ? ShaderMask(
                              shaderCallback: (r) => const LinearGradient(colors: [Color(0xFFFFF2C2), _gold2]).createShader(r),
                              child: Text(fmt(p.price), textDirection: TextDirection.ltr, style: nu(22, c: Colors.white, h: 1.2)),
                            )
                          : Text(fmt(p.price), textDirection: TextDirection.ltr, style: nu(22, h: 1.2)),
                      Text(p.unit, style: ku(10.5, c: const Color(0xFF9CC4CB), h: 1.3)),
                    ],
                  ),
                ],
              ),
            ),
            Positioned(
              top: -10,
              left: 14,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(99),
                  gradient: const LinearGradient(colors: [Color(0xFFFF5F5F), _gold3]),
                  boxShadow: [BoxShadow(color: op(const Color(0xFFFF5A3C), 0.5), blurRadius: 12, offset: const Offset(0, 5), spreadRadius: -5)],
                ),
                child: Text('−50٪', textDirection: TextDirection.ltr, style: nu(11, c: Colors.white)),
              ),
            ),
            if (p.badge.isNotEmpty)
              Positioned(
                top: -11,
                right: 14,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 3),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(99),
                    gradient: const LinearGradient(colors: [_gold1, Color(0xFFFFB84D)]),
                    boxShadow: [BoxShadow(color: op(const Color(0xFFFFAA32), 0.5), blurRadius: 12, offset: const Offset(0, 5), spreadRadius: -5)],
                  ),
                  child: Text(p.badge, style: ku(11, w: FontWeight.w800, c: _brown, h: 1.5)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _radio(bool on) => AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 22,
        height: 22,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: on ? const Color(0xFFFFC95E) : const Color(0x598CEBF5), width: 2),
        ),
        child: on ? const DecoratedBox(decoration: BoxDecoration(shape: BoxShape.circle, color: Color(0xFFFFC95E))) : null,
      );

  Widget _trust() {
    Widget t(String ic, String hex, String s) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            svgIcon(ic, hex, size: 15),
            const SizedBox(width: 5),
            Text(s, style: ku(11.5, c: const Color(0xFF9CC4CB), h: 1.4)),
          ],
        );
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 14,
      runSpacing: 6,
      children: [
        t(_P.shield, '#3cf08a', 'هەر کاتێک هەڵیبوەشێنەوە'),
        t(_P.bolt, '#ffd36b', 'یەکسەر چالاک دەبێت'),
        t(_P.lock, '#8ff3f9', 'پارەدانی پارێزراو'),
      ],
    );
  }

  Widget _groupView(_Group g) {
    final gc = _hex(g.hex);
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(children: [
            Container(width: 18, height: 3, decoration: BoxDecoration(color: gc, borderRadius: BorderRadius.circular(3))),
            const SizedBox(width: 8),
            Text(g.title, style: ku(13, w: FontWeight.w800, c: gc, h: 1.5)),
          ]),
          const SizedBox(height: 8),
          for (final f in g.items) _featTile(f),
        ],
      ),
    );
  }

  Widget _featTile(_Feat f) {
    final c = _hex(f.hex);
    return Container(
      margin: const EdgeInsets.only(bottom: 7),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(colors: [op(c, 0.11), const Color(0x05FFFFFF)]),
        border: Border.all(color: op(c, 0.24)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: op(c, 0.15), borderRadius: BorderRadius.circular(12), border: Border.all(color: op(c, 0.32))),
            child: svgIcon(f.icon, f.hex, size: 19),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(f.title, style: ku(13.5, w: FontWeight.w800, h: 1.5)),
                Text(f.desc, style: ku(11.5, c: const Color(0xFF8FB7BE), h: 1.6)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _compare() {
    Widget row(String a, String b, String c, {bool head = false}) => Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: head ? 7 : 9),
          decoration: BoxDecoration(
            color: head ? const Color(0x08FFFFFF) : null,
            border: head ? null : const Border(top: BorderSide(color: Color(0x128CEBF5))),
          ),
          child: Row(
            children: [
              Expanded(child: Text(a, style: ku(12.5, h: 1.4))),
              SizedBox(width: 74, child: Text(b, textAlign: TextAlign.center, style: ku(11.5, w: FontWeight.w700, c: head ? const Color(0xFF9CC4CB) : const Color(0xFF7FA6AD), h: 1.4))),
              SizedBox(width: 74, child: Text(c, textAlign: TextAlign.center, style: ku(11.5, w: FontWeight.w700, c: head ? const Color(0xFFFFD36B) : _gold1, h: 1.4))),
            ],
          ),
        );
    return Container(
      margin: const EdgeInsets.only(top: 12),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: const Color(0x09FFFFFF),
        border: Border.all(color: const Color(0x1F8CEBF5)),
      ),
      child: Column(children: [
        row('', 'خۆڕایی', 'Plus', head: true),
        row('📸 سکانی خواردن بە AI', '3 لە ڕۆژێکدا', 'بێسنوور'),
        row('✨ VEX AI', '3 پرسیار', 'بێسنوور'),
        row('🗓️ پلانی ژەم و ڕاهێنان', '—', '✓'),
        row('🧬 VitalAge، ECG، ڕۆژەکەت', '—', '✓'),
        row('📈 مێژوو و ڕاپۆرتی AI', '—', '✓'),
        row('👶 پرۆفایلی منداڵ و خێزان', '—', '✓'),
      ]),
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
                Text('VEX Band ت کڕیوە؟', style: ku(13.5, w: FontWeight.w800, c: _gold1, h: 1.4)),
                Text(used ? 'دیارییەکە پێشتر وەرگیراوە' : '6 مانگ Plus بە خۆڕایی وەربگرە',
                    style: ku(11.5, c: const Color(0xFFD9BF85), h: 1.4)),
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
                child: Text('پەیوەستکردن', style: ku(12, w: FontWeight.w700, c: _gold1, h: 1.3)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _pays() {
    const ms = ['FIB', 'FastPay', 'ZainCash', 'Qi Card'];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text('پارەدان بە:', style: ku(12, c: const Color(0xFF9CC4CB))),
        for (final m in ms)
          Press(
            onTap: () => setState(() => _method = m),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(99),
                color: m == _method ? op(V.cy, 0.12) : const Color(0x08FFFFFF),
                border: Border.all(color: m == _method ? V.cy : const Color(0x2E8CEBF5)),
              ),
              child: Text(m, textDirection: TextDirection.ltr, style: nu(12.5, w: FontWeight.w700, c: m == _method ? V.cy : V.tx)),
            ),
          ),
      ],
    );
  }

  Widget _footer(MediaQueryData mq) {
    final p = _plan;
    final trial = _trial;
    final label = trial ? '7 ڕۆژ بە خۆڕایی دەستپێبکە' : 'بەشداربوون · ${fmt(p.price)} د.ع';
    final fine = trial
        ? '7 ڕۆژ بە خۆڕایی، پاشان ${fmt(p.price)} د.ع بۆ ${p.name}. هەر کاتێک هەڵیبوەشێنەوە.'
        : '${fmt(p.price)} د.ع بۆ ${p.name} · داشکانی 50٪. هەر کاتێک هەڵیبوەشێنەوە.';
    return Container(
      padding: EdgeInsets.fromLTRB(14, 10, 14, mq.padding.bottom + 8),
      decoration: const BoxDecoration(
        color: _bg,
        border: Border(top: BorderSide(color: Color(0x24FFD678))),
        boxShadow: [BoxShadow(color: _bg, blurRadius: 18, offset: Offset(0, -10))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(p.name, style: ku(12.5, c: const Color(0xFF9CC4CB))),
              const SizedBox(width: 6),
              Text(fmt(p.price), textDirection: TextDirection.ltr, style: nu(20, c: _gold1)),
              const SizedBox(width: 4),
              Text('د.ع', style: ku(12, c: const Color(0xFF9CC4CB))),
              const SizedBox(width: 6),
              Text(fmt(p.oldPrice),
                  textDirection: TextDirection.ltr,
                  style: nu(12, w: FontWeight.w600, c: const Color(0xFFFF8A8A))
                      .copyWith(decoration: TextDecoration.lineThrough, decorationColor: const Color(0xFFFF5F5F))),
            ],
          ),
          const SizedBox(height: 6),
          Press(
            onTap: _pay,
            child: AnimatedBuilder(
              animation: _c,
              builder: (_, child) {
                final t = (_c.value * 2) % 1.0; // درەوشانەوە
                return Container(
                  height: 54,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: const Alignment(1, 1),
                      colors: const [_gold1, _gold2, _gold3],
                      stops: const [0, 0.55, 1],
                    ),
                    boxShadow: [BoxShadow(color: op(const Color(0xFFFFAA32), 0.55), blurRadius: 28, offset: const Offset(0, 12), spreadRadius: -12)],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Positioned.fill(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: FractionallySizedBox(
                            alignment: Alignment(-1.6 + t * 3.2, 0),
                            widthFactor: 0.3,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(colors: [op(Colors.white, 0), op(Colors.white, 0.45), op(Colors.white, 0)]),
                              ),
                            ),
                          ),
                        ),
                      ),
                      child!,
                    ],
                  ),
                );
              },
              child: Text(label, style: ku(15.5, w: FontWeight.w800, c: _brown, h: 1.3)),
            ),
          ),
          const SizedBox(height: 6),
          Text(fine, textAlign: TextAlign.center, style: ku(11, c: const Color(0xFF86AEB5), h: 1.6)),
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
          Text(_trial ? 'چالاکدەکرێت…' : 'پارەدان لە $_method …', style: ku(16, w: FontWeight.w800, h: 1.5)),
          Text('تکایە چاوەڕێ بکە، پەڕەکە دامەخە', style: ku(12.5, c: const Color(0xFF9CC4CB), h: 1.6)),
        ],
      ),
    );
  }

  Widget _success() {
    return Center(
      key: const ValueKey('ok'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 84,
              height: 84,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFFFFE9A8), _gold2, _gold3]),
                boxShadow: [BoxShadow(color: op(const Color(0xFFFFB43C), 0.7), blurRadius: 40, offset: const Offset(0, 16), spreadRadius: -10)],
              ),
              child: svgIcon(_P.check, '#3b2500', size: 40, stroke: 2.6),
            ),
            const SizedBox(height: 18),
            Text(_done, textAlign: TextAlign.center, style: ku(22, w: FontWeight.w800, h: 1.5)),
            const SizedBox(height: 4),
            Text(_doneDesc, textAlign: TextAlign.center, style: ku(13, c: const Color(0xFF9CC4CB), h: 1.8)),
            const SizedBox(height: 22),
            Press(
              onTap: () => Navigator.of(context).maybePop(),
              child: Container(
                height: 54,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: const LinearGradient(colors: [_gold1, _gold2, _gold3]),
                ),
                child: Text('دەستپێبکە', style: ku(15.5, w: FontWeight.w800, c: _brown, h: 1.3)),
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
              decoration: BoxDecoration(shape: BoxShape.circle, color: op(V.coral, 0.15), border: Border.all(color: op(V.coral, 0.5))),
              child: const Icon(Icons.close_rounded, color: V.coral, size: 36),
            ),
            const SizedBox(height: 16),
            Text('پارەدانەکە سەرنەکەوت', style: ku(20, w: FontWeight.w800, h: 1.5)),
            Text('هیچ پارەیەک نەبڕدرا. دووبارە هەوڵ بدەوە یان ڕێگایەکی تر هەڵبژێرە.',
                textAlign: TextAlign.center, style: ku(13, c: const Color(0xFF9CC4CB), h: 1.8)),
            const SizedBox(height: 20),
            Press(
              onTap: _pay,
              child: Container(
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(18), gradient: const LinearGradient(colors: [_gold1, _gold2, _gold3])),
                child: Text('دووبارە هەوڵ بدەوە', style: ku(15, w: FontWeight.w800, c: _brown, h: 1.3)),
              ),
            ),
            const SizedBox(height: 10),
            Press(
              onTap: () => setState(() => _view = _View.main),
              child: Container(
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0x338CEBF5))),
                child: Text('گۆڕینی پلان یان ڕێگای پارەدان', style: ku(13.5, w: FontWeight.w700, h: 1.3)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================ نیشانەی زێڕین ============================
class _GemPainter extends CustomPainter {
  _GemPainter(this.t);
  final double t; // 0..1 (6 چرکە)

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    const r = 40.0;
    final bob = math.sin(t * 2 * math.pi) * 3;

    // درەوشانەوەی پشتەوە
    canvas.drawCircle(
      c,
      78,
      Paint()..shader = RadialGradient(colors: [op(_gold2, 0.34), op(_gold2, 0)]).createShader(Rect.fromCircle(center: c, radius: 78)),
    );

    // بازنە گەڕاوەکان
    void ring(double radius, double w, double rot, double alpha) {
      canvas.save();
      canvas.translate(c.dx, c.dy);
      canvas.rotate(rot);
      final rect = Rect.fromCircle(center: Offset.zero, radius: radius);
      canvas.drawArc(
        rect,
        0,
        2 * math.pi,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = w
          ..shader = SweepGradient(
            colors: [op(_gold1, 0), op(_gold1, alpha), op(_gold1, 0), op(V.cy, 0), op(V.cy, alpha), op(V.cy, 0)],
            stops: const [0, 0.18, 0.4, 0.55, 0.75, 1],
          ).createShader(rect),
      );
      canvas.restore();
    }

    ring(56, 3, t * 2 * math.pi, 1);
    ring(66, 2, -t * 2 * math.pi * 0.55, 0.45);

    // نیشانەکە
    canvas.save();
    canvas.translate(c.dx, c.dy + bob);
    final hex = Path();
    for (int i = 0; i < 6; i++) {
      final a = rad(-90.0 + 60 * i);
      final p = Offset(math.cos(a) * r, math.sin(a) * r);
      i == 0 ? hex.moveTo(p.dx, p.dy) : hex.lineTo(p.dx, p.dy);
    }
    hex.close();
    final rect = Rect.fromCircle(center: Offset.zero, radius: r);
    canvas.drawShadow(hex, op(_gold3, 0.8), 14, false);
    canvas.drawPath(
      hex,
      Paint()..shader = const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFFFFF2C2), _gold2, _gold3], stops: [0, 0.45, 1]).createShader(rect),
    );
    // ڕووی سەرەوە (ڕووناکتر)
    final top = Path()..moveTo(0, -r);
    top.lineTo(math.cos(rad(-30)) * r, math.sin(rad(-30)) * r);
    top.lineTo(0, 0);
    top.lineTo(math.cos(rad(-150)) * r, math.sin(rad(-150)) * r);
    top.close();
    canvas.drawPath(top, Paint()..color = op(Colors.white, 0.3));
    // ڕووی خوارەوە (تاریکتر)
    final side = Path()..moveTo(0, 0);
    side.lineTo(math.cos(rad(30)) * r, math.sin(rad(30)) * r);
    side.lineTo(0, r);
    side.lineTo(math.cos(rad(150)) * r, math.sin(rad(150)) * r);
    side.close();
    canvas.drawPath(side, Paint()..color = op(const Color(0xFF7A3D00), 0.14));
    canvas.drawPath(
      hex,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..strokeJoin = StrokeJoin.round
        ..color = op(const Color(0xFFFFF6D4), 0.75),
    );
    // ئەستێرەی ناوەڕاست
    final s = Path()
      ..moveTo(0, -23)
      ..quadraticBezierTo(2, -3, 23, 0)
      ..quadraticBezierTo(2, 3, 0, 23)
      ..quadraticBezierTo(-2, 3, -23, 0)
      ..quadraticBezierTo(-2, -3, 0, -23)
      ..close();
    canvas.drawPath(s, Paint()..color = op(const Color(0xFF5B2F00), 0.92));
    canvas.restore();

    // دەنکە درەوشاوەکان
    const pts = [Offset(-92, -34), Offset(88, -22), Offset(-70, 28), Offset(74, 36), Offset(-104, 8)];
    for (int i = 0; i < pts.length; i++) {
      final k = math.sin((t * 2 + i * 0.37) * math.pi);
      final a = 0.15 + 0.85 * k * k;
      final col = i == 3 ? V.c2 : _gold1;
      canvas.drawCircle(c + pts[i], (i.isEven ? 3.0 : 2.0) * (0.6 + 0.6 * a), Paint()..color = op(col, a));
    }
  }

  @override
  bool shouldRepaint(covariant _GemPainter o) => o.t != t;
}
