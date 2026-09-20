/// Mock exam modes and configurations
enum ExamMode {
  standardExam, // 標準試験（全問題）
  speedExam, // 速度試験（時間制限あり）
  focusedExam, // 集中試験（特定分野のみ）
  weakAreasExam, // 弱点対策試験
  randomExam, // ランダム試験
  progressiveExam, // 段階式試験（難易度段階的）
}

enum ExamDifficulty {
  easy, // 簡単
  medium, // 標準
  hard, // 難しい
  veryHard, // 非常に難しい
}

enum ExamCategory {
  reading, // 読み
  meaning, // 意味
  stroke, // 画数
  writing, // 書き
  usage, // 使い方
  mixed, // 混合
}

/// Mock exam configuration
class ExamConfig {
  final int questionCount; // 問題数
  final int timeLimit; // 時間制限（分）
  final ExamMode mode; // 試験モード
  final ExamDifficulty difficulty; // 難易度
  final List<ExamCategory> categories; // カテゴリ
  final int targetLevel; // 目標級
  final bool showExplanations; // 解説表示
  final bool allowReview; // 見直し可能
  final bool randomizeOrder; // 問題順序ランダム
  final int passThreshold; // 合格ライン（%）

  ExamConfig({
    required this.questionCount,
    required this.timeLimit,
    required this.mode,
    required this.difficulty,
    required this.categories,
    required this.targetLevel,
    this.showExplanations = true,
    this.allowReview = true,
    this.randomizeOrder = true,
    this.passThreshold = 60,
  });

  /// Standard 50-question exam (official format)
  factory ExamConfig.standard({int level = 3}) => ExamConfig(
    questionCount: 50,
    timeLimit: 120,
    mode: ExamMode.standardExam,
    difficulty: ExamDifficulty.medium,
    categories: ExamCategory.values,
    targetLevel: level,
  );

  /// Speed exam: 30 questions in 60 minutes
  factory ExamConfig.speed({int level = 3}) => ExamConfig(
    questionCount: 30,
    timeLimit: 60,
    mode: ExamMode.speedExam,
    difficulty: ExamDifficulty.medium,
    categories: ExamCategory.values,
    targetLevel: level,
  );

  /// Focused exam: 20 questions on specific category
  factory ExamConfig.focused({
    required ExamCategory category,
    int level = 3,
  }) => ExamConfig(
    questionCount: 20,
    timeLimit: 45,
    mode: ExamMode.focusedExam,
    difficulty: ExamDifficulty.medium,
    categories: [category],
    targetLevel: level,
  );

  /// Weak areas exam: Adaptive difficulty based on user performance
  factory ExamConfig.weakAreas({int level = 3}) => ExamConfig(
    questionCount: 30,
    timeLimit: 90,
    mode: ExamMode.weakAreasExam,
    difficulty: ExamDifficulty.hard,
    categories: ExamCategory.values,
    targetLevel: level,
  );

  /// Random exam: Mix of all question types
  factory ExamConfig.random({int level = 3}) => ExamConfig(
    questionCount: 40,
    timeLimit: 90,
    mode: ExamMode.randomExam,
    difficulty: ExamDifficulty.medium,
    categories: ExamCategory.values,
    targetLevel: level,
  );

  /// Progressive exam: Difficulty increases with correct answers
  factory ExamConfig.progressive({int level = 3}) => ExamConfig(
    questionCount: 60,
    timeLimit: 150,
    mode: ExamMode.progressiveExam,
    difficulty: ExamDifficulty.medium,
    categories: ExamCategory.values,
    targetLevel: level,
  );

  Map<String, dynamic> toJson() => {
    'questionCount': questionCount,
    'timeLimit': timeLimit,
    'mode': mode.toString(),
    'difficulty': difficulty.toString(),
    'categories': categories.map((c) => c.toString()).toList(),
    'targetLevel': targetLevel,
    'showExplanations': showExplanations,
    'allowReview': allowReview,
    'randomizeOrder': randomizeOrder,
    'passThreshold': passThreshold,
  };

  factory ExamConfig.fromJson(Map<String, dynamic> json) => ExamConfig(
    questionCount: json['questionCount'] as int? ?? 50,
    timeLimit: json['timeLimit'] as int? ?? 120,
    mode: ExamMode.values.firstWhere(
      (m) => m.toString() == json['mode'],
      orElse: () => ExamMode.standardExam,
    ),
    difficulty: ExamDifficulty.values.firstWhere(
      (d) => d.toString() == json['difficulty'],
      orElse: () => ExamDifficulty.medium,
    ),
    categories: (json['categories'] as List?)
        ?.map((c) => ExamCategory.values.firstWhere(
          (cat) => cat.toString() == c,
          orElse: () => ExamCategory.mixed,
        ))
        .toList() ?? ExamCategory.values.toList(),
    targetLevel: json['targetLevel'] as int? ?? 3,
    showExplanations: json['showExplanations'] as bool? ?? true,
    allowReview: json['allowReview'] as bool? ?? true,
    randomizeOrder: json['randomizeOrder'] as bool? ?? true,
    passThreshold: json['passThreshold'] as int? ?? 60,
  );
}

/// Enhanced exam question with metadata
class EnhancedExamQuestion {
  final String questionId;
  final String kanji;
  final String questionType;
  final String question;
  final List<String> options;
  final String correctAnswer;
  final String explanation;
  final int level; // 10-1級
  final ExamDifficulty difficulty;
  final ExamCategory category;
  final double averageTimeSeconds;
  final double correctnessRate; // ユーザーの正答率
  final int userAttempts; // ユーザーが解いた回数
  final List<String> commonMistakes; // よくある間違い
  final String? additionalTip; // 追加ヒント

  const EnhancedExamQuestion({
    required this.questionId,
    required this.kanji,
    required this.questionType,
    required this.question,
    required this.options,
    required this.correctAnswer,
    required this.explanation,
    required this.level,
    required this.difficulty,
    required this.category,
    required this.averageTimeSeconds,
    required this.correctnessRate,
    required this.userAttempts,
    required this.commonMistakes,
    this.additionalTip,
  });

  factory EnhancedExamQuestion.fromJson(Map<String, dynamic> json) =>
    EnhancedExamQuestion(
      questionId: json['questionId'] as String? ?? '',
      kanji: json['kanji'] as String? ?? '',
      questionType: json['questionType'] as String? ?? 'reading',
      question: json['question'] as String? ?? '',
      options: List<String>.from(json['options'] as List? ?? []),
      correctAnswer: json['correctAnswer'] as String? ?? '',
      explanation: json['explanation'] as String? ?? '',
      level: json['level'] as int? ?? 3,
      difficulty: ExamDifficulty.values.firstWhere(
        (d) => d.toString() == json['difficulty'],
        orElse: () => ExamDifficulty.medium,
      ),
      category: ExamCategory.values.firstWhere(
        (c) => c.toString() == json['category'],
        orElse: () => ExamCategory.mixed,
      ),
      averageTimeSeconds: (json['averageTimeSeconds'] as num?)?.toDouble() ?? 0.0,
      correctnessRate: (json['correctnessRate'] as num?)?.toDouble() ?? 0.0,
      userAttempts: json['userAttempts'] as int? ?? 0,
      commonMistakes: List<String>.from(json['commonMistakes'] as List? ?? []),
      additionalTip: json['additionalTip'] as String?,
    );

  Map<String, dynamic> toJson() => {
    'questionId': questionId,
    'kanji': kanji,
    'questionType': questionType,
    'question': question,
    'options': options,
    'correctAnswer': correctAnswer,
    'explanation': explanation,
    'level': level,
    'difficulty': difficulty.toString(),
    'category': category.toString(),
    'averageTimeSeconds': averageTimeSeconds,
    'correctnessRate': correctnessRate,
    'userAttempts': userAttempts,
    'commonMistakes': commonMistakes,
    'additionalTip': additionalTip,
  };
}
