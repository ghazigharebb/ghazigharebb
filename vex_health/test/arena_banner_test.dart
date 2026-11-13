// تاقیکردنەوەی بانەری «VEX Arena دەستپێدەکات» (ژمێرەری زیندوو)
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vex_health/arena/arena_countdown_banner.dart';

void main() {
  final start = DateTime(2026, 11, 20, 10);
  late DateTime now;
  var taps = 0, ended = 0;

  Widget app(Widget child) => MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(body: Padding(padding: const EdgeInsets.all(16), child: SizedBox(width: 358, child: child))),
        ),
      );

  Widget slot() => ArenaCountdownSlot(
        startsAt: start,
        clock: () => now,
        onTap: () => taps++,
        onEnded: () => ended++,
        fallback: const Text('BAND', key: Key('band')),
      );

  setUp(() {
    taps = 0;
    ended = 0;
  });

  test('ArenaTimeLeft: ڕۆژ/کاتژمێر/خولەک/چرکە', () {
    final l = ArenaTimeLeft(const Duration(days: 7, hours: 12, minutes: 33, seconds: 23));
    expect([l.days, l.hours, l.minutes, l.seconds], [7, 12, 33, 23]);
    expect(ArenaTimeLeft.two(7), '07');
    final z = ArenaTimeLeft(const Duration(seconds: -5));
    expect([z.days, z.hours, z.minutes, z.seconds], [0, 0, 0, 0]);
  });

  testWidgets('زیاتر لە ٧ ڕۆژ ماوە ← دۆخی Band', (t) async {
    now = start.subtract(const Duration(days: 8));
    await t.pumpWidget(app(slot()));
    expect(find.byKey(const Key('band')), findsOneWidget);
    expect(find.text('VEX Arena'), findsNothing);
    await t.pumpWidget(const SizedBox());
  });

  testWidgets('لە ماوەی ٧ ڕۆژدا ← بانەر + ژمێرەر + پەنجە لێدان', (t) async {
    now = start.subtract(const Duration(days: 6, hours: 12, minutes: 33, seconds: 23));
    await t.pumpWidget(app(slot()));
    await t.pump(const Duration(milliseconds: 500));
    expect(find.text('VEX Arena'), findsOneWidget);
    expect(find.byKey(const Key('band')), findsNothing);
    expect(find.text('06'), findsOneWidget);
    expect(find.text('12'), findsOneWidget);
    expect(find.text('33'), findsOneWidget);
    expect(find.text('23'), findsOneWidget);
    expect(t.takeException(), isNull); // هیچ overflow ـێک نییە لە 358 px

    // چرکەیەک دواتر ← 22
    now = now.add(const Duration(seconds: 1));
    await t.pump(const Duration(seconds: 1));
    expect(find.text('22'), findsOneWidget);

    await t.tap(find.text('VEX Arena'));
    await t.pump(const Duration(milliseconds: 200));
    expect(taps, 1);
    await t.pumpWidget(const SizedBox());
  });

  testWidgets('کاتەکە تەواو بوو ← بانەر لادەچێت و دۆخی Band دەگەڕێتەوە', (t) async {
    now = start.subtract(const Duration(seconds: 2));
    await t.pumpWidget(app(slot()));
    await t.pump(const Duration(milliseconds: 500));
    expect(find.text('VEX Arena'), findsOneWidget);
    now = start.add(const Duration(seconds: 1));
    await t.pump(const Duration(seconds: 1));
    await t.pump(const Duration(milliseconds: 600));
    expect(find.text('VEX Arena'), findsNothing);
    expect(find.byKey(const Key('band')), findsOneWidget);
    expect(ended, 1);
    await t.pumpWidget(const SizedBox());
  });

  testWidgets('شاشەی بچووک (328 px) ← هیچ overflow ـێک', (t) async {
    now = start.subtract(const Duration(days: 6, hours: 23));
    await t.pumpWidget(MaterialApp(
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(body: Center(child: SizedBox(width: 328, child: slot()))),
      ),
    ));
    await t.pump(const Duration(milliseconds: 500));
    expect(find.text('VEX Arena'), findsOneWidget);
    expect(t.takeException(), isNull);
    await t.pumpWidget(const SizedBox());
  });
}
