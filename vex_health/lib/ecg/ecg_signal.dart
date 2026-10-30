// VEX Band — ECG ی زیندوو (v3): پڕۆسێسکردن، دۆزینەوەی لێدان و نیشاندانی شەپۆل
//
// سەرچاوە: Band شەپۆلی خاو بە پاکێتی 0x07 دەنێرێت (SDK: setECGRealtimeDuringHRVEnabled).
// هەر نموونەیەک 3 بایتە (24-bit, little-endian). SDK ی V8: 255 نموونە/چرکە (iOS ppgView).
//
// چاککردنەکانی v3 (بەراورد بە ئەپی ڕەسمی V8):
//   • شەپۆلەکە لە سەرەتا گیر نامێنێت: پانیی شاشە جێگیرە و هەرگیز بە گۆڕانی بچووکی ڕێژە سفر نابێتەوە
//     (هۆکاری کێشەکە: هەر پاکێتێک ڕێژەکەی کەمێک دەگۆڕی ← sweep لە 0 دەستی پێدەکردەوە).
//   • پەخشی نەرم: نموونەکان لە ڕیزێکدا کۆدەبنەوە و بە خێرایی ڕاستەقینە (≈ 255/چرکە) دەنووسرێن،
//     وەک مۆنیتەری نەخۆشخانە، نەک پارچە پارچە بە گەیشتنی پاکێتی BLE.
//   • ڕێژەی نموونە بە regression لەسەر 3–12 چرکە دەخەمڵێنرێت و یەک جار قفڵ دەکرێت (نەک هەر پاکێتێک).
//   • کاتێک پەنجە دادەنرێت سنوورەکان لە سەرەتاوە فێر دەبنەوە (پێشتر لەسەر نۆیز فێر دەبوون ← BPM ی 160–200).
//   • ڕەتکردنەوەی شەپۆلی T (Pan–Tompkins) ← دڵ دوو هێندە ناژمێردرێت.
//   • 4 RR ی یەکگرتوو کە ڕەتکرابوونەوە ← ڕیتمی نوێ قبوڵ دەکرێت (هەرگیز لەسەر ژمارەیەکی هەڵە گیر نابێت).
//   • پاکێتی ونبوو بە قەبارەی ناوەندی پاکێت پڕدەکرێتەوە.
// تاقیکراوەتەوە: tools/ecg_check/ecg_live_ref.py (هەمان ماتماتیک، 72 دۆخ: 128–512Hz، 50–150 bpm،
// پاکێتی 18–81 نموونە، دواکەوتنی BLE، پاکێتی ونبوو، 50Hz، جووڵەی هێڵ، T ی بەرز، دەستی ڕاست).
import 'dart:collection';
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

  /// ڕێژەی نموونە (لە سەرەتا 255؛ دوای ~6 چرکە قفڵ دەکرێت)
  late double rate;

  /// ڕێژەکە پشتڕاستکراوەتەوە (BPM تەنها دوای ئەمە پیشان دەدرێت)
  bool rateOk = false;
  bool _locked = false, _early = false;

  // ── نیشاندان (مۆنیتەر: خەتێک لە چەپەوە بۆ ڕاست دەنووسرێت، بۆشاییەک لە پێشیەوە) ──
  List<double> sweep = <double>[];
  int cursor = 0;
  bool sweepFull = false;

  /// دواین خاڵی نووسراو لەسەر شاشە (-1..1)
  double last = 0;

  final ListQueue<double> _play = ListQueue<double>();
  bool _playing = false;
  double _acc = 0;
  DateTime? _lastAdv;
  List<double> _tape = <double>[];

  // ── فلتەر ──
  final _Biquad _hp1 = _Biquad(), _hp2 = _Biquad(), _lp = _Biquad(), _notch = _Biquad();
  final _Biquad _qhp = _Biquad(), _qlp = _Biquad();
  bool _useNotch = false;

  int? _prev;
  double _off = 0;
  double? _x0;
  int _n = 0;
  int _since = 0;

  // ── دۆزینەوەی لێدان ──
  List<double> _y = <double>[];
  final List<double> _d = <double>[0, 0];
  final ListQueue<double> _mwi = ListQueue<double>();
  final ListQueue<double> _slw = ListQueue<double>();
  double _mwiSum = 0, _m1 = 0, _m2 = 0;
  double _spki = 0, _npki = 0;
  int _lastQrs = -1000000;
  double _lastSlope = 0;
  final List<double> _slopes = <double>[]; // لێژیی QRS ـە پەسەندکراوەکان
  int _learn = 0;
  final List<(int, double, double)> _cands = <(int, double, double)>[];
  double _lastR = -1e9;
  int _quiet = 0, _idleMark = 0, _hold = 0, _restartAt = 0;
  double _learnE = 0, _eFast = 0;

  final List<double> _rr = <double>[]; // RR ی پەسەندکراو (چرکە)
  final List<double> _rej = <double>[];

  /// هەموو RR ـە پەسەندکراوەکان لە کاتی پێوانە (بۆ HRV)
  List<double> rrLog = <double>[];
  final List<int> _pol = <int>[];
  bool _flip = false;

  double _env = 1e-6;
  final ListQueue<double> _stdWin = ListQueue<double>();
  double _sSum = 0, _sSq = 0;

  // ── کات و پاکێت ──
  DateTime? _t0, _lastPkt;
  int _count = 0;
  final List<(double, int)> _arr = <(double, int)>[];
  int? _lastId;
  double _pktAvg = 0;
  bool _railing = false;

  /// پاکێتە ونبووەکان (هەمان پشکنینی packetID ی SDK)
  int lostPackets = 0;

  int beatCount = 0;
  bool beatNow = false;

  int get window => sweep.length;

  int _winFor(double fs) => (seconds * fs).round().clamp(60, 3000).toInt();

  void reset() {
    rate = defaultRate;
    rateOk = _locked = _early = false;
    _design(rate);
    _prev = null;
    _off = 0;
    _x0 = null;
    _n = 0;
    _t0 = _lastPkt = null;
    _count = 0;
    _arr.clear();
    _lastId = null;
    _pktAvg = 0;
    lostPackets = 0;
    rrLog = <double>[];
    _rej.clear();
    _pol.clear();
    _flip = false;
    _env = 1e-6;
    _stdWin.clear();
    _sSum = _sSq = 0;
    beatCount = 0;
    beatNow = false;
    _play.clear();
    _playing = false;
    _acc = 0;
    _lastAdv = null;
    _tape = <double>[];
    _railing = false;
    sweep = List<double>.filled(_winFor(rate), 0);
    cursor = 0;
    sweepFull = false;
    last = 0;
    _resetDetector();
  }

  void _resetDetector() {
    _since = 0;
    _y = <double>[];
    _d
      ..clear()
      ..addAll([0, 0]);
    _mwi.clear();
    _slw.clear();
    _mwiSum = _m1 = _m2 = 0;
    _spki = _npki = 0;
    _lastQrs = -1000000;
    _lastSlope = 0;
    _slopes.clear();
    _learn = 0;
    _cands.clear();
    _lastR = -1e9;
    _rr.clear();
    _quiet = _idleMark = _hold = _restartAt = 0;
    _learnE = _eFast = 0;
  }

  /// پەنجە تازە دانرا ← سنوورەکان لەسەر ECG ی ڕاستەقینە فێر دەبنەوە (نەک لەسەر نۆیزی پێشوو)
  void restartLearning() {
    // هێڵی بنەڕەت لە ئاستی ئێستاوە ← هەنگاوی دەستلێدان بە high-pass دا نالەرێتەوە
    _design(rate);
    _x0 = null;
    _hold = _n + (0.5 * rate).round(); // بازدان بەسەر لەرینی دەستلێدانەکەدا
    _env = 1e-6; // قەبارەی نیشاندان بە خێرایی لەگەڵ ECG ی ڕاستەقینە دەگونجێت
    _learnE = 0;
    _restartAt = _n;
    _learn = 0;
    _spki = _npki = 0;
    _cands.clear();
    _rej.clear();
    _lastR = -1e9;
    _lastQrs = -1000000;
    _rr.clear();
    _lastSlope = 0;
    _slopes.clear();
  }

  void _design(double fs) {
    _hp1.set('hp', fs, 0.5);
    _hp2.set('hp', fs, 0.5);
    _lp.set('lp', fs, math.min(35.0, 0.4 * fs));
    _qhp.set('hp', fs, 5.0);
    _qlp.set('lp', fs, math.min(15.0, 0.3 * fs));
    _useNotch = fs > 115;
    if (_useNotch) _notch.set('notch', fs, 50.0, 8.0);
  }

  // ───────────── وەرگرتن ─────────────
  /// پاکێتێکی نوێ لە نموونەکان. packetId: 0..255 (بۆ دۆزینەوەی پاکێتی ونبوو)
  void addPacket(List<int> samples, {DateTime? now, int? packetId}) {
    if (samples.isEmpty) return;
    // پاکێتی ونبوو ← نموونەی ناوەند دادەنرێت بۆ ئەوەی کات (و BPM) ڕاست بمێنێتەوە
    if (packetId != null) {
      final lastId = _lastId;
      _lastId = packetId;
      if (lastId != null) {
        final lost = (packetId - lastId - 1) & 0xff;
        if (lost > 0 && lost < 8 && _prev != null) {
          lostPackets += lost;
          final a = _prev!, b = samples.first;
          final k = (lost * (_pktAvg > 0 ? _pktAvg : samples.length)).round();
          for (var i = 1; i <= k; i++) {
            _push((a + (b - a) * i / (k + 1)).round());
          }
          _count += k;
        }
      }
    }
    _pktAvg = _pktAvg == 0 ? samples.length.toDouble() : 0.9 * _pktAvg + 0.1 * samples.length;
    final t = now ?? DateTime.now();
    _t0 ??= t;
    _lastPkt = t;
    _count += samples.length;
    final ts = t.difference(_t0!).inMicroseconds / 1e6;
    _arr.add((ts, _count));
    while (_arr.isNotEmpty && ts - _arr.first.$1 > 12.0) {
      _arr.removeAt(0);
    }
    _estimate();
    var same = 0;
    for (final s in samples) {
      if (_prev == s) same++;
      _push(s);
    }
    // هێڵی تەواو ڕاست (0 یان 0xFFFFFF) ← ئەلیکترۆد نییە
    final was = _railing;
    _railing = same >= samples.length - 1 && (samples.last == 0 || samples.last == 0xFFFFFF);
    if (was && !_railing) {
      // ئەلیکترۆد گەڕایەوە ← لە ئاستی نوێوە دەست پێبکە (بێ لەرینەوەی گەورە)
      _design(rate);
      _x0 = null;
    }
  }

  /// ڕێژەی نموونە: لێژیی least-squares ی (کاتی گەیشتن، کۆی نموونەکان)؛ 0.8 چرکەی یەکەم پشتگوێ دەخرێت
  void _estimate() {
    final pts = _arr.where((p) => p.$1 >= 0.8).toList();
    if (pts.length < 4) return;
    final span = pts.last.$1 - pts.first.$1;
    if (span < 3.0) return;
    var mt = 0.0, mc = 0.0;
    for (final p in pts) {
      mt += p.$1;
      mc += p.$2;
    }
    mt /= pts.length;
    mc /= pts.length;
    var sxx = 0.0, sxy = 0.0;
    for (final p in pts) {
      final dx = p.$1 - mt;
      sxx += dx * dx;
      sxy += dx * (p.$2 - mc);
    }
    if (sxx <= 0) return;
    final est = sxy / sxx;
    if (est < 40 || est > 1100) return;
    final dev = (est - rate).abs() / rate;
    if (!_locked) {
      if (dev <= 0.12) rateOk = true;
      if (dev > 0.35 && !_early) {
        _early = true; // بە ڕوونی ڕێژەیەکی ترە ← ئێستا بیگۆڕە، لە 6 چرکەدا وردتری بکە
        _relock(est.roundToDouble());
        return;
      }
      if (span >= 6.0) {
        _locked = true;
        if (dev > 0.04) _relock(est.roundToDouble());
        rateOk = true;
      }
    } else if (span >= 9.0 && dev > 0.06) {
      _relock(est.roundToDouble());
    }
  }

  void _relock(double fs) {
    final k = rate / fs;
    _rr.clear(); // بە فلتەری هەڵە دۆزرابوونەوە ← BPM دووبارە وەردەگیرێتەوە
    rrLog = [for (final x in rrLog) x * k];
    _lastR = -1e9;
    final old = sweep, oc = cursor;
    rate = fs;
    _design(fs);
    _x0 = null;
    _mwi.clear();
    _slw.clear();
    _mwiSum = 0;
    _cands.clear();
    _quiet = _n + (0.6 * fs).round();
    _learn = 0;
    _spki = _npki = 0;
    _lastSlope = 0;
    _slopes.clear();
    _rej.clear();
    final nw = _winFor(fs);
    if (nw != old.length) {
      // شاشە سفر نابێتەوە: ناوەڕۆکی پێشوو بۆ پانیی نوێ دەگوازرێتەوە
      sweep = List<double>.generate(nw, (i) => old[math.min(old.length - 1, i * old.length ~/ nw)]);
      cursor = math.min(nw - 1, (oc * nw / old.length).round());
    }
    _play.clear();
  }

  void _push(int raw) {
    // کۆتایی ماوەی دەستلێدان ← هێڵی بنەڕەت دووبارە لە ئاستی ئێستاوە (لەرینی دەستلێدان نامێنێت)
    if (_hold > 0 && _n == _hold) {
      _design(rate);
      _x0 = null;
    }
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
    if (_y.length > keep * 2) _y.removeRange(0, _y.length - keep);
    _detect(_qlp.run(_qhp.run(y)));

    // پەنجە: لادانی ستانداردی 1 چرکە
    _stdWin.add(y);
    _sSum += y;
    _sSq += y * y;
    final k1 = rate.round().clamp(20, 1000).toInt();
    while (_stdWin.length > k1) {
      final o = _stdWin.removeFirst();
      _sSum -= o;
      _sSq -= o * o;
    }

    // 6) نیشاندان
    final shown = _flip ? -y : y;
    _env = math.max(_env * math.pow(0.5, 1 / (rate * 2.5)).toDouble(), shown.abs());
    final scale = math.max(_env * 1.05, ampFloor);
    // سەرەتا و ماوەی دەستلێدان (0.5 چرکە) هێڵی ڕاست پیشان دەدرێت، نەک لەرینەوەی گەورە
    final v = (_n > rate * 0.5 && _n >= _hold) ? (shown / scale).clamp(-1.0, 1.0).toDouble() : 0.0;
    _play.addLast(v);
    final cap = (rate * 3).round();
    while (_play.length > cap) {
      _play.removeFirst();
    }
    _tape.add(v);
  }


  double _slopeRef() {
    if (_slopes.length < 3) return 0;
    final s = [..._slopes]..sort();
    return s[s.length ~/ 2];
  }

  double? _medRr() {
    if (_rr.length < 3) return null;
    final s = [..._rr]..sort();
    return s[s.length ~/ 2];
  }

  void _detect(double q) {
    final fs = rate;
    _d.add(q);
    final dd = _d[_d.length - 1] - _d[_d.length - 3];
    _d.removeAt(0);
    final s = dd * dd;
    final w = math.max(3, (0.12 * fs).round());
    _mwi.addLast(s);
    _slw.addLast(dd.abs());
    _mwiSum += s;
    while (_mwi.length > w) {
      _mwiSum -= _mwi.removeFirst();
      _slw.removeFirst();
    }
    final m = math.sqrt(math.max(0.0, _mwiSum) / _mwi.length);
    final settle = (fs * 0.8).round();
    final learnLen = (fs * 1.2).round();
    // وزەی شەپۆل لەناکاو زۆر بوو (پەنجە دانرا) ← سنوورە کۆنەکان بێسوودن، دووبارە فێربە
    _eFast += (m - _eFast) * (1.0 / (0.5 * fs));
    if (_learn < learnLen) {
      _learnE = math.max(_learnE, _eFast);
    } else if (_learnE > 0 && _eFast > 5 * _learnE && _n - _restartAt > 2 * fs) {
      restartLearning();
    }
    if (_since > 3 && _m1 > _m2 && _m1 >= m && _n >= math.max(_quiet, _hold)) {
      final pk = _m1;
      final idx = _n - 2;
      var slope = 0.0;
      for (final v in _slw) {
        if (v > slope) slope = v;
      }
      if (_since < settle) {
        // فلتەرەکان جێگیر دەبن
      } else if (_learn < learnLen) {
        _spki = math.max(_spki, pk);
        _npki = 0.5 * _npki + 0.05 * pk;
      } else {
        final thr = _npki + 0.45 * (_spki - _npki);
        final refr = 0.22 * fs;
        final dt = idx - _lastQrs;
        final sref = _slopeRef();
        if (pk > thr && dt > refr) {
          if (slope < 0.4 * sref) {
            // زۆر نەرمە بۆ QRS (نۆیز، P یان T)
            _npki = 0.125 * pk + 0.875 * _npki;
          } else if (dt < 0.42 * fs && slope < 0.5 * _lastSlope) {
            // شەپۆلی T (Pan–Tompkins): نزیکی QRS ی پێشوو و لێژییەکەی زۆر کەمترە
            _npki = 0.125 * pk + 0.875 * _npki;
          } else {
            _spki = 0.125 * pk + 0.875 * _spki;
            _lastSlope = slope;
            _slopes.add(slope);
            if (_slopes.length > 8) _slopes.removeAt(0);
            _qrs(idx);
            _cands.clear();
          }
        } else {
          _npki = 0.125 * pk + 0.875 * _npki;
          if (dt > 0.36 * fs) _cands.add((idx, pk, slope));
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
        if (best.$2 > 0.5 * thr && best.$3 >= 0.4 * _slopeRef()) {
          _spki = 0.25 * best.$2 + 0.75 * _spki;
          _lastSlope = best.$3;
          _qrs(best.$1);
        }
      }
    }
    // 2.5 چرکە هیچ لێدانێک نەبوو ← سنوورەکان زۆر بەرز بوون (بۆ نموونە لەرینی دەستلێدان)
    if (_learn >= learnLen && _n - math.max(_lastQrs, _idleMark) > 2.5 * fs) {
      _spki *= 0.5;
      _npki *= 0.5;
      _idleMark = _n;
    }
    if (_since >= settle && _n >= _hold) _learn++;
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
        final med = _medRr();
        if (med == null || (rr >= 0.65 * med && rr <= 1.5 * med)) {
          _rr.add(rr);
          if (_rr.length > 12) _rr.removeAt(0);
          rrLog.add(rr);
          _rej.clear();
        } else {
          // ڕیتم بەڕاستی گۆڕا (یان RR ـە کۆنەکان هەڵە بوون): 4 ڕەتکراوەی یەکگرتوو ← وەریانبگرە
          _rej.add(rr);
          if (_rej.length >= 4) {
            final tl = _rej.sublist(_rej.length - 4);
            final mm = tl.reduce((a, b) => a + b) / 4;
            var sd = 0.0;
            for (final x in tl) {
              sd += (x - mm) * (x - mm);
            }
            sd = math.sqrt(sd / 4);
            if (sd / mm < 0.15) {
              _rr
                ..clear()
                ..addAll(tl);
              rrLog.addAll(tl);
              _rej.clear();
            }
          }
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

  // ───────────── پەخشی نەرم بۆ شاشە ─────────────
  /// هەر فرەیمێک بانگ دەکرێت (~30/چرکە): نموونەکان بە خێرایی ڕاستەقینە لەسەر شاشە دەنووسرێن.
  /// ~0.15 چرکە پێشبار ← BLE ـی پارچە پارچە وەک خەتێکی بەردەوام و نەرم دەردەکەوێت.
  void advance([DateTime? now]) {
    final t = now ?? DateTime.now();
    final prev = _lastAdv;
    _lastAdv = t;
    if (prev == null) return;
    final dt = (t.difference(prev).inMicroseconds / 1e6).clamp(0.0, 0.1).toDouble();
    final q = _play.length / rate;
    if (!_playing) {
      if (q < 0.15) return;
      _playing = true;
    }
    var speed = 1.0;
    if (q > 1.2) {
      speed = 2.0; // زۆر دواکەوت ← خێراتر بگەڕێوە
    } else if (q > 0.5) {
      speed = 1.15;
    } else if (q < 0.06) {
      speed = 0.85;
    }
    _acc += rate * dt * speed;
    var k = _acc.floor();
    _acc -= k;
    if (k > _play.length) {
      k = _play.length;
      _acc = 0;
      _playing = false; // بەتاڵ بوو ← چاوەڕێی پێشبار
    }
    if (sweep.isEmpty) return;
    for (var i = 0; i < k; i++) {
      final v = _play.removeFirst();
      sweep[cursor] = v;
      last = v;
      cursor++;
      if (cursor >= sweep.length) {
        cursor = 0;
        sweepFull = true;
      }
    }
  }

  /// هەموو نموونە پڕۆسێسکراوە نوێیەکان (بۆ تۆمارکردنی ڕاپۆرت) — دوای خوێندنەوە بەتاڵ دەبێتەوە
  List<double> takeTape() {
    final t = _tape;
    _tape = <double>[];
    return t;
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
    if (_n < rate * 0.8) return false;
    final n = _stdWin.length;
    if (n < 2) return false;
    final m = _sSum / n;
    final v = _sSq / n - m * m;
    return math.sqrt(math.max(0.0, v)) > minStd;
  }

  /// BPM ی زیندوو (null تا ڕێژە پشتڕاست بێتەوە و 3 RR ی دروست)
  double? get bpm {
    if (!rateOk || _rr.length < 3) return null;
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
