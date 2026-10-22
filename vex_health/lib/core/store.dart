// VEX Health — داتای ئەپ (Band، خواردن، ئاو)
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../onboarding/reg_data.dart' show kcalGoalFor;

/// داتاکانی Band (نموونە — لە ئەپی ڕاستەقینەدا لە Band ـەوە دێن)
class Health {
  int hr = 73, rhr = 70, hrAvg = 76, spo2 = 93, spo2Min = 90, spo2Avg = 96;
  int hrv = 54, hrvAvg = 53, stress = 55;
  double temp = 34.2, tempMin = 33.1, tempAvg = 33.8, km = 1.6;
  int steps = 2225, kcal = 67, active = 22;
  int heightCm = 179, weightKg = 77, goal = 2960;
}

class FoodItem {
  FoodItem({
    required this.n,
    required this.kcal,
    this.p = 0,
    this.c = 0,
    this.f = 0,
    required this.at,
    this.v = 'ok',
    this.e = '🍽️',
    this.slot = '',
  });

  final String n;
  final int kcal;
  final int p;
  final int c;
  final int f;
  final String at;
  final String v;
  final String e;

  /// ژەم: b بەیانی، l نیوەڕۆ، s سووک، d ئێوارە، n شەو
  final String slot;

  Map<String, dynamic> toJson() => {'n': n, 'kcal': kcal, 'p': p, 'c': c, 'f': f, 'at': at, 'v': v, 'e': e, 'slot': slot};

  static FoodItem fromJson(Map<String, dynamic> j) => FoodItem(
        n: '${j['n'] ?? ''}',
        kcal: toInt(j['kcal']),
        p: toInt(j['p']),
        c: toInt(j['c']),
        f: toInt(j['f']),
        at: '${j['at'] ?? ''}',
        v: '${j['v'] ?? 'ok'}',
        e: '${j['e'] ?? '🍽️'}',
        slot: '${j['slot'] ?? ''}',
      );
}

int toInt(dynamic v) {
  if (v is num) return v.round();
  return int.tryParse('$v') ?? 0;
}

double toDouble(dynamic v) {
  if (v is num) return v.toDouble();
  return double.tryParse('$v') ?? 0;
}

class Totals {
  const Totals(this.kcal, this.p, this.c, this.f);
  final int kcal;
  final int p;
  final int c;
  final int f;
}

class Store extends ChangeNotifier {
  Store._();
  static final Store I = Store._();

  static const int glassMl = 250;

  final Health h = Health();
  List<FoodItem> food = <FoodItem>[];
  int waterN = 0;
  int waterGoalMl = 2000;
  SharedPreferences? _sp;

  static String get today {
    final d = DateTime.now();
    return '${d.year}-${d.month}-${d.day}';
  }

  Future<void> load() async {
    try {
      final sp = await SharedPreferences.getInstance();
      _sp = sp;
      // دەستپێکردنەوە لە سفرەوە (بۆ چوونە دەرەوە / گەڕاندنەوەی هەژمار)
      food = <FoodItem>[];
      waterN = 0;
      _applyUser(sp.getString('vexuser'));
      final s = sp.getString('vexhome-food');
      if (s != null) {
        final o = jsonDecode(s);
        if (o is Map && o['day'] == today && o['items'] is List) {
          food = (o['items'] as List)
              .whereType<Map>()
              .map((m) => FoodItem.fromJson(Map<String, dynamic>.from(m)))
              .toList();
        }
      }
      final w = sp.getString('vexwater');
      if (w != null) {
        final o = jsonDecode(w);
        if (o is Map && o['day'] == today && o['n'] is num) {
          waterN = (o['n'] as num).toInt();
        }
      }
    } catch (_) {
      // ئەگەر خەزنکردن کار نەکات، ئەپەکە بە داتای نموونە بەردەوام دەبێت
    }
    notifyListeners();
  }

  /// باڵا، کێش و ئامانجی کالۆری لە هەژمارەکەوە
  void _applyUser(String? raw) {
    final d = Health();
    h.heightCm = d.heightCm;
    h.weightKg = d.weightKg;
    h.goal = d.goal;
    waterGoalMl = 2000;
    if (raw == null) return;
    try {
      final o = jsonDecode(raw);
      if (o is! Map) return;
      final hh = toInt(o['h']);
      final ww = toDouble(o['w']);
      if (hh >= 100 && hh <= 250) h.heightCm = hh;
      if (ww >= 25 && ww <= 250) h.weightKg = ww.round();
      final g = kcalGoalFor(o);
      if (g > 0) h.goal = g;
      final p = o['plan'];
      if (p is Map && toInt(p['water']) >= 1000) waterGoalMl = toInt(p['water']);
    } catch (_) {}
  }

  void _saveFood() {
    final sp = _sp;
    if (sp == null) return;
    sp.setString('vexhome-food', jsonEncode({'day': today, 'items': food.map((e) => e.toJson()).toList()}));
  }

  Totals totals() {
    int k = 0, p = 0, c = 0, f = 0;
    for (final x in food) {
      k += x.kcal;
      p += x.p;
      c += x.c;
      f += x.f;
    }
    return Totals(k, p, c, f);
  }

  /// بودجەی کالۆری = ئامانج + ئەوەی سووتاوە
  int get budget => h.goal + h.kcal;
  int get left => budget - totals().kcal;

  void addFood(FoodItem it) {
    food.insert(0, it);
    _saveFood();
    notifyListeners();
  }

  void removeFirst() {
    if (food.isEmpty) return;
    food.removeAt(0);
    _saveFood();
    notifyListeners();
  }

  int get waterGlasses => clampInt((waterGoalMl / glassMl).round(), 6, 12);

  void setWater(int n) {
    waterN = clampInt(n, 0, waterGlasses);
    final sp = _sp;
    if (sp != null) sp.setString('vexwater', jsonEncode({'day': today, 'n': waterN}));
    notifyListeners();
  }
}

int clampInt(int v, int lo, int hi) => v < lo ? lo : (v > hi ? hi : v);
