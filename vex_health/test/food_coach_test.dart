// تاقیکردنەوەی ڕاهێنەری خواردن: بزوێنەری پلان (هەموو ئامانج، نەخۆشی و هەستیارییەک) + UI
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vex_health/core/theme.dart';
import 'package:vex_health/food/food_db.dart';
import 'package:vex_health/food/food_design.dart';
import 'package:vex_health/onboarding/reg_lang_state.dart';

const _allgWords = {
  'gluten': ['نان', 'کولێرە', 'ساوەر', 'پاستا', 'کوسکوس', 'فریکە', 'شەعریە', 'گەنم', 'شۆفان'],
  'lact': ['ماست', 'شیر', 'پەنیر', 'جاجیک', 'لەبنە'],
  'nuts': ['گوێز', 'بادەم', 'فستق', 'کاجۆ', 'فندق'],
  'egg': ['هێلکە', 'ئۆملێت', 'عەجە'],
  'fish': ['ماسی', 'تونە', 'سەلمۆن', 'سەردین', 'مەسگووف'],
  'shell': ['میگوو', 'میگۆ', 'کریڤێت'],
  'sesame': ['کونجی', 'تەحین', 'حومس', 'حەلاوە', 'موتەبەل'],
};

Map<String, dynamic> _prof(String goal, {String sex = 'm', double age = 30, double h = 175, double w = 77, double tw = 0, double act = 1.55, int days = 3, List<String> conds = const [], List<String> allg = const [], double pace = .5}) => {
      'name': 'هگف', 'sex': sex, 'age': age, 'h': h, 'w': w, 'tw': tw, 'goal': goal, 'pace': pace, 'act': act, 'days': days,
      'conds': conds, 'allg': allg, 'note': '', 'where': '',
    };

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  test('coach engine: every goal × condition × allergy', () async {
    await FoodDb.I.load();
    expect(FoodDb.I.foods.length, greaterThan(400));
    final cases = <Map<String, dynamic>>[];
    const goals = ['lose', 'keep', 'muscle', 'gain', 'aging'];
    const condSets = [<String>[], ['heart'], ['diab', 'bp', 'chol'], ['kid', 'gout'], ['preg'], ['bf', 'gerd']];
    const allgSets = [<String>[], ['lact'], ['gluten', 'egg'], ['nuts', 'fish', 'shell', 'sesame'], ['gluten', 'lact', 'egg', 'sesame', 'soy']];
    var k = 0;
    for (final g in goals) {
      for (final c in condSets) {
        for (final a in allgSets) {
          k++;
          final f = k.isEven;
          cases.add(_prof(g, sex: f ? 'f' : 'm', age: 20.0 + (k * 7) % 55, h: f ? 160 : 178, w: f ? 58.0 + k % 30 : 70.0 + k % 40, act: const [1.2, 1.375, 1.55, 1.725][k % 4], days: k % 8, conds: c, allg: a, pace: const [.25, .5, .75][k % 3]));
        }
      }
    }
    var worst = 1.0, best = 0.0, n = 0, issues = <String>[];
    for (final P in cases) {
      for (final wk in ['2026-10-24', '2026-10-31']) {
        final week = debugCoachWeek(P, wk: wk);
        expect(week.length, 7);
        for (var di = 0; di < 7; di++) {
          final d = week[di];
          final ratio = (d['kcal'] as double) / (d['target'] as int);
          worst = ratio < worst ? ratio : worst;
          best = ratio > best ? ratio : best;
          n++;
          final tag = '${P['goal']} ${P['conds']} ${P['allg']} d$di';
          if (ratio < .8 || ratio > 1.15) issues.add('$tag kcal ${(ratio * 100).round()}%');
          final slots = d['slots'] as Map<String, List<List<Object>>>;
          for (final s in ['b', 'l', 's', 'd']) {
            if ((slots[s] ?? const []).isEmpty) issues.add('$tag empty $s');
          }
          for (final e in slots.entries) {
            for (final it in e.value) {
              final id = it[0] as String, cat = it[1] as String, q = it[4] as double, mn = it[5] as double, mx = it[6] as double;
              final tags = it[7] as List<String>, ku = it[8] as String;
              if (const {'fast', 'sweets', 'drinks', 'extras'}.contains(cat)) issues.add('$tag bad cat $id');
              if (q < mn - 1e-9 || q > mx + 1e-9) issues.add('$tag qty $id $q [$mn,$mx]');
              for (final a in (P['allg'] as List<String>)) {
                if (tags.contains(a)) issues.add('$tag allergen $a in $id');
                final toks = ku.split(RegExp(r'[\s()\-،,/]+'));
                for (final w in _allgWords[a] ?? const <String>[]) {
                  if (toks.any((x) => x == w || x == '${w}ی' || x == '${w}ە' || x == '${w}ەی')) issues.add('$tag allergen word $w in $ku');
                }
              }
              final c = P['conds'] as List<String>;
              if (c.contains('diab') && cat == 'dates') issues.add('$tag diab dates $id');
              if (c.contains('gout') && RegExp(r'جگەر|گورچیلە|پاچە|سەردین').hasMatch(ku)) issues.add('$tag gout $id');
              if (ku.contains('ترش')) issues.add('$tag pickle $id');
            }
          }
        }
      }
    }
    // نموونە بۆ لۆگ
    for (final P in [
      _prof('lose', w: 77, tw: 66, conds: ['heart']),
      _prof('muscle', w: 70, tw: 76, act: 1.725, days: 5),
      _prof('keep', sex: 'f', w: 62, allg: ['gluten', 'lact'], conds: ['diab']),
    ]) {
      final week = debugCoachWeek(P);
      // ignore: avoid_print
      print('=== ${P['goal']} ${P['conds']} ${P['allg']} target ${week[0]['target']} pool ${week[0]['pool']}');
      for (var di = 0; di < 7; di++) {
        final d = week[di];
        // ignore: avoid_print
        print('  d$di ${(d['kcal'] as double).round()} kcal P${(d['p'] as double).round()}');
        (d['slots'] as Map<String, List<List<Object>>>).forEach((s, l) {
          // ignore: avoid_print
          print('     $s: ${l.map((it) => '${it[8]} ${it[2]} (${(it[3] as double).round()})').join(' · ')}');
        });
      }
    }
    // ignore: avoid_print
    print('days $n · kcal ratio ${(worst * 100).round()}%..${(best * 100).round()}% · issues ${issues.length}');
    for (final i in issues.take(80)) {
      // ignore: avoid_print
      print('ISSUE $i');
    }
    expect(issues, isEmpty);
  });

  testWidgets('coach tab UI', (t) async {
    await t.runAsync(() => FoodDb.I.load());
    final today = DateTime.now();
    String key(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    final w0 = key(today.subtract(const Duration(days: 21)));
    final w1 = key(today.subtract(const Duration(days: 8)));
    SharedPreferences.setMockInitialValues({
      'vexfd_v1': jsonEncode({
        'prof': _prof('lose', w: 79, tw: 66, conds: ['heart'], days: 3, act: 1.375),
        'days': {},
        'fav': [],
        'weights': [
          {'d': w0, 'kg': 79.0},
          {'d': w1, 'kg': 77.0},
        ],
        'custom': [],
      }),
    });
    await t.binding.setSurfaceSize(const Size(400, 3000));
    LangState.I.code = 'ckb';
    await t.runAsync(() => VexTheme.I.setMode(VexMode.dark));
    await t.pumpWidget(MaterialApp(navigatorKey: navKey, home: const FoodDesignPage(tab: 'plan')));
    Future<void> settle([int ms = 400]) async {
      await t.runAsync(() => Future<void>.delayed(Duration(milliseconds: ms)));
      for (var i = 0; i < 14; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }
    }

    await settle(600);
    await settle(300);
    expect(t.takeException(), isNull);
    await expectLater(find.byType(FoodDesignPage), matchesGoldenFile('goldens/coach_dark.png'));
    final texts = t.widgetList<Text>(find.byType(Text)).map((w) => w.data ?? w.textSpan?.toPlainText() ?? '').where((s) => s.trim().isNotEmpty).toList();
    // ignore: avoid_print
    print('TEXTS ${texts.length}: ${texts.take(60).join(' | ')}');
    expect(find.textContaining('ڕاهێنەری هگف'), findsOneWidget);
    expect(find.textContaining('پلانی هەفتە'), findsOneWidget);

    // کردنەوەی ژەمی بەیانی + زیاتر
    await t.tap(find.textContaining('بەیانی').last);
    await settle();
    await t.tap(find.textContaining('زیاتر لە ڕاهێنەرەکە'));
    await settle();
    expect(t.takeException(), isNull);
    await expectLater(find.byType(FoodDesignPage), matchesGoldenFile('goldens/coach_open_dark.png'));

    // خواردم ← تۆمار
    await t.tap(find.textContaining('خواردم').first);
    await settle();
    expect(t.takeException(), isNull);

    // ڕووناک
    await t.runAsync(() => VexTheme.I.setMode(VexMode.light));
    await settle();
    await expectLater(find.byType(FoodDesignPage), matchesGoldenFile('goldens/coach_light.png'));

    // بەشەکانی زیاتر
    for (final seg in ['کات', 'ڕاپۆرت', 'ئامۆژگاری', 'بخۆ و نەخۆ']) {
      await t.ensureVisible(find.text(seg).first);
      await t.pump();
      await t.tap(find.text(seg).first);
      await settle(150);
      expect(t.takeException(), isNull);
    }
    await expectLater(find.byType(FoodDesignPage), matchesGoldenFile('goldens/coach_eat_light.png'));

    // شیتی کێش
    await t.ensureVisible(find.text('کێش').first);
    await t.pump();
    await t.tap(find.text('کێش').first);
    await settle();
    expect(t.takeException(), isNull);
    await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/coach_weight_sheet.png'));
    await t.tap(find.text('پاشەکەوتکردن').first);
    await settle();

    // شیتی ڕاهێنان
    await t.tap(find.text('ڕاهێنان').first);
    await settle();
    await t.tap(find.text('هەینی').last);
    await settle(150);
    await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/coach_train_sheet.png'));
    await t.tap(find.text('پاشەکەوتکردن').first);
    await settle();
    expect(t.takeException(), isNull);

    // گۆڕینی ژەم
    await t.ensureVisible(find.textContaining('نیوەڕۆ').last);
    await t.pump();
    await t.tap(find.textContaining('نیوەڕۆ').last);
    await settle();
    await t.ensureVisible(find.text('گۆڕین').first);
    await t.pump();
    await t.tap(find.text('گۆڕین').first);
    await settle();
    expect(t.takeException(), isNull);

    // پرسیار
    await t.ensureVisible(find.text('پرسیار').first);
    await t.pump();
    await t.tap(find.text('پرسیار').first);
    await settle();
    await t.enterText(find.byType(TextField), 'چی بخۆم؟');
    await t.pump();
    await t.tap(find.byIcon(Icons.add_rounded).last);
    await settle();
    expect(t.takeException(), isNull);
    await expectLater(find.byType(FoodDesignPage), matchesGoldenFile('goldens/coach_ask_light.png'));
    await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 200)));
    await t.pump(const Duration(seconds: 5));
  });
}
