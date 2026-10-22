// VEX Health — قوفڵی VEX Plus و VEX Band
//
// • بەشی Plus (VEX AI، خێزان، ڕاهێنان) تا Plus نەکڕدرێت لێڵ و قوفڵ دەمێنێتەوە.
// • بەشی Band (دڵ، ئۆکسجین، سترێس، خەو، پلەی پێست، نمرەی تەندروستی) تا Band پەیوەست نەکرێت قوفڵە.
// • پلانی خۆڕایی: 3 سکان لە ڕۆژێکدا (ScanQuota).
//
// بەکارهێنان:
//   Gated(kind: GateKind.plus, id: 'family', child: ...)        ← بەشێک لەناو پەڕەیەک
//   pushPage(GatePage(kind: GateKind.band, id: 'heart', child: HeartPage()))   ← پەڕەیەکی تەواو
//   if (!ScanQuota.take()) return;                               ← پێش هەر سکانێک
//
// هەر کاتێک Plus کڕدرا یان Band پەیوەست کرا، پەردەکە خۆی لادەچێت (بێ دووبارە کردنەوەی پەڕەکە).
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../band/band_lock.dart';
import '../band/band_emblem.dart';
import '../band/band_pair_card.dart';
import '../band/band_state.dart';
import '../core/icons.dart';
import '../core/theme.dart';
import '../onboarding/account.dart';
import 'plus_page.dart';
import 'plus_state.dart';

enum GateKind { band, plus }

Color get _gold1 => vk(0xFFFFE29A);
Color get _gold2 => vk(0xFFFFBF47);
Color get _gold3 => vk(0xFFFF9D3D);
Color get _brown => vk(0xFF3B2500);

class GateInfo {
  const GateInfo(this.title, this.desc, this.perks, {this.alt});
  final String title;
  final String desc;
  final List<String> perks;

  /// دوگمەی دووەم (تەنها Plus): نموونە «ڕاهێنانی خێرا»
  final String? alt;
}

const Map<String, GateInfo> _info = {
  // ---- Band ----
  'ring': GateInfo('نمرەی تەندروستی', 'Band ـەکەت پەیوەست بکە تا نمرەی تەندروستی ڕاستەقینەت بۆ ئەمڕۆ ببینیت.',
      ['نمرەی زیندووی ڕۆژانە', 'دڵ، خەو، سترێس و ئۆکسجین', 'ئامۆژگاریی تایبەت بە تۆ']),
  'health': GateInfo('داتای تەندروستی', 'ئەم زانیارییانە لە VEX Band ـەوە دێن. Band پەیوەست بکە تا زیندوو ببن.',
      ['هەموو نیشانە زیندووەکان', 'هاوکاتکردنی خۆکار', 'مێژووی ڕۆژانە و هەفتانە']),
  'heart': GateInfo('لێدانی دڵ', 'لێدانی دڵت بە درێژایی ڕۆژ و شەو لە Band ـەوە دەخوێنرێتەوە.',
      ['لێدانی دڵی زیندوو', 'پشوو، ناوەند و بەرزترین', 'ئاگاداری لێدانی نائاسایی']),
  'spo2': GateInfo('ئۆکسجینی خوێن', 'ئۆکسجینی خوێنت بە شێوەی بەردەوام لە Band ـەوە دەپێورێت.',
      ['SpO₂ ی زیندوو', 'پێوانەی شەو', 'ئاگاداری کەمبوونەوە']),
  'stress': GateInfo('سترێس و HRV', 'Band لە ڕێگەی HRV ـەوە ئاستی سترێست دەزانێت و ڕێنماییت دەکات.',
      ['ئاستی سترێس بە درێژایی ڕۆژ', 'HRV ی ورد', 'ڕاهێنانی هەناسەدان']),
  'temp': GateInfo('پلەی پێست', 'پلەی پێستت بە شێوەی بەردەوام لە Band ـەوە دەپێورێت.',
      ['گۆڕانی پلە بە درێژایی شەو', 'ئاگاداری هەڵکشان', 'بەراوردی ڕۆژانە']),
  'sleep': GateInfo('خەو', 'قۆناغەکانی خەوت (قووڵ، سووک، REM) لە Band ـەوە شی دەکرێنەوە.',
      ['قۆناغەکانی خەو', 'نمرەی خەو', 'ڕاسپاردەی خەوتن']),
  // ---- Plus ----
  'ai': GateInfo('VEX AI', 'یاریدەدەری تەندروستیی تایبەت بە تۆ، کە داتاکانت دەخوێنێتەوە و ڕێنماییت دەکات.',
      ['کورتەی ئەمڕۆ بە AI', 'پلانی تایبەت بە تۆ', 'سکانی بێسنووری خواردن']),
  'family': GateInfo('بازنەی خێزان', 'تەندروستیی خێزانەکەت لە یەک شوێن ببینە و ئاگادار بە.',
      ['تا 6 ئەندام', 'ئاگاداریی ئەنجامە ناڕێکەکان', 'پرۆفایلی هەر ئەندامێک']),
  'workout': GateInfo('ڕاهێنانی AI', 'پلانی ڕاهێنان کە بەپێی داتای Band ـەکەت هەموو ڕۆژێک خۆی دەگۆڕێت.',
      ['پلانی ڕاهێنانی تایبەت', 'شوێنپێی زیندووی ڕاهێنان', 'ڕاسپاردەی پشوودان'],
      alt: 'ڕاهێنانی خێرا'),
  'scan': GateInfo('سکانی بێسنوور', 'سکانە خۆڕاییەکانی ئەمڕۆت تەواو بوون. VEX Plus سکانی بێسنوورت دەداتێ.',
      ['سکانی بێسنوور', 'وردبینیی خۆراکی تەواو', 'پشتیوانی VEX AI']),
};

GateInfo gateInfo(String id) => _info[id] ?? _info['health']!;

bool _locked(GateKind k) => k == GateKind.plus ? !PlusState.I.isPro : !BandState.I.bleUp;

// ============================================================
//  سکانی خۆڕایی: 3 لە ڕۆژێکدا
// ============================================================
class ScanQuota {
  ScanQuota._();
  static const int free = 3;
  static const String key = 'vexscans';

  static String _today() {
    final n = DateTime.now();
    return '${n.year}-${n.month}-${n.day}';
  }

  static int used() {
    final m = Account.I.readMap(key);
    if ('${m['d']}' != _today()) return 0;
    final n = m['n'];
    return n is num ? n.toInt() : 0;
  }

  static int left() => PlusState.I.isPro ? 999 : (free - used()).clamp(0, free).toInt();

  /// پێش هەر سکانێک بانگ بکە. `false` = ڕێگە نەدرا (Plus دەکرێتەوە).
  static bool take() {
    if (PlusState.I.isPro) return true;
    final u = used();
    if (u >= free) {
      toast('3 سکانی خۆڕاییی ئەمڕۆ تەواو بوون');
      final i = gateInfo('scan');
      PlusPage.open(title: i.title, desc: i.desc);
      return false;
    }
    Account.I.writeMap(key, {'d': _today(), 'n': u + 1});
    final r = free - u - 1;
    toast(r > 0 ? '$r سکانی خۆڕایی ماوە ئەمڕۆ' : 'ئەمە دوایین سکانی خۆڕایی ئەمڕۆ بوو');
    return true;
  }
}

// ============================================================
//  پەردەی لێڵ
// ============================================================
class GateVeil extends StatelessWidget {
  const GateVeil({super.key, required this.kind, required this.id, this.compact = false, this.onAlt});
  final GateKind kind;
  final String id;
  final bool compact;
  final VoidCallback? onAlt;

  bool get _plus => kind == GateKind.plus;

  void _cta() {
    if (_plus) {
      final i = gateInfo(id);
      PlusPage.open(title: i.title, desc: i.desc);
    } else {
      showBandShop();
    }
  }

  Widget _icon() {
    final size = compact ? 58.0 : 76.0;
    return SizedBox(
      width: size + 10,
      height: size + 10,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          if (_plus)
            Container(
              width: size,
              height: size,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [op(_gold2, 0.34), op(_gold2, 0.08)],
                ),
                border: Border.all(color: op(_gold2, 0.8), width: 1.5),
                boxShadow: [BoxShadow(color: op(_gold2, 0.35), blurRadius: 22, spreadRadius: -4)],
              ),
              child: svgIcon(
                '<path d="M12 3l2.7 5.6 6.1.9-4.4 4.3 1 6.1L12 17l-5.4 2.9 1-6.1L3.2 9.5l6.1-.9z"/>',
                '#ffe29a',
                size: size * 0.46,
                fill: true,
              ),
            )
          else
            BandEmblem(size: size),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: 26,
              height: 26,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: V.surf2,
                border: Border.all(color: op(_plus ? _gold2 : V.cy, 0.7), width: 1.5),
              ),
              child: svgIcon(
                '<rect x="5" y="11" width="14" height="9" rx="2"/><path d="M8 11V8a4 4 0 0 1 8 0v3"/>',
                _plus ? '#ffbf47' : '#2fe6f3',
                size: 13,
                stroke: 2.2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _perk(String t) {
    final c = _plus ? _gold2 : V.mint;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Container(
            width: 18,
            height: 18,
            alignment: Alignment.center,
            decoration: BoxDecoration(shape: BoxShape.circle, color: op(c, 0.16)),
            child: svgIcon('<path d="M5 12.5l4.5 4.5L19 7.5"/>', _plus ? '#ffbf47' : '#3cf08a', size: 11, stroke: 3),
          ),
          const SizedBox(width: 9),
          Expanded(child: VText(t, style: ku(12.5, w: FontWeight.w600, c: V.tx, h: 1.5))),
        ],
      ),
    );
  }

  Widget _primary(String label) {
    return Press(
      onTap: _cta,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
        decoration: BoxDecoration(
          gradient: _plus ? LinearGradient(colors: [_gold1, _gold2, _gold3]) : V.prime,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: op(_plus ? _gold2 : V.mint, 0.4), blurRadius: 18, offset: const Offset(0, 8), spreadRadius: -8)],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: VText(label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: ku(14, w: FontWeight.w800, c: _plus ? _brown : V.ink, h: 1.3)),
            ),
            if (_plus) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: _brown, borderRadius: BorderRadius.circular(99)),
                child: VText('٥٠٪ داشکان', style: ku(10.5, w: FontWeight.w800, c: _gold1, h: 1.5)),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _link(String label, VoidCallback on) => Press(
        onTap: on,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          child: VText(label, style: ku(12.5, w: FontWeight.w700, c: _plus ? _gold2 : V.c2, h: 1.4)),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final i = gateInfo(id);
    final alt = i.alt;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 340),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            padding: EdgeInsets.fromLTRB(18, compact ? 12 : 16, 18, compact ? 6 : 8),
            decoration: BoxDecoration(
              color: op(V.surf, 0.78),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: op(_plus ? _gold2 : V.cy, 0.35)),
              boxShadow: [BoxShadow(color: vk(0x55000000), blurRadius: 30, offset: const Offset(0, 14), spreadRadius: -12)],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(child: _icon()),
                const SizedBox(height: 4),
                VText(
                  i.title,
                  textAlign: TextAlign.center,
                  style: ku(compact ? 15.5 : 17.5, w: FontWeight.w800, c: V.tx, h: 1.5),
                ),
                const SizedBox(height: 4),
                VText(i.desc, textAlign: TextAlign.center, style: ku(12.5, c: V.mu, h: 1.75)),
                if (!compact) ...[
                  const SizedBox(height: 10),
                  for (final p in i.perks) _perk(p),
                ],
                SizedBox(height: compact ? 10 : 14),
                _primary(_plus ? 'VEX Plus چالاک بکە' : 'VEX Band بکڕە'),
                Center(
                  child: alt != null && onAlt != null
                      ? _link(alt, onAlt!)
                      : (_plus ? const SizedBox(height: 8) : _link('Band ـم هەیە، پەیوەستی بکە', showBandPair)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
//  بەشێک لەناو پەڕەیەک: لێڵ + پەردە تا بکڕدرێت
// ============================================================
class Gated extends StatelessWidget {
  const Gated({
    super.key,
    required this.kind,
    required this.id,
    required this.child,
    this.minHeight = 0,
    this.compact = true,
    this.onAlt,
  });
  final GateKind kind;
  final String id;
  final Widget child;
  final double minHeight;
  final bool compact;
  final VoidCallback? onAlt;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([PlusState.I, BandState.I]),
      builder: (context, _) {
        if (!_locked(kind)) return child;
        return Stack(
          children: [
            ConstrainedBox(
              constraints: BoxConstraints(minHeight: minHeight),
              child: Align(alignment: Alignment.topCenter, child: GateBlur(child: child)),
            ),
            Positioned.fill(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: GateVeil(kind: kind, id: id, compact: compact, onAlt: onAlt),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ============================================================
//  پەڕەی تەواو: لێڵ + پەردە + دوگمەی داخستن
// ============================================================
class GatePage extends StatefulWidget {
  const GatePage({super.key, required this.kind, required this.id, required this.child, this.onAlt, this.closable = true});
  final GateKind kind;
  final String id;
  final Widget child;
  final VoidCallback? onAlt;

  /// false = ناو تابەکانی ئەپ (دوگمەی داخستن نییە و پەردەکە لە سەرووی شریتی خوارەوە دەوەستێت)
  final bool closable;

  @override
  State<GatePage> createState() => _GatePageState();
}

class _GatePageState extends State<GatePage> {
  // GlobalKey: کاتێک پەردە لادەچێت، دۆخی پەڕەکە (سکرۆڵ، تاب…) ناشێوێت
  final GlobalKey _k = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([PlusState.I, BandState.I]),
      builder: (context, _) {
        final inner = KeyedSubtree(key: _k, child: widget.child);
        if (!_locked(widget.kind)) return inner;
        final mq = MediaQuery.of(context);
        return Scaffold(
          backgroundColor: V.bg,
          body: Stack(
            children: [
              Positioned.fill(child: GateBlur(sigma: 9, opacity: 0.5, child: inner)),
              Positioned.fill(child: ColoredBox(color: op(V.bg, 0.35))),
              Positioned.fill(
                child: SafeArea(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(18, 20, 18, widget.closable ? 20 : 110),
                      child: GateVeil(kind: widget.kind, id: widget.id, onAlt: widget.onAlt),
                    ),
                  ),
                ),
              ),
              if (widget.closable)
              PositionedDirectional(
                top: mq.padding.top + 10,
                start: 14,
                child: Press(
                  onTap: () => Navigator.of(context).maybePop(),
                  child: Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: op(V.surf, 0.85), border: Border.all(color: V.line)),
                    child: svgIcon('<path d="M18 6L6 18M6 6l12 12"/>', '#9cc4cb', size: 18, stroke: 2.4),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// پەڕەی کۆدی ئەندازیاری: لێڵکردنی ناوەڕۆکی قوفڵکراو
class GateBlur extends StatelessWidget {
  const GateBlur({super.key, required this.child, this.sigma = 6, this.opacity = 0.55});
  final Widget child;
  final double sigma;
  final double opacity;

  @override
  Widget build(BuildContext context) => BandBlur(sigma: sigma, opacity: opacity, child: child);
}
