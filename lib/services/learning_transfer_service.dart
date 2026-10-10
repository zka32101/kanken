import 'package:ukalab_core/ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 学習の引き継ぎ（機種変更でコイン・衣装・推しの成長を復元する）の漢検アプリ側の組み立て。
///
/// 漢検の学習記録・実績・フレンドなどは Firestore（ログインのアカウント）に保存されているので、
/// 同じアカウントでログインすれば自動で引き継がれる。ここで運ぶのは、端末内にしか無いデータだけ。
///
/// - コイン台帳 / 衣装（合格記念・準備完了・着ている衣装）: app_common_kit の部品
/// - 推しの成長に使う「解いた問題ID」: [OshiProgressTransferSource]
const kankenTransferExamId = 'kanji_kentei';

/// 推しの成長（網羅率）に使う、端末内の「解いた問題ID」の部品。
/// 保存先は `oshi_answered_{profileId}_{level}`（[OshiProgressStore] と同じ）。
/// 復元は和集合で、端末内の分を消さず、何度実行しても同じ。
class OshiProgressTransferSource implements TransferSource {
  static const _prefix = 'oshi_answered_';

  @override
  String get partId => 'oshi_progress';

  @override
  Future<Object?> export() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      for (final key in prefs.getKeys())
        if (key.startsWith(_prefix)) key: prefs.getStringList(key) ?? const <String>[],
    };
  }

  @override
  Future<void> importMerged(Object? remote) async {
    if (remote is! Map) return;
    final prefs = await SharedPreferences.getInstance();
    for (final entry in remote.entries) {
      final key = entry.key;
      final value = entry.value;
      if (key is! String || !key.startsWith(_prefix) || value is! List) continue;
      final merged = <String>{
        ...(prefs.getStringList(key) ?? const <String>[]),
        ...value.whereType<String>(),
      }.toList()
        ..sort();
      await prefs.setStringList(key, merged);
    }
  }
}

/// 漢検アプリの学習の引き継ぎ。[remote] を省略すると Firestore（`uid` のアカウント）を使う。
LearningTransfer buildKankenTransfer({
  required String uid,
  required CoinService coin,
  required OutfitService outfit,
  TransferRemote? remote,
}) =>
    LearningTransfer(
      remote: remote ?? FirebaseTransferRemote(uid: uid, examId: kankenTransferExamId),
      sources: [
        CoinTransferSource(coin),
        OutfitTransferSource(outfit),
        OshiProgressTransferSource(),
      ],
    );

/// 結果を利用者向けの一文にする（設定画面の SnackBar 用）。
String transferResultMessage(TransferResult result, {required bool restore}) {
  final action = restore ? '引き継ぎ' : 'バックアップ';
  switch (result.status) {
    case TransferStatus.success:
      if (restore && result.nothingToRestore) return '保存されたデータはまだありません';
      return restore ? '引き継ぎました' : 'バックアップしました';
    case TransferStatus.partial:
      return '一部だけ$actionできました。もう一度お試しください';
    case TransferStatus.failed:
      return '$actionできませんでした。通信を確認して、もう一度お試しください';
  }
}
