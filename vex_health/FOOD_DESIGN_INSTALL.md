# خواردن دیزاین — دامەزراندن

1. فایلی `lib/food/food_design.dart` بخە ناو `lib/food/` ی پڕۆژەکەت.
2. پۆڵی `assets/food_design/` (36 وێنەی WebP) بخە ناو `assets/`.
3. لە `pubspec.yaml` ـدا لە بەشی `assets:` ئەمە زیاد بکە:
       - assets/food_design/
4. هەر شوێنێک دەتەوێت بەشی خواردن بکرێتەوە:
       import 'food/food_design.dart';
       openFoodDesign();
   یان ڕاستەوخۆ: `const FoodDesignPage()`

پێویستی: flutter_svg، shared_preferences، google_fonts، و core/theme.dart (هەیە).
کامێرا/گەلەری: `FoodDesignHooks.onScan = (bool camera) { ... };`
داتا لە SharedPreferences (کلیل `vexfd_v1`) دەپارێزرێت.
