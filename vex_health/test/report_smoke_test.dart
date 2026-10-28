// تاقیکردنەوەی ڕاپۆرتی گشتی: داتای ساختەی Band + ECG + خواردن ← پەڕە بێ هەڵە + PDF
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vex_health/band/band_state.dart';
import 'package:vex_health/band/ble/vex_ble.dart';
import 'package:vex_health/band/ble/vex_parsers.dart';
import 'package:vex_health/core/theme.dart';
import 'package:vex_health/ecg/ecg_controller.dart';
import 'package:vex_health/ecg/ecg_history.dart';
import 'package:vex_health/ecg/ecg_signal.dart';
import 'package:vex_health/onboarding/account.dart';
import 'package:vex_health/onboarding/reg_lang_state.dart';
import 'package:vex_health/report/general_report.dart';
import 'package:vex_health/vitalage/vital_age_engine.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  final now = DateTime.now();
  final day = DateTime(now.year, now.month, now.day);
  final fd = {
    'prof': {'name': 'Ghazi', 'sex': 'm', 'age': 32, 'h': 178, 'w': 77, 'goal': 'lose', 'pace': 0.5, 'act': 1.375, 'conds': ['bp']},
    'days': {
      for (var i = 1; i <= 10; i++)
        '${day.subtract(Duration(days: i)).year}-${day.subtract(Duration(days: i)).month.toString().padLeft(2, '0')}-${day.subtract(Duration(days: i)).day.toString().padLeft(2, '0')}': {
          'water': 6,
          'm': {
            'b': [{'n': 'هێلکە', 'kcal': 320, 'p': 16, 'c': 30, 'f': 12, 'fib': 3, 'sug': 4, 'salt': 1.2}],
            'l': [{'n': 'برنج', 'kcal': 700, 'p': 30, 'c': 90, 'f': 20, 'fib': 4, 'sug': 5, 'salt': 2.6}],
          }
        }
    },
    'weights': [
      {'d': '2026-09-01', 'kg': 78.0},
      {'d': '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}', 'kg': 76.4}
    ],
  };

  Future<void> seed() async {
    SharedPreferences.setMockInitialValues({
      'vexuser': jsonEncode({'name': 'Ghazi', 'sex': 'm', 'year': 1994, 'h': 178, 'w': 77, 'act': 'light', 'conds': ['bp'], 'band': {'paired': true}}),
      'vexfd_v1': jsonEncode(fd),
    });
    await Account.I.load();
    await BandState.I.load();
    await VitalAgeEngine.I.init();
    final b = VexBand.I;
    b.stepsDays.clear();
    b.hrRest.clear();
    b.spo2Hist.clear();
    b.tempHist.clear();
    b.hrvHist.clear();
    b.hrDyn.clear();
    b.sleepHist.clear();
    for (var i = 0; i < 12; i++) {
      final d = day.subtract(Duration(days: i));
      b.stepsDays.add(VexDaySteps(d, 6000 + i * 300, 40 + i, 4.2, 260, 10000));
      for (var h = 0; h < 24; h += 2) {
        b.hrRest.add(VexSample(d.add(Duration(hours: h)), 58.0 + h % 7 + i % 3));
        b.spo2Hist.add(VexSample(d.add(Duration(hours: h)), 95.0 + h % 4));
        b.tempHist.add(VexSample(d.add(Duration(hours: h)), 33.2 + (h % 5) / 10));
      }
      b.hrvHist.add(VexHrvRec(d.add(const Duration(hours: 9)), 45 + i % 6, 70, 66, 38 + i % 9, 60, 15));
      b.hrDyn.add(VexDynHr(d.add(const Duration(hours: 18)), List<int>.generate(15, (k) => 90 + k)));
      final q = <int>[for (var k = 0; k < 84; k++) [2, 2, 1, 1, 2, 3, 2, 4][k % 8]];
      b.sleepHist.add(VexSleepRec(d.subtract(const Duration(minutes: 40)), q, 5));
    }
    final tr = List<double>.generate(1200, (k) => math.sin(k / 6) * .2 + (k % 100 == 0 ? .9 : 0));
    await EcgHistory.add(EcgResult(
      bpm: 68, hrv: 47, stress: 30, stats: const EcgStats(bpm: 68, minBpm: 63, maxBpm: 74, beats: 34), quality: .95,
      trace: tr, sampleRate: 250, rightWrist: false, at: now.subtract(const Duration(days: 2)),
    ));
    await ReportStore.I.init();
    ReportStore.I.ingest(b);
  }

  testWidgets('warmup fonts', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 4600));
    await tester.runAsync(seed);
    await tester.pumpWidget(MaterialApp(navigatorKey: navKey, home: const GeneralReportPage()));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 800)));
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    final e = tester.takeException();
    // ignore: avoid_print
    print('WARMUP: $e');
  });

  for (final lang in ['ckb', 'en', 'ar', 'kmr', 'fa', 'tr']) {
    for (final light in [false, true]) {
      testWidgets('report $lang ${light ? 'light' : 'dark'}', (tester) async {
        await tester.binding.setSurfaceSize(const Size(400, 4600));
        await tester.runAsync(seed);
        LangState.I.code = lang;
        await tester.runAsync(() => VexTheme.I.setMode(light ? VexMode.light : VexMode.dark));
        await tester.pumpWidget(MaterialApp(navigatorKey: navKey, home: const GeneralReportPage()));
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 300)));
        for (var i = 0; i < 20; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        expect(tester.takeException(), isNull);
        expect(ReportStore.I.days.isNotEmpty, true);
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 400)));
        await tester.pump(const Duration(milliseconds: 100));
        await expectLater(find.byType(GeneralReportPage), matchesGoldenFile('goldens/report_${lang}_${light ? 'light' : 'dark'}.png'));
        await tester.drag(find.byType(ListView), const Offset(0, -2500));
        for (var i = 0; i < 10; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        expect(tester.takeException(), isNull);
        await tester.binding.setSurfaceSize(const Size(400, 120));
        await tester.pumpWidget(MaterialApp(home: Scaffold(backgroundColor: V.bg, body: const Padding(padding: EdgeInsets.all(12), child: ReportCard()))));
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 300)));
        await tester.pump(const Duration(milliseconds: 200));
        expect(tester.takeException(), isNull);
        await expectLater(find.byType(ReportCard), matchesGoldenFile('goldens/card_${lang}_${light ? 'light' : 'dark'}.png'));
      });
    }
  }

  testWidgets('report pdf', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 900));
    await tester.runAsync(seed);
    LangState.I.code = 'ckb';
    await tester.pumpWidget(MaterialApp(navigatorKey: navKey, home: const Scaffold(body: SizedBox())));
    final bytes = await tester.runAsync(() async {
      final f = generalReportPdf();
      for (var i = 0; i < 40; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
        tester.binding.scheduleFrame();
        await tester.pump();
      }
      return f;
    });
    expect(bytes, isNotNull);
    expect(String.fromCharCodes(bytes!.take(4)), '%PDF');
    Directory('test/goldens').createSync(recursive: true);
    File('test/goldens/report.pdf').writeAsBytesSync(bytes);
    // ignore: avoid_print
    print('PDF bytes: ${bytes.length}');
  });
}
