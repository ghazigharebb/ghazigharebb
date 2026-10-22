# VEX Band ↔ ئەپ (J-STYLE V8 SDK)

## فایلەکان
| فایل | کار |
|---|---|
| `lib/band/ble/vex_frame.dart` | دروستکردنی فرمانەکان (١٦ بایت + کۆ). ٢٤ فرمان بەراورد کراون لەگەڵ SDK ی ڕاستەقینە (`tools/sdk_check/`) و هاوتان |
| `lib/band/ble/vex_parsers.dart` | خوێندنەوەی وەڵامەکان: باتری، وەشان، MAC، هەنگاو، دڵ، SpO2، گەرما، HRV، خەو، PPG |
| `lib/band/ble/vex_ble.dart` | `VexBand.I`: سکان، پەیوەستبوون، ڕیزی نووسین، هاوکاتکردن، پێوانەی دەستی |
| `lib/vitalage/vital_age_engine.dart` | کۆکردنەوەی ٢١ ڕۆژ + ژماردنی تەمەنی ژیانی |
| `lib/vitalage/vital_age_page.dart` | پەڕەی دیزاین |
| `native/android/manifest_ble_permissions.xml`، `native/ios/Info_plist_additions.xml` | مۆڵەتی بلووتوس |

## دامەزراندن
1. `flutter pub get` (`flutter_blue_plus` زیادکراوە).
2. ناوەڕۆکی `native/android/manifest_ble_permissions.xml` بخەرە ناو `<manifest>` ی AndroidManifest.xml.
3. iOS: دوو دێڕی `NSBluetoothAlwaysUsageDescription` بخەرە ناو Info.plist.
4. `main.dart` پێشتر `VitalAgeEngine.I.init()` و `VexBand.I.init()` ی تێدایە.

## بەکارهێنان
```dart
final found = await VexBand.I.scan();          // یان quickConnect()
await VexBand.I.connect(found.first);
await VexBand.I.syncAll();                     // هەنگاو، دڵ، SpO2، گەرما، HRV، خەو
final r = await VexBand.I.measure(VexMeasure.heart);
await VexBand.I.find();                        // Band دەلەرێتەوە
```
دوگمەی «پەیوەستکردنەوە» ی ئەپ (`BandState.reconnect`) ئێستا سکان و پەیوەستبوونی ڕاستەقینە دەکات. لە debug دا ئەگەر Band نەدۆزرایەوە نموونەی دیزاین بەکاردێت.

## تەمەنی ژیانی (VitalAge)
- ڕۆژێک «تەواو»ە کاتێک خەو + هەنگاو + (دڵی ئارام یان HRV) هەبێت. ٢١ ڕۆژی تەواو پێویستە (نابێت بەدوای یەکدا بن).
- فۆرمولە لە `compute()` ڕوونە: خەو (٧–٨.٥ کاتژمێر باشترین)، دڵی ئارام (٦٠ بنەڕەت)، HRV (بەپێی تەمەن)، هەنگاو (١٠٠٠٠ باشترین)؛ کۆی کاریگەری لە −١٢ تا +١٥ ساڵ سنووردارە.
- تەمەنی ڕاستەقینە لە پرۆفایل (`age`) یان بەرواری لەدایکبوونی نووسراو (لە پەڕەکە) دێت.
- debug: درێژ دابگرە لەسەر ناونیشانی پەڕەکە بۆ بینینی ئەنجام بە داتای نموونە.
- **ئەمە خەمڵاندنێکی تەندروستیی گشتییە، نەک پزیشکی.** ژمارەکانی فۆرمولەکە (کۆنستانت) هێشتا لەسەر داتای ڕاستەقینە ڕێک نەخراون.

## ئەوەی پشکنراوە و ئەوەی نا
- ✅ فرمانەکان لەگەڵ SDK ی J-STYLE لەسەر JVM بەراورد کران: ٢٤/٢٤ ی وەک یەک. پارسەرەکان بە نموونەی دروستکراو (نەک Band) هاوتان.
- ❌ Flutter/Dart هەرگیز کۆمپایل نەکراوە (SDK ی Flutter لێرە نییە) — ڕەنگە هەڵەی بچووکی کۆمپایل دەرکەوێت.
- ❌ لەسەر Band ی ڕاستەقینە و مۆبایل تاقی نەکراوەتەوە: ناوی BLE ی Band، MTU، پیاچوونەوەی مێژوو (mode 2)، و ماناکانی HRV/خەو پێویستە بپشکنرێن.
- ❌ ECG ی ڕاستەقینە لە Android SDK دا فرمانی دەستپێکردنی نییە؛ تەنها PPG لە کاتی HRV. نەخراوەتە ناو ئەپ.
- ⚠️ `setTime` بە `tools/sdk_check` نەبەراورد کراوە (بەندە بە ناوچەی کاتی JVM).
- ⚠️ لایسنسی SDK و ڕێگەپێدانی دووبارە دابەشکردن لەگەڵ J-STYLE ڕوون بکەرەوە.
- ⚠️ دەقە نوێیەکانی پەڕەی VitalAge تەنها بە کوردی سۆرانین؛ لە زمانە تریشدا هەر سۆرانی دەردەکەون تا وەرگێڕان بۆ زیاد بکرێت.
