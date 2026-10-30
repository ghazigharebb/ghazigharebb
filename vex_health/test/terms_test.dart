import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vex_health/core/theme.dart';
import 'package:vex_health/onboarding/reg_lang_state.dart';
import 'package:vex_health/onboarding/terms_of_use.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;
  for (final lang in ['ckb', 'kmr', 'en', 'ar', 'fa', 'tr']) {
    for (final light in [false, true]) {
      testWidgets('terms $lang ${light ? 'light' : 'dark'}', (t) async {
        expect(termsOfUse(lang).sections.length, 11);
        SharedPreferences.setMockInitialValues({});
        await t.binding.setSurfaceSize(const Size(400, 2900));
        LangState.I.code = lang;
        await t.runAsync(() => VexTheme.I.setMode(light ? VexMode.light : VexMode.dark));
        await t.pumpWidget(MaterialApp(navigatorKey: navKey, home: const TermsOfUsePage()));
        await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 300)));
        for (var i = 0; i < 10; i++) {
          await t.pump(const Duration(milliseconds: 100));
        }
        expect(t.takeException(), isNull);
        await expectLater(find.byType(TermsOfUsePage), matchesGoldenFile('goldens/terms_${lang}_${light ? 'light' : 'dark'}.png'));
      });
    }
  }
}
