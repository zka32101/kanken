import 'package:app_common_kit/app_common_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanken/providers/oshi_provider.dart';
import 'package:kanken/screens/oshi_room_screen.dart';
import 'package:kanken/viewmodels/user_viewmodel.dart';
import 'package:kanken/widgets/oshi_card.dart';

void main() {
  test('場面のポーズ: 試験前日は応援・3日以上の連続は炎・それ以外は通常', () {
    final now = DateTime(2026, 10, 9);
    expect(oshiRoomSceneFor(examDate: DateTime(2026, 10, 10), streakDays: 0, now: now), MascotScene.eve);
    expect(oshiRoomSceneFor(examDate: null, streakDays: 3, now: now), MascotScene.streak);
    expect(oshiRoomSceneFor(examDate: null, streakDays: 2, now: now), isNull);
  });

  testWidgets('推しカードの「推しの部屋」から、部屋が開き、横長/縦長を切り替えられる', (tester) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final c = ProviderContainer(overrides: [
      coinServiceProvider.overrideWithValue(CoinService(store: InMemoryCoinStore(), shop: const [])),
      outfitServiceProvider.overrideWithValue(OutfitService(store: InMemoryOutfitStore())),
      oshiStageProvider.overrideWith((ref) async => MascotStage.lv3),
      currentUserProvider.overrideWith((ref) async => null),
    ]);
    addTearDown(c.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: c,
      child: const MaterialApp(home: Scaffold(body: OshiCard())),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    await tester.tap(find.text('推しの部屋'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));

    final room = find.byType(UkalabOshiRoom);
    expect(room, findsOneWidget);
    expect(tester.widget<UkalabOshiRoom>(room).portrait, isFalse);
    expect(tester.widget<UkalabOshiRoom>(room).room, UkalabRoom.language);
    expect(tester.widget<UkalabOshiRoom>(room).stage, MascotStage.lv3);

    await tester.tap(find.text('縦長'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(tester.widget<UkalabOshiRoom>(find.byType(UkalabOshiRoom)).portrait, isTrue);
  });
}
