// VEX Health — شوێنی سپۆنسەر (UK Pizza و نموونەکان) — بەکارهێنەر ناتوانێت لای ببات
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/store.dart';
import '../core/theme.dart';

class AdFood {
  const AdFood(this.n, this.s, this.k, this.p, this.c, this.f, this.img);
  final String n;
  final String s;
  final int k;
  final int p;
  final int c;
  final int f;
  final String img;
}

class Ad {
  const Ad({
    required this.id,
    required this.brand,
    this.sub,
    this.logo,
    required this.b1,
    required this.b2,
    required this.b3,
    required this.title,
    required this.line,
    this.img,
    this.hero,
    this.emo,
    this.stk,
    this.kcal = 0,
    this.chip,
    required this.when,
    required this.offer,
    required this.code,
    required this.cta,
    this.items = const [],
    this.example = false,
  });

  final String id;
  final String brand;
  final String? sub;
  final String? logo;
  final Color b1;
  final Color b2;
  final Color b3;
  final String title;
  final String line;
  final String? img;
  final String? hero;
  final String? emo;
  final String? stk;
  final int kcal;
  final String? chip;
  final List<int> when;
  final List<String> offer;
  final String code;
  final String cta;
  final List<AdFood> items;
  final bool example;
}

const List<Ad> kAds = [
  Ad(
    id: 'ukp',
    brand: 'UK Pizza',
    sub: 'Pizza and more · هەولێر',
    logo: 'assets/ads/ukpizza_logo.webp',
    b1: Color(0xFFE3173E),
    b2: Color(0xFF23308F),
    b3: Color(0xFF2A1240),
    line: '20٪ داشکاندن بۆ ئەندامانی VEX',
    img: 'assets/ads/pizza_slice.webp',
    hero: 'assets/ads/pizza_board.webp',
    stk: '−20%',
    title: 'پیپەرۆنی و هالاپینیۆ',
    kcal: 600,
    when: [11, 15, 18, 23],
    offer: ['20٪ داشکاندن بۆ بەکارهێنەرانی VEX', 'کۆدەکە لە کاتی داواکردندا بڵێ'],
    code: 'VEX20',
    cta: 'داواکردن',
    items: [
      AdFood('پیتزای پیپەرۆنی و هالاپینیۆ', '2 پارچە', 600, 26, 62, 27, 'assets/ads/pizza_slice.webp'),
      AdFood('پیتزای پەنیر', '2 پارچە', 560, 24, 64, 22, 'assets/ads/pizza_cheese.webp'),
    ],
  ),
  Ad(
    id: 'ph',
    brand: 'VitaCare',
    example: true,
    emo: '💊',
    b1: Color(0xFF14B8D6),
    b2: Color(0xFF0F7A5F),
    b3: Color(0xFF062F3A),
    title: 'ڤیتامین و تەواوکەرەکان',
    line: 'گەیاندنی خۆڕایی بۆ ئەندامانی VEX',
    chip: '🚚 گەیاندن بۆ ماڵ لە 30 خولەکدا',
    when: [7, 12],
    offer: ['گەیاندنی خۆڕایی بۆ ئەندامانی VEX', 'بۆ هەر داواکارییەک'],
    code: 'VEXCARE',
    cta: 'بینینی بەرهەمەکان',
  ),
  Ad(
    id: 'gym',
    brand: 'Iron Club',
    example: true,
    emo: '🏋️',
    b1: Color(0xFFFF8A3D),
    b2: Color(0xFF5B2DBF),
    b3: Color(0xFF21123F),
    title: 'مانگی یەکەم بە نیو نرخ',
    line: 'بە پیشاندانی ئەپی VEX لە هۆڵ',
    chip: '🏋️ ئامێری نوێ · ڕاهێنەری تایبەت',
    when: [15, 21],
    offer: ['50٪ داشکاندن بۆ مانگی یەکەم', 'بە پیشاندانی ئەپی VEX'],
    code: 'VEXFIT',
    cta: 'تۆمارکردن',
  ),
];

/// ڕیکلامی گونجاو بۆ ئەم کاتەی ڕۆژ یەکەم دێت
List<Ad> orderedAds() {
  final h = DateTime.now().hour;
  bool on(Ad a) {
    final w = a.when;
    final first = w.length >= 2 && h >= w[0] && h < w[1];
    final second = w.length >= 4 && h >= w[2] && h < w[3];
    return first || second;
  }

  final idx = List<int>.generate(kAds.length, (i) => i);
  idx.sort((a, b) {
    final x = (on(kAds[a]) ? 0 : 1).compareTo(on(kAds[b]) ? 0 : 1);
    return x != 0 ? x : a.compareTo(b);
  });
  return [for (final i in idx) kAds[i]];
}

int walkMin(int kcal) => (kcal / 5.4).round();

Widget brandLogo(Ad a, double size, {double ring = 2, double ringOpacity = 0.22}) {
  final shadow = [BoxShadow(color: op(Colors.white, ringOpacity), spreadRadius: ring)];
  final logo = a.logo;
  if (logo != null) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: shadow,
        image: DecorationImage(image: AssetImage(logo), fit: BoxFit.cover),
      ),
    );
  }
  return Container(
    width: size,
    height: size,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      boxShadow: shadow,
      gradient: LinearGradient(colors: [a.b1, a.b2]),
    ),
    child: VText(a.brand.substring(0, 1), style: nu(size * 0.46, c: Colors.white)),
  );
}

// ============================================================
// کارتی ڕیکلام لە سەرەکی
// ============================================================
class SponsorCarousel extends StatefulWidget {
  const SponsorCarousel({super.key});

  @override
  State<SponsorCarousel> createState() => _SponsorCarouselState();
}

class _SponsorCarouselState extends State<SponsorCarousel> with TickerProviderStateMixin {
  late final List<Ad> ads = orderedAds();
  late final AnimationController prog =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 7000));
  late final AnimationController shine =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 7000))..repeat();
  late final AnimationController spin =
      AnimationController(vsync: this, duration: const Duration(seconds: 46))..repeat();
  late final AnimationController wob =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..repeat(reverse: true);
  late final AnimationController flt =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 2500))..repeat(reverse: true);

  int cur = 0;
  double _dx = 0;

  @override
  void initState() {
    super.initState();
    prog.addStatusListener(_onStatus);
    prog.forward();
  }

  @override
  void dispose() {
    prog.removeStatusListener(_onStatus);
    prog.dispose();
    shine.dispose();
    spin.dispose();
    wob.dispose();
    flt.dispose();
    super.dispose();
  }

  void _onStatus(AnimationStatus s) {
    if (s == AnimationStatus.completed) _show(cur + 1);
  }

  void _show(int i) {
    if (!mounted) return;
    final n = ads.length;
    setState(() => cur = ((i % n) + n) % n);
    prog.forward(from: 0);
  }

  void _resume() {
    if (mounted && !prog.isAnimating) prog.forward();
  }

  double _shineX(double v) {
    if (v < 0.55) return 1.3;
    if (v < 0.8) return 1.3 - 2.6 * Curves.easeInOut.transform((v - 0.55) / 0.25);
    return -1.3;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: SizedBox(
        height: 146,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (_) => prog.stop(),
          onTapCancel: _resume,
          onTap: () {
            _resume();
            openAdSheet(ads[cur]);
          },
          onHorizontalDragStart: (_) {
            prog.stop();
            _dx = 0;
          },
          onHorizontalDragUpdate: (d) => _dx += d.delta.dx,
          onHorizontalDragEnd: (_) {
            if (_dx.abs() > 40) {
              _show(cur + (_dx < 0 ? 1 : -1));
            } else {
              _resume();
            }
          },
          onHorizontalDragCancel: _resume,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              for (int i = 0; i < ads.length; i++)
                Positioned.fill(
                  child: IgnorePointer(
                    ignoring: i != cur,
                    child: AnimatedOpacity(
                      opacity: i == cur ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 600),
                      child: AnimatedScale(
                        scale: i == cur ? 1.0 : 0.97,
                        duration: const Duration(milliseconds: 700),
                        curve: const Cubic(0.2, 0.9, 0.25, 1.0),
                        child: _slide(ads[i]),
                      ),
                    ),
                  ),
                ),
              Positioned(
                top: 8,
                right: 16,
                left: 146,
                height: 2,
                child: AnimatedBuilder(
                  animation: prog,
                  builder: (context, _) => Row(
                    children: [
                      for (int i = 0; i < ads.length; i++) ...[
                        if (i > 0) const SizedBox(width: 4),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(2),
                            child: Container(
                              height: 2,
                              color: op(Colors.white, 0.2),
                              alignment: AlignmentDirectional.centerStart,
                              child: FractionallySizedBox(
                                widthFactor: i < cur ? 1.0 : (i == cur ? prog.value : 0.0),
                                heightFactor: 1,
                                child: const ColoredBox(color: Colors.white),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _slide(Ad a) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: op(a.b1, 0.55), blurRadius: 44, offset: const Offset(0, 22), spreadRadius: -26)],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: const Alignment(-1, -0.27),
                    end: const Alignment(1, 0.27),
                    colors: [a.b3, a.b3, const Color(0xFF071C27)],
                    stops: const [0.0, 0.2, 1.0],
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.topRight,
                    radius: 1.4,
                    colors: [op(a.b2, 0.7), op(a.b2, 0)],
                    stops: const [0.0, 0.7],
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.centerLeft,
                    radius: 2.0,
                    colors: [op(a.b1, 0.88), op(a.b1, 0)],
                    stops: const [0.0, 0.62],
                  ),
                ),
              ),
            ),
            const Positioned.fill(child: CustomPaint(painter: _StripePainter())),
            Positioned.fill(
              child: AnimatedBuilder(
                animation: shine,
                builder: (context, child) => FractionalTranslation(
                  translation: Offset(_shineX(shine.value), 0),
                  child: child,
                ),
                child: const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment(-1, -0.27),
                      end: Alignment(1, 0.27),
                      colors: [Color(0x00FFFFFF), Color(0x1FFFFFFF), Color(0x00FFFFFF)],
                      stops: [0.38, 0.5, 0.62],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(left: -46, top: -31, width: 190, height: 190, child: _visual(a)),
            Positioned(right: 16, left: 140, top: 16, child: _text(a)),
            Positioned(right: 10, left: 10, bottom: 10, height: 34, child: _strip(a)),
          ],
        ),
      ),
    );
  }

  Widget _visual(Ad a) {
    final img = a.img;
    final stk = a.stk;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        if (img != null) ...[
          Positioned(
            left: 30,
            top: 36,
            width: 150,
            height: 150,
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: op(Colors.black, 0.45), blurRadius: 22)],
              ),
            ),
          ),
          Positioned.fill(
            child: RotationTransition(turns: spin, child: Image.asset(img, fit: BoxFit.contain)),
          ),
        ] else
          Positioned(left: 20, top: 22, width: 150, height: 150, child: _orb(a)),
        if (stk != null)
          Positioned(
            right: 6,
            top: 30,
            child: AnimatedBuilder(
              animation: wob,
              builder: (context, child) {
                final v = Curves.easeInOut.transform(wob.value);
                return Transform.rotate(
                  angle: rad(-12 + 6 * v),
                  child: Transform.scale(scale: 1 + 0.07 * v, child: child),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD23F),
                  borderRadius: BorderRadius.circular(13),
                  boxShadow: const [BoxShadow(color: Color(0x99000000), blurRadius: 18, offset: Offset(0, 10), spreadRadius: -6)],
                ),
                child: VText(stk, textDirection: TextDirection.ltr, style: nu(14, c: const Color(0xFF3B1D00), h: 1.1)),
              ),
            ),
          ),
      ],
    );
  }

  Widget _orb(Ad a) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [mix(a.b1, Colors.white, 0.05), a.b1, op(a.b1, 0.5), op(a.b1, 0)],
                stops: const [0.0, 0.45, 0.72, 0.74],
              ),
              boxShadow: [BoxShadow(color: op(a.b1, 0.8), blurRadius: 60, spreadRadius: -10)],
            ),
          ),
        ),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                center: const Alignment(0.24, -0.24),
                radius: 0.42,
                colors: [op(Colors.white, 0.45), op(Colors.white, 0)],
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: Center(
            child: AnimatedBuilder(
              animation: flt,
              builder: (context, child) {
                final v = Curves.easeInOut.transform(flt.value);
                return Transform.translate(
                  offset: Offset(14, -4 - 6 * v),
                  child: Transform.rotate(angle: rad(-12 + 8 * v), child: child),
                );
              },
              child: VText(a.emo ?? '', style: const TextStyle(fontSize: 58)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _text(Ad a) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            brandLogo(a, 26),
            const SizedBox(width: 7),
            Flexible(
              child: VText(a.brand, maxLines: 1, overflow: TextOverflow.ellipsis, style: nu(13, c: Colors.white)),
            ),
            const SizedBox(width: 7),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(99),
                border: Border.all(color: op(Colors.white, 0.2)),
              ),
              child: VText(
                a.example ? 'نموونە' : 'سپۆنسەر',
                style: ku(9.5, w: FontWeight.w700, c: op(Colors.white, 0.62), h: 1.4),
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        VText(
          a.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: ku(16.5, w: FontWeight.w800, c: Colors.white, h: 1.4, shadows: const [
            Shadow(color: Color(0x59000000), blurRadius: 12, offset: Offset(0, 2)),
          ]),
        ),
        VText(
          a.line,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: ku(12, w: FontWeight.w700, c: const Color(0xFFFFD977)),
        ),
      ],
    );
  }

  Widget _strip(Ad a) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.only(right: 12, left: 4),
          decoration: BoxDecoration(
            color: const Color(0x6B04121A),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: op(Colors.white, 0.1)),
          ),
          child: Row(
            children: [
              Expanded(
                child: AnimatedBuilder(
                  animation: Store.I,
                  builder: (context, _) => VText.rich(
                    _stripSpan(a),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: ku(11.5, w: FontWeight.w700, c: op(Colors.white, 0.9)),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                width: 26,
                height: 26,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [BoxShadow(color: Color(0x80000000), blurRadius: 14, offset: Offset(0, 6), spreadRadius: -4)],
                ),
                child: VText('‹', style: nu(16, c: a.b1, h: 1.0)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  TextSpan _stripSpan(Ad a) {
    final chip = a.chip;
    if (chip != null) return TextSpan(text: chip);
    final ok = Store.I.left >= a.kcal;
    const dot = TextSpan(text: '  ·  ', style: TextStyle(color: Color(0x59FFFFFF)));
    return TextSpan(children: [
      const TextSpan(text: '🔥 '),
      TextSpan(text: '${a.kcal}', style: nu(12, c: Colors.white)),
      const TextSpan(text: ' kcal'),
      dot,
      const TextSpan(text: '🚶 '),
      TextSpan(text: '${walkMin(a.kcal)}', style: nu(12, c: Colors.white)),
      const TextSpan(text: ' خولەک'),
      dot,
      TextSpan(
        text: ok ? '✓ دەگونجێت' : 'نیوەی بخۆ',
        style: TextStyle(color: ok ? const Color(0xFF7DFFB6) : const Color(0xFFFFD27A)),
      ),
    ]);
  }
}

class _StripePainter extends CustomPainter {
  const _StripePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..strokeWidth = 1
      ..shader = ui.Gradient.linear(
        Offset.zero,
        Offset(size.width * 0.55, 0),
        [const Color(0x09FFFFFF), const Color(0x00FFFFFF)],
      );
    // هێڵی لار (115°)
    const step = 14.0;
    final dx = size.height * 0.4663; // tan(25°)
    for (double x = -size.height; x < size.width + size.height; x += step) {
      canvas.drawLine(Offset(x, size.height), Offset(x + dx, 0), p);
    }
  }

  @override
  bool shouldRepaint(covariant _StripePainter oldDelegate) => false;
}

// ============================================================
// شیتی وردەکاری ڕیکلام
// ============================================================
void openAdSheet(Ad a) {
  showVSheet<void>(plain: true, color: const Color(0xFF05222C), builder: (_) => AdSheet(ad: a));
}

class AdSheet extends StatefulWidget {
  const AdSheet({super.key, required this.ad});
  final Ad ad;

  @override
  State<AdSheet> createState() => _AdSheetState();
}

class _AdSheetState extends State<AdSheet> {
  final Set<int> _added = <int>{};

  void _add(int i) {
    final a = widget.ad;
    final it = a.items[i];
    Store.I.addFood(FoodItem(
      n: '${a.brand} · ${it.n}',
      kcal: it.k,
      p: it.p,
      c: it.c,
      f: it.f,
      at: nowHM(),
      v: 'ok',
      e: '🍕',
    ));
    setState(() => _added.add(i));
    toast('✓ ${it.n} زیادکرا بۆ ژەمەکانت');
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.ad;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        _hero(context, a),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              _offer(a),
              if (a.items.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(2, 18, 2, 8),
                  child: Row(
                    children: [
                      VText('🍽️ خواردنەکان', style: ku(13, w: FontWeight.w800, c: const Color(0xFF9CC4CB))),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: op(V.cy, 0.12), borderRadius: BorderRadius.circular(99)),
                        child: VText('✨ زانیاری تەندروستی لە VEX', style: ku(10.5, w: FontWeight.w700, c: V.c2)),
                      ),
                    ],
                  ),
                ),
                for (int i = 0; i < a.items.length; i++) _item(a, i),
                Container(
                  margin: const EdgeInsets.only(top: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                  decoration: BoxDecoration(
                    color: const Color(0x14FFBE4D),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0x40FFBE4D)),
                  ),
                  child: VText.rich(
                    TextSpan(children: [
                      const TextSpan(text: '💡 ژمارەکان خەمڵاندنی VEX ن. دەست لە '),
                      TextSpan(text: '+', style: nu(12, c: const Color(0xFFFFE2A6))),
                      const TextSpan(text: ' بدە، یەکسەر دەچێتە ژەمەکانی ئەمڕۆت و کالۆرییەکەت حیساب دەکرێت.'),
                    ]),
                    style: ku(12, c: const Color(0xFFFFE2A6), h: 1.8),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Press(
                      onTap: () => toast('لە ئەپی ڕاستەقینەدا دەچێتە پەیجی ${a.brand}'),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: a.b1,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [BoxShadow(color: op(a.b1, 0.7), blurRadius: 26, offset: const Offset(0, 12), spreadRadius: -12)],
                        ),
                        child: VText(a.cta, textAlign: TextAlign.center, style: ku(14.5, w: FontWeight.w800, c: Colors.white)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Press(
                      onTap: () => toast('لە ئەپی ڕاستەقینەدا نەخشەی لقەکان دەکرێتەوە'),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: op(Colors.white, 0.06),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: op(const Color(0xFF8CEBF5), 0.2)),
                        ),
                        child: VText('📍 نزیکترین لق', textAlign: TextAlign.center, style: ku(14.5, w: FontWeight.w800)),
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(top: 14),
                child: VText(
                  'ڕێکلام · VEX Ads · ئەم ڕێکلامە بە پێی کاتی ڕۆژ پیشان دەدرێت، نەک داتای تەندروستیت',
                  textAlign: TextAlign.center,
                  style: ku(10.5, c: const Color(0xFF6F969D), h: 1.6),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _hero(BuildContext context, Ad a) {
    final hero = a.hero;
    return SizedBox(
      height: 250,
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRect(
              child: hero != null
                  ? TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 1.04, end: 1.12),
                      duration: const Duration(seconds: 9),
                      curve: Curves.easeOut,
                      builder: (context, v, child) => Transform.scale(scale: v, child: child),
                      child: Image.asset(hero, fit: BoxFit.cover),
                    )
                  : DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [a.b1, a.b2],
                        ),
                      ),
                      child: Center(child: VText(a.emo ?? '', style: const TextStyle(fontSize: 96))),
                    ),
            ),
          ),
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x0D000000), Color(0x0D000000), Color(0xF505222C)],
                  stops: [0.0, 0.3, 0.96],
                ),
              ),
            ),
          ),
          Positioned(
            right: 18,
            left: 18,
            bottom: 14,
            child: Row(
              children: [
                brandLogo(a, 54, ring: 3, ringOpacity: 0.2),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      VText(a.brand, style: nu(21, c: Colors.white)),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Flexible(
                            child: VText(
                              a.sub ?? 'سپۆنسەری VEX Health',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: ku(11.5, c: op(Colors.white, 0.8)),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
                            decoration: BoxDecoration(color: op(Colors.white, 0.14), borderRadius: BorderRadius.circular(99)),
                            child: VText(
                              a.example ? 'سپۆنسەر · نموونە' : 'سپۆنسەر',
                              style: ku(10, w: FontWeight.w700, c: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: 14,
            left: 14,
            child: Press(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: op(Colors.black, 0.4),
                  border: Border.all(color: op(Colors.white, 0.2)),
                ),
                child: const VText('✕', style: TextStyle(color: Colors.white, fontSize: 14)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _offer(Ad a) {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(colors: [op(a.b1, 0.30), op(a.b2, 0.26)]),
        border: Border.all(color: mix(a.b1, Colors.white, 0.3)),
      ),
      child: Row(
        children: [
          const VText('🎁', style: TextStyle(fontSize: 30)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                VText(a.offer[0], style: ku(14.5, w: FontWeight.w800)),
                VText(a.offer[1], style: ku(11.5, c: const Color(0xFFCFE9EE))),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Press(
            onTap: () {
              Clipboard.setData(ClipboardData(text: a.code));
              toast('کۆدەکە کۆپی کرا: ${a.code}');
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
              child: VText(a.code, textDirection: TextDirection.ltr, style: nu(14, c: a.b1, ls: 1.5)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _item(Ad a, int i) {
    final it = a.items[i];
    final done = _added.contains(i);
    Widget chip(String t) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(color: op(Colors.white, 0.07), borderRadius: BorderRadius.circular(99)),
          child: VText(t, style: ku(10.5, w: FontWeight.w700, c: const Color(0xFFCFE9EE))),
        );
    return Container(
      margin: EdgeInsets.only(top: i > 0 ? 9 : 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: op(Colors.white, 0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0x1F8CEBF5)),
      ),
      child: Row(
        children: [
          Image.asset(it.img, width: 70, height: 70, fit: BoxFit.contain),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                VText(it.n, style: ku(14, w: FontWeight.w800)),
                const SizedBox(height: 2),
                VText(
                  '${it.s} · ${it.k} kcal · نزیکەی ${walkMin(it.k)} خولەک پیاسە',
                  style: ku(11.5, c: const Color(0xFF9CC4CB)),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 5,
                  runSpacing: 5,
                  children: [chip('پڕۆتین ${it.p}g'), chip('کاربۆهیدرات ${it.c}g'), chip('چەوری ${it.f}g')],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Press(
            onTap: done ? null : () => _add(i),
            child: Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: done
                    ? null
                    : const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF8FF3F9), Color(0xFF3CF08A)],
                      ),
                color: done ? op(V.mint, 0.25) : null,
              ),
              child: VText(done ? '✓' : '+', style: nu(20, c: done ? V.mint : V.ink, h: 1.0)),
            ),
          ),
        ],
      ),
    );
  }
}
