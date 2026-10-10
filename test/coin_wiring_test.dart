import 'package:ukalab_core/ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// 学習コイン（app_common_kit）の配線テスト。
/// アプリ側（main.dart）と同じく coinServiceProvider を上書きして使う。
void main() {
  ProviderContainer makeContainer() {
    final service = CoinService(store: InMemoryCoinStore());
    return ProviderContainer(
      overrides: [coinServiceProvider.overrideWithValue(service)],
    );
  }

  test('初めて解く問題でコインが付与され、同じ問題では二度付与されない', () async {
    final container = makeContainer();
    addTearDown(container.dispose);
    final notifier = container.read(coinProvider.notifier);

    final first = await notifier.grant(CoinEvent.newQuestion('q1'));
    expect(first, isNotNull);
    expect(first!.amount, CoinRules.standard.newQuestion);
    expect(container.read(coinProvider).balance, CoinRules.standard.newQuestion);

    final again = await notifier.grant(CoinEvent.newQuestion('q1'));
    expect(again, isNull);
    expect(container.read(coinProvider).balance, CoinRules.standard.newQuestion);
  });

  test('別の問題なら続けて付与される', () async {
    final container = makeContainer();
    addTearDown(container.dispose);
    final notifier = container.read(coinProvider.notifier);

    await notifier.grant(CoinEvent.newQuestion('q1'));
    await notifier.grant(CoinEvent.newQuestion('q2'));
    expect(container.read(coinProvider).balance, CoinRules.standard.newQuestion * 2);
  });

  test('coinServiceProvider が未設定なら読み出しで例外になる（呼び出し側は握りつぶす）', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    expect(() => container.read(coinProvider), throwsA(anything));
  });
}
