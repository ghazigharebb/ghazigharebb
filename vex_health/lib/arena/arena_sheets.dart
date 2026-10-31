// VEX Arena — شیتەکان
part of 'vex_arena.dart';

/// ئایکۆن لە چوارگۆشەی ڕەنگاوڕەنگدا (.ri)
Widget _ri(String icon, Color k, {double s = 38, double r = 12, double i = 18}) => Container(
      width: s,
      height: s,
      decoration: BoxDecoration(color: _a(k, .16), borderRadius: BorderRadius.circular(r)),
      alignment: Alignment.center,
      child: AIcon(icon, size: i, color: k),
    );

/// ڕیز لەگەڵ ئایکۆن (.cwr > div)
Widget _cwRow(String icon, Color k, String b, String sm, {Widget? trail}) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(color: AC.surf2, borderRadius: BorderRadius.circular(16), border: Border.all(color: AC.line)),
      child: Row(children: [
        _ri(icon, k),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _richNum(b, ats(13.5, w: FontWeight.w800, h: 1.5), atn(13.5, h: 1.5)),
            if (sm.isNotEmpty) _richNum(sm, ats(12, c: AC.mu, h: 1.6), atn(12, w: FontWeight.w600, c: AC.mu, h: 1.6)),
          ]),
        ),
        if (trail != null) ...[const SizedBox(width: 8), trail],
      ]),
    );

/// سەری تاریکی شیت (.cwh / .rlh)
Widget _darkHead({required Widget icon, required List<Widget> children}) => Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: cssLin(170, const [Color(0xFF16224D), Color(0xFF080D22)]),
        border: Border.all(color: const Color(0x61FFD678)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(23),
        child: CustomPaint(
          painter: _TopGlow(const Color(0x4DFFC846)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
            child: SizedBox(width: double.infinity, child: Column(children: [icon, ...children])),
          ),
        ),
      ),
    );

class _TopGlow extends CustomPainter {
  _TopGlow(this.c);
  final Color c;
  @override
  void paint(Canvas cv, Size s) =>
      _ellipse(cv, Offset.zero & s, Offset(s.width / 2, 0), s.width * .8, s.height * .9, [c, c.withAlpha(0)], const [0, .7]);
  @override
  bool shouldRepaint(_TopGlow o) => o.c != c;
}

Widget _closeBtn(BuildContext ctx, {double top = 14}) =>
    Padding(padding: EdgeInsets.only(top: top), child: _Btn(tr('close'), kind: 's', onTap: () => Navigator.of(ctx).pop()));

// ---- سکە ----
void coinSheet(BuildContext context, ArenaCtl c) {
  arenaSheet(
    context,
    (ctx) => AnimatedBuilder(
      animation: c,
      builder: (_, __) {
        final st = c.store;
        final ct = c.coinsToday, mx = coinMax(c.div);
        final rest = c.today.tot >= maxDay(c.div) ? 0 : 25 - c.today.tot % 25;
        final left = kSkins.where((x) => x.cost > 0 && !c.skinOwned(x)).fold<int>(0, (a, x) => a + x.cost) +
            kChars.where((x) => !c.charOwned(x[0] as String)).fold<int>(0, (a, x) => a + (x[1] as int));
        String dk(String k) {
          final p = k.split('-');
          return p.length == 3 ? '${int.parse(p[2])}/${int.parse(p[1])}' : '';
        }

        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          _darkHead(
            icon: Container(
              width: 62,
              height: 62,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AC.goldG,
                boxShadow: [const BoxShadow(color: Color(0x2EFFD678), spreadRadius: 5), cssSh(0, 12, 28, -8, const Color(0xCCF2B21C))],
              ),
              alignment: Alignment.center,
              child: const AIcon('star', size: 30, color: Color(0xFF6B4300), sw: 2),
            ),
            children: [
              const SizedBox(height: 10),
              Text(tr('cw_t'), style: ats(12, w: FontWeight.w700, c: const Color(0xFFF6D9A6))),
              Text(afmt(st.coins), style: atn(40, c: Colors.white, h: 1.1)),
              Text(tr('coin_u'), style: ats(13, c: const Color(0xFFC9CFEA))),
            ],
          ),
          Container(
            margin: const EdgeInsets.only(top: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: AC.surf2, borderRadius: BorderRadius.circular(18), border: Border.all(color: AC.line)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Row(children: [
                Expanded(child: Text(tr('cw_today'), style: ats(13.5, w: FontWeight.w700))),
                _richNum(tr('n_of2', [ct, mx]), ats(13.5, w: FontWeight.w800, c: AC.t3g), atn(13.5, c: AC.t3g)),
              ]),
              const SizedBox(height: 10),
              _Bar(ct / mx, h: 8, gradient: AC.goldG),
              const SizedBox(height: 8),
              _richNum((ct >= mx ? tr('cw_max') : tr('cw_next', [rest])) + tr('cw_direct'), ats(12, c: AC.mu, h: 1.6), atn(12, w: FontWeight.w700, c: AC.mu, h: 1.6)),
            ]),
          ),
          Padding(padding: const EdgeInsets.fromLTRB(0, 16, 0, 8), child: Text(tr('cw_how'), style: ats(15, w: FontWeight.w800))),
          for (final r in [
            ['bolt', const Color(0xFFFFD36B), tr('cw_r1', [mx]), tr('cw_r1s', [mx, maxDay(c.div)])],
            ['fire', const Color(0xFFFF8A4D), tr('cw_r2'), tr('cw_r2s', [c.active, st.streak % 7])],
            ['crystal', const Color(0xFFB9A6FF), tr('cw_r3'), tr('cw_r3s')],
            ['gift', const Color(0xFFFF8A6A), tr('cw_r4'), tr('cw_r4s')],
            ['face', const Color(0xFFB9A6FF), tr('cw_r5'), tr('cw_r5s')],
            ['trophy', const Color(0xFFFFD36B), tr('cw_r6'), tr('cw_r6s')],
            ['shield', const Color(0xFF7FE7FF), tr('cw_r7'), tr('cw_r7s')],
          ]) ...[
            _cwRow(r[0] as String, r[1] as Color, r[2] as String, r[3] as String),
            const SizedBox(height: 8),
          ],
          Padding(
            padding: const EdgeInsets.fromLTRB(2, 4, 2, 0),
            child: _richNum(left > 0 ? tr('cw_left', [afmt(left)]) : tr('cw_all'), ats(12.5, c: AC.mu, h: 1.8), atn(12.5, c: AC.tx, h: 1.8)),
          ),
          if (st.clog.isNotEmpty) ...[
            Padding(padding: const EdgeInsets.fromLTRB(0, 16, 0, 8), child: Text(tr('cw_hist'), style: ats(15, w: FontWeight.w800))),
            for (final x in st.clog.take(8)) ...[
              _cwRow(
                _kClogIc[x.t] ?? 'star',
                x.c < 0 ? const Color(0xFFFF8A9C) : const Color(0xFF3CF08A),
                tr('co_${x.t}'),
                dk(x.k),
                trail: Text('${x.c > 0 ? '+' : ''}${x.c}', textDirection: TextDirection.ltr, style: atn(15, c: x.c < 0 ? const Color(0xFFFF8A9C) : AC.mint)),
              ),
              const SizedBox(height: 8),
            ],
          ],
          if (st.tamper) _KBox(k: AC.coral, icon: 'close', text: tr('tamper_s')),
          if (!st.clockOk) _KBox(k: AC.coral, icon: 'clock', text: tr('clock_s')),
          _closeBtn(ctx),
        ]);
      },
    ),
  );
}

const Map<String, String> _kClogIc = {
  'founder': 'star', 'char': 'face', 'freeze': 'shield', 'frzbuy': 'shield', 'chest': 'gift', 'week': 'trophy',
  'welcome': 'gift', 'day': 'bolt', 'streak': 'fire', 'guess': 'crystal', 'buy': 'star',
};

// ---- یاسا و ڕێساکان ----
void rulesSheet(BuildContext context, ArenaCtl c) {
  const sec = [
    [1, 'flag', Color(0xFF7FE7FF)],
    [2, 'heart', Color(0xFF3CF08A)],
    [3, 'crystal', Color(0xFFB9A6FF)],
    [4, 'star', Color(0xFFFFD36B)],
    [5, 'trophy', Color(0xFFFFB27A)],
    [6, 'shield', Color(0xFF3CF08A)],
    [7, 'close', Color(0xFFFF8A9C)],
    [8, 'eye', Color(0xFF7FD8FF)],
    [13, 'phone', Color(0xFF7FD8FF)],
    [12, 'lock', Color(0xFFFF8A9C)],
    [9, 'calendar', Color(0xFF7FD8FF)],
    [10, 'phone', Color(0xFF3CF08A)],
    [11, 'face', Color(0xFFB9A6FF)],
  ];
  Widget ul(List<String> items) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        for (final t in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Padding(padding: const EdgeInsets.only(top: 9), child: Container(width: 5, height: 5, decoration: BoxDecoration(color: AC.t3g, shape: BoxShape.circle))),
              const SizedBox(width: 8),
              Expanded(child: _richNum(t, ats(13, h: 1.75), atn(13, h: 1.75))),
            ]),
          ),
      ]);
  arenaSheet(
    context,
    (ctx) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _darkHead(
        icon: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(18), gradient: AC.goldG, boxShadow: [cssSh(0, 12, 26, -8, const Color(0xCCF2B21C))]),
          alignment: Alignment.center,
          child: const AIcon('trophy', size: 26, color: Color(0xFF5A3A00)),
        ),
        children: [
          const SizedBox(height: 10),
          _richNum(tr('rl_k', [c.S.n]), atn(11, c: AC.goldS, ls: 1.5), atn(11, c: AC.goldS, ls: 1.5)),
          const SizedBox(height: 4),
          Text(tr('rules_all'), textAlign: TextAlign.center, style: ats(18, w: FontWeight.w800, c: Colors.white)),
          const SizedBox(height: 6),
          Text(tr('rl_p'), textAlign: TextAlign.center, style: ats(13, c: const Color(0xFFC9CFEA), h: 1.75)),
        ],
      ),
      for (final x in sec)
        Container(
          margin: const EdgeInsets.only(top: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: AC.surf2, borderRadius: BorderRadius.circular(20), border: Border.all(color: AC.line)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(color: const Color(0x29FFD678), borderRadius: BorderRadius.circular(8)),
                alignment: Alignment.center,
                child: Text('${x[0]}', style: atn(12, c: AC.t3g)),
              ),
              const SizedBox(width: 10),
              _ri(x[1] as String, x[2] as Color, s: 34, r: 11),
              const SizedBox(width: 10),
              Expanded(child: Text(tr('ru${x[0]}_t'), style: ats(15.5, w: FontWeight.w800))),
            ]),
            const SizedBox(height: 8),
            if (x[0] == 2) ...[
              for (final k in kCats)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                  decoration: BoxDecoration(border: Border(top: BorderSide(color: AC.line))),
                  child: Row(children: [
                    CatTile.cat(k, size: 24),
                    const SizedBox(width: 8),
                    SizedBox(width: 74, child: Text(k.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: ats(12.5, w: FontWeight.w700))),
                    Expanded(child: Text(tr('src_${k.id}'), style: ats(12, c: AC.mu, h: 1.6))),
                    const SizedBox(width: 6),
                    Text('${k.max}', style: atn(12.5)),
                  ]),
                ),
              const SizedBox(height: 8),
              _richNum(tr('ru2_p'), ats(12.5, c: AC.mu, h: 1.75), atn(12.5, c: AC.tx, h: 1.75)),
            ] else if (x[0] == 7)
              Row(children: [
                for (var i = 1; i <= 3; i++) ...[
                  if (i > 1) const SizedBox(width: 6),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
                      decoration: BoxDecoration(
                        color: Color.fromRGBO(255, 111, 134, .08 * i),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0x4DFF6F86)),
                      ),
                      child: Column(children: [
                        Text('$i', style: atn(18, c: const Color(0xFFFF8A9C))),
                        const SizedBox(height: 3),
                        Text(tr('pen${i}_t'), style: ats(12.5, w: FontWeight.w800)),
                        const SizedBox(height: 3),
                        Text(tr('pen${i}_s'), textAlign: TextAlign.center, style: ats(11, c: AC.mu, h: 1.5)),
                      ]),
                    ),
                  ),
                ],
              ])
            else
              ul([for (var i = 1; i <= 8; i++) if (kArenaT.containsKey('ru${x[0]}_$i')) tr('ru${x[0]}_$i')]),
          ]),
        ),
      Padding(padding: const EdgeInsets.only(top: 14), child: _Btn(tr('got_it'), icon: 'check', onTap: () => Navigator.of(ctx).pop())),
    ]),
  );
}

// ---- خەڵات ----
void prizeSheet(BuildContext context, ArenaCtl c, Div dv) {
  arenaSheet(
    context,
    (ctx) => _PrizeSheet(c: c, dv: dv),
  );
}

class _PrizeSheet extends StatefulWidget {
  const _PrizeSheet({required this.c, required this.dv});
  final ArenaCtl c;
  final Div dv;
  @override
  State<_PrizeSheet> createState() => _PrizeSheetState();
}

class _PrizeSheetState extends State<_PrizeSheet> {
  final clock = ValueNotifier<DateTime>(DateTime.now());
  Timer? t;
  @override
  void initState() {
    super.initState();
    t = Timer.periodic(const Duration(seconds: 1), (_) => clock.value = DateTime.now());
  }

  @override
  void dispose() {
    t?.cancel();
    clock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.c, dv = widget.dv, S = c.S;
    final mine = dv == c.div;
    final my = c.myTotal, rk = c.rankOf(my);
    final day = S.day, left = S.live ? 30 - day + 1 : 30;
    final act = c.activeDays, need = 25, canReach = act + left - 1 >= need, ok = act >= need;
    final E = S.end.toLocal();
    final endS = '${E.day}/${E.month}/${E.year} · ${_p2(E.hour)}:${_p2(E.minute)}';
    final z = kPrizes[dv]!;
    final cols = [AC.silver, AC.gold, AC.bronze];
    final order = [z[1], z[0], z[2]];
    final gap3 = math.max(0, c.ptsAt(3, dv) - my);
    Widget st(Color k, String icon, String text) => Container(
          margin: const EdgeInsets.only(top: 10),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(color: _a(k, .12), borderRadius: BorderRadius.circular(14), border: Border.all(color: _a(k, .3))),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Padding(padding: const EdgeInsets.only(top: 2), child: AIcon(icon, size: 16, color: k)),
            const SizedBox(width: 8),
            Expanded(child: _richNum(text, ats(12.5, h: 1.6), atn(12.5, h: 1.6))),
          ]),
        );
    Widget bx(List<Widget> ch) => Container(
          margin: const EdgeInsets.only(top: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: AC.surf, borderRadius: BorderRadius.circular(22), border: Border.all(color: AC.line)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: ch),
        );
    Widget h4(String icon, String t) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(children: [AIcon(icon, size: 17, color: AC.tx), const SizedBox(width: 7), Text(t, style: ats(14.5, w: FontWeight.w800))]),
        );
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Container(
        margin: const EdgeInsets.only(top: 4),
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          gradient: const RadialGradient(center: Alignment(0, -1), radius: 1.3, colors: [Color(0xFF5A3D06), Color(0xFF2B1D05), Color(0xFF140D02)], stops: [0, .55, 1]),
          border: Border.all(color: const Color(0x66FFD56B)),
        ),
        child: Column(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(color: const Color(0x29FFD56B), borderRadius: BorderRadius.circular(99), border: Border.all(color: const Color(0x4DFFD56B))),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const AIcon('trophy', size: 14, color: Color(0xFFFFD56B)),
              const SizedBox(width: 6),
              _richNum(tr('pzs_k', [S.n]), ats(12, w: FontWeight.w800, c: const Color(0xFFFFD56B)), atn(12, c: const Color(0xFFFFD56B))),
            ]),
          ),
          const SizedBox(height: 10),
          Text(tr('pz_t', [tr(dv == Div.band ? 'dv_band' : 'dv_phone')]), textAlign: TextAlign.center, style: ats(22, w: FontWeight.w800, c: const Color(0xFFFFF3C4))),
          const SizedBox(height: 4),
          _richNum(tr(dv == Div.band ? 'pzs_band' : 'pzs_phone'), ats(12, c: const Color(0xB8FFF3C4), h: 1.6), atn(12, c: const Color(0xFFFFF3C4), h: 1.6), align: TextAlign.center),
          const SizedBox(height: 6),
          Text(S.live ? tr('pzs_ends') : tr('pzs_starts'), style: ats(12.5, c: const Color(0xB8FFF3C4))),
          const SizedBox(height: 14),
          ValueListenableBuilder<DateTime>(
            valueListenable: clock,
            builder: (_, now, __) {
              final d = S.end.difference(now);
              final t = d.isNegative ? Duration.zero : d;
              final v = ['${t.inDays}', _p2(t.inHours % 24), _p2(t.inMinutes % 60), _p2(t.inSeconds % 60)];
              final l = [tr('u_d'), tr('u_h'), tr('u_m'), tr('u_s')];
              return Directionality(
                textDirection: TextDirection.ltr,
                child: Row(children: [
                  for (var i = 0; i < 4; i++) ...[
                    if (i > 0) const SizedBox(width: 7),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(0, 9, 0, 7),
                        decoration: BoxDecoration(color: const Color(0x47000000), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0x38FFD56B))),
                        child: Column(children: [
                          Text(v[i], style: atn(26, w: FontWeight.w900, c: const Color(0xFFFFE9A8), h: 1.1)),
                          Text(l[i], style: ats(10.5, w: FontWeight.w700, c: const Color(0xB3FFF3C4))),
                        ]),
                      ),
                    ),
                  ],
                ]),
              );
            },
          ),
          const SizedBox(height: 10),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            const AIcon('flag', size: 14, color: Color(0xCCFFF3C4)),
            const SizedBox(width: 6),
            Text('${S.live ? tr('pzs_end') : tr('pzs_start')}: ', style: ats(12, w: FontWeight.w700, c: const Color(0xCCFFF3C4))),
            Text(endS, textDirection: TextDirection.ltr, style: atn(12, w: FontWeight.w700, c: const Color(0xCCFFF3C4))),
          ]),
          const SizedBox(height: 12),
          Container(
            height: 8,
            decoration: BoxDecoration(color: const Color(0x1FFFFFFF), borderRadius: BorderRadius.circular(9)),
            alignment: AlignmentDirectional.centerStart,
            child: FractionallySizedBox(
              widthFactor: (day / 30).clamp(0.0, 1.0),
              heightFactor: 1,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(9),
                  gradient: const LinearGradient(colors: [Color(0xFFFFD56B), Color(0xFFFFBE4D)]),
                  boxShadow: const [BoxShadow(color: Color(0xB3FFD56B), blurRadius: 12)],
                ),
              ),
            ),
          ),
          const SizedBox(height: 5),
          Row(children: [
            _richNum(tr('m_day1', [day]), ats(11, w: FontWeight.w700, c: const Color(0xB3FFF3C4)), atn(11, c: const Color(0xB3FFF3C4))),
            const Spacer(),
            _richNum(tr('n_days_left', [left]), ats(11, w: FontWeight.w700, c: const Color(0xB3FFF3C4)), atn(11, c: const Color(0xB3FFF3C4))),
          ]),
        ]),
      ),
      const SizedBox(height: 26),
      Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        for (var i = 0; i < 3; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(
            flex: i == 1 ? 115 : 100,
            child: Stack(clipBehavior: Clip.none, alignment: Alignment.topCenter, children: [
              Container(
                padding: EdgeInsets.fromLTRB(6, i == 1 ? 22 : 16, 6, 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [_a(cols[i], .22), _a(cols[i], .04)]),
                  border: Border.all(color: _a(cols[i], .45)),
                  boxShadow: i == 1 ? [cssSh(0, 14, 34, -16, cols[i])] : null,
                ),
                child: Column(children: [
                  Container(
                    width: i == 1 ? 66 : 54,
                    height: i == 1 ? 66 : 54,
                    decoration: BoxDecoration(color: _a(cols[i], .18), borderRadius: BorderRadius.circular(i == 1 ? 22 : 18)),
                    alignment: Alignment.center,
                    child: AIcon(order[i].il, size: i == 1 ? 36 : 28, color: Color.lerp(cols[i], AC.tx, .28)),
                  ),
                  const SizedBox(height: 5),
                  SizedBox(height: 34, child: Center(child: Text(order[i].name, textAlign: TextAlign.center, maxLines: 2, style: ats(13, w: FontWeight.w900, h: 1.3)))),
                  const SizedBox(height: 5),
                  Text(tr('place_${order[i].r}'), style: ats(10.5, w: FontWeight.w700, c: AC.mu)),
                  const SizedBox(height: 5),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: _a(cols[i], .18), borderRadius: BorderRadius.circular(99)),
                    child: _richNum(S.live && c.ptsAt(order[i].r, dv) > 0 ? tr('n_pts', [afmt(c.ptsAt(order[i].r, dv))]) : '—',
                        ats(10.5, w: FontWeight.w800), atn(10.5)),
                  ),
                ]),
              ),
              Positioned(
                top: -11,
                child: Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(color: cols[i], shape: BoxShape.circle, boxShadow: [BoxShadow(color: AC.sheet, spreadRadius: 3)]),
                  alignment: Alignment.center,
                  child: Text('${order[i].r}', style: atn(13, w: FontWeight.w900, c: const Color(0xFF2B1D05))),
                ),
              ),
            ]),
          ),
        ],
      ]),
      const SizedBox(height: 8),
      Text(S.live ? tr('pzs_note') : tr('pzs_note_pre'), textAlign: TextAlign.center, style: ats(11.5, c: AC.mu)),
      if (c.regd && S.live && mine)
        bx([
          h4('target', tr('pzs_you')),
          Row(children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: _a(AC.cy, .09), borderRadius: BorderRadius.circular(16)),
                child: Column(children: [
                  Text(tr('pzs_now'), style: ats(11, w: FontWeight.w700, c: AC.mu)),
                  Text('#${afmt(rk)}', style: atn(20, w: FontWeight.w900)),
                ]),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: _a(AC.cy, .09), borderRadius: BorderRadius.circular(16)),
                child: Column(children: [
                  Text(rk <= 3 ? tr('pzs_in3') : tr('pzs_to3'), style: ats(11, w: FontWeight.w700, c: AC.mu)),
                  if (rk <= 3) AIcon('trophy', size: 24, color: AC.t3g) else Text(afmt(gap3), style: atn(20, w: FontWeight.w900)),
                  if (rk > 3) Text(tr('pts'), style: ats(11, w: FontWeight.w700, c: AC.mu)),
                ]),
              ),
            ),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: Text(tr('act_days'), style: ats(12.5, w: FontWeight.w800))),
            Text('$act / $need', textDirection: TextDirection.ltr, style: atn(12.5)),
          ]),
          const SizedBox(height: 6),
          _Bar(act / need, h: 10, gradient: AC.goldG),
          if (ok)
            st(AC.mint, 'check', tr('pzs_ok'))
          else if (canReach)
            st(AC.cy, 'bulb', tr('pzs_can', [need - act, left]))
          else
            st(AC.amber, 'clock', tr('pzs_cant', [left])),
        ])
      else if (c.regd && !mine)
        bx([st(AC.cy, dv == Div.band ? 'shield' : 'phone', tr(dv == Div.band ? 'pzs_other_band' : 'pzs_other_phone'))])
      else if (c.regd)
        bx([st(AC.mint, 'check', tr('pzs_reg'))]),
      bx([
        Row(children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(color: _a(AC.violet, .18), borderRadius: BorderRadius.circular(15)),
            alignment: Alignment.center,
            child: AIcon('gift', size: 24, color: AC.violet),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(tr('pz_guar_t'), style: ats(13, w: FontWeight.w800, h: 1.6)),
              _richNum(tr(dv == Div.band ? 'pzs_guar_b' : 'pzs_guar_p'), ats(13, h: 1.6), atn(13, h: 1.6)),
            ]),
          ),
        ]),
      ]),
      bx([
        h4('shield', tr('pzs_rules')),
        for (final r in [
          ['clock', tr('pzs_r1', [activeMin(dv)])],
          ['trophy', tr('pzs_r2', [tr(dv == Div.band ? 'dv_band' : 'dv_phone'), maxDay(dv)])],
          ['robot', tr('pzs_r3')],
          ['flag', tr('pzs_r4')],
          ['phone', tr('pzs_r5')],
        ])
          Padding(
            padding: const EdgeInsets.only(bottom: 9),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(color: _a(AC.cy, .12), borderRadius: BorderRadius.circular(10)),
                alignment: Alignment.center,
                child: AIcon(r[0], size: 15, color: AC.cy),
              ),
              const SizedBox(width: 10),
              Expanded(child: _richNum(r[1], ats(13, h: 1.6), atn(13, h: 1.6))),
            ]),
          ),
      ]),
      Padding(
        padding: const EdgeInsets.only(top: 12),
        child: _Btn(tr('pzs_how'), icon: 'help', kind: 's', onTap: () {
          Navigator.of(context).pop();
          rulesSheet(context, c);
        }),
      ),
    ]);
  }
}

// ---- ڕاپۆرتی پشتڕاستکردنەوە ----
void fairSheet(BuildContext context, ArenaCtl c) {
  arenaSheet(
    context,
    (ctx) => AnimatedBuilder(
      animation: c,
      builder: (_, __) {
        final band = c.host.bandConnected;
        Widget sec(bool okk, String icon, String t, {bool warn = false}) => Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Padding(padding: const EdgeInsets.only(top: 2), child: AIcon(icon, size: 13, color: okk ? AC.mint : (warn ? AC.mu : const Color(0xFFFF8A9C)))),
                const SizedBox(width: 6),
                Expanded(child: Text(t, style: ats(12, h: 1.6, c: okk ? AC.tx : (warn ? AC.mu : const Color(0xFFFF8A9C))))),
              ]),
            );
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          _Ttl('shield', tr('fr_t'), small: tr('tab_today')),
          Text(tr('fr_p'), style: ats(12.5, c: AC.mu, h: 1.7)),
          const SizedBox(height: 10),
          for (var i = 0; i < kCats.length; i++)
            () {
              final k = kCats[i];
              final d = c.data[k.id] ?? const CatValue('', 0, 'none');
              final kk = d.st == 'ok' ? 'y' : d.st == 'rej' ? 'n' : 'w';
              final icon = d.st == 'ok' ? 'check' : d.st == 'rej' ? 'close' : d.st == 'na' ? 'lock' : 'clock';
              final col = kk == 'y' ? AC.mint : kk == 'n' ? AC.coral : AC.mu;
              final sub = d.st == 'ok'
                  ? (d.chk.isEmpty ? tr('chk_gen') : tr(d.chk))
                  : d.st == 'rej' || d.st == 'wait' || d.st == 'na'
                      ? tr(d.why)
                      : tr('fr_none');
              final appealed = c.store.apl.contains('${k.id}${c.tk}');
              return Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(border: i < kCats.length - 1 ? Border(bottom: BorderSide(color: AC.line)) : null),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(color: kk == 'w' ? AC.surf2 : _a(col, .14), borderRadius: BorderRadius.circular(10)),
                    alignment: Alignment.center,
                    child: AIcon(icon, size: 16, color: col),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('${k.name} · ${d.label}', style: ats(13, h: 1.75)),
                      Text(sub + (d.note.isNotEmpty ? ' · ${d.note}' : ''), style: ats(11, c: AC.mu, h: 1.6)),
                      if (d.st == 'rej')
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: _Tap(
                            radius: 99,
                            onTap: appealed
                                ? null
                                : () {
                                    c.appeal(k.id);
                                    arenaToast(ctx, tr('apl_ok'), 'shield');
                                  },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(borderRadius: BorderRadius.circular(99), border: Border.all(color: AC.line2)),
                              child: Text(appealed ? tr('apl_sent') : tr('apl'), style: ats(11.5, w: FontWeight.w800, c: AC.t3g)),
                            ),
                          ),
                        ),
                    ]),
                  ),
                ]),
              );
            }(),
          Container(
            margin: const EdgeInsets.only(top: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AC.surf2, borderRadius: BorderRadius.circular(16), border: Border.all(color: AC.line)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Row(children: [AIcon('lock', size: 15, color: AC.tx), const SizedBox(width: 6), Text(tr('fr_sec'), style: ats(13.5, w: FontWeight.w700))]),
              sec(band, band ? 'check' : 'phone', band ? tr('fr_band') : tr('fr_phone'), warn: !band),
              sec(c.store.clockOk, c.store.clockOk ? 'check' : 'close', c.store.clockOk ? tr('fr_clock_ok') : tr('fr_clock_no')),
              sec(!c.store.tamper, c.store.tamper ? 'close' : 'check', c.store.tamper ? tr('fr_tamp_no') : tr('fr_tamp_ok')),
            ]),
          ),
          const SizedBox(height: 10),
          Text(tr('fr_foot'), style: ats(12, c: AC.mu, h: 1.7)),
          _closeBtn(ctx),
        ]);
      },
    ),
  );
}

/// سەری ناوەڕاستی شیت (.v5sh)
Widget _v5sh(String icon, Color k, String t, String p) => Column(children: [
      Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: _a(k, .16),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: _a(k, .08), spreadRadius: 6)],
        ),
        alignment: Alignment.center,
        child: AIcon(icon, size: 30, color: k),
      ),
      const SizedBox(height: 10),
      Text(t, textAlign: TextAlign.center, style: ats(18, w: FontWeight.w800)),
      const SizedBox(height: 6),
      _richNum(p, ats(13, c: AC.mu, h: 1.75), atn(13, c: AC.tx, h: 1.75), align: TextAlign.center),
    ]);

Widget _skst(String icon, String t, {bool ok = false}) => Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AC.surf2,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ok ? const Color(0x663CF08A) : AC.line),
      ),
      child: Row(children: [
        AIcon(icon, size: 18, color: ok ? AC.mint : AC.tx),
        const SizedBox(width: 10),
        Expanded(child: _richNum(t, ats(13.5, c: ok ? AC.mint : AC.tx, h: 1.6), atn(13.5, c: ok ? AC.mint : AC.tx, h: 1.6))),
      ]),
    );

Widget _skpn(String t) => Padding(
      padding: const EdgeInsets.only(top: 8),
      child: _richNum(t, ats(12.5, c: AC.mu), atn(12.5, c: AC.mu), align: TextAlign.center),
    );

Widget _frzRow(int n, int on, String icon, Color k) => Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        for (var i = 0; i < n; i++) ...[
          if (i > 0) const SizedBox(width: 10),
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: i < on ? _a(k, .18) : AC.surf2,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: i < on ? k : AC.line, width: 1.5),
            ),
            alignment: Alignment.center,
            child: AIcon(icon, size: 22, color: i < on ? k : AC.mu),
          ),
        ],
      ]),
    );

// ---- پاراستنی زنجیرە ----
void freezeSheet(BuildContext context, ArenaCtl c) {
  arenaSheet(
    context,
    (ctx) => AnimatedBuilder(
      animation: c,
      builder: (_, __) {
        final n = c.store.frz, can = n < 2 && c.store.coins >= 30;
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          _v5sh('shield', const Color(0xFF7FD8FF), tr('freeze'), tr('frz_p')),
          _frzRow(2, n, 'shield', const Color(0xFF7FD8FF)),
          _skpn(tr('frz_n')),
          if (n >= 2)
            _skst('check', tr('frz_full'), ok: true)
          else ...[
            const SizedBox(height: 12),
            _Btn(tr('frz_buy'), lead: const _Coin(16), onTap: can
                ? () {
                    if (c.buyFreeze()) {
                      Navigator.of(ctx).pop();
                      arenaToast(context, tr('frz_ok'), 'shield');
                    }
                  }
                : null),
            if (!can && c.store.coins < 30) _skpn(tr('no_coins_s', [30 - c.store.coins])),
          ],
          _closeBtn(ctx, top: 8),
        ]);
      },
    ),
  );
}

// ---- ڕۆژی نەخۆشی یان گەشت ----
void excuseSheet(BuildContext context, ArenaCtl c) {
  arenaSheet(
    context,
    (ctx) => AnimatedBuilder(
      animation: c,
      builder: (_, __) {
        final used = c.store.exc.length, left = 3 - used;
        final todayEx = c.store.exc.contains(c.tk), active = c.today.tot >= c.active;
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          _v5sh('clock', const Color(0xFFB9A6FF), tr('exc_t'), tr('exc_p')),
          _frzRow(3, left, 'clock', const Color(0xFFB9A6FF)),
          _skpn(tr('exc_n', [left])),
          if (todayEx)
            _skst('check', tr('exc_used'), ok: true)
          else if (active)
            _skst('check', tr('exc_done'))
          else if (left > 0) ...[
            const SizedBox(height: 12),
            _Btn(tr('exc_use'), icon: 'check', onTap: c.live
                ? () {
                    if (c.useExcuse()) {
                      Navigator.of(ctx).pop();
                      arenaToast(context, tr('exc_ok'), 'check');
                    }
                  }
                : null),
          ] else
            _skst('lock', tr('exc_all')),
          Padding(padding: const EdgeInsets.only(top: 10), child: _skpn(tr('exc_fair'))),
          _closeBtn(ctx, top: 8),
        ]);
      },
    ),
  );
}

// ---- پێشبینی ----
void guessSheet(BuildContext context, ArenaCtl c) {
  if (c.store.guess[c.tk] != null) return;
  arenaSheet(
    context,
    (ctx) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _sh3(tr('gs_t')),
      Text(tr('hint_pre') + tr('hint_${c.today.power}'), textAlign: TextAlign.center, style: ats(12, c: AC.mu, h: 1.85)),
      const SizedBox(height: 14),
      LayoutBuilder(builder: (_, bc) {
        final w = (bc.maxWidth - 16) / 3;
        return Wrap(spacing: 8, runSpacing: 8, children: [
          for (final k in kCats)
            SizedBox(
              width: w,
              child: _Tap(
                radius: 18,
                onTap: () {
                  Navigator.of(ctx).pop();
                  c.guessPower(k.id);
                  arenaToast(context, tr('pw_saved', [k.name]), 'lock');
                },
                child: Ink(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                  decoration: BoxDecoration(color: AC.surf2, borderRadius: BorderRadius.circular(18), border: Border.all(color: AC.line)),
                  child: Column(children: [
                    CatTile.cat(k, size: 40),
                    const SizedBox(height: 6),
                    Text(k.name, textAlign: TextAlign.center, style: ats(12, w: FontWeight.w700, h: 1.3)),
                  ]),
                ),
              ),
            ),
        ]);
      }),
      const SizedBox(height: 12),
      _richNum(tr('gs_note'), ats(12, c: AC.mu, h: 1.7), atn(12, c: AC.mu, h: 1.7), align: TextAlign.center),
    ]),
  );
}

// ---- دوێنێ ----
void yesterdaySheet(BuildContext context, ArenaCtl c) {
  final k = c.yk;
  final p = catById(powerOf(k)), s2 = catById(secondOf(k));
  final g = c.store.guess[k];
  final r = c.store.days[k];
  final rows = r == null ? <PointRow>[] : dayPoints(r.f, k, c.div).rows.where((x) => x.pts > 0).toList()
    ..sort((a, b) => b.pts.compareTo(a.pts));
  arenaSheet(
    context,
    (ctx) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Row(children: [
        CatTile.cat(p, size: 52),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(tr('y_k'), style: ats(12, c: AC.mu)),
            _richNum('${p.name} ×3 · ${s2.name} ×1.5', ats(15, w: FontWeight.w800, h: 1.5), atn(15, h: 1.5)),
            Text(g == null ? tr('y_none') : (g == p.id ? tr('y_right') : tr('y_wrong', [catById(g).name])), style: ats(12, c: AC.mu)),
          ]),
        ),
      ]),
      if (rows.isNotEmpty) ...[
        const SizedBox(height: 12),
        Wrap(spacing: 6, runSpacing: 6, children: [
          for (final x in rows)
            Container(
              padding: const EdgeInsetsDirectional.fromSTEB(6, 5, 10, 5),
              decoration: BoxDecoration(color: _a(x.cat.color, .14), borderRadius: BorderRadius.circular(12), border: Border.all(color: _a(x.cat.color, .35))),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                CatTile.cat(x.cat, size: 20),
                const SizedBox(width: 6),
                Text('${x.cat.name} ', style: ats(12, w: FontWeight.w800)),
                Text('${x.pts}', style: atn(12)),
                if (x.mult > 1) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(gradient: AC.goldG, borderRadius: BorderRadius.circular(6)),
                    child: Text('×${x.mult == 3 ? '3' : '1.5'}', style: atn(10, c: const Color(0xFF3A2600))),
                  ),
                ],
              ]),
            ),
        ]),
        const SizedBox(height: 12),
        _richNum(tr('y_pts', [afmt(r?.t ?? 0)]), ats(12, c: AC.mu), atn(12, c: AC.tx)),
      ] else
        Padding(padding: const EdgeInsets.only(top: 12), child: Text(tr('y_nodata'), textAlign: TextAlign.center, style: ats(12, c: AC.mu))),
      _closeBtn(ctx),
    ]),
  );
}

// ---- بەشێک ----
void catSheet(BuildContext context, ArenaCtl c, ArenaCat k) {
  arenaSheet(
    context,
    (ctx) {
      final d = c.data[k.id] ?? const CatValue('', 0, 'none');
      Widget line(String icon, String t) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Padding(padding: const EdgeInsets.only(top: 3), child: AIcon(icon, size: 15, color: AC.mu)),
              const SizedBox(width: 8),
              Expanded(child: _richNum(t, ats(12, c: AC.mu, h: 1.7), atn(12, w: FontWeight.w700, c: AC.mu, h: 1.7))),
            ]),
          );
      return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Center(child: CatTile.cat(k, size: 60)),
        _sh3(k.name, top: 10),
        Text.rich(
          TextSpan(children: [
            TextSpan(text: '${tr('cat_today')}: '),
            TextSpan(text: d.label.isEmpty ? '—' : d.label, style: ats(12, w: FontWeight.w800, c: AC.tx)),
          ]),
          textAlign: TextAlign.center,
          style: ats(12, c: AC.mu, h: 1.85),
        ),
        _Card(
          margin: const EdgeInsets.only(top: 12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            line('shield', '${tr('cat_ver')}: ${tr('src_${k.id}')}'),
            line('target', tr('cat_max', [capOf(k, c.div) > 0 ? capOf(k, c.div) : k.max])),
            line('heart', tr('cat_healthy')),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: _Btn(tr('go_sec', [k.name]), icon: 'target', onTap: () {
            Navigator.of(ctx).pop();
            c.host.openSection(context, k.id);
          }),
        ),
        _closeBtn(ctx, top: 8),
      ]);
    },
  );
}

// ---- سندووق ----
void chestSheet(BuildContext context, ArenaCtl c) {
  if (c.chestOpen) return;
  final amt = c.chestAmount;
  if (!c.openChest()) return;
  arenaSheet(context, (ctx) => _ChestBody(amt: amt));
  Future.delayed(const Duration(milliseconds: 350), () {
    if (context.mounted) arenaConfetti(context);
  });
}

class _ChestBody extends StatefulWidget {
  const _ChestBody({required this.amt});
  final int amt;
  @override
  State<_ChestBody> createState() => _ChestBodyState();
}

class _ChestBodyState extends State<_ChestBody> with TickerProviderStateMixin {
  late final AnimationController open = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
  late final AnimationController spin = AnimationController(vsync: this, duration: const Duration(seconds: 14))..repeat();
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 350), () {
      if (mounted) open.forward();
    });
  }

  @override
  void dispose() {
    open.dispose();
    spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const SizedBox(height: 10),
        SizedBox(
          height: 150,
          child: AnimatedBuilder(
            animation: Listenable.merge([open, spin]),
            builder: (_, __) => Stack(alignment: Alignment.center, clipBehavior: Clip.none, children: [
              Opacity(
                opacity: open.value,
                child: Transform.scale(
                  scale: .4 + .6 * open.value,
                  child: Transform.rotate(angle: spin.value * 2 * math.pi, child: CustomPaint(size: const Size(230, 230), painter: _ChestRays())),
                ),
              ),
              Transform.scale(
                scale: 1 + .12 * math.sin(open.value * math.pi),
                child: Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    gradient: AC.goldG,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [cssSh(0, 18, 40, -12, const Color(0xE6F2B21C))],
                  ),
                  alignment: Alignment.center,
                  child: const AIcon('gift', size: 40, color: Color(0xFF5A3A00)),
                ),
              ),
            ]),
          ),
        ),
        _sh3(tr('chest_sh_t'), top: 4),
        Row(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
          Text('+${widget.amt}', style: atn(34, c: AC.t3g)),
          const SizedBox(width: 6),
          Text(tr('coin_u'), style: ats(16, w: FontWeight.w800, c: AC.t3g)),
        ]),
        const SizedBox(height: 4),
        Text(tr('chest_sh_p'), textAlign: TextAlign.center, style: ats(12, c: AC.mu, h: 1.85)),
        Padding(padding: const EdgeInsets.only(top: 14), child: _Btn(tr('great'), icon: 'check', onTap: () => Navigator.of(context).pop())),
      ]);
}

class _ChestRays extends CustomPainter {
  @override
  void paint(Canvas c, Size s) {
    final ctr = s.center(Offset.zero);
    final r = s.width / 2;
    final p = Paint()..color = const Color(0x40FFD678);
    for (double a = 0; a < 360; a += 22) {
      final a1 = a * math.pi / 180, a2 = (a + 8) * math.pi / 180;
      c.drawPath(
          Path()
            ..moveTo(ctr.dx, ctr.dy)
            ..lineTo(ctr.dx + r * math.cos(a1), ctr.dy + r * math.sin(a1))
            ..lineTo(ctr.dx + r * math.cos(a2), ctr.dy + r * math.sin(a2))
            ..close(),
          p);
    }
  }

  @override
  bool shouldRepaint(_ChestRays o) => false;
}

// ---- دەستکاری ----
void editSheet(BuildContext context, ArenaCtl c) {
  final n = TextEditingController(text: c.store.acc?.name ?? '');
  final b = TextEditingController(text: c.store.bio);
  InputDecoration dec() => InputDecoration(
        filled: true,
        fillColor: AC.inp,
        counterText: '',
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: AC.line)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: AC.line)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: AC.cy)),
      );
  Widget lbl(String t) => Padding(padding: const EdgeInsets.only(top: 14, bottom: 7), child: Text(t, style: ats(12, w: FontWeight.w800, c: AC.mu)));
  arenaSheet(
    context,
    (ctx) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _sh3(tr('edit')),
      lbl(tr('ed_name')),
      TextField(controller: n, maxLength: 24, style: ats(15), decoration: dec()),
      lbl(tr('bio')),
      TextField(controller: b, maxLength: 60, style: ats(15), decoration: dec()),
      Padding(
        padding: const EdgeInsets.only(top: 12),
        child: _Btn(tr('save'), onTap: () {
          c.editProfile(n.text, b.text);
          Navigator.of(ctx).pop();
          arenaToast(context, tr('saved'));
        }),
      ),
    ]),
  );
}

// ---- چوونە دەرەوە ----
void logoutSheet(BuildContext context, ArenaCtl c) {
  arenaSheet(
    context,
    (ctx) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Center(
        child: Container(
          width: 64,
          height: 64,
          margin: const EdgeInsets.fromLTRB(0, 4, 0, 10),
          decoration: BoxDecoration(
            color: const Color(0x24FF5F7E),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0x66FF5F7E)),
          ),
          alignment: Alignment.center,
          child: AIcon('logout', size: 30, color: AC.coral),
        ),
      ),
      _sh3(tr('lo_t')),
      Text(tr('lo_p'), textAlign: TextAlign.center, style: ats(12, c: AC.mu, h: 1.85)),
      const SizedBox(height: 14),
      Row(children: [
        Expanded(
          child: _Btn(tr('logout_yes'), kind: 'd', onTap: () {
            Navigator.of(ctx).pop();
            c.logout();
            arenaToast(context, tr('lo_done'), 'logout');
          }),
        ),
        const SizedBox(width: 8),
        Expanded(child: _Btn(tr('no'), kind: 's', onTap: () => Navigator.of(ctx).pop())),
      ]),
    ]),
  );
}

// ---- کارەکتەرەکان ----
void charSheet(BuildContext context, ArenaCtl c) {
  arenaSheet(context, (ctx) => _CharPicker(c: c));
}

class _CharPicker extends StatefulWidget {
  const _CharPicker({required this.c});
  final ArenaCtl c;
  @override
  State<_CharPicker> createState() => _CharPickerState();
}

class _CharPickerState extends State<_CharPicker> {
  late String cur;
  bool sure = false;
  @override
  void initState() {
    super.initState();
    final ch = widget.c.store.ch;
    cur = ch.isNotEmpty ? ch : (kChars.first[0] as String);
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.c;
    final cs = c.charState();
    final ok = cs == 'first' || cs == 'ok';
    final own = c.charOwned(cur), cost = charCost(cur), rar = charRarity(cur);
    final rule = cs == 'first'
        ? tr('cp_r_first')
        : cs == 'ok'
            ? tr('cp_r_ok')
            : cs == 'live'
                ? tr('cp_r_live')
                : tr('cp_r_wait', [c.charDaysLeft]);
    String label;
    String? icon = 'check';
    Widget? lead;
    VoidCallback? act;
    if (!own) {
      final need = cost - c.store.coins;
      if (need > 0) {
        label = tr('no_coins_s', [need]);
        icon = 'lock';
      } else {
        label = tr('buy_go', [cost]);
        icon = null;
        lead = const _Coin(16);
        act = () {
          if (c.buyChar(cur)) {
            arenaToast(context, tr('cp_bought'), 'star');
            arenaConfetti(context);
            setState(() {});
          }
        };
      }
    } else if (cur == c.store.ch) {
      label = tr('cp_on');
    } else if (!ok) {
      label = cs == 'live' ? tr('cp_locked') : tr('n_days', [c.charDaysLeft]);
      icon = 'lock';
    } else {
      label = sure ? tr('cp_sure') : (cs == 'first' ? tr('cp_set') : tr('cp_swap'));
      icon = sure ? 'help' : 'check';
      act = () {
        if (cs != 'first' && !sure) {
          setState(() => sure = true);
          return;
        }
        if (c.setChar(cur)) {
          Navigator.of(context).pop();
          arenaConfetti(context);
          arenaToast(context, tr('cp_done'), 'check');
        }
      };
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _sh3(tr('cp_t')),
      Text(tr('cp_s'), textAlign: TextAlign.center, style: ats(12, c: AC.mu, h: 1.85)),
      const SizedBox(height: 12),
      SizedBox(
        height: 268,
        child: Align(
          alignment: Alignment.topCenter,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (ch, an) => ScaleTransition(scale: Tween(begin: .92, end: 1.0).animate(an), child: FadeTransition(opacity: an, child: ch)),
            child: KeyedSubtree(key: ValueKey(cur), child: ArenaCardView.of(c, ch: cur, width: 236 * .8)),
          ),
        ),
      ),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(color: _a(rarColor(rar), .16), borderRadius: BorderRadius.circular(99)),
          child: Text(tr('crar_$rar'), style: ats(11, w: FontWeight.w800, c: rarColor(rar))),
        ),
        const SizedBox(width: 8),
        if (own)
          Text(cost > 0 ? tr('owned') : tr('free'), style: ats(11.5, c: AC.mu))
        else
          Row(mainAxisSize: MainAxisSize.min, children: [
            const _Coin(14),
            const SizedBox(width: 4),
            Text('$cost ', style: atn(11.5, c: AC.mu)),
            Text(tr('coin_u'), style: ats(11.5, c: AC.mu)),
          ]),
      ]),
      Container(
        margin: const EdgeInsets.only(top: 10),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(color: AC.surf2, borderRadius: BorderRadius.circular(14), border: Border.all(color: AC.line)),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(padding: const EdgeInsets.only(top: 2), child: AIcon(ok ? 'help' : 'lock', size: 14, color: ok ? AC.t3g : AC.coral)),
          const SizedBox(width: 6),
          Expanded(child: _richNum(rule, ats(12, h: 1.65), atn(12, h: 1.65))),
        ]),
      ),
      const SizedBox(height: 10),
      LayoutBuilder(builder: (_, bc) {
        final w = (bc.maxWidth - 30) / 4;
        return Wrap(spacing: 10, runSpacing: 10, children: [
          for (final x in kChars)
            () {
              final id = x[0] as String;
              final o = c.charOwned(id), on = id == cur, eq = id == c.store.ch;
              return GestureDetector(
                onTap: () {
                  if (id == cur) return;
                  HapticFeedback.selectionClick();
                  setState(() {
                    cur = id;
                    sure = false;
                  });
                },
                child: AnimatedScale(
                  scale: on ? 1.06 : 1,
                  duration: const Duration(milliseconds: 200),
                  child: SizedBox(
                    width: w,
                    height: w,
                    child: Stack(clipBehavior: Clip.none, children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: on ? [BoxShadow(color: AC.mint, spreadRadius: 3), BoxShadow(color: AC.mint, blurRadius: 18, offset: const Offset(0, 8), spreadRadius: -6)] : null,
                        ),
                        child: Opacity(opacity: o ? 1 : .85, child: CharAvatar(ch: id, name: '', size: w)),
                      ),
                      if (on)
                        PositionedDirectional(
                          top: 4,
                          end: 4,
                          child: Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(shape: BoxShape.circle, color: AC.mint),
                            alignment: Alignment.center,
                            child: const AIcon('check', size: 12, color: Color(0xFF04323A), sw: 2.4),
                          ),
                        ),
                      if (eq)
                        PositionedDirectional(
                          top: 4,
                          start: 4,
                          child: Container(
                            width: 18,
                            height: 18,
                            decoration: const BoxDecoration(shape: BoxShape.circle, gradient: AC.goldG),
                            alignment: Alignment.center,
                            child: const AIcon('star', size: 9, color: Color(0xFF3A2600), sw: 2.4),
                          ),
                        ),
                      Positioned(
                        bottom: 4,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: o ? const Color(0xCC0B7A3E) : const Color(0xCC0B1433),
                              borderRadius: BorderRadius.circular(99),
                            ),
                            child: o
                                ? (charCost(id) > 0
                                    ? const AIcon('check', size: 10, color: Colors.white, sw: 2.4)
                                    : Text(tr('free'), style: ats(9.5, w: FontWeight.w800, c: Colors.white)))
                                : Row(mainAxisSize: MainAxisSize.min, children: [
                                    const _Coin(10),
                                    const SizedBox(width: 3),
                                    Text('${charCost(id)}', style: atn(10, c: Colors.white)),
                                  ]),
                          ),
                        ),
                      ),
                    ]),
                  ),
                ),
              );
            }(),
        ]);
      }),
      const SizedBox(height: 12),
      Row(children: [
        const _Coin(16),
        const SizedBox(width: 5),
        Text(afmt(c.store.coins), style: atn(15)),
        const SizedBox(width: 4),
        Text(tr('coin_u'), style: ats(13, c: AC.mu)),
        const SizedBox(width: 10),
        Expanded(child: _Btn(label, icon: icon, lead: lead, onTap: act)),
      ]),
    ]);
  }
}

// ---- بڵاوکردنەوە ----
void shareSheet(BuildContext context, ArenaCtl c) {
  arenaSheet(
    context,
    (ctx) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _sh3(tr('sh_t')),
      const SizedBox(height: 6),
      Center(child: ArenaCardView.of(c)),
      const SizedBox(height: 10),
      Text(tr('sh_p', [tr('sh_txt')]), textAlign: TextAlign.center, style: ats(12, c: AC.mu, h: 1.85)),
      const SizedBox(height: 10),
      _Btn(tr('sh_go'), icon: 'share', onTap: () async {
        await Clipboard.setData(ClipboardData(text: tr('sh_txt')));
        if (ctx.mounted) arenaToast(ctx, tr('sh_copied'), 'check');
      }),
      _closeBtn(ctx, top: 8),
    ]),
  );
}

// ---- دیزاینی کارت ----
void skinSheet(BuildContext context, ArenaCtl c, CardSkin s) {
  arenaSheet(
    context,
    (ctx) => AnimatedBuilder(
      animation: c,
      builder: (_, __) {
        final ok = c.skinOwned(s);
        final rc = skinRarColor(s.rar);
        final need = s.cost > 0 ? math.max(0, s.cost - c.store.coins) : 0;
        final days = math.max(1, (need / 16).ceil());
        final acts = <Widget>[];
        if (ok) {
          if (c.store.skin == s.id) {
            acts.add(_skst('check', tr('sk_on'), ok: true));
          } else {
            acts.add(Padding(
              padding: const EdgeInsets.only(top: 12),
              child: _Btn(tr('sk_use'), icon: 'check', onTap: () {
                c.useSkin(s);
                Navigator.of(ctx).pop();
                arenaToast(context, tr('sk_changed', [s.name]), 'check');
              }),
            ));
          }
        } else if (s.lg > 0) {
          final L = kLeagues[s.lg], my = c.myTotal;
          acts.add(Container(
            margin: const EdgeInsets.only(top: 12),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(color: AC.surf2, borderRadius: BorderRadius.circular(16), border: Border.all(color: AC.line)),
            child: Row(children: [
              Emblem(L.idx, size: 22),
              const SizedBox(width: 10),
              Expanded(child: _richNum(tr('sk_need_lg', [L.name, afmt(L.min)]), ats(13.5, h: 1.6), atn(13.5, h: 1.6))),
            ]),
          ));
          acts.add(Padding(padding: const EdgeInsets.only(top: 10), child: _Bar(my / L.min, h: 8, gradient: AC.goldG)));
          acts.add(_skpn(tr('sk_left', [afmt(math.max(0, L.min - my))])));
        } else if (need > 0) {
          acts.add(_skst('lock', tr('sk_need', [need, days])));
          acts.add(Padding(
            padding: const EdgeInsets.only(top: 12),
            child: _Btn(tr('how_coins'), icon: 'star', kind: 's', onTap: () {
              Navigator.of(ctx).pop();
              coinSheet(context, c);
            }),
          ));
        } else {
          acts.add(Padding(
            padding: const EdgeInsets.only(top: 12),
            child: _Btn(tr('buy_go', [s.cost]), lead: const _Coin(16), onTap: () {
              if (c.buySkin(s)) {
                Navigator.of(ctx).pop();
                arenaConfetti(context);
                arenaToast(context, tr('sk_bought', [s.name]), 'star');
              }
            }),
          ));
          acts.add(_skpn(tr('sk_wallet', [afmt(c.store.coins), afmt(c.store.coins - s.cost)])));
        }
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
              decoration: BoxDecoration(color: _a(rc, .15), borderRadius: BorderRadius.circular(99), border: Border.all(color: _a(rc, .4))),
              child: Text(tr('rar_${s.rar}'), style: ats(11.5, w: FontWeight.w800, c: rc)),
            ),
          ),
          _sh3(s.name, top: 6),
          Text(s.desc, textAlign: TextAlign.center, style: ats(13, c: AC.mu, h: 1.6)),
          const SizedBox(height: 14),
          Center(child: ArenaCardView.of(c, skin: s.id)),
          const SizedBox(height: 4),
          ...acts,
          _closeBtn(ctx, top: 8),
        ]);
      },
    ),
  );
}

// ---- یاریزان ----
void playerSheet(BuildContext context, ArenaCtl c, APlayer x) {
  Widget box(String lab, Widget v, {String? icon, Color? k}) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
          decoration: BoxDecoration(color: AC.surf2, borderRadius: BorderRadius.circular(16), border: Border.all(color: AC.line)),
          child: Column(children: [
            Text(lab, style: ats(11, w: FontWeight.w700, c: AC.mu)),
            const SizedBox(height: 3),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              if (icon != null) ...[AIcon(icon, size: 16, color: k), const SizedBox(width: 5)],
              Flexible(child: v),
            ]),
          ]),
        ),
      );
  arenaSheet(
    context,
    (ctx) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Center(
        child: ArenaCardView(
          name: x.n,
          ch: x.ch,
          skin: skinById(x.skin),
          pts: x.p,
          city: x.city,
          title: (x.dv == Div.phone ? '${tr('dv_phone')} · ' : '') + tr('ti_${x.title}'),
          stats: x.stats,
          rank: c.live ? x.r : 0,
          season: c.S.n,
          founder: x.pre,
        ),
      ),
      const SizedBox(height: 14),
      Row(children: [
        box(tr('ps_streak'), Text('${x.st}', style: atn(16)), icon: 'fire', k: const Color(0xFFFF9466)),
        const SizedBox(width: 8),
        box(tr('ps_guess'), Text('${x.gp}', style: atn(16)), icon: 'crystal', k: AC.violet),
        const SizedBox(width: 8),
        box(tr('f_city'), Text(nm(x.city), maxLines: 1, overflow: TextOverflow.ellipsis, style: ats(13, w: FontWeight.w800))),
      ]),
      const SizedBox(height: 10),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        AIcon('eyeoff', size: 14, color: AC.mu),
        const SizedBox(width: 6),
        Flexible(child: Text(tr('ps_priv'), textAlign: TextAlign.center, style: ats(12, c: AC.mu, h: 1.85))),
      ]),
      _closeBtn(ctx, top: 6),
    ]),
  );
}
