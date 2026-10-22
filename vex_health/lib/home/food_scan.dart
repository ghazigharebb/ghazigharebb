// VEX Health — سکانی خواردن (کامێرا، گەلەری، نووسین) + کالۆری ئەمڕۆ
import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../core/ai_service.dart';
import '../core/store.dart';
import '../core/theme.dart';
import '../food/food_page.dart';
import '../scan/scan_page.dart';

/// کامێرای سەرەکی (یان گەلەری) ← پەڕەی سکانی خواردن (lib/scan)
Future<void> pickAndAnalyse(ImageSource src) => openFoodScan(source: src);

/// نووسین ← پەڕەی سکانی خواردن
void showAnalyseSheet({Uint8List? image, String? text}) {
  if (text != null && text.trim().isNotEmpty) {
    openFoodText(text);
  } else if (image != null) {
    openFoodImage(image);
  }
}

void showTypeSheet() {
  showVSheet<void>(builder: (_) => const _TypeView());
}

const Map<String, List<String>> kMeals = {
  'b': ['🌅', 'نانی بەیانی'],
  'l': ['☀️', 'نانی نیوەڕۆ'],
  's': ['🍎', 'ژەمی سووک'],
  'd': ['🌙', 'نانی ئێوارە'],
  'n': ['🌃', 'خواردنی درەنگی شەو'],
};

String mealNow() {
  final d = DateTime.now();
  final h = d.hour + d.minute / 60;
  if (h >= 5 && h < 10.5) return 'b';
  if (h >= 10.5 && h < 12) return 's';
  if (h >= 12 && h < 16) return 'l';
  if (h >= 16 && h < 18.5) return 's';
  if (h >= 18.5 && h < 22) return 'd';
  return 'n';
}

class Why {
  const Why(this.e, this.t, this.c);
  final String e;
  final String t;
  final Color c;
}

/// تێبینی بەپێی کات و کالۆری ماوە
List<Why> timeNote(Map<String, dynamic> r) {
  final h = DateTime.now().hour;
  final left = Store.I.left;
  final k = toDouble(r['kcal']);
  final out = <Why>[];
  if ((h >= 22 || h < 5) && k > 350) {
    out.add(const Why('🌙', 'بەم کاتەی شەو قورسە؛ کاریگەری لەسەر خەو دەکات.', Color(0xFF9B7BFF)));
  }
  if (k > left && left > 0) {
    out.add(Why('⚖️', 'لە کالۆری ماوەی ئەمڕۆت (${fmt(left)}) زیاترە.', V.coral));
  }
  if (h >= 5 && h < 11 && toDouble(r['sugar_g']) > 20) {
    out.add(const Why('🌅', 'شیرینی زۆر بە بەیانی زوو برسیت دەکاتەوە.', Color(0xFFFFBE4D)));
  }
  return out;
}

// ============================================================
// کارتی سکانی خواردن
// ============================================================
class FoodScanCard extends StatelessWidget {
  const FoodScanCard({super.key});

  Widget _sub(String label, VoidCallback onTap) => Press(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 11),
          decoration: box(r: 15),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: VText(label, maxLines: 1, textAlign: TextAlign.center, style: ku(13, w: FontWeight.w700)),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return VCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: op(V.orange, 0.16),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: op(V.orange, 0.4)),
                ),
                child: const VText('🍽️', style: TextStyle(fontSize: 22)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    VText('سکانی خواردن', style: ku(16, w: FontWeight.w800)),
                    VText('AI دەڵێت بۆ تۆ باشە یان نا، بەم کاتە', style: ku(12, c: V.mu)),
                  ],
                ),
              ),
              LinkBtn('بەشی خواردن ‹', onTap: () => openFoodPage()),
            ],
          ),
          const SizedBox(height: 12),
          const CamButton(),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _sub('🔎 خواردنەکان', () => openFoodPage())),
              const SizedBox(width: 8),
              Expanded(child: _sub('🖼️ گەلەری', () => pickAndAnalyse(ImageSource.gallery))),
              const SizedBox(width: 8),
              Expanded(child: _sub('✍️ بینووسە', showTypeSheet)),
            ],
          ),
          AnimatedBuilder(
            animation: Store.I,
            builder: (context, _) {
              final s = Store.I;
              return KcalBlock(t: s.totals(), budget: s.budget, last: s.food.isEmpty ? null : s.food.first);
            },
          ),
        ],
      ),
    );
  }
}

class CamButton extends StatefulWidget {
  const CamButton({super.key});

  @override
  State<CamButton> createState() => _CamButtonState();
}

class _CamButtonState extends State<CamButton> with TickerProviderStateMixin {
  late final AnimationController rot =
      AnimationController(vsync: this, duration: const Duration(seconds: 8))..repeat();
  late final AnimationController laser =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1700))..repeat(reverse: true);

  @override
  void dispose() {
    rot.dispose();
    laser.dispose();
    super.dispose();
  }

  Widget _viewfinder() {
    return Container(
      width: 74,
      height: 74,
      decoration: BoxDecoration(color: op(Colors.black, 0.22), borderRadius: BorderRadius.circular(18)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          children: [
            const Positioned.fill(child: CustomPaint(painter: _CornerPainter())),
            const Center(child: VText('🍲', style: TextStyle(fontSize: 32))),
            AnimatedBuilder(
              animation: laser,
              builder: (context, _) => Positioned(
                left: 10,
                right: 10,
                top: 10 + 52 * Curves.easeInOut.transform(laser.value),
                height: 2,
                child: Container(
                  decoration: BoxDecoration(
                    color: V.mint,
                    boxShadow: [BoxShadow(color: V.mint, blurRadius: 10, spreadRadius: 3)],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Press(
      onTap: () => pickAndAnalyse(ImageSource.camera),
      scale: 0.98,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          boxShadow: const [BoxShadow(color: Color(0x996A3DF0), blurRadius: 36, offset: Offset(0, 18), spreadRadius: -20)],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Stack(
            children: [
              const Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF6A3DF0), Color(0xFF3F63F5), Color(0xFF0FA5CC)],
                      stops: [0.0, 0.5, 1.0],
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: OverflowBox(
                  maxWidth: 640,
                  maxHeight: 640,
                  child: RotationTransition(
                    turns: rot,
                    child: const SizedBox(
                      width: 640,
                      height: 640,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: SweepGradient(
                            colors: [
                              Color(0x00FFFFFF),
                              Color(0x40FFFFFF),
                              Color(0x00FFFFFF),
                              Color(0x4D3CF08A),
                              Color(0x003CF08A),
                              Color(0x00FFFFFF),
                            ],
                            stops: [0.0, 0.125, 0.25, 0.4, 0.55, 1.0],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.all(1.5),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(21),
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xF7623AE8), Color(0xF23A5CF0), Color(0xF70D96BE)],
                        stops: [0.0, 0.5, 1.0],
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    _viewfinder(),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          VText('وێنەی خواردنەکەت بگرە', style: ku(16, w: FontWeight.w800, c: Colors.white)),
                          VText(
                            'کالۆری، پێکهاتە و بڕیاری بۆ تۆ لە چەند چرکەیەکدا',
                            style: ku(12, c: op(Colors.white, 0.88), h: 1.6),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(99)),
                            child: VText('📸 سکان بکە', style: ku(12, w: FontWeight.w800, c: const Color(0xFF4B2FC4))),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CornerPainter extends CustomPainter {
  const _CornerPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..color = Colors.white;
    final corner = Path()
      ..moveTo(8.25, 24)
      ..lineTo(8.25, 15)
      ..quadraticBezierTo(8.25, 8.25, 15, 8.25)
      ..lineTo(24, 8.25);
    for (int k = 0; k < 4; k++) {
      canvas.save();
      if (k == 1 || k == 3) {
        canvas.translate(size.width, 0);
        canvas.scale(-1, 1);
      }
      if (k >= 2) {
        canvas.translate(0, size.height);
        canvas.scale(1, -1);
      }
      canvas.drawPath(corner, p);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _CornerPainter oldDelegate) => false;
}

// ---- کالۆری ئەمڕۆ ----
class KcalBlock extends StatelessWidget {
  const KcalBlock({super.key, required this.t, required this.budget, required this.last});
  final Totals t;
  final int budget;
  final FoodItem? last;

  Widget _mac(String label, int g, Color c) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 7, height: 7, decoration: BoxDecoration(shape: BoxShape.circle, color: c)),
          const SizedBox(width: 4),
          VText.rich(
            TextSpan(children: [
              TextSpan(text: '$label '),
              TextSpan(text: '${fmt(g)}g', style: nu(11, c: V.mu)),
            ]),
            style: ku(11, w: FontWeight.w700, c: V.mu),
          ),
        ],
      );

  @override
  Widget build(BuildContext context) {
    final left = budget - t.kcal;
    final over = left < 0;
    final fr = clampD(t.kcal / budget, 0, 1);
    final l = last;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 14),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: VText.rich(
                TextSpan(children: [
                  const TextSpan(text: 'کالۆری ئەمڕۆ '),
                  TextSpan(text: ltr('${fmt(t.kcal)} / ${fmt(budget)}'), style: nu(15, c: V.tx)),
                ]),
                style: ku(12, w: FontWeight.w700, c: V.mu),
              ),
            ),
            VText.rich(
              over
                  ? TextSpan(children: [
                      TextSpan(text: fmt(-left), style: nu(12, c: V.coral)),
                      TextSpan(text: ' زیادە', style: ku(12, w: FontWeight.w800, c: V.coral)),
                    ])
                  : TextSpan(children: [
                      TextSpan(text: fmt(left), style: nu(12, c: V.mint)),
                      const TextSpan(text: ' ماوە'),
                    ]),
              style: ku(12, w: FontWeight.w800, c: V.mint),
            ),
          ],
        ),
        const SizedBox(height: 8),
        KcalTrack(fraction: fr, over: over),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          runSpacing: 4,
          children: [
            _mac('پڕۆتین', t.p, const Color(0xFFFF5F7E)),
            _mac('کاربۆ', t.c, const Color(0xFFFFBE4D)),
            _mac('چەوری', t.f, const Color(0xFF9B7BFF)),
          ],
        ),
        if (l != null)
          Container(
            margin: const EdgeInsets.only(top: 12),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: box(r: 15),
            child: Row(
              children: [
                VText(l.e, style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 10),
                Expanded(
                  child: VText(l.n, maxLines: 1, overflow: TextOverflow.ellipsis, style: ku(13, w: FontWeight.w800)),
                ),
                const SizedBox(width: 8),
                VText(l.at, textDirection: TextDirection.ltr, style: nu(12, w: FontWeight.w600, c: V.mu)),
                const SizedBox(width: 10),
                VText('${fmt(l.kcal)} kcal', textDirection: TextDirection.ltr, style: nu(13, c: V.orange)),
              ],
            ),
          ),
      ],
    );
  }
}

class KcalTrack extends StatefulWidget {
  const KcalTrack({super.key, required this.fraction, required this.over});
  final double fraction;
  final bool over;

  @override
  State<KcalTrack> createState() => _KcalTrackState();
}

class _KcalTrackState extends State<KcalTrack> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = widget.over
        ? const [Color(0xFFFF9466), Color(0xFFFF4F73)]
        : const [Color(0xFF3CF08A), Color(0xFF2FE6F3)];
    return SizedBox(
      height: 14,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(99),
        child: ColoredBox(
          color: V.track,
          child: Align(
            alignment: Alignment.centerLeft,
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: widget.fraction),
              duration: const Duration(milliseconds: 1400),
              curve: const Cubic(0.2, 0.9, 0.2, 1.0),
              builder: (context, v, _) => FractionallySizedBox(
                widthFactor: v,
                heightFactor: 1,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(99),
                    gradient: LinearGradient(colors: colors),
                  ),
                  child: CustomPaint(painter: _StripesPainter(_c)),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StripesPainter extends CustomPainter {
  _StripesPainter(this.a) : super(repaint: a);
  final Animation<double> a;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0) return;
    canvas.save();
    canvas.clipRRect(RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(size.height / 2)));
    final p = Paint()..color = const Color(0x33FFFFFF);
    const period = 14.0;
    const band = 7.0;
    final h = size.height;
    final shift = a.value * period;
    for (double x = -h - period + shift; x < size.width + period; x += period) {
      final path = Path()
        ..moveTo(x, h)
        ..lineTo(x + h, 0)
        ..lineTo(x + h + band, 0)
        ..lineTo(x + band, h)
        ..close();
      canvas.drawPath(path, p);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _StripesPainter oldDelegate) => false;
}

// ============================================================
// شیتی شیکاری AI
// ============================================================
class AnalyseView extends StatefulWidget {
  const AnalyseView({super.key, this.image, this.text});
  final Uint8List? image;
  final String? text;

  @override
  State<AnalyseView> createState() => _AnalyseViewState();
}

class _AnalyseViewState extends State<AnalyseView> with TickerProviderStateMixin {
  late final AnimationController laser =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..repeat(reverse: true);
  late final AnimationController dots =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1000))..repeat();

  static const List<String> _msgs = [
    'خواردنەکان دەناسرێنەوە...',
    'کێش و کالۆری دەژمێردرێت...',
    'بەراورد لەگەڵ ئامانجەکەت...',
  ];

  Timer? _msgT;
  int _msgI = 0;
  bool _done = false;
  String? _err;
  bool _notFood = false;
  String _notFoodName = '';
  Map<String, dynamic>? _r;
  FoodItem? _item;
  String _verdict = 'ok';
  List<Why> _extra = const [];

  @override
  void initState() {
    super.initState();
    _msgT = Timer.periodic(const Duration(milliseconds: 1800), (_) {
      if (mounted) setState(() => _msgI++);
    });
    _run();
  }

  @override
  void dispose() {
    _msgT?.cancel();
    laser.dispose();
    dots.dispose();
    super.dispose();
  }

  Future<void> _run() async {
    try {
      final r = await analyzeFood(image: widget.image, text: widget.text);
      if (!mounted) return;
      _msgT?.cancel();
      _apply(r);
    } catch (_) {
      if (!mounted) return;
      _msgT?.cancel();
      setState(() {
        _done = true;
        _err = 'شیکاری نەکرا. وێنەیەکی ڕوونتر تاقی بکەرەوە یان بینووسە.';
      });
    }
  }

  void _apply(Map<String, dynamic> r) {
    if (r['is_food'] == false) {
      setState(() {
        _done = true;
        _notFood = true;
        _notFoodName = '${r['name'] ?? ''}';
      });
      return;
    }
    final v0 = '${r['verdict']}';
    final v = (v0 == 'good' || v0 == 'ok' || v0 == 'bad') ? v0 : 'ok';
    final extra = timeNote(r);
    final name = '${r['name'] ?? 'خواردن'}';
    final item = FoodItem(
      n: name.length > 70 ? name.substring(0, 70) : name,
      kcal: toInt(r['kcal']),
      p: toInt(r['protein_g']),
      c: toInt(r['carbs_g']),
      f: toInt(r['fat_g']),
      at: nowHM(),
      v: (extra.any((x) => x.c == V.coral) && v == 'good') ? 'ok' : v,
      e: '${r['emoji'] ?? '🍽️'}',
    );
    Store.I.addFood(item);
    setState(() {
      _done = true;
      _r = r;
      _item = item;
      _verdict = v;
      _extra = extra;
    });
  }

  void _again() {
    Navigator.of(context).pop();
    pickAndAnalyse(ImageSource.camera);
  }

  void _type() {
    Navigator.of(context).pop();
    showTypeSheet();
  }

  @override
  Widget build(BuildContext context) {
    final img = widget.image;
    final scanH = img != null ? 240.0 : 200.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        SheetTitle(_item != null ? '✅ ئەنجامی سکان' : '🔬 AI دەپشکنێت'),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Container(
            height: scanH,
            color: const Color(0xFF021419),
            child: Stack(
              children: [
                Positioned.fill(
                  child: img != null
                      ? Image.memory(img, fit: BoxFit.cover)
                      : const Center(child: VText('🍽️', style: TextStyle(fontSize: 60))),
                ),
                if (!_done) ...[
                  AnimatedBuilder(
                    animation: laser,
                    builder: (context, _) => Positioned(
                      left: 16,
                      right: 16,
                      top: scanH * (0.08 + 0.8 * Curves.easeInOut.transform(laser.value)),
                      height: 3,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(9),
                          gradient: LinearGradient(colors: [Color(0x003CF08A), V.mint, Color(0x003CF08A)]),
                          boxShadow: [BoxShadow(color: V.mint, blurRadius: 22, spreadRadius: 5)],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 10,
                    right: 10,
                    bottom: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
                      decoration: BoxDecoration(color: const Color(0xD1021419), borderRadius: BorderRadius.circular(15)),
                      child: Row(
                        children: [
                          _dots(),
                          const SizedBox(width: 10),
                          Expanded(
                            child: VText(
                              _msgs[_msgI % _msgs.length],
                              style: ku(13, w: FontWeight.w700, c: const Color(0xFFEAFFFF)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        if (_err != null) ..._errorView(),
        if (_notFood) ..._notFoodView(),
        if (_item != null) ..._resultView(),
      ],
    );
  }

  Widget _dots() {
    return AnimatedBuilder(
      animation: dots,
      builder: (context, _) => Directionality(
        textDirection: TextDirection.ltr,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (int j = 0; j < 3; j++)
              Builder(builder: (context) {
                final t = (dots.value - j * 0.15) % 1.0;
                final k = t < 0.5 ? t * 2 : (1 - t) * 2;
                return Transform.translate(
                  offset: Offset(0, -5 * k),
                  child: Opacity(
                    opacity: 1 - 0.6 * k,
                    child: Container(
                      width: 6,
                      height: 6,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(shape: BoxShape.circle, color: V.mint),
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  List<Widget> _errorView() => [
        Note(VText('⚠️ ${_err ?? ''}', style: ku(13, h: 1.8))),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: VBtn('✍️ بینووسە', kind: BtnKind.ai, onTap: _type)),
            const SizedBox(width: 8),
            Expanded(child: VBtn('📸 دووبارە', onTap: _again)),
          ],
        ),
      ];

  List<Widget> _notFoodView() => [
        Note(VText('🤔 خواردن نەناسرایەوە: $_notFoodName. لە نزیکەوە وێنە بگرە.', style: ku(13, h: 1.8))),
        const SizedBox(height: 10),
        VBtn('📸 وێنەیەکی تر', kind: BtnKind.prime, onTap: _again),
      ];

  List<Widget> _resultView() {
    final r = _r ?? const <String, dynamic>{};
    final item = _item!;
    final v = _verdict;
    final k = v == 'good' ? V.mint : (v == 'bad' ? V.coral : V.amber);
    final slot = kMeals[mealNow()]!;
    final items = (r['items'] is List) ? (r['items'] as List) : const [];
    final vits = (r['vitamins'] is List) ? (r['vitamins'] as List) : const [];
    final reasons = (r['reasons'] is List) ? (r['reasons'] as List) : const [];
    final tip = r['tip'];
    final demo = r['demo'] == true;

    Widget tile(String val, String label, Color c) => Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 2),
            decoration: box(r: 14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                VText(val, textDirection: TextDirection.ltr, style: nu(15, c: c)),
                VText(label, style: ku(10, w: FontWeight.w700, c: V.mu)),
              ],
            ),
          ),
        );

    Widget chip(Widget child) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: box(r: 99),
          child: child,
        );

    Widget why(String text, Color c, {String? lead}) => Container(
          margin: const EdgeInsets.only(top: 6),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: op(c, 0.09),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: op(c, 0.3)),
          ),
          child: VText(lead == null ? text : '$lead  $text', style: ku(13, h: 1.75)),
        );

    return [
      Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: op(k, 0.18),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: op(k, 0.5)),
              ),
              child: VText(item.e, style: const TextStyle(fontSize: 28)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  VText(item.n, style: ku(17, w: FontWeight.w800, h: 1.5)),
                  VText(
                    (v == 'good' ? '😊 باشە بۆ تۆ' : (v == 'bad' ? '😟 باش نییە بۆ تۆ' : '😐 بە ئەندازە بیخۆ')) +
                        (demo ? ' · نموونە' : ''),
                    style: ku(12, w: FontWeight.w800, c: k),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      Padding(
        padding: const EdgeInsets.only(top: 10, bottom: 4),
        child: Align(
          alignment: Alignment.centerLeft,
          child: VText.rich(
            TextSpan(children: [
              TextSpan(text: fmt(item.kcal), style: nu(40, c: V.orange)),
              TextSpan(text: ' kcal', style: ku(13, c: V.mu)),
            ]),
            textDirection: TextDirection.ltr,
          ),
        ),
      ),
      Row(
        children: [
          tile('${fmt(item.p)}g', 'پڕۆتین', const Color(0xFFFF5F7E)),
          const SizedBox(width: 6),
          tile('${fmt(item.c)}g', 'کاربۆ', const Color(0xFFFFBE4D)),
          const SizedBox(width: 6),
          tile('${fmt(item.f)}g', 'چەوری', const Color(0xFF9B7BFF)),
          const SizedBox(width: 6),
          tile('${fmt(toDouble(r['sugar_g']))}g', 'شەکر', const Color(0xFFFF8FC8)),
        ],
      ),
      Padding(
        padding: const EdgeInsets.only(top: 10),
        child: Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final x in items.take(6))
              if (x is Map)
                chip(VText.rich(
                  TextSpan(children: [
                    TextSpan(text: '${x['name'] ?? ''} '),
                    TextSpan(text: '${fmt(toDouble(x['grams']))}g', style: nu(12, w: FontWeight.w600, c: V.mu)),
                  ]),
                  style: ku(12, w: FontWeight.w700),
                )),
            for (final x in vits.take(4)) chip(VText('💊 $x', style: ku(12, w: FontWeight.w700))),
          ],
        ),
      ),
      Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final x in reasons.take(3)) why('$x', k),
            for (final x in _extra) why(x.t, x.c, lead: x.e),
          ],
        ),
      ),
      if (tip != null && '$tip'.isNotEmpty) Note(VText('💡 $tip', style: ku(13, h: 1.8))),
      Container(
        margin: const EdgeInsets.only(top: 12),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
        decoration: BoxDecoration(
          color: op(V.mint, 0.1),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: op(V.mint, 0.45)),
        ),
        child: Row(
          children: [
            const VText('✅'),
            const SizedBox(width: 10),
            Expanded(
              child: VText.rich(
                TextSpan(children: [
                  TextSpan(text: 'زیاد کرا بۆ ${slot[0]} ${slot[1]} · '),
                  TextSpan(text: item.at, style: nu(13, c: V.tx)),
                ]),
                style: ku(13, w: FontWeight.w700),
              ),
            ),
            Press(
              onTap: () {
                Store.I.removeFirst();
                Navigator.of(context).pop();
                toast('سڕایەوە لە ژەمەکان');
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: box(r: 10, border: V.line2),
                child: VText('پاشگەزبوونەوە', style: ku(12, w: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 10),
      Row(
        children: [
          Expanded(child: VBtn('📸 وێنەیەکی تر', kind: BtnKind.ai, onTap: _again)),
          const SizedBox(width: 8),
          Expanded(
            child: VBtn('🍽️ بەشی خواردن', onTap: () {
              Navigator.of(context).pop();
              toast('دەچێتە بەشی خواردن (لە ئەپی ڕاستەقینەدا)');
            }),
          ),
        ],
      ),
    ];
  }
}

// ---- نووسینی خواردن ----
class _TypeView extends StatefulWidget {
  const _TypeView();

  @override
  State<_TypeView> createState() => _TypeViewState();
}

class _TypeViewState extends State<_TypeView> {
  final TextEditingController _c = TextEditingController();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _go() {
    final t = _c.text.trim();
    if (t.isEmpty) return;
    Navigator.of(context).pop();
    showAnalyseSheet(text: t);
  }

  @override
  Widget build(BuildContext context) {
    OutlineInputBorder b(Color c) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: c),
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        const SheetTitle('✍️ چیت خوارد؟'),
        const SizedBox(height: 6),
        TextField(
          controller: _c,
          autofocus: true,
          minLines: 2,
          maxLines: 4,
          style: ku(14),
          cursorColor: V.cy,
          decoration: InputDecoration(
            hintText: vxTr('بۆ نموونە: 8 دانە دۆڵمە و پەرداخێک دۆ'),
            hintStyle: ku(14, c: V.mu),
            filled: true,
            fillColor: V.surf2,
            contentPadding: const EdgeInsets.all(12),
            border: b(V.line),
            enabledBorder: b(V.line),
            focusedBorder: b(V.cy),
          ),
        ),
        const SizedBox(height: 10),
        VBtn('✨ شیکاری بکە', kind: BtnKind.ai, onTap: _go),
      ],
    );
  }
}

