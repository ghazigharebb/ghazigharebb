// VEX Band — کۆنتڕۆڵەری پێوانەی ECG
//
// ڕێڕەو: ڕێکخستن (calibrating، چاوەڕێی پەنجە) ← پێوانە (30 چرکە، تەنها کاتێک پەنجە لەسەرە) ← تەواو.
// فرمانەکان (بەپێی SDK ی فرۆشیار، PPGActivity.java):
//   1) measure(HRV, 50000, start)   — فرمانی 0x28
//   2) ppgStream(true)              — فرمانی 0x07  (setECGRealtimeDuringHRVEnabled)
// شەپۆلی خاو لە VexBand.I.ppgStream دێت و لە EcgSignal فلتەر و شیکار دەکرێت.
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../band/ble/vex_ble.dart';
import '../band/ble/vex_parsers.dart';
import 'ecg_signal.dart';

enum EcgPhase { waiting, measuring, done, failed }

class EcgResult {
  final double? bpm; // لێدانی دڵ
  final int? hrv, stress; // HRV (ms) و سترێس
  final EcgStats stats; // لە شەپۆلەکەوە
  final double quality; // 0..1
  final List<double> trace; // شەپۆلی تۆمارکراو (-1..1)
  final double sampleRate;
  final bool rightWrist;
  final DateTime at;
  const EcgResult({
    required this.bpm, required this.hrv, required this.stress, required this.stats, required this.quality,
    required this.trace, required this.sampleRate, required this.rightWrist, required this.at,
  });
}

class EcgController extends ChangeNotifier {
  EcgController({this.targetSeconds = 30, this.rightWrist = false, this.onDone});

  /// ماوەی پێوانە بە چرکە (تەنها کاتێک پەنجە لەسەر ئەلیکترۆدە دەژمێردرێت)
  final int targetSeconds;

  /// Band لە دەستی ڕاستە؟ (ئاراستەی شەپۆل)
  bool rightWrist;

  final void Function(EcgResult)? onDone;

  late final EcgSignal sig = EcgSignal(invert: rightWrist);
  final ValueNotifier<int> frame = ValueNotifier<int>(0);

  EcgPhase phase = EcgPhase.waiting;
  String failReason = '';
  Duration elapsed = Duration.zero;
  EcgResult? result;
  bool demo = false; // دەستکرد (تەنها debug، کاتێک Band پەیوەست نییە)
  bool fingerLost = false;

  StreamSubscription<VexPpg>? _ppg;
  StreamSubscription<VexMsg>? _raw;
  Timer? _timer;
  DateTime _startedAt = DateTime.now();
  DateTime _lastTick = DateTime.now();
  DateTime? _contactSince, _lostSince;
  VexMeasureResult? _dev;
  final List<double> _rec = <double>[];
  int _recSeen = 0;
  double _synthT = 0;
  DateTime? _synthLast;
  bool _stopped = false;
  DateTime _lastKick = DateTime.now();

  double get progress => (elapsed.inMilliseconds / (targetSeconds * 1000)).clamp(0.0, 1.0).toDouble();
  int get secondsLeft => (targetSeconds - elapsed.inMilliseconds / 1000).ceil().clamp(0, targetSeconds).toInt();

  // ───────────── دەستپێک ─────────────
  Future<void> start() async {
    _stopped = false;
    sig.invert = rightWrist;
    sig.reset();
    _rec.clear();
    _recSeen = 0;
    _dev = null;
    elapsed = Duration.zero;
    phase = EcgPhase.waiting;
    failReason = '';
    result = null;
    fingerLost = false;
    _startedAt = _lastTick = _lastKick = DateTime.now();
    _contactSince = _lostSince = null;
    _synthLast = null;
    notifyListeners();

    if (VexBand.I.linked) {
      demo = false;
      try {
        await VexBand.I.startWaveform();
      } catch (e) {
        _fail('band');
        return;
      }
      await _ppg?.cancel();
      await _raw?.cancel();
      _ppg = VexBand.I.ppgStream.stream.listen((p) => sig.addPacket(p.samples));
      _raw = VexBand.I.raw.stream.listen((m) {
        if (m is VexMeasureResult && !m.stopped) _dev = m;
      });
    } else if (kDebugMode) {
      demo = true; // بۆ بینینی دیزاین بەبێ Band
    } else {
      _fail('noband');
      return;
    }
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 33), (_) => _tick());
  }

  void _tick() {
    if (_stopped) return;
    final now = DateTime.now();
    if (demo) _synth(now);

    if (sig.beatNow) {
      sig.beatNow = false;
      if (phase == EcgPhase.measuring) HapticFeedback.selectionClick();
    }

    // Band پێوانەکەی ڕاگرت (بۆ نموونە دوای 50 چرکە)؟ ← دووبارە دەست پێدەکەینەوە
    if (!demo && VexBand.I.linked && (phase == EcgPhase.waiting || phase == EcgPhase.measuring)) {
      final lp = sig.lastPacket ?? _startedAt;
      if (now.difference(lp).inMilliseconds > 2500 && now.difference(_lastKick).inSeconds >= 5) {
        _lastKick = now;
        VexBand.I.startWaveform().catchError((_) {});
      }
    }

    final c = sig.contact(now);
    switch (phase) {
      case EcgPhase.waiting:
        if (c) {
          _contactSince ??= now;
          if (now.difference(_contactSince!).inMilliseconds >= 1200) {
            phase = EcgPhase.measuring;
            _lastTick = now;
            fingerLost = false;
            sig.rrLog.clear();
            _rec.clear();
            _recSeen = sig.cursor;
            HapticFeedback.lightImpact();
            notifyListeners();
          }
        } else {
          _contactSince = null;
        }
        if (now.difference(_startedAt).inSeconds > 90) {
          _fail('nofinger');
          return;
        }
      case EcgPhase.measuring:
        final dt = now.difference(_lastTick);
        _lastTick = now;
        _record();
        if (c) {
          if (fingerLost) {
            fingerLost = false;
            notifyListeners();
          }
          _lostSince = null;
          final before = secondsLeft;
          elapsed += dt;
          if (secondsLeft != before) notifyListeners();
          if (elapsed.inMilliseconds >= targetSeconds * 1000) {
            _finish();
            return;
          }
        } else {
          _lostSince ??= now;
          if (!fingerLost) {
            fingerLost = true;
            HapticFeedback.mediumImpact();
            notifyListeners();
          }
          // 3 چرکە بێ پەنجە ← دووبارە لە سەرەتاوە
          if (now.difference(_lostSince!).inSeconds >= 3) {
            phase = EcgPhase.waiting;
            _contactSince = null;
            fingerLost = false;
            elapsed = Duration.zero;
            _rec.clear();
            sig.rrLog.clear();
            _startedAt = now;
            notifyListeners();
          }
        }
      case EcgPhase.done:
      case EcgPhase.failed:
        break;
    }
    frame.value++;
  }

  /// هەموو نموونە نوێیەکانی ناو sweep تۆمار دەکات
  void _record() {
    final s = sig.sweep;
    if (s.isEmpty) return;
    var i = _recSeen;
    if (i >= s.length) i = 0;
    var guard = 0;
    while (i != sig.cursor && guard < s.length) {
      _rec.add(s[i]);
      i = (i + 1) % s.length;
      guard++;
    }
    _recSeen = sig.cursor;
    final cap = (sig.rate * (targetSeconds + 2)).round();
    if (_rec.length > cap) _rec.removeRange(0, _rec.length - cap);
  }

  void _synth(DateTime now) {
    // 250 نموونە لە چرکەیەکدا (وەک ECG ی ڕاستەقینە)
    const fs = 250.0;
    final last = _synthLast ?? now;
    _synthLast = now;
    final n = (now.difference(last).inMicroseconds / 1e6 * fs).round().clamp(0, 40);
    final out = <int>[];
    for (var i = 0; i < n; i++) {
      _synthT += 1 / fs;
      final v = ecgSynth(_synthT) * (rightWrist ? -1 : 1) + 0.02 * ((_synthT * 7919) % 1 - .5);
      out.add((8000000 + 3000 * v).round());
    }
    // 2.5 چرکەی یەکەم پەنجە نییە (هێڵی ڕاست)
    if (out.isNotEmpty && now.difference(_startedAt).inMilliseconds > 2500) sig.addPacket(out, now: now);
  }

  Future<void> _finish() async {
    _timer?.cancel();
    _stopped = true;
    _record();
    HapticFeedback.heavyImpact();
    phase = EcgPhase.done;
    notifyListeners();
    await _stopDevice();
    // چەند چرکەیەک چاوەڕێی ئەنجامی HRV ی Band دەکەین
    for (var i = 0; i < 25 && _dev == null && !demo; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
    final d = _dev;
    final st = EcgStats.from(sig.rrLog);
    // دڵ: لە شەپۆلەکەوە (وردترە، 30 چرکە)؛ ئەگەر کەم بوو ← ئەنجامی Band
    final bpm = st.bpm ?? ((d != null && d.hr > 0) ? d.hr.toDouble() : sig.bpm);
    final hrv = (d != null && d.hrv > 0) ? d.hrv : st.rmssd?.round();
    result = EcgResult(
      bpm: bpm,
      hrv: hrv,
      stress: (d != null && d.stress > 0) ? d.stress : null,
      stats: st,
      quality: sig.quality == 0 ? (st.beats > 10 ? 0.7 : 0.4) : sig.quality,
      trace: List<double>.of(_rec),
      sampleRate: sig.rate,
      rightWrist: rightWrist,
      at: DateTime.now(),
    );
    notifyListeners();
    onDone?.call(result!);
  }

  void _fail(String why) {
    _timer?.cancel();
    _stopped = true;
    phase = EcgPhase.failed;
    failReason = why;
    _stopDevice();
    notifyListeners();
  }

  Future<void> _stopDevice() async {
    await _ppg?.cancel();
    await _raw?.cancel();
    _ppg = _raw = null;
    if (VexBand.I.linked) {
      try {
        await VexBand.I.stopWaveform();
      } catch (_) {}
    }
  }

  /// هەڵوەشاندنەوە / داخستن
  Future<void> cancel() async {
    _timer?.cancel();
    _stopped = true;
    await _stopDevice();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _stopped = true;
    _ppg?.cancel();
    _raw?.cancel();
    if (VexBand.I.linked) {
      VexBand.I.stopWaveform().catchError((_) {});
    }
    frame.dispose();
    super.dispose();
  }
}
