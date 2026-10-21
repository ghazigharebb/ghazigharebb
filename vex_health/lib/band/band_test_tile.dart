// VEX Health — کارتی تاقیکردنەوەی دۆخی Band (تەنها لە debug دەردەکەوێت)
// بۆ ئەوەی بتوانیت دیزاینی «Band پەیوەست نییە» ببینیت بەبێ ئەوەی Band بپچڕێنیت.
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../home/home_screen.dart' show syncTime;
import 'band_state.dart';

class BandTestTile extends StatelessWidget {
  const BandTestTile({super.key});

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) return const SizedBox.shrink();
    return ListenableBuilder(
      listenable: BandState.I,
      builder: (context, _) {
        final on = BandState.I.connected;
        return VCard(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('تاقیکردنەوە: Band پەیوەستە', style: ku(14, w: FontWeight.w800, h: 1.5)),
                    Text('تەنها لە debug دەردەکەوێت', style: ku(12, c: V.mu, h: 1.6)),
                  ],
                ),
              ),
              Switch(
                value: on,
                activeColor: V.ink,
                activeTrackColor: V.cy,
                onChanged: (v) => BandState.I.setConnected(v, lastSync: syncTime.value),
              ),
            ],
          ),
        );
      },
    );
  }
}
