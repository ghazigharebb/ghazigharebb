// تاقیکردنەوەی شیکاری خواردن: داتای 30 ڕۆژ + Band ـی ڕاستەقینە (خەو و هەنگاو)
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vex_health/band/ble/vex_ble.dart';
import 'package:vex_health/band/ble/vex_parsers.dart';
import 'package:vex_health/core/theme.dart';
import 'package:vex_health/food/food_db.dart';
import 'package:vex_health/food/food_design.dart';
import 'package:vex_health/onboarding/reg_lang_state.dart';
import 'package:vex_health/vitalage/vital_age_engine.dart';

String _k(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

Map<String, dynamic> _e(String n, double kcal, double p, double c, double f, {String v = 'ok', double fib = 3, double sug = 5, double salt = .6}) =>
    {'n': n, 'kcal': kcal, 'p': p, 'c': c, 'f': f, 'fib': fib, 'sug': sug, 'salt': salt, 'q': '1', 'at': '12:00', 'fid': '', 'v': v, 'note': ''};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  Future<void> run(WidgetTester t, {required bool data, required bool light}) async {
    await t.runAsync(() => FoodDb.I.load());
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final days = <String, dynamic>{};
    if (data) {
      for (var i = 0; i < 30; i++) {
        if (i % 7 == 3) continue; // ڕۆژێکی تۆمارنەکراو لە هەر هەفتەیەک
        final big = i % 4 == 1;
        days[_k(today.subtract(Duration(days: i)))] = {
          'water': 4 + i % 5,
          'm': {
            'b': i % 3 == 2 ? [] : [_e('هێلکەی کوڵاو', 230, 19, 2, 16), _e('نانی تەنوور', 300, 10, 60, 2, fib: 2)],
            'l': [_e('برنج و شلەی فاسۆلیا', big ? 1100 : 700, 25, 110, 20, v: big ? 'mid' : 'ok', fib: 9)],
            's': [_e('سێو', 95, 0.5, 25, 0.3, sug: 19, fib: 4)],
            'd': [_e('کەباب', big ? 900 : 600, 35, 30, 30, v: big ? 'bad' : 'mid', salt: 2.4)],
            'n': i % 5 == 0 ? [_e('بسکیت', 250, 3, 35, 11, v: 'bad', sug: 18)] : [],
          },
        };
      }
    }
    SharedPreferences.setMockInitialValues({
      'vexfd_v1': jsonEncode({
        'prof': {
          'name': 'هگف', 'sex': 'm', 'age': 30, 'h': 178, 'w': 77, 'tw': 66, 'goal': 'lose', 'pace': .5, 'act': 1.375, 'days': 3,
          'conds': [], 'allg': [], 'note': '', 'where': '',
        },
        'days': days,
        'fav': [],
        'weights': data
            ? [
                {'d': _k(today.subtract(const Duration(days: 28))), 'kg': 80.4},
                {'d': _k(today.subtract(const Duration(days: 21))), 'kg': 79.6},
                {'d': _k(today.subtract(const Duration(days: 14))), 'kg': 78.9},
                {'d': _k(today.subtract(const Duration(days: 7))), 'kg': 78.1},
                {'d': _k(today), 'kg': 77.0},
              ]
            : [],
        'custom': [],
      }),
    });
    if (data) {
      // Band: هەنگاو و خەوی 7 ڕۆژ
      VexBand.I.stepsDays.clear();
      VexBand.I.sleepHist.clear();
      for (var i = 0; i < 7; i++) {
        final d = today.subtract(Duration(days: i));
        VexBand.I.stepsDays.add(VexDaySteps(d, 5000 + i * 1300, i.isEven ? 45 : 10, 4.2, 260, 10000));
        final start = d.subtract(const Duration(hours: 1)); // 23:00 ی شەوی پێشوو
        final mins = (i.isEven ? 5.5 : 7.5) * 60;
        VexBand.I.sleepHist.add(VexSleepRec(start, List<int>.filled((mins / 5).round(), i % 3 + 1), 5));
      }
      await t.runAsync(() => VitalAgeEngine.I.init());
      VitalAgeEngine.I.ingest(VexBand.I);
    }
    await t.binding.setSurfaceSize(const Size(400, 4200));
    LangState.I.code = 'ckb';
    await t.runAsync(() => VexTheme.I.setMode(light ? VexMode.light : VexMode.dark));
    await t.pumpWidget(MaterialApp(navigatorKey: navKey, home: const FoodDesignPage(tab: 'stats')));
  }

  void noErr(WidgetTester t) {
    final e = t.takeException();
    if (e != null) {
      // ignore: avoid_print
      print('ERR ${e is FlutterError ? e.toStringDeep() : e}');
    }
    expect(e, isNull);
  }

  Future<void> settle(WidgetTester t, [int ms = 400]) async {
    await t.runAsync(() => Future<void>.delayed(Duration(milliseconds: ms)));
    for (var i = 0; i < 14; i++) {
      await t.pump(const Duration(milliseconds: 100));
    }
  }

  testWidgets('stats tab: full data, all interactions', (t) async {
    final old = FlutterError.onError;
    FlutterError.onError = (d) {
      // ignore: avoid_print
      print('FERR ${d.toString().split('\n').take(40).join('\n')}');
      old?.call(d);
    };
    await run(t, data: true, light: false);
    await settle(t, 700);
    await expectLater(find.byType(FoodDesignPage), matchesGoldenFile('goldens/stats_first.png'));
    noErr(t);
    expect(find.textContaining('کالۆری 7 ڕۆژی ڕابردوو'), findsOneWidget);
    expect(find.text('6/7'), findsWidgets); // ڕۆژی تۆمارکراو
    expect(find.text('Band و خواردن · 7 ڕۆژ'), findsOneWidget);
    expect(find.textContaining('6.'), findsWidgets); // ناوەندی خەو
    await expectLater(find.byType(FoodDesignPage), matchesGoldenFile('goldens/stats_dark.png'));

    // کرتە لەسەر ستوونێک
    await t.tap(find.text('ئەمڕۆ').last);
    await settle(t, 100);
    // 30 ڕۆژ
    await t.tap(find.text('30 ڕۆژ'));
    await settle(t);
    noErr(t);
    expect(find.textContaining('کالۆری 30 ڕۆژی ڕابردوو'), findsOneWidget);
    // دابەشبوونی ناوەندی
    await t.tap(find.text('30 ڕۆژ').last);
    await settle(t);
    noErr(t);
    expect(find.text('دابەشبوونی ناوەندی'), findsOneWidget);
    // شیکردنەوەی هەفتە
    await t.ensureVisible(find.text('هەفتەکەم شی بکەرەوە'));
    await t.pump();
    await t.tap(find.text('هەفتەکەم شی بکەرەوە'));
    await settle(t);
    noErr(t);
    expect(find.text('چی باش بوو'), findsOneWidget);
    expect(find.text('3 هەنگاو بۆ هەفتەی داهاتوو'), findsOneWidget);
    await expectLater(find.byType(FoodDesignPage), matchesGoldenFile('goldens/stats_open_dark.png'));
    final texts = t.widgetList<Text>(find.byType(Text)).map((w) => w.data ?? '').where((s) => s.length > 25).toList();
    // ignore: avoid_print
    print('REPORT ${texts.join(' | ')}');

    // ڕووناک
    await t.runAsync(() => VexTheme.I.setMode(VexMode.light));
    await settle(t);
    noErr(t);
    await expectLater(find.byType(FoodDesignPage), matchesGoldenFile('goldens/stats_light.png'));

    // تۆمارکردنی کێش ← بەشی من
    await t.ensureVisible(find.text('تۆمارکردنی کێش و ئامانج'));
    await t.pump();
    await t.tap(find.text('تۆمارکردنی کێش و ئامانج'));
    await settle(t);
    noErr(t);
    await t.pump(const Duration(seconds: 5));
    FlutterError.onError = old;
  });
}
