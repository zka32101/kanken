import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/leaderboard.dart';
import '../models/achievement.dart';
import '../models/notifications.dart';
import '../services/firestore_service.dart';
import '../viewmodels/user_viewmodel.dart' as user_vm;

/// 日次リーダーボードプロバイダー
final dailyLeaderboardProvider = FutureProvider<LeaderboardStats>((ref) async {
  return _fetchLeaderboard(ref, LeaderboardPeriod.daily);
});

/// 週次リーダーボードプロバイダー
final weeklyLeaderboardProvider = FutureProvider<LeaderboardStats>((ref) async {
  return _fetchLeaderboard(ref, LeaderboardPeriod.weekly);
});

/// 月次リーダーボードプロバイダー
final monthlyLeaderboardProvider = FutureProvider<LeaderboardStats>((ref) async {
  return _fetchLeaderboard(ref, LeaderboardPeriod.monthly);
});

/// 全期間リーダーボードプロバイダー
final allTimeLeaderboardProvider = FutureProvider<LeaderboardStats>((ref) async {
  return _fetchLeaderboard(ref, LeaderboardPeriod.allTime);
});

/// ユーザーの現在のリーダーボード順位プロバイダー
final userLeaderboardRankProvider = FutureProvider.family<int?, LeaderboardPeriod>((ref, period) async {
  final userId = FirebaseAuth.instance.currentUser?.uid;
  if (userId == null) return null;

  try {
    final leaderboard = await _fetchLeaderboard(ref, period);
    return leaderboard.currentUserEntry?.rank;
  } catch (e) {
    return null;
  }
});

/// リーダーボード取得のコア処理
/// リーダーボードのドキュメントIDはプロフィール単位で分けるため
/// FirestoreService.rankingDocId(uid, profileId) の複合IDを使う。
Future<LeaderboardStats> _fetchLeaderboard(Ref ref, LeaderboardPeriod period) async {
  final userId = FirebaseAuth.instance.currentUser?.uid;
  final profileId = ref.watch(
    user_vm.currentUserProvider.select((async) => async.value?.profileId ?? 'default'),
  );

  try {
    final db = FirebaseFirestore.instance;

    // スコアコレクションから上位ユーザーを取得
    final query = db.collection('leaderboard').doc(period.toString()).collection('scores');
    final snapshot = await query
        .orderBy('totalScore', descending: true)
        .limit(100)
        .get();

    final entries = <LeaderboardEntry>[];
    var rank = 1;

    for (final doc in snapshot.docs) {
      final entry = LeaderboardEntry.fromJson(doc.data());
      entries.add(entry.copyWith(rank: rank));
      rank++;
    }

    // 現在のユーザー（プロフィール）の順位を取得
    LeaderboardEntry? currentUserEntry;
    if (userId != null) {
      final docId = FirestoreService.rankingDocId(userId, profileId);
      final userScoreDoc = await db
          .collection('leaderboard')
          .doc(period.toString())
          .collection('scores')
          .doc(docId)
          .get();

      if (userScoreDoc.exists) {
        final userData = userScoreDoc.data()!;
        final userRank = await _getUserRank(docId, period);
        currentUserEntry = LeaderboardEntry.fromJson(userData).copyWith(rank: userRank ?? 0);

        if (period == LeaderboardPeriod.allTime && userRank != null && userRank > 0) {
          await _checkLeaderboardRankAchievement(userId, profileId, userRank);
        }
      }
    }

    return LeaderboardStats(
      period: period,
      topEntries: entries,
      currentUserEntry: currentUserEntry,
      generatedAt: DateTime.now(),
    );
  } catch (e) {
    return LeaderboardStats(
      period: period,
      topEntries: [],
      currentUserEntry: null,
      generatedAt: DateTime.now(),
    );
  }
}

/// ユーザー（プロフィール）の順位を取得
Future<int?> _getUserRank(String docId, LeaderboardPeriod period) async {
  try {
    final db = FirebaseFirestore.instance;
    final query = db.collection('leaderboard').doc(period.toString()).collection('scores');

    // ユーザーのスコアを取得
    final userDoc = await query.doc(docId).get();
    if (!userDoc.exists) return null;

    final userScore = (userDoc.data()?['totalScore'] as num?)?.toInt() ?? 0;

    // より高いスコアを持つユーザー数をカウント
    final snapshot = await query
        .where('totalScore', isGreaterThan: userScore)
        .count()
        .get();

    return (snapshot.count ?? 0) + 1;
  } catch (e) {
    return null;
  }
}

/// ユーザースコアを更新
Future<void> updateUserScore(
  WidgetRef ref, {
  required int score,
  required int examsCompleted,
  required double averageAccuracy,
}) async {
  final userId = FirebaseAuth.instance.currentUser?.uid;
  if (userId == null) return;

  try {
    final db = FirebaseFirestore.instance;
    final user = await ref.read(user_vm.currentUserProvider.future);
    final profileId = user?.profileId ?? 'default';

    // ランキング参加設定(rankingOptIn)がオフのプロフィールはリーダーボードに載せない
    if (!(user?.rankingOptIn ?? false)) return;

    final docId = FirestoreService.rankingDocId(userId, profileId);
    final batch = db.batch();

    // 複数の期間（日次、週次、月次、全期間）に対してスコアを更新
    for (final period in LeaderboardPeriod.values) {
      final docRef = db
          .collection('leaderboard')
          .doc(period.toString())
          .collection('scores')
          .doc(docId);

      // 既存のスコアを取得
      final existingDoc = await docRef.get();
      int previousScore = 0;

      if (existingDoc.exists) {
        previousScore = (existingDoc.data()?['totalScore'] as num?)?.toInt() ?? 0;
      }

      final newScore = previousScore + score;

      batch.set(
        docRef,
        {
          'userId': userId,
          'profileId': profileId,
          'totalScore': newScore,
          'examsCompleted': examsCompleted,
          'averageAccuracy': averageAccuracy,
          'lastUpdated': Timestamp.now(),
        },
        SetOptions(merge: true),
      );
    }

    // スコア履歴を記録（プロフィール単位）
    await db
        .collection('users')
        .doc(userId)
        .collection('profiles')
        .doc(profileId)
        .collection('scoreHistory')
        .add({
      'userId': userId,
      'profileId': profileId,
      'score': score,
      'examsCompleted': examsCompleted,
      'averageAccuracy': averageAccuracy,
      'recordedAt': Timestamp.now(),
    });

    await batch.commit();
  } catch (e) {
    // エラーログなど必要に応じて処理
  }
}

const _leaderboardRankAchievements = {
  10: ('social_leaderboard_top10', 'トップランカー', 'リーダーボードでTOP10入り', '📈', 150),
  3: ('social_leaderboard_top3', 'エリート', 'リーダーボードでTOP3入り', '🥇', 300),
};

/// リーダーボード順位に応じたバッジ達成をチェック
Future<void> _checkLeaderboardRankAchievement(
  String userId,
  String profileId,
  int rank,
) async {
  try {
    final profileRef = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('profiles')
        .doc(profileId);

    for (final entry in _leaderboardRankAchievements.entries) {
      final threshold = entry.key;
      final info = entry.value;
      if (rank > threshold) continue;

      final achievementsRef = profileRef.collection('achievements');
      final achievementDoc = await achievementsRef.doc(info.$1).get();

      if (achievementDoc.exists && (achievementDoc.data()?['isUnlocked'] == true)) {
        continue;
      }

      final achievement = Achievement(
        id: info.$1,
        name: info.$2,
        description: info.$3,
        icon: info.$4,
        type: AchievementType.social,
        points: info.$5,
        isUnlocked: true,
        unlockedAt: DateTime.now(),
      );

      await achievementsRef.doc(info.$1).set(achievement.toJson(), SetOptions(merge: true));

      final notificationsRef = profileRef.collection('notifications');
      final notificationId = notificationsRef.doc().id;
      await notificationsRef.doc(notificationId).set(
            AppNotification(
              notificationId: notificationId,
              userId: userId,
              type: NotificationType.achievement.value,
              title: '🎉 新しいバッジを獲得！',
              message: '「${info.$2}」バッジを獲得しました！',
              relatedId: info.$1,
              isRead: false,
              createdAt: DateTime.now(),
            ).toJson(),
          );
    }
  } catch (e) {
    // エラーログなど必要に応じて処理
  }
}

/// LeaderboardEntry拡張メソッド
extension LeaderboardEntryExt on LeaderboardEntry {
  LeaderboardEntry copyWith({
    String? userId,
    String? userName,
    int? rank,
    int? totalScore,
    int? examsCompleted,
    double? averageAccuracy,
    int? streak,
    DateTime? lastUpdated,
  }) {
    return LeaderboardEntry(
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      rank: rank ?? this.rank,
      totalScore: totalScore ?? this.totalScore,
      examsCompleted: examsCompleted ?? this.examsCompleted,
      averageAccuracy: averageAccuracy ?? this.averageAccuracy,
      streak: streak ?? this.streak,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}
