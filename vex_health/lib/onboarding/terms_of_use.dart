// VEX Health — مەرجەکانی بەکارهێنان (terms_of_use.dart)
//
// 11 بەش بە 6 زمان: کوردیی سۆرانی، بادینی، English، العربية، فارسی، Türkçe.
// زمان لە LangState.I.code وەردەگیرێت و ڕەنگ لە VexTheme (ڕووناک / تاریک / خۆکار).
//
// بەکارهێنان:
//   openTermsOfUse();                  // لە پرۆفایل ← «مەرجەکانی بەکارهێنان»
//   const TermsOfUsePage()             // یان ڕاستەوخۆ وەک پەڕە
//   termsOfUse('ckb')                  // تەنها دەقەکان (بۆ نموونە بۆ وێب یان PDF)
import 'package:flutter/material.dart';

import '../core/theme.dart';
import 'reg_lang_state.dart';

/// دەقی مەرجەکان بە یەک زمان
class TermsDoc {
  const TermsDoc({
    required this.rtl,
    required this.title,
    required this.updated,
    required this.sections,
    required this.thanks,
  });

  final bool rtl;
  final String title;
  final String updated;

  /// [سەردێڕ، دەق]
  final List<List<String>> sections;
  final String thanks;
}

/// دەقی مەرجەکان بە زمانی داواکراو (بنەڕەت: کوردیی سۆرانی)
TermsDoc termsOfUse([String? code]) => _kTerms[code ?? LangState.I.code] ?? _kTerms['ckb']!;

/// کردنەوەی پەڕەی مەرجەکانی بەکارهێنان
Future<void> openTermsOfUse() async {
  final nav = navKey.currentState;
  if (nav == null) return;
  await nav.push<void>(MaterialPageRoute<void>(builder: (_) => const TermsOfUsePage()));
}

// ═════════════════════════════ دەقەکان ═════════════════════════════
const Map<String, TermsDoc> _kTerms = {
  // ───────── کوردیی سۆرانی ─────────
  'ckb': TermsDoc(
    rtl: true,
    title: 'مەرجەکانی بەکارهێنانی VEX',
    updated: 'دوایین نوێکردنەوە: 30ی تشرینی یەکەمی 2026',
    sections: [
      ['ڕەزامەندی', 'بە دروستکردنی هەژمار یان بەکارهێنانی VEX، ڕازی دەبیت بەم مەرجانە و بە سیاسەتی پاراستنی نهێنی.'],
      ['ئامۆژگاریی پزیشکی نییە', 'VEX تەنها بۆ تەندروستیی گشتییە. پێوانە و ڕاپۆرتەکانی دەستنیشانکردنی نەخۆشی یان چارەسەر نین. پێش هەر بڕیارێکی تەندروستی، پرس بە پزیشکەکەت بکە.'],
      ['فریاکەوتن', 'ئەگەر هەستت بە ئازاری سنگ، هەناسەتەنگی یان هەر نیشانەیەکی مەترسیدار کرد، چاوەڕێی ئاگادارکردنەوەی ئەپەکە مەکە و یەکسەر پەیوەندی بە 122 ـەوە بکە.'],
      ['هەژمار و تەمەن', 'دەبێت تەمەنت 18 ساڵ یان زیاتر بێت؛ ئەگەر کەمتر بێت، دەبێت دایک یان باوکت ڕازی بێت. زانیارییەکانت ڕاست بنووسە و هەژمارەکەت بپارێزە. هەر کاتێک بتەوێت، دەتوانیت لە پرۆفایلەوە هەژمارەکەت بسڕیتەوە.'],
      ['VEX Band', 'دروستیی پێوانەکان بە شێوەی لەدەستکردنی Band، جووڵەت و ئاستی باتری دەگۆڕێت. Band لە ئاو و لێدان بپارێزە و تەنها بە شەحنکەری خۆی شەحنی بکە.'],
      ['زیرەکیی دەستکرد و خواردن', 'سکانی خواردن، کالۆری و وەڵامەکانی VEX AI خەمڵاندنن و لەوانەیە هەڵەیان تێدابێت. ئەگەر ئەلێرجی یان نەخۆشییەکی درێژخایەنت هەیە، پێکهاتەی خواردنەکە خۆت پشتڕاست بکەرەوە.'],
      ['بازنەی خێزان و هاوڕێ', 'تەنها خۆت بڕیار دەدەیت چی هاوبەش بکەیت و هەر کاتێک بتەوێت دەتوانیت بیگۆڕیت. تەنها ئەو کەسانە بانگهێشت بکە کە دەیانناسیت، و زانیاریی تەندروستیی کەسانی تر مەدە بە هیچ کەسێک.'],
      ['VEX Plus', 'پارەدان لە ڕێگەی Google Play یان App Store دەکرێت و بەشداربوون خۆکار نوێ دەبێتەوە. هەر کاتێک بتەوێت، دەتوانیت لە ڕێکخستنەکانی فرۆشگاکەوە هەڵیبوەشێنیتەوە. کاتێک ماوەی خۆڕایی تەواو دەبێت، بەشداربوون بە پارە بەردەوام دەبێت، مەگەر پێشتر هەڵیبوەشێنیتەوە.'],
      ['VEX Arena و بەکارهێنانی دروست', 'خاڵ و خەڵاتەکان پارە نین و ناگوازرێنەوە. ڕێگە نادرێت بە فێڵکردن لە خاڵەکان، بە کۆپیکردن یان فرۆشتنەوەی ئەپەکە، یان بە بەکارهێنانی بۆ کاری نایاسایی؛ پێشێلکردنی ئەمانە دەبێتە هۆی ڕاگرتنی هەژمارەکەت.'],
      ['داتا و مافی خاوەندارێتی', 'داتاکانت هی خۆتن و هەرگیز نایانفرۆشین. ناو، لۆگۆ، دیزاین و کۆدی VEX موڵکی VEX ـن و بە یاسا پارێزراون.'],
      ['بەرپرسیارێتی و گۆڕانکاری', 'VEX وەک خۆی پێشکەش دەکرێت. بەرپرسیار نین لە هیچ زیانێک کە لە پشتبەستن بە پێوانەکان لە جیاتی پزیشک دروست بێت. ئەگەر ئەم مەرجانە گۆڕدران، لەناو ئەپەکەدا ئاگادارت دەکەینەوە. بۆ هەر پرسیارێک، لە پرۆفایلەوە پەیوەندیمان پێوە بکە.'],
    ],
    thanks: 'سوپاس کە VEX ـت هەڵبژارد 💚',
  ),

  // ───────── کوردیی بادینی ─────────
  'kmr': TermsDoc(
    rtl: true,
    title: 'مەرجێن بکارئینانا VEX',
    updated: 'دووماهیک نووکرن: 30ێ چریا ئێکێ 2026',
    sections: [
      ['ڕازیبوون', 'ب دروستکرنا هەژمارەکێ یان بکارئینانا VEX، تو ڕازی دبی ب ڤان مەرجان و ب سیاسەتا پاراستنا نهێنیێ.'],
      ['شیرەتا پزیشکی نینە', 'VEX تنێ بۆ ساخلەمیا گشتییە. پیڤان و ڕاپۆرتێن وێ نە دەستنیشانکرنا نەخۆشیێ و نە چارەسەرینە. بەری هەر بڕیارەکا ساخلەمیێ، پسیارێ ژ پزیشکێ خۆ بکە.'],
      ['فریاکەفتن', 'ئەگەر تە هەست ب ئێشا سنگی، تەنگیا بێهنێ یان هەر نیشانەکا مەترسیدار کر، چاڤەڕێی ئاگەهدارکرنا ئەپی نەبە و دەستبەجێ پەیوەندیێ ب 122 ڤە بکە.'],
      ['هەژمار و ژی', 'پێدڤییە ژیێ تە 18 ساڵ یان پتر بیت؛ ئەگەر کێمتر بیت، دڤێت دایک یان بابێ تە ڕازی بن. زانیاریێن خۆ ب دروستی بنڤیسە و هەژمارا خۆ بپارێزە. هەر دەمەکێ تە بڤێت، دشێی ژ پرۆفایلی هەژمارا خۆ ژێببەی.'],
      ['VEX Band', 'دروستیا پیڤانان ل دویڤ شێوازێ گرێدانا Band، لڤینا تە و ئاستێ باتریێ دهێتە گوهۆڕین. Band ژ ئاڤێ و لێدانێ بپارێزە و تنێ ب شەحنکەرێ وێ شەحن بکە.'],
      ['زیرەکیا دەستکرد و خوارن', 'سکانا خوارنێ، کالۆری و بەرسڤێن VEX AI خەمڵاندنن و دبیت شاشی تێدا هەبن. ئەگەر تە ئەلێرجی یان نەخۆشیەکا درێژخایەن هەبیت، پێکهاتێن خوارنێ ب خۆ پشتڕاست بکە.'],
      ['بازنێ خێزان و هەڤالان', 'تنێ تو بڕیارێ ددەی کا دێ چ پارڤە کەی و هەر دەمەکێ تە بڤێت دشێی بگوهۆڕی. تنێ ئەو کەسێن تو دناسی داخواز بکە، و زانیاریێن ساخلەمیێ یێن کەسێن دی نەدە چ کەسان.'],
      ['VEX Plus', 'پارەدان ب ڕێکا Google Play یان App Store دهێتە کرن و بەشداربوون ب شێوەیەکێ خۆکار نوو دبیت. هەر دەمەکێ تە بڤێت، دشێی ژ ڕێکخستنێن فرۆشگەهێ هەلبوەشینی. دەمێ ماوێ بەلاش ب دووماهی دهێت، بەشداربوون ب پارە بەردەوام دبیت، ئەگەر تە بەری هینگێ هەلنەوەشاندبیت.'],
      ['VEX Arena و بکارئینانا دروست', 'خاڵ و خەلات نە پارەنە و ناهێنە ڤەگوهاستن. فێلکرن د خاڵاندا، کۆپیکرن یان فرۆتنا ئەپی، یان بکارئینانا وێ بۆ کارێن نەیاسایی ڕێپێدای نینە؛ و دبیتە ئەگەرێ ڕاگرتنا هەژمارا تە.'],
      ['داتا و مافێ خودانیێ', 'داتایێن تە یێن تەنە و ئەم چ جاران نافرۆشین. ناڤ، لۆگۆ، دیزاین و کۆدێ VEX موڵکێ VEX نە و ب یاسایێ پاراستینە.'],
      ['بەرپرسیاری و گوهۆڕین', 'VEX وەکی خۆ پێشکێش دبیت. ئەم نە بەرپرسیارین ژ هەر زیانەکێ ژ پشتبەستنێ ب پیڤانان ل جهێ پزیشکی پەیدا ببیت. ئەگەر ئەڤ مەرجە هاتنە گوهۆڕین، دێ د ناڤ ئەپیدا تە ئاگەهدار کەین. بۆ هەر پسیارەکێ، ژ پرۆفایلی پەیوەندیێ ب مە ڤە بکە.'],
    ],
    thanks: 'سوپاس کو تە VEX هەلبژارت 💚',
  ),

  // ───────── English ─────────
  'en': TermsDoc(
    rtl: false,
    title: 'VEX Terms of Use',
    updated: 'Last updated: October 30, 2026',
    sections: [
      ['Agreement', 'By creating an account or using VEX, you agree to these Terms of Use and our Privacy Policy.'],
      ['Not medical advice', 'VEX is for general wellness only. Its measurements and reports are not a diagnosis or a treatment. Consult your doctor before making any health decision.'],
      ['Emergencies', 'If you feel chest pain, shortness of breath or any other serious symptom, do not wait for an alert from the app — call 122 immediately.'],
      ['Account and age', 'You must be 18 or older; if you are younger, you need a parent\'s consent. Enter accurate information and keep your account secure. You can delete your account at any time from your Profile.'],
      ['VEX Band', 'The accuracy of measurements depends on how you wear the Band, your movement and the battery level. Protect the Band from water and impact, and charge it only with its own charger.'],
      ['AI and food', 'Food scans, calories and VEX AI answers are estimates and may contain errors. If you have an allergy or a chronic condition, check the ingredients yourself.'],
      ['Family & friends circle', 'You alone decide what to share, and you can change it at any time. Invite only people you know, and never pass on other people\'s health information to anyone.'],
      ['VEX Plus', 'Payments are made through Google Play or the App Store, and subscriptions renew automatically. You can cancel at any time in your store settings. When a free period ends, the paid subscription continues unless you cancel before then.'],
      ['VEX Arena and fair use', 'Points and rewards are not money and cannot be transferred. Cheating with points, copying or reselling the app, or using it for anything illegal is not allowed and will lead to your account being suspended.'],
      ['Data and ownership', 'Your data belongs to you, and we never sell it. The VEX name, logo, design and code are the property of VEX and are protected by law.'],
      ['Liability and changes', 'VEX is provided as is. We are not responsible for any harm caused by relying on its measurements instead of a doctor. If these terms change, we will let you know in the app. For any question, contact us from your Profile.'],
    ],
    thanks: 'Thank you for choosing VEX 💚',
  ),

  // ───────── العربية ─────────
  'ar': TermsDoc(
    rtl: true,
    title: 'شروط استخدام VEX',
    updated: 'آخر تحديث: 30 تشرين الأول 2026',
    sections: [
      ['الموافقة', 'بإنشاء حساب أو استخدام VEX، فإنك توافق على شروط الاستخدام هذه وعلى سياسة الخصوصية.'],
      ['ليست نصيحة طبية', 'VEX مخصص للصحة العامة فقط، وقياساته وتقاريره ليست تشخيصًا ولا علاجًا. استشر طبيبك قبل اتخاذ أي قرار صحي.'],
      ['حالات الطوارئ', 'إذا شعرت بألم في الصدر أو ضيق في التنفس أو أي عرض خطير، فلا تنتظر تنبيه التطبيق، واتصل فورًا بالرقم 122.'],
      ['الحساب والعمر', 'يجب أن يكون عمرك 18 عامًا أو أكثر، وإن كنت أصغر فيلزم موافقة أحد والديك. أدخل معلوماتك بدقة وحافظ على أمان حسابك، ويمكنك حذف حسابك في أي وقت من الملف الشخصي.'],
      ['VEX Band', 'تختلف دقة القياسات بحسب طريقة ارتداء السوار وحركتك ومستوى البطارية. احمِ السوار من الماء والصدمات، واشحنه بشاحنه الخاص فقط.'],
      ['الذكاء الاصطناعي والطعام', 'مسح الطعام والسعرات الحرارية وإجابات VEX AI تقديرات قد تحتوي على أخطاء. إذا كانت لديك حساسية أو مرض مزمن، فتحقق من مكونات الطعام بنفسك.'],
      ['دائرة العائلة والأصدقاء', 'أنت وحدك تقرر ما تشاركه، ويمكنك تغييره في أي وقت. ادعُ فقط من تعرفهم، ولا تُعطِ المعلومات الصحية للآخرين لأي شخص.'],
      ['VEX Plus', 'يتم الدفع عبر Google Play أو App Store، ويتجدد الاشتراك تلقائيًا. يمكنك إلغاؤه في أي وقت من إعدادات المتجر. وعند انتهاء الفترة المجانية يستمر الاشتراك المدفوع ما لم تُلغِه قبل ذلك.'],
      ['VEX Arena والاستخدام السليم', 'النقاط والجوائز ليست أموالًا ولا يمكن نقلها. لا يُسمح بالغش في النقاط أو نسخ التطبيق أو إعادة بيعه أو استخدامه لأي غرض غير قانوني، ومخالفة ذلك تؤدي إلى إيقاف حسابك.'],
      ['البيانات والملكية', 'بياناتك ملكٌ لك ولن نبيعها أبدًا. اسم VEX وشعاره وتصميمه وشيفرته ملكٌ لـ VEX ومحمية بموجب القانون.'],
      ['المسؤولية والتعديلات', 'يُقدَّم VEX كما هو. لسنا مسؤولين عن أي ضرر ينتج عن الاعتماد على قياساته بدلًا من الطبيب. إذا تغيّرت هذه الشروط فسنُعلمك داخل التطبيق، ولأي سؤال تواصل معنا من الملف الشخصي.'],
    ],
    thanks: 'شكرًا لاختيارك VEX 💚',
  ),

  // ───────── فارسی ─────────
  'fa': TermsDoc(
    rtl: true,
    title: 'شرایط استفاده از VEX',
    updated: 'آخرین به‌روزرسانی: 30 اکتبر 2026',
    sections: [
      ['موافقت', 'با ساختن حساب یا استفاده از VEX، با این شرایط استفاده و سیاست حریم خصوصی موافقت می‌کنید.'],
      ['توصیه پزشکی نیست', 'VEX فقط برای سلامت عمومی است و اندازه‌گیری‌ها و گزارش‌های آن تشخیص یا درمان نیستند. پیش از هر تصمیم درباره سلامت خود، با پزشکتان مشورت کنید.'],
      ['شرایط اضطراری', 'اگر درد قفسه سینه، تنگی نفس یا هر نشانه خطرناکی داشتید، منتظر هشدار برنامه نمانید و فوراً با 122 تماس بگیرید.'],
      ['حساب و سن', 'باید 18 سال یا بیشتر داشته باشید؛ اگر کمتر هستید، رضایت یکی از والدین لازم است. اطلاعات خود را درست وارد کنید و از حسابتان محافظت کنید. هر زمان بخواهید، می‌توانید حساب خود را از نمایه حذف کنید.'],
      ['VEX Band', 'دقت اندازه‌گیری‌ها به نحوه بستن Band، حرکت شما و سطح باتری بستگی دارد. Band را از آب و ضربه محافظت کنید و فقط با شارژر خودش شارژ کنید.'],
      ['هوش مصنوعی و غذا', 'اسکن غذا، کالری و پاسخ‌های VEX AI تخمینی هستند و ممکن است خطا داشته باشند. اگر حساسیت غذایی یا بیماری مزمن دارید، ترکیبات غذا را خودتان بررسی کنید.'],
      ['حلقه خانواده و دوستان', 'فقط خودتان تصمیم می‌گیرید چه چیزی را به اشتراک بگذارید و هر زمان می‌توانید آن را تغییر دهید. فقط افرادی را که می‌شناسید دعوت کنید و اطلاعات سلامت دیگران را در اختیار هیچ‌کس قرار ندهید.'],
      ['VEX Plus', 'پرداخت از طریق Google Play یا App Store انجام می‌شود و اشتراک به‌طور خودکار تمدید می‌شود. هر زمان بخواهید، می‌توانید آن را از تنظیمات فروشگاه لغو کنید. با پایان دوره رایگان، اشتراک پولی ادامه می‌یابد، مگر اینکه پیش از آن لغو کنید.'],
      ['VEX Arena و استفاده درست', 'امتیازها و جایزه‌ها پول نیستند و قابل انتقال نیستند. تقلب در امتیازها، کپی یا فروش دوباره برنامه و استفاده از آن برای کارهای غیرقانونی مجاز نیست و به تعلیق حساب شما منجر می‌شود.'],
      ['داده‌ها و مالکیت', 'داده‌های شما متعلق به خودتان است و هرگز آن‌ها را نمی‌فروشیم. نام، لوگو، طراحی و کد VEX متعلق به VEX است و طبق قانون محافظت می‌شود.'],
      ['مسئولیت و تغییرات', 'VEX همان‌گونه که هست ارائه می‌شود. ما مسئول آسیبی که از اتکا به اندازه‌گیری‌ها به‌جای پزشک ایجاد شود نیستیم. اگر این شرایط تغییر کند، در برنامه به شما اطلاع می‌دهیم. برای هر پرسشی، از طریق نمایه با ما در تماس باشید.'],
    ],
    thanks: 'از اینکه VEX را انتخاب کردید سپاسگزاریم 💚',
  ),

  // ───────── Türkçe ─────────
  'tr': TermsDoc(
    rtl: false,
    title: 'VEX Kullanım Koşulları',
    updated: 'Son güncelleme: 30 Ekim 2026',
    sections: [
      ['Onay', 'Bir hesap oluşturarak veya VEX\'i kullanarak bu Kullanım Koşullarını ve Gizlilik Politikamızı kabul etmiş olursunuz.'],
      ['Tıbbi tavsiye değildir', 'VEX yalnızca genel sağlık içindir; ölçümleri ve raporları teşhis ya da tedavi değildir. Sağlıkla ilgili her karardan önce doktorunuza danışın.'],
      ['Acil durumlar', 'Göğüs ağrısı, nefes darlığı veya herhangi bir ciddi belirti hissederseniz uygulamanın uyarısını beklemeyin; hemen 122\'yi arayın.'],
      ['Hesap ve yaş', '18 yaşında veya daha büyük olmalısınız; daha küçükseniz ebeveyninizin onayı gerekir. Bilgilerinizi doğru girin ve hesabınızı güvende tutun. Hesabınızı istediğiniz zaman Profil\'den silebilirsiniz.'],
      ['VEX Band', 'Ölçümlerin doğruluğu Band\'in takılış şekline, hareketlerinize ve pil seviyesine göre değişir. Band\'i sudan ve darbelerden koruyun; yalnızca kendi şarj aletiyle şarj edin.'],
      ['Yapay zekâ ve beslenme', 'Yemek taraması, kaloriler ve VEX AI yanıtları tahminidir ve hata içerebilir. Alerjiniz veya kronik bir hastalığınız varsa yemeğin içeriğini kendiniz kontrol edin.'],
      ['Aile ve arkadaş çemberi', 'Neyi paylaşacağınıza yalnızca siz karar verirsiniz ve bunu istediğiniz zaman değiştirebilirsiniz. Yalnızca tanıdığınız kişileri davet edin ve başkalarının sağlık bilgilerini kimseyle paylaşmayın.'],
      ['VEX Plus', 'Ödemeler Google Play veya App Store üzerinden yapılır ve abonelik otomatik olarak yenilenir. Aboneliği istediğiniz zaman mağaza ayarlarından iptal edebilirsiniz. Ücretsiz dönem sona erdiğinde, öncesinde iptal etmediğiniz sürece ücretli abonelik devam eder.'],
      ['VEX Arena ve doğru kullanım', 'Puanlar ve ödüller para değildir ve devredilemez. Puanlarda hile yapmak, uygulamayı kopyalamak veya yeniden satmak ya da yasa dışı amaçlarla kullanmak yasaktır ve hesabınızın askıya alınmasına yol açar.'],
      ['Veriler ve mülkiyet', 'Verileriniz size aittir ve onları asla satmayız. VEX adı, logosu, tasarımı ve kodu VEX\'e aittir ve yasalarla korunmaktadır.'],
      ['Sorumluluk ve değişiklikler', 'VEX olduğu gibi sunulur. Doktor yerine ölçümlere güvenilmesinden doğan zararlardan sorumlu değiliz. Bu koşullar değişirse sizi uygulama içinde bilgilendiririz. Her türlü sorunuz için Profil\'den bize ulaşın.'],
    ],
    thanks: 'VEX\'i seçtiğiniz için teşekkürler 💚',
  ),
};

// ═════════════════════════════ پەڕە ═════════════════════════════
class TermsOfUsePage extends StatelessWidget {
  const TermsOfUsePage({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([LangState.I, VexTheme.I]),
      builder: (context, _) {
        final d = termsOfUse();
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
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 26),
                      decoration: BoxDecoration(
                        color: V.surf,
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: V.line2),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // نیشانە + ناونیشان
                          Row(
                            children: [
                              Container(
                                width: 46,
                                height: 46,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: op(V.cy, 0.12),
                                  border: Border.all(color: op(V.cy, 0.4)),
                                ),
                                child: Icon(Icons.verified_user_rounded, color: V.cy, size: 24),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(d.title, style: ku(21, w: FontWeight.w800, h: 1.4)),
                                    const SizedBox(height: 2),
                                    Text(d.updated, style: ku(12.5, w: FontWeight.w600, c: V.mu)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Divider(color: V.line, height: 24),
                          for (var i = 0; i < d.sections.length; i++) _section(i + 1, d.sections[i][0], d.sections[i][1], i == 2),
                          const SizedBox(height: 18),
                          Text(
                            d.thanks,
                            textAlign: TextAlign.center,
                            style: ku(15, w: FontWeight.w800, c: V.mint, h: 1.6),
                          ),
                        ],
                      ),
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

  /// یەک بەش: ژمارە + سەردێڕ + دەق. بەشی فریاکەوتن ڕەنگی سووری هەیە.
  Widget _section(int n, String head, String body, bool urgent) {
    final k = urgent ? V.coral : V.cy;
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            margin: const EdgeInsets.only(top: 2),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(9),
              color: op(k, 0.14),
              border: Border.all(color: op(k, 0.45)),
            ),
            child: Text('$n', style: nu(12.5, c: k)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(head, style: ku(16, w: FontWeight.w800, c: k, h: 1.5)),
                const SizedBox(height: 4),
                Text(body, style: ku(14.5, w: FontWeight.w500, c: V.tx, h: 1.85)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
