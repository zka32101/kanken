import 'package:cloud_firestore/cloud_firestore.dart';

/// 学習分析データ
class LearningAnalytics {
  final String userId;
  final int totalStudyMinutes;
  final double averageAccuracy;
  final int totalQuestionsAttempted;
  final int correctAnswers;
  final int currentStreak;
  final int longestStreak;
  final DateTime lastStudyDate;
  final Map<String, int> categoryStats;

  const LearningAnalytics({
    required this.userId,
    required this.totalStudyMinutes,
    required this.averageAccuracy,
    required this.totalQuestionsAttempted,
    required this.correctAnswers,
    required this.currentStreak,
    required this.longestStreak,
    required this.lastStudyDate,
    required this.categoryStats,
  });

  double get accuracyPercentage => averageAccuracy * 100;

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'totalStudyMinutes': totalStudyMinutes,
    'averageAccuracy': averageAccuracy,
    'totalQuestionsAttempted': totalQuestionsAttempted,
    'correctAnswers': correctAnswers,
    'currentStreak': currentStreak,
    'longestStreak': longestStreak,
    'lastStudyDate': Timestamp.fromDate(lastStudyDate),
    'categoryStats': categoryStats,
  };

  factory LearningAnalytics.fromJson(Map<String, dynamic> json) =>
      LearningAnalytics(
        userId: json['userId'] as String,
        totalStudyMinutes: json['totalStudyMinutes'] as int? ?? 0,
        averageAccuracy: (json['averageAccuracy'] as num?)?.toDouble() ?? 0.0,
        totalQuestionsAttempted: json['totalQuestionsAttempted'] as int? ?? 0,
        correctAnswers: json['correctAnswers'] as int? ?? 0,
        currentStreak: json['currentStreak'] as int? ?? 0,
        longestStreak: json['longestStreak'] as int? ?? 0,
        lastStudyDate: json['lastStudyDate'] is Timestamp
            ? (json['lastStudyDate'] as Timestamp).toDate()
            : DateTime.now(),
        categoryStats: Map<String, int>.from(
          json['categoryStats'] as Map<String, dynamic>? ?? {},
        ),
      );
}

/// 成長データポイント
class GrowthData {
  final DateTime date;
  final double accuracy;
  final int correctCount;
  final int totalCount;
  final int studyMinutes;

  const GrowthData({
    required this.date,
    required this.accuracy,
    required this.correctCount,
    required this.totalCount,
    required this.studyMinutes,
  });

  Map<String, dynamic> toJson() => {
    'date': Timestamp.fromDate(date),
    'accuracy': accuracy,
    'correctCount': correctCount,
    'totalCount': totalCount,
    'studyMinutes': studyMinutes,
  };

  factory GrowthData.fromJson(Map<String, dynamic> json) => GrowthData(
    date: json['date'] is Timestamp
        ? (json['date'] as Timestamp).toDate()
        : DateTime.now(),
    accuracy: (json['accuracy'] as num?)?.toDouble() ?? 0.0,
    correctCount: json['correctCount'] as int? ?? 0,
    totalCount: json['totalCount'] as int? ?? 0,
    studyMinutes: json['studyMinutes'] as int? ?? 0,
  );
}

/// 学習トレンド
class LearningTrend {
  final String category;
  final List<double> trendData;
  final double averageTrend;
  final String trend; // 'up', 'down', 'stable'

  const LearningTrend({
    required this.category,
    required this.trendData,
    required this.averageTrend,
    required this.trend,
  });

  Map<String, dynamic> toJson() => {
    'category': category,
    'trendData': trendData,
    'averageTrend': averageTrend,
    'trend': trend,
  };

  factory LearningTrend.fromJson(Map<String, dynamic> json) {
    final trendList = (json['trendData'] as List<dynamic>?)
        ?.map((e) => (e as num).toDouble())
        .toList() ?? [];

    return LearningTrend(
      category: json['category'] as String,
      trendData: trendList,
      averageTrend: (json['averageTrend'] as num?)?.toDouble() ?? 0.0,
      trend: json['trend'] as String? ?? 'stable',
    );
  }
}

/// 学習目標
class LearningGoal {
  final String goalId;
  final String userId;
  final String type; // 'daily', 'weekly', 'monthly'
  final int targetValue;
  final int currentValue;
  final String goalType; // 'accuracy', 'questions', 'time'
  final DateTime deadline;
  final bool isCompleted;
  final DateTime createdAt;

  const LearningGoal({
    required this.goalId,
    required this.userId,
    required this.type,
    required this.targetValue,
    required this.currentValue,
    required this.goalType,
    required this.deadline,
    required this.isCompleted,
    required this.createdAt,
  });

  double get progress => currentValue / targetValue;
  bool get isAchieved => currentValue >= targetValue;

  LearningGoal copyWith({
    String? goalId,
    String? userId,
    String? type,
    int? targetValue,
    int? currentValue,
    String? goalType,
    DateTime? deadline,
    bool? isCompleted,
    DateTime? createdAt,
  }) {
    return LearningGoal(
      goalId: goalId ?? this.goalId,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      targetValue: targetValue ?? this.targetValue,
      currentValue: currentValue ?? this.currentValue,
      goalType: goalType ?? this.goalType,
      deadline: deadline ?? this.deadline,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'goalId': goalId,
    'userId': userId,
    'type': type,
    'targetValue': targetValue,
    'currentValue': currentValue,
    'goalType': goalType,
    'deadline': Timestamp.fromDate(deadline),
    'isCompleted': isCompleted,
    'createdAt': Timestamp.fromDate(createdAt),
  };

  factory LearningGoal.fromJson(Map<String, dynamic> json) => LearningGoal(
    goalId: json['goalId'] as String,
    userId: json['userId'] as String,
    type: json['type'] as String? ?? 'daily',
    targetValue: json['targetValue'] as int? ?? 0,
    currentValue: json['currentValue'] as int? ?? 0,
    goalType: json['goalType'] as String? ?? 'accuracy',
    deadline: json['deadline'] is Timestamp
        ? (json['deadline'] as Timestamp).toDate()
        : DateTime.now(),
    isCompleted: json['isCompleted'] as bool? ?? false,
    createdAt: json['createdAt'] is Timestamp
        ? (json['createdAt'] as Timestamp).toDate()
        : DateTime.now(),
  );
}

/// 学習効率
class StudyEfficiency {
  final String userId;
  final int minutesStudied;
  final int questionsCompleted;
  final double accuracyRate;
  final double efficiencyScore;
  final DateTime calculatedAt;

  const StudyEfficiency({
    required this.userId,
    required this.minutesStudied,
    required this.questionsCompleted,
    required this.accuracyRate,
    required this.efficiencyScore,
    required this.calculatedAt,
  });

  // 効率スコア: (正答数 / 分数) × 正答率
  double get questionsPerMinute =>
      minutesStudied > 0 ? questionsCompleted / minutesStudied : 0;

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'minutesStudied': minutesStudied,
    'questionsCompleted': questionsCompleted,
    'accuracyRate': accuracyRate,
    'efficiencyScore': efficiencyScore,
    'calculatedAt': Timestamp.fromDate(calculatedAt),
  };

  factory StudyEfficiency.fromJson(Map<String, dynamic> json) =>
      StudyEfficiency(
        userId: json['userId'] as String,
        minutesStudied: json['minutesStudied'] as int? ?? 0,
        questionsCompleted: json['questionsCompleted'] as int? ?? 0,
        accuracyRate: (json['accuracyRate'] as num?)?.toDouble() ?? 0.0,
        efficiencyScore: (json['efficiencyScore'] as num?)?.toDouble() ?? 0.0,
        calculatedAt: json['calculatedAt'] is Timestamp
            ? (json['calculatedAt'] as Timestamp).toDate()
            : DateTime.now(),
      );
}
