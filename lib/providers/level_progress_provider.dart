import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/index.dart';
import '../viewmodels/index.dart';

/// 現在のプロフィールの級ごとの正答率集計（home_screen・practice画面の
/// 進捗バー／次の級までのカウントダウン表示に使う）。
final levelProgressProvider = FutureProvider<Map<String, LevelProgress>>((ref) async {
  final uid = ref.watch(currentUserIdProvider);
  if (uid == null) return {};

  final user = await ref.watch(currentUserProvider.future);
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.getLevelStats(uid, profileId: user?.profileId ?? 'default');
});

/// 指定した級の進捗（データが無ければ空の進捗を返す）
LevelProgress levelProgressFor(Map<String, LevelProgress> stats, String level) {
  return stats[level] ?? LevelProgress(level: level, correctCount: 0, totalCount: 0);
}
