// VEX Health — پارچە هاوبەشەکانی پەڕەکانی وردەکاری (دڵ، ئۆکسجین، سترێس، هەنگاو)
import 'package:flutter/material.dart';

import '../core/icons.dart';
import '../core/theme.dart';
import 'hc.dart';

/// چوارچێوەی پەڕە: پاشبنەما + هەڵکشان
class DetailScaffold extends StatelessWidget {
  const DetailScaffold({super.key, required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    return Scaffold(
      backgroundColor: HC.bg,
      body: Stack(
        children: [
          const Positioned.fill(child: HealthBg(radius: 1.1)),
          Positioned.fill(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(18, mq.padding.top + 14, 18, mq.padding.bottom + 28),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 430),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// سەرەوە: گەڕانەوە + ناو + ڕۆژ/هەفتە/مانگ
class DetailHeader extends StatelessWidget {
  const DetailHeader({super.key, required this.title, required this.mode, required this.onMode});
  final String title;
  final int mode;
  final ValueChanged<int> onMode;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Press(
          onTap: () => Navigator.of(context).maybePop(),
          child: Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: HC.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: HC.line),
            ),
            child: svgIcon(HI.back, HX.tx, size: 18, stroke: 2.4),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(title,
              maxLines: 2, overflow: TextOverflow.ellipsis, style: ku(22, w: FontWeight.w800, c: HC.tx, h: 1.3)),
        ),
        const SizedBox(width: 10),
        Seg3(index: mode, onTap: onMode),
      ],
    );
  }
}

/// ڕۆژ / هەفتە / مانگ
class Seg3 extends StatelessWidget {
  const Seg3({super.key, required this.index, required this.onTap});
  final int index;
  final ValueChanged<int> onTap;

  static const List<String> labels = ['ڕۆژ', 'هەفتە', 'مانگ'];

  @override
  Widget build(BuildContext context) {
    const w = 60.0;
    return Container(
      width: 190,
      height: 42,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: HC.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: HC.line),
      ),
      child: Stack(
        children: [
          AnimatedPositionedDirectional(
            duration: const Duration(milliseconds: 300),
            curve: const Cubic(0.2, 0.9, 0.3, 1.0),
            start: index * w,
            top: 0,
            bottom: 0,
            width: w,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [HC.c2, HC.c],
                ),
                boxShadow: const [BoxShadow(color: HC.glow, blurRadius: 16, offset: Offset(0, 4))],
              ),
            ),
          ),
          Positioned.fill(
            child: Row(
              children: [
                for (int i = 0; i < 3; i++)
                  SizedBox(
                    width: w,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => onTap(i),
                      child: Center(
                        child: AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 250),
                          style: ku(13, w: FontWeight.w600, c: i == index ? HC.ink : HC.mu),
                          child: Text(labels[i]),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// هێڵی بەروار
class DateRow extends StatelessWidget {
  const DateRow(this.label, {super.key, this.bottom = 4});
  final String label;
  final double bottom;

  Widget _c(String t) => Container(
        width: 30,
        height: 30,
        alignment: Alignment.center,
        decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: HC.line)),
        child: Text(t, style: ku(12, c: HC.mu, h: 1.0)),
      );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: 22, bottom: bottom),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _c('›'),
          const SizedBox(width: 16),
          Flexible(
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 150),
              child: Text(label, textAlign: TextAlign.center, style: ku(15, w: FontWeight.w600, c: HC.tx)),
            ),
          ),
          const SizedBox(width: 16),
          _c('‹'),
        ],
      ),
    );
  }
}

/// کارتی سادە
class HCard extends StatelessWidget {
  const HCard({super.key, required this.child, this.top = 14, this.radius = 22, this.padding = 16});
  final Widget child;
  final double top;
  final double radius;
  final double padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(top: top),
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: HC.card,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: HC.line),
      ),
      child: child,
    );
  }
}

/// سەردێڕی کارتی هێڵکاری + چیپی ڕوونکردنەوە
class ChartHead extends StatelessWidget {
  const ChartHead(this.title, this.tip,
      {super.key, this.tipColor = HC.c2, this.tipBg = const Color(0x1A03EAFB), this.tipLtr = true});
  final String title;
  final String tip;
  final Color tipColor;
  final Color tipBg;
  final bool tipLtr;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(child: Text(title, style: ku(14, c: HC.mu))),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: tipBg,
              borderRadius: BorderRadius.circular(99),
              border: Border.all(color: HC.line),
            ),
            child: Text(
              tip,
              textDirection: tipLtr ? TextDirection.ltr : null,
              style: ku(12, c: tipColor),
            ),
          ),
        ],
      ),
    );
  }
}

/// سێ خانەی کەمترین / زۆرترین / ناوەند
class StatItem {
  const StatItem(this.value, this.label, this.k, {this.unit = ''});
  final String value;
  final String label;
  final Color k;
  final String unit;
}

class StatRow extends StatelessWidget {
  const StatRow(this.items, {super.key});
  final List<StatItem> items;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Row(
        children: [
          for (int i = 0; i < items.length; i++) ...[
            if (i > 0) const SizedBox(width: 10),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: HC.card,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: HC.line),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Stack(
                    children: [
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        height: 3,
                        child: AnimatedContainer(duration: const Duration(milliseconds: 300), color: items[i].k),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text.rich(
                              TextSpan(children: [
                                TextSpan(text: items[i].value, style: nu(28, c: HC.tx, h: 1.15)),
                                if (items[i].unit.isNotEmpty)
                                  TextSpan(text: items[i].unit, style: ku(14, c: HC.mu)),
                              ]),
                              textAlign: TextAlign.center,
                              textDirection: TextDirection.ltr,
                            ),
                            const SizedBox(height: 2),
                            Text(items[i].label, textAlign: TextAlign.center, style: ku(12, c: HC.mu)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// ئاستەکان (ئاسایی، کەمێک نزم ...)
class ZoneItem {
  const ZoneItem(this.name, this.range, this.k);
  final String name;
  final String range;
  final Color k;
}

class ZoneList extends StatelessWidget {
  const ZoneList(this.items, this.active, {super.key});
  final List<ZoneItem> items;
  final int active;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (int i = 0; i < items.length; i++)
            AnimatedContainer(
              duration: const Duration(milliseconds: 350),
              margin: EdgeInsets.only(top: i > 0 ? 8 : 0),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
              decoration: BoxDecoration(
                color: i == active ? const Color(0x14FFFFFF) : HC.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: i == active ? items[i].k : HC.line, width: i == active ? 1.5 : 1),
                boxShadow: i == active
                    ? [BoxShadow(color: op(items[i].k, 0.55), blurRadius: 22, offset: const Offset(0, 6), spreadRadius: -8)]
                    : const [],
              ),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: items[i].k,
                      boxShadow: [BoxShadow(color: items[i].k, blurRadius: 10)],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text(items[i].name, style: ku(15, w: FontWeight.w600, c: HC.tx))),
                  Text(items[i].range,
                      textDirection: TextDirection.ltr,
                      style: ku(14, c: i == active ? HC.tx : HC.mu)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// ناونیشانی تەوەرەی x
class XLabels extends StatelessWidget {
  const XLabels(this.labels, {super.key, this.padLeft = 30, this.padRight = 4, this.top = 4});
  final List<String> labels;
  final double padLeft;
  final double padRight;
  final double top;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Padding(
        padding: EdgeInsets.fromLTRB(padLeft, top, padRight, 0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [for (final l in labels) Text(l, style: ku(11, c: HC.mu))],
        ),
      ),
    );
  }
}

/// سەرچاوەکان + تێبینی دیمۆ
class SourcesNote extends StatelessWidget {
  const SourcesNote({super.key, this.sources = true, this.demo = 'دیمۆی دیزاین · داتاکان نموونەن · تەنها بۆ زانیاری گشتییە'});
  final bool sources;
  final String demo;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (sources)
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 20, 4, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('سەرچاوەکان', style: ku(13, w: FontWeight.w600, c: HC.mu)),
                const SizedBox(height: 4),
                Text('1. WHO (2020) — ڕێنمایی چالاکی جەستەیی', style: ku(12, c: HC.mu, h: 1.9)),
                Text('2. CDC — مەترسییەکانی تەندروستی لە دانیشتنی درێژخایەن', style: ku(12, c: HC.mu, h: 1.9)),
              ],
            ),
          ),
        Padding(
          padding: const EdgeInsets.only(top: 16),
          child: Text(demo, textAlign: TextAlign.center, style: ku(11, c: op(HC.mu, 0.75))),
        ),
      ],
    );
  }
}

/// جووڵەی کێشانی هێڵی هێڵکاری (وەک وێب)
class ChartAnim {
  ChartAnim(this.t);
  final double t;

  /// هێڵ: دوای 0.1 چرکە دەست پێدەکات و 1.2 چرکە دەخایەنێت
  double line(double total, {double delay = 0.1, double dur = 1.2}) =>
      const Cubic(0.3, 0.8, 0.3, 1.0).transform(clampD((t * total - delay) / dur, 0, 1));

  /// ڕووبەر: دوای 0.8 چرکە دەردەکەوێت
  double area(double total, {double delay = 0.8, double dur = 0.9}) =>
      clampD((t * total - delay) / dur, 0, 1);
}
