// VEX Health — شیتەکانی وردەکاری (دڵ، ئۆکسجین، سترێس، پێست، خەو، چالاکی)
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/store.dart';
import '../core/theme.dart';
import '../vitalage/vital_age_page.dart';
import '../plus/gate.dart';
import '../band/band_state.dart';

void openMetricDetail(String k) {
  // Band پەیوەست نییە ← پەردەی لێڵ + «Band بکڕە / پەیوەستی بکە»
  if (k != 'act' && !BandState.I.bleUp) {
    final id = const {'hr': 'heart', 'spo2': 'spo2', 'stress': 'stress', 'temp': 'temp', 'sleep': 'sleep'}[k] ?? 'health';
    showVSheet<void>(builder: (_) => Center(child: GateVeil(kind: GateKind.band, id: id)));
    return;
  }
  switch (k) {
    case 'hr':
      showVSheet<void>(builder: (_) => const _HrSheet());
      break;
    case 'spo2':
      _spo2();
      break;
    case 'stress':
      _stress();
      break;
    case 'temp':
      _temp();
      break;
    case 'act':
      openActivitySheet();
      break;
    case 'sleep':
      _sleep();
      break;
  }
}

Widget _txt(String s) => VText(s, style: ku(13, h: 1.8));

// ---------- لێدانی دڵ ----------
class _HrSheet extends StatefulWidget {
  const _HrSheet();

  @override
  State<_HrSheet> createState() => _HrSheetState();
}

class _HrSheetState extends State<_HrSheet> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 2400))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final h = Store.I.h;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        const SheetTitle('❤️ لێدانی دڵ'),
        DBig('${h.hr}', 'BPM · ئاسایی · ڕاستەوخۆ'),
        ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: SizedBox(
            height: 150,
            child: CustomPaint(painter: _EcgPainter(_c)),
          ),
        ),
        K3([K3Item('لە پشوودا', '${h.rhr}'), K3Item('ناوەند', '${h.hrAvg}'), const K3Item('بەرزترین', '118')]),
        Note(_txt('💡 لێدانی دڵی پشوو ${h.rhr} لە ناوچەی ئاساییدایە (60-100). وەرزشی ڕێکوپێک بە تێپەڕبوونی کات کەمی دەکاتەوە.')),
      ],
    );
  }
}

class _EcgPainter extends CustomPainter {
  _EcgPainter(this.a) : super(repaint: a);
  final Animation<double> a;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = vk(0xFF071318));
    final grid = Paint()
      ..color = vk(0x1F3CF08A)
      ..strokeWidth = 1;
    for (double x = 0; x <= size.width; x += 20) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    }
    for (double y = 0; y <= size.height; y += 20) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    final path = Path();
    for (int i = 0; i <= 40; i++) {
      final x = i * 10.0;
      final y = 75 - math.sin(i * 0.7) * 8 - (i % 7 == 3 ? 40 : 0) + (i % 7 == 4 ? 18 : 0);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    final sx = size.width / 400, sy = size.height / 150;
    final shown = 1200 * a.value;
    final out = Path();
    for (final m in path.computeMetrics()) {
      out.addPath(m.extractPath(0, math.min(m.length, shown)), Offset.zero);
    }
    final scaled = out.transform(Matrix4.diagonal3Values(sx, sy, 1).storage);
    canvas.drawPath(
      scaled,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeJoin = StrokeJoin.round
        ..color = V.mint,
    );
  }

  @override
  bool shouldRepaint(covariant _EcgPainter oldDelegate) => false;
}

// ---------- ئۆکسجین ----------
void _spo2() {
  final h = Store.I.h;
  showVSheet<void>(
    builder: (_) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        const SheetTitle('🫁 ئۆکسجینی خوێن (SpO₂)'),
        DBig('${h.spo2}%', 'چاودێری بکە', color: V.amber),
        BarsChart(
          [95, 96, 94, 97, 96, 97, 98, 97, 96, 93, 97, 98, 97, 96, 97, 98, 97, 96, 95, 93],
          vk(0xFF14B8D6),
          85,
          100,
        ),
        K3([
          K3Item('نزمترین', '${h.spo2Min}%'),
          K3Item('ناوەند', '${h.spo2Avg}%'),
          K3Item('ئێستا', '${h.spo2}%'),
        ]),
        Note(_txt(
            '💡 95-100% ئاساییە. ئەگەر بەردەوام کەمتر لە 94% بوو یان هەناسەت قورس بوو، پزیشک ببینە. جووڵەی دەست و شل لەبەرکردنی Band ژمارەکە کەم دەکەنەوە.')),
      ],
    ),
  );
}

// ---------- سترێس ----------
void _stress() {
  final h = Store.I.h;
  showVSheet<void>(
    builder: (ctx) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        const SheetTitle('🧠 سترێس و HRV'),
        DBig('${h.stress}', 'مامناوەند', color: V.amber),
        BarsChart(
          [40, 38, 45, 60, 52, 58, 44, 40, 42, 46, 41, 40, 39, 42, 44, 48, 50, 52, 55, 55],
          vk(0xFFFFBE4D),
          0,
          100,
        ),
        K3([
          K3Item('HRV', '${h.hrv}ms'),
          K3Item('ناوەندی HRV', '${h.hrvAvg}ms'),
          const K3Item('هاوسەنگی', 'باش', isNum: false),
        ]),
        Note(_txt('💡 3 خولەک هەناسەدانی هێواش (4 چرکە هەڵمژین، 6 چرکە دەرکردن) سترێس کەم دەکاتەوە.')),
        const SizedBox(height: 12),
        VBtn(
          '🧘 دەستپێکردنی هەناسەدان',
          kind: BtnKind.prime,
          onTap: () {
            Navigator.of(ctx).pop();
            toast('🧘 هەڵمژە... 4 · 3 · 2 · 1');
          },
        ),
      ],
    ),
  );
}

// ---------- پلەی پێست ----------
void _temp() {
  final h = Store.I.h;
  showVSheet<void>(
    builder: (_) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        const SheetTitle('🌡️ پلەی گەرمی پێست'),
        DBig('${h.temp}°C', 'ئاسایی بۆ مەچەک'),
        BarsChart(
          [33.4, 33.6, 33.9, 34.0, 33.8, 34.1, 34.2, 34.0, 33.7, 33.9, 34.2, 34.1, 34.0, 33.9, 34.2],
          vk(0xFFFF9466),
          32,
          35,
        ),
        K3([
          K3Item('نزمترین', '${h.tempMin}'),
          K3Item('ناوەند', '${h.tempAvg}'),
          K3Item('ئێستا', '${h.temp}'),
        ]),
        Note(VText.rich(
          TextSpan(children: [
            const TextSpan(text: '💡 Band پلەی گەرمی '),
            TextSpan(text: 'پێستی مەچەک', style: ku(13, w: FontWeight.w800, h: 1.8)),
            const TextSpan(text: ' دەپێوێت، کە ئاساییە 32-35°C بێت؛ ئەمە پلەی گەرمی ناوەوەی لەش (37°C) نییە.'),
          ]),
          style: ku(13, h: 1.8),
        )),
      ],
    ),
  );
}

// ---------- خەو ----------
class _Stage {
  const _Stage(this.v, this.col);
  final String v;
  final Color col;
}

List<_Stage?> _sleepStages() {
  final out = <_Stage?>[];
  for (int s = 0; s < 28; s++) {
    final h = s / 4 + 0.125;
    if (h >= 6.84) {
      out.add(null);
      continue;
    }
    if (s == 13) {
      out.add(_Stage('بەئاگا', vk(0xFF5A6B80)));
      continue;
    }
    final cyc = ((h + 24 - 23.67) % 24) / 1.5;
    final f = cyc % 1;
    if (f < 0.35 && cyc < 3) {
      out.add(_Stage('قووڵ', vk(0xFF6F4BFF)));
    } else if (f > 0.74) {
      out.add(_Stage('REM', vk(0xFFD2B6FF)));
    } else {
      out.add(_Stage('سووک', vk(0xFFA58BFF)));
    }
  }
  return out;
}

void _sleep() {
  final ss = _sleepStages();
  int minutes(String v) => ss.where((d) => d != null && d.v == v).length * 15;
  String hm(int m) => '${m ~/ 60}:${pad2(m % 60)}';
  showVSheet<void>(
    builder: (_) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        const SheetTitle('🌙 خەوی دوێنێ شەو'),
        DBig('7:10', 'کاتژمێر · 23:40 → 06:50 · باش', color: vk(0xFFB39DFF)),
        Padding(
          padding: const EdgeInsets.only(top: 6, bottom: 10),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              height: 34,
              child: Directionality(
                textDirection: TextDirection.ltr,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (int i = 0; i < ss.length; i++) ...[
                      if (i > 0) const SizedBox(width: 1),
                      Expanded(child: _stageBar(ss[i])),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
        K3([
          K3Item('قووڵ', hm(minutes('قووڵ')), labelColor: vk(0xFF6F4BFF)),
          K3Item('REM', hm(minutes('REM')), labelColor: vk(0xFFD2B6FF)),
          const K3Item('بەئاگابوون', '1×'),
        ]),
        Note(_txt(
            '💡 خەوی قووڵت باش بوو. لە کاتژمێر 03:15 جارێک بەئاگا هاتیت، کە هاوکات بوو لەگەڵ دابەزینی SpO₂. ئەگەر دووبارە بووەوە، سەرنج بدە ئایا پرخە دەکەیت.')),
      ],
    ),
  );
}

Widget _stageBar(_Stage? d) {
  if (d == null) return const SizedBox.shrink();
  Alignment al;
  double hf;
  if (d.v == 'بەئاگا') {
    al = Alignment.topCenter;
    hf = 0.55;
  } else if (d.v == 'REM') {
    al = Alignment.center;
    hf = 0.55;
  } else if (d.v == 'قووڵ') {
    al = Alignment.bottomCenter;
    hf = 0.55;
  } else {
    al = Alignment.center;
    hf = 1;
  }
  return Align(
    alignment: al,
    child: FractionallySizedBox(
      heightFactor: hf,
      widthFactor: 1,
      child: ColoredBox(color: d.col),
    ),
  );
}

// ---------- چالاکی ----------
void openActivitySheet() {
  final h = Store.I.h;
  showVSheet<void>(
    builder: (_) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        const SheetTitle('🚶 چالاکی'),
        DBig(fmt(h.steps), 'هەنگاو · ${(h.steps / 100).round()}% لە ئامانج'),
        K3([
          K3Item('مەودا', '${h.km}km'),
          K3Item('کالۆری', '${h.kcal}'),
          K3Item('چالاک', '${h.active}خ'),
        ]),
        Note(_txt('💡 ${fmt(10000 - h.steps)} هەنگاوت ماوە، نزیکەی ${((10000 - h.steps) / 100).round()} خولەک پیاسە.')),
      ],
    ),
  );
}

// ---------- ئاگادارکردنەوەکان ----------
void openNotifications() {
  Widget ev(String e, String t, String s) => Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: V.line))),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: V.surf2, borderRadius: BorderRadius.circular(12)),
              child: VText(e, style: const TextStyle(fontSize: 17)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  VText(t, style: ku(13, h: 1.7)),
                  VText(s, style: ku(11, c: V.mu)),
                ],
              ),
            ),
          ],
        ),
      );
  showVSheet<void>(
    builder: (_) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        const SheetTitle('🔔 ئاگادارکردنەوەکان'),
        ev('🫁', 'SpO₂ ـی شەوت 90% بوو', 'ئەگەر بەردەوام بوو پزیشک ببینە'),
        ev('🚶', '7,775 هەنگاوت ماوە بۆ ئامانجی ئەمڕۆ', 'پیاسەیەکی 20 خولەکی یارمەتیت دەدات'),
        ev('💧', 'ئاو بخۆرەوە', '2 کاتژمێرە هیچ ئاوت تۆمار نەکردووە'),
      ],
    ),
  );
}

// ---------- تەمەنی ژیانی ----------
// پەڕەی تەواو: lib/vitalage/vital_age_page.dart
void openVitalAge() => openVitalAgePage();
