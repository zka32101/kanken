import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/index.dart';
import '../services/index.dart';
import '../providers/firebase_provider.dart' show currentUserIdProvider;
import '../providers/gamification_provider.dart' show currentGamificationNotifierProvider;
import 'services_provider.dart';

export '../providers/firebase_provider.dart' show currentUserIdProvider;

/// 現在アクティブな学習者プロフィールID（兄弟等での使い分け用）。
/// 1つのFirebase Authアカウント(uid)の下に複数のプロフィールを持てる。
/// アプリ起動直後はプロフィール未選択(null)で、activeProfilesProviderが
/// 解決した時点でホーム画面側が適切な初期値をセットする。
final activeProfileIdProvider = StateProvider<String?>((ref) => null);

/// (uid, profileId) の組でユーザー情報を取得するProvider
final userProvider = FutureProvider.family<User?,
    ({String uid, String profileId})>((ref, key) async {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return await firestoreService.getUser(key.uid, profileId: key.profileId);
});

/// uid配下の全プロフィール一覧
final userProfilesProvider = FutureProvider.family<List<User>, String>((ref, uid) async {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return await firestoreService.getUserProfiles(uid);
});

// 現在のユーザー（アクティブなプロフィール）情報
final currentUserProvider = FutureProvider<User?>((ref) async {
  final uid = ref.watch(currentUserIdProvider);
  if (uid == null) return null;

  final profileId = ref.watch(activeProfileIdProvider) ?? 'default';
  return ref.watch(userProvider((uid: uid, profileId: profileId))).when(
        data: (user) => user,
        loading: () => null,
        error: (err, stack) => null,
      );
});

// ストリーク継続状態
final streakCountProvider = FutureProvider<int>((ref) async {
  final user = await ref.watch(currentUserProvider.future);
  return user?.streakCount ?? 0;
});

/// 現在のユーザー・プロフィールが「覚えた」チェック済みの問題ID一覧
/// （questionsコレクションのドキュメントID、例:"LEVEL_9-毎"）
final learnedKanjiIdsProvider = FutureProvider<Set<String>>((ref) async {
  final uid = ref.watch(currentUserIdProvider);
  if (uid == null) return {};

  final user = await ref.watch(currentUserProvider.future);
  final firestoreService = ref.watch(firestoreServiceProvider);
  final learned = await firestoreService.getUserLearnedKanjis(
    uid,
    profileId: user?.profileId ?? 'default',
  );
  return learned.toSet();
});

// 現在の受験級
final currentLevelProvider = StateProvider<String>((ref) => 'LEVEL_10');

/// 受験予定日を登録・変更する（nullを渡すと削除）
Future<void> updateExamDate(WidgetRef ref, DateTime? examDate) async {
  final uid = ref.read(currentUserIdProvider);
  if (uid == null) return;

  final user = await ref.read(currentUserProvider.future);
  if (user == null) return;

  final firestoreService = ref.read(firestoreServiceProvider);
  await firestoreService.updateUser(
    user.copyWith(examDate: examDate, clearExamDate: examDate == null),
  );

  ref.invalidate(currentUserProvider);
  ref.invalidate(userProvider((uid: uid, profileId: user.profileId)));
}

/// 演習・模擬試験を1問以上完了したタイミングで呼び出し、
/// 連続学習日数(streakCount)を更新する。
/// - 最終学習日が「今日」なら何もしない（1日に何度学習してもカウントは1日分）
/// - 最終学習日が「昨日」ならstreakCountを+1
/// - それ以外（一昨日以前・記録なし）ならstreakCountを1にリセット
Future<int?> _computeAndPersistStreak(
  User user,
  FirestoreService firestoreService,
) async {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final last = user.lastStudyDate;
  final lastDay = last != null ? DateTime(last.year, last.month, last.day) : null;

  if (lastDay != null && lastDay == today) {
    return null; // 本日は記録済み、変更なし
  }

  final int newStreak;
  if (lastDay != null && today.difference(lastDay).inDays == 1) {
    newStreak = user.streakCount + 1;
  } else {
    newStreak = 1;
  }

  await firestoreService.updateUser(
    user.copyWith(streakCount: newStreak, lastStudyDate: today),
  );

  return newStreak;
}

/// 画面(ConsumerState/WidgetRef)側から呼び出す版
Future<void> recordStudyActivity(WidgetRef ref) async {
  final uid = ref.read(currentUserIdProvider);
  if (uid == null) return;

  final user = await ref.read(currentUserProvider.future);
  if (user == null) return;

  final firestoreService = ref.read(firestoreServiceProvider);
  final newStreak = await _computeAndPersistStreak(user, firestoreService);
  if (newStreak == null) return;

  ref.invalidate(currentUserProvider);
  ref.invalidate(userProvider((uid: uid, profileId: user.profileId)));

  try {
    await ref.read(currentGamificationNotifierProvider.notifier).updateStreak(newStreak);
  } catch (_) {}
  await checkAndAwardStreakBadges(ref, newStreak).catchError((_) => <String>[]);
}

/// StateNotifier内(Ref)側から呼び出す版
Future<void> recordStudyActivityWithRef(Ref ref) async {
  final uid = ref.read(currentUserIdProvider);
  if (uid == null) return;

  final user = await ref.read(currentUserProvider.future);
  if (user == null) return;

  final firestoreService = ref.read(firestoreServiceProvider);
  final newStreak = await _computeAndPersistStreak(user, firestoreService);
  if (newStreak == null) return;

  ref.invalidate(currentUserProvider);
  ref.invalidate(userProvider((uid: uid, profileId: user.profileId)));

  try {
    await ref.read(currentGamificationNotifierProvider.notifier).updateStreak(newStreak);
  } catch (_) {}
  await checkAndAwardStreakBadges(ref, newStreak).catchError((_) => <String>[]);
}
