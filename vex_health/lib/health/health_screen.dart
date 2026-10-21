// VEX Health — بەشی تەندروستی
import 'package:flutter/material.dart';

import '../band/band_lock.dart';
import '../band/band_pair_card.dart' show showBandPair;
import '../band/band_state.dart';
import '../band/band_widgets.dart';
import '../core/icons.dart';
import '../core/theme.dart';
import '../home/home_screen.dart' show syncTime;
import 'ai_brief.dart';
import 'day_ribbon.dart';
import 'hc.dart';
import 'vitals.dart';

class HealthScreen extends StatelessWidget {
  const HealthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    return Stack(
      children: [
        const Positioned.fill(child: HealthBg(radius: 1.0)),
        Positioned.fill(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(16, mq.padding.top + 16, 16, mq.padding.bottom + 128),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 430),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Rise(child: _HealthHeader()),
                    const Rise(delayMs: 20, child: BandBanner()),
                    BandBuilder(
                      builder: (context, on) {
                        const top = <Widget>[
                          Rise(delayMs: 45, child: AiBriefCard()),
                          Rise(delayMs: 90, child: _LiveSec()),
                          VitalsGrid(),
                          Rise(delayMs: 135, child: HSec('چالاکی', note: 'ئامانجی ڕۆژانە')),
                          Rise(delayMs: 135, child: ActivityRingsCard()),
                          ActivityGrid2(),
                        ];
                        const ribbon = Rise(delayMs: 225, child: DayRibbonCard());
                        if (on) {
                          return const Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [...top, ribbon, Rise(delayMs: 270, child: HealthLegend())],
                          );
                        }
                        // Band پەیوەست نییە: هەموو شتێک لێڵ، و «ڕۆژەکەت» قوفڵ
                        return const Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            BandBlur(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: top)),
                            SizedBox(height: 14),
                            BandLockPane(
                              title: 'ڕۆژەکەت',
                              text: 'VEX Band پەیوەست بکە بۆ بینینی ڕۆژەکەت',
                              child: ribbon,
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _HealthHeader extends StatefulWidget {
  const _HealthHeader();

  @override
  State<_HealthHeader> createState() => _HealthHeaderState();
}

class _HealthHeaderState extends State<_HealthHeader> with SingleTickerProviderStateMixin {
  late final AnimationController _spin =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
  bool _busy = false;

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  Future<void> _sync() async {
    if (_busy) return;
    if (!BandState.I.connected) {
      showBandPair();
      return;
    }
    _busy = true;
    _spin.repeat();
    await Future<void>.delayed(const Duration(milliseconds: 1400));
    if (!mounted) return;
    _spin.stop();
    _spin.reset();
    _busy = false;
    syncTime.value = nowHM();
    toast('Band هاوکات کرا ✓');
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('تەندروستی', style: ku(24, w: FontWeight.w800, c: HC.tx, h: 1.4)),
              Text(kurdishDate(), style: ku(13, c: HC.mu)),
            ],
          ),
        ),
        Press(
          onTap: _sync,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: HC.card,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: HC.line),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                RotationTransition(turns: _spin, child: svgIcon(HI.sync, HX.c2, size: 16)),
                const SizedBox(width: 6),
                Text('هاوکات', style: ku(13, w: FontWeight.w600, c: HC.tx)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// «نیشانە زیندووەکان»: کاتێک Band پەیوەست نییە «زیندوو» نانووسرێت
class _LiveSec extends StatelessWidget {
  const _LiveSec();

  @override
  Widget build(BuildContext context) {
    return BandBuilder(
      builder: (context, on) => on
          ? const HSec('نیشانە زیندووەکان', note: 'ئێستا', live: true)
          : const HSec('تەندروستی ئەمڕۆ', note: 'پەیوەست نییە'),
    );
  }
}
