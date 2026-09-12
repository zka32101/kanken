import 'package:cloud_firestore/cloud_firestore.dart';

/// 学習推奨の優先度
enum RecommendationPriority {
  critical,  // 緊急（<30%）
  high,      // 高（30-50%）
  medium,    // 中（50-70%）
  low,       // 低（>70%）
}

/// 推奨難易度
enum DifficultyLevel {
  basic,    // 基礎
  standard, // 標準
  advanced, // 応用
}

/// 学習推奨
class LearningRecommendation {
  final String recommendationId;
  final String userId;
  final String targetCategoryId;
  final String targetCategoryName;
  final RecommendationPriority priority;
  final DifficultyLevel difficulty;
  final String reason;                    // 推奨理由（日本語）
  final int recommendedDailyQuestions;    // 推奨日次出題数
  final int estimatedDaysToImprove;       // 改善予想日数
  final DateTime createdAt;
  final DateTime? completedAt;
  final bool isCompleted;
  final double? progressAccuracy;         // 進捗中の正答率

  const LearningRecommendation({
    required this.recommendationId,
    required this.userId,
    required this.targetCategoryId,
    required this.targetCategoryName,
    required this.priority,
    required this.difficulty,
    required this.reason,
    required this.recommendedDailyQuestions,
    required this.estimatedDaysToImprove,
    required this.createdAt,
    this.completedAt,
    this.isCompleted = false,
    this.progressAccuracy,
  });

  /// 優先度ラベル
  String getPriorityLabel() {
    switch (priority) {
      case RecommendationPriority.critical:
        return '🔴 緊急';
      case RecommendationPriority.high:
        return '🟠 高';
      case RecommendationPriority.medium:
        return '🟡 中';
      case RecommendationPriority.low:
        return '🟢 低';
    }
  }

  /// 難易度ラベル
  String getDifficultyLabel() {
    switch (difficulty) {
      case DifficultyLevel.basic:
        return '基礎';
      case DifficultyLevel.standard:
        return '標準';
      case DifficultyLevel.advanced:
        return '応用';
    }
  }

  /// 進捗率（0-100）
  int getProgressPercentage() {
    if (estimatedDaysToImprove <= 0) return 0;

    if (completedAt != null) return 100;

    final daysElapsed = DateTime.now().difference(createdAt).inDays;
    return ((daysElapsed / estimatedDaysToImprove) * 100).toInt().clamp(0, 100);
  }

  /// 学習完了可否判定
  bool get canMarkAsCompleted {
    return progressAccuracy != null && progressAccuracy! >= 0.75;
  }

  /// 推奨実施期間（何日以内に実施すべきか）
  int getUrgencyDays() {
    switch (priority) {
      case RecommendationPriority.critical:
        return 1;   // 今日
      case RecommendationPriority.high:
        return 3;   // 3日以内
      case RecommendationPriority.medium:
        return 7;   // 1週間以内
      case RecommendationPriority.low:
        return 14;  // 2週間以内
    }
  }

  /// JSON からのデシリアライズ
  factory LearningRecommendation.fromJson(Map<String, dynamic> json) {
    return LearningRecommendation(
      recommendationId: json['recommendationId'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      targetCategoryId: json['targetCategoryId'] as String? ?? '',
      targetCategoryName: json['targetCategoryName'] as String? ?? '',
      priority: _priorityFromString(json['priority'] as String? ?? 'medium'),
      difficulty: _difficultyFromString(json['difficulty'] as String? ?? 'standard'),
      reason: json['reason'] as String? ?? '',
      recommendedDailyQuestions: json['recommendedDailyQuestions'] as int? ?? 10,
      estimatedDaysToImprove: json['estimatedDaysToImprove'] as int? ?? 7,
      createdAt: json['createdAt'] is Timestamp
          ? (json['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      completedAt: json['completedAt'] is Timestamp
          ? (json['completedAt'] as Timestamp).toDate()
          : null,
      isCompleted: json['isCompleted'] as bool? ?? false,
      progressAccuracy: (json['progressAccuracy'] as num?)?.toDouble(),
    );
  }

  /// JSON へのシリアライズ
  Map<String, dynamic> toJson() => {
    'recommendationId': recommendationId,
    'userId': userId,
    'targetCategoryId': targetCategoryId,
    'targetCategoryName': targetCategoryName,
    'priority': _priorityToString(priority),
    'difficulty': _difficultyToString(difficulty),
    'reason': reason,
    'recommendedDailyQuestions': recommendedDailyQuestions,
    'estimatedDaysToImprove': estimatedDaysToImprove,
    'createdAt': Timestamp.fromDate(createdAt),
    'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
    'isCompleted': isCompleted,
    'progressAccuracy': progressAccuracy,
  };

  @override
  String toString() =>
      'LearningRecommendation(category: $targetCategoryName, priority: ${getPriorityLabel()}, progress: ${getProgressPercentage()}%)';
}

/// 優先度を文字列に変換
String _priorityToString(RecommendationPriority priority) {
  switch (priority) {
    case RecommendationPriority.critical:
      return 'critical';
    case RecommendationPriority.high:
      return 'high';
    case RecommendationPriority.medium:
      return 'medium';
    case RecommendationPriority.low:
      return 'low';
  }
}

/// 文字列から優先度に変換
RecommendationPriority _priorityFromString(String priority) {
  switch (priority) {
    case 'critical':
      return RecommendationPriority.critical;
    case 'high':
      return RecommendationPriority.high;
    case 'low':
      return RecommendationPriority.low;
    default:
      return RecommendationPriority.medium;
  }
}

/// 難易度を文字列に変換
String _difficultyToString(DifficultyLevel difficulty) {
  switch (difficulty) {
    case DifficultyLevel.basic:
      return 'basic';
    case DifficultyLevel.standard:
      return 'standard';
    case DifficultyLevel.advanced:
      return 'advanced';
  }
}

/// 文字列から難易度に変換
DifficultyLevel _difficultyFromString(String difficulty) {
  switch (difficulty) {
    case 'basic':
      return DifficultyLevel.basic;
    case 'advanced':
      return DifficultyLevel.advanced;
    default:
      return DifficultyLevel.standard;
  }
}

/// 学習推奨プラン
class LearningPlan {
  final List<LearningRecommendation> recommendations;
  final DateTime generatedAt;
  final int totalEstimatedDays;
  final int totalDailyQuestions;

  LearningPlan({
    required this.recommendations,
    required this.generatedAt,
  })  : totalEstimatedDays = recommendations.isNotEmpty
            ? recommendations
                .map((r) => r.estimatedDaysToImprove)
                .reduce((a, b) => a > b ? a : b)
            : 0,
        totalDailyQuestions = recommendations.fold(
          0,
          (sum, r) => sum + r.recommendedDailyQuestions,
        );

  /// 優先度別の分類
  Map<RecommendationPriority, List<LearningRecommendation>>
      getGroupedByPriority() {
    final grouped = <RecommendationPriority, List<LearningRecommendation>>{};
    for (final rec in recommendations) {
      grouped.putIfAbsent(rec.priority, () => []).add(rec);
    }
    return grouped;
  }

  /// 完了状況
  int get completedCount => recommendations.where((r) => r.isCompleted).length;
  double get completionPercentage =>
      recommendations.isEmpty ? 0.0 : (completedCount / recommendations.length);

  @override
  String toString() =>
      'LearningPlan(${recommendations.length} items, ${totalEstimatedDays} days, $totalDailyQuestions daily)';
}
