import 'package:cloud_firestore/cloud_firestore.dart';

/// 学習目標の種類
enum GoalType {
  weeklyStudyMinutes,   // 週間学習時間
  dailyQuestions,       // 日次問題数
  accuracyRate,         // 正答率目標
  streakDays,           // 連続学習日数
  examScore,            // 試験スコア目標
}

/// 学習目標
class LearningGoal {
  final String goalId;
  final String userId;
  final GoalType type;
  final int targetValue;
  final int currentValue;
  final DateTime createdAt;
  final DateTime? deadline;
  final bool isActive;
  final bool isAchieved;
  final DateTime? achievedAt;

  const LearningGoal({
    required this.goalId,
    required this.userId,
    required this.type,
    required this.targetValue,
    this.currentValue = 0,
    required this.createdAt,
    this.deadline,
    this.isActive = true,
    this.isAchieved = false,
    this.achievedAt,
  });

  /// 目標達成率（0.0-1.0）
  double get progressRate =>
      targetValue > 0 ? (currentValue / targetValue).clamp(0.0, 1.0) : 0.0;

  /// 達成率パーセント表示
  int get progressPercentage => (progressRate * 100).toInt();

  /// 期限切れかどうか
  bool get isExpired => deadline != null && DateTime.now().isAfter(deadline!);

  /// 目標タイプの表示名
  String get typeLabel {
    switch (type) {
      case GoalType.weeklyStudyMinutes:
        return '週間学習時間';
      case GoalType.dailyQuestions:
        return '日次問題数';
      case GoalType.accuracyRate:
        return '正答率目標';
      case GoalType.streakDays:
        return '連続学習日数';
      case GoalType.examScore:
        return '試験スコア目標';
    }
  }

  /// 目標タイプのアイコン
  String get typeIcon {
    switch (type) {
      case GoalType.weeklyStudyMinutes:
        return '⏱️';
      case GoalType.dailyQuestions:
        return '📝';
      case GoalType.accuracyRate:
        return '🎯';
      case GoalType.streakDays:
        return '🔥';
      case GoalType.examScore:
        return '🏆';
    }
  }

  /// 目標値の表示単位
  String get unit {
    switch (type) {
      case GoalType.weeklyStudyMinutes:
        return '分';
      case GoalType.dailyQuestions:
        return '問';
      case GoalType.accuracyRate:
        return '%';
      case GoalType.streakDays:
        return '日';
      case GoalType.examScore:
        return '点';
    }
  }

  LearningGoal copyWith({
    String? goalId,
    String? userId,
    GoalType? type,
    int? targetValue,
    int? currentValue,
    DateTime? createdAt,
    DateTime? deadline,
    bool? isActive,
    bool? isAchieved,
    DateTime? achievedAt,
  }) {
    return LearningGoal(
      goalId: goalId ?? this.goalId,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      targetValue: targetValue ?? this.targetValue,
      currentValue: currentValue ?? this.currentValue,
      createdAt: createdAt ?? this.createdAt,
      deadline: deadline ?? this.deadline,
      isActive: isActive ?? this.isActive,
      isAchieved: isAchieved ?? this.isAchieved,
      achievedAt: achievedAt ?? this.achievedAt,
    );
  }

  /// JSON からのデシリアライズ
  factory LearningGoal.fromJson(Map<String, dynamic> json) {
    return LearningGoal(
      goalId: json['goalId'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      type: _typeFromString(json['type'] as String? ?? 'dailyQuestions'),
      targetValue: json['targetValue'] as int? ?? 0,
      currentValue: json['currentValue'] as int? ?? 0,
      createdAt: json['createdAt'] is Timestamp
          ? (json['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      deadline: json['deadline'] is Timestamp
          ? (json['deadline'] as Timestamp).toDate()
          : null,
      isActive: json['isActive'] as bool? ?? true,
      isAchieved: json['isAchieved'] as bool? ?? false,
      achievedAt: json['achievedAt'] is Timestamp
          ? (json['achievedAt'] as Timestamp).toDate()
          : null,
    );
  }

  /// JSON へのシリアライズ
  Map<String, dynamic> toJson() => {
    'goalId': goalId,
    'userId': userId,
    'type': _typeToString(type),
    'targetValue': targetValue,
    'currentValue': currentValue,
    'createdAt': Timestamp.fromDate(createdAt),
    'deadline': deadline != null ? Timestamp.fromDate(deadline!) : null,
    'isActive': isActive,
    'isAchieved': isAchieved,
    'achievedAt': achievedAt != null ? Timestamp.fromDate(achievedAt!) : null,
  };
}

String _typeToString(GoalType type) {
  switch (type) {
    case GoalType.weeklyStudyMinutes:
      return 'weeklyStudyMinutes';
    case GoalType.dailyQuestions:
      return 'dailyQuestions';
    case GoalType.accuracyRate:
      return 'accuracyRate';
    case GoalType.streakDays:
      return 'streakDays';
    case GoalType.examScore:
      return 'examScore';
  }
}

GoalType _typeFromString(String type) {
  switch (type) {
    case 'weeklyStudyMinutes':
      return GoalType.weeklyStudyMinutes;
    case 'accuracyRate':
      return GoalType.accuracyRate;
    case 'streakDays':
      return GoalType.streakDays;
    case 'examScore':
      return GoalType.examScore;
    default:
      return GoalType.dailyQuestions;
  }
}
