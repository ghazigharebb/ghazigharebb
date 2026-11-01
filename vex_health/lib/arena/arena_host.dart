// VEX Health — بەستنەوەی VEX Arena بە ئەپەکەوە
//
// • arenaStore       هەژماری Arena (تۆمار، سکە، کارەکتەر، خاڵ...) — لە main.dart بار دەکرێت
// • AppArenaHost     داتای ئەمڕۆی ئەپەکە دەداتە Arena:
//                    ناو و ژمارە (لە هەژمار)، Band (هەنگاو، دڵ، SpO₂، HRV، سترێس، خەو)،
//                    خۆراک (ژەم و کات)، ئاو (پەرداخ و ئامانج)
//                    لیگ: ئەگەر Band پەیوەست کرابێت ← لیگی Band، ئەگەرنا ← لیگی مۆبایل
// • openArena()      پەڕەی Arena دەکاتەوە (لە پرۆفایلەوە)
// • reloadArena()    دوای گۆڕینی هەژمار، Arena لە سەرەتاوە بار دەکرێتەوە
import 'package:flutter/material.dart';

import '../band/band_state.dart';
import '../core/store.dart';
import '../food/food_page.dart' show openFoodPage;
import '../health/hc.dart' show pushPage;
import '../onboarding/account.dart';
import '../onboarding/reg_data.dart' show asI, cleanPhone, kThisYear;
import '../vitalage/vital_age_engine.dart';
import 'vex_arena.dart' as va;

/// هەژماری Arena — یەک دانەی هاوبەش بۆ هەموو ئەپەکە
final va.ArenaStore arenaStore = va.ArenaStore();

/// دوای چوونە دەرەوە / گەڕاندنەوەی هەژمار: Arena لە سەرەتاوە بار دەکرێتەوە
Future<void> reloadArena() async {
  arenaStore.reset();
  await arenaStore.load();
}

/// داتای ئەپەکە بۆ Arena
class AppArenaHost extends va.ArenaHost {
  AppArenaHost({this.onTab});

  /// گۆڕینی تابی خوارەوە (1 تەندروستی، 3 وەرزش)
  final ValueChanged<int>? onTab;

  @override
  va.ArenaProfile get profile {
    final u = Account.I.user ?? const <String, dynamic>{};
    var age = asI(u['age']);
    if (age <= 0) {
      final y = asI(u['year']);
      age = y > 0 ? kThisYear - y : 30;
    }
    final p = cleanPhone('${u['phone'] ?? ''}');
    return va.ArenaProfile(name: Account.I.name, phone: p.isEmpty ? '' : '0$p', age: age);
  }

  /// ئایا ئەم هەژمارە Band ی پەیوەست کردووە؟ (لە وەڵامی سەرەتای ئەپ + BLE)
  @override
  bool get hasBand {
    final b = Account.I.user?['band'];
    final paired = b is Map && b['paired'] == true;
    return paired || BandState.I.everPaired;
  }

  @override
  bool get bandConnected => hasBand && BandState.I.connected;

  @override
  va.ArenaDayInputs today() {
    final s = Store.I;
    final h = s.h;
    final band = bandConnected;
    final sleepMin = VitalAgeEngine.I.dayOf(DateTime.now())?.sleepMin ?? 0;
    return va.ArenaDayInputs(
      steps: h.steps,
      sleepHours: band ? sleepMin / 60 : 0,
      spo2: band ? h.spo2 : 0,
      stress: band ? h.stress : 0,
      hrv: band ? h.hrv : 0,
      restHr: band ? h.rhr : 0,
      activeMinutes: band ? h.active : 0,
      meals: [for (final f in s.food) va.ArenaMeal(f.n, f.kcal, f.at)],
      waterGlasses: s.waterN,
      waterGoalGlasses: s.waterGlasses,
    );
  }

  @override
  Listenable? get changes => Listenable.merge([Store.I, BandState.I, Account.I, VitalAgeEngine.I]);

  @override
  void openSection(BuildContext context, String catId) {
    final nav = Navigator.of(context);
    switch (catId) {
      case 'food':
      case 'water':
        openFoodPage();
        break;
      case 'run':
      case 'gym':
        if (nav.canPop()) nav.pop();
        onTab?.call(3);
        break;
      default:
        if (nav.canPop()) nav.pop();
        onTab?.call(1);
    }
  }
}

/// پەڕەی VEX Arena
Future<void> openArena({ValueChanged<int>? onTab}) {
  return pushPage(va.VexArenaPage(host: AppArenaHost(onTab: onTab), store: arenaStore));
}
