// VEX Health — سکانی خواردن: کامێرا ← شیکاری ← ئەنجام ← زیادکردن
//
// openFoodScan()   ← کامێرای سەرەکی (پشتەوە) دەکاتەوە، وێنە دەگرێت و شیکاری دەکات
// openFoodText()   ← خواردنی نووسراو شیکاری دەکات
// recoverLostScan()← ئەگەر Android لە کاتی کامێرادا ئەپەکەی داخست، وێنەکە دەگەڕێنێتەوە
import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../core/store.dart';
import '../core/theme.dart';
import '../food/food_db.dart';
import '../food/food_page.dart';
import '../onboarding/account.dart';
import '../onboarding/reg_data.dart' show asD, asI, kThisYear;
import 'scan_ai.dart';
import 'scan_model.dart';
import 'scan_widgets.dart';
import '../plus/gate.dart';

final ImagePicker _picker = ImagePicker();
bool _picking = false;
bool _pageOpen = false;

/// کامێرا (یان گەلەری) دەکاتەوە و وێنەکە شیکاری دەکات
Future<void> openFoodScan({ImageSource source = ImageSource.camera, String? slot}) async {
  if (_picking) return;
  _picking = true;
  try {
    final x = await _picker.pickImage(
      source: source,
      maxWidth: 1600,
      maxHeight: 1600,
      imageQuality: 85,
      preferredCameraDevice: CameraDevice.rear,
      requestFullMetadata: false,
    );
    if (x == null) return; // بەکارهێنەر پاشگەز بووەوە
    final bytes = await x.readAsBytes();
    if (bytes.isEmpty) {
      toast('⚠️ وێنەکە نەخوێنرایەوە. دووبارە هەوڵ بدەرەوە.');
      return;
    }
    _pushScan(image: bytes, slot: slot);
  } on PlatformException catch (e) {
    final c = e.code.toLowerCase();
    if (c.contains('no_available_camera')) {
      toast('📷 کامێرا لەم مۆبایلەدا نەدۆزرایەوە');
    } else if (c.contains('denied') || c.contains('access') || c.contains('permission')) {
      toast(source == ImageSource.camera
          ? '📷 ڕێگە بە کامێرا بدە لە ڕێکخستنەکانی مۆبایلەکەت'
          : '🖼️ ڕێگە بە وێنەکان بدە لە ڕێکخستنەکانی مۆبایلەکەت');
    } else {
      toast('⚠️ کامێرا نەکرایەوە. دووبارە هەوڵ بدەرەوە.');
    }
  } catch (_) {
    toast('⚠️ کامێرا نەکرایەوە. دووبارە هەوڵ بدەرەوە.');
  } finally {
    _picking = false;
  }
}

/// خواردنی نووسراو، وەک: «2 هێلکە و نانێک و چا»
void openFoodText(String text, {String? slot}) {
  final t = text.trim();
  if (t.isEmpty) return;
  _pushScan(text: t, slot: slot);
}

/// وێنەیەکی ئامادە (بۆ نموونە لە شوێنێکی ترەوە)
void openFoodImage(Uint8List bytes, {String? slot}) {
  if (bytes.isEmpty) return;
  _pushScan(image: bytes, slot: slot);
}

void _pushScan({Uint8List? image, String? text, String? slot}) {
  final nav = navKey.currentState;
  if (nav == null || _pageOpen) return;
  if (!ScanQuota.take()) return; // پلانی خۆڕایی: 3 سکان لە ڕۆژێکدا
  nav.push(
    PageRouteBuilder<void>(
      transitionDuration: const Duration(milliseconds: 320),
      reverseTransitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (context, a, b) => ScanPage(image: image, text: text, slot: slot),
      transitionsBuilder: (context, a, b, child) {
        final c = CurvedAnimation(parent: a, curve: Curves.easeOutCubic);
        return FadeTransition(
          opacity: c,
          child: SlideTransition(
            position: Tween<Offset>(begin: const Offset(0, 0.03), end: Offset.zero).animate(c),
            child: child,
          ),
        );
      },
    ),
  );
}

/// Android: ئەگەر سیستەم لە کاتی وێنەگرتندا ئەپەکەی داخستبێت، وێنەکە دەگەڕێتەوە
Future<void> recoverLostScan() async {
  if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
  try {
    final res = await _picker.retrieveLostData();
    if (res.isEmpty) return;
    final f = res.file ?? ((res.files?.isNotEmpty ?? false) ? res.files!.last : null);
    if (f == null) return;
    final b = await f.readAsBytes();
    if (b.isNotEmpty) _pushScan(image: b);
  } catch (_) {}
}

String _digits(String s) {
  var t = s.replaceAllMapped(RegExp('[٠-٩]'), (m) => '${m[0]!.codeUnitAt(0) - 0x0660}');
  t = t.replaceAllMapped(RegExp('[۰-۹]'), (m) => '${m[0]!.codeUnitAt(0) - 0x06F0}');
  return t.replaceAll(RegExp('[٫،,]'), '.');
}

String _verdOf(int s) => s >= 70 ? 'good' : (s >= 45 ? 'ok' : 'bad');

// =====================================================================
//  پەڕەی سکان
// =====================================================================
class ScanPage extends StatefulWidget {
  const ScanPage({super.key, this.image, this.text, this.slot});
  final Uint8List? image;
  final String? text;
  final String? slot;

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> with TickerProviderStateMixin {
  static const List<String> _steps = [
    'ناسینەوەی خواردن و خواردنەوەکان',
    'خەمڵاندنی بڕ و قەبارە',
    'ژماردنی کالۆری و پێکهاتە',
    'بەراورد لەگەڵ ڕۆژەکەت',
  ];

  late final AnimationController _scan = AnimationController(vsync: this, duration: const Duration(milliseconds: 2100));
  late final AnimationController _prog = AnimationController(vsync: this, duration: const Duration(seconds: 7));

  String _phase = 'scan'; // scan | res | fail | nf
  ScanResult? _r;
  ScanFail? _fail;
  bool _recalcBusy = false;
  bool _adding = false;
  int _gen = 0;
  int _step = 0;
  Timer? _stepT;
  String? _slot; // ژەمی هەڵبژێردراو بە دەست (null = خۆکار)
  String? _text;
  late final TextEditingController _retry = TextEditingController(text: widget.text ?? '');

  ImageProvider? _photo;
  late ScanCtx _ctx;
  late double _budget, _eaten, _w, _pro, _carb, _fat, _kpm;

  @override
  void initState() {
    super.initState();
    _pageOpen = true;
    _text = widget.text;
    _slot = widget.slot;
    if (widget.image != null) _photo = MemoryImage(widget.image!);
    _readUser();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _start();
    });
  }

  @override
  void dispose() {
    _pageOpen = false;
    _gen++;
    _stepT?.cancel();
    _scan.dispose();
    _prog.dispose();
    _retry.dispose();
    super.dispose();
  }

  /// زانیاری کەسەکە و ڕۆژەکەی
  void _readUser() {
    final s = Store.I;
    final u = Account.I.user ?? const <String, dynamic>{};
    int age = asI(u['age']);
    if (age <= 0) {
      final y = asI(u['year']);
      age = y > 0 ? kThisYear - y : 30;
    }
    final w0 = asD(u['w']);
    _w = w0 >= 25 ? w0 : s.h.weightKg.toDouble();
    final goal = s.h.goal.toDouble();
    _budget = math.max(1200, s.budget).toDouble();
    _eaten = s.totals().kcal.toDouble();
    _pro = _w * 1.6;
    _fat = goal * 0.28 / 9;
    _carb = math.max(50.0, (goal - _pro * 4 - _fat * 9) / 4);
    _kpm = 3.5 * 3.5 * _w / 200; // کالۆری لە خولەکێک پیاسەدا
    final now = mealSlotNow();
    _ctx = ScanCtx(
      female: u['sex'] == 'f',
      age: age,
      weight: _w,
      height: s.h.heightCm.toDouble(),
      goal: s.h.goal,
      eaten: s.totals().kcal,
      left: s.left,
      time: nowHM(),
      slotName: kSlotName[now] ?? '',
    );
  }

  // ---------------------------------------------------------------- شیکاری
  Future<void> _start() async {
    final g = ++_gen;
    _stepT?.cancel();
    setState(() {
      _phase = 'scan';
      _fail = null;
      _step = 0;
    });
    _scan.repeat();
    _prog.value = 0;
    _prog.animateTo(0.92, duration: const Duration(seconds: 7), curve: Curves.easeOutCubic);
    _stepT = Timer.periodic(const Duration(milliseconds: 750), (_) {
      if (mounted && _step < _steps.length - 1) setState(() => _step++);
    });
    final sw = Stopwatch()..start();
    ScanResult? r;
    ScanFail? f;
    try {
      r = await FoodAI.analyze(image: widget.image, text: _text, ctx: _ctx);
    } on ScanFail catch (e) {
      f = e;
    } catch (_) {
      f = ScanFail('server');
    }
    final rest = 1600 - sw.elapsedMilliseconds;
    if (rest > 0) await Future<void>.delayed(Duration(milliseconds: rest));
    if (!mounted || g != _gen) return;
    _stepT?.cancel();
    if (f != null || r == null) {
      _scan.stop();
      HapticFeedback.heavyImpact();
      setState(() {
        _phase = 'fail';
        _fail = f ?? ScanFail('server');
      });
      return;
    }
    if (!r.isFood) {
      _scan.stop();
      HapticFeedback.heavyImpact();
      setState(() {
        _phase = 'nf';
        _r = r;
      });
      return;
    }
    setState(() => _step = _steps.length);
    await _prog.animateTo(1, duration: const Duration(milliseconds: 260));
    if (!mounted || g != _gen) return;
    _scan.stop();
    HapticFeedback.mediumImpact();
    setState(() {
      _r = r;
      _phase = 'res';
    });
  }

  void _showDemo() {
    _gen++;
    _stepT?.cancel();
    _scan.stop();
    setState(() {
      _r = ScanResult.fromJson(demoPizza());
      _phase = 'res';
    });
  }

  void _again() {
    Navigator.of(context).pop();
    Future<void>.delayed(const Duration(milliseconds: 260), () => openFoodScan(slot: widget.slot));
  }

  // ---------------------------------------------------------------- دەستکاری
  void _stepQty(int i, int d) {
    final r = _r;
    if (r == null || i >= r.items.length) return;
    setState(() => r.items[i].n = stepQ(r.items[i], d));
  }

  void _setQty(int i, double v) {
    final r = _r;
    if (r == null || i >= r.items.length) return;
    setState(() => r.items[i].n = v.clamp(0.0, 50.0));
  }

  bool _push(ScanItem it, {double sug = 0, double fib = 0, int dScore = 0, bool addCount = false}) {
    final r = _r;
    if (r == null) return false;
    final ex = r.items.indexWhere((x) => x.name == it.name && x.unit == it.unit);
    if (ex >= 0) {
      final x = r.items[ex];
      setState(() => x.n = addCount ? (x.n + it.c0).clamp(0.0, 50.0) : stepQ(x, 1));
      return true;
    }
    if (r.items.length >= 6) {
      toast('زۆرترین 6 خواردن لە یەک ژەمدا');
      return false;
    }
    setState(() {
      r.items.add(it);
      r.base?.add(it.copy());
      r.fib += fib;
      r.sug += sug;
      if (r.sug0 != null) r.sug0 = r.sug0! + sug;
      if (dScore != 0) {
        r.score = (r.score + dScore).clamp(5, 96);
        if (r.score0 != null) r.score0 = (r.score0! + dScore).clamp(5, 96);
        r.verdict = _verdOf(r.score);
      }
      if (r.mealType == 'snack' && r.totals.k >= 250) r.mealType = 'meal';
    });
    return true;
  }

  void _addOn(AddOn a) {
    final ok = _push(
      ScanItem(name: a.t, e: a.e, unit: a.u, c0: 1, grams: a.g, kcal: a.k, p: a.p, c: a.c, f: a.f),
      sug: a.sug,
      fib: a.fib,
      dScore: a.bad ? -8 : (a.good ? 3 : 0),
    );
    if (ok) {
      HapticFeedback.selectionClick();
      toast('✓ ${a.e} ${a.t} زیادکرا بۆ ئەم ژەمە');
    }
  }

  /// «✍️ شتێکی تر»: ناو + کالۆری (ئەگەر خواردنێکی ناسراو بێت، کالۆری پێویست نییە)
  String? _custom(String name, String kcal) {
    final nm = name.length > 40 ? name.substring(0, 40) : name;
    final kv = double.tryParse(_digits(kcal).replaceAll(RegExp(r'[^\d.]'), ''));
    // ئەگەر لە لیستی خواردنەکاندا هەبێت و کالۆری نەنووسرابێت، ژمارەکانی لیستەکە بەکاردێن
    final k = FoodDb.I.best(nm);
    if (k != null && (kv == null || kv <= 0)) {
      final ok = _pushFood(k, k.unit0, 1);
      return ok ? null : 'زۆرترین 6 خواردن لە یەک ژەمدا';
    }
    if (kv == null || kv <= 0) {
      if (FoodAI.connected) {
        _recalc('هەروەها ${nm}م لەگەڵی خوارد', added: nm);
        return null;
      }
      return 'کالۆرییەکەی بنووسە (بۆ نموونە 150)';
    }
    final kc = kv.clamp(1.0, 5000.0);
    final e = ingEmoji(nm);
    final ok = _push(ScanItem(
      name: nm,
      e: e != '•' ? e : '🍽️',
      unit: 'بەش',
      c0: 1,
      kcal: kc,
      p: kc * 0.15 / 4,
      c: kc * 0.5 / 4,
      f: kc * 0.35 / 9,
    ));
    if (ok) toast('✓ $nm زیادکرا بۆ ئەم ژەمە');
    return ok ? null : 'زۆرترین 6 خواردن لە یەک ژەمدا';
  }

  /// خواردنێک لە لیستی 500 خواردنەکە
  bool _pushFood(FoodEntry f, FoodUnit u, double n) {
    final it = scanItemOf(f, u, n);
    final g = f.gramsOf(u, n);
    final v = f.verdictFor(it.kcal);
    final ok = _push(
      it,
      sug: f.sug * g / 100,
      fib: f.fib * g / 100,
      dScore: v == 'bad' ? -6 : (v == 'good' ? 3 : 0),
      addCount: true,
    );
    if (ok) {
      HapticFeedback.selectionClick();
      toast('✓ ${f.e} ${f.label} زیادکرا بۆ ئەم ژەمە');
    }
    return ok;
  }

  /// «🔎 خواردنی تر» ← لیستی خواردنەکان
  Future<void> _more() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final pk = await openFoodPage(pick: true);
    if (!mounted || pk == null || _r == null) return;
    final f = pk.food, u = pk.unit;
    if (f != null && u != null) {
      _pushFood(f, u, pk.n);
    } else if (pk.kcal > 0 && pk.name.isNotEmpty) {
      _custom(pk.name, '${pk.kcal.round()}');
    }
  }

  /// تێبینی: بە AI (ئەگەر بەسترابێت) یان بە بێ ئینتەرنێت
  Future<void> _recalc(String note, {String? added}) async {
    final r = _r;
    if (r == null || _recalcBusy) return;
    if (FoodAI.connected) {
      setState(() => _recalcBusy = true);
      try {
        final x = await FoodAI.recalc(r, note, _ctx);
        if (!mounted || x == null) return;
        x.note = added == null ? note : r.note;
        x.noteOk = added == null || r.noteOk;
        x.demo = r.demo;
        setState(() => _r = x);
        HapticFeedback.mediumImpact();
        toast(added == null ? '✓ بە پێی تێبینییەکەت حیساب کرایەوە' : '✓ $added زیادکرا بۆ ئەم ژەمە');
      } on ScanFail catch (e) {
        toast(e.message);
      } catch (_) {
        toast(ScanFail('server').message);
      } finally {
        if (mounted) setState(() => _recalcBusy = false);
      }
      return;
    }
    final ok = applyLocalNote(r, note);
    if (ok) {
      r.verdict = _verdOf(r.score);
      setState(() {});
      HapticFeedback.mediumImpact();
      toast('✓ بە پێی تێبینییەکەت حیساب کرایەوە');
    } else {
      toast('تێبینییەکەم تێنەگەیشت. بە کورتی بینووسە، وەک: بێ پەنیر، ڕۆنی کەم، 3 پارچە');
    }
  }

  // ---------------------------------------------------------------- زیادکردن
  String _slotOf(ScanResult r) => _slot ?? autoSlot(r);

  void _add() {
    final r = _r;
    if (r == null || _adding) return;
    final t = r.totals;
    if (t.k <= 0 && t.act == 0) {
      toast('بڕی خواردنەکە سفرە');
      return;
    }
    _adding = true;
    FocusManager.instance.primaryFocus?.unfocus();
    final live = liveScore(r, _budget, _eaten);
    final slot = _slotOf(r);
    final nm = r.mealName;
    Store.I.addFood(FoodItem(
      n: nm,
      kcal: t.k.round(),
      p: t.p.round(),
      c: t.c.round(),
      f: t.f.round(),
      at: nowHM(),
      v: live.v,
      e: r.emoji,
      slot: slot,
    ));
    HapticFeedback.mediumImpact();
    Navigator.of(context).pop();
    final short = nm.length > 28 ? '${nm.substring(0, 27)}…' : nm;
    toast('✓ $short بە سەرکەوتوویی زیاد کرا بۆ ${kSlotName[slot] ?? 'ژەم'}');
  }

  void _pickSlot() {
    final r = _r;
    if (r == null) return;
    final cur = _slotOf(r);
    const icons = {'b': '🌅', 'l': '☀️', 's': '🍎', 'd': '🌙', 'n': '🌃'};
    showVSheet<void>(
      builder: (c) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SheetTitle('بۆ کام ژەم زیادی بکەم؟'),
          const SizedBox(height: 6),
          for (final e in kSlotName.entries)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Press(
                onTap: () {
                  Navigator.of(c).pop();
                  HapticFeedback.selectionClick();
                  setState(() => _slot = e.key);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: e.key == cur ? const Color(0x1F2FE6F3) : V.surf2,
                    border: Border.all(color: e.key == cur ? V.cy : V.line),
                  ),
                  child: Row(
                    children: [
                      VText(icons[e.key] ?? '🍽️', style: const TextStyle(fontSize: 20)),
                      const SizedBox(width: 10),
                      Expanded(child: VText(e.value, style: ku(15, w: FontWeight.w800))),
                      if (e.key == cur) Icon(Icons.check_rounded, color: V.cy, size: 22),
                    ],
                  ),
                ),
              ),
            ),
          if (_slot != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: VBtn('⏰ خۆکار (بە پێی کاتژمێر)', onTap: () {
                Navigator.of(c).pop();
                setState(() => _slot = null);
              }),
            ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------- ڕووکار
  @override
  Widget build(BuildContext context) {
    final Widget body;
    switch (_phase) {
      case 'res':
        body = _result();
        break;
      case 'fail':
        body = _failView();
        break;
      case 'nf':
        body = _notFood();
        break;
      default:
        body = _scanning();
    }
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: kScanBg,
        resizeToAvoidBottomInset: true,
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 350),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          child: KeyedSubtree(key: ValueKey<String>(_phase), child: body),
        ),
      ),
    );
  }

  Widget _topBar(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 4),
      child: Row(
        children: [
          Semantics(
            button: true,
            label: 'داخستن',
            child: Press(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(shape: BoxShape.circle, color: RC2.white(0.06), border: Border.all(color: V.line)),
                child: Icon(Icons.close_rounded, color: V.tx, size: 22),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: VText(title, style: ku(17, w: FontWeight.w800))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(99),
              gradient: FoodAI.connected ? V.ai : null,
              color: FoodAI.connected ? null : RC2.white(0.06),
              border: FoodAI.connected ? null : Border.all(color: V.line2),
            ),
            child: VText(FoodAI.connected ? '✨ VEX AI' : '🧪 نموونە',
                style: ku(11.5, w: FontWeight.w800, c: FoodAI.connected ? Colors.white : V.mu)),
          ),
        ],
      ),
    );
  }

  // ---------- لە کاتی شیکاریدا ----------
  Widget _scanning() {
    final isText = widget.image == null;
    return SafeArea(
      child: Column(
        children: [
          _topBar('سکانی خواردن'),
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AspectRatio(
                        aspectRatio: isText ? 1.6 : 1,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(30),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              if (_photo != null)
                                Image(
                                  image: _photo!,
                                  fit: BoxFit.cover,
                                  gaplessPlayback: true,
                                  errorBuilder: (context, e, st) => const _PhotoFallback(),
                                )
                              else
                                _textBox(),
                              const IgnorePointer(child: DecoratedBox(decoration: BoxDecoration(color: Color(0x33020E12)))),
                              IgnorePointer(
                                child: AnimatedBuilder(
                                  animation: _scan,
                                  builder: (context, _) => CustomPaint(painter: _ScanPainter(_scan.value)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 22),
                      for (int i = 0; i < _steps.length; i++) _stepRow(i),
                      const SizedBox(height: 16),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(9),
                        child: SizedBox(
                          height: 6,
                          child: Stack(
                            children: [
                              Positioned.fill(child: ColoredBox(color: RC2.white(0.07))),
                              AnimatedBuilder(
                                animation: _prog,
                                builder: (context, _) => FractionallySizedBox(
                                  alignment: AlignmentDirectional.centerStart,
                                  widthFactor: _prog.value.clamp(0.0, 1.0),
                                  child: const DecoratedBox(decoration: BoxDecoration(gradient: V.prime)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      VText(
                        FoodAI.connected ? 'VEX AI شیکاری دەکات… چەند چرکەیەک' : 'شیکاری دەکرێت…',
                        textAlign: TextAlign.center,
                        style: ku(12.5, c: V.mu),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
            child: Press(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 13),
                alignment: Alignment.center,
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(18), border: Border.all(color: V.line2)),
                child: VText('هەڵوەشاندنەوە', style: ku(14, w: FontWeight.w800, c: V.mu)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _textBox() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0B3442), Color(0xFF04202A)],
        ),
      ),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const VText('✍️', style: TextStyle(fontSize: 38)),
          const SizedBox(height: 10),
          VText(
            '«${_text ?? ''}»',
            textAlign: TextAlign.center,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            style: ku(16, w: FontWeight.w700, h: 1.6),
          ),
        ],
      ),
    );
  }

  Widget _stepRow(int i) {
    final done = i < _step;
    final now = i == _step;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 300),
        opacity: done || now ? 1 : 0.4,
        child: Row(
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: done
                  ? Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: V.mint),
                      child: Icon(Icons.check_rounded, size: 16, color: V.ink),
                    )
                  : now
                      ? Padding(
                          padding: EdgeInsets.all(3),
                          child: CircularProgressIndicator(strokeWidth: 2.2, color: V.cy),
                        )
                      : Container(
                          decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: V.line2, width: 1.5)),
                        ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: VText(_steps[i],
                  style: ku(14, w: done || now ? FontWeight.w700 : FontWeight.w500, c: done ? V.tx : (now ? V.c2 : V.mu))),
            ),
          ],
        ),
      ),
    );
  }

  // ---------- هەڵە ----------
  Widget _failView() {
    final f = _fail ?? ScanFail('server');
    final isText = widget.image == null;
    return SafeArea(
      child: Column(
        children: [
          _topBar('سکانی خواردن'),
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(22),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Container(
                          width: 84,
                          height: 84,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0x1AFF5F7E),
                            border: Border.all(color: const Color(0x4DFF5F7E)),
                          ),
                          child: VText(f.code == 'network' ? '📡' : (f.code == 'offline_text' ? '🤔' : '⚠️'),
                              style: const TextStyle(fontSize: 38)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      VText(f.code == 'offline_text' ? 'نەمناسییەوە' : 'شیکاری نەکرا',
                          textAlign: TextAlign.center, style: ku(20, w: FontWeight.w800)),
                      const SizedBox(height: 6),
                      VText(f.message, textAlign: TextAlign.center, style: ku(14, c: V.mu, h: 1.8)),
                      const SizedBox(height: 20),
                      if (isText) ...[
                        TextField(
                          controller: _retry,
                          minLines: 2,
                          maxLines: 4,
                          maxLength: 300,
                          style: ku(15, h: 1.5),
                          cursorColor: V.cy,
                          decoration: InputDecoration(
                            hintText: vxTr('بۆ نموونە: 2 هێلکە و نانێک و چا'),
                            hintStyle: ku(14, c: kDim),
                            counterText: '',
                            filled: true,
                            fillColor: const Color(0x2E000000),
                            contentPadding: const EdgeInsets.all(13),
                            enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: V.line2)),
                            focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: V.cy)),
                          ),
                        ),
                        const SizedBox(height: 10),
                        VBtn('✨ دووبارە شیکاری بکە', kind: BtnKind.ai, onTap: () {
                          final t = _retry.text.trim();
                          if (t.isEmpty) return;
                          FocusManager.instance.primaryFocus?.unfocus();
                          _text = t;
                          _start();
                        }),
                      ] else ...[
                        VBtn('🔄 دووبارە هەوڵ بدەرەوە', kind: BtnKind.prime, onTap: _start),
                        const SizedBox(height: 10),
                        VBtn('📸 وێنەیەکی تر بگرە', onTap: _again),
                      ],
                      const SizedBox(height: 10),
                      VBtn('🍕 نموونەکە ببینە', onTap: _showDemo),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------- خواردن نییە ----------
  Widget _notFood() {
    final nm = _r?.name.trim() ?? '';
    return SafeArea(
      child: Column(
        children: [
          _topBar('سکانی خواردن'),
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(22),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_photo != null)
                        Center(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: SizedBox(
                              width: 150,
                              height: 150,
                              child: Image(image: _photo!, fit: BoxFit.cover, errorBuilder: (c, e, s) => const _PhotoFallback()),
                            ),
                          ),
                        ),
                      const SizedBox(height: 18),
                      VText('🤔 ئەمە خواردن نییە', textAlign: TextAlign.center, style: ku(20, w: FontWeight.w800)),
                      const SizedBox(height: 6),
                      VText(
                        nm.isNotEmpty
                            ? 'وا دیارە ئەمە «$nm» ـە. وێنەی خواردن یان خواردنەوەیەک بگرە.'
                            : 'وێنەی خواردن یان خواردنەوەیەک بگرە، با ڕوون و نزیک بێت.',
                        textAlign: TextAlign.center,
                        style: ku(14, c: V.mu, h: 1.8),
                      ),
                      const SizedBox(height: 20),
                      VBtn('📸 دووبارە وێنە بگرە', kind: BtnKind.prime, onTap: _again),
                      const SizedBox(height: 10),
                      VBtn('داخستن', onTap: () => Navigator.of(context).pop()),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------- ئەنجام ----------
  Widget _result() {
    final r = _r!;
    final t = r.totals;
    final live = liveScore(r, _budget, _eaten);
    final vc = (kVerd[live.v] ?? kVerd['ok']!).c;
    final mq = MediaQuery.of(context);
    final kb = mq.viewInsets.bottom > 0;
    final ImageProvider? heroImg = r.demo ? const AssetImage('assets/ads/pizza_board.webp') : _photo;
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: EdgeInsets.fromLTRB(14, mq.padding.top + 10, 14, 18),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ScanHero(r: r, image: heroImg, onClose: () => Navigator.of(context).pop()),
                    if (r.demo) _demoNote(),
                    Rise(
                      delayMs: 80,
                      child: ItemsCard(
                        r: r,
                        onStep: _stepQty,
                        onSet: _setQty,
                        onAddOn: _addOn,
                        onCustom: _custom,
                        onRecalc: _recalc,
                        recalcBusy: _recalcBusy,
                        onMore: _more,
                      ),
                    ),
                    Rise(delayMs: 160, child: NutCard(t: t, budget: _budget, pro: _pro, carb: _carb, fat: _fat)),
                    Rise(delayMs: 240, child: VerdictCard(r: r, live: live)),
                    Rise(delayMs: 300, child: DayCard(eaten: _eaten, meal: t.k, budget: _budget, color: vc, kpm: _kpm)),
                    Rise(delayMs: 360, child: WalkCard(r: r, t: t, kpm: _kpm)),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(6, 14, 6, 4),
                      child: VText(
                        'ژمارەکان خەمڵاندنن و لەوانەیە کەمێک جیاواز بن. بڕەکان و تێبینی ڕاست بکەرەوە بۆ ئەنجامی وردتر.',
                        textAlign: TextAlign.center,
                        style: ku(11.5, c: kDim, h: 1.7),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(child: VBtn('📸 سکانێکی تر', onTap: _again)),
                        const SizedBox(width: 10),
                        Expanded(child: VBtn('داخستن', onTap: () => Navigator.of(context).pop())),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (!kb) _addBar(r, t),
      ],
    );
  }

  Widget _demoNote() {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: const Color(0x14FFBE4D),
        border: Border.all(color: const Color(0x47FFBE4D)),
      ),
      child: Row(
        children: [
          const VText('🧪', style: TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Expanded(
            child: VText(
              'ئەنجامی نموونەیە. دوای بەستنەوەی AI، هەر خواردنێک وێنەی بگریت خۆی دەناسرێتەوە.',
              style: ku(12, w: FontWeight.w600, c: const Color(0xFFFFD993), h: 1.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _addBar(ScanResult r, ScanTotals t) {
    final mq = MediaQuery.of(context);
    final slot = _slotOf(r);
    final name = kSlotName[slot] ?? 'ژەم';
    final can = t.k > 0 || t.act > 0;
    final String hint;
    if (_slot != null) {
      hint = '🍽️ $name · بۆ گۆڕین دابگرە';
    } else if (slot == 's') {
      hint = '🍎 ژەمی سووک · بە پێی خواردنەکە · گۆڕین';
    } else {
      hint = '⏰ کاتژمێر ${ltr(nowHM())} · $name · خۆکار';
    }
    return Container(
      padding: EdgeInsets.fromLTRB(14, 10, 14, 10 + mq.padding.bottom),
      decoration: BoxDecoration(
        color: Color(0xF203181F),
        border: Border(top: BorderSide(color: V.line)),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Press(
                  onTap: _pickSlot,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(99),
                      color: RC2.white(0.05),
                      border: Border.all(color: V.line2),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: VText(hint,
                              maxLines: 1, overflow: TextOverflow.ellipsis, style: ku(12, w: FontWeight.w700, c: V.mu)),
                        ),
                        const SizedBox(width: 4),
                        Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: V.mu),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 9),
              Semantics(
                button: true,
                enabled: can,
                child: Press(
                  onTap: can ? _add : null,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    height: 56,
                    padding: const EdgeInsetsDirectional.fromSTEB(18, 0, 8, 0),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: can ? V.prime : null,
                      color: can ? null : RC2.white(0.07),
                      boxShadow: can
                          ? const [BoxShadow(color: Color(0x553CF08A), blurRadius: 26, offset: Offset(0, 8), spreadRadius: -10)]
                          : null,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: VText(
                            '➕ زیادکردن بۆ $name',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: ku(16, w: FontWeight.w800, c: can ? V.ink : kDim),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            color: can ? const Color(0x2604323A) : RC2.white(0.05),
                          ),
                          child: VText.rich(
                            TextSpan(children: [
                              TextSpan(text: fmt(t.k), style: nu(16, c: can ? V.ink : kDim)),
                              TextSpan(text: ' kcal', style: nu(11, w: FontWeight.w700, c: can ? V.ink : kDim)),
                            ]),
                            textDirection: TextDirection.ltr,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PhotoFallback extends StatelessWidget {
  const _PhotoFallback();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(color: Color(0xFF0B3442)),
      child: Center(child: VText('🍽️', style: TextStyle(fontSize: 64))),
    );
  }
}

/// تۆڕی کاڵ + هێڵی سکان + گۆشەکان
class _ScanPainter extends CustomPainter {
  _ScanPainter(this.t);
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    // تۆڕ
    final grid = Paint()
      ..color = const Color(0x142FE6F3)
      ..strokeWidth = 1;
    const n = 6;
    for (int i = 1; i < n; i++) {
      canvas.drawLine(Offset(w * i / n, 0), Offset(w * i / n, h), grid);
      canvas.drawLine(Offset(0, h * i / n), Offset(w, h * i / n), grid);
    }
    // هێڵی سکان (سەرەوە ← خوارەوە ← سەرەوە)
    final p = t < 0.5 ? t * 2 : 2 - t * 2;
    final y = 14 + (h - 28) * Curves.easeInOut.transform(p);
    final down = t < 0.5;
    final trail = Rect.fromLTWH(0, down ? y - 70 : y, w, 70);
    canvas.drawRect(
      trail,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: down
              ? const [Color(0x002FE6F3), Color(0x402FE6F3)]
              : const [Color(0x402FE6F3), Color(0x002FE6F3)],
        ).createShader(trail),
    );
    canvas.drawLine(
      Offset(10, y),
      Offset(w - 10, y),
      Paint()
        ..color = const Color(0xFF8FF3F9)
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 4),
    );
    // گۆشەکان
    final c = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round;
    const m = 16.0, l = 30.0;
    final path = Path()
      ..moveTo(m, m + l)
      ..lineTo(m, m)
      ..lineTo(m + l, m)
      ..moveTo(w - m - l, m)
      ..lineTo(w - m, m)
      ..lineTo(w - m, m + l)
      ..moveTo(m, h - m - l)
      ..lineTo(m, h - m)
      ..lineTo(m + l, h - m)
      ..moveTo(w - m - l, h - m)
      ..lineTo(w - m, h - m)
      ..lineTo(w - m, h - m - l);
    canvas.drawPath(path, c);
  }

  @override
  bool shouldRepaint(_ScanPainter o) => o.t != t;
}
