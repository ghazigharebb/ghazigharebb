// خواردن کامل — پرد (bridge) لە نێوان پەڕەی وێبی خواردن و Flutter
//
// ئەم فایلە سێ شت دەگرێتەوە:
//  1) VexFoodServer      سێرڤەری ناوخۆیی بچووک (http://localhost:8765) کە فایلەکانی assets/food_full/web بڵاو دەکاتەوە
//  2) VexScanRequest / VexFoodSummary   ئەو زانیارییانەی وێب بۆ Flutter دەینێرێت
//  3) VexFoodController  فەرمانەکانی Flutter بۆ وێب (زیادکردنی خواردن، گۆڕینی تیم...)
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_inappwebview/flutter_inappwebview.dart';

/// سێرڤەری ناوخۆیی بۆ فایلەکانی وێب (HTML، وێنە، فۆنت).
/// پێویستە لە pubspec.yaml ی ئەپەکە هەموو ئەو فۆڵدەرانەی assets/food_full/web/ ڕیز کرابن (README ببینە).
class VexFoodServer {
  VexFoodServer._();

  static const int port = 8765;
  static const String root = 'assets/food_full/web';
  static final InAppLocalhostServer _server = InAppLocalhostServer(
    port: port,
    documentRoot: root,
  );
  static Future<void>? _starting;

  /// ناونیشانی پەڕەکە
  static String get url => 'http://localhost:$port/index.html';

  /// یەک جار دەستی پێدەکات؛ بانگکردنی دووبارە ئاسایییە.
  static Future<void> ensureStarted() {
    return _starting ??= () async {
      if (!_server.isRunning()) {
        await _server.start();
      }
    }();
  }
}

/// داواکاری سکان لە پەڕەی وێبەوە (کامێرا، گەلەری، یان نووسین).
class VexScanRequest {
  VexScanRequest({
    required this.camera,
    required this.slot,
    required this.text,
    required this.image,
  });

  /// true = بەکارهێنەر دوگمەی کامێرای دا
  final bool camera;

  /// ژەم: b بەیانی، l نیوەڕۆ، s سووک، d ئێوارە، n شەو (دەشێت بەتاڵ بێت)
  final String slot;

  /// خواردنی نووسراو (دەشێت بەتاڵ بێت)
  final String text;

  /// وێنەی هەڵبژێردراو لە گەلەری (دەشێت null بێت)
  final Uint8List? image;

  static VexScanRequest fromMap(Map<dynamic, dynamic> m) {
    Uint8List? bytes;
    final raw = '${m['image'] ?? ''}';
    if (raw.isNotEmpty) {
      final i = raw.indexOf(',');
      final b64 = i >= 0 ? raw.substring(i + 1) : raw;
      try {
        bytes = base64Decode(b64);
      } catch (_) {
        bytes = null;
      }
    }
    return VexScanRequest(
      camera: m['camera'] == true,
      slot: '${m['slot'] ?? ''}',
      text: '${m['text'] ?? ''}',
      image: bytes,
    );
  }
}

/// یەک خواردنی تۆمارکراوی ئەمڕۆ (هەمان شێوەی syncHome ی وێب)
class VexFoodEntry {
  VexFoodEntry({
    required this.n,
    required this.kcal,
    required this.p,
    required this.c,
    required this.f,
    required this.at,
    required this.v,
    required this.e,
    required this.slot,
  });

  final String n;
  final int kcal;
  final double p;
  final double c;
  final double f;
  final String at;

  /// good / ok / bad
  final String v;
  final String e;
  final String slot;

  static double _d(dynamic v) {
    if (v is num) return v.toDouble();
    return double.tryParse('$v') ?? 0;
  }

  static VexFoodEntry fromMap(Map<dynamic, dynamic> m) => VexFoodEntry(
        n: '${m['n'] ?? ''}',
        kcal: _d(m['kcal']).round(),
        p: _d(m['p']),
        c: _d(m['c']),
        f: _d(m['f']),
        at: '${m['at'] ?? ''}',
        v: '${m['v'] ?? 'ok'}',
        e: '${m['e'] ?? '🍽️'}',
        slot: '${m['slot'] ?? ''}',
      );
}

/// کورتەی ئەمڕۆ: چەند کالۆری خوراوە و ئامانج چییە
class VexFoodSummary {
  VexFoodSummary({
    required this.kcal,
    required this.goal,
    required this.p,
    required this.c,
    required this.f,
    required this.burned,
    required this.items,
  });

  final int kcal;
  final int goal;

  /// ئامانجی پڕۆتین، کارب، چەوری بە گرام
  final int p, c, f;

  /// کالۆری سووتاو بەپێی Band
  final int burned;

  /// خواردنە تۆمارکراوەکانی ئەمڕۆ (نوێترین یەکەم)
  final List<VexFoodEntry> items;

  static int _i(dynamic v) {
    if (v is num) return v.round();
    return int.tryParse('$v') ?? 0;
  }

  static VexFoodSummary fromMap(Map<dynamic, dynamic> m) {
    final s = (m['summary'] is Map) ? m['summary'] as Map<dynamic, dynamic> : <dynamic, dynamic>{};
    final list = <VexFoodEntry>[];
    final raw = m['items'];
    if (raw is List) {
      for (final x in raw) {
        if (x is Map) list.add(VexFoodEntry.fromMap(x));
      }
    }
    return VexFoodSummary(
      kcal: _i(s['kcal']),
      goal: _i(s['goal']),
      p: _i(s['p']),
      c: _i(s['c']),
      f: _i(s['f']),
      burned: _i(s['burned']),
      items: list,
    );
  }
}

/// کۆنتڕۆڵی پەڕەی خواردن لە دەرەوەی ویجێتەکە.
/// نموونە:
///   final ctl = VexFoodController();
///   VexFoodPage(controller: ctl);
///   ctl.addItem({'n': 'هێلکە', 'kcal': 78, 'p': 6, 'c': 1, 'f': 5, 'slot': 'b'});
class VexFoodController {
  InAppWebViewController? _web;

  /// تەنها لەلایەن VexFoodPage ـەوە بانگ دەکرێت.
  void attach(InAppWebViewController c) {
    _web = c;
  }

  void detach() {
    _web = null;
  }

  bool get ready => _web != null;

  Future<void> _js(String code) async {
    final w = _web;
    if (w == null) return;
    try {
      await w.evaluateJavascript(source: code);
    } catch (_) {}
  }

  /// خواردنێک بۆ ڕۆژی ئەمڕۆ زیاد بکە.
  /// کلیلەکان: n (ناو)، kcal، p، c، f، fib، sug، v (good/ok/bad)، at ("13:20")، slot (b/l/s/d/n)
  Future<void> addItem(Map<String, dynamic> item) => _js('VEXFOOD.add(${jsonEncode(item)})');

  /// دوایین خواردنی زیادکراو بسڕەوە (ئەوەی بە addItem زیاد کرابێت)
  Future<void> undoLast() => _js('VEXFOOD.undo()');

  /// 'dark' یان 'light'
  Future<void> setTheme(String theme) => _js('VEXFOOD.theme(${jsonEncode(theme == 'light' ? 'light' : 'dark')})');

  /// پەڕەکە لە سەرەتاوە بخوێنەوە (دوای گۆڕینی پرۆفایل/چوونەدەرەوە)
  Future<void> reload() async {
    final w = _web;
    if (w == null) return;
    try {
      await w.reload();
    } catch (_) {}
  }
}
