// VEX Health — شیکاری خواردن بە AI
//
// ئێستا ئەنجامێکی نموونە دەگەڕێنێتەوە (هەمان نموونەی وێبەکە).
// بۆ AI ی ڕاستەقینە: ناوەڕۆکی analyzeFood بگۆڕە بۆ داواکارییەک بۆ
// سێرڤەرەکەی خۆت (کلیلی API هەرگیز مەخەرە ناو ئەپەکەوە). سێرڤەرەکەت دەبێت
// هەمان شێوەی JSON ـی خوارەوە بگەڕێنێتەوە:
// {"is_food":true,"name":"...","emoji":"🍛","items":[{"name":"...","grams":100}],
//  "kcal":500,"protein_g":20,"carbs_g":50,"fat_g":15,"sugar_g":5,
//  "vitamins":["..."],"verdict":"good|ok|bad","reasons":["..."],"tip":"..."}
import 'dart:typed_data';

const Map<String, dynamic> kDemoFood = {
  'is_food': true,
  'name': 'برنج و شلەی فاسۆلیا لەگەڵ مریشک',
  'emoji': '🍛',
  'items': [
    {'name': 'برنج', 'grams': 220},
    {'name': 'شلەی فاسۆلیا', 'grams': 200},
    {'name': 'مریشکی برژاو', 'grams': 120},
  ],
  'kcal': 780,
  'protein_g': 44,
  'carbs_g': 98,
  'fat_g': 20,
  'sugar_g': 6,
  'vitamins': ['ئاسن', 'پۆتاسیۆم', 'ڤیتامین B12'],
  'verdict': 'ok',
  'reasons': ['💪 پڕۆتینی باشی تێدایە', '🍚 برنجەکەی زۆرە بۆ ئەم کاتە'],
  'tip': 'نیوەی برنجەکە بە زەڵاتە بگۆڕە.',
  'demo': true,
};

Future<Map<String, dynamic>> analyzeFood({Uint8List? image, String? text}) async {
  await Future<void>.delayed(const Duration(milliseconds: 2200));
  return Map<String, dynamic>.from(kDemoFood);
}

// ============================================================
// کورتەی ئەمڕۆ (بەشی تەندروستی)
// هەمان نموونەی وێبەکە. بۆ AI ـی ڕاستەقینە، analyzeHealth بگۆڕە بۆ
// داواکارییەک بۆ سێرڤەرەکەت کە هەمان خانەکان بگەڕێنێتەوە.
// ============================================================
class HealthBrief {
  const HealthBrief({
    required this.score,
    required this.verdict,
    required this.good,
    required this.watch,
    required this.tip,
    required this.actions,
  });

  final int score;
  final String verdict;
  final String good;
  final String watch;
  final String tip;
  final List<String> actions;
}

const HealthBrief kDemoBrief = HealthBrief(
  score: 74,
  verdict: 'ئامادەیی جەستەت باشە',
  good: 'لێدانی دڵت 68 و ئۆکسجینت 95٪ ە، هەردووکیان لە ناوچەی ئاساییدان. HRV ی 48 نیشانی دەدات جەستەت باش پشووی داوە.',
  watch: 'سترێست 60 ـە و جووڵەت تەنها 24٪ی ئامانجەکەتە. دانیشتنی درێژ سترێس زیاتر دەکات.',
  tip: 'ئێستا کاتێکی باشە بۆ پیاسەیەکی کورت؛ 15 خولەک پیاسە نزیکەی 1,800 هەنگاو زیاد دەکات و سترێسیش کەم دەکاتەوە.',
  actions: ['🚶 15 خولەک پیاسە', '🧘 3 خولەک هەناسەی قووڵ', '💧 2 پەرداخ ئاو'],
);

Future<HealthBrief> analyzeHealth() async {
  return kDemoBrief;
}
