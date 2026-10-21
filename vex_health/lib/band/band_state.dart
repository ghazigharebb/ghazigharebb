// VEX Health — دۆخی پەیوەستبوونی Band
//
// هەموو شاشەکان لێرەوە دەزانن Band پەیوەستە یان نا (BandState.I.connected).
// کاتێک پەیوەست نییە، ئەو بەشانەی لە Band ـەوە دێن «—» + «پەیوەست نییە» نیشان دەدەن
// (هەرگیز 0 یان ژمارەی کۆنی ساختە نا).
//
// بۆ بەستنەوەی BLE ی ڕاستەقینە: لە کاتی پچڕان/پەیوەستبوون بانگی بکە
//     BandState.I.setConnected(false, lastSync: '12:42');
//     BandState.I.setConnected(true);
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/theme.dart';
import '../onboarding/account.dart';
import '../plus/plus_state.dart';

class BandState extends ChangeNotifier {
  BandState._();
  static final BandState I = BandState._();

  static const String _kOn = 'vex_band_on';
  static const String _kLast = 'vex_band_last';

  SharedPreferences? _sp;
  bool _connected = true;
  bool? _override;

  /// کاتی دوایین هاوکاتکردن (HH:mm) — '' واتە هیچ کاتێک هاوکات نەکراوە
  String lastSync = '';

  /// لە کاتی هەوڵی پەیوەستکردنەوەدا
  bool reconnecting = false;

  bool get connected => _connected;

  /// ئایا ئەم هەژمارە هەرگیز Band ی پەیوەست کردووە؟ (نەخێر ← کارتی «پەیوەستکردن / کڕین»)
  bool get everPaired => _paired() || lastSync.isNotEmpty || (_override ?? false);

  Future<void> load() async {
    try {
      final sp = await SharedPreferences.getInstance();
      _sp = sp;
      if (sp.containsKey(_kOn)) _override = sp.getBool(_kOn);
      lastSync = sp.getString(_kLast) ?? '';
    } catch (_) {}
    Account.I.addListener(_recalc);
    _connected = _override ?? _paired();
    notifyListeners();
  }

  /// بەپێی هەژمار: ئەگەر لە کاتی تۆمارکردن Band پەیوەست کرابێت
  bool _paired() {
    final b = Account.I.user?['band'];
    return b is Map && b['paired'] == true;
  }

  void _recalc() {
    final v = _override ?? _paired();
    if (v != _connected) {
      _connected = v;
      notifyListeners();
    }
  }

  /// لەلایەن BLE یان دوگمەی تاقیکردنەوەوە بانگ دەکرێت
  void setConnected(bool on, {String? lastSync}) {
    _override = on;
    _connected = on;
    reconnecting = false;
    if (!on && lastSync != null && lastSync.isNotEmpty) this.lastSync = lastSync;
    final sp = _sp;
    if (sp != null) {
      sp.setBool(_kOn, on);
      sp.setString(_kLast, this.lastSync);
    }
    notifyListeners();
  }

  /// دوگمەی «پەیوەستکردنەوە». لێرەدا نموونەیە؛ لەگەڵ BLE ی ڕاستەقینە دەگۆڕدرێت بە دۆزینەوەی Band
  Future<void> reconnect() async {
    if (reconnecting || _connected) return;
    reconnecting = true;
    notifyListeners();
    await Future<void>.delayed(const Duration(milliseconds: 1600));
    if (!reconnecting) return;
    setConnected(true);
    final gift = await PlusState.I.grantBandGift();
    toast(gift ? 'Band پەیوەست کرا 🎁 6 مانگ VEX Plus بە خۆڕایی' : 'Band پەیوەست کرا ✓');
  }
}
