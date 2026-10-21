// VEX Health — دۆخی قوفڵکراو (Band پەیوەست نییە): ناوەڕۆک لێڵ + دوگمەی پەیوەستکردن
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../core/icons.dart';
import '../core/theme.dart';
import 'band_emblem.dart';
import 'band_pair_card.dart';

/// ناوەڕۆکەکە لێڵ دەکات و پەنجەی پێدا ناچێت. لێڵکردنەکە یەک جار دەکێشرێت (RepaintBoundary) بۆ ئەوەی لاگ نەکات.
class BandBlur extends StatelessWidget {
  const BandBlur({super.key, required this.child, this.sigma = 5.5, this.opacity = 0.55});
  final Widget child;
  final double sigma;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: IgnorePointer(
        child: RepaintBoundary(
          child: ImageFiltered(
            imageFilter: ui.ImageFilter.blur(sigmaX: sigma, sigmaY: sigma, tileMode: TileMode.decal),
            child: Opacity(opacity: opacity, child: child),
          ),
        ),
      ),
    );
  }
}

/// کارتێکی لێڵ + ئایکۆن + نووسین + دوگمەی «پەیوەستکردن» لە ناوەڕاستدا
class BandLockPane extends StatelessWidget {
  const BandLockPane({super.key, required this.child, required this.title, required this.text, this.minHeight = 270});
  final Widget child;
  final String title;
  final String text;
  final double minHeight;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ConstrainedBox(
          constraints: BoxConstraints(minHeight: minHeight),
          child: Align(alignment: Alignment.topCenter, child: BandBlur(child: child)),
        ),
        Positioned.fill(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const BandEmblem(size: 78),
                  const SizedBox(height: 2),
                  Text(title, textAlign: TextAlign.center, style: ku(19, w: FontWeight.w800, h: 1.5)),
                  const SizedBox(height: 4),
                  Text(text, textAlign: TextAlign.center, style: ku(13, c: V.mu, h: 1.7)),
                  const SizedBox(height: 14),
                  Press(
                    onTap: showBandPair,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 13),
                      decoration: BoxDecoration(
                        gradient: V.prime,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(color: op(V.mint, 0.4), blurRadius: 18, offset: const Offset(0, 8), spreadRadius: -8)],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('پەیوەستکردن', style: ku(13.5, w: FontWeight.w800, c: V.ink, h: 1.3)),
                          const SizedBox(width: 8),
                          svgIcon('<path d="M10 14a4 4 0 0 0 5.7 0l3-3a4 4 0 0 0-5.7-5.7l-1 1"/><path d="M14 10a4 4 0 0 0-5.7 0l-3 3a4 4 0 0 0 5.7 5.7l1-1"/>', '#04323a', size: 17),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
