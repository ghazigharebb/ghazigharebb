// VEX Health — بەشی تەندروستی: ڕەنگ، ئایکۆن و پارچە هاوبەشەکان
import 'package:flutter/material.dart';

import '../core/theme.dart';

/// ڕەنگەکانی بەشی تەندروستی (هەمان ڕەنگەکانی وێبەکە)
class HC {
  HC._();
  static Color get bg => VexTheme.I.p.hBg;
  static Color get bg2 => VexTheme.I.p.hBg2;
  static Color get card => VexTheme.I.p.hCard;
  static Color get line => VexTheme.I.p.hLine;
  static Color get c => VexTheme.I.p.hC;
  static Color get c2 => VexTheme.I.p.hC2;
  static Color get tx => VexTheme.I.p.hTx;
  static Color get mu => VexTheme.I.p.hMu;
  static Color get track => VexTheme.I.p.hTrack;
  static Color get glow => VexTheme.I.p.hGlow;
  static Color get ok => VexTheme.I.p.hOk;
  static Color get wn => VexTheme.I.p.hWn;
  static Color get bd => VexTheme.I.p.hBd;
  static Color get nd => VexTheme.I.p.hNd;
  static Color get orange => VexTheme.I.p.hOrange;
  static Color get hr => VexTheme.I.p.hHr;
  static Color get hr2 => VexTheme.I.p.hHr2;
  static Color get ink => VexTheme.I.p.hInk;
}

/// ڕەنگەکان بە شێوەی hex بۆ ئایکۆنەکانی SVG
class HX {
  HX._();
  static String get c => vexHex(HC.c);
  static String get c2 => vexHex(HC.c2);
  static String get tx => vexHex(HC.tx);
  static String get mu => vexHex(HC.mu);
  static String get ok => vexHex(HC.ok);
  static String get wn => vexHex(HC.wn);
  static String get bd => vexHex(HC.bd);
  static String get nd => vexHex(HC.nd);
  static String get orange => vexHex(HC.orange);
  static String get hr => vexHex(HC.hr);
}

/// ئایکۆنەکان (ناوەڕۆکی SVG بە viewBox 24)
class HI {
  HI._();
  static String p(String d) => '<path d="$d"/>';
  static final String step = p('M13 4.5a1.5 1.5 0 1 1 0-.01M9 21l2-6 2 2v4M11 15l-1-5 3-1 2 3 3 1M10 10l-3 2');
  static final String fire = p('M12 3c1 4 5 5 5 10a5 5 0 0 1-10 0c0-2 1-3 2-4 0 2 1 3 2 3 0-3-1-5 1-9z');
  static final String pin = p('M12 21s-7-6-7-11a7 7 0 0 1 14 0c0 5-7 11-7 11zM12 12.5a2.5 2.5 0 1 0 0-5 2.5 2.5 0 0 0 0 5z');
  static final String heart = p('M12 21s-8-5-8-11a4.5 4.5 0 0 1 8-2.7A4.5 4.5 0 0 1 20 10c0 6-8 11-8 11z');
  static final String drop = p('M12 3s6 6.5 6 11a6 6 0 0 1-12 0c0-4.5 6-11 6-11z');
  static final String brain = p(
      'M9 4a3 3 0 0 0-3 3 3 3 0 0 0-2 5 3 3 0 0 0 2 5 3 3 0 0 0 6 1V5a3 3 0 0 0-3-1zM15 4a3 3 0 0 1 3 3 3 3 0 0 1 2 5 3 3 0 0 1-2 5 3 3 0 0 1-6 1');
  static final String wave = p('M3 12h2M7 8v8M11 5v14M15 8v8M19 11v2');
  static final String timer = p('M12 21a8 8 0 1 0 0-16 8 8 0 0 0 0 16zM12 9v4l2 2M10 2h4');
  static final String moon = p('M20 14.5A8 8 0 0 1 9.5 4 8 8 0 1 0 20 14.5z');
  static final String bat = p(
      'M7 6h10a2 2 0 0 1 2 2v10a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V8a2 2 0 0 1 2-2zM10 3h4M13 9l-3 4h4l-3 4');
  static final String temp = p('M14 14.8V5a2 2 0 0 0-4 0v9.8a4 4 0 1 0 4 0z');
  static final String sync = p('M20 11a8 8 0 0 0-14-4M4 13a8 8 0 0 0 14 4M6 3v4h4M18 21v-4h-4');
  static final String spark2 = p(
      'M12 2l1.8 5.2L19 9l-5.2 1.8L12 16l-1.8-5.2L5 9l5.2-1.8zM19 15l.9 2.1L22 18l-2.1.9L19 21l-.9-2.1L16 18l2.1-.9z');
  static final String spark = p('M12 2l1.8 5.2L19 9l-5.2 1.8L12 16l-1.8-5.2L5 9l5.2-1.8z');
  static final String bulb = p('M12 3a6 6 0 0 0-3.5 10.9V17h7v-3.1A6 6 0 0 0 12 3zM9.5 20.5h5');
  static const String route =
      '<circle cx="6" cy="19" r="2"/><circle cx="18" cy="5" r="2"/><path d="M8 19h7a3 3 0 0 0 0-6H9a3 3 0 0 1 0-6h7"/>';
  static const String clock = '<circle cx="12" cy="12" r="9"/><path d="M12 7v5l3 2"/>';
  static final String heartFill = p('M12 21s-8-5.2-8-11a4.6 4.6 0 0 1 8-3 4.6 4.6 0 0 1 8 3c0 5.8-8 11-8 11z');
  static final String back = p('M9 6l6 6-6 6');
  static final String chev = p('M15 6l-6 6 6 6');

  /// ڕوخسارەکانی دۆخ
  static const Map<String, String> face = {
    'ok':
        '<circle cx="12" cy="12" r="10"/><path d="M8 14c1.2 1.6 2.5 2.3 4 2.3s2.8-.7 4-2.3"/><path d="M9 9.5h.01M15 9.5h.01" stroke-width="2.6"/>',
    'wn':
        '<circle cx="12" cy="12" r="10"/><path d="M8.5 15h7"/><path d="M9 9.5h.01M15 9.5h.01" stroke-width="2.6"/>',
    'bd':
        '<circle cx="12" cy="12" r="10"/><path d="M8 16.5c1.2-1.6 2.5-2.3 4-2.3s2.8.7 4 2.3"/><path d="M9 9.5h.01M15 9.5h.01" stroke-width="2.6"/>',
    'nd': '<path d="M20 11a8 8 0 0 0-14-4M4 13a8 8 0 0 0 14 4M6 3v4h4M18 21v-4h-4"/>',
  };
}

Color statusColor(String f) {
  switch (f) {
    case 'ok':
      return HC.ok;
    case 'wn':
      return HC.wn;
    case 'bd':
      return HC.bd;
    default:
      return HC.nd;
  }
}

String statusHex(String f) {
  switch (f) {
    case 'ok':
      return HX.ok;
    case 'wn':
      return HX.wn;
    case 'bd':
      return HX.bd;
    default:
      return HX.nd;
  }
}

/// بەرواری ئەمڕۆ وەک "10ی تشرینی یەکەم 2026"
String todayLabel() {
  final d = DateTime.now();
  return '${d.day}ی ${kMonths[d.month - 1]} ${d.year}';
}

String monthLabel() {
  final d = DateTime.now();
  return '${kMonths[d.month - 1]} ${d.year}';
}

String monthName() => kMonths[DateTime.now().month - 1];

/// پاشبنەمای پەڕەکانی تەندروستی
class HealthBg extends StatelessWidget {
  const HealthBg({super.key, this.radius = 0.95});
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(child: ColoredBox(color: HC.bg)),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0, -1),
                radius: radius,
                colors: [HC.bg2, Color(0x000A3F4C)],
                stops: const [0.0, 0.7],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// سەردێڕی بەشەکان (نیشانە زیندووەکان، چالاکی ...)
class HSec extends StatelessWidget {
  const HSec(this.title, {super.key, this.note = '', this.live = false});
  final String title;
  final String note;
  final bool live;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 24, 4, 0),
      child: Row(
        children: [
          Expanded(child: VText(title, style: ku(15.5, w: FontWeight.w800, c: HC.tx))),
          if (live) ...[
            BlinkDot(size: 6, color: HC.ok, glow: true),
            const SizedBox(width: 6),
          ],
          VText(note, style: ku(11.5, w: FontWeight.w700, c: HC.mu)),
        ],
      ),
    );
  }
}

/// چوونە ناو پەڕەیەکی وردەکاری (لە چەپەوە دێت، وەک ئەپەکە)
Future<void> pushPage(Widget page) {
  final nav = navKey.currentState;
  if (nav == null) return Future<void>.value();
  return nav.push<void>(
    PageRouteBuilder<void>(
      transitionDuration: const Duration(milliseconds: 380),
      reverseTransitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, a, b) => page,
      transitionsBuilder: (context, a, b, child) {
        final curved = CurvedAnimation(
          parent: a,
          curve: const Cubic(0.2, 0.9, 0.25, 1.0),
          reverseCurve: Curves.easeInCubic,
        );
        return SlideTransition(
          position: Tween<Offset>(begin: const Offset(-1, 0), end: Offset.zero).animate(curved),
          child: FadeTransition(
            opacity: Tween<double>(begin: 0.4, end: 1).animate(curved),
            child: child,
          ),
        );
      },
    ),
  );
}

/// هێڵی ڕاستەوخۆ بە شێوەی خاڵ خاڵ
void dashLine(Canvas canvas, Offset a, Offset b, Paint p, {double on = 4, double off = 4}) {
  final d = b - a;
  final len = d.distance;
  if (len <= 0) return;
  final u = d / len;
  double x = 0;
  while (x < len) {
    final x2 = x + on < len ? x + on : len;
    canvas.drawLine(a + u * x, a + u * x2, p);
    x += on + off;
  }
}

/// هێڵێکی نەرم بە نێو خاڵەکاندا (هەمان شێوەی وێب)
Path smoothPath(List<Offset> pts, double div) {
  final path = Path();
  if (pts.isEmpty) return path;
  path.moveTo(pts[0].dx, pts[0].dy);
  for (int k = 0; k < pts.length - 1; k++) {
    final a = pts[k > 0 ? k - 1 : 0];
    final b = pts[k];
    final e = pts[k + 1];
    final f = pts[k + 2 < pts.length ? k + 2 : pts.length - 1];
    path.cubicTo(
      b.dx + (e.dx - a.dx) / div,
      b.dy + (e.dy - a.dy) / div,
      e.dx - (f.dx - b.dx) / div,
      e.dy - (f.dy - b.dy) / div,
      e.dx,
      e.dy,
    );
  }
  return path;
}

/// بەشێک لە path (بۆ جووڵەی کێشانی هێڵ)
Path partialPath(Path src, double t) {
  if (t >= 1) return src;
  final out = Path();
  if (t <= 0) return out;
  for (final m in src.computeMetrics()) {
    out.addPath(m.extractPath(0, m.length * t), Offset.zero);
  }
  return out;
}

/// نووسین لەسەر canvas
void paintText(
  Canvas canvas,
  String text,
  Offset at,
  TextStyle style, {
  TextAlign align = TextAlign.left,
  bool baseline = true,
}) {
  final tp = TextPainter(
    text: TextSpan(text: vxTr(text), style: style),
    textDirection: TextDirection.ltr,
  )..layout();
  double x = at.dx;
  if (align == TextAlign.center) x -= tp.width / 2;
  if (align == TextAlign.right) x -= tp.width;
  final y = baseline ? at.dy - tp.computeDistanceToActualBaseline(TextBaseline.alphabetic) : at.dy;
  tp.paint(canvas, Offset(x, y));
}
