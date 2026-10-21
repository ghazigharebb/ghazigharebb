// VEX Health — هەژماری بەکارهێنەر
//
// • 'vexuser'      زانیارییەکانی هەژماری ئێستا (هەمان شێوەی وەشانی وێب)
// • 'vexreg-draft' ڕەشنووسی تۆمارکردن، بۆ ئەوەی ئەگەر ئەپەکە داخرا لە هەمان شوێنەوە بەردەوام بێت
// • 'vexaccounts'  هەژمارەکان لەسەر ئەم مۆبایلە دەمێننەوە دوای چوونە دەرەوە؛
//                  کاتێک دووبارە بە هەمان ژمارە دێیتەوە، هەموو داتاکەت دەگەڕێتەوە
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../arena/arena_host.dart' show reloadArena;
import '../core/store.dart';
import '../family/family_data.dart';
import 'reg_data.dart';

class Account extends ChangeNotifier {
  Account._();
  static final Account I = Account._();

  static const String kUser = 'vexuser';
  static const String kDraft = 'vexreg-draft';
  static const String kVault = 'vexaccounts';

  SharedPreferences? _sp;
  Map<String, dynamic>? user;

  Future<SharedPreferences?> _prefs() async {
    if (_sp != null) return _sp;
    try {
      _sp = await SharedPreferences.getInstance();
    } catch (_) {
      _sp = null;
    }
    return _sp;
  }

  Future<void> load() async {
    await _prefs();
    user = _readUser();
  }

  Map<String, dynamic>? _readUser() {
    final s = _sp?.getString(kUser);
    if (s == null) return null;
    try {
      final o = jsonDecode(s);
      if (o is Map) return Map<String, dynamic>.from(o);
    } catch (_) {}
    return null;
  }

  /// پێویستە خۆی تۆمار بکات؟
  bool get need {
    final u = user;
    if (u == null) return true;
    return '${u['name'] ?? ''}'.trim().isEmpty || asD(u['h']) <= 0 || asD(u['w']) <= 0;
  }

  String get name => '${user?['name'] ?? ''}'.trim();
  String get firstName => firstWord(name);
  String get initial {
    final n = name;
    return n.isEmpty ? 'V' : String.fromCharCode(n.runes.first).toUpperCase();
  }

  Future<void> saveUser(Map<String, dynamic> u) async {
    user = u;
    final sp = await _prefs();
    await sp?.setString(kUser, jsonEncode(u));
    notifyListeners();
  }

  // ---------- ڕەشنووس ----------
  Map<String, dynamic>? readDraft() {
    final s = _sp?.getString(kDraft);
    if (s == null) return null;
    try {
      final o = jsonDecode(s);
      if (o is Map) return Map<String, dynamic>.from(o);
    } catch (_) {}
    return null;
  }

  void saveDraft(Map<String, dynamic> d) {
    _sp?.setString(kDraft, jsonEncode(d));
  }

  void clearDraft() {
    _sp?.remove(kDraft);
  }

  /// بۆ داتای لاوەکی (وەک vexdevice و vexprofile)
  Map<String, dynamic> readMap(String key) {
    final s = _sp?.getString(key);
    if (s == null) return <String, dynamic>{};
    try {
      final o = jsonDecode(s);
      if (o is Map) return Map<String, dynamic>.from(o);
    } catch (_) {}
    return <String, dynamic>{};
  }

  void writeMap(String key, Map<String, dynamic> v) {
    _sp?.setString(key, jsonEncode(v));
  }

  // ---------- هەژمارەکانی سەر ئەم مۆبایلە ----------
  Map<String, dynamic> _vault() {
    final s = _sp?.getString(kVault);
    if (s == null) return <String, dynamic>{};
    try {
      final o = jsonDecode(s);
      if (o is Map) return Map<String, dynamic>.from(o);
    } catch (_) {}
    return <String, dynamic>{};
  }

  bool _own(String k) => k.startsWith('vex') && k != kVault && k != kDraft;

  /// وێنەیەکی هەموو داتاکانی ئەم هەژمارە
  Map<String, dynamic> _snap() {
    final sp = _sp;
    final o = <String, dynamic>{};
    if (sp == null) return o;
    for (final k in sp.getKeys()) {
      if (!_own(k)) continue;
      final v = sp.get(k);
      if (v is String || v is bool || v is int || v is double) {
        o[k] = v;
      } else if (v is List) {
        o[k] = v.map((e) => '$e').toList();
      }
    }
    return o;
  }

  /// هەژماری ئێستا لەسەر ئەم مۆبایلە پاشەکەوت دەکات
  Future<void> stash() async {
    final sp = await _prefs();
    final u = user;
    if (sp == null || u == null) return;
    final phone = '${u['phone'] ?? ''}';
    if (phone.isEmpty) return;
    final v = _vault();
    v[phone] = {'snap': _snap(), 'name': '${u['name'] ?? ''}', 'at': DateTime.now().millisecondsSinceEpoch};
    await sp.setString(kVault, jsonEncode(v));
  }

  /// هەژمارێکی پاشەکەوتکراو بەم ژمارەیە هەیە؟
  Map<String, dynamic>? accountFor(String phone) {
    final a = _vault()[phone];
    if (a is Map && a['snap'] is Map && (a['snap'] as Map)[kUser] != null) {
      return Map<String, dynamic>.from(a);
    }
    return null;
  }

  /// هەموو داتاکانی هەژمارەکە دەگەڕێنێتەوە
  Future<void> restore(Map<String, dynamic> a) async {
    final sp = await _prefs();
    final snap = a['snap'];
    if (sp == null || snap is! Map) return;
    // داتای کەسی پێشوو لادەبرێت پێش گەڕاندنەوە
    for (final k in sp.getKeys().toList()) {
      if (_own(k)) await sp.remove(k);
    }
    for (final e in snap.entries) {
      final k = '${e.key}';
      final v = e.value;
      if (!_own(k) || v == null) continue;
      if (v is String) {
        await sp.setString(k, v);
      } else if (v is bool) {
        await sp.setBool(k, v);
      } else if (v is int) {
        await sp.setInt(k, v);
      } else if (v is double) {
        await sp.setDouble(k, v);
      } else if (v is List) {
        await sp.setStringList(k, v.map((x) => '$x').toList());
      }
    }
    user = _readUser();
    await reloadStores();
    notifyListeners();
  }

  /// چوونە دەرەوە: هەژمارەکە پاشەکەوت دەکرێت و ئەپەکە پاک دەبێتەوە
  Future<void> logout() async {
    final sp = await _prefs();
    await stash();
    if (sp != null) {
      for (final k in sp.getKeys().toList()) {
        if (k.startsWith('vex') && k != kVault) await sp.remove(k);
      }
    }
    user = null;
    await reloadStores();
    notifyListeners();
  }

  Future<void> reloadStores() async {
    await Store.I.load();
    await FamilyStore.I.load();
    await reloadArena();
  }
}
