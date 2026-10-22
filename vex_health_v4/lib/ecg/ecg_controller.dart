// VEX Band — کۆنتڕۆڵەری پێوانەی ECG
//
// ڕێڕەو: چاوەڕێی پەنجە ← پێوانە (٣٠ چرکە، تەنها کاتێک پەنجە لەسەرە) ← تەواو.
// فرمانەکان (بەپێی SDK ی فرۆشیار، PPGActivity.java):
//   1) measure(HRV, 50000, start)   — فرمانی 0x28
//   2) ppgStream(true)              — فرمانی 0x07
// شەپۆلی خاو لە VexBand.I.ppgStream دێت.
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../band/ble/vex_ble.dart';
import '../band/ble/vex_parsers.dart';
import 'ecg_signal.dart';

enum EcgPhase { waiting, measuring, done, failed }

class EcgResult {
  final double? bpm; // لێدانی دڵ
  final int? hrv, stress; // لە Band ـەوە (ئەگەر نێردرا)
  final double quality; // 0..1
  final List<double> trace; // شەپۆلی تۆمارکراو (ئاسایی کراو)
  final double sampleRate;
  final DateTime at;
  const EcgResult({required this.bpm, required this.hrv, required this.stress, required this.quality, required this.trace, required this.sampleRate, required this.at});
}

class EcgController extends ChangeNotifier {
  EcgController({this.targetSeconds = 30, this.onDone});

  /// ماوەی پێوانە بە چرکە (تەنها کاتێک پەنجە لەسەر ئەلیکترۆدە دەژمێردرێت)
  final int targetSeconds;

  /// کاتێک پێوانە تەواو بوو
  final void Function(EcgResult)? onDone;

  final EcgSignal sig = EcgSignal();
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
  double _synthT = 0;
  bool _stopped = false;

  double get progress => (elapsed.inMilliseconds / (targetSeconds * 1000)).clamp(0.0, 1.0).toDouble();
  int get secondsLeft => (targetSeconds - elapsed.inMilliseconds / 1000).ceil().clamp(0, targetSeconds).toInt();

  // ───────────── دەستپێک ─────────────
  Future<void> start() async {
    _stopped = false;
    sig.reset();
    _rec.clear();
    _dev = null;
    elapsed = Duration.zero;
    phase = EcgPhase.waiting;
    failReason = '';
    result = null;
    _startedAt = _lastTick = DateTime.now();
    _contactSince = _lostSince = null;
    notifyListeners();

    if (VexBand.I.linked) {
      demo = false;
      try {
        await VexBand.I.startWaveform();
      } catch (e) {
        _fail('نەتوانرا فرمان بنێردرێت بۆ Band');
        return;
      }
      _ppg = VexBand.I.ppgStream.stream.listen((p) => sig.addPacket(p.samples));
      _raw = VexBand.I.raw.stream.listen((m) {
        if (m is VexMeasureResult && !m.stopped) _dev = m;
      });
    } else if (kDebugMode) {
      demo = true; // بۆ بینینی دیزاین بەبێ Band
    } else {
      _fail('Band پەیوەست نییە');
      return;
    }
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 33), (_) => _tick());
  }

  void _tick() {
    if (_stopped) return;
    final now = DateTime.now();
    if (demo) _synth(now);

    // لێدانی دۆزراوە ← لەرزینی سووک
    if (sig.beatNow) {
      sig.beatNow = false;
      if (phase == EcgPhase.measuring) HapticFeedback.lightImpact();
    }

    final c = sig.contact(now);
    switch (phase) {
      case EcgPhase.waiting:
        if (c) {
          _contactSince ??= now;
          if (now.difference(_contactSince!).inMilliseconds >= 1000) {
            phase = EcgPhase.measuring;
            _lastTick = now;
            fingerLost = false;
            notifyListeners();
          }
        } else {
          _contactSince = null;
        }
        if (now.difference(_startedAt).inSeconds > 90) {
          _fail('پەنجە نەدۆزرایەوە. دووبارە هەوڵ بدە.');
          return;
        }
      case EcgPhase.measuring:
        final dt = now.difference(_lastTick);
        _lastTick = now;
        if (c) {
          if (fingerLost) {
            fingerLost = false;
            notifyListeners();
          }
          _lostSince = null;
          elapsed += dt;
          _rec.add(sig.disp.isEmpty ? 0 : sig.disp.last);
          if (elapsed.inMilliseconds >= targetSeconds * 1000) {
            _finish();
            return;
          }
        } else {
          _lostSince ??= now;
          if (!fingerLost) {
            fingerLost = true;
            notifyListeners();
          }
          // ٣ چرکە بێ پەنجە ← بگەڕێتەوە بۆ چاوەڕێکردن
          if (now.difference(_lostSince!).inSeconds >= 3) {
            phase = EcgPhase.waiting;
            _contactSince = null;
            fingerLost = false;
            elapsed = Duration.zero;
            _rec.clear();
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

  void _synth(DateTime now) {
    // ٥٠ نموونە لە چرکەیەکدا ← ٢ نموونە بۆ هەر 33ms
    const dt = 1 / 50.0;
    final n = 2;
    final out = <int>[];
    for (var i = 0; i < n; i++) {
      _synthT += dt;
      out.add((100000 + 3000 * ecgSynth(_synthT)).round());
    }
    // لە ٢ چرکەی یەکەمدا پەنجە نییە (هێڵی ڕاست)
    if (now.difference(_startedAt).inMilliseconds > 2500) sig.addPacket(out, now: now);
  }

  Future<void> _finish() async {
    _timer?.cancel();
    _stopped = true;
    HapticFeedback.mediumImpact();
    phase = EcgPhase.done;
    notifyListeners();
    await _stopDevice();
    // چەند چرکەیەک چاوەڕێی ئەنجامی HRV ی Band دەکەین
    for (var i = 0; i < 25 && _dev == null && !demo; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
    final d = _dev;
    final live = sig.bpm;
    final bpm = (d != null && d.hr > 0) ? d.hr.toDouble() : live;
    result = EcgResult(
      bpm: bpm,
      hrv: (d != null && d.hrv > 0) ? d.hrv : null,
      stress: (d != null && d.stress > 0) ? d.stress : null,
      quality: sig.quality == 0 ? 0.6 : sig.quality,
      trace: List<double>.of(_rec.length > 1500 ? _rec.sublist(_rec.length - 1500) : _rec),
      sampleRate: sig.rate,
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
