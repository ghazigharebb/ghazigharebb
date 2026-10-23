// VEX Health — 6 زمانی ئەپ و دەقەکانی بەشی سەرەتا (زمان، بەخێرهاتن، پرسیاری Band)
// ئەم فایلە لە ڕێگەی سکریپتەوە دروست کراوە.
// هەر زمانێک فایلی خۆی هەیە لە lib/lang/
import '../lang/lang_en_english.dart';
import '../lang/lang_ckb_kurdish_sorani.dart';
import '../lang/lang_kmr_kurdish_badini.dart';
import '../lang/lang_ar_arabic.dart';
import '../lang/lang_fa_persian.dart';
import '../lang/lang_tr_turkish.dart';

export '../lang/lang_en_english.dart' show kFeatEn;
export '../lang/lang_ar_arabic.dart' show kFeatAr;
export '../lang/lang_fa_persian.dart' show kFeatFa;
export '../lang/lang_tr_turkish.dart' show kFeatTr;

class RLang {
  const RLang(this.code, this.native, this.english, this.flag, this.rtl, this.t);
  final String code;
  final String native;
  final String english;

  /// ئیمۆجی ئاڵا؛ 'KU' = ئاڵای کوردستان (دەکێشرێت)
  final String flag;
  final bool rtl;
  final Map<String, String> t;
}

const List<RLang> kLangs = [kRegEn, kRegCkb, kRegBd, kRegAr, kRegFa, kRegTr];


const String kKuFlagSvg = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 60 40" preserveAspectRatio="xMidYMid slice" aria-hidden="true"><rect width="60" height="13.4" fill="#ED2024"/><rect y="13.3" width="60" height="13.4" fill="#fff"/><rect y="26.6" width="60" height="13.4" fill="#278E43"/><circle cx="30" cy="20" r="6.2" fill="#FEBD11"/><circle cx="30" cy="20" r="9.4" fill="none" stroke="#FEBD11" stroke-width="3.4" stroke-dasharray="1.45 1.45"/></svg>';
