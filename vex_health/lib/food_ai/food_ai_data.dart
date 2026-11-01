// VEX AI Food v2 — داتای خواردن، یەکەکان و بڕ بە وشە
//
// وێنەکان هەمان وێنە کۆنەکانی ئەپن (بازنەیی، بێ باگراوند، PNG/WEBP)
// خۆراکەکان بۆ هەر 100 گرام (یان 100 مل) ن و بۆ هەر یەکەیەک بە گرام دەگۆڕدرێن.
import 'dart:math' as math;

/// یەکەی پێوانە
class FUnit {
  const FUnit(this.id, this.word, this.steps);
  final String id;

  /// ناوی یەکە: قاپ، کاسە، کوپ...
  final String word;

  /// بڕە دیاریکراوەکان بۆ + و −
  final List<double> steps;

  bool get grams => id == 'g' || id == 'ml';
}

const List<double> _half = [0.5, 1, 1.5, 2, 2.5, 3, 4];
const List<double> _count = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 12, 15, 20];
const List<double> _gram = [25, 50, 75, 100, 125, 150, 175, 200, 250, 300, 350, 400, 450, 500, 600, 750, 1000];

const Map<String, FUnit> kUnits = {
  'qap': FUnit('qap', 'قاپ', _half),
  'kasa': FUnit('kasa', 'کاسە', _half),
  'kup': FUnit('kup', 'کوپ', _half),
  'parcha': FUnit('parcha', 'پارچە', _half),
  'shish': FUnit('shish', 'شیش', _count),
  'dana': FUnit('dana', 'دانە', _count),
  'mlak': FUnit('mlak', 'مڵاک', _count),
  'g': FUnit('g', 'گرام', _gram),
  'ml': FUnit('ml', 'مل', _gram),
};

FUnit unitOf(String id) => kUnits[id] ?? kUnits['g']!;

const List<String> _num = ['', 'یەک', 'دوو', 'سێ', 'چوار', 'پێنج', 'شەش', 'حەوت', 'هەشت', 'نۆ', 'دە'];

/// ژمارە بە ڕەقەمی ئینگلیزی و ڕاستەوخۆ چەپ‌بۆ‌ڕاست
String _d(num v) => '\u2066${v == v.roundToDouble() ? v.round() : v}\u2069';

/// بڕ بە وشەی ڕوون: «نیو قاپ»، «یەک قاپ»، «قاپ و نیو»، «دوو شیش»، «150 گرام»
String qtyWord(double q, String unitId) {
  final u = unitOf(unitId);
  if (u.grams) return '${_d(q)} ${u.word}';
  if ((q - 0.25).abs() < 0.01) return 'چارەکێک ${u.word}';
  if ((q - 0.5).abs() < 0.01) return 'نیو ${u.word}';
  final whole = q.floor();
  final half = (q - whole - 0.5).abs() < 0.01;
  if (whole == 1 && half) return '${u.word} و نیو';
  final w = whole <= 10 ? _num[whole] : _d(whole);
  if (whole == 0) return '${_d(q)} ${u.word}';
  return half ? '$w ${u.word} و نیو' : '$w ${u.word}';
}

/// خواردن
class FDish {
  const FDish({
    required this.id,
    required this.name,
    required this.ing,
    required this.units,
    required this.q0,
    required this.k,
    required this.p,
    required this.c,
    required this.f,
    required this.sug,
    required this.fib,
    required this.salt,
    required this.chol,
    this.alias = const [],
    this.liquid = false,
    this.img,
    this.net,
  });

  final String id;
  final String name;

  /// پێکهاتەکان
  final String ing;

  /// یەکەکان: id ← چەند گرام (یان مل). یەکەمیان بنەڕەتە.
  final Map<String, double> units;
  final double q0;

  /// بۆ 100 گرام: کالۆری، پرۆتین، کاربۆهیدرات، چەوری، شەکر، فایبەر، خوێ (g)، کۆلیسترۆڵ (mg)
  final double k, p, c, f, sug, fib, salt, chol;
  final List<String> alias;
  final bool liquid;

  /// وێنەی PNG (asset) — ئەگەر null بێت وێنەی ناو ئەپ نییە (لە سێرڤەرەوە دێت)
  final String? img;

  /// وێنەی PNG لە سێرڤەرەوە (بۆ خواردنی نوێ)
  final String? net;

  String get u0 => units.keys.first;
  double grams(String unit, double q) => (units[unit] ?? 1) * q;

  FNut nut(String unit, double q) {
    final m = grams(unit, q) / 100;
    return FNut(k * m, p * m, c * m, f * m, sug * m, fib * m, salt * m, chol * m, grams(unit, q));
  }

  FDish copyWith({String? id, String? name, Map<String, double>? units, double? q0}) => FDish(
        id: id ?? this.id,
        name: name ?? this.name,
        ing: ing,
        units: units ?? this.units,
        q0: q0 ?? this.q0,
        k: k,
        p: p,
        c: c,
        f: f,
        sug: sug,
        fib: fib,
        salt: salt,
        chol: chol,
        alias: alias,
        liquid: liquid,
        img: img,
        net: net,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'ing': ing,
        'units': units,
        'q0': q0,
        'n': [k, p, c, f, sug, fib, salt, chol],
        'liquid': liquid,
        if (img != null) 'img': img,
        if (net != null) 'net': net,
      };

  static FDish? fromJson(Object? o) {
    if (o is! Map) return null;
    final n = o['n'];
    final u = o['units'];
    if (n is! List || n.length < 8 || u is! Map || u.isEmpty) return null;
    double d(Object? v) => v is num ? v.toDouble() : double.tryParse('$v') ?? 0;
    return FDish(
      id: '${o['id']}',
      name: '${o['name']}',
      ing: '${o['ing'] ?? ''}',
      units: {for (final e in u.entries) '${e.key}': d(e.value)},
      q0: d(o['q0']) > 0 ? d(o['q0']) : 1,
      k: d(n[0]),
      p: d(n[1]),
      c: d(n[2]),
      f: d(n[3]),
      sug: d(n[4]),
      fib: d(n[5]),
      salt: d(n[6]),
      chol: d(n[7]),
      liquid: o['liquid'] == true,
      img: o['img'] is String ? o['img'] as String : null,
      net: o['net'] is String ? o['net'] as String : null,
    );
  }
}

/// کۆی خۆراک
class FNut {
  const FNut(this.k, this.p, this.c, this.f, this.sug, this.fib, this.salt, this.chol, this.g);
  static const FNut zero = FNut(0, 0, 0, 0, 0, 0, 0, 0, 0);
  final double k, p, c, f, sug, fib, salt, chol, g;
  FNut operator +(FNut o) => FNut(k + o.k, p + o.p, c + o.c, f + o.f, sug + o.sug, fib + o.fib, salt + o.salt, chol + o.chol, g + o.g);
}

const String _a = 'assets/food_ai/';

/// 10 خواردنی نموونە (هەمان وێنە کۆنەکان)
const List<FDish> kDishes = [
  FDish(
    id: 'rice',
    name: 'برنج',
    ing: 'برنجی یاسمین، ڕۆن، خوێ، ئاو',
    units: {'qap': 250, 'mlak': 20, 'g': 1},
    q0: 1,
    k: 170, p: 3, c: 28, f: 5, sug: 0.1, fib: 0.4, salt: 0.5, chol: 0,
    alias: ['تمن', 'ڕز', 'برنجی سپی', 'rice'],
    img: '${_a}rice.webp',
  ),
  FDish(
    id: 'kebab',
    name: 'کەباب',
    ing: 'گۆشتی قیمەکراو، پیاز، خوێ، بیبەر',
    units: {'shish': 90, 'qap': 270, 'g': 1},
    q0: 2,
    k: 260, p: 18, c: 3, f: 20, sug: 1, fib: 0.5, salt: 1.4, chol: 75,
    alias: ['کباب', 'کەبابی گۆشت', 'kebab'],
    img: '${_a}kebab.webp',
  ),
  FDish(
    id: 'salad',
    name: 'زەڵاتە',
    ing: 'تەماتە، خەیار، پیاز، جەعدە، لیمۆ، زەیت',
    units: {'kasa': 200, 'mlak': 20, 'g': 1},
    q0: 1,
    k: 45, p: 1, c: 5, f: 2.5, sug: 3, fib: 1.3, salt: 0.4, chol: 0,
    alias: ['زلاطە', 'سەڵاتە', 'زەڵاتەی ڕۆژهەڵات', 'salad'],
    img: '${_a}salad.webp',
  ),
  FDish(
    id: 'dolma',
    name: 'دۆڵمە',
    ing: 'گەڵای مێو، برنج، گۆشت، پیاز، تەماتە، ڕۆن',
    units: {'qap': 250, 'dana': 30, 'g': 1},
    q0: 1,
    k: 165, p: 5, c: 21, f: 7, sug: 2.5, fib: 2.5, salt: 0.65, chol: 10,
    alias: ['دۆلمە', 'یاپراخ', 'پەلکە مێو', 'dolma'],
    img: '${_a}dolma.webp',
  ),
  FDish(
    id: 'doogh',
    name: 'دۆ',
    ing: 'ماست، ئاو، خوێ، پونگ',
    units: {'kup': 250, 'ml': 1},
    q0: 1,
    k: 38, p: 2, c: 3, f: 2, sug: 3, fib: 0, salt: 0.4, chol: 6,
    alias: ['دوو', 'دۆی ماست', 'عەیران', 'doogh', 'ayran'],
    liquid: true,
    img: '${_a}doogh.webp',
  ),
  FDish(
    id: 'kunafa',
    name: 'کونافە',
    ing: 'کادەیف، پەنیری نابولسی، کەرە، شەربەت، فستق',
    units: {'parcha': 100, 'g': 1},
    q0: 1,
    k: 400, p: 9, c: 48, f: 20, sug: 28, fib: 1, salt: 0.6, chol: 45,
    alias: ['کنافە', 'کونافەی پەنیر', 'kunafa', 'knafeh'],
    img: '${_a}kunafa.webp',
  ),
  FDish(
    id: 'tea',
    name: 'چا',
    ing: 'چای ڕەش، ئاو، شەکر',
    units: {'kup': 100, 'ml': 1},
    q0: 1,
    k: 30, p: 0, c: 7.5, f: 0, sug: 7.5, fib: 0, salt: 0, chol: 0,
    alias: ['چای', 'چایی', 'تی', 'tea'],
    liquid: true,
    img: '${_a}tea.webp',
  ),
  FDish(
    id: 'bread',
    name: 'نانی تەنوور',
    ing: 'ئاردی گەنم، ئاو، خوێ، هەویرترش',
    units: {'dana': 100, 'g': 1},
    q0: 1,
    k: 265, p: 9, c: 54, f: 1.5, sug: 2, fib: 2.7, salt: 1.2, chol: 0,
    alias: ['نان', 'نانی تەنور', 'نانی ساج', 'نانی هەورامی', 'bread'],
    img: '${_a}bread.webp',
  ),
  FDish(
    id: 'hummus',
    name: 'حومس',
    ing: 'نۆک، تەحینە، لیمۆ، سیر، زەیتی زەیتوون',
    units: {'qap': 150, 'mlak': 15, 'g': 1},
    q0: 1,
    k: 177, p: 8, c: 14, f: 10, sug: 0.3, fib: 6, salt: 0.9, chol: 0,
    alias: ['حمص', 'حوموس', 'hummus'],
    img: '${_a}hummus.webp',
  ),
  FDish(
    id: 'kubba',
    name: 'کوبە',
    ing: 'برنج، گۆشتی قیمەکراو، پیاز، بەهارات',
    units: {'dana': 120, 'g': 1},
    q0: 2,
    k: 250, p: 12, c: 28, f: 12, sug: 1, fib: 2, salt: 1.0, chol: 30,
    alias: ['کبە', 'کوبەی برنج', 'کوبەی حەلەب', 'kubba', 'kibbeh'],
    img: '${_a}kubba.webp',
  ),
];

/// خواردنی زیادە بۆ هەڵبژاردنی ڕاستکردنەوە (جێگرەوە)
const List<FDish> kAltDishes = [
  FDish(
    id: 'milk',
    name: 'شیر',
    ing: 'شیری مانگا',
    units: {'kup': 250, 'ml': 1},
    q0: 1,
    k: 61, p: 3.2, c: 5, f: 3.3, sug: 5, fib: 0, salt: 0.1, chol: 10,
    alias: ['شیری مانگا', 'milk'],
    liquid: true,
    img: '${_a}milk.webp',
  ),
  FDish(
    id: 'yogurt',
    name: 'ماست',
    ing: 'ماستی ماڵەوە',
    units: {'kasa': 200, 'mlak': 20, 'g': 1},
    q0: 1,
    k: 61, p: 3.5, c: 4.7, f: 3.3, sug: 4.7, fib: 0, salt: 0.1, chol: 13,
    alias: ['ماستاو', 'yogurt'],
    img: '${_a}yogurt.webp',
  ),
];

FDish? dishById(String id) {
  for (final d in kDishes) {
    if (d.id == id) return d;
  }
  for (final d in kAltDishes) {
    if (d.id == id) return d;
  }
  return null;
}

/// ئاسانکردنی دەق بۆ بەراوردکردن (ی/ي، ک/ك، ە/ه...)
String normKu(String s) {
  var t = s.toLowerCase().trim();
  const rep = {'ي': 'ی', 'ى': 'ی', 'ك': 'ک', 'ة': 'ە', 'ه‌': 'ە', 'ۀ': 'ە', '‌': '', 'ـ': '', 'أ': 'ا', 'إ': 'ا', 'آ': 'ا'};
  rep.forEach((a, b) => t = t.replaceAll(a, b));
  return t.replaceAll(RegExp(r'\s+'), ' ');
}

/// چەند لە یەکچوون (0-1) بۆ گەڕانی ناوی خواردن
double matchScore(FDish d, String q) {
  final x = normKu(q);
  if (x.isEmpty) return 0;
  var best = 0.0;
  for (final n in [d.name, ...d.alias]) {
    final y = normKu(n);
    if (y == x) return 1;
    if (y.startsWith(x) || x.startsWith(y)) best = math.max(best, 0.86);
    if (y.contains(x) || x.contains(y)) best = math.max(best, 0.72);
  }
  return best;
}

/// ژەمەکان
const Map<String, String> kMealName = {
  'b': 'نانی بەیانی',
  'l': 'نانی نیوەڕۆ',
  's': 'خواردنی سووک',
  'd': 'نانی ئێوارە',
  'n': 'خواردنی شەو',
};
const List<String> kMealOrder = ['b', 'l', 's', 'd', 'n'];

String mealAt(DateTime d) {
  final h = d.hour + d.minute / 60;
  if (h >= 5 && h < 10.5) return 'b';
  if (h >= 12 && h < 16) return 'l';
  if (h >= 18.5 && h < 22.5) return 'd';
  if (h >= 22.5 || h < 5) return 'n';
  return 's';
}
