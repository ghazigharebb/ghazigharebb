// VEX Health — ئاگادارکردنەوەی هەنگاو (Android: notification ی بەردەوام / iOS: Live Activity + Dynamic Island)
//
// ئەم فایلە تەنها پردی نێوان Flutter و کۆدی ناتیڤە (Kotlin / Swift)ە.
// کۆدی ناتیڤ لە native/ ـدایە و بە tools/setup_native.py دەخرێتە ناو پڕۆژەکە (بڕوانە NOTIFICATIONS.md).
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/store.dart';

class StepNotify extends ChangeNotifier with WidgetsBindingObserver {
  StepNotify._();
  static final StepNotify I = StepNotify._();

  static const MethodChannel _ch = MethodChannel('vex/steps');
  static const String _prefKey = 'vex_stepnotify';
  static const int stepGoal = 10000;

  bool enabled = false;
  bool busy = false;
  bool running = false;

  /// iOS: توکنی Push ی Live Activity — ئەگەر سێرڤەرت هەبێت بۆ نوێکردنەوە لە کاتی داخرانی ئەپ (بڕوانە NOTIFICATIONS.md)
  String? pushToken;

  /// نامەی هەڵە / ڕێنمایی بۆ بەکارهێنەر (کوردی) — null = هیچ
  String? message;

  Timer? _debounce;
  DateTime _lastPush = DateTime.fromMillisecondsSinceEpoch(0);
  bool _hooked = false;

  bool get supported =>
      !kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS);
  bool get _isAndroid => !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// لە main() دوای Store.load بانگ بکە
  Future<void> load() async {
    if (!supported) return;
    _ch.setMethodCallHandler((call) async {
      if (call.method == 'pushToken' && call.arguments is String) {
        pushToken = call.arguments as String;
        notifyListeners();
      }
      return null;
    });
    try {
      final sp = await SharedPreferences.getInstance();
      enabled = sp.getBool(_prefKey) ?? false;
    } catch (_) {}
    if (enabled) {
      // بێ پرسیار دەست پێدەکات؛ ئەگەر مۆڵەت نەمابێت بە بێدەنگی کوژاوە دەبێت
      final ok = await _ensurePermissions(ask: false);
      if (ok) {
        await _start();
      } else {
        enabled = false;
        await _save();
      }
    }
    notifyListeners();
  }

  Future<void> _save() async {
    try {
      final sp = await SharedPreferences.getInstance();
      await sp.setBool(_prefKey, enabled);
    } catch (_) {}
  }

  /// کردنەوە / داخستنی ئاگادارکردنەوە (لە سویچی پرۆفایل)
  Future<void> setEnabled(bool on) async {
    if (!supported || busy) return;
    busy = true;
    message = null;
    notifyListeners();
    try {
      if (on) {
        final ok = await _ensurePermissions(ask: true);
        if (ok && await _start()) {
          enabled = true;
        } else {
          enabled = false;
          message ??= 'ئاگادارکردنەوەکە دەستی پێنەکرد. تکایە مۆڵەتەکان لە ڕێکخستنەکانی مۆبایلەکەت بدە.';
        }
      } else {
        await _stop();
        enabled = false;
      }
      await _save();
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<bool> _ensurePermissions({required bool ask}) async {
    if (!_isAndroid) return true; // iOS: Live Activity مۆڵەتی جیاوازی نەوێت؛ Motion لە کاتی یەکەم بەکارهێنان دەپرسرێت
    try {
      var n = await Permission.notification.status;
      var a = await Permission.activityRecognition.status;
      if (ask) {
        if (!n.isGranted) n = await Permission.notification.request();
        if (!a.isGranted) a = await Permission.activityRecognition.request();
      }
      if (!n.isGranted) {
        message = 'مۆڵەتی ئاگادارکردنەوە نەدراوە.';
        return false;
      }
      if (!a.isGranted) {
        message = 'مۆڵەتی «چالاکی جەستەیی» نەدراوە — بێ ئەوە هەنگاوەکان لە پشتەوە ناژمێردرێن.';
        return false;
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  Map<String, Object> _payload() {
    final h = Store.I.h;
    return <String, Object>{
      'steps': h.steps,
      'goal': stepGoal,
      'heightCm': h.heightCm,
      'weightKg': h.weightKg,
      'hr': h.hr,
      'day': Store.today,
    };
  }

  Future<bool> _start() async {
    try {
      final ok = await _ch.invokeMethod<bool>('start', _payload());
      running = ok ?? false;
      if (running) _hook();
      return running;
    } on MissingPluginException {
      message = 'کۆدی ناتیڤ هێشتا زیاد نەکراوە (بڕوانە NOTIFICATIONS.md).';
    } on PlatformException catch (e) {
      message = 'هەڵە: ${e.message ?? e.code}';
    } catch (_) {}
    running = false;
    return false;
  }

  Future<void> _stop() async {
    _unhook();
    try {
      await _ch.invokeMethod<void>('stop');
    } catch (_) {}
    running = false;
  }

  void _hook() {
    if (_hooked) return;
    _hooked = true;
    Store.I.addListener(_onStore);
    WidgetsBinding.instance.addObserver(this);
    _syncWater();
  }

  void _unhook() {
    if (!_hooked) return;
    _hooked = false;
    Store.I.removeListener(_onStore);
    WidgetsBinding.instance.removeObserver(this);
    _debounce?.cancel();
  }

  /// کاتێک داتای Store دەگۆڕێت، بە جیاوازی کەمترین 4 چرکە ناردنەکە دەکرێت (بۆ بەتاری)
  void _onStore() {
    final since = DateTime.now().difference(_lastPush);
    if (since >= const Duration(seconds: 4)) {
      _push();
    } else {
      _debounce?.cancel();
      _debounce = Timer(const Duration(seconds: 4) - since, _push);
    }
  }

  Future<void> _push() async {
    if (!running) return;
    _lastPush = DateTime.now();
    try {
      await _ch.invokeMethod<void>('update', _payload());
    } catch (_) {}
  }

  /// ئەو پەرداخە ئاوانەی لە notification ی Android دا زیاد کراون
  Future<void> _syncWater() async {
    if (!_isAndroid) return;
    try {
      final n = await _ch.invokeMethod<int>('takeWater') ?? 0;
      if (n > 0) Store.I.setWater(Store.I.waterN + n);
    } catch (_) {}
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _syncWater();
      _push();
    }
  }
}
