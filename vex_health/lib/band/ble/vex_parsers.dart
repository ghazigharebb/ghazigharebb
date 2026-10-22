// VEX Band — خوێندنەوەی وەڵامەکانی Band (notify)
// هەموو ئۆفسێتەکان لە ResolveUtil.java ی J-STYLE SDK وەرگیراون.
import 'dart:typed_data';

import 'vex_frame.dart';

String _h(int b) => (b & 0xff).toRadixString(16).padLeft(2, '0');
int _u(Uint8List v, int i) => i < v.length ? v[i] : 0;
int _le(Uint8List v, int i, int n) {
  var x = 0;
  for (var k = 0; k < n; k++) {
    x |= _u(v, i + k) << (8 * k);
  }
  return x;
}

/// «26 10 22 01 06 00» (BCD) ← DateTime
DateTime? _dt(Uint8List v, int o) {
  try {
    final y = int.parse('20${_h(_u(v, o))}');
    final mo = int.parse(_h(_u(v, o + 1)));
    final d = int.parse(_h(_u(v, o + 2)));
    final hh = int.parse(_h(_u(v, o + 3)));
    final mi = int.parse(_h(_u(v, o + 4)));
    final ss = int.parse(_h(_u(v, o + 5)));
    if (mo < 1 || mo > 12 || d < 1 || d > 31) return null;
    return DateTime(y, mo, d, hh, mi, ss);
  } catch (_) {
    return null;
  }
}

DateTime? _day(Uint8List v, int o) {
  final t = _dt(Uint8List.fromList([..._sl(v, o, 3), 0, 0, 0]), 0);
  return t;
}

List<int> _sl(Uint8List v, int o, int n) => List<int>.generate(n, (i) => _u(v, o + i));

// ───────────── مۆدێلەکان ─────────────
sealed class VexMsg {
  const VexMsg();
}

class VexBattery extends VexMsg {
  final int percent, chargeState, millivolt;
  const VexBattery(this.percent, this.chargeState, this.millivolt);
}

class VexVersion extends VexMsg {
  final String version;
  const VexVersion(this.version);
}

class VexMac extends VexMsg {
  final String mac;
  const VexMac(this.mac);
}

class VexDeviceTime extends VexMsg {
  final DateTime? time;
  final int mtu;
  const VexDeviceTime(this.time, this.mtu);
}

class VexRealtime extends VexMsg {
  final int steps, minutes, activeSeconds, hr, spo2;
  final double kcal, km, tempC;
  const VexRealtime({required this.steps, required this.kcal, required this.km, required this.minutes, required this.activeSeconds, required this.hr, required this.tempC, required this.spo2});
}

class VexDaySteps {
  final DateTime? day;
  final int steps, minutes, goal;
  final double kcal, km;
  const VexDaySteps(this.day, this.steps, this.minutes, this.km, this.kcal, this.goal);
}

class VexStepsHistory extends VexMsg {
  final List<VexDaySteps> days;
  final bool end;
  const VexStepsHistory(this.days, this.end);
}

class VexSample {
  final DateTime? at;
  final double value;
  const VexSample(this.at, this.value);
}

/// دڵ (ئارام/وردەکاری)، SpO2، گەرما
class VexSeries extends VexMsg {
  final int cmd;
  final List<VexSample> samples;
  final bool end;
  const VexSeries(this.cmd, this.samples, this.end);
}

class VexHrvRec {
  final DateTime? at;
  final int hrv, vascular, hr, stress, mood, breath;
  const VexHrvRec(this.at, this.hrv, this.vascular, this.hr, this.stress, this.mood, this.breath);
}

class VexHrvHistory extends VexMsg {
  final List<VexHrvRec> items;
  final bool end;
  const VexHrvHistory(this.items, this.end);
}

class VexDynHr {
  final DateTime? at;
  final List<int> bpm; // ١٥ نموونە
  const VexDynHr(this.at, this.bpm);
}

class VexDynHrHistory extends VexMsg {
  final List<VexDynHr> items;
  final bool end;
  const VexDynHrHistory(this.items, this.end);
}

class VexSleepRec {
  final DateTime? start;
  final List<int> quality; // 1 قووڵ، 2 سووک، 3 REM، هەر شتێکی تر بێدار (بەپێی دۆکیومێنتی SDK)
  final int unitMinutes; // ١ یان ٥
  const VexSleepRec(this.start, this.quality, this.unitMinutes);
}

class VexSleepHistory extends VexMsg {
  final List<VexSleepRec> items;
  final bool end;
  const VexSleepHistory(this.items, this.end);
}

class VexMeasureResult extends VexMsg {
  /// kind: 1 HRV، 2 دڵ، 3 SpO2 (بەپێی وەڵامی SDK)
  final int kind, hr, spo2, hrv, stress, high, low;
  final bool stopped;
  const VexMeasureResult(this.kind, this.hr, this.spo2, this.hrv, this.stress, this.high, this.low, this.stopped);
}

class VexPpg extends VexMsg {
  final int packetId;
  final List<int> samples; // ٣ بایت بۆ هەر نموونە (کەمترین بایت یەکەم)
  const VexPpg(this.packetId, this.samples);
}

class VexBasic extends VexMsg {
  final Map<String, int> v;
  const VexBasic(this.v);
}

class VexAck extends VexMsg {
  final int cmd;
  const VexAck(this.cmd);
}

class VexUnknown extends VexMsg {
  final Uint8List raw;
  const VexUnknown(this.raw);
}

// ───────────── پارسەر ─────────────
class VexParser {
  VexParser._();

  /// پشکنینی کۆ — بۆ پاکێتی ١٦ بایتی (پاکێتی درێژتر ڕاستەوخۆ پارس دەکرێت)
  static bool crcOk(Uint8List v) {
    if (v.length != 16) return true;
    var c = 0;
    for (var i = 0; i < 15; i++) {
      c += v[i];
    }
    return (c & 0xff) == v[15];
  }

  static VexMsg parse(Uint8List v) {
    if (v.isEmpty) return VexUnknown(v);
    switch (v[0] & 0xff) {
      case VexCmd.battery:
        return VexBattery(_u(v, 1), _u(v, 2), _u(v, 3) + (_u(v, 4) << 8));
      case VexCmd.version:
        return VexVersion([for (var i = 1; i < 5; i++) _u(v, i).toRadixString(16).toUpperCase()].join('.'));
      case VexCmd.mac:
        return VexMac([for (var i = 1; i < 7; i++) _h(_u(v, i)).toUpperCase()].join(':'));
      case VexCmd.getTime:
        return VexDeviceTime(_dt(v, 1), _u(v, 8));
      case VexCmd.setTime:
        return VexDeviceTime(null, _u(v, 1)); // وەڵام: MTU
      case VexCmd.realtime:
        return _realtime(v);
      case VexCmd.totalSteps:
        return _steps(v);
      case VexCmd.hrStatic:
        return _seriesStatic(v, VexCmd.hrStatic, 10, 3, 9);
      case VexCmd.spo2:
        return _seriesStatic(v, VexCmd.spo2, 10, 3, 9);
      case VexCmd.temp:
        return _temp(v);
      case VexCmd.hrDynamic:
        return _dyn(v);
      case VexCmd.hrv:
        return _hrv(v);
      case VexCmd.sleep:
        return _sleep(v);
      case VexCmd.measure:
        return _measure(v);
      case VexCmd.ppg:
        return v.length > 16 ? _ppg(v) : VexAck(VexCmd.ppg);
      case VexCmd.getBasic:
        return VexBasic({'sportFlash': _u(v, 5), 'hrHighFlash': _u(v, 6)});
      default:
        return VexAck(v[0] & 0xff);
    }
  }

  static VexMsg _realtime(Uint8List v) {
    final steps = _le(v, 1, 4);
    final cal = _le(v, 5, 4) / 100.0;
    final dist = _le(v, 9, 4) / 100.0;
    final secs = _le(v, 13, 4);
    final act = _le(v, 17, 4);
    final t = (_u(v, 22) + (_u(v, 23) << 8)) * 0.1;
    return VexRealtime(steps: steps, kcal: cal, km: dist, minutes: secs ~/ 60, activeSeconds: act, hr: _u(v, 21), tempC: t, spo2: _u(v, 24));
  }

  static VexMsg _steps(Uint8List v) {
    final len = v.length;
    var n = 27;
    if (len != 2) {
      if (len % 26 == 0) {
        n = 26;
      } else if (len % 27 == 0) {
        n = 27;
      } else if ((len - 2) % 26 == 0) {
        n = 26;
      } else if ((len - 2) % 27 == 0) {
        n = 27;
      }
    }
    final size = len ~/ n;
    if (size == 0) return const VexStepsHistory([], true);
    var end = false;
    final out = <VexDaySteps>[];
    for (var i = 0; i < size; i++) {
      final flag = 1 + (i + 1) * n;
      if (flag < len && v[flag] == 0xff) end = true;
      final o = i * n;
      final goal = n == 26 ? _u(v, 21 + o) : _u(v, 21 + o) + (_u(v, 22 + o) << 8);
      out.add(VexDaySteps(_day(v, 2 + o), _le(v, 5 + o, 4), _le(v, 9 + o, 4), _le(v, 13 + o, 4) / 100.0, _le(v, 17 + o, 4) / 100.0, goal));
    }
    return VexStepsHistory(out, end);
  }

  static VexMsg _seriesStatic(Uint8List v, int cmd, int n, int dateAt, int valAt) {
    final size = v.length ~/ n;
    if (size == 0) return VexSeries(cmd, const [], true);
    final end = v.last == 0xff;
    final out = <VexSample>[];
    for (var i = 0; i < size; i++) {
      out.add(VexSample(_dt(v, dateAt + i * n), _u(v, valAt + i * n).toDouble()));
    }
    return VexSeries(cmd, out, end);
  }

  static VexMsg _temp(Uint8List v) {
    const n = 11;
    final size = v.length ~/ n;
    final end = size == 0 || v.last == 0xff;
    final out = <VexSample>[];
    for (var i = 0; i < size; i++) {
      final t = _u(v, 9 + i * n) + (_u(v, 10 + i * n) << 8);
      out.add(VexSample(_dt(v, 3 + i * n), t * 0.1));
    }
    return VexSeries(VexCmd.temp, out, end);
  }

  static VexMsg _dyn(Uint8List v) {
    const n = 24;
    final size = v.length ~/ n;
    if (size == 0) return const VexDynHrHistory([], true);
    final end = v.last == 0xff;
    final out = <VexDynHr>[];
    for (var i = 0; i < size; i++) {
      out.add(VexDynHr(_dt(v, 3 + i * n), _sl(v, 9 + i * n, 15)));
    }
    return VexDynHrHistory(out, end);
  }

  static VexMsg _hrv(Uint8List v) {
    const n = 15;
    final size = v.length ~/ n;
    if (size == 0) return const VexHrvHistory([], true);
    final end = v.last == 0xff;
    final out = <VexHrvRec>[];
    for (var i = 0; i < size; i++) {
      final o = i * n;
      // ترتیبی SDK: [9]=HRV [10]=تەمەنی خوێنهێنەر [11]=دڵ [12]=سترێس [13]=مزاج [14]=هەناسە
      out.add(VexHrvRec(_dt(v, 3 + o), _u(v, 9 + o), _u(v, 10 + o), _u(v, 11 + o), _u(v, 12 + o), _u(v, 13 + o), _u(v, 14 + o)));
    }
    return VexHrvHistory(out, end);
  }

  static VexMsg _sleep(Uint8List v) {
    final len = v.length;
    final end = len >= 2 && v[len - 1] == 0xff && v[len - 2] == VexCmd.sleep;
    final out = <VexSleepRec>[];
    if (len == 130 || (end && len == 132)) {
      final k = _u(v, 9);
      out.add(VexSleepRec(_dt(v, 3), _sl(v, 10, k), 1));
    } else {
      const n = 34;
      final size = len ~/ n;
      for (var i = 0; i < size; i++) {
        final k = _u(v, 9 + i * n).clamp(0, 24);
        out.add(VexSleepRec(_dt(v, 3 + i * n), _sl(v, 10 + i * n, k), 5));
      }
      if (size == 0) return const VexSleepHistory([], true);
    }
    return VexSleepHistory(out, end);
  }

  static VexMsg _measure(Uint8List v) {
    final k = _u(v, 1);
    final hr = _u(v, 2), sp = _u(v, 3);
    final hasData = hr != 0 || sp != 0 || _u(v, 4) != 0;
    return VexMeasureResult(k, hr, sp, _u(v, 4), _u(v, 5), _u(v, 6), _u(v, 7), !hasData);
  }

  static VexMsg _ppg(Uint8List v) {
    // SDK: بایتی ١ = ژمارەی پاکێت، نموونەکان لە بایتی ٢ەوە (تەنها کاتێک درێژی > ١٦)
    final out = <int>[];
    for (var i = 2; i + 2 < v.length; i += 3) {
      out.add(_u(v, i) | (_u(v, i + 1) << 8) | (_u(v, i + 2) << 16));
    }
    return VexPpg(_u(v, 1), out);
  }
}
