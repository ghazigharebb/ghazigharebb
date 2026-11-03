// VEX Health — «Band لە دەستە یان نا» v3 (VEX Skin Sense)
//
// بۆچی v3؟ v2 هەر ٢ خولەک جارێک دەیپشکنی و شەپۆلی 0x07 ی بەکاردەهێنا، کە لە V8 دا شەپۆلی ECG ـە
// (تەنها کاتێک پەنجە لەسەر Band ـە کار دەکات)، نەک PPG ی ڕووناکی. بۆیە لابردنی Band چەند خولەکی دەخایاند.
//
// v3 چوار بەڵگە پێکەوە بەکاردەهێنێت (هەموو لە SDK ی J-STYLE V8):
//   ١) دڵی ڕووناکی (optical) ی بەردەوام: فرمانی 0x28 (جۆری ٢ = دڵ). Band هەر چرکەیەک دڵ دەنێرێت؛
//      کاتێک لەسەر پێست نییە، ئەلگۆریتمی خۆی 0 دەنێرێت یان ناردن ڕادەگرێت.  ← بەڵگەی سەرەکی (هەردوو ئاراستە)
//   ٢) پلەی گەرمیی پێست (NTC، فرمانی 0x14) هەر ٢ چرکە: لەسەر پێست ~٣٢–٣٥°C؛ لابردن ← دابەزین.  ← خێراکەر
//   ٣) شەحن (0x13): لەسەر شەحنەرە = لە دەست نییە (یەکسەر).
//   ٤) هەنگاو (0x09): هەنگاوی نوێ = دەست دەجووڵێت ← لە کاتی ڕۆیشتندا «لە دەست نییە» ی هەڵە ڕێگری دەکرێت.
//
// یاساکان (WearConfig):
//   • لە دەستە  ← یەکەم دڵی دروست (35–220) لە پێوانەی ڕووناکیدا (دوای دانانی ~٣–٥ چرکە).
//   • لە دەست نییە ← ٥ چرکە بێ دڵی دروست لە کاتێکدا Band 0 دەنێرێت (لە کاتی ڕۆیشتن ١٠ چرکە)،
//                    یان Band هیچ نانێرێت (دووبارە دەست پێدەکرێتەوە و ئینجا بڕیار دەدرێت)،
//                    یان گەرمی بە ڕوونی دابەزی + ٣ چرکە بێ دڵ، یان شەحن.
//   • هیچ کات لە ٣ چرکەی یەکەمی کەمبوونەوەیەکی کورتدا ناگۆڕێت ← لە دەستدا «پچڕان»ی درۆزن نییە.
//
// WearEngine لۆجیکی پاکە (بێ تایمەر، کات وەک پارامیتەر) بۆ ئەوەی بە تەواوی تاقی بکرێتەوە:
//   test/band_wear_test.dart
import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';

enum WearState { unknown, worn, off }

/// ئەستانەکانی بڕیار
class WearConfig {
  const WearConfig({
    this.minHr = 35,
    this.maxHr = 220,
    this.offAfter = const Duration(seconds: 5),
    this.offAfterMoving = const Duration(seconds: 10),
    this.movingWindow = const Duration(seconds: 8),
    this.warmup = const Duration(seconds: 9),
    this.stallAfter = const Duration(seconds: 3),
    this.silentOffAfter = const Duration(seconds: 7),
    this.confirmOn = const Duration(seconds: 5),
    this.tempOffAfter = const Duration(seconds: 3),
    this.tempDrop = 1.2,
    this.coldC = 27.0,
    this.skinMinC = 29.5,
  });

  final int minHr, maxHr;

  /// چەند چرکە بێ دڵی دروست (لە کاتێکدا Band 0 دەنێرێت) ← لە دەست نییە
  final Duration offAfter;

  /// هەمان، کاتێک لەم دواییانەدا هەنگاو هەبووە (جووڵە دڵی ڕووناکی تێک دەدات)
  final Duration offAfterMoving;
  final Duration movingWindow;

  /// دوای دەستپێکردنی پێوانە: Band چەند چرکەیەک 0 دەنێرێت تا دڵ دەدۆزێتەوە
  final Duration warmup;

  /// بێ هیچ پاکێتێک ← پێوانەکە دووبارە دەست پێبکرێتەوە
  final Duration stallAfter;

  /// ئەم ماوەیە هیچ پاکێتێک (لەگەڵ دووبارەکردنەوەش) ← لە دەست نییە
  final Duration silentOffAfter;

  /// «لە دەستە» = دوو دڵی دروست لەم ماوەیەدا (دڵی کۆنی ماوە لە Band هەڵە نادات)
  final Duration confirmOn;

  /// گەرمی دابەزی + ئەم ماوەیە بێ دڵ ← لە دەست نییە
  final Duration tempOffAfter;

  /// چەند پلە لە خوار گەرمیی پێستی فێربوو (لەسەر دەست)
  final double tempDrop;

  /// لە خوار ئەمە = بە دڵنیایی لەسەر پێست نییە
  final double coldC;

  /// لە سەر ئەمە = دەکرێت لەسەر پێست بێت (بۆ فێربوونی گەرمیی پێست)
  final double skinMinC;
}

/// تۆماری بڕیار (بۆ پەڕەی Band و ناردنی لۆگ)
class WearEvent {
  WearEvent(this.at, this.text);
  final DateTime at;
  final String text;
  @override
  String toString() {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(at.hour)}:${two(at.minute)}:${two(at.second)} $text';
  }
}

/// مێشکی بڕیار: بێ تایمەر، هەموو کاتەکان لە دەرەوە دێن (بۆ تاقیکردنەوە)
class WearEngine {
  WearEngine({this.cfg = const WearConfig()});

  final WearConfig cfg;

  WearState state = WearState.unknown;
  String reason = '';

  // پێوانەی ڕووناکی
  bool sessionOn = false;
  DateTime? _sessionAt; // کاتی دەستپێکردنی پێوانە (بۆ ماوەی گەرمبوونەوە)
  DateTime? _lastArm; // دوایین ناردنی فرمانی دەستپێک
  DateTime? _lastPacket; // دوایین پاکێتی 0x28
  DateTime? _lastValid; // دوایین دڵی دروست
  DateTime? _prevValid; // پێش ئەوە (بۆ پشتڕاستکردنەوەی «لە دەستە»)
  DateTime? _zeroSince; // یەکەم 0 ی دوای دوایین دڵی دروست
  int? lastHr;
  int rearms = 0;

  // گەرمی
  double? lastTemp;
  double? skinTemp; // گەرمیی پێستی فێربوو (تەنها کاتێک لە دەستە و دڵ هەیە)
  DateTime? _coolSince;

  // هەنگاو / شەحن
  int? _steps;
  DateTime? _lastStep;
  bool charging = false;

  final ListQueue<WearEvent> log = ListQueue();

  bool _valid(int hr) => hr >= cfg.minHr && hr <= cfg.maxHr;

  void _log(DateTime t, String s) {
    log.addLast(WearEvent(t, s));
    while (log.length > 80) {
      log.removeFirst();
    }
  }

  WearState _set(WearState s, DateTime t, String why) {
    if (s == state) return state;
    state = s;
    reason = why;
    if (s == WearState.off) {
      _zeroSince = null;
      _coolSince = null;
    }
    _log(t, '→ ${s.name} ($why)');
    return state;
  }

  // ───────── بەڵگەکان ─────────

  /// پێوانەی ڕووناکی دەستی پێکرد (یان دووبارە)
  void sessionStarted(DateTime t) {
    sessionOn = true;
    _sessionAt = t;
    _lastArm = t;
    _lastPacket = null;
    _zeroSince = null;
    _prevValid = null;
    _log(t, 'session start');
  }

  void sessionStopped(DateTime t) {
    if (!sessionOn) return;
    sessionOn = false;
    _zeroSince = null;
    _log(t, 'session stop');
  }

  /// هەر پاکێتێکی 0x28 ی پێوانەی دڵ (hr = 0 کاتێک Band دڵ نادۆزێتەوە)
  WearState hr(int bpm, DateTime t) {
    _lastPacket = t;
    if (charging) return state;
    if (_valid(bpm)) {
      lastHr = bpm;
      _prevValid = _lastValid;
      _lastValid = t;
      _zeroSince = null;
      _coolSince = null;
      if (state == WearState.worn) return state;
      // لە دەست نییە / نادیار ← دوو دڵی دروست بە دوای یەکدا (یەکەمیان لەوانەیە بەهای کۆنی Band بێت)
      final pv = _prevValid;
      if (pv != null && t.difference(pv) <= cfg.confirmOn && t.isAfter(pv)) {
        return _set(WearState.worn, t, 'heart $bpm');
      }
      return state;
    }
    _prevValid = null;
    _zeroSince ??= t;
    return tick(t);
  }

  /// پلەی گەرمیی NTC (°C)
  WearState temp(double c, DateTime t) {
    if (c <= 0 || c > 50) return state;
    lastTemp = c;
    // فێربوون: تەنها کاتێک دڵی دروستی نوێ هەیە (= بە دڵنیایی لەسەر پێستە)
    // (تەنها گۆڕانی هێواش فێر دەبێت؛ دابەزینی خێرا = لابردن، فێری نابێت)
    final fresh = _lastValid != null && t.difference(_lastValid!) <= const Duration(milliseconds: 1500);
    final s0 = skinTemp;
    if (state == WearState.worn && fresh && c >= cfg.skinMinC && (s0 == null || (c - s0).abs() <= 0.6)) {
      skinTemp = s0 == null ? c : s0 * 0.8 + c * 0.2;
    }
    final s = skinTemp;
    final cool = c < cfg.coldC || (s != null && c <= s - cfg.tempDrop);
    if (cool) {
      _coolSince ??= t;
    } else {
      _coolSince = null;
    }
    return tick(t);
  }

  /// کۆی هەنگاوی ڕاستەوخۆ (0x09)
  void steps(int total, DateTime t) {
    final p = _steps;
    _steps = total;
    if (p != null && total > p) _lastStep = t;
  }

  WearState setCharging(bool on, DateTime t) {
    if (on == charging) return state;
    charging = on;
    _log(t, on ? 'charging' : 'unplugged');
    if (on) return _set(WearState.off, t, 'charging');
    // لە شەحن دەرچوو: نادیار تا دڵ دەدۆزرێتەوە (پێوانە لە سەرەتاوە، بە ماوەی گەرمبوونەوەوە)
    _zeroSince = null;
    _lastValid = null;
    _prevValid = null;
    if (sessionOn) {
      _sessionAt = t;
      _lastArm = t;
      _lastPacket = null;
    }
    return _set(WearState.unknown, t, 'unplugged');
  }

  /// پێویستە پێوانەکە دووبارە دەست پێبکرێتەوە؟ (Band هیچ نانێرێت)
  bool needsRearm(DateTime t) {
    if (!sessionOn || charging) return false;
    DateTime? last = _lastPacket;
    final a = _lastArm;
    if (last == null || (a != null && a.isAfter(last))) last = a;
    return last != null && t.difference(last) >= cfg.stallAfter;
  }

  void rearmed(DateTime t) {
    rearms++;
    _lastArm = t;
    _log(t, 'rearm');
  }

  /// هەڵسەنگاندن (هەر چرکەیەک)
  WearState tick(DateTime t) {
    if (charging) return _set(WearState.off, t, 'charging');
    if (!sessionOn) {
      // بێ پێوانەی ڕووناکی (لە پاشبنەما): تەنها گەرمیی زۆر سارد بڕیار دەدات
      if (state != WearState.off && lastTemp != null && lastTemp! < cfg.coldC && _coolSince != null &&
          t.difference(_coolSince!) >= cfg.offAfter) {
        return _set(WearState.off, t, 'cold ${lastTemp!.toStringAsFixed(1)}°C');
      }
      return state;
    }
    if (state == WearState.off) return state; // تەنها دڵی دروست دەیگەڕێنێتەوە
    final since = _sessionAt!;
    final inWarmup = t.difference(since) < cfg.warmup;
    final lastV = _lastValid;
    final moving = _lastStep != null && t.difference(_lastStep!) <= cfg.movingWindow;

    // ١) گەرمیی پێست بە ڕوونی دابەزی (بەراورد بە گەرمیی فێربووی پێستی خۆت) + چەند چرکە بێ دڵ
    final cs = _coolSince;
    if (!moving && cs != null && skinTemp != null && t.difference(cs) >= cfg.tempOffAfter) {
      final noHr = lastV == null || t.difference(lastV) >= cfg.tempOffAfter;
      final zeroOrSilent = _zeroSince != null || t.difference(_lastPacket ?? since) >= cfg.tempOffAfter;
      if (noHr && zeroOrSilent) return _set(WearState.off, t, 'skin cooled ${lastTemp?.toStringAsFixed(1)}°C');
    }

    // ٢) Band 0 دەنێرێت: X چرکە بێ دڵی دروست
    final z = _zeroSince;
    if (z != null) {
      final need = moving ? cfg.offAfterMoving : cfg.offAfter;
      if (state == WearState.worn) {
        if (t.difference(z) >= need) return _set(WearState.off, t, 'no heart ${need.inSeconds}s');
      } else if (!inWarmup && (lastV == null || t.difference(lastV) >= need)) {
        return _set(WearState.off, t, 'no heart after start');
      }
    }

    // ٣) Band هیچ نانێرێت (دوای دووبارەکردنەوەش)
    final silentFor = t.difference(_lastPacket ?? since);
    if (rearms > 0 && silentFor >= cfg.silentOffAfter) {
      final noHr = lastV == null || t.difference(lastV) >= cfg.silentOffAfter;
      if (noHr && (state == WearState.worn || !inWarmup)) return _set(WearState.off, t, 'band silent');
    }

    // ٤) نادیار و زۆر سارد (بێ دڵ)
    if (state == WearState.unknown && !inWarmup && lastTemp != null && lastTemp! < cfg.coldC && (lastV == null || t.difference(lastV) >= cfg.offAfter)) {
      return _set(WearState.off, t, 'cold ${lastTemp!.toStringAsFixed(1)}°C');
    }
    return state;
  }
}

/// ڕاگری دۆخی «لە دەستە» — تایمەر و فرمانەکانی Band (لەسەر WearEngine)
class WearDetector extends ChangeNotifier {
  WearDetector({
    required this.isReady,
    required this.isBusy,
    required this.startSession,
    required this.stopSession,
    required this.readTemp,
    required this.readBattery,
    required this.onChanged,
    this.cfg = const WearConfig(),
  }) : engine = WearEngine(cfg: cfg);

  final bool Function() isReady; // BLE ئامادەیە؟
  final bool Function() isBusy; // ECG / پێوانەی دەستی لە کاردایە؟
  final Future<void> Function() startSession; // 0x28 دڵ، دەستپێک
  final Future<void> Function() stopSession; // 0x28 دڵ، ڕاگرتن
  final Future<void> Function() readTemp; // 0x14
  final Future<void> Function() readBattery; // 0x13
  final void Function(WearState) onChanged;
  final WearConfig cfg;
  final WearEngine engine;

  /// پێوانەی ڕووناکی بەردەوام تەنها کاتێک ئەپ لەسەر شاشەیە (باتری)
  bool foreground = true;

  /// ماوەی پشکنینی کورت لە پاشبنەما
  static const Duration backgroundProbeEvery = Duration(seconds: 60);
  static const Duration backgroundProbeMax = Duration(seconds: 14);

  /// پێوانەی ڕووناکی هەر ئەوەندە جارێک نوێ دەکرێتەوە (Band ـی V8 تا 65535 چرکە قبوڵ دەکات)
  static const int sessionSeconds = 3600;
  static const Duration sessionRenew = Duration(minutes: 50);

  WearState get state => engine.state;
  bool get isOff => engine.state == WearState.off;
  bool get isWorn => engine.state == WearState.worn;
  bool get checking => engine.state == WearState.unknown;

  Timer? _timer;
  int _tickN = 0;
  bool _arming = false, _paused = false;
  DateTime? _armedAt, _probeAt, _lastProbe;

  void start() {
    stop();
    final now = DateTime.now();
    engine.state = WearState.unknown;
    engine.reason = 'start';
    _tickN = 0;
    _lastProbe = null;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    unawaited(readBattery().catchError((_) {}));
    unawaited(readTemp().catchError((_) {}));
    if (foreground) unawaited(_arm(now));
    _emit();
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    _armedAt = _probeAt = null;
    _paused = false;
    if (engine.sessionOn) {
      engine.sessionStopped(DateTime.now());
      if (isReady()) unawaited(stopSession().catchError((_) {}));
    }
    engine.state = WearState.unknown;
  }

  /// ئەپ چووە پاشبنەما / گەڕایەوە
  void setForeground(bool fg) {
    if (fg == foreground) return;
    foreground = fg;
    if (_timer == null) return;
    final now = DateTime.now();
    if (fg) {
      unawaited(readTemp().catchError((_) {}));
      if (!engine.sessionOn && !isBusy()) unawaited(_arm(now));
    } else {
      _lastProbe = now; // یەکەم پشکنینی پاشبنەما دوای ١ خولەک
      if (engine.sessionOn && _probeAt == null) unawaited(_disarm(now));
    }
  }

  // ───────── بەڵگە لە Band ـەوە ─────────
  void onHeart(int hr) {
    if (_paused || !engine.sessionOn) return;
    final now = DateTime.now();
    if (kDebugMode) debugPrint('WEAR hr=$hr state=${engine.state.name}');
    engine.hr(hr, now);
    _emit();
    // پشکنینی کورتی پاشبنەما: کە بڕیار درا، ڕایبگرە
    if (_probeAt != null && engine.state != WearState.unknown && hr > 0) unawaited(_disarm(now));
  }

  void onTemp(double c) {
    engine.temp(c, DateTime.now());
    _emit();
  }

  void onSteps(int total) => engine.steps(total, DateTime.now());

  void onBattery({required bool charging}) {
    final now = DateTime.now();
    final was = engine.charging;
    engine.setCharging(charging, now);
    if (was && !charging && isReady() && !isBusy() && !_paused) {
      if (engine.sessionOn) {
        unawaited(startSession().catchError((_) {})); // Band لە کاتی شەحن پێوانەکەی ڕاگرتووە
      } else if (foreground) {
        unawaited(_arm(now));
      }
    }
    _emit();
  }

  /// ECG / پێوانەی دەستی: پێوانەی ڕووناکی ڕادەوەستێت و دۆخ وەک خۆی دەمێنێت
  void pause() {
    if (_paused) return;
    _paused = true;
    if (engine.sessionOn) engine.sessionStopped(DateTime.now());
    _armedAt = _probeAt = null;
  }

  void resume() {
    if (!_paused) return;
    _paused = false;
    if (_timer != null && foreground && isReady()) unawaited(_arm(DateTime.now()));
  }

  // ───────── تایمەر ─────────
  void _tick() {
    if (!isReady()) return;
    _tickN++;
    final now = DateTime.now();
    final busy = isBusy() || _paused;
    // گەرمی: لەسەر شاشە هەر ٢ چرکە، پاشبنەما هەر ١٠ چرکە. باتری: ١٥ / ٦٠ چرکە
    if (!busy) {
      if (_tickN % (foreground ? 2 : 10) == 0) unawaited(readTemp().catchError((_) {}));
      if (_tickN % (foreground ? 15 : 60) == 0) unawaited(readBattery().catchError((_) {}));
    }
    if (busy) return;

    if (foreground) {
      if (!engine.sessionOn && !engine.charging) {
        unawaited(_arm(now));
      } else if (engine.sessionOn) {
        final a = _armedAt;
        if (engine.needsRearm(now) || (a != null && now.difference(a) >= sessionRenew)) {
          engine.rearmed(now);
          unawaited(_arm(now, rearm: true));
        }
      }
    } else {
      // پاشبنەما: پشکنینی کورت هەر خولەکێک
      final p = _probeAt;
      if (p != null) {
        if (engine.needsRearm(now)) {
          engine.rearmed(now);
          unawaited(_arm(now, rearm: true));
        }
        if (now.difference(p) >= backgroundProbeMax) unawaited(_disarm(now));
      } else if (!engine.charging && (_lastProbe == null || now.difference(_lastProbe!) >= backgroundProbeEvery)) {
        _lastProbe = now;
        _probeAt = now;
        unawaited(_arm(now));
      }
    }
    engine.tick(now);
    _emit();
  }

  Future<void> _arm(DateTime now, {bool rearm = false}) async {
    if (_arming || !isReady() || isBusy() || _paused) return;
    _arming = true;
    try {
      if (!rearm) engine.sessionStarted(now);
      _armedAt = now;
      await startSession();
    } catch (e) {
      if (kDebugMode) debugPrint('WEAR arm: $e');
    } finally {
      _arming = false;
    }
  }

  Future<void> _disarm(DateTime now) async {
    _probeAt = null;
    _armedAt = null;
    engine.sessionStopped(now);
    try {
      if (isReady()) await stopSession();
    } catch (_) {}
  }

  WearState _last = WearState.unknown;
  void _emit() {
    final s = engine.state;
    if (s != _last) {
      _last = s;
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
