// VEX Health — هاوڕێ، خواردن (friend_food.dart)
//
// خواردن و ئاوی ئەندامانی بازنەی خێزان و هاوڕێ، ڕاستەوخۆ:
//   • هەر کاتێک تۆ ژەمێک یان پەرداخێک ئاو تۆمار دەکەیت (بەشی خواردن vexfd_v1، تۆماری
//     سەرەکی vexhome-food، ئاو vexwater)، وێنەیەکی ئەمڕۆت دروست دەکرێت و — ئەگەر
//     «خواردن و کالۆری» لە «چی هاوبەش دەکەم» کرابێتەوە — دەنێردرێت بۆ سێرڤەر.
//   • لە شیتی ئەندامدا FriendFoodCard هەمان کارتی وێبەکە پیشان دەدات: ڕینگی کالۆری بەرامبەر
//     ئامانج، پرۆتین/کاربۆ/چەوری، خاڵی خواردن، ژەمەکان بە کات و کالۆری، پەرداخەکانی ئاو،
//     کالۆری هەفتەکە و ئامۆژگاری. هەر 20 چرکە نوێ دەبێتەوە و ژەمی نوێ بە تۆست ئاگادار دەکات.
//   • 6 زمان (ckb · kmr · en · ar · fa · tr) و ڕووناک / تاریک / خۆکار.
//
// دانان (3 هەنگاو):
//   1) main.dart  ← دوای  await FamilyStore.I.load();
//          await FriendFood.I.init(baseUrl: kFriendFoodServer);
//   2) family_page.dart ← لە _MemberSheet، لە جیاتی بەشی «خواردن و ئاو هاوبەش نەکراوە…»:
//          FriendFoodCard(member: m),
//   3) (ئارەزوومەندانە) لە _PrivacyCard:  const FriendFoodPreviewLink(),
//
// سێرڤەر (REST · JSON · UTF-8) — ئەگەر kFriendFoodServer بەتاڵ بێت، کۆگای ناوخۆیی بەکاردێت
// (تەنها ئەم مۆبایلە + نموونەی ئەندامە دیمۆکان). بۆ کارکردن لە نێوان دوو مۆبایل:
//   PUT  {base}/v1/friends/food/{uid}           body = FFSnap.toJson()   ← ناردنی ئەمڕۆی من
//   GET  {base}/v1/friends/food/{uid}?day=YYYY-MM-DD                     ← وەرگرتنی هاوڕێ
//        200 → FFSnap JSON   ·   403 یان {"shared":false} → هاوبەشی نەکردووە   ·   404 → هیچ نییە
//   POST {base}/v1/friends/food/{uid}/request   body = {"from": myUid}   ← داوای هاوبەشکردن
//   Header: Authorization: Bearer <token>  (ئەگەر token دابنرێت)
// سێرڤەر دەبێت تەنها ئەو کەسانە ڕێگە بدات کە لە بازنەکەدان. uid ـی ئەندام = FMember.id،
// یان FriendFood.I.link(memberId, uid). ئاگادارکردنەوەی Push/WebSocket: FriendFood.I.receive(json).
// Firebase / Supabase: کلاسێک لە FriendFoodBackend دروست بکە و  init(custom: …)  بەکاربهێنە.
import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../core/store.dart';
import '../core/theme.dart';
import '../onboarding/account.dart';
import '../onboarding/reg_lang_state.dart';
import 'family_data.dart';

/// ناونیشانی سێرڤەری هاوبەشکردنی خواردن، بۆ نموونە: 'https://api.vexhealth.app'
/// (بەتاڵ = کۆگای ناوخۆیی)
const String kFriendFoodServer = '';

// ═════════════════════════════ زمان ═════════════════════════════
const Map<String, Map<String, Object>> _kFF = {
  'ckb': {
    'dir': 'rtl',
    'title': 'ئەمڕۆ چی خواردووە',
    'mine': 'خواردنی ئەمڕۆی من',
    'head': 'خواردن و ئاو',
    's3': ['زۆر باش', 'باش', 'پێویستی بە باشترکردنە'],
    'of': 'لە {g}',
    'mac': ['پرۆتین', 'کاربۆ', 'چەوری'],
    'mb': 'بەیانی', 'ml': 'نیوەڕۆ', 'ms': 'نێوان ژەم', 'md': 'ئێوارە', 'mn': 'درەنگی شەو',
    'water': 'ئاوی خواردراوە',
    'wLeft': 'ماوە {n} پەرداخ',
    'wDone': '✅ ئامانج تەواو بوو',
    'wEx': '🏆 +{n} پەرداخی زیاد!',
    'gl': '{a} / {b} پەرداخ',
    'week': 'کالۆری هەفتەکە',
    'goal': 'ئامانج',
    'avg': 'ناوەند', 'hit': 'ڕۆژی ئامانج', 'best': 'نزیکترین ڕۆژ', 'today': 'ئەمڕۆ',
    'lg': ['نزیک ئامانج', 'کەمتر', 'زیاتر'],
    'tp': 'پرۆتینەکەی کەمە — هێلکە، ماست یان مریشک زیاد بکات باشترە',
    'tf': 'چەوری زۆرە — با خواردنی برژاو و چەور کەم بکاتەوە',
    'tc': 'کاربۆهایدرەیتی زۆرە — سەوزە و پرۆتین زیاد بکات',
    'tw': 'شیرینی/برژاوی زۆر خواردووە — با ئاو و میوە بخواتەوە',
    'tok': 'هاوسەنگی خواردنەکەی زۆر باشە 👏',
    'tg': 'کەمێک سەوزە و پرۆتین زیاد بکات باشترە',
    'lock': '{n} هێشتا خواردن و ئاوی هاوبەش نەکردووە',
    'lockS': 'کاتێک {n} لە «چی هاوبەش دەکەم» خواردن و کالۆری بکاتەوە، هەموو ژەمێک و هەر پەرداخێک ئاو ڕاستەوخۆ لێرە دەردەکەوێت.',
    'ask': '🙏 داوای لێ بکە هاوبەشی بکات',
    'asked': '✓ داواکارییەکە بۆ {n} نێردرا',
    'none': 'ئەمڕۆ هێشتا هیچی تۆمار نەکردووە',
    'noneS': 'کە {n} یەکەم ژەم یان پەرداخێک ئاو تۆمار بکات، ڕاستەوخۆ لێرە دەردەکەوێت.',
    'noneMe': 'تۆ ئەمڕۆ هێشتا هیچت تۆمار نەکردووە',
    'noneMeS': 'هەر ژەمێک یان پەرداخێک ئاو لە بەشی خواردن تۆمار بکەیت، بازنەکەت لێرە دەیبینن.',
    'off': 'پەیوەندی بە سێرڤەرەوە نییە — دوایین داتا پیشان دەدرێت',
    'err': 'نەتوانرا داتای خواردن وەربگیرێت',
    'retry': 'دووبارە هەوڵبدەوە',
    'load': 'وەرگرتنی داتای خواردن…',
    'upd': 'نوێکرایەوە {t}',
    'now': 'ئێستا',
    'min': '{n} خولەک لەمەوبەر',
    'hr': '{n} کاتژمێر لەمەوبەر',
    'live': 'ڕاستەوخۆ',
    'nMeal': '🍽️ {n}: {m} · {k} kcal',
    'nWater': '💧 {n} پەرداخێک ئاوی خواردەوە',
    'share': 'هاوبەشکردنی خواردن و ئاو',
    'shOn': 'بازنەکەت ژەم و ئاوەکەت دەبینن',
    'shOff': 'کەس خواردنەکەت نابینێت',
    'prev': 'ئەوەی بازنەکەت دەیبینن',
    'demo': 'نموونە',
    'days': ['دووشەممە', 'سێشەممە', 'چوارشەممە', 'پێنجشەممە', 'هەینی', 'شەممە', 'یەکشەممە'],
  },
  'kmr': {
    'dir': 'rtl',
    'title': 'ئەڤرۆ چ خوارییە',
    'mine': 'خوارنا من یا ئەڤرۆ',
    'head': 'خوارن و ئاڤ',
    's3': ['گەلەک باش', 'باش', 'پێدڤی ب باشترکرنێ یە'],
    'of': 'ژ {g}',
    'mac': ['پرۆتین', 'کاربۆ', 'چەوری'],
    'mb': 'تێشت', 'ml': 'فراڤین', 'ms': 'ناڤبەرا ژەمان', 'md': 'شیڤ', 'mn': 'درەنگێ شەڤێ',
    'water': 'ئاڤا ڤەخواری',
    'wLeft': '{n} پەرداخ ماینە',
    'wDone': '✅ ئارمانج ب دووماهی هات',
    'wEx': '🏆 +{n} پەرداخێن زێدە!',
    'gl': '{a} / {b} پەرداخ',
    'week': 'کالۆرییێن ڤێ حەفتیێ',
    'goal': 'ئارمانج',
    'avg': 'ناڤنجی', 'hit': 'ڕۆژێن ئارمانجێ', 'best': 'نێزیکترین ڕۆژ', 'today': 'ئەڤرۆ',
    'lg': ['نێزیکی ئارمانجێ', 'کێمتر', 'پتر'],
    'tp': 'پرۆتینا وی کێمە — باشترە هێک، ماست یان مریشک زێدە بکەت',
    'tf': 'چەوری زۆرە — بلا خوارنێن سۆرکری و چەور کێم بکەت',
    'tc': 'کاربۆهایدرەیت زۆرە — بلا سەوزە و پرۆتینێ زێدە بکەت',
    'tw': 'شرینی/سۆرکری زۆر خوارینە — بلا ئاڤێ ڤەخوەت و فێقی بخوەت',
    'tok': 'هەڤسەنگیا خوارنا وی گەلەک باشە 👏',
    'tg': 'باشترە پچەکێ سەوزە و پرۆتین زێدە بکەت',
    'lock': '{n} هێشتا خوارن و ئاڤ پارڤە نەکرینە',
    'lockS': 'دەمێ {n} پارڤەکرنا «خوارن و کالۆری» ڤەکەت، هەر ژەمەک و هەر پەرداخەکا ئاڤێ ڕاستەوخۆ دێ ل ڤێرە دیار بیت.',
    'ask': '🙏 داخوازێ لێ بکە پارڤە بکەت',
    'asked': '✓ داخواز بۆ {n} هاتە هنارتن',
    'none': 'ئەڤرۆ هێشتا چ تۆمار نەکرینە',
    'noneS': 'هەر دەمێ {n} ژەمەکێ یان پەرداخەکا ئاڤێ تۆمار بکەت، دێ ل ڤێرە دیار بیت.',
    'noneMe': 'تە ئەڤرۆ هێشتا چ تۆمار نەکرینە',
    'noneMeS': 'هەر ژەمەک یان پەرداخەکا ئاڤێ ل پشکا خوارنێ تۆمار بکەی، بازنێ تە دێ ل ڤێرە بینیت.',
    'off': 'پەیوەندی ب سێرڤەری ڤە نینە — داتایێن دوماهیێ دیار دبن',
    'err': 'نەشیا داتایێن خوارنێ وەربگریت',
    'retry': 'دووبارە هەوڵ بدە',
    'load': 'وەرگرتنا داتایێن خوارنێ…',
    'upd': 'هاتە نووکرن {t}',
    'now': 'نوکە',
    'min': 'بەری {n} خولەکان',
    'hr': 'بەری {n} دەمژمێران',
    'live': 'ڕاستەوخۆ',
    'nMeal': '🍽️ {n}: {m} · {k} kcal',
    'nWater': '💧 {n} پەرداخەکا ئاڤێ ڤەخوار',
    'share': 'پارڤەکرنا خوارن و ئاڤێ',
    'shOn': 'بازنێ تە ژەم و ئاڤا تە دبینیت',
    'shOff': 'کەس خوارنا تە نابینیت',
    'prev': 'ئەوا بازنێ تە دبینیت',
    'demo': 'نموونە',
    'days': ['دووشەممی', 'سێشەممی', 'چارشەممی', 'پێنجشەممی', 'ئەینی', 'شەممی', 'یەکشەممی'],
  },
  'en': {
    'dir': 'ltr',
    'title': 'What they ate today',
    'mine': 'My food today',
    'head': 'Food & water',
    's3': ['Excellent', 'Good', 'Needs work'],
    'of': 'of {g}',
    'mac': ['Protein', 'Carbs', 'Fat'],
    'mb': 'Breakfast', 'ml': 'Lunch', 'ms': 'Snack', 'md': 'Dinner', 'mn': 'Late night',
    'water': 'Water intake',
    'wLeft': '{n} glasses left',
    'wDone': '✅ Goal reached',
    'wEx': '🏆 +{n} extra glasses!',
    'gl': '{a} / {b} glasses',
    'week': 'Calories this week',
    'goal': 'Goal',
    'avg': 'Average', 'hit': 'On-goal days', 'best': 'Closest day', 'today': 'Today',
    'lg': ['Near goal', 'Under', 'Over'],
    'tp': 'Protein is low — eggs, yogurt or chicken would help',
    'tf': 'Fat is high — cut back on fried and greasy food',
    'tc': 'Carbs are high — add vegetables and protein',
    'tw': 'Lots of sweets/fried food — drink water and eat fruit',
    'tok': 'Great balance today 👏',
    'tg': 'A little more vegetables and protein would be better',
    'lock': '{n} hasn\'t shared food & water yet',
    'lockS': 'When {n} turns on “Food & calories” in sharing, every meal and every glass of water shows up here live.',
    'ask': '🙏 Ask to share',
    'asked': '✓ Request sent to {n}',
    'none': 'Nothing logged yet today',
    'noneS': 'As soon as {n} logs a meal or a glass of water, it shows up here.',
    'noneMe': 'You haven\'t logged anything today',
    'noneMeS': 'Every meal or glass of water you log in Food is what your circle sees here.',
    'off': 'Server unreachable — showing the latest data',
    'err': 'Couldn\'t load the food data',
    'retry': 'Try again',
    'load': 'Loading food data…',
    'upd': 'Updated {t}',
    'now': 'just now',
    'min': '{n} min ago',
    'hr': '{n} h ago',
    'live': 'Live',
    'nMeal': '🍽️ {n}: {m} · {k} kcal',
    'nWater': '💧 {n} drank a glass of water',
    'share': 'Share food & water',
    'shOn': 'Your circle sees your meals and water',
    'shOff': 'No one sees your food',
    'prev': 'What your circle sees',
    'demo': 'Sample',
    'days': ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'],
  },
  'ar': {
    'dir': 'rtl',
    'title': 'ماذا أكل اليوم',
    'mine': 'طعامي اليوم',
    'head': 'الطعام والماء',
    's3': ['ممتاز', 'جيد', 'يحتاج تحسين'],
    'of': 'من {g}',
    'mac': ['بروتين', 'كربو', 'دهون'],
    'mb': 'الفطور', 'ml': 'الغداء', 'ms': 'وجبة خفيفة', 'md': 'العشاء', 'mn': 'آخر الليل',
    'water': 'الماء المشروب',
    'wLeft': 'باقي {n} أكواب',
    'wDone': '✅ اكتمل الهدف',
    'wEx': '🏆 +{n} أكواب إضافية!',
    'gl': '{a} / {b} أكواب',
    'week': 'سعرات هذا الأسبوع',
    'goal': 'الهدف',
    'avg': 'المتوسط', 'hit': 'أيام الهدف', 'best': 'أقرب يوم', 'today': 'اليوم',
    'lg': ['قريب من الهدف', 'أقل', 'أكثر'],
    'tp': 'البروتين قليل — يُفضّل إضافة بيض أو لبن أو دجاج',
    'tf': 'الدهون كثيرة — ليقلّل المقليات والأطعمة الدسمة',
    'tc': 'الكربوهيدرات كثيرة — ليُضِف خضارًا وبروتينًا',
    'tw': 'تناول حلويات/مقليات كثيرة — ليشرب الماء ويأكل الفاكهة',
    'tok': 'توازن طعامه اليوم ممتاز 👏',
    'tg': 'يُفضّل إضافة قليل من الخضار والبروتين',
    'lock': '{n} لم يشارك الطعام والماء بعد',
    'lockS': 'عندما يفعّل {n} مشاركة «الطعام والسعرات»، ستظهر هنا كل وجبة وكل كوب ماء مباشرة.',
    'ask': '🙏 اطلب منه المشاركة',
    'asked': '✓ تم إرسال الطلب إلى {n}',
    'none': 'لم يسجّل شيئًا اليوم بعد',
    'noneS': 'بمجرد أن يسجّل {n} وجبة أو كوب ماء سيظهر هنا.',
    'noneMe': 'لم تسجّل شيئًا اليوم بعد',
    'noneMeS': 'كل وجبة أو كوب ماء تسجّله في قسم الطعام تراه دائرتك هنا.',
    'off': 'لا اتصال بالخادم — تُعرض آخر البيانات',
    'err': 'تعذّر جلب بيانات الطعام',
    'retry': 'أعد المحاولة',
    'load': 'جارٍ جلب بيانات الطعام…',
    'upd': 'حُدّث {t}',
    'now': 'الآن',
    'min': 'قبل {n} دقيقة',
    'hr': 'قبل {n} ساعة',
    'live': 'مباشر',
    'nMeal': '🍽️ {n}: {m} · {k} kcal',
    'nWater': '💧 {n} شرب كوب ماء',
    'share': 'مشاركة الطعام والماء',
    'shOn': 'دائرتك ترى وجباتك والماء',
    'shOff': 'لا أحد يرى طعامك',
    'prev': 'ما تراه دائرتك',
    'demo': 'مثال',
    'days': ['الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت', 'الأحد'],
  },
  'fa': {
    'dir': 'rtl',
    'title': 'امروز چه خورده',
    'mine': 'غذای امروز من',
    'head': 'غذا و آب',
    's3': ['عالی', 'خوب', 'نیاز به بهبود'],
    'of': 'از {g}',
    'mac': ['پروتئین', 'کربو', 'چربی'],
    'mb': 'صبحانه', 'ml': 'ناهار', 'ms': 'میان‌وعده', 'md': 'شام', 'mn': 'آخر شب',
    'water': 'آب نوشیده‌شده',
    'wLeft': '{n} لیوان مانده',
    'wDone': '✅ هدف کامل شد',
    'wEx': '🏆 +{n} لیوان اضافه!',
    'gl': '{a} / {b} لیوان',
    'week': 'کالری این هفته',
    'goal': 'هدف',
    'avg': 'میانگین', 'hit': 'روزهای هدف', 'best': 'نزدیک‌ترین روز', 'today': 'امروز',
    'lg': ['نزدیک هدف', 'کمتر', 'بیشتر'],
    'tp': 'پروتئینش کم است — بهتر است تخم‌مرغ، ماست یا مرغ اضافه کند',
    'tf': 'چربی زیاد است — غذای سرخ‌کرده و چرب را کم کند',
    'tc': 'کربوهیدرات زیاد است — سبزی و پروتئین اضافه کند',
    'tw': 'شیرینی/سرخ‌کرده زیاد خورده — آب بنوشد و میوه بخورد',
    'tok': 'تعادل غذایش امروز عالی است 👏',
    'tg': 'بهتر است کمی سبزی و پروتئین اضافه کند',
    'lock': '{n} هنوز غذا و آب را به اشتراک نگذاشته',
    'lockS': 'وقتی {n} اشتراک «غذا و کالری» را روشن کند، هر وعده و هر لیوان آب همین‌جا زنده نمایش داده می‌شود.',
    'ask': '🙏 درخواست اشتراک',
    'asked': '✓ درخواست برای {n} فرستاده شد',
    'none': 'امروز هنوز چیزی ثبت نکرده',
    'noneS': 'به محض اینکه {n} وعده یا لیوان آبی ثبت کند، اینجا نمایش داده می‌شود.',
    'noneMe': 'امروز هنوز چیزی ثبت نکرده‌ای',
    'noneMeS': 'هر وعده یا لیوان آبی که در بخش غذا ثبت کنی، حلقه‌ات اینجا می‌بیند.',
    'off': 'اتصال به سرور برقرار نیست — آخرین داده‌ها نمایش داده می‌شود',
    'err': 'دریافت داده‌های غذا ممکن نشد',
    'retry': 'تلاش دوباره',
    'load': 'در حال دریافت داده‌های غذا…',
    'upd': 'به‌روزرسانی {t}',
    'now': 'همین حالا',
    'min': '{n} دقیقه پیش',
    'hr': '{n} ساعت پیش',
    'live': 'زنده',
    'nMeal': '🍽️ {n}: {m} · {k} kcal',
    'nWater': '💧 {n} یک لیوان آب نوشید',
    'share': 'اشتراک غذا و آب',
    'shOn': 'حلقه‌ات وعده‌ها و آبت را می‌بیند',
    'shOff': 'هیچ‌کس غذایت را نمی‌بیند',
    'prev': 'آنچه حلقه‌ات می‌بیند',
    'demo': 'نمونه',
    'days': ['دوشنبه', 'سه‌شنبه', 'چهارشنبه', 'پنجشنبه', 'جمعه', 'شنبه', 'یکشنبه'],
  },
  'tr': {
    'dir': 'ltr',
    'title': 'Bugün ne yedi',
    'mine': 'Bugünkü yemeklerim',
    'head': 'Yemek ve su',
    's3': ['Çok iyi', 'İyi', 'Geliştirilmeli'],
    'of': 'hedef {g}',
    'mac': ['Protein', 'Karb.', 'Yağ'],
    'mb': 'Kahvaltı', 'ml': 'Öğle', 'ms': 'Ara öğün', 'md': 'Akşam', 'mn': 'Gece',
    'water': 'İçilen su',
    'wLeft': '{n} bardak kaldı',
    'wDone': '✅ Hedef tamam',
    'wEx': '🏆 +{n} ekstra bardak!',
    'gl': '{a} / {b} bardak',
    'week': 'Bu haftanın kalorisi',
    'goal': 'Hedef',
    'avg': 'Ortalama', 'hit': 'Hedef günleri', 'best': 'En yakın gün', 'today': 'Bugün',
    'lg': ['Hedefe yakın', 'Az', 'Fazla'],
    'tp': 'Proteini az — yumurta, yoğurt ya da tavuk eklemesi iyi olur',
    'tf': 'Yağ fazla — kızartma ve yağlı yiyecekleri azaltmalı',
    'tc': 'Karbonhidrat fazla — sebze ve protein eklemeli',
    'tw': 'Çok tatlı/kızartma yemiş — su içip meyve yemeli',
    'tok': 'Bugünkü beslenme dengesi çok iyi 👏',
    'tg': 'Biraz sebze ve protein eklemesi daha iyi olur',
    'lock': '{n} henüz yemek ve su paylaşmadı',
    'lockS': '{n} paylaşımda “Yemek ve kalori”yi açtığında her öğün ve her bardak su burada canlı görünür.',
    'ask': '🙏 Paylaşmasını iste',
    'asked': '✓ İstek gönderildi: {n}',
    'none': 'Bugün henüz bir şey kaydetmedi',
    'noneS': '{n} bir öğün ya da bir bardak su kaydettiği anda burada görünür.',
    'noneMe': 'Bugün henüz bir şey kaydetmedin',
    'noneMeS': 'Yemek bölümünde kaydettiğin her öğünü ve suyu çevren burada görür.',
    'off': 'Sunucuya ulaşılamıyor — son veriler gösteriliyor',
    'err': 'Yemek verileri alınamadı',
    'retry': 'Tekrar dene',
    'load': 'Yemek verileri alınıyor…',
    'upd': 'Güncellendi: {t}',
    'now': 'şimdi',
    'min': '{n} dk önce',
    'hr': '{n} sa önce',
    'live': 'Canlı',
    'nMeal': '🍽️ {n}: {m} · {k} kcal',
    'nWater': '💧 {n} bir bardak su içti',
    'share': 'Yemek ve su paylaşımı',
    'shOn': 'Çevren öğünlerini ve suyunu görür',
    'shOff': 'Kimse yemeğini görmez',
    'prev': 'Çevrenin gördüğü',
    'demo': 'Örnek',
    'days': ['Pazartesi', 'Salı', 'Çarşamba', 'Perşembe', 'Cuma', 'Cumartesi', 'Pazar'],
  },
};

Map<String, Object> get _L => _kFF[LangState.I.code] ?? _kFF['ckb']!;
Map<String, Object> get _L0 => _kFF['ckb']!;
String _t(String k) => '${_L[k] ?? _L0[k] ?? k}';
List<String> _tl(String k) {
  final v = _L[k] ?? _L0[k];
  return v is List ? v.map((e) => '$e').toList() : const <String>[];
}

String _tf(String k, Map<String, Object?> a) =>
    _t(k).replaceAllMapped(RegExp(r'\{(\w+)\}'), (m) => '${a[m.group(1)] ?? ''}');
bool get _isLtr => _L['dir'] == 'ltr';
TextDirection get _dir => _isLtr ? TextDirection.ltr : TextDirection.rtl;

/// ژمارە و کات لەناو دەقی RTL وەک خۆی دەمێنێتەوە
String _iso(String s) => '⁦$s⁩';

// ═════════════════════════════ یارمەتیدەر ═════════════════════════════
int _i(Object? v) => v is num ? (v.isFinite ? v.round() : 0) : (int.tryParse('${v ?? ''}') ?? double.tryParse('${v ?? ''}')?.round() ?? 0);
double _d(Object? v) => v is num ? (v.isFinite ? v.toDouble() : 0) : (double.tryParse('${v ?? ''}') ?? 0);
String _s(Object? v) => v == null ? '' : '$v'.trim();

/// کلیلی ڕۆژ: 2026-10-28
String ffDayKey(DateTime d) => '${d.year}-${pad2(d.month)}-${pad2(d.day)}';

/// «8:5» یان «08:05» ← «08:05»؛ هەڵە ← ''
String _hm(String s) {
  final m = RegExp(r'^(\d{1,2}):(\d{1,2})').firstMatch(s.trim());
  if (m == null) return '';
  final h = int.parse(m.group(1)!), mi = int.parse(m.group(2)!);
  if (h > 23 || mi > 59) return '';
  return '${pad2(h)}:${pad2(mi)}';
}

const List<String> _kSlots = ['b', 'l', 's', 'd', 'n'];
String _slotOk(String s) => _kSlots.contains(s) ? s : '';

/// ژەم لە کاتەوە
String _slotAt(String hm) {
  final h = int.tryParse(hm.split(':').first) ?? DateTime.now().hour;
  if (h < 5) return 'n';
  if (h < 11) return 'b';
  if (h < 12) return 's';
  if (h < 16) return 'l';
  if (h < 18) return 's';
  if (h < 22) return 'd';
  return 'n';
}

const Map<String, String> _kSlotE = {'b': '☀️', 'l': '🌤️', 's': '🍎', 'd': '🌙', 'n': '🌌'};
const Map<String, int> _kSlotC = {'b': 0xFFFFBE4D, 'l': 0xFF3CF08A, 's': 0xFFFF8FC8, 'd': 0xFF9B7BFF, 'n': 0xFF6AA8FF};

/// ڕەنگی دەق لە دۆخی ڕووناکدا تۆختر دەکرێت بۆ خوێندنەوە
Color _ink(Color c) => VexTheme.I.isLight ? (Color.lerp(c, const Color(0xFF000000), 0.40) ?? c) : c;

// ═════════════════════════════ مۆدێل ═════════════════════════════
/// یەک خواردن لە ژەمێکدا
class FFItem {
  const FFItem({
    required this.n,
    this.e = '',
    this.s = 'l',
    this.at = '',
    this.k = 0,
    this.p = 0,
    this.c = 0,
    this.f = 0,
    this.w = false,
  });

  final String n; // ناو
  final String e; // ئیمۆجی (ئارەزوومەندانە)
  final String s; // ژەم: b بەیانی · l نیوەڕۆ · s نێوان · d ئێوارە · n شەو
  final String at; // کات HH:MM
  final int k, p, c, f; // kcal · پرۆتین · کاربۆ · چەوری (g)
  final bool w; // ئاگاداری (خواردنی نەگونجاو)

  Map<String, dynamic> toJson() => {'n': n, 'e': e, 's': s, 'at': at, 'k': k, 'p': p, 'c': c, 'f': f, 'w': w};

  static FFItem? fromJson(Object? o) {
    if (o is! Map) return null;
    final n = _s(o['n']);
    if (n.isEmpty) return null;
    final at = _hm(_s(o['at']));
    final s = _slotOk(_s(o['s'] ?? o['slot']));
    return FFItem(
      n: n.length > 80 ? n.substring(0, 80) : n,
      e: _s(o['e']),
      s: s.isEmpty ? _slotAt(at) : s,
      at: at,
      k: math.max(0, _i(o['k'] ?? o['kcal'])),
      p: math.max(0, _i(o['p'])),
      c: math.max(0, _i(o['c'])),
      f: math.max(0, _i(o['f'])),
      w: o['w'] == true,
    );
  }
}

/// وێنەی خواردن و ئاوی ئەمڕۆی کەسێک (ئەوەی دەنێردرێت و وەردەگیرێت)
class FFSnap {
  FFSnap({
    required this.uid,
    this.name = '',
    required this.day,
    required this.at,
    this.shared = true,
    this.goal = 2000,
    this.pg = 0,
    this.cg = 0,
    this.fg = 0,
    this.water = 0,
    this.wgoal = 8,
    this.items = const <FFItem>[],
    this.week = const <int?>[],
    this.demo = false,
  });

  /// وێنەی «هاوبەش ناکرێت» (کاتێک بەکارهێنەر هاوبەشکردنی کوژاندەوە)
  factory FFSnap.off(String uid, String day) =>
      FFSnap(uid: uid, day: day, at: DateTime.now().millisecondsSinceEpoch, shared: false);

  final String uid, name, day; // day = YYYY-MM-DD
  final int at; // کاتی نوێکردنەوە (ms)
  final bool shared, demo;
  final int goal, pg, cg, fg; // ئامانجی kcal و ماکرۆکان (g)
  final int water, wgoal; // پەرداخ (250ml)
  final List<FFItem> items;
  final List<int?> week; // 7 ڕۆژی کۆتایی، دوایینیان ئەمڕۆیە

  int get kcal => items.fold(0, (a, x) => a + x.k);
  int get p => items.fold(0, (a, x) => a + x.p);
  int get c => items.fold(0, (a, x) => a + x.c);
  int get f => items.fold(0, (a, x) => a + x.f);
  bool get isToday => day == ffDayKey(DateTime.now());
  bool get hasData => items.isNotEmpty || water > 0;

  Map<String, dynamic> toJson() {
    final ev = shared && hasData ? _eval(this) : null;
    return {
      'v': 1,
      'uid': uid,
      'name': name,
      'day': day,
      'at': at,
      'shared': shared,
      if (shared) ...{
        'goal': goal,
        'pg': pg,
        'cg': cg,
        'fg': fg,
        'water': water,
        'wgoal': wgoal,
        'kcal': kcal,
        'p': p,
        'c': c,
        'f': f,
        'score': ev?.sc ?? 0,
        'items': items.map((e) => e.toJson()).toList(),
        'week': week,
      },
      if (demo) 'demo': true,
    };
  }

  static FFSnap? fromJson(Object? o) {
    if (o is! Map) return null;
    final uid = _s(o['uid']);
    final day = _s(o['day']);
    if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(day)) return null;
    final goal = clampI(_i(o['goal']) <= 0 ? 2000 : _i(o['goal']), 800, 6000);
    final items = <FFItem>[];
    final raw = o['items'];
    if (raw is List) {
      for (final x in raw) {
        final it = FFItem.fromJson(x);
        if (it != null) items.add(it);
        if (items.length >= 60) break;
      }
    }
    final wk = <int?>[];
    final rw = o['week'];
    if (rw is List) {
      for (final x in rw.take(7)) {
        wk.add(x == null ? null : math.max(0, _i(x)));
      }
    }
    int g(String k, double share, int per) {
      final v = _i(o[k]);
      return v > 0 ? v : (goal * share / per).round();
    }

    return FFSnap(
      uid: uid,
      name: _s(o['name']),
      day: day,
      at: _i(o['at']) > 0 ? _i(o['at']) : DateTime.now().millisecondsSinceEpoch,
      shared: o['shared'] != false,
      goal: goal,
      pg: g('pg', 0.25, 4),
      cg: g('cg', 0.50, 4),
      fg: g('fg', 0.25, 9),
      water: clampI(_i(o['water']), 0, 40),
      wgoal: clampI(_i(o['wgoal']) <= 0 ? 8 : _i(o['wgoal']), 4, 16),
      items: items,
      week: wk,
      demo: o['demo'] == true,
    );
  }
}

// ═════════════════════════════ هەڵسەنگاندن (وەک وێبەکە) ═════════════════════════════
class _Ev {
  const _Ev(this.sc, this.tip);
  final int sc;
  final String tip; // کلیلی ئامۆژگاری
}

/// چەند لە ڕۆژەکە تێپەڕیوە بە پێی ژەمەکان (بۆ ئەوەی بەیانی خاڵ کەم نەبێت)
double _progAt(int hr) {
  const hs = [7, 13, 16, 20];
  const ws = [0.25, 0.40, 0.10, 0.25];
  double p = 0;
  for (int i = 0; i < hs.length; i++) {
    if (!(hr < hs[i] + 1 && hr < 22)) p += ws[i];
  }
  return p <= 0 ? 0.25 : p;
}

_Ev _eval(FFSnap s) {
  final kcal = s.kcal;
  final k = math.max(kcal, 1);
  final pP = (s.p * 4 / k * 100).round(), cP = (s.c * 4 / k * 100).round(), fP = (s.f * 9 / k * 100).round();
  final warn = s.items.where((x) => x.w).length;
  final hr = s.isToday ? DateTime.now().hour : 23;
  final dev = (kcal / (math.max(s.goal, 1) * math.min(_progAt(hr), 1.0)) - 1).abs();
  double sc = 100 - math.min(35, dev * 80) - (pP < 14 ? 12 : 0) - (fP > 38 ? 10 : 0) - (cP > 65 ? 10 : 0) - warn * 4;
  if (s.water >= s.wgoal) sc += 3;
  final v = clampI(sc.round(), 42, 98);
  final tip = kcal <= 0
      ? 'tg'
      : pP < 14
          ? 'tp'
          : fP > 38
              ? 'tf'
              : cP > 65
                  ? 'tc'
                  : warn > 1
                      ? 'tw'
                      : v >= 78
                          ? 'tok'
                          : 'tg';
  return _Ev(v, tip);
}

// ═════════════════════════════ ئەمڕۆی من (لە بەشی خواردنەوە) ═════════════════════════════
class _Goals {
  const _Goals(this.kcal, this.p, this.c, this.f, this.waterMl);
  final int kcal, p, c, f, waterMl;
}

/// هەمان پلانی بەشی خواردن (Mifflin-St Jeor) لە پرۆفایلی vexfd_v1
_Goals? _planFrom(Object? prof) {
  if (prof is! Map) return null;
  final w = _d(prof['w']), h = _d(prof['h']), age = _d(prof['age']);
  if (w < 25 || h < 100 || age < 5) return null;
  final sex = _s(prof['sex']);
  final goal = _s(prof['goal']);
  final pace = _d(prof['pace']) == 0 ? 0.5 : _d(prof['pace']);
  final act = _d(prof['act']) == 0 ? 1.375 : _d(prof['act']);
  final days = _i(prof['days']);
  final conds = prof['conds'] is List ? (prof['conds'] as List).map((e) => '$e').toList() : const <String>[];
  final bmr = 10 * w + 6.25 * h - 5 * age + (sex == 'm' ? 5 : -161);
  final tdee = bmr * act;
  final risky = conds.any((x) => const ['preg', 'bf', 'kid', 'heart'].contains(x));
  double k = tdee;
  if (goal == 'lose') {
    double d = (pace * 1100).roundToDouble();
    if (risky) d = math.min(d, 300);
    if (age >= 65) d = math.min(d, 400);
    k = tdee - d;
  }
  if (goal == 'muscle') k = tdee + 250;
  if (goal == 'gain') k = tdee + math.min(500, (pace * 1100).roundToDouble());
  if (conds.contains('preg')) k = math.max(k, tdee + 250);
  if (conds.contains('bf')) k = math.max(k, tdee + 300);
  final floor = sex == 'm' ? 1500.0 : 1200.0;
  if (k < floor) k = floor;
  k = (k / 10).round() * 10.0;
  double pk = const {'lose': 1.8, 'keep': 1.4, 'muscle': 2.0, 'gain': 1.6, 'aging': 1.2}[goal] ?? 1.4;
  if (conds.contains('kid')) pk = 0.8;
  final pr = (w * pk).round();
  final fat = (k * 0.28 / 9).round();
  int carb = math.max(0, ((k - pr * 4 - fat * 9) / 4).round());
  if (conds.contains('diab')) carb = math.min(carb, (k * 0.4 / 4).round());
  final water = (w * 35 / 250).round() * 250 + (days >= 3 ? 500 : 0);
  return _Goals(k.round(), pr, carb, fat, water);
}

Object? _json(String? raw) {
  if (raw == null || raw.isEmpty) return null;
  try {
    return jsonDecode(raw);
  } catch (_) {
    return null;
  }
}

/// خواردنەکانی ڕۆژێک لە بەشی خواردن (vexfd_v1)
List<FFItem> _fdItems(Object? day) {
  final out = <FFItem>[];
  if (day is! Map) return out;
  final m = day['m'];
  if (m is! Map) return out;
  m.forEach((slot, list) {
    if (list is! List) return;
    for (final e in list) {
      if (e is! Map) continue;
      final n = _s(e['n']);
      if (n.isEmpty) continue;
      final at = _hm(_s(e['at']));
      final s = _slotOk('$slot');
      out.add(FFItem(
        n: n,
        s: s.isEmpty ? _slotAt(at) : s,
        at: at,
        k: math.max(0, _i(e['kcal'])),
        p: math.max(0, _i(e['p'])),
        c: math.max(0, _i(e['c'])),
        f: math.max(0, _i(e['f'])),
        w: _s(e['v']) == 'bad',
      ));
    }
  });
  return out;
}

/// دروستکردنی وێنەی ئەمڕۆی بەکارهێنەر لە هەموو سەرچاوەکانی خواردن و ئاو
Future<FFSnap> ffBuildMine({String uid = '', String name = ''}) async {
  SharedPreferences? sp;
  try {
    sp = await SharedPreferences.getInstance();
  } catch (_) {}
  final now = DateTime.now();
  final key = ffDayKey(now);
  final items = <FFItem>[];
  int water = 0;
  Map? days;
  _Goals? plan;

  // 1) بەشی خواردن (food_design)
  final fd = _json(sp?.getString('vexfd_v1'));
  if (fd is Map) {
    plan = _planFrom(fd['prof']);
    if (fd['days'] is Map) days = fd['days'] as Map;
    final td = days?[key];
    items.addAll(_fdItems(td));
    if (td is Map) water += math.max(0, _i(td['water']));
  }

  // 2) تۆماری سەرەکی (ماڵەوە / سکان / گەڕان)
  final hf = _json(sp?.getString('vexhome-food'));
  if (hf is Map && _s(hf['day']) == Store.today && hf['items'] is List) {
    for (final e in hf['items'] as List) {
      if (e is! Map) continue;
      final n = _s(e['n']);
      if (n.isEmpty) continue;
      final at = _hm(_s(e['at']));
      final s = _slotOk(_s(e['slot']));
      items.add(FFItem(
        n: n,
        e: _s(e['e']) == '🍽️' ? '' : _s(e['e']),
        s: s.isEmpty ? _slotAt(at) : s,
        at: at,
        k: math.max(0, _i(e['kcal'])),
        p: math.max(0, _i(e['p'])),
        c: math.max(0, _i(e['c'])),
        f: math.max(0, _i(e['f'])),
        w: _s(e['v']) == 'bad',
      ));
    }
  }
  final hw = _json(sp?.getString('vexwater'));
  if (hw is Map && _s(hw['day']) == Store.today) water += math.max(0, _i(hw['n']));

  items.sort((a, b) {
    final x = a.at.isEmpty ? '99' : a.at, y = b.at.isEmpty ? '99' : b.at;
    return x.compareTo(y);
  });

  // ئامانجەکان
  final st = Store.I;
  final goal = clampI(plan?.kcal ?? st.h.goal, 800, 6000);
  final pg = plan?.p ?? (goal * 0.25 / 4).round();
  final cg = plan?.c ?? (goal * 0.50 / 4).round();
  final fg = plan?.f ?? (goal * 0.25 / 9).round();
  final wml = plan?.waterMl ?? st.waterGoalMl;
  final wgoal = clampI((wml / Store.glassMl).round(), 6, 12);

  // 7 ڕۆژی کۆتایی (کالۆری)
  final todayK = items.fold<int>(0, (a, x) => a + x.k);
  final week = <int?>[];
  for (int i = 6; i >= 0; i--) {
    if (i == 0) {
      week.add(todayK);
      continue;
    }
    final d = days?[ffDayKey(now.subtract(Duration(days: i)))];
    final its = _fdItems(d);
    week.add(its.isEmpty ? null : its.fold<int>(0, (a, x) => a + x.k));
  }

  return FFSnap(
    uid: uid,
    name: name,
    day: key,
    at: now.millisecondsSinceEpoch,
    goal: goal,
    pg: pg,
    cg: cg,
    fg: fg,
    water: clampI(water, 0, 40),
    wgoal: wgoal,
    items: items.length > 60 ? items.sublist(items.length - 60) : items,
    week: week,
  );
}

// ═════════════════════════════ نموونەی ئەندامە دیمۆکان ═════════════════════════════
// [ناو، kcal، پرۆتین، کاربۆ، چەوری، ئاگاداری]
const List<List<Object>> _kFB = [
  ['هێلکەی کوڵاو ×2', 140, 12, 1, 10, false], ['نانی تەنوور و پەنیر', 250, 9, 36, 7, false],
  ['ماست و خیار', 120, 8, 10, 5, false], ['شیر و هەنگوین', 160, 8, 20, 5, false],
  ['کولیچە', 210, 4, 30, 8, true], ['ئۆتس و میوە', 230, 7, 40, 4, false],
];
const List<List<Object>> _kFL = [
  ['برنج و خۆرشتی بامیە', 520, 22, 70, 16, false], ['دۆلمە', 430, 14, 52, 17, false],
  ['کباب و سەلاتە', 560, 38, 22, 30, false], ['مریشکی برژاو و برنج', 610, 42, 60, 18, false],
  ['شۆربای نیسک', 280, 15, 38, 6, false], ['بریانی', 640, 28, 80, 22, true], ['کوفتە', 480, 24, 40, 24, false],
];
const List<List<Object>> _kFS = [
  ['سێو', 80, 0, 21, 0, false], ['گوێز (مشتێک)', 185, 4, 4, 18, false], ['مۆز', 105, 1, 27, 0, false],
  ['بسکویت', 140, 2, 20, 6, true], ['ماستی کەم چەوری', 100, 6, 12, 3, false], ['شکولاتە', 210, 3, 24, 12, true],
];
const List<List<Object>> _kFD = [
  ['سەلاتەی سەوزە و تونا', 260, 24, 10, 12, false], ['ماست و نان', 230, 10, 34, 6, false],
  ['مریشکی گریل', 350, 40, 3, 18, false], ['شۆربا و نان', 300, 12, 42, 8, false],
  ['پیتزا (١ پارچە)', 290, 12, 34, 11, true], ['ماسی برژاو', 330, 34, 2, 20, false],
];
const Map<String, int> _kDemoAge = {'m1': 58, 'm2': 63, 'm3': 29, 'm4': 31};

int _hash(String s) {
  int h = 7;
  for (final c in s.codeUnits) {
    h = (h * 31 + c) & 0x7fffffff;
  }
  return h;
}

/// تەنها بۆ 4 ئەندامە نموونەییەکەی بازنە (m1…m4) کاتێک سێرڤەر دانەنراوە
FFSnap? _demoSnap(String uid) {
  final age = _kDemoAge[uid];
  if (age == null) return null;
  final now = DateTime.now();
  final hr = now.hour;
  final r = math.Random(_hash('$uid|${ffDayKey(now)}'));
  final goal = age > 55 ? 1800 : (age < 35 ? 2300 : 2000);
  final items = <FFItem>[];
  final meals = <List<Object>>[
    ['b', 7, _kFB, '07:45'],
    ['l', 13, _kFL, '13:20'],
    ['s', 16, _kFS, '16:30'],
    ['d', 20, _kFD, '20:10'],
  ];
  for (final m in meals) {
    final list = m[2] as List<List<Object>>;
    final a = list[r.nextInt(list.length)];
    final b = list[r.nextInt(list.length)];
    final h = m[1] as int;
    if (hr < h + 1 && hr < 22) continue;
    for (final x in [a, if (m[0] != 's' && b != a && (b[1] as int) < 300 && r.nextDouble() > 0.5) b]) {
      items.add(FFItem(
        n: x[0] as String, s: m[0] as String, at: m[3] as String,
        k: x[1] as int, p: x[2] as int, c: x[3] as int, f: x[4] as int, w: x[5] as bool,
      ));
    }
  }
  if (items.isEmpty) {
    final x = _kFB[r.nextInt(_kFB.length)];
    items.add(FFItem(n: x[0] as String, s: 'b', at: '07:45', k: x[1] as int, p: x[2] as int, c: x[3] as int, f: x[4] as int, w: x[5] as bool));
  }
  final wg = age > 60 ? 7 : 8;
  final water = math.min(wg + 2, (hr / 22 * wg).round() + r.nextInt(2));
  final kcal = items.fold<int>(0, (a, x) => a + x.k);
  return FFSnap(
    uid: uid,
    day: ffDayKey(now),
    at: now.subtract(Duration(minutes: 3 + r.nextInt(20))).millisecondsSinceEpoch,
    goal: goal,
    pg: (goal * 0.25 / 4).round(),
    cg: (goal * 0.50 / 4).round(),
    fg: (goal * 0.25 / 9).round(),
    water: water,
    wgoal: wg,
    items: items,
    week: [for (int i = 0; i < 6; i++) (goal * (0.74 + r.nextDouble() * 0.46)).round(), kcal],
    demo: true,
  );
}

// ═════════════════════════════ سێرڤەر ═════════════════════════════
/// ئەنجامی وەرگرتنی داتای هاوڕێیەک
class FFPull {
  const FFPull._(this.kind, [this.snap]);
  const FFPull.ok(FFSnap s) : this._(0, s);
  const FFPull.locked() : this._(1);
  const FFPull.none() : this._(2);
  final int kind; // 0 هەیە · 1 هاوبەشی نەکردووە · 2 هیچ نییە
  final FFSnap? snap;
}

/// پەیوەندی بە سێرڤەرەوە — بۆ Firebase/Supabase کلاسێکی تر لەمە دروست بکە
abstract class FriendFoodBackend {
  /// ناردنی وێنەی ئەمڕۆی من (یان FFSnap.off ئەگەر هاوبەشکردن کوژاوە)
  Future<void> push(FFSnap snap);

  /// وەرگرتنی دوایین وێنەی هاوڕێیەک. هەڵە → Exception (بۆ پیشاندانی «پەیوەندی نییە»)
  Future<FFPull> pull(String uid);

  /// داوای هاوبەشکردن لە هاوڕێیەک
  Future<void> requestShare(String fromUid, String toUid) async {}
}

/// REST/JSON (بڕوانە سەرەتای فایلەکە)
class FFHttpBackend extends FriendFoodBackend {
  FFHttpBackend(String base, {this.token, http.Client? client})
      : base = base.endsWith('/') ? base.substring(0, base.length - 1) : base,
        _c = client ?? http.Client();

  final String base;
  final Future<String?> Function()? token;
  final http.Client _c;
  static const Duration _timeout = Duration(seconds: 12);

  Uri _u(String uid, [String tail = '', Map<String, String>? q]) =>
      Uri.parse('$base/v1/friends/food/${Uri.encodeComponent(uid)}$tail').replace(queryParameters: q);

  Future<Map<String, String>> _h() async {
    final h = <String, String>{'Content-Type': 'application/json; charset=utf-8', 'Accept': 'application/json'};
    try {
      final t = await token?.call();
      if (t != null && t.isNotEmpty) h['Authorization'] = 'Bearer $t';
    } catch (_) {}
    return h;
  }

  @override
  Future<void> push(FFSnap snap) async {
    final r = await _c.put(_u(snap.uid), headers: await _h(), body: jsonEncode(snap.toJson())).timeout(_timeout);
    if (r.statusCode < 200 || r.statusCode >= 300) throw http.ClientException('push ${r.statusCode}');
  }

  @override
  Future<FFPull> pull(String uid) async {
    final r = await _c.get(_u(uid, '', {'day': ffDayKey(DateTime.now())}), headers: await _h()).timeout(_timeout);
    if (r.statusCode == 403) return const FFPull.locked();
    if (r.statusCode == 404 || r.statusCode == 204) return const FFPull.none();
    if (r.statusCode < 200 || r.statusCode >= 300) throw http.ClientException('pull ${r.statusCode}');
    final o = _json(utf8.decode(r.bodyBytes));
    if (o is Map && o['shared'] == false) return const FFPull.locked();
    final s = FFSnap.fromJson(o);
    return s == null ? const FFPull.none() : FFPull.ok(s);
  }

  @override
  Future<void> requestShare(String fromUid, String toUid) async {
    await _c.post(_u(toUid, '/request'), headers: await _h(), body: jsonEncode({'from': fromUid})).timeout(_timeout);
  }
}

/// کۆگای ناوخۆیی (بێ سێرڤەر): وێنەی خۆت + نموونەی ئەندامە دیمۆکان
class FFLocalBackend extends FriendFoodBackend {
  static const String _k = 'vexff_box_v1';

  Future<Map<String, dynamic>> _box(SharedPreferences sp) async {
    final o = _json(sp.getString(_k));
    return o is Map ? Map<String, dynamic>.from(o) : <String, dynamic>{};
  }

  @override
  Future<void> push(FFSnap snap) async {
    final sp = await SharedPreferences.getInstance();
    final b = await _box(sp);
    b[snap.uid] = snap.toJson();
    await sp.setString(_k, jsonEncode(b));
  }

  @override
  Future<FFPull> pull(String uid) async {
    final sp = await SharedPreferences.getInstance();
    final b = await _box(sp);
    final o = b[uid];
    if (o is Map) {
      if (o['shared'] == false) return const FFPull.locked();
      final s = FFSnap.fromJson(o);
      if (s != null) return FFPull.ok(s);
    }
    final d = _demoSnap(uid);
    return d == null ? const FFPull.none() : FFPull.ok(d);
  }
}

// ═════════════════════════════ ناوەند (Hub) ═════════════════════════════
enum FFStatus { idle, loading, ok, locked, none, error }

class FriendFood extends ChangeNotifier with WidgetsBindingObserver {
  FriendFood._();
  static final FriendFood I = FriendFood._();

  static const String _kCache = 'vexff_cache_v1';
  static const String _kLinks = 'vexff_links_v1';
  static const String _kUid = 'vexff_uid';
  static const String _kPushed = 'vexff_pushed_v1';
  static const Duration pollEvery = Duration(seconds: 20);

  FriendFoodBackend backend = FFLocalBackend();

  /// وێنەی ئەمڕۆی من (بۆ پێشبینین)
  FFSnap? mine;

  final Map<String, FFSnap> _cache = {};
  final Map<String, FFStatus> _st = {};
  final Map<String, int> _watch = {};
  final Map<String, String> _links = {};
  final Map<String, String> _names = {};
  final Map<String, int> _fresh = {}; // uid → کاتی دوایین ژەمی نوێ (ms)
  final Map<String, int> _asked = {};
  final Set<String> _busy = {};

  SharedPreferences? _sp;
  Timer? _tick, _poll, _deb, _saveT;
  Object? _rFd, _rHf, _rHw;
  String _day = '';
  String _uid = '';
  bool _uidFixed = false;
  String _lastPush = '';
  bool? _lastShare;
  bool _pubBusy = false, _pubAgain = false, _pending = false;
  int _retryN = 0;
  Future<void>? _initF;
  bool _ready = false;

  bool get ready => _ready;
  bool get serverOn => backend is! FFLocalBackend;
  bool get sharing => FamilyStore.I.share['food'] ?? false;

  /// uid ـی من لای سێرڤەر
  String get myUid {
    if (_uidFixed && _uid.isNotEmpty) return _uid;
    final u = Account.I.user;
    final e = _s(u?['email']).toLowerCase();
    if (e.contains('@')) return 'e:$e';
    final ph = _s(u?['phone']).replaceAll(RegExp(r'[^0-9+]'), '');
    if (ph.length >= 6) return 'p:$ph';
    return _uid;
  }

  /// دەستپێکردن (لە main.dart). دووبارە بانگکردنی سەلامەتە.
  Future<void> init({String? baseUrl, Future<String?> Function()? token, FriendFoodBackend? custom, String? uid}) {
    if (custom != null) {
      backend = custom;
    } else if (baseUrl != null && baseUrl.trim().isNotEmpty && !serverOn) {
      backend = FFHttpBackend(baseUrl.trim(), token: token);
    }
    if (uid != null && uid.trim().isNotEmpty) {
      _uid = uid.trim();
      _uidFixed = true;
    }
    return _initF ??= _init();
  }

  Future<void> _init() async {
    try {
      _sp = await SharedPreferences.getInstance();
    } catch (_) {}
    final sp = _sp;
    if (sp != null) {
      if (!_uidFixed) {
        _uid = sp.getString(_kUid) ?? '';
        if (_uid.isEmpty) {
          final r = math.Random();
          const ch = 'abcdefghijkmnpqrstuvwxyz23456789';
          _uid = 'vx_${List.generate(12, (_) => ch[r.nextInt(ch.length)]).join()}';
          await sp.setString(_kUid, _uid);
        }
      }
      final c = _json(sp.getString(_kCache));
      if (c is Map) {
        c.forEach((k, v) {
          final s = FFSnap.fromJson(v);
          if (s != null) _cache['$k'] = s;
        });
      }
      final l = _json(sp.getString(_kLinks));
      if (l is Map) l.forEach((k, v) => _links['$k'] = '$v');
      _lastPush = sp.getString(_kPushed) ?? '';
      _rFd = sp.getString('vexfd_v1');
      _rHf = sp.getString('vexhome-food');
      _rHw = sp.getString('vexwater');
    }
    if (_uid.isEmpty) _uid = 'vx_${DateTime.now().millisecondsSinceEpoch}';
    _day = ffDayKey(DateTime.now());
    _lastShare = sharing;
    Store.I.addListener(_schedule);
    FamilyStore.I.addListener(_onFamily);
    try {
      WidgetsBinding.instance.addObserver(this);
    } catch (_) {}
    _tick = Timer.periodic(const Duration(seconds: 3), (_) => _check());
    _ready = true;
    unawaited(_publish()); // دەستپێکردنی ئەپ چاوەڕێی سێرڤەر ناکات
  }

  /// وەستاندن و پاککردنەوە (چوونە دەرەوە لە هەژمار یان تاقیکردنەوە)
  void shutdown() {
    _tick?.cancel();
    _poll?.cancel();
    _deb?.cancel();
    _saveT?.cancel();
    _tick = _poll = _deb = _saveT = null;
    Store.I.removeListener(_schedule);
    FamilyStore.I.removeListener(_onFamily);
    try {
      WidgetsBinding.instance.removeObserver(this);
    } catch (_) {}
    _watch.clear();
    _cache.clear();
    _st.clear();
    _fresh.clear();
    _busy.clear();
    mine = null;
    _initF = null;
    _ready = false;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _check(force: true);
      for (final u in _watch.keys.toList()) {
        _refresh(u);
      }
    }
  }

  // ---------- ئەمڕۆی من ----------
  void _onFamily() {
    final s = sharing;
    if (s != _lastShare) {
      _lastShare = s;
      _deb?.cancel();
      _publish(force: true);
    }
  }

  /// گۆڕانکاری لە بەشی خواردن/ئاو (هەر 3 چرکە پشکنین؛ بێ خوێندنەوەی دیسک)
  void _check({bool force = false}) {
    final sp = _sp;
    if (sp == null) return;
    final d = ffDayKey(DateTime.now());
    final a = sp.getString('vexfd_v1'), b = sp.getString('vexhome-food'), c = sp.getString('vexwater');
    if (force || d != _day || !identical(a, _rFd) || !identical(b, _rHf) || !identical(c, _rHw)) {
      _rFd = a;
      _rHf = b;
      _rHw = c;
      _day = d;
      _schedule();
    } else if (_pending && ++_retryN >= 10) {
      _retryN = 0;
      _publish(force: true);
    }
  }

  void _schedule() {
    if (!_ready) return;
    _deb?.cancel();
    _deb = Timer(const Duration(milliseconds: 700), () => _publish());
  }

  /// ئێستا وێنەکە دروست بکە و بینێرە
  Future<void> publishNow() => _publish(force: true);

  Future<void> _publish({bool force = false}) async {
    if (_pubBusy) {
      _pubAgain = true;
      return;
    }
    _pubBusy = true;
    try {
      final uid = myUid;
      final nm = _s(Account.I.user?['name']);
      final snap = await ffBuildMine(uid: uid, name: nm);
      mine = snap;
      notifyListeners();
      final payload = sharing ? snap : FFSnap.off(uid, snap.day);
      final m = payload.toJson()..remove('at');
      final sig = jsonEncode(m);
      if (force || sig != _lastPush) {
        try {
          await backend.push(payload);
          _lastPush = sig;
          _pending = false;
          _sp?.setString(_kPushed, sig);
        } catch (_) {
          _pending = true; // دووبارە هەوڵدەدرێتەوە (~30 چرکە)
        }
      }
    } catch (_) {
      // هیچ کاتێک ئەپەکە ناوەستێت
    } finally {
      _pubBusy = false;
    }
    if (_pubAgain) {
      _pubAgain = false;
      await _publish();
    }
  }

  // ---------- هاوڕێکان ----------
  String uidOf(FMember m) => _links[m.id] ?? m.id;

  /// بەستنەوەی ئەندامێک بە uid ـی سێرڤەر
  void link(String memberId, String uid) {
    if (uid.trim().isEmpty) return;
    _links[memberId] = uid.trim();
    _sp?.setString(_kLinks, jsonEncode(_links));
    notifyListeners();
  }

  FFSnap? snapOf(FMember m) => _cache[uidOf(m)];
  FFStatus statusOf(FMember m) => _st[uidOf(m)] ?? FFStatus.idle;
  bool askedRecently(FMember m) {
    final t = _asked[uidOf(m)];
    return t != null && DateTime.now().millisecondsSinceEpoch - t < 10 * 60 * 1000;
  }

  /// ژەمی نوێ لە 3 خولەکی ڕابردوودا؟
  bool isFresh(FMember m) {
    final t = _fresh[uidOf(m)];
    return t != null && DateTime.now().millisecondsSinceEpoch - t < 3 * 60 * 1000;
  }

  void watch(FMember m) {
    final u = uidOf(m);
    _names[u] = m.n;
    _watch[u] = (_watch[u] ?? 0) + 1;
    _refresh(u);
    _poll ??= Timer.periodic(pollEvery, (_) {
      for (final x in _watch.keys.toList()) {
        _refresh(x);
      }
    });
  }

  void unwatch(FMember m) {
    final u = uidOf(m);
    final n = (_watch[u] ?? 1) - 1;
    if (n <= 0) {
      _watch.remove(u);
    } else {
      _watch[u] = n;
    }
    if (_watch.isEmpty) {
      _poll?.cancel();
      _poll = null;
    }
  }

  Future<void> refresh(FMember m) {
    _names[uidOf(m)] = m.n;
    return _refresh(uidOf(m));
  }

  Future<void> _refresh(String uid) async {
    if (_busy.contains(uid)) return;
    _busy.add(uid);
    if (_cache[uid] == null) {
      _st[uid] = FFStatus.loading;
      notifyListeners();
    }
    try {
      if (!_ready) await init();
      final r = await backend.pull(uid);
      if (r.kind == 0 && r.snap != null) {
        _apply(uid, r.snap!);
      } else if (r.kind == 1) {
        _st[uid] = FFStatus.locked;
        _cache.remove(uid);
        _saveCache();
      } else {
        _st[uid] = FFStatus.none;
      }
    } catch (_) {
      _st[uid] = FFStatus.error;
    } finally {
      _busy.remove(uid);
      notifyListeners();
    }
  }

  /// داتای نوێی هاوڕێیەک (لە Push / WebSocket / Firebase): FriendFood.I.receive(json)
  void receive(Object? json) {
    final s = FFSnap.fromJson(json);
    if (s == null || s.uid.isEmpty) return;
    if (!s.shared) {
      _st[s.uid] = FFStatus.locked;
      _cache.remove(s.uid);
      _saveCache();
    } else {
      _apply(s.uid, s);
    }
    notifyListeners();
  }

  void _apply(String uid, FFSnap s) {
    final old = _cache[uid];
    if (!s.shared) {
      _st[uid] = FFStatus.locked;
      return;
    }
    _st[uid] = FFStatus.ok;
    // ئاگادارکردنەوەی ژەم/ئاوی نوێ (تەنها کاتێک پێشتر داتامان هەبوو)
    if (old != null && old.day == s.day && s.isToday && old.shared) {
      final name = _names[uid] ?? (s.name.isNotEmpty ? s.name : '');
      if (s.items.length > old.items.length && s.items.isNotEmpty) {
        _fresh[uid] = DateTime.now().millisecondsSinceEpoch;
        final last = s.items.last;
        _toast(_tf('nMeal', {'n': name, 'm': last.n, 'k': fmt(last.k)}));
      } else if (s.water > old.water) {
        _toast(_tf('nWater', {'n': name}));
      }
    }
    _cache[uid] = s;
    _saveCache();
  }

  void _toast(String m) {
    try {
      if (navKey.currentContext != null) toast(m);
    } catch (_) {}
  }

  void _saveCache() {
    _saveT?.cancel();
    _saveT = Timer(const Duration(milliseconds: 600), () {
      final sp = _sp;
      if (sp == null) return;
      final cut = ffDayKey(DateTime.now().subtract(const Duration(days: 2)));
      _cache.removeWhere((k, v) => v.day.compareTo(cut) < 0);
      sp.setString(_kCache, jsonEncode(_cache.map((k, v) => MapEntry(k, v.toJson()))));
    });
  }

  /// داوای هاوبەشکردن
  Future<void> askShare(FMember m) async {
    final u = uidOf(m);
    _asked[u] = DateTime.now().millisecondsSinceEpoch;
    notifyListeners();
    _toast(_tf('asked', {'n': m.n}));
    try {
      await backend.requestShare(myUid, u);
    } catch (_) {}
  }
}

// ═════════════════════════════ کارتی خواردنی هاوڕێ ═════════════════════════════
const Cubic _kEase = Cubic(0.2, 0.9, 0.2, 1.0);
const Color _kG = Color(0xFF3CF08A), _kY = Color(0xFFFFBE4D), _kR = Color(0xFFFF5F7E);
const Color _kProt = Color(0xFF6AA8FF), _kCarb = Color(0xFFFFBE4D), _kFat = Color(0xFFFF8FC8);

/// کارتی «ئەمڕۆ چی خواردووە» بۆ ئەندامێکی بازنە.  FriendFoodCard.me() ← ئەوەی بازنەکەت دەیبینن
class FriendFoodCard extends StatefulWidget {
  const FriendFoodCard({super.key, required FMember this.member});
  const FriendFoodCard.me({super.key}) : member = null;

  final FMember? member;

  @override
  State<FriendFoodCard> createState() => _FriendFoodCardState();
}

class _FriendFoodCardState extends State<FriendFoodCard> {
  FMember? _watched;
  bool _alive = true;

  @override
  void initState() {
    super.initState();
    // دوای یەکەم فرەیم، بۆ ئەوەی notifyListeners لەناو build نەبێت
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_alive) _start();
    });
  }

  Future<void> _start() async {
    final hub = FriendFood.I;
    final m = widget.member;
    if (m != null && _watched == null) {
      hub.watch(m);
      _watched = m;
    }
    await hub.init();
    if (!_alive) return;
    if (m == null) hub.publishNow();
  }

  @override
  void didUpdateWidget(covariant FriendFoodCard old) {
    super.didUpdateWidget(old);
    if (old.member?.id != widget.member?.id) {
      final w = _watched;
      if (w != null) FriendFood.I.unwatch(w);
      _watched = null;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_alive) _start();
      });
    }
  }

  @override
  void dispose() {
    _alive = false;
    final w = _watched;
    if (w != null) FriendFood.I.unwatch(w);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([FriendFood.I, VexTheme.I, LangState.I]),
      builder: (context, _) => Directionality(
        textDirection: _dir,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 320),
          switchInCurve: _kEase,
          transitionBuilder: (c, a) => FadeTransition(
            opacity: a,
            child: SizeTransition(sizeFactor: a, axisAlignment: -1, child: c),
          ),
          child: _body(),
        ),
      ),
    );
  }

  Widget _body() {
    final hub = FriendFood.I;
    final m = widget.member;
    if (m == null) {
      final s = hub.mine;
      if (s == null) return const _FFLoading(key: ValueKey('ld'));
      if (!s.hasData) {
        return _FFInfo(key: const ValueKey('nm'), emoji: '🍽️', title: _t('noneMe'), sub: _t('noneMeS'));
      }
      return _FFView(key: const ValueKey('me'), snap: s, mine: true);
    }
    final st = hub.statusOf(m);
    final s = hub.snapOf(m);
    final name = m.n;
    if (st == FFStatus.locked || (s != null && !s.shared)) {
      final asked = hub.askedRecently(m);
      return _FFInfo(
        key: const ValueKey('lk'),
        emoji: '🔒',
        title: _tf('lock', {'n': name}),
        sub: _tf('lockS', {'n': name}),
        action: asked ? _tf('asked', {'n': name}) : _t('ask'),
        onAction: asked ? null : () => hub.askShare(m),
      );
    }
    if (s != null && s.isToday && s.hasData) {
      return _FFView(
        key: const ValueKey('ok'),
        snap: s,
        fresh: hub.isFresh(m),
        offline: st == FFStatus.error,
        onRefresh: () => hub.refresh(m),
      );
    }
    switch (st) {
      case FFStatus.idle:
      case FFStatus.loading:
        return const _FFLoading(key: ValueKey('ld'));
      case FFStatus.error:
        return _FFInfo(
          key: const ValueKey('er'),
          emoji: '📡',
          title: _t('err'),
          sub: _t('off'),
          action: _t('retry'),
          onAction: () => hub.refresh(m),
        );
      default:
        return _FFInfo(
          key: const ValueKey('no'),
          emoji: '🍽️',
          title: _t('none'),
          sub: _tf('noneS', {'n': name}),
          action: hub.askedRecently(m) ? null : _t('ask'),
          onAction: hub.askedRecently(m) ? null : () => hub.askShare(m),
        );
    }
  }
}

/// دیزاینی دەرەوەی کارتەکە (هەمان .fd ی وێبەکە)
BoxDecoration _shellDeco() {
  final light = VexTheme.I.isLight;
  return BoxDecoration(
    borderRadius: BorderRadius.circular(22),
    border: Border.all(color: V.line2),
    gradient: LinearGradient(
      begin: AlignmentDirectional.topStart,
      end: AlignmentDirectional.bottomEnd,
      colors: [
        Color.alphaBlend(op(_kG, light ? 0.08 : 0.10), V.surf2),
        Color.alphaBlend(op(V.cy, light ? 0.05 : 0.06), V.surf2),
      ],
    ),
  );
}

class _FFLoading extends StatelessWidget {
  const _FFLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 22),
      decoration: _shellDeco(),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2.4, color: V.cy, backgroundColor: V.track),
          ),
          const SizedBox(width: 10),
          Flexible(child: Text(_t('load'), style: ku(12.5, w: FontWeight.w700, c: V.mu))),
        ],
      ),
    );
  }
}

/// کارتی زانیاری (هاوبەش نەکراوە / هیچ نییە / هەڵە)
class _FFInfo extends StatelessWidget {
  const _FFInfo({super.key, required this.emoji, required this.title, required this.sub, this.action, this.onAction});
  final String emoji, title, sub;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
      decoration: _shellDeco(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('🍽️ ${_t('head')}', style: ku(15, w: FontWeight.w800)),
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 56,
              height: 56,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: op(V.cy, 0.10),
                border: Border.all(color: op(V.cy, 0.35)),
              ),
              child: Text(emoji, style: const TextStyle(fontSize: 26)),
            ),
          ),
          const SizedBox(height: 10),
          Text(title, textAlign: TextAlign.center, style: ku(14, w: FontWeight.w800, h: 1.6)),
          const SizedBox(height: 4),
          Text(sub, textAlign: TextAlign.center, style: ku(12, w: FontWeight.w600, c: V.mu, h: 1.75)),
          if (action != null) ...[
            const SizedBox(height: 12),
            Center(
              child: Press(
                onTap: onAction,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(99),
                    color: onAction == null ? V.surf2 : op(V.cy, 0.14),
                    border: Border.all(color: onAction == null ? V.line : op(V.cy, 0.5)),
                  ),
                  child: Text(
                    action!,
                    textAlign: TextAlign.center,
                    style: ku(12.5, w: FontWeight.w800, c: onAction == null ? V.mu : _ink(V.cy)),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// گرووپی ژەم
class _Grp {
  _Grp(this.s);
  final String s;
  final List<FFItem> items = [];
  String at = '';
  int k = 0;
  String e = '';
}

List<_Grp> _groups(FFSnap s) {
  final map = <String, _Grp>{};
  for (final it in s.items) {
    final g = map.putIfAbsent(it.s, () => _Grp(it.s));
    g.items.add(it);
    g.k += it.k;
    if (it.at.isNotEmpty && (g.at.isEmpty || it.at.compareTo(g.at) < 0)) g.at = it.at;
    if (g.e.isEmpty && it.e.isNotEmpty) g.e = it.e;
  }
  final out = map.values.toList();
  out.sort((a, b) {
    final x = a.at.isEmpty ? '${_kSlots.indexOf(a.s)}' : a.at;
    final y = b.at.isEmpty ? '${_kSlots.indexOf(b.s)}' : b.at;
    return x.compareTo(y);
  });
  return out;
}

String _ago(int ms) {
  final d = DateTime.now().millisecondsSinceEpoch - ms;
  final m = (d / 60000).floor();
  if (m < 1) return _t('now');
  if (m < 60) return _tf('min', {'n': m});
  return _tf('hr', {'n': (m / 60).floor()});
}

/// کارتی تەواو
class _FFView extends StatelessWidget {
  const _FFView({super.key, required this.snap, this.mine = false, this.fresh = false, this.offline = false, this.onRefresh});
  final FFSnap snap;
  final bool mine, fresh, offline;
  final VoidCallback? onRefresh;

  @override
  Widget build(BuildContext context) {
    final s = snap;
    final ev = _eval(s);
    final kc = ev.sc >= 85 ? _kG : (ev.sc >= 70 ? _kY : _kR);
    final s3 = _tl('s3');
    final lab = s3.length == 3 ? s3[ev.sc >= 85 ? 0 : (ev.sc >= 70 ? 1 : 2)] : '';
    final pc = s.goal <= 0 ? 0.0 : math.min(s.kcal / s.goal, 1.0);
    final rk = s.kcal > s.goal ? _kR : (pc > 0.85 ? _kY : _kG);
    final groups = _groups(s);
    final mac = _tl('mac');
    final light = VexTheme.I.isLight;

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(14),
      decoration: _shellDeco(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // سەردێڕ + خاڵ
          Row(
            children: [
              Expanded(
                child: Text(
                  '🍽️ ${mine ? _t('mine') : _t('title')}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: ku(15, w: FontWeight.w800),
                ),
              ),
              if (s.demo) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(color: V.surf2, borderRadius: BorderRadius.circular(99), border: Border.all(color: V.line)),
                  child: Text(_t('demo'), style: ku(9.5, w: FontWeight.w800, c: V.mu)),
                ),
                const SizedBox(width: 6),
              ],
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(99),
                  color: op(kc, 0.16),
                  border: Border.all(color: op(kc, 0.5)),
                ),
                child: Text.rich(
                  TextSpan(children: [
                    const TextSpan(text: '⭐ '),
                    TextSpan(text: '${ev.sc}', style: nu(11.5, c: _ink(kc))),
                    TextSpan(text: ' · $lab'),
                  ]),
                  style: ku(11.5, w: FontWeight.w800, c: _ink(kc)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // ڕینگ + ماکرۆ
          Row(
            children: [
              _KcalRing(frac: pc, color: rk, kcal: s.kcal, goal: s.goal),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  children: [
                    _MacroBar(label: mac.isNotEmpty ? mac[0] : 'P', g: s.p, goal: s.pg, color: _kProt),
                    const SizedBox(height: 9),
                    _MacroBar(label: mac.length > 1 ? mac[1] : 'C', g: s.c, goal: s.cg, color: _kCarb),
                    const SizedBox(height: 9),
                    _MacroBar(label: mac.length > 2 ? mac[2] : 'F', g: s.f, goal: s.fg, color: _kFat),
                  ],
                ),
              ),
            ],
          ),
          // ژەمەکان
          if (groups.isNotEmpty) ...[
            const SizedBox(height: 14),
            for (int i = 0; i < groups.length; i++) ...[
              if (i > 0) const SizedBox(height: 8),
              _MealRow(g: groups[i], fresh: fresh && i == groups.length - 1),
            ],
          ],
          const SizedBox(height: 12),
          _WaterBox(water: s.water, goal: s.wgoal),
          if (s.week.where((x) => x != null).length >= 2) _WeekBox(week: s.week, goal: s.goal),
          // ئامۆژگاری
          Container(
            margin: const EdgeInsets.only(top: 12),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: op(kc, light ? 0.12 : 0.10),
              border: Border.all(color: op(kc, 0.35)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(ev.sc >= 85 ? '✅' : '💡', style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 10),
                Expanded(child: Text(_t(ev.tip), style: ku(12.5, w: FontWeight.w700, h: 1.75))),
              ],
            ),
          ),
          // خوارەوە: ڕاستەوخۆ + کاتی نوێکردنەوە
          const SizedBox(height: 10),
          Row(
            children: [
              if (!offline) ...[
                const _LiveDot(),
                const SizedBox(width: 6),
                Text(_t('live'), style: ku(11, w: FontWeight.w800, c: _ink(_kG))),
                Text('  ·  ', style: ku(11, c: V.mu)),
              ] else ...[
                Text('📡 ', style: ku(11, c: V.mu)),
              ],
              Expanded(
                child: Text(
                  offline ? _t('off') : _tf('upd', {'t': _ago(s.at)}),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: ku(11, w: FontWeight.w600, c: V.mu, h: 1.5),
                ),
              ),
              if (onRefresh != null)
                Press(
                  onTap: onRefresh,
                  child: Container(
                    width: 32,
                    height: 32,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: V.surf2, border: Border.all(color: V.line)),
                    child: Icon(Icons.refresh_rounded, size: 18, color: V.mu),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LiveDot extends StatefulWidget {
  const _LiveDot();
  @override
  State<_LiveDot> createState() => _LiveDotState();
}

class _LiveDotState extends State<_LiveDot> with SingleTickerProviderStateMixin {
  late final AnimationController _a = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat(reverse: true);

  @override
  void dispose() {
    _a.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _a,
      builder: (context, _) => Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _kG,
          boxShadow: [BoxShadow(color: op(_kG, 0.25 + 0.5 * _a.value), blurRadius: 4 + 6 * _a.value, spreadRadius: 1)],
        ),
      ),
    );
  }
}

// ---------- ڕینگی کالۆری ----------
class _KcalRing extends StatelessWidget {
  const _KcalRing({required this.frac, required this.color, required this.kcal, required this.goal});
  final double frac;
  final Color color;
  final int kcal, goal;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 92,
      height: 92,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: frac.isFinite ? frac.clamp(0.0, 1.0).toDouble() : 0.0),
              duration: const Duration(milliseconds: 1200),
              curve: _kEase,
              builder: (context, v, _) => CustomPaint(painter: _RingP(v, color, V.track)),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FittedBox(fit: BoxFit.scaleDown, child: Text(fmt(kcal), style: nu(19, h: 1.15))),
              Text(
                _tf('of', {'g': _iso(fmt(goal))}),
                style: ku(10, w: FontWeight.w700, c: V.mu, h: 1.2),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RingP extends CustomPainter {
  _RingP(this.v, this.c, this.track);
  final double v;
  final Color c, track;

  @override
  void paint(Canvas canvas, Size size) {
    final sc = size.width / 92;
    final r = 38 * sc;
    final o = Offset(size.width / 2, size.height / 2);
    final rect = Rect.fromCircle(center: o, radius: r);
    canvas.drawCircle(o, r, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9 * sc
      ..color = track);
    if (v <= 0.001) return;
    final sweep = 2 * math.pi * v;
    canvas.drawArc(rect, -math.pi / 2, sweep, false, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9 * sc
      ..strokeCap = StrokeCap.round
      ..color = op(c, 0.55)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 4 * sc));
    canvas.drawArc(rect, -math.pi / 2, sweep, false, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9 * sc
      ..strokeCap = StrokeCap.round
      ..color = c);
  }

  @override
  bool shouldRepaint(_RingP o) => o.v != v || o.c != c || o.track != track;
}

// ---------- هێڵی ماکرۆ ----------
class _MacroBar extends StatelessWidget {
  const _MacroBar({required this.label, required this.g, required this.goal, required this.color});
  final String label;
  final int g, goal;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final f = goal <= 0 ? 0.0 : (g / goal).clamp(0.0, 1.0).toDouble();
    return Row(
      children: [
        SizedBox(
          width: 58,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: Text(label, style: ku(11.5, w: FontWeight.w800)),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(9),
            child: Container(
              height: 8,
              color: V.track,
              alignment: AlignmentDirectional.centerStart,
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: f),
                duration: const Duration(milliseconds: 1100),
                curve: _kEase,
                builder: (context, v, _) => FractionallySizedBox(
                  widthFactor: v,
                  heightFactor: 1,
                  child: DecoratedBox(
                    decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(9)),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 44,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerEnd,
            child: Text('${g}g', textDirection: TextDirection.ltr, style: nu(11.5, c: V.mu)),
          ),
        ),
      ],
    );
  }
}

// ---------- ژەم ----------
class _MealRow extends StatelessWidget {
  const _MealRow({required this.g, this.fresh = false});
  final _Grp g;
  final bool fresh;

  @override
  Widget build(BuildContext context) {
    final col = Color(_kSlotC[g.s] ?? 0xFF3CF08A);
    final names = g.items.map((x) => x.w ? '${x.n} ⚠️' : x.n).join(' · ');
    return AnimatedContainer(
      duration: const Duration(milliseconds: 600),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: V.surf2,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: fresh ? op(col, 0.8) : V.line, width: fresh ? 1.4 : 1),
        boxShadow: fresh ? [BoxShadow(color: op(col, 0.28), blurRadius: 14)] : null,
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: op(col, 0.18),
              border: Border.all(color: op(col, 0.45)),
            ),
            child: Text(g.e.isNotEmpty ? g.e : (_kSlotE[g.s] ?? '🍽️'), style: const TextStyle(fontSize: 19)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(
                  TextSpan(children: [
                    TextSpan(text: _t('m${g.s}')),
                    if (g.at.isNotEmpty) ...[
                      const TextSpan(text: ' · '),
                      TextSpan(text: _iso(g.at), style: nu(11.5, w: FontWeight.w600, c: V.mu)),
                    ],
                  ]),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: ku(12.5, w: FontWeight.w800),
                ),
                Text(
                  names,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: ku(11.5, w: FontWeight.w600, c: V.mu, h: 1.6),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(fmt(g.k), style: nu(14)),
              Text('kcal', style: nu(9.5, w: FontWeight.w600, c: V.mu)),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------- ئاو ----------
class _WaterBox extends StatefulWidget {
  const _WaterBox({required this.water, required this.goal});
  final int water, goal;

  @override
  State<_WaterBox> createState() => _WaterBoxState();
}

class _WaterBoxState extends State<_WaterBox> with TickerProviderStateMixin {
  static const Cubic _fillCurve = Cubic(0.2, 0.9, 0.3, 1.0);
  late final AnimationController _wave =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat(reverse: true);
  late AnimationController _fill;
  int _from = 0;

  int get _n => math.max(widget.goal, widget.water);

  AnimationController _mk() => AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 900 + 70 * math.max(0, widget.water - _from)),
      )..forward();

  @override
  void initState() {
    super.initState();
    _fill = _mk();
  }

  @override
  void didUpdateWidget(covariant _WaterBox old) {
    super.didUpdateWidget(old);
    if (old.water != widget.water) {
      _from = math.min(old.water, widget.water);
      _fill.dispose();
      _fill = _mk();
    }
  }

  @override
  void dispose() {
    _wave.dispose();
    _fill.dispose();
    super.dispose();
  }

  double _tOf(int i) {
    if (i < _from) return 1;
    final total = _fill.duration!.inMilliseconds.toDouble();
    final ms = _fill.value * total - (i - _from) * 70;
    return _fillCurve.transform((ms / 900).clamp(0.0, 1.0).toDouble());
  }

  @override
  Widget build(BuildContext context) {
    final w = widget.water, g = widget.goal;
    final ex = math.max(0, w - g), done = w >= g, left = math.max(0, g - w);
    final ml = w * Store.glassMl;
    final light = VexTheme.I.isLight;
    final gold = light ? const Color(0xFFB7791F) : _kY;
    final blue = light ? const Color(0xFF1F6FD1) : const Color(0xFF8FD4FF);
    var lit = (ml / 1000).toStringAsFixed(2);
    if (lit.endsWith('0')) lit = lit.substring(0, lit.length - 1);
    if (lit.endsWith('.0')) lit = lit.substring(0, lit.length - 2);

    final glParts = _tf('gl', {'a': '\u0000', 'b': _iso('$g')}).split('\u0000');
    final glPre = glParts.first, glPost = glParts.length > 1 ? glParts.last : '';
    final Widget pill;
    if (ex > 0) {
      pill = _pill(_tf('wEx', {'n': ex}), op(_kY, 0.18), gold);
    } else if (done) {
      pill = _pill(_t('wDone'), op(_kG, 0.14), _ink(V.mint));
    } else {
      pill = _pill(_tf('wLeft', {'n': left}), op(V.tx, 0.07), V.mu);
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: op(const Color(0xFF2FA0FF), 0.35)),
        gradient: LinearGradient(
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
          colors: [op(const Color(0xFF2FA0FF), light ? 0.10 : 0.14), op(const Color(0xFF2FE6F3), 0.05)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: Text('💧 ${_t('water')}', maxLines: 1, overflow: TextOverflow.ellipsis, style: ku(13, w: FontWeight.w800))),
              const SizedBox(width: 8),
              Flexible(child: pill),
            ],
          ),
          const SizedBox(height: 10),
          Directionality(
            textDirection: TextDirection.ltr,
            child: AnimatedBuilder(
              animation: Listenable.merge([_fill, _wave]),
              builder: (context, _) => Wrap(
                spacing: 5,
                runSpacing: 6,
                children: [
                  for (int i = 0; i < _n; i++)
                    SizedBox(
                      width: 30,
                      height: 37,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Positioned.fill(
                            child: CustomPaint(
                              painter: _GlassP(
                                fill: i < w ? _tOf(i) : 0,
                                extra: i >= g,
                                wave: _wave.value,
                                light: light,
                              ),
                            ),
                          ),
                          if (i >= g)
                            Positioned(
                              top: -7,
                              right: -3,
                              child: Text('★', style: TextStyle(fontSize: 10, color: gold, shadows: [Shadow(color: op(_kY, 0.9), blurRadius: 6)])),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(text: glPre),
                      TextSpan(text: _iso('$w'), style: nu(14, c: V.tx)),
                      TextSpan(text: glPost),
                    ],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: ku(11.5, w: FontWeight.w700, c: V.mu),
                ),
              ),
              Text('$lit L · ${fmt(ml)} ml', textDirection: TextDirection.ltr, style: nu(11, w: FontWeight.w700, c: V.mu)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(9),
            child: Container(
              height: 5,
              color: V.track,
              alignment: AlignmentDirectional.centerStart,
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: g <= 0 ? 0.0 : math.min(1.0, w / g)),
                duration: const Duration(milliseconds: 1000),
                curve: _kEase,
                builder: (context, v, _) => FractionallySizedBox(
                  widthFactor: v,
                  heightFactor: 1,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(9),
                      gradient: LinearGradient(colors: [blue, done ? _kG : const Color(0xFF2F8CFF)]),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _pill(String t, Color bg, Color fg) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(99)),
        child: Text(t, maxLines: 1, overflow: TextOverflow.ellipsis, style: ku(11, w: FontWeight.w800, c: fg)),
      );
}

/// پەرداخی ئاو (هەمان SVG ـی وێبەکە: viewBox 34×42)
class _GlassP extends CustomPainter {
  _GlassP({required this.fill, required this.extra, required this.wave, required this.light});
  final double fill, wave;
  final bool extra, light;

  static Path _glass() => Path()
    ..moveTo(6, 4)
    ..lineTo(28, 4)
    ..lineTo(25.4, 34.2)
    ..arcToPoint(const Offset(22.2, 37.1), radius: const Radius.circular(3.2))
    ..lineTo(11.8, 37.1)
    ..arcToPoint(const Offset(8.6, 34.2), radius: const Radius.circular(3.2))
    ..close();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 34, size.height / 42);
    final g = _glass();
    final on = fill > 0.001;
    if (on) {
      canvas.drawPath(
        g.shift(const Offset(0, 2.5)),
        Paint()
          ..color = extra ? const Color(0x73FFAA3C) : const Color(0x612F8CFF)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      );
    }
    canvas.drawPath(g, Paint()..color = light ? const Color(0x142F8CFF) : const Color(0x0DFFFFFF));
    if (on) {
      canvas.save();
      canvas.clipPath(g);
      final top = 39 - 26 * fill;
      final grad = extra
          ? const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFFFE08A), Color(0xFFFF9F43)])
          : const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF8FE8FF), Color(0xFF2F8CFF)]);
      final r = Rect.fromLTWH(0, top, 34, 39 - top + 3);
      canvas.drawRect(r, Paint()..shader = grad.createShader(Rect.fromLTWH(0, 13, 34, 26)));
      final dx = -4 * wave;
      final y = top;
      final w = Path()
        ..moveTo(4 + dx, y)
        ..quadraticBezierTo(8.2 + dx, y - 3, 12.5 + dx, y)
        ..quadraticBezierTo(16.8 + dx, y + 3, 21 + dx, y)
        ..quadraticBezierTo(25.2 + dx, y - 3, 29.5 + dx, y)
        ..quadraticBezierTo(33.8 + dx, y + 3, 38 + dx, y)
        ..lineTo(38 + dx, y + 3)
        ..lineTo(4 + dx, y + 3)
        ..close();
      canvas.drawPath(w, Paint()..color = const Color(0x59FFFFFF));
      canvas.restore();
    }
    final Color stroke;
    if (light) {
      stroke = on ? (extra ? const Color(0xFFE08A1E) : const Color(0xFF2F8CFF)) : const Color(0x732F8CFF);
    } else {
      stroke = on ? (extra ? const Color(0xFFFFE29A) : const Color(0xFFBFF0FF)) : const Color(0x8CBEEBFF);
    }
    canvas.drawPath(
      g,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8
        ..strokeJoin = StrokeJoin.round
        ..color = stroke,
    );
    canvas.drawLine(
      const Offset(10, 9),
      const Offset(11.6, 29),
      Paint()
        ..strokeWidth = 1.6
        ..strokeCap = StrokeCap.round
        ..color = light && !on ? const Color(0x552F8CFF) : const Color(0x80FFFFFF),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_GlassP o) => o.fill != fill || o.wave != wave || o.extra != extra || o.light != light;
}

// ---------- کالۆری هەفتە ----------
class _WeekBox extends StatelessWidget {
  const _WeekBox({required this.week, required this.goal});
  final List<int?> week;
  final int goal;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final days = _tl('days');
    final n = week.length;
    final vals = week.whereType<int>().toList();
    final mx = math.max(goal * 1.2, vals.isEmpty ? 1.0 : vals.reduce(math.max).toDouble());
    final gp = math.min(0.97, goal / mx);
    final past = <int>[];
    final pastDays = <String>[];
    for (int i = 0; i < n - 1; i++) {
      final v = week[i];
      if (v != null) {
        past.add(v);
        pastDays.add(days.length == 7 ? days[now.subtract(Duration(days: n - 1 - i)).weekday - 1] : '');
      }
    }
    final avg = past.isEmpty ? 0 : (past.reduce((a, b) => a + b) / past.length).round();
    final hit = past.where((v) => goal > 0 && (v / goal - 1).abs() <= 0.08).length;
    int bi = -1;
    for (int i = 0; i < past.length; i++) {
      if (bi < 0 || (past[i] - goal).abs() < (past[bi] - goal).abs()) bi = i;
    }
    final lg = _tl('lg');
    const cOk = Color(0xFF22C870), cLo = Color(0xFF1FA6CC), cHi = Color(0xFFFF4D6D);

    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: Text('📊 ${_t('week')}', style: ku(13.5, w: FontWeight.w800))),
              Text.rich(
                TextSpan(children: [
                  TextSpan(text: '┆ ${_t('goal')} '),
                  TextSpan(text: _iso(fmt(goal)), style: nu(10.5, w: FontWeight.w700, c: V.mu)),
                ]),
                style: ku(10.5, w: FontWeight.w700, c: V.mu),
              ),
            ],
          ),
          const SizedBox(height: 8),
          for (int i = 0; i < n; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 9),
              child: _weekRow(
                name: days.length == 7 ? days[now.subtract(Duration(days: n - 1 - i)).weekday - 1] : '',
                v: week[i],
                today: i == n - 1,
                mx: mx,
                gp: gp,
                cOk: cOk,
                cLo: cLo,
                cHi: cHi,
              ),
            ),
          if (lg.length == 3)
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 12,
              runSpacing: 4,
              children: [
                _legend(lg[0], cOk),
                _legend(lg[1], cLo),
                _legend(lg[2], cHi),
              ],
            ),
          if (past.isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                _stat(_t('avg'), Text(fmt(avg), style: nu(13))),
                const SizedBox(width: 8),
                _stat(_t('hit'), Text('$hit/${past.length}', textDirection: TextDirection.ltr, style: nu(13))),
                const SizedBox(width: 8),
                _stat(
                  _t('best'),
                  Text(bi >= 0 ? pastDays[bi] : '—', maxLines: 1, overflow: TextOverflow.ellipsis, style: ku(12.5, w: FontWeight.w800)),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _weekRow({
    required String name,
    required int? v,
    required bool today,
    required double mx,
    required double gp,
    required Color cOk,
    required Color cLo,
    required Color cHi,
  }) {
    final q = v == null || goal <= 0 ? 0.0 : v / goal;
    final c = v == null ? V.mu : (q > 1.08 ? cHi : (q >= 0.92 ? cOk : cLo));
    final f = v == null ? 0.0 : math.min(0.94, v / mx);
    return Row(
      children: [
        SizedBox(
          width: 92,
          child: Row(
            children: [
              Flexible(
                child: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: ku(12, w: v == null ? FontWeight.w600 : FontWeight.w800, c: today ? _ink(V.cy) : (v == null ? V.mu : V.tx)),
                ),
              ),
              if (today) ...[
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(color: V.cy, borderRadius: BorderRadius.circular(99)),
                  child: Text(_t('today'), style: ku(8.5, w: FontWeight.w800, c: const Color(0xFF04323A))),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: SizedBox(
              height: 14,
              child: Stack(
                alignment: Alignment.centerLeft,
                children: [
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 4,
                    height: 6,
                    child: v == null
                        ? CustomPaint(painter: _DashP(V.line2))
                        : DecoratedBox(decoration: BoxDecoration(color: V.track, borderRadius: BorderRadius.circular(9))),
                  ),
                  if (v != null)
                    Positioned(
                      left: 0,
                      right: 0,
                      top: 4,
                      height: 6,
                      child: TweenAnimationBuilder<double>(
                        tween: Tween<double>(begin: 0, end: f),
                        duration: const Duration(milliseconds: 1100),
                        curve: _kEase,
                        builder: (context, x, _) => FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: x,
                          heightFactor: 1,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(9),
                              gradient: LinearGradient(colors: [op(c, 0.15), c]),
                              boxShadow: [BoxShadow(color: op(c, 0.45), blurRadius: 8, spreadRadius: -2)],
                            ),
                          ),
                        ),
                      ),
                    ),
                  Positioned.fill(
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: gp,
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Container(width: 1.5, height: 14, color: const Color(0xFFFFD666)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 46,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerEnd,
            child: Text(v == null ? '—' : fmt(v), textDirection: TextDirection.ltr, style: nu(11.5, c: v == null ? V.mu : _ink(c))),
          ),
        ),
      ],
    );
  }

  Widget _legend(String t, Color c) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 9, height: 9, decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
          const SizedBox(width: 5),
          Text(t, style: ku(10.5, w: FontWeight.w700, c: V.mu)),
        ],
      );

  Widget _stat(String l, Widget v) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
          decoration: BoxDecoration(color: V.surf2, borderRadius: BorderRadius.circular(14), border: Border.all(color: V.line)),
          child: Column(
            children: [
              Text(l, maxLines: 1, overflow: TextOverflow.ellipsis, style: ku(10, w: FontWeight.w700, c: V.mu)),
              const SizedBox(height: 2),
              v,
            ],
          ),
        ),
      );
}

class _DashP extends CustomPainter {
  _DashP(this.c);
  final Color c;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = c
      ..strokeWidth = 1.5;
    final y = size.height / 2;
    for (double x = 0; x < size.width; x += 8) {
      canvas.drawLine(Offset(x, y), Offset(math.min(x + 4, size.width), y), p);
    }
  }

  @override
  bool shouldRepaint(_DashP o) => o.c != c;
}

// ═════════════════════════════ پێشبینینی خواردنی خۆم ═════════════════════════════
/// لینکێکی بچووک بۆ _PrivacyCard: «ئەوەی بازنەکەت دەیبینن»
class FriendFoodPreviewLink extends StatelessWidget {
  const FriendFoodPreviewLink({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([FamilyStore.I, LangState.I, VexTheme.I]),
      builder: (context, _) {
        final on = FamilyStore.I.share['food'] ?? false;
        return Directionality(
          textDirection: _dir,
          child: Press(
            onTap: openMyFoodPreview,
            child: Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: op(on ? _kG : V.mu, 0.08),
                border: Border.all(color: op(on ? _kG : V.mu, 0.3)),
              ),
              child: Row(
                children: [
                  const Text('👁️', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_t('prev'), style: ku(13, w: FontWeight.w800)),
                        Text(on ? _t('shOn') : _t('shOff'), style: ku(11, w: FontWeight.w600, c: V.mu)),
                      ],
                    ),
                  ),
                  Icon(_isLtr ? Icons.chevron_right_rounded : Icons.chevron_left_rounded, color: V.mu),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// شیتی «ئەوەی بازنەکەت دەیبینن» + دوگمەی هاوبەشکردن
Future<void> openMyFoodPreview() async {
  FriendFood.I.init();
  await showVSheet<void>(builder: (_) => const _MyFoodSheet());
}

class _MyFoodSheet extends StatelessWidget {
  const _MyFoodSheet();

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([FamilyStore.I, LangState.I, VexTheme.I]),
      builder: (context, _) {
        final on = FamilyStore.I.share['food'] ?? false;
        return Directionality(
          textDirection: _dir,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(color: V.surf2, borderRadius: BorderRadius.circular(18), border: Border.all(color: V.line)),
                child: Row(
                  children: [
                    const Text('🍽️', style: TextStyle(fontSize: 20)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_t('share'), style: ku(14, w: FontWeight.w800)),
                          Text(on ? _t('shOn') : _t('shOff'), style: ku(11.5, w: FontWeight.w600, c: V.mu)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Semantics(
                      toggled: on,
                      button: true,
                      label: _t('share'),
                      child: GestureDetector(
                        key: const ValueKey('ff-share-switch'),
                        behavior: HitTestBehavior.opaque,
                        onTap: () => FamilyStore.I.toggleShare('food'),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          width: 46,
                          height: 28,
                          padding: const EdgeInsets.all(3),
                          alignment: on ? AlignmentDirectional.centerEnd : AlignmentDirectional.centerStart,
                          decoration: BoxDecoration(color: on ? V.mint : V.track, borderRadius: BorderRadius.circular(99)),
                          child: Container(
                            width: 22,
                            height: 22,
                            decoration: const BoxDecoration(color: Color(0xFFFFFFFF), shape: BoxShape.circle),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              AnimatedOpacity(
                duration: const Duration(milliseconds: 250),
                opacity: on ? 1 : 0.45,
                child: const FriendFoodCard.me(),
              ),
            ],
          ),
        );
      },
    );
  }
}
