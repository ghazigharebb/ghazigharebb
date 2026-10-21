// VEX Health — ئایکۆنە SVG ـەکانی بەشی سەرەتا (جێگەی ئیمۆجییەکان)
// ئەم فایلە لە ڕێگەی سکریپتەوە دروست کراوە؛ هەر ئیمۆجییەک بە ئایکۆنێکی گرادیێنت دەگۆڕدرێت.
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../core/theme.dart';

class RIcoDef {
  const RIcoDef(this.paths, this.color);
  final String paths;
  final int color;
}

String _rn(String s) => s.replaceAll('\uFE0F', '');

const Map<String, RIcoDef> _kRIcons = {
  '🛋': RIcoDef(r'''<path d="M20 10V7a2 2 0 0 0-2-2H6a2 2 0 0 0-2 2v3"/><path d="M2 13a2 2 0 0 1 4 0v2h12v-2a2 2 0 0 1 4 0v5a1 1 0 0 1-1 1H3a1 1 0 0 1-1-1z"/><path d="M5 19v2M19 19v2"/>''', 0xFF9B9FFF),
  '🚶': RIcoDef(r'''<circle cx="13" cy="4.5" r="1.8"/><path d="M9.5 21l2-6-2.5-2.5 1.5-4.5 3.500 1.500 2 3.500M12 15l2.500 2.500V21M10.500 8.500L8 11"/>''', 0xFF3CF08A),
  '🏃': RIcoDef(r'''<circle cx="14.500" cy="4.500" r="1.800"/><path d="M4 12l3.500-2 3.500 1 2 3-3 3.500-3.500 1M13 14.500l3 2 1 4M11 11l3.500-1.500 3 2.500 3-.5"/>''', 0xFFFFBE4D),
  '🏋': RIcoDef(r'''<path d="M6.500 6.500v11M17.500 6.500v11M3.500 9v6M20.500 9v6M6.500 12h11"/>''', 0xFFFF7A5C),
  '😴': RIcoDef(r'''<path d="M20 14.500A8.500 8.500 0 1 1 9.500 4a6.800 6.800 0 0 0 10.500 10.500z"/><path d="M15 4h3l-3 3.500h3"/>''', 0xFFB9A4FF),
  '🌙': RIcoDef(r'''<path d="M20 14.500A8.500 8.500 0 1 1 9.500 4a6.800 6.800 0 0 0 10.500 10.500z"/>''', 0xFFB9A4FF),
  '🧘': RIcoDef(r'''<path d="M12 3c2.800 2.800 4 5.600 4 8.500S14.500 17 12 20c-2.500-3-4-5.600-4-8.500S9.200 5.800 12 3z"/><path d="M3 11c3 0 5.500 1.300 7.200 4M21 11c-3 0-5.500 1.300-7.200 4"/>''', 0xFF6EE7B7),
  '👣': RIcoDef(r'''<path d="M7 3c2 0 3 2 3 4.500S9 11 7.500 11 4 10 4 7.500 5 3 7 3z"/><path d="M5 14.500h5V16a2.500 2.500 0 0 1-5 0zM17 9c2 0 3 2 3 4.500S19 17 17.500 17 14 16 14 13.500 15 9 17 9z"/><path d="M15 20h5"/>''', 0xFF2FE6F3),
  '❤': RIcoDef(r'''<path d="M12 20.500S4 15.500 4 9.800A4.300 4.300 0 0 1 12 7.600 4.300 4.300 0 0 1 20 9.800c0 5.700-8 10.700-8 10.700z"/>''', 0xFFFF5F7E),
  '💓': RIcoDef(r'''<path d="M3 12h4l2.500-6 4 12 2.500-6H21"/>''', 0xFFFF5F7E),
  '🩸': RIcoDef(r'''<path d="M12 3s6.500 6.500 6.500 11.200a6.500 6.500 0 0 1-13 0C5.500 9.500 12 3 12 3z"/><path d="M9 14.500a3 3 0 0 0 3 3"/>''', 0xFFFF5F7E),
  '🫀': RIcoDef(r'''<path d="M9.500 3h5M10.500 3v5.500L5.500 18a2 2 0 0 0 1.800 3h9.400a2 2 0 0 0 1.800-3l-5-9.500V3"/><path d="M8 15h8"/>''', 0xFFFF9466),
  '🫁': RIcoDef(r'''<path d="M12 4v9"/><path d="M12 8.500c-2.500 0-5.500 3-5.500 7 0 3 1.200 4 2.700 4S12 18 12 15.500"/><path d="M12 8.500c2.500 0 5.500 3 5.500 7 0 3-1.200 4-2.700 4S12 18 12 15.500"/>''', 0xFF2FE6F3),
  '🦋': RIcoDef(r'''<path d="M12 7v12"/><path d="M12 7C9.500 2.500 4.500 3 4.500 7.500c0 2.800 3 4 7.500 4.500"/><path d="M12 7c2.500-4.500 7.500-4 7.500.5 0 2.800-3 4-7.500 4.500"/><path d="M12 12c-3.500 0-5.500 2.500-4.500 5.500S11 19 12 15M12 12c3.500 0 5.500 2.500 4.500 5.500S13 19 12 15"/>''', 0xFFC4A1FF),
  '🫘': RIcoDef(r'''<path d="M8.500 4C5 4 3.500 7.500 4.500 11.500S7 20 10 20c2 0 3-1.500 3-3.500 0-1.500 1.800-2 3.200-3.300C19 10.500 18.500 7 15.500 5.200 13.500 4 10.500 4 8.500 4z"/>''', 0xFFFF8A5F),
  '🤰': RIcoDef(r'''<circle cx="11" cy="4.500" r="1.800"/><path d="M11 8c-2 0-3 1.800-3 4 0 1.800.8 3 1.800 4V21M11 8c3 0 4.500 2.800 3.800 5.500-.5 2-2 2.500-2 4.500"/><path d="M14.500 11.500c2 0 3 1.500 3 3"/>''', 0xFFFF8FC8),
  '🤱': RIcoDef(r'''<circle cx="9" cy="5" r="2"/><path d="M9 8.500c-2.500 0-4 2-4 4.500V21M9 8.500c2.500 0 5 1.500 5 4.500"/><path d="M5 16h9a4 4 0 0 0 4-4"/><circle cx="17.500" cy="15.500" r="1.800"/>''', 0xFFFF8FC8),
  '⚖': RIcoDef(r'''<path d="M12 3v18M6 21h12M5 7h14"/><path d="M5 7l-3 7.500a3.200 3.200 0 0 0 6 0zM19 7l-3 7.500a3.200 3.200 0 0 0 6 0z"/>''', 0xFF3CF08A),
  '💪': RIcoDef(r'''<path d="M12 22c4.200 0 7-3 7-7 0-3.300-2-5.300-3-7.500-1 2-2 3-3.200 3 .2-4-1-7-3.800-9.500 0 5.500-4 7.500-4 13 0 4.500 3 8 7 8z"/>''', 0xFFFF9466),
  '👨‍👩‍👧': RIcoDef(r'''<circle cx="9" cy="8" r="3.200"/><path d="M3 20c0-3.500 2.800-6 6-6s6 2.500 6 6"/><circle cx="17" cy="9.500" r="2.300"/><path d="M16.500 14.200c2.700-.2 4.800 1.600 4.800 4.800"/>''', 0xFFFF8FC8),
  '⚡': RIcoDef(r'''<path d="M13 2.500L4.500 13.500H11l-1 8 9-12h-6.500z"/>''', 0xFFFFD24D),
  '💧': RIcoDef(r'''<path d="M12 3s6 6 6 10.800a6 6 0 0 1-12 0C6 9 12 3 12 3z"/><path d="M9.500 14.500a2.700 2.700 0 0 0 2.500 2.500"/>''', 0xFF2FE6F3),
  '🔔': RIcoDef(r'''<path d="M6 16.500V11a6 6 0 0 1 12 0v5.500l2 2H4z"/><path d="M10 21.500a2 2 0 0 0 4 0"/>''', 0xFFFFBE4D),
  '⌚': RIcoDef(r'''<rect x="7" y="6.500" width="10" height="11" rx="3"/><path d="M9 6.500l.8-3.500h4.400l.8 3.500M9 17.500l.8 3.500h4.400l.8-3.500M12 10v2.500l1.600 1"/>''', 0xFF8FF3F9),
  '📱': RIcoDef(r'''<rect x="6.500" y="2.500" width="11" height="19" rx="3"/><path d="M10.500 18.500h3"/>''', 0xFF8FF3F9),
  '🧬': RIcoDef(r'''<circle cx="12" cy="8" r="3.800"/><path d="M4.500 20.500c0-4 3.300-6.800 7.500-6.800s7.500 2.800 7.500 6.800"/>''', 0xFF2FE6F3),
  '🎂': RIcoDef(r'''<path d="M4 20.500h16M5 20.500v-7a2 2 0 0 1 2-2h10a2 2 0 0 1 2 2v7M5 16c2.200 0 2.200 1.500 3.500 1.500S10 16 12 16s2 1.500 3.500 1.500S17 16 19 16M12 11.500V8M12 4.500c.9 1 .9 2.200 0 3-.9-.8-.9-2 0-3z"/>''', 0xFFFF8FC8),
  '📏': RIcoDef(r'''<path d="M3 16.500L16.500 3l4.500 4.500L7.500 21z"/><path d="M7.500 12.500l2 2M10.500 9.500l2 2M13.500 6.500l2 2"/>''', 0xFFFFBE4D),
  '🎯': RIcoDef(r'''<circle cx="12" cy="12" r="9"/><circle cx="12" cy="12" r="5"/><circle cx="12" cy="12" r="1.200"/>''', 0xFFFF7A5C),
  '🩺': RIcoDef(r'''<path d="M6 3v6a4 4 0 0 0 8 0V3M4 3h4M12 3h4M10 13v2.500a4.500 4.500 0 0 0 9 0V13"/><circle cx="19" cy="11" r="2"/>''', 0xFF2FE6F3),
  '☀': RIcoDef(r'''<circle cx="12" cy="12" r="4"/><path d="M12 2.500v2M12 19.500v2M4.700 4.700l1.400 1.400M17.900 17.900l1.400 1.400M2.500 12h2M19.500 12h2M4.700 19.300l1.400-1.400M17.900 6.100l1.400-1.400"/>''', 0xFFFFBE4D),
  '🛌': RIcoDef(r'''<path d="M3 19V6M3 15h18v4M21 15v-2.500A3 3 0 0 0 18 9.500h-7V15"/><circle cx="7" cy="11.500" r="1.800"/>''', 0xFF2FE6F3),
  '✨': RIcoDef(r'''<path d="M11 3l1.900 5.600L18.500 10.500l-5.600 1.900L11 18l-1.900-5.600L3.500 10.500l5.600-1.900zM19 15l.8 2.200 2.200.8-2.200.8L19 21l-.8-2.200-2.200-.8 2.200-.8z"/>''', 0xFF3CF08A),
  '🔒': RIcoDef(r'''<rect x="5" y="11" width="14" height="10" rx="2.800"/><path d="M8 11V8a4 4 0 0 1 8 0v3M12 15.500v2"/>''', 0xFF3CF08A),
  '🚀': RIcoDef(r'''<path d="M5 15c-1.500 1.500-2 5-2 5s3.500-.5 5-2M12 15l-3-3M9 12c1.200-4.500 4.500-8.500 11.500-9 0 7-4.500 10.500-9 11.500z"/><circle cx="15.500" cy="8.500" r="1"/>''', 0xFFFF7A5C),
  '✓': RIcoDef(r'''<path d="M5 12.500l4.500 4.500L19 7.500"/>''', 0xFF3CF08A),
  '📸': RIcoDef(r'''<path d="M4 8h3l1.500-2.500h7L17 8h3a1 1 0 0 1 1 1v9a1 1 0 0 1-1 1H4a1 1 0 0 1-1-1V9a1 1 0 0 1 1-1z"/><circle cx="12" cy="13.500" r="3.500"/>''', 0xFFFFBE4D),
  '🏆': RIcoDef(r'''<path d="M8 4h8v6a4 4 0 0 1-8 0zM8 6H4.500v1.500A3 3 0 0 0 8 10.500M16 6h3.500v1.500a3 3 0 0 1-3.500 3M12 14v4M8.500 20.500h7M10 18h4"/>''', 0xFFFFBE4D),
  '📈': RIcoDef(r'''<path d="M3 17l5.500-5.500 4 4L21 7M15 7h6v6"/>''', 0xFFFF5F7E),
  '🧠': RIcoDef(r'''<path d="M9 4.500a3 3 0 0 0-3 3 3 3 0 0 0-2 2.800 3 3 0 0 0 1.200 2.400A3 3 0 0 0 6.500 17 3 3 0 0 0 12 18.500V5.500A3 3 0 0 0 9 4.500zM15 4.500a3 3 0 0 1 3 3 3 3 0 0 1 2 2.800 3 3 0 0 1-1.200 2.400A3 3 0 0 1 17.500 17 3 3 0 0 1 12 18.500"/>''', 0xFF9B7BFF),
  '🌡': RIcoDef(r'''<path d="M14 14.500V5a2 2 0 0 0-4 0v9.500a4 4 0 1 0 4 0z"/><path d="M12 9v7"/>''', 0xFFFFBE4D),
  '🚨': RIcoDef(r'''<path d="M7 18v-6a5 5 0 0 1 10 0v6M5 18h14M12 3v2M4.500 6.500l1.400 1.400M19.500 6.500l-1.400 1.400M9 21.500h6"/>''', 0xFFFF8A5F),
  '🥗': RIcoDef(r'''<path d="M3 12h18a9 9 0 0 1-18 0zM8 12c0-3 1.500-5 4-6M13 12c.5-3 2-4.500 5-4.500"/>''', 0xFF3CF08A),
  '🔥': RIcoDef(r'''<path d="M12 22c4 0 7-3 7-7 0-3.300-2-5.300-3-7.500-1 2-2 3-3.200 3 .2-4-1-7-3.800-9.500 0 5.500-4 7.500-4 13 0 4.500 3 8 7 8z"/>''', 0xFFFF9466),
  '🧑‍🏫': RIcoDef(r'''<circle cx="12" cy="8" r="3.500"/><path d="M5 20.500c0-3.800 3-6.500 7-6.500s7 2.700 7 6.500M9.500 14.500L12 18l2.500-3.500"/>''', 0xFF9B7BFF),
  '🥜': RIcoDef(r'''<path d="M12 3c-3 0-4.500 2-4.500 4 0 1.500 1 2 1 3.500S6.500 12 6.500 15.500C6.500 19 9 21 12 21s5.500-2 5.500-5.500c0-3.500-2-3.500-2-5S16.500 8.500 16.500 7c0-2-1.500-4-4.500-4zM8.500 10h7M8 15h8"/>''', 0xFFFFBE4D),
  '💊': RIcoDef(r'''<rect x="3" y="9" width="18" height="6" rx="3" transform="rotate(-45 12 12)"/><path d="M9 9l6 6"/>''', 0xFF3CF08A),
  '📊': RIcoDef(r'''<path d="M5 21V11M12 21V4M19 21v-7M3 21h18"/>''', 0xFF2FE6F3),
  '🍼': RIcoDef(r'''<path d="M9 3h6M10 3v2.500h4V3M8 8.500a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2V19a2 2 0 0 1-2 2h-4a2 2 0 0 1-2-2zM8 12.500h4M8 16.500h4"/>''', 0xFFFF8FC8),
  '🎁': RIcoDef(r'''<rect x="3.500" y="8" width="17" height="4"/><path d="M5 12v8h14v-8M12 8v12M12 8c-2-4-6-3.500-5 0M12 8c2-4 6-3.500 5 0"/>''', 0xFFFFBE4D),
  '📅': RIcoDef(r'''<rect x="3.500" y="5" width="17" height="15.500" rx="3"/><path d="M3.500 10h17M8 3v4M16 3v4M8 14h2M12 14h2M8 17.500h2"/>''', 0xFF8FF3F9),
  '🆘': RIcoDef(r'''<circle cx="12" cy="12" r="9"/><path d="M12 7.500v5M12 15.800v.2"/>''', 0xFFFF5F7E),
  '🍽': RIcoDef(r'''<path d="M7 3v8M4.500 3v5a2.500 2.500 0 0 0 5 0V3M7 11v10M17 21V3c-2.500 1.500-3.500 5-3.500 9H17"/>''', 0xFFFFBE4D),
  '👋': RIcoDef(r'''<path d="M8 12V6.500a1.500 1.500 0 0 1 3 0V11M11 11V5a1.500 1.500 0 0 1 3 0v6M14 11V6.500a1.500 1.500 0 0 1 3 0V14c0 4-2.500 7-6 7-2.500 0-4-1.500-5.500-4L4 14.500c-.7-1.200.8-2.500 2-1.500l2 2"/>''', 0xFFFFBE4D),
  '⏱': RIcoDef(r'''<circle cx="12" cy="13.500" r="8"/><path d="M12 9.500v4l2.500 1.500M9.500 2.500h5"/>''', 0xFF3CF08A),
  '⚠': RIcoDef(r'''<path d="M12 3.500L2.500 20h19z"/><path d="M12 10v4.500M12 17.500v.2"/>''', 0xFFFFBE4D),
  '💚': RIcoDef(r'''<path d="M12 20.500S4 15.500 4 9.800A4.300 4.300 0 0 1 12 7.600 4.300 4.300 0 0 1 20 9.800c0 5.700-8 10.700-8 10.700z"/><path d="M8.500 11.500l2.500 2.500 4.500-4.500"/>''', 0xFF3CF08A),
  '📶': RIcoDef(r'''<path d="M4 18v-2M9 18v-6M14 18V9M19 18V5"/>''', 0xFF3CF08A),
  '🔗': RIcoDef(r'''<path d="M10 14a4 4 0 0 0 5.600 0l3-3a4 4 0 0 0-5.600-5.600l-1 1"/><path d="M14 10a4 4 0 0 0-5.600 0l-3 3a4 4 0 0 0 5.600 5.600l1-1"/>''', 0xFF2FE6F3),
  '🔢': RIcoDef(r'''<path d="M5 9h14M5 15h14M9.500 4l-1.500 16M16 4l-1.500 16"/>''', 0xFF8FF3F9),
  '💬': RIcoDef(r'''<path d="M4 5.500h16a1 1 0 0 1 1 1V16a1 1 0 0 1-1 1H10l-5 4v-4H4a1 1 0 0 1-1-1V6.500a1 1 0 0 1 1-1z"/><path d="M8 10h8M8 13h5"/>''', 0xFF2FE6F3),
  '✋': RIcoDef(r'''<path d="M7 12V6.500a1.500 1.500 0 0 1 3 0V11M10 11V5a1.500 1.500 0 0 1 3 0v6M13 11V6.500a1.500 1.500 0 0 1 3 0V14c0 4-2.500 7-6 7-2.500 0-4-1.500-5.500-4L3 13.500c-.7-1.200.8-2.500 2-1.500l2 2"/>''', 0xFF2FE6F3),
  '🤚': RIcoDef(r'''<path d="M17 12V6.500a1.500 1.500 0 0 0-3 0V11M14 11V5a1.500 1.500 0 0 0-3 0v6M11 11V6.500a1.500 1.500 0 0 0-3 0V14c0 4 2.500 7 6 7 2.500 0 4-1.500 5.500-4l1.500-3.500c.7-1.200-.8-2.500-2-1.500l-2 2"/>''', 0xFF2FE6F3),
};

/// ئایا ئایکۆنێک بۆ ئەم ئیمۆجییە هەیە؟
bool hasRIco(String emoji) => _kRIcons.containsKey(_rn(emoji));

Color rIcoColor(String emoji, [Color fallback = V.cy]) {
  final d = _kRIcons[_rn(emoji)];
  return d == null ? fallback : Color(d.color);
}

String _hex(int c) => '#${(c & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';

/// ئایکۆن: tile = چوارچێوەی گرادیێنت، ئەگەرنا تەنها هێڵەکە
class RIco extends StatelessWidget {
  const RIco(this.emoji, {super.key, this.size = 48, this.tile = true, this.radius, this.color, this.stroke = 1.8});
  final String emoji;
  final double size;
  final bool tile;
  final double? radius;
  final Color? color;
  final double stroke;

  @override
  Widget build(BuildContext context) {
    final d = _kRIcons[_rn(emoji)];
    if (d == null) {
      // ئیمۆجییەکی نەناسراو: وەک خۆی نیشان دەدرێت
      return SizedBox(
        width: size,
        height: size,
        child: Center(child: Text(emoji, style: TextStyle(fontSize: size * (tile ? 0.5 : 0.9), height: 1))),
      );
    }
    final c = color ?? Color(d.color);
    final inner = tile ? size * 0.54 : size;
    final svg = SvgPicture.string(
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="${_hex(c.value)}" '
      'stroke-width="${tile ? stroke : stroke + 0.2}" stroke-linecap="round" stroke-linejoin="round">${d.paths}</svg>',
      width: inner,
      height: inner,
    );
    if (!tile) return SizedBox(width: size, height: size, child: svg);
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius ?? size * 0.3),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [mix(c, const Color(0xFF0B2C36), 0.66), mix(c, const Color(0xFF06202A), 0.92)],
        ),
        border: Border.all(color: op(c, 0.42)),
        boxShadow: [BoxShadow(color: op(c, 0.38), blurRadius: size * 0.4, offset: Offset(0, size * 0.16), spreadRadius: -size * 0.2)],
      ),
      child: svg,
    );
  }
}

/// ئایکۆنی بچووک لەناو دەق (بۆ TextSpan)
WidgetSpan ricoSpan(String emoji, {double size = 15, Color? color}) => WidgetSpan(
      alignment: PlaceholderAlignment.middle,
      child: Padding(
        padding: const EdgeInsetsDirectional.only(end: 3),
        child: RIco(emoji, size: size, tile: false, color: color),
      ),
    );

/// وێنەی کەسایەتی (نێر / مێ)
const String kAvatarM = r'''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 96 96" aria-hidden="true"><defs><linearGradient id="avm" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#5ff0ff"/><stop offset="1" stop-color="#2f7bff"/></linearGradient><linearGradient id="avm2" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#fff"/><stop offset="1" stop-color="#cfefff"/></linearGradient></defs><circle cx="48" cy="48" r="46" fill="url(#avm)" opacity=".16"/><circle cx="48" cy="48" r="45" fill="none" stroke="url(#avm)" stroke-width="1.6"/><path d="M17 85c2-18 14-26 31-26s29 8 31 26a46 46 0 0 1-62 0z" fill="url(#avm)"/><path d="M40 57v-6h16v6l-8 6z" fill="#cfefff"/><circle cx="48" cy="38" r="15.500" fill="url(#avm2)"/><path d="M32 37c-1-12 7-19 17-19 9 0 16 6 15 17-3-5-8-8-14-7-7 0-13 3-18 9z" fill="#0b3a5a"/></svg>''';
const String kAvatarF = r'''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 96 96" aria-hidden="true"><defs><linearGradient id="avf" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#ff9ad0"/><stop offset="1" stop-color="#b96bff"/></linearGradient><linearGradient id="avf2" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#fff"/><stop offset="1" stop-color="#ffe3f1"/></linearGradient></defs><circle cx="48" cy="48" r="46" fill="url(#avf)" opacity=".16"/><circle cx="48" cy="48" r="45" fill="none" stroke="url(#avf)" stroke-width="1.6"/><path d="M29 42c0-16 8-25 19-25s19 9 19 25v26c0 4-5 6-9 3V46H38v25c-4 3-9 1-9-3z" fill="#5b1e63"/><path d="M17 85c2-18 14-26 31-26s29 8 31 26a46 46 0 0 1-62 0z" fill="url(#avf)"/><path d="M42 57v-5h12v5l-6 5z" fill="#ffe3f1"/><circle cx="48" cy="39" r="14.500" fill="url(#avf2)"/><path d="M33 37c1-10 8-15 16-15s14 5 15 14c-6-1-13-5-17-9-3 5-8 8-14 10z" fill="#5b1e63"/></svg>''';

class RAvatar extends StatelessWidget {
  const RAvatar({super.key, required this.female, this.size = 104});
  final bool female;
  final double size;

  @override
  Widget build(BuildContext context) => SvgPicture.string(female ? kAvatarF : kAvatarM, width: size, height: size);
}
