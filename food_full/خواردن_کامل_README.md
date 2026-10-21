# خواردن کامل — بەشی خواردنی VEX Health بۆ Flutter

> **فایلی سەرەکی: ئەم فایلە (`خواردن_کامل_README.md`).** هەموو شتێک لێرە ڕوون کراوەتەوە.

## ١) ئەمە چییە؟ (بە ڕاستگۆییەوە)
بەشی خواردن **%١٠٠ هەمان پەڕەی وێبی خۆمانە** (٦ تاب: ئەمڕۆ، گەڕان، پلان/کۆچ، پرسیار، ئامار، من) لەگەڵ **هەموو ٧٠١ خواردن** و وێنەکانیان بە کوالیتی ٦٤٠px.
لە Flutter دا لەناو `flutter_inappwebview` دەکرێتەوە و لە سێرڤەری ناوخۆیی (`http://localhost:8765`) خزمەت دەکرێت — بۆیە دیزاین، ئەنیمەیشن و لۆجیک **بەتەواوی وەک وێب** دەمێنێتەوە.

⚠️ ئەمە **دووبارە نووسینەوەی Dart ی ڕەسەن نییە** (ئەوە ٦-١٠ هەزار هێڵ دەبوو و بێ کۆمپایلەر نەمدەتوانی بیپشکنم). هەروەها **من Flutter م کۆمپایل نەکردووە** (لێرە Flutter نییە)؛ فایلە Dart ەکان تەنها پشکنینی ڕستەسازییان (syntax) بۆ کراوە، و پەڕەی وێبەکە لە Chromium دا تاقی کراوەتەوە (٠ هەڵەی JS، ٧٠١ وێنە، ڕیکلام، گەڕان، زیادکردن، تیمی تاریک/ڕووناک). تاقیکردنەوەی ڕاستەقینە لەسەر مۆبایل کاری ئەندازیارە.

## ٢) هەر فایلێک چییە
| فایل | ئەرک |
|---|---|
| `lib/food_full/vex_food_page.dart` | **ویجێتی سەرەکی `VexFoodPage`** — ئەمە دەکەیتەوە (`Navigator.push`) |
| `lib/food_full/vex_food_bridge.dart` | سێرڤەری ناوخۆیی + پردی JS⇄Dart + `VexFoodController` |
| `lib/food_full/vex_health_glue.dart` | *(ئارەزوومەندانە)* بەستنەوە بە سکان و Store ی vex_health |
| `lib/food_full/main_demo.dart` | تاقیکردنەوەی سەربەخۆ بێ ئەپی VEX |
| `assets/food_full/web/index.html` | پەڕەی خواردنی تەواو (وێب) |
| `assets/food_full/web/data/vfdb.js` | داتابەیسی ٧٠١ خواردن |
| `assets/food_full/web/data/shim.js` | پرد: localStorage ← Flutter، سکان، ڕیکلام |
| `assets/food_full/web/data/ads.js` , `band.js` | ڕیکلامەکان و وێنەی Band |
| `assets/food_full/web/fonts/` | فۆنتی Noto Arabic (٤ کێش) و Sora |
| `assets/food_full/web/img/*.webp` | ٧٠١ وێنەی خواردن (٦٤٠px، نزیکەی ٣٧MB، بازنەیی و بێ باگراوندی سپی) |
| `tools/check_assets.py` | پشکنین: هەموو خواردنێک وێنەی هەیە؟ |
| `pubspec_زیادکردن.yaml` | ئەو دێڕانەی دەچنە pubspec |
| `ڕێنمایی_ئەندرۆید_و_ئایفۆن.md` | مۆڵەت و ڕێکخستنی Android/iOS |

## ٣) zip ـەکان (بەهۆی سنووری ٣٠MB پارچە پارچە کراوە)
هەموو پارچەکان **لە یەک فۆڵدەر unzip بکە** (Merge / Replace All):
- `خواردن_کامل_١.zip` — کۆد، دۆکیومێنت، داتا، فۆنت + بەشێک لە وێنەکان
- `خواردن_کامل_٢.zip` و `_٣.zip` — وێنەکانی تر (هەمان پێکهاتەی فۆڵدەر `assets/food_full/web/img/`)

دوای unzip کردنی هەموویان: `python3 tools/check_assets.py` — دەبێت بنووسێت **«وێنەی ونبوو: 0»** و **«هەموو شتێک ڕێکە ✅»**.

## ٤) دامەزراندن — هەنگاو بە هەنگاو
1. **فۆڵدەری `lib/food_full/`** کۆپی بکە بۆ `lib/` ی پرۆژەکە.
2. **فۆڵدەری `assets/food_full/`** کۆپی بکە بۆ `assets/` ی پرۆژەکە (ڕەگی پرۆژە).
3. `pubspec.yaml`: بەپێی `pubspec_زیادکردن.yaml` پاکێج و ٤ فۆڵدەری assets زیاد بکە. ⚠️ Flutter فۆڵدەری ناو فۆڵدەر ناخوێنێتەوە، بۆیە هەر ٤ دێڕەکە پێویستن. پاشان `flutter pub get`.
4. Android/iOS: `ڕێنمایی_ئەندرۆید_و_ئایفۆن.md` جێبەجێ بکە (minSdk 21، INTERNET، CAMERA، network_security_config بۆ localhost).
5. کردنەوە لە هەر شوێنێک:
```dart
import 'food_full/vex_food_page.dart';

Navigator.of(context).push(MaterialPageRoute(builder: (_) => const VexFoodPage()));
```
6. تاقیکردنەوەی خێرا بێ ئەپی VEX: `flutter run -t lib/food_full/main_demo.dart`

## ٥) بەستنەوە بە vex_health (ئارەزوومەندانە، بۆ سکان و پەڕەی سەرەکی)
بێ ئەمە پەڕەکە تەواو کار دەکات (گەڕان، زیادکردن، ئامار...) و خواردنەکان خۆیان خەزن دەکرێن. بەڵام بۆ ئەوەی سکانی کامێرا و کارتەکانی ماڵەوە هاوکات بن:
1. لە `lib/core/store.dart` لەناو `class Store` ئەم فەرمانە زیاد بکە:
```dart
void replaceFood(List<FoodItem> items) {
  food = List<FoodItem>.of(items);
  _saveFood();
  notifyListeners();
}
```
2. لەو پەڕەیەی `VexFoodPage` ی تێدا دەکەیتەوە:
```dart
final ctrl = VexFoodController();
late final glue = VexFoodGlue(ctrl);
@override void initState() { super.initState(); glue.start(); }
@override void dispose() { glue.stop(); super.dispose(); }
// ...
VexFoodPage(controller: ctrl, onScan: glue.onScan, onFoodChanged: glue.onFoodChanged)
```
سکان دەچێتە `openFoodScan / openFoodText / openFoodImage` ی `lib/scan/scan_page.dart`.

## ٦) تیم و ڕێکخستنەکان
- تاریک (بنەڕەت): `VexFoodPage(dark: true)`؛ ڕووناک: `dark: false` یان `controller.setTheme('light')`.
- `VexFoodController`: `addItem(map)`، `undoLast()`، `setTheme()`، `reload()`.
- هەژمار (`vexuser` لە SharedPreferences) خۆکار دەچێتە ناو پەڕەکە بۆ ئامانجی کالۆری.

## ٧) سنووردارییەکان (ڕاستگۆیانە)
- Flutter کۆمپایل نەکراوە؛ لەوانەیە ئاگادارکردنەوەی بچووکی Dart/پاکێج دەرکەوێت.
- localStorage ی WebView، مۆڵەتی کامێرا، و هەڵبژاردنی وێنە لەسەر ئامێری ڕاستەقینە دەبێت تاقی بکرێتەوە.
- فۆنتەکان ناوخۆیین (Google Fonts بەکارنایەت)، دەبێت ئینتەرنێت پێویست نەبێت.
- کارتی Band لەناو پەڕەکە داتای نموونەیە (وەک وێب)، نەک داتای زیندووی Band.
- لە ٣٦٠px ی وێب هەمان شێوە دەمێنێتەوە؛ ٥٩px زیادە لە ئینپوتی گەڕانی وێبی ئەسڵی چارەسەر کراوە لەم وەشانەدا.
- پارچە Dart ی خواردن.zip ی کۆن (xwardin) تەنها بەشێکی ناتەواوە — **ئەمە جێگەی دەگرێتەوە**، ئەوە بسڕەوە.
- پەڕەی خواردن ئامۆژگاری گشتییە، **ئامێری پزیشکی نییە**.
- ئەگەر دواتر ویستت، دەتوانرێت هەنگاو بە هەنگاو بە Dart ی ڕەسەن بنووسرێتەوە.
