// VEX Health — «Band لە دەستە یان نا» v4 (VEX Skin Sense v4 · PPG ی خاو)
//
// ڕێک هەمان لۆجیکی پەڕەی تاقیکردنەوە (tools/band_test/index.html · PpgWear) کە لەسەر Band ی ڕاستەقینە
// (JCV8B CB6164، ٢٠٢٦-١١-٠٣) تاقیکرایەوە و سەرکەوت.
//
// بۆچی v4؟ لۆگی Band ی ڕاستەقینە نیشانی دا:
//   • دڵی Band (0x28 / بایتی ٢١ ی 0x09) درۆ دەکات: لەسەر مێز ٣٠ چرکە «59» یان «76» ی جێگیر دەنێرێت.
//   • گەرمی زۆر هێواشە (~١° لە ٣٠ چرکەدا) و لە کاتی پێوانەی دڵدا نوێ نابێتەوە.
//   • شەپۆلی 0x07 (HRV) ٣٦ چرکە دوای دەستپێک دێت ← بۆ ٥ چرکە بەکار نایەت.
//   • هەستەوەری ڕووناکیی خاو (فرمانی 0x78، BleSDK.ppgWithMode) ← ڕاستەقینە و خێرا:
//       Band هەر چرکەیەک پاکێتی 0x3a دەنێرێت: ٣ بایت سەر + ٥٠ نموونە (٤ بایت، big-endian) = ٥٠ Hz.
//       لەسەر پێست: ئاستێکی جێگیر (~١–٣ ملیۆن) و گۆڕانی بچووک (<٠٫٥٪ لە نێوان دوو نموونەدا).
//       لابردن: ١–٢ پاکێتی شێواو (تێربوون / پچڕان)، پاشان Band خۆی ناردن ڕادەگرێت.
//       لەدەستکردنەوە: Band خۆی دەست پێدەکاتەوە (~٣ چرکە)، ١–٣ پاکێتی شێواو، پاشان پاکێتی پاک.
//
// یاساکان (WearConfig — هەمان ژمارەکانی PW لە پەڕەی تاقیکردنەوە):
//   • هەر پاکێت ← ١٥ نموونەی کۆتایی (٠٫٣ چرکە) دەپشکنرێت:
//       پاک (clean)  = هەموو لە نێوان 300,000 و 10,000,000 + گەورەترین گۆڕان ÷ ناوەند < 0.02
//       شێواو (chaos) = لە دەرەوەی ئەو سنوورە، یان گۆڕان > 0.05 ;  نێوان (mid) = هیچ ناگۆڕێت
//   • لە دەستە     ← یەک پاکێتی پاک.
//   • لە دەست نییە ← Band بێدەنگ بوو: ١٫٦ چرکە دوای پاکێتی شێواو / ٣ چرکە دوای پاکێتی پاک،
//                    یان ٣ پاکێتی شێواو بە دوای یەکدا، یان ٣٫٥ چرکە هیچ پاکێتێک لە سەرەتاوە، یان شەحن.
//   • کاتێک بێدەنگە (≥١٫٥ چرکە) فرمانی 0x78 هەر ٤ چرکە دووبارە دەنێردرێت: ئەگەر لە دەستە دەست پێدەکاتەوە.
//
// تێبینی: لە دۆخی 0x78 دا دڵی خۆی Band (بایتی ٢١) = 0. بۆیە دڵی ڕاستەوخۆ لە هەمان نموونەکانی PPG
// دەژمێردرێت (PpgHeart: autocorrelation ی ٦–٨ چرکە) و تەنها کاتێک دڵنیایە نیشان دەدرێت.
//
// WearEngine لۆجیکی پاکە (بێ تایمەر، کات وەک پارامیتەر) ← test/band_wear_test.dart
// (لەگەڵ پاکێتە ڕاستەقینەکانی Band: test/fixtures/ppg_real_20261103.dart).
import 'dart:async';
import 'dart:collection';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';

enum WearState { unknown, worn, off }

enum PpgKind { clean, mid, chaos }

/// ئەستانەکانی بڕیار (= PW لە tools/band_test/index.html)
class WearConfig {
  const WearConfig({
    this.win = 15,
    this.minDc = 300000,
    this.maxDc = 10000000,
    this.cleanRel = 0.02,
    this.chaosRel = 0.05,
    this.chaosRun = 3,
    this.gapAfterChaos = const Duration(milliseconds: 1600),
    this.gapAfterClean = const Duration(milliseconds: 3000),
    this.noDataOff = const Duration(milliseconds: 3500),
    this.resendAfterSilent = const Duration(milliseconds: 1500),
    this.resendEvery = const Duration(milliseconds: 4000),
    this.tickEvery = const Duration(milliseconds: 250),
  });

  /// چەند نموونەی کۆتایی هەر پاکێتێک دەپشکنرێت (١٥ = ٠٫٣ چرکە)
  final int win;

  /// سنووری ئاستی ڕووناکی لەسەر پێست
  final int minDc, maxDc;

  /// گەورەترین گۆڕانی نێوان دوو نموونە ÷ ناوەند: لە خوار = پاک، لە سەر = شێواو
  final double cleanRel, chaosRel;

  /// ئەوەندە پاکێتی شێواو بە دوای یەکدا ← لە دەست نییە
  final int chaosRun;

  /// Band بێدەنگ بوو دوای پاکێتی شێواو / پاک ← لە دەست نییە
  final Duration gapAfterChaos, gapAfterClean;

  /// لە دەستپێکەوە هیچ پاکێتێک نەهات ← لە دەست نییە
  final Duration noDataOff;

  /// بێدەنگ ← فرمانی PPG دووبارە بنێرە (هەر resendEvery جارێک)
  final Duration resendAfterSilent, resendEvery;

  /// ماوەی هەڵسەنگاندن
  final Duration tickEvery;
}

/// ئەنجامی پشکنینی یەک پاکێت
class PpgCheck {
  const PpgCheck(this.kind, this.rel, this.med, this.min, this.max);
  final PpgKind kind;
  final double rel;
  final int med, min, max;
}

/// پاکێتی 0x3a ی PPG ی خاو
class Ppg {
  static const int cmdStart = 0x78; // BleSDK.ppgWithMode
  static const int cmdData = 0x3a; // DeviceConst.Bloodsugar_data

  /// ئایا ئەم پاکێتە PPG ی خاوە؟
  static bool isPacket(Uint8List v) => v.length >= 43 && v[0] == cmdData;

  /// نموونەکان: لە بایتی ٣ ەوە، هەر ٤ بایت big-endian
  static List<int> samples(Uint8List v) {
    final o = <int>[];
    for (var i = 3; i + 3 < v.length; i += 4) {
      o.add((v[i] << 24) + (v[i + 1] << 16) + (v[i + 2] << 8) + v[i + 3]);
    }
    return o;
  }

  /// پاک / نێوان / شێواو (= ppgClass لە پەڕەی تاقیکردنەوە)
  static PpgCheck classify(List<int> s, [WearConfig c = const WearConfig()]) {
    final h = s.length > c.win ? s.sublist(s.length - c.win) : s;
    if (h.length < 8) return const PpgCheck(PpgKind.mid, 0, 0, 0, 0);
    final so = [...h]..sort();
    final med = so[so.length >> 1], mn = so.first, mx = so.last;
    var md = 0;
    for (var i = 1; i < h.length; i++) {
      final d = (h[i] - h[i - 1]).abs();
      if (d > md) md = d;
    }
    final rel = md / (med > 1 ? med : 1);
    final PpgKind k;
    if (mn < c.minDc || mx > c.maxDc) {
      k = PpgKind.chaos;
    } else if (rel < c.cleanRel) {
      k = PpgKind.clean;
    } else if (rel > c.chaosRel) {
      k = PpgKind.chaos;
    } else {
      k = PpgKind.mid;
    }
    return PpgCheck(k, rel, med, mn, mx);
  }
}

/// دڵ لە PPG ی خاو (autocorrelation). تەنها کاتێک دڵنیایە ژمارە دەدات.
class PpgHeart {
  PpgHeart({this.fs = 50, this.minSamples = 250, this.maxSamples = 400, this.minPeak = 0.3});

  final double fs;
  final int minSamples, maxSamples;
  final double minPeak;
  final List<double> _buf = [];
  final List<int> _last = [];

  /// دوایین دڵی دڵنیا (bpm) یان null
  int? bpm;

  void reset() {
    _buf.clear();
    _last.clear();
    bpm = null;
  }

  /// پاکێتێکی پاک/نێوان لە کاتی «لە دەستە»
  int? add(List<int> s) {
    for (final x in s) {
      _buf.add(x.toDouble());
    }
    if (_buf.length > maxSamples) _buf.removeRange(0, _buf.length - maxSamples);
    if (_buf.length < minSamples) return bpm;
    final e = estimate(_buf, fs: fs, minPeak: minPeak);
    if (e != null) {
      _last.add(e);
      if (_last.length > 3) _last.removeAt(0);
      final so = [..._last]..sort();
      bpm = so[so.length >> 1];
    }
    return bpm;
  }

  /// ژمێرەری پاک (بۆ تاقیکردنەوە): ٤٠–١٨٧ bpm
  static int? estimate(List<double> x, {double fs = 50, double minPeak = 0.3}) {
    const k = 50, h = k ~/ 2;
    final n = x.length;
    if (n < k + 40) return null;
    final ps = List<double>.filled(n + 1, 0);
    for (var i = 0; i < n; i++) {
      ps[i + 1] = ps[i] + x[i];
    }
    final y = <double>[for (var i = h; i < n - h; i++) x[i] - (ps[i + h] - ps[i - h]) / k];
    final z = <double>[];
    for (var i = 2; i < y.length - 2; i++) {
      z.add((y[i - 2] + y[i - 1] + y[i] + y[i + 1] + y[i + 2]) / 5);
    }
    if (z.length < 80) return null;
    final m = z.reduce((a, b) => a + b) / z.length;
    for (var i = 0; i < z.length; i++) {
      z[i] -= m;
    }
    var a0 = 0.0;
    for (final v in z) {
      a0 += v * v;
    }
    if (a0 <= 0) return null;
    double ac(int l) {
      var s = 0.0;
      for (var i = 0; i + l < z.length; i++) {
        s += z[i] * z[i + l];
      }
      return s / a0;
    }

    final lo = (fs * 60 / 187).round(), hi = (fs * 60 / 40).round();
    final a = <int, double>{for (var l = lo - 1; l <= hi + 1; l++) l: ac(l)};
    int? best;
    for (var l = lo; l <= hi; l++) {
      if (a[l]! >= a[l - 1]! && a[l]! >= a[l + 1]! && (best == null || a[l]! > a[best]!)) best = l;
    }
    if (best == null || a[best]! < minPeak) return null;
    final p = a[best - 1]!, q = a[best]!, r = a[best + 1]!;
    final d = p - 2 * q + r;
    final off = d != 0 ? 0.5 * (p - r) / d : 0.0;
    return (60 * fs / (best + off)).round();
  }
}

/// تۆماری بڕیار (بۆ پەڕەی Band و ناردنی لۆگ)
class WearEvent {
  WearEvent(this.at, this.text);
  final DateTime at;
  final String text;
  @override
  String toString() {
    String two(int v) => v.toString().padLeft(2, '0');
    final ms = (at.millisecond ~/ 100).toString();
    return '${two(at.hour)}:${two(at.minute)}:${two(at.second)}.$ms $text';
  }
}

/// مێشکی بڕیار (= class PpgWear لە پەڕەی تاقیکردنەوە): بێ تایمەر، هەموو کاتەکان لە دەرەوە دێن
class WearEngine {
  WearEngine({this.cfg = const WearConfig()});

  final WearConfig cfg;

  WearState state = WearState.unknown;
  String reason = '';
  DateTime? changedAt;

  DateTime? _start; // دەستپێکی چاودێری (یان دوای شەحن / ECG)
  DateTime? _last; // دوایین پاکێتی PPG
  PpgKind? lastKind;
  PpgCheck? lastCheck;
  int chaos = 0;
  int packets = 0;

  // زانیاری زیادە (نیشاندان)
  bool charging = false;
  double? lastTemp;
  final PpgHeart heart = PpgHeart();
  int? get lastHr => state == WearState.worn ? heart.bpm : null;

  final ListQueue<WearEvent> log = ListQueue();

  void _log(DateTime t, String s) {
    log.addLast(WearEvent(t, s));
    while (log.length > 600) {
      log.removeFirst();
    }
  }

  WearState _set(WearState s, DateTime t, String why) {
    if (s == state) return state;
    state = s;
    reason = why;
    changedAt = t;
    if (s != WearState.worn) heart.reset();
    _log(t, '→ ${s.name} ($why)');
    return state;
  }

  /// دەستپێکی چاودێری (پەیوەستبوون / دوای ECG). دۆخ وەک خۆی دەمێنێت.
  void begin(DateTime t) {
    _start = t;
    _last = null;
    lastKind = null;
    chaos = 0;
    _log(t, 'begin');
  }

  /// چاودێری ڕاگیرا (پچڕان)
  void end() {
    _start = null;
    _last = null;
    lastKind = null;
    chaos = 0;
  }

  bool get running => _start != null;

  /// هەر پاکێتێکی 0x3a
  PpgCheck packet(List<int> samples, DateTime t) {
    final r = Ppg.classify(samples, cfg);
    _last = t;
    lastKind = r.kind;
    lastCheck = r;
    packets++;
    if (charging) return r;
    switch (r.kind) {
      case PpgKind.clean:
        chaos = 0;
        _set(WearState.worn, t, 'ppg skin');
        heart.add(samples);
      case PpgKind.chaos:
        chaos++;
        heart.reset();
        if (chaos >= cfg.chaosRun) _set(WearState.off, t, 'ppg chaos x$chaos');
      case PpgKind.mid:
        if (state == WearState.worn) heart.add(samples);
    }
    return r;
  }

  /// هەڵسەنگاندن (هەر ٢٥٠ ms)
  WearState tick(DateTime t) {
    if (charging) return _set(WearState.off, t, 'charging');
    final s = _start;
    if (s == null) return state;
    final l = _last;
    if (l == null) {
      if (t.difference(s) >= cfg.noDataOff) _set(WearState.off, t, 'no ppg');
      return state;
    }
    final gap = t.difference(l);
    final lim = lastKind == PpgKind.clean ? cfg.gapAfterClean : cfg.gapAfterChaos;
    if (gap >= lim) _set(WearState.off, t, 'ppg stopped ${(gap.inMilliseconds / 1000).toStringAsFixed(1)}s');
    return state;
  }

  /// چەندە Band بێدەنگە
  Duration silentFor(DateTime t) {
    final l = _last ?? _start;
    return l == null ? Duration.zero : t.difference(l);
  }

  /// شەحن (0x13): لەسەر شەحنەر = لە دەست نییە. دەرچوون ← دووبارە دەپشکنرێت.
  WearState setCharging(bool on, DateTime t) {
    if (on == charging) return state;
    charging = on;
    _log(t, on ? 'charging' : 'unplugged');
    if (on) return _set(WearState.off, t, 'charging');
    if (_start != null) begin(t);
    return state;
  }

  /// گەرمیی پێست (تەنها نیشاندان)
  void temp(double c) {
    if (c > 0 && c <= 50) lastTemp = c;
  }
}

/// ڕاگری دۆخی «لە دەستە» — تایمەر و فرمانەکانی Band (لەسەر WearEngine)
class WearDetector extends ChangeNotifier {
  WearDetector({
    required this.isReady,
    required this.isBusy,
    required this.ppgOn,
    required this.ppgOff,
    required this.readBattery,
    required this.onChanged,
    this.cfg = const WearConfig(),
  }) : engine = WearEngine(cfg: cfg);

  final bool Function() isReady; // BLE ئامادەیە؟
  final bool Function() isBusy; // هاوکاتکردنی مێژوو لە کاردایە؟
  final Future<void> Function() ppgOn; // 0x78 mode 1
  final Future<void> Function() ppgOff; // 0x78 mode 3 + 5
  final Future<void> Function() readBattery; // 0x13
  final void Function(WearState) onChanged;
  final WearConfig cfg;
  final WearEngine engine;

  /// ئەپ لەسەر شاشەیە؟ (تەنها بۆ زانیاری؛ چاودێری لە هەردوو حاڵەتدا بەردەوامە)
  bool foreground = true;

  WearState get state => engine.state;
  bool get isOff => engine.state == WearState.off;
  bool get isWorn => engine.state == WearState.worn;
  bool get checking => engine.state == WearState.unknown;

  Timer? _timer;
  int _tickN = 0;
  bool _paused = false, _wasBusy = false;
  DateTime? _lastSend;

  void start() {
    stop(sendOff: false);
    final now = DateTime.now();
    engine.state = WearState.unknown;
    engine.reason = 'start';
    engine.changedAt = now;
    engine.heart.reset();
    engine.begin(now);
    _tickN = 0;
    _timer = Timer.periodic(cfg.tickEvery, (_) => _tick());
    unawaited(readBattery().catchError((_) {}));
    _send(now);
    _emit();
  }

  void stop({bool sendOff = true}) {
    _timer?.cancel();
    _timer = null;
    _paused = false;
    engine.end();
    if (sendOff && isReady()) unawaited(ppgOff().catchError((_) {}));
    engine.state = WearState.unknown;
  }

  void setForeground(bool fg) => foreground = fg;

  // ───────── لە Band ـەوە ─────────
  /// پاکێتی خاوی 0x3a
  void onPacket(Uint8List v) {
    if (_paused || !engine.running) return;
    final now = DateTime.now();
    final r = engine.packet(Ppg.samples(v), now);
    if (kDebugMode) debugPrint('WEAR ppg ${r.kind.name} rel=${r.rel.toStringAsFixed(4)} state=${engine.state.name}');
    _emit();
  }

  void onTemp(double c) => engine.temp(c);

  void onBattery({required bool charging}) {
    engine.setCharging(charging, DateTime.now());
    _emit();
  }

  /// ECG / پێوانەی دەستی: PPG ی خاو ڕادەوەستێت، دۆخ وەک خۆی دەمێنێت
  Future<void> pause() async {
    if (_paused) return;
    _paused = true;
    if (isReady()) {
      try {
        await ppgOff();
      } catch (_) {}
    }
  }

  void resume() {
    if (!_paused) return;
    _paused = false;
    if (_timer == null || !isReady()) return;
    final now = DateTime.now();
    engine.begin(now);
    _send(now);
  }

  // ───────── تایمەر ─────────
  void _send(DateTime now) {
    _lastSend = now;
    unawaited(ppgOn().catchError((_) {}));
  }

  void _tick() {
    if (!isReady() || _paused) return;
    _tickN++;
    final now = DateTime.now();
    if (_tickN % 120 == 0) unawaited(readBattery().catchError((_) {})); // هەر ٣٠ چرکە
    final busy = isBusy();
    if (busy) {
      _wasBusy = true;
      return; // لە کاتی هاوکاتکردن بڕیار نادرێت
    }
    if (_wasBusy) {
      _wasBusy = false;
      engine.begin(now); // دوای هاوکاتکردن: دەستپێکی نوێ (بێ «لە دەست نییە» ی هەڵە)
      _send(now);
    }
    // Band بێدەنگە ← فرمانی PPG دووبارە (ئەگەر لە دەستە دەست پێدەکاتەوە، ئەگەر نا بێدەنگ دەمێنێت)
    final ls = _lastSend;
    if (engine.silentFor(now) >= cfg.resendAfterSilent && (ls == null || now.difference(ls) >= cfg.resendEvery)) _send(now);
    engine.tick(now);
    _emit();
  }

  WearState _lastEmit = WearState.unknown;
  void _emit() {
    final s = engine.state;
    if (s != _lastEmit) {
      _lastEmit = s;
      onChanged(s);
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
