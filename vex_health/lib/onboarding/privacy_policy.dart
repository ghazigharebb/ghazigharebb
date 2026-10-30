// VEX Health — سیاسەتی پاراستنی نهێنی (privacy_policy.dart)
//
// 11 بەش بە 6 زمان: کوردیی سۆرانی، بادینی، English، العربية، فارسی، Türkçe.
// زمان لە LangState.I.code وەردەگیرێت و ڕەنگ لە VexTheme (ڕووناک / تاریک / خۆکار).
// هەر زمانێک ئاراستەی خۆی هەیە (RTL / LTR)، بۆیە دەقی ئینگلیزی و تورکی هەرگیز لە ڕاستەوە ناچن.
//
// بەکارهێنان:
//   openPrivacyPolicy();               // لە پرۆفایل ← «سیاسەتی پاراستنی نهێنی»
//   const PrivacyPolicyPage()          // یان ڕاستەوخۆ وەک پەڕە
//   privacyPolicy('ckb')               // تەنها دەقەکان (بۆ نموونە بۆ وێب یان PDF)
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/theme.dart';
import 'reg_lang_state.dart';

/// ئیمەیڵی پەیوەندی بە نهێنییەوە
const String kPrivacyEmail = 'privacy@hez.on-forge.com';

/// دەقی سیاسەتەکە بە یەک زمان
class PrivacyDoc {
  const PrivacyDoc({
    required this.rtl,
    required this.title,
    required this.updated,
    required this.intro,
    required this.highlights,
    required this.sections,
    required this.contactTitle,
    required this.contactNote,
    required this.copy,
    required this.copied,
    required this.thanks,
  });

  final bool rtl;
  final String title;
  final String updated;
  final String intro;

  /// سێ خاڵی سەرەکی لە سەرەوەی پەڕەکە
  final List<String> highlights;

  /// [سەردێڕ، دەق]. لە دەقدا: «\n» دێڕی نوێ، «• » خاڵ، «{email}» ئیمەیڵەکە.
  final List<List<String>> sections;
  final String contactTitle;
  final String contactNote;
  final String copy;
  final String copied;
  final String thanks;

  /// دەقی تەواو وەک نووسینی ئاسایی (بۆ هاوبەشکردن، وێب یان PDF)
  String get plainText {
    final b = StringBuffer()
      ..writeln(title)
      ..writeln(updated)
      ..writeln()
      ..writeln(intro);
    for (var i = 0; i < sections.length; i++) {
      b
        ..writeln()
        ..writeln('${i + 1}. ${sections[i][0]}')
        ..writeln(sections[i][1].replaceAll('{email}', kPrivacyEmail));
    }
    b
      ..writeln()
      ..writeln(thanks);
    return b.toString();
  }
}

/// دەقی سیاسەتەکە بە زمانی داواکراو (بنەڕەت: کوردیی سۆرانی)
PrivacyDoc privacyPolicy([String? code]) => _kPrivacy[code ?? LangState.I.code] ?? _kPrivacy['ckb']!;

/// کردنەوەی پەڕەی سیاسەتی پاراستنی نهێنی
Future<void> openPrivacyPolicy() async {
  final nav = navKey.currentState;
  if (nav == null) return;
  await nav.push<void>(MaterialPageRoute<void>(builder: (_) => const PrivacyPolicyPage()));
}

// ═════════════════════════════ دەقەکان ═════════════════════════════
const Map<String, PrivacyDoc> _kPrivacy = {
  // ───────── کوردیی سۆرانی ─────────
  'ckb': PrivacyDoc(
    rtl: true,
    title: 'سیاسەتی پاراستنی نهێنیی VEX',
    updated: 'دوایین نوێکردنەوە: 30ی تشرینی یەکەمی 2026',
    intro: 'نهێنیی تۆ بۆ ئێمە گرنگە. ئەم سیاسەتە بە ڕوونی دەڵێت VEX چ زانیارییەک کۆ دەکاتەوە، بۆچی بەکاری دەهێنێت و چۆن دەیپارێزێت.',
    highlights: ['هەرگیز داتاکانت نافرۆشین', 'تۆ بڕیار دەدەیت چی هاوبەش بکەیت', 'هەر کاتێک بتەوێت دەتوانیت بیسڕیتەوە'],
    sections: [
      ['ئێمە کێین', 'VEX ئەپی VEX و خزمەتگوزارییەکانی VEX Band پێشکەش دەکات. بۆ هەر پرسیارێک دەربارەی نهێنی، ئیمەیڵ بنێرە بۆ: {email}'],
      [
        'چ زانیارییەک کۆ دەکەینەوە',
        '• هەژمار: ناو، ئیمەیڵ، ژمارەی مۆبایل و ڕێگەی چوونەژوورەوە (وەک Gmail).\n'
            '• پرۆفایل: تەمەن، ڕەگەز، باڵا، کێش و ئامانج. نەخۆشی و هەستیاری تەنها ئەگەر خۆت بیاننووسیت.\n'
            '• تەندروستی: هەنگاو، لێدانی دڵ، ئۆکسجینی خوێن، ECG، خەو، سترێس، پلەی گەرمی، ئاو، خواردن و وەرزش.\n'
            '• ئامێر: جۆری مۆبایل، زانیاریی Band و وەشانی ئەپ.\n'
            '• بەشداربوون: تەنها دۆخی VEX Plus. ژمارەی کارتەکەت هەرگیز نابینین و هەڵی ناگرین.',
      ],
      [
        'بۆچی بەکاری دەهێنین',
        '• بۆ پیشاندانی داشبۆرد و ئامانجەکانت.\n'
            '• بۆ هاوکاتکردنی Band.\n'
            '• بۆ دروستکردنی پلانی خواردن و ڕاهێنان.\n'
            '• بۆ وەڵامەکانی VEX AI و ئاگادارکردنەوەی تەندروستی.\n'
            '• بۆ باشترکردنی ئەپەکە.\n'
            'هەرگیز زانیاریی تەندروستیت بۆ ڕیکلام بەکار ناهێنین.',
      ],
      ['داتای تەندروستی', 'داتای تەندروستی زانیارییەکی هەستیارە. تەنها بە ڕەزامەندیی خۆت کۆی دەکەینەوە و زۆربەی لەسەر مۆبایلەکەت خۆت هەڵدەگیرێت. تەنها بۆ خزمەتکردنی خۆت بەکاری دەهێنین.'],
      ['مۆڵەتەکان', 'شوێن (بۆ کاتەکانی بانگ و وەرزشی دەرەوە)، کامێرا (بۆ سکانی خواردن)، Bluetooth (بۆ Band) و ئاگادارکردنەوەکان تەنها کاتێک بەکار دێن کە خۆت ڕێگە بدەیت. هەر کاتێک بتەوێت، دەتوانیت لە ڕێکخستنەکانی مۆبایلەکەتەوە ڕایانبگریت.'],
      ['زیرەکیی دەستکرد', 'کاتێک وێنەی خواردن سکان دەکەیت یان پرسیار لە VEX AI دەکەیت، تەنها ئەو زانیارییانەی بۆ وەڵامەکە پێویستن بە شێوەی پارێزراو دەنێردرێن. تەنها بۆ دروستکردنی وەڵامەکەی تۆ بەکار دەهێنرێن.'],
      [
        'هاوبەشکردن',
        'هەرگیز داتاکانت نافرۆشین. تەنها لەم سێ حاڵەتەدا هاوبەش دەکرێن:\n'
            '• کاتێک خۆت لەگەڵ بازنەی خێزان و هاوڕێدا هاوبەشیان دەکەیت.\n'
            '• لەگەڵ دابینکەرانی خزمەتگوزاری (سێرڤەر، AI و پارەدان) کە تەنها بۆ ئێمە کار دەکەن.\n'
            '• ئەگەر یاسا داوای بکات یان بۆ پاراستنی ژیانی کەسێک پێویست بێت.',
      ],
      ['خێزان، هاوڕێ و Arena', 'تۆ بڕیار دەدەیت چی هاوبەش بکەیت، وەک دڵ، خەو، خواردن و ئاو، و هەر کاتێک بتەوێت دەتوانیت ڕایبگریت. لە VEX Arena، ناو و خاڵەکانت بۆ بەشداربووانی تر دەردەکەون.'],
      ['پاراستن و ماوەی هەڵگرتن', 'داتاکان بە شێوەی شفرەکراو دەگوازرێنەوە و دەستگەیشتن پێیان سنووردارە. تا هەژمارەکەت چالاک بێت هەڵیان دەگرین. کاتێک هەژمارەکەت دەسڕیتەوە، لە ماوەی 30 ڕۆژدا لە سێرڤەرەکانمان دەسڕێنەوە، مەگەر یاسا داوای هەڵگرتنیان بکات.'],
      [
        'مافەکانت و منداڵان',
        '• دەتوانیت داتاکانت ببینیت، ڕاستیان بکەیتەوە و کۆپییەکیان داوا بکەیت.\n'
            '• دەتوانیت ڕەزامەندییەکەت بکشێنیتەوە و هەژمارەکەت لە پرۆفایلەوە بسڕیتەوە.\n'
            '• بۆ هەر داواکارییەک ئیمەیڵمان بۆ بنێرە. لە ماوەی 30 ڕۆژدا وەڵامت دەدەینەوە.\n'
            'VEX بۆ تەمەنی 18 ساڵ و سەرووترە. کەسانی ژێر 18 ساڵ تەنها بە ڕەزامەندیی دایک یان باوک دەتوانن بەکاری بهێنن.',
      ],
      ['گۆڕانکاری و پەیوەندی', 'ئەگەر ئەم سیاسەتە گۆڕا، لەناو ئەپەکەدا ئاگادارت دەکەینەوە و بەرواری سەرەوە نوێ دەکەینەوە. بۆ هەر پرسیارێک: {email}'],
    ],
    contactTitle: 'پەیوەندی بە نهێنییەوە',
    contactNote: 'لە ماوەی 30 ڕۆژدا وەڵامت دەدەینەوە',
    copy: 'کۆپی',
    copied: 'کۆپی کرا',
    thanks: 'نهێنیی تۆ، متمانەی ئێمەیە 💚',
  ),

  // ───────── کوردیی بادینی ─────────
  'kmr': PrivacyDoc(
    rtl: true,
    title: 'سیاسەتا پاراستنا نهێنیێ یا VEX',
    updated: 'دووماهیک نووکرن: 30ێ چریا ئێکێ 2026',
    intro: 'نهێنیا تە بۆ مە یا گرنگە. ئەڤ سیاسەتە ب ڕوونی دبێژیت VEX چ زانیاریان کۆم دکەت، بۆچ بکاردئینیت و چاوا دپارێزیت.',
    highlights: ['ئەم چ جاران داتایێن تە نافرۆشین', 'تو بڕیارێ ددەی کا دێ چ پارڤە کەی', 'هەر دەمەکێ تە بڤێت دشێی ژێببەی'],
    sections: [
      ['ئەم کینە', 'VEX ئەپێ VEX و خزمەتگوزاریێن VEX Band پێشکێش دکەت. بۆ هەر پسیارەکێ دەربارەی نهێنیێ، ئیمەیلێ بفرێکە بۆ: {email}'],
      [
        'ئەم چ زانیاریان کۆم دکەین',
        '• هەژمار: ناڤ، ئیمەیل، ژمارا مۆبایلێ و ڕێکا چوونا ژوور (وەکی Gmail).\n'
            '• پرۆفایل: ژی، ڕەگەز، درێژاهی، کێش و ئارمانج. نەخۆشی و ئەلێرجی تنێ ئەگەر تو ب خۆ بنڤیسی.\n'
            '• ساخلەمی: هەنگاڤ، لێدانا دلی، ئۆکسجینا خوینێ، ECG، خەو، سترێس، پلەیا گەرمیێ، ئاڤ، خوارن و وەرزش.\n'
            '• ئامێر: جۆرێ مۆبایلێ، زانیاریێن Band و وەشانا ئەپی.\n'
            '• بەشداربوون: تنێ دۆخێ VEX Plus. ئەم چ جاران ژمارا کارتا تە نابینین و هەلناگرین.',
      ],
      [
        'بۆچ بکاردئینین',
        '• بۆ نیشاندانا داشبۆردێ و ئارمانجێن تە.\n'
            '• بۆ هەڤدەمکرنا Band.\n'
            '• بۆ دروستکرنا پلانا خوارنێ و ڕاهێنانێ.\n'
            '• بۆ بەرسڤێن VEX AI و ئاگەهدارکرنێن ساخلەمیێ.\n'
            '• بۆ باشترکرنا ئەپی.\n'
            'ئەم چ جاران زانیاریێن ساخلەمیا تە بۆ ڕیکلامێ بکارنائینین.',
      ],
      ['داتایێن ساخلەمیێ', 'داتایێن ساخلەمیێ زانیاریێن هەستیارن. ئەم تنێ ب ڕازیبوونا تە کۆم دکەین و پترییا وان ل سەر مۆبایلا تە ب خۆ دهێنە هەلگرتن. تنێ بۆ خزمەتا تە بکاردئینین.'],
      ['مۆڵەت', 'جه (بۆ دەمێن بانگێ و وەرزشا دەرڤە)، کامێرا (بۆ سکانا خوارنێ)، Bluetooth (بۆ Band) و ئاگەهدارکرن تنێ دەمێ تو ڕێ ددەی دهێنە بکارئینان. هەر دەمەکێ تە بڤێت، دشێی ژ ڕێکخستنێن مۆبایلا خۆ ڕاوەستینی.'],
      ['زیرەکیا دەستکرد', 'دەمێ تو وێنەیێ خوارنێ سکان دکەی یان پسیارێ ژ VEX AI دکەی، تنێ ئەو زانیاریێن بۆ بەرسڤێ پێدڤی ب شێوەیەکێ پاراستی دهێنە فرێکرن. تنێ بۆ دروستکرنا بەرسڤا تە دهێنە بکارئینان.'],
      [
        'پارڤەکرن',
        'ئەم چ جاران داتایێن تە نافرۆشین. تنێ د ڤان سێ حالەتاندا دهێنە پارڤەکرن:\n'
            '• دەمێ تو ب خۆ دگەل بازنێ خێزان و هەڤالان پارڤە دکەی.\n'
            '• دگەل دابینکەرێن خزمەتگوزاریێ (سێرڤەر، AI و پارەدان) یێن تنێ بۆ مە کار دکەن.\n'
            '• ئەگەر یاسا داخواز بکەت یان بۆ پاراستنا ژیانا کەسەکی پێدڤی بیت.',
      ],
      ['خێزان، هەڤال و Arena', 'تو بڕیارێ ددەی کا دێ چ پارڤە کەی، وەکی دل، خەو، خوارن و ئاڤ، و هەر دەمەکێ تە بڤێت دشێی ڕاوەستینی. د VEX Arena دا، ناڤ و خاڵێن تە بۆ بەشداربوویێن دی دیار دبن.'],
      ['پاراستن و ماوێ هەلگرتنێ', 'داتا ب شێوەیەکێ شفرەکری دهێنە ڤەگوهاستن و دەستگەهشتن پێ سنووردارە. هەتا هەژمارا تە چالاک بیت، ئەم هەلدگرین. دەمێ تو هەژمارا خۆ ژێدبەی، د ماوێ 30 ڕۆژاندا ژ سێرڤەرێن مە دهێنە ژێبرن، ئەگەر یاسا داخوازا هەلگرتنێ نەکەت.'],
      [
        'مافێن تە و زارۆک',
        '• دشێی داتایێن خۆ ببینی، ڕاست بکەی و کۆپیەکێ داخواز بکەی.\n'
            '• دشێی ڕازیبوونا خۆ ڤەکێشی و ژ پرۆفایلی هەژمارا خۆ ژێببەی.\n'
            '• بۆ هەر داخوازەکێ ئیمەیلێ بۆ مە بفرێکە. د ماوێ 30 ڕۆژاندا دێ بەرسڤا تە دەین.\n'
            'VEX بۆ ژیێ 18 ساڵان و سەرترە. کەسێن ژ 18 ساڵان کێمتر تنێ ب ڕازیبوونا دایک یان بابی دشێن بکاربینن.',
      ],
      ['گوهۆڕین و پەیوەندی', 'ئەگەر ئەڤ سیاسەتە هاتە گوهۆڕین، دێ د ناڤ ئەپیدا تە ئاگەهدار کەین و دیرۆکا سەری نوو کەین. بۆ هەر پسیارەکێ: {email}'],
    ],
    contactTitle: 'پەیوەندی بۆ نهێنیێ',
    contactNote: 'د ماوێ 30 ڕۆژاندا بەرسڤا تە ددەین',
    copy: 'کۆپی',
    copied: 'هاتە کۆپیکرن',
    thanks: 'نهێنیا تە، باوەریا مەیە 💚',
  ),

  // ───────── English ─────────
  'en': PrivacyDoc(
    rtl: false,
    title: 'VEX Privacy Policy',
    updated: 'Last updated: October 30, 2026',
    intro: 'Your privacy matters to us. This policy explains clearly what information VEX collects, why we use it, and how we protect it.',
    highlights: ['We never sell your data', 'You decide what to share', 'Delete your data any time'],
    sections: [
      ['Who we are', 'VEX provides the VEX app and VEX Band services. For any privacy question, email us at: {email}'],
      [
        'Information we collect',
        '• Account: name, email, phone number and sign-in method (such as Gmail).\n'
            '• Profile: age, sex, height, weight and goal. Health conditions and allergies only if you enter them yourself.\n'
            '• Health: steps, heart rate, blood oxygen, ECG, sleep, stress, temperature, water, food and workouts.\n'
            '• Device: phone model, Band information and app version.\n'
            '• Subscription: only your VEX Plus status. We never see or store your card number.',
      ],
      [
        'Why we use it',
        '• To show your dashboard and goals.\n'
            '• To sync your Band.\n'
            '• To build your meal and training plans.\n'
            '• For VEX AI answers and health alerts.\n'
            '• To improve the app.\n'
            'We never use your health information for advertising.',
      ],
      ['Health data', 'Health data is sensitive information. We collect it only with your consent, most of it stays on your own phone, and we use it only to serve you.'],
      ['Permissions', 'Location (for prayer times and outdoor workouts), camera (for food scanning), Bluetooth (for the Band) and notifications are used only when you allow them. You can turn them off at any time in your phone settings.'],
      ['Artificial intelligence', 'When you scan a food photo or ask VEX AI a question, only the information needed for the answer is sent securely, and it is used only to create your answer.'],
      [
        'Sharing',
        'We never sell your data. It is shared only in these three cases:\n'
            '• When you share it yourself with your family and friends circle.\n'
            '• With service providers (servers, AI and payments) who work only for us.\n'
            '• When the law requires it, or to protect someone\'s life.',
      ],
      ['Family, friends and Arena', 'You decide what to share, such as heart, sleep, food and water, and you can stop sharing at any time. In VEX Arena, your name and points are visible to other participants.'],
      ['Security and retention', 'Data is encrypted in transit and access to it is restricted. We keep it while your account is active. When you delete your account, it is removed from our servers within 30 days, unless the law requires us to keep it.'],
      [
        'Your rights and children',
        '• You can view and correct your data and request a copy.\n'
            '• You can withdraw your consent and delete your account from your profile.\n'
            '• Email us with any request; we will reply within 30 days.\n'
            'VEX is for people aged 18 and over. Anyone under 18 may use it only with a parent\'s consent.',
      ],
      ['Changes and contact', 'If this policy changes, we will notify you in the app and update the date above. For any question: {email}'],
    ],
    contactTitle: 'Privacy contact',
    contactNote: 'We reply within 30 days',
    copy: 'Copy',
    copied: 'Copied',
    thanks: 'Your privacy is our promise 💚',
  ),

  // ───────── العربية ─────────
  'ar': PrivacyDoc(
    rtl: true,
    title: 'سياسة الخصوصية لـ VEX',
    updated: 'آخر تحديث: 30 تشرين الأول 2026',
    intro: 'خصوصيتك مهمة لنا. توضّح هذه السياسة بوضوح ما المعلومات التي يجمعها VEX، ولماذا نستخدمها، وكيف نحميها.',
    highlights: ['لا نبيع بياناتك أبداً', 'أنت تقرر ما تشاركه', 'احذف بياناتك متى شئت'],
    sections: [
      ['من نحن', 'تقدّم VEX تطبيق VEX وخدمات VEX Band. لأي سؤال يخص الخصوصية، راسلنا على: {email}'],
      [
        'المعلومات التي نجمعها',
        '• الحساب: الاسم والبريد الإلكتروني ورقم الهاتف وطريقة تسجيل الدخول (مثل Gmail).\n'
            '• الملف الشخصي: العمر والجنس والطول والوزن والهدف. الأمراض والحساسية فقط إذا أدخلتها بنفسك.\n'
            '• الصحة: الخطوات ونبض القلب وأكسجين الدم وتخطيط القلب (ECG) والنوم والتوتر ودرجة الحرارة والماء والطعام والتمارين.\n'
            '• الجهاز: نوع الهاتف ومعلومات Band وإصدار التطبيق.\n'
            '• الاشتراك: حالة VEX Plus فقط. لا نرى رقم بطاقتك ولا نحفظه أبداً.',
      ],
      [
        'لماذا نستخدمها',
        '• لعرض لوحة المعلومات وأهدافك.\n'
            '• لمزامنة Band.\n'
            '• لإعداد خطة الطعام والتمارين.\n'
            '• لإجابات VEX AI والتنبيهات الصحية.\n'
            '• لتحسين التطبيق.\n'
            'لا نستخدم معلوماتك الصحية للإعلانات أبداً.',
      ],
      ['البيانات الصحية', 'البيانات الصحية معلومات حساسة. نجمعها بموافقتك فقط، ويُحفظ معظمها على هاتفك أنت، ونستخدمها فقط لخدمتك.'],
      ['الأذونات', 'الموقع (لمواقيت الصلاة والتمارين الخارجية)، والكاميرا (لمسح الطعام)، والبلوتوث (لـ Band)، والإشعارات تُستخدم فقط عندما تسمح بها. يمكنك إيقافها في أي وقت من إعدادات هاتفك.'],
      ['الذكاء الاصطناعي', 'عندما تمسح صورة طعام أو تسأل VEX AI، تُرسَل فقط المعلومات اللازمة للإجابة بشكل آمن، وتُستخدم فقط لإنشاء إجابتك.'],
      [
        'المشاركة',
        'لا نبيع بياناتك أبداً. تُشارَك فقط في هذه الحالات الثلاث:\n'
            '• عندما تشاركها بنفسك مع دائرة العائلة والأصدقاء.\n'
            '• مع مزوّدي الخدمة (الخوادم والذكاء الاصطناعي والدفع) الذين يعملون لصالحنا فقط.\n'
            '• إذا طلب القانون ذلك أو لحماية حياة شخص ما.',
      ],
      ['العائلة والأصدقاء و Arena', 'أنت تقرر ما تشاركه، مثل القلب والنوم والطعام والماء، ويمكنك إيقاف المشاركة في أي وقت. في VEX Arena، يظهر اسمك ونقاطك للمشاركين الآخرين.'],
      ['الحماية ومدة الاحتفاظ', 'تُنقل البيانات بشكل مشفّر، والوصول إليها محدود. نحتفظ بها ما دام حسابك نشطاً. عند حذف حسابك، تُحذف من خوادمنا خلال 30 يوماً، ما لم يُلزمنا القانون بالاحتفاظ بها.'],
      [
        'حقوقك والأطفال',
        '• يمكنك الاطلاع على بياناتك وتصحيحها وطلب نسخة منها.\n'
            '• يمكنك سحب موافقتك وحذف حسابك من الملف الشخصي.\n'
            '• راسلنا بأي طلب، وسنرد خلال 30 يوماً.\n'
            'VEX مخصّص لمن هم في عمر 18 عاماً فأكثر. ومن هم دون 18 عاماً يمكنهم استخدامه فقط بموافقة أحد الوالدين.',
      ],
      ['التغييرات والتواصل', 'إذا تغيّرت هذه السياسة، سنُعلمك داخل التطبيق ونحدّث التاريخ أعلاه. لأي سؤال: {email}'],
    ],
    contactTitle: 'التواصل بشأن الخصوصية',
    contactNote: 'نرد خلال 30 يوماً',
    copy: 'نسخ',
    copied: 'تم النسخ',
    thanks: 'خصوصيتك أمانة لدينا 💚',
  ),

  // ───────── فارسی ─────────
  'fa': PrivacyDoc(
    rtl: true,
    title: 'سیاست حفظ حریم خصوصی VEX',
    updated: 'آخرین به‌روزرسانی: 30 اکتبر 2026',
    intro: 'حریم خصوصی شما برای ما مهم است. این سیاست به‌روشنی توضیح می‌دهد VEX چه اطلاعاتی جمع‌آوری می‌کند، چرا از آن استفاده می‌کند و چگونه از آن محافظت می‌کند.',
    highlights: ['هرگز داده‌های شما را نمی‌فروشیم', 'شما تصمیم می‌گیرید چه چیزی را به اشتراک بگذارید', 'هر زمان بخواهید داده‌هایتان را حذف کنید'],
    sections: [
      ['ما چه کسانی هستیم', 'VEX اپلیکیشن VEX و خدمات VEX Band را ارائه می‌دهد. برای هر پرسشی درباره حریم خصوصی، به این نشانی ایمیل بزنید: {email}'],
      [
        'چه اطلاعاتی جمع‌آوری می‌کنیم',
        '• حساب کاربری: نام، ایمیل، شماره موبایل و روش ورود (مانند Gmail).\n'
            '• پروفایل: سن، جنسیت، قد، وزن و هدف. بیماری‌ها و آلرژی‌ها فقط اگر خودتان وارد کنید.\n'
            '• سلامت: گام‌ها، ضربان قلب، اکسیژن خون، نوار قلب (ECG)، خواب، استرس، دمای بدن، آب، غذا و ورزش.\n'
            '• دستگاه: مدل گوشی، اطلاعات Band و نسخه اپلیکیشن.\n'
            '• اشتراک: فقط وضعیت VEX Plus. شماره کارت شما را هرگز نمی‌بینیم و ذخیره نمی‌کنیم.',
      ],
      [
        'چرا از آن استفاده می‌کنیم',
        '• برای نمایش داشبورد و اهداف شما.\n'
            '• برای همگام‌سازی Band.\n'
            '• برای ساختن برنامه غذایی و تمرینی.\n'
            '• برای پاسخ‌های VEX AI و هشدارهای سلامت.\n'
            '• برای بهتر کردن اپلیکیشن.\n'
            'هرگز از اطلاعات سلامت شما برای تبلیغات استفاده نمی‌کنیم.',
      ],
      ['داده‌های سلامت', 'داده‌های سلامت اطلاعاتی حساس هستند. آن‌ها را فقط با رضایت شما جمع‌آوری می‌کنیم، بیشتر آن‌ها روی گوشی خودتان ذخیره می‌شود و فقط برای خدمت به شما از آن‌ها استفاده می‌کنیم.'],
      ['مجوزها', 'موقعیت مکانی (برای اوقات شرعی و ورزش در فضای باز)، دوربین (برای اسکن غذا)، بلوتوث (برای Band) و اعلان‌ها فقط زمانی استفاده می‌شوند که خودتان اجازه دهید. هر زمان بخواهید می‌توانید آن‌ها را از تنظیمات گوشی خاموش کنید.'],
      ['هوش مصنوعی', 'وقتی عکس غذا را اسکن می‌کنید یا از VEX AI سؤال می‌پرسید، فقط اطلاعات لازم برای پاسخ به‌صورت امن ارسال می‌شود و فقط برای ساختن پاسخ شما به کار می‌رود.'],
      [
        'اشتراک‌گذاری',
        'هرگز داده‌های شما را نمی‌فروشیم. داده‌ها فقط در این سه حالت به اشتراک گذاشته می‌شوند:\n'
            '• وقتی خودتان آن‌ها را با حلقه خانواده و دوستان به اشتراک می‌گذارید.\n'
            '• با ارائه‌دهندگان خدمات (سرور، هوش مصنوعی و پرداخت) که فقط برای ما کار می‌کنند.\n'
            '• اگر قانون آن را الزامی کند یا برای حفظ جان یک نفر لازم باشد.',
      ],
      ['خانواده، دوستان و Arena', 'شما تصمیم می‌گیرید چه چیزی را به اشتراک بگذارید، مانند قلب، خواب، غذا و آب، و هر زمان بخواهید می‌توانید آن را متوقف کنید. در VEX Arena، نام و امتیازهای شما برای شرکت‌کنندگان دیگر نمایش داده می‌شود.'],
      ['امنیت و مدت نگهداری', 'داده‌ها به‌صورت رمزگذاری‌شده منتقل می‌شوند و دسترسی به آن‌ها محدود است. تا زمانی که حساب شما فعال است آن‌ها را نگه می‌داریم. وقتی حساب خود را حذف کنید، ظرف 30 روز از سرورهای ما پاک می‌شوند، مگر اینکه قانون نگهداری آن‌ها را الزامی کند.'],
      [
        'حقوق شما و کودکان',
        '• می‌توانید داده‌های خود را ببینید، اصلاح کنید و یک نسخه از آن‌ها درخواست کنید.\n'
            '• می‌توانید رضایت خود را پس بگیرید و حساب خود را از پروفایل حذف کنید.\n'
            '• برای هر درخواستی ایمیل بزنید؛ ظرف 30 روز پاسخ می‌دهیم.\n'
            'VEX برای افراد 18 سال و بالاتر است. افراد زیر 18 سال فقط با رضایت یکی از والدین می‌توانند از آن استفاده کنند.',
      ],
      ['تغییرات و تماس', 'اگر این سیاست تغییر کند، داخل اپلیکیشن به شما اطلاع می‌دهیم و تاریخ بالا را به‌روز می‌کنیم. برای هر پرسشی: {email}'],
    ],
    contactTitle: 'تماس درباره حریم خصوصی',
    contactNote: 'ظرف 30 روز پاسخ می‌دهیم',
    copy: 'کپی',
    copied: 'کپی شد',
    thanks: 'حریم خصوصی شما، امانت ماست 💚',
  ),

  // ───────── Türkçe ─────────
  'tr': PrivacyDoc(
    rtl: false,
    title: 'VEX Gizlilik Politikası',
    updated: 'Son güncelleme: 30 Ekim 2026',
    intro: 'Gizliliğiniz bizim için önemlidir. Bu politika, VEX\'in hangi bilgileri topladığını, bunları neden kullandığını ve nasıl koruduğunu açıkça anlatır.',
    highlights: ['Verilerinizi asla satmayız', 'Neyi paylaşacağınıza siz karar verirsiniz', 'Verilerinizi istediğiniz zaman silin'],
    sections: [
      ['Biz kimiz', 'VEX, VEX uygulamasını ve VEX Band hizmetlerini sunar. Gizlilikle ilgili her türlü sorunuz için bize e-posta gönderin: {email}'],
      [
        'Topladığımız bilgiler',
        '• Hesap: ad, e-posta, telefon numarası ve giriş yöntemi (Gmail gibi).\n'
            '• Profil: yaş, cinsiyet, boy, kilo ve hedef. Hastalıklar ve alerjiler yalnızca kendiniz girerseniz.\n'
            '• Sağlık: adım, kalp atış hızı, kan oksijeni, EKG, uyku, stres, vücut sıcaklığı, su, yemek ve egzersiz.\n'
            '• Cihaz: telefon modeli, Band bilgileri ve uygulama sürümü.\n'
            '• Abonelik: yalnızca VEX Plus durumu. Kart numaranızı asla görmeyiz ve saklamayız.',
      ],
      [
        'Neden kullanıyoruz',
        '• Panonuzu ve hedeflerinizi göstermek için.\n'
            '• Band\'inizi senkronize etmek için.\n'
            '• Beslenme ve antrenman planınızı oluşturmak için.\n'
            '• VEX AI yanıtları ve sağlık uyarıları için.\n'
            '• Uygulamayı geliştirmek için.\n'
            'Sağlık bilgilerinizi asla reklam için kullanmayız.',
      ],
      ['Sağlık verileri', 'Sağlık verileri hassas bilgilerdir. Bunları yalnızca izninizle toplarız, büyük kısmı kendi telefonunuzda saklanır ve yalnızca size hizmet etmek için kullanılır.'],
      ['İzinler', 'Konum (namaz vakitleri ve açık hava egzersizleri için), kamera (yemek taraması için), Bluetooth (Band için) ve bildirimler yalnızca siz izin verdiğinizde kullanılır. Bunları istediğiniz zaman telefon ayarlarından kapatabilirsiniz.'],
      ['Yapay zekâ', 'Bir yemek fotoğrafı taradığınızda veya VEX AI\'a soru sorduğunuzda, yalnızca yanıt için gereken bilgiler güvenli şekilde gönderilir ve yalnızca yanıtınızı oluşturmak için kullanılır.'],
      [
        'Paylaşım',
        'Verilerinizi asla satmayız. Yalnızca şu üç durumda paylaşılır:\n'
            '• Aile ve arkadaş çemberinizle kendiniz paylaştığınızda.\n'
            '• Yalnızca bizim için çalışan hizmet sağlayıcılarla (sunucu, yapay zekâ ve ödeme).\n'
            '• Yasa gerektirdiğinde veya birinin hayatını korumak için gerektiğinde.',
      ],
      ['Aile, arkadaşlar ve Arena', 'Kalp, uyku, yemek ve su gibi neyi paylaşacağınıza siz karar verirsiniz ve paylaşımı istediğiniz zaman durdurabilirsiniz. VEX Arena\'da adınız ve puanlarınız diğer katılımcılara görünür.'],
      ['Güvenlik ve saklama süresi', 'Veriler şifreli olarak aktarılır ve erişim sınırlıdır. Hesabınız aktif olduğu sürece saklarız. Hesabınızı sildiğinizde, yasa saklamamızı gerektirmedikçe verileriniz 30 gün içinde sunucularımızdan silinir.'],
      [
        'Haklarınız ve çocuklar',
        '• Verilerinizi görebilir, düzeltebilir ve bir kopyasını isteyebilirsiniz.\n'
            '• Onayınızı geri çekebilir ve hesabınızı profilden silebilirsiniz.\n'
            '• Her türlü talebiniz için bize e-posta gönderin; 30 gün içinde yanıt veririz.\n'
            'VEX 18 yaş ve üzeri içindir. 18 yaşından küçükler yalnızca ebeveyn onayıyla kullanabilir.',
      ],
      ['Değişiklikler ve iletişim', 'Bu politika değişirse sizi uygulama içinde bilgilendirir ve yukarıdaki tarihi güncelleriz. Her türlü sorunuz için: {email}'],
    ],
    contactTitle: 'Gizlilik iletişimi',
    contactNote: '30 gün içinde yanıt veririz',
    copy: 'Kopyala',
    copied: 'Kopyalandı',
    thanks: 'Gizliliğiniz bize emanet 💚',
  ),
};

// ═════════════════════════════ پەڕە ═════════════════════════════
/// ئایکۆنی هەر بەشێک (بە ڕیز)
const List<IconData> _kPpIcons = [
  Icons.badge_rounded,
  Icons.inventory_2_rounded,
  Icons.track_changes_rounded,
  Icons.favorite_rounded,
  Icons.app_settings_alt_rounded,
  Icons.auto_awesome_rounded,
  Icons.share_rounded,
  Icons.diversity_3_rounded,
  Icons.lock_rounded,
  Icons.how_to_reg_rounded,
  Icons.update_rounded,
];

class PrivacyPolicyPage extends StatefulWidget {
  const PrivacyPolicyPage({super.key});

  @override
  State<PrivacyPolicyPage> createState() => _PrivacyPolicyPageState();
}

class _PrivacyPolicyPageState extends State<PrivacyPolicyPage> {
  bool _copied = false;

  Future<void> _copy() async {
    await Clipboard.setData(const ClipboardData(text: kPrivacyEmail));
    HapticFeedback.lightImpact();
    if (!mounted) return;
    setState(() => _copied = true);
    Future<void>.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([LangState.I, VexTheme.I]),
      builder: (context, _) {
        final d = privacyPolicy();
        final dir = d.rtl ? TextDirection.rtl : TextDirection.ltr;
        final top = MediaQuery.of(context).padding.top;
        final bottom = MediaQuery.of(context).padding.bottom;
        return Directionality(
          textDirection: dir,
          child: Scaffold(
            backgroundColor: V.bg,
            body: Column(
              children: [
                // سەرەوە: گەڕانەوە + ناونیشان
                Padding(
                  padding: EdgeInsets.fromLTRB(8, top + 6, 8, 6),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).maybePop(),
                        icon: Icon(d.rtl ? Icons.arrow_forward_ios_rounded : Icons.arrow_back_ios_new_rounded, size: 20, color: V.tx),
                      ),
                      Expanded(
                        child: Text(
                          d.title,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: ku(17, w: FontWeight.w800),
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(16, 6, 16, bottom + 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _hero(d),
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.fromLTRB(18, 6, 18, 22),
                          decoration: BoxDecoration(
                            color: V.surf,
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(color: V.line2),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              for (var i = 0; i < d.sections.length; i++) ...[
                                if (i > 0) Divider(color: V.line, height: 1),
                                _section(i, d.sections[i][0], d.sections[i][1]),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        _contact(d),
                        const SizedBox(height: 20),
                        Text(
                          d.thanks,
                          textAlign: TextAlign.center,
                          style: ku(15, w: FontWeight.w800, c: V.mint, h: 1.6),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// کارتی سەرەوە: قەڵغان + ناونیشان + بەروار + پێشەکی + سێ خاڵی سەرەکی
  Widget _hero(PrivacyDoc d) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: op(V.cy, 0.35)),
        gradient: LinearGradient(
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
          colors: [op(V.cy, 0.14), op(V.mint, 0.06), V.surf],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: V.prime,
                  boxShadow: [BoxShadow(color: op(V.cy, 0.35), blurRadius: 16, offset: const Offset(0, 6))],
                ),
                child: const Icon(Icons.shield_rounded, color: Color(0xFF05303A), size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(d.title, style: ku(20, w: FontWeight.w800, h: 1.4)),
                    const SizedBox(height: 2),
                    Text(d.updated, style: ku(12.5, w: FontWeight.w600, c: V.mu)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(d.intro, style: ku(14.5, w: FontWeight.w500, h: 1.85)),
          const SizedBox(height: 14),
          for (final h in d.highlights)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: op(V.mint, 0.16)),
                    child: Icon(Icons.check_rounded, color: V.mint, size: 16),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Text(h, style: ku(14, w: FontWeight.w700, h: 1.5))),
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// یەک بەش: ئایکۆن + ژمارە + سەردێڕ + دەق (دێڕ، خاڵ، ئیمەیڵ)
  Widget _section(int i, String head, String body) {
    final k = i == 3 ? V.mint : V.cy; // داتای تەندروستی جیاکراوەتەوە
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: op(k, 0.13),
                  border: Border.all(color: op(k, 0.4)),
                ),
                child: Icon(_kPpIcons[i % _kPpIcons.length], color: k, size: 19),
              ),
              const SizedBox(width: 12),
              Text('${i + 1}', style: nu(13, c: op(k, 0.8))),
              const SizedBox(width: 8),
              Expanded(child: Text(head, style: ku(16, w: FontWeight.w800, c: k, h: 1.5))),
            ],
          ),
          const SizedBox(height: 8),
          for (final (j, line) in body.split('\n').indexed) _line(line, k, afterList: j > 0 && body.split('\n')[j - 1].startsWith('• ')),
        ],
      ),
    );
  }

  /// دێڕێک: ئەگەر بە «• » دەستی پێکرد ← خاڵ، و ئەوەی پێش «:» ئەستوور دەبێت
  Widget _line(String line, Color k, {bool afterList = false}) {
    final bullet = line.startsWith('• ');
    final text = bullet ? line.substring(2) : line;
    final base = ku(14.5, w: FontWeight.w500, c: V.tx, h: 1.85);
    final spans = <InlineSpan>[];
    var rest = text;
    if (bullet) {
      final c = rest.indexOf(':');
      if (c > 0 && c < 40) {
        spans.add(TextSpan(text: rest.substring(0, c + 1), style: base.copyWith(fontWeight: FontWeight.w800)));
        rest = rest.substring(c + 1);
      }
    }
    final parts = rest.split('{email}');
    for (var j = 0; j < parts.length; j++) {
      if (parts[j].isNotEmpty) spans.add(TextSpan(text: parts[j]));
      if (j < parts.length - 1) {
        // ئیمەیڵ هەمیشە چەپ بۆ ڕاست، تەنانەت لەناو دەقی کوردی و عەرەبیدا
        spans.add(TextSpan(
          text: '\u2066$kPrivacyEmail\u2069',
          style: base.copyWith(color: V.cy, fontWeight: FontWeight.w700),
        ));
      }
    }
    final rich = Text.rich(TextSpan(style: base, children: spans));
    if (!bullet) return Padding(padding: EdgeInsets.only(top: afterList ? 10 : 2), child: rich);
    return Padding(
      padding: const EdgeInsetsDirectional.only(top: 4, start: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 11),
            child: Container(width: 6, height: 6, decoration: BoxDecoration(color: k, shape: BoxShape.circle)),
          ),
          const SizedBox(width: 10),
          Expanded(child: rich),
        ],
      ),
    );
  }

  /// کارتی پەیوەندی: ئیمەیڵ + کۆپی
  Widget _contact(PrivacyDoc d) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: V.surf,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: op(V.cy, 0.35)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), color: op(V.cy, 0.13)),
            child: Icon(Icons.mail_rounded, color: V.cy, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(d.contactTitle, style: ku(14.5, w: FontWeight.w800)),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(kPrivacyEmail, textDirection: TextDirection.ltr, style: nu(13.5, w: FontWeight.w700, c: V.cy)),
                ),
                const SizedBox(height: 2),
                Text(d.contactNote, style: ku(12, w: FontWeight.w600, c: V.mu)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _copy,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: _copied ? null : V.prime,
                color: _copied ? op(V.mint, 0.16) : null,
                border: _copied ? Border.all(color: V.mint) : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(_copied ? Icons.check_rounded : Icons.copy_rounded, size: 17, color: _copied ? V.mint : const Color(0xFF05303A)),
                  const SizedBox(width: 6),
                  Text(_copied ? d.copied : d.copy, style: ku(13, w: FontWeight.w800, c: _copied ? V.mint : const Color(0xFF05303A))),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
