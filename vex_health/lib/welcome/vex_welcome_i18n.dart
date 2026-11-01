// =============================================================================
//  VEX Health — دەقەکانی شاشەی بەخێرهاتن بە هەر 6 زمان
//  کوردی سۆرانی · کوردی بادینی · English · العربية · فارسی · Türkçe
//
//  بۆ گۆڕینی هەر دەقێک تەنها ئەم فایلە دەستکاری بکە.
//  feats: 31 تایبەتمەندی بە هەمان ڕیزبەندی kWelcomeRows لە vex_welcome.dart
// =============================================================================

class WelcomeLang {
  const WelcomeLang({
    required this.code,
    required this.native,
    required this.flag,
    required this.rtl,
    required this.title,
    required this.para,
    required this.statFeatures,
    required this.statAi,
    required this.statCare,
    required this.start,
    required this.login,
    required this.terms,
    required this.feats,
  });

  /// ckb · kmr · en · ar · fa · tr
  final String code;

  /// ناوی زمان بە خۆی
  final String native;

  /// ئیمۆجی ئاڵا؛ 'KU' = ئاڵای کوردستان (دەکێشرێت)
  final String flag;
  final bool rtl;

  /// «بەخێربێیت بۆ»
  final String title;

  /// ڕستەی ژێر ناونیشان
  final String para;

  /// «تایبەتمەندی» · «ی کوردی» (دوای AI) · «چاودێری» (دوای 24/7)
  final String statFeatures, statAi, statCare;

  /// دوگمەی «دەستپێکردن»
  final String start;

  /// «پێشتر هەژمارم هەیە · چوونە ژوورەوە»
  final String login;

  /// دەقی مەرجەکان لە خوارەوە
  final String terms;

  /// 31 تایبەتمەندی
  final List<String> feats;
}

const WelcomeLang kWelcomeCkb = WelcomeLang(
  code: 'ckb',
  native: 'کوردی سۆرانی',
  flag: 'KU',
  rtl: true,
  title: 'بەخێربێیت بۆ',
  para: 'تەندروستی، خواردن و وەرزش لە یەک ئەپدا، بە زیرەکی دەستکرد و بە زمانی کوردی.',
  statFeatures: 'تایبەتمەندی',
  statAi: 'ی کوردی',
  statCare: 'چاودێری',
  start: 'دەستپێکردن',
  login: 'پێشتر هەژمارم هەیە · چوونە ژوورەوە',
  terms: 'بە دەستپێکردن، ڕازی دەبیت بە مەرجەکانی بەکارهێنان و سیاسەتی پاراستنی نهێنی VEX.',
  feats: [
    'لێدانی دڵ 24/7',
    'ECG ی دڵ',
    'ئۆکسجینی خوێن',
    'سترێس و HRV',
    'شیکاری خەو',
    'پلەی گەرمی پێست',
    'تەمەنی جەستە',
    'ئاگاداری نائاسایی',
    'سکانی خواردن بە AI',
    'پلانی ژەمی تایبەت',
    'کالۆری و پڕۆتین',
    'ئاوی ڕۆژانە',
    'ئامانجی کێش',
    'ڕاهێنەری خۆراک',
    'ئاگاداری هەستیاری',
    'ڤیتامین و کانزا',
    'VEX AI بە کوردی',
    'کورتەی تەندروستی AI',
    'وەرزش و تایمەر',
    'هەنگاو و جووڵە',
    'هەناسە و ئارامی',
    'ڕاپۆرتی هەفتانە',
    'یادخستنەوەی زیرەک',
    'مێژووی تەندروستی',
    'بازنەی خێزان',
    'VEX Arena',
    'خاڵ و خەڵات',
    'VEX Band',
    'ئاگاداری فریاکەوتن',
    'پاراستنی نهێنی',
    'کاتی خەوتنی زیرەک',
  ],
);

const WelcomeLang kWelcomeKmr = WelcomeLang(
  code: 'kmr',
  native: 'کوردی بادینی',
  flag: 'KU',
  rtl: true,
  title: 'بخێر بێی بۆ',
  para: 'ساخلەمی، خوارن و وەرزش د ئێک ئەپێ دا، ب زیرەکیا دەستکرد.',
  statFeatures: 'تایبەتمەندی',
  statAi: 'یا کوردی',
  statCare: 'چاڤدێری',
  start: 'دەست پێ بکە',
  login: 'من ژ بەری نوکە ئەکاونتەک هەیە · چوونە ژوورڤە',
  terms: 'ب دەستپێکرنێ، تو ڕازی دبی ب مەرجێن بکارئینانێ و سیاسەتا پاراستنا نهێنیێ یا VEX.',
  feats: [
    'لێدانا دلی 24/7',
    'ECG یا دلی',
    'ئۆکسجینا خوینێ',
    'ستریس و HRV',
    'شرۆڤەکرنا خەوێ',
    'پلا گەرماتیا پێستی',
    'تەمەنێ لەشی',
    'ئاگەهداریا نەئاسایی',
    'سکانا خوارنێ ب AI',
    'پلانا ژەمێن تایبەت',
    'کالۆری و پڕۆتین',
    'ئاڤا ڕۆژانە',
    'ئارمانجا کێشێ',
    'ڕاهێنەرێ خوارنێ',
    'ئاگەهداریا هەستیاریێ',
    'ڤیتامین و کانزا',
    'VEX AI ب کوردی',
    'کورتیا ساخلەمیێ ب AI',
    'وەرزش و تایمەر',
    'هەنگاڤ و لڤین',
    'بێهنڤەدان و ئارامی',
    'ڕاپۆرتا حەفتیانە',
    'بیرئینانا زیرەک',
    'دیرۆکا ساخلەمیێ',
    'بازنەیا مالباتێ',
    'VEX Arena',
    'خال و خەلات',
    'VEX Band',
    'ئاگەهداریا فریاکەفتنێ',
    'پاراستنا نهێنیان',
    'دەمێ نڤستنا زیرەک',
  ],
);

const WelcomeLang kWelcomeEn = WelcomeLang(
  code: 'en',
  native: 'English',
  flag: '🇬🇧',
  rtl: false,
  title: 'Welcome to',
  para: 'Health, food and fitness in one app, powered by AI.',
  statFeatures: 'features',
  statAi: 'assistant',
  statCare: 'monitoring',
  start: 'Get started',
  login: 'I already have an account · Log in',
  terms: 'By continuing, you agree to the VEX Terms of Use and Privacy Policy.',
  feats: [
    'Heart monitoring 24/7',
    'ECG',
    'Blood oxygen',
    'Stress & HRV',
    'Sleep analysis',
    'Skin temperature',
    'Body age',
    'Abnormal alerts',
    'AI food scan',
    'Personal meal plan',
    'Calories & protein',
    'Daily water',
    'Weight goal',
    'Nutrition coach',
    'Allergy alerts',
    'Vitamins & minerals',
    'VEX AI assistant',
    'AI health summary',
    'Workouts & timer',
    'Steps & movement',
    'Breathing & calm',
    'Weekly report',
    'Smart reminders',
    'Health history',
    'Family circle',
    'VEX Arena',
    'Points & rewards',
    'VEX Band',
    'Emergency alerts',
    'Privacy first',
    'Smart bedtime',
  ],
);

const WelcomeLang kWelcomeAr = WelcomeLang(
  code: 'ar',
  native: 'العربية',
  flag: '🇸🇦',
  rtl: true,
  title: 'مرحباً بك في',
  para: 'الصحة والتغذية والرياضة في تطبيق واحد، بالذكاء الاصطناعي.',
  statFeatures: 'ميزة',
  statAi: 'ذكاء اصطناعي',
  statCare: 'مراقبة',
  start: 'ابدأ الآن',
  login: 'لدي حساب بالفعل · تسجيل الدخول',
  terms: 'بالمتابعة، فإنك توافق على شروط الاستخدام وسياسة الخصوصية الخاصة بـ VEX.',
  feats: [
    'مراقبة القلب 24/7',
    'تخطيط القلب',
    'أكسجين الدم',
    'التوتر وHRV',
    'تحليل النوم',
    'حرارة الجلد',
    'عمر الجسم',
    'تنبيهات غير طبيعية',
    'مسح الطعام بالذكاء الاصطناعي',
    'خطة وجبات شخصية',
    'السعرات والبروتين',
    'الماء اليومي',
    'هدف الوزن',
    'مدرب التغذية',
    'تنبيهات الحساسية',
    'فيتامينات ومعادن',
    'مساعد VEX AI',
    'ملخص صحي بالذكاء الاصطناعي',
    'التمارين والمؤقت',
    'الخطوات والحركة',
    'التنفس والهدوء',
    'التقرير الأسبوعي',
    'تذكيرات ذكية',
    'السجل الصحي',
    'دائرة العائلة',
    'VEX Arena',
    'نقاط ومكافآت',
    'VEX Band',
    'تنبيهات الطوارئ',
    'الخصوصية أولاً',
    'وقت النوم الذكي',
  ],
);

const WelcomeLang kWelcomeFa = WelcomeLang(
  code: 'fa',
  native: 'فارسی',
  flag: '🇮🇷',
  rtl: true,
  title: 'خوش آمدید به',
  para: 'سلامت، تغذیه و ورزش در یک برنامه، با هوش مصنوعی.',
  statFeatures: 'ویژگی',
  statAi: 'هوش مصنوعی',
  statCare: 'پایش',
  start: 'شروع',
  login: 'قبلاً حساب دارم · ورود',
  terms: 'با ادامه، با شرایط استفاده و سیاست حریم خصوصی VEX موافقت می‌کنید.',
  feats: [
    'پایش قلب ۲۴/۷',
    'نوار قلب',
    'اکسیژن خون',
    'استرس و HRV',
    'تحلیل خواب',
    'دمای پوست',
    'سن بدن',
    'هشدارهای غیرعادی',
    'اسکن غذا با هوش مصنوعی',
    'برنامهٔ غذایی شخصی',
    'کالری و پروتئین',
    'آب روزانه',
    'هدف وزن',
    'مربی تغذیه',
    'هشدار حساسیت',
    'ویتامین‌ها و مواد معدنی',
    'دستیار VEX AI',
    'خلاصهٔ سلامت با هوش مصنوعی',
    'تمرین و زمان‌سنج',
    'قدم و حرکت',
    'تنفس و آرامش',
    'گزارش هفتگی',
    'یادآوری‌های هوشمند',
    'سابقهٔ سلامت',
    'حلقهٔ خانواده',
    'VEX Arena',
    'امتیاز و جایزه',
    'VEX Band',
    'هشدارهای اورژانسی',
    'اول حریم خصوصی',
    'زمان خواب هوشمند',
  ],
);

const WelcomeLang kWelcomeTr = WelcomeLang(
  code: 'tr',
  native: 'Türkçe',
  flag: '🇹🇷',
  rtl: false,
  title: 'Hoş geldin',
  para: 'Sağlık, beslenme ve spor tek uygulamada, yapay zekâ ile.',
  statFeatures: 'özellik',
  statAi: 'asistanı',
  statCare: 'takip',
  start: 'Başla',
  login: 'Zaten hesabım var · Giriş yap',
  terms: 'Devam ederek VEX Kullanım Koşulları ve Gizlilik Politikası\'nı kabul etmiş olursun.',
  feats: [
    '7/24 kalp takibi',
    'EKG',
    'Kan oksijeni',
    'Stres ve HRV',
    'Uyku analizi',
    'Cilt sıcaklığı',
    'Vücut yaşı',
    'Olağandışı uyarılar',
    'Yapay zekâ ile yemek taraması',
    'Kişisel öğün planı',
    'Kalori ve protein',
    'Günlük su',
    'Kilo hedefi',
    'Beslenme koçu',
    'Alerji uyarıları',
    'Vitamin ve mineraller',
    'VEX AI asistanı',
    'Yapay zekâ sağlık özeti',
    'Antrenman ve zamanlayıcı',
    'Adım ve hareket',
    'Nefes ve sakinlik',
    'Haftalık rapor',
    'Akıllı hatırlatıcılar',
    'Sağlık geçmişi',
    'Aile çemberi',
    'VEX Arena',
    'Puan ve ödüller',
    'VEX Band',
    'Acil durum uyarıları',
    'Önce gizlilik',
    'Akıllı yatma saati',
  ],
);

/// هەموو زمانەکان (ڕیزبەندی وەک شاشەی هەڵبژاردنی زمان)
const List<WelcomeLang> kWelcomeLangs = [kWelcomeCkb, kWelcomeKmr, kWelcomeEn, kWelcomeAr, kWelcomeFa, kWelcomeTr];

/// زمانی [code]؛ ئەگەر نەبوو کوردی سۆرانی
WelcomeLang welcomeLang(String code) => kWelcomeLangs.firstWhere((l) => l.code == code, orElse: () => kWelcomeCkb);
