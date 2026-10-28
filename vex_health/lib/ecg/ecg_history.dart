// VEX Health — مێژووی پێوانەکانی ECG (لەسەر مۆبایلەکە، SharedPreferences)
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'ecg_controller.dart';

class EcgHistory {
  EcgHistory._();
  static const String _key = 'vex_ecg_hist_v1';
  static const int maxItems = 30;

  static Future<List<EcgResult>> load() async {
    try {
      final sp = await SharedPreferences.getInstance();
      final raw = sp.getString(_key);
      if (raw == null || raw.isEmpty) return <EcgResult>[];
      final list = jsonDecode(raw) as List;
      final out = <EcgResult>[];
      for (final e in list) {
        final r = EcgResult.fromJson(e);
        if (r != null) out.add(r);
      }
      return out;
    } catch (_) {
      return <EcgResult>[];
    }
  }

  static Future<void> _save(List<EcgResult> all) async {
    try {
      final sp = await SharedPreferences.getInstance();
      await sp.setString(_key, jsonEncode(all.map((e) => e.toJson()).toList()));
    } catch (_) {}
  }

  /// نوێترین لە سەرەوە
  static Future<List<EcgResult>> add(EcgResult r) async {
    final all = await load();
    all.removeWhere((e) => e.at.millisecondsSinceEpoch == r.at.millisecondsSinceEpoch);
    all.insert(0, r);
    if (all.length > maxItems) all.removeRange(maxItems, all.length);
    await _save(all);
    return all;
  }

  static Future<List<EcgResult>> remove(EcgResult r) async {
    final all = await load();
    all.removeWhere((e) => e.at.millisecondsSinceEpoch == r.at.millisecondsSinceEpoch);
    await _save(all);
    return all;
  }
}
