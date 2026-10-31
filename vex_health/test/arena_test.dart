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

  Future<void> done(WidgetTester t) async {
    await t.pump(const Duration(seconds: 4));
    await t.pumpWidget(const SizedBox());
    await t.pump(const Duration(seconds: 1));
  }

  /// پەڕەیەکی تۆمارکراو (بێ دەروازە) — بۆ تاقیکردنەوەی زمان و دۆخەکان
  Future<ArenaStore> openRegistered(WidgetTester t, {required String lang, required String mode, bool band = true, double h = 4400}) async {
    SharedPreferences.setMockInitialValues({});
    await t.binding.setSurfaceSize(Size(400, h));
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
      await t.pumpWidget(
          MaterialApp(debugShowCheckedModeBanner: false, navigatorKey: navKey, home: VexArenaPage(host: DemoArenaHost(band: mode == 'dark'))));
      await settle(t, 500);
      noErr(t, 'gate open');
      expect(find.text(tr('g_title')), findsOneWidget);
      // هیچ تابێک پێش تۆمارکردن نییە
      expect(find.text(tr('tab_rank')), findsNothing);
      await gold(find.byType(VexArenaPage), 'goldens/gate1_$mode.png');

      // هەنگاوی 1: هەڵەکان
      await t.tap(find.text(tr('cont')));
      await settle(t);
      expect(find.text(tr('e_name')), findsOneWidget);
      await t.enterText(find.byType(TextField).at(0), 'ئاراس کەریم');
      await t.enterText(find.byType(TextField).at(1), '123');
      await t.tap(find.text(tr('cont')));
      await settle(t);
      expect(find.text(tr('e_phone')), findsOneWidget);
      await t.enterText(find.byType(TextField).at(1), '7501234567');
      await settle(t);
      await t.tap(find.text(tr('cont')));
      await settle(t);
      noErr(t, 'step 2');

      // هەنگاوی 2: شار (یەکەم شار هەڵبژێردراوە)
      await gold(find.byType(VexArenaPage), 'goldens/gate2_$mode.png');
      await t.tap(find.text(tr('cont')));
      await settle(t);
      noErr(t, 'step 3');

      // هەنگاوی 3: کارەکتەر
      await t.tap(find.text(tr('cont')));
      await settle(t);
      expect(find.text(tr('e_char')), findsOneWidget);
      await t.tap(find.byType(CharAvatar).first);
      await settle(t);
      await gold(find.byType(VexArenaPage), 'goldens/gate3_$mode.png');
      await t.tap(find.text(tr('cont')));
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
      await t.pump(const Duration(seconds: 2));
      await gold(find.byType(MaterialApp), 'goldens/reveal_$mode.png');
      await t.tap(find.text(tr('rv_go')));
      await settle(t, 600);
      noErr(t, 'after reveal');
      expect(find.text(tr('tab_rank')), findsOneWidget);
      expect(arenaDebugCtl!.regd, isTrue);
      await done(t);
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
        await gold(find.byType(VexArenaPage), 'goldens/${lang}_${mode}_today.png');
        await t.tap(find.text(tr('tab_rank')));
        await settle(t);
        noErr(t, 'rank $lang');
        await gold(find.byType(VexArenaPage), 'goldens/${lang}_${mode}_rank.png');
        await t.tap(find.text(tr('tab_card')));
        await settle(t);
        noErr(t, 'card $lang');
        await gold(find.byType(VexArenaPage), 'goldens/${lang}_${mode}_card.png');
        await done(t);
      });
    }
  }

  // پەڕە بە قەبارەی مۆبایلی ڕاستەقینە (سکڕۆڵ و تابی چەسپاو)
  testWidgets('phone size scroll', (t) async {
    await openRegistered(t, lang: 'ckb', mode: 'dark', h: 860);
    noErr(t, 'open');
    await gold(find.byType(VexArenaPage), 'goldens/ckb_dark_phone_top.png');
    await t.drag(find.byType(Scrollable).first, const Offset(0, -900));
    await settle(t);
    noErr(t, 'scrolled');
    await gold(find.byType(VexArenaPage), 'goldens/ckb_dark_phone_scrolled.png');
    await done(t);
  });

  // ---------------------------------------------------------------------------
  // 3. لیگی مۆبایل (بێ Band) و بەرزبوونەوە بۆ لیگی Band
  // ---------------------------------------------------------------------------
  testWidgets('phone league + auto upgrade', (t) async {
    final st = await openRegistered(t, lang: 'ckb', mode: 'dark', band: false);
    noErr(t, 'phone open');
    expect(st.acc!.dv, 'phone');
    expect(arenaDebugCtl!.div, Div.phone);
    await gold(find.byType(VexArenaPage), 'goldens/phone_today.png');
    await t.tap(find.text(tr('tab_rank')));
    await settle(t);
    noErr(t, 'phone rank');
    await gold(find.byType(VexArenaPage), 'goldens/phone_rank.png');
    await done(t);

    // Band کڕی و پەیوەستی کرد ← ئۆتۆماتیک لیگی Band
    final c = ArenaCtl(DemoArenaHost(band: true), st);
    c.refresh();
    expect(st.acc!.dv, 'band');
    expect(c.div, Div.band);
  });

  // ---------------------------------------------------------------------------
  // 4. هەموو شیتەکان
  // ---------------------------------------------------------------------------
  for (final cfg in [
    ['ckb', 'dark'],
    ['ckb', 'light'],
    ['en', 'light'],
    ['ar', 'dark'],
    ['kmr', 'dark'],
    ['fa', 'light'],
    ['tr', 'dark'],
  ]) {
    testWidgets('sheets ${cfg[0]} ${cfg[1]}', (t) async {
      final st = await openRegistered(t, lang: cfg[0], mode: cfg[1], h: 1400);
      final c = arenaDebugCtl!;
      final tag = '${cfg[0]}_${cfg[1]}';
      final g = cfg[0] == 'ckb' || cfg[0] == 'en';
      BuildContext ctx() => navKey.currentState!.overlay!.context;
      Future<void> sheet(String n, void Function(BuildContext) open, {bool close = true}) async {
        open(ctx());
        await settle(t);
        noErr(t, n);
        if (g) await gold(find.byType(MaterialApp), 'goldens/sheet_${tag}_$n.png');
        if (close) await closeSheet(t);
      }

      await sheet('coins', (x) => coinSheet(x, c));
      await sheet('rules', (x) => rulesSheet(x, c));
      await sheet('prize_band', (x) => prizeSheet(x, c, Div.band));
      await sheet('prize_phone', (x) => prizeSheet(x, c, Div.phone));
      await sheet('fair', (x) => fairSheet(x, c));
      await sheet('freeze', (x) => freezeSheet(x, c));
      await sheet('excuse', (x) => excuseSheet(x, c));
      await sheet('yesterday', (x) => yesterdaySheet(x, c));
      await sheet('cat_walk', (x) => catSheet(x, c, catById('walk')));
      await sheet('cat_sleep', (x) => catSheet(x, c, catById('sleep')));
      await sheet('edit', (x) => editSheet(x, c));
      await sheet('share', (x) => shareSheet(x, c));
      await sheet('skin_neon', (x) => skinSheet(x, c, skinById('neon')));
      await sheet('skin_gold', (x) => skinSheet(x, c, skinById('gold')));
      await sheet('skin_auto', (x) => skinSheet(x, c, skinById('auto')));
      await sheet('chars', (x) => charSheet(x, c));
      final pl = c.players();
      if (pl.isNotEmpty) await sheet('player', (x) => playerSheet(x, c, pl.first));

      // پێشبینی: هەڵبژاردنی بەشێک
      if (c.live && st.guess[c.tk] == null) {
        await sheet('guess', (x) => guessSheet(x, c), close: false);
        await t.tap(find.text(catById('sleep').name).last);
        await settle(t);
        noErr(t, 'guessed');
        expect(st.guess[c.tk], 'sleep');
      }

      // کارەکتەر: هەڵبژاردنی کارەکتەرێکی تر
      await sheet('chars2', (x) => charSheet(x, c), close: false);
      await t.tap(find.byType(CharAvatar).at(3));
      await settle(t);
      noErr(t, 'char pick');
      await closeSheet(t);

      // پلەکان: هەموو بەشەکان
      await t.tap(find.text(tr('tab_rank')));
      await settle(t);
      for (final s in ['all', 'age', 'guess', 'week']) {
        final f = find.text(tr('sg_$s'));
        if (f.evaluate().isEmpty) continue;
        await t.tap(f.first);
        await settle(t);
        noErr(t, 'seg $s');
      }

      // چوونە دەرەوە
      await sheet('logout', (x) => logoutSheet(x, c), close: false);
      await t.tap(find.text(tr('logout_yes')));
      await settle(t, 500);
      noErr(t, 'logged out');
      expect(find.text(tr('g_title')), findsOneWidget);
      await done(t);
    });
  }

  // ---------------------------------------------------------------------------
  // 5. هەموو وەرگێڕانەکان پڕن
  // ---------------------------------------------------------------------------
  test('translations complete', () {
    final ph = RegExp(r'\{\d\}');
    for (final e in kArenaT.entries) {
      expect(e.value.length, 6, reason: e.key);
      final p0 = ph.allMatches(e.value[2]).map((m) => m[0]).toSet();
      for (final v in e.value) {
        expect(v.trim().isNotEmpty, isTrue, reason: e.key);
        expect(ph.allMatches(v).map((m) => m[0]).toSet(), p0, reason: e.key);
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
