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
import 'ble/vex_ble.dart';

class BandState extends ChangeNotifier {
  BandState._();
  static final BandState I = BandState._();

  static const String _kOn = 'vex_band_on';
  static const String _kLast = 'vex_band_last';

  SharedPreferences? _sp;
  bool _connected = true;
  bool? _override;
  bool _listening = false;

  /// کاتی دوایین هاوکاتکردن (HH:mm) — '' واتە هیچ کاتێک هاوکات نەکراوە
  String lastSync = '';

  /// لە کاتی هەوڵی پەیوەستکردنەوەدا
  bool reconnecting = false;

  /// Band ی BLE ی پەیوەستە، بەڵام لە دەستت نییە (VexBand ـەوە دیاری دەکرێت)
  bool offWrist = false;

  /// «پەیوەستە» = BLE ئامادەیە + Band لە دەستە. لە دەست نەبێت هەموو شاشەکان وەک پچڕاو (سوور و «—») نیشان دەدەن.
  bool get connected => _connected && !offWrist;

  /// ئایا BLE خۆی ئامادەیە (بێ گوێدان بە لە دەست بوون)؟
  bool get bleUp => _connected;

  void setOffWrist(bool v) {
    if (offWrist == v) return;
    offWrist = v;
    if (v) {
      final t = DateTime.now();
      lastSync = '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
      _sp?.setString(_kLast, lastSync);
    }
    notifyListeners();
  }

  /// ئایا ئەم هەژمارە هەرگیز Band ی پەیوەست کردووە؟ (نەخێر ← کارتی «پەیوەستکردن / کڕین»)
  bool get everPaired => _paired() || lastSync.isNotEmpty || (_override ?? false);

  Future<void> load() async {
    try {
      final sp = await SharedPreferences.getInstance();
      _sp = sp;
      _override = sp.containsKey(_kOn) ? sp.getBool(_kOn) : null;
      lastSync = sp.getString(_kLast) ?? '';
    } catch (_) {}
    if (!_listening) {
      _listening = true;
      Account.I.addListener(_recalc);
    }
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
    if (!on) offWrist = false;
    reconnecting = false;
    if (!on && lastSync != null && lastSync.isNotEmpty) this.lastSync = lastSync;
    final sp = _sp;
    if (sp != null) {
      sp.setBool(_kOn, on);
      sp.setString(_kLast, this.lastSync);
    }
    notifyListeners();
  }

  /// دوگمەی «پەیوەستکردنەوە»: BLE ی ڕاستەقینە (سکان ← پەیوەستبوون).
  /// لە debug دا ئەگەر Band نەدۆزرایەوە، نموونەی دیزاین بەکاردێت.
  Future<void> reconnect() async {
    // BLE ئامادەیە بەڵام Band لە دەست نییە: پەیوەستکردنەوە بێسوودە
    if (_connected && offWrist) {
      toast('Band لە دەستت نییە — لە دەستت بکە');
      return;
    }
    if (reconnecting || _connected) return;
    reconnecting = true;
    notifyListeners();
    var ok = false;
    try {
      ok = await VexBand.I.quickConnect();
    } catch (_) {}
    if (!reconnecting) return;
    if (!ok && kDebugMode) {
      await Future<void>.delayed(const Duration(milliseconds: 1200));
      ok = true; // تەنها بۆ تاقیکردنەوەی دیزاین
    }
    if (!ok) {
      reconnecting = false;
      notifyListeners();
      toast('Band نەدۆزرایەوە — Band نزیک بێنەوە و بلووتوس بکەرەوە');
      return;
    }
    setConnected(true);
    final gift = await PlusState.I.grantBandGift();
    toast(gift ? 'Band پەیوەست کرا 🎁 6 مانگ VEX Plus بە خۆڕایی' : 'Band پەیوەست کرا ✓');
  }
}
