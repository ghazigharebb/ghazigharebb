// تاقیکردنەوەی VEX Skin Sense v4 (WearEngine): «Band لە دەستە یان نا» لە PPG ی خاو (0x78 ← 0x3a)
//
// ١) پاکێتە ڕاستەقینەکانی Band (test/fixtures/ppg_real_20261103.dart) — دەبێت ڕێک هەمان بڕیار و هەمان
//    کاتی پەڕەی تاقیکردنەوە (tools/band_test/index.html) بدات: worn 2800 ms، off 17500 ms، worn 32800 ms.
// ٢) Band ی دەستکرد بۆ هەموو حاڵەتەکان (لابردن، لەدەستکردنەوە، بێدەنگی، شێواوی، شەحن، جووڵە).
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:vex_health/band/ble/vex_wear.dart';

import 'fixtures/ppg_real_20261103.dart';

final DateTime t0 = DateTime(2026, 11, 3, 13, 46, 58, 800);
DateTime at(int ms) => t0.add(Duration(milliseconds: ms));

/// پاکێتی 0x3a: [0x3a, 0, id, ...بایتەکان]
Uint8List pkt(List<int> bytesFrom3, [int id = 0]) => Uint8List.fromList([0x3a, 0, id & 255, ...bytesFrom3]);

/// پاکێتی دەستکرد لە نموونەکانەوە (٤ بایت BE)
Uint8List pktOf(List<int> samples) {
  final b = <int>[];
  for (final x in samples) {
    b.addAll([(x >> 24) & 255, (x >> 16) & 255, (x >> 8) & 255, x & 255]);
  }
  return pkt(b);
}

final _rnd = math.Random(7);
double _ph = 0;

/// لەسەر پێست: ~1.46M + دڵی ٧٢ bpm (٠٫٢٪) — ٥٠ نموونە
List<int> skin({int base = 1460000, double bpm = 72, double amp = 2500}) => [
      for (var i = 0; i < 50; i++) base + (amp * math.sin(_ph += 2 * math.pi * bpm / 60 / 50)).round() + _rnd.nextInt(60),
    ];

/// شێواو (لابردن / دانانەوە): تێربوون و پچڕان
List<int> chaos() => [for (var i = 0; i < 50; i++) _rnd.nextBool() ? 16500000 + _rnd.nextInt(100000) : _rnd.nextInt(9000)];

/// Band ی دەستکرد: هەر چرکەیەک پاکێتێک (ئەگەر null نەبێت)، هەڵسەنگاندن هەر ٢٥٠ ms
class Sim {
  Sim() : e = WearEngine() {
    e.begin(t0);
  }
  final WearEngine e;
  int ms = 0;
  final List<(int, WearState)> changes = [];
  WearState _last = WearState.unknown;

  void _rec() {
    if (e.state != _last) {
      _last = e.state;
      changes.add((ms, e.state));
    }
  }

  /// یەک چرکە: پاکێتێک لە سەرەتای چرکەکەدا، پاشان ٤ هەڵسەنگاندن
  void second(List<int>? samples) {
    if (samples != null) {
      e.packet(Ppg.samples(pktOf(samples)), at(ms));
      _rec();
    }
    for (var k = 0; k < 4; k++) {
      ms += 250;
      e.tick(at(ms));
      _rec();
    }
  }

  void seconds(int n, List<int>? Function() f) {
    for (var i = 0; i < n; i++) {
      second(f());
    }
  }

  /// یەکەم گۆڕان بۆ [s] لە دوای [fromMs]
  int? firstAfter(int fromMs, WearState s) {
    for (final c in changes) {
      if (c.$1 >= fromMs && c.$2 == s) return c.$1;
    }
    return null;
  }

  bool anyOffBetween(int a, int b) => changes.any((c) => c.$1 >= a && c.$1 < b && c.$2 == WearState.off);
}

void main() {
  group('پاکێتی 0x3a', () {
    test('نموونەکان: ٤ بایت big-endian لە بایتی ٣ ەوە (ڕێک وەک Band)', () {
      // یەکەم پاکێتی ڕاستەقینە: 3a 00 00 | 00 0e 9f 08 | 00 0e a0 8f | 00 0e a0 a6 | 00 14 76 55
      final v = pkt([0x00, 0x0e, 0x9f, 0x08, 0x00, 0x0e, 0xa0, 0x8f, 0x00, 0x0e, 0xa0, 0xa6, 0x00, 0x14, 0x76, 0x55, ...List.filled(40, 0)]);
      final s = Ppg.samples(v);
      expect(s.take(4).toList(), [958216, 958607, 958630, 1341013]);
      expect(Ppg.samples(Uint8List(203)..[0] = 0x3a).length, 50);
      expect(Ppg.isPacket(Uint8List(203)..[0] = 0x3a), isTrue);
      expect(Ppg.isPacket(Uint8List(16)..[0] = 0x3a), isFalse);
      expect(Ppg.isPacket(Uint8List(203)..[0] = 0x07), isFalse);
    });

    test('پۆلێنکردن: پاک / شێواو / نێوان', () {
      expect(Ppg.classify(skin()).kind, PpgKind.clean);
      expect(Ppg.classify(chaos()).kind, PpgKind.chaos);
      expect(Ppg.classify(List.filled(50, 200000)).kind, PpgKind.chaos); // ئاستی نزم (هیچ ڕووناکییەک)
      expect(Ppg.classify(List.filled(50, 12000000)).kind, PpgKind.chaos); // تێربوون
      // گۆڕانی ٣٪ ← نێوان (هیچ ناگۆڕێت)
      final mid = [for (var i = 0; i < 50; i++) 2000000 + (i.isEven ? 0 : 60000)];
      expect(Ppg.classify(mid).kind, PpgKind.mid);
    });
  });

  group('پاکێتە ڕاستەقینەکانی Band (JCV8B CB6164)', () {
    test('ڕێک هەمان بڕیار و کاتی پەڕەی تاقیکردنەوە', () {
      final e = WearEngine();
      e.begin(at(0));
      final kinds = <PpgKind>[];
      final changes = <(int, WearState)>[];
      var last = e.state, i = 0;
      void rec(int ms) {
        if (e.state != last) {
          last = e.state;
          changes.add((ms, e.state));
        }
      }

      for (var ms = 0; ms <= 44500; ms += 250) {
        while (i < realPackets.length && realPackets[i].$1 <= ms) {
          final (pms, bytes) = realPackets[i++];
          kinds.add(e.packet(Ppg.samples(pkt(bytes)), at(pms)).kind);
          rec(pms);
        }
        e.tick(at(ms));
        rec(ms);
      }
      expect(changes, [(2800, WearState.worn), (17500, WearState.off), (32800, WearState.worn)]);
      const c = PpgKind.clean, x = PpgKind.chaos;
      expect(kinds, [c, c, c, c, c, c, c, c, c, c, c, c, x, x, x, x, x, c, c, c, c, c, c, c, c, c, c]);
      // لابردن: ≤ ٥٫٥ چرکە لە دەنگی «لای ببە»؛ لەدەستکردن: ≤ ٦ چرکە لە دەنگی «لە دەستی بکە»
      final offPh = realPhases.firstWhere((p) => p.$2 == 'p78:off').$1;
      final onPh = realPhases.firstWhere((p) => p.$2 == 'p78:on1').$1;
      expect(17500 - offPh, lessThanOrEqualTo(5500));
      expect(32800 - onPh, lessThanOrEqualTo(6000));
    });

    test('دڵ لە PPG ی ڕاستەقینە: ژمارەیەکی ئاسایی (٥٥–١١٠)', () {
      final h = PpgHeart();
      int? bpm;
      for (final (ms, bytes) in realPackets) {
        if (ms < 3800 || ms >= 12500) continue; // تەنها کاتێک لە دەستە و جێگیرە
        bpm = h.add(Ppg.samples(pkt(bytes))) ?? bpm;
      }
      expect(bpm, isNotNull);
      expect(bpm!, inInclusiveRange(55, 110));
    });
  });

  group('Band ی دەستکرد', () {
    test('لە دەستە ← یەکەم پاکێتی پاک (یەکسەر)', () {
      final s = Sim()..seconds(3, skin);
      expect(s.changes.first, (0, WearState.worn));
    });

    test('لابردن: ٢ پاکێتی شێواو + بێدەنگی ← لە دەست نییە ≤ ٤ چرکە', () {
      final s = Sim()..seconds(10, skin);
      final off0 = s.ms;
      s
        ..seconds(2, chaos)
        ..seconds(10, () => null);
      final off = s.firstAfter(off0, WearState.off)!;
      expect(off - off0, lessThanOrEqualTo(4000));
      expect(s.e.state, WearState.off);
    });

    test('لابردنی خێرا (بێ پاکێتی شێواو) ← ≤ ٣ چرکە', () {
      final s = Sim()..seconds(10, skin);
      final off0 = s.ms;
      s.seconds(6, () => null);
      expect(s.firstAfter(off0, WearState.off)! - off0, lessThanOrEqualTo(3000));
    });

    test('لەدەستکردنەوە: Band دەست پێدەکاتەوە ← لە دەستە بە یەکەم پاکێتی پاک', () {
      final s = Sim()
        ..seconds(10, skin)
        ..seconds(2, chaos)
        ..seconds(15, () => null);
      expect(s.e.state, WearState.off);
      final on0 = s.ms;
      s
        ..seconds(2, () => null) // Band ~٢–٣ چرکە دەخایەنێت تا دەست پێدەکاتەوە
        ..seconds(2, chaos)
        ..seconds(5, skin);
      expect(s.firstAfter(on0, WearState.worn)! - on0, lessThanOrEqualTo(4000));
    });

    test('٣ پاکێتی شێواو بە دوای یەکدا ← لە دەست نییە (تەنانەت ئەگەر Band هەر بنێرێت)', () {
      final s = Sim()
        ..seconds(5, skin)
        ..seconds(3, chaos);
      expect(s.e.state, WearState.off);
      expect(s.e.reason, startsWith('ppg chaos'));
    });

    test('جووڵە لە دەستدا: ١–٢ پاکێتی شێواو / نێوان ← هیچ «لە دەست نییە» ی هەڵە نییە', () {
      final s = Sim()..seconds(5, skin);
      final a = s.ms;
      for (var k = 0; k < 20; k++) {
        s
          ..second(skin(amp: 9000)) // جووڵەی بەهێز
          ..second(chaos())
          ..second(skin())
          ..second(chaos())
          ..second(chaos())
          ..seconds(2, skin);
      }
      expect(s.anyOffBetween(a, s.ms), isFalse);
      expect(s.e.state, WearState.worn);
    });

    test('١٠ خولەک لە دەستدا (پاکێتێکی ون لێرە و لەوێ) ← ٠ پچڕان', () {
      final s = Sim();
      for (var i = 0; i < 600; i++) {
        s.second(i % 97 == 50 ? null : skin(base: 1400000 + 600 * (i % 200)));
      }
      expect(s.changes.where((c) => c.$2 == WearState.off), isEmpty);
    });

    test('هیچ پاکێتێک لە سەرەتاوە ← لە دەست نییە دوای ٣٫٥ چرکە', () {
      final s = Sim()..seconds(6, () => null);
      expect(s.changes, [(3500, WearState.off)]);
    });

    test('شەحن ← یەکسەر لە دەست نییە؛ دەرچوون ← دووبارە پشکنین', () {
      final s = Sim()..seconds(5, skin);
      s.e.setCharging(true, at(s.ms));
      expect(s.e.state, WearState.off);
      s.seconds(3, skin); // پاکێت لە کاتی شەحن دا هیچ ناگۆڕێت
      expect(s.e.state, WearState.off);
      s.e.setCharging(false, at(s.ms));
      s.seconds(2, skin);
      expect(s.e.state, WearState.worn);
    });

    test('دڵی دەستکرد ٧٢ bpm ← ٧٢ ± ٢', () {
      final h = PpgHeart();
      int? bpm;
      for (var i = 0; i < 10; i++) {
        bpm = h.add(skin(bpm: 72));
      }
      expect(bpm, isNotNull);
      expect((bpm! - 72).abs(), lessThanOrEqualTo(2));
      // لە دەست نییە ← دڵ نیشان نادرێت
      final e = WearEngine()..begin(t0);
      e.packet(skin(), t0);
      e.tick(t0.add(const Duration(seconds: 4)));
      expect(e.state, WearState.off);
      expect(e.lastHr, isNull);
    });
  });
}
