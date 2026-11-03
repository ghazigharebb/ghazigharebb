// VEX Health — کارتی «هەستەوەری دەست» (VEX Skin Sense) لە پەڕەی Band
//
// نیشان دەدات Band ئێستا چی دەبینێت: لە دەستە / لە دەست نییە / دەپشکنرێت، دڵی ڕاستەوخۆ، گەرمیی پێست،
// و هۆی دوایین بڕیار. دوگمەی «لۆگ» دوایین ٦٠٠ ڕووداو نیشان دەدات و کۆپی دەکات (بۆ ڕێکخستنی ئەستانەکان).
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/theme.dart';
import 'ble/vex_ble.dart';
import 'ble/vex_wear.dart';

class SkinSenseCard extends StatelessWidget {
  const SkinSenseCard({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([VexBand.I, VexBand.I.wear]),
      builder: (context, _) {
        final b = VexBand.I;
        if (!b.linked) return const SizedBox.shrink();
        final e = b.wear.engine;
        final (txt, col) = switch (e.state) {
          WearState.worn => ('لە دەستتە', V.mint),
          WearState.off => ('لە دەستت نییە', V.coral),
          WearState.unknown => ('دەپشکنرێت…', V.amber),
        };
        final hr = e.state == WearState.worn ? e.lastHr : null;
        final t = e.lastTemp;
        return Container(
          margin: const EdgeInsets.only(top: 14),
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          decoration: BoxDecoration(
            color: V.surf,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: op(col, 0.45)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: op(col, 0.15), borderRadius: BorderRadius.circular(12)),
                    child: Icon(Icons.back_hand_rounded, size: 19, color: col),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        VText('هەستەوەری دەست', style: ku(14, w: FontWeight.w800, h: 1.4)),
                        VText('هەستەوەری ڕووناکیی خاو (PPG) · ٥٠ جار لە چرکەیەکدا', style: ku(11.5, c: V.mu, h: 1.4)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
                    decoration: BoxDecoration(color: op(col, 0.15), borderRadius: BorderRadius.circular(99)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Container(width: 7, height: 7, decoration: BoxDecoration(shape: BoxShape.circle, color: col)),
                      const SizedBox(width: 6),
                      VText(txt, style: ku(12, w: FontWeight.w800, c: col, h: 1.3)),
                    ]),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _tile('دڵ', hr == null ? '—' : '$hr', 'bpm', V.coral),
                  const SizedBox(width: 8),
                  _tile('گەرمیی پێست', t == null ? '—' : t.toStringAsFixed(1), '°C', V.amber),
                  const SizedBox(width: 8),
                  _tile('شەحن', e.charging ? 'بەڵێ' : 'نەخێر', '', V.cy, ku: true),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: VText(
                      e.reason.isEmpty ? '' : 'دوایین بڕیار: ${e.reason}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textDirection: TextDirection.ltr,
                      style: nu(11, w: FontWeight.w600, c: V.mu),
                    ),
                  ),
                  Press(
                    onTap: () => _showLog(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(99), border: Border.all(color: V.line)),
                      child: VText('لۆگ', style: ku(12, w: FontWeight.w800, c: V.tx, h: 1.3)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _tile(String label, String value, String unit, Color c, {bool ku = false}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 8),
        decoration: BoxDecoration(color: op(c, 0.08), borderRadius: BorderRadius.circular(14)),
        child: Column(
          children: [
            VText(label, style: _ku(11, c: V.mu)),
            const SizedBox(height: 2),
            VText.rich(
              TextSpan(children: [
                TextSpan(text: value, style: ku ? _ku(15, w: FontWeight.w800, c: V.tx) : nu(17, w: FontWeight.w800, c: V.tx)),
                if (unit.isNotEmpty) TextSpan(text: ' $unit', style: nu(10.5, w: FontWeight.w700, c: V.mu)),
              ]),
              textDirection: TextDirection.ltr,
              style: nu(17),
            ),
          ],
        ),
      ),
    );
  }

  static TextStyle _ku(double s, {FontWeight? w, Color? c}) => ku(s, w: w ?? FontWeight.w400, c: c);

  void _showLog(BuildContext context) {
    final lines = VexBand.I.wear.engine.log.map((e) => e.toString()).toList().reversed.toList();
    final text = lines.join('\n');
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: V.surf,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => SafeArea(
        child: SizedBox(
          height: MediaQuery.of(ctx).size.height * 0.6,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
                child: Row(
                  children: [
                    Expanded(child: VText('لۆگی هەستەوەری دەست', style: ku(15, w: FontWeight.w800))),
                    Press(
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: text));
                        toast('کۆپی کرا ✓');
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(color: V.cy, borderRadius: BorderRadius.circular(99)),
                        child: VText('کۆپی', style: ku(12, w: FontWeight.w800, c: kOnAcc, h: 1.3)),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                  itemCount: lines.length,
                  itemBuilder: (_, i) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text(lines[i], textDirection: TextDirection.ltr, style: nu(12, w: FontWeight.w600, c: V.tx)),
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
