import 'package:cloud_firestore/cloud_firestore.dart';

/// 試験問題
class ExamQuestion {
  final String questionId;
  final String kanji;
  final String questionType; // reading/meaning/stroke/writing
  final String question;
  final List<String> options;
  final String correctAnswer;
  final String explanation;
  final int level; // 10-2級

  const ExamQuestion({
    required this.questionId,
    required this.kanji,
    required this.questionType,
    required this.question,
    required this.options,
    required this.correctAnswer,
    required this.explanation,
    required this.level,
  });

  /// JSON からのデシリアライズ
  factory ExamQuestion.fromJson(Map<String, dynamic> json) {
    return ExamQuestion(
      questionId: json['questionId'] as String? ?? '',
      kanji: json['kanji'] as String? ?? '',
      questionType: json['questionType'] as String? ?? 'reading',
      question: json['question'] as String? ?? '',
      options: List<String>.from(json['options'] as List? ?? []),
      correctAnswer: json['correctAnswer'] as String? ?? '',
      explanation: json['explanation'] as String? ?? '',
      level: json['level'] as int? ?? 10,
    );
  }

  /// JSON へのシリアライズ
  Map<String, dynamic> toJson() => {
    'questionId': questionId,
    'kanji': kanji,
    'questionType': questionType,
    'question': question,
    'options': options,
    'correctAnswer': correctAnswer,
    'explanation': explanation,
    'level': level,
  };
}

/// ユーザーの回答
class UserAnswer {
  final int questionIndex;
  final String selectedAnswer;
  final bool isCorrect;
  final int timeSpent; // 秒単位

  const UserAnswer({
    required this.questionIndex,
    required this.selectedAnswer,
    required this.isCorrect,
    required this.timeSpent,
  });

  factory UserAnswer.fromJson(Map<String, dynamic> json) {
    return UserAnswer(
      questionIndex: json['questionIndex'] as int? ?? 0,
      selectedAnswer: json['selectedAnswer'] as String? ?? '',
      isCorrect: json['isCorrect'] as bool? ?? false,
      timeSpent: json['timeSpent'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'questionIndex': questionIndex,
    'selectedAnswer': selectedAnswer,
    'isCorrect': isCorrect,
    'timeSpent': timeSpent,
  };
}

/// 試験結果
class ExamResult {
  final String resultId;
  final String userId;
  final String examSessionId;
  final int examLevel; // 受験した級
  final int totalQuestions;
  final int correctAnswers;
  final double accuracyRate;
  final int totalTimeSeconds;
  final List<UserAnswer> answers;
  final DateTime completedAt;
  final bool isPassed; // 合格判定（通常は60%以上）
  final int estimatedRank; // 順位推定
  final Map<String, dynamic> categoryScores; // 分野別スコア

  const ExamResult({
    required this.resultId,
    required this.userId,
    required this.examSessionId,
    required this.examLevel,
    required this.totalQuestions,
    required this.correctAnswers,
    required this.accuracyRate,
    required this.totalTimeSeconds,
    required this.answers,
    required this.completedAt,
    required this.isPassed,
    required this.estimatedRank,
    required this.categoryScores,
  });

  /// 得点計算（満点200点想定）
  int calculateScore() {
    return (accuracyRate * 200).toInt();
  }

  /// 合格判定
  bool getPassStatus() {
    return accuracyRate >= 0.6;
  }

  /// 平均回答時間
  double getAverageTimePerQuestion() {
    if (totalQuestions == 0) return 0;
    return totalTimeSeconds / totalQuestions;
  }

  /// JSON からのデシリアライズ
  factory ExamResult.fromJson(Map<String, dynamic> json) {
    final answersData = json['answers'] as List? ?? [];
    final answers = answersData
        .map((a) => UserAnswer.fromJson(a as Map<String, dynamic>))
        .toList();

    return ExamResult(
      resultId: json['resultId'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      examSessionId: json['examSessionId'] as String? ?? '',
      examLevel: json['examLevel'] as int? ?? 10,
      totalQuestions: json['totalQuestions'] as int? ?? 0,
      correctAnswers: json['correctAnswers'] as int? ?? 0,
      accuracyRate: (json['accuracyRate'] as num?)?.toDouble() ?? 0.0,
      totalTimeSeconds: json['totalTimeSeconds'] as int? ?? 0,
      answers: answers,
      completedAt: json['completedAt'] is Timestamp
          ? (json['completedAt'] as Timestamp).toDate()
          : DateTime.now(),
      isPassed: json['isPassed'] as bool? ?? false,
      estimatedRank: json['estimatedRank'] as int? ?? 0,
      categoryScores: json['categoryScores'] as Map<String, dynamic>? ?? {},
    );
  }

  /// JSON へのシリアライズ
  Map<String, dynamic> toJson() => {
    'resultId': resultId,
    'userId': userId,
    'examSessionId': examSessionId,
    'examLevel': examLevel,
    'totalQuestions': totalQuestions,
    'correctAnswers': correctAnswers,
    'accuracyRate': accuracyRate,
    'totalTimeSeconds': totalTimeSeconds,
    'answers': answers.map((a) => a.toJson()).toList(),
    'completedAt': Timestamp.fromDate(completedAt),
    'isPassed': isPassed,
    'estimatedRank': estimatedRank,
    'categoryScores': categoryScores,
  };
}

/// 試験セッション（進行中の試験）
class ExamSession {
  final String sessionId;
  final String userId;
  final int examLevel;
  final List<ExamQuestion> questions;
  final int currentQuestionIndex;
  final List<UserAnswer> userAnswers;
  final DateTime startedAt;
  final int totalTimeSeconds; // 制限時間
  final int elapsedSeconds; // 経過時間
  final bool isCompleted;

  const ExamSession({
    required this.sessionId,
    required this.userId,
    required this.examLevel,
    required this.questions,
    required this.currentQuestionIndex,
    required this.userAnswers,
    required this.startedAt,
    required this.totalTimeSeconds,
    required this.elapsedSeconds,
    required this.isCompleted,
  });

  /// 現在の問題を取得
  ExamQuestion? getCurrentQuestion() {
    if (currentQuestionIndex < questions.length) {
      return questions[currentQuestionIndex];
    }
    return null;
  }

  /// 進捗パーセンテージ
  double getProgressPercentage() {
    if (questions.isEmpty) return 0;
    return currentQuestionIndex / questions.length;
  }

  /// 残り時間（秒）
  int getRemainingTime() {
    return (totalTimeSeconds - elapsedSeconds).clamp(0, totalTimeSeconds);
  }

  /// 時間切れ判定
  bool isTimeUp() {
    return elapsedSeconds >= totalTimeSeconds;
  }

  factory ExamSession.fromJson(Map<String, dynamic> json) {
    final questionsData = json['questions'] as List? ?? [];
    final questions = questionsData
        .map((q) => ExamQuestion.fromJson(q as Map<String, dynamic>))
        .toList();

    final answersData = json['userAnswers'] as List? ?? [];
    final userAnswers = answersData
        .map((a) => UserAnswer.fromJson(a as Map<String, dynamic>))
        .toList();

    return ExamSession(
      sessionId: json['sessionId'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      examLevel: json['examLevel'] as int? ?? 10,
      questions: questions,
      currentQuestionIndex: json['currentQuestionIndex'] as int? ?? 0,
      userAnswers: userAnswers,
      startedAt: json['startedAt'] is Timestamp
          ? (json['startedAt'] as Timestamp).toDate()
          : DateTime.now(),
      totalTimeSeconds: json['totalTimeSeconds'] as int? ?? 1800,
      elapsedSeconds: json['elapsedSeconds'] as int? ?? 0,
      isCompleted: json['isCompleted'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'sessionId': sessionId,
    'userId': userId,
    'examLevel': examLevel,
    'questions': questions.map((q) => q.toJson()).toList(),
    'currentQuestionIndex': currentQuestionIndex,
    'userAnswers': userAnswers.map((a) => a.toJson()).toList(),
    'startedAt': Timestamp.fromDate(startedAt),
    'totalTimeSeconds': totalTimeSeconds,
    'elapsedSeconds': elapsedSeconds,
    'isCompleted': isCompleted,
  };
}

/// 試験統計情報
class ExamStatistics {
  final String userId;
  final int totalExamsTaken;
  final int totalPassed;
  final double averageAccuracy;
  final int bestScore;
  final int worstScore;
  final Map<int, Map<String, dynamic>> levelStatistics; // 級別の統計

  const ExamStatistics({
    required this.userId,
    required this.totalExamsTaken,
    required this.totalPassed,
    required this.averageAccuracy,
    required this.bestScore,
    required this.worstScore,
    required this.levelStatistics,
  });

  /// 合格率
  double getPassRate() {
    if (totalExamsTaken == 0) return 0;
    return totalPassed / totalExamsTaken;
  }

  /// 級別平均スコア
  int getAverageScoreForLevel(int level) {
    final stats = levelStatistics[level.toString()];
    if (stats == null) return 0;
    return (stats['averageScore'] as num?)?.toInt() ?? 0;
  }

  factory ExamStatistics.fromJson(Map<String, dynamic> json) {
    return ExamStatistics(
      userId: json['userId'] as String? ?? '',
      totalExamsTaken: json['totalExamsTaken'] as int? ?? 0,
      totalPassed: json['totalPassed'] as int? ?? 0,
      averageAccuracy: (json['averageAccuracy'] as num?)?.toDouble() ?? 0.0,
      bestScore: json['bestScore'] as int? ?? 0,
      worstScore: json['worstScore'] as int? ?? 0,
      levelStatistics:
          json['levelStatistics'] as Map<int, Map<String, dynamic>>? ?? {},
    );
  }

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'totalExamsTaken': totalExamsTaken,
    'totalPassed': totalPassed,
    'averageAccuracy': averageAccuracy,
    'bestScore': bestScore,
    'worstScore': worstScore,
    'levelStatistics': levelStatistics,
  };
}
