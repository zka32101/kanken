import 'package:cloud_firestore/cloud_firestore.dart';

/// ユーザーのゲーミフィケーション統計
class GamificationStats {
  final String userId;
  final int level;
  final int experience;
  final int coins;
  final int totalQuestions;
  final int correctCount;
  final int streak;
  final int recordStreak;
  final double accuracyRate;
  final DateTime lastPlayedAt;
  final DateTime createdAt;

  const GamificationStats({
    required this.userId,
    required this.level,
    required this.experience,
    required this.coins,
    required this.totalQuestions,
    required this.correctCount,
    required this.streak,
    required this.recordStreak,
    required this.accuracyRate,
    required this.lastPlayedAt,
    required this.createdAt,
  });

  /// ユーザーランク判定
  String getRank() {
    if (experience < 500) return '新米受験生';
    if (experience < 1000) return '見習い学生';
    if (experience < 2000) return '中堅学生';
    if (experience < 5000) return '精鋭受験生';
    return 'マスター';
  }

  /// 次のレベルまでの経験値
  int get expToNextLevel {
    final nextThreshold = (level * 500);
    return (nextThreshold - experience).clamp(0, nextThreshold);
  }

  /// 次のレベルまでの進捗 (0.0-1.0)
  double get expProgress {
    final currentThreshold = ((level - 1) * 500).clamp(0, double.infinity).toInt();
    final nextThreshold = (level * 500);
    if (nextThreshold <= currentThreshold) return 0.0;
    return ((experience - currentThreshold) / (nextThreshold - currentThreshold)).clamp(0.0, 1.0);
  }

  /// JSON からのデシリアライズ
  factory GamificationStats.fromJson(Map<String, dynamic> json) {
    return GamificationStats(
      userId: json['userId'] as String? ?? '',
      level: json['level'] as int? ?? 1,
      experience: json['experience'] as int? ?? 0,
      coins: json['coins'] as int? ?? 0,
      totalQuestions: json['totalQuestions'] as int? ?? 0,
      correctCount: json['correctCount'] as int? ?? 0,
      streak: json['streak'] as int? ?? 0,
      recordStreak: json['recordStreak'] as int? ?? 0,
      accuracyRate: (json['accuracyRate'] as num?)?.toDouble() ?? 0.0,
      lastPlayedAt: json['lastPlayedAt'] is Timestamp
          ? (json['lastPlayedAt'] as Timestamp).toDate()
          : DateTime.now(),
      createdAt: json['createdAt'] is Timestamp
          ? (json['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  /// JSON へのシリアライズ
  Map<String, dynamic> toJson() => {
    'userId': userId,
    'level': level,
    'experience': experience,
    'coins': coins,
    'totalQuestions': totalQuestions,
    'correctCount': correctCount,
    'streak': streak,
    'recordStreak': recordStreak,
    'accuracyRate': accuracyRate,
    'lastPlayedAt': Timestamp.fromDate(lastPlayedAt),
    'createdAt': Timestamp.fromDate(createdAt),
  };

  /// コピーメソッド（状態更新用）
  GamificationStats copyWith({
    int? level,
    int? experience,
    int? coins,
    int? totalQuestions,
    int? correctCount,
    int? streak,
    int? recordStreak,
    double? accuracyRate,
    DateTime? lastPlayedAt,
  }) {
    return GamificationStats(
      userId: userId,
      level: level ?? this.level,
      experience: experience ?? this.experience,
      coins: coins ?? this.coins,
      totalQuestions: totalQuestions ?? this.totalQuestions,
      correctCount: correctCount ?? this.correctCount,
      streak: streak ?? this.streak,
      recordStreak: recordStreak ?? this.recordStreak,
      accuracyRate: accuracyRate ?? this.accuracyRate,
      lastPlayedAt: lastPlayedAt ?? this.lastPlayedAt,
      createdAt: createdAt,
    );
  }

  @override
  String toString() => 'GamificationStats(userId: $userId, level: $level, exp: $experience/$expToNextLevel, rank: ${getRank()})';
}
