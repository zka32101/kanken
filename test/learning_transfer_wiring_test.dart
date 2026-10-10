import 'package:ukalab_core/ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanken/services/learning_transfer_service.dart';
import 'package:kanken/services/oshi_progress_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 学習の引き継ぎ（app_common_kit）と漢検アプリの連携テスト。
/// 旧端末で保存 → 新端末（空）で復元、を端末内の保存先ごと再現する。
CoinService _coin(DateTime t) => CoinService(store: InMemoryCoinStore(), clock: () => t);

LearningTransfer _transfer(CoinService coin, OutfitService outfit, TransferRemote remote) =>
    buildKankenTransfer(uid: 'u1', coin: coin, outfit: outfit, remote: remote);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('旧端末で保存し、新端末で復元すると、コイン・衣装・推しの成長が引き継がれる', () async {
    final remote = InMemoryTransferRemote();

    // 旧端末
    final oldCoin = _coin(DateTime(2026, 10, 1));
    await oldCoin.grant(CoinEvent.newQuestion('q1'));
    await oldCoin.grant(CoinEvent.newQuestion('q2'));
    final oldOutfit = OutfitService(store: InMemoryOutfitStore());
    await oldOutfit.reportPassed(UkalabCert.kanjiKentei);
    await OshiProgressStore.markAnswered(profileId: 'p1', level: 'LEVEL_10', questionId: 'q1');
    await OshiProgressStore.markAnswered(profileId: 'p1', level: 'LEVEL_10', questionId: 'q2');

    final backup = await _transfer(oldCoin, oldOutfit, remote).backup();
    expect(backup.status, TransferStatus.success);
    expect(backup.succeeded, ['coin', 'outfit', 'oshi_progress']);

    // 新端末（端末内の保存は空）
    SharedPreferences.setMockInitialValues({});
    final newCoin = _coin(DateTime(2026, 10, 9));
    final newOutfit = OutfitService(store: InMemoryOutfitStore());
    expect(await OshiProgressStore.answeredCount(profileId: 'p1', level: 'LEVEL_10'), 0);

    final restore = await _transfer(newCoin, newOutfit, remote).restore();

    expect(restore.status, TransferStatus.success);
    expect(newCoin.balance, oldCoin.balance);
    expect(newOutfit.passedCerts, {UkalabCert.kanjiKentei.id});
    expect(await OshiProgressStore.answeredCount(profileId: 'p1', level: 'LEVEL_10'), 2);
  });

  test('復元は統合: 新端末で先に解いた分も消えず、何度復元しても二重にならない', () async {
    final remote = InMemoryTransferRemote();
    final oldCoin = _coin(DateTime(2026, 10, 1));
    await oldCoin.grant(CoinEvent.newQuestion('q1'));
    await OshiProgressStore.markAnswered(profileId: 'p1', level: 'LEVEL_9', questionId: 'a');
    await _transfer(oldCoin, OutfitService(store: InMemoryOutfitStore()), remote).backup();

    SharedPreferences.setMockInitialValues({});
    final newCoin = _coin(DateTime(2026, 10, 9));
    await newCoin.grant(CoinEvent.newQuestion('q2'));
    await OshiProgressStore.markAnswered(profileId: 'p1', level: 'LEVEL_9', questionId: 'b');
    final transfer = _transfer(newCoin, OutfitService(store: InMemoryOutfitStore()), remote);
    await transfer.restore();
    await transfer.restore();

    expect(newCoin.ledger.entries.length, 2);
    expect(await OshiProgressStore.answeredCount(profileId: 'p1', level: 'LEVEL_9'), 2);
  });

  test('推しの成長の部品は、oshi_answered_ 以外の保存データを運ばない', () async {
    SharedPreferences.setMockInitialValues({
      'oshi_answered_p1_LEVEL_10': ['q1'],
      'oshi_total_LEVEL_10': 80,
      'handwriting_strictness': 'strict',
    });

    final exported = await OshiProgressTransferSource().export() as Map;

    expect(exported.keys, ['oshi_answered_p1_LEVEL_10']);
  });

  test('バックアップが一度も無いと「保存されたデータはまだありません」', () async {
    final result = await _transfer(
      _coin(DateTime(2026, 10, 9)),
      OutfitService(store: InMemoryOutfitStore()),
      InMemoryTransferRemote(),
    ).restore();

    expect(result.nothingToRestore, isTrue);
    expect(transferResultMessage(result, restore: true), '保存されたデータはまだありません');
  });

  test('結果の文言', () {
    const ok = TransferResult(status: TransferStatus.success, succeeded: ['coin']);
    const partial = TransferResult(status: TransferStatus.partial, succeeded: ['coin'], failed: ['outfit']);
    const failed = TransferResult(status: TransferStatus.failed, failed: ['coin']);

    expect(transferResultMessage(ok, restore: false), 'バックアップしました');
    expect(transferResultMessage(ok, restore: true), '引き継ぎました');
    expect(transferResultMessage(partial, restore: true), contains('一部だけ'));
    expect(transferResultMessage(failed, restore: false), contains('通信を確認'));
  });

  test('保存先のパスは共通ルールの users/{uid}/exams/{examId}/… に収まる', () {
    expect(
      FirebaseTransferRemote.docPath('u1', kankenTransferExamId, 'coin'),
      'users/u1/exams/kanji_kentei/transfer/coin',
    );
    expect(kankenTransferExamId, UkalabCert.kanjiKentei.id);
  });
}
