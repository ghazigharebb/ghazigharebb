// VEX Health — هەژماری بەکارهێنەر
//
// • 'vexuser'      زانیارییەکانی هەژماری ئێستا (هەمان شێوەی وەشانی وێب)
// • 'vexreg-draft' ڕەشنووسی تۆمارکردن، بۆ ئەوەی ئەگەر ئەپەکە داخرا لە هەمان شوێنەوە بەردەوام بێت
// • 'vexaccounts'  هەژمارەکان لەسەر ئەم مۆبایلە دەمێننەوە دوای چوونە دەرەوە؛
//                  کاتێک دووبارە بە هەمان ژمارە (یان هەمان Gmail) دێیتەوە، هەموو داتاکەت دەگەڕێتەوە:
//                  Plus، Band، خواردن، ئاو، خێزان… هەموو شتێک وەک کۆتا جار
// • 'vxgmails'     لیستی Gmail ـەکانی ئەم مۆبایلە (بە ئەنقەست بە 'vex' دەست پێناکات، بۆ ئەوەی هەرگیز پاک نەکرێتەوە)
import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../band/band_state.dart';
import '../core/store.dart';
import '../family/family_data.dart';
import '../plus/plus_state.dart';
import 'reg_data.dart';

class Account extends ChangeNotifier {
  Account._();
  static final Account I = Account._();

  static const String kUser = 'vexuser';
  static const String kDraft = 'vexreg-draft';
  static const String kVault = 'vexaccounts';
  static const String kGmails = 'vxgmails';

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

  /// ناسنامەی هەژمارەکە: ژمارەی مۆبایل، یان Gmail (بچووک کراو)
  static String idOf(String v) {
    final t = v.trim();
    return t.contains('@') ? t.toLowerCase() : t;
  }

  /// هەژماری ئێستا لەسەر ئەم مۆبایلە پاشەکەوت دەکات (بە ژمارە یان بە Gmail)
  Future<void> stash() async {
    final sp = await _prefs();
    final u = user;
    if (sp == null || u == null) return;
    final phone = '${u['phone'] ?? ''}'.trim();
    final email = idOf('${u['email'] ?? ''}');
    final id = phone.isNotEmpty ? phone : email;
    if (id.isEmpty) return;
    final v = _vault();
    v[id] = {
      'snap': _snap(),
      'name': '${u['name'] ?? ''}',
      'email': email,
      'phone': phone,
      'at': DateTime.now().millisecondsSinceEpoch,
    };
    await sp.setString(kVault, jsonEncode(v));
    if (email.isNotEmpty) await rememberGmail(email, '${u['name'] ?? ''}');
  }

  /// هەژمارێکی پاشەکەوتکراو بەم ژمارە یان Gmail ـە هەیە؟
  Map<String, dynamic>? accountFor(String id) {
    final a = _vault()[idOf(id)];
    if (a is Map && a['snap'] is Map && (a['snap'] as Map)[kUser] != null) {
      return Map<String, dynamic>.from(a);
    }
    return null;
  }

  // ---------- لیستی Gmail ـەکان ----------
  List<Map<String, dynamic>> _gmailList() {
    final s = _sp?.getString(kGmails);
    if (s == null) return <Map<String, dynamic>>[];
    try {
      final o = jsonDecode(s);
      if (o is List) {
        return [
          for (final e in o)
            if (e is Map && '${e['email'] ?? ''}'.isNotEmpty) Map<String, dynamic>.from(e),
        ];
      }
    } catch (_) {}
    return <Map<String, dynamic>>[];
  }

  /// Gmail ێک بۆ لیستی ئەم مۆبایلە زیاد دەکات (ئەگەر هەبوو، ناوەکەی نوێ دەکاتەوە)
  Future<void> rememberGmail(String email, [String name = '']) async {
    final sp = await _prefs();
    final e = idOf(email);
    if (sp == null || e.isEmpty) return;
    final l = _gmailList();
    final i = l.indexWhere((x) => x['email'] == e);
    if (i >= 0) {
      if (name.trim().isNotEmpty) l[i]['name'] = name.trim();
    } else {
      l.add({'email': e, 'name': name.trim()});
    }
    await sp.setString(kGmails, jsonEncode(l));
  }

  /// هەموو Gmail ـەکانی ئەم مۆبایلە: لیستی خۆی + ئەوانەی هەژماری پاشەکەوتکراویان هەیە.
  /// `has` = داتای پاشەکەوتکراو هەیە (تاگی «داتای هەیە»)
  List<Map<String, dynamic>> gmails() {
    final out = <String, Map<String, dynamic>>{};
    for (final g in _gmailList()) {
      out['${g['email']}'] = {'email': g['email'], 'name': '${g['name'] ?? ''}', 'has': false};
    }
    _vault().forEach((k, a) {
      if (a is! Map) return;
      final em = idOf('${a['email'] ?? ''}');
      if (em.isEmpty || a['snap'] is! Map) return;
      final nm = '${a['name'] ?? ''}';
      out[em] = {'email': em, 'name': nm.isNotEmpty ? nm : '${out[em]?['name'] ?? ''}', 'has': true};
    });
    return out.values.toList();
  }

  // ---------- پاشەکەوتکردنی خۆکار ----------
  Timer? _auto;
  _LifeObs? _obs;

  /// هەر 45 چرکە + کاتێک ئەپ دەچێتە باکگراوند، هەژمارەکە پاشەکەوت دەکرێت
  /// (بۆ ئەوەی ئەگەر ئەپ داخرا، هەموو شتێک لە ئاخرین کۆنێکتدا بمێنێتەوە)
  void startAutoStash() {
    _auto ??= Timer.periodic(const Duration(seconds: 45), (_) {
      if (user != null) stash();
    });
    if (_obs == null) {
      _obs = _LifeObs(() {
        if (user != null) stash();
      });
      WidgetsBinding.instance.addObserver(_obs!);
    }
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
    await PlusState.I.load(); // Plus ی هەژمارەکە دەگەڕێتەوە (یان free)
    await BandState.I.load(); // Band ـی هەژمارەکە دەگەڕێتەوە
  }
}

class _LifeObs with WidgetsBindingObserver {
  _LifeObs(this.onLeave);
  final VoidCallback onLeave;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      onLeave();
    }
  }
}
