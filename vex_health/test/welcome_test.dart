// شاشەی بەخێرهاتن: هەر 6 زمان، تاریک و ڕووناک، دوگمەکان و لیستی زمان
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vex_health/welcome/vex_welcome.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  Future<void> settle(WidgetTester t) async {
    for (var i = 0; i < 3; i++) {
      await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 200)));
      await t.runAsync(() => GoogleFonts.pendingFonts());
      await t.pump(const Duration(milliseconds: 400));
    }
    await t.pump(const Duration(seconds: 2));
  }

  Future<void> gold(Finder f, String name) async {
    if (autoUpdateGoldenFiles) await expectLater(f, matchesGoldenFile(name));
  }

  test('31 features, every language complete', () {
    expect(kWelcomeFeatCount, 31);
    for (final l in kWelcomeLangs) {
      expect(l.feats.length, 31, reason: l.code);
      for (final s in [l.title, l.para, l.statFeatures, l.statAi, l.statCare, l.start, l.login, l.terms, ...l.feats]) {
        expect(s.trim().isNotEmpty, isTrue, reason: l.code);
      }
      expect(l.feats.any((f) => f.contains('منداڵ') || f.toLowerCase().contains('baby')), isFalse, reason: l.code);
    }
  });

  for (final dark in [true, false]) {
    for (final l in kWelcomeLangs) {
      if (!dark && l.code != 'ckb' && l.code != 'en') continue;
      testWidgets('welcome ${l.code} ${dark ? 'dark' : 'light'}', (t) async {
        await t.binding.setSurfaceSize(const Size(412, 892));
        var started = 0, login = 0;
        String? picked;
        await t.pumpWidget(MaterialApp(
          debugShowCheckedModeBanner: false,
          home: VexWelcome(
            lang: l.code,
            dark: dark,
            onStart: () => started++,
            onLogin: () => login++,
            onLangChanged: (v) => picked = v,
          ),
        ));
        await settle(t);
        expect(t.takeException(), isNull);
        expect(find.text(l.start), findsOneWidget);
        await gold(find.byType(VexWelcome), 'goldens/welcome_${l.code}_${dark ? 'dark' : 'light'}.png');

        await t.tap(find.text(l.start));
        await t.tap(find.text(l.login));
        expect(started, 1);
        expect(login, 1);

        // لیستی زمان
        await t.tap(find.text(l.native).first);
        await settle(t);
        expect(t.takeException(), isNull);
        if (l.code == 'ckb') await gold(find.byType(MaterialApp), 'goldens/welcome_langs_${dark ? 'dark' : 'light'}.png');
        await t.tap(find.text('English').last);
        await settle(t);
        expect(picked, l.code == 'en' ? isNull : 'en');

        await t.pumpWidget(const SizedBox());
        await t.pump(const Duration(seconds: 1));
      });
    }
  }
}
