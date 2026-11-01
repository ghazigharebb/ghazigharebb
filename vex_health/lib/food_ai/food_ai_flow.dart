// VEX AI Food v2 — کامێرا (تا 5 وێنە) ← شیکردنەوە ← لیست (+ / −) ← ڕاستکردنەوە ← وردەکاری ← تۆمارکرا
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../core/store.dart';
import '../core/theme.dart';
import '../plus/gate.dart' show ScanQuota;
import '../scan/scan_ai.dart' show ScanFail;
import 'food_ai_data.dart';
import 'food_ai_store.dart';
import 'food_ai_widgets.dart';

final ImagePicker _picker = ImagePicker();
const int kMaxShots = 5;

/// کامێرای VEX AI (تا 5 وێنە)
Future<void> openFoodCapture({bool gallery = false}) async {
  final nav = navKey.currentState;
  if (nav == null) return;
  await nav.push(foodRoute<void>(FoodCapturePage(openGallery: gallery)));
}

/// نووسین ← لیستی ژەم
Future<void> openFoodText() async {
  final ctx = navKey.currentContext;
  if (ctx == null) return;
  final items = await showFoodTextSheet(ctx);
  if (items == null || items.isEmpty) return;
  for (final it in items) {
    it.png.value = 1;
  }
  navKey.currentState?.push(foodRoute<void>(FoodReviewPage(items: items, shots: const [])));
}

/// خواردنێک لە «خواردنەکانی تۆ» ← لیستی ژەم
void openFoodQuick(FDish d) {
  final it = FItem(dish: d, unit: d.u0, q: d.q0, conf: 1);
  it.png.value = 1;
  navKey.currentState?.push(foodRoute<void>(FoodReviewPage(items: [it], shots: const [])));
}

Future<List<FShot>> _pickGallery(int room) async {
  if (room <= 0) return const [];
  try {
    final xs = await _picker.pickMultiImage(maxWidth: 1600, maxHeight: 1600, imageQuality: 85, requestFullMetadata: false);
    final out = <FShot>[];
    for (final x in xs.take(room)) {
      final b = await x.readAsBytes();
      if (b.isNotEmpty) out.add(FShot(bytes: b));
    }
    if (xs.length > room) toast('تەنها $room وێنەی یەکەم وەرگیران (زۆرترین 5)');
    return out;
  } on PlatformException catch (e) {
    final c = e.code.toLowerCase();
    toast(c.contains('denied') || c.contains('access') || c.contains('permission')
        ? 'ڕێگە بە وێنەکان بدە لە ڕێکخستنەکانی مۆبایلەکەت'
        : 'گەلەری نەکرایەوە. دووبارە هەوڵ بدەرەوە.');
  } catch (_) {
    toast('گەلەری نەکرایەوە. دووبارە هەوڵ بدەرەوە.');
  }
  return const [];
}

Future<FShot?> _pickCamera() async {
  try {
    final x = await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1600,
      maxHeight: 1600,
      imageQuality: 85,
      preferredCameraDevice: CameraDevice.rear,
      requestFullMetadata: false,
    );
    if (x == null) return null;
    final b = await x.readAsBytes();
    if (b.isEmpty) {
      toast('وێنەکە نەخوێنرایەوە. دووبارە هەوڵ بدەرەوە.');
      return null;
    }
    return FShot(bytes: b);
  } on PlatformException catch (e) {
    final c = e.code.toLowerCase();
    if (c.contains('no_available_camera')) {
      toast('کامێرا لەم مۆبایلەدا نەدۆزرایەوە');
    } else if (c.contains('denied') || c.contains('access') || c.contains('permission')) {
      toast('ڕێگە بە کامێرا بدە لە ڕێکخستنەکانی مۆبایلەکەت');
    } else {
      toast('کامێرا نەکرایەوە. دووبارە هەوڵ بدەرەوە.');
    }
  } catch (_) {
    toast('کامێرا نەکرایەوە. دووبارە هەوڵ بدەرەوە.');
  }
  return null;
}

Color _detColor(String id) => const {
      'rice': kCarb,
      'kebab': kFat,
      'salad': kMint,
      'dolma': kMint,
      'doogh': kWarn,
      'kunafa': kCarb,
      'tea': kFat,
      'bread': kCarb,
      'hummus': kCarb,
      'kubba': kFat,
    }[id] ??
    kCy;

double _rotOf(String id) => ((id.hashCode % 17) - 8) * math.pi / 180;

class _IconBtn extends StatelessWidget {
  const _IconBtn(this.icon, this.onTap, {super.key, this.size = 44, this.dark = false});
  final String icon;
  final VoidCallback? onTap;
  final double size;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final c = dark ? Colors.white : V.tx;
    return Press(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: dark ? const Color(0x22FFFFFF) : V.surf,
          borderRadius: BorderRadius.circular(size * .34),
          border: Border.all(color: dark ? const Color(0x33FFFFFF) : V.line),
        ),
        child: ic(icon, c, size: 20),
      ),
    );
  }
}

// ═══════════════════════════════ 1 · کامێرا ═══════════════════════════════

class FoodCapturePage extends StatefulWidget {
  const FoodCapturePage({super.key, this.openGallery = false, this.retake = false});
  final bool openGallery;

  /// وێنەی نوێ بۆ یەک خواردن ← وێنەکان دەگەڕێنێتەوە (List<FShot>)
  final bool retake;

  @override
  State<FoodCapturePage> createState() => _FoodCapturePageState();
}

class _FoodCapturePageState extends State<FoodCapturePage> with SingleTickerProviderStateMixin {
  final List<FShot> shots = [];
  late final AnimationController _blink = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat();
  String? _view;
  bool _det = false;
  bool _busy = false;
  int _flash = 0;
  FShot? _flyShot;
  Rect? _flyRect;

  @override
  void initState() {
    super.initState();
    if (widget.openGallery) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _gallery());
    }
  }

  @override
  void dispose() {
    _blink.dispose();
    super.dispose();
  }

  Size get _size => MediaQuery.of(context).size;
  EdgeInsets get _pad => MediaQuery.of(context).padding;

  Rect _slot(int i) {
    final w = _size.width;
    final left = (w - (52 * 5 + 9 * 4)) / 2 + (4 - i) * 61;
    final top = _size.height - _pad.bottom - 146 - 52;
    return Rect.fromLTWH(left, top, 52, 52);
  }

  bool _room() {
    if (shots.length + (_flyShot == null ? 0 : 1) >= kMaxShots) {
      toast('زۆرترین 5 وێنە بە یەک جار');
      return false;
    }
    return true;
  }

  Future<void> _sample(String id) async {
    if (_busy || !_room()) return;
    _busy = true;
    HapticFeedback.selectionClick();
    setState(() {
      _view = id;
      _det = false;
    });
    await Future<void>.delayed(const Duration(milliseconds: 380));
    if (!mounted) return;
    setState(() => _det = true);
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    await _snap(FShot(sample: id));
    _busy = false;
  }

  Future<void> _snap(FShot s) async {
    HapticFeedback.mediumImpact();
    final to = _slot(shots.length);
    setState(() {
      _flash++;
      _flyShot = s;
      _flyRect = Offset.zero & _size;
    });
    await Future<void>.delayed(const Duration(milliseconds: 40));
    if (!mounted) return;
    setState(() => _flyRect = to);
    await Future<void>.delayed(const Duration(milliseconds: 640));
    if (!mounted) return;
    setState(() {
      shots.add(s);
      _flyShot = null;
      _flyRect = null;
      _view = null;
      _det = false;
    });
  }

  Future<void> _camera() async {
    if (_busy || !_room()) return;
    _busy = true;
    final s = await _pickCamera();
    _busy = false;
    if (s != null && mounted) await _snap(s);
  }

  Future<void> _gallery() async {
    if (_busy) return;
    _busy = true;
    final l = await _pickGallery(kMaxShots - shots.length);
    _busy = false;
    if (l.isNotEmpty && mounted) setState(() => shots.addAll(l));
  }

  void _go() {
    if (shots.isEmpty || _flyShot != null) return;
    if (widget.retake) {
      Navigator.of(context).pop(List<FShot>.of(shots));
      return;
    }
    // تەنها کاتێک AI ـی ڕاستەقینە بەکاردێت سکانی خۆڕایی دەژمێردرێت
    if (FoodAiEngine.live && shots.any((s) => s.bytes != null) && !ScanQuota.take()) return;
    Navigator.of(context).pushReplacement(foodRoute<void>(FoodAnalysisPage(shots: List<FShot>.of(shots))));
  }

  Future<void> _text() async {
    final items = await showFoodTextSheet(context);
    if (items == null || items.isEmpty || !mounted) return;
    for (final it in items) {
      it.png.value = 1;
    }
    Navigator.of(context).pushReplacement(foodRoute<void>(FoodReviewPage(items: items, shots: const [])));
  }

  Widget _viewfinder() {
    final w = _size.width;
    final ds = math.min(w * 0.8, 330.0);
    final d = _view == null ? null : dishById(_view!);
    return Stack(fit: StackFit.expand, children: [
      // چوارچێوەی ڕێنمایی
      AnimatedOpacity(
        opacity: d == null ? 1 : 0,
        duration: const Duration(milliseconds: 300),
        child: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            SizedBox(width: ds, height: ds, child: CustomPaint(painter: _Corners())),
            const SizedBox(height: 14),
            Text('خواردنەکەت بخەرە ناو چوارچێوەکە', style: ku(13, w: FontWeight.w600, c: Colors.white.withAlpha(200))),
          ]),
        ),
      ),
      AnimatedSwitcher(
        duration: const Duration(milliseconds: 420),
        switchInCurve: kEase,
        transitionBuilder: (c, a) => FadeTransition(opacity: a, child: ScaleTransition(scale: Tween<double>(begin: .86, end: 1).animate(a), child: c)),
        child: d == null
            ? const SizedBox.shrink()
            : Center(
                key: ValueKey<String>('vf-${d.id}'),
                child: SizedBox(
                  width: ds,
                  height: ds,
                  child: Stack(clipBehavior: Clip.none, children: [
                    Positioned.fill(
                      child: Transform.rotate(
                        angle: _rotOf(d.id),
                        child: Container(
                          decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withAlpha(120), blurRadius: 30, offset: const Offset(0, 16))]),
                          child: DishPng(d, size: ds),
                        ),
                      ),
                    ),
                    // چوارچێوەی ناسینەوە
                    Positioned.fill(
                      child: AnimatedOpacity(
                        opacity: _det ? 1 : 0,
                        duration: const Duration(milliseconds: 300),
                        child: AnimatedScale(
                          scale: _det ? 1 : 1.15,
                          duration: const Duration(milliseconds: 450),
                          curve: kSpring,
                          child: Container(
                            margin: EdgeInsets.all(ds * .05),
                            decoration: BoxDecoration(border: Border.all(color: _detColor(d.id), width: 2.5), borderRadius: BorderRadius.circular(26)),
                          ),
                        ),
                      ),
                    ),
                    PositionedDirectional(
                      top: ds * .05 - 13,
                      start: 22,
                      child: AnimatedOpacity(
                        opacity: _det ? 1 : 0,
                        duration: const Duration(milliseconds: 300),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(color: _detColor(d.id), borderRadius: BorderRadius.circular(99)),
                          child: Text(d.id == 'doogh' ? 'شیر ؟' : d.name, style: ku(12, w: FontWeight.w800, c: kInk)),
                        ),
                      ),
                    ),
                  ]),
                ),
              ),
      ),
    ]);
  }

  Widget _samples() {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        ic(FI.spark, kCy, size: 12, fill: true),
        const SizedBox(width: 5),
        Text('نموونەکان بۆ تاقیکردنەوە — دەستی لێبدە', style: ku(11.5, w: FontWeight.w700, c: Colors.white.withAlpha(215))),
      ]),
      const SizedBox(height: 6),
      SizedBox(
        height: 70,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: kDishes.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (context, i) {
            final d = kDishes[i];
            final on = _view == d.id;
            return Press(
              key: ValueKey<String>('fa-sample-${d.id}'),
              onTap: () => _sample(d.id),
              child: SizedBox(
                width: 54,
                child: Column(children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    width: 50,
                    height: 50,
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0x66000000),
                      border: Border.all(color: on ? kCy : const Color(0x55FFFFFF), width: on ? 2.2 : 1.2),
                    ),
                    child: DishPng(d, size: 44),
                  ),
                  const SizedBox(height: 3),
                  Text(d.name, maxLines: 1, overflow: TextOverflow.clip, style: ku(10, w: FontWeight.w600, c: Colors.white.withAlpha(220), h: 1.1)),
                ]),
              ),
            );
          },
        ),
      ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final pad = _pad;
    final n = shots.length;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(children: [
          Positioned.fill(child: Image.asset(kWood, fit: BoxFit.cover)),
          Positioned(
            left: 0,
            right: 0,
            top: pad.top + 64,
            bottom: pad.bottom + 316,
            child: _viewfinder(),
          ),
          // سەرەوە
          Positioned(
            top: pad.top + 10,
            left: 16,
            right: 16,
            child: Row(children: [
              _IconBtn(FI.x, () => Navigator.of(context).maybePop(), dark: true, key: const ValueKey<String>('fa-close')),
              const Spacer(),
              FChip(
                dark: true,
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  AnimatedBuilder(
                    animation: _blink,
                    builder: (context, _) => Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: kMint, boxShadow: [
                        BoxShadow(color: kMint.withAlpha(((1 - _blink.value) * 90).round()), spreadRadius: 3 + 3 * _blink.value),
                      ]),
                    ),
                  ),
                  const SizedBox(width: 7),
                  Text(FoodAiEngine.live ? 'AI ئامادەیە' : 'AI · دۆخی نموونە', style: ku(12, w: FontWeight.w700, c: kCy)),
                  Text(' · ', style: ku(12, c: kCy)),
                  Text('$n/5', style: nu(12, w: FontWeight.w700, c: kCy), textDirection: TextDirection.ltr),
                ]),
              ),
              const Spacer(),
              _IconBtn(FI.edit, _text, dark: true, key: const ValueKey<String>('fa-cap-text')),
            ]),
          ),
          // نموونەکان
          Positioned(left: 0, right: 0, bottom: pad.bottom + 232, child: _samples()),
          Positioned(
            left: 0,
            right: 0,
            bottom: pad.bottom + 206,
            child: Text.rich(
              TextSpan(children: [
                const TextSpan(text: 'تا '),
                TextSpan(text: '5', style: nu(11.5, w: FontWeight.w700, c: Colors.white.withAlpha(170))),
                const TextSpan(text: ' وێنە بە یەک جار · هەموو خواردنەکان پێکەوە'),
              ]),
              textAlign: TextAlign.center,
              style: ku(11.5, c: Colors.white.withAlpha(170)),
            ),
          ),
          // خانەکان
          for (var i = 0; i < kMaxShots; i++)
            Positioned.fromRect(
              rect: _slot(i),
              child: Press(
                key: ValueKey<String>('fa-slot-$i'),
                onTap: i < n ? () => setState(() => shots.removeAt(i)) : null,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0x66000000),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: i < n ? kCy : const Color(0x55FFFFFF), width: i < n ? 2 : 1.5),
                  ),
                  child: i < n
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(13),
                          child: Stack(fit: StackFit.expand, children: [
                            ShotView(shot: shots[i], zoom: 1.05),
                            Positioned(
                              left: 4,
                              bottom: 2,
                              child: Text('${i + 1}', style: nu(10, c: Colors.white).copyWith(shadows: const [Shadow(blurRadius: 3)])),
                            ),
                            Positioned(
                              right: 3,
                              top: 3,
                              child: Container(
                                width: 15,
                                height: 15,
                                alignment: Alignment.center,
                                decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xAA000000)),
                                child: ic(FI.x, Colors.white, size: 9, stroke: 3),
                              ),
                            ),
                          ]),
                        )
                      : null,
                ),
              ),
            ),
          // دوگمەکان
          Positioned(
            left: 0,
            right: 0,
            bottom: pad.bottom + 30,
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
              SizedBox(width: 110, child: Center(child: _IconBtn(FI.gal, _gallery, size: 50, dark: true, key: const ValueKey<String>('fa-gallery')))),
              Press(
                key: const ValueKey<String>('fa-shutter'),
                onTap: _camera,
                scale: 0.9,
                child: Container(
                  width: 82,
                  height: 82,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 4)),
                  child: Container(width: 64, height: 64, decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white)),
                ),
              ),
              SizedBox(
                width: 110,
                child: Center(
                  child: Press(
                    key: const ValueKey<String>('fa-go'),
                    onTap: n > 0 ? _go : null,
                    child: AnimatedOpacity(
                      opacity: n > 0 ? 1 : 0.35,
                      duration: const Duration(milliseconds: 300),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                        decoration: BoxDecoration(gradient: const LinearGradient(colors: [kCy, kMint]), borderRadius: BorderRadius.circular(99)),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          ic(FI.spark, kInk, size: 13, fill: true),
                          const SizedBox(width: 4),
                          Text(widget.retake ? 'باشە' : 'شیکردنەوە', style: ku(13, w: FontWeight.w800, c: kInk)),
                          if (n > 0) ...[
                            const SizedBox(width: 5),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6),
                              decoration: BoxDecoration(color: kInk, borderRadius: BorderRadius.circular(99)),
                              child: Text('$n', style: nu(11.5, c: kCy)),
                            ),
                          ],
                        ]),
                      ),
                    ),
                  ),
                ),
              ),
            ]),
          ),
          // وێنەکە دەفڕێت بۆ خانەکە
          if (_flyShot != null && _flyRect != null)
            AnimatedPositioned.fromRect(
              rect: _flyRect!,
              duration: const Duration(milliseconds: 600),
              curve: kEase,
              child: IgnorePointer(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(_flyRect!.width < 100 ? 15 : 0),
                  child: _flyShot!.bytes != null
                      ? Image.memory(_flyShot!.bytes!, fit: BoxFit.cover)
                      : Stack(fit: StackFit.expand, children: [
                          Image.asset(kWood, fit: BoxFit.cover),
                          Center(child: FractionallySizedBox(widthFactor: .82, child: AspectRatio(aspectRatio: 1, child: DishPng(dishById(_flyShot!.sample!)!, size: 400)))),
                        ]),
                ),
              ),
            ),
          // فلاش
          IgnorePointer(
            child: TweenAnimationBuilder<double>(
              key: ValueKey<int>(_flash),
              tween: Tween<double>(begin: _flash == 0 ? 0 : .85, end: 0),
              duration: const Duration(milliseconds: 400),
              builder: (context, v, _) => Container(color: Colors.white.withAlpha((v * 255).round())),
            ),
          ),
        ]),
      ),
    );
  }
}

class _Corners extends CustomPainter {
  @override
  void paint(Canvas canvas, Size s) {
    final p = Paint()
      ..color = Colors.white.withAlpha(210)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;
    const l = 34.0, r = 26.0;
    final path = Path()
      ..moveTo(0, l + r)
      ..lineTo(0, r)
      ..arcToPoint(const Offset(r, 0), radius: const Radius.circular(r))
      ..lineTo(l + r, 0)
      ..moveTo(s.width - l - r, 0)
      ..lineTo(s.width - r, 0)
      ..arcToPoint(Offset(s.width, r), radius: const Radius.circular(r))
      ..lineTo(s.width, l + r)
      ..moveTo(s.width, s.height - l - r)
      ..lineTo(s.width, s.height - r)
      ..arcToPoint(Offset(s.width - r, s.height), radius: const Radius.circular(r))
      ..lineTo(s.width - l - r, s.height)
      ..moveTo(l + r, s.height)
      ..lineTo(r, s.height)
      ..arcToPoint(Offset(0, s.height - r), radius: const Radius.circular(r))
      ..lineTo(0, s.height - l - r);
    canvas.drawPath(path, p);
  }

  @override
  bool shouldRepaint(_Corners o) => false;
}

// ═══════════════════════════════ 2 · شیکردنەوە ═══════════════════════════════

class FoodAnalysisPage extends StatefulWidget {
  const FoodAnalysisPage({super.key, required this.shots});
  final List<FShot> shots;

  @override
  State<FoodAnalysisPage> createState() => _FoodAnalysisPageState();
}

class _FoodAnalysisPageState extends State<FoodAnalysisPage> with TickerProviderStateMixin {
  late final AnimationController _scan = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))..repeat();
  late final Ticker _tk;
  Duration _el = Duration.zero;
  bool _seg = false;
  bool _lift = false;
  final Set<int> _done = {};
  final List<FItem> _found = [];
  FResult? _res;
  String? _err;

  @override
  void initState() {
    super.initState();
    _tk = createTicker((d) => setState(() => _el = d))..start();
    _run();
  }

  @override
  void dispose() {
    _tk.dispose();
    _scan.dispose();
    super.dispose();
  }

  Future<void> _wait(int ms) => Future<void>.delayed(Duration(milliseconds: ms));

  Future<void> _run() async {
    final f = FoodAiEngine.analyse(widget.shots).then<FResult?>((r) => r).catchError((Object e) {
      _err = e is ScanFail ? e.message : 'شیکاری نەکرا. دووبارە هەوڵ بدەرەوە.';
      return null;
    });
    await _wait(600);
    if (!mounted) return;
    setState(() => _seg = true);
    await _wait(780);
    if (!mounted) return;
    setState(() => _lift = true);
    final r = await f;
    await _wait(520);
    if (!mounted) return;
    if (r == null) {
      _tk.stop();
      setState(() {});
      return;
    }
    _res = r;
    final ns = widget.shots.length;
    for (var i = 0; i < ns; i++) {
      setState(() => _done.add(i));
      await _wait(200);
      for (final it in r.items.where((x) => (x.shot < 0 || x.shot >= ns ? 0 : x.shot) == i)) {
        if (!mounted) return;
        setState(() => _found.add(it));
        await _wait(210);
      }
      await _wait(150);
      if (!mounted) return;
    }
    _tk.stop();
    setState(() {});
    await _wait(900);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(foodRoute<void>(FoodReviewPage(items: r.items, shots: widget.shots, demoReal: r.demoReal)));
  }

  Widget _scanLine() => AnimatedBuilder(
        animation: _scan,
        builder: (context, _) => LayoutBuilder(builder: (context, c) {
          final h = c.maxHeight * .35;
          return Stack(children: [
            Positioned(
              left: 0,
              right: 0,
              top: -h + (c.maxHeight + h) * _scan.value,
              height: h,
              child: const DecoratedBox(
                decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0x002FE6F3), Color(0x442FE6F3), Color(0x002FE6F3)])),
              ),
            ),
          ]);
        }),
      );

  Widget _stage() {
    final s0 = widget.shots.first;
    final d0 = s0.sample == null ? null : dishById(s0.sample!);
    final ready = _res != null;
    return Container(
      height: 300,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(26), border: Border.all(color: V.line)),
      clipBehavior: Clip.antiAlias,
      child: Stack(fit: StackFit.expand, children: [
        ShotView(shot: s0, zoom: .95, rot: -6 * math.pi / 180),
        if (!ready || _done.isEmpty) _scanLine(),
        // بازنەی جیاکردنەوە
        if (d0 != null)
          Center(
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: _seg ? 1 : 0),
              duration: const Duration(milliseconds: 1000),
              curve: Curves.easeInOut,
              builder: (context, v, _) => SizedBox(width: 250, height: 250, child: CustomPaint(painter: _SegRing(v, _detColor(d0.id)))),
            ),
          ),
        // بڕین و بەرزکردنەوە (PNG)
        if (d0 != null)
          Center(
            child: AnimatedOpacity(
              opacity: _lift ? 1 : 0,
              duration: const Duration(milliseconds: 500),
              child: AnimatedSlide(
                offset: _lift ? const Offset(0, -0.04) : Offset.zero,
                duration: const Duration(milliseconds: 700),
                curve: kEase,
                child: AnimatedScale(
                  scale: _lift ? 0.92 : 0.8,
                  duration: const Duration(milliseconds: 700),
                  curve: kEase,
                  child: Container(
                    decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withAlpha(150), blurRadius: 28, offset: const Offset(0, 18))]),
                    child: DishPng(d0, size: 220),
                  ),
                ),
              ),
            ),
          ),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ns = widget.shots.length;
    final sec = (_el.inMilliseconds / 1000 * 0.62).toStringAsFixed(1);
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: V.bg,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Row(children: [
                _IconBtn(FI.x, () => Navigator.of(context).maybePop()),
                Expanded(child: Text('شیکردنەوە', textAlign: TextAlign.center, style: ku(19, w: FontWeight.w700))),
                FChip(
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    ic(FI.clock, V.cy, size: 13),
                    const SizedBox(width: 5),
                    Text('${sec}s', style: nu(12, w: FontWeight.w700, c: V.cy), textDirection: TextDirection.ltr),
                  ]),
                ),
              ]),
              const SizedBox(height: 12),
              _stage(),
              if (ns > 1) ...[
                const SizedBox(height: 12),
                Row(children: [
                  for (var i = 0; i < ns; i++) ...[
                    if (i > 0) const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        height: 70,
                        clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: V.line)),
                        child: Stack(fit: StackFit.expand, children: [
                          ShotView(shot: widget.shots[i], zoom: 1.0),
                          if (!_done.contains(i)) _scanLine(),
                          Positioned(
                            top: 6,
                            left: 6,
                            child: AnimatedScale(
                              scale: _done.contains(i) ? 1 : 0,
                              duration: const Duration(milliseconds: 400),
                              curve: kSpring,
                              child: Container(
                                width: 20,
                                height: 20,
                                alignment: Alignment.center,
                                decoration: const BoxDecoration(shape: BoxShape.circle, color: kMint),
                                child: ic(FI.check, kInk, size: 13, stroke: 3),
                              ),
                            ),
                          ),
                        ]),
                      ),
                    ),
                  ],
                ]),
              ],
              const SizedBox(height: 12),
              if (_err != null)
                _ErrorCard(msg: _err!, onBack: () => Navigator.of(context).maybePop())
              else ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text.rich(TextSpan(children: [
                    TextSpan(text: '${_found.length}', style: nu(12, w: FontWeight.w700, c: V.mu)),
                    const TextSpan(text: ' خواردن دۆزرایەوە'),
                  ]), style: ku(11.5, c: V.mu)),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView(padding: EdgeInsets.zero, children: [
                    for (final it in _found)
                      TweenAnimationBuilder<double>(
                        key: ObjectKey(it),
                        tween: Tween<double>(begin: 0, end: 1),
                        duration: const Duration(milliseconds: 550),
                        curve: kSpring,
                        builder: (context, v, child) => Opacity(
                          opacity: v.clamp(0.0, 1.0).toDouble(),
                          child: Transform.translate(offset: Offset(0, -30 * (1 - v)), child: Transform.scale(scale: .9 + .1 * v, child: child)),
                        ),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 7),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          decoration: box(r: 16, color: V.surf),
                          child: Row(children: [
                            CheckerBox(radius: 12, child: SizedBox(width: 42, height: 42, child: Center(child: DishPng(it.dish, size: 40)))),
                            const SizedBox(width: 10),
                            Text(it.sure ? it.dish.name : '${it.guess ?? it.dish.name} ؟', style: ku(14, w: FontWeight.w700)),
                            const Spacer(),
                            Text(it.word, style: ku(11.5, c: V.mu)),
                            const SizedBox(width: 8),
                            Container(width: 7, height: 7, decoration: BoxDecoration(shape: BoxShape.circle, color: it.sure ? kMint : kWarn)),
                          ]),
                        ),
                      ),
                  ]),
                ),
              ],
            ]),
          ),
        ),
      ),
    );
  }
}

class _SegRing extends CustomPainter {
  _SegRing(this.v, this.c);
  final double v;
  final Color c;
  @override
  void paint(Canvas canvas, Size s) {
    if (v <= 0) return;
    canvas.drawArc(Offset.zero & s, -math.pi / 2, math.pi * 2 * v, false, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..color = c);
  }

  @override
  bool shouldRepaint(_SegRing o) => o.v != v;
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.msg, required this.onBack});
  final String msg;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: box(r: 20, color: op(kFat, 0.08), border: op(kFat, 0.4)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(msg, textAlign: TextAlign.center, style: ku(14, w: FontWeight.w600)),
        const SizedBox(height: 12),
        GradBtn(label: 'گەڕانەوە', onTap: onBack, pad: const EdgeInsets.all(12), size: 14),
      ]),
    );
  }
}

// ═══════════════════════════════ 3 · لیستی ژەم ═══════════════════════════════

class FoodReviewPage extends StatefulWidget {
  const FoodReviewPage({super.key, required this.items, required this.shots, this.demoReal = false, this.slot});
  final List<FItem> items;
  final List<FShot> shots;
  final bool demoReal;
  final String? slot;

  @override
  State<FoodReviewPage> createState() => _FoodReviewPageState();
}

class _FoodReviewPageState extends State<FoodReviewPage> with SingleTickerProviderStateMixin {
  late final List<FItem> items = List<FItem>.of(widget.items);
  late String slot = widget.slot ?? mealAt(DateTime.now());
  late final String _at = nowHM();
  final Map<FItem, int> _dir = {};
  late final AnimationController _png;
  late final List<double> _s, _e;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final n = items.length;
    _s = [for (var i = 0; i < n; i++) .3 + i * .25];
    _e = [for (var i = 0; i < n; i++) 1.7 + i * .65];
    final total = n == 0 ? 0.1 : _e.last + .1;
    _png = AnimationController(vsync: this, duration: Duration(milliseconds: (total * 1000).round()))
      ..addListener(_tickPng)
      ..forward();
  }

  void _tickPng() {
    final t = _png.value * (_png.duration!.inMilliseconds / 1000);
    for (var i = 0; i < _s.length && i < widget.items.length; i++) {
      final it = widget.items[i];
      if (it.png.value >= 1 || (it.dish.img == null && it.dish.net == null)) continue;
      it.png.value = ((t - _s[i]) / (_e[i] - _s[i])).clamp(0.0, 1.0).toDouble();
    }
  }

  @override
  void dispose() {
    _png.dispose();
    super.dispose();
  }

  FNut get _tot => items.fold(FNut.zero, (a, x) => a + x.nut);
  int get _unsure => items.where((x) => !x.sure).length;

  FShot? _shotOf(FItem it) => it.shot >= 0 && it.shot < widget.shots.length ? widget.shots[it.shot] : null;

  void _step(FItem it, int dir) {
    if (it.step(dir)) {
      HapticFeedback.selectionClick();
      setState(() => _dir[it] = dir);
    }
  }

  Future<void> _fix(FItem it) async {
    final r = await showFixSheet(context, it);
    if (!mounted || r == null) return;
    if (r == 'delete') {
      setState(() => items.remove(it));
    } else if (r == 'retake') {
      final shots = await Navigator.of(context).push<List<FShot>>(foodRoute<List<FShot>>(const FoodCapturePage(retake: true)));
      if (shots == null || shots.isEmpty || !mounted) return;
      final res = await FoodAiEngine.analyse(shots).catchError((Object _) => const FResult([]));
      if (!mounted) return;
      setState(() {
        final i = items.indexOf(it);
        items.remove(it);
        for (final x in res.items) {
          x.png.value = 1;
          x.shot = -1;
        }
        items.insertAll(i < 0 ? items.length : i, res.items);
      });
    } else if (r is FDish) {
      setState(() {
        it.setDish(r);
        it.png.value = 1;
      });
    }
  }

  Future<void> _detail(FItem it) async {
    final r = await showDetailSheet(context, it);
    if (!mounted) return;
    if (r == 'delete') {
      setState(() => items.remove(it));
    } else {
      setState(() {});
    }
  }

  Future<void> _meal() async {
    final r = await showFoodSheet<String>(context, (ctx) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Padding(padding: const EdgeInsets.only(bottom: 10), child: Text('کام ژەم؟', textAlign: TextAlign.center, style: ku(17, w: FontWeight.w800))),
          for (final k in kMealOrder)
            Padding(
              padding: const EdgeInsets.only(bottom: 7),
              child: SoftBtn(label: kMealName[k]!, on: k == slot, onTap: () => Navigator.of(ctx).pop(k), key: ValueKey<String>('fa-meal-$k')),
            ),
        ]));
    if (r != null && mounted) setState(() => slot = r);
  }

  Future<void> _add() async {
    final l = await showFoodTextSheet(context);
    if (l == null || l.isEmpty || !mounted) return;
    setState(() {
      for (final x in l) {
        x.png.value = 1;
        items.add(x);
      }
    });
  }

  Future<void> _save() async {
    if (_saving || items.isEmpty) return;
    final u = items.where((x) => !x.sure).toList();
    if (u.isNotEmpty) {
      await _fix(u.first);
      return;
    }
    _saving = true;
    HapticFeedback.mediumImpact();
    await FoodAiStore.I.saveMeal(items, slot);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(foodRoute<void>(FoodDonePage(items: items, slot: slot)));
  }

  Widget _summary() {
    final t = _tot;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: VexTheme.I.isLight ? [op(V.cy, 0.12), V.surf] : const [Color(0xFF16414A), Color(0xFF0F2C33)],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: VexTheme.I.isLight ? op(V.cy, 0.35) : const Color(0xFF2A5761)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text.rich(
            TextSpan(children: [
              const TextSpan(text: 'کۆی ژەمەکە · '),
              TextSpan(text: '${items.length}', style: nu(13, w: FontWeight.w700, c: V.mu)),
              const TextSpan(text: ' خواردن'),
            ]),
            style: ku(13, c: V.mu),
          ),
          const Spacer(),
          CountNum(t.k, key: const ValueKey<String>('fa-total'), style: nu(28, c: V.tx)),
          Padding(padding: const EdgeInsets.only(bottom: 5, right: 4), child: Text('kcal', style: nu(13, w: FontWeight.w600, c: V.mu))),
        ]),
        const SizedBox(height: 10),
        MacroBar(n: t),
        const SizedBox(height: 8),
        MacroLegend(n: t),
      ]),
    );
  }

  Widget _row(int i) {
    final it = items[i];
    final warn = !it.sure;
    return AnimatedContainer(
      key: ObjectKey(it),
      duration: const Duration(milliseconds: 400),
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: warn ? (VexTheme.I.isLight ? const Color(0xFFFFF4E2) : const Color(0xFF2A2312)) : V.surf,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: warn ? kWarn.withAlpha(170) : V.line),
      ),
      child: Row(children: [
        Press(onTap: () => _detail(it), child: ItemThumb(item: it, shot: _shotOf(it))),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Flexible(
                child: GestureDetector(
                  key: ValueKey<String>('fa-name-$i'),
                  onTap: () => _detail(it),
                  child: Text(warn ? (it.guess ?? it.dish.name) : it.dish.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: ku(15, w: FontWeight.w700)),
                ),
              ),
              const SizedBox(width: 6),
              if (warn)
                _WarnChip(key: ValueKey<String>('fa-warn-$i'), onTap: () => _fix(it))
              else
                Container(width: 7, height: 7, decoration: const BoxDecoration(shape: BoxShape.circle, color: kMint)),
            ]),
            const SizedBox(height: 6),
            QtyStepper(word: it.word, dir: _dir[it] ?? 1, idx: i, onMinus: () => _step(it, -1), onPlus: () => _step(it, 1)),
          ]),
        ),
        const SizedBox(width: 6),
        SizedBox(
          width: 58,
          child: Column(children: [
            CountNum(it.nut.k, style: nu(19, c: V.tx)),
            Text('kcal', style: ku(10.5, c: V.mu)),
          ]),
        ),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final u = _unsure;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: V.bg,
        body: SafeArea(
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
              child: Row(children: [
                _IconBtn(FI.back, () => Navigator.of(context).maybePop(), key: const ValueKey<String>('fa-back')),
                Expanded(
                  child: Press(
                    key: const ValueKey<String>('fa-meal'),
                    onTap: _meal,
                    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Flexible(child: Text(kMealName[slot]!, maxLines: 1, style: ku(19, w: FontWeight.w700))),
                      const SizedBox(width: 4),
                      ic(FI.chev, V.mu, size: 16),
                    ]),
                  ),
                ),
                FChip(
                  color: V.mu,
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    ic(FI.clock, V.mu, size: 13),
                    const SizedBox(width: 5),
                    Text(_at, style: nu(12, w: FontWeight.w700, c: V.mu), textDirection: TextDirection.ltr),
                  ]),
                ),
              ]),
            ),
            Expanded(
              child: ListView(padding: const EdgeInsets.fromLTRB(16, 0, 16, 120), children: [
                if (widget.demoReal) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: box(r: 16, color: op(kWarn, 0.10), border: op(kWarn, 0.45)),
                    child: Row(children: [
                      ic(FI.spark, kWarn, size: 18, fill: true),
                      const SizedBox(width: 8),
                      Expanded(child: Text('دۆخی نموونە: AI ـی ڕاستەقینە هێشتا نەبەستراوە، بۆیە وێنەی خۆت وەک «دڵنیا نییە» دێت — خواردنی ڕاست هەڵبژێرە.', style: ku(12, h: 1.5))),
                    ]),
                  ),
                  const SizedBox(height: 10),
                ],
                _summary(),
                const SizedBox(height: 10),
                for (var i = 0; i < items.length; i++) _row(i),
                if (items.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 30),
                    child: Text('هیچ خواردنێک نییە — زیادی بکە', textAlign: TextAlign.center, style: ku(14, c: V.mu)),
                  ),
                const SizedBox(height: 4),
                SoftBtn(label: 'خواردنێکی تر زیاد بکە', icon: FI.plus, onTap: _add, key: const ValueKey<String>('fa-add')),
              ]),
            ),
          ]),
        ),
        bottomNavigationBar: Container(
          padding: EdgeInsets.fromLTRB(16, 10, 16, 16 + MediaQuery.of(context).padding.bottom),
          decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.bottomCenter, end: Alignment.topCenter, colors: [V.bg, V.bg.withAlpha(0)])),
          child: GradBtn(
            key: const ValueKey<String>('fa-save'),
            label: u > 0 ? 'دڵنیاکردنەوە ($u)' : 'تۆمارکردن',
            icon: u > 0 ? FI.edit : FI.check,
            enabled: items.isNotEmpty,
            onTap: _save,
          ),
        ),
      ),
    );
  }
}

class _WarnChip extends StatefulWidget {
  const _WarnChip({super.key, required this.onTap});
  final VoidCallback onTap;
  @override
  State<_WarnChip> createState() => _WarnChipState();
}

class _WarnChipState extends State<_WarnChip> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Press(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, child) {
          final k = math.sin(_c.value * math.pi);
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: kWarn,
              borderRadius: BorderRadius.circular(99),
              boxShadow: [BoxShadow(color: kWarn.withAlpha(((1 - k) * 110).round()), spreadRadius: 7 * k)],
            ),
            child: child,
          );
        },
        child: Text('دڵنیا نییە؟', style: ku(11, w: FontWeight.w800, c: const Color(0xFF2A1A00))),
      ),
    );
  }
}

// ═══════════════════════════════ شیتەکان ═══════════════════════════════

/// ڕاستکردنەوە: FDish (هەڵبژاردن) یان 'retake' یان 'delete'
Future<Object?> showFixSheet(BuildContext context, FItem it) {
  final alts = it.alts.isEmpty ? <FDish>[it.dish] : it.alts;
  String? sel;
  var typing = false;
  var q = '';
  return showFoodSheet<Object>(context, (ctx) {
    return StatefulBuilder(builder: (ctx, set) {
      final found = <FDish>[];
      if (typing && q.trim().isNotEmpty) {
        final sc = <FDish, double>{};
        for (final d in [...FoodAiStore.I.mine, ...kDishes, ...kAltDishes]) {
          final s = matchScore(d, q);
          if (s >= .7) sc[d] = s;
        }
        found.addAll((sc.keys.toList()..sort((a, b) => sc[b]!.compareTo(sc[a]!))).take(4));
      }
      final list = typing ? found : alts;
      Future<void> pick(FDish d) async {
        set(() => sel = d.id);
        HapticFeedback.selectionClick();
        await Future<void>.delayed(const Duration(milliseconds: 380));
        if (ctx.mounted) Navigator.of(ctx).pop(d);
      }

      return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          CheckerBox(radius: 16, child: SizedBox(width: 64, height: 64, child: Center(child: DishPng(it.dish, size: 60)))),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('ئەمە چییە؟', style: ku(18, w: FontWeight.w700)),
              Text(
                it.guess != null ? 'AI ـەکە بە «${it.guess}» ی ناسی بەڵام دڵنیا نییە' : 'خواردنی ڕاست هەڵبژێرە',
                style: ku(11.5, c: V.mu),
              ),
            ]),
          ),
        ]),
        const SizedBox(height: 12),
        if (typing)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: TextField(
              key: const ValueKey<String>('fa-fix-field'),
              autofocus: true,
              onChanged: (v) => set(() => q = v),
              style: ku(15, w: FontWeight.w600),
              cursorColor: V.cy,
              decoration: InputDecoration(
                hintText: 'ناوی خواردنەکە بنووسە…',
                hintStyle: ku(14, c: V.mu),
                filled: true,
                fillColor: V.surf,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: V.line)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: V.line)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: V.cy)),
              ),
            ),
          ),
        if (typing && q.trim().isNotEmpty && found.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Text(FoodAiEngine.live ? 'نەدۆزرایەوە — وێنەی نوێ بگرە تا AI بیناسێتەوە' : 'لە نموونەکاندا نییە — وێنەی نوێ بگرە', textAlign: TextAlign.center, style: ku(12.5, c: V.mu)),
          ),
        for (var i = 0; i < list.length; i++)
          Press(
            key: ValueKey<String>('fa-alt-$i'),
            onTap: () => pick(list[i]),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.only(bottom: 7),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: sel == list[i].id ? op(V.cy, 0.12) : V.surf,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: sel == list[i].id ? V.cy : V.line),
              ),
              child: Row(children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: sel == list[i].id ? V.cy : V.line2, width: sel == list[i].id ? 6 : 2)),
                ),
                const SizedBox(width: 10),
                DishPng(list[i], size: 36),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(list[i].name, style: ku(14.5, w: FontWeight.w700)),
                    Text(list[i].ing, maxLines: 1, overflow: TextOverflow.ellipsis, style: ku(11, c: V.mu)),
                  ]),
                ),
                const SizedBox(width: 6),
                Text.rich(
                  TextSpan(children: [
                    TextSpan(text: '${list[i].nut(list[i].u0, list[i].q0).k.round()}', style: nu(14, c: V.tx)),
                    TextSpan(text: ' kcal', style: ku(10.5, c: V.mu)),
                  ]),
                  textDirection: TextDirection.ltr,
                ),
              ]),
            ),
          ),
        const SizedBox(height: 4),
        Row(children: [
          Expanded(child: SoftBtn(key: const ValueKey<String>('fa-fix-type'), label: 'بنووسە', icon: FI.edit, on: typing, onTap: () => set(() => typing = !typing))),
          const SizedBox(width: 7),
          Expanded(child: SoftBtn(label: 'وێنەی نوێ', icon: FI.cam, onTap: () => Navigator.of(ctx).pop('retake'))),
          const SizedBox(width: 7),
          Expanded(child: SoftBtn(key: const ValueKey<String>('fa-fix-del'), label: 'سڕینەوە', icon: FI.trash, color: kFat, onTap: () => Navigator.of(ctx).pop('delete'))),
        ]),
      ]);
    });
  });
}

const List<List<Object>> _kPies = [
  [0.25, 'چارەک'],
  [0.5, 'نیو'],
  [1.0, 'یەک'],
  [1.5, 'یەک و نیو'],
  [2.0, 'دوو'],
];

/// وردەکاری: یەکە، بڕ و هەموو خۆراکەکان. 'delete' یان null
Future<Object?> showDetailSheet(BuildContext context, FItem it) {
  var unit = it.unit;
  var q = it.q;
  var dir = 1;
  var saved = FoodAiStore.I.isMine('${it.dish.name}ی ماڵەوە') || it.dish.id.startsWith('mine_');
  return showFoodSheet<Object>(context, (ctx) {
    return StatefulBuilder(builder: (ctx, set) {
      final d = it.dish;
      final u = unitOf(unit);
      final n = d.nut(unit, q);
      void apply() {
        it.unit = unit;
        it.q = q;
      }

      void setUnit(String nu0) {
        if (nu0 == unit) return;
        final g = d.grams(unit, q);
        final nu1 = unitOf(nu0);
        final per = d.units[nu0] ?? 1;
        final raw = g / per;
        var best = nu1.steps.first;
        for (final s in nu1.steps) {
          if ((s - raw).abs() < (best - raw).abs()) best = s;
        }
        set(() {
          unit = nu0;
          q = best;
        });
      }

      void stepQ(int k) {
        final tmp = FItem(dish: d, unit: unit, q: q);
        if (tmp.step(k)) set(() {
          q = tmp.q;
          dir = k;
        });
      }

      Widget nut(String v, String l, [Color? c]) => Container(
            padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 4),
            decoration: box(r: 13, color: V.surf),
            child: Column(children: [
              FittedBox(fit: BoxFit.scaleDown, child: Text(v, style: nu(15, c: c ?? V.tx), textDirection: TextDirection.ltr)),
              Text(l, maxLines: 1, style: ku(10.5, c: V.mu)),
            ]),
          );
      final gTxt = '${d.grams(unit, q).round()} ${d.liquid ? 'ml' : 'g'}';
      final mineName = d.id.startsWith('mine_') ? d.name : '${d.name}ی ماڵەوە';

      return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Stack(children: [
            CheckerBox(radius: 20, cell: 7, child: SizedBox(width: 96, height: 96, child: Center(child: DishPng(d, size: 90)))),
            Positioned(
              bottom: 4,
              left: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: kInk, borderRadius: BorderRadius.circular(6)),
                child: Text('PNG', style: nu(9, c: kCy)),
              ),
            ),
          ]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(d.name, style: ku(21, w: FontWeight.w700)),
              Text(d.ing, style: ku(11.5, c: V.mu, h: 1.5)),
              const SizedBox(height: 7),
              Wrap(spacing: 6, runSpacing: 6, children: [
                FChip(
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    ic(FI.spark, V.cy, size: 11, fill: true),
                    const SizedBox(width: 4),
                    Text('AI ${(it.conf * 100).round()}%', style: nu(11, w: FontWeight.w700, c: V.cy), textDirection: TextDirection.ltr),
                  ]),
                ),
                if (d.id.startsWith('mine_')) FChip(color: V.mint, child: Text('خواردنی تۆ', style: ku(11, w: FontWeight.w700, c: V.mint))),
              ]),
            ]),
          ),
          Press(
            key: const ValueKey<String>('fa-det-del'),
            onTap: () => Navigator.of(ctx).pop('delete'),
            child: Padding(padding: const EdgeInsets.all(6), child: ic(FI.trash, kFat, size: 20)),
          ),
        ]),
        Padding(padding: const EdgeInsets.fromLTRB(4, 14, 4, 6), child: Text('یەکە', style: ku(11.5, c: V.mu))),
        Container(
          padding: const EdgeInsets.all(3),
          decoration: box(r: 14, color: VexTheme.I.isLight ? V.surf2 : const Color(0xFF0B2329)),
          child: Row(children: [
            for (final k in d.units.keys)
              Expanded(
                child: Press(
                  key: ValueKey<String>('fa-unit-$k'),
                  onTap: () => setUnit(k),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(color: k == unit ? (VexTheme.I.isLight ? V.surf : const Color(0xFF1C4F59)) : Colors.transparent, borderRadius: BorderRadius.circular(11)),
                    child: Text(unitOf(k).word, textAlign: TextAlign.center, style: ku(13, w: FontWeight.w700, c: k == unit ? V.tx : V.mu)),
                  ),
                ),
              ),
          ]),
        ),
        Padding(padding: const EdgeInsets.fromLTRB(4, 12, 4, 6), child: Text('بڕ', style: ku(11.5, c: V.mu))),
        if (!u.grams)
          Row(children: [
            for (var i = 0; i < _kPies.length; i++) ...[
              if (i > 0) const SizedBox(width: 6),
              Expanded(
                child: Press(
                  key: ValueKey<String>('fa-pie-$i'),
                  onTap: () => set(() {
                    dir = (_kPies[i][0] as double) >= q ? 1 : -1;
                    q = _kPies[i][0] as double;
                  }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    transform: Matrix4.translationValues(0, (q - (_kPies[i][0] as double)).abs() < 1e-6 ? -3 : 0, 0),
                    padding: const EdgeInsets.fromLTRB(2, 8, 2, 6),
                    decoration: BoxDecoration(
                      gradient: (q - (_kPies[i][0] as double)).abs() < 1e-6
                          ? LinearGradient(begin: Alignment.topRight, end: Alignment.bottomLeft, colors: VexTheme.I.isLight ? [op(V.cy, 0.22), op(V.cy, 0.10)] : const [Color(0xFF1E5F69), Color(0xFF14444C)])
                          : null,
                      color: (q - (_kPies[i][0] as double)).abs() < 1e-6 ? null : (VexTheme.I.isLight ? V.surf2 : const Color(0xFF0B2329)),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: (q - (_kPies[i][0] as double)).abs() < 1e-6 ? V.cy : V.line),
                    ),
                    child: Column(children: [
                      PortionPie(_kPies[i][0] as double, on: (q - (_kPies[i][0] as double)).abs() < 1e-6),
                      const SizedBox(height: 3),
                      FittedBox(fit: BoxFit.scaleDown, child: Text(_kPies[i][1] as String, style: ku(12, w: FontWeight.w700))),
                    ]),
                  ),
                ),
              ),
            ],
          ]),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(
            child: Text.rich(
              TextSpan(children: [
                TextSpan(text: qtyWord(q, unit)),
                const TextSpan(text: ' · '),
                TextSpan(text: ltr(gTxt), style: nu(12, w: FontWeight.w600, c: V.mu)),
              ]),
              style: ku(12.5, w: FontWeight.w600, c: V.mu),
            ),
          ),
          QtyStepper(word: qtyWord(q, unit), dir: dir, idx: 99, onMinus: () => stepQ(-1), onPlus: () => stepQ(1)),
        ]),
        const SizedBox(height: 10),
        GridView.count(
          crossAxisCount: 4,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 6,
          crossAxisSpacing: 6,
          childAspectRatio: 1.45,
          children: [
            nut('${n.k.round()}', 'kcal'),
            nut('${g0(n.p)}g', 'پرۆتین', kPro),
            nut('${g0(n.c)}g', 'کاربۆهیدرات', kCarb),
            nut('${g0(n.f)}g', 'چەوری', kFat),
            nut('${g0(n.sug)}g', 'شەکر'),
            nut('${g0(n.fib)}g', 'فایبەر'),
            nut('${n.salt.toStringAsFixed(1)}g', 'خوێ'),
            nut('${n.chol.round()}mg', 'کۆلیسترۆڵ'),
          ],
        ),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(
            child: SoftBtn(
              key: const ValueKey<String>('fa-mine'),
              label: saved ? '«$mineName» پاشەکەوت کراوە' : 'پاشەکەوت وەک «$mineName»',
              icon: saved ? FI.check : FI.save,
              on: saved,
              onTap: saved
                  ? null
                  : () async {
                      apply();
                      await FoodAiStore.I.saveMine(it);
                      HapticFeedback.mediumImpact();
                      set(() => saved = true);
                    },
            ),
          ),
          const SizedBox(width: 8),
          GradBtn(
            key: const ValueKey<String>('fa-ok'),
            label: 'باشە',
            pad: const EdgeInsets.symmetric(horizontal: 26, vertical: 12),
            size: 15,
            onTap: () {
              apply();
              Navigator.of(ctx).pop('ok');
            },
          ),
        ]),
      ]);
    });
  });
}

/// نووسین: «دوو شیش کەباب و قاپێک برنج»
Future<List<FItem>?> showFoodTextSheet(BuildContext context) {
  var text = '';
  var busy = false;
  String? err;
  return showFoodSheet<List<FItem>>(context, (ctx) {
    return StatefulBuilder(builder: (ctx, set) {
      final l = FoodAiEngine.parseLocal(text, FoodAiStore.I.mine);
      Future<void> go() async {
        if (l.isNotEmpty) {
          Navigator.of(ctx).pop(l);
          return;
        }
        if (!FoodAiEngine.live || text.trim().isEmpty) return;
        set(() {
          busy = true;
          err = null;
        });
        try {
          final r = await FoodAiEngine.text(text.trim());
          if (ctx.mounted) Navigator.of(ctx).pop(r);
        } on ScanFail catch (e) {
          set(() {
            busy = false;
            err = e.message;
          });
        } catch (_) {
          set(() => busy = false);
        }
      }

      return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text('چیت خوارد؟', textAlign: TextAlign.center, style: ku(18, w: FontWeight.w800)),
        const SizedBox(height: 4),
        Text('بە وشەی ئاسایی بینووسە، بڕەکەش', textAlign: TextAlign.center, style: ku(12, c: V.mu)),
        const SizedBox(height: 12),
        TextField(
          key: const ValueKey<String>('fa-text-field'),
          autofocus: true,
          minLines: 1,
          maxLines: 3,
          onChanged: (v) => set(() => text = v),
          onSubmitted: (_) => go(),
          style: ku(15, w: FontWeight.w600),
          cursorColor: V.cy,
          decoration: InputDecoration(
            hintText: 'وەک: دوو شیش کەباب و قاپێک برنج و چا',
            hintStyle: ku(13.5, c: V.mu),
            filled: true,
            fillColor: V.surf,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: V.line)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: V.line)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: V.cy)),
          ),
        ),
        const SizedBox(height: 10),
        for (final it in l)
          Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: box(r: 14, color: V.surf),
            child: Row(children: [
              DishPng(it.dish, size: 34),
              const SizedBox(width: 8),
              Text(it.dish.name, style: ku(14, w: FontWeight.w700)),
              const SizedBox(width: 6),
              Text(it.word, style: ku(12, c: V.mu)),
              const Spacer(),
              Text('${it.nut.k.round()} kcal', style: nu(12.5, w: FontWeight.w700), textDirection: TextDirection.ltr),
            ]),
          ),
        if (text.trim().length > 1 && l.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Text(
              err ?? (FoodAiEngine.live ? 'AI دەیناسێتەوە — «زیادکردن» دابگرە' : 'ئەم خواردنە لە نموونەکاندا نییە — وێنەی بگرە'),
              textAlign: TextAlign.center,
              style: ku(12.5, c: err != null ? kFat : V.mu),
            ),
          ),
        const SizedBox(height: 6),
        GradBtn(
          key: const ValueKey<String>('fa-text-go'),
          label: busy ? 'AI شیکاری دەکات…' : (l.isEmpty ? 'زیادکردن' : 'زیادکردن (${l.length})'),
          icon: FI.plus,
          enabled: !busy && (l.isNotEmpty || (FoodAiEngine.live && text.trim().length > 1)),
          onTap: go,
        ),
      ]);
    });
  });
}

// ═══════════════════════════════ 4 · تۆمارکرا ═══════════════════════════════

class FoodDonePage extends StatefulWidget {
  const FoodDonePage({super.key, required this.items, required this.slot});
  final List<FItem> items;
  final String slot;

  @override
  State<FoodDonePage> createState() => _FoodDonePageState();
}

class _FoodDonePageState extends State<FoodDonePage> {
  bool _in = false;
  bool _toast = false;
  bool _conf = false;

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => _in = true);
    });
    Future<void>.delayed(const Duration(milliseconds: 900), () {
      if (mounted) setState(() => _conf = true);
    });
    Future<void>.delayed(const Duration(milliseconds: 1800), () {
      if (mounted) setState(() => _toast = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final its = widget.items;
    final meal = its.fold(FNut.zero, (a, x) => a + x.nut);
    final t = Store.I.totals();
    final goal = Store.I.h.goal.toDouble();
    const pos = [
      [0.5, 0.42, 0.62, 0.0, -0.5],
      [0.16, 0.66, 0.40, 0.15, 0.2],
      [0.84, 0.62, 0.40, 0.30, -0.3],
      [0.26, 0.16, 0.34, 0.45, 0.4],
      [0.76, 0.17, 0.34, 0.60, -0.2],
    ];
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: V.bg,
        body: SafeArea(
          child: Stack(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Row(children: [
                  _IconBtn(FI.back, () => Navigator.of(context).maybePop()),
                  Expanded(child: Text('ئەمڕۆ', textAlign: TextAlign.center, style: ku(19, w: FontWeight.w700))),
                  const SizedBox(width: 44),
                ]),
                SizedBox(
                  height: 290,
                  child: LayoutBuilder(builder: (context, c) {
                    final w = c.maxWidth, h = c.maxHeight;
                    return Stack(clipBehavior: Clip.none, children: [
                      Center(
                        child: Container(
                          width: w * .9,
                          height: h * .9,
                          decoration: const BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [Color(0x332FE6F3), Color(0x002FE6F3)], stops: [0, .62])),
                        ),
                      ),
                      for (var i = 0; i < its.length && i < pos.length; i++)
                        Positioned(
                          left: w * pos[i][0] - h * pos[i][2] / 2,
                          top: h * pos[i][1] - h * pos[i][2] / 2,
                          child: AnimatedScale(
                            scale: _in ? 1 : 0.3,
                            duration: Duration(milliseconds: 700 + (pos[i][3] * 1000).round()),
                            curve: kSpring,
                            child: AnimatedOpacity(
                              opacity: _in ? 1 : 0,
                              duration: Duration(milliseconds: 400 + (pos[i][3] * 1000).round()),
                              child: AnimatedRotation(
                                turns: _in ? 0 : pos[i][4] / 6.28,
                                duration: const Duration(milliseconds: 800),
                                curve: kEase,
                                child: Container(
                                  decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withAlpha(90), blurRadius: 22, offset: const Offset(0, 12))]),
                                  child: DishPng(its[i].dish, size: h * pos[i][2]),
                                ),
                              ),
                            ),
                          ),
                        ),
                      if (_conf) const Positioned.fill(child: Confetti()),
                    ]);
                  }),
                ),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: box(r: 22, color: V.surf),
                  child: Row(children: [
                    KcalRing(v: t.kcal.toDouble(), goal: goal),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(children: [
                        _bar('پرۆتین', t.p.toDouble(), goal * .25 / 4, kPro, 0),
                        _bar('کاربۆهیدرات', t.c.toDouble(), goal * .45 / 4, kCarb, 1),
                        _bar('چەوری', t.f.toDouble(), goal * .30 / 9, kFat, 2),
                      ]),
                    ),
                  ]),
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: GradBtn(key: const ValueKey<String>('fa-finish'), label: 'تەواو', icon: FI.check, onTap: () => Navigator.of(context).maybePop()),
                ),
              ]),
            ),
            AnimatedPositioned(
              duration: const Duration(milliseconds: 600),
              curve: kSpring,
              left: 16,
              right: 16,
              bottom: _toast ? 84 : -120,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: VexTheme.I.isLight ? V.surf : const Color(0xFF123B44),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: kCy.withAlpha(100)),
                  boxShadow: const [BoxShadow(color: Color(0x44000000), blurRadius: 20, offset: Offset(0, 8))],
                ),
                child: Row(children: [
                  Container(width: 30, height: 30, alignment: Alignment.center, decoration: const BoxDecoration(shape: BoxShape.circle, color: kMint), child: ic(FI.check, kInk, size: 18, stroke: 3)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('${kMealName[widget.slot]} تۆمارکرا', style: ku(14, w: FontWeight.w700)),
                      Text.rich(
                        TextSpan(children: [
                          TextSpan(text: '${its.length}', style: nu(11.5, w: FontWeight.w700, c: V.mu)),
                          const TextSpan(text: ' خواردن · '),
                          TextSpan(text: fmt(meal.k), style: nu(11.5, w: FontWeight.w700, c: V.mu)),
                          const TextSpan(text: ' kcal زیادکرا بۆ ئەمڕۆ'),
                        ]),
                        style: ku(11.5, c: V.mu),
                      ),
                    ]),
                  ),
                ]),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _bar(String l, double v, double goal, Color c, int i) {
    return Padding(
      padding: EdgeInsets.only(top: i == 0 ? 0 : 9),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Text(l, style: ku(12)),
          const Spacer(),
          Text('${v.round()} / ${goal.round()}g', style: nu(11.5, w: FontWeight.w600, c: V.mu), textDirection: TextDirection.ltr),
        ]),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(7),
          child: SizedBox(
            height: 7,
            child: Stack(children: [
              Positioned.fill(child: ColoredBox(color: V.track)),
              TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: _in && goal > 0 ? (v / goal).clamp(0.0, 1.0).toDouble() : 0.0),
                duration: const Duration(milliseconds: 1200),
                curve: kEase,
                builder: (context, f, _) => FractionallySizedBox(
                  alignment: AlignmentDirectional.centerStart,
                  widthFactor: f,
                  child: Container(decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(7))),
                ),
              ),
            ]),
          ),
        ),
      ]),
    );
  }
}
