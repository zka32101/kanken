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

      // Firestoreクエリを構築。
      // users/{uid} 本体はメール等を含みうるため本人のみ読み書き可能。
      // ランキング表示には rankings/{uid}（全員読み取り可の公開ミラー）を使う。
      Query query = firestore.collection('rankings');

      // 期間フィルター（週間・月間の場合）
      if (filter.period != RankingPeriod.allTime) {
        query = query.where(
          'lastPlayedAt',
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

        final userRanking = UserRanking(
          userId: doc.id,
          userName: data['userName'] as String? ?? 'Unknown',
          rank: i + 1, // ランク（1位から順に）
          level: data['level'] as int? ?? 1,
          experience: data['experience'] as int? ?? 0,
          coins: data['coins'] as int? ?? 0,
          accuracyRate: (data['accuracyRate'] as num?)?.toDouble() ?? 0.0,
          streak: data['streak'] as int? ?? 0,
          lastPlayedAt: data['lastPlayedAt'] is Timestamp
              ? (data['lastPlayedAt'] as Timestamp).toDate()
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

      // 現在のユーザーの値を取得（公開ミラーの rankings/{uid} を参照）
      final userDoc = await firestore.collection('rankings').doc(currentUserId).get();
      if (!userDoc.exists) return null;

      final userData = userDoc.data() as Map<String, dynamic>;
      final userValue = _extractSortValue(userData, filter.type);

      // より高い値を持つユーザーをカウント
      Query query = firestore.collection('rankings');
      query = query.where(sortField, isGreaterThan: userValue);

      final snapshot = await query.count().get();
      return (snapshot.count ?? 0) + 1; // ランク（0インデックスなので+1）
    } catch (e) {
      return null;
    }
  },
);

/// ソート対象フィールドを返す（rankings/{uid} のフラットなフィールド名）
String _getSortField(RankingType type) {
  switch (type) {
    case RankingType.level:
      return 'level';
    case RankingType.experience:
      return 'experience';
    case RankingType.accuracy:
      return 'accuracyRate';
    case RankingType.streak:
      return 'streak';
    case RankingType.coins:
      return 'coins';
  }
}

/// ソート値を抽出
dynamic _extractSortValue(Map<String, dynamic> data, RankingType type) {
  switch (type) {
    case RankingType.level:
      return data['level'] ?? 0;
    case RankingType.experience:
      return data['experience'] ?? 0;
    case RankingType.accuracy:
      return (data['accuracyRate'] as num?)?.toDouble() ?? 0.0;
    case RankingType.streak:
      return data['streak'] ?? 0;
    case RankingType.coins:
      return data['coins'] ?? 0;
  }
}
