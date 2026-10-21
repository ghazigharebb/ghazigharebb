// VEX Health — "ڕۆژەکەت": هێڵی کاتی ڕۆژ (خەو، چالاکی، سترێس، ژەم و لێدانی دڵ)
import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../core/theme.dart';

// ---------------- داتا ----------------
class _Cat {
  const _Cat(this.n, this.e, this.c);
  final String n;
  final String e;
  final Color c;
}

const Map<String, _Cat> _cat = {
  'sleep': _Cat('خەو', '🌙', Color(0xFF8B6BFF)),
  'walk': _Cat('چالاکی', '🚶', Color(0xFF3CF08A)),
  'stress': _Cat('سترێس', '🧠', Color(0xFFFF5F7E)),
  'meal': _Cat('ژەم', '🍽️', Color(0xFFFFD56B)),
};

class _Seg {
  const _Seg(this.t, this.s, this.e,
      {this.deep = 0, this.rem = 0, this.score = 0, this.steps = 0, this.hr = 0, this.peak = 0, this.what = ''});
  final String t;
  final int s;
  final int e;
  final int deep;
  final int rem;
  final int score;
  final int steps;
  final int hr;
  final int peak;
  final String what;

  int get len => e - s;

  _Seg clip(int lim) => _Seg(t, s, math.min(e, lim),
      deep: deep, rem: rem, score: score, steps: steps, hr: hr, peak: peak, what: what);
}

class _Meal {
  const _Meal(this.m, this.e, this.n, this.k, this.v);
  final int m;
  final String e;
  final String n;
  final int k;
  final String v;
}

const List<List<_Seg>> _days = [
  [
    _Seg('sleep', 0, 410, deep: 92, rem: 84, score: 82),
    _Seg('walk', 455, 480, steps: 2100, hr: 104, what: 'ڕۆیشتن بۆ کار'),
    _Seg('stress', 630, 672, peak: 78, hr: 92, what: 'کاتی کار'),
    _Seg('walk', 745, 770, steps: 1850, hr: 101, what: 'پیاسەی نیوەڕۆ'),
    _Seg('stress', 860, 885, peak: 66, hr: 88),
    _Seg('walk', 1025, 1052, steps: 2840, hr: 112, what: 'پیاسەی ئێوارە'),
    _Seg('sleep', 1415, 1440),
  ],
  [
    _Seg('sleep', 0, 385, deep: 64, rem: 60, score: 68),
    _Seg('walk', 470, 490, steps: 1700, hr: 99, what: 'ڕۆیشتن بۆ کار'),
    _Seg('stress', 600, 690, peak: 84, hr: 95, what: 'کۆبوونەوەی کار'),
    _Seg('stress', 900, 930, peak: 71, hr: 90),
    _Seg('walk', 1100, 1150, steps: 4900, hr: 108, what: 'پیاسەی ئێوارە'),
    _Seg('sleep', 1390, 1440),
  ],
];

const List<List<_Meal>> _meals = [
  [
    _Meal(495, '🍳', 'نانی بەیانی', 420, 'good'),
    _Meal(790, '🍛', 'برنج و شلەی فاسۆلیا', 650, 'ok'),
    _Meal(1180, '🥗', 'سنگی مریشک و زەڵاتە', 480, 'good'),
  ],
  [
    _Meal(520, '🍳', 'نان و پەنیر', 380, 'ok'),
    _Meal(810, '🍔', 'بێرگەر', 720, 'bad'),
    _Meal(1260, '🍰', 'کێک', 410, 'bad'),
  ],
];

class _Ins {
  const _Ins(this.e, this.k, this.t, this.s, this.tm, {this.seg, this.meal});
  final String e;
  final Color k;
  final String t;
  final String s;
  final String tm;
  final _Seg? seg;
  final _Meal? meal;
}

class _InsSet {
  _InsSet(this.g, this.b, this.a);
  final List<_Ins> g;
  final List<_Ins> b;
  final List<_Ins> a;
  int get total => g.length + b.length + a.length;
}

String _tm(int m) {
  final x = ((m % 1440) + 1440) % 1440;
  return '${pad2(x ~/ 60)}:${pad2(x % 60)}';
}

String _dur(int m) {
  if (m >= 60) return '${m ~/ 60}ک${m % 60 != 0 ? ' ${m % 60}خ' : ''}';
  return '${m}خ';
}

double _x(double m) => m / 1440 * 1000;
double _hrY(double hr) => 338 - (clampD(hr, 45, 175) - 45) / 130 * (338 - 196);

// ============================================================
// کارتی ڕۆژەکەت
// ============================================================
class DayRibbonCard extends StatefulWidget {
  const DayRibbonCard({super.key});

  @override
  State<DayRibbonCard> createState() => _DayRibbonCardState();
}

class _DayRibbonCardState extends State<DayRibbonCard> with TickerProviderStateMixin {
  late final AnimationController grow =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1300));
  late final AnimationController pulse =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1600))..repeat();
  late final AnimationController flash =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 2400));

  int day = 0;
  String? fil;
  double? scrubM;
  int flashIdx = -1;
  Timer? _hideT;
  Timer? _minuteT;
  Timer? _openT;

  @override
  void initState() {
    super.initState();
    grow.forward();
    _minuteT = Timer.periodic(const Duration(seconds: 60), (_) {
      if (mounted && day == 0) setState(() {});
    });
  }

  @override
  void dispose() {
    _hideT?.cancel();
    _minuteT?.cancel();
    _openT?.cancel();
    grow.dispose();
    pulse.dispose();
    flash.dispose();
    super.dispose();
  }

  // ---- داتای ڕۆژی هەڵبژێردراو ----
  int get lim {
    if (day != 0) return 1440;
    final d = DateTime.now();
    return d.hour * 60 + d.minute;
  }

  List<_Seg> get segs {
    final l = lim;
    return [for (final s in _days[day]) if (s.s < l) s.clip(l)];
  }

  List<_Meal> get meals {
    final l = lim;
    return [for (final m in _meals[day]) if (m.m < l) m];
  }

  _Seg? typeAt(double m, [List<_Seg>? list]) {
    for (final s in list ?? segs) {
      if (m >= s.s && m < s.e) return s;
    }
    return null;
  }

  double hrAt(double m, [List<_Seg>? list]) {
    final s = typeAt(m, list);
    final n = math.sin(m * 0.21) * 3 + math.sin(m * 0.05) * 4;
    if (s == null) return 72 + n;
    if (s.t == 'sleep') return 56 + n * 0.6;
    if (s.t == 'walk') return (s.hr > 0 ? s.hr : 104) + n;
    if (s.t == 'stress') return (s.hr > 0 ? s.hr : 90) + n;
    return 72 + n;
  }

  // ---- تێبینییەکانی ڕۆژ ----
  _InsSet _insights() {
    final sg = segs;
    final ml = meals;
    final l = lim;
    final g = <_Ins>[];
    final b = <_Ins>[];
    final a = <_Ins>[];

    final walks = sg.where((x) => x.t == 'walk').toList();
    _Seg? bestWalk;
    for (final w in walks) {
      final cur = bestWalk;
      if (cur == null || w.steps > cur.steps) bestWalk = w;
    }
    _Seg? sleep;
    for (final x in sg) {
      if (x.t == 'sleep' && x.s == 0) {
        sleep = x;
        break;
      }
    }
    final stress = sg.where((x) => x.t == 'stress').toList()
      ..sort((p, q) {
        final d = q.len.compareTo(p.len);
        return d != 0 ? d : p.s.compareTo(q.s);
      });

    final sl = sleep;
    if (sl != null && sl.score >= 75) {
      g.add(_Ins('🌙', const Color(0xFF8B6BFF), 'خەوێکی باش',
          '${_dur(sl.len)} · خەوی قووڵ ${sl.deep}خ · نمرە ${sl.score}', '${_tm(sl.s)}–${_tm(sl.e)}',
          seg: sl));
    }
    final bw = bestWalk;
    if (bw != null) {
      g.add(_Ins('🚶', const Color(0xFF3CF08A), 'باشترین چالاکی: ${bw.what}',
          '${fmt(bw.steps)} هەنگاو · دڵ ${bw.hr} BPM', _tm(bw.s),
          seg: bw));
    }
    // ئارامترین کات
    final dayEnd = math.min(l, 1320);
    final marks = <int>[
      480,
      for (final x in stress) ...[x.s, x.e],
      dayEnd,
    ]..sort();
    int c0 = 0, c1 = 0;
    for (int i = 0; i < marks.length - 1; i++) {
      final p = marks[i], q = marks[i + 1];
      final inStress = stress.any((x) => p >= x.s && p < x.e);
      if (!inStress && q - p > c1 - c0) {
        c0 = p;
        c1 = q;
      }
    }
    if (c1 - c0 >= 90) {
      g.add(_Ins('🍃', const Color(0xFF2FE6F3), 'ئارامترین کاتت', 'سترێسی نزم و لێدانی دڵی هێمن',
          '${_tm(c0)}–${_tm(c1)}'));
    }
    if (stress.isNotEmpty) {
      final x = stress.first;
      b.add(_Ins('🧠', const Color(0xFFFF5F7E), 'زۆرترین سترێس${x.what.isNotEmpty ? ' · ${x.what}' : ''}',
          '${_dur(x.len)} · بەرزترین ${x.peak}', '${_tm(x.s)}–${_tm(x.e)}',
          seg: x));
    }
    // ماوەی بێ جووڵە
    final act = <int>[
      480,
      for (final w in walks) ...[w.s, w.e],
      math.min(l, 1320),
    ]..sort();
    int i0 = 0, i1 = 0;
    for (int i = 0; i < act.length - 1; i++) {
      final p = act[i], q = act[i + 1];
      final inWalk = walks.any((w) => p >= w.s && p < w.e);
      if (!inWalk && q - p > i1 - i0) {
        i0 = p;
        i1 = q;
      }
    }
    if (i1 - i0 >= 150) {
      b.add(_Ins('🪑', const Color(0xFFFFBE4D), 'ماوەیەکی درێژ بێ جووڵە', 'هەر کاتژمێرێک 5 خولەک بڕۆ',
          '${_tm(i0)}–${_tm(i1)}'));
    }
    for (final m in ml) {
      if (m.v == 'bad') {
        b.add(_Ins(m.e, const Color(0xFFFF9A3D), '${m.n} باش نەبوو بۆ ئامانجەکەت', '${m.k} کالۆری', _tm(m.m),
            meal: m));
      }
    }
    if (sl != null && sl.score < 75) {
      a.add(_Ins('😴', const Color(0xFF8B6BFF), 'خەوی قووڵ کەم بوو',
          'تەنها ${sl.deep}خ · ئەمشەو مۆبایل کەمتر بەکاربهێنە', '${_tm(sl.s)}–${_tm(sl.e)}',
          seg: sl));
    }
    int mxM = 0;
    double mxH = 0;
    for (int m = 0; m <= l; m += 5) {
      final h = hrAt(m.toDouble(), sg);
      if (h > mxH) {
        mxH = h;
        mxM = m;
      }
    }
    final at = typeAt(mxM.toDouble(), sg);
    a.add(_Ins(
      '❤️',
      const Color(0xFFFF5F7E),
      'بەرزترین لێدانی دڵ ${mxH.round()} BPM',
      at != null && at.t == 'walk' ? 'لە کاتی پیاسە، ئاسایی بوو' : 'لە کاتی پشوو، ئاگاداری خۆت بە',
      _tm(mxM),
      seg: at,
    ));
    if (day == 0) {
      final wake = sl != null ? sl.e : 420;
      final bed = (wake - 480 + 1440) % 1440;
      a.add(_Ins('⏰', const Color(0xFF2FE6F3), 'ئەمشەو ${_tm(bed - 15)} بخەوە', 'بۆ 8 کاتژمێر خەو و هەستانێکی چالاک',
          _tm(bed - 15)));
    }
    return _InsSet(g, b, a);
  }

  // ---- کارلێک ----
  void _setDay(int d) {
    if (d == day) return;
    _hideT?.cancel();
    setState(() {
      day = d;
      fil = null;
      scrubM = null;
      flashIdx = -1;
    });
    grow.forward(from: 0);
  }

  void _setFil(String k) {
    setState(() => fil = fil == k ? null : k);
    grow.forward(from: 0);
  }

  void _scrubAt(double dx, double w) {
    _hideT?.cancel();
    final m = clampD(dx / w, 0, 1) * 1440;
    setState(() => scrubM = m > lim ? null : m);
  }

  void _hideSoon() {
    _hideT?.cancel();
    _hideT = Timer(const Duration(milliseconds: 1200), () {
      if (mounted) setState(() => scrubM = null);
    });
  }

  void _tapAt(Offset pos, double w) {
    final k = w / 1000;
    final x = pos.dx / k, y = pos.dy / k;
    for (final m in meals) {
      if ((Offset(_x(m.m.toDouble()), 30) - Offset(x, y)).distance < 34) {
        _hideSoon();
        _mealSheet(m);
        return;
      }
    }
    if (y >= 72 && y <= 146) {
      final s = typeAt(x / 1000 * 1440);
      if (s != null) _segSheet(s);
    }
    _hideSoon();
  }

  void _open(_Ins x) {
    final seg = x.seg;
    final meal = x.meal;
    if (seg != null) {
      final i = segs.indexWhere((s) => s.s == seg.s && s.t == seg.t);
      setState(() => flashIdx = i);
      flash.forward(from: 0);
      _openT?.cancel();
      _openT = Timer(const Duration(milliseconds: 900), () {
        if (mounted) _segSheet(seg);
      });
    } else if (meal != null) {
      _mealSheet(meal);
    }
  }

  // ---- شیتەکان ----
  Widget _sh1(String e, Color k, String title, String sub) {
    return Row(
      children: [
        Container(
          width: 52,
          height: 52,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: op(k, 0.18),
            borderRadius: BorderRadius.circular(17),
            border: Border.all(color: op(k, 0.45)),
          ),
          child: Text(e, style: const TextStyle(fontSize: 26)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: ku(18, w: FontWeight.w800)),
              Text(sub, style: ku(13, c: V.mu)),
            ],
          ),
        ),
      ],
    );
  }

  void _segSheet(_Seg s) {
    final c = _cat[s.t]!;
    final d = s.len;
    List<K3Item> k3 = const [];
    String note = '';
    if (s.t == 'sleep') {
      k3 = [
        K3Item('کات', _dur(d), isNum: false),
        K3Item('قووڵ', '${s.deep > 0 ? s.deep : '--'}خ'),
        K3Item('نمرە', s.score > 0 ? '${s.score}' : '--'),
      ];
      note = s.score >= 75
          ? '😴 خەوێکی باش بوو. هەمان کات بخەوە بۆ ئەوەی بەردەوام بێت.'
          : 'خەوی قووڵت کەم بوو؛ پێش خەو مۆبایل کەمتر بەکاربهێنە.';
    } else if (s.t == 'walk') {
      k3 = [
        K3Item('هەنگاو', fmt(s.steps)),
        K3Item('ماوە', _dur(d), isNum: false),
        K3Item('دڵ', '${s.hr}'),
      ];
      note = '🚶 هەر پیاسەیەکی 10 خولەکی دوای ژەم یارمەتی شەکری خوێن دەدات.';
    } else if (s.t == 'stress') {
      k3 = [
        K3Item('ماوە', _dur(d), isNum: false),
        K3Item('بەرزترین', '${s.peak}'),
        K3Item('دڵ', '${s.hr}'),
      ];
      note = '🧠 لەم کاتانەدا 2 خولەک هەناسەی هێواش (4 چرکە هەڵمژین، 6 چرکە دەرکردن) سترێس کەم دەکاتەوە.';
    }
    final title = '${c.n}${s.what.isNotEmpty ? ' · ${s.what}' : ''}';
    showVSheet<void>(
      builder: (_) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          _sh1(c.e, c.c, title, '${_tm(s.s)} – ${_tm(s.e)}'),
          if (k3.isNotEmpty) K3(k3),
          if (note.isNotEmpty) Note(Text(note, style: ku(13, h: 1.8))),
        ],
      ),
    );
  }

  void _mealSheet(_Meal m) {
    final Color k;
    final String lb;
    if (m.v == 'good') {
      k = const Color(0xFF3CF08A);
      lb = '😊 باش بوو بۆ تۆ';
    } else if (m.v == 'bad') {
      k = const Color(0xFFFF5F7E);
      lb = '😟 باش نەبوو بۆ ئامانجەکەت';
    } else {
      k = const Color(0xFFFFBE4D);
      lb = '😐 مامناوەند';
    }
    final after = hrAt(m.m + 30.0).round();
    showVSheet<void>(
      builder: (_) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          _sh1(m.e, k, m.n, '${_tm(m.m)} · $lb'),
          K3([
            K3Item('کالۆری', '${m.k}'),
            K3Item('کات', _tm(m.m)),
            K3Item('دڵ دوای ژەم', '$after'),
          ]),
          Note(Text('🍽️ ئەم ژەمە لە بەشی خواردنەوە هاتووە و لێرە لەگەڵ داتای Band ـەکەت پێکەوە نیشان دەدرێت.',
              style: ku(13, h: 1.8))),
        ],
      ),
    );
  }

  void _allSheet(_InsSet ins) {
    Widget count(int n, String label, Color k) => Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
            decoration: BoxDecoration(
              color: op(k, 0.1),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: op(k, 0.3)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('$n', style: nu(20, c: V.tx)),
                Text(label, style: ku(11, w: FontWeight.w800, c: k)),
              ],
            ),
          ),
        );

    Widget row(BuildContext ctx, _Ins x, int i) {
      return Rise(
        delayMs: i * 60,
        child: Press(
          scale: 0.98,
          onTap: () {
            Navigator.of(ctx).pop();
            _open(x);
          },
          child: Container(
            margin: const EdgeInsets.only(top: 6),
            decoration: BoxDecoration(
              color: V.surf2,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: V.line),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                children: [
                  Positioned(
                    right: 0,
                    top: 10,
                    bottom: 10,
                    width: 3,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: x.k,
                        borderRadius: const BorderRadius.horizontal(left: Radius.circular(3)),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                    child: Row(
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(color: op(x.k, 0.14), borderRadius: BorderRadius.circular(11)),
                          child: Text(x.e, style: const TextStyle(fontSize: 16)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(x.t, style: ku(13, w: FontWeight.w800, h: 1.5)),
                              Text(x.s, style: ku(11, c: V.mu, h: 1.6)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: V.track, borderRadius: BorderRadius.circular(99)),
                          child: Text(x.tm,
                              textDirection: TextDirection.ltr,
                              style: nu(11, w: FontWeight.w700, c: V.mu)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    Widget sec(BuildContext ctx, String title, Color col, List<_Ins> arr) {
      if (arr.isEmpty) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.only(top: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(2, 0, 2, 2),
              child: Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: col,
                      boxShadow: [BoxShadow(color: col, blurRadius: 8)],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(title, style: ku(12, w: FontWeight.w800, c: V.mu)),
                  const SizedBox(width: 8),
                  const Expanded(child: Divider(height: 1, thickness: 1, color: V.line)),
                ],
              ),
            ),
            for (int i = 0; i < arr.length; i++) row(ctx, arr[i], i),
          ],
        ),
      );
    }

    showVSheet<void>(
      builder: (ctx) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          _sh1('📖', const Color(0xFF8B6BFF), 'تێبینییەکانی ${day == 1 ? 'دوێنێ' : 'ئەمڕۆ'}', '${ins.total} تێبینی'),
          const SizedBox(height: 14),
          Row(
            children: [
              count(ins.g.length, '✓ باش', const Color(0xFF3CF08A)),
              const SizedBox(width: 8),
              count(ins.b.length, '! خراپ', const Color(0xFFFF5F7E)),
              const SizedBox(width: 8),
              count(ins.a.length, '• ئاگاداری', const Color(0xFF2FE6F3)),
            ],
          ),
          sec(ctx, 'کاتە باشەکان', const Color(0xFF3CF08A), ins.g),
          sec(ctx, 'کاتە خراپەکان', const Color(0xFFFF5F7E), ins.b),
          sec(ctx, 'ئاگادارکردنەوەکان', const Color(0xFF2FE6F3), ins.a),
          const SizedBox(height: 16),
          Press(
            onTap: () => Navigator.of(ctx).pop(),
            child: Container(
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: V.surf2,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: V.line2),
              ),
              child: Text('داخستن', textAlign: TextAlign.center, style: ku(14, w: FontWeight.w800)),
            ),
          ),
        ],
      ),
    );
  }

  // ---- پیشاندان ----
  @override
  Widget build(BuildContext context) {
    final ins = _insights();
    final now = DateTime.now().subtract(Duration(days: day));
    return CustomPaint(
      foregroundPainter: const _RibBorder(),
      child: Container(
        margin: const EdgeInsets.only(top: 14),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(color: V.surf, borderRadius: BorderRadius.circular(26)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(padding: const EdgeInsets.symmetric(horizontal: 14), child: _header(now)),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
              child: LayoutBuilder(builder: (context, cons) => _ribbon(cons.maxWidth)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 2, 14, 0),
              child: Directionality(
                textDirection: TextDirection.ltr,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    for (final l in const ['00', '06', '12', '18', '24'])
                      Text(l, style: nu(9.5, w: FontWeight.w400, c: V.mu)),
                  ],
                ),
              ),
            ),
            Padding(padding: const EdgeInsets.fromLTRB(14, 6, 14, 0), child: _legend()),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
              child: Row(
                children: [
                  Expanded(
                    child: Text.rich(
                      TextSpan(children: [
                        const TextSpan(text: 'تێبینییەکانی ڕۆژ '),
                        TextSpan(text: '${ins.total}', style: nu(12, c: V.tx)),
                      ]),
                      style: ku(12, w: FontWeight.w800, c: V.mu),
                    ),
                  ),
                  LinkBtn('هەمووی ‹', onTap: () => _allSheet(ins)),
                ],
              ),
            ),
            _carousel(ins),
          ],
        ),
      ),
    );
  }

  Widget _header(DateTime d) {
    Widget dayBtn(int v, String label) {
      final on = day == v;
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _setDay(v),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
          decoration: BoxDecoration(color: on ? V.tx : Colors.transparent, borderRadius: BorderRadius.circular(10)),
          child: Text(label, style: ku(11, w: FontWeight.w800, c: on ? V.bg : V.mu)),
        ),
      );
    }

    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0x4D8B6BFF), Color(0x332FE6F3)],
            ),
            border: Border.all(color: V.line2),
          ),
          child: const Text('📖', style: TextStyle(fontSize: 18)),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('ڕۆژەکەت', style: ku(16, w: FontWeight.w800)),
              Text('${day == 1 ? 'دوێنێ' : 'ئەمڕۆ'} · ${kDays[d.weekday % 7]}', style: ku(11, c: V.mu)),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: V.surf2,
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: V.line),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              dayBtn(1, 'دوێنێ'),
              const SizedBox(width: 4),
              dayBtn(0, 'ئەمڕۆ'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _ribbon(double w) {
    final h = w * 384 / 1000;
    final sm = scrubM;
    return SizedBox(
      width: w,
      height: h,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (d) => _scrubAt(d.localPosition.dx, w),
              onTapUp: (d) => _tapAt(d.localPosition, w),
              onTapCancel: _hideSoon,
              onHorizontalDragStart: (d) => _scrubAt(d.localPosition.dx, w),
              onHorizontalDragUpdate: (d) => _scrubAt(d.localPosition.dx, w),
              onHorizontalDragEnd: (_) => _hideSoon(),
              onHorizontalDragCancel: _hideSoon,
              child: CustomPaint(painter: _RibbonPainter(this)),
            ),
          ),
          if (sm != null) _tooltip(sm, w),
        ],
      ),
    );
  }

  Widget _tooltip(double m, double w) {
    final s = typeAt(m);
    final c = s != null ? _cat[s.t] : null;
    final hr = hrAt(m).round();
    final left = clampD(m / 1440 * w, 60, w - 60);
    return Positioned(
      left: left,
      top: -8,
      child: IgnorePointer(
        child: FractionalTranslation(
          translation: const Offset(-0.5, -1),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xF003161C),
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: V.line2),
              boxShadow: const [BoxShadow(color: Color(0x99000000), blurRadius: 24, offset: Offset(0, 10), spreadRadius: -10)],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(
                  TextSpan(children: [
                    TextSpan(text: c != null ? '${c.e} ' : '😌 '),
                    TextSpan(text: c != null ? c.n : 'پشوو', style: ku(13, w: FontWeight.w800, c: const Color(0xFFEFFEFF))),
                    const TextSpan(text: '  '),
                    TextSpan(text: _tm(m.round()), style: nu(12, w: FontWeight.w400, c: V.mu)),
                  ]),
                  style: ku(12, c: const Color(0xFFEFFEFF)),
                ),
                Text.rich(
                  TextSpan(children: [
                    const TextSpan(text: '♥ '),
                    TextSpan(text: '$hr', style: nu(12, c: const Color(0xFFEFFEFF))),
                    const TextSpan(text: ' BPM'),
                  ]),
                  style: ku(12, c: const Color(0xFFEFFEFF)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _legend() {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 10,
      runSpacing: 2,
      children: [
        for (final k in const ['sleep', 'walk', 'stress', 'meal'])
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _setFil(k),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: fil == k ? op(_cat[k]!.c, 0.12) : Colors.transparent,
                borderRadius: BorderRadius.circular(99),
                border: Border.all(color: fil == k ? _cat[k]!.c : Colors.transparent),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _cat[k]!.c,
                      boxShadow: [BoxShadow(color: _cat[k]!.c, blurRadius: 8)],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(_cat[k]!.n, style: ku(11, w: FontWeight.w700, c: V.mu)),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _carousel(_InsSet ins) {
    final all = <List<Object>>[
      for (final x in ins.g) ['g', x],
      for (final x in ins.b) ['b', x],
      for (final x in ins.a) ['a', x],
    ];
    return SizedBox(
      height: 84,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        itemCount: all.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final grp = all[i][0] as String;
          final x = all[i][1] as _Ins;
          final String lbl;
          final Color lc;
          if (grp == 'g') {
            lbl = '✓ باش';
            lc = const Color(0xFF3CF08A);
          } else if (grp == 'b') {
            lbl = '! خراپ';
            lc = const Color(0xFFFF5F7E);
          } else {
            lbl = '• ئاگاداری';
            lc = const Color(0xFF2FE6F3);
          }
          return Press(
            onTap: () => _open(x),
            scale: 0.98,
            child: Container(
              width: 224,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: mix(V.line, x.k, 0.3)),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [op(x.k, 0.1), V.surf2],
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  children: [
                    Positioned(
                      right: 0,
                      top: 10,
                      bottom: 10,
                      width: 3,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: x.k,
                          borderRadius: const BorderRadius.horizontal(left: Radius.circular(3)),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            children: [
                              Expanded(child: Text(lbl, style: ku(10.5, w: FontWeight.w800, c: lc))),
                              Text(x.tm,
                                  textDirection: TextDirection.ltr,
                                  style: nu(10.5, w: FontWeight.w700, c: V.mu)),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Text(x.e, style: const TextStyle(fontSize: 16)),
                              const SizedBox(width: 7),
                              Expanded(
                                child: Text(x.t,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: ku(13, w: FontWeight.w800, h: 1.45)),
                              ),
                            ],
                          ),
                          Text(x.s, maxLines: 1, overflow: TextOverflow.ellipsis, style: ku(11, c: V.mu)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ---- چوارچێوەی کارت ----
class _RibBorder extends CustomPainter {
  const _RibBorder();

  @override
  void paint(Canvas canvas, Size size) {
    // پەراوێزی سەرەوە (margin) لە ناو قەبارەکەدایە
    final rect = Rect.fromLTWH(0, 14, size.width, size.height - 14);
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..shader = const LinearGradient(
        begin: Alignment(-0.6, -1),
        end: Alignment(0.6, 1),
        colors: [V.line2, Color(0x268B6BFF), Color(0x008CEBF5)],
        stops: [0.0, 0.5, 0.8],
      ).createShader(rect);
    canvas.drawRRect(RRect.fromRectAndRadius(rect.deflate(0.5), const Radius.circular(26)), p);
  }

  @override
  bool shouldRepaint(covariant _RibBorder oldDelegate) => false;
}

// ---- کێشانی هێڵی ڕۆژ ----
class _RibbonPainter extends CustomPainter {
  _RibbonPainter(this.s) : super(repaint: Listenable.merge([s.grow, s.pulse, s.flash]));
  final _DayRibbonCardState s;

  static final TextStyle _bpm = nu(22, w: FontWeight.w400, c: V.mu);
  static final TextStyle _now = ku(21, w: FontWeight.w800, c: const Color(0xFF04323A));
  static const TextStyle _emoji = TextStyle(fontSize: 25);

  void _dash(Canvas canvas, Offset a, Offset b, Paint p) {
    final len = (b - a).distance;
    if (len <= 0) return;
    final u = (b - a) / len;
    double x = 0;
    while (x < len) {
      canvas.drawLine(a + u * x, a + u * math.min(len, x + 6), p);
      x += 16;
    }
  }

  void _text(Canvas canvas, String t, Offset at, TextStyle st, {TextAlign align = TextAlign.center}) {
    final tp = TextPainter(text: TextSpan(text: t, style: st), textDirection: TextDirection.ltr)..layout();
    double x = at.dx;
    if (align == TextAlign.center) x -= tp.width / 2;
    if (align == TextAlign.right) x -= tp.width;
    tp.paint(canvas, Offset(x, at.dy - tp.computeDistanceToActualBaseline(TextBaseline.alphabetic)));
  }

  @override
  void paint(Canvas canvas, Size size) {
    final k = size.width / 1000;
    canvas.save();
    canvas.scale(k);
    final lim = s.lim;
    final segs = s.segs;
    final meals = s.meals;
    final fil = s.fil;

    // پشوو (بنەڕەت)
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(0, 72, 1000, 74), const Radius.circular(22)),
      Paint()..color = const Color(0x8C2A6F7F),
    );
    // داهاتوو (هێڵی لار)
    if (lim < 1440) {
      final x0 = _x(lim.toDouble());
      canvas.save();
      canvas.clipRect(Rect.fromLTWH(x0, 72, 1000 - x0, 74));
      final hp = Paint()
        ..color = const Color(0x148CEBF5)
        ..strokeWidth = 3;
      for (double x = x0 - 80; x < 1080; x += 14.14) {
        canvas.drawLine(Offset(x, 146), Offset(x + 74, 72), hp);
      }
      canvas.restore();
    }
    // هێڵەکانی 06 ، 12 ، 18
    final gp = Paint()
      ..color = V.line
      ..strokeWidth = 2;
    for (final m in const [360.0, 720.0, 1080.0]) {
      _dash(canvas, Offset(_x(m), 64), Offset(_x(m), 342), gp);
    }

    // گەشەکردن لە چەپەوە
    final g = Curves.easeOutCubic.transform(s.grow.value);
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, 1000 * g, 384));

    for (int i = 0; i < segs.length; i++) {
      final sg = segs[i];
      final c = _cat[sg.t]!.c;
      final x0 = _x(sg.s.toDouble());
      final w = math.max(6.0, _x(sg.e.toDouble()) - x0);
      double o = (fil != null && fil != sg.t) ? 0.12 : 1.0;
      if (i == s.flashIdx && s.flash.isAnimating) {
        final v = (s.flash.value * 2) % 1.0;
        o *= 1 - 0.75 * (1 - (2 * v - 1).abs());
      }
      final rr = RRect.fromRectAndRadius(Rect.fromLTWH(x0, 72, w, 74), const Radius.circular(16));
      canvas.drawRRect(
        rr,
        Paint()
          ..color = op(c, 0.45 * o)
          ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 6),
      );
      canvas.drawRRect(rr, Paint()..color = op(c, o));
    }

    // لێدانی دڵ
    final pts = <Offset>[];
    for (int m = 0; m <= lim; m += 6) {
      pts.add(Offset(_x(m.toDouble()), _hrY(s.hrAt(m.toDouble(), segs))));
    }
    if (pts.length > 1) {
      final line = Path()..moveTo(pts[0].dx, pts[0].dy);
      for (int i = 1; i < pts.length; i++) {
        line.lineTo(pts[i].dx, pts[i].dy);
      }
      double minY = 338;
      for (final p in pts) {
        if (p.dy < minY) minY = p.dy;
      }
      final area = Path()
        ..addPath(line, Offset.zero)
        ..lineTo(pts.last.dx, 338)
        ..lineTo(0, 338)
        ..close();
      canvas.drawPath(
        area,
        Paint()
          ..shader = ui.Gradient.linear(
            Offset(0, minY),
            const Offset(0, 338),
            const [Color(0x59FF5F7E), Color(0x00FF5F7E)],
          ),
      );
      canvas.drawPath(
        line,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.5
          ..strokeJoin = StrokeJoin.round
          ..color = const Color(0xFFFF5F7E),
      );
    }
    _text(canvas, '♥ BPM', const Offset(1000, 200), _bpm, align: TextAlign.right);

    // ژەمەکان
    final mo = (fil != null && fil != 'meal') ? 0.15 : 1.0;
    for (final m in meals) {
      final x = _x(m.m.toDouble());
      if (mo < 1) canvas.saveLayer(null, Paint()..color = Color.fromRGBO(0, 0, 0, mo));
      canvas.drawLine(
        Offset(x, 54),
        Offset(x, 72),
        Paint()
          ..strokeWidth = 3
          ..color = const Color(0xFFFFD56B),
      );
      canvas.drawCircle(Offset(x, 30), 24, Paint()..color = const Color(0x2EFFD56B));
      canvas.drawCircle(
        Offset(x, 30),
        24,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..color = const Color(0xFFFFD56B),
      );
      _text(canvas, m.e, Offset(x, 39), _emoji);
      if (mo < 1) canvas.restore();
    }
    canvas.restore(); // گەشەکردن

    // ئێستا
    if (s.day == 0 && lim < 1440) {
      final x = _x(lim.toDouble());
      canvas.drawLine(
        Offset(x, 62),
        Offset(x, 338),
        Paint()
          ..strokeWidth = 4
          ..color = V.cy,
      );
      final pv = 1 - (2 * s.pulse.value - 1).abs();
      canvas.drawCircle(Offset(x, 109), 9 + 6 * pv, Paint()..color = V.cy);
      final px = clampD(x - 46, 0, 908);
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(px, 344, 92, 34), const Radius.circular(17)),
        Paint()..color = V.cy,
      );
      _text(canvas, 'ئێستا', Offset(clampD(x, 46, 954), 368), _now);
    }

    // پەنجە
    final sm = s.scrubM;
    if (sm != null) {
      final x = _x(sm);
      canvas.drawLine(
        Offset(x, 64),
        Offset(x, 338),
        Paint()
          ..strokeWidth = 3
          ..color = op(V.tx, 0.7),
      );
      final y = _hrY(s.hrAt(sm, segs));
      canvas.drawCircle(Offset(x, y), 10, Paint()..color = const Color(0xFFFF5F7E));
      canvas.drawCircle(
        Offset(x, y),
        10,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4
          ..color = Colors.white,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _RibbonPainter oldDelegate) => true;
}
