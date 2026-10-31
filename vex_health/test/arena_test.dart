// تاقیکردنەوەی VEX Arena: دەروازەی تۆمارکردن، هەر 3 تاب، هەموو شیتەکان،
// هەر 6 زمان، دۆخی ڕووناک / تاریک / خۆکار، و هەردوو لیگ (Band / مۆبایل).
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vex_health/arena/vex_arena.dart';
import 'package:vex_health/core/theme.dart';
import 'package:vex_health/onboarding/reg_lang_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  setUpAll(() async {
    final ar = FontLoader('NotoAr');
    for (final f in ['Regular', 'SemiBold', 'Bold']) {
      final m = File('tfonts/merged/NotoAr-$f.ttf');
      if (m.existsSync()) {
        final b = m.readAsBytesSync();
        ar.addFont(Future.value(ByteData.view(b.buffer)));
      } else {
        ar.addFont(rootBundle.load('assets/fonts/NotoSansArabic-$f.ttf'));
      }
    }
    await ar.load();
    final root = Platform.environment['FLUTTER_ROOT'] ?? '';
    final mi = File('$root/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf');
    if (mi.existsSync()) {
      final bytes = mi.readAsBytesSync();
      await (FontLoader('MaterialIcons')..addFont(Future.value(ByteData.view(bytes.buffer)))).load();
    }
  });

  Future<void> settle(WidgetTester t, [int ms = 300]) async {
    await t.runAsync(() => Future<void>.delayed(Duration(milliseconds: ms)));
    for (var i = 0; i < 14; i++) {
      await t.pump(const Duration(milliseconds: 100));
    }
  }

  // وێنەکان تەنها لەگەڵ --update-goldens دروست دەکرێن (بۆ پێداچوونەوەی دیزاین)
  Future<void> gold(Finder f, String name) async {
    if (autoUpdateGoldenFiles) await expectLater(f, matchesGoldenFile(name));
  }

  void noErr(WidgetTester t, String at) {
    final e = t.takeException();
    if (e != null) {
      // ignore: avoid_print
      print('ERR $at ${e is FlutterError ? e.toStringDeep() : e}');
    }
    expect(e, isNull, reason: at);
  }

  Future<void> theme(WidgetTester t, String m) async {
    if (m == 'auto') {
      t.binding.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
      await t.runAsync(() => VexTheme.I.setMode(VexMode.auto));
    } else {
      await t.runAsync(() => VexTheme.I.setMode(m == 'light' ? VexMode.light : VexMode.dark));
    }
  }

  Future<void> closeSheet(WidgetTester t) async {
    final nav = navKey.currentState!;
    if (nav.canPop()) nav.pop();
    await settle(t);
  }

  /// پەڕەیەکی تۆمارکراو (بێ دەروازە) — بۆ تاقیکردنەوەی زمان و دۆخەکان
  Future<ArenaStore> openRegistered(WidgetTester t, {required String lang, required String mode, bool band = true}) async {
    SharedPreferences.setMockInitialValues({});
    await t.binding.setSurfaceSize(const Size(400, 4400));
    LangState.I.code = lang;
    await theme(t, mode);
    final host = DemoArenaHost(band: band);
    final st = ArenaStore();
    await t.runAsync(() => st.load());
    ArenaCtl(host, st).register(name: 'ئاراس کەریم', phone: '07501234567', city: 'هەولێر', age: 'a', ch: '07');
    await t.runAsync(() => st.save());
    await t.pumpWidget(MaterialApp(debugShowCheckedModeBanner: false, navigatorKey: navKey, home: VexArenaPage(host: host, store: st)));
    await settle(t, 500);
    return st;
  }

  // ---------------------------------------------------------------------------
  // 1. دەروازەی تۆمارکردن (ڕێگای تەواو)
  // ---------------------------------------------------------------------------
  for (final mode in ['dark', 'light']) {
    testWidgets('gate flow $mode', (t) async {
      SharedPreferences.setMockInitialValues({});
      await t.binding.setSurfaceSize(const Size(400, 860));
      LangState.I.code = 'ckb';
      await theme(t, mode);
      await t.pumpWidget(MaterialApp(debugShowCheckedModeBanner: false, navigatorKey: navKey, home: VexArenaPage(host: DemoArenaHost(band: mode == 'dark'))));
      await settle(t, 500);
      noErr(t, 'gate open');
      expect(find.text(tr('g_title')), findsOneWidget);
      // هیچ تابێک پێش تۆمارکردن نییە
      expect(find.text(tr('tab_rank')), findsNothing);
      await gold(find.byType(VexArenaPage), 'goldens/gate1_$mode.png');

      // هەنگاوی 1: هەڵەکان
      await t.tap(find.text(tr('next')));
      await settle(t);
      expect(find.text(tr('e_name')), findsOneWidget);
      await t.enterText(find.byType(TextField).at(0), 'ئاراس کەریم');
      await t.enterText(find.byType(TextField).at(1), '123');
      await t.tap(find.text(tr('next')));
      await settle(t);
      expect(find.text(tr('e_phone')), findsOneWidget);
      await t.enterText(find.byType(TextField).at(1), '7501234567');
      await settle(t);
      expect(find.text('750 123 4567'), findsWidgets);
      await t.tap(find.text(tr('next')));
      await settle(t);
      noErr(t, 'step 2');

      // هەنگاوی 2: شار
      await t.tap(find.text(tr('next')));
      await settle(t);
      expect(find.text(tr('e_city')), findsOneWidget);
      await t.tap(find.text('هەولێر'));
      await settle(t);
      await gold(find.byType(VexArenaPage), 'goldens/gate2_$mode.png');
      await t.tap(find.text(tr('next')));
      await settle(t);
      noErr(t, 'step 3');

      // هەنگاوی 3: کارەکتەر
      await t.tap(find.text(tr('next')));
      await settle(t);
      expect(find.text(tr('e_char')), findsOneWidget);
      await t.tap(find.byType(CharAvatar).first);
      await settle(t);
      await gold(find.byType(VexArenaPage), 'goldens/gate3_$mode.png');
      await t.tap(find.text(tr('next')));
      await settle(t);
      noErr(t, 'step 4');

      // هەنگاوی 4: یاسا
      final go = seasonNow().live ? tr('join') : tr('register');
      await t.tap(find.text(go));
      await settle(t);
      expect(find.text(tr('e_agree')), findsOneWidget);
      await gold(find.byType(VexArenaPage), 'goldens/gate4_$mode.png');
      await t.ensureVisible(find.text(tr('agree')));
      await settle(t);
      await t.tap(find.text(tr('agree')));
      await settle(t);
      await t.tap(find.text(go));
      await settle(t, 600);
      noErr(t, 'registered');

      // پیشاندانی کارت
      expect(find.text(tr('rv_t')), findsOneWidget);
      await gold(find.byType(MaterialApp), 'goldens/reveal_$mode.png');
      await t.tap(find.text(tr('rv_go')));
      await settle(t, 600);
      noErr(t, 'after reveal');
      expect(find.text(tr('tab_rank')), findsOneWidget);
      expect(find.text(tr('ch_t')), findsOneWidget);

      await t.pump(const Duration(seconds: 4));
      await t.pumpWidget(const SizedBox());
      await t.pump(const Duration(seconds: 1));
    });
  }

  // ---------------------------------------------------------------------------
  // 2. هەر 6 زمان × 3 تاب
  // ---------------------------------------------------------------------------
  const langs = ['ckb', 'kmr', 'en', 'ar', 'fa', 'tr'];
  for (final lang in langs) {
    for (final mode in (lang == 'ckb' ? ['dark', 'light', 'auto'] : (lang == 'en' ? ['light', 'dark'] : ['dark']))) {
      testWidgets('tabs $lang $mode', (t) async {
        await openRegistered(t, lang: lang, mode: mode);
        noErr(t, 'open $lang');
        expect(find.text(tr('tab_today')), findsOneWidget);
        expect(find.text(tr('sp_t')), findsWidgets); // شوێنی سپۆنسەر بەتاڵە
        await gold(find.byType(VexArenaPage), 'goldens/${lang}_${mode}_today.png');
        await t.tap(find.text(tr('tab_rank')));
        await settle(t);
        noErr(t, 'rank $lang');
        await gold(find.byType(VexArenaPage), 'goldens/${lang}_${mode}_rank.png');
        await t.tap(find.text(tr('tab_card')));
        await settle(t);
        noErr(t, 'card $lang');
        await gold(find.byType(VexArenaPage), 'goldens/${lang}_${mode}_card.png');
        await t.pump(const Duration(seconds: 4));
        await t.pumpWidget(const SizedBox());
        await t.pump(const Duration(seconds: 1));
      });
    }
  }

  // ---------------------------------------------------------------------------
  // 3. لیگی مۆبایل (بێ Band) و بەرزبوونەوە بۆ لیگی Band
  // ---------------------------------------------------------------------------
  testWidgets('phone league + auto upgrade', (t) async {
    final st = await openRegistered(t, lang: 'ckb', mode: 'dark', band: false);
    noErr(t, 'phone open');
    expect(st.acc!.dv, 'phone');
    expect(find.text(tr('pb_t')), findsOneWidget);
    await gold(find.byType(VexArenaPage), 'goldens/phone_today.png');
    await t.tap(find.text(tr('tab_rank')));
    await settle(t);
    noErr(t, 'phone rank');
    await gold(find.byType(VexArenaPage), 'goldens/phone_rank.png');
    await t.pump(const Duration(seconds: 4));
    await t.pumpWidget(const SizedBox());
    await t.pump(const Duration(seconds: 1));

    // Band کڕی و پەیوەستی کرد ← ئۆتۆماتیک لیگی Band
    final host = DemoArenaHost(band: true);
    final c = ArenaCtl(host, st);
    c.refresh();
    expect(st.acc!.dv, 'band');
    expect(c.div, Div.band);
  });

  // ---------------------------------------------------------------------------
  // 4. هەموو شیتەکان (کوردی تاریک + ئینگلیزی ڕووناک)
  // ---------------------------------------------------------------------------
  for (final cfg in [
    ['ckb', 'dark'],
    ['en', 'light'],
    ['ar', 'dark'],
  ]) {
    testWidgets('sheets ${cfg[0]} ${cfg[1]}', (t) async {
      final st = await openRegistered(t, lang: cfg[0], mode: cfg[1]);
      final g = cfg[0] == 'ckb';
      Future<void> shot(String n) async {
        noErr(t, n);
        if (g) await gold(find.byType(MaterialApp), 'goldens/sheet_$n.png');
      }

      // سکە
      await t.tap(find.text(afmt(st.coins)).first); // دوگمەی سکە لە سەرپەڕە
      await settle(t);
      expect(find.text(tr('coins_t')), findsWidgets);
      await shot('coins');
      await closeSheet(t);

      // یاسا
      await t.tap(find.byIcon(Icons.help_outline_rounded));
      await settle(t);
      expect(find.text(tr('ru1_t')), findsOneWidget);
      await shot('rules');
      await closeSheet(t);

      // ئەگەر وەرز ڕاستەوخۆیە: ئەرک، هێز، پاراستن، بیانوو
      if (seasonNow().live) {
        await t.tap(find.text(tr('pw_go')));
        await settle(t);
        await shot('guess');
        await t.tap(find.text(catById('sleep').name).last);
        await settle(t);
        await t.tap(find.text(tr('pw_confirm', [catById('sleep').name])));
        await settle(t);
        noErr(t, 'guessed');
        expect(st.guess.values.contains('sleep'), isTrue);

        await t.tap(find.text(tr('freeze')).first);
        await settle(t);
        await shot('freeze');
        await closeSheet(t);

        await t.tap(find.text(tr('excuse')).first);
        await settle(t);
        await shot('excuse');
        await closeSheet(t);
      }

      // بەشێک
      await t.tap(find.text(catById('walk').name).last);
      await settle(t);
      await shot('cat_walk');
      await closeSheet(t);
      await t.tap(find.text(catById('water').name).last);
      await settle(t);
      noErr(t, 'cat water');
      await closeSheet(t);

      // خەڵات
      await t.tap(find.text(tr('pz_car')).first);
      await settle(t);
      await shot('prize');
      await closeSheet(t);
      await t.tap(find.text(tr('pz_other', [tr('dv_phone')])));
      await settle(t);
      noErr(t, 'prize toggle');
      expect(find.text(tr('pz_250')), findsWidgets);

      // یاری دادپەروەرانە
      await t.tap(find.text(tr('fair_t')));
      await settle(t);
      await shot('fair');
      await closeSheet(t);

      // پلەکان: یاریزان
      await t.tap(find.text(tr('tab_rank')));
      await settle(t);
      for (final s in ['week', 'age', 'guess', 'all']) {
        if (find.text(tr('sg_$s')).evaluate().isEmpty) break;
        await t.tap(find.text(tr('sg_$s')));
        await settle(t);
        noErr(t, 'seg $s');
      }
      await t.tap(find.text(tr('dv_phone')).first);
      await settle(t);
      noErr(t, 'rank phone div');
      await t.tap(find.text(tr('dv_band')).first);
      await settle(t);
      if (seasonNow().live) {
        await t.tap(find.byType(CharAvatar).first);
        await settle(t);
        await shot('player');
        await closeSheet(t);
      }

      // کارتەکەم
      await t.tap(find.text(tr('tab_card')));
      await settle(t);
      await t.tap(find.text(tr('edit')));
      await settle(t);
      await shot('edit');
      await closeSheet(t);
      await t.tap(find.byType(Image).at(4));
      await settle(t);
      noErr(t, 'char sheet');
      await closeSheet(t);
      await t.ensureVisible(find.text(tr('logout')));
      await t.tap(find.text(tr('logout')));
      await settle(t);
      await shot('logout');
      await t.tap(find.text(tr('logout_yes')));
      await settle(t, 500);
      noErr(t, 'logged out');
      expect(find.text(tr('g_title')), findsOneWidget);

      await t.pump(const Duration(seconds: 4));
      await t.pumpWidget(const SizedBox());
      await t.pump(const Duration(seconds: 1));
    });
  }

  // ---------------------------------------------------------------------------
  // 5. هەموو وەرگێڕانەکان پڕن
  // ---------------------------------------------------------------------------
  test('translations complete', () {
    for (final e in kArenaT.entries) {
      expect(e.value.length, 6, reason: e.key);
      if (e.key.startsWith('ti_need_t0') || e.key.startsWith('ti_need_t1') || e.key.startsWith('ti_need_t2')) continue;
      for (final v in e.value) {
        expect(v.trim().isNotEmpty, isTrue, reason: e.key);
      }
    }
  });

  // ---------------------------------------------------------------------------
  // 6. دژی فێڵ: دەستکاری داتا
  // ---------------------------------------------------------------------------
  testWidgets('tamper resets coins', (t) async {
    SharedPreferences.setMockInitialValues({});
    final st = ArenaStore();
    await t.runAsync(() => st.load());
    ArenaCtl(DemoArenaHost(), st).register(name: 'ئاراس کەریم', phone: '07501234567', city: 'هەولێر', age: 'a', ch: '07');
    await t.runAsync(() => st.save());
    expect(st.coins, greaterThan(0));
    final sp = await t.runAsync(() => SharedPreferences.getInstance());
    final raw = sp!.getString(ArenaStore.key)!;
    await t.runAsync(() => sp.setString(ArenaStore.key, raw.replaceFirst('"coins":${st.coins}', '"coins":99999')));
    final st2 = ArenaStore();
    await t.runAsync(() => st2.load());
    expect(st2.tamper, isTrue);
    expect(st2.coins, 0);
  });
}
