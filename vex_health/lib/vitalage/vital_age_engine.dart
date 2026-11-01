// VEX Health — تەمەنی ژیانی (VitalAge): کۆکردنەوەی ٢١ ڕۆژ + ژماردن
//
// داتا لە VexBand.I دێت (J-STYLE V8 SDK): هەنگاو (0x51)، دڵی ئارام (0x55)، HRV (0x56)، خەو (0x53).
// ڕۆژێک «تەواو» دەژمێردرێت کاتێک خەو + هەنگاو + (دڵی ئارام یان HRV) هەبێت.
// ٢١ ڕۆژی تەواو پێویستە (پێویست نییە بەدوای یەکدا بن).
//
// ⚠️ ئەمە خەمڵاندنێکی تەندروستیی گشتییە (wellness)، نەک پشکنینی پزیشکی.
//    فۆرمولەکە لە خوارەوە ڕوونە و دەتوانرێت بگۆڕدرێت (کۆنستانتەکان).
import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../band/ble/vex_ble.dart';
import '../band/ble/vex_parsers.dart';
import '../onboarding/account.dart';
import '../onboarding/reg_data.dart' show asI;

class VitalDay {
  double? sleepMin; // کۆی کاتی خەو (خولەک)
  int? steps;
  int? restHr;
  int? hrv;
  VitalDay({this.sleepMin, this.steps, this.restHr, this.hrv});

  bool get complete => sleepMin != null && steps != null && (restHr != null || hrv != null);

  Map<String, dynamic> toJson() => {
        if (sleepMin != null) 's': sleepMin,
        if (steps != null) 'p': steps,
        if (restHr != null) 'h': restHr,
        if (hrv != null) 'v': hrv,
      };

  factory VitalDay.fromJson(Map j) => VitalDay(
        sleepMin: (j['s'] as num?)?.toDouble(),
        steps: (j['p'] as num?)?.toInt(),
        restHr: (j['h'] as num?)?.toInt(),
        hrv: (j['v'] as num?)?.toInt(),
      );
}

/// یەک هۆکار لە ئەنجامدا
class VitalFactor {
  final String key; // sleep | hr | hrv | steps
  final String label;
  final double years; // − = گەنجتر، + = پیرتر
  final String detail;
  const VitalFactor(this.key, this.label, this.years, this.detail);
}

class VitalResult {
  final double age; // تەمەنی ژیانی
  final int realAge;
  final double delta; // age - realAge
  final List<VitalFactor> factors;
  final int days;
  const VitalResult(this.age, this.realAge, this.delta, this.factors, this.days);
}

class VitalAgeEngine extends ChangeNotifier {
  VitalAgeEngine._();
  static final VitalAgeEngine I = VitalAgeEngine._();

  static const int need = 21; // ڕۆژی پێویست
  static const String _kDays = 'vex_va_days';
  static const String _kBirth = 'vex_va_birth';

  final Map<String, VitalDay> _days = {};
  DateTime? birth;
  SharedPreferences? _sp;
  Timer? _deb;
  bool _inited = false;

  /// تەنها بۆ تاقیکردنەوەی دیزاین (debug) — ئەنجام بە داتای ساختە
  bool preview = false;

  static String key(DateTime t) =>
      '${t.year}-${t.month.toString().padLeft(2, '0')}-${t.day.toString().padLeft(2, '0')}';

  /// داتای ڕۆژێک (بۆ خوێندنەوە، بۆ نموونە خەوی ئەمڕۆ لە VEX Arena)
  VitalDay? dayOf(DateTime t) => _days[key(t)];

  Future<void> init() async {
    if (_inited) return;
    _inited = true;
    try {
      final sp = await SharedPreferences.getInstance();
      _sp = sp;
      final raw = sp.getString(_kDays);
      if (raw != null) {
        final j = jsonDecode(raw);
        if (j is Map) {
          j.forEach((k, v) {
            if (v is Map) _days[k as String] = VitalDay.fromJson(v);
          });
        }
      }
      final b = sp.getString(_kBirth);
      if (b != null) birth = DateTime.tryParse(b);
    } catch (_) {}
    VexBand.I.addListener(_onBand);
    notifyListeners();
  }

  // ───────────── تەمەن ─────────────
  int get realAge {
    final b = birth;
    if (b != null) {
      final n = DateTime.now();
      var a = n.year - b.year;
      if (n.month < b.month || (n.month == b.month && n.day < b.day)) a--;
      return a < 0 ? 0 : (a > 120 ? 120 : a);
    }
    return asI(Account.I.user?['age']);
  }

  bool get hasAge => realAge >= 10;

  Future<void> setBirth(DateTime d) async {
    birth = d;
    try {
      await _sp?.setString(_kBirth, d.toIso8601String());
    } catch (_) {}
    notifyListeners();
  }

  // ───────────── کۆکردنەوە ─────────────
  void _onBand() {
    _deb?.cancel();
    _deb = Timer(const Duration(seconds: 2), () => ingest(VexBand.I));
  }

  void ingest(VexBand b) {
    var changed = false;
    VitalDay d(DateTime t) => _days.putIfAbsent(key(t), () => VitalDay());
    final today = DateTime.now();
    bool ok(DateTime? t) => t != null && !t.isAfter(today.add(const Duration(days: 1))) && today.difference(t).inDays < 60;

    for (final s in b.stepsDays) {
      if (!ok(s.day) || s.steps <= 0) continue;
      final x = d(s.day!);
      if (x.steps != s.steps) {
        x.steps = s.steps;
        changed = true;
      }
    }

    final hr = <String, List<int>>{};
    for (final s in b.hrRest) {
      if (!ok(s.at)) continue;
      final v = s.value.round();
      if (v >= 35 && v <= 130) (hr[key(s.at!)] ??= []).add(v);
    }
    hr.forEach((k, l) {
      l.sort();
      final low = l.sublist(0, (l.length / 2).ceil()); // نیوەی نزمتر = دڵی ئارام
      final v = low[low.length ~/ 2];
      final x = _days.putIfAbsent(k, () => VitalDay());
      if (x.restHr != v) {
        x.restHr = v;
        changed = true;
      }
    });

    final hv = <String, List<int>>{};
    for (final r in b.hrvHist) {
      if (!ok(r.at) || r.hrv <= 0) continue;
      (hv[key(r.at!)] ??= []).add(r.hrv);
    }
    hv.forEach((k, l) {
      final v = (l.reduce((a, c) => a + c) / l.length).round();
      final x = _days.putIfAbsent(k, () => VitalDay());
      if (x.hrv != v) {
        x.hrv = v;
        changed = true;
      }
    });

    // خەو: هەر تۆمارێک = ژمارەی یەکەکانی (قووڵ/سووک/REM) × درێژی یەکە. ڕۆژەکە = ڕۆژی کۆتایی خەو.
    final sl = <String, double>{};
    for (final r in b.sleepHist) {
      final st = r.start;
      if (st == null || r.quality.isEmpty) continue;
      final end = st.add(Duration(minutes: r.quality.length * r.unitMinutes));
      if (!ok(end)) continue;
      // بەپێی دۆکیومێنتی SDK: 1 = قووڵ، 2 = سووک، 3 = REM، هەر شتێکی تر = بێدار
      final asleep = r.quality.where((q) => q >= 1 && q <= 3).length * r.unitMinutes;
      sl[key(end)] = (sl[key(end)] ?? 0) + asleep;
    }
    sl.forEach((k, v) {
      if (v < 30 || v > 16 * 60) return;
      final x = _days.putIfAbsent(k, () => VitalDay());
      if (x.sleepMin != v) {
        x.sleepMin = v;
        changed = true;
      }
    });

    if (changed) _save();
  }

  void _save() {
    // تەنها ٦٠ ڕۆژی دوایی
    final keys = _days.keys.toList()..sort();
    while (keys.length > 60) {
      _days.remove(keys.removeAt(0));
    }
    try {
      _sp?.setString(_kDays, jsonEncode(_days.map((k, v) => MapEntry(k, v.toJson()))));
    } catch (_) {}
    notifyListeners();
  }

  /// ڕۆژە تەواوەکان (نوێترین یەکەم)
  List<MapEntry<String, VitalDay>> get completeDays {
    final l = _days.entries.where((e) => e.value.complete).toList()..sort((a, b) => b.key.compareTo(a.key));
    return l;
  }

  int get collected => preview ? need : (completeDays.length > need ? need : completeDays.length);
  int get remaining => need - collected;
  double get progress => collected / need;
  bool get ready => collected >= need && hasAge;

  /// ئایا ئەمڕۆ هەر یەک لە چوار بەشەکە هەیە؟
  Map<String, bool> get today {
    final x = _days[key(DateTime.now())];
    // خەوی ئەمڕۆ = شەوی ڕابردوو (ڕۆژی کۆتایی خەو = ئەمڕۆ)
    return {
      'sleep': x?.sleepMin != null,
      'hr': x?.restHr != null,
      'hrv': x?.hrv != null,
      'steps': x?.steps != null,
    };
  }

  /// ٢١ خانەی ڕۆژ (کۆن ← نوێ): true = ڕۆژی تەواو
  List<bool> get cells {
    if (preview) return List<bool>.filled(need, true);
    final f = List<bool>.filled(need, false);
    for (var i = 0; i < collected; i++) {
      f[i] = true;
    }
    return f;
  }

  /// بەروارێکی خەمڵێنراو بۆ کردنەوە (ئەگەر هەموو ڕۆژێک داتا هەبێت)
  DateTime get eta => DateTime.now().add(Duration(days: remaining));

  // ───────────── ژماردن ─────────────
  VitalResult? compute() {
    if (!ready) return null;
    final ds = preview ? _demo() : completeDays.take(need).map((e) => e.value).toList();
    double avg(Iterable<num> l) => l.isEmpty ? double.nan : l.reduce((a, b) => a + b) / l.length;
    final sleepH = avg(ds.map((d) => d.sleepMin!)) / 60.0;
    final steps = avg(ds.map((d) => d.steps!));
    final rhrL = ds.where((d) => d.restHr != null).map((d) => d.restHr!);
    final hrvL = ds.where((d) => d.hrv != null).map((d) => d.hrv!);
    final rhr = avg(rhrL);
    final hrv = avg(hrvL);
    final a = realAge;

    final f = <VitalFactor>[];

    // خەو: ٧–٨ کاتژمێر = ٠. کەمتر/زیاتر = پیرتر
    double ys;
    if (sleepH >= 7 && sleepH <= 8.5) {
      ys = -0.8;
    } else if (sleepH < 7) {
      ys = ((7 - sleepH) * 1.6).clamp(0.0, 4.5).toDouble();
    } else {
      ys = ((sleepH - 8.5) * 1.0).clamp(0.0, 2.5).toDouble();
    }
    f.add(VitalFactor('sleep', 'خەو', ys, '${sleepH.toStringAsFixed(1)} کاتژمێر / شەو'));

    // دڵی ئارام: ٦٠ = ٠؛ هەر ٥ لێدان زیاتر = +١ ساڵ؛ هەر ٥ کەمتر = −٠.٨
    if (!rhr.isNaN) {
      final dlt = rhr - 60;
      final y = (dlt >= 0 ? dlt / 5 : dlt / 5 * 0.8).clamp(-4.0, 6.0).toDouble();
      f.add(VitalFactor('hr', 'دڵی ئارام', y, '${rhr.round()} bpm'));
    }

    // HRV: بەپێی تەمەن (پێوەرەکە بەپێی Band ـەکەیە — لە 10 تا 100). بنەڕەت = 75 − 0.6×(تەمەن−20)
    if (!hrv.isNaN) {
      final base = (75 - 0.6 * (a - 20)).clamp(25.0, 75.0).toDouble();
      final y = (-(hrv - base) / 10).clamp(-3.5, 3.5).toDouble();
      f.add(VitalFactor('hrv', 'HRV', y, '${hrv.round()} ms'));
    }

    // هەنگاو: ≥١٠٠٠٠ = −٢، ٧٥٠٠ = −١، ٥٠٠٠ = ٠، ≤٢٠٠٠ = +٣
    double yp;
    if (steps >= 10000) {
      yp = -2;
    } else if (steps >= 5000) {
      yp = -2 + (10000 - steps) / 5000 * 2;
    } else {
      yp = ((5000 - steps) / 3000).clamp(0.0, 3.0).toDouble();
    }
    f.add(VitalFactor('steps', 'هەنگاو', yp, '${steps.round()} هەنگاو / ڕۆژ'));

    final sum = f.fold<double>(0, (s, e) => s + e.years).clamp(-12.0, 15.0).toDouble();
    return VitalResult(a + sum, a, sum, f, ds.length);
  }

  List<VitalDay> _demo() => List.generate(
      need, (i) => VitalDay(sleepMin: 6.6 * 60 + (i % 5) * 12, steps: 6500 + (i % 7) * 600, restHr: 62 + i % 4, hrv: 52 + i % 9));

  /// بۆ تاقیکردنەوەی دیزاین لە debug
  void togglePreview() {
    preview = !preview;
    if (preview && birth == null && !hasAge) birth = DateTime(DateTime.now().year - 30, 1, 1);
    notifyListeners();
  }
}
