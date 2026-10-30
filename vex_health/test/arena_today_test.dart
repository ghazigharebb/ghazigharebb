// تاقیکردنەوەی بەشی «ئەمڕۆ» ی VEX Arena: ڕووناک و تاریک + هەموو دوگمە و شیتەکان
import 'dart:convert';
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
    // فۆنتی ڕاستەقینەی ئەپ (NotoAr) و ئایکۆنەکانی Material بۆ وێنەی دروست
    // ئەگەر فۆنتی تێکەڵکراو (عەرەبی + لاتینی) هەبێت، بۆ ئەوەی # و + و × ـیش دەربکەون
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

  Future<void> settle(WidgetTester t, [int ms = 400]) async {
    await t.runAsync(() => Future<void>.delayed(Duration(milliseconds: ms)));
    for (var i = 0; i < 16; i++) {
      await t.pump(const Duration(milliseconds: 100));
    }
  }

  void noErr(WidgetTester t, String at) {
    final e = t.takeException();
    if (e != null) {
      // ignore: avoid_print
      print('ERR $at ${e is FlutterError ? e.toStringDeep() : e}');
    }
    expect(e, isNull, reason: at);
  }

  Future<void> open(WidgetTester t, {required bool light}) async {
    SharedPreferences.setMockInitialValues({
      'vex_arena_v3': jsonEncode({
        'v': 3,
        'acc': {'name': 'هگف', 'city': 'هەولێر', 'age': 'a', 'phone': '', 'day': 6},
        'coins': 199,
        'season': 2140,
        'guess': {},
        'rev': [],
      }),
    });
    await t.binding.setSurfaceSize(const Size(400, 2300));
    LangState.I.code = 'ckb';
    await t.runAsync(() => VexTheme.I.setMode(light ? VexMode.light : VexMode.dark));
    await t.pumpWidget(MaterialApp(navigatorKey: navKey, home: VexArenaPage(host: DemoArenaHost())));
    await settle(t, 600);
  }

  for (final light in [false, true]) {
    testWidgets('arena today ${light ? 'light' : 'dark'}', (t) async {
      final old = FlutterError.onError;
      FlutterError.onError = (d) {
        // ignore: avoid_print
        print('FERR ${d.toString().split('\n').take(30).join('\n')}');
        old?.call(d);
      };
      await open(t, light: light);
      noErr(t, 'open');
      expect(find.text('خاڵی ئەمڕۆ'), findsOneWidget);
      expect(find.text('هێزی نهێنیی ئەمڕۆ'), findsOneWidget);
      expect(find.text('چالاکییەکانی ئەمڕۆ'), findsOneWidget);
      expect(find.text('یاریی پاک'), findsOneWidget);
      expect(find.text('خەڵاتەکانی وەرز'), findsOneWidget);
      expect(find.text('کۆی ئەمڕۆ'), findsOneWidget);
      await expectLater(find.byType(VexArenaPage), matchesGoldenFile('goldens/arena_today_${light ? 'light' : 'dark'}.png'));
      if (light) {
        await t.pumpWidget(const SizedBox());
        FlutterError.onError = old;
        return;
      }

      // پێشبینی
      await t.tap(find.text('پێشبینی بکە و +50 خاڵ ببەوە'));
      await settle(t);
      noErr(t, 'guess sheet');
      expect(find.text('کامیان هێزی ئەمڕۆیە؟'), findsOneWidget);
      await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/arena_guess_sheet.png'));
      await t.tap(find.text('خەو').last);
      await settle(t);
      noErr(t, 'guessed');
      expect(find.text('پێشبینییەکەت: خەو'), findsOneWidget);
      await expectLater(find.byType(VexArenaPage), matchesGoldenFile('goldens/arena_today_guessed.png'));

      // ئاشکراکردن (دیمۆ)
      await t.tap(find.text('تاقیکردنەوە: نیوەشەو ئاشکرا بکە (دیمۆ)'));
      await settle(t);
      noErr(t, 'reveal');
      expect(find.textContaining('هێزی ئەمڕۆ'), findsWidgets);
      await expectLater(find.byType(VexArenaPage), matchesGoldenFile('goldens/arena_today_revealed.png'));

      // دوێنێ
      await t.tap(find.textContaining('دوێنێ:'));
      await settle(t);
      noErr(t, 'yesterday');
      expect(find.text('ئاشکرا کرا · هێزی دوێنێ'), findsOneWidget);
      await t.tap(find.text('داخستن').last);
      await settle(t);

      // یاریی پاک
      await t.tap(find.text('یاریی پاک'));
      await settle(t);
      noErr(t, 'fair play');
      expect(find.text('ڕاپۆرتی AI'), findsOneWidget);
      await t.tap(find.text('داخستن').last);
      await settle(t);

      // چالاکییەک
      await t.tap(find.text('پیاسە').first);
      await settle(t);
      noErr(t, 'cat sheet');
      await t.tap(find.text('داخستن').last);
      await settle(t);

      // خەڵاتەکان
      await t.tap(find.text('ئۆتۆمبێل').last);
      await settle(t);
      noErr(t, 'prizes');
      Navigator.of(t.element(find.byType(VexArenaPage))).pop();
      await settle(t);

      // چۆن
      await t.tap(find.text('خاڵەکان چۆن کۆدەکرێنەوە؟'));
      await settle(t);
      noErr(t, 'how');
      Navigator.of(t.element(find.byType(VexArenaPage))).pop();
      await settle(t);

      // بەشەکانی تر هێشتا کار دەکەن
      await t.tap(find.text('پلەکان'));
      await settle(t);
      noErr(t, 'rank tab');
      await t.tap(find.text('کارتەکەم'));
      await settle(t);
      noErr(t, 'card tab');
      await t.tap(find.text('ئەمڕۆ'));
      await settle(t);
      noErr(t, 'back to today');
      await t.pump(const Duration(seconds: 4));
      await t.pumpWidget(const SizedBox());
      await t.pump(const Duration(seconds: 1));
      FlutterError.onError = old;
    });
  }
}
