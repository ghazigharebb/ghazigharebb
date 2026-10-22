// VEX Health — هەڵبژاردنی زمان (20 زمان) و پرسیاری «VEX Band ت هەیە؟»
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/theme.dart';
import 'reg_icons.dart';
import 'reg_lang_data.dart';
import 'reg_lang_state.dart';
import 'reg_widgets.dart';

/// دەقی گونجاو بۆ زمانەکە: عەرەبی/کوردی/فارسی/ئوردو بە فۆنتی عەرەبی، ئەوانی تر بە Noto Sans
TextStyle langStyle(RLang l, double size, {FontWeight w = FontWeight.w400, Color? c, double? h}) { c ??= V.tx; return
    l.rtl ? GoogleFonts.notoSansArabic(fontSize: size, fontWeight: w, color: c, height: h) : GoogleFonts.notoSans(fontSize: size, fontWeight: w, color: c, height: h); }

/// ئاڵا لەناو بازنەیەک؛ ئاڵای کوردستان دەکێشرێت (ئیمۆجی نییە)
class RFlag extends StatelessWidget {
  const RFlag(this.l, {super.key, this.size = 44, this.on = false});
  final RLang l;
  final double size;
  final bool on;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: RC.white(0.07),
        border: Border.all(color: on ? V.mint : RC.white(0.14), width: 1.5),
        boxShadow: on ? [BoxShadow(color: op(V.mint, 0.5), blurRadius: 14, spreadRadius: -4)] : null,
      ),
      child: ClipOval(
        child: l.flag == 'KU'
            ? SvgPicture.string(kKuFlagSvg, width: size, height: size, fit: BoxFit.cover)
            : Center(child: VText(l.flag, style: TextStyle(fontSize: size * 0.58, height: 1))),
      ),
    );
  }
}

/// دوگمەی بچووکی زمان لە سەرەوەی بەخێرهاتن
class RLangChip extends StatelessWidget {
  const RLangChip({super.key, required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = LangState.I.cur;
    return Semantics(
      button: true,
      label: l.native,
      child: Press(
        onTap: onTap,
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Container(
            padding: const EdgeInsets.fromLTRB(7, 6, 13, 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(99),
              color: RC.white(0.06),
              border: Border.all(color: RC.line(0.2)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                RFlag(l, size: 24),
                const SizedBox(width: 8),
                Text(l.native, style: langStyle(l, 12.5, w: FontWeight.w700)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// =====================================================================
//  هەنگاوی هەڵبژاردنی زمان
// =====================================================================
class RLangStep extends StatefulWidget {
  const RLangStep({super.key, required this.picked, required this.onPick, this.compact = false});
  final String picked;
  final ValueChanged<String> onPick;
  final bool compact;

  @override
  State<RLangStep> createState() => _RLangStepState();
}

class _RLangStepState extends State<RLangStep> {
  Timer? _t;
  int _hi = 0;

  @override
  void initState() {
    super.initState();
    _t = Timer.periodic(const Duration(milliseconds: 1800), (_) {
      if (mounted) setState(() => _hi = (_hi + 1) % kLangs.length);
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final L = langOf(widget.picked);
    final hl = kLangs[_hi];
    final c = widget.compact;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: c ? 2 : 8),
          // «سڵاو» بە هەموو زمانەکان دەخولێتەوە
          SizedBox(
            height: c ? 54 : 66,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 380),
              transitionBuilder: (child, anim) => FadeTransition(
                opacity: anim,
                child: SlideTransition(
                  position: Tween<Offset>(begin: const Offset(0, 0.25), end: Offset.zero).animate(anim),
                  child: child,
                ),
              ),
              child: Center(
                key: ValueKey<int>(_hi),
                child: Directionality(
                  textDirection: dirOfLang(hl),
                  child: ShaderMask(
                    shaderCallback: (r) => LinearGradient(
                      colors: [vk(0xFF8FF3F9), vk(0xFF3CF08A), vk(0xFFFFE29A)],
                    ).createShader(r),
                    blendMode: BlendMode.srcIn,
                    child: VText(
                      hl.t['hello'] ?? '',
                      maxLines: 1,
                      style: langStyle(hl, c ? 36 : 44, w: FontWeight.w800, c: kW, h: 1.3),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Directionality(
            textDirection: dirOfLang(L),
            child: Column(
              children: [
                VText(L.t['pick'] ?? '',
                    textAlign: TextAlign.center, style: langStyle(L, 21, w: FontWeight.w800, h: 1.5)),
                const SizedBox(height: 2),
                VText(L.t['pickSub'] ?? '',
                    textAlign: TextAlign.center, style: langStyle(L, 13, c: RC.p, h: 1.7)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, cons) {
              final w = (cons.maxWidth - 9) / 2;
              return Wrap(
                spacing: 9,
                runSpacing: 9,
                children: [
                  for (int i = 0; i < kLangs.length; i++)
                    SizedBox(
                      width: w,
                      child: Rise(
                        delayMs: 30 + i * 28,
                        child: _LangCard(l: kLangs[i], on: kLangs[i].code == widget.picked, onTap: () => widget.onPick(kLangs[i].code)),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _LangCard extends StatelessWidget {
  const _LangCard({required this.l, required this.on, required this.onTap});
  final RLang l;
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: on,
      label: '${l.native} ${l.english}',
      child: Press(
        onTap: onTap,
        scale: 0.97,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 11),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: on ? V.mint : RC.line(0.13), width: 1.5),
            gradient: on
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0x218FF3F9), Color(0x1F3CF08A)],
                  )
                : LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [RC.white(0.055), RC.white(0.02)],
                  ),
            boxShadow: on
                ? [BoxShadow(color: vk(0x663CF08A), blurRadius: 26, offset: Offset(0, 12), spreadRadius: -16)]
                : null,
          ),
          child: Directionality(
            textDirection: dirOfLang(l),
            child: Row(
              children: [
                RFlag(l, size: 42, on: on),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(l.native, maxLines: 2, style: langStyle(l, 13.5, w: FontWeight.w800, h: 1.4)),
                      Directionality(
                        textDirection: TextDirection.ltr,
                        child: VText(l.english, maxLines: 1, overflow: TextOverflow.ellipsis, style: nu(10.5, w: FontWeight.w600, c: vk(0xFF7FA6AD), h: 1.4)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                RCheck(on: on),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// =====================================================================
//  «VEX Band ت هەیە؟» — بە وێنەی Band ی ڕەشی خۆمان
// =====================================================================
class RBandQ extends StatelessWidget {
  const RBandQ({super.key, required this.has, required this.onPick, this.compact = false, this.tight = false});
  final bool? has;
  final ValueChanged<bool> onPick;
  final bool compact;
  final bool tight;

  @override
  Widget build(BuildContext context) {
    final l = LangState.I.cur;
    final t = l.t;
    final yp = (t['yesp'] ?? '').split('+');
    final sub = yp.first.trim();
    final gift = yp.last.trim();
    final heroH = tight ? 150.0 : (compact ? 190.0 : 232.0);
    return Directionality(
      textDirection: dirOfLang(l),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: heroH,
              child: Directionality(
                textDirection: TextDirection.ltr,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: heroH * 0.92,
                      height: heroH * 0.92,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [vk(0x5C2FE6F3), vk(0x1A3CF08A), vk(0x002FE6F3)],
                          stops: [0, 0.55, 0.74],
                        ),
                      ),
                    ),
                    Container(
                      width: heroH * 0.86,
                      height: heroH * 0.86,
                      decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: vk(0x4D8FF3F9))),
                    ),
                    Container(
                      width: heroH * 1.02,
                      height: heroH * 1.02,
                      decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: vk(0x2E3CF08A))),
                    ),
                    Image.asset(
                      'assets/brand/vex_band.webp',
                      height: heroH * 0.78,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => RBandArt(size: heroH * 0.8),
                    ),
                    Align(alignment: const Alignment(0.98, -0.78), child: _fc('❤️', '72', 'BPM')),
                    Align(alignment: const Alignment(-0.98, 0.34), child: _fc('💧', '98%', 'SpO₂')),
                    Align(alignment: const Alignment(0.74, 0.96), child: _fc('🌙', '7h 20m', '')),
                  ],
                ),
              ),
            ),
            SizedBox(height: tight ? 6 : 10),
            VText(t['bt'] ?? '',
                textAlign: TextAlign.center, style: langStyle(l, tight ? 21 : (compact ? 23 : 26), w: FontWeight.w800, h: 1.4)),
            Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 16),
              child: VText(t['bp'] ?? '', textAlign: TextAlign.center, style: langStyle(l, 13.5, c: RC.p, h: 1.7)),
            ),
            _BandOpt(
              l: l,
              art: Image.asset(
                'assets/brand/vex_band.webp',
                height: 44,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const RIco('⌚', size: 44),
              ),
              title: t['yes'] ?? '',
              sub: sub,
              ribbon: gift,
              on: has == true,
              onTap: () => onPick(true),
            ),
            const SizedBox(height: 11),
            _BandOpt(
              l: l,
              art: const RIco('📱', size: 54),
              title: t['no'] ?? '',
              sub: t['nop'] ?? '',
              on: has == false,
              onTap: () => onPick(false),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fc(String e, String v, String u) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(99),
          color: vk(0xE60A2E38),
          border: Border.all(color: RC.line(0.22)),
          boxShadow: [BoxShadow(color: vk(0x66000000), blurRadius: 14, offset: Offset(0, 6), spreadRadius: -6)],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            RIco(e, size: 14, tile: false),
            const SizedBox(width: 6),
            VText(v, style: nu(13, h: 1.2)),
            if (u.isNotEmpty) ...[
              const SizedBox(width: 4),
              VText(u, style: nu(9.5, w: FontWeight.w700, c: RC.mu, h: 1.2)),
            ],
          ],
        ),
      );
}

class _BandOpt extends StatelessWidget {
  const _BandOpt({required this.l, required this.art, required this.title, required this.sub, required this.on, required this.onTap, this.ribbon});
  final RLang l;
  final Widget art;
  final String title;
  final String sub;
  final String? ribbon;
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasR = ribbon != null && ribbon!.isNotEmpty;
    return Semantics(
      button: true,
      selected: on,
      label: title,
      child: Press(
        onTap: onTap,
        scale: 0.98,
        child: Padding(
          padding: EdgeInsets.only(top: hasR ? 12 : 0),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                width: double.infinity,
                padding: EdgeInsets.fromLTRB(14, hasR ? 34 : 16, 14, 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: on ? V.mint : RC.line(0.16), width: 1.5),
                  gradient: on
                      ? LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [vk(0x242FE6F3), vk(0x1F3CF08A)],
                        )
                      : LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [RC.white(0.06), RC.white(0.02)],
                        ),
                  boxShadow: on
                      ? [BoxShadow(color: vk(0x663CF08A), blurRadius: 34, offset: Offset(0, 16), spreadRadius: -18)]
                      : null,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        color: on ? vk(0x2E3CF08A) : RC.white(0.06),
                        border: Border.all(color: on ? vk(0x803CF08A) : vk(0x338FF3F9)),
                      ),
                      child: art,
                    ),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          VText(title, style: langStyle(l, 16, w: FontWeight.w800, h: 1.5)),
                          if (sub.isNotEmpty) VText(sub, style: langStyle(l, 12.5, c: RC.p, h: 1.65)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    RCheck(on: on),
                  ],
                ),
              ),
              if (hasR)
                PositionedDirectional(
                  top: -12,
                  end: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(99),
                      gradient: LinearGradient(colors: [vk(0xFFFFE29A), vk(0xFFFFBE4D), vk(0xFFFF9A4D)]),
                      boxShadow: [BoxShadow(color: vk(0x66FFBE4D), blurRadius: 18, offset: Offset(0, 8), spreadRadius: -6)],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        RIco('🎁', size: 14, tile: false, color: vk(0xFF3B2500)),
                        const SizedBox(width: 6),
                        VText(ribbon!, style: langStyle(l, 11.5, w: FontWeight.w800, c: vk(0xFF3B2500), h: 1.2)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
