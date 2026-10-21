// VEX Health — کاتەکانی نوێژ
//
// ڕێگای Muslim World League (فەجر 18° · عیشا 17°) و عەسری شافیعی — هەمان ڕێگای IslamicFinder.
// بێ ئینتەرنێت کار دەکات و بۆ هەر ڕۆژێک دەژمێردرێت. لەگەڵ خشتەی IslamicFinder ی هەولێر بۆ ئۆکتۆبەری 2026
// بەراورد کراوە: ~90% هەمان خولەک، و زۆرترین جیاوازی 1 خولەک.
import 'dart:math' as math;

class City {
  const City(this.key, this.name, this.lat, this.lng);
  final String key;
  final String name;
  final double lat;
  final double lng;
}

const List<City> kCities = [
  City('erbil', 'هەولێر', 36.19, 44.01),
  City('slemani', 'سلێمانی', 35.56, 45.43),
  City('duhok', 'دهۆک', 36.87, 42.99),
  City('kirkuk', 'کەرکووک', 35.47, 44.39),
  City('mosul', 'موسڵ', 36.34, 43.13),
  City('baghdad', 'بەغدا', 33.31, 44.37),
  City('basra', 'بەسرە', 30.51, 47.78),
  City('najaf', 'نەجەف', 32.00, 44.34),
  City('halabja', 'هەڵەبجە', 35.18, 45.99),
  City('zakho', 'زاخۆ', 37.14, 42.68),
];

/// ناوی نوێژەکان: کلیل ← [ناو، ئیمۆجی]
const Map<String, List<String>> kPrayerNames = {
  'fajr': ['بەیانی (فەجر)', '🌄'],
  'sunrise': ['خۆرهەڵات', '🌅'],
  'dhuhr': ['نیوەڕۆ (ظوهر)', '☀️'],
  'asr': ['عەسر', '🌤️'],
  'maghrib': ['ئێوارە (مەغریب)', '🌇'],
  'isha': ['خەوتنان (عیشا)', '🌙'],
};

/// ئەو پێنج نوێژەی کە دەتوانرێت ئاگادارکەرەوەیان بۆ دابنرێت
const List<String> kPrayerKeys = ['fajr', 'dhuhr', 'asr', 'maghrib', 'isha'];

String prayerShort(String k) => (kPrayerNames[k]?[0] ?? k).split(' ').first;

class PrayerCalc {
  PrayerCalc._();

  // ڕێکخستنی بچووک بۆ نزیککردنەوە لە IslamicFinder (خولەک)
  static const Map<String, double> _off = {
    'fajr': 1.4,
    'sunrise': -0.5,
    'dhuhr': 0.6,
    'asr': 0.2,
    'maghrib': 1.55,
    'isha': 0.3,
  };

  static const double _r = math.pi / 180;
  static double _sin(double d) => math.sin(d * _r);
  static double _cos(double d) => math.cos(d * _r);
  static double _tan(double d) => math.tan(d * _r);
  static double _asin(double x) => math.asin(x) / _r;
  static double _acos(double x) => math.acos(x.clamp(-1.0, 1.0)) / _r;
  static double _acot(double x) => math.atan(1 / x) / _r;
  static double _fix(double a, double b) => a - b * (a / b).floorToDouble();

  /// کاتەکان وەک خولەک لە نیوەشەوی ناوخۆییەوە (0..1439)
  static Map<String, int> compute(DateTime date, double lat, double lng, {double? tz, double asrFactor = 1}) {
    final zone = tz ?? date.timeZoneOffset.inMinutes / 60.0;
    var y = date.year;
    var m = date.month;
    final d = date.day;
    if (m <= 2) {
      y--;
      m += 12;
    }
    final a = (y / 100).floor();
    final b = 2 - a + (a / 4).floor();
    final jd = (365.25 * (y + 4716)).floorToDouble() +
        (30.6001 * (m + 1)).floorToDouble() +
        d +
        b -
        1524.5 -
        lng / (15 * 24);

    ({double dec, double eq}) sp(double j) {
      final dd = j - 2451545;
      final g = _fix(357.529 + 0.98560028 * dd, 360);
      final q = _fix(280.459 + 0.98564736 * dd, 360);
      final l = _fix(q + 1.915 * _sin(g) + 0.020 * _sin(2 * g), 360);
      final e = 23.439 - 0.00000036 * dd;
      final ra = math.atan2(_cos(e) * _sin(l), _cos(l)) / _r / 15;
      return (dec: _asin(_sin(e) * _sin(l)), eq: q / 15 - _fix(ra, 24));
    }

    final s0 = sp(jd + 0.5);
    final noon = _fix(12 - s0.eq, 24) - lng / 15 + zone;

    double ang(double angle, bool rising) {
      var tt = noon;
      for (var i = 0; i < 2; i++) {
        final s = sp(jd + (tt - zone + lng / 15) / 24);
        final h = _acos((-_sin(angle) - _sin(s.dec) * _sin(lat)) / (_cos(s.dec) * _cos(lat))) / 15;
        tt = noon + (rising ? -h : h);
      }
      return tt;
    }

    double asr(double f) {
      final s = sp(jd + 0.5);
      final aa = -_acot(f + _tan((lat - s.dec).abs()));
      final h = _acos((-_sin(aa) - _sin(s.dec) * _sin(lat)) / (_cos(s.dec) * _cos(lat))) / 15;
      return noon + h;
    }

    const hz = 0.833;
    final raw = <String, double>{
      'fajr': ang(18, true),
      'sunrise': ang(hz, true),
      'dhuhr': noon + 1 / 60,
      'asr': asr(asrFactor),
      'maghrib': ang(hz, false),
      'isha': ang(17, false),
    };
    final out = <String, int>{};
    raw.forEach((k, v) {
      final mins = (v * 60 + (_off[k] ?? 0)).round();
      out[k] = ((mins % 1440) + 1440) % 1440;
    });
    return out;
  }
}
