// VEX Arena — پەڕە، ستەیج، سەرپەڕە، سپۆنسەر، تابەکان، جام، دەروازەی تۆمارکردن
part of 'vex_arena.dart';

// =============================================================================
// پەڕەی سەرەکی
// =============================================================================

class VexArenaPage extends StatefulWidget {
  const VexArenaPage({super.key, required this.host, this.store, this.sponsor});
  final ArenaHost host;
  final ArenaStore? store;

  /// سپۆنسەری وەرز. null = شوێنەکە بەتاڵە و ئامادەیە بۆ سپۆنسەر
  final Widget? sponsor;

  @override
  State<VexArenaPage> createState() => _VexArenaPageState();
}

class _VexArenaPageState extends State<VexArenaPage> with WidgetsBindingObserver {
  late final ArenaStore store = widget.store ?? ArenaStore();
  late final ArenaCtl c = ArenaCtl(widget.host, store);
  final ValueNotifier<DateTime> clock = ValueNotifier<DateTime>(DateTime.now());
  Timer? _tick, _poll, _deb;
  bool ready = false;
  int tab = 0;
  Div? rankDiv;
  String seg = 'week';
  Div? przDiv;
  int shown = 11;
  bool toMe = false;

  @override
  void initState() {
    super.initState();
    arenaDebugCtl = c;
    WidgetsBinding.instance.addObserver(this);
    _init();
  }

  Future<void> _init() async {
    if (!store.loaded) await store.load();
    c.events.clear();
    c.refresh();
    c.events.clear();
    if (!mounted) return;
    setState(() => ready = true);
    c.addListener(_onCtl);
    widget.host.changes?.addListener(_onData);
    VexTheme.I.addListener(_re);
    LangState.I.addListener(_re);
    _tick = Timer.periodic(const Duration(seconds: 1), (_) => clock.value = DateTime.now());
    _poll = Timer.periodic(const Duration(seconds: 20), (_) => c.refresh());
  }

  void _re() {
    if (mounted) setState(() {});
  }

  void _onData() {
    _deb?.cancel();
    _deb = Timer(const Duration(milliseconds: 250), () {
      if (mounted) c.refresh();
    });
  }

  void _onCtl() {
    if (!mounted) return;
    setState(() {});
    if (c.events.isEmpty) return;
    final ev = List<ArenaEvent>.from(c.events);
    c.events.clear();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      var shownT = false;
      for (final e in ev) {
        if (e.icon == 'coin') continue;
        if (!shownT) {
          arenaToast(context, e.text, e.icon);
          shownT = true;
        }
        if (e.confetti) arenaConfetti(context);
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState s) {
    if (s == AppLifecycleState.resumed && ready) c.refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    c.removeListener(_onCtl);
    widget.host.changes?.removeListener(_onData);
    VexTheme.I.removeListener(_re);
    LangState.I.removeListener(_re);
    _tick?.cancel();
    _poll?.cancel();
    _deb?.cancel();
    clock.dispose();
    super.dispose();
  }

  void goTab(int t) {
    if (t == tab) return;
    HapticFeedback.selectionClick();
    setState(() => tab = t);
  }

  void upd(VoidCallback f) {
    if (mounted) setState(f);
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: arenaDir,
      child: Scaffold(
        backgroundColor: AC.bg,
        resizeToAvoidBottomInset: false,
        body: DefaultTextStyle(
          style: ats(14),
          child: Stack(children: [
            const Positioned.fill(child: _Aurora()),
            if (!ready)
              Center(child: CircularProgressIndicator(color: AC.t3g))
            else if (!c.regd)
              _Gate(c: c, onDone: _afterReg)
            else
              IndexedStack(index: tab, children: [
                for (var i = 0; i < 3; i++)
                  TickerMode(
                    enabled: i == tab,
                    child: [_TodayTab(s: this), _RankTab(s: this), _CardTab(s: this)][i],
                  ),
              ]),
          ]),
        ),
      ),
    );
  }

  void _afterReg() {
    setState(() => tab = 2);
    showArenaReveal(context, c);
  }

  Widget sponsorSlot() => widget.sponsor ?? _Sponsor(n: c.S.n);
}

/// پاشبنەمای پەڕە (.aur)
class _Aurora extends StatelessWidget {
  const _Aurora();
  @override
  Widget build(BuildContext context) => CustomPaint(painter: _AuroraPainter(AC.bg));
}

class _AuroraPainter extends CustomPainter {
  _AuroraPainter(this.bg);
  final Color bg;
  @override
  void paint(Canvas c, Size s) {
    final r = Offset.zero & s;
    c.drawRect(r, Paint()..color = bg);
    _ellipse(c, r, Offset(s.width * .5, -s.height * .08), s.width * .7, s.height * .38, const [Color(0x24FFC850), Color(0x00FFC850)], const [0, .7]);
    _ellipse(c, r, Offset(s.width * .5, s.height * 1.15), s.width * .7, s.height * .45, const [Color(0x1A5A6EFF), Color(0x005A6EFF)], const [0, .7]);
  }

  @override
  bool shouldRepaint(_AuroraPainter o) => o.bg != bg;
}

/// radial-gradient(rx ry at cx cy, ...)
void _ellipse(Canvas c, Rect r, Offset ctr, double rx, double ry, List<Color> cols, List<double> stops) {
  if (rx <= 0 || ry <= 0) return;
  final m = Matrix4.identity()
    ..translateByDouble(ctr.dx, ctr.dy, 0, 1)
    ..scaleByDouble(rx, ry, 1, 1);
  c.drawRect(r, Paint()..shader = ui.Gradient.radial(Offset.zero, 1, cols, stops, TileMode.clamp, m.storage));
}

// =============================================================================
// ستەیجی یاریگا (#t3bg)
// =============================================================================

class _Stage extends StatefulWidget {
  const _Stage({required this.h});
  final double h;
  @override
  State<_Stage> createState() => _StageState();
}

class _StageState extends State<_Stage> with SingleTickerProviderStateMixin {
  late final AnimationController a = AnimationController(vsync: this, duration: const Duration(seconds: 5))..repeat();
  @override
  void dispose() {
    a.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final light = AC.l;
    final h = widget.h;
    Widget beam(bool right) => AnimatedBuilder(
          animation: a,
          builder: (_, __) {
            final t = (a.value + (right ? 0 : .5)) % 1;
            final o = .5 + .45 * (.5 - .5 * math.cos(t * 2 * math.pi));
            return Opacity(opacity: o, child: _beamBox(h));
          },
        );
    final body = SizedBox(
      height: h,
      child: Stack(clipBehavior: Clip.hardEdge, children: [
        Positioned.fill(child: CustomPaint(painter: _StagePainter())),
        // زەوی یاریگا
        Positioned(
          left: -70,
          right: -70,
          bottom: -30,
          height: 230,
          child: Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 1 / 260)
              ..rotateX(58 * math.pi / 180),
            child: CustomPaint(painter: _FieldPainter()),
          ),
        ),
        // تیشکی ڕووناکی
        Positioned(
          top: -30,
          right: -26,
          child: Transform.rotate(angle: 30 * math.pi / 180, alignment: Alignment.topCenter, child: beam(true)),
        ),
        Positioned(
          top: -30,
          left: -26,
          child: Transform.rotate(angle: -30 * math.pi / 180, alignment: Alignment.topCenter, child: beam(false)),
        ),
        // چراکان
        Positioned(top: MediaQuery.of(context).padding.top + 2, right: 20, child: const _Lamp()),
        Positioned(top: MediaQuery.of(context).padding.top + 2, left: 20, child: const _Lamp()),
        if (!light)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 150,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                    begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [const Color(0x0004202A), AC.bg]),
              ),
            ),
          ),
      ]),
    );
    if (!light) return body;
    return Container(
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(34)),
        boxShadow: [BoxShadow(color: Color(0x99081028), offset: Offset(0, 18), blurRadius: 34, spreadRadius: -22)],
      ),
      child: ClipRRect(borderRadius: const BorderRadius.vertical(bottom: Radius.circular(34)), child: body),
    );
  }

  Widget _beamBox(double h) => ImageFiltered(
        imageFilter: ui.ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          width: 150,
          height: h * 1.1,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0x6BFFF4D6), Color(0x00FFF4D6)],
              stops: [0, .72],
            ),
          ),
        ),
      );
}

class _StagePainter extends CustomPainter {
  @override
  void paint(Canvas c, Size s) {
    final r = Offset.zero & s;
    _ellipse(c, r, Offset(s.width * .5, 0), s.width * 1.3, s.height * .6,
        const [Color(0xFF16306A), Color(0xFF0B1636), Color(0xFF070D22)], const [0, .46, 1]);
    _ellipse(c, r, Offset(s.width * .5, s.height * .36), s.width * .9, s.height * .46, const [Color(0x38FFC450), Color(0x00FFC450)], const [0, .62]);
  }

  @override
  bool shouldRepaint(_StagePainter o) => false;
}

class _FieldPainter extends CustomPainter {
  @override
  void paint(Canvas c, Size s) {
    final r = Offset.zero & s;
    c.drawRect(
        r,
        Paint()
          ..shader = const LinearGradient(
                  begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0x00148C50), Color(0x52148C50)])
              .createShader(r));
    final v = Paint()..color = const Color(0x1A78FFBE);
    for (double x = 0; x < s.width; x += 46) {
      c.drawRect(Rect.fromLTWH(x, 0, 2, s.height), v);
    }
    final hz = Paint()..color = const Color(0x1478FFBE);
    for (double y = s.height; y > 0; y -= 40) {
      c.drawRect(Rect.fromLTWH(0, y - 2, s.width, 2), hz);
    }
  }

  @override
  bool shouldRepaint(_FieldPainter o) => false;
}

class _Lamp extends StatelessWidget {
  const _Lamp();
  @override
  Widget build(BuildContext context) => Container(
        width: 56,
        height: 12,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(5),
          boxShadow: const [BoxShadow(color: Color(0x80FFECBE), blurRadius: 22, spreadRadius: 8)],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(5),
          child: Row(children: [
            for (var i = 0; i < 5; i++) ...[
              Container(width: 8, color: const Color(0xFFFFF7DC)),
              if (i < 4) Container(width: 3, color: const Color(0x2EFFFFFF)),
            ],
            Expanded(child: Container(color: const Color(0xFFFFF7DC))),
          ]),
        ),
      );
}

// =============================================================================
// سەرپەڕە، سپۆنسەر، تابەکان
// =============================================================================

class _Header extends StatelessWidget {
  const _Header({required this.s});
  final _VexArenaPageState s;
  @override
  Widget build(BuildContext context) {
    final c = s.c, S = c.S;
    final t = S.end.difference(DateTime.now());
    final sub = S.live
        ? tr('hdr_live', [S.n, math.max(0, t.inDays)])
        : tr('hdr_pre', [S.n, math.max(0, S.start.difference(DateTime.now()).inDays + 1)]);
    final canPop = Navigator.of(context).canPop();
    BoxDecoration dec(Color b) => BoxDecoration(
          color: const Color(0x8C080E22),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: b),
        );
    return SizedBox(
      height: 46,
      child: Row(children: [
        if (canPop) ...[
          _Tap(
            radius: 14,
            onTap: () => Navigator.of(context).maybePop(),
            child: Container(
              width: 44,
              height: 44,
              decoration: dec(const Color(0x24FFFFFF)),
              alignment: Alignment.center,
              child: AIcon('down', size: 20, color: const Color(0xFFE6ECFF)).rot(arenaLtr ? 90 : -90),
            ),
          ),
          const SizedBox(width: 10),
        ],
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(tr('arena'), maxLines: 1, style: ats(22, w: FontWeight.w800, c: Colors.white, h: 1.25)),
            const SizedBox(height: 2),
            Text(sub, maxLines: 1, overflow: TextOverflow.ellipsis, style: ats(12.5, w: FontWeight.w600, c: AC.stageMu, h: 1.25)),
          ]),
        ),
        const SizedBox(width: 10),
        _Tap(
          radius: 14,
          onTap: () => coinSheet(context, c),
          child: Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: dec(const Color(0x52FFD678)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const _Coin(19),
              const SizedBox(width: 6),
              Text(afmt(c.store.coins), style: atn(13, w: FontWeight.w900, c: const Color(0xFFFFE39A))),
            ]),
          ),
        ),
        const SizedBox(width: 10),
        _Tap(
          radius: 14,
          onTap: () => rulesSheet(context, c),
          child: Container(
            width: 44,
            height: 44,
            decoration: dec(const Color(0x24FFFFFF)),
            alignment: Alignment.center,
            child: const AIcon('help', size: 20, color: Color(0xFFE6ECFF)),
          ),
        ),
      ]),
    );
  }
}

extension _Rot on Widget {
  Widget rot(double deg) => Transform.rotate(angle: deg * math.pi / 180, child: this);
}

/// شوێنی سپۆنسەری وەرز — بەتاڵ و ئامادە (هەمان دیزاینی وێب)
class _Sponsor extends StatefulWidget {
  const _Sponsor({required this.n});
  final int n;
  @override
  State<_Sponsor> createState() => _SponsorState();
}

class _SponsorState extends State<_Sponsor> with SingleTickerProviderStateMixin {
  late final AnimationController a = AnimationController(vsync: this, duration: const Duration(seconds: 22))..repeat();
  @override
  void dispose() {
    a.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: a,
        builder: (_, __) => Container(
          constraints: const BoxConstraints(minHeight: 72),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: SweepGradient(
              transform: GradientRotation(a.value * 2 * math.pi * 3),
              colors: const [
                Color(0x26FFD678), Color(0xFFFFD36B), Color(0xFFFF6A3D), Color(0x26FFD678), Color(0x26FFD678),
                Color(0xFFFFD36B), Color(0x26FFD678), Color(0x26FFD678),
              ],
              stops: const [0, .12, .2, .32, .62, .74, .86, 1],
            ),
            boxShadow: [cssSh(0, 14, 32, -18, const Color(0xBFE2392D))],
          ),
          padding: const EdgeInsets.all(1.5),
          child: Container(
            constraints: const BoxConstraints(minHeight: 69),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20.5),
              gradient: cssLin(100, const [Color(0xFF2A0D10), Color(0xFF120A1C), Color(0xFF0B1026)], const [0, .55, 1]),
            ),
            child: Stack(children: [
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20.5),
                  child: CustomPaint(painter: _SpnGlow(arenaLtr)),
                ),
              ),
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(10, 4, 14, 4),
                child: Row(children: [
                  SizedBox(
                    width: 64,
                    height: 64,
                    child: Stack(alignment: Alignment.center, children: [
                      Transform.rotate(
                        angle: a.value * 2 * math.pi,
                        child: CustomPaint(size: const Size(64, 64), painter: _RingText('OFFICIAL SPONSOR • SEASON ${widget.n} •')),
                      ),
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0x99FFD36B), width: 1.5),
                          color: const Color(0x14FFD36B),
                        ),
                        alignment: Alignment.center,
                        child: const AIcon('star', size: 16, color: Color(0xFFFFD36B)),
                      ),
                    ]),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                      Text(tr('sp_small', [widget.n]), style: ats(11.5, w: FontWeight.w700, c: const Color(0xFFF6D9A6))),
                      Text(tr('sp_big'), maxLines: 1, overflow: TextOverflow.ellipsis, style: ats(19, w: FontWeight.w800, c: Colors.white, h: 1.3)),
                    ]),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                    decoration: BoxDecoration(
                        color: const Color(0x1FFFD36B),
                        borderRadius: BorderRadius.circular(99),
                        border: Border.all(color: const Color(0x59FFD36B))),
                    child: Text(tr('sp_free'), style: ats(11, w: FontWeight.w800, c: const Color(0xFFFFD36B))),
                  ),
                ]),
              ),
            ]),
          ),
        ),
      );
}

class _SpnGlow extends CustomPainter {
  _SpnGlow(this.ltr);
  final bool ltr;
  @override
  void paint(Canvas c, Size s) {
    final r = Offset.zero & s;
    _ellipse(c, r, Offset(s.width * (ltr ? .12 : .88), s.height * .5), s.width * .7, s.height * 1.4,
        const [Color(0x73E2392D), Color(0x00E2392D)], const [0, .62]);
    final dot = Paint()..color = const Color(0x29FFD36B);
    for (double x = 4; x < s.width; x += 12) {
      for (double y = 4; y < s.height; y += 12) {
        c.drawCircle(Offset(x, y), .8, dot);
      }
    }
  }

  @override
  bool shouldRepaint(_SpnGlow o) => o.ltr != ltr;
}

/// نووسین بە دەوری بازنەدا (OFFICIAL SPONSOR • SEASON 1 •)
class _RingText extends CustomPainter {
  _RingText(this.text);
  final String text;
  @override
  void paint(Canvas c, Size s) {
    final ctr = s.center(Offset.zero);
    const r = 26.2;
    final total = 2 * math.pi;
    final step = total / text.length;
    for (var i = 0; i < text.length; i++) {
      final tp = TextPainter(
        text: TextSpan(text: text[i], style: atn(6.2, w: FontWeight.w800, c: const Color(0xFFFFD36B))),
        textDirection: TextDirection.ltr,
      )..layout();
      final ang = -math.pi + i * step;
      c.save();
      c.translate(ctr.dx + r * math.cos(ang), ctr.dy + r * math.sin(ang));
      c.rotate(ang + math.pi / 2);
      tp.paint(c, Offset(-tp.width / 2, -tp.height / 2));
      c.restore();
    }
  }

  @override
  bool shouldRepaint(_RingText o) => o.text != text;
}

class _TabsBar extends StatelessWidget {
  const _TabsBar({required this.s});
  final _VexArenaPageState s;
  @override
  Widget build(BuildContext context) {
    final names = [tr('tab_today'), tr('tab_rank'), tr('tab_card')];
    return Container(
      height: 52,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AC.solid,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AC.line),
        boxShadow: [cssSh(0, 8, 18, -12, const Color(0x99000000))],
      ),
      child: LayoutBuilder(builder: (ctx, bc) {
        final w = (bc.maxWidth - 8) / 3;
        return Stack(children: [
          AnimatedPositionedDirectional(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            start: (w + 4) * s.tab,
            top: 0,
            bottom: 0,
            width: w,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: AC.tabG,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [cssSh(0, 6, 18, -6, const Color(0xB3F2B21C))],
              ),
            ),
          ),
          Row(children: [
            for (var i = 0; i < 3; i++) ...[
              if (i > 0) const SizedBox(width: 4),
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => s.goTab(i),
                  child: Center(
                    child: AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 200),
                      style: ats(14.5, w: i == s.tab ? FontWeight.w800 : FontWeight.w700, c: i == s.tab ? AC.onGold : AC.mu),
                      child: Text(names[i], maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                  ),
                ),
              ),
            ],
          ]),
        ]);
      }),
    );
  }
}

/// چوارچێوەی هەر تابێک: ستەیج + سەرپەڕە + سپۆنسەر + تابەکان (لکاو لە سەرەوە)
class _TabFrame extends StatefulWidget {
  const _TabFrame({required this.s, required this.id, required this.children, this.hero, this.tall = false});
  final _VexArenaPageState s;
  final String id;
  final Widget? hero;
  final bool tall;
  final List<Widget> children;
  @override
  State<_TabFrame> createState() => _TabFrameState();
}

class _TabFrameState extends State<_TabFrame> {
  final ScrollController sc = ScrollController();
  final GlobalKey tabsK = GlobalKey(), heroK = GlobalKey();
  double tabsY = 166, heroB = 787;

  @override
  void dispose() {
    sc.dispose();
    super.dispose();
  }

  void _measure() {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.attached) return;
    double? yOf(GlobalKey k, bool bottom) {
      final r = k.currentContext?.findRenderObject() as RenderBox?;
      if (r == null || !r.attached) return null;
      final p = r.localToGlobal(Offset(0, bottom ? r.size.height : 0), ancestor: box);
      return p.dy + (sc.hasClients ? sc.offset : 0);
    }

    final ty = yOf(tabsK, false), hb = yOf(heroK, true);
    if ((ty != null && (ty - tabsY).abs() > .5) || (hb != null && (hb - heroB).abs() > .5)) {
      setState(() {
        tabsY = ty ?? tabsY;
        heroB = hb ?? heroB;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _measure();
    });
    final s = widget.s;
    final top = MediaQuery.of(context).padding.top;
    final bottom = MediaQuery.of(context).padding.bottom;
    final stageH = widget.tall && widget.hero != null ? heroB + 34 : tabsY + 25;
    return Stack(children: [
      AnimatedBuilder(
        animation: sc,
        builder: (_, child) => Positioned(
          top: -(sc.hasClients ? sc.offset : 0.0),
          left: 0,
          right: 0,
          height: stageH,
          child: child!,
        ),
        child: _Stage(h: stageH),
      ),
      CustomScrollView(
        key: PageStorageKey('arena_${widget.id}'),
        controller: sc,
        slivers: [
          SliverPadding(
            padding: EdgeInsets.fromLTRB(16, top + 14, 16, 40 + bottom),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _Header(s: s),
                const SizedBox(height: 12),
                s.sponsorSlot(),
                const SizedBox(height: 12),
                KeyedSubtree(key: tabsK, child: _TabsBar(s: s)),
                if (widget.hero != null) KeyedSubtree(key: heroK, child: widget.hero!),
                ...widget.children,
              ]),
            ),
          ),
        ],
      ),
      // تابەکان کاتێک سکرۆڵ دەکرێت لە سەرەوە دەمێننەوە
      AnimatedBuilder(
        animation: sc,
        builder: (_, __) {
          final off = sc.hasClients ? sc.offset : 0.0;
          final pin = off > tabsY - top;
          return Positioned(
            top: top,
            left: 12,
            right: 12,
            child: IgnorePointer(
              ignoring: !pin,
              child: AnimatedOpacity(
                opacity: pin ? 1 : 0,
                duration: const Duration(milliseconds: 120),
                child: _TabsBar(s: s),
              ),
            ),
          );
        },
      ),
    ]);
  }
}

// =============================================================================
// جامی خول (.t3tro)
// =============================================================================

class _Trophy extends StatefulWidget {
  const _Trophy();
  @override
  State<_Trophy> createState() => _TrophyState();
}

class _TrophyState extends State<_Trophy> with TickerProviderStateMixin {
  late final AnimationController loop = AnimationController(vsync: this, duration: const Duration(seconds: 12))..repeat();
  late final AnimationController enter = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))..forward();
  late final AnimationController tap = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
  @override
  void dispose() {
    loop.dispose();
    enter.dispose();
    tap.dispose();
    super.dispose();
  }

  double _wave(double t, double period, [double phase = 0]) => .5 - .5 * math.cos(((t / period) + phase) * 2 * math.pi);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        tap.forward(from: 0);
      },
      child: SizedBox(
        width: 290,
        height: 272,
        child: AnimatedBuilder(
          animation: Listenable.merge([loop, enter, tap]),
          builder: (_, __) {
            final t = loop.value * 12;
            final pulse = _wave(t, 3.2), breath = _wave(t, 6), bob = _wave(t, 4.2);
            final e = Curves.easeOutBack.transform(enter.value.clamp(0.0, 1.0));
            final tp = tap.value;
            final pop = tp == 0 ? 1.0 : 1 + .07 * math.sin(math.min(1, tp / .6) * math.pi);
            return Stack(clipBehavior: Clip.none, alignment: Alignment.center, children: [
              // تیشکەکان
              Positioned(
                left: -55,
                top: -64,
                width: 400,
                height: 400,
                child: Opacity(
                  opacity: .7 + .3 * breath,
                  child: Transform.scale(
                    scale: .97 + .06 * breath,
                    child: Transform.rotate(angle: loop.value * 2 * math.pi * .25, child: CustomPaint(painter: _RaysPainter())),
                  ),
                ),
              ),
              // هالە
              Positioned(
                left: 20,
                right: 20,
                top: 10,
                bottom: 10,
                child: Opacity(
                  opacity: .75 + .25 * pulse,
                  child: Transform.scale(
                    scale: 1 + .07 * pulse,
                    child: const DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                            colors: [Color(0x8CFFCE5C), Color(0x24FFAA28), Color(0x00FFAA28)], stops: [0, .46, .7]),
                      ),
                    ),
                  ),
                ),
              ),
              // پایە
              Positioned(
                bottom: 4,
                child: Opacity(
                  opacity: .75 + .25 * pulse,
                  child: Container(
                    width: 220,
                    height: 36,
                    decoration: const BoxDecoration(
                      borderRadius: BorderRadius.all(Radius.elliptical(110, 18)),
                      gradient: RadialGradient(colors: [Color(0x99FFD66E), Color(0x2EFFB43C), Color(0x00FFB43C)], stops: [0, .6, 1]),
                    ),
                  ),
                ),
              ),
              Positioned.fill(child: CustomPaint(painter: _SparkPainter(t))),
              // جامەکە
              Transform.translate(
                offset: Offset(0, -7 * bob + 30 * (1 - e)),
                child: Opacity(
                  opacity: enter.value.clamp(0.0, 1.0),
                  child: Transform.scale(
                    scale: (.5 + .5 * e) * pop,
                    child: Image.asset('assets/arena/trophy.webp', width: 200, height: 236, filterQuality: FilterQuality.medium,
                        errorBuilder: (_, __, ___) => const SizedBox(width: 200, height: 236)),
                  ),
                ),
              ),
              if (tp > 0 && tp < 1)
                Positioned(
                  top: 272 * .44 - 75,
                  child: Opacity(
                    opacity: 1 - tp,
                    child: Transform.scale(
                      scale: .4 + 1.6 * tp,
                      child: Container(
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: const Color(0xE6FFE6A0), width: 2)),
                      ),
                    ),
                  ),
                ),
            ]);
          },
        ),
      ),
    );
  }
}

class _RaysPainter extends CustomPainter {
  @override
  void paint(Canvas c, Size s) {
    final ctr = s.center(Offset.zero);
    final r = s.width / 2;
    final rect = Rect.fromCircle(center: ctr, radius: r);
    c.saveLayer(rect, Paint());
    final p = Paint()..color = const Color(0x21FFDE8C);
    for (double a = 0; a < 360; a += 16) {
      final a1 = (a - 90) * math.pi / 180, a2 = (a - 85) * math.pi / 180;
      final path = Path()
        ..moveTo(ctr.dx, ctr.dy)
        ..lineTo(ctr.dx + r * math.cos(a1), ctr.dy + r * math.sin(a1))
        ..lineTo(ctr.dx + r * math.cos(a2), ctr.dy + r * math.sin(a2))
        ..close();
      c.drawPath(path, p);
    }
    c.drawRect(
        rect,
        Paint()
          ..blendMode = BlendMode.dstIn
          ..shader = ui.Gradient.radial(ctr, r, const [Color(0xFF000000), Color(0xFF000000), Color(0x00000000)], const [0, .18, .64]));
    c.restore();
  }

  @override
  bool shouldRepaint(_RaysPainter o) => false;
}

class _SparkPainter extends CustomPainter {
  _SparkPainter(this.t);
  final double t;
  static const sk = [[28.0, 40.0, 0.0], [250.0, 58.0, .8], [44.0, 170.0, 1.4], [244.0, 160.0, .4], [86.0, 14.0, 1.9], [214.0, 110.0, 1.1], [136.0, 4.0, 2.3]];
  static const du = [[96.0, 0.0], [120.0, 1.2], [150.0, 2.4], [176.0, .6], [200.0, 3.1], [110.0, 3.8], [186.0, 1.8]];
  @override
  void paint(Canvas c, Size s) {
    for (final p in sk) {
      final ph = ((t - p[2]) % 2.4) / 2.4;
      final v = .5 - .5 * math.cos(ph * 2 * math.pi);
      final sc = .3 + .7 * v;
      final cx = p[0] + 5, cy = p[1] + 5;
      final r = 5 * sc;
      final path = Path()
        ..moveTo(cx, cy - r)
        ..lineTo(cx + r * .2, cy - r * .2)
        ..lineTo(cx + r, cy)
        ..lineTo(cx + r * .2, cy + r * .2)
        ..lineTo(cx, cy + r)
        ..lineTo(cx - r * .2, cy + r * .2)
        ..lineTo(cx - r, cy)
        ..lineTo(cx - r * .2, cy - r * .2)
        ..close();
      c.drawPath(path, Paint()..color = const Color(0xFFFFF6D6).withAlpha((v * 255).round()));
    }
    for (final p in du) {
      final ph = ((t - p[1]) % 5) / 5;
      final o = ph < .15 ? ph / .15 : (ph < .85 ? 1 - (ph - .15) / .7 * .2 : .8 * (1 - (ph - .85) / .15));
      final y = s.height - 40 - ph * 150;
      final pr = 2 * (.5 + .5 * math.min(1, ph * 4));
      c.drawCircle(Offset(p[0] + 2, y), pr + 3, Paint()..color = const Color(0xFFFFD36B).withAlpha((o * 60).round())..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
      c.drawCircle(Offset(p[0] + 2, y), pr, Paint()..color = const Color(0xFFFFE7A6).withAlpha((o * 255).round()));
    }
  }

  @override
  bool shouldRepaint(_SparkPainter o) => o.t != t;
}

/// کاتژمێری ماوە (.t3cd)
class _Countdown extends StatelessWidget {
  const _Countdown({required this.to, required this.clock});
  final DateTime to;
  final ValueNotifier<DateTime> clock;
  @override
  Widget build(BuildContext context) => ValueListenableBuilder<DateTime>(
        valueListenable: clock,
        builder: (_, now, __) {
          final d = to.difference(now);
          final t = d.isNegative ? Duration.zero : d;
          final v = [t.inDays, t.inHours % 24, t.inMinutes % 60, t.inSeconds % 60];
          final l = [tr('u_d'), tr('u_h'), tr('u_m'), tr('u_s')];
          return Directionality(
            textDirection: TextDirection.ltr,
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              for (var i = 0; i < 4; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                Container(
                  width: 68,
                  padding: const EdgeInsets.fromLTRB(0, 9, 0, 7),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: const LinearGradient(
                        begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0x1CFFFFFF), Color(0x08FFFFFF)]),
                    border: Border.all(color: const Color(0x4DFFD678)),
                  ),
                  child: Column(children: [
                    Text(i == 0 ? '${v[i]}' : _p2(v[i]), style: atn(26, c: i == 3 ? AC.goldS : Colors.white, h: 1.15)),
                    const SizedBox(height: 1),
                    Text(l[i], style: ats(11, w: FontWeight.w700, c: const Color(0xFFCBBD94))),
                  ]),
                ),
              ],
            ]),
          );
        },
      );
}

/// بەشی قارەمان لەسەر ستەیج (#t3hero)
class _HeroBlock extends StatelessWidget {
  const _HeroBlock({required this.live, required this.title, required this.sub, required this.cdl, required this.to, required this.meta, required this.clock, this.n = 1});
  final bool live;
  final String title, sub, cdl;
  final DateTime? to;
  final List<String> meta;
  final ValueNotifier<DateTime> clock;
  final int n;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(0, 16, 0, 18),
        child: Column(children: [
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            _LivePill(live: live),
            const SizedBox(width: 8),
            Text('VEX ARENA · SEASON $n', textDirection: TextDirection.ltr, style: atn(11, c: AC.goldS, ls: 2.86)),
          ]),
          const SizedBox(height: 8),
          Text(title,
              textAlign: TextAlign.center,
              style: ats(math.min(31, math.max(24, MediaQuery.of(context).size.width * .072)), w: FontWeight.w900, c: Colors.white, h: 1.3)
                  .copyWith(shadows: const [Shadow(color: Color(0x66FFBE46), blurRadius: 30, offset: Offset(0, 6))])),
          const SizedBox(height: 4),
          Text(sub, textAlign: TextAlign.center, style: ats(13, w: FontWeight.w600, c: AC.stageMu)),
          const SizedBox(height: 2),
          const FittedBox(child: _Trophy()),
          if (to != null) ...[
            const SizedBox(height: 4),
            Text(cdl, style: ats(12.5, w: FontWeight.w700, c: const Color(0xFFFFDF94))),
            const SizedBox(height: 8),
            FittedBox(child: _Countdown(to: to!, clock: clock)),
          ],
          const SizedBox(height: 14),
          Wrap(alignment: WrapAlignment.center, crossAxisAlignment: WrapCrossAlignment.center, spacing: 10, runSpacing: 6, children: [
            for (var i = 0; i < meta.length; i++) ...[
              if (i > 0) Container(width: 4, height: 4, decoration: const BoxDecoration(color: Color(0xFF4A5888), shape: BoxShape.circle)),
              _richNum(meta[i], ats(12.5, w: FontWeight.w700, c: const Color(0xFFC4CDEA)), atn(14, w: FontWeight.w900, c: Colors.white)),
            ],
          ]),
        ]),
      );
}

class _LivePill extends StatefulWidget {
  const _LivePill({required this.live});
  final bool live;
  @override
  State<_LivePill> createState() => _LivePillState();
}

class _LivePillState extends State<_LivePill> with SingleTickerProviderStateMixin {
  late final AnimationController a = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat(reverse: true);
  @override
  void dispose() {
    a.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final live = widget.live;
    final k = live ? const Color(0xFFFF4D67) : const Color(0xFFFFD36B);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: live ? const Color(0x29FF4860) : const Color(0x24FFC846),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: live ? const Color(0x73FF5A6E) : const Color(0x73FFD678)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        FadeTransition(
          opacity: Tween(begin: .35, end: 1.0).animate(a),
          child: Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(shape: BoxShape.circle, color: k, boxShadow: live ? [BoxShadow(color: k, blurRadius: 8)] : null),
          ),
        ),
        const SizedBox(width: 6),
        Text(live ? tr('live') : tr('soon'), style: ats(11.5, w: FontWeight.w800, c: live ? const Color(0xFFFFC2CB) : const Color(0xFFFFD36B))),
      ]),
    );
  }
}

/// نووسین کە ژمارەکانی بە فۆنتی Sora دەردەکەون: «**11** یاریزان»
/// ژمارەکان لە نێو ⟦ ⟧ دان: tr دەقەکان بە {n} پڕ دەکاتەوە و ئێمە ژمارەکان دەدۆزینەوە
Widget _richNum(String s, TextStyle base, TextStyle num, {TextAlign align = TextAlign.start, int? maxLines}) {
  final re = RegExp(r'[+#×\-]?\d[\d,./:×%]*\+?');
  final spans = <InlineSpan>[];
  var i = 0;
  for (final m in re.allMatches(s)) {
    if (m.start > i) spans.add(TextSpan(text: s.substring(i, m.start)));
    spans.add(TextSpan(text: m.group(0), style: num));
    i = m.end;
  }
  if (i < s.length) spans.add(TextSpan(text: s.substring(i)));
  return Text.rich(TextSpan(style: base, children: spans), textAlign: align, maxLines: maxLines, overflow: maxLines == null ? null : TextOverflow.ellipsis);
}

// =============================================================================
// دەروازەی تۆمارکردن (.v8gate) — پێش چوونە ژوورەوە پێویستە
// =============================================================================

class _Gate extends StatefulWidget {
  const _Gate({required this.c, required this.onDone});
  final ArenaCtl c;
  final VoidCallback onDone;
  @override
  State<_Gate> createState() => _GateState();
}

class _GateState extends State<_Gate> {
  ArenaCtl get c => widget.c;
  int step = 1;
  String err = '';
  final name = TextEditingController();
  final phone = TextEditingController();
  final q = TextEditingController();
  final body = ScrollController();
  FixedExtentScrollController wheel = FixedExtentScrollController();
  List<String> list = List.of(kCities);
  int wi = 0;
  String city = '';
  String age = 'a';
  String ch = '';
  bool agree = false;

  static const List<String> _free = ['00', '01', '02', '03', '07', '08', '10', '11'];

  @override
  void initState() {
    super.initState();
    final a = c.store.acc;
    final p = c.host.profile;
    name.text = a?.name ?? p.name;
    final ph = a?.phone ?? p.phone;
    if (RegExp(r'^07\d{9}$').hasMatch(ph)) phone.text = _fmtPhone(ph.substring(1));
    city = a?.city ?? '';
    age = a?.age ?? (p.age < 18 ? 'y' : p.age < 40 ? 'a' : p.age < 60 ? 'm' : 's');
    ch = _free.contains(c.store.ch) ? c.store.ch : '';
  }

  @override
  void dispose() {
    name.dispose();
    phone.dispose();
    q.dispose();
    body.dispose();
    wheel.dispose();
    super.dispose();
  }

  String _fmtPhone(String d) {
    d = d.replaceAllMapped(RegExp('[٠-٩]'), (m) => '${m[0]!.codeUnitAt(0) - 0x660}').replaceAll(RegExp(r'\D'), '');
    if (d.startsWith('0')) d = d.substring(1);
    if (d.length > 10) d = d.substring(0, 10);
    final b = StringBuffer();
    for (var i = 0; i < d.length; i++) {
      if (i == 3 || i == 6) b.write(' ');
      b.write(d[i]);
    }
    return b.toString();
  }

  void _go(int s) {
    setState(() {
      step = s;
      err = '';
      if (s == 2) {
        q.text = '';
        list = List.of(kCities);
        wi = math.max(0, list.indexOf(city.isEmpty ? kCities.first : city));
        wheel.dispose();
        wheel = FixedExtentScrollController(initialItem: wi);
      }
    });
    if (body.hasClients) body.jumpTo(0);
  }

  void _next() {
    FocusScope.of(context).unfocus();
    if (step == 1) {
      final n = name.text.trim().replaceAll(RegExp(r'\s+'), ' ');
      final p = '0${phone.text.replaceAll(RegExp(r'\D'), '')}';
      if (n.length < 3 || !n.contains(' ')) return setState(() => err = tr('e_name'));
      if (!RegExp(r'^07[3-9]\d{8}$').hasMatch(p)) return setState(() => err = tr('e_phone'));
      _go(2);
    } else if (step == 2) {
      if (list.isEmpty) return setState(() => err = tr('e_city'));
      city = list[wi.clamp(0, list.length - 1)];
      _go(3);
    } else if (step == 3) {
      if (ch.isEmpty) return setState(() => err = tr('e_char'));
      _go(4);
    } else {
      if (!agree) return setState(() => err = tr('e_agree'));
      final n = name.text.trim().replaceAll(RegExp(r'\s+'), ' ');
      c.register(
        name: n.length > 24 ? n.substring(0, 24) : n,
        phone: '0${phone.text.replaceAll(RegExp(r'\D'), '')}',
        city: city,
        age: age,
        ch: ch,
      );
      HapticFeedback.mediumImpact();
      widget.onDone();
    }
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final steps = [tr('st_id'), tr('st_city'), tr('st_char'), tr('st_rules')];
    final kb = mq.viewInsets.bottom;
    return Stack(children: [
      Positioned.fill(child: CustomPaint(painter: _GateBg(AC.l, AC.bg))),
      Positioned.fill(
        child: Padding(
          padding: EdgeInsets.fromLTRB(12, math.max(12, mq.padding.top), 12, 12 + mq.padding.bottom + kb),
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 410, maxHeight: 720),
              child: Container(
                decoration: BoxDecoration(
                  color: AC.solid,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: AC.line2),
                  boxShadow: const [BoxShadow(color: Color(0xD9000000), offset: Offset(0, 40), blurRadius: 80, spreadRadius: -20)],
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(children: [
                  // سەر
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                    decoration: BoxDecoration(border: Border(bottom: BorderSide(color: AC.line))),
                    child: Row(children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          gradient: AC.goldG,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [cssSh(0, 10, 22, -10, const Color(0xE6F2B21C))],
                        ),
                        alignment: Alignment.center,
                        child: const AIcon('trophy', size: 20, color: Color(0xFF5A3A00)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(tr('g_title'), style: ats(17, w: FontWeight.w800)),
                          const SizedBox(height: 2),
                          Text(tr('g_sub'), style: ats(11.5, c: AC.mu)),
                        ]),
                      ),
                    ]),
                  ),
                  // ناوەڕۆک
                  Expanded(
                    child: SingleChildScrollView(
                      controller: body,
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(children: [
                            for (var i = 0; i < 4; i++) ...[
                              if (i > 0) const SizedBox(width: 6),
                              Expanded(child: _stepDot(i + 1, steps[i])),
                            ],
                          ]),
                        ),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 220),
                          child: KeyedSubtree(key: ValueKey(step), child: _stepBody()),
                        ),
                      ]),
                    ),
                  ),
                  // خوارەوە (هەمیشە جێگیر)
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
                    decoration: BoxDecoration(color: AC.solid, border: Border(top: BorderSide(color: AC.line))),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      SizedBox(
                        height: 20,
                        child: Center(
                          child: Text(err, maxLines: 1, overflow: TextOverflow.ellipsis, style: ats(12, w: FontWeight.w600, c: AC.coral)),
                        ),
                      ),
                      Row(children: [
                        if (step > 1) ...[
                          _Btn(tr('back'), kind: 's', lead: AIcon('down', size: 17, color: AC.tx).rot(arenaLtr ? 90 : -90), onTap: () => _go(step - 1)),
                          const SizedBox(width: 8),
                        ],
                        Expanded(
                          child: step < 4
                              ? _Btn(tr('cont'), trail: const AIcon('down', size: 17, color: AC.onGold).rot(arenaLtr ? -90 : 90), onTap: _next)
                              : _Btn(c.S.live ? tr('join') : tr('register'), icon: 'rocket', onTap: _next),
                        ),
                      ]),
                    ]),
                  ),
                ]),
              ),
            ),
          ),
        ),
      ),
    ]);
  }

  Widget _stepDot(int n, String label) {
    final on = n == step, dn = n < step;
    return Column(children: [
      AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: on ? AC.goldG : null,
          color: on ? null : (dn ? const Color(0x333CF08A) : AC.surf2),
          border: Border.all(color: on ? Colors.transparent : (dn ? const Color(0x803CF08A) : AC.line), width: 1.5),
          boxShadow: on ? const [BoxShadow(color: Color(0x2EFFC846), spreadRadius: 4)] : null,
        ),
        alignment: Alignment.center,
        child: dn
            ? AIcon('check', size: 13, color: AC.mint, sw: 2.4)
            : Text('$n', style: atn(12, c: on ? AC.onGold : AC.tx)),
      ),
      const SizedBox(height: 4),
      Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: ats(11, w: FontWeight.w700, c: on ? AC.tx : AC.mu)),
    ]);
  }

  InputDecoration _dec(String hint, {BorderRadius? r}) {
    final br = r ?? BorderRadius.circular(14);
    return InputDecoration(
      hintText: hint,
      hintStyle: ats(15, c: _a(AC.mu, .75)),
      filled: true,
      fillColor: AC.inp,
      isDense: true,
      counterText: '',
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(borderRadius: br, borderSide: BorderSide(color: AC.line)),
      enabledBorder: OutlineInputBorder(borderRadius: br, borderSide: BorderSide(color: AC.line)),
      focusedBorder: OutlineInputBorder(borderRadius: br, borderSide: BorderSide(color: AC.cy)),
    );
  }

  Widget _lbl(String t, [String? icon]) => Padding(
        padding: const EdgeInsets.only(top: 14, bottom: 7),
        child: Row(children: [
          if (icon != null) ...[AIcon(icon, size: 14, color: AC.mu), const SizedBox(width: 4)],
          Flexible(child: Text(t, style: ats(12, w: FontWeight.w800, c: AC.mu))),
        ]),
      );

  Widget _hint(String icon, String t) => Padding(
        padding: const EdgeInsets.fromLTRB(2, 8, 2, 0),
        child: _IconLine(icon, t, size: 11.5),
      );

  Widget _stepBody() {
    switch (step) {
      case 1:
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          _lbl(tr('f_name')),
          TextField(
            controller: name,
            maxLength: 24,
            textInputAction: TextInputAction.next,
            style: ats(15),
            scrollPadding: const EdgeInsets.only(bottom: 160),
            decoration: _dec(tr('f_name_h')),
            onChanged: (_) {
              if (err.isNotEmpty) setState(() => err = '');
            },
          ),
          _lbl(tr('f_phone')),
          Directionality(
            textDirection: TextDirection.ltr,
            child: IntrinsicHeight(
             child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AC.surf2,
                  borderRadius: const BorderRadius.horizontal(left: Radius.circular(14)),
                  border: Border(left: BorderSide(color: AC.line), top: BorderSide(color: AC.line), bottom: BorderSide(color: AC.line)),
                ),
                child: Text('+964', style: ats(15, w: FontWeight.w800, c: AC.mu)),
              ),
              Expanded(
                child: TextField(
                  controller: phone,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.done,
                  style: ats(16, ls: .96),
                  scrollPadding: const EdgeInsets.only(bottom: 160),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9 ٠-٩]')),
                    TextInputFormatter.withFunction((o, n) {
                      final f = _fmtPhone(n.text);
                      return TextEditingValue(text: f, selection: TextSelection.collapsed(offset: f.length));
                    }),
                  ],
                  decoration: _dec('750 123 4567', r: const BorderRadius.horizontal(right: Radius.circular(14))),
                  onChanged: (_) {
                    if (err.isNotEmpty) setState(() => err = '');
                  },
                  onSubmitted: (_) => _next(),
                ),
              ),
             ]),
            ),
          ),
          _hint('lock', tr('f_phone_h')),
        ]);
      case 2:
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          _lbl(tr('f_city'), 'pin'),
          TextField(
            controller: q,
            style: ats(15),
            decoration: _dec(tr('f_city_h')),
            onChanged: (v) {
              final t = v.trim();
              setState(() {
                list = t.isEmpty
                    ? List.of(kCities)
                    : kCities.where((x) => x.contains(t) || nm(x).toLowerCase().contains(t.toLowerCase())).toList();
                wi = 0;
                err = '';
              });
              if (wheel.hasClients) wheel.jumpToItem(0);
            },
          ),
          const SizedBox(height: 6),
          Container(
            height: 176,
            decoration: BoxDecoration(color: AC.surf2, borderRadius: BorderRadius.circular(18), border: Border.all(color: AC.line)),
            clipBehavior: Clip.antiAlias,
            child: Stack(children: [
              Positioned(
                left: 8,
                right: 8,
                top: 66,
                height: 44,
                child: Container(
                  decoration: BoxDecoration(
                    color: _a(AC.mint, .16),
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(color: _a(AC.mint, .55), width: 1.5),
                  ),
                ),
              ),
              if (list.isEmpty)
                Center(child: Text(tr('f_city_none'), style: ats(15, w: FontWeight.w700, c: AC.mu)))
              else
                ShaderMask(
                  shaderCallback: (r) => const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0x00000000), Color(0xFF000000), Color(0xFF000000), Color(0x00000000)],
                    stops: [0, .28, .72, 1],
                  ).createShader(r),
                  blendMode: BlendMode.dstIn,
                  child: ListWheelScrollView.useDelegate(
                    key: ValueKey('wl${list.length}${q.text}'),
                    controller: wheel,
                    itemExtent: 44,
                    diameterRatio: 1000,
                    physics: const FixedExtentScrollPhysics(),
                    onSelectedItemChanged: (i) => setState(() => wi = i),
                    childDelegate: ListWheelChildBuilderDelegate(
                      childCount: list.length,
                      builder: (_, i) {
                        final d = (i - wi).abs();
                        return GestureDetector(
                          onTap: () => wheel.animateToItem(i, duration: const Duration(milliseconds: 250), curve: Curves.easeOut),
                          child: Opacity(
                            opacity: d == 0 ? 1 : (d == 1 ? .6 : .35),
                            child: Center(
                              child: Text(nm(list[i]), style: ats(d == 0 ? 17 : 15, w: d == 0 ? FontWeight.w800 : FontWeight.w700)),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
            ]),
          ),
          _lbl(tr('f_age')),
          Wrap(spacing: 7, runSpacing: 7, children: [
            for (final a in kAges) _chip(a[1], a[0] == age, () => setState(() => age = a[0])),
          ]),
          if (age == 'y') _hint('help', tr('f_age_y')),
        ]);
      case 3:
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          _IconLine('face', tr('f_char_h'), size: 11.5),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 4,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            children: [
              for (final id in _free)
                GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() {
                      ch = id;
                      err = '';
                    });
                  },
                  child: AnimatedScale(
                    scale: ch == id ? 1.08 : 1,
                    duration: const Duration(milliseconds: 200),
                    child: LayoutBuilder(
                      builder: (_, bc) => Stack(clipBehavior: Clip.none, children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: ch == id
                                ? const [BoxShadow(color: Color(0xFFF2B21C), spreadRadius: 3), BoxShadow(color: Color(0xE6F2B21C), offset: Offset(0, 10), blurRadius: 20, spreadRadius: -6)]
                                : [BoxShadow(color: AC.line2, spreadRadius: 2)],
                          ),
                          child: CharAvatar(ch: id, name: '', size: bc.maxWidth, gold: ch == id),
                        ),
                        if (ch == id)
                          PositionedDirectional(
                            top: 3,
                            end: 3,
                            child: Container(
                              width: 22,
                              height: 22,
                              decoration: const BoxDecoration(shape: BoxShape.circle, color: AC.accent),
                              alignment: Alignment.center,
                              child: const AIcon('check', size: 13, color: AC.onGold, sw: 2.4),
                            ),
                          ),
                      ]),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(ch.isEmpty ? tr('f_char_pick') : tr('f_char_ok'), textAlign: TextAlign.center, style: ats(12.5, w: FontWeight.w700, c: AC.mu)),
        ]);
      default:
        return _rulesStep();
    }
  }

  Widget _chip(String t, bool on, VoidCallback f) => _Tap(
        radius: 99,
        onTap: f,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: on ? (AC.l ? const Color(0x1FE6A014) : const Color(0x24FFC846)) : AC.surf2,
            borderRadius: BorderRadius.circular(99),
            border: Border.all(color: on ? (AC.l ? const Color(0x73C48C14) : const Color(0x80FFD678)) : AC.line),
          ),
          child: Text(t, textDirection: TextDirection.ltr, style: atn(12.5, w: FontWeight.w700, c: on ? (AC.l ? const Color(0xFF8A5A00) : AC.goldS) : AC.tx)),
        ),
      );

  Widget _rulesStep() {
    final band = c.host.hasBand;
    final live = c.S.live;
    final rem = 30 - c.S.day + 1;
    final elig = <List<Object>>[
      if (!live) ['star', tr('el_pre'), const Color(0xFFFFD36B)],
      if (live) ['clock', tr('el_day', [c.S.day, rem]), const Color(0xFF7FD8FF)],
      if (live) rem >= 25 ? ['trophy', tr('el_all'), const Color(0xFF3CF08A)] : rem >= 20 ? ['gift', tr('el_guar'), const Color(0xFFFFB27A)] : ['users', tr('el_week'), const Color(0xFFFFB27A)],
    ];
    final ph = '0${phone.text.replaceAll(RegExp(r'\D'), '')}';
    final o = const Color(0xFFFF8A4D);
    Widget dot(Widget ch, {bool x = false}) => Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: x ? const Color(0x2EFF5F7E) : const Color(0x14FFFFFF),
            border: Border.all(color: x ? const Color(0xFFFF5F7E) : const Color(0x99FF8A4D), width: 1.5),
          ),
          alignment: Alignment.center,
          child: ch,
        );
    Widget call(int n) => Stack(clipBehavior: Clip.none, children: [
          dot(const AIcon('phone', size: 13, color: Color(0xFFFF9A6A))),
          PositionedDirectional(
            bottom: -6,
            end: -4,
            child: Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(shape: BoxShape.circle, color: o),
              alignment: Alignment.center,
              child: Text('$n', style: atn(10, c: Colors.white, h: 1)),
            ),
          ),
        ]);
    Widget dash() => Expanded(
          child: CustomPaint(size: const Size(double.infinity, 2), painter: _Dash(const Color(0x8CFF8A4D))),
        );
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(color: AC.surf2, borderRadius: BorderRadius.circular(16), border: Border.all(color: AC.line)),
        child: Row(children: [
          CharAvatar(ch: ch, name: name.text, size: 40, ring: AC.t3g),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(name.text.trim(), maxLines: 1, overflow: TextOverflow.ellipsis, style: ats(14.5, w: FontWeight.w800)),
              Text.rich(
                TextSpan(children: [
                  TextSpan(text: '\u2066${maskPhone(ph)}\u2069', style: atn(12, w: FontWeight.w600, c: AC.mu)),
                  TextSpan(text: ' · ${nm(city)}'),
                ]),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: ats(12, c: AC.mu),
              ),
            ]),
          ),
          _Tap(
            radius: 11,
            onTap: () => _go(1),
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(11), border: Border.all(color: AC.line)),
              alignment: Alignment.center,
              child: AIcon('edit', size: 15, color: AC.mu),
            ),
          ),
        ]),
      ),
      _DivBox(band: band),
      const SizedBox(height: 10),
      for (final e in elig) ...[
        _KBox(k: e[2] as Color, icon: e[0] as String, text: e[1] as String),
        const SizedBox(height: 6),
      ],
      const SizedBox(height: 4),
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: cssLin(130, const [Color(0x24FF8A4D), Color(0x08FF8A4D)]),
          border: Border.all(color: const Color(0x73FF8A4D)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            const AIcon('phone', size: 18, color: Color(0xFFFF9A6A)),
            const SizedBox(width: 8),
            Expanded(child: Text(tr('win_t'), style: ats(14, w: FontWeight.w800))),
          ]),
          const SizedBox(height: 6),
          _richNum(tr('win_s'), ats(12.5, h: 1.7), atn(12.5, w: FontWeight.w800, h: 1.7)),
          const SizedBox(height: 12),
          Directionality(
            textDirection: TextDirection.rtl,
            child: Row(children: [
              call(1), dash(), call(2), dash(), call(3), dash(),
              dot(const AIcon('close', size: 13, color: Color(0xFFFF5F7E)), x: true),
            ]),
          ),
          const SizedBox(height: 4),
        ]),
      ),
      const SizedBox(height: 10),
      for (final k in ['r_data', 'r_cheat', 'r_lock', 'r_18'])
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Padding(padding: const EdgeInsets.only(top: 3), child: AIcon('check', size: 13, color: AC.mint)),
            const SizedBox(width: 6),
            Expanded(child: Text(tr(k), style: ats(12, c: AC.mu, h: 1.6))),
          ]),
        ),
      const SizedBox(height: 6),
      _Tap(
        radius: 14,
        onTap: () => setState(() {
          agree = !agree;
          err = '';
        }),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: AC.surf2, borderRadius: BorderRadius.circular(14), border: Border.all(color: AC.line)),
          child: Row(children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: agree ? AC.accent : Colors.transparent,
                borderRadius: BorderRadius.circular(5),
                border: Border.all(color: agree ? AC.accent : AC.mu, width: 1.6),
              ),
              alignment: Alignment.center,
              child: agree ? const AIcon('check', size: 14, color: Colors.white, sw: 2.6) : null,
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(tr('agree'), style: ats(13.5, w: FontWeight.w700))),
          ]),
        ),
      ),
    ]);
  }
}

class _Dash extends CustomPainter {
  _Dash(this.c);
  final Color c;
  @override
  void paint(Canvas cv, Size s) {
    final p = Paint()
      ..color = c
      ..strokeWidth = 1.5;
    for (double x = 2; x < s.width - 2; x += 6) {
      cv.drawLine(Offset(x, 1), Offset(math.min(x + 3, s.width - 2), 1), p);
    }
  }

  @override
  bool shouldRepaint(_Dash o) => o.c != c;
}

/// قوتووی ڕەنگاوڕەنگ (.v6el p)
class _KBox extends StatelessWidget {
  const _KBox({required this.k, required this.icon, required this.text});
  final Color k;
  final String icon, text;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
        decoration: BoxDecoration(
          color: _a(k, .10),
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: _a(k, .35)),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(padding: const EdgeInsets.only(top: 2), child: AIcon(icon, size: 16, color: k)),
          const SizedBox(width: 8),
          Expanded(child: _richNum(text, ats(12.5, h: 1.65), atn(12.5, w: FontWeight.w800, h: 1.65))),
        ]),
      );
}

/// لیگی تۆ (.v9dv)
class _DivBox extends StatelessWidget {
  const _DivBox({required this.band});
  final bool band;
  @override
  Widget build(BuildContext context) {
    final k = band ? AC.mint : const Color(0xFF7FD8FF);
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: band ? const Color(0x143CF08A) : const Color(0x147FD8FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: band ? const Color(0x663CF08A) : const Color(0x667FD8FF)),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(color: _a(k, .16), borderRadius: BorderRadius.circular(12)),
          alignment: Alignment.center,
          child: AIcon(band ? 'shield' : 'phone', size: 20, color: k),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(tr(band ? 'dv_band_t' : 'dv_phone_t'), style: ats(13.5, w: FontWeight.w800)),
            const SizedBox(height: 2),
            Text(tr(band ? 'dv_band_s' : 'dv_phone_s'), style: ats(12, c: AC.mu, h: 1.6)),
          ]),
        ),
      ]),
    );
  }
}

class _GateBg extends CustomPainter {
  _GateBg(this.light, this.bg);
  final bool light;
  final Color bg;
  @override
  void paint(Canvas c, Size s) {
    final r = Offset.zero & s;
    c.drawRect(r, Paint()..color = light ? const Color(0xFFDFE6F5) : bg);
    _ellipse(c, r, Offset(s.width * .5, -s.height * .06), s.width * .9, s.height * .48, const [Color(0x47F2B21C), Color(0x00F2B21C)], const [0, .62]);
    _ellipse(c, r, Offset(s.width * .08, s.height * 1.04), s.width * .7, s.height * .45, const [Color(0x292FE6F3), Color(0x002FE6F3)], const [0, .62]);
    if (!light) {
      _ellipse(c, r, Offset(s.width * .96, s.height * .7), s.width * .6, s.height * .4, const [Color(0x1F9B7BFF), Color(0x009B7BFF)], const [0, .62]);
    }
  }

  @override
  bool shouldRepaint(_GateBg o) => o.light != light || o.bg != bg;
}

// =============================================================================
// پیشاندانی کارت دوای تۆمارکردن (.rvl)
// =============================================================================

void showArenaReveal(BuildContext context, ArenaCtl c) {
  final a = c.store.acc;
  if (a == null) return;
  showGeneralDialog(
    context: context,
    barrierDismissible: false,
    barrierLabel: 'reveal',
    barrierColor: Colors.transparent,
    transitionDuration: const Duration(milliseconds: 350),
    pageBuilder: (ctx, _, __) => _Reveal(c: c),
    transitionBuilder: (ctx, an, _, child) => FadeTransition(opacity: an, child: child),
  ).then((_) {
    if (context.mounted) arenaToast(context, tr('rv_toast'), 'star');
  });
}

class _Reveal extends StatefulWidget {
  const _Reveal({required this.c});
  final ArenaCtl c;
  @override
  State<_Reveal> createState() => _RevealState();
}

class _RevealState extends State<_Reveal> with TickerProviderStateMixin {
  late final AnimationController flip = AnimationController(vsync: this, duration: const Duration(milliseconds: 1300))..forward();
  late final AnimationController land = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100));
  late final AnimationController spin = AnimationController(vsync: this, duration: const Duration(seconds: 30))..repeat();
  bool landed = false;

  @override
  void initState() {
    super.initState();
    flip.addStatusListener((s) {
      if (s == AnimationStatus.completed) _land();
    });
    Future.delayed(const Duration(milliseconds: 1500), _land);
  }

  void _land() {
    if (landed || !mounted) return;
    setState(() => landed = true);
    land.forward();
    HapticFeedback.mediumImpact();
    arenaConfetti(context, 26);
  }

  @override
  void dispose() {
    flip.dispose();
    land.dispose();
    spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.c, a = c.store.acc!;
    final L = leagueOf(c.myTotal);
    final w = math.min(236.0, MediaQuery.of(context).size.width - 80);
    return Directionality(
      textDirection: arenaDir,
      child: Material(
        type: MaterialType.transparency,
        child: Container(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(0, -.24),
              radius: 1.1,
              colors: [Color(0xFF0D4F5E), Color(0xFF04202A), Color(0xFF010B10)],
              stops: [0, .45, 1],
            ),
          ),
          child: SafeArea(
            child: Stack(alignment: Alignment.center, children: [
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: spin,
                  builder: (_, __) => Opacity(
                    opacity: landed ? 1 : 0,
                    child: Transform.rotate(
                      angle: spin.value * 2 * math.pi,
                      child: CustomPaint(painter: _RevealRays()),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  AnimatedBuilder(
                    animation: flip,
                    builder: (_, __) {
                      final t = Curves.easeOutCubic.transform(flip.value);
                      final ang = (1 - t) * math.pi * 3;
                      final front = (ang % (2 * math.pi)) < math.pi / 2 || (ang % (2 * math.pi)) > math.pi * 1.5;
                      return Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.identity()
                          ..setEntry(3, 2, .0008)
                          ..translateByDouble(0, 60 * (1 - t), 0, 1)
                          ..rotateY(ang)
                          ..scaleByDouble(.6 + .4 * t, .6 + .4 * t, 1, 1),
                        child: front
                            ? ArenaCardView.of(c, width: w)
                            : Transform(
                                alignment: Alignment.center,
                                transform: Matrix4.rotationY(math.pi),
                                child: _CardBack(width: w),
                              ),
                      );
                    },
                  ),
                  const SizedBox(height: 26),
                  AnimatedOpacity(
                    opacity: landed ? 1 : 0,
                    duration: const Duration(milliseconds: 400),
                    child: AnimatedSlide(
                      offset: landed ? Offset.zero : const Offset(0, .1),
                      duration: const Duration(milliseconds: 400),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 360),
                        child: Column(children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0x243CF08A),
                              borderRadius: BorderRadius.circular(99),
                              border: Border.all(color: const Color(0x593CF08A)),
                            ),
                            child: Row(mainAxisSize: MainAxisSize.min, children: [
                              const AIcon('spark', size: 14, color: Color(0xFF7CF7B4)),
                              const SizedBox(width: 6),
                              Text(tr('rv_k', [c.S.n]) + (c.S.live ? tr('rv_k_live') : tr('rv_k_pre')),
                                  style: ats(12, w: FontWeight.w800, c: const Color(0xFF7CF7B4))),
                            ]),
                          ),
                          const SizedBox(height: 10),
                          ShaderMask(
                            shaderCallback: (r) => const LinearGradient(colors: [Color(0xFF8FF3F9), Color(0xFF3CF08A)]).createShader(r),
                            child: Text(tr('rv_t'), style: ats(26, w: FontWeight.w900, c: Colors.white)),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            c.S.live ? tr('rv_live', [a.name, L.name]) : tr('rv_pre', [a.name]),
                            textAlign: TextAlign.center,
                            style: ats(13.5, c: const Color(0xC7EAFCFF), h: 1.6),
                          ),
                          const SizedBox(height: 16),
                          _Btn(tr('rv_go'), icon: 'check', h: 54, onTap: () => Navigator.of(context).pop()),
                        ]),
                      ),
                    ),
                  ),
                ]),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

class _RevealRays extends CustomPainter {
  @override
  void paint(Canvas c, Size s) {
    final ctr = Offset(s.width / 2, s.height * .38);
    const r = 360.0;
    final rect = Rect.fromCircle(center: ctr, radius: r);
    c.saveLayer(rect, Paint());
    final p = Paint()..color = const Color(0x178FF3F9);
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
    c.drawRect(
        rect,
        Paint()
          ..blendMode = BlendMode.dstIn
          ..shader = ui.Gradient.radial(ctr, r, const [Color(0xFF000000), Color(0x00000000)], const [0, .6]));
    c.restore();
  }

  @override
  bool shouldRepaint(_RevealRays o) => false;
}

class _CardBack extends StatelessWidget {
  const _CardBack({required this.width});
  final double width;
  @override
  Widget build(BuildContext context) => Container(
        width: width,
        height: width * 330 / 236,
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30), bottom: Radius.circular(26)),
          gradient: const RadialGradient(
              center: Alignment(0, -.3), colors: [Color(0xFF1FD4C4), Color(0xFF0B5E74), Color(0xFF06303C)], stops: [0, .55, 1]),
          border: Border.all(color: const Color(0x38FFFFFF), width: 1.5),
        ),
        alignment: Alignment.center,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('VEX', style: atn(46, c: Colors.white, h: 1, ls: 1.8)),
          const SizedBox(height: 6),
          Text('ARENA', style: atn(12, c: Colors.white.withAlpha(217), ls: 6)),
        ]),
      );
}
