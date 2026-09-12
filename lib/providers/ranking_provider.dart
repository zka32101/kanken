import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanken/models/user_ranking.dart';
import 'firebase_provider.dart';

/// ランキングデータプロバイダー
final rankingProvider = FutureProvider.family<List<UserRanking>, RankingFilter>(
  (ref, filter) async {
    final firestore = ref.watch(firebaseProvider);

    // 期間に応じた開始日時を取算
    final now = DateTime.now();
    final startDate = filter.period == RankingPeriod.weekly
        ? now.subtract(Duration(days: now.weekday))
        : filter.period == RankingPeriod.monthly
            ? DateTime(now.year, now.month, 1)
            : DateTime(2000, 1, 1); // 全期間

    try {
      // ソート対象フィールドを決定
      final sortField = _getSortField(filter.type);

      // Firestoreクエリを構築
      Query query = firestore.collection('users');

      // 期間フィルター（週間・月間の場合）
      if (filter.period != RankingPeriod.allTime) {
        query = query.where(
          'stats.lastPlayedAt',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
        );
      }

      // ソート実行
      query = query.orderBy(sortField, descending: true).limit(filter.limit);

      final snapshot = await query.get();

      // UserRanking に変換（ランク付け）
      final rankings = <UserRanking>[];
      for (int i = 0; i < snapshot.docs.length; i++) {
        final doc = snapshot.docs[i];
        final data = doc.data() as Map<String, dynamic>;

        // ユーザー情報と統計情報を結合
        final userRanking = UserRanking(
          userId: doc.id,
          userName: data['profile']?['name'] ?? 'Unknown',
          rank: i + 1, // ランク（1位から順に）
          level: data['stats']?['level'] ?? 1,
          experience: data['stats']?['experience'] ?? 0,
          coins: data['profile']?['coins'] ?? 0,
          accuracyRate: (data['stats']?['accuracyRate'] as num?)?.toDouble() ?? 0.0,
          streak: data['stats']?['streak'] ?? 0,
          lastPlayedAt: data['stats']?['lastPlayedAt'] is Timestamp
              ? (data['stats']['lastPlayedAt'] as Timestamp).toDate()
              : DateTime.now(),
        );

        rankings.add(userRanking);
      }

      return rankings;
    } catch (e) {
      throw Exception('ランキング取得エラー: $e');
    }
  },
);

/// ユーザーの順位を取得
final userRankProvider = FutureProvider.family<int?, RankingFilter>(
  (ref, filter) async {
    final currentUserId = ref.watch(currentUserIdProvider);

    if (currentUserId == null) return null;

    final firestore = ref.watch(firebaseProvider);

    try {
      final sortField = _getSortField(filter.type);

      // 現在のユーザーの値を取得
      final userDoc = await firestore.collection('users').doc(currentUserId).get();
      if (!userDoc.exists) return null;

      final userData = userDoc.data() as Map<String, dynamic>;
      final userValue = _extractSortValue(userData, filter.type);

      // より高い値を持つユーザーをカウント
      Query query = firestore.collection('users');
      query = query.where(sortField, isGreaterThan: userValue);

      final snapshot = await query.count().get();
      return snapshot.count + 1; // ランク（0インデックスなので+1）
    } catch (e) {
      return null;
    }
  },
);

/// ソート対象フィールドを返す
String _getSortField(RankingType type) {
  switch (type) {
    case RankingType.level:
      return 'stats.level';
    case RankingType.experience:
      return 'stats.experience';
    case RankingType.accuracy:
      return 'stats.accuracyRate';
    case RankingType.streak:
      return 'stats.streak';
    case RankingType.coins:
      return 'profile.coins';
  }
}

/// ソート値を抽出
dynamic _extractSortValue(Map<String, dynamic> data, RankingType type) {
  switch (type) {
    case RankingType.level:
      return data['stats']?['level'] ?? 0;
    case RankingType.experience:
      return data['stats']?['experience'] ?? 0;
    case RankingType.accuracy:
      return (data['stats']?['accuracyRate'] as num?)?.toDouble() ?? 0.0;
    case RankingType.streak:
      return data['stats']?['streak'] ?? 0;
    case RankingType.coins:
      return data['profile']?['coins'] ?? 0;
  }
}
