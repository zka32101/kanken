import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/collection_badge.dart';

part 'collection_badge_provider.g.dart';

/// すべてのバッジ定義を取得
@riverpod
Future<List<CollectionBadge>> allBadges(AllBadgesRef ref) async {
  final snapshot = await FirebaseFirestore.instance
      .collection('badges')
      .orderBy('rarity')
      .orderBy('name')
      .get();

  return snapshot.docs
      .map((doc) => CollectionBadge.fromJson(doc.data()))
      .toList();
}

/// ユーザーのバッジ取得状況を取得
@riverpod
Future<List<UserBadgeProgress>> userBadgeProgress(
  UserBadgeProgressRef ref,
) async {
  final userId = FirebaseAuth.instance.currentUser?.uid;
  if (userId == null) return [];

  final snapshot = await FirebaseFirestore.instance
      .collection('users')
      .doc(userId)
      .collection('badgeProgress')
      .orderBy('lastUpdatedAt', descending: true)
      .get();

  return snapshot.docs
      .map((doc) => UserBadgeProgress.fromJson(doc.data()))
      .toList();
}

/// ユーザーの取得済みバッジを取得
@riverpod
Future<List<CollectionBadge>> acquiredBadges(AcquiredBadgesRef ref) async {
  final progress = await ref.watch(userBadgeProgressProvider.future);
  final allBadgesList = await ref.watch(allBadgesProvider.future);

  final acquiredIds =
      progress.where((p) => p.isAcquired).map((p) => p.badgeId).toSet();

  return allBadgesList
      .where((badge) => acquiredIds.contains(badge.badgeId))
      .toList();
}

/// ユーザーのバッジコレクション統計を取得
@riverpod
Future<BadgeCollectionStats> badgeCollectionStats(
  BadgeCollectionStatsRef ref,
) async {
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
}

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

/// バッジコレクション管理 StateNotifier
class BadgeCollectionNotifier extends StateNotifier<BadgeCollectionState> {
  BadgeCollectionNotifier() : super(BadgeCollectionState());

  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  /// バッジを取得
  Future<void> acquireBadge({
    required String badgeId,
    required int rewardCoins,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final currentUser = _auth.currentUser;
      if (currentUser == null) throw Exception('ユーザーがログインしていません');

      final progressId =
          _firestore.collection('users').doc(currentUser.uid).collection('badgeProgress').doc().id;

      // バッジの取得記録を保存
      await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('badgeProgress')
          .doc(progressId)
          .set({
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
        await _firestore
            .collection('users')
            .doc(currentUser.uid)
            .update({
          'coins': FieldValue.increment(rewardCoins),
        });
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

      // 既存の進捗を取得または作成
      final existingDocs = await _firestore
          .collection('users')
          .doc(userId)
          .collection('badgeProgress')
          .where('badgeId', isEqualTo: badgeId)
          .get();

      if (existingDocs.docs.isEmpty) {
        // 新規作成
        final progressId =
            _firestore.collection('users').doc(userId).collection('badgeProgress').doc().id;
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('badgeProgress')
            .doc(progressId)
            .set({
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
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('badgeProgress')
            .doc(docId)
            .update({
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

      final docs = await _firestore
          .collection('users')
          .doc(currentUser.uid)
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
@riverpod
BadgeCollectionNotifier badgeCollectionNotifier(
  BadgeCollectionNotifierRef ref,
) {
  return BadgeCollectionNotifier();
}
