// VEX Band — پڕۆسێسکردنی شەپۆلی ECG ی زیندوو (وردتر)
//
// سەرچاوە: Band شەپۆلی خاو بە پاکێتی 0x07 دەنێرێت (SDK: setECGRealtimeDuringHRVEnabled).
// هەر نموونەیەک 3 بایتە (24-bit, little-endian).
//
// زنجیرەی پڕۆسێس (هەمان ماتماتیکی tools/ecg_check/ecg_dsp_ref.py کە تاقیکراوەتەوە):
//   1) چارەسەری 24-bit (ئەگەر ژمارەکە بە نیشانە بێت و لە 0 تێپەڕێت)
//   2) فلتەری High-pass 0.5Hz (دوو جار) ← لابردنی جووڵەی هێڵی بنەڕەت (هەناسە، جووڵە)
//   3) Notch 50Hz (کارەبای شار) ئەگەر ڕێژەی نموونە > 115Hz بێت
//   4) Low-pass ≤ 35Hz ← شەپۆلێکی پاک بۆ نیشاندان
//   5) دۆزینەوەی لێدان (Pan–Tompkins): باندی QRS 5–15Hz ← گۆڕان ← وزە ← پەنجەرەی 120ms ←
//      سنووری خۆگونجێن + گەڕانەوە بۆ لێدانی ونبوو + شوێنی R بە وردی کەمتر لە نموونەیەک
//   6) ئاراستەی شەپۆل خۆکار ڕاست دەکرێتەوە (ئەگەر Band لە دەستی ڕاستە، شەپۆلەکە پێچەوانە دەبێت)
// تاقیکردنەوە لەسەر 50/125/250/512Hz، 45–170 bpm، نۆیز، 50Hz، جووڵەی هێڵ: هەڵەی ناوەند 0.3 bpm.
import 'dart:math' as math;

class _Biquad {
  double b0 = 1, b1 = 0, b2 = 0, a1 = 0, a2 = 0, z1 = 0, z2 = 0;

  void set(String kind, double fs, double fc, [double q = 0.7071]) {
    final w = 2 * math.pi * fc / fs;
    final cw = math.cos(w), sw = math.sin(w);
    final al = sw / (2 * q);
    double n0, n1, n2;
    switch (kind) {
      case 'hp':
        n0 = (1 + cw) / 2;
        n1 = -(1 + cw);
        n2 = (1 + cw) / 2;
      case 'lp':
        n0 = (1 - cw) / 2;
        n1 = 1 - cw;
        n2 = (1 - cw) / 2;
      default: // notch
        n0 = 1;
        n1 = -2 * cw;
        n2 = 1;
    }
    final a0 = 1 + al;
    b0 = n0 / a0;
    b1 = n1 / a0;
    b2 = n2 / a0;
    a1 = -2 * cw / a0;
    a2 = (1 - al) / a0;
    z1 = z2 = 0;
  }

  double run(double x) {
    final y = b0 * x + z1;
    z1 = b1 * x - a1 * y + z2;
    z2 = b2 * x - a2 * y;
    return y;
  }
}

class EcgSignal {
  EcgSignal({this.defaultRate = 255, this.seconds = 5, this.invert = false}) {
    rate = defaultRate;
    reset();
  }

  // ── ڕێکخستنەکان ──
  /// ڕێژەی نموونە پێش خەمڵاندن — SDK ی V8 (iOS ppgView: 255 نموونە/چرکە، پەنجەرەی 5 چرکە)
  final double defaultRate;

  /// چەند چرکە لەسەر شاشە نیشان بدرێت
  final double seconds;

  /// Band لە دەستی ڕاستە ← شەپۆل پێچەوانە دەکرێتەوە (پاشان خۆکار ڕاست دەکرێتەوە)
  bool invert;

  /// کەمترین لادانی ستانداردی شەپۆلی فلتەرکراو بۆ ئەوەی پەنجە لەسەر بێت
  static const double minStd = 0.8;

  /// کەمترین قەبارە بۆ ئاسایی‌کردن — بێ پەنجە نۆیز گەورە نانوێنرێت و هێڵەکە ڕاست دەمێنێتەوە
  static const double ampFloor = 40.0;

  late double rate;
  double _designRate = 0;

  // نیشاندان (شێوازی مۆنیتەر: خەتێک لە چەپەوە بۆ ڕاست دەنووسرێت، بۆشاییەک لە پێشیەوە)
  List<double> sweep = <double>[];
  int cursor = 0;
  bool sweepFull = false;

  /// دواین شەپۆل (بۆ تۆمارکردن): هەر نموونەیەک -1..1
  double last = 0;

  final _Biquad _hp1 = _Biquad(), _hp2 = _Biquad(), _lp = _Biquad(), _notch = _Biquad();
  final _Biquad _qhp = _Biquad(), _qlp = _Biquad();
  bool _useNotch = false;

  int? _prev;
  double _off = 0;
  double? _x0;
  int _n = 0;
  int _since = 0; // نموونە لە دوای دیزاینی فلتەر
  final List<double> _y = <double>[]; // شەپۆلی فلتەرکراو (3 چرکە)
  final List<double> _d = <double>[0, 0];
  final List<double> _mwi = <double>[];
  double _mwiSum = 0, _m1 = 0, _m2 = 0;
  double _spki = 0, _npki = 0;
  int _lastQrs = -1000000;
  int _learn = 0;
  final List<(int, double)> _cands = <(int, double)>[];
  double _lastR = -1e9;

  final List<double> _rr = <double>[]; // RR ی پەسەندکراو (چرکە)
  /// هەموو RR ـە پەسەندکراوەکان لە کاتی پێوانە (بۆ HRV)
  final List<double> rrLog = <double>[];
  final List<int> _pol = <int>[];
  bool _flip = false;

  double _env = 1e-6; // قەبارەی شەپۆل بۆ نیشاندان
  final List<double> _stdWin = <double>[];
  DateTime? _t0, _lastPkt;
  int _count = 0;
  bool _railing = false;

  int beatCount = 0;
  bool beatNow = false;

  int get window => (seconds * rate).round().clamp(60, 3000);

  void reset() {
    rate = defaultRate;
    _design(rate);
    _prev = null;
    _off = 0;
    _x0 = null;
    _n = 0;
    _t0 = _lastPkt = null;
    _count = 0;
    _lastId = null;
    lostPackets = 0;
    _resetDetector();
    rrLog.clear();
    _pol.clear();
    _flip = false;
    _env = 1e-6;
    _stdWin.clear();
    beatCount = 0;
    beatNow = false;
    _newSweep();
  }

  void _newSweep() {
    sweep = List<double>.filled(window, 0);
    cursor = 0;
    sweepFull = false;
  }

  void _resetDetector() {
    _since = 0;
    _y.clear();
    _d
      ..clear()
      ..addAll([0, 0]);
    _mwi.clear();
    _mwiSum = _m1 = _m2 = 0;
    _spki = _npki = 0;
    _lastQrs = -1000000;
    _learn = 0;
    _cands.clear();
    _lastR = -1e9;
    _rr.clear();
  }

  void _design(double fs) {
    _designRate = fs;
    _hp1.set('hp', fs, 0.5);
    _hp2.set('hp', fs, 0.5);
    _lp.set('lp', fs, math.min(35.0, 0.4 * fs));
    _qhp.set('hp', fs, 5.0);
    _qlp.set('lp', fs, math.min(15.0, 0.3 * fs));
    _useNotch = fs > 115;
    if (_useNotch) _notch.set('notch', fs, 50.0, 8.0);
  }

  int? _lastId;

  /// پاکێتە ونبووەکان (هەمان پشکنینی packetID ی SDK)
  int lostPackets = 0;

  /// پاکێتێکی نوێ لە نموونەکان. packetId: 0..255 (بۆ دۆزینەوەی پاکێتی ونبوو)
  void addPacket(List<int> samples, {DateTime? now, int? packetId}) {
    if (samples.isEmpty) return;
    // پاکێتی ونبوو ← نموونەی ناوەند دادەنرێت بۆ ئەوەی کات (و BPM) ڕاست بمێنێتەوە
    if (packetId != null) {
      final last = _lastId;
      _lastId = packetId;
      if (last != null) {
        final lost = (packetId - last - 1) & 0xff;
        if (lost > 0 && lost < 8 && _prev != null) {
          lostPackets += lost;
          final a = _prev!, b = samples.first;
          final n = lost * samples.length;
          for (var i = 1; i <= n; i++) {
            _push((a + (b - a) * i / (n + 1)).round());
          }
          _count += n;
        }
      }
    }
    final t = now ?? DateTime.now();
    _t0 ??= t;
    _lastPkt = t;
    _count += samples.length;
    final el = t.difference(_t0!).inMicroseconds / 1e6;
    if (el > 1.5) {
      final r = (_count / el).clamp(20.0, 1000.0);
      rate = rate * 0.85 + r * 0.15;
      // ئەگەر ڕێژە بە ڕوونی گۆڕا ← فلتەرەکان دووبارە دیزاین دەکرێنەوە
      if ((rate - _designRate).abs() / _designRate > 0.08) {
        _design(rate);
        _x0 = null;
        _resetDetector();
        _newSweep();
      }
    }
    var same = 0;
    for (final s in samples) {
      if (_prev == s) same++;
      _push(s);
    }
    // هێڵی تەواو ڕاست (0 یان 0xFFFFFF) ← ئەلیکترۆد نییە
    _railing = same >= samples.length - 1 && (samples.last == 0 || samples.last == 0xFFFFFF);
  }

  void _push(int raw) {
    // 1) 24-bit
    final p = _prev;
    if (p != null) {
      final d = raw - p;
      if (d > 0x800000) {
        _off -= 0x1000000;
      } else if (d < -0x800000) {
        _off += 0x1000000;
      }
    }
    _prev = raw;
    var x = raw + _off;
    _x0 ??= x;
    x -= _x0!;
    // 2..4) فلتەر
    var y = _hp2.run(_hp1.run(x));
    if (_useNotch) y = _notch.run(y);
    y = _lp.run(y);
    if (invert) y = -y;
    _n++;
    _since++;
    _y.add(y);
    final keep = (rate * 3).round();
    if (_y.length > keep) _y.removeRange(0, _y.length - keep);
    _detect(_qlp.run(_qhp.run(y)));

    // پەنجە: لادانی ستانداردی 1 چرکە
    _stdWin.add(y);
    final k1 = rate.round().clamp(20, 1000);
    if (_stdWin.length > k1) _stdWin.removeRange(0, _stdWin.length - k1);

    // 6) نیشاندان
    final shown = _flip ? -y : y;
    _env = math.max(_env * math.pow(0.5, 1 / (rate * 2.5)).toDouble(), shown.abs());
    final scale = math.max(_env * 1.05, ampFloor);
    final settled = _since > rate * 1.2;
    final v = settled ? (shown / scale).clamp(-1.0, 1.0).toDouble() : 0.0;
    last = v;
    if (sweep.length != window) _newSweep();
    sweep[cursor] = v;
    cursor++;
    if (cursor >= sweep.length) {
      cursor = 0;
      sweepFull = true;
    }
  }

  void _detect(double q) {
    final fs = rate;
    _d.add(q);
    final dd = _d[_d.length - 1] - _d[_d.length - 3];
    _d.removeAt(0);
    final s = dd * dd;
    final w = math.max(3, (0.12 * fs).round());
    _mwi.add(s);
    _mwiSum += s;
    while (_mwi.length > w) {
      _mwiSum -= _mwi.removeAt(0);
    }
    final m = math.sqrt(math.max(0.0, _mwiSum) / _mwi.length);
    final settle = (fs * 1.2).round();
    if (_since > 3 && _m1 > _m2 && _m1 >= m) {
      final pk = _m1;
      final idx = _n - 2;
      if (_since < settle) {
        // فلتەرەکان جێگیر دەبن
      } else if (_learn < (fs * 2).round()) {
        _spki = math.max(_spki, pk);
        _npki = 0.5 * _npki + 0.05 * pk;
      } else {
        final thr = _npki + 0.45 * (_spki - _npki);
        final refr = 0.25 * fs;
        if (pk > thr && idx - _lastQrs > refr) {
          _spki = 0.125 * pk + 0.875 * _spki;
          _qrs(idx);
          _cands.clear();
        } else {
          _npki = 0.125 * pk + 0.875 * _npki;
          if (idx - _lastQrs > refr) _cands.add((idx, pk));
        }
      }
    }
    // گەڕانەوە: 1.66 × RR ی ئاسایی هیچ لێدانێک نەبوو ← باشترین لوتکەی بازدراو
    if (_cands.isNotEmpty && _rr.length >= 2) {
      final tail = _rr.length > 8 ? _rr.sublist(_rr.length - 8) : _rr;
      final avg = tail.reduce((a, b) => a + b) / tail.length;
      if ((_n - _lastQrs) > 1.66 * avg * fs) {
        final thr = _npki + 0.45 * (_spki - _npki);
        var best = _cands.first;
        for (final c in _cands) {
          if (c.$2 > best.$2) best = c;
        }
        _cands.clear();
        if (best.$2 > 0.5 * thr) {
          _spki = 0.25 * best.$2 + 0.75 * _spki;
          _qrs(best.$1);
        }
      }
    }
    if (_since >= settle) _learn++;
    _m2 = _m1;
    _m1 = m;
  }

  void _qrs(int idx) {
    final fs = rate;
    final span = math.max(3, (0.2 * fs).round());
    final end = _y.length - (_n - 1 - idx);
    if (end <= 0) return;
    final st = math.max(0, end - span);
    var j = st;
    for (var i = st; i < end; i++) {
      if (_y[i].abs() > _y[j].abs()) j = i;
    }
    var r = idx - (end - 1 - j).toDouble();
    final amp = _y[j];
    if (j > st && j < end - 1) {
      final a = _y[j - 1].abs(), b = _y[j].abs(), c = _y[j + 1].abs();
      final den = a - 2 * b + c;
      if (den != 0) r += (0.5 * (a - c) / den).clamp(-0.5, 0.5);
    }
    if (_lastR > -1e8) {
      final rr = (r - _lastR) / fs;
      if (rr >= 0.27 && rr <= 2.2) {
        double? med;
        if (_rr.length >= 3) {
          final s = [..._rr]..sort();
          med = s[s.length ~/ 2];
        }
        if (med == null || (rr >= 0.65 * med && rr <= 1.5 * med)) {
          _rr.add(rr);
          if (_rr.length > 12) _rr.removeAt(0);
          rrLog.add(rr);
        }
      }
    }
    _lastR = r;
    _lastQrs = idx;
    _pol.add(amp >= 0 ? 1 : -1);
    if (_pol.length > 8) _pol.removeAt(0);
    if (_pol.length >= 6) {
      final sum = _pol.reduce((a, b) => a + b);
      if (sum <= -4) _flip = true;
      if (sum >= 4) _flip = false;
    }
    beatCount++;
    beatNow = true;
  }

  /// کاتی دواین پاکێت
  DateTime? get lastPacket => _lastPkt;

  /// شەپۆلەکە خۆکار هەڵگێڕدرایەوە؟
  bool get flipped => _flip;

  /// ئایا پەنجە لەسەر ئەلیکترۆدە؟
  bool contact([DateTime? now]) {
    final t = now ?? DateTime.now();
    final lp = _lastPkt;
    if (lp == null || t.difference(lp).inMilliseconds > 1500) return false;
    if (_railing) return false;
    if (_since < rate * 0.8) return false;
    return _std(_stdWin) > minStd;
  }

  /// BPM ی زیندوو (null تا 3 لێدانی دروست)
  double? get bpm {
    if (_rr.length < 3) return null;
    final tail = _rr.length > 8 ? _rr.sublist(_rr.length - 8) : _rr;
    final s = [...tail]..sort();
    final b = 60.0 / s[s.length ~/ 2];
    return (b >= 30 && b <= 220) ? b : null;
  }

  /// 0..1 — جێگیریی ڕیتم + پەنجە
  double get quality {
    if (!contact()) return 0;
    if (_rr.length < 4) return 0.4;
    final m = _rr.reduce((a, b) => a + b) / _rr.length;
    final sd = _std(_rr);
    return (1 - (sd / m) * 4).clamp(0.0, 1.0).toDouble();
  }

  static double _std(List<double> l) {
    if (l.length < 2) return 0;
    final m = l.reduce((a, b) => a + b) / l.length;
    var s = 0.0;
    for (final x in l) {
      s += (x - m) * (x - m);
    }
    return math.sqrt(s / l.length);
  }
}

/// ئەنجامی HRV لە RR ـەکان
class EcgStats {
  const EcgStats({this.bpm, this.minBpm, this.maxBpm, this.rmssd, this.sdnn, this.irregular = false, this.beats = 0});
  final double? bpm, minBpm, maxBpm, rmssd, sdnn;
  final bool irregular;
  final int beats;

  static EcgStats from(List<double> rr) {
    if (rr.length < 4) return EcgStats(beats: rr.length);
    final s = [...rr]..sort();
    final med = s[s.length ~/ 2];
    final mean = rr.reduce((a, b) => a + b) / rr.length;
    var ss = 0.0, sq = 0.0;
    for (final x in rr) {
      ss += (x - mean) * (x - mean);
    }
    for (var i = 1; i < rr.length; i++) {
      final d = rr[i] - rr[i - 1];
      sq += d * d;
    }
    final sdnn = math.sqrt(ss / rr.length) * 1000;
    final rmssd = math.sqrt(sq / (rr.length - 1)) * 1000;
    // ڕیتمی نائاسایی: جیاوازیی RR ـی یەک لە دوای یەک بە بەراورد بە ناوەند (پەیوەند نەکراوە بە دەستنیشانکردن)
    var big = 0;
    for (var i = 1; i < rr.length; i++) {
      if ((rr[i] - rr[i - 1]).abs() > 0.15 * med) big++;
    }
    return EcgStats(
      bpm: 60 / med,
      minBpm: 60 / s.last,
      maxBpm: 60 / s.first,
      rmssd: rmssd,
      sdnn: sdnn,
      irregular: rr.length >= 10 && big / (rr.length - 1) > 0.35,
      beats: rr.length + 1,
    );
  }
}

/// شەپۆلی دەستکرد بۆ تاقیکردنەوەی دیزاین بەبێ Band (تەنها debug)
double ecgSynth(double t, {double bpm = 72}) {
  final period = 60.0 / bpm;
  final x = t % period;
  final r = 0.25 * math.min(period, 0.9);
  double g(double c, double w, double a) => a * math.exp(-math.pow((x - c) / w, 2).toDouble());
  return g(r - .16, .025, .12) - g(r - .028, .012, .12) + g(r, .016, 1.0) - g(r + .03, .013, .25) + g(r + .24 * math.min(1, period), .05, .3);
}
