import 'package:cloud_firestore/cloud_firestore.dart';

/// ユーザーのリーダーボード統計
class LeaderboardEntry {
  final String userId;
  final String userName;
  final int rank;
  final int totalScore;
  final int examsCompleted;
  final double averageAccuracy;
  final int streak;
  final DateTime lastUpdated;

  const LeaderboardEntry({
    required this.userId,
    required this.userName,
    required this.rank,
    required this.totalScore,
    required this.examsCompleted,
    required this.averageAccuracy,
    required this.streak,
    required this.lastUpdated,
  });

  /// JSON からのデシリアライズ
  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      userId: json['userId'] as String? ?? '',
      userName: json['userName'] as String? ?? 'Unknown',
      rank: json['rank'] as int? ?? 0,
      totalScore: json['totalScore'] as int? ?? 0,
      examsCompleted: json['examsCompleted'] as int? ?? 0,
      averageAccuracy: (json['averageAccuracy'] as num?)?.toDouble() ?? 0.0,
      streak: json['streak'] as int? ?? 0,
      lastUpdated: json['lastUpdated'] is Timestamp
          ? (json['lastUpdated'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  /// JSON へのシリアライズ
  Map<String, dynamic> toJson() => {
    'userId': userId,
    'userName': userName,
    'rank': rank,
    'totalScore': totalScore,
    'examsCompleted': examsCompleted,
    'averageAccuracy': averageAccuracy,
    'streak': streak,
    'lastUpdated': Timestamp.fromDate(lastUpdated),
  };
}

/// リーダーボード期間
enum LeaderboardPeriod {
  daily,    // 日次
  weekly,   // 週次
  monthly,  // 月次
  allTime,  // 全期間
}

/// リーダーボード統計
class LeaderboardStats {
  final LeaderboardPeriod period;
  final List<LeaderboardEntry> topEntries;
  final LeaderboardEntry? currentUserEntry;
  final DateTime generatedAt;

  const LeaderboardStats({
    required this.period,
    required this.topEntries,
    this.currentUserEntry,
    required this.generatedAt,
  });

  /// 上位10件を取得
  List<LeaderboardEntry> get top10 => topEntries.take(10).toList();

  /// ユーザーが上位10に入っているか
  bool get isUserInTop10 => currentUserEntry != null && currentUserEntry!.rank <= 10;
}

/// ユーザースコア履歴
class UserScoreHistory {
  final String userId;
  final int score;
  final int examsCompleted;
  final double averageAccuracy;
  final DateTime recordedAt;

  const UserScoreHistory({
    required this.userId,
    required this.score,
    required this.examsCompleted,
    required this.averageAccuracy,
    required this.recordedAt,
  });

  /// JSON からのデシリアライズ
  factory UserScoreHistory.fromJson(Map<String, dynamic> json) {
    return UserScoreHistory(
      userId: json['userId'] as String? ?? '',
      score: json['score'] as int? ?? 0,
      examsCompleted: json['examsCompleted'] as int? ?? 0,
      averageAccuracy: (json['averageAccuracy'] as num?)?.toDouble() ?? 0.0,
      recordedAt: json['recordedAt'] is Timestamp
          ? (json['recordedAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  /// JSON へのシリアライズ
  Map<String, dynamic> toJson() => {
    'userId': userId,
    'score': score,
    'examsCompleted': examsCompleted,
    'averageAccuracy': averageAccuracy,
    'recordedAt': Timestamp.fromDate(recordedAt),
  };
}
