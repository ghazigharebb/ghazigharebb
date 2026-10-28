// VEX Health — پێوانەی ECG (هەمان شێوازی ئەپی فەرمیی Band، وردتر)
//
//   1) ڕێنمایی: وێنەی دەست و Band، هەڵبژاردنی دەست (چەپ / ڕاست)، «دەستپێکردنی پێوانە»، 4 ئامۆژگاری
//   2) پێوانە: 30 چرکە، هێڵی پێشکەوتن، تۆڕی کاغەزی ECG، شەپۆلی سوور (شێوازی مۆنیتەر)، لێدانی دڵ
//   3) ئەنجام: تۆماری 30 چرکە (3 ڕیز × 10 چرکە)، لێدانی دڵ، کەمترین/زۆرترین، HRV، ڕیتم، کوالیتی
//
// بانگکردن لە هەر شوێنێک:   openEcgPage();
// دەقەکان بە 6 زمانن (سۆرانی، بادینی، English، عربي، فارسی، Türkçe).
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/theme.dart';
import '../health/hc.dart';
import '../onboarding/reg_lang_state.dart';
import 'ecg_controller.dart';
import 'ecg_signal.dart';

void openEcgPage() => pushPage(const EcgPage());

// ───────────────────────── ڕەنگەکان (هەمیشە ڕەش، وەک ئەپی فەرمی) ─────────────────────────
const Color _bg = Color(0xFF000000);
const Color _tx = Color(0xFFFFFFFF);
const Color _mu = Color(0xFF8E8E93);
const Color _red = Color(0xFFF2463A);
const Color _lime = Color(0xFFD6F55B);
const Color _track = Color(0xFF1C1C1E);
const Color _amber = Color(0xFFFFB84D);
const LinearGradient _go = LinearGradient(colors: [Color(0xFF9EDCCB), Color(0xFF5CC68A)]);

// ───────────────────────── دەقەکان ─────────────────────────
const Map<String, Map<String, String>> _tx6 = {
  'ckb': {
    'guide': 'ڕێنمایی پێوانەی ECG', 'left': 'چەپ', 'right': 'ڕاست',
    'desc': 'بۆ باشترین ئەنجام، ئامێرەکە نزیکەی بە پانی پەنجەیەک لە سەرووی ئێسکی مەچەکەوە ببەستە، با بە توندی بە پێستەوە بنووسێت، و لە کاتی پێوانەدا دەستت ئاسوودە و بێ جووڵە بێت.',
    'start': 'دەستپێکردنی پێوانە',
    't1': 'دانیشە و هەردوو پێت لەسەر زەوی بن', 's1': 'بە ڕێکی دانیشە بۆ ئەوەی شێوەی لەش کار نەکاتە سەر پێوانەکە.',
    't2': 'باسکت بە ئاسایی لەسەر مێزێک دابنێ', 's2': 'باسکت ئاسوودە بێت بۆ ئەوەی گرژبوونی ماسولکە داتاکە تێک نەدات.',
    't3': 'لە شوێنێکی بێدەنگ بە و مەجووڵێ', 's3': 'قسە مەکە و مەجووڵێ بۆ ئەوەی ئاماژەکە ڕوونتر و جێگیرتر بێت.',
    't4': 'بە پەنجەی دەستەکەی تر (بێ ئامێر) بە نەرمی دەست لە خاڵی پێوانە بدە تا تەواو دەبێت', 's4': 'دەستلێدانێکی سووک بەسە، فشار مەخە. چاوەڕێ بکە تا تەواوبوون دیار دەبێت.',
    'meas': 'پێوانەی ECG', 'sec': 'چرکە',
    'instr': 'بە نەرمی پەنجەی شایەتمانی ئەو دەستەی ئامێری تێدا نییە لەسەر خاڵە کانزاییەکەی ناوەڕاستی ئامێرەکە دابنێ. کە پێوانە دەستی پێکرد، 30 چرکە بێ جووڵە بمێنەوە.',
    'calib': 'ڕێکخستنی داتا بەردەوامە. پێوانە خۆکار دەست پێدەکات. تکایە چاوەڕێ بکە.',
    'measuring': 'پێوانە دەکرێت… پەنجەت بێ جووڵە بهێڵەوە.',
    'lost': 'پەنجە لابرا — لە ماوەی 3 چرکەدا بیگەڕێنەوە.',
    'cancel': 'هەڵوەشاندنەوە', 'res': 'ئەنجامی ECG',
    'avg': 'ناوەندی لێدان', 'range': 'کەمترین – زۆرترین', 'rhythm': 'ڕیتم', 'regular': 'ڕێک', 'irregular': 'نائاسایی',
    'quality': 'کوالیتی ئاماژە', 'good': 'باش', 'fair': 'مامناوەند', 'weak': 'لاواز',
    'irrNote': 'لەم تۆمارەدا ڕیتمەکە نائاسایی دەرکەوت. ئەگەر دووبارە بووەوە یان هەستت بە ناڕەحەتی کرد، سەردانی پزیشک بکە.',
    'weakNote': 'ئاماژەکە لاواز بوو؛ بۆ ئەنجامی وردتر دووبارە پێوانە بکەرەوە.',
    'done': 'تەواو', 'again': 'دووبارە پێوانە', 'strip': 'تۆماری 30 چرکە',
    'disc': 'ئەم پێوانەیە بۆ شوێنکەوتنی تەندروستیی گشتییە و بۆ دەستنیشانکردنی نەخۆشی نییە.',
    'noband': 'Band پەیوەست نییە', 'band': 'نەتوانرا فرمان بنێردرێت بۆ Band', 'nofinger': 'پەنجە نەدۆزرایەوە. دووبارە هەوڵ بدە.',
    'failHint': 'دڵنیابە Band پەیوەستە و پەنجەت بە نەرمی لەسەر خاڵە کانزاییەکەیە.', 'retry': 'دووبارە هەوڵ بدە',
    'demo': 'نموونە', 'wL': 'دەستی چەپ', 'wR': 'دەستی ڕاست',
  },
  'kmr': {
    'guide': 'ڕێنمایا پیڤانا ECG', 'left': 'چەپ', 'right': 'ڕاست',
    'desc': 'بۆ باشترین ئەنجام، ئامیرێ نێزیکی ب پانیا تبلەکێ ل سەر هەستیێ مەچەکێ گرێبدە، بلا ب باشی ب پێستێ ڤە بنووسیت، و د دەمێ پیڤانێ دا دەستێ خۆ ئارام و بێ لڤین بهێلە.',
    'start': 'دەستپێکرنا پیڤانێ',
    't1': 'ڕوینە و هەردوو پێیێن خۆ ل سەر عەردی دانە', 's1': 'ب ڕێکی ڕوینە دا کو ڕەوشا لەشی کار نەکەتە سەر پیڤانێ.',
    't2': 'ملێ خۆ ب ئاسایی ل سەر مێزەکێ دانە', 's2': 'بلا ملێ تە ئارام بیت دا گرژبوونا ماسوولکان داتایان تێک نەدەت.',
    't3': 'ل جهەکێ بێدەنگ بە و نەلڤە', 's3': 'ئاخفتنێ نەکە و نەلڤە دا ئاماژە ڕوونتر و جێگیرتر بیت.',
    't4': 'ب تبلا دەستێ دی (بێ ئامیر) ب نەرمی دەستی ل خالا پیڤانێ بدە هەتا ب دوماهی دهێت', 's4': 'دەستلێدانەکا سڤک بەسە، پاڵ نەدە. چاڤەڕێ بکە هەتا ب دوماهی هاتن دیار دبیت.',
    'meas': 'پیڤانا ECG', 'sec': 'چرکە',
    'instr': 'ب نەرمی تبلا نیشاندانێ یا وی دەستێ ئامیر تێدا نەی ل سەر خالا کانزایی یا ناڤەڕاستا ئامیری دانە. پشتی پیڤان دەست پێدکەت، 30 چرکەیان بێ لڤین بمینە.',
    'calib': 'ڕێکخستنا داتایان بەردەوامە. پیڤان دێ ب خۆ دەست پێکەت. هیڤییە چاڤەڕێ بکە.',
    'measuring': 'پیڤان دهێتە کرن… تبلا خۆ بێ لڤین بهێلە.',
    'lost': 'تبل هاتە لادان — د ماوێ 3 چرکەیان دا بزڤڕینە.',
    'cancel': 'هەڵوەشاندن', 'res': 'ئەنجامێ ECG',
    'avg': 'ناڤەندا لێدانێ', 'range': 'کێمترین – زێدەترین', 'rhythm': 'ڕیتم', 'regular': 'ڕێک', 'irregular': 'نە ئاسایی',
    'quality': 'کوالیتیا ئاماژێ', 'good': 'باش', 'fair': 'ناڤینجی', 'weak': 'لاواز',
    'irrNote': 'د ڤێ تۆماری دا ڕیتم نە ئاسایی دیار بوو. ئەگەر دووبارە بوو یان تە هەست ب نەخۆشیێ کر، سەرەدانا نوژداری بکە.',
    'weakNote': 'ئاماژە لاواز بوو؛ بۆ ئەنجامەکێ دروستتر دووبارە بپیڤە.',
    'done': 'تەمام', 'again': 'دووبارە پیڤان', 'strip': 'تۆمارا 30 چرکەیان',
    'disc': 'ئەڤ پیڤانە بۆ چاڤدێریا ساخلەمیا گشتییە و نە بۆ دەستنیشانکرنا نەخۆشیێ یە.',
    'noband': 'Band نە گرێدایە', 'band': 'نەشیا فەرمان بۆ Band بهێتە هنارتن', 'nofinger': 'تبل نەهاتە دیتن. دووبارە هەول بدە.',
    'failHint': 'پشتڕاست بە کو Band گرێدایە و تبلا تە ب نەرمی ل سەر خالا کانزایی یە.', 'retry': 'دووبارە هەول بدە',
    'demo': 'نموونە', 'wL': 'دەستێ چەپ', 'wR': 'دەستێ ڕاست',
  },
  'en': {
    'guide': 'ECG Measurement Guide', 'left': 'Left', 'right': 'Right',
    'desc': "For the best measurement results, wear the device about one finger's width above the wrist bone, ensure it fits snugly against the skin, and keep your hand relaxed and still during the measurement.",
    'start': 'Start Measurement',
    't1': 'Sit down with both feet flat on the ground', 's1': 'Maintain an upright sitting posture to help minimize interference from body position.',
    't2': 'Place your arm naturally on a table', 's2': 'Support your arm in a relaxed position to avoid muscle tension affecting the data.',
    't3': 'Stay in a quiet environment and remain still', 's3': 'Avoid talking or moving to ensure a clearer and more stable signal.',
    't4': 'With the other hand (without the device), gently touch the measurement contact point until the process is complete', 's4': 'A light touch is sufficient—do not press hard. Wait until completion is indicated.',
    'meas': 'ECG Measurement', 'sec': 's',
    'instr': 'Please gently place the index finger of the hand without the wearable device on the metal contact at the center of the device. After the measurement starts, remain still for 30 seconds.',
    'calib': 'Data calibration in progress. Measurement will start automatically. Please wait.',
    'measuring': 'Measuring… keep your finger still.',
    'lost': 'Finger lifted — place it back within 3 seconds.',
    'cancel': 'Cancel', 'res': 'ECG Result',
    'avg': 'Average heart rate', 'range': 'Lowest – highest', 'rhythm': 'Rhythm', 'regular': 'Regular', 'irregular': 'Irregular',
    'quality': 'Signal quality', 'good': 'Good', 'fair': 'Fair', 'weak': 'Weak',
    'irrNote': 'The rhythm looked irregular in this recording. If it happens again or you feel unwell, see a doctor.',
    'weakNote': 'The signal was weak; measure again for a more accurate result.',
    'done': 'Done', 'again': 'Measure again', 'strip': '30-second recording',
    'disc': 'This measurement is for general wellness tracking and is not a medical diagnosis.',
    'noband': 'Band not connected', 'band': 'Could not send the command to the Band', 'nofinger': 'No finger detected. Please try again.',
    'failHint': 'Make sure the Band is connected and your finger rests lightly on the metal contact.', 'retry': 'Try again',
    'demo': 'Demo', 'wL': 'Left wrist', 'wR': 'Right wrist',
  },
  'ar': {
    'guide': 'دليل قياس تخطيط القلب (ECG)', 'left': 'اليسرى', 'right': 'اليمنى',
    'desc': 'للحصول على أفضل النتائج، ارتدِ الجهاز فوق عظمة الرسغ بمسافة عرض إصبع تقريباً، وتأكد من ملامسته للجلد بإحكام، وحافظ على يدك مسترخية وثابتة أثناء القياس.',
    'start': 'بدء القياس',
    't1': 'اجلس مع وضع قدميك على الأرض', 's1': 'حافظ على وضعية جلوس مستقيمة لتقليل تأثير وضعية الجسم.',
    't2': 'ضع ذراعك بشكل طبيعي على طاولة', 's2': 'اسند ذراعك في وضع مريح لتجنب تأثير توتر العضلات على البيانات.',
    't3': 'ابقَ في مكان هادئ ولا تتحرك', 's3': 'تجنب الكلام أو الحركة للحصول على إشارة أوضح وأكثر ثباتاً.',
    't4': 'بيدك الأخرى (التي لا ترتدي الجهاز)، المس نقطة القياس برفق حتى يكتمل القياس', 's4': 'لمسة خفيفة تكفي، لا تضغط بقوة. انتظر حتى يظهر الاكتمال.',
    'meas': 'قياس تخطيط القلب', 'sec': 'ث',
    'instr': 'ضع برفق إصبع السبابة لليد التي لا ترتدي الجهاز على نقطة التلامس المعدنية في وسط الجهاز. بعد بدء القياس، ابقَ ثابتاً لمدة 30 ثانية.',
    'calib': 'جارٍ معايرة البيانات. سيبدأ القياس تلقائياً. يرجى الانتظار.',
    'measuring': 'جارٍ القياس… أبقِ إصبعك ثابتاً.',
    'lost': 'رُفع الإصبع — أعده خلال 3 ثوانٍ.',
    'cancel': 'إلغاء', 'res': 'نتيجة تخطيط القلب',
    'avg': 'متوسط النبض', 'range': 'الأدنى – الأعلى', 'rhythm': 'النظم', 'regular': 'منتظم', 'irregular': 'غير منتظم',
    'quality': 'جودة الإشارة', 'good': 'جيدة', 'fair': 'متوسطة', 'weak': 'ضعيفة',
    'irrNote': 'ظهر النظم غير منتظم في هذا التسجيل. إذا تكرر ذلك أو شعرت بانزعاج، فراجع الطبيب.',
    'weakNote': 'كانت الإشارة ضعيفة؛ أعد القياس للحصول على نتيجة أدق.',
    'done': 'تم', 'again': 'قياس مرة أخرى', 'strip': 'تسجيل 30 ثانية',
    'disc': 'هذا القياس لمتابعة الصحة العامة وليس لتشخيص الأمراض.',
    'noband': 'Band غير متصل', 'band': 'تعذّر إرسال الأمر إلى Band', 'nofinger': 'لم يُكتشف الإصبع. حاول مرة أخرى.',
    'failHint': 'تأكد من اتصال Band ومن وضع إصبعك برفق على نقطة التلامس المعدنية.', 'retry': 'حاول مرة أخرى',
    'demo': 'تجريبي', 'wL': 'اليد اليسرى', 'wR': 'اليد اليمنى',
  },
  'fa': {
    'guide': 'راهنمای اندازه‌گیری نوار قلب (ECG)', 'left': 'چپ', 'right': 'راست',
    'desc': 'برای بهترین نتیجه، دستگاه را حدود یک بند انگشت بالاتر از استخوان مچ ببندید، مطمئن شوید محکم به پوست چسبیده است و در طول اندازه‌گیری دستتان آرام و بی‌حرکت باشد.',
    'start': 'شروع اندازه‌گیری',
    't1': 'بنشینید و هر دو پا را صاف روی زمین بگذارید', 's1': 'صاف بنشینید تا تأثیر وضعیت بدن کمتر شود.',
    't2': 'بازوی خود را به‌طور طبیعی روی میز بگذارید', 's2': 'بازو را در حالت آرام نگه دارید تا گرفتگی عضلات بر داده‌ها اثر نگذارد.',
    't3': 'در محیطی آرام بمانید و حرکت نکنید', 's3': 'صحبت نکنید و حرکت نکنید تا سیگنال واضح‌تر و پایدارتر باشد.',
    't4': 'با دست دیگر (بدون دستگاه)، نقطهٔ اندازه‌گیری را به‌آرامی لمس کنید تا فرایند کامل شود', 's4': 'لمس سبک کافی است، فشار ندهید. صبر کنید تا پایان اندازه‌گیری نمایش داده شود.',
    'meas': 'اندازه‌گیری نوار قلب', 'sec': 'ث',
    'instr': 'انگشت اشارهٔ دستی را که دستگاه ندارد به‌آرامی روی نقطهٔ تماس فلزی وسط دستگاه بگذارید. پس از شروع اندازه‌گیری، 30 ثانیه بی‌حرکت بمانید.',
    'calib': 'در حال کالیبره کردن داده‌ها. اندازه‌گیری خودکار شروع می‌شود. لطفاً صبر کنید.',
    'measuring': 'در حال اندازه‌گیری… انگشت خود را ثابت نگه دارید.',
    'lost': 'انگشت برداشته شد — ظرف 3 ثانیه دوباره بگذارید.',
    'cancel': 'لغو', 'res': 'نتیجهٔ نوار قلب',
    'avg': 'میانگین ضربان', 'range': 'کمترین – بیشترین', 'rhythm': 'ریتم', 'regular': 'منظم', 'irregular': 'نامنظم',
    'quality': 'کیفیت سیگنال', 'good': 'خوب', 'fair': 'متوسط', 'weak': 'ضعیف',
    'irrNote': 'ریتم در این ثبت نامنظم به نظر رسید. اگر تکرار شد یا احساس ناراحتی کردید، به پزشک مراجعه کنید.',
    'weakNote': 'سیگنال ضعیف بود؛ برای نتیجهٔ دقیق‌تر دوباره اندازه بگیرید.',
    'done': 'تمام', 'again': 'اندازه‌گیری دوباره', 'strip': 'ثبت 30 ثانیه',
    'disc': 'این اندازه‌گیری برای پیگیری سلامت عمومی است و برای تشخیص بیماری نیست.',
    'noband': 'Band متصل نیست', 'band': 'ارسال فرمان به Band ممکن نشد', 'nofinger': 'انگشت شناسایی نشد. دوباره تلاش کنید.',
    'failHint': 'مطمئن شوید Band متصل است و انگشتتان به‌آرامی روی نقطهٔ فلزی است.', 'retry': 'تلاش دوباره',
    'demo': 'نمونه', 'wL': 'دست چپ', 'wR': 'دست راست',
  },
  'tr': {
    'guide': 'EKG Ölçüm Rehberi', 'left': 'Sol', 'right': 'Sağ',
    'desc': 'En iyi sonuç için cihazı bilek kemiğinin yaklaşık bir parmak üstüne takın, cilde iyice oturduğundan emin olun ve ölçüm sırasında elinizi gevşek ve hareketsiz tutun.',
    'start': 'Ölçümü Başlat',
    't1': 'İki ayağınız yere düz basacak şekilde oturun', 's1': 'Vücut pozisyonunun etkisini azaltmak için dik oturun.',
    't2': 'Kolunuzu doğal şekilde bir masaya koyun', 's2': 'Kas gerginliğinin verileri etkilememesi için kolunuzu rahat tutun.',
    't3': 'Sessiz bir ortamda kalın ve hareket etmeyin', 's3': 'Daha net ve kararlı bir sinyal için konuşmayın ve kıpırdamayın.',
    't4': 'Diğer elinizle (cihaz olmayan) işlem bitene kadar ölçüm temas noktasına hafifçe dokunun', 's4': 'Hafif bir dokunuş yeterlidir, bastırmayın. Tamamlandığı gösterilene kadar bekleyin.',
    'meas': 'EKG Ölçümü', 'sec': 'sn',
    'instr': 'Cihaz takılı olmayan elinizin işaret parmağını cihazın ortasındaki metal temas noktasına hafifçe koyun. Ölçüm başladıktan sonra 30 saniye hareketsiz kalın.',
    'calib': 'Veri kalibrasyonu sürüyor. Ölçüm otomatik olarak başlayacak. Lütfen bekleyin.',
    'measuring': 'Ölçülüyor… parmağınızı sabit tutun.',
    'lost': 'Parmak kaldırıldı — 3 saniye içinde geri koyun.',
    'cancel': 'İptal', 'res': 'EKG Sonucu',
    'avg': 'Ortalama nabız', 'range': 'En düşük – en yüksek', 'rhythm': 'Ritim', 'regular': 'Düzenli', 'irregular': 'Düzensiz',
    'quality': 'Sinyal kalitesi', 'good': 'İyi', 'fair': 'Orta', 'weak': 'Zayıf',
    'irrNote': 'Bu kayıtta ritim düzensiz göründü. Tekrarlarsa veya rahatsızlık hissederseniz bir doktora başvurun.',
    'weakNote': 'Sinyal zayıftı; daha doğru bir sonuç için yeniden ölçün.',
    'done': 'Bitti', 'again': 'Tekrar ölç', 'strip': '30 saniyelik kayıt',
    'disc': 'Bu ölçüm genel sağlık takibi içindir, hastalık teşhisi için değildir.',
    'noband': 'Band bağlı değil', 'band': "Komut Band'e gönderilemedi", 'nofinger': 'Parmak algılanmadı. Tekrar deneyin.',
    'failHint': "Band'in bağlı olduğundan ve parmağınızın metal temas noktasına hafifçe değdiğinden emin olun.", 'retry': 'Tekrar dene',
    'demo': 'Örnek', 'wL': 'Sol el', 'wR': 'Sağ el',
  },
};

String get _lg => _tx6.containsKey(LangState.I.code) ? LangState.I.code : 'ckb';
bool get _rtl => _lg != 'en' && _lg != 'tr';
String _t(String k) => _tx6[_lg]![k] ?? _tx6['en']![k] ?? k;

TextStyle _f(double s, {FontWeight w = FontWeight.w700, Color c = _tx, double? h}) => ku(s, w: w, c: c, h: h);
TextStyle _n(double s, {FontWeight w = FontWeight.w700, Color c = _tx, double? h}) =>
    GoogleFonts.sora(fontSize: s, fontWeight: w, color: c, height: h, letterSpacing: s > 40 ? -2 : 0);

enum _Step { guide, measure, result }

// ═══════════════════════════════════════════════════════════════════════════
class EcgPage extends StatefulWidget {
  const EcgPage({super.key});
  @override
  State<EcgPage> createState() => _EcgPageState();
}

class _EcgPageState extends State<EcgPage> with TickerProviderStateMixin {
  static const String _wristKey = 'vex_ecg_wrist';
  _Step _step = _Step.guide;
  bool _right = false;
  EcgController? c;

  late final AnimationController _loop = AnimationController(vsync: this, duration: const Duration(milliseconds: 2600))..repeat();
  late final AnimationController _beat = AnimationController(vsync: this, duration: const Duration(milliseconds: 380));
  int _lastBeat = 0;

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((sp) {
      if (mounted) setState(() => _right = sp.getBool(_wristKey) ?? false);
    }).catchError((_) {});
  }

  @override
  void dispose() {
    c?.frame.removeListener(_onFrame);
    c?.dispose();
    _loop.dispose();
    _beat.dispose();
    super.dispose();
  }

  void _setWrist(bool right) {
    HapticFeedback.selectionClick();
    setState(() => _right = right);
    SharedPreferences.getInstance().then((sp) => sp.setBool(_wristKey, right)).catchError((_) => false);
  }

  void _start() {
    HapticFeedback.mediumImpact();
    c?.frame.removeListener(_onFrame);
    c?.dispose();
    final ctl = EcgController(rightWrist: _right, onDone: (_) {
      if (mounted) setState(() => _step = _Step.result);
    });
    ctl.frame.addListener(_onFrame);
    _lastBeat = 0;
    setState(() {
      c = ctl;
      _step = _Step.measure;
    });
    ctl.start();
  }

  void _onFrame() {
    final ctl = c;
    if (ctl == null) return;
    if (ctl.sig.beatCount != _lastBeat) {
      _lastBeat = ctl.sig.beatCount;
      _beat.forward(from: 0);
    }
  }

  Future<void> _cancel() async {
    await c?.cancel();
    if (!mounted) return;
    if (_step == _Step.measure) {
      setState(() => _step = _Step.guide);
    } else {
      Navigator.of(context).maybePop();
    }
  }

  @override
  Widget build(BuildContext context) {
    LangScope.of(context);
    return Directionality(
      textDirection: _rtl ? TextDirection.rtl : TextDirection.ltr,
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: PopScope(
          canPop: _step != _Step.measure,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop && _step == _Step.measure) _cancel();
          },
          child: Scaffold(
            backgroundColor: _bg,
            body: AnimatedSwitcher(
              duration: const Duration(milliseconds: 420),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, a) => FadeTransition(
                opacity: a,
                child: SlideTransition(position: Tween(begin: const Offset(0, .03), end: Offset.zero).animate(a), child: child),
              ),
              child: switch (_step) {
                _Step.guide => KeyedSubtree(key: const ValueKey('g'), child: _guide()),
                _Step.measure => KeyedSubtree(key: const ValueKey('m'), child: _measure()),
                _Step.result => KeyedSubtree(key: const ValueKey('r'), child: _result()),
              },
            ),
          ),
        ),
      ),
    );
  }

  // ───────────────────────── 1) ڕێنمایی ─────────────────────────
  Widget _guide() {
    final mq = MediaQuery.of(context);
    return CustomScrollView(slivers: [
      SliverAppBar(
        pinned: true,
        backgroundColor: _bg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 60,
        automaticallyImplyLeading: false,
        leading: _Tap(
          onTap: () => Navigator.of(context).maybePop(),
          child: Icon(_rtl ? Icons.arrow_forward : Icons.arrow_back, color: _tx, size: 26),
        ),
      ),
      SliverPadding(
        padding: EdgeInsets.fromLTRB(22, 0, 22, mq.padding.bottom + 28),
        sliver: SliverList(
          delegate: SliverChildListDelegate([
            Text(_t('guide'), style: _f(24, w: FontWeight.w800, h: 1.3)),
            const SizedBox(height: 8),
            SizedBox(
              height: 250,
              child: AnimatedBuilder(
                animation: _loop,
                builder: (_, __) => CustomPaint(painter: _WristArt(mode: 0, t: _loop.value, right: _right)),
              ),
            ),
            const SizedBox(height: 18),
            Row(children: [
              Expanded(child: _WristBtn(label: _t('left'), on: !_right, onTap: () => _setWrist(false))),
              const SizedBox(width: 14),
              Expanded(child: _WristBtn(label: _t('right'), on: _right, onTap: () => _setWrist(true))),
            ]),
            const SizedBox(height: 18),
            Text(_t('desc'), style: _f(13.5, w: FontWeight.w600, c: _mu, h: 1.6)),
            const SizedBox(height: 22),
            _GoBtn(label: _t('start'), onTap: _start),
            const SizedBox(height: 22),
            for (var i = 1; i <= 4; i++) _tip(_t('t$i'), _t('s$i')),
            const SizedBox(height: 8),
            Text(_t('disc'), textAlign: TextAlign.center, style: _f(11, w: FontWeight.w500, c: _mu.withValues(alpha: .7), h: 1.7)),
          ]),
        ),
      ),
    ]);
  }

  Widget _tip(String title, String sub) => Padding(
        padding: const EdgeInsets.only(bottom: 22),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 26,
            height: 26,
            margin: const EdgeInsets.only(top: 4),
            decoration: const BoxDecoration(color: _lime, shape: BoxShape.circle),
            child: const Icon(Icons.check_rounded, size: 18, color: Colors.black),
          ),
          const SizedBox(width: 22),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: _f(18, w: FontWeight.w800, h: 1.45)),
              const SizedBox(height: 8),
              Text(sub, style: _f(14.5, w: FontWeight.w600, c: _mu, h: 1.55)),
            ]),
          ),
        ]),
      );

  // ───────────────────────── 2) پێوانە ─────────────────────────
  Widget _measure() {
    final ctl = c!;
    final mq = MediaQuery.of(context);
    return ListenableBuilder(
      listenable: ctl,
      builder: (context, _) {
        if (ctl.phase == EcgPhase.failed) return _failed(ctl);
        final waiting = ctl.phase == EcgPhase.waiting;
        final note = ctl.fingerLost ? _t('lost') : (waiting ? _t('calib') : _t('measuring'));
        return Padding(
          padding: EdgeInsets.fromLTRB(0, mq.padding.top + 14, 0, mq.padding.bottom + 18),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: Row(children: [
                Expanded(child: Text(_t('meas'), style: _f(24, w: FontWeight.w800, h: 1.3))),
                if (ctl.demo)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), border: Border.all(color: _amber.withValues(alpha: .6))),
                    child: Text(_t('demo'), style: _f(10.5, c: _amber)),
                  ),
              ]),
            ),
            const SizedBox(height: 8),
            // ── ناوچەی شەپۆل / وێنە ──
            Expanded(
              child: AnimatedBuilder(
                animation: Listenable.merge([ctl.frame, _loop, _beat]),
                builder: (_, __) {
                  final contact = ctl.sig.contact();
                  final live = contact || ctl.phase == EcgPhase.measuring;
                  final b = ctl.sig.bpm;
                  return Stack(children: [
                    // تۆڕ و شەپۆل
                    Positioned.fill(
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 500),
                        opacity: live ? 1 : 0,
                        child: CustomPaint(painter: _GridPainter()),
                      ),
                    ),
                    Positioned.fill(
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 500),
                        opacity: live ? 1 : 0,
                        child: Directionality(
                          textDirection: TextDirection.ltr,
                          child: CustomPaint(painter: _SweepPainter(ctl.sig, ctl.frame.value, bottomPad: 120)),
                        ),
                      ),
                    ),
                    // وێنەی دەست (پێش دانانی پەنجە)
                    Positioned.fill(
                      bottom: 110,
                      child: IgnorePointer(
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 450),
                          opacity: live ? 0 : 1,
                          child: CustomPaint(painter: _WristArt(mode: 1, t: _loop.value, right: _right)),
                        ),
                      ),
                    ),
                    // دڵ + bpm
                    PositionedDirectional(
                      start: 22,
                      top: 16,
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 400),
                        opacity: live ? 1 : 0,
                        child: Directionality(
                          textDirection: TextDirection.ltr,
                          child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                            Transform.scale(
                              scale: 1 + .22 * math.sin(math.pi * _beat.value),
                              child: const Icon(Icons.favorite, color: _red, size: 30),
                            ),
                            const SizedBox(width: 10),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 250),
                              child: Text(b == null ? '--' : '${b.round()}', key: ValueKey(b?.round()), style: _n(24, w: FontWeight.w800)),
                            ),
                            const SizedBox(width: 6),
                            Padding(padding: const EdgeInsets.only(bottom: 2), child: Text('bpm', style: _n(15, c: _mu))),
                          ]),
                        ),
                      ),
                    ),
                    // ژمێرەر
                    PositionedDirectional(
                      start: 22,
                      bottom: 6,
                      child: Directionality(
                        textDirection: TextDirection.ltr,
                        child: Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 220),
                            transitionBuilder: (w, a) => FadeTransition(
                              opacity: a,
                              child: SlideTransition(position: Tween(begin: const Offset(0, .15), end: Offset.zero).animate(a), child: w),
                            ),
                            child: Text('${ctl.secondsLeft}', key: ValueKey(ctl.secondsLeft), style: _n(88, w: FontWeight.w700, h: 1)),
                          ),
                          const SizedBox(width: 12),
                          Text(_t('sec'), style: _f(20, w: FontWeight.w700, c: _mu)),
                        ]),
                      ),
                    ),
                  ]);
                },
              ),
            ),
            const SizedBox(height: 18),
            // هێڵی پێشکەوتن (ماوە)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: AnimatedBuilder(
                animation: ctl.frame,
                builder: (_, __) => _Bar(value: 1 - ctl.progress),
              ),
            ),
            const SizedBox(height: 26),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: Text(_t('instr'), style: _f(18, w: FontWeight.w800, h: 1.55)),
            ),
            const SizedBox(height: 22),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Text(note, key: ValueKey(note), style: _f(13, w: FontWeight.w600, c: ctl.fingerLost ? _amber : _mu, h: 1.6)),
              ),
            ),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: _OutlineBtn(label: _t('cancel'), onTap: _cancel),
            ),
          ]),
        );
      },
    );
  }

  Widget _failed(EcgController ctl) {
    final mq = MediaQuery.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(22, mq.padding.top + 14, 22, mq.padding.bottom + 18),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(_t('meas'), style: _f(24, w: FontWeight.w800, h: 1.3)),
        const Spacer(),
        const Icon(Icons.error_outline_rounded, size: 64, color: _amber),
        const SizedBox(height: 18),
        Text(_t(ctl.failReason), textAlign: TextAlign.center, style: _f(20, w: FontWeight.w800)),
        const SizedBox(height: 10),
        Text(_t('failHint'), textAlign: TextAlign.center, style: _f(14, w: FontWeight.w600, c: _mu, h: 1.6)),
        const Spacer(),
        _GoBtn(label: _t('retry'), onTap: _start),
        const SizedBox(height: 12),
        _OutlineBtn(label: _t('cancel'), onTap: () => setState(() => _step = _Step.guide)),
      ]),
    );
  }

  // ───────────────────────── 3) ئەنجام ─────────────────────────
  Widget _result() {
    final r = c?.result;
    final mq = MediaQuery.of(context);
    if (r == null) return const SizedBox.shrink();
    final st = r.stats;
    final q = r.quality;
    final (String ql, Color qc) = q > .75 ? (_t('good'), const Color(0xFF5CC68A)) : (q > .4 ? (_t('fair'), _amber) : (_t('weak'), _red));
    String two(int v) => v.toString().padLeft(2, '0');
    final d = r.at;
    final h12 = (d.hour + 11) % 12 + 1;
    final when = '${d.year}/${two(d.month)}/${two(d.day)}  $h12:${two(d.minute)} ${d.hour < 12 ? 'AM' : 'PM'}';
    return ListView(
      padding: EdgeInsets.fromLTRB(22, mq.padding.top + 14, 22, mq.padding.bottom + 24),
      children: [
        Row(children: [
          Expanded(child: Text(_t('res'), style: _f(24, w: FontWeight.w800, h: 1.3))),
          _Tap(onTap: () => Navigator.of(context).maybePop(), child: const Icon(Icons.close_rounded, color: _tx, size: 26)),
        ]),
        const SizedBox(height: 4),
        Text('$when  ·  ${r.rightWrist ? _t('wR') : _t('wL')}', textDirection: TextDirection.ltr, textAlign: _rtl ? TextAlign.right : TextAlign.left, style: _f(12.5, w: FontWeight.w600, c: _mu)),
        const SizedBox(height: 18),
        // لێدانی دڵ
        Directionality(
          textDirection: TextDirection.ltr,
          child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            AnimatedBuilder(
              animation: _loop,
              builder: (_, child) => Transform.scale(scale: 1 + .12 * math.max(0.0, math.sin(_loop.value * math.pi * 2 * ((r.bpm ?? 60) / 60 * 2.6))), child: child),
              child: const Icon(Icons.favorite, color: _red, size: 38),
            ),
            const SizedBox(width: 12),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: r.bpm ?? 0),
              duration: const Duration(milliseconds: 900),
              curve: Curves.easeOutCubic,
              builder: (_, v, __) => Text(r.bpm == null ? '--' : '${v.round()}', style: _n(72, w: FontWeight.w700, h: 1)),
            ),
            const SizedBox(width: 8),
            Padding(padding: const EdgeInsets.only(bottom: 10), child: Text('bpm', style: _n(18, c: _mu))),
          ]),
        ),
        const SizedBox(height: 18),
        // تۆماری 30 چرکە
        Text(_t('strip'), style: _f(13, w: FontWeight.w700, c: _mu)),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Container(
            height: 3 * 92,
            color: const Color(0xFF070707),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 1400),
              curve: Curves.easeOutCubic,
              builder: (_, v, __) => CustomPaint(painter: _StripPainter(r.trace, r.sampleRate, reveal: v)),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(child: _Stat(title: _t('avg'), value: r.bpm == null ? '--' : '${r.bpm!.round()}', unit: 'bpm')),
          const SizedBox(width: 10),
          Expanded(
            child: _Stat(
              title: _t('range'),
              value: st.minBpm == null ? '--' : '${st.minBpm!.round()}–${st.maxBpm!.round()}',
              unit: 'bpm',
            ),
          ),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: _Stat(title: 'HRV', value: r.hrv == null ? '--' : '${r.hrv}', unit: 'ms')),
          const SizedBox(width: 10),
          Expanded(
            child: _Stat(
              title: _t('rhythm'),
              value: st.bpm == null ? '--' : (st.irregular ? _t('irregular') : _t('regular')),
              valueColor: st.irregular ? _amber : const Color(0xFF5CC68A),
              text: true,
            ),
          ),
        ]),
        const SizedBox(height: 10),
        _Stat(title: _t('quality'), value: ql, valueColor: qc, text: true, bars: q),
        if (st.irregular) ...[const SizedBox(height: 14), _Note(_t('irrNote'), _amber)],
        if (q <= .4) ...[const SizedBox(height: 14), _Note(_t('weakNote'), _red)],
        const SizedBox(height: 24),
        _GoBtn(label: _t('done'), onTap: () => Navigator.of(context).maybePop()),
        const SizedBox(height: 12),
        _OutlineBtn(label: _t('again'), onTap: _start),
        const SizedBox(height: 18),
        Text(_t('disc'), textAlign: TextAlign.center, style: _f(11, w: FontWeight.w500, c: _mu.withValues(alpha: .7), h: 1.7)),
      ],
    );
  }
}

// ═════════════════════════ پارچەکان ═════════════════════════
class _Tap extends StatefulWidget {
  const _Tap({required this.child, required this.onTap, this.scale = .95});
  final Widget child;
  final VoidCallback onTap;
  final double scale;
  @override
  State<_Tap> createState() => _TapState();
}

class _TapState extends State<_Tap> {
  bool _d = false;
  @override
  Widget build(BuildContext context) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _d = true),
        onTapUp: (_) => setState(() => _d = false),
        onTapCancel: () => setState(() => _d = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _d ? widget.scale : 1,
          duration: Duration(milliseconds: _d ? 90 : 300),
          curve: _d ? Curves.easeOut : Curves.easeOutBack,
          child: widget.child,
        ),
      );
}

class _WristBtn extends StatelessWidget {
  const _WristBtn({required this.label, required this.on, required this.onTap});
  final String label;
  final bool on;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => _Tap(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
          height: 62,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(31),
            gradient: on ? const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFF7F8FA), Color(0xFFC9CCD2)]) : null,
            color: on ? null : Colors.black,
            border: Border.all(color: on ? const Color(0xFFE6E8EC) : _tx, width: 1.6),
            boxShadow: on ? const [BoxShadow(color: Color(0x33FFFFFF), blurRadius: 18, spreadRadius: -6)] : const [],
          ),
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 280),
            style: _f(20, w: FontWeight.w800, c: on ? Colors.black : _tx),
            child: Text(label),
          ),
        ),
      );
}

class _GoBtn extends StatelessWidget {
  const _GoBtn({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => _Tap(
        scale: .97,
        onTap: onTap,
        child: Container(
          height: 62,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: _go,
            borderRadius: BorderRadius.circular(31),
            boxShadow: const [BoxShadow(color: Color(0x405CC68A), blurRadius: 24, offset: Offset(0, 8), spreadRadius: -8)],
          ),
          child: Text(label, style: _f(18, w: FontWeight.w800, c: Colors.black)),
        ),
      );
}

class _OutlineBtn extends StatelessWidget {
  const _OutlineBtn({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => _Tap(
        scale: .97,
        onTap: onTap,
        child: Container(
          height: 60,
          alignment: Alignment.center,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(30), border: Border.all(color: _tx, width: 1.6)),
          child: Text(label, style: _f(18, w: FontWeight.w800)),
        ),
      );
}

/// هێڵی ماوە (پڕ ← بەتاڵ) بە ڕەنگی کەسک
class _Bar extends StatelessWidget {
  const _Bar({required this.value});
  final double value;
  @override
  Widget build(BuildContext context) => Directionality(
        textDirection: TextDirection.ltr,
        child: Container(
          height: 10,
          decoration: BoxDecoration(color: _track, borderRadius: BorderRadius.circular(5)),
          alignment: Alignment.centerLeft,
          child: FractionallySizedBox(
            widthFactor: value.clamp(0.0, 1.0),
            child: Container(decoration: BoxDecoration(gradient: _go, borderRadius: BorderRadius.circular(5))),
          ),
        ),
      );
}

class _Stat extends StatelessWidget {
  const _Stat({required this.title, required this.value, this.unit, this.valueColor = _tx, this.text = false, this.bars});
  final String title, value;
  final String? unit;
  final Color valueColor;
  final bool text;
  final double? bars;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        decoration: BoxDecoration(color: const Color(0xFF0F0F10), borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0xFF232325))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: _f(12.5, w: FontWeight.w700, c: _mu)),
          const SizedBox(height: 6),
          Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Flexible(
              child: Text(value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textDirection: text ? null : TextDirection.ltr,
                  style: text ? _f(20, w: FontWeight.w800, c: valueColor) : _n(26, w: FontWeight.w800, c: valueColor)),
            ),
            if (unit != null) ...[const SizedBox(width: 5), Padding(padding: const EdgeInsets.only(bottom: 3), child: Text(unit!, style: _n(12.5, c: _mu)))],
            if (bars != null) ...[
              const Spacer(),
              for (var i = 0; i < 4; i++)
                Container(
                  width: 6,
                  height: 8.0 + i * 5,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: i < (bars! > .75 ? 4 : bars! > .55 ? 3 : bars! > .25 ? 2 : bars! > 0 ? 1 : 0) ? valueColor : const Color(0xFF2A2A2D),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
            ],
          ]),
        ]),
      );
}

class _Note extends StatelessWidget {
  const _Note(this.text, this.color);
  final String text;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: color.withValues(alpha: .08), borderRadius: BorderRadius.circular(16), border: Border.all(color: color.withValues(alpha: .4))),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(Icons.info_outline_rounded, size: 20, color: color),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: _f(13.5, w: FontWeight.w600, h: 1.6))),
        ]),
      );
}

// ═════════════════════════ پەینتەرەکان ═════════════════════════
/// تۆڕی کاغەزی ECG (ڕەش)
class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas c, Size s) {
    const cell = 12.0;
    final minor = Paint()
      ..color = const Color(0x14FFFFFF)
      ..strokeWidth = 1;
    final major = Paint()
      ..color = const Color(0x24FFFFFF)
      ..strokeWidth = 1;
    var i = 0;
    for (double x = 0; x <= s.width; x += cell, i++) {
      c.drawLine(Offset(x, 0), Offset(x, s.height), i % 5 == 0 ? major : minor);
    }
    i = 0;
    for (double y = 0; y <= s.height; y += cell, i++) {
      c.drawLine(Offset(0, y), Offset(s.width, y), i % 5 == 0 ? major : minor);
    }
  }

  @override
  bool shouldRepaint(covariant _GridPainter o) => false;
}

/// شەپۆلی زیندوو بە شێوازی مۆنیتەر: لە چەپەوە بۆ ڕاست دەنووسرێت و بۆشاییەک لە پێش خەتەکەدا هەیە
class _SweepPainter extends CustomPainter {
  _SweepPainter(this.sig, this.tick, {this.bottomPad = 0});
  final EcgSignal sig;
  final int tick;
  final double bottomPad;

  @override
  void paint(Canvas c, Size s) {
    final h = s.height - bottomPad;
    final mid = h * .52;
    // هێڵی بنەڕەت
    c.drawLine(Offset(0, mid), Offset(s.width, mid), Paint()
      ..color = const Color(0x4DFFFFFF)
      ..strokeWidth = 1);
    final buf = sig.sweep;
    final n = buf.length;
    if (n < 2) return;
    final amp = h * .30;
    final dx = s.width / (n - 1);
    final gap = (n * .06).round();
    final cur = sig.cursor;
    final paint = Paint()
      ..color = _red
      ..strokeWidth = 2.6
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;
    final glow = Paint()
      ..color = _red.withValues(alpha: .35)
      ..strokeWidth = 7
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);

    Path seg(int a, int b) {
      final p = Path();
      for (var i = a; i < b; i++) {
        final pt = Offset(i * dx, mid - buf[i] * amp);
        if (i == a) {
          p.moveTo(pt.dx, pt.dy);
        } else {
          p.lineTo(pt.dx, pt.dy);
        }
      }
      return p;
    }

    // نوێ: 0..cursor ، کۆن: cursor+gap..n (تەنها کاتێک یەک جار پڕ بووبێت)
    final parts = <Path>[if (cur > 1) seg(0, cur), if (sig.sweepFull && cur + gap < n - 1) seg(cur + gap, n)];
    for (final p in parts) {
      c.drawPath(p, glow);
      c.drawPath(p, paint);
    }
    // خاڵی سەری خەتەکە
    if (cur > 0) {
      final head = Offset((cur - 1) * dx, mid - buf[cur - 1] * amp);
      c.drawCircle(head, 7, Paint()
        ..color = _red.withValues(alpha: .35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));
      c.drawCircle(head, 3.2, Paint()..color = const Color(0xFFFF7A70));
    }
  }

  @override
  bool shouldRepaint(covariant _SweepPainter o) => o.tick != tick;
}

/// تۆماری 30 چرکە: 3 ڕیز × 10 چرکە لەسەر کاغەزی ECG
class _StripPainter extends CustomPainter {
  _StripPainter(this.trace, this.rate, {this.reveal = 1});
  final List<double> trace;
  final double rate;
  final double reveal;

  @override
  void paint(Canvas c, Size s) {
    _GridPainter().paint(c, s);
    if (trace.length < 4) return;
    const rows = 3;
    final per = (trace.length / rows).ceil();
    final rh = s.height / rows;
    final shown = (trace.length * reveal).round();
    final paint = Paint()
      ..color = _red
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round;
    final tp = TextPainter(textDirection: TextDirection.ltr);
    for (var r = 0; r < rows; r++) {
      final st = r * per;
      if (st >= shown) break;
      final en = math.min(shown, math.min(trace.length, st + per));
      final mid = rh * r + rh * .55;
      final dx = s.width / math.max(1, per - 1);
      final p = Path();
      for (var i = st; i < en; i++) {
        final pt = Offset((i - st) * dx, mid - trace[i] * rh * .4);
        if (i == st) {
          p.moveTo(pt.dx, pt.dy);
        } else {
          p.lineTo(pt.dx, pt.dy);
        }
      }
      c.drawPath(p, paint);
      // کاتی ڕیز
      final sec = rate > 0 ? (st / rate).round() : r * 10;
      tp.text = TextSpan(text: '${sec}s', style: _n(9.5, w: FontWeight.w600, c: _mu));
      tp.layout();
      tp.paint(c, Offset(6, rh * r + 4));
    }
  }

  @override
  bool shouldRepaint(covariant _StripPainter o) => o.reveal != reveal || o.trace != trace;
}

/// وێنەی دەست و Band (ڕەش و سپی، شێوازی تیشکی X)
///   mode 0 = ڕێنمایی (بینینی لاوە، نیشانەی «یەک پەنجە لە سەرووی ئێسکی مەچەک»)
///   mode 1 = پێوانە (پەنجەی دەستی تر دێت و دەست لە ئەلیکترۆد دەدات)
class _WristArt extends CustomPainter {
  _WristArt({required this.mode, required this.t, required this.right});
  final int mode;
  final double t;
  final bool right;

  @override
  void paint(Canvas c, Size s) {
    final w = s.width, h = s.height;
    c.save();
    // دەستی ڕاست ← وێنەکە هەڵدەگێڕدرێتەوە
    if (right) {
      c.translate(w, 0);
      c.scale(-1, 1);
    }
    final cy = h * (mode == 0 ? .46 : .40);
    final armH = h * .2;
    final wristX = w * .40;

    // ── باسک ──
    final arm = Path()
      ..moveTo(w + 10, cy - armH * .62)
      ..cubicTo(w * .78, cy - armH * .6, w * .58, cy - armH * .5, wristX, cy - armH * .46)
      ..lineTo(wristX, cy + armH * .46)
      ..cubicTo(w * .58, cy + armH * .52, w * .78, cy + armH * .62, w + 10, cy + armH * .66)
      ..close();
    final armShader = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: const [Color(0xFFEDEDED), Color(0xFF9A9A9A), Color(0xFF3A3A3A)],
      stops: const [0, .55, 1],
    ).createShader(Rect.fromLTWH(0, cy - armH, w, armH * 2));
    c.drawPath(arm, Paint()
      ..color = const Color(0x33FFFFFF)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10));
    c.drawPath(arm, Paint()..shader = armShader);

    // ── مشت (دەستی پێچراو) ──
    final hand = Path()
      ..moveTo(wristX + 4, cy - armH * .46)
      ..cubicTo(w * .30, cy - armH * .62, w * .22, cy - armH * .78, w * .14, cy - armH * .55)
      ..cubicTo(w * .07, cy - armH * .35, w * .06, cy + armH * .15, w * .12, cy + armH * .42)
      ..cubicTo(w * .17, cy + armH * .62, w * .30, cy + armH * .6, wristX + 4, cy + armH * .46)
      ..close();
    c.drawPath(hand, Paint()..shader = armShader);
    // ئیسکی پەنجەکان (هێڵی کاڵ)
    final kn = Paint()
      ..color = const Color(0x55000000)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 3; i++) {
      final y = cy - armH * .2 + i * armH * .22;
      c.drawPath(
          Path()
            ..moveTo(w * .10 + i * 1.5, y)
            ..quadraticBezierTo(w * .16, y - 4, w * .24, y + 1),
          kn);
    }
    // پەنجە گەورە
    final thumb = Path()
      ..moveTo(w * .30, cy + armH * .30)
      ..quadraticBezierTo(w * .22, cy + armH * .62, w * .14, cy + armH * .50);
    c.drawPath(thumb, kn..strokeWidth = 2);

    // ── Band ──
    final bx = wristX + w * .07;
    final bandW = w * .085;
    final strap = RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(bx, cy), width: bandW, height: armH * 1.32), const Radius.circular(8));
    c.drawRRect(strap, Paint()..color = const Color(0xFF121212));
    final tex = Paint()
      ..color = const Color(0xFF2A2A2A)
      ..strokeWidth = 1;
    for (double y = strap.top + 4; y < strap.bottom - 4; y += 4) {
      c.drawLine(Offset(strap.left + 3, y), Offset(strap.right - 3, y + 2), tex);
    }
    c.drawRRect(strap, Paint()
      ..color = const Color(0xFF4A4A4A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4);

    // ئەلیکترۆد (کانزا)
    final el = RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(bx, cy + armH * .1), width: bandW * .72, height: armH * .34), const Radius.circular(5));

    // ئەلیکترۆد
    c.drawRRect(el, Paint()
      ..shader = const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFFF5F5F5), Color(0xFF9C9C9C)])
          .createShader(el.outerRect));
    c.drawRRect(el, Paint()
      ..color = const Color(0x66FFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2));

    if (mode == 0) {
      // نیشانەی «یەک پەنجە» لە نێوان Band و ئێسکی مەچەک
      final mk = Paint()
        ..color = const Color(0xFFD6F55B)
        ..strokeWidth = 1.6
        ..style = PaintingStyle.stroke;
      final y0 = cy - armH * .95;
      final a = 0.6 + 0.4 * math.sin(t * math.pi * 2);
      mk.color = mk.color.withValues(alpha: a);
      c.drawLine(Offset(wristX, y0), Offset(bx - bandW / 2, y0), mk);
      c.drawLine(Offset(wristX, y0 - 5), Offset(wristX, y0 + 5), mk);
      c.drawLine(Offset(bx - bandW / 2, y0 - 5), Offset(bx - bandW / 2, y0 + 5), mk);
      c.drawCircle(Offset(wristX, cy - armH * .46), 3, Paint()..color = const Color(0xFFD6F55B).withValues(alpha: a));
    } else {
      // پەنجە دێت ← دەست دەدات ← بازنەی پەیوەندی
      final p = (t * 1.0) % 1.0;
      final approach = Curves.easeInOutCubic.transform((p / .45).clamp(0.0, 1.0));
      final touching = p > .45 && p < .9;
      final tip = Offset(bx, el.center.dy + 2);
      final start = Offset(bx + w * .18, h + 30);
      final cur = Offset.lerp(start, tip + const Offset(0, 6), approach)!;
      // پەنجە (کەپسوول)
      final dir = (tip - start);
      final ang = math.atan2(dir.dy, dir.dx);
      c.save();
      c.translate(cur.dx, cur.dy);
      c.rotate(ang + math.pi);
      final fw = bandW * .62;
      final finger = RRect.fromRectAndRadius(Rect.fromLTWH(0, -fw / 2, h * .62, fw), Radius.circular(fw / 2));
      c.drawRRect(finger, Paint()
        ..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFF2F2F2), Color(0xFF8C8C8C)])
            .createShader(finger.outerRect));
      // نینۆک
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(fw * .18, -fw * .3, fw * .7, fw * .6), Radius.circular(fw * .3)), Paint()..color = const Color(0x33000000));
      c.restore();
      // بازنەکانی پەیوەندی
      if (touching) {
        final k = ((p - .45) / .45);
        for (var i = 0; i < 2; i++) {
          final kk = (k + i * .5) % 1.0;
          c.drawCircle(el.center, 10 + kk * 46, Paint()
            ..color = const Color(0xFF5CC68A).withValues(alpha: (1 - kk) * .7)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2);
        }
      }
    }
    c.restore();
  }

  @override
  bool shouldRepaint(covariant _WristArt o) => o.t != t || o.right != right || o.mode != mode;
}

/// تەنها بۆ debug: کە Band نییە نموونەکە دیار بێت
bool get ecgDemoAllowed => kDebugMode;
