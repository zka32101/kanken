import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/collection_badge.dart';
import '../viewmodels/user_viewmodel.dart' as user_vm;

/// users/{uid}/profiles/{profileId} 配下のドキュメント参照
DocumentReference<Map<String, dynamic>> _profileDoc(String uid, String profileId) {
  return FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .collection('profiles')
      .doc(profileId);
}

/// すべてのバッジ定義を取得
final allBadgesProvider = FutureProvider<List<CollectionBadge>>((ref) async {
  final snapshot = await FirebaseFirestore.instance
      .collection('badges')
      .orderBy('rarity')
      .orderBy('name')
      .get();

  return snapshot.docs
      .map((doc) => CollectionBadge.fromJson(doc.data()))
      .toList();
});

/// ユーザーのバッジ取得状況を取得（プロフィール単位）
final userBadgeProgressProvider = FutureProvider<List<UserBadgeProgress>>((ref) async {
  final userId = FirebaseAuth.instance.currentUser?.uid;
  if (userId == null) return [];

  final profileId = ref.watch(
    user_vm.currentUserProvider.select((async) => async.value?.profileId ?? 'default'),
  );

  final snapshot = await _profileDoc(userId, profileId)
      .collection('badgeProgress')
      .orderBy('lastUpdatedAt', descending: true)
      .get();

  return snapshot.docs
      .map((doc) => UserBadgeProgress.fromJson(doc.data()))
      .toList();
});

/// ユーザーの取得済みバッジを取得
final acquiredBadgesProvider = FutureProvider<List<CollectionBadge>>((ref) async {
  final progress = await ref.watch(userBadgeProgressProvider.future);
  final allBadgesList = await ref.watch(allBadgesProvider.future);

  final acquiredIds =
      progress.where((p) => p.isAcquired).map((p) => p.badgeId).toSet();

  return allBadgesList
      .where((badge) => acquiredIds.contains(badge.badgeId))
      .toList();
});

/// ユーザーのバッジコレクション統計を取得
final badgeCollectionStatsProvider = FutureProvider<BadgeCollectionStats>((ref) async {
  final allBadgesList = await ref.watch(allBadgesProvider.future);
  final progress = await ref.watch(userBadgeProgressProvider.future);

  final acquiredCount = progress.where((p) => p.isAcquired).length;
  final hiddenBadges = allBadgesList.where((b) => b.isHidden).length;
  final acquiredHiddenCount =
      progress.where((p) => p.isAcquired).where((p) {
    final badge = allBadgesList.firstWhere(
      (b) => b.badgeId == p.badgeId,
      orElse: () => throw Exception('Badge not found'),
    );
    return badge.isHidden;
  }).length;

  return BadgeCollectionStats(
    totalBadges: allBadgesList.length,
    acquiredCount: acquiredCount,
    hiddenBadges: hiddenBadges,
    acquiredHiddenCount: acquiredHiddenCount,
    allProgress: progress,
  );
});

/// バッジコレクション管理 State
class BadgeCollectionState {
  final bool isLoading;
  final String? error;

  BadgeCollectionState({
    this.isLoading = false,
    this.error,
  });

  BadgeCollectionState copyWith({
    bool? isLoading,
    String? error,
  }) {
    return BadgeCollectionState(
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

/// バッジコレクション管理 StateNotifier（プロフィール単位）
class BadgeCollectionNotifier extends StateNotifier<BadgeCollectionState> {
  BadgeCollectionNotifier(this._ref) : super(BadgeCollectionState());

  final Ref _ref;
  final _auth = FirebaseAuth.instance;

  Future<String> _currentProfileId() async {
    final user = await _ref.read(user_vm.currentUserProvider.future);
    return user?.profileId ?? 'default';
  }

  /// バッジを取得
  Future<void> acquireBadge({
    required String badgeId,
    required int rewardCoins,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final currentUser = _auth.currentUser;
      if (currentUser == null) throw Exception('ユーザーがログインしていません');

      final profileId = await _currentProfileId();
      final badgeProgressRef =
          _profileDoc(currentUser.uid, profileId).collection('badgeProgress');
      final progressId = badgeProgressRef.doc().id;

      // バッジの取得記録を保存
      await badgeProgressRef.doc(progressId).set({
        'progressId': progressId,
        'userId': currentUser.uid,
        'badgeId': badgeId,
        'currentCount': 0,
        'isAcquired': true,
        'acquiredAt': Timestamp.now(),
        'lastUpdatedAt': Timestamp.now(),
      });

      // ユーザーのコインを加算
      if (rewardCoins > 0) {
        await _profileDoc(currentUser.uid, profileId)
            .collection('wallet')
            .doc('balance')
            .set({'coins': FieldValue.increment(rewardCoins)}, SetOptions(merge: true));
      }

      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'バッジ取得に失敗しました: $e',
      );
    }
  }

  /// バッジ進捗を更新
  Future<void> updateBadgeProgress({
    required String userId,
    required String badgeId,
    required int newCount,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) throw Exception('ユーザーがログインしていません');

      final profileId = await _currentProfileId();
      final badgeProgressRef = _profileDoc(userId, profileId).collection('badgeProgress');

      // 既存の進捗を取得または作成
      final existingDocs =
          await badgeProgressRef.where('badgeId', isEqualTo: badgeId).get();

      if (existingDocs.docs.isEmpty) {
        // 新規作成
        final progressId = badgeProgressRef.doc().id;
        await badgeProgressRef.doc(progressId).set({
          'progressId': progressId,
          'userId': userId,
          'badgeId': badgeId,
          'currentCount': newCount,
          'isAcquired': false,
          'acquiredAt': null,
          'lastUpdatedAt': Timestamp.now(),
        });
      } else {
        // 既存を更新
        final docId = existingDocs.docs[0].id;
        await badgeProgressRef.doc(docId).update({
          'currentCount': newCount,
          'lastUpdatedAt': Timestamp.now(),
        });
      }
    } catch (e) {
      state = state.copyWith(
        error: 'バッジ進捗の更新に失敗しました: $e',
      );
    }
  }

  /// バッジをリセット
  Future<void> resetBadgeProgress({
    required String badgeId,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final currentUser = _auth.currentUser;
      if (currentUser == null) throw Exception('ユーザーがログインしていません');

      final profileId = await _currentProfileId();
      final docs = await _profileDoc(currentUser.uid, profileId)
          .collection('badgeProgress')
          .where('badgeId', isEqualTo: badgeId)
          .get();

      for (var doc in docs.docs) {
        await doc.reference.delete();
      }

      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'バッジリセットに失敗しました: $e',
      );
    }
  }
}

/// バッジコレクション管理プロバイダー
final badgeCollectionNotifierProvider = StateNotifierProvider<BadgeCollectionNotifier, BadgeCollectionState>((ref) {
  return BadgeCollectionNotifier(ref);
});
