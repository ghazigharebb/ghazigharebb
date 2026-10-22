// VEX Health — پەڕەی تەمەنی ژیانی (VitalAge)
// دوو دۆخ: ١) کۆکردنەوەی ٢١ ڕۆژ  ٢) ئەنجام (دوای ٢١ ڕۆژی تەواو)
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../band/band_state.dart';
import '../band/ble/vex_ble.dart';
import '../core/icons.dart';
import '../core/theme.dart';
import '../health/detail_common.dart';
import '../health/hc.dart';
import 'vital_age_engine.dart';

void openVitalAgePage() => pushPage(const VitalAgePage());

class VitalAgePage extends StatefulWidget {
  const VitalAgePage({super.key});
  @override
  State<VitalAgePage> createState() => _VitalAgePageState();
}

class _VitalAgePageState extends State<VitalAgePage> with SingleTickerProviderStateMixin {
  late final AnimationController _in = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..forward();
  bool _syncing = false;
  double _p = 0;

  @override
  void initState() {
    super.initState();
    VitalAgeEngine.I.init();
  }

  @override
  void dispose() {
    _in.dispose();
    super.dispose();
  }

  Future<void> _sync() async {
    if (_syncing) return;
    if (!VexBand.I.linked) {
      toast(BandState.I.connected ? 'پەیوەندی BLE ی Band نییە — لە پەڕەی Band دا پەیوەستی بکە' : 'Band پەیوەست نییە');
      return;
    }
    setState(() {
      _syncing = true;
      _p = 0;
    });
    await VexBand.I.syncAll(onProgress: (v) {
      if (mounted) setState(() => _p = v);
    });
    VitalAgeEngine.I.ingest(VexBand.I);
    if (mounted) setState(() => _syncing = false);
    toast('داتای Band هاوکات کرا ✓');
  }

  Future<void> _pickBirth() async {
    final e = VitalAgeEngine.I;
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: e.birth ?? DateTime(now.year - 30, 6, 15),
      firstDate: DateTime(now.year - 100),
      lastDate: DateTime(now.year - 10, now.month, now.day),
    );
    if (d != null) await e.setBirth(d);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([VitalAgeEngine.I, VexBand.I, BandState.I]),
      builder: (context, _) {
        final e = VitalAgeEngine.I;
        final res = e.compute();
        return DetailScaffold(children: [
          _header(),
          if (res != null) ..._result(res, e) else ..._collect(e),
          const SizedBox(height: 6),
          _disclaimer(),
        ]);
      },
    );
  }

  // ───────────── سەرەوە ─────────────
  Widget _header() {
    return Row(children: [
      Press(
        onTap: () => Navigator.of(context).maybePop(),
        child: Container(
          width: 38,
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: HC.card, borderRadius: BorderRadius.circular(12), border: Border.all(color: HC.line)),
          child: svgIcon(HI.back, HX.tx, size: 18, stroke: 2.4),
        ),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: GestureDetector(
          // تەنها لە debug: درێژ دابگرە بۆ تاقیکردنەوەی دیزاینی ئەنجام بە داتای ساختە
          onLongPress: kDebugMode ? VitalAgeEngine.I.togglePreview : null,
          child: VText('تەمەنی ژیانی', style: ku(22, w: FontWeight.w800, c: HC.tx, h: 1.3)),
        ),
      ),
      if (VitalAgeEngine.I.preview)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(color: op(HC.wn, .18), borderRadius: BorderRadius.circular(99)),
          child: VText('نموونە', style: ku(11, w: FontWeight.w800, c: HC.wn)),
        ),
    ]);
  }

  // ───────────── دۆخی ١: کۆکردنەوە ─────────────
  List<Widget> _collect(VitalAgeEngine e) {
    final rem = e.remaining;
    return [
      HCard(
        top: 16,
        radius: 28,
        padding: 18,
        child: Column(children: [
          Row(children: [
            Expanded(
              child: VText('کۆکردنەوەی زانیاری بەردەوامە',
                  style: ku(15.5, w: FontWeight.w800, c: HC.tx, h: 1.5)),
            ),
            _chip(svgIcon(HI.spark, HX.c, size: 13, stroke: 2.2), 'VEX Band', HC.c),
          ]),
          const SizedBox(height: 4),
          VText('لانیکەم ${VitalAgeEngine.need} ڕۆژی زانیاریی تەواو پێویستە بۆ یەکەم ڕاپۆرتی تەمەنی ژیانیت.',
              style: ku(12.5, c: HC.mu, h: 1.8)),
          const SizedBox(height: 16),
          SizedBox(
            width: 230,
            height: 230,
            child: AnimatedBuilder(
              animation: _in,
              builder: (_, __) => CustomPaint(
                painter: _DayRing(e.cells, Curves.easeOutCubic.transform(_in.value)),
                child: Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Row(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.end, children: [
                      Text('${(e.collected * Curves.easeOutCubic.transform(_in.value)).round()}',
                          style: ku(52, w: FontWeight.w800, c: HC.tx, h: 1.0)),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8, left: 4),
                        child: Text('/${VitalAgeEngine.need}', style: ku(18, w: FontWeight.w700, c: HC.mu)),
                      ),
                    ]),
                    const SizedBox(height: 6),
                    VText('ڕۆژی تەواو', style: ku(12.5, c: HC.mu)),
                  ]),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [op(HC.c, .20), op(HC.ok, .16)]),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: op(HC.c, .35)),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              VText('ماوە', style: ku(13, c: HC.mu)),
              const SizedBox(width: 8),
              Text('$rem', style: ku(28, w: FontWeight.w800, c: HC.c)),
              const SizedBox(width: 6),
              VText('ڕۆژ', style: ku(13, w: FontWeight.w700, c: HC.tx)),
            ]),
          ),
        ]),
      ),

      // ئەمڕۆ
      _sectionTitle('زانیاری ڕۆژانە پێویستە'),
      _todayGrid(e),
      const SizedBox(height: 8),
      _syncButton(),

      // تەقویمی ٢١ ڕۆژ
      _sectionTitle('پێشکەوتنی ٢١ ڕۆژ'),
      _calendar(e),

      // تەمەن
      _ageCard(e),

      // ئامۆژگاری
      _sectionTitle('ئامۆژگاری بۆ کۆکردنەوە'),
      HCard(
        top: 8,
        child: Column(children: [
          _tip('هەموو شەوێک Band لە دەست بێت بۆ تۆماری خەوی تەواو.'),
          _tip('ڕۆژانە Band هاوکات بکە (دوگمەی سەرەوە) بۆ ئەوەی زانیاری نەفەوتێت.'),
          _tip('Band بەتری هەبێت؛ ئەگەر ڕۆژێک بەتری نەما، ئەو ڕۆژە ناژمێردرێت.'),
          _tip('پێویست ناکات ٢١ ڕۆژ بەدوای یەکدا بن؛ ڕۆژە تەواوەکان دەژمێردرێن.', last: true),
        ]),
      ),
    ];
  }

  Widget _todayGrid(VitalAgeEngine e) {
    final t = e.today;
    final items = <_TodayItem>[
      _TodayItem('خەو', HI.moon, '#9b7bff', vk(0xFF9B7BFF), t['sleep']!),
      _TodayItem('لێدانی دڵ', HI.heart, HX.hr, HC.hr, t['hr']!),
      _TodayItem('HRV', HI.wave, HX.c, HC.c, t['hrv']!),
      _TodayItem('هەنگاو', HI.step, HX.ok, HC.ok, t['steps']!),
    ];
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 2.55,
        children: [for (final i in items) _todayTile(i)],
      ),
    );
  }

  Widget _todayTile(_TodayItem i) {
    final col = i.on ? i.color : HC.nd;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: op(col, i.on ? .12 : .05),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: op(col, i.on ? .45 : .22)),
      ),
      child: Row(children: [
        Container(
          width: 34,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: op(col, .18), shape: BoxShape.circle),
          child: svgIcon(i.icon, i.on ? i.hex : HX.nd, size: 17, stroke: 2.1),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
            VText(i.name, style: ku(13.5, w: FontWeight.w800, c: HC.tx)),
            VText(i.on ? 'تۆمارکرا' : 'چاوەڕێی Band', style: ku(11, c: i.on ? HC.ok : HC.mu)),
          ]),
        ),
        Icon(i.on ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded, size: 18, color: i.on ? HC.ok : HC.nd),
      ]),
    );
  }

  Widget _syncButton() {
    final linked = VexBand.I.linked;
    return Press(
      onTap: _sync,
      scale: .98,
      child: Container(
        height: 50,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: linked ? V.prime : null,
          color: linked ? null : HC.card,
          borderRadius: BorderRadius.circular(16),
          border: linked ? null : Border.all(color: HC.line),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          if (_syncing)
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2.4, value: _p == 0 ? null : _p, color: HC.ink),
            )
          else
            svgIcon(HI.sync, linked ? '#04323a' : HX.mu, size: 18, stroke: 2.3),
          const SizedBox(width: 10),
          VText(
            _syncing ? 'هاوکاتکردن… ${(_p * 100).round()}%' : (linked ? 'هاوکاتکردنی داتای Band' : 'Band پەیوەست نییە'),
            style: ku(14, w: FontWeight.w800, c: linked ? HC.ink : HC.mu),
          ),
        ]),
      ),
    );
  }

  Widget _calendar(VitalAgeEngine e) {
    final cells = e.cells;
    return HCard(
      top: 8,
      child: Column(children: [
        for (var r = 0; r < 3; r++)
          Padding(
            padding: EdgeInsets.only(top: r == 0 ? 0 : 8),
            child: Row(children: [
              for (var c = 0; c < 7; c++) ...[
                if (c > 0) const SizedBox(width: 7),
                Expanded(child: _cell(r * 7 + c, cells[r * 7 + c], e.collected)),
              ],
            ]),
          ),
        const SizedBox(height: 12),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          _dot(HC.ok),
          const SizedBox(width: 6),
          VText('ڕۆژی تەواو', style: ku(11.5, c: HC.mu)),
          const SizedBox(width: 18),
          _dot(HC.track),
          const SizedBox(width: 6),
          VText('ماوە', style: ku(11.5, c: HC.mu)),
        ]),
      ]),
    );
  }

  Widget _cell(int i, bool on, int collected) {
    final next = !on && i == collected;
    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: on ? null : HC.track,
          gradient: on ? V.prime : null,
          borderRadius: BorderRadius.circular(11),
          border: next ? Border.all(color: HC.c, width: 1.6) : null,
        ),
        child: on
            ? Icon(Icons.check_rounded, size: 16, color: HC.ink)
            : Text('${i + 1}', style: ku(11.5, w: FontWeight.w700, c: next ? HC.c : HC.nd)),
      ),
    );
  }

  Widget _dot(Color c) => Container(width: 10, height: 10, decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(3)));

  Widget _ageCard(VitalAgeEngine e) {
    final has = e.hasAge;
    final b = e.birth;
    return HCard(
      top: 14,
      child: Row(children: [
        Container(
          width: 42,
          height: 42,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: op(has ? HC.ok : HC.wn, .16), shape: BoxShape.circle),
          child: svgIcon(HI.clock, has ? HX.ok : HX.wn, size: 20, stroke: 2),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            VText(has ? 'تەمەنی ڕاستەقینە: ${e.realAge} ساڵ' : 'بەرواری لەدایکبوون بنووسە',
                style: ku(13.5, w: FontWeight.w800, c: HC.tx)),
            VText(
                has
                    ? (b == null ? 'لە پرۆفایلەکەتەوە. بۆ وردتر، بەرواری لەدایکبوون بنووسە.' : 'بەرواری لەدایکبوون تۆمارکراوە')
                    : 'تکایە بەرواری لەدایکبوونی ڕاستەقینەت بنووسە. ئەمە یارمەتیی شیکاری وردتر دەدات.',
                style: ku(11.5, c: has ? HC.mu : HC.wn, h: 1.7)),
          ]),
        ),
        const SizedBox(width: 8),
        Press(
          onTap: _pickBirth,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(color: op(HC.c, .14), borderRadius: BorderRadius.circular(12), border: Border.all(color: op(HC.c, .4))),
            child: VText(has ? 'گۆڕین' : 'نووسین', style: ku(12, w: FontWeight.w800, c: HC.c)),
          ),
        ),
      ]),
    );
  }

  // ───────────── دۆخی ٢: ئەنجام ─────────────
  List<Widget> _result(VitalResult r, VitalAgeEngine e) {
    final younger = r.delta < -0.5, older = r.delta > 0.5;
    final col = younger ? HC.ok : (older ? HC.wn : HC.c);
    final txt = younger
        ? '${r.delta.abs().toStringAsFixed(1)} ساڵ گەنجتر لە تەمەنی ڕاستەقینەت'
        : (older ? '${r.delta.toStringAsFixed(1)} ساڵ پیرتر لە تەمەنی ڕاستەقینەت' : 'نزیکە لە تەمەنی ڕاستەقینەت');
    final age = clampD(r.age, 10.0, 120.0);
    return [
      HCard(
        top: 16,
        radius: 28,
        padding: 20,
        child: Column(children: [
          Row(children: [
            Expanded(child: VText('تەمەنی ژیانیت', style: ku(15.5, w: FontWeight.w800, c: HC.tx))),
            _chip(svgIcon(HI.spark, HX.ok, size: 13, stroke: 2.4), '${r.days} ڕۆژ شیکرا', HC.ok),
          ]),
          const SizedBox(height: 10),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: age),
            duration: const Duration(milliseconds: 1600),
            curve: Curves.easeOutCubic,
            builder: (_, v, __) => ShaderMask(
              shaderCallback: (rc) => LinearGradient(colors: [HC.c2, col]).createShader(rc),
              child: Text(v.toStringAsFixed(1), style: ku(72, w: FontWeight.w800, c: kW, h: 1.1)),
            ),
          ),
          VText('ساڵ', style: ku(14, w: FontWeight.w700, c: HC.mu)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(color: op(col, .15), borderRadius: BorderRadius.circular(14), border: Border.all(color: op(col, .45))),
            child: VText(txt, textAlign: TextAlign.center, style: ku(13, w: FontWeight.w800, c: col, h: 1.6)),
          ),
          const SizedBox(height: 18),
          _ageScale(r, col),
        ]),
      ),
      _sectionTitle('چی کاریگەری هەیە'),
      HCard(
        top: 8,
        child: Column(children: [
          for (var i = 0; i < r.factors.length; i++) _factor(r.factors[i], last: i == r.factors.length - 1),
        ]),
      ),
      _sectionTitle('ڕێکاری باشترکردن'),
      HCard(top: 8, child: Column(children: _advice(r))),
      const SizedBox(height: 10),
      _syncButton(),
    ];
  }

  Widget _ageScale(VitalResult r, Color col) {
    final lo = math.min(r.age, r.realAge.toDouble()) - 6;
    final hi = math.max(r.age, r.realAge.toDouble()) + 6;
    double pos(double v) => clampD((v - lo) / (hi - lo), 0.0, 1.0);
    return LayoutBuilder(builder: (_, c) {
      final w = c.maxWidth;
      Widget pin(double v, String label, Color cl, bool top) => Positioned(
            left: clampD(pos(v) * w - 30, 0.0, w - 60),
            top: top ? 0 : 38,
            width: 60,
            child: Column(children: [
              if (top) Text(label, style: ku(10.5, w: FontWeight.w700, c: cl)),
              if (!top) Container(width: 2, height: 8, color: cl),
              if (top) Container(width: 2, height: 8, color: cl),
              if (!top) VText(label, style: ku(10.5, w: FontWeight.w700, c: cl)),
            ]),
          );
      return SizedBox(
        height: 64,
        child: Stack(children: [
          Positioned(
            left: 0,
            right: 0,
            top: 26,
            child: Container(
              height: 8,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(9),
                gradient: LinearGradient(colors: [HC.ok, HC.c, HC.wn]),
              ),
            ),
          ),
          pin(r.realAge.toDouble(), '${r.realAge}', HC.mu, true),
          pin(r.age, r.age.toStringAsFixed(1), col, false),
          Positioned(left: clampD(pos(r.realAge.toDouble()) * w - 5, 0.0, w - 10), top: 25, child: _knob(HC.mu)),
          Positioned(left: clampD(pos(r.age) * w - 7, 0.0, w - 14), top: 23, child: _knob(col, big: true)),
        ]),
      );
    });
  }

  Widget _knob(Color c, {bool big = false}) => Container(
        width: big ? 14 : 10,
        height: big ? 14 : 10,
        decoration: BoxDecoration(color: c, shape: BoxShape.circle, border: Border.all(color: HC.bg, width: 2)),
      );

  Widget _factor(VitalFactor f, {bool last = false}) {
    final good = f.years < -0.2, bad = f.years > 0.2;
    final col = good ? HC.ok : (bad ? HC.wn : HC.c);
    final icon = f.key == 'sleep'
        ? HI.moon
        : f.key == 'hr'
            ? HI.heart
            : f.key == 'hrv'
                ? HI.wave
                : HI.step;
    final frac = clampD(f.years.abs() / 6, 0.04, 1.0);
    return Padding(
      padding: EdgeInsets.only(bottom: last ? 0 : 14),
      child: Row(children: [
        Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: op(col, .16), shape: BoxShape.circle),
          child: svgIcon(icon, good ? HX.ok : (bad ? HX.wn : HX.c), size: 17, stroke: 2.1),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: VText(f.label, style: ku(13.5, w: FontWeight.w800, c: HC.tx))),
              Text('${f.years > 0 ? '+' : ''}${f.years.toStringAsFixed(1)}', style: ku(13.5, w: FontWeight.w800, c: col)),
              const SizedBox(width: 3),
              VText('ساڵ', style: ku(11, c: HC.mu)),
            ]),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: Container(
                height: 6,
                color: HC.track,
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(widthFactor: frac, child: DecoratedBox(decoration: BoxDecoration(color: col))),
              ),
            ),
            const SizedBox(height: 5),
            VText(f.detail, style: ku(11.5, c: HC.mu)),
          ]),
        ),
      ]),
    );
  }

  List<Widget> _advice(VitalResult r) {
    final worst = [...r.factors]..sort((a, b) => b.years.compareTo(a.years));
    final out = <Widget>[];
    for (final f in worst.take(2)) {
      if (f.years <= 0.2) continue;
      final t = switch (f.key) {
        'sleep' => 'هەوڵ بدە شەوانە ٧ بۆ ٨ کاتژمێر بنووی، و کاتی خەوتن جێگیر بێت.',
        'hr' => 'پیاسەی خێرا و ڕاهێنانی سووک بۆ دڵی ئارامتر.',
        'hrv' => 'هەناسەدانی ئارام و پشووی تەواو؛ لە شەودا ڕاگرتنی ڕاهێنانی قورس.',
        _ => 'هەنگاوەکانت بەرەو ١٠٬٠٠٠ بەرز بکەرەوە.',
      };
      out.add(_tip(t, last: false));
    }
    if (out.isEmpty) out.add(_tip('زۆر باشە! هەمان ڕێکاری ئێستات بپارێزە.', last: false));
    out.add(_tip('ڕاپۆرتەکە هەر ٢١ ڕۆژ جارێک نوێ دەبێتەوە.', last: true));
    return out;
  }

  // ───────────── هاوبەش ─────────────
  Widget _sectionTitle(String s) => Padding(
        padding: const EdgeInsets.only(top: 20),
        child: VText(s, style: ku(14.5, w: FontWeight.w800, c: HC.tx)),
      );

  Widget _chip(Widget icon, String t, Color c) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(color: op(c, .14), borderRadius: BorderRadius.circular(99), border: Border.all(color: op(c, .35))),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          icon,
          const SizedBox(width: 5),
          VText(t, style: ku(11, w: FontWeight.w800, c: c)),
        ]),
      );

  Widget _tip(String t, {bool last = false}) => Padding(
        padding: EdgeInsets.only(bottom: last ? 0 : 10),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            margin: const EdgeInsets.only(top: 7),
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: HC.c, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(child: VText(t, style: ku(12.5, c: HC.mu, h: 1.8))),
        ]),
      );

  Widget _disclaimer() => Padding(
        padding: const EdgeInsets.only(top: 14),
        child: VText(
          'ئەم ژمارەیە خەمڵاندنێکی تەندروستیی گشتییە لە داتای Band ـەکەت. ئامێری پزیشکی نییە و جێگەی پشکنینی دکتۆر ناگرێتەوە.',
          textAlign: TextAlign.center,
          style: ku(11, c: HC.nd, h: 1.8),
        ),
      );
}

class _TodayItem {
  final String name, icon, hex;
  final Color color;
  final bool on;
  const _TodayItem(this.name, this.icon, this.hex, this.color, this.on);
}

/// بازنەی ٢١ پارچە
class _DayRing extends CustomPainter {
  final List<bool> cells;
  final double t;
  _DayRing(this.cells, this.t);

  @override
  void paint(Canvas canvas, Size s) {
    final c = Offset(s.width / 2, s.height / 2);
    final r = s.width / 2 - 14;
    final n = cells.length;
    final seg = 2 * math.pi / n;
    final gap = seg * .22;
    final rect = Rect.fromCircle(center: c, radius: r);
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round
      ..color = HC.track;
    final glow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 22
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9);
    final fill = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < n; i++) {
      final a0 = -math.pi / 2 + i * seg + gap / 2;
      final sw = seg - gap;
      canvas.drawArc(rect, a0, sw, false, track);
      if (!cells[i]) continue;
      final k = clampD(t * n - i, 0, 1);
      if (k <= 0) continue;
      final col = Color.lerp(HC.c, HC.ok, i / (n - 1))!;
      glow.color = op(col, .35 * k);
      fill.color = col;
      canvas.drawArc(rect, a0, sw * k, false, glow);
      canvas.drawArc(rect, a0, sw * k, false, fill);
    }
  }

  @override
  bool shouldRepaint(covariant _DayRing o) => o.t != t || !listEquals(o.cells, cells);
}
