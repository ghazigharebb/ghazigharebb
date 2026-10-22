// VEX Band — پڕۆسێسکردنی شەپۆلی ECG ی زیندوو
//
// سەرچاوە: Band شەپۆلی خاو بە پاکێتی 0x07 دەنێرێت (SDK: setECGRealtimeDuringHRVEnabled).
// هەر نموونەیەک ٣ بایتە (little-endian). ئەم کلاسە:
//   • بازنەی بەرزی (DC) لادەبات و شەپۆلەکە ئاسایی دەکات (-1..1)
//   • دۆزینەوەی پەنجە (contact) دەکات
//   • لێدانەکان دەدۆزێتەوە و BPM ی زیندوو دەژمێرێت
// هەموو کۆنستانتەکان لێرە ڕێکخراون؛ ئەگەر شەپۆلەکە هەڵگەڕاوە بوو `invert = true` بکە.
import 'dart:math' as math;

class EcgSignal {
  EcgSignal({this.defaultRate = 50, this.seconds = 5, this.invert = false}) {
    rate = defaultRate;
    reset();
  }

  // ── ڕێکخستنەکان ──
  /// ڕێژەی نموونە لە چرکەیەکدا پێش خەمڵاندن (نموونەی فرۆشیار: 50)
  final double defaultRate;

  /// چەند چرکە لەسەر شاشە نیشان بدرێت
  final double seconds;

  /// ئەگەر لێدانەکان بەرەو خوارەوە دەچن
  bool invert;

  /// کەمترین لادانی ستانداردی خاو بۆ ئەوەی پەنجە دابنرێت
  static const double minStd = 0.8;
  static const double dcAlpha = 0.03;
  static const double ampDecay = 0.994;

  /// کەمترین قەبارەی ئاماژە بۆ ئاسایی‌کردن — بێ پەنجە، نۆیز گەورە نانوێنرێت و خەتەکە ڕاست دەمێنێتەوە
  static const double ampFloor = 40.0;

  late double rate;
  final List<double> disp = <double>[]; // نیشاندان
  final List<double> _rawWin = <double>[];
  final List<int> _beats = <int>[]; // ئیندێکسی لێدانەکان
  final List<double> _rr = <double>[]; // چرکە

  int _n = 0;
  int _lastBeat = -1000000;
  bool _init = false;
  double _dc = 0, _lp = 0, _amp = 1e-6;
  double _v1 = 0, _v2 = 0;
  DateTime? _t0, _lastPkt;
  int _count = 0;

  /// نەختەی ئەنیمەیشن: چەند جار لێدانێک دۆزرایەوە
  int beatCount = 0;
  bool beatNow = false; // true تا خوێندنەوەی دواتر

  int get window => (seconds * rate).round().clamp(60, 2000);

  void reset() {
    disp
      ..clear()
      ..addAll(List<double>.filled(window, 0));
    _rawWin.clear();
    _beats.clear();
    _rr.clear();
    _n = 0;
    _lastBeat = -1000000;
    _init = false;
    _dc = 0;
    _lp = 0;
    _amp = 1e-6;
    _v1 = _v2 = 0;
    _t0 = _lastPkt = null;
    _count = 0;
    beatCount = 0;
    beatNow = false;
    rate = defaultRate;
  }

  /// پاکێتێکی نوێ لە نموونەکان
  void addPacket(List<int> samples, {DateTime? now}) {
    if (samples.isEmpty) return;
    final t = now ?? DateTime.now();
    _t0 ??= t;
    _lastPkt = t;
    for (final s in samples) {
      _push(s.toDouble());
    }
    _count += samples.length;
    final el = t.difference(_t0!).inMicroseconds / 1e6;
    if (el > 2.0) {
      final r = _count / el;
      rate = (rate * 0.9 + r.clamp(20.0, 500.0) * 0.1);
    }
    final w = window;
    if (disp.length > w) disp.removeRange(0, disp.length - w);
  }

  void _push(double x) {
    _n++;
    if (!_init) {
      _dc = x;
      _init = true;
    }
    _dc += (x - _dc) * dcAlpha;
    final y = (x - _dc) * (invert ? -1 : 1);
    _lp += (y - _lp) * 0.4;
    final a = _lp.abs();
    _amp = math.max(_amp * ampDecay, a);
    final v = (_lp / (_amp < ampFloor ? ampFloor : _amp)).clamp(-1.0, 1.0).toDouble();
    disp.add(v);

    // پەنجە: نموونەی خاو
    _rawWin.add(x);
    final keep = rate.round().clamp(20, 500);
    if (_rawWin.length > keep) _rawWin.removeRange(0, _rawWin.length - keep);

    // دۆزینەوەی لێدان (لوتکە)
    if (_n > 3 && _v2 < _v1 && _v1 >= v && _v1 > 0.5 && (_n - 1 - _lastBeat) > _refractory() * rate) {
      final idx = _n - 1;
      if (_lastBeat > 0) {
        final rr = (idx - _lastBeat) / rate;
        if (rr > 0.3 && rr < 1.7) {
          _rr.add(rr);
          if (_rr.length > 8) _rr.removeAt(0);
        }
      }
      _lastBeat = idx;
      _beats.add(idx);
      beatCount++;
      beatNow = true;
    }
    _v2 = _v1;
    _v1 = v;
  }

  /// کەمترین ماوە لە نێوان دوو لێدان (چرکە) — بۆ نەگرتنی لوتکەی دووەمی شەپۆل (dicrotic)
  double _refractory() {
    if (_rr.length >= 3) {
      final s = [..._rr]..sort();
      return math.max(0.3, 0.6 * s[s.length ~/ 2]);
    }
    return 0.4;
  }

  /// ئایا پەنجە لەسەر ئەلیکترۆدە؟
  bool contact([DateTime? now]) {
    final t = now ?? DateTime.now();
    final lp = _lastPkt;
    if (lp == null || t.difference(lp).inMilliseconds > 1500) return false;
    if (_rawWin.length < (rate * 0.6)) return false;
    return _std(_rawWin) > minStd;
  }

  /// BPM ی زیندوو (null تا لێدانی پێویست دۆزرایەوە)
  double? get bpm {
    if (_rr.length < 3) return null;
    final s = [..._rr]..sort();
    final med = s[s.length ~/ 2];
    final b = 60.0 / med;
    return (b >= 35 && b <= 200) ? b : null;
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

/// شەپۆلی دەستکرد بۆ تاقیکردنەوەی دیزاین بەبێ Band (تەنها debug)
double ecgSynth(double t, {double bpm = 72}) {
  final period = 60.0 / bpm;
  final p = (t % period) / period; // 0..1
  double g(double c, double w, double a) => a * math.exp(-math.pow((p - c) / w, 2).toDouble());
  return g(.16, .035, .12) - g(.285, .008, .10) + g(.30, .010, 1.0) - g(.325, .010, .22) + g(.52, .055, .28);
}
