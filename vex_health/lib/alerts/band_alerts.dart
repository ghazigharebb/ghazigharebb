// VEX Health — ئاگادارکەرەوەی Band (لەرین)
//
// سێ بەش: ١) کاتژمێری لەرین  ٢) کاتی وەرزش (کەمبوونەوە بە میلی چرکە)  ٣) کاتەکانی نوێژ.
//
// چۆن کار دەکات:
//  • کاتێک ئەپ کراوەیە، کاتژمێرێکی ناوخۆیی هەر چرکەیەک دەپشکنێت و دەلەرێتەوە + پەنجەرەی «ڕاگرتن» نیشان دەدات.
//  • کاتێک ئەپ داخراوە، هەمان کاتەکان وەک ئاگادارکردنەوەی خشتەکراو (zonedSchedule) لە سیستەم تۆمار دەکرێن.
//  • لەرینی خودی Band: BandLink.syncAlerts / BandLink.vibrate — پردێکی MethodChannel ـە ('vex/band').
//    ئەگەر ناتیڤی BLE ـی Band نەنووسرابێت، ئەم پردە بێدەنگ پشتگوێ دەخرێت و مۆبایلەکە دەلەرێتەوە (بڕوانە ALERTS.md).
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../band/band_emblem.dart';
import '../core/theme.dart';
import 'prayer_calc.dart';
import 'prayer_site.dart';

// ---------------------------------------------------------------
// پردی Band
// ---------------------------------------------------------------
class BandLink {
  BandLink._();
  static const MethodChannel _ch = MethodChannel('vex/band');

  /// فەرمانی لەرین بنێرە بۆ Band (ئەگەر پردەکە هەبێت). true = Band وەڵامی دایەوە.
  static Future<bool> vibrate({List<int> pattern = const [500, 250, 500, 250, 900]}) async {
    try {
      final r = await _ch.invokeMethod<bool>('vibrate', {'pattern': pattern});
      return r ?? false;
    } on MissingPluginException {
      return false;
    } catch (_) {
      return false;
    }
  }

  /// لیستی ئاگادارکەرەوەکان بنێرە بۆ Band بۆ ئەوەی لە خۆیەوە بلەرێتەوە ئەگەر مۆبایل نزیک نەبوو
  static Future<void> syncAlerts(List<Map<String, Object?>> triggers) async {
    try {
      await _ch.invokeMethod<void>('syncAlerts', {'json': jsonEncode(triggers)});
    } catch (_) {}
  }
}

/// لەرینی بەردەوام لە کاتی ئاگادارکردنەوە
class BandHaptics {
  BandHaptics._();
  static Timer? _t;

  static void start() {
    stop();
    _buzz();
    _t = Timer.periodic(const Duration(milliseconds: 1400), (_) => _buzz());
  }

  static void _buzz() {
    HapticFeedback.vibrate();
    BandLink.vibrate();
  }

  static void stop() {
    _t?.cancel();
    _t = null;
  }
}

// ---------------------------------------------------------------
// مۆدێلەکان
// ---------------------------------------------------------------
class AlarmItem {
  AlarmItem({required this.id, required this.h, required this.m, this.on = true, this.label = ''});
  final int id;
  int h;
  int m;
  bool on;
  String label;

  Map<String, Object?> toJson() => {'id': id, 'h': h, 'm': m, 'on': on, 'label': label};
  factory AlarmItem.fromJson(Map<String, dynamic> j) => AlarmItem(
        id: (j['id'] as num).toInt(),
        h: (j['h'] as num).toInt(),
        m: (j['m'] as num).toInt(),
        on: j['on'] != false,
        label: (j['label'] ?? '') as String,
      );
}

String fmt12(int h, int m) => '${((h + 11) % 12) + 1}:${m.toString().padLeft(2, '0')}';
String ampm(int h) => h < 12 ? 'AM' : 'PM';

// ---------------------------------------------------------------
// ئەنجنی ئاگادارکەرەوەکان
// ---------------------------------------------------------------
class BandAlerts extends ChangeNotifier {
  BandAlerts._();
  static final BandAlerts I = BandAlerts._();

  static const String _prefKey = 'vex_band_alerts';
  static const String _siteKey = 'vex_if_cache';
  static const String _chan = 'vex_band_alerts';
  static const int _timerId = 2000000001;

  final FlutterLocalNotificationsPlugin _np = FlutterLocalNotificationsPlugin();
  SharedPreferences? _sp;
  Timer? _tick;
  bool _ready = false;

  // کاتژمێر
  final List<AlarmItem> alarms = [];

  // نوێژ
  bool prayerOn = false;
  String city = 'erbil';
  double? gpsLat;
  double? gpsLng;
  int lead = 0; // خولەک پێش بانگ
  final Map<String, bool> prayerItems = {for (final k in kPrayerKeys) k: true};

  // کاتی وەرزش
  int th = 0, tmin = 5, ts = 0;
  int timerEndMs = 0;
  int timerLeftMs = 0;
  bool timerRunning = false;

  final Map<String, bool> _fired = {};

  // کاتەکانی IslamicFinder (تەنها هەولێر): 'y-m-d' ← {نوێژ: خولەک}
  final Map<String, Map<String, int>> _site = {};
  int siteFetchedMs = 0;
  bool siteBusy = false;
  bool siteFailed = false;

  // ---------- بارکردن / پاشەکەوتکردن ----------
  Future<void> load() async {
    try {
      _sp = await SharedPreferences.getInstance();
      final raw = _sp!.getString(_prefKey);
      if (raw != null) {
        final j = jsonDecode(raw) as Map<String, dynamic>;
        alarms
          ..clear()
          ..addAll(((j['alarms'] ?? []) as List).map((e) => AlarmItem.fromJson(Map<String, dynamic>.from(e as Map))));
        final p = (j['pray'] ?? {}) as Map;
        prayerOn = p['on'] == true;
        city = (p['city'] ?? 'erbil') as String;
        gpsLat = (p['lat'] as num?)?.toDouble();
        gpsLng = (p['lng'] as num?)?.toDouble();
        lead = ((p['lead'] ?? 0) as num).toInt();
        final it = (p['items'] ?? {}) as Map;
        for (final k in kPrayerKeys) {
          prayerItems[k] = it[k] != false;
        }
        final t = (j['tm'] ?? {}) as Map;
        th = ((t['h'] ?? 0) as num).toInt();
        tmin = ((t['m'] ?? 5) as num).toInt();
        ts = ((t['s'] ?? 0) as num).toInt();
        timerEndMs = ((t['end'] ?? 0) as num).toInt();
        timerLeftMs = ((t['left'] ?? 0) as num).toInt();
        timerRunning = t['run'] == true && timerEndMs > DateTime.now().millisecondsSinceEpoch;
        if (!timerRunning) timerEndMs = 0;
      }
      final sc = _sp!.getString(_siteKey);
      if (sc != null) {
        final j = jsonDecode(sc) as Map<String, dynamic>;
        siteFetchedMs = ((j['at'] ?? 0) as num).toInt();
        ((j['days'] ?? {}) as Map).forEach((k, v) {
          _site[k as String] = {for (final e in (v as Map).entries) e.key as String: (e.value as num).toInt()};
        });
      }
    } catch (e) {
      if (kDebugMode) debugPrint('BandAlerts.load: $e');
    }
    await _initPlugin();
    _tick?.cancel();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) => _onTick());
    _ready = true;
    unawaited(_reschedule());
    notifyListeners();
    unawaited(refreshSite());
  }

  /// نوێکردنەوەی کاتەکان لە IslamicFinder (هەر 12 کاتژمێر جارێک، یان بە زۆر)
  Future<bool> refreshSite({bool force = false}) async {
    if (siteBusy) return false;
    final now = DateTime.now();
    final fresh = now.millisecondsSinceEpoch - siteFetchedMs < 12 * 3600 * 1000;
    final hasToday = _site.containsKey(_dayKey(now));
    if (!force && fresh && hasToday) return true;
    siteBusy = true;
    siteFailed = false;
    notifyListeners();
    final res = await IslamicFinder.fetchMonth(now, (d) => PrayerCalc.compute(d, 36.19, 44.01));
    siteBusy = false;
    if (res == null) {
      siteFailed = true;
      notifyListeners();
      return false;
    }
    _site.removeWhere((k, _) => k.startsWith('${now.year}-${now.month}-'));
    res.forEach((d, t) => _site['${now.year}-${now.month}-$d'] = t);
    siteFetchedMs = now.millisecondsSinceEpoch;
    try {
      await _sp?.setString(_siteKey, jsonEncode({'at': siteFetchedMs, 'days': _site}));
    } catch (_) {}
    notifyListeners();
    unawaited(_reschedule());
    return true;
  }

  /// کاتەکانی ئەمڕۆ لە IslamicFinder وەرگیراون؟
  bool get fromSite => city == 'erbil' && _site.containsKey(_dayKey(DateTime.now()));

  Future<void> _save() async {
    try {
      await _sp?.setString(
        _prefKey,
        jsonEncode({
          'alarms': alarms.map((a) => a.toJson()).toList(),
          'pray': {
            'on': prayerOn,
            'city': city,
            'lat': gpsLat,
            'lng': gpsLng,
            'lead': lead,
            'items': prayerItems,
          },
          'tm': {'h': th, 'm': tmin, 's': ts, 'end': timerEndMs, 'left': timerLeftMs, 'run': timerRunning},
        }),
      );
    } catch (_) {}
  }

  /// دوای هەموو گۆڕانکارییەک: پاشەکەوت + دووبارە خشتەکردن
  Future<void> changed() async {
    notifyListeners();
    await _save();
    await _reschedule();
  }

  // ---------- شوێن و کاتەکانی نوێژ ----------
  ({String name, double lat, double lng}) get place {
    if (city == 'gps' && gpsLat != null && gpsLng != null) {
      return (name: 'شوێنی ئێستا', lat: gpsLat!, lng: gpsLng!);
    }
    final c = kCities.firstWhere((x) => x.key == city, orElse: () => kCities.first);
    return (name: c.name, lat: c.lat, lng: c.lng);
  }

  Map<String, int> prayerTimes(DateTime d) {
    if (city == 'erbil') {
      final s = _site[_dayKey(d)];
      if (s != null) return s;
    }
    final p = place;
    return PrayerCalc.compute(d, p.lat, p.lng);
  }

  /// نوێژی داهاتوو و کاتی تەواوی
  ({String key, DateTime at}) nextPrayer([DateTime? now]) {
    final n = now ?? DateTime.now();
    final t = prayerTimes(n);
    final nm = n.hour * 60 + n.minute + n.second / 60.0;
    for (final k in kPrayerKeys) {
      if (t[k]! > nm) {
        return (key: k, at: DateTime(n.year, n.month, n.day, t[k]! ~/ 60, t[k]! % 60));
      }
    }
    final tm = DateTime(n.year, n.month, n.day).add(const Duration(days: 1, hours: 12));
    final t2 = prayerTimes(tm);
    return (key: 'fajr', at: DateTime(tm.year, tm.month, tm.day, t2['fajr']! ~/ 60, t2['fajr']! % 60));
  }

  // ---------- کاتی وەرزش ----------
  int get timerRemainingMs {
    if (timerRunning) return (timerEndMs - DateTime.now().millisecondsSinceEpoch).clamp(0, 1 << 40).toInt();
    if (timerLeftMs > 0) return timerLeftMs;
    return (th * 3600 + tmin * 60 + ts) * 1000;
  }

  Future<bool> timerStart() async {
    final ms = timerRemainingMs;
    if (ms <= 0) return false;
    await ensurePermission();
    timerLeftMs = 0;
    timerEndMs = DateTime.now().millisecondsSinceEpoch + ms;
    timerRunning = true;
    await changed();
    return true;
  }

  Future<void> timerPause() async {
    timerLeftMs = timerRemainingMs < 1 ? 1 : timerRemainingMs;
    timerRunning = false;
    timerEndMs = 0;
    await changed();
  }

  Future<void> timerReset() async {
    timerRunning = false;
    timerEndMs = 0;
    timerLeftMs = 0;
    await changed();
  }

  // ---------- ئەنجنی کاتژمێر ----------
  String _dayKey(DateTime d) => '${d.year}-${d.month}-${d.day}';

  void _onTick() {
    final now = DateTime.now();
    final nm = now.hour * 60 + now.minute;
    final dk = _dayKey(now);
    _fired.removeWhere((k, _) => !k.startsWith(dk));

    for (final a in alarms) {
      if (!a.on) continue;
      final id = '${dk}a${a.id}';
      if (a.h * 60 + a.m == nm && _fired[id] != true) {
        _fired[id] = true;
        _ring('⏰ ${a.label.isEmpty ? (kIsEn ? 'Alarm' : (kIsAr ? 'منبّه' : (kIsFa ? 'آلارم' : (kIsTr ? 'Alarm' : 'کاتژمێر')))) : a.label}', '${fmt12(a.h, a.m)} ${ampm(a.h)}');
      }
    }

    if (prayerOn) {
      final t = prayerTimes(now);
      for (final k in kPrayerKeys) {
        if (prayerItems[k] != true) continue;
        final id = '${dk}p$k';
        if (t[k]! - lead == nm && _fired[id] != true) {
          _fired[id] = true;
          final title = lead > 0 ? '$lead خولەک بۆ بانگی ${prayerShort(k)}' : 'کاتی ${prayerShort(k)} هات';
          _ring('🕌 $title', '${place.name} · ${fmt12(t[k]! ~/ 60, t[k]! % 60)} ${ampm(t[k]! ~/ 60)}');
        }
      }
    }

    if (timerRunning && timerEndMs > 0 && now.millisecondsSinceEpoch >= timerEndMs) {
      timerRunning = false;
      timerEndMs = 0;
      timerLeftMs = 0;
      _ring('⏱️ کاتی وەرزش تەواو بوو', 'باش بوو!');
      unawaited(_save());
      notifyListeners();
    }
  }

  // ---------- پەنجەرەی لەرین ----------
  bool _ringing = false;

  /// بۆ دوگمەی «تاقیکردنەوە»
  void test(String title, String sub) => _ring(title, sub);

  void _ring(String title, String sub) {
    final ctx = navKey.currentContext;
    if (ctx == null || _ringing) return;
    _ringing = true;
    BandHaptics.start();
    // خۆی دوای 60 چرکە دادەخرێت
    final auto = Timer(const Duration(seconds: 60), () {
      final c = navKey.currentState;
      if (_ringing && c != null && c.canPop()) c.pop();
    });
    showDialog<void>(
      context: ctx,
      barrierDismissible: false,
      barrierColor: vk(0xDB021218),
      builder: (c) => _RingDialog(title: title, sub: sub),
    ).whenComplete(() {
      auto.cancel();
      _ringing = false;
      BandHaptics.stop();
    });
  }

  // ---------- مۆڵەت ----------
  Future<void> ensurePermission() async {
    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        await Permission.notification.request();
        if (await Permission.scheduleExactAlarm.isDenied) {
          await Permission.scheduleExactAlarm.request();
        }
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        await _np
            .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
            ?.requestPermissions(alert: true, sound: true, badge: false);
      }
    } catch (_) {}
  }

  // ---------- خشتەکردنی ئاگادارکردنەوەی سیستەم (کاتێک ئەپ داخراوە) ----------
  Future<void> _initPlugin() async {
    try {
      tzdata.initializeTimeZones();
      await _np.initialize(const InitializationSettings(
        android: AndroidInitializationSettings('ic_stat_steps'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestSoundPermission: false,
          requestBadgePermission: false,
        ),
      ));
    } catch (e) {
      if (kDebugMode) debugPrint('BandAlerts.init: $e');
    }
  }

  NotificationDetails get _details => NotificationDetails(
        android: AndroidNotificationDetails(
          _chan,
          vxTr('ئاگادارکەرەوەی Band'),
          channelDescription: vxTr('کاتژمێر، کاتی وەرزش و کاتەکانی نوێژ'),
          importance: Importance.max,
          priority: Priority.high,
          category: AndroidNotificationCategory.alarm,
          enableVibration: true,
          vibrationPattern: Int64List.fromList([0, 500, 250, 500, 250, 900]),
          playSound: true,
          icon: 'ic_stat_steps',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentSound: true,
          interruptionLevel: InterruptionLevel.timeSensitive,
        ),
      );

  Future<void> _reschedule() async {
    if (!_ready) return;
    try {
      await _np.cancelAll();
      final now = DateTime.now();
      final jobs = <({int id, DateTime at, String title, String body})>[];

      // کاتژمێرەکان: 7 ڕۆژی داهاتوو
      for (final a in alarms.where((x) => x.on)) {
        for (var d = 0; d < 7; d++) {
          final at = DateTime(now.year, now.month, now.day + d, a.h, a.m);
          if (at.isAfter(now)) {
            jobs.add((
              id: 1000 + (a.id % 100000) * 10 + d,
              at: at,
              title: '⏰ ${a.label.isEmpty ? (kIsEn ? 'Alarm' : (kIsAr ? 'منبّه' : (kIsFa ? 'آلارم' : (kIsTr ? 'Alarm' : 'کاتژمێر')))) : a.label}',
              body: vxTr('${fmt12(a.h, a.m)} ${ampm(a.h)}'),
            ));
          }
        }
      }

      // نوێژەکان: 3 ڕۆژی داهاتوو
      if (prayerOn) {
        for (var d = 0; d < 3; d++) {
          final day = DateTime(now.year, now.month, now.day + d, 12);
          final t = prayerTimes(day);
          for (var i = 0; i < kPrayerKeys.length; i++) {
            final k = kPrayerKeys[i];
            if (prayerItems[k] != true) continue;
            final mins = t[k]! - lead;
            final at = DateTime(day.year, day.month, day.day, 0, mins);
            if (at.isAfter(now)) {
              jobs.add((
                id: 1500000000 + d * 10 + i,
                at: at,
                title: vxTr(lead > 0 ? '🕌 $lead خولەک بۆ بانگی ${prayerShort(k)}' : '🕌 کاتی ${prayerShort(k)} هات'),
                body: vxTr('${place.name} · ${fmt12(t[k]! ~/ 60, t[k]! % 60)} ${ampm(t[k]! ~/ 60)}'),
              ));
            }
          }
        }
      }

      // کاتی وەرزش
      if (timerRunning && timerEndMs > now.millisecondsSinceEpoch) {
        jobs.add((
          id: _timerId,
          at: DateTime.fromMillisecondsSinceEpoch(timerEndMs),
          title: vxTr('⏱️ کاتی وەرزش تەواو بوو'),
          body: vxTr('باش بوو!'),
        ));
      }

      jobs.sort((a, b) => a.at.compareTo(b.at));
      // iOS تەنها 64 ئاگادارکردنەوەی خشتەکراو قبوڵ دەکات
      final limit = defaultTargetPlatform == TargetPlatform.iOS ? 60 : 400;
      for (final j in jobs.take(limit)) {
        await _np.zonedSchedule(
          j.id,
          j.title,
          j.body,
          tz.TZDateTime.from(j.at, tz.UTC),
          _details,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        );
      }

      // بۆ Band: هەمان لیست
      unawaited(BandLink.syncAlerts([
        for (final j in jobs.take(limit)) {'id': j.id, 'at': j.at.millisecondsSinceEpoch, 'title': j.title},
      ]));
    } catch (e) {
      if (kDebugMode) debugPrint('BandAlerts.reschedule: $e');
    }
  }
}

// ---------------------------------------------------------------
// پەنجەرەی لەرین
// ---------------------------------------------------------------
class _RingDialog extends StatefulWidget {
  const _RingDialog({required this.title, required this.sub});
  final String title;
  final String sub;

  @override
  State<_RingDialog> createState() => _RingDialogState();
}

class _RingDialogState extends State<_RingDialog> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 520))
    ..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: 320,
            padding: const EdgeInsets.fromLTRB(20, 30, 20, 20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              gradient: LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [vk(0xFF0B4150), V.sheet],
              ),
              border: Border.all(color: vk(0x732FE6F3)),
              boxShadow: [BoxShadow(color: vk(0x662FE6F3), blurRadius: 50, spreadRadius: -12)],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedBuilder(
                  animation: _c,
                  builder: (_, child) => Transform.rotate(angle: (_c.value - 0.5) * 0.5, child: child),
                  child: const BandEmblem(size: 84),
                ),
                const SizedBox(height: 10),
                VText(widget.title, textAlign: TextAlign.center, style: ku(21, w: FontWeight.w800)),
                const SizedBox(height: 4),
                VText(widget.sub, textAlign: TextAlign.center, style: ku(13, w: FontWeight.w600, c: V.mu)),
                const SizedBox(height: 22),
                VBtn('ڕاگرتن', kind: BtnKind.prime, fontSize: 15, onTap: () => Navigator.of(context).pop()),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
