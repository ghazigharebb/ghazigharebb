// تاقیکردنەوەی ڕاپۆرتی گشتی: ماوەکان (24 کاتژمێر / 3 / 7 / 30 ڕۆژ / دیاریکراو)، سڕینەوەی دوای 30 ڕۆژ،
// هاوکاتکردنی هەموو، ڕۆژژمێر و PDF — لەگەڵ وێنە (golden) بۆ هەر یەکێکیان
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

String _k(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  final now = DateTime.now();
  final day = DateTime(now.year, now.month, now.day);
  final fd = {
    'prof': {'name': 'kurd story', 'sex': 'm', 'age': 31, 'h': 178, 'w': 75, 'goal': 'keep', 'pace': 0.5, 'act': 1.375},
    'days': {
      for (var i = 0; i <= 34; i += (i < 6 ? 1 : 3))
        _k(day.subtract(Duration(days: i))): {
          'water': 6 + i % 3,
          'm': {
            'b': [{'n': 'هێلکە', 'kcal': 320 + i * 4, 'p': 16, 'c': 30, 'f': 12, 'fib': 3, 'sug': 4, 'salt': 1.2}],
            'l': [{'n': 'برنج', 'kcal': 700, 'p': 30, 'c': 90, 'f': 20, 'fib': 4, 'sug': 5, 'salt': 2.1}],
            'd': [{'n': 'شۆربا', 'kcal': 450, 'p': 22, 'c': 40, 'f': 14, 'fib': 6, 'sug': 3, 'salt': 1.0}],
          }
        }
    },
    'weights': [
      {'d': _k(day.subtract(const Duration(days: 40))), 'kg': 78.0},
      {'d': _k(day.subtract(const Duration(days: 20))), 'kg': 76.2},
      {'d': _k(day.subtract(const Duration(days: 2))), 'kg': 75.0},
    ],
  };

  /// داتای 35 ڕۆژ (5 ڕۆژی کۆنتر لە 30 ڕۆژ بۆ تاقیکردنەوەی سڕینەوە)
  Future<void> seed([Map? f, Map? user]) async {
    SharedPreferences.setMockInitialValues({
      'vexuser': jsonEncode(user ?? {'name': 'kurd story', 'sex': 'm', 'year': now.year - 31, 'h': 178, 'w': 75, 'act': 'light', 'band': {'paired': true}}),
      'vexfd_v1': jsonEncode(f ?? fd),
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
    final rnd = math.Random(7);
    for (var i = 0; i < 35; i++) {
      final d = day.subtract(Duration(days: i));
      if (i != 12) b.stepsDays.add(VexDaySteps(d, i == 0 ? 6240 : 5200 + rnd.nextInt(6200), 40 + i % 30, 4.2, 260, 10000));
      for (var h = 0; h < 24; h++) {
        final t = d.add(Duration(hours: h, minutes: 5));
        if (t.isAfter(now) || i == 12) continue;
        final act = h >= 8 && h <= 21;
        b.hrRest.add(VexSample(t, (act ? 72.0 : 58.0) + rnd.nextInt(9)));
        if (h % 2 == 0) b.spo2Hist.add(VexSample(t.add(const Duration(minutes: 5)), 95.0 + rnd.nextInt(4)));
        if (h % 3 == 0) b.tempHist.add(VexSample(t.add(const Duration(minutes: 7)), 33.0 + rnd.nextInt(9) / 10));
        if (h % 3 == 1) b.hrvHist.add(VexHrvRec(t.add(const Duration(minutes: 9)), 40 + rnd.nextInt(20), 70, 66, 25 + rnd.nextInt(30), 60, 14 + rnd.nextInt(4)));
        if (h == 18) b.hrDyn.add(VexDynHr(t, List<int>.generate(15, (k) => 96 + k)));
      }
      final q = <int>[for (var k = 0; k < 90; k++) [2, 2, 1, 1, 2, 3, 2, 4][k % 8]];
      if (i != 12) b.sleepHist.add(VexSleepRec(d.subtract(const Duration(minutes: 50)), q, 5));
    }
    final tr = List<double>.generate(1200, (k) => math.sin(k / 6) * .2 + (k % 100 == 0 ? .9 : 0));
    for (final ago in [const Duration(hours: 5), const Duration(days: 4), const Duration(days: 40)]) {
      await EcgHistory.add(EcgResult(
        bpm: 68, hrv: 47, stress: 30, stats: const EcgStats(bpm: 68, minBpm: 63, maxBpm: 74, beats: 34), quality: .95,
        trace: tr, sampleRate: 250, rightWrist: false, at: now.subtract(ago),
      ));
    }
    await ReportStore.I.init();
    ReportStore.I.days.clear();
    ReportStore.I.hours.clear();
    ReportStore.I.sleeps.clear();
    ReportStore.I.ingest(b);
    // هەنگاوی کاتژمێر بە کاتژمێر (وەک ئەوەی ئەپەکە کراوە بووبێت)
    final s = ReportStore.I;
    for (var i = 0; i < 30; i++) {
      final t = now.subtract(Duration(hours: i));
      final h = s.hours.putIfAbsent('${_k(t)} ${t.hour.toString().padLeft(2, '0')}', RHour.new);
      final base = t.hour < 7 ? 0 : (t.hour - 6) * (380 + (t.hour * 37) % 260);
      h.sc = base;
    }
    s.markSynced(now.subtract(const Duration(minutes: 3)));
  }

  void noErr(WidgetTester t) {
    final e = t.takeException();
    if (e != null) {
      // ignore: avoid_print
      print('ERR>>> $e');
    }
    expect(e, isNull);
  }

  Future<void> settle(WidgetTester t, [int n = 20]) async {
    await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 300)));
    for (var i = 0; i < n; i++) {
      await t.pump(const Duration(milliseconds: 100));
    }
  }

  Future<void> page(WidgetTester t, String range, {double h = 2200, String lang = 'ckb', bool light = false}) async {
    await t.binding.setSurfaceSize(Size(400, h));
    await t.runAsync(seed);
    LangState.I.code = lang;
    await t.runAsync(() => VexTheme.I.setMode(light ? VexMode.light : VexMode.dark));
    await t.pumpWidget(MaterialApp(navigatorKey: navKey, debugShowCheckedModeBanner: false, home: GeneralReportPage(initialRange: range)));
    await settle(t);
  }

  test('30-day retention: nothing older than 30 days is kept', () async {
    await seed();
    final s = ReportStore.I;
    final cut = _k(ReportStore.firstDay());
    expect(s.days.keys.every((k) => k.compareTo(cut) >= 0), true);
    expect(s.days.length <= 30, true);
    expect(s.hours.keys.every((k) => k.substring(0, 10).compareTo(cut) >= 0), true);
    expect(s.sleeps.values.every((x) => !x.end.isBefore(ReportStore.firstDay())), true);
    expect(s.days.containsKey(cut), true);
    // ڕۆژی دواتر: ڕۆژی 31 (یەکەم ڕۆژ) دەسڕێتەوە
    final tomorrow = now.add(const Duration(days: 1));
    expect(s.prune(tomorrow), true);
    expect(s.days.containsKey(cut), false);
    expect(s.days.keys.every((k) => k.compareTo(_k(ReportStore.firstDay(tomorrow))) >= 0), true);
    // ignore: avoid_print
    print('RETENTION days=${s.days.length} hours=${s.hours.length} sleeps=${s.sleeps.length}');
  });

  test('personalized text differs per person, goal and range', () async {
    await seed();
    final a7 = await generalReportText(range: ReportRange.lastDays(7));
    final a24 = await generalReportText(range: ReportRange.h24());
    // کەسی دووەم: ئامانجی دابەزاندنی کێش، 96 کگ، تەمەن 67
    final f2 = Map<String, dynamic>.of(fd);
    f2['prof'] = {'name': 'Aram', 'sex': 'm', 'age': 67, 'h': 172, 'w': 96, 'goal': 'lose', 'pace': 0.5, 'act': 1.2, 'conds': ['diab', 'bp']};
    f2['weights'] = [
      {'d': _k(day.subtract(const Duration(days: 6))), 'kg': 97.4},
      {'d': _k(day.subtract(const Duration(days: 1))), 'kg': 96.0},
    ];
    await seed(f2, {'name': 'Aram', 'sex': 'm', 'year': now.year - 67, 'h': 172, 'w': 96, 'act': 'sed', 'conds': ['diab', 'bp'], 'band': {'paired': true}});
    final b7 = await generalReportText(range: ReportRange.lastDays(7));
    for (final lang in ['ckb', 'kmr', 'en', 'ar', 'fa', 'tr']) {
      LangState.I.code = lang;
      final x = await generalReportText(range: ReportRange.lastDays(7));
      // ignore: avoid_print
      print('STORY[$lang] ${x.story.join(' ¶ ')}\nRECS[$lang] ${x.recs.join(' | ')}');
      expect(x.story.join().contains('{'), false);
      expect(x.recs.join().contains('{'), false);
    }
    LangState.I.code = 'ckb';
    // ignore: avoid_print
    print('A7 ${a7.story.join(' ¶ ')}\nA24 ${a24.story.join(' ¶ ')}\nRECS-A ${a7.recs.join(' | ')}');
    expect(a7.story.join() == b7.story.join(), false);
    expect(a7.story.join() == a24.story.join(), false);
    expect(a7.story.first.contains('kurd story'), true);
    expect(b7.story.first.contains('Aram'), true);
    expect(b7.story.join().contains('1.4'), true); // 97.4 → 96.0 = 1.4 کگ کەم
    expect(b7.recs.any((x) => x.contains('67')), true); // ڕاسپاردەی تەمەن
  });

  test('ranges', () {
    final t = DateTime(2026, 11, 1, 19, 6);
    final h = ReportRange.h24(t);
    expect(h.hourly, true);
    expect(h.from, DateTime(2026, 10, 31, 19, 6));
    expect(ReportRange.lastDays(7, t).dayKeys, ['2026-10-26', '2026-10-27', '2026-10-28', '2026-10-29', '2026-10-30', '2026-10-31', '2026-11-01']);
    expect(ReportRange.lastDays(30, t).dayKeys.first, '2026-10-03');
    expect(ReportRange.lastDays(99, t).days, 30);
    final c = ReportRange.custom(DateTime(2026, 9, 1), DateTime(2026, 10, 28), t);
    expect(c.fromKey, '2026-10-03');
    expect(c.toKey, '2026-10-28');
    expect(c.days, 26);
    expect(ReportRange.custom(DateTime(2026, 10, 28), DateTime(2026, 10, 20), t).days, 9);
    expect(ReportRange.lastDays(7, t).dates, '26 Oct – 1 Nov 2026');
    expect(h.dates, '31 Oct 19:06 – 1 Nov 19:06');
  });

  for (final range in ['d7', 'h24', 'd30', 'd3']) {
    testWidgets('report $range', (t) async {
      await page(t, range, h: 9000);
      await expectLater(find.byType(GeneralReportPage), matchesGoldenFile('goldens/report_${range}_full.png'));
      noErr(t);
      await t.binding.setSurfaceSize(const Size(400, 860));
      await t.pump(const Duration(milliseconds: 200));
      await expectLater(find.byType(GeneralReportPage), matchesGoldenFile('goldens/report_${range}_top.png'));
    });
  }

  testWidgets('sync everything', (t) async {
    await page(t, 'd7', h: 860);
    noErr(t);
    await t.tap(find.text('هاوکاتکردنی هەموو'));
    for (var i = 0; i < 6; i++) {
      await t.pump(const Duration(milliseconds: 120));
    }
    await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 200)));
    await t.pump(const Duration(milliseconds: 150));
    await expectLater(find.byType(GeneralReportPage), matchesGoldenFile('goldens/report_sync_mid.png'));
    for (var i = 0; i < 40; i++) {
      await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 60)));
      await t.pump(const Duration(milliseconds: 100));
    }
    noErr(t);
  });

  testWidgets('calendar', (t) async {
    await page(t, 'd7', h: 900);
    noErr(t);
    await t.tap(find.byKey(const ValueKey('rng-c'))); // دوگمەی ڕۆژژمێر
    await settle(t, 10);
    final today = DateTime.now();
    final a = today.subtract(const Duration(days: 9)), b = today.subtract(const Duration(days: 3));
    await t.tap(find.byKey(ValueKey('day-${_k(a)}')));
    await t.pump(const Duration(milliseconds: 200));
    await t.tap(find.byKey(ValueKey('day-${_k(b)}')));
    await settle(t, 6);
    await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/report_calendar.png'));
    await t.tap(find.textContaining('پیشاندانی'));
    await settle(t, 10);
    noErr(t);
    await expectLater(find.byType(GeneralReportPage), matchesGoldenFile('goldens/report_custom_top.png'));
  });

  for (final lang in ['en', 'ar', 'kmr', 'fa', 'tr']) {
    testWidgets('report $lang', (t) async {
      final prev = FlutterError.onError;
      FlutterError.onError = (d) {
        // ignore: avoid_print
        print('DETAIL>>> ${d.toString()}');
        prev?.call(d);
      };
      await page(t, 'd7', h: 9000, lang: lang);
      FlutterError.onError = prev;
      await expectLater(find.byType(GeneralReportPage), matchesGoldenFile('goldens/report_lang_${lang}_full.png'));
      noErr(t);
      await t.binding.setSurfaceSize(const Size(400, 860));
      await t.pump(const Duration(milliseconds: 200));
      await expectLater(find.byType(GeneralReportPage), matchesGoldenFile('goldens/report_lang_$lang.png'));
    });
  }

  testWidgets('report light', (t) async {
    await page(t, 'h24', h: 2600, light: true);
    await expectLater(find.byType(GeneralReportPage), matchesGoldenFile('goldens/report_light.png'));
    noErr(t);
  });

  for (final range in ['d30', 'h24']) {
    testWidgets('pdf $range', (t) async {
      await t.binding.setSurfaceSize(const Size(400, 900));
      await t.runAsync(seed);
      LangState.I.code = 'ckb';
      await t.pumpWidget(MaterialApp(navigatorKey: navKey, home: const Scaffold(body: SizedBox())));
      final bytes = await t.runAsync(() async {
        final f = generalReportPdf(range: range == 'h24' ? ReportRange.h24() : ReportRange.lastDays(30));
        for (var i = 0; i < 60; i++) {
          await Future<void>.delayed(const Duration(milliseconds: 50));
          t.binding.scheduleFrame();
          await t.pump();
        }
        return f;
      });
      expect(bytes, isNotNull);
      expect(String.fromCharCodes(bytes!.take(4)), '%PDF');
      Directory('test/goldens').createSync(recursive: true);
      File('test/goldens/report_$range.pdf').writeAsBytesSync(bytes);
      // ignore: avoid_print
      print('PDF $range bytes: ${bytes.length}');
    });
  }
}
