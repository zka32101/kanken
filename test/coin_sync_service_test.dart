import 'dart:async';

import 'package:app_common_kit/app_common_kit.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanken/services/coin_sync_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ProviderContainer container;
  late StreamController<String?> users;
  late InMemoryCoinRemote remote;
  late List<String> requestedUids;
  late CoinSyncService service;

  setUp(() {
    container = ProviderContainer(overrides: [
      coinServiceProvider.overrideWithValue(CoinService(store: InMemoryCoinStore())),
    ]);
    users = StreamController<String?>();
    remote = InMemoryCoinRemote();
    requestedUids = [];
    service = CoinSyncService(
      container: container,
      userChanges: users.stream,
      remoteFor: (uid) {
        requestedUids.add(uid);
        return remote;
      },
    )..start();
  });

  tearDown(() async {
    service.dispose();
    await users.close();
    container.dispose();
  });

  test('未ログインのあいだは同期しない', () async {
    expect(await service.syncNow(), isNull);
    expect(requestedUids, isEmpty);
  });

  test('サインインすると台帳がサーバーへ書き込まれる', () async {
    await container.read(coinProvider.notifier).grant(CoinEvent.newQuestion('q1'));
    users.add('u1');
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    expect(requestedUids, ['u1']);
    expect(await remote.readLedger(), isNotEmpty);
  });

  test('サーバーの台帳が端末に統合される（端末移行）', () async {
    final other = CoinService(store: InMemoryCoinStore());
    await other.load();
    await other.grant(CoinEvent.newQuestion('q9'));
    await remote.writeLedger(other.ledger.toJson());

    users.add('u1');
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    expect(container.read(coinProvider).balance, CoinRules.standard.newQuestion);
  });

  test('間隔内の再同期はスキップし、force なら実行する', () async {
    users.add('u1');
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
    expect(await service.syncNow(), isNull);
    expect(await service.syncNow(force: true), CoinSyncResult.synced);
  });

  test('リモートが例外でも握りつぶす', () async {
    final failing = CoinSyncService(
      container: container,
      userChanges: Stream.value('u2'),
      remoteFor: (_) => throw StateError('offline'),
    );
    failing.start();
    await Future<void>.delayed(Duration.zero);
    expect(await failing.syncNow(), isNull);
    failing.dispose();
  });
}
