// تاقیکردنەوەی «هاوڕێ، خواردن»: دروستکردنی وێنەی ئەمڕۆ، JSON، سێرڤەری HTTP، کارتەکان (6 زمان × 2 ڕەنگ)
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vex_health/core/store.dart';
import 'package:vex_health/core/theme.dart';
import 'package:vex_health/family/family_data.dart';
import 'package:vex_health/family/family_page.dart';
import 'package:vex_health/family/friend_food.dart';
import 'package:vex_health/onboarding/account.dart';
import 'package:vex_health/onboarding/reg_lang_state.dart';

String p2(int n) => n.toString().padLeft(2, '0');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  final now = DateTime.now();
  String key(int back) {
    final d = now.subtract(Duration(days: back));
    return '${d.year}-${p2(d.month)}-${p2(d.day)}';
  }

  final fd = {
    'prof': {'name': 'Ghazi', 'sex': 'm', 'age': 32, 'h': 178, 'w': 77, 'goal': 'lose', 'pace': 0.5, 'act': 1.375},
    'days': {
      key(0): {
        'water': 3,
        'm': {
          'b': [
            {'n': 'هێلکە و نان', 'kcal': 320, 'p': 16, 'c': 30, 'f': 12, 'at': '07:40', 'v': 'ok'}
          ],
          'l': [
            {'n': 'برنج و مریشک', 'kcal': 610, 'p': 42, 'c': 60, 'f': 18, 'at': '13:15', 'v': 'ok'},
            {'n': 'کۆکا', 'kcal': 140, 'p': 0, 'c': 35, 'f': 0, 'at': '13:20', 'v': 'bad'}
          ],
        }
      },
      for (var i = 1; i <= 5; i++)
        key(i): {
          'water': 6,
          'm': {
            'l': [
              {'n': 'دۆلمە', 'kcal': 1500 + i * 120, 'p': 50, 'c': 160, 'f': 60}
            ]
          }
        },
    },
  };
  final home = {
    'day': Store.today,
    'items': [
      {'n': 'سێو', 'kcal': 80, 'p': 0, 'c': 21, 'f': 0, 'at': '16:30', 'v': 'ok', 'e': '🍎', 'slot': 's'}
    ],
  };

  Future<void> seed({bool share = true}) async {
    FriendFood.I.shutdown();
    SharedPreferences.setMockInitialValues({
      'vexuser': jsonEncode({'name': 'Ghazi', 'email': 'ghazi@example.com', 'sex': 'm', 'year': 1994, 'h': 178, 'w': 77}),
      'vexfd_v1': jsonEncode(fd),
      'vexhome-food': jsonEncode(home),
      'vexwater': jsonEncode({'day': Store.today, 'n': 2}),
    });
    await Account.I.load();
    await Store.I.load();
    await FamilyStore.I.load();
    FamilyStore.I.share['food'] = share;
    FriendFood.I.backend = FFLocalBackend();
    await FriendFood.I.init();
    await FriendFood.I.publishNow();
  }

  Future<void> settle(WidgetTester t, [int n = 25]) async {
    await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 250)));
    for (var i = 0; i < n; i++) {
      await t.pump(const Duration(milliseconds: 100));
    }
    await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 150)));
    for (var i = 0; i < 10; i++) {
      await t.pump(const Duration(milliseconds: 100));
    }
  }

  Future<void> finish(WidgetTester t) async {
    await t.pumpWidget(const SizedBox());
    FriendFood.I.shutdown();
    await t.pump(const Duration(seconds: 2));
  }

  test('ffBuildMine: هەموو سەرچاوەکان', () async {
    await seed();
    final s = await ffBuildMine(uid: 'u1', name: 'Ghazi');
    expect(s.items.length, 4);
    expect(s.kcal, 320 + 610 + 140 + 80);
    expect(s.water, 5);
    expect(s.items.first.at, '07:40');
    expect(s.items.where((x) => x.w).length, 1);
    expect(s.goal, inInclusiveRange(1500, 3500));
    expect(s.week.length, 7);
    expect(s.week.last, s.kcal);
    expect(s.week.where((x) => x != null).length, 6);
    final j = jsonDecode(jsonEncode(s.toJson()));
    final r = FFSnap.fromJson(j)!;
    expect(r.kcal, s.kcal);
    expect(r.items.length, 4);
    expect(r.water, 5);
    expect(r.goal, s.goal);
    expect(j['score'], inInclusiveRange(42, 98));
    // ناردن بۆ کۆگای ناوخۆیی
    expect(FriendFood.I.mine?.kcal, s.kcal);
    final back = await FFLocalBackend().pull(FriendFood.I.myUid);
    expect(back.kind, 0);
    expect(back.snap!.kcal, s.kcal);
    expect(FriendFood.I.myUid, 'e:ghazi@example.com');
    FriendFood.I.shutdown();
  });

  test('هاوبەشکردن کوژاوە ← shared:false', () async {
    await seed(share: false);
    final back = await FFLocalBackend().pull(FriendFood.I.myUid);
    expect(back.kind, 1);
    FriendFood.I.shutdown();
  });

  test('FFSnap.fromJson: داتای خراپ', () {
    expect(FFSnap.fromJson(null), isNull);
    expect(FFSnap.fromJson({'day': 'x'}), isNull);
    final s = FFSnap.fromJson({
      'uid': 'a',
      'day': '2026-10-28',
      'goal': -5,
      'water': 999,
      'items': [
        {'n': '', 'k': 5},
        {'n': 'نان', 'k': 'abc', 'at': '99:99', 's': 'zz'},
        'bad',
        {'n': 'شیر', 'kcal': 120.6, 'at': '8:5'},
      ],
      'week': [1, null, 'x', 4, 5, 6, 7, 8, 9],
    })!;
    expect(s.goal, 2000);
    expect(s.water, 40);
    expect(s.items.length, 2);
    expect(s.items[0].k, 0);
    expect(s.items[0].at, '');
    expect(s.items[1].k, 121);
    expect(s.items[1].at, '08:05');
    expect(s.items[1].s, 'b');
    expect(s.week.length, 7);
  });

  test('FFHttpBackend: push / pull / 403 / 404 / request', () async {
    final sent = <http.Request>[];
    final snap = FFSnap(
      uid: 'p:+9647500000000',
      name: 'غریب محمد',
      day: key(0),
      at: now.millisecondsSinceEpoch,
      items: const [FFItem(n: 'کباب', s: 'l', at: '13:00', k: 560, p: 38, c: 22, f: 30)],
      water: 4,
    );
    final c = MockClient((req) async {
      sent.add(req);
      if (req.method == 'GET' && req.url.path.endsWith('/locked')) return http.Response('', 403);
      if (req.method == 'GET' && req.url.path.endsWith('/nobody')) return http.Response('', 404);
      if (req.method == 'GET' && req.url.path.endsWith('/off')) {
        return http.Response.bytes(utf8.encode(jsonEncode({'shared': false, 'day': key(0)})), 200);
      }
      if (req.method == 'GET') return http.Response.bytes(utf8.encode(jsonEncode(snap.toJson())), 200);
      return http.Response('{}', 200);
    });
    final b = FFHttpBackend('https://api.example.com/', token: () async => 'T0K', client: c);
    await b.push(snap);
    expect(sent.last.method, 'PUT');
    expect(sent.last.url.toString(), 'https://api.example.com/v1/friends/food/p%3A%2B9647500000000');
    expect(sent.last.headers['Authorization'], 'Bearer T0K');
    expect(jsonDecode(sent.last.body)['kcal'], 560);
    final r = await b.pull('p:+9647500000000');
    expect(r.kind, 0);
    expect(r.snap!.name, 'غریب محمد');
    expect(r.snap!.kcal, 560);
    expect(sent.last.url.queryParameters['day'], key(0));
    expect((await b.pull('locked')).kind, 1);
    expect((await b.pull('nobody')).kind, 2);
    expect((await b.pull('off')).kind, 1);
    await b.requestShare('me', 'x');
    expect(sent.last.method, 'POST');
    expect(sent.last.url.path, '/v1/friends/food/x/request');
    final bad = FFHttpBackend('https://api.example.com', client: MockClient((_) async => http.Response('', 500)));
    await expectLater(bad.pull('a'), throwsA(isA<http.ClientException>()));
    await expectLater(bad.push(snap), throwsA(isA<http.ClientException>()));
  });

  testWidgets('receive: ژەمی نوێ', (t) async {
    await t.runAsync(seed);
    final m = FamilyStore.I.members.firstWhere((x) => x.id == 'm4');
    FriendFood.I.receive({
      'uid': 'm4',
      'day': key(0),
      'items': [
        {'n': 'هێلکە', 'k': 140, 's': 'b', 'at': '07:00'}
      ],
      'water': 1,
    });
    expect(FriendFood.I.snapOf(m)!.items.length, 1);
    FriendFood.I.receive({
      'uid': 'm4',
      'day': key(0),
      'items': [
        {'n': 'هێلکە', 'k': 140, 's': 'b', 'at': '07:00'},
        {'n': 'کباب', 'k': 560, 's': 'l', 'at': '13:00'}
      ],
      'water': 1,
    });
    expect(FriendFood.I.snapOf(m)!.items.length, 2);
    expect(FriendFood.I.isFresh(m), true);
    FriendFood.I.receive({'uid': 'm4', 'day': key(0), 'shared': false});
    expect(FriendFood.I.statusOf(m), FFStatus.locked);
    await finish(t);
  });

  for (final lang in ['ckb', 'kmr', 'en', 'ar', 'fa', 'tr']) {
    for (final light in [false, true]) {
      final tag = '${lang}_${light ? 'light' : 'dark'}';
      testWidgets('card $tag', (t) async {
        await t.binding.setSurfaceSize(const Size(400, 2600));
        await t.runAsync(seed);
        LangState.I.code = lang;
        await t.runAsync(() => VexTheme.I.setMode(light ? VexMode.light : VexMode.dark));
        final m4 = FamilyStore.I.members.firstWhere((x) => x.id == 'm4');
        final ghost = FMember(id: 'zz9', n: 'غریب', full: 'غریب محمد', rel: 'هاوڕێ', e: '🧑', g0: 0xFF445566, g1: 0xFF223344, col: 0xFF2FE6F3);
        await t.runAsync(() async {
          final sp = await SharedPreferences.getInstance();
          await sp.setString('vexff_box_v1', jsonEncode({'lk1': FFSnap.off('lk1', key(0)).toJson()}));
        });
        final locked = FMember(id: 'lk1', n: 'ڕێبوار', full: 'ڕێبوار', rel: 'هاوڕێ', e: '🧔', g0: 0xFF445566, g1: 0xFF223344, col: 0xFFFFBE4D);
        await t.pumpWidget(MaterialApp(
          navigatorKey: navKey,
          home: Scaffold(
            backgroundColor: V.bg,
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FriendFoodCard(member: m4),
                  const FriendFoodCard.me(),
                  FriendFoodCard(member: locked),
                  FriendFoodCard(member: ghost),
                  const FriendFoodPreviewLink(),
                ],
              ),
            ),
          ),
        ));
        await settle(t);
        expect(t.takeException(), isNull);
        expect(FriendFood.I.snapOf(m4), isNotNull);
        expect(FriendFood.I.statusOf(locked), FFStatus.locked);
        expect(FriendFood.I.statusOf(ghost), FFStatus.none);
        await expectLater(find.byType(Scaffold), matchesGoldenFile('goldens/ff_$tag.png'));
        await finish(t);
      });
    }
  }

  testWidgets('member sheet + preview sheet', (t) async {
    await t.binding.setSurfaceSize(const Size(400, 900));
    await t.runAsync(seed);
    LangState.I.code = 'ckb';
    await t.runAsync(() => VexTheme.I.setMode(VexMode.dark));
    await t.pumpWidget(MaterialApp(navigatorKey: navKey, home: const FamilyPage(openMemberId: 'm4')));
    await settle(t, 30);
    expect(t.takeException(), isNull);
    expect(find.byType(FriendFoodCard), findsWidgets);
    await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/sheet_member.png'));
    Navigator.of(navKey.currentContext!).pop();
    await settle(t, 10);
    openMyFoodPreview();
    await settle(t, 30);
    expect(t.takeException(), isNull);
    await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/sheet_mine.png'));
    // کوژاندنەوەی هاوبەشکردن لە ناو شیتەکە
    await t.tap(find.byKey(const ValueKey('ff-share-switch')));
    await settle(t, 10);
    expect(FamilyStore.I.share['food'], false);
    await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 400)));
    final back = await t.runAsync(() => FFLocalBackend().pull(FriendFood.I.myUid));
    expect(back!.kind, 1);
    await finish(t);
  });
}
