// خواردن کامل — بەستنەوە بە ئەپی VEX Health (ئارەزوومەندانە)
//
// ئەم فایلە تەنها کاتێک بەکار دێت کە پەڕەی خواردن لەناو هەمان ئەپی vex_health دابنرێت.
// ئەگەر پەڕەی خواردن بە تەنیا (demo) دەکەیتەوە، پێویستت پێی نییە.
//
// ئەرکەکانی:
//  • سکان:  کامێرا/گەلەری/نووسینی پەڕەی خواردن ← پەڕەی سکانی ئەپەکە (lib/scan/scan_page.dart)
//  • ئەمڕۆ:  خواردنی زیادکراو لە پەڕەی سکان (Store.I) ← دەچێتە پەڕەی خواردنیش
//  • ماڵەوە: خواردنی تۆمارکراو لە پەڕەی خواردن ← Store.I.replaceFood (کارتەکانی ماڵەوە نوێ دەبنەوە)
//
// ⚠️ پێویستی بە یەک فەرمانی زیادە لە lib/core/store.dart هەیە (README هەنگاوی ٥ ببینە):
//     void replaceFood(List<FoodItem> items) { food = List<FoodItem>.of(items); _saveFood(); notifyListeners(); }
import 'package:image_picker/image_picker.dart';

import '../core/store.dart';
import '../scan/scan_page.dart';
import 'vex_food_bridge.dart';

class VexFoodGlue {
  VexFoodGlue(this.controller);

  final VexFoodController controller;
  int _lastCount = 0;
  bool _applying = false;
  bool _started = false;

  /// لە initState ی ئەو پەڕەیەی VexFoodPage ی تێدایە بانگ بکە
  void start() {
    if (_started) return;
    _started = true;
    _lastCount = Store.I.food.length;
    Store.I.addListener(_onStore);
  }

  /// لە dispose بانگ بکە
  void stop() {
    if (!_started) return;
    _started = false;
    Store.I.removeListener(_onStore);
  }

  /// بیدە بە VexFoodPage(onScan: glue.onScan)
  void onScan(VexScanRequest r) {
    final slot = r.slot.isEmpty ? null : r.slot;
    if (r.text.trim().isNotEmpty) {
      openFoodText(r.text, slot: slot);
      return;
    }
    final img = r.image;
    if (img != null && img.isNotEmpty) {
      openFoodImage(img, slot: slot);
      return;
    }
    openFoodScan(source: ImageSource.camera, slot: slot);
  }

  /// بیدە بە VexFoodPage(onFoodChanged: glue.onFoodChanged)
  void onFoodChanged(VexFoodSummary s) {
    _applying = true;
    try {
      final list = <FoodItem>[];
      for (final x in s.items) {
        list.add(FoodItem(
          n: x.n,
          kcal: x.kcal,
          p: x.p.round(),
          c: x.c.round(),
          f: x.f.round(),
          at: x.at,
          v: x.v,
          e: x.e,
          slot: x.slot,
        ));
      }
      Store.I.replaceFood(list);
      _lastCount = Store.I.food.length;
    } finally {
      _applying = false;
    }
  }

  // خواردنێکی نوێ لە Store ـەوە زیاد کرا (بۆ نموونە لە پەڕەی سکان) ← بیخە ناو پەڕەی خواردن
  void _onStore() {
    if (_applying) return;
    final n = Store.I.food.length;
    final added = n - _lastCount;
    _lastCount = n;
    if (added <= 0) return;
    // خواردنی نوێ لە سەرەوەی لیستەکەن (Store.addFood بە insert(0))
    final fresh = Store.I.food.take(added).toList().reversed;
    for (final it in fresh) {
      controller.addItem(<String, dynamic>{
        'n': it.n,
        'kcal': it.kcal,
        'p': it.p,
        'c': it.c,
        'f': it.f,
        'v': it.v,
        'at': it.at,
        'e': it.e,
        'slot': it.slot,
        'src': 'scan',
      });
    }
  }
}
