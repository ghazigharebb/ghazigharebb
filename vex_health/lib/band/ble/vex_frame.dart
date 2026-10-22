// VEX Band — دروستکردنی فرمانەکانی BLE
// سەرچاوە: J-STYLE V8 SDK (BleSDK.java / DeviceConst.java). هەموو فرمانێک ١٦ بایتە:
//   بایتی ٠ = ئایدی فرمان، بایتی ١٥ = کۆی بایتەکانی ٠..١٤ & 0xFF
import 'dart:convert';
import 'dart:typed_data';

class VexUuid {
  static const service = '0000fff0-0000-1000-8000-00805f9b34fb';
  static const write = '0000fff6-0000-1000-8000-00805f9b34fb';
  static const notify = '0000fff7-0000-1000-8000-00805f9b34fb';
}

class VexCmd {
  static const setTime = 0x01, getTime = 0x41;
  static const setUser = 0x02, getUser = 0x42;
  static const setBasic = 0x03, getBasic = 0x04;
  static const ppg = 0x07; // شەپۆلی PPG لە کاتی پێوانەی HRV
  static const realtime = 0x09; // هەنگاوی ڕاستەوخۆ
  static const reset = 0x12, battery = 0x13;
  static const exercise = 0x19;
  static const mac = 0x22, version = 0x27;
  static const measure = 0x28;
  static const setAuto = 0x2a, getAuto = 0x2b;
  static const mcuReset = 0x2e;
  static const setName = 0x3d, getName = 0x3e;
  static const totalSteps = 0x51, detailSteps = 0x52, sleep = 0x53;
  static const hrDynamic = 0x54, hrStatic = 0x55, hrv = 0x56;
  static const sleepDetail = 0x6b, temp = 0x62, spo2 = 0x66;
  static const ntcTemp = 0x14;
}

/// مۆدی خوێندنەوەی مێژوو
class VexMode {
  static const latest = 0; // لە نوێترینەوە (تا ٥٠ تۆمار)
  static const next = 2; // بەردەوامبوون
  static const delete = 0x99; // سڕینەوەی هەموو
}

int _bcd(int v) => ((v ~/ 10) % 10 << 4) | (v % 10);

Uint8List _f(int cmd, [Map<int, int> b = const {}]) {
  final v = Uint8List(16);
  v[0] = cmd;
  b.forEach((i, x) => v[i] = x & 0xff);
  var c = 0;
  for (var i = 0; i < 15; i++) {
    c += v[i];
  }
  v[15] = c & 0xff;
  return v;
}

Uint8List _hist(int cmd, int mode, DateTime? from, {bool withTime = true}) {
  final b = <int, int>{1: mode};
  if (from != null) {
    b[4] = _bcd(from.year % 100);
    b[5] = _bcd(from.month);
    b[6] = _bcd(from.day);
    if (withTime) {
      b[7] = _bcd(from.hour);
      b[8] = _bcd(from.minute);
      b[9] = _bcd(from.second);
    }
  }
  return _f(cmd, b);
}

class VexFrame {
  VexFrame._();

  static Uint8List setTime(DateTime t) {
    final off = t.timeZoneOffset.inHours;
    // SDK: هەرێمی ئەرێنی = 0x80 + کاتژمێر، نەرێنی = ژمارەکە بە خۆی
    final zone = off >= 0 ? (0x80 + off) : -off;
    return _f(VexCmd.setTime, {
      1: _bcd(t.year % 100), 2: _bcd(t.month), 3: _bcd(t.day),
      4: _bcd(t.hour), 5: _bcd(t.minute), 6: _bcd(t.second), 8: zone,
    });
  }

  static Uint8List getTime() => _f(VexCmd.getTime);
  static Uint8List battery() => _f(VexCmd.battery);
  static Uint8List version() => _f(VexCmd.version);
  static Uint8List mac() => _f(VexCmd.mac);
  static Uint8List getUser() => _f(VexCmd.getUser);
  static Uint8List getBasic() => _f(VexCmd.getBasic);
  static Uint8List getName() => _f(VexCmd.getName);
  static Uint8List factoryReset() => _f(VexCmd.reset);
  static Uint8List restart() => _f(VexCmd.mcuReset);

  /// sex: 1 نێر / 0 مێ (بەپێی SDK: ژمارە وەک خۆی دەنێردرێت)
  static Uint8List setUser({required int sex, required int age, required int heightCm, required int weightKg, required int stepCm}) =>
      _f(VexCmd.setUser, {1: sex, 2: age, 3: heightCm, 4: weightKg, 5: stepCm});

  /// فڵاشی LED ـی مۆدی وەرزش (0x81 = کراوە، 0x80 = داخراو)
  static Uint8List setBasic({required bool sportFlash, required bool hrHighFlash}) =>
      _f(VexCmd.setBasic, {5: sportFlash ? 0x81 : 0x80, 6: hrHighFlash ? 0x81 : 0x80});

  /// ناوی Band — ASCII، تا ١٤ پیت
  static Uint8List setName(String n) {
    final s = n.codeUnits.take(14).toList();
    final b = <int, int>{};
    for (var i = 0; i < s.length; i++) {
      b[i + 1] = s[i] & 0xff;
    }
    return _f(VexCmd.setName, b);
  }

  /// هەنگاوی ڕاستەوخۆ (+ گەرما)
  static Uint8List realtime({bool on = true, bool temp = false}) =>
      _f(VexCmd.realtime, {1: on ? 1 : 0, 2: temp ? 1 : 0});

  // ---- مێژوو ----
  static Uint8List totalSteps({int mode = VexMode.latest, DateTime? from}) =>
      _hist(VexCmd.totalSteps, mode, from, withTime: false);
  static Uint8List detailSteps({int mode = VexMode.latest, DateTime? from}) => _hist(VexCmd.detailSteps, mode, from);
  static Uint8List sleep({int mode = VexMode.latest, DateTime? from}) => _hist(VexCmd.sleep, mode, from);
  static Uint8List sleepDetail({int mode = VexMode.latest, DateTime? from}) => _hist(VexCmd.sleepDetail, mode, from);
  static Uint8List hrDynamic({int mode = VexMode.latest, DateTime? from}) => _hist(VexCmd.hrDynamic, mode, from);
  static Uint8List hrStatic({int mode = VexMode.latest, DateTime? from}) => _hist(VexCmd.hrStatic, mode, from);
  static Uint8List hrv({int mode = VexMode.latest, DateTime? from}) => _hist(VexCmd.hrv, mode, from);
  static Uint8List spo2({int mode = VexMode.latest, DateTime? from}) => _hist(VexCmd.spo2, mode, from);
  static Uint8List tempHistory({int mode = VexMode.latest, DateTime? from}) => _hist(VexCmd.temp, mode, from);

  /// پێوانەی دەستی. kind: 2 دڵ، 3 SpO2، 4 HRV
  static Uint8List measure(int kind, {required bool start, int seconds = 50}) =>
      _f(VexCmd.measure, {1: kind, 2: start ? 1 : 0, 4: seconds & 0xff, 5: (seconds >> 8) & 0xff});

  /// شەپۆلی PPG ی ڕاستەوخۆ لە کاتی پێوانەی HRV
  static Uint8List ppgStream(bool on) => _f(VexCmd.ppg, {1: on ? 1 : 0});

  // ---- پێوانەی خۆکار ----
  /// kind: 1 دڵ، 2 SpO2، 3 گەرما، 4 HRV. weekMask بیت-ماسک (بەپێی SDK)
  static Uint8List setAuto({
    required int kind, required bool on,
    int startH = 0, int startM = 0, int endH = 23, int endM = 59,
    int weekMask = 0x7f, int everyMin = 10,
  }) =>
      _f(VexCmd.setAuto, {
        1: on ? 1 : 0, 2: _bcd(startH), 3: _bcd(startM), 4: _bcd(endH), 5: _bcd(endM),
        6: weekMask, 7: everyMin & 0xff, 8: (everyMin >> 8) & 0xff, 9: kind,
      });
  static Uint8List getAuto(int kind) => _f(VexCmd.getAuto, {1: kind});

  // ---- چالاکی/وەرزش ----
  /// work: 1 دەستپێک، 2 ڕاگرتن، 3 بەردەوام، 4 کۆتایی
  static Uint8List exercise({required int work, required int mode, int minutes = 0}) =>
      _f(VexCmd.exercise, {1: work, 2: mode, 4: minutes});
  static Uint8List breath({required int work, required int level, required int minutes}) =>
      _f(VexCmd.exercise, {1: work, 2: 6, 3: level, 4: minutes});
  /// Band دەلەرێتەوە (دۆزینەوە)
  static Uint8List find() => _f(VexCmd.exercise, {1: 5});

  static String utf8Safe(List<int> b) => utf8.decode(b, allowMalformed: true);
}
