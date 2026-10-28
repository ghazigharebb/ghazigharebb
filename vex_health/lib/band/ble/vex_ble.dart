// VEX Band — پەیوەستبوونی BLE ی ڕاستەقینە (flutter_blue_plus)
//
// بەکارهێنان:
//   await VexBand.I.init();                 // لە main دا (دوای BandState.I.load())
//   final found = await VexBand.I.scan();   // لیستی Band ـە نزیکەکان
//   await VexBand.I.connect(found.first);   // پەیوەستبوون + دانانی کات + باتری
//   await VexBand.I.syncAll();              // هەموو مێژوو
//   VexBand.I.measure(VexMeasure.heart);    // پێوانەی دەستی
//
// ⚠️ ئەم کۆدە لەسەر Band ی ڕاستەقینە و مۆبایل تاقی نەکراوەتەوە؛ بەپێی SDK نووسراوە.
import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../band_state.dart';
import 'vex_frame.dart';
import 'vex_parsers.dart';
import 'vex_wear.dart';

enum VexMeasure { heart, spo2, hrv }

class VexFound {
  final BluetoothDevice device;
  final String name;
  final int rssi;
  const VexFound(this.device, this.name, this.rssi);
}

class _Waiter {
  final int cmd;
  final Completer<List<VexMsg>> done = Completer();
  final List<VexMsg> got = [];
  Timer? quiet;
  _Waiter(this.cmd);
}

class VexBand extends ChangeNotifier {
  VexBand._();
  static final VexBand I = VexBand._();

  /// ناوی ئەو Band ـانەی لە سکاندا نیشان دەدرێن (بچووک). service ی fff0 هەمیشە قبوڵە.
  static List<String> nameHints = ['vex', 'v8', 'jstyle', 'j-style'];

  static const _kId = 'vex_band_id';

  BluetoothDevice? _dev;
  BluetoothCharacteristic? _wr;
  StreamSubscription? _nSub, _cSub;
  bool _ready = false;
  int mtu = 23;

  bool get linked => _ready;
  BluetoothDevice? get device => _dev;

  // ── دواین بەهاکان ──
  int? battery;
  bool charging = false;
  String? version, mac;
  VexRealtime? live;
  VexMeasureResult? lastMeasure;
  final List<VexDaySteps> stepsDays = [];
  final List<VexSample> hrRest = [], spo2Hist = [], tempHist = [];
  final List<VexHrvRec> hrvHist = [];
  final List<VexDynHr> hrDyn = [];
  final List<VexSleepRec> sleepHist = [];
  final StreamController<VexPpg> ppgStream = StreamController.broadcast();
  final StreamController<VexMsg> raw = StreamController.broadcast();

  final Map<int, _Waiter> _waiters = {};
  Future<void> _q = Future.value();

  // ───────────── دەستپێک ─────────────
  Future<void> init() async {
    try {
      final sp = await SharedPreferences.getInstance();
      final id = sp.getString(_kId);
      if (id != null && id.isNotEmpty) {
        // پەیوەستبوونەوەی خۆکار بە دوایین Band (بێدەنگ، شکست قبوڵە)
        unawaited(_autoReconnect(id));
      }
    } catch (_) {}
  }

  Future<void> _autoReconnect(String id) async {
    try {
      if (!await _perm()) return;
      await _open(BluetoothDevice.fromId(id));
    } catch (_) {}
  }

  Future<bool> _perm() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      final r = await [Permission.bluetoothScan, Permission.bluetoothConnect, Permission.locationWhenInUse].request();
      final ok = (r[Permission.bluetoothScan]?.isGranted ?? false) && (r[Permission.bluetoothConnect]?.isGranted ?? false);
      // Android ≤ 11: مۆڵەتی شوێن پێویستە و bluetoothScan «نادیار»ە
      return ok || (r[Permission.locationWhenInUse]?.isGranted ?? false);
    }
    return true;
  }

  // ───────────── سکان ─────────────
  Future<List<VexFound>> scan({Duration timeout = const Duration(seconds: 8)}) async {
    if (!await _perm()) return [];
    final out = <String, VexFound>{};
    final sub = FlutterBluePlus.scanResults.listen((rs) {
      for (final r in rs) {
        final n = r.advertisementData.advName.isNotEmpty ? r.advertisementData.advName : r.device.platformName;
        final byUuid = r.advertisementData.serviceUuids.contains(Guid(VexUuid.service));
        final l = n.toLowerCase();
        final byName = n.isNotEmpty && nameHints.any(l.contains);
        if (byUuid || byName) out[r.device.remoteId.str] = VexFound(r.device, n.isEmpty ? 'VEX Band' : n, r.rssi);
      }
    });
    try {
      await FlutterBluePlus.startScan(timeout: timeout);
      await FlutterBluePlus.isScanning.where((s) => !s).first;
    } finally {
      await sub.cancel();
    }
    final l = out.values.toList()..sort((a, b) => b.rssi.compareTo(a.rssi));
    return l;
  }

  /// سکان + پەیوەستبوون بە نزیکترین Band (بۆ دوگمەی «پەیوەستکردنەوە»)
  Future<bool> quickConnect() async {
    final l = await scan();
    if (l.isEmpty) return false;
    return connect(l.first);
  }

  // ───────────── پەیوەستبوون ─────────────
  Future<bool> connect(VexFound f) async {
    if (!await _perm()) return false;
    try {
      await _open(f.device);
      final sp = await SharedPreferences.getInstance();
      await sp.setString(_kId, f.device.remoteId.str);
      return true;
    } catch (e) {
      debugPrint('VexBand connect: $e');
      await disconnect(forget: false);
      return false;
    }
  }

  Future<void> _open(BluetoothDevice d) async {
    await disconnect(forget: false);
    _dev = d;
    await d.connect(timeout: const Duration(seconds: 15), autoConnect: false);
    _cSub = d.connectionState.listen((s) {
      if (s == BluetoothConnectionState.disconnected) _onDown();
    });
    if (defaultTargetPlatform == TargetPlatform.android) {
      try {
        mtu = await d.requestMtu(247);
      } catch (_) {}
    }
    final svcs = await d.discoverServices();
    BluetoothCharacteristic? wr, nt;
    for (final s in svcs) {
      if (s.uuid != Guid(VexUuid.service)) continue;
      for (final c in s.characteristics) {
        if (c.uuid == Guid(VexUuid.write)) wr = c;
        if (c.uuid == Guid(VexUuid.notify)) nt = c;
      }
    }
    if (wr == null || nt == null) throw StateError('Band ی VEX نەدۆزرایەوە (service fff0)');
    _wr = wr;
    await nt.setNotifyValue(true);
    _nSub = nt.onValueReceived.listen((v) => _onData(Uint8List.fromList(v)));
    _ready = true;
    BandState.I.setConnected(true);
    notifyListeners();
    // دانانی کات (پێویستە بۆ مێژوو) + باتری + وەشان
    await send(VexFrame.setTime(DateTime.now()));
    await send(VexFrame.battery());
    await send(VexFrame.version());
    await send(VexFrame.mac());
    _startWear(); // چاودێری «Band لە دەستە یان نا»
  }

  void _onDown() {
    if (!_ready && _dev == null) return;
    _stopWear();
    _ready = false;
    for (final w in _waiters.values) {
      if (!w.done.isCompleted) w.done.complete(w.got);
    }
    _waiters.clear();
    final t = DateTime.now();
    BandState.I.setConnected(false, lastSync: '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}');
    notifyListeners();
  }

  Future<void> disconnect({bool forget = true}) async {
    await _nSub?.cancel();
    await _cSub?.cancel();
    _nSub = _cSub = null;
    final d = _dev;
    _dev = null;
    _wr = null;
    final was = _ready;
    _stopWear();
    _ready = false;
    try {
      await d?.disconnect();
    } catch (_) {}
    if (forget) {
      try {
        (await SharedPreferences.getInstance()).remove(_kId);
      } catch (_) {}
    }
    if (was) {
      BandState.I.setConnected(false);
      notifyListeners();
    }
  }

  // ───────────── نووسین (ڕیز) ─────────────
  /// فرمانەکان یەک بە یەک دەنێردرێن؛ ڕێک وەک ڕیزی `offerValue` ی SDK.
  Future<void> send(Uint8List frame) {
    final c = Completer<void>();
    _q = _q.then((_) async {
      try {
        final w = _wr;
        if (w == null || !_ready && frame[0] != VexCmd.setTime) {
          if (w == null) throw StateError('Band پەیوەست نییە');
        }
        await w!.write(frame, withoutResponse: false);
        await Future<void>.delayed(const Duration(milliseconds: 40));
        c.complete();
      } catch (e) {
        c.completeError(e);
      }
    });
    return c.future;
  }

  /// فرمان بنێرە و چاوەڕێی وەڵام بە. بۆ مێژوو: تا نیشانەی کۆتایی یان بێدەنگی.
  Future<List<VexMsg>> request(Uint8List frame, {Duration timeout = const Duration(seconds: 4), Duration quiet = const Duration(milliseconds: 1200)}) async {
    final cmd = frame[0];
    final w = _Waiter(cmd);
    _waiters[cmd] = w;
    await send(frame);
    final t = Timer(timeout, () {
      if (!w.done.isCompleted) w.done.complete(w.got);
    });
    final r = await w.done.future;
    t.cancel();
    w.quiet?.cancel();
    _waiters.remove(cmd);
    return r;
  }

  static bool _isEnd(VexMsg m) => switch (m) {
        VexStepsHistory x => x.end,
        VexSeries x => x.end,
        VexHrvHistory x => x.end,
        VexDynHrHistory x => x.end,
        VexSleepHistory x => x.end,
        _ => true, // وەڵامی تاک
      };

  // ───────────── وەرگرتن ─────────────
  void _onData(Uint8List v) {
    if (v.isEmpty) return;
    if (!VexParser.crcOk(v)) return;
    final m = VexParser.parse(v);
    _apply(m);
    raw.add(m);
    final w = _waiters[v[0]];
    if (w != null && !w.done.isCompleted) {
      w.got.add(m);
      w.quiet?.cancel();
      if (_isEnd(m)) {
        w.done.complete(w.got);
      } else {
        w.quiet = Timer(const Duration(milliseconds: 1200), () {
          if (!w.done.isCompleted) w.done.complete(w.got);
        });
      }
    }
  }

  void _apply(VexMsg m) {
    switch (m) {
      case VexBattery b:
        battery = b.percent;
        charging = b.chargeState != 0;
        wear.onBattery(charging: charging);
      case VexVersion x:
        version = x.version;
      case VexMac x:
        mac = x.mac;
      case VexRealtime r:
        live = offWrist ? null : r;
        wear.onLive(hr: r.hr, spo2: r.spo2, tempC: r.tempC);
      case VexMeasureResult r:
        lastMeasure = r;
      case VexPpg p:
        ppgStream.add(p);
      default:
        break;
    }
    notifyListeners();
  }


  // ═══════════════════════════════════════════════════════════════════════════
  // «Band لە دەستە یان نا» — لۆجیکەکە لە vex_wear.dart ـە (PPG + شەحن + پاکێتی زیندوو)
  // ═══════════════════════════════════════════════════════════════════════════
  bool _busy = false;
  late final WearDetector wear = WearDetector(
    isReady: () => _ready,
    isBusy: () => _busy,
    samplePpg: _samplePpg,
    liveOn: () => liveSteps(true),
    onChanged: _onWear,
  );

  /// Band ی BLE ی پەیوەستە بەڵام لە دەست نییە
  bool get offWrist => wear.isOff;

  Timer? _batTimer;

  void _startWear() {
    wear.start();
    // باتری هەر ١ خولەک: «لەسەر شەحنە» = لە دەست نییە (بەڵگەی یەکسەر)
    _batTimer?.cancel();
    _batTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      if (_ready) unawaited(send(VexFrame.battery()).catchError((_) {}));
    });
  }

  void _stopWear() {
    _batTimer?.cancel();
    _batTimer = null;
    final was = wear.isOff;
    wear.stop();
    if (was) BandState.I.setOffWrist(false);
  }

  void _onWear(WearState s) {
    final off = s == WearState.off;
    if (off) {
      live = null;
      lastMeasure = null;
    }
    BandState.I.setOffWrist(off);
    notifyListeners();
  }

  /// ٧ چرکە شەپۆلی PPG ی ڕاستەقینە (هەمان ڕێگای ECG) بۆ پشکنینی دەست
  Future<(List<double>, double)?> _samplePpg() async {
    if (!_ready || _busy) return null;
    _busy = true;
    final buf = <double>[];
    DateTime? t0, t1;
    final sub = ppgStream.stream.listen((p) {
      final now = DateTime.now();
      t0 ??= now;
      t1 = now;
      for (final s in p.samples) {
        buf.add(s.toDouble());
      }
    });
    try {
      await send(VexFrame.measure(4, start: true, seconds: 50 * 1000));
      await send(VexFrame.ppgStream(true));
      await Future<void>.delayed(const Duration(seconds: 7));
    } finally {
      await sub.cancel();
      try {
        await send(VexFrame.measure(4, start: false, seconds: 50 * 1000));
        await send(VexFrame.ppgStream(false));
      } catch (_) {}
      _busy = false;
    }
    if (t0 == null || t1 == null || buf.length < 40) return null;
    final secs = t1!.difference(t0!).inMilliseconds / 1000.0;
    if (secs < 1.5) return null;
    // ٢ چرکەی یەکەم ڕادەکێشرێت (دەستپێکردنی سێنسەر)؛ ڕێژە = نموونە/چرکە
    final rate = buf.length / secs;
    final skip = (rate * 1.5).round().clamp(0, buf.length ~/ 2).toInt();
    return (buf.sublist(skip), rate);
  }

  // ───────────── ئاستی بەرز ─────────────
  /// خوێندنەوەی هەموو مێژوو. onProgress(0..1)
  Future<void> syncAll({void Function(double)? onProgress}) async {
    if (!_ready) return;
    final steps = <Future<void> Function()>[
      () => _readSteps(),
      () => _read(VexFrame.hrStatic, (m) => m is VexSeries ? m.samples : null, hrRest),
      () => _read(VexFrame.spo2, (m) => m is VexSeries ? m.samples : null, spo2Hist),
      () => _read(VexFrame.tempHistory, (m) => m is VexSeries ? m.samples : null, tempHist),
      () => _readList<VexHrvRec>(VexFrame.hrv, (m) => m is VexHrvHistory ? m.items : null, hrvHist),
      () => _readList<VexDynHr>(VexFrame.hrDynamic, (m) => m is VexDynHrHistory ? m.items : null, hrDyn),
      () => _readList<VexSleepRec>(VexFrame.sleep, (m) => m is VexSleepHistory ? m.items : null, sleepHist),
    ];
    await send(VexFrame.setTime(DateTime.now()));
    await send(VexFrame.battery());
    for (var i = 0; i < steps.length; i++) {
      try {
        await steps[i]();
      } catch (e) {
        debugPrint('VexBand sync step $i: $e');
      }
      onProgress?.call((i + 1) / steps.length);
    }
    final t = DateTime.now();
    BandState.I.lastSync = '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
    notifyListeners();
  }

  Future<void> _readList<T>(Uint8List Function({int mode, DateTime? from}) mk, List<T>? Function(VexMsg) pick, List<T> into) async {
    into.clear();
    var mode = VexMode.latest;
    for (var round = 0; round < 20; round++) {
      final r = await request(mk(mode: mode));
      var n = 0;
      var end = r.isEmpty;
      for (final m in r) {
        final l = pick(m);
        if (l != null) {
          into.addAll(l);
          n += l.length;
        }
        if (_isEnd(m)) end = true;
      }
      if (end || n == 0) break;
      mode = VexMode.next; // «بەردەوامبوون» کاتێک زیاتر لە ٥٠ تۆمار هەیە
    }
  }

  Future<void> _read(Uint8List Function({int mode, DateTime? from}) mk, List<VexSample>? Function(VexMsg) pick, List<VexSample> into) =>
      _readList<VexSample>(mk, pick, into);

  Future<void> _readSteps() => _readList<VexDaySteps>(VexFrame.totalSteps, (m) => m is VexStepsHistory ? m.days : null, stepsDays);

  /// هەنگاوی ڕاستەوخۆ (live) — ئاگادارکردنەوە بۆ هەر گۆڕانێک
  Future<void> liveSteps(bool on) => send(VexFrame.realtime(on: on, temp: true));

  /// پێوانەی دەستی. ئەنجام لە `lastMeasure` و `raw` دا دێت.
  Future<VexMeasureResult?> measure(VexMeasure k, {int seconds = 50}) async {
    final kind = switch (k) { VexMeasure.heart => 2, VexMeasure.spo2 => 3, VexMeasure.hrv => 4 };
    lastMeasure = null;
    final c = Completer<VexMeasureResult?>();
    final sub = raw.stream.where((m) => m is VexMeasureResult).listen((m) {
      final r = m as VexMeasureResult;
      if (!r.stopped && !c.isCompleted) c.complete(r);
    });
    await send(VexFrame.measure(kind, start: true, seconds: seconds));
    final r = await c.future.timeout(Duration(seconds: seconds + 15), onTimeout: () => null);
    await sub.cancel();
    await send(VexFrame.measure(kind, start: false, seconds: seconds));
    return r;
  }

  /// شەپۆلی زیندووی «ECG» ی Band (هەمان ڕێگای ئەپی فرۆشیار: PPGActivity.java).
  /// پاکێتەکان لە `ppgStream` دێن. پێویستە `stopWaveform()` بانگ بکرێت.
  Future<void> startWaveform() async {
    _busy = true; // لە کاتی ECG دا پشکنینی «لە دەستە» ڕادەوەستێت
    await send(VexFrame.measure(4, start: true, seconds: 50 * 1000));
    // SDK (iOS ppgView): شەپۆلی ECG دوای وەڵامی فرمانی پێوانە چالاک دەکرێت
    await Future<void>.delayed(const Duration(milliseconds: 350));
    await send(VexFrame.ppgStream(true));
  }

  Future<void> stopWaveform() async {
    await send(VexFrame.measure(4, start: false, seconds: 50 * 1000));
    await send(VexFrame.ppgStream(false));
    _busy = false;
  }

  Future<void> find() => send(VexFrame.find());

  /// نووسینی فرمانێکی درێژ (وەک کاتژمێرەکانی 0x23). ئەگەر لە MTU گەورەتر بێت long-write بەکاردێت.
  Future<void> sendLong(Uint8List data) {
    final c = Completer<void>();
    _q = _q.then((_) async {
      try {
        final w = _wr;
        if (w == null || !_ready) throw StateError('Band پەیوەست نییە');
        final room = (_dev?.mtuNow ?? mtu) - 3;
        await w.write(data, withoutResponse: false, allowLongWrite: data.length > room);
        await Future<void>.delayed(const Duration(milliseconds: 120));
        c.complete();
      } catch (e) {
        c.completeError(e);
      }
    });
    return c.future;
  }

  /// هەموو کاتژمێرەکانی ناو Band دەگۆڕێت بەم لیستە (هەتا 10). true = نێردرا.
  Future<bool> setAlarms(List<VexAlarm> list) async {
    if (!_ready) return false;
    try {
      for (final f in VexFrame.setAlarms(list)) {
        await (f.length == 16 ? send(f) : sendLong(f));
      }
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('VexBand.setAlarms: $e');
      return false;
    }
  }
  Future<void> setUser({required int sex, required int age, required int heightCm, required int weightKg, required int stepCm}) =>
      send(VexFrame.setUser(sex: sex, age: age, heightCm: heightCm, weightKg: weightKg, stepCm: stepCm));
}
