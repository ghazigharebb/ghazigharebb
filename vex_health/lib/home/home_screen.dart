// VEX Health — پەڕەی سەرەکی
import 'package:flutter/material.dart';

import '../band/band_state.dart';
import '../band/band_widgets.dart';
import '../core/icons.dart';
import '../core/theme.dart';
import '../onboarding/account.dart';
import 'detail_sheets.dart';
import 'food_scan.dart';
import 'health_ring.dart';
import 'home_cards.dart';
import 'sponsor_ad.dart';
import 'water_card.dart';

/// کاتی دوایین هاوکاتکردن لەگەڵ Band
final ValueNotifier<String> syncTime = ValueNotifier<String>('12:54');

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(16, mq.padding.top + 14, 16, mq.padding.bottom + 120),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Rise(child: HomeHeader()),
              Rise(child: BandStatus()),
              Rise(delayMs: 50, child: HealthCard()),
              Rise(delayMs: 100, child: SponsorCarousel()),
              Rise(delayMs: 150, child: FoodScanCard()),
              Rise(delayMs: 200, child: ActivityCard()),
              Rise(delayMs: 250, child: FamilyCard()),
              Rise(delayMs: 300, child: ToolsRow()),
              Rise(delayMs: 350, child: WaterCard()),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------- سەرەوە ----------
class HomeHeader extends StatefulWidget {
  const HomeHeader({super.key});

  @override
  State<HomeHeader> createState() => _HomeHeaderState();
}

class _HomeHeaderState extends State<HomeHeader> with SingleTickerProviderStateMixin {
  late final AnimationController _spin =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
  bool _busy = false;

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  Future<void> _sync() async {
    if (_busy) return;
    // Band پەیوەست نییە: هاوکاتکردن بێمانایە، هەوڵی پەیوەستکردنەوە دەدرێت
    if (!BandState.I.connected) {
      BandState.I.reconnect();
      return;
    }
    _busy = true;
    _spin.repeat();
    await Future<void>.delayed(const Duration(milliseconds: 1600));
    if (!mounted) return;
    _spin.stop();
    _spin.reset();
    _busy = false;
    syncTime.value = nowHM();
    toast('Band هاوکات کرا ✓');
  }

  Widget _hb({required Widget child, required VoidCallback onTap, bool dot = false}) {
    return Press(
      onTap: onTap,
      child: SizedBox(
        width: 42,
        height: 42,
        child: Stack(
          children: [
            Positioned.fill(
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: V.surf,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: V.line),
                ),
                child: child,
              ),
            ),
            if (dot)
              Positioned(
                top: 8,
                left: 9,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: V.coral,
                    border: Border.all(color: V.bg, width: 2),
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
    return Row(
      children: [
        Container(
          width: 50,
          height: 50,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: V.prime,
            boxShadow: [BoxShadow(color: Color(0x803CF08A), blurRadius: 20, offset: Offset(0, 8), spreadRadius: -10)],
          ),
          child: ListenableBuilder(
            listenable: Account.I,
            builder: (context, _) => Text(Account.I.name.isEmpty ? 'G' : Account.I.initial, style: ku(20, w: FontWeight.w800, c: V.ink, h: 1.2)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListenableBuilder(
                listenable: Account.I,
                builder: (context, _) => Text(
                    'سڵاو، ${Account.I.firstName.isEmpty ? 'ghazi' : Account.I.firstName} 👋',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: ku(19, w: FontWeight.w800, h: 1.4)),
              ),
              Text(kurdishDate(), style: ku(12, c: V.mu)),
            ],
          ),
        ),
        const SizedBox(width: 12),
        _hb(child: svgIcon(Ico.bell, '#effeff', size: 20), onTap: openNotifications, dot: true),
        const SizedBox(width: 12),
        _hb(
          child: RotationTransition(
            turns: Tween<double>(begin: 0, end: -1).animate(_spin),
            child: svgIcon(Ico.sync, '#effeff', size: 20),
          ),
          onTap: _sync,
        ),
      ],
    );
  }
}

// ---------- دۆخی Band ----------
class BandStatus extends StatelessWidget {
  const BandStatus({super.key});

  @override
  Widget build(BuildContext context) =>
      BandBuilder(builder: (context, on) => on ? _online() : _offline());

  /// Band پەیوەست نییە: خاڵی سوور + کاتی دوایین هاوکاتکردن + دوگمەی پەیوەستکردنەوە
  Widget _offline() {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: box(r: 16, color: V.surf),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(shape: BoxShape.circle, color: BandColors.dot),
          ),
          const SizedBox(width: 8),
          Text('Band پەیوەست نییە', style: ku(12, w: FontWeight.w700, c: BandColors.dot)),
          const SizedBox(width: 6),
          Expanded(
            child: Text.rich(
              TextSpan(children: [
                if (BandState.I.lastSync.isEmpty)
                  const TextSpan(text: '· هێشتا هاوکات نەکراوە')
                else ...[
                  const TextSpan(text: '· دوایین هاوکاتکردن '),
                  TextSpan(text: BandState.I.lastSync, style: nu(12, w: FontWeight.w700, c: V.mu)),
                ],
              ]),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: ku(12, w: FontWeight.w700, c: V.mu),
            ),
          ),
          const SizedBox(width: 6),
          const ReconnectButton(compact: true),
        ],
      ),
    );
  }

  Widget _online() {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: box(r: 16, color: V.surf),
      child: Row(
        children: [
          const BlinkDot(size: 8),
          const SizedBox(width: 6),
          Text('Band پەیوەستە', style: ku(12, w: FontWeight.w700, c: V.mint)),
          const SizedBox(width: 6),
          Expanded(
            child: ValueListenableBuilder<String>(
              valueListenable: syncTime,
              builder: (context, t, _) => Text.rich(
                TextSpan(children: [
                  const TextSpan(text: '· نوێکرایەوە '),
                  TextSpan(text: t, style: nu(12, w: FontWeight.w700, c: V.mu)),
                ]),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: ku(12, w: FontWeight.w700, c: V.mu),
              ),
            ),
          ),
          const _Battery(level: 0.25),
          const SizedBox(width: 5),
          Text('25%', textDirection: TextDirection.ltr, style: nu(12, w: FontWeight.w700, c: V.mu)),
        ],
      ),
    );
  }
}

class _Battery extends StatelessWidget {
  const _Battery({required this.level});
  final double level;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 25.5,
      height: 11,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 3.5,
            top: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(1),
              decoration: BoxDecoration(
                border: Border.all(color: V.mu, width: 1.5),
                borderRadius: BorderRadius.circular(3),
              ),
              child: Align(
                alignment: Alignment.centerRight,
                child: FractionallySizedBox(
                  widthFactor: level,
                  heightFactor: 1,
                  child: DecoratedBox(
                    decoration: BoxDecoration(color: V.amber, borderRadius: BorderRadius.circular(1)),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            top: 3.5,
            child: Container(
              width: 2,
              height: 4,
              decoration: BoxDecoration(color: V.mu, borderRadius: BorderRadius.circular(1)),
            ),
          ),
        ],
      ),
    );
  }
}
