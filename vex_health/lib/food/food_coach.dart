// VEX Health — ڕاهێنەری خواردن (food_coach.dart)
//
// بەشێکە لە food_design.dart (part)، هەمان داتا (vexfd_v1) و هەمان دیزاین:
//   • کارتی ڕاهێنەر: بازنەی کێش، ئامانج، ماوە و نزیکەی چەند هەفتە، ئاگاداری تەندروستی
//   • کێش / ڕاهێنان / ئامانج (شیتی تایبەت)
//   • ئامۆژگاری ئەمڕۆ (بە کرتە دەگۆڕێت)، کالۆری و پرۆتینی ئەمڕۆ، ژەمی داهاتوو + «خواردم»
//   • پلانی هەفتە: 7 ڕۆژ (ڕۆژی ڕاهێنان دیارە)، 4 ژەم، کردنەوە، گۆڕین، «دەیخۆم»، کۆی ڕۆژ
//   • زیاتر: بخۆ و نەخۆ، کاتی خواردن، ڕاپۆرتی هەفتە، ئامۆژگاری، پرسیار لە ڕاهێنەر
// پلانەکە لە لیستی 500 خواردنی ئەپ (FoodDb · assets/data/foods.json) دروست دەکرێت، بەپێی
// ئامانج، هەستیاری و نەخۆشییەکان، و هەر هەفتەیەک نوێ دەبێتەوە (vexcx_v1).
part of 'food_design.dart';

// ═════════════════════════════ بنەما ═════════════════════════════
const List<String> _kCxD = ['شەممە', 'یەکشەممە', 'دووشەممە', 'سێشەممە', 'چوارشەممە', 'پێنجشەممە', 'هەینی'];

/// [کلیل، ناو، کات، ئایکۆن]
const List<List<String>> _kCxSl = [
  ['b', 'بەیانی', '07:30', 'breakfast'],
  ['l', 'نیوەڕۆ', '13:00', 'lunch'],
  ['s', 'ژەمی سووک', '16:30', 'snack'],
  ['d', 'ئێوارە', '19:30', 'dinner'],
];

/// ڕۆژی هەفتە: 0 شەممە … 6 هەینی
int _cxIdx([DateTime? d]) => ((d ?? DateTime.now()).weekday % 7 + 1) % 7;

String _cxWeekKey() {
  final n = DateTime.now();
  return _key(DateTime(n.year, n.month, n.day).subtract(Duration(days: _cxIdx(n))));
}

int _cxH(String s) {
  var h = 0x811c9dc5;
  for (final c in s.codeUnits) {
    h ^= c;
    h = (h * 0x01000193) & 0xffffffff;
  }
  return h;
}

double _cxCl(double v, double a, double b) => v < a ? a : (v > b ? b : v);

/// بەشی هەر ژەمێک لە کالۆری ڕۆژ
Map<String, double> _cxShare(String goal) => goal == 'gain' || goal == 'muscle'
    ? const {'b': .24, 'l': .30, 's': .18, 'd': .28}
    : goal == 'lose'
        ? const {'b': .27, 'l': .33, 's': .10, 'd': .30}
        : const {'b': .25, 'l': .33, 's': .12, 'd': .30};

// ----- هەستیاری: وشەی ناو خواردن -----
const Map<String, List<String>> _kCxAl = {
  'gluten': [
    'نان', 'کولێرە', 'کەلانە', 'سەمون', 'تۆست', 'ساوەر', 'پاستا', 'ماکەرۆنی', 'سپاگێتی', 'لازانیا', 'کوسکوس', 'فریکە', 'شەعریە',
    'تەرخێنە', 'جۆ', 'گەنم', 'شۆفان', 'کوبە', 'عەجە', 'تەشریب', 'تۆرتیلا', 'کرواسان', 'تەبوولە', 'فەتووش', 'هەریسە', 'کەشکەک',
    'شنیتزڵ', 'کوتلێت', 'بۆرەک', 'سەمبووسە', 'فەتایەر', 'مەناقیش', 'عەجین', 'سمیت', 'کراکەر', 'برێوش', 'سەندویچ', 'ئارد', 'بەشەمەڵ',
  ],
  'lact': ['ماست', 'شیر', 'پەنیر', 'دۆ', 'دۆخەوا', 'جاجیک', 'قەیماخ', 'کرێم', 'لەبنە', 'کەشک', 'مەنسەف', 'ئەلفرێدۆ', 'بەشەمەڵ', 'یۆنانی', 'سیزەر'],
  'nuts': ['گوێز', 'بادەم', 'فستق', 'کاجۆ', 'فندق', 'چەرەس', 'موحەمەرە'],
  'egg': ['هێلکە', 'ئۆملێت', 'عەجە', 'کوکۆ', 'کوتلێت', 'شنیتزڵ', 'شامی', 'سیزەر', 'ئۆلیڤیە'],
  'fish': ['ماسی', 'تونە', 'سەلمۆن', 'سەلەمۆن', 'سەردین', 'مەسگوف', 'مەسگووف', 'تیلاپیا'],
  'shell': ['میگوو', 'میگۆ', 'کریڤێت'],
  'sesame': ['کونجی', 'تەحین', 'حومس', 'حەلاوە', 'موتەبەل', 'سمیت', 'ڕاشی', 'زەعتەر'],
  'soy': ['سۆیا', 'تۆفو'],
};

final RegExp _kCxSplit = RegExp(r'[\s()\[\]\-،,/+]+');
const Set<String> _kCxSuf = {'', 'ی', 'ە', 'ەی', 'یی', 'ێک', 'ەکان', 'ەکە'};

/// وشەکە بە تەواوی (یان بە پاشگری ی/ە) لە ناوەکەدا هەیە؟ («دۆ» ← «دۆڵمە» ناگرێتەوە)
bool _cxHasWord(List<String> toks, String w) {
  for (final t in toks) {
    if (t.startsWith(w) && _kCxSuf.contains(t.substring(w.length))) return true;
  }
  return false;
}

/// تاگەکانی هەستیاری بۆ خواردنێک
List<String> _cxTags(FoodEntry x) {
  final toks = [x.ku, ...x.al].expand((s) => s.split(_kCxSplit)).where((s) => s.isNotEmpty).toList();
  final out = <String>[];
  _kCxAl.forEach((k, ws) {
    if (ws.any((w) => _cxHasWord(toks, w))) out.add(k);
  });
  if (x.cat == 'bread' && !out.contains('gluten')) out.add('gluten');
  if (x.cat == 'dairy' && !out.contains('lact')) out.add('lact');
  if (x.cat == 'nuts' && !out.contains('nuts') && !RegExp(r'تۆوی|وشک|مێوژ|نۆک|کونجی|کەتان|چیا').hasMatch(x.ku)) out.add('nuts');
  return out;
}

// ═════════════════════════════ خواردنی پلان ═════════════════════════════
// خواردنە ڕێکخراوەکان (id ـی assets/data/foods.json)
const Set<String> _kCxSpread = {
  'qaymagh', 'hanguin', 'mraba', 'doshaw', 'rashi', 'dibs_rashi', 'kara', 'nutella', 'peanut_butter', 'zatar_ron',
  'qaymagh_hanguin', 'zaytun', 'kahi', 'kahi_qaymagh', 'zardena', 'penir_sheltani', 'hilka_spina',
};
const Set<String> _kCxBread = {'nani_tanur', 'nani_saj', 'samun', 'kulera', 'kalana', 'nani_toast', 'nani_qaweyi', 'nani_arabi', 'baget', 'tortilla'};
const Set<String> _kCxVeg = {
  'zalata', 'zalata_sawz', 'tabula', 'fattush', 'jajik', 'zalata_yunani', 'zalata_chawandar', 'sawza_tekal', 'brokoli',
  'fasolia_sawz_kolaw', 'bamya_taza', 'qarnabit',
};
const Set<String> _kCxFruitNo = {'limo', 'narginil', 'lichi', 'unab', 'twtrk_kewi'};
const Set<String> _kCxCheese = {'penir_spi', 'penir_kurdi', 'kashkawan', 'feta', 'mozarela', 'halum', 'chedar'};
const Set<String> _kCxSide = {'mast', 'mast_kam', 'do', 'jajik'};
const Set<String> _kCxBowl = {'otmil', 'otmil_shir', 'penir_kotij', 'mast_yunani'};

/// زۆرترین گرام بۆ یەک ژەم بەپێی جۆر
const Map<String, double> _kCxCap = {
  'main': 450, 'kofta': 400, 'dolma': 400, 'meat': 300, 'soup': 600, 'rice': 320, 'bread': 160, 'breakfast': 300,
  'dairy': 500, 'fruit': 320, 'nuts': 45, 'dates': 60, 'veg': 300, 'salad': 300,
};

class _CxM {
  _CxM(this.kc, this.p, this.c, this.f, this.fi, this.sg);
  final double kc, p, c, f, fi, sg;
}

class _CxF {
  _CxF(this.x, this.u, this.r, this.tags);
  final FoodEntry x;
  final FoodUnit u;
  final Set<String> r; // ڕۆڵەکان
  final List<String> tags;

  /// قەبارەی بەشەکان بۆ کالۆری زۆر (1 … 1.5)
  double big = 1;

  bool get gram => u.isGram;
  String get id => x.id;
  String get cat => x.cat;
  bool get fried => x.ku.contains('سوورکراو') || x.ku.contains('بروستد') || x.ku.contains('فڕاو');

  /// خواردنێکی تەواو کە برنج/نانی تێدایە (پێویستی بە کاربی زیادە نییە)
  bool get full => x.c >= 14 && (cat == 'main' || cat == 'kofta' || cat == 'dolma');

  /// یەکەی ژمارەیی (دانە، سیخ، پارچە…) ← ژمارەی تەواو
  bool get whole {
    final n = u.name;
    return u.g < 30 || (u.g <= 160 && (n.contains('دانە') || n.contains('سیخ') || n.contains('پارچە') || n.contains('قوتوو') || n.contains('مشت')));
  }

  double get capG => _kCxCheese.contains(id) ? 90 : (_kCxCap[cat] ?? 300);

  /// بڕی بنەڕەت (1 یەکە یان 100 گرام)
  double get base => gram ? 100 : 1;
  double _g(double q) => gram ? q : q * u.g;
  _CxM at(double q) {
    final g = _g(q) / 100;
    return _CxM(x.kcal * g, x.p * g, x.c * g, x.f * g, x.fib * g, x.sug * g);
  }

  double kcAt(double q) => x.kcal * _g(q) / 100;

  double get minQ => gram ? 30 : (whole ? 1 : .5);
  double get maxQ {
    if (gram) return (capG * big / 10).round() * 10.0;
    if (r.contains('v')) return u.g < 120 ? 1.5 : 1;
    final m = capG * big / u.g;
    if (whole) {
      final lim = (cat == 'bread' || id.startsWith('hilka')) ? 3 : (u.g < 20 ? 6 : 4);
      return math.max(1, math.min((lim * big).round(), m.floor())).toDouble();
    }
    return math.max(.5, (math.min(((cat == 'fruit' || cat == 'salad') ? 1.5 : 2.0) * big, m) * 2).floor() / 2);
  }

  double round(double q) {
    if (gram) return q < 50 ? (q / 5).round() * 5.0 : (q / 10).round() * 10.0;
    if (whole) return q.roundToDouble();
    return (q * 2).round() / 2;
  }

  /// بڕێک کە نزیکەی tk کالۆری بێت
  double scale(double tk) {
    final per = kcAt(1);
    if (per <= 0) return base;
    return _cxCl(round(tk / per), minQ, maxQ);
  }

  String qty(double q) => gram ? '${_f1(q)} g' : '${_f1(q)} ${u.name}';
}

/// خواردنە گونجاوەکان بۆ ئەم کەسە (ڕۆڵ + هەستیاری + نەخۆشی)
List<_CxF> _cxPool(_Prof P) {
  final out = <_CxF>[];
  final c = P.conds;
  for (final x in FoodDb.I.foods) {
    final cat = x.cat;
    if (cat == 'fast' || cat == 'sweets' || cat == 'drinks' || cat == 'extras') continue;
    final n = x.ku, i = x.id;
    if (n.contains('ترش') || n.contains('مەعجون') || n.contains('کرێمی') || n.contains('کاکاو')) continue;
    final tags = _cxTags(x);
    if (P.allg.any(tags.contains)) continue;
    // نەخۆشییەکان
    if (c.contains('diab') && (cat == 'dates' || x.sug > 15)) continue;
    if (c.contains('gout') && RegExp(r'جگەر|دڵ|گورچیلە|پاچە|سەردین|مێشک').hasMatch(n)) continue;
    if (c.contains('preg') && n.contains('جگەر')) continue;
    if ((c.contains('chol') || c.contains('heart')) && x.f > 20 && cat != 'nuts') continue;
    if (c.contains('bp') && RegExp(r'پاستورمە|سۆسج|مۆرتەدێلا|سوجوق|سوێر').hasMatch(n)) continue;
    if (x.sug >= 25 && cat != 'fruit' && cat != 'dates' && cat != 'nuts') continue;
    if (x.f > 30 && cat != 'nuts') continue;
    final r = <String>{};
    final pd = x.p; // پرۆتین بۆ 100g
    switch (cat) {
      case 'breakfast':
        if (!_kCxSpread.contains(i)) r.add('bm');
        if (i == 'hilka_kolaw' || i == 'hilka_spina') r.addAll(['bp', 'pp']);
        break;
      case 'dairy':
        if (_kCxCheese.contains(i)) {
          r.add('bm');
        } else if (x.sug <= 8 && x.f <= 10 && x.kcal < 200) {
          r.addAll(['sn', 'pp']);
          if (_kCxBowl.contains(i) || i == 'mast' || i == 'mast_kam') r.add('bm');
          if (pd >= 8) r.add('bp');
          if (_kCxSide.contains(i)) r.add('sd');
        }
        break;
      case 'meat':
        r.add('mp');
        if (x.f <= 12 && pd >= 20) r.add('lp');
        break;
      case 'main':
      case 'kofta':
      case 'dolma':
        r.add('md');
        break;
      case 'soup':
        r.add('ms');
        break;
      case 'rice':
        if (i == 'otmil' || i == 'otmil_shir') {
          r.add('bm');
        } else if (i == 'shofan' || i == 'cornflakes' || i == 'cornflakes_shir' || i == 'ard') {
          // نا
        } else if (pd >= 6) {
          r.add('md');
        } else {
          r.add('cb');
        }
        break;
      case 'bread':
        if (_kCxBread.contains(i) && x.f <= 15) r.addAll(['bc', 'cb']);
        break;
      case 'salad':
      case 'veg':
        if (_kCxVeg.contains(i)) r.add('v');
        if (i == 'jajik') r.add('sd');
        if (i == 'zalata_miwa') r.add('fr');
        break;
      case 'fruit':
        if (!_kCxFruitNo.contains(i)) r.add('fr');
        break;
      case 'dates':
        r.addAll(['fr', 'sn']);
        break;
      case 'nuts':
        if (x.kcal >= 450 && i != 'sunsun' && i != 'tov_katan' && i != 'chia') r.add('sn');
        break;
    }
    if (r.isEmpty) continue;
    out.add(_CxF(x, x.unit0, r, tags));
  }
  return out;
}

class _CxIt {
  _CxIt(this.o, this.q);
  final _CxF o;
  double q;
  _CxM get m => o.at(q);
}

class _CxSum {
  double kc = 0, p = 0, c = 0, f = 0, fi = 0, sg = 0;
  static _CxSum of(List<_CxIt> its) {
    final t = _CxSum();
    for (final z in its) {
      final m = z.m;
      t.kc += m.kc;
      t.p += m.p;
      t.c += m.c;
      t.f += m.f;
      t.fi += m.fi;
      t.sg += m.sg;
    }
    return t;
  }
}

class _CxCtx {
  _CxCtx(this.P, this.g, this.el, this.tr) {
    final big = _cxCl(g.kcal / 2400, 1, 1.5);
    for (final o in el) {
      o.big = big;
    }
  }
  final _Prof P;
  final _Plan g;
  final List<_CxF> el;
  final List<bool> tr;
  final Set<String> used = <String>{};
  final Map<String, int> cc = <String, int>{};
  final List<Set<String>> dayCat = List<Set<String>>.generate(7, (_) => <String>{});
}

bool _cxMainOK(String slot, _CxF o, bool tr) {
  final kc = o.kcAt(o.base);
  final r = o.r;
  switch (slot) {
    case 'b':
      return (r.contains('bm') || r.contains('bp')) && kc >= 40;
    case 'l':
      return (r.contains('mp') || r.contains('md')) && kc >= 60;
    case 'd':
      return (r.contains('mp') || r.contains('md') || r.contains('ms')) && kc >= 40;
    default:
      return (tr ? (r.contains('pp') || r.contains('sn') || r.contains('fr')) : (r.contains('sn') || r.contains('fr'))) && kc >= 35 && kc <= 480;
  }
}

/// دروستکردنی یەک ژەم (سەرەکی ← سەوزە/زەڵاتە ← برنج یان نان ← پرۆتینی زیادە ← لایەنی ماست/میوە)
List<_CxIt> _cxGen(_CxCtx ctx, int di, String slot, String seed, List<String> excl) {
  final P = ctx.P, g = ctx.g, goal = P.goal.isEmpty ? 'keep' : P.goal;
  final sh = _cxShare(goal)[slot]!;
  final tk = g.kcal * sh, tp = g.p * sh;
  final tr = ctx.tr[di];
  final kid = P.conds.contains('kid');
  final lose = goal == 'lose';
  final frac = slot == 's' ? .8 : .6;
  final cand = <(double, _CxF, double)>[];
  for (final o in ctx.el) {
    if (!_cxMainOK(slot, o, tr) || excl.contains(o.id)) continue;
    final q = o.scale(tk * frac);
    final m = o.at(q);
    if (m.kc > tk * 1.15) continue;
    var sc = 50 - ((m.kc - tk * frac).abs() / math.max(tk * frac, 1)) * 18;
    final pf = m.p / math.max(tp, 1);
    if (kid) {
      sc -= math.max(0, m.p - tp) * 1.5;
    } else {
      sc += (goal == 'muscle' || goal == 'gain' || goal == 'aging') ? math.min(14, pf * 10) : math.min(8, pf * 6);
      if (m.p > tp * 1.3) sc -= (m.p - tp * 1.3) * .6;
    }
    if (lose) {
      if (m.kc / math.max(m.p, 1) > 28) sc -= 7;
      if (m.fi >= 4) sc += 4;
    }
    if (goal == 'gain' && m.kc >= 300) sc += 4;
    if (o.fried) sc -= 12;
    if (o.x.f > 18) sc -= 6;
    if (P.conds.contains('diab')) sc -= m.sg * .6;
    if (ctx.used.contains(o.id)) sc -= 45;
    sc -= (ctx.cc['$slot${o.cat}'] ?? 0) * 6;
    if ((slot == 'l' || slot == 'd') && ctx.dayCat[di].contains(o.cat)) sc -= 10;
    if (slot == 'l' && o.r.contains('ms')) sc -= 20; // شۆربا بۆ ئێوارە باشترە
    sc += (_cxH('$seed|${o.id}') % 1000) / 100;
    cand.add((sc, o, q));
  }
  if (cand.isEmpty) return [];
  cand.sort((a, b) => b.$1.compareTo(a.$1));
  final main = cand.first.$2;
  final items = <_CxIt>[_CxIt(main, cand.first.$3)];
  double kc() => _CxSum.of(items).kc;
  double pp() => _CxSum.of(items).p;

  void pick(bool Function(_CxF) pred, double Function(_CxF) score, double target, {double? maxQ}) {
    _CxF? best;
    var bs = -1e9;
    for (final o in ctx.el) {
      if (items.any((z) => z.o.id == o.id) || !pred(o) || excl.contains(o.id)) continue;
      final s = score(o) + (_cxH('$seed#${o.id}') % 1000) / 200 - (o.fried ? 12 : 0);
      if (s > bs) {
        bs = s;
        best = o;
      }
    }
    if (best == null) return;
    var q = best.scale(target);
    if (maxQ != null) q = math.min(q, maxQ);
    items.add(_CxIt(best, q));
  }

  double dense(_CxF o) => o.x.p / math.max(o.x.kcal, 1);
  if (slot == 'b') {
    if (main.cat != 'rice' && !_kCxBowl.contains(main.id)) {
      pick((o) => o.r.contains('bc'), (o) => o.x.fib + o.x.p / 3, math.max(80, (tk - kc()) * .6));
    }
    if (!kid && tp - pp() > 10 && tk - kc() >= 70) {
      pick((o) => o.r.contains('bp') && o.cat != main.cat, (o) => dense(o) * 100, math.min(tk - kc(), math.max(60, (tp - pp()) * 7)));
    }
    if (tk - kc() >= 70) pick((o) => o.r.contains('fr') && o.cat == 'fruit', (o) => 0, tk - kc());
  } else if (slot == 'l' || slot == 'd') {
    pick((o) => o.r.contains('v'), (o) => -((ctx.cc['v${o.id}'] ?? 0) * 3.0), 80, maxQ: 1);
    if (!main.full) {
      final stew = main.cat == 'main';
      pick(
        (o) => o.r.contains('cb') && (!stew || o.cat == 'rice') && !(lose && slot == 'd' && o.kcAt(o.base) > 300),
        (o) => o.x.fib + (o.cat == (stew ? 'rice' : 'bread') ? 3 : 0),
        math.max(100, (tk - kc()) * .8),
      );
    }
    if (!kid && tp - pp() > 25 && tk - kc() >= 120) {
      pick((o) => o.r.contains('lp') && dense(o) >= .1, (o) => dense(o) * 100, math.min(tk - kc(), math.max(100, (tp - pp()) * 6)));
    }
    if (tk - kc() >= 90 && items.length < 4) pick((o) => o.r.contains('sd'), (o) => 0, tk - kc());
  } else if (tk - kc() >= 70) {
    if (main.r.contains('fr')) {
      pick((o) => (o.r.contains('sn') || o.r.contains('pp')) && o.cat != 'dates' && o.cat != main.cat, (o) => o.x.p / 5, tk - kc());
    } else {
      pick((o) => o.r.contains('fr') && o.cat == 'fruit', (o) => 0, tk - kc());
    }
  }
  // ئەگەر هێشتا کەم بوو ← میوە، گوێز یان برنج/نان
  for (var k = 0; k < 2 && kc() < tk * .85 && items.length < 4; k++) {
    final need = tk - kc();
    if (slot == 'b') {
      pick((o) => (o.r.contains('fr') && o.cat == 'fruit') || (o.r.contains('sn') && o.cat == 'nuts'), (o) => 0, need);
    } else if (slot == 's') {
      pick((o) => o.r.contains('sn') || o.r.contains('fr'), (o) => 0, need);
    } else {
      final hasCb = items.any((z) => z.o.r.contains('cb'));
      pick((o) => (!main.full && !hasCb && o.r.contains('cb')) || (o.r.contains('fr') && o.cat == 'fruit'), (o) => o.r.contains('cb') ? 2 : 0, need);
    }
  }
  // ڕێکخستنی کۆتایی بۆ ئامانجی ژەم
  final sf = tk / math.max(kc(), 1);
  if (sf > 1.08 || sf < .92) {
    final f = _cxCl(sf, .6, 1.6);
    for (final z in items) {
      if (z.o.r.contains('v')) continue;
      final old = z.q;
      z.q = _cxCl(z.o.round(z.q * f), z.o.minQ, z.o.maxQ);
      if (f > 1 && kc() > tk * 1.12) z.q = old; // زیادەڕۆیی نەکات
    }
  }
  return items;
}

void _cxCommit(_CxCtx ctx, int di, String slot, List<_CxIt> items) {
  if (items.isEmpty) return;
  final m = items.first.o;
  ctx.used.add(m.id);
  ctx.cc['$slot${m.cat}'] = (ctx.cc['$slot${m.cat}'] ?? 0) + 1;
  for (final z in items) {
    if (z.o.r.contains('v')) ctx.cc['v${z.o.id}'] = (ctx.cc['v${z.o.id}'] ?? 0) + 1;
  }
  ctx.dayCat[di].add(m.cat);
}

/// ڕێکخستنی ڕۆژ: ئەگەر کۆی ڕۆژ لە 92٪ ی ئامانج کەمتر بوو ← بەشەکان گەورەتر + ژەمی سووک
void _cxFill(_CxCtx ctx, Map<String, List<_CxIt>> d, String seed) {
  final goal = ctx.P.goal.isEmpty ? 'keep' : ctx.P.goal;
  final T = ctx.g.kcal.toDouble();
  double tot() => _CxSum.of([for (final l in d.values) ...l]).kc;
  if (tot() < T * .92) {
    for (final sl in const ['l', 'd', 'b', 's']) {
      if (tot() >= T * .95) break;
      final tk = T * _cxShare(goal)[sl]!;
      final f = math.min(1.35, T / math.max(tot(), 1));
      final its = d[sl] ?? const <_CxIt>[];
      for (final z in its) {
        if (z.o.r.contains('v')) continue;
        final old = z.q;
        z.q = _cxCl(z.o.round(z.q * f), z.o.minQ, z.o.maxQ);
        if (_CxSum.of(its).kc > tk * 1.25 || tot() > T * 1.05) z.q = old;
      }
    }
  }
  for (var k = 0; k < (T > 2600 ? 3 : 2); k++) {
    _cxTopUp(ctx, d, '$seed$k');
  }
}

/// ژەمی سووکی زیادە ئەگەر کۆی ڕۆژ لە 92٪ ی ئامانج کەمتر بوو
void _cxTopUp(_CxCtx ctx, Map<String, List<_CxIt>> d, String seed) {
  var tot = 0.0;
  final have = <String>{};
  d.forEach((k, l) {
    for (final z in l) {
      tot += z.m.kc;
      have.add(z.o.id);
    }
  });
  final def = ctx.g.kcal - tot;
  if (def < ctx.g.kcal * .08) return;
  _CxF? best;
  var bs = -1e9;
  for (final o in ctx.el) {
    if (have.contains(o.id) || !(o.r.contains('sn') || o.r.contains('fr'))) continue;
    final m = o.at(o.base);
    final cap = math.min(def, o.kcAt(o.maxQ));
    final sc = (_cxH(seed + o.id) % 1000) / 100 + (ctx.P.goal == 'lose' ? -m.kc / 50 : cap / 40) + m.p / 10;
    if (sc > bs) {
      bs = sc;
      best = o;
    }
  }
  if (best != null) d.putIfAbsent('s', () => <_CxIt>[]).add(_CxIt(best, best.scale(math.min(def, 450))));
}

// ═════════════════════════════ کۆگای ڕاهێنەر ═════════════════════════════
class _CxStore {
  _CxStore._();
  static final _CxStore I = _CxStore._();
  static const String _k = 'vexcx_v1';

  Map<String, dynamic> st = <String, dynamic>{};
  bool loaded = false;
  List<_CxF>? _pool;
  String _poolSig = '';
  final Map<String, _CxF> _byId = {};

  Future<void> load() async {
    if (loaded) return;
    try {
      final sp = await SharedPreferences.getInstance();
      final raw = sp.getString(_k);
      if (raw != null && raw.isNotEmpty) {
        final j = jsonDecode(raw);
        if (j is Map) st = Map<String, dynamic>.from(j);
      }
    } catch (_) {}
    if (!FoodDb.I.loaded) {
      try {
        await FoodDb.I.load();
      } catch (_) {}
    }
    loaded = true;
  }

  Future<void> _save() async {
    try {
      final sp = await SharedPreferences.getInstance();
      await sp.setString(_k, jsonEncode(st));
    } catch (_) {}
  }

  /// ڕۆژەکانی ڕاهێنان (0 شەممە … 6 هەینی)
  List<int> tdays(_Prof P) {
    final t = st['tdays'];
    if (t is List) return t.map((e) => _i(e)).where((e) => e >= 0 && e <= 6).toList()..sort();
    const m = {
      0: <int>[],
      1: [1],
      2: [1, 4],
      3: [0, 2, 4],
      4: [0, 1, 3, 4],
      5: [0, 1, 2, 4, 5],
      6: [0, 1, 2, 3, 4, 5],
      7: [0, 1, 2, 3, 4, 5, 6],
    };
    return List<int>.of(m[P.days.clamp(0, 7)] ?? const <int>[]);
  }

  void setTdays(List<int> d) {
    st['tdays'] = (d.toSet().toList()..sort());
    _save();
  }

  bool isTr(_Prof P, int di) => tdays(P).contains(di);

  List<_CxF> pool(_Prof P) {
    final sig = jsonEncode([P.allg, P.conds, FoodDb.I.foods.length]);
    if (_pool == null || sig != _poolSig) {
      _pool = _cxPool(P);
      _poolSig = sig;
      _byId
        ..clear()
        ..addEntries(_pool!.map((o) => MapEntry(o.id, o)));
    }
    return _pool!;
  }

  _CxF? food(_Prof P, String id) {
    pool(P);
    final o = _byId[id];
    if (o != null) return o;
    final x = FoodDb.I.byId(id);
    return x == null ? null : _CxF(x, x.unit0, const <String>{}, _cxTags(x));
  }

  String _sig(_Prof P, _Plan g) => jsonEncode([P.goal, g.kcal, g.p, P.conds, P.allg, tdays(P), FoodDb.I.foods.length]);

  _CxCtx _ctx(_Prof P, _Plan g) => _CxCtx(P, g, pool(P), [for (var i = 0; i < 7; i++) isTr(P, i)]);

  /// پلانی ئەم هەفتەیە (ئەگەر نەبوو یان ئامانج گۆڕا ← دروست دەکرێت)
  List<Map<String, List<_CxIt>>> plan(_Prof P, _Plan g) {
    final wk = _cxWeekKey(), sig = _sig(P, g);
    final raw = st['plan'];
    if (st['wk'] == wk && st['sig'] == sig && raw is List && raw.length == 7) {
      final out = _decode(P, raw);
      if (out != null) return out;
    }
    final ctx = _ctx(P, g);
    final out = <Map<String, List<_CxIt>>>[];
    for (var di = 0; di < 7; di++) {
      final d = <String, List<_CxIt>>{};
      for (final sl in _kCxSl) {
        final it = _cxGen(ctx, di, sl[0], '$wk|$di${sl[0]}', const []);
        _cxCommit(ctx, di, sl[0], it);
        d[sl[0]] = it;
      }
      _cxFill(ctx, d, '$wk|u$di');
      out.add(d);
    }
    st['wk'] = wk;
    st['sig'] = sig;
    st['plan'] = _encode(out);
    st['hist'] = <String, dynamic>{};
    _save();
    return out;
  }

  List<Map<String, List<_CxIt>>>? _decode(_Prof P, List raw) {
    final out = <Map<String, List<_CxIt>>>[];
    for (final d in raw) {
      if (d is! Map) return null;
      final m = <String, List<_CxIt>>{};
      for (final sl in _kCxSl) {
        final l = d[sl[0]];
        final its = <_CxIt>[];
        if (l is List) {
          for (final z in l) {
            if (z is List && z.length >= 2) {
              final o = food(P, '${z[0]}');
              if (o != null) its.add(_CxIt(o, _d(z[1])));
            }
          }
        }
        m[sl[0]] = its;
      }
      out.add(m);
    }
    return out;
  }

  List<Map<String, List<List<Object>>>> _encode(List<Map<String, List<_CxIt>>> p) => [
        for (final d in p) {for (final e in d.entries) e.key: [for (final z in e.value) <Object>[z.o.id, z.q]]},
      ];

  /// گۆڕینی ژەمێک بە پێشنیارێکی تر
  bool swap(_Prof P, _Plan g, int di, String slot) {
    final p = plan(P, g);
    final ctx = _ctx(P, g);
    for (var i = 0; i < 7; i++) {
      for (final sl in _kCxSl) {
        if (i == di && sl[0] == slot) continue;
        final it = p[i][sl[0]] ?? const <_CxIt>[];
        if (it.isNotEmpty) _cxCommit(ctx, i, sl[0], [it.first]);
      }
    }
    final hist = (st['hist'] is Map) ? Map<String, dynamic>.from(st['hist'] as Map) : <String, dynamic>{};
    final key = '$di$slot';
    final h = (hist[key] is List) ? (hist[key] as List).map((e) => '$e').toList() : <String>[];
    final cu = p[di][slot] ?? const <_CxIt>[];
    if (cu.isNotEmpty) h.add(cu.first.o.id);
    var it = _cxGen(ctx, di, slot, '${st['wk']}|$key|${h.length}', h);
    if (it.isEmpty) {
      h.clear();
      it = _cxGen(ctx, di, slot, '${st['wk']}|$key|r', const []);
    }
    if (it.isEmpty) return false;
    p[di][slot] = it;
    hist[key] = h;
    st['hist'] = hist;
    st['plan'] = _encode(p);
    _save();
    return true;
  }
}

// ═════════════════════════════ ئامۆژگاری و پێشکەوتن ═════════════════════════════
class _CxProg {
  _CxProg(this.w0, this.wc, this.tw, this.has, this.prog, this.left, this.eta, this.done);
  final double w0, wc, tw, prog, left;
  final bool has, done;
  final int eta;
}

_CxProg _cxProg(_Prof P, _Plan pl) {
  final ws = _FD.I.weights;
  final w0 = ws.isNotEmpty ? ws.first.kg : P.w;
  final wc = ws.isNotEmpty ? ws.last.kg : P.w;
  final tw = P.tw, goal = P.goal;
  final has = tw > 0 && (goal == 'lose' || goal == 'gain' || (goal == 'muscle' && tw > w0));
  var prog = 0.0, left = 0.0, eta = 0;
  var done = false;
  if (has) {
    final up = tw > w0;
    final tot = (tw - w0).abs() == 0 ? 1.0 : (tw - w0).abs();
    done = up ? wc >= tw : wc <= tw;
    prog = _cxCl((up ? wc - w0 : w0 - wc) / tot, 0, 1);
    left = done ? 0 : (tw - wc).abs();
    final rate = goal == 'lose'
        ? math.max(.15, (pl.tdee - pl.kcal) / 1100)
        : goal == 'gain'
            ? math.max(.1, (pl.kcal - pl.tdee) / 1100)
            : .25;
    eta = (left / rate).ceil();
  }
  return _CxProg(w0, wc, tw, has, prog, left, eta, done);
}

/// ئاراستەی کێش لە 10+ ڕۆژی کۆتایی
String? _cxTrend(_Prof P, _Plan pl) {
  final ws = _FD.I.weights;
  if (ws.length < 2) return null;
  final last = ws.last;
  final lt = _fromKey(last.d);
  _Wt? ref;
  for (var i = ws.length - 2; i >= 0; i--) {
    if (lt.difference(_fromKey(ws[i].d)).inDays >= 10) {
      ref = ws[i];
      break;
    }
  }
  if (ref == null) return null;
  final weeks = lt.difference(_fromKey(ref.d)).inDays / 7;
  final rate = (last.kg - ref.kg) / weeks;
  switch (P.goal) {
    case 'lose':
      final ex = (pl.tdee - pl.kcal) / 1100;
      if (-rate < ex * .3) return 'کێشەکەت بە هێواشی دادەبەزێت. بڕی خواردن ورد بپێوە، خواردنەوەی شیرین ڕابگرە و هەنگاوەکانت زیاد بکە.';
      if (-rate > .9) return 'زۆر خێرا دادەبەزیت (زیاتر لە 0.9kg لە هەفتەیەکدا). کەمێک زیاتر بخۆ بۆ ئەوەی ماسولکەت لەدەست نەچێت.';
      return 'ڕێژەی کەمبوونەوەت باشە و لەسەر ڕێگای ڕاستیت.';
    case 'muscle':
    case 'gain':
      if (rate < .1) return 'کێشت زیاد نابێت. ڕۆژانە 200-300 kcal زیاد بکە (شیر، گوێز، برنج).';
      if (rate > .7) return 'کێشت زۆر خێرا زیاد دەبێت، لەوانەیە چەوری بێت نەک ماسولکە. کەمێک کالۆری کەم بکەرەوە.';
      return 'زیادبوونی کێشەکەت باشە.';
    default:
      return rate.abs() < .3 ? 'کێشت جێگیرە، ئەمە دروستە.' : 'کێشت دەگۆڕێت؛ ئەگەر ئامانجت پاراستنە، کالۆری ڕێک بخە.';
  }
}

/// ئامۆژگارییەکانی ئەمڕۆ: [ئایکۆن، دەق]
List<List<String>> _cxMsgs(_Prof P, _Plan g, _Tot t, double hr, bool tr) {
  final M = <List<String>>[];
  final goal = P.goal;
  final exp = _cxCl((hr - 6) / 16, 0, 1);
  final has = t.kcal > 0;
  if (!has && hr >= 10) M.add(['edit', 'هێشتا هیچ خواردنێکت تۆمار نەکردووە. ژەمی ئێستا لە پلانەکە ببینە و بە یەک کرتە تۆماری بکە.']);
  if (has && t.p < g.p * exp * .7 && hr >= 12) {
    M.add(['protein', 'پرۆتینت دواکەوتووە: ${t.p.round()} لە ${g.p}g. لە ژەمی داهاتوودا پرۆتین زیاد بکە (مریشک، هێلکە، ماست، نیسک).']);
  }
  if (t.kcal > g.kcal * 1.08) {
    M.add([
      'warn',
      goal == 'lose'
          ? '${fmt(t.kcal - g.kcal)} kcal لە بودجە تێپەڕیوی. ترسناک نییە؛ ژەمی داهاتوو سووک بێت (زەڵاتە و پرۆتین) و سبەینێ بگەڕێوە سەر پلان.'
          : 'کەمێک لە بودجە زیاترت خواردووە؛ ژەمی داهاتوو سووکتر بێت.',
    ]);
  }
  if ((goal == 'gain' || goal == 'muscle') && hr >= 18 && t.kcal < g.kcal * .65) {
    M.add(['kcal', 'کالۆریت کەمە (${fmt(t.kcal)} لە ${fmt(g.kcal)}). بۆ ${goal == 'gain' ? 'زیادبوونی کێش' : 'دروستبوونی ماسولکە'} پێویستە تەواو بخۆیت؛ ژەمێکی پڕ یان شیر و گوێزێک زیاد بکە.']);
  }
  if (goal == 'lose' && hr >= 18 && has && t.kcal < g.kcal * .5) {
    M.add(['warn', 'زۆر کەمت خواردووە. برسیکردنی خۆت کێش دانابەزێنێت و ماسولکە دەسووتێنێت؛ ژەمێکی تەواوی پڕ پرۆتین بخۆ.']);
  }
  if (t.sug > g.sug * .9) M.add(['sugar', 'شەکری ئەمڕۆت نزیکی سنوورە (${t.sug.round()}/${g.sug}g). تا سبەینێ شیرینی مەخۆ.']);
  if (hr >= 13 && _peek(_todayKey()).water * 250 < g.water * .4) M.add(['water', 'کەمتر لە 40٪ ی ئاوی ئەمڕۆت خواردووەتەوە؛ ئێستا پەرداخێک بخۆرەوە.']);
  if (tr) {
    M.add([
      'gym',
      goal == 'muscle' || goal == 'gain'
          ? 'ئەمڕۆ ڕۆژی ڕاهێنانە: 1-2 کاتژمێر پێشی کارب و کەمێک پرۆتین بخۆ (مۆز، نان، برنج)، و لە ماوەی 2 کاتژمێر دوای ڕاهێنان 25-40g پرۆتین.'
          : 'ئەمڕۆ ڕۆژی ڕاهێنانە: پێش ڕاهێنان سووک بخۆ (مۆز یان نان)، و دوای ڕاهێنان ژەمێکی پڕ پرۆتین.',
    ]);
  }
  final ws = _FD.I.weights;
  if (ws.isEmpty || DateTime.now().difference(_fromKey(ws.last.d)).inDays >= 7) {
    M.add(['weight', 'هەفتەیەک بەسەر دوایین کێشکردندا تێپەڕیوە. بەیانی پێش خواردن کێشی خۆت تۆمار بکە بۆ ئەوەی ڕاهێنەر پلانەکە ڕاست بکاتەوە.']);
  }
  if (M.isEmpty) M.add(['ok', 'ئەمڕۆ لەسەر ڕێگای ڕاستیت. بەردەوام بە و پلانەکە پەیڕەو بکە.']);
  return M.take(3).toList();
}

/// بۆچی ئەم ژەمە؟
String _cxWhy(_Prof P, List<_CxIt> its, String slot, bool tr) {
  if (its.isEmpty) return '';
  final t = _CxSum.of(its);
  final a = <String>[];
  if (slot == 's' && tr) a.add('دوای ڕاهێنان لە ماوەی 2 کاتژمێردا بیخۆ');
  if (P.goal == 'muscle' || P.goal == 'gain') {
    if (t.p >= 25) a.add('نزیکەی ${t.p.round()}g پرۆتین بۆ دروستکردنی ماسولکە');
  } else if (P.goal == 'lose') {
    a.add('تەنها ${fmt(t.kc)} kcal، بەڵام تێرکەرە${t.p >= 20 ? ' (${t.p.round()}g پرۆتین)' : ''}');
  } else if (t.p >= 20) {
    a.add('${t.p.round()}g پرۆتین بۆ تێربوون و پاراستنی ماسولکە');
  }
  if (t.fi >= 5) a.add('فایبەری باشی تێدایە');
  if (a.isEmpty) a.add('هاوسەنگ و گونجاوە بۆ ئامانجەکەت');
  return a.take(2).join(' · ');
}

// ═════════════════════════════ ڕاهێنەر (UI) ═════════════════════════════
class _CoachTab extends StatefulWidget {
  const _CoachTab({super.key, required this.ask, required this.go, required this.onWizard});
  final bool ask;
  final ValueChanged<String> go;
  final void Function(_Prof?, {int step}) onWizard;
  @override
  State<_CoachTab> createState() => _CoachTabState();
}

class _CoachTabState extends State<_CoachTab> {
  int sel = _cxIdx();
  String? open;
  int mi = 0;
  bool more = false;
  String panel = 'eat';

  @override
  void initState() {
    super.initState();
    if (widget.ask) {
      more = true;
      panel = 'ask';
    }
    _CxStore.I.load().then((_) {
      if (mounted) setState(() {});
    });
  }

  void _re() {
    if (mounted) setState(() {});
  }

  /// تۆمارکردنی ژەمێکی پلان بۆ ئەمڕۆ
  void _log(String slot, List<_CxIt> its) {
    final P = _FD.I.prof!;
    final k = _todayKey();
    var n = 0;
    for (final z in its) {
      final m = z.m;
      final vd = _judge(name: z.o.x.ku, kcal: m.kc, p: m.p, f: m.f, fib: m.fi, sug: m.sg, salt: 0, tags: z.o.tags, P: P);
      _FD.I.day(k).m.putIfAbsent(slot, () => <_Entry>[]).add(_Entry(
            n: z.o.x.label,
            kcal: m.kc,
            p: m.p,
            c: m.c,
            f: m.f,
            fib: m.fi,
            sug: m.sg,
            q: z.o.qty(z.q),
            at: nowHM(),
            fid: z.o.id,
            v: vd.v,
          ));
      n++;
    }
    if (n == 0) return;
    _FD.I.save();
    HapticFeedback.lightImpact();
    toast('✓ تۆمار کرا · ${fmt(_CxSum.of(its).kc)} kcal');
    _re();
  }

  @override
  Widget build(BuildContext context) {
    final fd = _FD.I;
    final P = fd.prof!;
    final g = fd.plan!;
    if (!_CxStore.I.loaded) return Center(child: CircularProgressIndicator(color: V.cy));
    if (more && panel == 'ask') {
      return _CoachAsk(onBack: () => setState(() => panel = 'eat'));
    }
    final st = _CxStore.I;
    final plan = st.plan(P, g);
    final ti = _cxIdx();
    final now = DateTime.now();
    final hr = now.hour + now.minute / 60;
    final t = fd.totals(_todayKey());
    final tr = st.isTr(P, ti);
    final msgs = _cxMsgs(P, g, t, hr, tr);
    final tn = _cxTrend(P, g);
    if (tn != null && msgs.length < 3) msgs.add(['chart', tn]);
    if (mi >= msgs.length) mi = 0;

    // ژەمی داهاتوو
    final order = ['b', 'l', 's', 'd'];
    final start = hr < 10.5 ? 0 : (hr < 15 ? 1 : (hr < 18 ? 2 : 3));
    final today = _peek(_todayKey());
    String? nx;
    for (var k = start; k < 4; k++) {
      if ((today.m[order[k]] ?? const <_Entry>[]).isEmpty) {
        nx = order[k];
        break;
      }
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 120),
      physics: const BouncingScrollPhysics(),
      children: [
        Rise(child: _hero(P, g)),
        const SizedBox(height: 12),
        Rise(delayMs: 60, child: _bubble(msgs)),
        const SizedBox(height: 10),
        Rise(delayMs: 90, child: _bars(t, g)),
        if (nx != null && (plan[ti][nx] ?? const []).isNotEmpty) ...[
          const SizedBox(height: 12),
          Rise(delayMs: 120, child: _next(nx, plan[ti][nx]!, tr)),
        ],
        const SizedBox(height: 18),
        Rise(delayMs: 140, child: _weekHead()),
        const SizedBox(height: 10),
        Rise(delayMs: 160, child: _days(P)),
        const SizedBox(height: 12),
        ..._meals(P, g, plan, ti),
        const SizedBox(height: 12),
        _more(P, g),
        const SizedBox(height: 14),
        _t('ڕێنمایی گشتییە و جێگەی ڕاوێژی پزیشک ناگرێتەوە.', size: 12, c: V.mu, align: TextAlign.center),
        const SizedBox(height: 12),
        _aiNote(),
      ],
    );
  }

  // ───────── کارتی ڕاهێنەر ─────────
  Widget _hero(_Prof P, _Plan g) {
    final pg = _cxProg(P, g);
    final gl = _goalOf(P.goal);
    final name = P.name.trim();
    final Widget status;
    if (pg.has) {
      status = pg.done
          ? _t('🎉 گەیشتیت بە ئامانج! ئێستا بیپارێزە.', size: 13.5, w: FontWeight.w800, c: V.mint, h: 1.6)
          : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Wrap(crossAxisAlignment: WrapCrossAlignment.center, spacing: 4, children: [
                _t('ئامانج', size: 13.5, c: V.mu),
                _n('${_f1(pg.tw)}kg', 15),
                _t('· ماوە', size: 13.5, c: V.mu),
                _n('${_f1(double.parse(pg.left.toStringAsFixed(1)))}kg', 15),
              ]),
              const SizedBox(height: 2),
              Wrap(crossAxisAlignment: WrapCrossAlignment.center, spacing: 4, children: [
                _t('نزیکەی', size: 13.5, c: V.mu),
                _n('${pg.eta}', 15),
                _t('هەفتە', size: 13.5, c: V.mu),
              ]),
            ]);
    } else {
      status = _t(
        P.goal == 'keep' || P.goal == 'aging' ? 'ئامانج: پاراستنی کێشی ئێستا' : 'کێشی ئامانج دانەنراوە · لە «ئامانج» دایبنێ',
        size: 13,
        c: V.mu,
        h: 1.6,
      );
    }
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [op(V.mint, VexTheme.I.isLight ? 0.10 : 0.12), op(V.cy, 0.05)],
        ),
        border: Border.all(color: op(V.cy, 0.35)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          _Ring(
            frac: pg.has ? pg.prog : 0,
            colors: const [Color(0xFF8FF3F9), Color(0xFF3CF08A)],
            size: 104,
            w: 9,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              _n(_f1(double.parse(pg.wc.toStringAsFixed(1))), 30),
              _n('kg', 13, c: V.mu, w: FontWeight.w700),
            ]),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _t(name.isEmpty ? 'ڕاهێنەرەکەت' : 'ڕاهێنەری $name', size: 19, w: FontWeight.w800, lines: 1),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: op(V.mint, 0.14), borderRadius: BorderRadius.circular(30), border: Border.all(color: op(V.mint, 0.4))),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  _Sv(gl[3], size: 22),
                  const SizedBox(width: 6),
                  Flexible(child: _t(gl[1], size: 13, w: FontWeight.w800, c: V.mint, lines: 1)),
                ]),
              ),
              const SizedBox(height: 8),
              status,
            ]),
          ),
        ]),
        for (final f in g.flags)
          Container(
            margin: const EdgeInsets.only(top: 12),
            padding: const EdgeInsets.all(12),
            decoration: _glass(r: 18, tint: V.amber, a: 0.1),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(Icons.warning_amber_rounded, color: V.amber, size: 20),
              const SizedBox(width: 8),
              Expanded(child: _t(f, size: 12.5, h: 1.65, w: FontWeight.w700, c: V.amber)),
            ]),
          ),
        if (P.note.trim().isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 10),
            padding: const EdgeInsets.all(12),
            decoration: _glass(r: 18),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(Icons.edit_note_rounded, color: V.mu, size: 20),
              const SizedBox(width: 8),
              Expanded(child: Text(P.note.trim(), style: ku(12.5, w: FontWeight.w600, c: V.mu, h: 1.6))),
            ]),
          ),
        const SizedBox(height: 14),
        Row(children: [
          _act(const _Ic('weight', size: 36), 'کێش', _weightSheet),
          const SizedBox(width: 8),
          _act(const _Sv('w_gym', size: 36), 'ڕاهێنان', _trainSheet),
          const SizedBox(width: 8),
          _act(_Sv(gl[3], size: 36), 'ئامانج', () => widget.onWizard(P, step: 2)),
        ]),
      ]),
    );
  }

  Widget _act(Widget ic, String l, VoidCallback f) => Expanded(
        child: Press(
          onTap: f,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(color: V.surf2, borderRadius: BorderRadius.circular(20), border: Border.all(color: V.line)),
            child: Column(children: [ic, const SizedBox(height: 6), _t(l, size: 13.5, w: FontWeight.w800)]),
          ),
        ),
      );

  // ───────── ئامۆژگاری ─────────
  Widget _msgIcon(String k) {
    switch (k) {
      case 'protein':
        return const _Ic('protein', size: 30);
      case 'kcal':
        return const _Ic('kcal', size: 30);
      case 'sugar':
        return const _Ic('sugar', size: 30);
      case 'water':
        return const _Ic('water', size: 30);
      case 'weight':
        return const _Ic('weight', size: 30);
      case 'gym':
        return const _Sv('w_gym', size: 30);
      case 'warn':
        return const Icon(Icons.warning_amber_rounded, color: Color(0xFF05303A), size: 24);
      case 'chart':
        return const Icon(Icons.show_chart_rounded, color: Color(0xFF05303A), size: 24);
      case 'ok':
        return const Icon(Icons.thumb_up_alt_rounded, color: Color(0xFF05303A), size: 22);
      default:
        return const Icon(Icons.edit_rounded, color: Color(0xFF05303A), size: 22);
    }
  }

  Widget _bubble(List<List<String>> msgs) {
    final m = msgs[mi];
    return Press(
      scale: 0.99,
      onTap: msgs.length < 2 ? null : () => setState(() => mi = (mi + 1) % msgs.length),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: V.surf, borderRadius: BorderRadius.circular(24), border: Border.all(color: V.line)),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(gradient: V.prime, borderRadius: BorderRadius.circular(16)),
            child: Center(child: _msgIcon(m[0])),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 260),
                transitionBuilder: (c, a) => FadeTransition(opacity: a, child: SlideTransition(position: Tween<Offset>(begin: const Offset(0, .15), end: Offset.zero).animate(a), child: c)),
                child: KeyedSubtree(key: ValueKey<int>(mi), child: _t(m[1], size: 14, h: 1.75, w: FontWeight.w700)),
              ),
              if (msgs.length > 1) ...[
                const SizedBox(height: 8),
                Row(children: [
                  for (var i = 0; i < msgs.length; i++)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      margin: const EdgeInsetsDirectional.only(end: 5),
                      width: i == mi ? 20 : 7,
                      height: 7,
                      decoration: BoxDecoration(color: i == mi ? V.mint : V.track, borderRadius: BorderRadius.circular(9)),
                    ),
                ]),
              ],
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _bars(_Tot t, _Plan g) {
    Widget one(String l, String v, double frac, LinearGradient gr) => Expanded(
          child: Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            decoration: BoxDecoration(color: V.surf, borderRadius: BorderRadius.circular(22), border: Border.all(color: V.line)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Row(children: [
                _t(l, size: 13, c: V.mu),
                const SizedBox(width: 6),
                Expanded(child: FittedBox(fit: BoxFit.scaleDown, alignment: AlignmentDirectional.centerEnd, child: _n(v, 15))),
              ]),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(9),
                child: Container(
                  height: 9,
                  color: V.track,
                  alignment: AlignmentDirectional.centerStart,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0, end: _cxCl(frac, 0, 1)),
                    duration: const Duration(milliseconds: 900),
                    curve: Curves.easeOutCubic,
                    builder: (c, x, _) => FractionallySizedBox(widthFactor: x, heightFactor: 1, child: DecoratedBox(decoration: BoxDecoration(gradient: gr, borderRadius: BorderRadius.circular(9)))),
                  ),
                ),
              ),
            ]),
          ),
        );
    return Row(children: [
      one('کالۆری', '${fmt(t.kcal)}/${fmt(g.kcal)}', g.kcal <= 0 ? 0 : t.kcal / g.kcal, _gK),
      const SizedBox(width: 10),
      one('پرۆتین', '${t.p.round()}/${g.p}g', g.p <= 0 ? 0 : t.p / g.p, _gP),
    ]);
  }

  // ───────── ژەمی داهاتوو ─────────
  Widget _next(String slot, List<_CxIt> its, bool tr) {
    final sl = _kCxSl.firstWhere((z) => z[0] == slot);
    final sm = _CxSum.of(its);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        color: op(V.mint, VexTheme.I.isLight ? 0.08 : 0.10),
        border: Border.all(color: op(V.mint, 0.4)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          _Ic(sl[3], size: 34),
          const SizedBox(width: 8),
          Expanded(child: _t('ژەمی داهاتوو · ${slot == 's' && tr ? 'دوای ڕاهێنان' : sl[1]}', size: 15.5, w: FontWeight.w800, lines: 1)),
          _n('~${sl[2]}', 14, c: V.mu, w: FontWeight.w700),
        ]),
        const SizedBox(height: 10),
        Text(its.map((z) => z.o.x.label).join(' · '), style: ku(14, w: FontWeight.w700, h: 1.6)),
        const SizedBox(height: 14),
        Press(
          onTap: () => _log(slot, its),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              gradient: V.prime,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: op(V.mint, 0.3), blurRadius: 18, offset: const Offset(0, 6))],
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.check_rounded, color: Color(0xFF05303A), size: 22),
              const SizedBox(width: 8),
              _t('خواردم', size: 16, w: FontWeight.w800, c: const Color(0xFF05303A)),
              const SizedBox(width: 10),
              _n('${fmt(sm.kc)} kcal', 16, c: const Color(0xFF05303A)),
            ]),
          ),
        ),
      ]),
    );
  }

  // ───────── پلانی هەفتە ─────────
  Widget _weekHead() => Row(children: [
        Expanded(child: _t('پلانی هەفتە', size: 20, w: FontWeight.w800)),
        Icon(Icons.calendar_month_rounded, color: V.cy, size: 24),
      ]);

  Widget _days(_Prof P) {
    final ti = _cxIdx();
    return LayoutBuilder(builder: (context, cs) {
      final w = (cs.maxWidth - 3 * 8) / 4;
      return Wrap(spacing: 8, runSpacing: 8, children: [
        for (var i = 0; i < 7; i++)
          SizedBox(
            width: w,
            child: Press(
              onTap: () => setState(() {
                sel = i;
                open = null;
              }),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 11),
                decoration: BoxDecoration(
                  gradient: i == sel ? V.prime : null,
                  color: i == sel ? null : V.surf,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: i == sel ? Colors.transparent : (i == ti ? op(V.cy, 0.7) : V.line), width: i == ti && i != sel ? 1.5 : 1),
                ),
                child: Column(children: [
                  Icon(Icons.fitness_center_rounded, size: 17, color: _CxStore.I.isTr(P, i) ? (i == sel ? const Color(0xFF7A5200) : V.amber) : (i == sel ? const Color(0x9905303A) : op(V.mu, 0.55))),
                  const SizedBox(height: 4),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: _t(_kCxD[i], size: 13.5, w: FontWeight.w800, c: i == sel ? const Color(0xFF05303A) : V.tx),
                  ),
                ]),
              ),
            ),
          ),
      ]);
    });
  }

  List<Widget> _meals(_Prof P, _Plan g, List<Map<String, List<_CxIt>>> plan, int ti) {
    final tr2 = _CxStore.I.isTr(P, sel);
    final isT = sel == ti;
    final today = _peek(_todayKey());
    var dk = 0.0, dp = 0.0;
    final out = <Widget>[];
    for (var k = 0; k < _kCxSl.length; k++) {
      final sl = _kCxSl[k];
      final its = plan[sel][sl[0]] ?? const <_CxIt>[];
      final sm = _CxSum.of(its);
      dk += sm.kc;
      dp += sm.p;
      final done = isT && (today.m[sl[0]] ?? const <_Entry>[]).isNotEmpty;
      final nm = sl[0] == 's' && tr2 ? 'دوای ڕاهێنان' : sl[1];
      final isOpen = open == sl[0];
      out.add(Rise(
        delayMs: 180 + k * 50,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: V.surf,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: done ? op(V.mint, 0.55) : (isOpen ? op(V.cy, 0.5) : V.line)),
          ),
          child: Column(children: [
            Press(
              scale: 0.99,
              onTap: () => setState(() => open = isOpen ? null : sl[0]),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                child: Row(children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(color: done ? op(V.mint, 0.16) : V.surf2, borderRadius: BorderRadius.circular(16)),
                    child: Center(child: done ? Icon(Icons.check_rounded, color: V.mint, size: 28) : _Ic(sl[3], size: 38)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      _t(nm, size: 16, w: FontWeight.w800),
                      const SizedBox(height: 2),
                      Text(
                        its.isEmpty ? '—' : its.map((z) => z.o.x.label).join(' · '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: ku(12.5, w: FontWeight.w600, c: V.mu),
                      ),
                    ]),
                  ),
                  const SizedBox(width: 8),
                  Column(children: [
                    _n(fmt(sm.kc), 18),
                    _n('kcal', 11, c: V.mu, w: FontWeight.w600),
                  ]),
                  const SizedBox(width: 6),
                  AnimatedRotation(
                    turns: isOpen ? (kIsLtr ? 0.25 : -0.25) : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(kIsLtr ? Icons.chevron_right_rounded : Icons.chevron_left_rounded, color: V.mu),
                  ),
                ]),
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              child: !isOpen
                  ? const SizedBox(width: double.infinity)
                  : Padding(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                        Divider(color: V.line, height: 1),
                        const SizedBox(height: 8),
                        for (final z in its) _itemRow(z),
                        if (its.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 6, bottom: 4),
                            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Icon(Icons.lightbulb_rounded, color: V.amber, size: 18),
                              const SizedBox(width: 6),
                              Expanded(child: _t(_cxWhy(P, its, sl[0], tr2), size: 12.5, c: V.mu, h: 1.6)),
                            ]),
                          ),
                        const SizedBox(height: 8),
                        Row(children: [
                          Expanded(
                            child: _miniBtn(Icons.swap_horiz_rounded, 'گۆڕین', ghost: true, onTap: () {
                              final ok = _CxStore.I.swap(P, g, sel, sl[0]);
                              if (!ok) toast('پێشنیاری تر نییە');
                              HapticFeedback.selectionClick();
                              setState(() => open = sl[0]);
                            }),
                          ),
                          if (isT) ...[
                            const SizedBox(width: 8),
                            Expanded(
                              child: _miniBtn(
                                Icons.check_rounded,
                                done ? 'تۆمار کرا' : 'دەیخۆم',
                                onTap: done || its.isEmpty ? null : () => _log(sl[0], its),
                              ),
                            ),
                          ],
                        ]),
                      ]),
                    ),
            ),
          ]),
        ),
      ));
    }
    out.add(Padding(
      padding: const EdgeInsets.fromLTRB(6, 4, 6, 0),
      child: Row(children: [
        _t('کۆی ڕۆژ', size: 14, c: V.mu),
        const SizedBox(width: 10),
        Expanded(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerEnd,
            child: _n('${fmt(dk)} / ${fmt(g.kcal)} kcal · P ${dp.round()}g', 14.5),
          ),
        ),
      ]),
    ));
    return out;
  }

  Widget _itemRow(_CxIt z) {
    final m = z.m;
    final img = FoodDb.I.imageOf(z.o.x);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: V.surf2, borderRadius: BorderRadius.circular(18), border: Border.all(color: V.line)),
      child: Row(children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            width: 44,
            height: 44,
            child: img != null
                ? Image.asset(img, fit: BoxFit.cover, errorBuilder: (c, e, s) => Center(child: Text(z.o.x.e, style: const TextStyle(fontSize: 24))))
                : Container(color: V.surf, child: Center(child: Text(z.o.x.e, style: const TextStyle(fontSize: 24)))),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(z.o.x.label, maxLines: 1, overflow: TextOverflow.ellipsis, style: ku(14, w: FontWeight.w800)),
            const SizedBox(height: 2),
            Wrap(spacing: 4, crossAxisAlignment: WrapCrossAlignment.center, children: [
              _t(z.o.qty(z.q), size: 12, c: V.mu),
              _n('· P ${_f1(double.parse(m.p.toStringAsFixed(1)))} · C ${_f1(double.parse(m.c.toStringAsFixed(1)))} · F ${_f1(double.parse(m.f.toStringAsFixed(1)))}', 11.5, c: V.mu, w: FontWeight.w600),
            ]),
          ]),
        ),
        const SizedBox(width: 8),
        Column(children: [
          _n(fmt(m.kc), 15),
          _n('kcal', 10.5, c: V.mu, w: FontWeight.w600),
        ]),
      ]),
    );
  }

  Widget _miniBtn(IconData ic, String l, {VoidCallback? onTap, bool ghost = false}) => Press(
        onTap: onTap,
        child: Opacity(
          opacity: onTap == null ? 0.55 : 1,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              gradient: ghost ? null : V.prime,
              color: ghost ? V.surf2 : null,
              borderRadius: BorderRadius.circular(16),
              border: ghost ? Border.all(color: V.line) : null,
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(ic, size: 19, color: ghost ? V.tx : const Color(0xFF05303A)),
              const SizedBox(width: 6),
              _t(l, size: 13.5, w: FontWeight.w800, c: ghost ? V.tx : const Color(0xFF05303A)),
            ]),
          ),
        ),
      );

  // ───────── زیاتر لە ڕاهێنەرەکە ─────────
  Widget _more(_Prof P, _Plan g) {
    const segs = [
      ['eat', 'بخۆ و نەخۆ'],
      ['time', 'کات'],
      ['rep', 'ڕاپۆرت'],
      ['tips', 'ئامۆژگاری'],
      ['ask', 'پرسیار'],
    ];
    return Container(
      decoration: BoxDecoration(color: V.surf, borderRadius: BorderRadius.circular(24), border: Border.all(color: V.line)),
      child: Column(children: [
        Press(
          scale: 0.99,
          onTap: () => setState(() => more = !more),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              Icon(Icons.auto_awesome_rounded, color: V.mint, size: 22),
              const SizedBox(width: 10),
              Expanded(child: _t('زیاتر لە ڕاهێنەرەکە', size: 16, w: FontWeight.w800)),
              AnimatedRotation(
                turns: more ? (kIsLtr ? 0.25 : -0.25) : 0,
                duration: const Duration(milliseconds: 200),
                child: Icon(kIsLtr ? Icons.chevron_right_rounded : Icons.chevron_left_rounded, color: V.mu),
              ),
            ]),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: !more
              ? const SizedBox(width: double.infinity)
              : Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 14),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(children: [
                        for (final s in segs)
                          Padding(
                            padding: const EdgeInsetsDirectional.only(end: 8),
                            child: _Chp(
                              on: panel == s[0],
                              onTap: () => setState(() => panel = s[0]),
                              child: _t(s[1], size: 13, w: FontWeight.w800, c: panel == s[0] ? V.mint : V.tx),
                            ),
                          ),
                      ]),
                    ),
                    const SizedBox(height: 12),
                    _panel(P, g),
                  ]),
                ),
        ),
      ]),
    );
  }

  Widget _panel(_Prof P, _Plan g) {
    switch (panel) {
      case 'time':
        final goal = P.goal;
        final tm = <List<Object>>[
          [const _Ic('breakfast', size: 30), 'بەیانی (7-9)', 'پرۆتین + دانەوێڵەی تەواو (هێلکە، ماست، نانی جۆ).'],
          [const _Ic('lunch', size: 30), 'نیوەڕۆ (12:30-14)', 'گەورەترین ژەم: پرۆتین + برنج/نان + سەوزە.'],
          [const _Sv('w_gym', size: 30), 'پێش ڕاهێنان (1-2 کاتژمێر)', 'کاربی سووک + کەمێک پرۆتین (مۆز، نان). چەوری زۆر مەخۆ.'],
          [const _Ic('protein', size: 30), 'دوای ڕاهێنان (2 کاتژمێر)', goal == 'lose' ? 'پرۆتین 25-30g + کەمێک کارب.' : 'پرۆتین 25-40g + کارب بۆ چاکبوونەوەی ماسولکە.'],
          [const _Ic('dinner', size: 30), 'ئێوارە (2-3 کاتژمێر پێش خەو)', 'ژەمێکی سووکتر؛ شیرینی و ژەمی قورس مەخۆ.'],
          [const _Sv('t_sleep', size: 30), 'کافایین', 'دوای کاتژمێر 2 ی پاشنیوەڕۆ قاوە و چا مەخۆوە.'],
          [const _Ic('water', size: 30), 'ئاو', 'ڕۆژانە ${(g.water / 1000).toStringAsFixed(1)}L؛ لە ڕۆژی ڕاهێناندا زیاتر.'],
        ];
        return Column(children: [
          for (final z in tm)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: _glass(r: 18),
              child: Row(children: [
                z[0] as Widget,
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    _t(z[1] as String, size: 14, w: FontWeight.w800),
                    const SizedBox(height: 2),
                    _t(z[2] as String, size: 12.5, c: V.mu, h: 1.6),
                  ]),
                ),
              ]),
            ),
        ]);
      case 'rep':
        var days = 0, ok = 0;
        var sk = 0.0, sp = 0.0;
        for (var i = 0; i < 7; i++) {
          final t = _FD.I.totals(_key(DateTime.now().subtract(Duration(days: i))));
          if (t.kcal > 0) {
            days++;
            sk += t.kcal;
            sp += t.p;
            if ((t.kcal - g.kcal).abs() <= g.kcal * .1) ok++;
          }
        }
        Widget box(String v, String l) => Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: _glass(r: 18),
                child: Column(children: [_n(v, 19), const SizedBox(height: 4), _t(l, size: 11.5, c: V.mu)]),
              ),
            );
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            box('$days/7', 'ڕۆژی تۆمارکراو'),
            const SizedBox(width: 8),
            box(days > 0 ? fmt(sk / days) : '-', 'ناوەندی kcal'),
            const SizedBox(width: 8),
            box(days > 0 ? '${(sp / days).round()}g' : '-', 'ناوەندی پرۆتین'),
          ]),
          const SizedBox(height: 12),
          _t(
            days < 4
                ? 'لانیکەم 4 ڕۆژ لە هەفتەیەکدا تۆمار بکە بۆ ئەوەی ڕاهێنەر ڕاست بڕیار بدات.'
                : ok >= 5
                    ? 'بەڕاستی باشە! زۆربەی ڕۆژەکان لەسەر بودجە بوویت.'
                    : 'هەوڵ بدە زۆربەی ڕۆژەکان لە ±10٪ ی ${fmt(g.kcal)} kcal بمێنیتەوە.',
            size: 13,
            c: V.mu,
            h: 1.7,
          ),
        ]);
      case 'tips':
        final rules = _coachRules(P);
        return Column(children: [
          for (final r in rules)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: _glass(r: 18),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _Sv(r[0], size: 32),
                const SizedBox(width: 10),
                Expanded(child: _t(r[1], size: 13, h: 1.7, w: FontWeight.w600)),
              ]),
            ),
        ]);
      default:
        return _eatPanel(P);
    }
  }

  Widget _eatPanel(_Prof P) {
    final el = _CxStore.I.pool(P);
    final goal = P.goal;
    double sc(_CxF o) {
      final m = o.at(o.base);
      switch (goal) {
        case 'muscle':
          return m.kc > 450 || m.p < 10 ? -1e9 : m.p * 1.4 - m.kc / 45;
        case 'lose':
          return m.kc > 320 ? -1e9 : m.p * 1.2 + m.fi * 2.2 - m.kc / 28;
        case 'gain':
          return m.kc < 200 || o.fried ? -1e9 : m.kc / 32 + m.p * .6;
        default:
          return m.kc > 420 ? -1e9 : m.p * .5 + m.fi * 2 + ((o.r.contains('v') || o.r.contains('fr')) ? 8 : 0) - math.max(0, m.kc - 300) / 30;
      }
    }

    final eat = <_CxF>[];
    final seen = <String>{};
    final rows = el.where((o) => !o.fried && !o.r.contains('cb')).map((o) => (o, sc(o))).where((z) => z.$2 > -1e8).toList()..sort((a, b) => b.$2.compareTo(a.$2));
    for (final z in rows) {
      if (eat.length >= 6) break;
      final k = z.$1.x.ku.split(' ').first;
      if (seen.contains(k)) continue;
      seen.add(k);
      eat.add(z.$1);
    }
    // کەمتر بخۆ: خواردنی خێرا، شیرینی، خواردنەوەی شیرین + ئەوەی بۆ هەستیاری یان نەخۆشی باش نییە
    final bad = <(FoodEntry, String)>[];
    void addCat(String cat, String why, int n) {
      final l = FoodDb.I.foods.where((x) => x.cat == cat).toList()..sort((a, b) => b.kcal.compareTo(a.kcal));
      for (final x in l.take(n)) {
        bad.add((x, why));
      }
    }

    if (P.allg.isNotEmpty) {
      for (final x in FoodDb.I.foods) {
        if (bad.length >= 2) break;
        if (P.allg.any(_cxTags(x).contains) && const {'main', 'breakfast', 'bread', 'dairy', 'meat'}.contains(x.cat)) {
          bad.add((x, 'هەستیاریت هەیە بۆ ئەم خواردنە'));
        }
      }
    }
    addCat('fast', 'خواردنی خێرا: چەوری و خوێی زۆر', 2);
    addCat('sweets', 'شەکری زۆر و وزەی بەتاڵ', 2);
    final soda = FoodDb.I.foods.where((x) => x.cat == 'drinks' && x.sug >= 8).toList()..sort((a, b) => b.sug.compareTo(a.sug));
    for (final x in soda.take(2)) {
      bad.add((x, 'کالۆری شلە؛ تێرت ناکات'));
    }

    Widget row(FoodEntry x, String sub, Color k, IconData ic) {
      final u = x.unit0;
      final kc = x.kcal * (u.isGram ? 1 : u.g / 100);
      return Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(10),
        decoration: _glass(r: 18),
        child: Row(children: [
          Text(x.e, style: const TextStyle(fontSize: 26)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(x.label, maxLines: 1, overflow: TextOverflow.ellipsis, style: ku(14, w: FontWeight.w800)),
              Row(children: [
                Icon(ic, size: 14, color: k),
                const SizedBox(width: 4),
                Expanded(child: _t(sub, size: 12, c: k, lines: 2)),
              ]),
            ]),
          ),
          const SizedBox(width: 6),
          Column(children: [_n(fmt(kc), 14), _n('kcal', 10, c: V.mu, w: FontWeight.w600)]),
        ]),
      );
    }

    String why(_CxF o) {
      final m = o.at(o.base);
      switch (goal) {
        case 'muscle':
          return '${_f1(double.parse(m.p.toStringAsFixed(1)))}g پرۆتین لە ${fmt(m.kc)} kcal';
        case 'lose':
          return 'کالۆری کەم و تێرکەر';
        case 'gain':
          return 'وزەی زۆر و سوودبەخش';
        default:
          return 'هاوسەنگ و سوودبەخش';
      }
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Row(children: [Icon(Icons.check_circle_rounded, color: V.mint, size: 20), const SizedBox(width: 6), _t('زیاتر بخۆ', size: 14.5, w: FontWeight.w800, c: V.mint)]),
      const SizedBox(height: 8),
      for (final o in eat) row(o.x, why(o), V.mint, Icons.thumb_up_alt_rounded),
      const SizedBox(height: 6),
      Row(children: [Icon(Icons.block_rounded, color: V.coral, size: 20), const SizedBox(width: 6), _t('کەمتر بخۆ', size: 14.5, w: FontWeight.w800, c: V.coral)]),
      const SizedBox(height: 8),
      for (final z in bad.take(8)) row(z.$1, z.$2, V.coral, Icons.warning_amber_rounded),
    ]);
  }

  Widget _aiNote() => CustomPaint(
        painter: _DashBorder(V.line2, 20),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(Icons.verified_user_outlined, color: V.mu, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: _t(
                'VEX AI پزیشک نییە و نەخۆشی دەستنیشان ناکات. ژمارەکانی خۆراک خەمڵاندنن. بۆ هەر کێشەیەکی جددی یان بەردەوام، سەردانی پزیشک بکە.',
                size: 12.5,
                c: V.mu,
                h: 1.7,
              ),
            ),
          ]),
        ),
      );

  // ───────── شیتەکان ─────────
  void _weightSheet() {
    final P = _FD.I.prof!;
    final ws = _FD.I.weights;
    var w = ws.isNotEmpty ? ws.last.kg : P.w;
    if (w < 30 || w > 250) w = 70;
    showVSheet<void>(
      builder: (c) => StatefulBuilder(builder: (c, set) {
        Widget step(String l, double d) => Press(
              onTap: () => set(() => w = _cxCl(double.parse((w + d).toStringAsFixed(1)), 30, 250)),
              child: Container(
                width: 58,
                height: 48,
                decoration: BoxDecoration(color: V.surf2, borderRadius: BorderRadius.circular(16), border: Border.all(color: V.line)),
                child: Center(child: _n(l, 16)),
              ),
            );
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          _sheetTitle('کێشی ئێستا', sub: 'بەیانی، پێش خواردن بیکێشە. هەفتەی یەک جار بەسە.', icon: 'weight'),
          const SizedBox(height: 6),
          Center(
            child: Row(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
              _n(w.toStringAsFixed(1), 54, c: V.cy),
              const SizedBox(width: 6),
              _n('kg', 18, c: V.mu),
            ]),
          ),
          const SizedBox(height: 14),
          Directionality(
            textDirection: TextDirection.ltr,
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              step('-1', -1),
              const SizedBox(width: 8),
              step('-0.1', -.1),
              const SizedBox(width: 18),
              step('+0.1', .1),
              const SizedBox(width: 8),
              step('+1', 1),
            ]),
          ),
          const SizedBox(height: 10),
          Directionality(
            textDirection: TextDirection.ltr,
            child: SliderTheme(
              data: SliderTheme.of(c).copyWith(activeTrackColor: V.cy, inactiveTrackColor: V.track, thumbColor: V.mint, overlayColor: op(V.cy, 0.15)),
              child: Slider(value: w, min: 30, max: 250, onChanged: (v) => set(() => w = double.parse(v.toStringAsFixed(1)))),
            ),
          ),
          const SizedBox(height: 10),
          _bigBtn('پاشەکەوتکردن', () {
            _FD.I.setWeight(w);
            Navigator.of(c).pop();
            toast('✓ کێش تۆمار کرا و پلانەکە نوێ کرایەوە');
            _re();
          }),
        ]);
      }),
    );
  }

  void _trainSheet() {
    final P = _FD.I.prof!;
    final td = _CxStore.I.tdays(P).toSet();
    showVSheet<void>(
      builder: (c) => StatefulBuilder(builder: (c, set) {
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          _sheetTitle('ڕۆژەکانی ڕاهێنان', sub: 'لە ڕۆژی ڕاهێناندا ڕاهێنەر ژەمی پێش و دوای ڕاهێنان ڕێک دەخات.'),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (var i = 0; i < 7; i++)
              _Chp(
                on: td.contains(i),
                color: V.amber,
                onTap: () => set(() => td.contains(i) ? td.remove(i) : td.add(i)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.fitness_center_rounded, size: 16, color: td.contains(i) ? V.amber : V.mu),
                  const SizedBox(width: 6),
                  _t(_kCxD[i], size: 13.5, w: FontWeight.w800),
                ]),
              ),
          ]),
          const SizedBox(height: 12),
          _t('${td.length} ڕۆژ لە هەفتەیەکدا', size: 13, c: V.mu, align: TextAlign.center),
          const SizedBox(height: 14),
          _bigBtn('پاشەکەوتکردن', () {
            _CxStore.I.setTdays(td.toList());
            Navigator.of(c).pop();
            toast('✓ ڕۆژەکانی ڕاهێنان نوێ کرانەوە');
            _re();
          }),
        ]);
      }),
    );
  }
}

/// چوارچێوەی خاڵدار
class _DashBorder extends CustomPainter {
  _DashBorder(this.c, this.r);
  final Color c;
  final double r;
  @override
  void paint(Canvas canvas, Size s) {
    final p = Paint()
      ..color = c
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3;
    final path = Path()..addRRect(RRect.fromRectAndRadius(Offset.zero & s, Radius.circular(r)));
    for (final m in path.computeMetrics()) {
      var d = 0.0;
      while (d < m.length) {
        canvas.drawPath(m.extractPath(d, math.min(d + 6, m.length)), p);
        d += 11;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashBorder o) => o.c != c || o.r != r;
}

// ═════════════════════════════ پرسیار لە ڕاهێنەر ═════════════════════════════
class _CoachAsk extends StatefulWidget {
  const _CoachAsk({required this.onBack});
  final VoidCallback onBack;
  @override
  State<_CoachAsk> createState() => _CoachAskState();
}

class _CoachAskState extends State<_CoachAsk> {
  final TextEditingController q = TextEditingController();
  final ScrollController sc = ScrollController();
  final List<List<String>> msgs = [
    ['bot', 'سڵاو! من ڕاهێنەری خواردنی تۆم. دەتوانیت لەسەر کالۆری، پرۆتین، ئاو، کێش یان ئەوەی ئێستا چی بخۆیت پرسیار بکەیت.'],
  ];

  @override
  void dispose() {
    q.dispose();
    sc.dispose();
    super.dispose();
  }

  String _answer(String s) {
    final fd = _FD.I;
    final P = fd.prof!;
    final plan = fd.plan!;
    final t = fd.totals(_todayKey());
    final left = plan.kcal - t.kcal;
    bool has(List<String> k) => k.any((x) => s.contains(x));
    if (has(['چی بخۆم', 'برسیمە', 'برسی', 'ژەم', 'پێشنیار'])) {
      final p = _CxStore.I.plan(P, plan)[_cxIdx()];
      final hr = DateTime.now().hour;
      final slot = hr < 11 ? 'b' : (hr < 15 ? 'l' : (hr < 18 ? 's' : 'd'));
      final its = p[slot] ?? const <_CxIt>[];
      if (its.isEmpty) return 'ئەمڕۆ ${fmt(left)} kcal ت ماوە. ژەمێکی سووکی پڕ پرۆتین بخۆ.';
      return 'ئەمڕۆ ${fmt(left)} kcal ت ماوە. بەپێی پلانەکەت ئێستا: ${its.map((z) => '${z.o.x.label} (${z.o.qty(z.q)})').join('، ')}.';
    }
    if (has(['پرۆتین'])) {
      return 'ئامانجی پرۆتینت ${plan.p}g ـە؛ ئەمڕۆ ${t.p.round()}g ت خواردووە. ${t.p < plan.p ? 'هێلکە، ماست، مریشک یان کەباب زیاد بکە.' : 'ئامانجەکەت تەواو بووە، ئافەرین!'}';
    }
    if (has(['ئاو', 'تینو'])) {
      final ml = _peek(_todayKey()).water * 250;
      return 'ئامانجی ئاوت ${fmt(plan.water)}ml ـە و ${fmt(ml)}ml ت خواردووەتەوە. هەر کاتژمێرێک پەرداخێک بخۆرەوە.';
    }
    if (has(['کالۆری', 'kcal'])) {
      return 'ئامانجی ڕۆژانەت ${fmt(plan.kcal)} kcal ـە (BMR: ${fmt(plan.bmr)}، TDEE: ${fmt(plan.tdee)}). ئەمڕۆ ${fmt(t.kcal)} ت خواردووە.';
    }
    if (has(['کێش', 'لاواز', 'قەڵەو', 'کەم بکەمەوە'])) {
      if (P.goal == 'lose') {
        return 'ئامانجت کەمکردنەوەی کێشە: ${fmt(plan.kcal)} kcal، نیوەی قاپەکەت سەوزە بێت، و ڕۆژانە ${fmt(plan.steps)} هەنگاو بڕۆ.${plan.weeks > 0 ? ' نزیکەی ${plan.weeks} هەفتە دەخایەنێت.' : ''}';
      }
      return 'ئامانجی ئێستات «${_goalOf(P.goal)[1]}» ـە. بۆ گۆڕینی، لە «ئامانج» دەستکاری بکە.';
    }
    if (has(['شەکر', 'شیرین'])) {
      return 'سنووری شەکرت ${plan.sug}g ـە لە ڕۆژێکدا؛ ئەمڕۆ ${t.sug.round()}g ت خواردووە. شەربەت و شیرینی کەم بکەرەوە.';
    }
    if (has(['خوێ', 'فشار', 'سوێر'])) {
      return 'سنووری خوێت ${plan.salt}g ـە لە ڕۆژێکدا. ترشی و پەنیری سوێر کەم بخۆ.';
    }
    if (has(['هەنگاو', 'پیاسە', 'ڕاهێنان', 'وەرزش'])) {
      final td = _CxStore.I.tdays(P);
      return 'ئامانجی هەنگاوت ${fmt(plan.steps)} ـە و ${td.length} ڕۆژ لە هەفتەدا ڕاهێنان دەکەیت. پیاسەی 15 خولەکی دوای نان زۆر باشە.';
    }
    return 'نەمتوانی تێبگەم. دەتوانیت بپرسیت: «چی بخۆم؟»، «پرۆتینم چەندە؟»، «ئاو چەند بخۆمەوە؟» یان «چۆن کێش کەم بکەمەوە؟».';
  }

  void _send(String text) {
    final s = text.trim();
    if (s.isEmpty) return;
    setState(() {
      msgs.add(['me', s]);
      msgs.add(['bot', _answer(s)]);
      q.clear();
    });
    Future<void>.delayed(const Duration(milliseconds: 120), () {
      if (sc.hasClients) sc.animateTo(sc.position.maxScrollExtent + 200, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
    });
  }

  @override
  Widget build(BuildContext context) {
    const sugg = ['چی بخۆم ئێستا؟', 'پرۆتینم چەندە؟', 'ئاو چەند بخۆمەوە؟', 'چۆن کێش کەم بکەمەوە؟', 'شەکرم چۆنە؟'];
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 4),
        child: Row(children: [
          Press(
            onTap: widget.onBack,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(color: V.surf, borderRadius: BorderRadius.circular(30), border: Border.all(color: V.line)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(kIsLtr ? Icons.chevron_left_rounded : Icons.chevron_right_rounded, color: V.tx, size: 20),
                _t('پلانەکە', size: 13, w: FontWeight.w800),
              ]),
            ),
          ),
          const Spacer(),
          _t('پرسیار لە ڕاهێنەر', size: 15, w: FontWeight.w800),
        ]),
      ),
      Expanded(
        child: ListView(
          controller: sc,
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
          physics: const BouncingScrollPhysics(),
          children: [
            for (final m in msgs)
              Align(
                alignment: m[0] == 'me' ? AlignmentDirectional.centerEnd : AlignmentDirectional.centerStart,
                child: Container(
                  constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                  decoration: BoxDecoration(
                    gradient: m[0] == 'me' ? V.prime : null,
                    color: m[0] == 'me' ? null : V.surf,
                    borderRadius: BorderRadius.circular(20),
                    border: m[0] == 'me' ? null : Border.all(color: V.line),
                  ),
                  child: m[0] == 'me'
                      ? Text(m[1], style: ku(14, w: FontWeight.w700, c: const Color(0xFF05303A), h: 1.6))
                      : _t(m[1], size: 13.5, h: 1.75, w: FontWeight.w600),
                ),
              ),
          ],
        ),
      ),
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Row(children: [
          for (final s in sugg)
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 8),
              child: _Chp(on: false, onTap: () => _send(s), child: _t(s, size: 12, w: FontWeight.w800)),
            ),
        ]),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
        child: Row(children: [
          Expanded(child: _Field(c: q, hint: 'پرسیارەکەت بنووسە...')),
          const SizedBox(width: 8),
          _PlusBtn(color: V.mint, onTap: () => _send(q.text), size: 50),
        ]),
      ),
    ]);
  }
}

// ═════════════════════════════ تاقیکردنەوە ═════════════════════════════
/// پلانی هەفتەیەک بۆ پرۆفایلێک (بێ پاشەکەوتکردن) ـ تەنها بۆ تاقیکردنەوە.
/// هەر ڕۆژێک: {target, kcal, p, slots: {b: [[id, cat, qty, kcal, q, minQ, maxQ, tags]]}}
@visibleForTesting
List<Map<String, Object>> debugCoachWeek(Map<String, dynamic> prof, {String wk = '2026-10-24'}) {
  final P = _Prof.fromJson(prof);
  final g = _planFor(P);
  final el = _cxPool(P);
  const m = {
    0: <int>[],
    1: [1],
    2: [1, 4],
    3: [0, 2, 4],
    4: [0, 1, 3, 4],
    5: [0, 1, 2, 4, 5],
    6: [0, 1, 2, 3, 4, 5],
    7: [0, 1, 2, 3, 4, 5, 6],
  };
  final td = m[P.days.clamp(0, 7)] ?? const <int>[];
  final ctx = _CxCtx(P, g, el, [for (var i = 0; i < 7; i++) td.contains(i)]);
  final out = <Map<String, Object>>[];
  for (var di = 0; di < 7; di++) {
    final d = <String, List<_CxIt>>{};
    for (final sl in _kCxSl) {
      final it = _cxGen(ctx, di, sl[0], '$wk|$di${sl[0]}', const []);
      _cxCommit(ctx, di, sl[0], it);
      d[sl[0]] = it;
    }
    _cxFill(ctx, d, '$wk|u$di');
    final all = [for (final l in d.values) ...l];
    final s = _CxSum.of(all);
    out.add({
      'target': g.kcal,
      'kcal': s.kc,
      'p': s.p,
      'pool': el.length,
      'slots': {
        for (final e in d.entries)
          e.key: [
            for (final z in e.value) [z.o.id, z.o.cat, z.o.qty(z.q), z.m.kc, z.q, z.o.minQ, z.o.maxQ, z.o.tags, z.o.x.ku],
          ],
      },
    });
  }
  return out;
}
