# Per-language sentence templates (applied before dictionary segmentation).
# Pattern tokens: «N» = a number (latin/arabic/persian digits, ranges allowed).
# Replacement: $1..$9 = captured group, translated again by the dictionary;
#              $!1 = captured group kept verbatim (names).
# Literal replacement text is protected from re-translation.
N = r'([\d٠-٩۰-۹](?:[\d٠-٩۰-۹.,\-–]*[\d٠-٩۰-۹])?)'
L = ['en', 'kmr', 'ar', 'fa', 'tr']

T = []
def t(p, en, kmr, ar, fa, tr):
    # en=None: leave English to the dictionary
    T.append((p.replace('«N»', N), {'en': en, 'kmr': kmr, 'ar': ar, 'fa': fa, 'tr': tr}))

# ---- AI / sample answers -------------------------------------------------
t(r'ئەمە وەڵامی نموونەیە، چونکە AI لە دەرەوەی Claude کار ناکات\.',
  "This is a sample answer, because AI doesn't work outside Claude.",
  'ئەڤە بەرسڤەکا نموونەیە، چونکی AI ل دەرڤەی Claude کار ناکەت.',
  'هذه إجابة تجريبية، لأن AI لا يعمل خارج Claude.',
  'این یک پاسخ نمونه است، چون AI بیرون از Claude کار نمی‌کند.',
  'Bu örnek bir yanıttır, çünkü AI Claude dışında çalışmaz.')
t(r'لە ناو Claude ئەم بەشە ڕاستەوخۆ وەڵامت دەداتەوە\.',
  'Inside Claude, this section answers you directly.',
  'د ناڤ Claude دا ئەڤ بەشە ڕاستەوخۆ بەرسڤا تە ددەت.',
  'داخل Claude يجيبك هذا القسم مباشرة.',
  'در Claude این بخش مستقیماً به شما پاسخ می‌دهد.',
  'Claude içinde bu bölüm sana doğrudan yanıt verir.')
t(r'ئەمە وەڵامی نموونەیە؛ AI تەنها لە ناو Claude کار دەکات\. لە کاتی مەترسیدا «N»\.',
  'This is a sample answer; AI only works inside Claude. In an emergency, call $1.',
  'ئەڤە بەرسڤەکا نموونەیە؛ AI تەنێ د ناڤ Claude دا کار دکەت. د دەمێ مەترسیێ دا پەیوەندیێ ب $1 بکە.',
  'هذه إجابة تجريبية؛ يعمل AI داخل Claude فقط. في حالات الطوارئ اتصل بـ $1.',
  'این یک پاسخ نمونه است؛ AI فقط داخل Claude کار می‌کند. در شرایط اضطراری با $1 تماس بگیرید.',
  'Bu örnek bir yanıttır; AI yalnızca Claude içinde çalışır. Acil durumda $1 numarasını ara.')
t(r'ئەمە نموونەیە: AI تەنها لە ناو Claude کار دەکات\. لەوێ ئەم بەشە ڕاستەوخۆ وەڵامت دەداتەوە\.',
  'This is a sample: AI only works inside Claude. There, this section answers you directly.',
  'ئەڤە نموونەیە: AI تەنێ د ناڤ Claude دا کار دکەت. ل وێرێ ئەڤ بەشە ڕاستەوخۆ بەرسڤا تە ددەت.',
  'هذا مثال: يعمل AI داخل Claude فقط. هناك يجيبك هذا القسم مباشرة.',
  'این یک نمونه است: AI فقط داخل Claude کار می‌کند. آنجا این بخش مستقیماً به شما پاسخ می‌دهد.',
  'Bu bir örnektir: AI yalnızca Claude içinde çalışır. Orada bu bölüm sana doğrudan yanıt verir.')
t(r'ئەم پەڕەیە لە Claude بکەرەوە، یان نموونەکە ببینە\.',
  'Open this page in Claude, or see the sample.',
  'ئەڤێ پەڕێ د Claude دا ڤەکە، یان نموونێ ببینە.',
  'افتح هذه الصفحة في Claude، أو اطّلع على النموذج.',
  'این صفحه را در Claude باز کنید یا نمونه را ببینید.',
  "Bu sayfayı Claude'da aç ya da örneği gör.")
t(r'AI تەنها لە ناو Claude کار دەکات',
  'AI only works inside Claude',
  'AI تەنێ د ناڤ Claude دا کار دکەت',
  'يعمل AI داخل Claude فقط',
  'AI فقط داخل Claude کار می‌کند',
  'AI yalnızca Claude içinde çalışır')
t(r'AI بە وردی سەیری هەموو بەشێکی قاپەکە دەکات\.',
  'AI carefully examines every part of the plate.',
  'AI ب هویری بەرێ خۆ ددەتە هەمی پشکێن قاپی.',
  'يفحص AI كل جزء من الطبق بدقة.',
  'AI همهٔ بخش‌های بشقاب را با دقت بررسی می‌کند.',
  'AI tabağın her bölümünü dikkatle inceler.')
t(r'زۆرجار «N» بۆ «N» چرکە دەخایەنێت\.',
  'It usually takes $1 to $2 seconds.',
  'پترییا جاران $1 هەتا $2 چرکەیان دڤێت.',
  'يستغرق عادةً من $1 إلى $2 ثانية.',
  'معمولاً $1 تا $2 ثانیه طول می‌کشد.',
  'Genellikle $1 ila $2 saniye sürer.')
t(r'ئەم وێنەیە ناخوێندرێتەوە\. وێنەیەکی JPG یان PNG هەڵبژێرە\.',
  "This photo can't be read. Choose a JPG or PNG photo.",
  'ئەڤ وێنەیە ناهێتە خواندن. وێنەیەکێ JPG یان PNG هەلبژێرە.',
  'تعذّرت قراءة هذه الصورة. اختر صورة JPG أو PNG.',
  'این عکس قابل خواندن نیست. یک عکس JPG یا PNG انتخاب کنید.',
  'Bu fotoğraf okunamıyor. JPG veya PNG bir fotoğraf seç.')

# ---- Nutrition advice ----------------------------------------------------
t(r'لە جیاتی «N» ژەم، «N» ژەمی بچووکتر بخۆ\.',
  'Instead of $1 meals, eat $2 smaller meals.',
  'ل جهێ $1 ژەمان، $2 ژەمێن بچووکتر بخۆ.',
  'بدلاً من $1 وجبات، تناول $2 وجبات أصغر.',
  'به جای $1 وعده، $2 وعدهٔ کوچک‌تر بخورید.',
  '$1 öğün yerine $2 küçük öğün ye.')
t(r'لە ماوەی «N» کاتژمێر دوای ڕاهێنان ژەمێکی پرۆتیندار بخۆ\.',
  'Within $1 hours after training, eat a protein-rich meal.',
  'د ماوێ $1 دەمژمێران دا پشتی ڕاهێنانێ ژەمەکا پرۆتیندار بخۆ.',
  'تناول وجبة غنية بالبروتين خلال $1 ساعة بعد التمرين.',
  'ظرف $1 ساعت پس از تمرین یک وعدهٔ پرپروتئین بخورید.',
  'Antrenmandan sonraki $1 saat içinde proteinli bir öğün ye.')
t(r'لە ماوەی «N» کاتژمێردا «N» گرام پرۆتین لەگەڵ کارب بخۆ، و «N} ?ml ئاوی زیادە بخۆرەوە\.'.replace('«N}', '«N»'),
  'Within $1 hours, eat $2 g of protein with carbs, and drink an extra $3 ml of water.',
  'د ماوێ $1 دەمژمێران دا $2 گرام پرۆتین دگەل کاربێ بخۆ، و $3 ml ئاڤا زێدە ڤەخۆ.',
  'خلال $1 ساعة تناول $2 غ من البروتين مع الكربوهيدرات، واشرب $3 مل إضافية من الماء.',
  'ظرف $1 ساعت $2 گرم پروتئین همراه با کربوهیدرات بخورید و $3 میلی‌لیتر آب اضافه بنوشید.',
  '$1 saat içinde karbonhidratla birlikte $2 g protein ye ve fazladan $3 ml su iç.')
t(r'«N» کم ڕاتکرد',
  'You ran $1 km', 'تە $1 km ڕەڤی', 'ركضت $1 كم', '$1 کیلومتر دویدید', '$1 km koştun')
t(r'«N» خولەک وەرزشت کرد',
  'You worked out for $1 minutes', 'تە $1 دەقان وەرزش کر', 'تمرّنت $1 دقيقة', '$1 دقیقه ورزش کردید', '$1 dakika spor yaptın')
t(r'، «N» کالۆری سووتا\.',
  ', burning $1 calories.', '، $1 کالۆری سۆتن.', '، وحرقت $1 سعرة حرارية.', '، $1 کالری سوزاندید.', ', $1 kalori yaktın.')
t(r'لە هەر ژەمێکدا «N» گرام پرۆتین بخۆ: ',
  'Eat $1 g of protein at every meal: ',
  'د هەر ژەمەکێ دا $1 گرام پرۆتین بخۆ: ',
  'تناول $1 غ من البروتين في كل وجبة: ',
  'در هر وعده $1 گرم پروتئین بخورید: ',
  'Her öğünde $1 g protein ye: ')
t(r'«N» کاتژمێر پێش ڕاهێنان کارب بخۆ ',
  'Eat carbs $1 hours before training ',
  '$1 دەمژمێران بەری ڕاهێنانێ کاربێ بخۆ ',
  'تناول الكربوهيدرات قبل التمرين بـ $1 ساعة ',
  '$1 ساعت پیش از تمرین کربوهیدرات بخورید ',
  'Antrenmandan $1 saat önce karbonhidrat ye ')
t(r'(^|\s)«N» کاتژمێر بخەوە؛ ',
  '$!1Sleep $2 hours; ', '$!1$2 دەمژمێران بنڤە؛ ', '$!1نم $2 ساعات؛ ', '$!1$2 ساعت بخوابید؛ ', '$!1$2 saat uyu; ')
t(r'ڕۆژانە «N» خولەک هەتاوی بەیانی بۆ ڤیتامین D باشە\.',
  '$1 minutes of morning sun daily is good for vitamin D.',
  'ڕۆژانە $1 دەقە تاڤا سپێدێ بۆ ڤیتامین D باشە.',
  'التعرّض لشمس الصباح $1 دقيقة يومياً مفيد لفيتامين D.',
  'روزانه $1 دقیقه آفتاب صبح برای ویتامین D خوب است.',
  'Günde $1 dakika sabah güneşi D vitamini için iyidir.')
t(r'ڕۆژانە شیرەمەنی بخۆ بۆ کالسیۆم، و «N» خولەک هەتاوی بەیانی بۆ ڤیتامین D\.',
  'Eat dairy daily for calcium, and get $1 minutes of morning sun for vitamin D.',
  'ڕۆژانە شیرەمەنیان بخۆ بۆ کالسیۆمێ، و $1 دەقە تاڤا سپێدێ بۆ ڤیتامین D.',
  'تناول مشتقات الحليب يومياً للكالسيوم، وتعرّض لشمس الصباح $1 دقيقة لفيتامين D.',
  'روزانه برای کلسیم لبنیات بخورید و برای ویتامین D $1 دقیقه در آفتاب صبح باشید.',
  'Kalsiyum için her gün süt ürünleri tüket ve D vitamini için $1 dakika sabah güneşi al.')
t(r'لە کاتی بەکارهێنانی مۆبایل، هەر «N» خولەک جارێک «N» چرکە سەیری شوێنێکی دوور بکە\.',
  'When using your phone, look at something far away for $2 seconds every $1 minutes.',
  'د دەمێ بکارئینانا مۆبایلێ دا، هەر $1 دەقان جارەکێ $2 چرکەیان بەرێ خۆ بدە جهەکێ دویر.',
  'عند استخدام الهاتف، انظر إلى شيء بعيد لمدة $2 ثانية كل $1 دقيقة.',
  'هنگام استفاده از موبایل، هر $1 دقیقه یک بار $2 ثانیه به نقطه‌ای دور نگاه کنید.',
  'Telefon kullanırken her $1 dakikada bir $2 saniye uzak bir noktaya bak.')
t(r'ئەمە لە بودجەی ماوەی ئەمڕۆت \(«N» kcal\) زیاترە\.',
  "This exceeds what's left of today's budget ($1 kcal).",
  'ئەڤە ژ بودجەیا مای یا ئەڤرۆ ($1 kcal) پترە.',
  'هذا يتجاوز المتبقي من ميزانية اليوم ($1 kcal).',
  'این از باقی‌ماندهٔ بودجهٔ امروز شما ($1 kcal) بیشتر است.',
  'Bu, bugünkü kalan bütçeni ($1 kcal) aşıyor.')

# ---- Children ------------------------------------------------------------
t(r'پرۆفایلی (.+?) دروست کرا\.',
  "$!1's profile has been created.", 'پرۆفایلا $!1 هاتە دروستکرن.', 'تم إنشاء ملف $!1.',
  'پروفایل $!1 ساخته شد.', '$!1 için profil oluşturuldu.')
t(r'تا «N» مانگ هیچ خواردن و ئاوێک پێویست نییە؛ شیری دایک یان قوتوو بەسە\.',
  'Until $1 months, no food or water is needed; breast milk or formula is enough.',
  'هەتا $1 هەیڤان چ خوارن و ئاڤ پێدڤی نینن؛ شیرێ دایکێ یان شیرێ قوتیێ بەسە.',
  'حتى عمر $1 أشهر لا حاجة لأي طعام أو ماء؛ حليب الأم أو الحليب الصناعي يكفي.',
  'تا $1 ماهگی هیچ غذا و آبی لازم نیست؛ شیر مادر یا شیر خشک کافی است.',
  '$1. aya kadar hiçbir yiyecek ya da suya gerek yoktur; anne sütü veya mama yeterlidir.')
t(r'بۆ منداڵی «N» ساڵ = «N» مانگ، «N» ساڵ = «N» مانگ\.',
  'A $1-year-old = $2 months, $3 years = $4 months.',
  'زارۆکێ $1 سالی = $2 هەیڤ، $3 سال = $4 هەیڤ.',
  'الطفل بعمر $1 سنة = $2 شهراً، و$3 سنوات = $4 شهراً.',
  'کودک $1 ساله = $2 ماه، $3 ساله = $4 ماه.',
  '$1 yaşındaki çocuk = $2 ay, $3 yaş = $4 ay.')
t(r'بۆ منداڵی سەروو «N» ساڵ، پرۆفایلی گەورە بەکاربهێنە\.',
  'For a child over $1 years, use an adult profile.',
  'بۆ زارۆکێ ژ $1 سالان مەزنتر، پرۆفایلا مەزنان بکاربینە.',
  'للطفل فوق $1 سنوات استخدم ملف شخص بالغ.',
  'برای کودک بالای $1 سال از پروفایل بزرگسال استفاده کنید.',
  '$1 yaşından büyük çocuk için yetişkin profili kullan.')
t(r'زیاتر لە «N» کاتژمێر لە کۆرپەدا',
  'More than $1 hours in an infant', 'پتر ژ $1 دەمژمێران ل زارۆکێ ساڤا', 'أكثر من $1 ساعة عند الرضيع',
  'بیش از $1 ساعت در نوزاد', 'Bebekte $1 saatten uzun')
t(r'زیاتر لە «N» ڕۆژ',
  'More than $1 days', 'پتر ژ $1 ڕۆژان', 'أكثر من $1 أيام', 'بیش از $1 روز', '$1 günden uzun')
t(r'بۆ منداڵی سەروو «N» مانگ: ',
  'For a child over $1 months: ', 'بۆ زارۆکێ ژ $1 هەیڤان مەزنتر: ', 'للطفل فوق $1 أشهر: ',
  'برای کودک بالای $1 ماه: ', '$1 aydan büyük çocuk için: ')
t(r'بۆ سەروو «N» مانگ: ',
  'Over $1 months: ', 'بۆ سەروو $1 هەیڤان: ', 'لمن تجاوز $1 أشهر: ', 'برای بالای $1 ماه: ', '$1 aydan büyükler için: ')

# ---- Workouts / zones ----------------------------------------------------
t(r'زۆرترین کاتت \(«N»[٪%]\) لە ناوچەی «(.+?)» بوو\.',
  'You spent most of your time ($1%) in the «$2» zone.',
  'پترییا دەمێ تە ($1٪) د ناڤچەیا «$2» دا بوو.',
  'قضيت معظم وقتك ($1٪) في نطاق «$2».',
  'بیشتر وقت شما ($1٪) در محدودهٔ «$2» بود.',
  'Zamanının çoğunu (%$1) «$2» bölgesinde geçirdin.')
t(r'زۆرترین کاتت لەسەر «(.+?)» بوو \(«N» خولەک\)\.',
  'You spent most of your time on «$1» ($2 minutes).',
  'پترییا دەمێ تە ل سەر «$1» بوو ($2 دەقە).',
  'قضيت معظم وقتك في «$1» ($2 دقيقة).',
  'بیشتر وقت شما صرف «$1» شد ($2 دقیقه).',
  'Zamanının çoğunu «$1» ile geçirdin ($2 dakika).')
t(r'بۆ دەستپێک «N» خولەک پیاسە لەگەڵ نەخشە باشە؛ ئامانجێک دابنێ و Play بگرە\.',
  'To start, a $1-minute walk with the map is good; set a goal and tap Play.',
  'بۆ دەستپێکێ $1 دەقە پیاسە دگەل نەخشێ باشە؛ ئارمانجەکێ دانە و ل سەر Play بدە.',
  'للبداية، المشي $1 دقيقة مع الخريطة جيد؛ حدّد هدفاً واضغط Play.',
  'برای شروع، $1 دقیقه پیاده‌روی با نقشه خوب است؛ یک هدف تعیین کنید و Play را بزنید.',
  "Başlangıç için haritayla $1 dakikalık yürüyüş iyidir; bir hedef belirle ve Play'e dokun.")
t(r'ناوەندی لێدانی دڵت «N» بوو\.',
  'Your average heart rate was $1.', 'تێکڕایا لێدانا دلێ تە $1 بوو.', 'كان متوسط نبض قلبك $1.',
  'میانگین ضربان قلب شما $1 بود.', 'Ortalama nabzın $1 idi.')
t(r'بەرامبەر بە ماوەی پێشوو «N»[٪%] کالۆری زیاتر سووتاندووە، ئافەرین\.',
  'Compared with the previous period, you burned $1% more calories. Well done.',
  'بەرامبەر ماوێ بەری نوکە، تە $1٪ کالۆری پتر سۆتینە، دەستخۆش.',
  'مقارنةً بالفترة السابقة، حرقت سعرات أكثر بنسبة $1٪، أحسنت.',
  'نسبت به دورهٔ قبل $1٪ کالری بیشتری سوزانده‌اید، آفرین.',
  'Önceki döneme göre %$1 daha fazla kalori yaktın, aferin.')
t(r'بەرامبەر بە ماوەی پێشوو «N»[٪%] کەمتر بووە؛ «N» خولەک زیاد بکە\.',
  "That's $1% less than the previous period; add $2 minutes.",
  'بەرامبەر ماوێ بەری نوکە $1٪ کێمتر بوویە؛ $2 دەقان زێدە بکە.',
  'انخفض بنسبة $1٪ مقارنةً بالفترة السابقة؛ أضف $2 دقيقة.',
  'نسبت به دورهٔ قبل $1٪ کمتر شده؛ $2 دقیقه اضافه کنید.',
  'Önceki döneme göre %$1 daha az; $2 dakika ekle.')
t(r'هەوڵبدە لانیکەم «N» ڕۆژ لە هەفتەدا بجووڵێیت\.',
  'Try to move at least $1 days a week.', 'هەول بدە کێمترین $1 ڕۆژان د حەفتیێ دا بلڤی.',
  'حاول أن تتحرك $1 أيام في الأسبوع على الأقل.', 'سعی کنید حداقل $1 روز در هفته فعالیت کنید.',
  'Haftada en az $1 gün hareket etmeye çalış.')

# ---- Arena / power -------------------------------------------------------
t(r'هێزی ئەمڕۆ (.+?) بوو · \+«N» خاڵ',
  "Today's power was $1 · +$2 points", 'هێزا ئەڤرۆ $1 بوو · +$2 خال', 'كانت قوة اليوم $1 · +$2 نقطة',
  'قدرت امروز $1 بود · +$2 امتیاز', 'Bugünün gücü $1 idi · +$2 puan')
t(r'هێزی ئەمڕۆ (.+?) بوو · سبەینێ هێزێکی نوێ دەبێت',
  "Today's power was $1 · A new power tomorrow", 'هێزا ئەڤرۆ $1 بوو · سوبەهی دێ هێزەکا نوی هەبیت',
  'كانت قوة اليوم $1 · قوة جديدة غداً', 'قدرت امروز $1 بود · فردا قدرتی جدید', 'Bugünün gücü $1 idi · Yarın yeni bir güç')
t(r'کاتێک (.+?) ئەپی VEX دابەزێنێت و قبوڵی بکات، لێرە دەردەکەوێت\.',
  "When $!1 downloads the VEX app and accepts, they'll appear here.",
  'دەمێ $!1 ئەپێ VEX دابەزینیت و قەبوول بکەت، دێ ل ڤێرە دیار بیت.',
  'عندما يحمّل $!1 تطبيق VEX ويقبل الدعوة، سيظهر هنا.',
  'وقتی $!1 اپلیکیشن VEX را دانلود کند و بپذیرد، اینجا نمایش داده می‌شود.',
  '$!1 VEX uygulamasını indirip kabul ettiğinde burada görünecek.')
t(r'ئەزانی هێزی نهێنیی ئەمڕۆ چییە؟ ئەپی VEX دابەزێنە',
  "Do you know today's Secret Power? Download the VEX app",
  'تو دزانی هێزا نهێنی یا ئەڤرۆ چییە؟ ئەپێ VEX دابەزینە',
  'هل تعرف ما هي القوة السرية لليوم؟ حمّل تطبيق VEX',
  'می‌دانی قدرت مخفی امروز چیست؟ اپلیکیشن VEX را دانلود کن',
  "Bugünün Gizli Gücü'nü biliyor musun? VEX uygulamasını indir")
t(r'بەخێربێیت (.+?) · لە لیگی (.+?) دەست پێدەکەیت',
  "Welcome $!1 · you're starting in the $2 league", 'بخێر بێی $!1 · تو د لیگا $2 دا دەست پێ دکەی',
  'أهلاً بك $!1 · ستبدأ في دوري $2', 'خوش آمدید $!1 · در لیگ $2 شروع می‌کنید', 'Hoş geldin $!1 · $2 liginde başlıyorsun')
t(r'هەنگاو بێ بەرزبوونەوەی لێدانی دڵ ڕەت دەکرێتەوە، بۆیە لەقاندنی مۆبایل و Band کار ناکات\.',
  "Steps without a rise in heart rate are rejected, so shaking your phone and Band doesn't work.",
  'هەنگاڤێن بێ بلندبوونا لێدانا دلی دهێنە ڕەتکرن، لەوما هەژاندنا مۆبایلێ و Band کار ناکەت.',
  'تُرفض الخطوات التي لا يرافقها ارتفاع في نبض القلب، لذا لا يجدي هزّ الهاتف أو Band.',
  'قدم‌هایی که با افزایش ضربان قلب همراه نباشند رد می‌شوند، پس تکان دادن موبایل و Band فایده‌ای ندارد.',
  "Nabız artışı olmayan adımlar reddedilir, bu yüzden telefonu ve Band'i sallamak işe yaramaz.")
t(r'هەر ژمارەی مۆبایلێک یەک ئەکاونت، و هەر Band ـێک یەک کەس؛ گۆڕینی Band چاوەڕوانی «N» ڕۆژی هەیە\.',
  'One account per phone number, and one person per Band; changing your Band has a $1-day waiting period.',
  'هەر ژمارەکا مۆبایلێ ئێک ئەکاونت، و هەر Band ەک ئێک کەس؛ گوهۆڕینا Band پێدڤی ب $1 ڕۆژان چاڤەڕێکرنێ هەیە.',
  'حساب واحد لكل رقم هاتف، وشخص واحد لكل Band؛ تغيير Band يتطلب انتظار $1 أيام.',
  'هر شمارهٔ موبایل یک حساب، و هر Band یک نفر؛ تعویض Band $1 روز زمان انتظار دارد.',
  "Her telefon numarasına bir hesap, her Band'e bir kişi; Band değiştirmek için $1 gün beklemek gerekir.")
t(r'ڕۆژانە زۆرترین «N» خاڵ، و ئەگەر دوو کەس خاڵیان یەکسان بوو، ئەوەی ڕۆژی چالاکیی زیاترە پێشتر دەکەوێت\.',
  'A maximum of $1 points per day; if two people tie on points, the one with more active days ranks higher.',
  'ڕۆژانە پترین $1 خال، و ئەگەر خالێن دوو کەسان وەکی ئێک بن، یێ ڕۆژێن چالاکیێ پتر هەین دکەڤیتە پێشیێ.',
  'بحد أقصى $1 نقطة يومياً، وإذا تعادل شخصان في النقاط يتقدّم صاحب أيام النشاط الأكثر.',
  'حداکثر $1 امتیاز در روز؛ اگر امتیاز دو نفر برابر شود، کسی که روزهای فعال بیشتری دارد جلوتر قرار می‌گیرد.',
  'Günde en fazla $1 puan; iki kişinin puanı eşitse daha çok aktif günü olan öne geçer.')

# ---- Onboarding ----------------------------------------------------------
t(r'تا «N» دانە هەڵبژێرە\.',
  'Choose up to $1.', 'هەتا $1 دانان هەلبژێرە.', 'اختر حتى $1.', 'حداکثر $1 مورد انتخاب کنید.', 'En fazla $1 tane seç.')

# ---- Band / Plus phrases (Latin product names split Kurdish runs) ---------
t(r'Band ـەکەت پەیوەست بکە تا نمرە و نیشانە زیندووەکانت ببینیت',
  None, 'Band ێ خۆ گرێ بدە دا نمرە و نیشانێن خۆ یێن زیندی ببینی', 'صِل Band لترى درجتك ومؤشراتك المباشرة',
  'Band را وصل کنید تا امتیاز و شاخص‌های زندهٔ خود را ببینید', "Puanını ve canlı göstergelerini görmek için Band'ini bağla")
t(r'Band ـەکەت پەیوەست بکە تا هەموو شتێک زیندوو ببێت\.',
  None, 'Band ێ خۆ گرێ بدە دا هەمی تشت زیندی ببیت.', 'صِل Band ليعمل كل شيء مباشرة.',
  'Band را وصل کنید تا همه چیز زنده شود.', "Her şeyin canlı olması için Band'ini bağla.")
t(r'Band ـەکەت پەیوەست بکە',
  None, 'Band ێ خۆ گرێ بدە', 'صِل Band', 'Band را وصل کنید', "Band'ini bağla")
t(r'Band ـم هەیە، پەیوەستی بکە',
  None, 'من Band هەیە، گرێ بدە', 'لديّ Band، صِله', 'Band دارم، وصلش کن', "Band'im var, bağla")
t(r'زیندوو لە Band ـەوە',
  None, 'ڕاستەوخۆ ژ Band', 'مباشر من Band', 'زنده از Band', "Band'den canlı")
t(r'VEX Plus چالاک بکە',
  None, 'VEX Plus چالاک بکە', 'فعّل VEX Plus', 'VEX Plus را فعال کنید', "VEX Plus'ı etkinleştir")
t(r'VEX Band V8 بکڕە',
  None, 'VEX Band V8 بکڕە', 'اشترِ VEX Band V8', 'VEX Band V8 را بخرید', 'VEX Band V8 satın al')
t(r'، بە VEX Plus$',
  None, '، ب VEX Plus', '، مع VEX Plus', '، با VEX Plus', ', VEX Plus ile')
t(r'(^|[^✨] ?)پلانی ڕاهێنانی AI',
  None, '$!1پلانا ڕاهێنانێ یا AI', '$!1خطة تمارين AI', '$!1برنامهٔ تمرینی AI', '$!1AI antrenman planı')
t(r'شیکاری AI بۆ تەندروستی',
  None, 'شرۆڤەکرنا AI بۆ ساخلەمیێ', 'تحليل AI لصحتك', 'تحلیل سلامت با AI', 'Sağlığın için AI analizi')

# ---- found in testing (fragments around Latin words / numbers) -----------
t(r'پێوانەی ECG', None, 'پێڤانا ECG', 'قياس ECG', 'اندازه‌گیری ECG', 'ECG ölçümü')
t(r'پەیوەستکردنی Band', None, 'گرێدانا Band', 'توصيل Band', 'اتصال Band', "Band'i bağla")
t(r'«N»[٪%] داشکاندن بۆ ئەندامانی VEX', None, '$1٪ داشکاندن بۆ ئەندامێن VEX', 'خصم $1٪ لأعضاء VEX', '$1٪ تخفیف برای اعضای VEX', 'VEX üyelerine %$1 indirim')
t(r'گەیاندنی خۆڕایی بۆ ئەندامانی VEX', None, 'گەهاندنا خۆڕایی بۆ ئەندامێن VEX', 'توصيل مجاني لأعضاء VEX', 'ارسال رایگان برای اعضای VEX', 'VEX üyelerine ücretsiz teslimat')
t(r'بە پیشاندانی ئەپی VEX لە هۆڵ', None, 'ب نیشاندانا ئەپێ VEX ل هۆلێ', 'عند إظهار تطبيق VEX في النادي', 'با نشان دادن اپلیکیشن VEX در باشگاه', 'Salonda VEX uygulamasını göstererek')
for ku, v in [('بەیانی', (None, '$1ێ سپێدێ', '$1 صباحاً', '$1 صبح', 'sabah $1')),
              ('ئێوارە', (None, '$1ێ ئێڤاری', '$1 مساءً', '$1 عصر', 'akşam $1')),
              ('نیوەڕۆ', (None, '$1ێ نیڤرۆ', '$1 ظهراً', '$1 ظهر', 'öğlen $1')),
              ('شەو', (None, '$1ێ شەڤێ', '$1 ليلاً', '$1 شب', 'gece $1'))]:
    t('«N»ی ' + ku + r'(?![ء-يٱ-ۓە])', *v)
t(r'بەپێی کێشی «N» ?kg', None, 'ل گۆرەی کێشا $1 kg', 'حسب وزنك $1 kg', 'بر اساس وزن $1 kg', '$1 kg kilona göre')
t(r'پلانی هەفتانە بە AI', None, 'پلانا حەفتیانە ب AI', 'خطة أسبوعية مع AI', 'برنامهٔ هفتگی با AI', 'AI ile haftalık plan')
t(r'ئەندامی VEX Health', None, 'ئەندامێ VEX Health', 'عضو في VEX Health', 'عضو VEX Health', 'VEX Health üyesi')
t(r'چاوەڕوانی Band', None, 'چاڤەڕێیا Band', 'بانتظار Band', 'در انتظار Band', 'Band bekleniyor')
t(r'پچڕاندنی Band', None, 'قەتاندنا Band', 'فصل Band', 'قطع اتصال Band', 'Band bağlantısını kes')
t(r'دۆزینەوەی Band', None, 'دیتنا Band', 'العثور على Band', 'یافتن Band', "Band'i bul")
t(r'کارەکتەرەکەی بازنەکەت زیندوو دەبێت: لێدانی دڵ، هەنگاو و ئاگادارکردنەوە ڕاستەوخۆ لەسەر Band\.', None,
  'کەرەکتەرێ بازنەیا تە زیندی دبیت: لێدانا دلی، هەنگاڤ و ئاگەهداری ڕاستەوخۆ ل سەر Band.',
  'تصبح شخصية دائرتك حية: نبض القلب والخطوات والتنبيهات مباشرة على Band.',
  'شخصیت حلقهٔ شما زنده می‌شود: ضربان قلب، قدم‌ها و اعلان‌ها به‌صورت زنده روی Band.',
  "Çemberinin karakteri canlanır: nabız, adımlar ve bildirimler canlı olarak Band'de.")
t(r'ئەگەر ماوەی خەو کەمتر لە «N» کاتژمێر بێت، وەک خەوی کورت دەژمێردرێت\.',
  'Sleep shorter than $1 h counts as a nap.',
  'ئەگەر ماوێ خەوێ ژ $1 دەمژمێران کێمتر بیت، وەکی خەوا کورت دهێتە هژمارتن.',
  'إذا كانت مدة النوم أقل من $1 ساعة، تُحسب قيلولة.',
  'اگر مدت خواب کمتر از $1 ساعت باشد، چرت حساب می‌شود.',
  'Uyku $1 saatten kısaysa şekerleme sayılır.')
t(r'پرسیاری بێسنوور بە VEX AI', None, 'پسیارێن بێ سنوور ژ VEX AI', 'أسئلة غير محدودة مع VEX AI', 'پرسش نامحدود از VEX AI', "VEX AI'a sınırsız soru")
t(r'شیکاری هەموو داتاکانی Band', None, 'شرۆڤەکرنا هەمی داتایێن Band', 'تحليل كل بيانات Band', 'تحلیل همهٔ داده‌های Band', 'Tüm Band verilerinin analizi')
t(r'کات بۆ هەر «N» کم', None, 'دەم بۆ هەر $1 km', 'الوقت لكل $1 كم', 'زمان برای هر $1 کیلومتر', 'Her $1 km için süre')
t(r'هەموو ئەوانەی «N» ڕۆژ تەواو دەکەن خەڵاتیان هەیە', None, 'هەمی ئەوێن $1 ڕۆژان ب دوماهی دئینن خەلات وەردگرن',
  'كل من يكمل $1 يوماً يحصل على جائزة', 'همهٔ کسانی که $1 روز را کامل کنند جایزه می‌گیرند', '$1 günü tamamlayan herkes ödül alır')
t(r'بۆ سەروو «N» مانگ: ئاو، هەرمێ، هەڵووژە و سەوزە زیاد بکە\.',
  'Over $1 months: add water, pears, plums and vegetables.',
  'بۆ سەروو $1 هەیڤان: ئاڤێ، هەرمێ، هەلووژە و زەرزەواتێ زێدە بکە.',
  'لمن تجاوز $1 أشهر: أضف الماء والكمثرى والبرقوق والخضار.',
  'برای بالای $1 ماه: آب، گلابی، آلو و سبزیجات اضافه کنید.',
  '$1 aydan büyükler için: su, armut, erik ve sebze ekle.')
t(r'زۆرترین «N» خواردن لە یەک ژەمدا',
  'Up to $1 foods in one meal', 'پترین $1 خوارن د ئێک ژەمێ دا', 'بحد أقصى $1 أطعمة في وجبة واحدة',
  'حداکثر $1 غذا در یک وعده', 'Bir öğünde en fazla $1 yiyecek')
t(r'ECG ی دڵ', 'Heart ECG', 'ECG یا دلی', 'تخطيط القلب ECG', 'نوار قلب ECG', "Kalp ECG'si")
t(r'سکانی خواردن بە AI', 'AI food scan', 'سکانا خوارنێ ب AI', 'مسح الطعام عبر AI', 'اسکن غذا با AI', 'AI ile yemek tarama')
t(r'کورتەی تەندروستی AI', 'AI health summary', 'کورتیا ساخلەمیێ ب AI', 'ملخص صحي من AI', 'خلاصهٔ سلامت با AI', 'AI sağlık özeti')
t(r'«N» هەنگاو بڕۆ؛ ', 'Walk $1 steps; ', '$1 پێنگاڤان بچە؛ ', 'امشِ $1 خطوة؛ ', '$1 قدم راه بروید؛ ', '$1 adım yürü; ')
t(r'بۆ شیکاری قووڵتر دوگمەی VEX AI بگرە\.', 'for a deeper analysis, tap VEX AI.',
  'بۆ شرۆڤەکرنەکا کویرتر ل سەر دوگما VEX AI بدە.', 'لتحليل أعمق اضغط زر VEX AI.',
  'برای تحلیل عمیق‌تر دکمهٔ VEX AI را بزنید.', 'Daha derin bir analiz için VEX AI düğmesine dokun.')
t(r'شیکاری VEX AI لەسەر داتای ڕاستەقینەی خۆت\.', 'VEX AI analysis based on your real data.',
  'شرۆڤەکرنا VEX AI ل سەر داتایێن تە یێن ڕاستەقینە.', 'تحليل VEX AI بناءً على بياناتك الحقيقية.',
  'تحلیل VEX AI بر اساس داده‌های واقعی شما.', 'Gerçek verilerine dayalı VEX AI analizi.')
t(r'بەشداربوون لە VEX Arena بەخۆڕاییە · تەنها شارەکەت هەڵبژێرە', 'Joining VEX Arena is free · Just choose your city',
  'بەشداربوون د VEX Arena دا ب خۆڕاییە · تەنێ باژێرێ خۆ هەلبژێرە', 'الانضمام إلى VEX Arena مجاني · فقط اختر مدينتك',
  'پیوستن به VEX Arena رایگان است · فقط شهرتان را انتخاب کنید', "VEX Arena'ya katılım ücretsiz · Sadece şehrini seç")
