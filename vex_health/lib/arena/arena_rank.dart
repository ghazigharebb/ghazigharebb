// VEX Arena — تابی «پلەکان»
part of 'vex_arena.dart';

const List<List<String>> _kSegs = [
  ['week', 'users'],
  ['all', 'trophy'],
  ['age', 'users'],
  ['guess', 'crystal'],
];

class _RankTab extends StatelessWidget {
  const _RankTab({required this.s});
  final _VexArenaPageState s;

  @override
  Widget build(BuildContext context) {
    final c = s.c;
    final pre = !c.live;
    var seg = s.seg;
    if (pre && seg == 'week') seg = 'all';
    if (!_kSegs.any((x) => x[0] == seg)) seg = 'all';
    return _TabFrame(s: s, id: 'rank', children: [
      if (pre) _PreBar(c: c),
      if (seg == 'week') _WeekBoard(s: s) else _Board(s: s, seg: seg),
    ]);
  }
}

class _Segs extends StatelessWidget {
  const _Segs({required this.s, required this.seg, required this.pre});
  final _VexArenaPageState s;
  final String seg;
  final bool pre;
  @override
  Widget build(BuildContext context) {
    final list = _kSegs.where((x) => !pre || x[0] != 'week').toList();
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: AC.surf2, borderRadius: BorderRadius.circular(16), border: Border.all(color: AC.line)),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(children: [
          for (final x in list) ...[
            if (x != list.first) const SizedBox(width: 4),
            _Tap(
              radius: 12,
              onTap: () => s.upd(() {
                s.seg = x[0];
                s.shown = 11;
              }),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
                decoration: BoxDecoration(gradient: x[0] == seg ? AC.tabG : null, borderRadius: BorderRadius.circular(12)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  AIcon(x[1], size: 14, color: x[0] == seg ? AC.onGold : AC.mu),
                  const SizedBox(width: 5),
                  Text(tr(x[0] == 'all' && pre ? 'sg_reg' : 'sg_${x[0]}'), style: ats(12, w: FontWeight.w800, c: x[0] == seg ? AC.onGold : AC.mu)),
                ]),
              ),
            ),
          ],
        ]),
      ),
    );
  }
}

/// گروپی هەفتە (rWeek)
class _WeekBoard extends StatefulWidget {
  const _WeekBoard({required this.s});
  final _VexArenaPageState s;
  @override
  State<_WeekBoard> createState() => _WeekBoardState();
}

class _WeekBoardState extends State<_WeekBoard> {
  final GlobalKey meK = GlobalKey();
  @override
  Widget build(BuildContext context) {
    final s = widget.s, c = s.c;
    final g = c.weekGroup();
    final me = g.firstWhere((x) => x.me, orElse: () => g.first);
    final small = g.length < 5;
    final lg = leagueOf(c.myTotal);
    final w = weekInfo(c.now);
    if (s.toMe) {
      s.toMe = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final ctx = meK.currentContext;
        if (ctx != null) Scrollable.ensureVisible(ctx, alignment: .5, duration: const Duration(milliseconds: 500));
      });
    }
    Widget sum(String l, Widget v) => Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
            decoration: BoxDecoration(color: AC.surf2, borderRadius: BorderRadius.circular(14), border: Border.all(color: AC.line)),
            child: Column(children: [
              Text(l, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis, style: ats(11, w: FontWeight.w700, c: AC.mu)),
              const SizedBox(height: 2),
              v,
            ]),
          ),
        );
    Widget line(String t, bool gold) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(children: [
            Expanded(child: Container(height: 1, color: gold ? const Color(0x73FFD678) : const Color(0x593CF08A))),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(t, style: ats(11, w: FontWeight.w800, c: gold ? AC.t3g : AC.mint)),
            ),
            Expanded(child: Container(height: 1, color: gold ? const Color(0x73FFD678) : const Color(0x593CF08A))),
          ]),
        );
    return _Card(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _Ttl('users', tr('wk_title'), small: '${tr(c.div == Div.band ? 'dv_band' : 'dv_phone')} · ${tr('league_of', [lg.name])}'),
      _Segs(s: s, seg: 'week', pre: false),
      const SizedBox(height: 12),
      Row(children: [
        sum(tr('ws_rank'), Text('#${me.r}', style: atn(18))),
        const SizedBox(width: 6),
        sum(tr('ws_pts'), Text(afmt(me.p), style: atn(18))),
        const SizedBox(width: 6),
        sum(tr('ws_left'), _richNum(tr('n_days', [w.left + 1]), ats(18, w: FontWeight.w800), atn(18))),
      ]),
      Container(
        margin: const EdgeInsets.only(top: 10),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(color: const Color(0x1AFFC846), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0x4DFFD678))),
        child: Row(children: [
          AIcon(small ? 'users' : (me.r <= 10 ? 'trophy' : 'target'), size: 14, color: AC.t3g),
          const SizedBox(width: 6),
          Expanded(
            child: _richNum(
              small ? tr('wr_small', [g.length]) : (me.r <= 10 ? tr('wr_zone', [weekReward(me.r)]) : tr('wr_gap', [g[9].p - me.p + 1])),
              ats(12.5, h: 1.6),
              atn(12.5, h: 1.6),
            ),
          ),
        ]),
      ),
      const SizedBox(height: 4),
      for (final x in g) ...[
        Container(
          key: x.me ? meK : null,
          margin: const EdgeInsets.only(top: 2),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
          decoration: BoxDecoration(
            color: x.me ? const Color(0x24FFC846) : null,
            borderRadius: BorderRadius.circular(14),
            border: x.me ? Border.all(color: const Color(0x80FFD678)) : null,
          ),
          child: Row(children: [
            SizedBox(width: 22, child: Text('${x.r}', textAlign: TextAlign.center, style: atn(13, c: x.r <= 3 || x.me ? AC.t3g : AC.mu))),
            const SizedBox(width: 10),
            CharAvatar(
                ch: x.ch,
                name: x.n,
                size: 30,
                ring: x.me ? AC.cy : x.r == 1 ? AC.gold : x.r == 2 ? AC.silver : x.r == 3 ? AC.bronze : null),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(x.me ? '${tr('you')} · ${nm(x.n)}' : nm(x.n), maxLines: 1, overflow: TextOverflow.ellipsis, style: ats(13.5, w: FontWeight.w700, h: 1.5)),
                Text(nm(x.city), style: ats(11, c: AC.mu, h: 1.5)),
              ]),
            ),
            if (!small && weekReward(x.r) > 0)
              Container(
                margin: const EdgeInsetsDirectional.only(end: 10),
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(color: const Color(0x24FFC846), borderRadius: BorderRadius.circular(99)),
                child: Text('+${weekReward(x.r)}', style: atn(11, c: AC.t3g)),
              ),
            SizedBox(width: 52, child: Text(afmt(x.p), textAlign: TextAlign.end, style: atn(14))),
          ]),
        ),
        if (x.r == 3 && g.length > 3) line(tr('wl_champs'), true),
        if (x.r == 10 && g.length > 10) line(tr('wl_zone'), false),
      ],
      const SizedBox(height: 12),
      _richNum(tr('wl_note'), ats(12, c: AC.mu, h: 1.7), atn(12, w: FontWeight.w600, c: AC.mu, h: 1.7)),
    ]));
  }
}

/// تابلۆی پلەکان (rRank)
class _Board extends StatelessWidget {
  const _Board({required this.s, required this.seg});
  final _VexArenaPageState s;
  final String seg;
  @override
  Widget build(BuildContext context) {
    final c = s.c, pre = !c.live;
    final dv = s.rankDiv ?? c.div;
    final pl = c.divPlayers(dv);
    final a = c.store.acc;
    var l = List.of(pl);
    if (seg == 'age' && a != null) l = l.where((x) => x.age == a.age).toList();
    if (seg == 'guess') l.sort((x, y) => y.gp != x.gp ? y.gp.compareTo(x.gp) : x.r.compareTo(y.r));
    if (pre && seg != 'guess') l.sort((x, y) => x.at.compareTo(y.at));
    final rr = <APlayer, int>{for (var i = 0; i < l.length; i++) l[i]: i + 1};
    final gs = seg == 'guess';
    final pod = !pre && !gs && l.length >= 3 && l[2].p > 0;
    final t3 = pod ? l.take(3).toList() : <APlayer>[];
    final rest = pod ? l.skip(3).toList() : l;
    final vis = rest.take(s.shown).toList();
    final my = c.myTotal, rk = c.rankOf(my);
    final ahead = c.divPlayers().where((x) => !x.me && x.p > my).toList();
    final nx = ahead.isEmpty ? null : ahead.last;
    final gap = nx == null ? 0 : nx.p - my + 1;
    Widget val(APlayer x, {double size = 14}) {
      if (gs) {
        return Row(mainAxisSize: MainAxisSize.min, children: [
          Text('${x.gp} ', style: atn(size)),
          AIcon('crystal', size: 13, color: AC.violet),
        ]);
      }
      if (pre) {
        return x.pre
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(color: const Color(0x24FFC846), borderRadius: BorderRadius.circular(99)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  AIcon('star', size: 10, color: AC.t3g),
                  const SizedBox(width: 3),
                  Text(tr('founder'), style: ats(10.5, w: FontWeight.w800, c: AC.t3g)),
                ]),
              )
            : const SizedBox.shrink();
      }
      return Text(afmt(x.p), style: atn(size));
    }

    Widget pd(APlayer x, double h, Color col, double sz) => Expanded(
          flex: x == t3.first ? 12 : 10,
          child: _Tap(
            onTap: () => x.me ? s.goTab(2) : playerSheet(context, c, x),
            child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
              if (x == t3.first) ...[AIcon('crown', size: 24, color: AC.gold), const SizedBox(height: 3)],
              CharAvatar(ch: x.ch, name: x.n, size: sz - 8, ring: col),
              const SizedBox(height: 8),
              Text(x.me ? tr('you') : nm(x.n), maxLines: 1, overflow: TextOverflow.ellipsis, style: ats(12, w: FontWeight.w700, h: 1.4)),
              Text(nm(x.city), maxLines: 1, style: ats(11, c: AC.mu)),
              const SizedBox(height: 2),
              val(x, size: 13),
              const SizedBox(height: 8),
              Container(
                height: h,
                width: double.infinity,
                decoration: BoxDecoration(color: col, borderRadius: const BorderRadius.vertical(top: Radius.circular(14), bottom: Radius.circular(4))),
                alignment: Alignment.center,
                child: Text('${rr[x]}', style: atn(20, c: const Color(0xFF3A2600))),
              ),
            ]),
          ),
        );

    return _Card(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _Ttl('trophy', pre ? tr('rk_pre_title', [c.S.n]) : tr('rk_title'), small: tr('n_part', [afmt(pl.length)])),
      Row(children: [
        for (final d in Div.values) ...[
          if (d == Div.phone) const SizedBox(width: 6),
          Expanded(
            child: _Tap(
              radius: 14,
              onTap: () => s.upd(() {
                s.rankDiv = d;
                s.shown = 11;
              }),
              child: Stack(clipBehavior: Clip.none, children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                  decoration: BoxDecoration(
                    color: d == dv ? const Color(0x1FFFC846) : AC.surf2,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: d == dv ? const Color(0x8CFFD678) : AC.line),
                  ),
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    AIcon(d == Div.band ? 'shield' : 'phone', size: 14, color: d == dv ? AC.tx : AC.mu),
                    const SizedBox(width: 6),
                    Flexible(child: Text(tr(d == Div.band ? 'dv_band' : 'dv_phone'), maxLines: 1, overflow: TextOverflow.ellipsis, style: ats(13, w: FontWeight.w800, c: d == dv ? AC.tx : AC.mu))),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
                      decoration: BoxDecoration(gradient: d == dv ? AC.goldG : null, color: d == dv ? null : const Color(0x14FFFFFF), borderRadius: BorderRadius.circular(99)),
                      child: Text('${c.divPlayers(d).length}', style: atn(11, c: d == dv ? AC.onGold : AC.mu)),
                    ),
                  ]),
                ),
                if (d == c.div)
                  PositionedDirectional(
                    top: -7,
                    start: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7),
                      decoration: BoxDecoration(gradient: AC.goldG, borderRadius: BorderRadius.circular(99)),
                      child: Text(tr('you'), style: ats(10, w: FontWeight.w800, c: AC.onGold, h: 1.6)),
                    ),
                  ),
              ]),
            ),
          ),
        ],
      ]),
      const SizedBox(height: 10),
      _Segs(s: s, seg: seg, pre: pre),
      if (pre)
        Container(
          margin: const EdgeInsets.only(top: 12),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration: BoxDecoration(color: const Color(0x1A7FD8FF), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0x597FD8FF))),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Padding(padding: EdgeInsets.only(top: 3), child: AIcon('clock', size: 16, color: Color(0xFF7FD8FF))),
            const SizedBox(width: 8),
            Expanded(
              child: _richNum(tr('rk_pre', [math.max(0, c.S.start.difference(DateTime.now()).inDays + 1)]), ats(12.5, h: 1.7), atn(12.5, h: 1.7)),
            ),
          ]),
        )
      else if (a != null && c.regd && dv == c.div)
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: _Tap(
            radius: 20,
            onTap: () => s.goTab(2),
            child: Ink(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: cssLin(135, AC.l ? const [Color(0x24E6A014), Color(0x08E6A014)] : const [Color(0x33FFC846), Color(0x0DFFC846)]),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AC.l ? const Color(0x73C48C14) : const Color(0x8CFFD678)),
              ),
              child: Row(children: [
                CharAvatar(ch: c.store.ch, name: a.name, size: 40, ring: leagueOf(my).color),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text.rich(
                      TextSpan(children: [
                        TextSpan(text: nm(a.name)),
                        TextSpan(text: ' (${tr('you')})', style: ats(13, c: AC.mu)),
                      ]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: ats(14, w: FontWeight.w700, h: 1.6),
                    ),
                    const SizedBox(height: 2),
                    _richNum(rk > 1 && nx != null ? tr('mine_gap', [afmt(gap), '#${afmt(rk - 1)}']) : (pl.length > 1 ? tr('mine_top') : tr('mine_only')),
                        ats(11, c: AC.mu, h: 1.5), atn(11, w: FontWeight.w700, c: AC.mu, h: 1.5)),
                  ]),
                ),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text('#${afmt(rk)}', style: atn(19)),
                  _richNum(tr('n_pts', [afmt(my)]), ats(11, w: FontWeight.w700, c: AC.mu), atn(11, w: FontWeight.w700, c: AC.mu)),
                ]),
              ]),
            ),
          ),
        ),
      if (pod)
        Padding(
          padding: const EdgeInsets.only(top: 20),
          child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            pd(t3[1], 62, AC.silver, 62),
            const SizedBox(width: 8),
            pd(t3[0], 88, AC.gold, 78),
            const SizedBox(width: 8),
            pd(t3[2], 48, AC.bronze, 62),
          ]),
        ),
      for (final x in vis)
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: _Tap(
            radius: 16,
            onTap: () => x.me ? s.goTab(2) : playerSheet(context, c, x),
            child: Ink(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color: x.me ? null : AC.surf2,
                gradient: x.me ? cssLin(135, AC.l ? const [Color(0x24E6A014), Color(0x08E6A014)] : const [Color(0x33FFC846), Color(0x0DFFC846)]) : null,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: x.me ? (AC.l ? const Color(0x73C48C14) : const Color(0x8CFFD678)) : AC.line),
              ),
              child: Row(children: [
                SizedBox(width: 40, child: Text('#${rr[x]}', textAlign: TextAlign.center, style: atn(12, c: AC.mu))),
                const SizedBox(width: 10),
                CharAvatar(ch: x.ch, name: x.n, size: 36, ring: x.me ? AC.cy : (pre ? null : leagueOf(x.p).color)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(nm(x.n) + (x.me ? ' (${tr('you')})' : ''), maxLines: 1, overflow: TextOverflow.ellipsis, style: ats(13, w: FontWeight.w700, h: 1.6)),
                    Row(children: [
                      Flexible(child: Text(nm(x.city), maxLines: 1, overflow: TextOverflow.ellipsis, style: ats(11, c: AC.mu, h: 1.6))),
                      if (!pre) ...[
                        Text(' · ${leagueOf(x.p).name} · ', style: ats(11, c: AC.mu, h: 1.6)),
                        const AIcon('fire', size: 12, color: Color(0xFFFF9466)),
                        const SizedBox(width: 2),
                        Text('${x.st}', style: atn(11, w: FontWeight.w600, c: AC.mu)),
                      ],
                    ]),
                  ]),
                ),
                val(x),
              ]),
            ),
          ),
        ),
      if (rest.length > s.shown)
        Padding(
          padding: const EdgeInsets.only(top: 10),
          child: _Btn(tr('more'), icon: 'chart', kind: 's', onTap: () => s.upd(() => s.shown += 15)),
        ),
      if (l.isEmpty)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 26, horizontal: 10),
          child: Column(children: [
            AIcon('users', size: 30, color: AC.mu),
            const SizedBox(height: 4),
            Text(tr('rk_empty'), style: ats(15, w: FontWeight.w700)),
            Text(tr(seg == 'age' ? 'rk_empty_age' : 'rk_empty_s'), style: ats(12, c: AC.mu)),
          ]),
        ),
    ]));
  }
}
