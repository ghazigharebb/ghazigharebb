// VEX Plus — شیتی پارەدان: FIB / Qi Card / FastPay (ڕووناک، تاریک و خۆکار)
// بانگ بکە: `final paid = await showPlusPay(plan);`  ← true ئەگەر پارەکە وەرگیرا.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/theme.dart';
import 'plus_state.dart';

/// شێوازێکی پارەدان. ڕەنگەکان جێگیرن (ڕەنگی برەندەکەن) و لە هەر سێ دۆخدا دەخوێنرێنەوە.
class PayMethod {
  const PayMethod({
    required this.id,
    required this.name,
    required this.sub,
    required this.asset,
    required this.accent,
    required this.btn,
    required this.btnText,
    required this.hint,
    this.appUri,
  });
  final String id; // fib | qicard | fastpay
  final String name;
  final String sub;
  final String asset; // assets/pay/xxx.png
  final Color accent; // لێوار و نیشانەی هەڵبژێردراو
  final Color btn; // پاشبنەمای دوگمەی پارەدان
  final Color btnText;
  final String hint;
  final String? appUri; // بۆ کردنەوەی ئەپ (ئەگەر FIB/Qi/FastPay ڕێگە بدەن)
}

const List<PayMethod> kPayMethods = [
  PayMethod(
    id: 'fib',
    name: 'FIB',
    sub: 'لە ئەپی FIB ـەوە، بێ کارت',
    asset: 'assets/pay/fib.png',
    accent: Color(0xFF0A9488),
    btn: Color(0xFF007E75),
    btnText: Color(0xFFFFFFFF),
    hint: 'ئەپی FIB بکەرەوە ← «سکان» ← ئەم بارکۆدە بخوێنەرەوە',
  ),
  PayMethod(
    id: 'qicard',
    name: 'Qi Card',
    sub: 'بە کارتی Qi یان ئەپی Qi',
    asset: 'assets/pay/qi.png',
    accent: Color(0xFFA77B00),
    btn: Color(0xFFFFCB05),
    btnText: Color(0xFF1A1400),
    hint: 'ئەپی Qi بکەرەوە ← «سکان» ← ئەم بارکۆدە بخوێنەرەوە',
  ),
  PayMethod(
    id: 'fastpay',
    name: 'FastPay',
    sub: 'لە ئەپی FastPay ـەوە',
    asset: 'assets/pay/fastpay.png',
    accent: Color(0xFFD42A57),
    btn: Color(0xFFC8254F),
    btnText: Color(0xFFFFFFFF),
    hint: 'ئەپی FastPay بکەرەوە ← «سکان» ← ئەم بارکۆدە بخوێنەرەوە',
  ),
];

PayMethod payMethodOf(String id) => kPayMethods.firstWhere((m) => m.id == id, orElse: () => kPayMethods.first);

/// شیتی پارەدان دەکاتەوە. `true` = پارەکە وەرگیرا، `null/false` = هەڵوەشێنرایەوە.
Future<bool?> showPlusPay(PlusPlan plan, {String? method}) => showVSheet<bool>(builder: (c) => PlusPaySheet(plan: plan, method: method));

enum _Step { pick, scan }

class PlusPaySheet extends StatefulWidget {
  const PlusPaySheet({super.key, required this.plan, this.method});
  final PlusPlan plan;
  final String? method; // ئەگەر دیاری کرابێت، یەکسەر دەچێتە قۆناغی بارکۆد

  @override
  State<PlusPaySheet> createState() => _PlusPaySheetState();
}

class _PlusPaySheetState extends State<PlusPaySheet> {
  late String _id = widget.method ?? 'fib';
  _Step _step = _Step.pick;
  PayRequest? _req;
  bool _loading = false;
  bool _expired = false;
  String? _err;
  int _left = 0;
  Timer? _tick;
  Timer? _poll;
  bool _checking = false;

  PayMethod get _m => payMethodOf(_id);

  @override
  void initState() {
    super.initState();
    if (widget.method != null) WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  @override
  void dispose() {
    _stop();
    super.dispose();
  }

  void _stop() {
    _tick?.cancel();
    _poll?.cancel();
    _tick = null;
    _poll = null;
  }

  Future<void> _start() async {
    if (_loading) return;
    HapticFeedback.mediumImpact();
    setState(() {
      _loading = true;
      _err = null;
    });
    try {
      final r = await PlusPayment.create(_id, widget.plan);
      if (!mounted) return;
      setState(() {
        _req = r;
        _step = _Step.scan;
        _loading = false;
        _expired = false;
        _left = r.expiresAt.difference(DateTime.now()).inSeconds;
      });
      _stop();
      _tick = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        final l = _req!.expiresAt.difference(DateTime.now()).inSeconds;
        setState(() {
          _left = l < 0 ? 0 : l;
          if (l <= 0) _expired = true;
        });
        if (l <= 0) _stop();
      });
      _poll = Timer.periodic(const Duration(seconds: 2), (_) => _check());
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _err = 'نەتوانرا بارکۆد دروست بکرێت. دووبارە هەوڵ بدەوە.';
      });
    }
  }

  Future<void> _check() async {
    final r = _req;
    if (r == null || _checking || _expired) return;
    _checking = true;
    try {
      final s = await PlusPayment.status(r.id);
      if (!mounted) return;
      if (s == PayStatus.paid) {
        _stop();
        HapticFeedback.heavyImpact();
        Navigator.of(context).pop(true);
      } else if (s == PayStatus.failed || s == PayStatus.expired) {
        _stop();
        setState(() => _expired = true);
      }
    } catch (_) {
      // هەڵەی تۆڕ: دووبارە هەوڵ دەداتەوە لە خولی دواتر
    } finally {
      _checking = false;
    }
  }

  void _back() {
    _stop();
    setState(() {
      _step = _Step.pick;
      _req = null;
      _expired = false;
    });
  }

  Future<void> _openApp() async {
    final u = _req?.appLink ?? _m.appUri;
    if (u == null) return;
    try {
      await launchUrl(Uri.parse(u), mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: kDir,
      child: AnimatedSize(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        alignment: Alignment.topCenter,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: _step == _Step.pick ? _pick() : _scan(),
        ),
      ),
    );
  }

  // ============================ هەڵبژاردن ============================
  Widget _pick() {
    final p = widget.plan;
    return Column(
      key: const ValueKey('pick'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  VText('پارەدان', style: ku(20, w: FontWeight.w800, h: 1.4)),
                  VText('VEX Plus · ${plusTxt(p.name)}', style: ku(13, c: V.mu, h: 1.5)),
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                VText(fmt(p.price), textDirection: TextDirection.ltr, style: nu(24, c: V.tx)),
                const SizedBox(width: 5),
                VText('IQD', textDirection: TextDirection.ltr, style: nu(12, c: V.mu)),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        for (final m in kPayMethods) ...[
          _tile(m),
          const SizedBox(height: 10),
        ],
        const SizedBox(height: 4),
        if (_err != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: VText(_err!, textAlign: TextAlign.center, style: ku(12.5, c: V.coral, h: 1.6)),
          ),
        _payButton(),
        const SizedBox(height: 10),
        _lock(),
      ],
    );
  }

  Widget _tile(PayMethod m) {
    final on = m.id == _id;
    return Press(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _id = m.id);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          color: on ? V.surf2 : V.surf,
          border: Border.all(color: on ? m.accent : V.line, width: on ? 2 : 1.5),
        ),
        child: Row(
          children: [
            _logo(m, 54),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  VText(m.name, textDirection: TextDirection.ltr, style: nu(18, w: FontWeight.w800, c: V.tx, h: 1.3)),
                  VText(m.sub, style: ku(12.5, c: V.mu, h: 1.5)),
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: on ? m.accent : Colors.transparent,
                border: Border.all(color: on ? m.accent : V.line, width: 2),
              ),
              child: on ? const Icon(Icons.check_rounded, size: 17, color: Colors.white) : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _logo(PayMethod m, double s) {
    return Container(
      width: s,
      height: s,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(s * 0.29),
        border: Border.all(color: V.line),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(s * 0.29),
        child: Image.asset(m.asset, width: s, height: s, fit: BoxFit.cover, filterQuality: FilterQuality.high),
      ),
    );
  }

  Widget _payButton() {
    final m = _m;
    return Press(
      onTap: _start,
      child: Container(
        height: 58,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: m.btn, borderRadius: BorderRadius.circular(19)),
        child: _loading
            ? SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 3, color: m.btnText))
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.asset(m.asset, width: 34, height: 34, fit: BoxFit.cover),
                  ),
                  const SizedBox(width: 12),
                  VText('پارەدان بە', style: ku(17, w: FontWeight.w800, c: m.btnText, h: 1.3)),
                  const SizedBox(width: 6),
                  VText(m.name, textDirection: TextDirection.ltr, style: nu(17, w: FontWeight.w800, c: m.btnText, h: 1.3)),
                ],
              ),
      ),
    );
  }

  Widget _lock() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.lock_outline_rounded, size: 14, color: V.mu),
        const SizedBox(width: 6),
        VText('پارەدانەکە لەناو ئەپی شێوازەکە تەواو دەبێت', style: ku(12, c: V.mu, h: 1.5)),
      ],
    );
  }

  // ============================ بارکۆد ============================
  Widget _scan() {
    final m = _m;
    final r = _req;
    final p = widget.plan;
    final mm = (_left ~/ 60).toString().padLeft(2, '0');
    final ss = (_left % 60).toString().padLeft(2, '0');
    return Column(
      key: const ValueKey('scan'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Press(
              onTap: _back,
              child: Container(
                width: 42,
                height: 42,
                decoration: box(r: 14),
                child: Icon(Icons.chevron_right_rounded, color: V.tx, size: 24),
              ),
            ),
            Expanded(
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    VText('پارەدان بە', style: ku(17, w: FontWeight.w800, h: 1.4)),
                    const SizedBox(width: 6),
                    VText(m.name, textDirection: TextDirection.ltr, style: nu(17, w: FontWeight.w800, h: 1.4)),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 42),
          ],
        ),
        const SizedBox(height: 14),
        Center(child: VText('VEX Plus · ${plusTxt(p.name)}', style: ku(13, c: V.mu, h: 1.5))),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            VText(fmt(p.price), textDirection: TextDirection.ltr, style: nu(38, c: V.tx, h: 1.3)),
            const SizedBox(width: 6),
            VText('IQD', textDirection: TextDirection.ltr, style: nu(14, c: V.mu)),
          ],
        ),
        const SizedBox(height: 12),
        // بارکۆد هەمیشە لەسەر پاشبنەمای سپییە تا لە هەموو دۆخەکان بخوێنرێتەوە
        Center(
          child: Container(
            width: 264,
            height: 264,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: V.line),
            ),
            child: r == null
                ? const SizedBox()
                : Stack(
                    alignment: Alignment.center,
                    children: [
                      Opacity(
                        opacity: _expired ? 0.12 : 1,
                        child: QrImageView(
                          data: r.qrData,
                          version: QrVersions.auto,
                          errorCorrectionLevel: QrErrorCorrectLevel.H,
                          backgroundColor: Colors.white,
                          padding: EdgeInsets.zero,
                          eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: Color(0xFF04202A)),
                          dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: Color(0xFF04202A)),
                        ),
                      ),
                      if (!_expired)
                        Container(
                          width: 54,
                          height: 54,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            color: Colors.white,
                            boxShadow: const [BoxShadow(color: Colors.white, spreadRadius: 4)],
                          ),
                          child: ClipRRect(borderRadius: BorderRadius.circular(14), child: Image.asset(m.asset, fit: BoxFit.cover)),
                        ),
                      if (_expired)
                        Icon(Icons.refresh_rounded, size: 56, color: m.accent),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 14),
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(99),
              color: V.surf,
              border: Border.all(color: V.line),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.timer_outlined, size: 16, color: V.amber),
                const SizedBox(width: 8),
                VText(_expired ? 'بارکۆدەکە بەسەرچوو' : 'بارکۆدەکە ماوەی', style: ku(13.5, c: V.mu, h: 1.4)),
                if (!_expired) ...[
                  const SizedBox(width: 6),
                  VText('$mm:$ss', textDirection: TextDirection.ltr, style: nu(14, c: V.amber, h: 1.4)),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        VText(_expired ? 'دوگمەی خوارەوە بۆ بارکۆدی نوێ' : m.hint, textAlign: TextAlign.center, style: ku(13.5, c: V.mu, h: 1.8)),
        const SizedBox(height: 14),
        if (_expired)
          Press(
            onTap: _start,
            child: Container(
              height: 54,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: m.btn, borderRadius: BorderRadius.circular(18)),
              child: VText('بارکۆدی نوێ', style: ku(16, w: FontWeight.w800, c: m.btnText, h: 1.3)),
            ),
          )
        else if ((r?.appLink ?? m.appUri) != null)
          Press(
            onTap: _openApp,
            child: Container(
              height: 54,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: m.btn, borderRadius: BorderRadius.circular(18)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  VText('کردنەوەی ئەپی', style: ku(16, w: FontWeight.w800, c: m.btnText, h: 1.3)),
                  const SizedBox(width: 6),
                  VText(m.name, textDirection: TextDirection.ltr, style: nu(16, w: FontWeight.w800, c: m.btnText, h: 1.3)),
                ],
              ),
            ),
          )
        else
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2.4, color: m.accent)),
              const SizedBox(width: 10),
              VText('چاوەڕێی پارەدان…', style: ku(13.5, c: V.mu, h: 1.5)),
            ],
          ),
        const SizedBox(height: 6),
        Center(
          child: Press(
            onTap: _back,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: VText('گۆڕینی شێوازی پارەدان', style: ku(13.5, w: FontWeight.w700, c: V.cy, h: 1.3)),
            ),
          ),
        ),
        // تەنها لە دیمۆ: دوگمەی «پارەکەم دا» — لە ڕاستەقینە سێرڤەر وەڵام دەداتەوە
        if (PlusPayment.isDemo && r != null && !_expired)
          Center(
            child: Press(
              onTap: () {
                PlusPayment.demoMarkPaid(r.id);
                _check();
              },
              child: Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 22),
                alignment: Alignment.center,
                decoration: box(r: 14),
                child: VText('پارەکەم دا (دیمۆ)', style: ku(13.5, w: FontWeight.w700, h: 1.3)),
              ),
            ),
          ),
      ],
    );
  }
}
