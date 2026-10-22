// VEX Health — پرۆفایل (هەمان دیزاینی وێب) + چوونە دەرەوە
// چوونە دەرەوە: هەژمارەکە لەسەر ئەم مۆبایلە دەمێنێتەوە؛ کاتێک بە هەمان ژمارە دێیتەوە، هەموو داتاکانت دەگەڕێتەوە.
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../alerts/alerts_sheets.dart';
import '../alerts/band_alerts.dart';
import '../alerts/prayer_calc.dart';
import '../band/band_emblem.dart';
import '../band/device_page.dart';
import '../band/band_state.dart';
import '../band/band_test_tile.dart';
import '../core/icons.dart';
import '../core/theme.dart';
import '../family/family_page.dart';
import '../food/food_page.dart';
import '../health/hc.dart' show pushPage;
import '../notify/step_notify_tile.dart';
import '../plus/plus_page.dart';
import '../plus/plus_state.dart';
import 'account.dart';
import 'reg_lang_state.dart';
import 'reg_data.dart';
import 'reg_widgets.dart';
import '../plus/gate.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key, this.onTab});

  /// گۆڕینی تابی خوارەوە: 2 = VEX AI، 3 = وەرزش
  final ValueChanged<int>? onTab;

  static const String _kArena = 'VEX Arena بەم زووانە دەکرێتەوە';

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    return ListenableBuilder(
      listenable: Account.I,
      builder: (context, _) {
        final u = Account.I.user ?? const <String, dynamic>{};
        final name = Account.I.name;
        final phone = cleanPhone('${u['phone'] ?? ''}');
        final h = asD(u['h']);
        final w = asD(u['w']);
        final goal = u.isEmpty ? 0 : kcalGoalFor(u);
        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(16, mq.padding.top + 14, 16, mq.padding.bottom + 120),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Rise(child: VText('پرۆفایل', style: ku(24, w: FontWeight.w800, h: 1.5))),
                  Rise(
                    delayMs: 50,
                    child: _Hero(
                      name: name,
                      initial: Account.I.initial,
                      phone: phone,
                      weight: w,
                      height: h,
                      goal: goal,
                    ),
                  ),
                  Rise(delayMs: 80, child: _PlusCard()),
                  Rise(delayMs: 100, child: _BandCard()),
                  Rise(
                    delayMs: 150,
                    child: _Group('کۆمەڵایەتی', [
                      _RowItem('🏆', vk(0xFFFFBE4D), 'VEX Arena', 'پێشبڕکێی تەندروستی و خەڵات',
                          onTap: () => toast(_kArena)),
                      _RowItem('👨‍👩‍👧', vk(0xFF9B7BFF), 'بازنەی خێزان و هاوڕێ', 'چاودێری و هاندانی یەکتر',
                          onTap: () => pushPage(const GatePage(kind: GateKind.plus, id: 'family', child: FamilyPage()))),
                    ]),
                  ),
                  Rise(
                    delayMs: 200,
                    child: _Group('تەندروستی', [
                      _RowItem('🍽️', V.mint, 'خواردن و پلانی AI', 'ئامانجی کالۆری، ژەمەکان، ئاو',
                          onTap: () => openFoodPage()),
                      _RowItem('🏃', V.cy, 'وەرزش', 'ڕاکردن، پیاسە، پایسکل', onTap: () => onTab?.call(3)),
                      _RowItem('🌙', V.violet, 'خەو', 'قۆناغەکانی خەو و کوالیتی',
                          onTap: () => toast('بەشی خەو بەم زووانە دەکرێتەوە')),
                      _RowItem('✨', vk(0xFF4D6BFF), 'VEX AI', 'پرسیار لە یاریدەدەری تەندروستی',
                          onTap: () => onTab?.call(2)),
                    ]),
                  ),
                  Rise(delayMs: 220, child: const _AlertsGroup()),
                  Rise(delayMs: 235, child: const _ThemeCard()),
                  Rise(
                    delayMs: 250,
                    child: _Group('ڕێکخستنەکان', [
                      _SwitchRow('notif', '🔔', vk(0xFFFF9466), 'ئاگادارکردنەوەکان', 'بیرخستنەوەی ئاو، جووڵە و خەو'),
                      _SwitchRow('fam', '🛡️', vk(0xFF9B7BFF), 'ئاگاداری بۆ خێزان', 'ئەگەر دڵ یان SpO₂ نائاسایی بوو'),
                      _SwitchRow('vib', '📳', vk(0xFF2FE6F3), 'لەرینەوەی Band', 'کاتی ئاگادارکردنەوە'),
                    ], tail: [
                      _RowItem('🌐', V.mint, 'زمان', kIsEn ? 'English' : (kIsBd ? 'کوردی بادینی' : (kIsAr ? 'العربية' : (kIsFa ? 'فارسی' : (kIsTr ? 'Türkçe' : 'کوردی (سۆرانی)')))),
                          onTap: () => _pickLanguage()),
                      _RowItem('🚑', V.coral, 'فریاکەوتن', 'پەیوەندی بە 122', onTap: _callEmergency),
                    ]),
                  ),
                  const StepNotifyTile(),
                  const BandTestTile(),
                  const SizedBox(height: 18),
                  Press(
                    onTap: () => _confirmLogout(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        color: vk(0x14FF5F7E),
                        border: Border.all(color: vk(0x59FF5F7E)),
                      ),
                      child: VText('🚪 چوونە دەرەوە', style: ku(15, w: FontWeight.w800, c: vk(0xFFFF8A9D))),
                    ),
                  ),
                  const SizedBox(height: 10),
                  VText(
                    'هەژمارەکەت لەسەر ئەم مۆبایلە دەمێنێتەوە. کاتێک دووبارە بە هەمان ژمارە دێیتەوە، هەموو داتاکانت دەگەڕێتەوە.',
                    textAlign: TextAlign.center,
                    style: ku(11.5, c: RC.dim, h: 1.7),
                  ),
                  const SizedBox(height: 14),
                  VText('VEX Health · وەشانی 1.0', textAlign: TextAlign.center, style: ku(11, c: V.mu)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// هەڵبژاردنی زمانی ئەپ: کوردی (سۆرانی)، کوردی بادینی، عەرەبی یان English
  static void _pickLanguage() {
    showVSheet<void>(
      builder: (c) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Center(child: Text('🌐', style: TextStyle(fontSize: 40))),
          const SizedBox(height: 6),
          // ناوی دوو زمانەکە هەمیشە بە زمانی خۆیان دەنووسرێن (بەبێ وەرگێڕان)
          Text('Language · زمان', textAlign: TextAlign.center, style: ku(18, w: FontWeight.w800, h: 1.5)),
          const SizedBox(height: 14),
          for (final o in const [['en', 'English', 'English'], ['ckb', 'کوردی (سۆرانی)', 'Kurdish (Sorani)'], ['kmr', 'کوردی بادینی', 'Kurdish (Badini)'], ['ar', 'العربية', 'Arabic'], ['fa', 'فارسی', 'Persian'], ['tr', 'Türkçe', 'Turkish']])
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Press(
                onTap: () {
                  Navigator.of(c).pop();
                  LangState.I.set(o[0]);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: LangState.I.code == o[0] ? vk(0x2A2FE6F3) : vk(0x0EFFFFFF),
                    border: Border.all(color: LangState.I.code == o[0] ? V.cy : V.line),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(o[1],
                            textDirection: o[0] == 'en' ? TextDirection.ltr : TextDirection.rtl,
                            style: o[0] == 'en'
                                ? GoogleFonts.sora(fontSize: 15, fontWeight: FontWeight.w700, color: V.tx)
                                : GoogleFonts.notoSansArabic(fontSize: 15, fontWeight: FontWeight.w700, color: V.tx)),
                      ),
                      if (LangState.I.code == o[0]) Text('✓', style: TextStyle(fontSize: 18, color: V.cy)),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  static Future<void> _callEmergency() async {
    try {
      final ok = await launchUrl(Uri(scheme: 'tel', path: '122'));
      if (!ok) toast('نەتوانرا پەیوەندی بکرێت');
    } catch (_) {
      toast('نەتوانرا پەیوەندی بکرێت');
    }
  }

  void _confirmLogout(BuildContext context) {
    showVSheet<void>(
      builder: (c) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Center(child: VText('🚪', style: TextStyle(fontSize: 44))),
          const SizedBox(height: 6),
          VText('دڵنیایت دەتەوێت بچیتە دەرەوە؟', textAlign: TextAlign.center, style: ku(19, w: FontWeight.w800, h: 1.5)),
          const SizedBox(height: 6),
          VText(
            'داتاکانت پاشەکەوت دەکرێن. بۆ گەڕانەوە، «پێشتر هەژمارم هەیە» دابگرە و هەمان ژمارە بنووسە.',
            textAlign: TextAlign.center,
            style: ku(13, c: V.mu, h: 1.8),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: VBtn('بەڵێ، چوونە دەرەوە', kind: BtnKind.prime, onTap: () async {
                  Navigator.of(c).pop();
                  await Account.I.logout();
                }),
              ),
              const SizedBox(width: 10),
              Expanded(child: VBtn('نەخێر', onTap: () => Navigator.of(c).pop())),
            ],
          ),
        ],
      ),
    );
  }
}

// ============================================================
// سەرەوە: ئەڤاتار، ناو، پلە و چوار پێوەرەکە
// ============================================================
class _Hero extends StatelessWidget {
  const _Hero({
    required this.name,
    required this.initial,
    required this.phone,
    required this.weight,
    required this.height,
    required this.goal,
  });
  final String name;
  final String initial;
  final String phone;
  final double weight;
  final double height;
  final int goal;

  String get _sub {
    if (phone.length >= 10) {
      return ltr('+964 ${phone.substring(0, 3)} ••• ${phone.substring(6)}');
    }
    return 'ئەندامی VEX Health';
  }

  @override
  Widget build(BuildContext context) {
    return VCard(
      padding: const EdgeInsets.fromLTRB(14, 22, 14, 14),
      child: Column(
        children: [
          SizedBox(
            width: 92,
            height: 92,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: SweepGradient(
                      colors: [vk(0xFF2FE6F3), vk(0xFF3CF08A), vk(0xFF9B7BFF), vk(0xFF2FE6F3)],
                    ),
                    boxShadow: [BoxShadow(color: vk(0x472FE6F3), blurRadius: 26, spreadRadius: -6)],
                  ),
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: vk(0xFF062A35)),
                    child: VText(initial, style: nu(38, c: vk(0xFFEAFFFF), h: 1.2)),
                  ),
                ),
                Positioned(
                  left: 4,
                  bottom: 2,
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: V.mint,
                      border: Border.all(color: vk(0xFF062A35), width: 3),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          VText(name.isEmpty ? 'هەژماری من' : name,
              maxLines: 1, overflow: TextOverflow.ellipsis, style: ku(21, w: FontWeight.w800, h: 1.4)),
          const SizedBox(height: 2),
          VText(_sub, style: phone.length >= 10 ? nu(12, w: FontWeight.w600, c: V.mu) : ku(12, c: V.mu)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: vk(0x21FFBE4D),
              borderRadius: BorderRadius.circular(99),
              border: Border.all(color: vk(0x4DFFBE4D)),
            ),
            child: VText('🏆 VEX Arena · بەشداری بکە', style: ku(11.5, w: FontWeight.w800, c: V.amber, h: 1.4)),
          ),
          const SizedBox(height: 16),
          _Stats(weight: weight, height: height, goal: goal),
        ],
      ),
    );
  }
}

/// چوار پێوەر لە یەک ڕیز: ئایکۆن + ژمارە + یەکە + ناونیشان
class _Stats extends StatelessWidget {
  const _Stats({required this.weight, required this.height, required this.goal});
  final double weight;
  final double height;
  final int goal;

  static const String _scale =
      '<path d="M6 4h12l2 16H4z"/><path d="M9 9a3 3 0 0 1 6 0"/><path d="M12 9l1.6-2"/>';
  static const String _ruler =
      '<path d="M3 17L17 3l4 4L7 21z"/><path d="M7 13l2 2M10 10l2 2M13 7l2 2"/>';
  static const String _target =
      '<circle cx="12" cy="12" r="9"/><circle cx="12" cy="12" r="5"/><circle cx="12" cy="12" r="1.5"/>';

  @override
  Widget build(BuildContext context) {
    final tiles = <Widget>[
      _StatTile(icon: HI.fire, color: vk(0xFFFF9466), hex: '#ff9466', label: 'زنجیرە', value: '0', unit: 'ڕۆژ'),
      _StatTile(
          icon: _scale,
          color: V.cy,
          hex: '#2fe6f3',
          label: 'کێش',
          value: weight > 0 ? numTxt(weight) : '—',
          unit: weight > 0 ? 'kg' : ''),
      _StatTile(
          icon: _ruler,
          color: V.violet,
          hex: '#9b7bff',
          label: 'بەرزی',
          value: height > 0 ? numTxt(height) : '—',
          unit: height > 0 ? 'cm' : ''),
      _StatTile(
          icon: _target,
          color: V.mint,
          hex: '#3cf08a',
          label: 'ئامانج',
          value: goal > 0 ? fmt(goal) : '—',
          unit: goal > 0 ? 'kcal' : ''),
    ];
    return Row(
      children: [
        for (int i = 0; i < tiles.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(child: tiles[i]),
        ],
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.color,
    required this.hex,
    required this.label,
    required this.value,
    required this.unit,
  });
  final String icon;
  final Color color;
  final String hex;
  final String label;
  final String value;
  final String unit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(2, 12, 2, 11),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [op(color, 0.15), op(color, 0.03)],
        ),
        border: Border.all(color: mix(V.line, color, 0.26)),
        boxShadow: [BoxShadow(color: op(color, 0.18), blurRadius: 14, offset: const Offset(0, 6), spreadRadius: -8)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: op(color, 0.16),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: op(color, 0.3)),
            ),
            child: svgIcon(icon, hex, size: 16),
          ),
          const SizedBox(height: 7),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: VText(value, textDirection: TextDirection.ltr, maxLines: 1, style: nu(17, c: V.tx, h: 1.1)),
          ),
          if (unit.isNotEmpty) ...[
            const SizedBox(height: 3),
            VText(unit, textDirection: TextDirection.ltr, style: nu(9.5, c: color)),
          ],
          const SizedBox(height: 7),
          VText(label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: ku(10.5, w: FontWeight.w700, c: V.mu, h: 1.2)),
        ],
      ),
    );
  }
}

// ============================================================
// کارتی VEX Plus
// ============================================================
class _PlusCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: PlusState.I,
      builder: (context, _) {
        final S = PlusState.I;
        final pro = S.isPro;
        final light = VexTheme.I.isLight;
        final g1 = vk(0xFFFFE29A);
        final g2 = vk(0xFFFFBF47);
        // ڕووناک: کارتی زێڕینی پڕ + دەقی قاوەیی تۆخ؛ تاریک: زێڕی شەفاف + دەقی زێڕین
        final cTitle = light ? vk(0xFF3B2500) : g1;
        final cSub = light ? vk(0xFF5E3A00) : vk(0xFFD9BF85);
        final String title = pro ? 'VEX Plus' : 'VEX Plus بکەرەوە';
        final String sub = pro
            ? (S.src == 'trial'
                ? 'تاقیکردنەوە · ${S.daysLeft} ڕۆژ ماوە'
                : S.src == 'band'
                    ? 'دیاری Band · تا ${S.untilText}'
                    : 'چالاکە · تا ${S.untilText}')
            : (S.canTrial ? '7 ڕۆژ بە خۆڕایی · 50٪ داشکان' : '50٪ داشکان لەسەر هەموو پلانەکان');
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Press(
            onTap: () => PlusPage.open(),
            scale: 0.98,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                gradient: LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  colors: light ? [vk(0xFFFFE7A3), vk(0xFFFFC857)] : [op(g2, 0.22), op(g2, 0.05)],
                ),
                border: Border.all(color: light ? vk(0xFFD9A23C) : op(g2, 0.5)),
                boxShadow: [BoxShadow(color: op(g2, light ? 0.35 : 0.3), blurRadius: 26, offset: const Offset(0, 12), spreadRadius: -14)],
              ),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      gradient: light ? null : LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [vk(0xFFFFE9A8), g2, vk(0xFFFF9D3D)]),
                      color: light ? vk(0xFF3B2500) : null,
                    ),
                    child: VText('✦', style: TextStyle(fontSize: 22, color: light ? vk(0xFFFFD36B) : vk(0xFF3B2500), height: 1.1)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        VText(title, style: ku(15, w: FontWeight.w800, c: cTitle, h: 1.5)),
                        VText(sub, style: ku(11.5, c: cSub, h: 1.5)),
                      ],
                    ),
                  ),
                  if (!pro)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(99),
                        gradient: LinearGradient(colors: [vk(0xFFFF5F5F), vk(0xFFFF9D3D)]),
                      ),
                      child: VText('−50٪', textDirection: TextDirection.ltr, style: nu(11, c: Colors.white)),
                    )
                  else
                    VText('بەڕێوەبردن', style: ku(12, w: FontWeight.w700, c: cTitle)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ============================================================
// کارتی Band
// ============================================================
class _BandCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: BandState.I,
      builder: (context, _) {
        final on = BandState.I.connected;
        return Press(
          onTap: () {
            pushPage(const DevicePage());
          },
          scale: 0.98,
          child: VCard(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                      colors: [vk(0x332FE6F3), vk(0x1F3CF08A)],
                    ),
                    border: Border.all(color: V.line2),
                  ),
                  child: const BandEmblem(size: 46),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      VText('VEX Band V8', style: nu(15, h: 1.4)),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: on ? V.mint : V.coral,
                              boxShadow: on ? [BoxShadow(color: V.mint, blurRadius: 8)] : null,
                            ),
                          ),
                          const SizedBox(width: 6),
                          VText(on ? 'پەیوەستە · پاتری 25%' : 'پەیوەست نییە · بۆ پەیوەستکردنەوە دایبگرە',
                              style: ku(12, c: V.mu, h: 1.5)),
                        ],
                      ),
                    ],
                  ),
                ),
                VText('‹', style: ku(18, c: V.mu)),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ============================================================
// گرووپ و ڕیزەکان
// ============================================================
class _Group extends StatelessWidget {
  const _Group(this.title, this.items, {this.tail = const []});
  final String title;
  final List<Widget> items;
  final List<Widget> tail;

  @override
  Widget build(BuildContext context) {
    final all = [...items, ...tail];
    return Padding(
      padding: const EdgeInsets.only(top: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
            child: VText(title, style: ku(12, w: FontWeight.w800, c: V.mu)),
          ),
          Container(
            decoration: BoxDecoration(
              color: V.surf,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: V.line),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(21),
              child: Column(
                children: [
                  for (int i = 0; i < all.length; i++) ...[
                    if (i > 0) Divider(height: 1, thickness: 1, color: V.line),
                    all[i],
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RowBody extends StatelessWidget {
  const _RowBody({required this.emoji, required this.color, required this.title, required this.sub, required this.trailing});
  final String emoji;
  final Color color;
  final String title;
  final String sub;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: op(color, 0.16), borderRadius: BorderRadius.circular(12)),
            child: VText(emoji, style: const TextStyle(fontSize: 19)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                VText(title, style: ku(14, w: FontWeight.w700, h: 1.5)),
                VText(sub, style: ku(11.5, w: FontWeight.w600, c: V.mu, h: 1.6)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          trailing,
        ],
      ),
    );
  }
}

class _RowItem extends StatelessWidget {
  const _RowItem(this.emoji, this.color, this.title, this.sub, {required this.onTap});
  final String emoji;
  final Color color;
  final String title;
  final String sub;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Press(
      onTap: onTap,
      scale: 0.99,
      child: _RowBody(
        emoji: emoji,
        color: color,
        title: title,
        sub: sub,
        trailing: VText('‹', style: ku(18, c: V.mu)),
      ),
    );
  }
}

/// ڕیزی سویچ؛ هەڵبژاردنەکە لەسەر مۆبایل دەمێنێتەوە
class _SwitchRow extends StatefulWidget {
  const _SwitchRow(this.k, this.emoji, this.color, this.title, this.sub);
  final String k;
  final String emoji;
  final Color color;
  final String title;
  final String sub;

  @override
  State<_SwitchRow> createState() => _SwitchRowState();
}

class _SwitchRowState extends State<_SwitchRow> {
  bool on = true;
  SharedPreferences? _sp;

  String get _key => 'vex_pref_${widget.k}';

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((sp) {
      _sp = sp;
      final v = sp.getBool(_key);
      if (v != null && mounted) setState(() => on = v);
    }).catchError((_) {});
  }

  void _toggle() {
    setState(() => on = !on);
    _sp?.setBool(_key, on);
  }

  @override
  Widget build(BuildContext context) {
    return Press(
      onTap: _toggle,
      scale: 0.99,
      child: _RowBody(
        emoji: widget.emoji,
        color: widget.color,
        title: widget.title,
        sub: widget.sub,
        trailing: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          width: 46,
          height: 28,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(color: on ? V.mint : V.track, borderRadius: BorderRadius.circular(99)),
          child: AnimatedAlign(
            duration: const Duration(milliseconds: 250),
            alignment: on ? AlignmentDirectional.centerEnd : AlignmentDirectional.centerStart,
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: kW,
                boxShadow: [BoxShadow(color: vk(0x4D000000), blurRadius: 6, offset: Offset(0, 2))],
              ),
            ),
          ),
        ),
      ),
    );
  }
}


// ============================================================
// ئاگادارکەرەوەی Band (لەرین): کاتژمێر · کاتی وەرزش · نوێژ
// ============================================================
class _AlertsGroup extends StatelessWidget {
  const _AlertsGroup();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: BandAlerts.I,
      builder: (context, _) {
        final A = BandAlerts.I;
        final n = A.alarms.where((x) => x.on).length;
        var prayerSub = 'چالاک نییە · ئارەزوومەندانە';
        if (A.prayerOn) {
          final nx = A.nextPrayer();
          final mins = nx.at.hour * 60 + nx.at.minute;
          prayerSub = 'داهاتوو: ${prayerShort(nx.key)} · ${fmt12(mins ~/ 60, mins % 60)} ${ampm(mins ~/ 60)}';
        }
        return _Group('ئاگادارکەرەوەی Band (لەرین)', [
          _RowItem('⏰', V.cy, 'کاتژمێری لەرین', n > 0 ? '$n کاتژمێر چالاکە' : 'کاتژمێری لەرین دابنێ',
              onTap: openAlarmSheet),
          _RowItem('⏱️', V.orange, 'کاتی وەرزش',
              A.timerRunning ? 'ئێستا کار دەکات…' : 'کاتی کەمبوونەوە بە میلی چرکە',
              onTap: openTimerSheet),
          _RowItem('🕌', V.mint, 'کاتەکانی نوێژ', prayerSub, onTap: openPrayerSheet),
        ]);
      },
    );
  }
}


// ============================================================
// دۆخی ڕەنگ: خۆکار / ڕووناک / تاریک
// ============================================================
class _ThemeCard extends StatelessWidget {
  const _ThemeCard();

  @override
  Widget build(BuildContext context) {
    return VCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          VText('ڕووکار', style: ku(14, w: FontWeight.w800, h: 1.5)),
          const SizedBox(height: 2),
          VText('«خۆکار» لەگەڵ ڕۆژ و شەوی مۆبایلەکەت دەگۆڕێت', style: ku(11.5, c: V.mu, h: 1.6)),
          const SizedBox(height: 12),
          const ThemeModePicker(labels: ['خۆکار', 'ڕووناک', 'تاریک']),
        ],
      ),
    );
  }
}
