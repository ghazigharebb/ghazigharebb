// تاقیکردنەوەی ECG ی زیندوو (هاوشێوەی tools/ecg_check/ecg_live_ref.py)
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:vex_health/ecg/ecg_signal.dart';

double _ecg(double x, double period) {
  final r = 0.25 * math.min(period, 0.9);
  double g(double c, double w, double a) => a * math.exp(-math.pow((x - c) / w, 2).toDouble());
  return g(r - .16, .025, .12) - g(r - .028, .012, .12) + g(r, .016, 1.0) - g(r + .03, .013, .25) + g(r + .27 * math.min(1, period), .06, .45);
}

class _Out {
  _Out(this.sig, this.log, this.heads, this.measFrom);
  final EcgSignal sig;
  final List<(double, double?)> log;
  final List<int> heads;
  final double? measFrom;
}

_Out _sim(double fs, double bpm, int seed, {bool invert = false, int? psize, bool flatBefore = false}) {
  final rnd = math.Random(seed);
  double gauss() {
    final u = math.max(1e-12, rnd.nextDouble()), v = rnd.nextDouble();
    return math.sqrt(-2 * math.log(u)) * math.cos(2 * math.pi * v);
  }

  const secs = 34.0, finger = 3.0;
  final beats = <(double, double)>[];
  var t = 0.0;
  while (t < secs + 2) {
    final p = 60 / bpm * (1 + 0.04 * math.sin(t * 0.9) + 0.015 * gauss());
    beats.add((t, p));
    t += p;
  }
  final events = <(double, List<int>, int)>[];
  var pkt = <int>[];
  var pid = 0, bi = 0;
  final n = (fs * secs).round();
  var target = psize ?? 18 + rnd.nextInt(58);
  for (var i = 0; i < n; i++) {
    final ts = i / fs;
    while (bi + 1 < beats.length && beats[bi + 1].$1 <= ts) {
      bi++;
    }
    int raw;
    if (ts < finger) {
      raw = flatBefore ? 0xFFFFFF : 8000000 + (gauss() * 0.004 * 3000).round();
    } else {
      var v = _ecg(ts - beats[bi].$1, beats[bi].$2) * (invert ? -1 : 1);
      v += 0.04 * gauss() + 0.3 * math.sin(2 * math.pi * 50 * ts) + 1.5 * math.sin(2 * math.pi * 0.3 * ts);
      if (ts - finger < 0.4) v += 6 * (1 - (ts - finger) / 0.4);
      raw = 8000000 + (3000 * v).round();
    }
    pkt.add(raw);
    if (pkt.length >= target) {
      events.add((ts + 0.03 + (gauss() * 0.04).abs(), pkt, pid & 0xff));
      pid++;
      pkt = <int>[];
      target = psize ?? 18 + rnd.nextInt(58);
    }
  }
  for (var k = 0; k + 1 < events.length; k++) {
    if (rnd.nextDouble() < 0.15) events[k] = (events[k + 1].$1, events[k].$2, events[k].$3);
  }
  events.removeWhere((_) => rnd.nextDouble() < 0.01);
  var mx = 0.0;
  for (var k = 0; k < events.length; k++) {
    mx = math.max(mx, events[k].$1);
    events[k] = (mx, events[k].$2, events[k].$3);
  }

  final sig = EcgSignal();
  final t0 = DateTime(2026);
  DateTime at(double s) => t0.add(Duration(microseconds: (s * 1e6).round()));
  var ei = 0;
  t = 0.0;
  double? contactSince, measFrom;
  double? noContact = 0;
  final log = <(double, double?)>[];
  final heads = <int>[];
  while (t < secs) {
    while (ei < events.length && events[ei].$1 <= t) {
      sig.addPacket(events[ei].$2, now: at(events[ei].$1), packetId: events[ei].$3);
      ei++;
    }
    sig.advance(at(t));
    final c = sig.contact(at(t));
    if (c) {
      if (contactSince == null) {
        if (noContact != null && t - noContact >= 0.6) sig.restartLearning();
        contactSince = t;
        noContact = null;
      }
      if (measFrom == null && t - contactSince >= 1.2) {
        measFrom = t;
        sig.rrLog.clear();
      }
    } else {
      contactSince = null;
      noContact ??= t;
    }
    sig.takeTape();
    if (measFrom != null) {
      log.add((t, sig.bpm));
      heads.add(sig.cursor);
    }
    t += 0.033;
  }
  return _Out(sig, log, heads, measFrom);
}

void main() {
  for (final c in <(double, double, int, bool, int?, bool)>[
    (255, 55, 1, false, 40, false),
    (255, 72, 2, true, 81, false),
    (255, 95, 3, false, null, false),
    (255, 130, 1, true, 40, true),
    (250, 72, 3, false, null, true),
    (256, 150, 2, false, 81, false),
    (512, 72, 1, false, 40, false),
  ]) {
    test('live ecg fs=${c.$1} bpm=${c.$2} seed=${c.$3} inv=${c.$4} pkt=${c.$5} flat=${c.$6}', () {
      final o = _sim(c.$1, c.$2, c.$3, invert: c.$4, psize: c.$5, flatBefore: c.$6);
      expect(o.measFrom, isNotNull, reason: 'no finger contact');
      final bpm = c.$2;
      // 8 چرکە دوای دانانی پەنجە: هەموو BPM ـێک لە 6٪ دا
      final late = [for (final e in o.log) if (e.$1 - 3.0 >= 8) e.$2];
      final bad = late.where((b) => b == null || (b - bpm).abs() / bpm > 0.08).length;
      expect(bad, 0, reason: 'late bad $bad/${late.length}: ${late.take(5).toList()}');
      // هیچ کاتێک BPM ی زۆر هەڵە پیشان نادرێت
      final wrong = [for (final e in o.log) if (e.$2 != null && (e.$2! - bpm).abs() / bpm > 0.12) e.$2];
      expect(wrong, isEmpty, reason: 'wrong $wrong');
      // شەپۆل هەموو شاشەکە دەبڕێت و لە سەرەتا گیر نامێنێت
      var wraps = 0, maxHead = 0;
      for (var k = 1; k < o.heads.length; k++) {
        if (o.heads[k] < o.heads[k - 1] - o.sig.window * 0.5) wraps++;
        maxHead = math.max(maxHead, o.heads[k]);
      }
      expect(wraps, greaterThanOrEqualTo(3));
      expect(maxHead, greaterThan(o.sig.window * 0.9));
      // print بۆ بینینی ئەنجام لە CI
      // ignore: avoid_print
      print('fs=${c.$1} bpm=$bpm -> ${o.sig.bpm?.toStringAsFixed(1)} rate=${o.sig.rate} beats=${o.sig.beatCount} wraps=$wraps');
    });
  }

  test('stable rate: sweep length never resets', () {
    final s = EcgSignal();
    final t0 = DateTime(2026);
    final w0 = s.window;
    var cur = 0, i = 0;
    for (var k = 0; k < 400; k++) {
      final now = t0.add(Duration(milliseconds: k * 50));
      s.addPacket([for (var j = 0; j < 13; j++) 8000000 + ((i++ % 50) * 40)], now: now, packetId: k & 0xff);
      s.advance(now);
      if (k > 20) expect(s.cursor == 0 || s.cursor >= cur || s.sweepFull, true);
      cur = s.cursor;
    }
    expect(s.window, w0);
  });
}
