import 'package:cloud_firestore/cloud_firestore.dart';

/// 子どもの学習統計（保護者向け）
class ChildLearningStats {
  final String childId;
  final String childName;
  final int currentLevel;
  final int totalQuestions;
  final int correctAnswers;
  final double accuracyRate;
  final int streakDays;
  final int longestStreak;
  final int totalLearningMinutes;
  final DateTime lastLearningAt;
  final int badgesAcquired;
  final int totalBadges;

  const ChildLearningStats({
    required this.childId,
    required this.childName,
    required this.currentLevel,
    required this.totalQuestions,
    required this.correctAnswers,
    required this.accuracyRate,
    required this.streakDays,
    required this.longestStreak,
    required this.totalLearningMinutes,
    required this.lastLearningAt,
    required this.badgesAcquired,
    required this.totalBadges,
  });

  /// 正答率パーセンテージ
  String getAccuracyPercentage() {
    return '${(accuracyRate * 100).toStringAsFixed(1)}%';
  }

  /// バッジ取得率
  String getBadgeAcquisitionRate() {
    if (totalBadges == 0) return '0%';
    return '${((badgesAcquired / totalBadges) * 100).toStringAsFixed(1)}%';
  }

  /// 学習状態判定
  bool isActiveLearner() => streakDays >= 3;

  /// 最後の学習からの経過日数
  int getDaysSinceLastLearning() {
    return DateTime.now().difference(lastLearningAt).inDays;
  }

  /// JSON からのデシリアライズ
  factory ChildLearningStats.fromJson(Map<String, dynamic> json) {
    return ChildLearningStats(
      childId: json['childId'] as String? ?? '',
      childName: json['childName'] as String? ?? '',
      currentLevel: json['currentLevel'] as int? ?? 10,
      totalQuestions: json['totalQuestions'] as int? ?? 0,
      correctAnswers: json['correctAnswers'] as int? ?? 0,
      accuracyRate: (json['accuracyRate'] as num?)?.toDouble() ?? 0,
      streakDays: json['streakDays'] as int? ?? 0,
      longestStreak: json['longestStreak'] as int? ?? 0,
      totalLearningMinutes: json['totalLearningMinutes'] as int? ?? 0,
      lastLearningAt: json['lastLearningAt'] is Timestamp
          ? (json['lastLearningAt'] as Timestamp).toDate()
          : DateTime.now(),
      badgesAcquired: json['badgesAcquired'] as int? ?? 0,
      totalBadges: json['totalBadges'] as int? ?? 0,
    );
  }

  /// JSON へのシリアライズ
  Map<String, dynamic> toJson() => {
    'childId': childId,
    'childName': childName,
    'currentLevel': currentLevel,
    'totalQuestions': totalQuestions,
    'correctAnswers': correctAnswers,
    'accuracyRate': accuracyRate,
    'streakDays': streakDays,
    'longestStreak': longestStreak,
    'totalLearningMinutes': totalLearningMinutes,
    'lastLearningAt': Timestamp.fromDate(lastLearningAt),
    'badgesAcquired': badgesAcquired,
    'totalBadges': totalBadges,
  };

  @override
  String toString() =>
      'ChildLearningStats(childName: $childName, accuracyRate: ${getAccuracyPercentage()}, streakDays: $streakDays)';
}

/// 学習グラフのデータポイント
class LearningDataPoint {
  final DateTime date;
  final int questionsAnswered;
  final int correctAnswers;
  final double accuracyRate;

  const LearningDataPoint({
    required this.date,
    required this.questionsAnswered,
    required this.correctAnswers,
    required this.accuracyRate,
  });

  /// JSON からのデシリアライズ
  factory LearningDataPoint.fromJson(Map<String, dynamic> json) {
    return LearningDataPoint(
      date: json['date'] is Timestamp
          ? (json['date'] as Timestamp).toDate()
          : DateTime.now(),
      questionsAnswered: json['questionsAnswered'] as int? ?? 0,
      correctAnswers: json['correctAnswers'] as int? ?? 0,
      accuracyRate: (json['accuracyRate'] as num?)?.toDouble() ?? 0,
    );
  }

  /// JSON へのシリアライズ
  Map<String, dynamic> toJson() => {
    'date': Timestamp.fromDate(date),
    'questionsAnswered': questionsAnswered,
    'correctAnswers': correctAnswers,
    'accuracyRate': accuracyRate,
  };
}

/// 弱点分野情報（保護者向け）
class ChildWeakArea {
  final String categoryId;
  final String categoryName;
  final int totalAttempts;
  final int correctAnswers;
  final double accuracyRate;
  final String level;  // excellent/good/normal/weak/veryWeak
  final DateTime lastAttemptAt;

  const ChildWeakArea({
    required this.categoryId,
    required this.categoryName,
    required this.totalAttempts,
    required this.correctAnswers,
    required this.accuracyRate,
    required this.level,
    required this.lastAttemptAt,
  });

  /// 改善が必要か判定
  bool needsImprovement() => level == 'weak' || level == 'veryWeak';

  /// レベルラベル（日本語）
  String getLevelLabel() {
    switch (level) {
      case 'excellent':
        return '優秀';
      case 'good':
        return '良好';
      case 'normal':
        return '普通';
      case 'weak':
        return '要改善';
      case 'veryWeak':
        return '要強化';
      default:
        return '不明';
    }
  }

  /// JSON からのデシリアライズ
  factory ChildWeakArea.fromJson(Map<String, dynamic> json) {
    return ChildWeakArea(
      categoryId: json['categoryId'] as String? ?? '',
      categoryName: json['categoryName'] as String? ?? '',
      totalAttempts: json['totalAttempts'] as int? ?? 0,
      correctAnswers: json['correctAnswers'] as int? ?? 0,
      accuracyRate: (json['accuracyRate'] as num?)?.toDouble() ?? 0,
      level: json['level'] as String? ?? 'normal',
      lastAttemptAt: json['lastAttemptAt'] is Timestamp
          ? (json['lastAttemptAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  /// JSON へのシリアライズ
  Map<String, dynamic> toJson() => {
    'categoryId': categoryId,
    'categoryName': categoryName,
    'totalAttempts': totalAttempts,
    'correctAnswers': correctAnswers,
    'accuracyRate': accuracyRate,
    'level': level,
    'lastAttemptAt': Timestamp.fromDate(lastAttemptAt),
  };
}

/// 保護者ダッシュボード統計
class ParentDashboardStats {
  final String parentId;
  final List<ChildLearningStats> childrenStats;
  final Map<String, List<LearningDataPoint>> learningGraphData;
  final Map<String, List<ChildWeakArea>> weakAreas;

  const ParentDashboardStats({
    required this.parentId,
    required this.childrenStats,
    required this.learningGraphData,
    required this.weakAreas,
  });

  /// 子どもの数
  int getChildrenCount() => childrenStats.length;

  /// 平均正答率
  double getAverageAccuracyRate() {
    if (childrenStats.isEmpty) return 0;
    final total =
        childrenStats.fold(0.0, (sum, child) => sum + child.accuracyRate);
    return total / childrenStats.length;
  }

  /// 改善が必要な分野の数
  int getWeakAreasCount() {
    int count = 0;
    for (var areas in weakAreas.values) {
      count += areas.where((a) => a.needsImprovement()).length;
    }
    return count;
  }

  /// 全員のストリークの合計
  int getTotalStreakDays() {
    return childrenStats.fold(0, (sum, child) => sum + child.streakDays);
  }
}
