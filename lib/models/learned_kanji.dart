class LearnedKanji {
  final String id;
  final String uid;
  final String questionId;
  final String kanji;
  final String level;
  final DateTime learnedAt;

  LearnedKanji({
    required this.id,
    required this.uid,
    required this.questionId,
    required this.kanji,
    required this.level,
    required this.learnedAt,
  });

  factory LearnedKanji.fromJson(Map<String, dynamic> json) {
    return LearnedKanji(
      id: json['id'] ?? '',
      uid: json['uid'] ?? '',
      questionId: json['questionId'] ?? '',
      kanji: json['kanji'] ?? '',
      level: json['level'] ?? '',
      learnedAt: json['learnedAt'] != null
        ? DateTime.parse(json['learnedAt'])
        : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'uid': uid,
      'questionId': questionId,
      'kanji': kanji,
      'level': level,
      'learnedAt': learnedAt.toIso8601String(),
    };
  }

  LearnedKanji copyWith({
    String? id,
    String? uid,
    String? questionId,
    String? kanji,
    String? level,
    DateTime? learnedAt,
  }) {
    return LearnedKanji(
      id: id ?? this.id,
      uid: uid ?? this.uid,
      questionId: questionId ?? this.questionId,
      kanji: kanji ?? this.kanji,
      level: level ?? this.level,
      learnedAt: learnedAt ?? this.learnedAt,
    );
  }
}
