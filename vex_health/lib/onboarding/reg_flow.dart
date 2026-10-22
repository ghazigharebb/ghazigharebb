// VEX Health — بەشی سەرەتا: بەخێرهاتن، تۆمارکردن هەنگاو بە هەنگاو، چوونە ژوورەوە
//
// ڕیزبەندی هەنگاوەکان:
//   تۆمارکردنی نوێ:  بەخێرهاتن → ناو → شێوازی چوونەژوورەوە (مۆبایل / Gmail) → [مۆبایل → کۆد | Gmail] → ڕەگەز → ساڵ → بەرزی → کێش → ئامانج
//                     → چالاکی → ئامانجەکان → Band → [پەیوەستکردن] → خەو → تەندروستی
//                     → ئاگادارکردنەوە → پلان
//   هەژمارم هەیە:    بەخێرهاتن → شێواز → مۆبایل → کۆد (یان Gmail) → (ئەگەر هەژمارەکە لەم مۆبایلەدا هەبێت ڕاستەوخۆ دەکرێتەوە)
//                     ئەگەرنا: ناو → ڕەگەز → ... (هەمان ڕیز)
//
// کۆدی تاقیکردنەوە: 123456
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../band/band_emblem.dart';
import '../core/icons.dart';
import '../core/theme.dart';
import 'account.dart';
import 'reg_build.dart';
import 'reg_data.dart';
import 'reg_done.dart';
import '../plus/plus_page.dart';
import '../plus/plus_state.dart';
import 'reg_gauge.dart';
import 'reg_icons.dart';
import 'reg_lang.dart';
import 'reg_lang_data.dart';
import 'reg_lang_state.dart';
import 'reg_widgets.dart';

class RegFlow extends StatefulWidget {
  const RegFlow({super.key, required this.onDone, this.onReveal, this.ready = true});

  /// دوای ئەوەی مۆشنی کۆتایی تەواو بوو و ئەپەکە دەرکەوت
  final VoidCallback onDone;

  /// کاتێک شاشەی کۆتایی دەست پێدەکات (ئەپەکەی ژێرەوە دەتوانێت جووڵەکانی چالاک بکاتەوە)
  final VoidCallback? onReveal;

  /// تا دیمەنی دەستپێک (Splash) لانەچێت، ناوەڕۆک نیشان نادرێت بۆ ئەوەی جووڵەکان لە دەست نەچن
  final bool ready;

  @override
  State<RegFlow> createState() => _RegFlowState();
}

class _RegFlowState extends State<RegFlow> {
  RegDraft d = RegDraft();
  String cur = 'welcome';
  bool verified = false;
  bool busy = false;
  String busyLabel = '';
  bool goingBack = false;
  int scr = 0;
  String pairPh = 'scan';

  /// زمانی هەڵبژێردراو لەسەر شاشەی زمان (تا دوگمەی «بەردەوامبە» نەکرێت پاشەکەوت ناکرێت)
  String pickL = LangState.I.code;

  Timer? _auto;
  Timer? _resendT;
  Timer? _draftT;
  final List<Timer> _stepT = [];
  int resendLeft = 0;

  final TextEditingController nameC = TextEditingController();
  final TextEditingController phoneC = TextEditingController();
  final TextEditingController otpC = TextEditingController();
  final TextEditingController codeC = TextEditingController();
  final FocusNode nameF = FocusNode();
  final FocusNode phoneF = FocusNode();
  final FocusNode otpF = FocusNode();
  final FocusNode codeF = FocusNode();
  final TextEditingController gmC = TextEditingController();
  final FocusNode gmF = FocusNode();
  bool gmAdding = false;
  String gmErr = '';

  String otpErr = '';
  bool otpBad = false;
  int otpTick = 0;
  String codeErr = '';

  String? doneTitle;
  String doneSub = '';

  @override
  void initState() {
    super.initState();
    _show();
  }

  @override
  void dispose() {
    _auto?.cancel();
    _resendT?.cancel();
    _draftT?.cancel();
    for (final t in _stepT) {
      t.cancel();
    }
    nameC.dispose();
    phoneC.dispose();
    otpC.dispose();
    codeC.dispose();
    nameF.dispose();
    phoneF.dispose();
    otpF.dispose();
    codeF.dispose();
    gmC.dispose();
    gmF.dispose();
    super.dispose();
  }

  // ---------- دەستپێکردن: ڕەشنووس یان هەژماری پێشوو ----------
  void _show() {
    final dr = Account.I.readDraft();
    final dd = dr?['D'];
    if (dr != null && dd is Map && dr['verified'] == true) {
      d = RegDraft.fromJson(dd);
      verified = true;
      var c = '${dr['cur'] ?? ''}';
      if (c == 'sub') c = 'plan';
      cur = _seq().contains(c) && !const {'welcome', 'lang', 'otp', 'method', 'gmail'}.contains(c) ? c : 'sex';
      if (cur == 'pair') pairPh = d.band.paired ? 'ok' : 'scan';
    } else {
      d = RegDraft();
      verified = false;
      pickL = LangState.I.code;
      // کەسی نوێ کە هێشتا زمانی هەڵنەبژاردووە: یەکەم شاشە هەڵبژاردنی زمانە
      cur = LangState.I.chosen ? 'welcome' : 'lang';
      final u = Account.I.user;
      if (u != null) {
        if ('${u['name'] ?? ''}'.isNotEmpty) d.name = '${u['name']}';
        if ('${u['phone'] ?? ''}'.isNotEmpty) d.phone = cleanPhone('${u['phone']}');
        if ('${u['email'] ?? ''}'.isNotEmpty) d.email = '${u['email']}'.toLowerCase();
        if (u['sex'] == 'm' || u['sex'] == 'f') d.sex = '${u['sex']}';
        final y = asI(u['year']);
        if (y >= kThisYear - 95 && y <= kThisYear - 13) d.year = y;
      }
    }
    _defaults(cur);
    if (widget.ready) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _enter(cur);
      });
    }
  }

  @override
  void didUpdateWidget(RegFlow old) {
    super.didUpdateWidget(old);
    if (widget.ready && !old.ready) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _enter(cur);
      });
    }
  }

  // ---------- هەنگاوەکان ----------
  List<String> _seq() {
    // دوای هەڵبژاردنی شێواز: Gmail = یەک هەنگاو؛ مۆبایل = ژمارە + کۆد
    final au = d.auth == 'gmail' ? ['gmail'] : ['phone', 'otp'];
    final a = d.mode == 'login'
        ? ['lang', 'welcome', 'method', ...au, 'name']
        : ['lang', 'welcome', 'name', 'method', ...au];
    a.addAll(['sex', 'year', 'height', 'weight', 'target', 'act', 'goals', 'band']);
    if (d.band.has == true) a.add('pair');
    a.addAll(['sleep', 'health', 'notif', 'sub', 'plan']);
    return a;
  }

  void _next() {
    final s = _seq();
    int i = s.indexOf(cur) + 1;
    if (i < s.length && s[i] == 'otp' && verified) i++;
    if (i > 0 && i < s.length) _go(s[i]);
  }

  void _back() {
    if (busy) return;
    final s = _seq();
    int i = s.indexOf(cur) - 1;
    if (i >= 0 && s[i] == 'otp' && verified) i--;
    if (i >= 0 && s[i] == 'sub') i--; // شاشەی پارەدان دووبارە نابێتەوە
    if (i >= 0) _go(s[i], back: true);
  }

  void _go(String step, {bool back = false}) {
    _clearStepTimers();
    _auto?.cancel();
    setState(() {
      cur = step;
      goingBack = back;
      busy = false;
      scr++;
      _defaults(step);
    });
    _saveDraft();
    _enter(step);
  }

  void _clearStepTimers() {
    for (final t in _stepT) {
      t.cancel();
    }
    _stepT.clear();
  }

  void _later(int ms, VoidCallback f) {
    _stepT.add(Timer(Duration(milliseconds: ms), () {
      if (mounted) f();
    }));
  }

  void _focusSoon(FocusNode f) => _later(380, () {
        if (f.canRequestFocus) f.requestFocus();
      });

  void _hideKeyboard() {
    final f = FocusManager.instance.primaryFocus;
    if (f != null) f.unfocus();
  }

  /// نرخە سەرەتاییەکان پێش دروستکردنی هەنگاوەکە (باڵا، کێش، ئامانج)
  void _defaults(String step) {
    if (step == 'height' || step == 'weight' || step == 'target') {
      if (d.h == 0) d.h = d.sex == 'f' ? 162 : 175;
      if (d.w == 0) d.w = d.sex == 'f' ? 62 : 75;
    }
    if (step == 'target' && (!d.twSet || d.tw <= 0)) d.tw = d.defTarget();
  }

  /// ئەو کارانەی کاتی هاتنە ناو هەر هەنگاوێک دەکرێن
  void _enter(String step) {
    switch (step) {
      case 'name':
        nameC.text = d.name;
        nameC.selection = TextSelection.collapsed(offset: nameC.text.length);
        _focusSoon(nameF);
        break;
      case 'method':
        _hideKeyboard();
        break;
      case 'gmail':
        gmC.clear();
        gmErr = '';
        gmAdding = Account.I.gmails().isEmpty;
        if (gmAdding) _focusSoon(gmF); else _hideKeyboard();
        break;
      case 'phone':
        phoneC.text = fmtPhone(d.phone);
        phoneC.selection = TextSelection.collapsed(offset: phoneC.text.length);
        _focusSoon(phoneF);
        break;
      case 'otp':
        otpC.clear();
        otpErr = '';
        otpBad = false;
        if (resendLeft <= 0) _startResend();
        _focusSoon(otpF);
        break;
      case 'height':
      case 'weight':
      case 'target':
        _hideKeyboard();
        break;
      case 'pair':
        _hideKeyboard();
        _enterPair();
        break;
      case 'sub':
        _hideKeyboard();
        _openSub();
        break;
      default:
        _hideKeyboard();
    }
  }

  void _saveDraft() {
    if (cur == 'welcome' || cur == 'lang') return;
    Account.I.saveDraft({'D': d.toJson(), 'cur': cur, 'verified': verified});
  }

  void _saveDraftSoon() {
    _draftT?.cancel();
    _draftT = Timer(const Duration(milliseconds: 250), _saveDraft);
  }

  /// پێشتر دوای هەڵبژاردن خۆکارانە دەچووە هەنگاوی دواتر؛ ئێستا تەنها بە دوگمەی «بەردەوامبە» دەڕوات
  void _autoNext() {
    _auto?.cancel();
  }

  /// هەنگاوی subscribe: هەمان لاپەڕەی VEX Plus ی ناو ئەپەکە دەکرێتەوە؛ X = بەردەوامبوون بە خۆڕایی
  Future<void> _openSub() async {
    if (PlusState.I.isPro) {
      _later(0, _next);
      return;
    }
    await Future<void>.delayed(const Duration(milliseconds: 260));
    if (!mounted || cur != 'sub') return;
    await PlusPage.open();
    if (!mounted || cur != 'sub') return;
    _next();
  }

  bool _ok(String s) {
    switch (s) {
      case 'name':
        return d.name.trim().length >= 2;
      case 'method':
        return d.auth.isNotEmpty;
      case 'gmail':
        return validGmail(d.email);
      case 'phone':
        return validPhone(d.phone);
      case 'otp':
        return otpC.text.length == 6;
      case 'sex':
        return d.sex.isNotEmpty;
      case 'year':
        return d.year >= kThisYear - 95 && d.year <= kThisYear - 13;
      case 'height':
        return d.h >= 120 && d.h <= 220;
      case 'weight':
        return d.w >= 30 && d.w <= 200;
      case 'target':
        return d.tw >= 30 && d.tw <= 200;
      case 'act':
        return d.act.isNotEmpty;
      case 'goals':
        return d.goals.isNotEmpty;
      case 'band':
        return d.band.has != null;
      case 'pair':
        return d.band.paired;
      case 'sleep':
        return d.sleepMin >= 180;
      case 'plan':
        return d.built;
      default:
        return true;
    }
  }

  String _cta() {
    switch (cur) {
      case 'lang':
        return langOf(pickL).t['cont'] ?? 'Continue';
      case 'welcome':
        return LangState.I.t('cta');
      case 'band':
        return LangState.I.t('cont');
      case 'phone':
        return verified ? 'بەردەوامبە' : 'ناردنی کۆد';
      case 'otp':
        return 'پشتڕاستکردنەوە';
      case 'notif':
        return 'ڕێگەپێدان و بەردەوامبوون';
      case 'plan':
        return 'دەستپێکردن';
      default:
        return 'بەردەوامبە';
    }
  }

  bool get _noGo => (cur == 'pair' && !d.band.paired) || (cur == 'plan' && !d.built) || cur == 'sub';
  bool get _canSkip => cur == 'health' || cur == 'notif';

  String _alt() {
    if (cur == 'welcome') return LangState.I.t('alt');
    if (cur == 'pair') {
      if (pairPh == 'scan' || pairPh == 'found') return 'کۆدی سەر قوتووەکە بنووسە';
      if (pairPh == 'code') return 'گەڕانەوە بۆ گەڕانی خۆکار';
    }
    return '';
  }

  void _onGo() {
    if (busy || !_ok(cur)) return;
    switch (cur) {
      case 'lang':
        LangState.I.set(pickL);
        _next();
        break;
      case 'welcome':
        d.mode = 'new';
        _next();
        break;
      case 'name':
        d.name = d.name.trim();
        _next();
        break;
      case 'method':
        _next();
        break;
      case 'gmail':
        _gmLogin(d.email);
        break;
      case 'phone':
        if (verified) {
          _next();
        } else {
          _sendCode();
        }
        break;
      case 'otp':
        _verify();
        break;
      case 'plan':
        _finish();
        break;
      default:
        _next();
    }
  }

  void _onAlt() {
    if (cur == 'welcome') {
      d.mode = 'login';
      d.auth = '';
      verified = false;
      _go('method');
    } else if (cur == 'pair') {
      _pairTo(pairPh == 'code' ? 'scan' : 'code');
    }
  }

  void _onSkip() {
    if (!_canSkip || busy) return;
    if (cur == 'health') {
      d.conds = [];
      d.condsDone = false;
    } else if (cur == 'notif') {
      for (final k in d.notif.keys.toList()) {
        d.notif[k] = false;
      }
    }
    _saveDraft();
    _next();
  }

  void _onSystemBack() {
    if (doneTitle != null) return;
    if (cur == 'lang') {
      SystemNavigator.pop();
    } else if (cur == 'welcome') {
      pickL = LangState.I.code;
      _go('lang', back: true);
    } else {
      _back();
    }
  }

  // ---------- کۆد ----------
  void _hold(String label) => setState(() {
        busy = true;
        busyLabel = label;
      });

  void _sendCode() {
    _hold('ناردن…');
    _later(900, () {
      _go('otp');
      _startResend();
    });
  }

  void _startResend() {
    _resendT?.cancel();
    setState(() => resendLeft = 30);
    _resendT = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() => resendLeft = math.max(0, resendLeft - 1));
      if (resendLeft <= 0) t.cancel();
    });
  }

  void _onOtpChanged(String v) {
    setState(() {
      otpErr = '';
      otpBad = false;
    });
    if (v.length == 6) _verify();
  }

  void _verify() {
    final c = otpC.text;
    if (c.length < 6 || busy) return;
    _hold('پشکنین…');
    _later(700, () async {
      if (c != '123456') {
        setState(() {
          busy = false;
          otpErr = 'کۆدەکە هەڵەیە. دووبارە هەوڵ بدەرەوە.';
          otpBad = true;
          otpTick++;
        });
        otpC.clear();
        HapticFeedback.heavyImpact();
        otpF.requestFocus();
        return;
      }
      verified = true;
      buzz(1);
      _hideKeyboard();
      final acc = Account.I.accountFor(d.phone);
      if (acc != null) {
        // ئەم ژمارەیە پێشتر لەم مۆبایلەدا هەژماری هەبووە: هەموو داتاکانی دەگەڕێتەوە
        _hold('هەژمارەکەت دەکرێتەوە…');
        await Account.I.restore(acc);
        await Future<void>.delayed(const Duration(milliseconds: 450));
        if (!mounted) return;
        final u = Account.I.user;
        if (u != null && '${u['name'] ?? ''}'.trim().isNotEmpty) {
          _welcomeBack(u);
        } else {
          setState(() => busy = false);
          _next();
        }
        return;
      }
      final u = Account.I.user;
      if (u != null && '${u['phone'] ?? ''}' == d.phone && '${u['name'] ?? ''}'.trim().isNotEmpty && asD(u['h']) > 0) {
        _hold('هەژمارەکەت دەکرێتەوە…');
        await Future<void>.delayed(const Duration(milliseconds: 450));
        if (!mounted) return;
        _welcomeBack(u);
        return;
      }
      setState(() => busy = false);
      _next();
    });
  }

  /// چوونە ژوورەوە بە Gmail: ئەگەر هەژمارەکە لەم مۆبایلەدا هەبوو هەموو داتاکانی (Plus، Band…) دەگەڕێتەوە
  Future<void> _gmLogin(String email) async {
    if (busy) return;
    final e = Account.idOf(email);
    if (!validGmail(e)) return;
    d.email = e;
    d.auth = 'gmail';
    verified = true;
    _hideKeyboard();
    _hold('پشکنین…');
    await Account.I.rememberGmail(e);
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    final acc = Account.I.accountFor(e);
    if (acc != null) {
      _hold('هەژمارەکەت دەکرێتەوە…');
      await Account.I.restore(acc);
      await Future<void>.delayed(const Duration(milliseconds: 450));
      if (!mounted) return;
      final u = Account.I.user;
      if (u != null && '${u['name'] ?? ''}'.trim().isNotEmpty) {
        _welcomeBack(u);
        return;
      }
      setState(() => busy = false);
      _next();
      return;
    }
    final u = Account.I.user;
    if (u != null && Account.idOf('${u['email'] ?? ''}') == e && '${u['name'] ?? ''}'.trim().isNotEmpty && asD(u['h']) > 0) {
      _hold('هەژمارەکەت دەکرێتەوە…');
      await Future<void>.delayed(const Duration(milliseconds: 450));
      if (!mounted) return;
      _welcomeBack(u);
      return;
    }
    setState(() => busy = false);
    _next();
  }

  /// Gmail ێکی نوێ لە خانەکەوە زیاد دەکات
  Future<void> _gmAddFromField() async {
    final e = Account.idOf(gmC.text);
    if (!validGmail(e)) {
      setState(() => gmErr = 'Gmail ێکی دروست بنووسە، وەک name@gmail.com');
      HapticFeedback.heavyImpact();
      return;
    }
    await Account.I.rememberGmail(e);
    if (!mounted) return;
    _hideKeyboard();
    setState(() {
      d.email = e;
      d.auth = 'gmail';
      gmAdding = false;
      gmErr = '';
      gmC.clear();
    });
    buzz(1);
    _saveDraft();
  }

  // ---------- پەیوەستکردنی Band ----------
  void _pairTo(String ph) {
    _clearStepTimers();
    setState(() => pairPh = ph);
    _enterPair();
  }

  void _enterPair() {
    switch (pairPh) {
      case 'scan':
        if (d.band.code.isEmpty) {
          final r = math.Random();
          const hex = '0123456789ABCDEF';
          d.band.code = 'VX8-${List<String>.generate(4, (_) => hex[r.nextInt(16)]).join()}';
        }
        _later(2600, () => _pairTo('found'));
        break;
      case 'link':
        _later(1800, () {
          d.band.paired = true;
          buzz(2);
          _pairTo('ok');
          _saveDraft();
        });
        break;
      case 'code':
        codeC.clear();
        codeErr = '';
        _focusSoon(codeF);
        break;
      default:
        break;
    }
  }

  void _submitCode() {
    final c = codeC.text.trim().toUpperCase();
    if (!RegExp(r'^VX[0-9A-Z-]{3,}$').hasMatch(c)) {
      setState(() => codeErr = 'کۆدەکە دەبێت بە VX دەست پێبکات، بۆ نموونە VX8-1234');
      HapticFeedback.heavyImpact();
      return;
    }
    d.band.code = c;
    _hideKeyboard();
    _pairTo('link');
  }

  // ---------- کۆتایی ----------
  Future<void> _finish() async {
    if (busy) return;
    _hold('ئامادەکردن…');
    final p = d.plan();
    final u = <String, dynamic>{
      'name': d.name.trim().length > 30 ? d.name.trim().substring(0, 30) : d.name.trim(),
      'phone': d.auth == 'gmail' ? '' : d.phone,
      'email': d.auth == 'gmail' ? d.email : '',
      'auth': d.auth == 'gmail' ? 'gmail' : 'phone',
      'sex': d.sex,
      'year': d.year,
      'age': d.age,
      'h': d.h,
      'w': d.w,
      'units': {'h': d.uh, 'w': d.uw},
      'act': d.act,
      'tw': d.tw > 0 ? d.tw : d.w,
      'wgoal': d.tw > 0 ? d.wGoal : 'keep',
      'goals': List<String>.from(d.goals),
      'band': {
        'has': d.band.has == true,
        'paired': d.band.paired,
        'code': d.band.code,
        'wrist': d.band.wrist,
      },
      'sleep': {'bed': d.bed, 'wake': d.wake},
      'conds': List<String>.from(d.conds),
      'notif': Map<String, bool>.from(d.notif),
      'plan': {
        'steps': p.steps,
        'act': p.act,
        'water': p.water,
        'sleep': p.sleep,
        'hrMax': p.hrMax,
        'bmi': p.bmi,
      },
      'at': DateTime.now().millisecondsSinceEpoch,
    };
    await Account.I.saveUser(u);
    Account.I.clearDraft();
    // Band ی پەیوەستکراو = 6 مانگ VEX Plus بە خۆڕایی (یەک جار)
    if (d.band.has == true && d.band.paired) {
      await PlusState.I.grantBandGift();
    }
    // Band و ئاگادارکردنەوەکان بۆ بەشەکانی تری ئەپ
    if (d.band.has == true && d.band.paired) {
      final dev = Account.I.readMap('vexdevice');
      dev.addAll({
        'state': 'on',
        'name': 'VEX Band',
        'wrist': d.band.wrist == 'right' ? 'دەستی ڕاست' : 'دەستی چەپ',
        'last': DateTime.now().millisecondsSinceEpoch,
      });
      Account.I.writeMap('vexdevice', dev);
    }
    final prof = Account.I.readMap('vexprofile');
    prof['notif'] = d.notif.values.any((v) => v);
    prof['fam'] = d.notif['fam'] == true;
    Account.I.writeMap('vexprofile', prof);
    await Account.I.stash();
    await Account.I.reloadStores();
    _resendT?.cancel();
    if (!mounted) return;
    _done('بەخێربێیت ${firstWord(d.name)}', 'هەموو شتێک ئامادەیە');
  }

  void _welcomeBack(Map<String, dynamic> u) {
    Account.I.clearDraft();
    _resendT?.cancel();
    _done('بەخێربێیتەوە ${firstWord('${u['name'] ?? ''}')}', 'هەژمارەکەت کرایەوە');
  }

  void _done(String title, String sub) {
    _clearStepTimers();
    _auto?.cancel();
    _hideKeyboard();
    setState(() {
      busy = false;
      doneTitle = title;
      doneSub = sub;
    });
    widget.onReveal?.call();
  }

  // =====================================================================
  //  UI
  // =====================================================================
  @override
  Widget build(BuildContext context) {
    final dt = doneTitle;
    if (dt != null) {
      return RDone(title: dt, sub: doneSub, onFinished: widget.onDone);
    }
    if (!widget.ready) {
      return Material(color: RC.bg, child: IgnorePointer(child: SizedBox.expand(child: _RegBg())));
    }
    final mq = MediaQuery.of(context);
    return PopScope(
      canPop: false,
      // ignore: deprecated_member_use
      onPopInvoked: (didPop) {
        if (!didPop) _onSystemBack();
      },
      child: Material(
        color: RC.bg,
        child: Stack(
          children: [
            const Positioned.fill(child: IgnorePointer(child: _RegBg())),
            LayoutBuilder(
              builder: (context, cons) {
                final h = cons.maxHeight;
                final kb = h - mq.padding.top < 470;
                final tight = h < 660;
                final compact = h < 720;
                return Padding(
                  padding: EdgeInsets.only(top: mq.padding.top),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 440),
                      child: Column(
                        children: [
                          if (cur != 'welcome' && cur != 'lang') _header(kb),
                          Expanded(child: _main(compact: compact, tight: tight, kb: kb)),
                          _footer(mq, kb: kb, compact: compact),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // ---------- سەرەوە: گەڕانەوە، ڕێڕەو، تێپەڕاندن ----------
  Widget _header(bool kb) {
    final s = _seq();
    final i = s.indexOf(cur);
    final pct = i <= 0 ? 0.0 : i / (s.length - 1);
    return Padding(
      padding: EdgeInsets.fromLTRB(18, kb ? 6 : 14, 18, kb ? 2 : 6),
      child: Row(
        children: [
          Semantics(
            button: true,
            label: 'گەڕانەوە',
            child: Press(
              onTap: busy ? null : _back,
              child: Container(
                width: kb ? 34 : 40,
                height: kb ? 34 : 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(kb ? 12 : 14),
                  border: Border.all(color: RC.line(0.18)),
                  color: RC.white(0.05),
                ),
                child: CustomPaint(size: const Size(20, 20), painter: _Chevron()),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              height: 6,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(9), color: RC.white(0.08)),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(end: pct),
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeOutCubic,
                  builder: (context, v, _) => FractionallySizedBox(
                    widthFactor: v.clamp(0.0, 1.0),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(9),
                        gradient: LinearGradient(
                          begin: AlignmentDirectional.centerStart,
                          end: AlignmentDirectional.centerEnd,
                          colors: [Color(0xFF8FF3F9), Color(0xFF3CF08A)],
                        ),
                        boxShadow: [BoxShadow(color: vk(0x8C3CF08A), blurRadius: 12)],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 64,
            child: Visibility(
              visible: _canSkip,
              maintainSize: true,
              maintainAnimation: true,
              maintainState: true,
              child: Press(
                onTap: _canSkip ? _onSkip : null,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
                  child: VText('تێپەڕاندن', textAlign: TextAlign.end, style: ku(13, w: FontWeight.w700, c: RC.mu)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------- ناوەڕاست (هەنگاوی ئێستا بە جووڵەوە) ----------
  Widget _main({required bool compact, required bool tight, required bool kb}) {
    final key = ValueKey<int>(scr);
    final dir = goingBack ? 26.0 : -26.0;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 450),
      layoutBuilder: (current, previous) => Stack(
        fit: StackFit.expand,
        children: [...previous, if (current != null) current],
      ),
      transitionBuilder: (child, anim) {
        final incoming = child.key == key;
        return AnimatedBuilder(
          animation: anim,
          builder: (context, ch) {
            final v = anim.value;
            if (!incoming) return Opacity(opacity: v, child: ch);
            final e = Curves.easeOutCubic.transform(v);
            return Opacity(
              opacity: e,
              child: Transform.translate(offset: Offset(dir * (1 - e), 0), child: ch),
            );
          },
          child: child,
        );
      },
      child: KeyedSubtree(
        key: key,
        child: cur == 'welcome' ? _welcome(compact: compact, tight: tight) : _stepScroll(compact, tight, kb),
      ),
    );
  }

  Widget _stepScroll(bool compact, bool tight, bool kb) {
    return SingleChildScrollView(
      padding: EdgeInsets.only(top: kb ? 0 : (compact ? 2 : 8), bottom: kb ? 6 : 18),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.manual,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: _step(compact: compact, tight: tight, kb: kb),
      ),
    );
  }

  static const EdgeInsets _px = EdgeInsets.symmetric(horizontal: 22);
  Widget _p(Widget w) => Padding(padding: _px, child: w);

  /// سەری هەنگاو: ئایکۆن + ناونیشان + ڕوونکردنەوە
  List<Widget> _head(String icon, String title, List<InlineSpan> sub, {required bool compact, required bool tight, required bool kb}) {
    return [
      if (icon.isNotEmpty && !tight && !kb) _p(Align(alignment: AlignmentDirectional.centerStart, child: RIcon(icon, compact: compact))),
      _p(RTitle(title, compact: compact || kb)),
      if (!kb) _p(RPara(sub, compact: compact)),
      if (kb) const SizedBox(height: 6),
    ];
  }

  // ---------- بەخێرهاتن ----------
  Widget _welcome({required bool compact, required bool tight}) {
    return LayoutBuilder(
      builder: (context, cons) {
        final h = cons.maxHeight;
        final logo = (h * 0.17).clamp(96.0, 136.0);
        final L = LangState.I.cur;
        return Stack(
          children: [
        SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: h),
            child: Padding(
              padding: const EdgeInsets.only(top: 10, bottom: 6),
              child: Directionality(
                textDirection: dirOfLang(L),
                child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Rise(child: RLogo(width: logo)),
                  const SizedBox(height: 4),
                  Rise(
                    delayMs: 80,
                    child: Column(
                      children: [
                        VText(LangState.I.t('wt'),
                            textAlign: TextAlign.center,
                            style: langStyle(L, tight ? 21 : (compact ? 23 : 26), w: FontWeight.w800, h: 1.4)),
                        ShaderMask(
                          shaderCallback: (r) =>
                              LinearGradient(colors: [vk(0xFF8FF3F9), vk(0xFF3CF08A)]).createShader(r),
                          blendMode: BlendMode.srcIn,
                          child: VText('VEX Health',
                              textDirection: TextDirection.ltr,
                              style: nu(tight ? 27 : (compact ? 30 : 34), c: kW, h: 1.25)),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: tight ? 8 : 6),
                  if (!tight)
                    Rise(
                      delayMs: 140,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 34),
                        child: VText(
                          LangState.I.t('wp'),
                          textAlign: TextAlign.center,
                          style: langStyle(L, 13.5, c: RC.p, h: 1.75),
                        ),
                      ),
                    ),
                  SizedBox(height: compact ? 10 : 16),
                  Rise(delayMs: 180, child: _p(_stats())),
                  SizedBox(height: compact ? 10 : 16),
                  RMarquee(compact: tight),
                ],
              ),
              ),
            ),
          ),
        ),
            PositionedDirectional(
              top: 6,
              start: 18,
              child: Rise(
                delayMs: 200,
                child: RLangChip(onTap: () {
                  pickL = LangState.I.code;
                  _go('lang', back: true);
                }),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _stats() {
    Widget dot() => Container(
          width: 4,
          height: 4,
          margin: const EdgeInsets.symmetric(horizontal: 9),
          decoration: BoxDecoration(shape: BoxShape.circle, color: vk(0xFF3D6870)),
        );
    final st = langStyle(LangState.I.cur, 12.5, w: FontWeight.w700, c: RC.p);
    return SizedBox(
      height: 28,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: kFeatCount.toDouble()),
              duration: const Duration(milliseconds: 1300),
              curve: Curves.easeOutCubic,
              builder: (context, v, _) => SizedBox(
                width: 28,
                child: ShaderMask(
                  shaderCallback: (r) =>
                      LinearGradient(colors: [vk(0xFF8FF3F9), vk(0xFF3CF08A)]).createShader(r),
                  blendMode: BlendMode.srcIn,
                  child: VText('${v.round()}', textAlign: TextAlign.center, style: nu(19, c: kW, h: 1.2)),
                ),
              ),
            ),
            const SizedBox(width: 4),
            VText(LangState.I.t('s1'), style: st),
            dot(),
            VText.rich(TextSpan(children: [
              TextSpan(text: 'AI', style: nu(12.5, c: V.tx)),
              TextSpan(text: ' ${LangState.I.t('s2')}'),
            ]), style: st),
            dot(),
            VText.rich(TextSpan(children: [
              TextSpan(text: ltr('24/7'), style: nu(12.5, c: V.tx)),
              TextSpan(text: ' ${LangState.I.t('s3')}'),
            ]), style: st),
          ],
        ),
      ),
    );
  }

  // ---------- هەنگاوەکان ----------
  List<Widget> _step({required bool compact, required bool tight, required bool kb}) {
    switch (cur) {
      case 'lang':
        return [RLangStep(picked: pickL, compact: compact, onPick: _pickLang)];
      case 'sub':
        return const [SizedBox(height: 320)];
      case 'name':
        return _name(compact, tight, kb);
      case 'method':
        return _method(compact, tight, kb);
      case 'gmail':
        return _gmail(compact, tight, kb);
      case 'phone':
        return _phone(compact, tight, kb);
      case 'otp':
        return _otp(compact, tight, kb);
      case 'sex':
        return _sex(compact, tight, kb);
      case 'year':
        return _year(compact, tight, kb);
      case 'height':
        return _height(compact, tight, kb);
      case 'weight':
        return _weight(compact, tight, kb);
      case 'target':
        return _target(compact, tight, kb);
      case 'act':
        return _act(compact, tight, kb);
      case 'goals':
        return _goals(compact, tight, kb);
      case 'band':
        return _band(compact, tight, kb);
      case 'pair':
        return _pair(compact, tight, kb);
      case 'sleep':
        return _sleep(compact, tight, kb);
      case 'health':
        return _health(compact, tight, kb);
      case 'notif':
        return _notif(compact, tight, kb);
      case 'plan':
        return _plan(compact, tight, kb);
      default:
        return const [];
    }
  }

  void _pickLang(String c) {
    if (c == pickL) return;
    setState(() => pickL = c);
    buzz(0);
  }

  List<Widget> _name(bool compact, bool tight, bool kb) => [
        ..._head('👋', d.mode == 'login' ? 'بەخێربێیتەوە! ناوت چییە؟' : 'ناوت چییە؟',
            [const TextSpan(text: 'بەم ناوە لە ئەپەکەدا بانگت دەکەین.')],
            compact: compact, tight: tight, kb: kb),
        _p(TextField(
          controller: nameC,
          focusNode: nameF,
          maxLength: 30,
          textInputAction: TextInputAction.next,
          textCapitalization: TextCapitalization.words,
          autofillHints: const [AutofillHints.givenName],
          style: ku(kb ? 17 : 18, w: FontWeight.w700, c: kW),
          cursorColor: V.cy,
          decoration: rInputDeco('بۆ نموونە: ئاری', compact: kb),
          onChanged: (v) => setState(() => d.name = v),
          onSubmitted: (_) => _onGo(),
        )),
      ];

  // ---------- شێوازی چوونەژوورەوە ----------
  List<Widget> _method(bool compact, bool tight, bool kb) => [
        ..._head('🔒', d.mode == 'login' ? 'چۆن دەچیتە ژوورەوە؟' : 'چۆن داخیل دەبیت؟',
            [const TextSpan(text: 'یەکێک لەمانە هەڵبژێرە. هەر کاتێک بگەڕێیتەوە، داتاکانت وەک خۆیان دەمێننەوە.')],
            compact: compact, tight: tight, kb: kb),
        _p(ROptTile(
          emoji: '📱',
          title: 'ژمارەی مۆبایل',
          sub: 'کۆدێکی 6 ژمارەیی بە SMS دێت',
          on: d.auth == 'phone',
          compact: tight,
          onTap: () {
            setState(() {
              d.auth = 'phone';
              verified = false;
            });
            buzz(0);
            _saveDraft();
          },
        )),
        _p(Padding(
          padding: EdgeInsets.only(top: tight ? 8 : 10),
          child: ROptTile(
            emoji: '✉',
            title: 'Gmail',
            sub: 'بە هەژماری Google ـەکەت',
            on: d.auth == 'gmail',
            compact: tight,
            onTap: () {
              setState(() {
                d.auth = 'gmail';
                verified = false;
              });
              buzz(0);
              _saveDraft();
            },
          ),
        )),
        if (!kb)
          _p(const RLock('هەر هەژمارێک داتاکانی خۆی هەیە (Plus، Band، خواردن، خێزان…) و بە ژمارە یان Gmail ـەکەت دەگەڕێتەوە، تەنانەت دوای چوونە دەرەوە.')),
      ];

  // ---------- Gmail ----------
  List<Widget> _gmail(bool compact, bool tight, bool kb) {
    final list = Account.I.gmails();
    return [
      ..._head('✉', 'Gmail ـەکەت هەڵبژێرە',
          [const TextSpan(text: 'هەر Gmail ـێک داتای خۆی هەیە و لەگەڵ Band ـەکەتدا دەمێنێتەوە.')],
          compact: compact, tight: tight, kb: kb),
      for (final g in list)
        _p(Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _GmTile(
            name: '${g['name']}',
            email: '${g['email']}',
            has: g['has'] == true,
            on: d.email == g['email'],
            onTap: () {
              setState(() {
                d.email = '${g['email']}';
                d.auth = 'gmail';
              });
              buzz(0);
              _saveDraft();
            },
          ),
        )),
      _p(_GmAddTile(open: gmAdding, onTap: () {
        setState(() {
          gmAdding = !gmAdding;
          gmErr = '';
        });
        if (gmAdding) _focusSoon(gmF);
      })),
      if (gmAdding)
        _p(Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Directionality(
                textDirection: TextDirection.ltr,
                child: TextField(
                  controller: gmC,
                  focusNode: gmF,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.done,
                  autocorrect: false,
                  enableSuggestions: false,
                  textAlign: TextAlign.left,
                  autofillHints: const [AutofillHints.email],
                  style: nu(kb ? 16 : 17, w: FontWeight.w700, c: kW),
                  cursorColor: V.cy,
                  decoration: rInputDeco('name@gmail.com', compact: kb, ltrHint: true),
                  onChanged: (_) {
                    if (gmErr.isNotEmpty) setState(() => gmErr = '');
                  },
                  onSubmitted: (_) => _gmAddFromField(),
                ),
              ),
              if (gmErr.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 6, right: 4, left: 4),
                  child: VText(gmErr, style: ku(12.5, w: FontWeight.w700, c: RC.err)),
                ),
              RLink('زیادکردنی ئەم Gmail ـە', top: 6, onTap: _gmAddFromField),
            ],
          ),
        )),
      if (!kb)
        _p(RHint([
          const TextSpan(text: 'وەشانی دیمۆ: Gmail ـەکە تەنها لەسەر ئەم مۆبایلە دەناسرێتەوە.'),
        ], top: 10)),
      _p(RLink('ژمارەی مۆبایل بەکاربهێنە', top: kb ? 2 : 6, onTap: busy
          ? null
          : () {
              d.auth = 'phone';
              verified = false;
              _go('phone');
            })),
    ];
  }

  List<Widget> _phone(bool compact, bool tight, bool kb) {
    final ok = validPhone(d.phone);
    final help = ok
        ? '✓ ژمارەکە دروستە'
        : (d.phone.isNotEmpty && d.phone[0] != '7')
            ? 'ژمارەی مۆبایلی عێراق بە 7 دەست پێدەکات'
            : '10 ژمارە، بۆ نموونە 750 123 4567';
    return [
      ..._head(
          '📱',
          d.mode == 'login' ? 'چوونە ژوورەوە' : 'ژمارەی مۆبایلەکەت',
          [const TextSpan(text: 'کۆدێکی 6 ژمارەیی دەنێرین بۆ پشتڕاستکردنەوە و پاراستنی هەژمارەکەت.')],
          compact: compact,
          tight: tight,
          kb: kb),
      _p(Directionality(
        textDirection: TextDirection.ltr,
        child: IntrinsicHeight(
          child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                color: RC.white(0.06),
                border: Border.all(color: RC.line(0.2), width: 1.5),
              ),
              child: VText('🇮🇶 +964', style: nu(16)),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: phoneC,
                focusNode: phoneF,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.send,
                textAlign: TextAlign.left,
                textDirection: TextDirection.ltr,
                autofillHints: const [AutofillHints.telephoneNumberNational],
                inputFormatters: [PhoneFormatter()],
                style: nu(kb ? 17 : 18, w: FontWeight.w700, c: kW, ls: 1),
                cursorColor: V.cy,
                decoration: rInputDeco('750 123 4567', compact: kb, ltrHint: true),
                onChanged: (v) {
                  final p = cleanPhone(v);
                  setState(() {
                    if (p != d.phone) verified = false;
                    d.phone = p;
                  });
                },
                onSubmitted: (_) => _onGo(),
              ),
            ),
          ],
        ),
        ),
      )),
      _p(Padding(
        padding: EdgeInsets.only(top: kb ? 6 : 10, right: 4, left: 4),
        child: VText(help, style: ku(12.5, w: FontWeight.w600, c: ok ? V.mint : RC.mu)),
      )),
      if (!kb)
        _p(const RLock('ژمارەکەت بۆ هیچ کەسێک دەرناکەوێت و تەنها بۆ چوونە ژوورەوە و پاراستنی هەژمارەکەت بەکاردێت.')),
      _p(RLink('هەژماری Gmail بەکاربهێنە', top: kb ? 4 : 10, onTap: busy
          ? null
          : () {
              d.auth = 'gmail';
              verified = false;
              _go('gmail');
            })),
    ];
  }

  List<Widget> _otp(bool compact, bool tight, bool kb) {
    final ph = d.phone.length >= 10 ? '+964 ${d.phone.substring(0, 3)} ••• ${d.phone.substring(6)}' : '+964 ${d.phone}';
    return [
      ..._head('💬', 'کۆدەکە بنووسە', [
        const TextSpan(text: 'کۆدێکی 6 ژمارەییمان نارد بۆ '),
        numSpan(ph, size: 14, c: V.tx),
      ], compact: compact, tight: tight, kb: kb),
      _p(ROtp(
        controller: otpC,
        focus: otpF,
        onChanged: _onOtpChanged,
        errorTick: otpTick,
        bad: otpBad,
        compact: kb,
      )),
      _p(Container(
        constraints: BoxConstraints(minHeight: kb ? 0 : 20),
        margin: EdgeInsets.only(top: kb ? 6 : 10),
        child: VText(otpErr, textAlign: TextAlign.center, style: ku(13, w: FontWeight.w700, c: RC.err)),
      )),
      _p(RHint([
        const TextSpan(text: 'کۆدی تاقیکردنەوە: '),
        numSpan('123456', size: 12.5, c: RC.soft),
      ], top: kb ? 6 : 14)),
      _p(Opacity(
        opacity: resendLeft > 0 ? 0.55 : 1,
        child: RLink(
          resendLeft > 0 ? 'دووبارە ناردن لە ${ltr('0:${resendLeft.toString().padLeft(2, '0')}')}' : 'کۆدەکەم پێنەگەیشت · دووبارە بنێرە',
          top: kb ? 4 : 12,
          onTap: resendLeft > 0 || busy
              ? null
              : () {
                  toast('کۆدەکە دووبارە نێردرا (دیمۆ)');
                  _startResend();
                },
        ),
      )),
      _p(RLink('ژمارەکە بگۆڕە', top: 0, color: RC.mu, onTap: busy ? null : _back)),
    ];
  }

  List<Widget> _sex(bool compact, bool tight, bool kb) {
    final f = firstWord(d.name);
    void pick(String v) {
      setState(() {
        d.sex = v;
        if (!d.hSet) d.h = v == 'f' ? 162 : 175;
        if (!d.wSet) d.w = v == 'f' ? 62 : 75;
        if (v == 'm') d.conds.removeWhere((c) => c == 'preg' || c == 'bf');
      });
      buzz(0);
      _saveDraft();
      _autoNext();
    }

    return [
      ..._head('🧬', f.isEmpty ? 'ڕەگەزت چییە؟' : 'خۆشحاڵین بە ناسینت، $f!\nڕەگەزت چییە؟',
          [const TextSpan(text: 'بۆ حیسابی دروستی لێدانی دڵ، کالۆری و خەو پێویستە.')],
          compact: compact, tight: tight, kb: kb),
      _p(Row(
        children: [
          Expanded(child: RBigOpt(emoji: '👨', art: RAvatar(female: false, size: tight ? 84 : 104), title: 'نێر', on: d.sex == 'm', onTap: () => pick('m'), compact: tight)),
          const SizedBox(width: 10),
          Expanded(child: RBigOpt(emoji: '👩', art: RAvatar(female: true, size: tight ? 84 : 104), title: 'مێ', on: d.sex == 'f', onTap: () => pick('f'), compact: tight)),
        ],
      )),
    ];
  }

  List<Widget> _year(bool compact, bool tight, bool kb) => [
        ..._head('🎂', 'ساڵی لەدایکبوونت چەندە؟',
            [const TextSpan(text: 'تەمەن کاریگەری لەسەر ئاستی ئاسایی دڵ، خەو و ئامانجەکانت هەیە.')],
            compact: compact, tight: tight, kb: kb),
        RYearWheel(
          value: d.year,
          compact: compact,
          onChanged: (y) {
            setState(() => d.year = y);
            _saveDraftSoon();
          },
        ),
        Padding(
          padding: const EdgeInsets.only(top: 14),
          child: VText.rich(
            TextSpan(children: [
              const TextSpan(text: 'تەمەنت: '),
              numSpan('${d.age}', size: 18, c: V.mint),
              const TextSpan(text: ' ساڵ'),
            ]),
            textAlign: TextAlign.center,
            style: ku(14, w: FontWeight.w700, c: RC.p),
          ),
        ),
      ];

  // ---------- بەرزی ----------
  String get _hVal {
    if (d.uh == 'ft') {
      int i = (d.h / 2.54).round();
      final f = i ~/ 12;
      i -= f * 12;
      return '$f′ $i″';
    }
    return '${d.h}';
  }

  void _setH(num v) {
    final x = v.round().clamp(120, 220);
    if (x == d.h) return;
    setState(() {
      d.h = x;
      d.hSet = true;
    });
    _saveDraftSoon();
  }

  List<Widget> _height(bool compact, bool tight, bool kb) => [
        ..._head('📏', 'بەرزیت چەندە؟', [const TextSpan(text: 'هێڵەکە ڕابکێشە، یان − و + بەکاربهێنە.')],
            compact: compact, tight: tight, kb: kb),
        _p(RValue(
          value: _hVal,
          unit: d.uh == 'ft' ? 'فوت و ئینج' : 'سانتیمەتر',
          compact: compact,
          onMinus: () {
            buzz(0);
            _setH(d.h - 1);
          },
          onPlus: () {
            buzz(0);
            _setH(d.h + 1);
          },
        )),
        RUnitSeg(
          values: const ['cm', 'ft'],
          value: d.uh,
          onChanged: (u) {
            setState(() => d.uh = u);
            _saveDraft();
          },
        ),
        SizedBox(height: compact ? 12 : 22),
        RRuler(
          min: 120,
          max: 220,
          step: 1,
          value: d.h.toDouble(),
          height: tight ? 76 : (compact ? 84 : 92),
          onChanged: _setH,
        ),
      ];

  // ---------- کێش ----------
  String get _wVal => d.uw == 'lb' ? '${(d.w * 2.20462).round()}' : numTxt(d.w);

  void _setW(double v) {
    final x = ((v * 2).round() / 2).clamp(30.0, 200.0);
    if (x == d.w) return;
    setState(() {
      if (!d.twSet) d.tw = 0;
      d.w = x;
      d.wSet = true;
    });
    _saveDraftSoon();
  }

  List<Widget> _weight(bool compact, bool tight, bool kb) => [
        ..._head('⚖️', 'کێشت چەندە؟',
            [const TextSpan(text: 'نزیکەی کێشی ئێستات بەسە. هەر کاتێک دەتوانیت نوێی بکەیتەوە.')],
            compact: compact, tight: tight, kb: kb),
        _p(RValue(
          value: _wVal,
          unit: d.uw == 'lb' ? 'پاوەند' : 'کیلۆگرام',
          compact: compact,
          onMinus: () {
            buzz(0);
            _setW(d.w - 0.5);
          },
          onPlus: () {
            buzz(0);
            _setW(d.w + 0.5);
          },
        )),
        RUnitSeg(
          values: const ['kg', 'lb'],
          value: d.uw,
          onChanged: (u) {
            setState(() => d.uw = u);
            _saveDraft();
          },
        ),
        SizedBox(height: compact ? 12 : 22),
        RRuler(
          min: 30,
          max: 200,
          step: 0.5,
          value: d.w,
          height: tight ? 76 : (compact ? 84 : 92),
          onChanged: _setW,
        ),
        if (d.h > 0) _p(RBmiCard(bmi: d.bmi, compact: tight)),
      ];

  // ---------- کێشی ئامانج ----------
  void _setTw(double v) {
    final x = ((v * 2).round() / 2).clamp(30.0, 200.0);
    if (x == d.tw && d.twSet) return;
    setState(() {
      d.tw = x;
      d.twSet = true;
    });
    _saveDraftSoon();
  }

  List<Widget> _target(bool compact, bool tight, bool kb) {
    if (d.h <= 0 || d.w <= 0 || d.tw <= 0) return const [];
    final g = d.wGoal;
    final diff = (d.tw - d.w).abs();
    final r = d.healthyRange;
    final tb = d.tw / math.pow(d.h / 100, 2);
    final wk = (diff / 0.5).ceil();
    final mo = (wk / 4.345 * 2).round() / 2;
    final k = g == 'keep' ? V.cy : (g == 'lose' ? V.mint : RC.lilac);
    final rng = d.uw == 'lb'
        ? '${(r[0] * 2.20462).round()}–${(r[1] * 2.20462).round()} lb'
        : '${r[0]}–${r[1]} kg';

    Widget chip(Color c, List<InlineSpan> sp) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(99),
            color: op(c, 0.11),
            border: Border.all(color: op(c, 0.36)),
          ),
          child: VText.rich(TextSpan(children: sp), style: ku(12.5, w: FontWeight.w800, c: c, h: 1.3)),
        );

    final InlineSpan info;
    if (tb < 18.5) {
      info = TextSpan(style: ku(12, c: V.amber, h: 1.7), children: [
        ricoSpan('⚠️', size: 14, color: V.amber),
        const TextSpan(text: 'ئەم ئامانجە لە خوار ئاستی تەندروستە. لە '),
        numSpan(d.kgTxt(r[0].toDouble()), size: 12, c: V.amber),
        const TextSpan(text: ' کەمتر مەبە.'),
      ]);
    } else if (tb >= 30 && g == 'gain') {
      info = TextSpan(style: ku(12, c: V.amber, h: 1.7), children: [
        ricoSpan('⚠️', size: 14, color: V.amber),
        const TextSpan(text: 'ئەم ئامانجە لە سەرووی ئاستی تەندروستە.'),
      ]);
    } else {
      info = TextSpan(children: [
        ricoSpan('💚', size: 14),
        const TextSpan(text: 'کێشی تەندروست بۆ '),
        numSpan('${d.h}cm', size: 12, c: RC.mu, w: FontWeight.w600),
        const TextSpan(text: ': '),
        numSpan(rng, size: 12, c: V.tx),
      ]);
    }

    return [
      _p(RTitle('دەتەوێت کێشت ببێت بە چەند؟', compact: compact || kb)),
      if (!kb)
        _p(RPara([
          const TextSpan(text: 'ئێستا '),
          numSpan(d.kgTxt(d.w), size: compact ? 13 : 14),
          const TextSpan(text: ' ـیت. ئامانجێکی تەندروست هەڵبژێرە.'),
        ], compact: compact)),
      _p(RGauge(
        heightCm: d.h,
        weight: d.w,
        target: d.tw,
        unit: d.uw,
        compact: tight,
        onMinus: () {
          buzz(0);
          _setTw(d.tw - 0.5);
        },
        onPlus: () {
          buzz(0);
          _setTw(d.tw + 0.5);
        },
      )),
      SizedBox(height: compact ? 6 : 10),
      RRuler(
        min: 30,
        max: 200,
        step: 0.5,
        value: d.tw,
        height: tight ? 76 : (compact ? 84 : 92),
        onChanged: _setTw,
      ),
      _p(Padding(
        padding: const EdgeInsets.only(top: 10),
        child: Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 7,
          runSpacing: 7,
          children: [
            chip(k, g == 'keep'
                ? [ricoSpan('⚖️', size: 13, color: k), const TextSpan(text: 'پاراستنی کێش')]
                : [
                    TextSpan(text: g == 'lose' ? '↓ ' : '↑ '),
                    numSpan(d.kgTxt(double.parse(diff.toStringAsFixed(1))), size: 12.5, c: k),
                    TextSpan(text: g == 'lose' ? ' کەمکردنەوە' : ' زیادکردن'),
                  ]),
            if (g != 'keep')
              chip(RC.lilac, [
                ricoSpan('📅', size: 13, color: RC.lilac),
                numSpan('$wk', size: 12.5, c: RC.lilac),
                const TextSpan(text: ' هەفتە'),
                if (wk >= 8) ...[
                  const TextSpan(text: ' · '),
                  numSpan(numTxt(mo), size: 12.5, c: RC.lilac),
                  const TextSpan(text: ' مانگ'),
                ],
              ]),
            if (g != 'keep')
              Press(
                onTap: () {
                  buzz(0);
                  _setTw(d.w);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(99),
                    color: RC.white(0.04),
                    border: Border.all(color: RC.line(0.2)),
                  ),
                  child: VText.rich(
                    TextSpan(children: [ricoSpan('⚖️', size: 13, color: RC.soft), const TextSpan(text: 'هەمان کێش')]),
                    style: ku(12.5, w: FontWeight.w700, c: RC.soft, h: 1.3),
                  ),
                ),
              ),
          ],
        ),
      )),
      if (!tight)
        _p(Padding(
          padding: const EdgeInsets.only(top: 8),
          child: VText.rich(info, textAlign: TextAlign.center, style: ku(12, c: RC.mu, h: 1.7)),
        )),
    ];
  }

  // ---------- چالاکی ----------
  List<Widget> _act(bool compact, bool tight, bool kb) => [
        ..._head('🏃', 'لە ڕۆژێکی ئاساییدا چەند چالاکیت؟',
            [const TextSpan(text: 'بۆ دانانی ئامانجی هەنگاو و جووڵەی گونجاو بۆ تۆ.')],
            compact: compact, tight: tight, kb: kb),
        for (int i = 0; i < kActs.length; i++)
          _p(Padding(
            padding: EdgeInsets.only(top: i == 0 ? 0 : (tight ? 8 : 10)),
            child: ROptTile(
              emoji: kActs[i].e,
              title: kActs[i].t,
              sub: kActs[i].s,
              on: d.act == kActs[i].k,
              compact: tight,
              onTap: () {
                setState(() => d.act = kActs[i].k);
                buzz(0);
                _saveDraft();
                _autoNext();
              },
            ),
          )),
      ];

  // ---------- ئامانجەکان ----------
  List<Widget> _goals(bool compact, bool tight, bool kb) {
    final n = d.goals.length;
    return [
      ..._head('🎯', 'چیت دەوێت باشتر بکەیت؟',
          [const TextSpan(text: 'تا 3 دانە هەڵبژێرە. ئەپەکە بە پێی ئەمانە بۆت ڕێکدەخەین.')],
          compact: compact, tight: tight, kb: kb),
      _p(Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: VText.rich(
          n > 0
              ? TextSpan(children: [
                  numSpan('$n', size: 12.5, c: V.mint),
                  const TextSpan(text: ' لە '),
                  numSpan('3', size: 12.5, c: RC.mu, w: FontWeight.w700),
                  const TextSpan(text: ' هەڵبژێردراوە'),
                ])
              : const TextSpan(text: 'یەک یان زیاتر هەڵبژێرە'),
          style: ku(12.5, w: FontWeight.w700, c: RC.mu),
        ),
      )),
      _p(LayoutBuilder(
        builder: (context, cons) {
          final w = (cons.maxWidth - 10) / 2;
          return Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final g in kGoals)
                SizedBox(
                  width: w,
                  child: ROptTile(
                    emoji: g.e,
                    title: g.t,
                    on: d.goals.contains(g.k),
                    small: true,
                    check: false,
                    onTap: () {
                      if (d.goals.contains(g.k)) {
                        setState(() => d.goals.remove(g.k));
                      } else {
                        if (d.goals.length >= 3) {
                          toast('زۆرترین 3 ئامانج هەڵبژێرە');
                          HapticFeedback.heavyImpact();
                          return;
                        }
                        setState(() => d.goals.add(g.k));
                      }
                      buzz(0);
                      _saveDraft();
                    },
                  ),
                ),
            ],
          );
        },
      )),
    ];
  }

  // ---------- Band ----------
  List<Widget> _band(bool compact, bool tight, bool kb) {
    void pick(bool y) {
      setState(() {
        if (d.band.has != y) {
          d.band.paired = false;
          pairPh = 'scan';
        }
        d.band.has = y;
        if (y && !d.band.paired) pairPh = 'scan';
      });
      buzz(0);
      _saveDraft();
    }

    return [
      RBandQ(has: d.band.has, onPick: pick, compact: compact, tight: tight),
    ];
  }

  // ---------- پەیوەستکردنی Band ----------
  List<Widget> _pair(bool compact, bool tight, bool kb) {
    final later = RLink('دواتر پەیوەستی دەکەم', color: RC.mu, onTap: () {
      d.band.paired = false;
      _next();
    });
    Widget center(String title, String sub) => _p(Column(
          children: [
            RTitle(title, compact: compact, center: true),
            RPara([TextSpan(text: sub)], compact: compact, center: true),
          ],
        ));
    final radar = tight ? 160.0 : 200.0;
    switch (pairPh) {
      case 'scan':
        return [
          Center(child: Padding(padding: const EdgeInsets.only(top: 8, bottom: 18), child: RRadar(icon: '⌚', size: radar))),
          center('گەڕان بە دوای Band ـەکەت…', 'Band ـەکەت نزیک مۆبایلەکە بهێڵە و Bluetooth چالاک بێت.'),
          later,
        ];
      case 'found':
        return [
          const Center(child: Padding(padding: EdgeInsets.only(top: 8, bottom: 10), child: RRadar(icon: '⌚', rings: 0, size: 150))),
          center('Band ـەکەت دۆزرایەوە', 'دڵنیابە ئەمە Band ـەکەی خۆتە، پاشان پەیوەستی بکە.'),
          _p(Rise(
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: RC.white(0.05),
                border: Border.all(color: vk(0x592FE6F3), width: 1.5),
              ),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(15), color: vk(0x1F2FE6F3)),
                    child: const BandEmblem(size: 40),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        VText('VEX Band V8', style: nu(15, w: FontWeight.w800)),
                        VText.rich(
                          TextSpan(children: [
                            numSpan(d.band.code, size: 12, c: RC.mu, w: FontWeight.w600),
                            const TextSpan(text: ' · '),
                            ricoSpan('📶', size: 13, color: V.mint),
                            const TextSpan(text: 'زۆر نزیک'),
                          ]),
                          style: ku(12, c: RC.mu),
                        ),
                      ],
                    ),
                  ),
                  Press(
                    onTap: () {
                      buzz(0);
                      _pairTo('link');
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(13), gradient: V.prime),
                      child: VText('پەیوەستکردن', style: ku(13, w: FontWeight.w800, c: V.ink)),
                    ),
                  ),
                ],
              ),
            ),
          )),
          later,
        ];
      case 'link':
        return [
          Center(child: Padding(padding: const EdgeInsets.only(top: 8, bottom: 18), child: RRadar(icon: '🔗', rings: 1, size: radar))),
          center('پەیوەستکردن…', 'تکایە Band ـەکە لە مۆبایلەکە دوور مەخەرەوە.'),
        ];
      case 'code':
        return [
          if (!kb) _p(const Align(alignment: AlignmentDirectional.centerStart, child: RIcon('🔢'))),
          _p(RTitle('کۆدی Band بنووسە', compact: compact || kb)),
          if (!kb) _p(RPara(const [TextSpan(text: 'کۆدەکە لە پشتی قوتووەکە یان لە ژێر Band ـەکەدا نووسراوە.')], compact: compact)),
          _p(TextField(
            controller: codeC,
            focusNode: codeF,
            maxLength: 14,
            textAlign: TextAlign.center,
            textDirection: TextDirection.ltr,
            textCapitalization: TextCapitalization.characters,
            autocorrect: false,
            enableSuggestions: false,
            textInputAction: TextInputAction.done,
            style: nu(18, w: FontWeight.w700, c: kW, ls: 2),
            cursorColor: V.cy,
            decoration: rInputDeco('VX8-1234', compact: kb, ltrHint: true).copyWith(
              enabledBorder: codeErr.isEmpty
                  ? null
                  : OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide(color: V.coral, width: 1.5),
                    ),
            ),
            onChanged: (_) {
              if (codeErr.isNotEmpty) setState(() => codeErr = '');
            },
            onSubmitted: (_) => _submitCode(),
          )),
          _p(Container(
            constraints: const BoxConstraints(minHeight: 20),
            margin: const EdgeInsets.only(top: 10, bottom: 10),
            child: VText(codeErr, textAlign: TextAlign.center, style: ku(13, w: FontWeight.w700, c: RC.err)),
          )),
          _p(RGo(label: 'پەیوەستکردن', onTap: _submitCode, compact: kb)),
          _p(const RHint([TextSpan(text: 'دیمۆ: هەر کۆدێک کە بە VX دەست پێبکات کار دەکات')])),
        ];
      default: // ok
        return [
          const Center(child: _PairOk()),
          center('Band پەیوەست کرا', 'داتای دڵ، ئۆکسجین، خەو و سترێس لێرەوە دەست پێدەکات.'),
          _p(Padding(
            padding: const EdgeInsets.only(bottom: 8, right: 4, left: 4),
            child: VText('Band لە کام دەستتە؟', style: ku(12.5, w: FontWeight.w800, c: RC.p)),
          )),
          _p(Row(
            children: [
              Expanded(child: _segBtn('دەستی چەپ', '✋', d.band.wrist == 'left', () => _wrist('left'))),
              const SizedBox(width: 8),
              Expanded(child: _segBtn('دەستی ڕاست', '🤚', d.band.wrist == 'right', () => _wrist('right'))),
            ],
          )),
          _p(const RHint([TextSpan(text: 'پێشنیار: ئەو دەستەی کەمتر بەکاری دەهێنیت، بۆ پێوانی وردتر.')])),
        ];
    }
  }

  void _wrist(String w) {
    setState(() => d.band.wrist = w);
    buzz(0);
    _saveDraft();
  }

  Widget _segBtn(String label, String icon, bool on, VoidCallback onTap) => Press(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: on ? V.mint : RC.line(0.16), width: 1.5),
            color: on ? vk(0x1F3CF08A) : RC.white(0.04),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              RIco(icon, size: 18, tile: false, color: on ? V.mint : null),
              const SizedBox(width: 7),
              VText(label, style: ku(14, w: FontWeight.w800)),
            ],
          ),
        ),
      );

  // ---------- خەو ----------
  List<Widget> _sleep(bool compact, bool tight, bool kb) {
    final mn = d.sleepMin;
    final h = mn ~/ 60, r = mn % 60;
    final rec = d.sleepRec;
    final hh = mn / 60;
    final Color c;
    final String e, t;
    if (hh < rec[0]) {
      c = V.amber;
      e = '😴';
      t = 'کەمێک کەمترە لە پێشنیار (${rec[0]}–${rec[1]} کاتژمێر). هەوڵ بدە کەمێک زووتر بخەویت.';
    } else if (hh > rec[1]) {
      c = V.cy;
      e = '🛌';
      t = 'زیاترە لە پێشنیار (${rec[0]}–${rec[1]} کاتژمێر)، بەڵام بۆ هەندێک کەس ئاساییە.';
    } else {
      c = V.mint;
      e = '✨';
      t = 'نایابە! لە ناو ماوەی پێشنیارکراودایە (${rec[0]}–${rec[1]} کاتژمێر).';
    }

    Widget card(String key, String label, String icon) => Expanded(
          child: Container(
            padding: const EdgeInsets.fromLTRB(10, 16, 10, 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              color: RC.white(0.04),
              border: Border.all(color: RC.line(0.14)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    RIco(icon, size: 16, tile: false),
                    const SizedBox(width: 6),
                    VText(label, style: ku(12.5, w: FontWeight.w700, c: RC.mu)),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 6, bottom: 10),
                  child: VText(key == 'bed' ? d.bed : d.wake, style: nu(32, h: 1.1)),
                ),
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      RPM(plus: false, size: 42, onTap: () => _shiftTime(key, -15)),
                      const SizedBox(width: 8),
                      RPM(plus: true, size: 42, onTap: () => _shiftTime(key, 15)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );

    return [
      ..._head('🌙', 'کەی دەخەویت و کەی هەڵدەستیت؟',
          [const TextSpan(text: 'بۆ شیکاری خەو و یادخستنەوەی کاتی خەوتن. نزیکەی ڕۆژانی ئاسایی بەسە.')],
          compact: compact, tight: tight, kb: kb),
      _p(Row(children: [card('bed', 'کاتی خەوتن', '🌙'), const SizedBox(width: 10), card('wake', 'کاتی هەستان', '☀️')])),
      _p(AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.only(top: 14),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: op(c, 0.09),
          border: Border.all(color: op(c, 0.32)),
        ),
        child: Row(
          children: [
            RIco(e, size: 46, radius: 15),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  VText.rich(
                    TextSpan(children: [
                      const TextSpan(text: 'ماوەی خەو: '),
                      numSpan('$h', size: 20, c: c),
                      const TextSpan(text: ' کاتژمێر'),
                      if (r > 0) ...[
                        const TextSpan(text: ' و '),
                        numSpan('$r', size: 20, c: c),
                        const TextSpan(text: ' خولەک'),
                      ],
                    ]),
                    style: ku(16, w: FontWeight.w800, h: 1.5),
                  ),
                  VText(t, style: ku(12.5, c: RC.p, h: 1.6)),
                ],
              ),
            ),
          ],
        ),
      )),
    ];
  }

  void _shiftTime(String key, int delta) {
    buzz(0);
    setState(() {
      if (key == 'bed') {
        d.bed = toHM(toMin(d.bed) + delta);
      } else {
        d.wake = toHM(toMin(d.wake) + delta);
      }
    });
    _saveDraftSoon();
  }

  // ---------- دۆخی تەندروستی ----------
  List<Widget> _health(bool compact, bool tight, bool kb) {
    final list = kConds.where((c) => !c.femaleOnly || d.sex == 'f').toList();
    return [
      ..._head('🩺', 'هیچ دۆخێکی تەندروستیت هەیە؟', [
        const TextSpan(text: 'ئارەزوومەندانەیە. یارمەتیمان دەدات ئاگادارکردنەوە و ئامۆژگارییەکان بۆ تۆ وردتر بکەین.'),
      ], compact: compact, tight: tight, kb: kb),
      _p(Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final c in list)
            RChip(
              label: c.t,
              icon: c.e,
              on: d.conds.contains(c.k),
              compact: tight,
              onTap: () {
                setState(() {
                  d.condsDone = true;
                  if (d.conds.contains(c.k)) {
                    d.conds.remove(c.k);
                  } else {
                    d.conds.add(c.k);
                  }
                });
                buzz(0);
                _saveDraft();
              },
            ),
          RChip(
            label: 'هیچیان',
            icon: '✓',
            on: d.conds.isEmpty && d.condsDone,
            compact: tight,
            onTap: () {
              setState(() {
                d.conds = [];
                d.condsDone = true;
              });
              buzz(0);
              _saveDraft();
            },
          ),
        ],
      )),
      _p(const RLock('ئەم زانیارییە نهێنییە، لەسەر مۆبایلەکەت دەمێنێتەوە و بۆ بازنەی خێزانیش دەرناکەوێت.')),
      _p(const RHint([TextSpan(text: 'VEX ئامرازێکی پزیشکی نییە و جێگەی پزیشک ناگرێتەوە.')])),
    ];
  }

  // ---------- ئاگادارکردنەوەکان ----------
  List<Widget> _notif(bool compact, bool tight, bool kb) {
    final list = kNotif.where((n) => n.k != 'heart' || d.band.has == true).toList();
    return [
      ..._head('🔔', 'ئاگادارکردنەوەکان', [
        const TextSpan(text: 'تەنها ئەوانەی سوودیان بۆ تۆ هەیە. هەر کاتێک دەتوانیت لە ڕێکخستنەکاندا بیانگۆڕیت.'),
      ], compact: compact, tight: tight, kb: kb),
      _p(Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          color: RC.white(0.035),
          border: Border.all(color: RC.line(0.12)),
        ),
        child: Column(
          children: [
            for (int i = 0; i < list.length; i++)
              Container(
                padding: EdgeInsets.symmetric(vertical: tight ? 10 : 13),
                decoration: BoxDecoration(
                  border: i == 0 ? null : Border(top: BorderSide(color: RC.line(0.1))),
                ),
                child: Row(
                  children: [
                    Container(
                      width: tight ? 36 : 42,
                      height: tight ? 36 : 42,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), color: RC.white(0.05)),
                      child: RIco(list[i].e, size: tight ? 38 : 44, radius: 14),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          VText(list[i].t, style: ku(14.5, w: FontWeight.w800, h: 1.4)),
                          VText(list[i].s, style: ku(12, c: RC.mu, h: 1.6)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    RSwitch(
                      on: d.notif[list[i].k] == true,
                      label: list[i].t,
                      onTap: () {
                        setState(() => d.notif[list[i].k] = !(d.notif[list[i].k] == true));
                        buzz(0);
                        _saveDraft();
                      },
                    ),
                  ],
                ),
              ),
          ],
        ),
      )),
    ];
  }

  // ---------- پلان ----------
  List<Widget> _plan(bool compact, bool tight, bool kb) {
    if (!d.built) {
      return [
        _p(RBuildShow(
          bandHas: d.band.has == true,
          compact: compact,
          onDone: () {
            setState(() => d.built = true);
            buzz(1);
            _saveDraft();
          },
        )),
      ];
    }
    return [_p(Rise(child: RPlanSummary(d: d, compact: tight)))];
  }

  // ---------- خوارەوە: دوگمەی سەرەکی ----------
  Widget _footer(MediaQueryData mq, {required bool kb, required bool compact}) {
    final alt = _alt();
    final welcome = cur == 'welcome';
    return Padding(
      padding: EdgeInsets.fromLTRB(22, kb ? 6 : (welcome ? 6 : 10), 22, mq.padding.bottom + (kb ? 8 : (compact ? 12 : 18))),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!_noGo)
            RGo(
              label: busy ? busyLabel : _cta(),
              enabled: _ok(cur) || busy,
              busy: busy,
              compact: kb,
              onTap: _onGo,
            ),
          if (alt.isNotEmpty) RLink(alt, top: welcome ? 6 : (kb ? 4 : 12), onTap: busy ? null : _onAlt),
          if (welcome)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: VText(
                LangState.I.t('terms'),
                textAlign: TextAlign.center,
                textDirection: dirOfLang(LangState.I.cur),
                style: langStyle(LangState.I.cur, 10.5, c: RC.dim, h: 1.6),
              ),
            ),
        ],
      ),
    );
  }
}

// ---------- پشتەوە ----------
class _RegBg extends StatelessWidget {
  const _RegBg();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0, -1.08),
                radius: 0.95,
                colors: [vk(0x382FE6F3), vk(0x002FE6F3)],
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(1, 1.1),
                radius: 0.8,
                colors: [vk(0x1F3CF08A), vk(0x003CF08A)],
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(-1, 0.2),
                radius: 0.6,
                colors: [vk(0x129B7BFF), vk(0x009B7BFF)],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// تیری گەڕانەوە (ڕوو لە ڕاست، بۆ ئەپی کوردی)
class _Chevron extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 24;
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = V.tx;
    final path = Path()
      ..moveTo(9 * s, 6 * s)
      ..lineTo(15 * s, 12 * s)
      ..lineTo(9 * s, 18 * s);
    canvas.drawPath(path, p);
  }

  @override
  bool shouldRepaint(_Chevron o) => false;
}

/// ✓ ی پەیوەستبوونی Band
class _PairOk extends StatelessWidget {
  const _PairOk();

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutBack,
      builder: (context, v, child) => Opacity(
        opacity: v.clamp(0.0, 1.0),
        child: Transform.scale(scale: 0.3 + 0.7 * v, child: child),
      ),
      child: Container(
        width: 92,
        height: 92,
        margin: const EdgeInsets.only(top: 6, bottom: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: V.prime,
          boxShadow: [BoxShadow(color: vk(0xB33CF08A), blurRadius: 50, spreadRadius: -6)],
        ),
        child: VText('✓', style: ku(44, w: FontWeight.w900, c: V.ink, h: 1.1)),
      ),
    );
  }
}


// ---------- هەژماری Gmail (لیست) ----------
class _GmTile extends StatelessWidget {
  const _GmTile({required this.name, required this.email, required this.has, required this.on, required this.onTap});
  final String name;
  final String email;
  final bool has;
  final bool on;
  final VoidCallback onTap;

  static final List<int> _cols = [0xFF2FE6F3, 0xFF3CF08A, 0xFFFFBE4D, 0xFFB9A4FF, 0xFFFF7A8A, 0xFF6EA8FF];

  @override
  Widget build(BuildContext context) {
    final seed = email.codeUnits.fold<int>(0, (a, b) => a + b);
    final k = vk(_cols[seed % _cols.length]);
    final src = name.trim().isNotEmpty ? name.trim() : email;
    final letter = String.fromCharCode(src.runes.first).toUpperCase();
    return Press(
      onTap: onTap,
      scale: 0.98,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: on ? V.mint : RC.line(0.14), width: 1.5),
          gradient: on ? LinearGradient(colors: [Color(0x1A8FF3F9), Color(0x1A3CF08A)]) : null,
          color: on ? null : RC.white(0.035),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [k, mix(k, vk(0xFF0B2C36), 0.45)]),
              ),
              child: VText(letter, style: nu(18, c: vk(0xFF04161C), h: 1)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (name.trim().isNotEmpty)
                    VText(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: ku(14.5, w: FontWeight.w800, c: kW, h: 1.4)),
                  Directionality(
                    textDirection: TextDirection.ltr,
                    child: Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: Text(email, maxLines: 1, overflow: TextOverflow.ellipsis, style: nu(12.5, w: FontWeight.w600, c: RC.mu, h: 1.5)),
                    ),
                  ),
                ],
              ),
            ),
            if (has) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(color: op(V.mint, 0.14), borderRadius: BorderRadius.circular(99), border: Border.all(color: op(V.mint, 0.4))),
                child: VText('داتای هەیە', style: ku(10.5, w: FontWeight.w800, c: V.mint, h: 1.4)),
              ),
            ],
            const SizedBox(width: 10),
            RCheck(on: on),
          ],
        ),
      ),
    );
  }
}

class _GmAddTile extends StatelessWidget {
  const _GmAddTile({required this.open, required this.onTap});
  final bool open;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Press(
      onTap: onTap,
      scale: 0.98,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: open ? V.cy : RC.line(0.22), width: 1.5),
          color: RC.white(0.02),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              alignment: Alignment.center,
              decoration: BoxDecoration(shape: BoxShape.circle, color: RC.white(0.06), border: Border.all(color: RC.line(0.25))),
              child: svgIcon('<path d="M12 5v14M5 12h14"/>', '#8ff3f9', size: 20, stroke: 2.4),
            ),
            const SizedBox(width: 12),
            Expanded(child: VText('Gmail ێکی تر زیاد بکە', style: ku(14.5, w: FontWeight.w800, c: kW, h: 1.4))),
          ],
        ),
      ),
    );
  }
}
