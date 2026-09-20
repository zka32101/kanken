import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/leaderboard.dart';
import '../models/achievement.dart';
import '../models/notifications.dart';

/// 日次リーダーボードプロバイダー
final dailyLeaderboardProvider = FutureProvider<LeaderboardStats>((ref) async {
  return _fetchLeaderboard(LeaderboardPeriod.daily);
});

/// 週次リーダーボードプロバイダー
final weeklyLeaderboardProvider = FutureProvider<LeaderboardStats>((ref) async {
  return _fetchLeaderboard(LeaderboardPeriod.weekly);
});

/// 月次リーダーボードプロバイダー
final monthlyLeaderboardProvider = FutureProvider<LeaderboardStats>((ref) async {
  return _fetchLeaderboard(LeaderboardPeriod.monthly);
});

/// 全期間リーダーボードプロバイダー
final allTimeLeaderboardProvider = FutureProvider<LeaderboardStats>((ref) async {
  return _fetchLeaderboard(LeaderboardPeriod.allTime);
});

/// ユーザーの現在のリーダーボード順位プロバイダー
final userLeaderboardRankProvider = FutureProvider.family<int?, LeaderboardPeriod>((ref, period) async {
  final userId = FirebaseAuth.instance.currentUser?.uid;
  if (userId == null) return null;

  try {
    final leaderboard = await _fetchLeaderboard(period);
    return leaderboard.currentUserEntry?.rank;
  } catch (e) {
    return null;
  }
});

/// リーダーボード取得のコア処理
Future<LeaderboardStats> _fetchLeaderboard(LeaderboardPeriod period) async {
  final userId = FirebaseAuth.instance.currentUser?.uid;

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

    // 現在のユーザーの順位を取得
    LeaderboardEntry? currentUserEntry;
    if (userId != null) {
      final userScoreDoc = await db
          .collection('leaderboard')
          .doc(period.toString())
          .collection('scores')
          .doc(userId)
          .get();

      if (userScoreDoc.exists) {
        final userData = userScoreDoc.data()!;
        final userRank = await _getUserRank(userId, period);
        currentUserEntry = LeaderboardEntry.fromJson(userData).copyWith(rank: userRank ?? 0);

        if (period == LeaderboardPeriod.allTime && userRank != null && userRank > 0) {
          await _checkLeaderboardRankAchievement(userId, userRank);
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

/// ユーザーの順位を取得
Future<int?> _getUserRank(String userId, LeaderboardPeriod period) async {
  try {
    final db = FirebaseFirestore.instance;
    final query = db.collection('leaderboard').doc(period.toString()).collection('scores');

    // ユーザーのスコアを取得
    final userDoc = await query.doc(userId).get();
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
Future<void> updateUserScore({
  required int score,
  required int examsCompleted,
  required double averageAccuracy,
}) async {
  final userId = FirebaseAuth.instance.currentUser?.uid;
  if (userId == null) return;

  try {
    final db = FirebaseFirestore.instance;
    final batch = db.batch();

    // 複数の期間（日次、週次、月次、全期間）に対してスコアを更新
    for (final period in LeaderboardPeriod.values) {
      final docRef = db
          .collection('leaderboard')
          .doc(period.toString())
          .collection('scores')
          .doc(userId);

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
          'totalScore': newScore,
          'examsCompleted': examsCompleted,
          'averageAccuracy': averageAccuracy,
          'lastUpdated': Timestamp.now(),
        },
        SetOptions(merge: true),
      );
    }

    // スコア履歴を記録
    await db.collection('users').doc(userId).collection('scoreHistory').add({
      'userId': userId,
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
Future<void> _checkLeaderboardRankAchievement(String userId, int rank) async {
  try {
    for (final entry in _leaderboardRankAchievements.entries) {
      final threshold = entry.key;
      final info = entry.value;
      if (rank > threshold) continue;

      final achievementDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('achievements')
          .doc(info.$1)
          .get();

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

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('achievements')
          .doc(info.$1)
          .set(achievement.toJson(), SetOptions(merge: true));

      final notificationId = FirebaseFirestore.instance.collection('users').doc().id;
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .doc(notificationId)
          .set(
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
