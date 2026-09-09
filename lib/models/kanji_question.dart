enum QuestionType { multipleChoice, handwriting }

class KanjiQuestion {
  final String id;
  final String level; // LEVEL_10 ~ LEVEL_5
  final String kanji;
  final QuestionType questionType;
  final List<String> choices; // 選択肢（手書きの場合は空）
  final String correctAnswer;
  final Map<String, dynamic>? strokeOrderData;
  final int version;

  KanjiQuestion({
    required this.id,
    required this.level,
    required this.kanji,
    required this.questionType,
    required this.choices,
    required this.correctAnswer,
    this.strokeOrderData,
    required this.version,
  });

  factory KanjiQuestion.fromJson(Map<String, dynamic> json) {
    return KanjiQuestion(
      id: json['id'] ?? '',
      level: json['level'] ?? 'LEVEL_10',
      kanji: json['kanji'] ?? '',
      questionType: _parseQuestionType(json['questionType']),
      choices: List<String>.from(json['choices'] ?? []),
      correctAnswer: json['correctAnswer'] ?? '',
      strokeOrderData: json['strokeOrderData'],
      version: json['version'] ?? 1,
    );
  }

  static QuestionType _parseQuestionType(String? type) {
    switch (type) {
      case 'handwriting':
        return QuestionType.handwriting;
      default:
        return QuestionType.multipleChoice;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'level': level,
      'kanji': kanji,
      'questionType': questionType.toString().split('.').last,
      'choices': choices,
      'correctAnswer': correctAnswer,
      'strokeOrderData': strokeOrderData,
      'version': version,
    };
  }

  KanjiQuestion copyWith({
    String? id,
    String? level,
    String? kanji,
    QuestionType? questionType,
    List<String>? choices,
    String? correctAnswer,
    Map<String, dynamic>? strokeOrderData,
    int? version,
  }) {
    return KanjiQuestion(
      id: id ?? this.id,
      level: level ?? this.level,
      kanji: kanji ?? this.kanji,
      questionType: questionType ?? this.questionType,
      choices: choices ?? this.choices,
      correctAnswer: correctAnswer ?? this.correctAnswer,
      strokeOrderData: strokeOrderData ?? this.strokeOrderData,
      version: version ?? this.version,
    );
  }
}
