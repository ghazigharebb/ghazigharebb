// VEX Plus — دۆخی بەشداربوون (پلان، ماوە، تاقیکردنەوەی خۆڕایی، دیاری Band)
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// پلانێکی بەشداربوون
class PlusPlan {
  const PlusPlan({
    required this.key,
    required this.name,
    required this.sub,
    required this.oldPrice,
    required this.price,
    required this.days,
    required this.unit,
    this.badge = '',
  });
  final String key;
  final String name; // «6 مانگ»
  final String sub;
  final int oldPrice; // دینار، پێش داشکان
  final int price; // دینار، دوای 50٪ داشکان
  final int days;
  final String unit; // «د.ع / مانگ»
  final String badge;
}

const List<PlusPlan> kPlusPlans = [
  PlusPlan(key: 'month', name: '1 مانگ', sub: 'هەر کاتێک ڕایبگرە', oldPrice: 10000, price: 5000, days: 30, unit: 'د.ع / مانگ'),
  PlusPlan(
      key: 'half',
      name: '6 مانگ',
      sub: 'وەک 4,167 د.ع لە مانگێکدا',
      oldPrice: 50000,
      price: 25000,
      days: 180,
      unit: 'د.ع / 6 مانگ',
      badge: 'باوترین'),
  PlusPlan(
      key: 'year',
      name: '12 مانگ',
      sub: 'نرخی 50٪ بۆ ساڵێک قفڵ دەبێت',
      oldPrice: 100000,
      price: 50000,
      days: 365,
      unit: 'د.ع / ساڵ',
      badge: 'باشترین بەها'),
];

PlusPlan plusPlanOf(String key) => kPlusPlans.firstWhere((p) => p.key == key, orElse: () => kPlusPlans.last);

/// ڕێگای پارەدان. بۆ پارەدانی ڕاستەقینە (FIB, FastPay, ZainCash, Qi Card) ئەمە بگۆڕە بە API ی خۆت.
/// دەبێت `true` بگەڕێنێتەوە ئەگەر پارەکە بە سەرکەوتوویی وەرگیرا، و `false` یان exception ئەگەر نا.
/// ئاگاداری: چالاککردنی Plus دەبێت لەلایەن سێرڤەرەوە پشتڕاست بکرێتەوە (نەک تەنها لە مۆبایل).
abstract class PlusPayment {
  static Future<bool> Function(String method, PlusPlan plan) charge = _demo;

  static Future<bool> _demo(String method, PlusPlan plan) async {
    await Future<void>.delayed(const Duration(milliseconds: 1500));
    return true; // دیمۆ: هیچ پارەیەک نابڕدرێت
  }
}

class PlusState extends ChangeNotifier {
  PlusState._();
  static final PlusState I = PlusState._();

  static const _kPlan = 'vex_plus_plan';
  static const _kUntil = 'vex_plus_until';
  static const _kSrc = 'vex_plus_src';
  static const _kTrial = 'vex_plus_trial';
  static const _kGift = 'vex_plus_gift';

  String plan = 'free'; // free | plus
  int until = 0; // ms
  String src = ''; // trial | band | month | half | year
  bool trialUsed = false;
  bool bandGiftUsed = false;

  bool get isPro => plan != 'free' && until > DateTime.now().millisecondsSinceEpoch;
  bool get canTrial => !trialUsed && !isPro;

  int get daysLeft {
    final ms = until - DateTime.now().millisecondsSinceEpoch;
    return ms <= 0 ? 0 : (ms / 86400000).ceil();
  }

  String get untilText {
    final d = DateTime.fromMillisecondsSinceEpoch(until);
    return '${d.year}/${d.month}/${d.day}';
  }

  Future<void> load() async {
    try {
      final sp = await SharedPreferences.getInstance();
      plan = sp.getString(_kPlan) ?? 'free';
      until = sp.getInt(_kUntil) ?? 0;
      src = sp.getString(_kSrc) ?? '';
      trialUsed = sp.getBool(_kTrial) ?? false;
      bandGiftUsed = sp.getBool(_kGift) ?? false;
    } catch (_) {}
    notifyListeners();
  }

  Future<void> _save() async {
    try {
      final sp = await SharedPreferences.getInstance();
      await sp.setString(_kPlan, plan);
      await sp.setInt(_kUntil, until);
      await sp.setString(_kSrc, src);
      await sp.setBool(_kTrial, trialUsed);
      await sp.setBool(_kGift, bandGiftUsed);
    } catch (_) {}
  }

  int _base() {
    final now = DateTime.now().millisecondsSinceEpoch;
    return isPro && until > now ? until : now;
  }

  /// پاش پارەدانی سەرکەوتوو (یان دەستپێکردنی تاقیکردنەوە)
  Future<void> activate(PlusPlan p, {bool trial = false}) async {
    plan = 'plus';
    if (trial) {
      until = DateTime.now().millisecondsSinceEpoch + 7 * 86400000;
      src = 'trial';
      trialUsed = true;
    } else {
      until = _base() + p.days * 86400000;
      src = p.key;
    }
    await _save();
    notifyListeners();
  }

  /// 6 مانگ بە خۆڕایی کاتێک یەکەم جار Band پەیوەست دەکرێت (تەنها یەک جار). `true` ئەگەر دیاریەکە درا.
  Future<bool> grantBandGift() async {
    if (bandGiftUsed) return false;
    bandGiftUsed = true;
    plan = 'plus';
    until = _base() + 180 * 86400000;
    src = 'band';
    await _save();
    notifyListeners();
    return true;
  }
}
