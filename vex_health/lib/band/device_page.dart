// VEX Health — پەڕەی «ئامێرەکانم» (VEX Band V8)
//
// پەڕەیەکی تەنیا: هەموو شتێک لێرەدایە. بەکارهێنان: pushPage(const DevicePage()).
//  • دۆخەکان: پەیوەندیکراو / هاوکات دەکرێت / دەگەڕێت / پچڕاو (لە BandState.I ـەوە)
//  • باتری، ڕێکخستنەکان، زانیاری ئامێر (MAC، سۆفتوێر)، لابردنی ئامێر
//
// کارایی (بێ لاگ): هەموو ئەنیمەیشنەکان بە یەک AnimationController و تەنها لە ناو RepaintBoundary ـی
// بچووک؛ هیچ blur ی ئەنیمەیتکراو نییە؛ وێنەی Band پێشوەخت precache دەکرێت.
import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../alerts/alerts_sheets.dart';
import '../alerts/band_alerts.dart';
import '../core/icons.dart';
import '../core/theme.dart';
import 'band_state.dart';
import 'ble/vex_ble.dart';
import 'band_widgets.dart';

// ============================================================
// دۆخی ئامێر (بەپێی ڕێکخستنی بەکارهێنەر؛ لە ئامێر هەڵدەگیرێت)
// ============================================================
class DeviceStore extends ChangeNotifier {
  DeviceStore._();
  static final DeviceStore I = DeviceStore._();

  static const String _key = 'vex_device';
  static const List<String> hrOptions = ['هەر 5 خولەک', 'هەر 10 خولەک', 'هەر 30 خولەک', 'کوژاوە'];
  static const List<String> wristOptions = ['دەستی چەپ', 'دەستی ڕاست'];

  String name = 'VEX Band';
  int battery = 25; // لەگەڵ BLE ی ڕاستەقینە لێرە نوێ بکەرەوە: DeviceStore.I.setBattery(..)
  String hr = 'هەر 10 خولەک';
  String wrist = 'دەستی چەپ';
  bool notif = true;
  bool sleepMon = true;
  String fwText = 'پشکنینی وەشانی نوێ';
  bool loaded = false;
  SharedPreferences? _sp;

  Future<void> load() async {
    if (loaded) return;
    try {
      _sp = await SharedPreferences.getInstance();
      final raw = _sp!.getString(_key);
      if (raw != null) {
        final j = jsonDecodeSafe(raw);
        name = (j['name'] ?? name) as String;
        battery = ((j['battery'] ?? battery) as num).toInt().clamp(0, 100);
        hr = hrOptions.contains(j['hr']) ? j['hr'] as String : hr;
        wrist = wristOptions.contains(j['wrist']) ? j['wrist'] as String : wrist;
        notif = j['notif'] != false;
        sleepMon = j['sleepMon'] != false;
      }
    } catch (_) {}
    loaded = true;
    notifyListeners();
  }

  Map<String, dynamic> jsonDecodeSafe(String s) {
    try {
      final v = _jsonDecode(s);
      return v is Map<String, dynamic> ? v : <String, dynamic>{};
    } catch (_) {
      return <String, dynamic>{};
    }
  }

  void setBattery(int v) {
    battery = v.clamp(0, 100);
    _save();
  }

  void _save() {
    notifyListeners();
    try {
      _sp?.setString(_key, _jsonEncode({'name': name, 'battery': battery, 'hr': hr, 'wrist': wrist, 'notif': notif, 'sleepMon': sleepMon}));
    } catch (_) {}
  }

  void update(void Function() f) {
    f();
    _save();
  }
}

dynamic _jsonDecode(String s) => jsonDecode(s);
String _jsonEncode(Object o) => jsonEncode(o);

// ============================================================
// پەڕەکە
// ============================================================
enum _St { on, sync, search, off }

const String _kBandImg = 'assets/brand/vex_band.webp';

Color _stColor(_St s, bool low) {
  switch (s) {
    case _St.on:
    case _St.sync:
      return low ? V.amber : V.mint;
    case _St.search:
      return V.cy;
    case _St.off:
      return V.coral;
  }
}

class DevicePage extends StatefulWidget {
  const DevicePage({super.key});

  @override
  State<DevicePage> createState() => _DevicePageState();
}

class _DevicePageState extends State<DevicePage> with SingleTickerProviderStateMixin {
  final DeviceStore D = DeviceStore.I;
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(seconds: 2800))..repeat();
  bool _syncing = false;
  double _syncP = 0;
  Timer? _syncT;
  bool _buzz = false;
  bool _imgReady = false;

  @override
  void initState() {
    super.initState();
    D.load();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_imgReady) {
      _imgReady = true;
      precacheImage(const AssetImage(_kBandImg), context).catchError((_) {});
    }
  }

  @override
  void dispose() {
    _syncT?.cancel();
    _c.dispose();
    super.dispose();
  }

  _St get _st {
    if (_syncing) return _St.sync;
    if (BandState.I.reconnecting) return _St.search;
    return BandState.I.connected ? _St.on : _St.off;
  }

  String _hm(DateTime d) => '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  void _sync() {
    if (_syncing || !BandState.I.connected) return;
    if (VexBand.I.linked) {
      setState(() {
        _syncing = true;
        _syncP = 0;
      });
      VexBand.I.syncAll(onProgress: (v) {
        if (mounted) setState(() => _syncP = v);
      }).whenComplete(() {
        BandState.I.lastSync = _hm(DateTime.now());
        if (mounted) {
          setState(() {
            _syncing = false;
            _syncP = 0;
          });
          toast('هەموو داتاکان هاوکات کران ✓');
        }
      });
      return;
    }
    setState(() {
      _syncing = true;
      _syncP = 0;
    });
    _syncT?.cancel();
    _syncT = Timer.periodic(const Duration(milliseconds: 90), (t) {
      _syncP += 0.04 + math.Random().nextDouble() * 0.07;
      if (_syncP >= 1) {
        t.cancel();
        BandState.I.setConnected(true);
        BandState.I.lastSync = _hm(DateTime.now());
        if (mounted) {
          setState(() {
            _syncing = false;
            _syncP = 0;
          });
          toast('هەموو داتاکان هاوکات کران ✓');
        }
      } else if (mounted) {
        setState(() {});
      }
    });
  }

  Future<void> _find() async {
    setState(() => _buzz = true);
    toast('Band ـەکەت دەلەرێتەوە…');
    HapticFeedback.heavyImpact();
    BandLink.vibrate();
    if (VexBand.I.linked) VexBand.I.find().catchError((_) {});
    await Future<void>.delayed(const Duration(milliseconds: 1100));
    if (mounted) setState(() => _buzz = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: V.bg,
      body: ListenableBuilder(
        listenable: Listenable.merge([BandState.I, D]),
        builder: (context, _) {
          final st = _st;
          final low = D.battery <= 20;
          final col = _stColor(st, low);
          final dim = st == _St.off || st == _St.search;
          return Stack(
            children: [
              // پاشبنەما: درەوشانەوەی ڕەنگی دۆخ
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(0, -0.55),
                      radius: 0.9,
                      colors: [op(col, 0.22), Colors.transparent],
                    ),
                  ),
                ),
              ),
              SafeArea(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 34),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 440),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _top(),
                          _hero(st, col, low),
                          IgnorePointer(
                            ignoring: dim,
                            child: AnimatedOpacity(
                              duration: const Duration(milliseconds: 250),
                              opacity: dim ? 0.45 : 1,
                              child: _details(low),
                            ),
                          ),
                          if (kDebugMode) _demo(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ---------- سەرەوە ----------
  Widget _top() {
    Widget ib(IconData i, VoidCallback f, String tip) => Semantics(
          label: tip,
          button: true,
          child: GestureDetector(
            onTap: f,
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: V.surf,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: V.line),
              ),
              child: Icon(i, size: 20, color: V.tx),
            ),
          ),
        );
    return Row(
      children: [
        ib(Icons.chevron_right_rounded, () => Navigator.of(context).maybePop(), 'گەڕانەوە'),
        Expanded(child: Center(child: VText('ئامێرەکانم', style: ku(18, w: FontWeight.w800)))),
        ib(Icons.edit_outlined, _rename, 'گۆڕینی ناو'),
      ],
    );
  }

  // ---------- Hero ----------
  Widget _hero(_St st, Color col, bool low) {
    final off = st == _St.off || st == _St.search;
    final pill = switch (st) {
      _St.on => 'پەیوەندیکراو',
      _St.sync => 'هاوکات دەکرێت…',
      _St.search => 'دەگەڕێت بۆ Band…',
      _St.off => 'پەیوەندی پچڕاوە',
    };
    return Column(
      children: [
        const SizedBox(height: 6),
        SizedBox(
          width: 300,
          height: 300,
          child: RepaintBoundary(
            child: AnimatedBuilder(
              animation: _c,
              builder: (context, _) {
                final t = _c.value * 2800; // چرکە
                final fl = off ? 0.0 : math.sin(t / 7 * 2 * math.pi);
                final yaw = off ? -0.31 : fl * 0.52;
                final lift = off ? 10.0 : -8 * (0.5 - 0.5 * math.cos(t / 3.5 * 2 * math.pi));
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    CustomPaint(
                      size: const Size(300, 300),
                      painter: _StagePainter(
                        t: t,
                        color: col,
                        search: st == _St.search,
                        on: !off,
                        syncP: st == _St.sync ? _syncP.clamp(0.0, 1.0) : -1,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(40, 26, 40, 44),
                      child: Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.identity()
                          ..setEntry(3, 2, 0.0011)
                          ..rotateY(yaw)
                          ..translate(_buzz ? math.sin(t * 90) * 5 : 0.0, lift),
                        child: ColorFiltered(
                          colorFilter: off
                              ? const ColorFilter.matrix(<double>[
                                  0.17, 0.33, 0.06, 0, 0, //
                                  0.17, 0.33, 0.06, 0, 0,
                                  0.17, 0.33, 0.06, 0, 0,
                                  0, 0, 0, 0.75, 0,
                                ])
                              : const ColorFilter.mode(Colors.transparent, BlendMode.dst),
                          child: Image.asset(
                            _kBandImg,
                            fit: BoxFit.contain,
                            gaplessPlayback: true,
                            filterQuality: FilterQuality.medium,
                            errorBuilder: (c, e, s) => const Center(child: VText('VEX', style: TextStyle(fontSize: 40))),
                          ),
                        ),
                      ),
                    ),
                    PositionedDirectional(
                      top: 24,
                      end: 34,
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: V.bg,
                          border: Border.all(color: col, width: 2),
                          boxShadow: [BoxShadow(color: op(col, 0.5), blurRadius: 14)],
                        ),
                        child: Icon(
                          switch (st) {
                            _St.off => Icons.link_off_rounded,
                            _St.search => Icons.search_rounded,
                            _St.sync => Icons.sync_rounded,
                            _St.on => Icons.bluetooth_connected_rounded,
                          },
                          size: 20,
                          color: col,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 6),
        VText(D.name, style: ku(24, w: FontWeight.w800, h: 1.3)),
        VText.rich(
          TextSpan(children: [
            const TextSpan(text: 'مۆدێلی '),
            TextSpan(text: 'V8', style: nu(12, w: FontWeight.w700, c: V.mu)),
          ]),
          style: ku(12, w: FontWeight.w600, c: V.mu),
        ),
        const SizedBox(height: 12),
        Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
            decoration: BoxDecoration(
              color: op(col, 0.14),
              borderRadius: BorderRadius.circular(99),
              border: Border.all(color: op(col, 0.55), width: 1.5),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                VText(pill, style: ku(15, w: FontWeight.w800, c: col, h: 1.3)),
                const SizedBox(width: 8),
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: col, boxShadow: [BoxShadow(color: col, blurRadius: 8)]),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        _subLine(st),
        if (st == _St.off) _tips(),
        const SizedBox(height: 16),
        _cta(st),
      ],
    );
  }

  Widget _subLine(_St st) {
    String t;
    switch (st) {
      case _St.on:
        t = BandState.I.lastSync.isEmpty ? 'پەیوەندیکراو' : 'دوایین هاوکاتکردن: ${BandState.I.lastSync}';
        break;
      case _St.sync:
        t = 'داتای دڵ، هەنگاو و خەو وەردەگیرێت… ${(math.min(_syncP, 1) * 100).round()}%';
        break;
      case _St.search:
        t = 'Band ـەکەت نزیک مۆبایلەکەت بهێنە';
        break;
      case _St.off:
        t = BandState.I.lastSync.isEmpty ? 'هێشتا هاوکات نەکراوە' : 'دوایین هاوکاتکردن: ${BandState.I.lastSync}';
        break;
    }
    return Center(child: VText(t, textAlign: TextAlign.center, textDirection: TextDirection.rtl, style: ku(13, c: V.mu, h: 1.7)));
  }

  Widget _tips() {
    return Container(
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: op(V.coral, 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: op(V.coral, 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          VText('بۆچی پەیوەندی نییە؟', style: ku(13, w: FontWeight.w800, h: 1.8)),
          for (final t in const ['Bluetooth ـی مۆبایلەکەت هەڵکراوە؟', 'Band لە 10 مەتر نزیکترە؟', 'باتری Band تەواو نەبووە؟'])
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Row(
                children: [
                  Container(width: 5, height: 5, decoration: BoxDecoration(shape: BoxShape.circle, color: V.coral)),
                  const SizedBox(width: 8),
                  Expanded(child: VText(t, style: ku(13, h: 1.8))),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _btn(String label, IconData icon, VoidCallback? onTap, {bool primary = false}) {
    final fg = primary ? V.ink : V.tx;
    return Expanded(
      child: Press(
        onTap: onTap,
        child: Opacity(
          opacity: onTap == null ? 0.55 : 1,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              gradient: primary ? V.prime : null,
              color: primary ? null : V.surf,
              borderRadius: BorderRadius.circular(16),
              border: primary ? null : Border.all(color: V.line),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 18, color: fg),
                const SizedBox(width: 8),
                VText(label, style: ku(14, w: FontWeight.w800, c: fg, h: 1.3)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _cta(_St st) {
    switch (st) {
      case _St.on:
        return Row(children: [
          _btn('هاوکاتکردن', Icons.sync_rounded, _sync, primary: true),
          const SizedBox(width: 10),
          _btn('دۆزینەوەی Band', Icons.my_location_rounded, _find),
        ]);
      case _St.off:
        return Row(children: [_btn('پەیوەندیکردنەوە', Icons.bluetooth_rounded, () => BandState.I.reconnect(), primary: true)]);
      case _St.sync:
        return Row(children: [_btn('تکایە چاوەڕێ بکە…', Icons.hourglass_top_rounded, null)]);
      case _St.search:
        return Row(children: [_btn('دەگەڕێت…', Icons.search_rounded, null)]);
    }
  }

  // ---------- وردەکارییەکان ----------
  Widget _details(bool low) {
    final bc = D.battery <= 20 ? V.coral : D.battery <= 40 ? V.amber : V.mint;
    final days = (D.battery / 12).round().clamp(0, 9);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // باتری
        _card(
          Row(
            children: [
              Container(
                width: 46,
                height: 24,
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(border: Border.all(color: V.tx, width: 2.5), borderRadius: BorderRadius.circular(6)),
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: FractionallySizedBox(
                    widthFactor: D.battery / 100,
                    heightFactor: 1,
                    child: DecoratedBox(decoration: BoxDecoration(color: bc, borderRadius: BorderRadius.circular(2))),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    VText('${D.battery}%', textDirection: TextDirection.ltr, style: nu(24, h: 1.2)),
                    VText(low ? 'باتری کەمە، بیخەرە سەر شەحن' : 'نزیکەی $days ڕۆژ ماوە', style: ku(12, c: V.mu, h: 1.5)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: op(bc, 0.14), borderRadius: BorderRadius.circular(99)),
                child: VText(D.battery <= 20 ? 'کەم' : D.battery <= 40 ? 'مامناوەند' : 'باش', style: ku(12, w: FontWeight.w800, c: bc, h: 1.3)),
              ),
            ],
          ),
        ),
        _label('ڕێکخستنەکان'),
        _card(Column(children: [
          _row(_I.cog, V.cy, 'تایبەتمەندییەکانی Band', 'ئامانج، زەنگ، وەرزش و PPI', onTap: () => openAlarmSheet()),
          _row(_I.bell, V.amber, 'لەرینەوە بۆ ئاگادارکردنەوە', 'پەیام و پەیوەندی',
              sw: D.notif, onTap: () => D.update(() => D.notif = !D.notif)),
          _row(_I.heart, V.coral, 'پێوانی خۆکاری دڵ', 'چەند جار لە کاتژمێرێکدا', value: D.hr, onTap: () => _pick('پێوانی خۆکاری دڵ', DeviceStore.hrOptions, D.hr, (v) => D.hr = v)),
          _row(_I.moon, V.violet, 'چاودێری خەو و SpO₂ بە شەو', 'باتری زیاتر بەکاردێنێت',
              sw: D.sleepMon, onTap: () => D.update(() => D.sleepMon = !D.sleepMon)),
          _row(_I.hand, V.mint, 'کام دەست', null, value: D.wrist, onTap: () => _pick('Band لە کام دەستە؟', DeviceStore.wristOptions, D.wrist, (v) => D.wrist = v), last: true),
        ])),
        _label('زانیاری ئامێر'),
        _card(Column(children: [
          _row(_I.watch, V.cy, 'مۆدێل', null, value: 'VEX Band V8', valueLtr: true),
          _row(_I.link, V.violet, 'ناونیشانی MAC', null, value: 'C9:B5:55:CB:61:••', valueLtr: true, onTap: () {
            Clipboard.setData(const ClipboardData(text: 'C9:B5:55:CB:61'));
            toast('کۆپی کرا ✓');
          }),
          _row(_I.up, V.mint, 'نوێکردنەوەی سۆفتوێر', D.fwText, onTap: _checkFw, last: true),
        ])),
        const SizedBox(height: 18),
        Press(
          onTap: _unpair,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 13),
            alignment: Alignment.center,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: op(V.coral, 0.35))),
            child: VText('لابردنی ئامێر', style: ku(14, w: FontWeight.w800, c: V.coral, h: 1.3)),
          ),
        ),
      ],
    );
  }

  Widget _card(Widget child) => Container(
        margin: const EdgeInsets.only(top: 14),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(color: V.surf, borderRadius: BorderRadius.circular(24), border: Border.all(color: V.line)),
        child: child,
      );

  Widget _label(String t) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 20, 4, 0),
        child: VText(t, style: ku(12, w: FontWeight.w800, c: V.mu)),
      );

  Widget _row(String icon, Color color, String title, String? sub,
      {String? value, bool valueLtr = false, bool? sw, VoidCallback? onTap, bool last = false}) {
    final hex = '#${(color.value & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';
    final body = Container(
      padding: const EdgeInsets.symmetric(vertical: 13),
      decoration: BoxDecoration(border: last ? null : Border(bottom: BorderSide(color: V.line))),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: op(color, 0.14), borderRadius: BorderRadius.circular(12)),
            child: svgIcon(icon, hex, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                VText(title, style: ku(14, w: FontWeight.w700, h: 1.4)),
                if (sub != null) VText(sub, style: ku(12, c: V.mu, h: 1.4)),
              ],
            ),
          ),
          if (value != null)
            VText(value, textDirection: valueLtr ? TextDirection.ltr : null, style: valueLtr ? nu(12.5, w: FontWeight.w700, c: V.mu) : ku(13, w: FontWeight.w700, c: V.mu)),
          if (sw != null)
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: 46,
              height: 28,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(color: sw ? V.mint : V.track, borderRadius: BorderRadius.circular(99)),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 220),
                alignment: sw ? AlignmentDirectional.centerEnd : AlignmentDirectional.centerStart,
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: kW),
                ),
              ),
            )
          else if (onTap != null && value == null || (onTap != null && value != null && !valueLtr))
            Padding(padding: const EdgeInsetsDirectional.only(start: 6), child: VText('‹', style: ku(18, c: V.mu))),
        ],
      ),
    );
    return onTap == null ? body : Press(onTap: onTap, scale: 0.99, child: body);
  }

  // ---------- کردارەکان ----------
  void _pick(String title, List<String> opts, String cur, void Function(String) set) {
    showVSheet<void>(
      builder: (ctx) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          VText(title, textAlign: TextAlign.center, style: ku(18, w: FontWeight.w800)),
          const SizedBox(height: 14),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final o in opts)
                GestureDetector(
                  onTap: () {
                    D.update(() => set(o));
                    Navigator.of(ctx).pop();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: o == cur ? op(V.mint, 0.12) : V.surf2,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: o == cur ? V.mint : V.line),
                    ),
                    child: VText(o, style: ku(13, w: FontWeight.w700, c: o == cur ? V.mint : V.tx, h: 1.3)),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  void _rename() {
    final ctl = TextEditingController(text: D.name);
    showVSheet<void>(
      builder: (ctx) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          VText('ناوی Band', textAlign: TextAlign.center, style: ku(18, w: FontWeight.w800)),
          const SizedBox(height: 14),
          TextField(
            controller: ctl,
            maxLength: 20,
            autofocus: true,
            style: ku(15, w: FontWeight.w700),
            decoration: InputDecoration(
              counterText: '',
              filled: true,
              fillColor: V.surf2,
              contentPadding: const EdgeInsets.all(14),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: V.line2)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: V.line2)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: V.cy)),
            ),
          ),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(child: VBtn('پاشگەزبوونەوە', onTap: () => Navigator.of(ctx).pop())),
            const SizedBox(width: 10),
            Expanded(
              child: VBtn('پاشەکەوت', kind: BtnKind.prime, onTap: () {
                final v = ctl.text.trim();
                if (v.isNotEmpty) D.update(() => D.name = v);
                Navigator.of(ctx).pop();
              }),
            ),
          ]),
        ],
      ),
    ).whenComplete(ctl.dispose);
  }

  Future<void> _checkFw() async {
    D.update(() => D.fwText = 'دەپشکنرێت…');
    await Future<void>.delayed(const Duration(milliseconds: 1400));
    D.update(() => D.fwText = 'نوێترین وەشانت هەیە ✓');
  }

  void _unpair() {
    showVSheet<void>(
      builder: (ctx) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          VText('لابردنی ${D.name}؟', textAlign: TextAlign.center, style: ku(18, w: FontWeight.w800)),
          const SizedBox(height: 8),
          VText('داتا کۆنەکانت دەمێننەوە، بەڵام Band هاوکات نابێت تا دووبارە پەیوەندی بکەیتەوە.',
              textAlign: TextAlign.center, style: ku(13, c: V.mu, h: 1.8)),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: VBtn('نەخێر', onTap: () => Navigator.of(ctx).pop())),
            const SizedBox(width: 10),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  Navigator.of(ctx).pop();
                  BandState.I.setConnected(false);
                  toast('Band لابرا');
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: V.coral, borderRadius: BorderRadius.circular(15)),
                  child: VText('بەڵێ، لایببە', style: ku(14, w: FontWeight.w800, c: Colors.white, h: 1.3)),
                ),
              ),
            ),
          ]),
        ],
      ),
    );
  }

  // تەنها لە دۆخی گەشەپێدان (debug)
  Widget _demo() {
    Widget chip(String t, VoidCallback f) => GestureDetector(
          onTap: f,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(99), border: Border.all(color: V.line2)),
            child: VText(t, style: ku(11, w: FontWeight.w700, c: V.mu, h: 1.3)),
          ),
        );
    return Padding(
      padding: const EdgeInsets.only(top: 22),
      child: Column(children: [
        VText('دیمۆ: تاقیکردنەوەی دۆخەکان', style: ku(11, c: V.mu)),
        const SizedBox(height: 6),
        Wrap(spacing: 6, runSpacing: 6, alignment: WrapAlignment.center, children: [
          chip('پەیوەندیکراو', () {
            if (D.battery < 20) D.setBattery(25);
            BandState.I.setConnected(true);
          }),
          chip('پچڕاو', () => BandState.I.setConnected(false, lastSync: _hm(DateTime.now()))),
          chip('باتری کەم', () {
            D.setBattery(12);
            BandState.I.setConnected(true);
          }),
        ]),
      ]),
    );
  }
}

// ============================================================
// ئایکۆنەکان (SVG ی ناوخۆیی)
// ============================================================
class _I {
  static const cog =
      '<circle cx="12" cy="12" r="3"/><path d="M19.4 15a1.7 1.7 0 0 0 .3 1.8l.1.1a2 2 0 1 1-2.8 2.8l-.1-.1a1.7 1.7 0 0 0-1.8-.3 1.7 1.7 0 0 0-1 1.5V21a2 2 0 0 1-4 0v-.1a1.7 1.7 0 0 0-1.1-1.5 1.7 1.7 0 0 0-1.8.3l-.1.1a2 2 0 1 1-2.8-2.8l.1-.1a1.7 1.7 0 0 0 .3-1.8 1.7 1.7 0 0 0-1.5-1H3a2 2 0 0 1 0-4h.1a1.7 1.7 0 0 0 1.5-1.1 1.7 1.7 0 0 0-.3-1.8l-.1-.1a2 2 0 1 1 2.8-2.8l.1.1a1.7 1.7 0 0 0 1.8.3H9a1.7 1.7 0 0 0 1-1.5V3a2 2 0 0 1 4 0v.1a1.7 1.7 0 0 0 1 1.5 1.7 1.7 0 0 0 1.8-.3l.1-.1a2 2 0 1 1 2.8 2.8l-.1.1a1.7 1.7 0 0 0-.3 1.8V9a1.7 1.7 0 0 0 1.5 1H21a2 2 0 0 1 0 4h-.1a1.7 1.7 0 0 0-1.5 1z"/>';
  static const bell = '<path d="M6 8a6 6 0 0 1 12 0c0 7 3 9 3 9H3s3-2 3-9"/><path d="M10.3 21a1.9 1.9 0 0 0 3.4 0"/>';
  static const heart = '<path d="M12 20s-7-4.4-7-10a4 4 0 0 1 7-2.5A4 4 0 0 1 19 10c0 5.6-7 10-7 10z"/>';
  static const moon = '<path d="M20 14.5A8 8 0 1 1 9.5 4a6.5 6.5 0 0 0 10.5 10.5z"/>';
  static const hand = '<path d="M8 13V5a1.5 1.5 0 0 1 3 0v6M11 11V3.5a1.5 1.5 0 0 1 3 0V11M14 11V5.5a1.5 1.5 0 0 1 3 0V14a7 7 0 0 1-7 7 6 6 0 0 1-5-3l-2-3.5a1.5 1.5 0 0 1 2.5-1.5L8 15"/>';
  static const watch = '<rect x="6" y="6" width="12" height="12" rx="4"/><path d="M9 6l.6-3h4.8L15 6M9 18l.6 3h4.8l.6-3"/>';
  static const link =
      '<path d="M10 14a4 4 0 0 0 5.7 0l3-3a4 4 0 0 0-5.7-5.7l-1 1"/><path d="M14 10a4 4 0 0 0-5.7 0l-3 3a4 4 0 0 0 5.7 5.7l1-1"/>';
  static const up = '<path d="M12 19V5M5 12l7-7 7 7"/>';
}

// ============================================================
// مەیدانی Band: شەپۆل، درەوشانەوە، بازنەی هاوکاتکردن، سێبەر
// ============================================================
class _StagePainter extends CustomPainter {
  _StagePainter({required this.t, required this.color, required this.search, required this.on, required this.syncP});
  final double t;
  final Color color;
  final bool search;
  final bool on;
  final double syncP; // -1 = نیشان مەدە

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);

    // درەوشانەوە (gradient، نەک blur)
    canvas.drawCircle(
      c,
      size.width * 0.34,
      Paint()
        ..shader = RadialGradient(colors: [op(color, on ? 0.5 : 0.14), Colors.transparent])
            .createShader(Rect.fromCircle(center: c, radius: size.width * 0.34)),
    );

    // شەپۆلەکان
    if (on || search) {
      final period = search ? 1.6 : 2.8;
      for (var i = 0; i < 3; i++) {
        final p = ((t / period) + i / 3) % 1.0;
        final sc = 0.55 + 0.6 * p;
        canvas.drawCircle(
          c,
          size.width / 2 * sc,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2
            ..color = (search ? V.cy : color).withAlpha(((0.7 * (1 - p)) * 255).round().clamp(0, 255)),
        );
      }
    }

    // بازنەی هاوکاتکردن
    if (syncP >= 0) {
      final r = size.width / 2 - 8;
      final rect = Rect.fromCircle(center: c, radius: r);
      canvas.drawCircle(
        c,
        r,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4
          ..color = V.track,
      );
      canvas.drawArc(
        rect,
        -math.pi / 2,
        2 * math.pi * syncP,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4
          ..strokeCap = StrokeCap.round
          ..color = V.cy,
      );
    }

    // سێبەری خوارەوە
    final pulse = on ? 1 - 0.18 * (0.5 - 0.5 * math.cos(t / 3.5 * 2 * math.pi)) : 1.0;
    final ped = Rect.fromCenter(center: Offset(c.dx, size.height - 47), width: 200 * pulse, height: 34);
    canvas.drawOval(
      ped,
      Paint()
        ..shader = RadialGradient(colors: [op(color, on ? 0.55 : 0.2), Colors.transparent]).createShader(ped),
    );
  }

  @override
  bool shouldRepaint(covariant _StagePainter o) =>
      o.t != t || o.color != color || o.search != search || o.on != on || o.syncP != syncP;
}
