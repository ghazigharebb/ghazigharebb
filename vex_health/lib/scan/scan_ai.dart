// VEX Health — سکانی خواردن: پەیوەندی بە AI ـەوە
//
// ┌───────────────────────────────────────────────────────────────────────┐
// │  بۆ بەستنەوە بە AI ـی ڕاستەقینە تەنها ئەم دوو دێڕەی AiConfig بگۆڕە:     │
// │    endpoint = ناونیشانی سێرڤەرەکەت (https://...)                        │
// │    appKey   = وشەی نهێنی نێوان ئەپ و سێرڤەر (ئارەزوومەندانە)            │
// │  نموونەی سێرڤەرێکی ئامادە: server_example/food_server.mjs               │
// │  کلیلی API ی Claude هەرگیز مەخەرە ناو ئەپەکەوە؛ تەنها لە سێرڤەرەکەدا.   │
// └───────────────────────────────────────────────────────────────────────┘
//
// ئەپەکە ئەم JSON ـە دەنێرێت بۆ سێرڤەرەکەت (POST):
//   {"task":"food_scan" | "food_recalc", "prompt":"...",
//    "image":{"media_type":"image/jpeg","data":"<base64>"}   ← تەنها کاتێک وێنە هەبێت
//    "text":"..."}                                             ← تەنها کاتێک نووسراو بێت
// سێرڤەرەکە وێنە و prompt ـەکە دەنێرێت بۆ Claude و ئەو JSON ـەی Claude دەیگەڕێنێتەوە
// ڕاستەوخۆ دەگەڕێنێتەوە بۆ ئەپ (شێوەکەی لە kSchema دا هەیە).
//
// تا endpoint بەتاڵ بێت (دۆخی نموونە):
//   • وێنە ← ئەنجامی نموونەی پیتزا (بۆ تاقیکردنەوەی هەموو بەشەکان)
//   • نووسین ← خواردنە باوەکان (هێلکە، نان، برنج، سێو...) بە بێ ئینتەرنێت حیساب دەکرێن
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../core/vx_en.dart';
import '../food/food_db.dart';
import 'scan_model.dart';

class AiConfig {
  AiConfig._();

  /// ناونیشانی سێرڤەرەکەت، بۆ نموونە: 'https://api.vexhealth.app/food'
  /// بەتاڵ = دۆخی نموونە
  static const String endpoint = '';

  /// وشەی نهێنی کە ئەپ لە سەرپەڕەی x-app-key دا دەینێرێت (ئارەزوومەندانە)
  static const String appKey = '';

  static const Duration timeout = Duration(seconds: 60);
}

/// زانیاری کەسەکە بۆ ئەوەی AI بزانێت ئەم ژەمە بۆ ئەو گونجاوە یان نا
class ScanCtx {
  const ScanCtx({
    required this.female,
    required this.age,
    required this.weight,
    required this.height,
    required this.goal,
    required this.eaten,
    required this.left,
    required this.time,
    required this.slotName,
  });
  final bool female;
  final int age;
  final double weight;
  final double height;
  final int goal;
  final int eaten;
  final int left;
  final String time;
  final String slotName;

  String get line => 'Person: ${female ? 'female' : 'male'}, $age years, ${weight.round()} kg, ${height.round()} cm, '
      'daily goal $goal kcal, already eaten $eaten kcal today, $left kcal left. Local time $time ($slotName).';
}

class ScanFail implements Exception {
  ScanFail(this.code);
  final String code;

  String get message {
    switch (code) {
      case 'timeout':
        return 'وەڵامەکە زۆری خایاند. دووبارە هەوڵ بدەرەوە.';
      case 'network':
        return 'ئینتەرنێت نییە یان سێرڤەر وەڵام ناداتەوە.';
      case 'rate_limited':
        return 'داواکاری زۆرە. کەمێکی تر هەوڵ بدەرەوە.';
      case 'invalid_json':
        return 'وەڵامەکە تەواو نەبوو. دووبارە هەوڵ بدەرەوە.';
      case 'offline_text':
        return 'ئەم خواردنە نەناسرایەوە. بە کورتی بینووسە، وەک: 2 هێلکە و نانێک';
      default:
        return 'شیکاری نەکرا. دووبارە هەوڵ بدەرەوە.';
    }
  }

  @override
  String toString() => 'ScanFail($code)';
}

const String _kSchemaKu =
    '{"is_food":true,"name":"meal name","emoji":"🍛","confidence":85,"items":[{"name":"…","inside":"up to 4 main ingredients, or empty","count":1,"unit":"قاپ","grams":250,"kcal":300,"protein_g":0,"carbs_g":0,"fat_g":0,"x":40,"y":55}],"fiber_g":0,"sugar_g":0,"sodium_mg":0,"digest_h_min":2,"digest_h_max":3,"meal_type":"meal","score":70,"verdict":"good","summary":"one short sentence"}';


const String _kSchemaEn =
    '{"is_food":true,"name":"meal name","emoji":"🍛","confidence":85,"items":[{"name":"…","inside":"up to 4 main ingredients, or empty","count":1,"unit":"plate","grams":250,"kcal":300,"protein_g":0,"carbs_g":0,"fat_g":0,"x":40,"y":55}],"fiber_g":0,"sugar_g":0,"sodium_mg":0,"digest_h_min":2,"digest_h_max":3,"meal_type":"meal","score":70,"verdict":"good","summary":"one short sentence"}';


const String _kRulesKu =
    'Write every human-readable string in Central Kurdish (Sorani, Arabic script). Food names short (1-3 words), the common Kurdish name (e.g. برنج، شلەی فاسۆلیا، کەباب، نان، دۆڵمە، زەڵاتە، مریشک، پیتزا).\n'
    'items = each separate food or drink the way a person counts it, NOT raw ingredients (a pizza is ONE item counted in slices, a plate of rice is ONE item, bread is ONE item counted in loaves). count + unit = how much of it, in a natural Kurdish unit (پارچە، قاپ، دانە، پەرداخ، کەوچک، قوتوو، سیخ، لەفە، کاسە). grams, kcal, protein_g, carbs_g, fat_g of an item are for its WHOLE count. inside = up to 4 main ingredients in Kurdish, so the person can spot what to correct.\n'
    'fiber_g, sugar_g, sodium_mg = totals for the whole meal. digest_h_min / digest_h_max = realistic hours for the stomach to digest this meal (water 0.2-0.4, juice or soda 0.5-1, fruit 0.5-1, a rice or bread meal 2-3, meat, fried or very fatty meals 3-5).\n'
    'score = 0-100, how good this meal is for this person right now (nutrition quality, amount versus the calories left, time of day). verdict: good (score>=70), ok (45-69), bad (<45).\n'
    'summary = one warm, encouraging sentence (max 18 words). Never judgmental, never scary.\n'
    'meal_type = "snack" for a light snack, fruit, sweet, drink or small bite that is not a full meal (usually under about 250 kcal), otherwise "meal".\n'
    'At most 6 items. Reply with ONLY this JSON (numbers as numbers):\n$_kSchemaKu';


const String _kRulesEn =
    'Write every human-readable string in clear, natural English. Food names short (1-3 words), the common English name (e.g. rice, bean stew, kebab, bread, dolma, salad, chicken, pizza).\n'
    'items = each separate food or drink the way a person counts it, NOT raw ingredients (a pizza is ONE item counted in slices, a plate of rice is ONE item, bread is ONE item counted in loaves). count + unit = how much of it, in a natural English unit (slice, plate, piece, glass, tablespoon, can, skewer, flatbread, bowl). grams, kcal, protein_g, carbs_g, fat_g of an item are for its WHOLE count. inside = up to 4 main ingredients in English, so the person can spot what to correct.\n'
    'fiber_g, sugar_g, sodium_mg = totals for the whole meal. digest_h_min / digest_h_max = realistic hours for the stomach to digest this meal (water 0.2-0.4, juice or soda 0.5-1, fruit 0.5-1, a rice or bread meal 2-3, meat, fried or very fatty meals 3-5).\n'
    'score = 0-100, how good this meal is for this person right now (nutrition quality, amount versus the calories left, time of day). verdict: good (score>=70), ok (45-69), bad (<45).\n'
    'summary = one warm, encouraging sentence (max 18 words). Never judgmental, never scary.\n'
    'meal_type = "snack" for a light snack, fruit, sweet, drink or small bite that is not a full meal (usually under about 250 kcal), otherwise "meal".\n'
    'At most 6 items. Reply with ONLY this JSON (numbers as numbers):\n$_kSchemaEn';

/// ئینگلیزی یان کوردی بەپێی زمانی ئەپ
String get kSchema => kIsEn
    ? _kSchemaEn
    : (kIsAr
        ? _kSchemaKu.replaceFirst('"unit":"قاپ"', '"unit":"صحن"')
        : (kIsFa
            ? _kSchemaKu.replaceFirst('"unit":"قاپ"', '"unit":"بشقاب"')
            : (kIsTr ? _kSchemaKu.replaceFirst('"unit":"قاپ"', '"unit":"tabak"') : _kSchemaKu)));

String get kRules => kIsEn
    ? _kRulesEn
    : kIsAr
        ? _kRulesKu
            .replaceFirst('Central Kurdish (Sorani, Arabic script)', 'clear Modern Standard Arabic (Arabic script)')
            .replaceFirst('the common Kurdish name (e.g. برنج، شلەی فاسۆلیا، کەباب، نان، دۆڵمە، زەڵاتە، مریشک، پیتزا)',
                'the common Arabic name (e.g. أرز، مرق الفاصولياء، كباب، خبز، دولمة، سلطة، دجاج، بيتزا)')
            .replaceFirst('natural Kurdish unit (پارچە، قاپ، دانە، پەرداخ، کەوچک، قوتوو، سیخ، لەفە، کاسە)',
                'natural Arabic unit (قطعة، صحن، حبة، كوب، ملعقة، علبة، سيخ، لفة، وعاء)')
            .replaceFirst('main ingredients in Kurdish', 'main ingredients in Arabic')
            .replaceFirst('"unit":"قاپ"', '"unit":"صحن"')
        : kIsFa
            ? _kRulesKu
                .replaceFirst('Central Kurdish (Sorani, Arabic script)', 'clear standard Persian (Farsi, Persian script)')
                .replaceFirst('the common Kurdish name (e.g. برنج، شلەی فاسۆلیا، کەباب، نان، دۆڵمە، زەڵاتە، مریشک، پیتزا)',
                    'the common Persian name (e.g. برنج، خورش لوبیا، کباب، نان، دلمه، سالاد، مرغ، پیتزا)')
                .replaceFirst('natural Kurdish unit (پارچە، قاپ، دانە، پەرداخ، کەوچک، قوتوو، سیخ، لەفە، کاسە)',
                    'natural Persian unit (تکه، بشقاب، عدد، لیوان، قاشق، قوطی، سیخ، رپ، کاسه)')
                .replaceFirst('main ingredients in Kurdish', 'main ingredients in Persian')
                .replaceFirst('"unit":"قاپ"', '"unit":"بشقاب"')
        : kIsTr
            ? _kRulesKu
                .replaceFirst('Central Kurdish (Sorani, Arabic script)', 'clear standard Turkish (Latin script)')
                .replaceFirst('the common Kurdish name (e.g. برنج، شلەی فاسۆلیا، کەباب، نان، دۆڵمە، زەڵاتە، مریشک، پیتزا)',
                    'the common Turkish name (e.g. pilav, fasulye yahnisi, kebap, ekmek, dolma, salata, tavuk, pizza)')
                .replaceFirst('natural Kurdish unit (پارچە، قاپ، دانە، پەرداخ، کەوچک، قوتوو، سیخ، لەفە، کاسە)',
                    'natural Turkish unit (dilim, tabak, adet, bardak, kaşık, kutu, şiş, dürüm, kase)')
                .replaceFirst('main ingredients in Kurdish', 'main ingredients in Turkish')
                .replaceFirst('"unit":"قاپ"', '"unit":"tabak"')
        : kIsBd
            ? _kRulesKu.replaceFirst('Central Kurdish (Sorani, Arabic script)',
                'Kurdish Badini (Kurmanji dialect written in Arabic script, NOT Sorani; use Badini words such as ئاڤ, خوارن, نان, برنج, هەنگاڤ, نڤستن)')
            : _kRulesKu;

String buildScanPrompt({String? text, required ScanCtx ctx}) {
  final t = text?.trim() ?? '';
  final hasText = t.isNotEmpty;
  return 'You are VEX AI, an expert dietitian inside a Kurdish health app. '
      '${hasText ? 'The person describes what they ate: "${t.length > 400 ? t.substring(0, 400) : t}".' : 'Look at the attached photo of a meal.'}\n'
      'Identify every food and drink${hasText ? '' : ' visible'} and estimate each amount the way a dietitian would'
      '${hasText ? '' : ' (use the plate, cutlery and hands as scale)'}. If a whole dish that is normally shared is shown '
      '(a whole pizza, a big tray), count ONE typical serving for one person and say so in the summary.\n'
      '${ctx.line}\n'
      '${hasText ? 'Set x and y of every item to 50.' : 'For each item give x and y: the centre of that item in the photo, as percent of image width and height (0-100, x from the LEFT edge, y from the TOP edge).'}\n'
      '$kRules\n'
      'If it is not food or drink, reply {"is_food":false,"name":"what it is"}.';
}

String buildRecalcPrompt(ScanResult r, String note, ScanCtx ctx) {
  final n = note.length > 300 ? note.substring(0, 300) : note;
  return 'You are VEX AI, an expert dietitian inside a Kurdish health app. You analysed a meal; the person checked it and wrote a correction.\n'
      'Your previous analysis (counts already set by the person): ${jsonEncode(r.toPrevJson())}\n'
      'The person\'s note, in ${kIsEn ? 'English' : (kIsBd ? 'Kurdish (Badini)' : (kIsAr ? 'Arabic' : (kIsFa ? 'Persian' : (kIsTr ? 'Turkish' : 'Kurdish'))))}: "$n"\n'
      'Apply the note precisely to the nutrition: an ingredient left out removes its calories and macros, less oil lowers fat and kcal, '
      'no sugar lowers sugar and carbs, a different size rescales. Keep every item\'s name, count and unit exactly as given unless the note clearly changes them; '
      'add an item only if the note mentions extra food or drink. Update inside, score, verdict and digestion to match. '
      'In the summary, briefly and warmly mention what changed.\n'
      '${ctx.line}\n'
      'Set x and y of every item to 50.\n'
      '$kRules';
}

/// جۆری وێنە لە یەکەم بایتەکانەوە
String mimeOf(Uint8List b) {
  if (b.length > 3 && b[0] == 0x89 && b[1] == 0x50 && b[2] == 0x4E && b[3] == 0x47) return 'image/png';
  if (b.length > 11 && b[8] == 0x57 && b[9] == 0x45 && b[10] == 0x42 && b[11] == 0x50) return 'image/webp';
  if (b.length > 3 && b[0] == 0x47 && b[1] == 0x49 && b[2] == 0x46) return 'image/gif';
  return 'image/jpeg';
}

class FoodAI {
  FoodAI._();

  static bool get connected => AiConfig.endpoint.trim().isNotEmpty;

  /// وێنە یان نووسین شیکاری دەکات
  static Future<ScanResult> analyze({Uint8List? image, String? text, required ScanCtx ctx}) async {
    if (!connected) return _offline(image: image, text: text);
    final body = <String, dynamic>{
      'task': 'food_scan',
      'prompt': buildScanPrompt(text: text, ctx: ctx),
      if (image != null) 'image': {'media_type': mimeOf(image), 'data': base64Encode(image)},
      if (text != null && text.trim().isNotEmpty) 'text': text.trim(),
    };
    final j = await _post(body);
    final r = ScanResult.fromJson(j);
    if (r == null) throw ScanFail('invalid_json');
    return r;
  }

  /// بە پێی تێبینی کەسەکە دووبارە حیساب دەکاتەوە (null = AI نەبەستراوەتەوە)
  static Future<ScanResult?> recalc(ScanResult r, String note, ScanCtx ctx) async {
    if (!connected) return null;
    final j = await _post(<String, dynamic>{'task': 'food_recalc', 'prompt': buildRecalcPrompt(r, note, ctx)});
    final x = ScanResult.fromJson(j);
    if (x == null || !x.isFood) throw ScanFail('invalid_json');
    return x;
  }

  static Future<dynamic> _post(Map<String, dynamic> body) async {
    try {
      final res = await http
          .post(
            Uri.parse(AiConfig.endpoint.trim()),
            headers: {
              'content-type': 'application/json',
              if (AiConfig.appKey.isNotEmpty) 'x-app-key': AiConfig.appKey,
            },
            body: jsonEncode(body),
          )
          .timeout(AiConfig.timeout);
      if (res.statusCode == 429) throw ScanFail('rate_limited');
      if (res.statusCode >= 400) throw ScanFail('server');
      final j = extractJson(utf8.decode(res.bodyBytes));
      if (j == null) throw ScanFail('invalid_json');
      return j;
    } on ScanFail {
      rethrow;
    } on TimeoutException {
      throw ScanFail('timeout');
    } catch (_) {
      throw ScanFail('network');
    }
  }

  /// JSON لە وەڵامەکەدا دەدۆزێتەوە (ئەگەر سێرڤەر دەقی تەواوی Claude بگەڕێنێتەوە)
  static dynamic extractJson(String s) {
    try {
      final o = jsonDecode(s);
      if (o is Map && o['result'] is Map) return o['result'];
      if (o is Map && o['text'] is String) return extractJson(o['text'] as String);
      if (o is Map) return o;
    } catch (_) {}
    final i = s.indexOf('{'), j = s.lastIndexOf('}');
    if (i >= 0 && j > i) {
      try {
        return jsonDecode(s.substring(i, j + 1));
      } catch (_) {}
    }
    return null;
  }

  // ---------- دۆخی نموونە (بێ AI) ----------
  static Future<ScanResult> _offline({Uint8List? image, String? text}) async {
    await Future<void>.delayed(const Duration(milliseconds: 2300));
    final t = text?.trim() ?? '';
    if (t.isNotEmpty) {
      final r = parseTextOffline(t);
      if (r != null) return r;
      throw ScanFail('offline_text');
    }
    return ScanResult.fromJson(demoPizza())!;
  }
}

const Map<String, double> _numWords = {
  'نیو': 0.5,
  'نیوە': 0.5,
  'یەک': 1,
  'دوو': 2,
  'سێ': 3,
  'چوار': 4,
  'پێنج': 5,
  'شەش': 6,
};

/// «2 هێلکە و نانێک و چا»، «قاپێک برنج و شلە»، «200 گرام مریشک» ← بە بێ ئینتەرنێت (لە لیستی 500 خواردنەکەوە)
ScanResult? parseTextOffline(String text) {
  var t = text.replaceAllMapped(RegExp('[٠-٩]'), (m) => '${m[0]!.codeUnitAt(0) - 0x0660}');
  t = t.replaceAllMapped(RegExp('[۰-۹]'), (m) => '${m[0]!.codeUnitAt(0) - 0x06F0}');
  final parts = t.split(RegExp(r'[،,؛;+\n]|\sو\s|\sلەگەڵ\s|\swith\s|\sand\s')).map((s) => s.trim()).where((s) => s.isNotEmpty);
  final items = <ScanItem>[];
  final db = FoodDb.I;
  double fib = 0, sug = 0;
  for (final p in parts) {
    final f = db.best(p);
    if (f == null) continue;
    final u = db.unitIn(f, p);
    double n = 1;
    final m = RegExp(r'(\d+(?:\.\d+)?)').firstMatch(p.replaceAll('٫', '.'));
    if (m != null) {
      n = double.tryParse(m[1]!) ?? 1;
    } else {
      for (final w in _numWords.entries) {
        if (RegExp('(^|\\s)${w.key}(\\s|\$|ی|ێک)').hasMatch(p)) {
          n = w.value;
          break;
        }
      }
    }
    if (u.isGram) {
      if (m == null) n = 100;
      n = n.clamp(1.0, 3000.0);
    } else {
      n = n.clamp(0.25, 50.0);
    }
    final it = scanItemOf(f, u, n);
    final ex = items.where((i) => i.name == it.name && i.unit == it.unit);
    if (ex.isNotEmpty) {
      final x = ex.first;
      final add = it.c0;
      final k = add / x.c0;
      x.grams += x.grams * k;
      x.kcal += x.kcal * k;
      x.p += x.p * k;
      x.c += x.c * k;
      x.f += x.f * k;
      x.c0 += add;
      x.n = x.c0;
    } else {
      if (items.length >= 6) break;
      items.add(it);
    }
    final g = f.gramsOf(u, n);
    fib += f.fib * g / 100;
    sug += f.sug * g / 100;
  }
  if (items.isEmpty) return null;
  final kc = items.fold<double>(0, (s, i) => s + i.kcal);
  final pr = items.fold<double>(0, (s, i) => s + i.p);
  final sc = (kc < 250 ? 74 : (kc < 700 ? 66 : 52)) + (pr * 4 > kc * 0.25 ? 6 : 0) - (sug > 30 ? 10 : 0);
  return ScanResult(
    isFood: true,
    name: items.length == 1 ? items.first.name : '${items.first.name} و ${items.length - 1} شتی تر',
    emoji: items.first.e.isNotEmpty ? items.first.e : '🍽️',
    confidence: 90,
    items: items,
    fib: fib,
    sug: sug,
    sod: 0,
    dmin: kc < 250 ? 0.8 : 2,
    dmax: kc < 250 ? 1.5 : 3,
    score: sc.clamp(5, 96),
    verdict: sc >= 70 ? 'good' : (sc >= 45 ? 'ok' : 'bad'),
    summary: 'بە پێی ئەوەی نووسیت و لیستی خواردنەکانی VEX حیساب کرا.',
    mealType: kc < 250 ? 'snack' : 'meal',
  );
}
