// VEX Health — بەستنەوەی VEX Arena بە ئەپەکەوە
//
// • arenaStore       هەژماری Arena (ناو، سکە، کارەکتەر...) — لە main.dart بار دەکرێت
// • AppArenaHost     داتای ئەمڕۆی ئەپەکە دەداتە Arena (ناو و ژمارە، هەنگاو، ژەم، ئاو، کێش)
// • openArena()      پەڕەی Arena دەکاتەوە (لە پرۆفایلەوە)
//
// تێبینی: خەو، HRV و داتای دوێنێ و وەرزش هێشتا نموونەن (لەگەڵ Band و بەشی وەرزشدا دەبەسترێنەوە).
import 'package:flutter/material.dart';

import '../core/store.dart';
import '../health/hc.dart' show pushPage;
import '../food/food_page.dart' show openFoodPage;
import '../onboarding/account.dart';
import '../onboarding/reg_data.dart';
import 'vex_arena.dart' as va;

/// هەژماری Arena — یەک دانەی هاوبەش بۆ هەموو ئەپەکە
final va.ArenaStore arenaStore = va.ArenaStore();

/// دوای چوونە دەرەوە / گەڕاندنەوەی هەژمار: Arena لە سەرەتاوە بار دەکرێتەوە
Future<void> reloadArena() async {
  final s = arenaStore;
  s.acc = null;
  s.skin = 'auto';
  s.title = 't0';
  s.bio = 'بۆ تەندروستی';
  s.ch = '';
  s.coins = 340;
  s.season = 2140;
  s.bestPower = 0;
  s.owned = <String>{};
  s.guess = <String, String>{};
  s.revealed = <String>{};
  s.seasonEnd = null;
  await s.load();
}

/// داتای ئەپەکە بۆ Arena
class AppArenaHost extends va.ArenaHost {
  AppArenaHost({this.onTab});

  /// گۆڕینی تابی خوارەوە (1 تەندروستی، 3 وەرزش)
  final ValueChanged<int>? onTab;

  @override
  va.ArenaProfile get profile {
    final u = Account.I.user ?? const <String, dynamic>{};
    int age = asI(u['age']);
    if (age <= 0) {
      final y = asI(u['year']);
      age = y > 0 ? kThisYear - y : 30;
    }
    final g = '${u['wgoal'] ?? ''}';
    return va.ArenaProfile(
      name: Account.I.name,
      phone: cleanPhone('${u['phone'] ?? ''}'),
      age: age,
      weightGoal: (g == 'lose' || g == 'gain' || g == 'keep') ? g : '',
    );
  }

  @override
  va.ArenaDayInputs today() {
    final S = Store.I;
    return va.ArenaDayInputs(
      bandSteps: S.h.steps,
      sleepHours: 6.3,
      spo2: S.h.spo2,
      stress: S.h.stress,
      hrv: S.h.hrv,
      meals: [for (final f in S.food) va.ArenaMeal(f.n, f.kcal, f.v == 'good' || f.v == 'bad' ? f.v : 'ok')],
      waterGlasses: S.waterN,
      waterGoalGlasses: S.waterGlasses,
      weights: [va.ArenaWeight(DateTime.now(), S.h.weightKg.toDouble())],
    );
  }

  @override
  va.ArenaDayInputs yesterday() => const va.ArenaDayInputs(
        bandSteps: 7800,
        sleepHours: 7.6,
        spo2: 96,
        stress: 50,
        hrv: 56,
        meals: [va.ArenaMeal('ژەم', 500, 'good'), va.ArenaMeal('ژەم', 600, 'ok')],
        waterGlasses: 9,
        waterGoalGlasses: 11,
      );

  @override
  Listenable? get changes => Store.I;

  @override
  void openSection(BuildContext context, String catId) {
    final nav = Navigator.of(context);
    switch (catId) {
      case 'food':
      case 'water':
      case 'body':
        nav.pop();
        openFoodPage();
        break;
      case 'run':
      case 'gym':
        nav.pop();
        onTab?.call(3);
        break;
      default:
        nav.pop();
        onTab?.call(1);
    }
  }
}

/// پەڕەی VEX Arena
Future<void> openArena({ValueChanged<int>? onTab}) {
  return pushPage(va.VexArenaPage(host: AppArenaHost(onTab: onTab), store: arenaStore));
}
