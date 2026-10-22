// VEX Health — کارتی سویچی ئاگادارکردنەوەی هەنگاو (لە پرۆفایل)
import 'package:flutter/material.dart';

import '../core/theme.dart';
import 'step_notify.dart';

class StepNotifyTile extends StatelessWidget {
  const StepNotifyTile({super.key});

  @override
  Widget build(BuildContext context) {
    final n = StepNotify.I;
    if (!n.supported) return const SizedBox.shrink();
    return ListenableBuilder(
      listenable: n,
      builder: (context, _) {
        return VCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: op(V.cy, 0.12), borderRadius: BorderRadius.circular(14)),
                    child: Icon(Icons.directions_walk_rounded, color: V.cy, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        VText('ئاگادارکردنەوەی هەنگاو', style: ku(15, w: FontWeight.w800, h: 1.4)),
                        VText(
                          'هەنگاو، کالۆری و ماوەی ئامانج هەمیشە لەسەر شاشەی مۆبایلەکەت',
                          style: ku(12, c: V.mu, h: 1.6),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  n.busy
                      ? SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.4, color: V.cy))
                      : Switch(
                          value: n.enabled,
                          activeColor: V.ink,
                          activeTrackColor: V.cy,
                          onChanged: (v) => n.setEnabled(v),
                        ),
                ],
              ),
              if (n.message != null)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: VText(n.message!, style: ku(12, c: V.mu, h: 1.7)),
                ),
            ],
          ),
        );
      },
    );
  }
}
