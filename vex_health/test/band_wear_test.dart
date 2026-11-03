// تاقیکردنەوەی VEX Skin Sense (WearEngine): «Band لە دەستە یان نا»
//
// Band هەر چرکەیەک پاکێتی دڵ (0x28) دەنێرێت؛ گەرمی هەر ٢ چرکە. هەموو کاتەکان دەستکردن (بێ چاوەڕوانی ڕاستەقینە).
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:vex_health/band/ble/vex_wear.dart';

class Sim {
  Sim() : e = WearEngine();
  final WearEngine e;
  DateTime t = DateTime(2026, 11, 3, 12);
  final List<(double, WearState)> changes = [];
  WearState _last = WearState.unknown;
  double sec = 0;

  void _rec() {
    if (e.state != _last) {
      _last = e.state;
      changes.add((sec, e.state));
    }
  }

  void start() {
    e.sessionStarted(t);
    _rec();
  }

  /// یەک چرکە: پاکێتی دڵ (null = هیچ پاکێتێک)، گەرمی (هەر ٢ چرکە)، هەنگاو
  void second({int? hr, double? temp, int? steps, bool rearm = true}) {
    t = t.add(const Duration(seconds: 1));
    sec += 1;
    if (hr != null) e.hr(hr, t);
    if (temp != null && sec.round() % 2 == 0) e.temp(temp, t);
    if (steps != null) e.steps(steps, t);
    if (rearm && e.needsRearm(t)) e.rearmed(t);
    e.tick(t);
    _rec();
  }

  void run(int n, {int? Function(int i)? hr, double? Function(int i)? temp, int? Function(int i)? steps, bool rearm = true}) {
    for (var i = 0; i < n; i++) {
      second(hr: hr?.call(i), temp: temp?.call(i), steps: steps?.call(i), rearm: rearm);
    }
  }

  /// کەی بۆ یەکەم جار گەیشتە [s] (چرکە لە دەستپێکی تاقیکردنەوە)
  double? firstAt(WearState s, {double after = -1}) {
    for (final c in changes) {
      if (c.$1 > after && c.$2 == s) return c.$1;
    }
    return null;
  }
}

/// دڵی ڕاستەقینە بە کەمێک گۆڕان
int hrNow(int i) => 72 + (math.sin(i / 7) * 6).round();

void main() {
  test('دانان: دوای ~٣ چرکە گەرمبوونەوە، لە ٥ چرکەدا «لە دەستە»', () {
    final s = Sim()..start();
    // Band ٣ چرکەی یەکەم 0 دەنێرێت، پاشان دڵ
    s.run(12, hr: (i) => i < 3 ? 0 : hrNow(i), temp: (i) => 33.0);
    final at = s.firstAt(WearState.worn)!;
    expect(at, lessThanOrEqualTo(5));
    expect(s.e.state, WearState.worn);
  });

  test('لە دەستدا ١٠ خولەک: هیچ کات «پچڕان» نییە (تەنانەت لەگەڵ 0 ی کورت ≤٣ چرکە)', () {
    final s = Sim()..start();
    final r = math.Random(7);
    s.run(600, hr: (i) {
      if (i < 3) return 0;
      // هەر ~٤٠ چرکە جارێک ١–٣ چرکە 0 (جووڵەی دەست)
      if (i % 40 >= 20 && i % 40 < 20 + 1 + r.nextInt(3)) return 0;
      return hrNow(i);
    }, temp: (i) => 33.2 + r.nextDouble() * 0.3);
    expect(s.firstAt(WearState.off), isNull);
    expect(s.e.state, WearState.worn);
  });

  test('لابردن (Band 0 دەنێرێت): دوای ٥ چرکە «لە دەست نییە»', () {
    final s = Sim()..start();
    s.run(30, hr: (i) => i < 3 ? 0 : hrNow(i), temp: (i) => 33.0);
    final removedAt = s.sec;
    s.run(20, hr: (i) => 0, temp: (i) => 33.0 - i * 0.05);
    final off = s.firstAt(WearState.off)!;
    expect(off - removedAt, inInclusiveRange(4, 6));
  });

  test('لابردن (Band هیچ نانێرێت): لە ≤٨ چرکەدا «لە دەست نییە»', () {
    final s = Sim()..start();
    s.run(30, hr: (i) => i < 3 ? 0 : hrNow(i), temp: (i) => 33.0);
    final removedAt = s.sec;
    s.run(20, temp: (i) => 33.0);
    final off = s.firstAt(WearState.off)!;
    expect(off - removedAt, lessThanOrEqualTo(8));
    expect(s.e.rearms, greaterThan(0));
  });

  test('لابردن + گەرمی دادەبەزێت: خێراتر (≤٥ چرکە)', () {
    final s = Sim()..start();
    s.run(40, hr: (i) => i < 3 ? 0 : hrNow(i), temp: (i) => 33.4);
    final removedAt = s.sec;
    // Band چەند چرکەیەک دڵی کۆن دەنێرێت، پاشان هیچ؛ گەرمی خێرا دادەبەزێت
    s.run(15, hr: (i) => i < 1 ? 74 : null, temp: (i) => 33.4 - (i + 1) * 0.8);
    final off = s.firstAt(WearState.off)!;
    expect(off - removedAt, lessThanOrEqualTo(6));
  });

  test('دووبارە لە دەست کردنەوە: لە ≤٥ چرکەی یەکەم دڵدا «لە دەستە»', () {
    final s = Sim()..start();
    s.run(20, hr: (i) => i < 3 ? 0 : hrNow(i), temp: (i) => 33.0);
    s.run(30, hr: (i) => 0, temp: (i) => 28.0);
    expect(s.e.state, WearState.off);
    final wearAt = s.sec;
    // Band دوای ~٣ چرکە دڵ دەدۆزێتەوە
    s.run(10, hr: (i) => i < 3 ? 0 : hrNow(i), temp: (i) => 29.0 + i * 0.3);
    final on = s.firstAt(WearState.worn, after: wearAt)!;
    expect(on - wearAt, lessThanOrEqualTo(5));
  });

  test('یەک دڵی کۆن دوای لابردن «لە دەستە» ی هەڵە نادات', () {
    final s = Sim()..start();
    s.run(20, hr: (i) => i < 3 ? 0 : hrNow(i), temp: (i) => 33.0);
    s.run(10, hr: (i) => 0, temp: (i) => 32.0);
    expect(s.e.state, WearState.off);
    final at = s.sec;
    s.run(1, hr: (i) => 71); // بەهای کۆنی Band
    s.run(10, hr: (i) => 0, temp: (i) => 30.0);
    expect(s.firstAt(WearState.worn, after: at), isNull);
  });

  test('ڕۆیشتن (هەنگاو) + 0 ی ٧ چرکە: هێشتا لە دەستە؛ ١٠+ چرکە: لە دەست نییە', () {
    final s = Sim()..start();
    var steps = 1000;
    s.run(20, hr: (i) => i < 3 ? 0 : hrNow(i), temp: (i) => 33.0, steps: (i) => steps += 2);
    final a = s.sec;
    s.run(7, hr: (i) => 0, temp: (i) => 33.0, steps: (i) => steps += 2);
    expect(s.e.state, WearState.worn);
    s.run(1, hr: (i) => hrNow(i), temp: (i) => 33.0, steps: (i) => steps += 2);
    expect(s.firstAt(WearState.off, after: a), isNull);
    final b = s.sec;
    s.run(14, hr: (i) => 0, temp: (i) => 33.0, steps: (i) => steps += 2);
    final off = s.firstAt(WearState.off, after: b)!;
    expect(off - b, inInclusiveRange(9, 11));
  });

  test('لەسەر شەحن: یەکسەر «لە دەست نییە»؛ دوای لابردنی شەحن و دانان: «لە دەستە»', () {
    final s = Sim()..start();
    s.run(10, hr: (i) => i < 3 ? 0 : hrNow(i), temp: (i) => 33.0);
    s.e.setCharging(true, s.t);
    expect(s.e.state, WearState.off);
    s.run(5, hr: (i) => 80);
    expect(s.e.state, WearState.off, reason: 'لە کاتی شەحندا دڵ هەڵە نییە');
    s.e.setCharging(false, s.t);
    s.run(8, hr: (i) => i < 3 ? 0 : hrNow(i), temp: (i) => 32.0);
    expect(s.e.state, WearState.worn);
  });

  test('دەستپێکردن بێ دەست: دوای ماوەی گەرمبوونەوە «لە دەست نییە» (نەک «لە دەستە»)', () {
    final s = Sim()..start();
    s.run(15, hr: (i) => 0, temp: (i) => 26.0);
    expect(s.firstAt(WearState.worn), isNull);
    final off = s.firstAt(WearState.off)!;
    expect(off, lessThanOrEqualTo(10));
  });

  test('هەوای سارد (گەرمیی پێست ٢٦°) لە دەستدا: «لە دەست نییە» ی هەڵە نییە', () {
    final s = Sim()..start();
    s.run(300, hr: (i) => i < 3 ? 0 : hrNow(i), temp: (i) => 26.0);
    expect(s.firstAt(WearState.off), isNull);
    expect(s.e.state, WearState.worn);
  });

  test('لۆگ: هەموو گۆڕانێک تۆمار دەکرێت', () {
    final s = Sim()..start();
    s.run(10, hr: (i) => i < 3 ? 0 : hrNow(i), temp: (i) => 33.0);
    s.run(8, hr: (i) => 0, temp: (i) => 33.0);
    final txt = s.e.log.map((e) => e.text).join('|');
    expect(txt, contains('→ worn'));
    expect(txt, contains('→ off'));
  });
}
