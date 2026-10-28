// VEX Health — ڕاپۆرتی گشتی (general_report.dart)
//
// ڕاپۆرتێکی تەواوی تەندروستی بۆ 30 ڕۆژی ڕابردوو، بە دیزاینی کلینیکی (A)، لە 6 زمان و
// ڕووناک/تاریک/خۆکار، لەگەڵ داگرتنی PDF (A4).
//
// سەرچاوەی داتا (هەمووی ڕاستەقینەیە، هیچ ژمارەیەکی ساختە نییە):
//   • VEX Band (BLE · J-STYLE V8 SDK) ← VexBand.I: هەنگاو 0x51، دڵ 0x55 + 0x54، SpO₂ 0x66،
//     پلەی گەرمی 0x65، HRV/سترێس/هەناسە 0x56، خەو 0x53، Realtime 0x09، پێوانەی دەستی (پەستان).
//     ReportStore هەموو ئەوانە ڕۆژانە کۆدەکاتەوە و لە مۆبایلەکە هەڵیدەگرێت (120 ڕۆژ)،
//     بۆیە دوای داخستنی ئەپیش ڕاپۆرتەکە داتاکەی هەیە.
//   • ECG ← EcgHistory (هەمان پێوانەکانی بەشی ECG، لەگەڵ شەپۆلی ڕاستەقینە)
//   • خواردن، ئاو و کێش ← بەشی خواردن (vexfd_v1) یان تۆماری ئەمڕۆی سەرەکی (Store)
//   • ناو، تەمەن، باڵا، کێش، دۆخی تەندروستی ← هەژمار (Account)
//   • تەمەنی لەش ← VitalAgeEngine (21 ڕۆژ)
//
// دانان:
//   1) main.dart  → await ReportStore.I.init();   (دوای VitalAgeEngine.I.init، پێش VexBand.I.init)
//   2) پرۆفایل    → const ReportCard()             (کارتەکە خۆی ڕاپۆرتەکە دەکاتەوە)
//   3) یان لە هەر شوێنێک: openGeneralReport();
import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../band/band_state.dart';
import '../band/ble/vex_ble.dart';
import '../band/ble/vex_parsers.dart';
import '../core/store.dart';
import '../core/theme.dart';
import '../ecg/ecg_controller.dart';
import '../ecg/ecg_history.dart';
import '../health/hc.dart' show pushPage;
import '../onboarding/account.dart';
import '../onboarding/reg_data.dart' show asD, asI;
import '../onboarding/reg_lang_state.dart';
import '../vitalage/vital_age_engine.dart';

/// کردنەوەی ڕاپۆرتی گشتی
Future<void> openGeneralReport() async {
  await ReportStore.I.init();
  await pushPage(const GeneralReportPage());
}

// ═════════════════════════════ زمان ═════════════════════════════
Map get _T => (_kTX[LangState.I.code] ?? _kTX['ckb']) as Map;
Map get _T0 => _kTX['ckb'] as Map;
String _t(String k) => '${_T[k] ?? _T0[k] ?? k}';
String _g(String grp, String k) => '${(_T[grp] as Map?)?[k] ?? (_T0[grp] as Map?)?[k] ?? k}';
List<String> _lv() => ((_T['lv'] ?? _T0['lv']) as List).map((e) => '$e').toList();
String _f(String s, Map<String, Object?> o) => s.replaceAllMapped(RegExp(r'\{(\w+)\}'), (m) => '${o[m.group(1)] ?? ''}');
bool get _rtl => '${_T['dir']}' != 'ltr';
TextDirection get _dir => _rtl ? TextDirection.rtl : TextDirection.ltr;
String _join(List<String> a) {
  if (a.isEmpty) return '';
  if (a.length == 1) return a.first;
  return a.sublist(0, a.length - 1).join(_t('sep')) + _t('and') + a.last;
}

String _p2(int n) => n.toString().padLeft(2, '0');
String _key(DateTime d) => '${d.year}-${_p2(d.month)}-${_p2(d.day)}';
String _dmy(DateTime d) => '${_p2(d.day)}.${_p2(d.month)}.${d.year}';
String _f1(num v) => ((v * 10).round() / 10).toStringAsFixed(1);
String _hm(num min) {
  var h = min ~/ 60;
  var m = (min % 60).round();
  if (m == 60) {
    h++;
    m = 0;
  }
  return '${h}h ${_p2(m)}m';
}

double? _avg(Iterable<num> l) => l.isEmpty ? null : l.fold<double>(0, (a, b) => a + b) / l.length;

// ═════════════════════════════ کۆگای داتای Band ═════════════════════════════
/// کورتەی یەک ڕۆژ لە داتای Band
class RDay {
  double? hrA, sp, tp, km, kc;
  int? hrN, hrX, rhr, spN, hrv, st, br, sl, dp, lt, rm, aw, bed, wake, stp, act, bpH, bpL;

  RDay();

  bool get any => hrA != null || sp != null || tp != null || hrv != null || st != null || sl != null || stp != null;

  Map<String, dynamic> toJson() {
    final m = <String, dynamic>{};
    void s(String k, Object? v) {
      if (v != null) m[k] = v is double ? double.parse(v.toStringAsFixed(2)) : v;
    }

    s('ha', hrA);
    s('hn', hrN);
    s('hx', hrX);
    s('rh', rhr);
    s('sp', sp);
    s('sn', spN);
    s('tp', tp);
    s('hv', hrv);
    s('st', st);
    s('br', br);
    s('sl', sl);
    s('dp', dp);
    s('lt', lt);
    s('rm', rm);
    s('aw', aw);
    s('bd', bed);
    s('wk', wake);
    s('pt', stp);
    s('km', km);
    s('kc', kc);
    s('ac', act);
    s('bh', bpH);
    s('bl', bpL);
    return m;
  }

  factory RDay.fromJson(Map j) {
    double? d(String k) => (j[k] as num?)?.toDouble();
    int? i(String k) => (j[k] as num?)?.round();
    return RDay()
      ..hrA = d('ha')
      ..hrN = i('hn')
      ..hrX = i('hx')
      ..rhr = i('rh')
      ..sp = d('sp')
      ..spN = i('sn')
      ..tp = d('tp')
      ..hrv = i('hv')
      ..st = i('st')
      ..br = i('br')
      ..sl = i('sl')
      ..dp = i('dp')
      ..lt = i('lt')
      ..rm = i('rm')
      ..aw = i('aw')
      ..bed = i('bd')
      ..wake = i('wk')
      ..stp = i('pt')
      ..km = d('km')
      ..kc = d('kc')
      ..act = i('ac')
      ..bpH = i('bh')
      ..bpL = i('bl');
  }

  /// تێکەڵکردن: تەنها خانە پڕەکانی [o] دەنووسرێن
  void merge(RDay o) {
    hrA = o.hrA ?? hrA;
    hrN = o.hrN ?? hrN;
    hrX = o.hrX ?? hrX;
    rhr = o.rhr ?? rhr;
    sp = o.sp ?? sp;
    spN = o.spN ?? spN;
    tp = o.tp ?? tp;
    hrv = o.hrv ?? hrv;
    st = o.st ?? st;
    br = o.br ?? br;
    sl = o.sl ?? sl;
    dp = o.dp ?? dp;
    lt = o.lt ?? lt;
    rm = o.rm ?? rm;
    aw = o.aw ?? aw;
    bed = o.bed ?? bed;
    wake = o.wake ?? wake;
    if (o.stp != null && (stp == null || o.stp! >= stp! || o.km != null)) {
      stp = o.stp;
      km = o.km ?? km;
      kc = o.kc ?? kc;
      act = o.act ?? act;
    }
    bpH = o.bpH ?? bpH;
    bpL = o.bpL ?? bpL;
  }
}

/// هەموو داتای Band بۆ ڕاپۆرت کۆدەکاتەوە و هەڵیدەگرێت (هەمیشە کار دەکات، تەنانەت ئەگەر ڕاپۆرت نەکرابێتەوە)
class ReportStore extends ChangeNotifier {
  ReportStore._();
  static final ReportStore I = ReportStore._();

  static const String _kDays = 'vex_report_days_v1';
  static const String _kHist = 'vex_report_hist_v1';
  static const int keepDays = 120;

  final Map<String, RDay> days = {};
  final Map<String, int> scoreHist = {};
  SharedPreferences? _sp;
  bool _inited = false;
  Timer? _deb;
  StreamSubscription<VexMsg>? _raw;

  Future<void> init() async {
    if (_inited) return;
    _inited = true;
    try {
      final sp = await SharedPreferences.getInstance();
      _sp = sp;
      final raw = sp.getString(_kDays);
      if (raw != null && raw.isNotEmpty) {
        final j = jsonDecode(raw);
        if (j is Map) {
          j.forEach((k, v) {
            if (v is Map) days['$k'] = RDay.fromJson(v);
          });
        }
      }
      final h = sp.getString(_kHist);
      if (h != null && h.isNotEmpty) {
        final j = jsonDecode(h);
        if (j is Map) {
          j.forEach((k, v) {
            if (v is num) scoreHist['$k'] = v.round();
          });
        }
      }
    } catch (_) {}
    VexBand.I.addListener(_onBand);
    _raw = VexBand.I.raw.stream.listen(_onMsg, onError: (_) {});
    ingest(VexBand.I);
    notifyListeners();
  }

  void _onBand() {
    _deb?.cancel();
    _deb = Timer(const Duration(seconds: 2), () => ingest(VexBand.I));
  }

  /// پێوانەی دەستیی پەستانی خوێن (ئەگەر Band بینێرێت)
  void _onMsg(VexMsg m) {
    if (m is VexMeasureResult && !m.stopped && m.high >= 70 && m.high <= 230 && m.low >= 40 && m.low < m.high) {
      final k = _key(DateTime.now());
      final d = days.putIfAbsent(k, RDay.new);
      d.bpH = m.high;
      d.bpL = m.low;
      _save();
    }
  }

  /// کۆکردنەوەی هەموو مێژووی Band (دوای هەر هاوکاتکردنێک)
  void ingest(VexBand b) {
    final now = DateTime.now();
    bool ok(DateTime? t) => t != null && !t.isAfter(now.add(const Duration(days: 1))) && now.difference(t).inDays < keepDays;
    final n = <String, RDay>{};
    RDay d(DateTime t) => n.putIfAbsent(_key(t), RDay.new);

    for (final s in b.stepsDays) {
      if (!ok(s.day) || s.steps <= 0) continue;
      final x = d(s.day!);
      x.stp = s.steps;
      x.km = s.km;
      x.kc = s.kcal;
      x.act = s.minutes;
    }
    final lv = b.live;
    if (lv != null && lv.steps > 0) {
      final x = d(now);
      if ((x.stp ?? 0) <= lv.steps) {
        x.stp = lv.steps;
        x.km = lv.km;
        x.kc = lv.kcal;
        x.act = lv.minutes;
      }
    }

    final hr = <String, List<int>>{}, rest = <String, List<int>>{};
    for (final s in b.hrRest) {
      if (!ok(s.at)) continue;
      final v = s.value.round();
      if (v < 30 || v > 220) continue;
      (hr[_key(s.at!)] ??= []).add(v);
      (rest[_key(s.at!)] ??= []).add(v);
    }
    for (final r in b.hrDyn) {
      if (!ok(r.at)) continue;
      for (final v in r.bpm) {
        if (v >= 30 && v <= 220) (hr[_key(r.at!)] ??= []).add(v);
      }
    }
    hr.forEach((k, l) {
      final x = n.putIfAbsent(k, RDay.new);
      x.hrA = _avg(l);
      x.hrN = l.reduce(math.min);
      x.hrX = l.reduce(math.max);
    });
    rest.forEach((k, l) {
      l.sort();
      final low = l.sublist(0, (l.length / 2).ceil());
      n.putIfAbsent(k, RDay.new).rhr = low[low.length ~/ 2];
    });

    final sp = <String, List<int>>{};
    for (final s in b.spo2Hist) {
      if (!ok(s.at)) continue;
      final v = s.value.round();
      if (v >= 70 && v <= 100) (sp[_key(s.at!)] ??= []).add(v);
    }
    sp.forEach((k, l) {
      final x = n.putIfAbsent(k, RDay.new);
      x.sp = _avg(l);
      x.spN = l.reduce(math.min);
    });

    final tp = <String, List<double>>{};
    for (final s in b.tempHist) {
      if (!ok(s.at)) continue;
      if (s.value >= 28 && s.value <= 42) (tp[_key(s.at!)] ??= []).add(s.value);
    }
    tp.forEach((k, l) => n.putIfAbsent(k, RDay.new).tp = _avg(l));

    final hv = <String, List<int>>{}, st = <String, List<int>>{}, br = <String, List<int>>{};
    for (final r in b.hrvHist) {
      if (!ok(r.at)) continue;
      final k = _key(r.at!);
      if (r.hrv > 0 && r.hrv < 300) (hv[k] ??= []).add(r.hrv);
      if (r.stress > 0 && r.stress <= 100) (st[k] ??= []).add(r.stress);
      if (r.breath >= 5 && r.breath <= 40) (br[k] ??= []).add(r.breath);
    }
    hv.forEach((k, l) => n.putIfAbsent(k, RDay.new).hrv = _avg(l)!.round());
    st.forEach((k, l) => n.putIfAbsent(k, RDay.new).st = _avg(l)!.round());
    br.forEach((k, l) => n.putIfAbsent(k, RDay.new).br = _avg(l)!.round());

    // خەو: ڕۆژەکە = ڕۆژی کۆتایی خەو. 1 قووڵ، 2 سووک، 3 REM، هەر شتێکی تر بێدار (SDK)
    final sl = <String, List<int>>{};
    final bed = <String, DateTime>{}, wake = <String, DateTime>{};
    for (final r in b.sleepHist) {
      final s0 = r.start;
      if (s0 == null || r.quality.isEmpty || r.unitMinutes <= 0) continue;
      final end = s0.add(Duration(minutes: r.quality.length * r.unitMinutes));
      if (!ok(end)) continue;
      final k = _key(end);
      final a = sl[k] ??= [0, 0, 0, 0];
      for (final q in r.quality) {
        final i = q == 1 ? 0 : (q == 2 ? 1 : (q == 3 ? 2 : 3));
        a[i] += r.unitMinutes;
      }
      if (bed[k] == null || s0.isBefore(bed[k]!)) bed[k] = s0;
      if (wake[k] == null || end.isAfter(wake[k]!)) wake[k] = end;
    }
    sl.forEach((k, a) {
      final asleep = a[0] + a[1] + a[2];
      if (asleep < 30 || asleep > 16 * 60) return;
      final x = n.putIfAbsent(k, RDay.new);
      x.dp = a[0];
      x.lt = a[1];
      x.rm = a[2];
      x.aw = a[3];
      x.sl = asleep;
      final bd = bed[k], wk = wake[k];
      if (bd != null) x.bed = bd.hour * 60 + bd.minute;
      if (wk != null) x.wake = wk.hour * 60 + wk.minute;
    });

    if (n.isEmpty) return;
    var changed = false;
    n.forEach((k, v) {
      final cur = days[k];
      if (cur == null) {
        if (v.any || v.bpH != null) {
          days[k] = v;
          changed = true;
        }
      } else {
        final before = jsonEncode(cur.toJson());
        cur.merge(v);
        if (jsonEncode(cur.toJson()) != before) changed = true;
      }
    });
    if (changed) _save();
  }

  void _save() {
    final keys = days.keys.toList()..sort();
    while (keys.length > keepDays) {
      days.remove(keys.removeAt(0));
    }
    try {
      _sp?.setString(_kDays, jsonEncode(days.map((k, v) => MapEntry(k, v.toJson()))));
    } catch (_) {}
    notifyListeners();
  }

  /// نمرەی مانگی ئێستا هەڵدەگرێت و نمرەی مانگی پێشوو دەگەڕێنێتەوە
  int? recordScore(int score) {
    final mon = _key(DateTime.now()).substring(0, 7);
    final prev = scoreHist.keys.where((k) => k.compareTo(mon) < 0).toList()..sort();
    final p = prev.isEmpty ? null : scoreHist[prev.last];
    if (scoreHist[mon] != score) {
      scoreHist[mon] = score;
      try {
        _sp?.setString(_kHist, jsonEncode(scoreHist));
      } catch (_) {}
    }
    return p;
  }

  @override
  void dispose() {
    _raw?.cancel();
    super.dispose();
  }
}

// ═════════════════════════════ ژماردنی ڕاپۆرت ═════════════════════════════
class _Flag {
  const _Flag(this.k, this.t);
  final String k; // ok | hi | lo | na
  final String t;
}

_Flag _fl(String k) => _Flag(k, _t(k));
_Flag _fx(String k, String label) => _Flag(k, _t(label));

class _Goals {
  int kcal = 0, p = 0, c = 0, f = 0, fib = 0, sug = 0, water = 0, steps = 8000;
}

class _Rep {
  // کەس
  String name = '', sex = '', goal = '';
  int age = 0;
  double h = 0, w = 0, act = 1.375, bmi = 0, bmr = 0, tdee = 0;
  List<String> conds = [];
  // Band
  bool connected = false, linked = false;
  String lastSync = '';
  int bandDays = 0, nights = 0;
  double? hr, rhr, sp, tp, hrv, st, br, sl, eff, stp, bpH, bpL;
  int? hrMin, hrMax, spMin;
  Map<String, double>? stg;
  String? lnT;
  // ECG
  List<EcgResult> ecg = [];
  int irr = 0;
  double? ecgHrv;
  // خواردن
  int foodDays = 0;
  Map<String, double>? fa;
  final _Goals goals = _Goals();
  // جووڵە و کێش
  double? actWeek, burned;
  int wCount = 0;
  double? wChange;
  // تەمەنی لەش
  VitalResult? va;
  int vaCollected = 0, vaNeed = VitalAgeEngine.need;
  // هەڵسەنگاندن
  final Map<String, _Flag> v = {}, nf = {};
  int? score, prev, lvl;
  final List<(String, int, bool)> risks = [];
  final List<String> good = [], att = [], recs = [];
  String no = '';
  int pts = 0;
}

_Rep _build(List<EcgResult> ecgAll, Map? fd) {
  final r = _Rep();
  final now = DateTime.now();
  final today = _key(now);
  final cut30 = _key(now.subtract(const Duration(days: 29)));
  final cut90 = _key(now.subtract(const Duration(days: 89)));

  // ───── کەس ─────
  final u = Account.I.user ?? const <String, dynamic>{};
  final prof = (fd?['prof'] is Map) ? fd!['prof'] as Map : const {};
  r.name = Account.I.name.isNotEmpty ? Account.I.name : '${prof['name'] ?? ''}'.trim();
  r.sex = '${u['sex'] ?? prof['sex'] ?? ''}';
  r.age = VitalAgeEngine.I.realAge;
  if (r.age <= 0) r.age = asI(u['age']);
  if (r.age <= 0 && asI(u['year']) > 1900) r.age = now.year - asI(u['year']);
  if (r.age <= 0) r.age = asI(prof['age']);
  r.h = asD(u['h']) > 0 ? asD(u['h']) : asD(prof['h']);
  final ws = <(String, double)>[];
  if (fd?['weights'] is List) {
    for (final x in fd!['weights'] as List) {
      if (x is Map && asD(x['kg']) > 0) ws.add(('${x['d']}', asD(x['kg'])));
    }
  }
  ws.sort((a, b) => a.$1.compareTo(b.$1));
  r.w = ws.isNotEmpty ? ws.last.$2 : (asD(u['w']) > 0 ? asD(u['w']) : asD(prof['w']));
  r.act = const {'sed': 1.2, 'light': 1.375, 'active': 1.55, 'very': 1.725}['${u['act']}'] ?? (asD(prof['act']) > 0 ? asD(prof['act']) : 1.375);
  r.goal = '${prof['goal'] ?? u['wgoal'] ?? ''}';
  final cn = (_T0['cn'] as Map);
  for (final c in [...(u['conds'] is List ? u['conds'] as List : const []), ...(prof['conds'] is List ? prof['conds'] as List : const [])]) {
    final k = '$c';
    if (cn.containsKey(k) && !r.conds.contains(k)) r.conds.add(k);
  }
  if (r.h > 0 && r.w > 0) r.bmi = r.w / math.pow(r.h / 100, 2);
  if (r.h > 0 && r.w > 0 && r.age > 0) {
    r.bmr = 10 * r.w + 6.25 * r.h - 5 * r.age + (r.sex == 'f' ? -161 : 5);
    r.tdee = r.bmr * r.act;
  }

  // ───── ئامانجەکان (هەمان هاوکێشەی بەشی خواردن) ─────
  final g = r.goals;
  if (r.w > 0 && r.h > 0 && r.age > 0) {
    double k = r.tdee;
    final pace = asD(prof['pace']) > 0 ? asD(prof['pace']) : 0.5;
    final risky = r.conds.any((x) => const ['preg', 'bf', 'kid', 'heart'].contains(x));
    if (r.goal == 'lose') {
      var d = (pace * 1100).roundToDouble();
      if (risky) d = math.min(d, 300);
      if (r.age >= 65) d = math.min(d, 400);
      k = r.tdee - d;
    }
    if (r.goal == 'muscle') k = r.tdee + 250;
    if (r.goal == 'gain') k = r.tdee + math.min(500, (pace * 1100).roundToDouble());
    if (r.conds.contains('preg')) k = math.max(k, r.tdee + 250);
    if (r.conds.contains('bf')) k = math.max(k, r.tdee + 300);
    k = math.max(k, r.sex == 'f' ? 1200.0 : 1500.0);
    k = (k / 10).round() * 10.0;
    var pk = const {'lose': 1.8, 'keep': 1.4, 'muscle': 2.0, 'gain': 1.6, 'aging': 1.2}[r.goal] ?? 1.4;
    if (r.conds.contains('kid')) pk = 0.8;
    g.kcal = k.round();
    g.p = (r.w * pk).round();
    g.f = (k * 0.28 / 9).round();
    g.c = math.max(0, ((k - g.p * 4 - g.f * 9) / 4).round());
    if (r.conds.contains('diab')) g.c = math.min(g.c, (k * 0.4 / 4).round());
    g.sug = r.conds.contains('diab') ? 25 : (k * 0.1 / 4).round();
    g.fib = (k / 1000 * 14).round();
    g.water = (r.w * 35 / 250).round() * 250;
  } else if (Store.I.waterGoalMl > 0) {
    g.water = Store.I.waterGoalMl;
  }
  g.steps = const {'sed': 6000, 'light': 8000, 'active': 10000, 'very': 12000}['${u['act']}'] ?? 8000;

  // ───── Band ─────
  final bs = BandState.I;
  r.connected = bs.connected;
  r.linked = VexBand.I.linked;
  r.lastSync = bs.lastSync;
  final rs = ReportStore.I;
  final dk = rs.days.keys.where((k) => k.compareTo(cut30) >= 0 && k.compareTo(today) <= 0).toList()..sort();
  final dd = [for (final k in dk) rs.days[k]!];
  r.bandDays = dd.where((d) => d.any).length;
  r.pts += r.bandDays * 24;
  List<num> col(num? Function(RDay) f) => [for (final d in dd) if (f(d) != null) f(d)!];
  r.hr = _avg(col((d) => d.hrA));
  final hn = col((d) => d.hrN), hx = col((d) => d.hrX);
  if (hn.isNotEmpty) r.hrMin = hn.reduce(math.min).round();
  if (hx.isNotEmpty) r.hrMax = hx.reduce(math.max).round();
  r.rhr = _avg(col((d) => d.rhr));
  r.sp = _avg(col((d) => d.sp));
  final sn = col((d) => d.spN);
  if (sn.isNotEmpty) r.spMin = sn.reduce(math.min).round();
  r.tp = _avg(col((d) => d.tp));
  r.hrv = _avg(col((d) => d.hrv));
  r.st = _avg(col((d) => d.st));
  r.br = _avg(col((d) => d.br));
  final sls = dd.where((d) => d.sl != null).toList();
  r.nights = sls.length;
  if (sls.isNotEmpty) {
    r.sl = _avg(sls.map((d) => d.sl!));
    final asleep = sls.fold<int>(0, (a, d) => a + d.sl!), awake = sls.fold<int>(0, (a, d) => a + (d.aw ?? 0));
    r.eff = asleep + awake > 0 ? asleep / (asleep + awake) * 100 : null;
    final ln = sls.last;
    final tot = (ln.dp ?? 0) + (ln.lt ?? 0) + (ln.rm ?? 0) + (ln.aw ?? 0);
    if (tot > 0) r.stg = {'D': (ln.dp ?? 0) / tot * 100, 'R': (ln.rm ?? 0) / tot * 100, 'L': (ln.lt ?? 0) / tot * 100, 'A': (ln.aw ?? 0) / tot * 100};
    if (ln.bed != null && ln.wake != null) r.lnT = '${_p2(ln.bed! ~/ 60)}:${_p2(ln.bed! % 60)} – ${_p2(ln.wake! ~/ 60)}:${_p2(ln.wake! % 60)}';
  }
  var stDays = dd.where((d) => (d.stp ?? 0) > 0).toList();
  final stPast = [for (var i = 0; i < dk.length; i++) if (dk[i] != today && (dd[i].stp ?? 0) > 0) dd[i]];
  if (stPast.isNotEmpty) stDays = stPast;
  if (stDays.isNotEmpty) {
    r.stp = _avg(stDays.map((d) => d.stp!));
    final am = stDays.where((d) => d.act != null).map((d) => d.act!);
    if (am.isNotEmpty) r.actWeek = _avg(am)! * 7;
    final kc = dd.where((d) => d.kc != null).map((d) => d.kc!);
    if (kc.isNotEmpty) r.burned = kc.fold<double>(0, (a, b) => a + b);
  }
  final bp = dd.where((d) => d.bpH != null && d.bpL != null).toList();
  if (bp.isNotEmpty) {
    r.bpH = _avg(bp.map((d) => d.bpH!));
    r.bpL = _avg(bp.map((d) => d.bpL!));
  }

  // ───── ECG ─────
  final e30 = ecgAll.where((e) => _key(e.at).compareTo(cut30) >= 0).toList();
  r.ecg = e30.isNotEmpty ? e30 : ecgAll.take(10).toList();
  r.irr = r.ecg.where((e) => e.stats.irregular).length;
  final eh = r.ecg.where((e) => (e.hrv ?? 0) > 0).map((e) => e.hrv!);
  r.ecgHrv = _avg(eh);
  r.hrv ??= r.ecgHrv;
  r.pts += r.ecg.length * 30;

  // ───── خواردن و ئاو ─────
  final fdays = <Map<String, double>>[];
  if (fd?['days'] is Map) {
    (fd!['days'] as Map).forEach((k, v) {
      final key = '$k';
      if (key.compareTo(cut30) < 0 || key.compareTo(today) > 0 || v is! Map || v['m'] is! Map) return;
      final t = <String, double>{'kcal': 0, 'p': 0, 'c': 0, 'f': 0, 'fib': 0, 'sug': 0, 'salt': 0, 'saltN': 0, 'n': 0};
      (v['m'] as Map).forEach((_, l) {
        if (l is! List) return;
        for (final x in l) {
          if (x is! Map) continue;
          t['kcal'] = t['kcal']! + asD(x['kcal']);
          t['p'] = t['p']! + asD(x['p']);
          t['c'] = t['c']! + asD(x['c']);
          t['f'] = t['f']! + asD(x['f']);
          t['fib'] = t['fib']! + asD(x['fib']);
          t['sug'] = t['sug']! + asD(x['sug']);
          if (x['salt'] != null) {
            t['salt'] = t['salt']! + asD(x['salt']);
            t['saltN'] = t['saltN']! + 1;
          }
          t['n'] = t['n']! + 1;
        }
      });
      if (t['n']! > 0) {
        t['water'] = asD(v['water']) * 250;
        fdays.add(t);
      }
    });
  }
  if (fdays.isEmpty && Store.I.food.isNotEmpty) {
    final t = <String, double>{'kcal': 0, 'p': 0, 'c': 0, 'f': 0, 'fib': 0, 'sug': 0, 'salt': 0, 'saltN': 0, 'n': 0};
    for (final x in Store.I.food) {
      t['kcal'] = t['kcal']! + x.kcal;
      t['p'] = t['p']! + x.p;
      t['c'] = t['c']! + x.c;
      t['f'] = t['f']! + x.f;
      t['n'] = t['n']! + 1;
    }
    t['water'] = (Store.I.waterN * Store.glassMl).toDouble();
    fdays.add(t);
  }
  r.foodDays = fdays.length;
  if (fdays.isNotEmpty) {
    final fa = <String, double>{};
    for (final k in ['kcal', 'p', 'c', 'f', 'fib', 'sug', 'water']) {
      fa[k] = _avg(fdays.map((t) => t[k] ?? 0))!;
    }
    final sd = fdays.where((t) => (t['saltN'] ?? 0) > 0).toList();
    if (sd.isNotEmpty) fa['salt'] = _avg(sd.map((t) => t['salt']!))!;
    r.fa = fa;
    r.pts += fdays.fold<int>(0, (a, t) => a + (t['n'] ?? 0).round());
  }

  // ───── کێش ─────
  final w90 = ws.where((x) => x.$1.compareTo(cut90) >= 0).toList();
  r.wCount = w90.length;
  r.pts += w90.length;
  if (w90.length >= 2) r.wChange = w90.last.$2 - w90.first.$2;

  // ───── تەمەنی لەش ─────
  final ve = VitalAgeEngine.I;
  r.va = ve.preview ? null : ve.compute();
  r.vaCollected = ve.preview ? 0 : ve.collected;

  _evaluate(r);
  r.no = 'VX-${now.year}-${_p2(now.month)}-${_hash('${r.name}|${r.h}|${u['year'] ?? r.age}')}';
  return r;
}

int _hash(String s) {
  var h = 7;
  for (final c in s.codeUnits) {
    h = (h * 31 + c) & 0x7fffffff;
  }
  return 1000 + h % 9000;
}

void _evaluate(_Rep r) {
  final v = r.v, nf = r.nf, g = r.goals;
  if (r.hr != null) v['hr'] = r.hr! < 50 ? _fl('lo') : (r.hr! > 100 ? _fl('hi') : _fl('ok'));
  if (r.rhr != null) v['rhr'] = r.rhr! < 45 ? _fl('lo') : (r.rhr! > 90 ? _fl('hi') : _fl('ok'));
  if (r.sp != null) v['sp'] = r.sp! >= 95 ? _fl('ok') : (r.sp! >= 91 ? _fx('hi', 'mid') : _fl('lo'));
  if (r.spMin != null) v['spl'] = r.spMin! >= 90 ? _fl('ok') : _fl('lo');
  if (r.tp != null) v['tp'] = r.tp! < 32 ? _fl('lo') : (r.tp! > 35.5 ? _fl('hi') : _fl('ok'));
  if (r.st != null) v['st'] = r.st! <= 50 ? _fl('ok') : (r.st! <= 75 ? _fx('hi', 'mid') : _fl('hi'));
  if (r.br != null) v['br'] = r.br! < 10 ? _fl('lo') : (r.br! > 22 ? _fl('hi') : _fl('ok'));
  if (r.sl != null) v['sl'] = r.sl! < 420 ? _fl('lo') : (r.sl! > 540 ? _fl('hi') : _fl('ok'));
  if (r.stp != null) v['stp'] = r.stp! >= g.steps ? _fl('ok') : _fl('lo');
  if (r.hrv != null) v['hrv'] = r.hrv! < 20 ? _fl('lo') : _fl('ok');
  if (r.bpH != null) v['bp'] = (r.bpH! >= 130 || r.bpL! >= 85) ? _fl('hi') : (r.bpH! >= 120 ? _fx('hi', 'mid') : _fl('ok'));

  final fa = r.fa;
  if (fa != null) {
    if (g.kcal > 0) nf['kc'] = fa['kcal']! > g.kcal * 1.1 ? _fx('hi', 'much') : (fa['kcal']! < g.kcal * .8 ? _fl('lo') : _fx('ok', 'good'));
    if (g.p > 0) nf['pr'] = fa['p']! >= g.p * .9 ? _fx('ok', 'good') : _fl('lo');
    if (g.c > 0) nf['cb'] = fa['c']! > g.c * 1.15 ? _fx('hi', 'much') : _fx('ok', 'good');
    if (g.f > 0) nf['ft'] = fa['f']! > g.f * 1.15 ? _fx('hi', 'much') : _fx('ok', 'good');
    if (g.fib > 0 && fa['fib']! > 0) nf['fb'] = fa['fib']! >= g.fib * .8 ? _fx('ok', 'good') : _fl('lo');
    if (g.sug > 0 && fa['sug']! > 0) nf['sg'] = fa['sug']! > g.sug ? _fx('hi', 'much') : _fx('ok', 'good');
    if (fa['salt'] != null) nf['sa'] = fa['salt']! > 5 ? _fx('hi', 'much') : _fx('ok', 'good');
    if (g.water > 0 && fa['water']! > 0) nf['wa'] = fa['water']! >= g.water * .9 ? _fx('ok', 'good') : _fl('lo');
  }

  // ───── نمرە ─────
  final parts = <(int, double)>[];
  void add(int w, num s) => parts.add((w, s.clamp(0, 100).toDouble()));
  if (r.hr != null) add(15, r.hr! >= 60 && r.hr! <= 100 ? 100 : (r.hr! < 50 || r.hr! > 110 ? 45 : 75));
  if (r.sp != null) add(10, r.sp! >= 95 ? 100 : (r.sp! >= 91 ? 70 : 40));
  if (r.sl != null) {
    final sh = r.sl! / 60;
    add(20, sh >= 7 && sh <= 9 ? 100 : (sh >= 6 && sh < 7 ? 60 + (sh - 6) * 25 : (sh > 9 ? 80 : math.max(25, 60 - (6 - sh) * 30))));
  }
  if (r.st != null) add(10, r.st! < 25 ? 100 : (r.st! <= 50 ? 85 : (r.st! <= 75 ? 60 : 35)));
  if (r.stp != null) add(15, math.max(20, math.min(100, r.stp! / 10000 * 100)));
  if (fa != null && g.kcal > 0) {
    var nut = math.max(0, 1 - (fa['kcal']! - g.kcal).abs() / g.kcal) * 40;
    nut += (g.p > 0 ? math.min(1, fa['p']! / g.p) : 1) * 25;
    nut += (g.fib > 0 && fa['fib']! > 0 ? math.min(1, fa['fib']! / g.fib) : 1) * 15;
    nut += (g.sug > 0 ? (fa['sug']! <= g.sug ? 1 : math.max(0, 1 - (fa['sug']! - g.sug) / g.sug)) : 1) * 10;
    nut += (g.water > 0 && fa['water']! > 0 ? math.min(1, fa['water']! / g.water) : 1) * 10;
    add(20, nut);
  }
  if (r.bmi > 0) add(10, r.bmi >= 18.5 && r.bmi < 25 ? 100 : (r.bmi >= 25 && r.bmi < 30 ? 75 : (r.bmi < 18.5 ? 70 : 50)));
  if (r.ecg.isNotEmpty) add(5, r.irr == 0 ? 100 : 40);
  if (r.bpH != null) add(10, v['bp']!.k == 'ok' ? 100 : (r.bpH! >= 130 ? 50 : 75));
  if (parts.isNotEmpty) {
    var sw = 0, sv = 0.0;
    for (final p in parts) {
      sw += p.$1;
      sv += p.$1 * p.$2;
    }
    r.score = (sv / sw).round();
    r.lvl = r.score! >= 88 ? 0 : (r.score! >= 72 ? 1 : (r.score! >= 55 ? 2 : 3));
    r.prev = ReportStore.I.recordScore(r.score!);
  }

  // ───── مەترسی ─────
  var pc = 0;
  if (r.hr != null) pc += r.hr! > 100 ? 2 : (r.hr! < 50 ? 1 : 0);
  if (r.conds.contains('heart')) pc += 2;
  if (r.conds.contains('bp')) pc += 2;
  if (r.conds.contains('chol')) pc += 1;
  if (r.bmi >= 30) pc += 1;
  if (r.stp != null && r.stp! < 5000) pc += 1;
  if (fa?['salt'] != null && fa!['salt']! > 5) pc += 1;
  if (r.bpH != null) pc += r.bpH! >= 130 ? 2 : (r.bpH! >= 120 ? 1 : 0);
  if (r.irr > 0) pc += 2;
  r.risks.add(('rc', pc, r.hr != null || r.conds.isNotEmpty || r.bmi > 0 || r.ecg.isNotEmpty));
  var pm = 0;
  if (r.bmi >= 30) {
    pm += 2;
  } else if (r.bmi >= 25) {
    pm += 1;
  }
  if (nf['sg']?.k == 'hi') pm += 1;
  if (nf['fb']?.k == 'lo') pm += 1;
  if (nf['kc']?.k == 'hi') pm += 1;
  if (r.conds.contains('diab')) pm += 2;
  r.risks.add(('rmt', pm, r.bmi > 0 || fa != null));
  var ps = 0;
  if (r.sl != null) ps += r.sl! < 360 ? 2 : (r.sl! < 420 ? 1 : 0);
  if (r.st != null) ps += r.st! > 75 ? 2 : (r.st! > 50 ? 1 : 0);
  if (r.eff != null && r.eff! < 85) ps += 1;
  r.risks.add(('rs', ps, r.sl != null || r.st != null));
  var pa = 0;
  if (r.stp != null) pa += r.stp! < 5000 ? 2 : (r.stp! < g.steps ? 1 : 0);
  if (r.actWeek != null && r.actWeek! < 150) pa += 1;
  r.risks.add(('ra', pa, r.stp != null));

  // ───── پوختە و ڕاسپاردە ─────
  void gb(bool ok, String k) => (ok ? r.good : r.att).add(_g('g', k));
  if (v['hr'] != null) gb(v['hr']!.k == 'ok', 'hr');
  if (v['sp'] != null) gb(v['sp']!.k == 'ok', 'sp');
  if (r.ecg.isNotEmpty) gb(r.irr == 0, 'ecg');
  if (v['bp'] != null) (v['bp']!.k == 'ok' ? r.good : r.att).add(_t('g_bp'));
  if (v['sl'] != null) gb(v['sl']!.k == 'ok', 'sl');
  if (v['st'] != null) gb(v['st']!.k == 'ok', 'st');
  if (v['stp'] != null) gb(v['stp']!.k == 'ok', 'stp');
  if (v['tp'] != null && v['tp']!.k != 'ok') r.att.add(_g('g', 'tp'));
  if (nf['kc'] != null) gb(nf['kc']!.k == 'ok', 'kc');
  if (nf['pr'] != null) gb(nf['pr']!.k == 'ok', 'pr');
  if (nf['fb'] != null && nf['fb']!.k != 'ok') r.att.add(_g('g', 'fb'));
  if (nf['sg'] != null && nf['sg']!.k != 'ok') r.att.add(_g('g', 'sg'));
  if (nf['sa'] != null && nf['sa']!.k != 'ok') r.att.add(_g('g', 'sa'));
  if (nf['wa'] != null && nf['wa']!.k != 'ok') r.att.add(_g('g', 'wa'));
  if (r.bmi > 0) gb(r.bmi >= 18.5 && r.bmi < 25, 'bmi');

  void rc(String k, [Map<String, Object?> o = const {}]) => r.recs.add(_f(_g('r', k), o));
  final hasBand = r.bandDays > 0;
  if (!hasBand) rc('band');
  if (nf['sa']?.k == 'hi') rc('salt');
  if (v['sl']?.k == 'lo') rc('sleep');
  if (v['st']?.k == 'hi') rc('stress');
  if (nf['pr']?.k == 'lo') rc('prot', {'n': fmt(math.max(10, ((g.p - fa!['p']!) / 5).round() * 5))});
  if (nf['kc']?.k == 'hi') {
    rc('kcalHi');
  } else if (nf['kc']?.k == 'lo') {
    rc('kcalLo');
  }
  if (nf['sg']?.k == 'hi') rc('sug');
  if (nf['fb']?.k == 'lo') rc('fib');
  if (nf['wa']?.k == 'lo') rc('water', {'n': math.max(1, ((g.water - fa!['water']!) / 250).round())});
  if (v['stp']?.k == 'lo') rc('steps', {'n': fmt(math.max(500, ((g.steps - r.stp!) / 500).round() * 500))});
  if (r.bmi >= 27) rc('bmi');
  if (r.foodDays == 0) rc('food');
  if (r.ecg.isEmpty) rc('ecg');
  if (r.recs.length > 6) r.recs.removeRange(6, r.recs.length);
  if (r.recs.isEmpty) rc('keep');
}

int _riskLvl(int p) => p <= 1 ? 0 : (p <= 3 ? 1 : 2);

// ═════════════════════════════ ڕەنگەکان ═════════════════════════════
class _P {
  const _P({
    required this.paper, required this.ink, required this.mu, required this.ln, required this.kvb, required this.kvl,
    required this.lhb, required this.acc, required this.secL, required this.secN, required this.secNx,
    required this.okc, required this.okb, required this.hic, required this.hib, required this.loc, required this.lob,
    required this.nac, required this.nab, required this.ecgb, required this.ecgg, required this.ecgl, required this.ecgx,
    required this.wb, required this.wbc, required this.wbl, required this.wbi, required this.trk, required this.btn,
    required this.btnx, required this.dark,
  });
  final Color paper, ink, mu, ln, kvb, kvl, acc, secL, secN, secNx, okc, okb, hic, hib, loc, lob, nac, nab;
  final Color ecgb, ecgg, ecgl, ecgx, wb, wbc, wbl, wbi, trk, btnx;
  final List<Color> lhb, btn;
  final bool dark;
}

const _P _pDark = _P(
  paper: Color(0xFF0A2F3A), ink: Color(0xFFEAFFFF), mu: Color(0xFFA3C8CF), ln: Color(0x218CEBF5), kvb: Color(0x0BFFFFFF),
  kvl: Color(0x1F8CEBF5), lhb: [Color(0xFF0F4F5F), Color(0xFF08313C)], acc: Color(0xFF2FE6F3), secL: Color(0x738CEBF5),
  secN: Color(0xFF2FE6F3), secNx: Color(0xFF04202A), okc: Color(0xFF3CF08A), okb: Color(0x213CF08A), hic: Color(0xFFFFB27A),
  hib: Color(0x26FF9466), loc: Color(0xFFA9C6FF), lob: Color(0x297FA8FF), nac: Color(0xFFA3C8CF), nab: Color(0x12FFFFFF),
  ecgb: Color(0xFF062630), ecgg: Color(0x212FE6F3), ecgl: Color(0xFF2FE6F3), ecgx: Color(0xFF8FBCC4), wb: Color(0x17FFBE4D),
  wbc: Color(0xFFFFE2A8), wbl: Color(0x4DFFBE4D), wbi: Color(0xFFFFBE4D), trk: Color(0x14FFFFFF),
  btn: [Color(0xFF8FF3F9), Color(0xFF3CF08A)], btnx: Color(0xFF04323A), dark: true,
);

const _P _pLight = _P(
  paper: Color(0xFFFFFFFF), ink: Color(0xFF0E2A33), mu: Color(0xFF566D76), ln: Color(0xFFE3EAED), kvb: Color(0xFFF5F8F9),
  kvl: Color(0xFFE3EAED), lhb: [Color(0xFF0E2A33), Color(0xFF12323C)], acc: Color(0xFF087780), secL: Color(0xFF0E2A33),
  secN: Color(0xFF0E2A33), secNx: Color(0xFFFFFFFF), okc: Color(0xFF14632F), okb: Color(0xFFE3F5E9), hic: Color(0xFF9A3412),
  hib: Color(0xFFFFEDE2), loc: Color(0xFF1E40AF), lob: Color(0xFFE4ECFF), nac: Color(0xFF566D76), nab: Color(0xFFEEF2F4),
  ecgb: Color(0xFFFFFBFB), ecgg: Color(0xFFF6D5D5), ecgl: Color(0xFFB91C1C), ecgx: Color(0xFF7A5B5B), wb: Color(0xFFFFF7F0),
  wbc: Color(0xFF7C2D12), wbl: Color(0xFFF5D0B5), wbi: Color(0xFFC2410C), trk: Color(0xFFE3EAED),
  btn: [Color(0xFF0E2A33), Color(0xFF12323C)], btnx: Color(0xFFFFFFFF), dark: false,
);

// ═════════════════════════════ ئایکۆنەکان ═════════════════════════════
String _ico(String body, String col, {double sw = 2.3}) =>
    '<svg viewBox="0 0 24 24" fill="none" stroke="$col" stroke-width="$sw" stroke-linecap="round" stroke-linejoin="round">$body</svg>';
const String _iPulse = '<path d="M3 12h4l2-5 4 10 2-5h6"/>';
const String _iWarn = '<path d="M12 4l9 16H3z"/><path d="M12 10v4M12 17v.5"/>';
const String _iDl = '<path d="M12 4v11M7 10l5 5 5-5M5 20h14"/>';
const String _iBack = '<path d="M9 6l6 6-6 6"/>';
const String _iSync = '<path d="M20 11a8 8 0 0 0-14-4M4 13a8 8 0 0 0 14 4M6 3v4h4M18 21v-4h-4"/>';
String _hex(Color c) => vexHex(c);
Widget _svg(String body, Color c, double size, {double sw = 2.3}) => SvgPicture.string(_ico(body, _hex(c), sw: sw), width: size, height: size);

/// ئایکۆنی 3D ی ڕاپۆرت (تەختەی نووسین + لێدانی دڵ + ✓)
const String kReportIconSvg =
    '<svg viewBox="0 0 96 96"><defs><linearGradient id="ra" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#5ff4ff"/><stop offset=".55" stop-color="#16b6cf"/><stop offset="1" stop-color="#0a6a82"/></linearGradient><linearGradient id="rb" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#ffffff"/><stop offset="1" stop-color="#dff6fb"/></linearGradient><linearGradient id="rc" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#f4f8fb"/><stop offset=".5" stop-color="#b7c6d1"/><stop offset="1" stop-color="#7c8f9d"/></linearGradient><linearGradient id="rd" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#ff8aa0"/><stop offset="1" stop-color="#ff3d6a"/></linearGradient><radialGradient id="re" cx=".35" cy=".3" r=".8"><stop offset="0" stop-color="#9dffc6"/><stop offset=".55" stop-color="#2fd877"/><stop offset="1" stop-color="#0d9a4c"/></radialGradient><radialGradient id="rf" cx=".5" cy=".5" r=".5"><stop offset="0" stop-color="#2fe6f3" stop-opacity=".45"/><stop offset="1" stop-color="#2fe6f3" stop-opacity="0"/></radialGradient></defs>'
    '<circle cx="48" cy="50" r="44" fill="url(#rf)"/><rect x="19" y="17" width="56" height="70" rx="11" fill="#02222b" opacity=".35"/>'
    '<rect x="18" y="14" width="56" height="70" rx="11" fill="url(#ra)"/><rect x="18.8" y="14.8" width="54.4" height="68.4" rx="10.4" fill="none" stroke="#ffffff" stroke-opacity=".35" stroke-width="1.2"/>'
    '<path d="M22 26c0-6 4-9 9-9h6c-8 3-11 9-11 20v36c-3-2-4-5-4-9z" fill="#ffffff" opacity=".28"/><rect x="25" y="24" width="42" height="53" rx="6" fill="url(#rb)"/>'
    '<rect x="34" y="9" width="24" height="13" rx="5" fill="url(#rc)" stroke="#5f7381" stroke-width="1"/><circle cx="46" cy="13.5" r="2.6" fill="#40525e"/><rect x="36" y="16" width="20" height="3" rx="1.5" fill="#ffffff" opacity=".55"/>'
    '<path d="M29 44h7l3-7 5 15 4-11 3 3h11" fill="none" stroke="#ff3d6a" stroke-opacity=".25" stroke-width="6" stroke-linecap="round" stroke-linejoin="round"/>'
    '<path d="M29 44h7l3-7 5 15 4-11 3 3h11" fill="none" stroke="url(#rd)" stroke-width="3.4" stroke-linecap="round" stroke-linejoin="round"/>'
    '<rect x="30" y="58" width="22" height="3.6" rx="1.8" fill="#9fb8c2"/><rect x="30" y="65" width="15" height="3.6" rx="1.8" fill="#c3d4da"/><rect x="30" y="30" width="12" height="3" rx="1.5" fill="#c3d4da"/>'
    '<circle cx="67.5" cy="71" r="13" fill="#02222b" opacity=".3"/><circle cx="67" cy="69" r="13" fill="url(#re)" stroke="#ffffff" stroke-width="2.2"/>'
    '<path d="M61 69.2l4.2 4.2 7.6-8.4" fill="none" stroke="#ffffff" stroke-width="3.4" stroke-linecap="round" stroke-linejoin="round"/>'
    '<ellipse cx="63" cy="63.5" rx="4.5" ry="2.4" fill="#ffffff" opacity=".45" transform="rotate(-30 63 63.5)"/></svg>';

// ═════════════════════════════ پارچە بچووکەکان ═════════════════════════════
Widget _tx(String s, double size, Color c, {FontWeight w = FontWeight.w700, double? h, TextAlign? a}) =>
    Text(s, textAlign: a, style: ku(size, w: w, c: c, h: h));
Widget _nm(String s, double size, Color c, {FontWeight w = FontWeight.w800}) =>
    Text(s, textDirection: TextDirection.ltr, style: nu(size, w: w, c: c));

Widget _gap(double h) => SizedBox(height: h);

Widget _grid(List<Widget> items, int cols, {double gap = 8}) {
  final rows = <Widget>[];
  for (var i = 0; i < items.length; i += cols) {
    final cells = <Widget>[];
    for (var j = 0; j < cols; j++) {
      if (j > 0) cells.add(SizedBox(width: gap));
      cells.add(Expanded(child: i + j < items.length ? items[i + j] : const SizedBox()));
    }
    if (rows.isNotEmpty) rows.add(SizedBox(height: gap));
    rows.add(IntrinsicHeight(child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: cells)));
  }
  return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: rows);
}

Widget _kv(_P p, String label, Widget value) => Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 9),
      decoration: BoxDecoration(color: p.kvb, borderRadius: BorderRadius.circular(11), border: Border.all(color: p.kvl)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        _tx(label, 10.5, p.mu, w: FontWeight.w600),
        const SizedBox(height: 2),
        value,
      ]),
    );

Widget _kvT(_P p, String label, String v, {double size = 14}) => _kv(p, label, _tx(v, size, p.ink, w: FontWeight.w800, h: 1.45));
Widget _kvN(_P p, String label, String v, {Color? c}) =>
    _kv(p, label, Align(alignment: AlignmentDirectional.centerStart, child: _nm(v, 14, c ?? p.ink)));

Widget _flagW(_P p, _Flag f) {
  final (fg, bg) = switch (f.k) { 'ok' => (p.okc, p.okb), 'hi' => (p.hic, p.hib), 'lo' => (p.loc, p.lob), _ => (p.nac, p.nab) };
  return Align(
    alignment: AlignmentDirectional.centerStart,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(f.t, maxLines: 1, style: ku(10.5, w: FontWeight.w800, c: fg)),
    ),
  );
}

Widget _sec(_P p, int no, String title, [String extra = '']) => Container(
      margin: const EdgeInsets.only(top: 22, bottom: 10),
      padding: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: p.secL, width: 2))),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
          decoration: BoxDecoration(color: p.secN, borderRadius: BorderRadius.circular(6)),
          child: _nm(_p2(no), 11, p.secNx, w: FontWeight.w700),
        ),
        const SizedBox(width: 8),
        Expanded(child: _tx(title, 15, p.ink, w: FontWeight.w800)),
        if (extra.isNotEmpty) _tx(extra, 10.5, p.mu, w: FontWeight.w600),
      ]),
    );

const List<int> _cols = [140, 100, 95, 80];

Widget _th(_P p, List<String> h) => Padding(
      padding: const EdgeInsets.fromLTRB(2, 0, 2, 6),
      child: Row(children: [for (var i = 0; i < 4; i++) Expanded(flex: _cols[i], child: _tx(h[i], 10.5, p.mu))]),
    );

Widget _row(_P p, String label, String value, String ref, _Flag f) => Container(
      padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 2),
      decoration: BoxDecoration(border: Border(top: BorderSide(color: p.ln))),
      child: Row(children: [
        Expanded(flex: _cols[0], child: _tx(label, 12.5, p.ink, h: 1.4)),
        Expanded(flex: _cols[1], child: Align(alignment: AlignmentDirectional.centerStart, child: _nm(value, 12.5, p.ink, w: FontWeight.w700))),
        Expanded(flex: _cols[2], child: Align(alignment: AlignmentDirectional.centerStart, child: _nm(ref, 11, p.mu, w: FontWeight.w600))),
        Expanded(flex: _cols[3], child: _flagW(p, f)),
      ]),
    );

Widget _para(_P p, String s, {bool muted = false, double size = 12.5}) =>
    Text(s, style: ku(size, w: FontWeight.w600, c: muted ? p.mu : p.ink, h: 1.85));

Widget _note(_P p, String s) => Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
      decoration: BoxDecoration(color: p.kvb, borderRadius: BorderRadius.circular(10), border: Border.all(color: p.kvl)),
      child: _para(p, s, muted: true, size: 11.5),
    );

/// هێڵی پێشکەوتن (ئاراستە هەمیشە چەپ ← ڕاست بۆ ژمارە)
Widget _bar(double frac, Color c, Color track, {double h = 6}) => Directionality(
      textDirection: TextDirection.ltr,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(h),
        child: Container(
          height: h,
          color: track,
          alignment: Alignment.centerLeft,
          child: FractionallySizedBox(widthFactor: frac.clamp(0.0, 1.0).toDouble(), heightFactor: 1, child: Container(color: c)),
        ),
      ),
    );

class _EcgPainter extends CustomPainter {
  _EcgPainter(this.trace, this.grid, this.line);
  final List<double> trace;
  final Color grid, line;
  @override
  void paint(Canvas c, Size s) {
    final g = Paint()
      ..color = grid
      ..strokeWidth = 0.7;
    for (double x = 0; x <= s.width; x += 10) {
      c.drawLine(Offset(x, 0), Offset(x, s.height), g);
    }
    for (double y = 0; y <= s.height; y += 10) {
      c.drawLine(Offset(0, y), Offset(s.width, y), g);
    }
    if (trace.length < 2) return;
    final path = Path();
    for (var i = 0; i < trace.length; i++) {
      final x = i / (trace.length - 1) * s.width;
      final y = s.height * .55 - trace[i].clamp(-1.0, 1.0) * s.height * .45;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    c.drawPath(
        path,
        Paint()
          ..color = line
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6
          ..strokeJoin = StrokeJoin.round);
  }

  @override
  bool shouldRepaint(covariant _EcgPainter o) => o.trace != trace || o.line != line || o.grid != grid;
}

/// 3.5 چرکەی یەکەمی شەپۆلی ڕاستەقینەی ECG
List<double> _ecgSlice(EcgResult e) {
  if (e.trace.isEmpty || e.sampleRate <= 0) return const [];
  final n = math.min(e.trace.length, (e.sampleRate * 3.5).round());
  final start = math.min(e.trace.length - n, (e.sampleRate * 1.0).round());
  return e.trace.sublist(math.max(0, start), math.max(0, start) + n);
}

// ═════════════════════════════ بەشەکانی ڕاپۆرت ═════════════════════════════
/// هەر بەشێک = لیستی پارچە (بۆ PDF خشتەکان ڕیز بە ڕیز دابەش دەبن)
List<List<Widget>> _blocks(_Rep r, _P p, {bool print = false}) {
  final out = <List<Widget>>[];
  final now = DateTime.now();
  final na = _Flag('na', r.bandDays > 0 ? _t('nod') : (r.connected ? _t('nod') : _t('na')));
  String v0(num? x, String Function(num) f) => x == null ? '—' : f(x);
  var secNo = 0;
  Widget sec(String k, [String extra = '']) => _sec(p, ++secNo, _t(k), extra);

  // ───── سەردێڕ ─────
  out.add([
    Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: p.lhb),
        borderRadius: print ? BorderRadius.circular(12) : const BorderRadius.vertical(top: Radius.circular(19)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: const Color(0xFF2FE6F3), borderRadius: BorderRadius.circular(9)),
            child: _svg(_iPulse, const Color(0xFF0E2A33), 18, sw: 2.5),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: AlignmentDirectional.centerStart,
              child: Text('VEX HEALTH', textDirection: TextDirection.ltr, style: nu(14, c: Colors.white, ls: 1.5)),
            ),
          ),
          const SizedBox(width: 10),
          const Spacer(),
          Flexible(
            flex: 2,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: AlignmentDirectional.centerEnd,
              child: _nm('No. ${r.no}', 10.5, const Color(0xFFB9D6DC), w: FontWeight.w600),
            ),
          ),
        ]),
        _gap(10),
        _tx(_t('doc'), 20, Colors.white, w: FontWeight.w800, h: 1.4),
        _gap(8),
        Wrap(spacing: 14, runSpacing: 4, alignment: WrapAlignment.spaceBetween, children: [
          _tx('${_t('per')} · ${_dmy(now.subtract(const Duration(days: 29)))} – ${_dmy(now)}', 11.5, const Color(0xFFB9D6DC), w: FontWeight.w600),
          _tx('${_t('iss')}: ${_dmy(now)}', 11.5, const Color(0xFFB9D6DC), w: FontWeight.w600),
        ]),
      ]),
    ),
  ]);

  // ───── کەس + نمرە ─────
  final sexT = r.sex == 'm' ? _t('m') : (r.sex == 'f' ? _t('f') : '—');
  Widget chip(String s, bool on) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
        decoration: BoxDecoration(color: p.kvb, borderRadius: BorderRadius.circular(20), border: Border.all(color: p.kvl)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 6, height: 6, decoration: BoxDecoration(shape: BoxShape.circle, color: on ? p.okc : const Color(0xFFE5405F))),
          const SizedBox(width: 5),
          _tx(s, 10.5, p.mu),
        ]),
      );
  final lv = _lv();
  final scoreBox = Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: p.kvl)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Expanded(child: _tx(_t('score'), 12, p.mu)),
        _nm(r.score == null ? '—' : '${r.score}', 26, p.acc),
        _nm('/100', 12, p.mu, w: FontWeight.w600),
      ]),
      _gap(10),
      Directionality(
        textDirection: TextDirection.ltr,
        child: SizedBox(
          height: 16,
          child: Stack(alignment: Alignment.center, children: [
            Container(
              height: 8,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                gradient: const LinearGradient(colors: [Color(0xFFC2410C), Color(0xFFEAB308), Color(0xFF16A34A), Color(0xFF0E7490)], stops: [0, .45, .75, 1]),
              ),
            ),
            if (r.score != null)
              Align(
                alignment: Alignment(((r.score! / 100) * 2 - 1).clamp(-1.0, 1.0).toDouble(), 0),
                child: Container(
                  width: 5,
                  height: 16,
                  decoration: BoxDecoration(color: p.ink, borderRadius: BorderRadius.circular(2), border: Border.all(color: p.paper, width: 1)),
                ),
              ),
          ]),
        ),
      ),
      _gap(8),
      if (r.lvl != null) _tx(lv[r.lvl!], 11.5, r.lvl! <= 1 ? p.okc : (r.lvl == 2 ? p.mu : p.hic), w: FontWeight.w800),
      if (r.score != null)
        _tx(
          r.prev == null
              ? _t('dNew')
              : (r.prev == r.score ? _t('dEq') : _f(r.score! > r.prev! ? _t('dUp') : _t('dDn'), {'a': r.prev, 'b': r.score})),
          11.5,
          r.prev == null || r.prev == r.score ? p.mu : (r.score! > r.prev! ? p.okc : p.hic),
          h: 1.6,
        ),
    ]),
  );
  final va = r.va;
  final vaBox = Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: p.kvl)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _tx(_t('va'), 12, p.mu, h: 1.4),
      _gap(6),
      if (va != null) ...[
        Row(crossAxisAlignment: CrossAxisAlignment.end, children: [_nm(va.age.round().toString(), 26, p.ink), const SizedBox(width: 4), _tx(_t('yrs'), 12, p.mu)]),
        _tx(
          va.delta.round() < 0
              ? _f(_t('vaY'), {'n': -va.delta.round()})
              : (va.delta.round() > 0 ? _f(_t('vaO'), {'n': va.delta.round()}) : _t('vaE')),
          11.5,
          va.delta.round() <= 0 ? p.okc : p.hic,
          w: FontWeight.w800,
          h: 1.5,
        ),
      ] else ...[
        Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          _nm('${r.vaCollected}/${r.vaNeed}', 24, p.ink),
          const SizedBox(width: 4),
          _tx(_t('nights'), 12, p.mu),
        ]),
        _gap(6),
        _bar(r.vaCollected / r.vaNeed, p.acc, p.trk),
        _gap(6),
        _tx(r.bandDays > 0 || r.connected ? _f(_t('vaLock'), {'n': r.vaNeed}) : _t('vaBand'), 11, p.mu, h: 1.5),
      ],
    ]),
  );
  out.add([
    Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        _grid([
          _kvT(p, _t('nm'), r.name.isEmpty ? '—' : r.name),
          _kv(p, _t('age'), Row(mainAxisSize: MainAxisSize.min, children: [if (r.age > 0) ...[_nm('${r.age}', 14, p.ink), _tx(' · ', 14, p.ink)], _tx(sexT, 14, p.ink, w: FontWeight.w800)])),
          _kvN(p, _t('ht'), r.h > 0 ? '${r.h.round()} cm' : '—'),
          _kvN(p, _t('wt'), r.w > 0 ? '${_f1(r.w)} kg' : '—'),
          _kvN(p, 'BMI', r.bmi > 0 ? _f1(r.bmi) : '—'),
          _kvT(p, _t('src'), r.bandDays > 0 ? _t('srcB') : _t('srcA'), size: 12.5),
        ], 3),
        _gap(10),
        Wrap(spacing: 6, runSpacing: 6, children: [
          r.bandDays > 0 ? chip(_f(_t('cvB'), {'n': r.bandDays}), true) : chip(_t('cvBo'), false),
          chip(_f(_t('cvF'), {'n': r.foodDays}), r.foodDays > 0),
          chip(_f(_t('cvE'), {'n': r.ecg.length}), r.ecg.isNotEmpty),
          chip(_f(_t('cvW'), {'n': r.wCount}), r.wCount > 0),
        ]),
        if (r.conds.isNotEmpty) ...[
          _gap(10),
          Text.rich(TextSpan(children: [
            TextSpan(text: '${_t('conds')}: ', style: ku(12, w: FontWeight.w600, c: p.mu)),
            TextSpan(text: _join([for (final c in r.conds) _g('cn', c)]), style: ku(12, w: FontWeight.w800, c: p.ink)),
          ])),
        ],
        _gap(12),
        IntrinsicHeight(
          child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Expanded(flex: 125, child: scoreBox),
            const SizedBox(width: 8),
            Expanded(flex: 100, child: vaBox),
          ]),
        ),
      ]),
    ),
  ]);

  // ───── 01 نیشانە ژیانییەکان ─────
  final th = _th(p, [_t('thT'), _t('thR'), _t('thN'), _t('thS')]);
  final vit = <Widget>[
    _row(p, _t('hr'), v0(r.hr, (x) => '${x.round()} bpm'), '60–100', r.v['hr'] ?? na),
    if (r.rhr != null) _row(p, _t('rhr'), '${r.rhr!.round()} bpm', '50–90', r.v['rhr']!),
    _row(p, _t('hrr'), r.hrMin == null ? '—' : '${r.hrMin} – ${r.hrMax}', '40–180', r.hrMin == null ? na : _fl('inf')),
    _row(p, _t('hrv'), v0(r.hrv, (x) => '${x.round()} ms'), '20–100', r.v['hrv'] ?? na),
    _row(p, _t('sp'), v0(r.sp, (x) => '${x.round()} %'), '95–100', r.v['sp'] ?? na),
    _row(p, _t('spl'), r.spMin == null ? '—' : '${r.spMin} %', '≥ 90', r.v['spl'] ?? na),
    if (r.bpH != null) _row(p, _t('bp'), '${r.bpH!.round()}/${r.bpL!.round()}', '< 120/80', r.v['bp']!),
    _row(p, _t('tp'), v0(r.tp, (x) => '${_f1(x)} °C'), '32–35.5', r.v['tp'] ?? na),
    _row(p, _t('st'), v0(r.st, (x) => '${x.round()}'), '< 50', r.v['st'] ?? na),
    if (r.br != null) _row(p, _t('br'), '${r.br!.round()} /min', '12–20', r.v['br']!),
    _row(p, _t('sl'), v0(r.sl, (x) => _hm(x)), '7–9 h', r.v['sl'] ?? na),
    _row(p, _t('stp'), v0(r.stp, (x) => fmt(x)), '≥ ${fmt(r.goals.steps)}', r.v['stp'] ?? na),
  ];
  out.add([
    Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      sec('s1', r.bandDays > 0 ? _f(_t('bandDays'), {'n': r.bandDays}) : ''),
      th,
      vit.first,
    ]),
    ...vit.skip(1),
    if (r.bandDays == 0) _note(p, r.connected ? _t('nod') : _t('bandOff')),
  ]);

  // ───── 02 ECG ─────
  final ecgW = <Widget>[sec('s2', r.ecg.isNotEmpty ? _f(_t('recN').replaceFirst(' 0 ', ' {m} '), {'n': r.ecg.length, 'm': r.irr}) : '')];
  if (r.ecg.isNotEmpty) {
    final e = r.ecg.first;
    final tr = _ecgSlice(e);
    if (tr.isNotEmpty) {
      ecgW.add(Container(
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 6),
        decoration: BoxDecoration(color: p.ecgb, borderRadius: BorderRadius.circular(12), border: Border.all(color: p.kvl)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          SizedBox(height: 74, child: CustomPaint(painter: _EcgPainter(tr, p.ecgg, p.ecgl))),
          _gap(4),
          Row(children: [
            _nm('Lead I · 25 mm/s · 10 mm/mV', 10, p.ecgx, w: FontWeight.w600),
            const Spacer(),
            _tx('${_t('lst')}: ${_dmy(e.at)}', 10.5, p.ecgx, w: FontWeight.w600),
          ]),
        ]),
      ));
      ecgW.add(_gap(10));
    }
    final bpm = e.bpm ?? e.stats.bpm;
    ecgW.add(_grid([
      _kv(p, _t('rh'), _tx(r.irr == 0 ? _t('rhOk') : _t('rhIrr'), 14, r.irr == 0 ? p.ink : p.hic, w: FontWeight.w800)),
      _kvT(p, _t('rec'), _f(_t('recN').replaceFirst(' 0 ', ' {m} '), {'n': r.ecg.length, 'm': r.irr}), size: 13),
      _kvN(p, _t('lhr'), bpm == null ? '—' : '${bpm.round()} bpm${e.stats.minBpm != null && e.stats.maxBpm != null ? ' · ${e.stats.minBpm!.round()}–${e.stats.maxBpm!.round()}' : ''}'),
      _kvN(p, _t('q'), '${(e.quality * 100).round()} %'),
    ], 2));
    ecgW.add(Padding(padding: const EdgeInsets.only(top: 10), child: _para(p, r.irr == 0 ? _t('ecgOk') : _f(_t('ecgIrr'), {'n': r.irr}))));
  } else {
    ecgW.add(_para(p, _t('ecgNo'), muted: true));
  }
  out.add([Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: ecgW)]);

  // ───── 03 خەو ─────
  final slW = <Widget>[sec('s3', r.nights > 0 ? _f(_t('bandDays'), {'n': r.nights}) : '')];
  if (r.sl != null) {
    slW.add(_grid([
      _kvN(p, _t('sla'), _hm(r.sl!)),
      _kvN(p, _t('eff'), r.eff == null ? '—' : '${r.eff!.round()} %'),
      _kvN(p, _t('ln'), r.lnT ?? '—'),
    ], 3));
    final s = r.stg;
    if (s != null) {
      const cs = [Color(0xFF3B37C8), Color(0xFF8B5CF6), Color(0xFF60A5FA), Color(0xFFF59E0B)];
      final vals = [s['D']!, s['R']!, s['L']!, s['A']!];
      final names = [_t('dp'), _t('rm'), _t('lt'), _t('aw')];
      slW.add(_gap(12));
      slW.add(Directionality(
        textDirection: TextDirection.ltr,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(7),
          child: SizedBox(
            height: 14,
            child: Row(children: [
              for (var i = 0; i < 4; i++)
                if (vals[i] > 0) Expanded(flex: math.max(1, (vals[i] * 10).round()), child: Container(color: cs[i])),
            ]),
          ),
        ),
      ));
      slW.add(_gap(8));
      slW.add(Wrap(spacing: 12, runSpacing: 4, children: [
        for (var i = 0; i < 4; i++)
          Row(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 9, height: 9, decoration: BoxDecoration(color: cs[i], borderRadius: BorderRadius.circular(3))),
            const SizedBox(width: 5),
            _tx(names[i], 11, p.ink, w: FontWeight.w600),
            const SizedBox(width: 4),
            _nm('${vals[i].round()}%', 11, p.ink, w: FontWeight.w700),
          ]),
      ]));
    }
    slW.add(Padding(
      padding: const EdgeInsets.only(top: 10),
      child: _para(p, r.sl! < 420 ? _f(_t('debt'), {'h': _f1((420 - r.sl!) * 7 / 60)}) : _t('slOk')),
    ));
  } else {
    slW.add(_para(p, r.bandDays > 0 || r.connected ? _t('nod') : _t('bandOff'), muted: true));
  }
  out.add([Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: slW)]);

  // ───── 04 خۆراک ─────
  final g = r.goals;
  final fa = r.fa;
  if (fa != null) {
    String gv(int x, String unit, [String pre = '']) => x > 0 ? '$pre${fmt(x)}${unit.isEmpty ? '' : ' $unit'}' : '—';
    final info = _fl('inf');
    final rows = <Widget>[
      _row(p, _t('kc'), fmt(fa['kcal']!), gv(g.kcal, ''), r.nf['kc'] ?? info),
      _row(p, _t('pr'), '${fmt(fa['p']!)} g', gv(g.p, 'g'), r.nf['pr'] ?? info),
      _row(p, _t('cb'), '${fmt(fa['c']!)} g', gv(g.c, 'g'), r.nf['cb'] ?? info),
      _row(p, _t('ft'), '${fmt(fa['f']!)} g', gv(g.f, 'g'), r.nf['ft'] ?? info),
      if (fa['fib']! > 0) _row(p, _t('fb'), '${fmt(fa['fib']!)} g', gv(g.fib, 'g'), r.nf['fb'] ?? info),
      if (fa['sug']! > 0) _row(p, _t('sg'), '${fmt(fa['sug']!)} g', gv(g.sug, 'g', '< '), r.nf['sg'] ?? info),
      if (fa['salt'] != null) _row(p, _t('sa'), '${_f1(fa['salt']!)} g', '< 5 g', r.nf['sa']!),
      if (fa['water']! > 0) _row(p, _t('wa'), '${_f1(fa['water']! / 1000)} L', g.water > 0 ? '${_f1(g.water / 1000)} L' : '—', r.nf['wa'] ?? info),
    ];
    out.add([
      Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        sec('s4', _f(_t('bandDays'), {'n': r.foodDays})),
        _th(p, [_t('thE'), _t('thD'), _t('thG'), _t('thS')]),
        rows.first,
      ]),
      ...rows.skip(1),
      Padding(padding: const EdgeInsets.only(top: 8), child: _para(p, _f(_t('fdays'), {'n': r.foodDays}), muted: true, size: 11.5)),
    ]);
  } else {
    out.add([Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [sec('s4'), _para(p, _t('fnone'), muted: true)])]);
  }

  // ───── 05 جووڵە و کێش ─────
  final wc = r.wChange;
  final towardGoal = wc != null && ((wc < 0) == (r.goal != 'gain' && r.goal != 'muscle'));
  out.add([
    Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      sec('s5'),
      _grid([
        _kvN(p, _t('stp'), r.stp == null ? '—' : fmt(r.stp!)),
        _kvN(p, _t('am'), r.actWeek == null ? '—' : '${fmt(r.actWeek!)} / 150'),
        _kvN(p, _t('bn'), r.burned == null ? '—' : '${fmt(r.burned!)} kcal'),
        _kv(
            p,
            _t('wc'),
            wc == null
                ? _tx(r.wCount == 1 ? _t('one') : '—', 14, p.ink, w: FontWeight.w800)
                : Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: _nm('${wc > 0 ? '+' : (wc < 0 ? '−' : '')}${_f1(wc.abs())} kg', 14, wc.abs() < .05 ? p.ink : (towardGoal ? p.okc : p.hic)))),
        _kvN(p, _t('bt'), r.bmr > 0 ? '${fmt(r.bmr)} / ${fmt(r.tdee)}' : '—'),
        _kvN(p, 'BMI', r.bmi > 0 ? _f1(r.bmi) : '—'),
      ], 2),
    ]),
  ]);

  // ───── 06 مەترسی ─────
  const rc = [Color(0xFF16A34A), Color(0xFFEA580C), Color(0xFFDC2626)];
  out.add([
    Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      sec('s6'),
      for (final x in r.risks)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(children: [
            Expanded(flex: 135, child: _tx(_t(x.$1), 12.5, p.ink, h: 1.4)),
            const SizedBox(width: 8),
            Expanded(flex: 200, child: _bar(x.$3 ? math.max(.14, math.min(1.0, x.$2 / 5)) : 0.0, rc[_riskLvl(x.$2)], p.trk)),
            const SizedBox(width: 8),
            Expanded(
              flex: 80,
              child: _flagW(
                  p,
                  x.$3
                      ? _Flag(['ok', 'hi', 'hi'][_riskLvl(x.$2)], [_t('low'), _t('mod'), _t('high')][_riskLvl(x.$2)])
                      : _Flag('na', _t('nod'))),
            ),
          ]),
        ),
    ]),
  ]);

  // ───── 07 پوختە ─────
  final sum = [
    if (r.score != null) _f(_t('sIn'), {'lvl': lv[r.lvl!], 's': r.score}),
    if (r.good.isNotEmpty) _f(_t('sGood'), {'x': _join(r.good)}),
    r.att.isNotEmpty ? _f(_t('sAtt'), {'x': _join(r.att)}) : _t('sAll'),
  ].join(' ');
  out.add([Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [sec('s7'), _para(p, sum)])]);

  // ───── 08 ڕاسپاردەکان ─────
  out.add([
    Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      sec('s8'),
      for (var i = 0; i < r.recs.length; i++)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: 22,
              height: 22,
              margin: const EdgeInsets.only(top: 2),
              alignment: Alignment.center,
              decoration: BoxDecoration(color: p.secN, shape: BoxShape.circle),
              child: _nm('${i + 1}', 11, p.secNx),
            ),
            const SizedBox(width: 10),
            Expanded(child: _para(p, r.recs[i])),
          ]),
        ),
    ]),
  ]);

  // ───── پزیشک + کۆتایی ─────
  out.add([
    Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Container(
        margin: const EdgeInsets.only(top: 14),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: p.wb, borderRadius: BorderRadius.circular(12), border: Border.all(color: p.wbl)),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _svg(_iWarn, p.wbi, 22, sw: 2),
          const SizedBox(width: 10),
          Expanded(
            child: Text.rich(
              TextSpan(children: [
                TextSpan(text: '${_t('docT')} ', style: ku(12, w: FontWeight.w800, c: p.wbc, h: 1.8)),
                TextSpan(
                  text: _t('docX') + (r.conds.isNotEmpty ? ' ${_f(_t('docC'), {'x': _join([for (final c in r.conds) _g('cn', c)])})}' : ''),
                  style: ku(12, w: FontWeight.w600, c: p.wbc, h: 1.8),
                ),
              ]),
            ),
          ),
        ]),
      ),
      Container(
        margin: const EdgeInsets.only(top: 18),
        padding: const EdgeInsets.only(top: 12, bottom: 12),
        decoration: BoxDecoration(border: Border(top: BorderSide(color: p.kvl))),
        child: Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _tx(_t('by'), 11, p.mu, w: FontWeight.w600),
              _tx(_t('eng'), 13, p.ink, w: FontWeight.w800),
              _tx(_f(_t('pts'), {'n': fmt(r.pts)}), 11, p.mu, w: FontWeight.w600),
            ]),
          ),
          Container(
            width: 58,
            height: 58,
            alignment: Alignment.center,
            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: p.acc, width: 2)),
            child: Container(
              width: 48,
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: op(p.acc, .55))),
              child: Text('VEX', textDirection: TextDirection.ltr, style: nu(13, c: p.acc, ls: 1)),
            ),
          ),
        ]),
      ),
      Padding(padding: const EdgeInsets.only(bottom: 16), child: _para(p, _t('disc'), muted: true, size: 10.5)),
    ]),
  ]);
  return out;
}

// ═════════════════════════════ پەڕەی ڕاپۆرت ═════════════════════════════
/// داتای بەشی خواردن (کێش، ژەمەکان، ئاو) — ئەگەر هەبێت
Future<Map?> _loadFood() async {
  try {
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getString('vexfd_v1');
    if (raw != null && raw.isNotEmpty) {
      final j = jsonDecode(raw);
      if (j is Map) return j;
    }
  } catch (_) {}
  return null;
}

/// PDF ی ڕاپۆرتی گشتی بە بایت (بۆ ناردن یان هەڵگرتن لە هەر شوێنێکی ئەپ)
Future<Uint8List> generalReportPdf() async {
  await ReportStore.I.init();
  final e = await EcgHistory.load();
  final fd = await _loadFood();
  return _makePdf(_build(e, fd));
}

class GeneralReportPage extends StatefulWidget {
  const GeneralReportPage({super.key});
  @override
  State<GeneralReportPage> createState() => _GeneralReportPageState();
}

class _GeneralReportPageState extends State<GeneralReportPage> {
  List<EcgResult> _ecg = const [];
  Map? _fd;
  bool _loaded = false, _busy = false, _sync = false;
  double _syncP = 0;
  final GlobalKey _btnKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await ReportStore.I.init();
    final e = await EcgHistory.load();
    final fd = await _loadFood();
    if (!mounted) return;
    setState(() {
      _ecg = e;
      _fd = fd;
      _loaded = true;
    });
  }

  Future<void> _doSync() async {
    if (_sync || !VexBand.I.linked) return;
    setState(() {
      _sync = true;
      _syncP = 0;
    });
    try {
      await VexBand.I.syncAll(onProgress: (v) {
        if (mounted) setState(() => _syncP = v);
      });
      ReportStore.I.ingest(VexBand.I);
      VitalAgeEngine.I.ingest(VexBand.I);
      toast(_t('synced'));
    } catch (_) {}
    if (mounted) setState(() => _sync = false);
  }

  Rect _origin() {
    final b = _btnKey.currentContext?.findRenderObject() as RenderBox?;
    if (b == null || !b.hasSize) return const Rect.fromLTWH(0, 0, 10, 10);
    return b.localToGlobal(Offset.zero) & b.size;
  }

  Future<void> _pdf(_Rep r) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final bytes = await _makePdf(r);
      final name = 'VEX-Report-${_key(DateTime.now())}.pdf';
      await Share.shareXFiles(
        [XFile.fromData(bytes, mimeType: 'application/pdf', name: name)],
        fileNameOverrides: [name],
        subject: _t('share'),
        sharePositionOrigin: _origin(),
      );
    } catch (e) {
      debugPrint('report pdf: $e');
      toast(_t('pdfErr'));
    }
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([ReportStore.I, BandState.I, VexBand.I, VexTheme.I, LangState.I, VitalAgeEngine.I]),
      builder: (context, _) {
        final p = VexTheme.I.isLight ? _pLight : _pDark;
        final mq = MediaQuery.of(context);
        final r = _build(_ecg, _fd);
        final blocks = _loaded ? _blocks(r, p) : const <List<Widget>>[];
        final fg = p.dark ? const Color(0xFFEFFEFF) : const Color(0xFF062832);
        Widget ib(String icon, VoidCallback? f, {Key? key, bool flip = false}) => Press(
              key: key,
              onTap: f,
              child: Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: p.dark ? const Color(0xB30C3A48) : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: p.dark ? const Color(0x388CEBF5) : const Color(0xFFDCE5E8)),
                ),
                child: Transform.flip(flipX: flip, child: _svg(icon, fg, 20, sw: 2.2)),
              ),
            );
        return Directionality(
          textDirection: _dir,
          child: Scaffold(
            backgroundColor: V.bg,
            body: Stack(children: [
              const Positioned.fill(child: Aurora()),
              ListView(
                padding: EdgeInsets.fromLTRB(12, mq.padding.top + 12, 12, mq.padding.bottom + 30),
                children: [
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 460),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                        Row(children: [
                          ib(_iBack, () => Navigator.of(context).maybePop(), flip: !_rtl),
                          Expanded(child: _tx(_t('t'), 17, fg, w: FontWeight.w800, a: TextAlign.center)),
                          ib(_iDl, _loaded && !_busy ? () => _pdf(r) : null),
                        ]),
                        _gap(12),
                        if (r.linked || r.lastSync.isNotEmpty) _syncBar(p, r, fg),
                        if (!_loaded)
                          const Padding(padding: EdgeInsets.all(60), child: Center(child: CircularProgressIndicator()))
                        else
                          Container(
                            clipBehavior: Clip.antiAlias,
                            decoration: BoxDecoration(
                              color: p.paper,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: p.kvl),
                              boxShadow: [BoxShadow(color: p.dark ? const Color(0x59000000) : const Color(0x170E2A33), blurRadius: 32, offset: const Offset(0, 14))],
                            ),
                            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                              for (var i = 0; i < blocks.length; i++)
                                Rise(
                                  delayMs: math.min(i, 8) * 50,
                                  child: Padding(
                                    padding: i == 0 ? EdgeInsets.zero : const EdgeInsets.symmetric(horizontal: 16),
                                    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: blocks[i]),
                                  ),
                                ),
                            ]),
                          ),
                        _gap(18),
                        Press(
                          key: _btnKey,
                          onTap: _loaded && !_busy ? () => _pdf(r) : null,
                          child: Container(
                            height: 56,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(colors: p.btn),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [BoxShadow(color: p.dark ? const Color(0x403CF08A) : const Color(0x400E2A33), blurRadius: 24, offset: const Offset(0, 10))],
                            ),
                            child: Row(mainAxisSize: MainAxisSize.min, children: [
                              if (_busy)
                                SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.5, color: p.btnx))
                              else
                                _svg(_iDl, p.btnx, 21),
                              const SizedBox(width: 10),
                              _tx(_busy ? _t('pdfW') : _t('pdf'), 15.5, p.btnx, w: FontWeight.w800),
                            ]),
                          ),
                        ),
                        _gap(8),
                        _tx(_t('pdfNote'), 11.5, V.mu, a: TextAlign.center, h: 1.7),
                      ]),
                    ),
                  ),
                ],
              ),
            ]),
          ),
        );
      },
    );
  }

  Widget _syncBar(_P p, _Rep r, Color fg) {
    final on = r.linked;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
      decoration: BoxDecoration(
        color: p.dark ? const Color(0x940C3A48) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: p.dark ? const Color(0x218CEBF5) : const Color(0xFFDCE5E8)),
      ),
      child: Row(children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: r.connected ? const Color(0xFF3CF08A) : const Color(0xFFE5405F))),
        const SizedBox(width: 8),
        Expanded(
          child: _tx(
            _sync ? '${_t('syncing')} ${(_syncP * 100).round()}%' : (r.lastSync.isNotEmpty ? _f(_t('lastSync'), {'t': r.lastSync}) : 'VEX Band'),
            12,
            V.mu,
          ),
        ),
        if (on)
          Press(
            onTap: _sync ? null : _doSync,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(color: op(p.acc, .12), borderRadius: BorderRadius.circular(12), border: Border.all(color: op(p.acc, .4))),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                _sync
                    ? SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: p.acc))
                    : _svg(_iSync, p.acc, 15, sw: 2.2),
                const SizedBox(width: 6),
                _tx(_t('sync'), 12, p.acc, w: FontWeight.w800),
              ]),
            ),
          ),
      ]),
    );
  }
}

// ═════════════════════════════ PDF (A4) ═════════════════════════════
/// هەر پارچەیەک وێنە دەکرێت (ڕووناک) و لە PDF دا ڕیز دەکرێن؛ خشتەکان ڕیز بە ڕیز دابەش دەبن
Future<Uint8List> _makePdf(_Rep r) async {
  final st = navKey.currentState;
  final ov = st?.overlay;
  if (ov == null) throw StateError('no overlay');
  final blocks = _blocks(r, _pLight, print: true);
  final parts = <Widget>[];
  for (var i = 0; i < blocks.length; i++) {
    for (var j = 0; j < blocks[i].length; j++) {
      parts.add(Padding(
        padding: EdgeInsets.only(top: i == 0 || j > 0 ? 0 : 2),
        child: blocks[i][j],
      ));
    }
  }
  const w = 560.0;
  final keys = List.generate(parts.length, (_) => GlobalKey());
  final entry = OverlayEntry(
    builder: (c) => Stack(children: [
      Positioned(
        left: 0,
        top: 0,
        width: w,
        child: IgnorePointer(
          child: MediaQuery(
            data: MediaQuery.of(c).copyWith(textScaler: TextScaler.noScaling),
            child: Directionality(
              textDirection: _dir,
              child: Material(
                color: Colors.white,
                child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  for (var i = 0; i < parts.length; i++)
                    RepaintBoundary(key: keys[i], child: ColoredBox(color: Colors.white, child: parts[i])),
                ]),
              ),
            ),
          ),
        ),
      ),
      // پەردە: بەکارهێنەر وێنەگرتنەکە نابینێت
      Positioned.fill(
        child: ColoredBox(
          color: V.bg,
          child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 14),
            Text(_t('pdfW'), textDirection: _dir, style: ku(14, w: FontWeight.w700, c: V.tx)),
          ])),
        ),
      ),
    ]),
  );
  ov.insert(entry);
  final images = <Uint8List>[];
  try {
    await WidgetsBinding.instance.endOfFrame;
    await Future<void>.delayed(const Duration(milliseconds: 250));
    await WidgetsBinding.instance.endOfFrame;
    for (final k in keys) {
      final ro = k.currentContext?.findRenderObject();
      if (ro is! RenderRepaintBoundary) continue;
      for (var t = 0; kDebugMode && t < 20 && ro.debugNeedsPaint; t++) {
        WidgetsBinding.instance.scheduleFrame();
        await WidgetsBinding.instance.endOfFrame;
      }
      final img = await ro.toImage(pixelRatio: 3);
      // پارچەیەکی زۆر درێژ دەکرێتە چەند لاپەڕە
      const maxH = 2200;
      if (img.height <= maxH) {
        final bd = await img.toByteData(format: ui.ImageByteFormat.png);
        if (bd != null) images.add(bd.buffer.asUint8List());
      } else {
        for (var y = 0; y < img.height; y += maxH) {
          final h = math.min(maxH, img.height - y);
          final rec = ui.PictureRecorder();
          Canvas(rec).drawImageRect(img, Rect.fromLTWH(0, y.toDouble(), img.width.toDouble(), h.toDouble()),
              Rect.fromLTWH(0, 0, img.width.toDouble(), h.toDouble()), Paint());
          final part = await rec.endRecording().toImage(img.width, h);
          final bd = await part.toByteData(format: ui.ImageByteFormat.png);
          part.dispose();
          if (bd != null) images.add(bd.buffer.asUint8List());
        }
      }
      img.dispose();
    }
  } finally {
    entry.remove();
  }
  if (images.isEmpty) throw StateError('no images');

  final doc = pw.Document(title: 'VEX Health General Report ${r.no}', author: 'VEX Health', creator: 'VEX Health');
  final now = DateTime.now();
  const grey = PdfColor.fromInt(0xFF566D76);
  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(26, 24, 26, 22),
      header: (ctx) => ctx.pageNumber == 1
          ? pw.SizedBox()
          : pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 8),
              padding: const pw.EdgeInsets.only(bottom: 6),
              decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColor.fromInt(0xFF0E2A33), width: 1.5))),
              child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                pw.Text('VEX HEALTH', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, letterSpacing: 1.4)),
                pw.Text('No. ${r.no}', style: const pw.TextStyle(fontSize: 8.5, color: grey)),
              ]),
            ),
      footer: (ctx) => pw.Container(
        margin: const pw.EdgeInsets.only(top: 8),
        padding: const pw.EdgeInsets.only(top: 5),
        decoration: const pw.BoxDecoration(border: pw.Border(top: pw.BorderSide(color: PdfColor.fromInt(0xFFE3EAED), width: .8))),
        child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
          pw.Text('VEX Health - ${_dmy(now)}', style: const pw.TextStyle(fontSize: 8, color: grey)),
          pw.Text('${ctx.pageNumber} / ${ctx.pagesCount}', style: const pw.TextStyle(fontSize: 8, color: grey)),
        ]),
      ),
      build: (ctx) => [for (final b in images) pw.Image(pw.MemoryImage(b), width: PdfPageFormat.a4.width - 52, fit: pw.BoxFit.fitWidth)],
    ),
  );
  return doc.save();
}

// ═════════════════════════════ کارتی پرۆفایل ═════════════════════════════
/// کارتی «ڕاپۆرتی گشتی» بۆ بەشی پرۆفایل
class ReportCard extends StatelessWidget {
  const ReportCard({super.key});
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([VexTheme.I, LangState.I]),
      builder: (context, _) {
        final light = VexTheme.I.isLight;
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Press(
            onTap: openGeneralReport,
            scale: 0.98,
            child: Container(
              padding: const EdgeInsets.fromLTRB(10, 10, 14, 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                gradient: LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  colors: light ? const [Color(0xFFF2FCFE), Color(0xFFE2F6F8)] : const [Color(0x3D2FE6F3), Color(0x0F3CF08A)],
                ),
                border: Border.all(color: light ? const Color(0xFF9BE3EA) : const Color(0x732FE6F3), width: 1.3),
                boxShadow: [BoxShadow(color: light ? const Color(0x2E0AA7B8) : const Color(0x332FE6F3), blurRadius: 24, offset: const Offset(0, 10), spreadRadius: -12)],
              ),
              child: Row(children: [
                SvgPicture.string(kReportIconSvg, width: 62, height: 62),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(_t('t'), style: ku(16, w: FontWeight.w800, c: V.tx, h: 1.5)),
                    Text(_t('sub'), style: ku(11.5, w: FontWeight.w600, c: V.mu, h: 1.5)),
                  ]),
                ),
                Container(
                  width: 34,
                  height: 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: light ? Colors.white : const Color(0x0EFFFFFF),
                    border: Border.all(color: light ? const Color(0xFFDCE5E8) : const Color(0x218CEBF5)),
                  ),
                  child: Transform.flip(flipX: kIsLtr, child: _svg('<path d="M15 6l-6 6 6 6"/>', V.c2, 18, sw: 2.6)),
                ),
              ]),
            ),
          ),
        );
      },
    );
  }
}

// ═════════════════════════════ وەرگێڕان (6 زمان) ═════════════════════════════
const Map<String, dynamic> _kTX = {"ckb": {"dir": "rtl", "t": "ڕاپۆرتی گشتی", "doc": "ڕاپۆرتی گشتیی تەندروستی", "per": "ماوە: 30 ڕۆژی ڕابردوو", "iss": "دەرچوون", "nm": "ناو", "age": "تەمەن / ڕەگەز", "ht": "باڵا", "wt": "کێش", "src": "سەرچاوە", "m": "نێر", "f": "مێ", "yrs": "ساڵ", "srcB": "ئەپ و \u2068VEX Band\u2069", "srcA": "تۆمارەکانی ئەپ", "conds": "دۆخی تەندروستی", "cvB": "{n} ڕۆژ داتای Band", "cvBo": "Band پەیوەست نییە", "cvF": "{n} ڕۆژ خواردن", "cvE": "{n} تۆماری ECG", "cvW": "{n} پێوانەی کێش", "score": "نمرەی گشتی", "lv": ["زۆر باش", "باش", "مامناوەند", "پێویستی بە سەرنجە"], "dUp": "لە {a} بۆ {b} بەرز بووەتەوە", "dDn": "لە {a} بۆ {b} دابەزیوە", "dEq": "وەک ڕاپۆرتی پێشوو", "dNew": "یەکەم ڕاپۆرتی تۆ", "va": "تەمەنی لەش (VitalAge)", "vaLock": "پێویستی بە {n} ڕۆژ داتای تەواوی Band هەیە", "vaBand": "پێویستی بە VEX Band هەیە", "nights": "ڕۆژ", "vaY": "{n} ساڵ گەنجتر لە تەمەنت", "vaO": "{n} ساڵ گەورەتر لە تەمەنت", "vaE": "هاوتای تەمەنی خۆتە", "s1": "نیشانە ژیانییەکان", "s2": "دڵ و ECG", "s3": "خەو", "s4": "خۆراک و ئاو", "s5": "جووڵە و کێش", "s6": "هەڵسەنگاندنی مەترسی", "s7": "پوختەی شیکاری", "s8": "ڕاسپاردەکان (بە ڕیزی گرنگی)", "thT": "پشکنین", "thR": "ئەنجام", "thN": "ئاسایی", "thS": "دۆخ", "hr": "لێدانی دڵ (تێکڕا)", "hrr": "کەمترین – زۆرترین لێدان", "hrv": "HRV (گۆڕانی لێدان)", "sp": "ئۆکسجینی خوێن SpO₂", "spl": "نزمترین SpO₂", "tp": "پلەی گەرمی پێست", "st": "فشاری دەروونی", "sl": "کاتی خەو", "stp": "هەنگاوی ڕۆژانە", "ok": "ئاسایی", "hi": "بەرز ↑", "lo": "کەم ↓", "mid": "مامناوەند", "na": "پەیوەست نییە", "nod": "داتا نییە", "good": "باش", "much": "زۆر ↑", "inf": "زانیاری", "bandOff": "VEX Band پەیوەست نییە، بۆیە پێوانەکانی Band لەم ڕاپۆرتەدا نین. Band ـەکەت پەیوەست بکە و هاوکاتی بکە.", "bandDays": "{n} ڕۆژ", "rh": "ڕیتمی دڵ", "rhOk": "ڕیتمی ڕێک", "rec": "تۆمارەکان", "recN": "{n} تۆمار · 0 ناڕێک", "lhr": "تێکڕای لێدان (دوایین)", "q": "کوالیتیی ئاماژە", "lst": "دوایین تۆمار", "ecgOk": "لە هەموو تۆمارەکاندا ڕیتمی دڵ ڕێک بووە و هیچ نیشانەیەکی لێدانی ناڕێک نەبینراوە.", "ecgNo": "هێشتا هیچ پێوانەیەکی ECG ت نییە. لە بەشی ECG ـەوە 30 چرکە پێوانە بکە تا لێرە دەربکەوێت.", "sla": "تێکڕای خەو", "eff": "کارایی خەو", "ln": "دوایین شەو", "dp": "قووڵ", "rm": "REM", "lt": "سووک", "aw": "بێدار", "debt": "قەرزی خەو: نزیکەی {h} کاتژمێر لە هەفتەیەکدا.", "slOk": "تێکڕای خەوت لە سنووری پێشنیارکراودایە (7–9 کاتژمێر).", "thE": "توخم", "thD": "تێکڕای ڕۆژ", "thG": "ئامانج", "kc": "کالۆری", "pr": "پرۆتین", "cb": "کارب", "ft": "چەوری", "fb": "فایبەر", "sg": "شەکر", "sa": "خوێ", "wa": "ئاو", "fdays": "لەسەر بنەمای {n} ڕۆژی تۆمارکراو لە 30 ڕۆژی ڕابردوودا", "fnone": "هێشتا هیچ خواردنێک تۆمار نەکراوە. لە بەشی خواردنەوە ژەمەکانت تۆمار بکە تا ئێرە پڕ بێتەوە.", "am": "خولەکی چالاک / هەفتە", "wo": "ڕاهێنان (30 ڕۆژ)", "bn": "کالۆری سووتاو (ڕاهێنان)", "wc": "گۆڕانی کێش", "bt": "BMR / TDEE", "one": "یەک پێوانە", "rc": "دڵ و خوێنبەر", "rmt": "مێتابۆلیزم و کێش", "rs": "خەو و ماندووبوون", "ra": "کەم جووڵەیی", "low": "نزم", "mod": "مامناوەند", "high": "بەرز", "sIn": "دۆخی گشتی: {lvl} — نمرەی {s} لە 100.", "sGood": "ئەم بەشانە باشن: {x}.", "sAtt": "ئەم بەشانە پێویستیان بە سەرنجە: {x}.", "sAll": "هیچ خاڵێکی پێویست بە سەرنج نەبینرا؛ بەم شێوەیە بەردەوام بە.", "and": " و ", "sep": "، ", "g": {"hr": "لێدانی دڵ", "sp": "ئۆکسجینی خوێن", "ecg": "ڕیتمی دڵ (ECG)", "sl": "خەو", "st": "فشاری دەروونی", "stp": "جووڵە", "kc": "کالۆری", "pr": "پرۆتین", "fb": "فایبەر", "sg": "شەکر", "sa": "خوێ", "wa": "ئاو", "bmi": "کێش (BMI)", "tp": "پلەی گەرمی"}, "r": {"salt": "خوێ بگەیەنە ژێر 5 گرام لە ڕۆژێکدا؛ ترشی، پەنیری سوێر و خواردنی ئامادە کەم بکەرەوە.", "sleep": "کاتێکی جێگیر بۆ نووستن دابنێ و شەوانە لانیکەم 7 کاتژمێر بخەوە.", "stress": "ڕۆژانە 2–3 جار 5 خولەک هەناسەی قووڵ هەڵبکێشە و پشووی کورت لە شاشە وەربگرە.", "prot": "ڕۆژانە نزیکەی {n} گرام پرۆتینی زیاتر بخۆ: هێلکە، ماست، نیسک، مریشک یان ماسی.", "fib": "فایبەر زیاد بکە: سەوزە لە هەموو ژەمێکدا و نانی جۆ لە جیاتی نانی سپی.", "water": "ڕۆژانە نزیکەی {n} پەرداخ ئاوی زیاتر بخۆرەوە.", "steps": "ڕۆژانە نزیکەی {n} هەنگاوی زیاتر بڕۆ؛ 10 خولەک پیاسە دوای نانخواردن یارمەتیدەرە.", "sug": "شەکر کەم بکەرەوە: خواردنەوەی شیرین و شیرینی لە ڕۆژانەوە بکە بە جارجار.", "kcalHi": "کالۆری ڕۆژانەت لە ئامانج زیاترە؛ بڕی ژەمەکان و ژەمە سووکەکان کەم بکەرەوە.", "kcalLo": "کالۆری ڕۆژانەت زۆر لە ئامانج کەمترە؛ ژەمەکانت بە پرۆتین و دانەوێڵەی تەواو پڕتر بکە.", "bmi": "کەمکردنەوەی کێش بە هێواشی (نزیکەی 0.5 کیلۆ لە هەفتەیەکدا) کاریگەریی باشی لەسەر دڵ و شەکری خوێن دەبێت.", "ecg": "مانگانە لانیکەم یەک پێوانەی ECG بکە بۆ چاودێریی ڕیتمی دڵ.", "food": "ژەمەکانت لە بەشی خواردن تۆمار بکە تا شیکاری خۆراک وردتر بێت.", "band": "VEX Band پەیوەست بکە بۆ ئەوەی لێدانی دڵ، خەو، ئۆکسجین و فشاری دەروونی لە ڕاپۆرتەکەدا بن.", "keep": "پێوەرەکانت باشن؛ هەمان شێوازی ژیان بەردەوام بکە و مانگی داهاتوو دووبارە ڕاپۆرت وەربگرە."}, "docT": "کەی سەردانی پزیشک بکەیت؟", "docX": "ئەگەر ئازار یان تەنگیی سنگ، سەرگێژخواردن، هەناسەتەنگی یان لێدانی ناڕێکت هەست پێ کرد، یان ئۆکسجینی خوێنت بە بەردەوامی لە 92% کەمتر بوو، دەستبەجێ سەردانی پزیشک بکە.", "docC": "بەهۆی ({x})، ئەم ڕاپۆرتە لە سەردانی داهاتوودا پیشانی پزیشکەکەت بدە.", "by": "شیکاری لەلایەن", "eng": "VEX AI · بزوێنەری تەندروستی", "pts": "{n} خاڵی داتا", "disc": "ئەم ڕاپۆرتە لەسەر بنەمای داتای VEX Band و تۆمارەکانی ناو ئەپ دروست کراوە و دەستنیشانکردنی نەخۆشی (تشخیص) نییە. بۆ هەر بڕیارێکی پزیشکی، ڕاپۆرتەکە پیشانی پزیشکەکەت بدە.", "pdf": "داگرتنی PDF", "pdfW": "ئامادەکردنی PDF…", "pdfOk": "PDF ئامادە کرا ✓", "pdfNo": "داگرتنی فایل لێرە بەردەست نییە؛ لاپەڕەکانی ڕاپۆرت لێرە دەبینیت.", "pdfErr": "دروستکردنی PDF سەرکەوتوو نەبوو؛ دووبارە هەوڵ بدەرەوە.", "pdfDec": "داگرتن هەڵوەشێنرایەوە", "pdfNote": "PDF ـەکە بە قەبارەی A4 ئامادە دەکرێت و بۆ پیشاندان بە پزیشک گونجاوە.", "pv": "پێشبینینی ڕاپۆرت", "pg": "لاپەڕە {a} لە {b}", "back": "گەڕانەوە", "cn": {"diab": "شەکرە", "bp": "فشاری خوێن", "chol": "کۆلیسترۆڵ", "heart": "نەخۆشی دڵ", "kid": "نەخۆشی گورچیلە", "gout": "نیقرس", "gerd": "ڕیفلاکس", "preg": "دووگیانی", "bf": "شیردان", "asth": "ڕەبۆ", "thy": "تیرۆید"}, "sync": "هاوکاتکردنی Band", "syncing": "هاوکاتکردن…", "lastSync": "دوایین هاوکاتکردن: {t}", "synced": "هاوکاتکرا ✓", "bp": "پەستانی خوێن (خەمڵاندن)", "br": "ڕێژەی هەناسە", "rhr": "لێدانی دڵی ئارام", "irr": "{n} تۆماری ناڕێک", "rhIrr": "ناڕێکی دەبینرێت", "ecgIrr": "لە {n} تۆماردا لێدانی ناڕێک بینراوە؛ ئەم ڕاپۆرتە پیشانی پزیشکەکەت بدە.", "g_bp": "پەستانی خوێن", "sub": "پشکنینی گشتی و شیکاری · PDF", "share": "ڕاپۆرتی گشتیی VEX Health"}, "kmr": {"dir": "rtl", "t": "ڕاپۆرتا گشتی", "doc": "ڕاپۆرتا گشتی یا ساخلەمیێ", "per": "ماوە: 30 ڕۆژێن بۆری", "iss": "دەرچوون", "nm": "ناڤ", "age": "ژی / ڕەگەز", "ht": "درێژی", "wt": "کێش", "src": "ژێدەر", "m": "نێر", "f": "مێ", "yrs": "ساڵ", "srcB": "ئەپ و \u2068VEX Band\u2069", "srcA": "تۆمارێن ئەپێ", "conds": "ڕەوشا ساخلەمیێ", "cvB": "{n} ڕۆژێن داتایێن Band", "cvBo": "Band نەگرێدایە", "cvF": "{n} ڕۆژێن خوارنێ", "cvE": "{n} تۆمارێن ECG", "cvW": "{n} پیڤانێن کێشێ", "score": "نمرا گشتی", "lv": ["گەلەک باش", "باش", "ناڤنجی", "پێدڤی ب سەرنجێ یە"], "dUp": "ژ {a} بۆ {b} بلند بوویە", "dDn": "ژ {a} بۆ {b} نزم بوویە", "dEq": "وەکی ڕاپۆرتا بەری", "dNew": "ئێکەم ڕاپۆرتا تە", "va": "ژیێ لەشی (VitalAge)", "vaLock": "پێدڤی ب {n} ڕۆژێن داتایێن تەمامێن Band هەیە", "vaBand": "پێدڤی ب VEX Band هەیە", "nights": "ڕۆژ", "vaY": "{n} ساڵان گەنجترە ژ ژیێ تە", "vaO": "{n} ساڵان مەزنترە ژ ژیێ تە", "vaE": "وەکی ژیێ تە یە", "s1": "نیشانێن ژیانێ", "s2": "دل و ECG", "s3": "خەو", "s4": "خوارن و ئاڤ", "s5": "لڤین و کێش", "s6": "هەلسەنگاندنا مەترسیێ", "s7": "کورتیا شلۆڤەکرنێ", "s8": "ڕاسپاردە (ل دویڤ گرنگیێ)", "thT": "پشکنین", "thR": "ئەنجام", "thN": "ئاسایی", "thS": "ڕەوش", "hr": "لێدانا دلی (تێکڕا)", "hrr": "کێمترین – زێدەترین لێدان", "hrv": "HRV (گوهۆڕینا لێدانێ)", "sp": "ئۆکسجینا خوینێ SpO₂", "spl": "نزمترین SpO₂", "tp": "پلا گەرمیا پێستی", "st": "فشارا دەروونی", "sl": "دەمێ خەوێ", "stp": "پێنگاڤێن ڕۆژانە", "ok": "ئاسایی", "hi": "بلند ↑", "lo": "کێم ↓", "mid": "ناڤنجی", "na": "نەگرێدایە", "nod": "داتا نینە", "good": "باش", "much": "زێدە ↑", "inf": "زانیاری", "bandOff": "VEX Band نەگرێدایە، لەوما پیڤانێن Band د ڤێ ڕاپۆرتێ دا نینن. Band ـا خۆ گرێبدە و هاوکات بکە.", "bandDays": "{n} ڕۆژ", "rh": "ڕیتما دلی", "rhOk": "ڕیتما ڕێک", "rec": "تۆمار", "recN": "{n} تۆمار · 0 نەڕێک", "lhr": "تێکڕایا لێدانێ (دوماهیک)", "q": "کوالیتیا ئاماژێ", "lst": "دوماهیک تۆمار", "ecgOk": "د هەمی تۆماران دا ڕیتما دلی ڕێک بوو و چ نیشانێن لێدانا نەڕێک نەهاتنە دیتن.", "ecgNo": "هێشتا چ پیڤانێن ECG نینن. ژ پشکا ECG ـێ 30 چرکەیان بپیڤە دا ل ڤێرە دیار ببیت.", "sla": "تێکڕایا خەوێ", "eff": "کارینەریا خەوێ", "ln": "دوماهیک شەڤ", "dp": "کویر", "rm": "REM", "lt": "سڤک", "aw": "هشیار", "debt": "قەرزێ خەوێ: نێزیکی {h} دەمژمێران د حەفتیێ دا.", "slOk": "تێکڕایا خەوا تە د سنوورێ پێشنیارکری دایە (7–9 دەمژمێر).", "thE": "توخم", "thD": "تێکڕایا ڕۆژێ", "thG": "ئارمانج", "kc": "کالۆری", "pr": "پرۆتین", "cb": "کارب", "ft": "چەوری", "fb": "فایبەر", "sg": "شەکر", "sa": "خوێ", "wa": "ئاڤ", "fdays": "ل سەر بنیاتێ {n} ڕۆژێن تۆمارکری د 30 ڕۆژێن بۆری دا", "fnone": "هێشتا چ خوارن نەهاتینە تۆمارکرن. ژ پشکا خوارنێ ژەمێن خۆ تۆمار بکە دا ئەڤ پشکە پڕ ببیت.", "am": "خولەکێن چالاک / حەفتی", "wo": "ڕاهێنان (30 ڕۆژ)", "bn": "کالۆریێن سۆتی (ڕاهێنان)", "wc": "گوهۆڕینا کێشێ", "bt": "BMR / TDEE", "one": "ئێک پیڤان", "rc": "دل و خوینبەر", "rmt": "مێتابۆلیزم و کێش", "rs": "خەو و وەستیان", "ra": "کێم لڤین", "low": "نزم", "mod": "ناڤنجی", "high": "بلند", "sIn": "ڕەوشا گشتی: {lvl} — نمرا {s} ژ 100.", "sGood": "ئەڤ پشکە باشن: {x}.", "sAtt": "ئەڤ پشکە پێدڤی ب سەرنجێ نە: {x}.", "sAll": "چ خاڵێن پێدڤی ب سەرنجێ نەهاتنە دیتن؛ ب ڤی ڕەنگی بەردەوام بە.", "and": " و ", "sep": "، ", "g": {"hr": "لێدانا دلی", "sp": "ئۆکسجینا خوینێ", "ecg": "ڕیتما دلی (ECG)", "sl": "خەو", "st": "فشارا دەروونی", "stp": "لڤین", "kc": "کالۆری", "pr": "پرۆتین", "fb": "فایبەر", "sg": "شەکر", "sa": "خوێ", "wa": "ئاڤ", "bmi": "کێش (BMI)", "tp": "پلا گەرمیێ"}, "r": {"salt": "خوێیێ بگەهینە بن 5 گرامان د ڕۆژێ دا؛ ترشی، پەنیرێ سوێر و خوارنێن ئامادە کێم بکە.", "sleep": "دەمەکێ جێگیر بۆ نڤستنێ دانە و شەڤانە کێمتر نە ژ 7 دەمژمێران بنڤە.", "stress": "ڕۆژانە 2–3 جاران 5 خولەکان هەناسێن کویر بکێشە و بێهنڤەدانێن کورت ژ شاشێ وەربگرە.", "prot": "ڕۆژانە نێزیکی {n} گرامان پرۆتینا زێدەتر بخۆ: هێک، ماست، نیسک، مریشک یان ماسی.", "fib": "فایبەرێ زێدە بکە: سەوزە د هەمی ژەمان دا و نانێ جەهی ل جهێ نانێ سپی.", "water": "ڕۆژانە نێزیکی {n} پەرداخێن ئاڤێ زێدەتر ڤەخۆ.", "steps": "ڕۆژانە نێزیکی {n} پێنگاڤێن زێدەتر بهاڤێژە؛ 10 خولەک پیاسە پشتی خوارنێ هاریکارە.", "sug": "شەکرێ کێم بکە: ڤەخوارنێن شرین و شرینیان ژ ڕۆژانە بکە جار جار.", "kcalHi": "کالۆریێن ڕۆژانە یێن تە ژ ئارمانجێ زێدەترن؛ بڕێ ژەمان و ژەمێن سڤک کێم بکە.", "kcalLo": "کالۆریێن ڕۆژانە یێن تە گەلەک ژ ئارمانجێ کێمترن؛ ژەمێن خۆ ب پرۆتین و دانەوێڵێن تەمام پڕتر بکە.", "bmi": "کێمکرنا کێشێ ب هێدیکی (نێزیکی 0.5 کیلۆ د حەفتیێ دا) کارتێکرنەکا باش ل سەر دلی و شەکرا خوینێ دکەت.", "ecg": "هەر هەیڤ کێمتر نە ژ ئێک پیڤانا ECG بکە بۆ چاڤدێریا ڕیتما دلی.", "food": "ژەمێن خۆ ل پشکا خوارنێ تۆمار بکە دا شلۆڤەکرنا خوارنێ دروستتر ببیت.", "band": "VEX Band گرێبدە دا لێدانا دلی، خەو، ئۆکسجین و فشارا دەروونی د ڕاپۆرتێ دا هەبن.", "keep": "پیڤەرێن تە باشن؛ ب هەمان شێوازێ ژیانێ بەردەوام بە و هەیڤا بهێت دووبارە ڕاپۆرتێ وەربگرە."}, "docT": "کەنگی سەرەدانا نۆژداری بکەی؟", "docX": "ئەگەر ئێش یان تەنگیا سنگی، گێژبوون، هەناسەتەنگی یان لێدانا نەڕێک هەست پێ کر، یان ئۆکسجینا خوینا تە ب بەردەوامی ژ 92% کێمتر بوو، دەستبەجێ سەرەدانا نۆژداری بکە.", "docC": "ژ بەر ({x})، ڤێ ڕاپۆرتێ د سەرەدانا بهێت دا نیشا نۆژدارێ خۆ بدە.", "by": "شلۆڤەکرن ژ لایێ", "eng": "VEX AI · بزوێنەرێ ساخلەمیێ", "pts": "{n} خاڵێن داتایان", "disc": "ئەڤ ڕاپۆرتە ل سەر بنیاتێ داتایێن VEX Band و تۆمارێن ناڤ ئەپێ هاتیە دروستکرن و دەستنیشانکرنا نەخۆشیێ (تشخیص) نینە. بۆ هەر بڕیارەکا پزیشکی، ڕاپۆرتێ نیشا نۆژدارێ خۆ بدە.", "pdf": "داگرتنا PDF", "pdfW": "ئامادەکرنا PDF…", "pdfOk": "PDF ئامادە بوو ✓", "pdfNo": "داگرتنا فایلان ل ڤێرە بەردەست نینە؛ لاپەڕێن ڕاپۆرتێ ل ڤێرە دبینی.", "pdfErr": "دروستکرنا PDF سەرنەکەفت؛ دووبارە هەوڵ بدە.", "pdfDec": "داگرتن هاتە هەڵوەشاندن", "pdfNote": "PDF ب قەبارێ A4 دهێتە ئامادەکرن و بۆ نیشادانا نۆژداری گونجایە.", "pv": "پێشدیتنا ڕاپۆرتێ", "pg": "لاپەڕە {a} ژ {b}", "back": "زڤڕین", "cn": {"diab": "شەکرە", "bp": "فشارا خوینێ", "chol": "کۆلیسترۆڵ", "heart": "نەخۆشیا دلی", "kid": "نەخۆشیا گورچیلێ", "gout": "نیقرس", "gerd": "ڕیفلاکس", "preg": "دووگیانی", "bf": "شیردان", "asth": "ڕەبۆ", "thy": "تیرۆید"}, "sync": "هاوکاتکرنا Band", "syncing": "هاوکاتکرن…", "lastSync": "دوماهیک هاوکاتکرن: {t}", "synced": "هاتە هاوکاتکرن ✓", "bp": "فشارا خوینێ (خەمڵاندن)", "br": "ڕێژا هەناسێ", "rhr": "لێدانا دلێ ئارام", "irr": "{n} تۆمارێن نەڕێک", "rhIrr": "نەڕێکی دهێتە دیتن", "ecgIrr": "د {n} تۆماران دا لێدانا نەڕێک هاتە دیتن؛ ڤێ ڕاپۆرتێ نیشا نۆژدارێ خۆ بدە.", "g_bp": "فشارا خوینێ", "sub": "پشکنینا گشتی و شلۆڤەکرن · PDF", "share": "ڕاپۆرتا گشتی یا VEX Health"}, "en": {"dir": "ltr", "t": "General Report", "doc": "General Health Report", "per": "Period: last 30 days", "iss": "Issued", "nm": "Name", "age": "Age / Sex", "ht": "Height", "wt": "Weight", "src": "Source", "m": "Male", "f": "Female", "yrs": "yrs", "srcB": "VEX Band + app", "srcA": "App records", "conds": "Health conditions", "cvB": "{n} days of Band data", "cvBo": "Band not connected", "cvF": "{n} food days", "cvE": "{n} ECG recordings", "cvW": "{n} weigh-ins", "score": "Overall score", "lv": ["Excellent", "Good", "Fair", "Needs attention"], "dUp": "Up from {a} to {b}", "dDn": "Down from {a} to {b}", "dEq": "Same as last report", "dNew": "Your first report", "va": "Body age (VitalAge)", "vaLock": "Needs {n} complete days of Band data", "vaBand": "Requires VEX Band", "nights": "days", "vaY": "{n} years younger than your age", "vaO": "{n} years older than your age", "vaE": "Same as your age", "s1": "Vital signs", "s2": "Heart & ECG", "s3": "Sleep", "s4": "Nutrition & water", "s5": "Activity & weight", "s6": "Risk assessment", "s7": "Summary", "s8": "Recommendations (by priority)", "thT": "Test", "thR": "Result", "thN": "Normal", "thS": "Status", "hr": "Heart rate (avg)", "hrr": "Lowest – highest rate", "hrv": "HRV (heart rate variability)", "sp": "Blood oxygen SpO₂", "spl": "Lowest SpO₂", "tp": "Skin temperature", "st": "Stress", "sl": "Sleep duration", "stp": "Daily steps", "ok": "Normal", "hi": "High ↑", "lo": "Low ↓", "mid": "Moderate", "na": "Not connected", "nod": "No data", "good": "Good", "much": "High ↑", "inf": "Info", "bandOff": "VEX Band is not connected, so Band measurements are not in this report. Connect and sync your Band.", "bandDays": "{n} days", "rh": "Heart rhythm", "rhOk": "Regular rhythm", "rec": "Recordings", "recN": "{n} recordings · 0 irregular", "lhr": "Average rate (latest)", "q": "Signal quality", "lst": "Latest recording", "ecgOk": "Heart rhythm was regular in every recording, with no signs of an irregular heartbeat.", "ecgNo": "No ECG measurements yet. Take a 30-second measurement in the ECG section and it will appear here.", "sla": "Average sleep", "eff": "Sleep efficiency", "ln": "Last night", "dp": "Deep", "rm": "REM", "lt": "Light", "aw": "Awake", "debt": "Sleep debt: about {h} hours per week.", "slOk": "Your average sleep is within the recommended range (7–9 hours).", "thE": "Nutrient", "thD": "Daily avg", "thG": "Target", "kc": "Calories", "pr": "Protein", "cb": "Carbs", "ft": "Fat", "fb": "Fiber", "sg": "Sugar", "sa": "Salt", "wa": "Water", "fdays": "Based on {n} logged days in the last 30 days", "fnone": "No food logged yet. Log your meals in the Food section to fill this part.", "am": "Active minutes / week", "wo": "Workouts (30 days)", "bn": "Calories burned (workouts)", "wc": "Weight change", "bt": "BMR / TDEE", "one": "One weigh-in", "rc": "Heart & circulation", "rmt": "Metabolism & weight", "rs": "Sleep & fatigue", "ra": "Inactivity", "low": "Low", "mod": "Moderate", "high": "High", "sIn": "Overall status: {lvl} — score {s} of 100.", "sGood": "Doing well: {x}.", "sAtt": "Needs attention: {x}.", "sAll": "Nothing needs attention right now; keep it up.", "and": " and ", "sep": ", ", "g": {"hr": "heart rate", "sp": "blood oxygen", "ecg": "heart rhythm (ECG)", "sl": "sleep", "st": "stress", "stp": "activity", "kc": "calories", "pr": "protein", "fb": "fiber", "sg": "sugar", "sa": "salt", "wa": "water", "bmi": "weight (BMI)", "tp": "temperature"}, "r": {"salt": "Keep salt under 5 g a day; cut down on pickles, salty cheese and processed food.", "sleep": "Set a fixed bedtime and sleep at least 7 hours a night.", "stress": "Take 5 minutes of deep breathing 2–3 times a day and short breaks from screens.", "prot": "Eat about {n} g more protein a day: eggs, yogurt, lentils, chicken or fish.", "fib": "Add fiber: vegetables with every meal and whole-grain bread instead of white bread.", "water": "Drink about {n} more glasses of water a day.", "steps": "Walk about {n} more steps a day; a 10-minute walk after meals helps.", "sug": "Cut sugar: make sweet drinks and desserts occasional rather than daily.", "kcalHi": "Your daily calories are above target; reduce portion sizes and snacks.", "kcalLo": "Your daily calories are well below target; make meals fuller with protein and whole grains.", "bmi": "Losing weight gradually (about 0.5 kg a week) benefits your heart and blood sugar.", "ecg": "Take at least one ECG measurement a month to track your heart rhythm.", "food": "Log your meals in the Food section for a more accurate nutrition analysis.", "band": "Connect VEX Band so heart rate, sleep, oxygen and stress are included in the report.", "keep": "Your measurements look good; keep the same routine and generate a new report next month."}, "docT": "When to see a doctor", "docX": "See a doctor right away if you feel chest pain or tightness, dizziness, shortness of breath or an irregular heartbeat, or if your blood oxygen stays below 92%.", "docC": "Because of ({x}), show this report to your doctor at your next visit.", "by": "Analysis by", "eng": "VEX AI · Health engine", "pts": "{n} data points", "disc": "This report is generated from VEX Band data and records in the app. It is not a medical diagnosis. For any medical decision, show this report to your doctor.", "pdf": "Download PDF", "pdfW": "Preparing PDF…", "pdfOk": "PDF ready ✓", "pdfNo": "File download is not available here; you can view the report pages below.", "pdfErr": "Could not create the PDF; please try again.", "pdfDec": "Download cancelled", "pdfNote": "The PDF is A4 sized and ready to show your doctor.", "pv": "Report preview", "pg": "Page {a} of {b}", "back": "Back", "cn": {"diab": "Diabetes", "bp": "High blood pressure", "chol": "Cholesterol", "heart": "Heart disease", "kid": "Kidney disease", "gout": "Gout", "gerd": "Reflux", "preg": "Pregnancy", "bf": "Breastfeeding", "asth": "Asthma", "thy": "Thyroid"}, "sync": "Sync Band", "syncing": "Syncing…", "lastSync": "Last sync: {t}", "synced": "Synced ✓", "bp": "Blood pressure (estimate)", "br": "Breathing rate", "rhr": "Resting heart rate", "irr": "{n} irregular recordings", "rhIrr": "Irregularity seen", "ecgIrr": "An irregular heartbeat was seen in {n} recordings; show this report to your doctor.", "g_bp": "blood pressure", "sub": "Full check-up & analysis · PDF", "share": "VEX Health General Report"}, "ar": {"dir": "rtl", "t": "التقرير العام", "doc": "التقرير الصحي العام", "per": "المدة: آخر 30 يومًا", "iss": "تاريخ الإصدار", "nm": "الاسم", "age": "العمر / الجنس", "ht": "الطول", "wt": "الوزن", "src": "المصدر", "m": "ذكر", "f": "أنثى", "yrs": "سنة", "srcB": "التطبيق و \u2068VEX Band\u2069", "srcA": "سجلات التطبيق", "conds": "الحالة الصحية", "cvB": "{n} أيام من بيانات السوار", "cvBo": "السوار غير متصل", "cvF": "{n} أيام طعام", "cvE": "{n} تسجيلات ECG", "cvW": "{n} قياسات وزن", "score": "النتيجة العامة", "lv": ["ممتاز", "جيد", "متوسط", "يحتاج إلى اهتمام"], "dUp": "ارتفعت من {a} إلى {b}", "dDn": "انخفضت من {a} إلى {b}", "dEq": "مثل التقرير السابق", "dNew": "تقريرك الأول", "va": "عمر الجسم (VitalAge)", "vaLock": "يحتاج إلى {n} يومًا من بيانات السوار الكاملة", "vaBand": "يتطلب سوار VEX Band", "nights": "أيام", "vaY": "أصغر من عمرك بـ {n} سنوات", "vaO": "أكبر من عمرك بـ {n} سنوات", "vaE": "مطابق لعمرك", "s1": "العلامات الحيوية", "s2": "القلب وتخطيط القلب", "s3": "النوم", "s4": "التغذية والماء", "s5": "النشاط والوزن", "s6": "تقييم المخاطر", "s7": "ملخص التحليل", "s8": "التوصيات (حسب الأولوية)", "thT": "الفحص", "thR": "النتيجة", "thN": "الطبيعي", "thS": "الحالة", "hr": "نبض القلب (المتوسط)", "hrr": "أدنى – أعلى نبض", "hrv": "تقلب نبض القلب HRV", "sp": "أكسجين الدم SpO₂", "spl": "أدنى SpO₂", "tp": "حرارة الجلد", "st": "التوتر", "sl": "مدة النوم", "stp": "الخطوات اليومية", "ok": "طبيعي", "hi": "مرتفع ↑", "lo": "منخفض ↓", "mid": "متوسط", "na": "غير متصل", "nod": "لا بيانات", "good": "جيد", "much": "مرتفع ↑", "inf": "معلومة", "bandOff": "سوار VEX Band غير متصل، لذلك لا تظهر قياساته في هذا التقرير. قم بتوصيله ومزامنته.", "bandDays": "{n} أيام", "rh": "نظم القلب", "rhOk": "نظم منتظم", "rec": "التسجيلات", "recN": "{n} تسجيلات · 0 غير منتظم", "lhr": "متوسط النبض (الأخير)", "q": "جودة الإشارة", "lst": "آخر تسجيل", "ecgOk": "كان نظم القلب منتظمًا في جميع التسجيلات، ولم تظهر أي علامة على عدم انتظام الضربات.", "ecgNo": "لا توجد قياسات ECG بعد. قم بقياس لمدة 30 ثانية من قسم ECG ليظهر هنا.", "sla": "متوسط النوم", "eff": "كفاءة النوم", "ln": "آخر ليلة", "dp": "عميق", "rm": "REM", "lt": "خفيف", "aw": "استيقاظ", "debt": "دَين النوم: حوالي {h} ساعات أسبوعيًا.", "slOk": "متوسط نومك ضمن المدى الموصى به (7–9 ساعات).", "thE": "العنصر", "thD": "متوسط اليوم", "thG": "الهدف", "kc": "السعرات", "pr": "البروتين", "cb": "الكربوهيدرات", "ft": "الدهون", "fb": "الألياف", "sg": "السكر", "sa": "الملح", "wa": "الماء", "fdays": "بناءً على {n} أيام مسجلة خلال آخر 30 يومًا", "fnone": "لم يُسجَّل أي طعام بعد. سجّل وجباتك من قسم الطعام ليمتلئ هذا الجزء.", "am": "دقائق النشاط / أسبوع", "wo": "التمارين (30 يومًا)", "bn": "السعرات المحروقة (تمارين)", "wc": "تغيّر الوزن", "bt": "BMR / TDEE", "one": "قياس واحد", "rc": "القلب والدورة الدموية", "rmt": "الأيض والوزن", "rs": "النوم والإرهاق", "ra": "قلة الحركة", "low": "منخفض", "mod": "متوسط", "high": "مرتفع", "sIn": "الحالة العامة: {lvl} — النتيجة {s} من 100.", "sGood": "جوانب جيدة: {x}.", "sAtt": "جوانب تحتاج إلى اهتمام: {x}.", "sAll": "لا توجد جوانب تحتاج إلى اهتمام حاليًا؛ استمر على هذا النحو.", "and": " و", "sep": "، ", "g": {"hr": "نبض القلب", "sp": "أكسجين الدم", "ecg": "نظم القلب (ECG)", "sl": "النوم", "st": "التوتر", "stp": "النشاط", "kc": "السعرات", "pr": "البروتين", "fb": "الألياف", "sg": "السكر", "sa": "الملح", "wa": "الماء", "bmi": "الوزن (BMI)", "tp": "الحرارة"}, "r": {"salt": "اجعل الملح أقل من 5 غرامات يوميًا؛ قلّل المخللات والأجبان المالحة والأطعمة الجاهزة.", "sleep": "حدّد موعدًا ثابتًا للنوم ونَم 7 ساعات على الأقل كل ليلة.", "stress": "خذ 5 دقائق من التنفس العميق 2–3 مرات يوميًا واستراحات قصيرة بعيدًا عن الشاشات.", "prot": "تناول حوالي {n} غرامًا إضافيًا من البروتين يوميًا: بيض، لبن، عدس، دجاج أو سمك.", "fib": "زِد الألياف: خضار مع كل وجبة وخبز أسمر بدل الخبز الأبيض.", "water": "اشرب حوالي {n} أكواب إضافية من الماء يوميًا.", "steps": "امشِ حوالي {n} خطوة إضافية يوميًا؛ المشي 10 دقائق بعد الأكل مفيد.", "sug": "قلّل السكر: اجعل المشروبات المحلاة والحلويات من حين لآخر بدل كل يوم.", "kcalHi": "سعراتك اليومية أعلى من الهدف؛ قلّل حجم الحصص والوجبات الخفيفة.", "kcalLo": "سعراتك اليومية أقل بكثير من الهدف؛ اجعل وجباتك أغنى بالبروتين والحبوب الكاملة.", "bmi": "إنقاص الوزن تدريجيًا (حوالي 0.5 كغ أسبوعيًا) مفيد للقلب وسكر الدم.", "ecg": "قم بقياس ECG مرة واحدة على الأقل شهريًا لمتابعة نظم القلب.", "food": "سجّل وجباتك في قسم الطعام ليصبح تحليل التغذية أدق.", "band": "وصّل سوار VEX Band ليشمل التقرير نبض القلب والنوم والأكسجين والتوتر.", "keep": "قياساتك جيدة؛ استمر على نفس نمط الحياة وأنشئ تقريرًا جديدًا الشهر القادم."}, "docT": "متى تراجع الطبيب؟", "docX": "راجع الطبيب فورًا إذا شعرت بألم أو ضيق في الصدر، أو دوخة، أو ضيق تنفس، أو خفقان غير منتظم، أو إذا بقي أكسجين الدم أقل من 92%.", "docC": "بسبب ({x})، اعرض هذا التقرير على طبيبك في زيارتك القادمة.", "by": "تحليل بواسطة", "eng": "VEX AI · محرك الصحة", "pts": "{n} نقطة بيانات", "disc": "أُعدّ هذا التقرير من بيانات VEX Band وسجلات التطبيق، وهو ليس تشخيصًا طبيًا. لأي قرار طبي، اعرض التقرير على طبيبك.", "pdf": "تنزيل PDF", "pdfW": "جارٍ تجهيز PDF…", "pdfOk": "ملف PDF جاهز ✓", "pdfNo": "تنزيل الملفات غير متاح هنا؛ يمكنك عرض صفحات التقرير أدناه.", "pdfErr": "تعذّر إنشاء PDF؛ حاول مرة أخرى.", "pdfDec": "أُلغي التنزيل", "pdfNote": "يُجهَّز ملف PDF بحجم A4 وهو مناسب لعرضه على الطبيب.", "pv": "معاينة التقرير", "pg": "صفحة {a} من {b}", "back": "رجوع", "cn": {"diab": "السكري", "bp": "ضغط الدم", "chol": "الكوليسترول", "heart": "أمراض القلب", "kid": "أمراض الكلى", "gout": "النقرس", "gerd": "الارتجاع", "preg": "الحمل", "bf": "الرضاعة", "asth": "الربو", "thy": "الغدة الدرقية"}, "sync": "مزامنة السوار", "syncing": "جارٍ المزامنة…", "lastSync": "آخر مزامنة: {t}", "synced": "تمت المزامنة ✓", "bp": "ضغط الدم (تقديري)", "br": "معدل التنفس", "rhr": "نبض الراحة", "irr": "{n} تسجيلات غير منتظمة", "rhIrr": "لوحظ عدم انتظام", "ecgIrr": "لوحظ نبض غير منتظم في {n} تسجيلات؛ اعرض هذا التقرير على طبيبك.", "g_bp": "ضغط الدم", "sub": "فحص شامل وتحليل · PDF", "share": "التقرير العام من VEX Health"}, "fa": {"dir": "rtl", "t": "گزارش کلی", "doc": "گزارش کلی سلامت", "per": "بازه: 30 روز گذشته", "iss": "تاریخ صدور", "nm": "نام", "age": "سن / جنسیت", "ht": "قد", "wt": "وزن", "src": "منبع", "m": "مرد", "f": "زن", "yrs": "سال", "srcB": "اپ و \u2068VEX Band\u2069", "srcA": "ثبت‌های اپ", "conds": "وضعیت سلامت", "cvB": "{n} روز داده Band", "cvBo": "Band متصل نیست", "cvF": "{n} روز غذا", "cvE": "{n} ثبت ECG", "cvW": "{n} وزن‌کشی", "score": "امتیاز کلی", "lv": ["عالی", "خوب", "متوسط", "نیازمند توجه"], "dUp": "از {a} به {b} افزایش یافته", "dDn": "از {a} به {b} کاهش یافته", "dEq": "مانند گزارش قبلی", "dNew": "نخستین گزارش شما", "va": "سن بدن (VitalAge)", "vaLock": "به {n} روز داده کامل Band نیاز دارد", "vaBand": "به VEX Band نیاز دارد", "nights": "روز", "vaY": "{n} سال جوان‌تر از سن شما", "vaO": "{n} سال مسن‌تر از سن شما", "vaE": "برابر با سن شما", "s1": "علائم حیاتی", "s2": "قلب و ECG", "s3": "خواب", "s4": "تغذیه و آب", "s5": "فعالیت و وزن", "s6": "ارزیابی خطر", "s7": "خلاصه تحلیل", "s8": "توصیه‌ها (به ترتیب اهمیت)", "thT": "آزمایش", "thR": "نتیجه", "thN": "طبیعی", "thS": "وضعیت", "hr": "ضربان قلب (میانگین)", "hrr": "کمترین – بیشترین ضربان", "hrv": "HRV (تغییرپذیری ضربان)", "sp": "اکسیژن خون SpO₂", "spl": "کمترین SpO₂", "tp": "دمای پوست", "st": "استرس", "sl": "مدت خواب", "stp": "قدم روزانه", "ok": "طبیعی", "hi": "بالا ↑", "lo": "پایین ↓", "mid": "متوسط", "na": "متصل نیست", "nod": "بدون داده", "good": "خوب", "much": "زیاد ↑", "inf": "اطلاعات", "bandOff": "VEX Band متصل نیست، بنابراین اندازه‌گیری‌های آن در این گزارش نیست. Band خود را متصل و همگام کنید.", "bandDays": "{n} روز", "rh": "ریتم قلب", "rhOk": "ریتم منظم", "rec": "ثبت‌ها", "recN": "{n} ثبت · 0 نامنظم", "lhr": "میانگین ضربان (آخرین)", "q": "کیفیت سیگنال", "lst": "آخرین ثبت", "ecgOk": "در همه ثبت‌ها ریتم قلب منظم بود و هیچ نشانه‌ای از ضربان نامنظم دیده نشد.", "ecgNo": "هنوز اندازه‌گیری ECG ندارید. از بخش ECG یک اندازه‌گیری 30 ثانیه‌ای انجام دهید تا اینجا نمایش داده شود.", "sla": "میانگین خواب", "eff": "بازده خواب", "ln": "شب گذشته", "dp": "عمیق", "rm": "REM", "lt": "سبک", "aw": "بیدار", "debt": "کمبود خواب: حدود {h} ساعت در هفته.", "slOk": "میانگین خواب شما در محدوده توصیه‌شده است (7–9 ساعت).", "thE": "ماده", "thD": "میانگین روزانه", "thG": "هدف", "kc": "کالری", "pr": "پروتئین", "cb": "کربوهیدرات", "ft": "چربی", "fb": "فیبر", "sg": "قند", "sa": "نمک", "wa": "آب", "fdays": "بر اساس {n} روز ثبت‌شده در 30 روز گذشته", "fnone": "هنوز غذایی ثبت نشده است. وعده‌های خود را در بخش غذا ثبت کنید تا این بخش پر شود.", "am": "دقیقه فعال / هفته", "wo": "تمرین‌ها (30 روز)", "bn": "کالری سوزانده (تمرین)", "wc": "تغییر وزن", "bt": "BMR / TDEE", "one": "یک وزن‌کشی", "rc": "قلب و گردش خون", "rmt": "متابولیسم و وزن", "rs": "خواب و خستگی", "ra": "کم‌تحرکی", "low": "پایین", "mod": "متوسط", "high": "بالا", "sIn": "وضعیت کلی: {lvl} — امتیاز {s} از 100.", "sGood": "موارد خوب: {x}.", "sAtt": "موارد نیازمند توجه: {x}.", "sAll": "در حال حاضر موردی نیازمند توجه نیست؛ همین‌طور ادامه دهید.", "and": " و ", "sep": "، ", "g": {"hr": "ضربان قلب", "sp": "اکسیژن خون", "ecg": "ریتم قلب (ECG)", "sl": "خواب", "st": "استرس", "stp": "فعالیت", "kc": "کالری", "pr": "پروتئین", "fb": "فیبر", "sg": "قند", "sa": "نمک", "wa": "آب", "bmi": "وزن (BMI)", "tp": "دما"}, "r": {"salt": "نمک را زیر 5 گرم در روز نگه دارید؛ ترشی، پنیر شور و غذاهای آماده را کم کنید.", "sleep": "ساعت ثابتی برای خواب تعیین کنید و هر شب دست‌کم 7 ساعت بخوابید.", "stress": "روزانه 2–3 بار 5 دقیقه تنفس عمیق انجام دهید و از صفحه‌نمایش استراحت‌های کوتاه بگیرید.", "prot": "روزانه حدود {n} گرم پروتئین بیشتر بخورید: تخم‌مرغ، ماست، عدس، مرغ یا ماهی.", "fib": "فیبر را افزایش دهید: سبزی در هر وعده و نان سبوس‌دار به جای نان سفید.", "water": "روزانه حدود {n} لیوان آب بیشتر بنوشید.", "steps": "روزانه حدود {n} قدم بیشتر راه بروید؛ 10 دقیقه پیاده‌روی پس از غذا کمک می‌کند.", "sug": "قند را کم کنید: نوشیدنی‌های شیرین و شیرینی را به جای هر روز، گاه‌به‌گاه مصرف کنید.", "kcalHi": "کالری روزانه شما بیشتر از هدف است؛ اندازه وعده‌ها و میان‌وعده‌ها را کم کنید.", "kcalLo": "کالری روزانه شما بسیار کمتر از هدف است؛ وعده‌ها را با پروتئین و غلات کامل کامل‌تر کنید.", "bmi": "کاهش تدریجی وزن (حدود 0.5 کیلو در هفته) برای قلب و قند خون مفید است.", "ecg": "دست‌کم ماهی یک بار ECG بگیرید تا ریتم قلب را پیگیری کنید.", "food": "وعده‌های خود را در بخش غذا ثبت کنید تا تحلیل تغذیه دقیق‌تر شود.", "band": "VEX Band را متصل کنید تا ضربان قلب، خواب، اکسیژن و استرس در گزارش بیایند.", "keep": "شاخص‌های شما خوب است؛ همین سبک زندگی را ادامه دهید و ماه آینده گزارش تازه بگیرید."}, "docT": "چه زمانی به پزشک مراجعه کنید؟", "docX": "اگر درد یا فشار قفسه سینه، سرگیجه، تنگی نفس یا ضربان نامنظم احساس کردید، یا اکسیژن خون شما مدام زیر 92% بود، فوراً به پزشک مراجعه کنید.", "docC": "به دلیل ({x})، این گزارش را در مراجعه بعدی به پزشک خود نشان دهید.", "by": "تحلیل توسط", "eng": "VEX AI · موتور سلامت", "pts": "{n} داده", "disc": "این گزارش بر پایه داده‌های VEX Band و ثبت‌های داخل اپ تهیه شده و تشخیص پزشکی نیست. برای هر تصمیم پزشکی، گزارش را به پزشک خود نشان دهید.", "pdf": "دانلود PDF", "pdfW": "در حال آماده‌سازی PDF…", "pdfOk": "PDF آماده شد ✓", "pdfNo": "دانلود فایل اینجا در دسترس نیست؛ صفحه‌های گزارش را در زیر می‌بینید.", "pdfErr": "ساخت PDF ناموفق بود؛ دوباره تلاش کنید.", "pdfDec": "دانلود لغو شد", "pdfNote": "PDF در اندازه A4 آماده می‌شود و برای نشان دادن به پزشک مناسب است.", "pv": "پیش‌نمایش گزارش", "pg": "صفحه {a} از {b}", "back": "بازگشت", "cn": {"diab": "دیابت", "bp": "فشار خون", "chol": "کلسترول", "heart": "بیماری قلبی", "kid": "بیماری کلیه", "gout": "نقرس", "gerd": "ریفلاکس", "preg": "بارداری", "bf": "شیردهی", "asth": "آسم", "thy": "تیروئید"}, "sync": "همگام‌سازی Band", "syncing": "در حال همگام‌سازی…", "lastSync": "آخرین همگام‌سازی: {t}", "synced": "همگام شد ✓", "bp": "فشار خون (تخمینی)", "br": "تعداد تنفس", "rhr": "ضربان استراحت", "irr": "{n} ثبت نامنظم", "rhIrr": "نامنظمی دیده شد", "ecgIrr": "در {n} ثبت ضربان نامنظم دیده شد؛ این گزارش را به پزشک خود نشان دهید.", "g_bp": "فشار خون", "sub": "بررسی کامل و تحلیل · PDF", "share": "گزارش کلی VEX Health"}, "tr": {"dir": "ltr", "t": "Genel Rapor", "doc": "Genel Sağlık Raporu", "per": "Dönem: son 30 gün", "iss": "Düzenlenme", "nm": "Ad", "age": "Yaş / Cinsiyet", "ht": "Boy", "wt": "Kilo", "src": "Kaynak", "m": "Erkek", "f": "Kadın", "yrs": "yaş", "srcB": "VEX Band + uygulama", "srcA": "Uygulama kayıtları", "conds": "Sağlık durumları", "cvB": "{n} gün Band verisi", "cvBo": "Band bağlı değil", "cvF": "{n} gün yemek", "cvE": "{n} EKG kaydı", "cvW": "{n} tartı", "score": "Genel puan", "lv": ["Mükemmel", "İyi", "Orta", "Dikkat gerektiriyor"], "dUp": "{a} puandan {b} puana yükseldi", "dDn": "{a} puandan {b} puana düştü", "dEq": "Önceki raporla aynı", "dNew": "İlk raporun", "va": "Vücut yaşı (VitalAge)", "vaLock": "{n} günlük tam Band verisi gerekiyor", "vaBand": "VEX Band gerekiyor", "nights": "gün", "vaY": "Yaşından {n} yıl genç", "vaO": "Yaşından {n} yıl büyük", "vaE": "Yaşınla aynı", "s1": "Yaşamsal bulgular", "s2": "Kalp ve EKG", "s3": "Uyku", "s4": "Beslenme ve su", "s5": "Aktivite ve kilo", "s6": "Risk değerlendirmesi", "s7": "Özet", "s8": "Öneriler (önem sırasına göre)", "thT": "Ölçüm", "thR": "Sonuç", "thN": "Normal", "thS": "Durum", "hr": "Nabız (ortalama)", "hrr": "En düşük – en yüksek nabız", "hrv": "HRV (kalp hızı değişkenliği)", "sp": "Kan oksijeni SpO₂", "spl": "En düşük SpO₂", "tp": "Cilt sıcaklığı", "st": "Stres", "sl": "Uyku süresi", "stp": "Günlük adım", "ok": "Normal", "hi": "Yüksek ↑", "lo": "Düşük ↓", "mid": "Orta", "na": "Bağlı değil", "nod": "Veri yok", "good": "İyi", "much": "Fazla ↑", "inf": "Bilgi", "bandOff": "VEX Band bağlı değil, bu yüzden Band ölçümleri bu raporda yok. Band'ini bağla ve senkronize et.", "bandDays": "{n} gün", "rh": "Kalp ritmi", "rhOk": "Düzenli ritim", "rec": "Kayıtlar", "recN": "{n} kayıt · 0 düzensiz", "lhr": "Ortalama nabız (son)", "q": "Sinyal kalitesi", "lst": "Son kayıt", "ecgOk": "Tüm kayıtlarda kalp ritmi düzenliydi; düzensiz kalp atışına dair bir işaret görülmedi.", "ecgNo": "Henüz EKG ölçümün yok. EKG bölümünden 30 saniyelik bir ölçüm yap, burada görünsün.", "sla": "Ortalama uyku", "eff": "Uyku verimi", "ln": "Son gece", "dp": "Derin", "rm": "REM", "lt": "Hafif", "aw": "Uyanık", "debt": "Uyku borcu: haftada yaklaşık {h} saat.", "slOk": "Ortalama uykun önerilen aralıkta (7–9 saat).", "thE": "Besin", "thD": "Günlük ort.", "thG": "Hedef", "kc": "Kalori", "pr": "Protein", "cb": "Karbonhidrat", "ft": "Yağ", "fb": "Lif", "sg": "Şeker", "sa": "Tuz", "wa": "Su", "fdays": "Son 30 gündeki {n} kayıtlı güne göre", "fnone": "Henüz yemek kaydı yok. Bu bölümü doldurmak için öğünlerini Yemek bölümünden kaydet.", "am": "Aktif dakika / hafta", "wo": "Antrenman (30 gün)", "bn": "Yakılan kalori (antrenman)", "wc": "Kilo değişimi", "bt": "BMR / TDEE", "one": "Tek tartı", "rc": "Kalp ve dolaşım", "rmt": "Metabolizma ve kilo", "rs": "Uyku ve yorgunluk", "ra": "Hareketsizlik", "low": "Düşük", "mod": "Orta", "high": "Yüksek", "sIn": "Genel durum: {lvl} — 100 üzerinden {s} puan.", "sGood": "İyi gidenler: {x}.", "sAtt": "Dikkat gerektirenler: {x}.", "sAll": "Şu an dikkat gerektiren bir şey yok; böyle devam et.", "and": " ve ", "sep": ", ", "g": {"hr": "nabız", "sp": "kan oksijeni", "ecg": "kalp ritmi (EKG)", "sl": "uyku", "st": "stres", "stp": "aktivite", "kc": "kalori", "pr": "protein", "fb": "lif", "sg": "şeker", "sa": "tuz", "wa": "su", "bmi": "kilo (BMI)", "tp": "sıcaklık"}, "r": {"salt": "Tuzu günde 5 gramın altında tut; turşu, tuzlu peynir ve hazır gıdaları azalt.", "sleep": "Sabit bir yatma saati belirle ve her gece en az 7 saat uyu.", "stress": "Günde 2–3 kez 5 dakika derin nefes al ve ekrandan kısa molalar ver.", "prot": "Günde yaklaşık {n} g daha fazla protein ye: yumurta, yoğurt, mercimek, tavuk ya da balık.", "fib": "Lifi artır: her öğünde sebze ve beyaz ekmek yerine tam tahıllı ekmek.", "water": "Günde yaklaşık {n} bardak daha fazla su iç.", "steps": "Günde yaklaşık {n} adım daha fazla yürü; yemekten sonra 10 dakikalık yürüyüş işe yarar.", "sug": "Şekeri azalt: şekerli içecekleri ve tatlıları her gün yerine ara sıra tüket.", "kcalHi": "Günlük kalorin hedefin üzerinde; porsiyonları ve atıştırmalıkları azalt.", "kcalLo": "Günlük kalorin hedefin çok altında; öğünlerini protein ve tam tahıllarla zenginleştir.", "bmi": "Kademeli kilo vermek (haftada yaklaşık 0,5 kg) kalbine ve kan şekerine iyi gelir.", "ecg": "Kalp ritmini izlemek için ayda en az bir EKG ölçümü yap.", "food": "Daha doğru bir beslenme analizi için öğünlerini Yemek bölümüne kaydet.", "band": "Nabız, uyku, oksijen ve stresin rapora girmesi için VEX Band'i bağla.", "keep": "Ölçümlerin iyi görünüyor; aynı düzene devam et ve gelecek ay yeni bir rapor oluştur."}, "docT": "Ne zaman doktora gitmeli?", "docX": "Göğüs ağrısı veya sıkışma, baş dönmesi, nefes darlığı ya da düzensiz kalp atışı hissedersen veya kan oksijenin sürekli %92'nin altındaysa hemen doktora git.", "docC": "({x}) nedeniyle bu raporu bir sonraki ziyaretinde doktoruna göster.", "by": "Analiz", "eng": "VEX AI · Sağlık motoru", "pts": "{n} veri noktası", "disc": "Bu rapor VEX Band verilerinden ve uygulamadaki kayıtlardan oluşturulmuştur; tıbbi bir teşhis değildir. Her tıbbi karar için raporu doktoruna göster.", "pdf": "PDF indir", "pdfW": "PDF hazırlanıyor…", "pdfOk": "PDF hazır ✓", "pdfNo": "Burada dosya indirme kullanılamıyor; rapor sayfalarını aşağıda görebilirsin.", "pdfErr": "PDF oluşturulamadı; lütfen tekrar dene.", "pdfDec": "İndirme iptal edildi", "pdfNote": "PDF A4 boyutunda hazırlanır ve doktoruna göstermeye uygundur.", "pv": "Rapor önizlemesi", "pg": "Sayfa {a} / {b}", "back": "Geri", "cn": {"diab": "Diyabet", "bp": "Yüksek tansiyon", "chol": "Kolesterol", "heart": "Kalp hastalığı", "kid": "Böbrek hastalığı", "gout": "Gut", "gerd": "Reflü", "preg": "Gebelik", "bf": "Emzirme", "asth": "Astım", "thy": "Tiroid"}, "sync": "Band'i senkronize et", "syncing": "Senkronize ediliyor…", "lastSync": "Son senkronizasyon: {t}", "synced": "Senkronize edildi ✓", "bp": "Tansiyon (tahmini)", "br": "Solunum hızı", "rhr": "Dinlenik nabız", "irr": "{n} düzensiz kayıt", "rhIrr": "Düzensizlik görüldü", "ecgIrr": "{n} kayıtta düzensiz kalp atışı görüldü; bu raporu doktoruna göster.", "g_bp": "tansiyon", "sub": "Genel kontrol ve analiz · PDF", "share": "VEX Health Genel Rapor"}};
