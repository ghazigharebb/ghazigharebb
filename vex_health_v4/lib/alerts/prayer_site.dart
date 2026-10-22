// VEX Health — پەیوەندی بە IslamicFinder
//
// کاتەکانی بانگ لە هەمان پەڕەی IslamicFinder ی هەولێر دەخوێنرێنەوە:
//   https://www.islamicfinder.org/world/iraq/95446/erbil-prayer-times/
// خشتەی مانگانەی پەڕەکە شی دەکرێتەوە (فەجر، خۆرهەڵات، ظوهر، عەسر، مەغریب، عیشا).
//
// پاراستن: هەر ڕۆژێک کە لەگەڵ ژماردنی ناوخۆیی زیاتر لە 6 خولەک جیاواز بێت ڕەت دەکرێتەوە، بۆیە ئەگەر
// پەڕەکە شێوەی گۆڕا یان شی کردنەکە هەڵە بوو، کاتی هەڵە هەرگیز نیشان نادرێت و ژماردنی ناوخۆیی بەکاردێت.
import 'package:http/http.dart' as http;

class IslamicFinder {
  IslamicFinder._();

  static const String erbilUrl = 'https://www.islamicfinder.org/world/iraq/95446/erbil-prayer-times/';
  static const List<String> keys = ['fajr', 'sunrise', 'dhuhr', 'asr', 'maghrib', 'isha'];

  /// پەڕەکە دابەزێنە و خشتەی مانگەکە بگەڕێنەوە: ڕۆژی مانگ ← {نوێژ: خولەک لە نیوەشەو}
  /// null = نەتوانرا (ئینتەرنێت نییە / پەڕەکە گۆڕاوە)
  static Future<Map<int, Map<String, int>>?> fetchMonth(DateTime now, Map<String, int> Function(DateTime) local) async {
    try {
      final r = await http
          .get(Uri.parse(erbilUrl), headers: const {
            'User-Agent': 'Mozilla/5.0 (Linux; Android 13) AppleWebKit/537.36 Chrome/120 Mobile Safari/537.36',
            'Accept-Language': 'en',
          })
          .timeout(const Duration(seconds: 12));
      if (r.statusCode != 200) return null;
      final days = parseMonth(r.body);
      // بەراورد لەگەڵ ژماردنی ناوخۆیی
      final ok = <int, Map<String, int>>{};
      days.forEach((d, t) {
        final dt = DateTime(now.year, now.month, d, 12);
        if (dt.month != now.month) return;
        final l = local(dt);
        var good = true;
        for (final k in keys) {
          final a = t[k]!, b = l[k]!;
          var diff = (a - b).abs();
          if (diff > 720) diff = 1440 - diff;
          if (diff > 6) good = false;
        }
        if (good) ok[d] = t;
      });
      return ok.length >= 10 ? ok : null;
    } catch (_) {
      return null;
    }
  }

  static final RegExp _time = RegExp(r'(\d{1,2}):(\d{2})\s*([AaPp])\.?[Mm]\.?');

  static int? _toMin(String h, String m, String ap) {
    var hh = int.tryParse(h), mm = int.tryParse(m);
    if (hh == null || mm == null || hh < 1 || hh > 12 || mm > 59) return null;
    hh = hh % 12;
    if (ap.toLowerCase() == 'p') hh += 12;
    return hh * 60 + mm;
  }

  /// HTML ← خشتە. تەنها ڕیزەکانی شێوەی «14 Wed … 6 کات» وەردەگیرێن.
  static Map<int, Map<String, int>> parseMonth(String html) {
    final text = html
        .replaceAll(RegExp(r'<script[\s\S]*?</script>', caseSensitive: false), ' ')
        .replaceAll(RegExp(r'<style[\s\S]*?</style>', caseSensitive: false), ' ')
        .replaceAll(RegExp(r'<[^>]+>'), ' ')
        .replaceAll('&nbsp;', ' ')
        .replaceAll(RegExp(r'\s+'), ' ');
    const t = r'(\d{1,2}:\d{2}\s?[AaPp][Mm])';
    // ڕیز: ڕۆژ + ناوی ڕۆژ + (ڕۆژی هیجری + ناوی ڕۆژ)؟ + 6 کات
    final row = RegExp(
      r'(?:^|\s)(\d{1,2})\s+[A-Za-z]{3,9}\s+(?:\d{1,2}\s+(?:[A-Za-z]{3,9}\s+)?)?' + t + r'\s+' + t + r'\s+' + t + r'\s+' + t + r'\s+' + t + r'\s+' + t,
    );
    final out = <int, Map<String, int>>{};
    for (final m in row.allMatches(text)) {
      final day = int.tryParse(m.group(1)!);
      if (day == null || day < 1 || day > 31) continue;
      final vals = <int>[];
      for (var i = 2; i <= 7; i++) {
        final tm = _time.firstMatch(m.group(i)!);
        final v = tm == null ? null : _toMin(tm.group(1)!, tm.group(2)!, tm.group(3)!);
        if (v == null) break;
        vals.add(v);
      }
      if (vals.length != 6) continue;
      out.putIfAbsent(day, () => {for (var i = 0; i < 6; i++) keys[i]: vals[i]});
    }
    return out;
  }
}
