// VEX Arena — کارتی یاریزان + تابی «کارتەکەم»
part of 'vex_arena.dart';

const List<String> _kStatIds = ['walk', 'run', 'sleep', 'food', 'heart', 'calm'];

/// کارتی یاریزان (.pcard)
class ArenaCardView extends StatefulWidget {
  const ArenaCardView({
    super.key,
    required this.name,
    required this.ch,
    required this.skin,
    required this.pts,
    required this.city,
    required this.title,
    required this.stats,
    this.rank = 0,
    this.season = 1,
    this.founder = false,
    this.width = 236,
  });

  factory ArenaCardView.of(ArenaCtl c, {double width = 236, String? ch, String? skin}) {
    final a = c.store.acc;
    return ArenaCardView(
      name: a?.name ?? '',
      ch: ch ?? c.store.ch,
      skin: skinById(skin ?? c.store.skin),
      pts: c.myTotal,
      city: a?.city ?? '',
      title: tr('ti_${c.store.title}'),
      stats: c.myStats(),
      rank: c.live && c.regd ? c.rankOf(c.myTotal) : 0,
      season: c.S.n,
      founder: c.founder,
      width: width,
    );
  }

  final String name, ch, city, title;
  final CardSkin skin;
  final int pts, rank, season;
  final List<int> stats;
  final bool founder;
  final double width;

  @override
  State<ArenaCardView> createState() => _ArenaCardViewState();
}

class _ArenaCardViewState extends State<ArenaCardView> with SingleTickerProviderStateMixin {
  late final AnimationController a = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat();
  @override
  void dispose() {
    a.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w = widget, k = w.width / 236;
    final lg = leagueOf(w.pts);
    final ac = w.skin.accent(w.pts);
    final white = Colors.white;
    final card = SizedBox(
      width: 236,
      height: 330,
      child: Stack(clipBehavior: Clip.hardEdge, children: [
        Positioned.fill(
          child: Image.asset(w.skin.asset(w.pts), fit: BoxFit.fill, gaplessPlayback: true, filterQuality: FilterQuality.medium,
              errorBuilder: (_, __, ___) => DecoratedBox(decoration: BoxDecoration(gradient: cssLin(165, [lg.c1, lg.c2])))),
        ),
        // درەوشانەوە (sheen)
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedBuilder(
              animation: a,
              builder: (_, __) {
                final t = (a.value / .38).clamp(0.0, 1.0);
                return Transform.translate(
                  offset: Offset(-236 * .7 + t * 236 * 2.3, 0),
                  child: Transform(
                    transform: Matrix4.skewX(-.24),
                    child: Container(
                      width: 236 * .55,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(colors: [Color(0x00FFFFFF), Color(0x57FFFFFF), Color(0x00FFFFFF)]),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 22, 16, 0),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              SizedBox(
                width: 56,
                child: Column(children: [
                  Text('${ratingOf(w.pts)}',
                      style: atn(40, c: white, h: 1).copyWith(shadows: const [Shadow(color: Color(0x59000000), blurRadius: 10, offset: Offset(0, 2))])),
                  const SizedBox(height: 5),
                  Text('VEX', style: atn(10, w: FontWeight.w500, c: white.withAlpha(217), h: 1, ls: .8)),
                  const SizedBox(height: 5),
                  Emblem(lg.idx, size: 32),
                  const SizedBox(height: 5),
                  Row(mainAxisSize: MainAxisSize.min, children: [
                    AIcon('pin', size: 11, color: white.withAlpha(230)),
                    const SizedBox(width: 3),
                    Flexible(
                        child: Text(nm(w.city), maxLines: 1, overflow: TextOverflow.ellipsis, style: ats(10, c: white.withAlpha(230), h: 1))),
                  ]),
                ]),
              ),
              const Spacer(),
              Transform.translate(
                offset: const Offset(0, -4),
                child: Stack(clipBehavior: Clip.none, children: [
                  Container(
                    decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: [
                      BoxShadow(color: ac, spreadRadius: 3),
                      cssSh(0, 12, 26, -10, const Color(0xB3000000)),
                    ]),
                    child: CharAvatar(ch: w.ch, name: w.name, size: 126),
                  ),
                  if (w.founder)
                    PositionedDirectional(
                      bottom: 2,
                      end: 2,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: cssLin(160, const [Color(0xFFFFF1B8), Color(0xFFF2B21C), Color(0xFFC98A08)], const [0, .6, 1]),
                          boxShadow: const [BoxShadow(color: Color(0x40000000), spreadRadius: 3), BoxShadow(color: Color(0x73000000), blurRadius: 12, offset: Offset(0, 6))],
                        ),
                        alignment: Alignment.center,
                        child: const AIcon('star', size: 15, color: Color(0xFF3A2600), sw: 2.2),
                      ),
                    ),
                ]),
              ),
            ]),
          ),
          Container(
            margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            padding: const EdgeInsets.only(bottom: 6),
            decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0x38FFFFFF)))),
            width: double.infinity,
            child: Text(nm(w.name), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis, style: ats(18, w: FontWeight.w800, c: white, h: 1.4)),
          ),
          const SizedBox(height: 5),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(w.title, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis, style: ats(11, c: white.withAlpha(224))),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
            child: Column(children: [
              for (var r = 0; r < 2; r++)
                Padding(
                  padding: EdgeInsets.only(top: r == 0 ? 0 : 4),
                  child: Row(children: [
                    for (var i = r * 3; i < r * 3 + 3; i++) ...[
                      if (i % 3 > 0) const SizedBox(width: 6),
                      Expanded(
                        child: Row(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
                          Text(i < w.stats.length ? '${w.stats[i]}' : '–', style: atn(15, w: FontWeight.w700, c: white)),
                          const SizedBox(width: 4),
                          Flexible(child: Text(catById(_kStatIds[i]).name, maxLines: 1, overflow: TextOverflow.clip, style: ats(10, c: white))),
                        ]),
                      ),
                    ],
                  ]),
                ),
            ]),
          ),
        ]),
        Positioned(
          left: 0,
          right: 0,
          bottom: 10,
          child: Text(
            'VEX ARENA · SEASON ${w.season} · ${w.rank > 0 ? '#${afmt(w.rank)}' : tr('registered')}',
            textAlign: TextAlign.center,
            textDirection: TextDirection.ltr,
            style: atn(9, w: FontWeight.w500, c: white.withAlpha(199), ls: 1.08),
          ),
        ),
      ]),
    );
    return Container(
      width: 236 * k,
      height: 330 * k,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30 * k), bottom: Radius.circular(26 * k)),
        boxShadow: [cssSh(0, 18 * k, 34 * k, -18 * k, ac)],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30 * k), bottom: Radius.circular(26 * k)),
        child: FittedBox(child: card),
      ),
    );
  }
}

class _CardTab extends StatelessWidget {
  const _CardTab({required this.s});
  final _VexArenaPageState s;

  @override
  Widget build(BuildContext context) {
    final c = s.c, st = c.store, a = st.acc!;
    final t = c.myTotal, lv = levelOf(t), xs = lvlStart(lv), xe = lvlStart(lv + 1);
    final cs = c.charState();
    final filled = ((t - xs) / math.max(1, xe - xs) * 20).round();
    final owned = kSkins.where(c.skinOwned).length;
    final B = c.badges();
    return _TabFrame(s: s, id: 'card', children: [
      if (!c.live) _PreBar(c: c),
      _Card(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const SizedBox(height: 6),
        Center(child: ArenaCardView.of(c)),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(
            child: _Btn(
              st.ch.isEmpty ? tr('cp_pick') : (cs == 'ok' ? tr('cp_change') : tr('cp_chars')),
              icon: 'face',
              h: 53,
              onTap: () => charSheet(context, c),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(width: 48, child: _Btn('', icon: 'share', kind: 's', h: 53, onTap: () => shareSheet(context, c))),
          const SizedBox(width: 8),
          SizedBox(width: 48, child: _Btn('', icon: 'edit', kind: 's', h: 53, onTap: () => editSheet(context, c))),
        ]),
        if (st.ch.isNotEmpty) ...[
          const SizedBox(height: 10),
          _IconLine(cs == 'ok' || cs == 'first' ? 'check' : 'lock',
              cs == 'ok' ? tr('cl_ok') : cs == 'live' ? tr('cl_live') : tr('cl_wait', [c.charDaysLeft]),
              size: 12, iconColor: cs == 'ok' ? AC.mint : AC.mu),
        ],
        const SizedBox(height: 14),
        Row(children: [
          Expanded(child: _richNum(tr('lvl_xp', [lv]), ats(11, w: FontWeight.w700, c: AC.mu), atn(11, w: FontWeight.w800, c: AC.mu))),
          Text('${afmt(t)} / ${afmt(xe)}', textDirection: TextDirection.ltr, style: atn(11, w: FontWeight.w700, c: AC.mu)),
        ]),
        const SizedBox(height: 6),
        Row(children: [
          for (var i = 0; i < 20; i++) ...[
            if (i > 0) const SizedBox(width: 4),
            Expanded(
              child: Container(
                height: 8,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  color: i < filled ? null : AC.track,
                  gradient: i < filled ? const LinearGradient(colors: [Color(0xFFFFE08A), Color(0xFFF2B21C)]) : null,
                  boxShadow: i < filled ? const [BoxShadow(color: Color(0x73FFC846), blurRadius: 8)] : null,
                ),
              ),
            ),
          ],
        ]),
      ])),

      // دیزاینی کارت
      _Card(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        _Ttl('star', tr('sk_t'), smallW: _richNum(tr('sk_own', ['$owned/${kSkins.length}']), ats(11.5, w: FontWeight.w600, c: AC.mu), atn(11.5, c: AC.mu))),
        _Tap(
          radius: 16,
          onTap: () => coinSheet(context, c),
          child: Ink(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0x24FFC846), Color(0x08FFC846)]),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0x59FFD678)),
            ),
            child: Row(children: [
              const _Coin(16),
              const SizedBox(width: 8),
              Text(afmt(st.coins), style: atn(16, c: AC.tx)),
              const SizedBox(width: 4),
              Text(tr('coin_u'), style: ats(13, w: FontWeight.w700)),
              const Spacer(),
              Text(tr('how_coins'), style: ats(12, c: AC.mu)),
              const SizedBox(width: 6),
              AIcon('down', size: 15, color: AC.mu).rot(arenaLtr ? -90 : 90),
            ]),
          ),
        ),
        const SizedBox(height: 12),
        LayoutBuilder(builder: (_, bc) {
          final w = (bc.maxWidth - 16) / 3;
          return Wrap(spacing: 8, runSpacing: 8, children: [for (final k in kSkins) SizedBox(width: w, child: _SkinTile(c: c, s: k))]);
        }),
        const SizedBox(height: 10),
        Text(tr('sk_note'), style: ats(12, c: AC.mu, h: 1.7)),
      ])),

      // نازناو
      _Card(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        _Ttl('flag', tr('ti_head'), small: tr('ti_s')),
        Wrap(spacing: 6, runSpacing: 6, children: [
          for (final x in kTitles)
            () {
              final id = x[0] as String;
              final ok = c.titleOk(id), on = st.title == id;
              return Opacity(
                opacity: ok ? 1 : .55,
                child: _Tap(
                  radius: 99,
                  onTap: () => ok ? c.setTitle(id) : arenaToast(context, tr('ti_locked'), 'lock'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: on ? (AC.l ? const Color(0x1FE6A014) : const Color(0x24FFC846)) : AC.surf2,
                      borderRadius: BorderRadius.circular(99),
                      border: Border.all(color: on ? (AC.l ? const Color(0x73C48C14) : const Color(0x80FFD678)) : AC.line),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      AIcon(ok ? x[2] as String : 'lock', size: 14, color: on ? (AC.l ? const Color(0xFF8A5A00) : AC.goldS) : AC.tx),
                      const SizedBox(width: 6),
                      Text(tr('ti_$id'), style: ats(12, w: FontWeight.w700, c: on ? (AC.l ? const Color(0xFF8A5A00) : AC.goldS) : AC.tx)),
                    ]),
                  ),
                ),
              );
            }(),
        ]),
      ])),

      // مێدالیاکان
      _Card(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        _Ttl('trophy', tr('bd_t'), smallW: Text('${B.where((b) => b[2] == true).length}/${B.length}', textDirection: TextDirection.ltr, style: atn(11.5, c: AC.mu))),
        LayoutBuilder(builder: (_, bc) {
          final w = (bc.maxWidth - 24) / 4;
          return Wrap(spacing: 8, runSpacing: 8, children: [
            for (final b in B)
              SizedBox(
                width: w,
                child: Opacity(
                  opacity: b[2] == true ? 1 : .4,
                  child: ColorFiltered(
                    colorFilter: b[2] == true
                        ? const ColorFilter.mode(Colors.transparent, BlendMode.dst)
                        : const ColorFilter.matrix([.2126, .7152, .0722, 0, 0, .2126, .7152, .0722, 0, 0, .2126, .7152, .0722, 0, 0, 0, 0, 0, 1, 0]),
                    child: Container(
                      constraints: const BoxConstraints(minHeight: 82),
                      padding: const EdgeInsets.fromLTRB(2, 11, 2, 9),
                      decoration: BoxDecoration(color: AC.surf2, borderRadius: BorderRadius.circular(16), border: Border.all(color: AC.line)),
                      child: Column(children: [
                        CatTile(b[0] as String, b[3] as Color, size: 40),
                        const SizedBox(height: 6),
                        Text(tr(b[1] as String), textAlign: TextAlign.center, style: ats(10, w: FontWeight.w700, h: 1.4)),
                      ]),
                    ),
                  ),
                ),
              ),
          ]);
        }),
      ])),

      // تایبەتمەندی
      _Card(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        _Ttl('eye', tr('pv_t'), small: tr('pv_s')),
        _IconLine('eye', tr('pv_y'), size: 13, color: AC.tx, iconColor: AC.mint, gap: 9),
        const SizedBox(height: 10),
        _IconLine('eyeoff', tr('pv_n'), size: 13, color: AC.tx, iconColor: AC.coral, gap: 9),
      ])),

      // ئەکاونت
      _Card(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        _Ttl('face', tr('acc_t')),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          CharAvatar(ch: st.ch, name: a.name, size: 42, ring: leagueOf(t).color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(nm(a.name), style: ats(14, w: FontWeight.w700, h: 1.6)),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(maskPhone(a.phone), textDirection: TextDirection.ltr, style: atn(12, w: FontWeight.w500, c: AC.mu)),
              ),
              const SizedBox(height: 4),
              Row(children: [
                AIcon('pin', size: 11, color: AC.mu),
                const SizedBox(width: 4),
                Text(nm(a.city), style: ats(12, c: AC.mu)),
              ]),
            ]),
          ),
        ]),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(color: const Color(0x143CF08A), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0x4D3CF08A))),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Padding(padding: const EdgeInsets.only(top: 2), child: AIcon('phone', size: 16, color: AC.mint)),
            const SizedBox(width: 8),
            Expanded(child: _richNum(tr('acc_win'), ats(12, h: 1.65), atn(12, w: FontWeight.w800, h: 1.65))),
          ]),
        ),
        const SizedBox(height: 14),
        _Btn(tr('logout'), icon: 'logout', kind: 'd', h: 55, onTap: () => logoutSheet(context, c)),
      ])),
    ]);
  }
}

/// خانەی دیزاینی کارت (.skc)
class _SkinTile extends StatelessWidget {
  const _SkinTile({required this.c, required this.s});
  final ArenaCtl c;
  final CardSkin s;
  @override
  Widget build(BuildContext context) {
    final t = c.myTotal;
    final ok = c.skinOwned(s), on = c.store.skin == s.id;
    final rc = skinRarColor(s.rar);
    Widget foot;
    if (on) {
      foot = Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        const AIcon('check', size: 12, color: AC.accent),
        const SizedBox(width: 4),
        Flexible(child: Text(tr('in_use'), maxLines: 1, overflow: TextOverflow.ellipsis, style: ats(11, w: FontWeight.w800, c: AC.accent))),
      ]);
    } else if (ok) {
      foot = Text(tr('owned'), style: ats(11, w: FontWeight.w800, c: AC.mint));
    } else if (s.lg > 0) {
      foot = Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        AIcon('lock', size: 11, color: AC.mu),
        const SizedBox(width: 4),
        Flexible(child: Text(kLeagues[s.lg].name, maxLines: 1, overflow: TextOverflow.ellipsis, style: ats(11, w: FontWeight.w800, c: AC.mu))),
      ]);
    } else {
      foot = Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        const _Coin(16),
        const SizedBox(width: 4),
        Text('${s.cost}', style: atn(11, w: FontWeight.w800, c: AC.mu)),
      ]);
    }
    return _Tap(
      radius: 18,
      onTap: () => skinSheet(context, c, s),
      child: Container(
        padding: const EdgeInsets.fromLTRB(6, 6, 6, 8),
        decoration: BoxDecoration(
          color: AC.surf2,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: on ? AC.accent : AC.line),
          boxShadow: on ? const [BoxShadow(color: Color(0x2EF2B21C), spreadRadius: 3), BoxShadow(color: Color(0xCCF2B21C), offset: Offset(0, 10), blurRadius: 20, spreadRadius: -12)] : null,
        ),
        child: Column(children: [
          AspectRatio(
            aspectRatio: 92 / 123,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(fit: StackFit.expand, children: [
                Image.asset(s.asset(t), fit: BoxFit.fill, gaplessPlayback: true),
                Padding(
                  padding: const EdgeInsets.all(6),
                  child: Column(children: [
                    Row(children: [
                      if (!ok)
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(color: const Color(0x73000000), borderRadius: BorderRadius.circular(7)),
                          alignment: Alignment.center,
                          child: const AIcon('lock', size: 11, color: Colors.white),
                        ),
                      const Spacer(),
                      Text('${ratingOf(t)}', style: atn(13, c: Colors.white)),
                    ]),
                    const Spacer(),
                    Container(
                      width: 31,
                      height: 31,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0x33FFFFFF),
                        border: Border.all(color: s.accent(t), width: 1.5),
                      ),
                    ),
                    const Spacer(),
                    Container(width: 52, height: 4, decoration: BoxDecoration(color: const Color(0x8CFFFFFF), borderRadius: BorderRadius.circular(3))),
                    const SizedBox(height: 4),
                    Container(width: 33, height: 3, decoration: BoxDecoration(color: const Color(0x59FFFFFF), borderRadius: BorderRadius.circular(3))),
                    const SizedBox(height: 8),
                  ]),
                ),
              ]),
            ),
          ),
          const SizedBox(height: 5),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
            decoration: BoxDecoration(color: _a(rc, .14), borderRadius: BorderRadius.circular(99)),
            child: Text(tr('rar_${s.rar}'), style: ats(10, w: FontWeight.w800, c: rc)),
          ),
          const SizedBox(height: 5),
          Text(s.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: ats(12.5, w: FontWeight.w800)),
          const SizedBox(height: 5),
          foot,
        ]),
      ),
    );
  }
}
