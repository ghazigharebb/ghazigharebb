// VEX Health — کارتی «Band پەیوەست نییە» + پەڕەی کڕینی VEX Band
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/icons.dart';
import '../core/theme.dart';
import 'band_emblem.dart';
import 'band_state.dart';
import 'band_widgets.dart';

class _I {
  static const link =
      '<path d="M10 14a4 4 0 0 0 5.7 0l3-3a4 4 0 0 0-5.7-5.7l-1 1"/><path d="M14 10a4 4 0 0 0-5.7 0l-3 3a4 4 0 0 0 5.7 5.7l1-1"/>';
  static const bag = '<path d="M5 8h14l-1 12H6z"/><path d="M9 8V6a3 3 0 0 1 6 0v2"/>';
  static const heart = '<path d="M12 20s-7-4.4-7-10a4 4 0 0 1 7-2.5A4 4 0 0 1 19 10c0 5.6-7 10-7 10z"/>';
  static const drop = '<path d="M12 3s6 6.2 6 10.5a6 6 0 0 1-12 0C6 9.2 12 3 12 3z"/>';
  static const moon = '<path d="M20 14.5A8 8 0 1 1 9.5 4a6.5 6.5 0 0 0 10.5 10.5z"/>';
  static const gauge = '<path d="M4 17a8 8 0 0 1 16 0"/><path d="M12 17l4-5"/>';
  static const ecg = '<path d="M3 12h4l2-5 4 10 2-5h6"/>';
  static const flame =
      '<path d="M12 3c1 3 4 4.5 4 8.5a4 4 0 0 1-8 0c0-1.6.7-2.6 1.5-3.5C9.5 10 11 9 11 7c0-1.5.4-2.8 1-4z"/>';
  static const gift =
      '<rect x="3" y="9" width="18" height="12" rx="2"/><path d="M12 9v12M3 13h18M12 9c-2-4-6-3-5 0M12 9c2-4 6-3 5 0"/>';
}

Color _hexC(String h) => vk(int.parse('FF${h.substring(1)}', radix: 16));

class _Chip extends StatelessWidget {
  const _Chip(this.label, this.color);
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: op(color, 0.12),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: op(color, 0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 6, height: 6, decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
          const SizedBox(width: 5),
          VText(label, style: ku(11.5, w: FontWeight.w800, c: color, h: 1.4)),
        ],
      ),
    );
  }
}

class _Btn extends StatelessWidget {
  const _Btn({required this.label, required this.icon, required this.onTap, this.primary = false});
  final String label;
  final String icon;
  final VoidCallback onTap;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final fg = primary ? V.ink : V.tx;
    return Press(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          gradient: primary ? V.prime : null,
          color: primary ? null : vk(0x0FFFFFFF),
          borderRadius: BorderRadius.circular(15),
          border: primary ? null : Border.all(color: vk(0x388CEBF5)),
          boxShadow: primary ? [BoxShadow(color: op(V.mint, 0.4), blurRadius: 18, offset: const Offset(0, 8), spreadRadius: -8)] : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            svgIcon(icon, primary ? '#04323a' : '#effeff', size: 17),
            const SizedBox(width: 7),
            VText(label, style: ku(13, w: FontWeight.w800, c: fg, h: 1.3)),
          ],
        ),
      ),
    );
  }
}

/// کارتی گەورەی «Band پەیوەست نییە» (شاشەی تەندروستی)
class BandPairCard extends StatelessWidget {
  const BandPairCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [vk(0xEB083440), vk(0xF204201B)],
        ),
        border: Border.all(color: op(V.cy, 0.28)),
        boxShadow: [BoxShadow(color: op(V.cy, 0.22), blurRadius: 40, offset: const Offset(0, 20), spreadRadius: -24)],
      ),
      child: Column(
        children: [
          const BandEmblem(size: 92),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: BandColors.dot)),
              const SizedBox(width: 8),
              VText('VEX Band پەیوەست نییە', style: ku(17, w: FontWeight.w800, h: 1.5)),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 6,
            runSpacing: 6,
            children: [
              _Chip('دڵ', _hexC('#ff5f7e')),
              _Chip('خەو', V.violet),
              _Chip('سترێس', V.amber),
              _Chip('SpO₂', V.cy),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _Btn(label: 'کڕینی Band', icon: _I.bag, onTap: showBandShop)),
              const SizedBox(width: 8),
              Expanded(
                child: _Btn(
                  label: 'پەیوەستکردن',
                  icon: _I.link,
                  primary: true,
                  onTap: showBandPair,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// پەڕەی کڕینی VEX Band
void showBandShop() => showVSheet<void>(builder: (_) => const _BandShop());

class _BandShop extends StatelessWidget {
  const _BandShop();

  @override
  Widget build(BuildContext context) {
    final feats = <List<String>>[
      [_I.heart, '#ff5f7e', 'لێدانی دڵ 24/7'],
      [_I.drop, '#2fe6f3', 'SpO₂ و HRV'],
      [_I.moon, '#9b7bff', 'قۆناغەکانی خەو'],
      [_I.gauge, '#ffbe4d', 'سترێس'],
      [_I.ecg, '#3cf08a', 'ECG'],
      [_I.flame, '#ff9466', 'هەنگاو و کالۆری'],
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 200,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 190,
                height: 190,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [op(V.cy, 0.34), op(V.mint, 0.1), Colors.transparent], stops: const [0, .6, 1]),
                ),
              ),
              const BandEmblem(size: 170),
              Positioned(top: 6, right: 14, child: _Stat(_I.heart, '#ff5f7e', '72', 'BPM')),
              Positioned(bottom: 40, left: 6, child: _Stat(_I.drop, '#2fe6f3', '98%', 'SpO₂')),
              Positioned(bottom: 2, right: 26, child: _Stat(_I.moon, '#9b7bff', '7h 20m', '')),
            ],
          ),
        ),
        Center(
          child: ShaderMask(
            shaderCallback: (r) => LinearGradient(colors: [vk(0xFF2FE6F3), vk(0xFF3CF08A)]).createShader(r),
            child: VText('VEX BAND V8', style: nu(13, c: kW, ls: 3)),
          ),
        ),
        const SizedBox(height: 6),
        VText('ئەم بەشە داتای VEX Band ی پێویستە',
            textAlign: TextAlign.center, style: ku(20, w: FontWeight.w800, h: 1.5)),
        const SizedBox(height: 4),
        VText('دڵ، خەو و سترێس شەو و ڕۆژ خۆکارانە دەپێورێن.',
            textAlign: TextAlign.center, style: ku(13, c: V.mu, h: 1.7)),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 3.3,
          children: [
            for (final f in feats)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: vk(0x0AFFFFFF),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: V.line),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: op(_hexC(f[1]), 0.15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: op(_hexC(f[1]), 0.3)),
                      ),
                      child: svgIcon(f[0], f[1], size: 17),
                    ),
                    const SizedBox(width: 9),
                    Expanded(child: VText(f[2], maxLines: 1, overflow: TextOverflow.ellipsis, style: ku(12.5, w: FontWeight.w700, h: 1.3))),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: LinearGradient(colors: [op(V.amber, 0.16), op(V.amber, 0.04)]),
            border: Border.all(color: op(V.amber, 0.35)),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: op(V.amber, 0.15), borderRadius: BorderRadius.circular(13)),
                child: svgIcon(_I.gift, '#ffbe4d', size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    VText('6 مانگ VEX Plus بە خۆڕایی', style: ku(13.5, w: FontWeight.w800, c: vk(0xFFFFE29A), h: 1.4)),
                    VText('لەگەڵ پەیوەستکردنی Band', style: ku(11.5, c: vk(0xFFC9B27A), h: 1.4)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _Btn(
          label: 'پەیوەستکردنی Band',
          icon: _I.link,
          primary: true,
          onTap: () {
            Navigator.of(context).pop();
            showBandPair();
          },
        ),
        const SizedBox(height: 10),
        _Btn(
          label: 'داواکردنی VEX Band',
          icon: _I.bag,
          onTap: () {
            Navigator.of(context).pop();
            toast('داواکردنی Band بەم زووانە دەکرێتەوە');
          },
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.icon, this.hex, this.value, this.unit);
  final String icon;
  final String hex;
  final String value;
  final String unit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: vk(0xD6041C24),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: vk(0x388FF3F9)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        textDirection: TextDirection.ltr,
        children: [
          svgIcon(icon, hex, size: 14),
          const SizedBox(width: 6),
          VText(value, style: nu(12.5)),
          if (unit.isNotEmpty) ...[
            const SizedBox(width: 4),
            VText(unit, style: nu(9, c: V.mu)),
          ],
        ],
      ),
    );
  }
}


// ============================================================
// پەڕەی پەیوەستکردنی Band (گەڕان ← دۆزرایەوە ← پەیوەستبوون)
// ============================================================
/// بۆ BLE ی ڕاستەقینە: لە `_scan()` ی خوارەوە Band ـەکان بدۆزەرەوە و `_found` پڕ بکەرەوە
void showBandPair() => showVSheet<void>(builder: (_) => const _BandPair());

enum _Ps { intro, scan, found, link }

class _BandPair extends StatefulWidget {
  const _BandPair();
  @override
  State<_BandPair> createState() => _BandPairState();
}

class _BandPairState extends State<_BandPair> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 2400))..repeat();
  _Ps _st = _Ps.intro;
  Timer? _t;

  @override
  void dispose() {
    _t?.cancel();
    _c.dispose();
    super.dispose();
  }

  void _scan() {
    setState(() => _st = _Ps.scan);
    // نموونە: لێرە بگۆڕە بە گەڕانی BLE ی ڕاستەقینە
    _t?.cancel();
    _t = Timer(const Duration(milliseconds: 2600), () {
      if (mounted) setState(() => _st = _Ps.found);
    });
  }

  Future<void> _link() async {
    setState(() => _st = _Ps.link);
    BandState.I.reconnect();
    // چاوەڕێی تەواوبوون
    for (var i = 0; i < 40 && mounted && !BandState.I.connected; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final busy = _st == _Ps.scan || _st == _Ps.link;
    final title = switch (_st) {
      _Ps.intro => 'پەیوەستکردنی VEX Band',
      _Ps.scan => 'گەڕان بەدوای Band…',
      _Ps.found => 'Band دۆزرایەوە',
      _Ps.link => 'پەیوەست دەکرێت…',
    };
    final sub = switch (_st) {
      _Ps.intro => 'Band ـەکەت هەڵبکە و لە تەنیشت مۆبایلەکەت دایبنێ',
      _Ps.scan => 'Bluetooth ـەکەت چالاک بێت',
      _Ps.found => 'پەنجە بە Band ـەکە بنێ بۆ پەیوەستکردن',
      _Ps.link => 'تکایە چاوەڕێ بە',
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 210,
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (busy)
                AnimatedBuilder(
                  animation: _c,
                  builder: (_, __) => CustomPaint(size: const Size(210, 210), painter: _RadarPainter(_c.value)),
                ),
              const BandEmblem(size: 120),
            ],
          ),
        ),
        Center(child: VText(title, style: ku(19, w: FontWeight.w800, h: 1.5))),
        const SizedBox(height: 2),
        VText(sub, textAlign: TextAlign.center, style: ku(13, c: V.mu, h: 1.7)),
        const SizedBox(height: 14),
        if (_st == _Ps.intro) ...[
          for (final r in const [
            ['1', 'Band ـەکە شەحن بکە و هەڵی بکە'],
            ['2', 'Bluetooth ی مۆبایلەکەت چالاک بکە'],
            ['3', 'دوگمەی «گەڕان» بکە'],
          ])
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(children: [
                Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: op(V.cy, 0.14), border: Border.all(color: op(V.cy, 0.35))),
                  child: VText(r[0], style: nu(12.5, w: FontWeight.w800, c: V.cy)),
                ),
                const SizedBox(width: 10),
                Expanded(child: VText(r[1], style: ku(13, w: FontWeight.w600, h: 1.5))),
              ]),
            ),
          const SizedBox(height: 6),
          _Btn(label: 'گەڕان', icon: _I.link, primary: true, onTap: _scan),
          const SizedBox(height: 10),
          _Btn(label: 'کڕینی Band', icon: _I.bag, onTap: () {
            Navigator.of(context).pop();
            showBandShop();
          }),
        ],
        if (_st == _Ps.found)
          Press(
            onTap: _link,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: LinearGradient(colors: [op(V.mint, 0.16), op(V.cy, 0.06)]),
                border: Border.all(color: op(V.mint, 0.45)),
              ),
              child: Row(children: [
                const BandEmblem(size: 44),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    VText('VEX Band V8', style: nu(15, w: FontWeight.w800)),
                    VText('نزیک • ئامادەیە', style: ku(11.5, c: V.mu, h: 1.4)),
                  ]),
                ),
                svgIcon(_I.link, '#3cf08a', size: 22),
              ]),
            ),
          ),
        if (_st == _Ps.scan)
          _Btn(label: 'هەڵوەشاندنەوە', icon: _I.bag, onTap: () {
            _t?.cancel();
            setState(() => _st = _Ps.intro);
          }),
      ],
    );
  }
}

class _RadarPainter extends CustomPainter {
  _RadarPainter(this.t);
  final double t;
  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    for (var i = 0; i < 3; i++) {
      final k = (t + i / 3) % 1;
      canvas.drawCircle(
        c,
        40 + 65 * k,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = op(V.cy, 0.5 * (1 - k)),
      );
    }
    final a = t * 2 * math.pi;
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: 100),
      a,
      0.8,
      true,
      Paint()..shader = SweepGradient(startAngle: 0, endAngle: 0.8, colors: [op(V.cy, 0.0), op(V.cy, 0.28)], transform: GradientRotation(a)).createShader(Rect.fromCircle(center: c, radius: 100)),
    );
  }

  @override
  bool shouldRepaint(covariant _RadarPainter o) => o.t != t;
}
