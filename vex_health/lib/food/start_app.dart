// VEX Health — دەستپێکی ئەپ (start_app.dart)
//
// ڕێکخستن:  Splash ← بەخێربێیت (3 سلاید) ← ئیشتراک (paywall) ← بازنەکە دەکرێتەوە ← بەشی خواردن
//   • «منداڵ و کەسانی زیاتر» لابراوە؛ پلانەکە تەنها بۆ خۆتە.
//   • پێش کردنەوەی بازنە، ئیشتراک دەکرێت و سوودەکان پیشان دەدرێن.
//
// بەکارهێنان:
//   1) openStartApp();                       // لە هەر شوێنێک (ئەگەر پێشتر تەواو کرابێت ڕاستەوخۆ دەچێتە خواردن)
//   2) MaterialApp(home: const StartAppGate())
//
// پەیوەستکردنی کڕین (in-app purchase):
//   StartAppHooks.onSubscribe = (String plan) async { /* plan: 'year' | 'month' */ return true; };
//   StartAppHooks.onRestore   = () async => true;
//   نرخەکان:  StartAppHooks.monthlyPrice / yearlyPrice
//
// پێویستی: food_design.dart + assets/food_design/ + assets/brand/ + shared_preferences
import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/theme.dart';
import 'food_design.dart';

/// دەستپێکردن: ئەگەر پێشتر تەواو کرابێت دەچێتە بەشی خواردن
Future<void> openStartApp() async {
  final nav = navKey.currentState;
  if (nav == null) return;
  final done = await _StartStore.done();
  if (done) {
    await openFoodDesign();
    return;
  }
  await nav.push<void>(MaterialPageRoute<void>(builder: (_) => const StartApp()));
}

/// وەک home ی MaterialApp بەکاربهێنە
class StartAppGate extends StatelessWidget {
  const StartAppGate({super.key});
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _StartStore.done(),
      builder: (c, s) {
        if (!s.hasData) return Scaffold(backgroundColor: V.bg);
        return s.data == true ? const FoodDesignPage() : const StartApp();
      },
    );
  }
}

/// پەیوەستکردن بە کڕینی ناو ئەپ
class StartAppHooks {
  StartAppHooks._();
  static Future<bool> Function(String plan)? onSubscribe;
  static Future<bool> Function()? onRestore;
  static String monthlyPrice = '\$4.99';
  static String yearlyPrice = '\$29.99';
  static String yearlyNote = '\$2.50 / مانگ';
  static int trialDays = 7;
}

class _StartStore {
  static const String _k = 'vexstart_v1';
  static Future<bool> done() async {
    try {
      final sp = await SharedPreferences.getInstance();
      final raw = sp.getString(_k);
      if (raw == null || raw.isEmpty) return false;
      final j = jsonDecode(raw);
      return j is Map && j['done'] == true;
    } catch (_) {
      return false;
    }
  }

  static Future<void> finish({required bool sub, String plan = ''}) async {
    try {
      final sp = await SharedPreferences.getInstance();
      await sp.setString(_k, jsonEncode({'done': true, 'sub': sub, 'plan': plan}));
    } catch (_) {}
  }
}

// ═════════════════════════════ پارچە بچووکەکان ═════════════════════════════
class _Ic extends StatelessWidget {
  const _Ic(this.name, {this.size = 28});
  final String name;
  final double size;
  @override
  Widget build(BuildContext context) => Image.asset(
        'assets/food_design/$name.webp',
        width: size,
        height: size,
        fit: BoxFit.contain,
        errorBuilder: (c, e, s) => SizedBox(width: size, height: size),
      );
}

Widget _t(String s, {double size = 14, FontWeight w = FontWeight.w700, Color? c, TextAlign? align, double? h}) =>
    VText(s, textAlign: align, style: ku(size, w: w, c: c, h: h));

Widget _n(String s, double size, {Color? c, FontWeight w = FontWeight.w800}) =>
    Text(s, textDirection: TextDirection.ltr, style: nu(size, w: w, c: c));

const List<String> _kOrbit = ['bread', 'fruit', 'protein', 'dairy', 'veg', 'water'];

class _Slide {
  const _Slide(this.icon, this.title, this.sub, this.color);
  final String icon, title, sub;
  final Color color;
}

const List<_Slide> _kSlides = [
  _Slide('scan', 'خواردن بە کامێرا بناسەوە', 'وێنەی خواردنەکە بگرە، کالۆری و ماکرۆکانی دەزانیت و پێت دەڵێت بۆ تۆ باشە یان نا.', Color(0xFF2FE6F3)),
  _Slide('coach', 'ڕاهێنەری تایبەتی تۆ', 'پلانی کالۆری، پرۆتین و ئاو بەپێی تەمەن، کێش، ئامانج و تەندروستیت دروست دەکرێت.', Color(0xFF3CF08A)),
  _Slide('analytics', 'شیکاری و بەردەوامی', 'ڕۆژانە و هەفتانە پێشکەوتنت ببینە: کالۆری، کێش، ئاو و ڕۆژانی بەردەوام.', Color(0xFFFFA52E)),
];

class _Benefit {
  const _Benefit(this.icon, this.text);
  final String icon, text;
}

const List<_Benefit> _kBenefits = [
  _Benefit('coach', 'پلانی کالۆری و ماکرۆی تایبەت بە خۆت'),
  _Benefit('scan', 'ناسینەوەی خواردن بە کامێرا و گەلەری'),
  _Benefit('aitext', 'ڕاهێنەری AI؛ وەڵامی هەر پرسیارێک'),
  _Benefit('regional', 'خواردنی کوردی و ناوچەیی لەناو لیستەکەدا'),
  _Benefit('analytics', 'شیکاری ٧ ڕۆژ، ماکرۆ و کێش'),
  _Benefit('minerals', 'ڤیتامین و کانزا و ئاگاداری هەستیاری'),
  _Benefit('water', 'بیرخستنەوەی ئاو و ئامانجی ڕۆژانە'),
];

// ═════════════════════════════ پەڕەی سەرەکی ═════════════════════════════
class StartApp extends StatefulWidget {
  const StartApp({super.key});
  @override
  State<StartApp> createState() => _StartAppState();
}

class _StartAppState extends State<StartApp> with TickerProviderStateMixin {
  int stage = 0; // 0 splash · 1 welcome · 2 paywall · 3 ring
  int slide = 0;
  String plan = 'year';
  bool busy = false;
  bool subbed = false;
  final PageController pc = PageController();
  late final AnimationController loop = AnimationController(vsync: this, duration: const Duration(seconds: 9))..repeat();
  late final AnimationController ringC = AnimationController(vsync: this, duration: const Duration(milliseconds: 2800));
  Timer? timer;

  @override
  void initState() {
    super.initState();
    timer = Timer(const Duration(milliseconds: 2600), () {
      if (mounted && stage == 0) go(1);
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    pc.dispose();
    loop.dispose();
    ringC.dispose();
    super.dispose();
  }

  void go(int s) {
    HapticFeedback.selectionClick();
    setState(() => stage = s);
    if (s == 3) {
      ringC.forward(from: 0);
      timer?.cancel();
      timer = Timer(const Duration(milliseconds: 3600), _enter);
    }
  }

  Future<void> _subscribe() async {
    if (busy) return;
    setState(() => busy = true);
    bool ok = true;
    final h = StartAppHooks.onSubscribe;
    if (h != null) {
      try {
        ok = await h(plan);
      } catch (_) {
        ok = false;
      }
    } else {
      toast('ئیشتراک چالاک کرا ✓');
    }
    if (!mounted) return;
    setState(() => busy = false);
    if (ok) {
      subbed = true;
      go(3);
    } else {
      toast('ئیشتراک تەواو نەبوو، دووبارە هەوڵ بدەرەوە');
    }
  }

  Future<void> _restore() async {
    final h = StartAppHooks.onRestore;
    if (h == null) {
      toast('هیچ کڕینێک نەدۆزرایەوە');
      return;
    }
    bool ok = false;
    try {
      ok = await h();
    } catch (_) {}
    if (!mounted) return;
    if (ok) {
      subbed = true;
      toast('کڕینەکەت گەڕایەوە ✓');
      go(3);
    } else {
      toast('هیچ کڕینێک نەدۆزرایەوە');
    }
  }

  Future<void> _enter() async {
    if (!mounted) return;
    await _StartStore.finish(sub: subbed, plan: subbed ? plan : '');
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        pageBuilder: (c, a, b) => const FoodDesignPage(),
        transitionsBuilder: (c, a, b, child) => FadeTransition(opacity: a, child: child),
        transitionDuration: const Duration(milliseconds: 700),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget body;
    switch (stage) {
      case 0:
        body = _splash();
        break;
      case 1:
        body = _welcome();
        break;
      case 2:
        body = _paywall();
        break;
      default:
        body = _ring();
    }
    return Directionality(
      textDirection: kDir,
      child: Scaffold(
        backgroundColor: V.bg,
        body: Stack(children: [
          const Positioned.fill(child: Aurora()),
          SafeArea(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 520),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeIn,
              transitionBuilder: (child, a) => FadeTransition(
                opacity: a,
                child: ScaleTransition(scale: Tween<double>(begin: 0.97, end: 1).animate(a), child: child),
              ),
              child: KeyedSubtree(key: ValueKey<int>(stage), child: body),
            ),
          ),
        ]),
      ),
    );
  }

  // ───────────── 0 · Splash ─────────────
  Widget _orbit(double r, double iconSize, {double glow = 1}) {
    return AnimatedBuilder(
      animation: loop,
      builder: (c, _) {
        final t = loop.value;
        final pulse = 1 + 0.06 * math.sin(t * 2 * math.pi * 3);
        return SizedBox(
          width: r * 2 + iconSize,
          height: r * 2 + iconSize,
          child: Stack(alignment: Alignment.center, children: [
            Transform.scale(
              scale: pulse,
              child: Container(
                width: r * 1.5,
                height: r * 1.5,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [op(V.cy, 0.34 * glow), op(V.cy, 0)]),
                ),
              ),
            ),
            Container(
              width: r * 2,
              height: r * 2,
              decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: op(V.cy, 0.14))),
            ),
            for (int i = 0; i < _kOrbit.length; i++)
              Transform.translate(
                offset: Offset(
                  math.cos(t * 2 * math.pi + i * math.pi / 3) * r,
                  math.sin(t * 2 * math.pi + i * math.pi / 3) * r,
                ),
                child: Container(
                  width: iconSize,
                  height: iconSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: V.surf,
                    border: Border.all(color: V.line),
                    boxShadow: [BoxShadow(color: op(V.cy, 0.22), blurRadius: 14)],
                  ),
                  child: Center(child: _Ic(_kOrbit[i], size: iconSize * 0.66)),
                ),
              ),
          ]),
        );
      },
    );
  }

  Widget _logo(double size) => TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0.4, end: 1),
        duration: const Duration(milliseconds: 1100),
        curve: Curves.elasticOut,
        builder: (c, v, _) => Transform.scale(
          scale: v,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: V.surf,
              border: Border.all(color: op(V.cy, 0.5), width: 1.6),
              boxShadow: [BoxShadow(color: op(V.cy, 0.4), blurRadius: 30)],
            ),
            padding: EdgeInsets.all(size * 0.2),
            child: Image.asset(
              'assets/brand/vx_logo.webp',
              fit: BoxFit.contain,
              errorBuilder: (c, e, s) => Center(child: Text('VEX', style: nu(size * 0.28, c: V.cy))),
            ),
          ),
        ),
      );

  Widget _splash() {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Stack(alignment: Alignment.center, children: [_orbit(122, 50), _logo(104)]),
        const SizedBox(height: 26),
        TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: 1),
          duration: const Duration(milliseconds: 900),
          curve: Curves.easeOut,
          builder: (c, v, child) => Opacity(opacity: v, child: Transform.translate(offset: Offset(0, 14 * (1 - v)), child: child)),
          child: Column(children: [
            ShaderMask(
              shaderCallback: (r) => V.prime.createShader(r),
              child: Text('VEX Food', style: nu(36, c: Colors.white)),
            ),
            const SizedBox(height: 6),
            _t('ڕاهێنەری خواردنی تایبەتی تۆ', size: 14, c: V.mu),
          ]),
        ),
        const SizedBox(height: 34),
        AnimatedBuilder(
          animation: loop,
          builder: (c, _) => Row(mainAxisSize: MainAxisSize.min, children: [
            for (int i = 0; i < 3; i++)
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: op(V.cy, 0.25 + 0.75 * (0.5 + 0.5 * math.sin(loop.value * 2 * math.pi * 4 - i * 1.1)).clamp(0.0, 1.0)),
                ),
              ),
          ]),
        ),
      ]),
    );
  }

  // ───────────── 1 · بەخێربێیت ─────────────
  Widget _welcome() {
    final last = slide == _kSlides.length - 1;
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 0),
        child: Row(children: [
          SizedBox(width: 36, height: 36, child: Image.asset('assets/brand/vx_logo.webp', errorBuilder: (c, e, s) => const SizedBox())),
          const SizedBox(width: 8),
          Text('VEX Food', style: nu(16, c: V.tx)),
          const Spacer(),
          Press(onTap: () => go(2), child: Padding(padding: const EdgeInsets.all(8), child: _t('تێپەڕە', size: 13, c: V.mu))),
        ]),
      ),
      Expanded(
        child: PageView.builder(
          controller: pc,
          itemCount: _kSlides.length,
          onPageChanged: (i) => setState(() => slide = i),
          itemBuilder: (c, i) {
            final s = _kSlides[i];
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 26),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                if (i == 0) ...[
                  _t('بەخێربێیت بۆ VEX Food', size: 25, w: FontWeight.w800, align: TextAlign.center),
                  const SizedBox(height: 6),
                  _t('پلانی خواردنەکە تایبەتە بە خۆت و دەستت پێ دەکات', size: 13, c: V.mu, align: TextAlign.center),
                  const SizedBox(height: 22),
                ],
                AnimatedBuilder(
                  animation: loop,
                  builder: (c, _) {
                    final dy = 8 * math.sin(loop.value * 2 * math.pi * 3 + i);
                    return Transform.translate(
                      offset: Offset(0, dy),
                      child: Container(
                        width: 190,
                        height: 190,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(colors: [op(s.color, 0.28), op(s.color, 0.04)]),
                          border: Border.all(color: op(s.color, 0.45)),
                          boxShadow: [BoxShadow(color: op(s.color, 0.28), blurRadius: 40)],
                        ),
                        child: Center(child: _Ic(s.icon, size: 110)),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 28),
                _t(s.title, size: 21, w: FontWeight.w800, align: TextAlign.center),
                const SizedBox(height: 10),
                _t(s.sub, size: 13.5, c: V.mu, h: 1.8, align: TextAlign.center, w: FontWeight.w600),
              ]),
            );
          },
        ),
      ),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        for (int i = 0; i < _kSlides.length; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: slide == i ? 26 : 8,
            height: 8,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            decoration: BoxDecoration(color: slide == i ? V.cy : V.track, borderRadius: BorderRadius.circular(6)),
          ),
      ]),
      Padding(
        padding: const EdgeInsets.fromLTRB(22, 20, 22, 22),
        child: _cta(last ? 'دەست پێ بکە' : 'دواتر', () {
          if (last) {
            go(2);
          } else {
            pc.nextPage(duration: const Duration(milliseconds: 380), curve: Curves.easeOutCubic);
          }
        }),
      ),
    ]);
  }

  Widget _cta(String label, VoidCallback f, {bool loading = false}) {
    return Press(
      onTap: loading ? null : f,
      child: LayoutBuilder(
        builder: (c, box) => ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Container(
            height: 56,
            decoration: BoxDecoration(
              gradient: V.prime,
              boxShadow: [BoxShadow(color: op(V.mint, 0.35), blurRadius: 22, offset: const Offset(0, 8))],
            ),
            child: Stack(alignment: Alignment.center, children: [
              AnimatedBuilder(
                animation: loop,
                builder: (c, _) {
                  final x = ((loop.value * 3) % 1.0) * (box.maxWidth + 120) - 90;
                  return Positioned(
                    left: x,
                    top: 0,
                    bottom: 0,
                    child: Transform(
                      transform: Matrix4.skewX(-0.35),
                      child: Container(width: 46, color: const Color(0x38FFFFFF)),
                    ),
                  );
                },
              ),
              loading
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 3, color: Color(0xFF05303A)))
                  : _t(label, size: 16, w: FontWeight.w800, c: const Color(0xFF05303A)),
            ]),
          ),
        ),
      ),
    );
  }

  // ───────────── 2 · ئیشتراک ─────────────
  Widget _planCard(String key, String title, String price, String sub, {String? badge}) {
    final on = plan == key;
    return Expanded(
      child: Press(
        onTap: () => setState(() => plan = key),
        child: Stack(clipBehavior: Clip.none, children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.fromLTRB(10, 18, 10, 14),
            decoration: BoxDecoration(
              color: on ? op(V.mint, 0.12) : V.surf,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: on ? V.mint : V.line, width: on ? 1.8 : 1),
              boxShadow: on ? [BoxShadow(color: op(V.mint, 0.25), blurRadius: 20)] : null,
            ),
            child: Column(children: [
              _t(title, size: 13.5, w: FontWeight.w800, c: on ? V.mint : V.tx),
              const SizedBox(height: 6),
              _n(price, 22, c: V.tx),
              const SizedBox(height: 3),
              _t(sub, size: 11, c: V.mu, align: TextAlign.center),
            ]),
          ),
          if (badge != null)
            PositionedDirectional(
              top: -10,
              start: 0,
              end: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(gradient: V.prime, borderRadius: BorderRadius.circular(12)),
                  child: _t(badge, size: 10.5, w: FontWeight.w800, c: const Color(0xFF05303A)),
                ),
              ),
            ),
        ]),
      ),
    );
  }

  Widget _benefit(int i) {
    final b = _kBenefits[i];
    return TweenAnimationBuilder<double>(
      key: ValueKey<String>('b$i'),
      tween: Tween<double>(begin: 0, end: 1),
      duration: Duration(milliseconds: 420 + i * 90),
      curve: Curves.easeOutCubic,
      builder: (c, v, child) => Opacity(opacity: v, child: Transform.translate(offset: Offset(0, 18 * (1 - v)), child: child)),
      child: Container(
        margin: const EdgeInsets.only(bottom: 9),
        padding: const EdgeInsets.fromLTRB(10, 9, 12, 9),
        decoration: BoxDecoration(color: V.surf, borderRadius: BorderRadius.circular(18), border: Border.all(color: V.line)),
        child: Row(children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(color: op(V.cy, 0.1), borderRadius: BorderRadius.circular(14)),
            child: Center(child: _Ic(b.icon, size: 30)),
          ),
          const SizedBox(width: 11),
          Expanded(child: _t(b.text, size: 13, w: FontWeight.w700, h: 1.5)),
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(shape: BoxShape.circle, gradient: V.prime),
            child: const Icon(Icons.check_rounded, size: 17, color: Color(0xFF05303A)),
          ),
        ]),
      ),
    );
  }

  Widget _paywall() {
    return Column(children: [
      Expanded(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 8),
          physics: const BouncingScrollPhysics(),
          children: [
            Center(child: Stack(alignment: Alignment.center, children: [_orbit(70, 34, glow: 0.8), _logo(66)])),
            const SizedBox(height: 4),
            _t('ئیشتراک بکە و ئەمانە بەدەست بهێنە', size: 22, w: FontWeight.w800, align: TextAlign.center, h: 1.5),
            const SizedBox(height: 6),
            _t('${StartAppHooks.trialDays} ڕۆژ بەخۆڕایی تاقی بکەرەوە، هەر کاتێک بتەوێت هەڵیبوەشێنەرەوە', size: 12.5, c: V.mu, align: TextAlign.center, h: 1.6),
            const SizedBox(height: 18),
            for (int i = 0; i < _kBenefits.length; i++) _benefit(i),
            const SizedBox(height: 14),
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _planCard('year', 'ساڵانە', StartAppHooks.yearlyPrice, StartAppHooks.yearlyNote, badge: 'باشترین'),
              const SizedBox(width: 12),
              _planCard('month', 'مانگانە', StartAppHooks.monthlyPrice, 'هەر مانگ'),
            ]),
            const SizedBox(height: 10),
          ],
        ),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 6, 20, 10),
        child: Column(children: [
          _cta('ئیشتراک بکە', _subscribe, loading: busy),
          const SizedBox(height: 6),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Press(onTap: _restore, child: Padding(padding: const EdgeInsets.all(8), child: _t('گەڕاندنەوەی کڕین', size: 12, c: V.mu))),
            Container(width: 1, height: 12, color: V.line2),
            Press(onTap: () => go(3), child: Padding(padding: const EdgeInsets.all(8), child: _t('ئێستا نا', size: 12, c: V.mu))),
          ]),
          _t('ئیشتراکەکە خۆکار نوێ دەبێتەوە و دەتوانیت لە ڕێکخستنەکانی ستۆر هەڵیبوەشێنیتەوە.', size: 10.5, c: op(V.mu, 0.8), align: TextAlign.center, w: FontWeight.w500, h: 1.5),
        ]),
      ),
    ]);
  }

  // ───────────── 3 · بازنەکە دەکرێتەوە ─────────────
  Widget _ring() {
    return AnimatedBuilder(
      animation: ringC,
      builder: (c, _) {
        final t = Curves.easeInOutCubic.transform(ringC.value);
        final txt = t < 0.45 ? 'بازنەکەت دەکرێتەوە...' : (t < 0.9 ? 'پلانەکەت ئامادە دەکرێت...' : 'ڕاهێنەرەکەت ئامادەیە!');
        return Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            SizedBox(
              width: 260,
              height: 260,
              child: Stack(alignment: Alignment.center, children: [
                CustomPaint(size: const Size(260, 260), painter: _RingOpenP(t, V.track)),
                Opacity(
                  opacity: t.clamp(0.0, 1.0),
                  child: Transform.scale(
                    scale: 0.6 + 0.4 * t,
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      const _Ic('kcal', size: 84),
                      const SizedBox(height: 4),
                      Text('VEX', style: nu(18, c: V.cy)),
                    ]),
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 28),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: KeyedSubtree(key: ValueKey<String>(txt), child: _t(txt, size: 17, w: FontWeight.w800, align: TextAlign.center)),
            ),
            const SizedBox(height: 10),
            if (subbed) _t('ئیشتراکەکەت چالاکە ✓', size: 12.5, c: V.mint),
          ]),
        );
      },
    );
  }
}

/// بازنەی کراوە: سێ کەوان (پرۆتین، کارب، چەوری) یەک بە یەک دەکرێنەوە
class _RingOpenP extends CustomPainter {
  _RingOpenP(this.t, this.track);
  final double t;
  final Color track;
  static const List<Color> _cols = [Color(0xFFFF5F7E), Color(0xFFFFA52E), Color(0xFF9B7BFF)];

  @override
  void paint(Canvas c, Size s) {
    final center = Offset(s.width / 2, s.height / 2);
    final r = math.min(s.width, s.height) / 2 - 22;
    final rect = Rect.fromCircle(center: center, radius: r);
    const w = 18.0;
    c.drawCircle(center, r, Paint()..style = PaintingStyle.stroke..strokeWidth = w..color = track);
    const seg = 2 * math.pi / 3;
    const gap = 0.22;
    final start0 = -math.pi / 2 + (1 - t) * math.pi;
    for (int i = 0; i < 3; i++) {
      final k = ((t * 1.5 - i * 0.2) / 0.6).clamp(0.0, 1.0);
      if (k <= 0) continue;
      final a0 = start0 + i * seg;
      final sw = (seg - gap) * k;
      c.drawArc(
        rect,
        a0,
        sw,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = w + 12
          ..strokeCap = StrokeCap.round
          ..color = _cols[i].withAlpha(70)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9),
      );
      c.drawArc(
        rect,
        a0,
        sw,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = w
          ..strokeCap = StrokeCap.round
          ..color = _cols[i],
      );
    }
    // خاڵی گەشاوە لە سەری کەوان
    final head = start0 + (t * 2 * math.pi);
    c.drawCircle(
      Offset(center.dx + r * math.cos(head), center.dy + r * math.sin(head)),
      5 * (1 - t) + 2,
      Paint()..color = const Color(0xFFEAFFFF).withAlpha((255 * (1 - t)).round()),
    );
  }

  @override
  bool shouldRepaint(covariant _RingOpenP o) => o.t != t || o.track != track;
}
