// خواردن کامل — پەڕەی خواردنی VEX Health لەناو Flutter
//
// ئەمە هەمان کۆد و دیزاینی بەشی خواردنی وێبە (٧٠٠ خواردن بە وێنە، ئەمڕۆ، گەڕان، ڕاهێنەر،
// شیکاری، من، ڤیتامین، ئاو، Band، ڕێکلام) و بە flutter_inappwebview دەکرێتەوە.
//
// بەکارهێنان:
//   Navigator.push(context, MaterialPageRoute(builder: (_) => const VexFoodPage()));
import 'dart:async';
import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import 'vex_food_bridge.dart';

/// کلیلی پاشەکەوتکردنی خواردن لە SharedPreferences (نوسخەیەکی پارێزراو)
const String kVexFoodPrefsKey = 'vexfood-v2';

/// کلیلی زانیاری هەژمار (هەمان کلیلی بەشی onboarding/account)
const String kVexUserPrefsKey = 'vexuser';

class VexFoodPage extends StatefulWidget {
  const VexFoodPage({
    super.key,
    this.controller,
    this.onScan,
    this.onFoodChanged,
    this.dark = true,
    this.safeTop = true,
  });

  /// بۆ کۆنتڕۆڵکردنی پەڕەکە لە دەرەوە (ئارەزوومەندانە)
  final VexFoodController? controller;

  /// کاتێک بەکارهێنەر کامێرا/گەلەری/نووسینی سکان دەکات. ئەگەر null بێت، تەنها نامەیەک پیشان دەدرێت.
  final void Function(VexScanRequest req)? onScan;

  /// هەر جارێک خواردن یان ئاو گۆڕدرا (بۆ هاوکاتکردنی پەڕەی سەرەکی)
  final void Function(VexFoodSummary s)? onFoodChanged;

  /// true = تیمی تاریک (بنەڕەت)
  final bool dark;

  /// SafeArea ی سەرەوە بەکاربێنە (کاتێک پەڕەکە بە Navigator.push دەکرێتەوە)
  final bool safeTop;

  @override
  State<VexFoodPage> createState() => _VexFoodPageState();
}

class _VexFoodPageState extends State<VexFoodPage> {
  static const Color _bg = Color(0xFF04202A);

  bool _serverReady = false;
  String? _error;
  String _restoreJs = '';

  @override
  void initState() {
    super.initState();
    _boot();
  }

  @override
  void dispose() {
    widget.controller?.detach();
    super.dispose();
  }

  Future<void> _boot() async {
    try {
      await VexFoodServer.ensureStarted();
      _restoreJs = await _buildRestoreScript();
      if (!mounted) return;
      setState(() => _serverReady = true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = '$e');
    }
  }

  /// پێش بارکردنی پەڕە: ئەگەر localStorage بەتاڵە، خواردن و هەژمار لە SharedPreferences دەگەڕێنێتەوە.
  Future<String> _buildRestoreScript() async {
    String food = '';
    String user = '';
    try {
      final sp = await SharedPreferences.getInstance();
      food = sp.getString(kVexFoodPrefsKey) ?? '';
      user = sp.getString(kVexUserPrefsKey) ?? '';
    } catch (_) {}
    final b = StringBuffer('try{');
    if (food.isNotEmpty) {
      b.write("if(!localStorage.getItem('vexfood-v2'))localStorage.setItem('vexfood-v2',${_q(food)});");
    }
    if (user.isNotEmpty) {
      // هەژماری ئێستا هەمیشە لە ئەپەوە دێت
      b.write("localStorage.setItem('vexuser',${_q(user)});");
    }
    b.write('}catch(e){}');
    return b.toString();
  }

  /// دەقێک وەک JavaScript string دەگۆڕێت
  String _q(String s) {
    final e = s
        .replaceAll('\\', '\\\\')
        .replaceAll("'", "\\'")
        .replaceAll('\n', '\\n')
        .replaceAll('\r', '\\r')
        .replaceAll(' ', '\\u2028')
        .replaceAll(' ', '\\u2029');
    return "'$e'";
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(content: Text(msg)));
  }

  void _registerHandlers(InAppWebViewController c) {
    c.addJavaScriptHandler(
      handlerName: 'vexScan',
      callback: (args) {
        if (args.isEmpty || args.first is! Map) return false;
        final req = VexScanRequest.fromMap(args.first as Map<dynamic, dynamic>);
        final cb = widget.onScan;
        if (cb == null) {
          _toast('سکان لێرە هێشتا بە پەڕەی سکانی ئەپەکە نەبەسترایەوە (README ببینە)');
          return false;
        }
        cb(req);
        return true;
      },
    );
    c.addJavaScriptHandler(
      handlerName: 'vexFoodChanged',
      callback: (args) {
        if (args.isEmpty || args.first is! Map) return null;
        final cb = widget.onFoodChanged;
        if (cb != null) cb(VexFoodSummary.fromMap(args.first as Map<dynamic, dynamic>));
        return null;
      },
    );
    c.addJavaScriptHandler(
      handlerName: 'vexFoodSave',
      callback: (args) async {
        if (args.isEmpty) return null;
        try {
          final sp = await SharedPreferences.getInstance();
          await sp.setString(kVexFoodPrefsKey, '${args.first}');
        } catch (_) {}
        return null;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget body;
    if (_error != null) {
      body = Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'پەڕەی خواردن نەکرایەوە:\n$_error',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70),
          ),
        ),
      );
    } else if (!_serverReady) {
      body = const Center(child: CircularProgressIndicator(color: Color(0xFF2FE6F3)));
    } else {
      body = InAppWebView(
        initialUrlRequest: URLRequest(url: WebUri(VexFoodServer.url)),
        initialUserScripts: UnmodifiableListView<UserScript>([
          UserScript(
            source: _restoreJs,
            injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START,
          ),
        ]),
        initialSettings: InAppWebViewSettings(
          javaScriptEnabled: true,
          transparentBackground: true,
          supportZoom: false,
          disableContextMenu: true,
          allowsInlineMediaPlayback: true,
          mediaPlaybackRequiresUserGesture: false,
          useShouldOverrideUrlLoading: true,
          verticalScrollBarEnabled: false,
          horizontalScrollBarEnabled: false,
        ),
        onWebViewCreated: (c) {
          widget.controller?.attach(c);
          _registerHandlers(c);
        },
        onLoadStop: (c, url) async {
          try {
            await c.evaluateJavascript(
              source: "try{VEXFOOD.theme('${widget.dark ? 'dark' : 'light'}')}catch(e){}",
            );
          } catch (_) {}
        },
        onPermissionRequest: (c, request) async {
          return PermissionResponse(
            resources: request.resources,
            action: PermissionResponseAction.GRANT,
          );
        },
        shouldOverrideUrlLoading: (c, action) async {
          final uri = action.request.url;
          if (uri == null) return NavigationActionPolicy.ALLOW;
          final host = uri.host;
          if (host == 'localhost' || host == '127.0.0.1' || uri.scheme == 'about' || uri.scheme == 'data' || uri.scheme == 'blob') {
            return NavigationActionPolicy.ALLOW;
          }
          try {
            await launchUrl(Uri.parse(uri.toString()), mode: LaunchMode.externalApplication);
          } catch (_) {}
          return NavigationActionPolicy.CANCEL;
        },
      );
    }

    final content = Container(color: _bg, child: body);
    return Scaffold(
      backgroundColor: _bg,
      body: widget.safeTop ? SafeArea(bottom: false, child: content) : content,
    );
  }
}
