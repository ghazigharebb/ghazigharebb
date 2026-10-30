// تاقیکردنەوەی سیاسەتی پاراستنی نهێنی: 6 زمان × ڕووناک و تاریک + کۆپیکردنی ئیمەیڵ
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vex_health/core/theme.dart';
import 'package:vex_health/onboarding/privacy_policy.dart';
import 'package:vex_health/onboarding/reg_lang_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  test('privacy policy: every language is complete', () {
    for (final lang in ['ckb', 'kmr', 'en', 'ar', 'fa', 'tr']) {
      final d = privacyPolicy(lang);
      expect(d.sections.length, 11, reason: lang);
      expect(d.highlights.length, 3, reason: lang);
      expect(d.rtl, !(lang == 'en' || lang == 'tr'), reason: lang);
      for (final s in d.sections) {
        expect(s.length, 2);
        expect(s[0].trim(), isNotEmpty);
        expect(s[1].trim(), isNotEmpty);
      }
      expect(d.sections.first[1].contains('{email}'), isTrue, reason: lang);
      expect(d.sections.last[1].contains('{email}'), isTrue, reason: lang);
      // هەمان ژمارەکان لە هەموو زمانەکاندا
      final all = d.sections.map((s) => s[1]).join(' ');
      expect(all.contains('30'), isTrue, reason: lang);
      expect(all.contains('18'), isTrue, reason: lang);
      expect(d.plainText.contains(kPrivacyEmail), isTrue, reason: lang);
      expect(d.plainText.contains('{email}'), isFalse, reason: lang);
    }
    // هەمان ژمارەی خاڵ لە هەر بەشێکدا لە هەموو زمانەکاندا
    final ref = privacyPolicy('ckb').sections.map((s) => '• '.allMatches(s[1]).length).toList();
    for (final lang in ['kmr', 'en', 'ar', 'fa', 'tr']) {
      expect(privacyPolicy(lang).sections.map((s) => '• '.allMatches(s[1]).length).toList(), ref, reason: lang);
    }
  });

  for (final lang in ['ckb', 'kmr', 'en', 'ar', 'fa', 'tr']) {
    for (final light in [false, true]) {
      testWidgets('privacy $lang ${light ? 'light' : 'dark'}', (t) async {
        SharedPreferences.setMockInitialValues({});
        await t.binding.setSurfaceSize(const Size(400, 4600));
        LangState.I.code = lang;
        await t.runAsync(() => VexTheme.I.setMode(light ? VexMode.light : VexMode.dark));
        await t.pumpWidget(MaterialApp(navigatorKey: navKey, home: const PrivacyPolicyPage()));
        await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 300)));
        for (var i = 0; i < 10; i++) {
          await t.pump(const Duration(milliseconds: 100));
        }
        final e = t.takeException();
        if (e != null) {
          // ignore: avoid_print
          print('ERR $lang ${e is FlutterError ? e.toStringDeep() : e}');
        }
        expect(e, isNull);
        final d = privacyPolicy(lang);
        expect(find.text(d.sections[6][0]), findsOneWidget);
        await expectLater(find.byType(PrivacyPolicyPage), matchesGoldenFile('goldens/privacy_${lang}_${light ? 'light' : 'dark'}.png'));

        // کۆپیکردنی ئیمەیڵ
        String? clip;
        t.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (c) async {
          if (c.method == 'Clipboard.setData') clip = (c.arguments as Map)['text'] as String?;
          return null;
        });
        await t.ensureVisible(find.text(d.copy));
        await t.tap(find.text(d.copy));
        await t.pump(const Duration(milliseconds: 300));
        expect(clip, kPrivacyEmail);
        expect(find.text(d.copied), findsOneWidget);
        await t.pump(const Duration(seconds: 3));
        expect(find.text(d.copy), findsOneWidget);
        t.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null);
      });
    }
  }
}
