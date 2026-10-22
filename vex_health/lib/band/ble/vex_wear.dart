// VEX Health — «Band لە دەستە یان نا» (wear detection v2: تێکەڵکردنی چەند بەڵگەیەک)
//
// بەڵگەکان (بەهێزترەوە بۆ لاوازتر):
//   ١) شەپۆلی PPG ی ڕاستەقینە: لێدانی دڵ شەپۆلێکی خولاوە (autocorrelation 40–180 bpm). بێ پەنجە/دەست هیچ خولێک نییە.
//   ٢) شەحن: Band لەسەر شەحنەرە = لە دەست نییە (یەکسەر).
//   ٣) پاکێتی زیندوو (0x09): لێدانی دڵ / SpO₂ / گەرمی.  لاوازترە (لەوانەیە بەهای کۆن بمێنێتەوە).
//
// یاسا:
//   • بەبێ پشکنینی PPG، هیچ کات بڕیار نادرێت کە «لە دەست نییە» (تەنها شەحن نەبێت) — هەڵەی درۆزن کەم دەبێت.
//   • «لە دەست نییە» = دوو پشکنینی PPG ی نەرێنی لە دووی یەک (یان یەک پشکنین + نەبوونی نیشانەی ژیان).
//   • «لە دەستە» = یەک پشکنینی ئەرێنی (یەکسەر).
//   • نیشانەی ژیان کە دوای «لە دەست نییە» دێت ← پشکنینێکی خێرا (نەک گۆڕینی ڕاستەوخۆ).
//
// ⚠️ ئەستانەکان لەسەر داتای دەستکرد تاقی کراونەتەوە (tools/wear_check/wear_test.py)، نەک لەسەر Band ی ڕاستەقینە.
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';

enum WearState { unknown, worn, off }

/// ئەنجامی شیکاری PPG
class PpgCheck {
  final bool pulse; // خولی لێدان دۆزرایەوە
  final double ac; // ئەندازەی AC
  final double acf; // بەهێزی خول 0..1
  final double bpm;
  const PpgCheck(this.pulse, this.ac, this.acf, this.bpm);
  @override
  String toString() => 'PpgCheck(pulse=$pulse ac=${ac.toStringAsFixed(1)} acf=${acf.toStringAsFixed(2)} bpm=${bpm.toStringAsFixed(0)})';
}

/// کەمترین AC و acf بۆ ئەوەی «لێدان»ی دڵ بێت. ئەگەر Band ی تۆ ئەندازەی جیاوازی PPG دەنێرێت، ئەمانە ڕێک بخە.
const double kMinAc = 8.0;
const double kMinAcf = 0.45;

/// شیکاری PPG: `x` نموونە خاوەکانن، `rate` = نموونە لە چرکەیەکدا. null = داتای کەم.
PpgCheck? analyzePpg(List<double> x, double rate) {
  final n = x.length;
  if (rate < 5 || n < rate * 3.5) return null;
  // لابردنی DC/drift: کەمکردنەوەی تێکڕای جووڵاوی ١ چرکە
  final w = math.max(3, rate.round());
  final pre = List<double>.filled(n + 1, 0);
  for (var i = 0; i < n; i++) {
    pre[i + 1] = pre[i] + x[i];
  }
  final y = List<double>.filled(n, 0);
  for (var i = 0; i < n; i++) {
    final a = math.max(0, i - w ~/ 2), b = math.min(n, i + w ~/ 2 + 1);
    y[i] = x[i] - (pre[b] - pre[a]) / (b - a);
  }
  // نەرمکردن (٣ خاڵ) و لابردنی تێکڕا
  final z = List<double>.filled(n, 0);
  var m = 0.0;
  for (var i = 0; i < n; i++) {
    z[i] = (y[math.max(0, i - 1)] + y[i] + y[math.min(n - 1, i + 1)]) / 3;
    m += z[i];
  }
  m /= n;
  var e0 = 0.0;
  for (var i = 0; i < n; i++) {
    z[i] -= m;
    e0 += z[i] * z[i];
  }
  if (e0 <= 1e-9) return const PpgCheck(false, 0, 0, 0);
  final ac = math.sqrt(e0 / n);
  final lo = (rate * 0.33).round(), hi = math.min((rate * 1.5).round(), n ~/ 2);
  if (hi <= lo + 2) return null;
  final rs = <double>[];
  var best = -1.0;
  for (var l = lo; l <= hi; l++) {
    var s = 0.0;
    for (var i = 0; i < n - l; i++) {
      s += z[i] * z[i + l];
    }
    final r = s / e0 * (n / (n - l));
    rs.add(r);
    if (r > best) best = r;
  }
  // یەکەم لوتکە ≥ ٨٠٪ ی باشترین = ماوەی ڕاستەقینەی لێدان
  var bl = lo;
  for (var k = 1; k < rs.length - 1; k++) {
    if (rs[k] >= 0.8 * best && rs[k] >= rs[k - 1] && rs[k] >= rs[k + 1]) {
      bl = lo + k;
      break;
    }
  }
  final bpm = 60 * rate / bl;
  final pulse = ac >= kMinAc && best >= kMinAcf && bpm >= 40 && bpm <= 180;
  return PpgCheck(pulse, ac, best.clamp(0.0, 1.0).toDouble(), bpm);
}

/// ڕاگری دۆخی «لە دەستە»
class WearDetector extends ChangeNotifier {
  WearDetector({
    required this.isReady,
    required this.isBusy,
    required this.samplePpg,
    required this.liveOn,
    required this.onChanged,
  });

  final bool Function() isReady; // BLE ئامادەیە؟
  final bool Function() isBusy; // ECG یان پێوانەی تر بەکاردێت؟
  /// ٦–٨ چرکە شەپۆلی PPG وەردەگرێت: (نموونەکان، نموونە/چرکە) یان null
  final Future<(List<double>, double)?> Function() samplePpg;
  final Future<void> Function() liveOn; // داوای پاکێتی زیندوو
  final void Function(WearState) onChanged;

  // ئەستانەکان
  static const double coldTemp = 30.0; // °C
  static const Duration noLifeAfter = Duration(seconds: 15);
  static const Duration probeEveryWorn = Duration(minutes: 2);
  static const Duration probeEveryOff = Duration(seconds: 20);
  static const Duration reprobeAfterNeg = Duration(seconds: 6);
  static const int offNeedsNegatives = 2;

  WearState state = WearState.unknown;
  bool get isOff => state == WearState.off;

  Timer? _timer;
  bool _probing = false, _charging = false;
  int _neg = 0;
  DateTime _lastProbe = DateTime.fromMillisecondsSinceEpoch(0);
  DateTime? _lastLive, _noLifeSince;
  bool _life = false, _cold = false;
  bool _lifeAfterOff = false;
  PpgCheck? lastCheck;

  void start() {
    stop();
    state = WearState.unknown;
    _neg = 0;
    _noLifeSince = null;
    _lastLive = null;
    _lastProbe = DateTime.fromMillisecondsSinceEpoch(0); // یەکەم پشکنین دەستبەجێ
    unawaited(liveOn().catchError((_) {}));
    _timer = Timer.periodic(const Duration(seconds: 3), (_) => _tick());
    _tick();
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    _probing = false;
    if (state != WearState.unknown) _set(WearState.unknown, notify: false);
  }

  // ── بەڵگەکان ──
  void onBattery({required bool charging}) {
    if (charging == _charging) return;
    _charging = charging;
    if (charging) {
      _neg = offNeedsNegatives;
      _set(WearState.off);
    } else {
      _lastProbe = DateTime.fromMillisecondsSinceEpoch(0); // لە شەحن دەرچوو ← پشکنین
      _tick();
    }
  }

  void onLive({required int hr, required int spo2, required double tempC}) {
    final now = DateTime.now();
    _lastLive = now;
    _cold = tempC > 0 && tempC < coldTemp;
    _life = (hr > 0 || spo2 > 0) && !_cold;
    if (kDebugMode) debugPrint('WEAR live hr=$hr spo2=$spo2 temp=$tempC life=$_life state=$state');
    if (_life) {
      _noLifeSince = null;
      if (state == WearState.off && !_charging) _lifeAfterOff = true; // دەبێت بە PPG پشتڕاست بکرێتەوە
    } else {
      _noLifeSince ??= now;
    }
    if (_lifeAfterOff || (_noLifeSince != null && now.difference(_noLifeSince!) >= noLifeAfter && state != WearState.off)) {
      _tick();
    }
  }

  // ── خولی سەرەکی ──
  void _tick() {
    if (!isReady() || _charging) return;
    final now = DateTime.now();
    final ll = _lastLive;
    if (ll == null || now.difference(ll) > const Duration(seconds: 25)) {
      unawaited(liveOn().catchError((_) {}));
    }
    if (_probing || isBusy()) return;
    final since = now.difference(_lastProbe);
    final noLife = _noLifeSince != null && now.difference(_noLifeSince!) >= noLifeAfter;
    final every = state == WearState.off ? probeEveryOff : probeEveryWorn;
    final wantNow = state == WearState.unknown || _lifeAfterOff || (noLife && state == WearState.worn) || (_neg > 0 && _neg < offNeedsNegatives && since >= reprobeAfterNeg);
    if (wantNow || since >= every) unawaited(probe());
  }

  /// یەک پشکنینی PPG (٦–٨ چرکە) و تێکەڵکردنی ئەنجامەکەی
  Future<void> probe() async {
    if (!isReady() || _probing || isBusy() || _charging) return;
    _probing = true;
    _lastProbe = DateTime.now();
    _lifeAfterOff = false;
    try {
      final got = await samplePpg();
      if (!isReady()) return;
      if (got == null) return; // نەتوانرا (ECG بەکارهاتبوو…) — نادیار
      final chk = analyzePpg(got.$1, got.$2);
      lastCheck = chk;
      if (kDebugMode) debugPrint('WEAR probe n=${got.$1.length} rate=${got.$2.toStringAsFixed(1)} → $chk');
      if (chk == null) return; // داتای کەم: بڕیار نادرێت
      if (chk.pulse) {
        _neg = 0;
        _noLifeSince = null;
        _set(WearState.worn);
      } else {
        _neg++;
        // دوو نەرێنی لە دووی یەک، یان یەک نەرێنی + هیچ نیشانەی ژیان (hr/SpO₂/گەرمی) = لە دەست نییە.
        // یەک نەرێنی تەنها (لەگەڵ نیشانەی ژیان) ← بڕیار نادرێت و دوای ٦ چرکە دووبارە دەپشکنرێت (جووڵەی زۆر).
        if (_neg >= offNeedsNegatives || !_life) _set(WearState.off);
      }
    } catch (e) {
      if (kDebugMode) debugPrint('WEAR probe error: $e');
    } finally {
      _probing = false;
    }
  }

  void _set(WearState s, {bool notify = true}) {
    if (s == state) return;
    state = s;
    if (notify) {
      onChanged(s);
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
