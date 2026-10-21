# ئاگادارکردنەوەی هەنگاو — Android و iOS

هەنگاو، کالۆری، کیلۆمەتر، دڵ و ماوەی ئامانج، هەمیشە لەسەر شاشەی مۆبایل. هەمان ئەو دیزاینەیە کە لە وێب بینیتت (`vex-steps-notif`).

| | Android | iOS |
|---|---|---|
| شێواز | notification ی بەردەوام (Foreground Service) | Live Activity + Dynamic Island + Widget ی شاشەی قفڵ |
| ژماردنی هەنگاو لە پشتەوە | بەڵێ، سێنسەری مۆبایل، ئەپ داخرابێت‌یش | تەنها کاتێک ئەپ کراوە/لە پشتەوەی نزیکە (بڕوانە خوارەوە) |
| swipe و گەڕانەوە دوای 1 خولەک | **بەڵێ** (خۆکار) | نا — iOS ڕێگا نادات (بڕوانە خوارەوە) |
| دوگمەی ئاو +١ | بەڵێ | نا |

## 1) Flutter (هەر دووکیان)
```bash
flutter create .          # ئەگەر android/ و ios/ ـت نییە
flutter pub get
```
لە ئەپەکە: **پرۆفایل ‹ ئاگادارکردنەوەی هەنگاو** سویچەکە بکەرەوە. مۆڵەتەکان دەپرسرێن.

## 2) Android
```bash
python3 tools/setup_native.py
flutter run
```
سکریپتەکە خۆی ئەمانە دەکات: Kotlin ـەکان، layout و drawable ـەکان، مۆڵەتەکان و `service`/`receiver` لە AndroidManifest. دووبارە جێبەجێکردنی بێ مەترسییە.

پێویستی: `compileSdk 34+` (هەموو پڕۆژەی نوێی Flutter وایە).
Android 13+: مۆڵەتی ئاگادارکردنەوە؛ Android 10+: مۆڵەتی «چالاکی جەستەیی».

**چۆن کار دەکات:** `StepService` هەنگاو لە `TYPE_STEP_COUNTER` دەژمێرێت و هەموو 3 چرکە/1 خولەک نوێی دەکاتەوە. ئەگەر Flutter داتای Band نارد، ئەوە دەبێتە بنەما و هەنگاوی مۆبایل لەسەری زیاد دەبێت. ئەگەر بەکارهێنەر notification ـەکە swipe بکات، دوای 60 چرکە خۆی دەگەڕێتەوە. دوای ڕیستارتی مۆبایل خۆی دەست پێدەکاتەوە (ئەگەر سویچەکە کرابێت).

⚠️ کارخانەی Xiaomi/Huawei/Oppo/Samsung ڕەنگە ئەپ لە پشتەوە بکوژن: بەکارهێنەر دەبێت «Battery ‹ Unrestricted» بۆ VEX Health دابنێت.

## 3) iOS (Xcode — یەک جار)
Widget Extension تەنها لە Xcode دروست دەکرێت، هەنگاوەکان:

1. `open ios/Runner.xcworkspace`
2. **Runner ‹ Signing & Capabilities ‹ + Capability ‹ App Groups** — گرووپێک دروست بکە، نموونە `group.com.xxx.vexhealth` (xxx = Bundle ID ی خۆت).
3. **File ‹ New ‹ Target ‹ Widget Extension** — ناوی `VexStepsWidget`، تیکی «Include Live Activity» و «Include Configuration App Intent» **مەکە** (کۆدەکەمان هەیە). لە پرسیاری Activate: Activate.
4. لە Target ی `VexStepsWidget`: **Deployment Target = iOS 16.2**، و هەمان **App Groups** capability (هەمان گرووپ).
5. فایلە خۆکارەکانی Xcode بۆ ئەو Target (`VexStepsWidget.swift` …) **بسڕەوە**، و ئەمانە زیاد بکە (Add Files):
   - `native/ios/VexStepsWidget/*.swift` ← تەنها Target ی `VexStepsWidget`
   - `native/ios/Shared_VexShared.swift` ← **هەردوو** Target (Runner و VexStepsWidget)
   - `native/ios/Runner/StepsBridge.swift` ← تەنها Runner
6. `Shared_VexShared.swift`: `appGroup` بگۆڕە بۆ گرووپەکەی خۆت.
7. `ios/Runner/AppDelegate.swift`: ئەو 3 دێڕەی `VexSteps` لە `native/ios/Runner/AppDelegate_snippet.swift` زیاد بکە.
8. `ios/Runner/Info.plist`: ناوەڕۆکی `native/ios/Info_plist_additions.xml` زیاد بکە.
9. دەبێت لەسەر **iPhone ی ڕاستەقینە** تاقی بکرێتەوە (Simulator ی Dynamic Island هەیە بەڵام هەنگاو نییە). iOS 16.2+ پێویستە. لە Settings ‹ VEX Health ‹ Live Activities چالاک بێت.

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
