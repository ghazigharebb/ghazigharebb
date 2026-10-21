// VEX Health — خاڵی دەستپێکردنی ئەپ
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'alerts/band_alerts.dart';
import 'arena/arena_host.dart';
import 'band/band_state.dart';
import 'core/icons.dart';
import 'core/store.dart';
import 'core/theme.dart';
import 'family/family_data.dart';
import 'food/food_db.dart';
import 'health/health_screen.dart';
import 'home/home_screen.dart';
import 'notify/step_notify.dart';
import 'onboarding/account.dart';
import 'onboarding/profile_page.dart';
import 'onboarding/reg_lang_state.dart';
import 'onboarding/reg_flow.dart';
import 'scan/scan_page.dart';
import 'plus/plus_state.dart';
import 'splash/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark,
    systemNavigationBarColor: V.bg,
    systemNavigationBarIconBrightness: Brightness.light,
  ));
  // هەژمار پێش هەموو شتێک بار دەکرێت بۆ ئەوەی بزانین بەشی سەرەتا پیشان بدرێت یان نا
  await Account.I.load();
  await Store.I.load();
  await FamilyStore.I.load();
  await BandState.I.load(); // دۆخی پەیوەستبوونی Band
  await FoodDb.I.load(); // لیستی 500 خواردنەکە
  await BandAlerts.I.load(); // کاتژمێر، کاتی وەرزش و نوێژ
  await PlusState.I.load(); // VEX Plus
  await arenaStore.load(); // VEX Arena
  await LangState.I.load(); // زمانی هەڵبژێردراوی بەشی سەرەتا
  await StepNotify.I.load(); // ئاگادارکردنەوەی هەنگاو (ئەگەر کرابێتەوە)
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final base = ThemeData(brightness: Brightness.dark, useMaterial3: true);
    return MaterialApp(
      title: 'VEX Health',
      debugShowCheckedModeBanner: false,
      navigatorKey: navKey,
      theme: base.copyWith(
        scaffoldBackgroundColor: V.bg,
        colorScheme: ColorScheme.fromSeed(seedColor: V.cy, brightness: Brightness.dark),
        textTheme: GoogleFonts.notoSansArabicTextTheme(base.textTheme),
        splashFactory: NoSplash.splashFactory,
        highlightColor: Colors.transparent,
      ),
      // هەموو ئەپەکە ڕاست بۆ چەپ (کوردی)
      builder: (context, child) => Directionality(
        textDirection: TextDirection.rtl,
        child: child ?? const SizedBox.shrink(),
      ),
      home: const Shell(),
    );
  }
}

class Shell extends StatefulWidget {
  const Shell({super.key});

  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int tab = 0;
  bool _splash = true;

  /// بەشی سەرەتا (تۆمارکردن / چوونە ژوورەوە) لە سەر ئەپەکە
  bool _reg = Account.I.need;
  bool _revealing = false;
  int _regGen = 0;

  @override
  void initState() {
    super.initState();
    Account.I.addListener(_onAccount);
  }

  @override
  void dispose() {
    Account.I.removeListener(_onAccount);
    super.dispose();
  }

  /// دوای چوونە دەرەوە بەشی سەرەتا دەگەڕێتەوە
  void _onAccount() {
    if (Account.I.need && !_reg && mounted) {
      setState(() {
        _reg = true;
        _revealing = false;
        _regGen++;
        tab = 0;
      });
    }
  }

  static const List<String> _names = ['سەرەکی', 'تەندروستی', 'VEX AI', 'وەرزش', 'پرۆفایل'];

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    return Scaffold(
      backgroundColor: V.bg,
      body: Stack(
        children: [
          // کاتێک بەشی سەرەتا کراوەیە، جووڵەکانی ئەپەکەی ژێرەوە دەوەستن (بێ لاگ)
          Positioned.fill(
            child: TickerMode(
              enabled: !_reg || _revealing,
              child: Stack(
                children: [
                const Positioned.fill(child: Aurora()),
                Positioned.fill(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 380),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    layoutBuilder: (current, previous) => Stack(
                      fit: StackFit.expand,
                      children: [...previous, if (current != null) current],
                    ),
                    transitionBuilder: (child, anim) => FadeTransition(
                      opacity: anim,
                      child: SlideTransition(
                        position: Tween<Offset>(begin: const Offset(0, 0.02), end: Offset.zero).animate(anim),
                        child: child,
                      ),
                    ),
                    child: tab == 0
                        ? const HomeScreen(key: ValueKey<int>(0))
                        : tab == 1
                            ? const HealthScreen(key: ValueKey<int>(1))
                            : tab == 4
                                ? ProfilePage(key: const ValueKey<int>(4), onTab: (i) => setState(() => tab = i))
                                : SoonPage(key: ValueKey<int>(tab), title: _names[tab]),
                  ),
                ),
                Positioned(
                  left: 12,
                  right: 12,
                  bottom: mq.padding.bottom + 12,
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 416),
                      child: VNav(index: tab, onTap: (i) => setState(() => tab = i)),
                    ),
                  ),
                ),
                ],
              ),
            ),
          ),
          // تۆمارکردن / چوونە ژوورەوە — لە کۆتاییدا بە بازنەیەکی گەورەبوو ئەپەکە دەردەکەوێت
          if (_reg)
            Positioned.fill(
              child: RegFlow(
                key: ValueKey<int>(_regGen),
                ready: !_splash,
                onReveal: () {
                  if (mounted) setState(() => _revealing = true);
                },
                onDone: () {
                  if (mounted) {
                    setState(() {
                      _reg = false;
                      _revealing = false;
                      tab = 0;
                    });
                  }
                },
              ),
            ),
          // دیمەنی دەستپێک لە سەر هەموو شتێک
          if (_splash)
            Positioned.fill(
              child: VexSplash(onDone: () {
                if (mounted) setState(() => _splash = false);
                // Android: ئەگەر لە کاتی وێنەگرتندا ئەپەکە داخرابوو، وێنەکە دەگەڕێتەوە بۆ سکان
                if (!Account.I.need) recoverLostScan();
              }),
            ),
        ],
      ),
    );
  }
}

/// بەشەکانی تر — دواتر بۆ Flutter دەگوازرێنەوە
class SoonPage extends StatelessWidget {
  const SoonPage({super.key, required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🚧', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Text(title, style: ku(20, w: FontWeight.w800)),
            const SizedBox(height: 6),
            Text(
              'ئەم بەشە لە هەنگاوی داهاتوودا بۆ Flutter دەگوازرێتەوە',
              textAlign: TextAlign.center,
              style: ku(13, c: V.mu, h: 1.8),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------- شریتی خوارەوە ----------
class VNav extends StatelessWidget {
  const VNav({super.key, required this.index, required this.onTap});
  final int index;
  final ValueChanged<int> onTap;

  Widget _item(int i, String icon, String label) {
    final on = index == i;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onTap(i),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: on ? op(V.cy, 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            svgIcon(icon, on ? '#8ff3f9' : '#8cb7bf', size: 22),
            const SizedBox(height: 4),
            Text(label, style: ku(11, w: FontWeight.w700, c: on ? V.c2 : V.mu, h: 1.2)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // بەرزی 84 = 70 ـی شریتەکە + 14 بۆ دوگمەی AI کە بەرزترە،
    // بۆ ئەوەی هەموو دوگمەکە دەست لێدانی وەربگرێت (هیچ گۆڕانێکی بینراو نییە)
    return SizedBox(
      height: 84,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          const Positioned(top: 14, left: 0, right: 0, bottom: 0, child: Glass(child: SizedBox.expand())),
          Positioned(
            top: 14,
            left: 0,
            right: 0,
            bottom: 0,
            child: Row(
              children: [
                Expanded(child: _item(0, Ico.home, 'سەرەکی')),
                Expanded(child: _item(1, Ico.heart, 'تەندروستی')),
                const SizedBox(width: 78),
                Expanded(child: _item(3, Ico.run, 'وەرزش')),
                Expanded(child: _item(4, Ico.user, 'پرۆفایل')),
              ],
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Center(
              child: Press(
                onTap: () => onTap(2),
                child: Container(
                  width: 62,
                  height: 62,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF0B3A52), Color(0xFF17104A)],
                    ),
                    border: Border.all(color: V.cy, width: 2),
                    boxShadow: [BoxShadow(color: op(V.cy, index == 2 ? 0.6 : 0.35), blurRadius: 24)],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      svgIcon(Ico.spark, '#8ff3f9', size: 20, fill: true),
                      Text('AI', style: nu(12, c: Colors.white, h: 1.2)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
