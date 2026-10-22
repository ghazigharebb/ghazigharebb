// VEX Health — شاشەکانی ئاگادارکەرەوەی Band: کاتژمێر · کاتی وەرزش · کاتەکانی نوێژ
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../core/theme.dart';
import 'band_alerts.dart';
import 'prayer_calc.dart';

void openAlarmSheet() => showVSheet<void>(builder: (_) => const _AlarmSheet());
void openTimerSheet() => showVSheet<void>(builder: (_) => const _TimerSheet());
void openPrayerSheet() => showVSheet<void>(builder: (_) => const _PrayerSheet());

// ============================================================
// پارچە هاوبەشەکان
// ============================================================
Widget _ltr(String s, TextStyle st, {TextAlign? align}) =>
    VText(s, style: st, textDirection: TextDirection.ltr, textAlign: align, maxLines: 1);

/// کاتی 12 کاتژمێری: «6:43 PM»
Widget _time12(int mins, {double size = 24, bool showAmPm = true}) {
  final h = mins ~/ 60, m = mins % 60;
  return Row(
    mainAxisSize: MainAxisSize.min,
    textDirection: TextDirection.ltr,
    crossAxisAlignment: CrossAxisAlignment.baseline,
    textBaseline: TextBaseline.alphabetic,
    children: [
      VText(fmt12(h, m), style: nu(size, h: 1.1)),
      if (showAmPm) ...[
        const SizedBox(width: 4),
        VText(ampm(h), style: nu(size * 0.45, c: V.cy)),
      ],
    ],
  );
}

class _Sw extends StatelessWidget {
  const _Sw(this.on, this.onTap);
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          width: 46,
          height: 28,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(color: on ? V.mint : V.track, borderRadius: BorderRadius.circular(99)),
          child: AnimatedAlign(
            duration: const Duration(milliseconds: 220),
            alignment: on ? AlignmentDirectional.centerEnd : AlignmentDirectional.centerStart,
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: kW,
                boxShadow: [BoxShadow(color: vk(0x4D000000), blurRadius: 6, offset: Offset(0, 2))],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// دوگمەی + / − : دابگرە بۆ گۆڕینی خێراتر
class _HoldBtn extends StatefulWidget {
  const _HoldBtn(this.label, this.onStep);
  final String label;

  /// mult = 1 بۆ کلیکی ئاسایی، 5 کاتێک ماوەیەکی زۆر دادەگیرێت
  final void Function(int mult) onStep;

  @override
  State<_HoldBtn> createState() => _HoldBtnState();
}

class _HoldBtnState extends State<_HoldBtn> {
  Timer? _t;
  int _n = 0;
  bool _down = false;

  void _loop() {
    if (!_down) return;
    _n++;
    widget.onStep(_n > 12 ? 5 : 1);
    _t = Timer(Duration(milliseconds: _n > 12 ? 50 : 90), _loop);
  }

  void _press() {
    _down = true;
    _n = 0;
    widget.onStep(1);
    _t?.cancel();
    _t = Timer(const Duration(milliseconds: 380), _loop);
    setState(() {});
  }

  void _release() {
    _down = false;
    _t?.cancel();
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _down = false;
    _t?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _press(),
      onPointerUp: (_) => _release(),
      onPointerCancel: (_) => _release(),
      child: Container(
        height: 38,
        constraints: const BoxConstraints(maxWidth: 66),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: _down ? op(V.cy, 0.22) : V.surf2,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: V.line2),
        ),
        child: VText(widget.label, style: nu(19)),
      ),
    );
  }
}

/// ستوونێک: + ژمارە −
class _Col extends StatelessWidget {
  const _Col({required this.label, required this.value, required this.onStep, this.size = 30});
  final String label;
  final String value;
  final void Function(int mult) onStep;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _HoldBtn('+', (m) => onStep(m)),
          const SizedBox(height: 6),
          _ltr(value, nu(size, h: 1.1)),
          const SizedBox(height: 6),
          _HoldBtn('−', (m) => onStep(-m)),
          const SizedBox(height: 6),
          VText(label, style: ku(11, w: FontWeight.w700, c: V.mu)),
        ],
      ),
    );
  }
}

class _Seg extends StatelessWidget {
  const _Seg({required this.labels, required this.index, required this.onPick});
  final List<String> labels;
  final int index;
  final ValueChanged<int> onPick;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: V.surf2, borderRadius: BorderRadius.circular(14), border: Border.all(color: V.line)),
      child: Row(
        children: [
          for (int i = 0; i < labels.length; i++)
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onPick(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 2),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: i == index ? V.prime : null,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: VText(
                    labels[i],
                    textAlign: TextAlign.center,
                    style: ku(12, w: FontWeight.w800, c: i == index ? V.ink : V.mu, h: 1.3),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

Widget _heading(String t, String sub) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        VText(t, style: ku(20, w: FontWeight.w800)),
        const SizedBox(height: 4),
        VText(sub, style: ku(12, w: FontWeight.w600, c: V.mu, h: 1.7)),
        const SizedBox(height: 12),
      ],
    );

Widget _card({required Widget child, Color? border, Color? fill, EdgeInsets? pad}) => Container(
      margin: const EdgeInsets.only(top: 8),
      padding: pad ?? const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: fill ?? V.surf2,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border ?? V.line),
      ),
      child: child,
    );

// ============================================================
// ١) کاتژمێری لەرین
// ============================================================
class _AlarmSheet extends StatefulWidget {
  const _AlarmSheet();
  @override
  State<_AlarmSheet> createState() => _AlarmSheetState();
}

class _AlarmSheetState extends State<_AlarmSheet> {
  final BandAlerts A = BandAlerts.I;
  bool editing = false;
  int h = 7, m = 0;
  final TextEditingController label = TextEditingController();

  @override
  void dispose() {
    label.dispose();
    super.dispose();
  }

  void _startNew() {
    final d = DateTime.now().add(const Duration(minutes: 1));
    setState(() {
      h = d.hour;
      m = d.minute;
      label.clear();
      editing = true;
    });
  }

  Future<void> _save() async {
    if (A.alarms.length >= 8) {
      toast('زۆرترین ٨ کاتژمێر');
      return;
    }
    final id = A.alarms.isEmpty ? 1 : A.alarms.map((x) => x.id).reduce((a, b) => a > b ? a : b) + 1;
    A.alarms.add(AlarmItem(id: id, h: h, m: m, label: label.text.trim()));
    await A.ensurePermission();
    await A.changed();
    if (!mounted) return;
    setState(() => editing = false);
    toast('کاتژمێرەکە دانرا ✓');
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: A,
      builder: (context, _) => editing ? _editor() : _list(),
    );
  }

  Widget _list() {
    final list = [...A.alarms]..sort((a, b) => (a.h * 60 + a.m).compareTo(b.h * 60 + b.m));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _heading('⏰ کاتژمێری لەرین', 'لە کاتی دیاریکراو Band دەلەرێتەوە.'),
        if (list.isEmpty)
          _card(
            child: Center(child: VText('هیچ کاتژمێرێک دانەنراوە', style: ku(13, w: FontWeight.w700, c: V.mu))),
          ),
        for (final a in list)
          _card(
            child: Row(
              children: [
                _time12(a.h * 60 + a.m),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      VText(a.label.isEmpty ? 'کاتژمێر' : a.label,
                          maxLines: 1, overflow: TextOverflow.ellipsis, style: ku(14, w: FontWeight.w800)),
                      VText('هەموو ڕۆژێک', style: ku(11.5, w: FontWeight.w600, c: V.mu)),
                    ],
                  ),
                ),
                _Sw(a.on, () async {
                  a.on = !a.on;
                  if (a.on) await A.ensurePermission();
                  await A.changed();
                }),
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: () async {
                    A.alarms.removeWhere((x) => x.id == a.id);
                    await A.changed();
                  },
                  child: Container(
                    width: 32,
                    height: 32,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: op(V.coral, 0.12), borderRadius: BorderRadius.circular(10)),
                    child: VText('✕', style: ku(14, c: V.coral)),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: VBtn('داخستن', onTap: () => Navigator.of(context).pop())),
            const SizedBox(width: 10),
            Expanded(child: VBtn('+ زیادکردن', kind: BtnKind.prime, onTap: _startNew)),
          ],
        ),
        const SizedBox(height: 10),
        VBtn('📳 تاقیکردنەوەی لەرین', onTap: () => A.test('📳 تاقیکردنەوە', 'Band دەبێ بلەرێتەوە')),
      ],
    );
  }

  Widget _editor() {
    final pm = h >= 12;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        VText('کاتژمێری نوێ', style: ku(20, w: FontWeight.w800)),
        const SizedBox(height: 14),
        Center(child: _time12(h * 60 + m, size: 42)),
        const SizedBox(height: 12),
        Row(
          children: [
            _Col(
              label: 'خولەک',
              value: m.toString().padLeft(2, '0'),
              onStep: (d) => setState(() => m = ((m + d) % 60 + 60) % 60),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 44),
              child: VText(':', style: nu(26, c: V.mu)),
            ),
            _Col(
              label: 'کاتژمێر',
              value: '${((h + 11) % 12) + 1}',
              onStep: (d) => setState(() => h = ((((h % 12) + d) % 12 + 12) % 12) + (pm ? 12 : 0)),
            ),
          ],
        ),
        const SizedBox(height: 4),
        _Seg(
          labels: const ['AM · بەیانی', 'PM · ئێوارە'],
          index: pm ? 1 : 0,
          onPick: (i) => setState(() => h = h % 12 + (i == 1 ? 12 : 0)),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: label,
          maxLength: 24,
          style: ku(14, w: FontWeight.w700),
          decoration: InputDecoration(
            counterText: '',
            hintText: vxTr('ناو (دڵخوازە) · بۆ نموونە: بەخەبەرهاتن'),
            hintStyle: ku(13, w: FontWeight.w600, c: V.mu),
            filled: true,
            fillColor: V.surf2,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: V.line2)),
            enabledBorder:
                OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: V.line2)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: V.cy)),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: VBtn('گەڕانەوە', onTap: () => setState(() => editing = false))),
            const SizedBox(width: 10),
            Expanded(child: VBtn('پاشەکەوت', kind: BtnKind.prime, onTap: _save)),
          ],
        ),
      ],
    );
  }
}

// ============================================================
// ٢) کاتی وەرزش
// ============================================================
class _TimerSheet extends StatefulWidget {
  const _TimerSheet();
  @override
  State<_TimerSheet> createState() => _TimerSheetState();
}

class _TimerSheetState extends State<_TimerSheet> {
  final BandAlerts A = BandAlerts.I;
  Timer? _t;

  @override
  void initState() {
    super.initState();
    // نوێکردنەوە هەر ~33ms بۆ نیشاندانی میلی چرکە
    _t = Timer.periodic(const Duration(milliseconds: 33), (_) {
      if (mounted && A.timerRunning) setState(() {});
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  bool get _fresh => !A.timerRunning && A.timerLeftMs == 0;

  void _step(String k, int d) {
    if (!_fresh) return;
    setState(() {
      if (k == 'h') A.th = ((A.th + d) % 100 + 100) % 100;
      if (k == 'm') A.tmin = ((A.tmin + d) % 60 + 60) % 60;
      if (k == 's') A.ts = ((A.ts + d) % 60 + 60) % 60;
    });
  }

  void _preset(int secs) {
    if (A.timerRunning) return;
    setState(() {
      A.timerLeftMs = 0;
      A.th = secs ~/ 3600;
      A.tmin = secs % 3600 ~/ 60;
      A.ts = secs % 60;
    });
  }

  @override
  Widget build(BuildContext context) {
    final ms = A.timerRemainingMs;
    final hh = ms ~/ 3600000, mm = ms % 3600000 ~/ 60000, ss = ms % 60000 ~/ 1000, x = ms % 1000;
    String p(int n) => n.toString().padLeft(2, '0');
    final run = A.timerRunning;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        VText('⏱️ کاتی وەرزش', style: ku(20, w: FontWeight.w800)),
        const SizedBox(height: 12),
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.fromLTRB(8, 18, 8, 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            color: V.surf2,
            gradient: RadialGradient(center: Alignment.topCenter, radius: 1.2, colors: [op(V.cy, 0.16), Colors.transparent]),
            border: Border.all(color: run ? V.cy : V.line2),
            boxShadow: run ? [BoxShadow(color: op(V.cy, 0.3), blurRadius: 26, spreadRadius: -8)] : null,
          ),
          child: Column(
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  textDirection: TextDirection.ltr,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    VText('${p(hh)}:${p(mm)}:${p(ss)}', style: nu(36, h: 1.1)),
                    VText('.${x.toString().padLeft(3, '0')}', style: nu(22, c: V.cy)),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              VText('کاتژمێر : خولەک : چرکە . میلی چرکە', style: ku(11, w: FontWeight.w700, c: V.mu)),
              if (_fresh) ...[
                const SizedBox(height: 12),
                Row(
                  textDirection: TextDirection.ltr,
                  children: [
                    _Col(label: 'کاتژمێر', value: p(A.th), onStep: (d) => _step('h', d)),
                    Padding(padding: const EdgeInsets.only(bottom: 44), child: VText(':', style: nu(24, c: V.mu))),
                    _Col(label: 'خولەک', value: p(A.tmin), onStep: (d) => _step('m', d)),
                    Padding(padding: const EdgeInsets.only(bottom: 44), child: VText(':', style: nu(24, c: V.mu))),
                    _Col(label: 'چرکە', value: p(A.ts), onStep: (d) => _step('s', d)),
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final e in const [['1 خولەک', 60], ['5 خولەک', 300], ['10 خولەک', 600], ['30 خولەک', 1800]])
              GestureDetector(
                onTap: () => _preset(e[1] as int),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
                  decoration: BoxDecoration(
                    color: V.surf2,
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(color: V.line2),
                  ),
                  child: VText(e[0] as String, style: ku(12, w: FontWeight.w800)),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Center(child: VText('دوگمەی + و − دابگرە بۆ گۆڕینی خێراتر', style: ku(11.5, w: FontWeight.w600, c: V.mu))),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: VBtn('سفرکردنەوە', onTap: () async {
                await A.timerReset();
                if (mounted) setState(() {});
              }),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: VBtn(
                run ? 'ڕاگرتن' : (A.timerLeftMs > 0 ? 'بەردەوامبوون' : 'دەستپێبکە'),
                kind: BtnKind.prime,
                onTap: () async {
                  if (run) {
                    await A.timerPause();
                  } else if (!await A.timerStart()) {
                    toast('کات دیاری بکە');
                  }
                  if (mounted) setState(() {});
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ============================================================
// ٣) کاتەکانی نوێژ
// ============================================================
class _PrayerSheet extends StatefulWidget {
  const _PrayerSheet();
  @override
  State<_PrayerSheet> createState() => _PrayerSheetState();
}

class _PrayerSheetState extends State<_PrayerSheet> {
  final BandAlerts A = BandAlerts.I;
  Timer? _t;
  bool _locating = false;

  @override
  void initState() {
    super.initState();
    _t = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
    A.refreshSite(); // کاتەکان لە IslamicFinder نوێ بکەرەوە
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  String _left(Duration d) {
    final s = d.inSeconds < 0 ? 0 : d.inSeconds;
    String p(int n) => n.toString().padLeft(2, '0');
    return '${p(s ~/ 3600)}:${p(s % 3600 ~/ 60)}:${p(s % 60)}';
  }

  Future<void> _useGps() async {
    setState(() => _locating = true);
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
        toast('ڕێگەپێدانی شوێن نەدرا');
        return;
      }
      if (!await Geolocator.isLocationServiceEnabled()) {
        toast('GPS ـی مۆبایل بکەرەوە');
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.low, timeLimit: Duration(seconds: 12)),
      );
      A.city = 'gps';
      A.gpsLat = pos.latitude;
      A.gpsLng = pos.longitude;
      await A.changed();
      toast('شوێنی ئێستا دیاری کرا ✓');
    } catch (_) {
      toast('نەتوانرا شوێن بدۆزرێتەوە');
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: A,
      builder: (context, _) {
        final now = DateTime.now();
        final t = A.prayerTimes(now);
        final nx = A.nextPrayer(now);
        final nextToday = nx.at.day == now.day;
        final place = A.place;
        final site = A.fromSite;
        final gps = A.city == 'gps';
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _heading('🕌 کاتەکانی نوێژ',
                'ئارەزوومەندانە: هەر کاتێک بتەوێت چالاکی بکە. Band لە کاتی بانگ یان پێش بانگ دەلەرێتەوە.'),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () async {
                A.prayerOn = !A.prayerOn;
                if (A.prayerOn) await A.ensurePermission();
                await A.changed();
              },
              child: _card(
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(color: op(V.mint, 0.16), borderRadius: BorderRadius.circular(12)),
                      child: const VText('🔔', style: TextStyle(fontSize: 19)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          VText('لەرینی کاتی نوێژ', style: ku(14, w: FontWeight.w800)),
                          VText(A.prayerOn ? 'چالاکە' : 'ناچالاکە', style: ku(11.5, w: FontWeight.w600, c: V.mu)),
                        ],
                      ),
                    ),
                    _Sw(A.prayerOn, () async {
                      A.prayerOn = !A.prayerOn;
                      if (A.prayerOn) await A.ensurePermission();
                      await A.changed();
                    }),
                  ],
                ),
              ),
            ),
            // شار
            _card(
              pad: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  dropdownColor: V.sheet,
                  value: gps ? 'gps' : A.city,
                  icon: Icon(Icons.keyboard_arrow_down_rounded, color: V.mu),
                  style: ku(14, w: FontWeight.w700),
                  items: [
                    for (final c in kCities) DropdownMenuItem(value: c.key, child: VText(c.name)),
                    DropdownMenuItem(value: 'gps', child: VText(gps ? '📍 شوێنی ئێستای من' : '📍 شوێنی ئێستای من (GPS)')),
                  ],
                  onChanged: (v) async {
                    if (v == null) return;
                    if (v == 'gps') {
                      await _useGps();
                    } else {
                      A.city = v;
                      await A.changed();
                      if (v == 'erbil') A.refreshSite();
                    }
                  },
                ),
              ),
            ),
            if (_locating)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Center(child: VText('شوێنەکەت دەدۆزرێتەوە…', style: ku(12, w: FontWeight.w700, c: V.cy))),
              ),
            // داهاتوو
            Container(
              margin: const EdgeInsets.only(top: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(colors: [op(V.mint, 0.16), op(V.cy, 0.08)]),
                border: Border.all(color: op(V.mint, 0.3)),
              ),
              child: Column(
                children: [
                  VText('داهاتوو: ${kPrayerNames[nx.key]![0]}${nextToday ? '' : ' (سبەی)'}',
                      style: ku(12, w: FontWeight.w700, c: V.mu)),
                  const SizedBox(height: 2),
                  _ltr(_left(nx.at.difference(now)), nu(26)),
                ],
              ),
            ),
            const SizedBox(height: 10),
            _Seg(
              labels: const ['لە کاتی بانگ', '5 خولەک پێش', '10 خولەک پێش', '15 خولەک پێش'],
              index: const [0, 5, 10, 15].indexOf(A.lead).clamp(0, 3).toInt(),
              onPick: (i) async {
                A.lead = const [0, 5, 10, 15][i];
                await A.changed();
              },
            ),
            for (final k in kPrayerNames.keys)
              _card(
                border: k == nx.key && nextToday ? V.mint : V.line,
                fill: k == nx.key && nextToday ? op(V.mint, 0.1) : V.surf2,
                child: Row(
                  children: [
                    VText(kPrayerNames[k]![1], style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          VText(kPrayerNames[k]![0], style: ku(14, w: FontWeight.w800)),
                          if (k == 'sunrise') VText('تەنها زانیاری', style: ku(11, w: FontWeight.w600, c: V.mu)),
                        ],
                      ),
                    ),
                    _time12(t[k]!, size: 17),
                    if (k != 'sunrise') ...[
                      const SizedBox(width: 10),
                      _Sw(A.prayerItems[k] == true, () async {
                        A.prayerItems[k] = !(A.prayerItems[k] == true);
                        await A.changed();
                      }),
                    ] else
                      const SizedBox(width: 56),
                  ],
                ),
              ),
            const SizedBox(height: 12),
            // سەرچاوە
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: V.surf2,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: site ? op(V.mint, 0.35) : V.line),
              ),
              child: Column(
                children: [
                  VText(
                    site
                        ? '✓ کاتەکان لە IslamicFinder وەرگیراون (${place.name})'
                        : (A.city == 'erbil'
                            ? (A.siteBusy
                                ? 'پەیوەندی بە IslamicFinder دەکرێت…'
                                : (A.siteFailed
                                    ? 'IslamicFinder بەردەست نییە — ژماردنی ناوخۆیی بەکاردێت'
                                    : 'ژماردنی ناوخۆیی (${place.name})'))
                            : 'ژماردنی ناوخۆیی (${place.name}) · ڕێگای Muslim World League'),
                    textAlign: TextAlign.center,
                    style: ku(12, w: FontWeight.w700, c: site ? V.mint : V.mu, h: 1.7),
                  ),
                  if (A.city == 'erbil') ...[
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: A.siteBusy
                          ? null
                          : () async {
                              final ok = await A.refreshSite(force: true);
                              toast(ok ? 'کاتەکان نوێ کرانەوە ✓' : 'نەتوانرا نوێ بکرێتەوە');
                            },
                      child: VText('↻ نوێکردنەوە لە IslamicFinder',
                          style: ku(12.5, w: FontWeight.w800, c: A.siteBusy ? V.mu : V.cy)),
                    ),
                  ],
                  const SizedBox(height: 4),
                  VText('فەجر 18° · عیشا 17° · عەسر شافیعی. هەر ڕۆژێک خۆکارانە نوێ دەبێتەوە.',
                      textAlign: TextAlign.center, style: ku(10.5, w: FontWeight.w600, c: V.mu, h: 1.7)),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(child: VBtn('داخستن', onTap: () => Navigator.of(context).pop())),
                const SizedBox(width: 10),
                Expanded(
                  child: VBtn('📳 تاقیکردنەوە',
                      kind: BtnKind.prime, onTap: () => A.test('🕌 تاقیکردنەوەی کاتی نوێژ', 'Band دەبێ بلەرێتەوە')),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
