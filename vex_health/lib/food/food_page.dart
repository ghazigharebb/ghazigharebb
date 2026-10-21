// VEX Health — بەشی خواردن: گەڕان، پۆلەکان، وردەکاری و زیادکردن
//
// openFoodPage()            ← بۆ تۆمارکردنی خواردن لە ڕۆژەکەدا
// openFoodPage(pick: true)  ← بۆ هەڵبژاردنی خواردنێک (بۆ نموونە لە پەڕەی سکان) و گەڕاندنەوەی
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/store.dart';
import '../core/theme.dart';
import '../scan/scan_model.dart' show kSlotName, mealSlotNow, nf, parseQ;
import 'food_db.dart';

/// ئەنجامی هەڵبژاردن (بۆ پەڕەی سکان)
class FoodPick {
  const FoodPick({this.food, this.unit, this.n = 1, this.name = '', this.kcal = 0});
  final FoodEntry? food; // null = خواردنی دەستی (ناو + کالۆری)
  final FoodUnit? unit;
  final double n;
  final String name;
  final double kcal;
}

bool _open = false;

Future<FoodPick?> openFoodPage({bool pick = false, String? query}) async {
  final nav = navKey.currentState;
  if (nav == null || _open) return null;
  _open = true;
  try {
    return await nav.push<FoodPick>(
      PageRouteBuilder<FoodPick>(
        transitionDuration: const Duration(milliseconds: 300),
        reverseTransitionDuration: const Duration(milliseconds: 220),
        pageBuilder: (context, a, b) => FoodPage(pick: pick, query: query),
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
  } finally {
    _open = false;
  }
}

const Map<String, String> kSlotIcon = {'b': '🌅', 'l': '☀️', 's': '🍎', 'd': '🌙', 'n': '🌃'};
const Color _kPro = Color(0xFFFF5F7E);
const Color _kCarb = Color(0xFFFFBE4D);
const Color _kFat = Color(0xFF9B7BFF);
const Color _kDim = Color(0xFF5F8A92);

// ---------- دواین خواردنەکان ----------
class _Recent {
  static const String _key = 'vexfood-recent';
  static List<String> ids = [];
  static bool _loaded = false;

  static Future<void> load() async {
    if (_loaded) return;
    _loaded = true;
    try {
      final sp = await SharedPreferences.getInstance();
      final s = sp.getString(_key);
      if (s != null) {
        final j = jsonDecode(s);
        if (j is List) ids = j.map((x) => '$x').where((id) => FoodDb.I.byId(id) != null).take(12).toList();
      }
    } catch (_) {}
  }

  static Future<void> add(String id) async {
    ids.remove(id);
    ids.insert(0, id);
    if (ids.length > 12) ids = ids.sublist(0, 12);
    try {
      final sp = await SharedPreferences.getInstance();
      await sp.setString(_key, jsonEncode(ids));
    } catch (_) {}
  }
}

// =====================================================================
//  وێنەی بچووکی خواردن (وێنە ئەگەر هەبێت، ئەگەرنا ئیمۆجی)
// =====================================================================
class FoodThumb extends StatelessWidget {
  const FoodThumb(this.f, {super.key, this.size = 50, this.radius = 15});
  final FoodEntry f;
  final double size;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final img = FoodDb.I.imageOf(f);
    final dpr = MediaQuery.of(context).devicePixelRatio;
    Widget emoji() => Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            color: const Color(0x142FE6F3),
            border: Border.all(color: V.line),
          ),
          child: Text(f.e, style: TextStyle(fontSize: size * 0.5, height: 1.1)),
        );
    if (img == null) return emoji();
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Image.asset(
        img,
        width: size,
        height: size,
        fit: BoxFit.cover,
        cacheWidth: (size * dpr).round(),
        errorBuilder: (c, e, s) => emoji(),
      ),
    );
  }
}

// =====================================================================
//  پەڕەی خواردنەکان
// =====================================================================
class FoodPage extends StatefulWidget {
  const FoodPage({super.key, this.pick = false, this.query});
  final bool pick;
  final String? query;

  @override
  State<FoodPage> createState() => _FoodPageState();
}

class _FoodPageState extends State<FoodPage> {
  late final TextEditingController _q = TextEditingController(text: widget.query ?? '');
  final TextEditingController _ck = TextEditingController();
  final FocusNode _qf = FocusNode();
  final ScrollController _sc = ScrollController();
  String? _cat;
  List<Object> _rows = const [];

  @override
  void initState() {
    super.initState();
    _rebuild();
    _Recent.load().then((_) {
      if (mounted) setState(_rebuild);
    });
    if (widget.pick) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _qf.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _q.dispose();
    _ck.dispose();
    _qf.dispose();
    _sc.dispose();
    super.dispose();
  }

  /// ڕیزەکانی لیست: String = سەردێڕ، FoodEntry = خواردن
  void _rebuild() {
    final db = FoodDb.I;
    final q = _q.text.trim();
    final rows = <Object>[];
    if (q.isNotEmpty) {
      rows.addAll(db.search(q, cat: _cat, limit: 120));
    } else if (_cat != null) {
      rows.addAll(db.foods.where((f) => f.cat == _cat));
    } else {
      final rec = _Recent.ids.map(db.byId).whereType<FoodEntry>().toList();
      if (rec.isNotEmpty) {
        rows.add('🕘 دواین جار');
        rows.addAll(rec);
      }
      for (final c in db.cats) {
        final l = db.foods.where((f) => f.cat == c.k).toList();
        if (l.isEmpty) continue;
        rows.add('${c.e} ${c.t}');
        rows.addAll(l);
      }
    }
    _rows = rows;
  }

  void _setCat(String? k) {
    HapticFeedback.selectionClick();
    setState(() {
      _cat = _cat == k ? null : k;
      _rebuild();
    });
    if (_sc.hasClients) _sc.jumpTo(0);
  }

  Future<void> _openFood(FoodEntry f) async {
    FocusManager.instance.primaryFocus?.unfocus();
    final r = await showVSheet<FoodPick>(builder: (c) => FoodSheet(f: f, pick: widget.pick));
    if (!mounted) return;
    if (r != null) {
      _Recent.add(f.id);
      if (widget.pick) {
        Navigator.of(context).pop(r);
      } else {
        setState(_rebuild);
      }
    }
  }

  /// خواردنێک کە لە لیستەکەدا نییە: ناو + کالۆری
  void _addCustom() {
    final name = _q.text.trim();
    final kv = parseKcal(_ck.text);
    if (name.length < 2) {
      _qf.requestFocus();
      return;
    }
    if (kv == null || kv <= 0) {
      toast('کالۆرییەکەی بنووسە (بۆ نموونە 150)');
      return;
    }
    final kc = kv.clamp(1.0, 5000.0);
    FocusManager.instance.primaryFocus?.unfocus();
    HapticFeedback.mediumImpact();
    if (widget.pick) {
      Navigator.of(context).pop(FoodPick(name: name, kcal: kc));
      return;
    }
    final slot = mealSlotNow();
    Store.I.addFood(FoodItem(
      n: name.length > 40 ? name.substring(0, 40) : name,
      kcal: kc.round(),
      p: (kc * 0.15 / 4).round(),
      c: (kc * 0.5 / 4).round(),
      f: (kc * 0.35 / 9).round(),
      at: nowHM(),
      v: kc > 700 ? 'bad' : 'ok',
      e: '🍽️',
      slot: slot,
    ));
    _ck.clear();
    toast('✓ $name زیاد کرا بۆ ${kSlotName[slot]}');
  }

  @override
  Widget build(BuildContext context) {
    final db = FoodDb.I;
    final mq = MediaQuery.of(context);
    final kb = mq.viewInsets.bottom > 0;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: V.bg,
        body: Column(
          children: [
            SizedBox(height: mq.padding.top + 8),
            // سەرەوە
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
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
                        decoration: BoxDecoration(shape: BoxShape.circle, color: V.surf2, border: Border.all(color: V.line)),
                        child: const Icon(Icons.close_rounded, color: V.tx, size: 22),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.pick ? 'چیت لەگەڵی خوارد؟' : 'خواردنەکان', style: ku(19, w: FontWeight.w800, h: 1.4)),
                        Text('${ltr(fmt(db.foods.length))} خواردن و خواردنەوە · کالۆری و پێکهاتە',
                            maxLines: 1, overflow: TextOverflow.ellipsis, style: ku(11.5, c: V.mu)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // گەڕان
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: TextField(
                controller: _q,
                focusNode: _qf,
                textInputAction: TextInputAction.search,
                style: ku(15.5, w: FontWeight.w600),
                cursorColor: V.cy,
                onChanged: (_) => setState(_rebuild),
                decoration: InputDecoration(
                  hintText: 'بگەڕێ: دۆڵمە، قەسپ، کۆلا، شلە…',
                  hintStyle: ku(14.5, c: _kDim),
                  prefixIcon: const Icon(Icons.search_rounded, color: V.mu),
                  suffixIcon: _q.text.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.cancel_rounded, color: V.mu, size: 20),
                          onPressed: () => setState(() {
                            _q.clear();
                            _rebuild();
                          }),
                        ),
                  filled: true,
                  fillColor: const Color(0x2E000000),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 13),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: V.line2)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: V.cy)),
                ),
              ),
            ),
            // پۆلەکان
            SizedBox(
              height: 52,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
                children: [
                  _chip('هەموو', _cat == null, () => _setCat(null)),
                  for (final c in db.cats) _chip('${c.e} ${c.t}', _cat == c.k, () => _setCat(c.k)),
                ],
              ),
            ),
            Expanded(child: _list()),
            if (!widget.pick && !kb) _todayBar(),
          ],
        ),
      ),
    );
  }

  Widget _chip(String t, bool on, VoidCallback onTap) => Padding(
        padding: const EdgeInsetsDirectional.only(end: 6),
        child: Press(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(99),
              color: on ? const Color(0x262FE6F3) : V.surf2,
              border: Border.all(color: on ? V.cy : V.line),
            ),
            child: Text(t, style: ku(12.5, w: FontWeight.w700, c: on ? V.tx : V.mu, h: 1.2)),
          ),
        ),
      );

  Widget _list() {
    final mq = MediaQuery.of(context);
    if (!FoodDb.I.loaded) {
      return Center(child: Text('لیستی خواردنەکان بار نەبوو.', style: ku(14, c: V.mu)));
    }
    if (_rows.isEmpty) return _empty();
    return ListView.builder(
      controller: _sc,
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: EdgeInsets.fromLTRB(14, 4, 14, 24 + (widget.pick ? mq.padding.bottom : 0)),
      itemCount: _rows.length + (_q.text.trim().isNotEmpty ? 1 : 0),
      itemBuilder: (context, i) {
        if (i >= _rows.length) return _customBox(compact: true);
        final x = _rows[i];
        if (x is String) {
          return Padding(
            padding: EdgeInsets.only(top: i == 0 ? 4 : 18, bottom: 6),
            child: Text(x, style: ku(13.5, w: FontWeight.w800, c: V.mu)),
          );
        }
        return _row(x as FoodEntry);
      },
    );
  }

  Widget _row(FoodEntry f) {
    final u = f.unit0;
    return Press(
      onTap: () => _openFood(f),
      scale: 0.985,
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: V.surf,
          border: Border.all(color: V.line),
        ),
        child: Row(
          children: [
            FoodThumb(f, size: 48),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(f.ku, maxLines: 1, overflow: TextOverflow.ellipsis, style: ku(14.5, w: FontWeight.w800, h: 1.4)),
                  Text(
                    '1 ${u.name} · ${ltr('${fmt(u.g)}g')}${f.ar.isNotEmpty ? ' · ${f.ar.split('/').first.trim()}' : ''}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: ku(11.5, c: V.mu, h: 1.4),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(fmt(f.kcalOf(u, 1)), style: nu(16, h: 1.2)),
                Text('kcal', style: nu(10, w: FontWeight.w600, c: V.mu)),
              ],
            ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_left_rounded, color: _kDim, size: 22),
          ],
        ),
      ),
    );
  }

  Widget _empty() {
    return ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(14, 24, 14, 24),
      children: [
        const Center(child: Text('🔎', style: TextStyle(fontSize: 40))),
        const SizedBox(height: 8),
        Text('«${_q.text.trim()}» نەدۆزرایەوە', textAlign: TextAlign.center, style: ku(17, w: FontWeight.w800)),
        const SizedBox(height: 4),
        Text('بە شێوەیەکی تر بینووسە، یان خۆت کالۆرییەکەی دابنێ:',
            textAlign: TextAlign.center, style: ku(13, c: V.mu, h: 1.7)),
        const SizedBox(height: 12),
        _customBox(),
      ],
    );
  }

  /// زیادکردنی دەستی (ناو = دەقی گەڕان)
  Widget _customBox({bool compact = false}) {
    final name = _q.text.trim();
    return Container(
      margin: EdgeInsets.only(top: compact ? 10 : 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: V.surf2,
        border: Border.all(color: V.line2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(compact ? 'ئەوەی دەتەوێت لە لیستەکەدا نییە؟' : '✍️ «$name» بە کالۆری خۆت',
              maxLines: 1, overflow: TextOverflow.ellipsis, style: ku(13, w: FontWeight.w800, c: compact ? V.mu : V.tx)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _ck,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  textDirection: TextDirection.ltr,
                  maxLength: 4,
                  style: nu(16, w: FontWeight.w700),
                  cursorColor: V.cy,
                  onSubmitted: (_) => _addCustom(),
                  decoration: InputDecoration(
                    hintText: 'kcal',
                    hintStyle: nu(14, w: FontWeight.w600, c: _kDim),
                    counterText: '',
                    isDense: true,
                    filled: true,
                    fillColor: const Color(0x2E000000),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(13), borderSide: const BorderSide(color: V.line2)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(13), borderSide: const BorderSide(color: V.cy)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Press(
                onTap: _addCustom,
                child: Container(
                  height: 46,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(13), gradient: V.prime),
                  child: Text('➕ زیادکردن', style: ku(14, w: FontWeight.w800, c: V.ink)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _todayBar() {
    final mq = MediaQuery.of(context);
    return AnimatedBuilder(
      animation: Store.I,
      builder: (context, _) {
        final s = Store.I;
        final eaten = s.totals().kcal;
        final b = s.budget;
        final over = eaten > b;
        return Container(
          padding: EdgeInsets.fromLTRB(16, 10, 14, 10 + mq.padding.bottom),
          decoration: const BoxDecoration(
            color: Color(0xF2041C24),
            border: Border(top: BorderSide(color: V.line)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('ئەمڕۆ خواردووتە', style: ku(11.5, c: V.mu)),
                    Text.rich(
                      TextSpan(children: [
                        TextSpan(text: fmt(eaten), style: nu(18, c: over ? const Color(0xFFFF8A5F) : V.tx)),
                        TextSpan(text: ' / ${fmt(b)} kcal', style: nu(12, w: FontWeight.w600, c: V.mu)),
                      ]),
                      textDirection: TextDirection.ltr,
                    ),
                  ],
                ),
              ),
              Press(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), gradient: V.prime),
                  child: Text('✓ تەواو', style: ku(14.5, w: FontWeight.w800, c: V.ink)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// «150»، «١٥٠»، «150 kcal»
double? parseKcal(String s) {
  var t = s.replaceAllMapped(RegExp('[٠-٩]'), (m) => '${m[0]!.codeUnitAt(0) - 0x0660}');
  t = t.replaceAllMapped(RegExp('[۰-۹]'), (m) => '${m[0]!.codeUnitAt(0) - 0x06F0}');
  t = t.replaceAll(RegExp('[٫،,]'), '.').replaceAll(RegExp(r'[^\d.]'), '');
  return double.tryParse(t);
}

// =====================================================================
//  وردەکاری خواردن: یەکە، بڕ، کالۆری، پێکهاتە، ژەم، زیادکردن
// =====================================================================
class FoodSheet extends StatefulWidget {
  const FoodSheet({super.key, required this.f, this.pick = false});
  final FoodEntry f;
  final bool pick;

  @override
  State<FoodSheet> createState() => _FoodSheetState();
}

class _FoodSheetState extends State<FoodSheet> {
  late FoodUnit _u = widget.f.unit0;
  double _n = 1;
  late String _slot = _autoSlot();
  bool _slotManual = false;
  late final TextEditingController _c = TextEditingController(text: nf(_n));
  final FocusNode _cf = FocusNode();

  FoodEntry get f => widget.f;

  @override
  void initState() {
    super.initState();
    _cf.addListener(() {
      if (_cf.hasFocus) {
        _c.selection = TextSelection(baseOffset: 0, extentOffset: _c.text.length);
      } else {
        _commit();
      }
    });
  }

  @override
  void dispose() {
    _c.dispose();
    _cf.dispose();
    super.dispose();
  }

  String _autoSlot() {
    const light = {'fruit', 'nuts', 'dates', 'sweets', 'drinks', 'extras'};
    final k = f.kcalOf(f.unit0, 1);
    if (light.contains(f.cat) && k < 300) return 's';
    return mealSlotNow();
  }

  double get _max => _u.isGram ? 3000 : 50;

  void _setN(double v) {
    if (!mounted) return;
    final x = v.clamp(0.0, _max);
    setState(() {
      _n = (x * 100).round() / 100;
      if (!_cf.hasFocus) _c.text = _u.isGram ? fmt(_n) : nf(_n);
      if (!_slotManual) _slot = _autoSlot();
    });
  }

  void _step(int d) {
    HapticFeedback.selectionClick();
    double n = _n;
    if (_u.isGram) {
      final st = n < 100 || (n == 100 && d < 0) ? 10.0 : 25.0;
      n = d > 0 ? ((n / st).floor() + 1) * st : ((n / st).ceil() - 1) * st;
    } else if (d > 0) {
      n = n < 0.5 ? 0.5 : (n < 1 ? 1 : n.floorToDouble() + 1);
    } else {
      n = n > 1 ? n.ceilToDouble() - 1 : (n > 0.5 ? 0.5 : (n > 0.25 ? 0.25 : 0));
    }
    _setN(n);
  }

  void _commit() {
    final raw = _c.text;
    double? v;
    if (_u.isGram) {
      v = parseKcal(raw);
    } else {
      v = parseQ(raw);
    }
    if (v != null) {
      _setN(v);
    } else {
      _c.text = _u.isGram ? fmt(_n) : nf(_n);
    }
  }

  void _setUnit(FoodUnit u) {
    if (u.name == _u.name) return;
    HapticFeedback.selectionClick();
    final grams = _u.g * _n;
    double n;
    if (u.isGram) {
      n = ((grams / 5).round() * 5).toDouble();
      if (n <= 0) n = 100;
    } else {
      n = (grams / u.g * 2).round() / 2;
      if (n <= 0) n = 1;
    }
    setState(() => _u = u);
    _setN(n);
  }

  String get _qtyTxt => _u.isGram ? '${fmt(_n)}g' : '${nf(_n)} ${_u.name}';

  void _done() {
    _commit();
    if (_n <= 0) {
      toast('بڕەکە بنووسە');
      return;
    }
    HapticFeedback.mediumImpact();
    if (widget.pick) {
      Navigator.of(context).pop(FoodPick(food: f, unit: _u, n: _n, name: f.ku));
      return;
    }
    final k = f.kcalOf(_u, _n);
    final nm = '${f.ku} · $_qtyTxt';
    Store.I.addFood(FoodItem(
      n: nm.length > 70 ? '${nm.substring(0, 68)}…' : nm,
      kcal: k.round(),
      p: f.pOf(_u, _n).round(),
      c: f.cOf(_u, _n).round(),
      f: f.fOf(_u, _n).round(),
      at: nowHM(),
      v: f.verdictFor(k),
      e: f.e,
      slot: _slot,
    ));
    Navigator.of(context).pop(FoodPick(food: f, unit: _u, n: _n, name: f.ku));
    toast('✓ ${f.ku} ($_qtyTxt) زیاد کرا بۆ ${kSlotName[_slot]}');
  }

  @override
  Widget build(BuildContext context) {
    final img = FoodDb.I.imageOf(f);
    final cat = FoodDb.I.catOf(f.cat);
    final k = f.kcalOf(_u, _n);
    final g = f.gramsOf(_u, _n);
    final pp = f.pOf(_u, _n), cc = f.cOf(_u, _n), ff = f.fOf(_u, _n);
    final fib = f.fibOf(_u, _n), sug = f.sugOf(_u, _n);
    final subs = [f.ar.split('/').first.trim(), f.en].where((x) => x.isNotEmpty).join(' · ');
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // وێنە
        if (img != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: AspectRatio(
              aspectRatio: 16 / 10,
              child: Image.asset(img, fit: BoxFit.cover, errorBuilder: (c, e, s) => _emojiHero()),
            ),
          )
        else
          _emojiHero(),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(f.ku, style: ku(20, w: FontWeight.w800, h: 1.4)),
                  if (subs.isNotEmpty) Text(subs, style: ku(12, c: V.mu, h: 1.5)),
                ],
              ),
            ),
            if (cat != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(99), color: V.surf2, border: Border.all(color: V.line)),
                child: Text('${cat.e} ${cat.t}', style: ku(11, w: FontWeight.w700, c: V.mu)),
              ),
          ],
        ),
        const SizedBox(height: 14),
        // یەکەکان
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final u in f.units)
              Press(
                onTap: () => _setUnit(u),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(99),
                    color: u.name == _u.name ? const Color(0x262FE6F3) : Colors.transparent,
                    border: Border.all(color: u.name == _u.name ? V.cy : V.line2),
                  ),
                  child: Text(
                    u.isGram ? u.name : '${u.name} ${ltr('(${fmt(u.g)}g)')}',
                    style: ku(12.5, w: FontWeight.w700, c: u.name == _u.name ? V.tx : V.mu, h: 1.2),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        // بڕ + کالۆری
        Row(
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                color: const Color(0x2E000000),
                border: Border.all(color: V.line2),
              ),
              child: Directionality(
                textDirection: TextDirection.ltr,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _btn('−', _n <= 0 ? null : () => _step(-1)),
                    SizedBox(
                      width: 64,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextField(
                            controller: _c,
                            focusNode: _cf,
                            textAlign: TextAlign.center,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            textInputAction: TextInputAction.done,
                            style: nu(20, h: 1.15),
                            cursorColor: V.cy,
                            decoration: const InputDecoration(isDense: true, border: InputBorder.none, contentPadding: EdgeInsets.zero),
                            onSubmitted: (_) => _cf.unfocus(),
                          ),
                          Text(_u.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textDirection: TextDirection.rtl,
                              style: ku(10.5, w: FontWeight.w700, c: V.mu, h: 1.3)),
                        ],
                      ),
                    ),
                    _btn('+', _n >= _max ? null : () => _step(1)),
                  ],
                ),
              ),
            ),
            const Spacer(),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text.rich(
                  TextSpan(children: [
                    TextSpan(text: fmt(k), style: nu(30, c: const Color(0xFFFFE3CC), h: 1.1)),
                    TextSpan(text: ' kcal', style: nu(12, w: FontWeight.w700, c: V.mu)),
                  ]),
                  textDirection: TextDirection.ltr,
                ),
                Text('≈ ${fmt(g)}g', textDirection: TextDirection.ltr, style: nu(12, w: FontWeight.w600, c: V.mu)),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        // پێکهاتە
        Row(
          children: [
            Expanded(child: _macro('💪 پڕۆتین', pp, _kPro)),
            const SizedBox(width: 8),
            Expanded(child: _macro('🌾 کارب', cc, _kCarb)),
            const SizedBox(width: 8),
            Expanded(child: _macro('🥑 چەوری', ff, _kFat)),
          ],
        ),
        if (fib >= 0.5 || sug >= 0.5)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text.rich(
              TextSpan(children: [
                if (fib >= 0.5) ...[
                  const TextSpan(text: '🥦 ڕیشاڵ '),
                  TextSpan(text: ltr('${_g(fib)}g'), style: nu(12, w: FontWeight.w700)),
                ],
                if (fib >= 0.5 && sug >= 0.5) const TextSpan(text: '   ·   '),
                if (sug >= 0.5) ...[
                  const TextSpan(text: '🍬 شەکر '),
                  TextSpan(text: ltr('${_g(sug)}g'), style: nu(12, w: FontWeight.w700)),
                ],
              ]),
              textAlign: TextAlign.center,
              style: ku(12, w: FontWeight.w700, c: V.mu),
            ),
          ),
        if (!widget.pick) ...[
          const SizedBox(height: 14),
          Text('بۆ کام ژەم؟', style: ku(12.5, w: FontWeight.w800, c: V.mu)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final e in kSlotName.entries)
                Press(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() {
                      _slot = e.key;
                      _slotManual = true;
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(99),
                      color: e.key == _slot ? const Color(0x263CF08A) : Colors.transparent,
                      border: Border.all(color: e.key == _slot ? V.mint : V.line2),
                    ),
                    child: Text('${kSlotIcon[e.key]} ${e.value}',
                        style: ku(12, w: FontWeight.w700, c: e.key == _slot ? V.tx : V.mu, h: 1.2)),
                  ),
                ),
            ],
          ),
        ],
        const SizedBox(height: 16),
        Press(
          onTap: _done,
          child: Container(
            height: 56,
            padding: const EdgeInsetsDirectional.fromSTEB(18, 0, 8, 0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: V.prime,
              boxShadow: const [BoxShadow(color: Color(0x553CF08A), blurRadius: 26, offset: Offset(0, 8), spreadRadius: -10)],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.pick ? '➕ زیادکردن بۆ ئەم ژەمە' : '➕ زیادکردن بۆ ${kSlotName[_slot]}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: ku(16, w: FontWeight.w800, c: V.ink),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), color: const Color(0x2604323A)),
                  child: Text('${fmt(k)} kcal', textDirection: TextDirection.ltr, style: nu(14, c: V.ink)),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'ژمارەکان خەمڵاندنی ستانداردن؛ چێشتی ماڵان کەمێک جیاوازە بە پێی ڕۆن و بڕ.',
          textAlign: TextAlign.center,
          style: ku(11, c: _kDim, h: 1.6),
        ),
      ],
    );
  }

  static String _g(double v) => v < 10 ? nf((v * 10).round() / 10) : fmt(v);

  Widget _emojiHero() => Container(
        height: 120,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0B3442), Color(0xFF062A35)],
          ),
          border: Border.all(color: V.line),
        ),
        child: Text(f.e, style: const TextStyle(fontSize: 64)),
      );

  Widget _btn(String t, VoidCallback? onTap) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(
          width: 46,
          height: 52,
          child: Center(child: Text(t, style: nu(24, w: FontWeight.w600, c: onTap == null ? const Color(0xFF35575E) : V.c2, h: 1))),
        ),
      );

  Widget _macro(String label, double v, Color c) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: V.surf2,
          border: Border.all(color: op(c, 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: ku(11.5, w: FontWeight.w700, c: V.mu)),
            Text.rich(
              TextSpan(children: [
                TextSpan(text: _g(v), style: nu(17)),
                TextSpan(text: ' g', style: nu(11, w: FontWeight.w600, c: V.mu)),
              ]),
              textDirection: TextDirection.ltr,
            ),
          ],
        ),
      );
}
