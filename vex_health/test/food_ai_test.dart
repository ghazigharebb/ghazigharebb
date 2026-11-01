// تاقیکردنەوەی VEX AI Food v2: داتا، بڕ بە وشە، + / −، نووسین، تۆمارکردن (ماڵەوە + ڕاپۆرت)،
// هەموو ڕێڕەوەکە (کامێرا ← شیکردنەوە ← لیست ← ڕاستکردنەوە ← وردەکاری ← تۆمارکرا) بە وێنە،
// و ڤیدیۆی هەموو ئەپەکە (فرەیم بە فرەیم).
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vex_health/band/band_state.dart';
import 'package:vex_health/core/store.dart';
import 'package:vex_health/core/theme.dart';
import 'package:vex_health/food_ai/food_ai_data.dart';
import 'package:vex_health/food_ai/food_ai_store.dart';
import 'package:vex_health/food_ai/food_ai_tab.dart';
import 'package:vex_health/main.dart';
import 'package:vex_health/onboarding/account.dart';
import 'package:vex_health/plus/plus_state.dart';

const _user = {'name': 'Wasta', 'sex': 'm', 'year': 1994, 'h': 178, 'w': 77, 'act': 'light', 'goal': 'keep'};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  final shotKey = GlobalKey();
  final finger = ValueNotifier<Offset?>(null);
  final press = ValueNotifier<int>(0);
  var frames = 0;
  var recording = false;
  final videoDir = Directory('test/goldens/video');

  final assets = [for (final d in [...kDishes, ...kAltDishes]) d.img!, 'assets/food_ai/wood.jpg'];

  Future<void> reset({bool withUser = true}) async {
    SharedPreferences.setMockInitialValues({
      if (withUser) 'vexuser': jsonEncode(_user),
    });
    await Account.I.load();
    if (withUser) Account.I.user = Map<String, dynamic>.from(_user);
    await Store.I.load();
    Store.I.food.clear();
    FoodAiStore.I.reset();
    await FoodAiStore.I.init();
  }

  Widget harness(Widget app) => RepaintBoundary(
        key: shotKey,
        child: Stack(textDirection: TextDirection.ltr, children: [
          app,
          // پەنجە (بۆ ڤیدیۆ)
          ValueListenableBuilder<Offset?>(
            valueListenable: finger,
            builder: (context, o, _) => ValueListenableBuilder<int>(
              valueListenable: press,
              builder: (context, p, _) => o == null
                  ? const SizedBox.shrink()
                  : Positioned(
                      left: o.dx - 23,
                      top: o.dy - 23,
                      child: IgnorePointer(
                        child: AnimatedScale(
                          scale: p.isOdd ? 0.72 : 1,
                          duration: const Duration(milliseconds: 140),
                          child: Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const RadialGradient(colors: [Color(0x99FFFFFF), Color(0x33FFFFFF)]),
                              border: Border.all(color: Colors.white, width: 2),
                              boxShadow: const [BoxShadow(color: Color(0x88000000), blurRadius: 16, offset: Offset(0, 4))],
                            ),
                          ),
                        ),
                      ),
                    ),
            ),
          ),
        ]),
      );

  Future<void> cap(WidgetTester t) async {
    if (!recording) return;
    final ro = shotKey.currentContext?.findRenderObject();
    if (ro is! RenderRepaintBoundary) return;
    final n = frames++;
    await t.runAsync(() async {
      final img = await ro.toImage(pixelRatio: 1.5);
      final bd = await img.toByteData(format: ui.ImageByteFormat.png);
      img.dispose();
      if (bd != null) File('${videoDir.path}/f_${n.toString().padLeft(4, '0')}.png').writeAsBytesSync(bd.buffer.asUint8List());
    });
  }

  /// کات تێدەپەڕێت (15 فرەیم لە چرکەیەکدا بۆ ڤیدیۆ)
  Future<void> run(WidgetTester t, int ms) async {
    const step = 66;
    var left = ms;
    while (left > 0) {
      final d = left < step ? left : step;
      await t.pump(Duration(milliseconds: d));
      left -= d;
      await cap(t);
    }
  }

  Future<void> fonts(WidgetTester t) async {
    await t.runAsync(() => GoogleFonts.pendingFonts());
    await t.pump();
  }

  Future<void> precache(WidgetTester t) async {
    final ctx = navKey.currentContext ?? t.element(find.byType(MaterialApp).first);
    await t.runAsync(() async {
      for (final p in assets) {
        await precacheImage(AssetImage(p), ctx);
      }
    });
    await t.pump();
  }

  Future<void> gold(WidgetTester t, String name) async {
    await fonts(t);
    if (autoUpdateGoldenFiles) await expectLater(find.byKey(shotKey), matchesGoldenFile('goldens/food/$name.png'));
  }

  void noErr(WidgetTester t, String at) {
    final e = t.takeException();
    if (e != null) {
      // ignore: avoid_print
      print('ERR $at ${e is FlutterError ? e.toStringDeep() : e}');
    }
    expect(e, isNull, reason: at);
  }

  /// دەستلێدان بە پەنجەی دیار
  Future<void> tap(WidgetTester t, Finder f, {int after = 350}) async {
    expect(f, findsWidgets);
    await t.ensureVisible(f.first);
    await t.pump();
    final c = t.getCenter(f.first);
    final from = finger.value;
    if (recording) {
      if (from == null) {
        finger.value = c;
        await run(t, 200);
      } else {
        for (var i = 1; i <= 8; i++) {
          final k = Curves.easeInOut.transform(i / 8);
          finger.value = Offset.lerp(from, c, k);
          await t.pump(const Duration(milliseconds: 66));
          await cap(t);
        }
      }
      press.value++;
      await run(t, 140);
      press.value++;
    }
    await t.tap(f.first, warnIfMissed: false);
    await run(t, after);
  }

  Future<void> phone(WidgetTester t, {double h = 844}) async {
    t.view.physicalSize = Size(390 * 2, h * 2);
    t.view.devicePixelRatio = 2;
    t.view.padding = const FakeViewPadding(top: 88, bottom: 60);
    t.view.viewPadding = const FakeViewPadding(top: 88, bottom: 60);
    addTearDown(t.view.reset);
  }

  Future<void> end(WidgetTester t) async {
    finger.value = null;
    await t.pumpWidget(const SizedBox());
    await t.pump(const Duration(seconds: 3));
  }

  // ─────────────────────────── داتا ───────────────────────────

  test('10 sample foods: image, units, sane nutrition', () {
    expect(kDishes.length, 10);
    final ids = <String>{};
    for (final d in [...kDishes, ...kAltDishes]) {
      expect(ids.add(d.id), true, reason: 'duplicate ${d.id}');
      expect(File(d.img!).existsSync(), true, reason: d.img);
      expect(d.units.isNotEmpty, true);
      expect(d.units.containsKey('g') || d.units.containsKey('ml'), true, reason: d.id);
      // کالۆری ≈ 4p + 4c + 9f (±25%)
      final est = d.p * 4 + d.c * 4 + d.f * 9;
      expect((est - d.k).abs() <= d.k * 0.25 + 8, true, reason: '${d.id} $est vs ${d.k}');
      expect(d.sug <= d.c + 0.01, true, reason: d.id);
    }
  });

  test('amounts are words, never fractions', () {
    expect(qtyWord(1, 'qap'), 'یەک قاپ');
    expect(qtyWord(0.5, 'qap'), 'نیو قاپ');
    expect(qtyWord(1.5, 'qap'), 'قاپ و نیو');
    expect(qtyWord(2.5, 'kasa'), 'دوو کاسە و نیو');
    expect(qtyWord(3, 'shish'), 'سێ شیش');
    expect(qtyWord(0.25, 'kup'), 'چارەکێک کوپ');
    expect(qtyWord(12, 'dana'), contains('12'));
    expect(qtyWord(150, 'g'), contains('150'));
    for (final u in kUnits.values) {
      for (final s in u.steps) {
        expect(qtyWord(s, u.id).contains('/'), false);
      }
    }
  });

  test('+ / − walk the unit steps and change kcal', () {
    final it = FItem(dish: dishById('kebab')!, unit: 'shish', q: 2);
    final k2 = it.nut.k;
    expect(it.step(1), true);
    expect(it.q, 3);
    expect(it.word, 'سێ شیش');
    expect(it.nut.k, closeTo(k2 * 1.5, 0.01));
    final r = FItem(dish: dishById('rice')!, unit: 'qap', q: 1);
    expect(r.step(-1), true);
    expect(r.word, 'نیو قاپ');
    expect(r.step(-1), false);
    expect(r.q, 0.5);
    // بڕی گەورەتر لە لیستەکە (لە AI ـەوە)
    final big = FItem(dish: dishById('rice')!, unit: 'qap', q: 6);
    expect(big.step(1), false);
    expect(big.step(-1), true);
    expect(big.q, 4);
  });

  test('typed text is understood offline', () {
    final l = FoodAiEngine.parseLocal('دوو شیش کەباب و قاپێک برنج و چا، 150 گرام حومس', const []);
    expect(l.map((e) => e.dish.id).toList(), ['kebab', 'rice', 'tea', 'hummus']);
    expect(l[0].q, 2);
    expect(l[0].unit, 'shish');
    expect(l[1].unit, 'qap');
    expect(l[1].q, 1);
    expect(l[3].unit, 'g');
    expect(l[3].q, 150);
    expect(FoodAiEngine.parseLocal('pizza', const []), isEmpty);
  });

  test('demo AI: samples exact, doogh unsure with alternatives, real photo must be confirmed', () async {
    final r = await FoodAiEngine.analyse([for (final d in kDishes) FShot(sample: d.id)]);
    expect(r.items.length, 10);
    expect(r.demoReal, false);
    final dg = r.items.firstWhere((x) => x.shot == 4);
    expect(dg.sure, false);
    expect(dg.guess, 'شیر');
    expect(dg.alts.first.id, 'doogh');
    expect(r.items.where((x) => !x.sure).length, 1);
    final real = await FoodAiEngine.analyse([FShot(bytes: _fakePhoto())]);
    expect(real.demoReal, true);
    expect(real.items.single.sure, false);
  });

  test('server JSON is parsed (new food with its own PNG)', () {
    final l = FoodAiEngine.parseItems({
      'items': [
        {'id': 'rice', 'name': 'برنج', 'unit': 'qap', 'qty': 1.5, 'conf': 0.93, 'shot': 0},
        {
          'id': null,
          'name': 'مەقلووبە',
          'ing': 'برنج، باینجان، مریشک',
          'unit': 'qap',
          'qty': 1,
          'units': {'qap': 300, 'g': 1},
          'per100': [180, 8, 22, 7, 2, 2, 0.8, 30],
          'conf': 0.62,
          'shot': 1,
          'png': 'https://cdn.example.com/maqluba.png',
          'alts': [
            {'name': 'برنجی سوور', 'unit': 'qap', 'units': {'qap': 250}, 'per100': [160, 3, 30, 4, 1, 1, 0.6, 0]}
          ],
        },
      ]
    });
    expect(l.length, 2);
    expect(l[0].dish.img, isNotNull);
    expect(l[1].dish.name, 'مەقلووبە');
    expect(l[1].dish.net, 'https://cdn.example.com/maqluba.png');
    expect(l[1].sure, false);
    expect(l[1].alts.length, 2);
    expect(l[1].nut.k, closeTo(540, 0.1));
  });

  test('saving a meal feeds today, the home card and the general report; delete removes everywhere', () async {
    await reset();
    final items = [
      FItem(dish: dishById('rice')!, unit: 'qap', q: 1),
      FItem(dish: dishById('kebab')!, unit: 'shish', q: 2),
      FItem(dish: dishById('doogh')!, unit: 'kup', q: 1),
    ];
    final want = items.fold<double>(0, (a, x) => a + x.nut.k);
    await FoodAiStore.I.saveMeal(items, 'l');
    expect(FoodAiStore.I.today.length, 3);
    expect(Store.I.food.length, 3);
    expect(Store.I.totals().kcal, closeTo(want, 2));
    final sp = await SharedPreferences.getInstance();
    final fd = jsonDecode(sp.getString('vexfd_v1')!) as Map;
    final day = (fd['days'] as Map)[FoodAiStore.todayKey] as Map;
    final l = (day['m'] as Map)['l'] as List;
    expect(l.length, 3);
    expect(l.first['fib'], isNotNull);
    expect(l.first['salt'], isNotNull);
    // دووبارە بارکردنەوە (وەک کردنەوەی ئەپ)
    FoodAiStore.I.reset();
    await FoodAiStore.I.init();
    expect(FoodAiStore.I.today.length, 3);
    expect(FoodAiStore.I.today.first.dish.img, isNotNull);
    await FoodAiStore.I.remove(FoodAiStore.I.today[1]);
    expect(FoodAiStore.I.today.length, 2);
    expect(Store.I.food.length, 2);
    final fd2 = jsonDecode(sp.getString('vexfd_v1')!) as Map;
    expect((((fd2['days'] as Map)[FoodAiStore.todayKey] as Map)['m'] as Map)['l'].length, 2);
    // خواردنەکانی تۆ
    final d = await FoodAiStore.I.saveMine(FItem(dish: dishById('dolma')!, unit: 'qap', q: 1.5));
    expect(d.name, 'دۆڵمەی ماڵەوە');
    expect(d.q0, 1.5);
    FoodAiStore.I.reset();
    await FoodAiStore.I.init();
    expect(FoodAiStore.I.mine.single.name, 'دۆڵمەی ماڵەوە');
    expect(FoodAiStore.I.mine.single.img, dishById('dolma')!.img);
  });

  // ─────────────────────────── هەموو ڕێڕەوەکە (وێنە) ───────────────────────────

  Future<void> openTab(WidgetTester t, {bool light = false}) async {
    await t.runAsync(() => reset());
    await t.runAsync(() => VexTheme.I.setMode(light ? VexMode.light : VexMode.dark));
    await t.pumpWidget(harness(MaterialApp(
      navigatorKey: navKey,
      debugShowCheckedModeBanner: false,
      builder: (context, child) => Directionality(textDirection: TextDirection.rtl, child: child!),
      home: Scaffold(backgroundColor: V.bg, body: const FoodAiTab()),
    )));
    await precache(t);
    await run(t, 1200);
  }

  testWidgets('full flow: 5 photos → analysis → steps → fix → detail → save → today', (t) async {
    await phone(t);
    await openTab(t);
    noErr(t, 'tab');
    await gold(t, '01_tab_empty');

    await tap(t, find.byKey(const ValueKey<String>('fa-open-cam')), after: 700);
    await precache(t);
    await gold(t, '02_camera');

    // نموونەی یەکەم: ناسینەوە لە کامێرادا
    await tap(t, find.byKey(const ValueKey<String>('fa-sample-rice')), after: 700);
    await gold(t, '03_detect');
    await run(t, 900);
    for (final id in ['kebab', 'salad', 'dolma', 'doogh']) {
      await tap(t, find.byKey(ValueKey<String>('fa-sample-$id')), after: 1750);
    }
    noErr(t, 'camera');
    await gold(t, '04_tray5');
    // شەشەم ڕێگە نادرێت
    await tap(t, find.byKey(const ValueKey<String>('fa-sample-tea')), after: 400);
    await run(t, 1500);

    await tap(t, find.byKey(const ValueKey<String>('fa-go')), after: 1500);
    await gold(t, '05_analysis');
    await run(t, 2600);
    await gold(t, '06_analysis_found');
    await run(t, 1900);
    noErr(t, 'analysis');
    expect(find.text('نانی نیوەڕۆ').evaluate().isNotEmpty || find.text('نانی بەیانی').evaluate().isNotEmpty || find.byKey(const ValueKey<String>('fa-meal')).evaluate().isNotEmpty, true);
    await gold(t, '07_review');
    await run(t, 4500);
    await gold(t, '08_review_png');

    // + / −
    await tap(t, find.byKey(const ValueKey<String>('fa-plus-1')), after: 700);
    await tap(t, find.byKey(const ValueKey<String>('fa-minus-0')), after: 900);
    expect(find.text('سێ شیش'), findsOneWidget);
    expect(find.text('نیو قاپ'), findsOneWidget);
    await gold(t, '09_steps');

    // ڕاستکردنەوە: «شیر ؟» ← دۆ
    expect(find.text('دڵنیاکردنەوە (1)'), findsOneWidget);
    await tap(t, find.byKey(const ValueKey<String>('fa-warn-4')), after: 800);
    await gold(t, '10_fix');
    await tap(t, find.byKey(const ValueKey<String>('fa-alt-0')), after: 1400);
    expect(find.text('دۆ'), findsOneWidget);
    expect(find.text('تۆمارکردن'), findsOneWidget);
    noErr(t, 'fix');

    // وردەکاری: دۆڵمە ← یەک و نیو
    await tap(t, find.byKey(const ValueKey<String>('fa-name-3')), after: 900);
    await gold(t, '11_detail');
    await tap(t, find.byKey(const ValueKey<String>('fa-pie-3')), after: 700);
    expect(find.text('قاپ و نیو'), findsWidgets);
    await tap(t, find.byKey(const ValueKey<String>('fa-mine')), after: 700);
    await gold(t, '12_detail_15');
    // یەکە: گرام
    await tap(t, find.byKey(const ValueKey<String>('fa-unit-g')), after: 600);
    await gold(t, '13_detail_grams');
    await tap(t, find.byKey(const ValueKey<String>('fa-unit-qap')), after: 600);
    await tap(t, find.byKey(const ValueKey<String>('fa-ok')), after: 1000);
    noErr(t, 'detail');
    await gold(t, '14_review_final');

    final before = Store.I.totals().kcal;
    expect(before, 0);
    await tap(t, find.byKey(const ValueKey<String>('fa-save')), after: 1200);
    await run(t, 1800);
    await gold(t, '15_done');
    await run(t, 1500);
    noErr(t, 'done');
    expect(FoodAiStore.I.today.length, 5);
    expect(Store.I.food.length, 5);
    expect(FoodAiStore.I.mine.single.name, 'دۆڵمەی ماڵەوە');
    final dolma = FoodAiStore.I.today.firstWhere((x) => x.dish.id == 'dolma');
    expect(dolma.q, 1.5);
    expect(FoodAiStore.I.today.firstWhere((x) => x.dish.id == 'doogh').dish.name, 'دۆ');

    await tap(t, find.byKey(const ValueKey<String>('fa-finish')), after: 900);
    await gold(t, '16_tab_today');

    // نووسین
    await tap(t, find.byKey(const ValueKey<String>('fa-open-text')), after: 700);
    await t.enterText(find.byKey(const ValueKey<String>('fa-text-field')), 'دوو کوپ چا و نانی تەنوور، 150 گرام حومس');
    await run(t, 600);
    await gold(t, '17_text');
    await tap(t, find.byKey(const ValueKey<String>('fa-text-go')), after: 1200);
    await gold(t, '18_text_review');
    await tap(t, find.byKey(const ValueKey<String>('fa-save')), after: 3000);
    await tap(t, find.byKey(const ValueKey<String>('fa-finish')), after: 900);
    expect(FoodAiStore.I.today.length, 8);
    noErr(t, 'text');

    // خواردنەکانی تۆ ← زیادکردن بە یەک دەستلێدان
    await t.drag(find.byType(ListView).first, const Offset(0, -300));
    await run(t, 600);
    await tap(t, find.byKey(const ValueKey<String>('fa-mine-0')), after: 800);
    await gold(t, '19_mine_menu');
    await tap(t, find.text('زیادکردن بۆ ئەمڕۆ'), after: 1000);
    await tap(t, find.byKey(const ValueKey<String>('fa-save')), after: 3000);
    await tap(t, find.byKey(const ValueKey<String>('fa-finish')), after: 900);
    expect(FoodAiStore.I.today.length, 9);

    // سڕینەوە
    await tap(t, find.byKey(const ValueKey<String>('fa-log-del-0')), after: 700);
    await tap(t, find.byKey(const ValueKey<String>('fa-log-del-ok')), after: 900);
    expect(FoodAiStore.I.today.length, 8);
    expect(Store.I.food.length, 8);
    noErr(t, 'delete');
    await end(t);
  });

  testWidgets('all 10 sample foods at once (2 rounds of 5)', (t) async {
    await phone(t);
    await openTab(t);
    await tap(t, find.byKey(const ValueKey<String>('fa-open-cam')), after: 700);
    for (final id in ['tea', 'bread', 'hummus', 'kubba', 'kunafa']) {
      await tap(t, find.byKey(ValueKey<String>('fa-sample-$id')), after: 1750);
    }
    await tap(t, find.byKey(const ValueKey<String>('fa-go')), after: 4500);
    await run(t, 4500);
    noErr(t, 'b');
    await gold(t, '20_review_b');
    await tap(t, find.byKey(const ValueKey<String>('fa-save')), after: 3500);
    await tap(t, find.byKey(const ValueKey<String>('fa-finish')), after: 900);
    expect(FoodAiStore.I.today.length, 5);
    expect(FoodAiStore.I.today.map((e) => e.dish.id).toSet(), {'tea', 'bread', 'hummus', 'kubba', 'kunafa'});
    await end(t);
  });

  testWidgets('light theme: review and detail', (t) async {
    await phone(t);
    await openTab(t, light: true);
    await gold(t, '21_light_tab');
    await tap(t, find.byKey(const ValueKey<String>('fa-open-cam')), after: 700);
    for (final id in ['rice', 'kebab', 'salad']) {
      await tap(t, find.byKey(ValueKey<String>('fa-sample-$id')), after: 1750);
    }
    await tap(t, find.byKey(const ValueKey<String>('fa-go')), after: 4200);
    await run(t, 3500);
    await gold(t, '22_light_review');
    await tap(t, find.byKey(const ValueKey<String>('fa-name-1')), after: 900);
    await gold(t, '23_light_detail');
    noErr(t, 'light');
    await t.runAsync(() => VexTheme.I.setMode(VexMode.dark));
    await end(t);
  });

  // ─────────────────────────── ڤیدیۆی هەموو ئەپەکە ───────────────────────────

  testWidgets('whole app video: home → VEX AI → 5 photos → save → home card', (t) async {
    await phone(t);
    await t.runAsync(() async {
      await reset();
      await VexTheme.I.setMode(VexMode.dark);
      await BandState.I.load();
      await PlusState.I.load();
    });
    if (videoDir.existsSync()) videoDir.deleteSync(recursive: true);
    videoDir.createSync(recursive: true);
    await t.pumpWidget(harness(const MyApp()));
    await precache(t);
    await run(t, 3200); // سپلاش
    noErr(t, 'splash');
    recording = true;
    await run(t, 1600);
    await gold(t, '30_app_home');

    final nav = find.descendant(of: find.byType(VNav), matching: find.text('VEX AI'));
    await tap(t, nav, after: 1400);
    noErr(t, 'tab');
    await gold(t, '31_app_vexai');
    await tap(t, find.byKey(const ValueKey<String>('fa-open-cam')), after: 900);
    await tap(t, find.byKey(const ValueKey<String>('fa-sample-rice')), after: 1900);
    for (final id in ['kebab', 'salad', 'dolma', 'doogh']) {
      await tap(t, find.byKey(ValueKey<String>('fa-sample-$id')), after: 1750);
    }
    await tap(t, find.byKey(const ValueKey<String>('fa-go')), after: 4300);
    await run(t, 3200);
    await tap(t, find.byKey(const ValueKey<String>('fa-plus-1')), after: 700);
    await tap(t, find.byKey(const ValueKey<String>('fa-minus-0')), after: 900);
    await tap(t, find.byKey(const ValueKey<String>('fa-warn-4')), after: 1000);
    await tap(t, find.byKey(const ValueKey<String>('fa-alt-0')), after: 1500);
    await tap(t, find.byKey(const ValueKey<String>('fa-name-3')), after: 1100);
    await tap(t, find.byKey(const ValueKey<String>('fa-pie-3')), after: 900);
    await tap(t, find.byKey(const ValueKey<String>('fa-mine')), after: 800);
    await tap(t, find.byKey(const ValueKey<String>('fa-ok')), after: 1200);
    await tap(t, find.byKey(const ValueKey<String>('fa-save')), after: 4300);
    await tap(t, find.byKey(const ValueKey<String>('fa-finish')), after: 1600);
    await gold(t, '32_app_today');
    noErr(t, 'flow');
    // گەڕانەوە بۆ سەرەکی: کارتی خواردن کالۆرییەکە پیشان دەدات
    final home = find.descendant(of: find.byType(VNav), matching: find.text('سەرەکی'));
    await tap(t, home, after: 1500);
    await t.drag(find.byType(Scrollable).first, const Offset(0, -900));
    await run(t, 1600);
    await gold(t, '33_app_home_after');
    finger.value = null;
    await run(t, 600);
    recording = false;
    noErr(t, 'home');
    expect(Store.I.food.length, 5);
    // ignore: avoid_print
    print('VIDEO_FRAMES=$frames');
    await end(t);
  });
}

/// وێنەی ساختە بۆ تاقیکردنەوەی وێنەی ڕاستەقینە
Uint8List _fakePhoto() => Uint8List.fromList(List<int>.generate(4096, (i) => (i * 37) % 251));
