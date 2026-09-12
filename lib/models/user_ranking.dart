import 'package:cloud_firestore/cloud_firestore.dart';

/// ユーザーランキング情報
class UserRanking {
  final String userId;
  final String userName;
  final int rank;
  final int level;
  final int experience;
  final int coins;
  final double accuracyRate;
  final int streak;
  final DateTime lastPlayedAt;

  const UserRanking({
    required this.userId,
    required this.userName,
    required this.rank,
    required this.level,
    required this.experience,
    required this.coins,
    required this.accuracyRate,
    required this.streak,
    required this.lastPlayedAt,
  });

  /// ランクバッジ取得
  String getRankBadge() {
    switch (rank) {
      case 1:
        return '🥇';
      case 2:
        return '🥈';
      case 3:
        return '🥉';
      default:
        return '${rank}位';
    }
  }

  /// ランク表示テキスト
  String getRankLabel() {
    switch (rank) {
      case 1:
        return '1位 (金)';
      case 2:
        return '2位 (銀)';
      case 3:
        return '3位 (銅)';
      default:
        return '$rank位';
    }
  }

  /// JSON からのデシリアライズ
  factory UserRanking.fromJson(Map<String, dynamic> json) {
    return UserRanking(
      userId: json['userId'] as String? ?? '',
      userName: json['userName'] as String? ?? 'Unknown',
      rank: json['rank'] as int? ?? 0,
      level: json['level'] as int? ?? 1,
      experience: json['experience'] as int? ?? 0,
      coins: json['coins'] as int? ?? 0,
      accuracyRate: (json['accuracyRate'] as num?)?.toDouble() ?? 0.0,
      streak: json['streak'] as int? ?? 0,
      lastPlayedAt: json['lastPlayedAt'] is Timestamp
          ? (json['lastPlayedAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  /// JSON へのシリアライズ
  Map<String, dynamic> toJson() => {
    'userId': userId,
    'userName': userName,
    'rank': rank,
    'level': level,
    'experience': experience,
    'coins': coins,
    'accuracyRate': accuracyRate,
    'streak': streak,
    'lastPlayedAt': Timestamp.fromDate(lastPlayedAt),
  };

  /// ランキング比較用
  @override
  String toString() =>
      'UserRanking(rank: $rank, userId: $userId, exp: $experience, level: $level)';
}

/// ランキングタイプ
enum RankingType {
  level,           // レベル順
  experience,      // 経験値順
  accuracy,        // 正答率順
  streak,          // ストリーク順
  coins,           // コイン順
}

/// ランキングフィルター
class RankingFilter {
  final RankingType type;
  final RankingPeriod period;
  final int limit;

  const RankingFilter({
    this.type = RankingType.level,
    this.period = RankingPeriod.allTime,
    this.limit = 100,
  });
}

/// ランキング期間
enum RankingPeriod {
  weekly,   // 週間
  monthly,  // 月間
  allTime,  // 全期間
}
