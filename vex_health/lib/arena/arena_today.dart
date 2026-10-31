// VEX Arena — تابی «ئەمڕۆ» (وەرزی ڕاستەوخۆ و پێش وەرز)
part of 'vex_arena.dart';

class _TodayTab extends StatelessWidget {
  const _TodayTab({required this.s});
  final _VexArenaPageState s;

  @override
  Widget build(BuildContext context) {
    final c = s.c, S = c.S;
    if (!S.live) {
      return _TabFrame(
        s: s,
        id: 'today',
        tall: true,
        hero: _HeroBlock(
          live: false,
          n: S.n,
          title: tr('pre_ttl', [S.n]),
          sub: tr('pre_sub'),
          cdl: tr('cd_start'),
          to: S.start,
          meta: [tr('m_reg', [afmt(c.players().length)]), kDate(S.start), tr('m_30')],
          clock: s.clock,
        ),
        children: [
          _PreBar(c: c),
          _RegCard(c: c, s: s),
          _PrizePanel(s: s),
          const _CmpCard(),
          _WarmUp(c: c),
          _SyncHead(c: c),
          _Activities(c: c, pre: true),
          _AllRules(c: c),
        ],
      );
    }
    return _TabFrame(
      s: s,
      id: 'today',
      tall: true,
      hero: _HeroBlock(
        live: true,
        n: S.n,
        title: tr('hero_t'),
        sub: tr('hero_s'),
        cdl: tr('cd_end'),
        to: S.end,
        meta: [tr('m_players', [afmt(c.players().length)]), tr('m_day', [S.day]), tr('m_prizes')],
        clock: s.clock,
      ),
      children: [
        _GoalCard(c: c),
        if (c.div == Div.phone) const _PhoneBanner(),
        if (c.store.cb == c.tk) const _ComeBack(),
        _Missions(c: c),
        _WeekCard(s: s),
        _PowerCard(c: c),
        _PrizePanel(s: s),
        _YouCard(c: c),
        _SyncHead(c: c),
        _Activities(c: c, pre: false),
        _FairBtn(c: c),
        _AllRules(c: c),
      ],
    );
  }
}

// ---- ئامانجی ئەمڕۆ (.v5g) ----
class _GoalCard extends StatelessWidget {
  const _GoalCard({required this.c});
  final ArenaCtl c;
  @override
  Widget build(BuildContext context) {
    final t = c.today.tot, g = c.goal, act = c.active;
    final counted = t >= act, done = t >= g;
    final bm = c.bestMoves();
    final sh = c.shield();
    final lost = sh.where((x) => x == 'x').length;
    final streak = c.store.streak + (counted ? 1 : 0);
    final have = c.activeDays + c.store.exc.length;
    Widget status;
    if (done) {
      status = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _okLine(tr('goal_done')),
        Text(tr('goal_more'), style: ats(12.5, c: AC.mu, h: 1.6)),
      ]);
    } else if (counted) {
      status = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _okLine(tr('counted')),
        _richNum(tr('to_goal', [g - t, g]), ats(12.5, c: AC.mu, h: 1.6), atn(12.5, w: FontWeight.w700, c: AC.mu, h: 1.6)),
      ]);
    } else {
      status = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _richNum(tr('to_count', [act - t]), ats(16, w: FontWeight.w800, h: 1.45), atn(16, h: 1.45)),
        _richNum(tr('day_n_of', [have + 1, 25]), ats(12.5, c: AC.mu, h: 1.6), atn(12.5, w: FontWeight.w700, c: AC.mu, h: 1.6)),
      ]);
    }
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AC.l ? Colors.white : null,
        gradient: AC.t3card,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AC.t3gl),
        boxShadow: AC.t3sh,
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          SizedBox(
            width: 132,
            height: 132,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 1300),
              curve: Curves.easeOutCubic,
              builder: (_, v, __) => CustomPaint(
                painter: _GoalRing(math.min(1, t / g) * v, math.min(1, act / g), counted, AC.track, AC.bg),
                child: Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Text(afmt(t * v), style: atn(32, h: 1.05)),
                    _richNum(tr('of_n', [g]), ats(12, w: FontWeight.w700, c: AC.mu), atn(12, w: FontWeight.w700, c: AC.mu)),
                  ]),
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(tr('goal_k'), style: ats(12.5, w: FontWeight.w800, c: AC.mu, ls: .25)),
              const SizedBox(height: 2),
              status,
            ]),
          ),
        ]),
        if (bm.isNotEmpty && !done) ...[
          const SizedBox(height: 14),
          _Tap(
            radius: 16,
            onTap: () => c.host.openSection(context, bm.first.cat.id),
            child: Ink(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                gradient: AC.goldG,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [cssSh(0, 10, 24, -12, const Color(0xCCF2B21C))],
              ),
              child: Row(children: [
                CatTile.cat(bm.first.cat, size: 30),
                const SizedBox(width: 10),
                Expanded(
                  child: _richNum(tr('do_now', [bm.first.cat.name, bm.first.cap - bm.first.base]), ats(14, w: FontWeight.w700, c: AC.onGold),
                      atn(14, c: AC.onGold)),
                ),
                const AIcon('down', size: 16, color: AC.onGold).rot(arenaLtr ? -90 : 90),
              ]),
            ),
          ),
          if (bm.length > 1) ...[
            const SizedBox(height: 8),
            Wrap(spacing: 6, runSpacing: 6, children: [
              for (final r in bm.skip(1))
                _Tap(
                  radius: 99,
                  onTap: () => catSheet(context, c, r.cat),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(color: AC.surf2, borderRadius: BorderRadius.circular(99), border: Border.all(color: AC.line)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      AIcon(r.cat.icon, size: 14, color: r.cat.color),
                      const SizedBox(width: 5),
                      Text('${r.cat.name} ', style: ats(12, w: FontWeight.w700)),
                      Text('+${r.cap - r.base}', style: atn(12, c: AC.mint)),
                    ]),
                  ),
                ),
            ]),
          ],
        ],
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _Pill5(icon: 'fire', k: const Color(0xFFFF8A4D), value: '$streak', label: tr('streak_d'), onTap: () => arenaToast(context, tr('streak_toast', [streak, ((streak + 1) / 7).ceil() * 7]), 'fire'))),
          const SizedBox(width: 6),
          Expanded(child: _Pill5(icon: 'shield', k: const Color(0xFF7FD8FF), value: '${c.store.frz}', of: '2', label: tr('freeze_s'), onTap: () => freezeSheet(context, c))),
          const SizedBox(width: 6),
          Expanded(child: _Pill5(icon: 'clock', k: const Color(0xFFB9A6FF), value: '${3 - c.store.exc.length}', of: '3', label: tr('excuse_s'), onTap: () => excuseSheet(context, c))),
        ]),
        Container(
          margin: const EdgeInsets.only(top: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: cssLin(135, const [Color(0x1FFF8A4D), Color(0x05FF8A4D)]),
            border: Border.all(color: const Color(0x4DFF8A4D)),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [
              AIcon('shield', size: 15, color: AC.tx),
              const SizedBox(width: 6),
              Expanded(child: Text(tr('shield_t'), style: ats(13, w: FontWeight.w800))),
              _richNum(tr('plus_pts', [math.max(0, 70 - lost * 10)]), ats(13, w: FontWeight.w900, c: const Color(0xFFFF9A6A)),
                  atn(13, w: FontWeight.w900, c: const Color(0xFFFF9A6A))),
            ]),
            const SizedBox(height: 10),
            Row(children: [
              for (var i = 0; i < 7; i++) ...[
                if (i > 0) const SizedBox(width: 5),
                Expanded(child: _ShieldSeg(sh[i])),
              ],
            ]),
            const SizedBox(height: 8),
            Text((lost > 0 ? '${tr('shield_lost', [lost])} ' : '') + tr('shield_s'), style: ats(11.5, c: AC.mu, h: 1.6)),
          ]),
        ),
      ]),
    );
  }

  Widget _okLine(String t) => Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(padding: const EdgeInsets.only(top: 4), child: AIcon('check', size: 15, color: AC.mint, sw: 2.2)),
        const SizedBox(width: 6),
        Flexible(child: Text(t, style: ats(16, w: FontWeight.w800, c: AC.mint, h: 1.45))),
      ]);
}

class _GoalRing extends CustomPainter {
  _GoalRing(this.f, this.mark, this.on, this.track, this.bg);
  final double f, mark;
  final bool on;
  final Color track, bg;
  @override
  void paint(Canvas c, Size s) {
    final k = s.width / 120;
    final ctr = s.center(Offset.zero);
    final r = 54 * k;
    c.drawCircle(ctr, r, Paint()
      ..color = track
      ..style = PaintingStyle.stroke
      ..strokeWidth = 11 * k);
    if (f > 0) {
      final rect = Rect.fromCircle(center: ctr, radius: r);
      c.drawArc(
          rect,
          -math.pi / 2,
          math.pi * 2 * f.clamp(0.0, 1.0),
          false,
          Paint()
            ..shader = const LinearGradient(
                    begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFFFFF0B0), Color(0xFFFFD25A), Color(0xFFE7A514)])
                .createShader(rect)
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.round
            ..strokeWidth = 11 * k);
    }
    final a = mark * 2 * math.pi;
    final p = Offset(ctr.dx + r * math.sin(a), ctr.dy - r * math.cos(a));
    c.drawCircle(p, 4.2 * k, Paint()..color = on ? const Color(0xFF3CF08A) : bg);
    c.drawCircle(p, 4.2 * k, Paint()
      ..color = const Color(0xFF3CF08A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2 * k);
  }

  @override
  bool shouldRepaint(_GoalRing o) => o.f != f || o.mark != mark || o.on != on || o.track != track;
}

class _Pill5 extends StatelessWidget {
  const _Pill5({required this.icon, required this.k, required this.value, required this.label, this.of, this.onTap});
  final String icon, value, label;
  final String? of;
  final Color k;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => _Tap(
        radius: 16,
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
          decoration: BoxDecoration(color: AC.surf2, borderRadius: BorderRadius.circular(16), border: Border.all(color: AC.line)),
          child: Column(children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(color: _a(k, .16), borderRadius: BorderRadius.circular(11)),
              alignment: Alignment.center,
              child: AIcon(icon, size: 18, color: k),
            ),
            const SizedBox(height: 3),
            Text.rich(
              TextSpan(children: [
                TextSpan(text: value, style: atn(18, c: AC.tx)),
                if (of != null) TextSpan(text: '/$of', style: atn(13, w: FontWeight.w700, c: AC.mu)),
              ]),
              textDirection: TextDirection.ltr,
            ),
            const SizedBox(height: 3),
            Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: ats(11.5, w: FontWeight.w700, c: AC.mu)),
          ]),
        ),
      );
}

class _ShieldSeg extends StatelessWidget {
  const _ShieldSeg(this.k);
  final String k;
  @override
  Widget build(BuildContext context) {
    const o = Color(0xFFFF8A4D);
    final ok = k == 'ok', now = k == 'now', x = k == 'x';
    return Container(
      height: 30,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        gradient: ok
            ? const LinearGradient(colors: [Color(0xFFFFB36B), Color(0xFFFF6A3D)], begin: Alignment.topCenter, end: Alignment.bottomCenter)
            : null,
        color: ok ? null : (x ? AC.surf2 : _a(o, now ? .18 : .1)),
        border: now ? Border.all(color: o, width: 1.5) : null,
        boxShadow: ok ? [cssSh(0, 6, 14, -8, const Color(0xFFFF6A3D))] : null,
      ),
      alignment: Alignment.center,
      child: AIcon(x ? 'close' : 'fire', size: 13, color: ok ? Colors.white : (x ? AC.mu : _a(o, now ? 1 : .6))),
    );
  }
}

class _PhoneBanner extends StatelessWidget {
  const _PhoneBanner();
  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(top: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: cssLin(120, const [Color(0x297FD8FF), Color(0x087FD8FF)]),
          border: Border.all(color: const Color(0x667FD8FF)),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(color: const Color(0x2E7FD8FF), borderRadius: BorderRadius.circular(13)),
            alignment: Alignment.center,
            child: const AIcon('phone', size: 20, color: Color(0xFF7FD8FF)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(tr('pb_t'), style: ats(14, w: FontWeight.w800)),
              const SizedBox(height: 2),
              _richNum(tr('pb_s'), ats(12, c: AC.mu, h: 1.6), atn(12, w: FontWeight.w700, c: AC.mu, h: 1.6)),
            ]),
          ),
        ]),
      );
}

class _ComeBack extends StatelessWidget {
  const _ComeBack();
  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(top: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: cssLin(120, const [Color(0x2E3CF08A), Color(0x0A3CF08A)]),
          border: Border.all(color: const Color(0x733CF08A)),
        ),
        child: Row(children: [
          AIcon('star', size: 22, color: AC.mint),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(tr('cb_t'), style: ats(15, w: FontWeight.w800)),
              _richNum(tr('cb_s'), ats(12.5, c: AC.mu), atn(12.5, w: FontWeight.w700, c: AC.mu)),
            ]),
          ),
        ]),
      );
}

// ---- ئەرکەکان (.v5ms) ----
class _Missions extends StatelessWidget {
  const _Missions({required this.c, this.inner = false});
  final ArenaCtl c;
  final bool inner;
  @override
  Widget build(BuildContext context) {
    final ms = c.missions();
    final done = ms.where((m) => m.ok).length;
    final open = c.chestOpen;
    final ready = done == 3 && !open;
    return Container(
      margin: EdgeInsets.only(top: inner ? 12 : 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AC.surf2, borderRadius: BorderRadius.circular(24), border: Border.all(color: AC.line)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        _H(tr('ms_t'), small: tr('n_of_3', [done])),
        for (var i = 0; i < ms.length; i++)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 9),
            decoration: BoxDecoration(border: i > 0 ? Border(top: BorderSide(color: AC.line)) : null),
            child: Row(children: [
              CatTile.cat(ms[i].cat, size: 34),
              const SizedBox(width: 10),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _richNum(tr(ms[i].key), ats(13.5, w: FontWeight.w800, c: ms[i].ok ? AC.mint : AC.tx, h: 1.5),
                      atn(13.5, c: ms[i].ok ? AC.mint : AC.tx, h: 1.5)),
                  Text(tr('${ms[i].key}_h'), style: ats(11.5, c: AC.mu, h: 1.5)),
                  const SizedBox(height: 5),
                  _Bar(ms[i].v / ms[i].target, color: ms[i].cat.color, h: 4),
                ]),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 40,
                child: Center(
                  child: ms[i].ok
                      ? AIcon('check', size: 16, color: AC.mint, sw: 2.2)
                      : Text('${ms[i].v}/${ms[i].target}', textDirection: TextDirection.ltr, style: atn(12, w: FontWeight.w700, c: AC.mu)),
                ),
              ),
            ]),
          ),
        _Tap(
          radius: 18,
          onTap: () {
            if (ready) {
              chestSheet(context, c);
            } else if (!open) {
              arenaToast(context, tr('chest_need_t', [3 - done]), 'gift');
            }
          },
          child: Ink(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: ready ? cssLin(120, const [Color(0x33FFC846), Color(0x0AFFC846)]) : null,
            ),
            child: CustomPaint(
              painter: ready ? null : _DashBorder(AC.line, 18),
              foregroundPainter: ready ? _SolidBorder(AC.accent, 18) : null,
              child: Padding(
                padding: const EdgeInsets.all(2),
                child: Row(children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      gradient: ready ? AC.goldG : null,
                      color: ready ? null : (open ? const Color(0x293CF08A) : AC.surf2),
                      boxShadow: ready ? const [BoxShadow(color: Color(0xB3FFC846), blurRadius: 16)] : null,
                    ),
                    alignment: Alignment.center,
                    child: AIcon('gift', size: 22, color: ready ? const Color(0xFF5A3A00) : (open ? AC.mint : AC.mu)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      _richNum(open ? tr('chest_got', [c.store.chest?['c'] ?? 0]) : (ready ? tr('chest_ready') : tr('chest_t')),
                          ats(14, w: FontWeight.w700, h: 1.6), atn(14, h: 1.6)),
                      _richNum(open ? tr('chest_tomorrow') : (ready ? tr('chest_range') : tr('chest_need', [3 - done])), ats(12, c: AC.mu, h: 1.6),
                          atn(12, w: FontWeight.w700, c: AC.mu, h: 1.6)),
                    ]),
                  ),
                ]),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}

class _DashBorder extends CustomPainter {
  _DashBorder(this.c, this.r);
  final Color c;
  final double r;
  @override
  void paint(Canvas cv, Size s) {
    final path = Path()..addRRect(RRect.fromRectAndRadius((Offset.zero & s).inflate(10), Radius.circular(r)));
    final p = Paint()
      ..color = c
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (final m in path.computeMetrics()) {
      var d = 0.0;
      while (d < m.length) {
        cv.drawPath(m.extractPath(d, math.min(d + 4, m.length)), p);
        d += 7;
      }
    }
  }

  @override
  bool shouldRepaint(_DashBorder o) => o.c != c;
}

class _SolidBorder extends CustomPainter {
  _SolidBorder(this.c, this.r);
  final Color c;
  final double r;
  @override
  void paint(Canvas cv, Size s) => cv.drawRRect(
      RRect.fromRectAndRadius((Offset.zero & s).inflate(10), Radius.circular(r)),
      Paint()
        ..color = c
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5);
  @override
  bool shouldRepaint(_SolidBorder o) => o.c != c;
}

// ---- گروپی هەفتە (.v5wk) ----
class _WeekCard extends StatelessWidget {
  const _WeekCard({required this.s});
  final _VexArenaPageState s;
  @override
  Widget build(BuildContext context) {
    final c = s.c;
    final g = c.weekGroup();
    final me = g.firstWhere((x) => x.me, orElse: () => g.first);
    final small = g.length < 5;
    final idx = g.indexOf(me);
    final near = g.sublist(math.max(0, idx - 2), math.min(g.length, idx + 2));
    final above = idx > 0 ? g[idx - 1] : null;
    final zoneGap = me.r > 10 && g.length >= 10 ? g[9].p - me.p + 1 : 0;
    final w = weekInfo(c.now);
    final lg = leagueOf(c.myTotal);
    final zk = me.r <= 3 ? 'gold' : me.r <= 10 ? 'ok' : '';
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AC.surf2, borderRadius: BorderRadius.circular(24), border: Border.all(color: AC.line)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        _Tap(
          onTap: () {
            s.upd(() {
              s.seg = 'week';
              s.toMe = true;
            });
            s.goTab(1);
          },
          child: Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(tr('wk_k', [lg.name]), style: ats(11.5, w: FontWeight.w700, c: AC.mu)),
                const SizedBox(height: 2),
                _richNum(tr('rank_of', ['#${me.r}', 30]), ats(24, w: FontWeight.w800, h: 1.3), atn(24, h: 1.3)),
                const SizedBox(height: 2),
                _richNum(tr('wk_left', [w.left + 1]), ats(11.5, w: FontWeight.w700, c: AC.mu), atn(11.5, c: AC.mu)),
              ]),
            ),
            const SizedBox(width: 10),
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * .42),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  gradient: zk == 'gold' ? AC.goldG : null,
                  color: zk == 'ok' ? const Color(0x1A3CF08A) : (zk == 'gold' ? null : AC.surf2),
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(color: zk == 'ok' ? const Color(0x733CF08A) : (zk == 'gold' ? Colors.transparent : AC.line)),
                ),
                child: _richNum(
                  small
                      ? tr('wk_members', ['${g.length}/30'])
                      : me.r <= 3
                          ? tr('wk_champ', [weekReward(me.r)])
                          : me.r <= 10
                              ? tr('wk_zone')
                              : tr('wk_gap', [zoneGap]),
                  ats(12, w: FontWeight.w800, c: zk == 'gold' ? AC.onGold : (zk == 'ok' ? AC.mint : AC.mu)),
                  atn(12, c: zk == 'gold' ? AC.onGold : (zk == 'ok' ? AC.mint : AC.mu)),
                  align: TextAlign.center,
                ),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 10),
        for (final x in near)
          Container(
            margin: const EdgeInsets.only(bottom: 2),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: x.me ? const Color(0x24FFC846) : null,
              borderRadius: BorderRadius.circular(12),
              border: x.me ? Border.all(color: const Color(0x73FFD678)) : null,
            ),
            child: Row(children: [
              SizedBox(width: 22, child: Text('${x.r}', textAlign: TextAlign.center, style: atn(13, c: x.me ? AC.t3g : AC.mu))),
              const SizedBox(width: 10),
              CharAvatar(ch: x.ch, name: x.n, size: 24, ring: x.me ? AC.cy : null),
              const SizedBox(width: 10),
              Expanded(child: Text(x.me ? tr('you') : nm(x.n), maxLines: 1, overflow: TextOverflow.ellipsis, style: ats(13, w: FontWeight.w700, c: x.me ? AC.t3g : AC.tx))),
              Text(afmt(x.p), style: atn(13)),
            ]),
          ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Padding(padding: const EdgeInsets.only(top: 4), child: AIcon(above != null ? 'up' : 'crown', size: 13, color: AC.mint)),
            const SizedBox(width: 6),
            Expanded(
              child: above != null
                  ? Text.rich(
                      TextSpan(children: [
                        TextSpan(text: nm(above.n), style: ats(12.5, w: FontWeight.w700)),
                        TextSpan(text: ' ${tr('rival_a')} '),
                        TextSpan(text: '${above.p - me.p + 1}', style: atn(12.5, w: FontWeight.w700)),
                        TextSpan(text: ' ${tr('rival_b')}'),
                      ]),
                      style: ats(12.5, c: AC.mu, h: 1.6),
                    )
                  : Text(tr('rival_top'), style: ats(12.5, c: AC.mu, h: 1.6)),
            ),
          ]),
        ),
      ]),
    );
  }
}

// ---- هێزی نهێنی (.t3pow) ----
class _PowerCard extends StatelessWidget {
  const _PowerCard({required this.c});
  final ArenaCtl c;
  @override
  Widget build(BuildContext context) {
    final g = c.store.guess[c.tk];
    final early = c.now.hour < 6;
    final y = c.store.days[c.yk];
    final l = AC.l;
    final pColor = l ? const Color(0xFF5B4BB0) : const Color(0xFFCBC1F2);
    return Container(
      margin: const EdgeInsets.only(top: 22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: l ? cssLin(160, const [Color(0xFFF4F0FF), Color(0xFFE9E2FF)]) : cssLin(160, const [Color(0xFF1F1650), Color(0xFF110C2C)]),
        border: Border.all(color: l ? const Color(0x476D4FE0) : const Color(0x66AA8CFF)),
      ),
      child: Stack(children: [
        if (!l)
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(26),
              child: CustomPaint(painter: _CornerGlow(const Color(0x599B7BFF), arenaLtr)),
            ),
          ),
        Padding(
          padding: const EdgeInsets.all(18),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: cssLin(145, const [Color(0xFFC9B8FF), Color(0xFF7B5CFF)]),
                  boxShadow: [cssSh(0, 12, 28, -8, const Color(0xD97B5CFF))],
                ),
                alignment: Alignment.center,
                child: Text('?', style: atn(28, c: Colors.white)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(tr('pw_t'), style: ats(18, w: FontWeight.w800, c: l ? AC.tx : Colors.white, h: 1.4)),
                  const SizedBox(height: 2),
                  _richNum(tr('pw_s'), ats(13, c: pColor, h: 1.7), atn(13, c: l ? AC.tx : Colors.white, h: 1.7)),
                ]),
              ),
            ]),
            Container(
              margin: const EdgeInsets.only(top: 14),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(color: l ? const Color(0x146D4FE0) : const Color(0x12FFFFFF), borderRadius: BorderRadius.circular(14)),
              child: Row(children: [
                const AIcon('bulb', size: 18, color: Color(0xFFFFD36B)),
                const SizedBox(width: 8),
                Expanded(child: Text(tr('hint_pre') + tr('hint_${c.today.power}'), style: ats(13, w: FontWeight.w600, c: l ? const Color(0xFF3B2C8A) : const Color(0xFFE4DDFF)))),
              ]),
            ),
            const SizedBox(height: 12),
            if (g == null)
              _Tap(
                radius: 16,
                onTap: () => guessSheet(context, c),
                child: Ink(
                  height: 50,
                  decoration: BoxDecoration(color: l ? const Color(0xFF6D4FE0) : Colors.white, borderRadius: BorderRadius.circular(16)),
                  child: Center(
                    child: _richNum(tr('pw_go'), ats(15, w: FontWeight.w800, c: l ? Colors.white : const Color(0xFF2A1D6B)),
                        atn(15, c: l ? Colors.white : const Color(0xFF2A1D6B))),
                  ),
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: l ? const Color(0x146D4FE0) : const Color(0x14FFFFFF), borderRadius: BorderRadius.circular(16)),
                child: Row(children: [
                  CatTile.cat(catById(g), size: 34),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(tr('pw_mine', [catById(g).name]), style: ats(14, w: FontWeight.w700, c: l ? AC.tx : Colors.white)),
                      _richNum(tr('pw_when'), ats(12, c: pColor), atn(12, w: FontWeight.w700, c: pColor)),
                    ]),
                  ),
                  AIcon('lock', size: 18, color: pColor),
                ]),
              ),
            const SizedBox(height: 8),
            _Tap(
              onTap: () => early ? arenaToast(context, tr('y_early'), 'clock') : yesterdaySheet(context, c),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(children: [
                  Expanded(
                    child: _richNum(
                      early ? tr('y_early') : tr('y_line', [catById(powerOf(c.yk)).name, catById(secondOf(c.yk)).name, afmt(y?.t ?? 0)]),
                      ats(12.5, w: FontWeight.w600, c: l ? const Color(0xFF5B4BB0) : const Color(0xFFB3A7E6)),
                      atn(12.5, w: FontWeight.w700, c: l ? const Color(0xFF5B4BB0) : const Color(0xFFB3A7E6)),
                    ),
                  ),
                  AIcon('down', size: 16, color: l ? const Color(0xFF5B4BB0) : const Color(0xFFB3A7E6)).rot(arenaLtr ? -90 : 90),
                ]),
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}

class _CornerGlow extends CustomPainter {
  _CornerGlow(this.c, this.ltr);
  final Color c;
  final bool ltr;
  @override
  void paint(Canvas cv, Size s) {
    _ellipse(cv, Offset.zero & s, Offset(ltr ? 0 : s.width, 0), s.width * .8, s.height * .9, [c, c.withAlpha(0)], const [0, .6]);
  }

  @override
  bool shouldRepaint(_CornerGlow o) => o.c != c || o.ltr != ltr;
}

// ---- خەڵاتەکان (.t3prz) — لە هەردوو دۆخدا تاریکە ----
class _PrizePanel extends StatefulWidget {
  const _PrizePanel({required this.s});
  final _VexArenaPageState s;
  @override
  State<_PrizePanel> createState() => _PrizePanelState();
}

class _PrizePanelState extends State<_PrizePanel> with SingleTickerProviderStateMixin {
  late final AnimationController a = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat();
  @override
  void dispose() {
    a.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.s, c = s.c;
    final d = s.przDiv ?? c.div;
    final z = kPrizes[d]!;
    const st = {
      1: [Color(0x99FFD26E), Color(0x57FFC846), AC.goldS, 106.0],
      2: [Color(0x52D2DCF5), Color(0x33D2DCF5), Color(0xFFDFE6FB), 76.0],
      3: [Color(0x73E69650), Color(0x38E69650), Color(0xFFFFB27A), 58.0],
    };
    Widget il(String k, bool big) {
      final svg = k == 'car' ? kPzCar : (k == 'phone' ? kPzPhone : kPzCash);
      final w = k == 'car' ? 107.0 : (k == 'phone' ? 50.0 : 72.0);
      return SizedBox(height: 68, child: Center(child: SvgPicture.string(svg, width: w)));
    }

    Widget col(Prize p) {
      final x = st[p.r]!;
      final c1 = x[0] as Color, c2 = x[1] as Color, c3 = x[2] as Color, h = x[3] as double;
      return Expanded(
        child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
          il(p.il, p.r == 1),
          const SizedBox(height: 8),
          Text(p.name, textAlign: TextAlign.center, maxLines: 2,
              style: ats(p.r == 1 ? 14.5 : 13, w: FontWeight.w800, c: p.r == 1 ? AC.goldS : AC.stageTx, h: 1.35)),
          const SizedBox(height: 8),
          Container(
            height: h,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16), bottom: Radius.circular(6)),
              gradient: LinearGradient(colors: [c2, c2.withAlpha(0)], begin: Alignment.topCenter, end: Alignment.bottomCenter),
              border: Border.all(color: c1),
              boxShadow: p.r == 1 ? [cssSh(0, -12, 40, -14, const Color(0xBFFFBE3C))] : null,
            ),
            alignment: Alignment.center,
            child: Text('${p.r}', style: atn(p.r == 1 ? 42 : 30, c: c3, h: 1.35)),
          ),
        ]),
      );
    }

    Widget pyr(String icon, String b, String sm) => Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0x0FFFFFFF),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0x38FFD678)),
          ),
          child: Row(children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(color: const Color(0x29FFC846), borderRadius: BorderRadius.circular(10)),
              alignment: Alignment.center,
              child: AIcon(icon, size: 18, color: AC.goldS),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(b, style: ats(13, w: FontWeight.w700, c: Colors.white, h: 1.6)),
                _richNum(sm, ats(11.5, c: const Color(0xFFC9CFEA), h: 1.55), atn(11.5, w: FontWeight.w700, c: const Color(0xFFC9CFEA), h: 1.55)),
              ]),
            ),
          ]),
        );
    return Container(
      margin: const EdgeInsets.only(top: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: cssLin(170, const [Color(0xFF16224D), Color(0xFF080D22)]),
        border: Border.all(color: const Color(0x61FFD678)),
        boxShadow: [cssSh(0, 24, 50, -26, const Color(0x8CFFBE3C))],
      ),
      child: Stack(children: [
        Positioned.fill(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Stack(children: [
              Positioned.fill(child: CustomPaint(painter: _PrzGlow())),
              Positioned(
                top: -10,
                left: 0,
                right: 0,
                child: Center(
                  child: AnimatedBuilder(
                    animation: a,
                    builder: (_, child) => Opacity(opacity: .5 + .45 * (.5 - .5 * math.cos(a.value * 2 * math.pi)), child: child),
                    child: ImageFiltered(
                      imageFilter: ui.ImageFilter.blur(sigmaX: 3, sigmaY: 3),
                      child: ClipPath(
                        clipper: _ConeClip(),
                        child: Container(
                          width: 200,
                          height: 260,
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Color(0x4DFFF0C8), Color(0x00FFF0C8)],
                              stops: [0, .85],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ]),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _H(tr('pz_t', [tr(d == Div.band ? 'dv_band' : 'dv_phone')]), small: tr(d == Div.band ? 'pz_big' : 'pz_norm'),
                color: const Color(0xFFEEF3FF), smallColor: AC.stageMu),
            _Tap(
              radius: 16,
              onTap: () => prizeSheet(context, c, d),
              child: SizedBox(
                height: 210,
                child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [col(z[1]), const SizedBox(width: 8), col(z[0]), const SizedBox(width: 8), col(z[2])]),
              ),
            ),
            const SizedBox(height: 12),
            pyr('trophy', tr('pz_week_t'), tr('pz_week_s')),
            pyr('gift', tr('pz_guar_t'), tr(d == Div.band ? 'pz_guar_b' : 'pz_guar_p')),
            const SizedBox(height: 4),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const AIcon('flag', size: 15, color: AC.stageMu),
              const SizedBox(width: 6),
              Flexible(child: _richNum(tr('pz_rule', [activeMin(d)]), ats(12.5, w: FontWeight.w600, c: AC.stageMu), atn(12.5, c: Colors.white))),
            ]),
            const SizedBox(height: 10),
            _Tap(
              radius: 14,
              onTap: () => s.upd(() => s.przDiv = d == Div.band ? Div.phone : Div.band),
              child: Ink(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: const Color(0x0DFFFFFF), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0x24FFFFFF))),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  AIcon(d == Div.band ? 'phone' : 'shield', size: 14, color: const Color(0xFFC9CFEA)),
                  const SizedBox(width: 6),
                  Text(tr('pz_other', [tr(d == Div.band ? 'dv_phone' : 'dv_band')]), style: ats(12.5, w: FontWeight.w700, c: const Color(0xFFC9CFEA))),
                ]),
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}

class _PrzGlow extends CustomPainter {
  @override
  void paint(Canvas c, Size s) {
    _ellipse(c, Offset.zero & s, Offset(s.width * .5, s.height * .38), s.width * .7, s.height * .55, const [Color(0x4DFFC450), Color(0x00FFC450)], const [0, .7]);
  }

  @override
  bool shouldRepaint(_PrzGlow o) => false;
}

class _ConeClip extends CustomClipper<Path> {
  @override
  Path getClip(Size s) => Path()
    ..moveTo(s.width * .42, 0)
    ..lineTo(s.width * .58, 0)
    ..lineTo(s.width, s.height)
    ..lineTo(0, s.height)
    ..close();
  @override
  bool shouldReclip(_ConeClip o) => false;
}

// ---- تۆ لەم وەرزەدا (.t3me) ----
class _YouCard extends StatelessWidget {
  const _YouCard({required this.c});
  final ArenaCtl c;
  @override
  Widget build(BuildContext context) {
    final tot = c.myTotal, lg = leagueOf(tot);
    final have = c.activeDays + c.store.exc.length, need = 25, left = c.S.daysLeft;
    final ok = have >= need, can = have + left - 1 >= need;
    final band = c.div == Div.band;
    Widget badge(String icon, String t, bool gold) => Container(
          margin: const EdgeInsetsDirectional.only(start: 6),
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
          decoration: BoxDecoration(
            gradient: gold ? AC.goldG : null,
            color: gold ? null : AC.surf2,
            borderRadius: BorderRadius.circular(99),
            border: gold ? null : Border.all(color: AC.line),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            AIcon(icon, size: 11, color: gold ? AC.onGold : AC.mu),
            const SizedBox(width: 3),
            Flexible(child: _richNum(t, ats(10.5, w: FontWeight.w800, c: gold ? AC.onGold : AC.mu), atn(10.5, c: gold ? AC.onGold : AC.mu))),
          ]),
        );
    Widget stat(Widget icon, String v, String l, {bool num = true}) => Expanded(
          child: Column(children: [
            SizedBox(height: 26, child: Center(child: icon)),
            const SizedBox(height: 3),
            Text(v, maxLines: 1, style: num ? atn(14, c: AC.tx) : ats(14, w: FontWeight.w800)),
            const SizedBox(height: 3),
            Text(l, maxLines: 1, overflow: TextOverflow.ellipsis, style: ats(11.5, w: FontWeight.w700, c: AC.mu)),
          ]),
        );
    return Container(
      margin: const EdgeInsets.only(top: 22),
      decoration: BoxDecoration(
        color: AC.l ? Colors.white : null,
        gradient: AC.t3card,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AC.t3gl),
        boxShadow: AC.t3sh,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: AlignmentDirectional.centerStart,
              end: AlignmentDirectional.centerEnd,
              colors: AC.l ? const [Color(0x29E6A014), Color(0x05E6A014)] : const [Color(0x33FFC846), Color(0x08FFC846)],
            ),
          ),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
              child: Wrap(crossAxisAlignment: WrapCrossAlignment.center, runSpacing: 6, children: [
                Text(tr('you_t'), style: ats(13, w: FontWeight.w800, c: AC.t3g)),
                badge(band ? 'shield' : 'phone', tr(band ? 'dv_band' : 'dv_phone'), band),
                if (c.founder) badge('star', tr('founder'), true) else badge('pin', tr('joined_day', [math.max(1, c.joinDay)]), false),
              ]),
            ),
            const SizedBox(width: 8),
            Row(mainAxisSize: MainAxisSize.min, children: [
              AIcon('chart', size: 13, color: AC.mint),
              const SizedBox(width: 4),
              _richNum(tr('rank_all', ['#${afmt(c.rankOf(tot))}']), ats(12, w: FontWeight.w800, c: AC.mint), atn(12, c: AC.mint)),
            ]),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [
              Expanded(child: Text(tr('act_days'), style: ats(12.5, w: FontWeight.w700))),
              _richNum(tr('n_of2', [have, need]), ats(12.5, w: FontWeight.w700), atn(12.5)),
            ]),
            const SizedBox(height: 8),
            _Bar(have / need, h: 10, gradient: LinearGradient(begin: AlignmentDirectional.centerEnd, end: AlignmentDirectional.centerStart, colors: const [Color(0xFFFFE08A), Color(0xFFF2B21C)]), glow: true),
            const SizedBox(height: 8),
            _richNum(
              ok ? tr('el_ok') : can ? tr('el_can', [left, need - have]) : (have + left - 1 >= 20 ? tr('el_no25') : tr('el_noall')),
              ats(12.5, c: AC.mu, h: 1.7),
              atn(12.5, c: AC.tx, h: 1.7),
            ),
          ]),
        ),
        Container(
          margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
          padding: const EdgeInsets.only(top: 14, bottom: 16),
          decoration: BoxDecoration(border: Border(top: BorderSide(color: AC.line))),
          child: Row(children: [
            stat(Emblem(lg.idx, size: 22), lg.name, tr('league'), num: false),
            stat(AIcon('chart', size: 22, color: AC.c2), afmt(tot), tr('season_tot')),
            stat(const AIcon('star', size: 22, color: Color(0xFFB9A6FF)), '${levelOf(tot)}', tr('level')),
            stat(const AIcon('target', size: 22, color: Color(0xFFFF8A4D)), afmt(c.avgDaily), tr('avg')),
          ]),
        ),
      ]),
    );
  }
}

// ---- چالاکییەکان ----
class _SyncHead extends StatelessWidget {
  const _SyncHead({required this.c});
  final ArenaCtl c;
  @override
  Widget build(BuildContext context) {
    final ls = c.lastSync;
    return Padding(
      padding: const EdgeInsets.only(top: 22, bottom: 12),
      child: Row(children: [
        Expanded(child: Text(c.live ? tr('act_t') : tr('act_t_pre'), style: ats(18, w: FontWeight.w800))),
        _Tap(
          radius: 99,
          onTap: () {
            c.refresh();
            arenaToast(context, tr('synced'), 'sync');
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(color: _a(AC.mint, .08), borderRadius: BorderRadius.circular(99), border: Border.all(color: _a(AC.mint, .4))),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              AIcon('shield', size: 13, color: AC.mint),
              const SizedBox(width: 5),
              Text(tr('sync_src'), style: ats(11.5, w: FontWeight.w800, c: AC.mint)),
              Text('${_p2(ls.hour)}:${_p2(ls.minute)}', style: atn(11.5, c: AC.mint)),
              const SizedBox(width: 5),
              AIcon('sync', size: 13, color: AC.mint),
            ]),
          ),
        ),
      ]),
    );
  }
}

class _Activities extends StatelessWidget {
  const _Activities({required this.c, required this.pre});
  final ArenaCtl c;
  final bool pre;
  @override
  Widget build(BuildContext context) {
    final rows = [...c.today.rows]..sort((a, b) {
        if ((a.cap > 0) != (b.cap > 0)) return a.cap > 0 ? -1 : 1;
        if ((a.base > 0) != (b.base > 0)) return a.base > 0 ? -1 : 1;
        return (b.cap == 0 ? 0 : b.base / b.cap).compareTo(a.cap == 0 ? 0 : a.base / a.cap);
      });
    final n = rows.where((r) => r.cap > 0).length, done = rows.where((r) => r.base > 0).length;
    final rev = c.store.rev.contains(c.tk);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      for (final r in rows) ...[
        _ActRow(c: c, r: r, d: c.data[r.cat.id] ?? const CatValue('', 0, 'none'), rev: rev),
        const SizedBox(height: 8),
      ],
      Container(
        margin: const EdgeInsets.only(top: 2),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: cssLin(135, AC.l ? const [Color(0x24E6A014), Color(0x08E6A014)] : const [Color(0x29FFC846), Color(0x0AFFC846)]),
          border: Border.all(color: AC.t3gl),
        ),
        child: Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(pre ? tr('tot_pre') : tr('tot_t'), style: ats(15, w: FontWeight.w800, h: 1.6)),
              _richNum(tr('tot_s', [done, n]), ats(12, w: FontWeight.w600, c: AC.mu, h: 1.6), atn(12, w: FontWeight.w700, c: AC.mu, h: 1.6)),
            ]),
          ),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(afmt(c.today.tot), style: atn(26, c: AC.t3g, h: 1.1)),
            _richNum(tr('of_n', [maxDay(c.div)]), ats(12, w: FontWeight.w600, c: AC.mu), atn(12, w: FontWeight.w600, c: AC.mu)),
          ]),
        ]),
      ),
    ]);
  }
}

class _ActRow extends StatelessWidget {
  const _ActRow({required this.c, required this.r, required this.d, required this.rev});
  final ArenaCtl c;
  final PointRow r;
  final CatValue d;
  final bool rev;
  @override
  Widget build(BuildContext context) {
    final na = r.cap == 0, idle = r.base == 0;
    final f = na ? 0.0 : r.base / r.cap;
    Widget vb(String icon, String text, Color fg, Color bg) => Container(
          margin: const EdgeInsetsDirectional.only(start: 6),
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(99)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            AIcon(icon, size: 10, color: fg, sw: 2.2),
            if (text.isNotEmpty) ...[const SizedBox(width: 2), Text(text, style: ats(10, w: FontWeight.w800, c: fg, h: 1.2))],
          ]),
        );
    Widget? badge;
    if (na) {
      badge = vb('lock', 'Band', AC.mu, AC.surf2);
    } else if (d.st == 'rej') {
      badge = vb('close', tr('rejected'), const Color(0xFFFF8A9C), const Color(0x24FF5F7E));
    } else if (d.st == 'wait') {
      badge = vb('clock', 'Band', AC.mu, AC.surf2);
    } else if (d.note.isNotEmpty) {
      badge = vb('help', tr('partial'), const Color(0xFFFFB27A), const Color(0x24FF8A4D));
    } else if (d.st == 'ok') {
      badge = vb('check', '', AC.mint, const Color(0x1F3CF08A));
    }
    return Opacity(
      opacity: na ? .55 : 1,
      child: _Tap(
        radius: 20,
        onTap: () => catSheet(context, c, r.cat),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(color: AC.surf2, borderRadius: BorderRadius.circular(20), border: Border.all(color: AC.line)),
          child: Row(children: [
            CatTile.cat(r.cat, size: 46, idle: idle, strong: true),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Flexible(child: Text(r.cat.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: ats(14.5, w: FontWeight.w800, h: 1.5))),
                  if (rev && r.mult > 1 && r.cap > 0)
                    Container(
                      margin: const EdgeInsetsDirectional.only(start: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(color: _a(r.cat.color, .22), borderRadius: BorderRadius.circular(99)),
                      child: Text('×${r.mult == 3 ? '3' : '1.5'}', style: atn(10.5, w: FontWeight.w900, c: r.cat.color)),
                    ),
                ]),
                Row(children: [
                  Flexible(child: Text(d.label, maxLines: 1, overflow: TextOverflow.ellipsis, style: ats(12, w: FontWeight.w600, c: AC.mu, h: 1.6))),
                  if (badge != null) badge,
                ]),
                const SizedBox(height: 5),
                _Bar(f, color: r.cat.color, h: 5),
              ]),
            ),
            const SizedBox(width: 12),
            ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 48),
              child: Column(children: [
                Text(na ? '—' : (rev ? (r.pts > 0 ? '+${r.pts}' : '0') : '${r.base}'),
                    style: atn(21, c: rev && r.pts > 0 ? AC.mint : AC.tx, h: 1.15)),
                const SizedBox(height: 2),
                _richNum(na ? tr('dv_band') : (rev ? tr('pts') : tr('of_n', [r.cap])), ats(11, w: FontWeight.w600, c: AC.mu),
                    atn(11, w: FontWeight.w600, c: AC.mu)),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

class _FairBtn extends StatelessWidget {
  const _FairBtn({required this.c});
  final ArenaCtl c;
  @override
  Widget build(BuildContext context) {
    final rej = c.data.values.where((d) => d.st == 'rej').length;
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: _Tap(
        radius: 20,
        onTap: () => fairSheet(context, c),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(color: AC.l ? const Color(0x1413A85C) : const Color(0x123CF08A), borderRadius: BorderRadius.circular(20)),
          child: Row(children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: const Color(0x293CF08A), borderRadius: BorderRadius.circular(13)),
              alignment: Alignment.center,
              child: AIcon('shield', size: 20, color: AC.mint),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(tr('fair_t'), style: ats(15, w: FontWeight.w800, h: 1.6)),
                _richNum(rej > 0 ? tr('fair_rej', [rej]) : tr('fair_ok'), ats(12.5, w: FontWeight.w600, c: AC.mu, h: 1.6),
                    atn(12.5, c: AC.mu, h: 1.6)),
              ]),
            ),
            AIcon('down', size: 16, color: AC.mu).rot(arenaLtr ? -90 : 90),
          ]),
        ),
      ),
    );
  }
}

class _AllRules extends StatelessWidget {
  const _AllRules({required this.c});
  final ArenaCtl c;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 10),
        child: _Tap(
          radius: 16,
          onTap: () => rulesSheet(context, c),
          child: Ink(
            height: 48,
            decoration: BoxDecoration(color: AC.surf2, borderRadius: BorderRadius.circular(16), border: Border.all(color: AC.line)),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              AIcon('help', size: 18, color: AC.tx),
              const SizedBox(width: 6),
              Text(tr('rules_all'), style: ats(14, w: FontWeight.w700)),
            ]),
          ),
        ),
      );
}

// =============================================================================
// پێش وەرز
// =============================================================================

/// ئاگادارکردنەوەی وەرز (.v6nb)
class _PreBar extends StatelessWidget {
  const _PreBar({required this.c});
  final ArenaCtl c;
  @override
  Widget build(BuildContext context) {
    final d = math.max(0, c.S.start.difference(DateTime.now()).inDays + 1);
    final hot = d <= 3;
    final k = hot ? const Color(0xFFFF8A4D) : const Color(0xFF7FD8FF);
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: _Tap(
        radius: 18,
        onTap: () => prizeSheet(context, c, c.div),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: cssLin(120, [_a(k, hot ? .2 : .16), _a(k, .03)]),
            border: Border.all(color: _a(k, hot ? .55 : .4)),
          ),
          child: Row(children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(color: _a(k, .18), borderRadius: BorderRadius.circular(12)),
              alignment: Alignment.center,
              child: AIcon('bell', size: 18, color: k),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _richNum(tr('nb_t', [c.S.n, d]), ats(14, w: FontWeight.w800), atn(14)),
                const SizedBox(height: 1),
                _richNum('${kDate(c.S.start)} · ${tr('nb_6am')}${c.regd ? tr('nb_reg') : tr('nb_join')}', ats(11.5, c: AC.mu), atn(11.5, w: FontWeight.w600, c: AC.mu)),
              ]),
            ),
            AIcon('down', size: 15, color: AC.mu).rot(arenaLtr ? -90 : 90),
          ]),
        ),
      ),
    );
  }
}

/// تۆمارکراویت (.v6rg.ok)
class _RegCard extends StatelessWidget {
  const _RegCard({required this.c, required this.s});
  final ArenaCtl c;
  final _VexArenaPageState s;
  @override
  Widget build(BuildContext context) {
    final on = c.store.rmd;
    return Container(
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AC.l ? Colors.white : null,
        gradient: cssLin(130, AC.l ? const [Color(0x2413A85C), Color(0x05FFFFFF)] : const [Color(0x243CF08A), Color(0x0513224A)]),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0x733CF08A)),
        boxShadow: AC.t3sh,
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(17),
              gradient: cssLin(160, const [Color(0xFF5BF5A0), Color(0xFF16B764)]),
              boxShadow: [cssSh(0, 10, 24, -10, const Color(0xFF16B764))],
            ),
            alignment: Alignment.center,
            child: const AIcon('check', size: 26, color: Color(0xFF04301A), sw: 2.4),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _richNum(tr('rg_k', [c.S.n]), ats(11.5, w: FontWeight.w800, c: AC.mint), atn(11.5, c: AC.mint)),
              Text(tr('rg_t', [nm(c.store.acc?.name ?? '')]), style: ats(16, w: FontWeight.w800, h: 1.5)),
              Text(tr('rg_s', [kDate(c.S.start)]), style: ats(12.5, c: AC.mu, h: 1.6)),
            ]),
          ),
        ]),
        const SizedBox(height: 12),
        _Tap(
          radius: 14,
          onTap: () {
            c.store.rmd = !c.store.rmd;
            c.store.save();
            s.upd(() {});
            arenaToast(context, c.store.rmd ? tr('rm_on_t') : tr('rm_off_t'), 'bell');
          },
          child: Ink(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AC.surf2,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: on ? const Color(0x733CF08A) : AC.line),
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              AIcon('bell', size: 15, color: on ? AC.mint : AC.tx),
              const SizedBox(width: 6),
              Flexible(child: Text(on ? tr('rm_on') : tr('rm_off'), style: ats(13, w: FontWeight.w700, c: on ? AC.mint : AC.tx))),
            ]),
          ),
        ),
      ]),
    );
  }
}

/// کەی بەشداربیت؟ (.v7cmp)
class _CmpCard extends StatelessWidget {
  const _CmpCard();
  @override
  Widget build(BuildContext context) {
    final rows = <List<Object?>>[
      ['star', tr('ej_badge'), null],
      ['gift', tr('ej_50'), tr('ej_20')],
      ['calendar', tr('ej_all30'), tr('ej_left')],
      ['trophy', tr('ej_allpz'), tr('ej_to6')],
      ['users', tr('ej_week'), tr('ej_week')],
      ['crown', tr('ej_tie'), null],
    ];
    Widget seg(int f, Gradient? g, Color? col, Widget ch) => Expanded(
          flex: f,
          child: Container(
            decoration: BoxDecoration(gradient: g, color: col),
            alignment: Alignment.center,
            child: FittedBox(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: ch)),
          ),
        );
    TextStyle sb([Color? c]) => ats(10.5, w: FontWeight.w800, c: c ?? const Color(0xFF1C1300));
    Widget lg(Gradient? g, Color? col, String t) => Row(children: [
          Container(width: 12, height: 12, decoration: BoxDecoration(gradient: g, color: col, borderRadius: BorderRadius.circular(4))),
          const SizedBox(width: 6),
          Expanded(child: _richNum(t, ats(11.5, c: AC.mu, h: 1.4), atn(11.5, w: FontWeight.w600, c: AC.mu, h: 1.4))),
        ]);
    final s0 = cssLin(135, const [Color(0xFFFFF0B0), Color(0xFFF2B21C)]);
    final s1 = cssLin(135, const [Color(0xFF7DF5B1), Color(0xFF22C26F)]);
    final s2 = cssLin(135, const [Color(0xFFFFD29A), Color(0xFFFF9A4D)]);
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AC.surf2, borderRadius: BorderRadius.circular(24), border: Border.all(color: AC.line)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        _H(tr('ej_t'), small: tr('ej_s'), pad: const EdgeInsets.only(bottom: 4)),
        Text(tr('ej_p'), style: ats(12.5, c: AC.mu, h: 1.7)),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.only(top: 30),
          child: Stack(clipBehavior: Clip.none, children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                height: 34,
                child: Row(children: [
                  seg(4, s0, null, Row(mainAxisSize: MainAxisSize.min, children: [const AIcon('star', size: 12, color: Color(0xFF1C1300)), const SizedBox(width: 3), Text(tr('now'), style: sb())])),
                  const SizedBox(width: 3),
                  seg(6, s1, null, _richNum(tr('ej_d16'), sb(), atn(10.5, c: const Color(0xFF1C1300)))),
                  const SizedBox(width: 3),
                  seg(5, s2, null, Text('7–11', style: atn(10.5, c: const Color(0xFF1C1300)))),
                  const SizedBox(width: 3),
                  seg(9, null, AC.track, Text('12–30', style: atn(10.5, c: AC.mu))),
                ]),
              ),
            ),
            PositionedDirectional(
              top: -30,
              start: 0,
              child: Column(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(gradient: AC.goldG, borderRadius: BorderRadius.circular(99)),
                  child: Text(tr('ej_here'), style: ats(10.5, w: FontWeight.w800, c: AC.onGold)),
                ),
                Container(width: 2, height: 8, color: AC.accent),
              ]),
            ),
          ]),
        ),
        const SizedBox(height: 10),
        Row(children: [Expanded(child: lg(s0, null, tr('ej_l0'))), const SizedBox(width: 10), Expanded(child: lg(s1, null, tr('ej_l1')))]),
        const SizedBox(height: 6),
        Row(children: [Expanded(child: lg(s2, null, tr('ej_l2'))), const SizedBox(width: 10), Expanded(child: lg(null, AC.track, tr('ej_l3')))]),
        const SizedBox(height: 14),
        Container(
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(18), border: Border.all(color: AC.line)),
          clipBehavior: Clip.antiAlias,
          child: Column(children: [
            Row(children: [
              const SizedBox(width: 40),
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(gradient: AC.goldG),
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const AIcon('star', size: 14, color: AC.onGold),
                    const SizedBox(width: 4),
                    Flexible(child: Text(tr('ej_before'), textAlign: TextAlign.center, style: ats(12, w: FontWeight.w800, c: AC.onGold))),
                  ]),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
                  child: Text(tr('ej_after'), textAlign: TextAlign.center, style: ats(12, w: FontWeight.w800, c: AC.mu)),
                ),
              ),
            ]),
            for (final r in rows)
              Container(
                constraints: const BoxConstraints(minHeight: 42),
                decoration: BoxDecoration(border: Border(top: BorderSide(color: AC.line))),
                child: IntrinsicHeight(
                  child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    SizedBox(width: 40, child: Center(child: AIcon(r[0] as String, size: 15, color: AC.mu))),
                    Expanded(
                      child: Container(
                        color: const Color(0x1AFFC846),
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
                        alignment: Alignment.center,
                        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          AIcon('check', size: 13, color: AC.mint, sw: 2.2),
                          const SizedBox(width: 3),
                          Flexible(child: _richNum(r[1] as String, ats(12, w: FontWeight.w700, c: AC.t3g, h: 1.5), atn(12, c: AC.t3g, h: 1.5), align: TextAlign.center)),
                        ]),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
                        alignment: Alignment.center,
                        child: r[2] == null
                            ? Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                                AIcon('close', size: 13, color: AC.coral),
                                const SizedBox(width: 3),
                                Text(tr('none'), style: ats(12, w: FontWeight.w700, c: AC.coral)),
                              ])
                            : _richNum(r[2] as String, ats(12, w: FontWeight.w700, c: AC.mu, h: 1.5), atn(12, c: AC.mu, h: 1.5), align: TextAlign.center),
                      ),
                    ),
                  ]),
                ),
              ),
          ]),
        ),
      ]),
    );
  }
}

/// ڕاهێنانی پێش وەرز (.v6wu)
class _WarmUp extends StatelessWidget {
  const _WarmUp({required this.c});
  final ArenaCtl c;
  @override
  Widget build(BuildContext context) {
    final t = c.today.tot, act = c.active;
    Widget box(String l, Widget v) => Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
            decoration: BoxDecoration(color: AC.surf2, borderRadius: BorderRadius.circular(16), border: Border.all(color: AC.line)),
            child: Column(children: [
              Text(l, textAlign: TextAlign.center, style: ats(11, w: FontWeight.w700, c: AC.mu)),
              const SizedBox(height: 3),
              v,
            ]),
          ),
        );
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        _H(tr('wu_t'), small: tr('wu_s'), pad: const EdgeInsets.only(bottom: 6)),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 2), child: Text(tr('wu_p'), style: ats(12.5, c: AC.mu, h: 1.7))),
        const SizedBox(height: 10),
        Row(children: [
          box(tr('wu_pts'), Text(afmt(t), style: atn(20))),
          const SizedBox(width: 6),
          box(tr('wu_coins'), Text('${c.coinsToday}/${coinMax(c.div)}', textDirection: TextDirection.ltr, style: atn(20))),
          const SizedBox(width: 6),
          box(tr('wu_act'), t >= act ? AIcon('check', size: 18, color: AC.mint, sw: 2.4) : _richNum(tr('wu_left', [act - t]), ats(20, w: FontWeight.w800), atn(20))),
        ]),
        _Missions(c: c, inner: true),
      ]),
    );
  }
}
