// VEX Health — ئایکۆنەکان (SVG)
import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'vex_theme.dart';

/// ئایکۆنی هێڵی بازنەی تەندروستی
const Map<String, String> kRingIcons = {
  'sleep': '<path d="M20 14.5A8 8 0 0 1 9.5 4 8 8 0 1 0 20 14.5z"/>',
  'hr': '<path d="M12 20s-7.5-4.6-7.5-10.2A4.3 4.3 0 0 1 12 7.2a4.3 4.3 0 0 1 7.5 2.6C19.5 15.4 12 20 12 20z"/>',
  'temp': '<path d="M14 14.8V5a2 2 0 0 0-4 0v9.8a4 4 0 1 0 4 0z"/><path d="M12 11v6"/>',
  'act': '<path d="M12 3c1 4 5 5.5 5 10.5a5 5 0 0 1-10 0c0-2.2 1-3.6 2.2-4.5.2 2 1.2 3 2.3 3 0-3.4-1-5.8.5-9z"/>',
  'spo2': '<path d="M12 3s6 6.5 6 11a6 6 0 0 1-12 0c0-4.5 6-11 6-11z"/>',
  'stress':
      '<path d="M9.5 4.5a3 3 0 0 0-3 3 3 3 0 0 0-2 5.2 3 3 0 0 0 2 4.8 3 3 0 0 0 5.5 1V6.3a3 3 0 0 0-2.5-1.8z"/><path d="M14.5 4.5a3 3 0 0 1 3 3 3 3 0 0 1 2 5.2 3 3 0 0 1-2 4.8 3 3 0 0 1-5.5 1"/>',
};

class Ico {
  Ico._();
  static const String home = '<path d="M3 11l9-8 9 8M5 10v10h14V10"/>';
  static const String heart =
      '<path d="M12 21s-8-5-8-11a4.5 4.5 0 0 1 8-2.7A4.5 4.5 0 0 1 20 10c0 6-8 11-8 11z"/>';
  static const String spark = '<path d="M12 2l1.8 5.2L19 9l-5.2 1.8L12 16l-1.8-5.2L5 9l5.2-1.8z"/>';
  static const String run =
      '<circle cx="14" cy="4.5" r="2"/><path d="M8 21l3-6-2.5-2.5L10 8l4 1 2 3M11 15l3 2 1 4M10 8L7 11"/>';
  static const String user = '<circle cx="12" cy="8" r="4"/><path d="M4 21c1-4 4-6 8-6s7 2 8 6"/>';
  static const String bell = '<path d="M6 8a6 6 0 0 1 12 0c0 7 3 8 3 8H3s3-1 3-8M10 20a2 2 0 0 0 4 0"/>';
  static const String sync =
      '<path d="M20 11a8 8 0 0 0-14.5-4.5L4 8M4 4v4h4M4 13a8 8 0 0 0 14.5 4.5L20 16M20 20v-4h-4"/>';
  static const String ecg = '<path d="M3 12h4l2-5 4 10 2-5h6"/>';
  static const String sparkTool = '<path d="M12 3l1.8 5.2L19 10l-5.2 1.8L12 17l-1.8-5.2L5 10l5.2-1.8z"/>';
  static const String drop = '<path d="M12 2.5s-6.5 7-6.5 11.6a6.5 6.5 0 0 0 13 0C18.5 9.5 12 2.5 12 2.5z"/>';
}

String iconSvg(String inner, String hex0, {double stroke = 2, bool fill = false}) => _iconSvg(inner, vexMapHex(hex0), stroke, fill);

String _iconSvg(String inner, String hex, double stroke, bool fill) =>
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" '
    'fill="${fill ? hex : 'none'}" stroke="${fill ? 'none' : hex}" '
    'stroke-width="$stroke" stroke-linecap="round" stroke-linejoin="round">$inner</svg>';

Widget svgIcon(String inner, String hex, {double size = 20, double stroke = 2, bool fill = false}) =>
    SvgPicture.string(iconSvg(inner, hex, stroke: stroke, fill: fill), width: size, height: size);
