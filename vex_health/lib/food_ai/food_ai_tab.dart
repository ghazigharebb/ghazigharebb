// VEX AI Food v2 — تابی VEX AI: ئەمڕۆ، وێنەگرتن، خواردنەکانی تۆ، ژەمەکانی ئەمڕۆ
//
// هیچ لیستی خواردن (کاتالۆگ) نییە: تەنها وێنە یان نووسین. AI خۆی دەیناسێتەوە.
import 'package:flutter/material.dart';

import '../core/store.dart';
import '../core/theme.dart';
import 'food_ai_data.dart';
import 'food_ai_flow.dart';
import 'food_ai_store.dart';
import 'food_ai_widgets.dart';

/// داواکردنی گۆڕینی تاب (main.dart گوێی لێدەگرێت)
final ValueNotifier<int?> appTabRequest = ValueNotifier<int?>(null);
const int kFoodTab = 2;

/// بەشی خواردن ← تابی VEX AI
void goFoodTab() {
  navKey.currentState?.popUntil((r) => r.isFirst);
  appTabRequest.value = null;
  appTabRequest.value = kFoodTab;
}

class FoodAiTab extends StatefulWidget {
  const FoodAiTab({super.key});

  @override
  State<FoodAiTab> createState() => _FoodAiTabState();
}

class _FoodAiTabState extends State<FoodAiTab> {
  @override
  void initState() {
    super.initState();
    FoodAiStore.I.init();
  }

  Future<void> _remove(FLog x) async {
    final ok = await showFoodSheet<bool>(context, (ctx) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            CheckerBox(radius: 14, child: SizedBox(width: 56, height: 56, child: Center(child: DishPng(x.dish, size: 52)))),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(x.dish.name, style: ku(17, w: FontWeight.w700)),
                Text('${qtyWord(x.q, x.unit)} · ${n0(x.nut.k)} kcal', style: ku(12, c: V.mu)),
              ]),
            ),
          ]),
          const SizedBox(height: 14),
          SoftBtn(key: const ValueKey<String>('fa-log-del-ok'), label: 'سڕینەوە لە ئەمڕۆ', icon: FI.trash, color: kFat, onTap: () => Navigator.of(ctx).pop(true)),
          const SizedBox(height: 7),
          SoftBtn(label: 'پاشگەزبوونەوە', onTap: () => Navigator.of(ctx).pop(false)),
        ]));
    if (ok == true) await FoodAiStore.I.remove(x);
  }

  Future<void> _mineMenu(FDish d) async {
    final r = await showFoodSheet<String>(context, (ctx) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            CheckerBox(radius: 14, child: SizedBox(width: 56, height: 56, child: Center(child: DishPng(d, size: 52)))),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(d.name, style: ku(17, w: FontWeight.w700)),
                Text('${qtyWord(d.q0, d.u0)} · ${n0(d.nut(d.u0, d.q0).k)} kcal', style: ku(12, c: V.mu)),
              ]),
            ),
          ]),
          const SizedBox(height: 14),
          GradBtn(label: 'زیادکردن بۆ ئەمڕۆ', icon: FI.plus, onTap: () => Navigator.of(ctx).pop('add')),
          const SizedBox(height: 7),
          SoftBtn(label: 'لابردن لە خواردنەکانی تۆ', icon: FI.trash, color: kFat, onTap: () => Navigator.of(ctx).pop('del')),
        ]));
    if (r == 'add') openFoodQuick(d);
    if (r == 'del') await FoodAiStore.I.removeMine(d);
  }

  Widget _head() {
    return Row(children: [
      Container(
        width: 44,
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(gradient: V.ai, borderRadius: BorderRadius.circular(15)),
        child: ic(FI.spark, Colors.white, size: 22, fill: true),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('VEX AI · خواردن', style: ku(20, w: FontWeight.w800)),
          Text(kurdishDate(), style: ku(12, c: V.mu)),
        ]),
      ),
      FChip(
        color: FoodAiEngine.live ? V.mint : kWarn,
        child: Text(FoodAiEngine.live ? 'AI بەستراوە' : 'دۆخی نموونە', style: ku(11, w: FontWeight.w700, c: FoodAiEngine.live ? V.mint : kWarn)),
      ),
    ]);
  }

  Widget _today() {
    final t = Store.I.totals();
    final goal = Store.I.h.goal.toDouble();
    final left = (goal - t.kcal).round();
    Widget bar(String l, int v, double g, Color c) => Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [
              Text(l, style: ku(12)),
              const Spacer(),
              Text('$v / ${g.round()}g', style: nu(11.5, w: FontWeight.w600, c: V.mu), textDirection: TextDirection.ltr),
            ]),
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(7),
              child: SizedBox(
                height: 7,
                child: Stack(children: [
                  Positioned.fill(child: ColoredBox(color: V.track)),
                  TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0, end: g <= 0 ? 0.0 : (v / g).clamp(0.0, 1.0).toDouble()),
                    duration: const Duration(milliseconds: 1000),
                    curve: kEase,
                    builder: (context, f, _) => FractionallySizedBox(
                      alignment: AlignmentDirectional.centerStart,
                      widthFactor: f,
                      child: Container(decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(7))),
                    ),
                  ),
                ]),
              ),
            ),
          ]),
        );
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: box(r: 24, color: V.surf),
      child: Row(children: [
        KcalRing(v: t.kcal.toDouble(), goal: goal, size: 108),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text.rich(
              TextSpan(children: [
                TextSpan(text: left >= 0 ? 'ماوە: ' : 'زیاتر: '),
                TextSpan(text: fmt(left.abs()), style: nu(13, w: FontWeight.w800, c: left >= 0 ? V.mint : kFat)),
                const TextSpan(text: ' kcal'),
              ]),
              style: ku(12.5, w: FontWeight.w600, c: V.mu),
            ),
            bar('پرۆتین', t.p, goal * .25 / 4, kPro),
            bar('کاربۆهیدرات', t.c, goal * .45 / 4, kCarb),
            bar('چەوری', t.f, goal * .30 / 9, kFat),
          ]),
        ),
      ]),
    );
  }

  Widget _capture() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: VexTheme.I.isLight ? [op(V.cy, 0.14), V.surf] : const [Color(0xFF16414A), Color(0xFF0F2C33)],
        ),
        border: Border.all(color: VexTheme.I.isLight ? op(V.cy, 0.35) : const Color(0xFF2A5761)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Press(
          key: const ValueKey<String>('fa-open-cam'),
          onTap: () => openFoodCapture(),
          child: Container(
            height: 92,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [kCy, kMint]),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: kCy.withAlpha(80), blurRadius: 26, offset: const Offset(0, 12), spreadRadius: -10)],
            ),
            child: Row(children: [
              Container(
                width: 56,
                height: 56,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: kInk.withAlpha(30), shape: BoxShape.circle, border: Border.all(color: kInk.withAlpha(60), width: 1.5)),
                child: ic(FI.cam, kInk, size: 28, stroke: 2.2),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('وێنەی خواردنەکەت بگرە', style: ku(17, w: FontWeight.w800, c: kInk)),
                  Text('تا 5 وێنە بە یەک جار · AI هەموو خواردنێک دەناسێتەوە', maxLines: 2, style: ku(11.5, w: FontWeight.w600, c: kInk.withAlpha(190))),
                ]),
              ),
            ]),
          ),
        ),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: SoftBtn(key: const ValueKey<String>('fa-open-gal'), label: 'گەلەری', icon: FI.gal, onTap: () => openFoodCapture(gallery: true))),
          const SizedBox(width: 8),
          Expanded(child: SoftBtn(key: const ValueKey<String>('fa-open-text'), label: 'بنووسە', icon: FI.edit, onTap: openFoodText)),
        ]),
      ]),
    );
  }

  Widget _mine() {
    final m = FoodAiStore.I.mine;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _title('خواردنەکانی تۆ', m.isEmpty ? null : '${m.length}'),
      if (m.isEmpty)
        Container(
          padding: const EdgeInsets.all(14),
          decoration: box(r: 18, color: V.surf),
          child: Row(children: [
            ic(FI.save, V.cy, size: 20),
            const SizedBox(width: 10),
            Expanded(child: Text('لە وردەکاریی هەر خواردنێک «پاشەکەوت» دابگرە — جاری داهاتوو بە یەک دەستلێدان زیاد دەبێت.', style: ku(12, c: V.mu, h: 1.5))),
          ]),
        )
      else
        SizedBox(
          height: 112,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: m.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              final d = m[i];
              return Press(
                key: ValueKey<String>('fa-mine-$i'),
                onTap: () => _mineMenu(d),
                child: Container(
                  width: 104,
                  padding: const EdgeInsets.all(8),
                  decoration: box(r: 18, color: V.surf),
                  child: Column(children: [
                    DishPng(d, size: 50),
                    const SizedBox(height: 4),
                    Text(d.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: ku(12, w: FontWeight.w700)),
                    Text('${n0(d.nut(d.u0, d.q0).k)} kcal', style: ku(10.5, c: V.mu)),
                  ]),
                ),
              );
            },
          ),
        ),
    ]);
  }

  Widget _title(String t, String? badge) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 18, 4, 8),
        child: Row(children: [
          Text(t, style: ku(15, w: FontWeight.w800)),
          if (badge != null) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
              decoration: BoxDecoration(color: op(V.cy, 0.14), borderRadius: BorderRadius.circular(99)),
              child: Text(badge, style: nu(11, c: V.cy)),
            ),
          ],
        ]),
      );

  Widget _meals() {
    final l = FoodAiStore.I.today;
    if (l.isEmpty) {
      return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        _title('ژەمەکانی ئەمڕۆ', null),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 14),
          decoration: box(r: 18, color: V.surf),
          child: Column(children: [
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              for (final id in ['rice', 'kebab', 'salad'])
                Padding(padding: const EdgeInsets.symmetric(horizontal: 2), child: Opacity(opacity: .55, child: DishPng(dishById(id)!, size: 40))),
            ]),
            const SizedBox(height: 8),
            Text('هێشتا هیچ خواردنێکت تۆمار نەکردووە', style: ku(13, w: FontWeight.w600)),
            Text('وێنەیەک بگرە، AI ـەکە خۆی دەیناسێتەوە', style: ku(11.5, c: V.mu)),
          ]),
        ),
      ]);
    }
    final out = <Widget>[];
    var idx = 0;
    for (final s in kMealOrder) {
      final g = l.where((x) => x.slot == s).toList();
      if (g.isEmpty) continue;
      final k = g.fold<double>(0, (a, x) => a + x.nut.k);
      out.add(Padding(
        padding: const EdgeInsets.fromLTRB(4, 18, 4, 8),
        child: Row(children: [
          Text(kMealName[s]!, style: ku(15, w: FontWeight.w800)),
          const SizedBox(width: 6),
          Text(g.first.at, style: nu(11.5, w: FontWeight.w600, c: V.mu), textDirection: TextDirection.ltr),
          const Spacer(),
          Text('${fmt(k)} kcal', style: nu(13, w: FontWeight.w700, c: V.cy), textDirection: TextDirection.ltr),
        ]),
      ));
      for (final x in g) {
        final i = idx++;
        out.add(Container(
          key: ValueKey<String>('fa-log-$i'),
          margin: const EdgeInsets.only(bottom: 7),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: box(r: 18, color: V.surf),
          child: Row(children: [
            CheckerBox(radius: 13, child: SizedBox(width: 46, height: 46, child: Center(child: DishPng(x.dish, size: 43)))),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(x.dish.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: ku(14.5, w: FontWeight.w700)),
                Text(qtyWord(x.q, x.unit), style: ku(11.5, c: V.mu)),
              ]),
            ),
            Column(children: [
              Text(fmt(x.nut.k), style: nu(16, c: V.tx), textDirection: TextDirection.ltr),
              Text('kcal', style: ku(10, c: V.mu)),
            ]),
            const SizedBox(width: 4),
            Press(
              key: ValueKey<String>('fa-log-del-$i'),
              onTap: () => _remove(x),
              child: Padding(padding: const EdgeInsets.all(6), child: ic(FI.trash, V.mu, size: 17)),
            ),
          ]),
        ));
      }
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: out);
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    return ListenableBuilder(
      listenable: Listenable.merge([FoodAiStore.I, Store.I, VexTheme.I]),
      builder: (context, _) => Directionality(
        textDirection: TextDirection.rtl,
        child: ListView(
          padding: EdgeInsets.fromLTRB(16, mq.padding.top + 14, 16, mq.padding.bottom + 120),
          children: [
            _head(),
            const SizedBox(height: 14),
            _today(),
            const SizedBox(height: 12),
            _capture(),
            _mine(),
            _meals(),
          ],
        ),
      ),
    );
  }
}
