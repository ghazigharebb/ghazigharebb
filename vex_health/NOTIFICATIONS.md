# ئاگادارکردنەوەی هەنگاو — Android و iOS

هەنگاو، کالۆری، کیلۆمەتر، دڵ و ماوەی ئامانج، هەمیشە لەسەر شاشەی مۆبایل. دیزاینی «گەشت»: ڕێگای ماڵ ← ڕاکەر ← ئاڵا،
ژمارەی هەنگاو بە فۆنتی Sora، ئایکۆنی شریتی سەرەوە لۆگۆی VX (`ic_stat_vx`).

**چۆن کێشراوە (Android):** RemoteViews فۆنتی تایبەت قبوڵ ناکات، بۆیە `StepArt.kt` ژمارەکە و ڕێگاکە وەک وێنە دەکێشێت
(فۆنتی Sora لە `assets/google_fonts/` ی Flutter ـەوە دەخوێنرێتەوە) و دەقە کوردییەکان TextView ن. دۆخی ڕووناک / تاریکی سیستەم خۆی دەناسێتەوە.

| | Android | iOS |
|---|---|---|
| شێواز | notification ی بەردەوام (Foreground Service) | Live Activity + Dynamic Island + Widget ی شاشەی قفڵ |
| ژماردنی هەنگاو لە پشتەوە | بەڵێ، سێنسەری مۆبایل، ئەپ داخرابێت‌یش | تەنها کاتێک ئەپ کراوە/لە پشتەوەی نزیکە (بڕوانە خوارەوە) |
| swipe و گەڕانەوە دوای 1 خولەک | **بەڵێ** (خۆکار) | نا — iOS ڕێگا نادات (بڕوانە خوارەوە) |
| دوگمەی ئاو +١ | بەڵێ | نا |

## دانان — 3 هەنگاو
```bash
flutter create .                 # تەنها ئەگەر android/ و ios/ ـت نییە
flutter pub get

# Android (لە هەر کۆمپیوتەرێک)
python3 tools/setup_native.py    # Kotlin، layout، ئایکۆن، مۆڵەت، desugaring و compileSdk خۆی دادەنێت

# iOS (لەسەر Mac)
gem install xcodeproj            # یەک جار
ruby tools/setup_ios.rb          # Widget Extension، App Group، Info.plist و AppDelegate خۆی دادەنێت
```
پاشان لە Xcode (`open ios/Runner.xcworkspace`): **Signing & Capabilities ‹ Team** بۆ `Runner` و `VexStepsWidget` هەڵبژێرە. ئینجا `flutter run`.

هەردوو سکریپت دووبارە جێبەجێکردنیان بێ مەترسییە (هیچ شتێک دووبارە زیاد ناکەن).
لە ئەپەکە: **پرۆفایل ‹ ئاگادارکردنەوەی هەنگاو** سویچەکە بکەرەوە. مۆڵەتەکان دەپرسرێن.

**Band:** کاتێک VEX Band پەیوەستە، هەنگاوی ئەمڕۆی Band دەبێتە بنەما و هەنگاوی مۆبایل لەسەری زیاد دەبێت؛ هەر کاتێک Band هاوکات دەکات یان جیا دەبێتەوە، ئاگادارکردنەوەکە خۆی نوێ دەبێتەوە. بێ Band تەنها سێنسەری مۆبایل بەکاردێت. ئامانج = ئامانجی کەسی بەکارهێنەر لە پلانی تۆمارکردن.

**پشکنراوە:** هەردوو سکریپت لەسەر پڕۆژەیەکی نوێی `flutter create` جێبەجێ کران و `flutter build apk` و `flutter build ios --no-codesign` سەرکەوتوو بوون (VexStepsWidget.appex لەناو ئەپەکەدایە).

⚠️ Xiaomi/Huawei/Oppo/Samsung ڕەنگە ئەپ لە پشتەوە بکوژن: «Battery ‹ Unrestricted» بۆ VEX Health.
iOS: دەبێت لەسەر **iPhone ی ڕاستەقینە** تاقی بکرێتەوە، iOS 16.2+، و Settings ‹ VEX Health ‹ Live Activities چالاک بێت.

## سنووردارییەکانی iOS (ڕاستگۆیانە)
- **بێ سێرڤەر:** Live Activity تەنها کاتێک نوێ دەبێتەوە کە ئەپ کراوەیە یان تازە داخراوە. ئەپ دابخرێت (swipe up) هەنگاو دەوەستێت تا جارێکی تر بیکەیتەوە. ئەگەر ئەپ لە پشتەوە بمێنێت، iOS دەتوانێت بیوەستێنێت.
- **swipe ← گەڕانەوە دوای 1 خولەک:** iOS ڕێگا نادات notification ی بەردەوام هەبێت. بەکارهێنەر Live Activity ڕابکێشێت، تەنها بە کردنەوەی ئەپ یان بە Push دەگەڕێتەوە.
- Live Activity زۆرینە 8 کاتژمێر نیشان دەدرێت (سنووری Apple).
- **ڕێگای تەواو (ئارەزوومەندانە):** سێرڤەرێک کە Push ی ActivityKit بنێرێت. `StepNotify.I.pushToken` توکنی Live Activity ـە؛ بینێرە بۆ سێرڤەر. نموونەی APNs (`apns-push-type: liveactivity`، topic = `<bundleId>.push-type.liveactivity`):
```json
{ "aps": { "timestamp": 1760000000, "event": "update",
    "content-state": { "steps": 6420, "goal": 10000, "km": 4.77, "kcal": 190, "hr": 72, "remKm": 2.65, "remMin": 34 } } }
```
  بۆ دەستپێکردنەوەی خۆکار دوای swipe (iOS 17.2+) دەکرێت `push-to-start token` بەکاربهێنرێت. ئەمە دواتر زیاد دەکرێت ئەگەر سێرڤەرت هەبوو.

## داتای هەنگاو
هەنگاو لە `Store.I.h.steps` دەخوێنرێتەوە (Band). ئێستا ئەو نموونەیە؛ کاتێک Band ڕاستەقینە بەسترا، تەنها ئەو ژمارەیە نوێ بکەرەوە و `Store.I.notifyListeners()` بکە — ئاگادارکردنەوەکە خۆی نوێ دەبێتەوە (کەمترین 4 چرکە جارێک).

## تاقیکردنەوە
- [ ] Android: سویچ ‹ مۆڵەتەکان ‹ notification دەردەکەوێت ‹ پیاسە بکە، ژمارە زیاد دەبێت
- [ ] Android: notification swipe بکە ‹ دوای 1 خولەک دەگەڕێتەوە
- [ ] Android: ئەپ دابخە ‹ پیاسە ‹ هەنگاو زیاد دەبێت؛ ئەپ بکەرەوە ‹ ژمارە یەک دەگرنەوە
- [ ] Android: «ئاو +١» ‹ ئەپ بکەرەوە ‹ پەرداخی ئاو زیاد بووە
- [ ] iOS: سویچ ‹ Dynamic Island + شاشەی قفڵ ‹ پیاسە ‹ ژمارە نوێ دەبێتەوە
- [ ] iOS: لە 10,000 کەسەکە لە تەنیشت ئاڵا دەوەستێت
