// VEX Health — داتای بازنەی خێزان و هاوڕێ (ئەندامەکان، بانگهێشتەکان، هاوبەشکردن)
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// ڕەنگی دۆخەکان: باشە / ئاگاداربە / پێویستی بە سەرنجە
class FK {
  FK._();
  static const Color g = Color(0xFF3CF08A);
  static const Color y = Color(0xFFFFBE4D);
  static const Color r = Color(0xFFFF5F7E);
  static const Color pink = Color(0xFFFF8FC8);
  static const Color none = Color(0xFF8CB7BF);

  static Color of(String st) => st == 'r' ? r : st == 'y' ? y : st == 'g' ? g : none;
  static String dot(String st) => st == 'r' ? '🔴' : st == 'y' ? '🟡' : '🟢';
}

/// ئەندامێکی بازنە (یان بانگهێشتێکی چاوەڕوان)
class FMember {
  FMember({
    required this.id,
    required this.n,
    required this.full,
    required this.rel,
    required this.e,
    required this.g0,
    required this.g1,
    required this.col,
    this.age = 30,
    this.hr = 70,
    this.steps = 3500,
    this.goal = 8000,
    this.sleep = 7,
    this.spo2 = 97,
    this.bat = 90,
    this.sync = 0,
    this.st = 'g',
    this.note = '',
    this.pend = false,
    this.code = '',
  });

  final String id;
  String n; // ناوی کورت (دایکم)
  String full; // ناوی تەواو
  String rel; // پەیوەندی
  String e; // ئیمۆجی
  int g0; // ڕەنگی سەرەتای گرادیەنت
  int g1; // ڕەنگی کۆتایی گرادیەنت
  int col; // ڕەنگی ئەندام (بازنەی هەنگاو)
  int age;
  int hr;
  int steps;
  int goal;
  double sleep;
  int spo2;
  int bat;
  int sync; // خولەک لەمەوبەر
  String st; // g / y / r
  String note;
  bool pend; // چاوەڕوانی ڕەزامەندی
  String code; // کۆدی بانگهێشت

  Color get color => Color(col);
  Color get grad0 => Color(g0);
  Color get grad1 => Color(g1);
  Color get stColor => FK.of(st);
  double get stepFrac => goal <= 0 ? 0 : (steps / goal).clamp(0.0, 1.0).toDouble();

  Map<String, dynamic> toJson() => {
        'id': id,
        'n': n,
        'full': full,
        'rel': rel,
        'e': e,
        'g0': g0,
        'g1': g1,
        'col': col,
        'age': age,
        'hr': hr,
        'steps': steps,
        'goal': goal,
        'sleep': sleep,
        'spo2': spo2,
        'bat': bat,
        'sync': sync,
        'st': st,
        'note': note,
        'pend': pend,
        'code': code,
      };

  static int _i(Object? v, int d) => v is num ? v.toInt() : d;
  static double _d(Object? v, double d) => v is num ? v.toDouble() : d;
  static String _s(Object? v, String d) => v is String ? v : d;

  static FMember? fromJson(Object? o) {
    if (o is! Map) return null;
    final id = _s(o['id'], '');
    final n = _s(o['n'], '');
    if (id.isEmpty || n.isEmpty) return null;
    return FMember(
      id: id,
      n: n,
      full: _s(o['full'], n),
      rel: _s(o['rel'], ''),
      e: _s(o['e'], '🙂'),
      g0: _i(o['g0'], 0xFF445566),
      g1: _i(o['g1'], 0xFF223344),
      col: _i(o['col'], 0xFF2FE6F3),
      age: _i(o['age'], 30),
      hr: _i(o['hr'], 70),
      steps: _i(o['steps'], 3500),
      goal: _i(o['goal'], 8000),
      sleep: _d(o['sleep'], 7),
      spo2: _i(o['spo2'], 97),
      bat: _i(o['bat'], 90),
      sync: _i(o['sync'], 0),
      st: _s(o['st'], 'g'),
      note: _s(o['note'], ''),
      pend: o['pend'] == true,
      code: _s(o['code'], ''),
    );
  }
}

/// ئاگادارکردنەوەیەک
class FAlert {
  const FAlert(this.emoji, this.kind, this.m, this.text, this.sub, this.action);
  final String emoji;
  final String kind; // g / y / r
  final FMember m;
  final String text; // دوای ناوەکە دێت
  final String sub;
  final String action; // call / remind / cheer
}

/// یاریزانێکی چالێنجی هەفتانە
class FPlayer {
  const FPlayer(this.n, this.steps, this.color);
  final String n;
  final double steps;
  final Color color;
}

/// شتێک کە دەتوانیت هاوبەشی بکەیت
class FShare {
  const FShare(this.key, this.emoji, this.label, [this.sub]);
  final String key;
  final String emoji;
  final String label;
  final String? sub;
}

const List<FShare> kShares = [
  FShare('steps', '👣', 'هەنگاو و چالاکی'),
  FShare('hr', '❤️', 'لێدانی دڵ'),
  FShare('sleep', '🌙', 'خەو'),
  FShare('spo2', '🫁', 'ئۆکسجینی خوێن'),
  FShare('stress', '🧠', 'سترێس'),
  FShare('food', '🍽️', 'خواردن و کالۆری'),
  FShare('sos', '🚨', 'ئاگادارکردنەوەی نائاسایی', 'ئەگەر دڵ یان SpO₂ نائاسایی بوو'),
];

/// پەیوەندییەکان لە شیتی زیادکردن
const List<List<String>> kRelations = [
  ['دایک', '👩'],
  ['باوک', '👨'],
  ['هاوسەر', '💑'],
  ['منداڵ', '🧒'],
  ['برا / خوشک', '🧑‍🤝‍🧑'],
  ['باپیر / داپیر', '👴'],
  ['هاوڕێ', '🤝'],
  ['هاوکار', '💼'],
];

/// ناوی پێشنیارکراو بە پێی پەیوەندی
String? relDefaultName(String rel) {
  switch (rel) {
    case 'دایک':
      return 'دایکم';
    case 'باوک':
      return 'باوکم';
    case 'هاوسەر':
      return 'هاوسەرەکەم';
  }
  return null;
}

/// ئەندامی تۆ (ناوەڕاستی بازنەکە)
class FMe {
  FMe._();
  static const String letter = 'G';
  static const String name = 'تۆ';
  static const int steps = 2225;
  static const Color color = Color(0xFF2FE6F3);
}

const int kChallengeGoal = 150000;
const int kMaxCircle = 8;

class FamilyStore extends ChangeNotifier {
  FamilyStore._();
  static final FamilyStore I = FamilyStore._();

  static const String _key = 'vexfamily';

  List<FMember> members = defaults();
  List<FMember> pending = [];
  Map<String, bool> share = defaultShare();
  SharedPreferences? _sp;

  static Map<String, bool> defaultShare() => {
        'steps': true,
        'hr': true,
        'sleep': true,
        'spo2': true,
        'stress': false,
        'food': false,
        'sos': true,
      };

  static List<FMember> defaults() => [
        FMember(
            id: 'm1', n: 'دایکم', full: 'ئامینە', rel: 'دایک', e: '👩',
            g0: 0xFFFF8FC8, g1: 0xFFC94B8B, col: 0xFFFF8FC8,
            age: 58, hr: 78, steps: 4120, goal: 7000, sleep: 6.1, spo2: 95, bat: 64, sync: 5,
            st: 'y', note: 'هەنگاوی ئەمڕۆی کەمە'),
        FMember(
            id: 'm2', n: 'باوکم', full: 'محەمەد', rel: 'باوک', e: '👨',
            g0: 0xFF6AA8FF, g1: 0xFF2F5FBF, col: 0xFF6AA8FF,
            age: 63, hr: 84, steps: 1980, goal: 6000, sleep: 7.2, spo2: 91, bat: 18, sync: 22,
            st: 'r', note: 'SpO₂ ـی شەوی ڕابردوو 91% بوو'),
        FMember(
            id: 'm3', n: 'ڕۆژان', full: 'ڕۆژان', rel: 'هاوسەر', e: '👩‍🦱',
            g0: 0xFF9B7BFF, g1: 0xFF5A3DD6, col: 0xFF9B7BFF,
            age: 29, hr: 66, steps: 8900, goal: 10000, sleep: 7.6, spo2: 98, bat: 81, sync: 2,
            st: 'g', note: 'هەموو شتێک باشە'),
        FMember(
            id: 'm4', n: 'ڕێبین', full: 'ڕێبین', rel: 'هاوڕێ', e: '🧔',
            g0: 0xFFFFBE4D, g1: 0xFFE07B10, col: 0xFFFFBE4D,
            age: 31, hr: 62, steps: 12340, goal: 10000, sleep: 6.8, spo2: 97, bat: 45, sync: 1,
            st: 'g', note: 'ئامانجی ئەمڕۆی تەواو کرد 🎉'),
      ];

  int get total => members.length + pending.length;
  bool get full => total >= kMaxCircle;

  Future<void> load() async {
    try {
      final sp = await SharedPreferences.getInstance();
      _sp = sp;
      // دەستپێکردنەوە لە سفرەوە (بۆ چوونە دەرەوە / گەڕاندنەوەی هەژمار)
      members = defaults();
      pending = [];
      share = defaultShare();
      final s = sp.getString(_key);
      if (s != null) {
        final o = jsonDecode(s);
        if (o is Map && o['members'] is List) {
          members = (o['members'] as List).map(FMember.fromJson).whereType<FMember>().toList();
          if (o['pending'] is List) {
            pending = (o['pending'] as List).map(FMember.fromJson).whereType<FMember>().toList();
            for (final p in pending) {
              p.pend = true;
            }
          }
          if (o['share'] is Map) {
            final m = o['share'] as Map;
            final d = defaultShare();
            for (final k in d.keys) {
              final v = m[k];
              if (v is bool) d[k] = v;
            }
            share = d;
          }
        }
      }
    } catch (_) {
      // ئەگەر خەزنکردن کار نەکات، بە داتای نموونە بەردەوام دەبێت
    }
    notifyListeners();
  }

  void _save() {
    final sp = _sp;
    if (sp != null) {
      sp.setString(
        _key,
        jsonEncode({
          'members': members.map((e) => e.toJson()).toList(),
          'pending': pending.map((e) => e.toJson()).toList(),
          'share': share,
        }),
      );
    }
    notifyListeners();
  }

  FMember? byId(String id) {
    for (final m in members) {
      if (m.id == id) return m;
    }
    for (final m in pending) {
      if (m.id == id) return m;
    }
    return null;
  }

  void toggleShare(String k) {
    share[k] = !(share[k] ?? false);
    _save();
  }

  void remove(String id) {
    members.removeWhere((m) => m.id == id);
    _save();
  }

  void cancelInvite(String id) {
    pending.removeWhere((m) => m.id == id);
    _save();
  }

  FMember invite({required String name, required String rel, required String emoji, required String code}) {
    final p = FMember(
      id: 'p${DateTime.now().millisecondsSinceEpoch}',
      n: name,
      full: name,
      rel: rel,
      e: emoji,
      g0: 0xFF445566,
      g1: 0xFF223344,
      col: 0xFFFFBE4D,
      pend: true,
      code: code,
      note: 'بانگهێشت نێردرا',
    );
    pending.add(p);
    _save();
    return p;
  }

  static const List<int> _newCols = [0xFF5BE3A4, 0xFFFF9466, 0xFF7FE7FF, 0xFFC7B5FF];

  /// قبوڵکردنی بانگهێشت (دیمۆ)
  FMember accept(String id) {
    final i = pending.indexWhere((m) => m.id == id);
    final p = i >= 0 ? pending.removeAt(i) : null;
    final col = _newCols[members.length % _newCols.length];
    final m = FMember(
      id: 'm${DateTime.now().millisecondsSinceEpoch}',
      n: p?.n ?? 'ئەندام',
      full: p?.full ?? 'ئەندام',
      rel: p?.rel ?? '',
      e: p?.e ?? '🙂',
      g0: col,
      g1: 0xFF223344,
      col: col,
      age: 30,
      hr: 70,
      steps: 3500,
      goal: 8000,
      sleep: 7,
      spo2: 97,
      bat: 90,
      sync: 0,
      st: 'g',
      note: 'تازە هاتە ناو بازنەکە',
    );
    members.add(m);
    _save();
    return m;
  }

  /// ئاگادارکردنەوەکان (لە داتای ئەندامەکانەوە)
  List<FAlert> alerts() {
    final a = <FAlert>[];
    for (final m in members) {
      if (m.spo2 < 93) {
        a.add(FAlert('🫁', 'r', m, ': SpO₂ ـی ${m.spo2}% بوو', 'لەوانەیە پێویست بێت پزیشک ببینێت', 'call'));
      }
      if (m.bat < 20) {
        a.add(FAlert('🔋', 'y', m, ': باتری Band ـەکەی ${m.bat}% ـە', 'پێی بڵێ بیخاتە سەر شەحن', 'remind'));
      }
      if (m.steps < m.goal * 0.5 && m.age > 50) {
        a.add(FAlert('🚶', 'y', m, ' ئەمڕۆ کەم ڕۆیشتووە', '${fmtN(m.steps)} لە ${fmtN(m.goal)} هەنگاو', 'cheer'));
      }
      if (m.steps >= m.goal) {
        a.add(FAlert('🎉', 'g', m, ' ئامانجی ئەمڕۆی تەواو کرد!', '${fmtN(m.steps)} هەنگاو', 'cheer'));
      }
    }
    return a;
  }

  /// گرنگترین ئاگادارکردنەوە بۆ کارتی سەرەکی
  FAlert? topAlert() {
    final a = alerts();
    for (final k in ['r', 'y', 'g']) {
      for (final x in a) {
        if (x.kind == k) return x;
      }
    }
    return null;
  }

  /// چالێنجی هەفتانە: تۆ + ئەندامەکان
  List<FPlayer> players() => [
        const FPlayer(FMe.name, FMe.steps * 2.6, FMe.color),
        for (final m in members) FPlayer(m.n, m.steps * 2.6, m.color),
      ];
}

/// ژمارە بە فاریزە (1,980)
String fmtN(num v) {
  final n = v.round();
  final s = n.abs().toString();
  final b = StringBuffer();
  for (int i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
    b.write(s[i]);
  }
  return (n < 0 ? '-' : '') + b.toString();
}

/// ژمارەی خەو (6.1 / 7)
String fmtSleep(double h) => h == h.roundToDouble() ? h.toStringAsFixed(0) : h.toStringAsFixed(1);

/// چەند ڕۆژ ماوە تا کۆتایی هەفتە (هەینی)
int challengeDaysLeft() {
  final wd = DateTime.now().weekday; // 1 = دووشەممە ... 5 = هەینی ... 7 = یەکشەممە
  return (DateTime.friday - wd + 7) % 7;
}

/// کۆدی بانگهێشت: VX-AB12
String newInviteCode() {
  const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  final r = math.Random();
  return 'VX-${List.generate(4, (_) => chars[r.nextInt(chars.length)]).join()}';
}
