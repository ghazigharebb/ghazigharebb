// VEX Health — شیکاری خواردن (food_stats.dart)
//
// بەشێکە لە food_design.dart (part)، هەمان داتا (vexfd_v1) + داتای ڕاستەقینەی Band (خەو و هەنگاو):
//   • کالۆری 7 / 30 ڕۆژ: ستوونەکان، هێڵی ئامانج، کرتە لە ڕۆژێک ← وردەکاری ئەو ڕۆژە
//   • ناوەندی کالۆری و پرۆتین، ڕۆژی تۆمارکراو
//   • دابەشبوونی ماکرۆ (ئەمڕۆ یان ناوەندی ماوەکە) + پێشنیار
//   • کوالیتی خواردن: فایبەر، شەکر، خوێ، ئاو، هەڵسەنگاندنی ژەمەکان، دابەشبوونی کالۆری بەسەر ژەمەکاندا
//   • کێش: هێڵکاری، ئامانج، گۆڕانکاری
//   • Band و خواردن: خەو بەرامبەر کالۆری، هەنگاو، ڕۆژی چالاک
//   • بەردەوامی + شیکردنەوەی هەفتە (چی باش بوو، چی باشتر بکەیت، 3 هەنگاو)
part of 'food_design.dart';

/// ڕۆژەکانی هەفتە (یەکشەممە = 0، بەپێی weekday % 7)
const List<String> _kStD = ['ی', 'د', 'س', 'چ', 'پ', 'ه', 'ش'];
const List<String> _kStDay = ['یەکشەممە', 'دووشەممە', 'سێشەممە', 'چوارشەممە', 'پێنجشەممە', 'هەینی', 'شەممە'];

const Color _kStP = Color(0xFFFF5F7E); // پرۆتین
const Color _kStC = Color(0xFFFFA52E); // کارب
const Color _kStF = Color(0xFF9B7BFF); // چەوری
const Color _kStSleep = Color(0xFF9B7BFF);

/// داتای Band بۆ ڕۆژێک
class _StBand {
  _StBand(this.sleepH, this.steps, this.active);
  final double? sleepH;
  final int? steps;
  final int? active; // خولەکی چالاکی
}

_StBand _stBand(String k) {
  final v = VitalAgeEngine.I.dayOf(k);
  double? sl = v?.sleepMin == null ? null : v!.sleepMin! / 60;
  int? st = v?.steps;
  int? act;
  for (final s in VexBand.I.stepsDays) {
    final d = s.day;
    if (d == null || _key(d) != k) continue;
    if (s.steps > 0 && (st == null || s.steps > st)) st = s.steps;
    if (s.minutes > 0) act = math.max(act ?? 0, s.minutes);
  }
  if (sl != null && (sl < 0.5 || sl > 16)) sl = null;
  return _StBand(sl, st, act);
}

/// کۆی ماوەیەک
class _StSum {
  int days = 0; // ڕۆژی تۆمارکراو
  double kcal = 0, p = 0, c = 0, f = 0, fib = 0, sug = 0, salt = 0;
  int water = 0, waterDays = 0; // پەرداخی 250ml
  int ok = 0, mid = 0, bad = 0; // هەڵسەنگاندنی ژەمەکان
  int inGoal = 0, over = 0, under = 0;
  int sugOver = 0, saltOver = 0, noBreakfast = 0, lateNight = 0;
  final Map<String, double> meal = {'b': 0, 'l': 0, 'd': 0, 's': 0, 'n': 0};

  double avg(double v) => days == 0 ? 0 : v / days;
}

_StSum _stSum(List<String> keys, _Plan g) {
  final s = _StSum();
  for (final k in keys) {
    final d = _FD.I.days[k];
    if (d == null) continue;
    if (d.water > 0) {
      s.water += d.water;
      s.waterDays++;
    }
    if (!_FD.I.hasLog(k)) continue;
    final t = _FD.I.totals(k);
    s.days++;
    s.kcal += t.kcal;
    s.p += t.p;
    s.c += t.c;
    s.f += t.f;
    s.fib += t.fib;
    s.sug += t.sug;
    s.salt += t.salt;
    if ((t.kcal - g.kcal).abs() <= g.kcal * .1) {
      s.inGoal++;
    } else if (t.kcal > g.kcal) {
      s.over++;
    } else {
      s.under++;
    }
    if (t.sug > g.sug) s.sugOver++;
    if (t.salt > g.salt) s.saltOver++;
    if ((d.m['b'] ?? const <_Entry>[]).isEmpty) s.noBreakfast++;
    if ((d.m['n'] ?? const <_Entry>[]).isNotEmpty) s.lateNight++;
    d.m.forEach((mk, l) {
      for (final e in l) {
        s.meal[mk] = (s.meal[mk] ?? 0) + e.kcal;
        if (e.v == 'bad') {
          s.bad++;
        } else if (e.v == 'mid') {
          s.mid++;
        } else {
          s.ok++;
        }
      }
    });
  }
  return s;
}

List<String> _stKeys(int n) {
  final now = DateTime.now();
  final t = DateTime(now.year, now.month, now.day);
  return [for (var i = n - 1; i >= 0; i--) _key(t.subtract(Duration(days: i)))];
}

String _stDate(String k) {
  final d = _fromKey(k);
  return '${_kStDay[d.weekday % 7]} \u2066${pad2(d.day)}/${pad2(d.month)}\u2069';
}

// ═════════════════════════════ شیکردنەوەی هەفتە ═════════════════════════════
class _StReport {
  final List<String> good = [], fix = [], todo = [];
}

_StReport _stWeekly(_Prof P, _Plan g) {
  final r = _StReport();
  final keys = _stKeys(7);
  final s = _stSum(keys, g);
  final n = s.days;
  if (n == 0) {
    r.fix.add('هیچ خواردنێکت لەم 7 ڕۆژەدا تۆمار نەکردووە، بۆیە ناتوانرێت هەفتەکەت هەڵبسەنگێنرێت.');
    r.todo.add('هەموو ژەمێک بە یەک کرتە لە «ئەمڕۆ» یان لە پلانی ڕاهێنەر تۆمار بکە.');
    r.todo.add('هەفتەی یەک جار، بەیانی پێش خواردن، کێشی خۆت تۆمار بکە.');
    r.todo.add('ڕۆژانە ${(g.water / 1000).toStringAsFixed(1)} لیتر ئاو بخۆرەوە.');
    return r;
  }
  final aK = s.avg(s.kcal), aP = s.avg(s.p), aFib = s.avg(s.fib), aSug = s.avg(s.sug), aSalt = s.avg(s.salt);
  final water = s.waterDays == 0 ? 0.0 : s.water * 250 / s.waterDays;
  final band = keys.map(_stBand).toList();
  final sl = band.where((b) => b.sleepH != null).map((b) => b.sleepH!).toList();
  final stp = band.where((b) => b.steps != null).map((b) => b.steps!).toList();
  final aSleep = sl.isEmpty ? null : sl.reduce((a, b) => a + b) / sl.length;
  final aSteps = stp.isEmpty ? null : stp.reduce((a, b) => a + b) / stp.length;

  // ✅ باش
  if (n >= 5) r.good.add('$n ڕۆژ لە 7 ڕۆژ خواردنت تۆمار کردووە. بەردەوامی کلیلی سەرکەوتنە.');
  if (s.inGoal >= (n / 2).ceil()) r.good.add('لە ${s.inGoal} ڕۆژدا کالۆرییەکەت لە ±10٪ ی ئامانج (${fmt(g.kcal)}) بوو.');
  if (aP >= g.p * .9) r.good.add('ناوەندی پرۆتین ${aP.round()}g بوو لە ${g.p}g؛ زۆر باشە.');
  if (aFib >= g.fib * .9) r.good.add('فایبەرت باش بوو (ناوەندی ${aFib.round()}g).');
  if (s.sugOver == 0) r.good.add('هیچ ڕۆژێک لە سنووری شەکر (${g.sug}g) تێنەپەڕیویت.');
  if (water >= g.water * .9 && s.waterDays > 0) r.good.add('ئاوت باش خواردووەتەوە (ناوەندی ${fmt(water)}ml).');
  final tot = s.ok + s.mid + s.bad;
  if (tot >= 5 && s.ok / tot >= .6) r.good.add('${(s.ok / tot * 100).round()}٪ ی ژەمەکانت هەڵسەنگاندنی «باش» یان وەرگرتووە.');
  final ws = _FD.I.weights;
  if (ws.length >= 2) {
    final last = ws.last;
    _Wt? ref;
    for (var i = ws.length - 2; i >= 0; i--) {
      if (_fromKey(last.d).difference(_fromKey(ws[i].d)).inDays >= 6) {
        ref = ws[i];
        break;
      }
    }
    if (ref != null) {
      final dk = last.kg - ref.kg;
      final goodDir = (P.goal == 'lose' && dk < -0.05) || ((P.goal == 'gain' || P.goal == 'muscle') && dk > 0.05) || ((P.goal == 'keep' || P.goal == 'aging') && dk.abs() <= 0.5);
      if (goodDir) r.good.add('کێشت ${dk >= 0 ? '+' : ''}${dk.toStringAsFixed(1)}kg گۆڕاوە؛ لەگەڵ ئامانجەکەتە.');
    }
  }
  if (aSteps != null && aSteps >= 8000) r.good.add('ناوەندی هەنگاوت ${fmt(aSteps)} بوو؛ چالاکییەکی باشە.');

  // ⚠️ باشتر بکە + 🎯 هەنگاو
  void add(String f, String t) {
    r.fix.add(f);
    r.todo.add(t);
  }

  if (n < 4) add('تەنها $n ڕۆژ تۆمار کراوە؛ شیکردنەوە بە کەمی ڕۆژ ورد نییە.', 'لانیکەم 5 ڕۆژ لە هەفتەدا هەموو ژەمەکانت تۆمار بکە.');
  if (aP < g.p * .8 && !P.conds.contains('kid')) {
    add('پرۆتین کەم بوو: ناوەندی ${aP.round()}g لە ${g.p}g.', 'لە هەر ژەمێکدا پرۆتینێک دابنێ: هێلکە یان ماست بۆ بەیانی، مریشک یان نیسک بۆ نیوەڕۆ و ئێوارە.');
  }
  if (s.over >= 3) {
    add('لە ${s.over} ڕۆژدا زیاتر لە 10٪ لە ئامانجی کالۆری تێپەڕیویت.', 'بڕی برنج و نان بکە بە نیوە و نیوەی قاپەکەت پڕ بکە لە زەڵاتە و سەوزە.');
  }
  if (s.under >= 3 && (P.goal == 'gain' || P.goal == 'muscle')) {
    add('لە ${s.under} ڕۆژدا کالۆریت کەمتر بوو لە پێویست.', 'ڕۆژانە ژەمێکی سووکی پڕ وزە زیاد بکە: شیر و خورما، یان گوێز و مۆز.');
  } else if (s.under >= 3 && P.goal == 'lose' && aK < g.kcal * .75) {
    add('زۆر کەمت خواردووە (ناوەندی ${fmt(aK)} kcal)؛ ئەمە ماسولکە دەسووتێنێت.', 'ژەمەکانت مەبڕە؛ سێ ژەمی تەواو بخۆ و پرۆتین لە هەر ژەمێکدا هەبێت.');
  }
  if (aFib < g.fib * .7) {
    add('فایبەر کەم بوو: ناوەندی ${aFib.round()}g لە ${g.fib}g.', 'ڕۆژانە زەڵاتەیەک و میوەیەک زیاد بکە و نانی سپی بگۆڕە بە نانی گەنمی تەواو یان جۆ.');
  }
  if (s.sugOver >= 2 || aSug > g.sug) {
    add('لە ${s.sugOver} ڕۆژدا شەکر لە سنوور (${g.sug}g) تێپەڕیوە.', 'شەربەت و خواردنەوەی گازی بگۆڕە بە ئاو، و شیرینی تەنها هەفتەی یەک جار.');
  }
  if (s.saltOver >= 2 || aSalt > g.salt) {
    add('خوێ زیاد بوو لە ${s.saltOver} ڕۆژدا.', 'ترشی، پەنیری سوێر و خواردنی ئامادەکراو کەم بکەرەوە.');
  }
  if (s.waterDays > 0 && water < g.water * .7) {
    add('ئاو کەم بوو: ناوەندی ${fmt(water)}ml لە ${fmt(g.water)}ml.', 'بەیانی کە هەڵدەستیت و پێش هەر ژەمێک پەرداخێک ئاو بخۆرەوە.');
  }
  if (s.noBreakfast >= 3) add('لە ${s.noBreakfast} ڕۆژدا نانی بەیانیت نەخواردووە.', 'نانی بەیانی سادە بێت: هێلکە + نان + خەیار، یان ماست و میوە.');
  if (s.lateNight >= 3) add('لە ${s.lateNight} ڕۆژدا درەنگی شەو خواردنت خواردووە.', 'دوایین ژەمت 2-3 کاتژمێر پێش خەو بێت؛ ئەگەر برسیت بوو ماست یان خەیار بخۆ.');
  if (tot >= 5 && s.bad / tot >= .3) add('${(s.bad / tot * 100).round()}٪ ی ژەمەکانت هەڵسەنگاندنی «خراپ» یان وەرگرتووە.', 'خواردنی سوورکراو و خێرا بگۆڕە بە برژاو یان کوڵاو.');
  if (aSleep != null && aSleep < 6.5) add('ناوەندی خەوت ${aSleep.toStringAsFixed(1)} کاتژمێر بوو؛ خەوی کەم برسێتی زیاد دەکات.', 'هەوڵ بدە 7-8 کاتژمێر بخەویت و دوای کاتژمێر 2 ی پاشنیوەڕۆ قاوە مەخۆرەوە.');
  if (aSteps != null && aSteps < 6000) add('ناوەندی هەنگاوت ${fmt(aSteps)} بوو.', 'دوای نانی نیوەڕۆ و ئێوارە 15 خولەک پیاسە بکە.');

  if (r.good.isEmpty) r.good.add('خواردنەکانت تۆمار دەکەیت؛ ئەمە یەکەم هەنگاوە بۆ گۆڕانکاری.');
  if (r.fix.isEmpty) r.fix.add('هیچ کێشەیەکی گەورە نییە. بەم شێوەیە بەردەوام بە.');
  const extra = [
    'هەفتەی یەک جار، بەیانی پێش خواردن، کێشی خۆت تۆمار بکە.',
    'پلانی ڕاهێنەر بۆ هەفتەی داهاتوو ببینە و ژەمەکان پێشتر ئامادە بکە.',
    'ڕۆژانە 15 خولەک پیاسە دوای نان.',
  ];
  for (final x in extra) {
    if (r.todo.length >= 3) break;
    r.todo.add(x);
  }
  return r;
}

// ═════════════════════════════ UI ═════════════════════════════
class _StatsTab extends StatefulWidget {
  const _StatsTab({required this.go});
  final ValueChanged<String> go;
  @override
  State<_StatsTab> createState() => _StatsTabState();
}

class _StatsTabState extends State<_StatsTab> {
  int range = 7;
  int? sel;
  bool macroAvg = false;
  bool report = false;

  void _on() {
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    VexBand.I.addListener(_on);
    VitalAgeEngine.I.addListener(_on);
  }

  @override
  void dispose() {
    VexBand.I.removeListener(_on);
    VitalAgeEngine.I.removeListener(_on);
    super.dispose();
  }

  Widget _title(String s, {Widget? icon, String? sub, Widget? trail}) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          if (icon != null) ...[icon, const SizedBox(width: 8)],
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _t(s, size: 16, w: FontWeight.w800),
              if (sub != null) ...[const SizedBox(height: 2), _t(sub, size: 11.5, c: V.mu, w: FontWeight.w600)],
            ]),
          ),
          if (trail != null) trail,
        ]),
      );

  Widget _kpi(String l, String v, {Color? c}) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 6),
          decoration: BoxDecoration(color: V.surf2, borderRadius: BorderRadius.circular(16), border: Border.all(color: V.line)),
          child: Column(children: [
            _t(l, size: 11, c: V.mu, align: TextAlign.center, lines: 1),
            const SizedBox(height: 4),
            FittedBox(fit: BoxFit.scaleDown, child: _n(v, 17, c: c)),
          ]),
        ),
      );

  Widget _seg(List<(String, bool, VoidCallback)> items) => Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(color: V.surf2, borderRadius: BorderRadius.circular(30), border: Border.all(color: V.line)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          for (final it in items)
            Press(
              onTap: it.$3,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(gradient: it.$2 ? V.prime : null, borderRadius: BorderRadius.circular(30)),
                child: _t(it.$1, size: 12, w: FontWeight.w800, c: it.$2 ? const Color(0xFF05303A) : V.mu),
              ),
            ),
        ]),
      );

  @override
  Widget build(BuildContext context) {
    final fd = _FD.I;
    final g = fd.plan!;
    final P = fd.prof!;
    final keys = _stKeys(range);
    final s = _stSum(keys, g);
    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 6, 14, 120),
      physics: const BouncingScrollPhysics(),
      children: [
        Rise(child: _kcalCard(keys, s, g)),
        Rise(delayMs: 60, child: _macroCard(s, g)),
        Rise(delayMs: 100, child: _qualityCard(s, g)),
        Rise(delayMs: 140, child: _weightCard(P)),
        Rise(delayMs: 180, child: _bandCard(g)),
        Rise(delayMs: 220, child: _streakCard()),
        Rise(delayMs: 260, child: _reportCard(P, g)),
        const SizedBox(height: 14),
        _t('ژمارەکان خەمڵاندنن و جێگەی ڕاوێژی پزیشک ناگرنەوە.', size: 11.5, c: V.mu, align: TextAlign.center),
      ],
    );
  }

  // ───────── کالۆری ─────────
  Widget _kcalCard(List<String> keys, _StSum s, _Plan g) {
    final n = keys.length;
    final tots = keys.map((k) => _FD.I.totals(k)).toList();
    final logged = keys.map(_FD.I.hasLog).toList();
    final mx = math.max(g.kcal * 1.25, tots.fold<double>(0, (a, t) => math.max(a, t.kcal)));
    final today = _todayKey();
    final si = (sel != null && sel! < n) ? sel! : n - 1;
    const h = 130.0, top = 18.0, bottom = 24.0;
    final goalY = h * g.kcal / mx;
    final small = n > 7;

    Widget bar(int i) {
      final t = tots[i];
      final on = logged[i];
      final bh = on ? math.max(h * t.kcal / mx, 4.0) : 4.0;
      final over = on && t.kcal > g.kcal;
      final isT = keys[i] == today;
      final isS = i == si;
      final d = _fromKey(keys[i]);
      final lbl = small ? ((d.day % 5 == 0 || isT) ? '${d.day}' : '') : _kStD[d.weekday % 7];
      return Expanded(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() => sel = i);
          },
          child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
            SizedBox(
              height: top,
              child: !small && on ? FittedBox(fit: BoxFit.scaleDown, child: _n(fmt(t.kcal), 9.5, c: isS ? V.tx : V.mu, w: FontWeight.w700)) : null,
            ),
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: bh),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutCubic,
              builder: (c, v, _) => Container(
                width: small ? 7 : 26,
                height: v,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(small ? 4 : 10), bottom: Radius.circular(small ? 3 : 6)),
                  gradient: on
                      ? LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: over ? const [Color(0xFFFF8AA0), Color(0xFFD6244F)] : const [Color(0xFFFFD36B), Color(0xFFFF6F86)],
                        )
                      : null,
                  color: on ? null : V.track,
                  border: isS ? Border.all(color: V.cy, width: 2) : (isT ? Border.all(color: op(V.cy, .55), width: 1.2) : null),
                  boxShadow: on && !small ? [BoxShadow(color: op(const Color(0xFFFF6F86), .35), blurRadius: 12, offset: const Offset(0, 6))] : null,
                ),
              ),
            ),
            SizedBox(
              height: bottom,
              child: OverflowBox(maxWidth: 44, child: Center(child: _n(lbl, small ? 10 : 12, c: isS ? V.cy : V.mu, w: FontWeight.w700))),
            ),
          ]),
        ),
      );
    }

    final sk = keys[si];
    final st = tots[si];
    final sOn = logged[si];
    final diff = st.kcal - g.kcal;
    return VCard(
      margin: const EdgeInsets.only(top: 8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        _title(
          'کالۆری $range ڕۆژی ڕابردوو',
          icon: Icon(Icons.bar_chart_rounded, color: V.cy, size: 24),
          sub: 'هێڵی سەوز = ئامانج',
          trail: _seg([
            ('7 ڕۆژ', range == 7, () => setState(() {
                  range = 7;
                  sel = null;
                })),
            ('30 ڕۆژ', range == 30, () => setState(() {
                  range = 30;
                  sel = null;
                })),
          ]),
        ),
        Directionality(
          textDirection: TextDirection.ltr,
          child: SizedBox(
            height: top + h + bottom,
            child: Stack(clipBehavior: Clip.none, children: [
              Positioned(
                left: 0,
                right: 0,
                bottom: bottom + goalY,
                child: CustomPaint(size: const Size(double.infinity, 2), painter: _StDash(op(V.mint, .85))),
              ),
              Positioned(
                right: 0,
                bottom: bottom + goalY + 3,
                child: _n(fmt(g.kcal), 10.5, c: V.mint, w: FontWeight.w700),
              ),
              Positioned.fill(
                child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [for (var i = 0; i < n; i++) bar(i)]),
              ),
            ]),
          ),
        ),
        const SizedBox(height: 10),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          child: Container(
            key: ValueKey<String>(sk),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: op(V.cy, .07), borderRadius: BorderRadius.circular(16), border: Border.all(color: op(V.cy, .3))),
            child: Row(children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _t(sk == today ? 'ئەمڕۆ' : _stDate(sk), size: 13, w: FontWeight.w800),
                  const SizedBox(height: 3),
                  sOn
                      ? _n('P ${st.p.round()}g · C ${st.c.round()}g · F ${st.f.round()}g', 11.5, c: V.mu, w: FontWeight.w600)
                      : _t('هیچ خواردنێک تۆمار نەکراوە', size: 11.5, c: V.mu),
                ]),
              ),
              if (sOn)
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  _n('${fmt(st.kcal)} kcal', 15),
                  _n('${diff >= 0 ? '+' : '−'}${fmt(diff.abs())}', 11.5, c: diff.abs() <= g.kcal * .1 ? V.mint : (diff > 0 ? V.coral : V.amber), w: FontWeight.w700),
                ]),
            ]),
          ),
        ),
        const SizedBox(height: 10),
        Row(children: [
          _kpi('ناوەندی کالۆری', s.days == 0 ? '0' : fmt(s.avg(s.kcal))),
          const SizedBox(width: 8),
          _kpi('ناوەندی پرۆتین', '${s.avg(s.p).round()}g'),
          const SizedBox(width: 8),
          _kpi('ڕۆژی تۆمارکراو', '${s.days}/$range'),
        ]),
      ]),
    );
  }

  // ───────── ماکرۆ ─────────
  Widget _macroCard(_StSum s, _Plan g) {
    final t = _FD.I.totals(_todayKey());
    final p = macroAvg ? s.avg(s.p) : t.p;
    final c = macroAvg ? s.avg(s.c) : t.c;
    final f = macroAvg ? s.avg(s.f) : t.f;
    final pk = p * 4, ck = c * 4, fk = f * 9;
    final sum = pk + ck + fk;
    String pc(double v) => sum <= 0 ? '0%' : '${(v / sum * 100).round()}%';
    Widget row(String l, Color col, double kc, double gr, int goal) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(children: [
            Container(width: 11, height: 11, decoration: BoxDecoration(color: col, shape: BoxShape.circle)),
            const SizedBox(width: 8),
            _t(l, size: 13.5, w: FontWeight.w700),
            const SizedBox(width: 6),
            Expanded(child: FittedBox(fit: BoxFit.scaleDown, alignment: AlignmentDirectional.centerStart, child: _n('${gr.round()}/${goal}g', 11, c: V.mu, w: FontWeight.w600))),
            _n(pc(kc), 14.5, c: col),
          ]),
        );
    return VCard(
      margin: const EdgeInsets.only(top: 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        _title(
          macroAvg ? 'دابەشبوونی ناوەندی' : 'دابەشبوونی ئەمڕۆ',
          icon: Icon(Icons.pie_chart_rounded, color: V.mint, size: 24),
          trail: _seg([
            ('ئەمڕۆ', !macroAvg, () => setState(() => macroAvg = false)),
            ('$range ڕۆژ', macroAvg, () => setState(() => macroAvg = true)),
          ]),
        ),
        Row(children: [
          SizedBox(
            width: 112,
            height: 112,
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: 1),
              duration: const Duration(milliseconds: 900),
              curve: Curves.easeOutCubic,
              builder: (cx, a, _) => CustomPaint(
                painter: _StDonut([pk, ck, fk], const [_kStP, _kStC, _kStF], V.track, a),
                child: Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    _n(fmt(sum), 17),
                    _n('kcal', 10, c: V.mu, w: FontWeight.w600),
                  ]),
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(children: [
              row('پرۆتین', _kStP, pk, p, g.p),
              row('کارب', _kStC, ck, c, g.c),
              row('چەوری', _kStF, fk, f, g.f),
            ]),
          ),
        ]),
        const SizedBox(height: 8),
        _t(
          sum <= 0
              ? (macroAvg ? 'لەم ماوەیەدا هیچ خواردنێک تۆمار نەکراوە.' : 'هێشتا هیچ خواردنێکت ئەمڕۆ تۆمار نەکردووە.')
              : 'پێشنیار: پرۆتین 20-30٪، کارب 45-55٪، چەوری 25-30٪',
          size: 12,
          c: V.mu,
          h: 1.6,
        ),
      ]),
    );
  }

  // ───────── کوالیتی ─────────
  Widget _qualityCard(_StSum s, _Plan g) {
    final water = s.waterDays == 0 ? 0.0 : s.water * 250 / s.waterDays;
    Widget meter(Widget ic, String l, double v, double goal, String unit, {bool limit = false}) {
      final fr = goal <= 0 ? 0.0 : v / goal;
      final col = limit ? (fr <= 1 ? V.mint : (fr <= 1.2 ? V.amber : V.coral)) : (fr >= .9 ? V.mint : (fr >= .6 ? V.amber : V.coral));
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(children: [
          ic,
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Row(children: [
                _t(l, size: 13, w: FontWeight.w700),
                const SizedBox(width: 6),
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: AlignmentDirectional.centerEnd,
                    child: _n('${unit == 'ml' ? fmt(v) : v.round()}${limit ? ' / <' : ' / '}${fmt(goal)}$unit', 12, c: s.days == 0 && unit != 'ml' ? V.mu : col),
                  ),
                ),
              ]),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  height: 7,
                  color: V.track,
                  alignment: AlignmentDirectional.centerStart,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0, end: _cxCl(fr, 0, 1)),
                    duration: const Duration(milliseconds: 900),
                    curve: Curves.easeOutCubic,
                    builder: (c, x, _) => FractionallySizedBox(widthFactor: x, heightFactor: 1, child: DecoratedBox(decoration: BoxDecoration(color: col, borderRadius: BorderRadius.circular(8)))),
                  ),
                ),
              ),
            ]),
          ),
        ]),
      );
    }

    final tot = s.ok + s.mid + s.bad;
    Widget verdict() {
      if (tot == 0) return _t('هێشتا هیچ ژەمێک هەڵنەسەنگێنراوە.', size: 12, c: V.mu);
      Widget seg(int v, Color c) => v == 0 ? const SizedBox.shrink() : Expanded(flex: v, child: Container(height: 12, color: c));
      Widget lg(String l, int v, Color c) => Row(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 9, height: 9, decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
            const SizedBox(width: 5),
            _t(l, size: 11.5, c: V.mu),
            const SizedBox(width: 4),
            _n('$v', 12, c: c),
          ]);
      return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        ClipRRect(borderRadius: BorderRadius.circular(8), child: Row(children: [seg(s.ok, V.mint), seg(s.mid, V.amber), seg(s.bad, V.coral)])),
        const SizedBox(height: 8),
        Wrap(spacing: 14, runSpacing: 6, children: [lg('باش', s.ok, V.mint), lg('مامناوەند', s.mid, V.amber), lg('خراپ', s.bad, V.coral)]),
      ]);
    }

    final mk = s.meal.values.fold<double>(0, (a, b) => a + b);
    Widget meals() {
      if (mk <= 0) return _t('هێشتا هیچ ژەمێک تۆمار نەکراوە.', size: 12, c: V.mu);
      return Column(children: [
        for (final m in _kMeals)
          if ((s.meal[m[0]] ?? 0) > 0)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(children: [
                _Ic(m[2], size: 26),
                const SizedBox(width: 8),
                SizedBox(width: 118, child: _t(m[1], size: 12.5, w: FontWeight.w700, lines: 1)),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      height: 8,
                      color: V.track,
                      alignment: AlignmentDirectional.centerStart,
                      child: FractionallySizedBox(
                        widthFactor: _cxCl((s.meal[m[0]] ?? 0) / mk, 0, 1),
                        heightFactor: 1,
                        child: const DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(colors: [Color(0xFFFFD36B), Color(0xFFFF6F86)]))),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(width: 38, child: _n('${((s.meal[m[0]] ?? 0) / mk * 100).round()}%', 12.5, align: TextAlign.end)),
              ]),
            ),
      ]);
    }

    Widget sub(String l) => Padding(padding: const EdgeInsets.only(top: 14, bottom: 8), child: _t(l, size: 13, w: FontWeight.w800, c: V.mu));
    return VCard(
      margin: const EdgeInsets.only(top: 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        _title('کوالیتی خواردن', icon: const _Ic('vitamins', size: 28), sub: 'ناوەندی ڕۆژانە · $range ڕۆژ'),
        meter(const _Ic('fiber', size: 28), 'فایبەر', s.avg(s.fib), g.fib.toDouble(), 'g'),
        meter(const _Ic('sugar', size: 28), 'شەکر', s.avg(s.sug), g.sug.toDouble(), 'g', limit: true),
        meter(const _Sv('salt2', size: 28), 'خوێ', s.avg(s.salt), g.salt.toDouble(), 'g', limit: true),
        meter(const _Ic('water', size: 28), 'ئاو', water, g.water.toDouble(), 'ml'),
        sub('هەڵسەنگاندنی ژەمەکان'),
        verdict(),
        sub('کالۆری بەپێی ژەم'),
        meals(),
      ]),
    );
  }

  // ───────── کێش ─────────
  Widget _weightCard(_Prof P) {
    final all = _FD.I.weights;
    final ws = all.length > 10 ? all.sublist(all.length - 10) : all;
    final first = all.isEmpty ? P.w : all.first.kg;
    final last = all.isEmpty ? P.w : all.last.kg;
    final diff = last - first;
    final good = diff.abs() < .05 ? null : ((P.goal == 'lose') ? diff < 0 : ((P.goal == 'gain' || P.goal == 'muscle') ? diff > 0 : diff.abs() <= .5));
    return VCard(
      margin: const EdgeInsets.only(top: 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        _title('کێش', icon: const _Ic('weight', size: 28), trail: _n('${all.length} تۆمار', 12, c: V.mu, w: FontWeight.w700)),
        if (ws.length >= 2)
          SizedBox(
            height: 150,
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: 1),
                duration: const Duration(milliseconds: 1000),
                curve: Curves.easeOutCubic,
                builder: (c, a, _) => CustomPaint(
                  size: Size.infinite,
                  painter: _StWeight(
                    [for (final w in ws) w.kg],
                    [for (final w in ws) '${_fromKey(w.d).day}/${_fromKey(w.d).month}'],
                    P.tw > 0 ? P.tw : 0,
                    a,
                    V.mint,
                    V.bg,
                    V.tx,
                    V.mu,
                  ),
                ),
              ),
            ),
          )
        else
          Container(
            padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 12),
            decoration: BoxDecoration(color: V.surf2, borderRadius: BorderRadius.circular(16), border: Border.all(color: V.line)),
            child: _t('کێشی 2 ڕۆژی جیاواز تۆمار بکە بۆ ئەوەی هێڵکارییەکە دەربکەوێت.', size: 12.5, c: V.mu, align: TextAlign.center, h: 1.6),
          ),
        const SizedBox(height: 10),
        Row(children: [
          _kpi('یەکەم', '${_f1(double.parse(first.toStringAsFixed(1)))}kg'),
          const SizedBox(width: 8),
          _kpi('ئێستا', '${_f1(double.parse(last.toStringAsFixed(1)))}kg', c: V.cy),
          const SizedBox(width: 8),
          _kpi('گۆڕانکاری', '${diff >= 0 ? '+' : '−'}${diff.abs().toStringAsFixed(1)}kg', c: good == null ? null : (good ? V.mint : V.amber)),
        ]),
        if (P.tw > 0 && (P.goal == 'lose' || P.goal == 'gain' || P.goal == 'muscle')) ...[
          const SizedBox(height: 8),
          _t(
            (P.goal == 'lose' ? last <= P.tw : last >= P.tw)
                ? 'گەیشتیت بە کێشی ئامانج (${_f1(P.tw)}kg)!'
                : 'کێشی ئامانج ${_f1(P.tw)}kg · ماوە ${(P.tw - last).abs().toStringAsFixed(1)}kg',
            size: 12.5,
            c: V.mu,
            align: TextAlign.center,
          ),
        ],
        const SizedBox(height: 12),
        Press(
          onTap: () => widget.go('me'),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 13),
            decoration: BoxDecoration(color: V.surf2, borderRadius: BorderRadius.circular(18), border: Border.all(color: V.line2)),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const _Ic('weight', size: 24),
              const SizedBox(width: 8),
              Flexible(child: _t('تۆمارکردنی کێش و ئامانج', size: 14, w: FontWeight.w800, lines: 1)),
            ]),
          ),
        ),
      ]),
    );
  }

  // ───────── Band و خواردن ─────────
  Widget _bandCard(_Plan g) {
    final keys = _stKeys(7);
    final b = keys.map(_stBand).toList();
    final kc = keys.map((k) => _FD.I.hasLog(k) ? _FD.I.totals(k).kcal : 0.0).toList();
    final sl = b.where((x) => x.sleepH != null).map((x) => x.sleepH!).toList();
    final stp = b.where((x) => x.steps != null).map((x) => x.steps!).toList();
    final act = b.where((x) => (x.active ?? 0) >= 30 || (x.active == null && (x.steps ?? 0) >= 10000)).length;
    final hasBand = sl.isNotEmpty || stp.isNotEmpty;
    // پەیوەندی خەو و کالۆری
    String note;
    final lg = [
      for (var i = 0; i < 7; i++)
        if (kc[i] > 0 && b[i].sleepH != null) (kc[i], b[i].sleepH!),
    ];
    if (!hasBand) {
      note = 'Band ـەکەت پەیوەست بکە و هاوکاتی بکە بۆ ئەوەی خەو و هەنگاو لێرە دەربکەون.';
    } else if (lg.length < 3) {
      note = 'کاتێک 3 ڕۆژ یان زیاتر خواردنت تۆمار کرد، پەیوەندی نێوان خەو و خواردنت لێرە دەردەکەوێت.';
    } else {
      final lo = lg.where((x) => x.$2 < 6.5).toList(), hi = lg.where((x) => x.$2 >= 6.5).toList();
      if (lo.isEmpty || hi.isEmpty) {
        note = lo.isEmpty ? 'هەموو شەوێک 6.5 کاتژمێر یان زیاتر خەوتوویت؛ زۆر باشە.' : 'زۆربەی شەوەکان کەمتر لە 6.5 کاتژمێر خەوتوویت؛ خەوی کەم برسێتی زیاد دەکات.';
      } else {
        double av(List<(double, double)> z) => z.fold<double>(0, (a, x) => a + x.$1) / z.length;
        final d = (av(lo) - av(hi)).round();
        note = d > 0 ? 'لەو ڕۆژانەی کەمتر لە 6.5 کاتژمێر خەوتوویت، نزیکەی ${fmt(d)} کالۆری زیاترت خواردووە.' : 'خەوی کەم کاری لە خواردنت نەکردووە (${fmt(-d)} کالۆری کەمتر).';
      }
    }
    final mx = math.max(g.kcal * 1.2, kc.fold<double>(0, (a, b) => math.max(a, b)));
    return VCard(
      margin: const EdgeInsets.only(top: 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        _title('Band و خواردن · 7 ڕۆژ', icon: Icon(Icons.watch_rounded, color: V.cy, size: 24), sub: 'خەو بەرامبەر کالۆری'),
        Directionality(
          textDirection: TextDirection.ltr,
          child: SizedBox(
            height: 150,
            child: Stack(children: [
              Positioned.fill(
                bottom: 24,
                child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  for (var i = 0; i < 7; i++)
                    Expanded(
                      child: Center(
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: TweenAnimationBuilder<double>(
                            tween: Tween<double>(begin: 0, end: kc[i] > 0 ? math.max(126 * kc[i] / mx, 4.0) : 4.0),
                            duration: const Duration(milliseconds: 800),
                            curve: Curves.easeOutCubic,
                            builder: (c, v, _) => Container(
                              width: 22,
                              height: v,
                              decoration: BoxDecoration(
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(9), bottom: Radius.circular(5)),
                                gradient: kc[i] > 0 ? const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFFFBE4D), Color(0xFFFF6F86)]) : null,
                                color: kc[i] > 0 ? null : V.track,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ]),
              ),
              if (sl.isNotEmpty)
                Positioned.fill(
                  bottom: 24,
                  child: CustomPaint(painter: _StSleep([for (final x in b) x.sleepH], _kStSleep, V.bg)),
                ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: 22,
                child: Row(children: [
                  for (final k in keys)
                    Expanded(child: Center(child: _n(_kStD[_fromKey(k).weekday % 7], 12, c: k == _todayKey() ? V.cy : V.mu, w: FontWeight.w700))),
                ]),
              ),
            ]),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(alignment: WrapAlignment.center, spacing: 16, runSpacing: 6, children: [
          Row(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 12, height: 12, decoration: BoxDecoration(borderRadius: BorderRadius.circular(4), gradient: const LinearGradient(colors: [Color(0xFFFFBE4D), Color(0xFFFF6F86)]))),
            const SizedBox(width: 6),
            _t('کالۆری خواردراو', size: 11.5, c: V.mu),
          ]),
          Row(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 12, height: 12, decoration: BoxDecoration(borderRadius: BorderRadius.circular(4), color: _kStSleep)),
            const SizedBox(width: 6),
            _t('کاتژمێری خەو', size: 11.5, c: V.mu),
          ]),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          _kpi('ناوەندی خەو', sl.isEmpty ? '—' : '${(sl.reduce((a, c) => a + c) / sl.length).toStringAsFixed(1)}h'),
          const SizedBox(width: 8),
          _kpi('ناوەندی هەنگاو', stp.isEmpty ? '—' : fmt(stp.reduce((a, c) => a + c) / stp.length)),
          const SizedBox(width: 8),
          _kpi('ڕۆژی چالاک', hasBand ? '$act/7' : '—'),
        ]),
        const SizedBox(height: 10),
        _t(note, size: 12.5, c: V.mu, h: 1.7),
      ]),
    );
  }

  // ───────── بەردەوامی ─────────
  Widget _streakCard() {
    final st = _FD.I.streaks();
    final now = DateTime.now();
    var past = 0, lg = 0;
    for (var d = 1; d <= now.day; d++) {
      past++;
      if (_FD.I.hasLog(_key(DateTime(now.year, now.month, d)))) lg++;
    }
    return VCard(
      margin: const EdgeInsets.only(top: 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        _title('بەردەوامی', icon: const _Sv('flame', size: 28), sub: 'ڕۆژانی یەک لە دوای یەک کە خواردنت تۆمار کردووە'),
        Row(children: [
          _kpi('ئێستا', '${st[0]} ڕۆژ', c: V.orange),
          const SizedBox(width: 8),
          _kpi('باشترین', '${st[1]} ڕۆژ', c: V.amber),
          const SizedBox(width: 8),
          _kpi('ئەم مانگە', '${past == 0 ? 0 : (lg / past * 100).round()}%', c: V.mint),
        ]),
      ]),
    );
  }

  // ───────── شیکردنەوەی هەفتە ─────────
  Widget _reportCard(_Prof P, _Plan g) {
    final r = report ? _stWeekly(P, g) : null;
    Widget sec(IconData ic, Color c, String t, List<String> l, {bool num = false}) => Container(
          margin: const EdgeInsets.only(top: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: op(c, .08), borderRadius: BorderRadius.circular(18), border: Border.all(color: op(c, .35))),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [Icon(ic, color: c, size: 20), const SizedBox(width: 6), Expanded(child: _t(t, size: 14, w: FontWeight.w800, c: c))]),
            const SizedBox(height: 6),
            for (var i = 0; i < l.length; i++)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  SizedBox(width: 18, child: num ? _n('${i + 1}', 13, c: c) : Padding(padding: const EdgeInsets.only(top: 8), child: Container(width: 6, height: 6, decoration: BoxDecoration(color: c, shape: BoxShape.circle)))),
                  const SizedBox(width: 6),
                  Expanded(child: _t(l[i], size: 13, h: 1.7, w: FontWeight.w600)),
                ]),
              ),
          ]),
        );
    return VCard(
      margin: const EdgeInsets.only(top: 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        _title('شیکردنەوەی هەفتەکەت', icon: Icon(Icons.auto_awesome_rounded, color: V.violet, size: 24)),
        _t('خواردن، ئاو، کێش و داتای Band ی 7 ڕۆژی ڕابردوو دەخوێنرێتەوە و پێت دەڵێت چی باش بووە و چی بگۆڕیت.', size: 12.5, c: V.mu, h: 1.7),
        const SizedBox(height: 12),
        Press(
          onTap: () {
            HapticFeedback.lightImpact();
            setState(() => report = !report);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(gradient: V.ai, borderRadius: BorderRadius.circular(18)),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(report ? Icons.expand_less_rounded : Icons.auto_awesome_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Flexible(child: _t(report ? 'داخستن' : 'هەفتەکەم شی بکەرەوە', size: 14.5, w: FontWeight.w800, c: Colors.white, lines: 1)),
            ]),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: r == null
              ? const SizedBox(width: double.infinity)
              : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  sec(Icons.check_circle_rounded, V.mint, 'چی باش بوو', r.good),
                  sec(Icons.warning_amber_rounded, V.amber, 'چی باشتر بکەیت', r.fix),
                  sec(Icons.flag_rounded, V.cy, '3 هەنگاو بۆ هەفتەی داهاتوو', r.todo.take(3).toList(), num: true),
                ]),
        ),
      ]),
    );
  }
}

// ═════════════════════════════ وێنەکێشەکان ═════════════════════════════
class _StDash extends CustomPainter {
  _StDash(this.c);
  final Color c;
  @override
  void paint(Canvas canvas, Size s) {
    final p = Paint()
      ..color = c
      ..strokeWidth = 1.5;
    for (var x = 0.0; x < s.width; x += 9) {
      canvas.drawLine(Offset(x, 0), Offset(math.min(x + 5, s.width), 0), p);
    }
  }

  @override
  bool shouldRepaint(covariant _StDash o) => o.c != c;
}

class _StDonut extends CustomPainter {
  _StDonut(this.v, this.cols, this.track, this.a);
  final List<double> v;
  final List<Color> cols;
  final Color track;
  final double a;
  @override
  void paint(Canvas canvas, Size s) {
    final w = s.shortestSide * .15;
    final r = Rect.fromCircle(center: s.center(Offset.zero), radius: s.shortestSide / 2 - w / 2);
    canvas.drawArc(r, 0, math.pi * 2, false, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = w
      ..color = track);
    final sum = v.fold<double>(0, (x, y) => x + y);
    if (sum <= 0) return;
    var st = -math.pi / 2;
    for (var i = 0; i < v.length; i++) {
      final sw = v[i] / sum * math.pi * 2 * a;
      if (sw <= 0) continue;
      canvas.drawArc(r, st, sw, false, Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = w
        ..color = cols[i]);
      st += sw;
    }
  }

  @override
  bool shouldRepaint(covariant _StDonut o) => o.a != a || o.track != track || !_stSame(o.v, v);
}

bool _stSame(List<double> a, List<double> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

/// هێڵکاری کێش: ناوچەی ڕەنگاوڕەنگ، خاڵ و ژمارە، هێڵی ئامانج
class _StWeight extends CustomPainter {
  _StWeight(this.kg, this.lbl, this.goal, this.a, this.c, this.bg, this.tx, this.mu);
  final List<double> kg;
  final List<String> lbl;
  final double goal, a;
  final Color c, bg, tx, mu;

  @override
  void paint(Canvas canvas, Size s) {
    if (kg.length < 2) return;
    var lo = kg.reduce(math.min), hi = kg.reduce(math.max);
    if (goal > 0 && (goal - lo).abs() < 6 && (goal - hi).abs() < 6) {
      lo = math.min(lo, goal);
      hi = math.max(hi, goal);
    }
    lo -= 1;
    hi += 1;
    const padX = 20.0, top = 22.0, bot = 22.0;
    final w = s.width - padX * 2, h = s.height - top - bot;
    double x(int i) => padX + i * w / (kg.length - 1);
    double y(double v) => top + (1 - (v - lo) / (hi - lo)) * h;
    // ئامانج
    if (goal > 0 && goal >= lo && goal <= hi) {
      final gy = y(goal);
      final gp = Paint()
        ..color = c.withAlpha(140)
        ..strokeWidth = 1.2;
      for (var xx = 0.0; xx < s.width; xx += 9) {
        canvas.drawLine(Offset(xx, gy), Offset(math.min(xx + 5, s.width), gy), gp);
      }
      _txt(canvas, '${goal % 1 == 0 ? goal.toInt() : goal}', Offset(s.width - 2, gy - 15), c, 10, end: true);
    }
    final n = kg.length;
    final shown = (1 + (n - 1) * a).clamp(1, n.toDouble());
    final path = Path()..moveTo(x(0), y(kg[0]));
    for (var i = 1; i < n; i++) {
      if (i > shown) break;
      path.lineTo(x(i), y(kg[i]));
    }
    final last = math.min(n - 1, shown.floor());
    final area = Path.from(path)
      ..lineTo(x(last), top + h)
      ..lineTo(x(0), top + h)
      ..close();
    canvas.drawPath(
      area,
      Paint()
        ..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [c.withAlpha(80), c.withAlpha(0)]).createShader(Rect.fromLTWH(0, top, s.width, h)),
    );
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = c,
    );
    for (var i = 0; i <= last; i++) {
      final o = Offset(x(i), y(kg[i]));
      canvas.drawCircle(o, 5, Paint()..color = bg);
      canvas.drawCircle(o, 5, Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = c);
      final v = kg[i];
      _txt(canvas, v % 1 == 0 ? '${v.toInt()}' : v.toStringAsFixed(1), Offset(o.dx, o.dy - 20), tx, 11);
      if (n <= 7 || i == 0 || i == n - 1 || i % 2 == 0) _txt(canvas, lbl[i], Offset(o.dx, s.height - 15), mu, 9.5);
    }
  }

  void _txt(Canvas canvas, String s, Offset at, Color col, double size, {bool end = false}) {
    final tp = TextPainter(
      text: TextSpan(text: s, style: nu(size, w: FontWeight.w700, c: col)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(end ? at.dx - tp.width : at.dx - tp.width / 2, at.dy));
  }

  @override
  bool shouldRepaint(covariant _StWeight o) => o.a != a || o.goal != goal || o.c != c || o.bg != bg || !_stSame(o.kg, kg);
}

/// هێڵی خەو (3 … 10 کاتژمێر) لەسەر ستوونەکانی کالۆری
class _StSleep extends CustomPainter {
  _StSleep(this.h, this.c, this.bg);
  final List<double?> h;
  final Color c, bg;
  @override
  void paint(Canvas canvas, Size s) {
    final n = h.length;
    double x(int i) => (i + .5) / n * s.width;
    double y(double v) => s.height - (_cxCl(v, 3, 10) - 3) / 7 * (s.height - 10) - 5;
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round
      ..color = c;
    Path? path;
    for (var i = 0; i < n; i++) {
      final v = h[i];
      if (v == null) {
        if (path != null) canvas.drawPath(path, p);
        path = null;
        continue;
      }
      if (path == null) {
        path = Path()..moveTo(x(i), y(v));
      } else {
        path.lineTo(x(i), y(v));
      }
    }
    if (path != null) canvas.drawPath(path, p);
    for (var i = 0; i < n; i++) {
      final v = h[i];
      if (v == null) continue;
      canvas.drawCircle(Offset(x(i), y(v)), 4, Paint()..color = bg);
      canvas.drawCircle(Offset(x(i), y(v)), 4, Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..color = c);
    }
  }

  @override
  bool shouldRepaint(covariant _StSleep o) => true;
}
