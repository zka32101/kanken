import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/index.dart';
import '../services/index.dart';
import '../providers/firebase_provider.dart' show currentUserIdProvider;
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
