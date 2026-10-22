# English language pack — VEX Health

How to install
1. Copy this whole `vex_health` folder over your project (or merge the changed files listed below).
2. Run: flutter pub get && flutter run
3. In the first screen (language picker) choose English: onboarding AND the whole app become English (LTR, Sora font).
   Later: Profile > Language switches between English and Kurdish instantly.

New files: lib/core/vx_en.dart (engine, VText), lib/core/vx_en_data.dart (dictionary)
Main idea: every Text became VText, which translates at display time; Kurdish mode is unchanged.
Changed: core/theme.dart, main.dart, onboarding/{reg_lang,profile_page,reg_widgets,reg_gauge}.dart,
scan/{scan_ai,scan_model}.dart, alerts/band_alerts.dart, food/food_db.dart, home/water_card.dart, family/*, health/{hc,day_ribbon}.dart
and all files where Text( was replaced by VText(.

Not translated: native notification text outside Dart, pack.mp3 voice. Local scan-note parser understands Kurdish only (AI handles English).
Review the English health wording before release.
